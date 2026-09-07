// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

class GlobalsBuilder with Builder<ir.Globals> {
  final ModuleBuilder _moduleBuilder;
  final _importedGlobals = <ir.ImportedGlobal>[];
  final _globalBuilders = <GlobalBuilder>[];

  GlobalsBuilder(this._moduleBuilder);

  /// Defines a new global variable in this module.
  GlobalBuilder define(ir.GlobalType type, [String? name]) {
    final global = GlobalBuilder(
      _moduleBuilder,
      ir.FinalizableIndex(),
      type,
      name,
    );
    _globalBuilders.add(global);
    return global;
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
          final definedGlobal = switch (global) {
            ir.DefinedGlobal() => global,
            GlobalBuilder() => global.build(),
            _ => null,
          };
          if (definedGlobal != null && !order.contains(definedGlobal)) {
            dfs(definedGlobal);
          }
        }
      }
      order.add(g);
    }

    for (final b in _globalBuilders) {
      final g = b.build();
      if (!order.contains(g)) {
        dfs(g);
      }
    }

    final defined = order.toList();
    finalizeImportsAndDefinitions(_importedGlobals, defined);
    return ir.Globals(_importedGlobals, defined);
  }
}
