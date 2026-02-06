// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:cfg/utils/misc.dart';
import 'package:crypto/crypto.dart';
import 'package:native_compiler/configuration.dart';
import 'package:native_compiler/runtime/vm_defs.dart';
import 'package:native_compiler/snapshot/image_writer.dart';

/// Collection of Mach-O file format constants.
class MachO {
  static const int MH_MAGIC_64 = 0xfeedfacf;

  // CPU with a 64-bit ABI.
  static const int CPU_ARCH_ABI64 = 0x01000000;

  // ARM-family CPUs.
  static const int CPU_TYPE_ARM = 12;
  static const int CPU_TYPE_ARM64 = CPU_TYPE_ARM | CPU_ARCH_ABI64;

  // ARM-family CPU subtypes.
  static const int CPU_SUBTYPE_ARM_ALL = 0;
  static const int CPU_SUBTYPE_ARM64_ALL = CPU_SUBTYPE_ARM_ALL;

  // Filetypes for the Mach-O header.

  // A dynamically bound shared library.
  static const int MH_DYLIB = 0x6;

  // Flag values for the Mach-O header.

  // The object file has no undefined references.
  static const int MH_NOUNDEFS = 0x1;
  // The object file is an appropriate input for the dynamic linker
  // and cannot be statically link edited again.
  static const int MH_DYLDLINK = 0x4;
  // The object file does not re-export any of its input dynamic
  // libraries.
  static const int MH_NO_REEXPORTED_DYLIBS = 0x100000;

  // Load commands

  // The static symbol table.
  static const int LC_SYMTAB = 0x2;
  // The dynamic symbol table.
  static const int LC_DYSYMTAB = 0xb;
  // A dynamic library that must be loaded to use this object file.
  static const int LC_LOAD_DYLIB = 0xc;
  // The identifier for this dynamic library (for MH_DYLIB files).
  static const int LC_ID_DYLIB = 0xd;
  // A 64-bit segment.
  static const int LC_SEGMENT_64 = 0x19;
  // The UUID, used as a build identifier.
  static const int LC_UUID = 0x1b;
  // The code signature which protects the preceding portion of the object file.
  // Must be the last contents in the object file.
  static const int LC_CODE_SIGNATURE = 0x1d;
  static const int LC_ENCRYPTION_INFO_64 = 0x2c;
  // The target platform and minimum and target OS versions for this object file.
  static const int LC_BUILD_VERSION = 0x32;

  static const String systemDylibName = "/usr/lib/libSystem.B.dylib";
  static const Version systemCurrentVersion = Version(1351, 0, 0);
  static const Version systemCompatVersion = Version(1, 0, 0);

  static const int VM_PROT_NONE = 0x00;
  static const int VM_PROT_READ = 0x01;
  static const int VM_PROT_WRITE = 0x02;
  static const int VM_PROT_EXECUTE = 0x04;

  // Section types.

  static const int S_REGULAR = 0x0;
  static const int S_ZEROFILL = 0x1;

  // Section attributes. Note that these values do not need shifting when
  // combining with a type and so the type bits are always 0.

  static const int S_NO_ATTRIBUTES = 0;
  // The section only contains instructions.
  static const int S_ATTR_PURE_INSTRUCTIONS = 0x80000000;
  // The section contains some instructions. Should be set if
  // S_ATTR_PURE_INSTRUCTIONS is also set.
  static const int S_ATTR_SOME_INSTRUCTIONS = 0x00000400;

  // Special segment and section names used by Mach-O files.
  static const String SEG_TEXT = "__TEXT";
  static const String SECT_TEXT = "__text";
  static const String SECT_CONST = "__const";

  // Segment name for the linkedit segment. Does not contain sections but rather
  // the non-header contents for other non-segment link commands like the symbol
  // table and code signature.
  static const String SEG_LINKEDIT = "__LINKEDIT";

  // The external symbol bit.
  static const int N_EXT = 0x1;

  // A symbol defined in a specific section (load command index in n_sect).
  static const int N_SECT = 0xe;

  // Magic numbers for code signature blobs.
  static const int CSMAGIC_CODEDIRECTORY = 0xfade0c02;
  static const int CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0;

  // Types for code signature blobs.
  static const int CSSLOT_CODEDIRECTORY = 0;

  // Code signature code directory flags.
  static const int CS_ADHOC = 0x00000002;
  static const int CS_LINKER_SIGNED = 0x00020000;

  // Code signature hash types.
  static const int CS_HASHTYPE_SHA256 = 0x2;

  // Code signature version numbers.

  // The earliest version that can appear in a code signature.
  static const int CS_SUPPORTSNONE = 0x20001;
  static const int CS_SUPPORTSSCATTER = 0x20100;
  static const int CS_SUPPORTSTEAMID = 0x20200;
  static const int CS_SUPPORTSCODELIMIT64 = 0x20300;
  static const int CS_SUPPORTSEXECSEG = 0x20400;
}

extension type Version._(int value) {
  const Version(int major, int minor, int patch)
    : value = (major << 16) | (minor << 8) | patch;
}

const noVersion = Version(0, 0, 0);

final class MachoImageWriter extends ImageWriter {
  static const declareSymbols = const bool.fromEnvironment(
    'declare.symbols',
    defaultValue: true,
  );

  final TargetCPU targetCPU;
  final String libraryName;

  late final int commandAlignment = switch (targetCPU) {
    .arm64 => 8,
  };

  late final int pageSize = switch (targetCPU) {
    .arm64 => 16 * 1024,
  };

  late final Header header;
  late final Segment textSegment;
  late final Section textSection;
  late final Section constSection;

  late final SymbolTable symbolTable = SymbolTable(this);
  late final StringTable stringTable = StringTable(this);
  late final CodeSignature codeSignature = CodeSignature(this);

  MachoImageWriter(this.targetCPU, this.libraryName) {
    header = Header(this);
    symbolTable.addSymbol(isolateSnapshotInstructionsAsmSymbol, textSection, 0);
    symbolTable.addSymbol(isolateSnapshotDataAsmSymbol, constSection, 0);
  }

  @override
  int addInstructions(String symbol, Uint8List instructions) {
    final offset = textSection.unalignedSize;
    textSection.addContents(instructions);
    if (declareSymbols) {
      symbolTable.addSymbol(symbol, textSection, offset);
    }
    return offset;
  }

  @override
  int addReadOnlyData(List<Uint8List> data, int length) {
    final offset = constSection.unalignedSize;
    for (final bytes in data) {
      constSection.addContents(bytes);
    }
    return offset;
  }

  void calculateOffsets() {
    var vmAddr = 0;
    var fileOffset = 0;
    for (final seg in header.segments) {
      seg.vmAddr = vmAddr;
      seg.fileOffset = fileOffset;

      if (vmAddr == 0) {
        // Reserve space for header.
        vmAddr += header.size;
        fileOffset += header.size;
      }

      for (final section in seg.sections) {
        section.vmAddr = roundUp(vmAddr, section.align);
        section.fileOffset = roundUp(fileOffset, section.align);

        vmAddr = section.vmAddr + section.unalignedSize;
        fileOffset = section.fileOffset + section.unalignedSize;
      }

      if (seg.name == MachO.SEG_LINKEDIT) {
        symbolTable.fileOffset = fileOffset;
        vmAddr += symbolTable.unalignedSize;
        fileOffset += symbolTable.unalignedSize;

        stringTable.fileOffset = fileOffset;
        vmAddr += stringTable.unalignedSize;
        fileOffset += stringTable.unalignedSize;

        fileOffset = roundUp(fileOffset, CodeSignature.alignment);
        vmAddr = roundUp(vmAddr, CodeSignature.alignment);

        codeSignature.fileOffset = fileOffset;
        vmAddr += codeSignature.size;
        fileOffset += codeSignature.size;
        // Do not pad contents of __LINKEDIT segment as
        // it needs to be at the end of the Mach-O file.
      } else {
        fileOffset = roundUp(fileOffset, pageSize);
      }

      vmAddr = roundUp(vmAddr, pageSize);
      seg.vmSize = vmAddr - seg.vmAddr;
      seg.fileSize = fileOffset - seg.fileOffset;
    }
  }

  void writeTo(Sink<List<int>> out) {
    calculateOffsets();

    final stream = BufferedStream(out, codeSignature.hashesSize);

    for (final seg in header.segments) {
      assert(stream.position == seg.fileOffset);

      if (seg.vmAddr == 0) {
        header.write(stream);
      }

      for (final section in seg.sections) {
        stream.writeZeros(section.fileOffset - stream.position);
        section.writeContents(stream);
      }

      if (seg.name == MachO.SEG_LINKEDIT) {
        symbolTable.writeContents(stream);
        stringTable.writeContents(stream);
        stream.writeZeros(codeSignature.fileOffset - stream.position);
        codeSignature.writeContents(stream);
        assert(stream.position == seg.fileOffset + seg.fileSize);
      } else {
        stream.writeZeros(seg.fileOffset + seg.fileSize - stream.position);
      }
    }

    stream.flush();
  }
}

extension on String {
  /// Length of the string encoded as UTF-8 and including terminating zero.
  int get zstringLength => utf8.encode(this).length + 1;
}

class Header {
  final MachoImageWriter writer;
  final List<LoadCommand> loadCommands = [];

  Header(this.writer) {
    writer.textSection = Section(
      writer,
      MachO.SECT_TEXT,
      MachO.SEG_TEXT,
      writer.pageSize,
      MachO.S_REGULAR |
          MachO.S_ATTR_PURE_INSTRUCTIONS |
          MachO.S_ATTR_SOME_INSTRUCTIONS,
    );
    writer.constSection = Section(
      writer,
      MachO.SECT_CONST,
      MachO.SEG_TEXT,
      writer.pageSize,
      MachO.S_REGULAR | MachO.S_NO_ATTRIBUTES,
    );
    writer.textSegment =
        Segment(
            writer,
            MachO.SEG_TEXT,
            MachO.VM_PROT_READ | MachO.VM_PROT_EXECUTE,
            MachO.VM_PROT_READ | MachO.VM_PROT_EXECUTE,
          )
          ..sections.add(writer.textSection)
          ..sections.add(writer.constSection);

    loadCommands.add(writer.textSegment);

    loadCommands.add(
      Segment(
        writer,
        MachO.SEG_LINKEDIT,
        MachO.VM_PROT_READ,
        MachO.VM_PROT_READ,
      ),
    );

    loadCommands.add(
      DylibCommand(writer, MachO.LC_ID_DYLIB, writer.libraryName),
    );

    loadCommands.add(
      DylibCommand(
        writer,
        MachO.LC_LOAD_DYLIB,
        MachO.systemDylibName,
        MachO.systemCurrentVersion,
        MachO.systemCompatVersion,
      ),
    );

    loadCommands.add(SymtabCommand(writer));
    loadCommands.add(DysymtabCommand(writer));
    loadCommands.add(EncryptionInfoCommand(writer));
    loadCommands.add(CodeSignatureCommand(writer));

    // TODO: LC_UUID, LC_BUILD_VERSION
  }

  late final List<Segment> segments = loadCommands
      .whereType<Segment>()
      .toList();

  late final List<Section> sections = [
    for (final seg in segments) ...seg.sections,
  ];

  // Size of the header without load commands.
  static const int headerSize = 8 * 4;

  // Total size of the load commands.
  late final int sizeOfCommands = loadCommands.fold(
    0,
    (int size, LoadCommand cmd) => size + cmd.size,
  );

  late final int unalignedSize = headerSize + sizeOfCommands;

  late final int size = roundUp(unalignedSize, writer.pageSize);

  void write(BufferedStream stream) {
    assert(stream.position == 0);
    // struct mach_header_64 {
    //   uint32_t magic;
    //   uint32_t cputype;
    //   uint32_t cpusubtype;
    //   uint32_t filetype;
    //   uint32_t ncmds;
    //   uint32_t sizeofcmds;
    //   uint32_t flags;
    //   uint32_t reserved;
    // };
    stream.writeUint32(MachO.MH_MAGIC_64);
    switch (writer.targetCPU) {
      case .arm64:
        stream.writeUint32(MachO.CPU_TYPE_ARM64);
        stream.writeUint32(MachO.CPU_SUBTYPE_ARM64_ALL);
    }
    stream.writeUint32(MachO.MH_DYLIB);
    stream.writeUint32(loadCommands.length);
    stream.writeUint32(sizeOfCommands);
    stream.writeUint32(
      MachO.MH_NOUNDEFS | MachO.MH_DYLDLINK | MachO.MH_NO_REEXPORTED_DYLIBS,
    );
    stream.writeUint32(0);

    assert(stream.position == headerSize);
    for (final cmd in loadCommands) {
      cmd.write(stream);
    }
    assert(stream.position == unalignedSize);
    stream.writeZeros(size - unalignedSize);
    assert(stream.position == size);
  }
}

abstract base class LoadCommand {
  final MachoImageWriter writer;
  final int cmd;

  LoadCommand(this.writer, this.cmd);

  int get unalignedSize;

  late final int size = roundUp(unalignedSize, writer.commandAlignment);

  void write(BufferedStream stream);

  int startWritingCommand(BufferedStream stream) {
    final start = stream.position;
    stream.writeUint32(cmd);
    stream.writeUint32(size);
    return start;
  }

  void endWritingCommand(BufferedStream stream, int start) {
    assert(stream.position == start + unalignedSize);
    stream.writeZeros(size - unalignedSize);
    assert(stream.position == start + size);
  }
}

final class Segment extends LoadCommand {
  final String name;
  final int initProtection;
  final int maxProtection;
  final List<Section> sections = [];

  late final int vmAddr;
  late final int vmSize;
  late final int fileOffset;
  late final int fileSize;

  Segment(
    MachoImageWriter writer,
    this.name,
    this.initProtection,
    this.maxProtection,
  ) : super(writer, MachO.LC_SEGMENT_64);

  @override
  late final int unalignedSize =
      2 * 4 + 16 + 4 * 8 + 4 * 4 + Section.headerSize * sections.length;

  @override
  void write(BufferedStream stream) {
    final start = startWritingCommand(stream);
    // struct segment_command_64 {
    //   uint32_t cmd;
    //   uint32_t cmdsize;
    //   char segname[16];
    //   uint64_t vmaddr;
    //   uint64_t vmsize;
    //   uint64_t fileoff;
    //   uint64_t filesize;
    //   uint32_t maxprot;
    //   uint32_t initprot;
    //   uint32_t nsects;
    //   uint32_t flags;
    // };
    stream.writeZStringAsNChars(name, 16);
    stream.writeUint64(vmAddr);
    stream.writeUint64(vmSize);
    stream.writeUint64(fileOffset);
    stream.writeUint64(fileSize);
    stream.writeUint32(maxProtection);
    stream.writeUint32(initProtection);
    stream.writeUint32(sections.length);
    stream.writeUint32(0);
    for (final section in sections) {
      section.write(stream);
    }
    endWritingCommand(stream, start);
  }
}

class Section {
  final MachoImageWriter writer;
  final String name;
  final String segmentName;
  final int align;
  final int flags;
  int unalignedSize = 0;

  late final int vmAddr;
  late final int fileOffset;

  final List<Uint8List> contents = [];

  Section(this.writer, this.name, this.segmentName, this.align, this.flags);

  static const int headerSize = 16 + 16 + 2 * 8 + 8 * 4;

  late final int index = 1 + writer.header.sections.indexOf(this);

  /// Add [bytes] to the contents of this section and return their offset.
  int addContents(Uint8List bytes) {
    final offset = unalignedSize;
    contents.add(bytes);
    unalignedSize += bytes.length;
    return offset;
  }

  void write(BufferedStream stream) {
    // struct section_64 {
    //   char sectname[16];
    //   char segname[16];
    //   uint64_t addr;
    //   uint64_t size;
    //   uint32_t offset;
    //   uint32_t align;
    //   uint32_t reloff;
    //   uint32_t nreloc;
    //   uint32_t flags;
    //   uint32_t reserved1;
    //   uint32_t reserved2;
    //   uint32_t reserved3;
    // };
    stream.writeZStringAsNChars(name, 16);
    stream.writeZStringAsNChars(segmentName, 16);
    stream.writeUint64(vmAddr);
    stream.writeUint64(unalignedSize);
    stream.writeUint32(fileOffset);
    stream.writeUint32(log2OfPowerOf2(align));
    stream.writeUint32(0);
    stream.writeUint32(0);
    stream.writeUint32(flags);
    stream.writeUint32(0);
    stream.writeUint32(0);
    stream.writeUint32(0);
  }

  void writeContents(BufferedStream stream) {
    assert(stream.position == fileOffset);
    for (final bytes in contents) {
      stream.writeBytes(bytes);
    }
    assert(stream.position == fileOffset + unalignedSize);
  }
}

final class DylibCommand extends LoadCommand {
  final String name;
  final Version currentVersion;
  final Version compatibilityVersion;

  DylibCommand(
    super.writer,
    super.cmd,
    this.name, [
    this.currentVersion = noVersion,
    this.compatibilityVersion = noVersion,
  ]);

  @override
  late final int unalignedSize = (2 + 4) * 4 + name.zstringLength;

  @override
  void write(BufferedStream stream) {
    final start = startWritingCommand(stream);
    // struct dylib_command {
    //   uint32_t cmd;
    //   uint32_t cmdsize;
    //   struct dylib dylib;
    // };
    // struct dylib {
    //   uint32_t name;
    //   uint32_t timestamp;
    //   uint32_t current_version;
    //   uint32_t compatibility_version;
    // };
    const int nameOffset = (2 + 4) * 4;
    stream.writeUint32(nameOffset);
    stream.writeUint32(0);
    stream.writeUint32(currentVersion.value);
    stream.writeUint32(compatibilityVersion.value);
    assert(stream.position == start + nameOffset);
    stream.writeZString(name);
    endWritingCommand(stream, start);
  }
}

final class SymtabCommand extends LoadCommand {
  SymtabCommand(MachoImageWriter writer) : super(writer, MachO.LC_SYMTAB);

  @override
  late final int unalignedSize = (2 + 4) * 4;

  @override
  void write(BufferedStream stream) {
    final start = startWritingCommand(stream);
    // struct symtab_command {
    //   uint32_t cmd;
    //   uint32_t cmdsize;
    //   uint32_t symoff;
    //   uint32_t nsyms;
    //   uint32_t stroff;
    //   uint32_t strsize;
    // };
    stream.writeUint32(writer.symbolTable.fileOffset);
    stream.writeUint32(writer.symbolTable.symbols.length);
    stream.writeUint32(writer.stringTable.fileOffset);
    stream.writeUint32(writer.stringTable.unalignedSize);
    endWritingCommand(stream, start);
  }
}

final class DysymtabCommand extends LoadCommand {
  DysymtabCommand(MachoImageWriter writer) : super(writer, MachO.LC_DYSYMTAB);

  @override
  late final int unalignedSize = (2 + 18) * 4;

  @override
  void write(BufferedStream stream) {
    final start = startWritingCommand(stream);
    // struct dysymtab_command {
    //   uint32_t cmd;
    //   uint32_t cmdsize;
    //   uint32_t ilocalsym;
    //   uint32_t nlocalsym;
    //   uint32_t iextdefsym;
    //   uint32_t nextdefsym;
    //   uint32_t iundefsym;
    //   uint32_t nundefsym;
    //   uint32_t tocoff;
    //   uint32_t ntoc;
    //   uint32_t modtaboff;
    //   uint32_t nmodtab;
    //   uint32_t extrefsymoff;
    //   uint32_t nextrefsyms;
    //   uint32_t indirectsymoff;
    //   uint32_t nindirectsyms;
    //   uint32_t extreloff;
    //   uint32_t nextrel;
    //   uint32_t locreloff;
    //   uint32_t nlocrel;
    // };
    stream.writeUint32(0);
    stream.writeUint32(0);
    final nExtDefSym = writer.symbolTable.symbols.length;
    stream.writeUint32(0);
    stream.writeUint32(nExtDefSym);
    stream.writeUint32(nExtDefSym);
    stream.writeUint32(0);
    for (var i = 0; i < 12; ++i) {
      stream.writeUint32(0);
    }
    endWritingCommand(stream, start);
  }
}

class SymbolTable {
  final MachoImageWriter writer;
  final List<Symbol> symbols = [];
  int fileOffset = 0;

  SymbolTable(this.writer);

  int get unalignedSize => Symbol.size * symbols.length;

  void addSymbol(String name, Section section, int offset) {
    symbols.add(
      Symbol(
        writer.stringTable.findOrAdd(name),
        MachO.N_SECT | MachO.N_EXT,
        section,
        offset,
      ),
    );
  }

  void writeContents(BufferedStream stream) {
    assert(stream.position == fileOffset);
    for (final sym in symbols) {
      sym.write(stream);
    }
    assert(stream.position == fileOffset + unalignedSize);
  }
}

class Symbol {
  final int nameIndex;
  final int type;
  final Section section;
  final int offset;

  Symbol(this.nameIndex, this.type, this.section, this.offset);

  static const int size = 4 + 1 + 1 + 2 + 8;

  void write(BufferedStream stream) {
    // struct nlist_64 {
    //   uint32_t n_strx;
    //   uint8_t n_type;
    //   uint8_t n_sect;
    //   uint16_t n_desc;
    //   uint64_t n_value;
    // };
    stream.writeUint32(nameIndex);
    stream.writeUint8(type);
    stream.writeUint8(section.index);
    stream.writeUint16(0);
    stream.writeUint64(section.vmAddr + offset);
  }
}

class StringTable {
  final MachoImageWriter writer;
  int fileOffset = 0;
  int unalignedSize = 0;
  final Map<String, int> strings = {};
  Uint8List _chars = Uint8List(256);

  StringTable(this.writer) {
    // Ensure the string containing a single space is always at index 0.
    final index = findOrAdd(" ");
    assert(index == 0);
    // Assign the empty string the index of the null byte in the
    // string added above.
    strings[""] = index + 1;
  }

  int findOrAdd(String str) => strings[str] ??= _add(str);

  @pragma('vm:never-inline')
  void _grow(int requiredSize) {
    int newCapacity = _chars.length << 1;
    while (newCapacity < requiredSize) {
      newCapacity = newCapacity << 1;
    }
    final old = _chars;
    _chars = Uint8List(newCapacity);
    _chars.setRange(0, unalignedSize, old);
  }

  int _add(String str) {
    final offset = unalignedSize;
    final chars = utf8.encode(str);
    final len = chars.length + 1;
    if (unalignedSize + len > _chars.length) {
      _grow(unalignedSize + len);
    }
    _chars.setRange(offset, offset + chars.length, chars);
    _chars[offset + chars.length] = 0;
    unalignedSize += len;
    return offset;
  }

  void writeContents(BufferedStream stream) {
    assert(stream.position == fileOffset);
    stream.writeBytes(Uint8List.sublistView(_chars, 0, unalignedSize));
  }
}

final class EncryptionInfoCommand extends LoadCommand {
  EncryptionInfoCommand(MachoImageWriter writer)
    : super(writer, MachO.LC_ENCRYPTION_INFO_64);

  @override
  late final int unalignedSize = (2 + 4) * 4;

  @override
  void write(BufferedStream stream) {
    final start = startWritingCommand(stream);
    // struct encryption_info_command_64 {
    //   uint32_t cmd;
    //   uint32_t cmdsize;
    //   uint32_t cryptoff;
    //   uint32_t cryptsize;
    //   uint32_t cryptid;
    //   uint32_t pad;
    // };
    stream.writeUint32(writer.textSection.fileOffset);
    stream.writeUint32(
      writer.textSegment.fileOffset +
          writer.textSegment.fileSize -
          writer.textSection.fileOffset,
    );
    stream.writeUint32(0);
    stream.writeUint32(0);
    endWritingCommand(stream, start);
  }
}

final class CodeSignatureCommand extends LoadCommand {
  CodeSignatureCommand(MachoImageWriter writer)
    : super(writer, MachO.LC_CODE_SIGNATURE);

  @override
  late final int unalignedSize = (2 + 2) * 4;

  @override
  void write(BufferedStream stream) {
    final start = startWritingCommand(stream);
    // struct linkedit_data_command {
    //   uint32_t cmd;
    //   uint32_t cmdsize;
    //   uint32_t dataoff;
    //   uint32_t datasize;
    // };
    stream.writeUint32(writer.codeSignature.fileOffset);
    stream.writeUint32(writer.codeSignature.size);
    endWritingCommand(stream, start);
  }
}

class CodeSignature {
  /// Alignment of code signature.
  static const int alignment = 16;

  /// Size of the block to hash for Mach-O code signature.
  static const int blockSize = 4 * 1024;

  /// Size of one hash.
  static const int hashSize = 256 ~/ 8;

  /// Alignment of hashes.
  static const int hashAlignment = 16;

  final MachoImageWriter writer;

  CodeSignature(this.writer);

  // Should be set before number of hashes and size is calculated.
  late final int fileOffset;

  int get numHashes => (fileOffset + blockSize - 1) ~/ blockSize;
  int get hashesSize => numHashes * hashSize;

  static const int blobHeaderPadding = 4; // Padding to align directory by 8.
  static const int blobHeadersSize = (3 + 2) * 4 + blobHeaderPadding;
  static const int directoryHeaderSize = 9 * 4 + 4 * 1 + 4 * 4 + 4 * 8;
  late final int identifierSize = writer.libraryName.zstringLength;
  late final int size =
      roundUp(
        blobHeadersSize + directoryHeaderSize + identifierSize,
        hashAlignment,
      ) +
      hashesSize;

  void writeContents(BufferedStream stream) {
    assert(stream.position == fileOffset);
    stream.finalizeHashing();
    // struct CS_SuperBlob {
    //   uint32_t magic;  /* magic number */
    //   uint32_t length; /* total length of SuperBlob */
    //   uint32_t count;  /* number of index entries following */
    // };
    // struct CS_BlobIndex {
    //   uint32_t type;   /* type of entry */
    //   uint32_t offset; /* offset of entry */
    // };
    stream.writeUint32BE(MachO.CSMAGIC_EMBEDDED_SIGNATURE);
    stream.writeUint32BE(size);
    stream.writeUint32BE(1);
    stream.writeUint32BE(MachO.CSSLOT_CODEDIRECTORY);
    stream.writeUint32BE(blobHeadersSize);
    stream.writeZeros(blobHeaderPadding);
    assert(stream.position == fileOffset + blobHeadersSize);
    // struct CS_CodeDirectory {
    //   uint32_t magic;         /* magic number (CSMAGIC_CODEDIRECTORY) */
    //   uint32_t length;        /* total length of CodeDirectory blob */
    //   uint32_t version;       /* compatibility version */
    //   uint32_t flags;         /* setup and mode flags */
    //   uint32_t hashOffset;    /* offset of hash slot element at index zero */
    //   uint32_t identOffset;   /* offset of identifier string */
    //   uint32_t nSpecialSlots; /* number of special hash slots */
    //   uint32_t nCodeSlots;    /* number of ordinary (code) hash slots */
    //   uint32_t codeLimit;     /* limit to main image signature range */
    //   uint8_t hashSize;       /* size of each hash in bytes */
    //   uint8_t hashType;       /* type of hash (cdHashType* constants) */
    //   uint8_t platform;       /* platform identifier; zero if not platform binary */
    //   uint8_t pageSize;       /* log2(page size in bytes); 0 => infinite */
    //   uint32_t spare2;        /* unused (must be zero) */
    //   /* Version 0x20100 */
    //   uint32_t scatterOffset; /* offset of optional scatter vector */
    //   /* Version 0x20200 */
    //   uint32_t teamOffset;    /* offset of optional team identifier */
    //   /* Version 0x20300 */
    //   uint32_t spare3;        /* unused (must be zero) */
    //   uint64_t codeLimit64;   /* limit to main image signature range, 64 bits */
    //   /* Version 0x20400 */
    //   uint64_t execSegBase;   /* offset of executable segment */
    //   uint64_t execSegLimit;  /* limit of executable segment */
    //   uint64_t execSegFlags;  /* executable segment flags */
    // };
    stream.writeUint32BE(MachO.CSMAGIC_CODEDIRECTORY);
    final directorySize = size - blobHeadersSize;
    stream.writeUint32BE(directorySize);
    stream.writeUint32BE(MachO.CS_SUPPORTSEXECSEG);
    stream.writeUint32BE(MachO.CS_ADHOC | MachO.CS_LINKER_SIGNED);
    final hashesOffset = directorySize - hashesSize;
    stream.writeUint32BE(hashesOffset);
    stream.writeUint32BE(directoryHeaderSize);
    stream.writeUint32BE(0);
    stream.writeUint32BE(numHashes);
    stream.writeUint32BE(fileOffset);
    stream.writeUint8(hashSize);
    stream.writeUint8(MachO.CS_HASHTYPE_SHA256);
    stream.writeUint8(0);
    stream.writeUint8(log2OfPowerOf2(blockSize));
    stream.writeUint32BE(0);
    stream.writeUint32BE(0);
    stream.writeUint32BE(0);
    stream.writeUint32BE(0);
    stream.writeUint64BE(0);
    stream.writeUint64BE(writer.textSegment.fileOffset);
    stream.writeUint64BE(writer.textSegment.fileSize);
    stream.writeUint64BE(0);
    assert(
      stream.position == fileOffset + blobHeadersSize + directoryHeaderSize,
    );
    stream.writeZString(writer.libraryName);
    stream.writeZeros(fileOffset + size - hashesSize - stream.position);
    assert(stream.position == fileOffset + blobHeadersSize + hashesOffset);
    stream.writeBytes(stream.hashes);
    assert(stream.position == fileOffset + size);
  }
}

/// Buffers image writing and calculation of hashes for code signature.
class BufferedStream {
  // All our targets are little-endian.
  static const Endian endianness = Endian.little;

  /// Size of the buffer, in bytes.
  static const int bufferSize = 256 * 1024;

  /// Size of the block for hashing.
  static const int blockSize = CodeSignature.blockSize;

  // Max number of bytes to put into buffer instead of writing directly.
  static const int maxSizeToBuffer = bufferSize - blockSize;

  final Sink<List<int>> _out;
  Uint8List _buffer;
  ByteData _bufferData;
  int _position = 0;
  int _flushed = 0;
  bool _isHashing = true;
  final Uint8List _hashes;
  int _hashesPosition = 0;

  BufferedStream(Sink<List<int>> out, int hashesSize)
    : this._(out, Uint8List(bufferSize), Uint8List(hashesSize));

  BufferedStream._(this._out, this._buffer, this._hashes)
    : _bufferData = _buffer.buffer.asByteData();

  int get position => _flushed + _position;

  Uint8List get hashes {
    assert(!_isHashing);
    return _hashes;
  }

  @pragma('vm:prefer-inline')
  void _ensureCapacity(int length) {
    assert(0 <= length && length <= maxSizeToBuffer);
    if (length > bufferSize - _position) {
      flush();
      assert(length <= bufferSize - _position);
    }
  }

  @pragma('vm:never-inline')
  void flush() {
    if (_position == 0) {
      return;
    }
    int sizeToFlush = _position;
    if (_isHashing) {
      sizeToFlush = roundDown(_position, blockSize);
      for (var pos = 0; pos < sizeToFlush; pos += blockSize) {
        _addHash(_buffer, pos, blockSize);
      }
    }
    _out.add(Uint8List.sublistView(_buffer, 0, sizeToFlush));
    _flushed += sizeToFlush;
    _position -= sizeToFlush;
    // Create a new buffer to avoid modifying the old one
    // as IOSink.add consumes data asynchronously.
    final old = _buffer;
    _buffer = Uint8List(bufferSize);
    _bufferData = _buffer.buffer.asByteData();
    if (_position != 0) {
      // Copy the remaining bytes from old buffer.
      assert(_isHashing);
      _buffer.setRange(0, _position, old, sizeToFlush);
    }
  }

  void _addHash(Uint8List buffer, int position, int length) {
    assert(_isHashing);
    final hash = sha256
        .convert(Uint8List.sublistView(buffer, position, position + length))
        .bytes;
    assert(hash.length == CodeSignature.hashSize);
    _hashes.setRange(_hashesPosition, _hashesPosition + hash.length, hash);
    _hashesPosition += hash.length;
  }

  void finalizeHashing() {
    assert(_isHashing);
    flush();
    if (_position > 0) {
      assert(_position < blockSize);
      _addHash(_buffer, 0, _position);
    }
    assert(_hashesPosition == _hashes.length);
    _isHashing = false;
  }

  void writeUint8(int value) {
    assert((value & 0xff) == value);
    _ensureCapacity(1);
    _buffer[_position] = value;
    _position += 1;
  }

  void writeUint16(int value) {
    assert((value & 0xffff) == value);
    _ensureCapacity(2);
    _bufferData.setUint16(_position, value, endianness);
    _position += 2;
  }

  void writeUint32(int value) {
    assert((value & 0xffffffff) == value);
    _ensureCapacity(4);
    _bufferData.setUint32(_position, value, endianness);
    _position += 4;
  }

  void writeUint32BE(int value) {
    assert((value & 0xffffffff) == value);
    _ensureCapacity(4);
    _bufferData.setUint32(_position, value, Endian.big);
    _position += 4;
  }

  void writeUint64(int value) {
    _ensureCapacity(8);
    _bufferData.setUint64(_position, value, endianness);
    _position += 8;
  }

  void writeUint64BE(int value) {
    _ensureCapacity(8);
    _bufferData.setUint64(_position, value, Endian.big);
    _position += 8;
  }

  void writeBytes(Uint8List bytes) {
    final len = bytes.length;
    if (len >= maxSizeToBuffer) {
      if (_isHashing) {
        assert(len >= blockSize);
        var start = 0;
        // Fill buffer up to the block size for hashing.
        if (_position > 0) {
          start = roundUp(_position, blockSize) - _position;
          _buffer.setRange(_position, _position + start, bytes);
          _position += start;
          flush();
          assert(_position == 0);
        }
        // Write out the whole number of blocks.
        final sizeToFlush = roundDown(bytes.length - start, blockSize);
        for (var pos = 0; pos < sizeToFlush; pos += blockSize) {
          _addHash(bytes, start + pos, blockSize);
        }
        _out.add(Uint8List.sublistView(bytes, start, start + sizeToFlush));
        _flushed += sizeToFlush;
        // Copy the remaining bytes to the buffer.
        final int remaining = bytes.length - start - sizeToFlush;
        _buffer.setRange(0, remaining, bytes, start + sizeToFlush);
        _position = remaining;
      } else {
        flush();
        _out.add(bytes);
        _flushed += bytes.length;
      }
      return;
    }
    _ensureCapacity(len);
    _buffer.setRange(_position, _position + len, bytes);
    _position += len;
  }

  /// Write a zero-terminated UTF-8 string.
  void writeZString(String value) {
    writeBytes(utf8.encode(value));
    writeUint8(0);
  }

  /// Write a zero-terminated UTF-8 string [value] as [n] characters.
  void writeZStringAsNChars(String value, int n) {
    final utf = utf8.encode(value);
    final len = utf.length;
    if (len >= n) {
      throw ArgumentError('String "$value" exceeds $n characters');
    }
    writeBytes(utf);
    writeZeros(n - len);
  }

  /// Write [len] zero bytes.
  void writeZeros(int len) {
    assert(len >= 0);
    if (len == 0) {
      return;
    }
    _ensureCapacity(len);
    _buffer.fillRange(_position, _position + len, 0);
    _position += len;
  }
}
