// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debuginfo.h"

#include "vm/elfgen.h"
#include "vm/gdbjit_linux.h"

namespace dart {

DebugInfo::DebugInfo() {
  handle_ = reinterpret_cast<void*>(new ElfGen());
  ASSERT(handle_ != NULL);
}


DebugInfo::~DebugInfo() {
  ElfGen* elf_gen = reinterpret_cast<ElfGen*>(handle_);
  delete elf_gen;
}


void DebugInfo::AddCode(uword pc, intptr_t size) {
  ElfGen* elf_gen = reinterpret_cast<ElfGen*>(handle_);
  elf_gen->AddCode(pc, size);
}


void DebugInfo::AddCodeRegion(const char* name, uword pc, intptr_t size) {
  ElfGen* elf_gen = reinterpret_cast<ElfGen*>(handle_);
  elf_gen->AddCodeRegion(name, pc, size);
}


bool DebugInfo::WriteToMemory(ByteBuffer* region) {
  ElfGen* elf_gen = reinterpret_cast<ElfGen*>(handle_);
  return elf_gen->WriteToMemory(region);
}


DebugInfo* DebugInfo::NewGenerator() {
  return new DebugInfo();
}


void DebugInfo::RegisterSection(const char* name,
                                uword entry_point,
                                intptr_t size) {
  ElfGen* elf_section = new ElfGen();
  ASSERT(elf_section != NULL);
  elf_section->AddCode(entry_point, size);
  elf_section->AddCodeRegion(name, entry_point, size);

  ByteBuffer* dynamic_region = new ByteBuffer();
  ASSERT(dynamic_region != NULL);

  elf_section->WriteToMemory(dynamic_region);

  ::addDynamicSection(reinterpret_cast<const char*>(dynamic_region->data()),
                      dynamic_region->size());
  dynamic_region->set_data(NULL);
  delete dynamic_region;
  delete elf_section;
}


void DebugInfo::UnregisterAllSections() {
  ::deleteDynamicSections();
}

}  // namespace dart
