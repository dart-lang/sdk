// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/elf.h"

#include "platform/elf.h"
#include "vm/cpu.h"
#include "vm/dwarf.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"
#include "vm/zone_text_buffer.h"

namespace dart {

#if defined(DART_PRECOMPILER)

// A wrapper around BaseWriteStream that provides methods useful for
// writing ELF files (e.g., using ELF definitions of data sizes).
class ElfWriteStream : public ValueObject {
 public:
  explicit ElfWriteStream(BaseWriteStream* stream, const Elf& elf)
      : stream_(ASSERT_NOTNULL(stream)), elf_(elf) {}

  // Subclasses of Section may need to query the Elf object during Write(),
  // so we store it in the ElfWriteStream for easy access.
  const Elf& elf() const { return elf_; }

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
  const Elf& elf_;
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
  const char* symbol_name = nullptr;

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

  // Returns whether the size of a section can change.
  bool HasBeenFinalized() const {
    // Sections can grow or shrink up until Elf::ComputeOffsets has been run,
    // which sets the file offset (and memory offset for allocated sections).
    return file_offset_is_set();
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
    // All segments should have at least one section.
    ASSERT(initial_section->IsAllocated());
    sections_.Add(initial_section);
    if (type == elf::ProgramHeaderType::PT_LOAD) {
      ASSERT(initial_section->load_segment == nullptr);
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

  // Adds a given section to the end of this segment. Returns whether the
  // section was successfully added.
  bool Add(Section* section) {
    ASSERT(section != nullptr);
    // We only add additional sections to load segments.
    ASSERT(type == elf::ProgramHeaderType::PT_LOAD);
    // Don't use this to change a section's segment.
    ASSERT(section->load_segment == nullptr);
    // We only add sections with the same executable and writable bits.
    if (IsExecutable() != section->IsExecutable() ||
        IsWritable() != section->IsWritable()) {
      return false;
    }
    sections_.Add(section);
    section->load_segment = this;
    return true;
  }

  bool Merge(Segment* other) {
    ASSERT(other != nullptr);
    // We only add additional sections to load segments.
    ASSERT(type == elf::ProgramHeaderType::PT_LOAD);
    // We only merge segments with the same executable and writable bits.
    if (IsExecutable() != other->IsExecutable() ||
        IsWritable() != other->IsWritable()) {
      return false;
    }
    for (auto* section : other->sections_) {
      // Don't merge segments where the memory offsets have already been
      // calculated.
      ASSERT(!section->memory_offset_is_set());
      sections_.Add(section);
      section->load_segment = this;
    }
    return true;
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
  GrowableArray<Section*> sections_;
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
    AddString("");
  }

  intptr_t FileSize() const { return text_.length(); }
  intptr_t MemorySize() const { return dynamic_ ? FileSize() : 0; }

  void Write(ElfWriteStream* stream) {
    stream->WriteBytes(reinterpret_cast<const uint8_t*>(text_.buffer()),
                       text_.length());
  }

  intptr_t AddString(const char* str) {
    ASSERT(str != nullptr);
    if (auto const kv = text_indices_.Lookup(str)) {
      return kv->value;
    }
    intptr_t offset = text_.length();
    text_.AddString(str);
    text_.AddChar('\0');
    text_indices_.Insert({str, offset});
    return offset;
  }

  const char* At(intptr_t index) {
    ASSERT(index < text_.length());
    return text_.buffer() + index;
  }

  static const intptr_t kNotIndexed = CStringIntMapKeyValueTrait::kNoValue;

  // Returns the index of |str| if it is present in the string table
  // and |kNotIndexed| otherwise.
  intptr_t Lookup(const char* str) const {
    return text_indices_.LookupValue(str);
  }

  const bool dynamic_;
  ZoneTextBuffer text_;
  CStringIntMap text_indices_;
};

class Symbol : public ZoneAllocated {
 public:
  Symbol(const char* cstr,
         intptr_t name,
         intptr_t binding,
         intptr_t type,
         intptr_t initial_section_index,
         intptr_t size)
      : name_index(name),
        binding(binding),
        type(type),
        size(size),
        section_index(initial_section_index),
        cstr_(cstr) {}

  void Finalize(intptr_t final_section_index, intptr_t offset) {
    ASSERT(!HasBeenFinalized());  // No symbol should be re-finalized.
    section_index = final_section_index;
    offset_ = offset;
  }
  bool HasBeenFinalized() const { return offset_ != kNotFinalizedMarker; }
  intptr_t offset() const {
    ASSERT(HasBeenFinalized());
    // Only the reserved initial symbol should have an offset of 0.
    ASSERT_EQUAL(type == elf::STT_NOTYPE, offset_ == 0);
    return offset_;
  }

  void Write(ElfWriteStream* stream) const {
    const intptr_t start = stream->Position();
    stream->WriteWord(name_index);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteAddr(offset());
    stream->WriteWord(size);
    stream->WriteByte(elf::SymbolInfo(binding, type));
    stream->WriteByte(0);
    stream->WriteHalf(section_index);
#else
    stream->WriteByte(elf::SymbolInfo(binding, type));
    stream->WriteByte(0);
    stream->WriteHalf(section_index);
    stream->WriteAddr(offset());
    stream->WriteXWord(size);
#endif
    ASSERT_EQUAL(stream->Position() - start, sizeof(elf::Symbol));
  }

  const intptr_t name_index;
  const intptr_t binding;
  const intptr_t type;
  const intptr_t size;
  // Is set twice: once in Elf::AddSection to the section's initial index into
  // sections_, and then in Elf::FinalizeSymbols to the section's final index
  // into sections_ after reordering.
  intptr_t section_index;

 private:
  static const intptr_t kNotFinalizedMarker = -1;

  const char* const cstr_;
  intptr_t offset_ = kNotFinalizedMarker;

  friend class SymbolHashTable;  // For cstr_ access.
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
    const char* const kReservedName = "";
    AddSymbol(kReservedName, elf::STB_LOCAL, elf::STT_NOTYPE, elf::SHN_UNDEF,
              /*size=*/0);
    FinalizeSymbol(kReservedName, elf::SHN_UNDEF, /*offset=*/0);
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
                 intptr_t size) {
    ASSERT(!table_->HasBeenFinalized());
    auto const name_index = table_->AddString(name);
    ASSERT(by_name_index_.Lookup(name_index) == nullptr);
    auto const symbol = new (zone_)
        Symbol(name, name_index, binding, type, section_index, size);
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

  void FinalizeSymbol(const char* name,
                      intptr_t final_section_index,
                      intptr_t offset) {
    const intptr_t name_index = table_->Lookup(name);
    ASSERT(name_index != StringTable::kNotIndexed);
    Symbol* symbol = by_name_index_.Lookup(name_index);
    ASSERT(symbol != nullptr);
    symbol->Finalize(final_section_index, offset);
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
  GrowableArray<Symbol*> symbols_;
  mutable IntMap<Symbol*> by_name_index_;
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
  explicit DynamicTable(Zone* zone)
      : Section(elf::SectionHeaderType::SHT_DYNAMIC,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/true) {
    entry_size = sizeof(elf::DynamicEntry);

    // Entries that are not constants are fixed during Elf::Finalize().
    AddEntry(zone, elf::DynamicEntryType::DT_HASH, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_STRTAB, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_STRSZ, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_SYMTAB, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_SYMENT, sizeof(elf::Symbol));
    AddEntry(zone, elf::DynamicEntryType::DT_NULL, 0);
  }

  static constexpr intptr_t kInvalidEntry = -1;

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
      ASSERT(value != kInvalidEntry);
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

  void FinalizeEntry(elf::DynamicEntryType tag, intptr_t value) {
    for (auto* entry : entries_) {
      if (entry->tag == tag) {
        entry->value = value;
        break;
      }
    }
  }

  void FinalizeEntries(StringTable* strtab,
                       SymbolTable* symtab,
                       SymbolHashTable* hash) {
    FinalizeEntry(elf::DynamicEntryType::DT_HASH, hash->memory_offset());
    FinalizeEntry(elf::DynamicEntryType::DT_STRTAB, strtab->memory_offset());
    FinalizeEntry(elf::DynamicEntryType::DT_STRSZ, strtab->MemorySize());
    FinalizeEntry(elf::DynamicEntryType::DT_SYMTAB, symtab->memory_offset());
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

class BitsContainer : public Section {
 public:
  // Fully specified BitsContainer information.
  BitsContainer(elf::SectionHeaderType type,
                bool allocate,
                bool executable,
                bool writable,
                intptr_t size,
                const uint8_t* bytes,
                const ZoneGrowableArray<Elf::Relocation>* relocations,
                const ZoneGrowableArray<Elf::SymbolData>* symbols,
                int alignment = kDefaultAlignment)
      : Section(type, allocate, executable, writable, alignment),
        file_size_(type == elf::SectionHeaderType::SHT_NOBITS ? 0 : size),
        memory_size_(allocate ? size : 0),
        bytes_(bytes),
        relocations_(relocations),
        symbols_(symbols) {
    ASSERT(type == elf::SectionHeaderType::SHT_NOBITS || bytes != nullptr);
  }

  // For BitsContainers used only as sections.
  BitsContainer(elf::SectionHeaderType type,
                intptr_t size,
                const uint8_t* bytes,
                const ZoneGrowableArray<Elf::Relocation>* relocations,
                const ZoneGrowableArray<Elf::SymbolData>* symbols,
                intptr_t alignment = kDefaultAlignment)
      : BitsContainer(type,
                      /*allocate=*/false,
                      /*executable=*/false,
                      /*writable=*/false,
                      size,
                      bytes,
                      relocations,
                      symbols,
                      alignment) {}

  // For BitsContainers used as segments whose type differ on the type of the
  // ELF file. Creates an elf::SHT_PROGBITS section if type is Snapshot,
  // otherwise creates an elf::SHT_NOBITS section.
  BitsContainer(Elf::Type t,
                bool executable,
                bool writable,
                intptr_t size,
                const uint8_t* bytes,
                const ZoneGrowableArray<Elf::Relocation>* relocations,
                const ZoneGrowableArray<Elf::SymbolData>* symbols,
                intptr_t alignment = kDefaultAlignment)
      : BitsContainer(t == Elf::Type::Snapshot
                          ? elf::SectionHeaderType::SHT_PROGBITS
                          : elf::SectionHeaderType::SHT_NOBITS,
                      /*allocate=*/true,
                      executable,
                      writable,
                      size,
                      bytes,
                      relocations,
                      symbols,
                      alignment) {}

  const BitsContainer* AsBitsContainer() const { return this; }
  const ZoneGrowableArray<Elf::SymbolData>* symbols() const { return symbols_; }

  void Write(ElfWriteStream* stream) {
    if (type == elf::SectionHeaderType::SHT_NOBITS) return;
    if (relocations_ == nullptr) {
      return stream->WriteBytes(bytes(), FileSize());
    }
    const SymbolTable* symtab = ASSERT_NOTNULL(stream->elf().symtab());
    // Resolve relocations as we write.
    intptr_t current_pos = 0;
    for (const auto& reloc : *relocations_) {
      // We assume here that the relocations are sorted in increasing order,
      // with unique section offsets.
      ASSERT(current_pos <= reloc.section_offset);
      if (current_pos < reloc.section_offset) {
        stream->WriteBytes(bytes_ + current_pos,
                           reloc.section_offset - current_pos);
      }
      intptr_t source_address = reloc.source_offset;
      intptr_t target_address = reloc.target_offset;
      // Null symbols denote that the corresponding offset should be treated
      // as an absolute offset in the ELF memory space.
      if (reloc.source_symbol != nullptr) {
        if (strcmp(reloc.source_symbol, ".") == 0) {
          source_address += memory_offset() + reloc.section_offset;
        } else {
          const Symbol* const source_symbol = symtab->Find(reloc.source_symbol);
          ASSERT(source_symbol != nullptr);
          source_address += source_symbol->offset();
        }
      }
      if (reloc.target_symbol != nullptr) {
        if (strcmp(reloc.target_symbol, ".") == 0) {
          target_address += memory_offset() + reloc.section_offset;
        } else {
          const Symbol* const target_symbol = symtab->Find(reloc.target_symbol);
          if (target_symbol == nullptr) {
            ASSERT_EQUAL(strcmp(reloc.target_symbol, kSnapshotBuildIdAsmSymbol),
                         0);
            ASSERT_EQUAL(reloc.target_offset, 0);
            ASSERT_EQUAL(reloc.source_offset, 0);
            ASSERT_EQUAL(reloc.size_in_bytes, compiler::target::kWordSize);
            // TODO(dartbug.com/43516): Special case for snapshots with deferred
            // sections that handles the build ID relocation in an
            // InstructionsSection when there is no build ID.
            const word to_write = Image::kNoRelocatedAddress;
            stream->WriteBytes(reinterpret_cast<const uint8_t*>(&to_write),
                               reloc.size_in_bytes);
            current_pos = reloc.section_offset + reloc.size_in_bytes;
            continue;
          }
          target_address += target_symbol->offset();
        }
      }
      ASSERT(reloc.size_in_bytes <= kWordSize);
      const word to_write = target_address - source_address;
      ASSERT(Utils::IsInt(reloc.size_in_bytes * kBitsPerByte, to_write));
      stream->WriteBytes(reinterpret_cast<const uint8_t*>(&to_write),
                         reloc.size_in_bytes);
      current_pos = reloc.section_offset + reloc.size_in_bytes;
    }
    stream->WriteBytes(bytes_ + current_pos, FileSize() - current_pos);
  }

  uint32_t Hash() const {
    ASSERT(bytes() != nullptr);
    return Utils::StringHash(bytes(), MemorySize());
  }

  intptr_t FileSize() const { return file_size_; }
  intptr_t MemorySize() const { return memory_size_; }
  const uint8_t* bytes() const { return bytes_; }

 private:
  const intptr_t file_size_;
  const intptr_t memory_size_;
  const uint8_t* const bytes_;
  const ZoneGrowableArray<Elf::Relocation>* const relocations_;
  const ZoneGrowableArray<Elf::SymbolData>* const symbols_;
};

Elf::Elf(Zone* zone, BaseWriteStream* stream, Type type, Dwarf* dwarf)
    : zone_(zone),
      unwrapped_stream_(stream),
      type_(type),
      dwarf_(dwarf),
      shstrtab_(new (zone) StringTable(zone, /*allocate=*/false)),
      dynstrtab_(new (zone) StringTable(zone, /*allocate=*/true)),
      dynsym_(new (zone) SymbolTable(zone, dynstrtab_, /*dynamic=*/true)),
      strtab_(new (zone_) StringTable(zone_, /*allocate=*/false)),
      symtab_(new (zone_) SymbolTable(zone, strtab_, /*dynamic=*/false)) {
  // Separate debugging information should always have a Dwarf object.
  ASSERT(type_ == Type::Snapshot || dwarf_ != nullptr);
  // Assumed by various offset logic in this file.
  ASSERT_EQUAL(unwrapped_stream_->Position(), 0);
}

void Elf::AddSection(Section* section,
                     const char* name,
                     const char* symbol_name) {
  ASSERT(section_table_file_size_ < 0);
  ASSERT(!shstrtab_->HasBeenFinalized());
  section->set_name(shstrtab_->AddString(name));
  // We do not set the section index yet, that will be done during Finalize().
  sections_.Add(section);
  // We do set the initial section index in initialized symbols for quick lookup
  // until reordering happens.
  const intptr_t initial_section_index = sections_.length() - 1;
  if (symbol_name != nullptr) {
    ASSERT(section->IsAllocated());
    section->symbol_name = symbol_name;
    // While elf::STT_SECTION might seem more appropriate, section symbols are
    // usually local and dlsym won't return them.
    ASSERT(!dynsym_->HasBeenFinalized());
    dynsym_->AddSymbol(symbol_name, elf::STB_GLOBAL, elf::STT_FUNC,
                       initial_section_index, section->MemorySize());
    // Some tools assume the static symbol table is a superset of the dynamic
    // symbol table when it exists (see dartbug.com/41783).
    ASSERT(!symtab_->HasBeenFinalized());
    symtab_->AddSymbol(symbol_name, elf::STB_GLOBAL, elf::STT_FUNC,
                       initial_section_index, section->FileSize());
  }
  if (auto const container = section->AsBitsContainer()) {
    if (container->symbols() != nullptr) {
      ASSERT(section->IsAllocated());
      for (const auto& symbol_data : *container->symbols()) {
        ASSERT(!symtab_->HasBeenFinalized());
        symtab_->AddSymbol(symbol_data.name, elf::STB_LOCAL, symbol_data.type,
                           initial_section_index, symbol_data.size);
      }
    }
  }
}

void Elf::AddText(const char* name,
                  const uint8_t* bytes,
                  intptr_t size,
                  const ZoneGrowableArray<Relocation>* relocations,
                  const ZoneGrowableArray<SymbolData>* symbols) {
  auto const image =
      new (zone_) BitsContainer(type_, /*executable=*/true,
                                /*writable=*/false, size, bytes, relocations,
                                symbols, ImageWriter::kTextAlignment);
  AddSection(image, ".text", name);
}

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

void Elf::CreateBSS() {
  uint8_t* bytes = nullptr;
  if (type_ == Type::Snapshot) {
    // Ideally the BSS segment would take no space in the object, but Android's
    // "strip" utility truncates the memory-size of our segments to their
    // file-size.
    //
    // Therefore we must insert zero-filled data for the BSS.
    bytes = zone_->Alloc<uint8_t>(kBssSize);
    memset(bytes, 0, kBssSize);
  }
  // For the BSS section, we add two local symbols to the static symbol table,
  // one for each isolate. We use local symbols because these addresses are only
  // used for relocation. (This matches the behavior in the assembly output,
  // where these symbols are also local.)
  auto* bss_symbols = new (zone_) ZoneGrowableArray<Elf::SymbolData>();
  bss_symbols->Add({kVmSnapshotBssAsmSymbol, elf::STT_SECTION, 0, kBssVmSize});
  bss_symbols->Add({kIsolateSnapshotBssAsmSymbol, elf::STT_SECTION, kBssVmSize,
                    kBssIsolateSize});
  bss_ = new (zone_) BitsContainer(
      type_, /*executable=*/false, /*writable=*/true, kBssSize, bytes,
      /*relocations=*/nullptr, bss_symbols, ImageWriter::kBssAlignment);
  AddSection(bss_, ".bss");
}

void Elf::AddROData(const char* name,
                    const uint8_t* bytes,
                    intptr_t size,
                    const ZoneGrowableArray<Relocation>* relocations,
                    const ZoneGrowableArray<SymbolData>* symbols) {
  auto const image =
      new (zone_) BitsContainer(type_, /*executable=*/false,
                                /*writable=*/false, size, bytes, relocations,
                                symbols, ImageWriter::kRODataAlignment);
  AddSection(image, ".rodata", name);
}

#if defined(DART_PRECOMPILER)
class DwarfElfStream : public DwarfWriteStream {
 public:
  DwarfElfStream(Zone* zone, NonStreamingWriteStream* stream)
      : zone_(ASSERT_NOTNULL(zone)),
        stream_(ASSERT_NOTNULL(stream)),
        relocations_(new (zone) ZoneGrowableArray<Elf::Relocation>()) {}

  const uint8_t* buffer() const { return stream_->buffer(); }
  intptr_t bytes_written() const { return stream_->bytes_written(); }

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
  // The prefix is ignored for DwarfElfStreams.
  EncodedPosition WritePrefixedLength(const char* symbol_prefix,
                                      std::function<void()> body) {
    const intptr_t fixup = stream_->Position();
    // We assume DWARF v2 currently, so all sizes are 32-bit.
    u4(0);
    // All sizes for DWARF sections measure the size of the section data _after_
    // the size value.
    const intptr_t start = stream_->Position();
    body();
    const intptr_t end = stream_->Position();
    stream_->SetPosition(fixup);
    u4(end - start);
    stream_->SetPosition(end);
    return EncodedPosition(fixup);
  }
  // Shorthand for when working directly with DwarfElfStreams.
  intptr_t WritePrefixedLength(std::function<void()> body) {
    const EncodedPosition& pos = WritePrefixedLength(nullptr, body);
    return pos.position();
  }

  void OffsetFromSymbol(const char* symbol, intptr_t offset) {
    relocations_->Add(
        {kAddressSize, stream_->Position(), nullptr, 0, symbol, offset});
    addr(0);  // Resolved later.
  }
  template <typename T>
  void RelativeSymbolOffset(const char* symbol) {
    relocations_->Add({sizeof(T), stream_->Position(), ".", 0, symbol, 0});
    stream_->WriteFixed<T>(0);  // Resolved later.
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

  const ZoneGrowableArray<Elf::Relocation>* relocations() const {
    return relocations_;
  }

 protected:
#if defined(TARGET_ARCH_IS_32_BIT)
  static constexpr intptr_t kAddressSize = kInt32Size;
#else
  static constexpr intptr_t kAddressSize = kInt64Size;
#endif

  void addr(uword value) {
#if defined(TARGET_ARCH_IS_32_BIT)
    u4(value);
#else
    u8(value);
#endif
  }

  Zone* const zone_;
  NonStreamingWriteStream* const stream_;
  ZoneGrowableArray<Elf::Relocation>* relocations_ = nullptr;
  uint32_t* abstract_origins_ = nullptr;
  intptr_t abstract_origins_size_ = -1;

 private:
  DISALLOW_COPY_AND_ASSIGN(DwarfElfStream);
};

static constexpr intptr_t kInitialDwarfBufferSize = 64 * KB;
#endif

const Section* Elf::FindSectionBySymbolName(const char* name) const {
  const Symbol* const symbol = symtab_->Find(name);
  if (symbol == nullptr) return nullptr;
  // Should not be run between OrderSectionsAndCreateSegments (when section
  // indices may change) and FinalizeSymbols() (sets the final section index).
  ASSERT(segments_.length() == 0 || symbol->HasBeenFinalized());
  const Section* const section = sections_[symbol->section_index];
  ASSERT_EQUAL(strcmp(section->symbol_name, name), 0);
  return section;
}

void Elf::FinalizeSymbols() {
  // Must be run after OrderSectionsAndCreateSegments and ComputeOffsets.
  ASSERT(segments_.length() > 0);
  ASSERT(section_table_file_offset_ > 0);
  for (const auto& section : sections_) {
    if (section->symbol_name != nullptr) {
      dynsym_->FinalizeSymbol(section->symbol_name, section->index(),
                              section->memory_offset());
      symtab_->FinalizeSymbol(section->symbol_name, section->index(),
                              section->memory_offset());
    }
    if (auto const container = section->AsBitsContainer()) {
      if (container->symbols() != nullptr) {
        for (const auto& symbol_data : *container->symbols()) {
          symtab_->FinalizeSymbol(
              symbol_data.name, section->index(),
              section->memory_offset() + symbol_data.offset);
        }
      }
    }
  }
}

void Elf::FinalizeEhFrame() {
#if defined(DART_PRECOMPILER) &&                                               \
    (defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64))
  // Multiplier which will be used to scale operands of DW_CFA_offset and
  // DW_CFA_val_offset.
  const intptr_t kDataAlignment = compiler::target::kWordSize;

  static const uint8_t DW_EH_PE_pcrel = 0x10;
  static const uint8_t DW_EH_PE_sdata4 = 0x0b;

  ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
  DwarfElfStream dwarf_stream(zone_, &stream);

  // Emit CIE.

  // Used to calculate offset to CIE in FDEs.
  const intptr_t cie_start = dwarf_stream.WritePrefixedLength([&] {
    dwarf_stream.u4(0);  // CIE
    dwarf_stream.u1(1);  // Version (must be 1 or 3)
    // Augmentation String
    dwarf_stream.string("zR");             // NOLINT
    dwarf_stream.uleb128(1);               // Code alignment (must be 1).
    dwarf_stream.sleb128(kDataAlignment);  // Data alignment
    dwarf_stream.u1(
        ConcreteRegister(LINK_REGISTER));  // Return address register
    dwarf_stream.uleb128(1);               // Augmentation size
    dwarf_stream.u1(DW_EH_PE_pcrel | DW_EH_PE_sdata4);  // FDE encoding.
    // CFA is FP+0
    dwarf_stream.u1(Dwarf::DW_CFA_def_cfa);
    dwarf_stream.uleb128(FP);
    dwarf_stream.uleb128(0);
  });

  // Emit an FDE covering each .text section.
  const auto text_name = shstrtab_->Lookup(".text");
  ASSERT(text_name != StringTable::kNotIndexed);
  for (auto section : sections_) {
    if (section->name() != text_name) continue;
    dwarf_stream.WritePrefixedLength([&]() {
      // Offset to CIE. Note that unlike pcrel this offset is encoded
      // backwards: it will be subtracted from the current position.
      dwarf_stream.u4(stream.Position() - cie_start);
      // Start address as a PC relative reference.
      dwarf_stream.RelativeSymbolOffset<int32_t>(section->symbol_name);
      dwarf_stream.u4(section->MemorySize());  // Size.
      dwarf_stream.u1(0);                      // Augmentation Data length.

      // FP at FP+kSavedCallerPcSlotFromFp*kWordSize
      COMPILE_ASSERT(kSavedCallerFpSlotFromFp >= 0);
      dwarf_stream.u1(Dwarf::DW_CFA_offset | FP);
      dwarf_stream.uleb128(kSavedCallerFpSlotFromFp);

      // LR at FP+kSavedCallerPcSlotFromFp*kWordSize
      COMPILE_ASSERT(kSavedCallerPcSlotFromFp >= 0);
      dwarf_stream.u1(Dwarf::DW_CFA_offset | ConcreteRegister(LINK_REGISTER));
      dwarf_stream.uleb128(kSavedCallerPcSlotFromFp);

      // SP is FP+kCallerSpSlotFromFp*kWordSize
      COMPILE_ASSERT(kCallerSpSlotFromFp >= 0);
      dwarf_stream.u1(Dwarf::DW_CFA_val_offset);
#if defined(TARGET_ARCH_ARM64)
      dwarf_stream.uleb128(ConcreteRegister(CSP));
#elif defined(TARGET_ARCH_ARM)
      dwarf_stream.uleb128(SP);
#else
#error "Unsupported .eh_frame architecture"
#endif
      dwarf_stream.uleb128(kCallerSpSlotFromFp);
    });
  }

  dwarf_stream.u4(0);  // end of section

  auto const eh_frame = new (zone_)
      BitsContainer(type_, /*writable=*/false, /*executable=*/false,
                    dwarf_stream.bytes_written(), dwarf_stream.buffer(),
                    dwarf_stream.relocations(), /*symbols=*/nullptr);
  AddSection(eh_frame, ".eh_frame");
#endif  // defined(DART_PRECOMPILER) && \
        //   (defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64))
}

void Elf::FinalizeDwarfSections() {
  if (dwarf_ == nullptr) return;
#if defined(DART_PRECOMPILER)
  auto add_debug = [&](const char* name, const DwarfElfStream& stream) {
    auto const image = new (zone_) BitsContainer(
        elf::SectionHeaderType::SHT_PROGBITS, stream.bytes_written(),
        stream.buffer(), stream.relocations(), /*symbols=*/nullptr);
    AddSection(image, name);
  };
  {
    ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream);
    dwarf_->WriteAbbreviations(&dwarf_stream);
    add_debug(".debug_abbrev", dwarf_stream);
  }

  {
    ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream);
    dwarf_->WriteDebugInfo(&dwarf_stream);
    add_debug(".debug_info", dwarf_stream);
  }

  {
    ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
    DwarfElfStream dwarf_stream(zone_, &stream);
    dwarf_->WriteLineNumberProgram(&dwarf_stream);
    add_debug(".debug_line", dwarf_stream);
  }
#endif
}

void Elf::OrderSectionsAndCreateSegments() {
  GrowableArray<Section*> reordered_sections;
  // The first section in the section header table is always a reserved
  // entry containing only 0 values.
  reordered_sections.Add(new (zone_) ReservedSection());

  Segment* current_segment = nullptr;
  auto add_to_reordered_sections = [&](Section* section) {
    section->set_index(reordered_sections.length());
    reordered_sections.Add(section);
    if (!section->IsAllocated()) return;
    const bool was_added =
        current_segment == nullptr ? false : current_segment->Add(section);
    if (!was_added) {
      // There is no current segment or it is incompatible for merging, so
      // following compatible segments will be merged into this one if possible.
      current_segment =
          new (zone_) Segment(zone_, section, elf::ProgramHeaderType::PT_LOAD);
      section->load_segment = current_segment;
      segments_.Add(current_segment);
    }
  };

  // Add writable, non-executable sections first, due to a bug in Jelly Bean's
  // ELF loader when a writable segment is placed between two non-writable
  // segments. See also Elf::WriteProgramTable(), which double-checks this.
  for (auto* const section : sections_) {
    if (section->IsAllocated() && section->IsWritable() &&
        !section->IsExecutable()) {
      add_to_reordered_sections(section);
    }
  }

  // Now add the non-writable, non-executable allocated sections in a new
  // segment, starting with the data sections.
  for (auto* const section : sections_) {
    if (section->IsAllocated() && !section->IsWritable() &&
        !section->IsExecutable()) {
      add_to_reordered_sections(section);
    }
  }

  // Now add the non-writable, executable sections in a new segment.
  for (auto* const section : sections_) {
    if (section->IsAllocated() && !section->IsWritable() &&
        section->IsExecutable()) {
      add_to_reordered_sections(section);
    }
  }

  // We put all unallocated sections last because otherwise, they would
  // affect the file offset but not the memory offset of any following allocated
  // sections. Doing it in this order makes it easier to keep file and memory
  // offsets page-aligned with respect to each other, which is required for
  // some loaders.
  for (auto* const section : sections_) {
    if (!section->IsAllocated()) {
      add_to_reordered_sections(section);
    }
  }

  // Now replace sections_.
  sections_.Clear();
  sections_.AddArray(reordered_sections);
}

void Elf::Finalize() {
  ASSERT(program_table_file_size_ < 0);

  // Generate the build ID now that we have all user-provided sections.
  // Generating it at this point also means it'll be the first writable
  // non-executable section added to sections_ and thus end up right after the
  // program table after reordering. This limits how much of the ELF file needs
  // to be read to get the build ID (header + program table + note segment).
  GenerateBuildId();

  // We add BSS in all cases, even to the separate debugging information ELF,
  // to ensure that relocated addresses are consistent between ELF snapshots
  // and ELF separate debugging information.
  CreateBSS();

  // Adding the dynamic symbol table and associated sections.
  AddSection(dynstrtab_, ".dynstr");
  AddSection(dynsym_, ".dynsym");

  auto const hash = new (zone_) SymbolHashTable(zone_, dynstrtab_, dynsym_);
  AddSection(hash, ".hash");

  auto const dynamic = new (zone_) DynamicTable(zone_);
  AddSection(dynamic, ".dynamic");

  if (!IsStripped()) {
    AddSection(strtab_, ".strtab");
    AddSection(symtab_, ".symtab");
  }
  AddSection(shstrtab_, ".shstrtab");
  FinalizeEhFrame();
  FinalizeDwarfSections();

  OrderSectionsAndCreateSegments();

  // Now that the sections have indices, set up links between them as needed.
  dynsym_->link = dynstrtab_->index();
  hash->link = dynsym_->index();
  dynamic->link = dynstrtab_->index();
  if (!IsStripped()) {
    symtab_->link = strtab_->index();
  }

  // Now add any special non-load segments.

  if (build_id_ != nullptr) {
    // Add a PT_NOTE segment for the build ID.
    segments_.Add(new (zone_) NoteSegment(zone_, build_id_));
  }

  // Add a PT_DYNAMIC segment for the dynamic symbol table.
  segments_.Add(new (zone_) DynamicSegment(zone_, dynamic));

  // At this point, all sections have been added and ordered and all sections
  // appropriately grouped into segments. Add the program table and then
  // calculate file and memory offsets.
  FinalizeProgramTable();
  ComputeOffsets();

  // Now that we have reordered the sections and set memory offsets, we can
  // update the symbol tables to add index and address information. This must
  // be done prior to writing the symbol tables and any sections with
  // relocations.
  FinalizeSymbols();
  // Also update the entries in the dynamic table.
  dynamic->FinalizeEntries(dynstrtab_, dynsym_, hash);

  // Finally, write the ELF file contents.
  ElfWriteStream wrapped(unwrapped_stream_, *this);
  WriteHeader(&wrapped);
  WriteProgramTable(&wrapped);
  WriteSections(&wrapped);
  WriteSectionTable(&wrapped);
}

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

void Elf::GenerateBuildId() {
  uint32_t hashes[kBuildIdSegmentNamesLength];
  for (intptr_t i = 0; i < kBuildIdSegmentNamesLength; i++) {
    auto const name = kBuildIdSegmentNames[i];
    auto const section = FindSectionBySymbolName(name);
    // If we're missing a section, then we don't generate a final build ID.
    if (section == nullptr) return;
    auto const bits = section->AsBitsContainer();
    if (bits == nullptr) {
      FATAL1("Section for symbol %s is not a BitsContainer", name);
    }
    // For now, if we don't have section contents (because we're generating
    // assembly), don't generate a final build ID, as we'll have different
    // build IDs in the snapshot and the separate debugging information.
    //
    // TODO(dartbug.com/43274): Change once we generate consistent build IDs
    // between assembly snapshots and their debugging information.
    if (bits->bytes() == nullptr) return;
    hashes[i] = bits->Hash();
  }
  auto const description_bytes = reinterpret_cast<uint8_t*>(hashes);
  const size_t description_length = sizeof(hashes);
  // To ensure we can quickly check for a final build ID, we ensure the first
  // byte contains a non-zero value.
  if (description_bytes[0] == 0) {
    description_bytes[0] = 1;
  }
  // Now that we have the description field contents, create the section.
  ZoneWriteStream stream(zone(), kBuildIdHeaderSize + description_length);
  stream.WriteFixed<decltype(elf::Note::name_size)>(sizeof(elf::ELF_NOTE_GNU));
  stream.WriteFixed<decltype(elf::Note::description_size)>(description_length);
  stream.WriteFixed<decltype(elf::Note::type)>(elf::NoteType::NT_GNU_BUILD_ID);
  ASSERT_EQUAL(stream.Position(), sizeof(elf::Note));
  stream.WriteBytes(elf::ELF_NOTE_GNU, sizeof(elf::ELF_NOTE_GNU));
  ASSERT_EQUAL(stream.bytes_written(), kBuildIdHeaderSize);
  stream.WriteBytes(description_bytes, description_length);
  // While the build ID section does not need to be writable, the first segment
  // in our ELF files is writable (see Elf::WriteProgramTable) and so this
  // ensures we can put it right after the program table without padding.
  build_id_ = new (zone_) BitsContainer(
      elf::SectionHeaderType::SHT_NOTE,
      /*allocate=*/true, /*executable=*/false,
      /*writable=*/true, stream.bytes_written(), stream.buffer(),
      /*relocations=*/nullptr, /*symbols=*/nullptr, kNoteAlignment);
  AddSection(build_id_, kBuildIdNoteName, kSnapshotBuildIdAsmSymbol);
}

void Elf::FinalizeProgramTable() {
  ASSERT(program_table_file_size_ < 0);

  program_table_file_offset_ = sizeof(elf::ElfHeader);

  // There is one additional segment we need the size of the program table to
  // create, so calculate it as if that segment were already in place.
  program_table_file_size_ =
      (1 + segments_.length()) * sizeof(elf::ProgramHeader);

  auto const program_table_segment_size =
      program_table_file_offset_ + program_table_file_size_;

  // Segment for loading the initial part of the ELF file, including the
  // program header table. Required by Android but not by Linux.
  Segment* const initial_load =
      new (zone_) ProgramTableLoadSegment(zone_, program_table_segment_size);
  // Merge the initial writable segment into this one and replace it (so it
  // doesn't change the number of segments).
  const bool was_merged = initial_load->Merge(segments_[0]);
  ASSERT(was_merged);
  segments_[0] = initial_load;

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  segments_.InsertAt(
      0, new (zone_) ProgramTableSelfSegment(zone_, program_table_file_offset_,
                                             program_table_file_size_));
}

static const intptr_t kElfSectionTableAlignment = compiler::target::kWordSize;

void Elf::ComputeOffsets() {
  // We calculate the size and offset of the program header table during
  // finalization.
  ASSERT(program_table_file_offset_ > 0 && program_table_file_size_ > 0);
  intptr_t file_offset = program_table_file_offset_ + program_table_file_size_;
  // Program table memory size is same as file size.
  intptr_t memory_offset = file_offset;

  // When calculating memory and file offsets for sections, we'll need to know
  // if we've changed segments. Start with the one for the program table.
  ASSERT(segments_[0]->type != elf::ProgramHeaderType::PT_LOAD);
  const auto* current_segment = segments_[1];
  ASSERT(current_segment->type == elf::ProgramHeaderType::PT_LOAD);

  // The non-reserved sections are output to the file in order after the program
  // header table. If we're entering a new segment, then we need to align
  // according to the PT_LOAD segment alignment as well to keep the file offsets
  // aligned with the memory addresses.
  for (intptr_t i = 1; i < sections_.length(); i++) {
    auto const section = sections_[i];
    file_offset = Utils::RoundUp(file_offset, section->alignment);
    memory_offset = Utils::RoundUp(memory_offset, section->alignment);
    if (section->IsAllocated() && section->load_segment != current_segment) {
      current_segment = section->load_segment;
      ASSERT(current_segment->type == elf::ProgramHeaderType::PT_LOAD);
      const intptr_t load_align = Segment::Alignment(current_segment->type);
      file_offset = Utils::RoundUp(file_offset, load_align);
      memory_offset = Utils::RoundUp(memory_offset, load_align);
    }
    section->set_file_offset(file_offset);
    if (section->IsAllocated()) {
      section->set_memory_offset(memory_offset);
#if defined(DEBUG)
      if (type_ == Type::Snapshot) {
        // For files that will be dynamically loaded, make sure the file offsets
        // of allocated sections are page aligned to the memory offsets.
        ASSERT_EQUAL(section->file_offset() % Elf::kPageSize,
                     section->memory_offset() % Elf::kPageSize);
      }
#endif
    }
    file_offset += section->FileSize();
    memory_offset += section->MemorySize();
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
  // Should be writing the first section immediately after the program table.
  ASSERT_EQUAL(stream->Position(),
               program_table_file_offset_ + program_table_file_size_);
  // Skip the reserved first section, as its alignment is 0 (which will cause
  // stream->Align() to fail) and it never contains file contents anyway.
  ASSERT_EQUAL(static_cast<uint32_t>(sections_[0]->type),
               static_cast<uint32_t>(elf::SectionHeaderType::SHT_NULL));
  ASSERT_EQUAL(sections_[0]->alignment, 0);
  // The program table is considered part of the first load segment (the
  // second segment in segments_), so other sections in the same segment should
  // not have extra segment alignment added.
  ASSERT(segments_[0]->type != elf::ProgramHeaderType::PT_LOAD);
  const Segment* current_segment = segments_[1];
  ASSERT(current_segment->type == elf::ProgramHeaderType::PT_LOAD);
  for (intptr_t i = 1; i < sections_.length(); i++) {
    Section* section = sections_[i];
    stream->Align(section->alignment);
    if (section->IsAllocated() && section->load_segment != current_segment) {
      // Changing segments, so align accordingly.
      current_segment = section->load_segment;
      ASSERT(current_segment->type == elf::ProgramHeaderType::PT_LOAD);
      const intptr_t load_align = Segment::Alignment(current_segment->type);
      stream->Align(load_align);
    }
    ASSERT_EQUAL(stream->Position(), section->file_offset());
    section->Write(stream);
    ASSERT_EQUAL(stream->Position(),
                 section->file_offset() + section->FileSize());
  }
}

#endif  // DART_PRECOMPILER

}  // namespace dart
