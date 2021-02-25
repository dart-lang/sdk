// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'static_type_base.dart';
import 'static_type_cache.dart';
import 'static_type_provider.dart';

/// Class that provides the static type of expression using the visitor pattern
/// and a precomputed cache for complex expression type.
class CachedStaticType extends StaticTypeBase implements StaticTypeProvider {
  final StaticTypeCache _cache;

  @override
  final ir.StaticTypeContext staticTypeContext;

  @override
  final ThisInterfaceType thisType;

  CachedStaticType(this.staticTypeContext, this._cache, this.thisType)
      : super(staticTypeContext.typeEnvironment);

  @override
  ir.DartType getStaticType(ir.Expression node) {
    ir.DartType type = node.accept(this);
    assert(type != null, "No static type found for ${node.runtimeType}.");
    return type;
  }

  @override
  ir.DartType getForInIteratorType(ir.ForInStatement node) {
    ir.DartType type = _cache.getForInIteratorType(node);
    assert(type != null, "No for-in iterator type found for ${node}.");
    return type;
  }

  ir.DartType _getStaticType(ir.Expression node) {
    ir.DartType type = _cache[node];
    assert(type != null, "No static type cached for ${node.runtimeType}.");
    return type;
  }

  @override
  ir.DartType visitVariableGet(ir.VariableGet node) => _getStaticType(node);

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) => _getStaticType(node);

  @override
  ir.DartType visitSuperPropertyGet(ir.SuperPropertyGet node) =>
      _getStaticType(node);

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) =>
      _getStaticType(node);

  @override
  ir.DartType visitStaticInvocation(ir.StaticInvocation node) =>
      _getStaticType(node);

  @override
  ir.DartType visitSuperMethodInvocation(ir.SuperMethodInvocation node) =>
      _getStaticType(node);

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) =>
      _getStaticType(node);

  @override
  ir.DartType visitInstantiation(ir.Instantiation node) => _getStaticType(node);

  @override
  ir.DartType visitNullCheck(ir.NullCheck node) => _getStaticType(node);
}
