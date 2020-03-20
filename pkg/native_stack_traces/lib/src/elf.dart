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

  void writeToStringBuffer(StringBuffer buffer) {
    buffer..write('Format is ')..write(wordSize * 8)..write(' bits');
    switch (endian) {
      case Endian.little:
        buffer..writeln(' and little-endian');
        break;
      case Endian.big:
        buffer..writeln(' and big-endian');
        break;
    }
    buffer
      ..write('Entry point: 0x')
      ..writeln(paddedHex(entry, wordSize))
      ..write('Flags: 0x')
      ..writeln(paddedHex(flags, 4))
      ..write('Program header offset: 0x')
      ..writeln(paddedHex(programHeaderOffset, wordSize))
      ..write('Program header entry size: ')
      ..writeln(programHeaderEntrySize)
      ..write('Program header entry count: ')
      ..writeln(programHeaderCount)
      ..write('Section header offset: 0x')
      ..writeln(paddedHex(sectionHeaderOffset, wordSize))
      ..write('Section header entry size: ')
      ..writeln(sectionHeaderEntrySize)
      ..write('Section header entry count: ')
      ..writeln(sectionHeaderCount)
      ..write('Section header strings index: ')
      ..write(sectionHeaderStringsIndex);
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
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

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Type: ')
      ..writeln(_typeToString(type))
      ..write('Flags: 0x')
      ..writeln(paddedHex(flags, 4))
      ..write('Offset: 0x')
      ..writeln(paddedHex(offset, reader.wordSize))
      ..write('Virtual address: 0x')
      ..writeln(paddedHex(vaddr, reader.wordSize))
      ..write('Physical address: 0x')
      ..writeln(paddedHex(paddr, reader.wordSize))
      ..write('Size in file: ')
      ..writeln(filesz)
      ..write('Size in memory')
      ..writeln(memsz)
      ..write('Alignment: 0x')
      ..write(paddedHex(align, reader.wordSize));
  }

  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
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

  void writeToStringBuffer(StringBuffer buffer) {
    for (var i = 0; i < length; i++) {
      if (i != 0) buffer..writeln()..writeln();
      buffer
        ..write('Entry ')
        ..write(i)
        ..writeln(':');
      _entries[i].writeToStringBuffer(buffer);
    }
  }

  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class SectionHeaderEntry {
  final Reader reader;

  int nameIndex;
  String _cachedName;
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
    _cachedName = nameTable[nameIndex];
  }

  String get name => _cachedName != null ? _cachedName : '<${nameIndex}>';

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

  void writeToStringBuffer(StringBuffer buffer) {
    buffer.write('Name: ');
    if (_cachedName != null) {
      buffer
        ..write('"')
        ..write(name)
        ..write('" (@ ')
        ..write(nameIndex)
        ..writeln(')');
    } else {
      buffer.writeln(name);
    }
    buffer
      ..write('Type: ')
      ..writeln(_typeToString(type))
      ..write('Flags: 0x')
      ..writeln(paddedHex(flags, reader.wordSize))
      ..write('Address: 0x')
      ..writeln(paddedHex(addr, reader.wordSize))
      ..write('Offset: 0x')
      ..writeln(paddedHex(offset, reader.wordSize))
      ..write('Size: ')
      ..writeln(size)
      ..write('Link: ')
      ..writeln(link)
      ..write('Info: 0x')
      ..writeln(paddedHex(info, 4))
      ..write('Address alignment: 0x')
      ..writeln(paddedHex(addrAlign, reader.wordSize))
      ..write('Entry size: ')
      ..write(entrySize);
  }

  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
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

  void writeToStringBuffer(StringBuffer buffer) {
    for (var i = 0; i < length; i++) {
      if (i != 0) buffer..writeln()..writeln();
      buffer
        ..write('Entry ')
        ..write(i)
        ..writeln(':');
      _entries[i].writeToStringBuffer(buffer);
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
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

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Section "')
      ..write(headerEntry.name)
      ..write('" is unparsed and ')
      ..write(length)
      ..writeln(' bytes long.');
  }

  @override
  String toString() {
    StringBuffer buffer;
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class StringTable extends Section {
  final _entries;

  StringTable(SectionHeaderEntry entry, Reader reader)
      : _entries = Map<int, String>.fromEntries(
            reader.readRepeated((r) => r.readNullTerminatedString())),
        super(entry, reader);

  String operator [](int index) => _entries[index];
  bool containsKey(int index) => _entries.containsKey(index);

  @override
  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Section "')
      ..write(headerEntry.name)
      ..writeln('" is a string table:');
    for (var key in _entries.keys) {
      buffer
        ..write("  ")
        ..write(key)
        ..write(" => ")
        ..writeln(_entries[key]);
    }
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

  void writeToStringBuffer(StringBuffer buffer) {
    if (name != null) {
      buffer..write('"')..write(name)..write('" =>');
    } else {
      buffer..write('<')..write(nameIndex)..write('> =>');
    }
    switch (bind) {
      case SymbolBinding.STB_GLOBAL:
        buffer..write(' a global');
        break;
      case SymbolBinding.STB_LOCAL:
        buffer..write(' a local');
        break;
    }
    switch (visibility) {
      case SymbolVisibility.STV_DEFAULT:
        break;
      case SymbolVisibility.STV_HIDDEN:
        buffer..write(' hidden');
        break;
      case SymbolVisibility.STV_INTERNAL:
        buffer..write(' internal');
        break;
      case SymbolVisibility.STV_PROTECTED:
        buffer..write(' protected');
        break;
    }
    buffer
      ..write(" symbol that points to ")
      ..write(size)
      ..write(" bytes at location 0x")
      ..write(paddedHex(value, _wordSize))
      ..write(" in section ")
      ..write(sectionIndex);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class SymbolTable extends Section {
  final List<Symbol> _entries;
  final _nameCache = Map<String, Symbol>();

  SymbolTable(SectionHeaderEntry entry, Reader reader)
      : _entries = reader
            .readRepeated(Symbol.fromReader)
            .map((kv) => kv.value)
            .toList(),
        super(entry, reader);

  void _cacheNames(StringTable stringTable) {
    _nameCache.clear();
    for (final symbol in _entries) {
      symbol._cacheNameFromStringTable(stringTable);
      _nameCache[symbol.name] = symbol;
    }
  }

  Iterable<String> get keys => _nameCache.keys;
  Symbol operator [](String name) => _nameCache[name];
  bool containsKey(String name) => _nameCache.containsKey(name);

  @override
  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Section "')
      ..write(headerEntry.name)
      ..writeln('" is a symbol table:');
    for (var symbol in _entries) {
      buffer.write(" ");
      symbol.writeToStringBuffer(buffer);
      buffer.writeln();
    }
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

  /// Lookup of a dynamic symbol by name.
  ///
  /// Returns -1 if there is no dynamic symbol that matches [name].
  Symbol dynamicSymbolFor(String name) {
    for (final SymbolTable dynsym in namedSections(".dynsym")) {
      if (dynsym.containsKey(name)) {
        return dynsym[name];
      }
    }
    return null;
  }

  /// The [Section]s whose names match [name].
  Iterable<Section> namedSections(String name) {
    return _sections.keys
        .where((entry) => entry.name == name)
        .map((entry) => _sections[entry]);
  }

  /// Reverse lookup of the static symbol that contains the given virtual
  /// address. Returns null if no static symbol matching the address is found.
  Symbol staticSymbolAt(int address) {
    for (final SymbolTable table in namedSections('.symtab')) {
      for (final name in table.keys) {
        final symbol = table[name];
        if (symbol.value <= address && address < (symbol.value + symbol.size)) {
          return symbol;
        }
      }
    }
    return null;
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
    for (var i = 0; i < sectionHeader.length; i++) {
      final entry = sectionHeader[i];
      if (i == header.sectionHeaderStringsIndex) {
        sections[entry] = sectionHeader.nameTable;
        continue;
      }
      sections[entry] = Section.fromEntryAndReader(
          entry, reader.refocus(entry.offset, entry.size));
    }
    void _cacheSymbolNames(String stringTableTag, String symbolTableTag) {
      final stringTables = <SectionHeaderEntry, StringTable>{};
      final symbolTables = <SymbolTable>[];
      for (final entry in sections.keys) {
        if (entry.name == stringTableTag) {
          stringTables[entry] = sections[entry];
        } else if (entry.name == symbolTableTag) {
          symbolTables.add(sections[entry]);
        }
      }
      for (final symbolTable in symbolTables) {
        final link = symbolTable.headerEntry.link;
        final entry = sectionHeader[link];
        if (!stringTables.containsKey(entry)) {
          throw FormatException(
              "String table not found at section header entry ${link}");
        }
        symbolTable._cacheNames(stringTables[entry]);
      }
    }

    _cacheSymbolNames('.strtab', '.symtab');
    _cacheSymbolNames('.dynstr', '.dynsym');
    return Elf._(header, programHeader, sectionHeader, sections);
  }

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..writeln('-----------------------------------------------------')
      ..writeln('             ELF header information')
      ..writeln('-----------------------------------------------------')
      ..writeln();
    _header.writeToStringBuffer(buffer);
    buffer
      ..writeln()
      ..writeln()
      ..writeln('-----------------------------------------------------')
      ..writeln('            Program header information')
      ..writeln('-----------------------------------------------------')
      ..writeln();
    _programHeader.writeToStringBuffer(buffer);
    buffer
      ..writeln()
      ..writeln()
      ..writeln('-----------------------------------------------------')
      ..writeln('            Section header information')
      ..writeln('-----------------------------------------------------')
      ..writeln();
    _sectionHeader.writeToStringBuffer(buffer);
    buffer
      ..writeln()
      ..writeln()
      ..writeln('-----------------------------------------------------')
      ..writeln('                 Section information')
      ..writeln('-----------------------------------------------------')
      ..writeln();
    for (final entry in _sections.keys) {
      _sections[entry].writeToStringBuffer(buffer);
      buffer.writeln();
    }
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}
