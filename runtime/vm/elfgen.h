// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ELFGEN_H_
#define VM_ELFGEN_H_

#include "vm/lockers.h"
#include "vm/thread.h"

namespace dart {

// -----------------------------------------------------------------------------
// Implementation of ElfGen
//
// Specification documents:
//   http://refspecs.freestandards.org
//
//   ELF generic ABI:
//     http://refspecs.freestandards.org/elf/gabi4+/contents.html
//   ELF processor-specific supplement for X86_64:
//     http://refspecs.freestandards.org/elf/x86_64-SysV-psABI.pdf
//   DWARF 2.0:
//     http://refspecs.freestandards.org/dwarf/dwarf-2.0.0.pdf

// Forward declarations.
class File;

// ElfGen is used to generate minimal ELF information containing code, symbols,
// and line numbers for generated code in the dart VM. This information is
// used in two ways:
// - it is used to generate in-memory ELF information which is then
//   registered with gdb using the JIT interface.
// - it is also used to generate a file with the ELF information. This file
//   is not executed, but read by pprof to analyze Dart programs.

class ElfGen {
 public:
  ElfGen();
  ~ElfGen();

  // Add the code starting at pc.
  void AddCode(uword pc, intptr_t size);

  // Add symbol information for a region (includes the start and end symbol),
  // does not add the actual code.
  void AddCodeRegion(const char* name, uword pc, intptr_t size);

  // Add specified symbol information, does not add the actual code.
  int AddFunction(const char* name, uword pc, intptr_t size);

  // Write out all the Elf information using the specified handle.
  bool WriteToFile(File* handle);
  bool WriteToMemory(DebugInfo::ByteBuffer* region);

  // Register this generated section with GDB using the JIT interface.
  static void RegisterSectionWithGDB(const char* name,
                                     uword entry_point,
                                     intptr_t size);

  // Unregister all generated section from GDB.
  static void UnregisterAllSectionsWithGDB();

 private:
  // ELF helpers
  typedef int (*OutputWriter)(void* handle,
                              const DebugInfo::ByteBuffer& section);
  typedef void (*OutputPadder)(void* handle, int padding_size);

  int AddString(DebugInfo::ByteBuffer* buf, const char* str);
  int AddSectionName(const char* str);
  int AddName(const char* str);
  void AddELFHeader(int shoff);
  void AddSectionHeader(int section, int offset);
  int PadSection(DebugInfo::ByteBuffer* section, int offset, int alignment);
  bool WriteOutput(void* handle, OutputWriter writer, OutputPadder padder);

  uword text_vma_;  // text section vma
  intptr_t text_size_;  // text section size
  int text_padding_;  // padding preceding text section

  static const int kNumSections = 5;  // we generate 5 sections
  int section_name_[kNumSections];  // array of section name indices
  DebugInfo::ByteBuffer section_buf_[kNumSections];  // array of section buffers
  DebugInfo::ByteBuffer header_;  // ELF header buffer
  DebugInfo::ByteBuffer sheaders_;  // section header table buffer
  DebugInfo::ByteBuffer lineprog_;  // line statement program, part of
                                    // '.debug_line' section

  // current state of the DWARF line info generator
  uintptr_t cur_addr_;  // current pc
  int map_offset_;
  uword map_begin_;
  uword map_end_;

  Mutex lock_;
};


enum {
  // Various constant sizes for ELF files.
  kAddrSize = sizeof(uword),
  kPageSize = 4*1024,  // Memory mapping page size.
  kTextAlign = 16,
  kELFHeaderSize = 40 + 3*kAddrSize,
  kProgramHeaderEntrySize = 8 + 6*kAddrSize,
  kSectionHeaderEntrySize = 16 + 6*kAddrSize,
  kSymbolSize = 8 + 2*kAddrSize,

  // Our own layout of sections.
  kUndef = 0,   // Undefined section.
  kText,        // Text section.
  kShStrtab,    // Section header string table.
  kStrtab,      // String table.
  kSymtab,      // Symbol table.
  kNumSections,  // Num of section header entries in section header table.

  // Various ELF constants.
  kELFCLASS32 = 1,
  kELFCLASS64 = 2,
  kELFDATA2LSB = 1,
  kELFDATA2MSB = 2,
  kEM_386 = 3,
  kEM_MIPS = 8,
  kEM_ARM = 40,
  kEM_X86_64 = 62,
  kEV_CURRENT = 1,
  kET_EXEC = 2,  // not used
  kET_DYN = 3,
  kSHT_PROGBITS = 1,
  kSHT_SYMTAB = 2,
  kSHT_STRTAB = 3,
  kSHF_WRITE = 1,  // not used
  kSHF_ALLOC = 2,
  kSHF_EXECINSTR = 4,
  kSTB_LOCAL = 0,
  kSTB_EXPORTED = 1,
  kSTT_FUNC = 2,
};


// ELF and DWARF constants.
static const char* kEI_MAG0_MAG3 = "\177ELF";
static const uint8_t kSpecialOpcodeLengths[] = { 0, 1, 1, 1, 1, 0, 0, 0, 1 };


// Section attributes.
// The field names correspond to the field names of Elf32_Shdr and Elf64_Shdr.
static const struct {
  // Section header index (only used to check correct section order).
  int shndx;
  const char* name;  // sh_name will be the index of name inserted in shstrtab.
  int sh_type;
  int sh_flags;
  int sh_link;
  int sh_addralign;
  int sh_entsize;
} section_attr[kNumSections + 1] = {
  { kUndef,      "",               0,             0,
    0,       0,           0           },
  { kText,       ".text",          kSHT_PROGBITS, kSHF_ALLOC|kSHF_EXECINSTR,
    0,       kTextAlign,  0           },
  { kShStrtab,   ".shstrtab",      kSHT_STRTAB,   0,
    0,       1,           0           },
  { kStrtab,     ".strtab",        kSHT_STRTAB,   0,
    0,       1,           0           },
  { kSymtab,     ".symtab",        kSHT_SYMTAB,   0,
    kStrtab, kAddrSize,   kSymbolSize },
  // Sentinel to pad the last section
  // for proper alignment of section header table.
  { 0,          "",               0,             0,
    0,       kAddrSize,   0           }
};


// Convenience function aligning an integer.
static inline uintptr_t Align(uintptr_t x, intptr_t size) {
  // size is a power of 2
  ASSERT((size & (size-1)) == 0);
  return (x + (size-1)) & ~(size-1);
}


// Convenience function writing a single byte to a ByteBuffer.
static inline void WriteByte(DebugInfo::ByteBuffer* buf, uint8_t byte) {
  buf->Add(byte);
}


// Convenience function writing an unsigned native word to a ByteBuffer.
// The word is 32-bit wide in 32-bit mode and 64-bit wide in 64-bit mode.
static inline void WriteWord(DebugInfo::ByteBuffer* buf, uword word) {
  uint8_t* p = reinterpret_cast<uint8_t*>(&word);
  for (size_t i = 0; i < sizeof(word); i++) {
    buf->Add(p[i]);
  }
}

static inline void WriteInt(DebugInfo::ByteBuffer* buf, int word) {
  uint8_t* p = reinterpret_cast<uint8_t*>(&word);
  for (size_t i = 0; i < sizeof(word); i++) {
    buf->Add(p[i]);
  }
}

static inline void WriteShort(DebugInfo::ByteBuffer* buf, uint16_t word) {
  uint8_t* p = reinterpret_cast<uint8_t*>(&word);
  for (size_t i = 0; i < sizeof(word); i++) {
    buf->Add(p[i]);
  }
}

static inline void WriteString(DebugInfo::ByteBuffer* buf, const char* str) {
  for (size_t i = 0; i < strlen(str); i++) {
    buf->Add(static_cast<uint8_t>(str[i]));
  }
}

static inline void Write(DebugInfo::ByteBuffer* buf,
                         const void* mem,
                         int length) {
  const uint8_t* p = reinterpret_cast<const uint8_t*>(mem);
  for (int i = 0; i < length; i++) {
    buf->Add(p[i]);
  }
}


// Write given section to file and return written size.
static int WriteSectionToFile(void* handle,
                              const DebugInfo::ByteBuffer& section) {
#if 0
  File* fp = reinterpret_cast<File*>(handle);
  int size = section.size();
  fp->WriteFully(section.data(), size);
  return size;
#else
  return 0;
#endif
}


// Pad output file to specified padding size.
static void PadFile(void* handle, int padding_size) {
#if 0
  File* fp = reinterpret_cast<File*>(handle);
  for (int i = 0; i < padding_size; i++) {
    fp->WriteFully("", 1);
  }
#endif
}


// Write given section to specified memory region and return written size.
static int WriteSectionToMemory(void* handle,
                                const DebugInfo::ByteBuffer& section) {
  DebugInfo::ByteBuffer* buffer =
      reinterpret_cast<DebugInfo::ByteBuffer*>(handle);
  int size = section.size();
  for (int i = 0; i < size; i++) {
    buffer->Add(static_cast<uint8_t>(section.data()[i]));
  }
  return size;
}


// Pad memory to specified padding size.
static void PadMemory(void* handle, int padding_size) {
  DebugInfo::ByteBuffer* buffer =
      reinterpret_cast<DebugInfo::ByteBuffer*>(handle);
  for (int i = 0; i < padding_size; i++) {
    buffer->Add(static_cast<uint8_t>(0));
  }
}


// Constructor
ElfGen::ElfGen()
    : text_vma_(0), text_size_(0), text_padding_(0), map_offset_(0), lock_() {
  for (int i = 0; i < kNumSections; i++) {
    ASSERT(section_attr[i].shndx == i);  // Verify layout of sections.
    section_name_[i] = AddSectionName(section_attr[i].name);
  }
  // Section header string table always starts with an empty string, which is
  // the name of the kUndef section.
  ASSERT((section_attr[0].name[0] == '\0') && (section_name_[0] == 0));

  // String table always starts with an empty string.
  AddName("");
  ASSERT(section_buf_[kStrtab].size() == 1);

  // Symbol at index 0 in symtab is always STN_UNDEF (all zero):
  DebugInfo::ByteBuffer* symtab = &section_buf_[kSymtab];
  while (symtab->size() < kSymbolSize) {
    WriteInt(symtab, 0);
  }
  ASSERT(symtab->size() == kSymbolSize);
}


// Destructor
ElfGen::~ElfGen() {
}


void ElfGen::AddCode(uword pc, intptr_t size) {
  MutexLocker ml(&lock_);
  text_vma_ = pc;
  text_size_ = size;
  // We pad the text section in the file to align absolute code addresses with
  // corresponding file offsets as if the code had been loaded by memory
  // mapping.
  if (text_vma_ % kPageSize < kELFHeaderSize) {
    text_padding_ = text_vma_ % kPageSize + kPageSize - kELFHeaderSize;
  } else {
    text_padding_ = text_vma_ % kPageSize - kELFHeaderSize;
  }

  Write(&section_buf_[kText], reinterpret_cast<void*>(pc), size);
  // map_offset is the file offset of the first mapped page.
  map_offset_ = (kELFHeaderSize + text_padding_)/kPageSize*kPageSize;
  map_begin_ = Align(text_vma_ - kPageSize + 1, kPageSize);
  map_end_ = Align(text_vma_ + size, kPageSize);
}


void ElfGen::AddCodeRegion(const char* name, uword pc, intptr_t size) {
  MutexLocker ml(&lock_);
  AddFunction(name, pc, size);
  char end_name[256];
  OS::SNPrint(end_name, sizeof(end_name), "%s_end", name);
  AddFunction(end_name, pc + size, 0);
}


int ElfGen::AddFunction(const char* name, uword pc, intptr_t size) {
  ASSERT(text_vma_ != 0);  // code must have been added
  DebugInfo::ByteBuffer* symtab = &section_buf_[kSymtab];
  const int beg = symtab->size();
  WriteInt(symtab, AddName(name));  // st_name
#if defined(ARCH_IS_64_BIT)
  WriteShort(symtab, (kSTB_LOCAL << 4) + kSTT_FUNC);  // st_info + (st_other<<8)
  WriteShort(symtab, kText);  // st_shndx
#endif
  WriteWord(symtab, pc);  // st_value
  WriteWord(symtab, size);  // st_size
#if defined(ARCH_IS_32_BIT)
  // st_info + (st_other<<8)
  WriteShort(symtab, (kSTB_EXPORTED << 4) + kSTT_FUNC);
  WriteShort(symtab, kText);  // st_shndx
#endif
  ASSERT(symtab->size() - beg == kSymbolSize);
  return beg / kSymbolSize;  // symbol index in symtab
}


bool ElfGen::WriteToFile(File* handle) {
  return WriteOutput(handle, WriteSectionToFile, PadFile);
}


bool ElfGen::WriteToMemory(DebugInfo::ByteBuffer* region) {
  return WriteOutput(region, WriteSectionToMemory, PadMemory);
}


int ElfGen::AddString(DebugInfo::ByteBuffer* buf, const char* str) {
  const int str_index = buf->size();
  WriteString(buf, str);
  WriteByte(buf, 0);  // terminating '\0'
  return str_index;
}


int ElfGen::AddSectionName(const char* str) {
  return AddString(&section_buf_[kShStrtab], str);
}


int ElfGen::AddName(const char* str) {
  return AddString(&section_buf_[kStrtab], str);
}


void ElfGen::AddELFHeader(int shoff) {
  ASSERT(text_vma_ != 0);  // Code must have been added.
  Write(&header_, kEI_MAG0_MAG3, 4);  // EI_MAG0..EI_MAG3
#if defined(ARCH_IS_32_BIT)
  WriteByte(&header_, kELFCLASS32);  // EI_CLASS
#elif defined(ARCH_IS_64_BIT)
  WriteByte(&header_, kELFCLASS64);  // EI_CLASS
#else
#error Unknown architecture.
#endif
  WriteByte(&header_, kELFDATA2LSB);  // EI_DATA
  WriteByte(&header_, kEV_CURRENT);  // EI_VERSION
  WriteByte(&header_, 0);  // EI_PAD
  WriteInt(&header_, 0);  // EI_PAD
  WriteInt(&header_, 0);  // EI_PAD
  WriteShort(&header_, kET_DYN);  // e_type, fake a shared object.
#if defined(TARGET_ARCH_IA32)
  WriteShort(&header_, kEM_386);  // e_machine
#elif defined(TARGET_ARCH_X64)
  WriteShort(&header_, kEM_X86_64);  // e_machine
#elif defined(TARGET_ARCH_ARM)
  WriteShort(&header_, kEM_ARM);  // e_machine
#elif defined(TARGET_ARCH_ARM64)
  // TODO(zra): Find the right ARM64 constant.
  WriteShort(&header_, kEM_ARM);  // e_machine
#elif defined(TARGET_ARCH_MIPS)
  WriteShort(&header_, kEM_MIPS);  // e_machine
#else
#error Unknown architecture.
#endif
  WriteInt(&header_, kEV_CURRENT);  // e_version
  WriteWord(&header_, 0);  // e_entry: none
  WriteWord(&header_, 0);  // e_phoff: no program header table.
  WriteWord(&header_, shoff);  // e_shoff: section header table offset.
  WriteInt(&header_, 0);  // e_flags: no flags.
  WriteShort(&header_, kELFHeaderSize);  // e_ehsize: header size.
  WriteShort(&header_, kProgramHeaderEntrySize);  // e_phentsize
  WriteShort(&header_, 0);  // e_phnum: no entries program header table.
  WriteShort(&header_, kSectionHeaderEntrySize);  // e_shentsize
  // e_shnum: number of section header entries.
  WriteShort(&header_, kNumSections);
  WriteShort(&header_, kShStrtab);  // e_shstrndx: index of shstrtab.
  ASSERT(header_.size() == kELFHeaderSize);
}


void ElfGen::AddSectionHeader(int section, int offset) {
  WriteInt(&sheaders_, section_name_[section]);
  WriteInt(&sheaders_, section_attr[section].sh_type);
  WriteWord(&sheaders_, section_attr[section].sh_flags);
  // sh_addr: abs addr
  WriteWord(&sheaders_, (section == kText) ? text_vma_ : 0);
  WriteWord(&sheaders_, offset);  // sh_offset: section file offset.
  WriteWord(&sheaders_, section_buf_[section].size());
  WriteInt(&sheaders_, section_attr[section].sh_link);
  WriteInt(&sheaders_, 0);
  WriteWord(&sheaders_, section_attr[section].sh_addralign);
  WriteWord(&sheaders_, section_attr[section].sh_entsize);
  ASSERT(sheaders_.size() == kSectionHeaderEntrySize * (section + 1));
}


// Pads the given section with zero bytes for the given aligment, assuming the
// section starts at given file offset; returns file offset after padded
// section.
int ElfGen::PadSection(DebugInfo::ByteBuffer* section,
                       int offset,
                       int alignment) {
  offset += section->size();
  int aligned_offset = Align(offset, alignment);
  while (offset++ < aligned_offset) {
    WriteByte(section, 0);  // one byte padding.
  }
  return aligned_offset;
}


bool ElfGen::WriteOutput(void* handle,
                         OutputWriter writer,
                         OutputPadder padder) {
  if (handle == NULL || writer == NULL || padder == NULL) {
    return false;
  }

  // Align all sections before writing the ELF header in order to calculate the
  // file offset of the section header table, which is needed in the ELF header.
  // Pad each section as required by the aligment constraint of the immediately
  // following section, except the ELF header section, which requires special
  // padding (text_padding_) to align the text_ section.
  int offset = kELFHeaderSize + text_padding_;
  for (int i = kText; i < kNumSections; i++) {
    offset = PadSection(&section_buf_[i],
                        offset,
                        section_attr[i+1].sh_addralign);
  }

  const int shoff = offset;  // Section header table offset.

  // Write elf header.
  AddELFHeader(shoff);
  offset = (*writer)(handle, header_);

  // Pad file before writing text section in order to align vma with file
  // offset.
  (*padder)(handle, text_padding_);

  offset += text_padding_;
  ASSERT((text_vma_ - offset) % kPageSize == 0);

  // Section header at index 0 in section header table is always SHN_UNDEF:
  for (int i = 0; i < kNumSections; i++) {
    AddSectionHeader(i, offset);
    offset += (*writer)(handle, section_buf_[i]);
  }
  // Write section header table.
  ASSERT(offset == shoff);
  offset += (*writer)(handle, sheaders_);
  ASSERT(offset == shoff + kNumSections * kSectionHeaderEntrySize);

  return true;
}

}  // namespace dart

#endif  // VM_ELFGEN_H_
