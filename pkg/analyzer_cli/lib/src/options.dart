// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/driver.dart';
import 'package:args/args.dart';
import 'package:telemetry/telemetry.dart' as telemetry;

const _binaryName = 'dartanalyzer';

/// Shared exit handler.
///
/// *Visible for testing.*
ExitHandler exitHandler = exit;

T cast<T>(dynamic value) => value as T;

/// Print the given [message] to stderr and exit with the given [exitCode].
void printAndFail(String message, {int exitCode: 15}) {
  errorSink.writeln(message);
  exitHandler(exitCode);
}

/// Exit handler.
///
/// *Visible for testing.*
typedef void ExitHandler(int code);

/// Analyzer commandline configuration options.
class CommandLineOptions {
  /// The path to output analysis results when in build mode.
  final String buildAnalysisOutput;

  /// Whether to use build mode.
  final bool buildMode;

  /// Whether to use build mode as a Bazel persistent worker.
  final bool buildModePersistentWorker;

  /// List of summary file paths to use in build mode.
  final List<String> buildSummaryInputs;

  /// List of unlinked summary file paths to use in build mode.
  final List<String> buildSummaryUnlinkedInputs;

  /// Whether to skip analysis when creating summaries in build mode.
  final bool buildSummaryOnly;

  /// Whether to only produce unlinked summaries instead of linked summaries.
  /// Must be used in combination with `buildSummaryOnly`.
  final bool buildSummaryOnlyUnlinked;

  /// The path to output the summary when creating summaries in build mode.
  final String buildSummaryOutput;

  /// The path to output the semantic-only summary when creating summaries in
  /// build mode.
  final String buildSummaryOutputSemantic;

  /// Whether to suppress a nonzero exit code in build mode.
  final bool buildSuppressExitCode;

  /// The options defining the context in which analysis is performed.
  final ContextBuilderOptions contextBuilderOptions;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// The path to the dart SDK summary file.
  final String dartSdkSummaryPath;

  /// Whether to disable cache flushing.  This option can improve analysis
  /// speed at the expense of memory usage.  It may also be useful for working
  /// around bugs.
  final bool disableCacheFlushing;

  /// Whether to report hints
  final bool disableHints;

  /// Whether to display version information
  final bool displayVersion;

  /// A list of the names of the experiments that are to be enabled.
  final List<String> enabledExperiments;

  /// Whether to ignore unrecognized flags
  final bool ignoreUnrecognizedFlags;

  /// Whether to report lints
  final bool lints;

  /// Whether to log additional analysis messages and exceptions
  final bool log;

  /// Whether to use machine format for error display
  final bool machineFormat;

  /// The path to a file to write a performance log.
  /// (Or null if not enabled.)
  final String perfReport;

  /// Whether to enable parsing via the Fasta parser.
  final bool useFastaParser;

  /// Batch mode (for unit testing)
  final bool batchMode;

  /// Whether to show package: warnings
  final bool showPackageWarnings;

  /// If not null, show package: warnings only for matching packages.
  final String showPackageWarningsPrefix;

  /// Whether to show SDK warnings
  final bool showSdkWarnings;

  /// The source files to analyze
  List<String> _sourceFiles;

  /// Whether to treat warnings as fatal
  final bool warningsAreFatal;

  /// Whether to treat info level items as fatal
  final bool infosAreFatal;

  /// Whether to use strong static checking.
  ///
  /// This flag is deprecated and hard-coded to `true`.
  final bool strongMode = true;

  /// Whether to treat lints as fatal
  // TODO(devoncarew): Deprecate and remove this flag.
  final bool lintsAreFatal;

  /// Emit output in a verbose mode.
  final bool verbose;

  /// Use ANSI color codes for output.
  final bool color;

  /// Whether we should analyze the given source for the purposes of training a
  /// Dart analyzer snapshot.
  final bool trainSnapshot;

  /// Path to a file to dump summary dependency information to for any given
  /// build.
  final String summaryDepsOutput;

  /// Initialize options from the given parsed [args].
  CommandLineOptions._fromArgs(ArgResults args)
      : buildAnalysisOutput = cast(args['build-analysis-output']),
        buildMode = cast(args['build-mode']),
        buildModePersistentWorker = cast(args['persistent_worker']),
        buildSummaryInputs =
            (args['build-summary-input'] as List).cast<String>(),
        buildSummaryUnlinkedInputs =
            (args['build-summary-unlinked-input'] as List).cast<String>(),
        buildSummaryOnly = cast(args['build-summary-only']),
        buildSummaryOnlyUnlinked = cast(args['build-summary-only-unlinked']),
        buildSummaryOutput = cast(args['build-summary-output']),
        buildSummaryOutputSemantic =
            cast(args['build-summary-output-semantic']),
        buildSuppressExitCode = cast(args['build-suppress-exit-code']),
        contextBuilderOptions = createContextBuilderOptions(args),
        dartSdkPath = cast(args['dart-sdk']),
        dartSdkSummaryPath = cast(args['dart-sdk-summary']),
        disableCacheFlushing = cast(args['disable-cache-flushing']),
        disableHints = cast(args['no-hints']),
        displayVersion = cast(args['version']),
        enabledExperiments =
            cast(args['enable-experiment'] ?? const <String>[]),
        ignoreUnrecognizedFlags = cast(args['ignore-unrecognized-flags']),
        lints = cast(args[lintsFlag]),
        log = cast(args['log']),
        machineFormat = args['format'] == 'machine',
        perfReport = cast(args['x-perf-report']),
        useFastaParser = cast(args['use-fasta-parser']),
        batchMode = cast(args['batch']),
        showPackageWarnings = cast(args['show-package-warnings']) ||
            cast(args['package-warnings']) ||
            args['x-package-warnings-prefix'] != null,
        showPackageWarningsPrefix = cast(args['x-package-warnings-prefix']),
        showSdkWarnings = cast(args['sdk-warnings']),
        _sourceFiles = args.rest,
        infosAreFatal = cast(args['fatal-infos']) || cast(args['fatal-hints']),
        warningsAreFatal = cast(args['fatal-warnings']),
        lintsAreFatal = cast(args['fatal-lints']),
        trainSnapshot = cast(args['train-snapshot']),
        verbose = cast(args['verbose']),
        color = cast(args['color']),
        summaryDepsOutput = cast(args['summary-deps-output']);

  /// The path to an analysis options file
  String get analysisOptionsFile =>
      contextBuilderOptions.defaultAnalysisOptionsFilePath;

  /// A table mapping the names of defined variables to their values.
  Map<String, String> get definedVariables =>
      contextBuilderOptions.declaredVariables;

  /// The path to a `.packages` configuration file
  String get packageConfigPath => contextBuilderOptions.defaultPackageFilePath;

  /// The path to the package root
  String get packageRootPath =>
      contextBuilderOptions.defaultPackagesDirectoryPath;

  /// The source files to analyze
  List<String> get sourceFiles => _sourceFiles;

  /// Replace the sourceFiles parsed from the command line.
  void rewriteSourceFiles(List<String> newSourceFiles) {
    _sourceFiles = newSourceFiles;
  }

  /// Parse [args] into [CommandLineOptions] describing the specified
  /// analyzer options. In case of a format error, calls [printAndFail], which
  /// by default prints an error message to stderr and exits.
  static CommandLineOptions parse(List<String> args,
      {printAndFail(String msg) = printAndFail}) {
    CommandLineOptions options = _parse(args);

    /// Only happens in testing.
    if (options == null) {
      return null;
    }

    // Check SDK.
    if (!options.buildModePersistentWorker) {
      // Infer if unspecified.
      options.dartSdkPath ??= getSdkPath(args);

      String sdkPath = options.dartSdkPath;

      // Check that SDK is specified.
      if (sdkPath == null) {
        printAndFail('No Dart SDK found.');
        return null; // Only reachable in testing.
      }
      // Check that SDK is existing directory.
      if (!(new Directory(sdkPath)).existsSync()) {
        printAndFail('Invalid Dart SDK path: $sdkPath');
        return null; // Only reachable in testing.
      }
    }

    // Check package config.
    {
      if (options.packageRootPath != null &&
          options.packageConfigPath != null) {
        printAndFail("Cannot specify both '--package-root' and '--packages.");
        return null; // Only reachable in testing.
      }
    }

    // Build mode.
    if (options.buildModePersistentWorker && !options.buildMode) {
      printAndFail('The option --persisten_worker can be used only '
          'together with --build-mode.');
      return null; // Only reachable in testing.
    }

    if (options.buildSummaryOnlyUnlinked) {
      printAndFail('The option --build-summary-only-unlinked is deprecated.');
      return null; // Only reachable in testing.
    }

    return options;
  }

  static String _getVersion() {
    try {
      // This is relative to bin/snapshot, so ../..
      String versionPath =
          Platform.script.resolve('../../version').toFilePath();
      File versionFile = new File(versionPath);
      return versionFile.readAsStringSync().trim();
    } catch (_) {
      // This happens when the script is not running in the context of an SDK.
      return "<unknown>";
    }
  }

  static CommandLineOptions _parse(List<String> args) {
    args = preprocessArgs(PhysicalResourceProvider.INSTANCE, args);

    bool verbose = args.contains('-v') || args.contains('--verbose');
    bool hide = !verbose;

    ArgParser parser = new ArgParser(allowTrailingOptions: true);

    if (!hide) {
      parser.addSeparator('General options:');
    }

    // TODO(devoncarew): This defines some hidden flags, which would be better
    // defined with the rest of the hidden flags below (to group well with the
    // other flags).
    defineAnalysisArguments(parser, hide: hide);

    parser
      ..addOption('format',
          help: 'Specifies the format in which errors are displayed; the only '
              'currently allowed value is \'machine\'.')
      ..addFlag('version',
          help: 'Print the analyzer version.',
          defaultsTo: false,
          negatable: false)
      ..addMultiOption('enable-experiment',
          help:
              'Enable one or more experimental features. If multiple features '
              'are being added, they should be comma separated.',
          splitCommas: true)
      ..addFlag('no-hints',
          help: 'Do not show hint results.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('fatal-infos',
          help: 'Treat infos as fatal.', defaultsTo: false, negatable: false)
      ..addFlag('fatal-warnings',
          help: 'Treat non-type warnings as fatal.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('help',
          abbr: 'h',
          help:
              'Display this help message. Add --verbose to show hidden options.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('verbose',
          abbr: 'v',
          defaultsTo: false,
          help: 'Verbose output.',
          negatable: false);

    parser.addFlag('analytics',
        help: 'Enable or disable sending analytics information to Google.',
        hide: !telemetry.SHOW_ANALYTICS_UI);

    // Build mode options.
    if (!hide) {
      parser.addSeparator('Build mode flags:');
    }

    parser
      ..addFlag('persistent_worker',
          help: 'Enable Bazel persistent worker mode.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addOption('build-analysis-output',
          help: 'Specifies the path to the file where analysis results should '
              'be written.',
          hide: hide)
      ..addFlag('build-mode',
          help: 'Run in build mode; '
              'this is used to generate analyzer summaries for build systems.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addMultiOption('build-summary-input',
          help: 'Path to a linked summary file that contains information from '
              'a previous analysis run; may be specified multiple times.',
          hide: hide)
      ..addMultiOption('build-summary-unlinked-input',
          help: 'Path to an unlinked summary file that contains information '
              'from a previous analysis run; may be specified multiple times.',
          hide: hide)
      ..addOption('build-summary-output',
          help: 'Specifies the path to the file where the full summary '
              'information should be written.',
          hide: hide)
      ..addOption('build-summary-output-semantic',
          help: 'Specifies the path to the file where the semantic summary '
              'information should be written.',
          hide: hide)
      ..addFlag('build-summary-only',
          help: 'Disable analysis (only generate summaries).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('build-summary-only-unlinked',
          help: 'Only output the unlinked summary.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('build-suppress-exit-code',
          help: 'Exit with code 0 even if errors are found.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('color',
          help: 'Use ansi colors when printing messages.',
          defaultsTo: ansi.terminalSupportsAnsi(),
          hide: hide)
      ..addOption('summary-deps-output',
          help: 'Path to a file to dump summary dependency info to.',
          hide: hide);

    // Hidden flags.
    if (!hide) {
      parser.addSeparator('Less frequently used flags:');
    }

    parser
      ..addFlag('batch',
          help: 'Read commands from standard input (for testing).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag(ignoreUnrecognizedFlagsFlag,
          help: 'Ignore unrecognized command line flags.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('disable-cache-flushing', defaultsTo: false, hide: hide)
      ..addOption('x-perf-report',
          help: 'Writes a performance report to the given file (experimental).',
          hide: hide)
      ..addOption('x-package-warnings-prefix',
          help:
              'Show warnings from package: imports that match the given prefix (deprecated).',
          hide: hide)
      ..addFlag('enable-conditional-directives',
          help:
              'deprecated -- Enable support for conditional directives (DEP 40).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('show-package-warnings',
          help: 'Show warnings from package: imports (deprecated).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('sdk-warnings',
          help: 'Show warnings from SDK imports (deprecated).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('log',
          help: 'Log additional messages and exceptions.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('enable_type_checks',
          help: 'Check types in constant evaluation (deprecated).',
          defaultsTo: false,
          negatable: false,
          hide: true)
      // TODO(brianwilkerson) Remove the following option after we're sure that
      // it's no longer being used.
      ..addFlag('enable-assert-initializers',
          help:
              'Enable parsing of asserts in constructor initializers (deprecated).',
          defaultsTo: null,
          negatable: false,
          hide: hide)
      ..addFlag('use-analysis-driver-memory-byte-store',
          help: 'Use memory byte store, not the file system cache.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('fatal-hints',
          help: 'Treat hints as fatal (deprecated: use --fatal-infos).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('fatal-lints',
          help: 'Treat lints as fatal.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addFlag('package-warnings',
          help: 'Show warnings from package: imports (deprecated).',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addMultiOption('url-mapping',
          help: '--url-mapping=libraryUri,/path/to/library.dart directs the '
              'analyzer to use "library.dart" as the source for an import '
              'of "libraryUri".',
          splitCommas: false,
          hide: hide)
      ..addFlag('use-fasta-parser',
          help: 'Whether to enable parsing via the Fasta parser.',
          defaultsTo: true,
          hide: hide)
      ..addFlag('preview-dart-2',
          help: 'Enable the Dart 2.0 preview.',
          defaultsTo: true,
          hide: hide,
          negatable: true)
      ..addFlag('train-snapshot',
          help: "Analyze the given source for the purposes of training a "
              "dartanalyzer snapshot.",
          hide: hide,
          negatable: false);

    try {
      if (args.contains('--$ignoreUnrecognizedFlagsFlag')) {
        args = filterUnknownArguments(args, parser);
      }
      ArgResults results = parser.parse(args);

      // Persistent worker.
      if (args.contains('--persistent_worker')) {
        bool hasBuildMode = args.contains('--build-mode');
        bool onlyDartSdkArg = args.length == 2 ||
            (args.length == 3 && args.any((a) => a.startsWith('--dart-sdk'))) ||
            (args.length == 4 && args.contains('--dart-sdk'));
        if (!(hasBuildMode && onlyDartSdkArg)) {
          printAndFail('The --persistent_worker flag should be used with and '
              'only with the --build-mode flag, and possibly the --dart-sdk '
              'option. Got: $args');
          return null; // Only reachable in testing.
        }
        return new CommandLineOptions._fromArgs(results);
      }

      // Help requests.
      if (cast(results['help'])) {
        _showUsage(parser, analytics, fromHelp: true);
        exitHandler(0);
        return null; // Only reachable in testing.
      }

      // Enable / disable analytics.
      if (telemetry.SHOW_ANALYTICS_UI) {
        if (results.wasParsed('analytics')) {
          analytics.enabled = cast(results['analytics']);
          outSink.writeln(
              telemetry.createAnalyticsStatusMessage(analytics.enabled));
          exitHandler(0);
          return null; // Only reachable in testing.
        }
      }

      // Batch mode and input files.
      if (cast(results['batch'])) {
        if (results.rest.isNotEmpty) {
          errorSink.writeln('No source files expected in the batch mode.');
          _showUsage(parser, analytics);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      } else if (cast(results['persistent_worker'])) {
        if (results.rest.isNotEmpty) {
          errorSink.writeln(
              'No source files expected in the persistent worker mode.');
          _showUsage(parser, analytics);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      } else if (cast(results['version'])) {
        outSink.writeln('$_binaryName version ${_getVersion()}');
        exitHandler(0);
        return null; // Only reachable in testing.
      } else {
        if (results.rest.isEmpty && !cast<bool>(results['build-mode'])) {
          _showUsage(parser, analytics, fromHelp: true);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      }

      if (results.wasParsed('strong')) {
        errorSink.writeln(
            'Note: the --strong flag is deprecated and will be removed in an '
            'future release.\n');
      }
      if (results.wasParsed('enable-experiment')) {
        List<String> names =
            (results['enable-experiment'] as List).cast<String>().toList();
        bool errorFound = false;
        for (var validationResult in validateFlags(names)) {
          if (validationResult.isError) {
            errorFound = true;
          }
          var kind = validationResult.isError ? 'ERROR' : 'WARNING';
          errorSink.writeln('$kind: ${validationResult.message}');
        }
        if (errorFound) {
          _showUsage(parser, null);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      }

      return new CommandLineOptions._fromArgs(results);
    } on FormatException catch (e) {
      errorSink.writeln(e.message);
      _showUsage(parser, null);
      exitHandler(15);
      return null; // Only reachable in testing.
    }
  }

  static _showUsage(ArgParser parser, telemetry.Analytics analytics,
      {bool fromHelp: false}) {
    void printAnalyticsInfo() {
      if (!telemetry.SHOW_ANALYTICS_UI) {
        return;
      }

      if (fromHelp) {
        errorSink.writeln('');
        errorSink.writeln(telemetry.analyticsNotice);
      }

      if (analytics != null) {
        errorSink.writeln('');
        errorSink.writeln(telemetry.createAnalyticsStatusMessage(
            analytics.enabled,
            command: 'analytics'));
      }
    }

    errorSink.writeln(
        'Usage: $_binaryName [options...] <directory or list of files>');

    // If it's our first run, we display the analytics info more prominently.
    if (analytics != null && analytics.firstRun) {
      printAnalyticsInfo();
    }

    errorSink.writeln('');
    errorSink.writeln(parser.usage);

    if (analytics != null && !analytics.firstRun) {
      printAnalyticsInfo();
    }

    errorSink.writeln('');
    errorSink.writeln('''
Run "dartanalyzer -h -v" for verbose help output, including less commonly used options.
For more information, see https://www.dartlang.org/tools/analyzer.\n''');
  }
}
