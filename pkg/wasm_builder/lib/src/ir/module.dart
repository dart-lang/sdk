// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../serialize/serialize.dart';
import 'ir.dart';

/// A logically const wasm module ready to encode. Created with `ModuleBuilder`.
class Module implements Serializable {
  // The [Module] object represents a collection of many wasm objects. Some of
  // those will have back pointers to this [Module]. That means the data
  // structures are cyclic.
  //
  // (This is similar to how Kernel AST nodes have children and those children
  // have back pointers to the parent).
  //
  // To break the cycle when constructing the objects, we create the [Module] in
  // uninitialized form, then create the constitutents and finally initialize the
  // module with the constitutents.
  bool _initialized = false;

  late final String _moduleName;
  late final Functions _functions;
  late final Tables _tables;
  late final Tags _tags;
  late final Memories _memories;
  late final Exports _exports;
  late final Globals _globals;
  late final Types _types;
  late final DataSegments _dataSegments;
  late final List<Import> _imports;
  late final List<int> _watchPoints;
  late final Uri? _sourceMapUrl;

  Module.uninitialized() : _initialized = false;

  void initialize(
    String moduleName,
    Functions functions,
    Tables tables,
    Tags tags,
    Memories memories,
    Exports exports,
    Globals globals,
    Types types,
    DataSegments dataSegments,
    List<Import> imports,
    List<int> watchPoints,
    Uri? sourceMapUrl,
  ) {
    if (_initialized) throw 'Already initialized';

    _initialized = true;
    _moduleName = moduleName;
    _functions = functions;
    _tables = tables;
    _tags = tags;
    _memories = memories;
    _exports = exports;
    _globals = globals;
    _types = types;
    _dataSegments = dataSegments;
    _imports = imports;
    _watchPoints = watchPoints;
    _sourceMapUrl = sourceMapUrl;
  }

  String get moduleName => _moduleName;
  Functions get functions => _functions;
  Tables get tables => _tables;
  Tags get tags => _tags;
  Memories get memories => _memories;
  Exports get exports => _exports;
  Globals get globals => _globals;
  Types get types => _types;
  DataSegments get dataSegments => _dataSegments;
  List<Import> get imports => _imports;
  List<int> get watchPoints => _watchPoints;
  Uri? get sourceMapUrl => _sourceMapUrl;

  /// Serialize a module to its binary representation.
  @override
  void serialize(Serializer s) {
    if (watchPoints.isNotEmpty) {
      Serializer.traceEnabled = true;
    }
    // Wasm module preamble: magic number, version 1.
    s.writeBytes(Uint8List.fromList(
        const [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]));
    TypeSection(types, watchPoints).serialize(s);
    ImportSection(imports, watchPoints).serialize(s);
    FunctionSection(functions.defined, watchPoints).serialize(s);
    TableSection(tables.defined, watchPoints).serialize(s);
    MemorySection(memories.defined, watchPoints).serialize(s);
    TagSection(tags.defined, watchPoints).serialize(s);
    GlobalSection(globals.defined, watchPoints).serialize(s);
    ExportSection(exports.exported, watchPoints).serialize(s);
    StartSection(functions.start, watchPoints).serialize(s);
    ElementSection(
            tables.defined, tables.imported, functions.declared, watchPoints)
        .serialize(s);
    DataCountSection(dataSegments.defined, watchPoints).serialize(s);
    CodeSection(functions.defined, watchPoints).serialize(s);
    DataSection(dataSegments.defined, watchPoints).serialize(s);
    NameSection(
            moduleName,
            <BaseFunction>[...functions.imported, ...functions.defined],
            types.recursionGroups,
            <Global>[...globals.imported, ...globals.defined],
            watchPoints)
        .serialize(s);
    SourceMapSection(sourceMapUrl).serialize(s);
  }
}
