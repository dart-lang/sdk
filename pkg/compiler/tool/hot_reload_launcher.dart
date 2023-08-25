// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper script to run keep dart2js in memory and trigger a hot-reload between
/// runs. This can speed up iterating on compiler changes, while still working
/// with the compiler sources.
///
/// Usage: launch with a special VM flag to enable the vm service, which adds
/// the necessary mechanism to support hot reloads, and passing all arguments
/// that will be forwarded to dart2js:
///
/// ```
/// out/ReleaseX64/dart --disable-dart-dev --enable-vm-service \
///     pkg/compiler/tool/hot_reload_launcher.dart <dart2js-args>
/// ```
///
/// This will do one compile immediately. After it completes, the process will
/// wait for additional input. On every new-line entered (text is ignored), it
/// will trigger a hot reload to refresh the compiler, then reexecute the
/// compiler with the exact same args provided upfront.
import 'dart:developer';
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

import 'dart:io' as io;

import 'package:compiler/src/dart2js.dart' as p;

int iteration = 0;

main(List<String> args) async {
  try {
    if (io.Platform.isLinux) {
      // Calculate how long it took for the process to reach main, this gives us
      // an estimate of how long it takes to compile dart2js and load it.
      final result = io.Process.runSync(
          'ps', ['--pid', '${io.pid}', '-D', '%F %T', '-o', 'lstart=']);
      final startTimeString = (result.stdout as String).trim();
      final startTime = DateTime.parse(startTimeString);
      final currentTime = DateTime.now();
      final diff = currentTime.difference(startTime).inMilliseconds;
      print('${'--' * 20} (compiler loaded: ${diff}ms)');
    }
  } catch (e) {
    print('Warning: couldn\'t compute load time [$e]');
  }
  final info =
      await Service.controlWebServer(enable: true, silenceOutput: true);
  final observatoryUri = info.serverUri;
  if (observatoryUri == null) {
    print('Error: VM service not found. Make sure to invoke the '
        'Dart VM with the `--enable-vm-service` flag');
    io.exit(1);
  }
  final wsUri = 'ws://${observatoryUri.authority}${observatoryUri.path}ws';
  final vmService = await vm_service_io.vmServiceConnectUri(wsUri);
  final vm = await vmService.getVM();
  final id =
      vm.isolates!.firstWhere((isolate) => !isolate.isSystemIsolate!).id!;

  // Override exitFunc to prevent the defualt behavior (a process exit).
  p.exitFunc = (code) {
    throw "Exit with code $code";
  };

  Stopwatch watch = Stopwatch()..start();
  while (true) {
    print('${'--' * 20} (iteration: $iteration, '
        'rebuild time: ${watch.elapsedMilliseconds}ms)');
    iteration++;
    try {
      await p.compilerMain(args);
    } catch (e, s) {
      print('$e\n$s');
    }
    print('${'--' * 20} (done, please <enter> to compile again) ');
    var line = io.stdin.readLineSync();
    if (line == null) break;
    watch.reset();
    vmService.reloadSources(id);
  }
}
