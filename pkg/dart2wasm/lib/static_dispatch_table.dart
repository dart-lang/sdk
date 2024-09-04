// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

class StaticDispatchTables {
  final Translator translator;

  final Map<w.FunctionType, StaticDispatchTableForSignature> _tables =
      LinkedHashMap(
          hashCode: (t) =>
              Object.hash(Object.hashAll(t.inputs), Object.hashAll(t.outputs)),
          equals: (t1, t2) => t1.isStructurallyEqualTo(t2));

  StaticDispatchTables(this.translator);

  StaticDispatchTableForSignature getTableForType(w.FunctionType type) {
    return _tables[type] ??=
        StaticDispatchTableForSignature(translator, type, _tables.length);
  }

  void outputTables() {
    for (final table in _tables.values) {
      table.output();
    }
  }
}

/// Builds a static dispatch table for a specific function type signature.
///
/// All calls to this table will have the same signature and so `call_indirect`
/// instructions that reference this table can omit the type check.
class StaticDispatchTableForSignature {
  final w.FunctionType _functionType;

  final Translator translator;

  /// Contents of wasm table.
  final Map<w.BaseFunction, int> _table = {};

  late final w.TableBuilder _definedWasmTable;
  final WasmTableImporter _importedWasmTables;

  StaticDispatchTableForSignature(
      this.translator, this._functionType, int nameCounter)
      : _importedWasmTables =
            WasmTableImporter(translator, 'static$nameCounter-') {
    _definedWasmTable = translator.mainModule.tables
        .define(w.RefType(_functionType, nullable: true), _table.length);
  }

  /// Gets the wasm table used to reference this static dispatch table in
  /// [module].
  ///
  /// This can either be the table definition itself or an import of it. Imports
  /// the table into [module] if it is not imported yet.
  w.Table getWasmTable(w.ModuleBuilder module) {
    return _importedWasmTables.get(_definedWasmTable, module);
  }

  /// Returns the index for [function] in the table allocating one if necessary.
  int indexForFunction(w.BaseFunction function) {
    assert(function.type.isStructurallyEqualTo(function.type));
    return _table[function] ??= _table.length;
  }

  void output() {
    final importedTables = _importedWasmTables;
    _table.forEach((fun, index) {
      final targetModule = fun.enclosingModule;
      if (translator.isMainModule(targetModule)) {
        _definedWasmTable.setElement(index, fun);
      } else {
        // This will generate the imported table if it doesn't already exist.
        (getWasmTable(targetModule) as w.ImportedTable).setElements[fun] =
            index;
      }
    });

    _definedWasmTable.minSize = _table.length;
    for (final table in importedTables.imports) {
      table.minSize = _table.length;
    }
  }
}
