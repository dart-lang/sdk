// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io' show File;

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analyzer_cli/src/fix/context.dart';
import 'package:analyzer_cli/src/fix/options.dart';
import 'package:analyzer_cli/src/fix/server.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;

// For development
const runAnalysisServerFromSource = false;

class Driver {
  final Context context = new Context();
  final Server server = new Server();

  Completer serverConnected;
  Completer analysisComplete;
  bool dryRun;
  bool force;
  bool verbose;
  List<String> targets;

  static const progressThreshold = 10;
  int progressCount = progressThreshold;

  Future start(List<String> args) async {
    final options = Options.parse(args, context);

    dryRun = options.dryRun;
    force = options.force;
    verbose = options.verbose;
    targets = options.targets;

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
      context.stderr.writeln('Failed to connect to server');
      context.exit(15);
    });
  }

  Future setupAnalysis(Options options) async {
    context.stdout.write('Calculating fixes...');
    verboseOut('');
    verboseOut('Setup analysis');
    await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
        new ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
    await server.send(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        new AnalysisSetAnalysisRootsParams(
          options.targets,
          const [],
        ).toJson());
  }

  Future<EditDartfixResult> requestFixes(Options options) async {
    verboseOut('Requesting fixes');
    analysisComplete = new Completer();
    Map<String, dynamic> json = await server.send(
        EDIT_REQUEST_DARTFIX, new EditDartfixParams(options.targets).toJson());
    await analysisComplete?.future;
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
      context.print('');
      context.print(result.otherRecommendations.isNotEmpty
          ? 'No recommended changes that cannot be automatically applied.'
          : 'No recommended changes.');
      return;
    }
    context.print('');
    context.print('Files to be changed:');
    for (SourceFileEdit fileEdit in result.fixes) {
      context.print(fileEdit.file);
    }
    if (shouldApplyChanges(result)) {
      for (SourceFileEdit fileEdit in result.fixes) {
        final file = new File(fileEdit.file);
        String code = await file.readAsString();
        for (SourceEdit edit in fileEdit.edits) {
          code = edit.apply(code);
        }
        await file.writeAsString(code);
      }
      context.print('Changes applied.');
    }
  }

  void showDescriptions(List<String> descriptions, String title) {
    if (descriptions.isNotEmpty) {
      context.print('');
      context.print('$title:');
      List<String> sorted = new List.from(descriptions)..sort();
      for (String line in sorted) {
        context.print(line);
      }
    }
  }

  bool shouldApplyChanges(EditDartfixResult result) {
    context.print();
    if (result.hasErrors) {
      context.print('WARNING: The analyzed source contains errors'
          ' that may affect the accuracy of these changes.');
      context.print();
      if (!force) {
        context.print('Rerun with --$forceOption to apply these changes.');
        return false;
      }
    }
    if (dryRun) {
      context.print('Dry run complete. No changes applied.');
      return false;
    }
    return true;
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
    if (errors.isNotEmpty && isTarget(params.file)) {
      resetProgress();
      context.print(params.file);
      for (AnalysisError error in errors) {
        Location loc = error.location;
        context.print('  ${error.message}'
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
    context.stderr.writeln(message.toString());
    context.exit(15);
  }

  void onServerStatus(ServerStatusParams params) {
    if (params.analysis != null && !params.analysis.isAnalyzing) {
      verboseOut('Analysis complete');
      analysisComplete?.complete();
      analysisComplete = null;
    }
  }

  void resetProgress() {
    if (!verbose && progressCount >= progressThreshold) {
      context.print();
    }
    progressCount = 0;
  }

  void showProgress() {
    if (!verbose && progressCount % progressThreshold == 0) {
      context.stdout.write('.');
    }
    ++progressCount;
  }

  void verboseOut(String message) {
    if (verbose) {
      context.print(message);
    }
  }

  bool isTarget(String filePath) {
    for (String target in targets) {
      if (filePath == target || path.isWithin(target, filePath)) {
        return true;
      }
    }
    return false;
  }
}
