// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/src/services/chrome/chrome_debug_exception.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;

/// Returns a port that is probably, but not definitely, not in use.
///
/// This has a built-in race condition: another process may bind this port at
/// any time after this call has returned.
Future<int> findUnusedPort() async {
  int port;
  ServerSocket socket;
  try {
    socket = await ServerSocket.bind(
      InternetAddress.loopbackIPv6,
      0,
      v6Only: true,
    );
  } on SocketException {
    socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  }
  port = socket.port;
  await socket.close();
  return port;
}

/// Binds a new http server to [hostname].
///
/// Tries [port] first if specified, then falls back to port 0 so the OS picks a
/// port that is free for this exact bind. A port from [findUnusedPort] is only
/// known to be free on `[::1]`. It can still be held over IPv4, which makes the
/// dual-stack `[::]` bind used for `'any'` fail with "Address already in use".
///
/// Retries a few times to recover from transient bind errors.
Future<HttpServer> startHttpServer(String hostname, {int? port}) async {
  const retries = 5;
  var requestedPort = port ?? 0;
  for (var attempt = 1; ; attempt++) {
    try {
      return await HttpMultiServer.bind(hostname, requestedPort);
    } on SocketException {
      if (attempt == retries) rethrow;
    }
    requestedPort = 0;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// Handles [requests] using [handler].
///
/// Captures all sync and async stack error traces and passes
/// them to the [onError] handler.
void serveHttpRequests(
  Stream<HttpRequest> requests,
  Handler handler,
  void Function(Object, StackTrace) onError,
) {
  return Chain.capture(() {
    serveRequests(requests, handler);
  }, onError: onError);
}

/// Throws an [wip.ExceptionDetails] object if `exceptionDetails` is present on
/// the result.
void handleErrorIfPresent(wip.WipResponse? response, {String? evalContents}) {
  final result = response?.result;
  if (result == null) return;
  if (result.containsKey('exceptionDetails')) {
    throw ChromeDebugException(
      result['exceptionDetails'] as Map<String, dynamic>,
      evalContents: evalContents,
    );
  }
}

/// Returns result contained in the response.
/// Throws an [wip.ExceptionDetails] object if `exceptionDetails` is present on
/// the result or the result is null.
Map<String, dynamic> getResultOrHandleError(
  wip.WipResponse? response, {
  String? evalContents,
}) {
  handleErrorIfPresent(response, evalContents: evalContents);
  final result = response?.result?['result'];
  if (result == null) {
    throw ChromeDebugException({
      'text': 'null result from Chrome Devtools',
    }, evalContents: evalContents);
  }
  return result as Map<String, dynamic>;
}
