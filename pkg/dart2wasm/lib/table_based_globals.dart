// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

class TableBasedGlobals {
  final Translator translator;

  final Map<w.HeapType, TypeSpecificGlobalTable> _tables = {};

  TableBasedGlobals(this.translator);

  TypeSpecificGlobalTable getTableForType(w.HeapType type) {
    return _tables[type] ??= TypeSpecificGlobalTable(
        translator, type, 'global-table-${_tables.length}');
  }

  void outputTables() {
    for (final table in _tables.values) {
      table.output();
    }
  }
}

class TypeSpecificGlobalTable {
  final Translator translator;
  final w.HeapType _tableHeapType;

  /// Contents of wasm table.
  final Map<Object, (int, w.InstructionsBuilder?)> _table = {};

  late final w.TableBuilder _definedWasmTable = translator.mainModule.tables
      .define(w.RefType(_tableHeapType, nullable: true), _table.length);
  final WasmTableImporter _importedWasmTables;

  TypeSpecificGlobalTable(
      this.translator, this._tableHeapType, String tableName)
      : _importedWasmTables = WasmTableImporter(translator, tableName) {
    assert(_tableHeapType.isStructuralSubtypeOf(w.HeapType.any));
  }

  w.RefType get type => w.RefType(_tableHeapType, nullable: true);

  /// Gets the wasm table used to reference this table in [module].
  ///
  /// This can either be the table definition itself or an import of it. Imports
  /// the table into [module] if it is not imported yet.
  w.Table getWasmTable(w.ModuleBuilder module) {
    return _importedWasmTables.get(_definedWasmTable, module);
  }

  /// Returns the index for [function] in the table allocating one if necessary.
  int indexForObject(Object object,
      [w.ModuleBuilder? initModule,
      void Function(w.InstructionsBuilder)? init]) {
    assert((initModule != null) == (init != null));
    final existing = _table[object];
    if (existing != null) return existing.$1;

    w.InstructionsBuilder? expression;
    if (initModule != null) {
      expression = w.InstructionsBuilder(
          initModule, [], [w.RefType(_tableHeapType, nullable: false)],
          constantExpression: true);
      init!(expression);
    }

    return (_table[object] = (_table.length, expression)).$1;
  }

  void output() {
    final importedTables = _importedWasmTables;
    _table.forEach((fun, tuple) {
      final (index, expression) = tuple;
      if (expression != null) {
        final moduleBuilder = expression.moduleBuilder;
        if (translator.isMainModule(moduleBuilder)) {
          _definedWasmTable.moduleBuilder.elements
              .activeExpressionSegmentBuilderFor(_definedWasmTable)
              .setExpressionAt(index, expression);
        } else {
          // This will generate the imported table if it doesn't already exist.
          final importedTable = getWasmTable(moduleBuilder) as w.ImportedTable;
          moduleBuilder.elements
              .activeExpressionSegmentBuilderFor(importedTable)
              .setExpressionAt(index, expression);
        }
      }
    });

    _definedWasmTable.minSize = _table.length;
    for (final table in importedTables.imports) {
      table.minSize = _table.length;
    }
  }
}
