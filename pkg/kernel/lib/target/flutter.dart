// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.flutter;

import '../ast.dart';
import '../transformations/continuation.dart' as cont;
import '../transformations/erasure.dart';
import '../transformations/sanitize_for_vm.dart';
import '../transformations/mixin_full_resolution.dart' as mix;
import '../transformations/setup_builtin_library.dart' as setup_builtin_library;
import 'targets.dart';

class FlutterTarget extends Target {
  final TargetFlags flags;

  FlutterTarget(this.flags);

  bool get strongMode => flags.strongMode;

  bool get strongModeSdk => false;

  String get name => 'flutter';

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
        'dart:_vmservice',
        'dart:_builtin',
        'dart:nativewrappers',
        'dart:io',

        // Required for flutter.
        'dart:ui',
        'dart:vmservice_sky',
      ];

  void performModularTransformations(Program program) {
    new mix.MixinFullResolution(this).transform(program);
  }

  void performGlobalTransformations(Program program) {
    cont.transformProgram(program);

    // Repair `_getMainClosure()` function in dart:{_builtin,ui} libraries.
    setup_builtin_library.transformProgram(program);
    setup_builtin_library.transformProgram(program, libraryUri: 'dart:ui');

    if (strongMode) {
      new Erasure().transform(program);
    }

    new SanitizeForVM().transform(program);
  }

  @override
  Expression instantiateInvocation(Member target, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    // TODO(ahe): This should probably return the same as VmTarget does.
    return new InvalidExpression();
  }
}
