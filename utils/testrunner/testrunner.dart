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
 * testrunner supports simple DOM render tests. These use expected values
 * for the text render output from DumpRenderTree. When running a test in DRT
 * testrunner will see if there is a file with a .render extension in the
 * same directory as the test file and with the same base file name. If so
 * it will do additional checks of the rendered layout.
 *
 * Here is a simple example test:
 *
 *     #library('sample');
 *     #import('dart:html');
 *     #import('pkg:unittest/unittest.dart');
 *
 *     main() {
 *       group('foo', () {
 *         test('test 1', () {
 *           document.body.nodes.add(new Element.html("<p>Test 1</p>"));
 *         });
 *         test('test 2', () {
 *           document.body.nodes.add(new Element.html("<p>Test 2</p>"));
 *         });
 *      });
 *    }
 *
 * And a sample matching .render file:
 *
 *     [foo test 1]
 *     RenderBlock {P} at (0,0) size 284x20
 *       RenderText {#text} at (0,0) size 38x19
 *         text run at (0,0) width 38: "Test 1"
 *     [foo test 2]
 *     RenderBlock {P} at (0,0) size 284x20
 *       RenderText {#text} at (0,0) size 38x19
 *         text run at (0,0) width 38: "Test 2"
 *
 * Note that the render content is only the content inside the <body> element,
 * not including the body element itself.
 *
 * Running testrunner with a `--generate-renders` flag will make it create
 * .render files for you.
 */

// TODO - layout tests that use PNGs rather than DRT text render dumps.
#library('testrunner');
#import('dart:io');
#import('dart:isolate');
#import('dart:math');
#import('../../pkg/args/args.dart');

#source('configuration.dart');
#source('dart_task.dart');
#source('dart_wrap_task.dart');
#source('dart2js_task.dart');
#source('delete_task.dart');
#source('drt_task.dart');
#source('html_wrap_task.dart');
#source('macros.dart');
#source('options.dart');
#source('pipeline_runner.dart');
#source('pipeline_task.dart');
#source('run_process_task.dart');
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

/** The full set of options. */
Configuration config;

/**
 * The user can specify output streams on the command line, using 'none',
 * 'stdout', 'stderr', or a file path; [getStream] will take such a name
 * and return an appropriate [OutputStream].
 */
OutputStream getStream(String name) {
  if (name == 'none') {
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
 * Generate a templated list of commands that should be executed for each test
 * file. Each command is an instance of a [PipelineTask].
 * The commands can make use of a number of metatokens that will be
 * expanded before execution (see the [Meta] class for details).
 */
List getPipelineTemplate(String runtime, bool checkedMode, bool keepTests) {
  var pipeline = new List();
  var pathSep = Platform.pathSeparator;
  Directory tempDir = new Directory(config.tempDir);

  if (!tempDir.existsSync()) {
    tempDir.createSync();
  }

  // Templates for the generated files that are used to run the wrapped test.
  var basePath =
      '${config.tempDir}$pathSep${Macros.flattenedDirectory}_'
      '${Macros.filenameNoExtension}';
  var tempDartFile = '${basePath}.dart';
  var tempJsFile = '${basePath}.js';
  var tempHTMLFile = '${basePath}.html';
  var tempCSSFile = '${basePath}.css';

  // Add step for wrapping in Dart scaffold.
  pipeline.add(new DartWrapTask(Macros.fullFilePath, tempDartFile));

  // Add the compiler step, unless we are running native Dart.
  if (runtime == 'drt-js') {
    if (checkedMode) {
      pipeline.add(new Dart2jsTask.checked(tempDartFile, tempJsFile));
    } else {
      pipeline.add(new Dart2jsTask(tempDartFile, tempJsFile));
    }
  }

  // Add step for wrapping in HTML, if we are running in DRT.
  if (runtime != 'vm') {
    // The user can have pre-existing HTML and CSS files for the test in the
    // same directory and using the same name. The paths to these are matched
    // by these two templates.
    var HTMLFile =
        '${Macros.directory}$pathSep${Macros.filenameNoExtension}.html';
    var CSSFile =
        '${Macros.directory}$pathSep${Macros.filenameNoExtension}.css';
    pipeline.add(new HtmlWrapTask(Macros.fullFilePath,
        HTMLFile, tempHTMLFile, CSSFile, tempCSSFile));
  }

  // Add the execution step.
  if (runtime == 'vm') {
    if (checkedMode) {
      pipeline.add(new DartTask.checked(tempDartFile));
    } else {
      pipeline.add(new DartTask(tempDartFile));
    }
  } else {
    pipeline.add(new DrtTask(Macros.fullFilePath, tempHTMLFile));
  }
  return pipeline;
}

/**
 * Given a [List] of [testFiles], either print the list or create
 * and execute pipelines for the files.
 */
void processTests(List pipelineTemplate, List testFiles) {
  _outStream = getStream(config.outputStream);
  _logStream = getStream(config.logStream);
  if (config.listFiles) {
    if (_outStream != null) {
      for (var i = 0; i < testFiles.length; i++) {
        _outStream.writeString(testFiles[i]);
        _outStream.writeString('\n');
      }
    }
  } else {
    // Create execution pipelines for each test file from the pipeline
    // template and the concrete test file path, and then kick
    // off execution of the first batch.
    _tasks = new List();
    for (var i = 0; i < testFiles.length; i++) {
      _tasks.add(new PipelineRunner(pipelineTemplate, testFiles[i],
          config.verbose, completeHandler));
    }

    _maxTasks = min(config.maxTasks, testFiles.length);
    _numTasks = 0;
    _nextTask = 0;
    spawnTasks();
  }
}

/** Execute as many tasks as possible up to the maxTasks limit. */
void spawnTasks() {
  while (_numTasks < _maxTasks && _nextTask < _tasks.length) {
    ++_numTasks;
    _tasks[_nextTask++].execute();
  }
}

/**
 * Handle the completion of a task. Kick off more tasks if we
 * have them.
 */
void completeHandler(String testFile,
                     int exitCode,
                     List _stdout,
                     List _stderr) {
  writelog(_stdout, _outStream, _logStream);
  writelog(_stderr, _outStream, _logStream);
  --_numTasks;
  if (exitCode == 0 || !config.stopOnFailure) {
    spawnTasks();
  }
  if (_numTasks == 0) {
    // No outstanding tasks; we're all done.
    // We could later print a summary report here.
  }
}

/**
 * Our tests are configured so that critical messages have a '###' prefix.
 * [writeLog] takes the output from a pipeline execution and writes it to
 * our output streams. It will strip the '###' if necessary on critical
 * messages; other messages will only be written if verbose output was
 * specified.
 */
void writelog(List messages, OutputStream out, OutputStream log) {
  for (var i = 0; i < messages.length; i++) {
    var msg = messages[i];
    if (msg.startsWith('###')) {
      if (out != null) {
        out.writeString(msg.substring(3));
        out.writeString('\n');
      }
    } else if (config.verbose) {
      if (log != null) {
        log.writeString(msg);
        log.writeString('\n');
      }
    }
  }
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
      config = new Configuration(optionsParser, options);
      // Build the command templates needed for test compile and execute.
      var pipelineTemplate = getPipelineTemplate(config.runtime,
                                                 config.checkedMode,
                                                 config.keepTests);
      if (pipelineTemplate != null) {
        // Build the list of tests and then execute them.
        List dirs = options.rest;
        if (dirs.length == 0) {
          dirs.add('.'); // Use current working directory as default.
        }
        buildFileList(dirs,
            new RegExp(options['test-file-pattern']), options['recurse'],
            (f) => processTests(pipelineTemplate, f));
      }
    }
  }
}


