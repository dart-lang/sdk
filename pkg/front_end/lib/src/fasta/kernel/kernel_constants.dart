// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import 'package:kernel/ast.dart'
    show
        Constant,
        DartType,
        EnvironmentBoolConstant,
        EnvironmentIntConstant,
        EnvironmentStringConstant,
        ListConstant,
        MapConstant,
        NullConstant,
        StaticInvocation,
        StringConstant,
        TreeNode;

import 'package:kernel/transformations/constants.dart'
    show ConstantsBackend, ErrorReporter;

import '../problems.dart' show unexpected, unimplemented;

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
      if (positionalArguments.length == 1 &&
          positionalArguments.first is StringConstant &&
          (namedArguments.length == 0 ||
              (namedArguments.length == 1 &&
                  namedArguments.containsKey('defaultValue')))) {
        StringConstant name = positionalArguments.first;
        Constant defaultValue =
            namedArguments['defaultValue'] ?? new NullConstant();
        if (nativeName == 'Bool_fromEnvironment') {
          return new EnvironmentBoolConstant(name.value, defaultValue);
        }
        if (nativeName == 'Integer_fromEnvironment') {
          return new EnvironmentIntConstant(name.value, defaultValue);
        }
        return new EnvironmentStringConstant(name.value, defaultValue);
      }
      return unexpected('valid constructor invocation', node.toString(),
          node.fileOffset, node.location.file);
    }
    return unimplemented('constant evaluation of ${nativeName}',
        node.fileOffset, node.location.file);
  }
}
