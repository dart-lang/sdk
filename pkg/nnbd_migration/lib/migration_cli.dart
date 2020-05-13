// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide File;

import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart'
    show File, ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/api_for_analysis_server/dartfix_listener_interface.dart';
import 'package:nnbd_migration/api_for_analysis_server/driver_provider.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/utilities/source_edit_diff_formatter.dart';
import 'package:path/path.dart' show Context;

String _pluralize(int count, String single, {String multiple}) {
  return count == 1 ? single : (multiple ?? '${single}s');
}

String _removePeriod(String value) {
  return value.endsWith('.') ? value.substring(0, value.length - 1) : value;
}

/// Data structure recording command-line options for the migration tool that
/// have been passed in by the client.
@visibleForTesting
class CommandLineOptions {
  static const applyChangesFlag = 'apply-changes';
  static const helpFlag = 'help';
  static const ignoreErrorsFlag = 'ignore-errors';
  static const previewPortOption = 'preview-port';
  static const sdkPathOption = 'sdk-path';
  static const summaryOption = 'summary';
  static const verboseFlag = 'verbose';
  static const webPreviewFlag = 'web-preview';

  final bool applyChanges;

  final String directory;

  final bool ignoreErrors;

  final int previewPort;

  final String sdkPath;

  final String summary;

  final bool webPreview;

  CommandLineOptions(
      {@required this.applyChanges,
      @required this.directory,
      @required this.ignoreErrors,
      @required this.previewPort,
      @required this.sdkPath,
      @required this.summary,
      @required this.webPreview});
}

/// Command-line API for the migration tool, with additional methods exposed for
/// testing.
class MigrationCli {
  /// The name of the executable, for reporting in help messages.
  final String binaryName;

  /// The SDK path that should be used if none is provided by the user.  Used in
  /// testing to install a mock SDK.
  final String defaultSdkPathOverride;

  /// Factory to create an appropriate Logger instance to give feedback to the
  /// user.  Used in testing to allow user feedback messages to be tested.
  final Logger Function(bool isVerbose) loggerFactory;

  /// Resource provider that should be used to access the filesystem.  Used in
  /// testing to redirect to an in-memory filesystem.
  final ResourceProvider resourceProvider;

  /// Logger instance we use to give feedback to the user.
  Logger logger;

  /// The result of parsing command-line options.
  @visibleForTesting
  /*late*/ CommandLineOptions options;

  /// The exit code that should be used when the process terminates, or `null`
  /// if there is still more work to do.
  int exitCode;

  final Map<String, List<AnalysisError>> fileErrors = {};

  final Map<String, LineInfo> lineInfo = {};

  MigrationCli(
      {@required this.binaryName,
      @visibleForTesting this.loggerFactory = _defaultLoggerFactory,
      @visibleForTesting this.defaultSdkPathOverride,
      @visibleForTesting ResourceProvider resourceProvider})
      : logger = loggerFactory(false),
        resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  Ansi get ansi => logger.ansi;

  Context get pathContext => resourceProvider.pathContext;

  /// Blocks until an interrupt signal (control-C) is received.  Tests may
  /// override this method to simulate control-C.
  @visibleForTesting
  Future<void> blockUntilSignalInterrupt() {
    Stream<ProcessSignal> stream = ProcessSignal.sigint.watch();
    return stream.first;
  }

  /// Parses and validates command-line arguments, and stores the results in
  /// [options].
  ///
  /// If no additional work should be done (e.g. because the user asked for
  /// help, or supplied a bad option), a nonzero value is stored in [exitCode].
  @visibleForTesting
  void parseCommandLineArgs(List<String> args) {
    try {
      var argResults = _createParser().parse(args);
      var isVerbose = argResults[CommandLineOptions.verboseFlag] as bool;
      if (argResults[CommandLineOptions.helpFlag] as bool) {
        _showUsage(isVerbose);
        exitCode = 0;
        return;
      }
      var rest = argResults.rest;
      String migratePath;
      if (rest.isEmpty) {
        migratePath = pathContext.current;
      } else if (rest.length > 1) {
        throw _BadArgException('No more than one path may be specified.');
      } else {
        migratePath = pathContext
            .normalize(pathContext.join(pathContext.current, rest[0]));
      }
      var migrateResource = resourceProvider.getResource(migratePath);
      if (migrateResource is File) {
        if (migrateResource.exists) {
          throw _BadArgException('$migratePath is a file.');
        } else {
          throw _BadArgException('$migratePath does not exist.');
        }
      }
      var applyChanges =
          argResults[CommandLineOptions.applyChangesFlag] as bool;
      var previewPortRaw =
          argResults[CommandLineOptions.previewPortOption] as String;
      int previewPort;
      try {
        previewPort = previewPortRaw == null ? null : int.parse(previewPortRaw);
      } on FormatException catch (_) {
        throw _BadArgException(
            'Invalid value for --${CommandLineOptions.previewPortOption}');
      }
      var webPreview = argResults[CommandLineOptions.webPreviewFlag] as bool;
      if (applyChanges && webPreview) {
        throw _BadArgException('--apply-changes requires --no-web-preview');
      }
      options = CommandLineOptions(
          applyChanges: applyChanges,
          directory: migratePath,
          ignoreErrors: argResults[CommandLineOptions.ignoreErrorsFlag] as bool,
          previewPort: previewPort,
          sdkPath: argResults[CommandLineOptions.sdkPathOption] as String ??
              defaultSdkPathOverride ??
              getSdkPath(),
          summary: argResults[CommandLineOptions.summaryOption] as String,
          webPreview: webPreview);
      if (isVerbose) {
        logger = loggerFactory(true);
      }
    } on Object catch (exception) {
      String message;
      if (exception is FormatException) {
        message = exception.message;
      } else if (exception is _BadArgException) {
        message = exception.message;
      } else {
        message =
            'Exception occurred while parsing command-line options: $exception';
      }
      logger.stderr(message);
      _showUsage(false);
      exitCode = 1;
      return;
    }
  }

  /// Runs the full migration process.
  void run(List<String> args) async {
    parseCommandLineArgs(args);
    if (exitCode != null) return;

    logger.stdout('Migrating ${options.directory}');
    logger.stdout('');

    List<String> previewUrls;
    NonNullableFix nonNullableFix;
    _DartFixListener dartFixListener;
    await _withProgress(
        '${ansi.emphasized('Generating migration suggestions')}', () async {
      var contextCollection = AnalysisContextCollectionImpl(
          includedPaths: [options.directory],
          resourceProvider: resourceProvider,
          sdkPath: options.sdkPath);
      var context = contextCollection.contexts.single;
      var fixCodeProcessor = _FixCodeProcessor(context, this);
      dartFixListener = _DartFixListener(
          _DriverProvider(resourceProvider, context.currentSession));
      nonNullableFix = NonNullableFix(dartFixListener, resourceProvider,
          included: [options.directory],
          preferredPort: options.previewPort,
          enablePreview: options.webPreview,
          summaryPath: options.summary);
      fixCodeProcessor.registerCodeTask(nonNullableFix);
      try {
        await fixCodeProcessor.runFirstPhase();
        _checkForErrors();
      } on StateError catch (e) {
        logger.stdout(e.toString());
        exitCode = 1;
      }
      if (exitCode != null) return;
      previewUrls = await fixCodeProcessor.runLaterPhases();
    });
    if (exitCode != null) return;

    if (options.applyChanges) {
      logger.stdout(ansi.emphasized('Applying changes:'));

      var allEdits = dartFixListener.sourceChange.edits;
      _applyMigrationSuggestions(allEdits);

      logger.stdout('');
      logger.stdout(
          'Applied ${allEdits.length} ${_pluralize(allEdits.length, 'edit')}.');

      // Note: do not open the web preview if apply-changes is specified, as we
      // currently cannot tell the web preview to disable the "apply migration"
      // button.
      exitCode = 0;
      return;
    }

    if (options.webPreview) {
      String url = previewUrls.first;
      assert(previewUrls.length <= 1,
          'Got unexpected extra preview URLs from server');

      logger.stdout(ansi.emphasized('View migration results:'));

      // TODO(devoncarew): Open a browser automatically.
      logger.stdout('''
Visit:
  
  ${ansi.emphasized(url)}

to see the migration results. Use the interactive web view to review, improve, or apply
the results (alternatively, to apply the results without using the web preview, re-run
the tool with --${CommandLineOptions.applyChangesFlag}).
''');

      logger.stdout('When finished with the preview, hit ctrl-c '
          'to terminate this process.');

      // Block until sigint (ctrl-c).
      await blockUntilSignalInterrupt();
      nonNullableFix.shutdownServer();
    } else {
      logger.stdout(ansi.emphasized('Summary of changes:'));

      _displayChangeSummary(dartFixListener);

      logger.stdout('');
      logger.stdout('To apply these changes, re-run the tool with '
          '--${CommandLineOptions.applyChangesFlag}.');
    }
    exitCode = 0;
  }

  /// Perform the indicated source edits to the given source, returning the
  /// resulting transformed text.
  String _applyEdits(SourceFileEdit sourceFileEdit, String source) {
    List<SourceEdit> edits = _sortEdits(sourceFileEdit);
    return SourceEdit.applySequence(source, edits);
  }

  void _applyMigrationSuggestions(List<SourceFileEdit> edits) {
    // Apply the changes to disk.
    for (SourceFileEdit sourceFileEdit in edits) {
      String relPath =
          pathContext.relative(sourceFileEdit.file, from: options.directory);
      int count = sourceFileEdit.edits.length;
      logger.stdout('  $relPath ($count ${_pluralize(count, 'change')})');

      String source;
      var file = resourceProvider.getFile(sourceFileEdit.file);
      try {
        source = file.readAsStringSync();
      } catch (_) {}

      if (source == null) {
        logger.stdout('    Unable to retrieve source for file.');
      } else {
        source = _applyEdits(sourceFileEdit, source);

        try {
          file.writeAsStringSync(source);
        } catch (e) {
          logger.stdout('    Unable to write source for file: $e');
        }
      }
    }
  }

  void _checkForErrors() {
    if (fileErrors.isEmpty) {
      logger.stdout('No analysis issues found.');
    } else {
      logger.stdout('');

      int issueCount =
          fileErrors.values.map((list) => list.length).reduce((a, b) => a + b);
      logger.stdout(
          '$issueCount analysis ${_pluralize(issueCount, 'issue')} found:');
      List<AnalysisError> allErrors = fileErrors.values
          .fold(<AnalysisError>[], (list, element) => list..addAll(element));
      _displayIssues(logger, options.directory, allErrors, lineInfo);
      var importErrorCount = allErrors.where(_isUriError).length;

      logger.stdout('');
      logger.stdout(
          'Note: analysis errors will result in erroneous migration suggestions.');

      if (options.ignoreErrors) {
        logger.stdout('Continuing with migration suggestions due to the use of '
            '--${CommandLineOptions.ignoreErrorsFlag}.');
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
            '--${CommandLineOptions.ignoreErrorsFlag}).');
        exitCode = 1;
        return;
      }
    }
  }

  ArgParser _createParser({bool hide = true}) {
    var parser = ArgParser();
    parser.addFlag(CommandLineOptions.applyChangesFlag,
        defaultsTo: false,
        negatable: false,
        help: 'Apply the proposed null safety changes to the files on disk.');
    parser.addFlag(CommandLineOptions.helpFlag,
        abbr: 'h',
        help:
            'Display this help message. Add --verbose to show hidden options.',
        defaultsTo: false,
        negatable: false);
    parser.addFlag(
      CommandLineOptions.ignoreErrorsFlag,
      defaultsTo: false,
      negatable: false,
      help: 'Attempt to perform null safety analysis even if there are '
          'analysis errors in the project.',
    );
    parser.addOption(CommandLineOptions.previewPortOption,
        help:
            'Run the preview server on the specified port.  If not specified, '
            'dynamically allocate a port.');
    parser.addOption(CommandLineOptions.sdkPathOption,
        help: 'The path to the Dart SDK.', hide: hide);
    parser.addOption(CommandLineOptions.summaryOption,
        help:
            'Output path for a machine-readable summary of migration changes');
    parser.addFlag(CommandLineOptions.verboseFlag,
        abbr: 'v',
        defaultsTo: false,
        help: 'Verbose output.',
        negatable: false);
    parser.addFlag(CommandLineOptions.webPreviewFlag,
        defaultsTo: true,
        negatable: true,
        help: 'Show an interactive preview of the proposed null safety changes '
            'in a browser window.\n'
            'With --no-web-preview, the proposed changes are instead printed to '
            'the console.');
    return parser;
  }

  void _displayChangeSummary(_DartFixListener migrationResults) {
    Map<String, List<_DartFixSuggestion>> fileSuggestions = {};
    for (_DartFixSuggestion suggestion in migrationResults.suggestions) {
      String file = suggestion.location.file;
      fileSuggestions.putIfAbsent(file, () => <_DartFixSuggestion>[]);
      fileSuggestions[file].add(suggestion);
    }

    // present a diff-like view
    var diffStyle = DiffStyle(logger.ansi);
    for (SourceFileEdit sourceFileEdit in migrationResults.sourceChange.edits) {
      String file = sourceFileEdit.file;
      String relPath = pathContext.relative(file, from: options.directory);
      var edits = sourceFileEdit.edits;
      int count = edits.length;

      logger.stdout('');
      logger.stdout('${ansi.emphasized(relPath)} '
          '($count ${_pluralize(count, 'change')}):');

      String source;
      try {
        source = resourceProvider.getFile(file).readAsStringSync();
      } catch (_) {}

      if (source == null) {
        logger.stdout('  (unable to retrieve source for file)');
      } else {
        for (var line
            in diffStyle.formatDiff(source, _sourceEditsToAtomicEdits(edits))) {
          logger.stdout('  $line');
        }
      }
    }
  }

  void _displayIssues(Logger logger, String directory,
      List<AnalysisError> issues, Map<String, LineInfo> lineInfo) {
    issues.sort((AnalysisError one, AnalysisError two) {
      if (one.source != two.source) {
        return one.source.fullName.compareTo(two.source.fullName);
      }
      return one.offset - two.offset;
    });

    _IssueRenderer renderer =
        _IssueRenderer(logger, directory, pathContext, lineInfo);
    for (AnalysisError issue in issues) {
      renderer.render(issue);
    }
  }

  bool _isUriError(AnalysisError error) =>
      error.errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST;

  void _showUsage(bool isVerbose) {
    logger.stderr('Usage: $binaryName [options...] [<package directory>]');

    logger.stderr('');
    logger.stderr(_createParser(hide: !isVerbose).usage);
    if (!isVerbose) {
      logger.stderr('');
      logger
          .stderr('Run "$binaryName -h -v" for verbose help output, including '
              'less commonly used options.');
    }
  }

  List<SourceEdit> _sortEdits(SourceFileEdit sourceFileEdit) {
    // Sort edits in reverse offset order.
    List<SourceEdit> edits = sourceFileEdit.edits.toList();
    edits.sort((a, b) {
      return b.offset - a.offset;
    });
    return edits;
  }

  Future<void> _withProgress(String message, FutureOr<void> callback()) async {
    var progress = logger.progress(message);
    try {
      await callback();
      progress.finish(showTiming: true);
    } finally {
      progress.cancel();
    }
  }

  static Logger _defaultLoggerFactory(bool isVerbose) {
    var ansi = Ansi(Ansi.terminalSupportsAnsi);
    if (isVerbose) {
      return Logger.verbose(ansi: ansi);
    } else {
      return Logger.standard(ansi: ansi);
    }
  }

  static Map<int, List<AtomicEdit>> _sourceEditsToAtomicEdits(
      List<SourceEdit> edits) {
    return {
      for (var edit in edits)
        edit.offset: [AtomicEdit.replace(edit.length, edit.replacement)]
    };
  }
}

class _BadArgException implements Exception {
  final String message;

  _BadArgException(this.message);
}

class _DartFixListener implements DartFixListenerInterface {
  @override
  final DriverProvider server;

  @override
  final SourceChange sourceChange = SourceChange('null safety migration');

  final List<_DartFixSuggestion> suggestions = [];

  _DartFixListener(this.server);

  @override
  void addDetail(String detail) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void addEditWithoutSuggestion(Source source, SourceEdit edit) {
    sourceChange.addEdit(source.fullName, -1, edit);
  }

  @override
  void addRecommendation(String description, [Location location]) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void addSourceFileEdit(
      String description, Location location, SourceFileEdit fileEdit) {
    suggestions.add(_DartFixSuggestion(description, location: location));
    for (var sourceEdit in fileEdit.edits) {
      sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
    }
  }

  @override
  void addSuggestion(String description, Location location) {
    suggestions.add(_DartFixSuggestion(description, location: location));
  }
}

class _DartFixSuggestion {
  final String description;

  final Location location;

  _DartFixSuggestion(this.description, {@required this.location});
}

class _DriverProvider implements DriverProvider {
  @override
  final ResourceProvider resourceProvider;

  final AnalysisSession analysisSession;

  _DriverProvider(this.resourceProvider, this.analysisSession);

  @override
  AnalysisSession getAnalysisSession(String path) => analysisSession;
}

class _FixCodeProcessor extends Object with FixCodeProcessor {
  final AnalysisContext context;

  final Set<String> pathsToProcess;

  final MigrationCli _migrationCli;

  _FixCodeProcessor(this.context, this._migrationCli)
      : pathsToProcess = context.contextRoot
            .analyzedFiles()
            .where((s) => s.endsWith('.dart'))
            .toSet();

  /// Call the supplied [process] function to process each compilation unit.
  Future processResources(
      Future<void> Function(ResolvedUnitResult result) process) async {
    var driver = context.currentSession;
    var pathsProcessed = <String>{};
    for (var path in pathsToProcess) {
      if (pathsProcessed.contains(path)) continue;
      switch (await driver.getSourceKind(path)) {
        case SourceKind.PART:
          // Parts will either be found in a library, below, or if the library
          // isn't [isIncluded], will be picked up in the final loop.
          continue;
          break;
        case SourceKind.LIBRARY:
          var result = await driver.getResolvedLibrary(path);
          if (result != null) {
            for (var unit in result.units) {
              if (pathsToProcess.contains(unit.path) &&
                  !pathsProcessed.contains(unit.path)) {
                await process(unit);
                pathsProcessed.add(unit.path);
              }
            }
          }
          break;
        default:
          break;
      }
    }

    for (var path in pathsToProcess.difference(pathsProcessed)) {
      var result = await driver.getResolvedUnit(path);
      if (result == null || result.unit == null) {
        continue;
      }
      await process(result);
    }
  }

  Future<void> runFirstPhase() async {
    // Process package
    await processPackage(context.contextRoot.root);

    // Process each source file.
    await processResources((ResolvedUnitResult result) async {
      List<AnalysisError> errors = result.errors
          .where((error) => error.severity == Severity.error)
          .toList();
      if (errors.isNotEmpty) {
        _migrationCli.fileErrors[result.path] = errors;
        _migrationCli.lineInfo[result.path] = result.lineInfo;
      }
      if (_migrationCli.options.ignoreErrors ||
          _migrationCli.fileErrors.isEmpty) {
        await processCodeTasks(0, result);
      }
    });
  }

  Future<List<String>> runLaterPhases() async {
    for (var phase = 1; phase < numPhases; phase++) {
      await processResources((ResolvedUnitResult result) async {
        await processCodeTasks(phase, result);
      });
    }
    await finishCodeTasks();

    return nonNullableFixTask.previewUrls;
  }
}

/// Given a Logger and an analysis issue, render the issue to the logger.
class _IssueRenderer {
  final Logger logger;
  final String rootDirectory;
  final Context pathContext;
  final Map<String, LineInfo> lineInfo;

  _IssueRenderer(
      this.logger, this.rootDirectory, this.pathContext, this.lineInfo);

  void render(AnalysisError issue) {
    // severity • Message ... at foo/bar.dart:6:1 • (error_code)
    var lineInfoForThisFile = lineInfo[issue.source.fullName];
    var location = lineInfoForThisFile.getLocation(issue.offset);

    final Ansi ansi = logger.ansi;

    logger.stdout(
      '  ${ansi.error(_severityToString(issue.severity))} • '
      '${ansi.emphasized(_removePeriod(issue.message))} '
      'at ${pathContext.relative(issue.source.fullName, from: rootDirectory)}'
      ':${location.lineNumber}:'
      '${location.columnNumber} '
      '• (${issue.errorCode.name.toLowerCase()})',
    );
  }

  String _severityToString(Severity severity) {
    switch (severity) {
      case Severity.error:
        return 'error';
      case Severity.warning:
        return 'warning';
      case Severity.info:
        return 'info';
    }
    return '???';
  }
}
