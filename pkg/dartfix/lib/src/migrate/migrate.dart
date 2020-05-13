// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:nnbd_migration/isolate_server.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:nnbd_migration/src/messages.dart';
import 'package:path/path.dart' as path;

import '../util.dart';
import 'apply.dart';
import 'display.dart';
import 'options.dart';

String get _dartSdkVersion {
  String version = Platform.version;

  // Remove the build date and OS.
  if (version.contains(' ')) {
    version = version.substring(0, version.indexOf(' '));
  }

  // Convert a git hash to 8 chars.
  // '2.8.0-edge.fd992e423ef69ece9f44bd3ac58fa2355b563212'
  final RegExp versionRegExp = RegExp(r'^.*\.([0123456789abcdef]+)$');
  RegExpMatch match = versionRegExp.firstMatch(version);
  if (match != null && match.group(1).length == 40) {
    String commit = match.group(1);
    version = version.replaceAll(commit, commit.substring(0, 10));
  }

  return version;
}

// TODO(devoncarew): Over time, we should look to share code with the
// implementation here and that in lib/src/driver.dart.

typedef LogProvider = Logger Function();

/// Perform null safety related migrations on the user's code.
class MigrateCommand extends Command {
  final LogProvider logProvider;

  @override
  final bool hidden;

  MigrateCommand({this.logProvider, this.hidden = false}) {
    MigrateOptions.defineOptions(argParser);
  }

  @override
  String get description =>
      'Perform a null safety migration on a project or package.'
      '\n\nThe migrate feature is in preview and not yet complete; we welcome '
      'feedback.\n\n'
      'https://github.com/dart-lang/sdk/tree/master/pkg/nnbd_migration#providing-feedback';

  @override
  String get invocation {
    return '${super.invocation} [project or directory]';
  }

  @override
  String get name => 'migrate';

  @override
  Future<int> run() async {
    MigrateOptions options = _parseAndValidateOptions();

    Logger logger;
    if (logProvider != null) {
      logger = logProvider();
    }
    logger ??= Logger.standard();

    final Ansi ansi = logger.ansi;

    logger.stdout('Migrating ${options.directory}');
    logger.stdout('');

    Progress getProgress(String message) => options.debug
        ? SimpleProgress(logger, message)
        : logger.progress(message);

    Map<String, List<AnalysisError>> fileErrors = {};

    String instrumentationLogFile;
    String sdkPath = options.sdkPath;
    bool stdioPassthrough = false;

    if (options.debug) {
      stdioPassthrough = true;
      instrumentationLogFile = path.join(
          Directory.systemTemp.createTempSync('migration_debug').path,
          'instrumentationLog');
      logger.stdout('Instrumentation log file:  $instrumentationLogFile');
    }

    Progress progress = getProgress('${ansi.emphasized('Analyzing project')}');

    Server server = Server(
        listener: logger.isVerbose ? _ServerListener(logger) : null,
        stdioPassthrough: stdioPassthrough);
    try {
      await server.start(
          clientId: 'dart $name',
          clientVersion: _dartSdkVersion,
          instrumentationLogFile: instrumentationLogFile,
          sdkPath: sdkPath);
      _ServerNotifications serverNotifications = _ServerNotifications(server);
      await serverNotifications.listenToServer(server);

      serverNotifications.analysisErrorsEvents
          .listen((AnalysisErrorsParams event) {
        List<AnalysisError> errors = event.errors
            .where((error) => error.severity == AnalysisErrorSeverity.ERROR)
            .toList();
        if (errors.isEmpty) {
          fileErrors.remove(event.file);
        } else {
          fileErrors[event.file] = errors;
        }
      });

      var params =
          AnalysisSetAnalysisRootsParams([options.directoryAbsolute], []);
      await server.send(ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS, params.toJson());

      await serverNotifications.onNextAnalysisComplete;

      progress.finish(showTiming: true);
    } finally {
      progress.cancel();
    }

    // Handle if there were any errors.
    if (fileErrors.isEmpty) {
      logger.stdout('No analysis issues found.');
    } else {
      logger.stdout('');

      int issueCount =
          fileErrors.values.map((list) => list.length).reduce((a, b) => a + b);
      logger.stdout(
          '$issueCount analysis ${pluralize('issue', issueCount)} found:');
      List<AnalysisError> allErrors = fileErrors.values
          .fold(<AnalysisError>[], (list, element) => list..addAll(element));
      _displayIssues(
        logger,
        options.directory,
        allErrors,
      );
      var importErrorCount = allErrors.where(_isUriError).length;

      logger.stdout('');
      logger.stdout(
          'Note: analysis errors will result in erroneous migration suggestions.');

      if (options.ignoreErrors) {
        logger.stdout('Continuing with migration suggestions due to the use of '
            '--${MigrateOptions.ignoreErrorsOption}.');
      } else {
        // Fail with how to continue.
        logger.stdout('');
        if (importErrorCount != 0) {
          logger.stdout(
              'Unresolved URIs found.  Did you forget to run "pub get"?');
          logger.stdout('');
        }
        logger.stdout(
            'Please fix the analysis issues (or, force generation of migration '
            'suggestions by re-running with '
            '--${MigrateOptions.ignoreErrorsOption}).');
        return 1;
      }
    }

    // Calculate migration suggestions.
    logger.stdout('');
    progress =
        getProgress('${ansi.emphasized('Generating migration suggestions')}');
    Map<String, dynamic> json;

    try {
      final EditDartfixParams params =
          EditDartfixParams([options.directoryAbsolute]);
      params.includedFixes = ['non-nullable'];
      params.port = options.previewPort;
      json = await server.send(EDIT_REQUEST_DARTFIX, params.toJson());
      progress.finish(showTiming: true);
    } finally {
      progress.cancel();
    }

    EditDartfixResult migrationResults =
        EditDartfixResult.fromJson(ResponseDecoder(null), 'result', json);

    if (migrationResults.suggestions.isEmpty) {
      logger.stdout('No migration changes necessary.');
      return 0;
    }

    List<SourceEdit> allEdits = migrationResults.edits
        .fold(<SourceEdit>[], (list, edit) => list..addAll(edit.edits));
    List<String> files =
        migrationResults.edits.map((edit) => edit.file).toList();

    logger.stdout('Found ${allEdits.length} '
        'suggested ${pluralize('change', allEdits.length)} in '
        '${files.length} ${pluralize('file', files.length)}.');

    logger.stdout('');

    if (options.applyChanges) {
      logger.stdout(ansi.emphasized('Applying changes:'));

      _applyMigrationSuggestions(logger, options.directory, migrationResults);

      logger.stdout('');
      logger.stdout(
          'Applied ${allEdits.length} ${pluralize('edit', allEdits.length)}.');

      // Note: do not open the web preview if apply-changes is specified, as we
      // currently cannot tell the web preview to disable the "apply migration"
      // button.
      return 0;
    }

    if (options.webPreview) {
      String url = migrationResults.urls.first;
      assert(migrationResults.urls.length <= 1,
          'Got unexpected extra preview URLs from server');

      logger.stdout(ansi.emphasized('View migration results:'));

      // TODO(devoncarew): Open a browser automatically.
      logger.stdout('''
Visit:
  
  ${ansi.emphasized(url)}

to see the migration results. Use the interactive web view to review, improve, or apply
the results (alternatively, to apply the results without using the web preview, re-run
the tool with --${MigrateOptions.applyChangesOption}).
''');

      logger.stdout('When finished with the preview, hit ctrl-c '
          'to terminate this process.');

      // Block until sigint (ctrl-c).
      await _blockUntilSignalInterrupt();
    } else {
      logger.stdout(ansi.emphasized('Summary of changes:'));

      _displayChangeSummary(logger, options.directory, migrationResults);

      logger.stdout('');
      logger.stdout('To apply these changes, re-run the tool with '
          '--${MigrateOptions.applyChangesOption}.');
    }

    // ignore: unawaited_futures
    server.stop(timeLimit: Duration(seconds: 1));

    return 0;
  }

  void _applyMigrationSuggestions(
    Logger logger,
    String directory,
    EditDartfixResult migrationResults,
  ) {
    // Apply the changes to disk.
    for (SourceFileEdit sourceFileEdit in migrationResults.edits) {
      String relPath = path.relative(sourceFileEdit.file, from: directory);
      int count = sourceFileEdit.edits.length;
      logger.stdout('  $relPath ($count ${pluralize('change', count)})');

      String source;
      try {
        source = File(sourceFileEdit.file).readAsStringSync();
      } catch (_) {}

      if (source == null) {
        logger.stdout('    Unable to retrieve source for file.');
      } else {
        source = applyEdits(sourceFileEdit, source);

        try {
          File(sourceFileEdit.file).writeAsStringSync(source);
        } catch (e) {
          logger.stdout('    Unable to write source for file: $e');
        }
      }
    }
  }

  Future _blockUntilSignalInterrupt() {
    Stream<ProcessSignal> stream = ProcessSignal.sigint.watch();
    return stream.first;
  }

  void _displayChangeSummary(
    Logger logger,
    String directory,
    EditDartfixResult migrationResults,
  ) {
    final Ansi ansi = logger.ansi;

    Map<String, List<DartFixSuggestion>> fileSuggestions = {};
    for (DartFixSuggestion suggestion in migrationResults.suggestions) {
      String file = suggestion.location.file;
      fileSuggestions.putIfAbsent(file, () => <DartFixSuggestion>[]);
      fileSuggestions[file].add(suggestion);
    }

    // present a diff-like view
    for (SourceFileEdit sourceFileEdit in migrationResults.edits) {
      String file = sourceFileEdit.file;
      String relPath = path.relative(file, from: directory);
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

  void _displayIssues(
    Logger logger,
    String directory,
    List<AnalysisError> issues,
  ) {
    issues.sort((AnalysisError one, AnalysisError two) {
      if (one.location.file != two.location.file) {
        return one.location.file.compareTo(two.location.file);
      }
      return one.location.offset - two.location.offset;
    });

    IssueRenderer renderer = IssueRenderer(logger, directory);
    for (AnalysisError issue in issues) {
      renderer.render(issue);
    }
  }

  bool _isUriError(AnalysisError error) => error.code == 'uri_does_not_exist';

  /// Parse and validate the user's options; throw a UsageException if there are
  /// issues, and return an [MigrateOptions] result otherwise.
  MigrateOptions _parseAndValidateOptions() {
    String dirPath;

    if (argResults.rest.isNotEmpty) {
      if (argResults.rest.length == 1) {
        dirPath = argResults.rest.first;

        if (FileSystemEntity.isFileSync(dirPath)) {
          // Calling this will throw an exception.
          usageException(
              'Please provide a path to a package or directory to migrate.');
        } else if (!FileSystemEntity.isDirectorySync(dirPath)) {
          // Calling this will throw an exception.
          usageException("'$dirPath' not found; "
              'please provide a path to a package or directory to migrate.');
        }
      } else {
        // Calling this will throw an exception.
        usageException(
            'Please provide a path to a package or directory to migrate.');
      }
    } else {
      dirPath = Directory.current.path;
    }

    return MigrateOptions(argResults, dirPath);
  }
}

class _ServerListener with ServerListener {
  final Logger logger;

  _ServerListener(this.logger);

  @override
  void log(String prefix, String details) {
    logger.trace('[$prefix] $details');
  }
}

class _ServerNotifications with NotificationHandler {
  final Server server;

  StreamController<ServerStatusParams> _serverStatusController =
      StreamController<ServerStatusParams>.broadcast();

  StreamController<AnalysisErrorsParams> _analysisErrorsController =
      StreamController<AnalysisErrorsParams>.broadcast();

  _ServerNotifications(this.server);

  Stream<AnalysisErrorsParams> get analysisErrorsEvents =>
      _analysisErrorsController.stream;

  Future get onNextAnalysisComplete {
    Completer completer = Completer();

    StreamSubscription sub;
    sub = serverStatusEvents.listen((event) {
      if (!event.analysis.isAnalyzing) {
        sub.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  Stream<ServerStatusParams> get serverStatusEvents =>
      _serverStatusController.stream;

  Future listenToServer(Server server) async {
    server.listenToOutput(notificationProcessor: handleEvent);

    await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
        ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
  }

  @override
  void onAnalysisErrors(AnalysisErrorsParams event) {
    _analysisErrorsController.add(event);
  }

  @override
  void onServerError(ServerErrorParams event) {
    stderr.writeln('encountered error: ${event.message}');

    for (String fatal in [migratedAlready, nnbdExperimentOff, sdkNnbdOff]) {
      if (event.message.contains(fatal)) {
        server.kill();
        exit(2);
      }
    }
  }

  @override
  void onServerStatus(ServerStatusParams event) {
    if (event.analysis != null) {
      _serverStatusController.add(event);
    }
  }
}
