// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

/// Visitor that computes the static type of an expression.
///
/// This visitor doesn't traverse subtrees that are not needed for computing
/// the static type.
// TODO(johnniwinther): Add improved type promotion to handle negative
// reasoning.
abstract class StaticTypeVisitor extends ir.Visitor<ir.DartType> {
  ir.TypeEnvironment _typeEnvironment;

  StaticTypeVisitor(this._typeEnvironment);

  fail(String message) => message;

  ir.TypeEnvironment get typeEnvironment => _typeEnvironment;

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

  @override
  ir.DartType defaultNode(ir.Node node) {
    return null;
  }

  ir.DartType visitNode(ir.Node node) {
    return node?.accept(this);
  }

  Null visitNodes(List<ir.Node> nodes) {
    for (ir.Node node in nodes) {
      visitNode(node);
    }
  }

  ir.DartType defaultExpression(ir.Expression node) {
    throw fail('Unhandled node $node (${node.runtimeType})');
  }

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    return node.type;
  }

  @override
  ir.DartType visitAwaitExpression(ir.AwaitExpression node) {
    return typeEnvironment.unfutureType(visitNode(node.operand));
  }

  @override
  ir.DartType visitBoolLiteral(ir.BoolLiteral node) => typeEnvironment.boolType;

  @override
  ir.DartType visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded node) =>
      typeEnvironment.objectType;

  @override
  ir.DartType visitStringLiteral(ir.StringLiteral node) =>
      typeEnvironment.stringType;

  @override
  ir.DartType visitStringConcatenation(ir.StringConcatenation node) {
    return typeEnvironment.stringType;
  }

  @override
  ir.DartType visitNullLiteral(ir.NullLiteral node) => const ir.BottomType();

  @override
  ir.DartType visitIntLiteral(ir.IntLiteral node) => typeEnvironment.intType;

  @override
  ir.DartType visitDoubleLiteral(ir.DoubleLiteral node) =>
      typeEnvironment.doubleType;

  @override
  ir.DartType visitSymbolLiteral(ir.SymbolLiteral node) =>
      typeEnvironment.symbolType;

  @override
  ir.DartType visitListLiteral(ir.ListLiteral node) {
    return typeEnvironment.literalListType(node.typeArgument);
  }

  @override
  ir.DartType visitMapLiteral(ir.MapLiteral node) {
    return typeEnvironment.literalMapType(node.keyType, node.valueType);
  }

  @override
  ir.DartType visitVariableGet(ir.VariableGet node) =>
      node.promotedType ?? node.variable.type;

  @override
  ir.DartType visitVariableSet(ir.VariableSet node) {
    return visitNode(node.value);
  }

  /// Computes the result type of the property access [node] on a receiver of
  /// type [receiverType].
  ///
  /// If the `node.interfaceTarget` is `null` but matches an `Object` member
  /// it is updated to target this member.
  ir.DartType computePropertyGetType(
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

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    return computePropertyGetType(node, receiverType);
  }

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitDirectPropertyGet(ir.DirectPropertyGet node) {
    ir.DartType receiverType = visitNode(node.receiver);
    ir.Class superclass = node.target.enclosingClass;
    receiverType = getTypeAsInstanceOf(receiverType, superclass);
    return ir.Substitution.fromInterfaceType(receiverType)
        .substituteType(node.target.getterType);
  }

  @override
  ir.DartType visitDirectMethodInvocation(ir.DirectMethodInvocation node) {
    ir.DartType receiverType = visitNode(node.receiver);
    if (typeEnvironment.isOverloadedArithmeticOperator(node.target)) {
      ir.DartType argumentType = visitNode(node.arguments.positional[0]);
      return typeEnvironment.getTypeOfOverloadedArithmetic(
          receiverType, argumentType);
    }
    ir.Class superclass = node.target.enclosingClass;
    receiverType = getTypeAsInstanceOf(receiverType, superclass);
    ir.DartType returnType = ir.Substitution.fromInterfaceType(receiverType)
        .substituteType(node.target.function.returnType);
    return ir.Substitution.fromPairs(
            node.target.function.typeParameters, node.arguments.types)
        .substituteType(returnType);
  }

  @override
  ir.DartType visitDirectPropertySet(ir.DirectPropertySet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitThisExpression(ir.ThisExpression node) =>
      typeEnvironment.thisType;

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
  ir.DartType narrowInstanceReceiver(
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
  ir.DartType computeMethodInvocationType(
      ir.MethodInvocation node, ir.DartType receiverType) {
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
        ir.DartType argumentType = visitNode(node.arguments.positional[0]);
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

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) {
    ir.DartType receiverType = visitNode(node.receiver);
    return computeMethodInvocationType(node, receiverType);
  }

  @override
  ir.DartType visitStaticGet(ir.StaticGet node) => node.target.getterType;

  @override
  ir.DartType visitStaticSet(ir.StaticSet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitStaticInvocation(ir.StaticInvocation node) {
    return ir.Substitution.fromPairs(
            node.target.function.typeParameters, node.arguments.types)
        .substituteType(node.target.function.returnType);
  }

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) {
    return node.arguments.types.isEmpty
        ? node.target.enclosingClass.rawType
        : new ir.InterfaceType(
            node.target.enclosingClass, node.arguments.types);
  }

  @override
  ir.DartType visitSuperPropertyGet(ir.SuperPropertyGet node) {
    if (node.interfaceTarget == null) {
      // TODO(johnniwinther): Resolve and set the target here.
      return const ir.DynamicType();
    }
    ir.Class declaringClass = node.interfaceTarget.enclosingClass;
    if (declaringClass.typeParameters.isEmpty) {
      return node.interfaceTarget.getterType;
    }
    ir.DartType receiver = typeEnvironment.hierarchy
        .getTypeAsInstanceOf(typeEnvironment.thisType, declaringClass);
    return ir.Substitution.fromInterfaceType(receiver)
        .substituteType(node.interfaceTarget.getterType);
  }

  @override
  ir.DartType visitSuperPropertySet(ir.SuperPropertySet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    if (node.interfaceTarget == null) {
      // TODO(johnniwinther): Resolve and set the target here.
      return const ir.DynamicType();
    }
    ir.Class superclass = node.interfaceTarget.enclosingClass;
    ir.InterfaceType receiverType = typeEnvironment.hierarchy
        .getTypeAsInstanceOf(typeEnvironment.thisType, superclass);
    ir.DartType returnType = ir.Substitution.fromInterfaceType(receiverType)
        .substituteType(node.interfaceTarget.function.returnType);
    return ir.Substitution.fromPairs(
            node.interfaceTarget.function.typeParameters, node.arguments.types)
        .substituteType(returnType);
  }

  @override
  ir.DartType visitThrow(ir.Throw node) => const ir.BottomType();

  @override
  ir.DartType visitRethrow(ir.Rethrow node) => const ir.BottomType();

  @override
  ir.DartType visitLogicalExpression(ir.LogicalExpression node) =>
      typeEnvironment.boolType;

  @override
  ir.DartType visitNot(ir.Not node) {
    return typeEnvironment.boolType;
  }

  @override
  ir.DartType visitConditionalExpression(ir.ConditionalExpression node) {
    return node.staticType;
  }

  @override
  ir.DartType visitIsExpression(ir.IsExpression node) {
    return typeEnvironment.boolType;
  }

  @override
  ir.DartType visitTypeLiteral(ir.TypeLiteral node) => typeEnvironment.typeType;

  @override
  ir.DartType visitFunctionExpression(ir.FunctionExpression node) {
    return node.function.functionType;
  }

  @override
  ir.DartType visitLet(ir.Let node) {
    return visitNode(node.body);
  }

  ir.DartType computeInstantiationType(
      ir.Instantiation node, ir.FunctionType expressionType) {
    return ir.Substitution.fromPairs(
            expressionType.typeParameters, node.typeArguments)
        .substituteType(expressionType.withoutTypeParameters);
  }

  @override
  ir.DartType visitInstantiation(ir.Instantiation node) {
    ir.FunctionType expressionType = visitNode(node.expression);
    return computeInstantiationType(node, expressionType);
  }

  @override
  ir.DartType visitInvalidExpression(ir.InvalidExpression node) =>
      const ir.BottomType();

  @override
  ir.DartType visitLoadLibrary(ir.LoadLibrary node) {
    return typeEnvironment.futureType(const ir.DynamicType());
  }
}

/// Visitor that computes the static type of an expression using a cache to
/// avoid recomputations.
class CachingStaticTypeVisitor extends StaticTypeVisitor {
  Map<ir.Expression, ir.DartType> _cache = {};

  CachingStaticTypeVisitor(ir.TypeEnvironment typeEnvironment)
      : super(typeEnvironment);

  @override
  ir.DartType visitNode(ir.Node node) {
    ir.DartType result;
    if (node is ir.Expression) {
      result = _cache[node];
      if (result != null) return result;
      result = super.visitNode(node);
      _cache[node] = result;
    } else {
      result = super.visitNode(node);
    }
    return result;
  }
}

/// Visitor that traverse the whole tree while returning the static type of
/// expressions.
abstract class StaticTypeTraversalVisitor extends StaticTypeVisitor {
  StaticTypeTraversalVisitor(ir.TypeEnvironment typeEnvironment)
      : super(typeEnvironment);

  @override
  ir.DartType defaultNode(ir.Node node) {
    node.visitChildren(this);
    return null;
  }

  Null defaultMember(ir.Member node) {
    typeEnvironment.thisType =
        node.enclosingClass != null ? node.enclosingClass.thisType : null;
    node.visitChildren(this);
    typeEnvironment.thisType = null;
    return null;
  }

  ir.DartType visitExpressionStatement(ir.ExpressionStatement node) {
    visitNode(node.expression);
    return null;
  }

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    visitNode(node.operand);
    return super.visitAsExpression(node);
  }

  @override
  ir.DartType visitStringConcatenation(ir.StringConcatenation node) {
    visitNodes(node.expressions);
    return super.visitStringConcatenation(node);
  }

  @override
  ir.DartType visitListLiteral(ir.ListLiteral node) {
    visitNodes(node.expressions);
    return super.visitListLiteral(node);
  }

  @override
  ir.DartType visitMapLiteral(ir.MapLiteral node) {
    visitNodes(node.entries);
    return super.visitMapLiteral(node);
  }

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    visitNode(node.receiver);
    return super.visitPropertySet(node);
  }

  @override
  ir.DartType visitDirectMethodInvocation(ir.DirectMethodInvocation node) {
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return super.visitDirectMethodInvocation(node);
  }

  @override
  ir.DartType visitDirectPropertySet(ir.DirectPropertySet node) {
    visitNode(node.receiver);
    return super.visitDirectPropertySet(node);
  }

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) {
    if (isSpecialCasedBinaryOperator(node.interfaceTarget)) {
      return super.visitMethodInvocation(node);
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return super.visitMethodInvocation(node);
  }

  @override
  ir.DartType visitStaticInvocation(ir.StaticInvocation node) {
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return super.visitStaticInvocation(node);
  }

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) {
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return super.visitConstructorInvocation(node);
  }

  @override
  ir.DartType visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return super.visitSuperMethodInvocation(node);
  }

  @override
  ir.DartType visitThrow(ir.Throw node) {
    visitNode(node.expression);
    return super.visitThrow(node);
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

  @override
  ir.DartType visitIsExpression(ir.IsExpression node) {
    visitNode(node.operand);
    return super.visitIsExpression(node);
  }

  @override
  ir.DartType visitFunctionExpression(ir.FunctionExpression node) {
    visitNode(node.function.body);
    return super.visitFunctionExpression(node);
  }

  @override
  ir.DartType visitLet(ir.Let node) {
    visitNode(node.variable.initializer);
    return super.visitLet(node);
  }
}
