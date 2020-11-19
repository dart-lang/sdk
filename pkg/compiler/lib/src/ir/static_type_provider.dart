// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

/// Interface for accessing static types on expressions.
abstract class StaticTypeProvider {
  ir.DartType getStaticType(ir.Expression node);
  ir.DartType getForInIteratorType(ir.ForInStatement node);
}
