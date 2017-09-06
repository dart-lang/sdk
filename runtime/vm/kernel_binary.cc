// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/kernel_binary.h"
#include "platform/globals.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/kernel.h"
#include "vm/os.h"

namespace dart {

namespace kernel {

Program* Program::ReadFrom(Reader* reader) {
  uint32_t magic = reader->ReadUInt32();
  if (magic != kMagicProgramFile) FATAL("Invalid magic identifier");

  Program* program = new Program();
  program->kernel_data_ = reader->buffer();
  program->kernel_data_size_ = reader->size();

  // Read backwards at the end.
  reader->set_offset(reader->size() - (4 * LibraryCountFieldCountFromEnd));
  program->library_count_ = reader->ReadUInt32();
  reader->set_offset(reader->size() - (4 * LibraryCountFieldCountFromEnd) -
                     (4 * program->library_count_) -
                     (SourceTableFieldCountFromFirstLibraryOffset * 4));
  program->source_table_offset_ = reader->ReadUInt32();
  program->name_table_offset_ = reader->ReadUInt32();
  program->string_table_offset_ = reader->ReadUInt32();
  program->main_method_reference_ = NameIndex(reader->ReadUInt32() - 1);

  return program;
}

}  // namespace kernel

kernel::Program* ReadPrecompiledKernelFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length) {
  kernel::Reader reader(buffer, buffer_length);
  return kernel::Program::ReadFrom(&reader);
}

}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
