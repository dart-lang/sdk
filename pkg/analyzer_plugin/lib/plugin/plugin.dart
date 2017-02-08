// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriverScheduler, PerformanceLog;
import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/src/utilities/null_string_sink.dart';
import 'package:analyzer_plugin/utilities/subscription_manager.dart';
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
   * The file content overlay used by any analysis drivers that are created.
   */
  final FileContentOverlay fileContentOverlay = new FileContentOverlay();

  /**
   * Initialize a newly created analysis server plugin. If a resource [provider]
   * is given, then it will be used to access the file system. Otherwise a
   * resource provider that accesses the physical file system will be used.
   */
  ServerPlugin(this.resourceProvider) {
    analysisDriverScheduler = new AnalysisDriverScheduler(performanceLog);
  }

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
   * Handle an 'analysis.handleWatchEvents' request.
   */
  AnalysisHandleWatchEventsResult handleAnalysisHandleWatchEvents(
          Map<String, Object> parameters) =>
      null;

  /**
   * Handle an 'analysis.reanalyze' request.
   */
  AnalysisReanalyzeResult handleAnalysisReanalyze(
          Map<String, Object> parameters) =>
      null;

  /**
   * Handle an 'analysis.setContextBuilderOptions' request.
   */
  AnalysisSetContextBuilderOptionsResult handleAnalysisSetContextBuilderOptions(
          Map<String, Object> parameters) =>
      null;

  /**
   * Handle an 'analysis.setContextRoots' request.
   */
  AnalysisSetContextRootsResult handleAnalysisSetContextRoots(
      Map<String, Object> parameters) {
    // TODO(brianwilkerson) Implement this so that implementors don't have to
    // figure out how to manage contexts.
    return null;
  }

  /**
   * Handle an 'analysis.setPriorityFiles' request.
   */
  AnalysisSetPriorityFilesResult handleAnalysisSetPriorityFiles(
          Map<String, Object> parameters) =>
      new AnalysisSetPriorityFilesResult();

  /**
   * Handle an 'analysis.setSubscriptions' request. Most subclasses should not
   * override this method, but should instead use the [subscriptionManager] to
   * access the list of subscriptions for any given file.
   */
  AnalysisSetSubscriptionsResult handleAnalysisSetSubscriptions(
      Map<String, Object> parameters) {
    Map<AnalysisService, List<String>> subscriptions = validateParameter(
        parameters,
        ANALYSIS_REQUEST_SET_SUBSCRIPTIONS_SUBSCRIPTIONS,
        'analysis.setSubscriptions');
    subscriptionManager.setSubscriptions(subscriptions);
    // TODO(brianwilkerson) Cause any newly subscribed for notifications to be sent.
    return new AnalysisSetSubscriptionsResult();
  }

  /**
   * Handle an 'analysis.updateContent' request. Most subclasses should not
   * override this method, but should instead use the [contentCache] to access
   * the current content of overlaid files.
   */
  AnalysisUpdateContentResult handleAnalysisUpdateContent(
      Map<String, Object> parameters) {
    Map<String, Object> files = validateParameter(parameters,
        ANALYSIS_REQUEST_UPDATE_CONTENT_FILES, 'analysis.updateContent');
    files.forEach((String filePath, Object overlay) {
      // We don't need to get the correct URI because only the full path is
      // used by the contentCache.
      Source source = resourceProvider.getFile(filePath).createSource();
      if (overlay is AddContentOverlay) {
        fileContentOverlay[source.fullName] = overlay.content;
      } else if (overlay is ChangeContentOverlay) {
        String fileName = source.fullName;
        String oldContents = fileContentOverlay[fileName];
        String newContents;
        if (oldContents == null) {
          // The server should only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw new RequestFailure(new RequestError(
              RequestErrorCode.INVALID_OVERLAY_CHANGE,
              'Invalid overlay change: no content to change'));
        }
        try {
          newContents = SourceEdit.applySequence(oldContents, overlay.edits);
        } on RangeError {
          throw new RequestFailure(new RequestError(
              RequestErrorCode.INVALID_OVERLAY_CHANGE,
              'Invalid overlay change: invalid edit'));
        }
        fileContentOverlay[fileName] = newContents;
      } else if (overlay is RemoveContentOverlay) {
        fileContentOverlay[source.fullName] = null;
      }
      contentChanged(filePath);
    });
    return new AnalysisUpdateContentResult();
  }

  /**
   * Handle a 'completion.getSuggestions' request.
   */
  CompletionGetSuggestionsResult handleCompletionGetSuggestions(
          Map<String, Object> parameters) =>
      new CompletionGetSuggestionsResult(
          -1, -1, const <CompletionSuggestion>[]);

  /**
   * Handle an 'edit.getAssists' request.
   */
  EditGetAssistsResult handleEditGetAssists(Map<String, Object> parameters) =>
      new EditGetAssistsResult(const <PrioritizedSourceChange>[]);

  /**
   * Handle an 'edit.getAvailableRefactorings' request. Subclasses that override
   * this method in order to participate in refactorings must also override the
   * method [handleEditGetRefactoring].
   */
  EditGetAvailableRefactoringsResult handleEditGetAvailableRefactorings(
          Map<String, Object> parameters) =>
      new EditGetAvailableRefactoringsResult(const <RefactoringKind>[]);

  /**
   * Handle an 'edit.getFixes' request.
   */
  EditGetFixesResult handleEditGetFixes(Map<String, Object> parameters) =>
      new EditGetFixesResult(const <AnalysisErrorFixes>[]);

  /**
   * Handle an 'edit.getRefactoring' request.
   */
  EditGetRefactoringResult handleEditGetRefactoring(
          Map<String, Object> parameters) =>
      null;

  /**
   * Handle a 'plugin.shutdown' request. Subclasses can override this method to
   * perform any required clean-up, but cannot prevent the plugin from shutting
   * down.
   */
  PluginShutdownResult handlePluginShutdown(Map<String, Object> parameters) =>
      new PluginShutdownResult();

  /**
   * Handle a 'plugin.versionCheck' request.
   */
  PluginVersionCheckResult handlePluginVersionCheck(
      Map<String, Object> parameters) {
    String byteStorePath = validateParameter(parameters,
        PLUGIN_REQUEST_VERSION_CHECK_BYTESTOREPATH, 'plugin.versionCheck');
    String versionString = validateParameter(parameters,
        PLUGIN_REQUEST_VERSION_CHECK_VERSION, 'plugin.versionCheck');
    Version serverVersion = new Version.parse(versionString);
    _byteStore =
        new MemoryCachingByteStore(new FileByteStore(byteStorePath), 64 * M);
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
   * Start this plugin by listening to the given communication [channel].
   */
  void start(PluginCommunicationChannel channel) {
    this._channel = channel;
    _channel.listen(_onRequest, onError: onError, onDone: onDone);
  }

  /**
   * Validate that the value in the map of [parameters] at the given [key] is of
   * the type [T]. If it is, return it. Otherwise throw a [RequestFailure] that
   * will cause an error to be returned to the server.
   */
  Object/*=T*/ validateParameter/*<T>*/(
      Map<String, Object> parameters, String key, String requestName) {
    Object value = parameters[key];
    // ignore: type_annotation_generic_function_parameter
    if (value is Object/*=T*/) {
      return value;
    }
    String message;
    if (value == null) {
      message = 'Missing parameter $key in $requestName';
    } else {
      message = 'Invalid value for $key in $requestName (${value.runtimeType})';
    }
    throw new RequestFailure(
        new RequestError(RequestErrorCode.INVALID_PARAMETER, message));
  }

  /**
   * Compute the response that should be returned for the given [request], or
   * `null` if the response has already been sent.
   */
  Response _getResponse(Request request) {
    ResponseResult result = null;
    switch (request.id) {
      case ANALYSIS_REQUEST_HANDLE_WATCH_EVENTS:
        result = handleAnalysisHandleWatchEvents(request.params);
        break;
      case ANALYSIS_REQUEST_REANALYZE:
        result = handleAnalysisReanalyze(request.params);
        break;
      case ANALYSIS_REQUEST_SET_CONTEXT_BUILDER_OPTIONS:
        result = handleAnalysisSetContextBuilderOptions(request.params);
        break;
      case ANALYSIS_REQUEST_SET_CONTEXT_ROOTS:
        result = handleAnalysisSetContextRoots(request.params);
        break;
      case ANALYSIS_REQUEST_SET_PRIORITY_FILES:
        result = handleAnalysisSetPriorityFiles(request.params);
        break;
      case ANALYSIS_REQUEST_SET_SUBSCRIPTIONS:
        result = handleAnalysisSetSubscriptions(request.params);
        break;
      case ANALYSIS_REQUEST_UPDATE_CONTENT:
        result = handleAnalysisUpdateContent(request.params);
        break;
      case COMPLETION_REQUEST_GET_SUGGESTIONS:
        result = handleCompletionGetSuggestions(request.params);
        break;
      case EDIT_REQUEST_GET_ASSISTS:
        result = handleEditGetAssists(request.params);
        break;
      case EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS:
        result = handleEditGetAvailableRefactorings(request.params);
        break;
      case EDIT_REQUEST_GET_FIXES:
        result = handleEditGetFixes(request.params);
        break;
      case EDIT_REQUEST_GET_REFACTORING:
        result = handleEditGetRefactoring(request.params);
        break;
      case PLUGIN_REQUEST_SHUTDOWN:
        result = handlePluginShutdown(request.params);
        _channel.sendResponse(result.toResponse(request.id));
        _channel.close();
        return null;
      case PLUGIN_REQUEST_VERSION_CHECK:
        result = handlePluginVersionCheck(request.params);
        break;
    }
    if (result == null) {
      return new Response(request.id,
          error: RequestErrorFactory.unknownRequest(request));
    }
    return result.toResponse(request.id);
  }

  /**
   * The method that is called when a [request] is received from the analysis
   * server.
   */
  void _onRequest(Request request) {
    String id = request.id;
    Response response;
    try {
      response = _getResponse(request);
    } on RequestFailure catch (exception) {
      _channel.sendResponse(new Response(id, error: exception.error));
    } catch (exception, stackTrace) {
      response = new Response(id,
          error: new RequestError(
              RequestErrorCode.PLUGIN_ERROR, exception.toString(),
              stackTrace: stackTrace.toString()));
    }
    if (response != null) {
      _channel.sendResponse(response);
    }
  }
}
