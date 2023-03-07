// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

/// Interface for accessing static types on expressions.
abstract class StaticTypeProvider {
  ir.DartType getStaticType(ir.Expression node);
  ir.DartType getForInIteratorType(ir.ForInStatement node);
}

/// A static type provider for a context with no Kernel nodes.
// TODO(51310): Refactor so that a StaticTypeProvider is not required for
// synthetic elements.
class NoStaticTypeProvider implements StaticTypeProvider {
  @override
  ir.DartType getStaticType(ir.Expression node) {
    throw UnsupportedError('NoStaticTypeProvider.getStaticType');
  }

  @override
  ir.DartType getForInIteratorType(ir.ForInStatement node) {
    throw UnsupportedError('NoStaticTypeProvider.getForInIteratorType');
  }
}
