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
#include "vm/elf.h"
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
class Instructions;
class Object;

class Image : ValueObject {
 public:
  explicit Image(const void* raw_memory)
      : Image(reinterpret_cast<uword>(raw_memory)) {}
  explicit Image(const uword raw_memory)
      : raw_memory_(raw_memory),
        snapshot_size_(FieldValue(raw_memory, HeaderField::ImageSize)),
        extra_info_(ExtraInfo(raw_memory_, snapshot_size_)) {
    ASSERT(Utils::IsAligned(raw_memory, kMaxObjectAlignment));
  }

  // Even though an Image is read-only memory, we must return a void* here.
  // All objects in an Image are pre-marked, though, so the GC will not attempt
  // to change the returned memory.
  void* object_start() const {
    return reinterpret_cast<void*>(raw_memory_ + kHeaderSize);
  }

  uword object_size() const { return snapshot_size_ - kHeaderSize; }

  bool contains(uword address) const {
    uword start = reinterpret_cast<uword>(object_start());
    return address >= start && (address - start < object_size());
  }

  // Returns the address of the BSS section, or nullptr if one is not available.
  // Only has meaning for instructions images from precompiled snapshots.
  uword* bss() const;

  // Returns the relocated address of the isolate's instructions, or 0 if
  // one is not available. Only has meaning for instructions images from
  // precompiled snapshots.
  uword instructions_relocated_address() const;

  // Returns the GNU build ID, or nullptr if not available. See
  // build_id_length() for the length of the returned buffer. Only has meaning
  // for instructions images from precompiled snapshots.
  const uint8_t* build_id() const;

  // Returns the length of the GNU build ID returned by build_id(). Only has
  // meaning for instructions images from precompiled snapshots.
  intptr_t build_id_length() const;

  // Returns whether this instructions section was compiled to ELF. Only has
  // meaning for instructions images from precompiled snapshots.
  bool compiled_to_elf() const;

 private:
  // Word-sized fields in an Image object header.
  enum class HeaderField : intptr_t {
    // The size of the image (total of header and payload).
    ImageSize,
    // The offset of the InstructionsSection object in the image. Note this
    // offset is from the start of the _image_, _not_ from its payload start,
    // so we can detect images without an InstructionsSection by a 0 value here.
    InstructionsSectionOffset,
    // If adding more fields, updating kHeaderFields below. (However, more
    // fields _can't_ be added on 64-bit architectures, see the restrictions
    // on kHeaderSize below.)
  };

  // Number of fields described by the HeaderField enum.
  static constexpr intptr_t kHeaderFields =
      static_cast<intptr_t>(HeaderField::InstructionsSectionOffset) + 1;

  static uword FieldValue(uword raw_memory, HeaderField field) {
    return reinterpret_cast<const uword*>(
        raw_memory)[static_cast<intptr_t>(field)];
  }

  // Constants used to denote special values for the offsets in the Image
  // object header and the fields of the InstructionsSection object.
  static constexpr intptr_t kNoInstructionsSection = 0;
  static constexpr intptr_t kNoBssSection = 0;
  static constexpr intptr_t kNoRelocatedAddress = 0;
  static constexpr intptr_t kNoBuildId = 0;

  // The size of the Image object header.
  //
  // Note: Image::kHeaderSize is _not_ an architecture-dependent constant,
  // and so there is no compiler::target::Image::kHeaderSize.
  static constexpr intptr_t kHeaderSize = kMaxObjectAlignment;
  // Explicitly double-checking kHeaderSize is never changed. Increasing the
  // Image header size would mean objects would not start at a place expected
  // by parts of the VM (like the GC) that use Image pages as HeapPages.
  static_assert(kHeaderSize == kMaxObjectAlignment,
                "Image page cannot be used as HeapPage");
  // Make sure that the number of fields in the Image header fit both on the
  // host and target architectures.
  static_assert(kHeaderFields * kWordSize <= kHeaderSize,
                "Too many fields in Image header for host architecture");
  static_assert(kHeaderFields * compiler::target::kWordSize <= kHeaderSize,
                "Too many fields in Image header for target architecture");

  // We don't use a handle or the tagged pointer because this object cannot be
  // moved in memory by the GC.
  static const InstructionsSectionLayout* ExtraInfo(const uword raw_memory,
                                                    const uword size);

  // Most internal uses would cast this to uword, so just store it as such.
  const uword raw_memory_;
  const intptr_t snapshot_size_;
  const InstructionsSectionLayout* const extra_info_;

  // For access to private constants.
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
  friend class ImageWriter;

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

  // Alignment constants used in writing ELF or assembly snapshots.

  // BSS sections contain word-sized data.
  static constexpr intptr_t kBssAlignment = compiler::target::kWordSize;
  // ROData sections contain objects wrapped in an Image object.
  static constexpr intptr_t kRODataAlignment = kMaxObjectAlignment;
  // Text sections contain objects (even in bare instructions mode) wrapped
  // in an Image object, and for now we also align them to the same page
  // size assumed by Elf objects.
  static_assert(Elf::kPageSize >= kMaxObjectAlignment,
                "Page alignment must be consistent with max object alignment");
  static constexpr intptr_t kTextAlignment = Elf::kPageSize;

  void ResetOffsets() {
    next_data_offset_ = Image::kHeaderSize;
    next_text_offset_ = Image::kHeaderSize;
#if defined(DART_PRECOMPILER)
    if (FLAG_precompiled_mode) {
      // We reserve space for the initial InstructionsSection object. It is
      // manually serialized since it includes offsets to other snapshot parts.
      // In bare instructions mode, it contains all the payloads and so we
      // start after the header, whereas in non-bare mode, it contains no
      // payload and Instructions start after it.
      next_text_offset_ +=
          FLAG_use_bare_instructions
              ? compiler::target::InstructionsSection::HeaderSize()
              : compiler::target::InstructionsSection::InstanceSize(0);
    }
#endif
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

  void Write(NonStreamingWriteStream* clustered_stream, bool vm);
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
  static intptr_t SizeInSnapshot(const Object& object) {
    return SizeInSnapshot(object.raw());
  }

  // Returns nullptr if there is no profile writer.
  const char* ObjectTypeForProfile(const Object& object) const;
  static const char* TagObjectTypeAsReadOnly(Zone* zone, const char* type);

 protected:
  virtual void WriteBss(bool vm) = 0;
  virtual void WriteROData(NonStreamingWriteStream* clustered_stream, bool vm);
  virtual void WriteText(bool vm) = 0;

  static uword GetMarkedTags(classid_t cid, intptr_t size);
  static uword GetMarkedTags(const Object& obj);

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
  const char* const image_type_;
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
        object_type_(writer->ObjectTypeForProfile(object)) {}

  ~TraceImageObjectScope() {
    if (writer_->profile_writer_ == nullptr) return;
    ASSERT(writer_->IsROSpace());
    writer_->profile_writer_->SetObjectTypeAndName(
        {writer_->offset_space_, start_offset_}, object_type_, nullptr);
    writer_->profile_writer_->AttributeBytesTo(
        {writer_->offset_space_, start_offset_},
        stream_->Position() - section_offset_ - start_offset_);
  }

 private:
  ImageWriter* const writer_;
  const T* const stream_;
  const intptr_t section_offset_;
  const intptr_t start_offset_;
  const char* const object_type_;
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
                      BaseWriteStream* stream,
                      bool strip = false,
                      Elf* debug_elf = nullptr);
  void Finalize();

 private:
  virtual void WriteBss(bool vm);
  virtual void WriteROData(NonStreamingWriteStream* clustered_stream, bool vm);
  virtual void WriteText(bool vm);

  void FrameUnwindPrologue();
  void FrameUnwindEpilogue();
  intptr_t WriteByteSequence(uword start, uword end);
  intptr_t Align(intptr_t alignment, uword position = 0);
  intptr_t WriteWordLiteralText(word value);

  BaseWriteStream* const assembly_stream_;
  Dwarf* const assembly_dwarf_;
  Elf* const debug_elf_;

  // Used to ensure unique names for Code symbols across text sections.
  intptr_t unique_symbol_counter_ = 0;

  DISALLOW_COPY_AND_ASSIGN(AssemblyImageWriter);
};

class BlobImageWriter : public ImageWriter {
 public:
  BlobImageWriter(Thread* thread,
                  NonStreamingWriteStream* vm_instructions,
                  NonStreamingWriteStream* isolate_instructions,
                  Elf* debug_elf = nullptr,
                  Elf* elf = nullptr);

 private:
  virtual void WriteBss(bool vm);
  virtual void WriteROData(NonStreamingWriteStream* clustered_stream, bool vm);
  virtual void WriteText(bool vm);

  intptr_t WriteByteSequence(uword start, uword end);

  NonStreamingWriteStream* const vm_instructions_;
  NonStreamingWriteStream* const isolate_instructions_;
  Elf* const elf_;
  Elf* const debug_elf_;

  NonStreamingWriteStream* instructions_blob_stream_ = nullptr;
  // Used to ensure unique names for Code symbols across text sections.
  intptr_t unique_symbol_counter_ = 0;

  DISALLOW_COPY_AND_ASSIGN(BlobImageWriter);
};

}  // namespace dart

#endif  // RUNTIME_VM_IMAGE_SNAPSHOT_H_
