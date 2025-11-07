// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A table defined in a module.
class TableBuilder extends ir.Table with IndexableBuilder<ir.DefinedTable> {
  final ModuleBuilder moduleBuilder;

  TableBuilder(this.moduleBuilder, ir.FinalizableIndex index, ir.RefType type,
      int minSize, int? maxSize)
      : super(moduleBuilder.module, index, type, minSize, maxSize);

  @override
  ir.DefinedTable forceBuild() => ir.DefinedTable(
      enclosingModule, finalizableIndex, type, minSize, maxSize);
}
