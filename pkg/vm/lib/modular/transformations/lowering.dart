// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;

import '../specializer/factory_specializer.dart';
import 'for_in_lowering.dart' show ForInLowering;
import 'late_var_init_transformer.dart' show LateVarInitTransformer;
import 'list_literals_lowering.dart' show ListLiteralsLowering;
import 'type_casts_optimizer.dart'
    as typeCastsOptimizer
    show transformAsExpression;

/// VM-specific lowering transformations and optimizations combined into a
/// single transformation pass.
///
/// Each transformation is applied locally to AST nodes of certain types
/// after transforming children nodes.
void transformLibraries(
  List<Library> libraries,
  CoreTypes coreTypes,
  ClassHierarchy hierarchy, {
  required bool productMode,
  required bool isClosureContextLoweringEnabled,
}) {
  final transformer = _Lowering(
    coreTypes,
    hierarchy,
    productMode: productMode,
    isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
  );
  libraries.forEach(transformer.visitLibrary);
}

void transformProcedure(
  Procedure procedure,
  CoreTypes coreTypes,
  ClassHierarchy hierarchy, {
  required bool productMode,
  required bool isClosureContextLoweringEnabled,
}) {
  final transformer = _Lowering(
    coreTypes,
    hierarchy,
    productMode: productMode,
    isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
  );
  procedure.accept(transformer);
}

class _Lowering extends Transformer {
  final TypeEnvironment env;
  final LateVarInitTransformer lateVarInitTransformer;
  final FactorySpecializer factorySpecializer;
  final ListLiteralsLowering listLiteralsLowering;
  final ForInLowering forInLowering;

  Member? _currentMember;
  FunctionNode? _currentFunctionNode;
  StaticTypeContext? _cachedStaticTypeContext;
  LocalFunctionIdGenerator? _localFunctionIdGenerator;
  LocalFunctionIdGenerator? _constructorFunctionIdGenerator;

  _Lowering(
    CoreTypes coreTypes,
    ClassHierarchy hierarchy, {
    required bool productMode,
    required bool isClosureContextLoweringEnabled,
  }) : env = TypeEnvironment(coreTypes, hierarchy),
       lateVarInitTransformer = LateVarInitTransformer(),
       factorySpecializer = FactorySpecializer(coreTypes),
       listLiteralsLowering = ListLiteralsLowering(coreTypes),
       forInLowering = ForInLowering(
         coreTypes,
         productMode: productMode,
         isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
       );

  StaticTypeContext get _staticTypeContext =>
      _cachedStaticTypeContext ??= StaticTypeContext(_currentMember!, env);

  LocalFunctionIdGenerator get _currentLocalFunctionIdGenerator =>
      _localFunctionIdGenerator ??= LocalFunctionIdGenerator();

  @override
  visitClass(Class node) {
    _constructorFunctionIdGenerator = LocalFunctionIdGenerator();
    final result = super.visitClass(node);
    _constructorFunctionIdGenerator = null;
    return result;
  }

  @override
  defaultMember(Member node) {
    if (node is Procedure && node.isRedirectingFactory) {
      // Keep bodies of redirecting factories unchanged because
      // front-end expects them to have a certain shape.
      return node;
    }

    _currentMember = node;
    _cachedStaticTypeContext = null;

    // Share the same ID generator for constructors and instance fields
    // as VM includes instance field initializers into constructors.
    if (node is Constructor || (node is Field && node.isInstanceMember)) {
      _localFunctionIdGenerator = _constructorFunctionIdGenerator;
    }

    final result = super.defaultMember(node);

    _currentMember = null;
    _cachedStaticTypeContext = null;
    _localFunctionIdGenerator = null;
    return result;
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    node.id = _currentLocalFunctionIdGenerator.allocateId();
    return super.visitFunctionExpression(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    node.id = _currentLocalFunctionIdGenerator.allocateId();
    return super.visitFunctionDeclaration(node);
  }

  @override
  visitFunctionNode(FunctionNode node) {
    final savedFunctionNode = _currentFunctionNode;
    _currentFunctionNode = node;

    final result = super.visitFunctionNode(node);

    _currentFunctionNode = savedFunctionNode;
    return result;
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    return factorySpecializer.transformStaticInvocation(node);
  }

  @override
  visitAsExpression(AsExpression node) {
    node.transformChildren(this);
    return typeCastsOptimizer.transformAsExpression(node, _staticTypeContext);
  }

  @override
  visitBlock(Block node) {
    node.transformChildren(this);
    return lateVarInitTransformer.transformBlock(
      node,
      _currentLocalFunctionIdGenerator,
    );
  }

  @override
  visitAssertBlock(AssertBlock node) {
    node.transformChildren(this);
    return lateVarInitTransformer.transformAssertBlock(
      node,
      _currentLocalFunctionIdGenerator,
    );
  }

  @override
  visitListLiteral(ListLiteral node) {
    node.transformChildren(this);
    return listLiteralsLowering.transformListLiteral(node);
  }

  @override
  visitForInStatement(ForInStatement node) {
    node.transformChildren(this);
    return forInLowering.transformForInStatement(
      node,
      _currentFunctionNode,
      _staticTypeContext,
    );
  }

  @override
  visitFunctionTearOff(FunctionTearOff node) {
    node.transformChildren(this);
    return node.receiver;
  }
}
