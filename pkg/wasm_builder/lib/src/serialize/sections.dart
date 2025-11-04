// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'deserializer.dart';
import 'serializer.dart';

abstract class Section implements Serializable {
  final List<int> watchPoints;

  Section(this.watchPoints);

  @override
  void serialize(Serializer s) {
    final contents = Serializer();
    serializeContents(contents);
    final data = contents.data;
    if (data.isNotEmpty) {
      s.writeByte(id);
      s.writeUnsigned(data.length);
      s.sourceMapSerializer
          .copyMappings(contents.sourceMapSerializer, s.offset);
      s.writeData(contents, watchPoints);
    }
  }

  int get id;

  void serializeContents(Serializer s);
}

class TypeSection extends Section {
  static const sectionId = 1;

  final ir.Types types;

  TypeSection(this.types, super.watchPoints);

  List<List<ir.DefType>> get recursionGroups => types.recursionGroups;

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (types.recursionGroups.isEmpty) return;

    s.writeUnsigned(types.recursionGroups.length);
    int typeIndex = 0;

    // Set all the indices first since types can be referenced before they are
    // serialized.
    for (final group in recursionGroups) {
      assert(group.isNotEmpty, 'Empty groups are not allowed.');

      for (final type in group) {
        type.index = typeIndex++;
      }
    }
    for (final group in recursionGroups) {
      if (group.length > 1) {
        s.writeByte(0x4E); // -0x32
        s.writeUnsigned(group.length);
      }
      for (final type in group) {
        assert(
            type.superType == null || type.superType!.index <= group.last.index,
            "Type '$type' has a supertype in a later recursion group");
        assert(
            type.constituentTypes
                .whereType<ir.RefType>()
                .map((t) => t.heapType)
                .whereType<ir.DefType>()
                .every((d) => d.index <= group.last.index),
            "Type '$type' depends on a type in a later recursion group");
        type.serializeDefinition(s);
      }
    }
  }

  static ir.Types deserialize(Deserializer? d) {
    if (d == null) {
      return ir.Types([]);
    }

    final List<ir.DefType> definedTypes = [];
    final List<List<ir.DefType>> recursionGroups = [];

    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      late int recursionGroupMemberCount;
      if (d.peekByte() == 0x4E) {
        d.readByte();
        // We may have more than one type in the recursion group.
        recursionGroupMemberCount = d.readUnsigned();
      } else {
        // Old type encoding. The type becomes it's own recursion group.
        recursionGroupMemberCount = 1;
      }

      // As types can form cycles within a recursion group, we construct them in
      // two phases:
      //
      //   1) allocate the type objects and fixed parts of them
      //   2) fill in the composite type references
      //
      // So for example we'd create a [ir.StructType] in phase 1) and then in
      // phase 2) we'd populate the struct field types.
      final typesInGroup = <ir.DefType>[];
      final startOffset = d.offset;
      for (int j = 0; j < recursionGroupMemberCount; j++) {
        final type = ir.DefType.deserializeAllocate(d, definedTypes);
        typesInGroup.add(type);
        definedTypes.add(type);
      }
      d.offset = startOffset;
      for (int j = 0; j < recursionGroupMemberCount; j++) {
        typesInGroup[j].deserializeFill(d, definedTypes);
      }
      recursionGroups.add(typesInGroup);
    }
    return ir.Types(recursionGroups);
  }
}

class ImportSection extends Section {
  static const int sectionId = 2;

  final ir.Imports imports;

  ImportSection(this.imports, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (imports.all.isNotEmpty) {
      s.writeList(imports.all);
    }
  }

  static ir.Imports deserialize(
      Deserializer? d, ir.Module module, ir.Types types) {
    final imports = <ir.Import>[];
    final importedMemories = <ir.ImportedMemory>[];
    final importedGlobals = <ir.ImportedGlobal>[];
    final importedTags = <ir.ImportedTag>[];
    final importedTables = <ir.ImportedTable>[];
    final importedFunctions = <ir.ImportedFunction>[];

    if (d != null) {
      final count = d.readUnsigned();
      for (int i = 0; i < count; i++) {
        final moduleName = d.readName();
        final name = d.readName();
        final kind = d.readByte();
        switch (kind) {
          case 0x00: // Function
            final typeIndex = d.readUnsigned();
            final type = types[typeIndex] as ir.FunctionType;
            final import = ir.ImportedFunction(
                module, moduleName, name, ir.FinalizableIndex(), type);
            import.finalizableIndex.value = importedFunctions.length;
            importedFunctions.add(import);
            imports.add(import);
            break;
          case 0x01: // Table
            final type = ir.RefType.deserialize(d, types.defined);
            final limits = d.readByte();
            final minSize = d.readUnsigned();
            final maxSize = limits == 0x01 ? d.readUnsigned() : null;
            final import = ir.ImportedTable(module, moduleName, name,
                ir.FinalizableIndex(), type, minSize, maxSize);
            import.finalizableIndex.value = importedTables.length;
            importedTables.add(import);
            imports.add(import);
            break;
          case 0x02: // Memory
            final limits = d.readByte();
            final shared = limits == 0x03;
            final minSize = d.readUnsigned();
            final maxSize =
                limits == 0x01 || limits == 0x03 ? d.readUnsigned() : null;
            final import = ir.ImportedMemory(module, moduleName, name,
                ir.FinalizableIndex(), shared, minSize, maxSize);
            import.finalizableIndex.value = importedMemories.length;
            importedMemories.add(import);
            imports.add(import);
            break;
          case 0x03: // Global
            final type = ir.GlobalType.deserialize(d, types.defined);
            final import = ir.ImportedGlobal(
                module, moduleName, name, ir.FinalizableIndex(), type);
            import.finalizableIndex.value = importedGlobals.length;
            importedGlobals.add(import);
            imports.add(import);
            break;
          case 0x04: // Tag
            final exceptionByte = d.readByte();
            if (exceptionByte != 0x00) throw 'unexpected';
            d.readUnsigned(); // typeIndex
            throw 'runtimeType';
          default:
            throw "Invalid import kind: $kind";
        }
      }
    }
    return ir.Imports.deserialized(imports, importedFunctions, importedTags,
        importedGlobals, importedTables, importedMemories);
  }
}

class FunctionSection extends Section {
  static const int sectionId = 3;

  final List<ir.DefinedFunction> functions;

  FunctionSection(this.functions, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (functions.isNotEmpty) {
      s.writeUnsigned(functions.length);
      for (final function in functions) {
        s.writeUnsigned(function.type.index);
      }
    }
  }

  static ir.Functions deserialize(Deserializer? d, ir.Module module,
      ir.Types types, List<ir.ImportedFunction> imported) {
    if (d == null) {
      return ir.Functions.withoutDeclared(imported, []);
    }

    final List<ir.DefinedFunction> defined = [];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final typeIndex = d.readUnsigned();
      final type = types[typeIndex] as ir.FunctionType;
      final function = ir.DefinedFunction.withoutBody(
          module, ir.FinalizableIndex()..value = imported.length + i, type);
      defined.add(function);
    }
    return ir.Functions.withoutDeclared(imported, defined);
  }
}

class TableSection extends Section {
  static const int sectionId = 4;

  final List<ir.DefinedTable> tables;

  TableSection(this.tables, super.watchPOints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (tables.isNotEmpty) {
      s.writeList(tables);
    }
  }

  static ir.Tables deserialize(Deserializer? d, ir.Module module,
      ir.Types types, List<ir.ImportedTable> imported) {
    if (d == null) return ir.Tables(imported, []);

    final defined = <ir.DefinedTable>[];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final type = ir.RefType.deserialize(d, types.defined);
      final limits = d.readByte();
      final minSize = d.readUnsigned();
      final maxSize = limits == 0x01 ? d.readUnsigned() : null;
      final table = ir.DefinedTable(
          module,
          [],
          ir.FinalizableIndex()..value = imported.length + i,
          type,
          minSize,
          maxSize);
      defined.add(table);
    }
    return ir.Tables(imported, defined);
  }
}

class MemorySection extends Section {
  static const int sectionId = 5;

  final List<ir.DefinedMemory> memories;

  MemorySection(this.memories, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (memories.isNotEmpty) {
      s.writeList(memories);
    }
  }

  static ir.Memories deserialize(
      Deserializer? d, ir.Module module, List<ir.ImportedMemory> imported) {
    if (d == null) return ir.Memories(imported, []);

    final defined = <ir.DefinedMemory>[];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final limits = d.readByte();
      final shared = limits == 0x03;
      final minSize = d.readUnsigned();
      final maxSize =
          limits == 0x01 || limits == 0x03 ? d.readUnsigned() : null;
      final memory = ir.DefinedMemory(
          module,
          ir.FinalizableIndex()..value = imported.length + i,
          shared,
          minSize,
          maxSize);
      defined.add(memory);
    }
    return ir.Memories(imported, defined);
  }
}

class TagSection extends Section {
  static const int sectionId = 13;

  final List<ir.DefinedTag> tags;

  TagSection(this.tags, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (tags.isNotEmpty) {
      s.writeList(tags);
    }
  }

  static ir.Tags deserialize(Deserializer? d, ir.Module module, ir.Types types,
      List<ir.ImportedTag> imported) {
    if (d == null) return ir.Tags([], imported);

    final defined = <ir.DefinedTag>[];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final attribute = d.readByte();
      if (attribute != 0) {
        throw "Invalid tag attribute: $attribute";
      }
      final type = types[d.readUnsigned()] as ir.FunctionType;
      final tag = ir.DefinedTag(
          module, ir.FinalizableIndex()..value = imported.length + i, type);
      defined.add(tag);
    }
    return ir.Tags(defined, []);
  }
}

class GlobalSection extends Section {
  static const int sectionId = 6;

  final List<ir.DefinedGlobal> globals;

  GlobalSection(this.globals, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (globals.isNotEmpty) {
      s.writeList(globals);
    }
  }

  static ir.Globals deserialize(
      Deserializer? d,
      ir.Module module,
      ir.Types types,
      ir.Functions functions,
      List<ir.ImportedGlobal> imported) {
    if (d == null) {
      return ir.Globals(imported, []);
    }

    final globals = ir.Globals(imported, []);

    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final type = ir.GlobalType.deserialize(d, types.defined);
      final initializer =
          ir.Instructions.deserializeConst(d, types, functions, globals);
      final global = ir.DefinedGlobal(module, initializer,
          ir.FinalizableIndex()..value = globals.length, type);
      globals.defined.add(global);
    }
    return globals;
  }
}

class ExportSection extends Section {
  static const int sectionId = 7;

  final List<ir.Export> exports;

  ExportSection(this.exports, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (exports.isNotEmpty) {
      s.writeList(exports);
    }
  }

  static ir.Exports deserialize(
      Deserializer? d,
      ir.Functions functions,
      ir.Tables tables,
      ir.Memories memories,
      ir.Globals globals,
      ir.Tags tags) {
    if (d == null) {
      return ir.Exports([]);
    }

    final exports = <ir.Export>[];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final name = d.readName();
      final kind = d.readByte();
      final index = d.readUnsigned();
      switch (kind) {
        case 0x00:
          exports.add(ir.FunctionExport(name, functions[index]));
          break;
        case 0x01:
          exports.add(ir.TableExport(name, tables[index]));
          break;
        case 0x02:
          exports.add(ir.MemoryExport(name, memories[index]));
          break;
        case 0x03:
          exports.add(ir.GlobalExport(name, globals[index]));
          break;
        case 0x04:
          exports.add(ir.TagExport(name, tags[index]));
          break;
        default:
          throw "Invalid export kind: $kind";
      }
    }
    return ir.Exports(exports);
  }
}

class StartSection extends Section {
  static const int sectionId = 8;

  final ir.BaseFunction? startFunction;

  StartSection(this.startFunction, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (startFunction != null) {
      s.writeUnsigned(startFunction!.index);
    }
  }

  static ir.BaseFunction? deserialize(Deserializer? d, ir.Functions functions) {
    if (d == null) {
      return null;
    }
    return functions[d.readUnsigned()];
  }
}

sealed class _Element implements Serializable {}

class _TableElement implements _Element {
  final ir.Table table;
  final int startIndex;
  final List<ir.BaseFunction> entries = [];

  _TableElement(this.table, this.startIndex);

  @override
  void serialize(Serializer s) {
    final int kind;
    if (table.index == 0) {
      kind = 0x00;
      s.writeByte(kind);
    } else {
      kind = 0x06;
      s.writeByte(kind);
      s.writeUnsigned(table.index);
    }

    ir.I32Const(startIndex).serialize(s);
    ir.End().serialize(s);

    if (kind == 0x06) {
      s.write(table.type);
    }
    s.writeUnsigned(entries.length);
    for (var entry in entries) {
      if (kind == 0x0) {
        s.writeUnsigned(entry.index);
      } else {
        ir.RefFunc(entry).serialize(s);
        ir.End().serialize(s);
      }
    }
  }

  static _TableElement deserialize(
    Deserializer d,
    ir.Module module,
    ir.Types types,
    ir.Functions functions,
    ir.Tables tables,
    ir.Globals globals,
  ) {
    final int tableIndex;
    final kind = d.readByte();
    switch (kind) {
      case 0x00:
        tableIndex = 0;
        break;
      case 0x06:
        tableIndex = d.readUnsigned();
        break;
      default:
        throw "unsupported element segment kind $kind";
    }

    final i0 = ir.Instruction.deserializeConst(d, types, functions, globals);
    final i1 = ir.Instruction.deserializeConst(d, types, functions, globals);
    if (i0 is! ir.I32Const || i1 is! ir.End) {
      throw StateError('Expected offset to be encoded as '
          '`(i32.const <value>) (end)`. '
          'Got instead: (${i0.name}) (${i1.name})');
    }
    final offset = i0.value;

    if (kind == 0x06) {
      ir.RefType.deserialize(d, types.defined);
    }

    final table = tables[tableIndex];
    final tableElement = _TableElement(table, offset);
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      if (kind == 0x0) {
        tableElement.entries.add(functions[d.readUnsigned()]);
      } else {
        final i0 =
            ir.Instruction.deserializeConst(d, types, functions, globals);
        final i1 =
            ir.Instruction.deserializeConst(d, types, functions, globals);
        if (i0 is! ir.RefFunc || i1 is! ir.End) {
          throw StateError('Expected function reference to be encoded as '
              '`(ref.func <value>) (end)`. '
              'Got instead: (${i0.name}) (${i1.name})');
        }
        tableElement.entries.add(i0.function);
      }
    }
    return tableElement;
  }
}

class _DeclaredElement implements _Element {
  final List<ir.BaseFunction> entries;

  _DeclaredElement(this.entries);

  @override
  void serialize(Serializer s) {
    if (entries.isEmpty) return;
    s.writeByte(0x03);
    s.writeByte(0x00);

    s.writeUnsigned(entries.length);
    for (final entry in entries) {
      s.writeUnsigned(entry.index);
    }
  }

  static _DeclaredElement deserialize(Deserializer d, ir.Functions functions) {
    if (d.readByte() != 0x03) throw 'bad encoding';

    final elemkind = d.readByte();
    if (elemkind != 0x00) throw "unsupported elemkind";

    final declaredFunctions = d.readList((d) => functions[d.readUnsigned()]);
    return _DeclaredElement(declaredFunctions);
  }
}

class ElementSection extends Section {
  static const int sectionId = 9;

  final List<ir.DefinedTable> definedTables;
  final List<ir.ImportedTable> importedTables;
  final List<ir.BaseFunction> declaredFunctions;

  ElementSection(this.definedTables, this.importedTables,
      this.declaredFunctions, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    // Group nonempty element entries into contiguous stretches and serialize
    // each stretch as an element.
    List<_Element> elements = [];
    for (final table in definedTables) {
      _TableElement? current;
      for (int i = 0; i < table.elements.length; i++) {
        ir.BaseFunction? function = table.elements[i];
        if (function != null) {
          if (current == null) {
            current = _TableElement(table, i);
            elements.add(current);
          }
          current.entries.add(function);
        } else {
          current = null;
        }
      }
    }
    for (final table in importedTables) {
      final entries = [...table.setElements.entries]
        ..sort((a, b) => a.key.compareTo(b.key));

      _TableElement? current;
      int lastIndex = -2;
      for (final entry in entries) {
        final index = entry.key;
        final function = entry.value;
        if (index != lastIndex + 1) {
          current = _TableElement(table, index);
          elements.add(current);
        }
        current!.entries.add(function);
        lastIndex = index;
      }
    }
    if (declaredFunctions.isNotEmpty) {
      elements.add(_DeclaredElement(declaredFunctions));
    }
    if (elements.isNotEmpty) {
      s.writeList(elements);
    }
  }

  static void deserialize(
    Deserializer? d,
    ir.Module module,
    ir.Types types,
    ir.Functions functions,
    ir.Tables tables,
    ir.Globals globals,
  ) {
    if (d == null) {
      functions.declared = [];
      return;
    }
    final declaredFunctions = <ir.BaseFunction>[];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      if (d.peekByte() == 0x03) {
        final declaredElement = _DeclaredElement.deserialize(d, functions);
        declaredFunctions.addAll(declaredElement.entries);
        continue;
      }
      final tableElement = _TableElement.deserialize(
          d, module, types, functions, tables, globals);
      for (int i = 0; i < tableElement.entries.length; i++) {
        final table = tableElement.table;
        final offset = tableElement.startIndex;
        final function = tableElement.entries[i];

        if (table is ir.DefinedTable) {
          if (table.elements.length <= offset + i) {
            table.elements.length = offset + i + 1;
          }
          table.elements[offset + i] = function;
        } else if (table is ir.ImportedTable) {
          table.setElements[offset + i] = function;
        } else {
          throw "unsupported table type $table";
        }
      }
    }

    functions.declared = declaredFunctions;
  }
}

class DataCountSection extends Section {
  static const int sectionId = 12;

  final List<ir.DataSegment> dataSegments;

  DataCountSection(this.dataSegments, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (dataSegments.isNotEmpty) {
      s.writeUnsigned(dataSegments.length);
    }
  }

  static ir.DataSegments deserialize(Deserializer? d) {
    if (d == null) {
      return ir.DataSegments([]);
    }
    final count = d.readUnsigned();
    final uninitializedSegments = [
      for (int i = 0; i < count; ++i) ir.DataSegment.uninitialized()
    ];
    return ir.DataSegments(uninitializedSegments);
  }
}

class CodeSection extends Section {
  static const int sectionId = 10;

  final List<ir.DefinedFunction> functions;

  CodeSection(this.functions, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (functions.isNotEmpty) {
      s.writeList(functions);
    }
  }

  static void deserialize(
    Deserializer? d,
    List<ir.DefinedFunction> definedFunctions,
    ir.Module module,
    ir.Types types,
    ir.Functions functions,
    ir.Tables tables,
    ir.Memories memories,
    ir.Tags tags,
    ir.Globals globals,
    ir.DataSegments dataSegments,
  ) {
    if (d == null) {
      return;
    }

    final count = d.readUnsigned();
    if (count != functions.defined.length) {
      throw "Code count mismatch";
    }
    for (int i = 0; i < count; i++) {
      final function = definedFunctions[i];
      final type = function.type;

      final locals = <ir.Local>[
        // Parameters
        for (int i = 0; i < type.inputs.length; ++i)
          ir.Local(i, type.inputs[i]),
      ];
      final instructions = <ir.Instruction>[];

      final bodySize = d.readUnsigned();
      final bodyDeserializer = Deserializer(d.readBytes(bodySize));

      final localDeclCount = bodyDeserializer.readUnsigned();
      for (int j = 0; j < localDeclCount; j++) {
        final localCount = bodyDeserializer.readUnsigned();
        final type = ir.ValueType.deserialize(bodyDeserializer, types.defined);
        for (int k = 0; k < localCount; k++) {
          locals.add(ir.Local(locals.length, type));
        }
      }
      while (!bodyDeserializer.isAtEnd) {
        final instruction = ir.Instruction.deserialize(bodyDeserializer, types,
            tables, tags, globals, dataSegments, memories, functions);
        instructions.add(instruction);
      }

      function.body = ir.Instructions(locals, {}, instructions, null, [], []);
    }
  }
}

class DataSection extends Section {
  static const int sectionId = 11;

  final List<ir.DataSegment> dataSegments;

  DataSection(this.dataSegments, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (dataSegments.isNotEmpty) {
      s.writeList(dataSegments);
    }
  }

  static void deserialize(
      Deserializer? d, ir.DataSegments dataSegments, ir.Memories memories) {
    final defined = dataSegments.defined;
    if (d == null) {
      assert(defined.isEmpty);
      return;
    }

    final count = d.readUnsigned();
    if (defined.length != count) {
      throw "Mismatch number of data segments";
    }
    for (int i = 0; i < count; i++) {
      final mode = d.readByte();
      if (mode == 0x1) {
        // Passive segment.
        final length = d.readUnsigned();
        final content = d.readBytes(length);
        defined[i]
          ..index = i
          ..memory = null
          ..offset = null
          ..content = content;
        continue;
      }

      ir.Memory? memory;
      int? offset;
      if (mode == 0x00 || mode == 0x02) {
        if (mode == 0x00) {
          memory = memories[0];
        } else if (mode == 0x02) {
          // Active segment
          final memoryIndex = d.readUnsigned();
          memory = memories[memoryIndex];
        }

        final i32ConstByte = d.readByte();
        if (i32ConstByte != 0x41) throw 'bad encoding';
        offset = d.readSigned();
        final endByte = d.readByte();
        if (endByte != 0x0B) throw 'bad encoding';

        // final offsetInitializer = ir.Instructions.deserialize(d, module);
        // offset = (offsetInitializer.instructions.single as ir.I32Const).value;
      }
      final content = d.readBytes(d.readUnsigned());
      defined[i]
        ..index = i
        ..memory = memory
        ..offset = offset
        ..content = content;
    }
  }
}

abstract class CustomSection extends Section {
  static const int sectionId = 0;

  CustomSection(super.watchPoints);

  @override
  int get id => sectionId;
}

class NameSection extends CustomSection {
  static const String customSectionName = 'name';

  final String? moduleName;
  final List<ir.BaseFunction> functions;
  final List<List<ir.DefType>> types;
  final List<ir.Global> globals;

  NameSection(
    this.moduleName,
    this.functions,
    this.types,
    this.globals,
    super.watchPoints,
  );

  @override
  void serializeContents(Serializer s) {
    final moduleNameSubsection = Serializer();
    if (moduleName != null) {
      moduleNameSubsection.writeName(moduleName!);
    }

    int functionNameCount = 0;
    final functionNames = Serializer();
    for (int i = 0; i < functions.length; i++) {
      final String? functionName = functions[i].functionName;
      if (functionName != null) {
        functionNames.writeUnsigned(i);
        functionNames.writeName(functionName);
        functionNameCount++;
      }
    }

    int typeIndex = 0;
    int typeNameCount = 0;
    final typeNames = Serializer();
    int typesWithNamedFieldsCount = 0;
    final fieldNames = Serializer();
    for (final recursionGroup in types) {
      for (final defType in recursionGroup) {
        if (defType is ir.DataType) {
          final name = defType.name;
          if (name != null) {
            typeNames.writeUnsigned(typeIndex);
            typeNames.writeName(name);
            typeNameCount++;
            if (defType is ir.StructType && defType.fieldNames.isNotEmpty) {
              fieldNames.writeUnsigned(typeIndex);
              fieldNames.writeUnsigned(defType.fieldNames.length);
              for (final entry in defType.fieldNames.entries) {
                fieldNames.writeUnsigned(entry.key);
                fieldNames.writeName(entry.value);
              }
              typesWithNamedFieldsCount++;
            }
          }
        }
        typeIndex++;
      }
    }

    int globalNameCount = 0;
    final globalNames = Serializer();
    for (int i = 0; i < globals.length; i++) {
      final globalName = globals[i].globalName;
      if (globalName != null) {
        globalNames.writeUnsigned(i);
        globalNames.writeName(globalName);
        globalNameCount++;
      }
    }

    int functionsWithLocalNamesCount = 0;
    final localNames = Serializer();
    for (final function in functions) {
      if (function is ir.DefinedFunction) {
        if (function.localNames.isNotEmpty) {
          localNames.writeUnsigned(function.finalizableIndex.value);
          localNames.writeUnsigned(function.localNames.length);
          for (final entry in function.localNames.entries) {
            localNames.writeUnsigned(entry.key);
            localNames.writeName(entry.value);
          }
          functionsWithLocalNamesCount++;
        }
      }
    }

    s.writeName(customSectionName);

    s.writeByte(0); // Module name subsection
    if (moduleNameSubsection.offset > 0) {
      s.writeUnsigned(moduleNameSubsection.data.length);
      s.writeData(moduleNameSubsection);
    }

    if (functionNameCount > 0) {
      s.writeByte(1); // Function names subsection
      s.writeUnsigned(functionNames.data.length +
          Serializer.writeUnsignedByteCount(functionNameCount));
      s.writeUnsigned(functionNameCount);
      s.writeData(functionNames);
    }

    if (functionsWithLocalNamesCount > 0) {
      s.writeByte(2); // Local names substion
      s.writeUnsigned(localNames.data.length +
          Serializer.writeUnsignedByteCount(functionsWithLocalNamesCount));
      s.writeUnsigned(functionsWithLocalNamesCount);
      s.writeData(localNames);
    }

    if (typeNameCount > 0) {
      s.writeByte(4); // Type names subsection
      s.writeUnsigned(typeNames.data.length +
          Serializer.writeUnsignedByteCount(typeNameCount));
      s.writeUnsigned(typeNameCount);
      s.writeData(typeNames);
    }

    if (globalNameCount > 0) {
      s.writeByte(7); // Global names subsection
      s.writeUnsigned(globalNames.data.length +
          Serializer.writeUnsignedByteCount(globalNameCount));
      s.writeUnsigned(globalNameCount);
      s.writeData(globalNames);
    }

    if (typesWithNamedFieldsCount > 0) {
      s.writeByte(10); // Field names subsection
      s.writeUnsigned(fieldNames.data.length +
          Serializer.writeUnsignedByteCount(typesWithNamedFieldsCount));
      s.writeUnsigned(typesWithNamedFieldsCount);
      s.writeData(fieldNames);
    }
  }

  static String? deserialize(Deserializer? d, ir.Functions functions,
      ir.Types types, ir.Globals globals) {
    String? moduleName;

    if (d == null) {
      return moduleName;
    }

    while (!d.isAtEnd) {
      final subsectionId = d.readByte();
      final subsectionSize = d.readUnsigned();
      final subsectionDeserializer = Deserializer(d.readBytes(subsectionSize));
      switch (subsectionId) {
        case 0: // Module name
          moduleName = subsectionDeserializer.readName();
          break;
        case 1: // Function names
          final count = subsectionDeserializer.readUnsigned();
          for (int i = 0; i < count; i++) {
            final funcIndex = subsectionDeserializer.readUnsigned();
            final funcName = subsectionDeserializer.readName();
            final func = functions[funcIndex];
            func.functionName = funcName;
          }
          break;
        case 2: // Local names
          final funcCount = subsectionDeserializer.readUnsigned();
          for (int i = 0; i < funcCount; i++) {
            final funcIndex = subsectionDeserializer.readUnsigned();
            final localCount = subsectionDeserializer.readUnsigned();
            final func = functions[funcIndex];
            if (func is ir.DefinedFunction) {
              for (int j = 0; j < localCount; j++) {
                final localIndex = subsectionDeserializer.readUnsigned();
                final localName = subsectionDeserializer.readName();
                func.body.localNames[localIndex] = localName;
              }
            } else {
              // Skip local names for imported functions
              for (int j = 0; j < localCount; j++) {
                subsectionDeserializer.readUnsigned();
                subsectionDeserializer.readName();
              }
            }
          }
          break;
        case 4: // Type names
          final count = subsectionDeserializer.readUnsigned();
          for (int i = 0; i < count; i++) {
            final typeIndex = subsectionDeserializer.readUnsigned();
            final typeName = subsectionDeserializer.readName();
            final type = types[typeIndex];
            if (type is ir.DataType) {
              type.name = typeName;
            }
          }
          break;
        case 7: // Global names
          final count = subsectionDeserializer.readUnsigned();
          for (int i = 0; i < count; i++) {
            final globalIndex = subsectionDeserializer.readUnsigned();
            final globalName = subsectionDeserializer.readName();
            globals[globalIndex].globalName = globalName;
          }
          break;
        case 10: // Field names
          final typeCount = subsectionDeserializer.readUnsigned();
          for (int i = 0; i < typeCount; i++) {
            final typeIndex = subsectionDeserializer.readUnsigned();
            final fieldCount = subsectionDeserializer.readUnsigned();
            final type = types[typeIndex];
            if (type is ir.StructType) {
              for (int j = 0; j < fieldCount; j++) {
                final fieldIndex = subsectionDeserializer.readUnsigned();
                final fieldName = subsectionDeserializer.readName();
                type.fieldNames[fieldIndex] = fieldName;
              }
            } else {
              throw 'unexpected field name of non struct';
            }
          }
          break;
      }
    }
    return moduleName;
  }
}

class SourceMapSection extends CustomSection {
  static const String customSectionName = 'sourceMappingURL';

  final Uri? url;

  SourceMapSection(this.url) : super([]);

  @override
  void serializeContents(Serializer s) {
    if (url != null) {
      s.writeName(customSectionName);
      s.writeName(url!.toString());
    }
  }

  static Uri? deserialize(Deserializer? d) {
    if (d == null) {
      return null;
    }
    return Uri.parse(d.readName());
  }
}
