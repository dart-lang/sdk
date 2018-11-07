// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'package:analysis_server_client/protocol.dart';

class NotificationHandler {
  /// Dispatch the notification named [event], and containing parameters
  /// [params], to the appropriate stream.
  void handleEvent(String event, params) {
    ResponseDecoder decoder = new ResponseDecoder(null);
    switch (event) {
      case ANALYSIS_NOTIFICATION_ANALYZED_FILES:
        onAnalysisAnalyzedFiles(new AnalysisAnalyzedFilesParams.fromJson(
            decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_CLOSING_LABELS:
        onAnalysisClosingLabels(new AnalysisClosingLabelsParams.fromJson(
            decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_ERRORS:
        onAnalysisErrors(
            new AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_FLUSH_RESULTS:
        onAnalysisFlushResults(
            new AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_FOLDING:
        onAnalysisFolding(
            new AnalysisFoldingParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_HIGHLIGHTS:
        onAnalysisHighlights(
            new AnalysisHighlightsParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_IMPLEMENTED:
        onAnalysisImplemented(
            new AnalysisImplementedParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_INVALIDATE:
        onAnalysisInvalidate(
            new AnalysisInvalidateParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_NAVIGATION:
        onAnalysisNavigation(
            new AnalysisNavigationParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_OCCURRENCES:
        onAnalysisOccurrences(
            new AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_OUTLINE:
        onAnalysisOutline(
            new AnalysisOutlineParams.fromJson(decoder, 'params', params));
        break;
      case ANALYSIS_NOTIFICATION_OVERRIDES:
        onAnalysisOverrides(
            new AnalysisOverridesParams.fromJson(decoder, 'params', params));
        break;
      case COMPLETION_NOTIFICATION_RESULTS:
        onCompletionResults(
            new CompletionResultsParams.fromJson(decoder, 'params', params));
        break;
      case EXECUTION_NOTIFICATION_LAUNCH_DATA:
        onExecutionLaunchData(
            new ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
        break;
      case FLUTTER_NOTIFICATION_OUTLINE:
        onFlutterOutline(
            new FlutterOutlineParams.fromJson(decoder, 'params', params));
        break;
      case SEARCH_NOTIFICATION_RESULTS:
        onSearchResults(
            new SearchResultsParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_CONNECTED:
        onServerConnected(
            new ServerConnectedParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_ERROR:
        onServerError(
            new ServerErrorParams.fromJson(decoder, 'params', params));
        break;
      case SERVER_NOTIFICATION_STATUS:
        onServerStatus(
            new ServerStatusParams.fromJson(decoder, 'params', params));
        break;
      default:
        onUnknownNotification(event, params);
        break;
    }
  }

  void onAnalysisAnalyzedFiles(AnalysisAnalyzedFilesParams params) {}

  void onAnalysisClosingLabels(AnalysisClosingLabelsParams params) {}

  void onAnalysisErrors(AnalysisErrorsParams params) {}

  void onAnalysisFlushResults(AnalysisFlushResultsParams params) {}

  void onAnalysisFolding(AnalysisFoldingParams params) {}

  void onAnalysisHighlights(AnalysisHighlightsParams params) {}

  void onAnalysisImplemented(AnalysisImplementedParams params) {}

  void onAnalysisInvalidate(AnalysisInvalidateParams params) {}

  void onAnalysisNavigation(AnalysisNavigationParams params) {}

  void onAnalysisOccurrences(AnalysisOccurrencesParams params) {}

  void onAnalysisOutline(AnalysisOutlineParams params) {}

  void onAnalysisOverrides(AnalysisOverridesParams params) {}

  void onCompletionResults(CompletionResultsParams params) {}

  void onExecutionLaunchData(ExecutionLaunchDataParams params) {}

  void onFlutterOutline(FlutterOutlineParams params) {}

  void onSearchResults(SearchResultsParams params) {}

  void onServerConnected(ServerConnectedParams params) {}

  void onServerError(ServerErrorParams params) {}

  void onServerStatus(ServerStatusParams params) {}

  void onUnknownNotification(String event, params) {}
}
