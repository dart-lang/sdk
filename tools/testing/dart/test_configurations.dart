// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_configurations;

import "dart:async";
import 'dart:io';
import "dart:math" as math;

import "browser_controller.dart";
import "co19_test_config.dart";
import "http_server.dart";
import "path.dart";
import "test_progress.dart";
import "test_runner.dart";
import "test_suite.dart";
import "utils.dart";
import "vm_test_config.dart";

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
    new Path('runtime/bin/vmservice'),
    new Path('samples'),
    new Path('samples-dev'),
    new Path('tests/benchmark_smoke'),
    new Path('tests/chrome'),
    new Path('tests/compiler/dart2js'),
    new Path('tests/compiler/dart2js_extra'),
    new Path('tests/compiler/dart2js_native'),
    new Path('tests/corelib'),
    new Path('tests/html'),
    new Path('tests/isolate'),
    new Path('tests/language'),
    new Path('tests/lib'),
    new Path('tests/standalone'),
    new Path('tests/try'),
    new Path('tests/utils'),
    new Path('utils/tests/css'),
    new Path('utils/tests/peg'),
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

  Browser.deleteCache = firstConf['clear_browser_cache'];

  if (recordingPath != null && recordingOutputPath != null) {
    print("Fatal: Can't have the '--record_to_file' and '--replay_from_file'"
          "at the same time. Exiting ...");
    exit(1);
  }

  if (!firstConf['append_logs'])  {
    var files = [new File(TestUtils.flakyFileName()),
                 new File(TestUtils.testOutcomeFileName())];
    for (var file in files) {
      if (file.existsSync()) {
        file.deleteSync();
      }
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
  if (configurations.length > 1 &&
      (configurations[0]['test_server_port'] != 0 ||
       configurations[0]['test_server_cross_origin_port'] != 0)) {
    print("If the http server ports are specified, only one configuration"
          " may be run at a time");
    exit(1);
  }
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
                                       conf['runtime'],
                                       null,
                                       conf['package_root']);
      serverFutures.add(servers.startServers(conf['local_ip'],
          port: conf['test_server_port'],
          crossOriginPort: conf['test_server_cross_origin_port']));
      conf['_servers_'] = servers;
      if (verbose) {
        serverFutures.last.then((_) {
          var commandline = servers.httpServerCommandline();
          print('Started HttpServers: $commandline');
        });
      }
    }

    if (conf['runtime'].startsWith('ie')) {
      // NOTE: We've experienced random timeouts of tests on ie9/ie10. The
      // underlying issue has not been determined yet. Our current hypothesis
      // is that windows does not handle the IE processes independently.
      // If we have more than one browser and kill a browser we are seeing
      // issues with starting up a new browser just after killing the hanging
      // browser.
      maxBrowserProcesses = 1;
    } else if (conf['runtime'].startsWith('safari')) {
      // Safari does not allow us to run from a fresh profile, so we can only
      // use one browser. Additionally, you can not start two simulators
      // for mobile safari simultainiously.
      maxBrowserProcesses = 1;
    } else if (conf['runtime'] == 'chrome' &&
               Platform.operatingSystem == 'macos') {
      // Chrome on mac results in random timeouts.
      maxBrowserProcesses = math.max(1, maxBrowserProcesses ~/ 2);
    }

    // If we specifically pass in a suite only run that.
    if (conf['suite_dir'] != null) {
      var suite_path = new Path(conf['suite_dir']);
      testSuites.add(new PKGTestSuite(conf, suite_path));
    } else {
      for (String key in selectors.keys) {
        if (key == 'co19') {
          testSuites.add(new Co19TestSuite(conf));
        } else if (conf['compiler'] == 'none' &&
                   conf['runtime'] == 'vm' &&
                   key == 'vm') {
          // vm tests contain both cc tests (added here) and dart tests (added
          // in [TEST_SUITE_DIRECTORIES]).
          testSuites.add(new VMTestSuite(conf));
        } else if (conf['analyzer']) {
          if (key == 'analyze_library') {
            testSuites.add(new AnalyzeLibraryTestSuite(conf));
          }
        } else if (conf['compiler'] == 'none' &&
                   conf['runtime'] == 'vm' &&
                   key == 'pkgbuild') {
          if (!conf['use_repository_packages'] &&
              !conf['use_public_packages']) {
            print("You need to use either --use-repository-packages or "
                  "--use-public-packages with the pkgbuild test suite!");
            exit(1);
          }
          if (!conf['use_sdk']) {
            print("Running the 'pkgbuild' test suite requires "
                  "passing the '--use-sdk' to test.py");
            exit(1);
          }
          testSuites.add(
              new PkgBuildTestSuite(conf, 'pkgbuild', 'pkg/pkgbuild.status'));
        } else if (key == 'pub') {
          // TODO(rnystrom): Move pub back into TEST_SUITE_DIRECTORIES once
          // #104 is fixed.
          testSuites.add(new StandardTestSuite(conf, 'pub',
              new Path('sdk/lib/_internal/pub_generated'),
              ['sdk/lib/_internal/pub/pub.status'],
              isTestFilePredicate: (file) => file.endsWith('_test.dart'),
              recursive: true));
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
  if (firstConf['write_test_outcome_log']) {
    eventListener.add(new TestOutcomeLogWriter());
  }
  if (firstConf['copy_coredumps']) {
    eventListener.add(new UnexpectedCrashDumpArchiver());
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
