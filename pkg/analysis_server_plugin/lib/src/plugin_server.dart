// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_processor.dart';
import 'package:analysis_server_plugin/src/registry.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/lint/lint_rule_timers.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

typedef _ErrorAndProtocolError = ({
  AnalysisError error,
  protocol.AnalysisError protocolError,
});

typedef _PluginState = ({
  AnalysisContext analysisContext,
  List<_ErrorAndProtocolError> errors,
});

/// The server that communicates with the analysis server, passing requests and
/// responses between the analysis server and individual plugins.
class PluginServer {
  /// The communication channel being used to communicate with the analysis
  /// server.
  late PluginCommunicationChannel _channel;

  final OverlayResourceProvider _resourceProvider;

  late final ByteStore _byteStore =
      MemoryCachingByteStore(NullByteStore(), 1024 * 1024 * 256);

  AnalysisContextCollectionImpl? _contextCollection;

  String? _sdkPath;

  final List<Plugin> _plugins;

  final _registry = PluginRegistryImpl();

  /// The recent state of analysis reults, to be cleared on file changes.
  final _recentState = <String, _PluginState>{};

  PluginServer({
    required ResourceProvider resourceProvider,
    required List<Plugin> plugins,
  })  : _resourceProvider = OverlayResourceProvider(resourceProvider),
        _plugins = plugins {
    for (var plugin in plugins) {
      plugin.register(_registry);
    }
  }

  /// Handles an 'analysis.setContextRoots' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  // TODO(srawlins): Unnecessary??
  Future<protocol.AnalysisSetContextRootsResult> handleAnalysisSetContextRoots(
      protocol.AnalysisSetContextRootsParams parameters) async {
    var currentContextCollection = _contextCollection;
    if (currentContextCollection != null) {
      _contextCollection = null;
      await currentContextCollection.dispose();
    }

    var includedPaths = parameters.roots.map((e) => e.root).toList();
    var contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: _resourceProvider,
      includedPaths: includedPaths,
      byteStore: _byteStore,
      sdkPath: _sdkPath,
      fileContentCache: FileContentCache(_resourceProvider),
    );
    _contextCollection = contextCollection;
    await _analyzeAllFilesInContextCollection(
        contextCollection: contextCollection);
    return protocol.AnalysisSetContextRootsResult();
  }

  /// Handles an 'edit.getFixes' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.EditGetFixesResult> handleEditGetFixes(
      protocol.EditGetFixesParams parameters) async {
    // TODO(srawlins): Run this all in `runZonedGuarded`.
    var path = parameters.file;
    var offset = parameters.offset;

    var recentState = _recentState[path];
    if (recentState == null) {
      return protocol.EditGetFixesResult(const []);
    }

    var (:analysisContext, :errors) = recentState;

    var libraryResult =
        await analysisContext.currentSession.getResolvedLibrary(path);
    if (libraryResult is! ResolvedLibraryResult) {
      return protocol.EditGetFixesResult(const []);
    }
    var result = await analysisContext.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      return protocol.EditGetFixesResult(const []);
    }

    var lintAtOffset = errors.where((error) => error.error.offset == offset);
    if (lintAtOffset.isEmpty) return protocol.EditGetFixesResult(const []);

    var errorFixesList = <protocol.AnalysisErrorFixes>[];

    var workspace = DartChangeWorkspace([analysisContext.currentSession]);
    for (var (:error, :protocolError) in lintAtOffset) {
      var context = DartFixContext(
        // TODO(srawlins): Use a real instrumentation service. Other
        // implementations get InstrumentationService from AnalysisServer.
        instrumentationService: InstrumentationService.NULL_SERVICE,
        workspace: workspace,
        resolvedResult: result,
        error: error,
      );

      List<Fix> fixes;
      try {
        fixes = await computeFixes(context);
      } on InconsistentAnalysisException {
        // TODO(srawlins): Is it important to at least log this? Or does it
        // happen on the regular?
        fixes = [];
      }

      if (fixes.isNotEmpty) {
        fixes.sort(Fix.compareFixes);
        var errorFixes = protocol.AnalysisErrorFixes(protocolError);
        errorFixesList.add(errorFixes);
        for (var fix in fixes) {
          errorFixes.fixes.add(protocol.PrioritizedSourceChange(1, fix.change));
        }
      }
    }

    return protocol.EditGetFixesResult(errorFixesList);
  }

  /// Handles a 'plugin.versionCheck' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.PluginVersionCheckResult> handlePluginVersionCheck(
      protocol.PluginVersionCheckParams parameters) async {
    // TODO(srawlins): It seems improper for _this_ method to be the point where
    // the SDK path is configured...
    _sdkPath = parameters.sdkPath;
    return protocol.PluginVersionCheckResult(
        true, 'Plugin Server', '0.0.1', ['*.dart']);
  }

  /// Initializes each of the registered plugins.
  Future<void> initialize() async {
    await Future.wait(
        _plugins.map((p) => p.start()).whereType<Future<Object?>>());
  }

  /// Starts this plugin by listening to the given communication [channel].
  void start(PluginCommunicationChannel channel) {
    _channel = channel;
    _channel.listen(_handleRequest,
        // TODO(srawlins): Implement.
        onError: () {},
        // TODO(srawlins): Implement.
        onDone: () {});
  }

  /// This method is invoked when a new instance of [AnalysisContextCollection]
  /// is created, so the plugin can perform initial analysis of analyzed files.
  ///
  /// By default analyzes every [AnalysisContext] with [_analyzeFiles].
  Future<void> _analyzeAllFilesInContextCollection({
    required AnalysisContextCollection contextCollection,
  }) async {
    await _forAnalysisContexts(contextCollection, (analysisContext) async {
      var paths = analysisContext.contextRoot.analyzedFiles().toList();
      await _analyzeFiles(
        analysisContext: analysisContext,
        paths: paths,
      );
    });
  }

  /// Analyzes the file at the given [path].
  Future<void> _analyzeFile(
      {required AnalysisContext analysisContext, required String path}) async {
    // TODO(srawlins): Run this all in `runZonedGuarded`.
    var file = _resourceProvider.getFile(path);
    var analysisOptions = analysisContext.getAnalysisOptionsForFile(file);
    var lints = await _computeLints(
      analysisContext,
      path,
      analysisOptions: analysisOptions as AnalysisOptionsImpl,
    );
    _channel.sendNotification(
        protocol.AnalysisErrorsParams(path, lints).toNotification());
  }

  /// Analyzes the files at the given [paths].
  Future<void> _analyzeFiles({
    required AnalysisContext analysisContext,
    required List<String> paths,
  }) async {
    // TODO(srawlins): Implement "priority files" and analyze them first.
    // TODO(srawlins): Analyze libraries instead of files, for efficiency.
    for (var path in paths.toSet()) {
      await _analyzeFile(
        analysisContext: analysisContext,
        path: path,
      );
    }
  }

  Future<List<protocol.AnalysisError>> _computeLints(
    AnalysisContext analysisContext,
    String path, {
    required AnalysisOptionsImpl analysisOptions,
  }) async {
    var libraryResult =
        await analysisContext.currentSession.getResolvedLibrary(path);
    if (libraryResult is! ResolvedLibraryResult) {
      return [];
    }
    var result = await analysisContext.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      return [];
    }
    var listener = RecordingErrorListener();
    var errorReporter = ErrorReporter(listener, result.libraryElement.source);

    var currentUnit = LintRuleUnitContext(
      file: result.file,
      content: result.content,
      errorReporter: errorReporter,
      unit: result.unit,
    );
    var allUnits = [
      for (var unit in libraryResult.units)
        LintRuleUnitContext(
          file: unit.file,
          content: unit.content,
          errorReporter: errorReporter,
          unit: unit.unit,
        ),
    ];

    var enableTiming = analysisOptions.enableTiming;
    var nodeRegistry = NodeLintRegistry(enableTiming);

    var context = LinterContextWithResolvedResults(
      allUnits,
      currentUnit,
      libraryResult.element.typeProvider,
      libraryResult.element.typeSystem as TypeSystemImpl,
      (analysisContext.currentSession as AnalysisSessionImpl)
          .inheritanceManager,
      // TODO(srawlins): Support 'package' parameter.
      null,
    );
    // TODO(srawlins): Distinguish between registered rules and enabled rules.
    for (var rule in _registry.registeredRules) {
      rule.reporter = errorReporter;
      var timer = enableTiming ? lintRuleTimers.getTimer(rule) : null;
      timer?.start();
      rule.registerNodeProcessors(nodeRegistry, context);
      timer?.stop();
    }

    var exceptionHandler = LinterExceptionHandler(
            propagateExceptions: analysisOptions.propagateLinterExceptions)
        .logException;
    currentUnit.unit.accept(LinterVisitor(nodeRegistry, exceptionHandler));
    // The list of the `AnalysisError`s and their associated
    // `protocol.AnalysisError`s.
    var errorsAndProtocolErrors = [
      for (var e in listener.errors)
        (
          error: e,
          protocolError: protocol.AnalysisError(
            protocol.AnalysisErrorSeverity.INFO,
            protocol.AnalysisErrorType.STATIC_WARNING,
            _locationFor(currentUnit.unit, path, e),
            e.message,
            e.errorCode.name,
            correction: e.correction,
            // TODO(srawlins): Use a valid value here.
            hasFix: true,
          )
        ),
    ];
    _recentState[path] = (
      analysisContext: analysisContext,
      errors: [...errorsAndProtocolErrors],
    );
    return errorsAndProtocolErrors.map((e) => e.protocolError).toList();
  }

  /// Invokes [fn] for all analysis contexts.
  Future<void> _forAnalysisContexts(
    AnalysisContextCollection contextCollection,
    Future<void> Function(AnalysisContext analysisContext) fn,
  ) async {
    for (var analysisContext in contextCollection.contexts) {
      await fn(analysisContext);
    }
  }

  /// Computes the response for the given [request].
  Future<Response?> _getResponse(Request request, int requestTime) async {
    ResponseResult? result;
    switch (request.method) {
      case protocol.ANALYSIS_REQUEST_GET_NAVIGATION:
      case protocol.ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS:
        result = null;
      case protocol.ANALYSIS_REQUEST_SET_CONTEXT_ROOTS:
        var params =
            protocol.AnalysisSetContextRootsParams.fromRequest(request);
        result = await handleAnalysisSetContextRoots(params);
      case protocol.ANALYSIS_REQUEST_SET_PRIORITY_FILES:
      case protocol.ANALYSIS_REQUEST_SET_SUBSCRIPTIONS:
      case protocol.ANALYSIS_REQUEST_UPDATE_CONTENT:
      case protocol.COMPLETION_REQUEST_GET_SUGGESTIONS:
      case protocol.EDIT_REQUEST_GET_ASSISTS:
      case protocol.EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS:
        result = null;
      case protocol.EDIT_REQUEST_GET_FIXES:
        var params = protocol.EditGetFixesParams.fromRequest(request);
        result = await handleEditGetFixes(params);
      case protocol.EDIT_REQUEST_GET_REFACTORING:
        result = null;
      case protocol.PLUGIN_REQUEST_SHUTDOWN:
        _channel.sendResponse(protocol.PluginShutdownResult()
            .toResponse(request.id, requestTime));
        _channel.close();
        return null;
      case protocol.PLUGIN_REQUEST_VERSION_CHECK:
        var params = protocol.PluginVersionCheckParams.fromRequest(request);
        result = await handlePluginVersionCheck(params);
    }
    if (result == null) {
      return Response(request.id, requestTime,
          error: RequestErrorFactory.unknownRequest(request.method));
    }
    return result.toResponse(request.id, requestTime);
  }

  Future<void> _handleRequest(Request request) async {
    var requestTime = DateTime.now().millisecondsSinceEpoch;
    var id = request.id;
    Response? response;
    try {
      response = await _getResponse(request, requestTime);
    } on RequestFailure catch (exception) {
      response = Response(id, requestTime, error: exception.error);
    } catch (exception, stackTrace) {
      response = Response(id, requestTime,
          error: protocol.RequestError(
              protocol.RequestErrorCode.PLUGIN_ERROR, exception.toString(),
              stackTrace: stackTrace.toString()));
    }
    if (response != null) {
      _channel.sendResponse(response);
    }
  }

  static protocol.Location _locationFor(
      CompilationUnit unit, String path, AnalysisError error) {
    var lineInfo = unit.lineInfo;
    var startLocation = lineInfo.getLocation(error.offset);
    var endLocation = lineInfo.getLocation(error.offset + error.length);
    return protocol.Location(
      path,
      error.offset,
      error.length,
      startLocation.lineNumber,
      startLocation.columnNumber,
      endLine: endLocation.lineNumber,
      endColumn: endLocation.columnNumber,
    );
  }
}
