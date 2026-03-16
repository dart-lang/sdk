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
    int typeIndex = 0;
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
        type.index = typeIndex++;
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
            final type = types[d.readUnsigned()] as ir.FunctionType;
            final tag = ir.ImportedTag(
                module, moduleName, name, ir.FinalizableIndex(), type);
            tag.finalizableIndex.value = importedTags.length;
            importedTags.add(tag);
            imports.add(tag);
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
      return ir.Functions(imported, []);
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
    return ir.Functions(imported, defined);
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
    if (d == null) return ir.Tags(imported, []);

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
    return ir.Tags(imported, defined);
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
      final export = switch (kind) {
        0x00 => ir.FunctionExport(name, functions[index]),
        0x01 => ir.TableExport(name, tables[index]),
        0x02 => ir.MemoryExport(name, memories[index]),
        0x03 => ir.GlobalExport(name, globals[index]),
        0x04 => ir.TagExport(name, tags[index]),
        _ => throw "Invalid export kind: $kind",
      };
      exports.add(export);
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

class ElementSection extends Section {
  static const int sectionId = 9;

  final ir.Elements elementSegments;

  ElementSection(this.elementSegments, super.watchPoints);

  @override
  int get id => sectionId;

  @override
  void serializeContents(Serializer s) {
    if (elementSegments.segments.isNotEmpty) {
      s.writeList(elementSegments.segments);
    }
  }

  static ir.Elements deserialize(
    Deserializer? d,
    ir.Module module,
    ir.Types types,
    ir.Functions functions,
    ir.Tables tables,
    ir.Globals globals,
  ) {
    if (d == null) {
      return ir.Elements([]);
    }

    final segments = <ir.ElementSegment>[];
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final byte = d.peekByte();
      if (byte == 0x03) {
        // Declarative segment, only to forward-declare functions.
        final es = ir.DeclarativeElementSegment.deserialize(d, functions);
        segments.add(es);
        continue;
      }
      if (byte == 0x00 || byte == 0x02) {
        // Active element, table values are function indices.
        final es = ir.ActiveFunctionElementSegment.deserialize(
            d, module, types, functions, tables, globals);
        segments.add(es);
        continue;
      }
      if (byte == 0x04 || byte == 0x06) {
        // Active element, table values are expressions.
        final es = ir.ActiveExpressionElementSegment.deserialize(
            d, module, types, functions, tables, globals);
        segments.add(es);
        continue;
      }
    }

    return ir.Elements(segments);
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
  final ir.Functions functions;
  final List<List<ir.DefType>> types;
  final ir.Globals globals;

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
    for (int i = 0; i < functions.length; i++) {
      final function = functions[i];
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

class RemovableIfUnusedSection extends CustomSection {
  static const String customSectionName = 'binaryen.removable.if.unused';

  final ir.Functions functions;

  RemovableIfUnusedSection(this.functions) : super([]);

  @override
  void serializeContents(Serializer s) {
    final functionsToAnnotate = [
      ...functions.imported.where((f) => f.isPure),
      ...functions.defined.where((f) => f.isPure),
    ];
    if (functionsToAnnotate.isNotEmpty) {
      s.writeName(customSectionName);
      s.writeUnsigned(functionsToAnnotate.length);
      for (final function in functionsToAnnotate) {
        s.writeUnsigned(function.index);
        s.writeUnsigned(1); // Number of hints
        s.writeUnsigned(0); // Offset (0 == function-level)
        s.writeUnsigned(0); // always 0
      }
    }
  }

  static void deserialize(Deserializer? d, ir.Functions functions) {
    if (d == null) return;

    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final functionIndex = d.readUnsigned();
      final numHints = d.readUnsigned();
      for (int j = 0; j < numHints; j++) {
        final offset = d.readUnsigned(); // Offset (0 == function-level)
        if (offset != 0) {
          throw UnsupportedError(
              'Only function-level ($customSectionName) annotation supported.');
        }
        final data = d.readUnsigned(); // always 0
        if (data != 0) {
          throw StateError('Expected 0 but got $data');
        }
        functions[functionIndex].isPure = true;
      }
    }
  }
}
