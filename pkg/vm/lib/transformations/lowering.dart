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
import 'package:vm/transformations/map_factory_specializer.dart';

import 'late_var_init_transformer.dart' show LateVarInitTransformer;
import 'list_factory_specializer.dart' show ListFactorySpecializer;

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

typedef SpecializerTransformer<T extends TreeNode> = TreeNode Function(T node);

/// Combine Two Specializer Transformer Method.
SpecializerTransformer<T> combine<T extends TreeNode>(
    SpecializerTransformer<T> a,
    SpecializerTransformer<T> b,
) {
  return (node) => b(a(node));
}

/// Combine a list of Specializer Transformer Method.
SpecializerTransformer<T> combineSpecializer<T extends TreeNode>(
  List<SpecializerTransformer<T>> transformers,
) {
  return transformers.fold(
    (node) => node,
    (previousValue, element) => combine(previousValue, element),
  );
}

class _Lowering extends Transformer {
  final TypeEnvironment env;
  final bool nullSafety;
  final ListFactorySpecializer listFactorySpecializer;
  final MapFactorySpecializer mapFactorySpecializer;
  final LateVarInitTransformer lateVarInitTransformer;

  Member _currentMember;
  StaticTypeContext _cachedStaticTypeContext;

  _Lowering(CoreTypes coreTypes, ClassHierarchy hierarchy, this.nullSafety)
      : env = TypeEnvironment(coreTypes, hierarchy),
        listFactorySpecializer = ListFactorySpecializer(coreTypes),
        mapFactorySpecializer = MapFactorySpecializer(coreTypes),
        lateVarInitTransformer = LateVarInitTransformer();

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
    return combineSpecializer([
      listFactorySpecializer.transformStaticInvocation,
      mapFactorySpecializer.transformStaticInvocation,
    ])(node);
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
