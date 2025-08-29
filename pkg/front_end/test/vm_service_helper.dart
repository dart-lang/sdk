// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";

import "package:vm_service/vm_service.dart" as vmService;
import "package:vm_service/vm_service_io.dart" as vmService;

export "package:vm_service/vm_service.dart";
export "package:vm_service/vm_service_io.dart";

class VMServiceHelper {
  late vmService.VmService _serviceClient;
  vmService.VmService get serviceClient => _serviceClient;

  VMServiceHelper();

  Future connect(Uri observatoryUri) async {
    String path = observatoryUri.path;
    if (!path.endsWith("/")) path += "/";
    String wsUriString = 'ws://${observatoryUri.authority}${path}ws';
    _serviceClient = await vmService.vmServiceConnectUri(
      wsUriString,
      log: const StdOutLog(),
    );
  }

  Future disconnect() async {
    await _serviceClient.dispose();
  }

  Future<void> resumeAllIsolates() async {
    vmService.VM vm = await serviceClient.getVM();
    for (vmService.IsolateRef isolate in vm.isolates!) {
      try {
        await serviceClient.resume(isolate.id!);
      } catch (e) {
        // It might exit at some point so we can't expect to get a good result.
      }
    }
  }

  Future<void> waitUntilSomeIsolatePausedAtExit() async {
    while (true) {
      vmService.VM vm = await serviceClient.getVM();
      if (vm.isolates!.isNotEmpty) {
        for (vmService.IsolateRef isolate in vm.isolates!) {
          String isolateId = isolate.id!;
          if (await isPausedAtExit(isolateId) == true) {
            return;
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<bool> waitUntilPaused(String isolateId) async {
    int nulls = 0;
    int tries = 0;
    while (true) {
      tries++;
      bool? result = await isPaused(isolateId);
      if (result == null) {
        nulls++;
        if (nulls > 5) {
          // We've now asked for the isolate 5 times and in all cases gotten
          // `Sentinel`. Most likely things aren't working for whatever reason.
          return false;
        }
      } else if (result) {
        return true;
      } else {
        if (tries > 50) {
          // Waited 5+ seconds --- check if some isolate is paused at start
          // and resume if it is. This is for instance the case with macros.
          await _resumeAllPausedAtStartIsolates();
          tries = 0;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _resumeAllPausedAtStartIsolates() async {
    vmService.VM vm = await serviceClient.getVM();
    for (vmService.IsolateRef isolateRef in vm.isolates!) {
      try {
        String? id = isolateRef.id;
        if (id == null) continue;
        vmService.Isolate isolate = await _serviceClient.getIsolate(id);
        if (isolate.pauseEvent?.kind == "PauseStart") {
          print("Found isolate paused at start - resuming it.");
          await serviceClient.resume(id);
        }
      } catch (e) {
        // It might exit at some point so we can't expect to get a good result.
      }
    }
  }

  Future<bool?> isPaused(String isolateId) async {
    vmService.Isolate isolate = await _serviceClient.getIsolate(isolateId);
    String? kind = isolate.pauseEvent!.kind;
    if (kind != "Resume" && kind != "None") return true;
    return false;
  }

  Future<bool> isPausedAtStart(String isolateId) async {
    dynamic tmp = await _serviceClient.getIsolate(isolateId);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.pauseEvent!.kind == "PauseStart";
    }
    return false;
  }

  Future<bool> isPausedAtExit(String isolateId) async {
    vmService.Isolate isolate = await _serviceClient.getIsolate(isolateId);
    return isolate.pauseEvent!.kind == "PauseExit";
  }

  Future<vmService.AllocationProfile> forceGC(String isolateId) async {
    await waitUntilIsolateIsRunnable(isolateId);
    int expectGcAfter = new DateTime.now().millisecondsSinceEpoch;
    while (true) {
      vmService.AllocationProfile allocationProfile;
      try {
        allocationProfile = await _serviceClient.getAllocationProfile(
          isolateId,
          gc: true,
        );
      } catch (e) {
        print(e.runtimeType);
        rethrow;
      }
      if (allocationProfile.dateLastServiceGC != null &&
          allocationProfile.dateLastServiceGC! >= expectGcAfter) {
        return allocationProfile;
      }
    }
  }

  Future<bool?> isIsolateRunnable(String isolateId) async {
    dynamic tmp = await _serviceClient.getIsolate(isolateId);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.runnable;
    }
    return null;
  }

  Future<void> waitUntilIsolateIsRunnable(String isolateId) async {
    int nulls = 0;
    while (true) {
      bool? result = await isIsolateRunnable(isolateId);
      if (result == null) {
        nulls++;
        if (nulls > 5) {
          // We've now asked for the isolate 5 times and in all cases gotten
          // `Sentinel`. Most likely things aren't working for whatever reason.
          return;
        }
      } else if (result) {
        return;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<String> getIsolateId() async {
    vmService.VM vm = await _serviceClient.getVM();
    if (vm.isolates!.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates!.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates!.single;
    return isolateRef.id!;
  }
}

class StdOutLog implements vmService.Log {
  const StdOutLog();

  @override
  void severe(String message) {
    print("> SEVERE: $message");
  }

  @override
  void warning(String message) {
    print("> WARNING: $message");
  }
}

abstract class LaunchingVMServiceHelper extends VMServiceHelper {
  late Process _process;
  Process get process => _process;

  bool _started = false;

  Future<void> start(
    List<String> scriptAndArgs, {
    void Function(String line)? stdoutReceiver,
    void Function(String line)? stderrReceiver,
    bool pauseIsolateOnStart = true,
  }) async {
    if (_started) throw "Already started";
    _started = true;
    _process = await Process.start(Platform.resolvedExecutable, [
      if (pauseIsolateOnStart) "--pause_isolates_on_start",
      "--enable-vm-service=0",
      ...scriptAndArgs,
    ]);
    _process.stdout
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((line) {
          const kDartVMServiceListening =
              'The Dart VM service is listening on ';
          if (line.startsWith(kDartVMServiceListening)) {
            Uri observatoryUri = Uri.parse(
              line.substring(kDartVMServiceListening.length),
            );
            _setupAndRun(observatoryUri).catchError((e, st) {
              // Manually kill the process or it will leak,
              // see http://dartbug.com/42918
              killProcess();
              // This seems to rethrow.
              throw e;
            });
          }
          if (stdoutReceiver != null) {
            stdoutReceiver(line);
          } else {
            stdout.writeln("> $line");
          }
        });
    _process.stderr
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((line) {
          if (stderrReceiver != null) {
            stderrReceiver(line);
          } else {
            stderr.writeln("> $line");
          }
        });
    // ignore: unawaited_futures
    _process.exitCode.then((value) {
      processExited(value);
    });
  }

  Future<void> startWithoutRunning(Uri observatoryUri) async {
    if (_started) throw "Already started";
    _started = true;
    await _setupAndRun(observatoryUri);
  }

  void processExited(int exitCode) {}

  void killProcess() {
    _process.kill();
  }

  Future _setupAndRun(Uri observatoryUri) async {
    await connect(observatoryUri);
    await run();
  }

  Future<void> run();
}
