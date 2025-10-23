// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import '../serialize/printer.dart';
import 'ir.dart';

/// An (imported or defined) table.
class Table with Indexable, Exportable implements Serializable {
  @override
  final FinalizableIndex finalizableIndex;
  final RefType type;
  // Mutable so that a table's size does not need to be known prior to the table
  // being instantiated.
  int minSize;
  final int? maxSize;
  @override
  final Module enclosingModule;

  Table(this.enclosingModule, this.finalizableIndex, this.type, this.minSize,
      this.maxSize);

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
  Export buildExport(String name) => TableExport(name, this);
}

/// A table defined in a module.
class DefinedTable extends Table {
  final List<BaseFunction?> elements;

  DefinedTable(super.enclosingModule, this.elements, super.finalizableIndex,
      super.type, super.minSize, super.maxSize);

  void printTo(IrPrinter p, {bool includeElements = true}) {
    // NOTE: This format differs from what V8's `wami` will print.
    // It makes it easier to see the exact values of the table.
    p.write('(table ');
    p.writeTableReference(this, alwaysPrint: true);
    String? exportName;
    for (final e in enclosingModule.exports.exported) {
      if (e is TableExport && e.table == this) {
        exportName = e.name;
        break;
      }
    }
    if (exportName != null) {
      p.write(' ');
      p.writeExport(exportName);
    }

    p.write(' $minSize ');
    p.writeValueType(type);
    if (includeElements) {
      if (elements.any((e) => e != null)) {
        p.writeln();
        p.withIndent(() {
          for (int i = 0; i < elements.length; ++i) {
            final function = elements[i];
            if (function != null) {
              p.write('(def $i ');
              p.writeFunctionReference(function);
              p.writeln(')');
            }
          }
        });
      }
    } else {
      p.write(' <...>');
    }
    p.write(')');
  }
}

/// An imported table.
class ImportedTable extends Table implements Import {
  @override
  final String module;
  @override
  final String name;

  /// Functions to be inserted via the elements section.
  final Map<int, BaseFunction> setElements = {};

  ImportedTable(super.enclosingModule, this.module, this.name,
      super.finalizableIndex, super.type, super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x01);
    super.serialize(s);
  }

  void printTo(IrPrinter p, {bool includeElements = true}) {
    // NOTE: This format differs from what V8's `wami` will print.
    // It makes it easier to see the exact values of the table.
    p.write('(table ');
    p.writeTableReference(this, alwaysPrint: true);
    p.write(' ');
    p.writeImport(module, name);
    p.write(' $minSize ');
    p.writeValueType(type);
    if (includeElements) {
      if (setElements.isNotEmpty) {
        p.writeln();
        p.withIndent(() {
          setElements.forEach((int i, function) {
            p.write('(set $i ');
            p.writeFunctionReference(function);
            p.writeln(')');
          });
        });
      }
    } else {
      p.write(' <...>');
    }
    p.write(')');
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
