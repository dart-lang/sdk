// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dds/src/dap/logging.dart';
import 'package:dds/src/dap/server.dart';
import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';

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
    // Treat anything written to stderr as the DAP crashing and fail the test.
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

    final _process = await Process.start(
      Platform.resolvedExecutable,
      [
        dapServerScript,
        'dap',
        ...?additionalArgs,
        if (logger != null) '--verbose'
      ],
    );

    final startedCompleter = Completer<void>();
    late String host;
    late int port;

    // Scrape the `started` event to get the host/port. Any other output
    // should be sent to the logger (as it may be verbose output for diagnostic
    // purposes).
    _process.stdout.transform(utf8.decoder).listen((text) {
      if (!startedCompleter.isCompleted) {
        final event = jsonDecode(text);
        if (event['state'] == 'started') {
          host = event['dapHost'];
          port = event['dapPort'];
          startedCompleter.complete();
          return;
        }
      }
      logger?.call(text);
    });
    await startedCompleter.future;

    return OutOfProcessDapTestServer._(_process, host, port, logger);
  }
}
