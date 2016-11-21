// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:observatory/service_io.dart';
import 'package:stack_trace/stack_trace.dart';
import 'service_test_common.dart';

/// Will be set to the http address of the VM's service protocol before
/// any tests are invoked.
String serviceHttpAddress;
String serviceWebsocketAddress;

const String _TESTEE_ENV_KEY = 'SERVICE_TEST_TESTEE';
const Map<String, String> _TESTEE_SPAWN_ENV = const {
  _TESTEE_ENV_KEY: 'true'
};
bool _isTestee() {
  return Platform.environment.containsKey(_TESTEE_ENV_KEY);
}

const String _SKY_SHELL_ENV_KEY = 'SERVICE_TEST_SKY_SHELL';
bool _shouldLaunchSkyShell() {
  return Platform.environment.containsKey(_SKY_SHELL_ENV_KEY);
}
String _skyShellPath() {
  return Platform.environment[_SKY_SHELL_ENV_KEY];
}

class _ServiceTesteeRunner {
  Future run({testeeBefore(): null,
              testeeConcurrent(): null,
              bool pause_on_start: false,
              bool pause_on_exit: false}) async {
    if (!pause_on_start) {
      if (testeeBefore != null) {
        var result = testeeBefore();
        if (result is Future) {
          await result;
        }
      }
      print(''); // Print blank line to signal that testeeBefore has run.
    }
    if (testeeConcurrent != null) {
      var result = testeeConcurrent();
      if (result is Future) {
        await result;
      }
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      stdin.first.then((_) => exit(0));
    }
  }

  void runSync({void testeeBeforeSync(): null,
                void testeeConcurrentSync(): null,
                bool pause_on_start: false,
                bool pause_on_exit: false}) {
    if (!pause_on_start) {
      if (testeeBeforeSync != null) {
        testeeBeforeSync();
      }
      print(''); // Print blank line to signal that testeeBefore has run.
    }
    if (testeeConcurrentSync != null) {
      testeeConcurrentSync();
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      stdin.first.then((_) => exit(0));
    }
  }
}

class _ServiceTesteeLauncher {
  Process process;
  final List<String> args;
  bool killedByTester = false;

  _ServiceTesteeLauncher() :
      args = [Platform.script.toFilePath()] {}

  // Spawn the testee process.
  Future<Process> _spawnProcess(bool pause_on_start,
                                bool pause_on_exit,
                                bool pause_on_unhandled_exceptions,
                                bool trace_service,
                                bool trace_compiler,
                                bool testeeControlsServer,
                                bool useAuthToken) {
    assert(pause_on_start != null);
    assert(pause_on_exit != null);
    assert(pause_on_unhandled_exceptions != null);
    assert(trace_service != null);
    assert(trace_compiler != null);
    assert(testeeControlsServer != null);
    assert(useAuthToken != null);

    if (_shouldLaunchSkyShell()) {
      return _spawnSkyProcess(pause_on_start,
                              pause_on_exit,
                              pause_on_unhandled_exceptions,
                              trace_service,
                              trace_compiler,
                              testeeControlsServer);
    } else {
      return _spawnDartProcess(pause_on_start,
                               pause_on_exit,
                               pause_on_unhandled_exceptions,
                               trace_service,
                               trace_compiler,
                               testeeControlsServer,
                               useAuthToken);
    }
  }

  Future<Process> _spawnDartProcess(bool pause_on_start,
                                    bool pause_on_exit,
                                    bool pause_on_unhandled_exceptions,
                                    bool trace_service,
                                    bool trace_compiler,
                                    bool testeeControlsServer,
                                    bool useAuthToken) {
    assert(!_shouldLaunchSkyShell());

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
    if (!testeeControlsServer) {
      fullArgs.add('--enable-vm-service:0');
    }
    fullArgs.addAll(args);

    return _spawnCommon(
        dartExecutable,
        fullArgs,
        <String, String>{
          'DART_SERVICE_USE_AUTH': '$useAuthToken'
        });
  }

  Future<Process> _spawnSkyProcess(bool pause_on_start,
                                   bool pause_on_exit,
                                   bool pause_on_unhandled_exceptions,
                                   bool trace_service,
                                   bool trace_compiler,
                                   bool testeeControlsServer) {
    assert(_shouldLaunchSkyShell());

    String dartExecutable = _skyShellPath();

    var dartFlags = [];
    var fullArgs = [];
    if (trace_service) {
      dartFlags.add('--trace_service');
      dartFlags.add('--trace_service_verbose');
    }
    if (trace_compiler) {
      dartFlags.add('--trace_compiler');
    }
    if (pause_on_start) {
      dartFlags.add('--pause_isolates_on_start');
      fullArgs.add('--start-paused');
    }
    if (pause_on_exit) {
      dartFlags.add('--pause_isolates_on_exit');
    }
    if (pause_on_unhandled_exceptions) {
      dartFlags.add('--pause_isolates_on_unhandled_exceptions');
    }
    // Override mirrors.
    dartFlags.add('--enable_mirrors=true');

    fullArgs.addAll(Platform.executableArguments);
    if (!testeeControlsServer) {
      fullArgs.add('--observatory-port=0');
    }
    fullArgs.add('--dart-flags=${dartFlags.join(' ')}');
    fullArgs.addAll(args);

    return _spawnCommon(dartExecutable, fullArgs, <String, String>{});
  }

  Future<Process> _spawnCommon(String executable,
                               List<String> arguments,
                               Map<String, String> dartEnvironment) {
    var environment = _TESTEE_SPAWN_ENV;
    var bashEnvironment = new StringBuffer();
    environment.forEach((k, v) => bashEnvironment.write("$k=$v "));
    if (dartEnvironment != null) {
      dartEnvironment.forEach((k, v) {
        arguments.insert(0, '-D$k=$v');
      });
    }
    print('** Launching $bashEnvironment$executable ${arguments.join(' ')}');
    return Process.start(executable, arguments, environment: environment);
  }

  Future<Uri> launch(bool pause_on_start,
                     bool pause_on_exit,
                     bool pause_on_unhandled_exceptions,
                     bool trace_service,
                     bool trace_compiler,
                     bool testeeControlsServer,
                     bool useAuthToken) {
    return _spawnProcess(pause_on_start,
                  pause_on_exit,
                  pause_on_unhandled_exceptions,
                  trace_service,
                  trace_compiler,
                  testeeControlsServer,
                  useAuthToken).then((p) {
      Completer<Uri> completer = new Completer<Uri>();
      process = p;
      Uri uri;
      var blank;
      var first = true;
      process.stdout.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        const kObservatoryListening = 'Observatory listening on ';
        if (line.startsWith(kObservatoryListening)) {
          uri = Uri.parse(line.substring(kObservatoryListening.length));
        }
        if (pause_on_start || line == '') {
          // Received blank line.
          blank = true;
        }
        if ((uri != null) && (blank == true) && (first == true)) {
          completer.complete(uri);
          // Stop repeat completions.
          first = false;
          print('** Signaled to run test queries on $uri');
        }
        print('>testee>out> $line');
      });
      process.stderr.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        print('>testee>err> $line');
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

void setupAddresses(Uri serverAddress) {
  serviceWebsocketAddress =
          'ws://${serverAddress.authority}${serverAddress.path}ws';
  serviceHttpAddress =
      'http://${serverAddress.authority}${serverAddress.path}';
}

class _ServiceTesterRunner {
  void run({List<String> mainArgs,
            List<VMTest> vmTests,
            List<IsolateTest> isolateTests,
            bool pause_on_start: false,
            bool pause_on_exit: false,
            bool trace_service: false,
            bool trace_compiler: false,
            bool verbose_vm: false,
            bool pause_on_unhandled_exceptions: false,
            bool testeeControlsServer: false,
            bool useAuthToken: false}) {
    var process = new _ServiceTesteeLauncher();
    process.launch(pause_on_start, pause_on_exit,
                   pause_on_unhandled_exceptions,
                   trace_service, trace_compiler,
                   testeeControlsServer,
                   useAuthToken).then((Uri serverAddress) async {
      if (mainArgs.contains("--gdb")) {
        var pid = process.process.pid;
        var wait = new Duration(seconds: 10);
        print("Testee has pid $pid, waiting $wait before continuing");
        sleep(wait);
      }
      setupAddresses(serverAddress);
      var name = Platform.script.pathSegments.last;
      Chain.capture(() async {
        var vm =
            new WebSocketVM(new WebSocketVMTarget(serviceWebsocketAddress));
        print('Loading VM...');
        await vm.load();
        print('Done loading VM');

        // Run vm tests.
        if (vmTests != null) {
          var testIndex = 1;
          var totalTests = vmTests.length;
          for (var test in vmTests) {
            vm.verbose = verbose_vm;
            print('Running $name [$testIndex/$totalTests]');
            testIndex++;
            await test(vm);
          }
        }

        // Run isolate tests.
        if (isolateTests != null) {
          var isolate = await vm.isolates.first.load();
          var testIndex = 1;
          var totalTests = isolateTests.length;
          for (var test in isolateTests) {
            vm.verbose = verbose_vm;
            print('Running $name [$testIndex/$totalTests]');
            testIndex++;
            await test(isolate);
          }
        }

        await process.requestExit();
      }, onError: (error, stackTrace) {
        process.requestExit();
        print('Unexpected exception in service tests: $error\n$stackTrace');
        throw error;
      });
    });
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
Future runIsolateTests(List<String> mainArgs,
                       List<IsolateTest> tests,
                       {testeeBefore(),
                        testeeConcurrent(),
                        bool pause_on_start: false,
                        bool pause_on_exit: false,
                        bool trace_service: false,
                        bool trace_compiler: false,
                        bool verbose_vm: false,
                        bool pause_on_unhandled_exceptions: false,
                        bool testeeControlsServer: false,
                        bool useAuthToken: false}) async {
  assert(!pause_on_start || testeeBefore == null);
  if (_isTestee()) {
    new _ServiceTesteeRunner().run(testeeBefore: testeeBefore,
                                   testeeConcurrent: testeeConcurrent,
                                   pause_on_start: pause_on_start,
                                   pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        isolateTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        trace_service: trace_service,
        trace_compiler: trace_compiler,
        verbose_vm: verbose_vm,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions,
        testeeControlsServer: testeeControlsServer,
        useAuthToken: useAuthToken);
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
  if (_isTestee()) {
    new _ServiceTesteeRunner().runSync(testeeBeforeSync: testeeBefore,
                                       testeeConcurrentSync: testeeConcurrent,
                                       pause_on_start: pause_on_start,
                                       pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        isolateTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        trace_service: trace_service,
        trace_compiler: trace_compiler,
        verbose_vm: verbose_vm,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions);
  }
}


/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
Future runVMTests(List<String> mainArgs,
                  List<VMTest> tests,
                  {testeeBefore(),
                   testeeConcurrent(),
                   bool pause_on_start: false,
                   bool pause_on_exit: false,
                   bool trace_service: false,
                   bool trace_compiler: false,
                   bool verbose_vm: false,
                   bool pause_on_unhandled_exceptions: false}) async {
  if (_isTestee()) {
    new _ServiceTesteeRunner().run(testeeBefore: testeeBefore,
                                   testeeConcurrent: testeeConcurrent,
                                   pause_on_start: pause_on_start,
                                   pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        vmTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        trace_service: trace_service,
        trace_compiler: trace_compiler,
        verbose_vm: verbose_vm,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions);
  }
}
