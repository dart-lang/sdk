// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'static_type_provider.dart';

/// Class that provides the static type of expression using the visitor pattern
/// and a precomputed cache for complex expression type.
class CachedStaticType implements StaticTypeProvider {
  final ir.StaticTypeCache _cache;

  final ir.StaticTypeContext staticTypeContext;

  CachedStaticType(this.staticTypeContext) : _cache = ir.StaticTypeCacheImpl();

  @override
  ir.DartType getStaticType(ir.Expression node) =>
      _cache.getExpressionType(node, staticTypeContext);

  @override
  ir.DartType getForInIteratorType(ir.ForInStatement node) =>
      _cache.getForInIteratorType(node, staticTypeContext);
}
