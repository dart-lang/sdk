// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../../debug_info.dart';
import '../ir/ir.dart' as ir;
import '../serialize/sections.dart';
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
  final DebugInfoTables? debugInfoTables;
  final TypesBuilder types;
  late final functions = FunctionsBuilder(this);
  late final elements = ElementsBuilder(this);
  late final tables = TablesBuilder(module);
  late final memories = MemoriesBuilder(module);
  late final tags = TagsBuilder(module);
  final dataSegments = DataSegmentsBuilder();
  late final globals = GlobalsBuilder(this);
  final exports = ExportsBuilder();
  FunctionBuilder? _startFunction;
  final List<ExtraCustomSection> _extraCustomSections = [];

  /// Whether relaxed SIMD instructions may be emitted into this module.
  ///
  /// Relaxed SIMD is a Wasm proposal separate from fixed-width SIMD, and its
  /// instructions are allowed to produce different results on different
  /// engines. A module containing one only runs on an engine implementing the
  /// proposal, so using them is opt-in per module.
  final bool allowRelaxedSimd;

  /// Create a new, initially empty, module.
  ///
  /// When building multiple modules that exchange WasmGC types, pass a shared
  /// [types] builder so all modules canonicalize and emit identical recursion
  /// groups.
  ModuleBuilder(
    this.moduleName,
    this.sourceMapUrl, {
    TypesBuilder? types,
    this.allowRelaxedSimd = false,
  }) : types = types ?? TypesBuilder(),
       debugInfoTables = sourceMapUrl == null ? null : DebugInfoTables();

  void addCustomSection(String name, Uint8List data) {
    _extraCustomSections.add(ExtraCustomSection(name, data));
  }

  /// Whether loading the module would have no effect.
  ///
  /// This means no code is executable and no external data would be modified.
  bool get hasNoEffect {
    // Exports can be used from the outside.
    if (exports.hasExports) return false;

    // Start function is implicitly used from the outside - it's run at module
    // instantiation time.
    if (_startFunction != null) return false;

    // Active element segments are implicitly used from the outside - they are
    // run at module instantiation time and may patch imported tables.
    if (elements.hasActiveElementSegments) return false;

    return true;
  }

  FunctionBuilder? get startFunctionIfCreated => _startFunction;

  FunctionBuilder get startFunction => _startFunction ??= functions.define(
    types.defineFunction(const [], const []),
    "#init",
  );

  @override
  ir.Module forceBuild() {
    if (_startFunction case final start?) {
      start.body.end();
      start.build();
    }
    final finalFunctions = functions.build();
    final finalTables = tables.build();
    final finalElements = elements.build();
    final finalMemories = memories.build();
    final finalGlobals = globals.build();
    final finalTags = tags.build();
    final finalExports = exports.build();
    final finalTypes = types.build(
      finalFunctions,
      finalTables,
      finalGlobals,
      finalTags,
      finalElements,
    );
    final finalDataSegments = dataSegments.build();
    final imports = ir.Imports(
      finalFunctions.imported,
      finalTags.imported,
      finalGlobals.imported,
      finalTables.imported,
      finalMemories.imported,
    );
    return module..initialize(
      moduleName,
      finalFunctions,
      _startFunction?.function,
      finalTables,
      finalElements,
      finalTags,
      finalMemories,
      finalExports,
      finalGlobals,
      finalTypes,
      finalDataSegments,
      imports,
      sourceMapUrl,
      _extraCustomSections,
      debugInfoTables,
    );
  }
}
