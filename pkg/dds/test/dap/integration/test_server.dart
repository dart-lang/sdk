// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show Random;

import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/server.dart';
import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';

final _random = Random();

abstract class DapTestServer {
  List<String> get errorLogs;
  String get host;
  int get port;
  Future<void> stop();
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
  List<String> get errorLogs => const []; // In-proc errors just throw in-line.

  @override
  Future<void> stop() async {
    await _server.stop();
  }

  static Future<InProcessDapTestServer> create({Logger? logger}) async {
    final DapServer server = await DapServer.create(logger: logger);
    return InProcessDapTestServer._(server);
  }
}

/// An instance of a DAP server running out-of-process.
///
/// This is how an editor will usually consume DAP so is a more accurate test
/// but will be a little more difficult to debug tests as the debugger will not
/// be attached to the process.
class OutOfProcessDapTestServer extends DapTestServer {
  /// To avoid issues with port bindings if multiple test libraries are run
  /// concurrently (in their own processes), start from a random port between
  /// [DapServer.defaultPort] and [DapServer.defaultPort] + 5000.
  ///
  /// This number will then be increased should multiple libraries run within
  /// this same process.
  static var _nextPort = DapServer.defaultPort + _random.nextInt(5000);

  var _isShuttingDown = false;
  final Process _process;
  final int port;
  final String host;
  final List<String> _errors = [];

  List<String> get errorLogs => _errors;

  OutOfProcessDapTestServer._(
    this._process,
    this.host,
    this.port,
    Logger? logger,
  ) {
    // The DAP server should generally not write to stdout/stderr (unless -v is
    // passed), but it may do if it fails to start or crashes. If this happens,
    // and there's no logger, print to stdout.
    _process.stdout.transform(utf8.decoder).listen(logger ?? print);
    _process.stderr.transform(utf8.decoder).listen((error) {
      logger?.call(error);
      _errors.add(error);
      throw error;
    });
    unawaited(_process.exitCode.then((code) {
      final message = 'Out-of-process DAP server terminated with code $code';
      logger?.call(message);
      _errors.add(message);
      if (!_isShuttingDown && code != 0) {
        throw message;
      }
    }));
  }

  @override
  Future<void> stop() async {
    _isShuttingDown = true;
    await _process.kill();
    await _process.exitCode;
  }

  static Future<OutOfProcessDapTestServer> create({
    Logger? logger,
    List<String>? additionalArgs,
  }) async {
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
        'dap',
        '--host=$host',
        '--port=$port',
        ...?additionalArgs,
        if (logger != null) '--verbose'
      ],
    );

    return OutOfProcessDapTestServer._(_process, host, port, logger);
  }
}
