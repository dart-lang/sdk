// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'tables.dart';

/// A table defined in a module.
class TableBuilder extends ir.Table with Builder<ir.DefinedTable> {
  final List<ir.BaseFunction?> elements;

  TableBuilder(super.index, super.type, super.minSize, super.maxSize)
      : elements = List.filled(minSize, null);

  void setElement(int index, ir.BaseFunction function) {
    assert(type == ir.RefType.func(nullable: true),
        "Elements are only supported for funcref tables");
    elements[index] = function;
  }

  @override
  ir.DefinedTable forceBuild() =>
      ir.DefinedTable(elements, index, type, minSize, maxSize);
}
