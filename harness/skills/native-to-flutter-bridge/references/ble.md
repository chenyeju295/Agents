# BLE 封装参考

## 推荐方案

**插件：** `flutter_blue_plus: ^1.x`  
**策略：** 在插件上封装一层领域接口，core_ble 不直接暴露插件类型。

---

## 完整接口定义

```dart
// src/ble_service.dart
import 'package:core_base/core_base.dart';
import 'ble_models.dart';
import 'ble_errors.dart';

abstract class BleService {
  /// 扫描附近设备。调用方负责在不需要时取消订阅。
  Stream<List<BleDevice>> scanDevices({
    List<String> serviceUuids = const [],
    Duration timeout = const Duration(seconds: 10),
  });

  /// 停止扫描
  Future<void> stopScan();

  /// 连接设备。返回 BleConnection 用于后续读写。
  Future<Result<BleConnection>> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
  });

  /// 当前连接状态流
  Stream<BleConnectionState> connectionState(String deviceId);
}

abstract class BleConnection {
  String get deviceId;

  Future<Result<Uint8List>> readCharacteristic(BleCharacteristic characteristic);

  Future<Result<void>> writeCharacteristic(
    BleCharacteristic characteristic,
    Uint8List data, {
    bool withResponse = true,
  });

  /// 订阅 notify/indicate
  Stream<Result<Uint8List>> subscribeCharacteristic(BleCharacteristic characteristic);

  Future<void> disconnect();
}
```

---

## 领域模型

```dart
// src/ble_models.dart
class BleDevice {
  final String id;
  final String? name;
  final int rssi;
  final Map<String, Uint8List> serviceData;

  const BleDevice({
    required this.id,
    this.name,
    required this.rssi,
    this.serviceData = const {},
  });
}

class BleCharacteristic {
  final String serviceUuid;
  final String characteristicUuid;
  const BleCharacteristic({required this.serviceUuid, required this.characteristicUuid});
}

enum BleConnectionState { connecting, connected, disconnecting, disconnected }
```

---

## 错误归一化

```dart
// src/ble_errors.dart
sealed class BleError extends AppError {
  const factory BleError.permissionDenied() = _PermissionDenied;
  const factory BleError.bluetoothOff() = _BluetoothOff;
  const factory BleError.deviceNotFound(String deviceId) = _DeviceNotFound;
  const factory BleError.connectionTimeout(String deviceId) = _ConnectionTimeout;
  const factory BleError.connectionLost(String deviceId, String reason) = _ConnectionLost;
  const factory BleError.operationFailed(String operation, String detail) = _OperationFailed;
}
```

---

## flutter_blue_plus 实现层要点

```dart
// src/ble_service_impl.dart
class BleServiceImpl implements BleService {
  @override
  Stream<List<BleDevice>> scanDevices({
    List<String> serviceUuids = const [],
    Duration timeout = const Duration(seconds: 10),
  }) {
    // flutter_blue_plus 的 scanResults 是 List<ScanResult>
    // 必须在这里转换为 BleDevice，不能把 ScanResult 透传出去
    FlutterBluePlus.startScan(
      withServices: serviceUuids.map((u) => Guid(u)).toList(),
      timeout: timeout,
    );
    return FlutterBluePlus.scanResults.map(
      (results) => results.map(_toDevice).toList(),
    );
  }

  BleDevice _toDevice(ScanResult r) => BleDevice(
    id: r.device.remoteId.str,
    name: r.device.platformName.isEmpty ? null : r.device.platformName,
    rssi: r.rssi,
  );

  @override
  Future<Result<BleConnection>> connect(String deviceId, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(timeout: timeout);
      return Result.success(BleConnectionImpl(device));
    } on FlutterBluePlusException catch (e) {
      return Result.failure(_mapError(e, deviceId));
    }
  }

  BleError _mapError(FlutterBluePlusException e, [String? deviceId]) {
    // Android / iOS 错误码都归一化到 BleError
    return switch (e.errorCode) {
      133 => BleError.connectionTimeout(deviceId ?? ''),      // Android GATT_ERROR
      8   => BleError.connectionLost(deviceId ?? '', 'GATT_CONN_TIMEOUT'), // Android
      _   => BleError.operationFailed(e.function ?? '', e.description ?? ''),
    };
  }
}
```

---

## 已知平台坑

### Android
- **GATT error 133**：连接时最常见，通常是设备端未准备好。建议 retry 1次，间隔 500ms。
- **扫描限制**：Android 7+ 前台 30 秒内最多启动 5 次扫描，超出被系统静默。长时扫描用 `withoutDuplicates: false` + 自己去重。
- **MTU**：连接后主动请求 `device.requestMtu(512)`，否则默认 23 字节。
- **线程**：`FlutterBluePlus` 回调已在主线程，无需手动切换。

### iOS
- **CoreBluetooth 状态**：App 首次启动会触发权限弹窗，扫描必须在 `CBCentralManagerStatePoweredOn` 之后调用，`flutter_blue_plus` 已处理，但 `adapterState` 需监听。
- **后台模式**：若需后台 BLE，`Info.plist` 必须加 `bluetooth-central`，且扫描行为受限——不能指定 nil serviceUUID。
- **设备 ID**：iOS 的 device ID 是 UUID，每次 App 安装后可能变化，不能持久化存储用于再连接，要用 characteristic 里的设备序列号。

### 权限（两端）
```xml
<!-- Android AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" /> <!-- Android 11 以下需要 -->

<!-- iOS Info.plist -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙连接智能设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙连接智能设备</string>
```

---

## 测试模板

```dart
// test/ble_service_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleServiceImpl', () {
    late BleService service;

    setUp(() {
      // Mock MethodChannel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.smartwear/ble'),
        (call) async => switch (call.method) {
          'connect' => {'success': true},
          _ => null,
        },
      );
      service = BleServiceImpl();
    });

    test('connect returns BleError.deviceNotFound when device missing', () async {
      // arrange: mock returns not found
      // act
      final result = await service.connect('nonexistent-id');
      // assert
      expect(result.isFailure, isTrue);
    });
  });
}
```
