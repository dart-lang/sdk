// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

class GlobalsBuilder with Builder<ir.Globals> {
  final ModuleBuilder _moduleBuilder;
  final _importedGlobals = <ir.ImportedGlobal>[];
  final _definedGlobals = <ir.DefinedGlobal>[];

  GlobalsBuilder(this._moduleBuilder);

  List<ir.DefinedGlobal> get defined => _definedGlobals;

  /// Defines a new global variable in this module.
  GlobalBuilder define(ir.GlobalType type, [String? name]) {
    final global = ir.DefinedGlobal.withoutInitializer(
      _moduleBuilder.module,
      ir.FinalizableIndex(),
      type,
      name,
    );
    _definedGlobals.add(global);
    return GlobalBuilder(_moduleBuilder, global);
  }

  /// Imports a global variable into this module.
  ir.ImportedGlobal import(String module, String name, ir.GlobalType type) {
    final global = ir.ImportedGlobal(
      _moduleBuilder.module,
      module,
      name,
      ir.FinalizableIndex(),
      type,
    );
    _importedGlobals.add(global);
    return global;
  }

  @override
  ir.Globals forceBuild() {
    final order = <ir.DefinedGlobal>{};

    void dfs(ir.DefinedGlobal g) {
      for (final i in g.initializer.instructions) {
        if (i is ir.GlobalGet) {
          final global = i.global;
          if (global is ir.DefinedGlobal && !order.contains(global)) {
            dfs(global);
          }
        }
      }
      order.add(g);
    }

    for (final g in _definedGlobals) {
      if (!order.contains(g)) {
        dfs(g);
      }
    }

    finalizeImportsAndDefinitions(_importedGlobals, order);
    return ir.Globals(_importedGlobals, order.toList());
  }
}
