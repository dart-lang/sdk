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

/// The header of the ELF file, which includes information necessary to parse
/// the rest of the file.
class ElfHeader {
  final int wordSize;
  final Endian endian;
  final int entry;
  final int flags;
  final int headerSize;
  final int programHeaderOffset;
  final int programHeaderCount;
  final int programHeaderEntrySize;
  final int sectionHeaderOffset;
  final int sectionHeaderCount;
  final int sectionHeaderEntrySize;
  final int sectionHeaderStringsIndex;

  ElfHeader._(
      this.wordSize,
      this.endian,
      this.entry,
      this.flags,
      this.headerSize,
      this.programHeaderOffset,
      this.sectionHeaderOffset,
      this.programHeaderCount,
      this.sectionHeaderCount,
      this.programHeaderEntrySize,
      this.sectionHeaderEntrySize,
      this.sectionHeaderStringsIndex);

  static ElfHeader? fromReader(Reader reader) {
    final fileSize = reader.length;

    for (final sigByte in _ELFMAG.codeUnits) {
      if (reader.readByte() != sigByte) {
        return null;
      }
    }

    int wordSize;
    switch (reader.readByte()) {
      case _ELFCLASS32:
        wordSize = 4;
        break;
      case _ELFCLASS64:
        wordSize = 8;
        break;
      default:
        throw FormatException("Unexpected e_ident[EI_CLASS] value");
    }
    final calculatedHeaderSize = 0x18 + 3 * wordSize + 0x10;

    if (fileSize < calculatedHeaderSize) {
      throw FormatException("ELF file too small for header: "
          "file size ${fileSize} < "
          "calculated header size $calculatedHeaderSize");
    }

    Endian endian;
    switch (reader.readByte()) {
      case _ELFDATA2LSB:
        endian = Endian.little;
        break;
      case _ELFDATA2MSB:
        endian = Endian.big;
        break;
      default:
        throw FormatException("Unexpected e_indent[EI_DATA] value");
    }

    if (reader.readByte() != 0x01) {
      throw FormatException("Unexpected e_ident[EI_VERSION] value");
    }

    // After this point, we need the reader to be correctly set up re: word
    // size and endianness, since we start reading more than single bytes.
    reader.endian = endian;
    reader.wordSize = wordSize;

    // Skip rest of e_ident/e_type/e_machine, i.e. move to e_version.
    reader.seek(0x14, absolute: true);
    if (_readElfWord(reader) != 0x01) {
      throw FormatException("Unexpected e_version value");
    }

    final entry = _readElfAddress(reader);
    final programHeaderOffset = _readElfOffset(reader);
    final sectionHeaderOffset = _readElfOffset(reader);
    final flags = _readElfWord(reader);
    final headerSize = _readElfHalf(reader);

    final programHeaderEntrySize = _readElfHalf(reader);
    final programHeaderCount = _readElfHalf(reader);
    final programHeaderSize = programHeaderEntrySize * programHeaderCount;

    final sectionHeaderEntrySize = _readElfHalf(reader);
    final sectionHeaderCount = _readElfHalf(reader);
    final sectionHeaderSize = sectionHeaderEntrySize * sectionHeaderCount;

    final sectionHeaderStringsIndex = _readElfHalf(reader);

    if (reader.offset != headerSize) {
      throw FormatException("Only read ${reader.offset} bytes, not the "
          "full header size ${headerSize}");
    }

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

    return ElfHeader._(
        wordSize,
        endian,
        entry,
        flags,
        headerSize,
        programHeaderOffset,
        sectionHeaderOffset,
        programHeaderCount,
        sectionHeaderCount,
        programHeaderEntrySize,
        sectionHeaderEntrySize,
        sectionHeaderStringsIndex);
  }

  int get programHeaderSize => programHeaderCount * programHeaderEntrySize;
  int get sectionHeaderSize => sectionHeaderCount * sectionHeaderEntrySize;

  // Constants used within the ELF specification.
  static const _ELFMAG = "\x7fELF";
  static const _ELFCLASS32 = 0x01;
  static const _ELFCLASS64 = 0x02;
  static const _ELFDATA2LSB = 0x01;
  static const _ELFDATA2MSB = 0x02;

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

/// An entry in the [ProgramHeader] describing a memory segment loaded into
/// memory and used during runtime.
class ProgramHeaderEntry {
  final int type;
  final int flags;
  final int offset;
  final int vaddr;
  final int paddr;
  final int filesz;
  final int memsz;
  final int align;
  final int wordSize;

  // p_type constants from ELF specification.
  static const _PT_NULL = 0;
  static const _PT_LOAD = 1;
  static const _PT_DYNAMIC = 2;
  static const _PT_PHDR = 6;

  ProgramHeaderEntry._(this.type, this.flags, this.offset, this.vaddr,
      this.paddr, this.filesz, this.memsz, this.align, this.wordSize);

  static ProgramHeaderEntry fromReader(Reader reader) {
    int wordSize = reader.wordSize;
    assert(wordSize == 4 || wordSize == 8);
    final type = _readElfWord(reader);
    late int flags;
    if (wordSize == 8) {
      flags = _readElfWord(reader);
    }
    final offset = _readElfOffset(reader);
    final vaddr = _readElfAddress(reader);
    final paddr = _readElfAddress(reader);
    final filesz = _readElfNative(reader);
    final memsz = _readElfNative(reader);
    if (wordSize == 4) {
      flags = _readElfWord(reader);
    }
    final align = _readElfNative(reader);
    return ProgramHeaderEntry._(
        type, flags, offset, vaddr, paddr, filesz, memsz, align, wordSize);
  }

  static const _typeStrings = <int, String>{
    _PT_NULL: "PT_NULL",
    _PT_LOAD: "PT_LOAD",
    _PT_DYNAMIC: "PT_DYNAMIC",
    _PT_PHDR: "PT_PHDR",
  };

  static String _typeToString(int type) =>
      _typeStrings[type] ?? "unknown (${paddedHex(type, 4)})";

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Type: ')
      ..writeln(_typeToString(type))
      ..write('Flags: 0x')
      ..writeln(paddedHex(flags, 4))
      ..write('Offset: 0x')
      ..writeln(paddedHex(offset, wordSize))
      ..write('Virtual address: 0x')
      ..writeln(paddedHex(vaddr, wordSize))
      ..write('Physical address: 0x')
      ..writeln(paddedHex(paddr, wordSize))
      ..write('Size in file: ')
      ..writeln(filesz)
      ..write('Size in memory: ')
      ..writeln(memsz)
      ..write('Alignment: 0x')
      ..write(paddedHex(align, wordSize));
  }

  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

/// A list of [ProgramHeaderEntry]s describing the memory segments loaded at
/// runtime when this file is used.
class ProgramHeader {
  final List<ProgramHeaderEntry> _entries;

  ProgramHeader._(this._entries);

  int get length => _entries.length;
  ProgramHeaderEntry operator [](int index) => _entries[index];

  static ProgramHeader fromReader(Reader reader, ElfHeader header) {
    final programReader = reader.refocusedCopy(
        header.programHeaderOffset, header.programHeaderSize);
    final entries =
        programReader.readRepeated(ProgramHeaderEntry.fromReader).toList();
    return ProgramHeader._(entries);
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

/// An entry in the [SectionHeader] that describes a single [Section].
class SectionHeaderEntry {
  final int nameIndex;
  final int type;
  final int flags;
  final int addr;
  final int offset;
  final int size;
  final int link;
  final int info;
  final int addrAlign;
  final int entrySize;
  final int wordSize;
  late String name;

  SectionHeaderEntry._(
      this.nameIndex,
      this.type,
      this.flags,
      this.addr,
      this.offset,
      this.size,
      this.link,
      this.info,
      this.addrAlign,
      this.entrySize,
      this.wordSize);

  static SectionHeaderEntry fromReader(Reader reader) {
    final nameIndex = _readElfWord(reader);
    final type = _readElfWord(reader);
    final flags = _readElfNative(reader);
    final addr = _readElfAddress(reader);
    final offset = _readElfOffset(reader);
    final size = _readElfNative(reader);
    final link = _readElfWord(reader);
    final info = _readElfWord(reader);
    final addrAlign = _readElfNative(reader);
    final entrySize = _readElfNative(reader);
    return SectionHeaderEntry._(nameIndex, type, flags, addr, offset, size,
        link, info, addrAlign, entrySize, reader.wordSize);
  }

  // sh_type constants from ELF specification.
  static const _SHT_NULL = 0;
  static const _SHT_PROGBITS = 1;
  static const _SHT_SYMTAB = 2;
  static const _SHT_STRTAB = 3;
  static const _SHT_HASH = 5;
  static const _SHT_DYNAMIC = 6;
  static const _SHT_NOTE = 7;
  static const _SHT_NOBITS = 8;
  static const _SHT_DYNSYM = 11;

  void setName(StringTable nameTable) {
    name = nameTable[nameIndex]!;
  }

  static const _typeStrings = <int, String>{
    _SHT_NULL: "SHT_NULL",
    _SHT_PROGBITS: "SHT_PROGBITS",
    _SHT_SYMTAB: "SHT_SYMTAB",
    _SHT_STRTAB: "SHT_STRTAB",
    _SHT_HASH: "SHT_HASH",
    _SHT_DYNAMIC: "SHT_DYNAMIC",
    _SHT_NOTE: "SHT_NOTE",
    _SHT_NOBITS: "SHT_NOBITS",
    _SHT_DYNSYM: "SHT_DYNSYM",
  };

  static String _typeToString(int type) =>
      _typeStrings[type] ?? "unknown (${paddedHex(type, 4)})";

  void writeToStringBuffer(StringBuffer buffer) {
    buffer.write('Name: ');
    buffer
      ..write('"')
      ..write(name)
      ..write('" (@ ')
      ..write(nameIndex)
      ..writeln(')');
    buffer
      ..write('Type: ')
      ..writeln(_typeToString(type))
      ..write('Flags: 0x')
      ..writeln(paddedHex(flags, wordSize))
      ..write('Address: 0x')
      ..writeln(paddedHex(addr, wordSize))
      ..write('Offset: 0x')
      ..writeln(paddedHex(offset, wordSize))
      ..write('Size: ')
      ..writeln(size)
      ..write('Link: ')
      ..writeln(link)
      ..write('Info: 0x')
      ..writeln(paddedHex(info, 4))
      ..write('Address alignment: 0x')
      ..writeln(paddedHex(addrAlign, wordSize))
      ..write('Entry size: ')
      ..write(entrySize);
  }

  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

/// A list of [SectionHeaderEntry]s describing the [Section]s in the ELF file.
class SectionHeader {
  final List<SectionHeaderEntry> entries;

  SectionHeader._(this.entries);

  static SectionHeader fromReader(Reader reader, ElfHeader header) {
    final headerReader = reader.refocusedCopy(
        header.sectionHeaderOffset, header.sectionHeaderSize);
    final entries =
        headerReader.readRepeated(SectionHeaderEntry.fromReader).toList();
    final nameTableEntry = entries[header.sectionHeaderStringsIndex];
    assert(nameTableEntry.type == SectionHeaderEntry._SHT_STRTAB);
    return SectionHeader._(entries);
  }

  void writeToStringBuffer(StringBuffer buffer) {
    for (var i = 0; i < entries.length; i++) {
      if (i != 0) buffer..writeln()..writeln();
      buffer
        ..write('Entry ')
        ..write(i)
        ..writeln(':');
      entries[i].writeToStringBuffer(buffer);
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

/// A section in an ELF file.
///
/// Some sections correspond to segments from the [ProgramHeader] and contain
/// the information that will be loaded into memory for that segment, whereas
/// others include information, like debugging sections, that are not loaded
/// at runtime.
///
/// Only some sections are currently parsed by the  ELF reader; most are left
/// unparsed as they are not needed for DWARF address translation.
class Section {
  final SectionHeaderEntry headerEntry;

  Section._(this.headerEntry);

  static Section fromReader(Reader reader, SectionHeaderEntry entry) {
    switch (entry.type) {
      case SectionHeaderEntry._SHT_STRTAB:
        return StringTable.fromReader(reader, entry);
      case SectionHeaderEntry._SHT_SYMTAB:
        return SymbolTable.fromReader(reader, entry);
      case SectionHeaderEntry._SHT_DYNSYM:
        return SymbolTable.fromReader(reader, entry);
      case SectionHeaderEntry._SHT_NOTE:
        return Note.fromReader(reader, entry);
      default:
        return Section._(entry);
    }
  }

  int get offset => headerEntry.offset;
  int get virtualAddress => headerEntry.addr;
  int get length => headerEntry.size;

  // Convenience function for preparing a reader to read a particular section.
  Reader refocusedCopy(Reader reader) => reader.refocusedCopy(offset, length);

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
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

/// A section that contains a single note.
class Note extends Section {
  final int type;
  final String name;
  final Uint8List description;

  Note._(entry, this.type, this.name, this.description) : super._(entry);

  static Note fromReader(Reader originalReader, SectionHeaderEntry entry) {
    final reader = originalReader.refocusedCopy(entry.offset, entry.size);
    final nameLength = reader.readBytes(4);
    final descriptionLength = reader.readBytes(4);
    final type = reader.readBytes(4);
    final nameEnd = reader.offset + nameLength;
    final name = reader.readNullTerminatedString();
    assert(reader.offset == nameEnd);
    assert(reader.length - reader.offset == descriptionLength);
    final descriptionStart = reader.offset;
    final descriptionEnd = descriptionStart + descriptionLength;
    final description =
        Uint8List.sublistView(reader.bdata, descriptionStart, descriptionEnd);
    return Note._(entry, type, name, description);
  }

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Section "')
      ..write(headerEntry.name)
      ..writeln('" is a note:');
    buffer
      ..write('  Type: ')
      ..writeln(type);
    buffer
      ..write('  Name: "')
      ..write(name)
      ..writeln('"');
    buffer
      ..write('  Description: ')
      ..writeln(description);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

/// A map from table offsets to strings, used to store names of ELF objects.
class StringTable extends Section {
  final Map<int, String> _entries;

  StringTable._(entry, this._entries) : super._(entry);

  static StringTable fromReader(Reader reader, SectionHeaderEntry entry) {
    final sectionReader = reader.refocusedCopy(entry.offset, entry.size);
    final entries = Map.fromEntries(sectionReader
        .readRepeatedWithOffsets((r) => r.readNullTerminatedString()));
    return StringTable._(entry, entries);
  }

  String? operator [](int index) => _entries[index];
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

/// A symbol in an ELF file, which names a portion of the virtual address space.
class Symbol {
  final int nameIndex;
  final int info;
  final int other;
  final int sectionIndex;
  final int value;
  final int size;
  final int _wordSize;
  late String name;

  Symbol._(this.nameIndex, this.info, this.other, this.sectionIndex, this.value,
      this.size, this._wordSize);

  static Symbol fromReader(Reader reader) {
    final wordSize = reader.wordSize;
    final nameIndex = _readElfWord(reader);
    late int info;
    late int other;
    late int sectionIndex;
    if (wordSize == 8) {
      info = reader.readByte();
      other = reader.readByte();
      sectionIndex = _readElfSection(reader);
    }
    final value = _readElfAddress(reader);
    final size = _readElfNative(reader);
    if (wordSize == 4) {
      info = reader.readByte();
      other = reader.readByte();
      sectionIndex = _readElfSection(reader);
    }
    return Symbol._(
        nameIndex, info, other, sectionIndex, value, size, wordSize);
  }

  void _cacheNameFromStringTable(StringTable table) {
    final nameFromTable = table[nameIndex];
    if (nameFromTable == null) {
      throw FormatException("Index $nameIndex not found in string table");
    }
    name = nameFromTable;
  }

  SymbolBinding get bind => SymbolBinding.values[info >> 4];
  SymbolType get type => SymbolType.values[info & 0x0f];
  SymbolVisibility get visibility => SymbolVisibility.values[other & 0x03];

  void writeToStringBuffer(StringBuffer buffer) {
    buffer..write('"')..write(name)..write('" =>');
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

/// A table of (static or dynamic) [Symbol]s.
class SymbolTable extends Section {
  final List<Symbol> _entries;
  final Map<String, Symbol> _nameCache;

  SymbolTable._(SectionHeaderEntry entry, this._entries)
      : _nameCache = {},
        super._(entry);

  static SymbolTable fromReader(Reader reader, SectionHeaderEntry entry) {
    final sectionReader = reader.refocusedCopy(entry.offset, entry.size);
    final entries = sectionReader.readRepeated(Symbol.fromReader).toList();
    return SymbolTable._(entry, entries);
  }

  void _cacheNames(StringTable stringTable) {
    _nameCache.clear();
    for (final symbol in _entries) {
      symbol._cacheNameFromStringTable(stringTable);
      _nameCache[symbol.name] = symbol;
    }
  }

  Iterable<String> get keys => _nameCache.keys;
  Iterable<Symbol> get values => _entries;
  Symbol? operator [](String name) => _nameCache[name];
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

/// Information parsed from an Executable and Linking Format (ELF) file.
class Elf {
  final ElfHeader _header;
  final ProgramHeader _programHeader;
  final SectionHeader _sectionHeader;
  final Map<SectionHeaderEntry, Section> _sections;
  final Map<String, Set<Section>> _sectionsByName;

  Elf._(this._header, this._programHeader, this._sectionHeader, this._sections,
      this._sectionsByName);

  /// Creates an [Elf] from [bytes].
  ///
  /// Returns null if the file does not start with the ELF magic number.
  static Elf? fromBuffer(Uint8List bytes) =>
      Elf.fromReader(Reader.fromTypedData(bytes));

  /// Creates an [Elf] from the file at [path].
  ///
  /// Returns null if the file does not start with the ELF magic number.
  static Elf? fromFile(String path) => Elf.fromReader(Reader.fromFile(path));

  Iterable<Section> namedSections(String name) =>
      _sectionsByName[name] ?? <Section>[];

  /// Lookup of a dynamic symbol by name.
  ///
  /// Returns -1 if there is no dynamic symbol that matches [name].
  Symbol? dynamicSymbolFor(String name) {
    for (final section in namedSections(".dynsym")) {
      final dynsym = section as SymbolTable;
      if (dynsym.containsKey(name)) return dynsym[name];
    }
    return null;
  }

  /// Reverse lookup of the static symbol that contains the given virtual
  /// address. Returns null if no static symbol matching the address is found.
  Symbol? staticSymbolAt(int address) {
    for (final section in namedSections('.symtab')) {
      final table = section as SymbolTable;
      for (final symbol in table.values) {
        final start = symbol.value;
        final end = start + symbol.size;
        if (start <= address && address < end) return symbol;
      }
    }
    return null;
  }

  /// Creates an [Elf] from the data pointed to by [reader].
  ///
  /// After succesful completion, the [endian] and [wordSize] fields of the
  /// reader are set to match the values read from the ELF header. The position
  /// of the reader will be unchanged.
  ///
  /// Returns null if the file does not start with the ELF magic number.
  static Elf? fromReader(Reader elfReader) {
    // ELF files contain absolute offsets from the start of the file, so
    // make sure we have a reader that a) makes no assumptions about the
    // endianness or word size, since we'll read those in the header and b)
    // has an internal offset of 0 so absolute offsets can be used directly.
    final reader = Reader.fromTypedData(ByteData.sublistView(
        elfReader.bdata, elfReader.bdata.offsetInBytes + elfReader.offset));
    final header = ElfHeader.fromReader(reader);
    // Only happens if the file didn't start with the expected magic number.
    if (header == null) return null;
    // At this point, the endianness and wordSize should have been set
    // during ElfHeader.fromReader.
    assert(reader.endian != null && reader.wordSize != null);
    final programHeader = ProgramHeader.fromReader(reader, header);
    final sectionHeader = SectionHeader.fromReader(reader, header);
    final sections = <SectionHeaderEntry, Section>{};
    for (var i = 0; i < sectionHeader.entries.length; i++) {
      final entry = sectionHeader.entries[i];
      sections[entry] = Section.fromReader(reader, entry);
    }
    // Now set up the by-name section table and cache the names in the section
    // header entries.
    if (header.sectionHeaderStringsIndex < 0 ||
        header.sectionHeaderStringsIndex >= sectionHeader.entries.length) {
      throw FormatException("Section header string table index invalid");
    }
    final sectionHeaderStringTableEntry =
        sectionHeader.entries[header.sectionHeaderStringsIndex];
    final sectionHeaderStringTable =
        sections[sectionHeaderStringTableEntry] as StringTable?;
    if (sectionHeaderStringTable == null) {
      throw FormatException(
          "No section for entry ${sectionHeaderStringTableEntry}");
    }
    final sectionsByName = <String, Set<Section>>{};
    for (final entry in sectionHeader.entries) {
      final section = sections[entry];
      if (section == null) {
        throw FormatException("No section found for entry ${entry}");
      }
      entry.setName(sectionHeaderStringTable);
      sectionsByName.putIfAbsent(entry.name, () => {}).add(section);
    }
    void _cacheSymbolNames(String stringTableTag, String symbolTableTag) {
      final stringTables = sectionsByName[stringTableTag]?.cast<StringTable>();
      if (stringTables == null) {
        return;
      }
      final stringTableMap =
          Map.fromEntries(stringTables.map((s) => MapEntry(s.headerEntry, s)));
      final symbolTables = sectionsByName[symbolTableTag]?.cast<SymbolTable>();
      if (symbolTables == null) {
        return;
      }
      for (final symbolTable in symbolTables) {
        final link = symbolTable.headerEntry.link;
        final entry = sectionHeader.entries[link];
        final stringTable = stringTableMap[entry];
        if (stringTable == null) {
          throw FormatException(
              "String table not found at section header entry ${link}");
        }
        symbolTable._cacheNames(stringTable);
      }
    }

    _cacheSymbolNames('.strtab', '.symtab');
    _cacheSymbolNames('.dynstr', '.dynsym');
    // Set the wordSize and endian of the original reader before returning.
    elfReader.wordSize = reader.wordSize;
    elfReader.endian = reader.endian;
    return Elf._(
        header, programHeader, sectionHeader, sections, sectionsByName);
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
    for (final entry in _sectionHeader.entries) {
      _sections[entry]!.writeToStringBuffer(buffer);
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
