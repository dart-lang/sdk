// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

/// Builds a table of functions that can be used across modules.
class CrossModuleFunctionTable {
  static const w.HeapType _tableHeapType = w.HeapType.func;

  final Translator translator;

  /// Contents of wasm table.
  final Map<w.BaseFunction, int> _table = {};

  late final w.TableBuilder _definedWasmTable = translator.mainModule.tables
      .define(w.RefType(_tableHeapType, nullable: true), _table.length);
  final WasmTableImporter _importedWasmTables;

  CrossModuleFunctionTable(this.translator)
      : _importedWasmTables =
            WasmTableImporter(translator, 'cross-module-funcs-');

  /// Gets the wasm table used to reference this table in [module].
  ///
  /// This can either be the table definition itself or an import of it. Imports
  /// the table into [module] if it is not imported yet.
  w.Table getWasmTable(w.ModuleBuilder module) {
    return _importedWasmTables.get(_definedWasmTable, module);
  }

  /// Returns the index for [function] in the table allocating one if necessary.
  int indexForFunction(w.BaseFunction function) {
    assert(function.type.isStructuralSubtypeOf(_tableHeapType));
    return _table[function] ??= _table.length;
  }

  void output() {
    final importedTables = _importedWasmTables;
    _table.forEach((fun, index) {
      final targetModule = translator.moduleToBuilder[fun.enclosingModule]!;
      if (translator.isMainModule(targetModule)) {
        _definedWasmTable.moduleBuilder.elements
            .activeFunctionSegmentBuilderFor(_definedWasmTable)
            .setFunctionAt(index, fun);
      } else {
        // This will generate the imported table if it doesn't already exist.
        final importedTable = getWasmTable(targetModule) as w.ImportedTable;
        targetModule.elements
            .activeFunctionSegmentBuilderFor(importedTable)
            .setFunctionAt(index, fun);
      }
    });

    _definedWasmTable.minSize = _table.length;
    for (final table in importedTables.imports) {
      table.minSize = _table.length;
    }
  }
}
