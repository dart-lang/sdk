// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dap/dap.dart' as dap;
import 'package:dds/dap.dart' hide Response;
import 'package:dds/dds.dart';
import 'package:dds/dds_launcher.dart';
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

  UriConverter? _uriConverter;

  @override
  UriConverter? uriConverter() => _uriConverter;

  void setUriConverter(UriConverter uriConverter) {
    _uriConverter = uriConverter;
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

  UriConverter? get currentUriConverter => _uriConverter;
  UriConverter? _uriConverter;

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

  @override
  UriConverter? uriConverter() {
    return _uriConverter;
  }

  void setUriConverter(UriConverter uriConverter) {
    _uriConverter = uriConverter;
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

class MockVmService implements VmService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final isolate1 = IsolateRef(id: 'isolate1');
  final isolate2 = IsolateRef(id: 'isolate2');
  final sdkLibrary = LibraryRef(id: 'libSdk', uri: 'dart:core');
  final externalPackageLibrary =
      LibraryRef(id: 'libPkgExternal', uri: 'package:external/foo.dart');
  final localPackageLibrary =
      LibraryRef(id: 'libPkgLocal', uri: 'package:local/foo.dart');

  /// A human-readable string for each request made, useful for verifying in
  /// tests.
  final List<String> requests = [];

  /// A list of methods that were called on the Mock VM Service.
  List<({String method, String? isolateId, Map<String, dynamic>? args})>
      calledMethods = [];

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
    return {isolate1.id, isolate2.id}.contains(isolateId)
        ? Isolate(
            id: isolateId,
            libraries: [
              sdkLibrary,
              externalPackageLibrary,
              localPackageLibrary
            ],
          )
        : throw SentinelException.parse('getIsolate', {});
  }

  List<String>? receivedLookupResolvedPackageUris;
  UriList? lookupResolvedPackageUrisResponse;

  @override
  Future<UriList> lookupResolvedPackageUris(
    String isolateId,
    List<String> uris, {
    bool? local,
  }) async {
    receivedLookupResolvedPackageUris = uris;
    return lookupResolvedPackageUrisResponse ??
        UriList(uris: uris.map((e) => null).toList());
  }

  @override
  Future<VM> getVM() async {
    return VM(
      isolates: [isolate1, isolate2],
    );
  }

  @override
  Future<Response> callMethod(
    String method, {
    String? isolateId,
    Map<String, dynamic>? args,
  }) async {
    calledMethods.add((method: method, isolateId: isolateId, args: args));

    // Some DDS methods are implemented as extensions so we can't override
    // them in the mock, we need to override callMethod and handle them here
    // (and provide their responses) instead.

    if (method == 'getDartDevelopmentServiceVersion') {
      return Version(major: 2, minor: 0);
    } else if (method == 'readyToResume') {
      isolateId ??= args != null ? args['isolateId'] : null;
      return {isolate1.id, isolate2.id}.contains(isolateId)
          ? Success()
          : throw SentinelException.parse(method, {});
    }

    throw 'MockVmService does not handle $method ($isolateId, $args)';
  }

  @override
  Future<Success> resume(
    String isolateId, {
    String? step,
    int? frameIndex,
  }) async {
    // Do nothing, just pretend.
    return {isolate1.id, isolate2.id}.contains(isolateId)
        ? Success()
        : throw SentinelException.parse('resume', {});
  }

  @override
  Future<Success> setIsolatePauseMode(
    String isolateId, {
    /*ExceptionPauseMode*/ String? exceptionPauseMode,
    bool? shouldPauseOnExit,
  }) async {
    // Do nothing, just pretend.
    return {isolate1.id, isolate2.id}.contains(isolateId)
        ? Success()
        : throw SentinelException.parse('setIsolatePauseMode', {});
  }
}

class MockDartDevelopmentServiceLauncher
    implements DartDevelopmentServiceLauncher {
  MockDartDevelopmentServiceLauncher();

  @override
  Uri? get devToolsUri => throw UnimplementedError();

  @override
  Future<void> get done => throw UnimplementedError();

  @override
  Future<void> shutdown() {
    throw UnimplementedError();
  }

  @override
  Uri get sseUri => throw UnimplementedError();

  @override
  Uri get uri => throw UnimplementedError();

  @override
  Uri get wsUri => Uri(scheme: 'ws', host: 'localhost');

  @override
  Uri? get dtdUri => throw UnimplementedError();
}
