// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to wrap a program and run it repeatedly triggering a hot-reload
/// between runs. This is used for trying out hot reload behavior with little
/// setup involved.
///
/// To use this logic, create a program that you wish to test with hot-reload,
/// and call `run` wrapping a top-level method tearoff, which contains the logic
/// of the program.  For example:
///
/// ```dart
/// import 'hot_reload_helper.dart' as helper;
///
/// example() async {
///   print('hello world');
/// }
///
/// main() => helper.run(example);
/// ```
///
/// Then launch this program with a special VM flag to enable the vm service,
/// which adds the necessary mechanism to support hot reloads:
///
/// ```
/// out/ReleaseX64/dart --disable-dart-dev --enable-vm-service example.dart
/// ```
///
/// The program will run `example` once and wait for you to hit `<enter>` before
/// performing a hot reload and rerunning the `example` method again.
library;

import 'dart:developer';
import 'dart:io' as io;
import 'package:vm_service/vm_service.dart' show VmService, ReloadReport;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

/// Runs [program] repeatedly after each request to do a hot reload.  If the
/// reload fails, it prints to stdout the reason for the failure.
Future<void> run(Function() program) async {
  final helper = await HotReloadHelper.create();
  const yellow = '\x1b[33m';
  const green = '\x1b[32m';
  var iteration = 0;

  while (true) {
    iteration++;
    try {
      await program();
    } catch (e, s) {
      print('$e\n$s');
    }
    _colorLine('(iteration $iteration done, press <enter> to reload)', green);

    var success = false;
    while (!success) {
      var line = io.stdin.readLineSync();
      if (line == null) break;
      final result = await helper.reload();
      if (result.success ?? false) {
        success = true;
      } else {
        _colorLine('reload failed:', yellow);
        print(result.reasonForCancelling);
        _colorLine('(press <enter> to try again)', yellow);
      }
    }
  }
}

/// Helper to mediate with the vm service protocol.
///
/// Contains logic to initiate a connection with the vm service protocol on the
/// Dart VM running the current program and for requesting a hot-reload request
/// on the current isolate.
class HotReloadHelper {
  final String _id;
  final VmService _vmService;

  HotReloadHelper._(this._vmService, this._id);

  /// Create a helper that is bound to the current VM and isolate.
  static Future<HotReloadHelper> create() async {
    final info =
        await Service.controlWebServer(enable: true, silenceOutput: true);
    final observatoryUri = info.serverUri;
    if (observatoryUri == null) {
      print('Error: no VM service found. '
          'Please invoke dart with `--enable-vm-service`.');
      io.exit(1);
    }
    final wsUri = 'ws://${observatoryUri.authority}${observatoryUri.path}ws';
    final vmService = await vm_service_io.vmServiceConnectUri(wsUri);
    final vm = await vmService.getVM();
    final id =
        vm.isolates!.firstWhere((isolate) => !isolate.isSystemIsolate!).id!;
    return HotReloadHelper._(vmService, id);
  }

  /// Triggter a hot-reload on the current isolate.
  Future<ReloadReport> reload() => _vmService.reloadSources(_id);
}

/// Extension to expose the reason for a failed reload.
///
/// This is currently in the json response from the vm-service, but not exposed
/// as an API in [ReloadReport].
extension on ReloadReport {
  String? get reasonForCancelling {
    final notices = json?['notices'] as List?;
    if (notices != null) {
      for (final notice in notices) {
        if (notice['type'] == 'ReasonForCancelling') {
          return notice['message'] as String?;
        }
      }
    }
    return null;
  }
}

void _colorLine(String message, String color) {
  const none = '\x1b[0m';
  print('$color${'--' * 20} $message$none');
}
