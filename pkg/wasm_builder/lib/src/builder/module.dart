// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A Wasm module builder.
///
/// NOTE: The [ModuleBuilder] contains builders for various constituents and
/// those in return will refer back to the [ModuleBuilder], making the builders
/// be cyclic data structures.
///
/// The main reason for this is that e.g. an [InstructionsBuilder] may insert
/// new instructions. Doing so may require e.g. defining new function types. So
/// it does so by calling `moduleBuilder.functions.defineFunction()`.
///
/// We could avoid some of the cyclic dependencies by passing the individual
/// builders down to other builders that need it, instead of passing an
/// [ModuleBuilder] down that contains all builders.
class ModuleBuilder with Builder<ir.Module> {
  final ir.Module module = ir.Module.uninitialized();

  final String moduleName;
  final Uri? sourceMapUrl;
  final List<int> watchPoints;
  late final TypesBuilder types;
  late final functions = FunctionsBuilder(this);
  late final tables = TablesBuilder(module);
  late final memories = MemoriesBuilder(module);
  late final tags = TagsBuilder(module);
  final dataSegments = DataSegmentsBuilder();
  late final globals = GlobalsBuilder(this);
  final exports = ExportsBuilder();
  ir.BaseFunction? _startFunction;

  /// Create a new, initially empty, module.
  ///
  /// The [watchPoints] is a list of byte offsets within the final module of
  /// bytes to watch. When the module is serialized, the stack traces leading
  /// to the production of all watched bytes are printed. This can be used to
  /// debug runtime errors happening at specific offsets within the module.
  ModuleBuilder(this.moduleName, this.sourceMapUrl,
      {ModuleBuilder? parent, this.watchPoints = const []}) {
    types = TypesBuilder(this, parent: parent?.types);
  }

  set startFunction(ir.BaseFunction init) {
    assert(_startFunction == null);
    _startFunction = init;
  }

  @override
  ir.Module forceBuild() {
    final finalFunctions = functions.build();
    final finalTables = tables.build();
    final finalMemories = memories.build();
    final finalGlobals = globals.build();
    final finalTags = tags.build();
    final imports = ir.Imports(
      finalFunctions.imported,
      finalTags.imported,
      finalGlobals.imported,
      finalTables.imported,
      finalMemories.imported,
    );
    return module
      ..initialize(
          moduleName,
          finalFunctions,
          _startFunction,
          finalTables,
          finalTags,
          finalMemories,
          exports.build(),
          finalGlobals,
          types.build(),
          dataSegments.build(),
          imports,
          watchPoints,
          sourceMapUrl);
  }
}
