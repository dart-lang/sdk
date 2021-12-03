// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

/// Special bottom type used to signal that an expression or statement does
/// not complete normally. This is the case for instance of throw expressions
/// and return statements.
class DoesNotCompleteType extends ir.NeverType {
  const DoesNotCompleteType() : super.internal(ir.Nullability.nonNullable);

  @override
  String toString() => 'DoesNotCompleteType()';
}

/// Special interface type used to signal that the static type of an expression
/// has precision of a this-expression.
class ThisInterfaceType extends ir.InterfaceType {
  ThisInterfaceType(ir.Class classNode, ir.Nullability nullability,
      [List<ir.DartType> typeArguments])
      : super(classNode, nullability, typeArguments);

  factory ThisInterfaceType.from(ir.InterfaceType type) => type != null
      ? ThisInterfaceType(type.classNode, type.nullability, type.typeArguments)
      : null;

  @override
  String toString() => 'this:${super.toString()}';
}

/// Special interface type used to signal that the static type of an expression
/// is exact, i.e. the runtime type is not a subtype or subclass of the type.
class ExactInterfaceType extends ir.InterfaceType {
  ExactInterfaceType(ir.Class classNode, ir.Nullability nullability,
      [List<ir.DartType> typeArguments])
      : super(classNode, nullability, typeArguments);

  factory ExactInterfaceType.from(ir.InterfaceType type) => type != null
      ? ExactInterfaceType(type.classNode, type.nullability, type.typeArguments)
      : null;

  @override
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
abstract class StaticTypeBase extends ir.Visitor<ir.DartType>
    with ir.VisitorNullMixin<ir.DartType> {
  final ir.TypeEnvironment _typeEnvironment;

  StaticTypeBase(this._typeEnvironment);

  fail(String message) => message;

  ir.TypeEnvironment get typeEnvironment => _typeEnvironment;

  ir.StaticTypeContext get staticTypeContext;

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

  @override
  ir.DartType defaultExpression(ir.Expression node) {
    throw fail('Unhandled node $node (${node.runtimeType})');
  }

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    return node.type;
  }

  @override
  ir.DartType visitAwaitExpression(ir.AwaitExpression node) {
    return typeEnvironment.flatten(visitNode(node.operand));
  }

  @override
  ir.DartType visitBoolLiteral(ir.BoolLiteral node) =>
      typeEnvironment.coreTypes.boolNonNullableRawType;

  @override
  ir.DartType visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded node) =>
      typeEnvironment.coreTypes.objectNonNullableRawType;

  @override
  ir.DartType visitStringLiteral(ir.StringLiteral node) =>
      typeEnvironment.coreTypes.stringNonNullableRawType;

  @override
  ir.DartType visitStringConcatenation(ir.StringConcatenation node) {
    return typeEnvironment.coreTypes.stringNonNullableRawType;
  }

  @override
  ir.DartType visitNullLiteral(ir.NullLiteral node) => const ir.NullType();

  @override
  ir.DartType visitIntLiteral(ir.IntLiteral node) =>
      typeEnvironment.coreTypes.intNonNullableRawType;

  @override
  ir.DartType visitDoubleLiteral(ir.DoubleLiteral node) =>
      typeEnvironment.coreTypes.doubleNonNullableRawType;

  @override
  ir.DartType visitSymbolLiteral(ir.SymbolLiteral node) =>
      typeEnvironment.coreTypes.symbolNonNullableRawType;

  @override
  ir.DartType visitListLiteral(ir.ListLiteral node) {
    return typeEnvironment.listType(
        node.typeArgument, ir.Nullability.nonNullable);
  }

  @override
  ir.DartType visitSetLiteral(ir.SetLiteral node) {
    return typeEnvironment.setType(
        node.typeArgument, ir.Nullability.nonNullable);
  }

  @override
  ir.DartType visitMapLiteral(ir.MapLiteral node) {
    return typeEnvironment.mapType(
        node.keyType, node.valueType, ir.Nullability.nonNullable);
  }

  @override
  ir.DartType visitVariableSet(ir.VariableSet node) {
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
      typeEnvironment.coreTypes.boolNonNullableRawType;

  @override
  ir.DartType visitNot(ir.Not node) {
    return typeEnvironment.coreTypes.boolNonNullableRawType;
  }

  @override
  ir.DartType visitConditionalExpression(ir.ConditionalExpression node) {
    return node.staticType;
  }

  @override
  ir.DartType visitIsExpression(ir.IsExpression node) {
    return typeEnvironment.coreTypes.boolNonNullableRawType;
  }

  @override
  ir.DartType visitTypeLiteral(ir.TypeLiteral node) =>
      typeEnvironment.coreTypes.typeNonNullableRawType;

  @override
  ir.DartType visitFunctionExpression(ir.FunctionExpression node) {
    return node.function.computeFunctionType(staticTypeContext.nonNullable);
  }

  @override
  ir.DartType visitLet(ir.Let node) {
    return visitNode(node.body);
  }

  @override
  ir.DartType visitBlockExpression(ir.BlockExpression node) {
    return visitNode(node.value);
  }

  @override
  ir.DartType visitInvalidExpression(ir.InvalidExpression node) =>
      const DoesNotCompleteType();

  @override
  ir.DartType visitLoadLibrary(ir.LoadLibrary node) {
    return typeEnvironment.futureType(
        const ir.DynamicType(), ir.Nullability.nonNullable);
  }

  @override
  ir.DartType visitConstantExpression(ir.ConstantExpression node) {
    // TODO(johnniwinther): Include interface exactness where applicable.
    return node.getStaticType(staticTypeContext);
  }

  @override
  ir.DartType visitEqualsNull(ir.EqualsNull node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitEqualsCall(ir.EqualsCall node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitDynamicInvocation(ir.DynamicInvocation node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitFunctionInvocation(ir.FunctionInvocation node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitLocalFunctionInvocation(ir.LocalFunctionInvocation node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitInstanceInvocation(ir.InstanceInvocation node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitInstanceGetterInvocation(ir.InstanceGetterInvocation node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitFunctionTearOff(ir.FunctionTearOff node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitInstanceTearOff(ir.InstanceTearOff node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitDynamicGet(ir.DynamicGet node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitInstanceGet(ir.InstanceGet node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitDynamicSet(ir.DynamicSet node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitInstanceSet(ir.InstanceSet node) =>
      node.getStaticType(staticTypeContext);

  @override
  ir.DartType visitStaticTearOff(ir.StaticTearOff node) =>
      node.getStaticType(staticTypeContext);
}
