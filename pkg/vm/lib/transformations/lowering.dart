// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/transformations/type_casts_optimizer.dart'
    as typeCastsOptimizer show transformAsExpression;
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;
import 'package:vm/transformations/specializer/factory_specializer.dart';
import 'late_var_init_transformer.dart' show LateVarInitTransformer;

/// VM-specific lowering transformations and optimizations combined into a
/// single transformation pass.
///
/// Each transformation is applied locally to AST nodes of certain types
/// after transforming children nodes.
void transformLibraries(List<Library> libraries, CoreTypes coreTypes,
    ClassHierarchy hierarchy, bool nullSafety) {
  final transformer = _Lowering(coreTypes, hierarchy, nullSafety);
  libraries.forEach(transformer.visitLibrary);
}

class _Lowering extends Transformer {
  final TypeEnvironment env;
  final bool nullSafety;
  final LateVarInitTransformer lateVarInitTransformer;
  final FactorySpecializer factorySpecializer;

  Member _currentMember;
  StaticTypeContext _cachedStaticTypeContext;

  _Lowering(CoreTypes coreTypes, ClassHierarchy hierarchy, this.nullSafety)
      : env = TypeEnvironment(coreTypes, hierarchy),
        lateVarInitTransformer = LateVarInitTransformer(),
        factorySpecializer = FactorySpecializer(coreTypes);

  StaticTypeContext get _staticTypeContext =>
      _cachedStaticTypeContext ??= StaticTypeContext(_currentMember, env);

  @override
  defaultMember(Member node) {
    _currentMember = node;
    _cachedStaticTypeContext = null;

    final result = super.defaultMember(node);

    _currentMember = null;
    _cachedStaticTypeContext = null;
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
        node, _staticTypeContext, nullSafety);
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
}
