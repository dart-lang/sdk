// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/target/targets.dart' show Target, TargetFlags;

import 'unsupported_vm_target.dart'
    if (dart.library.io) 'package:vm/modular/target/vm.dart' show VmTarget;

MacroConfiguration computeMacroConfiguration({Uri? targetSdkSummary}) {
  // Force the SDK summary to "vm_platform_strong.dill".
  // TODO(54404): make this sufficiently correct for all use cases.

  Uri? sdkSummary;
  if ((targetSdkSummary == null ||
      targetSdkSummary.path == 'virtual_platform_kernel.dill' ||
      targetSdkSummary.path.contains('vm_platform_strong.dill'))) {
    sdkSummary = targetSdkSummary;
  } else if (targetSdkSummary.path.contains('/platform_strong.dill')) {
    // Flutter. Expecting the dill to be
    // bin/cache/artifacts/engine/common/flutter_patched_sdk/platform_strong.dill
    // and the Dart SDK to be under bin/cache/dart-sdk.
    sdkSummary = targetSdkSummary.resolve(
        './../../../../dart-sdk/lib/_internal/vm_platform_strong.dill');
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

class MacroConfiguration {
  final Target target;
  final Uri? sdkSummary;

  MacroConfiguration({required this.target, required this.sdkSummary});
}
