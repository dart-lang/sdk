// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'coverage_helper.dart';
import 'vm_service_helper.dart' as vmService;

Future<void> main(List<String> args) async {
  CoverageHelper coverageHelper = new CoverageHelper();

  List<String> allArgs = <String>[];
  allArgs.addAll([
    "--disable-dart-dev",
    "--enable-asserts",
    "--pause_isolates_on_exit",
  ]);
  allArgs.addAll(args);

  await coverageHelper.start(allArgs);
}

class CoverageHelper extends vmService.LaunchingVMServiceHelper {
  final bool forceCompilation;
  final bool printHits;

  CoverageHelper({this.forceCompilation = false, this.printHits = true});

  @override
  Future<void> run() async {
    vmService.VM vm = await serviceClient.getVM();
    if (vm.isolates!.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates!.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates!.single;
    await waitUntilIsolateIsRunnable(isolateRef.id!);
    await serviceClient.resume(isolateRef.id!);
    Completer<String> cTimeout = new Completer();
    Timer timer = new Timer(new Duration(minutes: 20), () {
      cTimeout.complete("Timeout");
      killProcess();
    });

    Completer<String> cRunDone = new Completer();
    // ignore: unawaited_futures
    waitUntilPaused(isolateRef.id!).then((value) => cRunDone.complete("Done"));

    await Future.any([cRunDone.future, cTimeout.future, cProcessExited.future]);

    timer.cancel();

    if (!await isPausedAtExit(isolateRef.id!)) {
      killProcess();
      throw "Expected to be paused at exit, but is just paused!";
    }

    // Get and process coverage information.
    Stopwatch stopwatch = new Stopwatch()..start();
    vmService.SourceReport sourceReport = await serviceClient.getSourceReport(
        isolateRef.id!, [vmService.SourceReportKind.kCoverage],
        forceCompile: forceCompilation);
    print("Got source report from VM in ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();
    Coverage coverage =
        getCoverageFromSourceReport([sourceReport], includeCoverageFor);

    // It's paused at exit, so resuming should allow us to exit.
    await serviceClient.resume(isolateRef.id!);

    coverage.printCoverage(printHits);
  }

  bool includeCoverageFor(Uri uri) {
    if (uri.isScheme("dart")) {
      return false;
    }
    if (uri.isScheme("package")) {
      return uri.pathSegments.first == "front_end" ||
          uri.pathSegments.first == "_fe_analyzer_shared" ||
          uri.pathSegments.first == "kernel";
    }
    return true;
  }

  Completer<String> cProcessExited = new Completer();
  @override
  void processExited(int exitCode) {
    cProcessExited.complete("Exit");
  }
}
