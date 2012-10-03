//#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * testrunner is a program to run Dart unit tests. Unlike $DART/tools/test.dart,
 * this program is intended for 3rd parties to be able to run unit tests in
 * a batched fashion. As such, it adds some features and removes others. Some
 * of the removed features are:
 *
 *   - No support for test.status files. The assumption is that tests are
 *     expected to pass.
 *   - A restricted set of runtimes. The assumption here is that the Dart
 *     libraries deal with platform dependencies, and so the primary
 *     SKUs that a user of this app would be concerned with would be
 *     Dart-native versus compiled, and client (browser) vs server. To
 *     support these, three runtimes are allowed: 'drt-dart' and 'drt-js' (for
 *     client native and client-compiled, respectively), and 'vm'
 *     (for server-side native).
 *   - No sharding of test processes.
 *
 * On the other hand, a number of features have been added:
 *
 *   - The ability to filter tests by group or name.
 *   - The ability to run tests in isolates.
 *   - The ability to customize the format of the test result messages.
 *   - The ability to list the tests available.
 *
 * By default, testrunner will run all tests in the current directory.
 * With a -R option, it will recurse into subdirectories.
 * Directories can also be specified on the command line; if
 * any are specified they will override the use of the current directory.
 * All files that match the `--test-file-pattern` will be included; by default
 * this is files with names that end in _test.dart.
 *
 * Options can be specified on the command line, via a configuration
 * file (`--config`) or via a test.config file in the test directory,
 * in decreasing order of priority.
 *
 * The three runtimes are:
 *
 *   vm - run native Dart in the VM; i.e. using $DARTSDK/dart-sdk/bin/dart.
 *   drt-dart - run native Dart in DumpRenderTree, the headless version of
 *       Dartium, which is located in $DARTSDK/chromium/DumpRenderTree, if
 *       you intsalled the SDK that is bundled with the editor, or available
 *       from http://gsdview.appspot.com/dartium-archive/continuous/
 *       otherwise.
 *
 *   drt-js - run Dart compiled to Javascript in DumpRenderTree.
 *
 * testrunner supports simple DOM render tests. These can use expected values
 * for the render output from DumpRenderTree, either are textual DOM
 * descriptions (`--layout-tests`) or pixel renderings (`--pixel-tests`).
 * When running layout tests, testrunner will see if there is a file with
 * a .png or a .txt extension in a directory with the same name as the
 * test file (without extension) and with the test name as the file name.
 * For example, if there is a test file foo_test.dart with tests 'test1'
 * and 'test2', it will look for foo_test/test1.txt and foo_test/test2.txt
 * for text render layout files. If these exist it will do additional checks
 * of the rendered layout; if not, the test will fail.
 *
 * Layout file (re)generation can be done using `--regenerate`. This will
 * create or update the layout files (and implicitly pass the tests).
 *
 * The wrapping and execution of test files is handled by test_pipeline.dart,
 * which is run in an isolate. The `--pipeline` argument can be used to
 * specify a different script for running a test file pipeline, allowing
 * customization of the pipeline.
 */

// TODO - layout tests that use PNGs rather than DRT text render dumps.
#library('testrunner');
#import('dart:io');
#import('dart:isolate');
#import('dart:math');
#import('../../pkg/args/lib/args.dart');

#source('options.dart');
#source('utils.dart');

/** The set of [PipelineRunner]s to execute. */
List _tasks;

/** The maximum number of pipelines that can run concurrently. */
int _maxTasks;

/** The number of pipelines currently running. */
int _numTasks;

/** The index of the next pipeline runner to execute. */
int _nextTask;

/** The stream to use for high-value messages, like test results. */
OutputStream _outStream;

/** The stream to use for low-value messages, like verbose output. */
OutputStream _logStream;

/**
 * The user can specify output streams on the command line, using 'none',
 * 'stdout', 'stderr', or a file path; [getStream] will take such a name
 * and return an appropriate [OutputStream].
 */
OutputStream getStream(String name) {
  if (name == null || name == 'none') {
    return null;
  }
  if (name == 'stdout') {
    return stdout;
  }
  if (name == 'stderr') {
    return stderr;
  }
  return new File(name).openOutputStream(FileMode.WRITE);
}

/**
 * Given a [List] of [testFiles], either print the list or create
 * and execute pipelines for the files.
 */
void processTests(Map config, List testFiles) {
  _outStream = getStream(config['out']);
  _logStream = getStream(config['log']);
  if (config['list-files']) {
    if (_outStream != null) {
      for (var i = 0; i < testFiles.length; i++) {
        _outStream.writeString(testFiles[i]);
        _outStream.writeString('\n');
      }
    }
  } else {
    _maxTasks = min(config['tasks'], testFiles.length);
    _numTasks = 0;
    _nextTask = 0;
    spawnTasks(config, testFiles);
  }
}

/** Execute as many tasks as possible up to the maxTasks limit. */
void spawnTasks(Map config, List testFiles) {
  var verbose = config['verbose'];
  // If we were running in the VM and the immediate flag was set, we have
  // already printed the important messages (i.e. prefixed with ###),
  // so we should skip them now.
  var skipNonVerbose = config['immediate'] && config['runtime'] == 'vm';
  while (_numTasks < _maxTasks && _nextTask < testFiles.length) {
    ++_numTasks;
    var testfile = testFiles[_nextTask++];
    config['testfile'] = testfile;
    ReceivePort port = new ReceivePort();
    port.receive((msg, _) {
      List stdout = msg[0];
      List stderr = msg[1];
      List log = msg[2];
      int exitCode = msg[3];
      writelog(stdout, _outStream, _logStream, verbose, skipNonVerbose);
      writelog(stderr, _outStream, _logStream, true, skipNonVerbose);
      writelog(log, _outStream, _logStream, verbose, skipNonVerbose);
      port.close();
      --_numTasks;
      if (exitCode == 0 || !config['stopOnFailure']) {
        spawnTasks(config, testFiles);
      }
      if (_numTasks == 0) {
        // No outstanding tasks; we're all done.
        // We could later print a summary report here.
      }
    });
    SendPort s = spawnUri(config['pipeline']);
    s.send(config, port.toSendPort());
  }
}

/**
 * Our tests are configured so that critical messages have a '###' prefix.
 * [writeLog] takes the output from a pipeline execution and writes it to
 * our output streams. It will strip the '###' if necessary on critical
 * messages; other messages will only be written if verbose output was
 * specified.
 */
void writelog(List messages, OutputStream out, OutputStream log,
              bool includeVerbose, bool skipNonVerbose) {
  for (var i = 0; i < messages.length; i++) {
    var msg = messages[i];
    if (msg.startsWith('###')) {
      if (!skipNonVerbose && out != null) {
        out.writeString(msg.substring(3));
        out.writeString('\n');
      }
    } else if (includeVerbose && log != null) {
      log.writeString(msg);
      log.writeString('\n');
    }
  }
}

sanitizeConfig(Map config, ArgParser parser) {
  config['layout'] = config['layout-text'] || config['layout-pixel'];

  // TODO - check if next three are actually used.
  config['runInBrowser'] = (config['runtime'] != 'vm');
  config['verbose'] = (config['log'] != 'none' && !config['list-groups']);
  config['filtering'] = (config['include'].length > 0 ||
      config['exclude'].length > 0);

  config['timeout'] = int.parse(config['timeout']);
  config['tasks'] = int.parse(config['tasks']);

  config['keep-files'] = (config['keep-files'] &&
      !(config['list-groups'] || config['list-tests']));

  var dartsdk = config['dartsdk'];
  var pathSep = Platform.pathSeparator;

  if (dartsdk != null) {
    if (parser.getDefault('dart2js') == config['dart2js']) {
      config['dart2js'] =
          '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart2js';
    }
    if (parser.getDefault('dart') == config['dart']) {
      config['dart'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart';
    }
    if (parser.getDefault('drt') == config['drt']) {
      config['drt'] = '$dartsdk${pathSep}chromium${pathSep}DumpRenderTree';
    }
  }

  config['unittest'] = makePathAbsolute(config['unittest']);
  config['drt'] = makePathAbsolute(config['drt']);
  config['dart'] = makePathAbsolute(config['dart']);
  config['dart2js'] = makePathAbsolute(config['dart2js']);
  config['runnerDir'] = runnerDirectory;
}

main() {
  var optionsParser = getOptionParser();
  var options = loadConfiguration(optionsParser);
  if (isSane(options)) {
    if (options['list-options']) {
      printOptions(optionsParser, options, false, stdout);
    } else if (options['list-all-options']) {
        printOptions(optionsParser, options, true, stdout);
    } else {
      var config = new Map();
      for (var option in options.options) {
        config[option] = options[option];
      }
      var rest = [];
      // Process the remmaining command line args. If they look like
      // options then split them up and add them to the map; they may be for
      // custom pipelines.
      for (var other in options.rest) {
        var idx;
        if (other.startsWith('--') && (idx = other.indexOf('=')) > 0) {
          var optName = other.substring(2, idx);
          var optValue = other.substring(idx+1);
          config[optName] = optValue;
        } else {
          rest.add(other);
        }
      }

      sanitizeConfig(config, optionsParser);

      // Build the list of tests and then execute them.
      List dirs = rest;
      if (dirs.length == 0) {
        dirs.add('.'); // Use current working directory as default.
      }
      buildFileList(dirs,
          new RegExp(options['test-file-pattern']), options['recurse'],
          (f) => processTests(config, f));
    }
  }
}


