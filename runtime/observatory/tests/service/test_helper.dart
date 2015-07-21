// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override --checked

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

  Future<int> launch(bool pause_on_exit) {
    String dartExecutable = Platform.executable;
    var fullArgs = [];
    if (pause_on_exit == true) {
      fullArgs.add('--pause-isolates-on-exit');
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
        if (line == '') {
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

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
void runIsolateTests(List<String> mainArgs,
                     List<IsolateTest> tests,
                     {void testeeBefore(),
                      void testeeConcurrent(),
                      bool pause_on_exit}) {
  if (mainArgs.contains(_TESTEE_MODE_FLAG)) {
    if (testeeBefore != null) {
      testeeBefore();
    }
    print(''); // Print blank line to signal that we are ready.
    if (testeeConcurrent != null) {
      testeeConcurrent();
    }
    // Wait around for the process to be killed.
    stdin.first.then((_) => exit(0));
  } else {
    var process = new _TestLauncher();
    process.launch(pause_on_exit).then((port) {
      if (mainArgs.contains("--gdb")) {
        port = 8181;
      }
      String addr = 'ws://localhost:$port/ws';
      var testIndex = 1;
      var totalTests = tests.length;
      var name = Platform.script.pathSegments.last;
      runZoned(() {
        new WebSocketVM(new WebSocketVMTarget(addr)).load()
            .then((VM vm) => vm.isolates.first.load())
            .then((Isolate isolate) => Future.forEach(tests, (test) {
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


// Cancel the subscription and complete the completer when finished processing
// events.
typedef void ServiceEventHandler(ServiceEvent event,
                                 StreamSubscription subscription,
                                 Completer completer);

Future processServiceEvents(VM vm,
                            String streamId,
                            ServiceEventHandler handler) {
  Completer completer = new Completer();
  vm.getEventStream(streamId).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      handler(event, subscription, completer);
    });
  });
  return completer.future;
}


Future<Isolate> hasStoppedAtBreakpoint(Isolate isolate) {
  // Set up a listener to wait for breakpoint events.
  Completer completer = new Completer();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
        print("Event: $event");
        if (event.kind == ServiceEvent.kPauseBreakpoint) {
          print('Breakpoint reached');
          subscription.cancel();
          if (completer != null) {
            completer.complete(isolate);
            completer = null;
          }
        }
    });

    // Pause may have happened before we subscribed.
    isolate.reload().then((_) {
      if ((isolate.pauseEvent != null) &&
         (isolate.pauseEvent.kind == ServiceEvent.kPauseBreakpoint)) {
        // Already waiting at a breakpoint.
        print('Breakpoint reached');
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
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Frame top = stack['frames'][0];
    Script script = await top.location.script.load();
    expect(script.tokenToLine(top.location.tokenPos), equals(line));
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


/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
Future runVMTests(List<String> mainArgs,
                  List<VMTest> tests,
                  {Future testeeBefore(),
                   Future testeeConcurrent(),
                   bool pause_on_exit}) async {
  if (mainArgs.contains(_TESTEE_MODE_FLAG)) {
    if (testeeBefore != null) {
      await testeeBefore();
    }
    print(''); // Print blank line to signal that we are ready.
    if (testeeConcurrent != null) {
      await testeeConcurrent();
    }
    // Wait around for the process to be killed.
    stdin.first.then((_) => exit(0));
  } else {
    var process = new _TestLauncher();
    process.launch(pause_on_exit).then((port) async {
      if (mainArgs.contains("--gdb")) {
        port = 8181;
      }
      String addr = 'ws://localhost:$port/ws';
      var testIndex = 1;
      var totalTests = tests.length;
      var name = Platform.script.pathSegments.last;
      runZoned(() {
        new WebSocketVM(new WebSocketVMTarget(addr)).load()
            .then((VM vm) => Future.forEach(tests, (test) {
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
