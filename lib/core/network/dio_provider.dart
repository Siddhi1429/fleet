import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/diagnostics/domain/diagnostics_provider.dart';
import 'mock_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.fleetops.mock',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': '1.0.0',
    },
  ));

  // Diagnostics interceptor — tracks active API calls and logs
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      ref.read(diagnosticsProvider.notifier).incrementApiCall();
      ref.read(diagnosticsProvider.notifier).addLog(
            '[REQ] ${options.method} ${options.path}',
          );
      return handler.next(options);
    },
    onResponse: (response, handler) {
      ref.read(diagnosticsProvider.notifier).decrementApiCall();
      ref.read(diagnosticsProvider.notifier).addLog(
            '[RES] ${response.statusCode} ${response.requestOptions.path}',
          );
      return handler.next(response);
    },
    onError: (DioException e, handler) {
      ref.read(diagnosticsProvider.notifier).decrementApiCall();
      ref.read(diagnosticsProvider.notifier).addLog(
            '[ERR] ${e.type.name} ${e.requestOptions.path}: ${e.message}',
          );
      return handler.next(e);
    },
  ));

  // Mock interceptor — intercepts all requests and returns mock data
  dio.interceptors.add(MockInterceptor());

  return dio;
});
