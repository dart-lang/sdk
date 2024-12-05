// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'tables.dart';

/// A table defined in a module.
class TableBuilder extends ir.Table with IndexableBuilder<ir.DefinedTable> {
  final List<ir.BaseFunction?> elements;

  TableBuilder(super.enclosingModule, super.index, super.type, super.minSize,
      super.maxSize)
      : elements = List.filled(minSize, null, growable: true);

  void setElement(int index, ir.BaseFunction function) {
    assert(type.isSubtypeOf(ir.RefType.func(nullable: true)),
        "Elements are only supported for funcref tables");
    assert(maxSize == null || index < maxSize!,
        'Index $index greater than max table size $maxSize');
    if (index >= elements.length) {
      elements.length = index + 1;
    }
    elements[index] = function;
  }

  @override
  ir.DefinedTable forceBuild() => ir.DefinedTable(
      enclosingModule, elements, finalizableIndex, type, minSize, maxSize);
}
