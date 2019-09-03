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

class DynamicTable;
class Section;
class StringTable;
class Symbol;
class SymbolTable;

class Elf : public ZoneAllocated {
 public:
  Elf(Zone* zone, StreamingWriteStream* stream);

  intptr_t NextMemoryOffset();
  intptr_t AddText(const char* name, const uint8_t* bytes, intptr_t size);
  intptr_t AddROData(const char* name, const uint8_t* bytes, intptr_t size);
  void AddDebug(const char* name, const uint8_t* bytes, intptr_t size);

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
  void AddSection(Section* section);
  void AddSegment(Section* section);

  void ComputeFileOffsets();
  void WriteHeader();
  void WriteSectionTable();
  void WriteProgramTable();
  void WriteSections();

  Zone* const zone_;
  StreamingWriteStream* stream_;
  GrowableArray<Section*> sections_;
  GrowableArray<Section*> segments_;

  intptr_t memory_offset_;
  intptr_t section_table_file_offset_;
  intptr_t section_table_file_size_;
  intptr_t program_table_file_offset_;
  intptr_t program_table_file_size_;
  StringTable* shstrtab_;
  StringTable* symstrtab_;
  SymbolTable* symtab_;
  DynamicTable* dynamic_;
};

}  // namespace dart

#endif  // RUNTIME_VM_ELF_H_
