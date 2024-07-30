// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:vm/modular/target/vm.dart' show VmTarget;

import 'macro_target.dart';

// Coverage-ignore(suite): Not run.
MacroConfiguration computeMacroConfiguration({Uri? targetSdkSummary}) {
  // Force the SDK summary to "vm_platform_strong.dill".
  // TODO(54404): make this sufficiently correct for all use cases.

  return new MacroConfiguration(
      target: new VmTarget(
          new TargetFlags(soundNullSafety: true, supportMirrors: false)),
      sdkSummary: _findSdkSummary(targetSdkSummary: targetSdkSummary));
}

// Coverage-ignore(suite): Not run.
Uri _findSdkSummary({Uri? targetSdkSummary}) {
  if (targetSdkSummary?.path == 'virtual_platform_kernel.dill') {
    return targetSdkSummary!;
  }
  // This makes it work in the incremental test suite.
  if (targetSdkSummary?.path == '/vm_platform_strong.dill') {
    return targetSdkSummary!;
  }

  // If the currently-running tool is in a Dart SDK folder, use the platform
  // dill from there. Failing that, try searching from the target dill.
  List<Directory> searchDirectories = [
    new File(Platform.resolvedExecutable).parent,
    if (targetSdkSummary != null && targetSdkSummary.isScheme("file"))
      new File.fromUri(targetSdkSummary).parent,
  ];

  for (Directory searchDirectory in searchDirectories) {
    Directory? sdkDirectory = _findSdkDirectoryAbove(searchDirectory);
    if (sdkDirectory != null) {
      File? maybeResult = _findPlatformDillUnder(sdkDirectory);
      if (maybeResult != null) return maybeResult.uri;
    }
  }

  // Maybe there's no Dart SDK folder at all, but some build system has put the
  // dill we need next to the target dill.
  if (targetSdkSummary != null) {
    File maybeResult =
        new File.fromUri(targetSdkSummary.resolve('./vm_platform_strong.dill'));
    if (maybeResult.existsSync()) return maybeResult.uri;
  }

  throw new StateError('Unable to find platform dill to build macros.');
}

// Coverage-ignore(suite): Not run.
// Looks for a directory `dart-sdk` in or above [directory].
Directory? _findSdkDirectoryAbove(Directory directory) {
  while (directory.parent.path != directory.path) {
    final Directory sdkDirectory =
        new Directory.fromUri(directory.uri.resolve('./dart-sdk'));
    if (sdkDirectory.existsSync()) return sdkDirectory;
    directory = directory.parent;
  }
  return null;
}

// Coverage-ignore(suite): Not run.
// Returns the `vm_platform_strong.dill` file under [sdkDirectory] if it
// exists, or `null` if not.
File? _findPlatformDillUnder(Directory sdkDirectory) {
  File maybeResult = new File.fromUri(
      sdkDirectory.uri.resolve('./lib/_internal/vm_platform_strong.dill'));
  return maybeResult.existsSync() ? maybeResult : null;
}
