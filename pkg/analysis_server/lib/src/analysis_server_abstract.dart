// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:io' as io;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/file_string_sink.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analysis_server/src/utilities/tee_string_sink.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/file_byte_store.dart'
    show EvictingFileByteStore;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/util/glob.dart';

/// Implementations of [AbstractAnalysisServer] implement a server that listens
/// on a [CommunicationChannel] for analysis messages and process them.
abstract class AbstractAnalysisServer {
  /// The options of this server instance.
  AnalysisServerOptions options;

  /// The builder for attachments that should be included into crash reports.
  final CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder;

  /// The [ContextManager] that handles the mapping from analysis roots to
  /// context directories.
  ContextManager contextManager;

  /// The object used to manage sending a subset of notifications to the client.
  /// The subset of notifications are those to which plugins may contribute.
  /// This field is `null` when the new plugin support is disabled.
  AbstractNotificationManager notificationManager;

  /// The object used to manage the execution of plugins.
  PluginManager pluginManager;

  /// The object used to manage the SDK's known to this server.
  final DartSdkManager sdkManager;

  /// The [SearchEngine] for this server, may be `null` if indexing is disabled.
  SearchEngine searchEngine;

  ByteStore byteStore;

  nd.AnalysisDriverScheduler analysisDriverScheduler;

  DeclarationsTracker declarationsTracker;
  DeclarationsTrackerData declarationsTrackerData;

  /// The DiagnosticServer for this AnalysisServer. If available, it can be used
  /// to start an http diagnostics server or return the port for an existing
  /// server.
  final DiagnosticServer diagnosticServer;

  /// A [RecentBuffer] of the most recent exceptions encountered by the analysis
  /// server.
  final RecentBuffer<ServerException> exceptions = RecentBuffer(10);

  /// The instrumentation service that is to be used by this analysis server.
  InstrumentationService instrumentationService;

  /// Performance information after initial analysis is complete
  /// or `null` if the initial analysis is not yet complete
  ServerPerformance performanceAfterStartup;

  /// The class into which performance information is currently being recorded.
  /// During startup, this will be the same as [performanceDuringStartup]
  /// and after startup is complete, this switches to [performanceAfterStartup].
  ServerPerformance performance;

  /// Performance information before initial analysis is complete.
  final ServerPerformance performanceDuringStartup = ServerPerformance();

  RequestStatisticsHelper requestStatistics;

  PerformanceLog analysisPerformanceLogger;

  /// The set of the files that are currently priority.
  final Set<String> priorityFiles = <String>{};

  final List<String> analyzableFilePatterns = <String>[
    '**/*.${AnalysisEngine.SUFFIX_DART}',
    '**/*.${AnalysisEngine.SUFFIX_HTML}',
    '**/*.${AnalysisEngine.SUFFIX_HTM}',
    '**/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}',
    '**/${AnalysisEngine.PUBSPEC_YAML_FILE}',
    '**/${AnalysisEngine.ANDROID_MANIFEST_FILE}'
  ];

  /// The [ResourceProvider] using which paths are converted into [Resource]s.
  final OverlayResourceProvider resourceProvider;

  /// The next modification stamp for a changed file in the [resourceProvider].
  int overlayModificationStamp = 0;

  /// A list of the globs used to determine which files should be analyzed. The
  /// list is lazily created and should be accessed using [analyzedFilesGlobs].
  List<Glob> _analyzedFilesGlobs;

  AbstractAnalysisServer(
    this.options,
    this.sdkManager,
    this.diagnosticServer,
    this.crashReportingAttachmentsBuilder,
    ResourceProvider baseResourceProvider,
    this.instrumentationService,
    this.notificationManager, {
    this.requestStatistics,
  }) : resourceProvider = OverlayResourceProvider(baseResourceProvider) {
    performance = performanceDuringStartup;

    pluginManager = PluginManager(
        resourceProvider,
        _getByteStorePath(),
        sdkManager.defaultSdkDirectory,
        notificationManager,
        instrumentationService);
    var pluginWatcher = PluginWatcher(resourceProvider, pluginManager);

    {
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
      if (requestStatistics != null) {
        sink = TeeStringSink(sink, requestStatistics.perfLoggerStringSink);
      }
      analysisPerformanceLogger = PerformanceLog(sink);
    }

    byteStore = createByteStore(resourceProvider);

    analysisDriverScheduler = nd.AnalysisDriverScheduler(
        analysisPerformanceLogger,
        driverWatcher: pluginWatcher);

    if (options.featureSet.completion) {
      declarationsTracker = DeclarationsTracker(byteStore, resourceProvider);
      declarationsTrackerData = DeclarationsTrackerData(declarationsTracker);
      analysisDriverScheduler.outOfBandWorker =
          CompletionLibrariesWorker(declarationsTracker);
    }

    contextManager = ContextManagerImpl(resourceProvider, sdkManager,
        analyzedFilesGlobs, instrumentationService);
    searchEngine = SearchEngineImpl(driverMap.values);
  }

  /// Return a list of the globs used to determine which files should be
  /// analyzed.
  List<Glob> get analyzedFilesGlobs {
    if (_analyzedFilesGlobs == null) {
      _analyzedFilesGlobs = <Glob>[];
      for (var pattern in analyzableFilePatterns) {
        try {
          _analyzedFilesGlobs
              .add(Glob(resourceProvider.pathContext.separator, pattern));
        } catch (exception, stackTrace) {
          AnalysisEngine.instance.instrumentationService.logException(
              CaughtException.withMessage(
                  'Invalid glob pattern: "$pattern"', exception, stackTrace));
        }
      }
    }
    return _analyzedFilesGlobs;
  }

  /// The list of current analysis sessions in all contexts.
  List<AnalysisSession> get currentSessions {
    return driverMap.values.map((driver) => driver.currentSession).toList();
  }

  /// A table mapping [Folder]s to the [AnalysisDriver]s associated with them.
  Map<Folder, nd.AnalysisDriver> get driverMap => contextManager.driverMap;

  /// Return the total time the server's been alive.
  Duration get uptime {
    var start =
        DateTime.fromMillisecondsSinceEpoch(performanceDuringStartup.startTime);
    return DateTime.now().difference(start);
  }

  void addContextsToDeclarationsTracker() {
    for (var driver in driverMap.values) {
      declarationsTracker?.addContext(driver.analysisContext);
      driver.resetUriResolution();
    }
  }

  /// If the state location can be accessed, return the file byte store,
  /// otherwise return the memory byte store.
  ByteStore createByteStore(ResourceProvider resourceProvider) {
    const M = 1024 * 1024 /*1 MiB*/;
    const G = 1024 * 1024 * 1024 /*1 GiB*/;

    const memoryCacheSize = 128 * M;

    if (resourceProvider is OverlayResourceProvider) {
      OverlayResourceProvider overlay = resourceProvider;
      resourceProvider = overlay.baseProvider;
    }
    if (resourceProvider is PhysicalResourceProvider) {
      var stateLocation = resourceProvider.getStateLocation('.analysis-driver');
      if (stateLocation != null) {
        return MemoryCachingByteStore(
            EvictingFileByteStore(stateLocation.path, G), memoryCacheSize);
      }
    }

    return MemoryCachingByteStore(NullByteStore(), memoryCacheSize);
  }

  /// Return an analysis driver to which the file with the given [path] is
  /// added if one exists, otherwise a driver in which the file was analyzed if
  /// one exists, otherwise the first driver, otherwise `null`.
  nd.AnalysisDriver getAnalysisDriver(String path) {
    var drivers = driverMap.values.toList();
    if (drivers.isNotEmpty) {
      // Sort the drivers so that more deeply nested contexts will be checked
      // before enclosing contexts.
      drivers.sort((first, second) =>
          second.contextRoot.root.length - first.contextRoot.root.length);
      var driver = drivers.firstWhere(
          (driver) => driver.contextRoot.containsFile(path),
          orElse: () => null);
      driver ??= drivers.firstWhere(
          (driver) => driver.knownFiles.contains(path),
          orElse: () => null);
      driver ??= drivers.first;
      return driver;
    }
    return null;
  }

  /// Return the appropriate analysis session for the file with the given
  /// [path].
  AnalysisSession getAnalysisSession(String path) =>
      getAnalysisDriver(path).currentSession;

  DartdocDirectiveInfo getDartdocDirectiveInfoFor(ResolvedUnitResult result) {
    return declarationsTracker
            ?.getContext(result.session.analysisContext)
            ?.dartdocDirectiveInfo ??
        DartdocDirectiveInfo();
  }

  /// Return a [Future] that completes with the [Element] at the given
  /// [offset] of the given [file], or with `null` if there is no node at the
  /// [offset] or the node does not have an element.
  Future<Element> getElementAtOffset(String file, int offset) async {
    if (!priorityFiles.contains(file)) {
      var driver = getAnalysisDriver(file);
      if (driver == null) {
        return null;
      }

      var unitElementResult = await driver.getUnitElement(file);
      if (unitElementResult == null) {
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

  /// Return the [Element] of the given [node], or `null` if [node] is `null` or
  /// does not have an element.
  Element getElementOfNode(AstNode node) {
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

  /// Return a [Future] that completes with the resolved [AstNode] at the
  /// given [offset] of the given [file], or with `null` if there is no node as
  /// the [offset].
  Future<AstNode> getNodeAtOffset(String file, int offset) async {
    var result = await getResolvedUnit(file);
    var unit = result?.unit;
    if (unit != null) {
      return NodeLocator(offset).searchWithin(unit);
    }
    return null;
  }

  /// Return the unresolved unit for the file with the given [path].
  ParsedUnitResult getParsedUnit(String path) {
    if (!AnalysisEngine.isDartFileName(path)) {
      return null;
    }

    return getAnalysisDriver(path)?.currentSession?.getParsedUnit(path);
  }

  /// Return the resolved unit for the file with the given [path]. The file is
  /// analyzed in one of the analysis drivers to which the file was added,
  /// otherwise in the first driver, otherwise `null` is returned.
  Future<ResolvedUnitResult> getResolvedUnit(String path,
      {bool sendCachedToStream = false}) {
    if (!AnalysisEngine.isDartFileName(path)) {
      return null;
    }

    var driver = getAnalysisDriver(path);
    if (driver == null) {
      return Future.value();
    }

    return driver
        .getResult(path, sendCachedToStream: sendCachedToStream)
        .catchError((e, st) {
      AnalysisEngine.instance.instrumentationService.logException(e, st);
      return null;
    });
  }

  void logExceptionResult(nd.ExceptionResult result) {
    var message = 'Analysis failed: ${result.filePath}';
    if (result.contextKey != null) {
      message += ' context: ${result.contextKey}';
    }

    var attachments =
        crashReportingAttachmentsBuilder.forExceptionResult(result);

    // TODO(39284): should this exception be silent?
    AnalysisEngine.instance.instrumentationService.logException(
      SilentException.wrapInMessage(message, result.exception),
      null,
      attachments,
    );
  }

  /// Notify the declarations tracker that the file with the given [path] was
  /// changed - added, updated, or removed.  Schedule processing of the file.
  void notifyDeclarationsTracker(String path) {
    declarationsTracker?.changeFile(path);
    analysisDriverScheduler.notify(null);
  }

  /// Notify the flutter widget properties support that the file with the
  /// given [path] was changed - added, updated, or removed.
  void notifyFlutterWidgetDescriptions(String path) {}

  /// Read all files, resolve all URIs, and perform required analysis in
  /// all current analysis drivers.
  void reanalyze() {
    for (var driver in driverMap.values) {
      driver.resetUriResolution();
    }
  }

  /// Sends an error notification to the user.
  void sendServerErrorNotification(
    String message,
    dynamic exception,
    /*StackTrace*/ stackTrace, {
    bool fatal = false,
  });

  void updateContextInDeclarationsTracker(nd.AnalysisDriver driver) {
    declarationsTracker?.discardContext(driver.analysisContext);
    declarationsTracker?.addContext(driver.analysisContext);
  }

  /// Return the path to the location of the byte store on disk, or `null` if
  /// there is no on-disk byte store.
  String _getByteStorePath() {
    ResourceProvider provider = resourceProvider;
    if (provider is OverlayResourceProvider) {
      provider = (provider as OverlayResourceProvider).baseProvider;
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
