// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

class MemoriesBuilder with Builder<ir.Memories> {
  final _definedMemories = <ir.DefinedMemory>[];
  final _importedMemories = <ir.Import>[];

  /// Add a new memory to the module.
  ir.DefinedMemory define(bool shared, int minSize, [int? maxSize]) {
    final memory =
        ir.DefinedMemory(ir.FinalizableIndex(), shared, minSize, maxSize);
    _definedMemories.add(memory);
    return memory;
  }

  /// Imports a memory into this module.
  ///
  /// All imported memories must be specified before any memories are declared
  /// using [defined].
  ir.ImportedMemory import(String module, String name, bool shared, int minSize,
      [int? maxSize]) {
    final memory = ir.ImportedMemory(
        module, name, ir.FinalizableIndex(), shared, minSize, maxSize);
    _importedMemories.add(memory);
    return memory;
  }

  @override
  ir.Memories forceBuild() {
    finalizeImportsAndDefinitions(_importedMemories, _definedMemories);
    return ir.Memories(_importedMemories, _definedMemories);
  }
}
