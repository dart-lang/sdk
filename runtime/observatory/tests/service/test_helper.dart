// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

bool _isWebSocketDisconnect(e) {
  return e is NetworkRpcException;
}

// This invocation should set up the state being tested.
const String _TESTEE_MODE_FLAG = "--testee-mode";

class _TestLauncher {
  Process process;
  final List<String> args;
  bool killedByTester = false;

  _TestLauncher() : args = ['--enable-vm-service:0',
                            Platform.script.toFilePath(),
                            _TESTEE_MODE_FLAG] {}

  Future<int> launch(bool pause_on_start,
                     bool pause_on_exit,
                     bool pause_on_unhandled_exceptions,
                     bool trace_service,
                     bool trace_compiler) {
    assert(pause_on_start != null);
    assert(pause_on_exit != null);
    assert(trace_service != null);
    // TODO(turnidge): I have temporarily turned on service tracing for
    // all tests to help diagnose flaky tests.
    trace_service = true;
    String dartExecutable = Platform.executable;
    var fullArgs = [];
    if (trace_service) {
      fullArgs.add('--trace-service');
      fullArgs.add('--trace-service-verbose');
    }
    if (trace_compiler) {
      fullArgs.add('--trace-compiler');
    }
    if (pause_on_start) {
      fullArgs.add('--pause-isolates-on-start');
    }
    if (pause_on_exit) {
      fullArgs.add('--pause-isolates-on-exit');
    }
    if (pause_on_unhandled_exceptions) {
      fullArgs.add('--pause-isolates-on-unhandled-exceptions');
    }
    fullArgs.addAll(Platform.executableArguments);
    fullArgs.addAll(args);
    print('** Launching $dartExecutable ${fullArgs.join(' ')}');
    return Process.start(dartExecutable, fullArgs).then((p) {

      Completer completer = new Completer();
      process = p;
      var portNumber;
      var blank;
      var first = true;
      process.stdout.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        if (line.startsWith('Observatory listening on http://')) {
          RegExp portExp = new RegExp(r"\d+.\d+.\d+.\d+:(\d+)");
          var port = portExp.firstMatch(line).group(1);
          portNumber = int.parse(port);
        }
        if (pause_on_start || line == '') {
          // Received blank line.
          blank = true;
        }
        if (portNumber != null && blank == true && first == true) {
          completer.complete(portNumber);
          // Stop repeat completions.
          first = false;
          print('** Signaled to run test queries on $portNumber');
        }
        print(line);
      });
      process.stderr.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        print(line);
      });
      process.exitCode.then((exitCode) {
        if ((exitCode != 0) && !killedByTester) {
          throw "Testee exited with $exitCode";
        }
        print("** Process exited");
      });
      return completer.future;
    });
  }

  void requestExit() {
    print('** Killing script');
    if (process.kill()) {
      killedByTester = true;
    }
  }
}

typedef Future IsolateTest(Isolate isolate);
typedef Future VMTest(VM vm);

/// Will be set to the http address of the VM's service protocol before
/// any tests are invoked.
String serviceHttpAddress;

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
Future runIsolateTests(List<String> mainArgs,
                       List<IsolateTest> tests,
                       {testeeBefore(),
                        void testeeConcurrent(),
                        bool pause_on_start: false,
                        bool pause_on_exit: false,
                        bool trace_service: false,
                        bool trace_compiler: false,
                        bool verbose_vm: false,
                        bool pause_on_unhandled_exceptions: false}) async {
  assert(!pause_on_start || testeeBefore == null);
  if (mainArgs.contains(_TESTEE_MODE_FLAG)) {
    if (!pause_on_start) {
      if (testeeBefore != null) {
        var result = testeeBefore();
        if (result is Future) {
          await result;
        }
      }
      print(''); // Print blank line to signal that we are ready.
    }
    if (testeeConcurrent != null) {
      testeeConcurrent();
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      stdin.first.then((_) => exit(0));
    }
  } else {
    var process = new _TestLauncher();
    process.launch(pause_on_start, pause_on_exit,
                   pause_on_unhandled_exceptions,
                   trace_service, trace_compiler).then((port) {
      if (mainArgs.contains("--gdb")) {
        port = 8181;
      }
      String addr = 'ws://localhost:$port/ws';
      serviceHttpAddress = 'http://localhost:$port';
      var testIndex = 1;
      var totalTests = tests.length;
      var name = Platform.script.pathSegments.last;
      runZoned(() {
        new WebSocketVM(new WebSocketVMTarget(addr)).load()
            .then((VM vm) => vm.isolates.first.load())
            .then((Isolate isolate) => Future.forEach(tests, (test) {
              isolate.vm.verbose = verbose_vm;
              print('Running $name [$testIndex/$totalTests]');
              testIndex++;
              return test(isolate);
            })).then((_) => process.requestExit());
      }, onError: (e, st) {
        process.requestExit();
        if (!_isWebSocketDisconnect(e)) {
          print('Unexpected exception in service tests: $e $st');
          throw e;
        }
      });
    });
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
///
/// This is a special version of this test harness specifically for the
/// pause_on_unhandled_exceptions_test, which cannot properly function
/// in an async context (because exceptions are *always* handled in async
/// functions).
///
/// TODO(johnmccutchan): Don't use the shared harness for the
/// pause_on_unhandled_exceptions_test.
void runIsolateTestsSynchronous(List<String> mainArgs,
                                List<IsolateTest> tests,
                                {void testeeBefore(),
                                 void testeeConcurrent(),
                                 bool pause_on_start: false,
                                 bool pause_on_exit: false,
                                 bool trace_service: false,
                                 bool trace_compiler: false,
                                 bool verbose_vm: false,
                                 bool pause_on_unhandled_exceptions: false}) {
  assert(!pause_on_start || testeeBefore == null);
  if (mainArgs.contains(_TESTEE_MODE_FLAG)) {
    if (!pause_on_start) {
      if (testeeBefore != null) {
        testeeBefore();
      }
      print(''); // Print blank line to signal that we are ready.
    }
    if (testeeConcurrent != null) {
      testeeConcurrent();
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      stdin.first.then((_) => exit(0));
    }
  } else {
    var process = new _TestLauncher();
    process.launch(pause_on_start, pause_on_exit,
                   pause_on_unhandled_exceptions,
                   trace_service, trace_compiler).then((port) {
      if (mainArgs.contains("--gdb")) {
        port = 8181;
      }
      String addr = 'ws://localhost:$port/ws';
      serviceHttpAddress = 'http://localhost:$port';
      var testIndex = 1;
      var totalTests = tests.length;
      var name = Platform.script.pathSegments.last;
      runZoned(() {
        new WebSocketVM(new WebSocketVMTarget(addr)).load()
            .then((VM vm) => vm.isolates.first.load())
            .then((Isolate isolate) => Future.forEach(tests, (test) {
              isolate.vm.verbose = verbose_vm;
              print('Running $name [$testIndex/$totalTests]');
              testIndex++;
              return test(isolate);
            })).then((_) => process.requestExit());
      }, onError: (e, st) {
        process.requestExit();
        if (!_isWebSocketDisconnect(e)) {
          print('Unexpected exception in service tests: $e $st');
          throw e;
        }
      });
    });
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


Future<Isolate> hasPausedFor(Isolate isolate, String kind) {
  // Set up a listener to wait for breakpoint events.
  Completer completer = new Completer();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
        if (event.kind == kind) {
          print('Paused with $kind');
          subscription.cancel();
          if (completer != null) {
            // Reload to update isolate.pauseEvent.
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
        print('Paused with $kind');
        subscription.cancel();
        if (completer != null) {
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


/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
Future runVMTests(List<String> mainArgs,
                  List<VMTest> tests,
                  {Future testeeBefore(),
                   Future testeeConcurrent(),
                   bool pause_on_start: false,
                   bool pause_on_exit: false,
                   bool trace_service: false,
                   bool trace_compiler: false,
                   bool verbose_vm: false,
                   bool pause_on_unhandled_exceptions: false}) async {
  if (mainArgs.contains(_TESTEE_MODE_FLAG)) {
    if (!pause_on_start) {
      if (testeeBefore != null) {
        await testeeBefore();
      }
      print(''); // Print blank line to signal that we are ready.
    }
    if (testeeConcurrent != null) {
      await testeeConcurrent();
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      stdin.first.then((_) => exit(0));
    }
  } else {
    var process = new _TestLauncher();
    process.launch(pause_on_start,
                   pause_on_exit,
                   pause_on_unhandled_exceptions,
                   trace_service, trace_compiler).then((port) async {
      if (mainArgs.contains("--gdb")) {
        port = 8181;
      }
      String addr = 'ws://localhost:$port/ws';
      serviceHttpAddress = 'http://localhost:$port';
      var testIndex = 1;
      var totalTests = tests.length;
      var name = Platform.script.pathSegments.last;
      runZoned(() {
        new WebSocketVM(new WebSocketVMTarget(addr)).load()
            .then((VM vm) => Future.forEach(tests, (test) {
              vm.verbose = verbose_vm;
              print('Running $name [$testIndex/$totalTests]');
              testIndex++;
              return test(vm);
            })).then((_) => process.requestExit());
      }, onError: (e, st) {
        process.requestExit();
        if (!_isWebSocketDisconnect(e)) {
          print('Unexpected exception in service tests: $e $st');
          throw e;
        }
      });
    });
  }
}
