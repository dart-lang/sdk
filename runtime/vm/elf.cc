// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/elf.h"

#include "platform/elf.h"
#include "platform/unwinding_records.h"
#include "vm/cpu.h"
#include "vm/dwarf.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"
#include "vm/unwinding_records.h"
#include "vm/zone_text_buffer.h"

namespace dart {

#if defined(DART_PRECOMPILER)

// A wrapper around BaseWriteStream that provides methods useful for
// writing ELF files (e.g., using ELF definitions of data sizes).
class ElfWriteStream : public ValueObject {
 public:
  explicit ElfWriteStream(BaseWriteStream* stream, const Elf& elf)
      : stream_(ASSERT_NOTNULL(stream)),
        elf_(elf),
        start_(stream_->Position()) {
    // So that we can use the underlying stream's Align, as all alignments
    // will be less than or equal to this alignment.
    ASSERT(Utils::IsAligned(start_, Elf::kPageSize));
  }

  // Subclasses of Section may need to query the Elf object during Write(),
  // so we store it in the ElfWriteStream for easy access.
  const Elf& elf() const { return elf_; }

  // We return positions in terms of the ELF content that has been written,
  // ignoring any previous content on the stream.
  intptr_t Position() const { return stream_->Position() - start_; }
  void Align(const intptr_t alignment) {
    ASSERT(Utils::IsPowerOfTwo(alignment));
    ASSERT(alignment <= Elf::kPageSize);
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
  const intptr_t start_;
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

// We only allow for dynamic casting to a subset of section types, since
// these are the only ones we need to distinguish at runtime.
#define FOR_EACH_SECTION_TYPE(V)                                               \
  V(ReservedSection)                                                           \
  V(SymbolTable)                                                               \
  V(DynamicTable)                                                              \
  V(BitsContainer)                                                             \
  V(TextSection) V(DataSection) V(BssSection) V(PseudoSection) V(SectionTable)
#define DEFINE_TYPE_CHECK_FOR(Type)                                            \
  bool Is##Type() const { return true; }

#define DECLARE_SECTION_TYPE_CLASS(Type) class Type;
FOR_EACH_SECTION_TYPE(DECLARE_SECTION_TYPE_CLASS)
#undef DECLARE_SECTION_TYPE_CLASS

class BitsContainer;
class Segment;

// Align note sections and segments to 4 byte boundaries.
static constexpr intptr_t kNoteAlignment = 4;

class Section : public ZoneAllocated {
 public:
  Section(elf::SectionHeaderType t,
          bool allocate,
          bool executable,
          bool writable,
          intptr_t align = compiler::target::kWordSize)
      : type(t),
        flags(EncodeFlags(allocate, executable, writable)),
        alignment(align),
        // Non-segments will never have a memory offset, here represented by 0.
        memory_offset_(allocate ? kLinearInitValue : 0) {
    // Only SHT_NULL sections (namely, the reserved section) are allowed to have
    // an alignment of 0 (as the written section header entry for the reserved
    // section must be all 0s).
    ASSERT(alignment > 0 || type == elf::SectionHeaderType::SHT_NULL);
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
  // This field is set for all sections, but due to reordering, we may set it
  // more than once.
  intptr_t index = elf::SHN_UNDEF;

#define FOR_EACH_SECTION_LINEAR_FIELD(M)                                       \
  M(name)                                                                      \
  M(file_offset)

  FOR_EACH_SECTION_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  // Only needs to be overridden for sections that may not be allocated or
  // for allocated sections where MemorySize() and FileSize() may differ.
  virtual intptr_t FileSize() const {
    if (!IsAllocated()) {
      UNREACHABLE();
    }
    return MemorySize();
  }

  // Loader view.

#define FOR_EACH_SEGMENT_LINEAR_FIELD(M) M(memory_offset)

  FOR_EACH_SEGMENT_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

  // Only needs to be overridden for sections that may be allocated.
  virtual intptr_t MemorySize() const {
    if (IsAllocated()) {
      UNREACHABLE();
    }
    return 0;
  }

  // Other methods.

  bool IsAllocated() const {
    return (flags & elf::SHF_ALLOC) == elf::SHF_ALLOC;
  }
  bool IsExecutable() const {
    return (flags & elf::SHF_EXECINSTR) == elf::SHF_EXECINSTR;
  }
  bool IsWritable() const { return (flags & elf::SHF_WRITE) == elf::SHF_WRITE; }

  bool HasBits() const { return type != elf::SectionHeaderType::SHT_NOBITS; }

  // Returns whether the size of a section can change.
  bool HasBeenFinalized() const {
    // Sections can grow or shrink up until Elf::ComputeOffsets has been run,
    // which sets the file (and memory, if applicable) offsets.
    return file_offset_is_set();
  }

#define DEFINE_BASE_TYPE_CHECKS(Type)                                          \
  Type* As##Type() {                                                           \
    return Is##Type() ? reinterpret_cast<Type*>(this) : nullptr;               \
  }                                                                            \
  const Type* As##Type() const {                                               \
    return const_cast<Type*>(const_cast<Section*>(this)->As##Type());          \
  }                                                                            \
  virtual bool Is##Type() const { return false; }

  FOR_EACH_SECTION_TYPE(DEFINE_BASE_TYPE_CHECKS)
#undef DEFINE_BASE_TYPE_CHECKS

  // Only some sections support merging.
  virtual bool CanMergeWith(const Section& other) const { return false; }
  virtual void Merge(const Section& other) { UNREACHABLE(); }

  // Writes the file contents of the section.
  virtual void Write(ElfWriteStream* stream) const { UNREACHABLE(); }

  virtual void WriteSectionHeader(ElfWriteStream* stream) const {
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(name());
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteWord(flags);
    stream->WriteAddr(memory_offset());
    stream->WriteOff(file_offset());
    stream->WriteWord(FileSize());
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
    stream->WriteXWord(FileSize());
    stream->WriteWord(link);
    stream->WriteWord(info);
    stream->WriteXWord(alignment);
    stream->WriteXWord(entry_size);
#endif
  }

 private:
  static intptr_t EncodeFlags(bool allocate, bool executable, bool writable) {
    // We currently don't allow sections that are both executable and writable.
    ASSERT(!executable || !writable);
    intptr_t flags = 0;
    if (allocate) flags |= elf::SHF_ALLOC;
    if (executable) flags |= elf::SHF_EXECINSTR;
    if (writable) flags |= elf::SHF_WRITE;
    return flags;
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
    ASSERT(initial_section != nullptr);
    sections_.Add(initial_section);
  }

  virtual ~Segment() {}

  const GrowableArray<Section*>& sections() const { return sections_; }

  intptr_t Alignment() const {
    switch (type) {
      case elf::ProgramHeaderType::PT_LOAD:
        return Elf::kPageSize;
      case elf::ProgramHeaderType::PT_PHDR:
      case elf::ProgramHeaderType::PT_DYNAMIC:
        return compiler::target::kWordSize;
      case elf::ProgramHeaderType::PT_NOTE:
        return kNoteAlignment;
      case elf::ProgramHeaderType::PT_GNU_STACK:
        return 1;
      default:
        UNREACHABLE();
        return 0;
    }
  }

  bool IsExecutable() const { return (flags & elf::PF_X) == elf::PF_X; }
  bool IsWritable() const { return (flags & elf::PF_W) == elf::PF_W; }

  void WriteProgramHeader(ElfWriteStream* stream) const {
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteOff(FileOffset());
    stream->WriteAddr(MemoryOffset());  // Virtual address.
    stream->WriteAddr(MemoryOffset());  // Physical address.
    stream->WriteWord(FileSize());
    stream->WriteWord(MemorySize());
    stream->WriteWord(flags);
    stream->WriteWord(Alignment());
#else
    stream->WriteWord(static_cast<uint32_t>(type));
    stream->WriteWord(flags);
    stream->WriteOff(FileOffset());
    stream->WriteAddr(MemoryOffset());  // Virtual address.
    stream->WriteAddr(MemoryOffset());  // Physical address.
    stream->WriteXWord(FileSize());
    stream->WriteXWord(MemorySize());
    stream->WriteXWord(Alignment());
#endif
  }

  // Adds a given section to the end of this segment. Returns whether the
  // section was successfully added.
  bool Add(Section* section) {
    ASSERT(section != nullptr);
    // We can't add if memory offsets have already been calculated.
    ASSERT(!section->memory_offset_is_set());
    // We only add additional sections to load segments.
    ASSERT(type == elf::ProgramHeaderType::PT_LOAD);
    // We only add sections with the same executable and writable bits.
    if (IsExecutable() != section->IsExecutable() ||
        IsWritable() != section->IsWritable()) {
      return false;
    }
    sections_.Add(section);
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

  const elf::ProgramHeaderType type;
  const intptr_t flags;

 private:
  static intptr_t EncodeFlags(bool executable, bool writable) {
    intptr_t flags = elf::PF_R;
    if (executable) flags |= elf::PF_X;
    if (writable) flags |= elf::PF_W;
    return flags;
  }

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
    set_file_offset(0);
  }

  DEFINE_TYPE_CHECK_FOR(ReservedSection);
  intptr_t FileSize() const { return 0; }
};

// Specifies the permissions used for the stack, notably whether the stack
// should be executable. If absent, the stack will be executable.
class GnuStackSection : public Section {
 public:
  GnuStackSection()
      : Section(elf::SectionHeaderType::SHT_NULL,
                /*allocate=*/false,
                /*executable=*/false,
                /*writable=*/true) {
    set_file_offset(0);
  }

  intptr_t FileSize() const { return 0; }
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
    Add("");
  }

  intptr_t FileSize() const { return text_.length(); }
  intptr_t MemorySize() const { return dynamic_ ? FileSize() : 0; }

  void Write(ElfWriteStream* stream) const {
    stream->WriteBytes(reinterpret_cast<const uint8_t*>(text_.buffer()),
                       text_.length());
  }

  intptr_t Add(const char* str) {
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

  const char* At(intptr_t index) const {
    if (index >= text_.length()) return nullptr;
    return text_.buffer() + index;
  }

  static constexpr intptr_t kNotIndexed = CStringIntMapKeyValueTrait::kNoValue;

  // Returns the index of |str| if it is present in the string table
  // and |kNotIndexed| otherwise.
  intptr_t Lookup(const char* str) const {
    return text_indices_.LookupValue(str);
  }

  const bool dynamic_;
  ZoneTextBuffer text_;
  CStringIntMap text_indices_;
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
        by_label_index_(zone) {
    link = table_->index;
    entry_size = sizeof(elf::Symbol);
    // The first symbol table entry is reserved and must be all zeros.
    // (String tables always have the empty string at the 0th index.)
    ASSERT_EQUAL(table_->Lookup(""), 0);
    symbols_.Add({/*name_index=*/0, elf::STB_LOCAL, elf::STT_NOTYPE, /*size=*/0,
                  elf::SHN_UNDEF, /*offset=*/0, /*label =*/0});
    // The info field on a symbol table section holds the index of the first
    // non-local symbol, so since there are none yet, it points past the single
    // symbol we do have.
    info = 1;
  }

  DEFINE_TYPE_CHECK_FOR(SymbolTable)
  const StringTable& strtab() const { return *table_; }
  intptr_t FileSize() const { return symbols_.length() * entry_size; }
  intptr_t MemorySize() const { return dynamic_ ? FileSize() : 0; }

  struct Symbol {
    void Write(ElfWriteStream* stream) const {
      const intptr_t start = stream->Position();
      ASSERT(section_index == elf::SHN_UNDEF || offset > 0);
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

    intptr_t name_index;
    intptr_t binding;
    intptr_t type;
    intptr_t size;
    // Must be updated whenever sections are reordered.
    intptr_t section_index;
    // Initialized to the section-relative offset, must be updated to the
    // snapshot-relative offset before writing.
    intptr_t offset;
    // Only used within the VM and not written as part of the ELF file. If 0,
    // this symbol cannot be looked up via label.
    intptr_t label;

   private:
    DISALLOW_ALLOCATION();
  };

  const GrowableArray<Symbol>& symbols() const { return symbols_; }

  void Initialize(const GrowableArray<Section*>& sections);

  void Write(ElfWriteStream* stream) const {
    for (const auto& symbol : symbols_) {
      const intptr_t start = stream->Position();
      symbol.Write(stream);
      ASSERT_EQUAL(stream->Position() - start, entry_size);
    }
  }

  void AddSymbol(const char* name,
                 intptr_t binding,
                 intptr_t type,
                 intptr_t size,
                 intptr_t index,
                 intptr_t offset,
                 intptr_t label) {
    ASSERT(label > 0);
    ASSERT(!table_->HasBeenFinalized());
    auto const name_index = table_->Add(name);
    ASSERT(name_index != 0);
    const intptr_t new_index = symbols_.length();
    symbols_.Add({name_index, binding, type, size, index, offset, label});
    by_label_index_.Insert(label, new_index);
    // The info field on a symbol table section holds the index of the first
    // non-local symbol, so that local symbols can be skipped if desired. Thus,
    // we need to make sure local symbols are before any non-local ones.
    if (binding == elf::STB_LOCAL) {
      if (info != new_index) {
        // There are non-local symbols, as otherwise [info] would be the
        // index of the new symbol. Since the order doesn't otherwise matter,
        // swap the new local symbol with the value at index [info], so when
        // [info] is incremented it will point just past the new local symbol.
        ASSERT(symbols_[info].binding != elf::STB_LOCAL);
        symbols_.Swap(info, new_index);
        // Since by_label_index has indices into symbols_, we need to update it.
        by_label_index_.Update({symbols_[info].label, info});
        by_label_index_.Update({symbols_[new_index].label, new_index});
      }
      info += 1;
    }
  }

  void UpdateSectionIndices(const GrowableArray<intptr_t>& index_map) {
#if defined(DEBUG)
    const intptr_t map_size = index_map.length();
    // The first entry must be 0 so that symbols with index SHN_UNDEF, like
    // the initial reserved symbol, are unchanged.
    ASSERT_EQUAL(index_map[0], 0);
    for (intptr_t i = 1; i < map_size; i++) {
      ASSERT(index_map[i] != 0);
      ASSERT(index_map[i] < map_size);
    }
#endif
    for (auto& symbol : symbols_) {
      DEBUG_ASSERT(symbol.section_index < map_size);
      symbol.section_index = index_map[symbol.section_index];
    }
  }

  void Finalize(const GrowableArray<intptr_t>& address_map) {
#if defined(DEBUG)
    const intptr_t map_size = address_map.length();
    // The first entry must be 0 so that symbols with index SHN_UNDEF, like
    // the initial reserved symbol, are unchanged.
    ASSERT_EQUAL(address_map[0], 0);
    for (intptr_t i = 1; i < map_size; i++) {
      // No section begins at the start of the snapshot.
      ASSERT(address_map[i] != 0);
    }
#endif
    for (auto& symbol : symbols_) {
      DEBUG_ASSERT(symbol.section_index < map_size);
      symbol.offset += address_map[symbol.section_index];
    }
  }

  const Symbol* FindUid(intptr_t label) const {
    ASSERT(label > 0);
    const intptr_t symbols_index = by_label_index_.Lookup(label);
    if (symbols_index == 0) return nullptr;  // Not found.
    return &symbols_[symbols_index];
  }

 private:
  Zone* const zone_;
  StringTable* const table_;
  const bool dynamic_;
  GrowableArray<Symbol> symbols_;
  // Maps positive symbol labels to indexes in symbols_. No entry for the
  // reserved symbol, which has index 0, the same as the IntMap's kNoValue.
  IntMap<intptr_t> by_label_index_;
};

class SymbolHashTable : public Section {
 public:
  SymbolHashTable(Zone* zone, SymbolTable* symtab)
      : Section(elf::SectionHeaderType::SHT_HASH,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/false),
        buckets_(zone, 0),
        chains_(zone, 0) {
    link = symtab->index;
    entry_size = sizeof(int32_t);

    const auto& symbols = symtab->symbols();
    const intptr_t num_symbols = symbols.length();
    buckets_.FillWith(elf::STN_UNDEF, 0, num_symbols);
    chains_.FillWith(elf::STN_UNDEF, 0, num_symbols);

    for (intptr_t i = 1; i < num_symbols; i++) {
      const auto& symbol = symbols[i];
      uint32_t hash = HashSymbolName(symtab->strtab().At(symbol.name_index));
      uint32_t probe = hash % num_symbols;
      chains_[i] = buckets_[probe];  // next = head
      buckets_[probe] = i;           // head = symbol
    }
  }

  intptr_t MemorySize() const {
    return entry_size * (buckets_.length() + chains_.length() + 2);
  }

  void Write(ElfWriteStream* stream) const {
    stream->WriteWord(buckets_.length());
    stream->WriteWord(chains_.length());
    for (const int32_t bucket : buckets_) {
      stream->WriteWord(bucket);
    }
    for (const int32_t chain : chains_) {
      stream->WriteWord(chain);
    }
  }

  static uint32_t HashSymbolName(const void* p) {
    auto* name = reinterpret_cast<const uint8_t*>(p);
    uint32_t h = 0;
    while (*name != '\0') {
      h = (h << 4) + *name++;
      uint32_t g = h & 0xf0000000;
      h ^= g;
      h ^= g >> 24;
    }
    return h;
  }

 private:
  GrowableArray<int32_t> buckets_;  // "Head"
  GrowableArray<int32_t> chains_;   // "Next"
};

class DynamicTable : public Section {
 public:
  // .dynamic section is expected to be writable on most Linux systems
  // unless dynamic linker is explicitly built with support for an read-only
  // .dynamic section (DL_RO_DYN_SECTION).
  DynamicTable(Zone* zone, SymbolTable* symtab, SymbolHashTable* hash)
      : Section(elf::SectionHeaderType::SHT_DYNAMIC,
                /*allocate=*/true,
                /*executable=*/false,
                /*writable=*/true),
        symtab_(symtab),
        hash_(hash) {
    link = strtab().index;
    entry_size = sizeof(elf::DynamicEntry);

    AddEntry(zone, elf::DynamicEntryType::DT_HASH, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_STRTAB, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_STRSZ, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_SYMTAB, kInvalidEntry);
    AddEntry(zone, elf::DynamicEntryType::DT_SYMENT, sizeof(elf::Symbol));
    AddEntry(zone, elf::DynamicEntryType::DT_NULL, 0);
  }

  static constexpr intptr_t kInvalidEntry = -1;

  DEFINE_TYPE_CHECK_FOR(DynamicTable)
  const SymbolHashTable& hash() const { return *hash_; }
  const SymbolTable& symtab() const { return *symtab_; }
  const StringTable& strtab() const { return symtab().strtab(); }
  intptr_t MemorySize() const { return entries_.length() * entry_size; }

  void Write(ElfWriteStream* stream) const {
    for (intptr_t i = 0; i < entries_.length(); i++) {
      entries_[i]->Write(stream);
    }
  }

  void Finalize() {
    FinalizeEntry(elf::DynamicEntryType::DT_HASH, hash().memory_offset());
    FinalizeEntry(elf::DynamicEntryType::DT_STRTAB, strtab().memory_offset());
    FinalizeEntry(elf::DynamicEntryType::DT_STRSZ, strtab().MemorySize());
    FinalizeEntry(elf::DynamicEntryType::DT_SYMTAB, symtab().memory_offset());
  }

 private:
  struct Entry : public ZoneAllocated {
    Entry(elf::DynamicEntryType tag, intptr_t value) : tag(tag), value(value) {}

    void Write(ElfWriteStream* stream) const {
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

  SymbolTable* const symtab_;
  SymbolHashTable* const hash_;
  GrowableArray<Entry*> entries_;
};

class BitsContainer : public Section {
 public:
  // Fully specified BitsContainer information. Unless otherwise specified,
  // BitContainers are aligned on byte boundaries (i.e., no padding is used).
  BitsContainer(elf::SectionHeaderType type,
                bool allocate,
                bool executable,
                bool writable,
                int alignment = 1)
      : Section(type, allocate, executable, writable, alignment) {}

  // For BitsContainers used only as unallocated sections.
  explicit BitsContainer(elf::SectionHeaderType type, intptr_t alignment = 1)
      : BitsContainer(type,
                      /*allocate=*/false,
                      /*executable=*/false,
                      /*writable=*/false,
                      alignment) {}

  // For BitsContainers used as segments whose type differ on the type of the
  // ELF file. Creates an elf::SHT_PROGBITS section if type is Snapshot,
  // otherwise creates an elf::SHT_NOBITS section.
  BitsContainer(Elf::Type t,
                bool executable,
                bool writable,
                intptr_t alignment = 1)
      : BitsContainer(t == Elf::Type::Snapshot
                          ? elf::SectionHeaderType::SHT_PROGBITS
                          : elf::SectionHeaderType::SHT_NOBITS,
                      /*allocate=*/true,
                      executable,
                      writable,
                      alignment) {}

  DEFINE_TYPE_CHECK_FOR(BitsContainer)

  bool IsNoBits() const { return type == elf::SectionHeaderType::SHT_NOBITS; }
  bool HasBytes() const {
    return portions_.length() != 0 && portions_[0].bytes != nullptr;
  }

  struct Portion {
    void Write(ElfWriteStream* stream, intptr_t section_start) const {
      ASSERT(bytes != nullptr);
      if (relocations == nullptr) {
        stream->WriteBytes(bytes, size);
        return;
      }
      const SymbolTable& symtab = stream->elf().symtab();
      // Resolve relocations as we write.
      intptr_t current_pos = 0;
      for (const auto& reloc : *relocations) {
        // We assume here that the relocations are sorted in increasing order,
        // with unique section offsets.
        ASSERT(current_pos <= reloc.section_offset);
        if (current_pos < reloc.section_offset) {
          stream->WriteBytes(bytes + current_pos,
                             reloc.section_offset - current_pos);
        }
        intptr_t source_address = reloc.source_offset;
        if (reloc.source_label > 0) {
          auto* const source_symbol = symtab.FindUid(reloc.source_label);
          ASSERT(source_symbol != nullptr);
          source_address += source_symbol->offset;
        } else if (reloc.source_label == Elf::Relocation::kSelfRelative) {
          source_address += section_start + offset + reloc.section_offset;
        } else {
          ASSERT_EQUAL(reloc.source_label, Elf::Relocation::kSnapshotRelative);
          // No change to source_address.
        }
        ASSERT(reloc.size_in_bytes <= kWordSize);
        word to_write = reloc.target_offset - source_address;
        if (reloc.target_label > 0) {
          if (auto* const target_symbol = symtab.FindUid(reloc.target_label)) {
            to_write += target_symbol->offset;
          } else {
            ASSERT_EQUAL(reloc.target_label, Elf::kBuildIdLabel);
            ASSERT_EQUAL(reloc.target_offset, 0);
            ASSERT_EQUAL(reloc.source_offset, 0);
            ASSERT_EQUAL(reloc.size_in_bytes, compiler::target::kWordSize);
            // TODO(dartbug.com/43516): Special case for snapshots with deferred
            // sections that handles the build ID relocation in an
            // InstructionsSection when there is no build ID.
            to_write = Image::kNoRelocatedAddress;
          }
        } else if (reloc.target_label == Elf::Relocation::kSelfRelative) {
          to_write += section_start + offset + reloc.section_offset;
        } else {
          ASSERT_EQUAL(reloc.target_label, Elf::Relocation::kSnapshotRelative);
          // No change to source_address.
        }
        ASSERT(Utils::IsInt(reloc.size_in_bytes * kBitsPerByte, to_write));
        stream->WriteBytes(reinterpret_cast<const uint8_t*>(&to_write),
                           reloc.size_in_bytes);
        current_pos = reloc.section_offset + reloc.size_in_bytes;
      }
      stream->WriteBytes(bytes + current_pos, size - current_pos);
    }

    intptr_t offset;
    const char* symbol_name;
    intptr_t label;
    const uint8_t* bytes;
    intptr_t size;
    const ZoneGrowableArray<Elf::Relocation>* relocations;
    const ZoneGrowableArray<Elf::SymbolData>* symbols;

   private:
    DISALLOW_ALLOCATION();
  };

  const GrowableArray<Portion>& portions() const { return portions_; }

  const Portion& AddPortion(
      const uint8_t* bytes,
      intptr_t size,
      const ZoneGrowableArray<Elf::Relocation>* relocations = nullptr,
      const ZoneGrowableArray<Elf::SymbolData>* symbols = nullptr,
      const char* symbol_name = nullptr,
      intptr_t label = 0) {
    // Any named portion should also have a valid symbol label.
    ASSERT(symbol_name == nullptr || label > 0);
    ASSERT(IsNoBits() || bytes != nullptr);
    ASSERT(bytes != nullptr || relocations == nullptr);
    // Make sure all portions are consistent in containing bytes.
    ASSERT(portions_.is_empty() || HasBytes() == (bytes != nullptr));
    const intptr_t offset = Utils::RoundUp(total_size_, alignment);
    portions_.Add(
        {offset, symbol_name, label, bytes, size, relocations, symbols});
    const Portion& portion = portions_.Last();
    total_size_ = offset + size;
    return portion;
  }

  void Write(ElfWriteStream* stream) const {
    if (type == elf::SectionHeaderType::SHT_NOBITS) return;
    intptr_t start_position = stream->Position();  // Used for checks.
    for (const auto& portion : portions_) {
      stream->Align(alignment);
      ASSERT_EQUAL(stream->Position(), start_position + portion.offset);
      portion.Write(stream, memory_offset());
    }
    ASSERT_EQUAL(stream->Position(), start_position + total_size_);
  }

  // Returns the hash for the portion corresponding to symbol_name.
  // Returns 0 if the portion has no bytes or no portions have that name.
  uint32_t Hash(const char* symbol_name) const {
    for (const auto& portion : portions_) {
      if (strcmp(symbol_name, portion.symbol_name) == 0) {
        if (portion.bytes == nullptr) return 0;
        const uint32_t hash = Utils::StringHash(portion.bytes, portion.size);
        // Ensure a non-zero return.
        return hash == 0 ? 1 : hash;
      }
    }
    return 0;
  }

  intptr_t FileSize() const { return IsNoBits() ? 0 : total_size_; }
  intptr_t MemorySize() const { return IsAllocated() ? total_size_ : 0; }

 private:
  GrowableArray<Portion> portions_;
  intptr_t total_size_ = 0;
};

class NoteSection : public BitsContainer {
 public:
  NoteSection()
      : BitsContainer(elf::SectionHeaderType::SHT_NOTE,
                      /*allocate=*/true,
                      /*executable=*/false,
                      /*writable=*/false,
                      kNoteAlignment) {}
};

// Abstract bits container that allows merging by just appending the portion
// information (with properly adjusted offsets) of the other to this one.
class ConcatenableBitsContainer : public BitsContainer {
 public:
  ConcatenableBitsContainer(Elf::Type type,
                            bool executable,
                            bool writable,
                            intptr_t alignment)
      : BitsContainer(type, executable, writable, alignment) {}

  virtual bool CanMergeWith(const Section& other) const = 0;
  virtual void Merge(const Section& other) {
    ASSERT(other.IsBitsContainer());
    ASSERT(CanMergeWith(other));
    for (const auto& portion : other.AsBitsContainer()->portions()) {
      AddPortion(portion.bytes, portion.size, portion.relocations,
                 portion.symbols, portion.symbol_name, portion.label);
    }
  }
};

class TextSection : public ConcatenableBitsContainer {
 public:
  explicit TextSection(Elf::Type t)
      : ConcatenableBitsContainer(t,
                                  /*executable=*/true,
                                  /*writable=*/false,
                                  ImageWriter::kTextAlignment) {}

  DEFINE_TYPE_CHECK_FOR(TextSection);

  virtual bool CanMergeWith(const Section& other) const {
    return other.IsTextSection();
  }
};

class DataSection : public ConcatenableBitsContainer {
 public:
  explicit DataSection(Elf::Type t)
      : ConcatenableBitsContainer(t,
                                  /*executable=*/false,
                                  /*writable=*/false,
                                  ImageWriter::kRODataAlignment) {}

  DEFINE_TYPE_CHECK_FOR(DataSection);

  virtual bool CanMergeWith(const Section& other) const {
    return other.IsDataSection();
  }
};

class BssSection : public ConcatenableBitsContainer {
 public:
  explicit BssSection(Elf::Type t)
      : ConcatenableBitsContainer(t,
                                  /*executable=*/false,
                                  /*writable=*/true,
                                  ImageWriter::kBssAlignment) {}

  DEFINE_TYPE_CHECK_FOR(BssSection);

  virtual bool CanMergeWith(const Section& other) const {
    return other.IsBssSection();
  }
};

// Represents portions of the file/memory space which do not correspond to
// sections from the section header. Should never be added to the section table,
// but may be added to segments.
class PseudoSection : public Section {
 public:
  // All PseudoSections are aligned to target word size.
  static constexpr intptr_t kAlignment = compiler::target::kWordSize;

  PseudoSection(bool allocate, bool executable, bool writable)
      : Section(elf::SectionHeaderType::SHT_NULL,
                allocate,
                executable,
                writable,
                kAlignment) {}

  DEFINE_TYPE_CHECK_FOR(PseudoSection)

  void Write(ElfWriteStream* stream) const = 0;
};

class ProgramTable : public PseudoSection {
 public:
  explicit ProgramTable(Zone* zone)
      : PseudoSection(/*allocate=*/true,
                      /*executable=*/false,
                      /*writable=*/false),
        segments_(zone, 0) {
    entry_size = sizeof(elf::ProgramHeader);
  }

  const GrowableArray<Segment*>& segments() const { return segments_; }
  intptr_t SegmentCount() const { return segments_.length(); }
  intptr_t MemorySize() const {
    return segments_.length() * sizeof(elf::ProgramHeader);
  }

  void Add(Segment* segment) {
    ASSERT(segment != nullptr);
    segments_.Add(segment);
  }

  void Write(ElfWriteStream* stream) const;

 private:
  GrowableArray<Segment*> segments_;
};

// This particular PseudoSection should not appear in segments either (hence
// being marked non-allocated), but is directly held by the Elf object.
class SectionTable : public PseudoSection {
 public:
  explicit SectionTable(Zone* zone)
      : PseudoSection(/*allocate=*/false,
                      /*executable=*/false,
                      /*writable=*/false),
        zone_(zone),
        sections_(zone_, 2),
        shstrtab_(zone_, /*allocate=*/false) {
    entry_size = sizeof(elf::SectionHeader);
    // The section at index 0 (elf::SHN_UNDEF) must be all 0s.
    ASSERT_EQUAL(shstrtab_.Lookup(""), 0);
    Add(new (zone_) ReservedSection(), "");
    Add(&shstrtab_, ".shstrtab");
  }

  const GrowableArray<Section*>& sections() const { return sections_; }
  intptr_t SectionCount() const { return sections_.length(); }
  intptr_t StringTableIndex() const { return shstrtab_.index; }

  bool HasSectionNamed(const char* name) {
    return shstrtab_.Lookup(name) != StringTable::kNotIndexed;
  }

  void Add(Section* section, const char* name = nullptr) {
    ASSERT(!section->IsPseudoSection());
    ASSERT(name != nullptr || section->name_is_set());
    if (name != nullptr) {
      // First, check for an existing section with the same table name.
      if (auto* const old_section = Find(name)) {
        ASSERT(old_section->CanMergeWith(*section));
        old_section->Merge(*section);
        return;
      }
      // No existing section with this name.
      const intptr_t name_index = shstrtab_.Add(name);
      section->set_name(name_index);
    }
    section->index = sections_.length();
    sections_.Add(section);
  }

  Section* Find(const char* name) {
    const intptr_t name_index = shstrtab_.Lookup(name);
    if (name_index == StringTable::kNotIndexed) {
      // We're guaranteed that no section with this name has been added yet.
      return nullptr;
    }
    // We check walk all sections to check for uniqueness in DEBUG mode.
    Section* result = nullptr;
    for (Section* const section : sections_) {
      if (section->name() == name_index) {
#if defined(DEBUG)
        ASSERT(result == nullptr);
        result = section;
#else
        return section;
#endif
      }
    }
    return result;
  }

  intptr_t FileSize() const {
    return sections_.length() * sizeof(elf::SectionHeader);
  }

  void Write(ElfWriteStream* stream) const;

  // Reorders the sections for creating a minimal amount of segments and
  // creates and returns an appropriate program table.
  //
  // Also takes and adjusts section indices in the static symbol table, since it
  // is not recorded in sections_ for stripped outputs.
  ProgramTable* CreateProgramTable(SymbolTable* symtab);

 private:
  Zone* const zone_;
  GrowableArray<Section*> sections_;
  StringTable shstrtab_;
};

class ElfHeader : public PseudoSection {
 public:
  ElfHeader(const ProgramTable& program_table,
            const SectionTable& section_table)
      : PseudoSection(/*allocate=*/true,
                      /*executable=*/false,
                      /*writable=*/false),
        program_table_(program_table),
        section_table_(section_table) {}

  intptr_t MemorySize() const { return sizeof(elf::ElfHeader); }

  void Write(ElfWriteStream* stream) const;

 private:
  const ProgramTable& program_table_;
  const SectionTable& section_table_;
};

#undef DEFINE_TYPE_CHECK_FOR
#undef FOR_EACH_SECTION_TYPE

Elf::Elf(Zone* zone, BaseWriteStream* stream, Type type, Dwarf* dwarf)
    : zone_(zone),
      unwrapped_stream_(stream),
      type_(type),
      dwarf_(dwarf),
      section_table_(new (zone) SectionTable(zone)) {
  // Separate debugging information should always have a Dwarf object.
  ASSERT(type_ == Type::Snapshot || dwarf_ != nullptr);
  // Assumed by various offset logic in this file.
  ASSERT_EQUAL(unwrapped_stream_->Position(), 0);
}

void Elf::AddText(const char* name,
                  intptr_t label,
                  const uint8_t* bytes,
                  intptr_t size,
                  const ZoneGrowableArray<Relocation>* relocations,
                  const ZoneGrowableArray<SymbolData>* symbols) {
  auto* const container = new (zone_) TextSection(type_);
  container->AddPortion(bytes, size, relocations, symbols, name, label);
  section_table_->Add(container, kTextName);
}

void Elf::CreateBSS() {
  // Not idempotent.
  ASSERT(section_table_->Find(kBssName) == nullptr);
  // No text section means no BSS section.
  auto* const text_section = section_table_->Find(kTextName);
  if (text_section == nullptr) return;
  ASSERT(text_section->IsTextSection());

  auto* const bss_container = new (zone_) BssSection(type_);
  for (const auto& portion : text_section->AsBitsContainer()->portions()) {
    size_t size;
    const char* symbol_name;
    intptr_t label;
    // First determine whether this is the VM's text portion or the isolate's.
    if (strcmp(portion.symbol_name, kVmSnapshotInstructionsAsmSymbol) == 0) {
      size = BSS::kVmEntryCount * compiler::target::kWordSize;
      symbol_name = kVmSnapshotBssAsmSymbol;
      label = kVmBssLabel;
    } else if (strcmp(portion.symbol_name,
                      kIsolateSnapshotInstructionsAsmSymbol) == 0) {
      size = BSS::kIsolateGroupEntryCount * compiler::target::kWordSize;
      symbol_name = kIsolateSnapshotBssAsmSymbol;
      label = kIsolateBssLabel;
    } else {
      // Not VM or isolate text.
      UNREACHABLE();
      continue;
    }

    uint8_t* bytes = nullptr;
    if (type_ == Type::Snapshot) {
      // Ideally the BSS segment would take no space in the object, but
      // Android's "strip" utility truncates the memory-size of our segments to
      // their file-size.
      //
      // Therefore we must insert zero-filled data for the BSS.
      bytes = zone_->Alloc<uint8_t>(size);
      memset(bytes, 0, size);
    }
    // For the BSS section, we add the section symbols as local symbols in the
    // static symbol table, as these addresses are only used for relocation.
    // (This matches the behavior in the assembly output.)
    auto* symbols = new (zone_) ZoneGrowableArray<Elf::SymbolData>();
    symbols->Add({symbol_name, elf::STT_SECTION, 0, size, label});
    bss_container->AddPortion(bytes, size, /*relocations=*/nullptr, symbols);
  }

  section_table_->Add(bss_container, kBssName);
}

void Elf::AddROData(const char* name,
                    intptr_t label,
                    const uint8_t* bytes,
                    intptr_t size,
                    const ZoneGrowableArray<Relocation>* relocations,
                    const ZoneGrowableArray<SymbolData>* symbols) {
  auto* const container = new (zone_) DataSection(type_);
  container->AddPortion(bytes, size, relocations, symbols, name, label);
  section_table_->Add(container, kDataName);
}

#if defined(DART_PRECOMPILER)
class DwarfElfStream : public DwarfWriteStream {
 public:
  DwarfElfStream(Zone* zone, NonStreamingWriteStream* stream)
      : zone_(ASSERT_NOTNULL(zone)),
        stream_(ASSERT_NOTNULL(stream)),
        relocations_(new(zone) ZoneGrowableArray<Elf::Relocation>()) {}

  const uint8_t* buffer() const { return stream_->buffer(); }
  intptr_t bytes_written() const { return stream_->bytes_written(); }
  intptr_t Position() const { return stream_->Position(); }

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
  void WritePrefixedLength(const char* unused, std::function<void()> body) {
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
  }
  // Shorthand for when working directly with DwarfElfStreams.
  void WritePrefixedLength(std::function<void()> body) {
    WritePrefixedLength(nullptr, body);
  }

  void OffsetFromSymbol(intptr_t label, intptr_t offset) {
    relocations_->Add({kAddressSize, stream_->Position(),
                       Elf::Relocation::kSnapshotRelative, 0, label, offset});
    addr(0);  // Resolved later.
  }
  template <typename T>
  void RelativeSymbolOffset(intptr_t label) {
    relocations_->Add({sizeof(T), stream_->Position(),
                       Elf::Relocation::kSelfRelative, 0, label, 0});
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

void SymbolTable::Initialize(const GrowableArray<Section*>& sections) {
  for (auto* const section : sections) {
    // The values of all added symbols are memory addresses.
    if (!section->IsAllocated()) continue;
    if (auto* const bits = section->AsBitsContainer()) {
      for (const auto& portion : section->AsBitsContainer()->portions()) {
        if (portion.symbol_name != nullptr) {
          // Global dynamic symbols for the content of a given section, which is
          // always a single structured element (and thus we use STT_OBJECT).
          const intptr_t binding = elf::STB_GLOBAL;
          const intptr_t type = elf::STT_OBJECT;
          // Some tools assume the static symbol table is a superset of the
          // dynamic symbol table when it exists and only use it, so put all
          // dynamic symbols there also. (see dartbug.com/41783).
          AddSymbol(portion.symbol_name, binding, type, portion.size,
                    section->index, portion.offset, portion.label);
        }
        if (!dynamic_ && portion.symbols != nullptr) {
          for (const auto& symbol_data : *portion.symbols) {
            // Local static-only symbols, e.g., code payloads or RO objects.
            AddSymbol(symbol_data.name, elf::STB_LOCAL, symbol_data.type,
                      symbol_data.size, section->index,
                      portion.offset + symbol_data.offset, symbol_data.label);
          }
        }
      }
    }
  }
}

void Elf::InitializeSymbolTables() {
  // Not idempotent.
  ASSERT(symtab_ == nullptr);

  // Create static and dynamic symbol tables.
  auto* const dynstrtab = new (zone_) StringTable(zone_, /*allocate=*/true);
  section_table_->Add(dynstrtab, ".dynstr");
  auto* const dynsym =
      new (zone_) SymbolTable(zone_, dynstrtab, /*dynamic=*/true);
  section_table_->Add(dynsym, ".dynsym");
  dynsym->Initialize(section_table_->sections());
  // Now the dynamic symbol table is populated, set up the hash table and
  // dynamic table.
  auto* const hash = new (zone_) SymbolHashTable(zone_, dynsym);
  section_table_->Add(hash, ".hash");
  auto* const dynamic = new (zone_) DynamicTable(zone_, dynsym, hash);
  section_table_->Add(dynamic, kDynamicTableName);

  // We only add the static string and symbol tables to the section table if
  // this is an unstripped output, but we always create them as they are used
  // to resolve relocations.
  auto* const strtab = new (zone_) StringTable(zone_, /*allocate=*/false);
  if (!IsStripped()) {
    section_table_->Add(strtab, ".strtab");
  }
  symtab_ = new (zone_) SymbolTable(zone_, strtab, /*dynamic=*/false);
  if (!IsStripped()) {
    section_table_->Add(symtab_, ".symtab");
  }
  symtab_->Initialize(section_table_->sections());
}

void Elf::FinalizeEhFrame() {
#if !defined(TARGET_ARCH_IA32)
#if defined(TARGET_ARCH_X64)
  // The x86_64 psABI defines the DWARF register numbers, which differ from
  // the registers' usual encoding within instructions.
  const intptr_t DWARF_RA = 16;  // No corresponding register.
  const intptr_t DWARF_FP = 6;   // RBP
#else
  const intptr_t DWARF_RA = ConcreteRegister(LINK_REGISTER);
  const intptr_t DWARF_FP = FP;
#endif

  // No text section added means no .eh_frame.
  TextSection* text_section = nullptr;
  if (auto* const section = section_table_->Find(kTextName)) {
    text_section = section->AsTextSection();
    ASSERT(text_section != nullptr);
  }
  // No text section added means no .eh_frame.
  if (text_section == nullptr) return;

#if defined(DART_TARGET_OS_WINDOWS) && defined(TARGET_ARCH_X64)
  // Append Windows unwinding instructions to the end of .text section.
  {
    auto* const unwinding_instructions_frame = new (zone_) TextSection(type_);
    ZoneWriteStream stream(
        zone(),
        /*initial_size=*/UnwindingRecordsPlatform::SizeInBytes());
    uint8_t* unwinding_instructions =
        zone()->Alloc<uint8_t>(UnwindingRecordsPlatform::SizeInBytes());

    intptr_t start_offset =
        Utils::RoundUp(text_section->FileSize(), text_section->alignment);
    stream.WriteBytes(UnwindingRecords::GenerateRecordsInto(
                          start_offset, unwinding_instructions),
                      UnwindingRecordsPlatform::SizeInBytes());

    unwinding_instructions_frame->AddPortion(stream.buffer(),
                                             stream.bytes_written());
    section_table_->Add(unwinding_instructions_frame, kTextName);
  }
#endif

  // Multiplier which will be used to scale operands of DW_CFA_offset and
  // DW_CFA_val_offset.
  const intptr_t kDataAlignment = -compiler::target::kWordSize;

  static constexpr uint8_t DW_EH_PE_pcrel = 0x10;
  static constexpr uint8_t DW_EH_PE_sdata4 = 0x0b;

  ZoneWriteStream stream(zone(), kInitialDwarfBufferSize);
  DwarfElfStream dwarf_stream(zone_, &stream);

  // Emit CIE.

  // Used to calculate offset to CIE in FDEs.
  const intptr_t cie_start = dwarf_stream.Position();
  dwarf_stream.WritePrefixedLength([&] {
    dwarf_stream.u4(0);  // CIE
    dwarf_stream.u1(1);  // Version (must be 1 or 3)
    // Augmentation String
    dwarf_stream.string("zR");             // NOLINT
    dwarf_stream.uleb128(1);               // Code alignment (must be 1).
    dwarf_stream.sleb128(kDataAlignment);  // Data alignment
    dwarf_stream.u1(DWARF_RA);             // Return address register
    dwarf_stream.uleb128(1);               // Augmentation size
    dwarf_stream.u1(DW_EH_PE_pcrel | DW_EH_PE_sdata4);  // FDE encoding.
    // CFA is caller's SP (FP+kCallerSpSlotFromFp*kWordSize)
    dwarf_stream.u1(Dwarf::DW_CFA_def_cfa);
    dwarf_stream.uleb128(DWARF_FP);
    dwarf_stream.uleb128(kCallerSpSlotFromFp * compiler::target::kWordSize);
  });

  // Emit rule defining that |reg| value is stored at CFA+offset.
  const auto cfa_offset = [&](intptr_t reg, intptr_t offset) {
    const intptr_t scaled_offset = offset / kDataAlignment;
    RELEASE_ASSERT(scaled_offset >= 0);
    dwarf_stream.u1(Dwarf::DW_CFA_offset | reg);
    dwarf_stream.uleb128(scaled_offset);
  };

  // Emit an FDE covering each .text section.
  for (const auto& portion : text_section->portions()) {
#if defined(DART_TARGET_OS_WINDOWS) && defined(TARGET_ARCH_X64)
    if (portion.label == 0) {
      // Unwinding instructions sections doesn't have label, doesn't dwarf
      continue;
    }
#endif
    ASSERT(portion.label != 0);  // Needed for relocations.
    dwarf_stream.WritePrefixedLength([&]() {
      // Offset to CIE. Note that unlike pcrel this offset is encoded
      // backwards: it will be subtracted from the current position.
      dwarf_stream.u4(stream.Position() - cie_start);
      // Start address as a PC relative reference.
      dwarf_stream.RelativeSymbolOffset<int32_t>(portion.label);
      dwarf_stream.u4(portion.size);           // Size.
      dwarf_stream.u1(0);                      // Augmentation Data length.

      // Caller FP at FP+kSavedCallerPcSlotFromFp*kWordSize,
      // where FP is CFA - kCallerSpSlotFromFp*kWordSize.
      COMPILE_ASSERT((kSavedCallerFpSlotFromFp - kCallerSpSlotFromFp) <= 0);
      cfa_offset(DWARF_FP, (kSavedCallerFpSlotFromFp - kCallerSpSlotFromFp) *
                               compiler::target::kWordSize);

      // Caller LR at FP+kSavedCallerPcSlotFromFp*kWordSize,
      // where FP is CFA - kCallerSpSlotFromFp*kWordSize
      COMPILE_ASSERT((kSavedCallerPcSlotFromFp - kCallerSpSlotFromFp) <= 0);
      cfa_offset(DWARF_RA, (kSavedCallerPcSlotFromFp - kCallerSpSlotFromFp) *
                               compiler::target::kWordSize);
    });
  }

  dwarf_stream.u4(0);  // end of section (FDE with zero length)

  auto* const eh_frame = new (zone_)
      BitsContainer(type_, /*writable=*/false, /*executable=*/false);
  eh_frame->AddPortion(dwarf_stream.buffer(), dwarf_stream.bytes_written(),
                       dwarf_stream.relocations());
  section_table_->Add(eh_frame, ".eh_frame");
#endif  // !defined(TARGET_ARCH_IA32)
}

void Elf::FinalizeDwarfSections() {
  if (dwarf_ == nullptr) return;

  // Currently we only output DWARF information involving code.
  ASSERT(section_table_->HasSectionNamed(kTextName));

  auto add_debug = [&](const char* name, const DwarfElfStream& stream) {
    auto const container =
        new (zone_) BitsContainer(elf::SectionHeaderType::SHT_PROGBITS);
    container->AddPortion(stream.buffer(), stream.bytes_written(),
                          stream.relocations());
    section_table_->Add(container, name);
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
}

ProgramTable* SectionTable::CreateProgramTable(SymbolTable* symtab) {
  const intptr_t num_sections = sections_.length();
  // Should have at least the reserved entry in sections_.
  ASSERT(!sections_.is_empty());
  ASSERT_EQUAL(sections_[0]->alignment, 0);

  // The new program table that collects the segments for allocated sections
  // and a few special segments.
  auto* const program_table = new (zone_) ProgramTable(zone_);

  GrowableArray<Section*> reordered_sections(zone_, num_sections);
  // Maps the old indices of sections to the new ones.
  GrowableArray<intptr_t> index_map(zone_, num_sections);
  index_map.FillWith(0, 0, num_sections);

  Segment* current_segment = nullptr;
  // Only called for sections in the section table (i.e., not special sections
  // appearing in segments only or the section table itself).
  auto add_to_reordered_sections = [&](Section* section) {
    intptr_t new_index = reordered_sections.length();
    index_map[section->index] = new_index;
    section->index = new_index;
    reordered_sections.Add(section);
    if (section->IsAllocated()) {
      ASSERT(current_segment != nullptr);
      if (!current_segment->Add(section)) {
        // The current segment is incompatible for the current sectioni, so
        // create a new one.
        current_segment = new (zone_)
            Segment(zone_, section, elf::ProgramHeaderType::PT_LOAD);
        program_table->Add(current_segment);
      }
    }
  };

  // The first section in the section header table is always a reserved
  // entry containing only 0 values, so copy it over from sections_.
  add_to_reordered_sections(sections_[0]);

  // There are few important invariants originating from Android idiosyncrasies
  // we are trying to maintain when ordering sections:
  //
  //   - Android requires the program header table be in the first load segment,
  //     so create PseudoSections representing the ELF header and program header
  //     table to initialize that segment.
  //
  //   - The Android dynamic linker in Jelly Bean incorrectly assumes that all
  //     non-writable segments are contiguous. Thus we write them all together.
  //     The bug is here: https://github.com/aosp-mirror/platform_bionic/blob/94963af28e445384e19775a838a29e6a71708179/linker/linker.c#L1991-L2001
  //
  //   - On Android native libraries can be mapped directly from an APK
  //     they are stored uncompressed in it. In such situations the name
  //     of the mapping no longer provides enough information for libunwindstack
  //     to find the original ELF file and instead it has to rely on heuristics
  //     to locate program header table. These heuristics currently assume that
  //     program header table will be located in the RO mapping which precedes
  //     RX mapping.
  //
  // These invariants imply the following order of segments: RO (program
  // header,  .note.gnu.build-id, .dynstr, .dynsym, .hash, .rodata
  // and .eh_frame), RX (.text), RW (.dynamic and .bss).
  //
  auto* const elf_header = new (zone_) ElfHeader(*program_table, *this);

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  program_table->Add(new (zone_) Segment(zone_, program_table,
                                         elf::ProgramHeaderType::PT_PHDR));

  // Create the initial load segment which contains the ELF header and program
  // table.
  current_segment =
      new (zone_) Segment(zone_, elf_header, elf::ProgramHeaderType::PT_LOAD);
  program_table->Add(current_segment);
  current_segment->Add(program_table);

  // We now do several passes over the collected sections to reorder them in
  // a way that minimizes segments (and thus padding) in the resulting snapshot.

  auto add_sections_matching =
      [&](const std::function<bool(Section*)>& should_add) {
        // We order the sections in a segment so all non-NOBITS sections come
        // before NOBITS sections, since the former sections correspond to the
        // file contents for the segment.
        for (auto* const section : sections_) {
          if (!section->HasBits()) continue;
          if (should_add(section)) {
            add_to_reordered_sections(section);
          }
        }
        for (auto* const section : sections_) {
          if (section->HasBits()) continue;
          if (should_add(section)) {
            add_to_reordered_sections(section);
          }
        }
      };

  // If a build ID was created, we put it right after the program table so it
  // can be read with a minimum number of bytes from the ELF file.
  auto* const build_id = Find(Elf::kBuildIdNoteName);
  if (build_id != nullptr) {
    ASSERT(build_id->type == elf::SectionHeaderType::SHT_NOTE);
    add_to_reordered_sections(build_id);
  }

  // Now add the other non-writable, non-executable allocated sections.
  add_sections_matching([&](Section* section) -> bool {
    if (section == build_id) return false;  // Already added.
    return section->IsAllocated() && !section->IsWritable() &&
           !section->IsExecutable();
  });

  // Now add the executable sections in a new segment.
  add_sections_matching([](Section* section) -> bool {
    return section->IsExecutable();  // Implies IsAllocated() && !IsWritable()
  });

  // Now add all the writable sections.
  add_sections_matching([](Section* section) -> bool {
    return section->IsWritable();  // Implies IsAllocated() && !IsExecutable()
  });

  // We put all non-reserved unallocated sections last. Otherwise, they would
  // affect the file offset but not the memory offset of any following allocated
  // sections. Doing it in this order makes it easier to keep file and memory
  // offsets page-aligned with respect to each other, which is required for
  // some loaders.
  add_sections_matching([](Section* section) -> bool {
    // Don't re-add the initial reserved section.
    return !section->IsReservedSection() && !section->IsAllocated();
  });

  // All sections should have been accounted for in the loops above.
  ASSERT_EQUAL(sections_.length(), reordered_sections.length());
  // Replace the content of sections_ with the reordered sections.
  sections_.Clear();
  sections_.AddArray(reordered_sections);

  // This must be true for uses of the map to be correct.
  ASSERT_EQUAL(index_map[elf::SHN_UNDEF], elf::SHN_UNDEF);

  // Since the section indices have been updated, change links to match
  // and update the indexes of symbols in any symbol tables.
  for (auto* const section : sections_) {
    // SHN_UNDEF maps to SHN_UNDEF, so no need to check for it.
    section->link = index_map[section->link];
    if (auto* const table = section->AsSymbolTable()) {
      table->UpdateSectionIndices(index_map);
    }
  }
  if (symtab->index == elf::SHN_UNDEF) {
    // The output is stripped, so this wasn't finalized during the loop above.
    symtab->UpdateSectionIndices(index_map);
  }

  // Add any special non-load segments.
  if (build_id != nullptr) {
    // Add a PT_NOTE segment for the build ID.
    program_table->Add(
        new (zone_) Segment(zone_, build_id, elf::ProgramHeaderType::PT_NOTE));
  }

  // Add a PT_DYNAMIC segment for the dynamic symbol table.
  ASSERT(HasSectionNamed(Elf::kDynamicTableName));
  auto* const dynamic = Find(Elf::kDynamicTableName)->AsDynamicTable();
  program_table->Add(
      new (zone_) Segment(zone_, dynamic, elf::ProgramHeaderType::PT_DYNAMIC));

  // Add a PT_GNU_STACK segment to prevent the loading of our snapshot from
  // switch the stack to be executable.
  auto* const gnu_stack = new (zone_) GnuStackSection();
  program_table->Add(new (zone_) Segment(zone_, gnu_stack,
                                         elf::ProgramHeaderType::PT_GNU_STACK));

  return program_table;
}

void Elf::Finalize() {
  // Generate the build ID now that we have all user-provided sections.
  GenerateBuildId();

  // We add a BSS section in all cases, even to the separate debugging
  // information, to ensure that relocated addresses are consistent between ELF
  // snapshots and the corresponding separate debugging information.
  CreateBSS();

  FinalizeEhFrame();
  FinalizeDwarfSections();

  // Create and initialize the dynamic and static symbol tables and any
  // other associated sections now that all other sections have been added.
  InitializeSymbolTables();
  // Creates an appropriate program table containing load segments for allocated
  // sections and any other segments needed. May reorder sections to minimize
  // the number of load segments, so also takes the static symbol table so
  // symbol section indices can be adjusted if needed.
  program_table_ = section_table_->CreateProgramTable(symtab_);
  // Calculate file and memory offsets, and finalizes symbol values in any
  // symbol tables.
  ComputeOffsets();

#if defined(DEBUG)
  if (type_ == Type::Snapshot) {
    // For files that will be dynamically loaded, ensure the file offsets
    // of allocated sections are page aligned to the memory offsets.
    for (auto* const segment : program_table_->segments()) {
      for (auto* const section : segment->sections()) {
        ASSERT_EQUAL(section->file_offset() % Elf::kPageSize,
                     section->memory_offset() % Elf::kPageSize);
      }
    }
  }
#endif

  // Finally, write the ELF file contents.
  ElfWriteStream wrapped(unwrapped_stream_, *this);

  auto write_section = [&](const Section* section) {
    wrapped.Align(section->alignment);
    ASSERT_EQUAL(wrapped.Position(), section->file_offset());
    section->Write(&wrapped);
    ASSERT_EQUAL(wrapped.Position(),
                 section->file_offset() + section->FileSize());
  };

  // To match ComputeOffsets, first we write allocated sections and then
  // unallocated sections. We access the allocated sections via the load
  // segments so we can properly align the stream for each entered segment.
  intptr_t section_index = 1;  // We don't visit the reserved section.
  for (auto* const segment : program_table_->segments()) {
    if (segment->type != elf::ProgramHeaderType::PT_LOAD) continue;
    wrapped.Align(segment->Alignment());
    for (auto* const section : segment->sections()) {
      ASSERT(section->IsAllocated());
      write_section(section);
      if (!section->IsPseudoSection()) {
        ASSERT_EQUAL(section->index, section_index);
        section_index++;
      }
    }
  }
  const auto& sections = section_table_->sections();
  for (; section_index < sections.length(); section_index++) {
    auto* const section = sections[section_index];
    ASSERT(!section->IsAllocated());
    write_section(section);
  }
  // Finally, write the section table.
  write_section(section_table_);
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
  // Not idempotent.
  ASSERT(section_table_->Find(kBuildIdNoteName) == nullptr);
  uint32_t hashes[kBuildIdSegmentNamesLength];
  // Currently, we construct the build ID out of data from two different
  // sections: the .text section and the .rodata section. We only create
  // a build ID when we have all four sections and when we have the actual
  // bytes from those sections.
  //
  // TODO(dartbug.com/43274): Generate build IDs for separate debugging
  // information for assembly snapshots.
  //
  // TODO(dartbug.com/43516): Generate build IDs for snapshots with deferred
  // sections.
  auto* const text_section = section_table_->Find(kTextName);
  if (text_section == nullptr) return;
  ASSERT(text_section->IsTextSection());
  auto* const text_bits = text_section->AsBitsContainer();
  auto* const data_section = section_table_->Find(kDataName);
  if (data_section == nullptr) return;
  ASSERT(data_section->IsDataSection());
  auto* const data_bits = data_section->AsBitsContainer();
  // Now try to find
  for (intptr_t i = 0; i < kBuildIdSegmentNamesLength; i++) {
    auto* const name = kBuildIdSegmentNames[i];
    hashes[i] = text_bits->Hash(name);
    if (hashes[i] == 0) {
      hashes[i] = data_bits->Hash(name);
    }
    // The symbol wasn't found in either section or there were no bytes
    // associated with the symbol.
    if (hashes[i] == 0) return;
  }
  auto const description_bytes = reinterpret_cast<uint8_t*>(hashes);
  const size_t description_length = sizeof(hashes);
  // Now that we have the description field contents, create the section.
  ZoneWriteStream stream(zone(), kBuildIdHeaderSize + description_length);
  stream.WriteFixed<decltype(elf::Note::name_size)>(sizeof(elf::ELF_NOTE_GNU));
  stream.WriteFixed<decltype(elf::Note::description_size)>(description_length);
  stream.WriteFixed<decltype(elf::Note::type)>(elf::NoteType::NT_GNU_BUILD_ID);
  ASSERT_EQUAL(stream.Position(), sizeof(elf::Note));
  stream.WriteBytes(elf::ELF_NOTE_GNU, sizeof(elf::ELF_NOTE_GNU));
  ASSERT_EQUAL(stream.bytes_written(), kBuildIdHeaderSize);
  stream.WriteBytes(description_bytes, description_length);
  auto* const container = new (zone_) NoteSection();
  container->AddPortion(stream.buffer(), stream.bytes_written(),
                        /*relocations=*/nullptr, /*symbols=*/nullptr,
                        kSnapshotBuildIdAsmSymbol, kBuildIdLabel);
  section_table_->Add(container, kBuildIdNoteName);
}

void Elf::ComputeOffsets() {
  intptr_t file_offset = 0;
  intptr_t memory_offset = 0;

  // Maps indices of allocated sections in the section table to memory offsets.
  const intptr_t num_sections = section_table_->SectionCount();
  GrowableArray<intptr_t> address_map(zone_, num_sections);
  address_map.Add(0);  // Don't adjust offsets for symbols with index SHN_UNDEF.

  auto calculate_section_offsets = [&](Section* section) {
    file_offset = Utils::RoundUp(file_offset, section->alignment);
    section->set_file_offset(file_offset);
    file_offset += section->FileSize();
    if (section->IsAllocated()) {
      memory_offset = Utils::RoundUp(memory_offset, section->alignment);
      section->set_memory_offset(memory_offset);
      memory_offset += section->MemorySize();
    }
  };

  intptr_t section_index = 1;  // We don't visit the reserved section.
  for (auto* const segment : program_table_->segments()) {
    if (segment->type != elf::ProgramHeaderType::PT_LOAD) continue;
    // Adjust file and memory offsets for segment alignment on entry.
    file_offset = Utils::RoundUp(file_offset, segment->Alignment());
    memory_offset = Utils::RoundUp(memory_offset, segment->Alignment());
    for (auto* const section : segment->sections()) {
      ASSERT(section->IsAllocated());
      calculate_section_offsets(section);
      if (!section->IsPseudoSection()) {
        // Note: this assumes that the sections in the section header has all
        // allocated sections before all (non-reserved) unallocated sections and
        // in the same order as the load segments in in the program table.
        address_map.Add(section->memory_offset());
        ASSERT_EQUAL(section->index, section_index);
        section_index++;
      }
    }
  }

  const auto& sections = section_table_->sections();
  for (; section_index < sections.length(); section_index++) {
    auto* const section = sections[section_index];
    ASSERT(!section->IsAllocated());
    calculate_section_offsets(section);
  }

  ASSERT_EQUAL(section_index, sections.length());
  // Now that all sections have been handled, set the file offset for the
  // section table, as it will be written after the last section.
  calculate_section_offsets(section_table_);

#if defined(DEBUG)
  // Double check that segment starts are aligned as expected.
  for (auto* const segment : program_table_->segments()) {
    ASSERT(Utils::IsAligned(segment->MemoryOffset(), segment->Alignment()));
  }
#endif

  // This must be true for uses of the map to be correct.
  ASSERT_EQUAL(address_map[elf::SHN_UNDEF], 0);
  // Adjust addresses in symbol tables as we now have section memory offsets.
  // Also finalize the entries of the dynamic table, as some are memory offsets.
  for (auto* const section : sections) {
    if (auto* const table = section->AsSymbolTable()) {
      table->Finalize(address_map);
    } else if (auto* const dynamic = section->AsDynamicTable()) {
      dynamic->Finalize();
    }
  }
  // Also adjust addresses in symtab for stripped snapshots.
  if (IsStripped()) {
    ASSERT_EQUAL(symtab_->index, elf::SHN_UNDEF);
    symtab_->Finalize(address_map);
  }
}

void ElfHeader::Write(ElfWriteStream* stream) const {
  ASSERT_EQUAL(file_offset(), 0);
  ASSERT_EQUAL(memory_offset(), 0);
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
#elif defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
  stream->WriteHalf(elf::EM_RISCV);
#else
  FATAL("Unknown ELF architecture");
#endif

  stream->WriteWord(elf::EV_CURRENT);  // Version
  stream->WriteAddr(0);                // "Entry point"
  stream->WriteOff(program_table_.file_offset());
  stream->WriteOff(section_table_.file_offset());

#if defined(TARGET_ARCH_ARM)
  uword flags = elf::EF_ARM_ABI | (TargetCPUFeatures::hardfp_supported()
                                       ? elf::EF_ARM_ABI_FLOAT_HARD
                                       : elf::EF_ARM_ABI_FLOAT_SOFT);
#else
  uword flags = 0;
#endif
  stream->WriteWord(flags);

  stream->WriteHalf(sizeof(elf::ElfHeader));
  stream->WriteHalf(program_table_.entry_size);
  stream->WriteHalf(program_table_.SegmentCount());
  stream->WriteHalf(section_table_.entry_size);
  stream->WriteHalf(section_table_.SectionCount());
  stream->WriteHalf(stream->elf().section_table().StringTableIndex());
}

void ProgramTable::Write(ElfWriteStream* stream) const {
  ASSERT(segments_.length() > 0);
  // Make sure all relevant segments were created by checking the type of the
  // first.
  ASSERT(segments_[0]->type == elf::ProgramHeaderType::PT_PHDR);
  const intptr_t start = stream->Position();
  // Should be immediately following the ELF header.
  ASSERT_EQUAL(start, sizeof(elf::ElfHeader));
#if defined(DEBUG)
  // Here, we count the number of times that a PT_LOAD writable segment is
  // followed by a non-writable segment. We initialize last_writable to true
  // so that we catch the case where the first segment is non-writable.
  bool last_writable = true;
  int non_writable_groups = 0;
#endif
  for (intptr_t i = 0; i < segments_.length(); i++) {
    const Segment* const segment = segments_[i];
    ASSERT(segment->type != elf::ProgramHeaderType::PT_NULL);
    ASSERT_EQUAL(i == 0, segment->type == elf::ProgramHeaderType::PT_PHDR);
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
    ASSERT_EQUAL(end - start, entry_size);
  }
#if defined(DEBUG)
  // All PT_LOAD non-writable segments must be contiguous. If not, some older
  // Android dynamic linkers fail to handle writable segments between
  // non-writable ones. See https://github.com/flutter/flutter/issues/43259.
  ASSERT(non_writable_groups <= 1);
#endif
}

void SectionTable::Write(ElfWriteStream* stream) const {
  for (intptr_t i = 0; i < sections_.length(); i++) {
    const Section* const section = sections_[i];
    ASSERT_EQUAL(i == 0, section->IsReservedSection());
    ASSERT_EQUAL(section->index, i);
    ASSERT(section->link < sections_.length());
    const intptr_t start = stream->Position();
    section->WriteSectionHeader(stream);
    const intptr_t end = stream->Position();
    ASSERT_EQUAL(end - start, entry_size);
  }
}

#endif  // DART_PRECOMPILER

}  // namespace dart
