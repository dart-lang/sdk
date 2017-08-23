// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriverGeneric, AnalysisDriverScheduler;
import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/src/utilities/null_string_sink.dart';
import 'package:analyzer_plugin/utilities/subscriptions/subscription_manager.dart';
import 'package:path/src/context.dart';
import 'package:pub_semver/pub_semver.dart';

/**
 * The abstract superclass of any class implementing a plugin for the analysis
 * server.
 *
 * Clients may not implement or mix-in this class, but are expected to extend
 * it.
 */
abstract class ServerPlugin {
  /**
   * A megabyte.
   */
  static const int M = 1024 * 1024;

  /**
   * The communication channel being used to communicate with the analysis
   * server.
   */
  PluginCommunicationChannel _channel;

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * The object used to manage analysis subscriptions.
   */
  final SubscriptionManager subscriptionManager = new SubscriptionManager();

  /**
   * The scheduler used by any analysis drivers that are created.
   */
  AnalysisDriverScheduler analysisDriverScheduler;

  /**
   * A table mapping the current context roots to the analysis driver created
   * for that root.
   */
  final Map<ContextRoot, AnalysisDriverGeneric> driverMap =
      <ContextRoot, AnalysisDriverGeneric>{};

  /**
   * The performance log used by any analysis drivers that are created.
   */
  final PerformanceLog performanceLog =
      new PerformanceLog(new NullStringSink());

  /**
   * The byte store used by any analysis drivers that are created, or `null` if
   * the cache location isn't known because the 'plugin.version' request has not
   * yet been received.
   */
  ByteStore _byteStore;

  /**
   * The SDK manager used to manage SDKs.
   */
  DartSdkManager _sdkManager;

  /**
   * The file content overlay used by any analysis drivers that are created.
   */
  final FileContentOverlay fileContentOverlay = new FileContentOverlay();

  /**
   * Initialize a newly created analysis server plugin. If a resource [provider]
   * is given, then it will be used to access the file system. Otherwise a
   * resource provider that accesses the physical file system will be used.
   */
  ServerPlugin(ResourceProvider provider)
      : resourceProvider = provider ?? PhysicalResourceProvider.INSTANCE {
    analysisDriverScheduler = new AnalysisDriverScheduler(performanceLog);
    analysisDriverScheduler.start();
  }

  /**
   * Return the byte store used by any analysis drivers that are created, or
   * `null` if the cache location isn't known because the 'plugin.version'
   * request has not yet been received.
   */
  ByteStore get byteStore => _byteStore;

  /**
   * Return the communication channel being used to communicate with the
   * analysis server, or `null` if the plugin has not been started.
   */
  PluginCommunicationChannel get channel => _channel;

  /**
   * Return the user visible information about how to contact the plugin authors
   * with any problems that are found, or `null` if there is no contact info.
   */
  String get contactInfo => null;

  /**
   * Return a list of glob patterns selecting the files that this plugin is
   * interested in analyzing.
   */
  List<String> get fileGlobsToAnalyze;

  /**
   * Return the user visible name of this plugin.
   */
  String get name;

  /**
   * Return the SDK manager used to manage SDKs.
   */
  DartSdkManager get sdkManager => _sdkManager;

  /**
   * Return the version number of this plugin, encoded as a string.
   */
  String get version;

  /**
   * Handle the fact that the file with the given [path] has been modified.
   */
  void contentChanged(String path) {
    // Ignore changes to files.
  }

  /**
   * Return the context root containing the file at the given [filePath].
   */
  ContextRoot contextRootContaining(String filePath) {
    Context pathContext = resourceProvider.pathContext;

    /**
     * Return `true` if the given [child] is either the same as or within the
     * given [parent].
     */
    bool isOrWithin(String parent, String child) {
      return parent == child || pathContext.isWithin(parent, child);
    }

    /**
     * Return `true` if the given context [root] contains the target [file].
     */
    bool ownsFile(ContextRoot root) {
      if (isOrWithin(root.root, filePath)) {
        List<String> excludedPaths = root.exclude;
        for (String excludedPath in excludedPaths) {
          if (isOrWithin(excludedPath, filePath)) {
            return false;
          }
        }
        return true;
      }
      return false;
    }

    for (ContextRoot root in driverMap.keys) {
      if (ownsFile(root)) {
        return root;
      }
    }
    return null;
  }

  /**
   * Create an analysis driver that can analyze the files within the given
   * [contextRoot].
   */
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot);

  /**
   * Return the driver being used to analyze the file with the given [path].
   */
  AnalysisDriverGeneric driverForPath(String path) {
    ContextRoot contextRoot = contextRootContaining(path);
    if (contextRoot == null) {
      return null;
    }
    return driverMap[contextRoot];
  }

  /**
   * Handle an 'analysis.getNavigation' request.
   */
  Future<AnalysisGetNavigationResult> handleAnalysisGetNavigation(
      AnalysisGetNavigationParams params) async {
    return new AnalysisGetNavigationResult(
        <String>[], <NavigationTarget>[], <NavigationRegion>[]);
  }

  /**
   * Handle an 'analysis.handleWatchEvents' request.
   */
  Future<AnalysisHandleWatchEventsResult> handleAnalysisHandleWatchEvents(
      AnalysisHandleWatchEventsParams parameters) async {
    for (WatchEvent event in parameters.events) {
      switch (event.type) {
        case WatchEventType.ADD:
          // TODO(brianwilkerson) Handle the event.
          break;
        case WatchEventType.MODIFY:
          contentChanged(event.path);
          break;
        case WatchEventType.REMOVE:
          // TODO(brianwilkerson) Handle the event.
          break;
        default:
          // Ignore unhandled watch event types.
          break;
      }
    }
    return new AnalysisHandleWatchEventsResult();
  }

  /**
   * Handle an 'analysis.setContextRoots' request.
   */
  Future<AnalysisSetContextRootsResult> handleAnalysisSetContextRoots(
      AnalysisSetContextRootsParams parameters) async {
    List<ContextRoot> contextRoots = parameters.roots;
    List<ContextRoot> oldRoots = driverMap.keys.toList();
    for (ContextRoot contextRoot in contextRoots) {
      if (!oldRoots.remove(contextRoot)) {
        // The context is new, so we create a driver for it. Creating the driver
        // has the side-effect of adding it to the analysis driver scheduler.
        AnalysisDriverGeneric driver = createAnalysisDriver(contextRoot);
        driverMap[contextRoot] = driver;
        _addFilesToDriver(
            driver,
            resourceProvider.getResource(contextRoot.root),
            contextRoot.exclude);
      }
    }
    for (ContextRoot contextRoot in oldRoots) {
      // The context has been removed, so we remove its driver.
      AnalysisDriverGeneric driver = driverMap.remove(contextRoot);
      // The `dispose` method has the side-effect of removing the driver from
      // the analysis driver scheduler.
      driver.dispose();
    }
    return new AnalysisSetContextRootsResult();
  }

  /**
   * Handle an 'analysis.setPriorityFiles' request.
   */
  Future<AnalysisSetPriorityFilesResult> handleAnalysisSetPriorityFiles(
      AnalysisSetPriorityFilesParams parameters) async {
    List<String> files = parameters.files;
    Map<AnalysisDriverGeneric, List<String>> filesByDriver =
        <AnalysisDriverGeneric, List<String>>{};
    for (String file in files) {
      ContextRoot contextRoot = contextRootContaining(file);
      if (contextRoot != null) {
        // TODO(brianwilkerson) Which driver should we use if there is no context root?
        AnalysisDriverGeneric driver = driverMap[contextRoot];
        filesByDriver.putIfAbsent(driver, () => <String>[]).add(file);
      }
    }
    filesByDriver.forEach((AnalysisDriverGeneric driver, List<String> files) {
      driver.priorityFiles = files;
    });
    return new AnalysisSetPriorityFilesResult();
  }

  /**
   * Handle an 'analysis.setSubscriptions' request. Most subclasses should not
   * override this method, but should instead use the [subscriptionManager] to
   * access the list of subscriptions for any given file.
   */
  Future<AnalysisSetSubscriptionsResult> handleAnalysisSetSubscriptions(
      AnalysisSetSubscriptionsParams parameters) async {
    Map<AnalysisService, List<String>> subscriptions = parameters.subscriptions;
    Map<String, List<AnalysisService>> newSubscriptions =
        subscriptionManager.setSubscriptions(subscriptions);
    sendNotificationsForSubscriptions(newSubscriptions);
    return new AnalysisSetSubscriptionsResult();
  }

  /**
   * Handle an 'analysis.updateContent' request. Most subclasses should not
   * override this method, but should instead use the [contentCache] to access
   * the current content of overlaid files.
   */
  Future<AnalysisUpdateContentResult> handleAnalysisUpdateContent(
      AnalysisUpdateContentParams parameters) async {
    Map<String, Object> files = parameters.files;
    files.forEach((String filePath, Object overlay) {
      if (overlay is AddContentOverlay) {
        fileContentOverlay[filePath] = overlay.content;
      } else if (overlay is ChangeContentOverlay) {
        String oldContents = fileContentOverlay[filePath];
        String newContents;
        if (oldContents == null) {
          // The server should only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw new RequestFailure(
              RequestErrorFactory.invalidOverlayChangeNoContent());
        }
        try {
          newContents = SourceEdit.applySequence(oldContents, overlay.edits);
        } on RangeError {
          throw new RequestFailure(
              RequestErrorFactory.invalidOverlayChangeInvalidEdit());
        }
        fileContentOverlay[filePath] = newContents;
      } else if (overlay is RemoveContentOverlay) {
        fileContentOverlay[filePath] = null;
      }
      contentChanged(filePath);
    });
    return new AnalysisUpdateContentResult();
  }

  /**
   * Handle a 'completion.getSuggestions' request.
   */
  Future<CompletionGetSuggestionsResult> handleCompletionGetSuggestions(
          CompletionGetSuggestionsParams parameters) async =>
      new CompletionGetSuggestionsResult(
          -1, -1, const <CompletionSuggestion>[]);

  /**
   * Handle an 'edit.getAssists' request.
   */
  Future<EditGetAssistsResult> handleEditGetAssists(
          EditGetAssistsParams parameters) async =>
      new EditGetAssistsResult(const <PrioritizedSourceChange>[]);

  /**
   * Handle an 'edit.getAvailableRefactorings' request. Subclasses that override
   * this method in order to participate in refactorings must also override the
   * method [handleEditGetRefactoring].
   */
  Future<EditGetAvailableRefactoringsResult> handleEditGetAvailableRefactorings(
          EditGetAvailableRefactoringsParams parameters) async =>
      new EditGetAvailableRefactoringsResult(const <RefactoringKind>[]);

  /**
   * Handle an 'edit.getFixes' request.
   */
  Future<EditGetFixesResult> handleEditGetFixes(
          EditGetFixesParams parameters) async =>
      new EditGetFixesResult(const <AnalysisErrorFixes>[]);

  /**
   * Handle an 'edit.getRefactoring' request.
   */
  Future<EditGetRefactoringResult> handleEditGetRefactoring(
          EditGetRefactoringParams parameters) async =>
      null;

  /**
   * Handle a 'kythe.getKytheEntries' request.
   */
  Future<KytheGetKytheEntriesResult> handleKytheGetKytheEntries(
          KytheGetKytheEntriesParams parameters) async =>
      null;

  /**
   * Handle a 'plugin.shutdown' request. Subclasses can override this method to
   * perform any required clean-up, but cannot prevent the plugin from shutting
   * down.
   */
  Future<PluginShutdownResult> handlePluginShutdown(
          PluginShutdownParams parameters) async =>
      new PluginShutdownResult();

  /**
   * Handle a 'plugin.versionCheck' request.
   */
  Future<PluginVersionCheckResult> handlePluginVersionCheck(
      PluginVersionCheckParams parameters) async {
    String byteStorePath = parameters.byteStorePath;
    String sdkPath = parameters.sdkPath;
    String versionString = parameters.version;
    Version serverVersion = new Version.parse(versionString);
    _byteStore =
        new MemoryCachingByteStore(new FileByteStore(byteStorePath), 64 * M);
    _sdkManager = new DartSdkManager(sdkPath, true);
    return new PluginVersionCheckResult(
        isCompatibleWith(serverVersion), name, version, fileGlobsToAnalyze,
        contactInfo: contactInfo);
  }

  /**
   * Return `true` if this plugin is compatible with an analysis server that is
   * using the given version of the plugin API.
   */
  bool isCompatibleWith(Version serverVersion) =>
      serverVersion <= new Version.parse(version);

  /**
   * The method that is called when the analysis server closes the communication
   * channel. This method will not be invoked under normal conditions because
   * the server will send a shutdown request and the plugin will stop listening
   * to the channel before the server closes the channel.
   */
  void onDone() {}

  /**
   * The method that is called when an error has occurred in the analysis
   * server. This method will not be invoked under normal conditions.
   */
  void onError(Object exception, StackTrace stackTrace) {}

  /**
   * If the plugin provides folding information, send a folding notification
   * for the file with the given [path] to the server.
   */
  Future<Null> sendFoldingNotification(String path) {
    return new Future.value();
  }

  /**
   * If the plugin provides highlighting information, send a highlights
   * notification for the file with the given [path] to the server.
   */
  Future<Null> sendHighlightsNotification(String path) {
    return new Future.value();
  }

  /**
   * If the plugin provides navigation information, send a navigation
   * notification for the file with the given [path] to the server.
   */
  Future<Null> sendNavigationNotification(String path) {
    return new Future.value();
  }

  /**
   * Send notifications for the services subscribed to for the file with the
   * given [path].
   *
   * This is a convenience method that subclasses can use to send notifications
   * after analysis has been performed on a file.
   */
  void sendNotificationsForFile(String path) {
    for (AnalysisService service in subscriptionManager.servicesForFile(path)) {
      _sendNotificationForFile(path, service);
    }
  }

  /**
   * Send notifications corresponding to the given description of
   * [subscriptions]. The map is keyed by the path of each file for which
   * notifications should be sent and has values representing the list of
   * services associated with the notifications to send.
   *
   * This method is used when the set of subscribed notifications has been
   * changed and notifications need to be sent even when the specified files
   * have already been analyzed.
   */
  void sendNotificationsForSubscriptions(
      Map<String, List<AnalysisService>> subscriptions) {
    subscriptions.forEach((String path, List<AnalysisService> services) {
      for (AnalysisService service in services) {
        _sendNotificationForFile(path, service);
      }
    });
  }

  /**
   * If the plugin provides occurrences information, send an occurrences
   * notification for the file with the given [path] to the server.
   */
  Future<Null> sendOccurrencesNotification(String path) {
    return new Future.value();
  }

  /**
   * If the plugin provides outline information, send an outline notification
   * for the file with the given [path] to the server.
   */
  Future<Null> sendOutlineNotification(String path) {
    return new Future.value();
  }

  /**
   * Start this plugin by listening to the given communication [channel].
   */
  void start(PluginCommunicationChannel channel) {
    _channel = channel;
    _channel.listen(_onRequest, onError: onError, onDone: onDone);
  }

  /**
   * Add all of the files contained in the given [resource] that are not in the
   * list of [excluded] resources to the given [driver].
   */
  void _addFilesToDriver(
      AnalysisDriverGeneric driver, Resource resource, List<String> excluded) {
    String path = resource.path;
    if (excluded.contains(path)) {
      return;
    }
    if (resource is File) {
      driver.addFile(path);
    } else if (resource is Folder) {
      try {
        for (Resource child in resource.getChildren()) {
          _addFilesToDriver(driver, child, excluded);
        }
      } on FileSystemException {
        // The folder does not exist, so ignore it.
      }
    }
  }

  /**
   * Compute the response that should be returned for the given [request], or
   * `null` if the response has already been sent.
   */
  Future<Response> _getResponse(Request request, int requestTime) async {
    ResponseResult result = null;
    switch (request.method) {
      case ANALYSIS_REQUEST_GET_NAVIGATION:
        var params = new AnalysisGetNavigationParams.fromRequest(request);
        result = await handleAnalysisGetNavigation(params);
        break;
      case ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS:
        var params = new AnalysisHandleWatchEventsParams.fromRequest(request);
        result = await handleAnalysisHandleWatchEvents(params);
        break;
      case ANALYSIS_REQUEST_SET_CONTEXT_ROOTS:
        var params = new AnalysisSetContextRootsParams.fromRequest(request);
        result = await handleAnalysisSetContextRoots(params);
        break;
      case ANALYSIS_REQUEST_SET_PRIORITY_FILES:
        var params = new AnalysisSetPriorityFilesParams.fromRequest(request);
        result = await handleAnalysisSetPriorityFiles(params);
        break;
      case ANALYSIS_REQUEST_SET_SUBSCRIPTIONS:
        var params = new AnalysisSetSubscriptionsParams.fromRequest(request);
        result = await handleAnalysisSetSubscriptions(params);
        break;
      case ANALYSIS_REQUEST_UPDATE_CONTENT:
        var params = new AnalysisUpdateContentParams.fromRequest(request);
        result = await handleAnalysisUpdateContent(params);
        break;
      case COMPLETION_REQUEST_GET_SUGGESTIONS:
        var params = new CompletionGetSuggestionsParams.fromRequest(request);
        result = await handleCompletionGetSuggestions(params);
        break;
      case EDIT_REQUEST_GET_ASSISTS:
        var params = new EditGetAssistsParams.fromRequest(request);
        result = await handleEditGetAssists(params);
        break;
      case EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS:
        var params =
            new EditGetAvailableRefactoringsParams.fromRequest(request);
        result = await handleEditGetAvailableRefactorings(params);
        break;
      case EDIT_REQUEST_GET_FIXES:
        var params = new EditGetFixesParams.fromRequest(request);
        result = await handleEditGetFixes(params);
        break;
      case EDIT_REQUEST_GET_REFACTORING:
        var params = new EditGetRefactoringParams.fromRequest(request);
        result = await handleEditGetRefactoring(params);
        break;
      case KYTHE_REQUEST_GET_KYTHE_ENTRIES:
        var params = new KytheGetKytheEntriesParams.fromRequest(request);
        result = await handleKytheGetKytheEntries(params);
        break;
      case PLUGIN_REQUEST_SHUTDOWN:
        var params = new PluginShutdownParams();
        result = await handlePluginShutdown(params);
        _channel.sendResponse(result.toResponse(request.id, requestTime));
        _channel.close();
        return null;
      case PLUGIN_REQUEST_VERSION_CHECK:
        var params = new PluginVersionCheckParams.fromRequest(request);
        result = await handlePluginVersionCheck(params);
        break;
    }
    if (result == null) {
      return new Response(request.id, requestTime,
          error: RequestErrorFactory.unknownRequest(request.method));
    }
    return result.toResponse(request.id, requestTime);
  }

  /**
   * The method that is called when a [request] is received from the analysis
   * server.
   */
  Future<Null> _onRequest(Request request) async {
    int requestTime = new DateTime.now().millisecondsSinceEpoch;
    String id = request.id;
    Response response;
    try {
      response = await _getResponse(request, requestTime);
    } on RequestFailure catch (exception) {
      response = new Response(id, requestTime, error: exception.error);
    } catch (exception, stackTrace) {
      response = new Response(id, requestTime,
          error: new RequestError(
              RequestErrorCode.PLUGIN_ERROR, exception.toString(),
              stackTrace: stackTrace.toString()));
    }
    if (response != null) {
      _channel.sendResponse(response);
    }
  }

  /**
   * Send a notification for the file at the given [path] corresponding to the
   * given [service].
   */
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
