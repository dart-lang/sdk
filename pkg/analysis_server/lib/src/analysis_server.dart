// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io' as io;
import 'dart:math' show max;

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart'
    show PROTOCOL_VERSION;
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/analysis_server_abstract.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/computer/computer_highlights2.dart';
import 'package:analysis_server/src/computer/new_notifications.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_analytics.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/domain_diagnostic.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/domain_kythe.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/domains/analysis/occurrences.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/flutter/flutter_domain.dart';
import 'package:analysis_server/src/flutter/flutter_notifications.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:analysis_server/src/search/search_domain.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/features.dart';
import 'package:analysis_server/src/services/flutter/widget_descriptions.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/file_state.dart' as nd;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as nd;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:telemetry/crash_reporting.dart';
import 'package:telemetry/telemetry.dart' as telemetry;
import 'package:watcher/watcher.dart';

typedef void OptionUpdater(AnalysisOptionsImpl options);

/// Instances of the class [AnalysisServer] implement a server that listens on a
/// [CommunicationChannel] for analysis requests and process them.
class AnalysisServer extends AbstractAnalysisServer {
  /// The channel from which requests are received and to which responses should
  /// be sent.
  final ServerCommunicationChannel channel;

  /// The object used to manage sending a subset of notifications to the client.
  /// The subset of notifications are those to which plugins may contribute.
  /// This field is `null` when the new plugin support is disabled.
  NotificationManager notificationManager;

  /// The object used to manage the execution of plugins.
  PluginManager pluginManager;

  /// The [SearchEngine] for this server, may be `null` if indexing is disabled.
  SearchEngine searchEngine;

  /// A flag indicating the value of the 'analyzing' parameter sent in the last
  /// status message to the client.
  bool statusAnalyzing = false;

  /// A list of the request handlers used to handle the requests sent to this
  /// server.
  List<RequestHandler> handlers;

  /// The object used to manage the SDK's known to this server.
  final DartSdkManager sdkManager;

  /// The instrumentation service that is to be used by this analysis server.
  final InstrumentationService instrumentationService;

  /// A set of the [ServerService]s to send notifications for.
  Set<ServerService> serverServices = new HashSet<ServerService>();

  /// A set of the [GeneralAnalysisService]s to send notifications for.
  Set<GeneralAnalysisService> generalAnalysisServices =
      new HashSet<GeneralAnalysisService>();

  /// A table mapping [AnalysisService]s to the file paths for which these
  /// notifications should be sent.
  Map<AnalysisService, Set<String>> analysisServices =
      new HashMap<AnalysisService, Set<String>>();

  /// A table mapping [FlutterService]s to the file paths for which these
  /// notifications should be sent.
  Map<FlutterService, Set<String>> flutterServices = {};

  /// The support for Flutter properties.
  WidgetDescriptions flutterWidgetDescriptions = WidgetDescriptions();

  /// The [Completer] that completes when analysis is complete.
  Completer _onAnalysisCompleteCompleter;

  /// The controller that is notified when analysis is started.
  StreamController<bool> _onAnalysisStartedController;

  /// If the "analysis.analyzedFiles" notification is currently being subscribed
  /// to (see [generalAnalysisServices]), and at least one such notification has
  /// been sent since the subscription was enabled, the set of analyzed files
  /// that was delivered in the most recently sent notification.  Otherwise
  /// `null`.
  Set<String> prevAnalyzedFiles;

  /// The default options used to create new analysis contexts. This object is
  /// also referenced by the ContextManager.
  final AnalysisOptionsImpl defaultContextOptions = new AnalysisOptionsImpl();

  /// The file resolver provider used to override the way file URI's are
  /// resolved in some contexts.
  ResolverProvider fileResolverProvider;

  /// The package resolver provider used to override the way package URI's are
  /// resolved in some contexts.
  ResolverProvider packageResolverProvider;

  PerformanceLog _analysisPerformanceLogger;

  /// The controller for [onAnalysisSetChanged].
  final StreamController _onAnalysisSetChangedController =
      new StreamController.broadcast(sync: true);

  final DetachableFileSystemManager detachableFileSystemManager;

  /// Initialize a newly created server to receive requests from and send
  /// responses to the given [channel].
  ///
  /// If [rethrowExceptions] is true, then any exceptions thrown by analysis are
  /// propagated up the call stack.  The default is true to allow analysis
  /// exceptions to show up in unit tests, but it should be set to false when
  /// running a full analysis server.
  AnalysisServer(
    this.channel,
    ResourceProvider baseResourceProvider,
    AnalysisServerOptions options,
    this.sdkManager,
    this.instrumentationService, {
    DiagnosticServer diagnosticServer,
    ResolverProvider fileResolverProvider = null,
    ResolverProvider packageResolverProvider = null,
    this.detachableFileSystemManager = null,
  }) : super(options, diagnosticServer, baseResourceProvider) {
    notificationManager = new NotificationManager(channel, resourceProvider);

    pluginManager = new PluginManager(
        resourceProvider,
        _getByteStorePath(),
        sdkManager.defaultSdkDirectory,
        notificationManager,
        instrumentationService);
    PluginWatcher pluginWatcher =
        new PluginWatcher(resourceProvider, pluginManager);

    defaultContextOptions.generateImplicitErrors = false;
    defaultContextOptions.useFastaParser = options.useFastaParser;

    {
      String name = options.newAnalysisDriverLog;
      StringSink sink = new NullStringSink();
      if (name != null) {
        if (name == 'stdout') {
          sink = io.stdout;
        } else if (name.startsWith('file:')) {
          String path = name.substring('file:'.length);
          sink = new io.File(path).openWrite(mode: io.FileMode.append);
        }
      }
      _analysisPerformanceLogger = new PerformanceLog(sink);
    }

    byteStore = createByteStore(resourceProvider);

    analysisDriverScheduler = new nd.AnalysisDriverScheduler(
        _analysisPerformanceLogger,
        driverWatcher: pluginWatcher);
    analysisDriverScheduler.status.listen(sendStatusNotificationNew);
    analysisDriverScheduler.start();

    if (options.featureSet.completion) {
      declarationsTracker = DeclarationsTracker(byteStore, resourceProvider);
      declarationsTrackerData = DeclarationsTrackerData(declarationsTracker);
      analysisDriverScheduler.outOfBandWorker =
          CompletionLibrariesWorker(declarationsTracker);
    }

    contextManager = new ContextManagerImpl(
        resourceProvider,
        sdkManager,
        packageResolverProvider,
        analyzedFilesGlobs,
        instrumentationService,
        defaultContextOptions);
    this.fileResolverProvider = fileResolverProvider;
    this.packageResolverProvider = packageResolverProvider;
    ServerContextManagerCallbacks contextManagerCallbacks =
        new ServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;
    AnalysisEngine.instance.logger = new AnalysisLogger(this);
    _onAnalysisStartedController = new StreamController.broadcast();
    onAnalysisStarted.first.then((_) {
      onAnalysisComplete.then((_) {
        performanceAfterStartup = new ServerPerformance();
        performance = performanceAfterStartup;
      });
    });
    searchEngine = new SearchEngineImpl(driverMap.values);
    Notification notification = new ServerConnectedParams(
            PROTOCOL_VERSION, io.pid,
            sessionId: instrumentationService.sessionId)
        .toNotification();
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
    handlers = <server.RequestHandler>[
      new ServerDomainHandler(this),
      new AnalysisDomainHandler(this),
      new EditDomainHandler(this),
      new SearchDomainHandler(this),
      new CompletionDomainHandler(this),
      new ExecutionDomainHandler(this),
      new DiagnosticDomainHandler(this),
      new AnalyticsDomainHandler(this),
      new KytheDomainHandler(this),
      new FlutterDomainHandler(this)
    ];
  }

  /// The analytics instance; note, this object can be `null`.
  telemetry.Analytics get analytics => options.analytics;

  /// The [Future] that completes when analysis is complete.
  Future get onAnalysisComplete {
    if (isAnalysisComplete()) {
      return new Future.value();
    }
    if (_onAnalysisCompleteCompleter == null) {
      _onAnalysisCompleteCompleter = new Completer();
    }
    return _onAnalysisCompleteCompleter.future;
  }

  /// The stream that is notified when the analysis set is changed - this might
  /// be a change to a file, external via a watch event, or internal via
  /// overlay. This means that the resolved world might have changed.
  ///
  /// The type of produced elements is not specified and should not be used.
  Stream get onAnalysisSetChanged => _onAnalysisSetChangedController.stream;

  /// The stream that is notified with `true` when analysis is started.
  Stream<bool> get onAnalysisStarted {
    return _onAnalysisStartedController.stream;
  }

  /// The socket from which requests are being read has been closed.
  void done() {}

  /// There was an error related to the socket from which requests are being
  /// read.
  void error(argument) {}

  /// Return one of the SDKs that has been created, or `null` if no SDKs have
  /// been created yet.
  DartSdk findSdk() {
    DartSdk sdk = sdkManager.anySdk;
    if (sdk != null) {
      return sdk;
    }
    // TODO(brianwilkerson) Should we create an SDK using the default options?
    return null;
  }

  /// Return the cached analysis result for the file with the given [path].
  /// If there is no cached result, return `null`.
  ResolvedUnitResult getCachedResolvedUnit(String path) {
    if (!AnalysisEngine.isDartFileName(path)) {
      return null;
    }

    nd.AnalysisDriver driver = getAnalysisDriver(path);
    return driver?.getCachedResult(path);
  }

  /// Handle a [request] that was read from the communication channel.
  void handleRequest(Request request) {
    performance.logRequestTiming(request.clientRequestTime);
    runZoned(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() {
        int count = handlers.length;
        for (int i = 0; i < count; i++) {
          try {
            Response response = handlers[i].handleRequest(request);
            if (response == Response.DELAYED_RESPONSE) {
              return;
            }
            if (response != null) {
              channel.sendResponse(response);
              return;
            }
          } on RequestFailure catch (exception) {
            channel.sendResponse(exception.response);
            return;
          } catch (exception, stackTrace) {
            RequestError error = new RequestError(
                RequestErrorCode.SERVER_ERROR, exception.toString());
            if (stackTrace != null) {
              error.stackTrace = stackTrace.toString();
            }
            Response response = new Response(request.id, error: error);
            channel.sendResponse(response);
            return;
          }
        }
        channel.sendResponse(new Response.unknownRequest(request));
      });
    }, onError: (exception, stackTrace) {
      sendServerErrorNotification(
          'Failed to handle request: ${request.toJson()}',
          exception,
          stackTrace,
          fatal: true);
    });
  }

  /// Return `true` if the [path] is both absolute and normalized.
  bool isAbsoluteAndNormalized(String path) {
    var pathContext = resourceProvider.pathContext;
    return pathContext.isAbsolute(path) && pathContext.normalize(path) == path;
  }

  /// Return `true` if analysis is complete.
  bool isAnalysisComplete() {
    return !analysisDriverScheduler.isAnalyzing;
  }

  /// Return `true` if the given path is a valid `FilePath`.
  ///
  /// This means that it is absolute and normalized.
  bool isValidFilePath(String path) {
    return resourceProvider.pathContext.isAbsolute(path) &&
        resourceProvider.pathContext.normalize(path) == path;
  }

  /// Read all files, resolve all URIs, and perform required analysis in
  /// all current analysis drivers.
  void reanalyze() {
    for (var driver in driverMap.values) {
      driver.resetUriResolution();
    }
  }

  /// Send the given [notification] to the client.
  void sendNotification(Notification notification) {
    channel.sendNotification(notification);
  }

  /// Send the given [response] to the client.
  void sendResponse(Response response) {
    channel.sendResponse(response);
  }

  /// If the [path] is not a valid file path, that is absolute and normalized,
  /// send an error response, and return `true`. If OK then return `false`.
  bool sendResponseErrorIfInvalidFilePath(Request request, String path) {
    if (!isAbsoluteAndNormalized(path)) {
      sendResponse(Response.invalidFilePathFormat(request, path));
      return true;
    }
    return false;
  }

  /// Sends a `server.error` notification.
  void sendServerErrorNotification(
    String message,
    dynamic exception,
    /*StackTrace*/ stackTrace, {
    bool fatal = false,
  }) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(exception ?? 'null exception');
    if (stackTrace != null) {
      buffer.writeln();
      buffer.write(stackTrace);
    } else if (exception is! CaughtException) {
      stackTrace = StackTrace.current;
      buffer.writeln();
      buffer.write(stackTrace);
    }

    // send the notification
    channel.sendNotification(
        new ServerErrorParams(fatal, message, buffer.toString())
            .toNotification());

    // send to crash reporting
    if (options.crashReportSender != null) {
      options.crashReportSender
          .sendReport(exception,
              stackTrace: stackTrace is StackTrace ? stackTrace : null)
          .catchError((_) {
        // Catch and ignore any exceptions when reporting exceptions (network
        // errors or other).
      });
    }

    // remember the last few exceptions
    if (exception is CaughtException) {
      stackTrace ??= exception.stackTrace;
    }
    exceptions.add(new ServerException(
      message,
      exception,
      stackTrace is StackTrace ? stackTrace : null,
      fatal,
    ));
  }

  /// Send status notification to the client. The state of analysis is given by
  /// the [status] information.
  void sendStatusNotificationNew(nd.AnalysisStatus status) {
    if (status.isAnalyzing) {
      _onAnalysisStartedController.add(true);
    }
    if (_onAnalysisCompleteCompleter != null && !status.isAnalyzing) {
      _onAnalysisCompleteCompleter.complete();
      _onAnalysisCompleteCompleter = null;
    }
    // Perform on-idle actions.
    if (!status.isAnalyzing) {
      if (generalAnalysisServices
          .contains(GeneralAnalysisService.ANALYZED_FILES)) {
        sendAnalysisNotificationAnalyzedFiles(this);
      }
      _scheduleAnalysisImplementedNotification();
    }
    // Only send status when subscribed.
    if (!serverServices.contains(ServerService.STATUS)) {
      return;
    }
    // Only send status when it changes
    if (statusAnalyzing == status.isAnalyzing) {
      return;
    }
    statusAnalyzing = status.isAnalyzing;
    AnalysisStatus analysis = new AnalysisStatus(status.isAnalyzing);
    channel.sendNotification(
        new ServerStatusParams(analysis: analysis).toNotification());
  }

  /// Implementation for `analysis.setAnalysisRoots`.
  ///
  /// TODO(scheglov) implement complete projects/contexts semantics.
  ///
  /// The current implementation is intentionally simplified and expected
  /// that only folders are given each given folder corresponds to the exactly
  /// one context.
  ///
  /// So, we can start working in parallel on adding services and improving
  /// projects/contexts support.
  void setAnalysisRoots(String requestId, List<String> includedPaths,
      List<String> excludedPaths, Map<String, String> packageRoots) {
    declarationsTracker?.discardContexts();
    if (notificationManager != null) {
      notificationManager.setAnalysisRoots(includedPaths, excludedPaths);
    }
    try {
      contextManager.setRoots(includedPaths, excludedPaths, packageRoots);
    } on UnimplementedError catch (e) {
      throw new RequestFailure(
          new Response.unsupportedFeature(requestId, e.message));
    }
    addContextsToDeclarationsTracker();
  }

  /// Implementation for `analysis.setSubscriptions`.
  void setAnalysisSubscriptions(
      Map<AnalysisService, Set<String>> subscriptions) {
    if (notificationManager != null) {
      notificationManager.setSubscriptions(subscriptions);
    }
    this.analysisServices = subscriptions;
    Set<String> allNewFiles =
        subscriptions.values.expand((files) => files).toSet();
    for (String file in allNewFiles) {
      // The result will be produced by the "results" stream with
      // the fully resolved unit, and processed with sending analysis
      // notifications as it happens after content changes.
      if (AnalysisEngine.isDartFileName(file)) {
        getResolvedUnit(file, sendCachedToStream: true);
      }
    }
  }

  /// Implementation for `flutter.setSubscriptions`.
  void setFlutterSubscriptions(Map<FlutterService, Set<String>> subscriptions) {
    this.flutterServices = subscriptions;
    Set<String> allNewFiles =
        subscriptions.values.expand((files) => files).toSet();
    for (String file in allNewFiles) {
      // The result will be produced by the "results" stream with
      // the fully resolved unit, and processed with sending analysis
      // notifications as it happens after content changes.
      if (AnalysisEngine.isDartFileName(file)) {
        getResolvedUnit(file, sendCachedToStream: true);
      }
    }
  }

  /// Implementation for `analysis.setGeneralSubscriptions`.
  void setGeneralAnalysisSubscriptions(
      List<GeneralAnalysisService> subscriptions) {
    Set<GeneralAnalysisService> newServices = subscriptions.toSet();
    if (newServices.contains(GeneralAnalysisService.ANALYZED_FILES) &&
        !generalAnalysisServices
            .contains(GeneralAnalysisService.ANALYZED_FILES) &&
        isAnalysisComplete()) {
      sendAnalysisNotificationAnalyzedFiles(this);
    } else if (!newServices.contains(GeneralAnalysisService.ANALYZED_FILES) &&
        generalAnalysisServices
            .contains(GeneralAnalysisService.ANALYZED_FILES)) {
      prevAnalyzedFiles = null;
    }
    generalAnalysisServices = newServices;
  }

  /// Set the priority files to the given [files].
  void setPriorityFiles(String requestId, List<String> files) {
    priorityFiles.clear();
    priorityFiles.addAll(files);
    // Set priority files in drivers.
    driverMap.values.forEach((driver) {
      driver.priorityFiles = files;
    });
  }

  /// Returns `true` if errors should be reported for [file] with the given
  /// absolute path.
  bool shouldSendErrorsNotificationFor(String file) {
    // Errors should not be reported for things that are explicitly skipped
    // during normal analysis (for example dot folders are skipped over in
    // _handleWatchEventImpl).
    return contextManager.isInAnalysisRoot(file) &&
        !contextManager.isContainedInDotFolder(file);
  }

  Future<void> shutdown() {
    if (options.analytics != null) {
      options.analytics
          .waitForLastPing(timeout: new Duration(milliseconds: 200))
          .then((_) {
        options.analytics.close();
      });
    }

    detachableFileSystemManager?.dispose();

    // Defer closing the channel and shutting down the instrumentation server so
    // that the shutdown response can be sent and logged.
    new Future(() {
      instrumentationService.shutdown();
      channel.close();
    });

    return new Future.value();
  }

  /// Implementation for `analysis.updateContent`.
  void updateContent(String id, Map<String, dynamic> changes) {
    _onAnalysisSetChangedController.add(null);
    changes.forEach((file, change) {
      // Prepare the old overlay contents.
      String oldContents;
      try {
        if (resourceProvider.hasOverlay(file)) {
          oldContents = resourceProvider.getFile(file).readAsStringSync();
        }
      } catch (_) {}

      // Prepare the new contents.
      String newContents;
      if (change is AddContentOverlay) {
        newContents = change.content;
      } else if (change is ChangeContentOverlay) {
        if (oldContents == null) {
          // The client may only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw new RequestFailure(new Response(id,
              error: new RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                  'Invalid overlay change')));
        }
        try {
          newContents = SourceEdit.applySequence(oldContents, change.edits);
        } on RangeError {
          throw new RequestFailure(new Response(id,
              error: new RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                  'Invalid overlay change')));
        }
      } else if (change is RemoveContentOverlay) {
        newContents = null;
      } else {
        // Protocol parsing should have ensured that we never get here.
        throw new AnalysisException('Illegal change type');
      }

      if (newContents != null) {
        resourceProvider.setOverlay(
          file,
          content: newContents,
          modificationStamp: overlayModificationStamp++,
        );
      } else {
        resourceProvider.removeOverlay(file);
      }

      driverMap.values.forEach((driver) {
        driver.changeFile(file);
      });

      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.
      contextManager.getDriverFor(file)?.addFile(file);

      notifyDeclarationsTracker(file);

      // TODO(scheglov) implement other cases
    });
  }

  /// Use the given updaters to update the values of the options in every
  /// existing analysis context.
  void updateOptions(List<OptionUpdater> optionUpdaters) {
    // TODO(scheglov) implement for the new analysis driver
//    //
//    // Update existing contexts.
//    //
//    for (AnalysisContext context in analysisContexts) {
//      AnalysisOptionsImpl options =
//          new AnalysisOptionsImpl.from(context.analysisOptions);
//      optionUpdaters.forEach((OptionUpdater optionUpdater) {
//        optionUpdater(options);
//      });
//      context.analysisOptions = options;
//      // TODO(brianwilkerson) As far as I can tell, this doesn't cause analysis
//      // to be scheduled for this context.
//    }
//    //
//    // Update the defaults used to create new contexts.
//    //
//    optionUpdaters.forEach((OptionUpdater optionUpdater) {
//      optionUpdater(defaultContextOptions);
//    });
  }

  /// Return the path to the location of the byte store on disk, or `null` if
  /// there is no on-disk byte store.
  String _getByteStorePath() {
    ResourceProvider provider = resourceProvider;
    if (provider is OverlayResourceProvider) {
      provider = (provider as OverlayResourceProvider).baseProvider;
    }
    if (provider is PhysicalResourceProvider) {
      Folder stateLocation = provider.getStateLocation('.analysis-driver');
      if (stateLocation != null) {
        return stateLocation.path;
      }
    }
    return null;
  }

  /// Returns `true` if there is a subscription for the given [service] and
  /// [file].
  bool _hasAnalysisServiceSubscription(AnalysisService service, String file) {
    return analysisServices[service]?.contains(file) ?? false;
  }

  bool _hasFlutterServiceSubscription(FlutterService service, String file) {
    return flutterServices[service]?.contains(file) ?? false;
  }

  Future<void> _scheduleAnalysisImplementedNotification() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    Set<String> files = analysisServices[AnalysisService.IMPLEMENTED];
    if (files != null) {
      scheduleImplementedNotification(this, files);
    }
  }
}

/// Various IDE options.
class AnalysisServerOptions {
  bool useAnalysisHighlight2 = false;

  String fileReadMode = 'as-is';
  String newAnalysisDriverLog;

  String clientId;
  String clientVersion;

  /// Base path where to cache data.
  String cacheFolder;

  /// The analytics instance; note, this object can be `null`, and should be
  /// accessed via a null-aware operator.
  telemetry.Analytics analytics;

  /// The crash report sender instance; note, this object can be `null`, and
  /// should be accessed via a null-aware operator.
  CrashReportSender crashReportSender;

  /// Whether to use the Language Server Protocol.
  bool useLanguageServerProtocol = false;

  /// Whether to enable parsing via the Fasta parser.
  bool useFastaParser = true;

  /// The set of enabled features.
  FeatureSet featureSet = FeatureSet();
}

class ServerContextManagerCallbacks extends ContextManagerCallbacks {
  final AnalysisServer analysisServer;

  /// The [ResourceProvider] by which paths are converted into [Resource]s.
  final ResourceProvider resourceProvider;

  ServerContextManagerCallbacks(this.analysisServer, this.resourceProvider);

  @override
  NotificationManager get notificationManager =>
      analysisServer.notificationManager;

  @override
  nd.AnalysisDriver addAnalysisDriver(
      Folder folder, ContextRoot contextRoot, AnalysisOptions options) {
    ContextBuilder builder = createContextBuilder(folder, options);
    nd.AnalysisDriver analysisDriver = builder.buildDriver(contextRoot);
    analysisDriver.results.listen((result) {
      NotificationManager notificationManager =
          analysisServer.notificationManager;
      String path = result.path;
      if (analysisServer.shouldSendErrorsNotificationFor(path)) {
        if (notificationManager != null) {
          notificationManager.recordAnalysisErrors(NotificationManager.serverId,
              path, server.doAnalysisError_listFromEngine(result));
        } else {
          new_sendErrorNotification(analysisServer, result);
        }
      }
      CompilationUnit unit = result.unit;
      if (unit != null) {
        if (notificationManager != null) {
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.HIGHLIGHTS, path)) {
            _runDelayed(() {
              notificationManager.recordHighlightRegions(
                  NotificationManager.serverId,
                  path,
                  _computeHighlightRegions(unit));
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.NAVIGATION, path)) {
            _runDelayed(() {
              notificationManager.recordNavigationParams(
                  NotificationManager.serverId,
                  path,
                  _computeNavigationParams(path, unit));
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.OCCURRENCES, path)) {
            _runDelayed(() {
              notificationManager.recordOccurrences(
                  NotificationManager.serverId,
                  path,
                  _computeOccurrences(unit));
            });
          }
//          if (analysisServer._hasAnalysisServiceSubscription(
//              AnalysisService.OUTLINE, path)) {
//            _runDelayed(() {
//              // TODO(brianwilkerson) Change NotificationManager to store params
//              // so that fileKind and libraryName can be recorded / passed along.
//              notificationManager.recordOutlines(NotificationManager.serverId,
//                  path, _computeOutlineParams(path, unit, result.lineInfo));
//            });
//          }
        } else {
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.HIGHLIGHTS, path)) {
            _runDelayed(() {
              sendAnalysisNotificationHighlights(analysisServer, path, unit);
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.NAVIGATION, path)) {
            _runDelayed(() {
              new_sendDartNotificationNavigation(analysisServer, result);
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.OCCURRENCES, path)) {
            _runDelayed(() {
              new_sendDartNotificationOccurrences(analysisServer, result);
            });
          }
        }
        if (analysisServer._hasAnalysisServiceSubscription(
            AnalysisService.CLOSING_LABELS, path)) {
          _runDelayed(() {
            sendAnalysisNotificationClosingLabels(
                analysisServer, path, result.lineInfo, unit);
          });
        }
        if (analysisServer._hasAnalysisServiceSubscription(
            AnalysisService.FOLDING, path)) {
          _runDelayed(() {
            sendAnalysisNotificationFolding(
                analysisServer, path, result.lineInfo, unit);
          });
        }
        if (analysisServer._hasAnalysisServiceSubscription(
            AnalysisService.OUTLINE, path)) {
          _runDelayed(() {
            sendAnalysisNotificationOutline(analysisServer, result);
          });
        }
        if (analysisServer._hasAnalysisServiceSubscription(
            AnalysisService.OVERRIDES, path)) {
          _runDelayed(() {
            sendAnalysisNotificationOverrides(analysisServer, path, unit);
          });
        }
        if (analysisServer._hasFlutterServiceSubscription(
            FlutterService.OUTLINE, path)) {
          _runDelayed(() {
            sendFlutterNotificationOutline(analysisServer, result);
          });
        }
        // TODO(scheglov) Implement notifications for AnalysisService.IMPLEMENTED.
      }
    });
    analysisDriver.exceptions.listen((nd.ExceptionResult result) {
      String message = 'Analysis failed: ${result.path}';
      if (result.contextKey != null) {
        message += ' context: ${result.contextKey}';
      }
      AnalysisEngine.instance.logger.logError(message, result.exception);
    });
    analysisServer.driverMap[folder] = analysisDriver;
    return analysisDriver;
  }

  @override
  void afterWatchEvent(WatchEvent event) {
    analysisServer._onAnalysisSetChangedController.add(null);
  }

  @override
  void analysisOptionsUpdated(nd.AnalysisDriver driver) {
    analysisServer.updateContextInDeclarationsTracker(driver);
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    nd.AnalysisDriver analysisDriver = analysisServer.driverMap[contextFolder];
    if (analysisDriver != null) {
      changeSet.addedSources.forEach((source) {
        analysisDriver.addFile(source.fullName);
      });
      changeSet.changedSources.forEach((source) {
        analysisDriver.changeFile(source.fullName);
      });
      changeSet.removedSources.forEach((source) {
        analysisDriver.removeFile(source.fullName);
      });
    }
  }

  @override
  void applyFileRemoved(nd.AnalysisDriver driver, String file) {
    driver.removeFile(file);
    sendAnalysisNotificationFlushResults(analysisServer, [file]);
  }

  @override
  void broadcastWatchEvent(WatchEvent event) {
    analysisServer.notifyDeclarationsTracker(event.path);
    analysisServer.pluginManager.broadcastWatchEvent(event);
  }

  @override
  ContextBuilder createContextBuilder(Folder folder, AnalysisOptions options) {
    String defaultPackageFilePath = null;
    String defaultPackagesDirectoryPath = null;
    String path = (analysisServer.contextManager as ContextManagerImpl)
        .normalizedPackageRoots[folder.path];
    if (path != null) {
      Resource resource = resourceProvider.getResource(path);
      if (resource.exists) {
        if (resource is File) {
          defaultPackageFilePath = path;
        } else {
          defaultPackagesDirectoryPath = path;
        }
      }
    }

    ContextBuilderOptions builderOptions = new ContextBuilderOptions();
    builderOptions.defaultOptions = options;
    builderOptions.defaultPackageFilePath = defaultPackageFilePath;
    builderOptions.defaultPackagesDirectoryPath = defaultPackagesDirectoryPath;
    ContextBuilder builder = new ContextBuilder(
        resourceProvider, analysisServer.sdkManager, null,
        options: builderOptions);
    builder.fileResolverProvider = analysisServer.fileResolverProvider;
    builder.packageResolverProvider = analysisServer.packageResolverProvider;
    builder.analysisDriverScheduler = analysisServer.analysisDriverScheduler;
    builder.performanceLog = analysisServer._analysisPerformanceLogger;
    builder.byteStore = analysisServer.byteStore;
    builder.enableIndex = true;
    return builder;
  }

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);
    nd.AnalysisDriver driver = analysisServer.driverMap.remove(folder);
    driver.dispose();
  }

  List<HighlightRegion> _computeHighlightRegions(CompilationUnit unit) {
    if (analysisServer.options.useAnalysisHighlight2) {
      return new DartUnitHighlightsComputer2(unit).compute();
    } else {
      return new DartUnitHighlightsComputer(unit).compute();
    }
  }

  server.AnalysisNavigationParams _computeNavigationParams(
      String path, CompilationUnit unit) {
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    computeDartNavigation(resourceProvider, collector, unit, null, null);
    collector.createRegions();
    return new server.AnalysisNavigationParams(
        path, collector.regions, collector.targets, collector.files);
  }

  List<Occurrences> _computeOccurrences(CompilationUnit unit) {
    OccurrencesCollectorImpl collector = new OccurrencesCollectorImpl();
    addDartOccurrences(collector, unit);
    return collector.allOccurrences;
  }

  /// Run [f] in a new [Future].
  ///
  /// This method is used to delay sending notifications. If there is a more
  /// important consumer of an analysis results, specifically a code completion
  /// computer, we want it to run before spending time of sending notifications.
  ///
  /// TODO(scheglov) Consider replacing this with full priority based scheduler.
  ///
  /// TODO(scheglov) Alternatively, if code completion work in a way that does
  /// not produce (at first) fully resolved unit, but only part of it - a single
  /// method, or a top-level declaration, we would not have this problem - the
  /// completion computer would be the only consumer of the partial analysis
  /// result.
  void _runDelayed(f()) {
    new Future(f);
  }
}

/// Used to record server exceptions.
class ServerException {
  final String message;
  final dynamic exception;
  final StackTrace stackTrace;
  final bool fatal;

  ServerException(this.message, this.exception, this.stackTrace, this.fatal);

  @override
  String toString() => message;
}

/// A class used by [AnalysisServer] to record performance information
/// such as request latency.
class ServerPerformance {
  /// The creation time and the time when performance information
  /// started to be recorded here.
  final int startTime = new DateTime.now().millisecondsSinceEpoch;

  /// The number of requests.
  int requestCount = 0;

  /// The number of requests that recorded latency information.
  int latencyCount = 0;

  /// The total latency (milliseconds) for all recorded requests.
  int requestLatency = 0;

  /// The maximum latency (milliseconds) for all recorded requests.
  int maxLatency = 0;

  /// The number of requests with latency > 150 milliseconds.
  int slowRequestCount = 0;

  /// Log timing information for a request.
  void logRequestTiming(int clientRequestTime) {
    ++requestCount;
    if (clientRequestTime != null) {
      int latency =
          new DateTime.now().millisecondsSinceEpoch - clientRequestTime;
      ++latencyCount;
      requestLatency += latency;
      maxLatency = max(maxLatency, latency);
      if (latency > 150) {
        ++slowRequestCount;
      }
    }
  }
}

/// Container with global [AnalysisServer] performance statistics.
class ServerPerformanceStatistics {
  /// The [PerformanceTag] for `package:analysis_server`.
  static final PerformanceTag server = new PerformanceTag('server');

  /// The [PerformanceTag] for time spent between calls to
  /// AnalysisServer.performOperation when the server is idle.
  static final PerformanceTag idle = new PerformanceTag('idle');

  /// The [PerformanceTag] for time spent in
  /// PerformAnalysisOperation._sendNotices.
  static final PerformanceTag notices = server.createChild('notices');

  /// The [PerformanceTag] for time spent in server communication channels.
  static final PerformanceTag serverChannel = server.createChild('channel');

  /// The [PerformanceTag] for time spent in server request handlers.
  static final PerformanceTag serverRequests = server.createChild('requests');
}
