// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vm_precompiler;

import '../ast.dart' show Program;
import '../core_types.dart' show CoreTypes;
import '../transformations/precompiler.dart' as transformPrecompiler
    show transformProgram;
import 'targets.dart' show TargetFlags;
import 'vm.dart' show VmTarget;

/// Dart VM ahead-of-time compiler (a.k.a. precompiler) target.
/// This target relies on strong mode and whole-program analysis.
class VmPrecompilerTarget extends VmTarget {
  VmPrecompilerTarget(TargetFlags flags) : super(flags);

  @override
  String get name => "vm_precompiler";

  @override
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {
    super.performGlobalTransformations(coreTypes, program, logger: logger);

    if (strongMode) {
      transformPrecompiler.transformProgram(coreTypes, program);
    }
  }
}
