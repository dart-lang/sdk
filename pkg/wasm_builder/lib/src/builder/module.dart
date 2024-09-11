// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

// TODO(joshualitt): Get rid of cycles in the builder graph.
/// A Wasm module builder.
class ModuleBuilder with Builder<ir.Module> {
  final Uri? sourceMapUrl;
  final List<int> watchPoints;
  late final TypesBuilder types;
  late final functions = FunctionsBuilder(this);
  late final tables = TablesBuilder(this);
  late final memories = MemoriesBuilder(this);
  late final tags = TagsBuilder(this);
  final dataSegments = DataSegmentsBuilder();
  late final globals = GlobalsBuilder(this);
  final exports = ExportsBuilder();

  /// Create a new, initially empty, module.
  ///
  /// The [watchPoints] is a list of byte offsets within the final module of
  /// bytes to watch. When the module is serialized, the stack traces leading
  /// to the production of all watched bytes are printed. This can be used to
  /// debug runtime errors happening at specific offsets within the module.
  ModuleBuilder(this.sourceMapUrl,
      {ModuleBuilder? parent, this.watchPoints = const []}) {
    types = TypesBuilder(this, parent: parent?.types);
  }

  @override
  ir.Module forceBuild() {
    final finalFunctions = functions.build();
    final finalTables = tables.build();
    final finalMemories = memories.build();
    final finalGlobals = globals.build();
    final finalTags = tags.build();
    return ir.Module(
        sourceMapUrl,
        finalFunctions,
        finalTables,
        finalTags,
        finalMemories,
        exports.build(),
        finalGlobals,
        types.build(),
        dataSegments.build(),
        <ir.Import>[
          ...finalFunctions.imported,
          ...finalTables.imported,
          ...finalMemories.imported,
          ...finalGlobals.imported,
          ...finalTags.imported,
        ],
        watchPoints);
  }
}
