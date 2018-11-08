// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:async';

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/server.dart';

/// [ServerConnectionHandler] listens to analysis server notifications
/// and detects when a connection has been established with the server.
///
/// Clients may initialize the [connected] field and/or override
/// the [onServerConnected] method to detect when the server has connected.
///
/// Clients may override the [handleServerError method to display information
/// about any server error that occurs. If the [server] field is set,
/// then the server will be shutdown or killed if a server error occurs.
mixin ServerConnectionHandler on NotificationHandler {
  Server server;
  Completer<bool> connected = new Completer();

  void handleServerError(String error, String trace) {}

  @override
  void onServerConnected(ServerConnectedParams params) {
    connected.complete(true);
  }

  void onServerError(ServerErrorParams params) {
    handleServerError(params.message, params.stackTrace);
    server?.stop();
  }

  Future<bool> waitForConnection({Duration timeLimit}) =>
      connected.future.timeout(
        timeLimit ?? const Duration(seconds: 15),
        onTimeout: () => false,
      );
}
