// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/kernel_binary.h"

#include <memory>

#include "platform/globals.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/kernel.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/version.h"

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

TypedDataPtr Reader::ReadLineStartsData(intptr_t line_start_count) {
  TypedData& line_starts_data = TypedData::Handle(
      TypedData::New(kTypedDataInt8ArrayCid, line_start_count, Heap::kOld));

  const intptr_t start_offset = offset();
  intptr_t i = 0;
  for (; i < line_start_count; ++i) {
    const intptr_t delta = ReadUInt();
    if (delta > kMaxInt8) {
      break;
    }
    line_starts_data.SetInt8(i, static_cast<int8_t>(delta));
  }

  if (i < line_start_count) {
    // Slow path: choose representation between Int16 and Int32 typed data.
    set_offset(start_offset);
    intptr_t max_delta = 0;
    for (intptr_t i = 0; i < line_start_count; ++i) {
      const intptr_t delta = ReadUInt();
      if (delta > max_delta) {
        max_delta = delta;
      }
    }

    ASSERT(max_delta > kMaxInt8);
    const intptr_t cid = (max_delta <= kMaxInt16) ? kTypedDataInt16ArrayCid
                                                  : kTypedDataInt32ArrayCid;
    line_starts_data = TypedData::New(cid, line_start_count, Heap::kOld);

    set_offset(start_offset);
    for (intptr_t i = 0; i < line_start_count; ++i) {
      const intptr_t delta = ReadUInt();
      if (cid == kTypedDataInt16ArrayCid) {
        line_starts_data.SetInt16(i << 1, static_cast<int16_t>(delta));
      } else {
        line_starts_data.SetInt32(i << 2, delta);
      }
    }
  }

  return line_starts_data.raw();
}

const char* kKernelInvalidFilesize =
    "File size is too small to be a valid kernel file";
const char* kKernelInvalidMagicIdentifier = "Invalid magic identifier";
const char* kKernelInvalidBinaryFormatVersion =
    "Invalid kernel binary format version";
const char* kKernelInvalidSizeIndicated =
    "Invalid kernel binary: Indicated size is invalid";
const char* kKernelInvalidSdkHash = "Invalid SDK hash";

const int kSdkHashSizeInBytes = 10;
const char* kSdkHashNull = "0000000000";

std::unique_ptr<Program> Program::ReadFrom(Reader* reader, const char** error) {
  if (reader->size() < 70) {
    // A kernel file (v43) currently contains at least the following:
    //   * Magic number (32)
    //   * Kernel version (32)
    //   * SDK Hash (10 * 8)
    //   * List of problems (8)
    //   * Length of source map (32)
    //   * Length of canonical name table (8)
    //   * Metadata length (32)
    //   * Length of string table (8)
    //   * Length of constant table (8)
    //   * Component index (11 * 32)
    //
    // so is at least 74 bytes.
    // (Technically it will also contain an empty entry in both source map and
    // string table, taking up another 8 bytes.)
    if (error != nullptr) {
      *error = kKernelInvalidFilesize;
    }
    return nullptr;
  }

  uint32_t magic = reader->ReadUInt32();
  if (magic != kMagicProgramFile) {
    if (error != nullptr) {
      *error = kKernelInvalidMagicIdentifier;
    }
    return nullptr;
  }

  uint32_t formatVersion = reader->ReadUInt32();
  if ((formatVersion < kMinSupportedKernelFormatVersion) ||
      (formatVersion > kMaxSupportedKernelFormatVersion)) {
    if (error != nullptr) {
      *error = kKernelInvalidBinaryFormatVersion;
    }
    return nullptr;
  }

  uint8_t sdkHash[kSdkHashSizeInBytes + 1];
  reader->ReadBytes(sdkHash, kSdkHashSizeInBytes);
  sdkHash[kSdkHashSizeInBytes] = 0;  // Null terminate.
  if (strcmp(Version::SdkHash(), kSdkHashNull) != 0 &&
      strcmp((const char*)sdkHash, kSdkHashNull) != 0 &&
      strcmp((const char*)sdkHash, Version::SdkHash()) != 0) {
    if (error != nullptr) {
      *error = kKernelInvalidSdkHash;
    }
    return nullptr;
  }

  std::unique_ptr<Program> program(new Program());
  program->binary_version_ = formatVersion;
  program->typed_data_ = reader->typed_data();
  program->kernel_data_ = reader->buffer();
  program->kernel_data_size_ = reader->size();

  // Dill files can be concatenated (e.g. cat a.dill b.dill > c.dill). Find out
  // if this dill contains more than one program.
  int subprogram_count = 0;
  reader->set_offset(reader->size() - 4);
  while (reader->offset() > 0) {
    intptr_t size = reader->ReadUInt32();
    intptr_t start = reader->offset() - size;
    if (start < 0 || size <= 0) {
      if (error != nullptr) {
        *error = kKernelInvalidSizeIndicated;
      }
      return nullptr;
    }
    ++subprogram_count;
    if (subprogram_count > 1) break;
    reader->set_offset(start - 4);
  }
  program->single_program_ = subprogram_count == 1;

  // Read backwards at the end.
  program->library_count_ = reader->ReadFromIndexNoReset(
      reader->size_, LibraryCountFieldCountFromEnd, 1, 0);
  intptr_t count_from_first_library_offset =
      SourceTableFieldCountFromFirstLibraryOffset41Plus;
  program->source_table_offset_ = reader->ReadFromIndexNoReset(
      reader->size_,
      LibraryCountFieldCountFromEnd + 1 + program->library_count_ + 1 +
          count_from_first_library_offset,
      1, 0);
  program->name_table_offset_ = reader->ReadUInt32();
  program->metadata_payloads_offset_ = reader->ReadUInt32();
  program->metadata_mappings_offset_ = reader->ReadUInt32();
  program->string_table_offset_ = reader->ReadUInt32();
  program->constant_table_offset_ = reader->ReadUInt32();

  program->main_method_reference_ = NameIndex(reader->ReadUInt32() - 1);
  NNBDCompiledMode compilation_mode =
      static_cast<NNBDCompiledMode>(reader->ReadUInt32());
  program->compilation_mode_ = compilation_mode;

  return program;
}

std::unique_ptr<Program> Program::ReadFromFile(
    const char* script_uri, const char** error /* = nullptr */) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  if (script_uri == NULL) {
    return nullptr;
  }
  if (!isolate->HasTagHandler()) {
    return nullptr;
  }
  std::unique_ptr<kernel::Program> kernel_program;

  const String& uri = String::Handle(String::New(script_uri));
  const Object& ret = Object::Handle(
      isolate->CallTagHandler(Dart_kKernelTag, Object::null_object(), uri));
  if (ret.IsExternalTypedData()) {
    const auto& typed_data = ExternalTypedData::Handle(
        thread->zone(), ExternalTypedData::RawCast(ret.raw()));
    kernel_program = kernel::Program::ReadFromTypedData(typed_data);
    return kernel_program;
  } else if (error != nullptr) {
    Api::Scope api_scope(thread);
    Dart_Handle retval = Api::NewHandle(thread, ret.raw());
    {
      TransitionVMToNative transition(thread);
      *error = Dart_GetError(retval);
    }
  }
  return kernel_program;
}

std::unique_ptr<Program> Program::ReadFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length,
                                                 const char** error) {
  kernel::Reader reader(buffer, buffer_length);
  return kernel::Program::ReadFrom(&reader, error);
}

std::unique_ptr<Program> Program::ReadFromTypedData(
    const ExternalTypedData& typed_data, const char** error) {
  kernel::Reader reader(typed_data);
  return kernel::Program::ReadFrom(&reader, error);
}

}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
