// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_options_parser");

List<String> defaultTestSelectors =
    const ['samples', 'standalone', 'corelib', 'co19', 'language',
           'isolate', 'stub-generator', 'vm'];

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
              'component',
              'The component to test against',
              ['-c', '--component'],
              ['most', 'vm', 'dartc', 'frog', 'frogsh', 'leg'],
              'vm'),
          new _TestOptionSpecification(
              'architecture',
              'The architecture to run tests for',
              ['-a', '--arch'],
              ['all', 'ia32', 'x64', 'simarm'],
              'ia32'),
          new _TestOptionSpecification(
              'system',
              'The operating system to run tests on',
              ['-s', '--system'],
              ['linux', 'macos', 'windows'],
              new Platform().operatingSystem()),
          new _TestOptionSpecification(
              'checked',
              'Run tests in checked mode',
              ['--checked'],
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
              ['compact', 'color', 'line', 'verbose', 'status', 'buildbot'],
              'compact'),
          new _TestOptionSpecification(
              'report',
              'Print a summary report of the number of tests, by expectation.',
              ['--report'],
              [],
              false,
              'bool'),
          new _TestOptionSpecification(
              'tasks',
              'The number of parallel tasks to run',
              ['-j', '--tasks'],
              [],
              new Platform().numberOfProcessors(),
              'int'),
          new _TestOptionSpecification(
              'help',
              'Print list of options',
              ['-h', '--help'],
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
    // Build configuration of default values.
    for (var option in _options) {
      configuration[option.name] = option.defaultValue;
    }
    // Overwrite with the arguments passed to the test script.
    var numArguments = arguments.length;
    for (var i = 0; i < numArguments; i++) {
      // Extract name and value for options.
      var arg = arguments[i];
      var name = '';
      var value = '';
      if (arg.startsWith('--')) {
        if (arg == '--help') {
          _printHelp();
          return null;
        }
        var split = arg.lastIndexOf('=');
        if (split == -1) {
          name = arg;
          value = '';
        } else {
          name = arg.substring(0, split);
          value = arg.substring(split + 1, arg.length);
        }
      } else if (arg.startsWith('-')) {
        if (arg == '-h') {
          _printHelp();
          return null;
        }
        if (arg.length > 2) {
          name = arg.substring(0, 2);
          value = arg.substring(2, arg.length);
        } else {
          name = arg;
          if ((i + 1) >= arguments.length) {
            print('No value supplied for option $name');
            return null;
          }
          value = arguments[++i];
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
      // Find the option specification for the name.
      var spec = _getSpecification(name);
      if (spec == null) {
        print('Unknown test option $name');
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
          configuration[spec.name] = Math.parseInt(value);
        } catch (var e) {
          print('Integer value expected for int option $name');
          exit(1);
        }
      } else {
        assert(spec.type == 'string');
        for (var v in value.split(',')) {
          if (spec.values.lastIndexOf(v) == -1) {
            print('Unknown value ($v) for option $name');
            exit(1);
          }
        }
        configuration[spec.name] = value;
      }
    }
    
    return _expandConfigurations(configuration);
  }


  /**
   * Recursively expand a configuration with multiple values per key
   * into a list of configurations with exactly one value per key.
   */
  List<Map> _expandConfigurations(Map configuration) {

    // TODO(ager): Get rid of this. This is for backwards
    // compatibility with the python test scripts. They use system
    // 'win32' for Windows.
    if (configuration['system'] == 'windows') {
      configuration['system'] = 'win32';
    }

    // Expand the pseudo-values such as 'all'.
    if (configuration['architecture'] == 'all') {
      configuration['architecture'] = 'ia32,x64,simarm';
    }
    if (configuration['mode'] == 'all') {
      configuration['mode'] = 'debug,release';
    }
    if (configuration['component'] == 'most') {
      configuration['component'] = 'vm,dartc';
    }

    // Create the artificial 'unchecked' option that test status files
    // expect.
    configuration['unchecked'] = !configuration['checked'];

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
        }
        pattern = pattern.replaceAll('*', '.*');
        pattern = pattern.replaceAll('/', '.*');
        if (selectorMap.containsKey(suite)) {
          print("Warning: selector '$suite/$pattern' overrides " +
                "previous selector for suite '$suite'");
        }
        selectorMap[suite] = new RegExp(pattern);
      }
      configuration['selectors'] = selectorMap;
    }

    // Expand the architectures.
    var archs = configuration['architecture'];
    if (archs.contains(',')) {
      var result = new List<Map>();
      for (var arch in archs.split(',')) {
        var newConfiguration = new Map.from(configuration);
        newConfiguration['architecture'] = arch;
        result.addAll(_expandConfigurations(newConfiguration));
      }
      return result;
    }

    // Expand modes.
    var modes = configuration['mode'];
    if (modes.contains(',')) {
      var result = new List<Map>();
      for (var mode in modes.split(',')) {
        var newConfiguration = new Map.from(configuration);
        newConfiguration['mode'] = mode;
        result.addAll(_expandConfigurations(newConfiguration));
      }
      return result;
    }

    // Expand components.
    var components = configuration['component'];
    if (components.contains(',')) {
      var result = new List<Map>();
      for (var component in components.split(',')) {
        var newConfiguration = new Map.from(configuration);
        newConfiguration['component'] = component;
        result.addAll(_expandConfigurations(newConfiguration));
      }
      return result;
    }

    // Adjust default timeout based on mode and component.
    if (configuration['timeout'] == -1) {
      var timeout = 60;
      switch (configuration['component']) {
        case 'dartc':
        case 'chromium':
        case 'dartium':
        case 'frogium':
          timeout *= 4;
          break;
        default:
          if (configuration['mode'] == 'debug') {
            timeout *= 2;
          }
          break;
      }
      configuration['timeout'] = timeout;
    }

    return [configuration];
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
          assert(option.values.empty());
        } else {
          buffer.add(name.startsWith('--') ? '=' : ' ');
          if (option.type == 'int') {
            assert(option.values.empty());
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
    return null;
  }


  List<_TestOptionSpecification> _options;
}
