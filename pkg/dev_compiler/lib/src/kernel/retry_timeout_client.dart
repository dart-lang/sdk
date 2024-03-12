// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

/// An HTTP client wrapper that times out connections and requests and
/// automatically retries failing requests.
class RetryTimeoutClient {
  /// The wrapped client.
  final HttpClient _inner;

  /// The number of times a request should be retried.
  final int _retries;

  /// The callback that determines whether a request should be retried.
  final bool Function(HttpClientResponse) _when;

  /// The callback that determines whether a request when an error is thrown.
  final bool Function(Object, StackTrace) _whenError;

  /// The callback that determines how long to wait before retrying a request.
  final Duration Function(int) _delay;

  /// The callback that determines when to cancel a connection.
  final Duration Function(int) _connectionTimeout;

  /// The callback that determines when to cancel a request.
  final Duration Function(int) _responseTimeout;

  /// The callback to call to indicate that a request is being retried.
  final void Function(Uri, HttpClientResponse?, int)? _onRetry;

  /// Creates a client wrapping [_inner] that retries HTTP requests.
  RetryTimeoutClient(
    this._inner, {
    int retries = 3,
    bool Function(HttpClientResponse)? when,
    bool Function(Object, StackTrace)? whenError,
    Duration Function(int retryCount)? delay,
    Duration Function(int retryCount)? connectionTimeout,
    Duration Function(int retryCount)? responseTimeout,
    void Function(Uri, HttpClientResponse?, int retryCount)? onRetry,
  })  : _retries = retries,
        _when = when ?? _defaultWhen,
        _whenError = whenError ?? _defaultWhenError,
        _delay = delay ?? _defaultDelay,
        _connectionTimeout = connectionTimeout ?? _defaultTimeout,
        _responseTimeout = responseTimeout ?? _defaultTimeout,
        _onRetry = onRetry {
    RangeError.checkNotNegative(_retries, 'retries');
  }

  Future<HttpClientResponse> headUrl(Uri url) {
    return _retry(url, _inner.headUrl);
  }

  Future<HttpClientResponse> getUrl(Uri url) {
    return _retry(url, _inner.getUrl);
  }

  Future<HttpClientResponse> _retry(
      Uri url, Future<HttpClientRequest> Function(Uri) method) async {
    var i = 0;
    for (;;) {
      HttpClientResponse? response;
      try {
        _inner.connectionTimeout = _connectionTimeout(i);
        var request = await method(url).timeout(
          _responseTimeout(i),
          onTimeout: () =>
              throw TimeoutException('$url, retry:$i', _responseTimeout(i)),
        );
        response = await request.close();
      } catch (error, stackTrace) {
        if (i == _retries || !_whenError(error, stackTrace)) rethrow;
      }

      if (response != null) {
        if (i == _retries || !_when(response)) return response;

        // Make sure the response stream is listened to so that we don't leave
        // dangling connections.
        unawaited(response.listen((_) {}).cancel().catchError((_) {}));
      }

      await Future.delayed(_delay(i));
      _onRetry?.call(url, response, i);
      i++;
    }
  }

  void close({bool force = false}) => _inner.close(force: force);
}

bool _defaultWhen(HttpClientResponse response) =>
    response.statusCode == 500 || response.statusCode == 503;

bool _defaultWhenError(Object error, StackTrace stackTrace) =>
    error is OSError ||
    error is HttpException ||
    error is SocketException ||
    error is TimeoutException;

Duration _defaultDelay(int retryCount) =>
    const Duration(milliseconds: 500) * pow(1.5, retryCount);

Duration _defaultTimeout(int retryCount) =>
    const Duration(milliseconds: 5000) * pow(1.5, retryCount);
