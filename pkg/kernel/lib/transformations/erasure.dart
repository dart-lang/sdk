// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.erasure;

import '../ast.dart';
import '../type_algebra.dart';

/// This pass is a temporary measure to run strong mode code in the VM, which
/// does not yet have the necessary runtime support.
///
/// Function type parameter lists are cleared and all uses of a function type
/// parameter are replaced by its upper bound.
///
/// All uses of type parameters in constants are replaced by 'dynamic'.
///
/// This does not preserve dynamic type safety.
class Erasure extends Transformer {
  final Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
  final Map<TypeParameter, DartType> constantSubstitution =
      <TypeParameter, DartType>{};

  int constantContexts = 0;

  void transform(Program program) {
    program.accept(this);
  }

  void pushConstantContext() {
    ++constantContexts;
  }

  void popConstantContext() {
    --constantContexts;
  }

  bool get isInConstantContext => constantContexts > 0;

  @override
  visitDartType(DartType type) {
    type = substitute(type, substitution);
    if (isInConstantContext) {
      type = substitute(type, constantSubstitution);
    }
    return type;
  }

  @override
  visitClass(Class node) {
    for (var parameter in node.typeParameters) {
      constantSubstitution[parameter] = const DynamicType();
    }
    node.transformChildren(this);
    constantSubstitution.clear();
    return node;
  }

  @override
  visitProcedure(Procedure node) {
    if (node.kind == ProcedureKind.Factory) {
      assert(node.enclosingClass != null);
      assert(node.enclosingClass.typeParameters.length ==
          node.function.typeParameters.length);
      // Factories can have function type parameters as long as they correspond
      // exactly to those on the enclosing class. However, these type parameters
      // may still not be in a constant.
      for (var parameter in node.function.typeParameters) {
        constantSubstitution[parameter] = const DynamicType();
      }
      // Skip the visitFunctionNode but traverse body.
      node.function.transformChildren(this);
      node.function.typeParameters.forEach(constantSubstitution.remove);
    } else {
      node.transformChildren(this);
    }
    return node;
  }

  bool isObject(DartType type) {
    return type is InterfaceType && type.classNode.supertype == null;
  }

  @override
  visitFunctionNode(FunctionNode node) {
    for (var parameter in node.typeParameters) {
      substitution[parameter] = const DynamicType();
    }
    for (var parameter in node.typeParameters) {
      if (!isObject(parameter.bound)) {
        substitution[parameter] = substitute(parameter.bound, substitution);
      }
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
    if (node.isConst) pushConstantContext();
    node.transformChildren(this);
    if (node.isConst) popConstantContext();
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

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) pushConstantContext();
    node.transformChildren(this);
    if (node.isConst) popConstantContext();
    return node;
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) pushConstantContext();
    node.transformChildren(this);
    if (node.isConst) popConstantContext();
    return node;
  }

  @override
  visitMapLiteral(MapLiteral node) {
    if (node.isConst) pushConstantContext();
    node.transformChildren(this);
    if (node.isConst) popConstantContext();
    return node;
  }
}
