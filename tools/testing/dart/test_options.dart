// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_options_parser;

import "dart:io";
import "drt_updater.dart";
import "test_suite.dart";
import "path.dart";
import "compiler_configuration.dart" show CompilerConfiguration;
import "runtime_configuration.dart" show RuntimeConfiguration;

const List<String> defaultTestSelectors = const [
  'samples',
  'standalone',
  'corelib',
  'co19',
  'language',
  'isolate',
  'vm',
  'html',
  'benchmark_smoke',
  'utils',
  'lib',
  'pkg',
  'analyze_library',
  'service',
  'kernel',
  'observatory_ui'
];

/**
 * Specification of a single test option.
 *
 * The name of the specification is used as the key for the option in
 * the Map returned from the [TestOptionParser] parse method.
 */
class _TestOptionSpecification {
  _TestOptionSpecification(
      this.name, this.description, this.keys, this.values, this.defaultValue,
      {this.type: 'string'});
  String name;
  String description;
  List<String> keys;
  List<String> values;
  var defaultValue;
  String type;
}

/**
 * Parser of test options.
 */
class TestOptionsParser {
  /**
   * Creates a test options parser initialized with the known options.
   */
  TestOptionsParser() {
    _options = [
      new _TestOptionSpecification('mode', 'Mode in which to run the tests',
          ['-m', '--mode'], ['all', 'debug', 'release', 'product'], 'debug'),
      new _TestOptionSpecification(
          'compiler',
          '''Specify any compilation step (if needed).

   none: Do not compile the Dart code (run native Dart code on the VM).
         (only valid with the following runtimes: vm, drt)

   dart2js: Compile dart code to JavaScript by running dart2js.
         (only valid with the following runtimes: d8, drt, chrome,
         safari, ie9, ie10, ie11, firefox, opera, chromeOnAndroid,
         none (compile only)),

   dart2analyzer: Perform static analysis on Dart code by running the analyzer
          (only valid with the following runtimes: none)

   dart2app:
   dart2appjit: Compile the Dart code into an app snapshot before running test
          (only valid with dart_app runtime)

   dartk: Compile the Dart source into Kernel before running test.

   dartkp: Compiler the Dart source into Kernel and then Kernel into AOT
   snapshot before running the test.''',
          ['-c', '--compiler'],
          ['none', 'precompiler', 'dart2js', 'dart2analyzer', 'dart2app',
           'dart2appjit', 'dartk', 'dartkp'],
          'none'),
      // TODO(antonm): fix the option drt.
      new _TestOptionSpecification(
          'runtime',
          '''Where the tests should be run.
    vm: Run Dart code on the standalone dart vm.

    dart_precompiled: Run a precompiled snapshot on a variant of the standalone
                      dart vm lacking a JIT.

    dart_app: Run a full app snapshot, with or without cached unoptimized code.

    d8: Run JavaScript from the command line using v8.

    jsshell: Run JavaScript from the command line using firefox js-shell.

    drt: Run Dart or JavaScript in the headless version of Chrome,
         Content shell.

    dartium: Run Dart or JavaScript in Dartium.

    ContentShellOnAndroid: Run Dart or JavaScript in Dartium content shell
                      on Android.

    DartiumOnAndroid: Run Dart or Javascript in Dartium on Android.

    [ff | chrome | safari | ie9 | ie10 | ie11 | opera | chromeOnAndroid]:
        Run JavaScript in the specified browser.

    none: No runtime, compile only (for example, used for dart2analyzer static
          analysis tests).''',
          ['-r', '--runtime'],
          [
            'vm',
            'dart_precompiled',
            'dart_app',
            'd8',
            'jsshell',
            'drt',
            'dartium',
            'ff',
            'firefox',
            'chrome',
            'safari',
            'ie9',
            'ie10',
            'ie11',
            'opera',
            'chromeOnAndroid',
            'safarimobilesim',
            'ContentShellOnAndroid',
            'DartiumOnAndroid',
            'none'
          ],
          'vm'),
      new _TestOptionSpecification(
          'arch',
          'The architecture to run tests for',
          ['-a', '--arch'],
          [
            'all',
            'ia32',
            'x64',
            'arm',
            'armv6',
            'armv5te',
            'arm64',
            'mips',
            'simarm',
            'simarmv6',
            'simarmv5te',
            'simarm64',
            'simmips',
            'simdbc',
            'simdbc64',
          ],
          'x64'),
      new _TestOptionSpecification(
          'system',
          'The operating system to run tests on',
          ['-s', '--system'],
          ['linux', 'macos', 'windows', 'android'],
          Platform.operatingSystem),
      new _TestOptionSpecification(
          'checked', 'Run tests in checked mode', ['--checked'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'strong', 'Run tests in strong mode', ['--strong'], [], false,
          type: 'bool'),
      new _TestOptionSpecification('host_checked',
          'Run compiler in checked mode', ['--host-checked'], [], false,
          type: 'bool'),
      new _TestOptionSpecification('minified',
          'Enable minification in the compiler', ['--minified'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'csp',
          'Run tests under Content Security Policy restrictions',
          ['--csp'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'cps_ir',
          'Run the compiler with the cps based backend',
          ['--cps-ir'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'noopt', 'Run an in-place precompilation', ['--noopt'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'fast_startup', 'Pass the --fast-startup flag to dart2js',
          ['--fast-startup'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'hot_reload', 'Run hot reload stress tests', ['--hot-reload'], [],
          false, type: 'bool'),
      new _TestOptionSpecification(
          'hot_reload_rollback',
          'Run hot reload rollback stress tests', ['--hot-reload-rollback'],
          [],
          false, type: 'bool'),
      new _TestOptionSpecification(
          'use_blobs',
          'Use mmap instead of shared libraries for precompilation',
          ['--use-blobs'], [], false, type: 'bool'),
      new _TestOptionSpecification(
          'timeout', 'Timeout in seconds', ['-t', '--timeout'], [], -1,
          type: 'int'),
      new _TestOptionSpecification(
          'progress',
          'Progress indication mode',
          ['-p', '--progress'],
          [
            'compact',
            'color',
            'line',
            'verbose',
            'silent',
            'status',
            'buildbot',
            'diff'
          ],
          'compact'),
      new _TestOptionSpecification('failure-summary',
          'Print failure summary at the end', ['--failure-summary'], [], false,
          type: 'bool'),
      new _TestOptionSpecification('step_name',
          'Step name for use by -pbuildbot', ['--step_name'], [], null),
      new _TestOptionSpecification(
          'report',
          'Print a summary report of the number of tests, by expectation',
          ['--report'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'tasks',
          'The number of parallel tasks to run',
          ['-j', '--tasks'],
          [],
          Platform.numberOfProcessors,
          type: 'int'),
      new _TestOptionSpecification(
          'shards',
          'The number of instances that the tests will be sharded over',
          ['--shards'],
          [],
          1,
          type: 'int'),
      new _TestOptionSpecification(
          'shard',
          'The index of this instance when running in sharded mode',
          ['--shard'],
          [],
          1,
          type: 'int'),
      new _TestOptionSpecification(
          'help', 'Print list of options', ['-h', '--help'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'verbose', 'Verbose output', ['-v', '--verbose'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'list', 'List tests only, do not run them', ['--list'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'report_in_json',
          'When doing list, output result summary in json only.',
          ['--report-in-json'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification('time',
          'Print timing information after running tests', ['--time'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'dart', 'Path to dart executable', ['--dart'], [], ''),
      new _TestOptionSpecification(
          'drt', // TODO(antonm): fix the option name.
          'Path to content shell executable',
          ['--drt'],
          [],
          ''),
      new _TestOptionSpecification('dartium',
          'Path to Dartium Chrome executable', ['--dartium'], [], ''),
      new _TestOptionSpecification('firefox',
          'Path to firefox browser executable', ['--firefox'], [], ''),
      new _TestOptionSpecification(
          'chrome', 'Path to chrome browser executable', ['--chrome'], [], ''),
      new _TestOptionSpecification(
          'safari', 'Path to safari browser executable', ['--safari'], [], ''),
      new _TestOptionSpecification(
          'use_sdk',
          '''Use compiler or runtime from the SDK.

Normally, the compiler or runtimes in PRODUCT_DIR is tested, with this
option, the compiler or runtime in PRODUCT_DIR/dart-sdk/bin is tested.

Note: currently only implemented for dart2js.''',
          ['--use-sdk'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'use_public_packages',
          'For tests using packages: Use pub.dartlang.org packages '
          'instead the ones in the repository.',
          ['--use-public-packages'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'use_repository_packages',
          'For tests using packages: Use pub.dartlang.org packages '
          'but use overrides for the packages available in the '
          'repository.',
          ['--use-repository-packages'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'build_directory',
          'The name of the build directory, where products are placed.',
          ['--build-directory'],
          [],
          ''),
      new _TestOptionSpecification('noBatch', 'Do not run tests in batch mode',
          ['-n', '--nobatch'], [], false,
          type: 'bool'),
      new _TestOptionSpecification('dart2js_batch',
          'Run dart2js tests in batch mode', ['--dart2js-batch'], [], false,
          type: 'bool'),
      new _TestOptionSpecification(
          'append_logs',
          'Do not delete old logs but rather append to them.',
          ['--append_logs'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'write_debug_log',
          'Don\'t write debug messages to stdout but rather to a logfile.',
          ['--write-debug-log'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'write_test_outcome_log',
          'Write the outcome of all tests executed to a '
          '"${TestUtils.flakyFileName()}" file.',
          ['--write-test-outcome-log'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'reset_browser_configuration',
          'Browser specific reset of configuration. '
          'WARNING: Using this option may remove your bookmarks and '
          'other settings.',
          ['--reset-browser-configuration'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'copy_coredumps',
          'If we see a crash that we did not expect, copy the core dumps. '
          'to /tmp',
          ['--copy-coredumps'],
          [],
          false,
          type: 'bool'),
      new _TestOptionSpecification(
          'local_ip',
          'IP address the http servers should listen on.'
          'This address is also used for browsers to connect.',
          ['--local_ip'],
          [],
          '127.0.0.1'),
      new _TestOptionSpecification('test_server_port',
          'Port for test http server.', ['--test_server_port'], [], 0,
          type: 'int'),
      new _TestOptionSpecification(
          'test_server_cross_origin_port',
          'Port for test http server cross origin.',
          ['--test_server_cross_origin_port'],
          [],
          0,
          type: 'int'),
      new _TestOptionSpecification('test_driver_port',
          'Port for http test driver server.', ['--test_driver_port'], [], 0,
          type: 'int'),
      new _TestOptionSpecification(
          'test_driver_error_port',
          'Port for http test driver server errors.',
          ['--test_driver_error_port'],
          [],
          0,
          type: 'int'),
      new _TestOptionSpecification(
          'record_to_file',
          'Records all the commands that need to be executed and writes it '
          'out to a file.',
          ['--record_to_file'],
          [],
          null),
      new _TestOptionSpecification(
          'replay_from_file',
          'Records all the commands that need to be executed and writes it '
          'out to a file.',
          ['--replay_from_file'],
          [],
          null),
      new _TestOptionSpecification(
          'builder_tag',
          'Machine specific options that is not captured by the regular '
          'test options. Used to be able to make sane updates to the '
          'status files.',
          ['--builder-tag'],
          [],
          ''),
      new _TestOptionSpecification(
          'vm_options',
          'Extra options to send to the vm when running',
          ['--vm-options'],
          [],
          null),
      new _TestOptionSpecification(
          'dart2js_options',
          'Extra options for dart2js compilation step',
          ['--dart2js-options'],
          [],
          null),
      new _TestOptionSpecification(
          'suite_dir',
          'Additional directory to add to the testing matrix',
          ['--suite-dir'],
          [],
          null),
      new _TestOptionSpecification('package_root',
          'The package root to use for testing.', ['--package-root'], [], null),
      new _TestOptionSpecification(
          'packages',
          'The package spec file to use for testing.',
          ['--packages'],
          [],
          null),
      new _TestOptionSpecification(
          'exclude_suite',
          'Exclude suites from default selector, only works when no'
          ' selector has been specified on the command line',
          ['--exclude-suite'],
          defaultTestSelectors,
          null),
    ];
  }

  /**
   * Parse a list of strings as test options.
   *
   * Returns a list of configurations in which to run the
   * tests. Configurations are maps mapping from option keys to
   * values. When encountering the first non-option string, the rest
   * of the arguments are stored in the returned Map under the 'rest'
   * key.
   */
  List<Map> parse(List<String> arguments) {
    var configuration = new Map();
    // Fill in configuration with arguments passed to the test script.
    var numArguments = arguments.length;
    for (var i = 0; i < numArguments; i++) {
      // Extract name and value for options.
      String arg = arguments[i];
      String name = '';
      String value = '';
      _TestOptionSpecification spec;
      if (arg.startsWith('--')) {
        if (arg == '--help') {
          _printHelp();
          return null;
        }
        var split = arg.indexOf('=');
        if (split == -1) {
          name = arg;
          spec = _getSpecification(name);
          // Boolean options do not have a value.
          if (spec.type != 'bool') {
            if ((i + 1) >= arguments.length) {
              print('No value supplied for option $name');
              return null;
            }
            value = arguments[++i];
          }
        } else {
          name = arg.substring(0, split);
          spec = _getSpecification(name);
          value = arg.substring(split + 1, arg.length);
        }
      } else if (arg.startsWith('-')) {
        if (arg == '-h') {
          _printHelp();
          return null;
        }
        if (arg.length > 2) {
          name = arg.substring(0, 2);
          spec = _getSpecification(name);
          value = arg.substring(2, arg.length);
        } else {
          name = arg;
          spec = _getSpecification(name);
          // Boolean options do not have a value.
          if (spec.type != 'bool') {
            if ((i + 1) >= arguments.length) {
              print('No value supplied for option $name');
              return null;
            }
            value = arguments[++i];
          }
        }
      } else {
        // The argument does not start with '-' or '--' and is
        // therefore not an option. We use it as a test selection
        // pattern.
        configuration.putIfAbsent('selectors', () => []);
        var patterns = configuration['selectors'];
        patterns.add(arg);
        continue;
      }

      // Multiple uses of a flag are an error, because there is no
      // naturally correct way to handle conflicting options.
      if (configuration.containsKey(spec.name)) {
        print('Error: test.dart disallows multiple "--${spec.name}" flags');
        exit(1);
      }
      // Parse the value for the option.
      if (spec.type == 'bool') {
        if (!value.isEmpty) {
          print('No value expected for bool option $name');
          exit(1);
        }
        configuration[spec.name] = true;
      } else if (spec.type == 'int') {
        try {
          configuration[spec.name] = int.parse(value);
        } catch (e) {
          print('Integer value expected for int option $name');
          exit(1);
        }
      } else {
        assert(spec.type == 'string');
        if (!spec.values.isEmpty) {
          for (var v in value.split(',')) {
            if (spec.values.lastIndexOf(v) == -1) {
              print('Unknown value ($v) for option $name');
              exit(1);
            }
          }
        }
        configuration[spec.name] = value;
      }
    }

    // Apply default values for unspecified options.
    for (var option in _options) {
      if (!configuration.containsKey(option.name)) {
        configuration[option.name] = option.defaultValue;
      }
    }

    List<Map> expandedConfigs = _expandConfigurations(configuration);
    List<Map> result = expandedConfigs.where(_isValidConfig).toList();
    for (var config in result) {
      config['_reproducing_arguments_'] =
          _constructReproducingCommandArguments(config);
    }
    return result.isEmpty ? null : result;
  }

  // For printing out reproducing command lines, we don't want to add these
  // options.
  Set<String> _blacklistedOptions = new Set<String>.from([
    'progress',
    'failure-summary',
    'step_name',
    'report',
    'tasks',
    'verbose',
    'time',
    'dart',
    'drt',
    'dartium',
    'firefox',
    'chrome',
    'safari',
    'build_directory',
    'append_logs',
    'local_ip',
    'shard',
    'shards',
  ]);

  List<String> _constructReproducingCommandArguments(Map config) {
    var arguments = new List<String>();
    for (var configKey in config.keys) {
      if (!_blacklistedOptions.contains(configKey)) {
        for (var option in _options) {
          var configValue = config[configKey];
          // We only include entries of [conf] if we find an option for it.
          if (configKey == option.name && configValue != option.defaultValue) {
            var isBooleanOption = option.type == 'bool';
            // Sort by length, so we get the shortest variant.
            var possibleOptions = new List.from(option.keys);
            possibleOptions.sort((a, b) => (a.length < b.length ? -1 : 1));
            var key = possibleOptions[0];
            if (key.startsWith('--')) {
              // long version
              arguments.add(key);
              if (!isBooleanOption) {
                arguments.add("$configValue");
              }
            } else {
              // short version
              assert(key.startsWith('-'));
              if (!isBooleanOption) {
                arguments.add("$key$configValue");
              } else {
                arguments.add(key);
              }
            }
          }
        }
      }
    }
    return arguments;
  }

  /**
   * Determine if a particular configuration has a valid combination of compiler
   * and runtime elements.
   */
  bool _isValidConfig(Map config) {
    bool isValid = true;
    List<String> validRuntimes;
    switch (config['compiler']) {
      case 'dart2js':
        // Note: by adding 'none' as a configuration, if the user
        // runs test.py -c dart2js -r drt,none the dart2js_none and
        // dart2js_drt will be duplicating work. If later we don't need 'none'
        // with dart2js, we should remove it from here.
        validRuntimes = const [
          'd8',
          'jsshell',
          'drt',
          'none',
          'dartium',
          'ff',
          'chrome',
          'safari',
          'ie9',
          'ie10',
          'ie11',
          'opera',
          'chromeOnAndroid',
          'safarimobilesim'
        ];
        break;
      case 'dart2analyzer':
        validRuntimes = const ['none'];
        break;
      case 'dart2app':
      case 'dart2appjit':
        validRuntimes = const ['dart_app'];
        break;
      case 'precompiler':
        validRuntimes = const ['dart_precompiled'];
        break;
      case 'dartk':
        validRuntimes = const ['vm'];
        break;
      case 'dartkp':
        validRuntimes = const ['dart_precompiled'];
        break;
      case 'none':
        validRuntimes = const [
          'vm',
          'drt',
          'dartium',
          'ContentShellOnAndroid',
          'DartiumOnAndroid'
        ];
        break;
    }
    if (!validRuntimes.contains(config['runtime'])) {
      isValid = false;
      print("Warning: combination of compiler '${config['compiler']}' and "
          "runtime '${config['runtime']}' is invalid. "
          "Skipping this combination.");
    }
    if (config['ie'] && Platform.operatingSystem != 'windows') {
      isValid = false;
      print("Warning cannot run Internet Explorer on non-Windows operating"
          " system.");
    }
    if (config['shard'] < 1 || config['shard'] > config['shards']) {
      isValid = false;
      print("Error: shard index is ${config['shard']} out of "
          "${config['shards']} shards");
    }

    if (config['use_repository_packages'] && config['use_public_packages']) {
      isValid = false;
      print("Cannot have both --use-repository-packages and "
          "--use-public-packages");
    }

    return isValid;
  }

  /**
   * Recursively expand a configuration with multiple values per key
   * into a list of configurations with exactly one value per key.
   */
  List<Map> _expandConfigurations(Map configuration) {
    // Expand the pseudo-values such as 'all'.
    if (configuration['arch'] == 'all') {
      configuration['arch'] = 'ia32,x64,simarm,simarm64,simmips,simdbc64';
    }
    if (configuration['mode'] == 'all') {
      configuration['mode'] = 'debug,release,product';
    }

    if (configuration['report_in_json']) {
      configuration['list'] = true;
      configuration['report'] = true;
    }

    // Use verbose progress indication for verbose output unless buildbot
    // progress indication is requested.
    if (configuration['verbose'] && configuration['progress'] != 'buildbot') {
      configuration['progress'] = 'verbose';
    }

    // Create the artificial negative options that test status files
    // expect.
    configuration['unchecked'] = !configuration['checked'];
    configuration['host_unchecked'] = !configuration['host_checked'];
    configuration['unminified'] = !configuration['minified'];
    configuration['nocsp'] = !configuration['csp'];

    String runtime = configuration['runtime'];
    if (runtime == 'firefox') {
      configuration['runtime'] == 'ff';
    }

    String compiler = configuration['compiler'];
    configuration['browser'] = TestUtils.isBrowserRuntime(runtime);
    configuration['analyzer'] = TestUtils.isCommandLineAnalyzer(compiler);

    // Set the javascript command line flag for less verbose status files.
    configuration['jscl'] = TestUtils.isJsCommandLineRuntime(runtime);

    // Allow suppression that is valid for all ie versions
    configuration['ie'] = runtime.startsWith('ie');

    // Expand the test selectors into a suite name and a simple
    // regular expressions to be used on the full path of a test file
    // in that test suite. If no selectors are explicitly given use
    // the default suite patterns.
    var selectors = configuration['selectors'];
    if (selectors is! Map) {
      if (selectors == null) {
        if (configuration['suite_dir'] != null) {
          var suite_path = new Path(configuration['suite_dir']);
          selectors = [suite_path.filename];
        } else {
          selectors = new List.from(defaultTestSelectors);
        }

        var exclude_suites = configuration['exclude_suite'] != null
            ? configuration['exclude_suite'].split(',')
            : [];
        for (var exclude in exclude_suites) {
          if (selectors.contains(exclude)) {
            selectors.remove(exclude);
          } else {
            print("Error: default selectors does not contain $exclude");
            exit(1);
          }
        }
      }
      Map<String, RegExp> selectorMap = new Map<String, RegExp>();
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
          print("Error: '$suite/$pattern'.  Only one test selection"
              " pattern is allowed to start with '$suite/'");
          exit(1);
        }
        selectorMap[suite] = new RegExp(pattern);
      }
      configuration['selectors'] = selectorMap;
    }

    // Put observatory_ui in a configuration with its own packages override.
    // Only one value in the configuration map is mutable:
    selectors = configuration['selectors'];
    if (selectors.containsKey('observatory_ui')) {
      if (selectors.length == 1) {
        configuration['packages'] = TestUtils.dartDirUri
          .resolve('runtime/observatory/.packages').toFilePath();
      } else {
        // Make a new configuration whose selectors map only contains
        // observatory_ui, and remove the key from the original selectors.
        // The only mutable value in the map is the selectors, so a
        // shallow copy is safe.
        var observatoryConfiguration = new Map.from(configuration);
        observatoryConfiguration['selectors'] =
          {'observatory_ui': selectors['observatory_ui']};
        selectors.remove('observatory_ui');

        // Set the packages flag.
        observatoryConfiguration['packages'] = TestUtils.dartDirUri
          .resolve('runtime/observatory/.packages').toFilePath();

        // Return the expansions of both configurations. Neither will reach
        // this line in the recursive call to _expandConfigurations.
        return _expandConfigurations(configuration)
          ..addAll(_expandConfigurations(observatoryConfiguration));
      }
    }
    // Set the default package spec explicitly.
    if (configuration['package_root'] == null &&
        configuration['packages'] == null) {
      configuration['packages'] =
        TestUtils.dartDirUri.resolve('.packages').toFilePath();
    }

    // Expand the architectures.
    if (configuration['arch'].contains(',')) {
      return _expandHelper('arch', configuration);
    }

    // Expand modes.
    if (configuration['mode'].contains(',')) {
      return _expandHelper('mode', configuration);
    }

    // Expand compilers.
    if (configuration['compiler'].contains(',')) {
      return _expandHelper('compiler', configuration);
    }

    // Expand runtimes.
    var runtimes = configuration['runtime'];
    if (runtimes.contains(',')) {
      return _expandHelper('runtime', configuration);
    } else {
      // All runtimes eventually go through this path, after expansion.
      var updater = runtimeUpdater(configuration);
      if (updater != null) {
        updater.update();
      }
    }

    // Adjust default timeout based on mode, compiler, and sometimes runtime.
    if (configuration['timeout'] == -1) {
      var isReload = configuration['hot_reload'] ||
                     configuration['hot_reload_rollback'];
      int compilerMulitiplier =
          new CompilerConfiguration(configuration).computeTimeoutMultiplier();
      int runtimeMultiplier = new RuntimeConfiguration(configuration)
          .computeTimeoutMultiplier(
              mode: configuration['mode'],
              isChecked: configuration['checked'],
              isReload: isReload,
              arch: configuration['arch']);
      configuration['timeout'] = 60 * compilerMulitiplier * runtimeMultiplier;
    }

    return [configuration];
  }

  /**
   * Helper for _expandConfigurations. Creates a new configuration and adds it
   * to a list, for use in a case when a particular configuration has multiple
   * results (separated by a ',').
   * Arguments:
   * option: The particular test option we are expanding.
   * configuration: The map containing all test configuration information
   * specified.
   */
  List<Map> _expandHelper(String option, Map configuration) {
    var result = new List<Map>();
    var configs = configuration[option];
    for (var config in configs.split(',')) {
      var newConfiguration = new Map.from(configuration);
      newConfiguration[option] = config;
      result.addAll(_expandConfigurations(newConfiguration));
    }
    return result;
  }

  /**
   * Print out usage information.
   */
  void _printHelp() {
    print('usage: dart test.dart [options] [selector]');
    print('');
    print('The optional selector limits the tests that will be run.');
    print('For example, the selector "language/issue", or equivalently');
    print('"language/*issue*", limits to test files matching the regexp');
    print('".*issue.*\\.dart" in the "tests/language" directory.');
    print('');
    print('Options:\n');
    for (var option in _options) {
      print('${option.name}: ${option.description}.');
      for (var name in option.keys) {
        assert(name.startsWith('-'));
        var buffer = new StringBuffer();
        ;
        buffer.write(name);
        if (option.type == 'bool') {
          assert(option.values.isEmpty);
        } else {
          buffer.write(name.startsWith('--') ? '=' : ' ');
          if (option.type == 'int') {
            assert(option.values.isEmpty);
            buffer.write('n (default: ${option.defaultValue})');
          } else {
            buffer.write('[');
            bool first = true;
            for (var value in option.values) {
              if (!first) buffer.write(", ");
              if (value == option.defaultValue) buffer.write('*');
              buffer.write(value);
              first = false;
            }
            buffer.write(']');
          }
        }
        print(buffer.toString());
      }
      print('');
    }
  }

  /**
   * Find the test option specification for a given option key.
   */
  _TestOptionSpecification _getSpecification(String name) {
    for (var option in _options) {
      if (option.keys.contains(name)) {
        return option;
      }
    }
    print('Unknown test option $name');
    exit(1);
  }

  List<_TestOptionSpecification> _options;
}
