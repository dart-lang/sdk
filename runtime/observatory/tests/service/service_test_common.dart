// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_test_common;

import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_common.dart';
import 'package:unittest/unittest.dart';

typedef Future IsolateTest(Isolate isolate);
typedef Future VMTest(VM vm);

Map<String, StreamSubscription> streamSubscriptions = {};

Future subscribeToStream(VM vm, String streamName, onEvent) async {
  assert(streamSubscriptions[streamName] == null);

  Stream stream = await vm.getEventStream(streamName);
  StreamSubscription subscription = stream.listen(onEvent);
  streamSubscriptions[streamName] = subscription;
}

Future cancelStreamSubscription(String streamName) async {
  StreamSubscription subscription = streamSubscriptions[streamName];
  subscription.cancel();
  streamSubscriptions.remove(streamName);
}

Future smartNext(Isolate isolate) async {
  print('smartNext');
  if (isolate.status == M.IsolateStatus.paused) {
    var event = isolate.pauseEvent;
    if (event.atAsyncSuspension) {
      return asyncNext(isolate);
    } else {
      return syncNext(isolate);
    }
  } else {
    throw 'The program is already running';
  }
}

Future asyncNext(Isolate isolate) async {
  print('asyncNext');
  if (isolate.status == M.IsolateStatus.paused) {
    var event = isolate.pauseEvent;
    if (!event.atAsyncSuspension) {
      throw 'No async continuation at this location';
    } else {
      return isolate.stepOverAsyncSuspension();
    }
  } else {
    throw 'The program is already running';
  }
}

Future syncNext(Isolate isolate) async {
  print('syncNext');
  if (isolate.status == M.IsolateStatus.paused) {
    return isolate.stepOver();
  } else {
    throw 'The program is already running';
  }
}

Future asyncStepOver(Isolate isolate) async {
  final Completer pausedAtSyntheticBreakpoint = new Completer();
  StreamSubscription subscription;

  // Cancel the subscription.
  cancelSubscription() {
    if (subscription != null) {
      subscription.cancel();
      subscription = null;
    }
  }

  // Complete futures with with error.
  completeError(error) {
    if (!pausedAtSyntheticBreakpoint.isCompleted) {
      pausedAtSyntheticBreakpoint.completeError(error);
    }
  }

  // Subscribe to the debugger event stream.
  Stream stream;
  try {
    stream = await isolate.vm.getEventStream(VM.kDebugStream);
  } catch (e) {
    completeError(e);
    return pausedAtSyntheticBreakpoint.future;
  }

  Breakpoint syntheticBreakpoint;

  subscription = stream.listen((ServiceEvent event) async {
    // Synthetic breakpoint add event. This is the first event we will
    // receive.
    bool isAdd = (event.kind == ServiceEvent.kBreakpointAdded) &&
                 (event.breakpoint.isSyntheticAsyncContinuation) &&
                 (event.owner == isolate);
    // Resume after synthetic breakpoint added. This is the second event
    // we will recieve.
    bool isResume = (event.kind == ServiceEvent.kResume) &&
                    (syntheticBreakpoint != null) &&
                    (event.owner == isolate);
    // Paused at synthetic breakpoint. This is the third event we will
    // receive.
    bool isPaused = (event.kind == ServiceEvent.kPauseBreakpoint) &&
                    (syntheticBreakpoint != null) &&
                    (event.breakpoint == syntheticBreakpoint);
    if (isAdd) {
      syntheticBreakpoint = event.breakpoint;
    } else if (isResume) {
    } else if (isPaused) {
      pausedAtSyntheticBreakpoint.complete(isolate);
      syntheticBreakpoint = null;
      cancelSubscription();
    }
  });

  // Issue the step OverAwait command.
  try {
    await isolate.stepOverAsyncSuspension();
  } catch (e) {
    // This can fail when another client issued the same resume command
    // or another client has moved the isolate forward.
    cancelSubscription();
    completeError(e);
  }

  return pausedAtSyntheticBreakpoint.future;
}

bool isEventOfKind(M.Event event, String kind) {
  switch (kind) {
    case ServiceEvent.kPauseBreakpoint:
      return event is M.PauseBreakpointEvent;
    case ServiceEvent.kPauseException:
      return event is M.PauseExceptionEvent;
    case ServiceEvent.kPauseExit:
      return event is M.PauseExitEvent;
    case ServiceEvent.kPauseStart:
      return event is M.PauseStartEvent;
    case ServiceEvent.kPausePostRequest:
      return event is M.PausePostRequestEvent;
    default:
      return false;
  }
}

Future<Isolate> hasPausedFor(Isolate isolate, String kind) {
  // Set up a listener to wait for breakpoint events.
  Completer completer = new Completer();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
        if ((isolate == event.isolate) && (event.kind == kind)) {
          if (completer != null) {
            // Reload to update isolate.pauseEvent.
            print('Paused with $kind');
            subscription.cancel();
            completer.complete(isolate.reload());
            completer = null;
          }
        }
    });

    // Pause may have happened before we subscribed.
    isolate.reload().then((_) {
      if ((isolate.pauseEvent != null) &&
         isEventOfKind(isolate.pauseEvent, kind)) {
        // Already waiting at a breakpoint.
        if (completer != null) {
          print('Paused with $kind');
          subscription.cancel();
          completer.complete(isolate);
          completer = null;
        }
      }
    });
  });

  return completer.future;  // Will complete when breakpoint hit.
}

Future<Isolate> hasStoppedAtBreakpoint(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPauseBreakpoint);
}

Future<Isolate> hasStoppedPostRequest(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPausePostRequest);
}

Future<Isolate> hasStoppedWithUnhandledException(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPauseException);
}

Future<Isolate> hasStoppedAtExit(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPauseExit);
}

Future<Isolate> hasPausedAtStart(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPauseStart);
}

IsolateTest reloadSources([bool pause = false]) {
    return (Isolate isolate) async {
      Map<String, dynamic> params = <String, dynamic>{ };
      if (pause == true) {
        params['pause'] = pause;
      }
      return isolate.invokeRpc('reloadSources', params);
    };
}

// Currying is your friend.
IsolateTest setBreakpointAtLine(int line) {
  return (Isolate isolate) async {
    print("Setting breakpoint for line $line");
    Library lib = await isolate.rootLibrary.load();
    Script script = lib.scripts.single;

    Breakpoint bpt = await isolate.addBreakpoint(script, line);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
    expect(bpt is Breakpoint, isTrue);
  };
}

IsolateTest stoppedAtLine(int line) {
  return (Isolate isolate) async {
    print("Checking we are at line $line");

    // Make sure that the isolate has stopped.
    isolate.reload();
    expect(isolate.pauseEvent is! M.ResumeEvent, isTrue);

    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));

    List<Frame> frames = stack['frames'];
    expect(frames.length, greaterThanOrEqualTo(1));

    Frame top = frames[0];
    Script script = await top.location.script.load();
    int actualLine = script.tokenToLine(top.location.tokenPos);
    if (actualLine != line) {
      StringBuffer sb = new StringBuffer();
      sb.write("Expected to be at line $line but actually at line $actualLine");
      sb.write("\nFull stack trace:\n");
      for (Frame f in stack['frames']) {
        sb.write(" $f [${await f.location.getLine()}]\n");
      }
      throw sb.toString();
    } else {
      print('Program is stopped at line: $line');
    }
  };
}


IsolateTest stoppedInFunction(String functionName, {bool contains: false}) {
  return (Isolate isolate) async {
    print("Checking we are in function: $functionName");

    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));

    List<Frame> frames = stack['frames'];
    expect(frames.length, greaterThanOrEqualTo(1));

    Frame topFrame = stack['frames'][0];
    ServiceFunction function = await topFrame.function.load();
    final bool matches =
        contains ? function.name.contains(functionName) :
                     function.name == functionName;
    if (!matches) {
      StringBuffer sb = new StringBuffer();
      sb.write("Expected to be in function $functionName but "
               "actually in function ${function.name}");
      sb.write("\nFull stack trace:\n");
      for (Frame f in stack['frames']) {
        await f.function.load();
        await (f.function.dartOwner as ServiceObject).load();
        String name = f.function.name;
        String ownerName = (f.function.dartOwner as ServiceObject).name;
        sb.write(" $f [$name] [$ownerName]\n");
      }
      throw sb.toString();
    } else {
      print('Program is stopped in function: $functionName');
    }
  };
}


Future<Isolate> resumeIsolate(Isolate isolate) {
  Completer completer = new Completer();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
  });
  isolate.resume();
  return completer.future;
}


Future resumeAndAwaitEvent(Isolate isolate, stream, onEvent) async {
  Completer completer = new Completer();
  var sub;
  sub = await isolate.vm.listenEventStream(
    stream,
    (ServiceEvent event) {
      var r = onEvent(event);
      if (r is! Future) {
        r = new Future.value(r);
      }
      r.then((x) => sub.cancel().then((_) {
        completer.complete();
      }));
    });
  await isolate.resume();
  return completer.future;
}

IsolateTest resumeIsolateAndAwaitEvent(stream, onEvent) {
  return (Isolate isolate) async =>
      resumeAndAwaitEvent(isolate, stream, onEvent);
}


Future<Isolate> stepOver(Isolate isolate) async {
  await isolate.stepOver();
  return hasStoppedAtBreakpoint(isolate);
}

Future<Isolate> stepInto(Isolate isolate) async {
  await isolate.stepInto();
  return hasStoppedAtBreakpoint(isolate);
}

Future<Isolate> stepOut(Isolate isolate) async {
  await isolate.stepOut();
  return hasStoppedAtBreakpoint(isolate);
}


Future isolateIsRunning(Isolate isolate) async {
  await isolate.reload();
  expect(isolate.running, true);
}

Future<Class> getClassFromRootLib(Isolate isolate, String className) async {
  Library rootLib = await isolate.rootLibrary.load();
  for (var i = 0; i < rootLib.classes.length; i++) {
    Class cls = rootLib.classes[i];
    if (cls.name == className) {
      return cls;
    }
  }
  return null;
}


Future<Instance> rootLibraryFieldValue(Isolate isolate,
                                       String fieldName) async {
  Library rootLib = await isolate.rootLibrary.load();
  Field field = rootLib.variables.singleWhere((v) => v.name == fieldName);
  await field.load();
  Instance value = field.staticValue;
  await value.load();
  return value;
}
