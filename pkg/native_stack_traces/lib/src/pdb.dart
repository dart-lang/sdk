// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reading of PDB files, which contain the debugging information for
// PE/COFF snapshots.
//
// References:
// - https://llvm.org/docs/PDB/index.html
// - https://github.com/microsoft/microsoft-pdb (cvinfo.h, dbi.h)

import 'dart:convert';
import 'dart:ffi'
    show
        Array,
        Int32,
        Packed,
        Struct,
        Uint16,
        Uint32,
        Uint8,
        Uint8Array,
        sizeOf;
import 'dart:typed_data';

import 'constants.dart' as constants;
import 'dwarf.dart';
import 'reader.dart';

/// A cursor for reading little-endian data.
///
/// Unlike [Reader], decodes strings as UTF-8, as CodeView strings are, and
/// aligns relative to a base offset, as the substreams of PDB streams are
/// aligned relative to their start.
class _Cursor {
  final ByteData _data;
  int offset;

  _Cursor(Uint8List bytes, [this.offset = 0])
      : _data = ByteData.sublistView(bytes);

  int get length => _data.lengthInBytes;
  bool get done => offset >= length;

  int u8() => _data.getUint8(offset++);

  int u16() {
    final value = _data.getUint16(offset, Endian.little);
    offset += 2;
    return value;
  }

  int u32() {
    final value = _data.getUint32(offset, Endian.little);
    offset += 4;
    return value;
  }

  /// Reads a struct with [reader].
  T read<T extends Struct>(_StructReader<T> reader) {
    final value = reader.create(_data, offset);
    offset += reader.size;
    return value;
  }

  /// Reads the prefix of a type or symbol record, and returns the kind of the
  /// record and the offset of its end.
  (int, int) recordPrefix() {
    final start = offset;
    final prefix = read(_recordPrefix);
    return (prefix.recordKind, start + 2 + prefix.recordLen);
  }

  Uint8List bytes(int size) {
    final value = Uint8List.sublistView(_data, offset, offset + size);
    offset += size;
    return value;
  }

  String string() {
    var end = offset;
    while (end < length && _data.getUint8(end) != 0) {
      end++;
    }
    final value = utf8.decode(Uint8List.sublistView(_data, offset, end),
        allowMalformed: true);
    offset = end + 1;
    return value;
  }

  void align(int alignment, {int base = 0}) {
    offset = base + (offset - base + alignment - 1) ~/ alignment * alignment;
  }
}

/// Creates views of structs of type [T] on bytes.
///
/// [Struct.create] needs its type argument to be known at compile time, so
/// each struct type has its own reader, like [_dbiStreamHeader]. Like PDB
/// files, the structs are little-endian, as all hosts that Dart runs on are.
final class _StructReader<T extends Struct> {
  final int size;
  final T Function(TypedData data, int offset) create;

  const _StructReader(this.size, this.create);
}

// The structs of PDB files, with the names they have in LLVM and in
// microsoft-pdb.

/// The super block at the start of an MSF file (`SuperBlock` in LLVM's
/// MSFCommon.h, https://llvm.org/docs/PDB/MsfFile.html).
final class _SuperBlock extends Struct {
  @Array(32)
  external Array<Uint8> fileMagic;
  @Uint32()
  external int blockSize;
  @Uint32()
  external int freeBlockMapBlock;
  @Uint32()
  external int numBlocks;
  @Uint32()
  external int numDirectoryBytes;
  @Uint32()
  external int unknown;
  @Uint32()
  external int blockMapAddr;
}

final _superBlock = _StructReader(sizeOf<_SuperBlock>(),
    (data, offset) => Struct.create<_SuperBlock>(data, offset));

/// A GUID (`GUID` in guiddef.h).
final class _Guid extends Struct {
  @Uint32()
  external int data1;
  @Uint16()
  external int data2;
  @Uint16()
  external int data3;
  @Array(8)
  external Array<Uint8> data4;
}

/// The header of the PDB info stream (`PDBStreamHeader` in LLVM's RawTypes.h,
/// https://llvm.org/docs/PDB/PdbStream.html).
final class _PdbStreamHeader extends Struct {
  @Uint32()
  external int version;
  @Uint32()
  external int signature;
  @Uint32()
  external int age;
  external _Guid guid;
}

final _pdbStreamHeader = _StructReader(sizeOf<_PdbStreamHeader>(),
    (data, offset) => Struct.create<_PdbStreamHeader>(data, offset));

/// The header of the string table in the /names stream
/// (`PDBStringTableHeader` in LLVM's RawTypes.h,
/// https://llvm.org/docs/PDB/StringTable.html).
final class _StringTableHeader extends Struct {
  @Uint32()
  external int signature;
  @Uint32()
  external int hashVersion;
  @Uint32()
  external int byteSize;
}

final _stringTableHeader = _StructReader(sizeOf<_StringTableHeader>(),
    (data, offset) => Struct.create<_StringTableHeader>(data, offset));

/// The header of the TPI and IPI streams (`TpiStreamHeader` in LLVM's
/// RawTypes.h, https://llvm.org/docs/PDB/TpiStream.html).
final class _TpiStreamHeader extends Struct {
  @Uint32()
  external int version;
  @Uint32()
  external int headerSize;
  @Uint32()
  external int typeIndexBegin;
  @Uint32()
  external int typeIndexEnd;
  @Uint32()
  external int typeRecordBytes;
  @Uint16()
  external int hashStreamIndex;
  @Uint16()
  external int hashAuxStreamIndex;
  @Uint32()
  external int hashKeySize;
  @Uint32()
  external int numHashBuckets;
  @Int32()
  external int hashValueBufferOffset;
  @Uint32()
  external int hashValueBufferLength;
  @Int32()
  external int indexOffsetBufferOffset;
  @Uint32()
  external int indexOffsetBufferLength;
  @Int32()
  external int hashAdjBufferOffset;
  @Uint32()
  external int hashAdjBufferLength;
}

final _tpiStreamHeader = _StructReader(sizeOf<_TpiStreamHeader>(),
    (data, offset) => Struct.create<_TpiStreamHeader>(data, offset));

/// The prefix of type and symbol records (`RecordPrefix` in LLVM's
/// RecordSerialization.h).
final class _RecordPrefix extends Struct {
  /// The length of the record, not including this field.
  @Uint16()
  external int recordLen;
  @Uint16()
  external int recordKind;
}

final _recordPrefix = _StructReader(sizeOf<_RecordPrefix>(),
    (data, offset) => Struct.create<_RecordPrefix>(data, offset));

/// An `LF_FUNC_ID` or `LF_MFUNC_ID` type record, followed by the name of the
/// function (`lfFuncId` and `lfMFuncId` in cvinfo.h).
final class _FuncIdRecord extends Struct {
  /// The scope of an `LF_FUNC_ID`, or the parent type of an `LF_MFUNC_ID`.
  @Uint32()
  external int scope;
  @Uint32()
  external int type;
}

final _funcIdRecord = _StructReader(sizeOf<_FuncIdRecord>(),
    (data, offset) => Struct.create<_FuncIdRecord>(data, offset));

/// The header of the DBI stream (`DbiStreamHeader` in LLVM's RawTypes.h,
/// `NewDBIHdr` in dbi.h, https://llvm.org/docs/PDB/DbiStream.html).
final class _DbiStreamHeader extends Struct {
  @Int32()
  external int versionSignature;
  @Uint32()
  external int versionHeader;
  @Uint32()
  external int age;
  @Uint16()
  external int globalSymbolStreamIndex;
  @Uint16()
  external int buildNumber;
  @Uint16()
  external int publicSymbolStreamIndex;
  @Uint16()
  external int pdbDllVersion;
  @Uint16()
  external int symRecordStreamIndex;
  @Uint16()
  external int pdbDllRbld;
  @Int32()
  external int modiSubstreamSize;
  @Int32()
  external int secContrSubstreamSize;
  @Int32()
  external int sectionMapSize;
  @Int32()
  external int fileInfoSize;
  @Int32()
  external int typeServerSize;
  @Uint32()
  external int mfcTypeServerIndex;
  @Int32()
  external int optionalDbgHdrSize;
  @Int32()
  external int ecSubstreamSize;
  @Uint16()
  external int flags;
  @Uint16()
  external int machine;
  @Uint32()
  external int reserved;
}

final _dbiStreamHeader = _StructReader(sizeOf<_DbiStreamHeader>(),
    (data, offset) => Struct.create<_DbiStreamHeader>(data, offset));

/// A section contribution (`SectionContrib` in LLVM's RawTypes.h, `SC` in
/// dbi.h).
final class _SectionContrib extends Struct {
  @Uint16()
  external int iSect;
  @Array(2)
  external Array<Uint8> padding;
  @Int32()
  external int off;
  @Int32()
  external int size;
  @Uint32()
  external int characteristics;
  @Uint16()
  external int imod;
  @Array(2)
  external Array<Uint8> padding2;
  @Uint32()
  external int dataCrc;
  @Uint32()
  external int relocCrc;
}

/// The module info of a module in the DBI stream, followed by the names of the
/// module and of its object file (`ModuleInfoHeader` in LLVM's RawTypes.h,
/// `MODI_60_Persist` in dbi.h).
final class _ModuleInfoHeader extends Struct {
  @Uint32()
  external int mod;
  external _SectionContrib sc;
  @Uint16()
  external int flags;
  @Uint16()
  external int moduleSymStream;
  @Uint32()
  external int symBytes;
  @Uint32()
  external int c11Bytes;
  @Uint32()
  external int c13Bytes;
  @Uint16()
  external int numFiles;
  @Array(2)
  external Array<Uint8> padding;
  @Uint32()
  external int fileNameOffs;
  @Uint32()
  external int srcFileNameNI;
  @Uint32()
  external int pdbFilePathNI;
}

final _moduleInfoHeader = _StructReader(sizeOf<_ModuleInfoHeader>(),
    (data, offset) => Struct.create<_ModuleInfoHeader>(data, offset));

/// A section header in the section header stream (`IMAGE_SECTION_HEADER` in
/// winnt.h, `coff_section` in LLVM's COFF.h).
final class _SectionHeader extends Struct {
  @Array(8)
  external Array<Uint8> name;
  @Uint32()
  external int virtualSize;
  @Uint32()
  external int virtualAddress;
  @Uint32()
  external int sizeOfRawData;
  @Uint32()
  external int pointerToRawData;
  @Uint32()
  external int pointerToRelocations;
  @Uint32()
  external int pointerToLinenumbers;
  @Uint16()
  external int numberOfRelocations;
  @Uint16()
  external int numberOfLinenumbers;
  @Uint32()
  external int characteristics;
}

final _sectionHeader = _StructReader(sizeOf<_SectionHeader>(),
    (data, offset) => Struct.create<_SectionHeader>(data, offset));

/// A procedure symbol, followed by its name (`PROCSYM32` in cvinfo.h).
@Packed(1)
final class _ProcSym extends Struct {
  @Uint32()
  external int parent;
  @Uint32()
  external int end;
  @Uint32()
  external int next;
  @Uint32()
  external int codeSize;
  @Uint32()
  external int dbgStart;
  @Uint32()
  external int dbgEnd;
  @Uint32()
  external int functionType;
  @Uint32()
  external int codeOffset;
  @Uint16()
  external int segment;
  @Uint8()
  external int flags;
}

final _procSym = _StructReader(sizeOf<_ProcSym>(),
    (data, offset) => Struct.create<_ProcSym>(data, offset));

/// A public symbol, followed by its name (`PUBSYM32` in cvinfo.h).
@Packed(1)
final class _PublicSym32 extends Struct {
  @Uint32()
  external int flags;
  @Uint32()
  external int offset;
  @Uint16()
  external int segment;
}

final _publicSym32 = _StructReader(sizeOf<_PublicSym32>(),
    (data, offset) => Struct.create<_PublicSym32>(data, offset));

/// An `S_INLINESITE` symbol, followed by the binary annotations of the call
/// (`INLINESITESYM` in cvinfo.h).
final class _InlineSiteSym extends Struct {
  @Uint32()
  external int parent;
  @Uint32()
  external int end;
  @Uint32()
  external int inlinee;
}

final _inlineSiteSym = _StructReader(sizeOf<_InlineSiteSym>(),
    (data, offset) => Struct.create<_InlineSiteSym>(data, offset));

/// An `S_INLINESITE2` symbol, followed by the binary annotations of the call
/// (`INLINESITESYM2` in cvinfo.h).
final class _InlineSiteSym2 extends Struct {
  @Uint32()
  external int parent;
  @Uint32()
  external int end;
  @Uint32()
  external int inlinee;
  @Uint32()
  external int invocations;
}

final _inlineSiteSym2 = _StructReader(sizeOf<_InlineSiteSym2>(),
    (data, offset) => Struct.create<_InlineSiteSym2>(data, offset));

/// An environment block symbol, followed by pairs of keys and values that end
/// with an empty key (`ENVBLOCKSYM` in cvinfo.h).
final class _EnvBlockSym extends Struct {
  @Uint8()
  external int flags;
}

final _envBlockSym = _StructReader(sizeOf<_EnvBlockSym>(),
    (data, offset) => Struct.create<_EnvBlockSym>(data, offset));

/// The header of a C13 debug subsection (`DebugSubsectionHeader` in LLVM's
/// DebugSubsection.h).
final class _DebugSubsectionHeader extends Struct {
  @Uint32()
  external int kind;
  @Uint32()
  external int length;
}

final _debugSubsectionHeader = _StructReader(sizeOf<_DebugSubsectionHeader>(),
    (data, offset) => Struct.create<_DebugSubsectionHeader>(data, offset));

/// The header of a `DEBUG_S_LINES` subsection, followed by line blocks
/// (`LineFragmentHeader` in LLVM's DebugLinesSubsection.h).
final class _LineFragmentHeader extends Struct {
  @Uint32()
  external int relocOffset;
  @Uint16()
  external int relocSegment;
  @Uint16()
  external int flags;
  @Uint32()
  external int codeSize;
}

final _lineFragmentHeader = _StructReader(sizeOf<_LineFragmentHeader>(),
    (data, offset) => Struct.create<_LineFragmentHeader>(data, offset));

/// The header of a line block, followed by its line entries and, if the
/// subsection has columns, by its column entries (`LineBlockFragmentHeader` in
/// LLVM's DebugLinesSubsection.h).
final class _LineBlockFragmentHeader extends Struct {
  /// The offset of the file checksum entry of the file of the block.
  @Uint32()
  external int nameIndex;
  @Uint32()
  external int numLines;
  @Uint32()
  external int blockSize;
}

final _lineBlockFragmentHeader = _StructReader(
    sizeOf<_LineBlockFragmentHeader>(),
    (data, offset) => Struct.create<_LineBlockFragmentHeader>(data, offset));

/// A line entry (`LineNumberEntry` in LLVM's DebugLinesSubsection.h,
/// `CV_Line_t` in cvinfo.h).
final class _LineNumberEntry extends Struct {
  @Uint32()
  external int offset;

  /// The line number, and whether the line is a statement.
  @Uint32()
  external int flags;
}

final _lineNumberEntry = _StructReader(sizeOf<_LineNumberEntry>(),
    (data, offset) => Struct.create<_LineNumberEntry>(data, offset));

/// A column entry (`ColumnNumberEntry` in LLVM's DebugLinesSubsection.h,
/// `CV_Column_t` in cvinfo.h).
final class _ColumnNumberEntry extends Struct {
  @Uint16()
  external int startColumn;
  @Uint16()
  external int endColumn;
}

final _columnNumberEntry = _StructReader(sizeOf<_ColumnNumberEntry>(),
    (data, offset) => Struct.create<_ColumnNumberEntry>(data, offset));

/// An entry of a `DEBUG_S_FILECHKSMS` subsection, followed by the checksum
/// and aligned to 4 bytes (`FileChecksumEntryHeader` in LLVM's
/// DebugChecksumsSubsection.h).
@Packed(1)
final class _FileChecksumEntryHeader extends Struct {
  /// The offset of the name of the file in the string table.
  @Uint32()
  external int fileNameOffset;
  @Uint8()
  external int checksumSize;
  @Uint8()
  external int checksumKind;
}

final _fileChecksumEntryHeader = _StructReader(
    sizeOf<_FileChecksumEntryHeader>(),
    (data, offset) => Struct.create<_FileChecksumEntryHeader>(data, offset));

/// An entry of a `DEBUG_S_INLINEELINES` subsection, followed by the extra
/// files of the inlined function if the subsection has them
/// (`InlineeSourceLineHeader` in LLVM's DebugInlineeLinesSubsection.h).
final class _InlineeSourceLineHeader extends Struct {
  @Uint32()
  external int inlinee;

  /// The offset of the file checksum entry of the file of the function.
  @Uint32()
  external int fileId;
  @Uint32()
  external int sourceLineNum;
}

final _inlineeSourceLineHeader = _StructReader(
    sizeOf<_InlineeSourceLineHeader>(),
    (data, offset) => Struct.create<_InlineeSourceLineHeader>(data, offset));

/// The streams of an MSF (multi-stream format) file, the container format
/// of PDB files.
class _MsfFile {
  static final _magic =
      ascii.encode('Microsoft C/C++ MSF 7.00\r\n\x1aDS\x00\x00\x00');
  static const _nilStreamSize = 0xffffffff;

  final Uint8List _bytes;
  final int _blockSize;

  /// The size and the blocks of each stream.
  final List<(int, List<int>)> _streams;

  _MsfFile._(this._bytes, this._blockSize, this._streams);

  static bool isMsfFile(Uint8List bytes) {
    if (bytes.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  static _MsfFile fromBytes(Uint8List bytes) {
    final superBlock = _Cursor(bytes).read(_superBlock);
    final blockSize = superBlock.blockSize;
    if (blockSize == 0 || blockSize & (blockSize - 1) != 0) {
      throw FormatException('Invalid MSF block size $blockSize');
    }
    final directorySize = superBlock.numDirectoryBytes;

    int blockCount(int size) => (size + blockSize - 1) ~/ blockSize;

    final blockMap = _Cursor(bytes, superBlock.blockMapAddr * blockSize);
    final directoryBlocks = [
      for (var i = 0; i < blockCount(directorySize); i++) blockMap.u32()
    ];
    final directory =
        _Cursor(_readBlocks(bytes, blockSize, directoryBlocks, directorySize));
    final streamCount = directory.u32();
    final sizes = <int>[];
    for (var i = 0; i < streamCount; i++) {
      final size = directory.u32();
      sizes.add(size == _nilStreamSize ? 0 : size);
    }
    final streams = [
      for (final size in sizes)
        (size, [for (var i = 0; i < blockCount(size); i++) directory.u32()]),
    ];
    return _MsfFile._(bytes, blockSize, streams);
  }

  /// Returns the contents of the stream with the given [index], which are
  /// only copied if its blocks aren't contiguous.
  Uint8List stream(int index) {
    final (size, blocks) = _streams[index];
    return _readBlocks(_bytes, _blockSize, blocks, size);
  }

  static Uint8List _readBlocks(
      Uint8List bytes, int blockSize, List<int> blocks, int size) {
    if (blocks.isEmpty) return Uint8List(0);
    var contiguous = true;
    for (var i = 1; i < blocks.length && contiguous; i++) {
      contiguous = blocks[i] == blocks[i - 1] + 1;
    }
    final first = blocks.first * blockSize;
    if (contiguous) return Uint8List.sublistView(bytes, first, first + size);
    final result = Uint8List(size);
    for (var i = 0; i < blocks.length; i++) {
      final start = blocks[i] * blockSize;
      final count = i == blocks.length - 1 ? size - i * blockSize : blockSize;
      result.setRange(i * blockSize, i * blockSize + count, bytes, start);
    }
    return result;
  }
}

// Indices of fixed streams.
const _pdbInfoStream = 1;
const _dbiStream = 3;
const _ipiStream = 4;

// Index of the section header stream in the optional debug header of the DBI
// stream.
const _sectionHeaderStreamIndex = 5;

// Symbol record kinds.
const _sEnd = 0x0006;
const _sThunk32 = 0x1102;
const _sBlock32 = 0x1103;
const _sWith32 = 0x1104;
const _sLProc32 = 0x110f;
const _sGProc32 = 0x1110;
const _sPub32 = 0x110e;
const _sSepCode = 0x1132;
const _sEnvBlock = 0x113d;
const _sLProc32Id = 0x1146;
const _sGProc32Id = 0x1147;
const _sInlineSite = 0x114d;
const _sInlineSiteEnd = 0x114e;
const _sProcIdEnd = 0x114f;
const _sLProc32Dpc = 0x1155;
const _sLProc32DpcId = 0x1156;
const _sInlineSite2 = 0x115d;

// Type record kinds.
const _lfFuncId = 0x1601;
const _lfMFuncId = 0x1602;

// Debug subsection kinds.
const _debugSLines = 0xf2;
const _debugSFileChecksums = 0xf4;
const _debugSInlineeLines = 0xf6;
const _debugSIgnore = 0x80000000;

const _linesHaveColumns = 0x1;
const _lineNumberMask = 0x00ffffff;

// The signature of DEBUG_S_INLINEELINES subsections whose entries have extra
// files.
const _inlineeLinesSignatureExtraFiles = 0x1;

/// The location of the code in [start, end), where offsets are relative to
/// the start of the procedure.
class _LineEntry {
  final int start;
  int end;
  final String filename;
  final int line;
  final int column;

  _LineEntry(this.start, this.end, this.filename, this.line, this.column);
}

/// Returns the entry for the code at [offset] in [entries], which are sorted
/// by start and don't overlap.
_LineEntry? _lineEntryAt(List<_LineEntry> entries, int offset) {
  // The index of the first entry that starts after [offset].
  var low = 0;
  var high = entries.length;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (entries[middle].start <= offset) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  if (low == 0) return null;
  final entry = entries[low - 1];
  return offset < entry.end ? entry : null;
}

/// A call to an inlined function.
class _InlineSite {
  final String name;
  final List<_LineEntry> lines;
  final List<_InlineSite> children = [];

  _InlineSite(this.name, this.lines);

  bool contains(int offset) => _lineEntryAt(lines, offset) != null;
}

class _Procedure {
  final String name;
  final int segment;
  final int offset;
  final int size;

  /// Whether this is a local procedure. Functions that are invisible in stack
  /// traces are emitted as local procedures.
  final bool isLocal;
  final List<_InlineSite> inlineSites = [];
  final List<_LineEntry> lines = [];

  /// The relative virtual address of the procedure, set once the section
  /// headers are known.
  int start = 0;

  _Procedure(this.name, this.segment, this.offset, this.size, this.isLocal);
}

/// The raw data of a call to an inlined function, which needs the file
/// checksums and inlinee lines of its module to be decoded.
class _RawInlineSite {
  final int inlinee;
  final Uint8List annotations;
  final List<_RawInlineSite> children = [];

  _RawInlineSite(this.inlinee, this.annotations);
}

int _decodeSigned(int value) => value & 1 != 0 ? -(value >> 1) : value >> 1;

// The name of the module of the linker, whose environment block has the
// working directory of the link.
const _linkerModuleName = '* Linker *';

// A Dart URI made absolute by LLD with an unknown working directory.
final _absolutizedUriRE = RegExp(r'[\\/]((?:dart|package):[^\\/].*)$');

/// Returns the original name of a file, undoing changes by linkers.
///
/// LLD makes file names that look relative absolute by prepending the working
/// directory of the link [cwd] and using backslashes, which turns URIs like
/// `dart:core/list.dart` into `<cwd>\dart:core\list.dart`, and relative paths
/// from `--resolve-dwarf-paths` like `sdk/lib/core/list.dart` into
/// `<cwd>\sdk\lib\core\list.dart`. The names in snapshots never contain
/// backslashes.
String _originalFilename(String name, String? cwd) {
  if (cwd != null && cwd.isNotEmpty) {
    final prefix = cwd.endsWith(r'\') ? cwd : '$cwd\\';
    if (name.startsWith(prefix)) {
      return name.substring(prefix.length).replaceAll(r'\', '/');
    }
  }
  final match = _absolutizedUriRE.firstMatch(name);
  if (match == null) return name;
  return match[1]!.replaceAll(r'\', '/');
}

/// The debugging information in a PDB file.
///
/// The PDB is expected to be linked from a PE/COFF snapshot, whose CodeView
/// debugging information has a procedure per Code object with the calls to
/// inlined functions as inline sites, and where functions that are invisible
/// in stack traces are local procedures.
class Pdb extends Dwarf {
  final String _buildId;
  final List<_Procedure> _procedures;
  final int? _isolateStart;
  final int _moduleCount;

  Pdb._(this._buildId, this._procedures, this._isolateStart, this._moduleCount);

  /// Whether [reader] contains a PDB file.
  static bool isPdb(Reader reader) => _MsfFile.isMsfFile(reader.bytes);

  /// Reads the PDB file in [reader]. Returns null if it is not a PDB file, or
  /// if it is malformed.
  static Pdb? fromReader(Reader reader) {
    if (!isPdb(reader)) return null;
    try {
      return _read(_MsfFile.fromBytes(reader.bytes));
    } on RangeError {
      return null;
    } on FormatException {
      return null;
    }
  }

  static Pdb _read(_MsfFile msf) {
    // The PDB info stream.
    final info = _Cursor(msf.stream(_pdbInfoStream));
    final infoHeader = info.read(_pdbStreamHeader);
    final namesStream = _namedStreams(info)['/names'];
    final names =
        namesStream != null ? _StringTable(msf.stream(namesStream)) : null;

    final inlineeNames = _functionIdNames(msf.stream(_ipiStream));

    // The DBI stream.
    final dbi = _Cursor(msf.stream(_dbiStream));
    final dbiHeader = dbi.read(_dbiStreamHeader);
    // The age in the DBI stream is the one in the CodeView record of the PE
    // image, while tools that rewrite the PDB can bump the age in the PDB info
    // stream.
    final age = dbiHeader.age != 0 ? dbiHeader.age : infoHeader.age;

    final modules = <({String name, _ModuleInfoHeader header})>[];
    final moduleInfoStart = dbi.offset;
    while (dbi.offset < moduleInfoStart + dbiHeader.modiSubstreamSize) {
      final header = dbi.read(_moduleInfoHeader);
      final name = dbi.string();
      dbi.string(); // Object file name.
      dbi.align(4, base: moduleInfoStart);
      modules.add((name: name, header: header));
    }

    String? cwd;
    for (final (:name, :header) in modules) {
      if (name == _linkerModuleName && header.moduleSymStream != 0xffff) {
        cwd = _workingDirectory(
            msf.stream(header.moduleSymStream), header.symBytes);
      }
    }

    final procedures = <_Procedure>[];
    for (final (name: _, :header) in modules) {
      if (header.moduleSymStream == 0xffff) continue;
      procedures.addAll(_readModule(msf.stream(header.moduleSymStream), header,
          names, inlineeNames, cwd));
    }

    // The section headers, from the optional debug header.
    dbi.offset = moduleInfoStart +
        dbiHeader.modiSubstreamSize +
        dbiHeader.secContrSubstreamSize +
        dbiHeader.sectionMapSize +
        dbiHeader.fileInfoSize +
        dbiHeader.typeServerSize +
        dbiHeader.ecSubstreamSize;
    final debugStreams = [
      for (var i = 0; i < dbiHeader.optionalDbgHdrSize ~/ 2; i++) dbi.u16()
    ];
    final sectionAddresses = <int>[];
    if (debugStreams.length > _sectionHeaderStreamIndex &&
        debugStreams[_sectionHeaderStreamIndex] != 0xffff) {
      final sections =
          _Cursor(msf.stream(debugStreams[_sectionHeaderStreamIndex]));
      while (sections.offset + _sectionHeader.size <= sections.length) {
        sectionAddresses.add(sections.read(_sectionHeader).virtualAddress);
      }
    }
    int? relativeVirtualAddress(int segment, int offset) =>
        segment >= 1 && segment <= sectionAddresses.length
            ? sectionAddresses[segment - 1] + offset
            : null;

    for (final procedure in procedures) {
      procedure.start =
          relativeVirtualAddress(procedure.segment, procedure.offset) ?? -1;
    }
    procedures.removeWhere((p) => p.start < 0);
    procedures.sort((a, b) => a.start.compareTo(b.start));

    // The start of the isolate instructions, from the public symbols. Like
    // the ELF and Mach-O readers, falls back to the old symbol name.
    int? textStart;
    int? oldIsolateStart;
    if (dbiHeader.symRecordStreamIndex != 0xffff) {
      final symbols = _Cursor(msf.stream(dbiHeader.symRecordStreamIndex));
      while (symbols.offset + _recordPrefix.size <= symbols.length) {
        final (kind, end) = symbols.recordPrefix();
        if (kind == _sPub32) {
          final symbol = symbols.read(_publicSym32);
          final name = symbols.string();
          if (name == constants.textSymbolName) {
            textStart = relativeVirtualAddress(symbol.segment, symbol.offset);
          } else if (name == constants.oldIsolateSymbolName) {
            oldIsolateStart =
                relativeVirtualAddress(symbol.segment, symbol.offset);
          }
        }
        symbols.offset = end;
      }
    }

    return Pdb._(_buildIdOf(infoHeader.guid, age), procedures,
        textStart ?? oldIsolateStart, modules.length);
  }

  /// Returns the build ID of the PE images linked with the PDB with the
  /// [guid] and [age], formatted like the VM does: like in the paths of symbol
  /// servers, where the first three fields of the GUID and the age are
  /// integers.
  static String _buildIdOf(_Guid guid, int age) {
    String hex(int value, int digits) =>
        value.toRadixString(16).padLeft(digits, '0');
    return [
      hex(guid.data1, 8),
      hex(guid.data2, 4),
      hex(guid.data3, 4),
      for (var i = 0; i < 8; i++) hex(guid.data4[i], 2),
      age.toRadixString(16),
    ].join();
  }

  /// Returns the working directory in the environment block of the symbols
  /// of the linker module.
  static String? _workingDirectory(Uint8List stream, int symbolsSize) {
    final symbols = _Cursor(stream, 4); // Skip the signature.
    while (symbols.offset + _recordPrefix.size <= symbolsSize) {
      final (kind, end) = symbols.recordPrefix();
      if (kind == _sEnvBlock) {
        symbols.read(_envBlockSym);
        // Pairs of keys and values, ending with an empty key.
        while (symbols.offset < end) {
          final key = symbols.string();
          if (key.isEmpty) break;
          final value = symbols.string();
          if (key == 'cwd') return value;
        }
      }
      symbols.offset = end;
    }
    return null;
  }

  /// Reads the named stream map of the PDB info stream.
  static Map<String, int> _namedStreams(_Cursor info) {
    final stringsSize = info.u32();
    final stringsStart = info.offset;
    info.offset += stringsSize;
    final size = info.u32();
    final capacity = info.u32();
    List<int> readBitVector() => [
          for (var i = info.u32(); i > 0; i--) info.u32(),
        ];
    final present = readBitVector();
    readBitVector(); // Deleted.
    final result = <String, int>{};
    for (var i = 0; i < capacity && result.length < size; i++) {
      if (i ~/ 32 >= present.length || present[i ~/ 32] & (1 << i % 32) == 0) {
        continue;
      }
      final nameOffset = info.u32();
      final stream = info.u32();
      final position = info.offset;
      info.offset = stringsStart + nameOffset;
      result[info.string()] = stream;
      info.offset = position;
    }
    return result;
  }

  /// Returns the names of the function IDs in the IPI stream.
  static Map<int, String> _functionIdNames(Uint8List stream) {
    final result = <int, String>{};
    if (stream.isEmpty) return result;
    final ipi = _Cursor(stream);
    final header = ipi.read(_tpiStreamHeader);
    ipi.offset = header.headerSize;
    var index = header.typeIndexBegin;
    while (ipi.offset + _recordPrefix.size <= ipi.length) {
      final (kind, end) = ipi.recordPrefix();
      if (kind == _lfFuncId || kind == _lfMFuncId) {
        ipi.read(_funcIdRecord);
        result[index] = ipi.string();
      }
      ipi.offset = end;
      index++;
    }
    return result;
  }

  static List<_Procedure> _readModule(
      Uint8List stream,
      _ModuleInfoHeader module,
      _StringTable? names,
      Map<int, String> inlineeNames,
      String? cwd) {
    // The symbols, with the inline sites of each procedure.
    final procedures = <_Procedure>[];
    final rawInlineSites = <_Procedure, List<_RawInlineSite>>{};
    final symbols = _Cursor(stream, 4); // Skip the signature.
    // The open scopes: procedures, inline sites, and other scopes (null).
    final scopes = <Object?>[];
    while (symbols.offset + _recordPrefix.size <= module.symBytes) {
      final (kind, end) = symbols.recordPrefix();
      switch (kind) {
        case _sGProc32 || _sLProc32 || _sGProc32Id || _sLProc32Id:
          final symbol = symbols.read(_procSym);
          final procedure = _Procedure(
              symbols.string(),
              symbol.segment,
              symbol.codeOffset,
              symbol.codeSize,
              kind == _sLProc32 || kind == _sLProc32Id);
          procedures.add(procedure);
          rawInlineSites[procedure] = [];
          scopes.add(procedure);
        case _sInlineSite || _sInlineSite2:
          final inlinee = kind == _sInlineSite
              ? symbols.read(_inlineSiteSym).inlinee
              : symbols.read(_inlineSiteSym2).inlinee;
          final site =
              _RawInlineSite(inlinee, symbols.bytes(end - symbols.offset));
          final parent = scopes.lastWhere(
              (s) => s is _Procedure || s is _RawInlineSite,
              orElse: () => null);
          if (parent is _RawInlineSite) {
            parent.children.add(site);
          } else if (parent is _Procedure) {
            rawInlineSites[parent]!.add(site);
          }
          scopes.add(site);
        // Other symbols that open scopes ended by S_END, like procedures of
        // other producers.
        case _sThunk32 ||
              _sBlock32 ||
              _sWith32 ||
              _sSepCode ||
              _sLProc32Dpc ||
              _sLProc32DpcId:
          scopes.add(null);
        case _sEnd || _sProcIdEnd || _sInlineSiteEnd:
          if (scopes.isNotEmpty) scopes.removeLast();
      }
      symbols.offset = end;
    }

    // The C13 debug subsections.
    final fileChecksums = <int, String>{};
    final inlineeLines = <int, (int, int)>{};
    final lineSubsections = <Uint8List>[];
    final subsections = _Cursor(stream, module.symBytes + module.c11Bytes);
    final subsectionsEnd = subsections.offset + module.c13Bytes;
    while (subsections.offset + _debugSubsectionHeader.size <= subsectionsEnd) {
      final header = subsections.read(_debugSubsectionHeader);
      final contents = subsections.bytes(header.length);
      subsections.align(4);
      if (header.kind & _debugSIgnore != 0) continue;
      switch (header.kind) {
        case _debugSLines:
          lineSubsections.add(contents);
        case _debugSFileChecksums:
          final checksums = _Cursor(contents);
          while (checksums.offset + _fileChecksumEntryHeader.size <=
              checksums.length) {
            final offset = checksums.offset;
            final entry = checksums.read(_fileChecksumEntryHeader);
            checksums.offset += entry.checksumSize;
            checksums.align(4);
            final name = names?.at(entry.fileNameOffset);
            fileChecksums[offset] =
                name != null ? _originalFilename(name, cwd) : '<unknown file>';
          }
        case _debugSInlineeLines:
          final lines = _Cursor(contents);
          final hasExtraFiles = lines.u32() == _inlineeLinesSignatureExtraFiles;
          while (lines.offset + _inlineeSourceLineHeader.size <= lines.length) {
            final entry = lines.read(_inlineeSourceLineHeader);
            // As in LLVM, the first entry is used if the linker merged the
            // IDs of different inlined functions.
            inlineeLines.putIfAbsent(
                entry.inlinee, () => (entry.fileId, entry.sourceLineNum));
            if (hasExtraFiles) {
              final extraFileCount = lines.u32();
              lines.offset += 4 * extraFileCount;
            }
          }
      }
    }
    String filename(int checksumOffset) =>
        fileChecksums[checksumOffset] ?? '<unknown file>';

    // The line tables of the procedures.
    final proceduresByAddress = {
      for (final p in procedures) (p.segment, p.offset): p,
    };
    for (final contents in lineSubsections) {
      final lines = _Cursor(contents);
      final header = lines.read(_lineFragmentHeader);
      final procedure =
          proceduresByAddress[(header.relocSegment, header.relocOffset)];
      if (procedure == null) continue;
      final hasColumns = header.flags & _linesHaveColumns != 0;
      while (lines.offset + _lineBlockFragmentHeader.size <= lines.length) {
        final block = lines.read(_lineBlockFragmentHeader);
        final file = filename(block.nameIndex);
        final entries = [
          for (var i = 0; i < block.numLines; i++) lines.read(_lineNumberEntry)
        ];
        final columns = [
          if (hasColumns)
            for (var i = 0; i < block.numLines; i++)
              lines.read(_columnNumberEntry)
        ];
        for (var i = 0; i < entries.length; i++) {
          procedure.lines.add(_LineEntry(
              entries[i].offset,
              header.codeSize,
              file,
              entries[i].flags & _lineNumberMask,
              hasColumns ? columns[i].startColumn : 0));
        }
      }
      // Sorts stably, so that of the entries at the same offset, the last one
      // in the line table covers the code.
      final sorted = procedure.lines.indexed.toList()
        ..sort((a, b) {
          final byStart = a.$2.start.compareTo(b.$2.start);
          return byStart != 0 ? byStart : a.$1.compareTo(b.$1);
        });
      procedure.lines
        ..clear()
        ..addAll(sorted.map((e) => e.$2));
      for (var i = 0; i < procedure.lines.length - 1; i++) {
        procedure.lines[i].end = procedure.lines[i + 1].start;
      }
    }

    // The inline sites, whose binary annotations are decoded now that the
    // file checksums and inlinee lines are known.
    _InlineSite decode(_RawInlineSite raw) {
      final (fileId, startLine) = inlineeLines[raw.inlinee] ?? (-1, 0);
      final site = _InlineSite(
          inlineeNames[raw.inlinee] ?? '<unknown>',
          _decodeAnnotations(
              raw.annotations, filename(fileId), startLine, filename));
      site.children.addAll(raw.children.map(decode));
      return site;
    }

    for (final procedure in procedures) {
      procedure.inlineSites.addAll(rawInlineSites[procedure]!.map(decode));
    }
    return procedures;
  }

  /// Decodes the binary annotations of an inline site into the locations of
  /// its code.
  static List<_LineEntry> _decodeAnnotations(Uint8List annotations,
      String startFilename, int startLine, String Function(int) filename) {
    final cursor = _Cursor(annotations);
    int? read() {
      if (cursor.done) return null;
      final first = cursor.u8();
      if (first & 0x80 == 0) return first;
      if (first & 0xc0 == 0x80) {
        if (cursor.done) return null;
        return (first & 0x3f) << 8 | cursor.u8();
      }
      if (first & 0xe0 == 0xc0) {
        if (cursor.offset + 3 > cursor.length) return null;
        return (first & 0x1f) << 24 |
            cursor.u8() << 16 |
            cursor.u8() << 8 |
            cursor.u8();
      }
      return null;
    }

    final entries = <_LineEntry>[];
    var codeOffset = 0;
    var file = startFilename;
    var line = startLine;
    var column = 0;
    // Starts the code of a new entry at the current code offset, which ends
    // the previous one unless it has an explicit length.
    void startEntry() {
      if (entries.isNotEmpty && entries.last.end < 0) {
        entries.last.end = codeOffset;
      }
      entries.add(_LineEntry(codeOffset, -1, file, line, column));
    }

    // Ends the code of the current entry after [length] bytes.
    void setLength(int length) {
      if (entries.isEmpty) return;
      entries.last.end = entries.last.start + length;
      codeOffset = entries.last.end;
    }

    decoding:
    while (true) {
      final opcode = read();
      if (opcode == null || opcode == 0) break;
      final operand = read();
      if (operand == null) break;
      switch (opcode) {
        case 1: // CodeOffset
          codeOffset = operand;
          startEntry();
        case 2 || 3: // ChangeCodeOffsetBase, ChangeCodeOffset
          codeOffset += operand;
          startEntry();
        case 4: // ChangeCodeLength
          setLength(operand);
        case 5: // ChangeFile
          file = filename(operand);
        case 6: // ChangeLineOffset
          line += _decodeSigned(operand);
        case 9: // ChangeColumnStart
          column = operand;
        case 11: // ChangeCodeOffsetAndLineOffset
          line += _decodeSigned(operand >> 4);
          codeOffset += operand & 0xf;
          startEntry();
        case 12: // ChangeCodeLengthAndCodeOffset
          final delta = read();
          if (delta == null) break decoding;
          codeOffset += delta;
          startEntry();
          setLength(operand);
        // ChangeLineEndDelta, ChangeRangeKind, ChangeColumnEndDelta and
        // ChangeColumnEnd don't affect the start locations.
      }
    }
    entries.removeWhere((e) => e.end < 0);
    // _lineEntryAt needs the entries sorted. Code offsets only grow, except
    // with CodeOffset, which can set any offset.
    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  @override
  String? buildId([String? arch]) => _buildId;

  @override
  int? vmStartAddress([String? arch]) => null;

  @override
  int? isolateStartAddress([String? arch]) => _isolateStart;

  _Procedure? _procedureAt(int address) {
    var low = 0;
    var high = _procedures.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final procedure = _procedures[mid];
      if (address < procedure.start) {
        high = mid - 1;
      } else if (address >= procedure.start + procedure.size) {
        low = mid + 1;
      } else {
        return procedure;
      }
    }
    return null;
  }

  List<CallInfo>? _callInfoFor(int address) {
    final procedure = _procedureAt(address);
    if (procedure == null) return null;
    final offset = address - procedure.start;
    if (procedure.lines.isEmpty) {
      return [StubCallInfo(name: procedure.name, offset: offset)];
    }

    // The calls to inlined functions containing the address, outermost first.
    final sites = <_InlineSite>[];
    var candidates = procedure.inlineSites;
    while (true) {
      final site = candidates.where((s) => s.contains(offset)).firstOrNull;
      if (site == null) break;
      sites.add(site);
      candidates = site.children;
    }

    DartCallInfo callInfo(String function, List<_LineEntry> lines,
        {required bool inlined, required bool internal}) {
      final entry = _lineEntryAt(lines, offset);
      return DartCallInfo(
          function: function,
          inlined: inlined,
          internal: internal,
          filename: entry?.filename ?? lines.first.filename,
          line: entry?.line ?? 0,
          column: entry?.column ?? 0);
    }

    return [
      for (final site in sites.reversed)
        callInfo(site.name, site.lines, inlined: true, internal: false),
      callInfo(procedure.name, procedure.lines,
          inlined: false,
          // As for artificial DWARF subprograms, don't hide invisible
          // functions at their start, which appear as Future listeners.
          internal: procedure.isLocal && (sites.isNotEmpty || offset != 0)),
    ];
  }

  @override
  Iterable<CallInfo>? callInfoForPCOffset(PCOffset pcOffset,
      {bool includeInternalFrames = false}) {
    final calls = _callInfoFor(virtualAddressOf(pcOffset));
    if (!includeInternalFrames) {
      return calls?.where((CallInfo c) => !c.isInternal);
    }
    return calls;
  }

  @override
  int virtualAddressOf(PCOffset pcOffset) {
    switch (pcOffset.section) {
      case InstructionsSection.none:
        // This address is already virtualized, so we don't need to change it.
        return pcOffset.offset;
      case InstructionsSection.vm:
        throw 'Cannot locate VM instructions section in PDB';
      case InstructionsSection.isolate:
        final isolateStart = isolateStartAddress(pcOffset.architecture);
        if (isolateStart == null) {
          throw 'Cannot locate isolate instructions section in PDB';
        }
        return pcOffset.offset + isolateStart;
    }
  }

  @override
  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..writeln('PDB file')
      ..writeln('  Build ID: ${buildId()}')
      ..writeln('  Modules: $_moduleCount')
      ..writeln('  Procedures: ${_procedures.length}');
    if (_isolateStart != null) {
      buffer.writeln('  Isolate instructions: '
          '0x${_isolateStart.toRadixString(16)}');
    }
  }

  @override
  String dumpFileInfo() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    for (final procedure in _procedures) {
      buffer
        ..write('  0x')
        ..write(procedure.start.toRadixString(16))
        ..write(' ')
        ..write(procedure.size)
        ..write(' ')
        ..writeln(procedure.name);
    }
    return buffer.toString();
  }
}

/// The string table in the /names stream.
class _StringTable {
  final Uint8List _strings;

  _StringTable._(this._strings);

  factory _StringTable(Uint8List stream) {
    final cursor = _Cursor(stream);
    final header = cursor.read(_stringTableHeader);
    return _StringTable._(cursor.bytes(header.byteSize));
  }

  String? at(int offset) =>
      offset < _strings.length ? _Cursor(_strings, offset).string() : null;
}
