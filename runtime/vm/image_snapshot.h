// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_IMAGE_SNAPSHOT_H_
#define RUNTIME_VM_IMAGE_SNAPSHOT_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Code;
class Dwarf;
class Instructions;
class Object;
class RawCode;
class RawInstructions;
class RawObject;

class Image : ValueObject {
 public:
  explicit Image(const void* raw_memory) : raw_memory_(raw_memory) {
    ASSERT(Utils::IsAligned(raw_memory, OS::kMaxPreferredCodeAlignment));
  }

  void* object_start() const {
    return reinterpret_cast<void*>(reinterpret_cast<uword>(raw_memory_) +
                                   kHeaderSize);
  }

  uword object_size() const {
    uword snapshot_size = *reinterpret_cast<const uword*>(raw_memory_);
    return snapshot_size - kHeaderSize;
  }

  static const intptr_t kHeaderSize = OS::kMaxPreferredCodeAlignment;

 private:
  const void* raw_memory_;  // The symbol kInstructionsSnapshot.

  DISALLOW_COPY_AND_ASSIGN(Image);
};

class ImageReader : public ZoneAllocated {
 public:
  ImageReader(const uint8_t* instructions_buffer, const uint8_t* data_buffer);

  RawInstructions* GetInstructionsAt(int32_t offset) const;
  RawObject* GetObjectAt(int32_t offset) const;

 private:
  const uint8_t* instructions_buffer_;
  const uint8_t* data_buffer_;
  const uint8_t* vm_instructions_buffer_;

  DISALLOW_COPY_AND_ASSIGN(ImageReader);
};

class ImageWriter : public ZoneAllocated {
 public:
  ImageWriter()
      : next_offset_(0), next_object_offset_(0), instructions_(), objects_() {
    ResetOffsets();
  }
  virtual ~ImageWriter() {}

  void ResetOffsets() {
    next_offset_ = Image::kHeaderSize;
    next_object_offset_ = Image::kHeaderSize;
    instructions_.Clear();
    objects_.Clear();
  }
  int32_t GetTextOffsetFor(RawInstructions* instructions, RawCode* code);
  int32_t GetDataOffsetFor(RawObject* raw_object);

  void Write(WriteStream* clustered_stream, bool vm);
  virtual intptr_t text_size() const = 0;
  intptr_t data_size() const { return next_object_offset_; }

 protected:
  void WriteROData(WriteStream* stream);
  virtual void WriteText(WriteStream* clustered_stream, bool vm) = 0;

  struct InstructionsData {
    explicit InstructionsData(RawInstructions* insns,
                              RawCode* code,
                              intptr_t offset)
        : raw_insns_(insns), raw_code_(code), offset_(offset) {}

    union {
      RawInstructions* raw_insns_;
      const Instructions* insns_;
    };
    union {
      RawCode* raw_code_;
      const Code* code_;
    };
    intptr_t offset_;
  };

  struct ObjectData {
    explicit ObjectData(RawObject* raw_obj) : raw_obj_(raw_obj) {}

    union {
      RawObject* raw_obj_;
      const Object* obj_;
    };
  };

  intptr_t next_offset_;
  intptr_t next_object_offset_;
  GrowableArray<InstructionsData> instructions_;
  GrowableArray<ObjectData> objects_;

 private:
  DISALLOW_COPY_AND_ASSIGN(ImageWriter);
};

class AssemblyImageWriter : public ImageWriter {
 public:
  AssemblyImageWriter(uint8_t** assembly_buffer,
                      ReAlloc alloc,
                      intptr_t initial_size);
  void Finalize();

  virtual void WriteText(WriteStream* clustered_stream, bool vm);
  virtual intptr_t text_size() const { return text_size_; }

  intptr_t AssemblySize() const { return assembly_stream_.bytes_written(); }

 private:
  void FrameUnwindPrologue();
  void FrameUnwindEpilogue();
  void WriteByteSequence(uword start, uword end);
  void WriteWordLiteralText(uword value) {
// Padding is helpful for comparing the .S with --disassemble.
#if defined(ARCH_IS_64_BIT)
    assembly_stream_.Print(".quad 0x%0.16" Px "\n", value);
#else
    assembly_stream_.Print(".long 0x%0.8" Px "\n", value);
#endif
    text_size_ += sizeof(value);
  }

  WriteStream assembly_stream_;
  intptr_t text_size_;
  Dwarf* dwarf_;

  DISALLOW_COPY_AND_ASSIGN(AssemblyImageWriter);
};

class BlobImageWriter : public ImageWriter {
 public:
  BlobImageWriter(uint8_t** instructions_blob_buffer,
                  ReAlloc alloc,
                  intptr_t initial_size)
      : ImageWriter(),
        instructions_blob_stream_(instructions_blob_buffer,
                                  alloc,
                                  initial_size) {}

  virtual void WriteText(WriteStream* clustered_stream, bool vm);
  virtual intptr_t text_size() const { return InstructionsBlobSize(); }

  intptr_t InstructionsBlobSize() const {
    return instructions_blob_stream_.bytes_written();
  }

 private:
  WriteStream instructions_blob_stream_;

  DISALLOW_COPY_AND_ASSIGN(BlobImageWriter);
};

}  // namespace dart

#endif  // RUNTIME_VM_IMAGE_SNAPSHOT_H_
