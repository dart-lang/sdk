// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

enum Status {
  pass,
  fail,
  crash;

  String get outcome => '${name[0].toUpperCase()}${name.substring(1)}';
}

class TestResult {
  final String name;
  final Status status;
  final Duration duration;
  final String output;
  final int retries;

  TestResult(
    this.name,
    this.status,
    this.duration,
    this.output, {
    this.retries = 0,
  });

  String toRecordJson(String configuration) {
    final outcome = status.outcome;

    final index = name.indexOf('/');
    final suite = index != -1 ? name.substring(0, index) : 'pkg';
    final testName = index != -1 ? name.substring(index + 1) : name;
    return jsonEncode({
      'name': name,
      'configuration': configuration,
      'suite': suite,
      'test_name': testName,
      'time_ms': duration.inMilliseconds,
      'expected': 'Pass',
      'result': outcome,
      'matches': status == Status.pass,
    });
  }

  String toLogJson(String configuration) {
    final outcome = switch (status) {
      Status.pass => 'Pass',
      Status.crash => 'Crash',
      Status.fail => 'Fail',
    };
    return jsonEncode({
      'name': name,
      'configuration': configuration,
      'result': outcome,
      'log': output,
    });
  }
}

class ActiveTest {
  final String name;
  final int attempt;
  final Stopwatch stopwatch;
  Process? process;

  ActiveTest(this.name, this.attempt) : stopwatch = Stopwatch()..start();
}

class _SuiteOptions {
  final String? configuration;
  final String? outputDirectory;
  final int concurrency;
  final int retries;
  final Duration timeout;
  final String? filter;
  final bool verbose;

  _SuiteOptions({
    required this.configuration,
    required this.outputDirectory,
    required this.concurrency,
    required this.retries,
    required this.timeout,
    required this.filter,
    required this.verbose,
  });

  static _SuiteOptions parse(List<String> args) {
    final parser = ArgParser()
      ..addOption(
        'named-configuration',
        help: 'Configuration to use for reporting test results',
        abbr: 'n',
        aliases: ['configuration'],
      )
      ..addOption(
        'output-directory',
        help: 'Location to emit the json-l result and log files',
      )
      ..addOption(
        'concurrency',
        help: 'Number of test scripts to run concurrently',
        abbr: 'j',
        defaultsTo: '6',
      )
      ..addOption(
        'retries',
        help: 'Number of times to retry a failed test script',
        defaultsTo: '3',
      )
      ..addOption(
        'timeout',
        help: 'Timeout in seconds for an individual test script attempt',
        abbr: 't',
        defaultsTo: '90',
      )
      ..addOption('filter', help: 'Only run test files matching this substring')
      ..addFlag('verbose', help: 'Enable verbose logging', defaultsTo: false);

    final parsed = parser.parse(args);
    return _SuiteOptions(
      configuration: parsed.option('named-configuration'),
      outputDirectory: parsed.option('output-directory'),
      concurrency: int.parse(parsed.option('concurrency')!),
      retries: int.parse(parsed.option('retries')!),
      timeout: Duration(seconds: int.parse(parsed.option('timeout')!)),
      filter: parsed.option('filter'),
      verbose: parsed.flag('verbose'),
    );
  }
}

class _EnvironmentPaths {
  final String dwdsDir;
  final Directory integrationDir;

  _EnvironmentPaths({required this.dwdsDir, required this.integrationDir});

  static _EnvironmentPaths resolve() {
    final packageUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:dwds/dwds.dart'),
    );
    if (packageUri == null) {
      throw StateError('Could not resolve package:dwds/dwds.dart');
    }
    final dwdsDir = p.dirname(p.dirname(packageUri.toFilePath()));
    final integrationDir = Directory(p.join(dwdsDir, 'test', 'integration'));

    if (!integrationDir.existsSync()) {
      throw StateError(
        'Integration directory not found at ${integrationDir.path}',
      );
    }

    return _EnvironmentPaths(dwdsDir: dwdsDir, integrationDir: integrationDir);
  }
}

final _activeTests = <ActiveTest>{};
final _completedResults = <TestResult>[];

void main([List<String> args = const []]) async {
  _setupSignalHandling();
  final options = _SuiteOptions.parse(args);
  final env = _EnvironmentPaths.resolve();

  final testFiles = _findTestFiles(env.integrationDir, options.filter);
  print('Found ${testFiles.length} integration test files.');

  final results = await _executeTestSuite(
    testFiles: testFiles,
    dwdsDir: env.dwdsDir,
    options: options,
  );

  final code = _reportResults(
    results,
    configuration: options.configuration,
    logDir: options.outputDirectory,
  );
  _cancelSignalHandlers();
  exit(code);
}

List<File> _findTestFiles(Directory integrationDir, String? filter) {
  return integrationDir
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.path.endsWith('_test.dart') &&
            !f.path.endsWith('integration_suite_test.dart') &&
            (filter == null || f.path.contains(filter)),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

Future<List<TestResult>> _executeTestSuite({
  required List<File> testFiles,
  required String dwdsDir,
  required _SuiteOptions options,
}) async {
  final results = <TestResult>[];
  var index = 0;

  Future<void> worker() async {
    while (true) {
      if (index >= testFiles.length) break;
      final testFile = testFiles[index++];
      final testName = _getTestName(testFile, dwdsDir);
      print('Starting test: $testName');

      final result = await _runTestScript(testFile, testName, options: options);

      results.add(result);
      _completedResults.add(result);
      _printTestResult(result, options);
    }
  }

  await Future.wait(List.generate(options.concurrency, (_) => worker()));
  results.sort((a, b) => a.name.compareTo(b.name));
  return results;
}

Future<TestResult> _runTestScript(
  File testFile,
  String testName, {
  required _SuiteOptions options,
}) async {
  final timeout = options.timeout;
  final maxRetries = options.retries;
  for (var retry = 0; retry <= maxRetries; retry++) {
    final active = ActiveTest(testName, retry + 1);
    _activeTests.add(active);

    try {
      final process = await Process.start(Platform.resolvedExecutable, [
        'test',
        '--timeout=${timeout.inSeconds}s',
        testFile.path,
      ]);
      active.process = process;

      final processOutput = _ProcessOutput.collect(process, testName, options);

      // An individual script may run multiple tests and includes compiler /
      // browser startup overhead, so we buffer the overall process timeout
      // beyond the per-test timeout passed to package:test.
      final scriptTimeout = timeout + const Duration(seconds: 20);

      final exitCode = await process.exitCode.timeout(
        scriptTimeout,
        onTimeout: () async {
          final message =
              '[TIMEOUT] $testName exceeded overall script timeout '
              '(${scriptTimeout.inSeconds}s). Force killing process.';
          print('  $message');
          processOutput.stderr.writeln(message);
          await _killProcessTree(process);
          return -1;
        },
      );

      final output = await processOutput.finish();
      active.stopwatch.stop();
      _activeTests.remove(active);

      if (exitCode == 0) {
        return TestResult(
          testName,
          Status.pass,
          active.stopwatch.elapsed,
          output,
          retries: retry,
        );
      }
      if (retry == maxRetries) {
        return TestResult(
          testName,
          Status.fail,
          active.stopwatch.elapsed,
          output,
          retries: retry,
        );
      }
      _printRetryNotice(testName, retry, maxRetries, 'failed', output, options);
    } catch (e, st) {
      active.stopwatch.stop();
      _activeTests.remove(active);

      if (retry == maxRetries) {
        return TestResult(
          testName,
          Status.crash,
          active.stopwatch.elapsed,
          '$e\n$st',
          retries: retry,
        );
      }
      _printRetryNotice(
        testName,
        retry,
        maxRetries,
        'crashed',
        '$e\n$st',
        options,
      );
    }
  }
  throw StateError('Unreachable');
}

/// Kills [process] along with any child processes it spawned.
///
/// [Process.kill] only terminates the process itself, so child processes
/// (ChromeDriver, Chrome, the frontend server, ...) would keep running and
/// slow down the tests that follow.
Future<void> _killProcessTree(Process process) async {
  try {
    if (Platform.isWindows) {
      await _killWindowsProcessTree(process.pid);
    } else {
      await _killPosixProcessTree(process.pid);
    }
  } on Exception catch (e) {
    print('  [WARNING] Failed to kill process tree of PID ${process.pid}: $e');
  }
  // Make sure the process itself is gone even if killing the tree failed.
  process.kill(ProcessSignal.sigkill);
}

/// Kills the process [pid] and its descendants with `taskkill /T`.
Future<void> _killWindowsProcessTree(int pid) async {
  final args = [
    // Terminate the process tree: the process and all of its descendants.
    '/T',
    // Forcefully terminate the processes, instead of asking them to close.
    '/F',
    // Select the process to terminate by its process ID.
    '/PID', '$pid',
  ];
  final result = await Process.run('taskkill', args);
  if (result.exitCode != 0) {
    throw ProcessException(
      'taskkill',
      args,
      '${result.stderr}'.trim(),
      result.exitCode,
    );
  }
}

/// Kills the process [pid] and its descendants with SIGKILL.
///
/// The descendants are collected before anything is killed, since orphaned
/// processes are reparented and can no longer be found from [pid].
Future<void> _killPosixProcessTree(int pid) async {
  final pids = [pid, ...await _descendantPids(pid)];
  for (final target in pids) {
    Process.killPid(target, ProcessSignal.sigkill);
  }
}

/// Returns the PIDs of all descendants of the process [pid], using
/// `pgrep -P` (available on both Linux and macOS).
Future<List<int>> _descendantPids(int pid) async {
  // pgrep exits with 1 when there are no matching processes.
  final result = await Process.run('pgrep', ['-P', '$pid']);
  final children = LineSplitter.split(result.stdout as String)
      .map(int.tryParse)
      .nonNulls;
  return [
    for (final child in children) ...[child, ...await _descendantPids(child)],
  ];
}

/// Collects the stdout and stderr of a test process so that it can be
/// included in the test result, echoing it live when running verbosely.
class _ProcessOutput {
  /// How long to wait for the output streams to close after the process
  /// exits.
  ///
  /// Orphaned child processes may keep the pipes open indefinitely, in which
  /// case the output collected so far is used.
  static const _drainTimeout = Duration(seconds: 5);

  final StringBuffer stdout;
  final StringBuffer stderr;
  final Future<void> _done;

  _ProcessOutput._(this.stdout, this.stderr, this._done);

  factory _ProcessOutput.collect(
    Process process,
    String testName,
    _SuiteOptions options,
  ) {
    Future<void> record(
      Stream<List<int>> stream,
      StringBuffer buffer,
      String livePrefix,
    ) {
      return stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            buffer.writeln(line);
            if (options.verbose) print('  [$livePrefix | $testName] $line');
          });
    }

    final stdout = StringBuffer();
    final stderr = StringBuffer();
    final done = Future.wait([
      record(process.stdout, stdout, 'LIVE'),
      record(process.stderr, stderr, 'STDERR LIVE'),
    ]).then<void>((_) {});
    return _ProcessOutput._(stdout, stderr, done);
  }

  /// Waits briefly for the output streams to close and returns the combined
  /// output collected so far.
  Future<String> finish() async {
    await _done.timeout(
      _drainTimeout,
      onTimeout: () => stderr.writeln(
        '<output streams still open ${_drainTimeout.inSeconds}s after the '
        'process exited; output may be incomplete>',
      ),
    );
    return '$stdout\n$stderr'.trim();
  }
}

void _printTestResult(TestResult result, _SuiteOptions options) {
  if (!options.verbose) return;
  if (result.status == Status.pass) {
    print('  [PASS] ${result.name} (${result.duration.inSeconds}s)');
  } else {
    final statusString = result.status.name.toUpperCase();
    final separator = '=' * 70;
    print('''

$separator
  [$statusString] ${result.name} (${result.duration.inSeconds}s)
$separator
${result.output}
$separator
  [$statusString] END OF OUTPUT FOR ${result.name}
$separator
''');
  }
}

void _printRetryNotice(
  String testName,
  int attempt,
  int maxRetries,
  String action,
  String detail,
  _SuiteOptions options,
) {
  if (!options.verbose) return;
  final separator = '=' * 70;
  print('''

$separator
  [RETRY] $testName $action (attempt $attempt/${maxRetries + 1}). Retrying...
$separator
$detail
$separator
  [RETRY] END OF ATTEMPT $attempt OUTPUT FOR $testName
$separator
''');
}

final _signalSubscriptions = <StreamSubscription<ProcessSignal>>[];

void _setupSignalHandling() {
  if (Platform.isWindows) return;
  for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
    _signalSubscriptions.add(
      signal.watch().listen((_) {
        _printInterruptedSummary();
        exit(1);
      }),
    );
  }
}

void _cancelSignalHandlers() {
  for (final sub in _signalSubscriptions) {
    sub.cancel();
  }
  _signalSubscriptions.clear();
}

void _printInterruptedSummary() {
  final separator = '=' * 70;
  final buffer = StringBuffer()
    ..writeln('\n$separator')
    ..writeln('  [INTERRUPTED / TIMEOUT] Suite terminated by signal.')
    ..writeln('  Active tests at time of interruption:')
    ..writeln(separator);
  for (final active in _activeTests) {
    buffer.writeln(
      '  - ${active.name} (attempt ${active.attempt}, '
      'running for ${active.stopwatch.elapsed.inSeconds}s)',
    );
    active.process?.kill();
  }
  buffer.writeln('$separator\n');

  final passedResults = _completedResults
      .where((r) => r.status == Status.pass)
      .toList();
  buffer
    ..writeln('  Succeeded tests: ${passedResults.length}')
    ..writeln(separator);
  if (passedResults.isEmpty) {
    buffer.writeln('  None.');
  } else {
    for (final result in passedResults) {
      final retriesText = result.retries == 1
          ? '1 retry'
          : '${result.retries} retries';
      buffer.writeln(
        '  - ${result.name} (${result.duration.inSeconds}s, $retriesText)',
      );
    }
  }
  buffer.writeln('$separator\n');
  print(buffer);
}

String _getTestName(File file, String dwdsDir) {
  final relPath = p.relative(file.path, from: dwdsDir);
  final withoutExt = p.withoutExtension(relPath);
  return p.join('pkg', 'dwds', withoutExt).replaceAll('\\', '/');
}

int _reportResults(
  List<TestResult> results, {
  String? configuration,
  String? logDir,
}) {
  final failedResults = results.where((r) => r.status != Status.pass).toList();
  final buffer = StringBuffer()
    ..writeln('\n================ Test Summary ================');
  for (final result in results) {
    final retriesText = result.retries > 0
        ? ' (retries: ${result.retries})'
        : '';
    buffer.writeln(
      '  ${result.name}: ${result.status.name.toUpperCase()} '
      '(${result.duration.inSeconds}s)$retriesText',
    );
  }

  if (logDir != null && configuration != null) {
    final dirUri = Directory(logDir).uri;
    final resultsBuffer = StringBuffer();
    for (final r in results) {
      resultsBuffer.writeln(r.toRecordJson(configuration));
    }
    File.fromUri(dirUri.resolve('results.json'))
        .writeAsStringSync(resultsBuffer.toString(), flush: true);

    final logsBuffer = StringBuffer();
    for (final r in failedResults) {
      logsBuffer.writeln(r.toLogJson(configuration));
    }
    File.fromUri(dirUri.resolve('logs.json'))
        .writeAsStringSync(logsBuffer.toString(), flush: true);
    buffer.writeln('Log files emitted under $dirUri');
  }

  if (failedResults.isNotEmpty) {
    buffer.writeln('\n================ Failed Tests ================');
    for (final result in failedResults) {
      buffer.writeln(
        '  ${result.name}: ${result.status.name.toUpperCase()} '
        '(${result.duration.inSeconds}s)',
      );
    }
    buffer.writeln(
      '\nError: ${failedResults.length} integration test(s) failed '
      '(see Failed Tests list above).',
    );
  } else {
    buffer.writeln('\nSuccess: All integration tests passed.');
  }
  print(buffer);

  if (logDir != null && configuration != null) {
    return 0;
  }
  return failedResults.isNotEmpty ? 1 : 0;
}
