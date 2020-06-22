// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.generics;

import 'dart:math' show min;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart' show StaticTypeContext;

import 'options.dart' show BytecodeOptions;

bool hasInstantiatorTypeArguments(Class c) {
  for (; c != null; c = c.superclass) {
    if (c.typeParameters.isNotEmpty) {
      return true;
    }
  }
  return false;
}

List<DartType> getTypeParameterTypes(List<TypeParameter> typeParameters) {
  if (typeParameters.isEmpty) {
    return const <DartType>[];
  }
  final types = new List<DartType>(typeParameters.length);
  for (int i = 0; i < typeParameters.length; ++i) {
    final tp = typeParameters[i];
    types[i] = new TypeParameterType(
        tp, TypeParameterType.computeNullabilityFromBound(tp));
  }
  return types;
}

bool _canReuseSuperclassTypeArguments(List<DartType> superTypeArgs,
    List<TypeParameter> typeParameters, int overlap) {
  for (int i = 0; i < overlap; ++i) {
    final superTypeArg = superTypeArgs[superTypeArgs.length - overlap + i];
    final typeParam = typeParameters[i];
    if (!(superTypeArg is TypeParameterType &&
        superTypeArg.parameter == typeParameters[i] &&
        superTypeArg.nullability ==
            TypeParameterType.computeNullabilityFromBound(typeParam))) {
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

  assert(typeParameters.length == typeArgs.length);

  final substitution = Substitution.fromPairs(typeParameters, typeArgs);

  List<DartType> flatTypeArgs = <DartType>[];
  for (var type in superTypeArgs) {
    flatTypeArgs.add(substitution.substituteType(type));
  }
  flatTypeArgs.addAll(typeArgs.getRange(overlap, typeArgs.length));

  return flatTypeArgs;
}

List<DartType> getInstantiatorTypeArguments(
    Class instantiatedClass, List<DartType> typeArgs) {
  final flatTypeArgs =
      flattenInstantiatorTypeArguments(instantiatedClass, typeArgs);
  if (isAllDynamic(flatTypeArgs)) {
    return null;
  }
  return flatTypeArgs;
}

List<DartType> getDefaultFunctionTypeArguments(FunctionNode function) {
  final typeParameters = function.typeParameters;
  if (typeParameters.isEmpty) {
    return null;
  }
  bool dynamicOnly = true;
  for (var tp in typeParameters) {
    if (tp.defaultType != null && tp.defaultType != const DynamicType()) {
      dynamicOnly = false;
      break;
    }
  }
  if (dynamicOnly) {
    return null;
  }
  List<DartType> defaultTypes = <DartType>[];
  for (var tp in typeParameters) {
    defaultTypes.add(tp.defaultType ?? const DynamicType());
  }
  return defaultTypes;
}

bool isAllDynamic(List<DartType> typeArgs) {
  for (var t in typeArgs) {
    if (t != const DynamicType()) {
      return false;
    }
  }
  return true;
}

bool isInstantiatedGenericType(DartType type) =>
    (type is InterfaceType) &&
    type.typeArguments.isNotEmpty &&
    !hasFreeTypeParameters(type.typeArguments);

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
  bool visitNeverType(NeverType node) => false;

  @override
  bool visitTypeParameterType(TypeParameterType node) =>
      _declaredTypeParameters == null ||
      !_declaredTypeParameters.contains(node.parameter);

  @override
  bool visitInterfaceType(InterfaceType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitFutureOrType(FutureOrType node) => node.typeArgument.accept(this);

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

/// Returns static type of [expr].
DartType getStaticType(Expression expr, StaticTypeContext staticTypeContext) =>
    expr.getStaticType(staticTypeContext);

/// Returns `true` if [type] cannot be extended in user code.
bool isSealedType(DartType type, CoreTypes coreTypes) {
  if (type is InterfaceType) {
    final cls = type.classNode;
    return cls == coreTypes.intClass ||
        cls == coreTypes.doubleClass ||
        cls == coreTypes.boolClass ||
        cls == coreTypes.stringClass ||
        cls == coreTypes.nullClass;
  }
  return false;
}

/// Returns true if an instance call to [interfaceTarget] with given
/// [receiver] can omit argument type checks needed due to generic-covariant
/// parameters.
bool isUncheckedCall(Member interfaceTarget, Expression receiver,
    StaticTypeContext staticTypeContext) {
  if (interfaceTarget == null) {
    // Dynamic call cannot be unchecked.
    return false;
  }

  if (!_hasGenericCovariantParameters(interfaceTarget)) {
    // Unchecked call makes sense only if there are generic-covariant parameters.
    return false;
  }

  // Calls via [this] do not require checks.
  if (receiver is ThisExpression) {
    return true;
  }

  DartType receiverStaticType = getStaticType(receiver, staticTypeContext);
  if (receiverStaticType is InterfaceType) {
    final typeArguments = receiverStaticType.typeArguments;
    if (typeArguments.isEmpty) {
      return true;
    }

    final typeParameters = receiverStaticType.classNode.typeParameters;
    assert(typeArguments.length == typeParameters.length);
    for (int i = 0; i < typeArguments.length; ++i) {
      switch (typeParameters[i].variance) {
        case Variance.covariant:
          if (!isSealedType(
              typeArguments[i], staticTypeContext.typeEnvironment.coreTypes)) {
            return false;
          }
          break;
        case Variance.invariant:
          break;
        case Variance.contravariant:
          return false;
        default:
          throw 'Unexpected variance ${typeParameters[i].variance} of '
              '${typeParameters[i]} in ${receiverStaticType.classNode}';
      }
    }
    return true;
  }
  return false;
}

/// If receiver type at run time matches static type we can omit argument type
/// checks. This condition can be efficiently tested if static receiver type is
/// fully instantiated (e.g. doesn't have type parameters).
/// [isInstantiatedInterfaceCall] tests if an instance call to
/// [interfaceTarget] with given [staticReceiverType] may benefit from
/// this optimization.
bool isInstantiatedInterfaceCall(
    Member interfaceTarget, DartType staticReceiverType) {
  // Providing instantiated receiver type wouldn't help in case of a
  // dynamic call or call without any parameter type checks.
  if (interfaceTarget == null ||
      !_hasGenericCovariantParameters(interfaceTarget)) {
    return false;
  }
  return isInstantiatedGenericType(staticReceiverType);
}

bool _hasGenericCovariantParameters(Member target) {
  if (target is Field) {
    return target.isGenericCovariantImpl;
  } else if (target is Procedure) {
    for (var param in target.function.positionalParameters) {
      if (param.isGenericCovariantImpl) {
        return true;
      }
    }
    for (var param in target.function.namedParameters) {
      if (param.isGenericCovariantImpl) {
        return true;
      }
    }
    return false;
  } else {
    throw 'Unexpected instance call target ${target.runtimeType} $target';
  }
}

/// Returns true if invocation [node] is a closure call with statically known
/// function type. Such invocations can omit argument type checks.
bool isUncheckedClosureCall(MethodInvocation node,
        StaticTypeContext staticTypeContext, BytecodeOptions options) =>
    node.name.name == 'call' &&
    getStaticType(node.receiver, staticTypeContext) is FunctionType &&
    !options.avoidClosureCallInstructions;
