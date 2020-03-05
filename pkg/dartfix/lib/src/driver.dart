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
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import 'migrate/display.dart';
import 'util.dart';

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

  /// Apply the fixes that were computed.
  void applyFixes() {
    for (SourceFileEdit fileEdit in result.edits) {
      final file = File(fileEdit.file);
      String code = file.existsSync() ? file.readAsStringSync() : '';
      code = SourceEdit.applySequence(code, fileEdit.edits);
      file.writeAsStringSync(code);
    }
  }

  bool checkIfChangesShouldBeApplied(EditDartfixResult result) {
    logger.stdout('');
    if (result.hasErrors) {
      logger.stdout('WARNING: The analyzed source contains errors'
          ' that might affect the accuracy of these changes.');
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

  /// Check if the specified options is supported by the version of analysis
  /// server being run and return `true` if they are.
  /// Display an error message and return `false` if not.
  bool checkIfSelectedOptionsAreSupported(Options options) {
    if (handler.serverProtocolVersion.compareTo(Version(1, 27, 2)) >= 0) {
      return true;
    }
    if (options.pedanticFixes) {
      _unsupportedOption(pedanticOption);
      return false;
    }
    if (handler.serverProtocolVersion.compareTo(Version(1, 22, 2)) >= 0) {
      return true;
    }
    if (options.excludeFixes.isNotEmpty) {
      _unsupportedOption(excludeFixOption);
      return false;
    }
    if (options.includeFixes.isNotEmpty) {
      _unsupportedOption(includeFixOption);
      return false;
    }
    if (options.showHelp) {
      return false;
    }
    return true;
  }

  void printAndApplyFixes() {
    showDescriptions('Recommended changes that cannot be automatically applied',
        result.otherSuggestions);
    showDetails(result.details);
    if (result.edits.isEmpty) {
      logger.stdout('');
      logger.stdout(result.otherSuggestions.isNotEmpty
          ? 'None of the recommended changes can be automatically applied.'
          : 'No recommended changes.');
      return;
    }
    logger.stdout('');
    logger.stdout(ansi.emphasized('Files to be changed:'));
    for (SourceFileEdit fileEdit in result.edits) {
      logger.stdout('  ${_relativePath(fileEdit.file)}');
    }
    if (checkIfChangesShouldBeApplied(result)) {
      applyFixes();
      logger.stdout(ansi.emphasized('Changes have been applied.'));
    }
  }

  Future<EditDartfixResult> requestFixes(
    Options options, {
    Progress progress,
  }) async {
    Future isAnalysisComplete = handler.analysisComplete();

    final params = EditDartfixParams(options.targets);
    if (options.excludeFixes.isNotEmpty) {
      params.excludedFixes = options.excludeFixes;
    }
    if (options.includeFixes.isNotEmpty) {
      params.includedFixes = options.includeFixes;
    }
    if (options.pedanticFixes) {
      params.includePedanticFixes = true;
    }
    Map<String, dynamic> json =
        await server.send(EDIT_REQUEST_DARTFIX, params.toJson());

    // TODO(danrubel): This is imprecise signal for determining when all
    // analysis error notifications have been received. Consider adding a new
    // notification indicating that the server is idle (all requests processed,
    // all analysis complete, all notifications sent).
    await isAnalysisComplete;

    progress.finish(showTiming: true);
    ResponseDecoder decoder = ResponseDecoder(null);
    return EditDartfixResult.fromJson(decoder, 'result', json);
  }

  /// Return `true` if the changes should be applied.
  bool shouldApplyFixes(EditDartfixResult result) {
    return overwrite || force;
  }

  void showDescriptions(String title, List<DartFixSuggestion> suggestions) {
    if (suggestions.isNotEmpty) {
      logger.stdout('');
      logger.stdout(ansi.emphasized('$title:'));
      List<DartFixSuggestion> sorted = List.from(suggestions)
        ..sort(compareSuggestions);
      for (DartFixSuggestion suggestion in sorted) {
        final msg = StringBuffer();
        msg.write('  ${toSentenceFragment(suggestion.description)}');
        final loc = suggestion.location;
        if (loc != null) {
          msg.write(' • ${_relativePath(loc.file)}');
          msg.write(' • ${loc.startLine}:${loc.startColumn}');
        }
        logger.stdout(msg.toString());
      }
    }
  }

  void showDetails(List<String> details) {
    if (details == null || details.isEmpty) {
      return;
    }
    logger.stdout('''

Analysis Details:
''');
    for (String detail in details) {
      logger.stdout('''
 • $detail
''');
    }
  }

  void showFix(DartFix fix) {
    logger.stdout('''

• ${ansi.emphasized(fix.name)}''');
    if (fix.description != null) {
      for (String line in _indentAndWrapDescription(fix.description)) {
        logger.stdout(line);
      }
    }
  }

  Future<EditGetDartfixInfoResult> showFixes({Progress progress}) async {
    Map<String, dynamic> json = await server.send(
        EDIT_REQUEST_GET_DARTFIX_INFO, EditGetDartfixInfoParams().toJson());
    progress?.finish(showTiming: true);
    ResponseDecoder decoder = ResponseDecoder(null);
    final result = EditGetDartfixInfoResult.fromJson(decoder, 'result', json);

    final fixes = List<DartFix>.from(result.fixes)
      ..sort((f1, f2) => f1.name.compareTo(f2.name));

    logger.stdout('''

These fixes can be enabled using --$includeFixOption:''');

    fixes
      ..sort(compareFixes)
      ..forEach(showFix);

    return result;
  }

  Future start(
    List<String> args, {
    Context testContext,
    Logger testLogger,
  }) async {
    final Options options = Options.parse(args, testContext, testLogger);

    force = options.force;
    overwrite = options.overwrite;
    targets = options.targets;
    context = testContext ?? options.context;
    logger = testLogger ?? options.logger;
    server = Server(listener: _Listener(logger));
    handler = _Handler(this, context);

    // Start showing progress before we start the analysis server.
    Progress progress;
    if (options.showHelp) {
      progress = logger.progress('${ansi.emphasized('Listing fixes')}');
    } else {
      progress = logger.progress('${ansi.emphasized('Calculating fixes')}');
    }

    if (!await startServer(options)) {
      context.exit(16);
    }

    if (!checkIfSelectedOptionsAreSupported(options)) {
      await server.stop();
      context.exit(1);
    }

    if (options.showHelp) {
      try {
        await showFixes(progress: progress);
      } finally {
        await server.stop();
      }
      context.exit(0);
    }

    if (options.includeFixes.isEmpty && !options.pedanticFixes) {
      logger.stdout('No fixes specified.');
      context.exit(1);
    }

    Future serverStopped;
    try {
      await startServerAnalysis(options);
      result = await requestFixes(options, progress: progress);
      var fileEdits = result.edits;
      var editCount = 0;
      for (SourceFileEdit fileEdit in fileEdits) {
        editCount += fileEdit.edits.length;
      }
      logger.stdout('Found $editCount changes in ${fileEdits.length} files.');

      previewFixes(logger, result);

      //
      // Stop the server.
      //
      serverStopped = server.stop();

      logger.stdout('');

      // Check if we should apply fixes.
      if (result.edits.isEmpty) {
        logger.stdout(result.otherSuggestions.isNotEmpty
            ? 'None of the recommended changes can be automatically applied.'
            : 'There are no recommended changes.');
      } else if (shouldApplyFixes(result)) {
        applyFixes();
        logger.stdout('Changes have been applied.');
      } else {
        logger.stdout('Re-run with --overwrite to apply the above changes.');
      }
      await serverStopped;
    } finally {
      // If we didn't already try to stop the server, then stop it now.
      if (serverStopped == null) {
        await server.stop();
      }
    }
  }

  Future<bool> startServer(Options options) async {
    // Automatically run analysis server from source
    // if this command line tool is being run from source within the SDK repo.
    String serverPath = options.serverSnapshot ?? findServerPath();
    if (options.verbose) {
      logger.trace('''
Dart SDK version ${Platform.version}
  ${Platform.resolvedExecutable}
dartfix
  ${Platform.script.toFilePath()}
analysis server
  $serverPath
''');
    }
    await server.start(
      clientId: 'dartfix',
      clientVersion: 'unspecified',
      sdkPath: options.sdkPath,
      serverPath: serverPath,
    );
    server.listenToOutput(notificationProcessor: handler.handleEvent);
    return handler.serverConnected(timeLimit: const Duration(seconds: 30));
  }

  Future<Progress> startServerAnalysis(
    Options options, {
    Progress progress,
  }) async {
    logger.trace('');
    logger.trace('Setup analysis');
    await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
        ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
    await server.send(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        AnalysisSetAnalysisRootsParams(
          options.targets,
          const [],
        ).toJson());
    return progress;
  }

  List<String> _indentAndWrapDescription(String description) =>
      description.split('\n').map((line) => '    $line').toList();

  String _relativePath(String filePath) {
    for (String target in targets) {
      if (filePath.startsWith(target)) {
        return filePath.substring(target.length + 1);
      }
    }
    return filePath;
  }

  void _unsupportedOption(String option) {
    final version = handler.serverProtocolVersion.toString();
    logger.stderr('''
The --$option option is not supported by analysis server version $version.
Please upgrade to a newer version of the Dart SDK to use this option.''');
  }

  void previewFixes(
    Logger logger,
    EditDartfixResult results,
  ) {
    final Ansi ansi = logger.ansi;

    Map<String, List<DartFixSuggestion>> fileSuggestions = {};
    for (DartFixSuggestion suggestion in results.suggestions) {
      String file = suggestion.location.file;
      fileSuggestions.putIfAbsent(file, () => <DartFixSuggestion>[]);
      fileSuggestions[file].add(suggestion);
    }

    // present a diff-like view
    for (SourceFileEdit sourceFileEdit in results.edits) {
      String file = sourceFileEdit.file;
      String relPath = path.relative(file);
      int count = sourceFileEdit.edits.length;

      logger.stdout('');
      logger.stdout('${ansi.emphasized(relPath)} '
          '($count ${pluralize('change', count)}):');

      String source;
      try {
        source = File(file).readAsStringSync();
      } catch (_) {}

      if (source == null) {
        logger.stdout('  (unable to retrieve source for file)');
      } else {
        SourcePrinter sourcePrinter = SourcePrinter(source);

        List<SourceEdit> edits = sortEdits(sourceFileEdit);

        // Apply edits.
        sourcePrinter.applyEdits(edits);

        // Render the changed lines.
        sourcePrinter.processChangedLines((lineNumber, lineText) {
          String prefix = '  line ${lineNumber.toString().padRight(3)} •';
          logger.stdout('$prefix ${lineText.trim()}');
        });
      }
    }
  }
}

class _Handler
    with NotificationHandler, ConnectionHandler, AnalysisCompleteHandler {
  final Driver driver;
  final Logger logger;
  final Context context;

  @override
  final Server server;
  Version serverProtocolVersion;

  _Handler(this.driver, this.context)
      : logger = driver.logger,
        server = driver.server;

  @override
  bool checkServerProtocolVersion(Version version) {
    serverProtocolVersion = version;
    return super.checkServerProtocolVersion(version);
  }

  @override
  void onAnalysisErrors(AnalysisErrorsParams params) {
    List<AnalysisError> errors = params.errors;
    bool foundAtLeastOneError = false;
    for (AnalysisError error in errors) {
      if (shouldShowError(error)) {
        if (!foundAtLeastOneError) {
          foundAtLeastOneError = true;
          logger.stdout('${driver._relativePath(params.file)}:');
        }
        Location loc = error.location;
        logger.stdout('  ${toSentenceFragment(error.message)}'
            ' • ${loc.startLine}:${loc.startColumn}');
      }
    }
    super.onAnalysisErrors(params);
    // Analysis errors are non-fatal; no need to exit.
  }

  @override
  void onFailedToConnect() {
    logger.stderr('Failed to connect to server');
    super.onFailedToConnect();
    // Exiting on connection failure is already handled by [Driver.start].
  }

  @override
  void onProtocolNotSupported(Version version) {
    logger.stderr('Expected protocol version $PROTOCOL_VERSION,'
        ' but found $version');
    final expectedVersion = Version.parse(PROTOCOL_VERSION);
    if (version > expectedVersion) {
      logger.stdout('''
This version of dartfix is incompatible with the current Dart SDK.
Try installing a newer version of dartfix by running:

    pub global activate dartfix
''');
    } else {
      logger.stdout('''
This version of dartfix is too new to be used with the current Dart SDK. Try
upgrading the Dart SDK to a newer version or installing an older version of
dartfix using:

    pub global activate dartfix <version>
''');
    }
    super.onProtocolNotSupported(version);
    // This is handled by the connection failure case; no need to exit here.
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
    // Server is stopped by super method, so we can safely exit here.
    context.exit(16);
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
