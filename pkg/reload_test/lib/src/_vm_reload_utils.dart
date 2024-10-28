// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions for the hot reload test suite.

import 'dart:developer' show Service;
import 'dart:io' as io;
import 'package:vm_service/vm_service.dart' show VmService, ReloadReport;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

int get hotRestartGeneration =>
    throw Exception('Not implemented on this platform.');

Future<void> hotRestart() async =>
    throw Exception('Not implemented on this platform.');

int _reloadCounter = 0;
int get hotReloadGeneration => _reloadCounter;

HotReloadHelper? _hotReloadHelper;

Future<void> hotReload() async {
  _hotReloadHelper ??= await HotReloadHelper.create();
  _reloadCounter++;
  await _hotReloadHelper!.reloadNextGeneration();
}

/// Helper to mediate with the vm service protocol.
///
/// Contains logic to initiate a connection with the vm service protocol on the
/// Dart VM running the current program and for requesting a hot-reload request
/// on the current isolate.
///
/// Adapted from:
/// https://github.com/dart-lang/sdk/blob/dbcf24cedbe4d3a8eccaa51712f0c98b92173ad2/pkg/dev_compiler/tool/hotreload/hot_reload_helper.dart#L77
class HotReloadHelper {
  /// ID for the isolate running the test.
  final String _id;
  final VmService _vmService;

  /// The output directory under which generation directories are saved.
  final Uri testOutputDirUri;

  /// File name of the dill (full or fragment) to be reloaded.
  ///
  /// We assume that:
  /// * Every generation only loads one dill
  /// * All dill files have the same name across every generation
  final String dillName;

  /// The current generation being executed by the VM.
  int generation = 0;

  HotReloadHelper._(
      this._vmService, this._id, this.testOutputDirUri, this.dillName);

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
    final currentIsolateGroup = vm.isolateGroups!
        .firstWhere((isolateGroup) => !isolateGroup.isSystemIsolateGroup!);
    final dillUri = Uri.file(currentIsolateGroup.name!);
    final generationPart =
        dillUri.pathSegments[dillUri.pathSegments.length - 2];

    if (!generationPart.startsWith('generation')) {
      print('Error: Unable to find generation in dill file: $dillUri.');
      io.exit(1);
    }

    return HotReloadHelper._(
        vmService, id, dillUri.resolve('../'), dillUri.pathSegments.last);
  }

  /// Trigger a hot-reload on the current isolate for the next generation.
  ///
  /// Also checks that the generation aftewards exists. If not, the VM service
  /// is disconnected to allow the VM to complete.
  Future<ReloadReport> reloadNextGeneration() async {
    generation += 1;
    final nextGenerationDillUri =
        testOutputDirUri.resolve('generation$generation/$dillName');
    print('Reloading: $nextGenerationDillUri');
    var reloadReport = await _vmService.reloadSources(_id,
        rootLibUri: nextGenerationDillUri.path);
    final nextNextGenerationDillUri =
        testOutputDirUri.resolve('generation${generation + 1}/$dillName');
    final hasNextNextGeneration =
        io.File.fromUri(nextNextGenerationDillUri).existsSync();
    if (!hasNextNextGeneration) {
      await _vmService.dispose();
    }
    return reloadReport;
  }
}
