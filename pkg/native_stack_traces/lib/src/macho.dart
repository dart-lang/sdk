// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'constants.dart' as constants;
import 'dwarf_container.dart';
import 'reader.dart';

int _readMachOUint8(Reader reader) => reader.readByte(signed: false);

int _readMachOUint16(Reader reader) => reader.readBytes(2, signed: false);

int _readMachOUint32(Reader reader) => reader.readBytes(4, signed: false);

int _readMachOUword(Reader reader) =>
    reader.readBytes(reader.wordSize, signed: false);

class StringTable implements DwarfContainerStringTable {
  final Map<int, String> _stringsByOffset;

  StringTable._(this._stringsByOffset);

  static StringTable fromReader(Reader reader) => StringTable._(Map.fromEntries(
      reader.readRepeatedWithOffsets((r) => r.readNullTerminatedString())));

  @override
  String? operator [](int index) {
    // Fast case: Index is for the start of a null terminated string.
    if (_stringsByOffset.containsKey(index)) {
      return _stringsByOffset[index];
    }
    // We can index into null terminated string entries for suffixes of
    // that string, so do a linear search to find the appropriate entry.
    for (final kv in _stringsByOffset.entries) {
      final start = index - kv.key;
      if (start >= 0 && start <= kv.value.length) {
        return kv.value.substring(start);
      }
    }
    return null;
  }

  void writeToStringBuffer(StringBuffer buffer) {
    for (final k in _stringsByOffset.keys) {
      buffer
        ..write(k.toString().padLeft(8, ' '))
        ..write(' => ')
        ..writeln(_stringsByOffset[k]);
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class Symbol implements DwarfContainerSymbol {
  final int index;
  final int type;
  final int sect;
  final int desc;
  @override
  final int value;
  @override
  late final String name;

  Symbol._(this.index, this.type, this.sect, this.desc, this.value);

  static Symbol fromReader(Reader reader) {
    final index = _readMachOUint32(reader);
    final type = _readMachOUint8(reader);
    final sect = _readMachOUint8(reader);
    final desc = _readMachOUint16(reader);
    final value = _readMachOUword(reader);
    return Symbol._(index, type, sect, desc, value);
  }
}

class SymbolTable {
  final Map<String, Symbol> _symbols;

  SymbolTable._(this._symbols);

  static SymbolTable fromReader(
      Reader reader, int nsyms, StringTable stringTable) {
    final symbols = <String, Symbol>{};
    for (int i = 0; i < nsyms; i++) {
      final symbol = Symbol.fromReader(reader);
      final index = symbol.index;
      final name = stringTable[index];
      if (name == null) {
        throw FormatException('Index $index not found in string table');
      }
      symbol.name = name;
      symbols[name] = symbol;
    }
    return SymbolTable._(symbols);
  }

  Iterable<String> get keys => _symbols.keys;
  Iterable<Symbol> get values => _symbols.values;

  Symbol? operator [](String name) => _symbols[name];

  bool containsKey(String name) => _symbols.containsKey(name);
}

class LoadCommand {
  final int cmd;
  final int cmdsize;

  LoadCommand._(this.cmd, this.cmdsize);

  static const LC_SEGMENT = 0x1;
  static const LC_SYMTAB = 0x2;
  static const LC_SEGMENT_64 = 0x19;

  static LoadCommand fromReader(Reader reader) {
    final start = reader.offset; // cmdsize includes size of cmd and cmdsize.
    final cmd = _readMachOUint32(reader);
    final cmdsize = _readMachOUint32(reader);
    assert(reader.remaining >= cmdsize - (reader.offset - start));
    LoadCommand command = LoadCommand._(cmd, cmdsize);
    switch (cmd) {
      case LC_SEGMENT:
      case LC_SEGMENT_64:
        command = SegmentCommand.fromReader(reader, cmd, cmdsize);
        break;
      case LC_SYMTAB:
        command = SymbolTableCommand.fromReader(reader, cmd, cmdsize);
        break;
      default:
        break;
    }
    reader.seek(start + cmdsize, absolute: true);
    return command;
  }

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Uninterpreted command 0x')
      ..write(cmd.toRadixString(16))
      ..write(' of size ')
      ..writeln(cmdsize);
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class SegmentCommand extends LoadCommand {
  final String segname;
  final int vmaddr;
  final int vmsize;
  final int fileoff;
  final int filesize;
  final int maxprot;
  final int initprot;
  final int nsects;
  final int flags;
  final Map<String, Section> sections;

  SegmentCommand._(
      int cmd,
      int cmdsize,
      this.segname,
      this.vmaddr,
      this.vmsize,
      this.fileoff,
      this.filesize,
      this.maxprot,
      this.initprot,
      this.nsects,
      this.flags,
      this.sections)
      : super._(cmd, cmdsize);

  static SegmentCommand fromReader(Reader reader, int cmd, int cmdsize) {
    final segname = reader.readFixedLengthNullTerminatedString(16);
    final vmaddr = _readMachOUword(reader);
    final vmsize = _readMachOUword(reader);
    final fileoff = _readMachOUword(reader);
    final filesize = _readMachOUword(reader);
    final maxprot = _readMachOUint32(reader);
    final initprot = _readMachOUint32(reader);
    final nsects = _readMachOUint32(reader);
    final flags = _readMachOUint32(reader);
    final sections = <String, Section>{};
    for (int i = 0; i < nsects; i++) {
      final section = Section.fromReader(reader);
      sections[section.sectname] = section;
    }
    return SegmentCommand._(cmd, cmdsize, segname, vmaddr, vmsize, fileoff,
        filesize, maxprot, initprot, nsects, flags, sections);
  }

  @override
  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Segment "')
      ..write(segname)
      ..write('" of size ')
      ..write(filesize)
      ..write(' at offset 0x')
      ..writeln(fileoff.toRadixString(16));
    buffer.writeln('Sections:');
    for (final section in sections.values) {
      section.writeToStringBuffer(buffer);
      buffer.writeln();
    }
  }
}

class Section {
  String sectname;
  String segname;
  int addr;
  int size;
  int offset;
  int align;
  int reloff;
  int nreloc;
  int flags;
  int reserved1;
  int reserved2;
  int? reserved3;

  Section._(
      this.sectname,
      this.segname,
      this.addr,
      this.size,
      this.offset,
      this.align,
      this.reloff,
      this.nreloc,
      this.flags,
      this.reserved1,
      this.reserved2,
      this.reserved3);

  static Section fromReader(Reader reader) {
    final sectname = reader.readFixedLengthNullTerminatedString(16);
    final segname = reader.readFixedLengthNullTerminatedString(16);
    final addr = _readMachOUword(reader);
    final size = _readMachOUword(reader);
    final offset = _readMachOUint32(reader);
    final align = _readMachOUint32(reader);
    final reloff = _readMachOUint32(reader);
    final nreloc = _readMachOUint32(reader);
    final flags = _readMachOUint32(reader);
    final reserved1 = _readMachOUint32(reader);
    final reserved2 = _readMachOUint32(reader);
    final reserved3 = (reader.wordSize == 8) ? _readMachOUint32(reader) : null;
    return Section._(sectname, segname, addr, size, offset, align, reloff,
        nreloc, flags, reserved1, reserved2, reserved3);
  }

  Reader shrink(Reader reader) => reader.shrink(offset, size);

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Section "')
      ..write(sectname)
      ..write('" of size ')
      ..write(size)
      ..write(' at offset 0x')
      ..write(paddedHex(offset, 4));
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class SymbolTableCommand extends LoadCommand {
  final int _symoff;
  final int _nsyms;
  final int _stroff;
  final int _strsize;

  SymbolTableCommand._(int cmd, int cmdsize, this._symoff, this._nsyms,
      this._stroff, this._strsize)
      : super._(cmd, cmdsize);

  static SymbolTableCommand fromReader(Reader reader, int cmd, int cmdsize) {
    final symoff = _readMachOUint32(reader);
    final nsyms = _readMachOUint32(reader);
    final stroff = _readMachOUint32(reader);
    final strsize = _readMachOUint32(reader);
    return SymbolTableCommand._(cmd, cmdsize, symoff, nsyms, stroff, strsize);
  }

  SymbolTable load(Reader reader) {
    final stringTable =
        StringTable.fromReader(reader.shrink(_stroff, _strsize));
    return SymbolTable.fromReader(reader.shrink(_symoff), _nsyms, stringTable);
  }

  @override
  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Symbol table with ')
      ..write(_nsyms)
      ..write(' symbols of size ')
      ..writeln(cmdsize);
  }
}

class MachOHeader {
  final int magic;
  final int cputype;
  final int cpusubtype;
  final int filetype;
  final int ncmds;
  final int sizeofcmds;
  final int flags;
  final int? reserved;
  final int size;

  MachOHeader._(this.magic, this.cputype, this.cpusubtype, this.filetype,
      this.ncmds, this.sizeofcmds, this.flags, this.reserved, this.size);

  static const _MH_MAGIC = 0xfeedface;
  static const _MH_CIGAM = 0xcefaedfe;
  static const _MH_MAGIC_64 = 0xfeedfacf;
  static const _MH_CIGAM_64 = 0xcffaedfe;

  static const _MH_DSYM = 0xa;

  static int? _wordSize(int magic) => (magic == _MH_MAGIC || magic == _MH_CIGAM)
      ? 4
      : (magic == _MH_MAGIC_64 || magic == _MH_CIGAM_64)
          ? 8
          : null;

  static Endian? _endian(int magic) =>
      (magic == _MH_MAGIC || magic == _MH_MAGIC_64)
          ? Endian.host
          : (magic == _MH_CIGAM || magic == _MH_CIGAM_64)
              ? (Endian.host == Endian.big ? Endian.little : Endian.big)
              : null;

  static MachOHeader? fromReader(Reader reader) {
    final start = reader.offset;
    // Initially assume host endianness.
    reader.endian = Endian.host;
    final magic = _readMachOUint32(reader);
    final wordSize = _wordSize(magic);
    final endian = _endian(magic);
    // Not an expected magic value, so not a supported Mach-O file.
    if (wordSize == null || endian == null) return null;
    reader.wordSize = wordSize;
    reader.endian = endian;
    final cputype = _readMachOUint32(reader);
    final cpusubtype = _readMachOUint32(reader);
    final filetype = _readMachOUint32(reader);
    final ncmds = _readMachOUint32(reader);
    final sizeofcmds = _readMachOUint32(reader);
    final flags = _readMachOUint32(reader);
    final reserved = reader.wordSize == 8 ? _readMachOUint32(reader) : null;
    final size = reader.offset - start;
    return MachOHeader._(magic, cputype, cpusubtype, filetype, ncmds,
        sizeofcmds, flags, reserved, size);
  }

  int get wordSize => _wordSize(magic)!;
  Endian get endian => _endian(magic)!;
  bool get isDSYM => filetype == _MH_DSYM;

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Magic: 0x')
      ..writeln(paddedHex(magic, 4));
    buffer
      ..write('Cpu Type: 0x')
      ..writeln(paddedHex(cputype, 4));
    buffer
      ..write('Cpu Subtype: 0x')
      ..writeln(paddedHex(cpusubtype, 4));
    buffer
      ..write('Filetype: 0x')
      ..writeln(paddedHex(filetype, 4));
    buffer
      ..write('Number of commands: ')
      ..writeln(ncmds);
    buffer
      ..write('Size of commands: ')
      ..writeln(sizeofcmds);
    buffer
      ..write('Flags: 0x')
      ..writeln(paddedHex(flags, 4));
    if (reserved != null) {
      buffer
        ..write('Reserved: 0x')
        ..writeln(paddedHex(reserved!, 4));
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class MachO extends DwarfContainer {
  final MachOHeader _header;
  final List<LoadCommand> _commands;
  final SymbolTable _symbolTable;
  final SegmentCommand _dwarfSegment;
  final StringTable? _debugStringTable;
  final StringTable? _debugLineStringTable;

  MachO._(this._header, this._commands, this._symbolTable, this._dwarfSegment,
      this._debugStringTable, this._debugLineStringTable);

  static MachO? fromReader(Reader machOReader) {
    // MachO files contain absolute offsets from the start of the file, so
    // make sure we have a reader that a) makes no assumptions about the
    // endianness or word size, since we'll read those in the header and b)
    // has an internal offset of 0 so absolute offsets can be used directly.
    final reader = machOReader.shrink(machOReader.offset);
    final header = MachOHeader.fromReader(reader);
    if (header == null) return null;

    final commandReader = reader.shrink(reader.offset, header.sizeofcmds);
    final commands =
        List.of(commandReader.readRepeated(LoadCommand.fromReader));
    assert(commands.length == header.ncmds);

    // This MachO file can't contain any debugging information.
    if (commands.isEmpty) return null;

    final symbolTable =
        commands.whereType<SymbolTableCommand>().single.load(reader);

    final dwarfSegment = commands
        .whereType<SegmentCommand?>()
        .firstWhere((sc) => sc!.segname == '__DWARF', orElse: () => null);
    if (dwarfSegment == null) {
      return null;
    }

    final debugStringTableSection = dwarfSegment.sections['__debug_str'];
    StringTable? debugStringTable;
    if (debugStringTableSection != null) {
      debugStringTable =
          StringTable.fromReader(debugStringTableSection.shrink(reader));
    }

    final debugLineStringTableSection =
        dwarfSegment.sections['__debug_line_str'];
    StringTable? debugLineStringTable;
    if (debugLineStringTableSection != null) {
      debugLineStringTable =
          StringTable.fromReader(debugLineStringTableSection.shrink(reader));
    }

    // Set the wordSize and endian of the original reader before returning.
    machOReader.wordSize = reader.wordSize;
    machOReader.endian = reader.endian;

    return MachO._(header, commands, symbolTable, dwarfSegment,
        debugStringTable, debugLineStringTable);
  }

  static String handleDSYM(String fileName) {
    if (!fileName.endsWith('.dSYM')) {
      return fileName;
    }
    final dwarfDir =
        Directory(path.join(fileName, 'Contents', 'Resources', 'DWARF'));
    // The DWARF directory inside the .dSYM should contain a single MachO file.
    final machoFile = dwarfDir.listSync().single as File;
    return machoFile.path;
  }

  static MachO? fromFile(String fileName) =>
      MachO.fromReader(Reader.fromFile(MachO.handleDSYM(fileName)));

  bool get isDSYM => _header.isDSYM;

  Reader applyWordSizeAndEndian(Reader reader) =>
      Reader.fromTypedData(reader.bdata,
          wordSize: _header.wordSize, endian: _header.endian);

  @override
  String? get architecture => CpuType.fromCode(_header.cputype)?.dartName;

  @override
  Reader abbreviationsTableReader(Reader containerReader) =>
      _dwarfSegment.sections['__debug_abbrev']!.shrink(containerReader);
  @override
  Reader lineNumberInfoReader(Reader containerReader) =>
      _dwarfSegment.sections['__debug_line']!.shrink(containerReader);
  @override
  Reader debugInfoReader(Reader containerReader) =>
      _dwarfSegment.sections['__debug_info']!.shrink(containerReader);

  @override
  int? get vmStartAddress => _symbolTable[constants.vmSymbolName]?.value;

  @override
  int? get isolateStartAddress =>
      _symbolTable[constants.isolateSymbolName]?.value;

  @override
  String? get buildId => null;

  @override
  DwarfContainerStringTable? get debugStringTable => _debugStringTable;

  @override
  DwarfContainerStringTable? get debugLineStringTable => _debugLineStringTable;

  @override
  Symbol? staticSymbolAt(int address) {
    Symbol? bestSym;
    for (final symbol in _symbolTable.values) {
      if (symbol.value > address) continue;
      // Pick the symbol with a value closest to the given address.
      if (bestSym == null || (bestSym.value < symbol.value)) {
        bestSym = symbol;
      }
    }
    return bestSym;
  }

  @override
  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..writeln('----------------------------------------')
      ..writeln('               Header')
      ..writeln('----------------------------------------')
      ..writeln('');
    _header.writeToStringBuffer(buffer);
    buffer
      ..writeln('')
      ..writeln('')
      ..writeln('----------------------------------------')
      ..writeln('            Load commands')
      ..writeln('----------------------------------------')
      ..writeln('');
    for (final command in _commands) {
      command.writeToStringBuffer(buffer);
      buffer.writeln('');
    }
  }
}

class UniversalBinaryArch {
  final int cputype;
  final int cpusubtype;
  final int offset;
  final int size;
  final int align;

  UniversalBinaryArch._(
      this.cputype, this.cpusubtype, this.offset, this.size, this.align);

  static UniversalBinaryArch fromReader(Reader reader) {
    final cputype = _readMachOUint32(reader);
    final cpusubtype = _readMachOUint32(reader);
    final offset = _readMachOUint32(reader);
    final size = _readMachOUint32(reader);
    final align = _readMachOUint32(reader);

    return UniversalBinaryArch._(cputype, cpusubtype, offset, size, align);
  }

  // Given a reader for the entire universal binary, returns a reader
  // for only this architecture's contents.
  Reader shrink(Reader reader) => reader.shrink(offset, size);

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('  Cpu Type: 0x')
      ..writeln(paddedHex(cputype, 4));
    buffer
      ..write('  Cpu Subtype: 0x')
      ..writeln(paddedHex(cpusubtype, 4));
    buffer
      ..write('  Offset: 0x')
      ..writeln(paddedHex(offset, 4));
    buffer
      ..write('  Size: ')
      ..writeln(size);
    buffer
      ..write('  Alignment: ')
      ..writeln(align);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

class UniversalBinaryHeader {
  final int magic;
  final List<UniversalBinaryArch> _arches;

  UniversalBinaryHeader._(this.magic, this._arches);

  static const _FAT_MAGIC = 0xcafebabe;
  static const _FAT_CIGAM = 0xbebafeca;

  static UniversalBinaryHeader? fromReader(Reader originalReader) {
    assert(originalReader.offset == 0);
    // Make sure we have a reader that makes no assumptions about the
    // endianness, since we'll read that in the header.
    final reader =
        Reader.fromTypedData(ByteData.sublistView(originalReader.bdata));
    reader.wordSize = 4;
    reader.endian = Endian.host;
    final magic = _readMachOUint32(reader);
    if (magic == _FAT_CIGAM) {
      reader.endian = Endian.host == Endian.big ? Endian.little : Endian.big;
    } else if (magic != _FAT_MAGIC) {
      // Not a universal binary.
      return null;
    }
    final archCount = _readMachOUint32(reader);
    final arches = <UniversalBinaryArch>[];
    for (int i = 0; i < archCount; i++) {
      arches.add(UniversalBinaryArch.fromReader(reader));
    }
    return UniversalBinaryHeader._(magic, arches);
  }

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('Magic: 0x')
      ..writeln(paddedHex(magic, 4));
    buffer
      ..write('Number of architectures: ')
      ..writeln(_arches.length);
    for (int i = 0; i < _arches.length; i++) {
      buffer
        ..write('Arch ')
        ..write(i)
        ..writeln(':');
      _arches[i].writeToStringBuffer(buffer);
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

/// Represents Dart architectures that have valid CPU type values in MachO.
enum CpuType {
  arm(_CPU_ARCH_ARM, "arm"),
  arm64(_CPU_ARCH_ARM | _CPU_ARCH_ABI64, "arm64"),
  i386(_CPU_ARCH_X86, "ia32"),
  x64(_CPU_ARCH_X86 | _CPU_ARCH_ABI64, "x64");

  static const _CPU_ARCH_ABI64 = 0x01000000;
  static const _CPU_ARCH_X86 = 7;
  static const _CPU_ARCH_ARM = 12;

  static const _prefix = 'CPU_ARCH';

  /// The 32-bit MachO encoding for this architecture.
  final int code;

  /// The name of this architecture as reported by Dart, e.g., in
  /// non-symbolic stack traces.
  final String dartName;

  const CpuType(this.code, this.dartName);

  static CpuType? fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }

  static CpuType? fromDartName(String arch) {
    for (final value in values) {
      if (value.dartName == arch) return value;
    }
    return null;
  }

  /// Whether this CpuType represents a 64-bit architecture.
  bool get is64Bit => code & _CPU_ARCH_ABI64 != 0;

  @override
  String toString() => '${_prefix}_${name.toUpperCase()}';
}

class UniversalBinary {
  final UniversalBinaryHeader _header;
  final Map<CpuType, UniversalBinaryArch> _arches;
  final Map<UniversalBinaryArch, MachO> _contents;

  UniversalBinary._(this._header, this._arches, this._contents);

  static UniversalBinary? fromReader(Reader originalReader) {
    // Universal binary files contain absolute offsets from the start of the
    // file, so make sure we have a reader that has an internal offset of 0 so
    // absolute offsets can be used directly.
    final reader = originalReader.shrink(originalReader.offset);
    final header = UniversalBinaryHeader.fromReader(reader);
    if (header == null) {
      return null;
    }
    final arches = <CpuType, UniversalBinaryArch>{};
    final contents = <UniversalBinaryArch, MachO>{};
    for (final arch in header._arches) {
      final cpuType = CpuType.fromCode(arch.cputype);
      if (cpuType == null) continue;
      final archReader = arch.shrink(reader);
      final macho = MachO.fromReader(archReader);
      // The MachO parser either failed (likely due to a lack of debugging
      // information) or this contains debugging information for something other
      // than a Dart snapshot (since it contains neither a VM or isolate
      // instruction section symbol).
      if ((macho == null) ||
          ((macho.vmStartAddress == null) &&
              (macho.isolateStartAddress == null))) {
        continue;
      }
      if (macho.isDSYM) {
        // Always take a dSYM section above a non-dSYM section. If there are
        // multiple dSYM sections for some reason, the last one read is fine.
        arches[cpuType] = arch;
      } else if (!arches.containsKey(cpuType)) {
        arches[cpuType] = arch;
      }
      contents[arch] = macho;
    }
    return UniversalBinary._(header, arches, contents);
  }

  static UniversalBinary? fromFile(String fileName) =>
      UniversalBinary.fromReader(Reader.fromFile(MachO.handleDSYM(fileName)));

  Iterable<CpuType> get architectures => _arches.keys;

  Reader? readerForCpuType(Reader originalReader, CpuType cpuType) {
    final arch = _arches[cpuType];
    if (arch == null) return null;
    final macho = _contents[arch]!;
    // Universal binary files contain absolute offsets from the start of the
    // file, so make sure to feed arch.shrink a reader that has an internal
    // offset of 0.
    return macho.applyWordSizeAndEndian(
        arch.shrink(originalReader.shrink(originalReader.offset)));
  }

  DwarfContainer? containerForCpuType(CpuType cpuType) {
    final arch = _arches[cpuType];
    if (arch == null) return null;
    return _contents[arch];
  }

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..writeln('----------------------------------------')
      ..writeln('       Universal Binary Header')
      ..writeln('----------------------------------------')
      ..writeln('');
    _header.writeToStringBuffer(buffer);
    for (final cpuType in _arches.keys) {
      buffer
        ..writeln('')
        ..writeln('')
        ..writeln('----------------------------------------------------------')
        ..writeln('    DWARF-containing Mach-O Contents for $cpuType')
        ..writeln('----------------------------------------------------------')
        ..writeln('');
      _contents[_arches[cpuType]!]!.writeToStringBuffer(buffer);
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

const _magicByteOffset = 0;
const _cpuTypeByteOffset = 4;
const _fileTypeByteOffset = 12;

/// Used by certain Dart tests to create a MachO file that only contains a
/// header for the given architecture.
Uint8List? emptyMachOForArchitecture(String dartName) {
  final cpuType = CpuType.fromDartName(dartName);
  if (cpuType == null) return null;
  // 4 bytes * 7 fields + 4 padding bytes on 64-bit architectures.
  final contents = Uint8List(32);
  // We'll leave most of the fields at 0.
  final byteData = ByteData.sublistView(contents);
  // Use the host endian magic number marker corresponding to the bit size.
  byteData.setUint32(
      _magicByteOffset,
      cpuType.is64Bit ? MachOHeader._MH_MAGIC_64 : MachOHeader._MH_MAGIC,
      Endian.host);
  byteData.setUint32(_cpuTypeByteOffset, cpuType.code, Endian.host);
  // Just to set it to a valid file type, even though there are no contents.
  byteData.setUint32(_fileTypeByteOffset, MachOHeader._MH_DSYM, Endian.host);
  return contents;
}
