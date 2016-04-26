// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_test_common;

import 'dart:async';
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


Future<Isolate> hasPausedFor(Isolate isolate, String kind) {
  // Set up a listener to wait for breakpoint events.
  Completer completer = new Completer();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
        if (event.kind == kind) {
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
         (isolate.pauseEvent.kind == kind)) {
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

Future<Isolate> hasStoppedWithUnhandledException(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPauseException);
}

Future<Isolate> hasPausedAtStart(Isolate isolate) {
  return hasPausedFor(isolate, ServiceEvent.kPauseStart);
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

    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));

    List<Frame> frames = stack['frames'];
    expect(frames.length, greaterThanOrEqualTo(1));

    Frame top = frames[0];
    Script script = await top.location.script.load();
    int actualLine = script.tokenToLine(top.location.tokenPos);
    if (actualLine != line) {
      var sb = new StringBuffer();
      sb.write("Expected to be at line $line but actually at line $actualLine");
      sb.write("\nFull stack trace:\n");
      for (Frame f in stack['frames']) {
        sb.write(" $f [${await f.location.getLine()}]\n");
      }
      throw sb.toString();
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
