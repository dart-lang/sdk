// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/elf.h"

#include "platform/elf.h"
#include "platform/text_buffer.h"
#include "vm/cpu.h"
#include "vm/thread.h"

namespace dart {

#if defined(TARGET_ARCH_IS_32_BIT)
static const intptr_t kElfHeaderSize = 52;
static const intptr_t kElfSectionTableAlignment = 4;
static const intptr_t kElfSectionTableEntrySize = 40;
static const intptr_t kElfProgramTableEntrySize = 32;
static const intptr_t kElfSymbolTableEntrySize = 16;
static const intptr_t kElfDynamicTableEntrySize = 8;
static const intptr_t kElfSymbolHashTableEntrySize = 4;
#else
static const intptr_t kElfHeaderSize = 64;
static const intptr_t kElfSectionTableAlignment = 8;
static const intptr_t kElfSectionTableEntrySize = 64;
static const intptr_t kElfProgramTableEntrySize = 56;
static const intptr_t kElfSymbolTableEntrySize = 24;
static const intptr_t kElfDynamicTableEntrySize = 16;
static const intptr_t kElfSymbolHashTableEntrySize = 4;
#endif

class Section : public ZoneAllocated {
 public:
  Section() {}

  virtual ~Section() {}
  virtual void Write(Elf* stream) = 0;

  // Linker view.
  intptr_t section_name = 0;  // Index into string table.
  intptr_t section_type = 0;
  intptr_t section_flags = 0;
  intptr_t section_index = -1;
  intptr_t section_link = elf::SHN_UNDEF;
  intptr_t section_info = 0;
  intptr_t section_entry_size = 0;
  intptr_t file_size = 0;
  intptr_t file_offset = -1;

  intptr_t alignment = 1;

  // Loader view.
  intptr_t segment_type = -1;
  intptr_t segment_flags = 0;
  intptr_t memory_size = 0;
  intptr_t memory_offset = -1;
};

class ProgramBits : public Section {
 public:
  ProgramBits(bool allocate,
              bool executable,
              bool writable,
              const uint8_t* bytes,
              intptr_t filesz,
              intptr_t memsz = -1) {
    if (memsz == -1) memsz = filesz;

    section_type = elf::SHT_PROGBITS;
    if (allocate) {
      section_flags = elf::SHF_ALLOC;
      if (executable) section_flags |= elf::SHF_EXECINSTR;
      if (writable) section_flags |= elf::SHF_WRITE;

      segment_type = elf::PT_LOAD;
      segment_flags = elf::PF_R;
      if (executable) segment_flags |= elf::PF_X;
      if (writable) segment_flags |= elf::PF_W;
    }

    bytes_ = bytes;
    file_size = filesz;
    memory_size = memsz;
  }

  void Write(Elf* stream) {
    if (bytes_ != nullptr) {
      stream->WriteBytes(bytes_, file_size);
    }
  }

  const uint8_t* bytes_;
};

class StringTable : public Section {
 public:
  explicit StringTable(bool allocate) : text_(128) {
    section_type = elf::SHT_STRTAB;
    section_flags = allocate ? elf::SHF_ALLOC : 0;
    segment_type = elf::PT_LOAD;
    segment_flags = elf::PF_R;

    text_.AddChar('\0');
    memory_size = file_size = text_.length();
  }

  intptr_t AddString(const char* str) {
    intptr_t offset = text_.length();
    text_.AddString(str);
    text_.AddChar('\0');
    memory_size = file_size = text_.length();
    return offset;
  }

  void Write(Elf* stream) {
    stream->WriteBytes(reinterpret_cast<const uint8_t*>(text_.buf()),
                       text_.length());
  }

  TextBuffer text_;
};

class Symbol : public ZoneAllocated {
 public:
  const char* cstr;
  intptr_t name;
  intptr_t info;
  intptr_t section;
  intptr_t offset;
  intptr_t size;
};

class SymbolTable : public Section {
 public:
  SymbolTable() {
    section_type = elf::SHT_DYNSYM;
    section_flags = elf::SHF_ALLOC;
    segment_type = elf::PT_LOAD;
    segment_flags = elf::PF_R;

    section_entry_size = kElfSymbolTableEntrySize;
    AddSymbol(NULL);
    section_info = 1;  // One "local" symbol, the reserved first entry.
  }

  void AddSymbol(Symbol* symbol) {
    symbols_.Add(symbol);
    memory_size += kElfSymbolTableEntrySize;
    file_size += kElfSymbolTableEntrySize;
  }

  void Write(Elf* stream) {
    // The first symbol table entry is reserved and must be all zeros.
    {
      const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
      stream->WriteWord(0);
      stream->WriteAddr(0);
      stream->WriteWord(0);
      stream->WriteByte(0);
      stream->WriteByte(0);
      stream->WriteHalf(0);
#else
      stream->WriteWord(0);
      stream->WriteByte(0);
      stream->WriteByte(0);
      stream->WriteHalf(0);
      stream->WriteAddr(0);
      stream->WriteXWord(0);
#endif
      const intptr_t end = stream->position();
      ASSERT((end - start) == kElfSymbolTableEntrySize);
    }

    for (intptr_t i = 1; i < symbols_.length(); i++) {
      Symbol* symbol = symbols_[i];
      const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
      stream->WriteWord(symbol->name);
      stream->WriteAddr(symbol->offset);
      stream->WriteWord(symbol->size);
      stream->WriteByte(symbol->info);
      stream->WriteByte(0);
      stream->WriteHalf(symbol->section);
#else
      stream->WriteWord(symbol->name);
      stream->WriteByte(symbol->info);
      stream->WriteByte(0);
      stream->WriteHalf(symbol->section);
      stream->WriteAddr(symbol->offset);
      stream->WriteXWord(symbol->size);
#endif
      const intptr_t end = stream->position();
      ASSERT((end - start) == kElfSymbolTableEntrySize);
    }
  }

  intptr_t length() const { return symbols_.length(); }
  Symbol* at(intptr_t i) const { return symbols_[i]; }

  GrowableArray<Symbol*> symbols_;
};

static uint32_t ElfHash(const unsigned char* name) {
  uint32_t h = 0;
  while (*name != '\0') {
    h = (h << 4) + *name++;
    uint32_t g = h & 0xf0000000;
    h ^= g;
    h ^= g >> 24;
  }
  return h;
}

class SymbolHashTable : public Section {
 public:
  SymbolHashTable(StringTable* strtab, SymbolTable* symtab) {
    section_type = elf::SHT_HASH;
    section_flags = elf::SHF_ALLOC;
    section_link = symtab->section_index;
    section_entry_size = kElfSymbolHashTableEntrySize;
    segment_type = elf::PT_LOAD;
    segment_flags = elf::PF_R;

    nchain_ = symtab->length();
    nbucket_ = symtab->length();

    bucket_ = Thread::Current()->zone()->Alloc<int32_t>(nbucket_);
    for (intptr_t i = 0; i < nbucket_; i++) {
      bucket_[i] = elf::STN_UNDEF;
    }

    chain_ = Thread::Current()->zone()->Alloc<int32_t>(nchain_);
    for (intptr_t i = 0; i < nchain_; i++) {
      chain_[i] = elf::STN_UNDEF;
    }

    for (intptr_t i = 1; i < symtab->length(); i++) {
      Symbol* symbol = symtab->at(i);
      uint32_t hash = ElfHash((const unsigned char*)symbol->cstr);
      uint32_t probe = hash % nbucket_;
      chain_[i] = bucket_[probe];  // next = head
      bucket_[probe] = i;          // head = symbol
    }

    memory_size = file_size = 4 * (nbucket_ + nchain_ + 2);
  }

  void Write(Elf* stream) {
    stream->WriteWord(nbucket_);
    stream->WriteWord(nchain_);
    for (intptr_t i = 0; i < nbucket_; i++) {
      stream->WriteWord(bucket_[i]);
    }
    for (intptr_t i = 0; i < nchain_; i++) {
      stream->WriteWord(chain_[i]);
    }
  }

 private:
  int32_t nbucket_;
  int32_t nchain_;
  int32_t* bucket_;  // "Head"
  int32_t* chain_;   // "Next"
};

class DynamicTable : public Section {
 public:
  DynamicTable(StringTable* strtab,
               SymbolTable* symtab,
               SymbolHashTable* hash) {
    section_type = elf::SHT_DYNAMIC;
    section_link = strtab->section_index;
    section_flags = elf::SHF_ALLOC | elf::SHF_WRITE;
    section_entry_size = kElfDynamicTableEntrySize;

    segment_type = elf::PT_LOAD;
    segment_flags = elf::PF_R | elf::PF_W;

    AddEntry(elf::DT_HASH, hash->memory_offset);
    AddEntry(elf::DT_STRTAB, strtab->memory_offset);
    AddEntry(elf::DT_STRSZ, strtab->memory_size);
    AddEntry(elf::DT_SYMTAB, symtab->memory_offset);
    AddEntry(elf::DT_SYMENT, kElfSymbolTableEntrySize);
    AddEntry(elf::DT_NULL, 0);
  }

  void Write(Elf* stream) {
    for (intptr_t i = 0; i < entries_.length(); i++) {
      const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
      stream->WriteWord(entries_[i]->tag);
      stream->WriteAddr(entries_[i]->value);
#else
      stream->WriteXWord(entries_[i]->tag);
      stream->WriteAddr(entries_[i]->value);
#endif
      const intptr_t end = stream->position();
      ASSERT((end - start) == kElfDynamicTableEntrySize);
    }
  }

  class Entry {
   public:
    intptr_t tag;
    intptr_t value;
  };

  void AddEntry(intptr_t tag, intptr_t value) {
    Entry* entry = new Entry();
    entry->tag = tag;
    entry->value = value;
    entries_.Add(entry);

    memory_size += kElfDynamicTableEntrySize;
    file_size += kElfDynamicTableEntrySize;
  }

 private:
  GrowableArray<Entry*> entries_;
};

// The first section must be written out and contains only zeros.
static const intptr_t kNumInvalidSections = 1;

// Extra segments put in the program table that aren't reified in
// Elf::segments_.
static const intptr_t kNumImplicitSegments = 3;

static const intptr_t kProgramTableSegmentSize = Elf::kPageSize;

Elf::Elf(Zone* zone, StreamingWriteStream* stream)
    : zone_(zone), stream_(stream), memory_offset_(0) {
  // Assumed by various offset logic in this file.
  ASSERT(stream_->position() == 0);

  // All our strings would fit in a single page. However, we use separate
  // .shstrtab and .dynstr to work around a bug in Android's strip utility.
  shstrtab_ = new (zone_) StringTable(/* allocate= */ false);
  shstrtab_->section_name = shstrtab_->AddString(".shstrtab");

  symstrtab_ = new (zone_) StringTable(/* allocate= */ true);
  symstrtab_->section_name = shstrtab_->AddString(".dynstr");

  symtab_ = new (zone_) SymbolTable();
  symtab_->section_name = shstrtab_->AddString(".dynsym");

  // Allocate regular segments after the program table.
  memory_offset_ = kProgramTableSegmentSize;
}

void Elf::AddSection(Section* section) {
  section->section_index = sections_.length() + kNumInvalidSections;
  sections_.Add(section);
}

void Elf::AddSegment(Section* section) {
  if (section->alignment < kPageSize) {
    section->alignment = kPageSize;
  }

  memory_offset_ = Utils::RoundUp(memory_offset_, section->alignment);
  section->memory_offset = memory_offset_;
  memory_offset_ += section->memory_size;
  segments_.Add(section);
  memory_offset_ = Utils::RoundUp(memory_offset_, kPageSize);
}

intptr_t Elf::NextMemoryOffset() {
  return memory_offset_;
}

intptr_t Elf::AddText(const char* name, const uint8_t* bytes, intptr_t size) {
  ProgramBits* image = new (zone_) ProgramBits(true, true, false, bytes, size);
  image->section_name = shstrtab_->AddString(".text");
  AddSection(image);
  AddSegment(image);

  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = symstrtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
  symbol->section = image->section_index;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = image->memory_offset;
  symbol->size = size;
  symtab_->AddSymbol(symbol);

  return symbol->offset;
}

intptr_t Elf::AddBSSData(const char* name, intptr_t size) {
  // Ideally the BSS segment would take no space in the object, but Android's
  // "strip" utility truncates the memory-size of our segments to their
  // file-size.
  //
  // Therefore we must insert zero-filled pages for the BSS.
  uint8_t* const bytes = Thread::Current()->zone()->Alloc<uint8_t>(size);
  memset(bytes, 0, size);

  ProgramBits* const image = new (zone_)
      ProgramBits(true, false, true, bytes, /*filesz=*/size, /*memsz=*/size);
  image->section_name = shstrtab_->AddString(".bss");
  AddSection(image);
  AddSegment(image);

  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = symstrtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_OBJECT;
  symbol->section = image->section_index;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = image->memory_offset;
  symbol->size = size;
  symtab_->AddSymbol(symbol);

  return symbol->offset;
}

intptr_t Elf::AddROData(const char* name, const uint8_t* bytes, intptr_t size) {
  ProgramBits* image = new (zone_) ProgramBits(true, false, false, bytes, size);
  image->section_name = shstrtab_->AddString(".rodata");
  AddSection(image);
  AddSegment(image);

  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = symstrtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_OBJECT;
  symbol->section = image->section_index;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = image->memory_offset;
  symbol->size = size;
  symtab_->AddSymbol(symbol);

  return symbol->offset;
}

void Elf::AddDebug(const char* name, const uint8_t* bytes, intptr_t size) {
  ProgramBits* image =
      new (zone_) ProgramBits(false, false, false, bytes, size);
  image->section_name = shstrtab_->AddString(name);
  AddSection(image);
}

void Elf::Finalize() {
  SymbolHashTable* hash = new (zone_) SymbolHashTable(symstrtab_, symtab_);
  hash->section_name = shstrtab_->AddString(".hash");

  AddSection(hash);
  AddSection(symtab_);
  AddSection(symstrtab_);

  symtab_->section_link = symstrtab_->section_index;
  hash->section_link = symtab_->section_index;

  // Before finalizing the string table's memory size:
  intptr_t name_dynamic = shstrtab_->AddString(".dynamic");

  // Finalizes memory size of string and symbol tables.
  AddSegment(hash);
  AddSegment(symtab_);
  AddSegment(symstrtab_);

  dynamic_ = new (zone_) DynamicTable(symstrtab_, symtab_, hash);
  dynamic_->section_name = name_dynamic;
  AddSection(dynamic_);
  AddSegment(dynamic_);

  AddSection(shstrtab_);
  shstrtab_->memory_offset = 0;  // No segment.

  ComputeFileOffsets();

  WriteHeader();
  WriteProgramTable();
  WriteSections();
  WriteSectionTable();
}

void Elf::ComputeFileOffsets() {
  intptr_t file_offset = kElfHeaderSize;

  program_table_file_offset_ = file_offset;
  program_table_file_size_ =
      (segments_.length() + kNumImplicitSegments) * kElfProgramTableEntrySize;
  file_offset += program_table_file_size_;

  for (intptr_t i = 0; i < sections_.length(); i++) {
    Section* section = sections_[i];
    file_offset = Utils::RoundUp(file_offset, section->alignment);
    section->file_offset = file_offset;
    file_offset += section->file_size;
  }

  file_offset = Utils::RoundUp(file_offset, kElfSectionTableAlignment);
  section_table_file_offset_ = file_offset;
  section_table_file_size_ =
      (sections_.length() + kNumInvalidSections) * kElfSectionTableEntrySize;
  file_offset += section_table_file_size_;
}

void Elf::WriteHeader() {
#if defined(TARGET_ARCH_IS_32_BIT)
  uint8_t size = elf::ELFCLASS32;
#else
  uint8_t size = elf::ELFCLASS64;
#endif
  uint8_t e_ident[16] = {0x7f,
                         'E',
                         'L',
                         'F',
                         size,
                         elf::ELFDATA2LSB,
                         elf::EV_CURRENT,
                         elf::ELFOSABI_SYSV,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0,
                         0};
  stream_->WriteBytes(e_ident, 16);

  WriteHalf(elf::ET_DYN);  // Shared library.

#if defined(TARGET_ARCH_IA32)
  WriteHalf(elf::EM_386);
#elif defined(TARGET_ARCH_X64)
  WriteHalf(elf::EM_X86_64);
#elif defined(TARGET_ARCH_ARM)
  WriteHalf(elf::EM_ARM);
#elif defined(TARGET_ARCH_ARM64)
  WriteHalf(elf::EM_AARCH64);
#else
  // E.g., DBC.
  FATAL("Unknown ELF architecture");
#endif

  WriteWord(elf::EV_CURRENT);  // Version
  WriteAddr(0);           // "Entry point"
  WriteOff(program_table_file_offset_);
  WriteOff(section_table_file_offset_);

#if defined(TARGET_ARCH_ARM)
  uword flags = elf::EF_ARM_ABI | (TargetCPUFeatures::hardfp_supported()
                                       ? elf::EF_ARM_ABI_FLOAT_HARD
                                       : elf::EF_ARM_ABI_FLOAT_SOFT);
#else
  uword flags = 0;
#endif
  WriteWord(flags);

  WriteHalf(kElfHeaderSize);
  WriteHalf(kElfProgramTableEntrySize);
  WriteHalf(segments_.length() + kNumImplicitSegments);
  WriteHalf(kElfSectionTableEntrySize);
  WriteHalf(sections_.length() + kNumInvalidSections);
  WriteHalf(shstrtab_->section_index);

  ASSERT(stream_->position() == kElfHeaderSize);
}

void Elf::WriteProgramTable() {
  ASSERT(stream_->position() == program_table_file_offset_);

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  {
    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream_->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(elf::PT_PHDR);
    WriteOff(program_table_file_offset_);   // File offset.
    WriteAddr(program_table_file_offset_);  // Virtual address.
    WriteAddr(program_table_file_offset_);  // Physical address, not used.
    WriteWord(program_table_file_size_);
    WriteWord(program_table_file_size_);
    WriteWord(elf::PF_R);
    WriteWord(kPageSize);
#else
    WriteWord(elf::PT_PHDR);
    WriteWord(elf::PF_R);
    WriteOff(program_table_file_offset_);   // File offset.
    WriteAddr(program_table_file_offset_);  // Virtual address.
    WriteAddr(program_table_file_offset_);  // Physical address, not used.
    WriteXWord(program_table_file_size_);
    WriteXWord(program_table_file_size_);
    WriteXWord(kPageSize);
#endif
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }
  // Load for self-reference to program header table. Required by Android but
  // not by Linux.
  {
    // We pre-allocated the virtual memory space for the program table itself.
    // Check that we didn't generate too many segments. Currently we generate a
    // fixed num of segments based on the four pieces of a snapshot, but if we
    // use more in the future we'll likely need to do something more compilated
    // to generate DWARF without knowing a piece's virtual address in advance.
    RELEASE_ASSERT((program_table_file_offset_ + program_table_file_size_) <
                   kProgramTableSegmentSize);

    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream_->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(elf::PT_LOAD);
    WriteOff(0);   // File offset.
    WriteAddr(0);  // Virtual address.
    WriteAddr(0);  // Physical address, not used.
    WriteWord(program_table_file_offset_ + program_table_file_size_);
    WriteWord(program_table_file_offset_ + program_table_file_size_);
    WriteWord(elf::PF_R);
    WriteWord(kPageSize);
#else
    WriteWord(elf::PT_LOAD);
    WriteWord(elf::PF_R);
    WriteOff(0);   // File offset.
    WriteAddr(0);  // Virtual address.
    WriteAddr(0);  // Physical address, not used.
    WriteXWord(program_table_file_offset_ + program_table_file_size_);
    WriteXWord(program_table_file_offset_ + program_table_file_size_);
    WriteXWord(kPageSize);
#endif
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }

  for (intptr_t i = 0; i < segments_.length(); i++) {
    Section* section = segments_[i];
    const intptr_t start = stream_->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(section->segment_type);
    WriteOff(section->file_offset);
    WriteAddr(section->memory_offset);  // Virtual address.
    WriteAddr(section->memory_offset);  // Physical address, not used.
    WriteWord(section->file_size);
    WriteWord(section->memory_size);
    WriteWord(section->segment_flags);
    WriteWord(section->alignment);
#else
    WriteWord(section->segment_type);
    WriteWord(section->segment_flags);
    WriteOff(section->file_offset);
    WriteAddr(section->memory_offset);  // Virtual address.
    WriteAddr(section->memory_offset);  // Physical address, not used.
    WriteXWord(section->file_size);
    WriteXWord(section->memory_size);
    WriteXWord(section->alignment);
#endif
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }

  // Special case: the dynamic section requires both LOAD and DYNAMIC program
  // header table entries.
  {
    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream_->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(elf::PT_DYNAMIC);
    WriteOff(dynamic_->file_offset);
    WriteAddr(dynamic_->memory_offset);  // Virtual address.
    WriteAddr(dynamic_->memory_offset);  // Physical address, not used.
    WriteWord(dynamic_->file_size);
    WriteWord(dynamic_->memory_size);
    WriteWord(dynamic_->segment_flags);
    WriteWord(dynamic_->alignment);
#else
    WriteWord(elf::PT_DYNAMIC);
    WriteWord(dynamic_->segment_flags);
    WriteOff(dynamic_->file_offset);
    WriteAddr(dynamic_->memory_offset);  // Virtual address.
    WriteAddr(dynamic_->memory_offset);  // Physical address, not used.
    WriteXWord(dynamic_->file_size);
    WriteXWord(dynamic_->memory_size);
    WriteXWord(dynamic_->alignment);
#endif
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }
}

void Elf::WriteSectionTable() {
  stream_->Align(kElfSectionTableAlignment);

  ASSERT(stream_->position() == section_table_file_offset_);

  {
    // The first entry in the section table is reserved and must be all zeros.
    ASSERT(kNumInvalidSections == 1);
    const intptr_t start = stream_->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(0);
    WriteWord(0);
    WriteWord(0);
    WriteAddr(0);
    WriteOff(0);
    WriteWord(0);
    WriteWord(0);
    WriteWord(0);
    WriteWord(0);
    WriteWord(0);
#else
    WriteWord(0);
    WriteWord(0);
    WriteXWord(0);
    WriteAddr(0);
    WriteOff(0);
    WriteXWord(0);
    WriteWord(0);
    WriteWord(0);
    WriteXWord(0);
    WriteXWord(0);
#endif
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfSectionTableEntrySize);
  }

  for (intptr_t i = 0; i < sections_.length(); i++) {
    Section* section = sections_[i];
    const intptr_t start = stream_->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(section->section_name);
    WriteWord(section->section_type);
    WriteWord(section->section_flags);
    WriteAddr(section->memory_offset);
    WriteOff(section->file_offset);
    WriteWord(section->file_size);  // Has different meaning for BSS.
    WriteWord(section->section_link);
    WriteWord(section->section_info);
    WriteWord(section->alignment);
    WriteWord(section->section_entry_size);
#else
    WriteWord(section->section_name);
    WriteWord(section->section_type);
    WriteXWord(section->section_flags);
    WriteAddr(section->memory_offset);
    WriteOff(section->file_offset);
    WriteXWord(section->file_size);  // Has different meaning for BSS.
    WriteWord(section->section_link);
    WriteWord(section->section_info);
    WriteXWord(section->alignment);
    WriteXWord(section->section_entry_size);
#endif
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfSectionTableEntrySize);
  }
}

void Elf::WriteSections() {
  for (intptr_t i = 0; i < sections_.length(); i++) {
    Section* section = sections_[i];
    stream_->Align(section->alignment);
    ASSERT(stream_->position() == section->file_offset);
    section->Write(this);
    ASSERT(stream_->position() == section->file_offset + section->file_size);
  }
}

}  // namespace dart
