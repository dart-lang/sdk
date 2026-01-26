// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_MACH_O_H_
#define RUNTIME_PLATFORM_MACH_O_H_

#include <platform/globals.h>

namespace dart {

namespace mach_o {

#pragma pack(push, 1)

typedef int cpu_type_t;
typedef int cpu_subtype_t;

// Mask for architecture variant bits.
static constexpr cpu_type_t CPU_ARCH_MASK = 0xff000000;
// CPU with a 64-bit ABI.
static constexpr cpu_type_t CPU_ARCH_ABI64 = 0x01000000;

// Fallback for architectures without more specific constants (e.g.,
// architectures like RISCV that MacOS doesn't run on natively).
static constexpr cpu_type_t CPU_TYPE_ANY = -1;
static constexpr cpu_subtype_t CPU_SUBTYPE_ANY = -1;

// x86-family CPUs.
static constexpr cpu_type_t CPU_TYPE_X86 = 7;
static constexpr cpu_type_t CPU_TYPE_I386 = CPU_TYPE_X86;
static constexpr cpu_type_t CPU_TYPE_X86_64 = CPU_TYPE_X86 | CPU_ARCH_ABI64;

// x86-family CPU subtypes.
constexpr cpu_subtype_t CPU_SUBTYPE_INTEL(uint8_t f, cpu_subtype_t m) {
  return f + (m << 4);
}
static constexpr cpu_subtype_t CPU_SUBTYPE_I386_ALL = CPU_SUBTYPE_INTEL(3, 0);
static constexpr cpu_subtype_t CPU_SUBTYPE_X86_ALL = CPU_SUBTYPE_I386_ALL;
static constexpr cpu_subtype_t CPU_SUBTYPE_X86_64_ALL = CPU_SUBTYPE_I386_ALL;

// ARM-family CPUs.
static constexpr cpu_type_t CPU_TYPE_ARM = 12;
static constexpr cpu_type_t CPU_TYPE_ARM64 = CPU_TYPE_ARM | CPU_ARCH_ABI64;

// ARM-family CPU subtypes.
static constexpr cpu_type_t CPU_SUBTYPE_ARM_ALL = 0;
static constexpr cpu_type_t CPU_SUBTYPE_ARM64_ALL = CPU_SUBTYPE_ARM_ALL;

typedef int vm_prot_t;

static constexpr vm_prot_t VM_PROT_NONE = 0x00;
static constexpr vm_prot_t VM_PROT_READ = 0x01;
static constexpr vm_prot_t VM_PROT_WRITE = 0x02;
static constexpr vm_prot_t VM_PROT_EXECUTE = 0x04;
static constexpr vm_prot_t VM_PROT_DEFAULT = (VM_PROT_READ | VM_PROT_WRITE);
static constexpr vm_prot_t VM_PROT_ALL =
    (VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);

struct mach_header {
  uint32_t magic;
  cpu_type_t cputype;
  cpu_subtype_t cpusubtype;
  uint32_t filetype;
  uint32_t ncmds;
  uint32_t sizeofcmds;
  uint32_t flags;
};

static constexpr uint32_t MH_MAGIC = 0xfeedface;
static constexpr uint32_t MH_CIGAM = 0xcefaedfe;

struct mach_header_64 {
  uint32_t magic;
  cpu_type_t cputype;
  cpu_subtype_t cpusubtype;
  uint32_t filetype;
  uint32_t ncmds;
  uint32_t sizeofcmds;
  uint32_t flags;
  uint32_t reserved;
};

static constexpr uint32_t MH_MAGIC_64 = 0xfeedfacf;
static constexpr uint32_t MH_CIGAM_64 = 0xcffaedfe;

// Filetypes for the Mach-O header.

// A relocatable object file that has all sections in a single unnamed segment.
static constexpr uint32_t MH_OBJECT = 0x1;
// A dynamically bound shared library.
static constexpr uint32_t MH_DYLIB = 0x6;
// An object file that only contains debugging information.
static constexpr uint32_t MH_DSYM = 0xa;

// Flag values for the Mach-O header.

// The object file has no undefined references.
static constexpr uint32_t MH_NOUNDEFS = 0x1;
// The object file is an appropriate input for the dynamic linker
// and cannot be statically link edited again.
static constexpr uint32_t MH_DYLDLINK = 0x4;
// The object file does not re-export any of its input dynamic
// libraries.
static constexpr uint32_t MH_NO_REEXPORTED_DYLIBS = 0x100000;

struct load_command {
  // The tag that specifies the load command for the following
  // bytes. One of the LC_* constants below.
  uint32_t cmd;
  // The total size of the load command, including cmd and cmdsize.
  uint32_t cmdsize;
};

// The description of the LC_* constants are followed by the name of
// the specific C structure describing their contents in parentheses.

// Flag stored in high bit for LC_* constants that denotes sections
// the dynamic linker must understand to properly load the library.
static constexpr uint32_t LC_REQ_DYLD = 0x80000000;

// A portion of the file that is mapped into memory when the
// object file is loaded. (segment_command)
static constexpr uint32_t LC_SEGMENT = 0x1;
// The static symbol table. (symtab_command)
static constexpr uint32_t LC_SYMTAB = 0x2;
// The dynamic symbol table. (dysymtab_command)
static constexpr uint32_t LC_DYSYMTAB = 0xb;
// A dynamic library that must be loaded to use this object file.
// (dylib_command)
static constexpr uint32_t LC_LOAD_DYLIB = 0xc;
// The identifier for this dynamic library (for MH_DYLIB files).
// (dylib_command)
static constexpr uint32_t LC_ID_DYLIB = 0xd;
// A 64-bit segment. (segment_command_64)
static constexpr uint32_t LC_SEGMENT_64 = 0x19;
// The UUID, used as a build identifier. (uuid_command)
static constexpr uint32_t LC_UUID = 0x1b;
static constexpr uint32_t LC_RPATH = (0x1c | LC_REQ_DYLD);
// The code signature which protects the preceding portion of the object file.
// Must be the last contents in the object file. (linkedit_data_command)
static constexpr uint32_t LC_CODE_SIGNATURE = 0x1d;
// Information about encrypted segments for 32-bit targets. Must also be present
// for programs with no encrypted segments that are uploaded to the App Store
// so it can be updated appropriately.
static constexpr uint32_t LC_ENCRYPTION_INFO = 0x21;
// Information about encrypted segments for 64-bit targets. Must also be present
// for programs with no encrypted segments that are uploaded to the App Store
// so it can be updated appropriately.
static constexpr uint32_t LC_ENCRYPTION_INFO_64 = 0x2c;
// An arbitrary piece of data not specified by the Mach-O format. (note_command)
static constexpr uint32_t LC_NOTE = 0x31;
// The target platform and minimum and target OS versions for this object file.
// (build_version_command)
static constexpr uint32_t LC_BUILD_VERSION = 0x32;

struct segment_command {
  uint32_t cmd;  // LC_SEGMENT
  uint32_t cmdsize;
  // The name of the segment. Must be unique within a given object file.
  char segname[16];
  // The starting virtual address and the size of the segment in memory.
  uint32_t vmaddr;
  uint32_t vmsize;
  // The starting file offset and size of the segment in the object file.
  // The file size and memory size of the segment may be different, for
  // example, if the segment contains zerofill sections.
  uint32_t fileoff;
  uint32_t filesize;
  // The maximum memory protection possible for this segment.
  vm_prot_t maxprot;
  // The initial memory protection for this segment once loaded.
  vm_prot_t initprot;
  // The number of sections in the variable-length payload of this load command.
  uint32_t nsects;
  //
  uint32_t flags;
  // section[]
};

// Contains the same fields as segment_command, but the starting memory
// address and size and the file offset and size are 64-bit fields.
struct segment_command_64 {
  uint32_t cmd;  // LC_SEGMENT_64
  uint32_t cmdsize;
  char segname[16];
  uint64_t vmaddr;
  uint64_t vmsize;
  uint64_t fileoff;
  uint64_t filesize;
  vm_prot_t maxprot;
  vm_prot_t initprot;
  uint32_t nsects;
  uint32_t flags;
  // section_64[]
};

struct section {
  char sectname[16];
  char segname[16];
  uint32_t addr;
  uint32_t size;
  uint32_t offset;
  uint32_t align;
  uint32_t reloff;
  uint32_t nreloc;
  uint32_t flags;
  uint32_t reserved1;
  uint32_t reserved2;
};

struct section_64 {
  char sectname[16];
  char segname[16];
  uint64_t addr;
  uint64_t size;
  uint32_t offset;
  uint32_t align;
  uint32_t reloff;
  uint32_t nreloc;
  uint32_t flags;
  uint32_t reserved1;
  uint32_t reserved2;
  uint32_t reserved3;
};

static constexpr uint32_t SECTION_TYPE = 0x000000ff;
static constexpr uint32_t SECTION_ATTRIBUTES = 0xffffff00;

// Creates section flags from the type and attributes.
constexpr uint32_t SectionFlags(intptr_t type, intptr_t attributes) {
  // Note that the S_* attribute values below do not need shifting.
  return (attributes & SECTION_ATTRIBUTES) | (type & SECTION_TYPE);
}

// Section types.

static constexpr uint32_t S_REGULAR = 0x0;
static constexpr uint32_t S_ZEROFILL = 0x1;
static constexpr uint32_t S_GB_ZEROFILL = 0xc;

// Section attributes. Note that these values do not need shifting when
// combining with a type and so the type bits are always 0.

static constexpr uint32_t S_NO_ATTRIBUTES = 0;
// The section only contains instructions.
static constexpr uint32_t S_ATTR_PURE_INSTRUCTIONS = 0x80000000;
// The section only contains information needed for debugging.
// No symbols should refer to this section and it must have type S_REGULAR.
static constexpr uint32_t S_ATTR_DEBUG = 0x02000000;
// The section contains some instructions. Should be set if
// S_ATTR_PURE_INSTRUCTIONS is also set.
static constexpr uint32_t S_ATTR_SOME_INSTRUCTIONS = 0x00000400;

// Special segment and section names used by Mach-O files. Only the
// ones used in our Mach-O writer are listed.

// Segment and section names for the text segment, which also contains
// constant data and unwinding information.
static constexpr char SEG_TEXT[] = "__TEXT";
static constexpr char SECT_TEXT[] = "__text";
static constexpr char SECT_CONST[] = "__const";
static constexpr char SECT_UNWIND_INFO[] = "__unwind_info";
static constexpr char SECT_EH_FRAME[] = "__eh_frame";

// Segment and section names for the data segment, which contains
// non-constant data (like the BSS section).
static constexpr char SEG_DATA[] = "__DATA";
static constexpr char SECT_BSS[] = "__bss";

// Segment and section names for the DWARF segment.
static constexpr char SEG_DWARF[] = "__DWARF";
static constexpr char SECT_DEBUG_LINE[] = "__debug_line";
static constexpr char SECT_DEBUG_INFO[] = "__debug_info";
static constexpr char SECT_DEBUG_ABBREV[] = "__debug_abbrev";

// Segment name for the linkedit segment. Does not contain sections but rather
// the non-header contents for other non-segment link commands like the symbol
// table and code signature.
static constexpr char SEG_LINKEDIT[] = "__LINKEDIT";

// Segment/section names used for relocatable object files.
static constexpr char SEG_UNNAMED[] = "";

static constexpr char SEG_LD[] = "__LD";
static constexpr char SECT_COMPACT_UNWIND[] = "__compact_unwind";

struct symtab_command {
  uint32_t cmd;  // LC_SYMTAB
  uint32_t cmdsize;
  uint32_t symoff;   // The offset of the symbol table data in the object file.
  uint32_t nsyms;    // The number of symbols in the symbol table data.
  uint32_t stroff;   // The offset of the string table for the symbol table.
  uint32_t strsize;  // The size of the string table in bytes.
};

// The structure used for symbols in the symbol table.
struct nlist {
  uint32_t n_idx;   // The index of the symbol name in the string table.
  uint8_t n_type;   // The type of the syble (see below).
  uint8_t n_sect;   // For section symbols, the section that owns this symbol.
  uint16_t n_desc;  // Interpreted based on the type of the symbol.
  // This is normally defined as a uword, but it must match the target
  // architecture's bitsize, not the host.
#if defined(TARGET_ARCH_IS_32_BIT)
  uint32_t n_value;
#else
  uint64_t n_value;
#endif
};

// The "section" for symbols not belonging to a specific section.
static constexpr uint8_t NO_SECT = 0;

// Masks for n_type.

// If any bits in (n_type & N_STAB) are set, then the symbol is
// a symbolic debugging symbol and so n_type is a specific constant.
static constexpr uint8_t N_STAB = 0xe0;

// Otherwise, n_type is a bitfield described by the following masks:

// The private external symbol bit.
static constexpr uint8_t N_PEXT = 0x10;
// A mask for the actual type of the symbol.
static constexpr uint8_t N_TYPE = 0xe;
// The external symbol bit.
static constexpr uint8_t N_EXT = 0x1;

// Values for the N_TYPE bits when no bits in N_STAB are set.

// An undefined symbol. (n_sect == NO_SECT)
static constexpr uint8_t N_UNDEF = 0x0;
// A symbol to an absolute offset in the Mach-O file. (n_sect == NO_SECT)
static constexpr uint8_t N_ABS = 0x2;
// A symbol defined in a specific section (load command index in n_sect).
static constexpr uint8_t N_SECT = 0xe;

// Values for the N_TYPE bits that set bits in N_STAB.

// A global symbol. (n_sect == NO_SECT, value = 0).
static constexpr uint8_t N_GSYM = 0x20;
// A function defined in a specific section.
static constexpr uint8_t N_FUN = 0x24;
// A static (object) symbol defined in a specific section.
static constexpr uint8_t N_STSYM = 0x26;
// The start of a function symbol in a specific section.
static constexpr uint8_t N_BNSYM = 0x2e;
// The end of a function symbol in a specific section.
static constexpr uint8_t N_ENSYM = 0x4e;
// The name of the object file. (n_sect == 0, n_desc = 1, value = mtime)
static constexpr uint8_t N_OSO = 0x66;

// Values for n_desc.

// Indicates an alternate symbol definition for a symbol value that
// is already defined elsewhere.
static constexpr uint16_t N_ALT_ENTRY = 0x0200;

struct dysymtab_command {
  uint32_t cmd;  // LC_DYSYMTAB
  uint32_t cmdsize;

  // The initial fields pairs are offsets into the symbol table information
  // in the linkedit segment. The first field is the symbol table index of
  // the first corresponding symbol (not file offset) and the second field
  // is the number of symbols starting at that index.

  // The local symbols in the symbol table.
  uint32_t ilocalsym;
  uint32_t nlocalsym;
  // The defined external symbols in the symbol table.
  uint32_t iextdefsym;
  uint32_t nextdefsym;
  // The undefined external symbols in the symbol table.
  uint32_t iundefsym;
  uint32_t nundefsym;

  // The remaining fields pairs are offsets into the linkedit segment.
  // The first field is the file offset and the second field is the number
  // of objects to read starting at that index.
  //
  // The Mach-O writer in the VM does not use these fields, so there's
  // no need for further documentation (they are populated with 0 values).

  uint32_t tocoff;
  uint32_t ntoc;
  uint32_t modtaboff;
  uint32_t nmodtab;
  uint32_t extrefsymoff;
  uint32_t nextrefsyms;
  uint32_t indirectsymoff;
  uint32_t nindirectsyms;
  uint32_t extreloff;
  uint32_t nextrel;
  uint32_t locreloff;
  uint32_t nlocrel;
};

struct note_command {
  uint32_t cmd;  // LC_NOTE
  uint32_t cmdsize;
  // An identifier used to determine the owner of this note (e.g., to
  // determine how to interpret the contents of the note.)
  char data_owner[16];
  // The file offset of the note contents.
  uint64_t offset;
  // The size of the note contents in bytes.
  uint64_t size;
};

struct uuid_command {
  uint32_t cmd;  // LC_UUID
  uint32_t cmdsize;
  uint8_t uuid[16];  // The 128-bit UUID of this object file.
};

struct build_version_command {
  uint32_t cmd;  // LC_BUILD_VERSION
  uint32_t cmdsize;
  uint32_t platform;  // See PLATFORM_* constants.
  // minos and sdk are X.Y.Z versions encoded as a bitfield:
  // From most to least significant:
  // X : 16
  // Y : 8
  // Z : 8
  uint32_t minos;  // Minimum OS version.
  uint32_t sdk;    // Target OS version.
  // The number of build_tool_version structs in the variable-length
  // payload of this load command. For our purposes, always 0 and
  // so there is no definition of the build_tool_version struct here.
  uint32_t ntools;
};

// Values for platform.

static constexpr uint32_t PLATFORM_UNKNOWN = 0x0;
static constexpr uint32_t PLATFORM_ANY = 0xffffffff;

static constexpr uint32_t PLATFORM_MACOS = 0x1;
static constexpr uint32_t PLATFORM_IOS = 0x2;

union lc_str {
  // The offset of the string in the load command contents.
  uint32_t offset;
  // We don't include the in-memory pointer alternative here.
};

struct dylib_info {
  lc_str name;
  // The timestamp the library was built and copied into user.
  uint32_t timestamp;
  // Version format is same as in build_version_command.
  uint32_t current_version;
  uint32_t compatibility_version;
};

struct dylib_command {
  uint32_t cmd;  // LC_LOAD_DYLIB and LC_ID_DYLIB among others
  uint32_t cmdsize;
  dylib_info dylib;
};

struct linkedit_data_command {
  uint32_t cmd;  // LC_CODE_SIGNATURE among others
  uint32_t cmdsize;
  // The file offset of the corresponding contents. (Note that this is
  // _not_ the offset into the linkedit segment.)
  uint32_t dataoff;
  // The size of the contents in bytes.
  uint32_t datasize;
};

struct rpath_command {
  uint32_t cmd;  // LC_RPATH
  uint32_t cmdsize;
  lc_str path;
};

// Magic numbers for code signature blobs.

static constexpr uint32_t CSMAGIC_CODEDIRECTORY = 0xfade0c02;
static constexpr uint32_t CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0;

// Types for code signature blobs.

static constexpr uint32_t CSSLOT_CODEDIRECTORY = 0;

// Code signature code directory flags.

static constexpr uint32_t CS_ADHOC = 0x00000002;
static constexpr uint32_t CS_LINKER_SIGNED = 0x00020000;

// Code signature hash types.

static constexpr uint8_t CS_HASHTYPE_SHA256 = 0x2;

// Code signature version numbers.

// The earliest version that can appear in a code signature.
static constexpr uint32_t CS_SUPPORTSNONE = 0x20001;
static constexpr uint32_t CS_SUPPORTSSCATTER = 0x20100;
static constexpr uint32_t CS_SUPPORTSTEAMID = 0x20200;
static constexpr uint32_t CS_SUPPORTSCODELIMIT64 = 0x20300;
static constexpr uint32_t CS_SUPPORTSEXECSEG = 0x20400;

struct cs_blob_index {
  uint32_t type;  // e.g., CSSLOT_CODEDIRECTORY
  // the offset of the nested blob within the superblob
  uint32_t offset;
};

struct cs_superblob {
  uint32_t magic;  // CSMAGIC_EMBEDDED_SIGNATURE
  // The length of the superblob, which includes any nested blobs.
  uint32_t length;
  // The number of nested blobs in this blob.
  uint32_t count;
  // The blob indices for the nested blobs.
  cs_blob_index index[];
  // The variable length payload also contains the contents of the nested blobs
  // after the blob indices. The blob indices are not aligned, and the data for
  // each nested blob is 8-byte aligned.
};

struct cs_code_directory {
  uint32_t magic;  // CSMAGIC_CODEDIRECTORY
  // The length of the code directory, including the identifier and hashes.
  uint32_t length;
  uint32_t version;            // For us, CS_SUPPORTSEXECSEG above.
  uint32_t flags;              // For us, CS_ADHOC | CS_LINKED_SIGNED.
  uint32_t hash_offset;        // The file offset of the hashes.
  uint32_t ident_offset;       // The file offset of the identifier.
  uint32_t num_special_slots;  // Unused by us, so 0.
  // The number of hashes (one for each page up to the code limit,
  // including one for the final incomplete page if any).
  uint32_t num_code_slots;
  // The end of the file covered by this code directory (for us, the file
  // offset of the superblob).
  uint32_t code_limit;
  // The size of each hash in the special and code slots.
  uint8_t hash_size;
  // The type of each hash in the special and code slots.
  uint8_t hash_type;
  uint8_t platform;         // Unused by us, so 0.
  uint8_t page_size;        // log2(page size)
  uint32_t spare2;          // always 0.
  uint32_t scatter_offset;  // Unused by us, so 0.
  uint32_t teamid_offset;   // Unused by us, so 0.
  uint32_t spare3;          // always 0.
  uint64_t code_limit_64;   // Code limit if larger than 32 bits.
  uint64_t exec_seg_base;   // file offset of the executable segment
  uint64_t exec_seg_limit;  // file size of the executable segment
  uint64_t exec_seg_flags;  // For our purposes, always 0.

  // Technically there can be more with later code signature versions,
  // but the Mach-O writer doesn't output those in the ad-hoc linker
  // signed signature.

  // The variable length payload contains the identifier followed by
  // the hashes in the special and code slots. The identifier data is
  // 8-byte aligned (like blobs) and the hash data is 16-byte aligned.
};

// Compact unwinding information constants for encodings.

// Architecture-independent constants for encodings.

// A shorthand for the zero-value encoding that denotes that the associated
// memory space does not contain function instructions.
static constexpr uint32_t UNWIND_INFO_ENCODING_NONE = 0;

static constexpr uint32_t UNWIND_INFO_ENCODING_IS_NOT_FUNCTION_START =
    0x80000000;
static constexpr uint32_t UNWIND_INFO_ENCODING_HAS_LSDA = 0x40000000;
static constexpr uint32_t UNWIND_INFO_ENCODING_PERSONALITY_MASK = 0x30000000;

// Currently compact unwinding information is only generated for ARM64, so only
// the constants used by the MachO writer are included below.

// ARM64-specific constants for encodings.
static constexpr uint32_t UNWIND_INFO_ENCODING_ARM64_MODE_MASK = 0x0F000000;

// A standard ARM64 prologue where FP/LR are immediately pushed on the
// stack and then SP is copied to FP. If there are any non-volatile
// registers saved, they are saved in pairs right below the FP/LR pair
// in register number order.
//
// In the MachO writer, this is the only non-zero encoding used and
// no non-volatile register pairs are recorded as being saved, so
// the appropriate constants for each pair and for other encodings are elided.
static constexpr uint32_t UNWIND_INFO_ENCODING_ARM64_MODE_FRAME = 0x04000000;

// Note that fields ending in section_offset are offsets into the unwind info
// section as a whole, whereas fields ending in page_offset are offsets into
// the specific second level page (e.g., the page header starts at offset 0).

struct unwind_info_lsda_index {
  uint32_t function_offset;
  uint32_t lsda_offset;
};

struct unwind_info_first_level_page_index {
  uint32_t function_offset;
  uint32_t second_level_page_section_offset;
  uint32_t lsda_index_section_offset;
};

// Second level pages have two formats: a compressed and a "regular" format.
// As the Mach-O writer only creates a single second level page with four
// entries currently, it uses the regular format as it is simpler.

static constexpr uint32_t UNWIND_INFO_REGULAR_SECOND_LEVEL_PAGE = 2;

struct unwind_info_regular_second_level_page_entry {
  uint32_t function_offset;
  uint32_t encoding;
};

struct unwind_info_regular_second_level_page_header {
  uint32_t kind;  // UNWIND_INFO_REGULAR_SECOND_LEVEL_PAGE
  uint16_t entry_page_offset;
  uint16_t entry_count;
};

static const size_t UNWIND_INFO_SECOND_LEVEL_PAGE_MAX_SIZE = 4 * KB;

static constexpr uint32_t UNWIND_INFO_REGULAR_SECOND_LEVEL_PAGE_MAX_ENTRIES =
    (UNWIND_INFO_SECOND_LEVEL_PAGE_MAX_SIZE -
     sizeof(unwind_info_regular_second_level_page_header)) /
    sizeof(unwind_info_regular_second_level_page_entry);

constexpr size_t UnwindInfoRegularSecondLevelPageSize(intptr_t entries) {
  return sizeof(unwind_info_regular_second_level_page_header) +
         sizeof(unwind_info_regular_second_level_page_entry) * entries;
}

static constexpr uint32_t UNWIND_INFO_VERSION = 1;

struct unwind_info_header {
  uint32_t version;
  uint32_t common_encodings_section_offset;
  uint32_t common_encodings_count;
  uint32_t personalities_section_offset;
  uint32_t personalities_count;
  uint32_t first_level_page_indices_section_offset;
  uint32_t first_level_page_indices_count;

  // Note that the last first level page indices is a sentinel that contains
  // the end of the covered space as its function offset and the end
  // of the lsda array as its lsda_index_section_offset.
  //
  // sentinel_index = first_level_page_indices_count - 1
  //
  // lsda_size =
  //    first_level_pages[sentinel_index].lsda_index_section_offset -
  //    first_level_pages[0].lsda_index_section_offset
  //
  // lsda_count = lsda_size / sizeof(unwind_info_lsda_index)
  // second_level_page_count = sentinel_index;

  // Variadic payload of unwind info section after unwind_info_header:
  // uint32_t common_encodings[common_encodings_count]
  // uint32_t personalities[personalities_count]
  // unwind_info_first_level_page_index
  //     first_level_pages[first_level_page_indices_count]
  // unwind_info_lsda_index lsda[lsda_count]
  // ... regular and compressed second level pages ...
};

// Relocation information in relocatable objects. The reloff field in
// the section and section_64 structs gives the starting file offset for
// the section's relocation information, and nreloc gives the number of
// structs found starting from that offset.
struct relocation_info {
  // The "address" of the relocation entry is the offset into the
  // corresponding section.
  int32_t address;
  // The metadata contains the following bit fields, from low to high:
  // 0-23:  The index of the section or symbol on which this relation entry
  //        is based. Note that, as with other parts of the Mach-O format,
  //        section indices are 1-based, while symbol indices are 0-based.
  // 24:    Whether or not this relocation is PC-relative.
  // 25-26: log2(n), where n is the size of the relocation entry in bytes.
  // 27:    Whether or not this relocation is "external". An external
  //        relocation is based on a symbol in the symbol table. If false,
  //        then the relocation is based on a section instead.
  // 28-31: The type of the relocation entry, see the RELOC_TYPE_*
  //        constants below.
  uint32_t metadata;
};

// The number of low bits used to store the symbol or section index in
// the relocation entry.
static constexpr uint32_t RELOC_METADATA_INDEX_BITS = 24;

// The size of the relocation in the section contents.
static constexpr uint32_t RELOC_SIZE_BYTE = 0 << 25;
static constexpr uint32_t RELOC_SIZE_2BYTES = 1 << 25;
static constexpr uint32_t RELOC_SIZE_4BYTES = 2 << 25;
static constexpr uint32_t RELOC_SIZE_8BYTES = 3 << 25;

// This bit is set if the index in the payload is the index of a symbol
// in the symbol table. It is unset if the index in the payload is the
// (1-based) index of a section.
static constexpr uint32_t RELOC_EXTERN = 1 << 27;

// For our purposes, the MachOWriter only emits two types of relocation entries:
// UNSIGNED and SUBTRACTOR. The numeric encoding of these types are
// platform dependent, but the semantics are the same for both X64 and ARM64:
//
// Consider a relocation comprised of the following parts:
//   (Target + TOffset) - (Source + SOffset)
// at the offset ROffset in section Section with virtual address
//   RAddress = Section.addr + ROffset
// in the relocatable object.
//
// An UNSIGNED relocation entry specifies Target. It refers either to a section
// or a symbol via the stored index.
//
// A SUBTRACTOR relocation entry specifies Source. It always refers to a symbol,
// never a section. Additionally, SUBTRACTOR relocation entries are always found
// immediately before the corresponding UNSIGNED relocation entries.
//
// The offsets are combined into a single addend, which is stored in the section
// contents at the offset of the relocation. If the relocation entries are
// symbol based, then
//   addend = TOffset - SOffset
// and for section-based relocation entries (which have no Source/SOffset),
//   addend = RAddress + TOffset
// That is, the virtual address of the relocation is included in the addend for
// section-based relocation entries.

// X64-specific constants for relocation types.

// A relocation specifying a section or symbol that is the target
// of the relocation.
static constexpr uint32_t RELOC_TYPE_X64_UNSIGNED = 0 << 28;
// A relocation specifying a symbol that is the source of the relocation.
// Note that in the list of the relocations, the source comes immediately
// _before_ the target (UNSIGNED) entry that it is subtracted from.
static constexpr uint32_t RELOC_TYPE_X64_SUBTRACTOR = 5 << 28;

// ARM64-specific constants for relocation types.

// A relocation specifying a section or symbol that is the target
// of the relocation.
static constexpr uint32_t RELOC_TYPE_ARM64_UNSIGNED = 0 << 28;
// A relocation specifying a symbol that is the source of the relocation.
// Note that in the list of the relocations, the source comes immediately
// _before_ the target (UNSIGNED) entry that it is subtracted from.
static constexpr uint32_t RELOC_TYPE_ARM64_SUBTRACTOR = 1 << 28;

struct encryption_info_command {
  uint32_t cmd;  // LC_ENCRYPTION_INFO
  uint32_t cmdsize;
  uint32_t cryptoff;   // file offset of the encrypted segment(s)
  uint32_t cryptsize;  // file size of the encrypted segment(s)
  uint32_t cryptid;    // encryption cypher used (0 == not encrypted)
};

struct encryption_info_command_64 {
  uint32_t cmd;  // LC_ENCRYPTION_INFO_64
  uint32_t cmdsize;
  uint32_t cryptoff;   // file offset of the encrypted segment(s)
  uint32_t cryptsize;  // file size of the encrypted segment(s)
  uint32_t cryptid;    // encryption cypher used (0 == not encrypted)
  uint32_t pad;        // padding to a multiple of 64 bits
};

#pragma pack(pop)

}  // namespace mach_o

}  // namespace dart

#endif  // RUNTIME_PLATFORM_MACH_O_H_
