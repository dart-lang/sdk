#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is the entrypoint of the dart test suite.  This suite is used
 * to test:
 *
 *     1. the dart vm
 *     2. the dart2js compiler
 *     3. the static analyzer
 *     4. the dart core library
 *     5. other standard dart libraries (DOM bindings, ui libraries,
 *            io libraries etc.)
 *
 * This script is normally invoked by test.py.  (test.py finds the dart vm
 * and passses along all command line arguments to this script.)
 *
 * The command line args of this script are documented in
 * "tools/testing/test_options.dart".
 *
 */

library test;

import "dart:async";
import "dart:io";
import "dart:math" as math;
import "testing/dart/browser_controller.dart";
import "testing/dart/http_server.dart";
import "testing/dart/record_and_replay.dart";
import "testing/dart/test_options.dart";
import "testing/dart/test_progress.dart";
import "testing/dart/test_runner.dart";
import "testing/dart/test_suite.dart";
import "testing/dart/utils.dart";

import "../runtime/tests/vm/test_config.dart";
import "../tests/co19/test_config.dart";
import "../tests/lib/analyzer/test_config.dart";

/**
 * The directories that contain test suites which follow the conventions
 * required by [StandardTestSuite]'s forDirectory constructor.
 * New test suites should follow this convention because it makes it much
 * simpler to add them to test.dart.  Existing test suites should be
 * moved to here, if possible.
*/
final TEST_SUITE_DIRECTORIES = [
    new Path('pkg'),
    new Path('runtime/tests/vm'),
    new Path('samples/tests/samples'),
    new Path('tests/benchmark_smoke'),
    new Path('tests/chrome'),
    new Path('tests/compiler/dart2js'),
    new Path('tests/compiler/dart2js_extra'),
    new Path('tests/compiler/dart2js_foreign'),
    new Path('tests/compiler/dart2js_native'),
    new Path('tests/corelib'),
    new Path('tests/html'),
    new Path('tests/isolate'),
    new Path('tests/json'),
    new Path('tests/language'),
    new Path('tests/lib'),
    new Path('tests/standalone'),
    new Path('tests/utils'),
    new Path('utils/tests/css'),
    new Path('utils/tests/peg'),
    new Path('sdk/lib/_internal/pub'),
    // TODO(amouravski): move these to tests/ once they no longer rely on weird
    // dependencies.
    new Path('sdk/lib/_internal/dartdoc'),
    new Path('tools/dom/docs'),
];

void testConfigurations(List<Map> configurations) {
  var startTime = new DateTime.now();
  // Extract global options from first configuration.
  var firstConf = configurations[0];
  var maxProcesses = firstConf['tasks'];
  var progressIndicator = firstConf['progress'];
  // TODO(kustermann): Remove this option once the buildbots don't use it
  // anymore.
  var failureSummary = firstConf['failure-summary'];
  BuildbotProgressIndicator.stepName = firstConf['step_name'];
  var verbose = firstConf['verbose'];
  var printTiming = firstConf['time'];
  var listTests = firstConf['list'];

  var recordingPath = firstConf['record_to_file'];
  var recordingOutputPath = firstConf['replay_from_file'];

  // We set a special flag in the safari browser if we need to clear out
  // the cache before running.
  Safari.deleteCache = firstConf['clear_safari_cache'];

  if (recordingPath != null && recordingOutputPath != null) {
    print("Fatal: Can't have the '--record_to_file' and '--replay_from_file'"
          "at the same time. Exiting ...");
    exit(1);
  }

  if (!firstConf['append_logs'])  {
    var file = new File(TestUtils.flakyFileName());
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  DebugLogger.init(firstConf['write_debug_log'] ?
      TestUtils.debugLogfile() : null, append: firstConf['append_logs']);

  // Print the configurations being run by this execution of
  // test.dart. However, don't do it if the silent progress indicator
  // is used. This is only needed because of the junit tests.
  if (progressIndicator != 'silent') {
    List output_words = configurations.length > 1 ?
        ['Test configurations:'] : ['Test configuration:'];
    for (Map conf in configurations) {
      List settings = ['compiler', 'runtime', 'mode', 'arch']
          .map((name) => conf[name]).toList();
      if (conf['checked']) settings.add('checked');
      output_words.add(settings.join('_'));
    }
    print(output_words.join(' '));
  }

  var runningBrowserTests = configurations.any((config) {
    return TestUtils.isBrowserRuntime(config['runtime']);
  });

  List<Future> serverFutures = [];
  var testSuites = new List<TestSuite>();
  var maxBrowserProcesses = maxProcesses;
  for (var conf in configurations) {
    Map<String, RegExp> selectors = conf['selectors'];
    var useContentSecurityPolicy = conf['csp'];
    if (!listTests && runningBrowserTests) {
      // Start global http servers that serve the entire dart repo.
      // The http server is available on window.location.port, and a second
      // server for cross-domain tests can be found by calling
      // getCrossOriginPortNumber().
      var servers = new TestingServers(new Path(TestUtils.buildDir(conf)),
                                       useContentSecurityPolicy,
                                       conf['runtime']);
      serverFutures.add(servers.startServers(conf['local_ip']));
      conf['_servers_'] = servers;
      if (verbose) {
        serverFutures.last.then((_) {
          var commandline = servers.httpServerCommandline();
          print('Started HttpServers: $commandline');
        });
      }
    }

    // There should not be more than one InternetExplorerDriver instance
    // running at a time. For details, see
    // http://code.google.com/p/selenium/wiki/InternetExplorerDriver.
    if (conf['runtime'].startsWith('ie') && !conf["use_browser_controller"]) {
      maxBrowserProcesses = 1;
    } else if (conf['runtime'].startsWith('safari') &&
               conf['use_browser_controller']) {
      // Safari does not allow us to run from a fresh profile, so we can only
      // use one browser.
      maxBrowserProcesses = 1;
    }

    for (String key in selectors.keys) {
      if (key == 'co19') {
        testSuites.add(new Co19TestSuite(conf));
      } else if (conf['runtime'] == 'vm' && key == 'vm') {
        // vm tests contain both cc tests (added here) and dart tests (added
        // in [TEST_SUITE_DIRECTORIES]).
        testSuites.add(new VMTestSuite(conf));
      } else if (conf['analyzer']) {
        if (key == 'analyze_library') {
          testSuites.add(new AnalyzeLibraryTestSuite(conf));
        }
        if (key == 'analyze_tests') {
          testSuites.add(new AnalyzeTestsTestSuite(conf));
        }
      }
    }

    for (final testSuiteDir in TEST_SUITE_DIRECTORIES) {
      final name = testSuiteDir.filename;
      if (selectors.containsKey(name)) {
        testSuites.add(
            new StandardTestSuite.forDirectory(conf, testSuiteDir));
      }
    }
  }

  void allTestsFinished() {
    for (var conf in configurations) {
      if (conf.containsKey('_servers_')) {
        conf['_servers_'].stopServers();
      }
    }
    DebugLogger.close();
  }

  var eventListener = [];
  if (progressIndicator != 'silent') {
    var printFailures = true;
    var formatter = new Formatter();
    if (progressIndicator == 'color') {
      progressIndicator = 'compact';
      formatter = new ColorFormatter();
    }
    if (progressIndicator == 'diff') {
      progressIndicator = 'compact';
      formatter = new ColorFormatter();
      printFailures = false;
      eventListener.add(new StatusFileUpdatePrinter());
    }
    eventListener.add(new SummaryPrinter());
    eventListener.add(new FlakyLogWriter());
    if (printFailures) {
      // The buildbot has it's own failure summary since it needs to wrap it
      // into '@@@'-annotated sections.
      var printFailureSummary = progressIndicator != 'buildbot';
      eventListener.add(new TestFailurePrinter(printFailureSummary, formatter));
    }
    eventListener.add(progressIndicatorFromName(progressIndicator,
                                                startTime,
                                                formatter));
    if (printTiming) {
      eventListener.add(new TimingPrinter(startTime));
    }
    eventListener.add(new SkippedCompilationsPrinter());
    eventListener.add(new LeftOverTempDirPrinter());
  }
  eventListener.add(new ExitCodeSetter());

  void startProcessQueue() {
    // [firstConf] is needed here, since the ProcessQueue needs to know the
    // settings of 'noBatch' and 'local_ip'
    new ProcessQueue(firstConf,
                     maxProcesses,
                     maxBrowserProcesses,
                     startTime,
                     testSuites,
                     eventListener,
                     allTestsFinished,
                     verbose,
                     listTests,
                     recordingPath,
                     recordingOutputPath);
  }

  // Start all the HTTP servers required before starting the process queue.
  if (serverFutures.isEmpty) {
    startProcessQueue();
  } else {
    Future.wait(serverFutures).then((_) => startProcessQueue());
  }
}

Future deleteTemporaryDartDirectories() {
  var completer = new Completer();
  var environment = Platform.environment;
  if (environment['DART_TESTING_DELETE_TEMPORARY_DIRECTORIES'] == '1') {
    Directory getTempDir() {
      // dir will be located in the system temporary directory.
      var dir = new Directory('').createTempSync();
      var path = new Path(dir.path).directoryPath;
      dir.deleteSync();
      return new Directory(path.toNativePath());
    }

    // These are the patterns of temporary directory names created by
    // 'Directory.createTempSync()' on linux/macos and windows.
    var regExp;
    if (['macos', 'linux'].contains(Platform.operatingSystem)) {
      regExp = new RegExp(r'^temp_dir1_......$');
    } else {
      regExp = new RegExp(r'tempdir-........-....-....-....-............$');
    }

    getTempDir().list().listen((directoryEntry) {
      if (directoryEntry is Directory) {
        if (regExp.hasMatch(new Path(directoryEntry.path).filename)) {
          try {
            directoryEntry.deleteSync(recursive: true);
          } catch (error) {
            DebugLogger.error(error);
          }
        }
      }
    }, onDone: completer.complete);
  } else {
    completer.complete();
  }
  return completer.future;
}

void main() {
  deleteTemporaryDartDirectories().then((_) {
    var optionsParser = new TestOptionsParser();
    var configurations = optionsParser.parse(new Options().arguments);
    if (configurations != null && configurations.length > 0) {
      testConfigurations(configurations);
    }
  });
}

