// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.generics;

import 'dart:math' show min;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/type_algebra.dart' show Substitution;

bool hasInstantiatorTypeArguments(Class c) {
  for (; c != null; c = c.superclass) {
    if (c.typeParameters.isNotEmpty) {
      return true;
    }
  }
  return false;
}

bool _canReuseSuperclassTypeArguments(List<DartType> superTypeArgs,
    List<TypeParameter> typeParameters, int overlap) {
  for (int i = 0; i < overlap; ++i) {
    final superTypeArg = superTypeArgs[superTypeArgs.length - overlap + i];
    if (!(superTypeArg is TypeParameterType &&
        superTypeArg.parameter == typeParameters[i])) {
      return false;
    }
  }
  return true;
}

List<DartType> flattenInstantiatorTypeArguments(
    Class instantiatedClass, List<DartType> typeArgs) {
  final typeParameters = instantiatedClass.typeParameters;
  assert(typeArgs.length == typeParameters.length);

  final supertype = instantiatedClass.supertype;
  if (supertype == null) {
    return typeArgs;
  }

  final superTypeArgs = flattenInstantiatorTypeArguments(
      supertype.classNode, supertype.typeArguments);

  // Shrink type arguments by reusing portion of superclass type arguments
  // if there is an overlapping. This optimization should be consistent with
  // VM in order to correctly reuse instantiator type arguments.
  int overlap = min(superTypeArgs.length, typeArgs.length);
  for (; overlap > 0; --overlap) {
    if (_canReuseSuperclassTypeArguments(
        superTypeArgs, typeParameters, overlap)) {
      break;
    }
  }

  final substitution = Substitution.fromPairs(typeParameters, typeArgs);

  List<DartType> flatTypeArgs = <DartType>[];
  flatTypeArgs.addAll(superTypeArgs.map((t) => substitution.substituteType(t)));
  flatTypeArgs.addAll(typeArgs.getRange(overlap, typeArgs.length));

  return flatTypeArgs;
}

List<DartType> getInstantiatorTypeArguments(
    Class instantiatedClass, List<DartType> typeArgs) {
  final flatTypeArgs =
      flattenInstantiatorTypeArguments(instantiatedClass, typeArgs);
  if (_isAllDynamic(flatTypeArgs)) {
    return null;
  }
  return flatTypeArgs;
}

List<DartType> getDefaultFunctionTypeArguments(FunctionNode function) {
  List<DartType> defaultTypes = function.typeParameters
      .map((p) => p.defaultType ?? const DynamicType())
      .toList();
  if (_isAllDynamic(defaultTypes)) {
    return null;
  }
  return defaultTypes;
}

bool _isAllDynamic(List<DartType> typeArgs) {
  for (var t in typeArgs) {
    if (t != const DynamicType()) {
      return false;
    }
  }
  return true;
}

bool hasFreeTypeParameters(List<DartType> typeArgs) {
  final findTypeParams = new FindFreeTypeParametersVisitor();
  return typeArgs.any((t) => t.accept(findTypeParams));
}

class FindFreeTypeParametersVisitor extends DartTypeVisitor<bool> {
  Set<TypeParameter> _declaredTypeParameters;

  bool visit(DartType type) => type.accept(this);

  @override
  bool defaultDartType(DartType node) =>
      throw 'Unexpected type ${node.runtimeType} $node';

  @override
  bool visitInvalidType(InvalidType node) => false;

  @override
  bool visitDynamicType(DynamicType node) => false;

  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitBottomType(BottomType node) => false;

  @override
  bool visitTypeParameterType(TypeParameterType node) =>
      _declaredTypeParameters == null ||
      !_declaredTypeParameters.contains(node.parameter);

  @override
  bool visitInterfaceType(InterfaceType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitTypedefType(TypedefType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.typeParameters.isNotEmpty) {
      _declaredTypeParameters ??= new Set<TypeParameter>();
      _declaredTypeParameters.addAll(node.typeParameters);
    }

    final bool result = node.positionalParameters.any((t) => t.accept(this)) ||
        node.namedParameters.any((p) => p.type.accept(this)) ||
        node.returnType.accept(this);

    if (node.typeParameters.isNotEmpty) {
      _declaredTypeParameters.removeAll(node.typeParameters);
    }

    return result;
  }
}

/// Returns true if the given type is recursive after its type arguments
/// are flattened.
bool isRecursiveAfterFlattening(InterfaceType type) {
  final visitor = new IsRecursiveAfterFlatteningVisitor();
  visitor.visit(type);
  return visitor.isRecursive(type);
}

class IsRecursiveAfterFlatteningVisitor extends DartTypeVisitor<void> {
  Set<DartType> _visited = new Set<DartType>();
  List<DartType> _stack = <DartType>[];
  Set<DartType> _recursive;

  bool isRecursive(DartType type) =>
      _recursive != null && _recursive.contains(type);

  void visit(DartType type) {
    if (!_visited.add(type)) {
      _recordRecursiveType(type);
      return;
    }
    _stack.add(type);

    type.accept(this);

    _stack.removeLast();
    _visited.remove(type);
  }

  void _recordRecursiveType(DartType type) {
    final int start = _stack.lastIndexOf(type);
    final recursive = (_recursive ??= new Set<DartType>());
    for (int i = start; i < _stack.length; ++i) {
      recursive.add(_stack[i]);
    }
  }

  @override
  void defaultDartType(DartType node) =>
      throw 'Unexpected type ${node.runtimeType} $node';

  @override
  void visitInvalidType(InvalidType node) {}

  @override
  void visitDynamicType(DynamicType node) {}

  @override
  void visitVoidType(VoidType node) {}

  @override
  void visitBottomType(BottomType node) {}

  @override
  void visitTypeParameterType(TypeParameterType node) {}

  @override
  void visitInterfaceType(InterfaceType node) {
    for (var typeArg in node.typeArguments) {
      visit(typeArg);
    }
    if (isRecursive(node)) {
      return;
    }
    final flatTypeArgs =
        flattenInstantiatorTypeArguments(node.classNode, node.typeArguments);
    for (var typeArg in flatTypeArgs.getRange(
        0, flatTypeArgs.length - node.typeArguments.length)) {
      visit(typeArg);
    }
  }

  @override
  void visitTypedefType(TypedefType node) => visit(node.unalias);

  @override
  void visitFunctionType(FunctionType node) {
    for (var p in node.positionalParameters) {
      visit(p);
    }
    for (var p in node.namedParameters) {
      visit(p.type);
    }
    visit(node.returnType);
  }
}
