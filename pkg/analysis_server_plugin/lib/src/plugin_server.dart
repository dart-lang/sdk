// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analysis_server_plugin/edit/assist/dart_assist_context.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/src/correction/assist_processor.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_processor.dart';
import 'package:analysis_server_plugin/src/registry.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

typedef _ErrorAndProtocolError = ({
  Diagnostic diagnostic,
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

  /// Paths of priority files.
  Set<String> _priorityPaths = {};

  final List<Plugin> _plugins;

  final _registry = PluginRegistryImpl();

  /// The recent state of analysis reults, to be cleared on file changes.
  final _recentState = <String, _PluginState>{};

  /// The next modification stamp for a changed file in the [resourceProvider].
  int _overlayModificationStamp = 0;

  PluginServer({
    required ResourceProvider resourceProvider,
    required List<Plugin> plugins,
  })  : _resourceProvider = OverlayResourceProvider(resourceProvider),
        _plugins = plugins {
    for (var plugin in plugins) {
      plugin.register(_registry);
    }
    _registry.registerIgnoreProducerGenerators();
  }

  /// Handles an 'analysis.setPriorityFiles' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.AnalysisSetPriorityFilesResult>
      handleAnalysisSetPriorityFiles(
          protocol.AnalysisSetPriorityFilesParams parameters) async {
    _priorityPaths = parameters.files.toSet();
    return protocol.AnalysisSetPriorityFilesResult();
  }

  /// Handles an 'edit.getAssists' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.EditGetAssistsResult> handleEditGetAssists(
      protocol.EditGetAssistsParams parameters) async {
    var path = parameters.file;

    var recentState = _recentState[path];
    if (recentState == null) {
      return protocol.EditGetAssistsResult(const []);
    }

    var (:analysisContext, :errors) = recentState;
    var libraryResult =
        await analysisContext.currentSession.getResolvedLibrary(path);
    if (libraryResult is! ResolvedLibraryResult) {
      return protocol.EditGetAssistsResult(const []);
    }
    var unitResult = libraryResult.unitWithPath(path);
    if (unitResult is! ResolvedUnitResult) {
      return protocol.EditGetAssistsResult(const []);
    }

    var context = DartAssistContext(
      // TODO(srawlins): Use a real instrumentation service. Other
      // implementations get InstrumentationService from AnalysisServer.
      InstrumentationService.NULL_SERVICE,
      DartChangeWorkspace([analysisContext.currentSession]),
      libraryResult,
      unitResult,
      parameters.offset,
      parameters.length,
    );

    List<Assist> assists;
    try {
      assists = await computeAssists(context);
    } on InconsistentAnalysisException {
      // TODO(srawlins): Is it important to at least log this? Or does it
      // happen on the regular?
      assists = [];
    }

    if (assists.isEmpty) {
      return protocol.EditGetAssistsResult(const []);
    }

    var corrections = [
      for (var assist in assists..sort(Assist.compareAssists))
        protocol.PrioritizedSourceChange(assist.kind.priority, assist.change)
    ];
    return protocol.EditGetAssistsResult(corrections);
  }

  /// Handles an 'edit.getFixes' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.EditGetFixesResult> handleEditGetFixes(
      protocol.EditGetFixesParams parameters) async {
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
    var unitResult = libraryResult.unitWithPath(path);
    if (unitResult is! ResolvedUnitResult) {
      return protocol.EditGetFixesResult(const []);
    }

    var lintAtOffset =
        errors.where((error) => error.diagnostic.offset == offset);
    if (lintAtOffset.isEmpty) return protocol.EditGetFixesResult(const []);

    var errorFixesList = <protocol.AnalysisErrorFixes>[];

    var workspace = DartChangeWorkspace([analysisContext.currentSession]);
    for (var (:diagnostic, :protocolError) in lintAtOffset) {
      var context = DartFixContext(
        // TODO(srawlins): Use a real instrumentation service. Other
        // implementations get InstrumentationService from AnalysisServer.
        instrumentationService: InstrumentationService.NULL_SERVICE,
        workspace: workspace,
        libraryResult: libraryResult,
        unitResult: unitResult,
        error: diagnostic,
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
    _channel.listen(_handleRequestZoned,
        // TODO(srawlins): Implement.
        onDone: () {});
  }

  /// This method is invoked when a new instance of [AnalysisContextCollection]
  /// is created, so the plugin can perform initial analysis of analyzed files.
  Future<void> _analyzeAllFilesInContextCollection({
    required AnalysisContextCollection contextCollection,
  }) async {
    _channel.sendNotification(
        protocol.PluginStatusParams(analysis: protocol.AnalysisStatus(true))
            .toNotification());
    await _forAnalysisContexts(contextCollection, (analysisContext) async {
      var paths = analysisContext.contextRoot
          .analyzedFiles()
          // TODO(srawlins): Enable analysis on other files, even if only
          // YAML files for analysis options and pubspec analysis and quick
          // fixes.
          .where((p) => file_paths.isDart(_resourceProvider.pathContext, p))
          .toSet();

      await _analyzeFiles(
        analysisContext: analysisContext,
        paths: paths,
      );
    });
    _channel.sendNotification(
        protocol.PluginStatusParams(analysis: protocol.AnalysisStatus(false))
            .toNotification());
  }

  Future<void> _analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    var file = _resourceProvider.getFile(path);
    var analysisOptions = analysisContext.getAnalysisOptionsForFile(file);
    var diagnostics = await _computeDiagnostics(
      analysisContext,
      path,
      analysisOptions: analysisOptions as AnalysisOptionsImpl,
    );
    _channel.sendNotification(
        protocol.AnalysisErrorsParams(path, diagnostics).toNotification());
  }

  /// Analyzes the files at the given [paths].
  Future<void> _analyzeFiles({
    required AnalysisContext analysisContext,
    required Set<String> paths,
  }) async {
    // First analyze priority files.
    for (var path in _priorityPaths) {
      if (paths.remove(path)) {
        await _analyzeFile(analysisContext: analysisContext, path: path);
      }
    }

    // Then analyze the remaining files.
    for (var path in paths) {
      await _analyzeFile(analysisContext: analysisContext, path: path);
    }
  }

  Future<List<protocol.AnalysisError>> _computeDiagnostics(
    AnalysisContext analysisContext,
    String path, {
    required AnalysisOptionsImpl analysisOptions,
  }) async {
    var libraryResult =
        await analysisContext.currentSession.getResolvedLibrary(path);
    if (libraryResult is! ResolvedLibraryResult) {
      return const [];
    }
    var unitResult = await analysisContext.currentSession.getResolvedUnit(path);
    if (unitResult is! ResolvedUnitResult) {
      return const [];
    }
    var listener = RecordingDiagnosticListener();
    var diagnosticReporter = DiagnosticReporter(
        listener, unitResult.libraryElement.firstFragment.source);

    var currentUnit = RuleContextUnit(
      file: unitResult.file,
      content: unitResult.content,
      diagnosticReporter: diagnosticReporter,
      unit: unitResult.unit,
    );
    var allUnits = [
      for (var unitResult in libraryResult.units)
        RuleContextUnit(
          file: unitResult.file,
          content: unitResult.content,
          diagnosticReporter: diagnosticReporter,
          unit: unitResult.unit,
        ),
    ];

    // TODO(srawlins): Enable timing similar to what the linter package's
    // `benchhmark.dart` script does.
    var nodeRegistry = RuleVisitorRegistryImpl(enableTiming: false);

    var context = RuleContextWithResolvedResults(
      allUnits,
      currentUnit,
      libraryResult.element.typeProvider,
      libraryResult.element.typeSystem as TypeSystemImpl,
      // TODO(srawlins): Support 'package' parameter.
      null,
    );

    // A mapping from each diagnostic code to its corresponding plugin.
    var pluginCodeMapping = <DiagnosticCode, String>{};

    // A mapping from each diagnostic code to its configured severity.
    var severityMapping = <DiagnosticCode, protocol.AnalysisErrorSeverity?>{};

    for (var configuration in analysisOptions.pluginConfigurations) {
      if (!configuration.isEnabled) continue;
      // TODO(srawlins): Namespace rules by their plugin, to avoid collisions.
      var rules =
          Registry.ruleRegistry.enabled(configuration.diagnosticConfigs);
      for (var rule in rules) {
        rule.reporter = diagnosticReporter;
        // TODO(srawlins): Enable timing similar to what the linter package's
        // `benchmark.dart` script does.
        rule.registerNodeProcessors(nodeRegistry, context);
      }
      for (var code in rules.expand((r) => r.diagnosticCodes)) {
        pluginCodeMapping.putIfAbsent(code, () => configuration.name);
        severityMapping.putIfAbsent(
            code, () => _configuredSeverity(configuration, code));
      }
    }

    context.currentUnit = currentUnit;
    currentUnit.unit.accept(
        AnalysisRuleVisitor(nodeRegistry, shouldPropagateExceptions: true));

    var ignoreInfo = IgnoreInfo.forDart(unitResult.unit, unitResult.content);
    var diagnostics = listener.diagnostics.where((e) {
      var pluginName = pluginCodeMapping[e.diagnosticCode];
      if (pluginName == null) {
        // If [e] is somehow not mapped, something is wrong; but don't mark it
        // as ignored.
        return true;
      }
      return !ignoreInfo.ignored(e, pluginName: pluginName);
    });

    // The list of the `AnalysisError`s and their associated
    // `protocol.AnalysisError`s.
    var diagnosticsAndProtocolErrors = [
      for (var diagnostic in diagnostics)
        (
          diagnostic: diagnostic,
          protocolError: protocol.AnalysisError(
            severityMapping[diagnostic.diagnosticCode] ??
                protocol.AnalysisErrorSeverity.INFO,
            protocol.AnalysisErrorType.STATIC_WARNING,
            _locationFor(currentUnit.unit, path, diagnostic),
            diagnostic.message,
            diagnostic.diagnosticCode.name,
            correction: diagnostic.correctionMessage,
            // TODO(srawlins): Use a valid value here.
            hasFix: true,
          )
        ),
    ];
    _recentState[path] = (
      analysisContext: analysisContext,
      errors: [...diagnosticsAndProtocolErrors],
    );
    return diagnosticsAndProtocolErrors.map((e) => e.protocolError).toList();
  }

  /// Converts the severity of [code] into a [protocol.AnalysisErrorSeverity].
  protocol.AnalysisErrorSeverity? _configuredSeverity(
      PluginConfiguration configuration, DiagnosticCode code) {
    var configuredSeverity =
        configuration.diagnosticConfigs[code.name]?.severity;
    if (configuredSeverity != null &&
        configuredSeverity != ConfiguredSeverity.enable) {
      var severityName = configuredSeverity.name.toUpperCase();
      var severity =
          protocol.AnalysisErrorSeverity.values.asNameMap()[severityName];
      assert(severity != null,
          'Invalid configured severity: ${configuredSeverity.name}');
      return severity;
    }

    // Fall back to the declared severity of [code].
    var severityName = code.severity.name.toUpperCase();
    var severity =
        protocol.AnalysisErrorSeverity.values.asNameMap()[code.severity.name];
    assert(severity != null, 'Invalid severity: $severityName');
    return severity;
  }

  /// Invokes [fn] first for priority analysis contexts, then for the rest.
  Future<void> _forAnalysisContexts(
    AnalysisContextCollection contextCollection,
    Future<void> Function(AnalysisContext analysisContext) fn,
  ) async {
    var nonPriorityAnalysisContexts = <AnalysisContext>[];
    for (var analysisContext in contextCollection.contexts) {
      if (_isPriorityAnalysisContext(analysisContext)) {
        await fn(analysisContext);
      } else {
        nonPriorityAnalysisContexts.add(analysisContext);
      }
    }

    for (var analysisContext in nonPriorityAnalysisContexts) {
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
        result = await _handleAnalysisSetContextRoots(params);

      case protocol.ANALYSIS_REQUEST_SET_PRIORITY_FILES:
      case protocol.ANALYSIS_REQUEST_SET_SUBSCRIPTIONS:
      case protocol.ANALYSIS_REQUEST_UPDATE_CONTENT:
        var params = protocol.AnalysisUpdateContentParams.fromRequest(request);
        result = await _handleAnalysisUpdateContent(params);

      case protocol.COMPLETION_REQUEST_GET_SUGGESTIONS:
        result = null;

      case protocol.EDIT_REQUEST_GET_ASSISTS:
        var params = protocol.EditGetAssistsParams.fromRequest(request);
        result = await handleEditGetAssists(params);

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

  /// Handles files that might have been affected by a content change of
  /// one or more files. The implementation may check if these files should
  /// be analyzed, do such analysis, and send diagnostics.
  ///
  /// By default invokes [_analyzeFiles] only for files that are analyzed in
  /// this [analysisContext].
  Future<void> _handleAffectedFiles({
    required AnalysisContext analysisContext,
    required List<String> paths,
  }) async {
    var analyzedPaths =
        paths.where(analysisContext.contextRoot.isAnalyzed).toSet();

    await _analyzeFiles(
      analysisContext: analysisContext,
      paths: analyzedPaths,
    );
  }

  /// Handles an 'analysis.setContextRoots' request.
  Future<protocol.AnalysisSetContextRootsResult> _handleAnalysisSetContextRoots(
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

  /// Handles an 'analysis.updateContent' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.AnalysisUpdateContentResult> _handleAnalysisUpdateContent(
      protocol.AnalysisUpdateContentParams parameters) async {
    var changedPaths = <String>{};
    var paths = parameters.files;
    paths.forEach((String path, Object overlay) {
      // Prepare the old overlay contents.
      String? oldContent;
      try {
        if (_resourceProvider.hasOverlay(path)) {
          oldContent = _resourceProvider.getFile(path).readAsStringSync();
        }
      } catch (_) {
        // Leave `oldContent` empty.
      }

      // Prepare the new contents.
      String? newContent;
      if (overlay is protocol.AddContentOverlay) {
        newContent = overlay.content;
      } else if (overlay is protocol.ChangeContentOverlay) {
        if (oldContent == null) {
          // The server should only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw RequestFailure(
              RequestErrorFactory.invalidOverlayChangeNoContent());
        }
        try {
          newContent =
              protocol.SourceEdit.applySequence(oldContent, overlay.edits);
        } on RangeError {
          throw RequestFailure(
              RequestErrorFactory.invalidOverlayChangeInvalidEdit());
        }
      } else if (overlay is protocol.RemoveContentOverlay) {
        newContent = null;
      }

      if (newContent != null) {
        _resourceProvider.setOverlay(
          path,
          content: newContent,
          modificationStamp: _overlayModificationStamp++,
        );
      } else {
        _resourceProvider.removeOverlay(path);
      }

      changedPaths.add(path);
    });
    await _handleContentChanged(changedPaths.toList());
    return protocol.AnalysisUpdateContentResult();
  }

  /// Handles the fact that files with [paths] were changed.
  Future<void> _handleContentChanged(List<String> paths) async {
    if (_contextCollection case var contextCollection?) {
      _channel.sendNotification(
          protocol.PluginStatusParams(analysis: protocol.AnalysisStatus(true))
              .toNotification());
      await _forAnalysisContexts(contextCollection, (analysisContext) async {
        for (var path in paths) {
          analysisContext.changeFile(path);
        }
        var affected = await analysisContext.applyPendingFileChanges();
        await _handleAffectedFiles(
            analysisContext: analysisContext, paths: affected);
      });
      _channel.sendNotification(
          protocol.PluginStatusParams(analysis: protocol.AnalysisStatus(false))
              .toNotification());
    }
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

  Future<void> _handleRequestZoned(Request request) async {
    await runZonedGuarded(
      () => _handleRequest(request),
      (error, stackTrace) {
        _channel.sendNotification(protocol.PluginErrorParams(
                false /* isFatal */, error.toString(), stackTrace.toString())
            .toNotification());
      },
    );
  }

  bool _isPriorityAnalysisContext(AnalysisContext analysisContext) =>
      _priorityPaths.any(analysisContext.contextRoot.isAnalyzed);

  static protocol.Location _locationFor(
      CompilationUnit unit, String path, Diagnostic diagnostic) {
    var lineInfo = unit.lineInfo;
    var startLocation = lineInfo.getLocation(diagnostic.offset);
    var endLocation =
        lineInfo.getLocation(diagnostic.offset + diagnostic.length);
    return protocol.Location(
      path,
      diagnostic.offset,
      diagnostic.length,
      startLocation.lineNumber,
      startLocation.columnNumber,
      endLine: endLocation.lineNumber,
      endColumn: endLocation.columnNumber,
    );
  }
}
