// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'android.dart';
import 'browser_controller.dart';
import 'co19_test_config.dart';
import 'configuration.dart';
import 'path.dart';
import 'test_progress.dart';
import 'test_runner.dart';
import 'test_suite.dart';
import 'utils.dart';
import 'vm_test_config.dart';

/**
 * The directories that contain test suites which follow the conventions
 * required by [StandardTestSuite]'s forDirectory constructor.
 * New test suites should follow this convention because it makes it much
 * simpler to add them to test.dart.  Existing test suites should be
 * moved to here, if possible.
*/
final TEST_SUITE_DIRECTORIES = [
  new Path('third_party/pkg/dartdoc'),
  new Path('pkg'),
  new Path('third_party/pkg_tested'),
  new Path('runtime/tests/vm'),
  new Path('runtime/observatory/tests/service'),
  new Path('runtime/observatory/tests/observatory_ui'),
  new Path('samples'),
  new Path('samples-dev'),
  new Path('tests/compiler/dart2js'),
  new Path('tests/compiler/dart2js_extra'),
  new Path('tests/compiler/dart2js_native'),
  new Path('tests/corelib_2'),
  new Path('tests/html'),
  new Path('tests/isolate'),
  new Path('tests/kernel'),
  new Path('tests/language'),
  new Path('tests/language_strong'),
  new Path('tests/language_2'),
  new Path('tests/lib'),
  new Path('tests/lib_strong'),
  new Path('tests/lib_2'),
  new Path('tests/standalone'),
  new Path('tests/standalone_2'),
  new Path('utils/tests/peg'),
];

// This file is created by gclient runhooks.
final VS_TOOLCHAIN_FILE = new Path("build/win_toolchain.json");

Future testConfigurations(List<Configuration> configurations) async {
  var startTime = new DateTime.now();
  // Extract global options from first configuration.
  var firstConf = configurations[0];
  var maxProcesses = firstConf.taskCount;
  var progressIndicator = firstConf.progress;
  BuildbotProgressIndicator.stepName = firstConf.stepName;
  var verbose = firstConf.isVerbose;
  var printTiming = firstConf.printTiming;
  var listTests = firstConf.listTests;

  var reportInJson = firstConf.reportInJson;

  Browser.resetBrowserConfiguration = firstConf.resetBrowser;

  if (!firstConf.appendLogs) {
    var files = [
      new File(TestUtils.flakyFileName),
      new File(TestUtils.testOutcomeFileName)
    ];
    for (var file in files) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  DebugLogger.init(firstConf.writeDebugLog ? TestUtils.debugLogFilePath : null,
      append: firstConf.appendLogs);

  // Print the configurations being run by this execution of
  // test.dart. However, don't do it if the silent progress indicator
  // is used. This is only needed because of the junit tests.
  if (progressIndicator != Progress.silent) {
    var outputWords = configurations.length > 1
        ? ['Test configurations:']
        : ['Test configuration:'];

    for (var configuration in configurations) {
      var settings = [
        configuration.compiler.name,
        configuration.runtime.name,
        configuration.mode.name,
        configuration.architecture.name
      ];
      if (configuration.isChecked) settings.add('checked');
      if (configuration.isStrong) settings.add('strong');
      if (configuration.useFastStartup) settings.add('fast-startup');
      if (configuration.useEnableAsserts) settings.add('enable-asserts');
      outputWords.add(settings.join('_'));
    }
    print(outputWords.join(' '));
  }

  var runningBrowserTests =
      configurations.any((config) => config.runtime.isBrowser);

  var serverFutures = <Future>[];
  var testSuites = <TestSuite>[];
  var maxBrowserProcesses = maxProcesses;
  if (configurations.length > 1 &&
      (configurations[0].testServerPort != 0 ||
          configurations[0].testServerCrossOriginPort != 0)) {
    print("If the http server ports are specified, only one configuration"
        " may be run at a time");
    exit(1);
  }

  for (var configuration in configurations) {
    if (!listTests && runningBrowserTests) {
      serverFutures.add(configuration.startServers());
    }

    if (configuration.runtime.isIE) {
      // NOTE: We've experienced random timeouts of tests on ie9/ie10. The
      // underlying issue has not been determined yet. Our current hypothesis
      // is that windows does not handle the IE processes independently.
      // If we have more than one browser and kill a browser we are seeing
      // issues with starting up a new browser just after killing the hanging
      // browser.
      maxBrowserProcesses = 1;
    } else if (configuration.runtime.isSafari) {
      // Safari does not allow us to run from a fresh profile, so we can only
      // use one browser. Additionally, you can not start two simulators
      // for mobile safari simultainiously.
      maxBrowserProcesses = 1;
    } else if (configuration.runtime == Runtime.chrome &&
        Platform.operatingSystem == 'macos') {
      // Chrome on mac results in random timeouts.
      // Issue: https://github.com/dart-lang/sdk/issues/23891
      // This change does not fix the problem.
      maxBrowserProcesses = math.max(1, maxBrowserProcesses ~/ 2);
    } else if (configuration.runtime != Runtime.drt) {
      // Even on machines with more than 16 processors, don't open more
      // than 15 browser instances, to avoid overloading the machine.
      // This is especially important when running locally on powerful
      // desktops.
      maxBrowserProcesses = math.min(maxBrowserProcesses, 15);
    }

    // If we specifically pass in a suite only run that.
    if (configuration.suiteDirectory != null) {
      var suitePath = new Path(configuration.suiteDirectory);
      testSuites.add(new PKGTestSuite(configuration, suitePath));
    } else {
      for (var testSuiteDir in TEST_SUITE_DIRECTORIES) {
        var name = testSuiteDir.filename;
        if (configuration.selectors.containsKey(name)) {
          testSuites.add(
              new StandardTestSuite.forDirectory(configuration, testSuiteDir));
        }
      }

      for (var key in configuration.selectors.keys) {
        if (key == 'co19') {
          testSuites.add(new Co19TestSuite(configuration));
        } else if ((configuration.compiler == Compiler.none ||
                configuration.compiler == Compiler.dartk) &&
            configuration.runtime == Runtime.vm &&
            key == 'vm') {
          // vm tests contain both cc tests (added here) and dart tests (added
          // in [TEST_SUITE_DIRECTORIES]).
          testSuites.add(new VMTestSuite(configuration));
        } else if (configuration.compiler == Compiler.dart2analyzer) {
          if (key == 'analyze_library') {
            testSuites.add(new AnalyzeLibraryTestSuite(configuration));
          }
        }
      }
    }
  }

  void allTestsFinished() {
    for (var configuration in configurations) {
      configuration.stopServers();
    }

    DebugLogger.close();
    TestUtils.deleteTempSnapshotDirectory(configurations[0]);
  }

  var eventListener = <EventListener>[];

  // We don't print progress if we list tests.
  if (progressIndicator != Progress.silent && !listTests) {
    var printFailures = true;
    var formatter = Formatter.normal;
    if (progressIndicator == Progress.color) {
      progressIndicator = Progress.compact;
      formatter = Formatter.color;
    }
    if (progressIndicator == Progress.diff) {
      progressIndicator = Progress.compact;
      formatter = Formatter.color;
      printFailures = false;
      eventListener.add(new StatusFileUpdatePrinter());
    }
    eventListener.add(new SummaryPrinter());
    eventListener.add(new FlakyLogWriter());
    if (printFailures) {
      // The buildbot has it's own failure summary since it needs to wrap it
      // into '@@@'-annotated sections.
      var printFailureSummary = progressIndicator != Progress.buildbot;
      eventListener.add(new TestFailurePrinter(printFailureSummary, formatter));
    }
    eventListener.add(ProgressIndicator.fromProgress(
        progressIndicator, startTime, formatter));
    if (printTiming) {
      eventListener.add(new TimingPrinter(startTime));
    }
    eventListener.add(new SkippedCompilationsPrinter());
  }

  if (firstConf.writeTestOutcomeLog) {
    eventListener.add(new TestOutcomeLogWriter());
  }

  if (firstConf.writeResultLog) {
    eventListener.add(new ResultLogWriter());
  }

  if (firstConf.copyCoreDumps) {
    eventListener.add(new UnexpectedCrashLogger());
  }

  // The only progress indicator when listing tests should be the
  // the summary printer.
  if (listTests) {
    eventListener.add(new SummaryPrinter(jsonOnly: reportInJson));
  } else {
    eventListener.add(new ExitCodeSetter());
    eventListener.add(new IgnoredTestMonitor());
  }

  // If any of the configurations need to access android devices we'll first
  // make a pool of all available adb devices.
  AdbDevicePool adbDevicePool;
  var needsAdbDevicePool = configurations.any((conf) {
    return conf.runtime == Runtime.dartPrecompiled &&
        conf.system == System.android;
  });
  if (needsAdbDevicePool) {
    adbDevicePool = await AdbDevicePool.create();
  }

  // Start all the HTTP servers required before starting the process queue.
  if (!serverFutures.isEmpty) {
    await Future.wait(serverFutures);
  }

  // [firstConf] is needed here, since the ProcessQueue needs to know the
  // settings of 'noBatch' and 'local_ip'
  new ProcessQueue(firstConf, maxProcesses, maxBrowserProcesses, startTime,
      testSuites, eventListener, allTestsFinished, verbose, adbDevicePool);
}
