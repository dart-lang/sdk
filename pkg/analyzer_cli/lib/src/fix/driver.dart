// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer_cli/src/fix/options.dart';
import 'package:analyzer_cli/src/fix/server.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

class Driver {
  static const timeout = const Duration(seconds: 5);

  final Server server = new Server();

  Completer serverConnected;
  Completer analysisComplete;
  bool verbose;

  Future start(List<String> args) async {
    final options = Options.parse(args);

    /// Only happens in testing.
    if (options == null) {
      return null;
    }
    verbose = options.verbose;

    serverConnected = new Completer();
    analysisComplete = new Completer();

    await startServer(options);
    outSink.writeln('Analyzing...');
    await setupAnalysis(options);

    // TODO(danrubel): Request fixes rather than waiting for analysis complete
    await analysisComplete.future;

    outSink.writeln('Analysis complete.');
    await stopServer(server);
  }

  Future startServer(Options options) async {
    if (options.verbose) {
      server.debugStdio();
    }
    verboseOut('Starting...');
    await server.start(sdkPath: options.sdkPath);
    server.listenToOutput(dispatchNotification);
    return serverConnected.future.timeout(timeout, onTimeout: () {
      printAndFail('Failed to connect to server');
    });
  }

  Future setupAnalysis(Options options) async {
    verboseOut('Setup analysis');

    await server.send("server.setSubscriptions",
        new ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());

    await server.send(
        "analysis.setAnalysisRoots",
        new AnalysisSetAnalysisRootsParams(
          options.analysisRoots,
          const [],
        ).toJson());
  }

  Future stopServer(Server server) async {
    verboseOut('Stopping...');
    await server.send("server.shutdown", null);
    await server.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
      return server.kill('server failed to exit');
    });
  }

  /**
   * Dispatch the notification named [event], and containing parameters
   * [params], to the appropriate stream.
   */
  void dispatchNotification(String event, params) {
    ResponseDecoder decoder = new ResponseDecoder(null);
    switch (event) {
      case "server.connected":
        onServerConnected(
            new ServerConnectedParams.fromJson(decoder, 'params', params));
        break;
//      case "server.error":
//        outOfTestExpect(params, isServerErrorParams);
//        _onServerError
//            .add(new ServerErrorParams.fromJson(decoder, 'params', params));
//        break;
      case "server.status":
        onServerStatus(
            new ServerStatusParams.fromJson(decoder, 'params', params));
        break;
//      case "analysis.analyzedFiles":
//        outOfTestExpect(params, isAnalysisAnalyzedFilesParams);
//        _onAnalysisAnalyzedFiles.add(new AnalysisAnalyzedFilesParams.fromJson(
//            decoder, 'params', params));
//        break;
//      case "analysis.closingLabels":
//        outOfTestExpect(params, isAnalysisClosingLabelsParams);
//        _onAnalysisClosingLabels.add(new AnalysisClosingLabelsParams.fromJson(
//            decoder, 'params', params));
//        break;
      case "analysis.errors":
        onAnalysisErrors(
            new AnalysisErrorsParams.fromJson(decoder, 'params', params));
        break;
//      case "analysis.flushResults":
//        outOfTestExpect(params, isAnalysisFlushResultsParams);
//        _onAnalysisFlushResults.add(
//            new AnalysisFlushResultsParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.folding":
//        outOfTestExpect(params, isAnalysisFoldingParams);
//        _onAnalysisFolding
//            .add(new AnalysisFoldingParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.highlights":
//        outOfTestExpect(params, isAnalysisHighlightsParams);
//        _onAnalysisHighlights.add(
//            new AnalysisHighlightsParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.implemented":
//        outOfTestExpect(params, isAnalysisImplementedParams);
//        _onAnalysisImplemented.add(
//            new AnalysisImplementedParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.invalidate":
//        outOfTestExpect(params, isAnalysisInvalidateParams);
//        _onAnalysisInvalidate.add(
//            new AnalysisInvalidateParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.navigation":
//        outOfTestExpect(params, isAnalysisNavigationParams);
//        _onAnalysisNavigation.add(
//            new AnalysisNavigationParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.occurrences":
//        outOfTestExpect(params, isAnalysisOccurrencesParams);
//        _onAnalysisOccurrences.add(
//            new AnalysisOccurrencesParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.outline":
//        outOfTestExpect(params, isAnalysisOutlineParams);
//        _onAnalysisOutline
//            .add(new AnalysisOutlineParams.fromJson(decoder, 'params', params));
//        break;
//      case "analysis.overrides":
//        outOfTestExpect(params, isAnalysisOverridesParams);
//        _onAnalysisOverrides.add(
//            new AnalysisOverridesParams.fromJson(decoder, 'params', params));
//        break;
//      case "completion.results":
//        outOfTestExpect(params, isCompletionResultsParams);
//        _onCompletionResults.add(
//            new CompletionResultsParams.fromJson(decoder, 'params', params));
//        break;
//      case "search.results":
//        outOfTestExpect(params, isSearchResultsParams);
//        _onSearchResults
//            .add(new SearchResultsParams.fromJson(decoder, 'params', params));
//        break;
//      case "execution.launchData":
//        outOfTestExpect(params, isExecutionLaunchDataParams);
//        _onExecutionLaunchData.add(
//            new ExecutionLaunchDataParams.fromJson(decoder, 'params', params));
//        break;
//      case "flutter.outline":
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
      outSink.writeln(params.file);
      for (AnalysisError error in errors) {
        Location loc = error.location;
        outSink.writeln('  ${error.message}'
            ' at ${loc.startLine}:${loc.startColumn}');
      }
    }
  }

  void onServerConnected(ServerConnectedParams params) {
    verboseOut('Connected to server');
    serverConnected.complete();
  }

  void onServerStatus(ServerStatusParams params) {
    if (params.analysis != null && !params.analysis.isAnalyzing) {
      verboseOut('Analysis complete');
      analysisComplete.complete();
    }
  }

  void verboseOut(String message) {
    if (verbose) {
      outSink.writeln(message);
    }
  }
}
