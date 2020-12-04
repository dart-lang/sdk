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
import 'fuchsia.dart';
import 'path.dart';
import 'process_queue.dart';
import 'terminal.dart';
import 'test_progress.dart';
import 'test_suite.dart';
import 'utils.dart';

export 'configuration.dart' show TestConfiguration;

/// The directories that contain test suites which follow the conventions
/// required by [StandardTestSuite]'s forDirectory constructor.
///
/// New test suites should follow this convention because it makes it much
/// simpler to add them to test.dart. Existing test suites should be moved to
/// here, if possible.
final testSuiteDirectories = [
  Path('third_party/pkg/dartdoc'),
  Path('pkg'),
  Path('third_party/pkg_tested'),
  Path('runtime/tests/vm'),
  Path('runtime/observatory/tests/service'),
  Path('runtime/observatory/tests/observatory_ui'),
  Path('runtime/observatory_2/tests/service_2'),
  Path('runtime/observatory_2/tests/observatory_ui_2'),
  Path('samples'),
  Path('samples_2'),
  Path('samples-dev'),
  Path('tests/corelib'),
  Path('tests/corelib_2'),
  Path('tests/dart2js'),
  Path('tests/dart2js_2'),
  Path('tests/dartdevc'),
  Path('tests/dartdevc_2'),
  Path('tests/language'),
  Path('tests/language_2'),
  Path('tests/lib'),
  Path('tests/lib_2'),
  Path('tests/standalone'),
  Path('tests/standalone_2'),
  Path('tests/ffi'),
  Path('tests/ffi_2'),
  Path('utils/tests/peg'),
];

// TODO(26372): Ensure that the returned future awaits on all started tasks.
Future testConfigurations(List<TestConfiguration> configurations) async {
  var startTime = DateTime.now();

  // Extract global options from first configuration.
  var firstConf = configurations[0];
  var maxProcesses = firstConf.taskCount;
  var progress = firstConf.progress;
  BuildbotProgressIndicator.stepName = firstConf.stepName;
  var verbose = firstConf.isVerbose;
  var printTiming = firstConf.printTiming;
  var listTests = firstConf.listTests;
  var listStatusFiles = firstConf.listStatusFiles;
  var reportInJson = firstConf.reportInJson;

  Browser.resetBrowserConfiguration = firstConf.resetBrowser;
  DebugLogger.init(firstConf.writeDebugLog ? TestUtils.debugLogFilePath : null);

  // Print the configurations being run by this execution of
  // test.dart. However, don't do it if the silent progress indicator
  // is used.
  if (progress != Progress.silent) {
    Terminal.print(
        'Test configuration${configurations.length > 1 ? 's' : ''}:');
    for (var configuration in configurations) {
      Terminal.print("    ${configuration.configuration}");
      Terminal.print(
          "Suites tested: ${configuration.selectors.keys.join(", ")}");
    }
  }

  var runningBrowserTests =
      configurations.any((config) => config.runtime.isBrowser);

  var serverFutures = <Future>[];
  var testSuites = <TestSuite>[];
  var maxBrowserProcesses = maxProcesses;
  if (configurations.length > 1 &&
      (configurations[0].testServerPort != 0 ||
          configurations[0].testServerCrossOriginPort != 0)) {
    Terminal.print(
        "If the http server ports are specified, only one configuration"
        " may be run at a time");
    exit(1);
  }

  for (var configuration in configurations) {
    if (!listTests && !listStatusFiles && runningBrowserTests) {
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
      // for mobile safari simultaneously.
      maxBrowserProcesses = 1;
    } else if (configuration.runtime == Runtime.chrome &&
        Platform.operatingSystem == 'macos') {
      // Chrome on mac results in random timeouts.
      // Issue: https://github.com/dart-lang/sdk/issues/23891
      // This change does not fix the problem.
      maxBrowserProcesses = math.max(1, maxBrowserProcesses ~/ 2);
    }

    // If we specifically pass in a suite only run that.
    if (configuration.suiteDirectory != null) {
      var suitePath = Path(configuration.suiteDirectory);
      testSuites.add(PackageTestSuite(configuration, suitePath));
    } else {
      for (var testSuiteDir in testSuiteDirectories) {
        var name = testSuiteDir.filename;
        if (configuration.selectors.containsKey(name)) {
          testSuites
              .add(StandardTestSuite.forDirectory(configuration, testSuiteDir));
        }
      }

      for (var key in configuration.selectors.keys) {
        if (key == 'co19_2' || key == 'co19') {
          testSuites.add(Co19TestSuite(configuration, key));
        } else if ((configuration.compiler == Compiler.none ||
                configuration.compiler == Compiler.dartk) &&
            configuration.runtime == Runtime.vm &&
            key == 'vm') {
          // vm tests contain both cc tests (added here) and dart tests (added
          // in [TEST_SUITE_DIRECTORIES]).
          testSuites.add(VMTestSuite(configuration));
        } else if (key == 'ffi_unit') {
          // 'ffi_unit' contains cc non-DartVM unit tests.
          //
          // This is a separate suite from 'ffi', because we want to run the
          // 'ffi' suite on many architectures, but 'ffi_unit' only on one.
          testSuites.add(FfiTestSuite(configuration));
        } else if (configuration.compiler == Compiler.dart2analyzer) {
          if (key == 'analyze_library') {
            testSuites.add(AnalyzeLibraryTestSuite(configuration));
          }
        }
      }
    }

    if (configuration.system == System.fuchsia) {
      await FuchsiaEmulator.publishPackage(
          configuration.buildDirectory, configuration.mode.name);
    }
  }

  // If we only need to print out status files for test suites
  // we return from running here and just print.
  if (firstConf.listStatusFiles) {
    for (var suite in testSuites) {
      Terminal.print(suite.suiteName);
      for (var statusFile in suite.statusFilePaths.toSet()) {
        Terminal.print("\t$statusFile");
      }
    }
    return;
  }

  void allTestsFinished() {
    for (var configuration in configurations) {
      configuration.stopServers();
    }
    FuchsiaEmulator.stop();

    DebugLogger.close();
    if (!firstConf.keepGeneratedFiles) {
      TestUtils.deleteTempSnapshotDirectory(configurations[0]);
    }
  }

  var eventListener = <EventListener>[];

  // We don't print progress if we list tests.
  if (progress != Progress.silent && !listTests) {
    var formatter = Formatter.normal;
    if (progress == Progress.color) {
      progress = Progress.compact;
      formatter = Formatter.color;
    }

    eventListener.add(SummaryPrinter());
    if (!firstConf.silentFailures) {
      eventListener.add(TestFailurePrinter(formatter));
    }

    if (firstConf.printPassingStdout) {
      eventListener.add(PassingStdoutPrinter(formatter));
    }

    var indicator =
        ProgressIndicator.fromProgress(progress, startTime, formatter);
    if (indicator != null) eventListener.add(indicator);

    if (printTiming) {
      eventListener.add(TimingPrinter(startTime));
    }

    eventListener.add(SkippedCompilationsPrinter());

    if (progress == Progress.status) {
      eventListener.add(TimedProgressPrinter());
    }

    if (firstConf.reportFailures) {
      eventListener.add(FailedTestsPrinter());
    }

    eventListener.add(ResultCountPrinter(formatter));
  }

  if (firstConf.writeResults) {
    eventListener.add(ResultWriter(firstConf.outputDirectory));
  }

  if (firstConf.copyCoreDumps) {
    eventListener.add(UnexpectedCrashLogger());
  }

  // The only progress indicator when listing tests should be the
  // the summary printer.
  if (listTests) {
    eventListener.add(SummaryPrinter(jsonOnly: reportInJson));
  } else {
    if (!firstConf.cleanExit) {
      eventListener.add(ExitCodeSetter());
    }
    eventListener.add(IgnoredTestMonitor());
  }

  // If any of the configurations need to access android devices we'll first
  // make a pool of all available adb devices.
  AdbDevicePool adbDevicePool;
  var needsAdbDevicePool = configurations.any((conf) {
    return conf.system == System.android;
  });
  if (needsAdbDevicePool) {
    adbDevicePool = await AdbDevicePool.create();
  }

  // Start all the HTTP servers required before starting the process queue.
  if (serverFutures.isNotEmpty) {
    await Future.wait(serverFutures);
  }

  // [firstConf] is needed here, since the ProcessQueue needs to know the
  // settings of 'noBatch' and 'local_ip'
  ProcessQueue(firstConf, maxProcesses, maxBrowserProcesses, testSuites,
      eventListener, allTestsFinished, verbose, adbDevicePool);
}
