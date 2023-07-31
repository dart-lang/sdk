// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

class MemoriesBuilder with Builder<ir.Memories> {
  final _definedMemories = <ir.DefinedMemory>[];
  final _importedMemories = <ir.Import>[];
  bool _anyMemoriesDefined = false;

  /// This is guarded by [_anyMemoriesDefined].
  int get _index => _importedMemories.length + _definedMemories.length;

  /// Add a new memory to the module.
  ir.DefinedMemory define(bool shared, int minSize, [int? maxSize]) {
    _anyMemoriesDefined = true;
    final memory = ir.DefinedMemory(_index, shared, minSize, maxSize);
    _definedMemories.add(memory);
    return memory;
  }

  /// Imports a memory into this module.
  ///
  /// All imported memories must be specified before any memories are declared
  /// using [defined].
  ir.ImportedMemory import(String module, String name, bool shared, int minSize,
      [int? maxSize]) {
    if (_anyMemoriesDefined) {
      throw "All memory imports must be specified before any definitions.";
    }
    final memory =
        ir.ImportedMemory(module, name, _index, shared, minSize, maxSize);
    _importedMemories.add(memory);
    return memory;
  }

  @override
  ir.Memories forceBuild() => ir.Memories(_importedMemories, _definedMemories);
}
