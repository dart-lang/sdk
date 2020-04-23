// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'package:analysis_server_client/protocol.dart';

/// [NotificationHandler] processes analysis server notifications
/// and dispatches those notifications to different methods based upon
/// the type of notification. Clients may override
/// any of the "on<EventName>" methods that are of interest.
///
/// Clients may mix-in this class, but may not implement it.
mixin NotificationHandler {
  void handleEvent(Notification notification) {
    var params = notification.params;
    var decoder = ResponseDecoder(null);
    switch (notification.event) {
      case ANALYSIS_NOTIFICATION_ANALYZED_FILES:
        onAnalysisAnalyzedFiles(
            AnalysisAnalyzedFilesParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_CLOSING_LABELS:
        onAnalysisClosingLabels(
            AnalysisClosingLabelsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_ERRORS:
        onAnalysisErrors(
            AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_FLUSH_RESULTS:
        onAnalysisFlushResults(
            AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_FOLDING:
        onAnalysisFolding(
            AnalysisFoldingParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_HIGHLIGHTS:
        onAnalysisHighlights(
            AnalysisHighlightsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_IMPLEMENTED:
        onAnalysisImplemented(
            AnalysisImplementedParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_INVALIDATE:
        onAnalysisInvalidate(
            AnalysisInvalidateParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_NAVIGATION:
        onAnalysisNavigation(
            AnalysisNavigationParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_OCCURRENCES:
        onAnalysisOccurrences(
            AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_OUTLINE:
        onAnalysisOutline(
            AnalysisOutlineParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_OVERRIDES:
        onAnalysisOverrides(
            AnalysisOverridesParams.fromJson(decoder, 'params', params));
        break;
      case COMPLETION_NOTIFICATION_AVAILABLE_SUGGESTIONS:
        onCompletionAvailableSuggestions(
            CompletionAvailableSuggestionsParams.fromJson(
                decoder, 'params', params));
        break;
      case COMPLETION_NOTIFICATION_EXISTING_IMPORTS:
        onCompletionExistingImports(CompletionExistingImportsParams.fromJson(
            decoder, 'params', params));
        break;
      case COMPLETION_NOTIFICATION_RESULTS:
        onCompletionResults(
            CompletionResultsParams.fromJson(decoder, 'params', params));
        break;
      case EXECUTION_NOTIFICATION_LAUNCH_DATA:
        onExecutionLaunchData(
            ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
        break;
      case FLUTTER_NOTIFICATION_OUTLINE:
        onFlutterOutline(
            FlutterOutlineParams.fromJson(decoder, 'params', params));
        break;
      case SEARCH_NOTIFICATION_RESULTS:
        onSearchResults(
            SearchResultsParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_CONNECTED:
        onServerConnected(
            ServerConnectedParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_ERROR:
        onServerError(ServerErrorParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_LOG:
        onServerLog(ServerLogParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_STATUS:
        onServerStatus(ServerStatusParams.fromJson(decoder, 'params', params));
        break;
      default:
        onUnknownNotification(notification.event, params);
        break;
    }
  }

  /// Reports the paths of the files that are being analyzed.
  ///
  /// This notification is not subscribed to by default. Clients can
  /// subscribe by including the value "ANALYZED_FILES" in the list
  /// of services passed in an analysis.setGeneralSubscriptions request.
  void onAnalysisAnalyzedFiles(AnalysisAnalyzedFilesParams params) {}

  /// Reports closing labels relevant to a given file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "CLOSING_LABELS"
  /// in the list of services passed in an
  /// analysis.setSubscriptions request.
  void onAnalysisClosingLabels(AnalysisClosingLabelsParams params) {}

  /// Reports the errors associated with a given file. The set of
  /// errors included in the notification is always a complete
  /// list that supersedes any previously reported errors.
  void onAnalysisErrors(AnalysisErrorsParams params) {}

  /// Reports that any analysis results that were previously
  /// associated with the given files should be considered to be
  /// invalid because those files are no longer being analyzed,
  /// either because the analysis root that contained it is no
  /// longer being analyzed or because the file no longer exists.
  ///
  /// If a file is included in this notification and at some later
  /// time a notification with results for the file is received,
  /// clients should assume that the file is once again being
  /// analyzed and the information should be processed.
  ///
  /// It is not possible to subscribe to or unsubscribe from this
  /// notification.
  void onAnalysisFlushResults(AnalysisFlushResultsParams params) {}

  /// Reports the folding regions associated with a given
  /// file. Folding regions can be nested, but will not be
  /// overlapping. Nesting occurs when a foldable element, such as
  /// a method, is nested inside another foldable element such as
  /// a class.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "FOLDING" in
  /// the list of services passed in an analysis.setSubscriptions
  /// request.
  void onAnalysisFolding(AnalysisFoldingParams params) {}

  /// Reports the highlight regions associated with a given file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "HIGHLIGHTS"
  /// in the list of services passed in an
  /// analysis.setSubscriptions request.
  void onAnalysisHighlights(AnalysisHighlightsParams params) {}

  /// Reports the classes that are implemented or extended and
  /// class members that are implemented or overridden in a file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "IMPLEMENTED" in
  /// the list of services passed in an analysis.setSubscriptions
  /// request.
  void onAnalysisImplemented(AnalysisImplementedParams params) {}

  /// Reports that the navigation information associated with a region of a
  /// single file has become invalid and should be re-requested.
  ///
  /// This notification is not subscribed to by default. Clients can
  /// subscribe by including the value "INVALIDATE" in the list of
  /// services passed in an analysis.setSubscriptions request.
  void onAnalysisInvalidate(AnalysisInvalidateParams params) {}

  /// Reports the navigation targets associated with a given file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "NAVIGATION"
  /// in the list of services passed in an
  /// analysis.setSubscriptions request.
  void onAnalysisNavigation(AnalysisNavigationParams params) {}

  /// Reports the occurrences of references to elements within a
  /// single file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "OCCURRENCES"
  /// in the list of services passed in an
  /// analysis.setSubscriptions request.
  void onAnalysisOccurrences(AnalysisOccurrencesParams params) {}

  /// Reports the outline associated with a single file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "OUTLINE" in
  /// the list of services passed in an analysis.setSubscriptions
  /// request.
  void onAnalysisOutline(AnalysisOutlineParams params) {}

  /// Reports the overriding members in a file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "OVERRIDES" in
  /// the list of services passed in an analysis.setSubscriptions
  /// request.
  void onAnalysisOverrides(AnalysisOverridesParams params) {}

  /// Reports the pre-computed, candidate completions from symbols defined
  /// in a corresponding library. This notification may be sent multiple times.
  /// When a notification is processed, clients should replace any previous
  /// information about the libraries in the list of changedLibraries, discard
  /// any information about the libraries in the list of removedLibraries, and
  /// preserve any previously received information about any libraries that are
  /// not included in either list.
  void onCompletionAvailableSuggestions(
      CompletionAvailableSuggestionsParams params) {}

  /// Reports existing imports in a library. This notification may be sent
  /// multiple times for a library. When a notification is processed, clients
  /// should replace any previous information for the library.
  void onCompletionExistingImports(CompletionExistingImportsParams params) {}

  /// Reports the completion suggestions that should be presented
  /// to the user. The set of suggestions included in the
  /// notification is always a complete list that supersedes any
  /// previously reported suggestions.
  void onCompletionResults(CompletionResultsParams params) {}

  /// Reports information needed to allow a single file to be launched.
  ///
  /// This notification is not subscribed to by default. Clients can
  /// subscribe by including the value "LAUNCH_DATA" in the list of services
  /// passed in an execution.setSubscriptions request.
  void onExecutionLaunchData(ExecutionLaunchDataParams params) {}

  /// Reports the Flutter outline associated with a single file.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "OUTLINE" in
  /// the list of services passed in an flutter.setSubscriptions
  /// request.
  void onFlutterOutline(FlutterOutlineParams params) {}

  /// Reports some or all of the results of performing a requested
  /// search. Unlike other notifications, this notification
  /// contains search results that should be added to any
  /// previously received search results associated with the same
  /// search id.
  void onSearchResults(SearchResultsParams params) {}

  /// Reports that the server is running. This notification is
  /// issued once after the server has started running but before
  /// any requests are processed to let the client know that it
  /// started correctly.
  ///
  /// It is not possible to subscribe to or unsubscribe from this
  /// notification.
  void onServerConnected(ServerConnectedParams params) {}

  /// Reports that an unexpected error has occurred while
  /// executing the server. This notification is not used for
  /// problems with specific requests (which are returned as part
  /// of the response) but is used for exceptions that occur while
  /// performing other tasks, such as analysis or preparing
  /// notifications.
  ///
  /// It is not possible to subscribe to or unsubscribe from this
  /// notification.
  void onServerError(ServerErrorParams params) {}

  /// The stream of entries describing events happened in the server.
  void onServerLog(ServerLogParams params) {}

  /// Reports the current status of the server. Parameters are
  /// omitted if there has been no change in the status
  /// represented by that parameter.
  ///
  /// This notification is not subscribed to by default. Clients
  /// can subscribe by including the value "STATUS" in
  /// the list of services passed in a server.setSubscriptions
  /// request.
  void onServerStatus(ServerStatusParams params) {}

  /// Reports a notification that is not processed
  /// by any other notification handlers.
  void onUnknownNotification(String event, params) {}
}
