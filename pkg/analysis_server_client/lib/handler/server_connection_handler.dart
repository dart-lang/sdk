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
import 'package:pub_semver/pub_semver.dart';

/// [ServerConnectionHandler] listens to analysis server notifications
/// and detects when a connection has been established with the server.
///
/// Clients may override [handleFailedToConnect], [handleProtocolNotSupported],
/// and [handleServerError] to display connection failure information.
mixin ServerConnectionHandler on NotificationHandler {
  Completer<bool> _connected = new Completer();

  /// Clients should implement this method to return the server being managed.
  /// This mixin will stop the server process if a connection cannot be
  /// established or if a server error occurs after connecting.
  Server get server;

  void handleFailedToConnect() {}

  void handleProtocolNotSupported(Version version) {}

  void handleServerError(String error, String trace) {}

  @override
  void onServerConnected(ServerConnectedParams params) {
    final minVersion = new Version.parse(PROTOCOL_VERSION);
    final maxVersion = minVersion.nextBreaking;
    final version = new Version.parse(params.version);
    if (minVersion <= version && version < maxVersion) {
      _connected.complete(true);
    } else {
      handleProtocolNotSupported(version);
      _connected.complete(false);
      server.stop();
    }
  }

  void onServerError(ServerErrorParams params) {
    handleServerError(params.message, params.stackTrace);
    server.stop();
  }

  /// Return a future that completes with a `bool` indicating whether
  /// a connection was successfully established with the server.
  Future<bool> serverConnected({Duration timeLimit}) {
    Future<bool> future = _connected.future;
    if (timeLimit != null) {
      future = future.timeout(
        timeLimit ?? const Duration(seconds: 15),
        onTimeout: () {
          handleFailedToConnect();
          server.stop();
          return false;
        },
      );
    }
    return future;
  }
}
