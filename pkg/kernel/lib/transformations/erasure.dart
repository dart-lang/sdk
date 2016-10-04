// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.erasure;

import '../ast.dart';
import '../type_algebra.dart';

/// Erases all function type parameter lists and replaces all uses of them with
/// their upper bounds.
///
/// This is a temporary measure to run strong mode code in the VM, which does
/// not yet support function type parameters.
///
/// This does not preserve dynamic type safety.
class Erasure extends Transformer {
  final Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};

  void transform(Program program) {
    program.accept(this);
  }

  @override
  visitDartType(DartType type) => substitute(type, substitution);

  @override
  visitProcedure(Procedure node) {
    if (node.kind == ProcedureKind.Factory) {
      assert(node.enclosingClass != null);
      assert(node.enclosingClass.typeParameters.length ==
          node.function.typeParameters.length);
      // Factories can have function type parameters as long as they correspond
      // exactly to those on the enclosing class.
      // Skip the visitFunctionNode but traverse body for local functions.
      node.function.transformChildren(this);
    } else {
      node.transformChildren(this);
    }
    return node;
  }

  @override
  visitFunctionNode(FunctionNode node) {
    for (var parameter in node.typeParameters) {
      substitution[parameter] = const DynamicType();
    }
    for (var parameter in node.typeParameters) {
      substitution[parameter] = substitute(parameter.bound, substitution);
    }
    node.transformChildren(this);
    node.typeParameters.forEach(substitution.remove);
    node.typeParameters.clear();
    return node;
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.target.kind != ProcedureKind.Factory) {
      node.arguments.types.clear();
    }
    node.transformChildren(this);
    return node;
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    node.arguments.types.clear();
    node.transformChildren(this);
    return node;
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    node.arguments.types.clear();
    node.transformChildren(this);
    return node;
  }
}
