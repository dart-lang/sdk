// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.flutter;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../transformations/continuation.dart' as cont;
import '../transformations/erasure.dart';
import '../transformations/mixin_full_resolution.dart' as mix;
import '../transformations/sanitize_for_vm.dart';
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
        'dart:nativewrappers',
        'dart:io',

        // Required for flutter.
        'dart:ui',
      ];

  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {
    mix.transformLibraries(this, coreTypes, hierarchy, libraries);
  }

  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {
    cont.transformProgram(coreTypes, program);

    if (strongMode) {
      new Erasure().transform(program);
    }

    new SanitizeForVM().transform(program);
  }

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    // TODO(ahe): This should probably return the same as VmTarget does.
    return new InvalidExpression();
  }

  @override
  Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    // TODO(ahe): This should probably return the same as VmTarget does.
    return new InvalidExpression();
  }
}
