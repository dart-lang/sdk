// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_COFF_H_
#define RUNTIME_PLATFORM_COFF_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)

namespace dart {
namespace coff {

#pragma pack(push, 1)

// -----------------------------------------------------------------------------
// PE/COFF file format constants and structures
//
// Reference: Microsoft PE/COFF specification (winnt.h definitions). This
// header contains the minimum subset required by the COFF object writer used
// by gen_snapshot.
// -----------------------------------------------------------------------------

// File header machine values (we only support x64 here).
static constexpr uint16_t PE_FILE_MACHINE_UNKNOWN = 0x0000;
static constexpr uint16_t PE_FILE_MACHINE_AMD64 = 0x8664;

// PE_FILE_HEADER.Characteristics flags.
static constexpr uint16_t PE_FILE_RELOCS_STRIPPED = 0x0001;
static constexpr uint16_t PE_FILE_EXECUTABLE_IMAGE = 0x0002;
static constexpr uint16_t PE_FILE_LINE_NUMS_STRIPPED = 0x0004;
static constexpr uint16_t PE_FILE_LARGE_ADDRESS_AWARE = 0x0020;

struct ImageFileHeader {
  uint16_t Machine;
  uint16_t NumberOfSections;
  uint32_t TimeDateStamp;
  uint32_t PointerToSymbolTable;
  uint32_t NumberOfSymbols;
  uint16_t SizeOfOptionalHeader;
  uint16_t Characteristics;
};

// PE_SECTION_HEADER.Characteristics flags (subset we use).
static constexpr uint32_t PE_SCN_CNT_CODE = 0x00000020;
static constexpr uint32_t PE_SCN_CNT_INITIALIZED_DATA = 0x00000040;
static constexpr uint32_t PE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080;
static constexpr uint32_t PE_SCN_LNK_INFO = 0x00000200;
static constexpr uint32_t PE_SCN_LNK_REMOVE = 0x00000800;
static constexpr uint32_t PE_SCN_LNK_COMDAT = 0x00001000;
static constexpr uint32_t PE_SCN_LNK_NRELOC_OVFL = 0x01000000;
static constexpr uint32_t PE_SCN_ALIGN_1BYTES = 0x00100000;
static constexpr uint32_t PE_SCN_ALIGN_2BYTES = 0x00200000;
static constexpr uint32_t PE_SCN_ALIGN_4BYTES = 0x00300000;
static constexpr uint32_t PE_SCN_ALIGN_8BYTES = 0x00400000;
static constexpr uint32_t PE_SCN_ALIGN_16BYTES = 0x00500000;
static constexpr uint32_t PE_SCN_ALIGN_32BYTES = 0x00600000;
static constexpr uint32_t PE_SCN_ALIGN_64BYTES = 0x00700000;
static constexpr uint32_t PE_SCN_ALIGN_MASK = 0x00F00000;
static constexpr uint32_t PE_SCN_MEM_DISCARDABLE = 0x02000000;
static constexpr uint32_t PE_SCN_MEM_NOT_CACHED = 0x04000000;
static constexpr uint32_t PE_SCN_MEM_NOT_PAGED = 0x08000000;
static constexpr uint32_t PE_SCN_MEM_SHARED = 0x10000000;
static constexpr uint32_t PE_SCN_MEM_EXECUTE = 0x20000000;
static constexpr uint32_t PE_SCN_MEM_READ = 0x40000000;
static constexpr uint32_t PE_SCN_MEM_WRITE = 0x80000000;

struct ImageSectionHeader {
  char Name[8];
  uint32_t VirtualSize;
  uint32_t VirtualAddress;
  uint32_t SizeOfRawData;
  uint32_t PointerToRawData;
  uint32_t PointerToRelocations;
  uint32_t PointerToLinenumbers;
  uint16_t NumberOfRelocations;
  uint16_t NumberOfLinenumbers;
  uint32_t Characteristics;
};

// Symbol storage classes.
static constexpr uint8_t PE_SYM_CLASS_NULL = 0;
static constexpr uint8_t PE_SYM_CLASS_EXTERNAL = 2;
static constexpr uint8_t PE_SYM_CLASS_STATIC = 3;
static constexpr uint8_t PE_SYM_CLASS_LABEL = 6;
static constexpr uint8_t PE_SYM_CLASS_FUNCTION = 101;
static constexpr uint8_t PE_SYM_CLASS_FILE = 103;
static constexpr uint8_t PE_SYM_CLASS_SECTION = 104;

// Symbol special section numbers.
static constexpr int16_t PE_SYM_UNDEFINED = 0;
static constexpr int16_t PE_SYM_ABSOLUTE = -1;
static constexpr int16_t PE_SYM_DEBUG = -2;

// Symbol base types.
static constexpr uint16_t PE_SYM_TYPE_NULL = 0x0000;
// Microsoft tooling expects function symbols to have DT_FUNCTION in the high
// byte of the Type field, regardless of base type. The full value commonly
// emitted is 0x20.
static constexpr uint16_t PE_SYM_DTYPE_FUNCTION = 0x0020;

struct ImageSymbol {
  union {
    char ShortName[8];
    struct {
      uint32_t Zeroes;  // 0 means use string table offset.
      uint32_t Offset;  // Offset into string table.
    } LongName;
  } N;
  int32_t Value;
  int16_t SectionNumber;
  uint16_t Type;
  uint8_t StorageClass;
  uint8_t NumberOfAuxSymbols;
};

// Auxiliary symbol record for PE_SYM_CLASS_STATIC section symbols.
struct ImageAuxSymbolSection {
  uint32_t Length;
  uint16_t NumberOfRelocations;
  uint16_t NumberOfLinenumbers;
  uint32_t CheckSum;
  int16_t Number;
  uint8_t Selection;
  uint8_t Reserved[3];
};

// Auxiliary symbol record for PE_SYM_CLASS_EXTERNAL function symbols.
struct ImageAuxSymbolFuncDef {
  uint32_t TagIndex;
  uint32_t TotalSize;
  uint32_t PointerToLinenumber;
  uint32_t PointerToNextFunction;
  uint16_t Unused;
};

// Relocation record.
struct ImageRelocation {
  uint32_t VirtualAddress;
  uint32_t SymbolTableIndex;
  uint16_t Type;
};

// x64 relocation types we use.
static constexpr uint16_t PE_REL_AMD64_ABSOLUTE = 0x0000;
static constexpr uint16_t PE_REL_AMD64_ADDR64 = 0x0001;
static constexpr uint16_t PE_REL_AMD64_ADDR32 = 0x0002;
static constexpr uint16_t PE_REL_AMD64_ADDR32NB = 0x0003;
static constexpr uint16_t PE_REL_AMD64_REL32 = 0x0004;
static constexpr uint16_t PE_REL_AMD64_REL32_1 = 0x0005;
static constexpr uint16_t PE_REL_AMD64_REL32_2 = 0x0006;
static constexpr uint16_t PE_REL_AMD64_REL32_3 = 0x0007;
static constexpr uint16_t PE_REL_AMD64_REL32_4 = 0x0008;
static constexpr uint16_t PE_REL_AMD64_REL32_5 = 0x0009;
static constexpr uint16_t PE_REL_AMD64_SECTION = 0x000A;
static constexpr uint16_t PE_REL_AMD64_SECREL = 0x000B;

// -----------------------------------------------------------------------------
// SEH / unwind info (x64)
//
// Locally redeclared to avoid pulling in runtime/platform/unwinding_records.h,
// which is built for the JIT and not appropriate for inclusion from the
// snapshot writer.
// -----------------------------------------------------------------------------

static constexpr uint8_t kUnwindVersion = 1;

// UNWIND_OP_CODES (subset).
enum UnwindOpCode : uint8_t {
  UWOP_PUSH_NONVOL = 0,
  UWOP_ALLOC_LARGE = 1,
  UWOP_ALLOC_SMALL = 2,
  UWOP_SET_FPREG = 3,
  UWOP_SAVE_NONVOL = 4,
  UWOP_SAVE_NONVOL_FAR = 5,
  UWOP_SAVE_XMM128 = 8,
  UWOP_SAVE_XMM128_FAR = 9,
  UWOP_PUSH_MACHFRAME = 10,
};

// Register encodings for unwind ops.
static constexpr uint8_t kRegRax = 0;
static constexpr uint8_t kRegRcx = 1;
static constexpr uint8_t kRegRdx = 2;
static constexpr uint8_t kRegRbx = 3;
static constexpr uint8_t kRegRsp = 4;
static constexpr uint8_t kRegRbp = 5;
static constexpr uint8_t kRegRsi = 6;
static constexpr uint8_t kRegRdi = 7;

struct UnwindCode {
  uint8_t CodeOffset;
  uint8_t UnwindOp : 4;
  uint8_t OpInfo : 4;
};

struct UnwindInfoHeader {
  uint8_t Version : 3;
  uint8_t Flags : 5;
  uint8_t SizeOfProlog;
  uint8_t CountOfCodes;
  uint8_t FrameRegister : 4;
  uint8_t FrameOffset : 4;
};

struct RuntimeFunction {
  uint32_t BeginAddress;
  uint32_t EndAddress;
  uint32_t UnwindData;
};

// -----------------------------------------------------------------------------
// CodeView debug records (MSVC PDB-compatible).
//
// Reference: Microsoft cvinfo.h, LLVM include/llvm/DebugInfo/CodeView. We
// declare only what the writer emits.
// -----------------------------------------------------------------------------

// .debug$S leading signature.
static constexpr uint32_t CV_SIGNATURE_C13 = 4;

// Debug subsection kinds.
static constexpr uint32_t DEBUG_S_SYMBOLS = 0xF1;
static constexpr uint32_t DEBUG_S_LINES = 0xF2;
static constexpr uint32_t DEBUG_S_STRINGTABLE = 0xF3;
static constexpr uint32_t DEBUG_S_FILECHKSMS = 0xF4;
static constexpr uint32_t DEBUG_S_INLINEELINES = 0xF6;

// File checksum kinds.
static constexpr uint8_t CHKSUM_TYPE_NONE = 0;
static constexpr uint8_t CHKSUM_TYPE_MD5 = 1;
static constexpr uint8_t CHKSUM_TYPE_SHA1 = 2;
static constexpr uint8_t CHKSUM_TYPE_SHA256 = 3;

// Symbol record kinds (subset).
static constexpr uint16_t S_END = 0x0006;
static constexpr uint16_t S_FRAMEPROC = 0x1012;
static constexpr uint16_t S_OBJNAME = 0x1101;
static constexpr uint16_t S_BLOCK32 = 0x1103;
static constexpr uint16_t S_COMPILE2 = 0x1116;
static constexpr uint16_t S_GPROC32 = 0x1110;
static constexpr uint16_t S_LPROC32 = 0x110F;
static constexpr uint16_t S_COMPILE3 = 0x113C;
static constexpr uint16_t S_GPROC32_ID = 0x1147;
static constexpr uint16_t S_LPROC32_ID = 0x1146;
static constexpr uint16_t S_PROC_ID_END = 0x114F;

// Type record kinds (subset).
static constexpr uint16_t LF_POINTER = 0x1002;
static constexpr uint16_t LF_PROCEDURE = 0x1008;
static constexpr uint16_t LF_ARGLIST = 0x1201;
static constexpr uint16_t LF_FUNC_ID = 0x1601;
static constexpr uint16_t LF_STRING_ID = 0x1605;

// Primitive type indices used by us.
static constexpr uint32_t T_VOID = 0x0003;
static constexpr uint32_t T_NOTYPE = 0x0000;

// Calling conventions.
static constexpr uint8_t CV_CALL_NEAR_C = 0x00;

// Language for S_COMPILE3 (we use CV_CFL_C as a closest reasonable proxy for
// Dart-AOT generated code).
static constexpr uint8_t CV_CFL_C = 0x00;
static constexpr uint8_t CV_CFL_CXX = 0x01;
static constexpr uint8_t CV_CFL_RUST = 0x15;

// Machine for S_COMPILE3.
static constexpr uint16_t CV_CFL_X64 = 0xD0;

// Subsection (kind/size) header. Each subsection in .debug$S starts with this
// followed by `length` bytes of payload, aligned to 4 on completion.
struct DebugSubsectionHeader {
  uint32_t Kind;    // DEBUG_S_*
  uint32_t Length;  // size of payload (not including header)
};

// Per-function block at the start of a DEBUG_S_LINES payload.
struct CvLineSectionHeader {
  uint32_t Offset;    // SECREL relocation target
  uint16_t Section;   // SECTION relocation target (1-based section index)
  uint16_t Flags;     // 0 (no columns) or 1 (with columns)
  uint32_t CodeSize;  // length of code described by this block
};

// Header for a contiguous line block within a function (one per source file).
struct CvLineBlockHeader {
  uint32_t NameIndex;  // offset into file checksum subsection
  uint32_t NumLines;
  uint32_t BlockSize;  // total bytes including this header
};

// Single line entry. `Flags` packs:
//   bits  0-23: line start
//   bits 24-30: delta line end
//   bit     31: is statement
struct CvLine {
  static constexpr uint32_t kLineMask = 0x00ffffffu;
  static constexpr uint32_t kIsStatementBit = 1u << 31;

  uint32_t Offset;  // byte offset from function start
  uint32_t Flags;
};

// File checksum entry header in a DEBUG_S_FILECHKSMS subsection.
struct CvFileChecksumHeader {
  uint32_t NameOffset;  // offset into DEBUG_S_STRINGTABLE
  uint8_t ChecksumSize;
  uint8_t ChecksumKind;  // CHKSUM_TYPE_*
  // Followed by `ChecksumSize` bytes, padded to 4-byte alignment.
};

// S_GPROC32_ID record (followed by null-terminated name).
struct ProcSym32 {
  uint16_t RecordLength;  // size of record excluding the length field itself
  uint16_t RecordKind;    // S_GPROC32_ID
  uint32_t Parent;        // 0
  uint32_t End;           // patched to point at matching S_PROC_ID_END
  uint32_t Next;          // 0
  uint32_t CodeSize;
  uint32_t DebugStart;    // 0
  uint32_t DebugEnd;      // 0
  uint32_t FunctionType;  // LF_FUNC_ID index
  uint32_t CodeOffset;    // patched by SECREL relocation
  uint16_t Segment;       // patched by SECTION relocation
  uint8_t Flags;
  // Followed by name (NUL-terminated).
};

// S_FRAMEPROC record.
struct FrameProcSym {
  uint16_t RecordLength;
  uint16_t RecordKind;  // S_FRAMEPROC
  uint32_t FrameSize;   // total frame
  uint32_t PaddingSize;
  uint32_t OffsetToPadding;
  uint32_t BytesOfCalleeSavedRegisters;
  uint32_t OffsetOfExceptionHandler;
  uint16_t SectionOfExceptionHandler;
  uint32_t Flags;
};

// S_COMPILE3 record (followed by null-terminated compiler name).
struct Compile3Sym {
  uint16_t RecordLength;
  uint16_t RecordKind;  // S_COMPILE3
  uint32_t Flags;       // low byte = language, high bytes = misc flags
  uint16_t Machine;     // CV_CFL_X64
  uint16_t FrontendMajor;
  uint16_t FrontendMinor;
  uint16_t FrontendBuild;
  uint16_t FrontendQFE;
  uint16_t BackendMajor;
  uint16_t BackendMinor;
  uint16_t BackendBuild;
  uint16_t BackendQFE;
  // Followed by VersionString (NUL-terminated).
};

// S_OBJNAME record (followed by null-terminated name).
struct ObjNameSym {
  uint16_t RecordLength;
  uint16_t RecordKind;  // S_OBJNAME
  uint32_t Signature;   // 0
  // Followed by name (NUL-terminated).
};

// LF_ARGLIST type record body.
struct ArgListType {
  uint16_t RecordLength;
  uint16_t RecordKind;  // LF_ARGLIST
  uint32_t Count;       // followed by `Count` uint32_t argument type indices
};

// LF_PROCEDURE type record.
struct ProcedureType {
  uint16_t RecordLength;
  uint16_t RecordKind;  // LF_PROCEDURE
  uint32_t ReturnType;
  uint8_t CallType;   // CV_CALL_NEAR_C
  uint8_t FuncAttrs;  // 0
  uint16_t ParameterCount;
  uint32_t ArgListType;
};

// LF_FUNC_ID type record (followed by NUL-terminated name).
struct FuncIdType {
  uint16_t RecordLength;
  uint16_t RecordKind;   // LF_FUNC_ID
  uint32_t ParentScope;  // 0
  uint32_t FunctionType;
  // Followed by Name (NUL-terminated).
};

// LF_STRING_ID type record (followed by NUL-terminated string).
struct StringIdType {
  uint16_t RecordLength;
  uint16_t RecordKind;  // LF_STRING_ID
  uint32_t Substring;   // 0
  // Followed by String (NUL-terminated).
};

#pragma pack(pop)

// -----------------------------------------------------------------------------
// Compile-time size assertions
// -----------------------------------------------------------------------------

static_assert(sizeof(ImageFileHeader) == 20, "PE/COFF file header layout");
static_assert(sizeof(ImageSectionHeader) == 40,
              "PE/COFF section header layout");
static_assert(sizeof(ImageSymbol) == 18, "PE/COFF symbol layout");
static_assert(sizeof(ImageAuxSymbolSection) == 18, "Aux section symbol layout");
static_assert(sizeof(ImageAuxSymbolFuncDef) == 18, "Aux funcdef layout");
static_assert(sizeof(ImageRelocation) == 10, "PE/COFF relocation layout");
static_assert(sizeof(UnwindInfoHeader) == 4, "Unwind info header layout");
static_assert(sizeof(UnwindCode) == 2, "Unwind code layout");
static_assert(sizeof(RuntimeFunction) == 12, "RUNTIME_FUNCTION layout");
static_assert(sizeof(DebugSubsectionHeader) == 8, "CodeView subsection header");
static_assert(sizeof(CvLineSectionHeader) == 12,
              "CodeView line section header");
static_assert(sizeof(CvLineBlockHeader) == 12, "CodeView line block header");
static_assert(sizeof(CvLine) == 8, "CodeView line entry");
static_assert(sizeof(CvFileChecksumHeader) == 6, "CodeView file checksum");
static_assert(sizeof(ProcSym32) == 39, "CodeView S_GPROC32_ID prefix");
// FrameProcSym is 30 bytes when packed-1 (2+2+4+4+4+4+4+2+4).  Microsoft's
// natural-aligned layout in cvinfo.h ends up at 32 bytes; the on-wire CodeView
// record is the packed 30-byte form, which is what gets emitted by our byte-
// stream helpers in codeview.cc.
static_assert(sizeof(FrameProcSym) == 30, "CodeView S_FRAMEPROC layout");
static_assert(sizeof(Compile3Sym) == 26, "CodeView S_COMPILE3 prefix");
static_assert(sizeof(ObjNameSym) == 8, "CodeView S_OBJNAME prefix");
static_assert(sizeof(ArgListType) == 8, "CodeView LF_ARGLIST prefix");
// ProcedureType: 2-byte RecordLength + 14-byte LF_PROCEDURE body = 16 bytes.
static_assert(sizeof(ProcedureType) == 16, "CodeView LF_PROCEDURE layout");
static_assert(sizeof(FuncIdType) == 12, "CodeView LF_FUNC_ID prefix");
static_assert(sizeof(StringIdType) == 8, "CodeView LF_STRING_ID prefix");

}  // namespace coff
}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_PLATFORM_COFF_H_
