// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vm;

import '../ast.dart';
import '../transformations/continuation.dart' as cont;
import '../transformations/erasure.dart';
import '../transformations/mixin_full_resolution.dart' as mix;
import '../transformations/sanitize_for_vm.dart';
import '../transformations/setup_builtin_library.dart' as setup_builtin_library;
import 'targets.dart';

/// Specializes the kernel IR to the Dart VM.
class VmTarget extends Target {
  final TargetFlags flags;

  VmTarget(this.flags);

  bool get strongMode => flags.strongMode;

  /// The VM patch files are not strong mode clean, so we adopt a hybrid mode
  /// where the SDK is internally unchecked, but trusted to satisfy the types
  /// declared on its interface.
  bool get strongModeSdk => false;

  String get name => 'vm';

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  List<String> get extraRequiredLibraries => const <String>[
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:developer',
        'dart:_internal',
        'dart:isolate',
        'dart:math',

        // The library dart:mirrors may be ignored by the VM, e.g. when built in
        // PRODUCT mode.
        'dart:mirrors',

        'dart:profiler',
        'dart:typed_data',
        'dart:vmservice_io',
        'dart:_vmservice',
        'dart:_builtin',
        'dart:nativewrappers',
        'dart:io',
      ];

  void transformProgram(Program program) {
    new mix.MixinFullResolution().transform(program);
    cont.transformProgram(program);

    // Repair `_getMainClosure()` function in dart:_builtin.
    setup_builtin_library.transformProgram(program);

    if (strongMode) {
      new Erasure().transform(program);
    }

    new SanitizeForVM().transform(program);
  }
}
