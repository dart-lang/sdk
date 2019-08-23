// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';

import 'dartfuzz.dart';

const debug = false;
const sigkill = 9;
const timeout = 60; // in seconds

// Status of divergence report.
enum ReportStatus { reported, ignored, rerun, no_divergence }

/// Result of running a test.
class TestResult {
  const TestResult(this.output, this.stderr, this.exitCode);
  final String output;
  final String stderr;
  final int exitCode;
}

/// Command runner.
TestResult runCommand(List<String> cmd, Map<String, String> env) {
  ProcessResult res = Process.runSync(
      'timeout', ['-s', '$sigkill', '$timeout', ...cmd],
      environment: env);
  if (debug) {
    print('\nrunning $cmd yields:\n'
        '${res.exitCode}\n${res.stdout}\n${res.stderr}\n');
  }
  return TestResult(res.stdout, res.stderr, res.exitCode);
}

/// Abstraction for running one test in a particular mode.
abstract class TestRunner {
  TestResult run();
  String description;

  // Factory.
  static TestRunner getTestRunner(String mode, bool ffi, String top, String tmp,
      Map<String, String> env, String fileName, Random rand) {
    String prefix = mode.substring(0, 3).toUpperCase();
    String tag = getTag(mode);
    List<String> extraFlags = [];
    // Required extra flags for kbc.
    if (mode.startsWith('kbc-int')) {
      prefix += '-INT';
      extraFlags += [
        '--enable-interpreter',
        '--compilation-counter-threshold=-1'
      ];
    } else if (mode.startsWith('kbc-mix')) {
      prefix += '-MIX';
      extraFlags += ['--enable-interpreter'];
    } else if (mode.startsWith('kbc-cmp')) {
      prefix += '-CMP';
      extraFlags += ['--use-bytecode-compiler'];
    }
    // Every once in a while, go directly from source for kbc.
    bool kbcSrc = false;
    if (mode.startsWith('kbc') && rand.nextInt(4) == 0) {
      prefix += '-SRC';
      kbcSrc = true;
    }
    // Every once in a while, stress test JIT.
    if (mode.startsWith('jit') && rand.nextInt(4) == 0) {
      final r = rand.nextInt(7);
      if (r == 0) {
        prefix += '-NOFIELDGUARDS';
        extraFlags += ['--use_field_guards=false'];
      } else if (r == 1) {
        prefix += '-NOINTRINSIFY';
        extraFlags += ['--intrinsify=false'];
      } else if (r == 2) {
        prefix += '-COMPACTEVERY';
        extraFlags += ['--gc_every=1000', '--use_compactor=true'];
      } else if (r == 3) {
        prefix += '-MARKSWEEPEVERY';
        extraFlags += ['--gc_every=1000', '--use_compactor=false'];
      } else if (r == 4) {
        prefix += '-DEPOPTEVERY';
        extraFlags += ['--deoptimize_every=100'];
      } else if (r == 5 && !ffi) {
        // TODO: https://github.com/dart-lang/sdk/issues/37606
        prefix += '-STACKTRACEEVERY';
        extraFlags += ['--stacktrace_every=100'];
      } else if (r == 6) {
        prefix += '-OPTCOUNTER';
        extraFlags += ['--optimization_counter_threshold=1'];
      }
    }
    // Every once in a while, disable VFP on arm32.
    if (mode.contains('arm32') && rand.nextInt(4) == 0) {
      prefix += '-noVFP';
      extraFlags += ['--no-use-vfp'];
    }
    // Every once in a while, use -O3 compiler.
    if (!mode.startsWith('djs') && rand.nextInt(4) == 0) {
      prefix += '-O3';
      extraFlags += ['--optimization_level=3'];
    }
    // Construct runner.
    if (mode.startsWith('jit')) {
      return new TestRunnerJIT(
          prefix, tag, top, tmp, env, fileName, extraFlags);
    } else if (mode.startsWith('aot')) {
      return new TestRunnerAOT(
          prefix, tag, top, tmp, env, fileName, extraFlags);
    } else if (mode.startsWith('kbc')) {
      return new TestRunnerKBC(
          prefix, tag, top, tmp, env, fileName, extraFlags, kbcSrc);
    } else if (mode.startsWith('djs')) {
      return new TestRunnerDJS(prefix, tag, top, tmp, env, fileName);
    }
    throw ('unknown runner in mode: $mode');
  }

  // Convert mode to tag.
  static String getTag(String mode) {
    if (mode.endsWith('debug-ia32')) return 'DebugIA32';
    if (mode.endsWith('debug-x64')) return 'DebugX64';
    if (mode.endsWith('debug-arm32')) return 'DebugSIMARM';
    if (mode.endsWith('debug-arm64')) return 'DebugSIMARM64';
    if (mode.endsWith('debug-dbc32')) return 'DebugSIMDBC';
    if (mode.endsWith('debug-dbc64')) return 'DebugSIMDBC64';
    if (mode.endsWith('ia32')) return 'ReleaseIA32';
    if (mode.endsWith('x64')) return 'ReleaseX64';
    if (mode.endsWith('arm32')) return 'ReleaseSIMARM';
    if (mode.endsWith('arm64')) return 'ReleaseSIMARM64';
    if (mode.endsWith('dbc32')) return 'ReleaseSIMDBC';
    if (mode.endsWith('dbc64')) return 'ReleaseSIMDBC64';
    throw ('unknown tag in mode: $mode');
  }
}

/// Concrete test runner of Dart JIT.
class TestRunnerJIT implements TestRunner {
  TestRunnerJIT(String prefix, String tag, String top, String tmp, this.env,
      this.fileName, List<String> extraFlags) {
    description = '$prefix-$tag';
    dart = '$top/out/$tag/dart';
    cmd = [dart, ...extraFlags, fileName];
  }

  TestResult run() {
    return runCommand(cmd, env);
  }

  String description;
  String dart;
  String fileName;
  Map<String, String> env;
  List<String> cmd;
}

/// Concrete test runner of Dart AOT.
class TestRunnerAOT implements TestRunner {
  TestRunnerAOT(String prefix, String tag, String top, String tmp,
      Map<String, String> e, this.fileName, List<String> extraFlags) {
    description = '$prefix-$tag';
    precompiler = '$top/pkg/vm/tool/precompiler2';
    dart = '$top/pkg/vm/tool/dart_precompiled_runtime2';
    snapshot = '$tmp/snapshot';
    env = Map<String, String>.from(e);
    env['DART_CONFIGURATION'] = tag;
    cmd = [precompiler, ...extraFlags, fileName, snapshot];
  }

  TestResult run() {
    TestResult result = runCommand(cmd, env);
    if (result.exitCode != 0) {
      return result;
    }
    return runCommand([dart, snapshot], env);
  }

  String description;
  String precompiler;
  String dart;
  String fileName;
  String snapshot;
  Map<String, String> env;
  List<String> cmd;
}

/// Concrete test runner of bytecode.
class TestRunnerKBC implements TestRunner {
  TestRunnerKBC(String prefix, String tag, String top, String tmp, this.env,
      this.fileName, List<String> extraFlags, bool kbcSrc) {
    description = '$prefix-$tag';
    dart = '$top/out/$tag/dart';
    if (kbcSrc) {
      cmd = [dart, ...extraFlags, fileName];
    } else {
      generate = '$top/pkg/vm/tool/gen_kernel';
      platform = '--platform=$top/out/$tag/vm_platform_strong.dill';
      dill = '$tmp/out.dill';
      cmd = [dart, ...extraFlags, dill];
    }
  }

  TestResult run() {
    if (generate != null) {
      TestResult result = runCommand(
          [generate, '--gen-bytecode', platform, '-o', dill, fileName], env);
      if (result.exitCode != 0) {
        return result;
      }
    }
    return runCommand(cmd, env);
  }

  String description;
  String generate;
  String platform;
  String dill;
  String dart;
  String fileName;
  Map<String, String> env;
  List<String> cmd;
}

/// Concrete test runner of Dart2JS.
class TestRunnerDJS implements TestRunner {
  TestRunnerDJS(String prefix, String tag, String top, String tmp, this.env,
      this.fileName) {
    description = '$prefix-$tag';
    dart2js = '$top/sdk/bin/dart2js';
    js = '$tmp/out.js';
  }

  TestResult run() {
    TestResult result = runCommand([dart2js, fileName, '-o', js], env);
    if (result.exitCode != 0) {
      return result;
    }
    return runCommand(['nodejs', js], env);
  }

  String description;
  String dart2js;
  String fileName;
  String js;
  Map<String, String> env;
}

/// Class to run fuzz testing.
class DartFuzzTest {
  DartFuzzTest(this.env, this.repeat, this.time, this.trueDivergence,
      this.showStats, this.top, this.mode1, this.mode2, this.rerun);

  int run() {
    setup();

    print('\n${isolate}: start');
    if (showStats) {
      showStatistics();
    }

    for (int i = 0; i < repeat; i++) {
      numTests++;
      seed = rand.nextInt(1 << 32);
      generateTest();
      runTest();
      if (showStats) {
        showStatistics();
      }
      // Timeout?
      if (timeIsUp()) {
        break;
      }
    }

    print('\n${isolate}: done');
    showStatistics();
    print('');

    cleanup();
    return numDivergences;
  }

  void setup() {
    rand = new Random();
    tmpDir = Directory.systemTemp.createTempSync('dart_fuzz');
    fileName = '${tmpDir.path}/fuzz.dart';
    fp = samePrecision(mode1, mode2);
    ffi = ffiCapable(mode1, mode2);
    runner1 = TestRunner.getTestRunner(
        mode1, ffi, top, tmpDir.path, env, fileName, rand);
    runner2 = TestRunner.getTestRunner(
        mode2, ffi, top, tmpDir.path, env, fileName, rand);
    isolate =
        'Isolate (${tmpDir.path}) ${ffi ? "" : "NO-"}FFI ${fp ? "" : "NO-"}FP : '
        '${runner1.description} - ${runner2.description}';

    start_time = new DateTime.now().millisecondsSinceEpoch;
    current_time = start_time;
    report_time = start_time;
    end_time = start_time + max(0, time - timeout) * 1000;

    numTests = 0;
    numSuccess = 0;
    numNotRun = 0;
    numTimeOut = 0;
    numDivergences = 0;
  }

  bool samePrecision(String mode1, String mode2) =>
      mode1.contains('64') == mode2.contains('64');

  bool ffiCapable(String mode1, String mode2) =>
      (mode1.startsWith('jit') || mode1.startsWith('kbc')) &&
      (mode2.startsWith('jit') || mode2.startsWith('kbc')) &&
      (!mode1.contains('arm') && !mode2.contains('arm'));

  bool timeIsUp() {
    if (time > 0) {
      current_time = new DateTime.now().millisecondsSinceEpoch;
      if (current_time > end_time) {
        return true;
      }
      // Report every 10 minutes.
      if ((current_time - report_time) > (10 * 60 * 1000)) {
        print(
            '\n${isolate}: busy @${numTests} ${current_time - start_time} seconds....');
        report_time = current_time;
      }
    }
    return false;
  }

  void cleanup() {
    tmpDir.delete(recursive: true);
  }

  void showStatistics() {
    stdout.write('\rTests: $numTests Success: $numSuccess Not-Run: '
        '$numNotRun: Time-Out: $numTimeOut Divergences: $numDivergences');
  }

  void generateTest() {
    final file = new File(fileName).openSync(mode: FileMode.write);
    new DartFuzz(seed, fp, ffi, file).run();
    file.closeSync();
  }

  void runTest() {
    TestResult result1 = runner1.run();
    TestResult result2 = runner2.run();
    if (checkDivergence(result1, result2) == ReportStatus.rerun && rerun) {
      print("\nCommencing re-run .... \n");
      numDivergences--;
      result1 = runner1.run();
      result2 = runner2.run();
      if (checkDivergence(result1, result2) == ReportStatus.no_divergence) {
        print("\nNo error on re-run\n");
      }
    }
  }

  ReportStatus checkDivergence(TestResult result1, TestResult result2) {
    if (result1.exitCode == result2.exitCode) {
      // No divergence in result code.
      switch (result1.exitCode) {
        case 0:
          // Both were successful, inspect output.
          if (result1.output == result2.output) {
            numSuccess++;
          } else {
            reportDivergence(result1, result2);
            return ReportStatus.reported;
          }
          break;
        case -sigkill:
          // Both had a time out.
          numTimeOut++;
          break;
        default:
          // Both had an error.
          numNotRun++;
          break;
      }
    } else {
      // Divergence in result code.
      if (trueDivergence) {
        // When only true divergences are requested, any divergence
        // with at least one time out is treated as a regular time out.
        if (result1.exitCode == -sigkill || result2.exitCode == -sigkill) {
          numTimeOut++;
          return ReportStatus.ignored;
        }
      }
      reportDivergence(result1, result2);
      // Exit codes outside [-255,255] are not due to Dart VM exits.
      if (result1.exitCode.abs() > 255 || result2.exitCode.abs() > 255) {
        return ReportStatus.rerun;
      } else {
        return ReportStatus.reported;
      }
    }
    return ReportStatus.no_divergence;
  }

  String generateReport(TestResult result1, TestResult result2) {
    if (result1.exitCode == result2.exitCode) {
      return "output";
    } else {
      return "${result1.exitCode} vs ${result2.exitCode}";
    }
  }

  void reportDivergence(TestResult result1, TestResult result2) {
    numDivergences++;
    String report = generateReport(result1, result2);
    print('\n${isolate}: !DIVERGENCE! $version:$seed (${report})');
    if (result1.exitCode == result2.exitCode) {
      // Only report the actual output divergence details when requested,
      // since this output may be lengthy and should be reproducable anyway.
      if (showStats) {
        print('\nout1:\n${result1.output}\nout2:\n${result2.output}\n');
      }
    } else {
      // For any other divergence, always report what went wrong.
      if (result1.exitCode != 0) {
        print(
            '\nfail1:\n${result1.exitCode}\n${result1.output}\n${result1.stderr}\n');
      }
      if (result2.exitCode != 0) {
        print(
            '\nfail2:\n${result2.exitCode}\n${result2.output}\n${result2.stderr}\n');
      }
    }
  }

  // Context.
  final Map<String, String> env;
  final int repeat;
  final int time;
  final bool trueDivergence;
  final bool showStats;
  final String top;
  final String mode1;
  final String mode2;
  final bool rerun;

  // Test.
  Random rand;
  Directory tmpDir;
  String fileName;
  TestRunner runner1;
  TestRunner runner2;
  bool fp;
  bool ffi;
  String isolate;
  int seed;

  // Timing
  int start_time;
  int current_time;
  int report_time;
  int end_time;

  // Stats.
  int numTests;
  int numSuccess;
  int numNotRun;
  int numTimeOut;
  int numDivergences;
}

/// Class to start fuzz testing session.
class DartFuzzTestSession {
  DartFuzzTestSession(
      this.isolates,
      this.repeat,
      this.time,
      this.trueDivergence,
      this.showStats,
      String tp,
      this.mode1,
      this.mode2,
      this.rerun)
      : top = getTop(tp) {}

  start() async {
    print('\n**\n**** Dart Fuzz Testing Session\n**\n');
    print('Fuzz Version    : ${version}');
    print('Isolates        : ${isolates}');
    print('Tests           : ${repeat}');
    if (time > 0) {
      print('Time            : ${time} seconds');
    } else {
      print('Time            : unlimited');
    }
    print('True Divergence : ${trueDivergence}');
    print('Show Stats      : ${showStats}');
    print('Dart Dev        : ${top}');
    // Fork.
    List<ReceivePort> ports = new List();
    for (int i = 0; i < isolates; i++) {
      ReceivePort r = new ReceivePort();
      ports.add(r);
      port = r.sendPort;
      await Isolate.spawn(run, this);
    }
    // Join.
    int divergences = 0;
    for (int i = 0; i < isolates; i++) {
      var d = await ports[i].first;
      divergences += d;
    }
    if (divergences == 0) {
      print('\nsuccess\n');
    } else {
      print('\nfailure ($divergences divergences)\n');
      exitCode = 1;
    }
  }

  static run(DartFuzzTestSession session) {
    int divergences = 0;
    try {
      final m1 = getMode(session.mode1, null);
      final m2 = getMode(session.mode2, m1);
      final fuzz = new DartFuzzTest(
          Platform.environment,
          session.repeat,
          session.time,
          session.trueDivergence,
          session.showStats,
          session.top,
          m1,
          m2,
          session.rerun);
      divergences = fuzz.run();
    } catch (e) {
      print('Isolate: $e');
    }
    session.port.send(divergences);
  }

  // Picks a top directory (command line, environment, or current).
  static String getTop(String top) {
    if (top == null || top == '') {
      top = Platform.environment['DART_TOP'];
    }
    if (top == null || top == '') {
      top = Directory.current.path;
    }
    return top;
  }

  // Picks a mode (command line or random).
  static String getMode(String mode, String other) {
    // Random when not set.
    if (mode == null || mode == '') {
      // Pick a mode at random (cluster), different from other.
      Random rand = new Random();
      do {
        mode = clusterModes[rand.nextInt(clusterModes.length)];
      } while (mode == other);
    }
    // Verify mode.
    if (modes.contains(mode)) {
      return mode;
    }
    throw ('unknown mode: $mode');
  }

  // Context.
  final int isolates;
  final int repeat;
  final int time;
  final bool trueDivergence;
  final bool showStats;
  final bool rerun;
  final String top;
  final String mode1;
  final String mode2;

  // Passes each port to isolate.
  SendPort port;

  // Modes used on cluster runs.
  static const List<String> clusterModes = [
    'jit-debug-ia32',
    'jit-debug-x64',
    'jit-debug-arm32',
    'jit-debug-arm64',
    'jit-ia32',
    'jit-x64',
    'jit-arm32',
    'jit-arm64',
    'aot-debug-x64',
    'aot-x64',
    'kbc-int-debug-ia32',
    'kbc-cmp-debug-ia32',
    'kbc-mix-debug-ia32',
    'kbc-int-debug-x64',
    'kbc-cmp-debug-x64',
    'kbc-mix-debug-x64',
    'kbc-int-debug-arm32',
    'kbc-cmp-debug-arm32',
    'kbc-mix-debug-arm32',
    'kbc-int-debug-arm64',
    'kbc-cmp-debug-arm64',
    'kbc-mix-debug-arm64',
    'kbc-int-ia32',
    'kbc-cmp-ia32',
    'kbc-mix-ia32',
    'kbc-int-x64',
    'kbc-cmp-x64',
    'kbc-mix-x64',
    'kbc-int-arm32',
    'kbc-cmp-arm32',
    'kbc-mix-arm32',
    'kbc-int-arm64',
    'kbc-cmp-arm64',
    'kbc-mix-arm64',
  ];

  // Modes not used on cluster runs because they have outstanding issues.
  static const List<String> nonClusterModes = [
    // Deprecated.
    'jit-debug-dbc32',
    'jit-debug-dbc64',
    'jit-dbc32',
    'jit-dbc64',
    // Times out often:
    'aot-debug-arm32',
    'aot-debug-arm64',
    'aot-arm32',
    'aot-arm64',
    // Too many divergences (due to arithmetic):
    'js-x64',
  ];

  // All modes.
  static List<String> modes = clusterModes + nonClusterModes;
}

/// Main driver for a fuzz testing session.
main(List<String> arguments) {
  // Set up argument parser.
  final parser = new ArgParser()
    ..addOption('isolates', help: 'number of isolates to use', defaultsTo: '1')
    ..addOption('repeat', help: 'number of tests to run', defaultsTo: '1000')
    ..addOption('time', help: 'time limit in seconds', defaultsTo: '0')
    ..addFlag('true-divergence',
        negatable: true, help: 'only report true divergences', defaultsTo: true)
    ..addFlag('show-stats',
        negatable: true, help: 'show session statistics', defaultsTo: true)
    ..addOption('dart-top', help: 'explicit value for \$DART_TOP')
    ..addOption('mode1', help: 'execution mode 1')
    ..addOption('mode2', help: 'execution mode 2')
    ..addFlag('rerun',
        negatable: true,
        help: 're-run if test only diverges on return code (not in the output)',
        defaultsTo: true)
    // Undocumented options for cluster runs.
    ..addOption('shards',
        help: 'number of shards used in cluster run', defaultsTo: '1')
    ..addOption('shard', help: 'shard id in cluster run', defaultsTo: '1')
    ..addOption('output_directory',
        help: 'path to output (ignored)', defaultsTo: null)
    ..addOption('output-directory',
        help: 'path to output (ignored)', defaultsTo: null);

  // Starts fuzz testing session.
  try {
    final results = parser.parse(arguments);
    final shards = int.parse(results['shards']);
    final shard = int.parse(results['shard']);
    if (shards > 1) {
      print('\nSHARD $shard OF $shards');
    }
    new DartFuzzTestSession(
            int.parse(results['isolates']),
            int.parse(results['repeat']),
            int.parse(results['time']),
            results['true-divergence'],
            results['show-stats'],
            results['dart-top'],
            results['mode1'],
            results['mode2'],
            results['rerun'])
        .start();
  } catch (e) {
    print('Usage: dart dartfuzz_test.dart [OPTIONS]\n${parser.usage}\n$e');
    exitCode = 255;
  }
}
