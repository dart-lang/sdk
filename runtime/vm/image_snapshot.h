// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_IMAGE_SNAPSHOT_H_
#define RUNTIME_VM_IMAGE_SNAPSHOT_H_

#include <utility>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/v8_snapshot_writer.h"

namespace dart {

// Forward declarations.
class Code;
class Dwarf;
class Instructions;
class Object;
class RawApiError;
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
  ImageReader(const uint8_t* data_image,
              const uint8_t* instructions_image,
              const uint8_t* shared_data_image,
              const uint8_t* shared_instructions_image);

  RawApiError* VerifyAlignment() const;

  RawInstructions* GetInstructionsAt(int32_t offset) const;
  RawObject* GetObjectAt(uint32_t offset) const;
  RawObject* GetSharedObjectAt(uint32_t offset) const;

 private:
  const uint8_t* data_image_;
  const uint8_t* instructions_image_;
  const uint8_t* shared_data_image_;
  const uint8_t* shared_instructions_image_;

  DISALLOW_COPY_AND_ASSIGN(ImageReader);
};

struct ObjectOffsetPair {
 public:
  ObjectOffsetPair() : ObjectOffsetPair(NULL, 0) {}
  ObjectOffsetPair(RawObject* obj, int32_t off) : object(obj), offset(off) {}

  RawObject* object;
  int32_t offset;
};

class ObjectOffsetTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef RawObject* Key;
  typedef int32_t Value;
  typedef ObjectOffsetPair Pair;

  static Key KeyOf(Pair kv) { return kv.object; }
  static Value ValueOf(Pair kv) { return kv.offset; }
  static intptr_t Hashcode(Key key);
  static inline bool IsKeyEqual(Pair pair, Key key);
};

typedef DirectChainedHashMap<ObjectOffsetTrait> ObjectOffsetMap;

class ImageWriter : public ValueObject {
 public:
  ImageWriter(Heap* heap,
              const void* shared_objects,
              const void* shared_instructions,
              const void* reused_instructions);
  virtual ~ImageWriter() {}

  static void SetupShared(ObjectOffsetMap* map, const void* shared_image);
  void ResetOffsets() {
    next_data_offset_ = Image::kHeaderSize;
    next_text_offset_ = Image::kHeaderSize;
    objects_.Clear();
    instructions_.Clear();
  }

  int32_t GetTextOffsetFor(RawInstructions* instructions, RawCode* code);
  bool GetSharedDataOffsetFor(RawObject* raw_object, uint32_t* offset);
  uint32_t GetDataOffsetFor(RawObject* raw_object);

  void Write(WriteStream* clustered_stream, bool vm);
  intptr_t data_size() const { return next_data_offset_; }
  intptr_t text_size() const { return next_text_offset_; }

  void DumpStatistics();

  void SetProfileWriter(V8SnapshotProfileWriter* profile_writer) {
    profile_writer_ = profile_writer;
  }

  void ClearProfileWriter() { profile_writer_ = nullptr; }

  void TraceInstructions(const Instructions& instructions);

 protected:
  void WriteROData(WriteStream* stream);
  virtual void WriteText(WriteStream* clustered_stream, bool vm) = 0;

  void DumpInstructionStats();
  void DumpInstructionsSizes();

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

  Heap* heap_;  // Used for mapping RawInstructiosn to object ids.
  intptr_t next_data_offset_;
  intptr_t next_text_offset_;
  GrowableArray<ObjectData> objects_;
  GrowableArray<InstructionsData> instructions_;
  ObjectOffsetMap shared_objects_;
  ObjectOffsetMap shared_instructions_;
  ObjectOffsetMap reuse_instructions_;

  V8SnapshotProfileWriter::IdSpace offset_space_ =
      V8SnapshotProfileWriter::kSnapshot;
  V8SnapshotProfileWriter* profile_writer_ = nullptr;

  template <class T>
  friend class TraceImageObjectScope;

 private:
  DISALLOW_COPY_AND_ASSIGN(ImageWriter);
};

#define AutoTraceImage(section_offset, stream, type)                           \
  auto AutoTraceImagObjectScopeVar##__COUNTER__ {                              \
    MakeTraceImageObjectScope(this, section_offset, stream, type)              \
  }

template <typename T>
class TraceImageObjectScope {
 public:
  TraceImageObjectScope(ImageWriter* writer,
                        intptr_t section_offset,
                        const T* stream,
                        const char* type)
      : writer_(writer),
        stream_(stream),
        section_offset_(section_offset),
        start_offset_(stream_->Position() - section_offset) {
    if (writer_->profile_writer_ != nullptr) {
      ASSERT(writer_->offset_space_ != V8SnapshotProfileWriter::kSnapshot);
      writer_->profile_writer_->SetObjectTypeAndName(
          {writer_->offset_space_, start_offset_}, type, nullptr);
    }
  }

  ~TraceImageObjectScope() {
    if (writer_->profile_writer_ != nullptr) {
      ASSERT(writer_->offset_space_ != V8SnapshotProfileWriter::kSnapshot);
      writer_->profile_writer_->AttributeBytesTo(
          {writer_->offset_space_, start_offset_},
          stream_->Position() - section_offset_ - start_offset_);
    }
  }

 private:
  ImageWriter* writer_;
  const T* stream_;
  intptr_t section_offset_;
  intptr_t start_offset_;
};

template <typename U>
static TraceImageObjectScope<U>&& MakeTraceImageObjectScope(
    ImageWriter* writer,
    intptr_t section_offset,
    U* stream,
    const char* type) {
  return std::move(
      TraceImageObjectScope<U>(writer, section_offset, stream, type));
}

class AssemblyImageWriter : public ImageWriter {
 public:
  AssemblyImageWriter(Thread* thread,
                      Dart_StreamingWriteCallback callback,
                      void* callback_data,
                      const void* shared_objects,
                      const void* shared_instructions);
  void Finalize();

  virtual void WriteText(WriteStream* clustered_stream, bool vm);

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
  }

  StreamingWriteStream assembly_stream_;
  Dwarf* dwarf_;

  DISALLOW_COPY_AND_ASSIGN(AssemblyImageWriter);
};

class BlobImageWriter : public ImageWriter {
 public:
  BlobImageWriter(Thread* thread,
                  uint8_t** instructions_blob_buffer,
                  ReAlloc alloc,
                  intptr_t initial_size,
                  const void* shared_objects,
                  const void* shared_instructions,
                  const void* reused_instructions);

  virtual void WriteText(WriteStream* clustered_stream, bool vm);

  intptr_t InstructionsBlobSize() const {
    return instructions_blob_stream_.bytes_written();
  }

 private:
  WriteStream instructions_blob_stream_;

  DISALLOW_COPY_AND_ASSIGN(BlobImageWriter);
};

void DropCodeWithoutReusableInstructions(const void* reused_instructions);

}  // namespace dart

#endif  // RUNTIME_VM_IMAGE_SNAPSHOT_H_
