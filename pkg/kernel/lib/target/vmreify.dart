// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vmreify;

import '../ast.dart' show Program;
import '../core_types.dart' show CoreTypes;
import '../transformations/generic_types_reification.dart' as reify
    show transformProgram;
import 'targets.dart' show TargetFlags;
import 'vmcc.dart' as vmcc_target;

/// Specializes the kernel IR to the Dart VM with reified generic types.
class VmGenericTypesReifiedTarget extends vmcc_target.VmClosureConvertedTarget {
  VmGenericTypesReifiedTarget(TargetFlags flags) : super(flags);

  @override
  String get name => "vmreify";

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  List<String> get extraRequiredLibraries {
    return new List<String>.from(super.extraRequiredLibraries)
      ..add("${flags.kernelRuntime.resolve('reify/types.dart')}")
      ..add("${flags.kernelRuntime.resolve('reify/declarations.dart')}")
      ..add("${flags.kernelRuntime.resolve('reify/interceptors.dart')}");
  }

  @override
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {
    super.performGlobalTransformations(coreTypes, program);
    // TODO(dmitryas) this transformation should be made modular
    reify.transformProgram(coreTypes, program);
  }

  // Disable tree shaking for Generic Types Reification. There are some runtime
  // libraries that are required for the transformation and are shaken off,
  // because they aren't invoked from the program being transformed prior to
  // the transformation.
  // TODO(dmitryas): remove this when the libraries are in dart:_internal
  @override
  void performTreeShaking(CoreTypes coreTypes, Program program) {}
}
