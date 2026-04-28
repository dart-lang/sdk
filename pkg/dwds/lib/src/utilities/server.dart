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

/// Finds unused port and binds a new http server to it.
///
/// Retries a few times to recover from errors due to
/// another thread or process opening the same port.
/// Starts by trying to bind to [port] if specified.
Future<HttpServer> startHttpServer(String hostname, {int? port}) async {
  HttpServer? httpServer;
  final retries = 5;
  var i = 0;
  var foundPort = port ?? await findUnusedPort();
  while (i < retries) {
    i++;
    try {
      httpServer = await HttpMultiServer.bind(hostname, foundPort);
    } on SocketException {
      if (i == retries) rethrow;
    }
    if (httpServer != null || i == retries) return httpServer!;
    foundPort = await findUnusedPort();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return httpServer!;
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
