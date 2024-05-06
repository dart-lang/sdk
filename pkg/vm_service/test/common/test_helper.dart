// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'service_test_common.dart';

export 'service_test_common.dart' show IsolateTest, VMTest;

/// The extra arguments to use
const List<String> extraDebuggingArgs = [];

/// Will be set to the http address of the VM's service protocol before
/// any tests are invoked.
late String serviceHttpAddress;
late String serviceWebsocketAddress;

const String _TESTEE_ENV_KEY = 'SERVICE_TEST_TESTEE';
const Map<String, String> _TESTEE_SPAWN_ENV = {_TESTEE_ENV_KEY: 'true'};
bool _isTestee() {
  return io.Platform.environment.containsKey(_TESTEE_ENV_KEY);
}

Uri _getTestUri(String script) {
  if (io.Platform.script.isScheme('data')) {
    // If running from pub we can assume that we're in the root of the package
    // directory.
    return Uri.parse('test/$script');
  } else if (io.Platform.script.toFilePath().endsWith('out.aotsnapshot')) {
    // We're running an AOT test. In this case, we need to use the exact URI we
    // launched with.
    return io.Platform.script;
  } else {
    // Resolve the script to ensure that test will fail if the provided script
    // name doesn't match the actual script.
    return io.Platform.script.resolve(script);
  }
}

class _ServiceTesteeRunner {
  Future<void> run({
    Function()? testeeBefore,
    Function()? testeeConcurrent,
    bool pauseOnStart = false,
    bool pauseOnExit = false,
  }) async {
    if (!pauseOnStart) {
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
    if (!pauseOnExit) {
      // Wait around for the process to be killed.
      await io.stdin.first.then((_) => io.exit(0));
    }
  }

  void runSync({
    void Function()? testeeBeforeSync,
    void Function()? testeeConcurrentSync,
    bool pauseOnStart = false,
    bool pauseOnExit = false,
  }) {
    if (!pauseOnStart) {
      if (testeeBeforeSync != null) {
        testeeBeforeSync();
      }
      print(''); // Print blank line to signal that testeeBefore has run.
    }
    if (testeeConcurrentSync != null) {
      testeeConcurrentSync();
    }
    if (!pauseOnExit) {
      // Wait around for the process to be killed.
      io.stdin.first.then((_) => io.exit(0));
    }
  }
}

class _ServiceTesteeLauncher {
  io.Process? process;
  List<String> args;

  bool killedByTester = false;
  final _exitCodeCompleter = Completer<int>();

  _ServiceTesteeLauncher(String script)
      : args = [_getTestUri(script).toFilePath()];

  Future<int> get exitCode => _exitCodeCompleter.future;

  // Spawn the testee process.
  Future<io.Process> _spawnProcess(
    bool pauseOnStart,
    bool pauseOnExit,
    bool pauseOnUnhandledExceptions,
    bool testeeControlsServer,
    bool useAuthToken,
    List<String>? experiments,
    List<String>? extraArgs,
  ) {
    return _spawnDartProcess(
      pauseOnStart,
      pauseOnExit,
      pauseOnUnhandledExceptions,
      testeeControlsServer,
      useAuthToken,
      experiments,
      extraArgs,
    );
  }

  Future<io.Process> _spawnDartProcess(
    bool pauseOnStart,
    bool pauseOnExit,
    bool pauseOnUnhandledExceptions,
    bool testeeControlsServer,
    bool useAuthToken,
    List<String>? experiments,
    List<String>? extraArgs,
  ) {
    final String dartExecutable = io.Platform.executable;

    final fullArgs = <String>[];
    if (pauseOnStart) {
      fullArgs.add('--pause-isolates-on-start');
    }
    if (pauseOnExit) {
      fullArgs.add('--pause-isolates-on-exit');
    }
    if (!useAuthToken) {
      fullArgs.add('--disable-service-auth-codes');
    }
    if (pauseOnUnhandledExceptions) {
      fullArgs.add('--pause-isolates-on-unhandled-exceptions');
    }
    fullArgs.add('--profiler');
    if (experiments != null) {
      fullArgs.addAll(experiments.map((e) => '--enable-experiment=$e'));
    }
    if (extraArgs != null) {
      fullArgs.addAll(extraArgs);
    }

    fullArgs.addAll(io.Platform.executableArguments);
    if (!testeeControlsServer) {
      fullArgs.add('--enable-vm-service:0');
    }
    fullArgs.addAll(args);
    return _spawnCommon(dartExecutable, fullArgs, <String, String>{});
  }

  Future<io.Process> _spawnCommon(
    String executable,
    List<String> arguments,
    Map<String, String> dartEnvironment,
  ) {
    final environment = _TESTEE_SPAWN_ENV;
    final bashEnvironment = StringBuffer();
    environment.forEach((k, v) => bashEnvironment.write('$k=$v '));
    dartEnvironment.forEach((k, v) {
      arguments.insert(0, '-D$k=$v');
    });
    print('** Launching $bashEnvironment$executable ${arguments.join(' ')}');
    return io.Process.start(
      executable,
      arguments,
      environment: environment,
    );
  }

  Future<Uri> launch(
    bool pauseOnStart,
    bool pauseOnExit,
    bool pauseOnUnhandledExceptions,
    bool testeeControlsServer,
    bool useAuthToken,
    List<String>? experiments,
    List<String>? extraArgs,
  ) {
    return _spawnProcess(
      pauseOnStart,
      pauseOnExit,
      pauseOnUnhandledExceptions,
      testeeControlsServer,
      useAuthToken,
      experiments,
      extraArgs,
    ).then((p) {
      final Completer<Uri> completer = Completer<Uri>();
      process = p;
      Uri? uri;
      bool blank = false;
      var first = true;
      process!.stdout
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        const kDartVMServiceListening = 'The Dart VM service is listening on ';
        if (line.startsWith(kDartVMServiceListening)) {
          uri = Uri.parse(line.substring(kDartVMServiceListening.length));
        }
        if (pauseOnStart || line == '') {
          // Received blank line.
          blank = true;
        }
        if ((uri != null) && (blank == true) && (first == true)) {
          completer.complete(uri!);
          // Stop repeat completions.
          first = false;
          print('** Signaled to run test queries on $uri');
        }
        io.stdout.write('>testee>out> $line\n');
      });
      process!.stderr
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        io.stdout.write('>testee>err> $line\n');
      });
      process!.exitCode.then(_exitCodeCompleter.complete);
      return completer.future;
    });
  }

  void requestExit() {
    if (process != null) {
      print('** Killing script');
      if (process!.kill()) {
        killedByTester = true;
      }
    }
  }
}

void setupAddresses(Uri /*!*/ serverAddress) {
  serviceWebsocketAddress =
      'ws://${serverAddress.authority}${serverAddress.path}ws';
  serviceHttpAddress = 'http://${serverAddress.authority}${serverAddress.path}';
}

class _ServiceTesterRunner {
  Future<void> run({
    List<String>? mainArgs,
    List<String>? extraArgs,
    List<String>? experiments,
    List<VMTest>? vmTests,
    List<IsolateTest>? isolateTests,
    required String scriptName,
    bool pauseOnStart = false,
    bool pauseOnExit = false,
    bool verboseVm = false,
    bool pauseOnUnhandledExceptions = false,
    bool testeeControlsServer = false,
    bool useAuthToken = false,
    bool allowForNonZeroExitCode = false,
    VmServiceFactory serviceFactory = VmService.defaultFactory,
  }) async {
    final process = _ServiceTesteeLauncher(scriptName);
    late VmService vm;
    late IsolateRef isolate;
    setUp(() async {
      await process
          .launch(
        pauseOnStart,
        pauseOnExit,
        pauseOnUnhandledExceptions,
        testeeControlsServer,
        useAuthToken,
        experiments,
        extraArgs,
      )
          .then((Uri serverAddress) async {
        if (mainArgs!.contains('--gdb')) {
          final pid = process.process!.pid;
          final wait = Duration(seconds: 10);
          print('Testee has pid $pid, waiting $wait before continuing');
          io.sleep(wait);
        }
        setupAddresses(serverAddress);
        vm = await vmServiceConnectUriWithFactory(
          serviceWebsocketAddress,
          vmServiceFactory: serviceFactory,
        );
        print('Done loading VM');
        isolate = await getFirstIsolate(vm);
      });
    });

    final name = _getTestUri(scriptName).pathSegments.last;

    test(
      name,
      () async {
        // Run vm tests.
        if (vmTests != null) {
          var testIndex = 1;
          final totalTests = vmTests.length;
          for (var t in vmTests) {
            print('$name [$testIndex/$totalTests]');
            await t(vm);
            testIndex++;
          }
        }

        // Run isolate tests.
        if (isolateTests != null) {
          var testIndex = 1;
          final totalTests = isolateTests.length;
          for (var t in isolateTests) {
            print('$name [$testIndex/$totalTests]');
            await t(vm, isolate);
            testIndex++;
          }
        }
      },
      retry: 0,
      timeout: Timeout.none,
    );

    tearDown(() async {
      print('All service tests completed successfully.');
      try {
        await vm.dispose();
      } catch (e, st) {
        print('''
Ignoring exception during vm-service connection shutdown:
$e
$st
''');
      }
      process.requestExit();
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      if (!(process.killedByTester || allowForNonZeroExitCode)) {
        throw 'Testee exited with unexpected exitCode: $exitCode';
      }
    }
    print('** Process exited: $exitCode');
  }

  Future<IsolateRef> getFirstIsolate(VmService service) async {
    var vm = await service.getVM();
    final vmIsolates = vm.isolates!;
    if (vmIsolates.isNotEmpty) {
      return vmIsolates.first;
    }
    Completer<dynamic>? completer = Completer();
    late StreamSubscription subscription;
    subscription = service.onIsolateEvent.listen((Event event) async {
      if (completer == null) {
        await subscription.cancel();
        return;
      }
      if (event.kind == EventKind.kIsolateRunnable) {
        vm = await service.getVM();
        await subscription.cancel();
        await service.streamCancel(EventStreams.kIsolate);
        completer!.complete(event.isolate!);
        completer = null;
      }
    });
    await service.streamListen(EventStreams.kIsolate);

    // The isolate may have started before we subscribed.
    vm = await service.getVM();
    if (vmIsolates.isNotEmpty) {
      await subscription.cancel();
      completer!.complete(vmIsolates.first);
      completer = null;
    }
    return (await completer!.future) as IsolateRef;
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
Future<void> runIsolateTests(
  List<String> mainArgs,
  List<IsolateTest> tests,
  String scriptName, {
  Function()? testeeBefore,
  Function()? testeeConcurrent,
  bool pauseOnStart = false,
  bool pauseOnExit = false,
  bool verboseVm = false,
  bool pauseOnUnhandledExceptions = false,
  bool testeeControlsServer = false,
  bool useAuthToken = false,
  bool allowForNonZeroExitCode = false,
  List<String>? experiments,
  List<String>? extraArgs,
}) async {
  assert(!pauseOnStart || testeeBefore == null);
  if (_isTestee()) {
    await _ServiceTesteeRunner().run(
      testeeBefore: testeeBefore,
      testeeConcurrent: testeeConcurrent,
      pauseOnStart: pauseOnStart,
      pauseOnExit: pauseOnExit,
    );
  } else {
    await _ServiceTesterRunner().run(
      mainArgs: mainArgs,
      scriptName: scriptName,
      extraArgs: extraArgs,
      isolateTests: tests,
      pauseOnStart: pauseOnStart,
      pauseOnExit: pauseOnExit,
      verboseVm: verboseVm,
      experiments: experiments,
      pauseOnUnhandledExceptions: pauseOnUnhandledExceptions,
      testeeControlsServer: testeeControlsServer,
      useAuthToken: useAuthToken,
      allowForNonZeroExitCode: allowForNonZeroExitCode,
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
void runIsolateTestsSynchronous(
  List<String> mainArgs,
  List<IsolateTest> tests,
  String scriptName, {
  void Function()? testeeBefore,
  void Function()? testeeConcurrent,
  bool pauseOnStart = false,
  bool pauseOnExit = false,
  bool verboseVm = false,
  bool pauseOnUnhandledExceptions = false,
  List<String>? extraArgs,
}) {
  assert(!pauseOnStart || testeeBefore == null);
  if (_isTestee()) {
    _ServiceTesteeRunner().runSync(
      testeeBeforeSync: testeeBefore,
      testeeConcurrentSync: testeeConcurrent,
      pauseOnStart: pauseOnStart,
      pauseOnExit: pauseOnExit,
    );
  } else {
    _ServiceTesterRunner().run(
      mainArgs: mainArgs,
      scriptName: scriptName,
      extraArgs: extraArgs,
      isolateTests: tests,
      pauseOnStart: pauseOnStart,
      pauseOnExit: pauseOnExit,
      verboseVm: verboseVm,
      pauseOnUnhandledExceptions: pauseOnUnhandledExceptions,
    );
  }
}

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invocation of the script.
Future<void> runVMTests(
  List<String> mainArgs,
  List<VMTest> tests,
  String scriptName, {
  Function()? testeeBefore,
  Function()? testeeConcurrent,
  bool pauseOnStart = false,
  bool pauseOnExit = false,
  bool verboseVm = false,
  bool pauseOnUnhandledExceptions = false,
  List<String>? extraArgs,
  VmServiceFactory serviceFactory = VmService.defaultFactory,
}) async {
  if (_isTestee()) {
    await _ServiceTesteeRunner().run(
      testeeBefore: testeeBefore,
      testeeConcurrent: testeeConcurrent,
      pauseOnStart: pauseOnStart,
      pauseOnExit: pauseOnExit,
    );
  } else {
    await _ServiceTesterRunner().run(
      mainArgs: mainArgs,
      scriptName: scriptName,
      extraArgs: extraArgs,
      vmTests: tests,
      pauseOnStart: pauseOnStart,
      pauseOnExit: pauseOnExit,
      verboseVm: verboseVm,
      pauseOnUnhandledExceptions: pauseOnUnhandledExceptions,
      serviceFactory: serviceFactory,
    );
  }
}
