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
 *     expected to pass. Status file support will be added in the future.
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
 *   TODO(antonm): fix the option name.
 *   drt-dart - run native Dart in content shell, the headless version of
 *       Dartium, which is located in $DARTSDK/chromium/content_shell, if
 *       you installed the SDK that is bundled with the editor, or available
 *       from http://gsdview.appspot.com/dartium-archive/continuous/
 *       otherwise.
 *
 *   TODO(antonm): fix the option name.
 *   drt-js - run Dart compiled to Javascript in content shell.
 *
 * testrunner supports simple DOM render tests. These can use expected values
 * for the render output from content shell, either are textual DOM
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
 *
 * Wrapper files are created for tests in the tmp directory, which can be
 * overridden with --tempdir. These files are not removed after the tests
 * are complete, primarily to reduce the amount of times pub must be 
 * executed. You can use --clean-files to force file cleanup. The temp 
 * directories will have pubspec.yaml files auto-generated unless the 
 * original test file directories have such files; in that case the existing
 * files will be copied. Whenever a new pubspec file is copied or 
 * created pub will be run (but not otherwise - so if you want to do 
 * the equivelent of pub update you should use --clean-files and the rerun
 * the tests).
 *
 * TODO(gram): if the user has a pubspec.yaml file,  we should inspect the
 * pubspec.lock file and give useful errors:
 *  - if the lock file doesn't exit, then run pub install
 *  - if it exists and it doesn't have the required packages (unittest or
 *    browser), ask the user to add them and run pub install again.
 */

library testrunner;
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:args/args.dart';

part 'options.dart';
part 'utils.dart';

/** The set of [PipelineRunner]s to execute. */
List _tasks;

/** The maximum number of pipelines that can run concurrently. */
int _maxTasks;

/** The number of pipelines currently running. */
int _numTasks;

/** The index of the next pipeline runner to execute. */
int _nextTask;

/** The sink to use for high-value messages, like test results. */
IOSink _outSink;

/** The sink to use for low-value messages, like verbose output. */
IOSink _logSink;

/**
 * The last temp test directory we accessed; we use this to know if we
 * need to check the pub configuration.
 */
String _testDir;
    
/**
 * The user can specify output streams on the command line, using 'none',
 * 'stdout', 'stderr', or a file path; [getSink] will take such a name
 * and return an appropriate [IOSink].
 */
IOSink getSink(String name) {
  if (name == null || name == 'none') {
    return null;
  }
  if (name == 'stdout') {
    return stdout;
  }
  if (name == 'stderr') {
    return stderr;
  }
  var f = new File(name);
  return f.openWrite();
}

/**
 * Given a [List] of [testFiles], either print the list or create
 * and execute pipelines for the files.
 */
void processTests(Map config, List testFiles) {
  _outSink = getSink(config['out']);
  _logSink = getSink(config['log']);
  if (config['list-files']) {
    if (_outSink != null) {
      for (var i = 0; i < testFiles.length; i++) {
        _outSink.write(testFiles[i]);
        _outSink.write('\n');
      }
    }
  } else {
    _maxTasks = min(config['tasks'], testFiles.length);
    _numTasks = 0;
    _nextTask = 0;
    spawnTasks(config, testFiles);
  }
}

/**
 * Create or update a pubspec for the target test directory. We use the
 * source directory pubspec if available; otherwise we create a minimal one.
 * We return a Future if we are running pub install, or null otherwise.
 */
Future doPubConfig(Path sourcePath, String sourceDir,
                   Path targetPath, String targetDir,
                   String pub, String runtime) {
  // Make sure the target directory exists.
  var d = new Directory(targetDir);
  if (!d.existsSync()) {
    d.createSync(recursive: true);
  }

  // If the source has no pubspec, but the dest does, leave 
  // things as they are. If neither do, create one in dest.

  var sourcePubSpecName = new Path(sourceDir).append("pubspec.yaml").
      toNativePath();
  var targetPubSpecName = new Path(targetDir).append("pubspec.yaml").
      toNativePath();
  var sourcePubSpec = new File(sourcePubSpecName);
  var targetPubSpec = new File(targetPubSpecName);

  if (!sourcePubSpec.existsSync()) {
    if (targetPubSpec.existsSync()) {
      return null;
    } else {
      // Create one.
      if (runtime == 'vm') {
        writeFile(targetPubSpecName,
          "name: testrunner\ndependencies:\n  unittest: any\n");
      } else {
        writeFile(targetPubSpecName,
          "name: testrunner\ndependencies:\n  unittest: any\n  browser: any\n");
      }
    }
  } else {
    if (targetPubSpec.existsSync()) {
      // If there is a source one, and it is older than the target,
      // leave the target as is.
      if (sourcePubSpec.lastModifiedSync().millisecondsSinceEpoch <
          targetPubSpec.lastModifiedSync().millisecondsSinceEpoch) {
        return null;
      }
    }
    // Source exists and is newer than target or there is no target;
    // copy the source to the target. If there is a pubspec.lock file,
    // copy that too.
    var s = sourcePubSpec.readAsStringSync();
    targetPubSpec.writeAsStringSync(s);
    var sourcePubLock = new File(sourcePubSpecName.replaceAll(".yaml", ".lock"));
    if (sourcePubLock.existsSync()) {
      var targetPubLock =
          new File(targetPubSpecName.replaceAll(".yaml", ".lock"));
      s = sourcePubLock.readAsStringSync();
      targetPubLock.writeAsStringSync(s);
    }
  }
  // A new target pubspec was created so run pub install.
  return _processHelper(pub, [ 'install' ], workingDir: targetDir);
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
      writelog(stdout, _outSink, _logSink, verbose, skipNonVerbose);
      writelog(stderr, _outSink, _logSink, true, skipNonVerbose);
      writelog(log, _outSink, _logSink, verbose, skipNonVerbose);
      port.close();
      --_numTasks;
      if (exitCode == 0 || !config['stop-on-failure']) {
        spawnTasks(config, testFiles);
      }
      if (_numTasks == 0) {
        // No outstanding tasks; we're all done.
        // We could later print a summary report here.
      }
    });
    // Get the names of the source and target test files and containing
    // directories.
    var testPath = new Path(testfile);
    var sourcePath = testPath.directoryPath;
    var sourceDir = sourcePath.toNativePath();

    var targetPath = new Path(config["tempdir"]);
    var normalizedTarget = testPath.directoryPath.toNativePath()
        .replaceAll(Platform.pathSeparator, '_')
        .replaceAll(':', '_');
    targetPath = targetPath.append("${normalizedTarget}_${config['runtime']}");
    var targetDir = targetPath.toNativePath();

    config['targetDir'] = targetDir;
    // If this is a new target dir, we need to redo the pub check.
    var f = null;
    if (targetDir != _testDir) {
      f = doPubConfig(sourcePath, sourceDir, targetPath, targetDir,
          config['pub'], config['runtime']);
      _testDir = targetDir;
    }
    var response = new ReceivePort();
    spawnUri(config['pipeline'], [], response)
        .then((_) => f)
        .then((_) => response.first)
        .then((s) { s.send([config, port.sendPort]); });
    if (f != null) break; // Don't do any more until pub is done.
  }
}

/**
 * Our tests are configured so that critical messages have a '###' prefix.
 * [writelog] takes the output from a pipeline execution and writes it to
 * our output sinks. It will strip the '###' if necessary on critical
 * messages; other messages will only be written if verbose output was
 * specified.
 */
void writelog(List messages, IOSink out, IOSink log,
              bool includeVerbose, bool skipNonVerbose) {
  for (var i = 0; i < messages.length; i++) {
    var msg = messages[i];
    if (msg.startsWith('###')) {
      if (!skipNonVerbose && out != null) {
        out.write(msg.substring(3));
        out.write('\n');
      }
    } else if (msg.startsWith('CONSOLE MESSAGE:')) {
      if (!skipNonVerbose && out != null) {
        int idx = msg.indexOf('###');
        if (idx > 0) {
          out.write(msg.substring(idx + 3));
          out.write('\n');
        }
      }
    } else if (includeVerbose && log != null) {
      log.write(msg);
      log.write('\n');
    }
  }
}

normalizeFilter(List filter) {
  // We want the filter to be a quoted string or list of quoted
  // strings.
  for (var i = 0; i < filter.length; i++) {
    var f = filter[i];
    if (f[0] != "'" && f[0] != '"') {
      filter[i] = "'$f'"; // TODO(gram): Quote embedded quotes.
    }
  }
  return filter;
}

void sanitizeConfig(Map config, ArgParser parser) {
  config['layout'] = config['layout-text'] || config['layout-pixel'];
  config['verbose'] = (config['log'] != 'none' && !config['list-groups']);
  config['timeout'] = int.parse(config['timeout']);
  config['tasks'] = int.parse(config['tasks']);

  var dartsdk = config['dartsdk'];
  var pathSep = Platform.pathSeparator;

  if (dartsdk == null) {
    var runner = Platform.executable;
    var idx = runner.indexOf('dart-sdk');
    if (idx < 0) {
      print("Please use --dartsdk option or run using the dart executable "
          "from the Dart SDK");
      exit(0);
    }
    dartsdk = runner.substring(0, idx);
  }
  if (Platform.operatingSystem == 'macos') {
    config['dart2js'] =
        '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart2js';
    config['dart'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart';
    config['pub'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}pub';
    config['drt'] =
      '$dartsdk/chromium/Content Shell.app/Contents/MacOS/Content Shell';
  } else if (Platform.operatingSystem == 'linux') {
    config['dart2js'] =
        '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart2js';
    config['dart'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart';
    config['pub'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}pub';
    config['drt'] = '$dartsdk${pathSep}chromium${pathSep}content_shell';
  } else {
    config['dart2js'] =
        '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart2js.bat';
    config['dart'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}dart.exe';
    config['pub'] = '$dartsdk${pathSep}dart-sdk${pathSep}bin${pathSep}pub.bat';
    config['drt'] = '$dartsdk${pathSep}chromium${pathSep}content_shell.exe';
  }

  for (var prog in [ 'drt', 'dart', 'pub', 'dart2js' ]) {
    config[prog] = makePathAbsolute(config[prog]);
  }
  config['runnerDir'] = runnerDirectory;
  config['include'] = normalizeFilter(config['include']);
  config['exclude'] = normalizeFilter(config['exclude']);
}

main(List<String> arguments) {
  var optionsParser = getOptionParser();
  var options = loadConfiguration(optionsParser, arguments);
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
      var f = buildFileList(dirs,
          new RegExp(config['test-file-pattern']), config['recurse']);
      if (config['sort']) f.sort();
      processTests(config, f);
    }
  }
}
