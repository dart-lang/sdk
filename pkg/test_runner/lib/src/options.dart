// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'configuration.dart';
import 'path.dart';
import 'repository.dart';
import 'test_configurations.dart';
import 'utils.dart';

const _legacyTestSelectors = [
  'corelib_2',
  'ffi_2',
  'language_2',
  'lib_2',
  'kernel',
  'utils',
  'vm',
];

const _defaultTestSelectors = [
  'corelib',
  'ffi',
  'kernel',
  'language',
  'lib',
  'samples',
  'service',
  'standalone',
  'utils',
  'vm',
];

extension _IntOption on ArgParser {
  void addIntegerOption(String name,
      {String? abbr,
      String? help,
      String? valueHelp,
      Iterable<String>? allowed,
      Map<String, String>? allowedHelp,
      String? defaultsTo,
      bool mandatory = false,
      bool hide = false,
      List<String> aliases = const []}) {
    addOption(name,
        abbr: abbr,
        help: help,
        valueHelp: valueHelp,
        allowed: allowed,
        allowedHelp: allowedHelp,
        defaultsTo: defaultsTo, callback: (value) {
      if (value != null) {
        int.tryParse(value) ??
            _fail('Integer value expected for option "--$name".');
      }
    }, mandatory: mandatory, hide: hide, aliases: aliases);
  }
}

/// Parses command line arguments and produces a test runner configuration.
class OptionsParser {
  /// Allows tests to specify a custom test matrix.
  final String _testMatrixFile;

  OptionsParser([this._testMatrixFile = 'tools/bots/test_matrix.json']);

  static final ArgParser parser = ArgParser()
    ..addMultiOption('mode',
        abbr: 'm',
        allowed: ['all', ...Mode.names],
        help: 'Mode in which to run the tests.')
    ..addMultiOption('compiler',
        abbr: 'c',
        allowed: Compiler.names,
        help: '''How the Dart code should be compiled or statically processed.
dart2js:              Compile to JavaScript using dart2js.
dart2analyzer:        Perform static analysis on Dart code using the analyzer.
compare_analyzer_cfe: Compare analyzer and common front end representations.
ddc:                  Compile to JavaScript using dartdevc.
app_jitk:             Compile the Dart code into Kernel and then into an app
                      snapshot.
dartk:                Compile the Dart code into Kernel before running test.
dartkp:               Compile the Dart code into Kernel and then Kernel into
                      AOT snapshot before running the test.
spec_parser:          Parse Dart code using the specification parser.
fasta:                Compile using CFE for errors, but do not run.
''')
    ..addMultiOption('runtime',
        abbr: 'r',
        allowed: Runtime.names,
        help: '''Where the tests should be run.
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

none:             No runtime, compile only.''')
    ..addMultiOption('arch',
        abbr: 'a',
        allowed: ['all', ...Architecture.names],
        defaultsTo: [Architecture.host.name],
        hide: true,
        help: '''The architecture to run tests for.

Allowed values are:
all
ia32, x64
arm, arm64, simarm, simarm64, arm_x64
riscv32, riscv64, simriscv32, simriscv64''')
    ..addOption('system',
        abbr: 's',
        allowed: ['all', ...System.names],
        defaultsTo: Platform.operatingSystem,
        hide: true,
        help: 'The operating system to run tests on.')
    ..addMultiOption('sanitizer',
        allowed: ['all', ...Sanitizer.names],
        defaultsTo: [Sanitizer.none.name],
        help: 'Sanitizer in which to run the tests.')
    ..addMultiOption('named-configuration',
        abbr: 'n',
        aliases: ['named_configuration'],
        hide: true,
        help: '''The named test configuration that supplies the values for all
test options, specifying how tests should be run.''')
    ..addFlag('detect-host',
        aliases: ['detect_host'],
        help: 'Replace the system and architecture options in named '
            'configurations to match the local host. Provided only as a '
            'convenience when running tests locally. It is an error use this '
            'flag with without specifying a named configuration.')
    ..addFlag('build',
        help: 'Build the necessary targets to test this configuration')
    // TODO(sigmund): rename flag once we migrate all dart2js bots to the test
    // matrix.
    ..addFlag('host-checked',
        aliases: ['host_checked'],
        hide: true,
        help: 'Run compiler with assertions enabled.')
    ..addFlag('minified',
        hide: true, help: 'Enable minification in the compiler.')
    ..addFlag('csp',
        hide: true,
        help: 'Run tests under Content Security Policy restrictions.')
    ..addFlag('fast-tests',
        aliases: ['fast_tests'],
        hide: true,
        help: 'Only run tests that are not marked `Slow` or `Timeout`.')
    ..addFlag('enable-asserts',
        aliases: ['enable_asserts'],
        help: 'Pass the --enable-asserts flag to dart2js or to the vm.')
    ..addFlag('use-cfe',
        aliases: ['use_cfe'],
        hide: true,
        help: 'Pass the --use-cfe flag to analyzer')
    ..addFlag('analyzer-use-fasta-parser',
        aliases: ['analyzer_use_fasta_parser'],
        hide: true,
        help: 'Pass the --use-fasta-parser flag to analyzer')
    ..addFlag('hot-reload', hide: true, help: 'Run hot reload stress tests.')
    ..addFlag('hot-reload-rollback',
        hide: true, help: 'Run hot reload rollback stress tests.')
    ..addFlag('use-blobs',
        aliases: ['use_blobs'],
        hide: true,
        help: 'Use mmap instead of shared libraries for precompilation.')
    ..addFlag(
      'use-elf',
      aliases: ['use_elf'],
      hide: true,
      help: 'Directly generate an ELF shared libraries for precompilation.',
    )
    ..addFlag('use-qemu',
        aliases: ['use_qemu'],
        hide: true,
        help: 'Use qemu to test arm32 on x64 host machines.')
    ..addFlag('keep-generated-files',
        abbr: 'k', hide: true, help: 'Keep any generated files.')
    ..addIntegerOption('timeout', abbr: 't', help: 'Timeout in seconds.')
    ..addOption('progress',
        abbr: 'p',
        allowed: Progress.names,
        defaultsTo: Progress.compact.name,
        help: '''Progress indication mode.

Allowed values are:
compact, color, line, verbose, silent, status, buildbot''')
    ..addOption('step-name',
        aliases: ['step_name'],
        hide: true,
        help: 'Step name for use by -pbuildbot.')
    ..addFlag('report',
        hide: true,
        help: 'Print a summary report of the number of tests, by expectation.')
    ..addFlag('report-failures',
        aliases: ['report_failures'],
        hide: true,
        help: 'Print a summary of the tests that failed.')
    ..addOption('tasks',
        abbr: 'j',
        defaultsTo: Platform.numberOfProcessors.toString(),
        help: 'The number of parallel tasks to run.')
    ..addIntegerOption('shards',
        defaultsTo: '1',
        hide: true,
        help: 'The number of instances that the tests will be sharded over.')
    ..addIntegerOption('shard',
        defaultsTo: '1',
        hide: true,
        help: 'The index of this instance when running in sharded mode.')
    ..addFlag('help', abbr: 'h', help: 'Print list of options.')
    ..addIntegerOption('repeat',
        defaultsTo: '1', help: 'How many times each test is run')
    ..addFlag('verbose', abbr: 'v', help: 'Verbose output.')
    ..addFlag('verify-ir',
        aliases: ['verify_ir'], hide: true, help: 'Verify kernel IR.')
    ..addFlag('no-tree-shake',
        aliases: ['no_tree_shake'],
        hide: true,
        help: 'Disable kernel IR tree shaking.')
    ..addFlag('list', help: 'List tests only, do not run them.')
    ..addFlag('find-configurations',
        aliases: ['find_configurations'], help: 'Find matching configurations.')
    ..addFlag('list-configurations',
        aliases: ['list_configurations'],
        help: 'Output list of configurations.')
    ..addFlag('list-status-files',
        aliases: ['list_status_files'],
        hide: true,
        help: 'List status files for test suites. Do not run any test suites.')
    ..addFlag('clean-exit',
        aliases: ['clean_exit'],
        hide: true,
        help: 'Exit 0 if tests ran and results were output.')
    ..addFlag('silent-failures',
        aliases: ['silent_failures'],
        hide: true,
        help: "Don't complain about failing tests. This is useful when in "
            "combination with --write-results.")
    ..addFlag('report-in-json',
        aliases: ['report_in_json'],
        hide: true,
        help: 'When listing with --list, output result summary in JSON.')
    ..addFlag('time', help: 'Print timing information after running tests.')
    ..addOption('dart', hide: true, help: 'Path to dart executable.')
    ..addOption('gen-snapshot',
        aliases: ['gen_snapshot'],
        hide: true,
        help: 'Path to gen_snapshot executable.')
    ..addOption('firefox',
        hide: true, help: 'Path to firefox browser executable.')
    ..addOption('chrome',
        hide: true, help: 'Path to chrome browser executable.')
    ..addOption('safari',
        hide: true, help: 'Path to safari browser executable.')
    ..addFlag('use-sdk',
        aliases: ['use_sdk'], help: 'Use compiler or runtime from the SDK.')
    ..addOption('nnbd',
        allowed: NnbdMode.names,
        defaultsTo: NnbdMode.strong.name,
        help: '''Which set of non-nullable type features to use.

Allowed values are: legacy, weak, strong''')
    ..addOption('output-directory',
        aliases: ['output_directory'],
        defaultsTo: "logs",
        hide: true,
        help: 'The name of the output directory for storing log files.')
    ..addFlag('no-batch',
        aliases: ['no_batch'],
        hide: true,
        help: "Don't run tests in batch mode.")
    ..addFlag('write-debug-log',
        aliases: ['write_debug_log'],
        hide: true,
        help: "Don't write debug messages to stdout but rather to a logfile.")
    ..addFlag('write-results',
        aliases: ['write_results'],
        hide: true,
        help: 'Write results to a "${TestUtils.resultsFileName}" json file '
            'located at the debug-output-directory.')
    ..addFlag('write-logs',
        aliases: ['write_logs'],
        hide: true,
        help: 'Write failing test stdout and stderr to the '
            '"${TestUtils.logsFileName}" file')
    ..addFlag('reset-browser-configuration',
        aliases: ['reset_browser_configuration'],
        hide: true,
        help: '''Browser specific reset of configuration.

Warning: Using this option may remove your bookmarks and other
settings.''')
    ..addFlag('copy-coredumps',
        aliases: ['copy_coredumps'],
        hide: true,
        help: 'Copy core dumps to "/tmp" when an unexpected crash occurs.')
    ..addFlag('rr',
        hide: true,
        help: '''Run VM tests under rr and save traces from crashes''')
    ..addOption('local-ip',
        aliases: ['local_ip'],
        hide: true,
        help: '''IP address the HTTP servers should listen on. This address is
also used for browsers to connect to.''',
        defaultsTo: '127.0.0.1')
    ..addIntegerOption('test-server-port',
        aliases: ['test_server_port'],
        hide: true,
        defaultsTo: '0',
        help: 'Port for test http server.')
    ..addIntegerOption('test-server-cross-origin-port',
        aliases: ['test_server_cross_origin_port'],
        hide: true,
        help: 'Port for test http server cross origin.',
        defaultsTo: '0')
    ..addIntegerOption('test-driver-error-port',
        aliases: ['test_driver_error_port'],
        hide: true,
        help: 'Port for http test driver server errors.',
        defaultsTo: '0')
    ..addOption('test-list',
        aliases: ['test_list'],
        hide: true,
        help: 'File containing a list of tests to be executed.')
    ..addOption('tests',
        help: 'A newline separated list of tests to be executed.')
    ..addOption('builder-tag',
        aliases: ['builder_tag'],
        help:
            '''Machine specific options that is not captured by the regular test
options. Used to be able to make sane updates to the status files.''',
        hide: true)
    ..addMultiOption('vm-options',
        aliases: ['vm_options'],
        hide: true,
        help: 'Extra options to send to the VM when running.')
    ..addMultiOption('dart2js-options',
        aliases: ['dart2js_options'],
        hide: true,
        help: 'Extra options for dart2js compilation step.')
    ..addMultiOption('ddc-options',
        aliases: ['ddc_options'],
        hide: true,
        help: 'Extra command line options passed to the DDC compiler.')
    ..addMultiOption('shared-options',
        aliases: ['shared_options'], hide: true, help: 'Extra shared options.')
    ..addMultiOption('enable-experiment',
        aliases: ['experiments', 'enable_experiment'],
        help: 'Experiment flags to enable.')
    ..addOption('babel',
        help: '''Transforms dart2js output with Babel. The value must be
Babel options JSON.''',
        hide: true)
    ..addFlag('default-suites',
        hide: true,
        help: 'Include the default suites in addition to the requested suites.')
    ..addOption('suite-dir',
        aliases: ['suite_dir'],
        hide: true,
        help: 'Additional directory to add to the testing matrix.')
    ..addOption('packages',
        hide: true, help: 'The package spec file to use for testing.')
    ..addOption('exclude-suite',
        aliases: ['exclude_suite'],
        hide: true,
        help:
            '''Exclude suites from default selector, only works when no selector
has been specified on the command line.''')
    ..addFlag('print-passing-stdout',
        aliases: ['print_passing_stdout'],
        hide: true,
        help: 'Print the stdout of passing, as well as failing, tests.')
    ..addOption('service-response-sizes-directory',
        aliases: ['service_response_sizes_directory'],
        hide: true,
        help:
            'Log VM service response size CSV files in the provided directory');

  /// For printing out reproducing command lines, we don't want to add these
  /// options.
  static const _denylistedOptions = {
    'build',
    'build-directory',
    'chrome',
    'clean-exit',
    'copy-coredumps',
    'dart',
    'debug-output-directory',
    'default-suites',
    'drt',
    'exclude-suite',
    'firefox',
    'local-ip',
    'output-directory',
    'progress',
    'repeat',
    'report',
    'report-failures',
    'reset-browser-configuration',
    'safari',
    'shard',
    'shards',
    'silent-failures',
    'step-name',
    'tasks',
    'tests',
    'time',
    'verbose',
    'write-debug-log',
    'write-logs',
    'write-results',
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
    'enable-asserts',
    'use-cfe',
    'analyzer-use-fasta-parser',
    'use-elf',
    'use-sdk',
    'hot-reload',
    'hot-reload-rollback',
    'host-checked',
    'csp',
    'minified',
    'vm-options',
    'dart2js_options',
    'experiments',
    'babel',
    'builder-tag',
    'use-qemu'
  };

  /// Parses a list of strings as test options.
  ///
  /// Returns a list of configurations in which to run the tests.
  /// Configurations are maps mapping from option keys to values. When
  /// encountering the first non-option string, the rest of the arguments are
  /// stored in the returned Map under the 'rest' key.
  List<TestConfiguration> parse(List<String> arguments) {
    late ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (error) {
      _fail(error.message);
    }
    if (results['help'] as bool) {
      _printHelp(verbose: results['verbose'] as bool);
      return const [];
    }
    var options = {for (var option in results.options) option: results[option]};

    if (options['find-configurations'] as bool) {
      findConfigurations(options);
      return const [];
    }

    if (options['list-configurations'] as bool) {
      listConfigurations(options);
      return const [];
    }

    // If a named configuration was specified ensure no other options, which are
    // implied by the named configuration, were specified.
    if (options['named-configuration'] is String) {
      for (var optionName in _namedConfigurationOptions) {
        if (results.wasParsed(optionName)) {
          var namedConfig = options['named-configuration'];
          _fail("Can't pass '--$optionName' since it is determined by the "
              "named configuration '$namedConfig'.");
        }
      }
    }

    var allSuiteDirectories = [
      ...testSuiteDirectories,
      Path('tests/co19'),
      Path('tests/co19_2'),
    ];

    var selectors = <String>[];
    for (var selector in results.rest) {
      // Allow passing in the full relative path to a test or directory and
      // infer the selector from it. This lets users use tab completion on
      // the command line.
      for (var suiteDirectory in allSuiteDirectories) {
        var path = suiteDirectory.toString();
        final separator = Platform.pathSeparator;
        if (separator != '/') {
          selector = selector.replaceAll(separator, '/');
        }
        if (selector.startsWith('$path/')) {
          selector = selector.substring(path.lastIndexOf('/') + 1);

          // Remove the `src/` subdirectories from the co19 and co19_2
          // directories that do not appear in the test names.
          if (selector.startsWith('co19')) {
            selector = selector.replaceFirst(RegExp('src/'), '');
          }
          break;
        }
      }

      // If they tab complete to a single test, ignore the ".dart".
      if (selector.endsWith('.dart')) {
        selector = selector.substring(0, selector.length - 5);
      }

      selectors.add(selector);
    }
    options['selectors'] = selectors;

    // Fetch list of tests to run, if option is present.
    var testList = options['test_list'];
    if (testList is String) {
      options['test-list-contents'] = File(testList).readAsLinesSync();
    }

    var tests = options['tests'];
    if (tests is String) {
      if (options.containsKey('test-list-contents')) {
        _fail('--tests and --test-list cannot be used together');
      }
      options['test-list-contents'] = LineSplitter.split(tests).toList();
    }

    return _expandConfigurations(options);
  }

  /// Given a set of parsed option values, returns the list of command line
  /// arguments that would reproduce that configuration.
  List<String> _reproducingCommand(
      Map<String, dynamic> data, bool usingNamedConfiguration) {
    var arguments = <String>[];

    for (var option in parser.options.values) {
      var name = option.name;
      if (!data.containsKey(name) ||
          _denylistedOptions.contains(name) ||
          (usingNamedConfiguration &&
              _namedConfigurationOptions.contains(name))) {
        continue;
      }

      var value = data[name];
      if (data[name] == option.defaultsTo ||
          (name == 'packages' &&
              value ==
                  Repository.uri
                      .resolve('.dart_tool/package_config.json')
                      .toFilePath())) {
        continue;
      }

      if (option.abbr != null) {
        arguments.add('-${option.abbr}');
      } else {
        arguments.add('--${option.name}');
      }
      if (value is String) {
        arguments.add(value);
      } else if (value is List<String>) {
        arguments.add(value.join(','));
      }
    }

    return arguments;
  }

  /// Recursively expands a configuration with multiple values per key into a
  /// list of configurations with exactly one value per key.
  List<TestConfiguration> _expandConfigurations(Map<String, dynamic> data) {
    var result = <TestConfiguration>[];

    // Handles a string option containing a space-separated list of words.
    listOption(String name) {
      var value = data[name] as List<String>;
      return value
          .expand((element) => element
              .split(" ")
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty))
          .toList();
    }

    var dart2jsOptions = listOption("dart2js-options");
    var ddcOptions = listOption("ddc-options");
    var vmOptions = listOption("vm-options");
    var sharedOptions = listOption("shared-options");
    var experiments = data["enable-experiment"] as List<String>?;

    // JSON reporting implies listing and reporting.
    if (data['report-in-json'] as bool) {
      data['list'] = true;
      data['report'] = true;
    }

    // Use verbose progress indication for verbose output unless buildbot
    // progress indication is requested.
    if ((data['verbose'] as bool) &&
        (data['progress'] as String?) != 'buildbot') {
      data['progress'] = 'verbose';
    }

    var systemName = data["system"] as String;
    if (systemName == "all") {
      _fail("Can only use '--system=all' with '--find-configurations'.");
    }
    var system = System.find(systemName);
    var runtimes = [...(data["runtime"] as List<String>).map(Runtime.find)];
    var compilers = [...(data["compiler"] as List<String>).map(Compiler.find)];

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
        [String? namedConfiguration]) {
      var configuration = TestConfiguration(
          configuration: innerConfiguration,
          progress: progress,
          selectors: _expandSelectors(data, innerConfiguration.nnbdMode),
          build: data["build"] as bool,
          testList: data["test-list-contents"] as List<String>?,
          repeat: int.parse(data["repeat"] as String),
          batch: !(data["no-batch"] as bool),
          copyCoreDumps: data["copy-coredumps"] as bool,
          rr: data["rr"] as bool,
          isVerbose: data["verbose"] as bool,
          listTests: data["list"] as bool,
          listStatusFiles: data["list-status-files"] as bool,
          cleanExit: data["clean-exit"] as bool,
          silentFailures: data["silent-failures"] as bool,
          printTiming: data["time"] as bool,
          printReport: data["report"] as bool,
          reportFailures: data["report-failures"] as bool,
          reportInJson: data["report-in-json"] as bool,
          resetBrowser: data["reset-browser-configuration"] as bool,
          writeDebugLog: data["write-debug-log"] as bool,
          writeResults: data["write-results"] as bool,
          writeLogs: data["write-logs"] as bool,
          drtPath: data["drt"] as String?,
          chromePath: data["chrome"] as String?,
          safariPath: data["safari"] as String?,
          firefoxPath: data["firefox"] as String?,
          dartPath: data["dart"] as String?,
          dartPrecompiledPath: data["dart-precompiled"] as String?,
          genSnapshotPath: data["gen-snapshot"] as String?,
          keepGeneratedFiles: data["keep-generated-files"] as bool,
          taskCount: int.parse(data["tasks"] as String),
          shardCount: int.parse(data["shards"] as String),
          shard: int.parse(data["shard"] as String),
          stepName: data["step-name"] as String?,
          testServerPort: int.parse(data['test-server-port'] as String),
          testServerCrossOriginPort:
              int.parse(data['test-server-cross-origin-port'] as String),
          testDriverErrorPort:
              int.parse(data['test-driver-error-port'] as String),
          localIP: data["local-ip"] as String,
          sharedOptions: <String>[
            ...sharedOptions,
            "-Dtest_runner.configuration=${innerConfiguration.name}"
          ],
          packages: data["packages"] as String?,
          serviceResponseSizesDirectory:
              data['service-response-sizes-directory'] as String?,
          suiteDirectory: data["suite-dir"] as String?,
          outputDirectory: data["output-directory"] as String,
          reproducingArguments:
              _reproducingCommand(data, namedConfiguration != null),
          fastTestsOnly: data["fast-tests"] as bool,
          printPassingStdout: data["print-passing-stdout"] as bool);

      if (configuration.validate()) {
        result.add(configuration);
      } else if (namedConfiguration != null) {
        _fail('The named configuration "$namedConfiguration" is invalid.');
      }
    }

    var namedConfigurations = data["named-configuration"] as List<String>;
    var detectHost = data['detect-host'] as bool;
    if (detectHost && namedConfigurations.isEmpty) {
      _fail('The `--detect-host` flag is only supported for named '
          'configurations.');
    }
    if (namedConfigurations.isNotEmpty) {
      var testMatrix = TestMatrix.fromPath(_testMatrixFile);
      for (var namedConfiguration in namedConfigurations) {
        try {
          var configuration = testMatrix.configurations
              .singleWhere((c) => c.name == namedConfiguration);
          if (configuration.system != System.host ||
              configuration.architecture != Architecture.host) {
            print("-- WARNING -- \n"
                "The provided named configuration does not match the host "
                "system or architecture:\n"
                "    ${configuration.name}");
            if (detectHost) {
              configuration = Configuration.detectHost(configuration);
              print("Detecting host configuration:\n"
                  "    $configuration");
            } else {
              print("Passing the `--detect-host` flag will modify the named "
                  "configuration to match the local system and architecture.");
            }
          }
          addConfiguration(configuration, namedConfiguration);
        } on StateError {
          var names = testMatrix.configurations
              .map((configuration) => configuration.name)
              .toList()
            ..sort();
          _fail('The named configuration "$namedConfiguration" does not exist.'
              ' The following configurations are available:\n'
              '  * ${names.join('\n  * ')}');
        }
      }
      return result;
    }

    var modes = data['mode'] as List<String>;
    if (modes.contains('all')) {
      modes = Mode.names;
    }
    // Expand runtimes.
    var configurationNumber = 1;
    for (var runtime in runtimes) {
      // Expand architectures.
      var architectures = data["arch"] as List<String>;
      if (architectures.contains("all")) {
        architectures = [
          "ia32",
          "x64",
          "x64c",
          "simarm",
          "simarm64",
          "simarm64c",
          "simriscv32",
          "simriscv64"
        ];
      }

      for (var architectureName in architectures) {
        var architecture = Architecture.find(architectureName);

        // Expand compilers.
        for (var compiler in compilers) {
          // Expand modes.
          for (var modeName
              in modes.isEmpty ? [compiler.defaultMode.name] : modes) {
            var mode = Mode.find(modeName);
            // Expand sanitizers.
            var sanitizers = data["sanitizer"] as List<String>;
            if (sanitizers.contains("all")) {
              sanitizers = Sanitizer.names;
            }
            for (var sanitizerName in sanitizers) {
              var sanitizer = Sanitizer.find(sanitizerName);
              var timeout = data["timeout"] != null
                  ? int.parse(data["timeout"] as String)
                  : null;
              var configuration = Configuration(
                  "custom-configuration-${configurationNumber++}",
                  architecture,
                  compiler,
                  mode,
                  runtime,
                  system,
                  nnbdMode: nnbdMode,
                  sanitizer: sanitizer,
                  timeout: timeout,
                  enableAsserts: data['enable-asserts'] as bool,
                  useAnalyzerCfe: data["use-cfe"] as bool,
                  useAnalyzerFastaParser:
                      data["analyzer-use-fasta-parser"] as bool,
                  useElf: data["use-elf"] as bool,
                  useSdk: data["use-sdk"] as bool,
                  useHotReload: data["hot-reload"] as bool,
                  useHotReloadRollback: data["hot-reload-rollback"] as bool,
                  isHostChecked: data["host-checked"] as bool,
                  isCsp: data["csp"] as bool,
                  isMinified: data["minified"] as bool,
                  vmOptions: vmOptions,
                  dart2jsOptions: dart2jsOptions,
                  ddcOptions: ddcOptions,
                  experiments: experiments,
                  babel: data['babel'] as String?,
                  builderTag: data["builder-tag"] as String?,
                  useQemu: data["use-qemu"] as bool);
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
  Map<String, RegExp> _expandSelectors(
      Map<String, dynamic> configuration, NnbdMode nnbdMode) {
    var selectors = configuration['selectors'] as List<String>? ?? [];

    if (selectors.isEmpty || configuration['default-suites'] as bool) {
      if (configuration['suite-dir'] != null) {
        var suitePath = Path(configuration['suite-dir'] as String);
        selectors.add(suitePath.filename);
      } else if (configuration['test-list-contents'] != null) {
        selectors = (configuration['test-list-contents'] as List<String>)
            .map((t) => t.split('/').first)
            .toSet()
            .toList();
      } else {
        if (nnbdMode == NnbdMode.legacy) {
          selectors.addAll(_legacyTestSelectors);
        } else {
          selectors.addAll(_defaultTestSelectors);
        }
      }

      var excludeSuites = configuration['exclude-suite'] != null
          ? (configuration['exclude-suite'] as String).split(',')
          : [];
      for (var exclude in excludeSuites) {
        if (selectors.contains(exclude)) {
          selectors.remove(exclude);
        } else {
          print("Warning: default selectors does not contain $exclude");
        }
      }
    }

    var selectorMap = <String, RegExp>{};
    for (var i = 0; i < selectors.length; i++) {
      var pattern = selectors[i];
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
  void _printHelp({bool verbose = false}) {
    print('''The Dart SDK's internal test runner.

    Usage: dart tools/test.dart [options] [selector]

The optional selector limits the tests that will be run. For example, the
selector "language/issue", or equivalently "language/*issue*", limits to test
files matching the regexp ".*issue.*\\.dart" in the "tests/language" directory.

If you specify only a runtime ("-r"), then an appropriate default compiler will
be chosen for that runtime. Likewise, if you specify only a compiler ("-c"),
then a matching runtime is chosen. If neither compiler nor runtime is selected,
the test is run directly from source on the VM.

Options:''');

    print(parser.usage);
  }
}

/// Exception thrown when the arguments could not be parsed.
class OptionParseException implements Exception {
  final String message;

  OptionParseException(this.message);

  @override
  String toString() => "OptionParseException: $message";
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
  var systemOption = options['system'] as String?;
  System? system = System.host;
  if (systemOption == 'all') {
    system = null;
  } else if (systemOption != null) {
    system = System.find(systemOption);
  }

  var architectureOption = options['arch'] as List<String>;
  var architectures = [
    if (architectureOption.isEmpty)
      Architecture.host
    else if (!architectureOption.contains('all'))
      ...architectureOption.map(Architecture.find)
  ];

  var modes = [
    if (options.containsKey('mode'))
      ...(options['mode'] as List<String>).map(Mode.find)
    else
      Mode.release
  ];
  var compilers = [...(options['compiler'] as List<String>).map(Compiler.find)];
  var runtimes = [...(options['runtime'] as List<String>).map(Runtime.find)];

  NnbdMode? nnbdMode;
  if (options.containsKey('nnbd')) {
    nnbdMode = NnbdMode.find(options['nnbd'] as String);
  }

  var names = SplayTreeSet<String>();
  for (var configuration in testMatrix.configurations) {
    if (system != null && configuration.system != system) continue;
    if (architectures.isNotEmpty &&
        !architectures.contains(configuration.architecture)) {
      continue;
    }
    if (modes.isNotEmpty && !modes.contains(configuration.mode)) continue;
    if (compilers.isNotEmpty && !compilers.contains(configuration.compiler)) {
      continue;
    }
    if (runtimes.isNotEmpty && !runtimes.contains(configuration.runtime)) {
      continue;
    }
    if (nnbdMode != null && configuration.nnbdMode != nnbdMode) continue;

    names.add(configuration.name);
  }

  var filters = [
    if (system != null) "system=$system",
    if (architectures.isNotEmpty) "arch=$architectures",
    if (modes.isNotEmpty) "mode=$modes",
    if (compilers.isNotEmpty) "compiler=$compilers",
    if (runtimes.isNotEmpty) "runtime=$runtimes",
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
Never _fail(String message) {
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
  final relativePath =
      config['sanitizer_symbolizer'][Platform.operatingSystem] as String?;
  if (relativePath != null) {
    var symbolizerPath = path.join(Directory.current.path, relativePath);
    environment['ASAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['LSAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['MSAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['TSAN_SYMBOLIZER_PATH'] = symbolizerPath;
    environment['UBSAN_SYMBOLIZER_PATH'] = symbolizerPath;
  }

  return environment;
})();
