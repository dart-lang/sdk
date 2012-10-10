// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_options_parser");

#import("dart:io");
#import("dart:math");
#import("drt_updater.dart");
#import("test_suite.dart");

List<String> defaultTestSelectors =
    const ['dartc', 'samples', 'standalone', 'corelib', 'co19', 'language',
           'isolate', 'vm', 'html', 'json', 'benchmark_smoke',
           'utils', 'pub', 'lib', 'pkg'];

/**
 * Specification of a single test option.
 *
 * The name of the specification is used as the key for the option in
 * the Map returned from the [TestOptionParser] parse method.
 */
class _TestOptionSpecification {
  _TestOptionSpecification(this.name,
                           this.description,
                           this.keys,
                           this.values,
                           this.defaultValue,
                           [type = 'string']) : this.type = type;
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
  String specialCommandHelp =
"""
Special command support. Wraps the command line in
a special command. The special command should contain
an '@' character which will be replaced by the normal
command executable.

For example if the normal command line that will be executed
is 'dart file.dart' and you specify special command
'python -u valgrind.py @ suffix' the final command will be
'python -u valgrind.py dart suffix file.dart'""";

  /**
   * Creates a test options parser initialized with the known options.
   */
  TestOptionsParser() {
    _options =
        [ new _TestOptionSpecification(
              'mode',
              'Mode in which to run the tests',
              ['-m', '--mode'],
              ['all', 'debug', 'release'],
              'debug'),
          new _TestOptionSpecification(
              'compiler',
              '''Specify any compilation step (if needed).

   none: Do not compile the Dart code (run native Dart code on the VM).
         (only valid with the following runtimes: vm, drt)

   dart2dart: Compile Dart code to Dart code
              (only valid with the following runtimes: vm, drt)

   dart2js: Compile dart code to JavaScript by running dart2js.
         (only valid with the following runtimes: d8, drt, chrome,
         safari, ie, firefox, opera, none (compile only)),

   dartc: Perform static analysis on Dart code by running dartc.
          (only valid with the following runtimes: none)''',
              ['-c', '--compiler'],
              ['none', 'dart2dart', 'dart2js', 'dartc'],
              'none'),
          new _TestOptionSpecification(
              'runtime',
              '''Where the tests should be run.
    vm: Run Dart code on the standalone dart vm.

    d8: Run JavaScript from the command line using v8.

    jsshell: Run JavaScript from the command line using firefox js-shell.

    drt: Run Dart or JavaScript in the headless version of Chrome,
         DumpRenderTree.

    dartium: Run Dart or JavaScript in Dartium.

    [ff | chrome | safari | ie | opera]: Run JavaScript in the specified
         browser.

    none: No runtime, compile only (for example, used for dartc static analysis
          tests).''',
              ['-r', '--runtime'],
              ['vm', 'd8', 'jsshell', 'drt', 'dartium', 'ff', 'firefox',
               'chrome', 'safari', 'ie', 'opera', 'none'],
              'vm'),
          new _TestOptionSpecification(
              'arch',
              'The architecture to run tests for',
              ['-a', '--arch'],
              ['all', 'ia32', 'x64', 'simarm'],
              'ia32'),
          new _TestOptionSpecification(
              'system',
              'The operating system to run tests on',
              ['-s', '--system'],
              ['linux', 'macos', 'windows'],
              Platform.operatingSystem),
          new _TestOptionSpecification(
              'checked',
              'Run tests in checked mode',
              ['--checked'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'host_checked',
              'Run compiler in checked mode',
              ['--host-checked'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'timeout',
              'Timeout in seconds',
              ['-t', '--timeout'],
              [],
              -1,
              'int'),
          new _TestOptionSpecification(
              'progress',
              'Progress indication mode',
              ['-p', '--progress'],
              ['compact', 'color', 'line', 'verbose',
               'silent', 'status', 'buildbot'],
              'compact'),
          new _TestOptionSpecification(
              'step_name',
              'Step name for use by -pbuildbot',
              ['--step_name'],
              [],
              'string'),
          new _TestOptionSpecification(
              'report',
              'Print a summary report of the number of tests, by expectation',
              ['--report'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'tasks',
              'The number of parallel tasks to run',
              ['-j', '--tasks'],
              [],
              Platform.numberOfProcessors,
              'int'),
          new _TestOptionSpecification(
              'shards',
              'The number of instances that the tests will be sharded over',
              ['--shards'],
              [],
              1,
              'int'),
          new _TestOptionSpecification(
              'shard',
              'The index of this instance when running in sharded mode',
              ['--shard'],
              [],
              1,
              'int'),
          new _TestOptionSpecification(
              'help',
              'Print list of options',
              ['-h', '--help'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'verbose',
              'Verbose output',
              ['-v', '--verbose'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'list',
              'List tests only, do not run them',
              ['--list'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'valgrind',
              'Run tests through valgrind',
              ['--valgrind'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'special-command',
              specialCommandHelp,
              ['--special-command'],
              [],
              ''),
          new _TestOptionSpecification(
              'time',
              'Print timing information after running tests',
              ['--time'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'additional-compiler-flags',
              'Additional flags to control test compilation',
              ['--additional-compiler-flags'],
              [],
              ''),
          new _TestOptionSpecification(
              'dart',
              'Path to dart executable',
              ['--dart'],
              [],
              ''),
          new _TestOptionSpecification(
              'drt',
              'Path to DumpRenderTree executable',
              ['--drt'],
              [],
              ''),
          new _TestOptionSpecification(
              'dartium',
              'Path to Dartium Chrome executable',
              ['--dartium'],
              [],
              ''),
          new _TestOptionSpecification(
              'use_sdk',
              '''Use compiler or runtime from the SDK.

Normally, the compiler or runtimes in PRODUCT_DIR is tested, with this
option, the compiler or runtime in PRODUCT_DIR/dart-sdk/bin is tested.

Note: currently only implemented for dart2js.''',
              ['--use-sdk'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'noBatch',
              'Do not run browser tests in batch mode',
              ['-n', '--nobatch'],
              [],
              false,
              'bool')];
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
        if (!value.isEmpty()) {
          print('No value expected for bool option $name');
          exit(1);
        }
        configuration[spec.name] = true;
      } else if (spec.type == 'int') {
        try {
          configuration[spec.name] = parseInt(value);
        } catch (e) {
          print('Integer value expected for int option $name');
          exit(1);
        }
      } else {
        assert(spec.type == 'string');
        if (!spec.values.isEmpty()) {
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
    List<Map> result = expandedConfigs.filter(_isValidConfig);
    return result.isEmpty() ? null : result;
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
        validRuntimes = const ['d8', 'jsshell', 'drt', 'none', 'dartium',
                               'ff', 'chrome', 'safari', 'ie', 'opera'];
        break;
      case 'dartc':
        validRuntimes = const ['none'];
        break;
      case 'none':
      case 'dart2dart':
        validRuntimes = const ['vm', 'drt', 'dartium'];
        break;
    }
    if (!Contains(config['runtime'], validRuntimes)) {
      isValid = false;
      print("Warning: combination of ${config['compiler']} and "
          "${config['runtime']} is invalid. Skipping this combination.");
    }
    if (config['runtime'] == 'ie' &&
        Platform.operatingSystem != 'windows') {
      isValid = false;
      print("Warning cannot run Internet Explorer on non-Windows operating"
          " system.");
    }
    if (config['shard'] < 1 || config['shard'] > config['shards']) {
      isValid = false;
      print("Error: shard index is ${config['shard']} out of "
            "${config['shards']} shards");
    }
    if (config['runtime'] == 'dartium' &&
        Contains(config['compiler'], const ['none', 'dart2dart']) &&
        config['checked']) {
      // TODO(vsm): Set the DART_FLAGS environment appropriately when
      // invoking Selenium to support checked mode.  It's not clear
      // the current selenium API supports this.
      isValid = false;
      print("Warning: checked mode is not yet supported for dartium tests.");
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
      configuration['arch'] = 'ia32,x64';
    }
    if (configuration['mode'] == 'all') {
      configuration['mode'] = 'debug,release';
    }
    if (configuration['valgrind']) {
      // TODO(ager): Get rid of this when there is only one checkout and
      // we don't have to special case for the runtime checkout.
      File valgrindFile = new File('runtime/tools/valgrind.py');
      if (!valgrindFile.existsSync()) {
        valgrindFile = new File('../runtime/tools/valgrind.py');
      }
      String valgrind = valgrindFile.fullPathSync();
      configuration['special-command'] = 'python -u $valgrind @';
    }

    // Use verbose progress indication for verbose output unless buildbot
    // progress indication is requested.
    if (configuration['verbose'] && configuration['progress'] != 'buildbot') {
      configuration['progress'] = 'verbose';
    }

    // Create the artificial 'unchecked' options that test status files
    // expect.
    configuration['unchecked'] = !configuration['checked'];
    configuration['host_unchecked'] = !configuration['host_checked'];

    String runtime = configuration['runtime'];
    if (runtime == 'firefox') {
      configuration['runtime'] == 'ff';
    }

    configuration['browser'] = TestUtils.isBrowserRuntime(runtime);

    // Set the javascript command line flag for less verbose status files.
    configuration['jscl'] = TestUtils.isJsCommandLineRuntime(runtime);

    // Expand the test selectors into a suite name and a simple
    // regular expressions to be used on the full path of a test file
    // in that test suite. If no selectors are explicitly given use
    // the default suite patterns.
    var selectors = configuration['selectors'];
    if (selectors is !Map) {
      if (selectors == null) {
        selectors = new List.from(defaultTestSelectors);
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
          pattern = pattern.replaceAll('/', '.*');
        } else {
          pattern = ".*";
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
      if (updater !== null) {
        updater.update();
      }
    }

    // Adjust default timeout based on mode, compiler, and sometimes runtime.
    if (configuration['timeout'] == -1) {
      var timeout = 60;
      switch (configuration['compiler']) {
        case 'dartc':
          timeout *= 4;
          break;
        case 'dart2js':
          // TODO(ahe): Restore the timeout of 30 seconds when dart2js
          // compile-time performance has improved.
          timeout = 60;
          if (configuration['mode'] == 'debug') {
            timeout *= 8;
          }
          if (configuration['host_checked']) {
            timeout *= 16;
          }
          if (configuration['checked']) {
            timeout *= 2;
          }
          if (Contains(configuration['runtime'],
                       const ['ie', 'ff', 'chrome', 'safari', 'opera'])) {
            timeout *= 8; // Allow additional time for browser testing to run.
          }
          break;
        default:
          if (configuration['mode'] == 'debug') {
            timeout *= 2;
          }
          if (Contains(configuration['runtime'], const ['drt', 'dartium'])) {
            timeout *= 4; // Allow additional time for browser testing to run.
          }
          break;
      }
      configuration['timeout'] = timeout;
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
    print('usage: dart test.dart [options]\n');
    print('Options:\n');
    for (var option in _options) {
      print('${option.name}: ${option.description}.');
      for (var name in option.keys) {
        assert(name.startsWith('-'));
        var buffer = new StringBuffer();;
        buffer.add(name);
        if (option.type == 'bool') {
          assert(option.values.isEmpty());
        } else {
          buffer.add(name.startsWith('--') ? '=' : ' ');
          if (option.type == 'int') {
            assert(option.values.isEmpty());
            buffer.add('n (default: ${option.defaultValue})');
          } else {
            buffer.add('[');
            bool first = true;
            for (var value in option.values) {
              if (!first) buffer.add(", ");
              if (value == option.defaultValue) buffer.add('*');
              buffer.add(value);
              first = false;
            }
            buffer.add(']');
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
      if (option.keys.some((key) => key == name)) {
        return option;
      }
    }
    print('Unknown test option $name');
    exit(1);
  }


  List<_TestOptionSpecification> _options;
}
