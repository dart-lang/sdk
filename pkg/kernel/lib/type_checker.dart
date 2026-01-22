// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.type_checker;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'names.dart';
import 'type_algebra.dart';
import 'type_environment.dart';
import 'src/non_null.dart';

/// Performs type checking on the kernel IR.
///
/// A concrete subclass of [TypeChecker] must implement [checkAssignable] and
/// [fail] in order to deal with subtyping requirements and error handling.
abstract class TypeChecker {
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final bool ignoreSdk;
  final TypeEnvironment environment;
  Library? currentLibrary;
  InterfaceType? currentThisType;

  TypeChecker(this.coreTypes, this.hierarchy, {this.ignoreSdk = true})
      : environment = new TypeEnvironment(coreTypes, hierarchy);

  void checkComponent(Component component) {
    for (Library library in component.libraries) {
      if (ignoreSdk && library.importUri.isScheme('dart')) continue;
      for (Class class_ in library.classes) {
        hierarchy.forEachOverridePair(class_,
            (Member ownMember, Member superMember, bool isSetter) {
          checkOverride(class_, ownMember, superMember, isSetter);
        });
      }
    }
    TypeCheckingVisitor visitor =
        new TypeCheckingVisitor(this, environment, hierarchy);
    for (Library library in component.libraries) {
      currentLibrary = library;
      if (ignoreSdk && library.importUri.isScheme('dart')) continue;
      for (Class class_ in library.classes) {
        currentThisType = coreTypes.thisInterfaceType(
            class_, class_.enclosingLibrary.nonNullable);
        for (Field field in class_.fields) {
          visitor.visitField(field);
        }
        for (Constructor constructor in class_.constructors) {
          visitor.visitConstructor(constructor);
        }
        for (Procedure procedure in class_.procedures) {
          visitor.visitProcedure(procedure);
        }
      }
      currentThisType = null;
      for (Procedure procedure in library.procedures) {
        visitor.visitProcedure(procedure);
      }
      for (Field field in library.fields) {
        visitor.visitField(field);
      }
      currentLibrary = null;
    }
  }

  DartType getterType(Class host, Member member) {
    Supertype hostType =
        hierarchy.getClassAsInstanceOf(host, member.enclosingClass!)!;
    Substitution substitution = Substitution.fromSupertype(hostType);
    return substitution.substituteType(member.getterType);
  }

  DartType setterType(Class host, Member member) {
    Supertype hostType =
        hierarchy.getClassAsInstanceOf(host, member.enclosingClass!)!;
    Substitution substitution = Substitution.fromSupertype(hostType);
    return substitution.substituteType(member.setterType, contravariant: true);
  }

  /// Check that [ownMember] of [host] can override [superMember].
  void checkOverride(
      Class host, Member ownMember, Member superMember, bool isSetter) {
    if (isSetter) {
      checkAssignable(ownMember, setterType(host, superMember),
          setterType(host, ownMember));
    } else {
      checkAssignable(ownMember, getterType(host, ownMember),
          getterType(host, superMember));
    }
  }

  /// Check that [from] is a subtype of [to].
  ///
  /// [where] is an AST node indicating roughly where the check is required.
  void checkAssignable(TreeNode where, DartType from, DartType to);

  /// Check unresolved invocation (one that has no interfaceTarget)
  /// and report an error if necessary.
  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    // By default we ignore unresolved method invocations.
  }

  /// Indicates that type checking failed.
  void fail(TreeNode where, String message);
}

class TypeCheckingVisitor
    with StatementVisitorExperimentExclusionMixin<void>
    implements
        ExpressionVisitor<DartType>,
        StatementVisitor<void>,
        MemberVisitor<void>,
        InitializerVisitor<void> {
  final TypeChecker checker;
  final TypeEnvironment environment;
  final ClassHierarchy hierarchy;

  CoreTypes get coreTypes => environment.coreTypes;
  Library? get currentLibrary => checker.currentLibrary;
  Class? get currentClass => checker.currentThisType?.classNode;
  InterfaceType? get currentThisType => checker.currentThisType;

  DartType? currentReturnType;
  DartType? currentYieldType;
  AsyncMarker currentAsyncMarker = AsyncMarker.Sync;

  TypeCheckingVisitor(this.checker, this.environment, this.hierarchy);

  void checkAssignable(TreeNode where, DartType from, DartType to) {
    checker.checkAssignable(where, from, to);
  }

  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    checker.checkUnresolvedInvocation(receiver, where);
  }

  Expression checkExpressionAndAssignability(Expression from, DartType to) {
    DartType type = visitExpression(from);
    checker.checkAssignable(from, type, to);
    return from;
  }

  void checkExpressionNoDowncast(Expression expression, DartType to) {
    checkAssignable(expression, visitExpression(expression), to);
  }

  void fail(TreeNode node, String message) {
    checker.fail(node, message);
  }

  DartType visitExpression(Expression node) => node.accept(this);

  void visitStatement(Statement node) {
    node.accept(this);
  }

  void visitInitializer(Initializer node) {
    node.accept(this);
  }

  @override
  DartType visitAuxiliaryExpression(AuxiliaryExpression node) {
    throw new UnsupportedError(
        "Unsupported auxiliary expression ${node} (${node.runtimeType}).");
  }

  @override
  TreeNode visitAuxiliaryStatement(AuxiliaryStatement node) {
    throw new UnsupportedError(
        "Unsupported auxiliary statement ${node} (${node.runtimeType}).");
  }

  @override
  TreeNode visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    throw new UnsupportedError(
        "Unsupported auxiliary initializer ${node} (${node.runtimeType}).");
  }

  @override
  void visitField(Field node) {
    Expression? initializer = node.initializer;
    if (initializer != null) {
      bool initializerIsNullExpression = initializer is NullLiteral ||
          initializer is ConstantExpression && initializer.type is NullType;
      if (initializerIsNullExpression) {
        // We skip type checks for `null` as the initializer as follows:
        //
        //   * If [node.type] is nullable, `null` is a valid initializer and
        //     doesn't need to be checked.
        //   * If [node.type] is non-nullable, `null` encodes an issue elsewhere
        //     in an erroneous program, such as a final field not being
        //     initialized in the constructors.
        return;
      }
      node.initializer =
          checkExpressionAndAssignability(initializer, node.type);
    }
  }

  @override
  void visitConstructor(Constructor node) {
    currentReturnType = null;
    currentYieldType = null;
    if (!node.isErroneous) {
      node.initializers.forEach(visitInitializer);
      handleFunctionNode(node.function,
          // Constructors can't be abstract, but can be external.
          isPartOfAbstractExternalOrNoSuchMethodForwarderMember:
              node.isExternal);
    }
  }

  @override
  void visitProcedure(Procedure node) {
    currentReturnType = _getInternalReturnType(node.function);
    currentYieldType = _getYieldType(node.function);
    handleFunctionNode(node.function,
        isPartOfAbstractExternalOrNoSuchMethodForwarderMember:
            node.isAbstract ||
                node.isExternal ||
                node.stubKind == ProcedureStubKind.NoSuchMethodForwarder);
  }

  void handleFunctionNode(FunctionNode node,
      {required bool isPartOfAbstractExternalOrNoSuchMethodForwarderMember}) {
    AsyncMarker oldAsyncMarker = currentAsyncMarker;
    currentAsyncMarker = node.asyncMarker;
    for (int parameterIndex = 0;
        parameterIndex < node.positionalParameters.length;
        parameterIndex++) {
      if (parameterIndex >= node.requiredParameterCount) {
        handleOptionalParameter(node.positionalParameters[parameterIndex],
            isPartOfAbstractExternalOrNoSuchMethodForwarderMethod:
                isPartOfAbstractExternalOrNoSuchMethodForwarderMember);
      }
    }
    for (VariableDeclaration namedParameter in node.namedParameters) {
      if (!namedParameter.isRequired) {
        handleOptionalParameter(namedParameter,
            isPartOfAbstractExternalOrNoSuchMethodForwarderMethod:
                isPartOfAbstractExternalOrNoSuchMethodForwarderMember);
      }
    }
    if (node.body != null) {
      visitStatement(node.body!);
    }
    currentAsyncMarker = oldAsyncMarker;
  }

  void handleNestedFunctionNode(FunctionNode node) {
    DartType? oldReturn = currentReturnType;
    DartType? oldYield = currentYieldType;
    currentReturnType = _getInternalReturnType(node);
    currentYieldType = _getYieldType(node);
    handleFunctionNode(node,
        // Nested functions can't be abstract.
        isPartOfAbstractExternalOrNoSuchMethodForwarderMember: false);
    currentReturnType = oldReturn;
    currentYieldType = oldYield;
  }

  void handleOptionalParameter(VariableDeclaration parameter,
      {required bool isPartOfAbstractExternalOrNoSuchMethodForwarderMethod}) {
    Expression? initializer = parameter.initializer;
    if (initializer != null &&
        !parameter.isErroneouslyInitialized &&
        !isPartOfAbstractExternalOrNoSuchMethodForwarderMethod) {
      // Default parameter values cannot be downcast.
      checkExpressionNoDowncast(initializer, parameter.type);
    }
  }

  Substitution getReceiverType(
      TreeNode access, Expression receiver, Member member) {
    DartType type = visitExpression(receiver);
    TypeDeclaration typeDeclaration = member.enclosingTypeDeclaration!;
    if (typeDeclaration is Class && typeDeclaration.supertype == null) {
      return Substitution.empty; // Members on Object are always accessible.
    }

    type = type.nonTypeParameterBound;
    if (type is NeverType || type is NullType || type is InvalidType) {
      // The bottom type is a subtype of all types, so it should be allowed.
      return Substitution.bottomForTypeDeclaration(typeDeclaration);
    }
    if (type is InterfaceType && typeDeclaration is Class) {
      // The receiver type should implement the interface declaring the member.
      List<DartType>? upcastTypeArguments = hierarchy
          .getInterfaceTypeArgumentsAsInstanceOfClass(type, typeDeclaration);
      if (upcastTypeArguments != null) {
        return Substitution.fromPairs(
            typeDeclaration.typeParameters, upcastTypeArguments);
      }
    } else if (type is ExtensionType && typeDeclaration is Class) {
      // The receiver type should implement the interface declaring the member.
      List<DartType>? upcastTypeArguments = hierarchy
          .getExtensionTypeArgumentsAsInstanceOfClass(type, typeDeclaration);
      if (upcastTypeArguments != null) {
        return Substitution.fromPairs(
            typeDeclaration.typeParameters, upcastTypeArguments);
      }
    } else if (type is ExtensionType &&
        typeDeclaration is ExtensionTypeDeclaration) {
      // The receiver type should implement the interface declaring the member.
      List<DartType>? upcastTypeArguments = hierarchy
          .getExtensionTypeArgumentsAsInstanceOfExtensionTypeDeclaration(
              type, typeDeclaration);
      if (upcastTypeArguments != null) {
        return Substitution.fromPairs(
            typeDeclaration.typeParameters, upcastTypeArguments);
      }
    }
    if (type is FunctionType && typeDeclaration == coreTypes.functionClass) {
      assert(type.typeParameters.isEmpty);
      return Substitution.empty;
    }
    // Note that we do not allow 'dynamic' here.  Dynamic calls should not
    // have a declared interface target.
    fail(access, '$member is not accessible on a receiver of type $type');
    return Substitution.bottomForTypeDeclaration(
        typeDeclaration); // Continue type checking.
  }

  Substitution getSuperReceiverType(Member member) {
    return Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(currentClass!, member.enclosingClass!)!);
  }

  DartType handleCall(Arguments arguments, DartType functionType,
      {Substitution receiver = Substitution.empty,
      required Member target,
      bool isErroneousTarget = false}) {
    if (functionType is FunctionType) {
      if (arguments.positional.length < functionType.requiredParameterCount) {
        fail(arguments, 'Too few positional arguments');
        return NeverType.fromNullability(currentLibrary!.nonNullable);
      }
      if (arguments.positional.length >
          functionType.positionalParameters.length) {
        fail(arguments, 'Too many positional arguments');
        return NeverType.fromNullability(currentLibrary!.nonNullable);
      }
      List<DartType> typeArguments = arguments.types;
      if (typeArguments.length != functionType.typeParameters.length) {
        fail(arguments, 'Wrong number of type arguments');
        return NeverType.fromNullability(currentLibrary!.nonNullable);
      }

      functionType = FunctionTypeInstantiator.instantiate(
          receiver.substituteType(functionType) as FunctionType,
          arguments.types);

      for (int i = 0; i < functionType.typeParameters.length; ++i) {
        DartType argument = arguments.types[i];
        DartType bound = functionType.typeParameters[i].bound;
        checkAssignable(arguments, argument, bound);
      }

      // Arguments of all types are allowed for `==`.
      bool targetIsEquals = target is Procedure &&
          target.kind == ProcedureKind.Operator &&
          target.name == equalsName;
      if (!isErroneousTarget && !targetIsEquals) {
        for (int i = 0; i < arguments.positional.length; ++i) {
          DartType expectedType = functionType.positionalParameters[i];
          arguments.positional[i] = checkExpressionAndAssignability(
              arguments.positional[i], expectedType);
        }
        for (int i = 0; i < arguments.named.length; ++i) {
          NamedExpression argument = arguments.named[i];
          bool found = false;
          for (int j = 0; j < functionType.namedParameters.length; ++j) {
            if (argument.name == functionType.namedParameters[j].name) {
              DartType expectedType = functionType.namedParameters[j].type;
              argument.value =
                  checkExpressionAndAssignability(argument.value, expectedType);
              found = true;
              break;
            }
          }
          if (!found) {
            fail(
                argument.value, 'Unexpected named parameter: ${argument.name}');
            return NeverType.fromNullability(currentLibrary!.nonNullable);
          }
        }
      }
      return functionType.returnType;
    } else {
      // Note: attempting to resolve .call() on [functionType] could lead to an
      // infinite regress, so just assume `dynamic`.
      return const DynamicType();
    }
  }

  DartType? _getInternalReturnType(FunctionNode function) {
    switch (function.asyncMarker) {
      case AsyncMarker.Sync:
        return function.returnType;

      case AsyncMarker.Async:
        Class container = coreTypes.futureClass;
        DartType returnType = function.returnType;
        if (returnType is InterfaceType && returnType.classNode == container) {
          return returnType.typeArguments.single;
        }
        return const DynamicType();

      case AsyncMarker.SyncStar:
      case AsyncMarker.AsyncStar:
        return null;
    }
  }

  DartType? _getYieldType(FunctionNode function) {
    switch (function.asyncMarker) {
      case AsyncMarker.Sync:
      case AsyncMarker.Async:
        return null;

      case AsyncMarker.SyncStar:
      case AsyncMarker.AsyncStar:
        Class container = function.asyncMarker == AsyncMarker.SyncStar
            ? coreTypes.iterableClass
            : coreTypes.streamClass;
        DartType returnType = function.returnType;
        if (returnType is InterfaceType && returnType.classNode == container) {
          return returnType.typeArguments.single;
        }
        return const DynamicType();
    }
  }

  FunctionType _instantiateAndCheck(FunctionType methodType,
      List<DartType> methodTypeArguments, TreeNode where) {
    assert(methodType.typeParameters.length == methodTypeArguments.length);
    if (methodType.typeParameters.isEmpty) return methodType;

    FunctionTypeInstantiator instantiator =
        FunctionTypeInstantiator.fromInstantiation(
            methodType, methodTypeArguments);
    for (int i = 0; i < methodTypeArguments.length; ++i) {
      DartType argument = methodTypeArguments[i];
      DartType bound =
          instantiator.substitute(methodType.typeParameters[i].bound);
      checkAssignable(where, argument, bound);
    }
    return FunctionTypeInstantiator.instantiate(
        methodType, methodTypeArguments);
  }

  @override
  DartType visitAsExpression(AsExpression node) {
    visitExpression(node.operand);
    return node.type;
  }

  @override
  DartType visitAwaitExpression(AwaitExpression node) {
    return environment.flatten(visitExpression(node.operand));
  }

  @override
  DartType visitBoolLiteral(BoolLiteral node) {
    return environment.coreTypes.boolNonNullableRawType;
  }

  @override
  DartType visitConditionalExpression(ConditionalExpression node) {
    bool staticTypeIsNonNullable =
        node.staticType.nullability == Nullability.nonNullable;
    bool staticTypeIsNonNullableFunctionType =
        node.staticType is FunctionType && staticTypeIsNonNullable;
    bool conditionIsEqualsNull = node.condition is EqualsNull;
    Expression then = node.then;
    bool thenIsNull = then is NullLiteral ||
        then is ConstantExpression && then.type is NullType;
    Expression otherwise = node.otherwise;
    bool otherwiseIsCallTearoff =
        otherwise is InstanceTearOff && otherwise.name == callName;

    if (staticTypeIsNonNullableFunctionType &&
        conditionIsEqualsNull &&
        thenIsNull &&
        otherwiseIsCallTearoff) {
      // Case of implicit `call` tear-offs for type coercion.
      //
      // Currently, coercions of interface types to function types, that is,
      // tearing off the `call` method, is encoded as follows:
      //
      //     FT f = let #t = e in #t == null ?{FT} null : #t.call;
      //
      // The line above is the encoding for `FT f = e;`, where `e` is an
      // expression of a static type that is an interface type, `FT` is a
      // function type, such as `void Function(int)`, `#t` is a synthesized
      // intermediate variable, and `{FT}` following `?` indicates the static
      // type of the conditional expression.
      //
      // We skip the type check in the then-part of the conditional expression
      // in such an encoding, due to the unconventional use of the `null`.

      // TODO(cstefantsova): Implement a type-safe encoding instead.
    } else {
      node.then = checkExpressionAndAssignability(node.then, node.staticType);
    }

    node.condition = checkExpressionAndAssignability(
        node.condition, environment.coreTypes.boolNonNullableRawType);
    node.otherwise =
        checkExpressionAndAssignability(node.otherwise, node.staticType);
    return node.staticType;
  }

  @override
  DartType visitConstructorInvocation(ConstructorInvocation node) {
    Constructor target = node.target;
    Arguments arguments = node.arguments;
    Class class_ = target.enclosingClass;
    handleCall(
        arguments,
        target.function
            .computeThisFunctionType(class_.enclosingLibrary.nonNullable),
        target: target,
        isErroneousTarget: target.isErroneous);
    return new InterfaceType(
        target.enclosingClass, currentLibrary!.nonNullable, arguments.types);
  }

  @override
  DartType visitDoubleLiteral(DoubleLiteral node) {
    return environment.coreTypes.doubleNonNullableRawType;
  }

  @override
  DartType visitFunctionExpression(FunctionExpression node) {
    handleNestedFunctionNode(node.function);
    return node.function.computeThisFunctionType(currentLibrary!.nonNullable);
  }

  @override
  DartType visitIntLiteral(IntLiteral node) {
    return environment.coreTypes.intNonNullableRawType;
  }

  @override
  DartType visitInvalidExpression(InvalidExpression node) {
    // Don't type check `node.expression`.
    return const InvalidType();
  }

  @override
  DartType visitIsExpression(IsExpression node) {
    visitExpression(node.operand);
    return environment.coreTypes.boolNonNullableRawType;
  }

  @override
  DartType visitLet(Let node) {
    DartType value = visitExpression(node.variable.initializer!);
    checkAssignable(node, value, node.variable.type);
    return visitExpression(node.body);
  }

  @override
  DartType visitBlockExpression(BlockExpression node) {
    visitStatement(node.body);
    return visitExpression(node.value);
  }

  @override
  DartType visitInstantiation(Instantiation node) {
    DartType type = visitExpression(node.expression);
    if (type is InvalidType || type is NeverType) {
      return type;
    }
    if (type is! FunctionType) {
      fail(node, 'Not a function type: $type');
      return NeverType.fromNullability(currentLibrary!.nonNullable);
    }
    FunctionType functionType = type;
    if (functionType.typeParameters.length != node.typeArguments.length) {
      fail(node, 'Wrong number of type arguments');
      return NeverType.fromNullability(currentLibrary!.nonNullable);
    }
    return _instantiateAndCheck(functionType, node.typeArguments, node);
  }

  @override
  DartType visitConstructorTearOff(ConstructorTearOff node) {
    return node.function.computeFunctionType(Nullability.nonNullable);
  }

  @override
  DartType visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    return node.function.computeFunctionType(Nullability.nonNullable);
  }

  @override
  DartType visitTypedefTearOff(TypedefTearOff node) {
    DartType type = visitExpression(node.expression);
    if (type is InvalidType || type is NeverType) {
      return type;
    }
    if (type is! FunctionType) {
      fail(node, 'Not a function type: $type');
      return NeverType.fromNullability(currentLibrary!.nonNullable);
    }
    FunctionType functionType = type;
    if (functionType.typeParameters.length != node.typeArguments.length) {
      fail(node, 'Wrong number of type arguments');
      return NeverType.fromNullability(currentLibrary!.nonNullable);
    }
    FreshStructuralParameters freshTypeParameters =
        getFreshStructuralParameters(node.structuralParameters);
    FunctionType result = freshTypeParameters.substitute(
            _instantiateAndCheck(functionType, node.typeArguments, node))
        as FunctionType;
    return new FunctionType(result.positionalParameters, result.returnType,
        result.declaredNullability,
        namedParameters: result.namedParameters,
        typeParameters: freshTypeParameters.freshTypeParameters,
        requiredParameterCount: result.requiredParameterCount);
  }

  @override
  DartType visitListLiteral(ListLiteral node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      node.expressions[i] = checkExpressionAndAssignability(
          node.expressions[i], node.typeArgument);
    }
    return environment.listType(node.typeArgument, currentLibrary!.nonNullable);
  }

  @override
  DartType visitSetLiteral(SetLiteral node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      node.expressions[i] = checkExpressionAndAssignability(
          node.expressions[i], node.typeArgument);
    }
    return environment.setType(node.typeArgument, currentLibrary!.nonNullable);
  }

  @override
  DartType visitRecordLiteral(RecordLiteral node) {
    for (int i = 0; i < node.positional.length; ++i) {
      node.positional[i] = checkExpressionAndAssignability(
          node.positional[i], node.recordType.positional[i]);
    }
    for (int i = 0; i < node.named.length; ++i) {
      DartType? namedFieldType;
      for (NamedType namedType in node.recordType.named) {
        if (namedType.name == node.named[i].name) {
          namedFieldType = namedType.type;
        }
      }
      node.named[i].value =
          checkExpressionAndAssignability(node.named[i].value, namedFieldType!);
    }
    return new RecordType(node.recordType.positional, node.recordType.named,
        currentLibrary!.nonNullable);
  }

  @override
  DartType visitLogicalExpression(LogicalExpression node) {
    node.left = checkExpressionAndAssignability(
        node.left, environment.coreTypes.boolNonNullableRawType);
    node.right = checkExpressionAndAssignability(
        node.right, environment.coreTypes.boolNonNullableRawType);
    return environment.coreTypes.boolNonNullableRawType;
  }

  @override
  DartType visitMapLiteral(MapLiteral node) {
    for (MapLiteralEntry entry in node.entries) {
      Expression key = entry.key;
      Expression value = entry.value;

      bool keyIsNull = key is NullLiteral ||
          key is ConstantExpression && key.type is NullType;
      bool keyIsInvalid = key is InvalidExpression;
      bool valueIsNull = value is NullLiteral ||
          value is ConstantExpression && value.type is NullType;
      bool valueIsInvalid = value is InvalidExpression;
      if (keyIsNull && valueIsInvalid || keyIsInvalid && valueIsNull) {
        // Erroneous map entries are encoded as follows:
        //
        //     {null: invalid-expression "..."}
        //
        //     or
        //
        //     {invalid-expression "...": null}
        //
        // We're skipping type checks in those kinds of entries.
        continue;
      }

      entry.key = checkExpressionAndAssignability(key, node.keyType);
      entry.value = checkExpressionAndAssignability(value, node.valueType);
    }
    return environment.mapType(
        node.keyType, node.valueType, currentLibrary!.nonNullable);
  }

  @override
  DartType visitNot(Not node) {
    visitExpression(node.operand);
    return environment.coreTypes.boolNonNullableRawType;
  }

  @override
  DartType visitNullCheck(NullCheck node) {
    return computeNonNull(visitExpression(node.operand));
  }

  @override
  DartType visitNullLiteral(NullLiteral node) {
    return const NullType();
  }

  @override
  DartType visitRethrow(Rethrow node) {
    return NeverType.fromNullability(currentLibrary!.nonNullable);
  }

  @override
  DartType visitStaticGet(StaticGet node) {
    return node.target.getterType;
  }

  @override
  DartType visitStaticInvocation(StaticInvocation node) {
    return handleCall(node.arguments, node.target.getterType,
        target: node.target);
  }

  @override
  DartType visitStaticSet(StaticSet node) {
    DartType value = visitExpression(node.value);
    checkAssignable(node.value, value, node.target.setterType);
    return value;
  }

  @override
  DartType visitStringConcatenation(StringConcatenation node) {
    node.expressions.forEach(visitExpression);
    return environment.coreTypes.stringNonNullableRawType;
  }

  @override
  DartType visitListConcatenation(ListConcatenation node) {
    DartType type = environment.iterableType(
        node.typeArgument, currentLibrary!.nonNullable);
    for (Expression part in node.lists) {
      DartType partType = visitExpression(part);
      checkAssignable(node, type, partType);
    }
    return type;
  }

  @override
  DartType visitSetConcatenation(SetConcatenation node) {
    DartType type = environment.iterableType(
        node.typeArgument, currentLibrary!.nonNullable);
    for (Expression part in node.sets) {
      DartType partType = visitExpression(part);
      checkAssignable(node, type, partType);
    }
    return type;
  }

  @override
  DartType visitMapConcatenation(MapConcatenation node) {
    DartType type = environment.mapType(
        node.keyType, node.valueType, currentLibrary!.nonNullable);
    for (Expression part in node.maps) {
      DartType partType = visitExpression(part);
      checkAssignable(node, type, partType);
    }
    return type;
  }

  @override
  DartType visitInstanceCreation(InstanceCreation node) {
    Substitution substitution = Substitution.fromPairs(
        node.classNode.typeParameters, node.typeArguments);
    node.fieldValues.forEach((Reference fieldRef, Expression value) {
      DartType fieldType = substitution.substituteType(fieldRef.asField.type);
      DartType valueType = visitExpression(value);
      checkAssignable(node, fieldType, valueType);
    });
    return new InterfaceType(
        node.classNode, currentLibrary!.nonNullable, node.typeArguments);
  }

  @override
  DartType visitFileUriExpression(FileUriExpression node) {
    return visitExpression(node.expression);
  }

  @override
  DartType visitStringLiteral(StringLiteral node) {
    return environment.coreTypes.stringNonNullableRawType;
  }

  @override
  DartType visitAbstractSuperMethodInvocation(
      AbstractSuperMethodInvocation node) {
    Member target = node.interfaceTarget;
    return handleCall(node.arguments, target.superGetterType,
        receiver: getSuperReceiverType(target), target: target);
  }

  @override
  DartType visitSuperMethodInvocation(SuperMethodInvocation node) {
    Member target = node.interfaceTarget;
    return handleCall(node.arguments, target.superGetterType,
        receiver: getSuperReceiverType(target), target: target);
  }

  @override
  DartType visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) {
    Member target = node.interfaceTarget;
    Substitution receiver = getSuperReceiverType(target);
    return receiver.substituteType(target.superGetterType);
  }

  @override
  DartType visitAbstractSuperPropertySet(AbstractSuperPropertySet node) {
    Member target = node.interfaceTarget;
    DartType value = visitExpression(node.value);
    Substitution receiver = getSuperReceiverType(target);
    checkAssignable(node.value, value,
        receiver.substituteType(target.superSetterType, contravariant: true));
    return value;
  }

  @override
  DartType visitSuperPropertyGet(SuperPropertyGet node) {
    Member target = node.interfaceTarget;
    Substitution receiver = getSuperReceiverType(target);
    return receiver.substituteType(target.superGetterType);
  }

  @override
  DartType visitSuperPropertySet(SuperPropertySet node) {
    Member target = node.interfaceTarget;
    DartType value = visitExpression(node.value);
    Substitution receiver = getSuperReceiverType(target);
    checkAssignable(node.value, value,
        receiver.substituteType(target.superSetterType, contravariant: true));
    return value;
  }

  @override
  DartType visitSymbolLiteral(SymbolLiteral node) {
    return environment.coreTypes.symbolNonNullableRawType;
  }

  @override
  DartType visitThisExpression(ThisExpression node) {
    return currentThisType!;
  }

  @override
  DartType visitThrow(Throw node) {
    visitExpression(node.expression);
    return NeverType.fromNullability(currentLibrary!.nonNullable);
  }

  @override
  DartType visitTypeLiteral(TypeLiteral node) {
    return environment.coreTypes.typeNonNullableRawType;
  }

  @override
  DartType visitVariableGet(VariableGet node) {
    return node.promotedType ?? node.variable.type;
  }

  @override
  DartType visitVariableSet(VariableSet node) {
    DartType value = visitExpression(node.value);
    checkAssignable(node.value, value, node.variable.type);
    return value;
  }

  @override
  DartType visitRecordIndexGet(RecordIndexGet node) {
    visitExpression(node.receiver);
    RecordType recordType = node.receiverType;
    assert(
        node.index < recordType.positional.length,
        "Encountered RecordIndexGet with index out of range: "
        "'${node.index}'.");
    return recordType.positional[node.index];
  }

  @override
  DartType visitRecordNameGet(RecordNameGet node) {
    visitExpression(node.receiver);
    DartType? result;
    for (NamedType namedType in node.receiverType.named) {
      if (namedType.name == node.name) {
        result = namedType.type;
      }
    }
    assert(
        result != null,
        "Encountered RecordNameGet with nonexistent name key: "
        "'${node.name}'.");
    return result!;
  }

  @override
  DartType visitLoadLibrary(LoadLibrary node) {
    return environment.futureType(
        const DynamicType(), currentLibrary!.nonNullable);
  }

  @override
  DartType visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return environment.coreTypes.objectNullableRawType;
  }

  @override
  DartType visitConstantExpression(ConstantExpression node) {
    return node.type;
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    visitExpression(node.condition);
    if (node.message != null) {
      visitExpression(node.message!);
    }
  }

  @override
  void visitBlock(Block node) {
    node.statements.forEach(visitStatement);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    node.statements.forEach(visitStatement);
  }

  @override
  void visitBreakStatement(BreakStatement node) {}

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {}

  @override
  void visitDoStatement(DoStatement node) {
    visitStatement(node.body);
    node.condition = checkExpressionAndAssignability(
        node.condition, environment.coreTypes.boolNonNullableRawType);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {}

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    DartType iterable = visitExpression(node.iterable);
    // TODO(asgerf): Store interface targets on for-in loops or desugar them,
    // instead of doing the ad-hoc resolution here.
    if (node.isAsync) {
      checkAssignable(
          node, getStreamElementType(iterable), node.expressionVariable.type);
    } else {
      checkAssignable(
          node, getIterableElementType(iterable), node.expressionVariable.type);
    }
    visitStatement(node.body);
  }

  static final Name iteratorName = new Name('iterator');
  static final Name currentName = new Name('current');

  DartType getIterableElementType(DartType iterable) {
    if (iterable is InterfaceType) {
      Member? iteratorGetter =
          hierarchy.getInterfaceMember(iterable.classNode, iteratorName);
      if (iteratorGetter == null) return const DynamicType();
      List<DartType> castedIterableArguments =
          hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
              iterable, iteratorGetter.enclosingClass!)!;
      DartType iteratorType = Substitution.fromPairs(
              iteratorGetter.enclosingClass!.typeParameters,
              castedIterableArguments)
          .substituteType(iteratorGetter.getterType);
      if (iteratorType is InterfaceType) {
        Member? currentGetter =
            hierarchy.getInterfaceMember(iteratorType.classNode, currentName);
        if (currentGetter == null) return const DynamicType();
        List<DartType> castedIteratorTypeArguments =
            hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
                iteratorType, currentGetter.enclosingClass!)!;
        return Substitution.fromPairs(
                currentGetter.enclosingClass!.typeParameters,
                castedIteratorTypeArguments)
            .substituteType(currentGetter.getterType);
      }
    }
    return const DynamicType();
  }

  DartType getStreamElementType(DartType stream) {
    if (stream is TypeDeclarationType) {
      List<DartType>? asStreamArguments =
          hierarchy.getTypeArgumentsAsInstanceOf(stream, coreTypes.streamClass);
      if (asStreamArguments == null) return const DynamicType();
      return asStreamArguments.single;
    }
    return const DynamicType();
  }

  @override
  void visitForStatement(ForStatement node) {
    node.variableInitializations.forEach(visitVariableInitialization);
    if (node.condition != null) {
      node.condition = checkExpressionAndAssignability(
          node.condition!, environment.coreTypes.boolNonNullableRawType);
    }
    node.updates.forEach(visitExpression);
    visitStatement(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    handleNestedFunctionNode(node.function);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.condition = checkExpressionAndAssignability(
        node.condition, environment.coreTypes.boolNonNullableRawType);
    visitStatement(node.then);
    if (node.otherwise != null) {
      visitStatement(node.otherwise!);
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    Expression? expression = node.expression;
    if (expression != null) {
      if (currentReturnType == null) {
        fail(node, 'Return of a value from void method');
      } else {
        DartType type = visitExpression(expression);
        if (currentAsyncMarker == AsyncMarker.Async) {
          type = environment.flatten(type);
        }
        checkAssignable(expression, type, currentReturnType!);
      }
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    visitExpression(node.expression);
    for (SwitchCase switchCase in node.cases) {
      switchCase.expressions.forEach(visitExpression);
      visitStatement(switchCase.body);
    }
  }

  @override
  void visitTryCatch(TryCatch node) {
    visitStatement(node.body);
    for (Catch catchClause in node.catches) {
      visitStatement(catchClause.body);
    }
  }

  @override
  void visitTryFinally(TryFinally node) {
    visitStatement(node.body);
    visitStatement(node.finalizer);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    visitVariableInitialization(node);
  }

  @override
  void visitVariableInitialization(VariableInitialization node) {
    if (node.initializer != null) {
      node.initializer =
          checkExpressionAndAssignability(node.initializer!, node.type);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition = checkExpressionAndAssignability(
        node.condition, environment.coreTypes.boolNonNullableRawType);
    visitStatement(node.body);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    if (node.isYieldStar) {
      Class container = currentAsyncMarker == AsyncMarker.AsyncStar
          ? coreTypes.streamClass
          : coreTypes.iterableClass;
      DartType type = visitExpression(node.expression);
      List<DartType>? asContainerArguments = type is TypeDeclarationType
          ? hierarchy.getTypeArgumentsAsInstanceOf(type, container)
          : null;
      if (asContainerArguments != null) {
        checkAssignable(
            node.expression, asContainerArguments[0], currentYieldType!);
      } else if (type is! InvalidType && type is! NeverType) {
        fail(node.expression, '$type is not an instance of $container');
      }
    } else {
      node.expression =
          checkExpressionAndAssignability(node.expression, currentYieldType!);
    }
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    node.value = checkExpressionAndAssignability(node.value, node.field.type);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    handleCall(node.arguments, node.target.getterType, target: node.target);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    handleCall(node.arguments, node.target.getterType,
        receiver: getSuperReceiverType(node.target), target: node.target);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    visitVariableDeclaration(node.variable);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    visitAssertStatement(node.statement);
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {}

  @override
  DartType visitDynamicGet(DynamicGet node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    switch (node.kind) {
      case DynamicAccessKind.Dynamic:
        return const DynamicType();
      case DynamicAccessKind.Never:
        return new NeverType.internal(currentLibrary!.nonNullable);
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        return const InvalidType();
    }
  }

  @override
  DartType visitDynamicInvocation(DynamicInvocation node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    node.arguments.positional.forEach(visitExpression);
    node.arguments.named
        .forEach((NamedExpression n) => visitExpression(n.value));
    switch (node.kind) {
      case DynamicAccessKind.Dynamic:
        return const DynamicType();
      case DynamicAccessKind.Never:
        return new NeverType.internal(currentLibrary!.nonNullable);
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        return const InvalidType();
    }
  }

  @override
  DartType visitDynamicSet(DynamicSet node) {
    DartType value = visitExpression(node.value);
    final DartType receiver = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiver, node);
    return value;
  }

  @override
  DartType visitEqualsCall(EqualsCall node) {
    visitExpression(node.left);
    visitExpression(node.right);
    // TODO(johnniwinther): Return Never as type for equals call on Never.
    return environment.coreTypes.boolNonNullableRawType;
  }

  @override
  DartType visitEqualsNull(EqualsNull node) {
    visitExpression(node.expression);
    return environment.coreTypes.boolNonNullableRawType;
  }

  @override
  DartType visitFunctionInvocation(FunctionInvocation node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    node.arguments.positional.forEach(visitExpression);
    node.arguments.named
        .forEach((NamedExpression n) => visitExpression(n.value));
    return node.functionType?.returnType ?? const DynamicType();
  }

  @override
  DartType visitInstanceGet(InstanceGet node) {
    Substitution receiver =
        getReceiverType(node, node.receiver, node.interfaceTarget);
    return receiver.substituteType(node.interfaceTarget.getterType);
  }

  @override
  DartType visitInstanceInvocation(InstanceInvocation node) {
    // TODO(johnniwinther): Use embedded static type.
    Member target = node.interfaceTarget;
    if (target is Procedure &&
        environment.isSpecialCasedBinaryOperator(target)) {
      assert(node.arguments.positional.length == 1);
      DartType receiver = visitExpression(node.receiver);
      DartType argument = visitExpression(node.arguments.positional[0]);
      return environment.getTypeOfSpecialCasedBinaryOperator(
          receiver, argument);
    } else {
      // Erroneous map literals with spreads are encoded as follows:
      //
      //     {InvalidExpression(...), null}
      //
      // That happens regardless of the type arguments of the map. Here we skip
      // such lowerings of erroneous map literals.
      bool isMapIndexSet =
          node.interfaceTarget.enclosingClass == coreTypes.mapClass &&
              node.interfaceTarget.kind == ProcedureKind.Operator &&
              node.interfaceTarget.name == indexSetName;
      if (node.arguments.positional case [InvalidExpression(), NullLiteral()]
          when isMapIndexSet) {
        return const InvalidType();
      } else {
        visitExpression(node.receiver);
        return handleCall(node.arguments, target.getterType,
            receiver:
                getReceiverType(node, node.receiver, node.interfaceTarget),
            target: node.interfaceTarget);
      }
    }
  }

  @override
  DartType visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    // TODO(johnniwinther): Use embedded static type.
    Member target = node.interfaceTarget;
    assert(
        !(target is Procedure &&
            environment.isSpecialCasedBinaryOperator(target)),
        "Unexpected instance getter invocation target: $target");
    visitExpression(node.receiver);
    return handleCall(node.arguments, target.getterType,
        receiver: getReceiverType(node, node.receiver, node.interfaceTarget),
        target: node.interfaceTarget);
  }

  @override
  DartType visitInstanceSet(InstanceSet node) {
    DartType value = visitExpression(node.value);
    Substitution receiver =
        getReceiverType(node, node.receiver, node.interfaceTarget);
    checkAssignable(
        node.value,
        value,
        receiver.substituteType(node.interfaceTarget.setterType,
            contravariant: true));
    return value;
  }

  @override
  DartType visitInstanceTearOff(InstanceTearOff node) {
    Substitution receiver =
        getReceiverType(node, node.receiver, node.interfaceTarget);
    return receiver.substituteType(node.interfaceTarget.getterType);
  }

  @override
  DartType visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    checkUnresolvedInvocation(node.functionType, node);
    node.arguments.positional.forEach(visitExpression);
    node.arguments.named
        .forEach((NamedExpression n) => visitExpression(n.value));
    return node.functionType.returnType;
  }

  @override
  DartType visitStaticTearOff(StaticTearOff node) {
    return node.target.getterType;
  }

  @override
  DartType visitFunctionTearOff(FunctionTearOff node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    // TODO(johnniwinther): Return the correct result type.
    return const DynamicType();
  }

  @override
  void visitPatternSwitchStatement(PatternSwitchStatement node) {
    // TODO(johnniwinther): Implement this.
  }

  @override
  DartType visitSwitchExpression(SwitchExpression node) {
    // TODO(johnniwinther): Implement this.
    return node.staticType!;
  }

  @override
  void visitIfCaseStatement(IfCaseStatement node) {
    // TODO(johnniwinther): Implement this.
  }

  @override
  DartType visitPatternAssignment(PatternAssignment node) {
    // TODO(johnniwinther): Implement this.
    return visitExpression(node.expression);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    // TODO(johnniwinther): Implement this.
  }

  @override
  DartType visitVariableRead(VariableRead node) {
    // TODO(cstefantsova): Implement visitVariableRead.
    throw new UnimplementedError(
        "Unimplemented support for $node (${node.runtimeType}).");
  }

  @override
  DartType visitVariableWrite(VariableWrite node) {
    // TODO(cstefantsova): Implement visitVariableWrite.
    throw new UnimplementedError(
        "Unimplemented support for $node (${node.runtimeType}).");
  }

  @override
  DartType visitRedirectingFactoryInvocation(
      RedirectingFactoryInvocation node) {
    return node.expression.accept(this);
  }
}
