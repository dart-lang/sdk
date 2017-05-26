// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'drt_updater.dart';
import 'test_suite.dart';
import 'path.dart';
import 'compiler_configuration.dart' show CompilerConfiguration;
import 'runtime_configuration.dart' show RuntimeConfiguration;

const _defaultTestSelectors = const [
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
      {String abbr, List<String> values, String defaultsTo = ""})
      : abbreviation = abbr,
        values = values ?? [],
        defaultValue = defaultsTo,
        type = _OptionValueType.string;

  _Option.bool(this.name, this.description, [this.abbreviation])
      : values = [],
        defaultValue = false,
        type = _OptionValueType.bool;

  _Option.int(this.name, this.description, {String abbr, int defaultsTo})
      : abbreviation = abbr,
        values = [],
        defaultValue = defaultsTo,
        type = _OptionValueType.int;

  final String name;
  final String description;
  final String abbreviation;
  final List<String> values;
  final Object defaultValue;
  final _OptionValueType type;

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
        values: ['all', 'debug', 'release', 'product'],
        defaultsTo: 'debug'),
    new _Option(
        'compiler',
        '''Specify any compilation step (if needed).

none:          Do not compile the Dart code (run native Dart code
               on the VM).
               (Only valid with runtimes vm, flutter, or drt.)

precompiler:   Compile into AOT snapshot before running the test.
               (Only valid with runtime dart_precompiled.)

dart2js:       Compile dart code to JavaScript by running dart2js.
               (Only valid with runtimes: d8, drt, chrome, safari,
               ie9, ie10, ie11, firefox, opera, chromeOnAndroid,
               and none [compile only].)

dart2analyzer: Perform static analysis on Dart code by running the
               analyzer.
               (Only valid with runtime none.)

app_jit:       Compile the Dart code into an app snapshot before
               running test.
               (Only valid with dart_app runtime.)

dartk:         Compile the Dart source into Kernel before running
               test.

dartkp:        Compile the Dart source into Kernel and then Kernel
               into AOT snapshot before running the test.
               (Only valid with runtime dart_precompiled.)''',
        abbr: 'c',
        values: [
          'none',
          'precompiler',
          'dart2js',
          'dart2analyzer',
          'app_jit',
          'dartk',
          'dartkp'
        ],
        defaultsTo: 'none'),
    new _Option(
        'runtime',
        '''Where the tests should be run.
vm:               Run Dart code on the standalone dart vm.

flutter:          Run Dart code on the flutter engine.

dart_precompiled: Run a precompiled snapshot on a variant of the
                  standalone dart VM lacking a JIT.

d8:               Run JavaScript from the command line using v8.

jsshell:          Run JavaScript from the command line using
                  Firefox js-shell.

drt:              Run Dart or JavaScript in the headless version
                  of Chrome, Content shell.

dartium:          Run Dart or JavaScript in Dartium.

ContentShellOnAndroid: Run Dart or JavaScript in Dartium content
                  shell on Android.

DartiumOnAndroid: Run Dart or Javascript in Dartium on Android.

ff:
chrome:
safari:
ie9:
ie10:
ie11:
opera:
chromeOnAndroid:  Run JavaScript in the specified browser.

self_check:       Pass each test or its compiled output to every
                  file under `pkg` whose name ends with
                  `_self_check.dart`. Each test is given to the
                  self_check tester as a filename on stdin using
                  the batch-mode protocol.

none:             No runtime, compile only. (For example, used
                  for dart2analyzer static analysis tests).''',
        abbr: 'r',
        values: [
          'vm',
          'flutter',
          'dart_precompiled',
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
          'self_check',
          'none'
        ],
        defaultsTo: 'vm'),
    new _Option(
        'arch',
        '''The architecture to run tests for.

Allowed values are:
all
ia32, x64
arm, armv6, armv5te, arm64,
simarm, simarmv6, simarmv5te, simarm64,
mips, simmips
simdbc, simdbc64''',
        abbr: 'a',
        values: [
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
        defaultsTo: 'x64'),
    new _Option('system', 'The operating system to run tests on.',
        abbr: 's',
        values: ['linux', 'macos', 'windows', 'android'],
        defaultsTo: Platform.operatingSystem),
    new _Option.bool('checked', 'Run tests in checked mode.'),
    new _Option.bool('strong', 'Run tests in strong mode.'),
    new _Option.bool('host_checked', 'Run compiler in checked mode.'),
    new _Option.bool('minified', 'Enable minification in the compiler.'),
    new _Option.bool(
        'csp', 'Run tests under Content Security Policy restrictions.'),
    new _Option.bool(
        'fast_startup', 'Pass the --fast-startup flag to dart2js.'),
    new _Option.bool('dart2js_with_kernel',
        'Enable the internal pipeline in dart2js to use kernel.'),
    new _Option.bool('hot_reload', 'Run hot reload stress tests.'),
    new _Option.bool(
        'hot_reload_rollback', 'Run hot reload rollback stress tests.'),
    new _Option.bool('use_blobs',
        'Use mmap instead of shared libraries for precompilation.'),
    new _Option.int('timeout', 'Timeout in seconds.',
        abbr: 't', defaultsTo: -1),
    new _Option(
        'progress',
        '''Progress indication mode.

Allowed values are:
compact, color, line, verbose, silent, status, buildbot, diff
''',
        abbr: 'p',
        values: [
          'compact',
          'color',
          'line',
          'verbose',
          'silent',
          'status',
          'buildbot',
          'diff'
        ],
        defaultsTo: 'compact'),
    new _Option('step_name', 'Step name for use by -pbuildbot.',
        defaultsTo: null),
    new _Option.bool('report',
        'Print a summary report of the number of tests, by expectation.'),
    new _Option.int('tasks', 'The number of parallel tasks to run.',
        abbr: 'j', defaultsTo: Platform.numberOfProcessors),
    new _Option.int('shards',
        'The number of instances that the tests will be sharded over.',
        defaultsTo: 1),
    new _Option.int(
        'shard', 'The index of this instance when running in sharded mode.',
        defaultsTo: 1),
    new _Option.bool('help', 'Print list of options.', 'h'),
    new _Option.bool('verbose', 'Verbose output.', 'v'),
    new _Option.bool('verify-ir', 'Verify kernel IR.'),
    new _Option.bool('no-tree-shake', 'Disable kernel IR tree shaking.'),
    new _Option.bool('list', 'List tests only, do not run them.'),
    new _Option.bool('report_in_json',
        'When listing with --list, output result summary in JSON.'),
    new _Option.bool('time', 'Print timing information after running tests.'),
    new _Option('dart', 'Path to dart executable.'),
    new _Option('flutter', 'Path to flutter executable.'),
    new _Option(
        'drt', // TODO(antonm): fix the option name.
        'Path to content shell executable.'),
    new _Option('dartium', 'Path to Dartium Chrome executable.'),
    new _Option('firefox', 'Path to firefox browser executable.'),
    new _Option('chrome', 'Path to chrome browser executable.'),
    new _Option('safari', 'Path to safari browser executable.'),
    new _Option.bool(
        'use_sdk',
        '''Use compiler or runtime from the SDK.

Normally, the compiler or runtimes in PRODUCT_DIR is tested, with
this option, the compiler or runtime in PRODUCT_DIR/dart-sdk/bin
is tested.

(Note: currently only implemented for dart2js.)'''),
    new _Option('build_directory',
        'The name of the build directory, where products are placed.'),
    new _Option.bool('noBatch', 'Do not run tests in batch mode.', 'n'),
    new _Option.bool('dart2js_batch', 'Run dart2js tests in batch mode.'),
    new _Option.bool(
        'append_logs', 'Do not delete old logs but rather append to them.'),
    new _Option.bool('write_debug_log',
        'Don\'t write debug messages to stdout but rather to a logfile.'),
    new _Option.bool('write_test_outcome_log',
        'Write test outcomes to a "${TestUtils.testOutcomeFileName}" file.'),
    new _Option.bool(
        'reset_browser_configuration',
        '''Browser specific reset of configuration.

Warning: Using this option may remove your bookmarks and other
settings.'''),
    new _Option.bool(
        'copy_coredumps',
        '''If we see a crash that we did not expect, copy the core dumps to
"/tmp".'''),
    new _Option(
        'local_ip',
        '''IP address the HTTP servers should listen on. This address is also
used for browsers to connect to.''',
        defaultsTo: '127.0.0.1'),
    new _Option.int('test_server_port', 'Port for test http server.',
        defaultsTo: 0),
    new _Option.int('test_server_cross_origin_port',
        'Port for test http server cross origin.',
        defaultsTo: 0),
    new _Option.int('test_driver_port', 'Port for http test driver server.',
        defaultsTo: 0),
    new _Option.int(
        'test_driver_error_port', 'Port for http test driver server errors.',
        defaultsTo: 0),
    new _Option('record_to_file',
        'Records all commands to be executed and writes to a file.',
        defaultsTo: null),
    new _Option(
        'replay_from_file', 'Replays a previously recorded list of commands.',
        defaultsTo: null),
    new _Option(
        'builder_tag',
        '''Machine specific options that is not captured by the regular test
options. Used to be able to make sane updates to the status files.'''),
    new _Option('vm_options', 'Extra options to send to the vm when running.',
        defaultsTo: null),
    new _Option(
        'dart2js_options', 'Extra options for dart2js compilation step.',
        defaultsTo: null),
    new _Option(
        'suite_dir', 'Additional directory to add to the testing matrix.',
        defaultsTo: null),
    new _Option('package_root', 'The package root to use for testing.',
        defaultsTo: null),
    new _Option('packages', 'The package spec file to use for testing.',
        defaultsTo: null),
    new _Option(
        'exclude_suite',
        '''Exclude suites from default selector, only works when no selector
has been specified on the command line.''',
        defaultsTo: null),
    new _Option.bool(
        'skip-compilation',
        '''
Skip the compilation step, using the compilation artifacts left in
the output folder from a previous run. This flag will often cause
false positves and negatives, but can be useful for quick and
dirty offline testing when not making changes that affect the
compiler.''')
  ];

  /// For printing out reproducing command lines, we don't want to add these
  /// options.
  static final _blacklistedOptions = [
    'append_logs',
    'build_directory',
    'chrome',
    'copy_coredumps',
    'dart',
    'flutter',
    'dartium',
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
  ].toSet();

  /// Parses a list of strings as test options.
  ///
  /// Returns a list of configurations in which to run the tests.
  /// Configurations are maps mapping from option keys to values. When
  /// encountering the first non-option string, the rest of the arguments are
  /// stored in the returned Map under the 'rest' key.
  List<Map> parse(List<String> arguments) {
    var configuration = {};

    // Fill in configuration with arguments passed to the test script.
    for (var i = 0; i < arguments.length; i++) {
      var arg = arguments[i];

      // Help supersedes all other arguments.
      if (arg == "--help" || arg == "-h") {
        _printHelp();
        return null;
      }

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

    var expandedConfigs = _expandConfigurations(configuration);
    var result = expandedConfigs.where(_isValidConfig).toList();
    for (var config in result) {
      config['_reproducing_arguments_'] = _reproducingCommand(config);
    }

    return result.isEmpty ? null : result;
  }

  /// Prints [message] and exits with a non-zero exit code.
  void _fail(String message) {
    print(message);
    exit(1);
  }

  /// Given a configuration, returns the list of command line arguments that
  /// would reproduce that configuration.
  List<String> _reproducingCommand(Map config) {
    var arguments = <String>[];

    for (var option in _options) {
      var name = option.name;
      if (!config.containsKey(name) || _blacklistedOptions.contains(name)) {
        continue;
      }

      var value = config[name];
      if (config[name] == option.defaultValue ||
          (name == 'packages' &&
              value ==
                  TestUtils.dartDirUri.resolve('.packages').toFilePath())) {
        continue;
      }

      arguments.add(option.shortCommand);
      if (option.type != _OptionValueType.bool) {
        arguments.add(value.toString());
      }
    }

    return arguments;
  }

  /// Determines if a particular configuration has a valid combination of
  /// compiler and runtime elements.
  bool _isValidConfig(Map config) {
    var isValid = true;
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
      case 'app_jit':
      case 'dartk':
        validRuntimes = const ['vm', 'self_check', 'none'];
        break;
      case 'precompiler':
      case 'dartkp':
        validRuntimes = const ['dart_precompiled'];
        break;
      case 'none':
        validRuntimes = const [
          'vm',
          'flutter',
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
      print("Warning: cannot run Internet Explorer on non-Windows operating"
          " system.");
    }

    if (config['shard'] < 1 || config['shard'] > config['shards']) {
      isValid = false;
      print("Error: shard index is ${config['shard']} out of "
          "${config['shards']} shards");
    }

    if (config['runtime'] == 'flutter' && config['flutter'] == '') {
      isValid = false;
      print("-rflutter requires the flutter engine executable to "
          "be specified using --flutter=");
    }

    if (config['runtime'] == 'flutter' && config['arch'] != 'x64') {
      isValid = false;
      print("-rflutter is applicable only for --arch=x64");
    }

    return isValid;
  }

  /// Recursively expands a configuration with multiple values per key into a
  /// list of configurations with exactly one value per key.
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
          selectors = _defaultTestSelectors.toList();
        }

        var excludeSuites = configuration['exclude_suite'] != null
            ? configuration['exclude_suite'].split(',')
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
            .resolve('runtime/observatory/.packages')
            .toFilePath();
      } else {
        // Make a new configuration whose selectors map only contains
        // observatory_ui, and remove the key from the original selectors.
        // The only mutable value in the map is the selectors, so a
        // shallow copy is safe.
        var observatoryConfiguration = new Map.from(configuration);
        observatoryConfiguration['selectors'] = {
          'observatory_ui': selectors['observatory_ui']
        };
        selectors.remove('observatory_ui');

        // Set the packages flag.
        observatoryConfiguration['packages'] = TestUtils.dartDirUri
            .resolve('runtime/observatory/.packages')
            .toFilePath();

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
      var isReload =
          configuration['hot_reload'] || configuration['hot_reload_rollback'];
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

  /// Helper for _expandConfigurations. Creates a new configuration and adds it
  /// to a list, for use in a case when a particular configuration has multiple
  /// results (separated by a ',').
  /// Arguments:
  /// option: The particular test option we are expanding.
  /// configuration: The map containing all test configuration information
  /// specified.
  List<Map> _expandHelper(String option, Map configuration) {
    var result = <Map>[];
    var configs = configuration[option];
    for (var config in configs.split(',')) {
      var newConfiguration = new Map.from(configuration);
      newConfiguration[option] = config;
      result.addAll(_expandConfigurations(newConfiguration));
    }
    return result;
  }

  /// Print out usage information.
  void _printHelp() {
    var buffer = new StringBuffer();

    buffer.writeln('''usage: dart test.dart [options] [selector]

The optional selector limits the tests that will be run.
For example, the selector "language/issue", or equivalently
"language/*issue*", limits to test files matching the regexp
".*issue.*\\.dart" in the "tests/language" directory.

Options:''');

    for (var option in _options) {
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
