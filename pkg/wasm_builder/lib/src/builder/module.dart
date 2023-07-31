// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

// TODO(joshualitt): Get rid of cycles in the builder graph.
/// A Wasm module builder.
class ModuleBuilder with Builder<ir.Module> {
  final List<int>? watchPoints;
  final types = TypesBuilder();
  late final functions = FunctionsBuilder(this);
  final tables = TablesBuilder();
  final memories = MemoriesBuilder();
  final tags = TagsBuilder();
  final dataSegments = DataSegmentsBuilder();
  late final globals = GlobalsBuilder(this);
  final exports = ExportsBuilder();
  bool dataReferencedFromGlobalInitializer = false;

  /// Create a new, initially empty, module.
  ///
  /// The [watchPoints] is a list of byte offsets within the final module of
  /// bytes to watch. When the module is serialized, the stack traces leading to
  /// the production of all watched bytes are printed. This can be used to debug
  /// runtime errors happening at specific offsets within the module.
  ModuleBuilder({this.watchPoints});

  @override
  ir.Module forceBuild() {
    final finalFunctions = functions.build();
    final finalTables = tables.build();
    final finalMemories = memories.build();
    final finalGlobals = globals.build();
    return ir.Module(
        finalFunctions,
        finalTables,
        tags.build(),
        finalMemories,
        exports.build(),
        finalGlobals,
        types.build(),
        dataSegments.build(),
        finalFunctions.imported
            .followedBy(finalTables.imported)
            .followedBy(finalMemories.imported)
            .followedBy(finalGlobals.imported)
            .toList(),
        watchPoints,
        dataReferencedFromGlobalInitializer);
  }
}
