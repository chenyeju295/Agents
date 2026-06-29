# 私有协议 SDK 封装参考

## 决策流程

```
拿到厂商 SDK
  ↓
pub.dev 搜索 "<vendor_name> flutter" → 有现成插件？
  ├── 有，且维护正常 → 直接用，参考 ble.md 的封装层模式
  └── 没有或停维护
        ↓
      厂商有 REST API 替代？
        ├── 有 → 用 core_network（dio），不用 Platform Channel
        └── 没有 → 自建 Plugin，按本文档操作
```

---

## Plugin 包创建

```bash
# 必须用 plugin 模板（有原生代码）
flutter create \
  --template=plugin \
  --platforms=android,ios \
  --org=com.example \
  packages/core/core_<vendor>/
```

---

## 标准包结构

```
core_<vendor>/
├── lib/
│   ├── core_<vendor>.dart              ← barrel only
│   └── src/
│       ├── <vendor>_service.dart       ← 抽象接口
│       ├── <vendor>_models.dart        ← 领域模型（不含 SDK 类型）
│       ├── <vendor>_errors.dart        ← 错误枚举
│       └── <vendor>_service_impl.dart  ← MethodChannel 调用
├── android/src/main/kotlin/com/example/core_<vendor>/
│   ├── Core<Vendor>Plugin.kt           ← Plugin 注册入口
│   └── <Vendor>Handler.kt             ← SDK 调用 + Channel 桥接
├── ios/Classes/
│   ├── Core<Vendor>Plugin.swift        ← Plugin 注册入口
│   └── <Vendor>Handler.swift          ← SDK 调用 + Channel 桥接
└── pubspec.yaml
```

---

## Dart 侧 MethodChannel 实现模板

```dart
// src/<vendor>_service_impl.dart
class VendorServiceImpl implements VendorService {
  static const _channel = MethodChannel('com.example.smartwear/vendor_xyz');
  static const _eventChannel = EventChannel('com.example.smartwear/vendor_xyz/events');

  @override
  Future<Result<VendorDevice>> initialize(VendorConfig config) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'initialize',
        config.toMap(),   // 自定义序列化，不传 SDK 对象
      );
      return Result.success(VendorDevice.fromMap(result!));
    } on PlatformException catch (e) {
      return Result.failure(_mapPlatformError(e));
    }
  }

  @override
  Stream<VendorEvent> get eventStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => VendorEvent.fromMap(Map<String, dynamic>.from(event as Map)));
  }

  VendorError _mapPlatformError(PlatformException e) {
    return switch (e.code) {
      'INIT_FAILED'      => const VendorError.initializationFailed(),
      'NOT_CONNECTED'    => const VendorError.notConnected(),
      'TIMEOUT'          => const VendorError.timeout(),
      'PERMISSION_DENIED'=> const VendorError.permissionDenied(),
      _                  => VendorError.unknown(e.code, e.message ?? ''),
    };
  }
}
```

---

## Android 原生侧模板（Kotlin）

```kotlin
// Core<Vendor>Plugin.kt
class CoreVendorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var handler: VendorHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.smartwear/vendor_xyz")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.example.smartwear/vendor_xyz/events")
        handler = VendorHandler(binding.applicationContext, eventChannel)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handler?.initialize(call.arguments as Map<*, *>, result)
            "sendCommand" -> handler?.sendCommand(call.arguments as Map<*, *>, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        handler?.dispose()
    }
}

// VendorHandler.kt
class VendorHandler(
    private val context: Context,
    eventChannel: EventChannel
) : EventChannel.StreamHandler {
    private val sdk = VendorSdk.getInstance()   // 厂商 SDK
    private var eventSink: EventChannel.EventSink? = null

    init {
        eventChannel.setStreamHandler(this)
    }

    fun initialize(args: Map<*, *>, result: MethodChannel.Result) {
        try {
            val config = VendorConfig(args["apiKey"] as String)
            sdk.init(context, config) { success, error ->
                // ⚠️ 厂商回调可能在子线程，必须切主线程
                Handler(Looper.getMainLooper()).post {
                    if (success) {
                        result.success(mapOf("deviceId" to sdk.deviceId))
                    } else {
                        result.error("INIT_FAILED", error?.message, null)
                    }
                }
            }
        } catch (e: Exception) {
            result.error("INIT_FAILED", e.message, null)
        }
    }

    // EventChannel — 推送事件到 Dart
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
        sdk.setDataListener { data ->
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(mapOf(
                    "type" to "data",
                    "payload" to data.toByteArray()
                ))
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        sdk.removeDataListener()
        eventSink = null
    }

    fun dispose() {
        sdk.disconnect()
        eventSink = null
    }
}
```

---

## iOS 原生侧模板（Swift）

```swift
// Core<Vendor>Plugin.swift
public class CoreVendorPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.smartwear/vendor_xyz",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.example.smartwear/vendor_xyz/events",
            binaryMessenger: registrar.messenger()
        )
        let instance = CoreVendorPlugin()
        let handler = VendorHandler(eventChannel: eventChannel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.handler = handler
    }

    var handler: VendorHandler?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handler?.initialize(args: call.arguments as? [String: Any] ?? [:], result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// VendorHandler.swift
class VendorHandler: NSObject, FlutterStreamHandler {
    private let sdk = VendorSDK.shared
    private var eventSink: FlutterEventSink?

    init(eventChannel: FlutterEventChannel) {
        super.init()
        eventChannel.setStreamHandler(self)
    }

    func initialize(args: [String: Any], result: @escaping FlutterResult) {
        let apiKey = args["apiKey"] as? String ?? ""
        sdk.initialize(apiKey: apiKey) { [weak self] success, error in
            // ⚠️ 确保在主线程回调 Flutter
            DispatchQueue.main.async {
                if success {
                    result(["deviceId": self?.sdk.deviceId ?? ""])
                } else {
                    result(FlutterError(
                        code: "INIT_FAILED",
                        message: error?.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        sdk.onDataReceived = { [weak self] data in
            DispatchQueue.main.async {
                self?.eventSink?(["type": "data", "payload": FlutterStandardTypedData(bytes: data)])
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sdk.onDataReceived = nil
        eventSink = nil
        return nil
    }
}
```

---

## 关键坑：线程安全

**Android 和 iOS 的厂商 SDK 回调大概率在子线程。**  
所有 `result.success()` / `result.error()` / `eventSink?.success()` 必须在主线程调用，否则 Flutter Engine 会 crash 或静默丢弃。

| 平台 | 切主线程方式 |
|------|------------|
| Android | `Handler(Looper.getMainLooper()).post { ... }` |
| iOS | `DispatchQueue.main.async { ... }` |

---

## pubspec.yaml 配置

```yaml
name: core_vendor_xyz
description: Vendor XYZ SDK wrapper for Flutter
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  core_base:
    path: ../../core/core_base

flutter:
  plugin:
    platforms:
      android:
        kotlin_version: '1.8.0'
        package: com.example.core_vendor_xyz
        pluginClass: CoreVendorXyzPlugin
      ios:
        pluginClass: CoreVendorXyzPlugin
```
