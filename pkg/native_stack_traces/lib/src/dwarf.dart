// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'elf.dart';
import 'reader.dart';

int _initialLengthValue(Reader reader) {
  final length = reader.readBytes(4);
  if (length == 0xffffffff) {
    throw FormatException("64-bit DWARF format detected");
  } else if (length > 0xfffffff0) {
    throw FormatException("Unrecognized reserved initial length value");
  }
  return length;
}

enum _Tag {
  compileUnit,
  inlinedSubroutine,
  subprogram,
}

const _tags = <int, _Tag>{
  0x11: _Tag.compileUnit,
  0x1d: _Tag.inlinedSubroutine,
  0x2e: _Tag.subprogram,
};

const _tagStrings = <_Tag, String>{
  _Tag.compileUnit: "DW_TAG_compile_unit",
  _Tag.inlinedSubroutine: "DW_TAG_inlined_subroutine",
  _Tag.subprogram: "DW_TAG_subroutine",
};

enum _AttributeName {
  abstractOrigin,
  callColumn,
  callFile,
  callLine,
  compilationDirectory,
  declarationColumn,
  declarationFile,
  declarationLine,
  highProgramCounter,
  lowProgramCounter,
  inline,
  name,
  producer,
  sibling,
  statementList,
}

const _attributeNames = <int, _AttributeName>{
  0x01: _AttributeName.sibling,
  0x03: _AttributeName.name,
  0x10: _AttributeName.statementList,
  0x11: _AttributeName.lowProgramCounter,
  0x12: _AttributeName.highProgramCounter,
  0x1b: _AttributeName.compilationDirectory,
  0x20: _AttributeName.inline,
  0x25: _AttributeName.producer,
  0x31: _AttributeName.abstractOrigin,
  0x39: _AttributeName.declarationColumn,
  0x3a: _AttributeName.declarationFile,
  0x3b: _AttributeName.declarationLine,
  0x57: _AttributeName.callColumn,
  0x58: _AttributeName.callFile,
  0x59: _AttributeName.callLine,
};

const _attributeNameStrings = <_AttributeName, String>{
  _AttributeName.sibling: "DW_AT_sibling",
  _AttributeName.name: "DW_AT_name",
  _AttributeName.statementList: "DW_AT_stmt_list",
  _AttributeName.lowProgramCounter: "DW_AT_low_pc",
  _AttributeName.highProgramCounter: "DW_AT_high_pc",
  _AttributeName.compilationDirectory: "DW_AT_comp_dir",
  _AttributeName.inline: "DW_AT_inline",
  _AttributeName.producer: "DW_AT_producer",
  _AttributeName.abstractOrigin: "DW_AT_abstract_origin",
  _AttributeName.declarationColumn: "DW_AT_decl_column",
  _AttributeName.declarationFile: "DW_AT_decl_file",
  _AttributeName.declarationLine: "DW_AT_decl_line",
  _AttributeName.callColumn: "DW_AT_call_column",
  _AttributeName.callFile: "DW_AT_call_file",
  _AttributeName.callLine: "DW_AT_call_line",
};

enum _AttributeForm {
  address,
  constant,
  reference4,
  sectionOffset,
  string,
}

const _attributeForms = <int, _AttributeForm>{
  0x01: _AttributeForm.address,
  0x08: _AttributeForm.string,
  0x0f: _AttributeForm.constant,
  0x13: _AttributeForm.reference4,
  0x17: _AttributeForm.sectionOffset,
};

const _attributeFormStrings = <_AttributeForm, String>{
  _AttributeForm.address: "DW_FORM_addr",
  _AttributeForm.string: "DW_FORM_string",
  _AttributeForm.constant: "DW_FORM_udata",
  _AttributeForm.reference4: "DW_FORM_ref4",
  _AttributeForm.sectionOffset: "DW_FORM_sec_offset",
};

class _Attribute {
  final _AttributeName name;
  final _AttributeForm form;

  _Attribute(this.name, this.form);
}

class _Abbreviation {
  final Reader reader;

  _Tag tag;
  bool children;
  List<_Attribute> attributes;

  _Abbreviation.fromReader(this.reader) {
    _read();
  }

  // Constants from the DWARF specification.
  static const _DW_CHILDREN_no = 0x00;
  static const _DW_CHILDREN_yes = 0x01;

  bool _readChildren() {
    switch (reader.readByte()) {
      case _DW_CHILDREN_no:
        return false;
      case _DW_CHILDREN_yes:
        return true;
      default:
        throw FormatException("Expected DW_CHILDREN_no or DW_CHILDREN_yes");
    }
  }

  void _read() {
    reader.reset();
    final tagInt = reader.readLEB128EncodedInteger();
    if (!_tags.containsKey(tagInt)) {
      throw FormatException("Unexpected DW_TAG value 0x${paddedHex(tagInt)}");
    }
    tag = _tags[tagInt];
    children = _readChildren();
    attributes = <_Attribute>[];
    while (!reader.done) {
      final nameInt = reader.readLEB128EncodedInteger();
      final formInt = reader.readLEB128EncodedInteger();
      if (nameInt == 0 && formInt == 0) {
        break;
      }
      if (!_attributeNames.containsKey(nameInt)) {
        throw FormatException("Unexpected DW_AT value 0x${paddedHex(nameInt)}");
      }
      if (!_attributeForms.containsKey(formInt)) {
        throw FormatException(
            "Unexpected DW_FORM value 0x${paddedHex(formInt)}");
      }
      attributes
          .add(_Attribute(_attributeNames[nameInt], _attributeForms[formInt]));
    }
  }

  @override
  String toString() {
    var ret = "    Tag: ${_tagStrings[tag]}\n"
        "    Children: ${children ? "DW_CHILDREN_yes" : "DW_CHILDREN_no"}\n"
        "    Attributes:\n";
    for (final attribute in attributes) {
      ret += "      ${_attributeNameStrings[attribute.name]}: "
          "${_attributeFormStrings[attribute.form]}\n";
    }
    return ret;
  }
}

class _AbbreviationsTable {
  final Reader reader;

  Map<int, _Abbreviation> _abbreviations;

  _AbbreviationsTable.fromReader(this.reader) {
    _read();
  }

  bool containsKey(int code) => _abbreviations.containsKey(code);
  _Abbreviation operator [](int code) => _abbreviations[code];

  void _read() {
    reader.reset();
    _abbreviations = <int, _Abbreviation>{};
    while (!reader.done) {
      final code = reader.readLEB128EncodedInteger();
      // Code of 0 marks end of abbreviations table.
      if (code == 0) {
        break;
      }
      final abbrev = _Abbreviation.fromReader(reader.shrink(reader.offset));
      _abbreviations[code] = abbrev;
      reader.seek(abbrev.reader.offset);
    }
  }

  @override
  String toString() =>
      "Abbreviations table:\n\n" +
      _abbreviations.keys
          .map((k) => "  Abbreviation $k:\n" + _abbreviations[k].toString())
          .join("\n");
}

/// A DWARF Debug Information Entry (DIE).
class DebugInformationEntry {
  final Reader reader;
  final CompilationUnit compilationUnit;

  // The index of the entry in the abbreviation table for this DIE. If 0, then
  // this is not actually a full DIE, but an end marker for a list of entries.
  int code;
  Map<_Attribute, Object> attributes;
  List<DebugInformationEntry> children;

  DebugInformationEntry.fromReader(this.reader, this.compilationUnit) {
    _read();
  }

  Object _readAttribute(_Attribute attribute) {
    switch (attribute.form) {
      case _AttributeForm.string:
        return reader.readNullTerminatedString();
      case _AttributeForm.address:
        return reader.readBytes(compilationUnit.addressSize);
      case _AttributeForm.sectionOffset:
        return reader.readBytes(4);
      case _AttributeForm.constant:
        return reader.readLEB128EncodedInteger();
      case _AttributeForm.reference4:
        return reader.readBytes(4);
    }
    return null;
  }

  String _nameOfOrigin(int offset) {
    if (!compilationUnit.referenceTable.containsKey(offset)) {
      throw ArgumentError(
          "${paddedHex(offset)} is not the offset of an abbreviated unit");
    }
    final origin = compilationUnit.referenceTable[offset];
    assert(origin.containsKey(_AttributeName.name));
    return origin[_AttributeName.name] as String;
  }

  String _attributeValueToString(_Attribute attribute, Object value) {
    switch (attribute.form) {
      case _AttributeForm.string:
        return value as String;
      case _AttributeForm.address:
        return paddedHex(value as int, compilationUnit.addressSize);
      case _AttributeForm.sectionOffset:
        return paddedHex(value as int, 4);
      case _AttributeForm.constant:
        return value.toString();
      case _AttributeForm.reference4:
        return paddedHex(value as int, 4) +
            " (origin: ${_nameOfOrigin(value as int)})";
    }
    return "<unknown>";
  }

  int get _unitOffset => reader.start - compilationUnit.reader.start;

  void _read() {
    reader.reset();
    code = reader.readLEB128EncodedInteger();
    // DIEs with an abbreviation table index of 0 are list end markers.
    if (code == 0) {
      return;
    }
    if (!compilationUnit.abbreviations.containsKey(code)) {
      throw FormatException("Unknown abbreviation code 0x${paddedHex(code)}");
    }
    final abbreviation = compilationUnit.abbreviations[code];
    attributes = <_Attribute, Object>{};
    for (final attribute in abbreviation.attributes) {
      attributes[attribute] = _readAttribute(attribute);
    }
    compilationUnit.referenceTable[_unitOffset] = this;
    if (!abbreviation.children) return;
    children = <DebugInformationEntry>[];
    while (!reader.done) {
      final child = DebugInformationEntry.fromReader(
          reader.shrink(reader.offset), compilationUnit);
      reader.seek(child.reader.offset);
      if (child.code == 0) {
        break;
      }
      children.add(child);
    }
  }

  _Attribute _attributeForName(_AttributeName name) => attributes.keys
      .firstWhere((_Attribute k) => k.name == name, orElse: () => null);

  bool containsKey(_AttributeName name) => _attributeForName(name) != null;

  Object operator [](_AttributeName name) {
    final key = _attributeForName(name);
    if (key == null) {
      return null;
    }
    return attributes[key];
  }

  DebugInformationEntry get abstractOrigin {
    final index = this[_AttributeName.abstractOrigin] as int;
    return compilationUnit.referenceTable[index];
  }

  int get lowPC => this[_AttributeName.lowProgramCounter] as int;

  int get highPC => this[_AttributeName.highProgramCounter] as int;

  bool containsPC(int virtualAddress) =>
      lowPC != null && lowPC <= virtualAddress && virtualAddress < highPC;

  String get name => this[_AttributeName.name] as String;

  int get callFileIndex => this[_AttributeName.callFile] as int;

  int get callLine => this[_AttributeName.callLine] as int;

  _Tag get tag => compilationUnit.abbreviations[code].tag;

  List<CallInfo> callInfo(int address, LineNumberProgram lineNumberProgram) {
    String callFilename(int index) => lineNumberProgram.filesInfo[index].name;
    if (!containsPC(address)) {
      return null;
    }
    final inlined = tag == _Tag.inlinedSubroutine;
    for (final unit in children) {
      final callInfo = unit.callInfo(address, lineNumberProgram);
      if (callInfo == null) {
        continue;
      }
      if (tag != _Tag.compileUnit) {
        callInfo.add(CallInfo(
            function: abstractOrigin.name,
            inlined: inlined,
            filename: callFilename(unit.callFileIndex),
            line: unit.callLine));
      }
      return callInfo;
    }
    if (tag == _Tag.compileUnit) {
      return null;
    }
    final filename = lineNumberProgram.filename(address);
    final line = lineNumberProgram.lineNumber(address);
    return [
      CallInfo(
          function: abstractOrigin.name,
          inlined: inlined,
          filename: filename,
          line: line)
    ];
  }

  @override
  String toString() {
    var ret =
        "Abbreviated unit (code $code, offset ${paddedHex(_unitOffset)}):\n";
    for (final attribute in attributes.keys) {
      ret += "  ${_attributeNameStrings[attribute.name]} => "
          "${_attributeValueToString(attribute, attributes[attribute])}\n";
    }
    if (children == null || children.isEmpty) {
      ret += "Has no children.\n\n";
      return ret;
    }
    ret += "Has ${children.length} " +
        (children.length == 1 ? "child" : "children") +
        "\n\n";
    for (int i = 0; i < children.length; i++) {
      ret += "Child ${i} of unit at offset ${paddedHex(_unitOffset)}:\n";
      ret += children[i].toString();
    }
    return ret;
  }
}

/// A class representing a DWARF compilation unit.
class CompilationUnit {
  final Reader reader;
  final Map<int, _AbbreviationsTable> _abbreviationsTables;
  final LineNumberInfo _lineNumberInfo;

  int size;
  int version;
  int abbreviationOffset;
  int addressSize;
  List<DebugInformationEntry> contents;
  Map<int, DebugInformationEntry> referenceTable;

  CompilationUnit.fromReader(
      this.reader, this._abbreviationsTables, this._lineNumberInfo) {
    _read();
  }

  void _read() {
    reader.reset();
    size = _initialLengthValue(reader);
    // An empty unit is an ending marker.
    if (size == 0) {
      return;
    }
    version = reader.readBytes(2);
    if (version != 2) {
      throw FormatException("Expected DWARF version 2, got $version");
    }
    abbreviationOffset = reader.readBytes(4);
    if (!_abbreviationsTables.containsKey(abbreviationOffset)) {
      throw FormatException("No abbreviation table found for offset "
          "0x${paddedHex(abbreviationOffset, 4)}");
    }
    addressSize = reader.readByte();
    contents = <DebugInformationEntry>[];
    referenceTable = <int, DebugInformationEntry>{};
    while (!reader.done) {
      final subunit =
          DebugInformationEntry.fromReader(reader.shrink(reader.offset), this);
      reader.seek(subunit.reader.offset);
      if (subunit.code == 0) {
        break;
      }
      assert(subunit.tag == _Tag.compileUnit);
      contents.add(subunit);
    }
  }

  Iterable<CallInfo> callInfo(int address) {
    for (final unit in contents) {
      final lineNumberProgram =
          _lineNumberInfo[unit[_AttributeName.statementList]];
      final callInfo = unit.callInfo(address, lineNumberProgram);
      if (callInfo != null) {
        return callInfo;
      }
    }
    return null;
  }

  _AbbreviationsTable get abbreviations =>
      _abbreviationsTables[abbreviationOffset];

  @override
  String toString() =>
      "Compilation unit:\n"
          "  Version: $version\n"
          "  Abbreviation offset: ${paddedHex(abbreviationOffset, 4)}\n"
          "  Address size: $addressSize\n\n" +
      contents.map((DebugInformationEntry u) => u.toString()).join();
}

/// A class representing a DWARF `.debug_info` section.
class DebugInfo {
  final Reader reader;
  final Map<int, _AbbreviationsTable> _abbreviationsTables;
  final LineNumberInfo _lineNumberInfo;

  List<CompilationUnit> units;

  DebugInfo.fromReader(
      this.reader, this._abbreviationsTables, this._lineNumberInfo) {
    _read();
  }

  void _read() {
    reader.reset();
    units = <CompilationUnit>[];
    while (!reader.done) {
      final unit = CompilationUnit.fromReader(
          reader.shrink(reader.offset), _abbreviationsTables, _lineNumberInfo);
      reader.seek(unit.reader.offset);
      if (unit.size == 0) {
        break;
      }
      units.add(unit);
    }
  }

  Iterable<CallInfo> callInfo(int address) {
    for (final unit in units) {
      final callInfo = unit.callInfo(address);
      if (callInfo != null) {
        return callInfo;
      }
    }
    return null;
  }

  String toString() =>
      "Debug information:\n\n" +
      units.map((CompilationUnit u) => u.toString()).join();
}

class FileEntry {
  final Reader reader;

  String name;
  int directoryIndex;
  int lastModified;
  int size;

  FileEntry.fromReader(this.reader) {
    _read();
  }

  void _read() {
    reader.reset();
    name = reader.readNullTerminatedString();
    if (name == "") {
      return;
    }
    directoryIndex = reader.readLEB128EncodedInteger();
    lastModified = reader.readLEB128EncodedInteger();
    size = reader.readLEB128EncodedInteger();
  }

  @override
  String toString() => "File name: $name\n"
      "  Directory index: $directoryIndex\n"
      "  Last modified: $lastModified\n"
      "  Size: $size\n";
}

class FileInfo {
  final Reader reader;

  Map<int, FileEntry> _files;

  FileInfo.fromReader(this.reader) {
    _read();
  }

  void _read() {
    reader.reset();
    _files = <int, FileEntry>{};
    int index = 1;
    while (!reader.done) {
      final file = FileEntry.fromReader(reader.shrink(reader.offset));
      reader.seek(file.reader.offset);
      // An empty null-terminated string marks the table end.
      if (file.name == "") {
        break;
      }
      _files[index] = file;
      index++;
    }
  }

  bool containsKey(int index) => _files.containsKey(index);
  FileEntry operator [](int index) => _files[index];

  void writeToStringBuffer(StringBuffer buffer) {
    if (_files.isEmpty) {
      buffer.writeln("No file information.");
      return;
    }

    final indexHeader = "Entry";
    final dirIndexHeader = "Dir";
    final modifiedHeader = "Time";
    final sizeHeader = "Size";
    final nameHeader = "Name";

    final indexStrings = _files
        .map((int i, FileEntry f) => MapEntry<int, String>(i, i.toString()));
    final dirIndexStrings = _files.map((int i, FileEntry f) =>
        MapEntry<int, String>(i, f.directoryIndex.toString()));
    final modifiedStrings = _files.map((int i, FileEntry f) =>
        MapEntry<int, String>(i, f.lastModified.toString()));
    final sizeStrings = _files.map(
        (int i, FileEntry f) => MapEntry<int, String>(i, f.size.toString()));

    final maxIndexLength = indexStrings.values
        .fold(indexHeader.length, (int acc, String s) => max(acc, s.length));
    final maxDirIndexLength = dirIndexStrings.values
        .fold(dirIndexHeader.length, (int acc, String s) => max(acc, s.length));
    final maxModifiedLength = modifiedStrings.values
        .fold(modifiedHeader.length, (int acc, String s) => max(acc, s.length));
    final maxSizeLength = sizeStrings.values
        .fold(sizeHeader.length, (int acc, String s) => max(acc, s.length));

    buffer.writeln("File information:");

    buffer..write(" ")..write(indexHeader.padRight(maxIndexLength));
    buffer..write(" ")..write(dirIndexHeader.padRight(maxDirIndexLength));
    buffer..write(" ")..write(modifiedHeader.padRight(maxModifiedLength));
    buffer..write(" ")..write(sizeHeader.padRight(maxSizeLength));
    buffer
      ..write(" ")
      ..writeln(nameHeader);

    for (final index in _files.keys) {
      buffer..write(" ")..write(indexStrings[index].padRight(maxIndexLength));
      buffer
        ..write(" ")
        ..write(dirIndexStrings[index].padRight(maxDirIndexLength));
      buffer
        ..write(" ")
        ..write(modifiedStrings[index].padRight(maxModifiedLength));
      buffer..write(" ")..write(sizeStrings[index].padRight(maxSizeLength));
      buffer
        ..write(" ")
        ..writeln(_files[index].name);
    }
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class LineNumberState {
  final defaultIsStatement;

  int address;
  int fileIndex;
  int line;
  int column;
  bool isStatement;
  bool basicBlock;
  bool endSequence;

  LineNumberState(this.defaultIsStatement) {
    reset();
  }

  void reset() {
    address = 0;
    fileIndex = 1;
    line = 1;
    column = 0;
    isStatement = defaultIsStatement;
    basicBlock = false;
    endSequence = false;
  }

  LineNumberState clone() {
    final clone = LineNumberState(defaultIsStatement);
    clone.address = address;
    clone.fileIndex = fileIndex;
    clone.line = line;
    clone.column = column;
    clone.isStatement = isStatement;
    clone.basicBlock = basicBlock;
    clone.endSequence = endSequence;
    return clone;
  }

  String toString() => "Current line number state machine registers:\n"
      "  Address: ${paddedHex(address)}\n"
      "  File index: $fileIndex\n"
      "  Line number: $line\n"
      "  Column number: $column\n"
      "  Is ${isStatement ? "" : "not "}a statement.\n"
      "  Is ${basicBlock ? "" : "not "}at the beginning of a basic block.\n"
      "  Is ${endSequence ? "" : "not "}just after the end of a sequence.\n";
}

/// A class representing a DWARF line number program.
class LineNumberProgram {
  final Reader reader;

  int size;
  int version;
  int headerLength;
  int minimumInstructionLength;
  bool defaultIsStatement;
  int lineBase;
  int lineRange;
  int opcodeBase;
  Map<int, int> standardOpcodeLengths;
  List<String> includeDirectories;
  FileInfo filesInfo;
  List<LineNumberState> calculatedMatrix;
  Map<int, LineNumberState> cachedLookups;

  LineNumberProgram.fromReader(this.reader) {
    _read();
  }

  void _read() {
    reader.reset();
    size = _initialLengthValue(reader);
    if (size == 0) {
      return;
    }
    version = reader.readBytes(2);
    headerLength = reader.readBytes(4);
    minimumInstructionLength = reader.readByte();
    switch (reader.readByte()) {
      case 0:
        defaultIsStatement = false;
        break;
      case 1:
        defaultIsStatement = true;
        break;
      default:
        throw FormatException("Unexpected value for default_is_stmt");
    }
    lineBase = reader.readByte(signed: true);
    lineRange = reader.readByte();
    opcodeBase = reader.readByte();
    standardOpcodeLengths = <int, int>{};
    // Standard opcode numbering starts at 1.
    for (int i = 1; i < opcodeBase; i++) {
      standardOpcodeLengths[i] = reader.readLEB128EncodedInteger();
    }
    includeDirectories = <String>[];
    while (!reader.done) {
      final directory = reader.readNullTerminatedString();
      if (directory == "") {
        break;
      }
      includeDirectories.add(directory);
    }
    filesInfo = FileInfo.fromReader(reader.shrink(reader.offset));
    reader.seek(filesInfo.reader.offset);
    // Header length doesn't include the 4-byte length or 2-byte version fields.
    assert(reader.offset == headerLength + 6);
    calculatedMatrix = <LineNumberState>[];
    final currentState = LineNumberState(defaultIsStatement);
    while (!reader.done) {
      _applyNextOpcode(currentState);
    }
    if (calculatedMatrix.isEmpty) {
      throw FormatException("No line number information generated by program");
    }
    // Set the offset to the declared size in case of padding.  The declared
    // size does not include the size of the size field itself.
    reader.seek(size + 4);
    cachedLookups = <int, LineNumberState>{};
  }

  void _addStateToMatrix(LineNumberState state) {
    calculatedMatrix.add(state.clone());
  }

  void _applyNextOpcode(LineNumberState state) {
    void applySpecialOpcode(int opcode) {
      final adjustedOpcode = opcode - opcodeBase;
      state.address = adjustedOpcode ~/ lineRange;
      state.line += lineBase + (adjustedOpcode % lineRange);
    }

    final opcode = reader.readByte();
    if (opcode >= opcodeBase) {
      return applySpecialOpcode(opcode);
    }
    switch (opcode) {
      case 0: // Extended opcodes
        final extendedLength = reader.readByte();
        final subOpcode = reader.readByte();
        switch (subOpcode) {
          case 0:
            throw FormatException(
                "Attempted to execute extended opcode ${subOpcode} (padding?)");
          case 1: // DW_LNE_end_sequence
            state.endSequence = true;
            _addStateToMatrix(state);
            state.reset();
            break;
          case 2: // DW_LNE_set_address
            // The length includes the subopcode.
            final valueLength = extendedLength - 1;
            assert(valueLength == 4 || valueLength == 8);
            final newAddress = reader.readBytes(valueLength);
            state.address = newAddress;
            break;
          case 3: // DW_LNE_define_file
            throw FormatException("DW_LNE_define_file instruction not handled");
          default:
            throw FormatException(
                "Extended opcode ${subOpcode} not in DWARF 2");
        }
        break;
      case 1: // DW_LNS_copy
        _addStateToMatrix(state);
        state.basicBlock = false;
        break;
      case 2: // DW_LNS_advance_pc
        final increment = reader.readLEB128EncodedInteger();
        state.address += minimumInstructionLength * increment;
        break;
      case 3: // DW_LNS_advance_line
        state.line += reader.readLEB128EncodedInteger(signed: true);
        break;
      case 4: // DW_LNS_set_file
        state.fileIndex = reader.readLEB128EncodedInteger();
        break;
      case 5: // DW_LNS_set_column
        state.column = reader.readLEB128EncodedInteger();
        break;
      case 6: // DW_LNS_negate_stmt
        state.isStatement = !state.isStatement;
        break;
      case 7: // DW_LNS_set_basic_block
        state.basicBlock = true;
        break;
      case 8: // DW_LNS_const_add_pc
        applySpecialOpcode(255);
        break;
      case 9: // DW_LNS_fixed_advance_pc
        state.address += reader.readBytes(2);
        break;
      default:
        throw FormatException("Standard opcode ${opcode} not in DWARF 2");
    }
  }

  bool containsKey(int address) {
    assert(calculatedMatrix.last.endSequence);
    return address >= calculatedMatrix.first.address &&
        address < calculatedMatrix.last.address;
  }

  LineNumberState operator [](int address) {
    if (cachedLookups.containsKey(address)) {
      return cachedLookups[address];
    }
    if (!containsKey(address)) {
      return null;
    }
    // Since the addresses are generated in increasing order, we can do a
    // binary search to find the right state.
    assert(calculatedMatrix != null && calculatedMatrix.isNotEmpty);
    var minIndex = 0;
    var maxIndex = calculatedMatrix.length - 1;
    while (true) {
      if (minIndex == maxIndex || minIndex + 1 == maxIndex) {
        final found = calculatedMatrix[minIndex];
        cachedLookups[address] = found;
        return found;
      }
      final index = minIndex + ((maxIndex - minIndex) ~/ 2);
      final compared = calculatedMatrix[index].address.compareTo(address);
      if (compared == 0) {
        return calculatedMatrix[index];
      } else if (compared < 0) {
        minIndex = index;
      } else if (compared > 0) {
        maxIndex = index;
      }
    }
  }

  String filename(int address) {
    final state = this[address];
    if (state == null) {
      return null;
    }
    return filesInfo[state.fileIndex].name;
  }

  int lineNumber(int address) {
    final state = this[address];
    if (state == null) {
      return null;
    }
    return state.line;
  }

  @override
  String toString() {
    var buffer = StringBuffer("  Size: $size\n"
        "  Version: $version\n"
        "  Header length: $headerLength\n"
        "  Min instruction length: $minimumInstructionLength\n"
        "  Default value of is_stmt: $defaultIsStatement\n"
        "  Line base: $lineBase\n"
        "  Line range: $lineRange\n"
        "  Opcode base: $opcodeBase\n"
        "  Standard opcode lengths:\n");
    for (int i = 1; i < opcodeBase; i++) {
      buffer
        ..write("    Opcode ")
        ..write(i)
        ..write(": ")
        ..writeln(standardOpcodeLengths[i]);
    }

    if (includeDirectories.isEmpty) {
      buffer.writeln("No include directories.");
    } else {
      buffer.writeln("Include directories:");
      for (final dir in includeDirectories) {
        buffer
          ..write("    ")
          ..writeln(dir);
      }
    }

    filesInfo.writeToStringBuffer(buffer);

    buffer.writeln("Results of line number program:");
    for (final state in calculatedMatrix) {
      buffer..write(state);
    }

    return buffer.toString();
  }
}

/// A class representing a DWARF .debug_line section.
class LineNumberInfo {
  final Reader reader;

  Map<int, LineNumberProgram> programs;

  LineNumberInfo.fromReader(this.reader) {
    _read();
  }

  void _read() {
    reader.reset();
    programs = <int, LineNumberProgram>{};
    while (!reader.done) {
      final start = reader.offset;
      final program = LineNumberProgram.fromReader(reader.shrink(start));
      reader.seek(program.reader.offset);
      if (program.size == 0) {
        break;
      }
      programs[start] = program;
    }
  }

  bool containsKey(int address) => programs.containsKey(address);
  LineNumberProgram operator [](int address) => programs[address];

  String toString() =>
      "Line number information:\n\n" +
      programs
          .map((int i, LineNumberProgram p) =>
              MapEntry(i, "Line number program @ 0x${paddedHex(i)}:\n$p\n"))
          .values
          .join();
}

// TODO(11617): Replace calls to these functions with a general hashing solution
// once available.
int _hashCombine(int hash, int value) {
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _hashFinish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

class CallInfo {
  final bool inlined;
  final String function;
  final String filename;
  final int line;

  CallInfo({this.inlined = false, this.function, this.filename, this.line});

  int get hashCode => _hashFinish(_hashCombine(
      _hashCombine(
          _hashCombine(_hashCombine(0, inlined.hashCode), function.hashCode),
          filename.hashCode),
      line.hashCode));

  bool operator ==(Object other) {
    if (other is CallInfo) {
      return inlined == other.inlined &&
          function == other.function &&
          filename == other.filename &&
          line == other.line;
    }
    return false;
  }

  String toString() =>
      "${function} (${filename}:${line <= 0 ? "??" : line.toString()})";
}

/// The instructions section in which a program counter address is located.
enum InstructionsSection { vm, isolate }

/// A program counter address viewed as an offset into the appropriate
/// instructions section of a Dart snapshot.
class PCOffset {
  final int offset;
  final InstructionsSection section;

  PCOffset(this.offset, this.section);

  /// The virtual address for this [PCOffset] in [dwarf].
  int virtualAddressIn(Dwarf dwarf) => dwarf.virtualAddressOf(this);

  /// The call information found for this [PCOffset] in [dwarf].
  ///
  /// If [includeInternalFrames] is false, then only information corresponding
  /// to user or library code is returned.
  Iterable<CallInfo> callInfoFrom(Dwarf dwarf,
          {bool includeInternalFrames = false}) =>
      dwarf.callInfoFor(dwarf.virtualAddressOf(this),
          includeInternalFrames: includeInternalFrames);

  @override
  int get hashCode => _hashFinish(_hashCombine(offset.hashCode, section.index));

  @override
  bool operator ==(Object other) {
    return other is PCOffset &&
        offset == other.offset &&
        section == other.section;
  }
}

/// The DWARF debugging information for a Dart snapshot.
class Dwarf {
  final Map<int, _AbbreviationsTable> _abbreviationTables;
  final DebugInfo _debugInfo;
  final LineNumberInfo _lineNumberInfo;
  final int _vmStartAddress;
  final int _isolateStartAddress;

  Dwarf._(this._abbreviationTables, this._debugInfo, this._lineNumberInfo,
      this._vmStartAddress, this._isolateStartAddress);

  /// Attempts to load the DWARF debugging information from the reader.
  ///
  /// Returns a [Dwarf] object if the load succeeds, otherwise returns null.
  static Dwarf fromReader(Reader reader) {
    // Currently, the only DWARF-containing format we recognize is ELF.
    final elf = Elf.fromReader(reader);
    if (elf == null) return null;
    return Dwarf._loadSectionsFromElf(elf);
  }

  /// Attempts to load the DWARF debugging information from the given bytes.
  ///
  /// Returns a [Dwarf] object if the load succeeds, otherwise returns null.
  static Dwarf fromBytes(Uint8List bytes) =>
      Dwarf.fromReader(Reader.fromTypedData(bytes));

  /// Attempts to load the DWARF debugging information from the file at [path].
  ///
  /// Returns a [Dwarf] object if the load succeeds, otherwise returns null.
  static Dwarf fromFile(String path) => Dwarf.fromReader(Reader.fromFile(path));

  static const String _vmSymbol = "_kDartVmSnapshotInstructions";
  static const String _isolateSymbol = "_kDartIsolateSnapshotInstructions";

  static Dwarf _loadSectionsFromElf(Elf elf) {
    final abbrevSection = elf.namedSections(".debug_abbrev").single;
    final abbreviationTables = <int, _AbbreviationsTable>{};
    var abbreviationOffset = 0;
    while (abbreviationOffset < abbrevSection.reader.length) {
      final table = _AbbreviationsTable.fromReader(
          abbrevSection.reader.shrink(abbreviationOffset));
      abbreviationTables[abbreviationOffset] = table;
      abbreviationOffset += table.reader.offset;
    }
    assert(abbreviationOffset == abbrevSection.reader.length);

    final lineNumberSection = elf.namedSections(".debug_line").single;
    final lineNumberInfo = LineNumberInfo.fromReader(lineNumberSection.reader);

    final infoSection = elf.namedSections(".debug_info").single;
    final debugInfo = DebugInfo.fromReader(
        infoSection.reader, abbreviationTables, lineNumberInfo);

    final vmStartAddress = elf.namedAddress(_vmSymbol);
    if (vmStartAddress == -1) {
      throw FormatException("Expected a dynamic symbol with name ${_vmSymbol}");
    }
    final isolateStartAddress = elf.namedAddress(_isolateSymbol);
    if (isolateStartAddress == -1) {
      throw FormatException(
          "Expected a dynamic symbol with name ${_isolateSymbol}");
    }

    return Dwarf._(abbreviationTables, debugInfo, lineNumberInfo,
        vmStartAddress, isolateStartAddress);
  }

  /// The call information for the given virtual address. There may be
  /// multiple [CallInfo] objects returned for a single virtual address when
  /// code has been inlined.
  ///
  /// If [includeInternalFrames] is false, then only information corresponding
  /// to user or library code is returned.
  Iterable<CallInfo> callInfoFor(int address,
      {bool includeInternalFrames = false}) {
    final calls = _debugInfo.callInfo(address);
    if (calls != null && !includeInternalFrames) {
      return calls.where((CallInfo c) => c.line > 0);
    }
    return calls;
  }

  /// The virtual address in this DWARF information for the given [PCOffset].
  int virtualAddressOf(PCOffset pcOffset) {
    switch (pcOffset.section) {
      case InstructionsSection.vm:
        return pcOffset.offset + _vmStartAddress;
      case InstructionsSection.isolate:
        return pcOffset.offset + _isolateStartAddress;
      default:
        throw "Unexpected value for instructions section";
    }
  }

  @override
  String toString() =>
      "DWARF debugging information:\n\n" +
      _abbreviationTables
          .map((int i, _AbbreviationsTable t) =>
              MapEntry(i, "(Offset ${paddedHex(i)}) $t"))
          .values
          .join() +
      "\n$_debugInfo\n$_lineNumberInfo";
}
