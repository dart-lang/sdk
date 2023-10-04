// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is a reimplementation of the header file mach-o/loader.h, which is
// part of the Apple system headers. All comments, which detail the format of
// Mach-O files, have been reproduced from the original header.

import 'dart:io';
import 'dart:typed_data';

import './macho_utils.dart';

class OffsetsAdjuster {
  /// A sorted list of non-negative offsets signifying the start of
  /// non-overlapping adjustment ranges, so either up to (but not including) the
  /// next listed offset or the end of the file.
  final offsets = <int>[0];

  /// The map of offsets to the adjustment needed for their adjustment range.
  final adjustments = <int, int>{0: 0};

  /// Adds a new adjustment at the given offset. If there is not an existing
  /// adjustment range starting at that offset, the adjustment range containing
  /// that offset is split, and all adjustment ranges that start at that offset
  /// or at later offsets have their adjustment increased accordingly.
  void add(int offset, int adjustment) {
    assert(offset >= 0);
    assert(adjustment >= 0);
    var startingIndex = offsets.lastIndexWhere((o) => o <= offset);
    // If the offset didn't already have an adjustment range, split the previous
    // range
    if (offsets[startingIndex] != offset) {
      final newIndex = startingIndex + 1;
      // Add a new adjustment range that starts at the offset and has an
      // initial adjustment value that's the same as the previous range the
      // offset was in.
      offsets.insert(newIndex, offset);
      adjustments[offset] = adjustments[offsets[startingIndex]]!;
      // Start making adjustments at the new range.
      startingIndex = newIndex;
    }
    // Adjust the adjustments for all ranges that start at the given offset
    // or later.
    for (int i = startingIndex; i < offsets.length; i++) {
      final off = offsets[i];
      adjustments[off] = adjustments[offset]! + adjustment;
    }
  }

  /// Adjusts the given offset according to the adjustment ranges collected.
  int adjust(int offset) {
    assert(offset >= 0);
    // We should always get a valid index since we add an entry for the start
    // of the file.
    final rangeStart = offsets.lastWhere((o) => o <= offset);
    return offset + adjustments[rangeStart]!;
  }
}

enum CpuType {
  i386(_typeX86, 'I386'),
  x64(_typeX86 | _architectureABI64, 'X64'),
  arm(_typeArm, 'ARM'),
  arm64(_typeArm | _architectureABI64, 'ARM64');

  final int _code;
  final String _headerName;

  const CpuType(this._code, this._headerName);

  /// Marks an architecture as using a 64-bit ABI.
  static const _architectureABI64 = 0x0100000;

  /// The base type of all X86 architecture variants.
  static const _typeX86 = 0x7;

  /// The base type of all ARM architecture variants.
  static const _typeArm = 0x12;

  static const _prefix = 'CPU_TYPE';

  static CpuType? fromCode(int code) {
    for (final value in values) {
      if (value._code == code) {
        return value;
      }
    }
    return null;
  }

  /// Returns whether the architecture represented by a given `cputype` value
  /// from the MachO header uses 64-bit pointers.
  static bool cpuTypeUses64BitPointers(int code) =>
      code & _architectureABI64 == _architectureABI64;

  /// Returns whether the architecture represented by this uses 64-bit pointers.
  bool get uses64BitPointers => cpuTypeUses64BitPointers(_code);

  @override
  String toString() => '${_prefix}_$_headerName';
}

enum VirtualMemoryProtection {
  none(0x00, 'NONE'),
  read(0x01, 'READ'),
  write(0x02, 'WRITE'),
  execute(0x04, 'EXECUTE');

  final int code;
  final String _headerName;

  const VirtualMemoryProtection(this.code, this._headerName);

  static const _prefix = 'VM_PROT';

  @override
  String toString() => '${_prefix}_$_headerName';
}

enum LoadCommandType {
  // Note that entries marked 'obsolete' in the C headers have not been
  // translated into enum values below.
  //
  // We also do not translate entries that we need not understand (even
  // if LC_REQ_DYLD is set).

  /// A 32-bit segment of the file that is mapped into memory at runtime.
  segment(0x1, 'SEGMENT'),

  /// The static symbol table.
  symbolTable(0x2, 'SYMTAB'),

  /// The dynamic symbol table.
  dynamicSymbolTable(0xb, 'DYSYMTAB'),

  /// A 64-bit segment of the file that is mapped into memory at runtime.
  segment64(0x19, 'SEGMENT_64'),

  /// A code signature.
  codeSignature(0x1d, 'CODE_SIGNATURE'),

  /// Information to split segments.
  segmentSplitInfo(0x1e, 'SEGMENT_SPLIT_INFO'),

  /// 32-bit encrypted segment information.
  encryptionInfo(0x21, 'ENCRYPTION_INFO'),

  /// Compressed dynamically linked shared library information.
  ///
  /// Note that the C headers include a separate name for the version that has
  /// LD_REQ_DYLD set: LC_DYLD_INFO_ONLY. We do not include this name.
  dynamicLibraryInfo(0x22, 'DYLD_INFO'),

  /// Compressed table of function start addresses.
  functionStarts(0x26, 'FUNCTION_STARTS'),

  /// Main entry point (replacement for LC_UNIXTHREAD).
  main(0x28 | _reqDyld, 'MAIN'),

  /// Table of non-instructions in the text segment.
  dataInCode(0x29, 'DATA_IN_CODE'),

  /// Code signing DRs copied from dynamically linked shared libraries.
  dynamicLibraryCodeSigningDRs(0x2b, 'DYLIB_CODE_SIGN_DRS'),

  /// 64-bit encrypted segment information.
  encryptionInfo64(0x2c, 'ENCRYPTION_INFO_64'),

  /// Optimization hints in object files.
  linkerOptimizationHint(0x2e, 'LINKER_OPTIMIZATION_HINT'),

  /// Arbitrary data included within a MachO file.
  note(0x31, 'NOTE'),

  /// A trie of dynamically linked shared library exports.
  dynamicLibraryExportsTrie(0x33 | _reqDyld, 'DYLD_EXPORTS_TRIE'),

  /// Chained fixups for dynamically linked shared libraries.
  dynamicLibraryChainedFixups(0x34 | _reqDyld, 'DYLD_CHAINED_FIXUPS'),

  /// A fileset entry.
  fileSetEntry(0x35 | _reqDyld, 'FILESET_ENTRY');

  /// After MacOS X 10.1 when a new load command is added that is required to be
  /// understood by the dynamic linker for the image to execute properly, this
  /// bit will be or'ed into the load command constant. If the dynamic
  /// linker sees such a load command it does not understand will issue a
  /// "unknown load command required for execution" error and refuse to use the
  /// image.  Other load commands without this bit that are not understood will
  /// simply be ignored.
  ///
  /// `LC_REQ_DYLD` in the C headers.
  static const _reqDyld = 0x80000000;

  final int code;
  final String _headerName;

  const LoadCommandType(this.code, this._headerName);

  static const _prefix = "LC";

  static LoadCommandType? fromCode(int code) {
    for (final value in values) {
      if ((value.code & _reqDyld != 0)) {
        /// LC_REQ_DYLD is set on the enum value, so it can only match exactly.
        if (value.code == code) {
          return value;
        }
      } else {
        /// The LC_REQ_DYLD bit should be ignored for matching purposes.
        final stripped = code & ~_reqDyld;
        if (value.code == stripped) {
          return value;
        }
      }
    }
    return null;
  }

  @override
  String toString() => '${_prefix}_$_headerName';
}

/// A load command describes how to load and use various parts of the file
/// contents (e.g., where to find the TEXT and DATA sections).
abstract class MachOLoadCommand {
  /// The encoding of this load command's type as a 32-bit value.
  ///
  /// `uint32_t cmd` in the C headers.
  final int code;

  /// The total size of the load command in bytes, including the type and size
  /// fields.
  ///
  /// `uint32_t cmdsize` in the C headers.
  final int size;

  MachOLoadCommand(this.code, this.size);

  static MachOLoadCommand fromStream(MachOReader stream) {
    final code = stream.readUint32();
    final size = stream.readUint32();

    final type = LoadCommandType.fromCode(code);
    if (type == null) {
      // Not a MachO section that needs to be adjusted for offset changes, so
      // just read the bytes without interpretation.
      final contents = stream.readBytes(size - 2 * 4);
      return MachOGenericLoadCommand(code, size, contents);
    }

    switch (type) {
      case LoadCommandType.segment:
      case LoadCommandType.segment64:
        return MachOSegmentCommand.fromStream(code, size, stream);
      case LoadCommandType.dynamicLibraryInfo:
        return MachODyldInfoCommand.fromStream(code, size, stream);
      case LoadCommandType.symbolTable:
        return MachOSymtabCommand.fromStream(code, size, stream);
      case LoadCommandType.dynamicSymbolTable:
        return MachODysymtabCommand.fromStream(code, size, stream);
      case LoadCommandType.codeSignature:
      case LoadCommandType.segmentSplitInfo:
      case LoadCommandType.functionStarts:
      case LoadCommandType.dataInCode:
      case LoadCommandType.dynamicLibraryCodeSigningDRs:
      case LoadCommandType.linkerOptimizationHint:
      case LoadCommandType.dynamicLibraryExportsTrie:
      case LoadCommandType.dynamicLibraryChainedFixups:
        return MachOLinkeditDataCommand.fromStream(code, size, stream);
      case LoadCommandType.encryptionInfo:
      case LoadCommandType.encryptionInfo64:
        return MachOEncryptionInfoCommand.fromStream(code, size, stream);
      case LoadCommandType.main:
        return MachOEntryPointCommand.fromStream(code, size, stream);
      case LoadCommandType.note:
        return MachONoteCommand.fromStream(code, size, stream);
      case LoadCommandType.fileSetEntry:
        return MachOFileSetEntryCommand.fromStream(code, size, stream);
    }
  }

  /// The type for this load command. Returns null for MachOGenericLoadCommand.
  LoadCommandType? get type => LoadCommandType.fromCode(code);

  /// Whether or not the dynamic linker is required to understand this load
  /// command.
  bool get mustBeUnderstood => (code & LoadCommandType._reqDyld) != 0;

  /// Returns a version of the load command with any file offsets appropriately
  /// adjusted as needed.
  MachOLoadCommand adjust(OffsetsAdjuster adjuster);

  void writeSync(MachOWriter stream) {
    stream
      ..writeUint32(code)
      ..writeUint32(size);
    writeContentsSync(stream);
  }

  /// Subclasses need to implement this serializer, which should NOT
  /// attempt to serialize the cmd and the cmdsize to the stream. That
  /// logic is handled by the parent class automatically.
  void writeContentsSync(MachOWriter stream);
}

/// A MachO load command that can be copied wholesale without any adjustments.
class MachOGenericLoadCommand extends MachOLoadCommand {
  final Uint8List contents;

  MachOGenericLoadCommand(super.cmd, super.cmdsize, this.contents);

  @override
  MachOLoadCommand adjust(OffsetsAdjuster adjuster) => this;

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeBytes(contents);
  }
}

/// The header of a MachO file. There are 32-bit and 64-bit variations, but
/// the only difference is that 64-bit headers have a reserved field for
/// padding. Thus, we merge the two into a single class.
class MachOHeader {
  /// The magic number identifier for the MachO file. Denotes whether the file
  /// is 32-bit or 64-bit, and whether its endianness matches the host.
  ///
  /// `uint32_t magic` in the C headers.
  final int magic;

  /// The CPU type assumed by this MachO file.
  ///
  /// `cpu_type_t cputype` in the C headers, where `cpu_type_t` is
  /// `integer_t` which is `int`.
  final int cpu;

  /// The machine type assumed by this MachO file.
  ///
  /// `cpu_subtype_t cpusubtype` in the C headers, where `cpu_subtype_t` is
  /// `integer_t` which is `int`.
  final int machine;

  /// The type of the MachO file.
  ///
  /// `uint32_t filetype` in the C headers.
  final int type;

  /// The number of load commands in this MachO file.
  ///
  /// `uint32_t ncmds` in the C headers.
  final int loadCommandsCount;

  /// The total size of the load commands.
  ///
  /// `uint32_t sizeofcmds` in the C headers.
  final int loadCommandsSize;

  /// A bit array of flags in the MachO file.
  ///
  /// `uint32_t flags` in the C headers.
  final int flags;

  /// Reserved space in 64-bit headers, null in 32-bit headers.
  ///
  /// `uint32_t reserved` in the C headers.
  final int? reserved;

  MachOHeader(this.magic, this.cpu, this.machine, this.type,
      this.loadCommandsCount, this.loadCommandsSize, this.flags, this.reserved);

  /// Constant for the magic field of a 32-bit mach_header with host endianness.
  static const int _magic32 = 0xfeedface;

  /// Constant for the magic field of a 32-bit mach_header with swapped
  /// endianness.
  static const int _cigam32 = 0xcefaedfe;

  /// Constant for the magic field of a 64-bit mach_header with host endianness.
  static const int _magic64 = 0xfeedfacf;

  /// Constant for the magic field of a 64-bit mach_header with swapped
  /// endianness.
  static const int _cigam64 = 0xcffaedfe;

  static MachOHeader? fromStream(RandomAccessFile original) {
    // First, read the magic value using host endianness, so we can determine
    // whether the file uses host endianness or swapped endianness.
    final magic = MachOReader(original, Endian.host).readUint32();

    if (!validMagic(magic)) return null;

    final is64Bit = magic == _magic64 || magic == _cigam64;
    final endian = magicEndian(magic);

    // Now recreate the MachOReader with the right endianness.
    final stream = MachOReader(original, endian);
    final cpu = stream.readInt32();
    final machine = stream.readInt32();
    final type = stream.readUint32();
    final loadCommandsCount = stream.readUint32();
    final loadCommandsSize = stream.readUint32();
    final flags = stream.readUint32();
    final reserved = is64Bit ? stream.readUint32() : null;

    return MachOHeader(magic, cpu, machine, type, loadCommandsCount,
        loadCommandsSize, flags, reserved);
  }

  static bool validMagic(int magic) =>
      magic == _magic32 ||
      magic == _magic64 ||
      magic == _cigam32 ||
      magic == _cigam64;

  static Endian magicEndian(int magic) =>
      (magic == _magic64 || magic == _magic32)
          ? Endian.host
          : Endian.host == Endian.big
              ? Endian.little
              : Endian.big;

  // A faster check than rechecking the magic number.
  bool get is64Bit => reserved != null;
  Endian get endian => magicEndian(magic);

  // The size of the header when written to disk. Seven 32-bit fields, plus
  // an extra 32-bit field for 64-bit headers to align it to word size.
  int get size => 7 * 4 + (is64Bit ? 4 : 0);

  void writeSync(RandomAccessFile original) {
    // Like reading, first we write the magic value using host endianness,
    // and then write the rest of the value using the detected endianness.
    MachOWriter(original, Endian.host).writeUint32(magic);
    final stream = MachOWriter(original, endian);
    stream
      ..writeInt32(cpu)
      ..writeInt32(machine)
      ..writeUint32(type)
      ..writeUint32(loadCommandsCount)
      ..writeUint32(loadCommandsSize)
      ..writeUint32(flags);
    if (is64Bit) {
      stream.writeUint32(reserved!);
    }
  }
}

/// A segment load command indicates that a part of this file is to be mapped
/// into a task's address space.  If the segment has sections, the section
/// structures follow directly after the segment load command and their size
/// is reflected in the [size] of the load command.
///
/// In the C headers, there are two different structs for 32-bit and 64-bit
/// segments. Here, we combine them into one, with the [type] of the load
/// command determining whether we read and write 32-bit or 64-bit values for
/// particular fields.
class MachOSegmentCommand extends MachOLoadCommand {
  /// The name of the segment.
  ///
  /// `char segname[16]` in the C headers.
  final String name;

  /// The memory address at which this segment should be placed.
  ///
  /// `uint64_t vmaddr` for 64-bit segment commands and `uint32_t vmaddr`
  /// for 32-bit segment commands in the C headers.
  final int memoryAddress;

  /// The memory size for this segment.
  ///
  /// `uint64_t vmsize` for 64-bit segment commands and `uint32_t vmsize`
  /// for 32-bit segment commands in the C headers.
  final int memorySize;

  /// The file offset for this segment.
  ///
  /// `uint64_t fileoff` for 64-bit segment commands and `uint32_t fileoff`
  /// for 32-bit segment commands in the C headers.
  final int fileOffset;

  /// The file size of this segment.
  ///
  /// `uint64_t filesize` for 64-bit segment commands and `uint32_t filesize`
  /// for 32-bit segment commands in the C headers.
  final int fileSize;

  /// The maximum VM protection allowed for this segment.
  ///
  /// `vm_prot_t maxprot` in the C headers, where `vm_prot_t` is `int`.
  final int maxProtection;

  /// The initial VM protection used for this segment.
  ///
  /// `vm_prot_t initprot` in the C headers, where `vm_prot_t` is `int`.
  final int initialProtection;

  /// The flags set for this segment.
  ///
  /// `uint32_t flags` in the C headers.
  final int flags;

  /// The list of sections structures in the segment.
  ///
  /// Note that we do not keep a separate field for the number of sections
  /// (`uint32_t nsects` in the C headers), but instead just use the length
  /// of this list.
  final List<MachOSection> sections;

  MachOSegmentCommand(
    super.code,
    super.size,
    this.name,
    this.memoryAddress,
    this.memorySize,
    this.fileOffset,
    this.fileSize,
    this.maxProtection,
    this.initialProtection,
    this.flags,
    this.sections,
  );

  static const _nameLength = 16;

  static MachOSegmentCommand fromStream(
      int code, int size, MachOReader stream) {
    bool is64Bit = LoadCommandType.fromCode(code) == LoadCommandType.segment64;
    final wordSize = is64Bit ? 8 : 4;

    final String name = stream.readFixedLengthNullTerminatedString(_nameLength);
    final memoryAddress = stream.readUword(wordSize);
    final memorySize = stream.readUword(wordSize);
    final fileOffset = stream.readUword(wordSize);
    final fileSize = stream.readUword(wordSize);
    final maxProtection = stream.readInt32();
    final initialProtection = stream.readInt32();
    final sectionCount = stream.readUint32();
    final flags = stream.readUint32();

    final sections = List<MachOSection>.generate(
        sectionCount, (_) => MachOSection.fromStream(stream, is64Bit),
        growable: false);

    return MachOSegmentCommand(
        code,
        size,
        name,
        memoryAddress,
        memorySize,
        fileOffset,
        fileSize,
        maxProtection,
        initialProtection,
        flags,
        sections);
  }

  int get _wordSize =>
      LoadCommandType.fromCode(code) == LoadCommandType.segment64 ? 8 : 4;

  @override
  MachOSegmentCommand adjust(OffsetsAdjuster adjuster) => MachOSegmentCommand(
      code,
      size,
      name,
      memoryAddress,
      memorySize,
      adjuster.adjust(fileOffset),
      fileSize,
      maxProtection,
      initialProtection,
      flags,
      sections.map((s) => s.adjust(adjuster)).toList());

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeFixedLengthNullTerminatedString(name, _nameLength);
    stream.writeUword(memoryAddress, _wordSize);
    stream.writeUword(memorySize, _wordSize);
    stream.writeUword(fileOffset, _wordSize);
    stream.writeUword(fileSize, _wordSize);
    stream.writeInt32(maxProtection);
    stream.writeInt32(initialProtection);
    stream.writeUint32(sections.length);
    stream.writeUint32(flags);

    for (final section in sections) {
      section.writeContentsSync(stream);
    }
  }
}

enum SectionType {
  /// A standard section that has no special meaning.
  regular(0x0, 'REGULAR'),

  /// This section has no file contents, but instead any virtual memory for
  /// this section is zero-filled at startup. Must be smaller than 4 gigabytes,
  /// but can be mixed with other types of sections in a given segment.
  zeroFill(0x1, 'ZEROFILL'),

  /// This section has no file contents, but instead any virtual memory for
  /// this section is zero-filled at startup. Can be larger than 4 gigabytes,
  /// but can only be in a segment with the same kind of section.
  gigabyteZeroFill(0xc, 'GB_ZEROFILL'),

  /// This section has no file contents, but instead any virtual memory for
  /// this section is zero-filled at startup. Used for BSS sections.
  threadLocalZeroFill(0x12, 'THREAD_LOCAL_ZEROFILL');

  final int _code;
  final String _headerName;

  const SectionType(this._code, this._headerName);

  static SectionType? fromFlags(int flags) {
    final code = flags & _typeMask;
    for (final value in values) {
      if (value._code == code) {
        return value;
      }
    }
    return null;
  }

  static const _prefix = 'S';
  static const _typeSize = 8;
  static const _typeMask = (1 << _typeSize) - 1;

  @override
  String toString() => '${_prefix}_$_headerName';
}

/// A section describes a specific portion of a segment. The specifics of
/// sections are mostly unimportant for our work here, except that we need
/// to recognize S_ZEROFILL/S_GB_ZEROFILL sections so they can be ignored for
/// file offset purposes.
///
/// In the C headers, sections are represented by two structs, one for 32-bit
/// headers and one for 64-bit headers. Other than whether specific fields
/// are 32-bit or 64-bit, the only other difference is that the 64-bit header
/// contains one more 32-bit reserved field.
class MachOSection {
  /// Name of this section.
  final String name;

  /// Name of the containing segment.
  final String segmentName;

  /// Memory address of this section.
  final int memoryAddress;

  /// The size of this section in memory (and in the file contents if not
  /// a zero fill section).
  final int size;

  /// File offset of the contents of this section.
  final int fileOffset;
  final int alignment;

  /// File offset of the relocation entries.
  final int relocationsFileOffset;

  /// Nuber of relocation entries.
  final int relocationsCount;

  /// Flags, which encode both the section type and any section attributes.
  final int flags;

  /// Reserved (for offset or index).
  ///
  /// `uint32_t reserved1` in the C headers.
  final int reserved1;
  // Reserved (for count or sizeof).
  ///
  /// `uint32_t reserved2` in the C headers.
  final int reserved2;

  /// Reserved in 64-bit sections for padding purposes. Null in 32-bit sections.
  ///
  /// `uint32_t reserved3` in the C headers.
  final int? reserved3;

  MachOSection(
    this.name,
    this.segmentName,
    this.memoryAddress,
    this.size,
    this.fileOffset,
    this.alignment,
    this.relocationsFileOffset,
    this.relocationsCount,
    this.flags,
    this.reserved1,
    this.reserved2,
    this.reserved3,
  );

  static MachOSection fromStream(MachOReader stream, bool is64Bit) {
    final wordSize = is64Bit ? 8 : 4;

    final String name = stream.readFixedLengthNullTerminatedString(_nameLength);
    final String segmentName = stream
        .readFixedLengthNullTerminatedString(MachOSegmentCommand._nameLength);
    final memoryAddress = stream.readUword(wordSize);
    final size = stream.readUword(wordSize);
    final fileOffset = stream.readUint32();
    final alignment = stream.readUint32();
    final relocationsFileOffset = stream.readUint32();
    final relocationsCount = stream.readUint32();
    final flags = stream.readUint32();
    final reserved1 = stream.readUint32();
    final reserved2 = stream.readUint32();
    int? reserved3;
    if (is64Bit) {
      reserved3 = stream.readUint32();
    }

    return MachOSection(
        name,
        segmentName,
        memoryAddress,
        size,
        fileOffset,
        alignment,
        relocationsFileOffset,
        relocationsCount,
        flags,
        reserved1,
        reserved2,
        reserved3);
  }

  static const _nameLength = 16;
  static const _attributesMask = 0xffffffff & ~SectionType._typeMask;

  static int combineIntoFlags(SectionType type, int attributes) {
    assert((attributes & ~_attributesMask) == 0);
    return attributes & type._code;
  }

  bool get is64Bit => reserved3 != null;

  SectionType? get type => SectionType.fromFlags(flags);
  int get attributes => flags & _attributesMask;

  bool get isZeroFill {
    final cachedType = type; // Don't recalculate for each comparison.
    return cachedType == SectionType.zeroFill ||
        cachedType == SectionType.gigabyteZeroFill ||
        cachedType == SectionType.threadLocalZeroFill;
  }

  MachOSection adjust(OffsetsAdjuster adjuster) => MachOSection(
      name,
      segmentName,
      memoryAddress,
      size,
      adjuster.adjust(fileOffset),
      alignment,
      adjuster.adjust(relocationsFileOffset),
      relocationsCount,
      flags,
      reserved1,
      reserved2,
      reserved3);

  void writeContentsSync(MachOWriter stream) {
    final int wordSize = is64Bit ? 8 : 4;
    stream.writeFixedLengthNullTerminatedString(name, _nameLength);
    stream.writeFixedLengthNullTerminatedString(
        segmentName, MachOSegmentCommand._nameLength);
    stream.writeUword(memoryAddress, wordSize);
    stream.writeUword(size, wordSize);
    stream.writeUint32(fileOffset);
    stream.writeUint32(alignment);
    stream.writeUint32(relocationsFileOffset);
    stream.writeUint32(relocationsCount);
    stream.writeUint32(flags);
    stream.writeUint32(reserved1);
    stream.writeUint32(reserved2);
    if (is64Bit) {
      stream.writeUint32(reserved3!);
    }
  }
}

/// A load command that describes a static symbol table.
class MachOSymtabCommand extends MachOLoadCommand {
  /// The file offset of the symbol table.
  ///
  /// `uint32_t symoff` in the C headers.
  final int fileOffset;

  /// The number of symbol table entries.
  ///
  /// `uint32_t symoff` in the C headers.
  final int symbolsCount;

  /// The file offset of the string table.
  ///
  /// `uint32_t stroff` in the C headers.
  final int stringTableFileOffset;

  /// The file size of the string table.
  ///
  /// `uint32_t strsize` in the C headers.
  final int stringTableSize;

  MachOSymtabCommand(
    super.code,
    super.size,
    this.fileOffset,
    this.symbolsCount,
    this.stringTableFileOffset,
    this.stringTableSize,
  );

  static MachOSymtabCommand fromStream(int code, int size, MachOReader stream) {
    final fileOffset = stream.readUint32();
    final symbolsCount = stream.readUint32();
    final stringTableFileOffset = stream.readUint32();
    final stringTableSize = stream.readUint32();

    return MachOSymtabCommand(code, size, fileOffset, symbolsCount,
        stringTableFileOffset, stringTableSize);
  }

  @override
  MachOSymtabCommand adjust(OffsetsAdjuster adjuster) => MachOSymtabCommand(
      code,
      size,
      adjuster.adjust(fileOffset),
      symbolsCount,
      adjuster.adjust(stringTableFileOffset),
      stringTableSize);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint32(fileOffset);
    stream.writeUint32(symbolsCount);
    stream.writeUint32(stringTableFileOffset);
    stream.writeUint32(stringTableSize);
  }
}

/// A load command representing the dynamic symbol table.
class MachODysymtabCommand extends MachOLoadCommand {
  /// The index of the local symbols.
  ///
  /// `uint32_t ilocalsym` in the C headers.
  final int localSymbolsIndex;

  /// The number of local symbols.
  ///
  /// `uint32_t nlocalsym` in the C headers.
  final int localSymbolsCount;

  /// The index of the externally defined symbols.
  ///
  /// `uint32_t iextdefsym` in the C headers.
  final int externalSymbolsIndex;

  /// The number of externally defined symbols.
  ///
  /// `uint32_t nextdefsym` in the C headers.
  final int externalSymbolsCount;

  /// The index of the undefined symbols.
  ///
  /// `uint32_t iundefsym` in the C headers.
  final int undefinedSymbolsIndex;

  /// The number of undefined symbols.
  ///
  /// `uint32_t nundefsym` in the C headers.
  final int undefinedSymbolsCount;

  /// The file offset of the table of contents.
  ///
  /// `uint32_t tocoff` in the C headers.
  final int tableOfContentsFileOffset;

  /// The number of entries in the table of contents.
  ///
  /// `uint32_t ntoc` in the C headers.
  final int tableOfContentsEntryCount;

  /// The file offset of the module table.
  ///
  /// `uint32_t modtaboff` in the C headers.
  final int moduleTableFileOffset;

  /// The number of entries in the module table.
  ///
  /// `uint32_t nmodtab` in the C headers.
  final int moduleTableEntryCount;

  /// The file offset of the referenced symbol table.
  ///
  /// `uint32_t extrefsymoff` in the C headers.
  final int referencedSymbolTableFileOffset;

  /// The number of entries in the referenced symbol table.
  ///
  /// `uint32_t nextrefsyms` in the C headers.
  final int referencedSymbolTableEntryCount;

  /// The file offset of the indirect symbol table.
  ///
  /// `uint32_t indirectsymoff` in the C headers.
  final int indirectSymbolTableFileOffset;

  /// The number of entries in the indirect symbol table.
  ///
  /// `uint32_t nindirectsyms` in the C headers.
  final int indirectSymbolTableEntryCount;

  /// The file offset of external relocation entries.
  ///
  /// `uint32_t extreloff` in the C headers.
  final int externalRelocationsFileOffset;

  /// The number of external relocation entries.
  ///
  /// `uint32_t nextrel` in the C headers.
  final int externalRelocationsCount;

  /// The file offset of local relocation entries.
  ///
  /// `uint32_t locreloff` in the C headers.
  final int localRelocationsFileOffset;

  /// The number of local relocation entries.
  ///
  /// `uint32_t nlocrel` in the C headers.
  final int localRelocationsCount;

  MachODysymtabCommand(
      super.code,
      super.size,
      this.localSymbolsIndex,
      this.localSymbolsCount,
      this.externalSymbolsIndex,
      this.externalSymbolsCount,
      this.undefinedSymbolsIndex,
      this.undefinedSymbolsCount,
      this.tableOfContentsFileOffset,
      this.tableOfContentsEntryCount,
      this.moduleTableFileOffset,
      this.moduleTableEntryCount,
      this.referencedSymbolTableFileOffset,
      this.referencedSymbolTableEntryCount,
      this.indirectSymbolTableFileOffset,
      this.indirectSymbolTableEntryCount,
      this.externalRelocationsFileOffset,
      this.externalRelocationsCount,
      this.localRelocationsFileOffset,
      this.localRelocationsCount);

  static MachODysymtabCommand fromStream(
      int code, int size, MachOReader stream) {
    final localSymbolsIndex = stream.readUint32();
    final localSymbolsCount = stream.readUint32();
    final externalSymbolsIndex = stream.readUint32();
    final externalSymbolsCount = stream.readUint32();
    final undefinedSymbolsIndex = stream.readUint32();
    final undefinedSymbolsCount = stream.readUint32();
    final tableOfContentsFileOffset = stream.readUint32();
    final tableOfContentsEntryCount = stream.readUint32();
    final moduleTableFileOffset = stream.readUint32();
    final moduleTableEntryCount = stream.readUint32();
    final referencedSymbolTableFileOffset = stream.readUint32();
    final referencedSymbolTableEntryCount = stream.readUint32();
    final indirectSymbolTableFileOffset = stream.readUint32();
    final indirectSymbolTableEntryCount = stream.readUint32();
    final externalRelocationsFileOffset = stream.readUint32();
    final externalRelocationsCount = stream.readUint32();
    final localRelocationsFileOffset = stream.readUint32();
    final localRelocationsCount = stream.readUint32();

    return MachODysymtabCommand(
        code,
        size,
        localSymbolsIndex,
        localSymbolsCount,
        externalSymbolsIndex,
        externalSymbolsCount,
        undefinedSymbolsIndex,
        undefinedSymbolsCount,
        tableOfContentsFileOffset,
        tableOfContentsEntryCount,
        moduleTableFileOffset,
        moduleTableEntryCount,
        referencedSymbolTableFileOffset,
        referencedSymbolTableEntryCount,
        indirectSymbolTableFileOffset,
        indirectSymbolTableEntryCount,
        externalRelocationsFileOffset,
        externalRelocationsCount,
        localRelocationsFileOffset,
        localRelocationsCount);
  }

  @override
  MachODysymtabCommand adjust(OffsetsAdjuster adjuster) => MachODysymtabCommand(
      code,
      size,
      localSymbolsIndex,
      localSymbolsCount,
      externalSymbolsIndex,
      externalSymbolsCount,
      undefinedSymbolsIndex,
      undefinedSymbolsCount,
      adjuster.adjust(tableOfContentsFileOffset),
      tableOfContentsEntryCount,
      adjuster.adjust(moduleTableFileOffset),
      moduleTableEntryCount,
      adjuster.adjust(referencedSymbolTableFileOffset),
      referencedSymbolTableEntryCount,
      adjuster.adjust(indirectSymbolTableFileOffset),
      indirectSymbolTableEntryCount,
      adjuster.adjust(externalRelocationsFileOffset),
      externalRelocationsCount,
      adjuster.adjust(localRelocationsFileOffset),
      localRelocationsCount);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint32(localSymbolsIndex);
    stream.writeUint32(localSymbolsCount);
    stream.writeUint32(externalSymbolsIndex);
    stream.writeUint32(externalSymbolsCount);
    stream.writeUint32(undefinedSymbolsIndex);
    stream.writeUint32(undefinedSymbolsCount);
    stream.writeUint32(tableOfContentsFileOffset);
    stream.writeUint32(tableOfContentsEntryCount);
    stream.writeUint32(moduleTableFileOffset);
    stream.writeUint32(moduleTableEntryCount);
    stream.writeUint32(referencedSymbolTableFileOffset);
    stream.writeUint32(referencedSymbolTableEntryCount);
    stream.writeUint32(indirectSymbolTableFileOffset);
    stream.writeUint32(indirectSymbolTableEntryCount);
    stream.writeUint32(externalRelocationsFileOffset);
    stream.writeUint32(externalRelocationsCount);
    stream.writeUint32(localRelocationsFileOffset);
    stream.writeUint32(localRelocationsCount);
  }
}

/// A load command that contains the offsets and sizes of a blob of data in
/// the __LINKEDIT segment. The contents of the blob is determined by the
/// specific `code` value used for the load command.
class MachOLinkeditDataCommand extends MachOLoadCommand {
  /// The file offset for the segment data.
  ///
  /// `uint32_t dataoff` in the C headers.
  final int dataFileOffset;

  /// The file size of the segment data.
  ///
  /// `uint32_t datasize` in the C headers.
  final int dataSize;

  MachOLinkeditDataCommand(
    super.code,
    super.size,
    this.dataFileOffset,
    this.dataSize,
  );

  static MachOLinkeditDataCommand fromStream(
      int code, final int size, MachOReader stream) {
    final dataFileOffset = stream.readUint32();
    final dataSize = stream.readUint32();

    return MachOLinkeditDataCommand(code, size, dataFileOffset, dataSize);
  }

  @override
  MachOLinkeditDataCommand adjust(OffsetsAdjuster adjuster) =>
      MachOLinkeditDataCommand(
          code, size, adjuster.adjust(dataFileOffset), dataSize);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint32(dataFileOffset);
    stream.writeUint32(dataSize);
  }
}

/// A load command that contains the offset and size of an encrypted segment.
class MachOEncryptionInfoCommand extends MachOLoadCommand {
  /// The file offset for the encrypted segment.
  ///
  /// `uint32_t cryptoff` in the C headers.
  final int fileOffset;

  /// The file size of the encrypted segment.
  ///
  /// `uint32_t cryptsize` in the C headers.
  final int fileSize;

  /// The id of the encryption system used for the encrypted segment.
  /// A value of 0 means that the segment is not yet encrypted.
  ///
  /// `uint32_t cryptid` in the C headers.
  final int encryptionSystem;

  /// Padding for 64-bit encryption info load commands. Null for 32-bit
  /// encryption info load commands.
  ///
  /// `uint32_t pad` for `encryption_info_command_64` in the C headers.
  final int? padding;

  MachOEncryptionInfoCommand(super.code, super.size, this.fileOffset,
      this.fileSize, this.encryptionSystem, this.padding);

  static MachOEncryptionInfoCommand fromStream(
      int code, final int size, MachOReader stream) {
    final is64Bit =
        LoadCommandType.fromCode(code) == LoadCommandType.encryptionInfo64;

    final fileOffset = stream.readUint32();
    final fileSize = stream.readUint32();
    final encryptionSystem = stream.readUint32();
    int? padding;
    if (is64Bit) {
      padding = stream.readUint32();
    }

    return MachOEncryptionInfoCommand(
        code, size, fileOffset, fileSize, encryptionSystem, padding);
  }

  @override
  MachOEncryptionInfoCommand adjust(OffsetsAdjuster adjuster) =>
      MachOEncryptionInfoCommand(code, size, adjuster.adjust(fileOffset),
          fileSize, encryptionSystem, padding);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint32(fileOffset);
    stream.writeUint32(fileSize);
    stream.writeUint32(encryptionSystem);
    if (padding != null) {
      stream.writeUint32(padding!);
    }
  }
}

/// A load command that contains the file offsets and sizes of  the new
/// compressed form of the information dyld needs to load the image on
/// MacOS 10.6 and later.
class MachODyldInfoCommand extends MachOLoadCommand {
  /// File offset for rebase information.
  ///
  /// `uint32_t rebase_off` in the C headers.
  final int rebaseOffset;

  /// File size of rebase information.
  ///
  /// `uint32_t rebase_size` in the C headers.
  final int rebaseSize;

  /// File offset for binding information.
  ///
  /// `uint32_t bind_off` in the C headers.
  final int bindingOffset;

  /// File size of binding information.
  ///
  /// `uint32_t bind_size` in the C headers.
  final int bindingSize;

  /// File offset for weak binding information.
  ///
  /// `uint32_t weak_bind_off` in the C headers.
  final int weakBindingOffset;

  /// File size of weak binding information.
  ///
  /// `uint32_t weak_bind_size` in the C headers.
  final int weakBindingSize;

  /// File offset for lazy binding information.
  ///
  /// `uint32_t lazy_bind_off` in the C headers.
  final int lazyBindingOffset;

  /// File size of lazy binding information.
  ///
  /// `uint32_t lazy_bind_size` in the C headers.
  final int lazyBindingSize;

  /// File offset for export information.
  ///
  /// `uint32_t export_off` in the C headers.
  final int exportOffset;

  /// File size of export information.
  ///
  /// `uint32_t export_size` in the C headers.
  final int exportSize;

  MachODyldInfoCommand(
      super.code,
      super.size,
      this.rebaseOffset,
      this.rebaseSize,
      this.bindingOffset,
      this.bindingSize,
      this.weakBindingOffset,
      this.weakBindingSize,
      this.lazyBindingOffset,
      this.lazyBindingSize,
      this.exportOffset,
      this.exportSize);

  static MachODyldInfoCommand fromStream(
      int code, int size, MachOReader stream) {
    final rebaseOffset = stream.readUint32();
    final rebaseSize = stream.readUint32();
    final bindingOffset = stream.readUint32();
    final bindingSize = stream.readUint32();
    final weakBindingOffset = stream.readUint32();
    final weakBindingSize = stream.readUint32();
    final lazyBindingOffset = stream.readUint32();
    final lazyBindingSize = stream.readUint32();
    final exportOffset = stream.readUint32();
    final exportSize = stream.readUint32();

    return MachODyldInfoCommand(
        code,
        size,
        rebaseOffset,
        rebaseSize,
        bindingOffset,
        bindingSize,
        weakBindingOffset,
        weakBindingSize,
        lazyBindingOffset,
        lazyBindingSize,
        exportOffset,
        exportSize);
  }

  @override
  MachODyldInfoCommand adjust(OffsetsAdjuster adjuster) => MachODyldInfoCommand(
      code,
      size,
      adjuster.adjust(rebaseOffset),
      rebaseSize,
      adjuster.adjust(bindingOffset),
      bindingSize,
      adjuster.adjust(weakBindingOffset),
      weakBindingSize,
      adjuster.adjust(lazyBindingOffset),
      lazyBindingSize,
      adjuster.adjust(exportOffset),
      exportSize);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint32(rebaseOffset);
    stream.writeUint32(rebaseSize);
    stream.writeUint32(bindingOffset);
    stream.writeUint32(bindingSize);
    stream.writeUint32(weakBindingOffset);
    stream.writeUint32(weakBindingSize);
    stream.writeUint32(lazyBindingOffset);
    stream.writeUint32(lazyBindingSize);
    stream.writeUint32(exportOffset);
    stream.writeUint32(exportSize);
  }
}

/// A load command used for executables to specify the file offset of the entry
/// point of the program.
class MachOEntryPointCommand extends MachOLoadCommand {
  /// The file offset of the entry point to the program (e.g., main()).
  ///
  /// `uint64_t entryoff` in the C headers.
  final int entryOffset;

  /// When non-zero, specifies the initial stack size.
  ///
  /// `uint64_t stacksize` in the C headers.
  final int stackSize;

  MachOEntryPointCommand(
      super.code, super.size, this.entryOffset, this.stackSize);

  static MachOEntryPointCommand fromStream(
      int code, int size, MachOReader stream) {
    final entryOffset = stream.readUint64();
    final stackSize = stream.readUint64();
    return MachOEntryPointCommand(code, size, entryOffset, stackSize);
  }

  @override
  MachOEntryPointCommand adjust(OffsetsAdjuster adjuster) =>
      MachOEntryPointCommand(
          code, size, adjuster.adjust(entryOffset), stackSize);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint64(entryOffset);
    stream.writeUint64(stackSize);
  }
}

/// A load command that references an array of entries in the __LINKEDIT
/// segment, each of which describes a range of data located in the __TEXT
/// segment.
class MachODataInCodeEntry extends MachOLoadCommand {
  /// The file offset of the array of data in code entries.
  ///
  /// `uint32_t offset` in the C headers.
  final int offset;

  /// The length of the array of data in bytes.
  ///
  /// `uint16_t length` in the C headers.
  final int length;

  /// The kind of entries contained in the array as a `DICE_KIND_` value.
  ///
  /// `uint16_t kind` in the C headers.
  final int kind;

  MachODataInCodeEntry(
    super.code,
    super.size,
    this.offset,
    this.length,
    this.kind,
  );

  static MachODataInCodeEntry fromStream(
      int code, int size, MachOReader stream) {
    final offset = stream.readUint32();
    final length = stream.readUint16();
    final kind = stream.readUint16();
    return MachODataInCodeEntry(code, size, offset, length, kind);
  }

  @override
  MachODataInCodeEntry adjust(OffsetsAdjuster adjuster) =>
      MachODataInCodeEntry(code, size, adjuster.adjust(offset), length, kind);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint32(offset);
    stream.writeUint16(length);
    stream.writeUint16(kind);
  }
}

/// A load command that points to an arbitrary block of data in the file.
class MachONoteCommand extends MachOLoadCommand {
  /// The owner name for this note.
  ///
  /// `char data_owner[16]` in the C headers.
  final String dataOwner;

  /// The file offset for the data.
  ///
  /// `uint64_t offset` in the C headers.
  final int fileOffset;

  /// The file size of the data.
  ///
  /// `uint64_t size` in the C headers.
  final int fileSize;

  MachONoteCommand(
      super.code, super.size, this.dataOwner, this.fileOffset, this.fileSize);

  static MachONoteCommand fromStream(int code, int size, MachOReader stream) {
    final dataOwner =
        stream.readFixedLengthNullTerminatedString(_dataOwnerLength);
    final fileOffset = stream.readUint64();
    final fileSize = stream.readUint64();
    return MachONoteCommand(code, size, dataOwner, fileOffset, fileSize);
  }

  /// Constructs a note load command given the content of the note-specific
  /// fields, using the default values for the code and size fields.
  static MachONoteCommand fromFields(
          String dataOwner, int fileOffset, int fileSize) =>
      MachONoteCommand(LoadCommandType.note.code, _defaultSize, dataOwner,
          fileOffset, fileSize);

  /// The maximum size of the dataOwner field contents.
  static const _dataOwnerLength = 16;

  // The total size of any given note load command. A note load command contains
  // the 4-byte cmd and cmdsize fields that start every load command, a 16 byte
  // name field, and then two additional 8-byte fields.
  static const _defaultSize = 4 + 4 + 16 + 8 + 8;

  @override
  MachONoteCommand adjust(OffsetsAdjuster adjuster) => MachONoteCommand(
      code, size, dataOwner, adjuster.adjust(fileOffset), fileSize);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeFixedLengthNullTerminatedString(dataOwner, _dataOwnerLength);
    stream.writeUint64(fileOffset);
    stream.writeUint64(fileSize);
  }
}

/// A load command that specifies a fileset entry.
class MachOFileSetEntryCommand extends MachOLoadCommand {
  /// The memory address of the dynamically linked shared library.
  ///
  /// `uint64_t vmaddr` in the C headers.
  final int memoryAddress;

  /// The file offset of the dynamically linked shared library.
  ///
  /// `uint64_t fileoff` in the C headers.
  final int fileOffset;

  /// The contained entry id.
  ///
  /// `lc_str entry_id` in the C headers.
  final int entryId;

  /// Reserved padding.
  ///
  /// `uint32_t reserved` in the C headers.
  final int reserved;

  MachOFileSetEntryCommand(super.code, super.size, this.memoryAddress,
      this.fileOffset, this.entryId, this.reserved);

  static MachOFileSetEntryCommand fromStream(
      int code, int size, MachOReader stream) {
    final memoryAddress = stream.readUint64();
    final fileOffset = stream.readUint64();
    final entryId = stream.readLCString();
    final reserved = stream.readUint32();
    return MachOFileSetEntryCommand(
        code, size, memoryAddress, fileOffset, entryId, reserved);
  }

  @override
  MachOFileSetEntryCommand adjust(OffsetsAdjuster adjuster) =>
      MachOFileSetEntryCommand(code, size, memoryAddress,
          adjuster.adjust(fileOffset), entryId, reserved);

  @override
  void writeContentsSync(MachOWriter stream) {
    stream.writeUint64(memoryAddress);
    stream.writeUint64(fileOffset);
    stream.writeLCString(entryId);
    stream.writeUint32(reserved);
  }
}

/// The headers and load commands of a MachO file. Note that this class does
/// not contain the contents of the load commands. Instead, those are expected
/// to be copied over from the original file appropriately.
class MachOFile {
  /// The header of the MachO file.
  final MachOHeader header;

  /// The load commands of the MachO file, which represent how to read the
  /// non-header contents of the MachO file.
  final List<MachOLoadCommand> commands;

  /// Whether or not the parsed MachO file has a code signature.
  final bool hasCodeSignature;

  MachOFile._(this.header, this.commands, this.hasCodeSignature);

  static MachOFile fromFile(File file) {
    // Ensure the file is long enough to contain the magic bytes.
    final int fileLength = file.lengthSync();
    if (fileLength < 4) {
      throw FormatException(
          "File was not formatted properly. Length was too short: $fileLength");
    }

    final stream = file.openSync();
    final header = MachOHeader.fromStream(stream);
    if (header == null) {
      throw FormatException(
          "Could not parse a MachO header from the file: ${file.path}");
    }

    final uses64BitPointers = CpuType.cpuTypeUses64BitPointers(header.cpu);
    final reader = MachOReader(stream, header.endian, uses64BitPointers);

    final commands = List<MachOLoadCommand>.generate(
        header.loadCommandsCount, (_) => MachOLoadCommand.fromStream(reader));

    final size = _totalSize(header, commands);
    assert(size == stream.positionSync());

    final hasCodeSignature =
        commands.any((c) => c.type == LoadCommandType.codeSignature);

    return MachOFile._(header, commands, hasCodeSignature);
  }

  /// Returns a new MachOFile that is like the input, but with the empty segment
  /// used to reserve header space dropped and with a new note load command
  /// inserted prior to the __LINKEDIT segment load command. Any file offsets
  /// in other load commands that reference the __LINKEDIT segment are adjusted
  /// appropriately.
  MachOFile adjustHeaderForSnapshot(int snapshotSize) {
    // This is not an idempotent operation.
    if (snapshotNote != null) {
      throw FormatException(
          "The executable already has a Dart snapshot inserted");
    }

    final reserved = reservedSegment;
    if (reserved == null) {
      throw FormatException("$reservedSegmentName segment not found");
    }

    final linkedit = linkEditSegment;
    if (linkedit == null) {
      throw FormatException("__LINKEDIT segment not found");
    }

    // We insert the contents of the snapshot where the old linkedit segment
    // started in the original executable, aligned appropriately.
    final int fileOffset = align(linkedit.fileOffset, segmentAlignment);
    final int fileSize = snapshotSize;

    final note =
        MachONoteCommand.fromFields(snapshotNoteName, fileOffset, fileSize);

    // Now we need to build the new header from these modified pieces.
    final newHeader = MachOHeader(
        header.magic,
        header.cpu,
        header.machine,
        header.type,
        // We remove the reserved section and replace it with the note.
        header.loadCommandsCount,
        header.loadCommandsSize - reserved.size + note.size,
        header.flags,
        header.reserved);

    // We'll want the __LINKEDIT segment to start at the next aligned file
    // offset after the end of the snapshot, so we'll need to adjust all
    // file offsets pointing into it (including its own segment) accordingly.
    final snapshotEnd =
        align(note.fileOffset + note.fileSize, segmentAlignment);
    final adjuster = OffsetsAdjuster()
      ..add(linkedit.fileOffset, snapshotEnd - linkedit.fileOffset);
    final newCommands = <MachOLoadCommand>[];
    for (final command in commands) {
      if (command == reserved) {
        // Drop the reserved segment on the floor, as we only add it so there's
        // enough header space to add the note.
        continue;
      }
      if (command == linkedit) {
        // Insert the new note prior to the __LINKEDIT segment.
        newCommands.add(note);
      }
      newCommands.add(command.adjust(adjuster));
    }

    final newFile = MachOFile._(newHeader, newCommands, hasCodeSignature);

    if (newFile.size > size) {
      throw FormatException("Cannot add new note load command to header: "
          "new size ${newFile.size} > the old size $size)");
    }

    return newFile;
  }

  /// The name of the segment containing all the structs created and maintained
  /// by the link editor.
  static const _linkEditSegmentName = "__LINKEDIT";

  /// Retrieves the segment load command used to reserve header space for the
  /// snapshot information. Returns null if not found or if it is of an
  /// unexpected form.
  MachOSegmentCommand? get reservedSegment {
    final reservedIndex = commands.indexWhere(
        (c) => c is MachOSegmentCommand && c.name == reservedSegmentName);
    if (reservedIndex < 0) {
      return null;
    }
    final reserved = commands[reservedIndex] as MachOSegmentCommand;
    assert(reserved.fileSize == 0);
    assert(reserved.sections.single.name == reservedSectionName);
    return reserved;
  }

  /// Retrieves the __LINKEDIT segment load command. Returns null if not found.
  MachOSegmentCommand? get linkEditSegment {
    final linkEditIndex = commands.indexWhere(
        (c) => c is MachOSegmentCommand && c.name == _linkEditSegmentName);
    if (linkEditIndex < 0) {
      return null;
    }

    // __LINKEDIT  should be the last segment load command.
    assert(
        !commands.skip(linkEditIndex + 1).any((c) => c is MachOSegmentCommand));

    return commands[linkEditIndex] as MachOSegmentCommand;
  }

  /// Retrieves the note load command that points to the snapshot contents in
  /// the executable. Returns null if not found.
  MachONoteCommand? get snapshotNote {
    final snapshotIndex = commands.indexWhere(
        (c) => c is MachONoteCommand && c.dataOwner == snapshotNoteName);
    if (snapshotIndex < 0) {
      return null;
    }
    return commands[snapshotIndex] as MachONoteCommand;
  }

  static bool containsSnapshot(File file) =>
      MachOFile.fromFile(file).snapshotNote != null;

  static int _totalSize(MachOHeader header, List<MachOLoadCommand> commands) =>
      commands.fold(header.size, (i, c) => i + c.size);

  int get size => _totalSize(header, commands);

  /// Writes the MachO file to the given [RandomAccessFile] stream.
  void writeSync(RandomAccessFile stream) {
    header.writeSync(stream);

    final uses64BitPointers = CpuType.cpuTypeUses64BitPointers(header.cpu);
    final writer = MachOWriter(stream, header.endian, uses64BitPointers);
    // Write all of the commands.
    for (var command in commands) {
      command.writeSync(writer);
    }
  }
}
