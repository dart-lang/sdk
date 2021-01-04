// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_checker;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'type_algebra.dart';
import 'type_environment.dart';

/// Performs type checking on the kernel IR.
///
/// A concrete subclass of [TypeChecker] must implement [checkAssignable] and
/// [fail] in order to deal with subtyping requirements and error handling.
abstract class TypeChecker {
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final bool ignoreSdk;
  TypeEnvironment environment;
  Library currentLibrary;
  InterfaceType currentThisType;

  TypeChecker(this.coreTypes, this.hierarchy, {this.ignoreSdk: true})
      : environment = new TypeEnvironment(coreTypes, hierarchy);

  void checkComponent(Component component) {
    for (Library library in component.libraries) {
      if (ignoreSdk && library.importUri.scheme == 'dart') continue;
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
      if (ignoreSdk && library.importUri.scheme == 'dart') continue;
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
        hierarchy.getClassAsInstanceOf(host, member.enclosingClass);
    Substitution substitution = Substitution.fromSupertype(hostType);
    return substitution.substituteType(member.getterType);
  }

  DartType setterType(Class host, Member member) {
    Supertype hostType =
        hierarchy.getClassAsInstanceOf(host, member.enclosingClass);
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

  /// Checks that [expression], which has type [from], can be assigned to [to].
  ///
  /// Should return a downcast if necessary, or [expression] if no cast is
  /// needed.
  Expression checkAndDowncastExpression(
      Expression expression, DartType from, DartType to) {
    checkAssignable(expression, from, to);
    return expression;
  }

  /// Check unresolved invocation (one that has no interfaceTarget)
  /// and report an error if necessary.
  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    // By default we ignore unresolved method invocations.
  }

  /// Indicates that type checking failed.
  void fail(TreeNode where, String message);
}

class TypeCheckingVisitor
    implements
        ExpressionVisitor<DartType>,
        StatementVisitor<Null>,
        MemberVisitor<Null>,
        InitializerVisitor<Null> {
  final TypeChecker checker;
  final TypeEnvironment environment;
  final ClassHierarchy hierarchy;

  CoreTypes get coreTypes => environment.coreTypes;
  Library get currentLibrary => checker.currentLibrary;
  Class get currentClass => checker.currentThisType.classNode;
  InterfaceType get currentThisType => checker.currentThisType;

  DartType currentReturnType;
  DartType currentYieldType;
  AsyncMarker currentAsyncMarker = AsyncMarker.Sync;

  TypeCheckingVisitor(this.checker, this.environment, this.hierarchy);

  void checkAssignable(TreeNode where, DartType from, DartType to) {
    checker.checkAssignable(where, from, to);
  }

  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    checker.checkUnresolvedInvocation(receiver, where);
  }

  Expression checkAndDowncastExpression(Expression from, DartType to) {
    TreeNode parent = from.parent;
    DartType type = visitExpression(from);
    Expression result = checker.checkAndDowncastExpression(from, type, to);
    result.parent = parent;
    return result;
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

  defaultMember(Member node) => throw 'Unused';

  DartType defaultBasicLiteral(BasicLiteral node) {
    return defaultExpression(node);
  }

  DartType defaultExpression(Expression node) {
    throw 'Unexpected expression ${node.runtimeType}';
  }

  defaultStatement(Statement node) {
    throw 'Unexpected statement ${node.runtimeType}';
  }

  defaultInitializer(Initializer node) {
    throw 'Unexpected initializer ${node.runtimeType}';
  }

  visitField(Field node) {
    if (node.initializer != null) {
      node.initializer =
          checkAndDowncastExpression(node.initializer, node.type);
    }
  }

  visitConstructor(Constructor node) {
    currentReturnType = null;
    currentYieldType = null;
    node.initializers.forEach(visitInitializer);
    handleFunctionNode(node.function);
  }

  visitProcedure(Procedure node) {
    currentReturnType = _getInternalReturnType(node.function);
    currentYieldType = _getYieldType(node.function);
    handleFunctionNode(node.function);
  }

  visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    currentReturnType = null;
    currentYieldType = null;
  }

  void handleFunctionNode(FunctionNode node) {
    AsyncMarker oldAsyncMarker = currentAsyncMarker;
    currentAsyncMarker = node.asyncMarker;
    node.positionalParameters
        .skip(node.requiredParameterCount)
        .forEach(handleOptionalParameter);
    node.namedParameters.forEach(handleOptionalParameter);
    if (node.body != null) {
      visitStatement(node.body);
    }
    currentAsyncMarker = oldAsyncMarker;
  }

  void handleNestedFunctionNode(FunctionNode node) {
    DartType oldReturn = currentReturnType;
    DartType oldYield = currentYieldType;
    currentReturnType = _getInternalReturnType(node);
    currentYieldType = _getYieldType(node);
    handleFunctionNode(node);
    currentReturnType = oldReturn;
    currentYieldType = oldYield;
  }

  void handleOptionalParameter(VariableDeclaration parameter) {
    if (parameter.initializer != null) {
      // Default parameter values cannot be downcast.
      checkExpressionNoDowncast(parameter.initializer, parameter.type);
    }
  }

  Substitution getReceiverType(
      TreeNode access, Expression receiver, Member member) {
    DartType type = visitExpression(receiver);
    Class superclass = member.enclosingClass;
    if (superclass.supertype == null) {
      return Substitution.empty; // Members on Object are always accessible.
    }
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).bound;
    }
    if (type is BottomType || type is NeverType || type is NullType) {
      // The bottom type is a subtype of all types, so it should be allowed.
      return Substitution.bottomForClass(superclass);
    }
    if (type is InterfaceType) {
      // The receiver type should implement the interface declaring the member.
      List<DartType> upcastTypeArguments =
          hierarchy.getTypeArgumentsAsInstanceOf(type, superclass);
      if (upcastTypeArguments != null) {
        return Substitution.fromPairs(
            superclass.typeParameters, upcastTypeArguments);
      }
    }
    if (type is FunctionType && superclass == coreTypes.functionClass) {
      assert(type.typeParameters.isEmpty);
      return Substitution.empty;
    }
    // Note that we do not allow 'dynamic' here.  Dynamic calls should not
    // have a declared interface target.
    fail(access, '$member is not accessible on a receiver of type $type');
    return Substitution.bottomForClass(superclass); // Continue type checking.
  }

  Substitution getSuperReceiverType(Member member) {
    return Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(currentClass, member.enclosingClass));
  }

  DartType handleCall(Arguments arguments, DartType functionType,
      {Substitution receiver: Substitution.empty,
      List<TypeParameter> typeParameters}) {
    if (functionType is FunctionType) {
      typeParameters ??= functionType.typeParameters;
      if (arguments.positional.length < functionType.requiredParameterCount) {
        fail(arguments, 'Too few positional arguments');
        return const BottomType();
      }
      if (arguments.positional.length >
          functionType.positionalParameters.length) {
        fail(arguments, 'Too many positional arguments');
        return const BottomType();
      }
      List<DartType> typeArguments = arguments.types;
      if (typeArguments.length != typeParameters.length) {
        fail(arguments, 'Wrong number of type arguments');
        return const BottomType();
      }
      Substitution substitution = _instantiateFunction(
          typeParameters, typeArguments, arguments,
          receiverSubstitution: receiver);
      for (int i = 0; i < arguments.positional.length; ++i) {
        DartType expectedType = substitution.substituteType(
            functionType.positionalParameters[i],
            contravariant: true);
        arguments.positional[i] =
            checkAndDowncastExpression(arguments.positional[i], expectedType);
      }
      for (int i = 0; i < arguments.named.length; ++i) {
        NamedExpression argument = arguments.named[i];
        bool found = false;
        for (int j = 0; j < functionType.namedParameters.length; ++j) {
          if (argument.name == functionType.namedParameters[j].name) {
            DartType expectedType = substitution.substituteType(
                functionType.namedParameters[j].type,
                contravariant: true);
            argument.value =
                checkAndDowncastExpression(argument.value, expectedType);
            found = true;
            break;
          }
        }
        if (!found) {
          fail(argument.value, 'Unexpected named parameter: ${argument.name}');
          return const BottomType();
        }
      }
      return substitution.substituteType(functionType.returnType);
    } else {
      // Note: attempting to resolve .call() on [functionType] could lead to an
      // infinite regress, so just assume `dynamic`.
      return const DynamicType();
    }
  }

  DartType _getInternalReturnType(FunctionNode function) {
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

      case AsyncMarker.SyncYielding:
        // The SyncStar transform wraps the original function body twice,
        // where the inner most function returns bool.
        TreeNode parent = function.parent;
        while (parent is! FunctionNode) {
          parent = parent.parent;
        }
        FunctionNode enclosingFunction = parent as FunctionNode;
        if (enclosingFunction.dartAsyncMarker == AsyncMarker.Sync) {
          parent = enclosingFunction.parent;
          while (parent is! FunctionNode) {
            parent = parent.parent;
          }
          enclosingFunction = parent as FunctionNode;
          if (enclosingFunction.dartAsyncMarker == AsyncMarker.SyncStar) {
            return coreTypes.boolLegacyRawType;
          }
        }
        return null;

      default:
        throw 'Unexpected async marker: ${function.asyncMarker}';
    }
  }

  DartType _getYieldType(FunctionNode function) {
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

      case AsyncMarker.SyncYielding:
        return function.returnType;

      default:
        throw 'Unexpected async marker: ${function.asyncMarker}';
    }
  }

  Substitution _instantiateFunction(List<TypeParameter> typeParameters,
      List<DartType> typeArguments, TreeNode where,
      {Substitution receiverSubstitution}) {
    Substitution instantiation =
        Substitution.fromPairs(typeParameters, typeArguments);
    Substitution substitution = receiverSubstitution == null
        ? instantiation
        : Substitution.combine(receiverSubstitution, instantiation);
    for (int i = 0; i < typeParameters.length; ++i) {
      DartType argument = typeArguments[i];
      DartType bound = substitution.substituteType(typeParameters[i].bound);
      checkAssignable(where, argument, bound);
    }
    return substitution;
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
    return environment.coreTypes.boolLegacyRawType;
  }

  @override
  DartType visitConditionalExpression(ConditionalExpression node) {
    node.condition = checkAndDowncastExpression(
        node.condition, environment.coreTypes.boolLegacyRawType);
    node.then = checkAndDowncastExpression(node.then, node.staticType);
    node.otherwise =
        checkAndDowncastExpression(node.otherwise, node.staticType);
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
        typeParameters: class_.typeParameters);
    return new InterfaceType(
        target.enclosingClass, currentLibrary.nonNullable, arguments.types);
  }

  @override
  DartType visitDoubleLiteral(DoubleLiteral node) {
    return environment.coreTypes.doubleLegacyRawType;
  }

  @override
  DartType visitFunctionExpression(FunctionExpression node) {
    handleNestedFunctionNode(node.function);
    return node.function.computeThisFunctionType(currentLibrary.nonNullable);
  }

  @override
  DartType visitIntLiteral(IntLiteral node) {
    return environment.coreTypes.intLegacyRawType;
  }

  @override
  DartType visitInvalidExpression(InvalidExpression node) {
    return const DynamicType();
  }

  @override
  DartType visitIsExpression(IsExpression node) {
    visitExpression(node.operand);
    return environment.coreTypes.boolLegacyRawType;
  }

  @override
  DartType visitLet(Let node) {
    DartType value = visitExpression(node.variable.initializer);
    if (node.variable.type is DynamicType) {
      node.variable.type = value;
    }
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
    if (type is! FunctionType) {
      fail(node, 'Not a function type: $type');
      return const BottomType();
    }
    FunctionType functionType = type;
    if (functionType.typeParameters.length != node.typeArguments.length) {
      fail(node, 'Wrong number of type arguments');
      return const BottomType();
    }
    return _instantiateFunction(
            functionType.typeParameters, node.typeArguments, node)
        .substituteType(functionType.withoutTypeParameters);
  }

  @override
  DartType visitListLiteral(ListLiteral node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      node.expressions[i] =
          checkAndDowncastExpression(node.expressions[i], node.typeArgument);
    }
    return environment.listType(node.typeArgument, currentLibrary.nonNullable);
  }

  @override
  DartType visitSetLiteral(SetLiteral node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      node.expressions[i] =
          checkAndDowncastExpression(node.expressions[i], node.typeArgument);
    }
    return environment.setType(node.typeArgument, currentLibrary.nonNullable);
  }

  @override
  DartType visitLogicalExpression(LogicalExpression node) {
    node.left = checkAndDowncastExpression(
        node.left, environment.coreTypes.boolLegacyRawType);
    node.right = checkAndDowncastExpression(
        node.right, environment.coreTypes.boolLegacyRawType);
    return environment.coreTypes.boolLegacyRawType;
  }

  @override
  DartType visitMapLiteral(MapLiteral node) {
    for (MapEntry entry in node.entries) {
      entry.key = checkAndDowncastExpression(entry.key, node.keyType);
      entry.value = checkAndDowncastExpression(entry.value, node.valueType);
    }
    return environment.mapType(
        node.keyType, node.valueType, currentLibrary.nonNullable);
  }

  DartType handleDynamicCall(DartType receiver, Arguments arguments) {
    arguments.positional.forEach(visitExpression);
    arguments.named.forEach((NamedExpression n) => visitExpression(n.value));
    return const DynamicType();
  }

  DartType handleFunctionCall(
      TreeNode access, FunctionType function, Arguments arguments) {
    if (function.requiredParameterCount > arguments.positional.length) {
      fail(access, 'Too few positional arguments');
      return const BottomType();
    }
    if (function.positionalParameters.length < arguments.positional.length) {
      fail(access, 'Too many positional arguments');
      return const BottomType();
    }
    if (function.typeParameters.length != arguments.types.length) {
      fail(access, 'Wrong number of type arguments');
      return const BottomType();
    }
    Substitution instantiation =
        Substitution.fromPairs(function.typeParameters, arguments.types);
    for (int i = 0; i < arguments.positional.length; ++i) {
      DartType expectedType = instantiation.substituteType(
          function.positionalParameters[i],
          contravariant: true);
      arguments.positional[i] =
          checkAndDowncastExpression(arguments.positional[i], expectedType);
    }
    for (int i = 0; i < arguments.named.length; ++i) {
      NamedExpression argument = arguments.named[i];
      DartType parameterType = function.getNamedParameter(argument.name);
      if (parameterType != null) {
        DartType expectedType =
            instantiation.substituteType(parameterType, contravariant: true);
        argument.value =
            checkAndDowncastExpression(argument.value, expectedType);
      } else {
        fail(argument.value, 'Unexpected named parameter: ${argument.name}');
        return const BottomType();
      }
    }
    return instantiation.substituteType(function.returnType);
  }

  @override
  DartType visitMethodInvocation(MethodInvocation node) {
    Member target = node.interfaceTarget;
    if (target == null) {
      DartType receiver = visitExpression(node.receiver);
      if (node.name.text == '==') {
        visitExpression(node.arguments.positional.single);
        return environment.coreTypes.boolLegacyRawType;
      }
      if (node.name.text == 'call' && receiver is FunctionType) {
        return handleFunctionCall(node, receiver, node.arguments);
      }
      checkUnresolvedInvocation(receiver, node);
      return handleDynamicCall(receiver, node.arguments);
    } else if (target is Procedure &&
        environment.isSpecialCasedBinaryOperator(target)) {
      assert(node.arguments.positional.length == 1);
      DartType receiver = visitExpression(node.receiver);
      DartType argument = visitExpression(node.arguments.positional[0]);
      return environment.getTypeOfSpecialCasedBinaryOperator(
          receiver, argument);
    } else {
      return handleCall(node.arguments, target.getterType,
          receiver: getReceiverType(node, node.receiver, node.interfaceTarget));
    }
  }

  @override
  DartType visitPropertyGet(PropertyGet node) {
    if (node.interfaceTarget == null) {
      final DartType receiver = visitExpression(node.receiver);
      checkUnresolvedInvocation(receiver, node);
      return const DynamicType();
    } else {
      Substitution receiver =
          getReceiverType(node, node.receiver, node.interfaceTarget);
      return receiver.substituteType(node.interfaceTarget.getterType);
    }
  }

  @override
  DartType visitPropertySet(PropertySet node) {
    DartType value = visitExpression(node.value);
    if (node.interfaceTarget != null) {
      Substitution receiver =
          getReceiverType(node, node.receiver, node.interfaceTarget);
      checkAssignable(
          node.value,
          value,
          receiver.substituteType(node.interfaceTarget.setterType,
              contravariant: true));
    } else {
      final DartType receiver = visitExpression(node.receiver);
      checkUnresolvedInvocation(receiver, node);
    }
    return value;
  }

  @override
  DartType visitNot(Not node) {
    visitExpression(node.operand);
    return environment.coreTypes.boolLegacyRawType;
  }

  @override
  DartType visitNullCheck(NullCheck node) {
    // TODO(johnniwinther): Return `NonNull(visitExpression(types))`.
    return visitExpression(node.operand);
  }

  @override
  DartType visitNullLiteral(NullLiteral node) {
    return const BottomType();
  }

  @override
  DartType visitRethrow(Rethrow node) {
    return const BottomType();
  }

  @override
  DartType visitStaticGet(StaticGet node) {
    return node.target.getterType;
  }

  @override
  DartType visitStaticInvocation(StaticInvocation node) {
    return handleCall(node.arguments, node.target.getterType);
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
    return environment.coreTypes.stringLegacyRawType;
  }

  @override
  DartType visitListConcatenation(ListConcatenation node) {
    DartType type =
        environment.iterableType(node.typeArgument, currentLibrary.nonNullable);
    for (Expression part in node.lists) {
      DartType partType = visitExpression(part);
      checkAssignable(node, type, partType);
    }
    return type;
  }

  @override
  DartType visitSetConcatenation(SetConcatenation node) {
    DartType type =
        environment.iterableType(node.typeArgument, currentLibrary.nonNullable);
    for (Expression part in node.sets) {
      DartType partType = visitExpression(part);
      checkAssignable(node, type, partType);
    }
    return type;
  }

  @override
  DartType visitMapConcatenation(MapConcatenation node) {
    DartType type = environment.mapType(
        node.keyType, node.valueType, currentLibrary.nonNullable);
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
        node.classNode, currentLibrary.nonNullable, node.typeArguments);
  }

  @override
  DartType visitFileUriExpression(FileUriExpression node) {
    return visitExpression(node.expression);
  }

  @override
  DartType visitStringLiteral(StringLiteral node) {
    return environment.coreTypes.stringLegacyRawType;
  }

  @override
  DartType visitSuperMethodInvocation(SuperMethodInvocation node) {
    if (node.interfaceTarget == null) {
      checkUnresolvedInvocation(currentThisType, node);
      return handleDynamicCall(currentThisType, node.arguments);
    } else {
      return handleCall(node.arguments, node.interfaceTarget.getterType,
          receiver: getSuperReceiverType(node.interfaceTarget));
    }
  }

  @override
  DartType visitSuperPropertyGet(SuperPropertyGet node) {
    if (node.interfaceTarget == null) {
      checkUnresolvedInvocation(currentThisType, node);
      return const DynamicType();
    } else {
      Substitution receiver = getSuperReceiverType(node.interfaceTarget);
      return receiver.substituteType(node.interfaceTarget.getterType);
    }
  }

  @override
  DartType visitSuperPropertySet(SuperPropertySet node) {
    DartType value = visitExpression(node.value);
    if (node.interfaceTarget != null) {
      Substitution receiver = getSuperReceiverType(node.interfaceTarget);
      checkAssignable(
          node.value,
          value,
          receiver.substituteType(node.interfaceTarget.setterType,
              contravariant: true));
    } else {
      checkUnresolvedInvocation(currentThisType, node);
    }
    return value;
  }

  @override
  DartType visitSymbolLiteral(SymbolLiteral node) {
    return environment.coreTypes.symbolLegacyRawType;
  }

  @override
  DartType visitThisExpression(ThisExpression node) {
    return currentThisType;
  }

  @override
  DartType visitThrow(Throw node) {
    visitExpression(node.expression);
    return const BottomType();
  }

  @override
  DartType visitTypeLiteral(TypeLiteral node) {
    return environment.coreTypes.typeLegacyRawType;
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
  DartType visitLoadLibrary(LoadLibrary node) {
    return environment.futureType(
        const DynamicType(), currentLibrary.nonNullable);
  }

  @override
  DartType visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return environment.coreTypes.objectLegacyRawType;
  }

  @override
  visitConstantExpression(ConstantExpression node) {
    return node.type;
  }

  @override
  visitAssertStatement(AssertStatement node) {
    visitExpression(node.condition);
    if (node.message != null) {
      visitExpression(node.message);
    }
  }

  @override
  visitBlock(Block node) {
    node.statements.forEach(visitStatement);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    node.statements.forEach(visitStatement);
  }

  @override
  visitBreakStatement(BreakStatement node) {}

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {}

  @override
  visitDoStatement(DoStatement node) {
    visitStatement(node.body);
    node.condition = checkAndDowncastExpression(
        node.condition, environment.coreTypes.boolLegacyRawType);
  }

  @override
  visitEmptyStatement(EmptyStatement node) {}

  @override
  visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
  }

  @override
  visitForInStatement(ForInStatement node) {
    DartType iterable = visitExpression(node.iterable);
    // TODO(asgerf): Store interface targets on for-in loops or desugar them,
    // instead of doing the ad-hoc resolution here.
    if (node.isAsync) {
      checkAssignable(node, getStreamElementType(iterable), node.variable.type);
    } else {
      checkAssignable(
          node, getIterableElementType(iterable), node.variable.type);
    }
    visitStatement(node.body);
  }

  static final Name iteratorName = new Name('iterator');
  static final Name currentName = new Name('current');

  DartType getIterableElementType(DartType iterable) {
    if (iterable is InterfaceType) {
      Member iteratorGetter =
          hierarchy.getInterfaceMember(iterable.classNode, iteratorName);
      if (iteratorGetter == null) return const DynamicType();
      List<DartType> castedIterableArguments =
          hierarchy.getTypeArgumentsAsInstanceOf(
              iterable, iteratorGetter.enclosingClass);
      DartType iteratorType = Substitution.fromPairs(
              iteratorGetter.enclosingClass.typeParameters,
              castedIterableArguments)
          .substituteType(iteratorGetter.getterType);
      if (iteratorType is InterfaceType) {
        Member currentGetter =
            hierarchy.getInterfaceMember(iteratorType.classNode, currentName);
        if (currentGetter == null) return const DynamicType();
        List<DartType> castedIteratorTypeArguments =
            hierarchy.getTypeArgumentsAsInstanceOf(
                iteratorType, currentGetter.enclosingClass);
        return Substitution.fromPairs(
                currentGetter.enclosingClass.typeParameters,
                castedIteratorTypeArguments)
            .substituteType(currentGetter.getterType);
      }
    }
    return const DynamicType();
  }

  DartType getStreamElementType(DartType stream) {
    if (stream is InterfaceType) {
      List<DartType> asStreamArguments =
          hierarchy.getTypeArgumentsAsInstanceOf(stream, coreTypes.streamClass);
      if (asStreamArguments == null) return const DynamicType();
      return asStreamArguments.single;
    }
    return const DynamicType();
  }

  @override
  visitForStatement(ForStatement node) {
    node.variables.forEach(visitVariableDeclaration);
    if (node.condition != null) {
      node.condition = checkAndDowncastExpression(
          node.condition, environment.coreTypes.boolLegacyRawType);
    }
    node.updates.forEach(visitExpression);
    visitStatement(node.body);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    handleNestedFunctionNode(node.function);
  }

  @override
  visitIfStatement(IfStatement node) {
    node.condition = checkAndDowncastExpression(
        node.condition, environment.coreTypes.boolLegacyRawType);
    visitStatement(node.then);
    if (node.otherwise != null) {
      visitStatement(node.otherwise);
    }
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      if (currentReturnType == null) {
        fail(node, 'Return of a value from void method');
      } else {
        DartType type = visitExpression(node.expression);
        if (currentAsyncMarker == AsyncMarker.Async) {
          type = environment.flatten(type);
        }
        checkAssignable(node.expression, type, currentReturnType);
      }
    }
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    visitExpression(node.expression);
    for (SwitchCase switchCase in node.cases) {
      switchCase.expressions.forEach(visitExpression);
      visitStatement(switchCase.body);
    }
  }

  @override
  visitTryCatch(TryCatch node) {
    visitStatement(node.body);
    for (Catch catchClause in node.catches) {
      visitStatement(catchClause.body);
    }
  }

  @override
  visitTryFinally(TryFinally node) {
    visitStatement(node.body);
    visitStatement(node.finalizer);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null) {
      node.initializer =
          checkAndDowncastExpression(node.initializer, node.type);
    }
  }

  @override
  visitWhileStatement(WhileStatement node) {
    node.condition = checkAndDowncastExpression(
        node.condition, environment.coreTypes.boolLegacyRawType);
    visitStatement(node.body);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    if (node.isYieldStar) {
      Class container = currentAsyncMarker == AsyncMarker.AsyncStar
          ? coreTypes.streamClass
          : coreTypes.iterableClass;
      DartType type = visitExpression(node.expression);
      List<DartType> asContainerArguments = type is InterfaceType
          ? hierarchy.getTypeArgumentsAsInstanceOf(type, container)
          : null;
      if (asContainerArguments != null) {
        checkAssignable(
            node.expression, asContainerArguments[0], currentYieldType);
      } else {
        fail(node.expression, '$type is not an instance of $container');
      }
    } else {
      node.expression =
          checkAndDowncastExpression(node.expression, currentYieldType);
    }
  }

  @override
  visitFieldInitializer(FieldInitializer node) {
    node.value = checkAndDowncastExpression(node.value, node.field.type);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    handleCall(node.arguments, node.target.getterType,
        typeParameters: const <TypeParameter>[]);
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    handleCall(node.arguments, node.target.getterType,
        typeParameters: const <TypeParameter>[],
        receiver: getSuperReceiverType(node.target));
  }

  @override
  visitLocalInitializer(LocalInitializer node) {
    visitVariableDeclaration(node.variable);
  }

  @override
  visitAssertInitializer(AssertInitializer node) {
    visitAssertStatement(node.statement);
  }

  @override
  visitInvalidInitializer(InvalidInitializer node) {}

  @override
  DartType visitDynamicGet(DynamicGet node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    return const DynamicType();
  }

  @override
  DartType visitDynamicInvocation(DynamicInvocation node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    node.arguments.positional.forEach(visitExpression);
    node.arguments.named
        .forEach((NamedExpression n) => visitExpression(n.value));
    return const DynamicType();
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
    return environment.coreTypes.boolLegacyRawType;
  }

  @override
  DartType visitEqualsNull(EqualsNull node) {
    visitExpression(node.expression);
    return environment.coreTypes.boolLegacyRawType;
  }

  @override
  DartType visitFunctionInvocation(FunctionInvocation node) {
    DartType receiverType = visitExpression(node.receiver);
    checkUnresolvedInvocation(receiverType, node);
    node.arguments.positional.forEach(visitExpression);
    node.arguments.named
        .forEach((NamedExpression n) => visitExpression(n.value));
    // TODO(johnniwinther): Return the correct result type.
    return const DynamicType();
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
      visitExpression(node.receiver);
      return handleCall(node.arguments, target.getterType,
          receiver: getReceiverType(node, node.receiver, node.interfaceTarget));
    }
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
    // TODO(johnniwinther): Return the correct result type.
    return const DynamicType();
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
}
