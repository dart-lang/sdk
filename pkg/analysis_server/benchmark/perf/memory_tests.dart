// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:test/test.dart';

import '../../test/integration/lsp_server/integration_tests.dart';
import '../../test/integration/support/integration_tests.dart';
import '../../test/lsp/server_abstract.dart' show ClientCapabilitiesHelperMixin;

/// A server protocol-agnostic interface to the memory test, allowing the same
/// benchmarks to run for both the original protocol and LSP.
abstract class AbstractBenchmarkTest {
  Future<void> get analysisFinished;
  Future<void> closeFile(String filePath);
  Future<void> complete(String filePath, int offset, {required bool isWarmUp});
  void debugStdio();
  Future<int> getMemoryUsage();
  Future<void> openFile(String filePath, String contents);
  Future<void> setUp(String dartSdkPath, List<String> roots);
  Future<void> shutdown();

  Future<void> updateFile(String filePath, String contents);
}

/// An implementation of [AbstractBenchmarkTest] for an 'original protocol'
/// memory test.
class AnalysisServerBenchmarkTest extends AbstractBenchmarkTest {
  final _test = AnalysisServerMemoryUsageTest();

  @override
  Future<void> get analysisFinished => _test.analysisFinished;

  @override
  Future<void> closeFile(String filePath) =>
      _test.sendAnalysisUpdateContent({filePath: RemoveContentOverlay()});

  @override
  Future<void> complete(
    String filePath,
    int offset, {
    required bool isWarmUp,
  }) async {
    await _test.sendCompletionGetSuggestions2(filePath, offset, 100,
        timeout: isWarmUp ? 60 * 1000 : 0);
  }

  @override
  void debugStdio() => _test.debugStdio();

  @override
  Future<int> getMemoryUsage() => _test.getMemoryUsage();

  @override
  Future<void> openFile(String filePath, String contents) async {
    await _test
        .sendAnalysisUpdateContent({filePath: AddContentOverlay(contents)});
    await _test.sendAnalysisSetPriorityFiles([filePath]);
  }

  @override
  Future<void> setUp(String dartSdkPath, List<String> roots) async {
    _test.dartSdkPath = dartSdkPath;
    await _test.setUp();
    await _test.subscribeToStatusNotifications();
    await _test.sendAnalysisSetAnalysisRoots(roots, []);
  }

  @override
  Future<void> shutdown() => _test.shutdown();

  @override
  Future<void> updateFile(String filePath, String contents) =>
      _test.sendAnalysisUpdateContent({filePath: AddContentOverlay(contents)});
}

/// Base class for analysis server memory usage tests.
class AnalysisServerMemoryUsageTest
    extends AbstractAnalysisServerIntegrationTest with ServerMemoryUsageMixin {
  /// Send the server an 'analysis.setAnalysisRoots' command directing it to
  /// analyze [sourceDirectory].
  Future<void> setAnalysisRoot() =>
      sendAnalysisSetAnalysisRoots([sourceDirectory.path], []);

  /// The server is automatically started before every test.
  @override
  Future<void> setUp() async {
    _vmServicePort = await ServiceProtocol._findAvailableSocketPort();

    onAnalysisErrors.listen((AnalysisErrorsParams params) {
      currentAnalysisErrors[params.file] = params.errors;
    });
    onServerError.listen((ServerErrorParams params) {
      // A server error should never happen during an integration test.
      fail('${params.message}\n${params.stackTrace}');
    });
    var serverConnected = Completer<void>();
    onServerConnected.listen((_) {
      outOfTestExpect(serverConnected.isCompleted, isFalse);
      serverConnected.complete();
    });
    return startServer(servicePort: _vmServicePort).then((_) {
      server.listenToOutput(dispatchNotification);
      server.exitCode.then((_) {
        skipShutdown = true;
      });
      return serverConnected.future;
    });
  }

  /// After every test, the server is stopped.
  Future<void> shutdown() async => await shutdownIfNeeded();

  /// Enable [ServerService.STATUS] notifications so that [analysisFinished]
  /// can be used.
  Future<void> subscribeToStatusNotifications() async {
    await sendServerSetSubscriptions([ServerService.STATUS]);
  }
}

/// An implementation of [AbstractBenchmarkTest] for an LSP memory test.
class LspAnalysisServerBenchmarkTest extends AbstractBenchmarkTest
    with ClientCapabilitiesHelperMixin {
  final _test = LspAnalysisServerMemoryUsageTest();
  final PrintableLogger _logger = PrintableLogger();

  /// Track the file contents so we can easily convert offsets (used in
  /// the interface) to Positions required by LSP without having to keep
  /// passing in the contents.
  final Map<String, String> _fileContents = {};
  int _fileVersion = 1;

  @override
  Future<void> get analysisFinished => _test.waitForAnalysisComplete();

  @override
  Future<void> closeFile(String filePath) {
    _fileContents.remove(filePath);
    return _test.closeFile(Uri.file(filePath));
  }

  @override
  Future<void> complete(String filePath, int offset, {required bool isWarmUp}) {
    final contents = _fileContents[filePath]!;
    final position = _test.positionFromOffset(offset, contents);
    return _test.getCompletion(Uri.file(filePath), position);
  }

  @override
  void debugStdio() => _logger.debugStdio();

  @override
  Future<int> getMemoryUsage() => _test.getMemoryUsage();

  @override
  Future<void> openFile(String filePath, String contents) {
    _fileContents[filePath] = contents;
    return _test.openFile(Uri.file(filePath), contents,
        version: _fileVersion++);
  }

  @override
  Future<void> setUp(String dartSdkPath, List<String> roots) async {
    // Use some reasonable default client capabilities that will activate
    // features that will exercise more code that benchmarks should measure
    // (such as applyEdit to allow suggestion sets results to be merged in).
    setDocumentChangesSupport();
    setApplyEditSupport();
    setWorkDoneProgressSupport();
    setCompletionItemSnippetSupport();
    setCompletionItemKinds(
        LspClientCapabilities.defaultSupportedCompletionKinds.toList());

    _test.dartSdkPath = dartSdkPath;
    _test.instrumentationService = InstrumentationLogAdapter(_logger);
    await _test.setUp();
    _test.projectFolderPath = roots.single;
    _test.projectFolderUri = Uri.file(_test.projectFolderPath);
    await _test.initialize();
  }

  @override
  Future<void> shutdown() async {
    _test.tearDown();
    await _logger.shutdown();
  }

  @override
  Future<void> updateFile(String filePath, String contents) {
    _fileContents[filePath] = contents;
    return _test.replaceFile(_fileVersion++, Uri.file(filePath), contents);
  }
}

/// Base class for LSP analysis server memory usage tests.
class LspAnalysisServerMemoryUsageTest
    extends AbstractLspAnalysisServerIntegrationTest
    with ServerMemoryUsageMixin {
  Map<String, List<lsp.Diagnostic>> currentAnalysisErrors = {};

  @override
  void expect(Object? actual, Matcher matcher, {String? reason}) =>
      outOfTestExpect(actual, matcher, reason: reason);

  /// The server is automatically started before every test.
  @override
  Future<void> setUp() async {
    _vmServicePort = await ServiceProtocol._findAvailableSocketPort();
    vmArgs.addAll([
      '--enable-vm-service=$_vmServicePort',
      '-DSILENT_OBSERVATORY=true',
      '--disable-service-auth-codes',
      '--disable-dart-dev'
    ]);
    await super.setUp();

    errorNotificationsFromServer.listen((lsp.NotificationMessage error) {
      // A server error should never happen during an integration test.
      fail('${error.toJson()}');
    });
  }

  /// After every test, the server is stopped.
  Future<void> shutdown() async => this.tearDown();
}

mixin ServerMemoryUsageMixin {
  late int _vmServicePort;

  Future<int> getMemoryUsage() async {
    var uri = Uri.parse('ws://127.0.0.1:$_vmServicePort/ws');
    var service = await ServiceProtocol.connect(uri);
    var vm = await service.call('getVM');

    var total = 0;

    var isolateGroupsRefs = vm['isolateGroups'] as List<Object?>;
    for (var isolateGroupRef
        in isolateGroupsRefs.cast<Map<Object?, Object?>>()) {
      final isolateGroupMemoryUsage = await service.call(
          'getIsolateGroupMemoryUsage',
          {'isolateGroupId': isolateGroupRef['id']});
      var heapUsage = isolateGroupMemoryUsage['heapUsage'] as int;
      var externalUsage = isolateGroupMemoryUsage['externalUsage'] as int;
      total += heapUsage + externalUsage;
    }

    await service.dispose();

    return total;
  }
}

class ServiceProtocol {
  final WebSocket socket;

  int _id = 0;
  final Map<String, Completer<Map<Object?, Object?>>> _completers = {};

  ServiceProtocol._(this.socket) {
    socket.listen(_handleMessage);
  }

  Future<Map<Object?, Object?>> call(String method,
      [Map<Object?, Object?> args = const {}]) {
    var id = '${++_id}';
    var completer = Completer<Map<Object?, Object?>>();
    _completers[id] = completer;
    var messageMap = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'args': args,
      'params': args,
    };
    var message = jsonEncode(messageMap);
    socket.add(message);
    return completer.future;
  }

  Future<void> dispose() => socket.close();

  void _handleMessage(Object? message) {
    if (message is! String) {
      return;
    }

    try {
      var json = jsonDecode(message) as Map<Object?, Object?>;
      if (json.containsKey('id')) {
        var id = json['id'];
        _completers[id]?.complete(json['result'] as Map<Object?, Object?>);
        _completers.remove(id);
      }
    } catch (e) {
      // ignore
    }
  }

  static Future<ServiceProtocol> connect(Uri uri) async {
    var socket = await WebSocket.connect(uri.toString());
    return ServiceProtocol._(socket);
  }

  static Future<int> _findAvailableSocketPort() async {
    var socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    try {
      return socket.port;
    } finally {
      await socket.close();
    }
  }
}
