// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart' as lsp;
import 'package:analysis_server/src/lsp/client_configuration.dart' as lsp;
import 'package:analysis_server/src/lsp/constants.dart' as lsp;
import 'package:analysis_server/src/lsp/error_or.dart' as lsp;
import 'package:analysis_server/src/lsp/handlers/handler_execute_command.dart'
    as lsp;
import 'package:analysis_server/src/lsp/handlers/handler_states.dart' as lsp;
import 'package:analysis_server/src/lsp/handlers/handlers.dart' as lsp;
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/protocol_server.dart'
    as legacy
    show MessageType;
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/message_scheduler.dart';
import 'package:analysis_server/src/server/performance.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/dart_tooling_daemon/dtd_services.dart';
import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analysis_server/src/services/pub/pub_command.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/services/user_prompts/survey_manager.dart';
import 'package:analysis_server/src/services/user_prompts/user_prompts.dart';
import 'package:analysis_server/src/utilities/file_string_sink.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analysis_server/src/utilities/process.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analysis_server/src/utilities/tee_string_sink.dart';
import 'package:analysis_server/src/utilities/timing_byte_store.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as analysis;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_byte_store.dart'
    show EvictingFileByteStore;
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as analysis;
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    as analyzer_plugin;
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

/// The function for sending `openUri` request to the client.
typedef OpenUriNotificationSender = Future<void> Function(Uri uri);

/// The function for sending prompts to the user and collecting button presses.
typedef UserPromptSender =
    Future<String?> Function(
      MessageType type,
      String message,
      List<String> actionLabels,
    );

/// Implementations of [AnalysisServer] implement a server that listens
/// on a [CommunicationChannel] for analysis messages and process them.
abstract class AnalysisServer {
  /// A flag indicating whether plugins are supported in this build.
  static final bool supportsPlugins = true;

  /// The options of this server instance.
  AnalysisServerOptions options;

  /// The object through which analytics are to be sent.
  final AnalyticsManager analyticsManager;

  /// A connection to DTD (the Dart Tooling Daemon) that allows other clients to
  /// call server functionality.
  ///
  /// Initialized by the client through a request that calls [connectToDtd].
  DtdServices? dtd;

  /// The object for managing showing surveys to users and recording their
  /// responses.
  ///
  /// `null` if surveys are not enabled.
  @visibleForTesting
  SurveyManager? surveyManager;

  /// The builder for attachments that should be included into crash reports.
  final CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder;

  /// The [ContextManager] that handles the mapping from analysis roots to
  /// context directories.
  late ContextManager contextManager;

  /// The object used to manage sending a subset of notifications to the client.
  /// The subset of notifications are those to which plugins may contribute.
  /// This field is `null` when the new plugin support is disabled.
  AbstractNotificationManager notificationManager;

  /// A reference to the handler for executing commands.
  ///
  /// This allows the server to call commands itself, such as "Fix All in
  /// Workspace" triggered from the [DartFixPromptManager].
  lsp.ExecuteCommandHandler? executeCommandHandler;

  /// The object used to manage the execution of plugins.
  late PluginManager pluginManager;

  /// The object used to manage the SDK's known to this server.
  final DartSdkManager sdkManager;

  /// The [SearchEngine] for this server.
  late final SearchEngine searchEngine;

  /// The optional [ByteStore] to use as [byteStore].
  final ByteStore? providedByteStore;

  late ByteStore byteStore;

  late FileContentCache fileContentCache;

  final UnlinkedUnitStore unlinkedUnitStore = UnlinkedUnitStoreImpl();

  final InfoDeclarationStore infoDeclarationStore = InfoDeclarationStoreImpl();

  late analysis.AnalysisDriverScheduler analysisDriverScheduler;

  late StreamSubscription<Object?>? analysisDriverSchedulerEventsSubscription;

  /// The DiagnosticServer for this AnalysisServer. If available, it can be used
  /// to start an http diagnostics server or return the port for an existing
  /// server.
  final DiagnosticServer? diagnosticServer;

  /// A [RecentBuffer] of the most recent exceptions encountered by the analysis
  /// server.
  final RecentBuffer<ServerException> exceptions = RecentBuffer(10);

  /// The instrumentation service that is to be used by this analysis server.
  InstrumentationService instrumentationService;

  /// Performance information after initial analysis is complete
  /// or `null` if the initial analysis is not yet complete
  ServerPerformance? performanceAfterStartup;

  /// A client for making requests to the pub.dev API.
  final PubApi pubApi;

  /// A service for fetching pub.dev package details.
  late PubPackageService pubPackageService;

  /// The class into which performance information is currently being recorded.
  /// During startup, this will be the same as [performanceDuringStartup]
  /// and after startup is complete, this switches to [performanceAfterStartup].
  late ServerPerformance performance;

  /// Performance information before initial analysis is complete.
  final ServerPerformance performanceDuringStartup = ServerPerformance();

  /// Performance about recent requests.
  final ServerRecentPerformance recentPerformance = ServerRecentPerformance();

  RequestStatisticsHelper? requestStatistics;

  PerformanceLog? analysisPerformanceLogger;

  /// Manages prompts telling the user about "dart fix".
  late final DartFixPromptManager _dartFixPrompt;

  /// The set of the files that are currently priority.
  final Set<String> priorityFiles = <String>{};

  /// The [ResourceProvider] using which paths are converted into [Resource]s.
  final OverlayResourceProvider resourceProvider;

  /// The [ClientUriConverter] to use to convert between URIs/Paths when
  /// communicating with the client.
  late ClientUriConverter _uriConverter = ClientUriConverter.noop(
    resourceProvider.pathContext,
  );

  /// The next modification stamp for a changed file in the [resourceProvider].
  ///
  /// This value is increased each time it is used and used instead of real
  /// modification stamps. It's seeded with `millisecondsSinceEpoch` to reduce
  /// the chance of colliding with values used in previous analysis sessions if
  /// used as a cache key.
  int overlayModificationStamp = DateTime.now().millisecondsSinceEpoch;

  /// Indicates whether the next time the server completes analysis is the first
  /// one since analysis contexts were built.
  ///
  /// This is useful for triggering things like [_dartFixPrompt] only when
  /// it may be useful to do so (after initial analysis and
  /// "pub get"/"pub upgrades").
  bool isFirstAnalysisSinceContextsBuilt = true;

  /// A completer that tracks in-progress analysis context rebuilds.
  ///
  /// Starts completed and will be replaced each time a context rebuild starts.
  Completer<void> analysisContextRebuildCompleter = Completer()..complete();

  /// The workspace for rename refactorings.
  late final refactoringWorkspace = RefactoringWorkspace(
    driverMap.values,
    searchEngine,
  );

  /// The paths of files for which [ResolvedUnitResult] was produced since
  /// the last idle state.
  final Set<String> filesResolvedSinceLastIdle = {};

  /// A mapping of [ProducerGenerator]s to the set of lint names with which they
  /// are associated (can fix).
  final Map<ProducerGenerator, Set<LintCode>> producerGeneratorsForLintRules;

  /// A completer for [lspUninitialized].
  final Completer<void> _lspUninitializedCompleter = Completer<void>();

  /// A scheduler that keeps track of all incoming messages and schedules them
  /// for processing.
  final MessageScheduler messageScheduler;

  /// A [TimingByteStore] that records timings for reads from the byte store.
  TimingByteStore? _timingByteStore;

  AnalysisServer(
    this.options,
    this.sdkManager,
    this.diagnosticServer,
    this.analyticsManager,
    this.crashReportingAttachmentsBuilder,
    ResourceProvider baseResourceProvider,
    this.instrumentationService,
    http.Client? httpClient,
    ProcessRunner? processRunner,
    this.notificationManager, {
    this.requestStatistics,
    bool enableBlazeWatcher = false,
    DartFixPromptManager? dartFixPromptManager,
    this.providedByteStore,
    PluginManager? pluginManager,
    bool retainDataForTesting = false,
  }) : resourceProvider = OverlayResourceProvider(baseResourceProvider),
       pubApi = PubApi(
         instrumentationService,
         httpClient,
         Platform.environment['PUB_HOSTED_URL'],
       ),
       producerGeneratorsForLintRules = AssistProcessor.computeLintRuleMap(),
       messageScheduler = MessageScheduler(
         testView: retainDataForTesting ? MessageSchedulerTestView() : null,
       ) {
    messageScheduler.setServer(this);
    // Set the default URI converter. This uses the resource providers path
    // context (unlike the initialized value) which allows tests to override it.
    uriConverter = ClientUriConverter.noop(baseResourceProvider.pathContext);

    // We can only spawn processes (eg. to run pub commands) when backed by
    // a real file system, otherwise we may try to run commands in folders that
    // don't really exist. If processRunner was supplied, it's likely a mock
    // from a test in which case the pub command should still be created.
    if (baseResourceProvider is PhysicalResourceProvider) {
      processRunner ??= ProcessRunner();
    }
    var pubCommand =
        processRunner != null &&
                Platform.environment[PubCommand
                        .disablePubCommandEnvironmentKey] ==
                    null
            ? PubCommand(
              instrumentationService,
              resourceProvider.pathContext,
              processRunner,
            )
            : null;

    pubPackageService = PubPackageService(
      instrumentationService,
      baseResourceProvider,
      pubApi,
      pubCommand,
    );
    performance = performanceDuringStartup;

    PluginWatcher? pluginWatcher;
    if (supportsPlugins) {
      this.pluginManager =
          pluginManager ??= PluginManager(
            resourceProvider,
            _getByteStorePath(),
            sdkManager.defaultSdkDirectory,
            notificationManager,
            instrumentationService,
          );

      pluginWatcher = PluginWatcher(resourceProvider, pluginManager);
    }

    var name = options.newAnalysisDriverLog;
    StringSink sink = NullStringSink();
    if (name != null) {
      if (name == 'stdout') {
        sink = io.stdout;
      } else if (name.startsWith('file:')) {
        var path = name.substring('file:'.length);
        sink = FileStringSink(path);
      }
    }
    var requestStatistics = this.requestStatistics;
    if (requestStatistics != null) {
      sink = TeeStringSink(sink, requestStatistics.perfLoggerStringSink);
    }
    var analysisPerformanceLogger =
        this.analysisPerformanceLogger = PerformanceLog(sink);

    byteStore = createByteStore(resourceProvider);
    fileContentCache = FileContentCache(resourceProvider);

    analysisDriverScheduler = analysis.AnalysisDriverScheduler(
      analysisPerformanceLogger,
      driverWatcher: pluginWatcher,
    );

    contextManager = ContextManagerImpl(
      resourceProvider,
      sdkManager,
      options.packagesFile,
      options.enabledExperiments,
      byteStore,
      fileContentCache,
      unlinkedUnitStore,
      infoDeclarationStore,
      analysisPerformanceLogger,
      analysisDriverScheduler,
      instrumentationService,
      enableBlazeWatcher: enableBlazeWatcher,
    );
    searchEngine = SearchEngineImpl(driverMap.values);

    if (dartFixPromptManager != null) {
      _dartFixPrompt = dartFixPromptManager;
    } else {
      var promptPreferences = UserPromptPreferences(
        resourceProvider,
        instrumentationService,
      );
      _dartFixPrompt = DartFixPromptManager(this, promptPreferences);
    }
  }

  /// A [Future] that completes when any in-progress analysis context rebuild
  /// completes.
  ///
  /// If no context rebuild is in progress, will return an already complete
  /// [Future].
  Future<void> get analysisContextsRebuilt =>
      analysisContextRebuildCompleter.future;

  /// A list of timings for the byte store, or `null` if timing is not being
  /// tracked.
  List<ByteStoreTimings>? get byteStoreTimings => _timingByteStore?.timings;

  /// The list of current analysis sessions in all contexts.
  Future<List<AnalysisSessionImpl>> get currentSessions async {
    var sessions = <AnalysisSessionImpl>[];
    for (var driver in driverMap.values) {
      await driver.applyPendingFileChanges();
      sessions.add(driver.currentSession);
    }
    return sessions;
  }

  /// A table mapping [Folder]s to the [AnalysisDriver]s associated with them.
  Map<Folder, analysis.AnalysisDriver> get driverMap =>
      contextManager.driverMap;

  /// The capabilities of the editor that owns this server.
  ///
  /// Request handlers should be careful to use the correct clients capabilities
  /// if they are available to non-editor clients (such as over DTD). The
  /// capabilities of the caller are available in [MessageInfo] and should
  /// usually be used when computing the results for requests, but if those
  /// requests additionally trigger requests to the editor, those requests to
  /// the editor should consider these capabilities.
  ///
  /// For the legacy server, this set may be a fixed set that is not actually
  /// configured by the client, but matches what legacy protocol editors expect
  /// when using LSP-over-Legacy.
  lsp.LspClientCapabilities? get editorClientCapabilities;

  /// The configuration (user/workspace settings) from the LSP client.
  ///
  /// For the legacy server, this set may be a fixed set that is not controlled
  /// by the client.
  lsp.LspClientConfiguration get lspClientConfiguration;

  /// A [Future] that completes when the LSP server moves into the initialized
  /// state and can handle normal LSP requests.
  ///
  /// Completes with the [InitializedStateMessageHandler] that is active.
  ///
  /// When the server leaves the initialized state, [lspUninitialized] will
  /// complete.
  FutureOr<lsp.InitializedStateMessageHandler> get lspInitialized;

  /// A [Future] that completes once the server transitions out of an
  /// initialized state.
  Future<void> get lspUninitialized => _lspUninitializedCompleter.future;

  /// Returns the function that can send `openUri` request to the client.
  /// Returns `null` is the client does not support it.
  OpenUriNotificationSender? get openUriNotificationSender;

  /// Returns owners of files.
  OwnedFiles get ownedFiles => contextManager.ownedFiles;

  /// Whether or not the client supports showMessageRequest to show the user
  /// a message and allow them to respond by clicking buttons.
  ///
  /// Callers should use [userPromptSender] instead of checking this directly.
  @protected
  bool get supportsShowMessageRequest;

  /// Return the total time the server's been alive.
  Duration get uptime {
    var start = DateTime.fromMillisecondsSinceEpoch(
      performanceDuringStartup.startTime,
    );
    return DateTime.now().difference(start);
  }

  /// The [ClientUriConverter] to use to convert between URIs/Paths when
  /// communicating with the client.
  ClientUriConverter get uriConverter => _uriConverter;

  /// Sets the [ClientUriConverter] to use to convert between URIs/Paths when
  /// communicating with the client.
  set uriConverter(ClientUriConverter value) {
    notificationManager.uriConverter = _uriConverter = value;
  }

  /// Returns the function for sending prompts to the user and collecting button
  /// presses.
  ///
  /// Returns `null` is the client does not support it.
  UserPromptSender? get userPromptSender =>
      supportsShowMessageRequest ? showUserPrompt : null;

  void afterContextsCreated() {
    _timingByteStore?.newTimings('after contexts created');
    isFirstAnalysisSinceContextsBuilt = true;
  }

  void afterContextsDestroyed() {}

  /// Broadcast a request built from the given [params] to all of the plugins
  /// that are currently associated with the context root from the given
  /// [driver]. Return a list containing futures that will complete when each of
  /// the plugins have sent a response, or an empty list if no [driver] is
  /// provided.
  Map<PluginInfo, Future<Response>> broadcastRequestToPlugins(
    analyzer_plugin.RequestParams requestParams,
    analysis.AnalysisDriver? driver,
  ) {
    if (driver == null || !AnalysisServer.supportsPlugins) {
      return <PluginInfo, Future<Response>>{};
    }
    return pluginManager.broadcastRequest(
      requestParams,
      contextRoot: driver.analysisContext!.contextRoot,
    );
  }

  /// Checks that all [sessions] are still consistent, throwing
  /// [InconsistentAnalysisException] if not.
  void checkConsistency(List<AnalysisSessionImpl> sessions) {
    for (var session in sessions) {
      session.checkConsistency();
    }
  }

  /// Completes [lspUninitialized], signalling that the server has moved out
  /// of a state where it can handle standard LSP requests.
  void completeLspUninitialization() {
    if (!_lspUninitializedCompleter.isCompleted) {
      _lspUninitializedCompleter.complete();
    }
  }

  /// Connects to DTD at [dtdUri].
  ///
  /// If there is already an active connection to DTD or there is an error
  /// connecting, returns an error, otherwise returns `null`.
  Future<lsp.ErrorOr<Null>> connectToDtd(
    Uri dtdUri, {
    bool registerExperimentalHandlers = false,
  }) async {
    switch (dtd?.state) {
      case DtdConnectionState.Connecting || DtdConnectionState.Connected:
        return lsp.error(
          lsp.ServerErrorCodes.StateError,
          'Server is already connected to DTD',
        );
      case DtdConnectionState.Disconnected || DtdConnectionState.Error || null:
        var connectResult = await DtdServices.connect(
          this,
          dtdUri,
          registerExperimentalHandlers: registerExperimentalHandlers,
        );
        return connectResult.mapResultSync((dtd) {
          this.dtd = dtd;
          return lsp.success(null);
        });
    }
  }

  /// If the state location can be accessed, return the file byte store,
  /// otherwise return the memory byte store.
  ByteStore createByteStore(ResourceProvider resourceProvider) {
    const M = 1024 * 1024 /*1 MiB*/;
    const G = 1024 * 1024 * 1024 /*1 GiB*/;

    const memoryCacheSize = 128 * M;

    if (providedByteStore case var providedByteStore?) {
      return providedByteStore;
    }

    if (resourceProvider is OverlayResourceProvider) {
      resourceProvider = resourceProvider.baseProvider;
    }
    if (resourceProvider is PhysicalResourceProvider) {
      var stateLocation = resourceProvider.getStateLocation('.analysis-driver');
      if (stateLocation != null) {
        var timingByteStore =
            _timingByteStore = TimingByteStore(
              EvictingFileByteStore(stateLocation.path, G),
            );
        return MemoryCachingByteStore(timingByteStore, memoryCacheSize);
      }
    }

    return MemoryCachingByteStore(NullByteStore(), memoryCacheSize);
  }

  void enableSurveys() {
    // TODO(dantup): This is currently gated on an LSP flag and should just
    //  be inlined into the constructor once we're happy for it to show up
    //  without a flag and for both protocols.
    surveyManager = SurveyManager(
      this,
      instrumentationService,
      analyticsManager.analytics,
    );
  }

  /// Return an analysis driver to which the file with the given [path] is
  /// added if one exists, otherwise a driver in which the file was analyzed if
  /// one exists, otherwise the first driver, otherwise `null`.
  analysis.AnalysisDriver? getAnalysisDriver(String path) {
    var drivers = driverMap.values.toList();
    if (drivers.isNotEmpty) {
      // Sort the drivers so that more deeply nested contexts will be checked
      // before enclosing contexts.
      drivers.sort((first, second) {
        var firstRoot = first.analysisContext!.contextRoot.root.path;
        var secondRoot = second.analysisContext!.contextRoot.root.path;
        return secondRoot.length - firstRoot.length;
      });
      var driver = drivers.firstWhereOrNull(
        (driver) => driver.analysisContext!.contextRoot.isAnalyzed(path),
      );
      driver ??= drivers.firstWhereOrNull(
        (driver) => driver.fsState.getExistingFromPath(path) != null,
      );
      driver ??= drivers.first;
      return driver;
    }
    return null;
  }

  /// Return an [AnalysisSession] in which the file with the given [path]
  /// should be analyzed, preferring the one in which it is analyzed, then
  /// the one where it is referenced, then the first, otherwise `null`.
  Future<AnalysisSession?> getAnalysisSession(String path) async {
    var analysisDriver = getAnalysisDriver(path);
    if (analysisDriver != null) {
      await analysisDriver.applyPendingFileChanges();
      return analysisDriver.currentSession;
    }
    return null;
  }

  DartdocDirectiveInfo getDartdocDirectiveInfoFor(ResolvedUnitResult result) {
    return getDartdocDirectiveInfoForSession(result.session);
  }

  DartdocDirectiveInfo getDartdocDirectiveInfoForSession(
    AnalysisSession session,
  ) {
    var analysisContext = session.analysisContext;
    analysisContext as DriverBasedAnalysisContext;
    return analysisContext.driver.dartdocDirectiveInfo;
  }

  /// Gets the current version number of a document (if known).
  int? getDocumentVersion(String path);

  /// Return a [Future] that completes with the [Element] at the given
  /// [offset] of the given [file], or with `null` if there is no node at the
  /// [offset] or the node does not have an element.
  Future<Element?> getElementAtOffset(String file, int offset) async {
    if (!priorityFiles.contains(file)) {
      var driver = getAnalysisDriver(file);
      if (driver == null) {
        return null;
      }

      var unitElementResult = await driver.getUnitElement(file);
      if (unitElementResult is! UnitElementResult) {
        return null;
      }

      var element = findElementByNameOffset(unitElementResult.element, offset);
      if (element != null) {
        return element;
      }
    }

    var node = await getNodeAtOffset(file, offset);
    return getElementOfNode(node);
  }

  /// Return a [Future] that completes with the [Element2] at the given
  /// [offset] of the given [file], or with `null` if there is no node at the
  /// [offset] or the node does not have an element.
  Future<Element2?> getElementAtOffset2(String file, int offset) async =>
      (await getElementAtOffset(file, offset)).asElement2;

  /// Return the [Element] of the given [node], or `null` if [node] is `null` or
  /// does not have an element.
  Element? getElementOfNode(AstNode? node) {
    if (node == null) {
      return null;
    }
    if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
      node = node.parent;
    }
    if (node is LibraryIdentifier) {
      node = node.parent;
    }
    if (node is StringLiteral && node.parent is UriBasedDirective) {
      return null;
    }
    var element = ElementLocator.locate(node);
    if (node is SimpleIdentifier && element is PrefixElement) {
      element = getImportElement(node);
    }
    return element;
  }

  /// Return the [Element] of the given [node], or `null` if [node] is `null` or
  /// does not have an element.
  Element2? getElementOfNode2(AstNode? node) {
    if (node == null) {
      return null;
    }
    if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
      node = node.parent;
    }
    if (node is LibraryIdentifier) {
      node = node.parent;
    }
    if (node is StringLiteral && node.parent is UriBasedDirective) {
      return null;
    }
    return ElementLocator.locate2(node);
  }

  /// Return a [LineInfo] for the file with the given [path].
  ///
  /// If the file does not exist or cannot be read, returns `null`.
  ///
  /// This method supports non-Dart files but uses the current content of the
  /// file which may not be the latest analyzed version of the file if it was
  /// recently modified, so using the LineInfo from an analyzed result may be
  /// preferable. This method exists mainly to support plugins which do not
  /// provide us a matching [LineInfo] for the content they used.
  LineInfo? getLineInfo(String path) {
    try {
      // First try from the overlay because it may be more up-to-date than
      // the file state.
      var content = resourceProvider.getFile(path).readAsStringSync();
      return LineInfo.fromContent(content);
    } on FileSystemException {
      // If the file does not exist or cannot be read, try the file state
      // because this could be something like a macro-generated file.
      var result = getAnalysisDriver(path)?.getFileSync(path);
      if (result is FileResult) {
        return result.lineInfo;
      }

      return null;
    }
  }

  /// Return a [Future] that completes with the resolved [AstNode] at the
  /// given [offset] of the given [file], or with `null` if there is no node as
  /// the [offset].
  Future<AstNode?> getNodeAtOffset(String file, int offset) async {
    var result = await getResolvedUnit(file);
    var unit = result?.unit;
    if (unit != null) {
      return NodeLocator(offset).searchWithin(unit);
    }
    return null;
  }

  /// Return the unresolved unit for the file with the given [path].
  ///
  /// Callers should handle [InconsistentAnalysisException] exceptions that may
  /// occur if a file is modified during this operation.
  Future<ParsedUnitResult?> getParsedUnit(String path) async {
    if (!file_paths.isDart(resourceProvider.pathContext, path)) {
      return null;
    }

    var session = await getAnalysisSession(path);
    if (session == null) {
      return null;
    }

    var result = session.getParsedUnit(path);
    return result is ParsedUnitResult ? result : null;
  }

  /// Return the resolved library for the library containing the file with the
  /// given [path]. The library is analyzed in one of the analysis drivers to
  /// which the file was added, otherwise in the first driver, otherwise `null`
  /// is returned.
  Future<ResolvedLibraryResult?> getResolvedLibrary(String path) async {
    if (!file_paths.isDart(resourceProvider.pathContext, path)) {
      return null;
    }
    var driver = getAnalysisDriver(path);
    if (driver == null) {
      return null;
    }
    try {
      return await driver.currentSession.getResolvedContainingLibrary(path);
    } on InconsistentAnalysisException {
      return null;
    } catch (exception, stackTrace) {
      instrumentationService.logException(exception, stackTrace);
    }
    return null;
  }

  /// Return the resolved unit for the file with the given [path]. The file is
  /// analyzed in one of the analysis drivers to which the file was added,
  /// otherwise in the first driver, otherwise `null` is returned.
  Future<ResolvedUnitResult?>? getResolvedUnit(
    String path, {
    bool sendCachedToStream = false,
  }) {
    if (!file_paths.isDart(resourceProvider.pathContext, path)) {
      return null;
    }

    var driver = getAnalysisDriver(path);
    if (driver == null) {
      return Future.value();
    }

    return driver
        .getResolvedUnit(path, sendCachedToStream: sendCachedToStream)
        .then((value) => value is ResolvedUnitResult ? value : null)
        .catchError((Object e, StackTrace st) {
          instrumentationService.logException(e, st);
          return null;
        });
  }

  /// Gets the version of a document known to the server, returning a
  /// [lsp.OptionalVersionedTextDocumentIdentifier] with a version of `null` if the
  /// document version is not known.
  lsp.OptionalVersionedTextDocumentIdentifier getVersionedDocumentIdentifier(
    String path,
  ) {
    return lsp.OptionalVersionedTextDocumentIdentifier(
      uri: resourceProvider.pathContext.toUri(path),
      version: getDocumentVersion(path),
    );
  }

  @mustCallSuper
  void handleAnalysisEvent(Object event) {
    switch (event) {
      case FileResult():
        contextManager.callbacks.handleFileResult(event);
      case analysis.AnalysisStatus():
        handleAnalysisStatusChange(event);
    }
  }

  @mustCallSuper
  FutureOr<void> handleAnalysisStatusChange(analysis.AnalysisStatus status) {
    if (isFirstAnalysisSinceContextsBuilt && !status.isWorking) {
      _timingByteStore?.newTimings('initial analysis completed');
      isFirstAnalysisSinceContextsBuilt = false;
      _dartFixPrompt.triggerCheck();
    }
  }

  /// Immediately handles an LSP message by delegating to the
  /// [lsp.InitializedStateMessageHandler]. This method does not schedule the
  /// message and is intended to be used by the scheduler (or LSP-over-Legacy
  /// where the original legacy wrapper was already scheduled).
  ///
  /// If the LSP server/support is not yet initialized, will wait until it is.
  FutureOr<lsp.ErrorOr<Object?>> immediatelyHandleLspMessage(
    lsp.IncomingMessage message,
    lsp.MessageInfo messageInfo, {
    lsp.CancellationToken? cancellationToken,
  }) async {
    // This is FutureOr<> because for the legacy server it's never a future, so
    // we can skip the await.
    var initializedLspHandler = lspInitialized;
    var handler =
        initializedLspHandler is lsp.InitializedStateMessageHandler
            ? initializedLspHandler
            : await initializedLspHandler;

    return handler.handleMessage(
      message,
      messageInfo,
      cancellationToken: cancellationToken,
    );
  }

  /// Return `true` if the file or directory with the given [path] will be
  /// analyzed in one of the analysis contexts.
  bool isAnalyzed(String path) {
    return contextManager.isAnalyzed(path);
  }

  void logExceptionResult(analysis.ExceptionResult result) {
    var message = 'Analysis failed: ${result.filePath}';
    if (result.contextKey != null) {
      message += ' context: ${result.contextKey}';
    }

    var attachments = crashReportingAttachmentsBuilder.forExceptionResult(
      result,
    );

    // TODO(39284): should this exception be silent?
    instrumentationService.logException(
      SilentException.wrapInMessage(message, result.exception),
      null,
      attachments,
    );
  }

  /// Notify the declarations tracker that the file with the given [path] was
  /// changed - added, updated, or removed.  Schedule processing of the file.
  void notifyDeclarationsTracker(String path) {
    analysisDriverScheduler.notify();
  }

  /// Notify the flutter widget properties support that the file with the
  /// given [path] was changed - added, updated, or removed.
  void notifyFlutterWidgetDescriptions(String path) {}

  /// Read all files, resolve all URIs, and perform required analysis in
  /// all current analysis drivers.
  Future<void> reanalyze() async {
    await contextManager.refresh();
  }

  /// Report analytics data related to the number and size of files that were
  /// analyzed.
  void reportAnalysisAnalytics() {
    var packagesFileMap = <String, File?>{};
    var immediateFileCount = 0;
    var immediateFileLineCount = 0;
    var transitiveFileCount = 0;
    var transitiveFileLineCount = 0;
    var transitiveFilePaths = <String>{};
    var transitiveFileUniqueLineCount = 0;
    var driverMap = contextManager.driverMap;
    for (var entry in driverMap.entries) {
      var rootPath = entry.key.path;
      var driver = entry.value;
      var contextRoot = driver.analysisContext?.contextRoot;
      if (contextRoot != null) {
        packagesFileMap[rootPath] = contextRoot.packagesFile;
      }
      var fileSystemState = driver.fsState;
      for (var fileState in fileSystemState.knownFiles) {
        var isImmediate = fileState.path.startsWith(rootPath);
        if (isImmediate) {
          immediateFileCount++;
          immediateFileLineCount += fileState.lineInfo.lineCount;
        } else {
          var lineCount = fileState.lineInfo.lineCount;
          transitiveFileCount++;
          transitiveFileLineCount += lineCount;
          if (transitiveFilePaths.add(fileState.path)) {
            transitiveFileUniqueLineCount += lineCount;
          }
        }
      }
    }
    var transitiveFileUniqueCount = transitiveFilePaths.length;

    var rootPaths = packagesFileMap.keys.toList();
    rootPaths.sort((first, second) => first.length.compareTo(second.length));
    var styleCounts = [
      0, // neither
      0, // only packages
      0, // only options -- (No longer incremented. Options files do not imply unique contexts.)
      0, // both -- (No longer incremented. Options files do not imply unique contexts.)
    ];
    var packagesFiles = <File>{};
    for (var rootPath in rootPaths) {
      var packagesFile = packagesFileMap[rootPath];
      var hasUniquePackageFile =
          packagesFile != null && packagesFiles.add(packagesFile);
      var style = hasUniquePackageFile ? 1 : 0;
      styleCounts[style]++;
    }

    analyticsManager.analysisComplete(
      numberOfContexts: driverMap.length,
      contextsWithoutFiles: styleCounts[0],
      contextsFromPackagesFiles: styleCounts[1],
      contextsFromOptionsFiles: styleCounts[2],
      contextsFromBothFiles: styleCounts[3],
      immediateFileCount: immediateFileCount,
      immediateFileLineCount: immediateFileLineCount,
      transitiveFileCount: transitiveFileCount,
      transitiveFileLineCount: transitiveFileLineCount,
      transitiveFileUniqueCount: transitiveFileUniqueCount,
      transitiveFileUniqueLineCount: transitiveFileUniqueLineCount,
    );
  }

  Future<ResolvedForCompletionResultImpl?> resolveForCompletion({
    required String path,
    required int offset,
    required OperationPerformanceImpl performance,
  }) async {
    if (!file_paths.isDart(resourceProvider.pathContext, path)) {
      return null;
    }

    var driver = getAnalysisDriver(path);
    if (driver == null) {
      return null;
    }

    try {
      await driver.applyPendingFileChanges();
      return await driver.resolveForCompletion(
        path: path,
        offset: offset,
        performance: performance,
      );
    } catch (e, st) {
      instrumentationService.logException(e, st);
    }
    return null;
  }

  /// Sends an LSP notification to the client.
  ///
  /// The legacy server will wrap LSP notifications inside an
  /// 'lsp.notification' notification.
  void sendLspNotification(lsp.NotificationMessage notification);

  /// Sends an error notification to the user.
  void sendServerErrorNotification(
    String message,
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  });

  /// Shows the user a prompt with some actions to select from using
  /// 'window/showMessageRequest'.
  ///
  /// Callers should use [userPromptSender] instead of calling this method
  /// directly because it returns null if the client does not support user
  /// prompts.
  @visibleForOverriding
  Future<String?> showUserPrompt(
    MessageType type,
    String message,
    List<String> actionLabels,
  );

  @mustCallSuper
  Future<void> shutdown() async {
    completeLspUninitialization();

    await analysisDriverSchedulerEventsSubscription?.cancel();
    analysisDriverSchedulerEventsSubscription = null;

    // For now we record plugins only on shutdown. We might want to record them
    // every time the set of plugins changes, in which case we'll need to listen
    // to the `PluginManager.pluginsChanged` stream.
    if (supportsPlugins) {
      analyticsManager.changedPlugins(pluginManager);
    }
    // For now we record context-dependent information only on shutdown. We
    // might want to record it on start-up as well.
    analyticsManager.createdAnalysisContexts(contextManager.analysisContexts);

    pubPackageService.shutdown();
    surveyManager?.shutdown();
    await contextManager.dispose();
    await analyticsManager.shutdown();
  }

  /// Return the path to the location of the byte store on disk, or `null` if
  /// there is no on-disk byte store.
  String? _getByteStorePath() {
    ResourceProvider provider = resourceProvider;
    if (provider is OverlayResourceProvider) {
      provider = provider.baseProvider;
    }
    if (provider is PhysicalResourceProvider) {
      var stateLocation = provider.getStateLocation('.analysis-driver');
      if (stateLocation != null) {
        return stateLocation.path;
      }
    }
    return null;
  }
}

/// ContextManager callbacks that operate on the base server regardless
/// of protocol.
abstract class CommonServerContextManagerCallbacks
    extends ContextManagerCallbacks {
  /// The [ResourceProvider] by which paths are converted into [Resource]s.
  final OverlayResourceProvider resourceProvider;

  /// The set of files for which notifications were sent.
  final Set<String> filesToFlush = {};

  CommonServerContextManagerCallbacks(this.resourceProvider);

  AnalysisServer get analysisServer;

  @override
  @mustCallSuper
  void afterContextsCreated() {
    analysisServer.afterContextsCreated();
  }

  @override
  @mustCallSuper
  void afterContextsDestroyed() {
    flushResults(filesToFlush.toList());
    filesToFlush.clear();
    analysisServer.afterContextsDestroyed();
  }

  @override
  void afterWatchEvent(WatchEvent event) {}

  @override
  @mustCallSuper
  void applyFileRemoved(String file) {
    // If the removed file doesn't have an overlay, we need to clear any
    // previous results.
    if (!resourceProvider.hasOverlay(file)) {
      // Clear the cached errors in the the notification manager so we don't
      // re-send stale results if a plugin sends an update and we merge it with
      // previous results.
      analysisServer.notificationManager.errors.clearResultsForFile(file);

      if (filesToFlush.remove(file)) {
        flushResults([file]);
      }
    }
  }

  @override
  @mustCallSuper
  void broadcastWatchEvent(WatchEvent event) {
    analysisServer.notifyDeclarationsTracker(event.path);
    analysisServer.notifyFlutterWidgetDescriptions(event.path);
    if (AnalysisServer.supportsPlugins) {
      analysisServer.pluginManager.broadcastWatchEvent(event);
    }
  }

  void flushResults(List<String> files);

  @override
  @mustCallSuper
  void handleFileResult(FileResult result) {
    var path = result.path;
    filesToFlush.add(path);

    // If this is a virtual file and the client supports URIs, we need to notify
    // that it's been updated.
    var lspUri = analysisServer.uriConverter.toClientUri(result.path);
    if (!lspUri.isScheme('file')) {
      // TODO(dantup): Should we do any kind of tracking here to avoid sending
      //  lots of notifications if there aren't actual changes?
      // TODO(dantup): We may be able to skip sending this if the file is not
      //  open (priority) depending on the response to
      //  https://github.com/microsoft/vscode/issues/202017
      var message = lsp.NotificationMessage(
        method: lsp.CustomMethods.dartTextDocumentContentDidChange,
        params: lsp.DartTextDocumentContentDidChangeParams(uri: lspUri),
        jsonrpc: lsp.jsonRpcVersion,
      );
      analysisServer.sendLspNotification(message);
    }

    if (result is AnalysisResultWithErrors) {
      if (analysisServer.isAnalyzed(path)) {
        var serverErrors = server.doAnalysisError_listFromEngine(result);
        recordAnalysisErrors(path, serverErrors);
      }
    }

    if (result is ResolvedUnitResult) {
      analysisServer.filesResolvedSinceLastIdle.add(path);
      handleResolvedUnitResult(result);
    }
  }

  void handleResolvedUnitResult(ResolvedUnitResult result);

  @override
  @mustCallSuper
  void listenAnalysisDriver(analysis.AnalysisDriver driver) {
    driver.exceptions.listen(analysisServer.logExceptionResult);
    driver.priorityFiles = analysisServer.priorityFiles.toList();
  }

  @override
  void pubspecChanged(String path) {
    analysisServer.pubPackageService.fetchPackageVersionsViaPubOutdated(
      path,
      pubspecWasModified: true,
    );
  }

  @override
  void pubspecRemoved(String path) {
    analysisServer.pubPackageService.flushPackageCaches(path);
  }

  @override
  @mustCallSuper
  void recordAnalysisErrors(String path, List<server.AnalysisError> errors) {
    filesToFlush.add(path);
    analysisServer.notificationManager.recordAnalysisErrors(
      NotificationManager.serverId,
      path,
      errors,
    );
  }
}

/// A server-agnostic type for messages sent to the client.
enum MessageType {
  error(lsp.MessageType.Error, legacy.MessageType.ERROR),
  warning(lsp.MessageType.Warning, legacy.MessageType.WARNING),
  info(lsp.MessageType.Info, legacy.MessageType.INFO),
  log(lsp.MessageType.Log, legacy.MessageType.LOG);

  final lsp.MessageType forLsp;
  final legacy.MessageType forLegacy;

  const MessageType(this.forLsp, this.forLegacy);
}

class ServerRecentPerformance {
  /// The maximum number of performance measurements to keep.
  static const int performanceListMaxLength = 50;

  /// The maximum number of slow performance measurements to keep.
  static const int slowRequestsListMaxLength = 1000;

  /// The duration we use to categorize requests as slow.
  static const Duration slowRequestsThreshold = Duration(milliseconds: 500);

  /// A list of code completion performance measurements for the latest
  /// completion operation up to [performanceListMaxLength] measurements.
  final RecentBuffer<CompletionPerformance> completion =
      RecentBuffer<CompletionPerformance>(performanceListMaxLength);

  /// A [RecentBuffer] for performance information about the most recent
  /// requests.
  final RecentBuffer<RequestPerformance> requests = RecentBuffer(
    performanceListMaxLength,
  );

  /// A [RecentBuffer] for performance information about the most recent
  /// slow requests.
  final RecentBuffer<RequestPerformance> slowRequests = RecentBuffer(
    slowRequestsListMaxLength,
  );
}
