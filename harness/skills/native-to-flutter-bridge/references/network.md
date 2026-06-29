# Wi-Fi / HTTP 封装参考

## 方案

**插件：** `dio: ^5.x`（不需要 Platform Channel，纯 Dart）  
**包类型：** `package`（非 plugin，无原生代码）

---

## core_network 接口

```dart
abstract class NetworkService {
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<Result<T>> post<T>(
    String path, {
    required Map<String, dynamic> body,
    T Function(Map<String, dynamic>)? fromJson,
  });
}
```

---

## Dio 实现层要点

```dart
class NetworkServiceImpl implements NetworkService {
  late final Dio _dio;

  NetworkServiceImpl({required String baseUrl, List<Interceptor> interceptors = const []}) {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(retries: 2),
      ...interceptors,
    ]);
  }

  @override
  Future<Result<T>> get<T>(String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return Result.success(fromJson != null
          ? fromJson(response.data as Map<String, dynamic>)
          : response.data as T);
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    }
  }

  NetworkError _mapDioError(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout => const NetworkError.timeout(),
    DioExceptionType.receiveTimeout    => const NetworkError.timeout(),
    DioExceptionType.badResponse       => NetworkError.httpError(e.response?.statusCode ?? 0),
    DioExceptionType.connectionError   => const NetworkError.noConnection(),
    _                                  => NetworkError.unknown(e.message ?? ''),
  };
}
```

---

## Riverpod 注入方式

```dart
// core_network 包内提供默认 Provider
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkServiceImpl(baseUrl: 'https://api.example.com');
});

// App 或 Feature 可覆盖
void main() {
  runApp(
    ProviderScope(
      overrides: [
        networkServiceProvider.overrideWith((_) =>
          NetworkServiceImpl(baseUrl: AppConfig.apiBaseUrl)),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 权限

```xml
<!-- Android -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

iOS 无需声明，但若访问 HTTP（非 HTTPS）需在 `Info.plist` 添加 ATS 例外。
