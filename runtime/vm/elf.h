// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ELF_H_
#define RUNTIME_VM_ELF_H_

#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/growable_array.h"
#include "vm/zone.h"

namespace dart {

class DynamicSegment;
class DynamicTable;
class Section;
class StringTable;
class Symbol;
class SymbolTable;

class Elf : public ZoneAllocated {
 public:
  Elf(Zone* zone, StreamingWriteStream* stream);

  static const intptr_t kPageSize = 4096;

  intptr_t NextMemoryOffset() const { return memory_offset_; }
  intptr_t NextSectionIndex() const { return sections_.length(); }
  intptr_t AddText(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddROData(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddBSSData(const char* name, intptr_t size);
  void AddDebug(const char* name, const uint8_t* bytes, intptr_t size);
  void AddStaticSymbol(intptr_t section,
                       const char* name,
                       intptr_t address,
                       intptr_t size);

  void Finalize();

  intptr_t position() const { return stream_->position(); }
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
  void AddSection(Section* section, const char* name);
  intptr_t AddSectionSymbol(const Section* section,
                            const char* name,
                            intptr_t size);

  void FinalizeProgramTable();
  void ComputeFileOffsets();
  void WriteHeader();
  void WriteSectionTable();
  void WriteProgramTable();
  void WriteSections();

  Zone* const zone_;
  StreamingWriteStream* const stream_;

  // All our strings would fit in a single page. However, we use separate
  // .shstrtab and .dynstr to work around a bug in Android's strip utility.
  StringTable* const shstrtab_;
  StringTable* const dynstrtab_;
  SymbolTable* const dynsym_;

  // Can only be created once the dynamic symbol table is complete.
  DynamicTable* dynamic_ = nullptr;
  DynamicSegment* dynamic_segment_ = nullptr;

  // The static tables are lazily created when static symbols are added.
  StringTable* strtab_ = nullptr;
  SymbolTable* symtab_ = nullptr;

  GrowableArray<Section*> sections_;
  GrowableArray<Section*> segments_;
  intptr_t memory_offset_;
  intptr_t section_table_file_offset_ = -1;
  intptr_t section_table_file_size_ = -1;
  intptr_t program_table_file_offset_ = -1;
  intptr_t program_table_file_size_ = -1;
};

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
