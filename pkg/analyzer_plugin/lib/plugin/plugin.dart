// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/utilities/subscriptions/subscription_manager.dart';
import 'package:pub_semver/pub_semver.dart';

/// The abstract superclass of any class implementing a plugin for the analysis
/// server.
///
/// Clients may not implement or mix-in this class, but are expected to extend
/// it.
abstract class ServerPlugin {
  /// The communication channel being used to communicate with the analysis
  /// server.
  late PluginCommunicationChannel _channel;

  /// The resource provider used to access the file system.
  final OverlayResourceProvider resourceProvider;

  late final ByteStore _byteStore = createByteStore();

  AnalysisContextCollectionImpl? _contextCollection;

  /// The next modification stamp for a changed file in the [resourceProvider].
  int _overlayModificationStamp = 0;

  /// The path to the Dart SDK, set by the analysis server.
  String? _sdkPath;

  /// Paths of priority files.
  Set<String> priorityPaths = {};

  /// The object used to manage analysis subscriptions.
  final SubscriptionManager subscriptionManager = SubscriptionManager();

  /// Initialize a newly created analysis server plugin. If a resource [resourceProvider]
  /// is given, then it will be used to access the file system. Otherwise a
  /// resource provider that accesses the physical file system will be used.
  ServerPlugin({
    required ResourceProvider resourceProvider,
  }) : resourceProvider = OverlayResourceProvider(resourceProvider);

  /// Return the communication channel being used to communicate with the
  /// analysis server.
  PluginCommunicationChannel get channel => _channel;

  /// Return the user visible information about how to contact the plugin authors
  /// with any problems that are found, or `null` if there is no contact info.
  String? get contactInfo => null;

  /// Return a list of glob patterns selecting the files that this plugin is
  /// interested in analyzing.
  List<String> get fileGlobsToAnalyze;

  /// Return the user visible name of this plugin.
  String get name;

  /// Return the version number of the plugin spec required by this plugin,
  /// encoded as a string.
  String get version;

  /// This method is invoked when a new instance of [AnalysisContextCollection]
  /// is created, so the plugin can perform initial analysis of analyzed files.
  ///
  /// By default analyzes every [AnalysisContext] with [analyzeFiles].
  Future<void> afterNewContextCollection({
    required AnalysisContextCollection contextCollection,
  }) async {
    await _forAnalysisContexts(contextCollection, (analysisContext) async {
      var paths = analysisContext.contextRoot.analyzedFiles().toList();
      await analyzeFiles(
        analysisContext: analysisContext,
        paths: paths,
      );
    });
  }

  /// Analyzes the given file.
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  });

  /// Analyzes the given files.
  /// By default invokes [analyzeFile] for every file.
  /// Implementations may override to optimize for batch analysis.
  Future<void> analyzeFiles({
    required AnalysisContext analysisContext,
    required List<String> paths,
  }) async {
    var pathSet = paths.toSet();

    // First analyze priority files.
    for (var path in priorityPaths) {
      if (pathSet.remove(path)) {
        await analyzeFile(
          analysisContext: analysisContext,
          path: path,
        );
      }
    }

    // Then analyze the remaining files.
    for (var path in pathSet) {
      await analyzeFile(
        analysisContext: analysisContext,
        path: path,
      );
    }
  }

  /// This method is invoked immediately before the current
  /// [AnalysisContextCollection] is disposed.
  Future<void> beforeContextCollectionDispose({
    required AnalysisContextCollection contextCollection,
  }) async {}

  /// Handle the fact that files with [paths] were changed.
  Future<void> contentChanged(List<String> paths) async {
    var contextCollection = _contextCollection;
    if (contextCollection != null) {
      await _forAnalysisContexts(contextCollection, (analysisContext) async {
        for (var path in paths) {
          analysisContext.changeFile(path);
        }
        var affected = await analysisContext.applyPendingFileChanges();
        await handleAffectedFiles(
          analysisContext: analysisContext,
          paths: affected,
        );
      });
    }
  }

  /// This method is invoked once to create the [ByteStore] that is used for
  /// all [AnalysisContextCollection] instances, and reused when new instances
  /// are created (and so can perform analysis faster).
  ByteStore createByteStore() {
    return MemoryCachingByteStore(
      NullByteStore(),
      1024 * 1024 * 256,
    );
  }

  /// Plugin implementations can use this method to flush the state of
  /// analysis, so reduce the used heap size, after performing a set of
  /// operations, e.g. in [afterNewContextCollection] or [handleAffectedFiles].
  ///
  /// The next analysis operation will be slower, because it will restore
  /// the state from the byte store cache, or recompute.
  Future<void> flushAnalysisState({
    bool elementModels = true,
  }) async {
    var contextCollection = _contextCollection;
    if (contextCollection != null) {
      for (var analysisContext in contextCollection.contexts) {
        if (elementModels) {
          analysisContext.driver.clearLibraryContext();
        }
      }
    }
  }

  /// Return the result of analyzing the file with the given [path].
  ///
  /// Throw a [RequestFailure] is the file cannot be analyzed.
  Future<ResolvedUnitResult> getResolvedUnitResult(String path) async {
    var contextCollection = _contextCollection;
    if (contextCollection != null) {
      var analysisContext = contextCollection.contextFor(path);
      var analysisSession = analysisContext.currentSession;
      var unitResult = await analysisSession.getResolvedUnit(path);
      if (unitResult is ResolvedUnitResult) {
        return unitResult;
      }
    }
    // Return an error from the request.
    throw RequestFailure(
      RequestErrorFactory.pluginError('Failed to analyze $path', null),
    );
  }

  /// Handles files that might have been affected by a content change of
  /// one or more files. The implementation may check if these files should
  /// be analyzed, do such analysis, and send diagnostics.
  ///
  /// By default invokes [analyzeFiles] only for files that are analyzed in
  /// this [analysisContext].
  Future<void> handleAffectedFiles({
    required AnalysisContext analysisContext,
    required List<String> paths,
  }) async {
    var analyzedPaths = paths
        .where(analysisContext.contextRoot.isAnalyzed)
        .toList(growable: false);

    await analyzeFiles(
      analysisContext: analysisContext,
      paths: analyzedPaths,
    );
  }

  /// Handle an 'analysis.getNavigation' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<AnalysisGetNavigationResult> handleAnalysisGetNavigation(
      AnalysisGetNavigationParams parameters) async {
    return AnalysisGetNavigationResult(
        <String>[], <NavigationTarget>[], <NavigationRegion>[]);
  }

  /// Handle an 'analysis.handleWatchEvents' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<AnalysisHandleWatchEventsResult> handleAnalysisHandleWatchEvents(
      AnalysisHandleWatchEventsParams parameters) async {
    for (var event in parameters.events) {
      switch (event.type) {
        case WatchEventType.ADD:
          // TODO(brianwilkerson): Handle the event.
          break;
        case WatchEventType.MODIFY:
          await contentChanged([event.path]);
          break;
        case WatchEventType.REMOVE:
          // TODO(brianwilkerson): Handle the event.
          break;
      }
    }
    return AnalysisHandleWatchEventsResult();
  }

  /// Handle an 'analysis.setContextRoots' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<AnalysisSetContextRootsResult> handleAnalysisSetContextRoots(
      AnalysisSetContextRootsParams parameters) async {
    var currentContextCollection = _contextCollection;
    if (currentContextCollection != null) {
      _contextCollection = null;
      await beforeContextCollectionDispose(
        contextCollection: currentContextCollection,
      );
      await currentContextCollection.dispose();
    }

    var includedPaths = parameters.roots.map((e) => e.root).toList();
    var contextCollection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: includedPaths,
      byteStore: _byteStore,
      sdkPath: _sdkPath,
      fileContentCache: FileContentCache(resourceProvider),
    );
    _contextCollection = contextCollection;
    await afterNewContextCollection(
      contextCollection: contextCollection,
    );
    return AnalysisSetContextRootsResult();
  }

  /// Handle an 'analysis.setPriorityFiles' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<AnalysisSetPriorityFilesResult> handleAnalysisSetPriorityFiles(
      AnalysisSetPriorityFilesParams parameters) async {
    priorityPaths = parameters.files.toSet();
    return AnalysisSetPriorityFilesResult();
  }

  /// Handle an 'analysis.setSubscriptions' request. Most subclasses should not
  /// override this method, but should instead use the [subscriptionManager] to
  /// access the list of subscriptions for any given file.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<AnalysisSetSubscriptionsResult> handleAnalysisSetSubscriptions(
      AnalysisSetSubscriptionsParams parameters) async {
    var subscriptions = parameters.subscriptions;
    var newSubscriptions = subscriptionManager.setSubscriptions(subscriptions);
    sendNotificationsForSubscriptions(newSubscriptions);
    return AnalysisSetSubscriptionsResult();
  }

  /// Handle an 'analysis.updateContent' request. Most subclasses should not
  /// override this method, but should instead use the [contentCache] to access
  /// the current content of overlaid files.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<AnalysisUpdateContentResult> handleAnalysisUpdateContent(
      AnalysisUpdateContentParams parameters) async {
    var changedPaths = <String>{};
    var paths = parameters.files;
    paths.forEach((String path, Object? overlay) {
      // Prepare the old overlay contents.
      String? oldContents;
      try {
        if (resourceProvider.hasOverlay(path)) {
          var file = resourceProvider.getFile(path);
          oldContents = file.readAsStringSync();
        }
      } catch (_) {}

      // Prepare the new contents.
      String? newContents;
      if (overlay is AddContentOverlay) {
        newContents = overlay.content;
      } else if (overlay is ChangeContentOverlay) {
        if (oldContents == null) {
          // The server should only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw RequestFailure(
              RequestErrorFactory.invalidOverlayChangeNoContent());
        }
        try {
          newContents = SourceEdit.applySequence(oldContents, overlay.edits);
        } on RangeError {
          throw RequestFailure(
              RequestErrorFactory.invalidOverlayChangeInvalidEdit());
        }
      } else if (overlay is RemoveContentOverlay) {
        newContents = null;
      }

      if (newContents != null) {
        resourceProvider.setOverlay(
          path,
          content: newContents,
          modificationStamp: _overlayModificationStamp++,
        );
      } else {
        resourceProvider.removeOverlay(path);
      }

      changedPaths.add(path);
    });
    await contentChanged(changedPaths.toList());
    return AnalysisUpdateContentResult();
  }

  /// Handle a 'completion.getSuggestions' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<CompletionGetSuggestionsResult> handleCompletionGetSuggestions(
      CompletionGetSuggestionsParams parameters) async {
    return CompletionGetSuggestionsResult(
        -1, -1, const <CompletionSuggestion>[]);
  }

  /// Handle an 'edit.getAssists' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<EditGetAssistsResult> handleEditGetAssists(
      EditGetAssistsParams parameters) async {
    return EditGetAssistsResult(const <PrioritizedSourceChange>[]);
  }

  /// Handle an 'edit.getAvailableRefactorings' request. Subclasses that override
  /// this method in order to participate in refactorings must also override the
  /// method [handleEditGetRefactoring].
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<EditGetAvailableRefactoringsResult> handleEditGetAvailableRefactorings(
      EditGetAvailableRefactoringsParams parameters) async {
    return EditGetAvailableRefactoringsResult(const <RefactoringKind>[]);
  }

  /// Handle an 'edit.getFixes' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<EditGetFixesResult> handleEditGetFixes(
      EditGetFixesParams parameters) async {
    return EditGetFixesResult(const <AnalysisErrorFixes>[]);
  }

  /// Handle an 'edit.getRefactoring' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<EditGetRefactoringResult?> handleEditGetRefactoring(
      EditGetRefactoringParams parameters) async {
    return null;
  }

  /// Handle a 'plugin.shutdown' request. Subclasses can override this method to
  /// perform any required clean-up, but cannot prevent the plugin from shutting
  /// down.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<PluginShutdownResult> handlePluginShutdown(
      PluginShutdownParams parameters) async {
    return PluginShutdownResult();
  }

  /// Handle a 'plugin.versionCheck' request.
  ///
  /// Throw a [RequestFailure] if the request could not be handled.
  Future<PluginVersionCheckResult> handlePluginVersionCheck(
      PluginVersionCheckParams parameters) async {
    _sdkPath = parameters.sdkPath;
    var versionString = parameters.version;
    var serverVersion = Version.parse(versionString);
    return PluginVersionCheckResult(
        isCompatibleWith(serverVersion), name, version, fileGlobsToAnalyze,
        contactInfo: contactInfo);
  }

  /// Return `true` if this plugin is compatible with an analysis server that is
  /// using the given version of the plugin API.
  bool isCompatibleWith(Version serverVersion) =>
      serverVersion <= Version.parse(version);

  /// The method that is called when the analysis server closes the communication
  /// channel. This method will not be invoked under normal conditions because
  /// the server will send a shutdown request and the plugin will stop listening
  /// to the channel before the server closes the channel.
  void onDone() {}

  /// The method that is called when an error has occurred in the analysis
  /// server. This method will not be invoked under normal conditions.
  void onError(Object exception, StackTrace stackTrace) {}

  /// If the plugin provides folding information, send a folding notification
  /// for the file with the given [path] to the server.
  Future<void> sendFoldingNotification(String path) {
    return Future.value();
  }

  /// If the plugin provides highlighting information, send a highlights
  /// notification for the file with the given [path] to the server.
  Future<void> sendHighlightsNotification(String path) {
    return Future.value();
  }

  /// If the plugin provides navigation information, send a navigation
  /// notification for the file with the given [path] to the server.
  Future<void> sendNavigationNotification(String path) {
    return Future.value();
  }

  /// Send notifications for the services subscribed to for the file with the
  /// given [path].
  ///
  /// This is a convenience method that subclasses can use to send notifications
  /// after analysis has been performed on a file.
  void sendNotificationsForFile(String path) {
    for (var service in subscriptionManager.servicesForFile(path)) {
      _sendNotificationForFile(path, service);
    }
  }

  /// Send notifications corresponding to the given description of
  /// [subscriptions]. The map is keyed by the path of each file for which
  /// notifications should be sent and has values representing the list of
  /// services associated with the notifications to send.
  ///
  /// This method is used when the set of subscribed notifications has been
  /// changed and notifications need to be sent even when the specified files
  /// have already been analyzed.
  void sendNotificationsForSubscriptions(
      Map<String, List<AnalysisService>> subscriptions) {
    subscriptions.forEach((String path, List<AnalysisService> services) {
      for (var service in services) {
        _sendNotificationForFile(path, service);
      }
    });
  }

  /// If the plugin provides occurrences information, send an occurrences
  /// notification for the file with the given [path] to the server.
  Future<void> sendOccurrencesNotification(String path) {
    return Future.value();
  }

  /// If the plugin provides outline information, send an outline notification
  /// for the file with the given [path] to the server.
  Future<void> sendOutlineNotification(String path) {
    return Future.value();
  }

  /// Start this plugin by listening to the given communication [channel].
  void start(PluginCommunicationChannel channel) {
    _channel = channel;
    _channel.listen(_onRequest, onError: onError, onDone: onDone);
  }

  /// Invokes [f] first for priority analysis contexts, then for the rest.
  Future<void> _forAnalysisContexts(
    AnalysisContextCollection contextCollection,
    Future<void> Function(AnalysisContext analysisContext) f,
  ) async {
    var nonPriorityAnalysisContexts = <AnalysisContext>[];
    for (var analysisContext in contextCollection.contexts) {
      if (_isPriorityAnalysisContext(analysisContext)) {
        await f(analysisContext);
      } else {
        nonPriorityAnalysisContexts.add(analysisContext);
      }
    }

    for (var analysisContext in nonPriorityAnalysisContexts) {
      await f(analysisContext);
    }
  }

  /// Compute the response that should be returned for the given [request], or
  /// `null` if the response has already been sent.
  Future<Response?> _getResponse(Request request, int requestTime) async {
    ResponseResult? result;
    switch (request.method) {
      case ANALYSIS_REQUEST_GET_NAVIGATION:
        var params = AnalysisGetNavigationParams.fromRequest(request);
        result = await handleAnalysisGetNavigation(params);
        break;
      case ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS:
        var params = AnalysisHandleWatchEventsParams.fromRequest(request);
        result = await handleAnalysisHandleWatchEvents(params);
        break;
      case ANALYSIS_REQUEST_SET_CONTEXT_ROOTS:
        var params = AnalysisSetContextRootsParams.fromRequest(request);
        result = await handleAnalysisSetContextRoots(params);
        break;
      case ANALYSIS_REQUEST_SET_PRIORITY_FILES:
        var params = AnalysisSetPriorityFilesParams.fromRequest(request);
        result = await handleAnalysisSetPriorityFiles(params);
        break;
      case ANALYSIS_REQUEST_SET_SUBSCRIPTIONS:
        var params = AnalysisSetSubscriptionsParams.fromRequest(request);
        result = await handleAnalysisSetSubscriptions(params);
        break;
      case ANALYSIS_REQUEST_UPDATE_CONTENT:
        var params = AnalysisUpdateContentParams.fromRequest(request);
        result = await handleAnalysisUpdateContent(params);
        break;
      case COMPLETION_REQUEST_GET_SUGGESTIONS:
        var params = CompletionGetSuggestionsParams.fromRequest(request);
        result = await handleCompletionGetSuggestions(params);
        break;
      case EDIT_REQUEST_GET_ASSISTS:
        var params = EditGetAssistsParams.fromRequest(request);
        result = await handleEditGetAssists(params);
        break;
      case EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS:
        var params = EditGetAvailableRefactoringsParams.fromRequest(request);
        result = await handleEditGetAvailableRefactorings(params);
        break;
      case EDIT_REQUEST_GET_FIXES:
        var params = EditGetFixesParams.fromRequest(request);
        result = await handleEditGetFixes(params);
        break;
      case EDIT_REQUEST_GET_REFACTORING:
        var params = EditGetRefactoringParams.fromRequest(request);
        result = await handleEditGetRefactoring(params);
        break;
      case PLUGIN_REQUEST_SHUTDOWN:
        var params = PluginShutdownParams();
        result = await handlePluginShutdown(params);
        _channel.sendResponse(result.toResponse(request.id, requestTime));
        _channel.close();
        return null;
      case PLUGIN_REQUEST_VERSION_CHECK:
        var params = PluginVersionCheckParams.fromRequest(request);
        result = await handlePluginVersionCheck(params);
        break;
    }
    if (result == null) {
      return Response(request.id, requestTime,
          error: RequestErrorFactory.unknownRequest(request.method));
    }
    return result.toResponse(request.id, requestTime);
  }

  bool _isPriorityAnalysisContext(AnalysisContext analysisContext) {
    return priorityPaths.any(analysisContext.contextRoot.isAnalyzed);
  }

  /// The method that is called when a [request] is received from the analysis
  /// server.
  Future<void> _onRequest(Request request) async {
    var requestTime = DateTime.now().millisecondsSinceEpoch;
    var id = request.id;
    Response? response;
    try {
      response = await _getResponse(request, requestTime);
    } on RequestFailure catch (exception) {
      response = Response(id, requestTime, error: exception.error);
    } catch (exception, stackTrace) {
      response = Response(id, requestTime,
          error: RequestError(
              RequestErrorCode.PLUGIN_ERROR, exception.toString(),
              stackTrace: stackTrace.toString()));
    }
    if (response != null) {
      _channel.sendResponse(response);
    }
  }

  /// Send a notification for the file at the given [path] corresponding to the
  /// given [service].
  void _sendNotificationForFile(String path, AnalysisService service) {
    switch (service) {
      case AnalysisService.FOLDING:
        sendFoldingNotification(path);
        break;
      case AnalysisService.HIGHLIGHTS:
        sendHighlightsNotification(path);
        break;
      case AnalysisService.NAVIGATION:
        sendNavigationNotification(path);
        break;
      case AnalysisService.OCCURRENCES:
        sendOccurrencesNotification(path);
        break;
      case AnalysisService.OUTLINE:
        sendOutlineNotification(path);
        break;
    }
  }
}
