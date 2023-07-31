// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

part 'table.dart';

/// The interface for the tables in a module.
class TablesBuilder with Builder<ir.Tables> {
  final _tableBuilders = <TableBuilder>[];
  final _importedTables = <ir.Import>[];
  bool _anyTablesDefined = false;

  /// This is guarded by [_anyTableDefined].
  int get _index => _importedTables.length + _tableBuilders.length;

  /// Defines a new table in this module.
  TableBuilder define(ir.RefType type, int minSize, [int? maxSize]) {
    _anyTablesDefined = true;
    final table = TableBuilder(_index, type, minSize, maxSize);
    _tableBuilders.add(table);
    return table;
  }

  /// Imports a table into this module.
  ///
  /// All imported tables must be specified before any tables are declared
  /// using [Tables.define].
  ir.ImportedTable import(
      String module, String name, ir.RefType type, int minSize,
      [int? maxSize]) {
    if (_anyTablesDefined) {
      throw "All table imports must be specified before any definitions.";
    }
    final table =
        ir.ImportedTable(module, name, _index, type, minSize, maxSize);
    _importedTables.add(table);
    return table;
  }

  @override
  ir.Tables forceBuild() =>
      ir.Tables(_importedTables, _tableBuilders.map((t) => t.build()).toList());
}
