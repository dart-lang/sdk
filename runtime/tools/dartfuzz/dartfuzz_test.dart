// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'dartfuzz.dart';

const debug = false;
const sigkill = 9;
const timeout = 30; // in seconds

// Exit code of running a test.
enum ResultCode { success, timeout, error }

/// Result of running a test.
class TestResult {
  TestResult(this.code, this.output);
  ResultCode code;
  String output;
}

/// Command runner.
TestResult runCommand(List<String> cmd, Map<String, String> env) {
  // TODO: use Dart API for some of the modes?
  ProcessResult res = Process.runSync(
      'timeout', ['-s', '$sigkill', '$timeout'] + cmd,
      environment: env);
  if (debug) {
    print('\nrunning $cmd yields:\n'
        '${res.exitCode}\n${res.stdout}\n${res.stderr}\n');
  }
  if (res.exitCode == -sigkill) {
    return new TestResult(ResultCode.timeout, res.stdout);
  } else if (res.exitCode != 0) {
    return new TestResult(ResultCode.error, res.stdout);
  }
  return new TestResult(ResultCode.success, res.stdout);
}

/// Abstraction for running one test in a particular mode.
abstract class TestRunner {
  String description();
  TestResult run(String fileName);

  // Factory.
  static TestRunner getTestRunner(
      Map<String, String> env, String top, String mode) {
    if (mode.startsWith('jit')) return new TestRunnerJIT(env, top, mode);
    if (mode.startsWith('aot')) return new TestRunnerAOT(env, top, mode);
    if (mode.startsWith('js')) return new TestRunnerJS(env, top, mode);
    throw ('unknown mode: $mode');
  }

  // Convert mode to tag.
  static String getTag(String mode) {
    if (mode.endsWith('debug-ia32')) return 'DebugIA32';
    if (mode.endsWith('debug-x64')) return 'DebugX64';
    if (mode.endsWith('debug-arm32')) return 'DebugSIMARM';
    if (mode.endsWith('debug-arm64')) return 'DebugSIMARM64';
    if (mode.endsWith('ia32')) return 'ReleaseIA32';
    if (mode.endsWith('x64')) return 'ReleaseX64';
    if (mode.endsWith('arm32')) return 'ReleaseSIMARM';
    if (mode.endsWith('arm64')) return 'ReleaseSIMARM64';
    throw ('unknown tag in mode: $mode');
  }
}

/// Concrete test runner of Dart JIT.
class TestRunnerJIT implements TestRunner {
  TestRunnerJIT(Map<String, String> e, String top, String mode) {
    tag = TestRunner.getTag(mode);
    env = Map<String, String>.from(e);
    env['PATH'] = "$top/out/$tag:${env['PATH']}";
  }
  String description() {
    return "JIT-${tag}";
  }

  TestResult run(String fileName) {
    return runCommand(['dart', fileName], env);
  }

  String tag;
  Map<String, String> env;
}

/// Concrete test runner of Dart AOT.
class TestRunnerAOT implements TestRunner {
  TestRunnerAOT(Map<String, String> e, String top, String mode) {
    tag = TestRunner.getTag(mode);
    env = Map<String, String>.from(e);
    env['PATH'] = "$top/pkg/vm/tool:${env['PATH']}";
    env['DART_CONFIGURATION'] = tag;
  }
  String description() {
    return "AOT-${tag}";
  }

  TestResult run(String fileName) {
    TestResult result = runCommand(['precompiler2', fileName, 'snapshot'], env);
    if (result.code != ResultCode.success) {
      return result;
    }
    return runCommand(['dart_precompiled_runtime2', 'snapshot'], env);
  }

  String tag;
  Map<String, String> env;
}

/// Concrete test runner of Dart2JS.
class TestRunnerJS implements TestRunner {
  TestRunnerJS(Map<String, String> e, String top, String mode) {
    env = Map<String, String>.from(e);
    env['PATH'] = "$top/out/ReleaseX64/dart-sdk/bin:${env['PATH']}";
  }
  String description() {
    return "Dart2JS";
  }

  TestResult run(String fileName) {
    TestResult result = runCommand(['dart2js', fileName], env);
    if (result.code != ResultCode.success) {
      return result;
    }
    return runCommand(['nodejs', 'out.js'], env);
  }

  Map<String, String> env;
}

/// Class to run a fuzz testing session.
class DartFuzzTest {
  DartFuzzTest(this.env, this.repeat, this.trueDivergence, this.showStats,
      this.top, this.mode1, this.mode2);

  bool runSession() {
    setupSession();

    print('\n**\n**** Dart Fuzz Testing\n**\n');
    print('Fuzz Version : ${version}');
    print('#Tests       : ${repeat}');
    print('Exec-Mode 1  : ${runner1.description()}');
    print('Exec-Mode 2  : ${runner2.description()}');
    print('Dart Dev     : ${top}');
    print('Orig Dir     : ${orgDir.path}');
    print('Temp Dir     : ${tmpDir.path}\n');

    showStatistics();
    for (int i = 0; i < repeat; i++) {
      numTests++;
      seed = rand.nextInt(1 << 32);
      generateTest();
      runTest();
      showStatistics();
    }

    cleanupSession();
    if (numDivergences != 0) {
      print('\n\nfailure\n');
      return false;
    }
    print('\n\nsuccess\n');
    return true;
  }

  void setupSession() {
    rand = new Random();
    orgDir = Directory.current;
    tmpDir = Directory.systemTemp.createTempSync('dart_fuzz');
    Directory.current = tmpDir;
    fileName = 'fuzz.dart';
    runner1 = TestRunner.getTestRunner(env, top, mode1);
    runner2 = TestRunner.getTestRunner(env, top, mode2);
    numTests = 0;
    numSuccess = 0;
    numNotRun = 0;
    numTimeOut = 0;
    numDivergences = 0;
  }

  void cleanupSession() {
    Directory.current = orgDir;
    tmpDir.delete(recursive: true);
  }

  void showStatistics() {
    if (showStats) {
      stdout.write('\rTests: $numTests Success: $numSuccess Not-Run: '
          '$numNotRun: Time-Out: $numTimeOut Divergences: $numDivergences');
    }
  }

  void generateTest() {
    final file = new File(fileName).openSync(mode: FileMode.write);
    new DartFuzz(seed, file).run();
    file.closeSync();
  }

  void runTest() {
    TestResult result1 = runner1.run(fileName);
    TestResult result2 = runner2.run(fileName);
    checkDivergence(result1, result2);
  }

  void checkDivergence(TestResult result1, TestResult result2) {
    if (result1.code == result2.code) {
      // No divergence in result code.
      switch (result1.code) {
        case ResultCode.success:
          // Both were successful, inspect output.
          if (result1.output == result2.output) {
            numSuccess++;
          } else {
            reportDivergence(result1, result2, true);
          }
          break;
        case ResultCode.timeout:
          // Both had a time out.
          numTimeOut++;
          break;
        case ResultCode.error:
          // Both had an error.
          numNotRun++;
          break;
      }
    } else {
      // Divergence in result code.
      if (trueDivergence) {
        // When only true divergences are requested, any divergence
        // with at least one time out is treated as a regular time out.
        if (result1.code == ResultCode.timeout ||
            result2.code == ResultCode.timeout) {
          numTimeOut++;
          return;
        }
      }
      reportDivergence(result1, result2, false);
    }
  }

  void reportDivergence(
      TestResult result1, TestResult result2, bool outputDivergence) {
    numDivergences++;
    print('\n\nDIVERGENCE on generated program $version:$seed\n');
    if (outputDivergence) {
      print('out1:\n${result1.output}\n\nout2:\n${result2.output}\n');
    }
  }

  // Context.
  final Map<String, String> env;
  final int repeat;
  final bool trueDivergence;
  final bool showStats;
  final String top;
  final String mode1;
  final String mode2;

  // Session.
  Random rand;
  Directory orgDir;
  Directory tmpDir;
  String fileName;
  TestRunner runner1;
  TestRunner runner2;
  int seed;

  // Stats.
  int numTests;
  int numSuccess;
  int numNotRun;
  int numTimeOut;
  int numDivergences;
}

/// Main driver for a fuzz testing session.
main(List<String> arguments) {
  // Set up argument parser.
  final parser = new ArgParser()
    ..addOption('repeat', help: 'number of tests to run', defaultsTo: '1000')
    ..addFlag('true-divergence',
        negatable: true, help: 'only report true divergences', defaultsTo: true)
    ..addFlag('show-stats',
        negatable: true, help: 'show session statistics', defaultsTo: true)
    ..addOption('dart-top',
        help: 'explicit value for \$DART_TOP', defaultsTo: '')
    ..addOption('mode1', help: 'execution mode 1', defaultsTo: 'jit-x64')
    ..addOption('mode2', help: 'execution mode 2', defaultsTo: 'aot-x64');

  // Start fuzz testing session.
  try {
    final env = Platform.environment;
    final results = parser.parse(arguments);
    final repeat = int.parse(results['repeat']);
    final trueDivergence = results['true-divergence'];
    final showStats = results['show-stats'];
    final mode1 = results['mode1'];
    final mode2 = results['mode2'];
    var top = results['dart-top'];
    if (top == '') {
      top = env['DART_TOP'];
    }
    final session = new DartFuzzTest(
        env, repeat, trueDivergence, showStats, top, mode1, mode2);
    if (!session.runSession()) {
      exitCode = 1;
    }
  } catch (e) {
    print('Usage: dart dartfuzz_test.dart [OPTIONS]\n${parser.usage}\n$e');
    exitCode = 255;
  }
}
