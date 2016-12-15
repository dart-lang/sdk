// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.converter;

import '../../ast.dart' show DartType, FunctionNode, TreeNode, TypeParameter;

import '../../clone.dart' show CloneVisitor;

class CloneWithoutBody extends CloneVisitor {
  CloneWithoutBody({Map<TypeParameter, DartType> typeSubstitution})
      : super(typeSubstitution: typeSubstitution);

  @override
  TreeNode cloneFunctionNodeBody(FunctionNode node) => null;
}
