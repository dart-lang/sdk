// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'reader.dart';

int _readElfBytes(Reader reader, int bytes, int alignment) {
  final alignOffset = reader.offset % alignment;
  if (alignOffset != 0) {
    // Move the reader to the next aligned position.
    reader.seek(reader.offset - alignOffset + alignment);
  }
  return reader.readBytes(bytes);
}

// Reads an Elf{32,64}_Addr.
int _readElfAddress(Reader reader) {
  return _readElfBytes(reader, reader.wordSize, reader.wordSize);
}

// Reads an Elf{32,64}_Off.
int _readElfOffset(Reader reader) {
  return _readElfBytes(reader, reader.wordSize, reader.wordSize);
}

// Reads an Elf{32,64}_Half.
int _readElfHalf(Reader reader) {
  return _readElfBytes(reader, 2, 2);
}

// Reads an Elf{32,64}_Word.
int _readElfWord(Reader reader) {
  return _readElfBytes(reader, 4, 4);
}

// Reads an Elf64_Xword.
int _readElfXword(Reader reader) {
  switch (reader.wordSize) {
    case 4:
      throw "Internal reader error: reading Elf64_Xword in 32-bit ELF file";
    case 8:
      return _readElfBytes(reader, 8, 8);
    default:
      throw "Unsupported word size ${reader.wordSize}";
  }
}

// Reads an Elf{32,64}_Section.
int _readElfSection(Reader reader) {
  return _readElfBytes(reader, 2, 2);
}

// Used in cases where the value read for a given field is Elf32_Word on 32-bit
// and Elf64_Xword on 64-bit.
int _readElfNative(Reader reader) {
  switch (reader.wordSize) {
    case 4:
      return _readElfWord(reader);
    case 8:
      return _readElfXword(reader);
    default:
      throw "Unsupported word size ${reader.wordSize}";
  }
}

class ElfHeader {
  final Reader startingReader;

  int wordSize;
  Endian endian;
  int entry;
  int flags;
  int headerSize;
  int programHeaderOffset;
  int sectionHeaderOffset;
  int programHeaderCount;
  int sectionHeaderCount;
  int programHeaderEntrySize;
  int sectionHeaderEntrySize;
  int sectionHeaderStringsIndex;

  int get programHeaderSize => programHeaderCount * programHeaderEntrySize;
  int get sectionHeaderSize => sectionHeaderCount * sectionHeaderEntrySize;

  // Constants used within the ELF specification.
  static const _ELFMAG = "\x7fELF";
  static const _ELFCLASS32 = 0x01;
  static const _ELFCLASS64 = 0x02;
  static const _ELFDATA2LSB = 0x01;
  static const _ELFDATA2MSB = 0x02;

  ElfHeader.fromReader(this.startingReader) {
    _read();
  }

  static bool startsWithMagicNumber(Reader reader) {
    reader.reset();
    for (final sigByte in _ELFMAG.codeUnits) {
      if (reader.readByte() != sigByte) {
        return false;
      }
    }
    return true;
  }

  int _readWordSize(Reader reader) {
    switch (reader.readByte()) {
      case _ELFCLASS32:
        return 4;
      case _ELFCLASS64:
        return 8;
      default:
        throw FormatException("Unexpected e_ident[EI_CLASS] value");
    }
  }

  int get calculatedHeaderSize => 0x18 + 3 * wordSize + 0x10;

  Endian _readEndian(Reader reader) {
    switch (reader.readByte()) {
      case _ELFDATA2LSB:
        return Endian.little;
      case _ELFDATA2MSB:
        return Endian.big;
      default:
        throw FormatException("Unexpected e_indent[EI_DATA] value");
    }
  }

  void _read() {
    startingReader.reset();
    for (final sigByte in _ELFMAG.codeUnits) {
      if (startingReader.readByte() != sigByte) {
        throw FormatException("Not an ELF file");
      }
    }
    wordSize = _readWordSize(startingReader);
    final fileSize = startingReader.bdata.buffer.lengthInBytes;
    if (fileSize < calculatedHeaderSize) {
      throw FormatException("ELF file too small for header: "
          "file size ${fileSize} < "
          "calculated header size $calculatedHeaderSize");
    }
    endian = _readEndian(startingReader);
    if (startingReader.readByte() != 0x01) {
      throw FormatException("Unexpected e_ident[EI_VERSION] value");
    }

    // After this point, we need the reader to be correctly set up re: word
    // size and endianness, since we start reading more than single bytes.
    final reader = Reader.fromTypedData(startingReader.bdata,
        wordSize: wordSize, endian: endian);
    reader.seek(startingReader.offset);

    // Skip rest of e_ident/e_type/e_machine, i.e. move to e_version.
    reader.seek(0x14, absolute: true);
    if (_readElfWord(reader) != 0x01) {
      throw FormatException("Unexpected e_version value");
    }

    entry = _readElfAddress(reader);
    programHeaderOffset = _readElfOffset(reader);
    sectionHeaderOffset = _readElfOffset(reader);
    flags = _readElfWord(reader);
    headerSize = _readElfHalf(reader);
    programHeaderEntrySize = _readElfHalf(reader);
    programHeaderCount = _readElfHalf(reader);
    sectionHeaderEntrySize = _readElfHalf(reader);
    sectionHeaderCount = _readElfHalf(reader);
    sectionHeaderStringsIndex = _readElfHalf(reader);

    if (headerSize != calculatedHeaderSize) {
      throw FormatException("Stored ELF header size ${headerSize} != "
          "calculated ELF header size $calculatedHeaderSize");
    }
    if (fileSize < programHeaderOffset) {
      throw FormatException("File is truncated before program header");
    }
    if (fileSize < programHeaderOffset + programHeaderSize) {
      throw FormatException("File is truncated within the program header");
    }
    if (fileSize < sectionHeaderOffset) {
      throw FormatException("File is truncated before section header");
    }
    if (fileSize < sectionHeaderOffset + sectionHeaderSize) {
      throw FormatException("File is truncated within the section header");
    }
  }

  String toString() {
    var ret = "Format is ${wordSize * 8} bits\n";
    switch (endian) {
      case Endian.little:
        ret += "Little-endian format\n";
        break;
      case Endian.big:
        ret += "Big-endian format\n";
        break;
    }
    ret += "Entry point: 0x${paddedHex(entry, wordSize)}\n"
        "Flags: 0x${paddedHex(flags, 4)}\n"
        "Header size: ${headerSize}\n"
        "Program header offset: "
        "0x${paddedHex(programHeaderOffset, wordSize)}\n"
        "Program header entry size: ${programHeaderEntrySize}\n"
        "Program header entry count: ${programHeaderCount}\n"
        "Section header offset: "
        "0x${paddedHex(sectionHeaderOffset, wordSize)}\n"
        "Section header entry size: ${sectionHeaderEntrySize}\n"
        "Section header entry count: ${sectionHeaderCount}\n"
        "Section header strings index: ${sectionHeaderStringsIndex}\n";
    return ret;
  }
}

class ProgramHeaderEntry {
  Reader reader;

  int type;
  int flags;
  int offset;
  int vaddr;
  int paddr;
  int filesz;
  int memsz;
  int align;

  // p_type constants from ELF specification.
  static const _PT_NULL = 0;
  static const _PT_LOAD = 1;
  static const _PT_DYNAMIC = 2;
  static const _PT_PHDR = 6;

  ProgramHeaderEntry.fromReader(this.reader) {
    assert(reader.wordSize == 4 || reader.wordSize == 8);
    _read();
  }

  void _read() {
    reader.reset();
    type = _readElfWord(reader);
    if (reader.wordSize == 8) {
      flags = _readElfWord(reader);
    }
    offset = _readElfOffset(reader);
    vaddr = _readElfAddress(reader);
    paddr = _readElfAddress(reader);
    filesz = _readElfNative(reader);
    memsz = _readElfNative(reader);
    if (reader.wordSize == 4) {
      flags = _readElfWord(reader);
    }
    align = _readElfNative(reader);
  }

  static const _typeStrings = <int, String>{
    _PT_NULL: "PT_NULL",
    _PT_LOAD: "PT_LOAD",
    _PT_DYNAMIC: "PT_DYNAMIC",
    _PT_PHDR: "PT_PHDR",
  };

  static String _typeToString(int type) {
    if (_typeStrings.containsKey(type)) {
      return _typeStrings[type];
    }
    return "unknown (${paddedHex(type, 4)})";
  }

  String toString() => "Type: ${_typeToString(type)}\n"
      "Flags: 0x${paddedHex(flags, 4)}\n"
      "Offset: $offset (0x${paddedHex(offset, reader.wordSize)})\n"
      "Virtual address: 0x${paddedHex(vaddr, reader.wordSize)}\n"
      "Physical address: 0x${paddedHex(paddr, reader.wordSize)}\n"
      "Size in file: $filesz\n"
      "Size in memory: $memsz\n"
      "Alignment: 0x${paddedHex(align, reader.wordSize)}\n";
}

class ProgramHeader {
  final Reader reader;
  final int entrySize;
  final int entryCount;

  List<ProgramHeaderEntry> _entries;

  ProgramHeader.fromReader(this.reader, {this.entrySize, this.entryCount}) {
    _read();
  }

  int get length => _entries.length;
  ProgramHeaderEntry operator [](int index) => _entries[index];

  void _read() {
    reader.reset();
    _entries = <ProgramHeaderEntry>[];
    for (var i = 0; i < entryCount; i++) {
      final entry = ProgramHeaderEntry.fromReader(
          reader.shrink(i * entrySize, entrySize));
      _entries.add(entry);
    }
  }

  String toString() {
    var ret = "";
    for (var i = 0; i < length; i++) {
      ret += "Entry $i:\n${this[i]}\n";
    }
    return ret;
  }
}

class SectionHeaderEntry {
  final Reader reader;

  int nameIndex;
  String name;
  int type;
  int flags;
  int addr;
  int offset;
  int size;
  int link;
  int info;
  int addrAlign;
  int entrySize;

  SectionHeaderEntry.fromReader(this.reader) {
    _read();
  }

  // sh_type constants from ELF specification.
  static const _SHT_NULL = 0;
  static const _SHT_PROGBITS = 1;
  static const _SHT_SYMTAB = 2;
  static const _SHT_STRTAB = 3;
  static const _SHT_HASH = 5;
  static const _SHT_DYNAMIC = 6;
  static const _SHT_NOBITS = 8;
  static const _SHT_DYNSYM = 11;

  void _read() {
    reader.reset();
    nameIndex = _readElfWord(reader);
    type = _readElfWord(reader);
    flags = _readElfNative(reader);
    addr = _readElfAddress(reader);
    offset = _readElfOffset(reader);
    size = _readElfNative(reader);
    link = _readElfWord(reader);
    info = _readElfWord(reader);
    addrAlign = _readElfNative(reader);
    entrySize = _readElfNative(reader);
  }

  void setName(StringTable nameTable) {
    name = nameTable[nameIndex];
  }

  static const _typeStrings = <int, String>{
    _SHT_NULL: "SHT_NULL",
    _SHT_PROGBITS: "SHT_PROGBITS",
    _SHT_SYMTAB: "SHT_SYMTAB",
    _SHT_STRTAB: "SHT_STRTAB",
    _SHT_HASH: "SHT_HASH",
    _SHT_DYNAMIC: "SHT_DYNAMIC",
    _SHT_NOBITS: "SHT_NOBITS",
    _SHT_DYNSYM: "SHT_DYNSYM",
  };

  static String _typeToString(int type) {
    if (_typeStrings.containsKey(type)) {
      return _typeStrings[type];
    }
    return "unknown (${paddedHex(type, 4)})";
  }

  String toString() => "Name: ${name} (@ ${nameIndex})\n"
      "Type: ${_typeToString(type)}\n"
      "Flags: 0x${paddedHex(flags, reader.wordSize)}\n"
      "Address: 0x${paddedHex(addr, reader.wordSize)}\n"
      "Offset: $offset (0x${paddedHex(offset, reader.wordSize)})\n"
      "Size: $size\n"
      "Link: $link\n"
      "Info: 0x${paddedHex(info, 4)}\n"
      "Address alignment: 0x${paddedHex(addrAlign, reader.wordSize)}\n"
      "Entry size: ${entrySize}\n";
}

class SectionHeader {
  final Reader reader;
  final int entrySize;
  final int entryCount;
  final int stringsIndex;

  List<SectionHeaderEntry> _entries;
  StringTable nameTable;

  SectionHeader.fromReader(this.reader,
      {this.entrySize, this.entryCount, this.stringsIndex}) {
    _read();
  }

  SectionHeaderEntry _readSectionHeaderEntry(int index) {
    final ret = SectionHeaderEntry.fromReader(
        reader.shrink(index * entrySize, entrySize));
    if (nameTable != null) {
      ret.setName(nameTable);
    }
    return ret;
  }

  void _read() {
    reader.reset();
    // Set up the section header string table first so we can use it
    // for the other section header entries.
    final nameTableEntry = _readSectionHeaderEntry(stringsIndex);
    assert(nameTableEntry.type == SectionHeaderEntry._SHT_STRTAB);
    nameTable = StringTable(nameTableEntry,
        reader.refocus(nameTableEntry.offset, nameTableEntry.size));
    nameTableEntry.setName(nameTable);

    _entries = <SectionHeaderEntry>[];
    for (var i = 0; i < entryCount; i++) {
      // We don't need to reparse the shstrtab entry.
      if (i == stringsIndex) {
        _entries.add(nameTableEntry);
      } else {
        _entries.add(_readSectionHeaderEntry(i));
      }
    }
  }

  int get length => _entries.length;
  SectionHeaderEntry operator [](int index) => _entries[index];

  @override
  String toString() {
    var ret = "";
    for (var i = 0; i < length; i++) {
      ret += "Entry $i:\n${this[i]}\n";
    }
    return ret;
  }
}

class Section {
  final Reader reader;
  final SectionHeaderEntry headerEntry;

  Section(this.headerEntry, this.reader);

  factory Section.fromEntryAndReader(SectionHeaderEntry entry, Reader reader) {
    switch (entry.type) {
      case SectionHeaderEntry._SHT_STRTAB:
        return StringTable(entry, reader);
      case SectionHeaderEntry._SHT_SYMTAB:
        return SymbolTable(entry, reader);
      case SectionHeaderEntry._SHT_DYNSYM:
        return SymbolTable(entry, reader);
      default:
        return Section(entry, reader);
    }
  }

  int get virtualAddress => headerEntry.addr;
  int get length => reader.bdata.lengthInBytes;
  @override
  String toString() => "an unparsed section of ${length} bytes\n";
}

class StringTable extends Section {
  final _entries = Map<int, String>();

  StringTable(SectionHeaderEntry entry, Reader reader) : super(entry, reader) {
    while (!reader.done) {
      _entries[reader.offset] = reader.readNullTerminatedString();
    }
  }

  String operator [](int index) => _entries[index];
  bool containsKey(int index) => _entries.containsKey(index);

  @override
  String toString() {
    var buffer = StringBuffer("a string table:\n");
    for (var key in _entries.keys) {
      buffer
        ..write(" ")
        ..write(key)
        ..write(" => ")
        ..writeln(_entries[key]);
    }
    return buffer.toString();
  }
}

enum SymbolBinding {
  STB_LOCAL,
  STB_GLOBAL,
}

enum SymbolType {
  STT_NOTYPE,
  STT_OBJECT,
  STT_FUNC,
}

enum SymbolVisibility {
  STV_DEFAULT,
  STV_INTERNAL,
  STV_HIDDEN,
  STV_PROTECTED,
}

class Symbol {
  final int nameIndex;
  final int info;
  final int other;
  final int sectionIndex;
  final int value;
  final int size;

  final int _wordSize;

  String name;

  Symbol._(this.nameIndex, this.info, this.other, this.sectionIndex, this.value,
      this.size, this._wordSize);

  static Symbol fromReader(Reader reader) {
    final nameIndex = _readElfWord(reader);
    int info;
    int other;
    int sectionIndex;
    if (reader.wordSize == 8) {
      info = reader.readByte();
      other = reader.readByte();
      sectionIndex = _readElfSection(reader);
    }
    final value = _readElfAddress(reader);
    final size = _readElfNative(reader);
    if (reader.wordSize == 4) {
      info = reader.readByte();
      other = reader.readByte();
      sectionIndex = _readElfSection(reader);
    }
    return Symbol._(
        nameIndex, info, other, sectionIndex, value, size, reader.wordSize);
  }

  void _cacheNameFromStringTable(StringTable table) {
    if (!table.containsKey(nameIndex)) {
      throw FormatException("Index $nameIndex not found in string table");
    }
    name = table[nameIndex];
  }

  SymbolBinding get bind => SymbolBinding.values[info >> 4];
  SymbolType get type => SymbolType.values[info & 0x0f];
  SymbolVisibility get visibility => SymbolVisibility.values[other & 0x03];

  @override
  String toString() {
    final buffer = StringBuffer("symbol ");
    if (name != null) {
      buffer..write('"')..write(name)..write('" ');
    }
    buffer
      ..write("(")
      ..write(nameIndex)
      ..write("): ")
      ..write(paddedHex(value, _wordSize))
      ..write(" ")
      ..write(size)
      ..write(" sec ")
      ..write(sectionIndex)
      ..write(" ")
      ..write(bind)
      ..write(" ")
      ..write(type)
      ..write(" ")
      ..write(visibility);
    return buffer.toString();
  }
}

class SymbolTable extends Section {
  final Iterable<Symbol> _entries;
  final _nameCache = Map<String, Symbol>();

  SymbolTable(SectionHeaderEntry entry, Reader reader)
      : _entries = reader.readRepeated(Symbol.fromReader),
        super(entry, reader);

  void _cacheNames(StringTable stringTable) {
    _nameCache.clear();
    for (final symbol in _entries) {
      symbol._cacheNameFromStringTable(stringTable);
      _nameCache[symbol.name] = symbol;
    }
  }

  Symbol operator [](String name) => _nameCache[name];
  bool containsKey(String name) => _nameCache.containsKey(name);

  @override
  String toString() {
    var buffer = StringBuffer("a symbol table:\n");
    for (var symbol in _entries) {
      buffer
        ..write(" ")
        ..writeln(symbol);
    }
    return buffer.toString();
  }
}

class Elf {
  ElfHeader _header;
  ProgramHeader _programHeader;
  SectionHeader _sectionHeader;
  Map<SectionHeaderEntry, Section> _sections;

  Elf._(this._header, this._programHeader, this._sectionHeader, this._sections);

  /// Creates an [Elf] from the data pointed to by [reader].
  ///
  /// Returns null if the file does not start with the ELF magic number.
  static Elf fromReader(Reader reader) {
    final start = reader.offset;
    if (!ElfHeader.startsWithMagicNumber(reader)) return null;
    reader.seek(start, absolute: true);
    return Elf._read(reader);
  }

  /// Creates an [Elf] from [bytes].
  ///
  /// Returns null if the file does not start with the ELF magic number.
  static Elf fromBuffer(Uint8List bytes) =>
      Elf.fromReader(Reader.fromTypedData(bytes));

  /// Creates an [Elf] from the file at [path].
  ///
  /// Returns null if the file does not start with the ELF magic number.
  static Elf fromFile(String path) => Elf.fromReader(Reader.fromFile(path));

  /// The virtual address value of the dynamic symbol named [name].
  ///
  /// Returns -1 if there is no dynamic symbol with that name.
  int namedAddress(String name) {
    for (final SymbolTable dynsym in namedSections(".dynsym")) {
      if (dynsym.containsKey(name)) {
        return dynsym[name].value;
      }
    }
    return -1;
  }

  /// The [Section]s whose names match [name].
  Iterable<Section> namedSections(String name) {
    return _sections.keys
        .where((entry) => entry.name == name)
        .map((entry) => _sections[entry]);
  }

  static Elf _read(Reader startingReader) {
    final header = ElfHeader.fromReader(startingReader.copy());
    // Now use the word size and endianness information from the header.
    final reader = Reader.fromTypedData(startingReader.bdata,
        wordSize: header.wordSize, endian: header.endian);
    final programHeader = ProgramHeader.fromReader(
        reader.refocus(header.programHeaderOffset, header.programHeaderSize),
        entrySize: header.programHeaderEntrySize,
        entryCount: header.programHeaderCount);
    final sectionHeader = SectionHeader.fromReader(
        reader.refocus(header.sectionHeaderOffset, header.sectionHeaderSize),
        entrySize: header.sectionHeaderEntrySize,
        entryCount: header.sectionHeaderCount,
        stringsIndex: header.sectionHeaderStringsIndex);
    final sections = <SectionHeaderEntry, Section>{};
    final dynsyms = Map<SectionHeaderEntry, SymbolTable>();
    final dynstrs = Map<SectionHeaderEntry, StringTable>();
    for (var i = 0; i < sectionHeader.length; i++) {
      final entry = sectionHeader[i];
      if (i == header.sectionHeaderStringsIndex) {
        sections[entry] = sectionHeader.nameTable;
        continue;
      }
      final section = Section.fromEntryAndReader(
          entry, reader.refocus(entry.offset, entry.size));
      // Store the dynamic symbol tables and dynamic string tables so we can
      // cache the symbol names afterwards.
      switch (entry.name) {
        case ".dynsym":
          dynsyms[entry] = section;
          break;
        case ".dynstr":
          dynstrs[entry] = section;
          break;
        default:
          break;
      }
      sections[entry] = section;
    }
    dynsyms.forEach((entry, dynsym) {
      final linkEntry = sectionHeader[entry.link];
      if (!dynstrs.containsKey(linkEntry)) {
        throw FormatException(
            "String table not found at section header entry ${entry.link}");
      }
      dynsym._cacheNames(dynstrs[linkEntry]);
    });
    return Elf._(header, programHeader, sectionHeader, sections);
  }

  @override
  String toString() {
    String accumulateSection(String acc, SectionHeaderEntry entry) =>
        acc + "\nSection ${entry.name} is ${_sections[entry]}";
    return "Header information:\n\n${_header}"
        "\nProgram header information:\n\n${_programHeader}"
        "\nSection header information:\n\n${_sectionHeader}"
        "${_sections.keys.fold("", accumulateSection)}";
  }
}
