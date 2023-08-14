// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show operatorFromString;
import 'package:front_end/src/api_prototype/static_weak_references.dart' as ir
    show StaticWeakReferences;
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
  Map<ir.Expression, TypeMap>? typeMapsForTesting;
  // TODO(johnniwinther): Change the key to `InstanceGet` when the old method
  //  invocation encoding is no longer used.
  final Map<ir.Expression, RuntimeTypeUseData> _pendingRuntimeTypeUseData = {};

  final ir.ClassHierarchy hierarchy;

  ThisInterfaceType? _thisType;
  ir.Library? _currentLibrary;

  StaticTypeVisitor(
      super.typeEnvironment, this.hierarchy, this._staticTypeCache);

  StaticTypeCache getStaticTypeCache() {
    return StaticTypeCache(_staticTypeCache._expressionTypes,
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
    return _thisType!;
  }

  void set thisType(ThisInterfaceType? value) {
    assert(value == null || _thisType == null);
    _thisType = value;
  }

  ir.Library get currentLibrary {
    return _currentLibrary!;
  }

  void set currentLibrary(ir.Library? value) {
    assert(value == null || _currentLibrary == null);
    _currentLibrary = value;
  }

  bool completes(ir.DartType? type) => type != const ir.NeverType.nonNullable();

  Set<ir.VariableDeclaration>? _currentVariables;
  final Set<ir.VariableDeclaration> _invalidatedVariables = {};

  TypeMap? _typeMapBase = const TypeMap();
  TypeMap? _typeMapWhenTrue;
  TypeMap? _typeMapWhenFalse;

  /// Joins [_typeMapWhenTrue] and [_typeMapWhenFalse] and stores the result
  /// in [_typeMapBase].
  void _flattenTypeMap() {
    if (_typeMapBase == null) {
      _typeMapBase = _typeMapWhenTrue!.join(_typeMapWhenFalse!);
      _typeMapWhenTrue = _typeMapWhenFalse = null;
    }
  }

  /// Returns the local variable type promotions for when the boolean value of
  /// the most recent node is not taken into account.
  TypeMap get typeMap {
    _flattenTypeMap();
    return _typeMapBase!;
  }

  /// Sets the local variable type promotions for when the boolean value of
  /// the most recent node is not taken into account.
  void set typeMap(TypeMap value) {
    _typeMapBase = value;
    _typeMapWhenTrue = _typeMapWhenFalse = null;
  }

  /// Returns the local variable type promotions for when the boolean value of
  /// the most recent node is `true`.
  TypeMap get typeMapWhenTrue => _typeMapWhenTrue ?? _typeMapBase!;

  /// Sets the local variable type promotions for when the boolean value of
  /// the most recent node is `true`.
  void set typeMapWhenTrue(TypeMap value) {
    _typeMapWhenTrue = value;
    _typeMapBase = null;
  }

  /// Returns the local variable type promotions for when the boolean value of
  /// the most recent node is `false`.
  TypeMap get typeMapWhenFalse => _typeMapWhenFalse ?? _typeMapBase!;

  /// Sets the local variable type promotions for when the boolean value of
  /// the most recent node is `false`.
  void set typeMapWhenFalse(TypeMap value) {
    _typeMapWhenFalse = value;
    _typeMapBase = null;
  }

  @override
  ir.DartType visitComponent(ir.Component node) {
    visitNodes(node.libraries);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitLibrary(ir.Library node) {
    visitNodes(node.classes);
    visitNodes(node.procedures);
    visitNodes(node.fields);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitClass(ir.Class node) {
    visitNodes(node.constructors);
    visitNodes(node.procedures);
    visitNodes(node.fields);
    return const ir.VoidType();
  }

  ir.InterfaceType? getInterfaceTypeOf(ir.DartType type) {
    while (type is ir.TypeParameterType) {
      type = type.parameter.bound;
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
      type = type.parameter.bound;
    }
    if (type is ir.NullType ||
        type is ir.NeverType &&
            (type.nullability == ir.Nullability.nonNullable ||
                type.nullability == ir.Nullability.legacy)) {
      return typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, currentLibrary.nullable);
    }
    if (type is ir.InterfaceType) {
      ir.InterfaceType? upcastType = typeEnvironment.getTypeAsInstanceOf(
          type, superclass, typeEnvironment.coreTypes,
          isNonNullableByDefault: currentLibrary.isNonNullableByDefault);
      if (upcastType != null) return upcastType;
    }
    // TODO(johnniwinther): Should we assert that this doesn't happen?
    return typeEnvironment.coreTypes
        .rawType(superclass, currentLibrary.nonNullable);
  }

  ir.Member? _resolveDynamicTarget(ir.DartType receiverType, ir.Name name) {
    if (receiverType is ir.InterfaceType) {
      return hierarchy.getInterfaceMember(receiverType.classNode, name);
    }
    return null;
  }

  ir.DartType _computeInstanceGetType(
      ir.DartType receiverType, ir.Member interfaceTarget) {
    ir.Class superclass = interfaceTarget.enclosingClass!;
    final castType = getTypeAsInstanceOf(receiverType, superclass);
    return ir.Substitution.fromInterfaceType(castType)
        .substituteType(interfaceTarget.getterType);
  }

  /// Replaces [original] with [replacement] in the AST and removes cached
  /// expression type information for [original].
  void _replaceExpression(ir.Expression original, ir.Expression replacement) {
    original.replaceWith(replacement);
    _staticTypeCache._expressionTypes.remove(original);
  }

  void handleDynamicGet(ir.Expression node, ir.DartType receiverType,
      ir.Name name, ir.DartType resultType) {}

  void handleInstanceGet(ir.Expression node, ir.DartType receiverType,
      ir.Member interfaceTarget, ir.DartType resultType) {}

  // TODO(johnniwinther): Change [node] to `InstanceGet` when the old method
  // invocation encoding is no longer used.
  void handleRuntimeTypeUse(ir.Expression node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType? argumentType) {}

  void handleRuntimeTypeGet(ir.DartType receiverType, ir.Expression node) {
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
          node, data.kind, data.receiverType!, data.argumentType);
    }
  }

  @override
  ir.DartType visitDynamicGet(ir.DynamicGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType resultType = super.visitDynamicGet(node);
    ir.Member? interfaceTarget = _resolveDynamicTarget(receiverType, node.name);
    if (interfaceTarget != null) {
      resultType = _computeInstanceGetType(receiverType, interfaceTarget);
      ir.InstanceGet instanceGet = ir.InstanceGet(
          ir.InstanceAccessKind.Instance, node.receiver, node.name,
          interfaceTarget: interfaceTarget, resultType: resultType)
        ..fileOffset = node.fileOffset;
      _replaceExpression(node, instanceGet);
      handleInstanceGet(instanceGet, receiverType, interfaceTarget, resultType);
    } else if (node.name == ir.Name.callName &&
        (receiverType is ir.FunctionType ||
            (receiverType is ir.InterfaceType &&
                receiverType.classNode == typeEnvironment.functionClass))) {
      ir.FunctionTearOff functionTearOff = ir.FunctionTearOff(node.receiver)
        ..fileOffset = node.fileOffset;
      _replaceExpression(node, functionTearOff);
      handleDynamicGet(
          functionTearOff, receiverType, ir.Name.callName, resultType);
      resultType = receiverType;
    } else {
      handleDynamicGet(node, receiverType, node.name, resultType);
    }
    if (node.name.text == Identifiers.runtimeType_) {
      // This handles `runtimeType` access on `Never`.
      handleRuntimeTypeGet(receiverType, node);
    }
    return resultType;
  }

  @override
  ir.DartType visitInstanceGet(ir.InstanceGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    // We compute the function type instead of reading it of [node] since the
    // receiver and argument types might have improved through inference of
    // effectively final variable types and type promotion.
    ir.DartType resultType =
        _computeInstanceGetType(receiverType, node.interfaceTarget);
    node.resultType = resultType;
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    handleInstanceGet(node, receiverType, node.interfaceTarget, resultType);
    if (node.name.text == Identifiers.runtimeType_) {
      // This handles `runtimeType` access on non-Never types, like in
      // `(throw 'foo').runtimeType`.
      handleRuntimeTypeGet(receiverType, node);
    }
    return resultType;
  }

  @override
  ir.DartType visitInstanceTearOff(ir.InstanceTearOff node) {
    ir.DartType receiverType = visitNode(node.receiver);
    // We compute the function type instead of reading it of [node] since the
    // receiver and argument types might have improved through inference of
    // effectively final variable types and type promotion.
    ir.DartType resultType =
        _computeInstanceGetType(receiverType, node.interfaceTarget);
    node.resultType = resultType;
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    assert(node.name.text != Identifiers.runtimeType_,
        "Unexpected .runtimeType instance tear-off.");
    handleInstanceGet(node, receiverType, node.interfaceTarget, resultType);
    return resultType;
  }

  @override
  ir.DartType visitRecordIndexGet(ir.RecordIndexGet node) {
    visitNode(node.receiver);
    return super.visitRecordIndexGet(node);
  }

  @override
  ir.DartType visitRecordNameGet(ir.RecordNameGet node) {
    visitNode(node.receiver);
    return super.visitRecordNameGet(node);
  }

  @override
  ir.DartType visitFunctionTearOff(ir.FunctionTearOff node) {
    ir.DartType receiverType = visitNode(node.receiver);
    handleDynamicGet(node, receiverType, ir.Name.callName, receiverType);
    return receiverType;
  }

  void handleDynamicSet(ir.Expression node, ir.DartType receiverType,
      ir.Name name, ir.DartType valueType) {}

  void handleInstanceSet(ir.Expression node, ir.DartType receiverType,
      ir.Member interfaceTarget, ir.DartType valueType) {}

  ir.Member? _resolveDynamicSet(ir.DartType receiverType, ir.Name name) {
    if (receiverType is ir.InterfaceType) {
      return hierarchy.getInterfaceMember(receiverType.classNode, name,
          setter: true);
    }
    return null;
  }

  ir.DartType _computeInstanceSetType(
      ir.DartType receiverType, ir.Member interfaceTarget) {
    ir.Class superclass = interfaceTarget.enclosingClass!;
    ir.Substitution receiverSubstitution = ir.Substitution.fromInterfaceType(
        getTypeAsInstanceOf(receiverType, superclass));
    return receiverSubstitution.substituteType(interfaceTarget.setterType);
  }

  ir.AsExpression? _createImplicitAsIfNeeded(
      ir.Expression value, ir.DartType valueType, ir.DartType setterType) {
    if (!typeEnvironment.isSubtypeOf(
        valueType, setterType, ir.SubtypeCheckMode.ignoringNullabilities)) {
      // We need to insert an implicit cast to preserve the invariant that
      // a property set with a known interface target is also statically
      // checked.
      return ir.AsExpression(value, setterType)..isTypeError = true;
    }
    return null;
  }

  @override
  ir.DartType visitDynamicSet(ir.DynamicSet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType valueType = visitNode(node.value);
    ir.Member? interfaceTarget = _resolveDynamicSet(receiverType, node.name);
    if (interfaceTarget != null) {
      ir.DartType setterType =
          _computeInstanceSetType(receiverType, interfaceTarget);
      ir.Expression value = node.value;
      ir.AsExpression? implicitCast =
          _createImplicitAsIfNeeded(value, valueType, setterType);
      if (implicitCast != null) {
        value = implicitCast;
        // Visit the newly created as expression; the original value has
        // already been visited.
        handleAsExpression(implicitCast, valueType);
        valueType = setterType;
      }
      ir.InstanceSet instanceSet = ir.InstanceSet(
          ir.InstanceAccessKind.Instance, node.receiver, node.name, value,
          interfaceTarget: interfaceTarget);
      _replaceExpression(node, instanceSet);
      receiverType = _narrowInstanceReceiver(interfaceTarget, receiverType);
      handleInstanceSet(node, receiverType, interfaceTarget, valueType);
    } else {
      handleDynamicSet(node, receiverType, node.name, valueType);
    }
    return valueType;
  }

  @override
  ir.DartType visitInstanceSet(ir.InstanceSet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType valueType = visitNode(node.value);
    handleInstanceSet(node, receiverType, node.interfaceTarget, valueType);
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

  /// Returns [receiverType] narrowed to enclosing class of [interfaceTarget].
  ///
  /// If [interfaceTarget] is `null` or `receiverType` is _not_ `dynamic` no
  /// narrowing is performed.
  ir.DartType _narrowInstanceReceiver(
      ir.Member? interfaceTarget, ir.DartType receiverType) {
    if (interfaceTarget != null && receiverType == const ir.DynamicType()) {
      receiverType = interfaceTarget.enclosingClass!.getThisType(
          typeEnvironment.coreTypes,
          interfaceTarget.enclosingLibrary.nonNullable);
    }
    return receiverType;
  }

  /// Returns `true` if [arguments] are applicable to the function type
  /// structure.
  bool _isApplicableToFunctionType(
      ir.Arguments arguments,
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
  bool _isApplicableToType(ir.Arguments arguments, ir.DartType type) {
    if (type is ir.DynamicType) return true;
    if (type == typeEnvironment.coreTypes.functionLegacyRawType ||
        type == typeEnvironment.coreTypes.functionNullableRawType ||
        type == typeEnvironment.coreTypes.functionNonNullableRawType)
      return true;
    if (type is ir.FunctionType) {
      return _isApplicableToFunctionType(
          arguments,
          type.typeParameters.length,
          type.requiredParameterCount,
          type.positionalParameters.length,
          () => type.namedParameters.map((p) => p.name).toSet());
    }
    return false;
  }

  /// Returns `true` if [member] can be called with the structure of
  /// [arguments].
  bool _isApplicableToMember(ir.Arguments arguments, ir.Member? member) {
    if (member is ir.Procedure) {
      if (member.kind == ir.ProcedureKind.Setter ||
          member.kind == ir.ProcedureKind.Factory) {
        return false;
      } else if (member.kind == ir.ProcedureKind.Getter) {
        return _isApplicableToType(arguments, member.getterType);
      } else if (member.kind == ir.ProcedureKind.Method ||
          member.kind == ir.ProcedureKind.Operator) {
        return _isApplicableToFunctionType(
            arguments,
            member.function.typeParameters.length,
            member.function.requiredParameterCount,
            member.function.positionalParameters.length,
            () => member.function.namedParameters.map((p) => p.name!).toSet());
      }
    } else if (member is ir.Field) {
      return _isApplicableToType(arguments, member.type);
    }
    return false;
  }

  /// Update the interface target on [node].
  ///
  /// This inserts any implicit cast of the arguments necessary to uphold the
  /// invariant that a method invocation with an interface target handles
  /// the static types at the call site.
  void _updateMethodInvocationTarget(ir.InvocationExpression node,
      ArgumentTypes argumentTypes, ir.DartType functionType) {
    if (functionType is! ir.FunctionType) return;
    Map<int, ir.DartType> neededPositionalChecks = {};
    for (int i = 0; i < node.arguments.positional.length; i++) {
      ir.DartType argumentType = argumentTypes.positional[i];
      ir.DartType parameterType = functionType.positionalParameters[i];
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
      ir.DartType parameterType = functionType.namedParameters
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
        ir.DartType argumentType, ir.DartType? checkedParameterType) {
      ir.VariableDeclaration variable =
          ir.VariableDeclaration.forValue(expression, type: argumentType);
      // Visit the newly created variable declaration.
      handleVariableDeclaration(variable);
      letVariables.add(variable);
      ir.VariableGet get = ir.VariableGet(variable)..parent = parent;
      // Visit the newly created variable get.
      handleVariableGet(get, argumentType);
      _staticTypeCache._expressionTypes[get] = argumentType;

      if (checkedParameterType == null) {
        return get;
      }
      // We need to insert an implicit cast to preserve the invariant that
      // a method invocation with a known interface target is also
      // statically checked.
      ir.AsExpression implicitCast = ir.AsExpression(get, checkedParameterType)
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

    ir.Expression dummy = ir.NullLiteral();
    node.replaceWith(dummy);
    ir.Expression body = node;
    for (ir.VariableDeclaration variable in letVariables.reversed) {
      body = ir.Let(variable, body);
    }
    dummy.replaceWith(body);
  }

  ir.Member? _resolveDynamicInvocationTarget(
      ir.DartType receiverType, ir.Name name, ir.Arguments arguments) {
    // TODO(34602): Remove when `interfaceTarget` is set on synthetic calls to
    // ==.
    if (name.text == '==' &&
        arguments.types.isEmpty &&
        arguments.positional.length == 1 &&
        arguments.named.isEmpty) {
      return typeEnvironment.coreTypes.objectEquals;
    }
    if (receiverType is ir.InterfaceType) {
      ir.Member? member =
          hierarchy.getInterfaceMember(receiverType.classNode, name);
      if (_isApplicableToMember(arguments, member)) {
        return member;
      }
    }
    return null;
  }

  /// Computes the function type of the function invocation of type
  /// [functionType] with the given [argument].
  ir.DartType _computeFunctionInvocationType(
      ir.DartType functionType, ir.Arguments arguments) {
    if (functionType is ir.FunctionType) {
      List<ir.DartType> typeArguments = arguments.types;
      if (functionType.typeParameters.isNotEmpty && typeArguments.isEmpty) {
        // If this was a dynamic call the invocation does not have the
        // inferred default type arguments so we need to create them here
        // to perform a valid substitution.
        typeArguments =
            functionType.typeParameters.map((t) => t.defaultType).toList();
      }
      return ir.Substitution.fromPairs(
              functionType.typeParameters, typeArguments)
          .substituteType(functionType.withoutTypeParameters);
    }
    return functionType;
  }

  /// Computes the function type of the instance invocation [node] on a receiver
  /// of type [receiverType] on the [interfaceTarget] with the given
  /// [argumentTypes].
  ir.DartType _computeInstanceInvocationType(
      ir.DartType receiverType,
      ir.Member interfaceTarget,
      ir.Arguments arguments,
      ArgumentTypes argumentTypes) {
    ir.Class superclass = interfaceTarget.enclosingClass!;
    ir.Substitution receiverSubstitution = ir.Substitution.fromInterfaceType(
        getTypeAsInstanceOf(receiverType, superclass));
    ir.DartType getterType =
        receiverSubstitution.substituteType(interfaceTarget.getterType);
    if (getterType is ir.FunctionType) {
      ir.FunctionType functionType = getterType;
      List<ir.DartType> typeArguments = arguments.types;
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
      getterType =
          ir.Substitution.fromPairs(functionType.typeParameters, typeArguments)
              .substituteType(functionType.withoutTypeParameters);
    }
    if (isSpecialCasedBinaryOperator(interfaceTarget)) {
      ir.DartType argumentType = argumentTypes.positional[0];
      ir.DartType resultType = typeEnvironment
          .getTypeOfSpecialCasedBinaryOperator(receiverType, argumentType);
      return ir.FunctionType(
          [argumentType], resultType, currentLibrary.nonNullable);
    }
    return getterType;
  }

  ir.DartType _getFunctionReturnType(ir.DartType functionType) {
    return functionType is ir.FunctionType
        ? functionType.returnType
        : const ir.DynamicType();
  }

  /// Computes the result type of the dynamic invocation [node] on a receiver of
  /// type [receiverType].
  ir.DartType _computeDynamicInvocationReturnType(
      ir.InvocationExpression node, ir.DartType receiverType) {
    if (node.name.text == 'call') {
      if (receiverType is ir.FunctionType) {
        if (receiverType.typeParameters.length != node.arguments.types.length) {
          return const ir.NeverType.nonNullable();
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
    final positional = arguments.positional.isEmpty
        ? const <ir.DartType>[]
        : arguments.positional.map(visitNode).toList(growable: false);
    final named = arguments.named.isEmpty
        ? const <ir.DartType>[]
        : arguments.named.map(visitNode).toList(growable: false);
    return ArgumentTypes(positional, named);
  }

  void handleDynamicInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {}

  void handleFunctionInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {}

  void handleInstanceInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ir.Member interfaceTarget,
      ArgumentTypes argumentTypes) {}

  void handleLocalFunctionInvocation(
      ir.InvocationExpression node,
      ir.FunctionDeclaration function,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {}

  void handleEqualsCall(ir.Expression left, ir.DartType leftType,
      ir.Expression right, ir.DartType rightType, ir.Member interfaceTarget) {}

  void _registerEqualsNull(TypeMap afterInvocation, ir.Expression expression) {
    if (expression is ir.VariableGet &&
        !_invalidatedVariables.contains(expression.variable)) {
      // If `expression == null` is true, we promote the type of the
      // variable to `Null` by registering that is known _not_ to be of its
      // declared type.
      TypeMap notOfItsDeclaredType = afterInvocation.promote(
          expression.variable, expression.variable.type,
          isTrue: false);
      TypeMap ofItsDeclaredType = afterInvocation
          .promote(expression.variable, expression.variable.type, isTrue: true);
      typeMapWhenTrue = notOfItsDeclaredType;
      typeMapWhenFalse = ofItsDeclaredType;
    }
  }

  @override
  ir.DartType visitInstanceInvocation(ir.InstanceInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType receiverType = visitNode(node.receiver);
    ir.Member interfaceTarget = node.interfaceTarget;
    // We compute the function type instead of reading it of [node] since the
    // receiver and argument types might have improved through inference of
    // effectively final variable types and type promotion.
    ir.DartType functionType = _computeInstanceInvocationType(
        receiverType, interfaceTarget, node.arguments, argumentTypes);
    if (functionType != node.functionType) {
      node.functionType = functionType as ir.FunctionType;
      // TODO(johnniwinther): To provide the static guarantee that arguments
      // of a statically typed call have been checked against the parameter
      // types we need to call [_updateMethodInvocationTarget]. This can create
      // uses of type variables are not registered with the closure model so
      // we skip it for now. Note that this invariant is not currently used
      // in later phases since it wasn't provided for function invocations in
      // the old method invocation encoding.
      //_updateMethodInvocationTarget(node, argumentTypes, functionType);
    }
    ir.DartType returnType = _getFunctionReturnType(functionType);
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    handleInstanceInvocation(
        node, receiverType, interfaceTarget, argumentTypes);
    _staticTypeCache._expressionTypes[node] = returnType;
    return returnType;
  }

  @override
  ir.DartType visitInstanceGetterInvocation(ir.InstanceGetterInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType receiverType = visitNode(node.receiver);
    ir.Member interfaceTarget = node.interfaceTarget;
    // We compute the function type instead of reading it of [node] since the
    // receiver and argument types might have improved through inference of
    // effectively final variable types and type promotion.
    ir.DartType functionType = _computeInstanceInvocationType(
        receiverType, interfaceTarget, node.arguments, argumentTypes);
    if (functionType is ir.FunctionType && functionType != node.functionType) {
      node.functionType = functionType;
      _updateMethodInvocationTarget(node, argumentTypes, functionType);
    }
    ir.DartType returnType = _getFunctionReturnType(functionType);
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    handleInstanceInvocation(
        node, receiverType, interfaceTarget, argumentTypes);
    _staticTypeCache._expressionTypes[node] = returnType;
    return returnType;
  }

  @override
  ir.DartType visitDynamicInvocation(ir.DynamicInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType receiverType = visitNode(node.receiver);
    ir.Member? interfaceTarget = _resolveDynamicInvocationTarget(
        receiverType, node.name, node.arguments);
    if (interfaceTarget != null) {
      // We can turn the dynamic invocation into an instance invocation.
      ir.DartType functionType = _computeInstanceInvocationType(
          receiverType, interfaceTarget, node.arguments, argumentTypes);
      ir.InvocationExpression replacement;
      if (interfaceTarget is ir.Field ||
          (interfaceTarget is ir.Procedure && interfaceTarget.isGetter)) {
        // This should actually be a function invocation of an instance get but
        // this doesn't work for invocation of js-interop properties. We
        // therefore use [ir.InstanceGetterInvocation] instead.
        replacement = ir.InstanceGetterInvocation(
            ir.InstanceAccessKind.Instance,
            node.receiver,
            node.name,
            node.arguments,
            interfaceTarget: interfaceTarget,
            functionType: functionType is ir.FunctionType ? functionType : null)
          ..fileOffset = node.fileOffset;
      } else {
        replacement = ir.InstanceInvocation(ir.InstanceAccessKind.Instance,
            node.receiver, node.name, node.arguments,
            interfaceTarget: interfaceTarget as ir.Procedure,
            functionType: functionType as ir.FunctionType)
          ..fileOffset = node.fileOffset;
      }
      _replaceExpression(node, replacement);
      _updateMethodInvocationTarget(replacement, argumentTypes, functionType);
      ir.DartType resultType = _getFunctionReturnType(functionType);
      receiverType = _narrowInstanceReceiver(interfaceTarget, receiverType);
      handleInstanceInvocation(
          replacement, receiverType, interfaceTarget, argumentTypes);
      return resultType;
    } else if (node.name == ir.Name.callName &&
        (receiverType is ir.FunctionType ||
            (receiverType is ir.InterfaceType &&
                receiverType.classNode == typeEnvironment.functionClass)) &&
        _isApplicableToType(node.arguments, receiverType)) {
      ir.DartType functionType =
          _computeFunctionInvocationType(receiverType, node.arguments);
      bool hasFunctionType = functionType is ir.FunctionType;
      ir.FunctionInvocation replacement = ir.FunctionInvocation(
          hasFunctionType
              ? ir.FunctionAccessKind.FunctionType
              : ir.FunctionAccessKind.Function,
          node.receiver,
          node.arguments,
          functionType: hasFunctionType ? functionType : null)
        ..fileOffset = node.fileOffset;
      ir.DartType resultType = _getFunctionReturnType(functionType);
      _replaceExpression(node, replacement);
      _updateMethodInvocationTarget(replacement, argumentTypes, functionType);
      handleFunctionInvocation(
          replacement, receiverType, argumentTypes, resultType);
      return resultType;
    } else {
      ir.DartType returnType =
          _computeDynamicInvocationReturnType(node, receiverType);
      _staticTypeCache._expressionTypes[node] = returnType;
      handleDynamicInvocation(node, receiverType, argumentTypes, returnType);
      if (operatorFromString(node.name.text) == null &&
          receiverType is ir.DynamicType) {
        // We might implicitly call a getter that returns a function.
        handleFunctionInvocation(
            node, const ir.DynamicType(), argumentTypes, returnType);
      }
      return returnType;
    }
  }

  @override
  ir.DartType visitEqualsCall(ir.EqualsCall node) {
    ir.DartType leftType = visitNode(node.left);
    ir.DartType rightType = visitNode(node.right);
    // This is accessed to ensure that [typeMapWhenTrue] and [typeMapWhenFalse]
    // are joined as the result of this node.
    // This is related to dartbug.com/45053
    _flattenTypeMap();
    leftType = _narrowInstanceReceiver(node.interfaceTarget, leftType);
    handleEqualsCall(
        node.left, leftType, node.right, rightType, node.interfaceTarget);
    return super.visitEqualsCall(node);
  }

  void handleEqualsNull(ir.EqualsNull node, ir.DartType expressionType) {}

  @override
  ir.DartType visitEqualsNull(ir.EqualsNull node) {
    ir.DartType expressionType = visitNode(node.expression);
    if (expressionType is ir.DynamicType) {
      expressionType = currentLibrary.isNonNullableByDefault
          ? typeEnvironment.objectNullableRawType
          : typeEnvironment.objectLegacyRawType;
    }
    _registerEqualsNull(typeMap, node.expression);
    handleEqualsNull(node, expressionType);
    return super.visitEqualsNull(node);
  }

  @override
  ir.DartType visitFunctionInvocation(ir.FunctionInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType functionType =
        _computeFunctionInvocationType(receiverType, node.arguments);
    if (functionType is ir.FunctionType) {
      // We might have improved the known function type through inference of
      // effectively final variable types and type promotion.
      node.functionType = functionType;
    }
    // We compute the return type instead of reading it of [node] since the
    // receiver and argument types might have improved through inference of
    // effectively final variable types and type promotion.
    ir.DartType returnType = _getFunctionReturnType(functionType);
    handleFunctionInvocation(node, functionType, argumentTypes, returnType);
    return returnType;
  }

  @override
  ir.DartType visitLocalFunctionInvocation(ir.LocalFunctionInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.FunctionDeclaration localFunction = node.localFunction;
    ir.DartType returnType = super.visitLocalFunctionInvocation(node);
    handleLocalFunctionInvocation(
        node, localFunction, argumentTypes, returnType);
    return returnType;
  }

  void handleVariableGet(ir.VariableGet node, ir.DartType type) {}

  @override
  ir.DartType visitVariableGet(ir.VariableGet node) {
    ir.DartType frontendType = node.getStaticType(staticTypeContext);
    ir.DartType staticType;
    if (currentLibrary.isNonNullableByDefault) {
      staticType = frontendType;
    } else {
      typeMapsForTesting?[node] = typeMap;
      staticType = typeMap.typeOf(node, typeEnvironment);
      assert(
          typeEnvironment.isSubtypeOf(staticType, frontendType,
              ir.SubtypeCheckMode.ignoringNullabilities),
          "Unexpected promotion of ${node.variable} in ${node.parent}. "
          "Expected $frontendType, found $staticType");
    }
    _staticTypeCache._expressionTypes[node] = staticType;
    handleVariableGet(node, staticType);
    return staticType;
  }

  void handleVariableSet(ir.VariableSet node, ir.DartType resultType) {}

  @override
  ir.DartType visitVariableSet(ir.VariableSet node) {
    ir.DartType resultType = super.visitVariableSet(node);
    handleVariableSet(node, resultType);
    if (!_currentVariables!.contains(node.variable)) {
      _invalidatedVariables.add(node.variable);
      typeMap = typeMap.remove([node.variable]);
    } else {
      typeMap = typeMap.reduce(node, resultType, typeEnvironment);
    }
    return resultType;
  }

  void handleStaticGet(
      ir.Expression node, ir.Member target, ir.DartType resultType) {}

  void handleStaticTearOff(
      ir.Expression node, ir.Procedure target, ir.DartType resultType) {}

  @override
  ir.DartType visitStaticGet(ir.StaticGet node) {
    ir.DartType resultType = super.visitStaticGet(node);
    ir.Member target = node.target;
    if (target is ir.Procedure && target.kind == ir.ProcedureKind.Method) {
      // TODO(johnniwinther): Remove this when dart2js uses the new method
      // invocation encoding.
      handleStaticTearOff(node, target, resultType);
    } else {
      handleStaticGet(node, target, resultType);
    }
    return resultType;
  }

  @override
  ir.DartType visitStaticTearOff(ir.StaticTearOff node) {
    ir.DartType resultType = super.visitStaticTearOff(node);
    handleStaticTearOff(node, node.target, resultType);
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

  void handleWeakStaticTearOff(ir.Expression node, ir.Procedure target) {}

  @override
  ir.DartType visitStaticInvocation(ir.StaticInvocation node) {
    ir.DartType returnType = ir.Substitution.fromPairs(
            node.target.function.typeParameters, node.arguments.types)
        .substituteType(node.target.function.returnType);
    _staticTypeCache._expressionTypes[node] = returnType;
    if (ir.StaticWeakReferences.isWeakReference(node)) {
      handleWeakStaticTearOff(
          ir.StaticWeakReferences.getWeakReferenceArgument(node),
          ir.StaticWeakReferences.getWeakReferenceTarget(node));
    } else {
      ArgumentTypes argumentTypes = _visitArguments(node.arguments);
      handleStaticInvocation(node, argumentTypes, returnType);
    }
    return returnType;
  }

  void handleConstructorInvocation(ir.ConstructorInvocation node,
      ArgumentTypes argumentTypes, ir.DartType resultType) {}

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType resultType = node.arguments.types.isEmpty
        ? ExactInterfaceType.from(typeEnvironment.coreTypes
            .nonNullableRawType(node.target.enclosingClass))
        : ExactInterfaceType(node.target.enclosingClass,
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
    final interfaceTarget = node.interfaceTarget;
    ir.Class declaringClass = interfaceTarget.enclosingClass!;
    if (declaringClass.typeParameters.isEmpty) {
      resultType = interfaceTarget.superGetterType;
    } else {
      ir.InterfaceType receiver = typeEnvironment.getTypeAsInstanceOf(
          thisType, declaringClass, typeEnvironment.coreTypes,
          isNonNullableByDefault: currentLibrary.isNonNullableByDefault)!;
      resultType = ir.Substitution.fromInterfaceType(receiver)
          .substituteType(interfaceTarget.superGetterType);
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
    final interfaceTarget = node.interfaceTarget;
    ir.Class superclass = interfaceTarget.enclosingClass!;
    ir.InterfaceType receiverType = typeEnvironment.getTypeAsInstanceOf(
        thisType, superclass, typeEnvironment.coreTypes,
        isNonNullableByDefault: currentLibrary.isNonNullableByDefault)!;
    returnType = ir.Substitution.fromInterfaceType(receiverType)
        .substituteType(interfaceTarget.function.returnType);
    returnType = ir.Substitution.fromPairs(
            interfaceTarget.function.typeParameters, node.arguments.types)
        .substituteType(returnType);
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

  ir.DartType? _handleConditional(
      ir.Expression condition, ir.TreeNode then, ir.TreeNode? otherwise) {
    visitNode(condition);
    TypeMap afterConditionWhenTrue = typeMapWhenTrue;
    TypeMap afterConditionWhenFalse = typeMapWhenFalse;
    typeMap = afterConditionWhenTrue;
    ir.DartType thenType = visitNode(then);
    TypeMap afterThen = typeMap;
    typeMap = afterConditionWhenFalse;
    ir.DartType? otherwiseType = visitNodeOrNull(otherwise);
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
      return const ir.NeverType.nonNullable();
    }
  }

  @override
  ir.DartType visitConditionalExpression(ir.ConditionalExpression node) {
    // TODO(johnniwinther): Should we return `const ir.NeverType.nonNullable()` if
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
    ir.FunctionType expressionType =
        visitNode(node.expression) as ir.FunctionType;
    ir.DartType resultType = _computeInstantiationType(node, expressionType);
    _staticTypeCache._expressionTypes[node] = resultType;
    handleInstantiation(node, expressionType, resultType);
    return resultType;
  }

  @override
  ir.DartType visitBlock(ir.Block node) {
    assert(_pendingRuntimeTypeUseData.isEmpty,
        "Incomplete RuntimeTypeUseData: $_pendingRuntimeTypeUseData");
    ir.DartType? type;
    for (ir.Statement statement in node.statements) {
      if (!completes(visitNode(statement))) {
        type = const ir.NeverType.nonNullable();
      }
    }
    assert(_pendingRuntimeTypeUseData.isEmpty,
        "Incomplete RuntimeTypeUseData: $_pendingRuntimeTypeUseData");
    return type ?? const ir.VoidType();
  }

  @override
  ir.DartType visitExpressionStatement(ir.ExpressionStatement node) {
    if (completes(visitNode(node.expression))) {
      return const ir.VoidType();
    } else {
      return const ir.NeverType.nonNullable();
    }
  }

  void handleAsExpression(ir.AsExpression node, ir.DartType operandType,
      {bool? isCalculatedTypeSubtype}) {}

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    final operand = node.operand;
    ir.DartType operandType = visitNode(operand);
    // Check if the calculated operandType is a subtype of the type specified
    // in the `as` expression.
    final isCalculatedTypeSubtype = typeEnvironment.isSubtypeOf(
        operandType, node.type, ir.SubtypeCheckMode.ignoringNullabilities);
    if (!isCalculatedTypeSubtype &&
        operand is ir.VariableGet &&
        !_invalidatedVariables.contains(operand.variable)) {
      typeMap = typeMap.promote(operand.variable, node.type, isTrue: true);
    }
    handleAsExpression(node, operandType,
        isCalculatedTypeSubtype: isCalculatedTypeSubtype);
    return super.visitAsExpression(node);
  }

  void handleNullCheck(ir.NullCheck node, ir.DartType operandType) {}

  @override
  ir.DartType visitNullCheck(ir.NullCheck node) {
    ir.DartType operandType = visitNode(node.operand);
    handleNullCheck(node, operandType);
    ir.DartType resultType = operandType is ir.NullType
        ? const ir.NeverType.nonNullable()
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
  ir.DartType visitMapLiteralEntry(ir.MapLiteralEntry entry) {
    visitNode(entry.key);
    visitNode(entry.value);
    return const ir.VoidType();
  }

  void handleRecordLiteral(ir.RecordLiteral node) {}

  @override
  ir.DartType visitRecordLiteral(ir.RecordLiteral node) {
    visitNodes(node.positional);
    for (final namedExpression in node.named) {
      visitNode(namedExpression.value);
    }
    handleRecordLiteral(node);
    return super.visitRecordLiteral(node);
  }

  void handleFunctionExpression(ir.FunctionExpression node) {}

  @override
  ir.DartType visitFunctionExpression(ir.FunctionExpression node) {
    TypeMap beforeClosure =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    typeMap = typeMap.remove(variableScopeModel.assignedVariables);
    ir.DartType returnType = super.visitFunctionExpression(node);
    Set<ir.VariableDeclaration>? _oldVariables = _currentVariables;
    _currentVariables = {};
    visitSignature(node.function);
    visitNodeOrNull(node.function.body);
    handleFunctionExpression(node);
    _invalidatedVariables.removeAll(_currentVariables!);
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
  ir.DartType visitSwitchCase(ir.SwitchCase node) {
    visitNodes(node.expressions);
    visitNode(node.body);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    return const ir.NeverType.nonNullable();
  }

  @override
  ir.DartType visitLabeledStatement(ir.LabeledStatement node) {
    visitNode(node.body);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitBreakStatement(ir.BreakStatement node) {
    return const ir.NeverType.nonNullable();
  }

  @override
  ir.DartType visitYieldStatement(ir.YieldStatement node) {
    visitNode(node.expression);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitAssertInitializer(ir.AssertInitializer node) {
    visitNode(node.statement);
    return const ir.VoidType();
  }

  void handleFieldInitializer(ir.FieldInitializer node) {}

  @override
  ir.DartType visitFieldInitializer(ir.FieldInitializer node) {
    visitNode(node.value);
    handleFieldInitializer(node);
    return const ir.VoidType();
  }

  void handleRedirectingInitializer(
      ir.RedirectingInitializer node, ArgumentTypes argumentTypes) {}

  @override
  ir.DartType visitRedirectingInitializer(ir.RedirectingInitializer node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    handleRedirectingInitializer(node, argumentTypes);
    return const ir.VoidType();
  }

  void handleSuperInitializer(
      ir.SuperInitializer node, ArgumentTypes argumentTypes) {}

  @override
  ir.DartType visitSuperInitializer(ir.SuperInitializer node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    handleSuperInitializer(node, argumentTypes);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitLocalInitializer(ir.LocalInitializer node) {
    visitNode(node.variable);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitNamedExpression(ir.NamedExpression node) =>
      visitNode(node.value);

  @override
  ir.DartType visitEmptyStatement(ir.EmptyStatement node) =>
      const ir.VoidType();

  @override
  ir.DartType visitForStatement(ir.ForStatement node) {
    visitNodes(node.variables);
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNodeOrNull(node.condition);
    typeMap = typeMapWhenTrue;
    visitNode(node.body);
    visitNodes(node.updates);
    typeMap = beforeLoop;
    return const ir.VoidType();
  }

  void handleForInStatement(ir.ForInStatement node, ir.DartType iterableType,
      ir.DartType iteratorType) {}

  @override
  ir.DartType visitForInStatement(ir.ForInStatement node) {
    // For sync for-in [iterableType] is a subtype of `Iterable`, for async
    // for-in [iterableType] is a subtype of `Stream`.
    ir.DartType iterableType = visitNode(node.iterable);
    ir.DartType iteratorType = const ir.DynamicType();
    ir.InterfaceType? iterableInterfaceType = getInterfaceTypeOf(iterableType);
    if (iterableInterfaceType != null) {
      if (node.isAsync) {
        ir.InterfaceType? streamType = typeEnvironment.getTypeAsInstanceOf(
            iterableInterfaceType,
            typeEnvironment.coreTypes.streamClass,
            typeEnvironment.coreTypes,
            isNonNullableByDefault: currentLibrary.isNonNullableByDefault);
        if (streamType != null) {
          iteratorType = ir.InterfaceType(
              typeEnvironment.coreTypes.streamIteratorClass,
              ir.Nullability.nonNullable,
              streamType.typeArguments);
        }
      } else {
        ir.Member? member = hierarchy.getInterfaceMember(
            iterableInterfaceType.classNode, ir.Name(Identifiers.iterator));
        if (member != null) {
          iteratorType = ir.Substitution.fromInterfaceType(
                  typeEnvironment.getTypeAsInstanceOf(iterableInterfaceType,
                      member.enclosingClass!, typeEnvironment.coreTypes,
                      isNonNullableByDefault:
                          currentLibrary.isNonNullableByDefault)!)
              .substituteType(member.getterType);
        }
      }
    }
    _staticTypeCache._forInIteratorTypes[node] = iteratorType;
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.variable);
    visitNode(node.body);
    handleForInStatement(node, iterableType, iteratorType);
    typeMap = beforeLoop;
    return const ir.VoidType();
  }

  @override
  ir.DartType visitDoStatement(ir.DoStatement node) {
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.body);
    visitNode(node.condition);
    typeMap = beforeLoop;
    return const ir.VoidType();
  }

  @override
  ir.DartType visitWhileStatement(ir.WhileStatement node) {
    TypeMap beforeLoop = typeMap =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    visitNode(node.condition);
    typeMap = typeMapWhenTrue;
    visitNode(node.body);
    typeMap = beforeLoop;
    return const ir.VoidType();
  }

  void handleSwitchStatement(ir.SwitchStatement node) {}

  @override
  ir.DartType visitSwitchStatement(ir.SwitchStatement node) {
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
    return const ir.VoidType();
  }

  @override
  ir.DartType visitReturnStatement(ir.ReturnStatement node) {
    visitNodeOrNull(node.expression);
    return const ir.NeverType.nonNullable();
  }

  @override
  ir.DartType visitIfStatement(ir.IfStatement node) {
    _handleConditional(node.condition, node.then, node.otherwise);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitTryCatch(ir.TryCatch node) {
    visitNode(node.body);
    visitNodes(node.catches);
    return const ir.VoidType();
  }

  void handleCatch(ir.Catch node) {}

  @override
  ir.DartType visitCatch(ir.Catch node) {
    handleCatch(node);
    visitNode(node.body);
    return const ir.VoidType();
  }

  @override
  ir.DartType visitTryFinally(ir.TryFinally node) {
    visitNode(node.body);
    visitNode(node.finalizer);
    return const ir.VoidType();
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
  ir.DartType visitAssertStatement(ir.AssertStatement node) {
    TypeMap beforeCondition = typeMap;
    visitNode(node.condition);
    TypeMap afterConditionWhenTrue = typeMapWhenTrue;
    TypeMap afterConditionWhenFalse = typeMapWhenFalse;
    typeMap = afterConditionWhenFalse;
    visitNodeOrNull(node.message);
    handleAssertStatement(node);
    typeMap = useAsserts ? afterConditionWhenTrue : beforeCondition;
    return const ir.VoidType();
  }

  void handleFunctionDeclaration(ir.FunctionDeclaration node) {}

  @override
  ir.DartType visitFunctionDeclaration(ir.FunctionDeclaration node) {
    TypeMap beforeClosure =
        typeMap.remove(variableScopeModel.getScopeFor(node).assignedVariables);
    typeMap = typeMap.remove(variableScopeModel.assignedVariables);
    Set<ir.VariableDeclaration>? _oldVariables = _currentVariables;
    _currentVariables = {};
    visitSignature(node.function);
    visitNodeOrNull(node.function.body);
    handleFunctionDeclaration(node);
    _invalidatedVariables.removeAll(_currentVariables!);
    _currentVariables = _oldVariables;
    typeMap = beforeClosure;
    return const ir.VoidType();
  }

  void handleParameter(ir.VariableDeclaration node) {}

  void visitParameter(ir.VariableDeclaration node) {
    _currentVariables?.add(node);
    visitNodeOrNull(node.initializer);
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
  ir.DartType visitProcedure(ir.Procedure node) {
    thisType = ThisInterfaceType.from(node.enclosingClass?.getThisType(
        typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable));
    _currentVariables = {};
    currentLibrary = node.enclosingLibrary;
    visitSignature(node.function);
    visitNodeOrNull(node.function.body);
    handleProcedure(node);
    _invalidatedVariables.removeAll(_currentVariables!);
    _currentVariables = null;
    thisType = null;
    currentLibrary = null;
    return const ir.VoidType();
  }

  void handleConstructor(ir.Constructor node) {}

  @override
  ir.DartType visitConstructor(ir.Constructor node) {
    thisType = ThisInterfaceType.from(node.enclosingClass.getThisType(
        typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable));
    _currentVariables = {};
    currentLibrary = node.enclosingLibrary;
    visitSignature(node.function);
    visitNodes(node.initializers);
    visitNodeOrNull(node.function.body);
    handleConstructor(node);
    _invalidatedVariables.removeAll(_currentVariables!);
    _currentVariables = null;
    thisType = null;
    currentLibrary = null;
    return const ir.VoidType();
  }

  void handleField(ir.Field node) {}

  @override
  ir.DartType visitField(ir.Field node) {
    thisType = ThisInterfaceType.from(node.enclosingClass?.getThisType(
        typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable));
    _currentVariables = {};
    currentLibrary = node.enclosingLibrary;
    visitNodeOrNull(node.initializer);
    handleField(node);
    _invalidatedVariables.removeAll(_currentVariables!);
    _currentVariables = null;
    thisType = null;
    currentLibrary = null;
    return const ir.VoidType();
  }

  void handleVariableDeclaration(ir.VariableDeclaration node) {}

  void _processLocalVariable(ir.VariableDeclaration node) {
    _currentVariables?.add(node);
    final initializer = node.initializer;
    if (initializer != null) {
      ir.DartType type = visitNode(initializer);
      if (variableScopeModel.isEffectivelyFinal(node) &&
          inferEffectivelyFinalVariableTypes) {
        node.type = type;
      }
    }
  }

  @override
  ir.DartType visitVariableDeclaration(ir.VariableDeclaration node) {
    _processLocalVariable(node);
    handleVariableDeclaration(node);
    return const ir.VoidType();
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

  @override
  String toString() {
    return 'ArgumentTypes(position=[${positional.join(',')}],'
        ' named=[${named.join(',')}])';
  }
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
  final Set<ir.DartType>? trueTypes;

  /// The types that the local variable is known _not_ to be an instance of.
  final Set<ir.DartType>? falseTypes;

  TypeHolder(this.declaredType, this.trueTypes, this.falseTypes);

  /// Computes a single type that soundly represents the promoted type of the
  /// local variable on this single path.
  ir.DartType? typeOf(ir.TypeEnvironment typeEnvironment) {
    ir.DartType candidate = declaredType;
    final trueTypes = this.trueTypes;
    final falseTypes = this.falseTypes;
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
  late final int hashCode = Hashing.setHash(
      falseTypes, Hashing.setHash(trueTypes, Hashing.objectHash(declaredType)));

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
    final trueTypes = this.trueTypes;
    final falseTypes = this.falseTypes;
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
    StringBuffer sb = StringBuffer();
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
  TargetInfo promote(ir.DartType type, {required bool isTrue}) {
    Set<TypeHolder> newTypeHolders = {};

    bool addTypeHolder(TypeHolder? typeHolder) {
      bool changed = false;

      Set<ir.DartType> addAsCopy(Set<ir.DartType>? set, ir.DartType type) {
        Set<ir.DartType> result;
        if (set == null) {
          result = {};
        } else if (set.contains(type)) {
          return set;
        } else {
          result = Set.of(set);
        }
        changed = true;
        return result..add(type);
      }

      Set<ir.DartType>? trueTypes = typeHolder?.trueTypes;
      Set<ir.DartType>? falseTypes = typeHolder?.falseTypes;
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
      newTypesOfInterest = {...typesOfInterest, type};
      changed = true;
    }
    return changed
        ? TargetInfo(declaredType, newTypeHolders, newTypesOfInterest)
        : this;
  }

  /// Returns the [TargetInfo] that describes that the local is either of [this]
  /// or the [other] type.
  ///
  /// Returns `null` if the join is empty.
  TargetInfo? join(TargetInfo? other) {
    if (other == null) return null;
    if (identical(this, other)) return this;

    Set<TypeHolder> newTypeHolders = {};
    Set<ir.DartType> newTypesOfInterest = {};

    /// Adds the [typeHolders] to [newTypeHolders] for types in
    /// [otherTypesOfInterest] while removing the information
    /// invalidated by [otherTrueTypes] and [otherFalseTypes].
    void addTypeHolders(
        Iterable<TypeHolder> typeHolders,
        Set<ir.DartType> otherTrueTypes,
        Set<ir.DartType> otherFalseTypes,
        Iterable<ir.DartType> otherTypesOfInterest) {
      for (TypeHolder typeHolder in typeHolders) {
        Set<ir.DartType>? newTrueTypes;
        final holderTrueTypes = typeHolder.trueTypes;
        if (holderTrueTypes != null) {
          newTrueTypes = Set.of(holderTrueTypes);

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
        Set<ir.DartType>? newFalseTypes;
        final holderFalseTypes = typeHolder.falseTypes;
        if (holderFalseTypes != null) {
          newFalseTypes = Set.of(holderFalseTypes);

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
              .add(TypeHolder(declaredType, newTrueTypes, newFalseTypes));
        }
      }
    }

    Set<ir.DartType> thisTrueTypes = {};
    Set<ir.DartType> thisFalseTypes = {};
    for (TypeHolder typeHolder in typeHolders) {
      final holderTrueTypes = typeHolder.trueTypes;
      final holderFalseTypes = typeHolder.falseTypes;
      if (holderTrueTypes != null) {
        thisTrueTypes.addAll(holderTrueTypes);
      }
      if (holderFalseTypes != null) {
        thisFalseTypes.addAll(holderFalseTypes);
      }
    }

    Set<ir.DartType> otherTrueTypes = {};
    Set<ir.DartType> otherFalseTypes = {};
    for (TypeHolder typeHolder in other.typeHolders) {
      final holderTrueTypes = typeHolder.trueTypes;
      final holderFalseTypes = typeHolder.falseTypes;
      if (holderTrueTypes != null) {
        otherTrueTypes.addAll(holderTrueTypes);
      }
      if (holderFalseTypes != null) {
        otherFalseTypes.addAll(holderFalseTypes);
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

    return TargetInfo(declaredType, newTypeHolders, newTypesOfInterest);
  }

  /// Computes a single type that soundly represents the promoted type of the
  /// local variable on all possible paths.
  ir.DartType? typeOf(ir.TypeEnvironment typeEnvironment) {
    ir.DartType? candidate = null;
    for (TypeHolder typeHolder in typeHolders) {
      ir.DartType? type = typeHolder.typeOf(typeEnvironment);
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
    StringBuffer sb = StringBuffer();
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
      {required bool isTrue}) {
    Map<ir.VariableDeclaration, TargetInfo> newInfoMap = Map.of(_targetInfoMap);
    TargetInfo? targetInfo = newInfoMap[variable];
    bool changed = false;
    if (targetInfo != null) {
      TargetInfo result = targetInfo.promote(type, isTrue: isTrue);
      changed = !identical(targetInfo, result);
      targetInfo = result;
    } else {
      changed = true;
      Set<ir.DartType>? trueTypes = isTrue ? {type} : null;
      Set<ir.DartType>? falseTypes = isTrue ? null : {type};
      TypeHolder typeHolder = TypeHolder(variable.type, trueTypes, falseTypes);
      targetInfo = TargetInfo(
          variable.type, <TypeHolder>[typeHolder], <ir.DartType>[type]);
    }
    newInfoMap[variable] = targetInfo;
    return changed ? TypeMap(newInfoMap) : this;
  }

  /// Returns the [TypeMap] that describes that the locals are either of [this]
  /// or the [other] types.
  TypeMap join(TypeMap other) {
    if (identical(this, other)) return this;

    Map<ir.VariableDeclaration, TargetInfo> newInfoMap = {};
    bool changed = false;
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      TargetInfo? result = info.join(other._targetInfoMap[variable]);
      changed |= !identical(info, result);
      if (result != null) {
        // Add only non-empty information.
        newInfoMap[variable] = result;
      }
    });
    return changed ? TypeMap(newInfoMap) : this;
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
    return changed ? TypeMap(newInfoMap) : this;
  }

  /// Returns the [TypeMap] where type information for `node.variable` is
  /// reduced to the promotions upheld by an assignment to `node.variable` of
  /// the static [type].
  TypeMap reduce(ir.VariableSet node, ir.DartType? type,
      ir.TypeEnvironment typeEnvironment) {
    Map<ir.VariableDeclaration, TargetInfo> newInfoMap = {};
    bool changed = false;
    _targetInfoMap.forEach((ir.VariableDeclaration variable, TargetInfo info) {
      if (variable != node.variable) {
        newInfoMap[variable] = info;
      } else if (type != null) {
        changed = true;
        Set<ir.DartType> newTypesOfInterest = {};
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
              TypeHolder(info.declaredType, newTypesOfInterest, null);
          TypeHolder typeHolderIfNull =
              TypeHolder(info.declaredType, null, {info.declaredType});
          newInfoMap[variable] = TargetInfo(
              info.declaredType,
              <TypeHolder>[typeHolderIfNonNull, typeHolderIfNull],
              newTypesOfInterest);
        }
      } else {
        changed = true;
      }
    });
    return changed ? TypeMap(newInfoMap) : this;
  }

  /// Computes a single type that soundly represents the promoted type of
  /// `node.variable` on all possible paths.
  ir.DartType typeOf(ir.VariableGet node, ir.TypeEnvironment typeEnvironment) {
    TargetInfo? info = _targetInfoMap[node.variable];
    ir.DartType? type;
    if (info != null) {
      type = info.typeOf(typeEnvironment);
    }
    return type ?? node.promotedType ?? node.variable.type;
  }

  String getText(String Function(Iterable<ir.DartType>) typesToText) {
    StringBuffer sb = StringBuffer();
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
    StringBuffer sb = StringBuffer();
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
