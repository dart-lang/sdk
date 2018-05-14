// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/kernel_binary.h"
#include "platform/globals.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/kernel.h"
#include "vm/os.h"

namespace dart {

namespace kernel {

const char* Reader::TagName(Tag tag) {
  switch (tag) {
#define CASE(Name, value)                                                      \
  case k##Name:                                                                \
    return #Name;
    KERNEL_TAG_LIST(CASE)
#undef CASE
    default:
      break;
  }
  return "Unknown";
}

Program* Program::ReadFrom(Reader* reader, bool take_buffer_ownership) {
  uint32_t magic = reader->ReadUInt32();
  if (magic != kMagicProgramFile) FATAL("Invalid magic identifier");

  uint32_t formatVersion = reader->ReadUInt32();
  if (formatVersion != kBinaryFormatVersion) {
    FATAL2("Invalid kernel binary format version (found %u, expected %u)",
           formatVersion, kBinaryFormatVersion);
  }

  Program* program = new Program();
  program->kernel_data_ = reader->buffer();
  program->kernel_data_size_ = reader->size();
  program->buffer_ownership_ = take_buffer_ownership;

  // Dill files can be concatenated (e.g. cat a.dill b.dill > c.dill). Find out
  // if this dill contains more than one program.
  int subprogram_count = 0;
  reader->set_offset(reader->size() - 4);
  while (reader->offset() > 0) {
    intptr_t size = reader->ReadUInt32();
    intptr_t start = reader->offset() - size;
    if (start < 0) {
      FATAL("Invalid kernel binary: Indicated size is invalid.");
    }
    ++subprogram_count;
    if (subprogram_count > 1) break;
    reader->set_offset(start - 4);
  }
  program->single_program_ = subprogram_count == 1;

  // Read backwards at the end.
  program->library_count_ = reader->ReadFromIndexNoReset(
      reader->size_, LibraryCountFieldCountFromEnd, 1, 0);
  program->source_table_offset_ = reader->ReadFromIndexNoReset(
      reader->size_,
      LibraryCountFieldCountFromEnd + 1 + program->library_count_ + 1 +
          SourceTableFieldCountFromFirstLibraryOffset,
      1, 0);
  program->name_table_offset_ = reader->ReadUInt32();
  program->string_table_offset_ = reader->ReadUInt32();
  program->constant_table_offset_ = reader->ReadUInt32();

  program->main_method_reference_ = NameIndex(reader->ReadUInt32() - 1);

  return program;
}

Program* Program::ReadFromFile(const char* script_uri) {
  Thread* thread = Thread::Current();
  if (script_uri == NULL) {
    return NULL;
  }
  kernel::Program* kernel_program = NULL;
  {
    TransitionVMToNative transition(thread);
    Api::Scope api_scope(thread);
    Dart_Handle retval = (thread->isolate()->library_tag_handler())(
        Dart_kKernelTag, Api::Null(),
        Api::NewHandle(thread, String::New(script_uri)));
    if (!Dart_IsError(retval)) {
      Dart_TypedData_Type data_type;
      uint8_t* data;
      ASSERT(Dart_IsTypedData(retval));

      uint8_t* kernel_buffer;
      intptr_t kernel_buffer_size;
      Dart_Handle val = Dart_TypedDataAcquireData(
          retval, &data_type, reinterpret_cast<void**>(&data),
          &kernel_buffer_size);
      ASSERT(!Dart_IsError(val));
      ASSERT(data_type == Dart_TypedData_kUint8);
      kernel_buffer = reinterpret_cast<uint8_t*>(malloc(kernel_buffer_size));
      memmove(kernel_buffer, data, kernel_buffer_size);
      Dart_TypedDataReleaseData(retval);

      kernel_program =
          kernel::Program::ReadFromBuffer(kernel_buffer, kernel_buffer_size);
    } else {
      THR_Print("tag handler failed: %s\n", Dart_GetError(retval));
    }
  }
  return kernel_program;
}

Program* Program::ReadFromBuffer(const uint8_t* buffer,
                                 intptr_t buffer_length,
                                 bool take_buffer_ownership) {
  kernel::Reader reader(buffer, buffer_length);
  return kernel::Program::ReadFrom(&reader, take_buffer_ownership);
}

}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
