// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of testrunner;

/** Create and return an options parser for the test runner. */
ArgParser getOptionParser() {
  var parser = new ArgParser();

  parser.addOption('help', abbr: '?',
      help: 'Show usage information.');

  parser.addOption('runtime', abbr: 'r', defaultsTo: 'vm',
      help: 'Where the tests should be run.',
      allowed: ['vm', 'drt-dart', 'drt-js'],
      allowedHelp: {
        'vm': 'Run Dart code natively on the standalone dart vm.',
        'drt-dart': 'Run Dart code natively in the headless version of\n'
          'Chrome, DumpRenderTree.',
        'drt-js': 'Run Dart compiled to JavaScript in the headless version\n'
            'of Chrome, DumpRenderTree.'
      });

  parser.addFlag('checked', defaultsTo: false,
      help: 'Run tests in checked mode.');

  parser.addFlag('layout-text', defaultsTo: false,
      help: 'Run text layout tests.');

  parser.addFlag('layout-pixel', defaultsTo: false,
      help: 'Run pixel layout tests.');

  parser.addOption('timeout', abbr: 't',
      help: 'Timeout in seconds', defaultsTo: '60');

  parser.addOption('tasks', abbr: 'j',
      defaultsTo: Platform.numberOfProcessors.toString(),
      help: 'The number of parallel tasks to run.');

  parser.addOption('out', abbr: 'o', defaultsTo: 'stdout',
      help: 'File to send test results. This should be a '
        'file name or one of stdout, stderr, or none.');

  parser.addOption('list-format',
      defaultsTo:
        '<FILENAME><GROUPNAME><TESTNAME>',
      help: 'Format for test list result output.');

  parser.addOption('pass-format',
      defaultsTo: 'PASS <TIME><FILENAME><GROUPNAME><TESTNAME><MESSAGE>',
      help: 'Format for passing test result output.');

  parser.addOption('fail-format',
      defaultsTo: 'FAIL <TIME><FILENAME><GROUPNAME><TESTNAME><MESSAGE>',
      help: 'Format for failed test result output.');

  parser.addOption('error-format',
      defaultsTo: 'ERROR <TIME><FILENAME><GROUPNAME><TESTNAME><MESSAGE>',
      help: 'Format for tests with errors result output.');

  parser.addFlag('summary', defaultsTo: false,
      help: 'Print a summary of tests passed/failed for each test file.');

  parser.addOption('log', abbr: 'l', defaultsTo: 'none',
      help: 'File to send test log/print output to. This should be a '
        'file name or one of stdout, stderr, or none.');

  // TODO(gram) - add loglevel once we have switched unittest to use the log
  // library.

  parser.addFlag('list-files', defaultsTo: false,
      help: 'List test files only, do not run them.');

  parser.addFlag('list-tests', defaultsTo: false,
      help: 'List tests only, do not run them.');

  parser.addFlag('list-groups', defaultsTo: false,
      help: 'List test groups only, do not run tests.');

  parser.addFlag('keep-files', defaultsTo: false,
      help: 'Keep the generated files in the temporary directory.');

  parser.addFlag('list-options', defaultsTo: false,
      help: 'Print non-default option settings, usable as a test.config.');

  parser.addFlag('list-all-options', defaultsTo: false,
      help: 'Print all option settings, usable as a test.config.');

  parser.addFlag('time',
      help: 'Print timing information after running tests',
      defaultsTo: false);

  parser.addFlag('stop-on-failure', defaultsTo: false,
      help: 'Stop execution upon first failure.');

  parser.addFlag('isolate', defaultsTo: false,
      help: 'Runs each test in a separate isolate.');

  parser.addOption('configfile', help: 'Path to an argument file to load.');

  parser.addOption('dartsdk', help: 'Path to dart SDK.');

  // The defaults here should be the name of the executable, with
  // the assumption that it is available on the PATH.
  parser.addOption('dart2js', help: 'Path to dart2js executable.',
      defaultsTo: 'dart2js');
  parser.addOption('dart',    help: 'Path to dart executable.',
      defaultsTo: 'dart');
  parser.addOption('drt',     help: 'Path to DumpRenderTree executable.',
      defaultsTo: 'drt');

  parser.addOption('tempdir', help: 'Directory to store temp files.',
      defaultsTo: '${Platform.pathSeparator}tmp'
                  '${Platform.pathSeparator}testrunner');

  parser.addOption('test-file-pattern',
      help: 'A regular expression that test file names must match '
        'to be considered', defaultsTo: '_test.dart\$');

  parser.addOption('include',
      help: 'Only run tests from the specified group(s).',
      allowMultiple: true);

  parser.addOption('exclude',
      help: 'Exclude tests from the specified group(s).',
      allowMultiple: true);

  parser.addFlag('recurse', abbr: 'R',
      help: 'Recurse through child directories looking for tests.',
      defaultsTo: false);

  parser.addFlag('immediate',
      help: 'Print test results immediately, instead of at the end of a test '
        'file. Note that in some async cases this may result in multiple '
        'messages for a single test.',
      defaultsTo: false);

  parser.addFlag('regenerate',
      help: 'Regenerate layout test expectation files.',
      defaultsTo: false);

  parser.addFlag('server', help: 'Run an HTTP server.', defaultsTo: false);

  parser.addOption('port', help: 'Port to use for HTTP server');

  parser.addOption('root',
      help: 'Root directory for HTTP server for static files');

  parser.addOption('unittest',  help: '#import path for unit test library.');

  parser.addOption('pipeline',
      help: 'Pipeline script to use to run each test file.',
      defaultsTo: 'run_pipeline.dart');

  return parser;
}

/** Print a value option, quoting it if it has embedded spaces. */
_printValueOption(String name, value, OutputStream stream) {
  if (value.indexOf(' ') >= 0) {
    stream.writeString("--$name='$value'\n");
  } else {
    stream.writeString("--$name=$value\n");
  }
}

/** Print the current option values. */
printOptions(ArgParser parser, ArgResults arguments,
             bool includeDefaults, OutputStream stream) {
  if (stream == null) return;
  for (var name in arguments.options) {
    if (!name.startsWith('list-')) {
      var value = arguments[name];
      var defaultValue = parser.getDefault(name);
      if (value is bool) {
        if (includeDefaults || (value != defaultValue)) {
          stream.writeString('--${value ? "" : "no-"}$name\n');
        }
      } else if (value is List) {
        if (value.length > 0) {
          for (var v in value) {
            _printValueOption(name, v, stream);
          }
        }
      } else if (value != null && (includeDefaults || value != defaultValue)) {
        _printValueOption(name, value, stream);
      }
    }
  }
}

/**
 * Get the test runner configuration. This loads options from multiple
 * sources, in increasing order of priority: a test.config file in the
 * current directory, a test config file specified with --configfile on
 * the command line, and other arguments specified on the command line.
 */
ArgResults loadConfiguration(optionsParser) {
  var options = new List();
  // We first load options from a test.config file in the working directory.
  options.addAll(getFileContents('test.config', false).
      filter((e) => e.trim().length > 0 && e[0] != '#'));
  // Next we look to see if the command line included a -testconfig argument,
  // and if so, load options from that file too; where these are not
  // multi-valued they will take precedence over the ones in test.config.
  var commandLineArgs = new Options().arguments;
  var cfgarg = '--configfile';
  for (var i = 0; i < commandLineArgs.length; i++) {
    if (commandLineArgs[i].startsWith(cfgarg)) {
      if (commandLineArgs[i] == cfgarg) {
        if (i == commandLineArgs.length - 1) {
          throw new Exception('Missing argument to $cfgarg');
        }
        options.addAll(getFileContents(commandLineArgs[++i], true).
            filter((e) => e.trim().length > 0 && e[0] != '#'));
      } else if (commandLineArgs[i].startsWith('$cfgarg=')) {
        options.addAll(
            getFileContents(commandLineArgs[i].substring(cfgarg.length), true).
                filter((e) => e.trim().length > 0 && e[0] != '#'));
      } else {
        throw new Exception('Missing argument to $cfgarg');
      }
    }
  }
  // Finally, we add options from the command line. These have the highest
  // precedence of all.
  options.addAll(commandLineArgs);
  // Now try parse the whole collection of options, and if this fails,
  // issue a usage message.
  try {
    return optionsParser.parse(options);
  } catch (e) {
    print(e);
    print('Usage: testrunner <options> [<directory or file> ...]');
    print(optionsParser.getUsage());
    return null;
  }
}

/** Perform some sanity checking of the configuration. */
bool isSane(ArgResults config) {
  if (config == null) {
    return false;
  }
  if (config['runtime'] == null) {
    print('Missing required option --runtime');
    return false;
  }
  if (config['unittest'] == null) {
    print('Missing required option --unittest');
    return false;
  }
  if (config['include'].length > 0 &&
      config['exclude'].length > 0) {
    print('--include and --exclude are mutually exclusive.');
    return false;
  }
  if ((config['layout-text'] || config['layout-pixel']) &&
      config['runtime'] == 'vm') {
    print('Layout tests must use --runtime values of "drt-dart" or "drt-js"');
    return false;
  }
  return true;
}
