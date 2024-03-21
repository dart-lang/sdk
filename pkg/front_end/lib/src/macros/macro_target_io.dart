// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:vm/modular/target/vm.dart' show VmTarget;

import 'macro_target.dart';

MacroConfiguration computeMacroConfiguration({Uri? targetSdkSummary}) {
  // Force the SDK summary to "vm_platform_strong.dill".
  // TODO(54404): make this sufficiently correct for all use cases.

  Uri? sdkSummary;

  if ((targetSdkSummary == null ||
      targetSdkSummary.path == 'virtual_platform_kernel.dill' ||
      targetSdkSummary.path.contains('vm_platform_strong.dill'))) {
    sdkSummary = targetSdkSummary;
  } else if (targetSdkSummary.path.contains('/flutter_patched_sdk/') ||
      targetSdkSummary.path.contains('/flutter_web_sdk/')) {
    // Flutter. Expecting the Flutter dill to be one of
    //
    //   flutter_patched_sdk/platform_strong.dill
    //   flutter_web_sdk/kernel/ddc_outline_sound.dill
    //
    // and the Dart SDK to be in a subdirectory `dart-sdk` above that.
    //
    // If not found leave `sdkSummary` as `null`.
    Directory directory = new Directory.fromUri(targetSdkSummary.resolve('.'));
    while (directory.parent != directory) {
      final Directory sdkDirectory =
          new Directory.fromUri(directory.uri.resolve('./dart-sdk'));
      if (sdkDirectory.existsSync()) {
        sdkSummary =
            sdkDirectory.uri.resolve('./lib/_internal/vm_platform_strong.dill');
        break;
      }
      directory = directory.parent;
    }
  } else {
    // Non-VM target platform, not Flutter. Find the platform dill next to the
    // non-VM platform dill.
    sdkSummary = targetSdkSummary.resolve('./vm_platform_strong.dill');
  }

  return new MacroConfiguration(
      target: new VmTarget(
          new TargetFlags(soundNullSafety: true, supportMirrors: false)),
      sdkSummary: sdkSummary);
}
