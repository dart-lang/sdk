// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/dap.dart';
import 'package:dds/src/dap/adapters/dart_cli_adapter.dart';
import 'package:dds/src/dap/adapters/dart_test_adapter.dart';

/// A [DartCliDebugAdapter] that captures what process/args will be launched.
class MockDartCliDebugAdapter extends DartCliDebugAdapter {
  final StreamSink<List<int>> stdin;
  final Stream<List<int>> stdout;

  late bool launchedInTerminal;
  late String executable;
  late List<String> processArgs;

  factory MockDartCliDebugAdapter() {
    final stdinController = StreamController<List<int>>();
    final stdoutController = StreamController<List<int>>();
    final channel = ByteStreamServerChannel(
        stdinController.stream, stdoutController.sink, null);

    return MockDartCliDebugAdapter._(
        stdinController.sink, stdoutController.stream, channel);
  }

  MockDartCliDebugAdapter._(
      this.stdin, this.stdout, ByteStreamServerChannel channel)
      : super(channel);

  Future<void> launchAsProcess(
    String executable,
    List<String> processArgs,
  ) async {
    this.launchedInTerminal = false;
    this.executable = executable;
    this.processArgs = processArgs;
  }

  Future<void> launchInEditorTerminal(
    bool debug,
    String terminalKind,
    String executable,
    List<String> processArgs,
  ) async {
    this.launchedInTerminal = true;
    this.executable = executable;
    this.processArgs = processArgs;
  }
}

/// A [DartTestDebugAdapter] that captures what process/args will be launched.
class MockDartTestDebugAdapter extends DartTestDebugAdapter {
  final StreamSink<List<int>> stdin;
  final Stream<List<int>> stdout;

  late String executable;
  late List<String> processArgs;

  factory MockDartTestDebugAdapter() {
    final stdinController = StreamController<List<int>>();
    final stdoutController = StreamController<List<int>>();
    final channel = ByteStreamServerChannel(
        stdinController.stream, stdoutController.sink, null);

    return MockDartTestDebugAdapter._(
      stdinController.sink,
      stdoutController.stream,
      channel,
    );
  }

  MockDartTestDebugAdapter._(
      this.stdin, this.stdout, ByteStreamServerChannel channel)
      : super(channel);

  Future<void> launchAsProcess(
    String executable,
    List<String> processArgs,
  ) async {
    this.executable = executable;
    this.processArgs = processArgs;
  }
}

class MockRequest extends Request {
  static var _requestId = 1;
  MockRequest()
      : super.fromMap({
          'command': 'mock_command',
          'type': 'mock_type',
          'seq': _requestId++,
        });
}
