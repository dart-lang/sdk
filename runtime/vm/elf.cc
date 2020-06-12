// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/elf.h"

#include "platform/elf.h"
#include "vm/cpu.h"
#include "vm/dwarf.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/thread.h"
#include "vm/zone_text_buffer.h"

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

// A wrapper around StreamingWriteStream that provides methods useful for
// writing ELF files (e.g., using ELF definitions of data sizes).
class ElfWriteStream : public ValueObject {
 public:
  explicit ElfWriteStream(StreamingWriteStream* stream)
      : stream_(ASSERT_NOTNULL(stream)) {}

  intptr_t position() const { return stream_->position(); }
  void Align(const intptr_t alignment) {
    ASSERT(Utils::IsPowerOfTwo(alignment));
    stream_->Align(alignment);
  }
  void WriteBytes(const uint8_t* b, intptr_t size) {
    stream_->WriteBytes(b, size);
  }
  void WriteByte(uint8_t value) {
    stream_->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  void WriteHalf(uint16_t value) {
    stream_->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  void WriteWord(uint32_t value) {
    stream_->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  void WriteAddr(compiler::target::uword value) {
    stream_->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
  void WriteOff(compiler::target::uword value) {
    stream_->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
#if defined(TARGET_ARCH_IS_64_BIT)
  void WriteXWord(uint64_t value) {
    stream_->WriteBytes(reinterpret_cast<uint8_t*>(&value), sizeof(value));
  }
#endif

 private:
  StreamingWriteStream* const stream_;
};

#define DEFINE_LINEAR_FIELD_METHODS(name, type, init)                          \
  type name() const {                                                          \
    ASSERT(name##_ != init);                                                   \
    return name##_;                                                            \
  }                                                                            \
  void set_##name(type value) {                                                \
    ASSERT_EQUAL(name##_, init);                                               \
    name##_ = value;                                                           \
  }

#define DEFINE_LINEAR_FIELD(name, type, init) type name##_ = init;

// Used for segments that should not be used as sections.
static constexpr intptr_t kInvalidSection = -1;

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
    // Only the reserved section (type 0) has (and must have) an alignment of 0.
    ASSERT(type == elf::SHT_NULL || alignment > 0);
    ASSERT(alignment == 0 || type != elf::SHT_NULL);
    // Segment-only entries should have a set segment_type.
    ASSERT(type != kInvalidSection || segment_type != elf::PT_NULL);
  }

  // The constructor that most subclasses will use.
  Section(intptr_t type,
          bool allocate,
          bool executable,
          bool writable,
          intptr_t alignment = 1)
      : Section(type,
                /*segment_type=*/allocate ? elf::PT_LOAD : elf::PT_NULL,
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

  static constexpr intptr_t kInitValue = -1;

#define FOR_EACH_SECTION_LINEAR_FIELD(M)                                       \
  M(section_name, intptr_t, kInitValue)                                        \
  M(section_index, intptr_t, kInitValue)                                       \
  M(file_offset, intptr_t, kInitValue)

  FOR_EACH_SECTION_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  virtual intptr_t FileSize() const = 0;

  // Loader view.
  const intptr_t segment_type;
  const intptr_t segment_flags;

#define FOR_EACH_SEGMENT_LINEAR_FIELD(M) M(memory_offset, intptr_t, kInitValue)

  FOR_EACH_SEGMENT_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  virtual intptr_t MemorySize() const = 0;

  // Other methods.

  // Returns whether new content can be added to a section.
  bool HasBeenFinalized() const {
    if (segment_type != elf::PT_NULL) {
      // The contents of a segment must not change after the segment is added
      // (when its memory offset is calculated).
      return memory_offset_ != kInitValue;
    } else {
      // Sections with an in-memory segment can have new content added until
      // we calculate file offsets.
      return file_offset_ != kInitValue;
    }
  }

  virtual void Write(ElfWriteStream* stream) = 0;

  void WriteSegmentEntry(ElfWriteStream* stream) {
    // This should never be used on sections without a segment.
    ASSERT(segment_type != elf::PT_NULL);
    ASSERT(MemorySize() > 0);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(segment_type);
    stream->WriteOff(file_offset());
    stream->WriteAddr(memory_offset());  // Virtual address.
    stream->WriteAddr(memory_offset());  // Physical address, not used.
    stream->WriteWord(FileSize());
    stream->WriteWord(MemorySize());
    stream->WriteWord(segment_flags);
    stream->WriteWord(alignment);
#else
    stream->WriteWord(segment_type);
    stream->WriteWord(segment_flags);
    stream->WriteOff(file_offset());
    stream->WriteAddr(memory_offset());  // Virtual address.
    stream->WriteAddr(memory_offset());  // Physical address, not used.
    stream->WriteXWord(FileSize());
    stream->WriteXWord(MemorySize());
    stream->WriteXWord(alignment);
#endif
  }

  void WriteSectionEntry(ElfWriteStream* stream) {
    // Segment-only entries should not be in sections_.
    ASSERT(section_type != kInvalidSection);
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
// zero values and does not correspond to a memory segment.
class ReservedSection : public Section {
 public:
  ReservedSection()
      : Section(/*type=*/elf::SHT_NULL,
                /*allocate=*/false,
                /*executable=*/false,
                /*writable=*/false,
                /*alignment=*/0) {
    set_section_name(0);
    set_section_index(0);
    set_file_offset(0);
  }

  intptr_t FileSize() const { return 0; }
  intptr_t MemorySize() const { return 0; }
  void Write(ElfWriteStream* stream) {}
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

  intptr_t FileSize() const { return file_size_; }
  intptr_t MemorySize() const { return memory_size_; }

  virtual void Write(ElfWriteStream* stream) = 0;

 private:
  const intptr_t file_size_;
  const intptr_t memory_size_;
};

// A segment for representing the program header table self-reference in the
// program header table. There is no corresponding section for this segment.
class ProgramTableSelfSegment : public BlobSection {
 public:
  ProgramTableSelfSegment(intptr_t offset, intptr_t size)
      : BlobSection(/*type=*/kInvalidSection,
                    /*segment_type=*/elf::PT_PHDR,
                    /*allocate=*/true,
                    /*executable=*/false,
                    /*writable=*/false,
                    /*filesz=*/size,
                    /*memsz=*/size) {
    set_file_offset(offset);
    set_memory_offset(offset);
  }

  void Write(ElfWriteStream* stream) { UNREACHABLE(); }
};

// A segment for representing the program header table load segment in the
// program header table. There is no corresponding section for this segment.
class ProgramTableLoadSegment : public BlobSection {
 public:
  // The Android dynamic linker in Jelly Bean incorrectly assumes that all
  // non-writable segments are continguous. Since the BSS segment comes directly
  // after the program header segment, we must make this segment writable so
  // later non-writable segments does not cause the BSS to be also marked as
  // read-only.
  //
  // The bug is here:
  //   https://github.com/aosp-mirror/platform_bionic/blob/94963af28e445384e19775a838a29e6a71708179/linker/linker.c#L1991-L2001
  explicit ProgramTableLoadSegment(intptr_t size)
      : BlobSection(/*type=*/kInvalidSection,
                    /*allocate=*/true,
                    /*executable=*/false,
                    /*writable=*/true,
                    /*filesz=*/size,
                    /*memsz=*/size) {
    set_file_offset(0);
    set_memory_offset(0);
  }

  void Write(ElfWriteStream* stream) { UNREACHABLE(); }
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

  void Write(ElfWriteStream* stream) { stream->WriteBytes(bytes_, FileSize()); }

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

  void Write(ElfWriteStream* stream) {}
};

class StringTable : public Section {
 public:
  explicit StringTable(bool allocate)
      : Section(elf::SHT_STRTAB,
                allocate,
                /*executable=*/false,
                /*writable=*/false),
        dynamic_(allocate),
        text_(Thread::Current()->zone(), 128),
        text_indices_() {
    text_.AddChar('\0');
    text_indices_.Insert({"", 1});
  }

  intptr_t FileSize() const { return text_.length(); }
  intptr_t MemorySize() const { return dynamic_ ? FileSize() : 0; }

  void Write(ElfWriteStream* stream) {
    stream->WriteBytes(reinterpret_cast<const uint8_t*>(text_.buffer()),
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

  const char* At(intptr_t index) {
    ASSERT(index < text_.length());
    return text_.buffer() + index;
  }
  intptr_t Lookup(const char* str) const {
    return text_indices_.LookupValue(str) - 1;
  }

  const bool dynamic_;
  ZoneTextBuffer text_;
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
      : name_index(name),
        info(info),
        section_index(section),
        offset(offset),
        size(size),
        cstr_(cstr) {}

  void Write(ElfWriteStream* stream) const {
    stream->WriteWord(name_index);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteAddr(offset);
    stream->WriteWord(size);
    stream->WriteByte(info);
    stream->WriteByte(0);
    stream->WriteHalf(section_index);
#else
    stream->WriteByte(info);
    stream->WriteByte(0);
    stream->WriteHalf(section_index);
    stream->WriteAddr(offset);
    stream->WriteXWord(size);
#endif
  }

  const intptr_t name_index;
  const intptr_t info;
  const intptr_t section_index;
  const intptr_t offset;
  const intptr_t size;

 private:
  friend class SymbolHashTable;  // For cstr_ access.

  const char* const cstr_;
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

  intptr_t FileSize() const { return Length() * kElfSymbolTableEntrySize; }
  intptr_t MemorySize() const { return dynamic_ ? FileSize() : 0; }

  void Write(ElfWriteStream* stream) {
    for (intptr_t i = 0; i < Length(); i++) {
      auto const symbol = At(i);
      const intptr_t start = stream->position();
      symbol->Write(stream);
      const intptr_t end = stream->position();
      ASSERT_EQUAL(end - start, kElfSymbolTableEntrySize);
    }
  }

  void AddSymbol(const Symbol* symbol) { symbols_.Add(symbol); }
  intptr_t Length() const { return symbols_.length(); }
  const Symbol* At(intptr_t i) const { return symbols_[i]; }

  const Symbol* FindSymbolWithNameIndex(intptr_t name_index) const {
    for (intptr_t i = 0; i < Length(); i++) {
      auto const symbol = At(i);
      if (symbol->name_index == name_index) return symbol;
    }
    return nullptr;
  }

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

  intptr_t FileSize() const { return 4 * (nbucket_ + nchain_ + 2); }
  intptr_t MemorySize() const { return FileSize(); }

  void Write(ElfWriteStream* stream) {
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

  intptr_t FileSize() const {
    return entries_.length() * kElfDynamicTableEntrySize;
  }
  intptr_t MemorySize() const { return FileSize(); }

  void Write(ElfWriteStream* stream) {
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
      ASSERT_EQUAL(end - start, kElfDynamicTableEntrySize);
    }
  }

  class Entry : public ZoneAllocated {
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

// A segment for representing the dynamic table segment in the program header
// table. There is no corresponding section for this segment.
class DynamicSegment : public BlobSection {
 public:
  explicit DynamicSegment(DynamicTable* dynamic)
      : BlobSection(/*type=*/kInvalidSection,
                    /*segment_type=*/elf::PT_DYNAMIC,
                    /*allocate=*/true,
                    /*executable=*/false,
                    /*writable=*/true,
                    /*filesz=*/dynamic->FileSize(),
                    /*memsz=*/dynamic->MemorySize()) {
    set_memory_offset(dynamic->memory_offset());
  }

  void Write(ElfWriteStream* stream) { UNREACHABLE(); }
};

static const intptr_t kProgramTableSegmentSize = Elf::kPageSize;

Elf::Elf(Zone* zone, StreamingWriteStream* stream, Dwarf* dwarf)
    : zone_(zone),
      unwrapped_stream_(stream),
      dwarf_(dwarf),
      shstrtab_(new (zone) StringTable(/*allocate=*/false)),
      dynstrtab_(new (zone) StringTable(/*allocate=*/true)),
      dynsym_(new (zone) SymbolTable(/*dynamic=*/true)),
      memory_offset_(kProgramTableSegmentSize) {
  // Assumed by various offset logic in this file.
  ASSERT_EQUAL(unwrapped_stream_->position(), 0);
  // The first section in the section header table is always a reserved
  // entry containing only 0 values.
  sections_.Add(new (zone_) ReservedSection());
  // Go ahead and add the section header string table, since it doesn't have
  // an in-memory segment and so can be added to until we compute file offsets.
  AddSection(shstrtab_, ".shstrtab");
  if (dwarf_ != nullptr) {
    // Not a stripped ELF file, so allocate static string and symbol tables.
    strtab_ = new (zone_) StringTable(/* allocate= */ false);
    AddSection(strtab_, ".strtab");
    symtab_ = new (zone_) SymbolTable(/*dynamic=*/false);
    AddSection(symtab_, ".symtab");
    symtab_->section_link = strtab_->section_index();
  }
}

void Elf::AddSection(Section* section, const char* name) {
  ASSERT(section_table_file_size_ < 0);
  ASSERT(!shstrtab_->HasBeenFinalized());
  section->set_section_name(shstrtab_->AddString(name));
  section->set_section_index(sections_.length());
  sections_.Add(section);
  if (section->MemorySize() > 0) {
    ASSERT(program_table_file_size_ < 0);
    memory_offset_ = Utils::RoundUp(memory_offset_, section->alignment);
    section->set_memory_offset(memory_offset_);
    segments_.Add(section);
    memory_offset_ += section->MemorySize();
    memory_offset_ = Utils::RoundUp(memory_offset_, kPageSize);
  }
}

intptr_t Elf::AddSegmentSymbol(const Section* section, const char* name) {
  // While elf::STT_SECTION might seem more appropriate, those symbols are
  // usually local and dlsym won't return them.
  auto const info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
  auto const section_index = section->section_index();
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  auto const address = section->memory_offset();
  auto const size = section->MemorySize();
  AddDynamicSymbol(name, info, section_index, address, size);
  return address;
}

intptr_t Elf::AddText(const char* name, const uint8_t* bytes, intptr_t size) {
  Section* image = nullptr;
  if (bytes != nullptr) {
    image = new (zone_) ProgramBits(true, true, false, bytes, size);
  } else {
    image = new (zone_) NoBits(true, true, false, size);
  }
  AddSection(image, ".text");

  return AddSegmentSymbol(image, name);
}

static bool FindSymbol(StringTable* strings,
                       SymbolTable* symbols,
                       const char* name,
                       intptr_t* offset,
                       intptr_t* size) {
  auto const name_index = strings->Lookup(name);
  if (name_index < 0) return false;
  auto const symbol = symbols->FindSymbolWithNameIndex(name_index);
  if (symbol == nullptr) return false;
  if (offset != nullptr) {
    *offset = symbol->offset;
  }
  if (size != nullptr) {
    *size = symbol->size;
  }
  return true;
}

bool Elf::FindDynamicSymbol(const char* name,
                            intptr_t* offset,
                            intptr_t* size) const {
  return FindSymbol(dynstrtab_, dynsym_, name, offset, size);
}

bool Elf::FindStaticSymbol(const char* name,
                           intptr_t* offset,
                           intptr_t* size) const {
  if (strtab_ == nullptr || symtab_ == nullptr) return false;
  return FindSymbol(strtab_, symtab_, name, offset, size);
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
  static_assert(Image::kBssAlignment <= kPageSize,
                "ELF .bss section is not aligned as expected by Image class");
  ASSERT_EQUAL(image->alignment, kPageSize);
  AddSection(image, ".bss");

  return AddSegmentSymbol(image, name);
}

intptr_t Elf::AddROData(const char* name, const uint8_t* bytes, intptr_t size) {
  ASSERT(bytes != nullptr);
  ProgramBits* image = new (zone_) ProgramBits(true, false, false, bytes, size);
  AddSection(image, ".rodata");

  return AddSegmentSymbol(image, name);
}

void Elf::AddDebug(const char* name, const uint8_t* bytes, intptr_t size) {
  ASSERT(dwarf_ != nullptr);
  ASSERT(bytes != nullptr);
  ProgramBits* image =
      new (zone_) ProgramBits(false, false, false, bytes, size);
  AddSection(image, name);
}

void Elf::AddDynamicSymbol(const char* name,
                           intptr_t info,
                           intptr_t section_index,
                           intptr_t address,
                           intptr_t size) {
  ASSERT(!dynstrtab_->HasBeenFinalized() && !dynsym_->HasBeenFinalized());
  auto const name_index = dynstrtab_->AddString(name);
  auto const symbol =
      new (zone_) Symbol(name, name_index, info, section_index, address, size);
  dynsym_->AddSymbol(symbol);

  // Some tools assume the static symbol table is a superset of the dynamic
  // symbol table when it exists (see dartbug.com/41783).
  AddStaticSymbol(name, info, section_index, address, size);
}

void Elf::AddStaticSymbol(const char* name,
                          intptr_t info,
                          intptr_t section_index,
                          intptr_t address,
                          intptr_t size) {
  if (dwarf_ == nullptr) return;  // No static info kept in stripped ELF files.

  ASSERT(!symtab_->HasBeenFinalized() && !strtab_->HasBeenFinalized());
  auto const name_index = strtab_->AddString(name);
  auto const symbol =
      new (zone_) Symbol(name, name_index, info, section_index, address, size);
  symtab_->AddSymbol(symbol);
}

#if defined(DART_PRECOMPILER)
class DwarfElfStream : public DwarfWriteStream {
 public:
  explicit DwarfElfStream(Zone* zone,
                          WriteStream* stream,
                          const CStringMap<intptr_t>& address_map)
      : zone_(zone),
        stream_(ASSERT_NOTNULL(stream)),
        address_map_(address_map) {}

  void sleb128(intptr_t value) {
    bool is_last_part = false;
    while (!is_last_part) {
      uint8_t part = value & 0x7F;
      value >>= 7;
      if ((value == 0 && (part & 0x40) == 0) ||
          (value == static_cast<intptr_t>(-1) && (part & 0x40) != 0)) {
        is_last_part = true;
      } else {
        part |= 0x80;
      }
      stream_->WriteFixed(part);
    }
  }

  void uleb128(uintptr_t value) {
    bool is_last_part = false;
    while (!is_last_part) {
      uint8_t part = value & 0x7F;
      value >>= 7;
      if (value == 0) {
        is_last_part = true;
      } else {
        part |= 0x80;
      }
      stream_->WriteFixed(part);
    }
  }

  void u1(uint8_t value) { stream_->WriteFixed(value); }
  // Can't use WriteFixed for these, as we may not be at aligned positions.
  void u2(uint16_t value) { stream_->WriteBytes(&value, sizeof(value)); }
  void u4(uint32_t value) { stream_->WriteBytes(&value, sizeof(value)); }
  void u8(uint64_t value) { stream_->WriteBytes(&value, sizeof(value)); }
  void string(const char* cstr) {  // NOLINT
    stream_->WriteBytes(reinterpret_cast<const uint8_t*>(cstr),
                        strlen(cstr) + 1);
  }
  intptr_t position() { return stream_->Position(); }
  intptr_t ReserveSize(const char* prefix, intptr_t* start) {
    ASSERT(start != nullptr);
    intptr_t fixup = position();
    // We assume DWARF v2, so all sizes are 32-bit.
    u4(0);
    // All sizes for DWARF sections measure the size of the section data _after_
    // the size value.
    *start = position();
    return fixup;
  }
  void SetSize(intptr_t fixup, const char* prefix, intptr_t start) {
    const uint32_t value = position() - start;
    memmove(stream_->buffer() + fixup, &value, sizeof(value));
  }
  void OffsetFromSymbol(const char* symbol, intptr_t offset) {
    auto const address = address_map_.LookupValue(symbol);
    ASSERT(address != 0);
    addr(address + offset);
  }
  void DistanceBetweenSymbolOffsets(const char* symbol1,
                                    intptr_t offset1,
                                    const char* symbol2,
                                    intptr_t offset2) {
    auto const address1 = address_map_.LookupValue(symbol1);
    ASSERT(address1 != 0);
    auto const address2 = address_map_.LookupValue(symbol2);
    ASSERT(address2 != 0);
    auto const delta = (address1 + offset1) - (address2 + offset2);
    RELEASE_ASSERT(delta >= 0);
    uleb128(delta);
  }
  void InitializeAbstractOrigins(intptr_t size) {
    abstract_origins_size_ = size;
    abstract_origins_ = zone_->Alloc<uint32_t>(abstract_origins_size_);
  }
  void RegisterAbstractOrigin(intptr_t index) {
    ASSERT(abstract_origins_ != nullptr);
    ASSERT(index < abstract_origins_size_);
    abstract_origins_[index] = position();
  }
  void AbstractOrigin(intptr_t index) { u4(abstract_origins_[index]); }

 private:
  void addr(uword value) {
#if defined(TARGET_ARCH_IS_32_BIT)
    u4(value);
#else
    u8(value);
#endif
  }

  Zone* const zone_;
  WriteStream* const stream_;
  const CStringMap<intptr_t>& address_map_;
  uint32_t* abstract_origins_ = nullptr;
  intptr_t abstract_origins_size_ = -1;

  DISALLOW_COPY_AND_ASSIGN(DwarfElfStream);
};

static constexpr intptr_t kInitialDwarfBufferSize = 64 * KB;

static uint8_t* ZoneReallocate(uint8_t* ptr, intptr_t len, intptr_t new_len) {
  return Thread::Current()->zone()->Realloc<uint8_t>(ptr, len, new_len);
}
#endif

const Section* Elf::FindSegmentForAddress(intptr_t address) const {
  for (intptr_t i = 0; i < segments_.length(); i++) {
    auto const segment = segments_[i];
    auto const start = segment->memory_offset();
    auto const end = start + segment->MemorySize();
    if (address >= start && address < end) {
      return segment;
    }
  }
  return nullptr;
}

void Elf::FinalizeDwarfSections() {
  if (dwarf_ == nullptr) return;
#if defined(DART_PRECOMPILER)
  // Add all the static symbols for Code objects. We'll keep a table of
  // symbol names to relocated addresses for use in the DwarfElfStream.
  // The default kNoValue of 0 is okay here, as no symbols are defined for
  // relocated address 0.
  CStringMap<intptr_t> symbol_to_address_map;
  // Prime the map with any existing static symbols.
  if (symtab_ != nullptr) {
    ASSERT(strtab_ != nullptr);
    // Skip the initial reserved entry in the symbol table.
    for (intptr_t i = 1; i < symtab_->Length(); i++) {
      auto const symbol = symtab_->At(i);
      auto const name = strtab_->At(symbol->name_index);
      symbol_to_address_map.Insert({name, symbol->offset});
    }
  }

  // Need these to turn offsets into relocated addresses.
  auto const vm_start =
      symbol_to_address_map.LookupValue(kVmSnapshotInstructionsAsmSymbol);
  ASSERT(vm_start > 0);
  auto const isolate_start =
      symbol_to_address_map.LookupValue(kIsolateSnapshotInstructionsAsmSymbol);
  ASSERT(isolate_start > 0);
  auto const vm_text = FindSegmentForAddress(vm_start);
  ASSERT(vm_text != nullptr);
  auto const isolate_text = FindSegmentForAddress(isolate_start);
  ASSERT(isolate_text != nullptr);

  SnapshotTextObjectNamer namer(zone_);
  const auto& codes = dwarf_->codes();
  for (intptr_t i = 0; i < codes.length(); i++) {
    const auto& code = *codes[i];
    auto const name = namer.SnapshotNameFor(i, code);
    const auto& pair = dwarf_->CodeAddress(code);
    ASSERT(pair.offset > 0);
    auto const segment = pair.vm ? vm_text : isolate_text;
    const intptr_t address = segment->memory_offset() + pair.offset;
    auto const info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
    AddStaticSymbol(name, info, segment->section_index(), address, code.Size());
    symbol_to_address_map.Insert({name, address});
  }

  // TODO(rmacnak): Generate .debug_frame / .eh_frame / .arm.exidx to
  // provide unwinding information.

  {
    uint8_t* buffer = nullptr;
    WriteStream stream(&buffer, ZoneReallocate, kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream, symbol_to_address_map);
    dwarf_->WriteAbbreviations(&dwarf_stream);
    AddDebug(".debug_abbrev", buffer, stream.bytes_written());
  }

  {
    uint8_t* buffer = nullptr;
    WriteStream stream(&buffer, ZoneReallocate, kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream, symbol_to_address_map);
    dwarf_->WriteDebugInfo(&dwarf_stream);
    AddDebug(".debug_info", buffer, stream.bytes_written());
  }

  {
    uint8_t* buffer = nullptr;
    WriteStream stream(&buffer, ZoneReallocate, kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream, symbol_to_address_map);
    dwarf_->WriteLineNumberProgram(&dwarf_stream);
    AddDebug(".debug_line", buffer, stream.bytes_written());
  }
#endif
}

void Elf::Finalize() {
  FinalizeDwarfSections();

  // Unlike the static tables, we must wait until finalization to add the
  // dynamic tables, as adding them marks them as finalized.
  AddSection(dynstrtab_, ".dynstr");
  AddSection(dynsym_, ".dynsym");
  dynsym_->section_link = dynstrtab_->section_index();

  auto const hash = new (zone_) SymbolHashTable(dynstrtab_, dynsym_);
  AddSection(hash, ".hash");

  dynamic_ = new (zone_) DynamicTable(dynstrtab_, dynsym_, hash);
  AddSection(dynamic_, ".dynamic");

  // Also add a PT_DYNAMIC segment for the dynamic symbol table.
  dynamic_segment_ = new (zone_) DynamicSegment(dynamic_);
  segments_.Add(dynamic_segment_);

  // At this point, all sections and user-defined segments have been added. Add
  // any program table-specific segments and then calculate file offsets for all
  // sections and segments.
  FinalizeProgramTable();
  ComputeFileOffsets();

  // Finally, write the ELF file contents.
  ElfWriteStream wrapped(unwrapped_stream_);
  WriteHeader(&wrapped);
  WriteProgramTable(&wrapped);
  WriteSections(&wrapped);
  WriteSectionTable(&wrapped);
}

void Elf::FinalizeProgramTable() {
  ASSERT(program_table_file_size_ < 0);

  program_table_file_offset_ = kElfHeaderSize;

  // There are two segments we need the size of the program table to create, so
  // calculate it as if those two segments were already in place.
  program_table_file_size_ =
      (2 + segments_.length()) * kElfProgramTableEntrySize;

  // We pre-allocated the virtual memory space for the program table itself.
  // Check that we didn't generate too many segments. Currently we generate a
  // fixed num of segments based on the four pieces of a snapshot, but if we
  // use more in the future we'll likely need to do something more compilated
  // to generate DWARF without knowing a piece's virtual address in advance.
  auto const program_table_segment_size =
      program_table_file_offset_ + program_table_file_size_;
  RELEASE_ASSERT(program_table_segment_size < kProgramTableSegmentSize);

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  segments_.InsertAt(
      0, new (zone_) ProgramTableSelfSegment(program_table_file_offset_,
                                             program_table_file_size_));

  // Segment for loading the initial part of the ELF file, including the
  // program header table. Required by Android but not by Linux.
  segments_.InsertAt(
      1, new (zone_) ProgramTableLoadSegment(program_table_segment_size));
}

void Elf::ComputeFileOffsets() {
  // We calculate the size and offset of the program header table during
  // finalization.
  ASSERT(program_table_file_offset_ > 0 && program_table_file_size_ > 0);
  intptr_t file_offset = program_table_file_offset_ + program_table_file_size_;

  // The first (reserved) section's file offset is set to 0 during construction,
  // so skip it.
  ASSERT(sections_.length() >= 1 && sections_[0]->section_type == 0);
  // The others are output to the file in order after the program header table.
  for (intptr_t i = 1; i < sections_.length(); i++) {
    Section* section = sections_[i];
    file_offset = Utils::RoundUp(file_offset, section->alignment);
    section->set_file_offset(file_offset);
    file_offset += section->FileSize();
  }

  // Make the dynamic segment's file offset the same as the dynamic table now
  // that it's been calculated for the latter.
  dynamic_segment_->set_file_offset(dynamic_->file_offset());

  file_offset = Utils::RoundUp(file_offset, kElfSectionTableAlignment);
  section_table_file_offset_ = file_offset;
  section_table_file_size_ = sections_.length() * kElfSectionTableEntrySize;
  file_offset += section_table_file_size_;
}

void Elf::WriteHeader(ElfWriteStream* stream) {
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
  stream->WriteBytes(e_ident, 16);

  stream->WriteHalf(elf::ET_DYN);  // Shared library.

#if defined(TARGET_ARCH_IA32)
  stream->WriteHalf(elf::EM_386);
#elif defined(TARGET_ARCH_X64)
  stream->WriteHalf(elf::EM_X86_64);
#elif defined(TARGET_ARCH_ARM)
  stream->WriteHalf(elf::EM_ARM);
#elif defined(TARGET_ARCH_ARM64)
  stream->WriteHalf(elf::EM_AARCH64);
#else
  FATAL("Unknown ELF architecture");
#endif

  stream->WriteWord(elf::EV_CURRENT);  // Version
  stream->WriteAddr(0);                // "Entry point"
  stream->WriteOff(program_table_file_offset_);
  stream->WriteOff(section_table_file_offset_);

#if defined(TARGET_ARCH_ARM)
  uword flags = elf::EF_ARM_ABI | (TargetCPUFeatures::hardfp_supported()
                                       ? elf::EF_ARM_ABI_FLOAT_HARD
                                       : elf::EF_ARM_ABI_FLOAT_SOFT);
#else
  uword flags = 0;
#endif
  stream->WriteWord(flags);

  stream->WriteHalf(kElfHeaderSize);
  stream->WriteHalf(kElfProgramTableEntrySize);
  stream->WriteHalf(segments_.length());
  stream->WriteHalf(kElfSectionTableEntrySize);
  stream->WriteHalf(sections_.length());
  stream->WriteHalf(shstrtab_->section_index());

  ASSERT_EQUAL(stream->position(), kElfHeaderSize);
}

void Elf::WriteProgramTable(ElfWriteStream* stream) {
  ASSERT(program_table_file_size_ >= 0);  // Check for finalization.
  ASSERT(stream->position() == program_table_file_offset_);

  for (intptr_t i = 0; i < segments_.length(); i++) {
    Section* section = segments_[i];
    const intptr_t start = stream->position();
    section->WriteSegmentEntry(stream);
    const intptr_t end = stream->position();
    ASSERT_EQUAL(end - start, kElfProgramTableEntrySize);
  }
}

void Elf::WriteSectionTable(ElfWriteStream* stream) {
  ASSERT(section_table_file_size_ >= 0);  // Check for finalization.
  stream->Align(kElfSectionTableAlignment);
  ASSERT_EQUAL(stream->position(), section_table_file_offset_);

  for (intptr_t i = 0; i < sections_.length(); i++) {
    Section* section = sections_[i];
    const intptr_t start = stream->position();
    section->WriteSectionEntry(stream);
    const intptr_t end = stream->position();
    ASSERT_EQUAL(end - start, kElfSectionTableEntrySize);
  }
}

void Elf::WriteSections(ElfWriteStream* stream) {
  // Skip the reserved first section, as its alignment is 0 (which will cause
  // stream->Align() to fail) and it never contains file contents anyway.
  ASSERT_EQUAL(sections_[0]->section_type, elf::SHT_NULL);
  ASSERT_EQUAL(sections_[0]->alignment, 0);
  for (intptr_t i = 1; i < sections_.length(); i++) {
    Section* section = sections_[i];
    stream->Align(section->alignment);
    ASSERT(stream->position() == section->file_offset());
    section->Write(stream);
    ASSERT(stream->position() == section->file_offset() + section->FileSize());
  }
}

}  // namespace dart
