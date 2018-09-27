// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analyzer_cli/src/fix/options.dart';
import 'package:analyzer_cli/src/fix/server.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

// For development
const runAnalysisServerFromSource = false;

class Driver {
  final Server server = new Server();

  Completer serverConnected;
  Completer analysisComplete;
  bool dryRun;
  bool verbose;
  static const progressThreshold = 10;
  int progressCount = progressThreshold;

  Future start(List<String> args) async {
    final options = Options.parse(args);

    /// Only happens in testing.
    if (options == null) {
      return null;
    }
    dryRun = options.dryRun;
    verbose = options.verbose;

    EditDartfixResult result;
    await startServer(options);
    bool normalShutdown = false;
    try {
      await setupAnalysis(options);
      result = await requestFixes(options);
      normalShutdown = true;
    } finally {
      try {
        await stopServer(server);
      } catch (_) {
        if (normalShutdown) {
          rethrow;
        }
      }
    }
    if (result != null) {
      applyFixes(result);
    }
  }

  Future startServer(Options options) async {
    const connectTimeout = const Duration(seconds: 15);
    serverConnected = new Completer();
    if (options.verbose) {
      server.debugStdio();
    }
    verboseOut('Starting...');
    await server.start(
        sdkPath: options.sdkPath, useSnapshot: !runAnalysisServerFromSource);
    server.listenToOutput(dispatchNotification);
    return serverConnected.future.timeout(connectTimeout, onTimeout: () {
      printAndFail('Failed to connect to server');
    });
  }

  Future setupAnalysis(Options options) async {
    verboseOut('Setup analysis');
    await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
        new ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
    await server.send(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        new AnalysisSetAnalysisRootsParams(
          options.analysisRoots,
          const [],
        ).toJson());
  }

  Future<EditDartfixResult> requestFixes(Options options) async {
    outSink.write('Calculating fixes...');
    verboseOut('');
    analysisComplete = new Completer();
    Map<String, dynamic> json = await server.send(EDIT_REQUEST_DARTFIX,
        new EditDartfixParams(options.analysisRoots).toJson());
    await analysisComplete.future;
    analysisComplete = null;
    resetProgress();
    ResponseDecoder decoder = new ResponseDecoder(null);
    return EditDartfixResult.fromJson(decoder, 'result', json);
  }

  Future stopServer(Server server) async {
    verboseOut('Stopping...');
    const timeout = const Duration(seconds: 5);
    await server.send(SERVER_REQUEST_SHUTDOWN, null).timeout(timeout,
        onTimeout: () {
      // fall through to wait for exit.
    });
    await server.exitCode.timeout(timeout, onTimeout: () {
      return server.kill('server failed to exit');
    });
  }

  Future applyFixes(EditDartfixResult result) async {
    showDescriptions(result.descriptionOfFixes, 'Recommended changes');
    showDescriptions(result.otherRecommendations,
        'Recommended changes that cannot not be automatically applied');
    if (result.descriptionOfFixes.isEmpty) {
      outSink.writeln('');
      outSink.writeln(result.otherRecommendations.isNotEmpty
          ? 'No recommended changes that cannot be automatically applied.'
          : 'No recommended changes.');
      return;
    }
    outSink.writeln('');
    outSink.writeln('Files to be changed:');
    for (SourceFileEdit fileEdit in result.fixes) {
      outSink.writeln(fileEdit.file);
    }
    if (dryRun || !(await confirmApplyChanges(result))) {
      return;
    }
    for (SourceFileEdit fileEdit in result.fixes) {
      final file = new File(fileEdit.file);
      String code = await file.readAsString();
      for (SourceEdit edit in fileEdit.edits) {
        code = edit.apply(code);
      }
      await file.writeAsString(code);
    }
    outSink.writeln('Changes applied.');
  }

  void showDescriptions(List<String> descriptions, String title) {
    if (descriptions.isNotEmpty) {
      outSink.writeln('');
      outSink.writeln('$title:');
      List<String> sorted = new List.from(descriptions)..sort();
      for (String line in sorted) {
        outSink.writeln(line);
      }
    }
  }

  Future<bool> confirmApplyChanges(EditDartfixResult result) async {
    outSink.writeln();
    if (result.hasErrors) {
      outSink.writeln('WARNING: The analyzed source contains errors'
          ' that may affect the accuracy of these changes.');
    }
    const prompt = 'Would you like to apply these changes (y/n)? ';
    outSink.write(prompt);
    final response = new Completer<bool>();
    final subscription = inputStream
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      line = line.trim().toLowerCase();
      if (line == 'y' || line == 'yes') {
        response.complete(true);
      } else if (line == 'n' || line == 'no') {
        response.complete(false);
      } else {
        outSink.writeln('  Unrecognized response. Please type "yes" or "no".');
        outSink.write(prompt);
      }
    });
    bool applyChanges = await response.future;
    await subscription.cancel();
    return applyChanges;
  }

  /// Dispatch the notification named [event], and containing parameters
  /// [params], to the appropriate stream.
  void dispatchNotification(String event, params) {
    ResponseDecoder decoder = new ResponseDecoder(null);
    switch (event) {
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
//      case ANALYSIS_NOTIFICATION_ANALYZED_FILES:
//        outOfTestExpect(params, isAnalysisAnalyzedFilesParams);
//        _onAnalysisAnalyzedFiles.add(new AnalysisAnalyzedFilesParams.fromJson(
//            decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_CLOSING_LABELS:
//        outOfTestExpect(params, isAnalysisClosingLabelsParams);
//        _onAnalysisClosingLabels.add(new AnalysisClosingLabelsParams.fromJson(
//            decoder, 'params', params));
//        break;
      case ANALYSIS_NOTIFICATION_ERRORS:
        onAnalysisErrors(
            new AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
//      case ANALYSIS_NOTIFICATION_FLUSH_RESULTS:
//        outOfTestExpect(params, isAnalysisFlushResultsParams);
//        _onAnalysisFlushResults.add(
//            new AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_FOLDING:
//        outOfTestExpect(params, isAnalysisFoldingParams);
//        _onAnalysisFolding
//            .add(new AnalysisFoldingParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_HIGHLIGHTS:
//        outOfTestExpect(params, isAnalysisHighlightsParams);
//        _onAnalysisHighlights.add(
//            new AnalysisHighlightsParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_IMPLEMENTED:
//        outOfTestExpect(params, isAnalysisImplementedParams);
//        _onAnalysisImplemented.add(
//            new AnalysisImplementedParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_INVALIDATE:
//        outOfTestExpect(params, isAnalysisInvalidateParams);
//        _onAnalysisInvalidate.add(
//            new AnalysisInvalidateParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_NAVIGATION:
//        outOfTestExpect(params, isAnalysisNavigationParams);
//        _onAnalysisNavigation.add(
//            new AnalysisNavigationParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_OCCURRENCES:
//        outOfTestExpect(params, isAnalysisOccurrencesParams);
//        _onAnalysisOccurrences.add(
//            new AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_OUTLINE:
//        outOfTestExpect(params, isAnalysisOutlineParams);
//        _onAnalysisOutline
//            .add(new AnalysisOutlineParams.fromJson(decoder, 'params', params));
//        break;
//      case ANALYSIS_NOTIFICATION_OVERRIDES:
//        outOfTestExpect(params, isAnalysisOverridesParams);
//        _onAnalysisOverrides.add(
//            new AnalysisOverridesParams.fromJson(decoder, 'params', params));
//        break;
//      case COMPLETION_NOTIFICATION_RESULTS:
//        outOfTestExpect(params, isCompletionResultsParams);
//        _onCompletionResults.add(
//            new CompletionResultsParams.fromJson(decoder, 'params', params));
//        break;
//      case SEARCH_NOTIFICATION_RESULTS:
//        outOfTestExpect(params, isSearchResultsParams);
//        _onSearchResults
//            .add(new SearchResultsParams.fromJson(decoder, 'params', params));
//        break;
//      case EXECUTION_NOTIFICATION_LAUNCH_DATA:
//        outOfTestExpect(params, isExecutionLaunchDataParams);
//        _onExecutionLaunchData.add(
//            new ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
//        break;
//      case FLUTTER_NOTIFICATION_OUTLINE:
//        outOfTestExpect(params, isFlutterOutlineParams);
//        _onFlutterOutline
//            .add(new FlutterOutlineParams.fromJson(decoder, 'params', params));
//        break;
//      default:
//        printAndFail('Unexpected notification: $event');
//        break;
    }
  }

  void onAnalysisErrors(AnalysisErrorsParams params) {
    List<AnalysisError> errors = params.errors;
    if (errors.isNotEmpty) {
      resetProgress();
      outSink.writeln(params.file);
      for (AnalysisError error in errors) {
        Location loc = error.location;
        outSink.writeln('  ${error.message}'
            ' at ${loc.startLine}:${loc.startColumn}');
      }
    } else {
      showProgress();
    }
  }

  void onServerConnected(ServerConnectedParams params) {
    verboseOut('Connected to server');
    serverConnected.complete();
  }

  void onServerError(ServerErrorParams params) async {
    try {
      await stopServer(server);
    } catch (e) {
      // ignored
    }
    final message = new StringBuffer('Server Error: ')..writeln(params.message);
    if (params.stackTrace != null) {
      message.writeln(params.stackTrace);
    }
    printAndFail(message.toString());
  }

  void onServerStatus(ServerStatusParams params) {
    if (params.analysis != null && !params.analysis.isAnalyzing) {
      verboseOut('Analysis complete');
      analysisComplete?.complete();
    }
  }

  void resetProgress() {
    if (!verbose && progressCount >= progressThreshold) {
      outSink.writeln();
    }
    progressCount = 0;
  }

  void showProgress() {
    if (!verbose && progressCount % progressThreshold == 0) {
      outSink.write('.');
    }
    ++progressCount;
  }

  void verboseOut(String message) {
    if (verbose) {
      outSink.writeln(message);
    }
  }
}
