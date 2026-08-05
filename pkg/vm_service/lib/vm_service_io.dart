// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'vm_service.dart';

/// Connect to the given uri and return a new [VmService] instance.
Future<VmService> vmServiceConnectUri(
  String wsUri, {
  Log? log,
  // pingInterval has a default to act as a keep-alive to prevent proxies like
  // Norton antivirus from dropping connections with no traffic for a period.
  Duration? pingInterval = const Duration(seconds: 15),
}) async {
  return vmServiceConnectUriWithFactory<VmService>(
    wsUri,
    vmServiceFactory: VmService.defaultFactory,
    log: log,
    pingInterval: pingInterval,
  );
}

/// Connect to the given uri and return a new instance of [T], which is
/// constructed by [vmServiceFactory] and may be a subclass of [VmService].
Future<T> vmServiceConnectUriWithFactory<T extends VmService>(
  String wsUri, {
  required VmServiceFactory<T> vmServiceFactory,
  Log? log,
  // pingInterval has a default to act as a keep-alive to prevent proxies like
  // Norton antivirus from dropping connections with no traffic for a period.
  Duration? pingInterval = const Duration(seconds: 15),
}) async {
  final WebSocket socket = await WebSocket.connect(wsUri)
    ..pingInterval = pingInterval;
  final StreamController<dynamic> controller = StreamController();
  final Completer streamClosedCompleter = Completer();

  socket.listen(
    (data) => controller.add(data),
    onDone: () => streamClosedCompleter.complete(),
  );

  return vmServiceFactory(
    inStream: controller.stream,
    writeMessage: (String message) => socket.add(message),
    log: log,
    disposeHandler: () => socket.close(),
    streamClosed: streamClosedCompleter.future,
    wsUri: wsUri,
  );
}
