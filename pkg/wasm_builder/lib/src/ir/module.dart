// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../serialize/printer.dart';
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

  late final String? _moduleName;
  late final Functions _functions;
  late final BaseFunction? _start;
  late final Tables _tables;
  late final Elements _elements;
  late final Tags _tags;
  late final Memories _memories;
  late final Exports _exports;
  late final Globals _globals;
  late final Types _types;
  late final DataSegments _dataSegments;
  late final Imports _imports;
  late final List<int> _watchPoints;
  late final Uri? _sourceMapUrl;

  Module.uninitialized() : _initialized = false;

  void initialize(
    String? moduleName,
    Functions functions,
    BaseFunction? start,
    Tables tables,
    Elements elements,
    Tags tags,
    Memories memories,
    Exports exports,
    Globals globals,
    Types types,
    DataSegments dataSegments,
    Imports imports,
    List<int> watchPoints,
    Uri? sourceMapUrl,
  ) {
    if (_initialized) throw 'Already initialized';

    _initialized = true;
    _moduleName = moduleName;
    _functions = functions;
    _start = start;
    _tables = tables;
    _elements = elements;
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

  String? get moduleName => _moduleName;
  Functions get functions => _functions;
  BaseFunction? get start => _start;
  Tables get tables => _tables;
  Elements get elements => _elements;
  Tags get tags => _tags;
  Memories get memories => _memories;
  Exports get exports => _exports;
  Globals get globals => _globals;
  Types get types => _types;
  DataSegments get dataSegments => _dataSegments;
  Imports get imports => _imports;
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
    StartSection(start, watchPoints).serialize(s);
    ElementSection(elements, watchPoints).serialize(s);
    DataCountSection(dataSegments.defined, watchPoints).serialize(s);
    CodeSection(functions.defined, watchPoints).serialize(s);
    DataSection(dataSegments.defined, watchPoints).serialize(s);
    NameSection(
            moduleName, functions, types.recursionGroups, globals, watchPoints)
        .serialize(s);
    RemovableIfUnusedSection(functions).serialize(s);
    SourceMapSection(sourceMapUrl).serialize(s);
  }

  static (Map<int, List<Deserializer>>, Map<String, List<Deserializer>>)
      _deserializeTopLevel(Deserializer d) {
    final preamble = d.readBytes(8);
    if (preamble[0] != 0x00 ||
        preamble[1] != 0x61 ||
        preamble[2] != 0x73 ||
        preamble[3] != 0x6D ||
        preamble[4] != 0x01 ||
        preamble[5] != 0x00 ||
        preamble[6] != 0x00 ||
        preamble[7] != 0x00) {
      throw 'Invalid Wasm preamble';
    }

    // Although we expect sections in a specific order, we discover all of them
    // here. This makes the code below that handles the presence/absense of a
    // section easier.
    final sections = <int, List<Deserializer>>{};
    final customSections = <String, List<Deserializer>>{};
    while (!d.isAtEnd) {
      final id = d.readByte();
      final size = d.readUnsigned();
      final deserializer = Deserializer(d.readBytes(size));

      if (id == CustomSection.sectionId) {
        // Custom section
        final name = deserializer.readName();
        customSections.putIfAbsent(name, () => []).add(deserializer);
      } else {
        sections.putIfAbsent(id, () => []).add(deserializer);
      }
    }

    return (sections, customSections);
  }

  static Module deserialize(Deserializer d) {
    final (sections, customSections) = _deserializeTopLevel(d);

    final Module module = Module.uninitialized();

    // We read the sections in the order they should be in the binary.

    final typeSections = sections[TypeSection.sectionId];
    final types = TypeSection.deserialize(typeSections?.single);

    final importSections = sections[ImportSection.sectionId];
    final imports =
        ImportSection.deserialize(importSections?.single, module, types);

    final functionSections = sections[FunctionSection.sectionId];
    final functions = FunctionSection.deserialize(
        functionSections?.single, module, types, imports.functions);

    final tablesSections = sections[TableSection.sectionId];
    final tables = TableSection.deserialize(
        tablesSections?.single, module, types, imports.tables);

    final memorySections = sections[MemorySection.sectionId];
    final memories = MemorySection.deserialize(
        memorySections?.single, module, imports.memories);

    final tagSections = sections[TagSection.sectionId];
    final tags = TagSection.deserialize(
        tagSections?.single, module, types, imports.tags);

    final globalSections = sections[GlobalSection.sectionId];
    final globals = GlobalSection.deserialize(
        globalSections?.single, module, types, functions, imports.globals);

    final exportSections = sections[ExportSection.sectionId];
    final exports = ExportSection.deserialize(
        exportSections?.single, functions, tables, memories, globals, tags);

    final startFunctionSections = sections[StartSection.sectionId];
    final start =
        StartSection.deserialize(startFunctionSections?.single, functions);

    final elementSections = sections[ElementSection.sectionId];
    final elements = ElementSection.deserialize(
        elementSections?.single, module, types, functions, tables, globals);

    final dataCountSections = sections[DataCountSection.sectionId];
    final dataSegments =
        DataCountSection.deserialize(dataCountSections?.single);

    final codeSections = sections[CodeSection.sectionId];
    CodeSection.deserialize(codeSections?.single, functions.defined, module,
        types, functions, tables, memories, tags, globals, dataSegments);

    final dataSections = sections[DataSection.sectionId];
    // As side-effect initializes [dataSegments.defined]
    DataSection.deserialize(dataSections?.single, dataSegments, memories);

    final moduleName = NameSection.deserialize(
        customSections[NameSection.customSectionName]?.single,
        functions,
        types,
        globals);
    RemovableIfUnusedSection.deserialize(
        customSections[RemovableIfUnusedSection.customSectionName]?.single,
        functions);
    final sourceMapUrl = SourceMapSection.deserialize(
        customSections[SourceMapSection.customSectionName]?.single);

    return module
      ..initialize(
        moduleName ?? '',
        functions,
        start,
        tables,
        elements,
        tags,
        memories,
        exports,
        globals,
        types,
        dataSegments,
        imports,
        [],
        sourceMapUrl,
      );
  }

  /// Deserialize just the `sourceMapUrl` section of a module as a [Uri].
  static Uri? deserializeSourceMapUrl(Deserializer d) {
    final (sections, customSections) = _deserializeTopLevel(d);
    final sourceMapUrl = SourceMapSection.deserialize(
        customSections[SourceMapSection.customSectionName]?.single);
    return sourceMapUrl;
  }

  String printAsWat(
      {ModulePrintSettings settings = const ModulePrintSettings()}) {
    final mp = ModulePrinter(this, settings: settings);

    if (settings.hasFilters) {
      // If we have any filters, we treat those as roots.
      if (settings.typeFilters.isNotEmpty) {
        for (final type in mp.typeNamer.sort(mp.typeNamer
            .filter(types.defined, settings.printTypeConstituents))) {
          mp.enqueueType(type);
        }
      }
      if (settings.globalFilters.isNotEmpty) {
        for (final global in mp.globalNamer.sort(mp.globalNamer
            .filter(globals.defined, settings.printGlobalInitializer))) {
          mp.enqueueGlobal(global);
        }
      }
      if (settings.functionFilters.isNotEmpty) {
        for (final function in mp.functionNamer.sort(mp.functionNamer
            .filter(functions.defined, settings.printFunctionBody))) {
          mp.enqueueFunction(function);
        }
      }
      if (settings.tableFilters.isNotEmpty) {
        for (final table in mp.tableNamer.sort(mp.tableNamer
            .filter(tables.defined, settings.printTableElements))) {
          mp.enqueueTable(table);
        }
      }
    } else {
      // Enqueue all types, tags, globals, functions thereby making the
      // printed module contain most things we care about.
      for (final type in types.defined) {
        if (type is! FunctionType) {
          mp.enqueueType(type);
        }
      }

      for (final memory in [...memories.imported, ...memories.defined]) {
        mp.enqueueMemory(memory);
      }

      for (final table in [...tables.imported, ...tables.defined]) {
        mp.enqueueTable(table);
      }

      for (final tag in [...tags.imported, ...tags.defined]) {
        mp.enqueueTag(tag);
      }

      for (final global in [...globals.imported, ...globals.defined]) {
        mp.enqueueGlobal(global);
      }

      for (final function in [...functions.imported, ...functions.defined]) {
        mp.enqueueFunction(function);
      }
    }
    return mp.print();
  }
}
