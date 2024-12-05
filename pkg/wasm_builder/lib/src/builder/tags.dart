// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

/// The interface for the tags in a module.
class TagsBuilder with Builder<ir.Tags> {
  final ModuleBuilder _module;
  final List<ir.DefinedTag> _defined = [];
  final List<ir.ImportedTag> _imported = [];

  TagsBuilder(this._module);

  void collectUsedTypes(Set<ir.DefType> usedTypes) {
    for (final tag in _defined) {
      usedTypes.add(tag.type);
    }
    for (final tag in _imported) {
      usedTypes.add(tag.type);
    }
  }

  /// Defines a new tag in the module.
  ir.Tag define(ir.FunctionType type) {
    final tag = ir.DefinedTag(_module, ir.FinalizableIndex(), type);
    _defined.add(tag);
    return tag;
  }

  /// Defines a new tag in the module.
  ir.Tag import(String module, String name, ir.FunctionType type) {
    final tag =
        ir.ImportedTag(_module, module, name, ir.FinalizableIndex(), type);
    _imported.add(tag);
    return tag;
  }

  @override
  ir.Tags forceBuild() {
    finalizeImportsAndDefinitions(_imported, _defined);
    return ir.Tags(_defined, _imported);
  }
}
