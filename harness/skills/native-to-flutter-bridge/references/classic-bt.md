# 经典蓝牙封装参考

## 插件评估结论

| 插件 | 状态 | 建议 |
|------|------|------|
| `flutter_bluetooth_serial` | 停止维护，Android only | ⚠️ 谨慎使用 |
| `bluetooth_classic` | 较新，双端 | 可评估 |
| 自建 Plugin | 完全可控 | 若 SDK 量级不大推荐 |

**决策规则：** 如果只有 1 个 feature 使用经典蓝牙，且厂商 SDK 已封装 SPP/RFCOMM，优先按 vendor-sdk.md 处理。若需要通用经典蓝牙（跨多设备），再考虑社区插件或自建。

---

## 接口定义

```dart
abstract class ClassicBtService {
  /// 扫描已配对设备
  Future<Result<List<ClassicBtDevice>>> getBondedDevices();

  /// 扫描附近可发现设备（需要 BLUETOOTH_SCAN 权限）
  Stream<ClassicBtDevice> discoverDevices();

  /// 建立 SPP (Serial Port Profile) 连接
  Future<Result<ClassicBtSocket>> connectSpp(
    String deviceAddress, {
    String? uuid, // 默认 SPP UUID: 00001101-0000-1000-8000-00805F9B34FB
  });
}

abstract class ClassicBtSocket {
  Stream<Uint8List> get inputStream;
  Future<Result<void>> write(Uint8List data);
  Future<void> close();
  bool get isConnected;
}
```

---

## 已知平台差异

### Android
- 经典蓝牙 + BLE 权限在 Android 12+ 是分开的，都需要声明
- `BluetoothSocket.connect()` 是阻塞调用，必须放在子线程
- 配对（Bond）和连接是两回事，connect 前不需要强制 bond

### iOS
- iOS **不支持**作为 Central 发起 SPP 连接（CoreBluetooth 只支持 BLE）
- 经典蓝牙连接在 iOS 上只能通过 MFi 授权的 ExternalAccessory 框架
- **实际影响：** 如果设备要同时支持 Android + iOS 经典蓝牙，通常需要硬件支持 BLE，否则 iOS 侧需要走厂商 MFi SDK

---

## 权限声明

```xml
<!-- Android -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

```xml
<!-- iOS Info.plist（仅 MFi 设备） -->
<key>UISupportedExternalAccessoryProtocols</key>
<array>
  <string>com.vendor.protocol</string>
</array>
```
