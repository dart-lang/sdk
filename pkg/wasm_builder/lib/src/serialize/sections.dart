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

  List<ir.DefType> get defTypes => types.defined;

  @override
  int get id => 1;

  @override
  bool get isNotEmpty => defTypes.isNotEmpty;

  @override
  void serializeContents(Serializer s) {
    s.writeUnsigned(types.recursionGroupSplits.length + 1);
    int typeIndex = 0;
    for (int split
        in types.recursionGroupSplits.followedBy([defTypes.length])) {
      s.writeByte(0x4E); // -0x32
      s.writeUnsigned(split - typeIndex);
      for (; typeIndex < split; typeIndex++) {
        ir.DefType defType = defTypes[typeIndex];
        assert(defType.superType == null || defType.superType!.index < split,
            "Type '$defType' has a supertype in a later recursion group");
        assert(
            defType.constituentTypes
                .whereType<ir.RefType>()
                .map((t) => t.heapType)
                .whereType<ir.DefType>()
                .every((d) => d.index < split),
            "Type '$defType' depends on a type in a later recursion group");
        defType.serializeDefinition(s);
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
  final List<ir.Tag> tags;

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

class _Element implements Serializable {
  final ir.Table table;
  final int startIndex;
  final List<ir.BaseFunction> entries = [];

  _Element(this.table, this.startIndex);

  @override
  void serialize(Serializer s) {
    if (table.index != 0) {
      s.writeByte(0x02);
      s.writeUnsigned(table.index);
    } else {
      s.writeByte(0x00);
    }
    s.writeByte(0x41); // i32.const
    s.writeSigned(startIndex);
    s.writeByte(0x0B); // end
    if (table.index != 0) {
      s.writeByte(0x00); // elemkind
    }
    s.writeUnsigned(entries.length);
    for (var entry in entries) {
      s.writeUnsigned(entry.index);
    }
  }
}

class ElementSection extends Section {
  final List<ir.DefinedTable> tables;

  ElementSection(this.tables, super.watchPoints);

  @override
  int get id => 9;

  @override
  bool get isNotEmpty =>
      tables.any((table) => table.elements.any((e) => e != null));

  @override
  void serializeContents(Serializer s) {
    // Group nonempty element entries into contiguous stretches and serialize
    // each stretch as an element.
    List<_Element> elements = [];
    for (final table in tables) {
      _Element? current;
      for (int i = 0; i < table.elements.length; i++) {
        ir.BaseFunction? function = table.elements[i];
        if (function != null) {
          if (current == null) {
            current = _Element(table, i);
            elements.add(current);
          }
          current.entries.add(function);
        } else {
          current = null;
        }
      }
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
  final List<ir.BaseFunction> functions;
  final List<ir.DefType> types;
  final int functionNameCount;
  final int typeNameCount;

  NameSection(this.functions, this.types, super.watchPoints,
      {required this.functionNameCount, required this.typeNameCount});

  @override
  bool get isNotEmpty => functionNameCount > 0 || typeNameCount > 0;

  @override
  void serializeContents(Serializer s) {
    s.writeName("name");

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
    for (int i = 0; i < types.length; i++) {
      final ty = types[i];
      if (ty is ir.DataType) {
        typeNameSubsection.writeUnsigned(i);
        typeNameSubsection.writeName(ty.name);
      }
    }

    s.writeByte(1); // Function names subsection
    s.writeUnsigned(functionNameSubsection.data.length);
    s.writeData(functionNameSubsection);
    s.writeByte(4); // Type names subsection
    s.writeUnsigned(typeNameSubsection.data.length);
    s.writeData(typeNameSubsection);
  }
}
