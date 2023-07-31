// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'tables.dart';

/// An (imported or defined) table.
class Table implements Exportable, Serializable {
  final int index;
  final RefType type;
  final int minSize;
  final int? maxSize;

  Table(this.index, this.type, this.minSize, this.maxSize);

  @override
  void serialize(Serializer s) {
    s.write(type);
    if (maxSize == null) {
      s.writeByte(0x00);
      s.writeUnsigned(minSize);
    } else {
      s.writeByte(0x01);
      s.writeUnsigned(minSize);
      s.writeUnsigned(maxSize!);
    }
  }

  /// Export a table from the module.
  @override
  Export export(String name) => TableExport(name, this);
}

/// A table defined in a module.
class DefinedTable extends Table {
  final List<BaseFunction?> elements;

  DefinedTable(
      this.elements, super.index, super.type, super.minSize, super.maxSize);
}

/// An imported table.
class ImportedTable extends Table implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedTable(this.module, this.name, super.index, super.type, super.minSize,
      super.maxSize);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x01);
    super.serialize(s);
  }
}

class TableExport extends Export {
  final Table table;

  TableExport(super.name, this.table);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x01);
    s.writeUnsigned(table.index);
  }
}
