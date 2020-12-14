// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide File;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart'
    show File, ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
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
import 'package:nnbd_migration/src/exceptions.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/driver_provider_impl.dart';
import 'package:nnbd_migration/src/front_end/migration_state.dart';
import 'package:nnbd_migration/src/front_end/non_nullable_fix.dart';
import 'package:nnbd_migration/src/messages.dart';
import 'package:nnbd_migration/src/utilities/progress_bar.dart';
import 'package:nnbd_migration/src/utilities/source_edit_diff_formatter.dart';
import 'package:path/path.dart' show Context;

String _pluralize(int count, String single, {String multiple}) {
  return count == 1 ? single : (multiple ?? '${single}s');
}

String _removePeriod(String value) {
  return value.endsWith('.') ? value.substring(0, value.length - 1) : value;
}

/// The result of a round of static analysis; primarily a list of
/// [AnalysisError]s.
class AnalysisResult {
  final List<AnalysisError> errors;
  final Map<String, LineInfo> lineInfo;
  final Context pathContext;
  final String rootDirectory;
  final bool allSourcesAlreadyMigrated;

  AnalysisResult(this.errors, this.lineInfo, this.pathContext,
      this.rootDirectory, this.allSourcesAlreadyMigrated) {
    errors.sort((AnalysisError one, AnalysisError two) {
      if (one.source != two.source) {
        return one.source.fullName.compareTo(two.source.fullName);
      }
      return one.offset - two.offset;
    });
  }

  bool get hasErrors => errors.isNotEmpty;

  /// Whether the errors include any which may be the result of not yet having
  /// run "pub get".
  bool get hasImportErrors => errors.any(
      (error) => error.errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST);

  /// Converts the list of errors into JSON, for displaying in the web preview.
  List<Map<String, dynamic>> toJson() {
    var result = <Map<String, dynamic>>[];
    // severity • Message ... at foo/bar.dart:6:1 • (error_code)
    for (var error in errors) {
      var lineInfoForThisFile = lineInfo[error.source.fullName];
      var location = lineInfoForThisFile.getLocation(error.offset);
      var path =
          pathContext.relative(error.source.fullName, from: rootDirectory);
      result.add({
        'severity': error.severity.name,
        'message': _removePeriod(error.message),
        'location': '$path:${location.lineNumber}:${location.columnNumber}',
        'code': error.errorCode.name.toLowerCase(),
      });
    }
    return result;
  }
}

/// Data structure recording command-line options for the migration tool that
/// have been passed in by the client.
class CommandLineOptions {
  static const applyChangesFlag = 'apply-changes';
  static const helpFlag = 'help';
  static const ignoreErrorsFlag = 'ignore-errors';
  static const ignoreExceptionsFlag = 'ignore-exceptions';
  static const previewHostnameOption = 'preview-hostname';
  static const previewPortOption = 'preview-port';
  static const sdkPathOption = 'sdk-path';
  static const skipImportCheckFlag = 'skip-import-check';
  static const summaryOption = 'summary';
  static const verboseFlag = 'verbose';
  static const webPreviewFlag = 'web-preview';

  final bool applyChanges;

  final String directory;

  final bool ignoreErrors;

  final bool ignoreExceptions;

  final String previewHostname;

  final int previewPort;

  final String sdkPath;

  final bool skipImportCheck;

  final String summary;

  final bool webPreview;

  CommandLineOptions(
      {@required this.applyChanges,
      @required this.directory,
      @required this.ignoreErrors,
      @required this.ignoreExceptions,
      @required this.previewHostname,
      @required this.previewPort,
      @required this.sdkPath,
      @required this.skipImportCheck,
      @required this.summary,
      @required this.webPreview});
}

// TODO(devoncarew): Refactor so this class extends DartdevCommand.
class MigrateCommand extends Command<int> {
  static const String cmdName = 'migrate';

  static const String cmdDescription =
      'Perform a null safety migration on a project or package.';

  static const String migrationGuideLink =
      'See https://dart.dev/go/null-safety-migration for a migration guide.';

  /// Return whether the SDK has null safety on by default.
  static bool get nullSafetyOnByDefault => IsEnabledByDefault.non_nullable;

  final bool verbose;

  ArgParser _argParser;

  MigrateCommand({this.verbose = false}) {
    MigrationCli._defineOptions(argParser, !verbose);
  }

  @override
  ArgParser get argParser {
    // We override this in order to configure the help text line wrapping.
    return _argParser ??= ArgParser(
      usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
    );
  }

  @override
  String get description => '$cmdDescription\n\n$migrationGuideLink';

  @override
  String get invocation {
    return '${super.invocation} [project or directory]';
  }

  @override
  String get name => cmdName;

  @override
  FutureOr<int> run() async {
    var cli = MigrationCli(binaryName: 'dart $name');
    try {
      await cli.decodeCommandLineArgs(argResults, isVerbose: verbose)?.run();
    } on MigrationExit catch (migrationExit) {
      return migrationExit.exitCode;
    }
    return 0;
  }
}

/// Command-line API for the migration tool, with additional parameters exposed
/// for testing.
///
/// Recommended usage: create an instance of this object and call
/// [decodeCommandLineArgs].  If it returns non-null, call
/// [MigrationCliRunner.run] on the result.  If either method throws a
/// [MigrationExit], exit with the error code contained therein.
class MigrationCli {
  /// A list of all the command-line options supported by the tool.
  ///
  /// This may be used by clients that wish to run migration but provide their
  /// own command-line interface.
  static final List<MigrationCliOption> options = [
    MigrationCliOption(
        CommandLineOptions.verboseFlag,
        (parser, hide) => parser.addFlag(
              CommandLineOptions.verboseFlag,
              abbr: 'v',
              defaultsTo: false,
              help: 'Show additional command output.',
              negatable: false,
            )),
    MigrationCliOption(
        CommandLineOptions.applyChangesFlag,
        (parser, hide) => parser.addFlag(CommandLineOptions.applyChangesFlag,
            defaultsTo: false,
            negatable: false,
            help:
                'Apply the proposed null safety changes to the files on disk.')),
    MigrationCliOption(
        CommandLineOptions.ignoreErrorsFlag,
        (parser, hide) => parser.addFlag(
              CommandLineOptions.ignoreErrorsFlag,
              defaultsTo: false,
              negatable: false,
              help:
                  'Attempt to perform null safety analysis even if the package has '
                  'analysis errors.',
            )),
    MigrationCliOption(
        CommandLineOptions.skipImportCheckFlag,
        (parser, hide) => parser.addFlag(
              CommandLineOptions.skipImportCheckFlag,
              defaultsTo: false,
              negatable: false,
              help: 'Go ahead with migration even if some imported files have '
                  'not yet been migrated.',
            )),
    MigrationCliOption.separator('Web interface options:'),
    MigrationCliOption(
        CommandLineOptions.webPreviewFlag,
        (parser, hide) => parser.addFlag(
              CommandLineOptions.webPreviewFlag,
              defaultsTo: true,
              negatable: true,
              help:
                  'Show an interactive preview of the proposed null safety changes '
                  'in a browser window. Use --no-web-preview to print proposed changes '
                  'to the console.',
            )),
    MigrationCliOption(
        CommandLineOptions.previewHostnameOption,
        (parser, hide) => parser.addOption(
              CommandLineOptions.previewHostnameOption,
              defaultsTo: 'localhost',
              valueHelp: 'host',
              help: 'Run the preview server on the specified hostname. If not '
                  'specified, "localhost" is used. Use "any" to specify IPv6.any or '
                  'IPv4.any.',
            )),
    MigrationCliOption(
        CommandLineOptions.previewPortOption,
        (parser, hide) => parser.addOption(
              CommandLineOptions.previewPortOption,
              valueHelp: 'port',
              help:
                  'Run the preview server on the specified port. If not specified, '
                  'dynamically allocate a port.',
            )),
    MigrationCliOption.separator('Additional options:'),
    MigrationCliOption(
        CommandLineOptions.summaryOption,
        (parser, hide) => parser.addOption(
              CommandLineOptions.summaryOption,
              help: 'Output a machine-readable summary of migration changes.',
              valueHelp: 'path',
            )),
    // hidden options
    MigrationCliOption(
        CommandLineOptions.ignoreExceptionsFlag,
        (parser, hide) => parser.addFlag(
              CommandLineOptions.ignoreExceptionsFlag,
              defaultsTo: false,
              negatable: false,
              help:
                  'Attempt to perform null safety analysis even if exceptions occur.',
              hide: hide,
            )),
    MigrationCliOption(
        CommandLineOptions.sdkPathOption,
        (parser, hide) => parser.addOption(
              CommandLineOptions.sdkPathOption,
              valueHelp: 'sdk-path',
              help: 'The path to the Dart SDK.',
              hide: hide,
            )),
  ];

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
  final Logger logger;

  /// The environment variables, tracked to help users debug if SDK_PATH was
  /// specified and that resulted in any [ExperimentStatusException]s.
  final Map<String, String> _environmentVariables;

  MigrationCli({
    @required this.binaryName,
    @visibleForTesting this.loggerFactory = _defaultLoggerFactory,
    @visibleForTesting this.defaultSdkPathOverride,
    @visibleForTesting ResourceProvider resourceProvider,
    @visibleForTesting Map<String, String> environmentVariables,
  })  : logger = loggerFactory(false),
        resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE,
        _environmentVariables = environmentVariables ?? Platform.environment;

  Context get pathContext => resourceProvider.pathContext;

  /// Parses and validates command-line arguments, and creates a
  /// [MigrationCliRunner] that is prepared to perform migration.
  ///
  /// If the user asked for help, it is printed using the logger configured in
  /// the constructor, and `null` is returned.
  ///
  /// If the user supplied a bad option, a message is printed using the logger
  /// configured in the constructor, and [MigrationExit] is thrown.
  MigrationCliRunner decodeCommandLineArgs(ArgResults argResults,
      {bool isVerbose}) {
    try {
      isVerbose ??= argResults[CommandLineOptions.verboseFlag] as bool;
      if (argResults[CommandLineOptions.helpFlag] as bool) {
        _showUsage(isVerbose);
        return null;
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
      bool webPreview;
      if (argResults.wasParsed(CommandLineOptions.webPreviewFlag)) {
        webPreview = argResults[CommandLineOptions.webPreviewFlag] as bool;
      } else {
        // If the `webPreviewFlag` wasn't explicitly passed, then the value of
        // this option is based on the value of the [applyChanges] option.
        webPreview = !applyChanges;
      }
      if (applyChanges && webPreview) {
        throw _BadArgException('--apply-changes requires --no-web-preview');
      }
      var options = CommandLineOptions(
          applyChanges: applyChanges,
          directory: migratePath,
          ignoreErrors: argResults[CommandLineOptions.ignoreErrorsFlag] as bool,
          ignoreExceptions:
              argResults[CommandLineOptions.ignoreExceptionsFlag] as bool,
          previewHostname:
              argResults[CommandLineOptions.previewHostnameOption] as String,
          previewPort: previewPort,
          sdkPath: argResults[CommandLineOptions.sdkPathOption] as String ??
              defaultSdkPathOverride ??
              getSdkPath(),
          skipImportCheck:
              argResults[CommandLineOptions.skipImportCheckFlag] as bool,
          summary: argResults[CommandLineOptions.summaryOption] as String,
          webPreview: webPreview);
      return MigrationCliRunner(this, options,
          logger: isVerbose ? loggerFactory(true) : null);
    } on Object catch (exception) {
      handleArgParsingException(exception);
    }
  }

  @alwaysThrows
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
    throw MigrationExit(1);
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
    for (var option in options) {
      option.addToParser(parser, hide);
    }
  }
}

/// Data structure representing a single command-line option to the migration
/// tool, or a separator in the list of command-line options.
class MigrationCliOption {
  /// The name of the option, without the leading `--`.
  final String name;

  /// Callback function that can be used to add the option or separator to the
  /// given [parser].  If [hide] is `true`, and the option is rarely used, it
  /// is added as a hidden option.
  final void Function(ArgParser parser, bool hide) addToParser;

  /// If `true`, this is a separator between command line options; if `false`,
  /// it's an option.
  final bool isSeparator;

  MigrationCliOption(this.name, this.addToParser) : isSeparator = false;

  MigrationCliOption.separator(this.name)
      : addToParser = ((parser, hide) => parser.addSeparator(name)),
        isSeparator = true;
}

/// Internals of the command-line API for the migration tool, with additional
/// methods exposed for testing.
///
/// This class may be used directly by clients that with to run migration but
/// provide their own command-line interface.
class MigrationCliRunner implements DartFixListenerClient {
  final MigrationCli cli;

  /// Logger instance we use to give feedback to the user.
  final Logger logger;

  /// The result of parsing command-line options.
  final CommandLineOptions options;

  final Map<String, LineInfo> lineInfo = {};

  DartFixListener _dartFixListener;

  _FixCodeProcessor _fixCodeProcessor;

  AnalysisContextCollection _contextCollection;

  bool _hasExceptions = false;

  bool _hasAnalysisErrors = false;

  MigrationCliRunner(this.cli, this.options, {Logger logger})
      : logger = logger ?? cli.logger;

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

  Ansi get ansi => logger.ansi;

  AnalysisContextCollection get contextCollection {
    _contextCollection ??= AnalysisContextCollectionImpl(
        includedPaths: [options.directory],
        resourceProvider: resourceProvider,
        sdkPath: pathContext.normalize(options.sdkPath));
    return _contextCollection;
  }

  @visibleForTesting
  bool get hasMultipleAnalysisContext {
    return contextCollection.contexts.length > 1;
  }

  @visibleForTesting
  bool get isPreviewServerRunning =>
      _fixCodeProcessor?.isPreviewServerRunnning ?? false;

  Context get pathContext => resourceProvider.pathContext;

  ResourceProvider get resourceProvider => cli.resourceProvider;

  /// Called after changes have been applied on disk.  Maybe overridden by a
  /// derived class.
  void applyHook() {}

  /// Blocks until an interrupt signal (control-C) is received.  Tests may
  /// override this method to simulate control-C.
  @visibleForTesting
  Future<void> blockUntilSignalInterrupt() {
    Stream<ProcessSignal> stream = ProcessSignal.sigint.watch();
    return stream.first;
  }

  /// Computes the internet address that should be passed to `HttpServer.bind`
  /// when starting the preview server.  May be overridden in derived classes.
  Object computeBindAddress() {
    var hostname = options.previewHostname;
    if (hostname == 'localhost') {
      return InternetAddress.loopbackIPv4;
    } else if (hostname == 'any') {
      return InternetAddress.anyIPv6;
    } else {
      return hostname;
    }
  }

  /// Computes the set of file paths that should be analyzed by the migration
  /// engine.  May be overridden by a derived class.
  ///
  /// All files to be migrated must be included in the returned set.  It is
  /// permissible for the set to contain additional files that could help the
  /// migration tool build up a more complete nullability graph (for example
  /// generated files, or usages of the code-to-be-migrated by one one of its
  /// clients).
  ///
  /// By default returns the set of all `.dart` files contained in the context.
  Set<String> computePathsToProcess(DriverBasedAnalysisContext context) =>
      context.contextRoot
          .analyzedFiles()
          .where((s) => s.endsWith('.dart'))
          .toSet();

  NonNullableFix createNonNullableFix(
      DartFixListener listener,
      ResourceProvider resourceProvider,
      LineInfo Function(String path) getLineInfo,
      Object bindAddress,
      {List<String> included = const <String>[],
      int preferredPort,
      String summaryPath,
      @required String sdkPath}) {
    return NonNullableFix(
        listener, resourceProvider, getLineInfo, bindAddress, logger,
        included: included,
        preferredPort: preferredPort,
        summaryPath: summaryPath,
        sdkPath: sdkPath);
  }

  @override
  void onException(String detail) {
    if (_hasExceptions) {
      if (!options.ignoreExceptions) {
        // Our intention is to exit immediately when an exception occurred.  We
        // tried, but failed (probably due to permissive mode logic in the
        // migration tool itself catching the MigrationExit exception).  The
        // stack has now been unwound further, so throw again.
        throw MigrationExit(1);
      }
      // We're not exiting immediately when an exception occurs.  We've already
      // reported that an exception happened.  So do nothing further.
      return;
    }
    _hasExceptions = true;
    if (options.ignoreExceptions) {
      logger.stdout('''
Exception(s) occurred during migration.  Attempting to perform
migration anyway due to the use of --${CommandLineOptions.ignoreExceptionsFlag}.

To see exception details, re-run without --${CommandLineOptions.ignoreExceptionsFlag}.
''');
    } else {
      if (_hasAnalysisErrors) {
        logger.stderr('''
Aborting migration due to an exception.  This may be due to a bug in
the migration tool, or it may be due to errors in the source code
being migrated.  If possible, try to fix errors in the source code and
re-try migrating.  If that doesn't work, consider filing a bug report
at:
''');
      } else {
        logger.stderr('''
Aborting migration due to an exception.  This most likely is due to a
bug in the migration tool.  Please consider filing a bug report at:
''');
      }
      logger.stderr('https://github.com/dart-lang/sdk/issues/new');
      var sdkVersion = Platform.version.split(' ')[0];
      logger.stderr('''
Please include the SDK version ($sdkVersion) in your bug report.

To attempt to perform migration anyway, you may re-run with
--${CommandLineOptions.ignoreExceptionsFlag}.

Exception details:
''');
      logger.stderr(detail);
      throw MigrationExit(1);
    }
  }

  @override
  void onFatalError(String detail) {
    logger.stderr(detail);
    throw MigrationExit(1);
  }

  @override
  void onMessage(String detail) {
    logger.stdout(detail);
  }

  /// Runs the full migration process.
  ///
  /// If something goes wrong, a message is printed using the logger configured
  /// in the constructor, and [MigrationExit] is thrown.
  Future<void> run() async {
    logger.stdout('Migrating ${options.directory}');
    logger.stdout('');

    logger.stdout(MigrateCommand.migrationGuideLink);
    logger.stdout('');

    if (hasMultipleAnalysisContext) {
      logger.stdout('Note: more than one project found; migrating the '
          'top-level project.');
      logger.stdout('');
    }

    DriverBasedAnalysisContext context = analysisContext;

    NonNullableFix nonNullableFix;

    logger.stdout(ansi.emphasized('Analyzing project...'));
    _fixCodeProcessor = _FixCodeProcessor(context, this);
    _dartFixListener =
        DartFixListener(DriverProviderImpl(resourceProvider, context), this);
    nonNullableFix = createNonNullableFix(_dartFixListener, resourceProvider,
        _fixCodeProcessor.getLineInfo, computeBindAddress(),
        included: [options.directory],
        preferredPort: options.previewPort,
        summaryPath: options.summary,
        sdkPath: options.sdkPath);
    nonNullableFix.rerunFunction = _rerunFunction;
    _fixCodeProcessor.registerCodeTask(nonNullableFix);

    try {
      var analysisResult = await _fixCodeProcessor.runFirstPhase();

      if (analysisResult.hasErrors) {
        _logErrors(analysisResult);
        if (!options.ignoreErrors) {
          throw MigrationExit(1);
        }
      } else if (analysisResult.allSourcesAlreadyMigrated) {
        _logAlreadyMigrated();
        throw MigrationExit(0);
      } else {
        logger.stdout('No analysis issues found.');
      }
    } on ExperimentStatusException catch (e) {
      logger.stdout(e.toString());
      final sdkPathVar = cli._environmentVariables['SDK_PATH'];
      if (sdkPathVar != null) {
        logger.stdout('$sdkPathEnvironmentVariableSet: $sdkPathVar');
      }
      throw MigrationExit(1);
    }

    logger.stdout('');
    logger.stdout(ansi.emphasized('Generating migration suggestions...'));
    var previewUrls = (await _fixCodeProcessor.runLaterPhases()).previewUrls;

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
      return;
    }

    if (options.webPreview) {
      assert(previewUrls.length == 1,
          'Got unexpected extra preview URLs from server');

      var url = previewUrls.single;
      // TODO(#41809): Open a browser automatically.
      logger.stdout('''
View the migration suggestions by visiting:

  ${ansi.emphasized(url)}

Use this interactive web view to review, improve, or apply the results.
When finished with the preview, hit ctrl-c to terminate this process.

If you make edits outside of the web view (in your IDE), use the 'Rerun from
sources' action.

''');

      // Block until sigint (ctrl-c).
      await blockUntilSignalInterrupt();
      nonNullableFix.shutdownServer();
    } else {
      logger.stdout(ansi.emphasized('Diff of changes:'));

      _displayChangeDiff(_dartFixListener);

      logger.stdout('');
      logger.stdout('To apply these changes, re-run the tool with '
          '--${CommandLineOptions.applyChangesFlag}.');
    }
  }

  /// Determines whether a migrated version of the file at [path] should be
  /// output by the migration too.  May be overridden by a derived class.
  ///
  /// This method should return `false` for files that are being considered by
  /// the migration tool for information only (for example generated files, or
  /// usages of the code-to-be-migrated by one one of its clients).
  ///
  /// By default returns `true` if the file is contained within the context
  /// root.  This means that if a client overrides [computePathsToProcess] to
  /// return additional paths that aren't inside the user's project, but doesn't
  /// override this method, then those additional paths will be analyzed but not
  /// migrated.
  bool shouldBeMigrated(DriverBasedAnalysisContext context, String path) {
    return context.contextRoot.isAnalyzed(path);
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
    applyHook();
  }

  void _displayChangeDiff(DartFixListener migrationResults) {
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

  void _logAlreadyMigrated() {
    logger.stdout(migratedAlready);
  }

  void _logErrors(AnalysisResult analysisResult) {
    logger.stdout('');

    var issueCount = analysisResult.errors.length;
    logger.stdout(
        '$issueCount analysis ${_pluralize(issueCount, 'issue')} found:');

    _IssueRenderer renderer =
        _IssueRenderer(logger, options.directory, pathContext, lineInfo);
    for (AnalysisError error in analysisResult.errors) {
      renderer.render(error);
    }
    logger.stdout('');
    _hasAnalysisErrors = true;

    if (options.ignoreErrors) {
      logger.stdout('Note: analysis errors will result in erroneous migration '
          'suggestions.');
      logger.stdout('Continuing with migration suggestions due to the use of '
          '--${CommandLineOptions.ignoreErrorsFlag}.');
    } else {
      // Fail with how to continue.
      logger.stdout("The migration tool didn't start, due to analysis errors.");
      logger.stdout('');
      if (analysisResult.hasImportErrors) {
        logger.stdout('''
The following steps might fix your problem:
1. Run `dart pub get`.
2. Try running `dart migrate` again.
''');
      } else if (analysisResult.allSourcesAlreadyMigrated) {
        logger.stdout('''
The following steps might fix your problem:
1. Set the lower SDK constraint (in pubspec.yaml) to a version before 2.12.
2. Run `dart pub get`.
3. Try running `dart migrate` again.
''');
      } else {
        const ignoreErrors = CommandLineOptions.ignoreErrorsFlag;
        logger.stdout('''
We recommend fixing the analysis issues before running `dart migrate`.
Alternatively, you can run `dart migrate --$ignoreErrors`, but you might
get erroneous migration suggestions.
''');
      }
      logger.stdout(
          'More information: https://dart.dev/go/null-safety-migration');
    }
  }

  Future<MigrationState> _rerunFunction() async {
    logger.stdout(ansi.emphasized('Re-analyzing project...'));

    _dartFixListener.reset();
    _fixCodeProcessor.prepareToRerun();
    var analysisResult = await _fixCodeProcessor.runFirstPhase();
    if (analysisResult.hasErrors) {
      _logErrors(analysisResult);
      return MigrationState(
          _fixCodeProcessor._task.migration,
          _fixCodeProcessor._task.includedRoot,
          _dartFixListener,
          _fixCodeProcessor._task.instrumentationListener,
          {},
          analysisResult);
    } else if (analysisResult.allSourcesAlreadyMigrated) {
      _logAlreadyMigrated();
      return MigrationState(
          _fixCodeProcessor._task.migration,
          _fixCodeProcessor._task.includedRoot,
          _dartFixListener,
          _fixCodeProcessor._task.instrumentationListener,
          {},
          analysisResult);
    } else {
      logger.stdout(ansi.emphasized('Re-generating migration suggestions...'));
      return await _fixCodeProcessor.runLaterPhases();
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

  static Map<int, List<AtomicEdit>> _sourceEditsToAtomicEdits(
      List<SourceEdit> edits) {
    return {
      for (var edit in edits)
        edit.offset: [AtomicEdit.replace(edit.length, edit.replacement)]
    };
  }
}

/// Exception thrown by [MigrationCli] if the client should exit.
class MigrationExit {
  /// The exit code that the client should set.
  final int exitCode;

  MigrationExit(this.exitCode);
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
  static const numPhases = 3;

  final DriverBasedAnalysisContext context;

  /// The task used to migrate to NNBD.
  NonNullableFix _task;

  Set<String> pathsToProcess;

  ProgressBar _progressBar;

  final MigrationCliRunner _migrationCli;

  _FixCodeProcessor(this.context, this._migrationCli)
      : pathsToProcess = _migrationCli.computePathsToProcess(context);

  bool get isPreviewServerRunnning => _task?.isPreviewServerRunning ?? false;

  LineInfo getLineInfo(String path) =>
      context.currentSession.getFile(path).lineInfo;

  void prepareToRerun() {
    var driver = context.driver;
    pathsToProcess = _migrationCli.computePathsToProcess(context);
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
              if (!pathsProcessed.contains(unit.path)) {
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

  Future<AnalysisResult> runFirstPhase() async {
    var analysisErrors = <AnalysisError>[];

    // All tasks should be registered; [numPhases] should be finalized.
    _progressBar = ProgressBar(_migrationCli.logger, pathsToProcess.length);

    // Process each source file.
    bool allSourcesAlreadyMigrated = true;
    await processResources((ResolvedUnitResult result) async {
      if (!result.unit.featureSet.isEnabled(Feature.non_nullable)) {
        allSourcesAlreadyMigrated = false;
      }
      _progressBar.tick();
      List<AnalysisError> errors = result.errors
          .where((error) => error.severity == Severity.error)
          .toList();
      if (errors.isNotEmpty) {
        analysisErrors.addAll(errors);
        _migrationCli.lineInfo[result.path] = result.lineInfo;
      }
      if (_migrationCli.options.ignoreErrors || analysisErrors.isEmpty) {
        await _task.prepareUnit(result);
      }
    });

    var unmigratedDependencies = _task.migration.unmigratedDependencies;
    if (unmigratedDependencies.isNotEmpty) {
      if (_migrationCli.options.skipImportCheck) {
        _migrationCli.logger.stdout(unmigratedDependenciesWarning);
      } else {
        throw ExperimentStatusException.unmigratedDependencies(
            unmigratedDependencies);
      }
    }

    return AnalysisResult(
        analysisErrors,
        _migrationCli.lineInfo,
        _migrationCli.pathContext,
        _migrationCli.options.directory,
        allSourcesAlreadyMigrated);
  }

  Future<MigrationState> runLaterPhases() async {
    _progressBar = ProgressBar(
        _migrationCli.logger, pathsToProcess.length * (numPhases - 1));

    await processResources((ResolvedUnitResult result) async {
      _progressBar.tick();
      await _task.processUnit(result);
    });
    await processResources((ResolvedUnitResult result) async {
      _progressBar.tick();
      if (_migrationCli.shouldBeMigrated(context, result.path)) {
        await _task.finalizeUnit(result);
      }
    });
    _progressBar.complete();
    _migrationCli.logger.stdout(_migrationCli.ansi
        .emphasized('Compiling instrumentation information...'));
    var state = await _task.finish();
    _task.processPackage(context.contextRoot.root, state.neededPackages);
    if (_migrationCli.options.webPreview) {
      await _task.startPreviewServer(state, _migrationCli.applyHook);
    }
    state.previewUrls = _task.previewUrls;

    return state;
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
      '  ${ansi.error(issue.severity.name)} • '
      '${ansi.emphasized(_removePeriod(issue.message))} '
      'at ${pathContext.relative(issue.source.fullName, from: rootDirectory)}'
      ':${location.lineNumber}:${location.columnNumber} '
      '• (${issue.errorCode.name.toLowerCase()})',
    );
  }
}

extension on Severity {
  /// Returns the simple name of the Severity, as a String.
  String get name {
    switch (this) {
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
