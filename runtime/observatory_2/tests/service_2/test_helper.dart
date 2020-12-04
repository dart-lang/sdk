// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dds/dds.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
export 'service_test_common.dart' show DDSTest, IsolateTest, VMTest;

/// Determines whether DDS is enabled for this test run.
const bool useDds = const bool.fromEnvironment('USE_DDS');

/// The extra arguments to use
const List<String> extraDebuggingArgs = ['--lazy-async-stacks'];

/// Will be set to the http address of the VM's service protocol before
/// any tests are invoked.
String serviceHttpAddress;
String serviceWebsocketAddress;

const String _TESTEE_ENV_KEY = 'SERVICE_TEST_TESTEE';
const Map<String, String> _TESTEE_SPAWN_ENV = const {_TESTEE_ENV_KEY: 'true'};
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
  Future run(
      {testeeBefore(): null,
      testeeConcurrent(): null,
      bool pause_on_start: false,
      bool pause_on_exit: false}) async {
    if (!pause_on_start) {
      if (testeeBefore != null) {
        final result = testeeBefore();
        if (result is Future) {
          await result;
        }
      }
      print(''); // Print blank line to signal that testeeBefore has run.
    }
    if (testeeConcurrent != null) {
      final result = testeeConcurrent();
      if (result is Future) {
        await result;
      }
    }
    if (!pause_on_exit) {
      // Wait around for the process to be killed.
      stdin.first.then((_) => exit(0));
    }
  }

  void runSync(
      {void testeeBeforeSync(): null,
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
  Future<void> get exited => _processCompleter.future;
  final _processCompleter = Completer<void>();
  bool killedByTester = false;

  _ServiceTesteeLauncher() : args = [Platform.script.toFilePath()] {}

  // Spawn the testee process.
  Future<Process> _spawnProcess(
      bool pause_on_start,
      bool pause_on_exit,
      bool pause_on_unhandled_exceptions,
      bool enable_service_port_fallback,
      bool testeeControlsServer,
      Uri serviceInfoUri,
      int port,
      List<String> extraArgs,
      List<String> executableArgs) {
    assert(pause_on_start != null);
    assert(pause_on_exit != null);
    assert(pause_on_unhandled_exceptions != null);
    assert(testeeControlsServer != null);

    if (_shouldLaunchSkyShell()) {
      return _spawnSkyProcess(
          pause_on_start,
          pause_on_exit,
          pause_on_unhandled_exceptions,
          testeeControlsServer,
          extraArgs,
          executableArgs);
    } else {
      return _spawnDartProcess(
          pause_on_start,
          pause_on_exit,
          pause_on_unhandled_exceptions,
          enable_service_port_fallback,
          testeeControlsServer,
          serviceInfoUri,
          port,
          extraArgs,
          executableArgs);
    }
  }

  Future<Process> _spawnDartProcess(
      bool pause_on_start,
      bool pause_on_exit,
      bool pause_on_unhandled_exceptions,
      bool enable_service_port_fallback,
      bool testeeControlsServer,
      Uri serviceInfoUri,
      int port,
      List<String> extraArgs,
      List<String> executableArgs) {
    assert(!_shouldLaunchSkyShell());

    final String dartExecutable = Platform.executable;

    final fullArgs = <String>[
      '--disable-dart-dev',
    ];
    if (pause_on_start) {
      fullArgs.add('--pause-isolates-on-start');
    }
    if (pause_on_exit) {
      fullArgs.add('--pause-isolates-on-exit');
    }
    if (enable_service_port_fallback) {
      fullArgs.add('--enable_service_port_fallback');
    }
    fullArgs.add('--write-service-info=$serviceInfoUri');

    if (pause_on_unhandled_exceptions) {
      fullArgs.add('--pause-isolates-on-unhandled-exceptions');
    }
    fullArgs.add('--profiler');
    if (extraArgs != null) {
      fullArgs.addAll(extraArgs);
    }
    fullArgs.addAll(executableArgs);
    if (!testeeControlsServer) {
      fullArgs.add('--enable-vm-service:$port');
    }
    fullArgs.addAll(args);

    return _spawnCommon(dartExecutable, fullArgs, <String, String>{});
  }

  Future<Process> _spawnSkyProcess(
      bool pause_on_start,
      bool pause_on_exit,
      bool pause_on_unhandled_exceptions,
      bool testeeControlsServer,
      List<String> extraArgs,
      List<String> executableArgs) {
    assert(_shouldLaunchSkyShell());

    final String dartExecutable = _skyShellPath();

    final dartFlags = <String>[];
    final fullArgs = <String>[];
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
    dartFlags.add('--profiler');
    // Override mirrors.
    dartFlags.add('--enable_mirrors=true');
    if (extraArgs != null) {
      fullArgs.addAll(extraArgs);
    }
    fullArgs.addAll(executableArgs);
    if (!testeeControlsServer) {
      fullArgs.add('--observatory-port=0');
    }
    fullArgs.add('--dart-flags=${dartFlags.join(' ')}');
    fullArgs.addAll(args);

    return _spawnCommon(dartExecutable, fullArgs, <String, String>{});
  }

  Future<Process> _spawnCommon(String executable, List<String> arguments,
      Map<String, String> dartEnvironment) {
    final environment = _TESTEE_SPAWN_ENV;
    final bashEnvironment = new StringBuffer();
    environment.forEach((k, v) => bashEnvironment.write("$k=$v "));
    if (dartEnvironment != null) {
      dartEnvironment.forEach((k, v) {
        arguments.insert(0, '-D$k=$v');
      });
    }
    print('** Launching $bashEnvironment$executable ${arguments.join(' ')}');
    return Process.start(executable, arguments, environment: environment);
  }

  Future<Uri> launch(
      bool pause_on_start,
      bool pause_on_exit,
      bool pause_on_unhandled_exceptions,
      bool enable_service_port_fallback,
      bool testeeControlsServer,
      int port,
      List<String> extraArgs,
      List<String> executableArgs) async {
    final completer = new Completer<Uri>();
    final serviceInfoDir =
        await Directory.systemTemp.createTemp('dart_service');
    final serviceInfoUri = serviceInfoDir.uri.resolve('service_info.json');
    final serviceInfoFile = await File.fromUri(serviceInfoUri).create();
    _spawnProcess(
            pause_on_start,
            pause_on_exit,
            pause_on_unhandled_exceptions,
            enable_service_port_fallback,
            testeeControlsServer,
            serviceInfoUri,
            port,
            extraArgs,
            executableArgs)
        .then((p) async {
      process = p;
      Uri uri;
      final blankCompleter = Completer();
      bool blankLineReceived = false;
      process.stdout
          .transform(utf8.decoder)
          .transform(new LineSplitter())
          .listen((line) {
        if (!blankLineReceived && (pause_on_start || line == '')) {
          // Received blank line.
          blankLineReceived = true;
          blankCompleter.complete();
        }
        print('>testee>out> $line');
      });
      process.stderr
          .transform(utf8.decoder)
          .transform(new LineSplitter())
          .listen((line) {
        print('>testee>err> ${line.trim()}');
      });
      process.exitCode.then((exitCode) async {
        await serviceInfoDir.delete(recursive: true);
        if ((exitCode != 0) && !killedByTester) {
          throw "Testee exited with $exitCode";
        }
        print("** Process exited");
        _processCompleter.complete();
      });

      // Wait for the blank line which signals that we're ready to run.
      await blankCompleter.future;
      while ((await serviceInfoFile.length()) <= 5) {
        await Future.delayed(Duration(milliseconds: 50));
      }
      final content = await serviceInfoFile.readAsString();
      final infoJson = json.decode(content);
      String rawUri = infoJson['uri'];

      // If rawUri ends with a /, Uri.parse will include an empty string as the
      // last path segment. Make sure it's not there to ensure we have a
      // consistent Uri.
      if (rawUri.endsWith('/')) {
        rawUri = rawUri.substring(0, rawUri.length - 1);
      }
      uri = Uri.parse(rawUri);
      completer.complete(uri);
    });
    return completer.future;
  }

  void requestExit() {
    if (process != null) {
      print('** Killing script');
      if (process.kill()) {
        killedByTester = true;
      }
    }
  }
}

void setupAddresses(Uri serverAddress) {
  serviceWebsocketAddress =
      'ws://${serverAddress.authority}${serverAddress.path}/ws';
  serviceHttpAddress = 'http://${serverAddress.authority}${serverAddress.path}';
}

class _ServiceTesterRunner {
  void run({
    List<String> mainArgs,
    List<String> extraArgs,
    List<String> executableArgs,
    List<DDSTest> ddsTests,
    List<IsolateTest> isolateTests,
    List<VMTest> vmTests,
    bool pause_on_start: false,
    bool pause_on_exit: false,
    bool verbose_vm: false,
    bool pause_on_unhandled_exceptions: false,
    bool enable_service_port_fallback: false,
    bool testeeControlsServer: false,
    bool enableDds: true,
    bool enableService: true,
    int port = 0,
  }) {
    if (executableArgs == null) {
      executableArgs = Platform.executableArguments;
    }
    DartDevelopmentService dds;
    WebSocketVM vm;
    _ServiceTesteeLauncher process;
    bool testsDone = false;

    ignoreLateException(Function f) async {
      try {
        await f();
      } catch (error, stackTrace) {
        if (testsDone) {
          print('Ignoring late exception during process exit:\n'
              '$error\n$stackTrace');
        } else {
          rethrow;
        }
      }
    }

    setUp(
      () => ignoreLateException(
        () async {
          process = _ServiceTesteeLauncher();
          await process
              .launch(
                  pause_on_start,
                  pause_on_exit,
                  pause_on_unhandled_exceptions,
                  enable_service_port_fallback,
                  testeeControlsServer,
                  port,
                  extraArgs,
                  executableArgs)
              .then((Uri serverAddress) async {
            if (mainArgs.contains("--gdb")) {
              final pid = process.process.pid;
              final wait = new Duration(seconds: 10);
              print("Testee has pid $pid, waiting $wait before continuing");
              sleep(wait);
            }
            if (useDds) {
              dds = await DartDevelopmentService.startDartDevelopmentService(
                  serverAddress);
              setupAddresses(dds.uri);
            } else {
              setupAddresses(serverAddress);
            }
            print('** Signaled to run test queries on $serviceHttpAddress'
                ' (${useDds ? "DDS" : "VM Service"})');
            vm =
                new WebSocketVM(new WebSocketVMTarget(serviceWebsocketAddress));
            print('Loading VM...');
            await vm.load();
            print('Done loading VM');
          });
        },
      ),
    );

    tearDown(
      () => ignoreLateException(
        () async {
          if (useDds) {
            await dds?.shutdown();
          }
          process.requestExit();
        },
      ),
    );

    final name = Platform.script.pathSegments.last;
    runTest(String name) {
      test(
        '$name (${useDds ? 'DDS' : 'VM Service'})',
        () => ignoreLateException(
          () async {
            // Run vm tests.
            if (vmTests != null) {
              int testIndex = 1;
              final totalTests = vmTests.length;
              for (var test in vmTests) {
                vm.verbose = verbose_vm;
                print('Running $name [$testIndex/$totalTests]');
                testIndex++;
                await test(vm);
              }
            }

            // Run dds tests.
            if (ddsTests != null) {
              int testIndex = 1;
              final totalTests = ddsTests.length;
              for (var test in ddsTests) {
                vm.verbose = verbose_vm;
                print('Running $name [$testIndex/$totalTests]');
                testIndex++;
                await test(vm, dds);
              }
            }

            // Run isolate tests.
            if (isolateTests != null) {
              final isolate = await getFirstIsolate(vm);
              int testIndex = 1;
              final totalTests = isolateTests.length;
              for (var test in isolateTests) {
                vm.verbose = verbose_vm;
                print('Running $name [$testIndex/$totalTests]');
                testIndex++;
                await test(isolate);
              }
            }

            print('All service tests completed successfully.');
            testsDone = true;
          },
        ),
        // Some service tests run fairly long (e.g., valid_source_locations_test).
        timeout: Timeout.none,
      );
    }

    if ((useDds && !enableDds) || (!useDds && ddsTests != null)) {
      print('Skipping DDS run for $name');
      return;
    }
    if (!useDds && !enableService) {
      print('Skipping VM Service run for $name');
      return;
    }
    runTest(name);
  }

  Future<Isolate> getFirstIsolate(WebSocketVM vm) async {
    if (vm.isolates.isNotEmpty) {
      final isolate = await vm.isolates.first.load();
      if (isolate is Isolate) {
        return isolate;
      }
    }

    Completer completer = new Completer();
    vm.getEventStream(VM.kIsolateStream).then((stream) {
      var subscription;
      subscription = stream.listen((ServiceEvent event) async {
        if (completer == null) {
          subscription.cancel();
          return;
        }
        if (event.kind == ServiceEvent.kIsolateRunnable) {
          if (vm.isolates.isNotEmpty) {
            vm.isolates.first.load().then((result) {
              if (result is Isolate) {
                subscription.cancel();
                completer.complete(result);
                completer = null;
              }
            });
          }
        }
      });
    });

    // The isolate may have started before we subscribed.
    if (vm.isolates.isNotEmpty) {
      vm.isolates.first.reload().then((result) async {
        if (completer != null && result is Isolate) {
          completer.complete(result);
          completer = null;
        }
      });
    }
    return await completer.future;
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
Future runIsolateTests(List<String> mainArgs, List<IsolateTest> tests,
    {testeeBefore(),
    testeeConcurrent(),
    bool pause_on_start: false,
    bool pause_on_exit: false,
    bool verbose_vm: false,
    bool pause_on_unhandled_exceptions: false,
    bool testeeControlsServer: false,
    bool enableDds: true,
    bool enableService: true,
    List<String> extraArgs}) async {
  assert(!pause_on_start || testeeBefore == null);
  if (_isTestee()) {
    new _ServiceTesteeRunner().run(
        testeeBefore: testeeBefore,
        testeeConcurrent: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
      mainArgs: mainArgs,
      extraArgs: extraArgs,
      isolateTests: tests,
      pause_on_start: pause_on_start,
      pause_on_exit: pause_on_exit,
      verbose_vm: verbose_vm,
      pause_on_unhandled_exceptions: pause_on_unhandled_exceptions,
      testeeControlsServer: testeeControlsServer,
      enableDds: enableDds,
      enableService: enableService,
    );
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
///
/// This is a special version of this test harness specifically for the
/// pause_on_unhandled_exceptions_test, which cannot properly function
/// in an async context (because exceptions are *always* handled in async
/// functions).
void runIsolateTestsSynchronous(List<String> mainArgs, List<IsolateTest> tests,
    {void testeeBefore(),
    void testeeConcurrent(),
    bool pause_on_start: false,
    bool pause_on_exit: false,
    bool verbose_vm: false,
    bool pause_on_unhandled_exceptions: false,
    List<String> extraArgs}) {
  assert(!pause_on_start || testeeBefore == null);
  if (_isTestee()) {
    new _ServiceTesteeRunner().runSync(
        testeeBeforeSync: testeeBefore,
        testeeConcurrentSync: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
        mainArgs: mainArgs,
        extraArgs: extraArgs,
        isolateTests: tests,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit,
        verbose_vm: verbose_vm,
        pause_on_unhandled_exceptions: pause_on_unhandled_exceptions);
  }
}

/// Runs [tests] in sequence, each of which should take a [VM] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
Future runVMTests(List<String> mainArgs, List<VMTest> tests,
    {testeeBefore(),
    testeeConcurrent(),
    bool pause_on_start: false,
    bool pause_on_exit: false,
    bool verbose_vm: false,
    bool pause_on_unhandled_exceptions: false,
    bool enable_service_port_fallback: false,
    bool enableDds: true,
    bool enableService: true,
    int port = 0,
    List<String> extraArgs,
    List<String> executableArgs}) async {
  if (_isTestee()) {
    new _ServiceTesteeRunner().run(
        testeeBefore: testeeBefore,
        testeeConcurrent: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
      mainArgs: mainArgs,
      extraArgs: extraArgs,
      executableArgs: executableArgs,
      vmTests: tests,
      pause_on_start: pause_on_start,
      pause_on_exit: pause_on_exit,
      verbose_vm: verbose_vm,
      pause_on_unhandled_exceptions: pause_on_unhandled_exceptions,
      enable_service_port_fallback: enable_service_port_fallback,
      enableDds: enableDds,
      enableService: enableService,
      port: port,
    );
  }
}

/// Runs [tests] in sequence, each of which should take a [VM] and
/// [DartDevelopmentService] and return a [Future]. Code for setting up state
/// can run before and/or concurrently with the tests. Uses [mainArgs] to
/// determine whether to run tests or testee in this invocation of the
/// script.
Future runDDSTests(List<String> mainArgs, List<DDSTest> tests,
    {testeeBefore(),
    testeeConcurrent(),
    bool pause_on_start: false,
    bool pause_on_exit: false,
    bool verbose_vm: false,
    bool pause_on_unhandled_exceptions: false,
    bool enable_service_port_fallback: false,
    int port = 0,
    List<String> extraArgs,
    List<String> executableArgs}) async {
  if (_isTestee()) {
    new _ServiceTesteeRunner().run(
        testeeBefore: testeeBefore,
        testeeConcurrent: testeeConcurrent,
        pause_on_start: pause_on_start,
        pause_on_exit: pause_on_exit);
  } else {
    new _ServiceTesterRunner().run(
      mainArgs: mainArgs,
      extraArgs: extraArgs,
      executableArgs: executableArgs,
      ddsTests: tests,
      pause_on_start: pause_on_start,
      pause_on_exit: pause_on_exit,
      verbose_vm: verbose_vm,
      pause_on_unhandled_exceptions: pause_on_unhandled_exceptions,
      enable_service_port_fallback: enable_service_port_fallback,
      enableDds: true,
      enableService: false,
      port: port,
    );
  }
}
