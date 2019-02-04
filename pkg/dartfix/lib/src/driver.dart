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
      if (checkSupported(options)) {
        if (options.listFixes) {
          await showListOfFixes();
        } else {
          final progress = await setupAnalysis(options);
          result = await requestFixes(options, progress);
        }
      }
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

  /// Check if the specified options is supported by the version of analysis
  /// server being run and return `true` if they are.
  /// Display an error message and return `false` if not.
  bool checkSupported(Options options) {
    if (handler.serverProtocolVersion.compareTo(new Version(1, 22, 2)) >= 0) {
      return true;
    }
    if (options.excludeFixes.isNotEmpty) {
      unsupportedOption(excludeOption);
      return false;
    }
    if (options.includeFixes.isNotEmpty) {
      unsupportedOption(includeOption);
      return false;
    }
    if (options.listFixes) {
      unsupportedOption(listOption);
      return false;
    }
    if (options.requiredFixes) {
      unsupportedOption(requiredOption);
      return false;
    }
    return true;
  }

  void unsupportedOption(String option) {
    final version = handler.serverProtocolVersion.toString();
    logger.stderr('''
The --$option option is not supported by analysis server version $version.
Please upgrade to a newer version of the Dart SDK to use this option.''');
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

    final params = new EditDartfixParams(options.targets);
    if (options.excludeFixes.isNotEmpty) {
      params.excludedFixes = options.excludeFixes;
    }
    if (options.includeFixes.isNotEmpty) {
      params.includedFixes = options.includeFixes;
    }
    if (options.requiredFixes) {
      params.includeRequiredFixes = true;
    }
    Map<String, dynamic> json =
        await server.send(EDIT_REQUEST_DARTFIX, params.toJson());

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

  showListOfFixes() async {
    final progress =
        logger.progress('${ansi.emphasized('Getting list of fixes')}');
    logger.trace('');
    Map<String, dynamic> json = await server.send(
        EDIT_REQUEST_GET_DARTFIX_INFO, new EditGetDartfixInfoParams().toJson());

    progress.finish(showTiming: true);
    ResponseDecoder decoder = new ResponseDecoder(null);
    final result = EditGetDartfixInfoResult.fromJson(decoder, 'result', json);

    final fixes = new List<DartFix>.from(result.fixes)
      ..sort((f1, f2) => f1.name.compareTo(f2.name));

    for (DartFix fix in fixes) {
      String line = fix.name;
      if (fix.isRequired == true) {
        line = '$line (required)';
      }
      logger.stdout('');
      logger.stdout(line);
      if (fix.description != null) {
        for (String line in indentAndWrapDescription(fix.description)) {
          logger.stdout(line);
        }
      }
    }
    return result;
  }

  List<String> indentAndWrapDescription(String description) =>
      description.split('\n').map((line) => '    $line').toList();
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
  Version serverProtocolVersion;

  _Handler(this.driver)
      : logger = driver.logger,
        server = driver.server;

  @override
  bool checkServerProtocolVersion(Version version) {
    serverProtocolVersion = version;
    return super.checkServerProtocolVersion(version);
  }

  @override
  void onFailedToConnect() {
    logger.stderr('Failed to connect to server');
  }

  @override
  void onProtocolNotSupported(Version version) {
    logger.stderr('Expected protocol version $PROTOCOL_VERSION,'
        ' but found $version');
    final expectedVersion = Version.parse(PROTOCOL_VERSION);
    if (version > expectedVersion) {
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
