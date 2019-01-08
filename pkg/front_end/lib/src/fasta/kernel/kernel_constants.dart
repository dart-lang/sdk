// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import 'package:kernel/ast.dart'
    show
        Constant,
        DartType,
        ListConstant,
        MapConstant,
        NullConstant,
        StaticInvocation,
        TreeNode;

import 'package:kernel/transformations/constants.dart'
    show ConstantsBackend, ErrorReporter;

import '../problems.dart' show unimplemented;

class KernelConstantsBackend extends ConstantsBackend {
  @override
  Constant lowerListConstant(ListConstant constant) => constant;

  @override
  Constant lowerMapConstant(MapConstant constant) => constant;

  @override
  Constant buildConstantForNative(
      String nativeName,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments,
      List<TreeNode> context,
      StaticInvocation node,
      ErrorReporter errorReporter,
      void abortEvaluation()) {
    // VM-specific names of the fromEnvironment factory constructors.
    if (nativeName == 'Bool_fromEnvironment' ||
        nativeName == 'Integer_fromEnvironment' ||
        nativeName == 'String_fromEnvironment') {
      return namedArguments['defaultValue'] ?? new NullConstant();
    }
    return unimplemented('constant evaluation of ${nativeName}',
        node.fileOffset, node.location.file);
  }
}
