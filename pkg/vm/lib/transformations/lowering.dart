// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;

import 'package:vm/transformations/specializer/factory_specializer.dart';

import 'for_in_lowering.dart' show ForInLowering;
import 'late_var_init_transformer.dart' show LateVarInitTransformer;
import 'list_literals_lowering.dart' show ListLiteralsLowering;
import 'type_casts_optimizer.dart' as typeCastsOptimizer
    show transformAsExpression;

/// VM-specific lowering transformations and optimizations combined into a
/// single transformation pass.
///
/// Each transformation is applied locally to AST nodes of certain types
/// after transforming children nodes.
void transformLibraries(
    List<Library> libraries, CoreTypes coreTypes, ClassHierarchy hierarchy,
    {required bool soundNullSafety, required bool productMode}) {
  final transformer = _Lowering(coreTypes, hierarchy,
      soundNullSafety: soundNullSafety, productMode: productMode);
  libraries.forEach(transformer.visitLibrary);
}

void transformProcedure(
    Procedure procedure, CoreTypes coreTypes, ClassHierarchy hierarchy,
    {required bool soundNullSafety, required bool productMode}) {
  final transformer = _Lowering(coreTypes, hierarchy,
      soundNullSafety: soundNullSafety, productMode: productMode);
  procedure.accept(transformer);
}

class _Lowering extends Transformer {
  final TypeEnvironment env;
  final bool soundNullSafety;
  final LateVarInitTransformer lateVarInitTransformer;
  final FactorySpecializer factorySpecializer;
  final ListLiteralsLowering listLiteralsLowering;
  final ForInLowering forInLowering;

  Member? _currentMember;
  FunctionNode? _currentFunctionNode;
  StaticTypeContext? _cachedStaticTypeContext;

  _Lowering(CoreTypes coreTypes, ClassHierarchy hierarchy,
      {required this.soundNullSafety, required bool productMode})
      : env = TypeEnvironment(coreTypes, hierarchy),
        lateVarInitTransformer = LateVarInitTransformer(),
        factorySpecializer = FactorySpecializer(coreTypes),
        listLiteralsLowering = ListLiteralsLowering(coreTypes),
        forInLowering = ForInLowering(coreTypes, productMode: productMode);

  StaticTypeContext get _staticTypeContext =>
      _cachedStaticTypeContext ??= StaticTypeContext(_currentMember!, env);

  @override
  defaultMember(Member node) {
    if (node is Procedure && node.isRedirectingFactory) {
      // Keep bodies of redirecting factories unchanged because
      // front-end expects them to have a certain shape.
      return node;
    }

    _currentMember = node;
    _cachedStaticTypeContext = null;

    final result = super.defaultMember(node);

    _currentMember = null;
    _cachedStaticTypeContext = null;
    return result;
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
    return typeCastsOptimizer.transformAsExpression(
        node, _staticTypeContext, soundNullSafety);
  }

  @override
  visitBlock(Block node) {
    node.transformChildren(this);
    return lateVarInitTransformer.transformBlock(node);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    node.transformChildren(this);
    return lateVarInitTransformer.transformAssertBlock(node);
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
        node, _currentFunctionNode, _staticTypeContext);
  }

  @override
  visitFunctionTearOff(FunctionTearOff node) {
    node.transformChildren(this);
    return node.receiver;
  }
}
