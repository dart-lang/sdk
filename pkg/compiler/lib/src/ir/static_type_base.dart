// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

/// Special bottom type used to signal that an expression or statement does
/// not complete normally. This is the case for instance of throw expressions
/// and return statements.
class DoesNotCompleteType extends ir.BottomType {
  const DoesNotCompleteType();

  String toString() => 'DoesNotCompleteType()';
}

/// Special interface type used to signal that the static type of an expression
/// has precision of a this-expression.
class ThisInterfaceType extends ir.InterfaceType {
  ThisInterfaceType(ir.Class classNode, [List<ir.DartType> typeArguments])
      : super(classNode, typeArguments);

  factory ThisInterfaceType.from(ir.InterfaceType type) => type != null
      ? new ThisInterfaceType(type.classNode, type.typeArguments)
      : null;

  String toString() => 'this:${super.toString()}';
}

/// Special interface type used to signal that the static type of an expression
/// is exact, i.e. the runtime type is not a subtype or subclass of the type.
class ExactInterfaceType extends ir.InterfaceType {
  ExactInterfaceType(ir.Class classNode, [List<ir.DartType> typeArguments])
      : super(classNode, typeArguments);

  factory ExactInterfaceType.from(ir.InterfaceType type) => type != null
      ? new ExactInterfaceType(type.classNode, type.typeArguments)
      : null;

  String toString() => 'exact:${super.toString()}';
}

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
abstract class StaticTypeBase extends ir.Visitor<ir.DartType> {
  final ir.TypeEnvironment _typeEnvironment;

  StaticTypeBase(this._typeEnvironment);

  fail(String message) => message;

  ir.TypeEnvironment get typeEnvironment => _typeEnvironment;

  ThisInterfaceType get thisType;

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
  ir.DartType visitNullLiteral(ir.NullLiteral node) => typeEnvironment.nullType;

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
  ThisInterfaceType visitThisExpression(ir.ThisExpression node) => thisType;

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
  ir.DartType visitThrow(ir.Throw node) => const DoesNotCompleteType();

  @override
  ir.DartType visitRethrow(ir.Rethrow node) => const DoesNotCompleteType();

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
      const DoesNotCompleteType();

  @override
  ir.DartType visitLoadLibrary(ir.LoadLibrary node) {
    return typeEnvironment.futureType(const ir.DynamicType());
  }
}
