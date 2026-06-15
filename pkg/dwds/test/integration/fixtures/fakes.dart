// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds/asset_reader.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/debugging/dart_runtime_debugger.dart';
import 'package:dwds/src/debugging/execution_context.dart';
import 'package:dwds/src/debugging/inspector.dart';
import 'package:dwds/src/debugging/instance.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/debugging/modules.dart';
import 'package:dwds/src/debugging/remote_debugger.dart';
import 'package:dwds/src/debugging/webkit_debugger.dart';
import 'package:dwds/src/handlers/socket_connections.dart';
import 'package:dwds/src/loaders/require.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/utilities/objects.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:vm_service/vm_service.dart';

/// A library of fake/stub implementations of our classes and their supporting
/// classes (e.g. WipConnection) for unit testing.
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'debugger_data.dart';
import 'utilities.dart';

/// Constructs a trivial Isolate we can use when we need to provide one but
/// don't want go through initialization.
Isolate get simpleIsolate => Isolate(
  id: '1',
  number: '1',
  name: 'fake',
  libraries: [],
  exceptionPauseMode: 'abc',
  breakpoints: [],
  pauseOnExit: false,
  pauseEvent: null,
  startTime: 0,
  livePorts: 0,
  runnable: false,
  isSystemIsolate: false,
  isolateFlags: [],
);

class FakeChromeAppInspector extends FakeInspector
    implements ChromeAppInspector {
  FakeChromeAppInspector(this._remoteDebugger, {required super.fakeIsolate});
  final WebkitDebugger _remoteDebugger;

  @override
  Future<RemoteObject> callFunction(
    String function,
    Iterable<String> argumentIds,
  ) async {
    functionsCalled.add(function);
    return RemoteObject({'type': 'string', 'value': 'true'});
  }

  @override
  Future<InstanceRef?> instanceRefFor(Object value) async =>
      ChromeAppInstanceHelper.kNullInstanceRef;

  @override
  Future<Obj> getObject(String objectId, {int? offset, int? count}) async =>
      Obj.parse({})!;

  @override
  Future<List<Property>> getProperties(
    String objectId, {
    int? offset,
    int? count,
    int? length,
  }) async {
    final response = await _remoteDebugger.sendCommand(
      'Runtime.getProperties',
      params: {'objectId': objectId, 'ownProperties': true},
    );
    final result = response.result?['result'] as List<dynamic>? ?? [];
    return result
        .map<Property>((Object? each) => Property(each as Map<String, dynamic>))
        .toList();
  }

  @override
  bool isDisplayableObject(Object? object) => true;

  @override
  bool isNativeJsError(InstanceRef instanceRef) => false;
}

class FakeInspector implements AppInspector {
  final List<String> functionsCalled = [];
  FakeInspector({required this.fakeIsolate});

  Isolate fakeIsolate;

  @override
  Object noSuchMethod(Invocation invocation) {
    throw UnsupportedError('This is a fake');
  }

  @override
  Future<void> initialize({ModifiedModuleReport? modifiedModuleReport}) async {}

  @override
  Future<ScriptList> getScripts() async => ScriptList(scripts: []);

  @override
  Future<ScriptRef> scriptRefFor(String uri) async =>
      ScriptRef(id: 'fake', uri: 'fake://uri');

  @override
  ScriptRef? scriptWithId(String? scriptId) => null;

  @override
  Isolate get isolate => fakeIsolate;

  @override
  IsolateRef get isolateRef => IsolateRef(
    id: fakeIsolate.id,
    number: fakeIsolate.number,
    name: fakeIsolate.name,
    isSystemIsolate: fakeIsolate.isSystemIsolate,
  );
}

class FakeSseConnection implements SseSocketConnection {
  /// A [StreamController] for incoming messages on SSE connection.
  final controllerIncoming = StreamController<String>();

  /// A [StreamController] for outgoing messages on SSE connection.
  final controllerOutgoing = StreamController<String>();

  @override
  bool get isInKeepAlivePeriod => false;

  @override
  StreamSink<String> get sink => controllerOutgoing.sink;

  @override
  Stream<String> get stream => controllerIncoming.stream;

  @override
  void shutdown() {}
}

class FakeModules implements Modules {
  final String _library;
  final String _module;
  final String _path;

  FakeModules({
    this._library = 'main.dart',
    this._module = 'main',
    this._path = 'web/main.dart',
  });

  @override
  Future<void> initialize(
    String entrypoint, {
    ModifiedModuleReport? modifiedModuleReport,
  }) async {}

  @override
  Future<Uri> libraryForSource(String serverPath) async => Uri(path: _library);

  @override
  Future<Uri> libraryOrPartForSource(String serverPath) async =>
      Uri(path: _library);

  @override
  Future<String> moduleForSource(String serverPath) async => _module;

  @override
  Future<Set<String>> sourcesForModule(String module) async => {_path};

  @override
  Future<Map<String, String>> modules() async => {_path: _module};

  @override
  Future<String> moduleForLibrary(String libraryUri) async => _module;

  @override
  Future<String?> getRuntimeScriptIdForModule(
    String entrypoint,
    String module,
  ) async => null;
}

class FakeWebkitDebugger implements WebkitDebugger {
  final Map<String, WipScript>? _scripts;
  @override
  Future disable() async => null;

  @override
  Future enable() async => null;

  FakeWebkitDebugger({this._scripts}) {
    final buildSettings = TestBuildSettings.dart(
      appEntrypoint: Uri.parse('package:fakeapp/main.dart'),
    );
    setGlobalsForTesting(
      toolConfiguration: TestToolConfiguration.withLoadStrategy(
        loadStrategy: RequireStrategy(
          ReloadConfiguration.none,
          (_) async => {},
          (_) async => {},
          (_, _) async => null,
          (MetadataProvider _, String _) async => '',
          (MetadataProvider _, String _) async => '',
          (String _) => '',
          (MetadataProvider _) async => <String, ModuleInfo>{},
          FakeAssetReader(),
          buildSettings,
        ),
      ),
    );
  }

  @override
  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer) =>
      Stream.empty();

  @override
  Future<String> getScriptSource(String scriptId) async => '';

  Stream<WipDomain>? get onClosed => null;

  @override
  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared =>
      const Stream.empty();

  @override
  late Stream<DebuggerPausedEvent> onPaused;

  @override
  Stream<DebuggerResumedEvent> get onResumed => const Stream.empty();

  @override
  Stream<ScriptParsedEvent> get onScriptParsed => const Stream.empty();

  @override
  Stream<TargetCrashedEvent> get onTargetCrashed => const Stream.empty();

  @override
  Future<WipResponse> pause() async => fakeWipResponse;

  @override
  Future<WipResponse> resume() async => fakeWipResponse;

  @override
  Map<String, WipScript> get scripts => _scripts!;

  List<WipResponse> results = variables1;
  int resultsReturned = 0;

  @override
  Future<WipResponse> sendCommand(
    String command, {
    Map<String, dynamic>? params,
  }) async {
    // Force the results that we expect for looking up the variables.
    if (command == 'Runtime.getProperties') {
      return results[resultsReturned++];
    }
    return fakeWipResponse;
  }

  @override
  Future<WipResponse> setPauseOnExceptions(PauseState state) async =>
      fakeWipResponse;

  @override
  Future<WipResponse> removeBreakpoint(String breakpointId) async =>
      fakeWipResponse;

  @override
  Future<WipResponse> stepInto({Map<String, dynamic>? params}) async =>
      fakeWipResponse;

  @override
  Future<WipResponse> stepOut() async => fakeWipResponse;

  @override
  Future<WipResponse> stepOver({Map<String, dynamic>? params}) async =>
      fakeWipResponse;

  @override
  Stream<ConsoleAPIEvent> get onConsoleAPICalled => const Stream.empty();

  @override
  Stream<ExceptionThrownEvent> get onExceptionThrown => const Stream.empty();

  @override
  Future<void> close() async {}

  @override
  Stream<WipConnection> get onClose => const Stream.empty();

  @override
  Future<RemoteObject> evaluate(
    String expression, {
    bool? returnByValue,
    int? contextId,
  }) async => RemoteObject({});

  @override
  Future<RemoteObject> evaluateOnCallFrame(
    String callFrameId,
    String expression,
  ) async {
    return RemoteObject(<String, dynamic>{});
  }

  @override
  Future<List<WipBreakLocation>> getPossibleBreakpoints(
    WipLocation start,
  ) async => [];

  @override
  Future<WipResponse> enablePage() async => fakeWipResponse;

  @override
  Future<WipResponse> pageReload() async => fakeWipResponse;

  @override
  Future<void> Function()? onReconnect;
}

/// Fake execution context that is needed for id only
class FakeExecutionContext extends ExecutionContext {
  @override
  Future<int> get id async {
    return 0;
  }

  FakeExecutionContext();
}

class FakeStrategy extends LoadStrategy {
  final BuildSettings _buildSettings;

  FakeStrategy(
    super.assetReader, {
    super.packageConfigPath,
    BuildSettings? buildSettings,
  }) : _buildSettings =
           buildSettings ??
           TestBuildSettings.dart(
             appEntrypoint: Uri.parse('package:myapp/main.dart'),
           );

  @override
  Future<String> bootstrapFor(String entrypoint) async => 'dummy_bootstrap';

  @override
  shelf.Handler get handler =>
      (request) => (request.url.path == 'someDummyPath')
      ? shelf.Response.ok('some dummy response')
      : shelf.Response.notFound('someDummyPath');

  @override
  BuildSettings get buildSettings => _buildSettings;

  @override
  String get id => 'dummy-id';

  @override
  String get moduleFormat => 'dummy-format';

  @override
  String get loadLibrariesModule => '';

  @override
  String get loadModuleSnippet => '';

  @override
  late final DartRuntimeDebugger dartRuntimeDebugger = DartRuntimeDebugger(
    loadStrategy: this,
    useLibraryBundleExpression: false,
  );

  @override
  ReloadConfiguration get reloadConfiguration => ReloadConfiguration.none;

  @override
  String? g3RelativePath(String absolutePath) => null;

  @override
  String loadClientSnippet(String clientScript) => 'dummy-load-client-snippet';

  @override
  Future<String?> moduleForServerPath(
    String entrypoint,
    String serverPath,
  ) async => '';

  @override
  Future<String> serverPathForModule(String entrypoint, String module) async =>
      '';

  @override
  Future<String> sourceMapPathForModule(
    String entrypoint,
    String module,
  ) async => '';

  @override
  String? serverPathForAppUri(String appUri) => '';

  @override
  MetadataProvider metadataProviderFor(String entrypoint) =>
      createProvider(entrypoint, FakeAssetReader());

  @override
  Future<Map<String, ModuleInfo>> moduleInfoForEntrypoint(String entrypoint) =>
      throw UnimplementedError();
}

class FakeAssetReader implements AssetReader {
  String? metadata;
  final String? _dartSource;
  final String? _sourceMap;
  FakeAssetReader({this.metadata, this._dartSource, this._sourceMap});

  @override
  String get basePath => '';

  @override
  Future<String> dartSourceContents(String serverPath) {
    return _throwUnimplementedOrReturnContents(_dartSource);
  }

  @override
  Future<String> metadataContents(String serverPath) {
    return _throwUnimplementedOrReturnContents(metadata);
  }

  @override
  Future<String> sourceMapContents(String serverPath) {
    return _throwUnimplementedOrReturnContents(_sourceMap);
  }

  @override
  Future<void> close() async {}

  Future<String> _throwUnimplementedOrReturnContents(String? contents) async {
    if (contents == null) throw UnimplementedError();
    return contents;
  }
}

class FakeExpressionCompiler implements ExpressionCompiler {
  @override
  Future<ExpressionCompilationResult> compileExpressionToJs(
    String isolateId,
    String libraryUri,
    String scriptUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  ) async => ExpressionCompilationResult(expression, false);

  @override
  Future<bool> updateDependencies(Map<String, ModuleInfo> modules) async =>
      true;

  @override
  Future<void> initialize(CompilerOptions options) async {}
}

final fakeWipResponse = WipResponse({
  'id': 1,
  'result': {'fake': ''},
});

final fakeFailingWipResponse = WipResponse({'result': 'Error: Bad request'});
