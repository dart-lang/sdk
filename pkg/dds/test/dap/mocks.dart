// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dap/dap.dart' as dap;
import 'package:dds/dap.dart';
import 'package:dds/src/dap/adapters/dart_cli_adapter.dart';
import 'package:dds/src/dap/adapters/dart_test_adapter.dart';
import 'package:dds/src/dap/isolate_manager.dart';
import 'package:vm_service/vm_service.dart';

/// A [DartCliDebugAdapter] that captures information about the process that
/// will be launched.
class MockDartCliDebugAdapter extends DartCliDebugAdapter {
  final StreamSink<List<int>> stdin;
  final Stream<List<int>> stdout;

  final mockService = MockVmService();

  late bool launchedInTerminal;
  late String executable;
  late List<String> processArgs;
  late String? workingDirectory;
  late Map<String, String>? env;

  factory MockDartCliDebugAdapter() {
    final stdinController = StreamController<List<int>>();
    final stdoutController = StreamController<List<int>>();
    final channel = ByteStreamServerChannel(
        stdinController.stream, stdoutController.sink, null);

    return MockDartCliDebugAdapter.withStreams(
        stdinController.sink, stdoutController.stream, channel);
  }

  MockDartCliDebugAdapter.withStreams(
      this.stdin, this.stdout, ByteStreamServerChannel channel)
      : super(channel) {
    vmService = mockService;
  }

  @override
  Future<bool> isExternalPackageLibrary(ThreadInfo thread, Uri uri) async {
    return uri.isScheme('package') && uri.path.startsWith('external');
  }

  @override
  Future<void> launchAsProcess(
    String executable,
    List<String> processArgs, {
    required String? workingDirectory,
    required Map<String, String>? env,
  }) async {
    launchedInTerminal = false;
    this.executable = executable;
    this.processArgs = processArgs;
    this.workingDirectory = workingDirectory;
    this.env = env;
  }

  @override
  Future<void> launchInEditorTerminal(
    bool debug,
    String terminalKind,
    String executable,
    List<String> processArgs, {
    required String? workingDirectory,
    required Map<String, String>? env,
  }) async {
    launchedInTerminal = true;
    this.executable = executable;
    this.processArgs = processArgs;
    this.workingDirectory = workingDirectory;
    this.env = env;
  }
}

/// A [DartTestDebugAdapter] that captures information about the process that
/// will be launched.
class MockDartTestDebugAdapter extends DartTestDebugAdapter {
  final StreamSink<List<int>> stdin;
  final Stream<List<int>> stdout;

  late String executable;
  late List<String> processArgs;
  late String? workingDirectory;
  late Map<String, String>? env;

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

  @override
  Future<void> launchAsProcess(
    String executable,
    List<String> processArgs, {
    required String? workingDirectory,
    required Map<String, String>? env,
  }) async {
    this.executable = executable;
    this.processArgs = processArgs;
    this.workingDirectory = workingDirectory;
    this.env = env;
  }
}

class MockRequest extends dap.Request {
  static var _requestId = 1;
  MockRequest()
      : super.fromMap({
          'command': 'mock_command',
          'type': 'mock_type',
          'seq': _requestId++,
        });
}

class MockVmService implements VmServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final isolate = IsolateRef(id: 'isolate1');
  final sdkLibrary = LibraryRef(id: 'libSdk', uri: 'dart:core');
  final externalPackageLibrary =
      LibraryRef(id: 'libPkgExternal', uri: 'package:external/foo.dart');
  final localPackageLibrary =
      LibraryRef(id: 'libPkgLocal', uri: 'package:local/foo.dart');

  /// A human-readable string for each request made, useful for verifying in
  /// tests.
  final List<String> requests = [];

  @override
  Future<Success> setLibraryDebuggable(
    String isolateId,
    String libraryId,
    bool isDebuggable,
  ) async {
    requests.add('setLibraryDebuggable($isolateId, $libraryId, $isDebuggable)');
    return Success();
  }

  @override
  Future<Isolate> getIsolate(String isolateId) async {
    return Isolate(
      id: isolate.id,
      libraries: [sdkLibrary, externalPackageLibrary, localPackageLibrary],
    );
  }

  @override
  Future<UriList> lookupResolvedPackageUris(
    String isolateId,
    List<String> uris, {
    bool? local,
  }) async {
    return UriList(uris: uris.map((e) => null).toList());
  }

  @override
  Future<VM> getVM() async {
    return VM(
      isolates: [isolate],
    );
  }
}
