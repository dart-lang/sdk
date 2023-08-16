// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

part 'global.dart';

class GlobalsBuilder with Builder<ir.Globals> {
  final ModuleBuilder _module;
  final _importedGlobals = <ir.Import>[];
  final _globalBuilders = <GlobalBuilder>[];
  bool _anyGlobalsDefined = false;

  GlobalsBuilder(this._module);

  /// This is guarded by [_anyGlobalsDefined].
  int get _index => _importedGlobals.length + _globalBuilders.length;

  /// Defines a new global variable in this module.
  GlobalBuilder define(ir.GlobalType type) {
    _anyGlobalsDefined = true;
    final global = GlobalBuilder(_module, _index, type);
    _globalBuilders.add(global);
    return global;
  }

  /// Imports a global variable into this module.
  ///
  /// All imported globals must be specified before any globals are declared
  /// using [Globals.define].
  ir.ImportedGlobal import(String module, String name, ir.GlobalType type) {
    if (_anyGlobalsDefined) {
      throw "All global imports must be specified before any definitions.";
    }
    final global = ir.ImportedGlobal(module, name, _index, type);
    _importedGlobals.add(global);
    return global;
  }

  @override
  ir.Globals forceBuild() => ir.Globals(
      _importedGlobals, _globalBuilders.map((g) => g.build()).toList());
}
