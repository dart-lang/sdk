// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

part 'table.dart';

/// The interface for the tables in a module.
class TablesBuilder with Builder<ir.Tables> {
  final ModuleBuilder _module;
  final _tableBuilders = <TableBuilder>[];
  final _importedTables = <ir.ImportedTable>[];

  TablesBuilder(this._module);

  /// Defines a new table in this module.
  TableBuilder define(ir.RefType type, int minSize, [int? maxSize]) {
    final table =
        TableBuilder(_module, ir.FinalizableIndex(), type, minSize, maxSize);
    _tableBuilders.add(table);
    return table;
  }

  /// Imports a table into this module.
  ir.ImportedTable import(
      String module, String name, ir.RefType type, int minSize,
      [int? maxSize]) {
    final table = ir.ImportedTable(
        _module, module, name, ir.FinalizableIndex(), type, minSize, maxSize);
    _importedTables.add(table);
    return table;
  }

  @override
  ir.Tables forceBuild() {
    final built = finalizeImportsAndBuilders<ir.DefinedTable>(
        _importedTables, _tableBuilders);
    return ir.Tables(_importedTables, built);
  }

  void collectUsedTypes(Set<ir.DefType> types) {
    for (final table in _tableBuilders) {
      final defType = table.type.containedDefType;
      if (defType != null) types.add(defType);
    }
    for (final table in _importedTables) {
      final defType = table.type.containedDefType;
      if (defType != null) types.add(defType);
    }
  }
}
