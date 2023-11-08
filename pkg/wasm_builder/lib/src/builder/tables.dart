// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

part 'table.dart';

/// The interface for the tables in a module.
class TablesBuilder with Builder<ir.Tables> {
  final _tableBuilders = <TableBuilder>[];
  final _importedTables = <ir.Import>[];

  /// Defines a new table in this module.
  TableBuilder define(ir.RefType type, int minSize, [int? maxSize]) {
    final table = TableBuilder(ir.FinalizableIndex(), type, minSize, maxSize);
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
    final table = ir.ImportedTable(
        module, name, ir.FinalizableIndex(), type, minSize, maxSize);
    _importedTables.add(table);
    return table;
  }

  @override
  ir.Tables forceBuild() {
    final built = finalizeImportsAndBuilders<ir.DefinedTable>(
        _importedTables, _tableBuilders);
    return ir.Tables(_importedTables, built);
  }
}
