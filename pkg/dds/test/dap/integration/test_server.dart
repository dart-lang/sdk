// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dds/src/dap/server.dart';
import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';

abstract class DapTestServer {
  String get host;
  int get port;
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

  String get host => _server.host;
  int get port => _server.port;

  @override
  FutureOr<void> stop() async {
    await _server.stop();
  }

  static Future<InProcessDapTestServer> create() async {
    final DapServer server = await DapServer.create();
    return InProcessDapTestServer._(server);
  }
}

/// An instance of a DAP server running out-of-process.
///
/// This is how an editor will usually consume DAP so is a more accurate test
/// but will be a little more difficult to debug tests as the debugger will not
/// be attached to the process.
class OutOfProcessDapTestServer extends DapTestServer {
  /// Since each test library will spawn its own server (setup/teardown are
  /// library-scoped) we'll use a different port for each one to avoid any issues
  /// with overlapping tests.
  static var _nextPort = DapServer.defaultPort;

  var _isShuttingDown = false;
  final Process _process;
  final int port;
  final String host;

  OutOfProcessDapTestServer._(this._process, this.host, this.port) {
    // The DAP server should generally not write to stdout/stderr (unless -v is
    // passed), but it may do if it fails to start or crashes. If this happens,
    // ensure these are included in the test output.
    _process.stdout.transform(utf8.decoder).listen(print);
    _process.stderr.transform(utf8.decoder).listen((s) => throw s);
    unawaited(_process.exitCode.then((code) {
      if (!_isShuttingDown && code != 0) {
        throw 'Out-of-process DAP server terminated with code $code';
      }
    }));
  }

  @override
  FutureOr<void> stop() async {
    _isShuttingDown = true;
    await _process.kill();
    await _process.exitCode;
  }

  static Future<OutOfProcessDapTestServer> create() async {
    final ddsEntryScript =
        await Isolate.resolvePackageUri(Uri.parse('package:dds/dds.dart'));
    final ddsLibFolder = path.dirname(ddsEntryScript!.toFilePath());
    final dapServerScript =
        path.join(ddsLibFolder, '../tool/dap/run_server.dart');

    final port = OutOfProcessDapTestServer._nextPort++;
    final host = 'localhost';
    final _process = await Process.start(
      Platform.resolvedExecutable,
      [
        dapServerScript,
        '--host=$host',
        '--port=$port',
      ],
    );

    return OutOfProcessDapTestServer._(_process, host, port);
  }
}
