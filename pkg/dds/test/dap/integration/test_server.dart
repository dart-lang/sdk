// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/src/dap/server.dart';

abstract class DapTestServer {
  String get host => _server.host;

  int get port => _server.port;
  DapServer get _server;

  FutureOr<void> stop();
}

/// An instance of a DAP server running in-process (to aid debugging).
///
/// All communication still goes over the socket to ensure all messages are
/// serialized and deserialized but it's not quite the same running out of
/// process.
class InProcessDapTestServer extends DapTestServer {
  final DapServer _server;

  InProcessDapTestServer._(this._server);

  @override
  FutureOr<void> stop() async {
    await _server.stop();
  }

  static Future<InProcessDapTestServer> create() async {
    final DapServer server = await DapServer.create();
    return InProcessDapTestServer._(server);
  }
}
