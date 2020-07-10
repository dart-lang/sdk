// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_IMAGE_SNAPSHOT_H_
#define RUNTIME_VM_IMAGE_SNAPSHOT_H_

#include <memory>
#include <utility>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/reusable_handles.h"
#include "vm/type_testing_stubs.h"
#include "vm/v8_snapshot_writer.h"

namespace dart {

// Forward declarations.
class Code;
class Dwarf;
class Elf;
class Instructions;
class Object;

class Image : ValueObject {
 public:
  explicit Image(const void* raw_memory) : raw_memory_(raw_memory) {
    ASSERT(Utils::IsAligned(raw_memory, kMaxObjectAlignment));
  }

  void* object_start() const {
    return reinterpret_cast<void*>(reinterpret_cast<uword>(raw_memory_) +
                                   kHeaderSize);
  }

  uword object_size() const {
    uword snapshot_size = *reinterpret_cast<const uword*>(raw_memory_);
    return snapshot_size - kHeaderSize;
  }

  bool contains(uword address) const {
    uword start = reinterpret_cast<uword>(object_start());
    return address >= start && (address - start < object_size());
  }

  // Returns the offset of the BSS section from this image. Only has meaning for
  // instructions images.
  word bss_offset() const {
    auto const raw_value = *(reinterpret_cast<const word*>(raw_memory_) + 1);
    return Utils::RoundDown(raw_value, kBssAlignment);
  }

  // Returns true if the image was compiled directly to ELF. Only has meaning
  // for instructions images.
  bool compiled_to_elf() const {
    auto const raw_value = *(reinterpret_cast<const word*>(raw_memory_) + 1);
    return (raw_value & 0x1) == 0x1;
  }

 private:
  static constexpr intptr_t kHeaderFields = 2;
  static constexpr intptr_t kHeaderSize = kMaxObjectAlignment;
  // Explicitly double-checking kHeaderSize is never changed. Increasing the
  // Image header size would mean objects would not start at a place expected
  // by parts of the VM (like the GC) that use Image pages as HeapPages.
  static_assert(kHeaderSize == kMaxObjectAlignment,
                "Image page cannot be used as HeapPage");

  // Determines how many bits we have for encoding any extra information in
  // the BSS offset.
  static constexpr intptr_t kBssAlignment = compiler::target::kWordSize;

  const void* raw_memory_;  // The symbol kInstructionsSnapshot.

  // For access to private constants.
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
  friend class ImageWriter;
  friend class Elf;

  DISALLOW_COPY_AND_ASSIGN(Image);
};

class ImageReader : public ZoneAllocated {
 public:
  ImageReader(const uint8_t* data_image, const uint8_t* instructions_image);

  ApiErrorPtr VerifyAlignment() const;

  ONLY_IN_PRECOMPILED(uword GetBareInstructionsAt(uint32_t offset) const);
  ONLY_IN_PRECOMPILED(uword GetBareInstructionsEnd() const);
  InstructionsPtr GetInstructionsAt(uint32_t offset) const;
  ObjectPtr GetObjectAt(uint32_t offset) const;

 private:
  const uint8_t* data_image_;
  const uint8_t* instructions_image_;

  DISALLOW_COPY_AND_ASSIGN(ImageReader);
};

struct ObjectOffsetPair {
 public:
  ObjectOffsetPair() : ObjectOffsetPair(NULL, 0) {}
  ObjectOffsetPair(ObjectPtr obj, int32_t off) : object(obj), offset(off) {}

  ObjectPtr object;
  int32_t offset;
};

class ObjectOffsetTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef ObjectPtr Key;
  typedef int32_t Value;
  typedef ObjectOffsetPair Pair;

  static Key KeyOf(Pair kv) { return kv.object; }
  static Value ValueOf(Pair kv) { return kv.offset; }
  static intptr_t Hashcode(Key key);
  static inline bool IsKeyEqual(Pair pair, Key key);
};

typedef DirectChainedHashMap<ObjectOffsetTrait> ObjectOffsetMap;

// A command which instructs the image writer to emit something into the ".text"
// segment.
//
// For now this supports
//
//   * emitting the instructions of a [Code] object
//   * emitting a trampoline of a certain size
//
struct ImageWriterCommand {
  enum Opcode {
    InsertInstructionOfCode,
    InsertBytesOfTrampoline,
  };

  ImageWriterCommand(intptr_t expected_offset, CodePtr code)
      : expected_offset(expected_offset),
        op(ImageWriterCommand::InsertInstructionOfCode),
        insert_instruction_of_code({code}) {}

  ImageWriterCommand(intptr_t expected_offset,
                     uint8_t* trampoline_bytes,
                     intptr_t trampoine_length)
      : expected_offset(expected_offset),
        op(ImageWriterCommand::InsertBytesOfTrampoline),
        insert_trampoline_bytes({trampoline_bytes, trampoine_length}) {}

  // The offset (relative to the very first [ImageWriterCommand]) we expect
  // this [ImageWriterCommand] to have.
  intptr_t expected_offset;

  Opcode op;
  union {
    struct {
      CodePtr code;
    } insert_instruction_of_code;
    struct {
      uint8_t* buffer;
      intptr_t buffer_length;
    } insert_trampoline_bytes;
  };
};

class ImageWriter : public ValueObject {
 public:
  explicit ImageWriter(Thread* thread);
  virtual ~ImageWriter() {}

  void ResetOffsets() {
    next_data_offset_ = Image::kHeaderSize;
    next_text_offset_ = Image::kHeaderSize;
    if (FLAG_use_bare_instructions && FLAG_precompiled_mode) {
      next_text_offset_ += compiler::target::InstructionsSection::HeaderSize();
    }
    objects_.Clear();
    instructions_.Clear();
  }

  // Will start preparing the ".text" segment by interpreting the provided
  // [ImageWriterCommand]s.
  void PrepareForSerialization(GrowableArray<ImageWriterCommand>* commands);

  bool IsROSpace() const {
    return offset_space_ == V8SnapshotProfileWriter::kVmData ||
           offset_space_ == V8SnapshotProfileWriter::kVmText ||
           offset_space_ == V8SnapshotProfileWriter::kIsolateData ||
           offset_space_ == V8SnapshotProfileWriter::kIsolateText;
  }
  int32_t GetTextOffsetFor(InstructionsPtr instructions, CodePtr code);
  uint32_t GetDataOffsetFor(ObjectPtr raw_object);

  void Write(WriteStream* clustered_stream, bool vm);
  intptr_t data_size() const { return next_data_offset_; }
  intptr_t text_size() const { return next_text_offset_; }
  intptr_t GetTextObjectCount() const;
  void GetTrampolineInfo(intptr_t* count, intptr_t* size) const;

  void DumpStatistics();

  void SetProfileWriter(V8SnapshotProfileWriter* profile_writer) {
    profile_writer_ = profile_writer;
  }

  void ClearProfileWriter() { profile_writer_ = nullptr; }

  void TraceInstructions(const Instructions& instructions);

  static intptr_t SizeInSnapshot(ObjectPtr object);
  static const intptr_t kBareInstructionsAlignment = 4;

  static_assert(
      (kObjectAlignmentLog2 -
       compiler::target::ObjectAlignment::kObjectAlignmentLog2) >= 0,
      "Target object alignment is larger than the host object alignment");

  // Converts the target object size (in bytes) to an appropriate argument for
  // ObjectLayout::SizeTag methods on the host machine.
  //
  // ObjectLayout::SizeTag expects a size divisible by kObjectAlignment and
  // checks this in debug mode, but the size on the target machine may not be
  // divisible by the host machine's object alignment if they differ.
  //
  // If target_size = n, we convert it to n * m, where m is the host alignment
  // divided by the target alignment. This means AdjustObjectSizeForTarget(n)
  // encodes on the host machine to the same bits that decode to n on the target
  // machine. That is:
  //    n * (host align / target align) / host align => n / target align
  static constexpr intptr_t AdjustObjectSizeForTarget(intptr_t target_size) {
    return target_size
           << (kObjectAlignmentLog2 -
               compiler::target::ObjectAlignment::kObjectAlignmentLog2);
  }

  static UNLESS_DEBUG(constexpr) compiler::target::uword
      UpdateObjectSizeForTarget(intptr_t size, uword marked_tags) {
    return ObjectLayout::SizeTag::update(AdjustObjectSizeForTarget(size),
                                         marked_tags);
  }

  // Returns nullptr if there is no profile writer.
  const char* ObjectTypeForProfile(const Object& object) const;
  static const char* TagObjectTypeAsReadOnly(Zone* zone, const char* type);

 protected:
  void WriteROData(WriteStream* stream);
  virtual void WriteText(WriteStream* clustered_stream, bool vm) = 0;

  void DumpInstructionStats();
  void DumpInstructionsSizes();

  struct InstructionsData {
    InstructionsData(InstructionsPtr insns, CodePtr code, intptr_t text_offset)
        : raw_insns_(insns),
          raw_code_(code),
          text_offset_(text_offset),
          trampoline_bytes(nullptr),
          trampoline_length(0) {}

    InstructionsData(uint8_t* trampoline_bytes,
                     intptr_t trampoline_length,
                     intptr_t text_offset)
        : raw_insns_(nullptr),
          raw_code_(nullptr),
          text_offset_(text_offset),
          trampoline_bytes(trampoline_bytes),
          trampoline_length(trampoline_length) {}

    union {
      InstructionsPtr raw_insns_;
      const Instructions* insns_;
    };
    union {
      CodePtr raw_code_;
      const Code* code_;
    };
    intptr_t text_offset_;

    uint8_t* trampoline_bytes;
    intptr_t trampoline_length;
  };

  struct ObjectData {
    explicit ObjectData(ObjectPtr raw_obj) : raw_obj_(raw_obj) {}

    union {
      ObjectPtr raw_obj_;
      const Object* obj_;
    };
  };

  Heap* heap_;  // Used for mapping RawInstructiosn to object ids.
  intptr_t next_data_offset_;
  intptr_t next_text_offset_;
  GrowableArray<ObjectData> objects_;
  GrowableArray<InstructionsData> instructions_;

  V8SnapshotProfileWriter::IdSpace offset_space_ =
      V8SnapshotProfileWriter::kSnapshot;
  V8SnapshotProfileWriter* profile_writer_ = nullptr;
  const char* const instructions_section_type_;
  const char* const instructions_type_;
  const char* const trampoline_type_;

  template <class T>
  friend class TraceImageObjectScope;
  friend class SnapshotTextObjectNamer;  // For InstructionsData.

 private:
  DISALLOW_COPY_AND_ASSIGN(ImageWriter);
};

#define AutoTraceImage(object, section_offset, stream)                         \
  auto AutoTraceImagObjectScopeVar##__COUNTER__ =                              \
      TraceImageObjectScope<std::remove_pointer<decltype(stream)>::type>(      \
          this, section_offset, stream, object);

template <typename T>
class TraceImageObjectScope {
 public:
  TraceImageObjectScope(ImageWriter* writer,
                        intptr_t section_offset,
                        const T* stream,
                        const Object& object)
      : writer_(ASSERT_NOTNULL(writer)),
        stream_(ASSERT_NOTNULL(stream)),
        section_offset_(section_offset),
        start_offset_(stream_->Position() - section_offset),
        object_(object) {}

  ~TraceImageObjectScope() {
    if (writer_->profile_writer_ == nullptr) return;
    ASSERT(writer_->IsROSpace());
    writer_->profile_writer_->SetObjectTypeAndName(
        {writer_->offset_space_, start_offset_},
        writer_->ObjectTypeForProfile(object_), nullptr);
    writer_->profile_writer_->AttributeBytesTo(
        {writer_->offset_space_, start_offset_},
        stream_->Position() - section_offset_ - start_offset_);
  }

 private:
  ImageWriter* const writer_;
  const T* const stream_;
  const intptr_t section_offset_;
  const intptr_t start_offset_;
  const Object& object_;
};

class SnapshotTextObjectNamer {
 public:
  explicit SnapshotTextObjectNamer(Zone* zone)
      : zone_(zone),
        owner_(Object::Handle(zone)),
        string_(String::Handle(zone)),
        insns_(Instructions::Handle(zone)),
        store_(Isolate::Current()->object_store()) {}

  const char* StubNameForType(const AbstractType& type) const;

  const char* SnapshotNameFor(intptr_t code_index, const Code& code);
  const char* SnapshotNameFor(intptr_t index,
                              const ImageWriter::InstructionsData& data);

 private:
  Zone* const zone_;
  Object& owner_;
  String& string_;
  Instructions& insns_;
  ObjectStore* const store_;
  TypeTestingStubNamer namer_;
};

class AssemblyImageWriter : public ImageWriter {
 public:
  AssemblyImageWriter(Thread* thread,
                      Dart_StreamingWriteCallback callback,
                      void* callback_data,
                      bool strip = false,
                      Elf* debug_elf = nullptr);
  void Finalize();

  virtual void WriteText(WriteStream* clustered_stream, bool vm);

 private:
  void FrameUnwindPrologue();
  void FrameUnwindEpilogue();
  intptr_t WriteByteSequence(uword start, uword end);
  intptr_t Align(intptr_t alignment, uword position = 0);

#if defined(TARGET_ARCH_IS_64_BIT)
  const char* kLiteralPrefix = ".quad";
#else
  const char* kLiteralPrefix = ".long";
#endif

  intptr_t WriteWordLiteralText(compiler::target::uword value) {
    // Padding is helpful for comparing the .S with --disassemble.
#if defined(TARGET_ARCH_IS_64_BIT)
    assembly_stream_.Print(".quad 0x%0.16" Px "\n", value);
#else
    assembly_stream_.Print(".long 0x%0.8" Px "\n", value);
#endif
    return compiler::target::kWordSize;
  }

  StreamingWriteStream assembly_stream_;
  Dwarf* assembly_dwarf_;
  Elf* debug_elf_;

  DISALLOW_COPY_AND_ASSIGN(AssemblyImageWriter);
};

class BlobImageWriter : public ImageWriter {
 public:
  BlobImageWriter(Thread* thread,
                  uint8_t** instructions_blob_buffer,
                  ReAlloc alloc,
                  intptr_t initial_size,
                  Elf* debug_elf = nullptr,
                  Elf* elf = nullptr);

  virtual void WriteText(WriteStream* clustered_stream, bool vm);

  intptr_t InstructionsBlobSize() const {
    return instructions_blob_stream_.bytes_written();
  }

 private:
  intptr_t WriteByteSequence(uword start, uword end);

  WriteStream instructions_blob_stream_;
  Elf* const elf_;
  Elf* const debug_elf_;

  DISALLOW_COPY_AND_ASSIGN(BlobImageWriter);
};

}  // namespace dart

#endif  // RUNTIME_VM_IMAGE_SNAPSHOT_H_
