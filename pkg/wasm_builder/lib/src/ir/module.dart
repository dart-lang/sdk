// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

/// A logically const wasm module ready to encode. Created with `ModuleBuilder`.
class Module implements Serializable {
  final Functions functions;
  final Tables tables;
  final Tags tags;
  final Memories memories;
  final Exports exports;
  final Globals globals;
  final Types types;
  final DataSegments dataSegments;
  final List<Import> imports;
  final List<int>? watchPoints;
  final bool dataReferencedFromGlobalInitializer;

  Module(
      this.functions,
      this.tables,
      this.tags,
      this.memories,
      this.exports,
      this.globals,
      this.types,
      this.dataSegments,
      this.imports,
      this.watchPoints,
      this.dataReferencedFromGlobalInitializer);

  /// Serialize a module to its binary representation.
  @override
  void serialize(Serializer s) {
    if (watchPoints != null) {
      Serializer.traceEnabled = true;
    }
    // Wasm module preamble: magic number, version 1.
    s.writeBytes(const [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]);
    TypeSection(types, watchPoints).serialize(s);
    ImportSection(imports, watchPoints).serialize(s);
    FunctionSection(functions.defined, watchPoints).serialize(s);
    TableSection(tables.defined, watchPoints).serialize(s);
    MemorySection(memories.defined, watchPoints).serialize(s);
    TagSection(tags.defined, watchPoints).serialize(s);
    if (dataReferencedFromGlobalInitializer) {
      DataCountSection(dataSegments.defined, watchPoints).serialize(s);
    }
    GlobalSection(globals.defined, watchPoints).serialize(s);
    ExportSection(exports.exported, watchPoints).serialize(s);
    StartSection(functions.start, watchPoints).serialize(s);
    ElementSection(tables.defined, watchPoints).serialize(s);
    if (!dataReferencedFromGlobalInitializer) {
      DataCountSection(dataSegments.defined, watchPoints).serialize(s);
    }
    CodeSection(functions.defined, watchPoints).serialize(s);
    DataSection(dataSegments.defined, watchPoints).serialize(s);
    if (functions.namedCount > 0 || types.namedCount > 0) {
      NameSection(functions.all, types.defined, watchPoints,
              functionNameCount: functions.namedCount,
              typeNameCount: types.namedCount)
          .serialize(s);
    }
  }
}
