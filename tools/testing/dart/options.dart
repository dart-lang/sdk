// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'configuration.dart';
import 'path.dart';
import 'repository.dart';
import 'runtime_updater.dart';
import 'utils.dart';

const _defaultTestSelectors = const [
  'samples',
  'standalone',
  'standalone_2',
  'corelib',
  'corelib_2',
  'co19',
  'language',
  'language_2',
  'isolate',
  'vm',
  'html',
  'benchmark_smoke',
  'utils',
  'lib',
  'lib_2',
  'analyze_library',
  'service',
  'kernel',
  'observatory_ui'
];

/// Specifies a single command line option.
///
/// The name of the specification is used as the key for the option in the Map
/// returned from the [TestOptionParser] parse method.
class _Option {
  // TODO(rnystrom): Some string options use "" to mean "no value" and others
  // use null. Clean that up.
  _Option(this.name, this.description,
      {String abbr, List<String> values, String defaultsTo, bool hide})
      : abbreviation = abbr,
        values = values ?? [],
        defaultValue = defaultsTo,
        type = _OptionValueType.string,
        verboseOnly = hide ?? false;

  _Option.bool(this.name, this.description, {String abbr, bool hide})
      : abbreviation = abbr,
        values = [],
        defaultValue = false,
        type = _OptionValueType.bool,
        verboseOnly = hide ?? false;

  _Option.int(this.name, this.description,
      {String abbr, int defaultsTo, bool hide})
      : abbreviation = abbr,
        values = [],
        defaultValue = defaultsTo,
        type = _OptionValueType.int,
        verboseOnly = hide ?? false;

  final String name;
  final String description;
  final String abbreviation;
  final List<String> values;
  final Object defaultValue;
  final _OptionValueType type;

  /// Only show this option in the verbose help.
  final bool verboseOnly;

  /// Gets the shortest command line argument used to refer to this option.
  String get shortCommand => abbreviation != null ? "-$abbreviation" : command;

  /// Gets the canonical long command line argument used to refer to this
  /// option.
  String get command => "--${name.replaceAll('_', '-')}";
}

enum _OptionValueType { bool, int, string }

/// Parses command line arguments and produces a test runner configuration.
class OptionsParser {
  static final List<_Option> _options = [
    new _Option('mode', 'Mode in which to run the tests.',
        abbr: 'm',
        values: ['all']..addAll(Mode.names),
        defaultsTo: Mode.debug.name),
    new _Option(
        'compiler',
        '''How the Dart code should be compiled or statically processed.

none:          Do not compile the Dart code.
precompiler:   Compile into AOT snapshot before running the test.
dart2js:       Compile to JavaScript using dart2js.
dart2analyzer: Perform static analysis on Dart code using the analyzer.
app_jit:       Compile the Dart code into an app snapshot.
dartk:         Compile the Dart code into Kernel before running test.
dartkp:        Compile the Dart code into Kernel and then Kernel into AOT
               snapshot before running the test.
spec_parser:   Parse Dart code using the specification parser.''',
        abbr: 'c',
        values: Compiler.names),
    new _Option(
        'runtime',
        '''Where the tests should be run.
vm:               Run Dart code on the standalone Dart VM.
flutter:          Run Dart code on the Flutter engine.
dart_precompiled: Run a precompiled snapshot on the VM without a JIT.
d8:               Run JavaScript from the command line using v8.
jsshell:          Run JavaScript from the command line using Firefox js-shell.
drt:              Run Dart or JavaScript in the headless version of Chrome,
                  Content shell.

ContentShellOnAndroid: Run Dart or JavaScript in content shell on Android.

ff:
chrome:
safari:
ie9:
ie10:
ie11:
opera:
chromeOnAndroid:  Run JavaScript in the specified browser.

self_check:       Pass each test or its compiled output to every file under
                  `pkg` whose name ends with `_self_check.dart`. Each test is
                  given to the self_check tester as a filename on stdin using
                  the batch-mode protocol.

none:             No runtime, compile only.''',
        abbr: 'r',
        values: Runtime.names),
    new _Option(
        'arch',
        '''The architecture to run tests for.

Allowed values are:
all
ia32, x64
arm, armv6, armv5te, arm64,
simarm, simarmv6, simarmv5te, simarm64,
simdbc, simdbc64''',
        abbr: 'a',
        values: ['all']..addAll(Architecture.names),
        defaultsTo: Architecture.x64.name,
        hide: true),
    new _Option('system', 'The operating system to run tests on.',
        abbr: 's',
        values: System.names,
        defaultsTo: Platform.operatingSystem,
        hide: true),
    new _Option.bool('checked', 'Run tests in checked mode.'),
    new _Option.bool('strong', 'Run tests in strong mode.'),
    new _Option.bool('host_checked', 'Run compiler in checked mode.',
        hide: true),
    new _Option.bool('minified', 'Enable minification in the compiler.',
        hide: true),
    new _Option.bool(
        'csp', 'Run tests under Content Security Policy restrictions.',
        hide: true),
    new _Option.bool('fast_startup', 'Pass the --fast-startup flag to dart2js.',
        hide: true),
    new _Option.bool('fast_tests',
        'Only run tests that are not marked `Slow` or `Timeout`.'),
    new _Option.bool('enable_asserts',
        'Pass the --enable-asserts flag to dart2js or to the vm.'),
    new _Option.bool(
        'preview_dart_2', 'Pass the --preview-dart-2 flag to analyzer.',
        hide: true),
    // TODO(sigmund): replace dart2js_with_kernel with preview-dart-2.
    new _Option.bool(
        'dart2js_with_kernel', 'Pass the --use-kernel flag to dart2js.',
        hide: true),
    new _Option.bool('hot_reload', 'Run hot reload stress tests.', hide: true),
    new _Option.bool(
        'hot_reload_rollback', 'Run hot reload rollback stress tests.',
        hide: true),
    new _Option.bool(
        'use_blobs', 'Use mmap instead of shared libraries for precompilation.',
        hide: true),
    new _Option.int('timeout', 'Timeout in seconds.', abbr: 't'),
    new _Option(
        'progress',
        '''Progress indication mode.

Allowed values are:
compact, color, line, verbose, silent, status, buildbot, diff''',
        abbr: 'p',
        values: Progress.names,
        defaultsTo: Progress.compact.name),
    new _Option('step_name', 'Step name for use by -pbuildbot.', hide: true),
    new _Option.bool('report',
        'Print a summary report of the number of tests, by expectation.',
        hide: true),
    new _Option.int('tasks', 'The number of parallel tasks to run.',
        abbr: 'j', defaultsTo: Platform.numberOfProcessors),
    new _Option.int('shards',
        'The number of instances that the tests will be sharded over.',
        defaultsTo: 1, hide: true),
    new _Option.int(
        'shard', 'The index of this instance when running in sharded mode.',
        defaultsTo: 1, hide: true),
    new _Option.bool('help', 'Print list of options.', abbr: 'h'),
    new _Option.bool('verbose', 'Verbose output.', abbr: 'v'),
    new _Option.bool('verify-ir', 'Verify kernel IR.', hide: true),
    new _Option.bool('no-tree-shake', 'Disable kernel IR tree shaking.',
        hide: true),
    new _Option.bool('list', 'List tests only, do not run them.'),
    new _Option.bool('list_status_files',
        'List status files for test-suites. Do not run any test suites.',
        hide: true),
    new _Option.bool('report_in_json',
        'When listing with --list, output result summary in JSON.',
        hide: true),
    new _Option.bool('time', 'Print timing information after running tests.'),
    new _Option('dart', 'Path to dart executable.', hide: true),
    new _Option('flutter', 'Path to flutter executable.', hide: true),
    new _Option('drt', 'Path to content shell executable.', hide: true),
    new _Option('firefox', 'Path to firefox browser executable.', hide: true),
    new _Option('chrome', 'Path to chrome browser executable.', hide: true),
    new _Option('safari', 'Path to safari browser executable.', hide: true),
    new _Option.bool('use_sdk', '''Use compiler or runtime from the SDK.'''),
    // TODO(rnystrom): This does not appear to be used. Remove?
    new _Option('build_directory',
        'The name of the build directory, where products are placed.',
        hide: true),
    new _Option('output_directory',
        'The name of the output directory for storing log files.',
        defaultsTo: "logs", hide: true),
    new _Option.bool('noBatch', 'Do not run tests in batch mode.',
        abbr: 'n', hide: true),
    new _Option.bool('dart2js_batch', 'Run dart2js tests in batch mode.',
        hide: true),
    new _Option.bool(
        'append_logs', 'Do not delete old logs but rather append to them.',
        hide: true),
    new _Option.bool('write_debug_log',
        'Don\'t write debug messages to stdout but rather to a logfile.',
        hide: true),
    new _Option.bool('write_test_outcome_log',
        'Write test outcomes to a "${TestUtils.testOutcomeFileName}" file.',
        hide: true),
    new _Option.bool(
        'write_result_log',
        'Write test results to a "${TestUtils.resultLogFileName}" json file '
        'located at the debug_output_directory.',
        hide: true),
    new _Option.bool(
        'reset_browser_configuration',
        '''Browser specific reset of configuration.

Warning: Using this option may remove your bookmarks and other
settings.''',
        hide: true),
    new _Option.bool(
        'copy_coredumps',
        '''If we see a crash that we did not expect, copy the core dumps to
"/tmp".''',
        hide: true),
    new _Option(
        'local_ip',
        '''IP address the HTTP servers should listen on. This address is also
used for browsers to connect to.''',
        defaultsTo: '127.0.0.1',
        hide: true),
    new _Option.int('test_server_port', 'Port for test http server.',
        defaultsTo: 0, hide: true),
    new _Option.int('test_server_cross_origin_port',
        'Port for test http server cross origin.',
        defaultsTo: 0, hide: true),
    new _Option.int('test_driver_port', 'Port for http test driver server.',
        defaultsTo: 0, hide: true),
    new _Option.int(
        'test_driver_error_port', 'Port for http test driver server errors.',
        defaultsTo: 0, hide: true),
    new _Option(
        'builder_tag',
        '''Machine specific options that is not captured by the regular test
options. Used to be able to make sane updates to the status files.''',
        hide: true),
    new _Option('vm_options', 'Extra options to send to the VM when running.',
        hide: true),
    new _Option(
        'dart2js_options', 'Extra options for dart2js compilation step.',
        hide: true),
    new _Option(
        'suite_dir', 'Additional directory to add to the testing matrix.',
        hide: true),
    new _Option('package_root', 'The package root to use for testing.',
        hide: true),
    new _Option('packages', 'The package spec file to use for testing.',
        hide: true),
    new _Option(
        'exclude_suite',
        '''Exclude suites from default selector, only works when no selector
has been specified on the command line.''',
        hide: true),
    new _Option.bool(
        'skip_compilation',
        '''
Skip the compilation step, using the compilation artifacts left in
the output folder from a previous run. This flag will often cause
false positves and negatives, but can be useful for quick and
dirty offline testing when not making changes that affect the
compiler.''',
        hide: true)
  ];

  /// For printing out reproducing command lines, we don't want to add these
  /// options.
  static final _blacklistedOptions = [
    'append_logs',
    'build_directory',
    'debug_output_directory',
    'chrome',
    'copy_coredumps',
    'dart',
    'flutter',
    'drt',
    'exclude_suite',
    'firefox',
    'local_ip',
    'progress',
    'report',
    'safari',
    'shard',
    'shards',
    'step_name',
    'tasks',
    'time',
    'verbose',
    'write_debug_log',
    'write_test_outcome_log',
    'write_result_log'
  ].toSet();

  /// Parses a list of strings as test options.
  ///
  /// Returns a list of configurations in which to run the tests.
  /// Configurations are maps mapping from option keys to values. When
  /// encountering the first non-option string, the rest of the arguments are
  /// stored in the returned Map under the 'rest' key.
  List<Configuration> parse(List<String> arguments) {
    // Help supersedes all other arguments.
    if (arguments.contains("--help") || arguments.contains("-h")) {
      _printHelp(
          verbose: arguments.contains("--verbose") || arguments.contains("-v"));
      return null;
    }

    var configuration = <String, dynamic>{};

    // Fill in configuration with arguments passed to the test script.
    for (var i = 0; i < arguments.length; i++) {
      var arg = arguments[i];

      // Extract name and value for options.
      String command;
      String value;
      _Option option;

      if (arg.startsWith("--")) {
        // A long option name.
        var equals = arg.indexOf("=");
        if (equals != -1) {
          // A long option with a value, like "--arch=ia32".
          command = arg.substring(0, equals);
          value = arg.substring(equals + 1);
        } else {
          command = arg;
        }

        option = _findByName(command.substring(2));
      } else if (arg.startsWith("-")) {
        // An abbreviated option.
        if (arg.length == 1) {
          _fail('Missing option name after "-".');
        }

        command = arg.substring(0, 2);

        if (arg.length > 2) {
          // An abbreviated option followed by a value, like "-aia32".
          value = arg.substring(2);
        }

        option = _findByAbbreviation(command.substring(1));
      } else {
        // The argument does not start with "-" or "--" and is therefore not an
        // option. Use it as a test selector pattern.
        var patterns = configuration.putIfAbsent("selectors", () => <String>[]);
        patterns.add(arg);
        continue;
      }

      if (option == null) {
        _fail('Unknown command line option "$command".');
      }

      // If we need a value, look at the next argument.
      if (value == null && option.type != _OptionValueType.bool) {
        if (i + 1 >= arguments.length) {
          _fail('Missing value for command line option "$command".');
        }
        value = arguments[++i];
      }

      // Multiple uses of a flag are an error, because there is no naturally
      // correct way to handle conflicting options.
      if (configuration.containsKey(option.name)) {
        _fail('Already have value for command line option "$command".');
      }

      // Parse the value for the option.
      switch (option.type) {
        case _OptionValueType.bool:
          if (value != null) {
            _fail('Boolean flag "$command" does not take a value.');
          }

          configuration[option.name] = true;
          break;

        case _OptionValueType.int:
          try {
            configuration[option.name] = int.parse(value);
          } on FormatException {
            _fail('Integer value expected for option "$command".');
          }
          break;

        case _OptionValueType.string:
          // Validate against the allowed values.
          if (!option.values.isEmpty) {
            for (var v in value.split(",")) {
              if (!option.values.contains(v)) {
                _fail('Unknown value "$v" for command line option "$command".');
              }
            }
          }

          // TODO(rnystrom): Store as a list instead of a comma-delimited
          // string.
          configuration[option.name] = value;
          break;
      }
    }

    // Apply default values for unspecified options.
    for (var option in _options) {
      if (!configuration.containsKey(option.name)) {
        configuration[option.name] = option.defaultValue;
      }
    }

    return _createConfigurations(configuration);
  }

  /// Prints [message] and exits with a non-zero exit code.
  void _fail(String message) {
    print(message);
    exit(1);
  }

  /// Given a set of parsed option values, returns the list of command line
  /// arguments that would reproduce that configuration.
  List<String> _reproducingCommand(Map<String, dynamic> data) {
    var arguments = <String>[];

    for (var option in _options) {
      var name = option.name;
      if (!data.containsKey(name) || _blacklistedOptions.contains(name)) {
        continue;
      }

      var value = data[name];
      if (data[name] == option.defaultValue ||
          (name == 'packages' &&
              value == Repository.uri.resolve('.packages').toFilePath())) {
        continue;
      }

      arguments.add(option.shortCommand);
      if (option.type != _OptionValueType.bool) {
        arguments.add(value.toString());
      }
    }

    return arguments;
  }

  List<Configuration> _createConfigurations(
      Map<String, dynamic> configuration) {
    var selectors = _expandSelectors(configuration);

    // Put observatory_ui in a configuration with its own packages override.
    // Only one value in the configuration map is mutable:
    if (selectors.containsKey('observatory_ui')) {
      if (selectors.length == 1) {
        configuration['packages'] = Repository.uri
            .resolve('runtime/observatory/.packages')
            .toFilePath();
      } else {
        // Make a new configuration whose selectors map only contains
        // observatory_ui, and remove observatory_ui from the original
        // selectors. The only mutable value in the map is the selectors, so a
        // shallow copy is safe.
        var observatoryConfiguration =
            new Map<String, dynamic>.from(configuration);
        var observatorySelectors = {
          'observatory_ui': selectors['observatory_ui']
        };
        selectors.remove('observatory_ui');

        // Set the packages flag.
        observatoryConfiguration['packages'] = Repository.uri
            .resolve('runtime/observatory/.packages')
            .toFilePath();

        return _expandConfigurations(configuration, selectors)
          ..addAll(_expandConfigurations(
              observatoryConfiguration, observatorySelectors));
      }
    }

    return _expandConfigurations(configuration, selectors);
  }

  /// Recursively expands a configuration with multiple values per key into a
  /// list of configurations with exactly one value per key.
  List<Configuration> _expandConfigurations(
      Map<String, dynamic> data, Map<String, RegExp> selectors) {
    var result = <Configuration>[];

    // Handles a string option containing a space-separated list of words.
    listOption(String name) {
      var value = data[name] as String;
      if (value == null) return const <String>[];
      return value
          .split(" ")
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    var dart2jsOptions = listOption("dart2js_options");
    var vmOptions = listOption("vm_options");

    // JSON reporting implies listing and reporting.
    if (data['report_in_json'] as bool) {
      data['list'] = true;
      data['report'] = true;
    }

    // Use verbose progress indication for verbose output unless buildbot
    // progress indication is requested.
    if ((data['verbose'] as bool) &&
        (data['progress'] as String) != 'buildbot') {
      data['progress'] = 'verbose';
    }

    var runtimeNames = data["runtime"] as String;
    var runtimes = <Runtime>[];
    if (runtimeNames != null) {
      runtimes.addAll(runtimeNames.split(",").map(Runtime.find));
    }

    var compilerNames = data["compiler"] as String;
    var compilers = <Compiler>[];
    if (compilerNames != null) {
      compilers.addAll(compilerNames.split(",").map(Compiler.find));
    }

    // Pick default compilers or runtimes if only one or the other is provided.
    if (runtimes.isEmpty) {
      if (compilers.isEmpty) {
        runtimes = [Runtime.vm];
        compilers = [Compiler.none];
      } else {
        // Pick a runtime for each compiler.
        runtimes.addAll(compilers.map((compiler) => compiler.defaultRuntime));
      }
    } else if (compilers.isEmpty) {
      // Pick a compiler for each runtime.
      compilers.addAll(runtimes.map((runtime) => runtime.defaultCompiler));
    }

    // Expand runtimes.
    for (var runtime in runtimes) {
      // Start installing the runtime if needed.
      if (runtime == Runtime.drt &&
          !(data["list"] as bool) &&
          !(data["list_status_files"] as bool)) {
        updateContentShell(data["drt"] as String);
      }

      // Expand architectures.
      var architectures = data["arch"] as String;
      if (architectures == "all") {
        architectures = "ia32,x64,simarm,simarm64,simdbc64";
      }

      for (var architectureName in architectures.split(",")) {
        var architecture = Architecture.find(architectureName);

        // Expand compilers.
        for (var compiler in compilers) {
          // Expand modes.
          var modes = data["mode"] as String;
          if (modes == "all") modes = "debug,release,product";
          for (var modeName in modes.split(",")) {
            var mode = Mode.find(modeName);

            var configuration = new Configuration(
                architecture: architecture,
                compiler: compiler,
                mode: mode,
                progress: Progress.find(data["progress"] as String),
                runtime: runtime,
                system: System.find(data["system"] as String),
                selectors: selectors,
                appendLogs: data["append_logs"] as bool,
                batch: !(data["noBatch"] as bool),
                batchDart2JS: data["dart2js_batch"] as bool,
                copyCoreDumps: data["copy_coredumps"] as bool,
                hotReload: data["hot_reload"] as bool,
                hotReloadRollback: data["hot_reload_rollback"] as bool,
                isChecked: data["checked"] as bool,
                isStrong: data["strong"] as bool,
                isHostChecked: data["host_checked"] as bool,
                isCsp: data["csp"] as bool,
                isMinified: data["minified"] as bool,
                isVerbose: data["verbose"] as bool,
                listTests: data["list"] as bool,
                listStatusFiles: data["list_status_files"] as bool,
                previewDart2: data["preview_dart_2"] as bool,
                printTiming: data["time"] as bool,
                printReport: data["report"] as bool,
                reportInJson: data["report_in_json"] as bool,
                resetBrowser: data["reset_browser_configuration"] as bool,
                skipCompilation: data["skip_compilation"] as bool,
                useBlobs: data["use_blobs"] as bool,
                useSdk: data["use_sdk"] as bool,
                useFastStartup: data["fast_startup"] as bool,
                useEnableAsserts: data["enable_asserts"] as bool,
                useDart2JSWithKernel: data["dart2js_with_kernel"] as bool,
                writeDebugLog: data["write_debug_log"] as bool,
                writeTestOutcomeLog: data["write_test_outcome_log"] as bool,
                writeResultLog: data["write_result_log"] as bool,
                drtPath: data["drt"] as String,
                chromePath: data["chrome"] as String,
                safariPath: data["safari"] as String,
                firefoxPath: data["firefox"] as String,
                dartPath: data["dart"] as String,
                dartPrecompiledPath: data["dart_precompiled"] as String,
                flutterPath: data["flutter"] as String,
                taskCount: data["tasks"] as int,
                timeout: data["timeout"] as int,
                shardCount: data["shards"] as int,
                shard: data["shard"] as int,
                stepName: data["step_name"] as String,
                testServerPort: data["test_server_port"] as int,
                testServerCrossOriginPort:
                    data['test_server_cross_origin_port'] as int,
                testDriverErrorPort: data["test_driver_error_port"] as int,
                localIP: data["local_ip"] as String,
                dart2jsOptions: dart2jsOptions,
                vmOptions: vmOptions,
                packages: data["packages"] as String,
                packageRoot: data["package_root"] as String,
                suiteDirectory: data["suite_dir"] as String,
                builderTag: data["builder_tag"] as String,
                outputDirectory: data["output_directory"] as String,
                reproducingArguments: _reproducingCommand(data),
                fastTestsOnly: data["fast_tests"] as bool);

            if (configuration.validate()) {
              result.add(configuration);
            }
          }
        }
      }
    }

    return result;
  }

  /// Expands the test selectors into a suite name and a simple regular
  /// expression to be used on the full path of a test file in that test suite.
  ///
  /// If no selectors are explicitly given, uses the default suite patterns.
  Map<String, RegExp> _expandSelectors(Map<String, dynamic> configuration) {
    var selectors = configuration['selectors'];

    if (selectors == null) {
      if (configuration['suite_dir'] != null) {
        var suitePath = new Path(configuration['suite_dir'] as String);
        selectors = [suitePath.filename];
      } else {
        selectors = _defaultTestSelectors.toList();
      }

      var excludeSuites = configuration['exclude_suite'] != null
          ? configuration['exclude_suite'].split(',')
          : [];
      for (var exclude in excludeSuites) {
        if ((selectors as List).contains(exclude)) {
          selectors.remove(exclude);
        } else {
          print("Warning: default selectors does not contain $exclude");
        }
      }
    }

    var selectorMap = <String, RegExp>{};
    for (var i = 0; i < (selectors as List).length; i++) {
      var pattern = selectors[i] as String;
      var suite = pattern;
      var slashLocation = pattern.indexOf('/');
      if (slashLocation != -1) {
        suite = pattern.substring(0, slashLocation);
        pattern = pattern.substring(slashLocation + 1);
        pattern = pattern.replaceAll('*', '.*');
      } else {
        pattern = ".?";
      }
      if (selectorMap.containsKey(suite)) {
        print("Error: '$suite/$pattern'.  Only one test selection"
            " pattern is allowed to start with '$suite/'");
        exit(1);
      }
      selectorMap[suite] = new RegExp(pattern);
    }

    return selectorMap;
  }

  /// Print out usage information.
  void _printHelp({bool verbose}) {
    var buffer = new StringBuffer();

    buffer.writeln('''The Dart SDK's internal test runner.

    Usage: dart tools/test.dart [options] [selector]

The optional selector limits the tests that will be run. For example, the
selector "language/issue", or equivalently "language/*issue*", limits to test
files matching the regexp ".*issue.*\\.dart" in the "tests/language" directory.

If you specify only a runtime ("-r"), then an appropriate default compiler will
be chosen for that runtime. Likewise, if you specify only a compiler ("-c"),
then a matching runtime is chosen. If neither compiler nor runtime is selected,
the test is run directly from source on the VM. 

Options:''');

    for (var option in _options) {
      if (!verbose && option.verboseOnly) continue;

      if (option.abbreviation != null) {
        buffer.write("-${option.abbreviation}, ");
      } else {
        buffer.write("    ");
      }

      buffer.write(option.command);

      switch (option.type) {
        case _OptionValueType.bool:
          // No value.
          break;
        case _OptionValueType.int:
          buffer.write("=<integer>");
          break;
        case _OptionValueType.string:
          if (option.values.length > 6) {
            // If there are many options, they won't fit nicely in one line and
            // should be instead listed in the description.
            buffer.write("=<...>");
          } else if (option.values.isNotEmpty) {
            buffer.write("=<${option.values.join('|')}>");
          } else {
            buffer.write("=<string>");
          }
          break;
      }

      if (option.type != _OptionValueType.bool &&
          option.defaultValue != null &&
          option.defaultValue != "") {
        buffer.write(" (defaults to ${option.defaultValue})");
      }

      buffer.writeln();
      buffer
          .writeln("      ${option.description.replaceAll('\n', '\n      ')}");
      buffer.writeln();
    }

    if (!verbose) {
      buffer.write('Pass "--verbose" to see more options.');
    }

    print(buffer);
  }

  _Option _findByAbbreviation(String abbreviation) {
    for (var option in _options) {
      if (abbreviation == option.abbreviation) return option;
    }

    return null;
  }

  _Option _findByName(String name) {
    for (var option in _options) {
      if (name == option.name) return option;

      // Allow hyphens instead of underscores as the separator since they are
      // more common for command line flags.
      if (name == option.name.replaceAll("_", "-")) return option;
    }

    return null;
  }
}
