// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

/// Base class for computing static types.
///
/// This class uses the visitor pattern to compute the static type that are
/// directly defined by the expression kind.
///
/// Subclasses will compute the static type or use a cache to look up the static
/// type of expression whose static type is not directly defined by the
/// expression kind. For instance method invocations whose static type depend
/// on the static types of the receiver and type arguments and the signature
/// of the targeted procedure.
class StaticTypeBase extends ir.Visitor<ir.DartType> {
  final ir.TypeEnvironment _typeEnvironment;

  StaticTypeBase(this._typeEnvironment);

  fail(String message) => message;

  ir.TypeEnvironment get typeEnvironment => _typeEnvironment;

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

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitDirectPropertySet(ir.DirectPropertySet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitThisExpression(ir.ThisExpression node) =>
      typeEnvironment.thisType;

  @override
  ir.DartType visitStaticGet(ir.StaticGet node) => node.target.getterType;

  @override
  ir.DartType visitStaticSet(ir.StaticSet node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitSuperPropertySet(ir.SuperPropertySet node) {
    return visitNode(node.value);
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

  @override
  ir.DartType visitInvalidExpression(ir.InvalidExpression node) =>
      const ir.BottomType();

  @override
  ir.DartType visitLoadLibrary(ir.LoadLibrary node) {
    return typeEnvironment.futureType(const ir.DynamicType());
  }
}
