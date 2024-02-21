// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../test/coverage_helper.dart';
import '../test/vm_service_helper.dart';

Uri? coverageUri;

Future<void> main(final List<String> args) async {
  String? coverage = Platform.environment["CFE_COVERAGE"];
  if (coverage != null) {
    coverageUri = Uri.base.resolveUri(Uri.file(coverage));
  } else {
    throw "Set coverage path via 'CFE_COVERAGE' environment!";
  }

  MyLaunchingVMServiceHelper launchingHelper =
      new MyLaunchingVMServiceHelper(args);
  await launchingHelper.start(
    [
      "--pause_isolates_on_exit",
      "--disable-dart-dev",
      ...args,
    ],
    pauseIsolateOnStart: false,
  );
  await launchingHelper.exitCompleter.future;
}

class MyLaunchingVMServiceHelper extends LaunchingVMServiceHelper {
  final List<String> args;
  final Completer<int> exitCompleter = new Completer<int>();

  MyLaunchingVMServiceHelper(this.args);

  @override
  void processExited(int code) {
    exitCode = code;
    exitCompleter.complete(code);
  }

  @override
  Future<void> run() async {
    // TODO(jensj): Get coverage for the isolate paused at exit, then resume
    // that one, continue until there's no more isolates left.
    // E.g. for pkg/front_end/tool/coverage_runner.dart.
    await waitUntilSomeIsolatePausedAtExit();

    Coverage? coverage = await collectCoverageWithHelper(
      helper: this,
      getKernelServiceCoverageToo: true,
      displayName: args.join(" "),
    );
    if (coverage != null) {
      File f = new File.fromUri(coverageUri!.resolve("coverage_run_"
          "${DateTime.now().microsecondsSinceEpoch}_"
          "${process.pid}.coverage"));
      coverage.writeToFile(f);
    }

    await resumeAllIsolates();
    try {
      while (true) {
        VM vm = await serviceClient.getVM();
        List<IsolateRef> isolates = vm.isolates!;
        if (isolates.isEmpty) break;
        for (IsolateRef isolate in isolates) {
          try {
            if (await isPaused(isolate.id!) == true) {
              await serviceClient.resume(isolate.id!);
            }
          } catch (e) {
            // It might exit at some point so we can't expect to get
            // a good result.
          }
        }
      }
    } catch (e) {
      // Assume this is a good thing.
    }
  }
}
