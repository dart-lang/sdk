// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/driver.dart';
import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';

const _analysisOptionsFileOption = 'options';
const _binaryName = 'dartanalyzer';
const _defaultLanguageVersionOption = 'default-language-version';
const _defineVariableOption = 'D';
const _enableExperimentOption = 'enable-experiment';
const _enableInitializingFormalAccessFlag = 'initializing-formal-access';
const _ignoreUnrecognizedFlagsFlag = 'ignore-unrecognized-flags';
const _implicitCastsFlag = 'implicit-casts';
const _lintsFlag = 'lints';
const _noImplicitDynamicFlag = 'no-implicit-dynamic';
const _packagesOption = 'packages';
const _sdkPathOption = 'dart-sdk';
const _sdkSummaryPathOption = 'dart-sdk-summary';

/// Shared exit handler.
///
/// *Visible for testing.*
ExitHandler exitHandler = io.exit;

T cast<T>(dynamic value) => value as T;

/// Print the given [message] to stderr and exit with the given [exitCode].
void printAndFail(String message, {int exitCode = 15}) {
  errorSink.writeln(message);
  exitHandler(exitCode);
}

/// Exit handler.
///
/// *Visible for testing.*
typedef ExitHandler = void Function(int code);

/// Analyzer commandline configuration options.
class CommandLineOptions {
  final ArgResults _argResults;

  /// The path to output analysis results when in build mode.
  final String buildAnalysisOutput;

  /// Whether to use build mode.
  final bool buildMode;

  /// Whether to use build mode as a Bazel persistent worker.
  final bool buildModePersistentWorker;

  /// List of summary file paths to use in build mode.
  final List<String> buildSummaryInputs;

  /// Whether to skip analysis when creating summaries in build mode.
  final bool buildSummaryOnly;

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

  /// Whether to disable cache flushing. This option can improve analysis
  /// speed at the expense of memory usage. It may also be useful for working
  /// around bugs.
  final bool disableCacheFlushing;

  /// Whether to report hints
  final bool disableHints;

  /// Whether to display version information
  final bool displayVersion;

  /// Whether to ignore unrecognized flags
  final bool ignoreUnrecognizedFlags;

  /// Whether to log additional analysis messages and exceptions
  final bool log;

  /// Whether to use machine format for error display
  final bool machineFormat;

  /// The path to a file to write a performance log.
  /// (Or null if not enabled.)
  final String perfReport;

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
  CommandLineOptions._fromArgs(
    ResourceProvider resourceProvider,
    ArgResults args,
  )   : _argResults = args,
        buildAnalysisOutput = cast(args['build-analysis-output']),
        buildMode = cast(args['build-mode']),
        buildModePersistentWorker = cast(args['persistent_worker']),
        buildSummaryInputs =
            (args['build-summary-input'] as List).cast<String>(),
        buildSummaryOnly = cast(args['build-summary-only']),
        buildSummaryOutput = cast(args['build-summary-output']),
        buildSummaryOutputSemantic =
            cast(args['build-summary-output-semantic']),
        buildSuppressExitCode = cast(args['build-suppress-exit-code']),
        contextBuilderOptions = _createContextBuilderOptions(
          resourceProvider,
          args,
        ),
        dartSdkPath = cast(args[_sdkPathOption]),
        dartSdkSummaryPath = cast(args[_sdkSummaryPathOption]),
        disableCacheFlushing = cast(args['disable-cache-flushing']),
        disableHints = cast(args['no-hints']),
        displayVersion = cast(args['version']),
        ignoreUnrecognizedFlags = cast(args[_ignoreUnrecognizedFlagsFlag]),
        log = cast(args['log']),
        machineFormat = args['format'] == 'machine',
        perfReport = cast(args['x-perf-report']),
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

  /// The default language version for files that are not in a package.
  /// (Or null if no default language version to force.)
  String get defaultLanguageVersion {
    return cast(_argResults[_defaultLanguageVersionOption]);
  }

  /// A table mapping the names of defined variables to their values.
  Map<String, String> get definedVariables =>
      contextBuilderOptions.declaredVariables;

  /// A list of the names of the experiments that are to be enabled.
  List<String> get enabledExperiments {
    return cast(_argResults[_enableExperimentOption]);
  }

  bool get implicitCasts => _argResults[_implicitCastsFlag] as bool;

  bool get lints => _argResults[_lintsFlag] as bool;

  bool get noImplicitDynamic => _argResults[_noImplicitDynamicFlag] as bool;

  /// The path to a `.packages` configuration file
  String get packageConfigPath => contextBuilderOptions.defaultPackageFilePath;

  /// The source files to analyze
  List<String> get sourceFiles => _sourceFiles;

  /// Replace the sourceFiles parsed from the command line.
  void rewriteSourceFiles(List<String> newSourceFiles) {
    _sourceFiles = newSourceFiles;
  }

  /// Update the [analysisOptions] with flags that the user specified
  /// explicitly. The [analysisOptions] are usually loaded from one of
  /// `analysis_options.yaml` files, possibly with includes. We consider
  /// flags that the user specified as command line options more important,
  /// so override the corresponding options.
  void updateAnalysisOptions(AnalysisOptionsImpl analysisOptions) {
    var defaultLanguageVersion = this.defaultLanguageVersion;
    if (defaultLanguageVersion != null) {
      var nonPackageLanguageVersion =
          Version.parse('$defaultLanguageVersion.0');
      analysisOptions.nonPackageLanguageVersion = nonPackageLanguageVersion;
      analysisOptions.nonPackageFeatureSet = FeatureSet.latestLanguageVersion()
          .restrictToVersion(nonPackageLanguageVersion);
    }

    var enabledExperiments = this.enabledExperiments;
    if (enabledExperiments.isNotEmpty) {
      analysisOptions.contextFeatures = FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: ExperimentStatus.currentVersion,
        flags: enabledExperiments,
      );
    }

    var implicitCasts = this.implicitCasts;
    if (implicitCasts != null) {
      analysisOptions.implicitCasts = implicitCasts;
    }

    var lints = this.lints;
    if (lints != null) {
      analysisOptions.lint = lints;
    }

    var noImplicitDynamic = this.noImplicitDynamic;
    if (noImplicitDynamic != null) {
      analysisOptions.implicitDynamic = !noImplicitDynamic;
    }
  }

  /// Return a list of command-line arguments containing all of the given [args]
  /// that are defined by the given [parser]. An argument is considered to be
  /// defined by the parser if
  /// - it starts with '--' and the rest of the argument (minus any value
  ///   introduced by '=') is the name of a known option,
  /// - it starts with '-' and the rest of the argument (minus any value
  ///   introduced by '=') is the name of a known abbreviation, or
  /// - it starts with something other than '--' or '-'.
  ///
  /// This function allows command-line tools to implement the
  /// '--ignore-unrecognized-flags' option.
  static List<String> filterUnknownArguments(
      List<String> args, ArgParser parser) {
    var knownOptions = <String>{};
    var knownAbbreviations = <String>{};
    parser.options.forEach((String name, Option option) {
      knownOptions.add(name);
      var abbreviation = option.abbr;
      if (abbreviation != null) {
        knownAbbreviations.add(abbreviation);
      }
      if (option.negatable ?? false) {
        knownOptions.add('no-$name');
      }
    });
    String optionName(int prefixLength, String argument) {
      var equalsOffset = argument.lastIndexOf('=');
      if (equalsOffset < 0) {
        return argument.substring(prefixLength);
      }
      return argument.substring(prefixLength, equalsOffset);
    }

    var filtered = <String>[];
    for (var i = 0; i < args.length; i++) {
      var argument = args[i];
      if (argument.startsWith('--') && argument.length > 2) {
        if (knownOptions.contains(optionName(2, argument))) {
          filtered.add(argument);
        }
      } else if (argument.startsWith('-D') && argument.indexOf('=') > 0) {
        filtered.add(argument);
      }
      if (argument.startsWith('-') && argument.length > 1) {
        if (knownAbbreviations.contains(optionName(1, argument))) {
          filtered.add(argument);
        }
      } else {
        filtered.add(argument);
      }
    }
    return filtered;
  }

  /// Parse [args] into [CommandLineOptions] describing the specified
  /// analyzer options. In case of a format error, calls [printAndFail], which
  /// by default prints an error message to stderr and exits.
  static CommandLineOptions parse(
      ResourceProvider resourceProvider, List<String> args,
      {void Function(String msg) printAndFail = printAndFail}) {
    var options = _parse(resourceProvider, args);

    /// Only happens in testing.
    if (options == null) {
      return null;
    }

    // Check SDK.
    if (!options.buildModePersistentWorker) {
      var sdkPath = options.dartSdkPath;

      // Check that SDK is existing directory.
      if (sdkPath != null) {
        if (!(io.Directory(sdkPath)).existsSync()) {
          printAndFail('Invalid Dart SDK path: $sdkPath');
          return null; // Only reachable in testing.
        }
      }

      // Infer if unspecified.
      sdkPath ??= getSdkPath(args);

      var pathContext = resourceProvider.pathContext;
      options.dartSdkPath = file_paths.absoluteNormalized(pathContext, sdkPath);
    }

    // Build mode.
    if (options.buildMode) {
      if (options.dartSdkSummaryPath == null) {
        // It is OK to not specify when persistent worker.
        // We will be given another set of options with each request.
        if (!options.buildModePersistentWorker) {
          printAndFail(
            'The option --build-mode also requires --dart-sdk-summary '
            'to be specified.',
          );
          return null; // Only reachable in testing.
        }
      }
    } else {
      if (options.buildModePersistentWorker) {
        printAndFail(
          'The option --persistent_worker can be used only '
          'together with --build-mode.',
        );
        return null; // Only reachable in testing.
      }
    }

    return options;
  }

  /// Preprocess the given list of command line [args].
  /// If the final arg is `@file_path` (Bazel worker mode),
  /// then read in all the lines of that file and add those as args.
  /// Always returns a new modifiable list.
  static List<String> preprocessArgs(
      ResourceProvider provider, List<String> args) {
    args = List.from(args);
    if (args.isEmpty) {
      return args;
    }
    var lastArg = args.last;
    if (lastArg.startsWith('@')) {
      var argsFile = provider.getFile(lastArg.substring(1));
      try {
        args.removeLast();
        args.addAll(argsFile
            .readAsStringSync()
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n')
            .split('\n')
            .where((String line) => line.isNotEmpty));
      } on FileSystemException catch (e) {
        throw Exception('Failed to read file specified by $lastArg : $e');
      }
    }
    return args;
  }

  /// Use the command-line [args] to create a context builder options.
  static ContextBuilderOptions _createContextBuilderOptions(
    ResourceProvider resourceProvider,
    ArgResults args,
  ) {
    String absoluteNormalizedPath(String path) {
      if (path == null) {
        return null;
      }
      var pathContext = resourceProvider.pathContext;
      return pathContext.normalize(
        pathContext.absolute(path),
      );
    }

    var builderOptions = ContextBuilderOptions();

    //
    // File locations.
    //
    builderOptions.dartSdkSummaryPath = absoluteNormalizedPath(
      cast(args[_sdkSummaryPathOption]),
    );
    builderOptions.defaultAnalysisOptionsFilePath = absoluteNormalizedPath(
      cast(args[_analysisOptionsFileOption]),
    );
    builderOptions.defaultPackageFilePath = absoluteNormalizedPath(
      cast(args[_packagesOption]),
    );
    //
    // Declared variables.
    //
    var declaredVariables = <String, String>{};
    var variables = (args[_defineVariableOption] as List).cast<String>();
    for (var variable in variables) {
      var index = variable.indexOf('=');
      if (index < 0) {
        // TODO (brianwilkerson) Decide the semantics we want in this case.
        // The VM prints "No value given to -D option", then tries to load '-Dfoo'
        // as a file and dies. Unless there was nothing after the '-D', in which
        // case it prints the warning and ignores the option.
      } else {
        var name = variable.substring(0, index);
        if (name.isNotEmpty) {
          // TODO (brianwilkerson) Decide the semantics we want in the case where
          // there is no name. If there is no name, the VM tries to load a file
          // named '-D' and dies.
          declaredVariables[name] = variable.substring(index + 1);
        }
      }
    }
    builderOptions.declaredVariables = declaredVariables;

    return builderOptions;
  }

  /// Add the standard flags and options to the given [parser]. The standard flags
  /// are those that are typically used to control the way in which the code is
  /// analyzed.
  ///
  /// TODO(danrubel) Update DDC to support all the options defined in this method
  /// then remove the [ddc] named argument from this method.
  static void _defineAnalysisArguments(ArgParser parser,
      {bool hide = true, bool ddc = false}) {
    parser.addOption(_sdkPathOption,
        help: 'The path to the Dart SDK.', hide: ddc && hide);
    parser.addOption(_analysisOptionsFileOption,
        help: 'Path to an analysis options file.', hide: ddc && hide);
    parser.addFlag('strong',
        help: 'Enable strong mode (deprecated); this option is now ignored.',
        defaultsTo: true,
        hide: true,
        negatable: true);
    parser.addFlag('declaration-casts',
        negatable: true,
        help:
            'Disable declaration casts in strong mode (https://goo.gl/cTLz40)\n'
            'This option is now ignored and will be removed in a future release.',
        hide: ddc && hide);
    parser.addMultiOption(_enableExperimentOption,
        help: 'Enable one or more experimental features. If multiple features '
            'are being added, they should be comma separated.',
        splitCommas: true);
    parser.addFlag(_implicitCastsFlag,
        negatable: true,
        help: 'Disable implicit casts in strong mode (https://goo.gl/cTLz40).',
        defaultsTo: null,
        hide: ddc && hide);
    parser.addFlag(_noImplicitDynamicFlag,
        defaultsTo: null,
        negatable: false,
        help: 'Disable implicit dynamic (https://goo.gl/m0UgXD).',
        hide: ddc && hide);

    //
    // Hidden flags and options.
    //
    parser.addMultiOption(_defineVariableOption,
        abbr: 'D',
        help:
            'Define an environment declaration. For example, "-Dfoo=bar" defines '
            'an environment declaration named "foo" whose value is "bar".',
        hide: hide);
    parser.addOption(_packagesOption,
        help: 'The path to the package resolution configuration file, which '
            'supplies a mapping of package names\nto paths.',
        hide: ddc);
    parser.addOption(_sdkSummaryPathOption,
        help: 'The path to the Dart SDK summary file.', hide: hide);
    parser.addFlag(_enableInitializingFormalAccessFlag,
        help:
            'Enable support for allowing access to field formal parameters in a '
            'constructor\'s initializer list (deprecated).',
        defaultsTo: false,
        negatable: false,
        hide: hide || ddc);
    if (!ddc) {
      parser.addFlag(_lintsFlag,
          help: 'Show lint results.', defaultsTo: null, negatable: true);
    }
  }

  static String _getVersion() {
    try {
      // This is relative to bin/snapshot, so ../..
      var versionPath =
          io.Platform.script.resolve('../../version').toFilePath();
      var versionFile = io.File(versionPath);
      return versionFile.readAsStringSync().trim();
    } catch (_) {
      // This happens when the script is not running in the context of an SDK.
      return '<unknown>';
    }
  }

  static CommandLineOptions _parse(
    ResourceProvider resourceProvider,
    List<String> args,
  ) {
    args = preprocessArgs(PhysicalResourceProvider.INSTANCE, args);

    var verbose = args.contains('-v') || args.contains('--verbose');
    var hide = !verbose;

    var parser = ArgParser(allowTrailingOptions: true);

    if (!hide) {
      parser.addSeparator('General options:');
    }

    // TODO(devoncarew): This defines some hidden flags, which would be better
    // defined with the rest of the hidden flags below (to group well with the
    // other flags).
    _defineAnalysisArguments(parser, hide: hide);

    parser
      ..addOption('format',
          help: 'Specifies the format in which errors are displayed; the only '
              'currently allowed value is \'machine\'.')
      ..addFlag('version',
          help: 'Print the analyzer version.',
          defaultsTo: false,
          negatable: false)
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
      ..addFlag(_ignoreUnrecognizedFlagsFlag,
          help: 'Ignore unrecognized command line flags.',
          defaultsTo: false,
          negatable: false,
          hide: hide)
      ..addOption(_defaultLanguageVersionOption,
          help: 'The default language version when it is not specified via '
              'other ways (internal, tests only).',
          hide: false)
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
      ..addFlag('train-snapshot',
          help: 'Analyze the given source for the purposes of training a '
              'dartanalyzer snapshot.',
          hide: hide,
          negatable: false);

    try {
      if (args.contains('--$_ignoreUnrecognizedFlagsFlag')) {
        args = filterUnknownArguments(args, parser);
      }
      var results = parser.parse(args);

      // Persistent worker.
      if (args.contains('--persistent_worker')) {
        var hasBuildMode = args.contains('--build-mode');
        var onlyDartSdkArg = args.length == 2 ||
            (args.length == 3 && args.any((a) => a.startsWith('--dart-sdk'))) ||
            (args.length == 4 && args.contains('--dart-sdk'));
        if (!(hasBuildMode && onlyDartSdkArg)) {
          printAndFail('The --persistent_worker flag should be used with and '
              'only with the --build-mode flag, and possibly the --dart-sdk '
              'option. Got: $args');
          return null; // Only reachable in testing.
        }
        return CommandLineOptions._fromArgs(resourceProvider, results);
      }

      // Help requests.
      if (cast(results['help'])) {
        _showUsage(parser, fromHelp: true);
        exitHandler(0);
        return null; // Only reachable in testing.
      }

      // Batch mode and input files.
      if (cast(results['batch'])) {
        if (results.rest.isNotEmpty) {
          errorSink.writeln('No source files expected in the batch mode.');
          _showUsage(parser);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      } else if (cast(results['persistent_worker'])) {
        if (results.rest.isNotEmpty) {
          errorSink.writeln(
              'No source files expected in the persistent worker mode.');
          _showUsage(parser);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      } else if (cast(results['version'])) {
        outSink.writeln('$_binaryName version ${_getVersion()}');
        exitHandler(0);
        return null; // Only reachable in testing.
      } else {
        if (results.rest.isEmpty && !cast<bool>(results['build-mode'])) {
          _showUsage(parser, fromHelp: true);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      }

      if (results.wasParsed('strong')) {
        errorSink.writeln(
            'Note: the --strong flag is deprecated and will be removed in an '
            'future release.\n');
      }
      if (results.wasParsed(_enableExperimentOption)) {
        var names =
            (results[_enableExperimentOption] as List).cast<String>().toList();
        var errorFound = false;
        for (var validationResult in validateFlags(names)) {
          if (validationResult.isError) {
            errorFound = true;
          }
          var kind = validationResult.isError ? 'ERROR' : 'WARNING';
          errorSink.writeln('$kind: ${validationResult.message}');
        }
        if (errorFound) {
          _showUsage(parser);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      }

      return CommandLineOptions._fromArgs(resourceProvider, results);
    } on FormatException catch (e) {
      errorSink.writeln(e.message);
      _showUsage(parser);
      exitHandler(15);
      return null; // Only reachable in testing.
    }
  }

  static void _showUsage(ArgParser parser, {bool fromHelp = false}) {
    errorSink.writeln(
        'Usage: $_binaryName [options...] <directory or list of files>');

    errorSink.writeln('');
    errorSink.writeln(parser.usage);

    errorSink.writeln('');
    errorSink.writeln('''
Run "dartanalyzer -h -v" for verbose help output, including less commonly used options.
For more information, see https://dart.dev/tools/dartanalyzer.\n''');
  }
}
