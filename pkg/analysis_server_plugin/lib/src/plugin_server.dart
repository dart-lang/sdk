// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/dart/analysis/driver.dart';
library;

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
import 'package:analysis_server_plugin/src/utilities/diagnostic_messages.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:meta/meta.dart';

/// A pair, matching a [Diagnostic] with it's equivalent
/// [protocol.AnalysisError].
typedef _DiagnosticAndAnalysisError = ({
  Diagnostic diagnostic,
  protocol.AnalysisError analysisError,
});

typedef _PluginState = ({
  AnalysisContext analysisContext,
  List<_DiagnosticAndAnalysisError> errors,
});

/// The server that communicates with the analysis server, passing requests and
/// responses between the analysis server and individual plugins.
class PluginServer {
  /// The communication channel being used to communicate with the analysis
  /// server.
  late PluginCommunicationChannel _channel;

  final OverlayResourceProvider _resourceProvider;

  late final ByteStore _byteStore = MemoryCachingByteStore(
    NullByteStore(),
    1024 * 1024 * 256,
  );

  AnalysisContextCollectionImpl? _contextCollection;

  String? _sdkPath;

  /// Paths of priority files.
  Set<String> _priorityPaths = {};

  final List<Plugin> _plugins;

  /// The recent state of analysis reults, to be cleared on file changes.
  final _recentState = <String, _PluginState>{};

  /// The map of files currently being analyzed, mapped to their active session.
  final _filesBeingAnalyzed = <String, AnalysisSession>{};

  /// The map of files currently being resolved, mapped to their active session.
  final _filesBeingResolved = <String, AnalysisSession>{};

  /// The next modification stamp for a changed file in the [_resourceProvider].
  int _overlayModificationStamp = 0;

  /// The map of registered features for each plugin, for namespacing purposes.
  static final registries = <String, PluginRegistryImpl>{};

  /// The current subscription of [_contextCollection]'s
  /// [AnalysisDriverScheduler.events] Stream. This must be cancelled when
  /// [_contextCollection] is disposed.
  StreamSubscription<Object>? _eventsSubscription;

  /// Whether we have received an 'analysis.setAnalysisRoots' request.
  ///
  /// If we have, we can ignore 'analysis.setContextRoots' requests.
  bool _receivedAnalysisRoots = false;

  /// Whether to fall back to the global [Registry.ruleRegistry] if a plugin
  /// registry is not found by name.
  ///
  /// Only older Dart SDKs call `PluginServer.new`, which sets this to `true`.
  /// Otherwise it is `false`.
  final bool _useGlobalRegistry;

  PluginServer({
    required ResourceProvider resourceProvider,
    required List<Plugin> plugins,
  }) : _resourceProvider = OverlayResourceProvider(resourceProvider),
       _plugins = plugins,
       _useGlobalRegistry = true {
    int i = 0;
    for (var plugin in plugins) {
      var registry = PluginRegistryImpl(plugin.name);
      // For this unnamed (old) constructor, we were not tracking them by name
      // so we do this (use '$i') simply to store the registries uniquely.
      //
      // `registries` was previously only used for the `PLUGIN_REQUEST_DETAILS`
      // request handling.
      //
      // Now, we plan on deprecating this constructor and move to `new2`, since
      // that allows us to track plugins by name and fix issues with ignores and
      // avoiding diagnostic collisions.
      //
      // When initializing with this constructor we can't use `registries` to
      // find them by name, so we use the main `Registry.ruleRegistry` to find
      // the rules instead.
      registries['$i'] = registry;
      plugin.register(registry);
      i++;
    }
    PluginRegistryImpl.registerIgnoreProducerGenerators();
  }

  PluginServer.new2({
    required ResourceProvider resourceProvider,
    required Map<String, Plugin> plugins,
  }) : _resourceProvider = OverlayResourceProvider(resourceProvider),
       _plugins = plugins.values.toList(),
       _useGlobalRegistry = false {
    for (var MapEntry(key: name, value: plugin) in plugins.entries) {
      var registry = PluginRegistryImpl(plugin.name);
      registries[name.toLowerCase()] = registry;
      plugin.register(registry);
    }
    PluginRegistryImpl.registerIgnoreProducerGenerators();
  }

  @visibleForTesting
  Set<String> get priorityPaths => {..._priorityPaths};

  /// Handles an 'analysis.setPriorityFiles' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.AnalysisSetPriorityFilesResult>
  handleAnalysisSetPriorityFiles(
    protocol.AnalysisSetPriorityFilesParams parameters,
  ) async {
    _priorityPaths = parameters.files.toSet();
    _updatePriorityFiles();
    return protocol.AnalysisSetPriorityFilesResult();
  }

  /// Handles an 'edit.getAssists' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.EditGetAssistsResult> handleEditGetAssists(
    protocol.EditGetAssistsParams parameters,
  ) async {
    var path = parameters.file;

    var recentState = _recentState[path];
    if (recentState == null) {
      return protocol.EditGetAssistsResult(const []);
    }

    var (:analysisContext, :errors) = recentState;
    var libraryResult = await analysisContext.currentSession
        .getResolvedLibraryContaining(path);
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
        protocol.PrioritizedSourceChange(assist.kind.priority, assist.change),
    ];
    return protocol.EditGetAssistsResult(corrections);
  }

  /// Handles an 'edit.getFixes' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.EditGetFixesResult> handleEditGetFixes(
    protocol.EditGetFixesParams parameters,
  ) async {
    var path = parameters.file;
    var offset = parameters.offset;

    var recentState = _recentState[path];
    if (recentState == null) {
      return protocol.EditGetFixesResult(const []);
    }

    var (:analysisContext, :errors) = recentState;

    var libraryResult = await analysisContext.currentSession
        .getResolvedLibraryContaining(path);
    if (libraryResult is! ResolvedLibraryResult) {
      return protocol.EditGetFixesResult(const []);
    }
    var unitResult = libraryResult.unitWithPath(path);
    if (unitResult is! ResolvedUnitResult) {
      return protocol.EditGetFixesResult(const []);
    }

    var lineInfo = unitResult.lineInfo;
    var requestLine = lineInfo.getLocation(offset).lineNumber;

    var diagnostics = errors.map((e) => e.diagnostic);

    var lintAtOffset = errors.where((error) {
      var errorLine = lineInfo.getLocation(error.diagnostic.offset).lineNumber;
      return errorLine == requestLine;
    });
    if (lintAtOffset.isEmpty) return protocol.EditGetFixesResult(const []);

    var errorFixesList = <protocol.AnalysisErrorFixes>[];

    var workspace = DartChangeWorkspace([analysisContext.currentSession]);
    for (var (:diagnostic, :analysisError) in lintAtOffset) {
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
        // TODO(srawlins): Somehow wrap each ProducerGenerator invocation in a
        // zone, to support `print` capturing per-plugin.
        fixes = await computeFixes(context, diagnostics: diagnostics);
      } on InconsistentAnalysisException {
        // TODO(srawlins): Is it important to at least log this? Or does it
        // happen on the regular?
        fixes = [];
      }

      if (fixes.isNotEmpty) {
        fixes.sort(Fix.compareFixes);
        var errorFixes = protocol.AnalysisErrorFixes(analysisError);
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
    protocol.PluginVersionCheckParams parameters,
  ) async {
    // TODO(srawlins): It seems improper for _this_ method to be the point where
    // the SDK path is configured...
    _sdkPath = parameters.sdkPath;
    return protocol.PluginVersionCheckResult(true, 'Plugin Server', '0.0.1', [
      '*.dart',
    ]);
  }

  /// Initializes each of the registered plugins.
  Future<void> initialize() async {
    await Future.wait(
      _plugins.map((p) => p.start()).whereType<Future<Object?>>(),
    );
  }

  /// Starts this plugin by listening to the given communication [channel].
  void start(PluginCommunicationChannel channel) {
    _channel = channel;
    _channel.listen(
      _handleRequestZoned,
      // TODO(srawlins): Implement.
      onDone: () {},
    );
  }

  /// Waits until all background drivers in the context collection are idle.
  @visibleForTesting
  Future<void> waitForIdle() async {
    if (_contextCollection case var contextCollection?) {
      await Future.wait([
        for (var analysisContext in contextCollection.contexts)
          analysisContext.driver.scheduler.waitForIdle(),
      ]);
    }
  }

  /// This method is invoked when a new instance of [AnalysisContextCollection]
  /// is created, so the plugin can perform initial analysis of analyzed files.
  Future<void> _analyzeAllFilesInContextCollection({
    required AnalysisContextCollectionImpl contextCollection,
  }) async {
    await _forAnalysisContexts(contextCollection, (analysisContext) async {
      final driver = analysisContext.driver;
      var paths = analysisContext.contextRoot
          .analyzedFiles()
          // TODO(srawlins): Enable analysis on other files, even if only
          // YAML files for analysis options and pubspec analysis and quick
          // fixes.
          .where((p) => file_paths.isDart(_resourceProvider.pathContext, p))
          .toSet();

      for (var path in paths) {
        driver.addFile(path);
      }
    });
  }

  /// Computes and returns [protocol.AnalysisError]s for each of the parts in
  /// the library at [libraryPath].
  Future<Map<String, List<protocol.AnalysisError>>> _computeAnalysisErrors(
    AnalysisContext analysisContext,
    String libraryPath, {
    required AnalysisOptionsImpl analysisOptions,
  }) async {
    var libraryResult = await analysisContext.currentSession.getResolvedLibrary(
      libraryPath,
    );
    if (libraryResult is! ResolvedLibraryResult) {
      // We only handle analyzing at the library-level. Below, we work through
      // each of the compilation units found in `libraryResult`.
      return const {};
    }

    var diagnosticListeners = {
      for (var unitResult in libraryResult.units)
        unitResult: RecordingDiagnosticListener(),
    };

    RuleContextUnit? definingContextUnit;
    var definingUnit =
        (libraryResult.element as LibraryElementImpl).firstFragment;
    var allUnits = <RuleContextUnit>[];

    for (var unitResult in libraryResult.units) {
      var contextUnit = RuleContextUnit(
        file: unitResult.file,
        content: unitResult.content,
        diagnosticReporter: DiagnosticReporter(
          diagnosticListeners[unitResult]!,
          unitResult.libraryElement.firstFragment.source,
        ),
        unit: unitResult.unit,
      );
      allUnits.add(contextUnit);
      if (unitResult.unit.declaredFragment == definingUnit) {
        definingContextUnit = contextUnit;
      }
    }
    // Just a fallback value. We shouldn't get into this situation, but this is
    // a safe default.
    definingContextUnit ??= allUnits.first;

    var package = analysisContext.contextRoot.workspace.findPackageFor(
      libraryPath,
    );

    var context = RuleContextWithResolvedResults(
      allUnits,
      definingContextUnit,
      libraryResult.element.typeProvider,
      libraryResult.element.typeSystem as TypeSystemImpl,
      package,
    );

    // A mapping from each diagnostic code to its corresponding plugin.
    var pluginCodeMapping = <DiagnosticCode, String>{};

    // A mapping from each diagnostic code to its configured severity.
    var severityMapping = <DiagnosticCode, protocol.AnalysisErrorSeverity?>{};

    for (var configuration in analysisOptions.pluginConfigurations) {
      // TODO(srawlins): Enable timing similar to what the linter package's
      // `benchmark.dart` script does.
      var ruleVisitorRegistry = RuleVisitorRegistryImpl(enableTiming: false);
      runZonedGuarded(
        () => _computeDiagnosticsFromPlugin(
          configuration,
          analysisContext: analysisContext,
          allUnits: allUnits,
          ruleVisitorRegistry: ruleVisitorRegistry,
          context: context,
          pluginCodeMapping: pluginCodeMapping,
          severityMapping: severityMapping,
        ),
        _zoneOnErrorHandler,
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => _print(configuration.name, line),
        ),
      );
    }

    // The list of the `AnalysisError`s and their associated
    // `protocol.AnalysisError`s.
    var diagnosticsAndAnalysisErrors =
        <({Diagnostic diagnostic, protocol.AnalysisError analysisError})>[];

    diagnosticListeners.forEach((unitResult, listener) {
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
      var unitDiagnosticsAndAnalysisErrors =
          <({Diagnostic diagnostic, protocol.AnalysisError analysisError})>[];

      for (var diagnostic in diagnostics) {
        unitDiagnosticsAndAnalysisErrors.add((
          diagnostic: diagnostic,
          analysisError: protocol.AnalysisError(
            severityMapping[diagnostic.diagnosticCode] ??
                protocol.AnalysisErrorSeverity.INFO,
            protocol.AnalysisErrorType.STATIC_WARNING,
            _locationFor(unitResult.unit, unitResult.path, diagnostic),
            diagnostic.message,
            diagnostic.diagnosticCode.lowerCaseName,
            correction: diagnostic.correctionMessage,
            contextMessages: diagnostic.contextMessages
                .map(
                  (message) => newDiagnosticMessage(
                    message,
                    analysisContext.currentSession,
                    lineInfo: message.filePath == unitResult.path
                        ? unitResult.lineInfo
                        : null,
                  ),
                )
                .nonNulls
                .toList(),
            // TODO(srawlins): Use a valid value here.
            hasFix: true,
          ),
        ));
      }

      _recentState[unitResult.path] = (
        analysisContext: analysisContext,
        errors: [...unitDiagnosticsAndAnalysisErrors],
      );

      diagnosticsAndAnalysisErrors.addAll(unitDiagnosticsAndAnalysisErrors);
    });

    // A map that has a key for each unit's path. It is important to collect the
    // analysis errors for each unit, even if it has none. We must send a
    // notification for each unit, even if there are no analysis errors to
    // report.
    var analysisErrorsByPath = <String, List<protocol.AnalysisError>>{
      for (var unitResult in libraryResult.units) unitResult.path: [],
    };
    for (var (diagnostic: _, :analysisError) in diagnosticsAndAnalysisErrors) {
      analysisErrorsByPath[analysisError.location.file]!.add(analysisError);
    }
    return analysisErrorsByPath;
  }

  /// Computes diagnostics for the plugin configured with [configuration].
  ///
  /// [pluginCodeMapping] and [severityMapping] are output parameters; this
  /// function adds mappings, which can be used at the call-site outside of the
  /// [Zone].
  void _computeDiagnosticsFromPlugin(
    PluginConfiguration configuration, {
    required AnalysisContext analysisContext,
    required List<RuleContextUnit> allUnits,
    required RuleVisitorRegistryImpl ruleVisitorRegistry,
    required RuleContextWithResolvedResults context,
    required Map<DiagnosticCode, String> pluginCodeMapping,
    required Map<DiagnosticCode, protocol.AnalysisErrorSeverity?>
    severityMapping,
  }) {
    if (!configuration.isEnabled) return;
    RegistryBase? registry = registries[configuration.name.toLowerCase()];
    if (registry == null) {
      if (!_useGlobalRegistry) {
        return;
      }
      // Only use the global registry if the `.new` constructor was used (by
      // older Dart SDKs). We'll remove this when we break from that API.
      registry = Registry.ruleRegistry;
    }
    var rules = registry.enabled({
      for (var entry in configuration.diagnosticConfigs.entries)
        entry.key.toLowerCase(): entry.value,
    });

    for (var code in rules.expand((r) => r.diagnosticCodes)) {
      pluginCodeMapping.putIfAbsent(code, () => configuration.name);
      severityMapping.putIfAbsent(
        code,
        () => _configuredSeverity(configuration, code),
      );
    }

    for (var rule in rules) {
      // TODO(srawlins): Enable timing similar to what the linter package's
      // `benchmark.dart` script does.
      rule.registerNodeProcessors(ruleVisitorRegistry, context);
    }

    // Now to perform the actual analysis.
    for (var currentUnit in allUnits) {
      if (!analysisContext.contextRoot.isAnalyzed(currentUnit.file.path)) {
        // If the file isn't analyzed, then we shouldn't be running any rules
        // on it. This can happen when the library has parts that aren't
        // analyzed (e.g. because they are excluded via analysis options).
        continue;
      }
      for (var rule in rules) {
        rule.reporter = currentUnit.diagnosticReporter;
      }

      context.currentUnit = currentUnit;
      currentUnit.unit.accept(
        AnalysisRuleVisitor(
          ruleVisitorRegistry,
          shouldPropagateExceptions: true,
        ),
      );
    }

    // Now that all lint rules have visited the code in each of the compilation
    // units, we can accept each lint rule's `afterLibrary` hook.
    AnalysisRuleVisitor(ruleVisitorRegistry).afterLibrary();
  }

  /// Converts the severity of [code] into a [protocol.AnalysisErrorSeverity].
  protocol.AnalysisErrorSeverity? _configuredSeverity(
    PluginConfiguration configuration,
    DiagnosticCode code,
  ) {
    var configuredSeverity =
        configuration.diagnosticConfigs[code.lowerCaseName]?.severity;
    if (configuredSeverity != null &&
        configuredSeverity != ConfiguredSeverity.enable) {
      var severityName = configuredSeverity.name.toUpperCase();
      var severity = protocol.AnalysisErrorSeverity.values
          .asNameMap()[severityName];
      assert(
        severity != null,
        'Invalid configured severity: ${configuredSeverity.name}',
      );
      return severity;
    }

    // Fall back to the declared severity of [code].
    var severityName = code.severity.name.toUpperCase();
    var severity = protocol.AnalysisErrorSeverity.values
        .asNameMap()[code.severity.name];
    assert(severity != null, 'Invalid severity: $severityName');
    return severity;
  }

  Future<void> _createContextCollection(List<String> includedPaths) async {
    if (_contextCollection case var contextCollection?) {
      _contextCollection = null;
      await contextCollection.dispose();
    }
    if (_eventsSubscription case var eventsSubscription?) {
      _eventsSubscription = null;
      await eventsSubscription.cancel();
    }

    var contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: _resourceProvider,
      includedPaths: includedPaths,
      byteStore: _byteStore,
      sdkPath: _sdkPath,
      fileContentCache: FileContentCache(_resourceProvider),
      configureAnalysisOptionsBuilder:
          // Disable extra warning computation and lint computation, because
          // these are reported in the main analysis server isolate, not in the
          // plugins isolate.
          ({required analysisOptionsBuilder}) => analysisOptionsBuilder
            ..warning = false
            ..lint = false,
      withFineDependencies: true,
      drainStreams: false,
    );
    _contextCollection = contextCollection;
    _updatePriorityFiles();
    _eventsSubscription = contextCollection.scheduler.events.listen((event) {
      if (event is ResolvedUnitResult) {
        _handleResolvedUnit(event);
      } else if (event is AnalysisStatus) {
        _handleAnalysisStatus(event);
      } else if (event is ErrorsResult) {
        _handleErrorsResult(event);
      }
    });
    await _analyzeAllFilesInContextCollection(
      contextCollection: contextCollection,
    );
  }

  /// Invokes [fn] first for priority analysis contexts, then for the rest.
  Future<void> _forAnalysisContexts(
    AnalysisContextCollectionImpl contextCollection,
    Future<void> Function(DriverBasedAnalysisContext analysisContext) fn,
  ) async {
    var nonPriorityAnalysisContexts = <DriverBasedAnalysisContext>[];
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
      case protocol.ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS:
        var params = protocol.AnalysisHandleWatchEventsParams.fromRequest(
          request,
        );
        result = await _handleAnalysisWatchEvents(params);

      case protocol.ANALYSIS_REQUEST_SET_CONTEXT_ROOTS:
        var params = protocol.AnalysisSetContextRootsParams.fromRequest(
          request,
        );
        result = await _handleAnalysisSetContextRoots(params);

      case protocol.ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS:
        var params = protocol.AnalysisSetAnalysisRootsParams.fromRequest(
          request,
        );
        result = await _handleAnalysisSetAnalysisRoots(params);

      case protocol.ANALYSIS_REQUEST_SET_PRIORITY_FILES:
        var params = protocol.AnalysisSetPriorityFilesParams.fromRequest(
          request,
        );
        result = await handleAnalysisSetPriorityFiles(params);

      case protocol.ANALYSIS_REQUEST_UPDATE_CONTENT:
        var params = protocol.AnalysisUpdateContentParams.fromRequest(request);
        result = await _handleAnalysisUpdateContent(params);

      case protocol.EDIT_REQUEST_GET_ASSISTS:
        var params = protocol.EditGetAssistsParams.fromRequest(request);
        result = await handleEditGetAssists(params);

      case protocol.EDIT_REQUEST_GET_FIXES:
        var params = protocol.EditGetFixesParams.fromRequest(request);
        result = await handleEditGetFixes(params);

      case protocol.PLUGIN_REQUEST_DETAILS:
        var details = <protocol.PluginDetails>[];
        for (var pluginRegistry in registries.values) {
          var assists = [
            for (var assistKind in pluginRegistry.assistKinds)
              protocol.AssistDescription(assistKind.id, assistKind.message),
          ];
          var fixes = [
            for (var MapEntry(key: fixKind, value: codes)
                in pluginRegistry.fixKinds.entries)
              protocol.FixDescription(fixKind.id, fixKind.message, codes),
          ];
          details.add(
            protocol.PluginDetails(
              pluginRegistry.pluginName,
              pluginRegistry.lintRules.keys.toList(),
              pluginRegistry.warningRules.keys.toList(),
              assists,
              fixes,
            ),
          );
        }
        result = protocol.PluginDetailsResult(details);

      case protocol.PLUGIN_REQUEST_SHUTDOWN:
        await Future.wait(
          _plugins.map((p) => p.shutDown()).whereType<Future<Object?>>(),
        );
        _channel.sendResponse(
          protocol.PluginShutdownResult().toResponse(request.id, requestTime),
        );
        _channel.close();
        return null;

      case protocol.PLUGIN_REQUEST_VERSION_CHECK:
        var params = protocol.PluginVersionCheckParams.fromRequest(request);
        result = await handlePluginVersionCheck(params);

      default:
        // Anything else is unsupported.
        result = null;
    }
    if (result == null) {
      return Response(
        request.id,
        requestTime,
        error: RequestErrorFactory.unknownRequest(request.method),
      );
    }
    return result.toResponse(request.id, requestTime);
  }

  /// Handles an 'analysis.setAnalysisRoots' request.
  Future<protocol.AnalysisSetAnalysisRootsResult>
  _handleAnalysisSetAnalysisRoots(
    protocol.AnalysisSetAnalysisRootsParams parameters,
  ) async {
    _receivedAnalysisRoots = true;
    await _createContextCollection(parameters.included);
    return protocol.AnalysisSetAnalysisRootsResult();
  }

  /// Handles an 'analysis.setContextRoots' request.
  Future<protocol.AnalysisSetContextRootsResult> _handleAnalysisSetContextRoots(
    protocol.AnalysisSetContextRootsParams parameters,
  ) async {
    // Allow any "simultaneous" requests to be processed.
    await Future<void>.delayed(Duration.zero);
    if (_receivedAnalysisRoots) {
      return protocol.AnalysisSetContextRootsResult();
    }

    var includedPaths = parameters.roots.map((e) => e.root).toList();
    await _createContextCollection(includedPaths);
    return protocol.AnalysisSetContextRootsResult();
  }

  void _handleAnalysisStatus(AnalysisStatus status) {
    _channel.sendNotification(
      protocol.PluginStatusParams(
        analysis: protocol.AnalysisStatus(status.isWorking),
      ).toNotification(),
    );
  }

  /// Handles an 'analysis.updateContent' request.
  ///
  /// Throws a [RequestFailure] if the request could not be handled.
  Future<protocol.AnalysisUpdateContentResult> _handleAnalysisUpdateContent(
    protocol.AnalysisUpdateContentParams parameters,
  ) async {
    var changedPaths = <String>{};
    var paths = parameters.files;
    paths.forEach((String path, Object overlay) {
      // Prepare the old overlay contents.
      String? oldContent;
      try {
        oldContent = _resourceProvider.getFile(path).readAsStringSync();
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
            RequestErrorFactory.invalidOverlayChangeNoContent(),
          );
        }
        try {
          newContent = protocol.SourceEdit.applySequence(
            oldContent,
            overlay.edits,
          );
        } on RangeError {
          throw RequestFailure(
            RequestErrorFactory.invalidOverlayChangeInvalidEdit(),
          );
        }
      } else if (overlay is protocol.RemoveContentOverlay) {
        newContent = null;
      }

      if (newContent != null) {
        if (newContent != oldContent) {
          _resourceProvider.setOverlay(
            path,
            content: newContent,
            modificationStamp: _overlayModificationStamp++,
          );
          changedPaths.add(path);
        }
      } else {
        if (_resourceProvider.hasOverlay(path)) {
          _resourceProvider.removeOverlay(path);
          changedPaths.add(path);
        }
      }
    });
    await _handleContentChanged(modifiedPaths: changedPaths.toList());
    return protocol.AnalysisUpdateContentResult();
  }

  /// Handles an 'analysis.handleWatchEvents' request.
  Future<protocol.AnalysisHandleWatchEventsResult> _handleAnalysisWatchEvents(
    protocol.AnalysisHandleWatchEventsParams parameters,
  ) async {
    final addedPaths = parameters.events
        .where((e) => e.type == protocol.WatchEventType.ADD)
        .map((e) => e.path)
        .toList();
    final modifiedPaths = parameters.events
        .where((e) => e.type == protocol.WatchEventType.MODIFY)
        .map((e) => e.path)
        .toList();
    final removedPaths = parameters.events
        .where((e) => e.type == protocol.WatchEventType.REMOVE)
        .map((e) => e.path)
        .toList();

    await _handleContentChanged(
      addedPaths: addedPaths,
      modifiedPaths: modifiedPaths,
      removedPaths: removedPaths,
    );

    return protocol.AnalysisHandleWatchEventsResult();
  }

  /// Handles added files, modified files, and removed files.
  Future<void> _handleContentChanged({
    List<String> addedPaths = const [],
    List<String> modifiedPaths = const [],
    List<String> removedPaths = const [],
  }) async {
    if (_contextCollection case var contextCollection?) {
      _filesBeingAnalyzed.clear();
      _filesBeingResolved.clear();
      await _forAnalysisContexts(contextCollection, (analysisContext) async {
        final driver = analysisContext.driver;
        for (var path in modifiedPaths) {
          driver.changeFile(path);
        }
        for (var path in removedPaths) {
          driver.removeFile(path);
        }
        for (var path in addedPaths) {
          driver.addFile(path);
        }
      });
      for (var path in removedPaths) {
        _channel.sendNotification(
          protocol.AnalysisErrorsParams(path, []).toNotification(),
        );
      }
    }
  }

  void _handleErrorsResult(ErrorsResult event) {
    var path = event.path;
    var session = event.session;
    var analysisContext = session.analysisContext;
    if (analysisContext is DriverBasedAnalysisContext) {
      if (analysisContext.contextRoot.isAnalyzed(path)) {
        var activeSession = _filesBeingResolved[path];
        if (activeSession != session) {
          _filesBeingResolved[path] = session;
          analysisContext.driver.getResolvedUnit(path);
        }
      }
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
      response = Response(
        id,
        requestTime,
        error: protocol.RequestError(
          protocol.RequestErrorCode.PLUGIN_ERROR,
          exception.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
    if (response != null) {
      _channel.sendResponse(response);
    }
  }

  Future<void> _handleRequestZoned(Request request) async {
    await runZonedGuarded(
      () => _handleRequest(request),
      _zoneOnErrorHandler,
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => _print('<shared plugin code>', line),
      ),
    );
  }

  Future<void> _handleResolvedUnit(ResolvedUnitResult unitResult) async {
    var analysisContext = unitResult.session.analysisContext;
    if (!analysisContext.contextRoot.isAnalyzed(unitResult.path)) {
      return;
    }
    if (unitResult.unit.declaredFragment !=
        unitResult.libraryElement.firstFragment) {
      return;
    }
    var session = unitResult.session;
    var activeSession = _filesBeingAnalyzed[unitResult.path];
    if (activeSession == session) {
      return;
    }
    _filesBeingAnalyzed[unitResult.path] = session;
    try {
      var file = _resourceProvider.getFile(unitResult.path);
      var analysisOptions = analysisContext.getAnalysisOptionsForFile(file);
      var analysisErrorsByPath = await _computeAnalysisErrors(
        analysisContext,
        unitResult.path,
        analysisOptions: analysisOptions as AnalysisOptionsImpl,
      );
      for (var MapEntry(key: path, value: analysisErrors)
          in analysisErrorsByPath.entries) {
        _channel.sendNotification(
          protocol.AnalysisErrorsParams(path, analysisErrors).toNotification(),
        );
      }
    } on InconsistentAnalysisException {
      // State changed during resolution; a subsequent pass will handle it.
    }
  }

  bool _isPriorityAnalysisContext(AnalysisContext analysisContext) =>
      _priorityPaths.any(analysisContext.contextRoot.isAnalyzed);

  void _print(String pluginName, String message) {
    _channel.sendNotification(
      protocol.PluginPrintParams(
        protocol.PluginPrint(
          pluginName,
          message,
          DateTime.now().millisecondsSinceEpoch,
        ),
      ).toNotification(),
    );
  }

  void _updatePriorityFiles() {
    if (_contextCollection case var contextCollection?) {
      for (var analysisContext in contextCollection.contexts) {
        analysisContext.driver.priorityFiles = _priorityPaths.toList();
      }
    }
  }

  /// The `onError` handler for use in [runZonedGuarded].
  void _zoneOnErrorHandler(Object error, StackTrace stackTrace) {
    _channel.sendNotification(
      protocol.PluginErrorParams(
        false /* isFatal */,
        error.toString(),
        stackTrace.toString(),
      ).toNotification(),
    );
  }

  static protocol.Location _locationFor(
    CompilationUnit unit,
    String path,
    Diagnostic diagnostic,
  ) {
    var lineInfo = unit.lineInfo;
    var startLocation = lineInfo.getLocation(diagnostic.offset);
    var endLocation = lineInfo.getLocation(
      diagnostic.offset + diagnostic.length,
    );
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
