// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartfix/handler/analysis_complete_handler.dart';
import 'package:dartfix/listener/bad_message_listener.dart';
import 'package:dartfix/src/context.dart';
import 'package:dartfix/src/options.dart';
import 'package:dartfix/src/util.dart';
import 'package:pub_semver/pub_semver.dart';

class Driver {
  static final expectedProtocolVersion = new Version.parse('1.21.1');

  Context context;
  _Handler handler;
  Logger logger;
  Server server;

  bool force;
  bool overwrite;
  List<String> targets;
  EditDartfixResult result;

  Ansi get ansi => logger.ansi;

  Future start(List<String> args,
      {Context testContext, Logger testLogger}) async {
    final Options options = Options.parse(args);

    force = options.force;
    overwrite = options.overwrite;
    targets = options.targets;
    context = testContext ?? options.context;
    logger = testLogger ?? options.logger;
    server = new Server(listener: new _Listener(logger));
    handler = new _Handler(this);

    if (!await startServer(options)) {
      context.exit(15);
    }

    try {
      final progress = await setupAnalysis(options);
      result = await requestFixes(options, progress);
    } finally {
      await server.stop();
    }
    if (result != null) {
      applyFixes();
    }
  }

  Future<bool> startServer(Options options) async {
    if (options.verbose) {
      logger.trace('Dart SDK version ${Platform.version}');
      logger.trace('  ${Platform.resolvedExecutable}');
      logger.trace('dartfix');
      logger.trace('  ${Platform.script.toFilePath()}');
    }
    // Automatically run analysis server from source
    // if this command line tool is being run from source within the SDK repo.
    String serverPath = findServerPath();
    await server.start(
      clientId: 'dartfix',
      clientVersion: 'unspecified',
      sdkPath: options.sdkPath,
      serverPath: serverPath,
    );
    server.listenToOutput(notificationProcessor: handler.handleEvent);
    return handler.serverConnected(timeLimit: const Duration(seconds: 15));
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
    Future isAnalysisComplete = handler.analysisComplete();
    Map<String, dynamic> json = await server.send(
        EDIT_REQUEST_DARTFIX, new EditDartfixParams(options.targets).toJson());

    // TODO(danrubel): This is imprecise signal for determining when all
    // analysis error notifications have been received. Consider adding a new
    // notification indicating that the server is idle (all requests processed,
    // all analysis complete, all notifications sent).
    await isAnalysisComplete;

    progress.finish(showTiming: true);
    ResponseDecoder decoder = new ResponseDecoder(null);
    return EditDartfixResult.fromJson(decoder, 'result', json);
  }

  Future applyFixes() async {
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
        msg.write('  ${toSentenceFragment(suggestion.description)}');
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

  String relativePath(String filePath) {
    for (String target in targets) {
      if (filePath.startsWith(target)) {
        return filePath.substring(target.length + 1);
      }
    }
    return filePath;
  }
}

class _Listener with ServerListener, BadMessageListener {
  final Logger logger;
  final bool verbose;

  _Listener(this.logger) : verbose = logger.isVerbose;

  @override
  void log(String prefix, String details) {
    if (verbose) {
      logger.trace('$prefix $details');
    }
  }
}

class _Handler
    with NotificationHandler, ConnectionHandler, AnalysisCompleteHandler {
  final Driver driver;
  final Logger logger;
  final Server server;

  _Handler(this.driver)
      : logger = driver.logger,
        server = driver.server;

  @override
  void onFailedToConnect() {
    logger.stderr('Failed to connect to server');
  }

  @override
  void onProtocolNotSupported(Version version) {
    logger.stderr('Expected protocol version ${Driver.expectedProtocolVersion},'
        ' but found $version');
    if (version > Driver.expectedProtocolVersion) {
      logger.stdout('''
This version of dartfix is incompatible with the current Dart SDK. 
Try installing a newer version of dartfix by running

    pub global activate dartfix
''');
    } else {
      logger.stdout('''
This version of dartfix is too new to be used with the current Dart SDK.
Try upgrading the Dart SDK to a newer version
or installing an older version of dartfix using

    pub global activate dartfix <version>
''');
    }
  }

  @override
  bool checkServerProtocolVersion(Version version) {
    // This overrides the default protocol version check to be more narrow
    // because the edit.dartfix protocol is experimental
    // and will continue to evolve.
    return version == Driver.expectedProtocolVersion;
  }

  @override
  void onServerError(ServerErrorParams params) {
    if (params.isFatal) {
      logger.stderr('Fatal Server Error: ${params.message}');
    } else {
      logger.stderr('Server Error: ${params.message}');
    }
    if (params.stackTrace != null) {
      logger.stderr(params.stackTrace);
    }
    super.onServerError(params);
  }

  @override
  void onAnalysisErrors(AnalysisErrorsParams params) {
    List<AnalysisError> errors = params.errors;
    bool foundAtLeastOneError = false;
    for (AnalysisError error in errors) {
      if (shouldShowError(error)) {
        if (!foundAtLeastOneError) {
          foundAtLeastOneError = true;
          logger.stdout('${driver.relativePath(params.file)}:');
        }
        Location loc = error.location;
        logger.stdout('  ${toSentenceFragment(error.message)}'
            ' • ${loc.startLine}:${loc.startColumn}');
      }
    }
  }
}
