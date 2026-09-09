// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

/// The interface for the tables in a module.
class TablesBuilder with Builder<ir.Tables> {
  final ir.Module _module;
  final _definedTables = <ir.DefinedTable>[];
  final _importedTables = <ir.ImportedTable>[];

  TablesBuilder(this._module);

  List<ir.DefinedTable> get defined => _definedTables;

  /// Defines a new table in this module.
  ir.DefinedTable define(ir.RefType type, int minSize, [int? maxSize]) {
    final table = ir.DefinedTable(
      _module,
      ir.FinalizableIndex(),
      type,
      minSize,
      maxSize,
    );
    _definedTables.add(table);
    return table;
  }

  /// Imports a table into this module.
  ir.ImportedTable import(
    String module,
    String name,
    ir.RefType type,
    int minSize, [
    int? maxSize,
  ]) {
    final table = ir.ImportedTable(
      _module,
      module,
      name,
      ir.FinalizableIndex(),
      type,
      minSize,
      maxSize,
    );
    _importedTables.add(table);
    return table;
  }

  @override
  ir.Tables forceBuild() {
    finalizeImportsAndDefinitions(_importedTables, _definedTables);
    return ir.Tables(_importedTables, _definedTables);
  }
}
