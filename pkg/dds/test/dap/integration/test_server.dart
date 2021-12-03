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

/// Enable to run from local source (useful in development).
const runFromSource = false;

abstract class DapTestServer {
  Future<void> stop();
  StreamSink<List<int>> get sink;
  Stream<List<int>> get stream;
}

/// An instance of a DAP server running in-process (to aid debugging).
///
/// All communication still goes over the socket to ensure all messages are
/// serialized and deserialized but it's not quite the same running out of
/// process.
class InProcessDapTestServer extends DapTestServer {
  late final DapServer _server;
  final stdinController = StreamController<List<int>>();
  final stdoutController = StreamController<List<int>>();

  StreamSink<List<int>> get sink => stdinController.sink;
  Stream<List<int>> get stream => stdoutController.stream;

  InProcessDapTestServer._(List<String> args) {
    _server = DapServer(
      stdinController.stream,
      stdoutController.sink,
      // Simulate flags based on the args to aid testing.
      enableDds: !args.contains('--no-dds'),
      ipv6: args.contains('--ipv6'),
      enableAuthCodes: !args.contains('--no-auth-codes'),
      test: args.contains('--test'),
    );
  }

  @override
  Future<void> stop() async {
    _server.stop();
  }

  static Future<InProcessDapTestServer> create({
    Logger? logger,
    List<String>? additionalArgs,
  }) async {
    return InProcessDapTestServer._([
      ...?additionalArgs,
    ]);
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

  StreamSink<List<int>> get sink => _process.stdin;
  Stream<List<int>> get stream => _process.stdout;

  OutOfProcessDapTestServer._(
    this._process,
    Logger? logger,
  ) {
    // Treat anything written to stderr as the DAP crashing and fail the test.
    _process.stderr.transform(utf8.decoder).listen((error) {
      logger?.call(error);
      throw error;
    });
    unawaited(_process.exitCode.then((code) {
      final message = 'Out-of-process DAP server terminated with code $code';
      logger?.call(message);
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
    final dartdevScript = path
        .normalize(path.join(ddsLibFolder, '../../dartdev/bin/dartdev.dart'));

    final args = [
      // When running from source, run the script instead of directly using
      // the "dart debug_adapter" command.
      if (runFromSource) dartdevScript,
      'debug_adapter',
      ...?additionalArgs,
    ];

    final _process = await Process.start(Platform.resolvedExecutable, args);

    return OutOfProcessDapTestServer._(_process, logger);
  }
}
