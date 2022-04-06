// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../serialization/serialization.dart';
import 'constants.dart';
import 'impact_data.dart';
import 'runtime_type_analysis.dart';
import 'static_type.dart';
import 'static_type_cache.dart';

/// Interface for collecting world impact data.
///
/// This is used both for direct world impact computation through the
/// [KernelImpactBuilder] and for serialization through the [ImpactBuilder]
/// and [ImpactLoader].
abstract class ImpactRegistry {
  void registerIntLiteral(int value);

  void registerDoubleLiteral(double value);

  void registerBoolLiteral(bool value);

  void registerStringLiteral(String value);

  void registerSymbolLiteral(String value);

  void registerNullLiteral();

  void registerListLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty});

  void registerSetLiteral(ir.DartType elementType,
      {bool isConst, bool isEmpty});

  void registerMapLiteral(ir.DartType keyType, ir.DartType valueType,
      {bool isConst, bool isEmpty});

  void registerStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency import);

  void registerStaticGet(ir.Member member, ir.LibraryDependency import);

  void registerStaticSet(ir.Member member, ir.LibraryDependency import);

  void registerAssert({bool withMessage});

  void registerGenericInstantiation(
      ir.FunctionType expressionType, List<ir.DartType> typeArguments);

  void registerSyncStar(ir.DartType elementType);

  void registerAsync(ir.DartType elementType);

  void registerAsyncStar(ir.DartType elementType);

  void registerStringConcatenation();

  void registerLocalFunction(ir.TreeNode node);

  void registerLocalWithoutInitializer();

  void registerIsCheck(ir.DartType type);

  void registerImplicitCast(ir.DartType type);

  void registerAsCast(ir.DartType type);

  void registerThrow();

  void registerSyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation);

  void registerAsyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation);

  void registerCatch();

  void registerStackTrace();

  void registerCatchType(ir.DartType type);

  void registerTypeLiteral(ir.DartType type, ir.LibraryDependency import);

  void registerFieldInitialization(ir.Field node);

  void registerFieldConstantInitialization(
      ir.Field node, ConstantReference constant);

  void registerLoadLibrary();

  void registerRedirectingInitializer(
      ir.Constructor constructor,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerParameterCheck(ir.DartType type);

  void registerLazyField();

  void registerNew(
      ir.Member constructor,
      ir.InterfaceType type,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import,
      {bool isConst});

  void registerConstInstantiation(ir.Class cls, List<ir.DartType> typeArguments,
      ir.LibraryDependency import);

  void registerStaticInvocation(
      ir.Procedure target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency import);

  void registerLocalFunctionInvocation(
      ir.FunctionDeclaration localFunction,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerDynamicInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Name name,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerInstanceInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Member target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerFunctionInvocation(
      ir.DartType receiverType,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  void registerDynamicGet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name);

  void registerInstanceGet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target);

  void registerDynamicSet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name);

  void registerInstanceSet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target);

  void registerSuperInvocation(ir.Member target, int positionalArguments,
      List<String> namedArguments, List<ir.DartType> typeArguments);

  void registerSuperGet(ir.Member target);

  void registerSuperSet(ir.Member target);

  void registerSuperInitializer(
      ir.Constructor source,
      ir.Constructor target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments);

  // TODO(johnniwinther): Change [node] to `InstanceGet` when the old method
  // invocation encoding is no longer used.
  void registerRuntimeTypeUse(ir.Expression node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType argumentType);

  // TODO(johnniwinther): Remove these when CFE provides constants.
  void registerConstructorNode(ir.Constructor node);
  void registerFieldNode(ir.Field node);
  void registerProcedureNode(ir.Procedure node);
  void registerStaticInvocationNode(ir.StaticInvocation node);
  void registerSwitchStatementNode(ir.SwitchStatement node);
  void registerConstConstructorInvocationNode(ir.ConstructorInvocation node);
}

class ImpactBuilderData {
  static const String tag = 'ImpactBuilderData';

  final ir.Member node;
  final ImpactData impactData;
  final Map<ir.Expression, TypeMap> typeMapsForTesting;
  final StaticTypeCache cachedStaticTypes;

  ImpactBuilderData(this.node, this.impactData, this.typeMapsForTesting,
      this.cachedStaticTypes);

  factory ImpactBuilderData.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    var node = source.readMemberNode();
    var data = ImpactData.fromDataSource(source);
    var cache = StaticTypeCache.readFromDataSource(source, node);
    source.end(tag);
    return ImpactBuilderData(node, data, const {}, cache);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(node);
    impactData.toDataSink(sink);
    cachedStaticTypes.writeToDataSink(sink, node);
    sink.end(tag);
  }
}

class ConstantImpactVisitor extends ir.VisitOnceConstantVisitor {
  final ImpactRegistry registry;
  final ir.LibraryDependency import;
  final ir.ConstantExpression expression;
  final ir.StaticTypeContext staticTypeContext;

  ConstantImpactVisitor(
      this.registry, this.import, this.expression, this.staticTypeContext);

  @override
  void defaultConstant(ir.Constant node) {
    throw UnsupportedError(
        "Unexpected constant ${node} (${node.runtimeType}).");
  }

  @override
  void visitUnevaluatedConstant(ir.UnevaluatedConstant node) {
    // Do nothing. This occurs when the constant couldn't be evaluated because
    // of a compile-time error.
  }

  @override
  void visitTypeLiteralConstant(ir.TypeLiteralConstant node) {
    registry.registerTypeLiteral(node.type, import);
  }

  @override
  void visitStaticTearOffConstant(ir.StaticTearOffConstant node) {
    registry.registerStaticTearOff(node.target, import);
  }

  @override
  void visitInstantiationConstant(ir.InstantiationConstant node) {
    registry.registerGenericInstantiation(
        node.tearOffConstant.getType(staticTypeContext), node.types);
    visitConstant(node.tearOffConstant);
  }

  @override
  void visitTypedefTearOffConstant(ir.TypedefTearOffConstant node) {
    defaultConstant(node);
  }

  @override
  void visitInstanceConstant(ir.InstanceConstant node) {
    registry.registerConstInstantiation(
        node.classNode, node.typeArguments, import);
    node.fieldValues.forEach((ir.Reference reference, ir.Constant value) {
      ir.Field field = reference.asField;
      registry.registerFieldConstantInitialization(
          field, ConstantReference(expression, value));
      visitConstant(value);
    });
  }

  @override
  void visitSetConstant(ir.SetConstant node) {
    registry.registerSetLiteral(node.typeArgument,
        isConst: true, isEmpty: node.entries.isEmpty);
    for (ir.Constant element in node.entries) {
      visitConstant(element);
    }
  }

  @override
  void visitListConstant(ir.ListConstant node) {
    registry.registerListLiteral(node.typeArgument,
        isConst: true, isEmpty: node.entries.isEmpty);
    for (ir.Constant element in node.entries) {
      visitConstant(element);
    }
  }

  @override
  void visitMapConstant(ir.MapConstant node) {
    registry.registerMapLiteral(node.keyType, node.valueType,
        isConst: true, isEmpty: node.entries.isEmpty);
    for (ir.ConstantMapEntry entry in node.entries) {
      visitConstant(entry.key);
      visitConstant(entry.value);
    }
  }

  @override
  void visitSymbolConstant(ir.SymbolConstant node) {
    // TODO(johnniwinther): Handle the library reference.
    registry.registerSymbolLiteral(node.name);
  }

  @override
  void visitStringConstant(ir.StringConstant node) {
    registry.registerStringLiteral(node.value);
  }

  @override
  void visitDoubleConstant(ir.DoubleConstant node) {
    registry.registerDoubleLiteral(node.value);
  }

  @override
  void visitIntConstant(ir.IntConstant node) {
    registry.registerIntLiteral(node.value);
  }

  @override
  void visitBoolConstant(ir.BoolConstant node) {
    registry.registerBoolLiteral(node.value);
  }

  @override
  void visitNullConstant(ir.NullConstant node) {
    registry.registerNullLiteral();
  }

  @override
  void visitConstructorTearOffConstant(ir.ConstructorTearOffConstant node) {
    // The CFE encoding of redirecting factories, which dart2js doesn't use,
    // uses ConstructorTearOff(Constant) to point to its effective target.
    // However, these should be safe to ignore.
  }
}
