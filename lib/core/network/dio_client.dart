import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_authflow_advanced/core/di/locator.dart';
import 'package:flutter_authflow_advanced/features/auth/data/auth_repository.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Injects the latest access token into outgoing requests.
class AuthInterceptor extends Interceptor {
  final AuthRepository auth;

  AuthInterceptor(this.auth);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only add header if not already set explicitly
    final hasAuthHeader = options.headers.containsKey('Authorization');
    if (!hasAuthHeader) {
      final t = await auth.current();
      if (t != null && t.accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer ${t.accessToken}';
      }
    }
    handler.next(options);
  }
}

/// Handles 401 responses by refreshing the token once, then retrying the request.
/// Concurrent 401s during an in-flight refresh will wait on the same refresh future.
class RefreshInterceptor extends Interceptor {
  final AuthRepository auth;
  final Dio dio;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  RefreshInterceptor(this.auth, this.dio);

  bool _isUnauthorized(DioException err) => err.response?.statusCode == 401;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isUnauthorized(err)) {
      handler.next(err);
      return;
    }

    try {
      // Ensure only one refresh happens; others await same future
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshCompleter = Completer<void>();

        try {
          await auth.refresh();
          _refreshCompleter!.complete();
        } catch (e) {
          _refreshCompleter!.completeError(e);
          rethrow;
        } finally {
          _isRefreshing = false;
        }
      } else {
        // Wait for the in-flight refresh to complete/fail
        await _refreshCompleter!.future;
      }

      // Clone & retry the original request with a clean header set
      final RequestOptions req = err.requestOptions;

      // Start from the original headers and remove Authorization
      final Map<String, dynamic> newHeaders = Map<String, dynamic>.from(
        req.headers,
      );
      newHeaders.remove('Authorization');

      final response = await dio.request<dynamic>(
        req.path,
        data: req.data,
        queryParameters: req.queryParameters,
        options: Options(
          method: req.method,
          headers: newHeaders,
          responseType: req.responseType,
          contentType: req.contentType,
          sendTimeout: req.sendTimeout,
          receiveTimeout: req.receiveTimeout,
          followRedirects: req.followRedirects,
          validateStatus: req.validateStatus,
          receiveDataWhenStatusError: req.receiveDataWhenStatusError,
          extra: req.extra,
        ),
        cancelToken: req.cancelToken,
        onReceiveProgress: req.onReceiveProgress,
        onSendProgress: req.onSendProgress,
      );

      // Let AuthInterceptor inject the fresh token on this retried call
      handler.resolve(response);
    } catch (e) {
      // Refresh failed → let the original error bubble up
      handler.reject(err);
    }
  }
}

/// Builds a Dio instance wired with Authorization + Refresh interceptors
Dio buildAuthedDio() {
  final dio = sl<Dio>();
  final authRepo = sl<AuthRepository>();

  dio.interceptors.clear();

  dio.interceptors.add(AuthInterceptor(authRepo));
  dio.interceptors.add(RefreshInterceptor(authRepo, dio));

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  // Demo mock protected endpoint
  bool first401 = true;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final uri = options.uri;
        if (uri.host == 'mockapi.local' && uri.path == '/secret') {
          final authHeader = options.headers['Authorization'] as String?;
          final isBearer = authHeader?.startsWith('Bearer access_') ?? false;

          // Force a single 401 once to showcase the refresh/retry flow
          if (!isBearer || first401) {
            first401 = false;
            return handler.reject(
              DioException(
                type: DioExceptionType.badResponse,
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 401),
              ),
            );
          }

          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: 'Top Secret: 🫣 it is awesome (via Dio)!',
            ),
          );
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}
