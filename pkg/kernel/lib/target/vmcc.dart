// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vmcc;

import '../ast.dart' show Program;
import '../core_types.dart' show CoreTypes;
import '../transformations/closure_conversion.dart' as cc show transformProgram;
import 'targets.dart' show TargetFlags;
import 'vm.dart' as vm_target;

class VmClosureConvertedTarget extends vm_target.VmTarget {
  VmClosureConvertedTarget(TargetFlags flags) : super(flags);

  @override
  String get name => "vmcc";

  @override
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {
    super.performGlobalTransformations(coreTypes, program);
    cc.transformProgram(coreTypes, program);
  }
}
