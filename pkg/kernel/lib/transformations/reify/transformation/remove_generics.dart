// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.transformation.remove_generics;

import 'package:kernel/ast.dart';
import 'transformer.dart';

class Erasure extends Transformer with DartTypeVisitor<DartType> {
  final ReifyVisitor reifyVisitor;

  Erasure(this.reifyVisitor);

  bool removeTypeParameters(Class cls) {
    return reifyVisitor.needsTypeInformation(cls);
  }

  TreeNode removeTypeArgumentsOfConstructorCall(ConstructorInvocation node) {
    Class cls = node.target.parent;
    if (removeTypeParameters(cls)) {
      node.arguments.types.clear();
      Constructor target = node.target;
      target.enclosingClass.typeParameters.clear();
    }
    return node;
  }

  TreeNode removeTypeArgumentsOfStaticCall(StaticInvocation node) {
    if (node.target.parent is Class) {
      Class cls = node.target.parent;
      if (!removeTypeParameters(cls)) {
        return node;
      }
    } else {
      // If parent is a Library, then a global procedure is invoked, and it may
      // be a generic function, so we need to remove type arguments anyway.
      assert(node.target.parent is Library);
    }
    node.arguments.types.clear();
    Procedure target = node.target;
    target.function.typeParameters.clear();
    return node;
  }

  TreeNode removeTypeArgumentOfMethodInvocation(MethodInvocation node) {
    node.arguments.types.clear();
    return node;
  }

  @override
  defaultDartType(DartType type) => type;

  @override
  InterfaceType visitInterfaceType(InterfaceType type) {
    if (removeTypeParameters(type.classNode)) {
      return new InterfaceType(type.classNode, const <DartType>[]);
    }
    return type;
  }

  @override
  TypedefType visitTypedefType(TypedefType type) {
    throw 'Typedef types not implemented in erasure';
  }

  @override
  Supertype visitSupertype(Supertype type) {
    if (removeTypeParameters(type.classNode)) {
      return new Supertype(type.classNode, const <DartType>[]);
    }
    return type;
  }

  @override
  FunctionType visitFunctionType(FunctionType type) {
    bool partHasChanged = false;

    DartType translate(DartType type) {
      DartType newType = type.accept(this);
      if (newType != type) {
        partHasChanged = true;
        return newType;
      } else {
        return type;
      }
    }

    DartType returnType = translate(type.returnType);
    List<DartType> positionalTypes =
        type.positionalParameters.map(translate).toList();
    List<NamedType> namedParameters = new List<NamedType>();
    for (NamedType param in type.namedParameters) {
      namedParameters.add(new NamedType(param.name, translate(param.type)));
    }
    if (partHasChanged) {
      return new FunctionType(positionalTypes, returnType,
          namedParameters: namedParameters,
          requiredParameterCount: type.requiredParameterCount);
    } else {
      return type;
    }
  }

  @override
  DynamicType visitTypeParameterType(_) => const DynamicType();

  @override
  DartType visitDartType(DartType type) {
    return type.accept(this);
  }

  @override
  StaticInvocation visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    if (node.target.kind == ProcedureKind.Factory ||
        node.target.kind == ProcedureKind.Method) {
      node = removeTypeArgumentsOfStaticCall(node);
    }
    return node;
  }

  @override
  ConstructorInvocation visitConstructorInvocation(ConstructorInvocation node) {
    node.transformChildren(this);
    return removeTypeArgumentsOfConstructorCall(node);
  }

  @override
  Class visitClass(Class node) {
    node.transformChildren(this);
    if (removeTypeParameters(node)) {
      node.typeParameters.clear();
    }
    return node;
  }

  @override
  Expression visitMethodInvocation(MethodInvocation node) {
    node.transformChildren(this);
    return removeTypeArgumentOfMethodInvocation(node);
  }
}
