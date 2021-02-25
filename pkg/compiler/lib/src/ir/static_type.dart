// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import '../common/names.dart';
import '../util/util.dart';
import 'runtime_type_analysis.dart';
import 'scope.dart';
import 'static_type_base.dart';
import 'static_type_cache.dart';
import 'util.dart';

/// Enum values for how the target of a static type should be interpreted.
enum ClassRelation {
  /// The target is any subtype of the static type.
  subtype,

  /// The target is a subclass or mixin application of the static type.
  ///
  /// This corresponds to accessing a member through a this expression.
  thisExpression,

  /// The target is an exact instance of the static type.
  exact,
}

ClassRelation computeClassRelationFromType(ir.DartType type) {
  if (type is ThisInterfaceType) {
    return ClassRelation.thisExpression;
  } else if (type is ExactInterfaceType) {
    return ClassRelation.exact;
  } else {
    return ClassRelation.subtype;
  }
}

class StaticTypeCacheImpl implements ir.StaticTypeCache {
  final Map<ir.Expression, ir.DartType> _expressionTypes = {};
  final Map<ir.ForInStatement, ir.DartType> _forInIteratorTypes = {};

  @override
  ir.DartType getExpressionType(
      ir.Expression node, ir.StaticTypeContext context) {
    return _expressionTypes[node] ??= node.getStaticTypeInternal(context);
  }

  @override
  ir.DartType getForInIteratorType(
      ir.ForInStatement node, ir.StaticTypeContext context) {
    return _forInIteratorTypes[node] ??= node.getElementTypeInternal(context);
  }

  @override
  ir.DartType getForInElementType(
      ir.ForInStatement node, ir.StaticTypeContext context) {
    throw UnsupportedError('StaticTypeCacheImpl.getForInElementType');
  }
}

/// Visitor that computes and caches the static type of expression while
/// visiting the full tree at expression level.
///
/// To ensure that the traversal only visits and computes the expression type
/// for each expression once, this class performs the traversal explicitly and
/// adds 'handleX' hooks for subclasses to handle individual expressions using
/// the readily compute static types of subexpressions.
abstract class StaticTypeVisitor extends StaticTypeBase {
  final StaticTypeCacheImpl _staticTypeCache;
  Map<ir.Expression, TypeMap> typeMapsForTesting;
  Map<ir.PropertyGet, RuntimeTypeUseData> _pendingRuntimeTypeUseData = {};

  final ir.ClassHierarchy hierarchy;

  ThisInterfaceType _thisType;
  ir.Library _currentLibrary;

  StaticTypeVisitor(
      ir.TypeEnvironment typeEnvironment, this.hierarchy, this._staticTypeCache)
      : super(typeEnvironment);

  StaticTypeCache getStaticTypeCache() {
    return new StaticTypeCache(_staticTypeCache._expressionTypes,
        _staticTypeCache._forInIteratorTypes);
  }

  /// If `true`, the effect of executing assert statements is taken into account
  /// when computing the static type.
  bool get useAsserts;

  /// If `true`, the static type of an effectively final variable is inferred
  /// from the static type of its initializer.
  bool get inferEffectivelyFinalVariableTypes;

  VariableScopeModel get variableScopeModel;

  @override
  ThisInterfaceType get thisType {
    assert(_thisType != null);
    return _thisType;
  }

  void set thisType(ThisInterfaceType value) {
    assert(value == null || _thisType == null);
    _thisType = value;
  }

  ir.Library get currentLibrary {
    assert(_currentLibrary != null);
    return _currentLibrary;
  }

  void set currentLibrary(ir.Library value) {
    assert(value == null || _currentLibrary == null);
    _currentLibrary = value;
  }

  bool completes(ir.DartType type) => type != const DoesNotCompleteType();

  Set<ir.VariableDeclaration> _currentVariables;
  Set<ir.VariableDeclaration> _invalidatedVariables =
      new Set<ir.VariableDeclaration>();

  TypeMap _typeMapBase = const TypeMap();
  TypeMap _typeMapWhenTrue;
  TypeMap _typeMapWhenFalse;

  /// Returns the local variable type promotions for when the boolean value of
  /// the most recent node is not taken into account.
  TypeMap get typeMap {
    if (_typeMapBase == null) {
      _typeMapBase = _typeMapWhenTrue.join(_typeMapWhenFalse);
      _typeMapWhenTrue = _typeMapWhenFalse = null;
    }
    return _typeMapBase;
  }

  /// Sets the local variable type promotions for when the boolean value of
  /// the most recent node is not taken into account.
  void set typeMap(TypeMap value) {
    _typeMapBase = value;
    _typeMapWhenTrue = _typeMapWhenFalse = null;
  }

  /// Returns the local variable type promotions for when the boolean value of
  /// the most recent node is `true`.
  TypeMap get typeMapWhenTrue => _typeMapWhenTrue ?? _typeMapBase;

  /// Sets the local variable type promotions for when the boolean value of
  /// the most recent node is `true`.
  void set typeMapWhenTrue(TypeMap value) {
    _typeMapWhenTrue = value;
    _typeMapBase = null;
  }

  /// Returns the local variable type promotions for when the boolean value of
  /// the most recent node is `false`.
  TypeMap get typeMapWhenFalse => _typeMapWhenFalse ?? _typeMapBase;

  /// Sets the local variable type promotions for when the boolean value of
  /// the most recent node is `false`.
  void set typeMapWhenFalse(TypeMap value) {
    _typeMapWhenFalse = value;
    _typeMapBase = null;
  }

  @override
  ir.DartType defaultNode(ir.Node node) =>
      throw UnsupportedError('Unhandled node $node (${node.runtimeType})');

  @override
  Null visitComponent(ir.Component node) {
    visitNodes(node.libraries);
  }

  @override
  Null visitLibrary(ir.Library node) {
    visitNodes(node.classes);
    visitNodes(node.procedures);
    visitNodes(node.fields);
  }

  @override
  Null visitClass(ir.Class node) {
    visitNodes(node.constructors);
    visitNodes(node.procedures);
    visitNodes(node.fields);
  }

  ir.InterfaceType getInterfaceTypeOf(ir.DartType type) {
    while (type is ir.TypeParameterType) {
      type = (type as ir.TypeParameterType).parameter.bound;
    }
    if (type is ir.InterfaceType) {
      return type;
    } else if (type is ir.NullType) {
      return typeEnvironment.coreTypes.deprecatedNullType;
    }
    return null;
  }

  /// Returns the static type of the expression as an instantiation of
  /// [superclass].
  ///
  /// Should only be used on code compiled in strong mode, as this method
  /// assumes the IR is strongly typed.
  ///
  /// This method furthermore assumes that the type of the expression actually
  /// is a subtype of (some instantiation of) the given [superclass].
  /// If this is not the case the raw type of [superclass] is returned.
  ///
  /// This method is derived from `ir.Expression.getStaticTypeAsInstanceOf`.
  ir.InterfaceType getTypeAsInstanceOf(ir.DartType type, ir.Class superclass) {
    // This method assumes the program is correctly typed, so if the superclass
    // is not generic, we can just return its raw type without computing the
    // type of this expression.  It also ensures that all types are considered
    // subtypes of Object (not just interface types), and function types are
    // considered subtypes of Function.
    if (superclass.typeParameters.isEmpty) {
      return typeEnvironment.coreTypes
          .rawType(superclass, currentLibrary.nonNullable);
    }
    while (type is ir.TypeParameterType) {
      type = (type as ir.TypeParameterType).parameter.bound;
    }
    if (type is ir.NullType) {
      return typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, currentLibrary.nullable);
    }
    if (type is ir.InterfaceType) {
      ir.InterfaceType upcastType = typeEnvironment.getTypeAsInstanceOf(
          type, superclass, currentLibrary, typeEnvironment.coreTypes);
      if (upcastType != null) return upcastType;
    } else if (type is ir.BottomType) {
      return typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, currentLibrary.nonNullable);
    }
    // TODO(johnniwinther): Should we assert that this doesn't happen?
    return typeEnvironment.coreTypes
        .rawType(superclass, currentLibrary.nonNullable);
  }

  /// Computes the result type of the property access [node] on a receiver of
  /// type [receiverType].
  ///
  /// If the `node.interfaceTarget` is `null` but matches an `Object` member
  /// it is updated to target this member.
  ir.DartType _computePropertyGetType(
      ir.PropertyGet node, ir.DartType receiverType) {
    ir.Member interfaceTarget = node.interfaceTarget;
    if (interfaceTarget == null && receiverType is ir.InterfaceType) {
      interfaceTarget = node.interfaceTarget =
          hierarchy.getInterfaceMember(receiverType.classNode, node.name);
    }
    if (interfaceTarget != null) {
      ir.Class superclass = interfaceTarget.enclosingClass;
      receiverType = getTypeAsInstanceOf(receiverType, superclass);
      return ir.Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
    }
    // Treat the properties of Object specially.
    String nameString = node.name.text;
    if (nameString == 'hashCode') {
      return typeEnvironment.coreTypes.intNonNullableRawType;
    } else if (nameString == 'runtimeType') {
      return typeEnvironment.coreTypes.typeNonNullableRawType;
    }
    return const ir.DynamicType();
  }

  void handlePropertyGet(
      ir.PropertyGet node, ir.DartType receiverType, ir.DartType resultType) {}

  void handleRuntimeTypeUse(ir.PropertyGet node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType argumentType) {}

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType resultType = _staticTypeCache._expressionTypes[node] =
        _computePropertyGetType(node, receiverType);
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    handlePropertyGet(node, receiverType, resultType);
    if (node.name.text == Identifiers.runtimeType_) {
      RuntimeTypeUseData data =
          computeRuntimeTypeUse(_pendingRuntimeTypeUseData, node);
      if (data.leftRuntimeTypeExpression == node) {
        // [node] is the left (or single) occurrence of `.runtimeType` so we
        // can set the static type of the receiver expression.
        data.receiverType = receiverType;
      } else {
        // [node] is the right occurrence of `.runtimeType` so we
        // can set the static type of the argument expression.
        assert(data.rightRuntimeTypeExpression == node,
            "Unexpected RuntimeTypeUseData for $node: $data");
        data.argumentType = receiverType;
      }
      if (data.isComplete) {
        /// We now have all need static types so we can remove the data from
        /// the cache and handle the runtime type use.
        _pendingRuntimeTypeUseData.remove(data.leftRuntimeTypeExpression);
        if (data.rightRuntimeTypeExpression != null) {
          _pendingRuntimeTypeUseData.remove(data.rightRuntimeTypeExpression);
        }
        handleRuntimeTypeUse(
            node, data.kind, data.receiverType, data.argumentType);
      }
    }
    return resultType;
  }

  void handlePropertySet(
      ir.PropertySet node, ir.DartType receiverType, ir.DartType valueType) {}

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType valueType = super.visitPropertySet(node);
    ir.Member interfaceTarget = node.interfaceTarget;
    if (interfaceTarget == null && receiverType is ir.InterfaceType) {
      interfaceTarget = hierarchy
          .getInterfaceMember(receiverType.classNode, node.name, setter: true);
      if (interfaceTarget != null) {
        ir.Class superclass = interfaceTarget.enclosingClass;
        ir.Substitution receiverSubstitution =
            ir.Substitution.fromInterfaceType(
                getTypeAsInstanceOf(receiverType, superclass));
        ir.DartType setterType =
            receiverSubstitution.substituteType(interfaceTarget.setterType);
        if (!typeEnvironment.isSubtypeOf(
            valueType, setterType, ir.SubtypeCheckMode.ignoringNullabilities)) {
          // We need to insert an implicit cast to preserve the invariant that
          // a property set with a known interface target is also statically
          // checked.
          ir.AsExpression implicitCast =
              new ir.AsExpression(node.value, setterType)
                ..isTypeError = true
                ..parent = node;
          node.value = implicitCast;
          // Visit the newly created as expression; the original value has
          // already been visited.
          handleAsExpression(implicitCast, valueType);
          valueType = setterType;
        }
        node.interfaceTarget = interfaceTarget;
      }
    }
    receiverType = _narrowInstanceReceiver(interfaceTarget, receiverType);
    handlePropertySet(node, receiverType, valueType);
    return valueType;
  }

  /// Returns `true` if [interfaceTarget] is an arithmetic operator whose result
  /// type is computed using both the receiver type and the argument type.
  ///
  /// Visitors that subclass the [StaticTypeVisitor] must special case this
  /// target as to avoid visiting the argument twice.
  bool isSpecialCasedBinaryOperator(ir.Member interfaceTarget) {
    return interfaceTarget is ir.Procedure &&
        typeEnvironment.isSpecialCasedBinaryOperator(interfaceTarget);
  }

  ir.Member _getMember(ir.Class cls, String name) {
    for (ir.Member member in cls.members) {
      if (member.name.text == name) return member;
    }
    throw fail("Member '$name' not found in $cls");
  }

  ir.Procedure _objectEquals;
  ir.Procedure get objectEquals =>
      _objectEquals ??= _getMember(typeEnvironment.coreTypes.objectClass, '==');

  /// Returns [receiverType] narrowed to enclosing class of [interfaceTarget].
  ///
  /// If [interfaceTarget] is `null` or `receiverType` is _not_ `dynamic` no
  /// narrowing is performed.
  ir.DartType _narrowInstanceReceiver(
      ir.Member interfaceTarget, ir.DartType receiverType) {
    if (interfaceTarget != null && receiverType == const ir.DynamicType()) {
      receiverType = interfaceTarget.enclosingClass.getThisType(
          typeEnvironment.coreTypes,
          interfaceTarget.enclosingLibrary.nonNullable);
    }
    return receiverType;
  }

  /// Returns `true` if [member] can be called with the structure of
  /// [arguments].
  bool _isApplicable(ir.Arguments arguments, ir.Member member) {
    /// Returns `true` if [arguments] are applicable to the function type
    /// structure.
    bool isFunctionTypeApplicable(
        int typeParameterCount,
        int requiredParameterCount,
        int positionalParameterCount,
        Iterable<String> Function() getNamedParameters) {
      if (arguments.types.isNotEmpty &&
          arguments.types.length != typeParameterCount) {
        return false;
      }
      if (arguments.positional.length < requiredParameterCount) {
        return false;
      }
      if (arguments.positional.length > positionalParameterCount) {
        return false;
      }
      Iterable<String> namedParameters = getNamedParameters();
      if (arguments.named.length > namedParameters.length) {
        return false;
      }
      if (arguments.named.isNotEmpty) {
        for (ir.NamedExpression namedArguments in arguments.named) {
          if (!namedParameters.contains(namedArguments.name)) {
            return false;
          }
        }
      }
      return true;
    }

    /// Returns `true` if [arguments] are applicable to a value of the static
    /// [type].
    bool isTypeApplicable(ir.DartType type) {
      if (type is ir.DynamicType) return true;
      if (type == typeEnvironment.coreTypes.functionLegacyRawType ||
          type == typeEnvironment.coreTypes.functionNullableRawType ||
          type == typeEnvironment.coreTypes.functionNonNullableRawType)
        return true;
      if (type is ir.FunctionType) {
        return isFunctionTypeApplicable(
            type.typeParameters.length,
            type.requiredParameterCount,
            type.positionalParameters.length,
            () => type.namedParameters.map((p) => p.name).toSet());
      }
      return false;
    }

    if (member is ir.Procedure) {
      if (member.kind == ir.ProcedureKind.Setter ||
          member.kind == ir.ProcedureKind.Factory) {
        return false;
      } else if (member.kind == ir.ProcedureKind.Getter) {
        return isTypeApplicable(member.getterType);
      } else if (member.kind == ir.ProcedureKind.Method ||
          member.kind == ir.ProcedureKind.Operator) {
        return isFunctionTypeApplicable(
            member.function.typeParameters.length,
            member.function.requiredParameterCount,
            member.function.positionalParameters.length,
            () => member.function.namedParameters.map((p) => p.name).toSet());
      }
    } else if (member is ir.Field) {
      return isTypeApplicable(member.type);
    }
    return false;
  }

  /// Update the interface target on [node].
  ///
  /// This inserts any implicit cast of the arguments necessary to uphold the
  /// invariant that a method invocation with an interface target handles
  /// the static types at the call site.
  void _updateMethodInvocationTarget(
      ir.MethodInvocation node,
      ArgumentTypes argumentTypes,
      ir.DartType functionType,
      ir.Member interfaceTarget) {
    // TODO(johnniwinther): Handle incremental target improvement.
    if (node.interfaceTarget != null) return;
    node.interfaceTarget = interfaceTarget;
    if (functionType is! ir.FunctionType) return;
    ir.FunctionType parameterTypes = functionType;
    Map<int, ir.DartType> neededPositionalChecks = {};
    for (int i = 0; i < node.arguments.positional.length; i++) {
      ir.DartType argumentType = argumentTypes.positional[i];
      ir.DartType parameterType = parameterTypes.positionalParameters[i];
      if (!typeEnvironment.isSubtypeOf(argumentType, parameterType,
          ir.SubtypeCheckMode.ignoringNullabilities)) {
        neededPositionalChecks[i] = parameterType;
      }
    }
    Map<int, ir.DartType> neededNamedChecks = {};
    for (int argumentIndex = 0;
        argumentIndex < node.arguments.named.length;
        argumentIndex++) {
      ir.NamedExpression namedArgument = node.arguments.named[argumentIndex];
      ir.DartType argumentType = argumentTypes.named[argumentIndex];
      ir.DartType parameterType = parameterTypes.namedParameters
          .singleWhere((namedType) => namedType.name == namedArgument.name)
          .type;
      if (!typeEnvironment.isSubtypeOf(argumentType, parameterType,
          ir.SubtypeCheckMode.ignoringNullabilities)) {
        neededNamedChecks[argumentIndex] = parameterType;
      }
    }
    if (neededPositionalChecks.isEmpty && neededNamedChecks.isEmpty) {
      // No implicit casts needed
      return;
    }

    List<ir.VariableDeclaration> letVariables = [];

    // Arguments need to be hoisted to an enclosing let expression in order
    // to ensure that the arguments are evaluated before any implicit cast.

    ir.Expression updateArgument(ir.Expression expression, ir.TreeNode parent,
        ir.DartType argumentType, ir.DartType checkedParameterType) {
      ir.VariableDeclaration variable =
          new ir.VariableDeclaration.forValue(expression, type: argumentType);
      // Visit the newly created variable declaration.
      handleVariableDeclaration(variable);
      letVariables.add(variable);
      ir.VariableGet get = new ir.VariableGet(variable)..parent = parent;
      // Visit the newly created variable get.
      handleVariableGet(get, argumentType);
      _staticTypeCache._expressionTypes[get] = argumentType;

      if (checkedParameterType == null) {
        return get;
      }
      // We need to insert an implicit cast to preserve the invariant that
      // a method invocation with a known interface target is also
      // statically checked.
      ir.AsExpression implicitCast =
          new ir.AsExpression(get, checkedParameterType)
            ..isTypeError = true
            ..parent = parent;
      // Visit the newly created as expression; the original value has
      // already been visited.
      handleAsExpression(implicitCast, argumentType);
      return implicitCast;
    }

    for (int index = 0; index < node.arguments.positional.length; index++) {
      ir.DartType argumentType = argumentTypes.positional[index];
      node.arguments.positional[index] = updateArgument(
          node.arguments.positional[index],
          node.arguments,
          argumentType,
          neededPositionalChecks[index]);
    }
    for (int argumentIndex = 0;
        argumentIndex < node.arguments.named.length;
        argumentIndex++) {
      ir.NamedExpression namedArgument = node.arguments.named[argumentIndex];
      ir.DartType argumentType = argumentTypes.named[argumentIndex];
      namedArgument.value = updateArgument(namedArgument.value, namedArgument,
          argumentType, neededNamedChecks[argumentIndex]);
    }

    ir.Expression dummy = new ir.NullLiteral();
    node.replaceWith(dummy);
    ir.Expression body = node;
    for (ir.VariableDeclaration variable in letVariables.reversed) {
      body = new ir.Let(variable, body);
    }
    dummy.replaceWith(body);
  }

  /// Computes the result type of the method invocation [node] on a receiver of
  /// type [receiverType].
  ///
  /// If the `node.interfaceTarget` is `null` but matches an `Object` member
  /// it is updated to target this member.
  ir.DartType _computeMethodInvocationType(ir.MethodInvocation node,
      ir.DartType receiverType, ArgumentTypes argumentTypes) {
    ir.Member interfaceTarget = node.interfaceTarget;
    // TODO(34602): Remove when `interfaceTarget` is set on synthetic calls to
    // ==.
    if (interfaceTarget == null &&
        node.name.text == '==' &&
        node.arguments.types.isEmpty &&
        node.arguments.positional.length == 1 &&
        node.arguments.named.isEmpty) {
      interfaceTarget = node.interfaceTarget = objectEquals;
    }
    if (interfaceTarget == null && receiverType is ir.InterfaceType) {
      ir.Member member =
          hierarchy.getInterfaceMember(receiverType.classNode, node.name);
      if (_isApplicable(node.arguments, member)) {
        interfaceTarget = member;
      }
    }
    if (interfaceTarget != null) {
      ir.Class superclass = interfaceTarget.enclosingClass;
      ir.Substitution receiverSubstitution = ir.Substitution.fromInterfaceType(
          getTypeAsInstanceOf(receiverType, superclass));
      ir.DartType getterType =
          receiverSubstitution.substituteType(interfaceTarget.getterType);
      if (getterType is ir.FunctionType) {
        ir.FunctionType functionType = getterType;
        List<ir.DartType> typeArguments = node.arguments.types;
        if (interfaceTarget is ir.Procedure &&
            interfaceTarget.function.typeParameters.isNotEmpty &&
            typeArguments.isEmpty) {
          // If this was a dynamic call the invocation does not have the
          // inferred default type arguments so we need to create them here
          // to perform a valid substitution.
          typeArguments = interfaceTarget.function.typeParameters
              .map((t) => receiverSubstitution.substituteType(t.defaultType))
              .toList();
        }
        getterType = ir.Substitution.fromPairs(
                functionType.typeParameters, typeArguments)
            .substituteType(functionType.withoutTypeParameters);
      }
      _updateMethodInvocationTarget(
          node, argumentTypes, getterType, interfaceTarget);
      if (isSpecialCasedBinaryOperator(interfaceTarget)) {
        ir.DartType argumentType = argumentTypes.positional[0];
        return typeEnvironment.getTypeOfSpecialCasedBinaryOperator(
            receiverType, argumentType);
      } else if (getterType is ir.FunctionType) {
        return getterType.returnType;
      } else {
        return const ir.DynamicType();
      }
    }
    if (node.name.text == 'call') {
      if (receiverType is ir.FunctionType) {
        if (receiverType.typeParameters.length != node.arguments.types.length) {
          return const DoesNotCompleteType();
        }
        return ir.Substitution.fromPairs(
                receiverType.typeParameters, node.arguments.types)
            .substituteType(receiverType.returnType);
      }
    }
    if (node.name.text == '==') {
      // We use this special case to simplify generation of '==' checks.
      return typeEnvironment.coreTypes.boolNonNullableRawType;
    }
    return const ir.DynamicType();
  }

  ArgumentTypes _visitArguments(ir.Arguments arguments) {
    List<ir.DartType> positional;
    List<ir.DartType> named;
    if (arguments.positional.isEmpty) {
      positional = const <ir.DartType>[];
    } else {
      positional =
          new List<ir.DartType>.filled(arguments.positional.length, null);
      int index = 0;
      for (ir.Expression argument in arguments.positional) {
        positional[index++] = visitNode(argument);
      }
    }
    if (arguments.named.isEmpty) {
      named = const <ir.DartType>[];
    } else {
      named = new List<ir.DartType>.filled(arguments.named.length, null);
      int index = 0;
      for (ir.NamedExpression argument in arguments.named) {
        named[index++] = visitNode(argument);
      }
    }
    return new ArgumentTypes(positional, named);
  }

  void handleMethodInvocation(
      ir.MethodInvocation node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {}

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType returnType =
        _computeMethodInvocationType(node, receiverType, argumentTypes);
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    if (node.name.text == '==') {
      ir.Expression left = node.receiver;
      ir.Expression right = node.arguments.positional[0];
      TypeMap afterInvocation = typeMap;
      if (left is ir.VariableGet &&
          isNullLiteral(right) &&
          !_invalidatedVariables.contains(left.variable)) {
        // If `left == null` is true, we promote the type of the variable to
        // `Null` by registering that is known _not_ to be of its declared type.
        typeMapWhenTrue = afterInvocation
            .promote(left.variable, left.variable.type, isTrue: false);
        typeMapWhenFalse = afterInvocation
            .promote(left.variable, left.variable.type, isTrue: true);
      }
      if (right is ir.VariableGet &&
          isNullLiteral(left) &&
          !_invalidatedVariables.contains(right.variable)) {
        // If `null == right` is true, we promote the type of the variable to
        // `Null` by registering that is known _not_ to be of its declared type.
        typeMapWhenTrue = afterInvocation
            .promote(right.variable, right.variable.type, isTrue: false);
        typeMapWhenFalse = afterInvocation
            .promote(right.variable, right.variable.type, isTrue: true);
      }
    }
    _staticTypeCache._expressionTypes[node] = returnType;
    handleMethodInvocation(node, receiverType, argumentTypes, returnType);
    return returnType;
  }

  void handleVariableGet(ir.VariableGet node, ir.DartType type) {}

  @override
  ir.DartType visitVariableGet(ir.VariableGet node) {
    if (typeMapsForTesting != null) {
      typeMapsForTesting[node] = typeMap;
    }
    ir.DartType promotedType = typeMap.typeOf(node, typeEnvironment);
    assert(
        node.promotedType == null ||
            promotedType is ir.NullType ||
            promotedType is ir.FutureOrType ||
            typeEnvironment.isSubtypeOf(promotedType, node.promotedType,
                ir.SubtypeCheckMode.ignoringNullabilities),
        "Unexpected promotion of ${node.variable} in ${node.parent}. "
        "Expected ${node.promotedType}, found $promotedType");
    _staticTypeCache._expressionTypes[node] = promotedType;
    handleVariableGet(node, promotedType);
    return promotedType;
  }

  void handleVariableSet(ir.VariableSet node, ir.DartType resultType) {}

  @override
  ir.DartType visitVariableSet(ir.VariableSet node) {
    ir.DartType resultType = super.visitVariableSet(node);
    handleVariableSet(node, resultType);
    if (!_currentVariables.contains(node.variable)) {
      _invalidatedVariables.add(node.variable);
      typeMap = typeMap.remove([node.variable]);
    } else {
      typeMap = typeMap.reduce(node, resultType, typeEnvironment);
    }
    return resultType;
  }

  void handleStaticGet(ir.StaticGet node, ir.DartType resultType) {}

  @override
  ir.DartType visitStaticGet(ir.StaticGet node) {
    ir.DartType resultType = super.visitStaticGet(node);
    handleStaticGet(node, resultType);
    return resultType;
  }

  void handleStaticSet(ir.StaticSet node, ir.DartType valueType) {}

  @override
  ir.DartType visitStaticSet(ir.StaticSet node) {
    ir.DartType valueType = super.visitStaticSet(node);
    handleStaticSet(node, valueType);
    return valueType;
  }

  void handleStaticInvocation(ir.StaticInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {}

  @override
  ir.DartType visitStaticInvocation(ir.StaticInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType returnType = ir.Substitution.fromPairs(
            node.target.function.typeParameters, node.arguments.types)
        .substituteType(node.target.function.returnType);
    _staticTypeCache._expressionTypes[node] = returnType;
    handleStaticInvocation(node, argumentTypes, returnType);
    return returnType;
  }

  void handleConstructorInvocation(ir.ConstructorInvocation node,
      ArgumentTypes argumentTypes, ir.DartType resultType) {}

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType resultType = node.arguments.types.isEmpty
        ? new ExactInterfaceType.from(typeEnvironment.coreTypes
            .nonNullableRawType(node.target.enclosingClass))
        : new ExactInterfaceType(node.target.enclosingClass,
            ir.Nullability.nonNullable, node.arguments.types);
    _staticTypeCache._expressionTypes[node] = resultType;
    handleConstructorInvocation(node, argumentTypes, resultType);
    return resultType;
  }

  void handleSuperPropertyGet(
      ir.SuperPropertyGet node, ir.DartType resultType) {}

  @override
  ir.DartType visitSuperPropertyGet(ir.SuperPropertyGet node) {
    ir.DartType resultType;
    if (node.interfaceTarget == null) {
      // TODO(johnniwinther): Resolve and set the target here.
      resultType = const ir.DynamicType();
    } else {
      ir.Class declaringClass = node.interfaceTarget.enclosingClass;
      if (declaringClass.typeParameters.isEmpty) {
        resultType = node.interfaceTarget.getterType;
      } else {
        ir.DartType receiver = typeEnvironment.getTypeAsInstanceOf(thisType,
            declaringClass, currentLibrary, typeEnvironment.coreTypes);
        resultType = ir.Substitution.fromInterfaceType(receiver)
            .substituteType(node.interfaceTarget.getterType);
      }
    }
    _staticTypeCache._expressionTypes[node] = resultType;
    handleSuperPropertyGet(node, resultType);
    return resultType;
  }

  void handleSuperPropertySet(
      ir.SuperPropertySet node, ir.DartType valueType) {}

  @override
  ir.DartType visitSuperPropertySet(ir.SuperPropertySet node) {
    ir.DartType valueType = super.visitSuperPropertySet(node);
    handleSuperPropertySet(node, valueType);
    return valueType;
  }

  void handleSuperMethodInvocation(ir.SuperMethodInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {}

  @override
  ir.DartType visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType returnType;
    if (node.interfaceTarget == null) {
      // TODO(johnniwinther): Resolve and set the target here.
      returnType = const ir.DynamicType();
    } else {
      ir.Class superclass = node.interfaceTarget.enclosingClass;
      ir.InterfaceType receiverType = typeEnvironment.getTypeAsInstanceOf(
          thisType, superclass, currentLibrary, typeEnvironment.coreTypes);
      returnType = ir.Substitution.fromInterfaceType(receiverType)
          .substituteType(node.interfaceTarget.function.returnType);
      returnType = ir.Substitution.fromPairs(
              node.interfaceTarget.function.typeParameters,
              node.arguments.types)
          .substituteType(returnType);
    }
    _staticTypeCache._expressionTypes[node] = returnType;
    handleSuperMethodInvocation(node, argumentTypes, returnType);
    return returnType;
  }

  @override
  ir.DartType visitLogicalExpression(ir.LogicalExpression node) {
    if (node.operatorEnum == ir.LogicalExpressionOperator.AND) {
      visitNode(node.left);
      TypeMap afterLeftWhenTrue = typeMapWhenTrue;
      TypeMap afterLeftWhenFalse = typeMapWhenFalse;
      typeMap = afterLeftWhenTrue;
      visitNode(node.right);
      TypeMap afterRightWhenTrue = typeMapWhenTrue;
      TypeMap afterRightWhenFalse = typeMapWhenFalse;
      typeMapWhenTrue = afterRightWhenTrue;
      typeMapWhenFalse = afterLeftWhenFalse.join(afterRightWhenFalse);
    } else {
      visitNode(node.left);
      TypeMap afterLeftWhenTrue = typeMapWhenTrue;
      TypeMap afterLeftWhenFalse = typeMapWhenFalse;
      typeMap = afterLeftWhenFalse;
      visitNode(node.right);
      TypeMap afterRightWhenTrue = typeMapWhenTrue;
      TypeMap afterRightWhenFalse = typeMapWhenFalse;
      typeMapWhenTrue = afterLeftWhenTrue.join(afterRightWhenTrue);
      typeMapWhenFalse = afterRightWhenFalse;
    }
    return super.visitLogicalExpression(node);
  }

  @override
  ir.DartType visitNot(ir.Not node) {
    visitNode(node.operand);
    TypeMap afterOperandWhenTrue = typeMapWhenTrue;
    TypeMap afterOperandWhenFalse = typeMapWhenFalse;
    typeMapWhenTrue = afterOperandWhenFalse;
    typeMapWhenFalse = afterOperandWhenTrue;
    return super.visitNot(node);
  }

  ir.DartType _handleConditional(
      ir.Expression condition, ir.TreeNode then, ir.TreeNode otherwise) {
    visitNode(condition);
    TypeMap afterConditionWhenTrue = typeMapWhenTrue;
    TypeMap afterConditionWhenFalse = typeMapWhenFalse;
    typeMap = afterConditionWhenTrue;
    ir.DartType thenType = visitNode(then);
    TypeMap afterThen = typeMap;
    typeMap = afterConditionWhenFalse;
    ir.DartType otherwiseType = visitNode(otherwise);
    TypeMap afterOtherwise = typeMap;
    if (completes(thenType) && completes(otherwiseType)) {
      typeMap = afterThen.join(afterOtherwise);
      return null;
    } else if (completes(thenType)) {
      typeMap = afterThen;
      return null;
    } else if (completes(otherwiseType)) {
      typeMap = afterOtherwise;
      return null;
    } else {
      typeMap = afterThen.join(afterOtherwise);
      return const DoesNotCompleteType();
    }
  }

  @override
  ir.DartType visitConditionalExpression(ir.ConditionalExpression node) {
    // TODO(johnniwinther): Should we return `const DoesNotCompleteType()` if
    // both branches are failing?
    _handleConditional(node.condition, node.then, node.otherwise);
    return super.visitConditionalExpression(node);
  }

  void handleIsExpression(ir.IsExpression node) {}

  @override
  ir.DartType visitIsExpression(ir.IsExpression node) {
    ir.Expression operand = node.operand;
    visitNode(operand);
    if (operand is ir.VariableGet &&
        !_invalidatedVariables.contains(operand.variable)) {
      TypeMap afterOperand = typeMap;
      typeMapWhenTrue =
          afterOperand.promote(operand.variable, node.type, isTrue: true);
      typeMapWhenFalse =
          afterOperand.promote(operand.variable, node.type, isTrue: false);
    }
    handleIsExpression(node);
    return super.visitIsExpression(node);
  }

  @override
  ir.DartType visitLet(ir.Let node) {
    _processLocalVariable(node.variable);
    return super.visitLet(node);
  }

  @override
  ir.DartType visitBlockExpression(ir.BlockExpression node) {
    visitNode(node.body);
    return super.visitBlockExpression(node);
  }

  ir.DartType _computeInstantiationType(
      ir.Instantiation node, ir.FunctionType expressionType) {
    return ir.Substitution.fromPairs(
            expressionType.typeParameters, node.typeArguments)
        .substituteType(expressionType.withoutTypeParameters);
  }

  void handleInstantiation(ir.Instantiation node,
      ir.FunctionType expressionType, ir.DartType resultType) {}

  @override
  ir.DartType visitInstantiation(ir.Instantiation node) {
    ir.FunctionType expressionType = visitNode(node.expression);
    ir.DartType resultType = _computeInstantiationType(node, expressionType);
    _staticTypeCache._expressionTypes[node] = resultType;
    handleInstantiation(node, expressionType, resultType);
    return resultType;
  }

  @override
  ir.DartType visitBlock(ir.Block node) {
    assert(_pendingRuntimeTypeUseData.isEmpty);
    ir.DartType type;
    for (ir.Statement statement in node.statements) {
      if (!completes(visitNode(statement))) {
        type = const DoesNotCompleteType();
      }
    }
    assert(_pendingRuntimeTypeUseData.isEmpty,
        "Incomplete RuntimeTypeUseData: $_pendingRuntimeTypeUseData");
    return type;
  }

  @override
  ir.DartType visitExpressionStatement(ir.ExpressionStatement node) {
    if (completes(visitNode(node.expression))) {
      return null;
    } else {
      return const DoesNotCompleteType();
    }
  }

  void handleAsExpression(ir.AsExpression node, ir.DartType operandType) {}

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    ir.DartType operandType = visitNode(node.operand);
    handleAsExpression(node, operandType);
    return super.visitAsExpression(node);
  }

  void handleNullCheck(ir.NullCheck node, ir.DartType operandType) {}

  @override
  ir.DartType visitNullCheck(ir.NullCheck node) {
    ir.DartType operandType = visitNode(node.operand);
    handleNullCheck(node, operandType);
    ir.DartType resultType = operandType is ir.NullType
        ? const ir.NeverType(ir.Nullability.nonNullable)
        : operandType.withDeclaredNullability(ir.Nullability.nonNullable);
    _staticTypeCache._expressionTypes[node] = resultType;
    return resultType;
  }

  void handleStringConcatenation(ir.StringConcatenation node) {}

  @override
  ir.DartType visitStringConcatenation(ir.StringConcatenation node) {
    visitNodes(node.expressions);
    handleStringConcatenation(node);
    return super.visitStringConcatenation(node);
  }

  void handleIntLiteral(ir.IntLiteral node) {}

  @override
  ir.DartType visitIntLiteral(ir.IntLiteral node) {
    handleIntLiteral(node);
    return super.visitIntLiteral(node);
  }

  void handleDoubleLiteral(ir.DoubleLiteral node) {}

  @override
  ir.DartType visitDoubleLiteral(ir.DoubleLiteral node) {
    handleDoubleLiteral(node);
    return super.visitDoubleLiteral(node);
  }

  void handleBoolLiteral(ir.BoolLiteral node) {}

  @override
  ir.DartType visitBoolLiteral(ir.BoolLiteral node) {
    handleBoolLiteral(node);
    return super.visitBoolLiteral(node);
  }

  void handleStringLiteral(ir.StringLiteral node) {}

  @override
  ir.DartType visitStringLiteral(ir.StringLiteral node) {
    handleStringLiteral(node);
    return super.visitStringLiteral(node);
  }

  void handleSymbolLiteral(ir.SymbolLiteral node) {}

  @override
  ir.DartType visitSymbolLiteral(ir.SymbolLiteral node) {
    handleSymbolLiteral(node);
    return super.visitSymbolLiteral(node);
  }

  void handleNullLiteral(ir.NullLiteral node) {}

  @override
  ir.DartType visitNullLiteral(ir.NullLiteral node) {
    handleNullLiteral(node);
    return super.visitNullLiteral(node);
  }

  void handleListLiteral(ir.ListLiteral node) {}

  @override
  ir.DartType visitListLiteral(ir.ListLiteral node) {
    visitNodes(node.expressions);
    handleListLiteral(node);
    return super.visitListLiteral(node);
  }

  void handleSetLiteral(ir.SetLiteral node) {}

  @override
  ir.DartType visitSetLiteral(ir.SetLiteral node) {
    visitNodes(node.expressions);
    handleSetLiteral(node);
    return super.visitSetLiteral(node);
  }

  void handleMapLiteral(ir.MapLiteral node) {}

  @override
  ir.DartType visitMapLiteral(ir.MapLiteral node) {
    visitNodes(node.entries);
    handleMapLiteral(node);
    return super.visitMapLiteral(node);
  }

  @override
  Null visitMapEntry(ir.MapEntry entry) {
    visitNode(entry.key);
    visitNode(entry.value);
  }

  void handleFunctionExpression(ir.FunctionExpression node) {}

  @override
  ir.DartType visitFunctionExpression(ir.FunctionExpression node) {
    TypeMap beforeClosure =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    typeMap = typeMap.remove(variableScopeModel.assignedVariables);
    ir.DartType returnType = super.visitFunctionExpression(node);
    Set<ir.VariableDeclaration> _oldVariables = _currentVariables;
    _currentVariables = {};
    visitSignature(node.function);
    visitNode(node.function.body);
    handleFunctionExpression(node);
    _invalidatedVariables.removeAll(_currentVariables);
    _currentVariables = _oldVariables;
    typeMap = beforeClosure;
    return returnType;
  }

  void handleThrow(ir.Throw node) {}

  @override
  ir.DartType visitThrow(ir.Throw node) {
    visitNode(node.expression);
    handleThrow(node);
    return super.visitThrow(node);
  }

  @override
  Null visitSwitchCase(ir.SwitchCase node) {
    visitNodes(node.expressions);
    visitNode(node.body);
  }

  @override
  ir.DartType visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    return const DoesNotCompleteType();
  }

  @override
  Null visitLabeledStatement(ir.LabeledStatement node) {
    visitNode(node.body);
  }

  @override
  ir.DartType visitBreakStatement(ir.BreakStatement node) {
    return const DoesNotCompleteType();
  }

  @override
  Null visitYieldStatement(ir.YieldStatement node) {
    visitNode(node.expression);
  }

  @override
  Null visitAssertInitializer(ir.AssertInitializer node) {
    visitNode(node.statement);
  }

  void handleFieldInitializer(ir.FieldInitializer node) {}

  @override
  Null visitFieldInitializer(ir.FieldInitializer node) {
    visitNode(node.value);
    handleFieldInitializer(node);
  }

  void handleRedirectingInitializer(
      ir.RedirectingInitializer node, ArgumentTypes argumentTypes) {}

  @override
  Null visitRedirectingInitializer(ir.RedirectingInitializer node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    handleRedirectingInitializer(node, argumentTypes);
  }

  void handleSuperInitializer(
      ir.SuperInitializer node, ArgumentTypes argumentTypes) {}

  @override
  Null visitSuperInitializer(ir.SuperInitializer node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    handleSuperInitializer(node, argumentTypes);
  }

  @override
  Null visitLocalInitializer(ir.LocalInitializer node) {
    visitNode(node.variable);
  }

  @override
  ir.DartType visitNamedExpression(ir.NamedExpression node) =>
      visitNode(node.value);

  @override
  Null visitEmptyStatement(ir.EmptyStatement node) {}

  @override
  Null visitForStatement(ir.ForStatement node) {
    visitNodes(node.variables);
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.condition);
    typeMap = typeMapWhenTrue;
    visitNode(node.body);
    visitNodes(node.updates);
    typeMap = beforeLoop;
  }

  void handleForInStatement(ir.ForInStatement node, ir.DartType iterableType,
      ir.DartType iteratorType) {}

  @override
  Null visitForInStatement(ir.ForInStatement node) {
    // For sync for-in [iterableType] is a subtype of `Iterable`, for async
    // for-in [iterableType] is a subtype of `Stream`.
    ir.DartType iterableType = visitNode(node.iterable);
    ir.DartType iteratorType = const ir.DynamicType();
    if (node.isAsync) {
      ir.InterfaceType streamInterfaceType = getInterfaceTypeOf(iterableType);
      ir.InterfaceType streamType = typeEnvironment.getTypeAsInstanceOf(
          streamInterfaceType,
          typeEnvironment.coreTypes.streamClass,
          currentLibrary,
          typeEnvironment.coreTypes);
      if (streamType != null) {
        iteratorType = new ir.InterfaceType(
            typeEnvironment.coreTypes.streamIteratorClass,
            ir.Nullability.nonNullable,
            streamType.typeArguments);
      }
    } else {
      ir.InterfaceType iterableInterfaceType = getInterfaceTypeOf(iterableType);
      ir.Member member = hierarchy.getInterfaceMember(
          iterableInterfaceType.classNode, new ir.Name(Identifiers.iterator));
      if (member != null) {
        iteratorType = ir.Substitution.fromInterfaceType(
                typeEnvironment.getTypeAsInstanceOf(
                    iterableInterfaceType,
                    member.enclosingClass,
                    currentLibrary,
                    typeEnvironment.coreTypes))
            .substituteType(member.getterType);
      }
    }
    _staticTypeCache._forInIteratorTypes[node] = iteratorType;
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.variable);
    visitNode(node.body);
    handleForInStatement(node, iterableType, iteratorType);
    typeMap = beforeLoop;
  }

  @override
  Null visitDoStatement(ir.DoStatement node) {
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.body);
    visitNode(node.condition);
    typeMap = beforeLoop;
  }

  @override
  Null visitWhileStatement(ir.WhileStatement node) {
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.condition);
    typeMap = typeMapWhenTrue;
    visitNode(node.body);
    typeMap = beforeLoop;
  }

  void handleSwitchStatement(ir.SwitchStatement node) {}

  @override
  Null visitSwitchStatement(ir.SwitchStatement node) {
    visitNode(node.expression);
    TypeMap afterExpression = typeMap;
    VariableScope scope = variableScopeModel.getScopeFor(node);
    TypeMap afterStatement = afterExpression.remove(scope.assignedVariables);
    TypeMap beforeCase =
        scope.hasContinueSwitch ? afterStatement : afterExpression;
    for (ir.SwitchCase switchCase in node.cases) {
      typeMap = beforeCase;
      visitNode(switchCase);
    }
    handleSwitchStatement(node);
    typeMap = afterStatement;
  }

  @override
  ir.DartType visitReturnStatement(ir.ReturnStatement node) {
    visitNode(node.expression);
    return const DoesNotCompleteType();
  }

  @override
  ir.DartType visitIfStatement(ir.IfStatement node) {
    return _handleConditional(node.condition, node.then, node.otherwise);
  }

  @override
  Null visitTryCatch(ir.TryCatch node) {
    visitNode(node.body);
    visitNodes(node.catches);
  }

  void handleCatch(ir.Catch node) {}

  @override
  Null visitCatch(ir.Catch node) {
    handleCatch(node);
    visitNode(node.body);
  }

  @override
  Null visitTryFinally(ir.TryFinally node) {
    visitNode(node.body);
    visitNode(node.finalizer);
  }

  void handleTypeLiteral(ir.TypeLiteral node) {}

  @override
  ir.DartType visitTypeLiteral(ir.TypeLiteral node) {
    handleTypeLiteral(node);
    return super.visitTypeLiteral(node);
  }

  void handleLoadLibrary(ir.LoadLibrary node) {}

  @override
  ir.DartType visitLoadLibrary(ir.LoadLibrary node) {
    handleLoadLibrary(node);
    return super.visitLoadLibrary(node);
  }

  void handleAssertStatement(ir.AssertStatement node) {}

  @override
  Null visitAssertStatement(ir.AssertStatement node) {
    TypeMap beforeCondition = typeMap;
    visitNode(node.condition);
    TypeMap afterConditionWhenTrue = typeMapWhenTrue;
    TypeMap afterConditionWhenFalse = typeMapWhenFalse;
    typeMap = afterConditionWhenFalse;
    visitNode(node.message);
    handleAssertStatement(node);
    typeMap = useAsserts ? afterConditionWhenTrue : beforeCondition;
  }

  void handleFunctionDeclaration(ir.FunctionDeclaration node) {}

  @override
  Null visitFunctionDeclaration(ir.FunctionDeclaration node) {
    TypeMap beforeClosure =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    typeMap = typeMap.remove(variableScopeModel.assignedVariables);
    Set<ir.VariableDeclaration> _oldVariables = _currentVariables;
    _currentVariables = {};
    visitSignature(node.function);
    visitNode(node.function.body);
    handleFunctionDeclaration(node);
    _invalidatedVariables.removeAll(_currentVariables);
    _currentVariables = _oldVariables;
    typeMap = beforeClosure;
  }

  void handleParameter(ir.VariableDeclaration node) {}

  void visitParameter(ir.VariableDeclaration node) {
    _currentVariables.add(node);
    visitNode(node.initializer);
    handleParameter(node);
  }

  void handleSignature(ir.FunctionNode node) {}

  void visitSignature(ir.FunctionNode node) {
    node.positionalParameters.forEach(visitParameter);
    node.namedParameters.forEach(visitParameter);
    handleSignature(node);
  }

  void handleProcedure(ir.Procedure node) {}

  @override
  Null visitProcedure(ir.Procedure node) {
    thisType = new ThisInterfaceType.from(node.enclosingClass?.getThisType(
        typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable));
    _currentVariables = {};
    currentLibrary = node.enclosingLibrary;
    visitSignature(node.function);
    visitNode(node.function.body);
    handleProcedure(node);
    _invalidatedVariables.removeAll(_currentVariables);
    _currentVariables = null;
    thisType = null;
    currentLibrary = null;
  }

  void handleConstructor(ir.Constructor node) {}

  @override
  Null visitConstructor(ir.Constructor node) {
    thisType = new ThisInterfaceType.from(node.enclosingClass.getThisType(
        typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable));
    _currentVariables = {};
    currentLibrary = node.enclosingLibrary;
    visitSignature(node.function);
    visitNodes(node.initializers);
    visitNode(node.function.body);
    handleConstructor(node);
    _invalidatedVariables.removeAll(_currentVariables);
    _currentVariables = null;
    thisType = null;
    currentLibrary = null;
  }

  void handleField(ir.Field node) {}

  @override
  Null visitField(ir.Field node) {
    thisType = new ThisInterfaceType.from(node.enclosingClass?.getThisType(
        typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable));
    _currentVariables = {};
    currentLibrary = node.enclosingLibrary;
    visitNode(node.initializer);
    handleField(node);
    _invalidatedVariables.removeAll(_currentVariables);
    _currentVariables = null;
    thisType = null;
    currentLibrary = null;
  }

  void handleVariableDeclaration(ir.VariableDeclaration node) {}

  void _processLocalVariable(ir.VariableDeclaration node) {
    _currentVariables.add(node);
    ir.DartType type = visitNode(node.initializer);
    if (node.initializer != null &&
        variableScopeModel.isEffectivelyFinal(node) &&
        inferEffectivelyFinalVariableTypes) {
      node.type = type;
    }
  }

  @override
  Null visitVariableDeclaration(ir.VariableDeclaration node) {
    _processLocalVariable(node);
    handleVariableDeclaration(node);
  }

  void handleConstantExpression(ir.ConstantExpression node) {}

  @override
  ir.DartType visitConstantExpression(ir.ConstantExpression node) {
    handleConstantExpression(node);
    return super.visitConstantExpression(node);
  }
}

class ArgumentTypes {
  final List<ir.DartType> positional;
  final List<ir.DartType> named;

  ArgumentTypes(this.positional, this.named);
}

/// Type information collected for a single path for a local variable.
///
/// This is used to implement guarded type promotion.
///
/// The terminology and implementation is based on this paper:
///
///   http://www.cs.williams.edu/FTfJP2011/6-Winther.pdf
///
class TypeHolder {
  /// The declared type of the local variable.
  final ir.DartType declaredType;

  /// The types that the local variable is known to be an instance of.
  final Set<ir.DartType> trueTypes;

  /// The types that the local variable is known _not_ to be an instance of.
  final Set<ir.DartType> falseTypes;

  int _hashCode;

  TypeHolder(this.declaredType, this.trueTypes, this.falseTypes);

  /// Computes a single type that soundly represents the promoted type of the
  /// local variable on this single path.
  ir.DartType typeOf(ir.TypeEnvironment typeEnvironment) {
    ir.DartType candidate = declaredType;
    if (falseTypes != null) {
      // TODO(johnniwinther): Special-case the `== null` representation to
      // make it faster.
      for (ir.DartType type in falseTypes) {
        if (typeEnvironment.isSubtypeOf(
            declaredType, type, ir.SubtypeCheckMode.ignoringNullabilities)) {
          return const ir.NullType();
        }
      }
    }
    if (trueTypes != null) {
      for (ir.DartType type in trueTypes) {
        if (type is ir.NullType) {
          return type;
        }
        if (typeEnvironment.isSubtypeOf(
            type, candidate, ir.SubtypeCheckMode.ignoringNullabilities)) {
          candidate = type;
        } else if (!typeEnvironment.isSubtypeOf(
            candidate, type, ir.SubtypeCheckMode.ignoringNullabilities)) {
          // We cannot promote. No single type is most specific.
          // TODO(johnniwinther): Compute implied types? For instance when the
          // declared type is `Iterable<String>` and tested type is
          // `List<dynamic>` we could promote to the implied type
          // `List<String>`.
          return null;
        }
      }
    }
    return candidate;
  }

  @override
  int get hashCode {
    if (_hashCode == null) {
      _hashCode = Hashing.setHash(falseTypes,
          Hashing.setHash(trueTypes, Hashing.objectHash(declaredType)));
    }
    return _hashCode;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is TypeHolder &&
        declaredType == other.declaredType &&
        equalSets(trueTypes, other.trueTypes) &&
        equalSets(falseTypes, other.falseTypes);
  }

  void _getText(
      StringBuffer sb, String Function(Iterable<ir.DartType>) typesToText) {
    sb.write('{');
    String comma = '';
    if (trueTypes != null) {
      sb.write('true:');
      sb.write(typesToText(trueTypes));
      comma = ',';
    }
    if (falseTypes != null) {
      sb.write(comma);
      sb.write('false:');
      sb.write(typesToText(falseTypes));
    }
    sb.write('}');
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('TypeHolder(');
    sb.write('declared=$declaredType');
    if (trueTypes != null) {
      sb.write(',true=$trueTypes');
    }
    if (falseTypes != null) {
      sb.write(',false=$falseTypes');
    }
    sb.write(')');
    return sb.toString();
  }
}

/// Type information for a single local variable on all possible paths.
///
/// This is used to implement guarded type promotion.
///
/// The terminology and implementation is based on this paper:
///
///   http://www.cs.williams.edu/FTfJP2011/6-Winther.pdf
///
class TargetInfo {
  /// The declared type of the local variable.
  final ir.DartType declaredType;

  /// Collected type information for disjoint paths.
  final Iterable<TypeHolder> typeHolders;

  /// Types relevant for promotion of the local variable.
  final Iterable<ir.DartType> typesOfInterest;

  TargetInfo(this.declaredType, this.typeHolders, this.typesOfInterest);

  /// Returns the [TargetInfo] that describes the added type knowledge for the
  /// local variable. If [isTrue] is `true`, the local variable is known to
  /// be an instance of [type]. If [isTrue] is `false`, the local variable is
  /// known _not_ to be an instance of [type].
  TargetInfo promote(ir.DartType type, {bool isTrue}) {
    Set<TypeHolder> newTypeHolders = new Set<TypeHolder>();

    bool addTypeHolder(TypeHolder typeHolder) {
      bool changed = false;

      Set<ir.DartType> addAsCopy(Set<ir.DartType> set, ir.DartType type) {
        Set<ir.DartType> result;
        if (set == null) {
          result = new Set<ir.DartType>();
        } else if (set.contains(type)) {
          return set;
        } else {
          result = Set<ir.DartType>.from(set);
        }
        changed = true;
        return result..add(type);
      }

      Set<ir.DartType> trueTypes = typeHolder?.trueTypes;
      Set<ir.DartType> falseTypes = typeHolder?.falseTypes;
      if (isTrue) {
        trueTypes = addAsCopy(trueTypes, type);
      } else {
        falseTypes = addAsCopy(falseTypes, type);
      }
      // TODO(johnniwinther): Check validity; if the true types are
      // contradicting, for instance if the local is known to be and instance
      // of types `int` and `String` simultaneously, then we could flag code
      // as dead code.
      newTypeHolders.add(TypeHolder(declaredType, trueTypes, falseTypes));
      return changed;
    }

    bool changed = false;
    if (typeHolders.isEmpty) {
      changed |= addTypeHolder(null);
    } else {
      for (TypeHolder typeHolder in typeHolders) {
        changed |= addTypeHolder(typeHolder);
      }
    }
    Iterable<ir.DartType> newTypesOfInterest;
    if (typesOfInterest.contains(type)) {
      newTypesOfInterest = typesOfInterest;
    } else {
      newTypesOfInterest = new Set<ir.DartType>.from(typesOfInterest)
        ..add(type);
      changed = true;
    }
    return changed
        ? new TargetInfo(declaredType, newTypeHolders, newTypesOfInterest)
        : this;
  }

  /// Returns the [TargetInfo] that describes that the local is either of [this]
  /// or the [other] type.
  ///
  /// Returns `null` if the join is empty.
  TargetInfo join(TargetInfo other) {
    if (other == null) return null;
    if (identical(this, other)) return this;

    Set<TypeHolder> newTypeHolders = new Set<TypeHolder>();
    Set<ir.DartType> newTypesOfInterest = new Set<ir.DartType>();

    /// Adds the [typeHolders] to [newTypeHolders] for types in
    /// [otherTypesOfInterest] while removing the information
    /// invalidated by [otherTrueTypes] and [otherFalseTypes].
    void addTypeHolders(
        Iterable<TypeHolder> typeHolders,
        Set<ir.DartType> otherTrueTypes,
        Set<ir.DartType> otherFalseTypes,
        Iterable<ir.DartType> otherTypesOfInterest) {
      for (TypeHolder typeHolder in typeHolders) {
        Set<ir.DartType> newTrueTypes;
        if (typeHolder.trueTypes != null) {
          newTrueTypes = new Set<ir.DartType>.from(typeHolder.trueTypes);

          /// Only types in [otherTypesOfInterest] has information from all
          /// paths.
          newTrueTypes.retainAll(otherTypesOfInterest);

          /// Remove types that are known to be false on other paths; these
          /// would amount to knowing that a variable is or is not of some
          /// type.
          newTrueTypes.removeAll(otherFalseTypes);
          if (newTrueTypes.isEmpty) {
            newTrueTypes = null;
          } else {
            newTypesOfInterest.addAll(newTrueTypes);
          }
        }
        Set<ir.DartType> newFalseTypes;
        if (typeHolder.falseTypes != null) {
          newFalseTypes = new Set<ir.DartType>.from(typeHolder.falseTypes);

          /// Only types in [otherTypesOfInterest] has information from all
          /// paths.
          newFalseTypes.retainAll(otherTypesOfInterest);

          /// Remove types that are known to be true on other paths; these
          /// would amount to knowing that a variable is or is not of some
          /// type.
          newFalseTypes.removeAll(otherTrueTypes);
          if (newFalseTypes.isEmpty) {
            newFalseTypes = null;
          } else {
            newTypesOfInterest.addAll(newFalseTypes);
          }
        }
        if (newTrueTypes != null || newFalseTypes != null) {
          // Only include type holders with information.
          newTypeHolders
              .add(new TypeHolder(declaredType, newTrueTypes, newFalseTypes));
        }
      }
    }

    Set<ir.DartType> thisTrueTypes = new Set<ir.DartType>();
    Set<ir.DartType> thisFalseTypes = new Set<ir.DartType>();
    for (TypeHolder typeHolder in typeHolders) {
      if (typeHolder.trueTypes != null) {
        thisTrueTypes.addAll(typeHolder.trueTypes);
      }
      if (typeHolder.falseTypes != null) {
        thisFalseTypes.addAll(typeHolder.falseTypes);
      }
    }

    Set<ir.DartType> otherTrueTypes = new Set<ir.DartType>();
    Set<ir.DartType> otherFalseTypes = new Set<ir.DartType>();
    for (TypeHolder typeHolder in other.typeHolders) {
      if (typeHolder.trueTypes != null) {
        otherTrueTypes.addAll(typeHolder.trueTypes);
      }
      if (typeHolder.falseTypes != null) {
        otherFalseTypes.addAll(typeHolder.falseTypes);
      }
    }

    addTypeHolders(this.typeHolders, otherTrueTypes, otherFalseTypes,
        other.typesOfInterest);
    addTypeHolders(
        other.typeHolders, thisTrueTypes, thisFalseTypes, this.typesOfInterest);

    if (newTypeHolders.isEmpty) {
      assert(newTypesOfInterest.isEmpty);
      return null;
    }

    return new TargetInfo(declaredType, newTypeHolders, newTypesOfInterest);
  }

  /// Computes a single type that soundly represents the promoted type of the
  /// local variable on all possible paths.
  ir.DartType typeOf(ir.TypeEnvironment typeEnvironment) {
    ir.DartType candidate = null;
    for (TypeHolder typeHolder in typeHolders) {
      ir.DartType type = typeHolder.typeOf(typeEnvironment);
      if (type == null) {
        // We cannot promote. No single type is most specific.
        return null;
      }
      if (candidate == null) {
        candidate = type;
      } else {
        if (type is ir.NullType) {
          // Keep the current candidate.
        } else if (candidate is ir.NullType) {
          candidate = type;
        } else if (typeEnvironment.isSubtypeOf(
            candidate, type, ir.SubtypeCheckMode.ignoringNullabilities)) {
          candidate = type;
        } else if (!typeEnvironment.isSubtypeOf(
            type, candidate, ir.SubtypeCheckMode.ignoringNullabilities)) {
          // We cannot promote. No promoted type of one path is a supertype of
          // the promoted type from all other paths.
          // TODO(johnniwinther): Compute a greatest lower bound, instead?
          return null;
        }
      }
    }
    return candidate;
  }

  void _getText(
      StringBuffer sb, String Function(Iterable<ir.DartType>) typesToText) {
    sb.write('[');
    String comma = '';
    for (TypeHolder typeHolder in typeHolders) {
      sb.write(comma);
      typeHolder._getText(sb, typesToText);
      comma = ',';
    }
    sb.write('|');
    sb.write(typesToText(typesOfInterest));
    sb.write(']');
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('TargetInfo(');
    sb.write('declaredType=$declaredType,');
    sb.write('typeHolders=$typeHolders,');
    sb.write('declarationsOfInterest=$typesOfInterest');
    sb.write(')');
    return sb.toString();
  }
}

/// Map from local variables to type information used for guarded type
/// promotion.
///
/// The terminology and implementation is based on this paper:
///
///   http://www.cs.williams.edu/FTfJP2011/6-Winther.pdf
///
class TypeMap {
  final Map<ir.VariableDeclaration, TargetInfo> _targetInfoMap;

  const TypeMap([this._targetInfoMap = const {}]);

  /// Returns the [TypeMap] that describes the added type knowledge for the
  /// local [variable]. If [isTrue] is `true`, the local [variable] is known to
  /// be an instance of [type]. If [isTrue] is `false`, the local [variable] is
  /// known _not_ to be an instance of [type].
  TypeMap promote(ir.VariableDeclaration variable, ir.DartType type,
      {bool isTrue}) {
    Map<ir.VariableDeclaration, TargetInfo> newInfoMap =
        new Map<ir.VariableDeclaration, TargetInfo>.from(_targetInfoMap);
    TargetInfo targetInfo = newInfoMap[variable];
    bool changed = false;
    if (targetInfo != null) {
      TargetInfo result = targetInfo.promote(type, isTrue: isTrue);
      changed = !identical(targetInfo, result);
      targetInfo = result;
    } else {
      changed = true;
      Set<ir.DartType> trueTypes =
          isTrue ? (new Set<ir.DartType>()..add(type)) : null;
      Set<ir.DartType> falseTypes =
          isTrue ? null : (new Set<ir.DartType>()..add(type));
      TypeHolder typeHolder =
          new TypeHolder(variable.type, trueTypes, falseTypes);
      targetInfo = new TargetInfo(
          variable.type, <TypeHolder>[typeHolder], <ir.DartType>[type]);
    }
    newInfoMap[variable] = targetInfo;
    return changed ? new TypeMap(newInfoMap) : this;
  }

  /// Returns the [TypeMap] that describes that the locals are either of [this]
  /// or the [other] types.
  TypeMap join(TypeMap other) {
    if (identical(this, other)) return this;

    Map<ir.VariableDeclaration, TargetInfo> newInfoMap = {};
    bool changed = false;
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      TargetInfo result = info.join(other._targetInfoMap[variable]);
      changed |= !identical(info, result);
      if (result != null) {
        // Add only non-empty information.
        newInfoMap[variable] = result;
      }
    });
    return changed ? new TypeMap(newInfoMap) : this;
  }

  /// Returns the [TypeMap] in which all type information for any of the
  /// [variables] has been removed.
  TypeMap remove(Iterable<ir.VariableDeclaration> variables) {
    bool changed = false;
    Map<ir.VariableDeclaration, TargetInfo> newInfoMap = {};
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      if (!variables.contains(variable)) {
        newInfoMap[variable] = info;
      } else {
        changed = true;
      }
    });
    return changed ? new TypeMap(newInfoMap) : this;
  }

  /// Returns the [TypeMap] where type information for `node.variable` is
  /// reduced to the promotions upheld by an assignment to `node.variable` of
  /// the static [type].
  TypeMap reduce(ir.VariableSet node, ir.DartType type,
      ir.TypeEnvironment typeEnvironment) {
    Map<ir.VariableDeclaration, TargetInfo> newInfoMap = {};
    bool changed = false;
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      if (variable != node.variable) {
        newInfoMap[variable] = info;
      } else if (type != null) {
        changed = true;
        Set<ir.DartType> newTypesOfInterest = new Set<ir.DartType>();
        for (ir.DartType typeOfInterest in info.typesOfInterest) {
          if (typeEnvironment.isSubtypeOf(type, typeOfInterest,
              ir.SubtypeCheckMode.ignoringNullabilities)) {
            newTypesOfInterest.add(typeOfInterest);
          }
        }
        if (newTypesOfInterest.length > 1 ||
            (newTypesOfInterest.length == 1 &&
                newTypesOfInterest.single != info.declaredType)) {
          // If [newTypesOfInterest] only contains the declared type we have no
          // information about the variable (it is either an instance of its
          // declared type or null) and the canonical way to represent this is
          // to have _no_ target info.
          TypeHolder typeHolderIfNonNull =
              new TypeHolder(info.declaredType, newTypesOfInterest, null);
          TypeHolder typeHolderIfNull = new TypeHolder(info.declaredType, null,
              new Set<ir.DartType>()..add(info.declaredType));
          newInfoMap[variable] = new TargetInfo(
              info.declaredType,
              <TypeHolder>[typeHolderIfNonNull, typeHolderIfNull],
              newTypesOfInterest);
        }
      } else {
        changed = true;
      }
    });
    return changed ? new TypeMap(newInfoMap) : this;
  }

  /// Computes a single type that soundly represents the promoted type of
  /// `node.variable` on all possible paths.
  ir.DartType typeOf(ir.VariableGet node, ir.TypeEnvironment typeEnvironment) {
    TargetInfo info = _targetInfoMap[node.variable];
    ir.DartType type;
    if (info != null) {
      type = info.typeOf(typeEnvironment);
    }
    return type ?? node.promotedType ?? node.variable.type;
  }

  String getText(String Function(Iterable<ir.DartType>) typesToText) {
    StringBuffer sb = new StringBuffer();
    sb.write('{');
    String comma = '';
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      sb.write('${comma}${variable.name}:');
      info._getText(sb, typesToText);
      comma = ',';
    });
    sb.write('}');
    return sb.toString();
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('TypeMap(');
    String comma = '';
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      sb.write('${comma}$variable->$info');
      comma = ',';
    });
    sb.write(')');
    return sb.toString();
  }
}
