---
name: native-to-flutter-bridge
description: >
  Use this skill whenever the task involves wrapping, encapsulating, or migrating native Android/iOS
  code into Flutter packages — especially for BLE, Classic Bluetooth, Wi-Fi/HTTP, or vendor SDK
  communication layers. Triggers include: "封装原生", "Platform Channel", "MethodChannel",
  "EventChannel", "写 core_ble / core_<vendor>", "接入厂商 SDK", "蓝牙封装", "设备通信",
  "Flutter plugin", or any task that touches packages/core/ with a communication capability.
  Always use this skill before writing any Platform Channel code, plugin boilerplate, or
  native bridge interface — the patterns and constraints here are authoritative for this repo.
---

# Native → Flutter Bridge Skill

封装原生 Android/iOS SDK 或系统 API 为 Flutter `packages/core/` 包的完整操作规范。

---

## 0. 收到任务先做的三件事

```
1. 确认通信类型 → 查对应 Reference 文件
2. 确认 specs/capabilities/<name>.md 存在 → 不存在先起草规范
3. 确认厂商 SDK 是否有现成 Flutter 插件 → 查 pub.dev，避免重复造轮子
```

**通信类型 → Reference 文件映射：**

| 通信类型 | 优先用现成插件 | Reference |
|---------|-------------|-----------|
| BLE（蓝牙低功耗） | `flutter_blue_plus` | [references/ble.md](references/ble.md) |
| 经典蓝牙 | `flutter_bluetooth_serial`（评估后决定） | [references/classic-bt.md](references/classic-bt.md) |
| Wi-Fi / HTTP | `dio` | [references/network.md](references/network.md) |
| 私有协议 SDK | 先查 pub.dev，通常需要自写 | [references/vendor-sdk.md](references/vendor-sdk.md) |

---

## 1. 包结构规范

所有 `packages/core/core_<name>/` 包遵循统一结构：

```
packages/core/core_<name>/
├── lib/
│   ├── core_<name>.dart          ← 唯一 barrel，只 export 公开接口
│   └── src/
│       ├── <name>_service.dart   ← 抽象接口（纯 Dart，无平台类型）
│       ├── <name>_models.dart    ← 领域模型（自定义类型，不泄露 SDK 类型）
│       ├── <name>_errors.dart    ← 错误枚举（继承 AppError）
│       └── <name>_service_impl.dart ← MethodChannel / EventChannel 实现
├── android/src/main/kotlin/      ← Android 原生实现
├── ios/Classes/                  ← iOS 原生实现
├── pubspec.yaml                  ← plugin 类型（有原生代码必须用 plugin）
└── test/
    └── <name>_service_test.dart  ← mock channel，纯 Dart 测试
```

**R3 强制：** `lib/core_<name>.dart` 只做 export，不写任何实现。

---

## 2. 接口设计三原则

### 原则 A：接口不泄露平台类型

```dart
// ✅ 正确：接口只用自定义 Dart 类型
abstract class BleService {
  Stream<List<BleDevice>> scanDevices({List<String> serviceUuids = const []});
  Future<Result<BleConnection>> connect(String deviceId);
}

// ❌ 错误：接口暴露了 flutter_blue_plus 的类型
abstract class BleService {
  Stream<List<BluetoothDevice>> scanDevices(); // BluetoothDevice 是插件类型
}
```

### 原则 B：跨包边界用 Result<T>，不 throw

```dart
// ✅ 正确
Future<Result<BleConnection>> connect(String deviceId);

// ❌ 错误
Future<BleConnection> connect(String deviceId); // 失败时 throw
```

`Result<T>` 来自 `core_base`，failure 携带 `AppError` 子类。

### 原则 C：错误归一化——Android/iOS 错误码统一映射

```dart
// <name>_errors.dart
sealed class BleError extends AppError {
  const factory BleError.deviceNotFound(String deviceId) = _DeviceNotFound;
  const factory BleError.connectionTimeout(String deviceId) = _ConnectionTimeout;
  const factory BleError.permissionDenied() = _PermissionDenied;
  // 不暴露平台原始错误码
}
```

---

## 3. Channel 命名约定

```
MethodChannel:  com.example.<package_id>/<capability>
EventChannel:   com.example.<package_id>/<capability>/events

示例：
  com.example.smartwear/ble
  com.example.smartwear/ble/scan_events
  com.example.smartwear/vendor_xyz
```

---

## 4. 执行检查清单

### 开始前
- [ ] `specs/capabilities/<name>.md` 已存在？（不存在先建，R2）
- [ ] pub.dev 已搜索现成插件？
- [ ] 厂商 SDK 双端（Android + iOS）都有？只有单端的要在接口注释里标注
- [ ] 包类型确认：有原生代码 → `flutter create --template=plugin`

### 代码写完后
- [ ] `lib/core_<name>.dart` 只有 export 语句？
- [ ] 接口参数/返回值里没有任何第三方插件类型或原生 SDK 类型？
- [ ] 所有跨包方法返回 `Result<T>`，没有 throw？
- [ ] 错误枚举覆盖了 Android 和 iOS 两侧的主要错误场景？
- [ ] `dart analyze packages/core/core_<name>/` 0 error？
- [ ] 有 mock channel 的基础单元测试？

---

## 5. 各通信类型详细操作

见对应 Reference 文件。每个文件包含：
- 推荐插件/方案
- 完整代码模板
- 平台特有的坑和处理方式
- Android / iOS 原生侧代码示例

**按需读取，不要全部加载：**
- 做 BLE → 读 [references/ble.md](references/ble.md)
- 做经典蓝牙 → 读 [references/classic-bt.md](references/classic-bt.md)
- 做 HTTP/网络 → 读 [references/network.md](references/network.md)
- 做厂商 SDK → 读 [references/vendor-sdk.md](references/vendor-sdk.md)

---

## 6. specs 规范草案模板

新建平台能力时，先在 `specs/capabilities/<name>.md` 写规范：

```markdown
# <Capability Name> 能力规范

> 状态：📋 草案 / 🏗️ 实现中 / ✅ 稳定
> 最后更新：YYYY-MM-DD

## 接口契约

\`\`\`dart
abstract class <Name>Service {
  // 方法签名 + 参数说明
}
\`\`\`

## 权限声明
- Android: <权限列表>
- iOS: <Info.plist key 列表>

## 错误场景
| 错误 | Android 触发 | iOS 触发 |
|------|------------|---------|
| ... | ... | ... |

## 线程模型
- 回调线程：...
- 调用方期望：...
```
