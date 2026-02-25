// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common/test_utils.dart';

final packageRoot = p.dirname(
  p.dirname(
    Isolate.resolvePackageUriSync(
      Uri.parse('package:perf_witness/server.dart'),
    )!.toFilePath(),
  ),
);

final testsDir = p.join(packageRoot, 'test');
final binDir = p.join(packageRoot, 'bin');

Future<io.Process> runProcess(
  String executable,
  List<String> arguments, {
  String tag = '',
  Pattern? waitFor,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  List<String>? stdout,
}) async {
  final ready = Completer();

  final process = await io.Process.start(
    executable,
    arguments,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
  );
  process.exitCode.whenComplete(() {
    if (!ready.isCompleted) {
      ready.complete();
    }
  });
  process.stdout.transform(Utf8Decoder()).transform(LineSplitter()).listen((
    line,
  ) {
    if (waitFor != null && !ready.isCompleted && line.contains(waitFor)) {
      ready.complete();
    }
    print('[$tag]stdout> $line');
    stdout?.add(line);
  });
  process.stderr.transform(Utf8Decoder()).transform(LineSplitter()).listen((
    line,
  ) {
    print('[$tag]stderr> $line');
  });
  if (waitFor != null) {
    await ready.future;
  }
  return process;
}

extension on io.Process {
  Future<void> askToExit() async {
    // On Windows we can't send Ctrl-C so we resort to using a Q keypress
    // instead.
    if (io.Platform.isWindows) {
      stdin.add('q'.codeUnits);
      await stdin.flush();
    } else {
      kill(io.ProcessSignal.sigint);
    }
  }
}

class BusyLoopProcess {
  final io.Process process;
  final String tag;
  final List<String> stdout;

  BusyLoopProcess._(this.process, this.tag, this.stdout);

  static Future<BusyLoopProcess> start(
    String tag,
    io.Directory tempDir, {
    bool startIsolate = false,
    bool aot = false,
    bool startInBackground = false,
    bool overrideDartDataHome = true,
    bool noShutdown = false,
    bool useDeferred = false,
    Uri? spawnUri,
    Map<String, String>? environment,
  }) async {
    final busyLoopArgs = [
      '--tag',
      tag,
      if (startIsolate) '--start-isolate',
      if (startInBackground) '--start-in-background',
      if (noShutdown) '--no-shutdown',
      if (useDeferred) '--use-deferred',
      if (spawnUri != null) ...['--spawn-uri', spawnUri.toString()],
    ];

    final stdout = <String>[];
    final String executable;
    if (aot) {
      final snapshot = p.join(tempDir.path, 'busyLoop.aot');
      executable = useDeferred
          ? p.join(p.dirname(io.Platform.resolvedExecutable), 'dartaotruntime')
          : p.join(tempDir.path, 'busyLoop.exe');
      if (useDeferred) {
        busyLoopArgs.insert(0, snapshot);
      }
      final result = await io.Process.run(io.Platform.resolvedExecutable, [
        'compile',
        if (useDeferred) 'aot-snapshot' else 'exe',
        '-o',
        if (useDeferred) snapshot else executable,
        if (useDeferred)
          '--extra-gen-snapshot-options=--loading-unit-manifest=${p.join(tempDir.path, 'manifest.json')}',
        p.join(testsDir, 'common', 'busy_loop.dart'),
      ]);
      if (result.exitCode != 0) {
        throw 'Failed to compile busyLoop script to a binary';
      }
    } else {
      executable = io.Platform.resolvedExecutable;
      busyLoopArgs.insertAll(0, [
        'run',
        p.join(testsDir, 'common', 'busy_loop.dart'),
      ]);
    }

    final process = await runProcess(
      executable,
      busyLoopArgs,
      tag: 'busy-loop($tag)',
      waitFor: 'BUSY LOOP READY',
      environment: {
        ...?environment,
        if (overrideDartDataHome) 'DART_DATA_HOME': tempDir.path,
      },
      includeParentEnvironment: environment == null,
      stdout: stdout,
    );

    return BusyLoopProcess._(process, tag, stdout);
  }

  int get pid {
    if (io.Platform.isWindows) {
      // On Windows dartvm.exe is a child process of dart.exe so process.pid
      // does not necessary match the PID of the process which will actually
      // execute the code.
      return int.parse(
        stdout.firstWhere((line) => line.startsWith('PID: ')).split(': ')[1],
      );
    }

    return process.pid;
  }

  void kill() {
    process.kill();
  }
}

class RecorderProcess {
  final List<String> stdout;
  final io.Process process;

  RecorderProcess._(this.process, this.stdout);

  static final pressKeyPattern = RegExp(r'Press (Ctrl-C|Q) to exit');

  static Future<RecorderProcess> start(
    io.Directory tempDir,
    io.Directory outputDir, {
    String? tag,
    bool recordNewProcesses = false,
    bool recordOnlyNewProcesses = false,
    bool enableAsyncSpans = false,
    bool enableProfiler = true,
    List<String> streams = const ['dart', 'gc'],
  }) async {
    final stdout = <String>[];
    return RecorderProcess._(
      await runProcess(
        io.Platform.resolvedExecutable,
        [
          'run',
          p.join(binDir, 'recorder.dart'),
          '-o',
          outputDir.path,
          if (tag != null) ...['--tag', tag],
          if (io.Platform.isWindows) '--wait-for-keypress',
          if (recordNewProcesses) '--record-new-processes',
          if (recordOnlyNewProcesses) '--record-only-new-processes',
          if (enableAsyncSpans) '--enable-async-spans',
          if (!enableProfiler) '--no-enable-profiler',
          if (streams != const ['dart', 'gc']) ...[
            '--streams',
            streams.join(','),
          ],
        ],
        tag: 'recorder',
        environment: {'DART_DATA_HOME': tempDir.path},
        waitFor: pressKeyPattern,
        stdout: stdout,
      ),
      stdout,
    );
  }

  Future<void> stop() async {
    await process.askToExit();
    if (await process.exitCode case final int exitCode when exitCode != 0) {
      throw Exception('Recorder process failed with exit code $exitCode');
    }
  }
}

void main() {
  group('Recorder and Server', () {
    late BusyLoopProcess busyLoopProcess;
    late io.Directory tempDir;

    setUp(() async {
      tempDir = io.Directory.systemTemp.createTempSync();
      busyLoopProcess = await BusyLoopProcess.start('busy-loop-tag', tempDir);
    });

    tearDown(() {
      busyLoopProcess.kill();
      tempDir.deleteSync(recursive: true);
    });

    test('end-to-end test with recorder script (JIT)', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(tempDir, outputDir);
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(
        traceData.hasSeenStack([
          'busyLoop',
          'AsyncSpan.run',
          'busyLoop.<anonymous closure>',
        ]),
        isTrue,
      );
      // Dart track should be enabled by default.
      expect(traceData.seenEvents, containsAll(['sleep']));
    });

    test('end-to-end test with recorder script - early exit', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(tempDir, outputDir);
      await Future.delayed(const Duration(seconds: 2));
      await busyLoopProcess.process.askToExit();
      await busyLoopProcess.process.exitCode;
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isTrue);
      expect(
        traceData.hasSeenStack([
          '_RawReceivePort._handleMessage',
          '_Timer._handleMessage',
          '_Timer._runTimers',
        ]),
        isTrue,
      );
      expect(traceData.seenEvents, containsAll(['sleep']));
    });

    test('profiler can be disabled', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        enableProfiler: false,
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isFalse);
      expect(traceData.seenEvents, containsAll(['sleep']));
    });

    test('streams can be configured', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        enableProfiler: false,
        streams: ['isolate', 'compiler'],
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isFalse);
      expect(
        traceData.seenEvents,
        containsAll(['HandleMessage', 'CompileFunction']),
      );
      // Dart trace is disabled.
      expect(traceData.seenEvents, isNot(contains('sleep')));
    });

    test('tag filtering positive test', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'busy-loop-tag',
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(
        timelines,
        equals(['${busyLoopProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );
    });

    test('tag filtering negative test', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'unmatched-tag',
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(
        timelines,
        isEmpty,
        reason: 'Expected no timeline file to be created',
      );
    });

    test('async spans are not activated by default', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final busyLoopWithIsolate = await BusyLoopProcess.start(
        'busy-loop-with-isolate-tag',
        tempDir,
        startIsolate: true,
      );

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(tempDir, outputDir);
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      busyLoopWithIsolate.kill();

      expect(
        busyLoopProcess.stdout,
        contains('[main] AsyncSpan.create is nop: true'),
      );
      expect(
        busyLoopProcess.stdout,
        isNot(contains('[main] AsyncSpan.create is nop: false')),
      );
      expect(
        busyLoopProcess.stdout,
        isNot(contains('[child-isolate] AsyncSpan.create is nop: true')),
      );
      expect(
        busyLoopProcess.stdout,
        isNot(contains('[child-isolate] AsyncSpan.create is nop: false')),
      );

      expect(
        busyLoopWithIsolate.stdout,
        contains('[main] AsyncSpan.create is nop: true'),
      );
      expect(
        busyLoopWithIsolate.stdout,
        isNot(contains('[main] AsyncSpan.create is nop: false')),
      );
      expect(
        busyLoopWithIsolate.stdout,
        contains('[child-isolate] AsyncSpan.create is nop: true'),
      );
      expect(
        busyLoopWithIsolate.stdout,
        isNot(contains('[child-isolate] AsyncSpan.create is nop: false')),
      );

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(
        timelines,
        unorderedEquals([
          '${busyLoopProcess.pid}.timeline',
          '${busyLoopWithIsolate.pid}.timeline',
        ]),
        reason: 'Expected timeline file to be created',
      );
    });

    test('async spans are activated when requested', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final busyLoopWithIsolate = await BusyLoopProcess.start(
        'busy-loop-with-isolate-tag',
        tempDir,
        startIsolate: true,
      );

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        enableAsyncSpans: true,
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      busyLoopWithIsolate.kill();

      expect(
        busyLoopProcess.stdout,
        contains('[main] AsyncSpan.create is nop: false'),
      );
      expect(
        busyLoopProcess.stdout,
        isNot(contains('[child-isolate] AsyncSpan.create is nop: true')),
      );
      expect(
        busyLoopProcess.stdout,
        isNot(contains('[child-isolate] AsyncSpan.create is nop: false')),
      );

      expect(
        busyLoopWithIsolate.stdout,
        contains('[main] AsyncSpan.create is nop: false'),
      );
      expect(
        busyLoopWithIsolate.stdout,
        contains('[child-isolate] AsyncSpan.create is nop: false'),
      );

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(
        timelines,
        unorderedEquals([
          '${busyLoopProcess.pid}.timeline',
          '${busyLoopWithIsolate.pid}.timeline',
        ]),
        reason: 'Expected timeline file to be created',
      );
    });

    test('record new processes - all', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordNewProcesses: true,
      );

      // Start a new process that should be recorded.
      final newProcess = await BusyLoopProcess.start(
        'new-process-tag',
        tempDir,
      );

      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      newProcess.kill();

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(
        timelines,
        unorderedEquals([
          '${newProcess.pid}.timeline',
          '${busyLoopProcess.pid}.timeline',
        ]),
      );
    });

    test('record new processes - specific tag', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'new-process-tag',
        recordNewProcesses: true,
      );
      // Start a new process that should be recorded.
      final newProcess = await BusyLoopProcess.start(
        'new-process-tag',
        tempDir,
      );

      // Start a new process that should NOT be recorded.
      final ignoredProcess = await BusyLoopProcess.start(
        'ignored-tag',
        tempDir,
      );

      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      newProcess.kill();
      ignoredProcess.kill();

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(timelines, unorderedEquals(['${newProcess.pid}.timeline']));
    });

    test('record only new processes', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process with --record-only-new-processes
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordOnlyNewProcesses: true,
      );

      // Start a new process that should be recorded.
      final newProcess = await BusyLoopProcess.start(
        'new-process-tag',
        tempDir,
      );

      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelines = outputDir
          .listSync()
          .map((e) => p.basename(e.path))
          .toList();
      expect(
        timelines,
        unorderedEquals(['${newProcess.pid}.timeline']),
        reason: 'Expected only new process to be recorded',
      );

      await newProcess.process.askToExit();
    });

    test('detect already running recorder', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final recorder1 = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordOnlyNewProcesses: true,
      );

      final recorder2 = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordOnlyNewProcesses: true,
      );
      await recorder1.stop();

      await expectLater(recorder1.process.exitCode, completes);
      expect(
        recorder2.stdout.join('\n'),
        contains(
          'another recorder process (pid ${recorder1.process.pid})'
          ' is already running',
        ),
      );
    });

    test('delete stale control socket', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Start a recorder to create the socket.
      final recorder1 = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordOnlyNewProcesses: true,
      );

      // Kill it forcibly so it leaves the socket.
      recorder1.process.kill(io.ProcessSignal.sigkill);
      await recorder1.process.exitCode;

      // Start another recorder. It should detect stale socket, delete it,
      // and start successfully.
      final recorder2 = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordOnlyNewProcesses: true,
      );

      await recorder2.stop();
    });

    test('start(inBackground: true) does not miss startup events', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      // Run the recorder in a separate process with --record-only-new-processes
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        recordOnlyNewProcesses: true,
      );

      // Start a new process that should be recorded.
      final newProcess = await BusyLoopProcess.start(
        'new-process-tag',
        tempDir,
      );
      await Future.delayed(const Duration(seconds: 1));
      await recorder.stop();

      final timelineFiles = outputDir.listSync().whereType<io.File>();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        unorderedEquals(['${newProcess.pid}.timeline']),
        reason: 'Expected only new process to be recorded',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isTrue);
      expect(traceData.hasSeenStack(['main']), isTrue);
      expect(traceData.seenEvents, containsAll(['ImportantStartupEvent']));

      await newProcess.process.askToExit();
    });
  });

  group('Failure cases', () {
    late io.Directory tempDir;

    setUp(() async {
      tempDir = io.Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('error to start server due no HOME is ignored gracefully', () async {
      final busyLoopProcess = await BusyLoopProcess.start(
        'busy-loop-tag',
        tempDir,
        overrideDartDataHome: false,
        environment: {},
      );
      await busyLoopProcess.process.askToExit();
      expect(await busyLoopProcess.process.exitCode, 0);
    });
  });

  group('AOT specific', () {
    late io.Directory tempDir;

    setUp(() async {
      tempDir = io.Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('end-to-end test with recorder script', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final busyLoopAotProcess = await BusyLoopProcess.start(
        'busy-loop-aot',
        tempDir,
        aot: true,
      );

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'busy-loop-aot',
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopAotProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isTrue);
      expect(
        traceData.hasSeenStack([
          'busyLoop',
          'AsyncSpan.run',
          'busyLoop.<anonymous closure>',
        ]),
        isTrue,
      );
      expect(traceData.seenEvents, containsAll(['sleep']));

      await busyLoopAotProcess.process.askToExit();
    });

    test('multiple isolate groups', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final simpleHotLoopSnapshot = p.join(tempDir.path, 'simple_hot_loop.aot');
      final result = await io.Process.run(io.Platform.executable, [
        'compile',
        'aot-snapshot',
        '-o',
        simpleHotLoopSnapshot,
        p.join(testsDir, 'common', 'simple_hot_loop.dart'),
      ]);
      expect(result.exitCode, 0);

      final busyLoopAotProcess = await BusyLoopProcess.start(
        'busy-loop-aot',
        tempDir,
        spawnUri: Uri.file(simpleHotLoopSnapshot),
        aot: true,
      );

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'busy-loop-aot',
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopAotProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isTrue);
      expect(
        traceData.hasSeenStack([
          'busyLoop',
          'AsyncSpan.run',
          'busyLoop.<anonymous closure>',
        ]),
        isTrue,
      );
      expect(traceData.hasSeenStack(['main', 'hotLoop']), isTrue);
      expect(traceData.seenEvents, containsAll(['sleep']));

      await busyLoopAotProcess.process.askToExit();
    });

    test('exiting without stopping recording', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final simpleHotLoopSnapshot = p.join(tempDir.path, 'simple_hot_loop.aot');
      final result = await io.Process.run(io.Platform.executable, [
        'compile',
        'aot-snapshot',
        '-o',
        simpleHotLoopSnapshot,
        p.join(testsDir, 'common', 'simple_hot_loop.dart'),
      ]);
      expect(result.exitCode, 0);

      final busyLoopAotProcess = await BusyLoopProcess.start(
        'busy-loop-aot',
        tempDir,
        noShutdown: true,
        aot: true,
        spawnUri: Uri.file(simpleHotLoopSnapshot),
      );

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'busy-loop-aot',
      );
      await Future.delayed(const Duration(seconds: 2));
      await busyLoopAotProcess.process.askToExit();
      await busyLoopAotProcess.process.exitCode;
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopAotProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isTrue);
      expect(
        traceData.hasSeenStack([
          'busyLoop',
          'AsyncSpan.run',
          'busyLoop.<anonymous closure>',
        ]),
        isTrue,
      );
      expect(traceData.hasSeenStack(['main', 'hotLoop']), isTrue);
      expect(traceData.seenEvents, containsAll(['sleep']));
    });

    test('with deferred units', () async {
      final outputDir = io.Directory('${tempDir.path}/output')..createSync();

      final busyLoopAotProcess = await BusyLoopProcess.start(
        'busy-loop-aot',
        tempDir,
        aot: true,
        useDeferred: true,
      );

      // Run the recorder in a separate process.
      final recorder = await RecorderProcess.start(
        tempDir,
        outputDir,
        tag: 'busy-loop-aot',
      );
      await Future.delayed(const Duration(seconds: 2));
      await recorder.stop();

      final timelineFiles = outputDir
          .listSync()
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.timeline'))
          .toList();

      final timelines = timelineFiles.map((e) => p.basename(e.path)).toList();
      expect(
        timelines,
        equals(['${busyLoopAotProcess.pid}.timeline']),
        reason: 'Expected timeline file to be created',
      );

      final traceData = TraceData.fromBytes(
        timelineFiles.first.readAsBytesSync(),
      );
      expect(traceData.trace.packet.any((p) => p.hasPerfSample()), isTrue);
      expect(
        traceData.hasSeenStack([
          'busyLoop',
          'AsyncSpan.run',
          'busyLoop.<anonymous closure>',
          // Must be able to symbolize a function from a deferred unit.
          'hotLoop',
        ]),
        isTrue,
      );
      expect(traceData.seenEvents, containsAll(['sleep']));

      await busyLoopAotProcess.process.askToExit();
    });

    test('AOT compiled busy loop is recorded', () async {
      final busyLoopProcess = await BusyLoopProcess.start(
        'busy-loop-tag',
        tempDir,
        aot: true,
      );
      await busyLoopProcess.process.askToExit();
      expect(await busyLoopProcess.process.exitCode, 0);
    });
  });
}
