// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions for the hot reload test suite.

import 'dart:convert';
import 'dart:developer' show Service;
import 'dart:io' as io;
import 'package:vm_service/vm_service.dart' show VmService, ReloadReport;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

import '../hot_reload_receipt.dart';

int get hotRestartGeneration =>
    throw Exception('Not implemented on this platform.');

Future<void> hotRestart() async =>
    throw Exception('Not implemented on this platform.');

int _reloadCounter = 0;
int get hotReloadGeneration => _reloadCounter;

HotReloadHelper? _hotReloadHelper;

Future<void> hotReload({bool expectRejection = false}) async {
  _hotReloadHelper ??= await HotReloadHelper.create();
  HotReloadReceipt reloadReceipt;
  if (expectRejection) {
    reloadReceipt = await _hotReloadHelper!._rejectNextGeneration();
  } else {
    _reloadCounter++;
    reloadReceipt = await _hotReloadHelper!._reloadNextGeneration();
  }
  // Write reload receipt with a leading tag to be recognized by the reload
  // suite runner and validated.
  print('${HotReloadReceipt.hotReloadReceiptTag}'
      '${jsonEncode(reloadReceipt.toJson())}');
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

  /// File name of a dill that contains compile time errors.
  ///
  /// We assume that this generation contained expected compile time errors and
  /// should be rejected at runtime.
  final String errorDillName;

  /// The current generation being executed by the VM.
  int generation = 0;

  HotReloadHelper._(this._vmService, this._id, this.testOutputDirUri,
      this.dillName, this.errorDillName);

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
    final dillName = dillUri.pathSegments.last;
    final errorDillName = dillName.replaceAll('.dill', '.error.dill');

    return HotReloadHelper._(
        vmService, id, dillUri.resolve('../'), dillName, errorDillName);
  }

  /// Trigger a hot-reload on the current isolate for the next generation.
  ///
  /// Also checks that the generation afterwards exists. If not, the VM service
  /// is disconnected to allow the VM to complete.
  Future<HotReloadReceipt> _reloadNextGeneration() async {
    generation += 1;
    final nextGenerationDillUri =
        testOutputDirUri.resolve('generation$generation/$dillName');
    print('Reloading: $nextGenerationDillUri');
    var reloadReport = await _vmService.reloadSources(_id,
        rootLibUri: nextGenerationDillUri.path);
    if (!reloadReport.success!) {
      throw Exception('Reload for generation $generation was rejected.\n'
          '${reloadReport.reasonForCancelling}');
    }
    var reloadReceipt = HotReloadReceipt(
      generation: generation,
      status: Status.accepted,
    );
    if (!hasNextGeneration) await cleanUp();
    return reloadReceipt;
  }

  Future<HotReloadReceipt> _rejectNextGeneration() async {
    generation += 1;
    HotReloadReceipt reloadReceipt;
    final errorDillFile = io.File.fromUri(
        testOutputDirUri.resolve('generation$generation/$errorDillName'));
    if (errorDillFile.existsSync()) {
      // This generation contained a compile time error that has already been
      // validated and should be rejected.
      reloadReceipt = HotReloadReceipt(
          generation: generation,
          status: Status.rejected,
          rejectionMessage: HotReloadReceipt.compileTimeErrorMessage);
    } else {
      final nextGenerationDillUri =
          testOutputDirUri.resolve('generation$generation/$dillName');
      print('Reloading (expecting rejection): $nextGenerationDillUri');
      final reloadReport = await _vmService.reloadSources(_id,
          rootLibUri: nextGenerationDillUri.path);
      if (reloadReport.success!) {
        throw Exception('Generation $generation was not rejected. Verify the '
            'calls of `hotReload(expectRejection: true)` in the test source '
            'match the rejected generation files.');
      }
      reloadReceipt = HotReloadReceipt(
        generation: generation,
        status: Status.rejected,
        rejectionMessage: reloadReport.reasonForCancelling,
      );
    }
    if (!hasNextGeneration) await cleanUp();
    return reloadReceipt;
  }

  bool get hasNextGeneration {
    final nextNextGenerationDirUri =
        testOutputDirUri.resolve('generation${generation + 1}');
    return io.Directory.fromUri(nextNextGenerationDirUri).existsSync();
  }

  Future<void> cleanUp() async => await _vmService.dispose();
}

/// Extension to expose the reason for a failed reload.
///
/// This is currently in the json response from the vm-service, but not exposed
/// as an API in [ReloadReport].
extension on ReloadReport {
  String? get reasonForCancelling {
    final notices = this.json?['notices'] as List?;
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
