// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.options;

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;

const _binaryName = 'dartanalyzer';

/// Shared exit handler.
///
/// *Visible for testing.*
ExitHandler exitHandler = exit;

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
  /// The path to an analysis options file
  final String analysisOptionsFile;

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

  /// Whether to use diet parsing, i.e. skip function bodies. We don't need to
  /// analyze function bodies to use summaries during future compilation steps.
  final bool buildSummaryOnlyDiet;

  /// Whether to use exclude informative data from created summaries.
  final bool buildSummaryExcludeInformative;

  /// The path to output the summary when creating summaries in build mode.
  final String buildSummaryOutput;

  /// The path to output the semantic-only summary when creating summaries in
  /// build mode.
  final String buildSummaryOutputSemantic;

  /// Whether to suppress a nonzero exit code in build mode.
  final bool buildSuppressExitCode;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// The path to the dart SDK summary file.
  String dartSdkSummaryPath;

  /// A table mapping the names of defined variables to their values.
  final Map<String, String> definedVariables;

  /// Whether to disable cache flushing.  This option can improve analysis
  /// speed at the expense of memory usage.  It may also be useful for working
  /// around bugs.
  final bool disableCacheFlushing;

  /// Whether to report hints
  final bool disableHints;

  /// Whether to display version information
  final bool displayVersion;

  /// Whether to enable null-aware operators (DEP 9).
  final bool enableNullAwareOperators;

  /// Whether to strictly follow the specification when generating warnings on
  /// "call" methods (fixes dartbug.com/21938).
  final bool enableStrictCallChecks;

  /// Whether to relax restrictions on mixins (DEP 34).
  final bool enableSuperMixins;

  /// Whether to treat type mismatches found during constant evaluation as
  /// errors.
  final bool enableTypeChecks;

  /// Whether to treat hints as fatal
  final bool hintsAreFatal;

  /// Whether to ignore unrecognized flags
  final bool ignoreUnrecognizedFlags;

  /// Whether to report lints
  final bool lints;

  /// Whether to log additional analysis messages and exceptions
  final bool log;

  /// Whether to use machine format for error display
  final bool machineFormat;

  /// The path to the package root
  final String packageRootPath;

  /// The path to a `.packages` configuration file
  final String packageConfigPath;

  /// The path to a file to write a performance log.
  /// (Or null if not enabled.)
  final String perfReport;

  /// Batch mode (for unit testing)
  final bool shouldBatch;

  /// Whether to show package: warnings
  final bool showPackageWarnings;

  /// If not null, show package: warnings only for matching packages.
  final String showPackageWarningsPrefix;

  /// Whether to show SDK warnings
  final bool showSdkWarnings;

  /// The source files to analyze
  final List<String> sourceFiles;

  /// Whether to treat warnings as fatal
  final bool warningsAreFatal;

  /// Whether to use strong static checking.
  final bool strongMode;

  /// Whether implicit casts are enabled (in strong mode)
  final bool implicitCasts;

  /// Whether implicit dynamic is enabled (mainly for strong mode users)
  final bool implicitDynamic;

  /// Whether to treat lints as fatal
  final bool lintsAreFatal;

  /// Initialize options from the given parsed [args].
  CommandLineOptions._fromArgs(
      ArgResults args, Map<String, String> definedVariables)
      : buildAnalysisOutput = args['build-analysis-output'],
        buildMode = args['build-mode'],
        buildModePersistentWorker = args['persistent_worker'],
        buildSummaryInputs = args['build-summary-input'] as List<String>,
        buildSummaryOnly = args['build-summary-only'],
        buildSummaryOnlyDiet = args['build-summary-only-diet'],
        buildSummaryExcludeInformative =
            args['build-summary-exclude-informative'],
        buildSummaryOutput = args['build-summary-output'],
        buildSummaryOutputSemantic = args['build-summary-output-semantic'],
        buildSuppressExitCode = args['build-suppress-exit-code'],
        dartSdkPath = args['dart-sdk'],
        dartSdkSummaryPath = args['dart-sdk-summary'],
        definedVariables = definedVariables,
        analysisOptionsFile = args['options'],
        disableCacheFlushing = args['disable-cache-flushing'],
        disableHints = args['no-hints'],
        displayVersion = args['version'],
        enableNullAwareOperators = args['enable-null-aware-operators'],
        enableStrictCallChecks = args['enable-strict-call-checks'],
        enableSuperMixins = args['supermixin'],
        enableTypeChecks = args['enable_type_checks'],
        hintsAreFatal = args['fatal-hints'],
        ignoreUnrecognizedFlags = args['ignore-unrecognized-flags'],
        lints = args['lints'],
        log = args['log'],
        machineFormat = args['machine'] || args['format'] == 'machine',
        packageConfigPath = args['packages'],
        packageRootPath = args['package-root'],
        perfReport = args['x-perf-report'],
        shouldBatch = args['batch'],
        showPackageWarnings = args['show-package-warnings'] ||
            args['package-warnings'] ||
            args['x-package-warnings-prefix'] != null,
        showPackageWarningsPrefix = args['x-package-warnings-prefix'],
        showSdkWarnings = args['show-sdk-warnings'] || args['warnings'],
        sourceFiles = args.rest,
        warningsAreFatal = args['fatal-warnings'],
        strongMode = args['strong'],
        implicitCasts = !args['no-implicit-casts'],
        implicitDynamic = !args['no-implicit-dynamic'],
        lintsAreFatal = args['fatal-lints'];

  /// Parse [args] into [CommandLineOptions] describing the specified
  /// analyzer options. In case of a format error, calls [printAndFail], which
  /// by default prints an error message to stderr and exits.
  static CommandLineOptions parse(List<String> args,
      [printAndFail(String msg) = printAndFail]) {
    CommandLineOptions options = _parse(args);
    // Check SDK.
    if (!options.buildModePersistentWorker) {
      // Infer if unspecified.
      if (options.dartSdkPath == null) {
        Directory sdkDir = getSdkDir(args);
        if (sdkDir != null) {
          options.dartSdkPath = sdkDir.path;
        }
      }

      var sdkPath = options.dartSdkPath;

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

    // OK.  Report deprecated options.
    if (options.enableNullAwareOperators) {
      errorSink.writeln(
          "Info: Option '--enable-null-aware-operators' is no longer needed. "
          "Null aware operators are supported by default.");
    }

    // Build mode.
    if (options.buildModePersistentWorker && !options.buildMode) {
      printAndFail('The option --persisten_worker can be used only '
          'together with --build-mode.');
    }
    if (options.buildSummaryOnlyDiet && !options.buildSummaryOnly) {
      printAndFail('The option --build-summary-only-diet can be used only '
          'together with --build-summary-only.');
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
    // Check if the args are in a file (bazel worker mode).
    if (args.last.startsWith('@')) {
      var argsFile = new File(args.last.substring(1));
      args = argsFile.readAsLinesSync();
    }

    args = args.expand((String arg) => arg.split('=')).toList();
    var parser = new CommandLineParser()
      ..addFlag('batch',
          abbr: 'b',
          help: 'Read commands from standard input (for testing).',
          defaultsTo: false,
          negatable: false)
      ..addOption('dart-sdk', help: 'The path to the Dart SDK.')
      ..addOption('dart-sdk-summary',
          help: 'The path to the Dart SDK summary file.', hide: true)
      ..addOption('packages',
          help:
              'Path to the package resolution configuration file, which supplies '
              'a mapping of package names to paths.  This option cannot be '
              'used with --package-root.')
      ..addOption('package-root',
          abbr: 'p',
          help: 'Path to a package root directory (deprecated). This option '
              'cannot be used with --packages.')
      ..addOption('options', help: 'Path to an analysis options file.')
      ..addOption('format',
          help: 'Specifies the format in which errors are displayed.')
      ..addFlag('machine',
          help: 'Print errors in a format suitable for parsing (deprecated).',
          defaultsTo: false,
          negatable: false)
      ..addFlag('version',
          help: 'Print the analyzer version.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('lints',
          help: 'Show lint results.', defaultsTo: false, negatable: false)
      ..addFlag('no-hints',
          help: 'Do not show hint results.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('disable-cache-flushing', defaultsTo: false, hide: true)
      ..addFlag('ignore-unrecognized-flags',
          help: 'Ignore unrecognized command line flags.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('fatal-hints',
          help: 'Treat hints as fatal.', defaultsTo: false, negatable: false)
      ..addFlag('fatal-warnings',
          help: 'Treat non-type warnings as fatal.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('fatal-lints',
          help: 'Treat lints as fatal.', defaultsTo: false, negatable: false)
      ..addFlag('package-warnings',
          help: 'Show warnings from package: imports.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('show-package-warnings',
          help: 'Show warnings from package: imports (deprecated).',
          defaultsTo: false,
          negatable: false)
      ..addFlag('warnings',
          help: 'Show warnings from SDK imports.',
          defaultsTo: false,
          negatable: false)
      ..addFlag('show-sdk-warnings',
          help: 'Show warnings from SDK imports (deprecated).',
          defaultsTo: false,
          negatable: false)
      ..addOption('x-package-warnings-prefix',
          help:
              'Show warnings from package: imports that match the given prefix',
          hide: true)
      ..addOption('x-perf-report',
          help: 'Writes a performance report to the given file (experimental).')
      ..addFlag('help',
          abbr: 'h',
          help: 'Display this help message.',
          defaultsTo: false,
          negatable: false)
      ..addOption('url-mapping',
          help: '--url-mapping=libraryUri,/path/to/library.dart directs the '
              'analyzer to use "library.dart" as the source for an import '
              'of "libraryUri".',
          allowMultiple: true,
          splitCommas: false)
      //
      // Build mode.
      //
      ..addFlag('persistent_worker',
          help: 'Enable Bazel persistent worker mode.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addOption('build-analysis-output',
          help:
              'Specifies the path to the file where analysis results should be written.',
          hide: true)
      ..addFlag('build-mode',
          // TODO(paulberry): add more documentation.
          help: 'Enable build mode.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addOption('build-summary-input',
          help: 'Path to a summary file that contains information from a '
              'previous analysis run.  May be specified multiple times.',
          allowMultiple: true,
          hide: true)
      ..addOption('build-summary-output',
          help: 'Specifies the path to the file where the full summary '
              'information should be written.',
          hide: true)
      ..addOption('build-summary-output-semantic',
          help: 'Specifies the path to the file where the semantic summary '
              'information should be written.',
          hide: true)
      ..addFlag('build-summary-only',
          help: 'Disable analysis (only generate summaries).',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('build-summary-only-ast',
          help: 'deprecated -- Generate summaries using ASTs.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('build-summary-only-diet',
          help: 'Diet parse function bodies.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('build-summary-exclude-informative',
          help: 'Exclude @informative information (docs, offsets, etc).  '
              'Deprecated: please use --build-summary-output-semantic instead.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('build-suppress-exit-code',
          help: 'Exit with code 0 even if errors are found.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      //
      // Hidden flags.
      //
      ..addFlag('enable-async',
          help: 'Enable support for the proposed async feature.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('enable-enum',
          help: 'Enable support for the proposed enum feature.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('enable-conditional-directives',
          help:
              'deprecated -- Enable support for conditional directives (DEP 40).',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('enable-null-aware-operators',
          help: 'Enable support for null-aware operators (DEP 9).',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('enable-strict-call-checks',
          help: 'Fix issue 21938.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('enable-new-task-model',
          help: 'deprecated -- Ennable new task model.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('initializing-formal-access',
          help:
              'Enable support for allowing access to field formal parameters in a constructor\'s initializer list',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('supermixin',
          help: 'Relax restrictions on mixins (DEP 34).',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('log',
          help: 'Log additional messages and exceptions.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('enable_type_checks',
          help: 'Check types in constant evaluation.',
          defaultsTo: false,
          negatable: false,
          hide: true)
      ..addFlag('strong',
          help: 'Enable strong static checks (https://goo.gl/DqcBsw)')
      ..addFlag('no-implicit-casts',
          negatable: false,
          help: 'Disable implicit casts in strong mode (https://goo.gl/cTLz40)')
      ..addFlag('no-implicit-dynamic',
          negatable: false,
          help: 'Disable implicit dynamic (https://goo.gl/m0UgXD)');

    try {
      // TODO(scheglov) https://code.google.com/p/dart/issues/detail?id=11061
      args =
          args.map((String arg) => arg == '-batch' ? '--batch' : arg).toList();
      Map<String, String> definedVariables = <String, String>{};
      var results = parser.parse(args, definedVariables);

      // Persistent worker.
      if (args.contains('--persistent_worker')) {
        bool validArgs;
        if (!args.contains('--build-mode')) {
          validArgs = false;
        } else if (args.length == 2) {
          validArgs = true;
        } else if (args.length == 4 && args.contains('--dart-sdk')) {
          validArgs = true;
        } else {
          validArgs = false;
        }
        if (!validArgs) {
          printAndFail('The --persistent_worker flag should be used with and '
              'only with the --build-mode flag, and possibly the --dart-sdk '
              'option. Got: $args');
          return null; // Only reachable in testing.
        }
        return new CommandLineOptions._fromArgs(results, definedVariables);
      }

      // Help requests.
      if (results['help']) {
        _showUsage(parser);
        exitHandler(0);
        return null; // Only reachable in testing.
      }
      // Batch mode and input files.
      if (results['batch']) {
        if (results.rest.isNotEmpty) {
          errorSink.writeln('No source files expected in the batch mode.');
          _showUsage(parser);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      } else if (results['persistent_worker']) {
        if (results.rest.isNotEmpty) {
          errorSink.writeln(
              'No source files expected in the persistent worker mode.');
          _showUsage(parser);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      } else if (results['version']) {
        outSink.write('$_binaryName version ${_getVersion()}');
        exitHandler(0);
        return null; // Only reachable in testing.
      } else {
        if (results.rest.isEmpty && !results['build-mode']) {
          _showUsage(parser);
          exitHandler(15);
          return null; // Only reachable in testing.
        }
      }
      return new CommandLineOptions._fromArgs(results, definedVariables);
    } on FormatException catch (e) {
      errorSink.writeln(e.message);
      _showUsage(parser);
      exitHandler(15);
      return null; // Only reachable in testing.
    }
  }

  static _showUsage(parser) {
    errorSink
        .writeln('Usage: $_binaryName [options...] <libraries to analyze...>');
    errorSink.writeln(parser.getUsage());
    errorSink.writeln('');
    errorSink.writeln(
        'For more information, see http://www.dartlang.org/tools/analyzer.');
  }
}

/// Commandline argument parser.
///
/// TODO(pq): when the args package supports ignoring unrecognized
/// options/flags, this class can be replaced with a simple [ArgParser]
/// instance.
class CommandLineParser {
  final List<String> _knownFlags;
  final bool _alwaysIgnoreUnrecognized;
  final ArgParser _parser;

  /// Creates a new command line parser.
  CommandLineParser({bool alwaysIgnoreUnrecognized: false})
      : _knownFlags = <String>[],
        _alwaysIgnoreUnrecognized = alwaysIgnoreUnrecognized,
        _parser = new ArgParser(allowTrailingOptions: true);

  ArgParser get parser => _parser;

  /// Defines a flag.
  /// See [ArgParser.addFlag()].
  void addFlag(String name,
      {String abbr,
      String help,
      bool defaultsTo: false,
      bool negatable: true,
      void callback(bool value),
      bool hide: false}) {
    _knownFlags.add(name);
    _parser.addFlag(name,
        abbr: abbr,
        help: help,
        defaultsTo: defaultsTo,
        negatable: negatable,
        callback: callback,
        hide: hide);
  }

  /// Defines a value-taking option.
  /// See [ArgParser.addOption()].
  void addOption(String name,
      {String abbr,
      String help,
      List<String> allowed,
      Map<String, String> allowedHelp,
      String defaultsTo,
      void callback(value),
      bool allowMultiple: false,
      bool splitCommas,
      bool hide: false}) {
    _knownFlags.add(name);
    _parser.addOption(name,
        abbr: abbr,
        help: help,
        allowed: allowed,
        allowedHelp: allowedHelp,
        defaultsTo: defaultsTo,
        callback: callback,
        allowMultiple: allowMultiple,
        splitCommas: splitCommas,
        hide: hide);
  }

  /// Generates a string displaying usage information for the defined options.
  /// See [ArgParser.usage].
  String getUsage() => _parser.usage;

  /// Parses [args], a list of command-line arguments, matches them against the
  /// flags and options defined by this parser, and returns the result. The
  /// values of any defined variables are captured in the given map.
  /// See [ArgParser].
  ArgResults parse(List<String> args, Map<String, String> definedVariables) =>
      _parser.parse(
          _filterUnknowns(parseDefinedVariables(args, definedVariables)));

  List<String> parseDefinedVariables(
      List<String> args, Map<String, String> definedVariables) {
    int count = args.length;
    List<String> remainingArgs = <String>[];
    for (int i = 0; i < count; i++) {
      String arg = args[i];
      if (arg == '--') {
        while (i < count) {
          remainingArgs.add(args[i++]);
        }
      } else if (arg.startsWith("-D")) {
        definedVariables[arg.substring(2)] = args[++i];
      } else {
        remainingArgs.add(arg);
      }
    }
    return remainingArgs;
  }

  List<String> _filterUnknowns(List<String> args) {
    // Only filter args if the ignore flag is specified, or if
    // _alwaysIgnoreUnrecognized was set to true.
    if (_alwaysIgnoreUnrecognized ||
        args.contains('--ignore-unrecognized-flags')) {
      //TODO(pquitslund): replace w/ the following once library skew issues are
      // sorted out
      //return args.where((arg) => !arg.startsWith('--') ||
      //  _knownFlags.contains(arg.substring(2)));

      // Filter all unrecognized flags and options.
      List<String> filtered = <String>[];
      for (int i = 0; i < args.length; ++i) {
        String arg = args[i];
        if (arg.startsWith('--') && arg.length > 2) {
          String option = arg.substring(2);
          // strip the last '=value'
          int equalsOffset = option.lastIndexOf('=');
          if (equalsOffset != -1) {
            option = option.substring(0, equalsOffset);
          }
          // Check the option
          if (!_knownFlags.contains(option)) {
            //"eat" params by advancing to the next flag/option
            i = _getNextFlagIndex(args, i);
          } else {
            filtered.add(arg);
          }
        } else {
          filtered.add(arg);
        }
      }

      return filtered;
    } else {
      return args;
    }
  }

  int _getNextFlagIndex(args, i) {
    for (; i < args.length; ++i) {
      if (args[i].startsWith('--')) {
        return i;
      }
    }
    return i;
  }
}
