// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:async';

import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:pub_semver/pub_semver.dart';

/// [ConnectionHandler] listens to analysis server notifications
/// and detects when a connection has been established with the server.
///
/// Clients may override [onFailedToConnect], [onProtocolNotSupported],
/// and [onServerError] to display connection failure information.
///
/// Clients may mix-in this class, but may not extend or implement it.
mixin ConnectionHandler implements NotificationHandler {
  final Completer<bool> _connected = Completer();

  /// Clients should implement this method to return the server being managed.
  /// This mixin will stop the server process if a connection cannot be
  /// established or if a server error occurs after connecting.
  Server get server;

  /// Return `true` if the server's protocol is compatible.
  bool checkServerProtocolVersion(Version version) {
    final minVersion = Version.parse(PROTOCOL_VERSION);
    final maxVersion = minVersion.nextBreaking;
    return minVersion <= version && version < maxVersion;
  }

  void onFailedToConnect() {}

  void onProtocolNotSupported(Version version) {}

  @override
  void onServerConnected(ServerConnectedParams params) {
    var version = Version.parse(params.version);
    if (checkServerProtocolVersion(version)) {
      _connected.complete(true);
    } else {
      onProtocolNotSupported(version);
      _connected.complete(false);
      server.stop();
    }
  }

  @override
  void onServerError(ServerErrorParams params) {
    server.stop();
  }

  /// Return a future that completes with a `bool` indicating whether
  /// a connection was successfully established with the server.
  Future<bool> serverConnected({Duration timeLimit}) {
    var future = _connected.future;
    if (timeLimit != null) {
      future = future.timeout(timeLimit, onTimeout: () {
        onFailedToConnect();
        server.stop();
        return false;
      });
    }
    return future;
  }
}
