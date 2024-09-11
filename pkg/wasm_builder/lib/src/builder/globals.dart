// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

part 'global.dart';

class GlobalsBuilder with Builder<ir.Globals> {
  final ModuleBuilder _module;
  final _importedGlobals = <ir.ImportedGlobal>[];
  final _globalBuilders = <GlobalBuilder>[];

  /// Number of named globals.
  int _namedCount = 0;

  GlobalsBuilder(this._module);

  void collectUsedTypes(Set<ir.DefType> usedTypes) {
    for (final global in _globalBuilders) {
      final defType = global.type.type.containedDefType;
      if (defType != null) usedTypes.add(defType);
      global.initializer.collectUsedTypes(usedTypes);
    }
    for (final global in _importedGlobals) {
      final defType = global.type.type.containedDefType;
      if (defType != null) usedTypes.add(defType);
    }
  }

  /// Defines a new global variable in this module.
  GlobalBuilder define(ir.GlobalType type, [String? name]) {
    final global = GlobalBuilder(_module, ir.FinalizableIndex(), type, name);
    _globalBuilders.add(global);
    if (name != null) {
      _namedCount += 1;
    }
    return global;
  }

  /// Imports a global variable into this module.
  ir.ImportedGlobal import(String module, String name, ir.GlobalType type) {
    final global =
        ir.ImportedGlobal(_module, module, name, ir.FinalizableIndex(), type);
    _importedGlobals.add(global);
    return global;
  }

  @override
  ir.Globals forceBuild() {
    final built = finalizeImportsAndBuilders<ir.DefinedGlobal>(
        _importedGlobals, _globalBuilders);
    return ir.Globals(_importedGlobals, built, _namedCount);
  }
}
