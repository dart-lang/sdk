// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'static_type_base.dart';

/// Visitor that computes and caches the static type of expression while
/// visiting the full tree at expression level.
///
/// To ensure that the traversal only visits and computes the expression type
/// for each expression once, this class performs the traversal explicitly and
/// adds 'handleX' hooks for subclasses to handle individual expressions using
/// the readily compute static types of subexpressions.
// TODO(johnniwinther): Add improved type promotion to handle negative
// reasoning.
abstract class StaticTypeVisitor extends StaticTypeBase {
  Map<ir.Expression, ir.DartType> _cache = {};

  StaticTypeVisitor(ir.TypeEnvironment typeEnvironment)
      : super(typeEnvironment);

  Map<ir.Expression, ir.DartType> get staticTypeCacheForTesting => _cache;

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
      return superclass.rawType;
    }
    while (type is ir.TypeParameterType) {
      type = (type as ir.TypeParameterType).parameter.bound;
    }
    if (type is ir.InterfaceType) {
      ir.InterfaceType upcastType =
          typeEnvironment.hierarchy.getTypeAsInstanceOf(type, superclass);
      if (upcastType != null) return upcastType;
    } else if (type is ir.BottomType) {
      return superclass.bottomType;
    }
    return superclass.rawType;
  }

  /// Computes the result type of the property access [node] on a receiver of
  /// type [receiverType].
  ///
  /// If the `node.interfaceTarget` is `null` but matches an `Object` member
  /// it is updated to target this member.
  ir.DartType _computePropertyGetType(
      ir.PropertyGet node, ir.DartType receiverType) {
    ir.Member interfaceTarget = node.interfaceTarget;
    if (interfaceTarget != null) {
      ir.Class superclass = interfaceTarget.enclosingClass;
      receiverType = getTypeAsInstanceOf(receiverType, superclass);
      return ir.Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
    }
    // Treat the properties of Object specially.
    String nameString = node.name.name;
    if (nameString == 'hashCode') {
      return typeEnvironment.intType;
    } else if (nameString == 'runtimeType') {
      return typeEnvironment.typeType;
    }
    return const ir.DynamicType();
  }

  void handlePropertyGet(
      ir.PropertyGet node, ir.DartType receiverType, ir.DartType resultType) {}

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType resultType =
        _cache[node] = _computePropertyGetType(node, receiverType);
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    handlePropertyGet(node, receiverType, resultType);
    return resultType;
  }

  void handlePropertySet(
      ir.PropertySet node, ir.DartType receiverType, ir.DartType valueType) {}

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType valueType = super.visitPropertySet(node);
    receiverType = _narrowInstanceReceiver(node.interfaceTarget, receiverType);
    handlePropertySet(node, receiverType, valueType);
    return valueType;
  }

  void handleDirectPropertyGet(ir.DirectPropertyGet node,
      ir.DartType receiverType, ir.DartType resultType) {}

  @override
  ir.DartType visitDirectPropertyGet(ir.DirectPropertyGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.Class superclass = node.target.enclosingClass;
    receiverType = getTypeAsInstanceOf(receiverType, superclass);
    ir.DartType resultType = ir.Substitution.fromInterfaceType(receiverType)
        .substituteType(node.target.getterType);
    _cache[node] = resultType;
    handleDirectPropertyGet(node, receiverType, resultType);
    return resultType;
  }

  void handleDirectMethodInvocation(
      ir.DirectMethodInvocation node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {}

  @override
  ir.DartType visitDirectMethodInvocation(ir.DirectMethodInvocation node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType returnType;
    if (typeEnvironment.isOverloadedArithmeticOperator(node.target)) {
      ir.DartType argumentType = argumentTypes.positional[0];
      returnType = typeEnvironment.getTypeOfOverloadedArithmetic(
          receiverType, argumentType);
    } else {
      ir.Class superclass = node.target.enclosingClass;
      receiverType = getTypeAsInstanceOf(receiverType, superclass);
      ir.DartType returnType = ir.Substitution.fromInterfaceType(receiverType)
          .substituteType(node.target.function.returnType);
      returnType = ir.Substitution.fromPairs(
              node.target.function.typeParameters, node.arguments.types)
          .substituteType(returnType);
    }
    _cache[node] = returnType;
    handleDirectMethodInvocation(node, receiverType, argumentTypes, returnType);
    return returnType;
  }

  void handleDirectPropertySet(ir.DirectPropertySet node,
      ir.DartType receiverType, ir.DartType valueType) {}

  @override
  ir.DartType visitDirectPropertySet(ir.DirectPropertySet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType valueType = super.visitDirectPropertySet(node);
    handleDirectPropertySet(node, receiverType, valueType);
    return valueType;
  }

  /// Returns `true` if [interfaceTarget] is an arithmetic operator whose result
  /// type is computed using both the receiver type and the argument type.
  ///
  /// Visitors that subclass the [StaticTypeVisitor] must special case this
  /// target as to avoid visiting the argument twice.
  bool isSpecialCasedBinaryOperator(ir.Member interfaceTarget) {
    return interfaceTarget is ir.Procedure &&
        typeEnvironment.isOverloadedArithmeticOperator(interfaceTarget);
  }

  ir.Member _getMember(ir.Class cls, String name) {
    for (ir.Member member in cls.members) {
      if (member.name.name == name) return member;
    }
    throw fail("Member '$name' not found in $cls");
  }

  ir.Procedure _objectEquals;
  ir.Procedure get objectEquals =>
      _objectEquals ??= _getMember(typeEnvironment.objectType.classNode, '==');

  /// Returns [receiverType] narrowed to enclosing class of [interfaceTarget].
  ///
  /// If [interfaceTarget] is `null` or `receiverType` is _not_ `dynamic` no
  /// narrowing is performed.
  ir.DartType _narrowInstanceReceiver(
      ir.Member interfaceTarget, ir.DartType receiverType) {
    if (interfaceTarget != null && receiverType == const ir.DynamicType()) {
      receiverType = interfaceTarget.enclosingClass.thisType;
    }
    return receiverType;
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
        node.name.name == '==' &&
        node.arguments.types.isEmpty &&
        node.arguments.positional.length == 1 &&
        node.arguments.named.isEmpty) {
      interfaceTarget = node.interfaceTarget = objectEquals;
    }
    if (interfaceTarget != null) {
      if (isSpecialCasedBinaryOperator(interfaceTarget)) {
        ir.DartType argumentType = argumentTypes.positional[0];
        return typeEnvironment.getTypeOfOverloadedArithmetic(
            receiverType, argumentType);
      }
      ir.Class superclass = interfaceTarget.enclosingClass;
      receiverType = getTypeAsInstanceOf(receiverType, superclass);
      ir.DartType getterType = ir.Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
      if (getterType is ir.FunctionType) {
        return ir.Substitution.fromPairs(
                getterType.typeParameters, node.arguments.types)
            .substituteType(getterType.returnType);
      } else {
        return const ir.DynamicType();
      }
    }
    if (node.name.name == 'call') {
      if (receiverType is ir.FunctionType) {
        if (receiverType.typeParameters.length != node.arguments.types.length) {
          return const ir.BottomType();
        }
        return ir.Substitution.fromPairs(
                receiverType.typeParameters, node.arguments.types)
            .substituteType(receiverType.returnType);
      }
    }
    if (node.name.name == '==') {
      // We use this special case to simplify generation of '==' checks.
      return typeEnvironment.boolType;
    }
    return const ir.DynamicType();
  }

  ArgumentTypes _visitArguments(ir.Arguments arguments) {
    List<ir.DartType> positional;
    List<ir.DartType> named;
    if (arguments.positional.isEmpty) {
      positional = const <ir.DartType>[];
    } else {
      positional = new List<ir.DartType>(arguments.positional.length);
      int index = 0;
      for (ir.Expression argument in arguments.positional) {
        positional[index++] = visitNode(argument);
      }
    }
    if (arguments.named.isEmpty) {
      named = const <ir.DartType>[];
    } else {
      named = new List<ir.DartType>(arguments.named.length);
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
    _cache[node] = returnType;
    handleMethodInvocation(node, receiverType, argumentTypes, returnType);
    return returnType;
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
    _cache[node] = returnType;
    handleStaticInvocation(node, argumentTypes, returnType);
    return returnType;
  }

  void handleConstructorInvocation(ir.ConstructorInvocation node,
      ArgumentTypes argumentTypes, ir.DartType resultType) {}

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) {
    ArgumentTypes argumentTypes = _visitArguments(node.arguments);
    ir.DartType resultType = node.arguments.types.isEmpty
        ? node.target.enclosingClass.rawType
        : new ir.InterfaceType(
            node.target.enclosingClass, node.arguments.types);
    _cache[node] = resultType;
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
        ir.DartType receiver = typeEnvironment.hierarchy
            .getTypeAsInstanceOf(typeEnvironment.thisType, declaringClass);
        resultType = ir.Substitution.fromInterfaceType(receiver)
            .substituteType(node.interfaceTarget.getterType);
      }
    }
    _cache[node] = resultType;
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
      ir.InterfaceType receiverType = typeEnvironment.hierarchy
          .getTypeAsInstanceOf(typeEnvironment.thisType, superclass);
      returnType = ir.Substitution.fromInterfaceType(receiverType)
          .substituteType(node.interfaceTarget.function.returnType);
      returnType = ir.Substitution.fromPairs(
              node.interfaceTarget.function.typeParameters,
              node.arguments.types)
          .substituteType(returnType);
    }
    _cache[node] = returnType;
    handleSuperMethodInvocation(node, argumentTypes, returnType);
    return returnType;
  }

  @override
  ir.DartType visitLogicalExpression(ir.LogicalExpression node) {
    visitNode(node.left);
    visitNode(node.right);
    return super.visitLogicalExpression(node);
  }

  @override
  ir.DartType visitNot(ir.Not node) {
    visitNode(node.operand);
    return super.visitNot(node);
  }

  @override
  ir.DartType visitConditionalExpression(ir.ConditionalExpression node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
    return super.visitConditionalExpression(node);
  }

  void handleIsExpression(ir.IsExpression node) {}

  @override
  ir.DartType visitIsExpression(ir.IsExpression node) {
    visitNode(node.operand);
    handleIsExpression(node);
    return super.visitIsExpression(node);
  }

  @override
  ir.DartType visitLet(ir.Let node) {
    visitNode(node.variable.initializer);
    return super.visitLet(node);
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
    _cache[node] = resultType;
    handleInstantiation(node, expressionType, resultType);
    return resultType;
  }

  @override
  Null visitBlock(ir.Block node) => visitNodes(node.statements);

  ir.DartType visitExpressionStatement(ir.ExpressionStatement node) {
    visitNode(node.expression);
    return null;
  }

  void handleAsExpression(ir.AsExpression node) {}

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    visitNode(node.operand);
    handleAsExpression(node);
    return super.visitAsExpression(node);
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
    visitSignature(node.function);
    visitNode(node.function.body);
    handleFunctionExpression(node);
    return super.visitFunctionExpression(node);
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
  Null visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {}

  @override
  Null visitLabeledStatement(ir.LabeledStatement node) {
    visitNode(node.body);
  }

  @override
  Null visitBreakStatement(ir.BreakStatement node) {}

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
    visitNode(node.condition);
    visitNodes(node.updates);
    visitNode(node.body);
  }

  void handleForInStatement(ir.ForInStatement node, ir.DartType iterableType) {}

  @override
  Null visitForInStatement(ir.ForInStatement node) {
    visitNode(node.variable);
    ir.DartType iterableType = visitNode(node.iterable);
    visitNode(node.body);
    handleForInStatement(node, iterableType);
  }

  @override
  Null visitDoStatement(ir.DoStatement node) {
    visitNode(node.body);
    visitNode(node.condition);
  }

  @override
  Null visitWhileStatement(ir.WhileStatement node) {
    visitNode(node.condition);
    visitNode(node.body);
  }

  void handleSwitchStatement(ir.SwitchStatement node) {}

  @override
  Null visitSwitchStatement(ir.SwitchStatement node) {
    visitNode(node.expression);
    visitNodes(node.cases);
    handleSwitchStatement(node);
  }

  @override
  Null visitReturnStatement(ir.ReturnStatement node) {
    visitNode(node.expression);
  }

  @override
  Null visitIfStatement(ir.IfStatement node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
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
    visitNode(node.condition);
    visitNode(node.message);
    handleAssertStatement(node);
  }

  void handleFunctionDeclaration(ir.FunctionDeclaration node) {}

  @override
  Null visitFunctionDeclaration(ir.FunctionDeclaration node) {
    visitSignature(node.function);
    visitNode(node.function.body);
    handleFunctionDeclaration(node);
  }

  void handleParameter(ir.VariableDeclaration node) {}

  void visitParameter(ir.VariableDeclaration node) {
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
    typeEnvironment.thisType =
        node.enclosingClass != null ? node.enclosingClass.thisType : null;
    visitSignature(node.function);
    visitNode(node.function.body);
    handleProcedure(node);
    typeEnvironment.thisType = null;
  }

  void handleConstructor(ir.Constructor node) {}

  @override
  Null visitConstructor(ir.Constructor node) {
    typeEnvironment.thisType = node.enclosingClass.thisType;
    visitSignature(node.function);
    visitNodes(node.initializers);
    visitNode(node.function.body);
    handleConstructor(node);
    typeEnvironment.thisType = null;
  }

  void handleField(ir.Field node) {}

  @override
  Null visitField(ir.Field node) {
    typeEnvironment.thisType =
        node.enclosingClass != null ? node.enclosingClass.thisType : null;
    visitNode(node.initializer);
    handleField(node);
    typeEnvironment.thisType = null;
  }

  void handleVariableDeclaration(ir.VariableDeclaration node) {}

  @override
  Null visitVariableDeclaration(ir.VariableDeclaration node) {
    visitNode(node.initializer);
    handleVariableDeclaration(node);
  }
}

class ArgumentTypes {
  final List<ir.DartType> positional;
  final List<ir.DartType> named;

  ArgumentTypes(this.positional, this.named);
}
