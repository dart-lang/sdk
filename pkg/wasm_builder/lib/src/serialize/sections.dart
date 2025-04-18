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
    if (isNotEmpty) {
      final contents = Serializer();
      serializeContents(contents);
      s.writeByte(id);
      s.writeUnsigned(contents.data.length);
      s.sourceMapSerializer
          .copyMappings(contents.sourceMapSerializer, s.offset);
      s.writeData(contents, watchPoints);
    }
  }

  int get id;

  bool get isNotEmpty;

  void serializeContents(Serializer s);
}

class TypeSection extends Section {
  final ir.Types types;

  TypeSection(this.types, super.watchPoints);

  List<List<ir.DefType>> get recursionGroups => types.recursionGroups;

  @override
  int get id => 1;

  @override
  bool get isNotEmpty => recursionGroups.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
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
}

class ImportSection extends Section {
  final List<ir.Import> imports;

  ImportSection(this.imports, super.watchPoints);

  @override
  int get id => 2;

  @override
  bool get isNotEmpty => imports.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(imports);
  }
}

class FunctionSection extends Section {
  final List<ir.DefinedFunction> functions;

  FunctionSection(this.functions, super.watchPoints);

  @override
  int get id => 3;

  @override
  bool get isNotEmpty => functions.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeUnsigned(functions.length);
    for (final function in functions) {
      s.writeUnsigned(function.type.index);
    }
  }
}

class TableSection extends Section {
  final List<ir.DefinedTable> tables;

  TableSection(this.tables, super.watchPOints);

  @override
  int get id => 4;

  @override
  bool get isNotEmpty => tables.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(tables);
  }
}

class MemorySection extends Section {
  final List<ir.DefinedMemory> memories;

  MemorySection(this.memories, super.watchPoints);

  @override
  int get id => 5;

  @override
  bool get isNotEmpty => memories.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(memories);
  }
}

class TagSection extends Section {
  final List<ir.DefinedTag> tags;

  TagSection(this.tags, super.watchPoints);

  @override
  int get id => 13;

  @override
  bool get isNotEmpty => tags.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(tags);
  }
}

class GlobalSection extends Section {
  final List<ir.DefinedGlobal> globals;

  GlobalSection(this.globals, super.watchPoints);

  @override
  int get id => 6;

  @override
  bool get isNotEmpty => globals.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(globals);
  }
}

class ExportSection extends Section {
  final List<ir.Export> exports;

  ExportSection(this.exports, super.watchPoints);

  @override
  int get id => 7;

  @override
  bool get isNotEmpty => exports.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(exports);
  }
}

class StartSection extends Section {
  final ir.BaseFunction? startFunction;

  StartSection(this.startFunction, super.watchPoints);

  @override
  int get id => 8;

  @override
  bool get isNotEmpty => startFunction != null;

  @override
  void serializeContents(Serializer s) {
    s.writeUnsigned(startFunction!.index);
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
  bool get isNotEmpty =>
      definedTables.any((table) => table.elements.any((e) => e != null)) ||
      importedTables.any((table) => table.setElements.isNotEmpty) ||
      declaredFunctions.isNotEmpty;

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
    s.writeList(elements);
  }
}

class DataCountSection extends Section {
  final List<ir.DataSegment> dataSegments;

  DataCountSection(this.dataSegments, super.watchPoints);

  @override
  int get id => 12;

  @override
  bool get isNotEmpty => dataSegments.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeUnsigned(dataSegments.length);
  }
}

class CodeSection extends Section {
  final List<ir.DefinedFunction> functions;

  CodeSection(this.functions, super.watchPoints);

  @override
  int get id => 10;

  @override
  bool get isNotEmpty => functions.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(functions);
  }
}

class DataSection extends Section {
  final List<ir.DataSegment> dataSegments;

  DataSection(this.dataSegments, super.watchPoints);

  @override
  int get id => 11;

  @override
  bool get isNotEmpty => dataSegments.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeList(dataSegments);
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
  final int functionNameCount;
  final int typeNameCount;
  final int globalNameCount;
  final int typesWithNamedFieldsCount;

  NameSection(this.moduleName, this.functions, this.types, this.globals,
      super.watchPoints,
      {required this.functionNameCount,
      required this.typeNameCount,
      required this.globalNameCount,
      required this.typesWithNamedFieldsCount});

  @override
  bool get isNotEmpty => functionNameCount > 0 || typeNameCount > 0;

  @override
  void serializeContents(Serializer s) {
    s.writeName("name");

    final moduleNameSubsection = Serializer();
    moduleNameSubsection.writeName(moduleName);

    final functionNameSubsection = Serializer();
    functionNameSubsection.writeUnsigned(functionNameCount);
    for (int i = 0; i < functions.length; i++) {
      String? functionName = functions[i].functionName;
      if (functionName != null) {
        functionNameSubsection.writeUnsigned(i);
        functionNameSubsection.writeName(functionName);
      }
    }

    final typeNameSubsection = Serializer();
    typeNameSubsection.writeUnsigned(typeNameCount);
    {
      int typeIndex = 0;
      for (final recursionGroup in types) {
        for (final defType in recursionGroup) {
          if (defType is ir.DataType) {
            typeNameSubsection.writeUnsigned(typeIndex);
            typeNameSubsection.writeName(defType.name);
          }
          typeIndex += 1;
        }
      }
    }

    final globalNameSubsection = Serializer();
    globalNameSubsection.writeUnsigned(globalNameCount);
    for (int i = 0; i < globals.length; i++) {
      final globalName = globals[i].globalName;
      if (globalName != null) {
        globalNameSubsection.writeUnsigned(i);
        globalNameSubsection.writeName(globalName);
      }
    }

    final fieldNameSubsection = Serializer();
    fieldNameSubsection.writeUnsigned(typesWithNamedFieldsCount);

    if (typesWithNamedFieldsCount != 0) {
      int typeIndex = 0;
      for (final recursionGroup in types) {
        for (final defType in recursionGroup) {
          if (defType is ir.StructType && defType.fieldNames.isNotEmpty) {
            fieldNameSubsection.writeUnsigned(typeIndex);
            fieldNameSubsection.writeUnsigned(defType.fieldNames.length);
            for (final entry in defType.fieldNames.entries) {
              fieldNameSubsection.writeUnsigned(entry.key);
              fieldNameSubsection.writeName(entry.value);
            }
          }
          typeIndex += 1;
        }
      }
    }

    final localNameSubsection = Serializer();
    List<ir.DefinedFunction> functionsWithLocalNames = [];
    for (final function in functions) {
      if (function is ir.DefinedFunction) {
        if (function.localNames.isNotEmpty) {
          functionsWithLocalNames.add(function);
        }
      }
    }
    localNameSubsection.writeUnsigned(functionsWithLocalNames.length);

    if (functionsWithLocalNames.isNotEmpty) {
      for (final function in functionsWithLocalNames) {
        localNameSubsection.writeUnsigned(function.finalizableIndex.value);
        localNameSubsection.writeUnsigned(function.localNames.length);
        for (final entry in function.localNames.entries) {
          localNameSubsection.writeUnsigned(entry.key);
          localNameSubsection.writeName(entry.value);
        }
      }
    }

    s.writeByte(0); // Module name subsection
    s.writeUnsigned(moduleNameSubsection.data.length);
    s.writeData(moduleNameSubsection);

    s.writeByte(1); // Function names subsection
    s.writeUnsigned(functionNameSubsection.data.length);
    s.writeData(functionNameSubsection);

    s.writeByte(2); // Local names substion
    s.writeUnsigned(localNameSubsection.data.length);
    s.writeData(localNameSubsection);

    s.writeByte(4); // Type names subsection
    s.writeUnsigned(typeNameSubsection.data.length);
    s.writeData(typeNameSubsection);

    s.writeByte(7); // Global names subsection
    s.writeUnsigned(globalNameSubsection.data.length);
    s.writeData(globalNameSubsection);

    s.writeByte(10); // Field names subsection
    s.writeUnsigned(fieldNameSubsection.data.length);
    s.writeData(fieldNameSubsection);
  }
}

class SourceMapSection extends CustomSection {
  final String url;

  SourceMapSection(this.url) : super([]);

  @override
  bool get isNotEmpty => true;

  @override
  void serializeContents(Serializer s) {
    s.writeName("sourceMappingURL");
    s.writeName(url);
  }
}
