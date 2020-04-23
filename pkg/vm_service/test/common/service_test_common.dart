// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_test_common;

import 'dart:async';
import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

typedef IsolateTest = Future<void> Function(
    VmService service, IsolateRef isolate);
typedef VMTest = Future<void> Function(VmService service);

Future<void> smartNext(VmService service, IsolateRef isolateRef) async {
  print('smartNext');
  final isolate = await service.getIsolate(isolateRef.id);
  if ((isolate.pauseEvent != null) &&
      (isolate.pauseEvent.kind == EventKind.kPauseBreakpoint)) {
    Event event = isolate.pauseEvent;
    // TODO(bkonyi): remove needless refetching of isolate object.
    if (event?.atAsyncSuspension ?? false) {
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
  final isolate = await service.getIsolate(isolateRef.id);
  if ((isolate.pauseEvent != null) &&
      (isolate.pauseEvent.kind == EventKind.kPauseBreakpoint)) {
    dynamic event = isolate.pauseEvent;
    if (!event.atAsyncSuspension) {
      throw 'No async continuation at this location';
    } else {
      return service.resume(isolateRef.id, step: 'OverAsyncSuspension');
    }
  } else {
    throw 'The program is already running';
  }
}

Future<void> syncNext(VmService service, IsolateRef isolateRef) async {
  print('syncNext');
  final isolate = await service.getIsolate(isolateRef.id);
  if ((isolate.pauseEvent != null) &&
      (isolate.pauseEvent.kind == EventKind.kPauseBreakpoint)) {
    return service.resume(isolate.id, step: 'Over');
  } else {
    throw 'The program is already running';
  }
}

Future<void> hasPausedFor(
    VmService service, IsolateRef isolateRef, String kind) async {
  var completer = Completer();
  var subscription;
  subscription = service.onDebugEvent.listen((event) async {
    if ((isolateRef.id == event.isolate.id) && (event.kind == kind)) {
      if (completer != null) {
        try {
          await service.streamCancel(EventStreams.kDebug);
        } catch (_) {/* swallow exception */} finally {
          subscription.cancel();
          completer?.complete();
          completer = null;
        }
      }
    }
  });

  await _subscribeDebugStream(service);

  // Pause may have happened before we subscribed.
  final isolate = await service.getIsolate(isolateRef.id);
  if ((isolate.pauseEvent != null) && (isolate.pauseEvent.kind == kind)) {
    if (completer != null) {
      try {
        await service.streamCancel(EventStreams.kDebug);
      } catch (_) {/* swallow exception */} finally {
        subscription.cancel();
        completer?.complete();
      }
    }
  }
  return completer?.future; // Will complete when breakpoint hit.
}

Future<void> hasStoppedAtBreakpoint(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseBreakpoint);
}

Future<void> hasStoppedPostRequest(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPausePostRequest);
}

Future<void> hasStoppedWithUnhandledException(
    VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseException);
}

Future<void> hasStoppedAtExit(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseExit);
}

Future<void> hasPausedAtStart(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseStart);
}

// Currying is your friend.
IsolateTest setBreakpointAtLine(int line) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Setting breakpoint for line $line");
    final isolate = await service.getIsolate(isolateRef.id);
    final Library lib = await service.getObject(isolate.id, isolate.rootLib.id);
    final script = lib.scripts.first;

    Breakpoint bpt = await service.addBreakpoint(isolate.id, script.id, line);
    print("Breakpoint is $bpt");
  };
}

IsolateTest stoppedAtLine(int line) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Checking we are at line $line");

    // Make sure that the isolate has stopped.
    final isolate = await service.getIsolate(isolateRef.id);
    expect(isolate.pauseEvent.kind != EventKind.kResume, isTrue);

    final stack = await service.getStack(isolateRef.id);

    final frames = stack.frames;
    expect(frames.length, greaterThanOrEqualTo(1));

    final top = frames[0];
    final Script script =
        await service.getObject(isolate.id, top.location.script.id);
    int actualLine = script.getLineNumberFromTokenPos(top.location.tokenPos);
    if (actualLine != line) {
      print("Actual: $actualLine Line: $line");
      final sb = StringBuffer();
      sb.write("Expected to be at line $line but actually at line $actualLine");
      sb.write("\nFull stack trace:\n");
      for (Frame f in stack.frames) {
        sb.write(
            " $f [${script.getLineNumberFromTokenPos(f.location.tokenPos)}]\n");
      }
      throw sb.toString();
    } else {
      print('Program is stopped at line: $line');
    }
  };
}

Future<void> resumeIsolate(VmService service, IsolateRef isolate) async {
  Completer completer = Completer();
  var subscription;
  subscription = service.onDebugEvent.listen((event) async {
    if (event.kind == EventKind.kResume) {
      try {
        await service.streamCancel(EventStreams.kDebug);
      } catch (_) {/* swallow exception */} finally {
        subscription.cancel();
        completer.complete();
      }
    }
  });
  await service.streamListen(EventStreams.kDebug);
  await service.resume(isolate.id);
  return completer.future;
}

Future<void> _subscribeDebugStream(VmService service) async {
  try {
    await service.streamListen(EventStreams.kDebug);
  } catch (_) {
    /* swallow exception */
  }
}

Future<void> _unsubscribeDebugStream(VmService service) async {
  try {
    await service.streamCancel(EventStreams.kDebug);
  } catch (_) {
    /* swallow exception */
  }
}

Future<void> stepOver(VmService service, IsolateRef isolateRef) async {
  await service.streamListen(EventStreams.kDebug);
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id, step: 'Over');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

Future<void> stepInto(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id, step: 'Into');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

Future<void> stepOut(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id, step: 'Out');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}
