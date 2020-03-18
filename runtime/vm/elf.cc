// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/elf.h"

#include "platform/elf.h"
#include "platform/text_buffer.h"
#include "vm/cpu.h"
#include "vm/hash_map.h"
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

#define DEFINE_LINEAR_FIELD_METHODS(name, type, init)                          \
  type name() const {                                                          \
    ASSERT(name##_ != init);                                                   \
    return name##_;                                                            \
  }                                                                            \
  void set_##name(type value) {                                                \
    ASSERT(name##_ == init);                                                   \
    name##_ = value;                                                           \
  }

#define DEFINE_LINEAR_FIELD(name, type, init) type name##_ = init;

class Section : public ZoneAllocated {
 public:
  Section(intptr_t type,
          intptr_t segment_type,
          bool allocate,
          bool executable,
          bool writable,
          intptr_t alignment = 1)
      : section_type(type),
        section_flags(EncodeSectionFlags(allocate, executable, writable)),
        alignment(allocate ? SegmentAlignment(alignment) : alignment),
        segment_type(segment_type),
        segment_flags(EncodeSegmentFlags(allocate, executable, writable)),
        // Non-segments will never have a memory offset, here represented by 0.
        memory_offset_(allocate ? -1 : 0) {
    // Only the reserved section (type 0) should have an alignment of 0.
    ASSERT(type == 0 || alignment > 0);
  }

  // The constructor that most subclasses will use.
  Section(intptr_t type,
          bool allocate,
          bool executable,
          bool writable,
          intptr_t alignment = 1)
      : Section(type,
                /*segment_type=*/allocate ? elf::PT_LOAD : 0,
                allocate,
                executable,
                writable,
                alignment) {}

  virtual ~Section() {}

  // Linker view.
  const intptr_t section_type;
  const intptr_t section_flags;
  const intptr_t alignment;

  // These are fields that only are not set for most kinds of sections and so we
  // set them to a reasonable default.
  intptr_t section_link = elf::SHN_UNDEF;
  intptr_t section_info = 0;
  intptr_t section_entry_size = 0;

#define FOR_EACH_SECTION_LINEAR_FIELD(M)                                       \
  M(section_name, intptr_t, -1)                                                \
  M(section_index, intptr_t, -1)                                               \
  M(file_offset, intptr_t, -1)

  FOR_EACH_SECTION_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  virtual intptr_t FileSize() = 0;

  // Loader view.
  const intptr_t segment_type;
  const intptr_t segment_flags;

#define FOR_EACH_SEGMENT_LINEAR_FIELD(M) M(memory_offset, intptr_t, -1)

  FOR_EACH_SEGMENT_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  virtual intptr_t MemorySize() = 0;

  // Other methods.
  virtual void Write(Elf* stream) = 0;

  void WriteSegmentEntry(Elf* stream, bool dynamic = false) {
    // This should never be used on either the reserved 0-filled section or
    // on sections without a segment.
    ASSERT(MemorySize() > 0);
    // dynamic should only be true if this section is the dynamic table.
    ASSERT(!dynamic || section_type == elf::SHT_DYNAMIC);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(dynamic ? elf::PT_DYNAMIC : segment_type);
    stream->WriteOff(file_offset());
    stream->WriteAddr(memory_offset());  // Virtual address.
    stream->WriteAddr(memory_offset());  // Physical address, not used.
    stream->WriteWord(FileSize());
    stream->WriteWord(MemorySize());
    stream->WriteWord(segment_flags);
    stream->WriteWord(alignment);
#else
    stream->WriteWord(dynamic ? elf::PT_DYNAMIC : segment_type);
    stream->WriteWord(segment_flags);
    stream->WriteOff(file_offset());
    stream->WriteAddr(memory_offset());  // Virtual address.
    stream->WriteAddr(memory_offset());  // Physical address, not used.
    stream->WriteXWord(FileSize());
    stream->WriteXWord(MemorySize());
    stream->WriteXWord(alignment);
#endif
  }

  void WriteSectionEntry(Elf* stream) {
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(section_name());
    stream->WriteWord(section_type);
    stream->WriteWord(section_flags);
    stream->WriteAddr(memory_offset());
    stream->WriteOff(file_offset());
    stream->WriteWord(FileSize());  // Has different meaning for BSS.
    stream->WriteWord(section_link);
    stream->WriteWord(section_info);
    stream->WriteWord(alignment);
    stream->WriteWord(section_entry_size);
#else
    stream->WriteWord(section_name());
    stream->WriteWord(section_type);
    stream->WriteXWord(section_flags);
    stream->WriteAddr(memory_offset());
    stream->WriteOff(file_offset());
    stream->WriteXWord(FileSize());  // Has different meaning for BSS.
    stream->WriteWord(section_link);
    stream->WriteWord(section_info);
    stream->WriteXWord(alignment);
    stream->WriteXWord(section_entry_size);
#endif
  }

 private:
  static intptr_t EncodeSectionFlags(bool allocate,
                                     bool executable,
                                     bool writable) {
    if (!allocate) return 0;
    intptr_t flags = elf::SHF_ALLOC;
    if (executable) flags |= elf::SHF_EXECINSTR;
    if (writable) flags |= elf::SHF_WRITE;
    return flags;
  }

  static intptr_t EncodeSegmentFlags(bool allocate,
                                     bool executable,
                                     bool writable) {
    if (!allocate) return 0;
    intptr_t flags = elf::PF_R;
    if (executable) flags |= elf::PF_X;
    if (writable) flags |= elf::PF_W;
    return flags;
  }

  static intptr_t SegmentAlignment(intptr_t alignment) {
    return alignment < Elf::kPageSize ? Elf::kPageSize : alignment;
  }

  FOR_EACH_SECTION_LINEAR_FIELD(DEFINE_LINEAR_FIELD);
  FOR_EACH_SEGMENT_LINEAR_FIELD(DEFINE_LINEAR_FIELD);

#undef FOR_EACH_SECTION_LINEAR_FIELD
#undef FOR_EACH_SEGMENT_LINEAR_FIELD
};

#undef DEFINE_LINEAR_FIELD
#undef DEFINE_LINEAR_FIELD_METHODS

// Represents the first entry in the section table, which should only contain
// zero values. Only used for WriteSectionEntry and should never actually appear
// in sections_.
class ReservedSection : public Section {
 public:
  ReservedSection()
      : Section(/*type=*/0,
                /*allocate=*/false,
                /*executable=*/false,
                /*writable=*/false,
                /*alignment=*/0) {
    set_section_name(0);
    set_section_index(0);
    set_file_offset(0);
  }

  intptr_t FileSize() { return 0; }
  intptr_t MemorySize() { return 0; }
  void Write(Elf* stream) { UNREACHABLE(); }
};

class BlobSection : public Section {
 public:
  BlobSection(intptr_t type,
              intptr_t segment_type,
              bool allocate,
              bool executable,
              bool writable,
              intptr_t filesz,
              intptr_t memsz,
              int alignment = 1)
      : Section(type, segment_type, allocate, executable, writable, alignment),
        file_size_(filesz),
        memory_size_(allocate ? memsz : 0) {}

  BlobSection(intptr_t type,
              bool allocate,
              bool executable,
              bool writable,
              intptr_t filesz,
              intptr_t memsz,
              int alignment = 1)
      : BlobSection(type,
                    /*segment_type=*/allocate ? elf::PT_LOAD : 0,
                    allocate,
                    executable,
                    writable,
                    filesz,
                    memsz,
                    alignment) {}

  intptr_t FileSize() { return file_size_; }
  intptr_t MemorySize() { return memory_size_; }

  virtual void Write(Elf* stream) = 0;

 private:
  const intptr_t file_size_;
  const intptr_t memory_size_;
};

// A section for representing the program header segment in the program header
// table. Only used for WriteSegmentEntry.
class ProgramTable : public BlobSection {
 public:
  ProgramTable(intptr_t offset, intptr_t size)
      : BlobSection(/*type=*/0,
                    /*segment_type=*/elf::PT_PHDR,
                    /*allocate=*/true,
                    /*executable=*/false,
                    /*writable=*/false,
                    /*filesz=*/size,
                    /*memsz=*/size) {
    set_file_offset(offset);
    set_memory_offset(offset);
  }

  // This should never actually be added to sections_ or segments_.
  void Write(Elf* stream) { UNREACHABLE(); }
};

// A section for representing the program header table load segment in the
// program header table. Only used for WriteSegmentEntry.
class ProgramTableLoad : public BlobSection {
 public:
  // The Android dynamic linker in Jelly Bean incorrectly assumes that all
  // non-writable segments are continguous. Since the BSS segment comes directly
  // after the program header segment, we must make this segment writable so
  // later non-writable segments does not cause the BSS to be also marked as
  // read-only.
  //
  // The bug is here:
  //   https://github.com/aosp-mirror/platform_bionic/blob/94963af28e445384e19775a838a29e6a71708179/linker/linker.c#L1991-L2001
  explicit ProgramTableLoad(intptr_t size)
      : BlobSection(/*type=*/0,
                    /*allocate=*/true,
                    /*executable=*/false,
                    /*writable=*/true,
                    /*filesz=*/size,
                    /*memsz=*/size) {
    set_file_offset(0);
    set_memory_offset(0);
  }

  // This should never actually be added to sections_ or segments_.
  void Write(Elf* stream) { UNREACHABLE(); }
};

class ProgramBits : public BlobSection {
 public:
  ProgramBits(bool allocate,
              bool executable,
              bool writable,
              const uint8_t* bytes,
              intptr_t filesz,
              intptr_t memsz = -1)
      : BlobSection(elf::SHT_PROGBITS,
                    allocate,
                    executable,
                    writable,
                    filesz,
                    memsz != -1 ? memsz : filesz),
        bytes_(ASSERT_NOTNULL(bytes)) {}

  void Write(Elf* stream) { stream->WriteBytes(bytes_, FileSize()); }

  const uint8_t* bytes_;
};

class NoBits : public BlobSection {
 public:
  NoBits(bool allocate, bool executable, bool writable, intptr_t memsz)
      : BlobSection(elf::SHT_NOBITS,
                    allocate,
                    executable,
                    writable,
                    /*filesz=*/0,
                    memsz) {}

  void Write(Elf* stream) {}
};

class StringTable : public Section {
 public:
  explicit StringTable(bool allocate)
      : Section(elf::SHT_STRTAB,
                allocate,
                /*executable=*/false,
                /*writable=*/false),
        dynamic_(allocate),
        text_(128),
        text_indices_() {
    text_.AddChar('\0');
    text_indices_.Insert({"", 1});
  }

  intptr_t FileSize() { return text_.length(); }
  intptr_t MemorySize() { return dynamic_ ? FileSize() : 0; }

  void Write(Elf* stream) {
    stream->WriteBytes(reinterpret_cast<const uint8_t*>(text_.buf()),
                       text_.length());
  }

  intptr_t AddString(const char* str) {
    if (auto const kv = text_indices_.Lookup(str)) return kv->value - 1;
    intptr_t offset = text_.length();
    text_.AddString(str);
    text_.AddChar('\0');
    text_indices_.Insert({str, offset + 1});
    return offset;
  }

  const bool dynamic_;
  TextBuffer text_;
  // To avoid kNoValue for intptr_t (0), we store an index n as n + 1.
  CStringMap<intptr_t> text_indices_;
};

class Symbol : public ZoneAllocated {
 public:
  Symbol(const char* cstr,
         intptr_t name,
         intptr_t info,
         intptr_t section,
         intptr_t offset,
         intptr_t size)
      : cstr_(cstr),
        name_index_(name),
        info_(info),
        section_index_(section),
        offset_(offset),
        size_(size) {}

  void Write(Elf* stream) const {
    stream->WriteWord(name_index_);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteAddr(offset_);
    stream->WriteWord(size_);
    stream->WriteByte(info_);
    stream->WriteByte(0);
    stream->WriteHalf(section_index_);
#else
    stream->WriteByte(info_);
    stream->WriteByte(0);
    stream->WriteHalf(section_index_);
    stream->WriteAddr(offset_);
    stream->WriteXWord(size_);
#endif
  }

 private:
  friend class SymbolHashTable;  // For cstr_ access.

  const char* cstr_;
  intptr_t name_index_;
  intptr_t info_;
  intptr_t section_index_;
  intptr_t offset_;
  intptr_t size_;
};

class SymbolTable : public Section {
 public:
  explicit SymbolTable(bool dynamic)
      : Section(dynamic ? elf::SHT_DYNSYM : elf::SHT_SYMTAB,
                dynamic,
                /*executable=*/false,
                /*writable=*/false,
                compiler::target::kWordSize),
        dynamic_(dynamic),
        reserved_("", 0, 0, 0, 0, 0) {
    section_entry_size = kElfSymbolTableEntrySize;
    // The first symbol table entry is reserved and must be all zeros.
    symbols_.Add(&reserved_);
    section_info = 1;  // One "local" symbol, the reserved first entry.
  }

  intptr_t FileSize() { return Length() * kElfSymbolTableEntrySize; }
  intptr_t MemorySize() { return dynamic_ ? FileSize() : 0; }

  void Write(Elf* stream) {
    for (intptr_t i = 0; i < Length(); i++) {
      auto const symbol = At(i);
      const intptr_t start = stream->position();
      symbol->Write(stream);
      const intptr_t end = stream->position();
      ASSERT((end - start) == kElfSymbolTableEntrySize);
    }
  }

  void AddSymbol(const Symbol* symbol) { symbols_.Add(symbol); }
  intptr_t Length() const { return symbols_.length(); }
  const Symbol* At(intptr_t i) const { return symbols_[i]; }

 private:
  const bool dynamic_;
  const Symbol reserved_;
  GrowableArray<const Symbol*> symbols_;
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
  SymbolHashTable(StringTable* strtab, SymbolTable* symtab)
      : Section(elf::SHT_HASH,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/false,
                compiler::target::kWordSize) {
    section_link = symtab->section_index();
    section_entry_size = kElfSymbolHashTableEntrySize;

    nchain_ = symtab->Length();
    nbucket_ = symtab->Length();

    auto zone = Thread::Current()->zone();
    bucket_ = zone->Alloc<int32_t>(nbucket_);
    for (intptr_t i = 0; i < nbucket_; i++) {
      bucket_[i] = elf::STN_UNDEF;
    }

    chain_ = zone->Alloc<int32_t>(nchain_);
    for (intptr_t i = 0; i < nchain_; i++) {
      chain_[i] = elf::STN_UNDEF;
    }

    for (intptr_t i = 1; i < symtab->Length(); i++) {
      auto const symbol = symtab->At(i);
      uint32_t hash = ElfHash((const unsigned char*)symbol->cstr_);
      uint32_t probe = hash % nbucket_;
      chain_[i] = bucket_[probe];  // next = head
      bucket_[probe] = i;          // head = symbol
    }
  }

  intptr_t FileSize() { return 4 * (nbucket_ + nchain_ + 2); }
  intptr_t MemorySize() { return FileSize(); }

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
  DynamicTable(StringTable* strtab, SymbolTable* symtab, SymbolHashTable* hash)
      : Section(elf::SHT_DYNAMIC,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/true,
                compiler::target::kWordSize) {
    section_link = strtab->section_index();
    section_entry_size = kElfDynamicTableEntrySize;

    AddEntry(elf::DT_HASH, hash->memory_offset());
    AddEntry(elf::DT_STRTAB, strtab->memory_offset());
    AddEntry(elf::DT_STRSZ, strtab->MemorySize());
    AddEntry(elf::DT_SYMTAB, symtab->memory_offset());
    AddEntry(elf::DT_SYMENT, kElfSymbolTableEntrySize);
    AddEntry(elf::DT_NULL, 0);
  }

  intptr_t FileSize() { return entries_.length() * kElfDynamicTableEntrySize; }
  intptr_t MemorySize() { return FileSize(); }

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
    : zone_(zone),
      stream_(stream),
      shstrtab_(new (zone) StringTable(/*allocate=*/false)),
      dynstrtab_(new (zone) StringTable(/*allocate=*/true)),
      dynsym_(new (zone) SymbolTable(/*dynamic=*/true)),
      memory_offset_(kProgramTableSegmentSize) {
  // Assumed by various offset logic in this file.
  ASSERT(stream_->position() == 0);
}

void Elf::AddSection(Section* section, const char* name) {
  ASSERT(shstrtab_ != nullptr);
  section->set_section_name(shstrtab_->AddString(name));
  section->set_section_index(sections_.length() + kNumInvalidSections);
  sections_.Add(section);
  if (section->MemorySize() > 0) {
    memory_offset_ = Utils::RoundUp(memory_offset_, section->alignment);
    section->set_memory_offset(memory_offset_);
    segments_.Add(section);
    memory_offset_ += section->MemorySize();
    memory_offset_ = Utils::RoundUp(memory_offset_, kPageSize);
  }
}

intptr_t Elf::NextMemoryOffset() const {
  return memory_offset_;
}

intptr_t Elf::NextSectionIndex() const {
  return sections_.length() + kNumInvalidSections;
}

intptr_t Elf::AddSectionSymbol(const Section* section,
                               const char* name,
                               intptr_t size) {
  auto const name_index = dynstrtab_->AddString(name);
  auto const info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
  auto const section_index = section->section_index();
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  auto const memory_offset = section->memory_offset();
  auto const symbol = new (zone_)
      Symbol(name, name_index, info, section_index, memory_offset, size);
  dynsym_->AddSymbol(symbol);

  return memory_offset;
}

intptr_t Elf::AddText(const char* name, const uint8_t* bytes, intptr_t size) {
  Section* image = nullptr;
  if (bytes != nullptr) {
    image = new (zone_) ProgramBits(true, true, false, bytes, size);
  } else {
    image = new (zone_) NoBits(true, true, false, size);
  }
  AddSection(image, ".text");

  return AddSectionSymbol(image, name, size);
}

void Elf::AddStaticSymbol(intptr_t section,
                          const char* name,
                          intptr_t address,
                          intptr_t size) {
  // Lazily allocate the static string and symbol tables, as we only add static
  // symbols in unstripped ELF files.
  if (strtab_ == nullptr) {
    ASSERT(symtab_ == nullptr);
    strtab_ = new (zone_) StringTable(/* allocate= */ false);
    symtab_ = new (zone_) SymbolTable(/*dynamic=*/false);
  }

  auto const name_index = strtab_->AddString(name);
  auto const info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
  Symbol* symbol =
      new (zone_) Symbol(name, name_index, info, section, address, size);
  symtab_->AddSymbol(symbol);
}

intptr_t Elf::AddBSSData(const char* name, intptr_t size) {
  // Ideally the BSS segment would take no space in the object, but Android's
  // "strip" utility truncates the memory-size of our segments to their
  // file-size.
  //
  // Therefore we must insert zero-filled pages for the BSS.
  uint8_t* const bytes = zone_->Alloc<uint8_t>(size);
  memset(bytes, 0, size);

  ProgramBits* const image =
      new (zone_) ProgramBits(true, false, true, bytes, size);
  AddSection(image, ".bss");

  return AddSectionSymbol(image, name, size);
}

intptr_t Elf::AddROData(const char* name, const uint8_t* bytes, intptr_t size) {
  ASSERT(bytes != nullptr);
  ProgramBits* image = new (zone_) ProgramBits(true, false, false, bytes, size);
  AddSection(image, ".rodata");

  return AddSectionSymbol(image, name, size);
}

void Elf::AddDebug(const char* name, const uint8_t* bytes, intptr_t size) {
  ASSERT(bytes != nullptr);
  ProgramBits* image =
      new (zone_) ProgramBits(false, false, false, bytes, size);
  AddSection(image, name);
}

void Elf::Finalize() {
  AddSection(dynstrtab_, ".dynstr");
  AddSection(dynsym_, ".dynsym");
  dynsym_->section_link = dynstrtab_->section_index();

  auto const hash = new (zone_) SymbolHashTable(dynstrtab_, dynsym_);
  AddSection(hash, ".hash");

  if (symtab_ != nullptr) {
    ASSERT(strtab_ != nullptr);
    AddSection(strtab_, ".strtab");
    AddSection(symtab_, ".symtab");
    symtab_->section_link = strtab_->section_index();
  }

  dynamic_ = new (zone_) DynamicTable(dynstrtab_, dynsym_, hash);
  AddSection(dynamic_, ".dynamic");

  AddSection(shstrtab_, ".shstrtab");

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
    section->set_file_offset(file_offset);
    file_offset += section->FileSize();
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
  FATAL("Unknown ELF architecture");
#endif

  WriteWord(elf::EV_CURRENT);  // Version
  WriteAddr(0);                // "Entry point"
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
  WriteHalf(shstrtab_->section_index());

  ASSERT(stream_->position() == kElfHeaderSize);
}

void Elf::WriteProgramTable() {
  ASSERT(stream_->position() == program_table_file_offset_);

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  {
    ProgramTable program_table(program_table_file_offset_,
                               program_table_file_size_);

    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream_->position();
    program_table.WriteSegmentEntry(this);
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
    auto const program_table_segment_size =
        program_table_file_offset_ + program_table_file_size_;
    RELEASE_ASSERT(program_table_segment_size < kProgramTableSegmentSize);

    // We create a section that, when printed as a segment, contains the
    // appropriate info for the program table.
    ProgramTableLoad program_table_load(program_table_segment_size);

    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream_->position();
    program_table_load.WriteSegmentEntry(this);
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }

  for (intptr_t i = 0; i < segments_.length(); i++) {
    Section* section = segments_[i];
    const intptr_t start = stream_->position();
    section->WriteSegmentEntry(this);
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }

  // Special case: the dynamic section requires both LOAD and DYNAMIC program
  // header table entries.
  {
    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream_->position();
    dynamic_->WriteSegmentEntry(this, /*dynamic=*/true);
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
    ReservedSection reserved;
    reserved.WriteSectionEntry(this);
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfSectionTableEntrySize);
  }

  for (intptr_t i = 0; i < sections_.length(); i++) {
    Section* section = sections_[i];
    const intptr_t start = stream_->position();
    section->WriteSectionEntry(this);
    const intptr_t end = stream_->position();
    ASSERT((end - start) == kElfSectionTableEntrySize);
  }
}

void Elf::WriteSections() {
  for (intptr_t i = 0; i < sections_.length(); i++) {
    Section* section = sections_[i];
    stream_->Align(section->alignment);
    ASSERT(stream_->position() == section->file_offset());
    section->Write(this);
    ASSERT(stream_->position() == section->file_offset() + section->FileSize());
  }
}

}  // namespace dart
