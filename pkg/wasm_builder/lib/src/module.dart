// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'instructions.dart';
import 'serialize.dart';
import 'types.dart';

/// A Wasm module.
///
/// Serves as a builder for building new modules.
class Module with SerializerMixin {
  final List<int>? watchPoints;

  final Map<_FunctionTypeKey, FunctionType> _functionTypeMap = {};

  final List<DefType> defTypes = [];
  final List<int> recursionGroupSplits = [];
  final List<BaseFunction> functions = [];
  final List<Table> tables = [];
  final List<Memory> memories = [];
  final List<Tag> tags = [];
  final List<DataSegment> dataSegments = [];
  final List<Global> globals = [];
  final List<Export> exports = [];
  BaseFunction? startFunction;

  bool anyFunctionsDefined = false;
  bool anyTablesDefined = false;
  bool anyMemoriesDefined = false;
  bool anyGlobalsDefined = false;
  bool dataReferencedFromGlobalInitializer = false;

  int functionNameCount = 0;
  int typeNameCount = 0;

  static const int memoryBlockSize = 0x10000;

  /// Create a new, initially empty, module.
  ///
  /// The [watchPoints] is a list of byte offsets within the final module of
  /// bytes to watch. When the module is serialized, the stack traces leading to
  /// the production of all watched bytes are printed. This can be used to debug
  /// runtime errors happening at specific offsets within the module.
  Module({this.watchPoints}) {
    if (watchPoints != null) {
      SerializerMixin.traceEnabled = true;
    }
  }

  /// All module imports (functions and globals).
  Iterable<Import> get imports => functions
      .whereType<Import>()
      .followedBy(tables.whereType<Import>())
      .followedBy(memories.whereType<Import>())
      .followedBy(globals.whereType<Import>());

  /// All functions defined in the module.
  Iterable<DefinedFunction> get definedFunctions =>
      functions.whereType<DefinedFunction>();

  /// All tables defined in the module.
  Iterable<DefinedTable> get definedTables => tables.whereType<DefinedTable>();

  /// All memories defined in the module.
  Iterable<DefinedMemory> get definedMemories =>
      memories.whereType<DefinedMemory>();

  /// All globals defined in the module.
  Iterable<DefinedGlobal> get definedGlobals =>
      globals.whereType<DefinedGlobal>();

  /// Add a new function type to the module.
  ///
  /// All function types are canonicalized, such that identical types become
  /// the same type definition in the module, assuming nominal type identity
  /// of all inputs and outputs.
  ///
  /// Inputs and outputs can't be changed after the function type is created.
  /// This means that recursive function types (without any non-function types
  /// on the recursion path) are not supported.
  FunctionType addFunctionType(
      Iterable<ValueType> inputs, Iterable<ValueType> outputs,
      {DefType? superType}) {
    final List<ValueType> inputList = List.unmodifiable(inputs);
    final List<ValueType> outputList = List.unmodifiable(outputs);
    final _FunctionTypeKey key = _FunctionTypeKey(inputList, outputList);
    return _functionTypeMap.putIfAbsent(key, () {
      final type = FunctionType(inputList, outputList, superType: superType)
        ..index = defTypes.length;
      defTypes.add(type);
      return type;
    });
  }

  /// Add a new struct type to the module.
  ///
  /// Fields can be added later, by adding to the [fields] list. This enables
  /// struct types to be recursive.
  StructType addStructType(String name,
      {Iterable<FieldType>? fields, DefType? superType}) {
    final type = StructType(name, fields: fields, superType: superType)
      ..index = defTypes.length;
    defTypes.add(type);
    typeNameCount += 1;
    return type;
  }

  /// Add a new array type to the module.
  ///
  /// The element type can be specified later. This enables array types to be
  /// recursive.
  ArrayType addArrayType(String name,
      {FieldType? elementType, DefType? superType}) {
    final type = ArrayType(name, elementType: elementType, superType: superType)
      ..index = defTypes.length;
    defTypes.add(type);
    typeNameCount += 1;
    return type;
  }

  /// Insert a recursion group split in the list of type definitions. Types can
  /// only reference other types in the same or earlier recursion groups.
  void splitRecursionGroup() {
    int typeCount = defTypes.length;
    if (typeCount > 0 &&
        (recursionGroupSplits.isEmpty ||
            recursionGroupSplits.last != typeCount)) {
      recursionGroupSplits.add(typeCount);
    }
  }

  /// Add a new function to the module with the given function type.
  ///
  /// The [DefinedFunction.body] must be completed (including the terminating
  /// `end`) before the module can be serialized.
  DefinedFunction addFunction(FunctionType type, [String? name]) {
    anyFunctionsDefined = true;
    if (name != null) functionNameCount++;
    final function = DefinedFunction(this, functions.length, type, name);
    functions.add(function);
    return function;
  }

  /// Add a new table to the module.
  DefinedTable addTable(RefType type, int minSize, [int? maxSize]) {
    anyTablesDefined = true;
    final table = DefinedTable(tables.length, type, minSize, maxSize);
    tables.add(table);
    return table;
  }

  /// Add a new memory to the module.
  DefinedMemory addMemory(bool shared, int minSize, [int? maxSize]) {
    anyMemoriesDefined = true;
    final memory = DefinedMemory(memories.length, shared, minSize, maxSize);
    memories.add(memory);
    return memory;
  }

  /// Add a new tag to the module.
  Tag addTag(FunctionType type) {
    final tag = Tag(tags.length, type);
    tags.add(tag);
    return tag;
  }

  /// Add a new data segment to the module.
  ///
  /// Either [memory] and [offset] must be both specified or both omitted. If
  /// they are specified, the segment becomes an *active* segment, otherwise it
  /// becomes a *passive* segment.
  ///
  /// If [initialContent] is specified, it defines the initial content of the
  /// segment. The content can be extended later.
  DataSegment addDataSegment(
      [Uint8List? initialContent, Memory? memory, int? offset]) {
    initialContent ??= Uint8List(0);
    assert((memory != null) == (offset != null));
    assert(memory == null ||
        offset! >= 0 &&
            offset + initialContent.length <= memory.minSize * memoryBlockSize);
    final DataSegment data =
        DataSegment(dataSegments.length, initialContent, memory, offset);
    dataSegments.add(data);
    return data;
  }

  /// Add a global variable to the module.
  ///
  /// The [DefinedGlobal.initializer] must be completed (including the
  /// terminating `end`) before the module can be serialized.
  DefinedGlobal addGlobal(GlobalType type) {
    anyGlobalsDefined = true;
    final global = DefinedGlobal(this, globals.length, type);
    globals.add(global);
    return global;
  }

  /// Import a function into the module.
  ///
  /// All imported functions must be specified before any functions are declared
  /// using [Module.addFunction].
  ImportedFunction importFunction(String module, String name, FunctionType type,
      [String? functionName]) {
    if (anyFunctionsDefined) {
      throw "All function imports must be specified before any definitions.";
    }
    if (functionName != null) functionNameCount++;
    final function =
        ImportedFunction(module, name, functions.length, type, functionName);
    functions.add(function);
    return function;
  }

  /// Import a table into the module.
  ///
  /// All imported tables must be specified before any tables are declared
  /// using [Module.addTable].
  ImportedTable importTable(
      String module, String name, RefType type, int minSize,
      [int? maxSize]) {
    if (anyTablesDefined) {
      throw "All table imports must be specified before any definitions.";
    }
    final table =
        ImportedTable(module, name, tables.length, type, minSize, maxSize);
    tables.add(table);
    return table;
  }

  /// Import a memory into the module.
  ///
  /// All imported memories must be specified before any memories are declared
  /// using [Module.addMemory].
  ImportedMemory importMemory(
      String module, String name, bool shared, int minSize,
      [int? maxSize]) {
    if (anyMemoriesDefined) {
      throw "All memory imports must be specified before any definitions.";
    }
    final memory =
        ImportedMemory(module, name, memories.length, shared, minSize, maxSize);
    memories.add(memory);
    return memory;
  }

  /// Import a global variable into the module.
  ///
  /// All imported globals must be specified before any globals are declared
  /// using [Module.addGlobal].
  ImportedGlobal importGlobal(String module, String name, GlobalType type) {
    if (anyGlobalsDefined) {
      throw "All global imports must be specified before any definitions.";
    }
    final global = ImportedGlobal(module, name, functions.length, type);
    globals.add(global);
    return global;
  }

  void _addExport(Export export) {
    assert(!exports.any((e) => e.name == export.name), export.name);
    exports.add(export);
  }

  /// Export a function from the module.
  ///
  /// All exports must have unique names.
  void exportFunction(String name, BaseFunction function) {
    function.exportedName = name;
    _addExport(FunctionExport(name, function));
  }

  /// Export a table from the module.
  ///
  /// All exports must have unique names.
  void exportTable(String name, Table table) {
    _addExport(TableExport(name, table));
  }

  /// Export a memory from the module.
  ///
  /// All exports must have unique names.
  void exportMemory(String name, Memory memory) {
    _addExport(MemoryExport(name, memory));
  }

  /// Export a global variable from the module.
  ///
  /// All exports must have unique names.
  void exportGlobal(String name, Global global) {
    exports.add(GlobalExport(name, global));
  }

  /// Serialize the module to its binary representation.
  Uint8List encode({bool emitNameSection = true}) {
    // Wasm module preamble: magic number, version 1.
    writeBytes(const [0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]);
    TypeSection(this).serialize(this);
    ImportSection(this).serialize(this);
    FunctionSection(this).serialize(this);
    TableSection(this).serialize(this);
    MemorySection(this).serialize(this);
    TagSection(this).serialize(this);
    if (dataReferencedFromGlobalInitializer) {
      DataCountSection(this).serialize(this);
    }
    GlobalSection(this).serialize(this);
    ExportSection(this).serialize(this);
    StartSection(this).serialize(this);
    ElementSection(this).serialize(this);
    if (!dataReferencedFromGlobalInitializer) {
      DataCountSection(this).serialize(this);
    }
    CodeSection(this).serialize(this);
    DataSection(this).serialize(this);
    if (emitNameSection) {
      NameSection(this).serialize(this);
    }
    return data;
  }
}

class _FunctionTypeKey {
  final List<ValueType> inputs;
  final List<ValueType> outputs;

  _FunctionTypeKey(this.inputs, this.outputs);

  @override
  bool operator ==(Object other) {
    if (other is! _FunctionTypeKey) return false;
    if (inputs.length != other.inputs.length) return false;
    if (outputs.length != other.outputs.length) return false;
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i] != other.inputs[i]) return false;
    }
    for (int i = 0; i < outputs.length; i++) {
      if (outputs[i] != other.outputs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int inputHash = 13;
    for (var input in inputs) {
      inputHash = inputHash * 17 + input.hashCode;
    }
    int outputHash = 23;
    for (var output in outputs) {
      outputHash = outputHash * 29 + output.hashCode;
    }
    return (inputHash * 2 + 1) * (outputHash * 2 + 1);
  }
}

/// An (imported or defined) function.
abstract class BaseFunction {
  final int index;
  final FunctionType type;
  final String? functionName;
  String? exportedName;

  BaseFunction(this.index, this.type, this.functionName);
}

/// A function defined in a module.
class DefinedFunction extends BaseFunction
    with SerializerMixin
    implements Serializable {
  /// All local variables defined in the function, including its inputs.
  List<Local> get locals => body.locals;

  /// The body of the function.
  late final Instructions body;

  DefinedFunction(Module module, super.index, super.type,
      [super.functionName]) {
    body = Instructions(module, type.outputs);
    for (ValueType paramType in type.inputs) {
      body.addLocal(paramType, isParameter: true);
    }
  }

  /// Add a local variable to the function.
  Local addLocal(ValueType type) => body.addLocal(type, isParameter: false);

  @override
  void serialize(Serializer s) {
    // Serialize locals internally first in order to compute the total size of
    // the serialized data.
    int paramCount = type.inputs.length;
    int entries = 0;
    for (int i = paramCount + 1; i <= locals.length; i++) {
      if (i == locals.length || locals[i - 1].type != locals[i].type) entries++;
    }
    writeUnsigned(entries);
    int start = paramCount;
    for (int i = paramCount + 1; i <= locals.length; i++) {
      if (i == locals.length || locals[i - 1].type != locals[i].type) {
        writeUnsigned(i - start);
        write(locals[i - 1].type);
        start = i;
      }
    }

    // Bundle locals and body
    assert(body.isComplete);
    s.writeUnsigned(data.length + body.data.length);
    s.writeData(this);
    s.writeData(body);
  }

  @override
  String toString() => exportedName ?? "#$index";
}

/// A local variable defined in a function.
class Local {
  final int index;
  final ValueType type;

  Local(this.index, this.type);

  @override
  String toString() => "$index";
}

/// An (imported or defined) table.
class Table implements Serializable {
  final int index;
  final RefType type;
  final int minSize;
  final int? maxSize;

  Table(this.index, this.type, this.minSize, this.maxSize);

  @override
  void serialize(Serializer s) {
    s.write(type);
    if (maxSize == null) {
      s.writeByte(0x00);
      s.writeUnsigned(minSize);
    } else {
      s.writeByte(0x01);
      s.writeUnsigned(minSize);
      s.writeUnsigned(maxSize!);
    }
  }
}

/// A table defined in a module.
class DefinedTable extends Table {
  final List<BaseFunction?> elements;

  DefinedTable(super.index, super.type, super.minSize, super.maxSize)
      : elements = List.filled(minSize, null);

  void setElement(int index, BaseFunction function) {
    assert(type == RefType.func(nullable: true),
        "Elements are only supported for funcref tables");
    elements[index] = function;
  }
}

/// An (imported or defined) memory.
class Memory {
  final int index;
  final bool shared;
  final int minSize;
  final int? maxSize;

  Memory(this.index, this.shared, this.minSize, [this.maxSize]) {
    if (shared && maxSize == null) {
      throw "Shared memory must specify a maximum size.";
    }
  }

  void _serializeLimits(Serializer s) {
    if (shared) {
      assert(maxSize != null);
      s.writeByte(0x03);
      s.writeUnsigned(minSize);
      s.writeUnsigned(maxSize!);
    } else if (maxSize == null) {
      s.writeByte(0x00);
      s.writeUnsigned(minSize);
    } else {
      s.writeByte(0x01);
      s.writeUnsigned(minSize);
      s.writeUnsigned(maxSize!);
    }
  }
}

/// A memory defined in a module.
class DefinedMemory extends Memory implements Serializable {
  DefinedMemory(super.index, super.shared, super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) => _serializeLimits(s);
}

/// A tag in a module.
class Tag implements Serializable {
  final int index;
  final FunctionType type;

  Tag(this.index, this.type);

  @override
  void serialize(Serializer s) {
    // 0 byte for exception.
    s.writeByte(0x00);
    s.write(type);
  }

  @override
  String toString() => "#$index";
}

/// A data segment in a module.
class DataSegment implements Serializable {
  final int index;
  final BytesBuilder content;
  final Memory? memory;
  final int? offset;

  DataSegment(this.index, Uint8List initialContent, this.memory, this.offset)
      : content = BytesBuilder()..add(initialContent);

  bool get isActive => memory != null;
  bool get isPassive => memory == null;

  int get length => content.length;

  /// Append content to the data segment.
  void append(Uint8List data) {
    content.add(data);
    assert(isPassive ||
        offset! >= 0 && offset! + content.length <= memory!.minSize);
  }

  @override
  void serialize(Serializer s) {
    if (memory != null) {
      // Active segment
      if (memory!.index == 0) {
        s.writeByte(0x00);
      } else {
        s.writeByte(0x02);
        s.writeUnsigned(memory!.index);
      }
      s.writeByte(0x41); // i32.const
      s.writeSigned(offset!);
      s.writeByte(0x0B); // end
    } else {
      // Passive segment
      s.writeByte(0x01);
    }
    s.writeUnsigned(content.length);
    s.writeBytes(content.toBytes());
  }
}

/// An (imported or defined) global variable.
abstract class Global {
  final int index;
  final GlobalType type;

  Global(this.index, this.type);

  @override
  String toString() => "$index";
}

/// A global variable defined in a module.
class DefinedGlobal extends Global implements Serializable {
  final Instructions initializer;

  DefinedGlobal(Module module, super.index, super.type)
      : initializer =
            Instructions(module, [type.type], isGlobalInitializer: true);

  @override
  void serialize(Serializer s) {
    assert(initializer.isComplete);
    s.write(type);
    s.writeData(initializer);
  }
}

/// Any import (function, table, memory or global).
abstract class Import implements Serializable {
  String get module;
  String get name;
}

/// An imported function.
class ImportedFunction extends BaseFunction implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedFunction(this.module, this.name, super.index, super.type,
      [super.functionName]);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x00);
    s.writeUnsigned(type.index);
  }

  @override
  String toString() => "$module.$name";
}

/// An imported table.
class ImportedTable extends Table implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedTable(this.module, this.name, super.index, super.type, super.minSize,
      super.maxSize);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x01);
    super.serialize(s);
  }
}

/// An imported memory.
class ImportedMemory extends Memory implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedMemory(this.module, this.name, super.index, super.shared,
      super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x02);
    _serializeLimits(s);
  }
}

/// An imported global variable.
class ImportedGlobal extends Global implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedGlobal(this.module, this.name, super.index, super.type);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x03);
    s.write(type);
  }
}

abstract class Export implements Serializable {
  final String name;

  Export(this.name);
}

class FunctionExport extends Export {
  final BaseFunction function;

  FunctionExport(super.name, this.function);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x00);
    s.writeUnsigned(function.index);
  }
}

class TableExport extends Export {
  final Table table;

  TableExport(super.name, this.table);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x01);
    s.writeUnsigned(table.index);
  }
}

class MemoryExport extends Export {
  final Memory memory;

  MemoryExport(super.name, this.memory);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x02);
    s.writeUnsigned(memory.index);
  }
}

class GlobalExport extends Export {
  final Global global;

  GlobalExport(super.name, this.global);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x03);
    s.writeUnsigned(global.index);
  }
}

abstract class Section with SerializerMixin implements Serializable {
  final Module module;

  Section(this.module);

  @override
  void serialize(Serializer s) {
    if (isNotEmpty) {
      serializeContents();
      s.writeByte(id);
      s.writeUnsigned(data.length);
      s.writeData(this, module.watchPoints);
    }
  }

  int get id;

  bool get isNotEmpty;

  void serializeContents();
}

class TypeSection extends Section {
  TypeSection(super.module);

  @override
  int get id => 1;

  @override
  bool get isNotEmpty => module.defTypes.isNotEmpty;

  @override
  void serializeContents() {
    writeUnsigned(module.recursionGroupSplits.length + 1);
    int typeIndex = 0;
    for (int split
        in module.recursionGroupSplits.followedBy([module.defTypes.length])) {
      writeByte(0x4F);
      writeUnsigned(split - typeIndex);
      for (; typeIndex < split; typeIndex++) {
        DefType defType = module.defTypes[typeIndex];
        assert(defType.superType == null || defType.superType!.index < split,
            "Type '$defType' has a supertype in a later recursion group");
        assert(
            defType.constituentTypes
                .whereType<RefType>()
                .map((t) => t.heapType)
                .whereType<DefType>()
                .every((d) => d.index < split),
            "Type '$defType' depends on a type in a later recursion group");
        defType.serializeDefinition(this);
      }
    }
  }
}

class ImportSection extends Section {
  ImportSection(super.module);

  @override
  int get id => 2;

  @override
  bool get isNotEmpty => module.imports.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.imports.toList());
  }
}

class FunctionSection extends Section {
  FunctionSection(super.module);

  @override
  int get id => 3;

  @override
  bool get isNotEmpty => module.definedFunctions.isNotEmpty;

  @override
  void serializeContents() {
    writeUnsigned(module.definedFunctions.length);
    for (var function in module.definedFunctions) {
      writeUnsigned(function.type.index);
    }
  }
}

class TableSection extends Section {
  TableSection(super.module);

  @override
  int get id => 4;

  @override
  bool get isNotEmpty => module.definedTables.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.definedTables.toList());
  }
}

class MemorySection extends Section {
  MemorySection(super.module);

  @override
  int get id => 5;

  @override
  bool get isNotEmpty => module.definedMemories.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.definedMemories.toList());
  }
}

class TagSection extends Section {
  TagSection(super.module);

  @override
  int get id => 13;

  @override
  bool get isNotEmpty => module.tags.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.tags);
  }
}

class GlobalSection extends Section {
  GlobalSection(super.module);

  @override
  int get id => 6;

  @override
  bool get isNotEmpty => module.definedGlobals.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.definedGlobals.toList());
  }
}

class ExportSection extends Section {
  ExportSection(super.module);

  @override
  int get id => 7;

  @override
  bool get isNotEmpty => module.exports.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.exports);
  }
}

class StartSection extends Section {
  StartSection(super.module);

  @override
  int get id => 8;

  @override
  bool get isNotEmpty => module.startFunction != null;

  @override
  void serializeContents() {
    writeUnsigned(module.startFunction!.index);
  }
}

class _Element implements Serializable {
  final Table table;
  final int startIndex;
  final List<BaseFunction> entries = [];

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
  ElementSection(super.module);

  @override
  int get id => 9;

  @override
  bool get isNotEmpty =>
      module.definedTables.any((table) => table.elements.any((e) => e != null));

  @override
  void serializeContents() {
    // Group nonempty element entries into contiguous stretches and serialize
    // each stretch as an element.
    List<_Element> elements = [];
    for (DefinedTable table in module.definedTables) {
      _Element? current;
      for (int i = 0; i < table.elements.length; i++) {
        BaseFunction? function = table.elements[i];
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
    writeList(elements);
  }
}

class DataCountSection extends Section {
  DataCountSection(super.module);

  @override
  int get id => 12;

  @override
  bool get isNotEmpty => module.dataSegments.isNotEmpty;

  @override
  void serializeContents() {
    writeUnsigned(module.dataSegments.length);
  }
}

class CodeSection extends Section {
  CodeSection(super.module);

  @override
  int get id => 10;

  @override
  bool get isNotEmpty => module.definedFunctions.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.definedFunctions.toList());
  }
}

class DataSection extends Section {
  DataSection(super.module);

  @override
  int get id => 11;

  @override
  bool get isNotEmpty => module.dataSegments.isNotEmpty;

  @override
  void serializeContents() {
    writeList(module.dataSegments);
  }
}

abstract class CustomSection extends Section {
  CustomSection(super.module);

  @override
  int get id => 0;
}

class NameSection extends CustomSection {
  NameSection(super.module);

  @override
  bool get isNotEmpty =>
      module.functionNameCount > 0 || module.typeNameCount > 0;

  @override
  void serializeContents() {
    writeName("name");

    final functionNameSubsection = _NameSubsection();
    functionNameSubsection.writeUnsigned(module.functionNameCount);
    for (int i = 0; i < module.functions.length; i++) {
      String? functionName = module.functions[i].functionName;
      if (functionName != null) {
        functionNameSubsection.writeUnsigned(i);
        functionNameSubsection.writeName(functionName);
      }
    }

    final typeNameSubsection = _NameSubsection();
    typeNameSubsection.writeUnsigned(module.typeNameCount);
    for (int i = 0; i < module.defTypes.length; i++) {
      final ty = module.defTypes[i];
      if (ty is DataType) {
        typeNameSubsection.writeUnsigned(i);
        typeNameSubsection.writeName(ty.name);
      }
    }

    writeByte(1); // Function names subsection
    writeUnsigned(functionNameSubsection.data.length);
    writeData(functionNameSubsection);
    writeByte(4); // Type names subsection
    writeUnsigned(typeNameSubsection.data.length);
    writeData(typeNameSubsection);
  }
}

class _NameSubsection with SerializerMixin {}
