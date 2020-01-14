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
  virtual void Write(StreamingWriteStream* stream) = 0;

  // Linker view.
  intptr_t section_name = -1;  // Index into shstrtab_.
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

  enum OutputType {
    kMainOutput,
    kDebugOutput,
    kAllOutput,
  };

  // When this section should be output, if we are stripping and/or splitting
  // debugging information. Only a few sections are not part of the main
  // (non-debugging) output, so we use kMainOutput as the default value.
  OutputType output_type = kMainOutput;
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

  void Write(StreamingWriteStream* stream) {
    if (bytes_ != nullptr) {
      Elf::WriteBytes(stream, bytes_, file_size);
    }
  }

  const uint8_t* bytes_;
};

class StringTable : public Section {
 public:
  explicit StringTable(bool dynamic) : text_(128), text_indices_() {
    section_type = elf::SHT_STRTAB;
    if (dynamic) {
      section_flags = elf::SHF_ALLOC;
      segment_type = elf::PT_LOAD;
      segment_flags = elf::PF_R;
    } else {
      section_flags = 0;
      memory_offset = 0;  // No segments for static tables.
    }

    text_.AddChar('\0');
    text_indices_.Insert({"", 1});
    memory_size = file_size = text_.length();
  }

  intptr_t AddString(const char* str) {
    if (auto const kv = text_indices_.Lookup(str)) return kv->value - 1;
    intptr_t offset = text_.length();
    text_.AddString(str);
    text_.AddChar('\0');
    text_indices_.Insert({str, offset + 1});
    memory_size = file_size = text_.length();
    return offset;
  }

  const char* GetString(intptr_t index) {
    ASSERT(index >= 0 && index < text_.length());
    return text_.buf() + index;
  }

  void Write(StreamingWriteStream* stream) {
    Elf::WriteBytes(stream, reinterpret_cast<const uint8_t*>(text_.buf()),
                    text_.length());
  }

  TextBuffer text_;
  // To avoid kNoValue for intptr_t (0), we store an index n as n + 1.
  CStringMap<intptr_t> text_indices_;
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
  explicit SymbolTable(bool dynamic) {
    if (dynamic) {
      section_type = elf::SHT_DYNSYM;
      section_flags = elf::SHF_ALLOC;
      segment_type = elf::PT_LOAD;
      segment_flags = elf::PF_R;
    } else {
      // No need to load the static symbol table at runtime since it's ignored
      // by the dynamic linker.
      section_type = elf::SHT_SYMTAB;
      section_flags = 0;
      memory_offset = 0;  // No segments for static tables.
      alignment = compiler::target::kWordSize;
    }

    section_entry_size = kElfSymbolTableEntrySize;
    section_info = 0;
    AddSymbol(nullptr);
  }

  void AddSymbol(Symbol* symbol) {
    // Adjust section_info to contain the count of local symbols, including the
    // reserved first entry (represented by the nullptr value).
    if (symbol == nullptr || ((symbol->info >> 4) == elf::STB_LOCAL)) {
      section_info += 1;
    }
    symbols_.Add(symbol);
    memory_size += kElfSymbolTableEntrySize;
    file_size += kElfSymbolTableEntrySize;
  }

  void Write(StreamingWriteStream* stream) {
    // The first symbol table entry is reserved and must be all zeros.
    {
      const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
      Elf::WriteWord(stream, 0);
      Elf::WriteAddr(stream, 0);
      Elf::WriteWord(stream, 0);
      Elf::WriteByte(stream, 0);
      Elf::WriteByte(stream, 0);
      Elf::WriteHalf(stream, 0);
#else
      Elf::WriteWord(stream, 0);
      Elf::WriteByte(stream, 0);
      Elf::WriteByte(stream, 0);
      Elf::WriteHalf(stream, 0);
      Elf::WriteAddr(stream, 0);
      Elf::WriteXWord(stream, 0);
#endif
      const intptr_t end = stream->position();
      ASSERT((end - start) == kElfSymbolTableEntrySize);
    }

    for (intptr_t i = 1; i < symbols_.length(); i++) {
      Symbol* symbol = symbols_[i];
      const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
      Elf::WriteWord(stream, symbol->name);
      Elf::WriteAddr(stream, symbol->offset);
      Elf::WriteWord(stream, symbol->size);
      Elf::WriteByte(stream, symbol->info);
      Elf::WriteByte(stream, 0);
      Elf::WriteHalf(stream, symbol->section);
#else
      Elf::WriteWord(stream, symbol->name);
      Elf::WriteByte(stream, symbol->info);
      Elf::WriteByte(stream, 0);
      Elf::WriteHalf(stream, symbol->section);
      Elf::WriteAddr(stream, symbol->offset);
      Elf::WriteXWord(stream, symbol->size);
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

  void Write(StreamingWriteStream* stream) {
    Elf::WriteWord(stream, nbucket_);
    Elf::WriteWord(stream, nchain_);
    for (intptr_t i = 0; i < nbucket_; i++) {
      Elf::WriteWord(stream, bucket_[i]);
    }
    for (intptr_t i = 0; i < nchain_; i++) {
      Elf::WriteWord(stream, chain_[i]);
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

  void Write(StreamingWriteStream* stream) {
    for (intptr_t i = 0; i < entries_.length(); i++) {
      const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
      Elf::WriteWord(stream, entries_[i]->tag);
      Elf::WriteAddr(stream, entries_[i]->value);
#else
      Elf::WriteXWord(stream, entries_[i]->tag);
      Elf::WriteAddr(stream, entries_[i]->value);
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

Elf::Elf(Zone* zone,
         StreamingWriteStream* stream,
         bool strip,
         StreamingWriteStream* debug_stream)
    : zone_(ASSERT_NOTNULL(zone)),
      strip_(strip),
      stream_(stream),
      debug_stream_(debug_stream),
      sections_(zone, 2),
      segments_(zone, 2),
      active_sections_(zone, 2),
      output_sections_(zone, 2),
      adjusted_indices_(zone),
      file_sizes_(zone, 2),
      section_names_(zone, 2),
      section_types_(zone, 2) {
  // We should be outputting at least one file.
  ASSERT(stream_ != nullptr || debug_stream_ != nullptr);
  // Stripping the main output only makes sense if it'll be output.
  ASSERT(!strip || stream_ != nullptr);

  // Assumed by various offset logic in this file.
  ASSERT(stream_ == nullptr || stream_->position() == 0);
  ASSERT(debug_stream_ == nullptr || debug_stream_->position() == 0);

  // All our strings would fit in a single page. However, we use separate
  // .shstrtab and .dynstr to work around a bug in Android's strip utility.
  shstrtab_ = new (zone_) StringTable(/*dynamic=*/false);
  shstrtab_->output_type = Section::kAllOutput;

  dynstrtab_ = new (zone_) StringTable(/*dynamic=*/true);
  dynsym_ = new (zone_) SymbolTable(/*dynamic=*/true);

  // The (non-section header) static tables are not needed in stripped output.
  strtab_ = new (zone_) StringTable(/*dynamic=*/false);
  strtab_->output_type = Section::kDebugOutput;
  symtab_ = new (zone_) SymbolTable(/*dynamic=*/false);
  symtab_->output_type = Section::kDebugOutput;

  // Allocate regular segments after the program table.
  memory_offset_ = kProgramTableSegmentSize;
}

void Elf::AddSection(Section* section, const char* name) {
  section->section_index = NextSectionIndex();
  section->section_name = shstrtab_->AddString(name);
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

intptr_t Elf::NextSectionIndex() const {
  return sections_.length() + kNumInvalidSections;
}

intptr_t Elf::AddText(const char* name, const uint8_t* bytes, intptr_t size) {
  ProgramBits* image = new (zone_) ProgramBits(true, true, false, bytes, size);
  AddSection(image, ".text");
  AddSegment(image);

  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = dynstrtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
  symbol->section = image->section_index;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = image->memory_offset;
  symbol->size = size;
  dynsym_->AddSymbol(symbol);

  return symbol->offset;
}

void Elf::AddStaticSymbol(intptr_t section,
                          const char* name,
                          size_t memory_offset) {
  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = strtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_FUNC;
  symbol->section = section;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = memory_offset;
  symbol->size = 0;
  symtab_->AddSymbol(symbol);
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
  AddSection(image, ".bss");
  AddSegment(image);

  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = dynstrtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_OBJECT;
  symbol->section = image->section_index;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = image->memory_offset;
  symbol->size = size;
  dynsym_->AddSymbol(symbol);

  return symbol->offset;
}

intptr_t Elf::AddROData(const char* name, const uint8_t* bytes, intptr_t size) {
  ProgramBits* image = new (zone_) ProgramBits(true, false, false, bytes, size);
  AddSection(image, ".rodata");
  AddSegment(image);

  Symbol* symbol = new (zone_) Symbol();
  symbol->cstr = name;
  symbol->name = dynstrtab_->AddString(name);
  symbol->info = (elf::STB_GLOBAL << 4) | elf::STT_OBJECT;
  symbol->section = image->section_index;
  // For shared libraries, this is the offset from the DSO base. For static
  // libraries, this is section relative.
  symbol->offset = image->memory_offset;
  symbol->size = size;
  dynsym_->AddSymbol(symbol);

  return symbol->offset;
}

void Elf::AddDebug(const char* name, const uint8_t* bytes, intptr_t size) {
  ProgramBits* image =
      new (zone_) ProgramBits(false, false, false, bytes, size);
  image->output_type = Section::kDebugOutput;
  AddSection(image, name);
}

void Elf::Finalize() {
  SymbolHashTable* hash = new (zone_) SymbolHashTable(dynstrtab_, dynsym_);

  AddSection(hash, ".hash");
  AddSection(dynsym_, ".dynsym");
  AddSection(dynstrtab_, ".dynstr");

  dynsym_->section_link = dynstrtab_->section_index;
  hash->section_link = dynsym_->section_index;

  // Finalizes memory size of string and symbol tables.
  AddSegment(hash);
  AddSegment(dynsym_);
  AddSegment(dynstrtab_);

  dynamic_ = new (zone_) DynamicTable(dynstrtab_, dynsym_, hash);
  AddSection(dynamic_, ".dynamic");
  AddSegment(dynamic_);

  // We only output the static symbol and string tables if they are non-empty.
  // We only need to check symtab_, since entries are added to strtab_ whenever
  // we add symbols. Here, an "empty" static symbol table only has one entry
  // (a nullptr value for the initial reserved entry).
  if (symtab_->symbols_.length() > 1) {
    AddSection(symtab_, ".symtab");
    AddSection(strtab_, ".strtab");
    symtab_->section_link = strtab_->section_index;
  }

  // The section header string table should come last.
  AddSection(shstrtab_, ".shstrtab");

  if (debug_stream_ != nullptr) {
    PrepareDebugOutputInfo();
    WriteHeader(debug_stream_);
    WriteProgramTable(debug_stream_);
    WriteSections(debug_stream_);
    WriteSectionTable(debug_stream_);
  }

  if (stream_ != nullptr) {
    PrepareMainOutputInfo();
    WriteHeader(stream_);
    WriteProgramTable(stream_);
    WriteSections(stream_);
    WriteSectionTable(stream_);
  }
}

void Elf::ClearOutputInfo() {
  active_sections_.Clear();
  output_sections_.Clear();
  adjusted_indices_.Clear();
  file_sizes_.Clear();
  section_names_.Clear();
  section_types_.Clear();

  // These don't need to be cleared normally, but doing so in DEBUG mode
  // may help us catch issues.
#if defined(DEBUG)
  section_table_entry_count_ = -1;
  section_table_file_offset_ = -1;
  program_table_entry_count_ = -1;
  program_table_file_offset_ = -1;
  for (auto section : sections_) {
    section->file_offset = -1;
  }
#endif
}

intptr_t Elf::ActiveSectionsIndex(intptr_t section_index) const {
  // This assumes all invalid sections come first in the table.
  ASSERT(section_index >= kNumInvalidSections);
  return SectionTableIndex(section_index) - kNumInvalidSections;
}

intptr_t Elf::SectionTableIndex(intptr_t section_index) const {
  // This assumes all invalid sections come first in the table.
  if (section_index < kNumInvalidSections) return section_index;
  ASSERT(adjusted_indices_.HasKey(section_index));
  return adjusted_indices_.LookupValue(section_index);
}

intptr_t Elf::ProgramTableSize() const {
  ASSERT(program_table_entry_count_ >= 0);
  return program_table_entry_count_ * kElfProgramTableEntrySize;
}

intptr_t Elf::SectionTableSize() const {
  ASSERT(section_table_entry_count_ >= 0);
  return section_table_entry_count_ * kElfSectionTableEntrySize;
}

void Elf::VerifyOutputInfo() const {
#if defined(DEBUG)
  // The section header string table should always be the last section. We can't
  // check for shstrtab_ because we recreate it to trim and reorder entries.
  ASSERT(active_sections_.Last()->section_type == elf::SHT_STRTAB);
  ASSERT(active_sections_.Last()->section_flags == 0);
  auto const shstrtab = reinterpret_cast<StringTable*>(active_sections_.Last());

  ASSERT(file_sizes_.length() == active_sections_.length());
  ASSERT(section_names_.length() == active_sections_.length());
  ASSERT(section_types_.length() == active_sections_.length());
  // Need this to output the section header.
  ASSERT(adjusted_indices_.HasKey(shstrtab->section_index));
  // Need this to output the dynamic section of the program table.
  ASSERT(adjusted_indices_.HasKey(dynamic_->section_index));

  // Perform extra checks on the Section GrowableArrays used in output
  // (segments_, active_sections_, and output_sections_), including that
  // they appear in the same order as in sections_.
  intptr_t last_index = 0;
  for (auto section : segments_) {
    ASSERT(section->file_offset != -1);
    ASSERT(section->section_index > last_index);
    last_index = section->section_index;
    auto const index = ActiveSectionsIndex(section->section_index);
    ASSERT(index >= 0 && index < active_sections_.length());
    ASSERT(file_sizes_.At(index) == 0 ||
           file_sizes_.At(index) == section->file_size);
  }

  last_index = 0;
  for (auto section : active_sections_) {
    ASSERT(section->file_offset != -1);
    ASSERT(section->section_index > last_index);
    last_index = section->section_index;
    auto const index = ActiveSectionsIndex(section->section_index);
    ASSERT(section_types_.At(index) == section->section_type ||
           section_types_.At(index) == elf::SHT_NOBITS);
    auto const link_index = SectionTableIndex(section->section_link);
    ASSERT(link_index >= 0 && link_index < section_table_entry_count_);
    auto const name_index = section_names_.At(index);
    ASSERT(name_index >= 0 && name_index < shstrtab->text_.length());
    // All (non-reserved) section names start with '.'.
    ASSERT(shstrtab->GetString(name_index)[0] == '.');
  }

  // Here, we primarily check that output_sections_ is a subset of
  // active_sections_, and thus all output sections are in the section table,
  // and that all the sections are continguous in the file modulo alignment.
  intptr_t file_offset = program_table_file_offset_ + ProgramTableSize();
  for (auto section : output_sections_) {
    auto const index = ActiveSectionsIndex(section->section_index);
    file_offset = Utils::RoundUp(file_offset, section->alignment);
    ASSERT(section->file_offset == file_offset);
    file_offset += section->file_size;
    ASSERT(index >= 0 && index < active_sections_.length());
  }
  ASSERT(Utils::RoundUp(file_offset, kElfSectionTableAlignment) ==
         section_table_file_offset_);
#endif
}

intptr_t Elf::PrepareDebugSection(Section* section,
                                  intptr_t file_offset,
                                  bool use_fake_info) {
  // All sections are output in the section table, even for debugging.
  active_sections_.Add(section);
  adjusted_indices_.Insert(section->section_index, section->section_index);
  if (use_fake_info) {
    // The fake offset of this section will be the aligned offset immediately
    // after the program table.
    auto const fake_offset = program_table_file_offset_ + ProgramTableSize();
    // No actual data will be output for these sections.
    section_types_.Add(elf::SHT_NOBITS);
    file_sizes_.Add(0);
    section->file_offset = Utils::RoundUp(fake_offset, section->alignment);
    return file_offset;
  }
  output_sections_.Add(section);
  section_types_.Add(section->section_type);
  file_sizes_.Add(section->file_size);
  section->file_offset = Utils::RoundUp(file_offset, section->alignment);
  return section->file_offset + section->file_size;
}

intptr_t Elf::PrepareMainSection(Section* section,
                                 intptr_t file_offset,
                                 intptr_t skipped_sections) {
  active_sections_.Add(section);
  output_sections_.Add(section);
  file_sizes_.Add(section->file_size);
  section_types_.Add(section->section_type);
  adjusted_indices_.Insert(section->section_index,
                           section->section_index - skipped_sections);
  section->file_offset = Utils::RoundUp(file_offset, section->alignment);
  return section->file_offset + section->file_size;
}

StringTable* Elf::CreateSectionHeaderStringTable() {
  // If there are no dropped sections prior to adding the section header string
  // table, we can just use the current name indices and shstrtab_.
  if (active_sections_.length() == (sections_.length() - 1)) {
    for (auto section : active_sections_) {
      section_names_.Add(section->section_name);
    }
    section_names_.Add(shstrtab_->section_name);
    return shstrtab_;
  }

  auto ret = new (zone_) StringTable(/*allocate=*/false);
  // Fill fields set outside of methods in Section and its subclasses.
  ret->section_name = shstrtab_->section_name;
  ret->section_index = shstrtab_->section_index;
  ret->output_type = Section::kAllOutput;

  for (auto section : active_sections_) {
    auto const cstr = shstrtab_->GetString(section->section_name);
    section_names_.Add(ret->AddString(cstr));
  }
  // Now add the name for the section header string table itself.
  section_names_.Add(ret->AddString(shstrtab_->GetString(ret->section_name)));
  return ret;
}

Section* Elf::AdjustForActiveSections(Section* section) {
  // Possibly trim shstrtab_ to remove names for dropped sections.
  if (section == shstrtab_) return CreateSectionHeaderStringTable();
  // No other section currently needs adjustment.
  return section;
}

void Elf::PrepareDebugOutputInfo() {
  ClearOutputInfo();

  intptr_t file_offset = kElfHeaderSize;

  // This is the same for both the debugging and stripped output.
  program_table_file_offset_ = file_offset;
  program_table_entry_count_ = segments_.length() + kNumImplicitSegments;
  file_offset += ProgramTableSize();

  for (auto section : sections_) {
    // When splitting out debugging information, we only output the contents
    // of debug sections and the section header string table, so change the
    // section header information appropriately for other sections.
    auto const use_fake_info = section->output_type == Section::kMainOutput;
    section = AdjustForActiveSections(section);
    file_offset = PrepareDebugSection(section, file_offset, use_fake_info);
  }

  file_offset = Utils::RoundUp(file_offset, kElfSectionTableAlignment);
  section_table_file_offset_ = file_offset;
  section_table_entry_count_ = active_sections_.length() + kNumInvalidSections;
  file_offset += SectionTableSize();

  VerifyOutputInfo();
}

void Elf::PrepareMainOutputInfo() {
  ClearOutputInfo();
  intptr_t file_offset = kElfHeaderSize;

  program_table_file_offset_ = file_offset;
  program_table_entry_count_ = segments_.length() + kNumImplicitSegments;
  file_offset += ProgramTableSize();

  intptr_t skipped_sections = 0;
  for (auto section : sections_) {
    if (strip_ && section->output_type == Section::kDebugOutput) {
      skipped_sections += 1;
      continue;
    }
    section = AdjustForActiveSections(section);
    file_offset = PrepareMainSection(section, file_offset, skipped_sections);
  }

  file_offset = Utils::RoundUp(file_offset, kElfSectionTableAlignment);
  section_table_file_offset_ = file_offset;
  section_table_entry_count_ = active_sections_.length() + kNumInvalidSections;
  file_offset += SectionTableSize();

  VerifyOutputInfo();
}

void Elf::WriteHeader(StreamingWriteStream* stream) {
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
  WriteBytes(stream, e_ident, 16);

  WriteHalf(stream, elf::ET_DYN);  // Shared library.

#if defined(TARGET_ARCH_IA32)
  WriteHalf(stream, elf::EM_386);
#elif defined(TARGET_ARCH_X64)
  WriteHalf(stream, elf::EM_X86_64);
#elif defined(TARGET_ARCH_ARM)
  WriteHalf(stream, elf::EM_ARM);
#elif defined(TARGET_ARCH_ARM64)
  WriteHalf(stream, elf::EM_AARCH64);
#else
  FATAL("Unknown ELF architecture");
#endif

  WriteWord(stream, elf::EV_CURRENT);  // Version
  WriteAddr(stream, 0);                // "Entry point"
  WriteOff(stream, program_table_file_offset_);
  WriteOff(stream, section_table_file_offset_);

#if defined(TARGET_ARCH_ARM)
  uword flags = elf::EF_ARM_ABI | (TargetCPUFeatures::hardfp_supported()
                                       ? elf::EF_ARM_ABI_FLOAT_HARD
                                       : elf::EF_ARM_ABI_FLOAT_SOFT);
#else
  uword flags = 0;
#endif
  WriteWord(stream, flags);

  WriteHalf(stream, kElfHeaderSize);
  WriteHalf(stream, kElfProgramTableEntrySize);
  WriteHalf(stream, program_table_entry_count_);
  WriteHalf(stream, kElfSectionTableEntrySize);
  WriteHalf(stream, section_table_entry_count_);
  // The section header string table is always last in the active sections.
  WriteHalf(stream, SectionTableIndex(active_sections_.Last()->section_index));

  ASSERT(stream->position() == kElfHeaderSize);
}

void Elf::WriteProgramTable(StreamingWriteStream* stream) {
  ASSERT(stream->position() == program_table_file_offset_);
  auto const program_table_file_size = ProgramTableSize();

  // Self-reference to program header table. Required by Android but not by
  // Linux. Must appear before any PT_LOAD entries.
  {
    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(stream, elf::PT_PHDR);
    WriteOff(stream, program_table_file_offset_);   // File offset.
    WriteAddr(stream, program_table_file_offset_);  // Virtual address.
    WriteAddr(stream, program_table_file_offset_);  // Physical address, unused.
    WriteWord(stream, program_table_file_size);
    WriteWord(stream, program_table_file_size);
    WriteWord(stream, elf::PF_R);
    WriteWord(stream, kPageSize);
#else
    WriteWord(stream, elf::PT_PHDR);
    WriteWord(stream, elf::PF_R);
    WriteOff(stream, program_table_file_offset_);   // File offset.
    WriteAddr(stream, program_table_file_offset_);  // Virtual address.
    WriteAddr(stream, program_table_file_offset_);  // Physical address, unused.
    WriteXWord(stream, program_table_file_size);
    WriteXWord(stream, program_table_file_size);
    WriteXWord(stream, kPageSize);
#endif
    const intptr_t end = stream->position();
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
    RELEASE_ASSERT((program_table_file_offset_ + program_table_file_size) <
                   kProgramTableSegmentSize);

    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream->position();

    // The Android dynamic linker in Jelly Bean incorrectly assumes that all
    // non-writable segments are continguous. We put BSS first, so we must make
    // this segment writable so it does not mark the BSS as read-only.
    //
    // The bug is here:
    //   https://github.com/aosp-mirror/platform_bionic/blob/94963af28e445384e19775a838a29e6a71708179/linker/linker.c#L1991-L2001
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(stream, elf::PT_LOAD);
    WriteOff(stream, 0);   // File offset.
    WriteAddr(stream, 0);  // Virtual address.
    WriteAddr(stream, 0);  // Physical address, not used.
    WriteWord(stream, program_table_file_offset_ + program_table_file_size);
    WriteWord(stream, program_table_file_offset_ + program_table_file_size);
    WriteWord(stream, elf::PF_R | elf::PF_W);
    WriteWord(stream, kPageSize);
#else
    WriteWord(stream, elf::PT_LOAD);
    WriteWord(stream, elf::PF_R | elf::PF_W);
    WriteOff(stream, 0);   // File offset.
    WriteAddr(stream, 0);  // Virtual address.
    WriteAddr(stream, 0);  // Physical address, not used.
    WriteXWord(stream, program_table_file_offset_ + program_table_file_size);
    WriteXWord(stream, program_table_file_offset_ + program_table_file_size);
    WriteXWord(stream, kPageSize);
#endif
    const intptr_t end = stream->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }

  // We need to write out the segment headers even in the debugging info,
  // even though there won't be any contents of those segments here and
  // so we should report sizes of 0.
  for (const auto section : segments_) {
    const intptr_t start = stream->position();
    // file_sizes_ corresponds to active_sections_, so we first need to
    // find the offset of this section in there.
    auto const active_sections_index =
        ActiveSectionsIndex(section->section_index);
    auto const file_size = file_sizes_.At(active_sections_index);
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(stream, section->segment_type);
    WriteOff(stream, section->file_offset);
    WriteAddr(stream, section->memory_offset);  // Virtual address.
    WriteAddr(stream, section->memory_offset);  // Physical address, not used.
    WriteWord(stream, file_size);
    WriteWord(stream, section->memory_size);
    WriteWord(stream, section->segment_flags);
    WriteWord(stream, section->alignment);
#else
    WriteWord(stream, section->segment_type);
    WriteWord(stream, section->segment_flags);
    WriteOff(stream, section->file_offset);
    WriteAddr(stream, section->memory_offset);  // Virtual address.
    WriteAddr(stream, section->memory_offset);  // Physical address, not used.
    WriteXWord(stream, file_size);
    WriteXWord(stream, section->memory_size);
    WriteXWord(stream, section->alignment);
#endif
    const intptr_t end = stream->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }

  // Special case: the dynamic section requires both LOAD and DYNAMIC program
  // header table entries.
  {
    ASSERT(kNumImplicitSegments == 3);
    const intptr_t start = stream->position();
    auto const active_sections_index =
        ActiveSectionsIndex(dynamic_->section_index);
    auto const file_size = file_sizes_.At(active_sections_index);
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(stream, elf::PT_DYNAMIC);
    WriteOff(stream, dynamic_->file_offset);
    WriteAddr(stream, dynamic_->memory_offset);  // Virtual address.
    WriteAddr(stream, dynamic_->memory_offset);  // Physical address, not used.
    WriteWord(stream, file_size);
    WriteWord(stream, dynamic_->memory_size);
    WriteWord(stream, dynamic_->segment_flags);
    WriteWord(stream, dynamic_->alignment);
#else
    WriteWord(stream, elf::PT_DYNAMIC);
    WriteWord(stream, dynamic_->segment_flags);
    WriteOff(stream, dynamic_->file_offset);
    WriteAddr(stream, dynamic_->memory_offset);  // Virtual address.
    WriteAddr(stream, dynamic_->memory_offset);  // Physical address, not used.
    WriteXWord(stream, file_size);
    WriteXWord(stream, dynamic_->memory_size);
    WriteXWord(stream, dynamic_->alignment);
#endif
    const intptr_t end = stream->position();
    ASSERT((end - start) == kElfProgramTableEntrySize);
  }
}

void Elf::WriteSectionTable(StreamingWriteStream* stream) {
  stream->Align(kElfSectionTableAlignment);
  ASSERT(stream->position() == section_table_file_offset_);

  {
    // The first entry in the section table is reserved and must be all zeros.
    ASSERT(kNumInvalidSections == 1);
    const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteAddr(stream, 0);
    WriteOff(stream, 0);
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteWord(stream, 0);
#else
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteXWord(stream, 0);
    WriteAddr(stream, 0);
    WriteOff(stream, 0);
    WriteXWord(stream, 0);
    WriteWord(stream, 0);
    WriteWord(stream, 0);
    WriteXWord(stream, 0);
    WriteXWord(stream, 0);
#endif
    const intptr_t end = stream->position();
    ASSERT((end - start) == kElfSectionTableEntrySize);
  }

  for (intptr_t i = 0; i < active_sections_.length(); i++) {
    Section* section = active_sections_[i];
    auto const name = section_names_.At(i);
    auto const type = section_types_.At(i);
    auto const file_size = file_sizes_.At(i);
    auto const link = SectionTableIndex(section->section_link);

    const intptr_t start = stream->position();
#if defined(TARGET_ARCH_IS_32_BIT)
    WriteWord(stream, name);
    WriteWord(stream, type);
    WriteWord(stream, section->section_flags);
    WriteAddr(stream, section->memory_offset);
    WriteOff(stream, section->file_offset);
    WriteWord(stream, file_size);  // Has different meaning for BSS.
    WriteWord(stream, link);
    WriteWord(stream, section->section_info);
    WriteWord(stream, section->alignment);
    WriteWord(stream, section->section_entry_size);
#else
    WriteWord(stream, name);
    WriteWord(stream, type);
    WriteXWord(stream, section->section_flags);
    WriteAddr(stream, section->memory_offset);
    WriteOff(stream, section->file_offset);
    WriteXWord(stream, file_size);  // Has different meaning for BSS.
    WriteWord(stream, link);
    WriteWord(stream, section->section_info);
    WriteXWord(stream, section->alignment);
    WriteXWord(stream, section->section_entry_size);
#endif
    const intptr_t end = stream->position();
    ASSERT((end - start) == kElfSectionTableEntrySize);
  }
}

void Elf::WriteSections(StreamingWriteStream* stream) {
  for (auto section : output_sections_) {
    stream->Align(section->alignment);
    ASSERT(stream->position() == section->file_offset);
    section->Write(stream);
    ASSERT(stream->position() == section->file_offset + section->file_size);
  }
}

}  // namespace dart
