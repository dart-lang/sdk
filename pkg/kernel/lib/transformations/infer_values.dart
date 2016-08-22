// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.infer_types;

import '../ast.dart';
import '../type_propagation/type_propagation.dart';

Program transformProgram(Program program) {
  TypePropagation propagation = new TypePropagation(program);

  var attacher = new InferredValueAttacher(propagation, program);
  attacher.attachInferredValues();

  return program;
}

class InferredValueAttacher extends RecursiveVisitor {
  final TypePropagation propagation;
  final Program program;

  InferredValueAttacher(this.propagation, this.program);

  attachInferredValues() => program.accept(this);

  visitField(Field node) {
    node.inferredValue = propagation.getFieldValue(node);
    super.visitField(node);
  }

  visitFunctionNode(FunctionNode node) {
    node.positionalParameters.forEach(_annotateVariableDeclaration);
    node.namedParameters.forEach(_annotateVariableDeclaration);
    node.inferredReturnValue = propagation.getReturnValue(node);
    super.visitFunctionNode(node);
  }

  _annotateVariableDeclaration(VariableDeclaration variable) {
    variable.inferredValue = propagation.getParameterValue(variable);
  }
}
