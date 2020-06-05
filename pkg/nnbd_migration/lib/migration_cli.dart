// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:io' hide File;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart'
    show File, ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/driver_provider_impl.dart';
import 'package:nnbd_migration/src/front_end/non_nullable_fix.dart';
import 'package:nnbd_migration/src/utilities/json.dart' as json;
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
  static const skipPubOutdatedFlag = 'skip-pub-outdated';
  static const summaryOption = 'summary';
  static const verboseFlag = 'verbose';
  static const webPreviewFlag = 'web-preview';

  final bool applyChanges;

  final String directory;

  final bool ignoreErrors;

  final int previewPort;

  final String sdkPath;

  final bool skipPubOutdated;

  final String summary;

  final bool webPreview;

  CommandLineOptions(
      {@required this.applyChanges,
      @required this.directory,
      @required this.ignoreErrors,
      @required this.previewPort,
      @required this.sdkPath,
      @required this.skipPubOutdated,
      @required this.summary,
      @required this.webPreview});
}

@visibleForTesting
class DependencyChecker {
  static final _pubName = Platform.isWindows ? 'pub.bat' : 'pub';

  /// The directory which contains the package being migrated.
  final String _directory;
  final Context _pathContext;
  final Logger _logger;
  final ProcessManager _processManager;

  DependencyChecker(
      this._directory, this._pathContext, this._logger, this._processManager);

  bool check() {
    var pubPath = _pathContext.join(getSdkPath(), 'bin', _pubName);
    var result = _processManager.runSync(
        pubPath, ['outdated', '--mode=null-safety', '--json'],
        workingDirectory: _directory);

    var preNullSafetyPackages = <String, String>{};
    try {
      if ((result.stderr as String).isNotEmpty) {
        throw FormatException(
            '`pub outdated --mode=null-safety` exited with exit code '
            '${result.exitCode} and stderr:\n\n${result.stderr}');
      }
      var outdatedOutput = jsonDecode(result.stdout as String);
      var outdatedMap = json.expectType<Map>(outdatedOutput, 'root');
      var packageList =
          json.expectType<List>(outdatedMap['packages'], 'packages');
      for (var package_ in packageList) {
        var package = json.expectType<Map>(package_, '');
        var current_ = json.expectKey(package, 'current');
        if (current_ == null) {
          continue;
        }
        var current = json.expectType<Map>(current_, 'current');
        if (json.expectType<bool>(current['nullSafety'], 'nullSafety')) {
          // For whatever reason, there is no "current" version of this package.
          // TODO(srawlins): We may want to report this to the user. But it may
          // be inconsequential.
          continue;
        }

        json.expectKey(package, 'package');
        json.expectKey(current, 'version');
        var name = json.expectType<String>(package['package'], 'package');
        // A version will be given, even if a package was provided with a local
        // or git path.
        var version = json.expectType<String>(current['version'], 'version');
        preNullSafetyPackages[name] = version;
      }
    } on FormatException catch (e) {
      _logger.stderr('Warning: ${e.message}');
      // Allow the program to continue; users should be allowed to attempt to
      // migrate when `pub outdated` is misbehaving, or if there is a bug above.
    }
    if (preNullSafetyPackages.isNotEmpty) {
      _logger.stderr(
          'Warning: dependencies are outdated. The version(s) of one or more '
          'packages currently checked out have not yet migrated to the Null '
          'Safety feature.');
      _logger.stderr('');
      for (var package in preNullSafetyPackages.entries) {
        _logger.stderr(
            '    ${package.key}, currently at version ${package.value}');
      }
      _logger.stderr('');
      _logger.stderr('It is highly recommended to upgrade all dependencies to '
          'versions which have migrated. Use `$_pubName outdated '
          '--mode=null-safety` to check the status of dependencies.');
      _logger.stderr('');
      _logger.stderr('Visit https://dart.dev/tools/pub/cmd/pub-outdated for '
          'more information.');
      _logger.stderr('');
      _logger.stderr('You can force migration with '
          "'--${CommandLineOptions.skipPubOutdatedFlag}' (not recommended).");
      return false;
    }
    return true;
  }
}

class MigrateCommand extends Command<dynamic> {
  final bool verbose;

  MigrateCommand({this.verbose = false}) {
    MigrationCli._defineOptions(argParser, !verbose);
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
  FutureOr<int> run() async {
    var cli = MigrationCli(binaryName: 'dart $name');
    await cli.run(argResults, isVerbose: verbose);
    return cli.exitCode;
  }
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

  /// Process manager that should be used to run processes. Used in testing to
  /// redirect to mock processes.
  @visibleForTesting
  final ProcessManager processManager;

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

  DartFixListener _dartFixListener;

  _FixCodeProcessor _fixCodeProcessor;

  AnalysisContextCollection _contextCollection;

  MigrationCli(
      {@required this.binaryName,
      @visibleForTesting this.loggerFactory = _defaultLoggerFactory,
      @visibleForTesting this.defaultSdkPathOverride,
      @visibleForTesting ResourceProvider resourceProvider,
      @visibleForTesting this.processManager = const ProcessManager.system()})
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

  NonNullableFix createNonNullableFix(DartFixListener listener,
      ResourceProvider resourceProvider, LineInfo getLineInfo(String path),
      {List<String> included = const <String>[],
      int preferredPort,
      bool enablePreview = true,
      String summaryPath}) {
    return NonNullableFix(listener, resourceProvider, getLineInfo,
        included: included,
        preferredPort: preferredPort,
        enablePreview: enablePreview,
        summaryPath: summaryPath);
  }

  /// Parses and validates command-line arguments, and stores the results in
  /// [options].
  ///
  /// If no additional work should be done (e.g. because the user asked for
  /// help, or supplied a bad option), a nonzero value is stored in [exitCode].
  @visibleForTesting
  void decodeCommandLineArgs(ArgResults argResults, {bool isVerbose}) {
    try {
      isVerbose ??= argResults[CommandLineOptions.verboseFlag] as bool;
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
          skipPubOutdated:
              argResults[CommandLineOptions.skipPubOutdatedFlag] as bool,
          summary: argResults[CommandLineOptions.summaryOption] as String,
          webPreview: webPreview);

      if (isVerbose) {
        logger = loggerFactory(true);
      }
    } on Object catch (exception) {
      handleArgParsingException(exception);
    }
  }

  void handleArgParsingException(Object exception) {
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

  /// Runs the full migration process.
  void run(ArgResults argResults, {bool isVerbose}) async {
    decodeCommandLineArgs(argResults, isVerbose: isVerbose);
    if (exitCode != null) return;
    if (!options.skipPubOutdated) {
      _checkDependencies();
    }
    if (exitCode != null) return;

    logger.stdout('Migrating ${options.directory}');
    logger.stdout('');

    if (hasMultipleAnalysisContext) {
      logger.stdout(
          'Note: more than one project found; migrating the top-level project.');
      logger.stdout('');
    }

    DriverBasedAnalysisContext context = analysisContext;

    List<String> previewUrls;
    NonNullableFix nonNullableFix;

    await _withProgress(
        '${ansi.emphasized('Generating migration suggestions')}', () async {
      _fixCodeProcessor = _FixCodeProcessor(context, this);
      _dartFixListener =
          DartFixListener(DriverProviderImpl(resourceProvider, context));
      nonNullableFix = createNonNullableFix(
          _dartFixListener, resourceProvider, _fixCodeProcessor.getLineInfo,
          included: [options.directory],
          preferredPort: options.previewPort,
          enablePreview: options.webPreview,
          summaryPath: options.summary);
      nonNullableFix.rerunFunction = _rerunFunction;
      _fixCodeProcessor.registerCodeTask(nonNullableFix);
      _fixCodeProcessor.nonNullableFixTask = nonNullableFix;

      try {
        // TODO(devoncarew): The progress written by the fix processor conflicts
        // with the progress written by the ansi logger above.
        await _fixCodeProcessor.runFirstPhase();
        _fixCodeProcessor._progressBar.clear();
        _checkForErrors();
      } on StateError catch (e) {
        logger.stdout(e.toString());
        exitCode = 1;
      }
      if (exitCode != null) return;
      previewUrls = await _fixCodeProcessor.runLaterPhases();
    });
    if (exitCode != null) return;

    if (options.applyChanges) {
      logger.stdout(ansi.emphasized('Applying changes:'));

      var allEdits = _dartFixListener.sourceChange.edits;
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

      // TODO(#41809): Open a browser automatically.
      logger.stdout('''
View the migration suggestions by visiting:

  ${ansi.emphasized(url)}

Use this interactive web view to review, improve, or apply the results.
''');

      logger.stdout('When finished with the preview, hit ctrl-c '
          'to terminate this process.');

      // Block until sigint (ctrl-c).
      await blockUntilSignalInterrupt();
      nonNullableFix.shutdownServer();
    } else {
      logger.stdout(ansi.emphasized('Summary of changes:'));

      _displayChangeSummary(_dartFixListener);

      logger.stdout('');
      logger.stdout('To apply these changes, re-run the tool with '
          '--${CommandLineOptions.applyChangesFlag}.');
    }
    exitCode = 0;
  }

  AnalysisContextCollection get contextCollection {
    _contextCollection ??= AnalysisContextCollectionImpl(
        includedPaths: [options.directory],
        resourceProvider: resourceProvider,
        sdkPath: pathContext.normalize(options.sdkPath));
    return _contextCollection;
  }

  @visibleForTesting
  DriverBasedAnalysisContext get analysisContext {
    // Handle the case of more than one analysis context being found (typically,
    // the current directory and one or more sub-directories).
    if (hasMultipleAnalysisContext) {
      return contextCollection.contextFor(options.directory)
          as DriverBasedAnalysisContext;
    } else {
      return contextCollection.contexts.single as DriverBasedAnalysisContext;
    }
  }

  @visibleForTesting
  bool get hasMultipleAnalysisContext {
    return contextCollection.contexts.length > 1;
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

  void _checkDependencies() {
    var successful = DependencyChecker(
            options.directory, pathContext, logger, processManager)
        .check();
    if (!successful) {
      exitCode = 1;
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

  void _displayChangeSummary(DartFixListener migrationResults) {
    Map<String, List<DartFixSuggestion>> fileSuggestions = {};
    for (DartFixSuggestion suggestion in migrationResults.suggestions) {
      String file = suggestion.location.file;
      fileSuggestions.putIfAbsent(file, () => <DartFixSuggestion>[]);
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

  Future<void> _rerunFunction() async {
    _dartFixListener.reset();
    _fixCodeProcessor.prepareToRerun();
    await _fixCodeProcessor.runFirstPhase();
    // TODO(paulberry): check for errors (see
    // https://github.com/dart-lang/sdk/issues/41712)
    await _fixCodeProcessor.runLaterPhases();
  }

  void _showUsage(bool isVerbose) {
    logger.stderr('Usage: $binaryName [options...] [<package directory>]');

    logger.stderr('');
    logger.stderr(createParser(hide: !isVerbose).usage);
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

  static ArgParser createParser({bool hide = true}) {
    var parser = ArgParser();
    parser.addFlag(CommandLineOptions.helpFlag,
        abbr: 'h',
        help:
            'Display this help message. Add --verbose to show hidden options.',
        defaultsTo: false,
        negatable: false);
    _defineOptions(parser, hide);
    return parser;
  }

  static Logger _defaultLoggerFactory(bool isVerbose) {
    var ansi = Ansi(Ansi.terminalSupportsAnsi);
    if (isVerbose) {
      return Logger.verbose(ansi: ansi);
    } else {
      return Logger.standard(ansi: ansi);
    }
  }

  static void _defineOptions(ArgParser parser, bool hide) {
    parser.addFlag(CommandLineOptions.applyChangesFlag,
        defaultsTo: false,
        negatable: false,
        help: 'Apply the proposed null safety changes to the files on disk.');
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
    parser.addFlag(
      CommandLineOptions.skipPubOutdatedFlag,
      defaultsTo: false,
      negatable: false,
      help: 'Skip the `pub outdated --mode=null-safety` check.',
    );
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
  }

  static Map<int, List<AtomicEdit>> _sourceEditsToAtomicEdits(
      List<SourceEdit> edits) {
    return {
      for (var edit in edits)
        edit.offset: [AtomicEdit.replace(edit.length, edit.replacement)]
    };
  }
}

/// An abstraction over the static methods on [Process].
///
/// Used in tests to run mock processes.
abstract class ProcessManager {
  const factory ProcessManager.system() = SystemProcessManager;

  /// Run a process synchronously, as in [Process.runSync].
  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory});
}

/// A [ProcessManager] that directs all method calls to static methods of
/// [Process], in order to run real processes.
class SystemProcessManager implements ProcessManager {
  const SystemProcessManager();

  ProcessResult runSync(String executable, List<String> arguments,
          {String workingDirectory}) =>
      Process.runSync(executable, arguments,
          workingDirectory: workingDirectory ?? Directory.current.path);
}

class _BadArgException implements Exception {
  final String message;

  _BadArgException(this.message);
}

class _FixCodeProcessor extends Object {
  final DriverBasedAnalysisContext context;

  NonNullableFix _task;

  Set<String> pathsToProcess;

  _ProgressBar _progressBar;

  final MigrationCli _migrationCli;

  /// The task used to migrate to NNBD.
  NonNullableFix nonNullableFixTask;

  _FixCodeProcessor(this.context, this._migrationCli)
      : pathsToProcess = _computePathsToProcess(context);

  LineInfo getLineInfo(String path) =>
      context.currentSession.getFile(path).lineInfo;

  void prepareToRerun() {
    var driver = context.driver;
    pathsToProcess = _computePathsToProcess(context);
    pathsToProcess.forEach(driver.changeFile);
  }

  /// Call the supplied [process] function to process each compilation unit.
  Future<void> processResources(
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

  void registerCodeTask(NonNullableFix task) {
    _task = task;
  }

  Future<void> runFirstPhase() async {
    // All tasks should be registered; [numPhases] should be finalized.
    _progressBar = _ProgressBar(pathsToProcess.length * _task.numPhases);

    // Process package
    _task.processPackage(context.contextRoot.root);

    // Process each source file.
    await processResources((ResolvedUnitResult result) async {
      _progressBar.tick();
      List<AnalysisError> errors = result.errors
          .where((error) => error.severity == Severity.error)
          .toList();
      if (errors.isNotEmpty) {
        _migrationCli.fileErrors[result.path] = errors;
        _migrationCli.lineInfo[result.path] = result.lineInfo;
      }
      if (_migrationCli.options.ignoreErrors ||
          _migrationCli.fileErrors.isEmpty) {
        await _task.processUnit(0, result);
      }
    });
  }

  Future<List<String>> runLaterPhases() async {
    for (var phase = 1; phase < _task.numPhases; phase++) {
      await processResources((ResolvedUnitResult result) async {
        _progressBar.tick();
        await _task.processUnit(phase, result);
      });
    }
    await _task.finish();
    _progressBar.complete();

    return nonNullableFixTask.previewUrls;
  }

  static Set<String> _computePathsToProcess(
          DriverBasedAnalysisContext context) =>
      context.contextRoot
          .analyzedFiles()
          .where((s) => s.endsWith('.dart'))
          .toSet();
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

/// A facility for drawing a progress bar in the terminal.
///
/// The bar is instantiated with the total number of "ticks" to be completed,
/// and progress is made by calling [tick]. The bar is drawn across one entire
/// line, like so:
///
///     [----------                                                   ]
///
/// The hyphens represent completed progress, and the whitespace represents
/// remaining progress.
///
/// If there is no terminal, the progress bar will not be drawn.
class _ProgressBar {
  /// Whether the progress bar should be drawn.
  /*late*/ bool _shouldDrawProgress;

  /// The width of the terminal, in terms of characters.
  /*late*/ int _width;

  /// The inner width of the terminal, in terms of characters.
  ///
  /// This represents the number of characters available for drawing progress.
  /*late*/ int _innerWidth;

  final int _totalTickCount;

  int _tickCount = 0;

  _ProgressBar(this._totalTickCount) {
    if (!stdout.hasTerminal) {
      _shouldDrawProgress = false;
    } else {
      _shouldDrawProgress = true;
      _width = stdout.terminalColumns;
      _innerWidth = stdout.terminalColumns - 2;
      stdout.write('[' + ' ' * _innerWidth + ']');
    }
  }

  /// Clear the progress bar from the terminal, allowing other logging to be
  /// printed.
  void clear() {
    if (!_shouldDrawProgress) {
      return;
    }
    stdout.write('\r' + ' ' * _width + '\r');
  }

  /// Draw the progress bar as complete, and print two newlines.
  void complete() {
    if (!_shouldDrawProgress) {
      return;
    }
    stdout.write('\r[' + '-' * _innerWidth + ']\n\n');
  }

  /// Progress the bar by one tick.
  void tick() {
    if (!_shouldDrawProgress) {
      return;
    }
    _tickCount++;
    var fractionComplete = _tickCount * _innerWidth ~/ _totalTickCount - 1;
    var remaining = _innerWidth - fractionComplete - 1;
    stdout.write('\r[' + // Bring cursor back to the start of the line.
        '-' * fractionComplete + // Print complete work.
        AnsiProgress.kAnimationItems[_tickCount % 4] + // Print spinner.
        ' ' * remaining + // Print remaining work.
        ']');
  }
}
