// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/src/context.dart';
import 'package:dartfix/src/verbose_server.dart';
import 'package:dartfix/src/options.dart';
import 'package:path/path.dart' as path;

class Driver {
  String dartfixVersion;

  Context context;
  Logger logger;
  Server server;

  Completer serverConnected;
  Completer analysisComplete;
  bool force;
  bool overwrite;
  List<String> targets;

  /// Read pubspec.yaml and return the version in that file.
  static String get pubspecVersion {
    String dir = path.dirname(Platform.script.toFilePath());
    File pubspec = new File(path.join(dir, '..', 'pubspec.yaml'));

    List<String> lines = pubspec.readAsLinesSync();
    if (lines[0] != 'name: dartfix') {
      throw 'Expected dartfix pubspec in: ${pubspec.path}';
    }
    String version;
    if (lines[1].startsWith('version:')) {
      version = lines[1].substring(8).trim();
    }
    if (version == null || version.isEmpty) {
      throw 'Failed to find dartfix pubspec version in ${pubspec.path}';
    }
    return version;
  }

  Driver() {
    this.dartfixVersion = pubspecVersion;
  }

  Ansi get ansi => logger.ansi;

  /// Return the analysis_server executable by proceeding upward
  /// until finding the Dart SDK repository root then returning
  /// the analysis_server executable within the repository.
  /// Return `null` if it cannot be found.
  String findServerPath() {
    String pathname = Platform.script.toFilePath();
    while (true) {
      String parent = path.dirname(pathname);
      if (parent.length >= pathname.length) {
        return null;
      }
      String serverPath =
          path.join(parent, 'pkg', 'analysis_server', 'bin', 'server.dart');
      if (new File(serverPath).existsSync()) {
        return serverPath;
      }
      pathname = parent;
    }
  }

  Future start(List<String> args) async {
    final Options options = Options.parse(args);

    force = options.force;
    overwrite = options.overwrite;
    targets = options.targets;

    context = options.context;
    logger = options.logger;

    EditDartfixResult result;

    await startServer(options);

    bool normalShutdown = false;
    try {
      final progress = await setupAnalysis(options);
      result = await requestFixes(options, progress);
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
    server = logger.isVerbose ? new VerboseServer(logger) : new Server();
    const connectTimeout = const Duration(seconds: 15);
    serverConnected = new Completer();
    if (options.verbose) {
      logger.trace('Dart SDK version ${Platform.version}');
      logger.trace('  ${Platform.resolvedExecutable}');
      logger.trace('dartfix');
      logger.trace('  ${Platform.script.toFilePath()}');
    }
    // Automatically run analysis server from source
    // if this command line tool is being run from source within the SDK repo.
    String serverPath = findServerPath();
    logger
        .trace(serverPath != null ? 'Starting from source...' : 'Starting...');
    await server.start(
      clientId: 'dartfix',
      clientVersion: dartfixVersion,
      sdkPath: options.sdkPath,
      serverPath: serverPath,
    );
    server.listenToOutput(notificationProcessor: handleEvent);
    await serverConnected.future.timeout(connectTimeout, onTimeout: () {
      logger.stderr('Failed to connect to server');
      context.exit(15);
    });
  }

  Future<Progress> setupAnalysis(Options options) async {
    final progress = logger.progress('${ansi.emphasized('Calculating fixes')}');
    logger.trace('');
    logger.trace('Setup analysis');
    await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
        new ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
    await server.send(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        new AnalysisSetAnalysisRootsParams(
          options.targets,
          const [],
        ).toJson());
    return progress;
  }

  Future<EditDartfixResult> requestFixes(
      Options options, Progress progress) async {
    logger.trace('Requesting fixes');
    analysisComplete = new Completer();
    Map<String, dynamic> json = await server.send(
        EDIT_REQUEST_DARTFIX, new EditDartfixParams(options.targets).toJson());
    await analysisComplete?.future;
    progress.finish(showTiming: true);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return EditDartfixResult.fromJson(decoder, 'result', json);
  }

  Future stopServer(Server server) async {
    logger.trace('Stopping...');
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
    showDescriptions('Recommended changes', result.suggestions);
    showDescriptions('Recommended changes that cannot be automatically applied',
        result.otherSuggestions);
    if (result.suggestions.isEmpty) {
      logger.stdout('');
      logger.stdout(result.otherSuggestions.isNotEmpty
          ? 'None of the recommended changes can be automatically applied.'
          : 'No recommended changes.');
      return;
    }
    logger.stdout('');
    logger.stdout(ansi.emphasized('Files to be changed:'));
    for (SourceFileEdit fileEdit in result.edits) {
      logger.stdout('  ${relativePath(fileEdit.file)}');
    }
    if (shouldApplyChanges(result)) {
      for (SourceFileEdit fileEdit in result.edits) {
        final file = new File(fileEdit.file);
        String code = await file.readAsString();
        for (SourceEdit edit in fileEdit.edits) {
          code = edit.apply(code);
        }
        await file.writeAsString(code);
      }
      logger.stdout(ansi.emphasized('Changes applied.'));
    }
  }

  void showDescriptions(String title, List<DartFixSuggestion> suggestions) {
    if (suggestions.isNotEmpty) {
      logger.stdout('');
      logger.stdout(ansi.emphasized('$title:'));
      List<DartFixSuggestion> sorted = new List.from(suggestions)
        ..sort(compareSuggestions);
      for (DartFixSuggestion suggestion in sorted) {
        final msg = new StringBuffer();
        msg.write('  ${_toSentenceFragment(suggestion.description)}');
        final loc = suggestion.location;
        if (loc != null) {
          msg.write(' • ${relativePath(loc.file)}');
          msg.write(' • ${loc.startLine}:${loc.startColumn}');
        }
        logger.stdout(msg.toString());
      }
    }
  }

  bool shouldApplyChanges(EditDartfixResult result) {
    logger.stdout('');
    if (result.hasErrors) {
      logger.stdout('WARNING: The analyzed source contains errors'
          ' that may affect the accuracy of these changes.');
      logger.stdout('');
      if (!force) {
        logger.stdout('Rerun with --$forceOption to apply these changes.');
        return false;
      }
    } else if (!overwrite && !force) {
      logger.stdout('Rerun with --$overwriteOption to apply these changes.');
      return false;
    }
    return true;
  }

  /// Dispatch the notification named [event], and containing parameters
  /// [params], to the appropriate stream.
  void handleEvent(String event, params) {
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
    bool foundAtLeastOneError = false;
    if (errors.isNotEmpty && isTarget(params.file)) {
      for (AnalysisError error in errors) {
        if (!shouldFilterError(error)) {
          if (!foundAtLeastOneError) {
            foundAtLeastOneError = true;
            logger.stdout('${relativePath(params.file)}:');
          }
          Location loc = error.location;
          logger.stdout('  ${_toSentenceFragment(error.message)}'
              ' • ${loc.startLine}:${loc.startColumn}');
        }
      }
    }
  }

  void onServerConnected(ServerConnectedParams params) {
    logger.trace('Connected to server');
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
    logger.stderr(message.toString());
    context.exit(15);
  }

  void onServerStatus(ServerStatusParams params) {
    if (params.analysis != null && !params.analysis.isAnalyzing) {
      logger.trace('Analysis complete');
      analysisComplete?.complete();
      analysisComplete = null;
    }
  }

  int compareSuggestions(DartFixSuggestion s1, DartFixSuggestion s2) {
    int result = s1.description.compareTo(s2.description);
    if (result != 0) {
      return result;
    }
    return (s2.location?.offset ?? 0) - (s1.location?.offset ?? 0);
  }

  String relativePath(String filePath) {
    for (String target in targets) {
      if (filePath.startsWith(target)) {
        return filePath.substring(target.length + 1);
      }
    }
    return filePath;
  }

  bool shouldFilterError(AnalysisError error) {
    // Do not show TODOs or errors that will be automatically fixed.

    // TODO(danrubel): Rather than checking the error.code with
    // specific strings, add something to the error indicating that
    // it will be automatically fixed by edit.dartfix.
    return error.type.name == 'TODO' ||
        error.code == 'wrong_number_of_type_arguments_constructor';
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

String _toSentenceFragment(String message) {
  return message.endsWith('.')
      ? message.substring(0, message.length - 1)
      : message;
}
