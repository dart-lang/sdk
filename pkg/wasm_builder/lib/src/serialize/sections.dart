// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
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
  final ir.Types types;

  TypeSection(this.types, super.watchPoints);

  List<List<ir.DefType>> get recursionGroups => types.recursionGroups;

  @override
  int get id => 1;

  @override
  void serializeContents(Serializer s) {
    if (types.recursionGroups.isNotEmpty) {
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
        s.writeByte(0x4E); // -0x32
        s.writeUnsigned(group.length);
        for (final type in group) {
          assert(
              type.superType == null ||
                  type.superType!.index <= group.last.index,
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
  }
}

class ImportSection extends Section {
  final List<ir.Import> imports;

  ImportSection(this.imports, super.watchPoints);

  @override
  int get id => 2;

  @override
  void serializeContents(Serializer s) {
    if (imports.isNotEmpty) {
      s.writeList(imports);
    }
  }
}

class FunctionSection extends Section {
  final List<ir.DefinedFunction> functions;

  FunctionSection(this.functions, super.watchPoints);

  @override
  int get id => 3;

  @override
  void serializeContents(Serializer s) {
    if (functions.isNotEmpty) {
      s.writeUnsigned(functions.length);
      for (final function in functions) {
        s.writeUnsigned(function.type.index);
      }
    }
  }
}

class TableSection extends Section {
  final List<ir.DefinedTable> tables;

  TableSection(this.tables, super.watchPOints);

  @override
  int get id => 4;

  @override
  void serializeContents(Serializer s) {
    if (tables.isNotEmpty) {
      s.writeList(tables);
    }
  }
}

class MemorySection extends Section {
  final List<ir.DefinedMemory> memories;

  MemorySection(this.memories, super.watchPoints);

  @override
  int get id => 5;

  @override
  void serializeContents(Serializer s) {
    if (memories.isNotEmpty) {
      s.writeList(memories);
    }
  }
}

class TagSection extends Section {
  final List<ir.DefinedTag> tags;

  TagSection(this.tags, super.watchPoints);

  @override
  int get id => 13;

  @override
  void serializeContents(Serializer s) {
    if (tags.isNotEmpty) {
      s.writeList(tags);
    }
  }
}

class GlobalSection extends Section {
  final List<ir.DefinedGlobal> globals;

  GlobalSection(this.globals, super.watchPoints);

  @override
  int get id => 6;

  @override
  void serializeContents(Serializer s) {
    if (globals.isNotEmpty) {
      s.writeList(globals);
    }
  }
}

class ExportSection extends Section {
  final List<ir.Export> exports;

  ExportSection(this.exports, super.watchPoints);

  @override
  int get id => 7;

  @override
  void serializeContents(Serializer s) {
    if (exports.isNotEmpty) {
      s.writeList(exports);
    }
  }
}

class StartSection extends Section {
  final ir.BaseFunction? startFunction;

  StartSection(this.startFunction, super.watchPoints);

  @override
  int get id => 8;

  @override
  void serializeContents(Serializer s) {
    if (startFunction != null) {
      s.writeUnsigned(startFunction!.index);
    }
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
    if (table.index != 0) {
      s.writeByte(0x06);
      s.writeUnsigned(table.index);
    } else {
      s.writeByte(0x00);
    }
    s.writeByte(0x41); // i32.const
    s.writeSigned(startIndex);
    s.writeByte(0x0B); // end
    if (table.index != 0) {
      s.write(table.type);
    }
    s.writeUnsigned(entries.length);
    for (var entry in entries) {
      if (table.index == 0) {
        s.writeUnsigned(entry.index);
      } else {
        s.writeByte(0xD2); // ref.func
        s.writeSigned(entry.index);
        s.writeByte(0x0B); // end
      }
    }
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
}

class ElementSection extends Section {
  final List<ir.DefinedTable> definedTables;
  final List<ir.ImportedTable> importedTables;
  final List<ir.BaseFunction> declaredFunctions;

  ElementSection(this.definedTables, this.importedTables,
      this.declaredFunctions, super.watchPoints);

  @override
  int get id => 9;

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
    for (final func in declaredFunctions) {
      elements.add(_DeclaredElement([func]));
    }
    if (elements.isNotEmpty) {
      s.writeList(elements);
    }
  }
}

class DataCountSection extends Section {
  final List<ir.DataSegment> dataSegments;

  DataCountSection(this.dataSegments, super.watchPoints);

  @override
  int get id => 12;

  @override
  void serializeContents(Serializer s) {
    if (dataSegments.isNotEmpty) {
      s.writeUnsigned(dataSegments.length);
    }
  }
}

class CodeSection extends Section {
  final List<ir.DefinedFunction> functions;

  CodeSection(this.functions, super.watchPoints);

  @override
  int get id => 10;

  @override
  void serializeContents(Serializer s) {
    if (functions.isNotEmpty) {
      s.writeList(functions);
    }
  }
}

class DataSection extends Section {
  final List<ir.DataSegment> dataSegments;

  DataSection(this.dataSegments, super.watchPoints);

  @override
  int get id => 11;

  @override
  void serializeContents(Serializer s) {
    if (dataSegments.isNotEmpty) {
      s.writeList(dataSegments);
    }
  }
}

abstract class CustomSection extends Section {
  CustomSection(super.watchPoints);

  @override
  int get id => 0;
}

class NameSection extends CustomSection {
  final String moduleName;
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
    moduleNameSubsection.writeName(moduleName);

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

    s.writeName("name"); // Name of the custom section.

    s.writeByte(0); // Module name subsection
    s.writeUnsigned(moduleNameSubsection.data.length);
    s.writeData(moduleNameSubsection);

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
}

class SourceMapSection extends CustomSection {
  final Uri? url;

  SourceMapSection(this.url) : super([]);

  @override
  void serializeContents(Serializer s) {
    if (url != null) {
      s.writeName("sourceMappingURL");
      s.writeName(url!.toString());
    }
  }
}
