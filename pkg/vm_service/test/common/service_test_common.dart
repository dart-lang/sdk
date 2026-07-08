// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection' show HashMap;
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_protos/vm_service_protos.dart' hide Frame;

import 'service_test_common.dart' as service_test_common;

import 'test_helper.dart'
    show runIsolateTests, runIsolateTestsSynchronous, runVMTests;

abstract class _TestHarness<T> {
  final List<String> args;
  final String _scriptName;
  final List<T> _tests = [];
  final TestScriptParser _scriptParser;

  _TestHarness(this._scriptName, this.args)
      : _scriptParser = TestScriptParser(_scriptName);

  List<T> get tests => _tests;
}

class VMTestHarness extends _TestHarness<VMTest> {
  VMTestHarness(super.scriptName, super.args);

  VMTestHarness addTest(VMTest test) {
    _tests.add(test);
    return this;
  }

  VMTestHarness addTestWithParser(VMTestWithParser test) {
    _tests.add((service) => test(service, _scriptParser));
    return this;
  }

  Future<void> run({
    bool pauseOnStart = false,
    bool pauseOnExit = false,
    bool pauseOnUnhandledExceptions = false,
    bool allowForNonZeroExitCode = false,
    bool useAuthToken = false,
    List<String>? extraArgs,
    VmServiceFactory serviceFactory = VmService.defaultFactory,
    required Future<void> Function(List<String> args) testeeMain,
  }) =>
      runVMTests(
        args,
        _tests,
        _scriptName,
        pauseOnStart: pauseOnStart,
        pauseOnExit: pauseOnExit,
        pauseOnUnhandledExceptions: pauseOnUnhandledExceptions,
        extraArgs: extraArgs,
        serviceFactory: serviceFactory,
        testeeMain: testeeMain,
      );
}

class IsolateTestHarness extends _TestHarness<IsolateTest> {
  final List<String> _recordedStops = [];

  IsolateTestHarness(super.scriptName, super.args);

  IsolateTestHarness addCustomTestWithParser(IsolateTestWithParser test) {
    _tests
        .add((service, isolateRef) => test(service, isolateRef, _scriptParser));
    return this;
  }

  IsolateTestHarness addCustomTest(IsolateTest test) {
    _tests.add(test);
    return this;
  }

  Future<void> run({
    bool pauseOnStart = false,
    bool pauseOnExit = false,
    bool pauseOnUnhandledExceptions = false,
    bool launchTesteeWithDartRunResident = false,
    bool allowForNonZeroExitCode = false,
    bool useAuthToken = false,
    List<String>? extraArgs,
    Map<String, String>? testeeEnvironment,
    required Future<void> Function(List<String> args) testeeMain,
  }) =>
      runIsolateTests(
        args,
        _tests,
        _scriptName,
        pauseOnStart: pauseOnStart,
        pauseOnExit: pauseOnExit,
        pauseOnUnhandledExceptions: pauseOnUnhandledExceptions,
        launchTesteeWithDartRunResident: launchTesteeWithDartRunResident,
        allowForNonZeroExitCode: allowForNonZeroExitCode,
        useAuthToken: useAuthToken,
        extraArgs: extraArgs,
        testeeEnvironment: testeeEnvironment,
        testeeMain: testeeMain,
      );

  void runSync({
    bool pauseOnStart = false,
    bool pauseOnExit = false,
    List<String>? extraArgs,
    required Future<void> Function(List<String> args) testeeMain,
  }) =>
      runIsolateTestsSynchronous(
        args,
        _tests,
        _scriptName,
        pauseOnStart: pauseOnStart,
        pauseOnExit: pauseOnExit,
        extraArgs: extraArgs,
        testeeMain: testeeMain,
      );

  IsolateTestHarness stoppedAtLine(String lineTag) {
    _tests.add(
        service_test_common.stoppedAtLine(_scriptParser.lineForTag(lineTag)));
    return this;
  }

  IsolateTestHarness stoppedAtLineColumnWithTag({
    required String lineTag,
    int? column,
  }) {
    _tests.add(service_test_common.stoppedAtLineColumn(
        line: _scriptParser.lineForTag(lineTag), column: column));
    return this;
  }

  IsolateTestHarness setBreakpointAtLine(String lineTag) {
    _tests.add(service_test_common.setBreakpointAtUriAndLine(
        _scriptName, _scriptParser.lineForTag(lineTag)));
    return this;
  }

  IsolateTestHarness setBreakpointAtUriAndLine(String uri, String lineTag) {
    _tests.add((service, isolateRef) async {
      final resolvedUri = uri.startsWith('package:')
          ? (await service.lookupResolvedPackageUris(isolateRef.id!, [uri]))
              .uris![0]!
          : uri;

      return service_test_common.setBreakpointAtUriAndLine(
              uri, _scriptParser.lineForTag(lineTag, script: resolvedUri))(
          service, isolateRef);
    });
    return this;
  }

  IsolateTestHarness setBreakpointAtLineColumn(String lineTag, int column) {
    _tests.add(service_test_common.setBreakpointAtUriLineColumn(
        _scriptName, _scriptParser.lineForTag(lineTag), column));
    return this;
  }

  IsolateTestHarness hasStoppedAtBreakpoint() {
    _tests.add(service_test_common.hasStoppedAtBreakpoint);
    return this;
  }

  IsolateTestHarness hasPausedAtStart() {
    _tests.add(service_test_common.hasPausedAtStart);
    return this;
  }

  IsolateTestHarness hasStoppedPostRequest() {
    _tests.add(service_test_common.hasStoppedPostRequest);
    return this;
  }

  IsolateTestHarness hasStoppedWithUnhandledException() {
    _tests.add(service_test_common.hasStoppedWithUnhandledException);
    return this;
  }

  IsolateTestHarness hasStoppedAtExit() {
    _tests.add(service_test_common.hasStoppedAtExit);
    return this;
  }

  IsolateTestHarness markDartColonLibrariesDebuggable() {
    _tests.add(service_test_common.markDartColonLibrariesDebuggable);
    return this;
  }

  IsolateTestHarness reloadSources({bool pause = false}) {
    _tests.add(service_test_common.reloadSources(pause: pause));
    return this;
  }

  IsolateTestHarness hasLocalVarInTopStackFrame(String varName) {
    _tests.add(service_test_common.hasLocalVarInTopStackFrame(varName));
    return this;
  }

  IsolateTestHarness stoppedInFunction(String functionName) {
    _tests.add(service_test_common.stoppedInFunction(functionName));
    return this;
  }

  IsolateTestHarness stepOver() {
    _tests.add(service_test_common.stepOver);
    return this;
  }

  IsolateTestHarness stepInto() {
    _tests.add(service_test_common.stepInto);
    return this;
  }

  IsolateTestHarness stepOut() {
    _tests.add(service_test_common.stepOut);
    return this;
  }

  IsolateTestHarness smartNext() {
    _tests.add(service_test_common.smartNext);
    return this;
  }

  IsolateTestHarness asyncNext() {
    _tests.add(service_test_common.asyncNext);
    return this;
  }

  IsolateTestHarness syncNext() {
    _tests.add(service_test_common.syncNext);
    return this;
  }

  IsolateTestHarness resumeIsolate() {
    _tests.add(service_test_common.resumeIsolate);
    return this;
  }

  IsolateTestHarness resumeProgramRecordingStops(
    bool includeCaller,
  ) {
    _tests.add(service_test_common.resumeProgramRecordingStops(
        _recordedStops, includeCaller));
    return this;
  }

  IsolateTestHarness runStepThroughProgramRecordingStops() {
    _tests.add(service_test_common
        .runStepThroughProgramRecordingStops(_recordedStops));
    return this;
  }

  IsolateTestHarness runStepIntoThroughProgramRecordingStops() {
    _tests.add(service_test_common
        .runStepIntoThroughProgramRecordingStops(_recordedStops));
    return this;
  }

  IsolateTestHarness checkRecordedStops({
    bool removeDuplicates = false,
    bool debugPrint = false,
    String? debugPrintFile,
    int? debugPrintLine,
  }) {
    final goldenUri =
        io.Platform.script.resolve('${io.Platform.script.path}.stops');

    _tests.add(service_test_common.checkRecordedStops(
        _recordedStops, goldenUri.toFilePath(),
        removeDuplicates: removeDuplicates,
        debugPrint: debugPrint,
        debugPrintFile: debugPrintFile,
        debugPrintLine: debugPrintLine,
        updateGoldens: args.contains('--update-goldens')));
    return this;
  }

  IsolateTestHarness validateRecordedStops(
    void Function(List<String> recordedStops) validator,
  ) {
    _tests.add((service, isolateRef) async {
      validator(_recordedStops);
    });
    return this;
  }
}

class TestScriptParser {
  final String _mainScript;
  final Map<String, _ParserFileData> _fileData = {};

  TestScriptParser(this._mainScript);

  int lineForTag(String lineTag, {String? script}) {
    script ??= _mainScript;
    return _fileData
        .putIfAbsent(script, () => _ParserFileData(script!))
        .lineForTag(lineTag);
  }

  int lineForRegExp(RegExp regExp, {String? script}) {
    script ??= _mainScript;
    return _fileData
        .putIfAbsent(script, () => _ParserFileData(script!))
        .lineForRegExp(regExp);
  }

  int offsetForTag(String lineTag, {String? script}) {
    script ??= _mainScript;
    return _fileData
        .putIfAbsent(script, () => _ParserFileData(script!))
        .offsetForTag(lineTag);
  }
}

class _ParserFileData {
  final String script;
  late final Map<String, int> _lineTags = _generateLineTags();
  late final Map<String, int> _offsetTags = _generateOffsetTags();
  static final RegExp _lineEndTagRegex = RegExp(r'// LINE_(\S+)$');
  static final RegExp _lineAnyTagRegex = RegExp(r'/\* LINE_(\S+) \*/');
  static final RegExp _offsetTagRegex = RegExp(r'/\* OFFSET_(\S+) \*/');
  static final RegExp _nonWhitespaceRegex = RegExp(r'\S');

  _ParserFileData(this.script);

  Map<String, int> _generateOffsetTags() {
    var text =
        io.File.fromUri(io.Platform.script.resolve(script)).readAsStringSync();
    final offsetTags = <String, int>{};
    RegExpMatch? match;
    int offsetCounter = 0;

    while ((match = _offsetTagRegex.firstMatch(text)) != null) {
      final matchString = match!.group(0)!;
      final offsetTag = matchString.substring(3, matchString.length - 3);
      final nextCharOffset = text.indexOf(_nonWhitespaceRegex, match.end);
      offsetTags[offsetTag] = nextCharOffset + offsetCounter;
      text = text.substring(match.end);
      offsetCounter += match.end;
    }
    return offsetTags;
  }

  Map<String, int> _generateLineTags() {
    final lines =
        io.File.fromUri(io.Platform.script.resolve(script)).readAsLinesSync();
    final lineTags = <String, int>{};
    int lineNum = 1;
    for (final line in lines) {
      if (_lineEndTagRegex.firstMatch(line) case final match?) {
        final lineTag = match.group(0)!.substring(3);
        lineTags[lineTag] = lineNum;
      } else if (_lineAnyTagRegex.firstMatch(line) case final match?) {
        final matchString = match.group(0)!;
        final lineTag = matchString.substring(3, matchString.length - 3);
        lineTags[lineTag] = lineNum;
      }
      lineNum++;
    }
    return lineTags;
  }

  int lineForRegExp(RegExp regExp) {
    final lines =
        io.File.fromUri(io.Platform.script.resolve(script)).readAsLinesSync();
    int lineNum = 1;
    for (final line in lines) {
      if (regExp.hasMatch(line)) {
        return lineNum;
      }
      lineNum++;
    }
    throw 'RegExp $regExp not found in $script';
  }

  int lineForTag(String lineTag) {
    final line = _lineTags[lineTag];
    if (line == null) {
      throw 'Line tag $lineTag not found in $script';
    }
    return line;
  }

  int offsetForTag(String offsetTag) {
    final offset = _offsetTags[offsetTag];
    if (offset == null) {
      throw 'Offset tag $offsetTag not found in $script';
    }
    return offset;
  }
}

typedef IsolateTest = Future<void> Function(
  VmService service,
  IsolateRef isolate,
);
typedef IsolateTestWithParser = Future<void> Function(
  VmService service,
  IsolateRef isolate,
  TestScriptParser scriptParser,
);
typedef VMTest = Future<void> Function(VmService service);
typedef VMTestWithParser = Future<void> Function(
    VmService service, TestScriptParser scriptParser);

Future<void> smartNext(VmService service, IsolateRef isolateRef) async {
  print('smartNext');
  final isolate = await service.getIsolate(isolateRef.id!);
  final Event event = isolate.pauseEvent!;
  if (event.kind == EventKind.kPauseBreakpoint) {
    // TODO(bkonyi): remove needless refetching of isolate object.
    if (event.atAsyncSuspension ?? false) {
      return asyncNext(service, isolateRef);
    } else {
      return syncNext(service, isolateRef);
    }
  } else {
    throw 'The program is already running';
  }
}

Future<void> asyncNext(VmService service, IsolateRef isolateRef) async {
  print('asyncNext');
  final id = isolateRef.id!;
  final isolate = await service.getIsolate(id);
  final event = isolate.pauseEvent!;
  if (event.kind == EventKind.kPauseBreakpoint) {
    final dynamic event = isolate.pauseEvent;
    if (!event.atAsyncSuspension) {
      throw 'No async continuation at this location';
    } else {
      await service.resume(id, step: 'OverAsyncSuspension');
    }
  } else {
    throw 'The program is already running';
  }
}

Future<void> syncNext(VmService service, IsolateRef isolateRef) async {
  print('syncNext');
  final id = isolateRef.id!;
  final isolate = await service.getIsolate(id);
  final event = isolate.pauseEvent!;
  if (event.kind == EventKind.kPauseBreakpoint) {
    await service.resume(id, step: 'Over');
  } else {
    throw 'The program is already running';
  }
}

// WARNING: interleaving calls based on hasPausedFor using Future.wait() may
// cause the debug stream to be cancelled after one of the checks completes.
// If another check is waiting on an event, it will no longer be notified of
// the event, causing the test to hang.
Future<void> hasPausedFor(
  VmService service,
  IsolateRef isolateRef,
  String kind,
) async {
  final completer = Completer<void>();
  late StreamSubscription<Event> subscription;
  bool completed = false;

  // Synchronously guard the entry to complete() before any async yields to
  // prevent concurrent execution paths (e.g., the stream listener and
  // getIsolate fallback) from double-completing it and throwing a StateError.
  Future<void> complete() async {
    if (completed) return;
    completed = true;
    try {
      await subscription.cancel();
      await _unsubscribeDebugStream(service);
    } catch (_) {}
    completer.complete();
  }

  subscription = service.onDebugEvent.listen((event) {
    if ((isolateRef.id == event.isolate!.id) && (event.kind == kind)) {
      unawaited(complete());
    }
  });

  await _subscribeDebugStream(service);

  // Pause may have happened before we subscribed.
  final id = isolateRef.id!;
  final isolate = await service.getIsolate(id);
  final event = isolate.pauseEvent!;
  if (event.kind == kind) {
    await complete();
  }
  return completer.future; // Will complete when breakpoint hit.
}

// WARNING: interleaving calls based on hasPausedFor using Future.wait() may
// cause the debug stream to be cancelled after one of the checks completes.
// If another check is waiting on an event, it will no longer be notified of
// the event, causing the test to hang.
Future<void> hasStoppedAtBreakpoint(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseBreakpoint);
}

// WARNING: interleaving calls based on hasPausedFor using Future.wait() may
// cause the debug stream to be cancelled after one of the checks completes.
// If another check is waiting on an event, it will no longer be notified of
// the event, causing the test to hang.
Future<void> hasStoppedPostRequest(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPausePostRequest);
}

// WARNING: interleaving calls based on hasPausedFor using Future.wait() may
// cause the debug stream to be cancelled after one of the checks completes.
// If another check is waiting on an event, it will no longer be notified of
// the event, causing the test to hang.
Future<void> hasStoppedWithUnhandledException(
  VmService service,
  IsolateRef isolate,
) {
  return hasPausedFor(service, isolate, EventKind.kPauseException);
}

// WARNING: interleaving calls based on hasPausedFor using Future.wait() may
// cause the debug stream to be cancelled after one of the checks completes.
// If another check is waiting on an event, it will no longer be notified of
// the event, causing the test to hang.
Future<void> hasStoppedAtExit(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseExit);
}

// WARNING: interleaving calls based on hasPausedFor using Future.wait() may
// cause the debug stream to be cancelled after one of the checks completes.
// If another check is waiting on an event, it will no longer be notified of
// the event, causing the test to hang.
Future<void> hasPausedAtStart(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseStart);
}

Future<void> markDartColonLibrariesDebuggable(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final requests = <Future>[];
  for (final libRef in isolate.libraries!) {
    final lib = await service.getObject(isolateId, libRef.id!) as Library;
    if (lib.uri!.startsWith('dart:') && !lib.uri!.startsWith('dart:_')) {
      requests.add(service.setLibraryDebuggable(isolateId, lib.id!, true));
    }
  }
  await Future.wait(requests);
}

IsolateTest setBreakpointAtUriAndLine(String uri, int line) {
  return (VmService service, IsolateRef isolateRef) async {
    print('Setting breakpoint for line $line in $uri');
    final Breakpoint bpt = await service.addBreakpointWithScriptUri(
      isolateRef.id!,
      uri,
      line,
    );
    print('Breakpoint is $bpt');
    expect(bpt, isNotNull);
  };
}

IsolateTest setBreakpointAtUriLineColumn(String uri, int line, int column) {
  return (VmService service, IsolateRef isolateRef) async {
    print('Setting breakpoint for line $line column $column');
    final Breakpoint bpt = await service
        .addBreakpointWithScriptUri(isolateRef.id!, uri, line, column: column);
    print('Breakpoint is $bpt');
    expect(bpt, isNotNull);
  };
}

extension BreakpointLocation on Breakpoint {
  Future<(String uri, (int line, int column))> getLocation(
    VmService service,
    IsolateRef isolateRef,
  ) async {
    if (location?.tokenPos == null) {
      return ('<unknown>', (-1, -1));
    }

    final script = (await service.getObject(
      isolateRef.id!,
      location!.script!.id!,
    )) as Script;
    return (
      script.uri!,
      (
        script.getLineNumberFromTokenPos(location!.tokenPos!) ?? -1,
        script.getColumnNumberFromTokenPos(location!.tokenPos!) ?? -1,
      ),
    );
  }
}

extension FrameLocation on Frame {
  Future<(String uri, (int line, int column))> getLocation(
    VmService service,
    IsolateRef isolateRef,
  ) async {
    if (location?.tokenPos == null) {
      return ('<unknown>', (-1, -1));
    }

    final script = (await service.getObject(
      isolateRef.id!,
      location!.script!.id!,
    )) as Script;
    return (
      script.uri!,
      (
        script.getLineNumberFromTokenPos(location!.tokenPos!) ?? -1,
        script.getColumnNumberFromTokenPos(location!.tokenPos!) ?? -1,
      ),
    );
  }
}

Future<String> formatFrames(
  VmService service,
  IsolateRef isolateRef,
  List<Frame> frames,
) async {
  final sb = StringBuffer();
  for (Frame f in frames) {
    sb.write(' $f');
    if (f.function case final funcRef?) {
      sb.write(' ');
      sb.write(await qualifiedFunctionName(service, isolateRef, funcRef));
    }
    if (f.location != null) {
      final (uri, (lineNo)) = await f.getLocation(service, isolateRef);
      sb.write(' $uri:$lineNo');
    }
    sb.writeln();
  }
  return sb.toString();
}

Future<String> formatStack(
  VmService service,
  IsolateRef isolateRef,
  Stack stack,
) async {
  final sb = StringBuffer();
  sb.write('Full stack trace:\n');
  sb.writeln(await formatFrames(service, isolateRef, stack.frames!));
  if (stack.asyncCausalFrames case final asyncFrames?) {
    sb.write('\nFull async stack trace:\n');
    sb.writeln(await formatFrames(service, isolateRef, asyncFrames));
  }
  return sb.toString();
}

/// If column is [null], this function checks that the isolate under test is
/// currently paused at line [line]. Otherwise, this function checks that the
/// isolate under test is currently paused at the location specified by [line]
/// and [column].
IsolateTest stoppedAtLineColumn({required int line, int? column}) {
  return (VmService service, IsolateRef isolateRef) async {
    if (column == null) {
      print('Checking we are at line $line');
    } else {
      print('Checking we are at $line:$column');
    }

    // Make sure that the isolate has stopped.
    final id = isolateRef.id!;
    final isolate = await service.getIsolate(id);
    final event = isolate.pauseEvent!;
    expect(event.kind != EventKind.kResume, isTrue);

    final stack = await service.getStack(id);

    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));

    final top = frames[0];
    final (_, (actualLine, actualColumn)) = await top.getLocation(
      service,
      isolateRef,
    );
    if (actualLine != line) {
      final sb = StringBuffer();
      sb.writeln(
        'Expected to be at line $line but actually at line $actualLine',
      );
      sb.writeln(await formatStack(service, isolateRef, stack));
      throw sb.toString();
    } else if (column != null && actualColumn != column) {
      final sb = StringBuffer();
      sb.writeln(
        'Expected to be at $line:$column but actually at $line:$actualColumn',
      );
      sb.writeln(await formatStack(service, isolateRef, stack));
      throw sb.toString();
    } else {
      print('Program is stopped at $actualLine:$actualColumn');
    }
  };
}

IsolateTest stoppedAtLine(int line) {
  return stoppedAtLineColumn(line: line);
}

Future<void> resumeIsolate(VmService service, IsolateRef isolate) async {
  Completer<void>? completer = Completer<void>();
  // Capture the future synchronously before any async yields or nullification
  // to ensure the caller always awaits the actual completion of the cleanup
  // tasks.
  final future = completer.future;
  late StreamSubscription<Event> subscription;
  bool cancelStreamAfterResume = false;

  // Synchronously nullify the completer before any async yields to prevent
  // concurrent execution paths (e.g., multiple stream events) from
  // double-completing it and throwing a StateError.
  Future<void> complete() async {
    if (completer != null) {
      final c = completer!;
      completer = null; // Synchronously set to null
      if (cancelStreamAfterResume) {
        await _unsubscribeDebugStream(service);
      }
      await subscription.cancel();
      c.complete();
    }
  }

  subscription = service.onDebugEvent.listen((event) {
    if (event.kind == EventKind.kResume && event.isolate?.id == isolate.id) {
      complete();
    }
  });
  cancelStreamAfterResume = await _subscribeDebugStream(service);
  await service.resume(isolate.id!);
  return future;
}

Future<bool> _subscribeDebugStream(VmService service) async {
  try {
    await service.streamListen(EventStreams.kDebug);
    return true;
  } catch (_) {
    /* swallow exception */
    return false;
  }
}

Future<void> _unsubscribeDebugStream(VmService service) async {
  try {
    await service.streamCancel(EventStreams.kDebug);
  } catch (_) {
    /* swallow exception */
  }
}

Future<void> resumeAndAwaitEvent(
  VmService service,
  IsolateRef isolateRef,
  String streamId,
  Function(Event) onEvent,
) async {
  final completer = Completer<void>();
  late final StreamSubscription sub;
  sub = service.onEvent(streamId).listen((event) async {
    await onEvent(event);
    await sub.cancel();
    await service.streamCancel(streamId);
    completer.complete();
  });

  await service.streamListen(streamId);
  await service.resume(isolateRef.id!);
  return completer.future;
}

IsolateTest resumeIsolateAndAwaitEvent(
  String streamId,
  Function(Event) onEvent,
) {
  return (VmService service, IsolateRef isolate) async =>
      resumeAndAwaitEvent(service, isolate, streamId, onEvent);
}

Future<void> stepOver(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id!, step: 'Over');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

Future<void> stepInto(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id!, step: 'Into');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

Future<void> stepOut(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id!, step: 'Out');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

IsolateTest resumeProgramRecordingStops(
  List<String> recordStops,
  bool includeCaller,
) {
  return (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseBreakpoint) {
        final stack = await service.getStack(isolateRef.id!);
        expect(stack.frames!.length, greaterThanOrEqualTo(2));

        String brokeAt = await _locationToString(
          service,
          isolateRef,
          stack.frames![0],
        );
        if (includeCaller) {
          brokeAt =
              '$brokeAt (${await _locationToString(service, isolateRef, stack.frames![1])})';
        }
        recordStops.add(brokeAt);
        await service.resume(isolateRef.id!);
      } else if (event.kind == EventKind.kPauseExit) {
        await subscription.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });

    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateRef.id!);
    return completer.future;
  };
}

Future<String> _locationToString(
  VmService service,
  IsolateRef isolateRef,
  Frame frame,
) async {
  final buffer = StringBuffer();
  final location = frame.location!;
  final script =
      await service.getObject(isolateRef.id!, location.script!.id!) as Script;
  final scriptName = p.basename(script.uri!);
  buffer.write(scriptName);
  final tokenPos = location.tokenPos!;
  final line = script.getLineNumberFromTokenPos(tokenPos);
  if (line != null) {
    buffer.write(':$line');
    final column = script.getColumnNumberFromTokenPos(tokenPos);
    if (column != null) {
      buffer.write(':$column');
    }
  }
  return buffer.toString();
}

IsolateTest runStepThroughProgramRecordingStops(List<String> recordStops) {
  return (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseBreakpoint) {
        final isolate = await service.getIsolate(isolateRef.id!);
        final frame = isolate.pauseEvent!.topFrame!;
        recordStops.add(await _locationToString(service, isolateRef, frame));
        if (event.atAsyncSuspension ?? false) {
          await service.resume(
            isolateRef.id!,
            step: StepOption.kOverAsyncSuspension,
          );
        } else {
          await service.resume(isolateRef.id!, step: StepOption.kOver);
        }
      } else if (event.kind == EventKind.kPauseExit) {
        await subscription.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateRef.id!);
    return completer.future;
  };
}

IsolateTest runStepIntoThroughProgramRecordingStops(List<String> recordStops) {
  return (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseBreakpoint) {
        final isolate = await service.getIsolate(isolateRef.id!);
        final frame = isolate.pauseEvent!.topFrame!;
        recordStops.add(await _locationToString(service, isolateRef, frame));
        await service.resume(isolateRef.id!, step: StepOption.kInto);
      } else if (event.kind == EventKind.kPauseExit) {
        await subscription.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateRef.id!);
    return completer.future;
  };
}

IsolateTest checkRecordedStops(
  List<String> recordStops,
  String goldenFileName, {
  bool removeDuplicates = false,
  bool debugPrint = false,
  String? debugPrintFile,
  int? debugPrintLine,
  bool updateGoldens = false,
}) {
  String formatLine(String line) {
    String output = line;
    if (debugPrintFile != null && debugPrintLine != null) {
      final int firstColon = line.indexOf(':');
      final int lastColon = line.lastIndexOf(':');
      if (firstColon > 0 && lastColon > 0) {
        final int lineNumber = int.parse(
          line.substring(firstColon + 1, lastColon),
        );
        final int relativeLineNumber = lineNumber - debugPrintLine;
        final columnNumber = line.substring(lastColon + 1);
        final file = line.substring(0, firstColon);
        if (file == debugPrintFile) {
          output = '\$file:\${LINE+$relativeLineNumber}:$columnNumber';
        }
      }
    }
    return output;
  }

  return (VmService service, IsolateRef isolate) async {
    var updatedStops =
        recordStops.takeWhile((s) => !s.contains('test_helper.dart')).toList();
    if (debugPrint) {
      for (int i = 0; i < updatedStops.length; i++) {
        final line = updatedStops[i];
        final output = formatLine(line);
        final String comma = i == updatedStops.length - 1 ? '' : ',';
        print("'$output'$comma");
      }
    }
    if (removeDuplicates) {
      updatedStops = removeAdjacentDuplicates(updatedStops);
    }

    print('Loading golden file from: $goldenFileName');
    final goldenFile = io.File(goldenFileName);

    if (updateGoldens) {
      goldenFile.writeAsStringSync(
        '// This file is generated by running the associated test with '
        '--update-goldens. Do not edit this file directly.\n\n'
        '${updatedStops.join('\n')}\n',
      );
      print('Updated golden file: ${goldenFile.path}');
      return;
    }

    if (!goldenFile.existsSync()) {
      throw 'Golden file not found: ${goldenFile.path}. Run with '
          '--update-goldens to generate.';
    }

    // Skip the first 3 lines which are comments.
    List<String> expectedStops = goldenFile.readAsLinesSync().skip(3).toList();
    if (removeDuplicates) {
      expectedStops = removeAdjacentDuplicates(expectedStops);
    }

    int i = 0;
    int j = 0;
    while (i < updatedStops.length && j < expectedStops.length) {
      if (updatedStops[i] != expectedStops[j]) {
        int k = i + 1;
        while (k < updatedStops.length && updatedStops[k] != expectedStops[j]) {
          k++;
        }
        if (k < updatedStops.length) {
          if (debugPrint) {
            print('Skipping recorded stops [$i, $k)');
          }
          i = k;
        } else {
          expect(
            formatLine(updatedStops[i]),
            formatLine(expectedStops[j]),
            reason: 'Recorded stop $i does not match expected stop $j. '
                'To regenerate golden, run with test with --update-goldens.',
          );
        }
      }
      if (debugPrint) {
        print(
          'Recorded stop $i matches expected stop $j: '
          '${formatLine(updatedStops[i])}',
        );
      }
      i++;
      j++;
    }

    expect(
      updatedStops.length >= expectedStops.length,
      true,
      reason: 'Expects at least ${expectedStops.length} breaks, '
          'got ${updatedStops.length}. To regenerate golden, run with test '
          'with --update-goldens.',
    );
  };
}

List<String> removeAdjacentDuplicates(List<String> fromList) {
  final List<String> result = <String>[];
  String? latestLine;
  for (String s in fromList) {
    if (s == latestLine) continue;
    latestLine = s;
    result.add(s);
  }
  return result;
}

typedef ServiceExtensionHandler = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> cb,
);

/// Registers a service extension and returns the actual service name used to
/// invoke the service.
Future<String> registerServiceHelper(
  VmService primaryClient,
  VmService serviceRegisterClient,
  String serviceName,
  ServiceExtensionHandler callback,
) async {
  final serviceNameCompleter = Completer<String>();
  late final StreamSubscription sub;
  sub = primaryClient.onServiceEvent.listen((event) {
    if (event.kind == EventKind.kServiceRegistered &&
        event.method!.endsWith(serviceName)) {
      serviceNameCompleter.complete(event.method!);
      sub.cancel();
    }
  });
  // TODO(bkonyi): if we end up in a situation where this call throws due to a
  // prior subscription to the Service stream, we should do something similar
  // to _subscribeDebugStream in this method.
  await primaryClient.streamListen(EventStreams.kService);

  // Register the service.
  serviceRegisterClient.registerServiceCallback(serviceName, callback);
  await serviceRegisterClient.registerService(serviceName, serviceName);

  // Wait for the service registered event on the non-registering client to get
  // the actual service name.
  final actualServiceName = await serviceNameCompleter.future;
  print("Service '$serviceName' registered as '$actualServiceName'");
  await primaryClient.streamCancel(EventStreams.kService);
  return actualServiceName;
}

Future<void> evaluateInFrameAndExpect(
  VmService service,
  String isolateId,
  String expression,
  String expected, {
  Map<String, String>? scope,
  String? kind,
  int topFrame = 0,
}) async {
  final result = await service.evaluateInFrame(
    isolateId,
    topFrame,
    expression,
    scope: scope,
  ) as InstanceRef;
  expect(result.valueAsString, expected);
  if (kind != null) {
    expect(result.kind!, kind);
  }
}

Future<void> evaluateAndExpect(
  VmService service,
  String isolateId,
  String targetId,
  String expression,
  String expected, {
  Map<String, String>? scope,
  String? kind,
}) async {
  final result = await service.evaluate(
    isolateId,
    targetId,
    expression,
    scope: scope,
  ) as InstanceRef;
  expect(result.valueAsString, expected);
  if (kind != null) {
    expect(result.kind!, kind);
  }
}

Future<HeapSnapshotGraph> fetchHeapSnapshot(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final completer = Completer<void>();
  late final StreamSubscription sub;
  final data = <ByteData>[];
  sub = service.onHeapSnapshotEvent.listen((event) async {
    data.add(event.data!);
    if (event.last == true) {
      await sub.cancel();
      await service.streamCancel(EventStreams.kHeapSnapshot);
      completer.complete();
    }
  });
  await service.streamListen(EventStreams.kHeapSnapshot);
  await service.requestHeapSnapshot(isolateId);
  await completer.future;
  return HeapSnapshotGraph.fromChunks(data);
}

IsolateTest reloadSources({bool pause = false}) {
  return (VmService service, IsolateRef isolateRef) async {
    await service.reloadSources(isolateRef.id!, pause: pause);
  };
}

IsolateTest hasLocalVarInTopStackFrame(String varName) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Checking we have variable '$varName' in the top frame");

    final isolateId = isolateRef.id!;
    // Make sure that the isolate has stopped.
    final isolate = await service.getIsolate(isolateId);
    expect(isolate.pauseEvent, isNotNull);
    expect(isolate.pauseEvent!.kind, isNot(EventKind.kResume));

    final stack = await service.getStack(isolateId);
    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));

    final top = frames[0];
    final vars = top.vars!;
    for (final variable in vars) {
      if (variable.name == varName) {
        return;
      }
    }
    final sb = StringBuffer();
    sb.write('Expected to find $varName in top awaiter stack frame, found ');
    if (vars.isEmpty) {
      sb.writeln('no variables');
    } else {
      sb.writeln('these instead:');
      for (var variable in vars) {
        sb.writeln('\t${variable.name}');
      }
    }
    throw sb.toString();
  };
}

IsolateTest stoppedInFunction(String functionName) {
  return (VmService service, IsolateRef isolateRef) async {
    print('Checking we are in function: $functionName');

    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);

    final frames = stack.frames!;
    expect(frames, isNotEmpty);

    final topFrame = frames[0];
    final function =
        await service.getObject(isolateId, topFrame.function!.id!) as Func;
    final name = function.name!;
    if (name != functionName) {
      final sb = StringBuffer();
      sb.writeln(
        'Expected to be in function $functionName but '
        'actually in function $name',
      );
      sb.writeln(await formatStack(service, isolateRef, stack));

      throw sb.toString();
    } else {
      print('Program is stopped in function: $functionName');
    }
  };
}

Future<String> qualifiedFunctionName(
  VmService service,
  IsolateRef isolate,
  FuncRef func,
) async {
  final funcName = func.name ?? '<unknown>';
  switch (func.owner) {
    case final FuncRef parentFuncRef:
      final parentFuncName = await qualifiedFunctionName(
        service,
        isolate,
        parentFuncRef,
      );
      return '$parentFuncName.$funcName';

    case final ClassRef parentClass:
      return '${parentClass.name!}.$funcName';

    case _:
      return funcName;
  }
}

Future<void> expectFrame(
  VmService service,
  IsolateRef isolate,
  Frame frame, {
  String kind = 'Regular',
  String? functionName,
  int? line,
}) async {
  expect(frame.kind, equals(kind));
  if (functionName != null) {
    expect(
      await qualifiedFunctionName(service, isolate, frame.function!),
      equals(functionName),
    );
  }
  if (line != null) {
    expect(frame.location, isNotNull);

    final script = await service.getObject(
      isolate.id!,
      frame.location!.script!.id!,
    ) as Script;
    expect(
      script.getLineNumberFromTokenPos(frame.location!.tokenPos!),
      equals(line),
    );
  }
}

Future<String> getCurrentExceptionAsString(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  final event = isolate.pauseEvent!;
  final exception =
      await service.getObject(isolateRef.id!, event.exception!.id!) as Instance;
  return exception.valueAsString!;
}

typedef ExpectedFrame = ({String? functionName, int? line});
const ExpectedFrame asyncGap = (functionName: null, line: null);

IsolateTest resumePastUnhandledException(String exceptionAsString) {
  return (service, isolateRef) async {
    do {
      await resumeIsolate(service, isolateRef);
      await hasStoppedWithUnhandledException(service, isolateRef);
    } while (await getCurrentExceptionAsString(service, isolateRef) ==
        exceptionAsString);
  };
}

IsolateTest expectUnhandledExceptionWithFrames({
  List<ExpectedFrame>? expectedFrames,
  String? exceptionAsString,
}) {
  return (VmService service, IsolateRef isolateRef) async {
    await hasStoppedWithUnhandledException(service, isolateRef);
    if (exceptionAsString != null) {
      expect(
        await getCurrentExceptionAsString(service, isolateRef),
        equals(exceptionAsString),
      );
    }

    if (expectedFrames == null) {
      return;
    }

    final stack = await service.getStack(isolateRef.id!);

    final frames = stack.asyncCausalFrames!;
    var currentKind = 'Regular';
    for (var i = 0; i < expectedFrames.length; i++) {
      final expected = expectedFrames[i];
      final got = frames[i];
      await expectFrame(
        service,
        isolateRef,
        got,
        kind: expected == asyncGap ? 'AsyncSuspensionMarker' : currentKind,
        functionName: expected.functionName,
        line: expected.line,
      );
      if (expected == asyncGap) {
        currentKind = 'AsyncCausal';
      }
    }
  };
}

/// This helper does 3 things:
/// 1) makes sure it's at the expected frame ([topFrameName]).
/// 2) checks that the expected variables are available (by name)
///    ([availableVariables]).
/// 3) Evaluates the given expression(s) and checks their (valueAsString) result
///    ([evaluations]).
IsolateTest testExpressionEvaluationAndAvailableVariables(
  String topFrameName,
  List<String> availableVariables,
  List<(String evaluate, String evaluationResult)> evaluations,
) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    expect(stack.frames![0].function!.name, topFrameName);

    // Check variables.
    expect(
      (stack.frames![0].vars ?? []).map((v) => v.name).toList(),
      equals(availableVariables),
    );

    // Evaluate.
    for (final (expression, expectedResult) in evaluations) {
      final result = await service.evaluateInFrame(
        isolateId,
        /* frame = */ 0,
        expression,
      ) as InstanceRef;
      print(result.valueAsString);
      expect(result.valueAsString, equals(expectedResult));
    }
  };
}

Map<String, String> mapFromListOfDebugAnnotations(
  List<DebugAnnotation> debugAnnotations,
) {
  return HashMap.fromEntries(
    debugAnnotations.map((a) {
      if (a.hasStringValue()) {
        return MapEntry(a.name, a.stringValue);
      } else if (a.hasLegacyJsonValue()) {
        return MapEntry(a.name, a.legacyJsonValue);
      } else {
        throw 'We should not be writing annotations without values';
      }
    }),
  );
}

int computeTimeOriginNanos(List<TracePacket> packets) {
  final packetsWithPerfSamples =
      packets.where((packet) => packet.hasPerfSample()).toList();
  if (packetsWithPerfSamples.isEmpty) {
    return 0;
  }
  int smallest = packetsWithPerfSamples.first.timestamp.toInt();
  for (int i = 0; i < packetsWithPerfSamples.length; i++) {
    if (packetsWithPerfSamples[i].timestamp < smallest) {
      smallest = packetsWithPerfSamples[i].timestamp.toInt();
    }
  }
  return smallest;
}

int computeTimeExtentNanos(List<TracePacket> packets, int timeOrigin) {
  final packetsWithPerfSamples =
      packets.where((packet) => packet.hasPerfSample()).toList();
  if (packetsWithPerfSamples.isEmpty) {
    return 0;
  }
  int largestExtent = packetsWithPerfSamples[0].timestamp.toInt() - timeOrigin;
  for (var i = 0; i < packetsWithPerfSamples.length; i++) {
    final int duration =
        packetsWithPerfSamples[i].timestamp.toInt() - timeOrigin;
    if (duration > largestExtent) {
      largestExtent = duration;
    }
  }
  return largestExtent;
}

Iterable<PerfSample> extractPerfSamplesFromTracePackets(
  List<TracePacket> packets,
) {
  return packets
      .where((packet) => packet.hasPerfSample())
      .map((packet) => packet.perfSample);
}
