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

// A wrapper around BaseWriteStream that provides methods useful for
// writing ELF files (e.g., using ELF definitions of data sizes).
class ElfWriteStream : public ValueObject {
 public:
  explicit ElfWriteStream(BaseWriteStream* stream)
      : stream_(ASSERT_NOTNULL(stream)) {}

  intptr_t Position() const { return stream_->Position(); }
  void Align(const intptr_t alignment) {
    ASSERT(Utils::IsPowerOfTwo(alignment));
    stream_->Align(alignment);
  }
  void WriteBytes(const uint8_t* b, intptr_t size) {
    stream_->WriteBytes(b, size);
  }
  void WriteByte(uint8_t value) { stream_->WriteByte(value); }
  void WriteHalf(uint16_t value) { stream_->WriteFixed(value); }
  void WriteWord(uint32_t value) { stream_->WriteFixed(value); }
  void WriteAddr(compiler::target::uword value) { stream_->WriteFixed(value); }
  void WriteOff(compiler::target::uword value) { stream_->WriteFixed(value); }
#if defined(TARGET_ARCH_IS_64_BIT)
  void WriteXWord(uint64_t value) { stream_->WriteFixed(value); }
#endif

 private:
  BaseWriteStream* const stream_;
};

static constexpr intptr_t kLinearInitValue = -1;

#define DEFINE_LINEAR_FIELD_METHODS(name)                                      \
  intptr_t name() const {                                                      \
    ASSERT(name##_ != kLinearInitValue);                                       \
    return name##_;                                                            \
  }                                                                            \
  bool name##_is_set() const { return name##_ != kLinearInitValue; }           \
  void set_##name(intptr_t value) {                                            \
    ASSERT(value != kLinearInitValue);                                         \
    ASSERT_EQUAL(name##_, kLinearInitValue);                                   \
    name##_ = value;                                                           \
  }

#define DEFINE_LINEAR_FIELD(name) intptr_t name##_ = kLinearInitValue;

class BitsContainer;
class Segment;

static constexpr intptr_t kDefaultAlignment = -1;
// Align note sections and segments to 4 byte boundries.
static constexpr intptr_t kNoteAlignment = 4;

class Section : public ZoneAllocated {
 public:
  Section(elf::SectionHeaderType t,
          bool allocate,
          bool executable,
          bool writable,
          intptr_t align = kDefaultAlignment)
      : type(t),
        flags(EncodeFlags(allocate, executable, writable)),
        alignment(align == kDefaultAlignment ? DefaultAlignment(t) : align),
        // Non-segments will never have a memory offset, here represented by 0.
        memory_offset_(allocate ? kLinearInitValue : 0) {
    // Only sections with type SHT_NULL are allowed to have an alignment of 0.
    ASSERT(type == elf::SectionHeaderType::SHT_NULL || alignment > 0);
    // Non-zero alignments must be a power of 2.
    ASSERT(alignment == 0 || Utils::IsPowerOfTwo(alignment));
  }

  virtual ~Section() {}

  // Linker view.
  const elf::SectionHeaderType type;
  const intptr_t flags;
  const intptr_t alignment;

  // These are fields that only are not set for most kinds of sections and so we
  // set them to a reasonable default.
  intptr_t link = elf::SHN_UNDEF;
  intptr_t info = 0;
  intptr_t entry_size = 0;

#define FOR_EACH_SECTION_LINEAR_FIELD(M)                                       \
  M(name)                                                                      \
  M(index)                                                                     \
  M(file_offset)

  FOR_EACH_SECTION_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  virtual intptr_t FileSize() const = 0;

  // Loader view.
#define FOR_EACH_SEGMENT_LINEAR_FIELD(M) M(memory_offset)

  FOR_EACH_SEGMENT_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  // Each section belongs to at most one PT_LOAD segment.
  Segment* load_segment = nullptr;

  virtual intptr_t MemorySize() const = 0;

  // Other methods.

  bool IsAllocated() const {
    return (flags & elf::SHF_ALLOC) == elf::SHF_ALLOC;
  }
  bool IsExecutable() const {
    return (flags & elf::SHF_EXECINSTR) == elf::SHF_EXECINSTR;
  }
  bool IsWritable() const { return (flags & elf::SHF_WRITE) == elf::SHF_WRITE; }

  // Returns whether new content can be added to a section.
  bool HasBeenFinalized() const {
    if (IsAllocated()) {
      // The contents of a section that is allocated (part of a segment) must
      // not change after the section is added.
      return memory_offset_is_set();
    } else {
      // Unallocated sections can have new content added until we calculate
      // file offsets.
      return file_offset_is_set();
    }
  }

  virtual const BitsContainer* AsBitsContainer() const { return nullptr; }

  // Writes the file contents of the section.
  virtual void Write(ElfWriteStream* stream) = 0;

  virtual void WriteSectionHeader(ElfWriteStream* stream) {
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(name());
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteWord(flags);
    stream->WriteAddr(memory_offset());
    stream->WriteOff(file_offset());
    stream->WriteWord(FileSize());  // Has different meaning for BSS.
    stream->WriteWord(link);
    stream->WriteWord(info);
    stream->WriteWord(alignment);
    stream->WriteWord(entry_size);
#else
    stream->WriteWord(name());
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteXWord(flags);
    stream->WriteAddr(memory_offset());
    stream->WriteOff(file_offset());
    stream->WriteXWord(FileSize());  // Has different meaning for BSS.
    stream->WriteWord(link);
    stream->WriteWord(info);
    stream->WriteXWord(alignment);
    stream->WriteXWord(entry_size);
#endif
  }

 private:
  static intptr_t EncodeFlags(bool allocate, bool executable, bool writable) {
    if (!allocate) return 0;
    intptr_t flags = elf::SHF_ALLOC;
    if (executable) flags |= elf::SHF_EXECINSTR;
    if (writable) flags |= elf::SHF_WRITE;
    return flags;
  }

  static intptr_t DefaultAlignment(elf::SectionHeaderType type) {
    switch (type) {
      case elf::SectionHeaderType::SHT_SYMTAB:
      case elf::SectionHeaderType::SHT_DYNSYM:
      case elf::SectionHeaderType::SHT_HASH:
      case elf::SectionHeaderType::SHT_DYNAMIC:
        return compiler::target::kWordSize;
      default:
        return 1;
    }
  }

  FOR_EACH_SECTION_LINEAR_FIELD(DEFINE_LINEAR_FIELD);
  FOR_EACH_SEGMENT_LINEAR_FIELD(DEFINE_LINEAR_FIELD);

#undef FOR_EACH_SECTION_LINEAR_FIELD
#undef FOR_EACH_SEGMENT_LINEAR_FIELD
};

#undef DEFINE_LINEAR_FIELD
#undef DEFINE_LINEAR_FIELD_METHODS

class Segment : public ZoneAllocated {
 public:
  Segment(Zone* zone,
          Section* initial_section,
          elf::ProgramHeaderType segment_type)
      : type(segment_type),
        // Flags for the segment are the same as the initial section.
        flags(EncodeFlags(ASSERT_NOTNULL(initial_section)->IsExecutable(),
                          ASSERT_NOTNULL(initial_section)->IsWritable())),
        sections_(zone, 0) {
    // Unlike sections, we don't have a reserved segment with the null type,
    // so we never should pass this value.
    ASSERT(segment_type != elf::ProgramHeaderType::PT_NULL);
    // All segments should have at least one section. The first one is added
    // during initialization. Unlike others added later, it should already have
    // a memory offset since we use it to determine the segment memory offset.
    ASSERT(initial_section->IsAllocated());
    ASSERT(initial_section->memory_offset_is_set());
    // Make sure the memory offset chosen for the initial section is consistent
    // with the alignment for the segment.
    ASSERT(Utils::IsAligned(initial_section->memory_offset(), Alignment(type)));
    sections_.Add(initial_section);
    if (type == elf::ProgramHeaderType::PT_LOAD) {
      ASSERT(initial_section->load_segment == nullptr);
      initial_section->load_segment = this;
    }
  }

  virtual ~Segment() {}

  static intptr_t Alignment(elf::ProgramHeaderType segment_type) {
    switch (segment_type) {
      case elf::ProgramHeaderType::PT_PHDR:
      case elf::ProgramHeaderType::PT_DYNAMIC:
        return compiler::target::kWordSize;
      case elf::ProgramHeaderType::PT_NOTE:
        return kNoteAlignment;
      default:
        return Elf::kPageSize;
    }
  }

  bool IsExecutable() const { return (flags & elf::PF_X) == elf::PF_X; }
  bool IsWritable() const { return (flags & elf::PF_W) == elf::PF_W; }

  void WriteProgramHeader(ElfWriteStream* stream) {
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteOff(FileOffset());
    stream->WriteAddr(MemoryOffset());  // Virtual address.
    stream->WriteAddr(MemoryOffset());  // Physical address, not used.
    stream->WriteWord(FileSize());
    stream->WriteWord(MemorySize());
    stream->WriteWord(flags);
    stream->WriteWord(Alignment(type));
#else
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteWord(flags);
    stream->WriteOff(FileOffset());
    stream->WriteAddr(MemoryOffset());  // Virtual address.
    stream->WriteAddr(MemoryOffset());  // Physical address, not used.
    stream->WriteXWord(FileSize());
    stream->WriteXWord(MemorySize());
    stream->WriteXWord(Alignment(type));
#endif
  }

  // Adds the given section to this segment.
  //
  // Returns whether the Section could be added to the segment. If not, a
  // new segment will need to be created for this section.
  //
  // Sets the memory offset of the section if added.
  bool Add(Section* section) {
    // We only add additional sections to load segments.
    ASSERT(type == elf::ProgramHeaderType::PT_LOAD);
    ASSERT(section != nullptr);
    // Only sections with the allocate flag set should be added to segments,
    // and sections with already-set memory offsets cannot be added.
    ASSERT(section->IsAllocated());
    ASSERT(!section->memory_offset_is_set());
    ASSERT(section->load_segment == nullptr);
    switch (sections_.Last()->type) {
      // We only use SHT_NULL sections as pseudo sections that will not appear
      // in the final ELF file. Don't pack sections into these segments, as we
      // may remove/replace the segments during finalization.
      case elf::SectionHeaderType::SHT_NULL:
      // If the last section in the segments is NOBITS, then we don't add it,
      // as otherwise we'll be guaranteed the file offset and memory offset
      // won't be page aligned without padding.
      case elf::SectionHeaderType::SHT_NOBITS:
        return false;
      default:
        break;
    }
    // We don't add if the W or X bits don't match.
    if (IsExecutable() != section->IsExecutable() ||
        IsWritable() != section->IsWritable()) {
      return false;
    }
    auto const start_address = Utils::RoundUp(MemoryEnd(), section->alignment);
    section->set_memory_offset(start_address);
    sections_.Add(section);
    section->load_segment = this;
    return true;
  }

  void Replace(Section* old_section, Section* new_section) {
    ASSERT(old_section->load_segment == this);
    // All these must be true for replacement to be safe.
    ASSERT_EQUAL(static_cast<uint32_t>(old_section->type),
                 static_cast<uint32_t>(new_section->type));
    ASSERT_EQUAL(old_section->MemorySize(), new_section->MemorySize());
    ASSERT_EQUAL(old_section->IsExecutable(), new_section->IsExecutable());
    ASSERT_EQUAL(old_section->IsWritable(), new_section->IsWritable());
    ASSERT(old_section->memory_offset_is_set());
    ASSERT(!new_section->memory_offset_is_set());
    for (intptr_t i = 0; i < sections_.length(); i++) {
      auto const section = sections_[i];
      if (section != old_section) {
        continue;
      }
      new_section->set_memory_offset(old_section->memory_offset());
      sections_[i] = new_section;
      new_section->load_segment = this;
      old_section->load_segment = nullptr;
      return;
    }
    UNREACHABLE();
  }

  intptr_t FileOffset() const { return sections_[0]->file_offset(); }

  intptr_t FileSize() const {
    auto const last = sections_.Last();
    const intptr_t end = last->file_offset() + last->FileSize();
    return end - FileOffset();
  }

  intptr_t MemoryOffset() const { return sections_[0]->memory_offset(); }

  intptr_t MemorySize() const {
    auto const last = sections_.Last();
    const intptr_t end = last->memory_offset() + last->MemorySize();
    return end - MemoryOffset();
  }

  intptr_t MemoryEnd() const { return MemoryOffset() + MemorySize(); }

 private:
  static constexpr intptr_t kInitValue = -1;
  static_assert(kInitValue < 0, "init value must be negative");

  static intptr_t EncodeFlags(bool executable, bool writable) {
    intptr_t flags = elf::PF_R;
    if (executable) flags |= elf::PF_X;
    if (writable) flags |= elf::PF_W;
    return flags;
  }

 public:
  const elf::ProgramHeaderType type;
  const intptr_t flags;

 private:
  GrowableArray<const Section*> sections_;
};

// Represents the first entry in the section table, which should only contain
// zero values and does not correspond to a memory segment.
class ReservedSection : public Section {
 public:
  ReservedSection()
      : Section(elf::SectionHeaderType::SHT_NULL,
                /*allocate=*/false,
                /*executable=*/false,
                /*writable=*/false,
                /*alignment=*/0) {
    set_name(0);
    set_index(0);
    set_file_offset(0);
  }

  intptr_t FileSize() const { return 0; }
  intptr_t MemorySize() const { return 0; }
  void Write(ElfWriteStream* stream) {}
};

// Represents portions of the file/memory space which do not correspond to
// actual sections. Should never be added to sections_.
class PseudoSection : public Section {
 public:
  PseudoSection(bool executable,
                bool writable,
                intptr_t file_offset,
                intptr_t file_size,
                intptr_t memory_offset,
                intptr_t memory_size)
      : Section(elf::SectionHeaderType::SHT_NULL,
                /*allocate=*/true,
                executable,
                writable,
                /*alignment=*/0),
        file_size_(file_size),
        memory_size_(memory_size) {
    set_file_offset(file_offset);
    set_memory_offset(memory_offset);
  }

  intptr_t FileSize() const { return file_size_; }
  intptr_t MemorySize() const { return memory_size_; }
  void WriteSectionHeader(ElfWriteStream* stream) { UNREACHABLE(); }
  void Write(ElfWriteStream* stream) { UNREACHABLE(); }

 private:
  const intptr_t file_size_;
  const intptr_t memory_size_;
};

// A segment for representing the program header table self-reference in the
// program header table.
class ProgramTableSelfSegment : public Segment {
 public:
  ProgramTableSelfSegment(Zone* zone, intptr_t offset, intptr_t size)
      : Segment(zone,
                new (zone) PseudoSection(/*executable=*/false,
                                         /*writable=*/false,
                                         offset,
                                         size,
                                         offset,
                                         size),
                elf::ProgramHeaderType::PT_PHDR) {}
};

// A segment for representing the program header table load segment in the
// program header table.
class ProgramTableLoadSegment : public Segment {
 public:
  // The Android dynamic linker in Jelly Bean incorrectly assumes that all
  // non-writable segments are continguous. Since the BSS segment comes directly
  // after the program header segment, we must make this segment writable so
  // later non-writable segments does not cause the BSS to be also marked as
  // read-only.
  //
  // The bug is here:
  //   https://github.com/aosp-mirror/platform_bionic/blob/94963af28e445384e19775a838a29e6a71708179/linker/linker.c#L1991-L2001
  explicit ProgramTableLoadSegment(Zone* zone, intptr_t size)
      : Segment(zone,
                // This segment should always start at address 0.
                new (zone) PseudoSection(/*executable=*/false,
                                         /*writable=*/true,
                                         0,
                                         size,
                                         0,
                                         size),
                elf::ProgramHeaderType::PT_LOAD) {}
};

class BitsContainer : public Section {
 public:
  // Fully specified BitsContainer information.
  BitsContainer(elf::SectionHeaderType type,
                bool allocate,
                bool executable,
                bool writable,
                intptr_t size,
                const uint8_t* bytes,
                int alignment = kDefaultAlignment)
      : Section(type, allocate, executable, writable, alignment),
        file_size_(type == elf::SectionHeaderType::SHT_NOBITS ? 0 : size),
        memory_size_(allocate ? size : 0),
        bytes_(bytes) {
    ASSERT(type == elf::SectionHeaderType::SHT_NOBITS || bytes != nullptr);
  }

  // For BitsContainers used only as sections.
  BitsContainer(elf::SectionHeaderType type,
                intptr_t size,
                const uint8_t* bytes,
                intptr_t alignment = kDefaultAlignment)
      : BitsContainer(type,
                      /*allocate=*/false,
                      /*executable=*/false,
                      /*writable=*/false,
                      size,
                      bytes,
                      alignment) {}

  // For BitsContainers used as segments whose type differ on the type of the
  // ELF file. Creates an elf::SHT_PROGBITS section if type is Snapshot,
  // otherwise creates an elf::SHT_NOBITS section.
  BitsContainer(Elf::Type t,
                bool executable,
                bool writable,
                intptr_t size,
                const uint8_t* bytes,
                intptr_t alignment = kDefaultAlignment)
      : BitsContainer(t == Elf::Type::Snapshot
                          ? elf::SectionHeaderType::SHT_PROGBITS
                          : elf::SectionHeaderType::SHT_NOBITS,
                      /*allocate=*/true,
                      executable,
                      writable,
                      size,
                      bytes,
                      alignment) {}

  const BitsContainer* AsBitsContainer() const { return this; }

  void Write(ElfWriteStream* stream) {
    if (type != elf::SectionHeaderType::SHT_NOBITS) {
      stream->WriteBytes(bytes_, FileSize());
    }
  }

  intptr_t FileSize() const { return file_size_; }
  intptr_t MemorySize() const { return memory_size_; }
  const uint8_t* bytes() const { return bytes_; }

 private:
  const intptr_t file_size_;
  const intptr_t memory_size_;
  const uint8_t* const bytes_;
};

class StringTable : public Section {
 public:
  explicit StringTable(Zone* zone, bool allocate)
      : Section(elf::SectionHeaderType::SHT_STRTAB,
                allocate,
                /*executable=*/false,
                /*writable=*/false),
        dynamic_(allocate),
        text_(zone, 128),
        text_indices_(zone) {
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
    ASSERT(str != nullptr);
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
         intptr_t binding,
         intptr_t type,
         intptr_t section,
         intptr_t offset,
         intptr_t size)
      : name_index(name),
        binding(binding),
        type(type),
        section_index(section),
        offset(offset),
        size(size),
        cstr_(cstr) {}

  void Write(ElfWriteStream* stream) const {
    const intptr_t start = stream->Position();
    stream->WriteWord(name_index);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteAddr(offset);
    stream->WriteWord(size);
    stream->WriteByte(elf::SymbolInfo(binding, type));
    stream->WriteByte(0);
    stream->WriteHalf(section_index);
#else
    stream->WriteByte(elf::SymbolInfo(binding, type));
    stream->WriteByte(0);
    stream->WriteHalf(section_index);
    stream->WriteAddr(offset);
    stream->WriteXWord(size);
#endif
    ASSERT_EQUAL(stream->Position() - start, sizeof(elf::Symbol));
  }

  const intptr_t name_index;
  const intptr_t binding;
  const intptr_t type;
  const intptr_t section_index;
  const intptr_t offset;
  const intptr_t size;

 private:
  friend class SymbolHashTable;  // For cstr_ access.

  const char* const cstr_;
};

class SymbolTable : public Section {
 public:
  SymbolTable(Zone* zone, StringTable* table, bool dynamic)
      : Section(dynamic ? elf::SectionHeaderType::SHT_DYNSYM
                        : elf::SectionHeaderType::SHT_SYMTAB,
                dynamic,
                /*executable=*/false,
                /*writable=*/false),
        zone_(zone),
        table_(table),
        dynamic_(dynamic),
        symbols_(zone, 1),
        by_name_index_(zone) {
    entry_size = sizeof(elf::Symbol);
    // The first symbol table entry is reserved and must be all zeros.
    // (String tables always have the empty string at the 0th index.)
    AddSymbol("", elf::STB_LOCAL, elf::STT_NOTYPE, elf::SHN_UNDEF, /*offset=*/0,
              /*size=*/0);
  }

  intptr_t FileSize() const { return Length() * entry_size; }
  intptr_t MemorySize() const { return dynamic_ ? FileSize() : 0; }

  void Write(ElfWriteStream* stream) {
    for (intptr_t i = 0; i < Length(); i++) {
      auto const symbol = At(i);
      const intptr_t start = stream->Position();
      symbol->Write(stream);
      ASSERT_EQUAL(stream->Position() - start, entry_size);
    }
  }

  void AddSymbol(const char* name,
                 intptr_t binding,
                 intptr_t type,
                 intptr_t section_index,
                 intptr_t offset,
                 intptr_t size) {
    ASSERT(!table_->HasBeenFinalized());
    auto const name_index = table_->AddString(name);
    ASSERT(by_name_index_.Lookup(name_index) == nullptr);
    auto const symbol = new (zone_)
        Symbol(name, name_index, binding, type, section_index, offset, size);
    symbols_.Add(symbol);
    by_name_index_.Insert(name_index, symbol);
    // The info field on a symbol table section holds the index of the first
    // non-local symbol, so they can be skipped if desired. Thus, we need to
    // make sure local symbols are before any non-local ones.
    if (binding == elf::STB_LOCAL) {
      if (info != symbols_.length() - 1) {
        // There are non-local symbols, as otherwise [info] would be the
        // index of the new symbol. Since the order doesn't otherwise matter,
        // swap the new local symbol with the value at index [info], so when
        // [info] is incremented it will point just past the new local symbol.
        ASSERT(symbols_[info]->binding != elf::STB_LOCAL);
        symbols_.Swap(info, symbols_.length() - 1);
      }
      info += 1;
    }
  }
  intptr_t Length() const { return symbols_.length(); }
  const Symbol* At(intptr_t i) const { return symbols_[i]; }

  const Symbol* Find(const char* name) const {
    ASSERT(name != nullptr);
    auto const name_index = table_->Lookup(name);
    return by_name_index_.Lookup(name_index);
  }

 private:
  Zone* const zone_;
  StringTable* const table_;
  const bool dynamic_;
  GrowableArray<const Symbol*> symbols_;
  mutable IntMap<const Symbol*> by_name_index_;
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
  SymbolHashTable(Zone* zone, StringTable* strtab, SymbolTable* symtab)
      : Section(elf::SectionHeaderType::SHT_HASH,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/false) {
    link = symtab->index();
    entry_size = sizeof(int32_t);

    nchain_ = symtab->Length();
    nbucket_ = symtab->Length();

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

  intptr_t FileSize() const { return entry_size * (nbucket_ + nchain_ + 2); }
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
  DynamicTable(Zone* zone,
               StringTable* strtab,
               SymbolTable* symtab,
               SymbolHashTable* hash)
      : Section(elf::SectionHeaderType::SHT_DYNAMIC,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/true) {
    link = strtab->index();
    entry_size = sizeof(elf::DynamicEntry);

    AddEntry(zone, elf::DynamicEntryType::DT_HASH, hash->memory_offset());
    AddEntry(zone, elf::DynamicEntryType::DT_STRTAB, strtab->memory_offset());
    AddEntry(zone, elf::DynamicEntryType::DT_STRSZ, strtab->MemorySize());
    AddEntry(zone, elf::DynamicEntryType::DT_SYMTAB, symtab->memory_offset());
    AddEntry(zone, elf::DynamicEntryType::DT_SYMENT, sizeof(elf::Symbol));
    AddEntry(zone, elf::DynamicEntryType::DT_NULL, 0);
  }

  intptr_t FileSize() const { return entries_.length() * entry_size; }
  intptr_t MemorySize() const { return FileSize(); }

  void Write(ElfWriteStream* stream) {
    for (intptr_t i = 0; i < entries_.length(); i++) {
      entries_[i]->Write(stream);
    }
  }

  struct Entry : public ZoneAllocated {
    Entry(elf::DynamicEntryType tag, intptr_t value) : tag(tag), value(value) {}

    void Write(ElfWriteStream* stream) {
      const intptr_t start = stream->Position();
#if defined(TARGET_ARCH_IS_32_BIT)
      stream->WriteWord(static_cast<uint32_t>(tag));
      stream->WriteAddr(value);
#else
      stream->WriteXWord(static_cast<uint64_t>(tag));
      stream->WriteAddr(value);
#endif
      ASSERT_EQUAL(stream->Position() - start, sizeof(elf::DynamicEntry));
    }

    elf::DynamicEntryType tag;
    intptr_t value;
  };

  void AddEntry(Zone* zone, elf::DynamicEntryType tag, intptr_t value) {
    auto const entry = new (zone) Entry(tag, value);
    entries_.Add(entry);
  }

 private:
  GrowableArray<Entry*> entries_;
};

// A segment for representing the dynamic table segment in the program header
// table. There is no corresponding section for this segment.
class DynamicSegment : public Segment {
 public:
  explicit DynamicSegment(Zone* zone, DynamicTable* dynamic)
      : Segment(zone, dynamic, elf::ProgramHeaderType::PT_DYNAMIC) {}
};

// A segment for representing the dynamic table segment in the program header
// table. There is no corresponding section for this segment.
class NoteSegment : public Segment {
 public:
  NoteSegment(Zone* zone, Section* note)
      : Segment(zone, note, elf::ProgramHeaderType::PT_NOTE) {
    ASSERT_EQUAL(static_cast<uint32_t>(note->type),
                 static_cast<uint32_t>(elf::SectionHeaderType::SHT_NOTE));
  }
};

// We assume that the final program table fits in a single page of memory.
static constexpr intptr_t kProgramTableSegmentSize = Elf::kPageSize;

// Here, both VM and isolate will be compiled into a single snapshot.
// In assembly generation, each serialized text section gets a separate
// pointer into the BSS segment and BSS slots are created for each, since
// we may not serialize both VM and isolate. Here, we always serialize both,
// so make a BSS segment large enough for both, with the VM entries coming
// first.
static constexpr intptr_t kBssVmSize =
    BSS::kVmEntryCount * compiler::target::kWordSize;
static constexpr intptr_t kBssIsolateSize =
    BSS::kIsolateEntryCount * compiler::target::kWordSize;
static constexpr intptr_t kBssSize = kBssVmSize + kBssIsolateSize;

// For the build ID, we generate a 128-bit hash, where each 32 bits is a hash of
// the contents of the following segments in order:
//
// .text(VM) | .text(Isolate) | .rodata(VM) | .rodata(Isolate)
static constexpr const char* kBuildIdSegmentNames[]{
    kVmSnapshotInstructionsAsmSymbol,
    kIsolateSnapshotInstructionsAsmSymbol,
    kVmSnapshotDataAsmSymbol,
    kIsolateSnapshotDataAsmSymbol,
};
static constexpr intptr_t kBuildIdSegmentNamesLength =
    ARRAY_SIZE(kBuildIdSegmentNames);
// Includes the note name, but not the description.
static constexpr intptr_t kBuildIdHeaderSize =
    sizeof(elf::Note) + sizeof(elf::ELF_NOTE_GNU);

Elf::Elf(Zone* zone, BaseWriteStream* stream, Type type, Dwarf* dwarf)
    : zone_(zone),
      unwrapped_stream_(stream),
      type_(type),
      dwarf_(dwarf),
      bss_(CreateBSS(zone, type, kBssSize)),
      shstrtab_(new (zone) StringTable(zone, /*allocate=*/false)),
      dynstrtab_(new (zone) StringTable(zone, /*allocate=*/true)),
      dynsym_(new (zone) SymbolTable(zone, dynstrtab_, /*dynamic=*/true)) {
  // Separate debugging information should always have a Dwarf object.
  ASSERT(type_ == Type::Snapshot || dwarf_ != nullptr);
  // Assumed by various offset logic in this file.
  ASSERT_EQUAL(unwrapped_stream_->Position(), 0);
  // The first section in the section header table is always a reserved
  // entry containing only 0 values.
  sections_.Add(new (zone_) ReservedSection());
  if (!IsStripped()) {
    // Not a stripped ELF file, so allocate static string and symbol tables.
    strtab_ = new (zone_) StringTable(zone_, /* allocate= */ false);
    symtab_ = new (zone_) SymbolTable(zone, strtab_, /*dynamic=*/false);
  }
  // We add an initial segment to represent reserved space for the program
  // header, and so we can always assume there's at least one segment in the
  // segments_ array. We later remove this and replace it with appropriately
  // calculated segments in Elf::FinalizeProgramTable().
  auto const start_segment =
      new (zone_) ProgramTableLoadSegment(zone_, kProgramTableSegmentSize);
  segments_.Add(start_segment);
  // We allocate an initial build ID of all zeroes, since we need the build ID
  // memory offset for the InstructionsSection (see BlobImageWriter::WriteText).
  // We replace it with the real build ID during finalization. (We add this
  // prior to BSS because we make the BuildID section writable also, so they are
  // placed in the same segment before any non-writable ones, and if we add it
  // after, then in separate debugging information, it'll go into a separate
  // segment because the BSS section for debugging info is NOBITS.)
  {
    uint32_t zeroes[kBuildIdSegmentNamesLength] = {0};
    build_id_ = CreateBuildIdNote(&zeroes, sizeof(zeroes));
    AddSection(build_id_, kBuildIdNoteName, kSnapshotBuildIdAsmSymbol);
  }
  // Note that the BSS segment must be in the first user-defined segment because
  // it cannot be placed in between any two non-writable segments, due to a bug
  // in Jelly Bean's ELF loader. (For this reason, the program table segments
  // generated during finalization are marked as writable.) See also
  // Elf::WriteProgramTable().
  //
  // We add it in all cases, even to the separate debugging information ELF,
  // to ensure that relocated addresses are consistent between ELF snapshots
  // and ELF separate debugging information.
  auto const bss_start = AddSection(bss_, ".bss");
  // For the BSS section, we add two local symbols to the static symbol table,
  // one for each isolate. We use local symbols because these addresses are only
  // used for relocation. (This matches the behavior in the assembly output,
  // where these symbols are also local.)
  AddStaticSymbol(kVmSnapshotBssAsmSymbol, elf::STB_LOCAL, elf::STT_SECTION,
                  bss_->index(), bss_start, kBssVmSize);
  AddStaticSymbol(kIsolateSnapshotBssAsmSymbol, elf::STB_LOCAL,
                  elf::STT_SECTION, bss_->index(), bss_start + kBssVmSize,
                  kBssIsolateSize);
}

intptr_t Elf::NextMemoryOffset(intptr_t alignment) const {
  // Without more information, we won't know whether we might create a new
  // segment or put the section into the current one. Thus, for now, only allow
  // the offset to be queried ahead of time if it matches the load segment
  // alignment.
  auto const type = elf::ProgramHeaderType::PT_LOAD;
  ASSERT_EQUAL(alignment, Segment::Alignment(type));
  return Utils::RoundUp(LastLoadSegment()->MemoryEnd(), alignment);
}

uword Elf::SymbolAddress(const char* name) const {
  ASSERT(name != nullptr);
  // Check the static symbol table first if it exists, since the dynamic
  // table is a subset of it. Fall back on the dynamic otherwise.
  if (symtab_ != nullptr) {
    if (auto const symbol = symtab_->Find(name)) {
      return symbol->offset;
    }
  } else if (auto const symbol = dynsym_->Find(name)) {
    return symbol->offset;
  }
  // If stripping, then we won't have symbols for the BSS sections because
  // they're only added to the static symbol table. Check for these special
  // cases before returning kNoSectionStart.
  if (strcmp(name, kVmSnapshotBssAsmSymbol) == 0) {
    ASSERT(bss_ != nullptr);
    ASSERT(bss_->memory_offset_is_set());
    return bss_->memory_offset();
  } else if (strcmp(name, kIsolateSnapshotBssAsmSymbol) == 0) {
    ASSERT(bss_ != nullptr);
    ASSERT(bss_->memory_offset_is_set());
    return bss_->memory_offset() + kBssVmSize;
  }
  return kNoSectionStart;
}

intptr_t Elf::AddSection(Section* section,
                         const char* name,
                         const char* symbol_name) {
  ASSERT(section_table_file_size_ < 0);
  ASSERT(!shstrtab_->HasBeenFinalized());
  section->set_name(shstrtab_->AddString(name));
  section->set_index(sections_.length());
  sections_.Add(section);

  // No memory offset, so just return -1.
  if (!section->IsAllocated()) return -1;

  ASSERT(program_table_file_size_ < 0);
  auto const last_load = LastLoadSegment();
  if (!last_load->Add(section)) {
    // We can't add this section to the last load segment, so create a new one.
    // The new segment starts at the next aligned address.
    auto const type = elf::ProgramHeaderType::PT_LOAD;
    intptr_t alignment =
        Utils::Maximum(section->alignment, Segment::Alignment(type));
    auto const start_address =
        Utils::RoundUp(last_load->MemoryEnd(), alignment);
    section->set_memory_offset(start_address);
    auto const segment = new (zone_) Segment(zone_, section, type);
    segments_.Add(segment);
  }
  if (symbol_name != nullptr) {
    // While elf::STT_SECTION might seem more appropriate, section symbols are
    // usually local and dlsym won't return them.
    AddDynamicSymbol(symbol_name, elf::STB_GLOBAL, elf::STT_FUNC,
                     section->index(), section->memory_offset(),
                     section->MemorySize());
  }
  return section->memory_offset();
}

void Elf::ReplaceSection(Section* old_section, Section* new_section) {
  ASSERT(section_table_file_size_ < 0);
  ASSERT(old_section->index_is_set());
  ASSERT(!new_section->index_is_set());
  ASSERT_EQUAL(new_section->IsAllocated(), old_section->IsAllocated());
  new_section->set_name(old_section->name());
  new_section->set_index(old_section->index());
  sections_[old_section->index()] = new_section;

  if (!old_section->IsAllocated()) {
    return;
  }

  ASSERT(program_table_file_size_ < 0);
  ASSERT(old_section->load_segment != nullptr);
  old_section->load_segment->Replace(old_section, new_section);
}

intptr_t Elf::AddText(const char* name, const uint8_t* bytes, intptr_t size) {
  auto const image = new (zone_) BitsContainer(type_, /*executable=*/true,
                                               /*writable=*/false, size, bytes,
                                               ImageWriter::kTextAlignment);
  return AddSection(image, ".text", name);
}

Section* Elf::CreateBSS(Zone* zone, Type type, intptr_t size) {
  uint8_t* bytes = nullptr;
  if (type == Type::Snapshot) {
    // Ideally the BSS segment would take no space in the object, but Android's
    // "strip" utility truncates the memory-size of our segments to their
    // file-size.
    //
    // Therefore we must insert zero-filled pages for the BSS.
    bytes = zone->Alloc<uint8_t>(size);
    memset(bytes, 0, size);
  }
  return new (zone) BitsContainer(type, /*executable=*/false, /*writable=*/true,
                                  kBssSize, bytes, ImageWriter::kBssAlignment);
}

intptr_t Elf::AddROData(const char* name, const uint8_t* bytes, intptr_t size) {
  auto const image = new (zone_) BitsContainer(type_, /*executable=*/false,
                                               /*writable=*/false, size, bytes,
                                               ImageWriter::kRODataAlignment);
  return AddSection(image, ".rodata", name);
}

void Elf::AddDebug(const char* name, const uint8_t* bytes, intptr_t size) {
  ASSERT(!IsStripped());
  ASSERT(bytes != nullptr);
  auto const image = new (zone_)
      BitsContainer(elf::SectionHeaderType::SHT_PROGBITS, size, bytes);
  AddSection(image, name);
}

void Elf::AddLocalSymbol(const char* name,
                         intptr_t type,
                         intptr_t offset,
                         intptr_t size) {
  const intptr_t section_index = sections_.length();
  // Assume the next section will go into its own segment (currently true
  // because we write writable sections, data vm (non-writable, non-executable),
  // text vm (executable), data isolate (non-executable), text isolate
  // (executable), and we only call this for data and text sections).
  const intptr_t address =
      NextMemoryOffset(ImageWriter::kTextAlignment) + offset;
  AddStaticSymbol(name, elf::STB_LOCAL, type, section_index, address, size);
}

void Elf::AddDynamicSymbol(const char* name,
                           intptr_t binding,
                           intptr_t type,
                           intptr_t section_index,
                           intptr_t address,
                           intptr_t size) {
  ASSERT(!dynsym_->HasBeenFinalized());
  dynsym_->AddSymbol(name, binding, type, section_index, address, size);

  // Some tools assume the static symbol table is a superset of the dynamic
  // symbol table when it exists (see dartbug.com/41783).
  AddStaticSymbol(name, binding, type, section_index, address, size);
}

void Elf::AddStaticSymbol(const char* name,
                          intptr_t binding,
                          intptr_t type,
                          intptr_t section_index,
                          intptr_t address,
                          intptr_t size) {
  if (IsStripped()) return;  // No static info kept in stripped ELF files.
  ASSERT(!symtab_->HasBeenFinalized());
  symtab_->AddSymbol(name, binding, type, section_index, address, size);
}

#if defined(DART_PRECOMPILER)
class DwarfElfStream : public DwarfWriteStream {
 public:
  explicit DwarfElfStream(Zone* zone,
                          NonStreamingWriteStream* stream,
                          const SymbolTable* table)
      : zone_(ASSERT_NOTNULL(zone)),
        stream_(ASSERT_NOTNULL(stream)),
        table_(table) {}

  void sleb128(intptr_t value) { stream_->WriteSLEB128(value); }
  void uleb128(uintptr_t value) { stream_->WriteLEB128(value); }
  void u1(uint8_t value) { stream_->WriteByte(value); }
  void u2(uint16_t value) { stream_->WriteFixed(value); }
  void u4(uint32_t value) { stream_->WriteFixed(value); }
  void u8(uint64_t value) { stream_->WriteFixed(value); }
  void string(const char* cstr) {  // NOLINT
    // Unlike stream_->WriteString(), we want the null terminator written.
    stream_->WriteBytes(cstr, strlen(cstr) + 1);
  }
  intptr_t ReserveSize(const char* prefix, intptr_t* start) {
    ASSERT(start != nullptr);
    intptr_t fixup = stream_->Position();
    // We assume DWARF v2, so all sizes are 32-bit.
    u4(0);
    // All sizes for DWARF sections measure the size of the section data _after_
    // the size value.
    *start = stream_->Position();
    return fixup;
  }
  void SetSize(intptr_t fixup, const char* prefix, intptr_t start) {
    const intptr_t old_position = stream_->Position();
    stream_->SetPosition(fixup);
    stream_->WriteFixed(static_cast<uint32_t>(old_position - start));
    stream_->SetPosition(old_position);
  }
  void OffsetFromSymbol(const char* symbol, intptr_t offset) {
    addr(RelocatedAddress(symbol, offset));
  }
  void DistanceBetweenSymbolOffsets(const char* symbol1,
                                    intptr_t offset1,
                                    const char* symbol2,
                                    intptr_t offset2) {
    auto const address1 = RelocatedAddress(symbol1, offset1);
    auto const address2 = RelocatedAddress(symbol2, offset2);
    RELEASE_ASSERT(address1 >= address2);
    auto const delta = address1 - address2;
    uleb128(delta);
  }
  void InitializeAbstractOrigins(intptr_t size) {
    abstract_origins_size_ = size;
    abstract_origins_ = zone_->Alloc<uint32_t>(abstract_origins_size_);
  }
  void RegisterAbstractOrigin(intptr_t index) {
    ASSERT(abstract_origins_ != nullptr);
    ASSERT(index < abstract_origins_size_);
    abstract_origins_[index] = stream_->Position();
  }
  void AbstractOrigin(intptr_t index) { u4(abstract_origins_[index]); }

 private:
  uword RelocatedAddress(const char* name, intptr_t offset) {
    auto const symbol = table_->Find(name);
    ASSERT(symbol != nullptr);
    return symbol->offset + offset;
  }

  void addr(uword value) {
#if defined(TARGET_ARCH_IS_32_BIT)
    u4(value);
#else
    u8(value);
#endif
  }

  Zone* const zone_;
  NonStreamingWriteStream* const stream_;
  const SymbolTable* table_;
  uint32_t* abstract_origins_ = nullptr;
  intptr_t abstract_origins_size_ = -1;

  DISALLOW_COPY_AND_ASSIGN(DwarfElfStream);
};

static constexpr intptr_t kInitialDwarfBufferSize = 64 * KB;
#endif

Segment* Elf::LastLoadSegment() const {
  for (intptr_t i = segments_.length() - 1; i >= 0; i--) {
    auto const segment = segments_.At(i);
    if (segment->type == elf::ProgramHeaderType::PT_LOAD) {
      return segment;
    }
  }
  // There should always be a load segment, since one is added in construction.
  UNREACHABLE();
}

const Section* Elf::FindSectionForAddress(intptr_t address) const {
  for (auto const section : sections_) {
    if (!section->IsAllocated()) continue;
    auto const start = section->memory_offset();
    auto const end = start + section->MemorySize();
    if (address >= start && address < end) {
      return section;
    }
  }
  return nullptr;
}

void Elf::FinalizeDwarfSections() {
  if (dwarf_ == nullptr) return;
#if defined(DART_PRECOMPILER)
  {
    ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
    // We can use symtab_ without checking because this is an unstripped
    // snapshot or separate debugging information, both of which have static
    // symbol tables, and the static symbol table is a superset of the dynamic.
    DwarfElfStream dwarf_stream(zone_, &stream, symtab_);
    dwarf_->WriteAbbreviations(&dwarf_stream);
    AddDebug(".debug_abbrev", stream.buffer(), stream.bytes_written());
  }

  {
    ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream, symtab_);
    dwarf_->WriteDebugInfo(&dwarf_stream);
    AddDebug(".debug_info", stream.buffer(), stream.bytes_written());
  }

  {
    ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream, symtab_);
    dwarf_->WriteLineNumberProgram(&dwarf_stream);
    AddDebug(".debug_line", stream.buffer(), stream.bytes_written());
  }
#endif
}

void Elf::Finalize() {
  if (auto const new_build_id = GenerateFinalBuildId()) {
    ReplaceSection(build_id_, new_build_id);

    // Add a PT_NOTE segment for the build ID.
    segments_.Add(new (zone_) NoteSegment(zone_, new_build_id));
  }

  // Adding the dynamic symbol table and associated sections.
  AddSection(dynstrtab_, ".dynstr");
  AddSection(dynsym_, ".dynsym");
  dynsym_->link = dynstrtab_->index();

  auto const hash = new (zone_) SymbolHashTable(zone_, dynstrtab_, dynsym_);
  AddSection(hash, ".hash");

  auto const dynamic =
      new (zone_) DynamicTable(zone_, dynstrtab_, dynsym_, hash);
  AddSection(dynamic, ".dynamic");

  // Add a PT_DYNAMIC segment for the dynamic symbol table.
  segments_.Add(new (zone_) DynamicSegment(zone_, dynamic));

  // Currently, we add all (non-reserved) unallocated sections after all
  // allocated sections. If we put unallocated sections between allocated
  // sections, they would affect the file offset but not the memory offset
  // of the later allocated sections.
  //
  // However, memory offsets must be page-aligned to the file offset for the
  // ELF file to be successfully loaded. This means we'd either have to add
  // extra padding _or_ determine file offsets before memory offsets. The
  // latter would require us to handle BSS relocations during ELF finalization,
  // instead of while writing the .text section content.
  if (!IsStripped()) {
    AddSection(strtab_, ".strtab");
    AddSection(symtab_, ".symtab");
    symtab_->link = strtab_->index();
  }
  AddSection(shstrtab_, ".shstrtab");
  FinalizeDwarfSections();

  // At this point, all non-programmatically calculated sections and segments
  // have been added. Add any programatically calculated sections and segments
  // and then calculate file offsets.
  FinalizeProgramTable();
  ComputeFileOffsets();

  // Finally, write the ELF file contents.
  ElfWriteStream wrapped(unwrapped_stream_);
  WriteHeader(&wrapped);
  WriteProgramTable(&wrapped);
  WriteSections(&wrapped);
  WriteSectionTable(&wrapped);
}

static uint32_t HashBitsContainer(const BitsContainer* bits) {
  uint32_t hash = 0;
  auto const size = bits->MemorySize();
  if (bits->bytes() == nullptr) {
    // Just hash the size as a fallback if this section has no contents.
    return FinalizeHash(size, 32);
  }
  auto const end = bits->bytes() + size;
  auto const non_word_size = size % kWordSize;
  auto const end_of_words =
      reinterpret_cast<const uword*>(bits->bytes() + (size - non_word_size));
  for (auto cursor = reinterpret_cast<const uword*>(bits->bytes());
       cursor < end_of_words; cursor++) {
    hash = CombineHashes(hash, *cursor);
  }
  for (auto cursor = reinterpret_cast<const uint8_t*>(end_of_words);
       cursor < end; cursor++) {
    hash = CombineHashes(hash, *cursor);
  }
  return FinalizeHash(hash, 32);
}

Section* Elf::GenerateFinalBuildId() {
  uint32_t hashes[kBuildIdSegmentNamesLength];
  for (intptr_t i = 0; i < kBuildIdSegmentNamesLength; i++) {
    auto const name = kBuildIdSegmentNames[i];
    auto const symbol = dynsym_->Find(name);
    if (symbol == nullptr) {
      // If we're missing a section, then we don't generate a final build ID.
      return nullptr;
    }
    auto const bits = sections_[symbol->section_index]->AsBitsContainer();
    if (bits == nullptr) {
      FATAL1("Section for symbol %s is not a BitsContainer", name);
    }
    if (bits->bytes() == nullptr) {
      // For now, if we don't have section contents (because we're generating
      // assembly), don't generate a final build ID, as we'll have different
      // build IDs in the snapshot and the separate debugging information.
      //
      // TODO(dartbug.com/43274): Change once we generate consistent build IDs
      // between assembly snapshots and their debugging information.
      return nullptr;
    }
    ASSERT_EQUAL(bits->MemorySize(), symbol->size);
    hashes[i] = HashBitsContainer(bits);
  }
  // To ensure we can quickly check for a final build ID, we ensure the first
  // byte contains a non-zero value.
  auto const bytes = reinterpret_cast<uint8_t*>(hashes);
  if (bytes[0] == 0) {
    bytes[0] = 1;
  }
  return CreateBuildIdNote(&hashes, sizeof(hashes));
}

Section* Elf::CreateBuildIdNote(const void* description_bytes,
                                intptr_t description_length) {
  ASSERT(description_length == 0 || description_bytes != nullptr);
  ZoneWriteStream stream(zone(), kBuildIdHeaderSize + description_length);
  stream.WriteFixed<decltype(elf::Note::name_size)>(sizeof(elf::ELF_NOTE_GNU));
  stream.WriteFixed<decltype(elf::Note::description_size)>(description_length);
  stream.WriteFixed<decltype(elf::Note::type)>(elf::NoteType::NT_GNU_BUILD_ID);
  ASSERT_EQUAL(stream.Position(), sizeof(elf::Note));
  stream.WriteBytes(elf::ELF_NOTE_GNU, sizeof(elf::ELF_NOTE_GNU));
  ASSERT_EQUAL(stream.bytes_written(), kBuildIdHeaderSize);
  stream.WriteBytes(description_bytes, description_length);
  // While the build ID section does not need to be writable, it and the
  // BSS section are allocated segments at the same time. Having the same flags
  // ensures they will be combined in the same segment and not unnecessarily
  // aligned into a new page.
  return new (zone_) BitsContainer(elf::SectionHeaderType::SHT_NOTE,
                                   /*allocate=*/true, /*executable=*/false,
                                   /*writable=*/true, stream.bytes_written(),
                                   stream.buffer(), kNoteAlignment);
}

void Elf::FinalizeProgramTable() {
  ASSERT(program_table_file_size_ < 0);

  program_table_file_offset_ = sizeof(elf::ElfHeader);

  // There are two segments we need the size of the program table to create, so
  // calculate it as if those two segments were already in place.
  program_table_file_size_ =
      (2 + segments_.length()) * sizeof(elf::ProgramHeader);

  // We pre-allocated the virtual memory space for the program table itself.
  // Check that we didn't generate too many segments. Currently we generate a
  // fixed num of segments based on the four pieces of a snapshot, but if we
  // use more in the future we'll likely need to do something more compilated
  // to generate DWARF without knowing a piece's virtual address in advance.
  auto const program_table_segment_size =
      program_table_file_offset_ + program_table_file_size_;
  RELEASE_ASSERT(program_table_segment_size < kProgramTableSegmentSize);

  // Remove the original stand-in segment we added in the constructor.
  segments_.EraseAt(0);

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  segments_.InsertAt(
      0, new (zone_) ProgramTableSelfSegment(zone_, program_table_file_offset_,
                                             program_table_file_size_));

  // Segment for loading the initial part of the ELF file, including the
  // program header table. Required by Android but not by Linux.
  segments_.InsertAt(1, new (zone_) ProgramTableLoadSegment(
                            zone_, program_table_segment_size));
}

static const intptr_t kElfSectionTableAlignment = compiler::target::kWordSize;

void Elf::ComputeFileOffsets() {
  // We calculate the size and offset of the program header table during
  // finalization.
  ASSERT(program_table_file_offset_ > 0 && program_table_file_size_ > 0);
  intptr_t file_offset = program_table_file_offset_ + program_table_file_size_;
  // When calculating file offsets for sections, we'll need to know if we've
  // changed segments. Start with the one for the program table.
  const auto* current_segment = segments_[1];

  // The non-reserved sections are output to the file in order after the program
  // header table. If we're entering a new segment, then we need to align
  // according to the PT_LOAD segment alignment as well to keep the file offsets
  // aligned with the memory addresses.
  auto const load_align = Segment::Alignment(elf::ProgramHeaderType::PT_LOAD);
  for (intptr_t i = 1; i < sections_.length(); i++) {
    auto const section = sections_[i];
    file_offset = Utils::RoundUp(file_offset, section->alignment);
    if (section->IsAllocated() && section->load_segment != current_segment) {
      file_offset = Utils::RoundUp(file_offset, load_align);
      current_segment = section->load_segment;
    }
    section->set_file_offset(file_offset);
#if defined(DEBUG)
    if (section->IsAllocated()) {
      // For files that will be dynamically loaded, make sure the file offsets
      // of allocated sections are page aligned to the memory offsets.
      ASSERT_EQUAL(section->file_offset() % load_align,
                   section->memory_offset() % load_align);
    }
#endif
    file_offset += section->FileSize();
  }

  file_offset = Utils::RoundUp(file_offset, kElfSectionTableAlignment);
  section_table_file_offset_ = file_offset;
  section_table_file_size_ = sections_.length() * sizeof(elf::SectionHeader);
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

  stream->WriteHalf(sizeof(elf::ElfHeader));
  stream->WriteHalf(sizeof(elf::ProgramHeader));
  stream->WriteHalf(segments_.length());
  stream->WriteHalf(sizeof(elf::SectionHeader));
  stream->WriteHalf(sections_.length());
  stream->WriteHalf(shstrtab_->index());

  ASSERT_EQUAL(stream->Position(), sizeof(elf::ElfHeader));
}

void Elf::WriteProgramTable(ElfWriteStream* stream) {
  ASSERT(program_table_file_size_ >= 0);  // Check for finalization.
  ASSERT(stream->Position() == program_table_file_offset_);
#if defined(DEBUG)
  // Here, we count the number of times that a PT_LOAD writable segment is
  // followed by a non-writable segment. We initialize last_writable to true so
  // that we catch the case where the first segment is non-writable.
  bool last_writable = true;
  int non_writable_groups = 0;
#endif
  for (auto const segment : segments_) {
#if defined(DEBUG)
    if (segment->type == elf::ProgramHeaderType::PT_LOAD) {
      if (last_writable && !segment->IsWritable()) {
        non_writable_groups++;
      }
      last_writable = segment->IsWritable();
    }
#endif
    const intptr_t start = stream->Position();
    segment->WriteProgramHeader(stream);
    const intptr_t end = stream->Position();
    ASSERT_EQUAL(end - start, sizeof(elf::ProgramHeader));
  }
#if defined(DEBUG)
  // All PT_LOAD non-writable segments must be contiguous. If not, some older
  // Android dynamic linkers fail to handle writable segments between
  // non-writable ones. See https://github.com/flutter/flutter/issues/43259.
  ASSERT(non_writable_groups <= 1);
#endif
}

void Elf::WriteSectionTable(ElfWriteStream* stream) {
  ASSERT(section_table_file_size_ >= 0);  // Check for finalization.
  stream->Align(kElfSectionTableAlignment);
  ASSERT_EQUAL(stream->Position(), section_table_file_offset_);

  for (auto const section : sections_) {
    const intptr_t start = stream->Position();
    section->WriteSectionHeader(stream);
    const intptr_t end = stream->Position();
    ASSERT_EQUAL(end - start, sizeof(elf::SectionHeader));
  }
}

void Elf::WriteSections(ElfWriteStream* stream) {
  ASSERT(section_table_file_size_ >= 0);  // Check for finalization.

  // Skip the reserved first section, as its alignment is 0 (which will cause
  // stream->Align() to fail) and it never contains file contents anyway.
  ASSERT_EQUAL(static_cast<uint32_t>(sections_[0]->type),
               static_cast<uint32_t>(elf::SectionHeaderType::SHT_NULL));
  ASSERT_EQUAL(sections_[0]->alignment, 0);
  auto const load_align = Segment::Alignment(elf::ProgramHeaderType::PT_LOAD);
  const Segment* current_segment = segments_[1];
  for (intptr_t i = 1; i < sections_.length(); i++) {
    Section* section = sections_[i];
    stream->Align(section->alignment);
    if (section->IsAllocated() && section->load_segment != current_segment) {
      // Changing segments, so align accordingly.
      stream->Align(load_align);
      current_segment = section->load_segment;
    }
    ASSERT_EQUAL(stream->Position(), section->file_offset());
    section->Write(stream);
    ASSERT_EQUAL(stream->Position(),
                 section->file_offset() + section->FileSize());
  }
}

}  // namespace dart
