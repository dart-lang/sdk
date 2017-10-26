// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_checker;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'type_algebra.dart';
import 'type_environment.dart';

/// Performs strong-mode type checking on the kernel IR.
///
/// A concrete subclass of [TypeChecker] must implement [checkAssignable] and
/// [fail] in order to deal with subtyping requirements and error handling.
abstract class TypeChecker {
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final bool ignoreSdk;
  TypeEnvironment environment;

  TypeChecker(this.coreTypes, this.hierarchy,
      {bool strongMode: false, this.ignoreSdk: true}) {
    environment =
        new TypeEnvironment(coreTypes, hierarchy, strongMode: strongMode);
  }

  void checkProgram(Program program) {
    for (var library in program.libraries) {
      if (ignoreSdk && library.importUri.scheme == 'dart') continue;
      for (var class_ in library.classes) {
        hierarchy.forEachOverridePair(class_,
            (Member ownMember, Member superMember, bool isSetter) {
          checkOverride(class_, ownMember, superMember, isSetter);
        });
      }
    }
    var visitor = new TypeCheckingVisitor(this, environment);
    for (var library in program.libraries) {
      if (ignoreSdk && library.importUri.scheme == 'dart') continue;
      for (var class_ in library.classes) {
        environment.thisType = class_.thisType;
        for (var field in class_.fields) {
          visitor.visitField(field);
        }
        for (var constructor in class_.constructors) {
          visitor.visitConstructor(constructor);
        }
        for (var procedure in class_.procedures) {
          visitor.visitProcedure(procedure);
        }
      }
      environment.thisType = null;
      for (var procedure in library.procedures) {
        visitor.visitProcedure(procedure);
      }
      for (var field in library.fields) {
        visitor.visitField(field);
      }
    }
  }

  DartType getterType(Class host, Member member) {
    var hostType = hierarchy.getClassAsInstanceOf(host, member.enclosingClass);
    var substitution = Substitution.fromSupertype(hostType);
    return substitution.substituteType(member.getterType);
  }

  DartType setterType(Class host, Member member) {
    var hostType = hierarchy.getClassAsInstanceOf(host, member.enclosingClass);
    var substitution = Substitution.fromSupertype(hostType);
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

  CoreTypes get coreTypes => environment.coreTypes;
  ClassHierarchy get hierarchy => environment.hierarchy;
  Class get currentClass => environment.thisType.classNode;

  TypeCheckingVisitor(this.checker, this.environment);

  void checkAssignable(TreeNode where, DartType from, DartType to) {
    checker.checkAssignable(where, from, to);
  }

  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    checker.checkUnresolvedInvocation(receiver, where);
  }

  Expression checkAndDowncastExpression(Expression from, DartType to) {
    var parent = from.parent;
    var type = visitExpression(from);
    var result = checker.checkAndDowncastExpression(from, type, to);
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
    environment.returnType = null;
    environment.yieldType = null;
    node.initializers.forEach(visitInitializer);
    handleFunctionNode(node.function);
  }

  visitProcedure(Procedure node) {
    environment.returnType = _getInternalReturnType(node.function);
    environment.yieldType = _getYieldType(node.function);
    handleFunctionNode(node.function);
  }

  void handleFunctionNode(FunctionNode node) {
    var oldAsyncMarker = environment.currentAsyncMarker;
    environment.currentAsyncMarker = node.asyncMarker;
    node.positionalParameters
        .skip(node.requiredParameterCount)
        .forEach(handleOptionalParameter);
    node.namedParameters.forEach(handleOptionalParameter);
    if (node.body != null) {
      visitStatement(node.body);
    }
    environment.currentAsyncMarker = oldAsyncMarker;
  }

  void handleNestedFunctionNode(FunctionNode node) {
    var oldReturn = environment.returnType;
    var oldYield = environment.yieldType;
    environment.returnType = _getInternalReturnType(node);
    environment.yieldType = _getYieldType(node);
    handleFunctionNode(node);
    environment.returnType = oldReturn;
    environment.yieldType = oldYield;
  }

  void handleOptionalParameter(VariableDeclaration parameter) {
    if (parameter.initializer != null) {
      // Default parameter values cannot be downcast.
      checkExpressionNoDowncast(parameter.initializer, parameter.type);
    }
  }

  Substitution getReceiverType(
      TreeNode access, Expression receiver, Member member) {
    var type = visitExpression(receiver);
    Class superclass = member.enclosingClass;
    if (superclass.supertype == null) {
      return Substitution.empty; // Members on Object are always accessible.
    }
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).bound;
    }
    if (type is BottomType) {
      // The bottom type is a subtype of all types, so it should be allowed.
      return Substitution.bottomForClass(superclass);
    }
    if (type is InterfaceType) {
      // The receiver type should implement the interface declaring the member.
      var upcastType = hierarchy.getTypeAsInstanceOf(type, superclass);
      if (upcastType != null) {
        return Substitution.fromInterfaceType(upcastType);
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
      if (arguments.types.length != typeParameters.length) {
        fail(arguments, 'Wrong number of type arguments');
        return const BottomType();
      }
      var instantiation =
          Substitution.fromPairs(typeParameters, arguments.types);
      var substitution = Substitution.combine(receiver, instantiation);
      for (int i = 0; i < typeParameters.length; ++i) {
        var argument = arguments.types[i];
        var bound = substitution.substituteType(typeParameters[i].bound);
        checkAssignable(arguments, argument, bound);
      }
      for (int i = 0; i < arguments.positional.length; ++i) {
        var expectedType = substitution.substituteType(
            functionType.positionalParameters[i],
            contravariant: true);
        arguments.positional[i] =
            checkAndDowncastExpression(arguments.positional[i], expectedType);
      }
      for (int i = 0; i < arguments.named.length; ++i) {
        var argument = arguments.named[i];
        bool found = false;
        for (int j = 0; j < functionType.namedParameters.length; ++j) {
          if (argument.name == functionType.namedParameters[j].name) {
            var expectedType = substitution.substituteType(
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
        TreeNode parent = function.parent;
        while (parent is! FunctionNode) {
          parent = parent.parent;
        }
        final enclosingFunction = parent as FunctionNode;
        if (enclosingFunction.dartAsyncMarker == AsyncMarker.SyncStar) {
          return coreTypes.boolClass.rawType;
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

  @override
  DartType visitAsExpression(AsExpression node) {
    visitExpression(node.operand);
    return node.type;
  }

  @override
  DartType visitAwaitExpression(AwaitExpression node) {
    return environment.unfutureType(visitExpression(node.operand));
  }

  @override
  DartType visitBoolLiteral(BoolLiteral node) {
    return environment.boolType;
  }

  @override
  DartType visitConditionalExpression(ConditionalExpression node) {
    node.condition =
        checkAndDowncastExpression(node.condition, environment.boolType);
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
    handleCall(arguments, target.function.functionType,
        typeParameters: class_.typeParameters);
    return new InterfaceType(target.enclosingClass, arguments.types);
  }

  @override
  DartType visitDirectMethodInvocation(DirectMethodInvocation node) {
    return handleCall(node.arguments, node.target.getterType,
        receiver: getReceiverType(node, node.receiver, node.target));
  }

  @override
  DartType visitDirectPropertyGet(DirectPropertyGet node) {
    var receiver = getReceiverType(node, node.receiver, node.target);
    return receiver.substituteType(node.target.getterType);
  }

  @override
  DartType visitDirectPropertySet(DirectPropertySet node) {
    var receiver = getReceiverType(node, node.receiver, node.target);
    var value = visitExpression(node.value);
    checkAssignable(node, value,
        receiver.substituteType(node.target.setterType, contravariant: true));
    return value;
  }

  @override
  DartType visitDoubleLiteral(DoubleLiteral node) {
    return environment.doubleType;
  }

  @override
  DartType visitFunctionExpression(FunctionExpression node) {
    handleNestedFunctionNode(node.function);
    return node.function.functionType;
  }

  @override
  DartType visitIntLiteral(IntLiteral node) {
    return environment.intType;
  }

  @override
  DartType visitInvalidExpression(InvalidExpression node) {
    return const BottomType();
  }

  @override
  DartType visitIsExpression(IsExpression node) {
    visitExpression(node.operand);
    return environment.boolType;
  }

  @override
  DartType visitLet(Let node) {
    var value = visitExpression(node.variable.initializer);
    if (node.variable.type is DynamicType) {
      node.variable.type = value;
    }
    return visitExpression(node.body);
  }

  @override
  DartType visitListLiteral(ListLiteral node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      node.expressions[i] =
          checkAndDowncastExpression(node.expressions[i], node.typeArgument);
    }
    return environment.literalListType(node.typeArgument);
  }

  @override
  DartType visitLogicalExpression(LogicalExpression node) {
    node.left = checkAndDowncastExpression(node.left, environment.boolType);
    node.right = checkAndDowncastExpression(node.right, environment.boolType);
    return environment.boolType;
  }

  @override
  DartType visitMapLiteral(MapLiteral node) {
    for (var entry in node.entries) {
      entry.key = checkAndDowncastExpression(entry.key, node.keyType);
      entry.value = checkAndDowncastExpression(entry.value, node.valueType);
    }
    return environment.literalMapType(node.keyType, node.valueType);
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
    var instantiation =
        Substitution.fromPairs(function.typeParameters, arguments.types);
    for (int i = 0; i < arguments.positional.length; ++i) {
      var expectedType = instantiation.substituteType(
          function.positionalParameters[i],
          contravariant: true);
      arguments.positional[i] =
          checkAndDowncastExpression(arguments.positional[i], expectedType);
    }
    for (int i = 0; i < arguments.named.length; ++i) {
      var argument = arguments.named[i];
      var parameterType = function.getNamedParameter(argument.name);
      if (parameterType != null) {
        var expectedType =
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
    var target = node.interfaceTarget;
    if (target == null) {
      var receiver = visitExpression(node.receiver);
      if (node.name.name == '==') {
        visitExpression(node.arguments.positional.single);
        return environment.boolType;
      }
      if (node.name.name == 'call' && receiver is FunctionType) {
        return handleFunctionCall(node, receiver, node.arguments);
      }
      checkUnresolvedInvocation(receiver, node);
      return handleDynamicCall(receiver, node.arguments);
    } else if (target is Procedure &&
        environment.isOverloadedArithmeticOperator(target)) {
      assert(node.arguments.positional.length == 1);
      var receiver = visitExpression(node.receiver);
      var argument = visitExpression(node.arguments.positional[0]);
      return environment.getTypeOfOverloadedArithmetic(receiver, argument);
    } else {
      return handleCall(node.arguments, target.getterType,
          receiver: getReceiverType(node, node.receiver, node.interfaceTarget));
    }
  }

  @override
  DartType visitPropertyGet(PropertyGet node) {
    if (node.interfaceTarget == null) {
      final receiver = visitExpression(node.receiver);
      checkUnresolvedInvocation(receiver, node);
      return const DynamicType();
    } else {
      var receiver = getReceiverType(node, node.receiver, node.interfaceTarget);
      return receiver.substituteType(node.interfaceTarget.getterType);
    }
  }

  @override
  DartType visitPropertySet(PropertySet node) {
    var value = visitExpression(node.value);
    if (node.interfaceTarget != null) {
      var receiver = getReceiverType(node, node.receiver, node.interfaceTarget);
      checkAssignable(
          node.value,
          value,
          receiver.substituteType(node.interfaceTarget.setterType,
              contravariant: true));
    } else {
      final receiver = visitExpression(node.receiver);
      checkUnresolvedInvocation(receiver, node);
    }
    return value;
  }

  @override
  DartType visitNot(Not node) {
    visitExpression(node.operand);
    return environment.boolType;
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
    var value = visitExpression(node.value);
    checkAssignable(node.value, value, node.target.setterType);
    return value;
  }

  @override
  DartType visitStringConcatenation(StringConcatenation node) {
    node.expressions.forEach(visitExpression);
    return environment.stringType;
  }

  @override
  DartType visitStringLiteral(StringLiteral node) {
    return environment.stringType;
  }

  @override
  DartType visitSuperMethodInvocation(SuperMethodInvocation node) {
    if (node.interfaceTarget == null) {
      checkUnresolvedInvocation(environment.thisType, node);
      return handleDynamicCall(environment.thisType, node.arguments);
    } else {
      return handleCall(node.arguments, node.interfaceTarget.getterType,
          receiver: getSuperReceiverType(node.interfaceTarget));
    }
  }

  @override
  DartType visitSuperPropertyGet(SuperPropertyGet node) {
    if (node.interfaceTarget == null) {
      checkUnresolvedInvocation(environment.thisType, node);
      return const DynamicType();
    } else {
      var receiver = getSuperReceiverType(node.interfaceTarget);
      return receiver.substituteType(node.interfaceTarget.getterType);
    }
  }

  @override
  DartType visitSuperPropertySet(SuperPropertySet node) {
    var value = visitExpression(node.value);
    if (node.interfaceTarget != null) {
      var receiver = getSuperReceiverType(node.interfaceTarget);
      checkAssignable(
          node.value,
          value,
          receiver.substituteType(node.interfaceTarget.setterType,
              contravariant: true));
    } else {
      checkUnresolvedInvocation(environment.thisType, node);
    }
    return value;
  }

  @override
  DartType visitSymbolLiteral(SymbolLiteral node) {
    return environment.symbolType;
  }

  @override
  DartType visitThisExpression(ThisExpression node) {
    return environment.thisType;
  }

  @override
  DartType visitThrow(Throw node) {
    visitExpression(node.expression);
    return const BottomType();
  }

  @override
  DartType visitTypeLiteral(TypeLiteral node) {
    return environment.typeType;
  }

  @override
  DartType visitVariableGet(VariableGet node) {
    return node.promotedType ?? node.variable.type;
  }

  @override
  DartType visitVariableSet(VariableSet node) {
    var value = visitExpression(node.value);
    checkAssignable(node.value, value, node.variable.type);
    return value;
  }

  @override
  DartType visitLoadLibrary(LoadLibrary node) {
    return environment.futureType(const DynamicType());
  }

  @override
  DartType visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return environment.objectType;
  }

  @override
  DartType visitVectorCreation(VectorCreation node) {
    return const VectorType();
  }

  @override
  DartType visitVectorGet(VectorGet node) {
    var type = visitExpression(node.vectorExpression);
    if (type is! VectorType) {
      fail(
          node.vectorExpression,
          'The type of vector-expression in vector-get node is expected to be '
          'VectorType, but $type found');
    }
    return const DynamicType();
  }

  @override
  visitVectorSet(VectorSet node) {
    var type = visitExpression(node.vectorExpression);
    if (type is! VectorType) {
      fail(
          node.vectorExpression,
          'The type of vector-expression in vector-set node is expected to be '
          'VectorType, but $type found');
    }
    return visitExpression(node.value);
  }

  @override
  visitVectorCopy(VectorCopy node) {
    var type = visitExpression(node.vectorExpression);
    if (type is! VectorType) {
      fail(
          node.vectorExpression,
          'The type of vector-expression in vector-copy node is exected to be '
          'VectorType, but $type found');
    }
    return const VectorType();
  }

  @override
  visitClosureCreation(ClosureCreation node) {
    var contextType = visitExpression(node.contextVector);
    if (contextType is! VectorType) {
      fail(
          node.contextVector,
          "The second child of 'ClosureConversion' node is supposed to be a "
          "Vector, but $contextType found.");
    }
    return node.functionType;
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
  visitBreakStatement(BreakStatement node) {}

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {}

  @override
  visitDoStatement(DoStatement node) {
    visitStatement(node.body);
    node.condition =
        checkAndDowncastExpression(node.condition, environment.boolType);
  }

  @override
  visitEmptyStatement(EmptyStatement node) {}

  @override
  visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
  }

  @override
  visitForInStatement(ForInStatement node) {
    var iterable = visitExpression(node.iterable);
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
      var iteratorGetter =
          hierarchy.getInterfaceMember(iterable.classNode, iteratorName);
      if (iteratorGetter == null) return const DynamicType();
      var castedIterable = hierarchy.getTypeAsInstanceOf(
          iterable, iteratorGetter.enclosingClass);
      var iteratorType = Substitution
          .fromInterfaceType(castedIterable)
          .substituteType(iteratorGetter.getterType);
      if (iteratorType is InterfaceType) {
        var currentGetter =
            hierarchy.getInterfaceMember(iteratorType.classNode, currentName);
        if (currentGetter == null) return const DynamicType();
        var castedIteratorType = hierarchy.getTypeAsInstanceOf(
            iteratorType, currentGetter.enclosingClass);
        return Substitution
            .fromInterfaceType(castedIteratorType)
            .substituteType(currentGetter.getterType);
      }
    }
    return const DynamicType();
  }

  DartType getStreamElementType(DartType stream) {
    if (stream is InterfaceType) {
      var asStream =
          hierarchy.getTypeAsInstanceOf(stream, coreTypes.streamClass);
      if (asStream == null) return const DynamicType();
      return asStream.typeArguments.single;
    }
    return const DynamicType();
  }

  @override
  visitForStatement(ForStatement node) {
    node.variables.forEach(visitVariableDeclaration);
    if (node.condition != null) {
      node.condition =
          checkAndDowncastExpression(node.condition, environment.boolType);
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
    node.condition =
        checkAndDowncastExpression(node.condition, environment.boolType);
    visitStatement(node.then);
    if (node.otherwise != null) {
      visitStatement(node.otherwise);
    }
  }

  @override
  visitInvalidStatement(InvalidStatement node) {}

  @override
  visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      if (environment.returnType == null) {
        fail(node, 'Return of a value from void method');
      } else {
        var type = visitExpression(node.expression);
        if (environment.currentAsyncMarker == AsyncMarker.Async) {
          type = environment.unfutureType(type);
        }
        checkAssignable(node.expression, type, environment.returnType);
      }
    }
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    visitExpression(node.expression);
    for (var switchCase in node.cases) {
      switchCase.expressions.forEach(visitExpression);
      visitStatement(switchCase.body);
    }
  }

  @override
  visitTryCatch(TryCatch node) {
    visitStatement(node.body);
    for (var catchClause in node.catches) {
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
    node.condition =
        checkAndDowncastExpression(node.condition, environment.boolType);
    visitStatement(node.body);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    if (node.isYieldStar) {
      Class container = environment.currentAsyncMarker == AsyncMarker.AsyncStar
          ? coreTypes.streamClass
          : coreTypes.iterableClass;
      var type = visitExpression(node.expression);
      var asContainer = type is InterfaceType
          ? hierarchy.getTypeAsInstanceOf(type, container)
          : null;
      if (asContainer != null) {
        checkAssignable(node.expression, asContainer.typeArguments[0],
            environment.yieldType);
      } else {
        fail(node.expression, '$type is not an instance of $container');
      }
    } else {
      node.expression =
          checkAndDowncastExpression(node.expression, environment.yieldType);
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
  visitInvalidInitializer(InvalidInitializer node) {}
}
