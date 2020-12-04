// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:smith/smith.dart';
import 'package:test_runner/src/test_configurations.dart';
import 'package:path/path.dart' as path;

import 'configuration.dart';
import 'path.dart';
import 'repository.dart';
import 'utils.dart';

const _defaultTestSelectors = [
  'samples_2',
  'standalone_2',
  'corelib_2',
  'language_2',
  'vm',
  'benchmark_smoke',
  'utils',
  'lib_2',
  'analyze_library',
  'service_2',
  'kernel',
  'observatory_ui_2',
  'ffi_2'
];

/// Specifies a single command line option.
///
/// The name of the specification is used as the key for the option in the Map
/// returned from [OptionsParser.parse].
class _Option {
  // TODO(rnystrom): Some string options use "" to mean "no value" and others
  // use null. Clean that up.
  _Option(this.name, this.description,
      {String abbr,
      List<String> values,
      String defaultsTo,
      bool allowMultiple,
      bool hide})
      : abbreviation = abbr,
        values = values ?? [],
        defaultValue = defaultsTo,
        type = _OptionValueType.string,
        allowMultiple = allowMultiple ?? true,
        verboseOnly = hide ?? false;

  _Option.bool(this.name, this.description, {String abbr, bool hide})
      : abbreviation = abbr,
        values = [],
        defaultValue = false,
        type = _OptionValueType.bool,
        allowMultiple = false,
        verboseOnly = hide ?? false;

  _Option.int(this.name, this.description,
      {String abbr, int defaultsTo, bool hide})
      : abbreviation = abbr,
        values = [],
        defaultValue = defaultsTo,
        type = _OptionValueType.int,
        allowMultiple = false,
        verboseOnly = hide ?? false;

  final String name;
  final String description;
  final String abbreviation;
  final List<String> values;
  final Object defaultValue;
  final _OptionValueType type;

  /// Whether a comma-separated list of values is permitted.
  final bool allowMultiple;

  /// Only show this option in the verbose help.
  final bool verboseOnly;

  /// The shortest command line argument used to refer to this option.
  String get shortCommand => abbreviation != null ? "-$abbreviation" : command;

  /// The canonical long command line argument used to refer to this option.
  String get command => "--${name.replaceAll('_', '-')}";
}

enum _OptionValueType { bool, int, string }

/// Parses command line arguments and produces a test runner configuration.
class OptionsParser {
  static final List<_Option> _options = [
    _Option('mode', 'Mode in which to run the tests.',
        abbr: 'm', values: ['all', ...Mode.names]),
    _Option(
        'compiler',
        '''How the Dart code should be compiled or statically processed.
none:                 Do not compile the Dart code.
dart2js:              Compile to JavaScript using dart2js.
dart2analyzer:        Perform static analysis on Dart code using the analyzer.
compare_analyzer_cfe: Compare analyzer and common front end representations.
dartdevc:             Compile to JavaScript using dart2js.
dartdevk:             Compile to JavaScript using dartdevk.
app_jitk:             Compile the Dart code into Kernel and then into an app
                      snapshot.
dartk:                Compile the Dart code into Kernel before running test.
dartkp:               Compile the Dart code into Kernel and then Kernel into
                      AOT snapshot before running the test.
spec_parser:          Parse Dart code using the specification parser.

fasta:                Compile using CFE for errors, but do not run.
''',
        abbr: 'c',
        values: Compiler.names),
    _Option(
        'runtime',
        '''Where the tests should be run.
vm:               Run Dart code on the standalone Dart VM.
dart_precompiled: Run a precompiled snapshot on the VM without a JIT.
d8:               Run JavaScript from the command line using v8.
jsshell:          Run JavaScript from the command line using Firefox js-shell.

firefox:
chrome:
safari:
ie9:
ie10:
ie11:
chromeOnAndroid:  Run JavaScript in the specified browser.

self_check:       Pass each test or its compiled output to every file under
                  `pkg` whose name ends with `_self_check.dart`. Each test is
                  given to the self_check tester as a filename on stdin using
                  the batch-mode protocol.

none:             No runtime, compile only.''',
        abbr: 'r',
        values: Runtime.names),
    _Option(
        'arch',
        '''The architecture to run tests for.

Allowed values are:
all
ia32, x64
arm, armv6, arm64,
simarm, simarmv6, simarm64, arm_x64''',
        abbr: 'a',
        values: ['all', ...Architecture.names],
        defaultsTo: Architecture.x64.name,
        hide: true),
    _Option('system', 'The operating system to run tests on.',
        abbr: 's',
        values: ['all', ...System.names],
        defaultsTo: Platform.operatingSystem,
        hide: true),
    _Option('sanitizer', 'Sanitizer in which to run the tests.',
        defaultsTo: Sanitizer.none.name, values: ['all', ...Sanitizer.names]),
    _Option(
        'named_configuration',
        '''The named test configuration that supplies the values for all
test options, specifying how tests should be run.''',
        abbr: 'n',
        hide: true),
    _Option.bool(
        'build', 'Build the necessary targets to test this configuration'),
    // TODO(sigmund): rename flag once we migrate all dart2js bots to the test
    // matrix.
    _Option.bool('host_checked', 'Run compiler with assertions enabled.',
        hide: true),
    _Option.bool('minified', 'Enable minification in the compiler.',
        hide: true),
    _Option.bool('csp', 'Run tests under Content Security Policy restrictions.',
        hide: true),
    _Option.bool('fast_tests',
        'Only run tests that are not marked `Slow` or `Timeout`.'),
    _Option.bool('enable_asserts',
        'Pass the --enable-asserts flag to dart2js or to the vm.'),
    _Option.bool('use_cfe', 'Pass the --use-cfe flag to analyzer', hide: true),
    _Option.bool('analyzer_use_fasta_parser',
        'Pass the --use-fasta-parser flag to analyzer',
        hide: true),

    _Option.bool('hot_reload', 'Run hot reload stress tests.', hide: true),
    _Option.bool('hot_reload_rollback', 'Run hot reload rollback stress tests.',
        hide: true),
    _Option.bool(
        'use_blobs', 'Use mmap instead of shared libraries for precompilation.',
        hide: true),
    _Option.bool('use_elf',
        'Directly generate an ELF shared libraries for precompilation.',
        hide: true),
    _Option.bool('use_qemu', 'Use qemu to test arm32 on x64 host machines.',
        hide: true),
    _Option.bool('keep_generated_files', 'Keep any generated files.',
        abbr: 'k'),
    _Option.int('timeout', 'Timeout in seconds.', abbr: 't'),
    _Option(
        'progress',
        '''Progress indication mode.

Allowed values are:
compact, color, line, verbose, silent, status, buildbot''',
        abbr: 'p',
        values: Progress.names,
        defaultsTo: Progress.compact.name,
        allowMultiple: false),
    _Option('step_name', 'Step name for use by -pbuildbot.', hide: true),
    _Option.bool('report',
        'Print a summary report of the number of tests, by expectation.',
        hide: true),
    _Option.bool('report_failures', 'Print a summary of the tests that failed.',
        hide: true),
    _Option.int('tasks', 'The number of parallel tasks to run.',
        abbr: 'j', defaultsTo: Platform.numberOfProcessors),
    _Option.int('shards',
        'The number of instances that the tests will be sharded over.',
        defaultsTo: 1, hide: true),
    _Option.int(
        'shard', 'The index of this instance when running in sharded mode.',
        defaultsTo: 1, hide: true),
    _Option.bool('help', 'Print list of options.', abbr: 'h'),
    _Option.int('repeat', 'How many times each test is run', defaultsTo: 1),
    _Option.bool('verbose', 'Verbose output.', abbr: 'v'),
    _Option.bool('verify-ir', 'Verify kernel IR.', hide: true),
    _Option.bool('no-tree-shake', 'Disable kernel IR tree shaking.',
        hide: true),
    _Option.bool('list', 'List tests only, do not run them.'),
    _Option.bool('find-configurations', 'Find matching configurations.'),
    _Option.bool('list-configurations', 'Output list of configurations.'),
    _Option.bool('list_status_files',
        'List status files for test-suites. Do not run any test suites.',
        hide: true),
    _Option.bool('clean_exit', 'Exit 0 if tests ran and results were output.',
        hide: true),
    _Option.bool(
        'silent_failures',
        "Don't complain about failing tests. This is useful when in "
            "combination with --write-results.",
        hide: true),
    _Option.bool('report_in_json',
        'When listing with --list, output result summary in JSON.',
        hide: true),
    _Option.bool('time', 'Print timing information after running tests.'),
    _Option('dart', 'Path to dart executable.', hide: true),
    _Option('gen-snapshot', 'Path to gen_snapshot executable.', hide: true),
    _Option('firefox', 'Path to firefox browser executable.', hide: true),
    _Option('chrome', 'Path to chrome browser executable.', hide: true),
    _Option('safari', 'Path to safari browser executable.', hide: true),
    _Option.bool('use_sdk', '''Use compiler or runtime from the SDK.'''),
    _Option(
        'nnbd',
        '''Which set of non-nullable type features to use.

Allowed values are: legacy, weak, strong''',
        values: NnbdMode.names,
        defaultsTo: NnbdMode.legacy.name,
        allowMultiple: false),
    // TODO(rnystrom): This does not appear to be used. Remove?
    _Option('build_directory',
        'The name of the build directory, where products are placed.',
        hide: true),
    _Option('output_directory',
        'The name of the output directory for storing log files.',
        defaultsTo: "logs", hide: true),
    _Option.bool('noBatch', 'Do not run tests in batch mode.', hide: true),
    _Option.bool('dart2js_batch', 'Run dart2js tests in batch mode.',
        hide: true),
    _Option.bool('write_debug_log',
        'Don\'t write debug messages to stdout but rather to a logfile.',
        hide: true),
    _Option.bool(
        'write_results',
        'Write results to a "${TestUtils.resultsFileName}" json file '
            'located at the debug_output_directory.',
        hide: true),
    _Option.bool(
        'write_logs',
        'Include the stdout and stderr of tests that don\'t match expectations '
            'in the "${TestUtils.logsFileName}" file',
        hide: true),
    _Option.bool(
        'reset_browser_configuration',
        '''Browser specific reset of configuration.

Warning: Using this option may remove your bookmarks and other
settings.''',
        hide: true),
    _Option.bool(
        'copy_coredumps',
        '''If we see a crash that we did not expect, copy the core dumps to
"/tmp".''',
        hide: true),
    _Option.bool('rr', '''Run VM tests under rr and save traces from crashes''',
        hide: true),
    _Option(
        'local_ip',
        '''IP address the HTTP servers should listen on. This address is also
used for browsers to connect to.''',
        defaultsTo: '127.0.0.1',
        hide: true),
    _Option.int('test_server_port', 'Port for test http server.',
        defaultsTo: 0, hide: true),
    _Option.int('test_server_cross_origin_port',
        'Port for test http server cross origin.',
        defaultsTo: 0, hide: true),
    _Option.int('test_driver_port', 'Port for http test driver server.',
        defaultsTo: 0, hide: true),
    _Option.int(
        'test_driver_error_port', 'Port for http test driver server errors.',
        defaultsTo: 0, hide: true),
    _Option('test_list', 'File containing a list of tests to be executed.',
        hide: true),
    _Option('tests', 'A newline separated list of tests to be executed.'),
    _Option(
        'builder_tag',
        '''Machine specific options that is not captured by the regular test
options. Used to be able to make sane updates to the status files.''',
        hide: true),
    _Option('vm_options', 'Extra options to send to the VM when running.',
        hide: true),
    _Option('dart2js_options', 'Extra options for dart2js compilation step.',
        hide: true),
    _Option('shared_options', 'Extra shared options.', hide: true),
    _Option('enable-experiment', 'Experiment flags to enable.'),
    _Option(
        'babel',
        '''Transforms dart2js output with Babel. The value must be
Babel options JSON.''',
        hide: true),
    _Option('suite_dir', 'Additional directory to add to the testing matrix.',
        hide: true),
    _Option('package_root', 'The package root to use for testing.', hide: true),
    _Option('packages', 'The package spec file to use for testing.',
        hide: true),
    _Option(
        'exclude_suite',
        '''Exclude suites from default selector, only works when no selector
has been specified on the command line.''',
        hide: true),
    _Option.bool(
        'skip_compilation',
        '''
Skip the compilation step, using the compilation artifacts left in
the output folder from a previous run. This flag will often cause
false positives and negatives, but can be useful for quick and
dirty offline testing when not making changes that affect the
compiler.''',
        hide: true),
    _Option.bool('print_passing_stdout',
        'Print the stdout of passing, as well as failing, tests.',
        hide: true)
  ];

  /// For printing out reproducing command lines, we don't want to add these
  /// options.
  static final _denylistedOptions = {
    'build',
    'build_directory',
    'chrome',
    'clean_exit',
    'copy_coredumps',
    'dart',
    'debug_output_directory',
    'drt',
    'exclude_suite',
    'firefox',
    'local_ip',
    'output_directory',
    'progress',
    'repeat',
    'report',
    'report_failures',
    'safari',
    'shard',
    'shards',
    'silent_failures',
    'step_name',
    'tasks',
    'tests',
    'time',
    'verbose',
    'write_debug_log',
    'write_logs',
    'write_results',
  };

  /// The set of objects which the named configuration should imply.
  static const _namedConfigurationOptions = {
    'system',
    'arch',
    'mode',
    'compiler',
    'runtime',
    'timeout',
    'nnbd',
    'sanitizer',
    'enable_asserts',
    'use_cfe',
    'analyzer_use_fasta_parser',
    'use_elf',
    'use_sdk',
    'hot_reload',
    'hot_reload_rollback',
    'host_checked',
    'csp',
    'minified',
    'vm_options',
    'dart2js_options',
    'experiments',
    'babel',
    'builder_tag',
    'use_qemu'
  };

  /// Parses a list of strings as test options.
  ///
  /// Returns a list of configurations in which to run the tests.
  /// Configurations are maps mapping from option keys to values. When
  /// encountering the first non-option string, the rest of the arguments are
  /// stored in the returned Map under the 'rest' key.
  List<TestConfiguration> parse(List<String> arguments) {
    // Help supersedes all other arguments.
    if (arguments.contains("--help") || arguments.contains("-h")) {
      _printHelp(
          verbose: arguments.contains("--verbose") || arguments.contains("-v"));
      return null;
    }

    // Parse the command line arguments to a map.
    var options = <String, dynamic>{};
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
        var patterns = options.putIfAbsent("selectors", () => <String>[]);

        var allSuiteDirectories = [
          ...testSuiteDirectories,
          "tests/co19",
          "tests/co19_2",
        ];
        // Allow passing in the full relative path to a test or directory and
        // infer the selector from it. This lets users use tab completion on
        // the command line.
        for (var suiteDirectory in allSuiteDirectories) {
          var path = suiteDirectory.toString();
          if (arg.startsWith("$path/") || arg.startsWith("$path\\")) {
            arg = arg.substring(path.lastIndexOf("/") + 1);

            // Remove the `src/` subdirectories from the co19 and co19_2
            // directories that do not appear in the test names.
            if (arg.startsWith("co19")) {
              arg = arg.replaceFirst(RegExp("src[/\]"), "");
            }
            break;
          }
        }

        // If they tab complete to a single test, ignore the ".dart".
        if (arg.endsWith(".dart")) arg = arg.substring(0, arg.length - 5);

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
      if (options.containsKey(option.name)) {
        _fail('Already have value for command line option "$command".');
      }

      // Parse the value for the option.
      switch (option.type) {
        case _OptionValueType.bool:
          if (value != null) {
            _fail('Boolean flag "$command" does not take a value.');
          }

          options[option.name] = true;
          break;

        case _OptionValueType.int:
          try {
            options[option.name] = int.parse(value);
          } on FormatException {
            _fail('Integer value expected for option "$command".');
          }
          break;

        case _OptionValueType.string:
          // Validate against the allowed values.
          if (option.values.isNotEmpty) {
            validate(String value) {
              if (!option.values.contains(value)) {
                _fail('Unknown value "$value" for option "$command".');
              }
            }

            if (option.allowMultiple) {
              value.split(",").forEach(validate);
            } else {
              if (value.contains(",")) {
                _fail('Only a single value is allowed for option "$command".');
              }
              validate(value);
            }
          }

          // TODO(rnystrom): Store as a list instead of a comma-delimited
          // string.
          options[option.name] = value;
          break;
      }
    }

    if (options.containsKey('find-configurations')) {
      findConfigurations(options);
      return null;
    }

    if (options.containsKey('list-configurations')) {
      listConfigurations(options);
      return null;
    }

    // If a named configuration was specified ensure no other options, which are
    // implied by the named configuration, were specified.
    if (options['named_configuration'] is String) {
      for (var optionName in _namedConfigurationOptions) {
        if (options.containsKey(optionName)) {
          var namedConfig = options['named_configuration'];
          _fail("Can't pass '--$optionName' since it is determined by the "
              "named configuration '$namedConfig'.");
        }
      }
    }

    // Apply default values for unspecified options.
    for (var option in _options) {
      if (!options.containsKey(option.name)) {
        options[option.name] = option.defaultValue;
      }
    }

    // Fetch list of tests to run, if option is present.
    var testList = options['test_list'];
    if (testList is String) {
      options['test_list_contents'] = File(testList).readAsLinesSync();
    }

    var tests = options['tests'];
    if (tests is String) {
      if (options.containsKey('test_list_contents')) {
        _fail('--tests and --test-list cannot be used together');
      }
      options['test_list_contents'] = LineSplitter.split(tests).toList();
    }

    return _createConfigurations(options);
  }

  /// Given a set of parsed option values, returns the list of command line
  /// arguments that would reproduce that configuration.
  List<String> _reproducingCommand(
      Map<String, dynamic> data, bool usingNamedConfiguration) {
    var arguments = <String>[];

    for (var option in _options) {
      var name = option.name;
      if (!data.containsKey(name) ||
          _denylistedOptions.contains(name) ||
          (usingNamedConfiguration &&
              _namedConfigurationOptions.contains(name))) {
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

  List<TestConfiguration> _createConfigurations(
      Map<String, dynamic> configuration) {
    var selectors = _expandSelectors(configuration);

    // Put observatory_ui in a configuration with its own packages override.
    // Only one value in the configuration map is mutable:
    if (selectors.containsKey('observatory_ui')) {
      if (selectors.length == 1) {
        configuration['packages'] =
            Repository.uri.resolve('.packages').toFilePath();
      } else {
        // Make a new configuration whose selectors map only contains
        // observatory_ui, and remove observatory_ui from the original
        // selectors. The only mutable value in the map is the selectors, so a
        // shallow copy is safe.
        var observatoryConfiguration = Map<String, dynamic>.from(configuration);
        var observatorySelectors = {
          'observatory_ui': selectors['observatory_ui']
        };
        selectors.remove('observatory_ui');

        // Set the packages flag.
        observatoryConfiguration['packages'] =
            Repository.uri.resolve('.packages').toFilePath();

        return [
          ..._expandConfigurations(configuration, selectors),
          ..._expandConfigurations(
              observatoryConfiguration, observatorySelectors)
        ];
      }
    }

    return _expandConfigurations(configuration, selectors);
  }

  /// Recursively expands a configuration with multiple values per key into a
  /// list of configurations with exactly one value per key.
  List<TestConfiguration> _expandConfigurations(
      Map<String, dynamic> data, Map<String, RegExp> selectors) {
    var result = <TestConfiguration>[];

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
    var sharedOptions = listOption("shared_options");

    var experimentNames = data["enable-experiment"] as String;
    var experiments = [
      if (experimentNames != null) ...experimentNames.split(",")
    ];

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

    var systemName = data["system"] as String;
    if (systemName == "all") {
      _fail("Can only use '--system=all' with '--find-configurations'.");
    }
    var system = System.find(systemName);

    var runtimeNames = data["runtime"] as String;
    var runtimes = [
      if (runtimeNames != null) ...runtimeNames.split(",").map(Runtime.find)
    ];

    var compilerNames = data["compiler"] as String;
    var compilers = [
      if (compilerNames != null) ...compilerNames.split(",").map(Compiler.find)
    ];

    // Pick default compilers or runtimes if only one or the other is provided.
    if (runtimes.isEmpty) {
      if (compilers.isEmpty) {
        runtimes = [Runtime.vm];
        compilers = [Compiler.dartk];
      } else {
        // Pick a runtime for each compiler.
        runtimes.addAll(compilers.map((compiler) => compiler.defaultRuntime));
      }
    } else if (compilers.isEmpty) {
      // Pick a compiler for each runtime.
      compilers.addAll(runtimes.map((runtime) => runtime.defaultCompiler));
    }

    var progress = Progress.find(data["progress"] as String);
    var nnbdMode = NnbdMode.find(data["nnbd"] as String);

    void addConfiguration(Configuration innerConfiguration,
        [String namedConfiguration]) {
      var configuration = TestConfiguration(
          configuration: innerConfiguration,
          progress: progress,
          selectors: selectors,
          build: data["build"] as bool,
          testList: data["test_list_contents"] as List<String>,
          repeat: data["repeat"] as int,
          batch: !(data["noBatch"] as bool),
          batchDart2JS: data["dart2js_batch"] as bool,
          copyCoreDumps: data["copy_coredumps"] as bool,
          rr: data["rr"] as bool,
          isVerbose: data["verbose"] as bool,
          listTests: data["list"] as bool,
          listStatusFiles: data["list_status_files"] as bool,
          cleanExit: data["clean_exit"] as bool,
          silentFailures: data["silent_failures"] as bool,
          printTiming: data["time"] as bool,
          printReport: data["report"] as bool,
          reportFailures: data["report_failures"] as bool,
          reportInJson: data["report_in_json"] as bool,
          resetBrowser: data["reset_browser_configuration"] as bool,
          skipCompilation: data["skip_compilation"] as bool,
          writeDebugLog: data["write_debug_log"] as bool,
          writeResults: data["write_results"] as bool,
          writeLogs: data["write_logs"] as bool,
          drtPath: data["drt"] as String,
          chromePath: data["chrome"] as String,
          safariPath: data["safari"] as String,
          firefoxPath: data["firefox"] as String,
          dartPath: data["dart"] as String,
          dartPrecompiledPath: data["dart_precompiled"] as String,
          genSnapshotPath: data["gen-snapshot"] as String,
          keepGeneratedFiles: data["keep_generated_files"] as bool,
          taskCount: data["tasks"] as int,
          shardCount: data["shards"] as int,
          shard: data["shard"] as int,
          stepName: data["step_name"] as String,
          testServerPort: data["test_server_port"] as int,
          testServerCrossOriginPort:
              data['test_server_cross_origin_port'] as int,
          testDriverErrorPort: data["test_driver_error_port"] as int,
          localIP: data["local_ip"] as String,
          sharedOptions: sharedOptions,
          packages: data["packages"] as String,
          suiteDirectory: data["suite_dir"] as String,
          outputDirectory: data["output_directory"] as String,
          reproducingArguments:
              _reproducingCommand(data, namedConfiguration != null),
          fastTestsOnly: data["fast_tests"] as bool,
          printPassingStdout: data["print_passing_stdout"] as bool);

      if (configuration.validate()) {
        result.add(configuration);
      }
    }

    var namedConfigurationOption = data["named_configuration"] as String;
    if (namedConfigurationOption != null) {
      var namedConfigurations = namedConfigurationOption.split(',');
      var testMatrixFile = "tools/bots/test_matrix.json";
      var testMatrix = TestMatrix.fromPath(testMatrixFile);
      for (var namedConfiguration in namedConfigurations) {
        var configuration = testMatrix.configurations.singleWhere(
            (c) => c.name == namedConfiguration,
            orElse: () => null);
        if (configuration == null) {
          var names = testMatrix.configurations
              .map((configuration) => configuration.name)
              .toList();
          names.sort();
          _fail('The named configuration "$namedConfiguration" does not exist.'
              ' The following configurations are available:\n'
              '  * ${names.join('\n  * ')}');
        }
        addConfiguration(configuration);
      }
      return result;
    }

    // Expand runtimes.
    for (var runtime in runtimes) {
      // Expand architectures.
      var architectures = data["arch"] as String;
      if (architectures == "all") {
        architectures = "ia32,x64,simarm,simarm64";
      }

      for (var architectureName in architectures.split(",")) {
        var architecture = Architecture.find(architectureName);

        // Expand compilers.
        for (var compiler in compilers) {
          // Expand modes.
          var modes = (data["mode"] as String) ?? compiler.defaultMode.name;
          if (modes == "all") modes = "debug,release,product";
          for (var modeName in modes.split(",")) {
            var mode = Mode.find(modeName);
            // Expand sanitizers.
            var sanitizers = (data["sanitizer"] as String) ?? "none";
            if (sanitizers == "all") {
              sanitizers = "none,asan,lsan,msan,tsan,ubsan";
            }
            for (var sanitizerName in sanitizers.split(",")) {
              var sanitizer = Sanitizer.find(sanitizerName);
              var configuration = Configuration("custom configuration",
                  architecture, compiler, mode, runtime, system,
                  nnbdMode: nnbdMode,
                  sanitizer: sanitizer,
                  timeout: data["timeout"] as int,
                  enableAsserts: data["enable_asserts"] as bool,
                  useAnalyzerCfe: data["use_cfe"] as bool,
                  useAnalyzerFastaParser:
                      data["analyzer_use_fasta_parser"] as bool,
                  useElf: data["use_elf"] as bool,
                  useSdk: data["use_sdk"] as bool,
                  useHotReload: data["hot_reload"] as bool,
                  useHotReloadRollback: data["hot_reload_rollback"] as bool,
                  isHostChecked: data["host_checked"] as bool,
                  isCsp: data["csp"] as bool,
                  isMinified: data["minified"] as bool,
                  vmOptions: vmOptions,
                  dart2jsOptions: dart2jsOptions,
                  experiments: experiments,
                  babel: data['babel'] as String,
                  builderTag: data["builder_tag"] as String,
                  useQemu: data["use_qemu"] as bool);
              addConfiguration(configuration);
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
        var suitePath = Path(configuration['suite_dir'] as String);
        selectors = [suitePath.filename];
      } else if (configuration['test_list_contents'] != null) {
        selectors = (configuration['test_list_contents'] as List<String>)
            .map((t) => t.split('/').first)
            .toSet()
            .toList();
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
        _fail("Error: '$suite/$pattern'.  Only one test selection"
            " pattern is allowed to start with '$suite/'");
      }
      selectorMap[suite] = RegExp(pattern);
    }

    return selectorMap;
  }

  /// Print out usage information.
  void _printHelp({bool verbose}) {
    var buffer = StringBuffer();

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

/// Exception thrown when the arguments could not be parsed.
class OptionParseException implements Exception {
  final String message;

  OptionParseException(this.message);
}

/// Prints the names of the configurations in the test matrix that match the
/// given filter options.
///
/// If any of the options `--system`, `--arch`, `--mode`, `--compiler`,
/// `--nnbd`, or `--runtime` (or their abbreviations) are passed, then only
/// configurations matching those are shown.
void findConfigurations(Map<String, dynamic> options) {
  var testMatrix = TestMatrix.fromPath('tools/bots/test_matrix.json');

  // Default to only showing configurations for the current machine.
  var systemOption = options['system'] as String;
  var system = System.host;
  if (systemOption == 'all') {
    system = null;
  } else if (systemOption != null) {
    system = System.find(systemOption);
  }

  var architectureOption = options['arch'] as String;
  var architectures = const [Architecture.x64];
  if (architectureOption == 'all') {
    architectures = null;
  } else if (architectureOption != null) {
    architectures =
        architectureOption.split(',').map(Architecture.find).toList();
  }

  var mode = Mode.release;
  if (options.containsKey('mode')) {
    mode = Mode.find(options['mode'] as String);
  }

  Compiler compiler;
  if (options.containsKey('compiler')) {
    compiler = Compiler.find(options['compiler'] as String);
  }

  Runtime runtime;
  if (options.containsKey('runtime')) {
    runtime = Runtime.find(options['runtime'] as String);
  }

  NnbdMode nnbdMode;
  if (options.containsKey('nnbd')) {
    nnbdMode = NnbdMode.find(options['nnbd'] as String);
  }

  var names = <String>[];
  for (var configuration in testMatrix.configurations) {
    if (system != null && configuration.system != system) continue;
    if (architectures != null &&
        !architectures.contains(configuration.architecture)) {
      continue;
    }
    if (mode != null && configuration.mode != mode) continue;
    if (compiler != null && configuration.compiler != compiler) continue;
    if (runtime != null && configuration.runtime != runtime) continue;
    if (nnbdMode != null && configuration.nnbdMode != nnbdMode) continue;

    names.add(configuration.name);
  }

  names.sort();

  var filters = [
    if (system != null) "system=$system",
    if (architectures != null) "arch=${architectures.join(',')}",
    if (mode != null) "mode=$mode",
    if (compiler != null) "compiler=$compiler",
    if (runtime != null) "runtime=$runtime",
    if (nnbdMode != null) "nnbd=$nnbdMode",
  ];

  if (filters.isEmpty) {
    print("All configurations:");
  } else {
    print("Configurations where ${filters.join(', ')}:");
  }

  for (var name in names) {
    print("- $name");
  }
}

/// Prints the names of the configurations in the test matrix.
void listConfigurations(Map<String, dynamic> options) {
  var testMatrix = TestMatrix.fromPath('tools/bots/test_matrix.json');

  var names = testMatrix.configurations
      .map((configuration) => configuration.name)
      .toList();
  names.sort();
  names.forEach(print);
}

/// Throws an [OptionParseException] with [message].
void _fail(String message) {
  throw OptionParseException(message);
}

// Returns a map of environment variables to be used with sanitizers.
final Map<String, String> sanitizerEnvironmentVariables = (() {
  final environment = <String, String>{};
  final testMatrixFile = "tools/bots/test_matrix.json";
  final config = json.decode(File(testMatrixFile).readAsStringSync());
  config['sanitizer_options'].forEach((String key, dynamic value) {
    environment[key] = value as String;
  });
  var symbolizerPath =
      config['sanitizer_symbolizer'][Platform.operatingSystem] as String;
  if (symbolizerPath != null) {
    symbolizerPath = path.join(Directory.current.path, symbolizerPath);
    environment['ASAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['LSAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['MSAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['TSAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['UBSAN_SYMBOLIZER_PATH'] = symbolizerPath;
  }

  return environment;
})();
