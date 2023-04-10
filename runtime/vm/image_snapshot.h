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

#if defined(DEBUG)
#define SNAPSHOT_BACKTRACE
#endif

namespace dart {

// Forward declarations.
class BitsContainer;
class Code;
class Dwarf;
class Elf;
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
    ASSERT(Utils::IsAligned(raw_memory, kObjectStartAlignment));
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
  static constexpr intptr_t kHeaderSize = kObjectStartAlignment;
  // Explicitly double-checking kHeaderSize is never changed. Increasing the
  // Image header size would mean objects would not start at a place expected
  // by parts of the VM (like the GC) that use Image pages as Pages.
  static_assert(kHeaderSize == kObjectStartAlignment,
                "Image page cannot be used as Page");
  // Make sure that the number of fields in the Image header fit both on the
  // host and target architectures.
  static_assert(kHeaderFields * kWordSize <= kHeaderSize,
                "Too many fields in Image header for host architecture");
  static_assert(kHeaderFields * compiler::target::kWordSize <= kHeaderSize,
                "Too many fields in Image header for target architecture");

  // We don't use a handle or the tagged pointer because this object cannot be
  // moved in memory by the GC.
  static const UntaggedInstructionsSection* ExtraInfo(const uword raw_memory,
                                                      const uword size);

  // Most internal uses would cast this to uword, so just store it as such.
  const uword raw_memory_;
  const intptr_t snapshot_size_;
  const UntaggedInstructionsSection* const extra_info_;

  // For access to private constants.
  friend class AssemblyImageWriter;
  friend class BitsContainer;
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
  ObjectOffsetPair() : ObjectOffsetPair(nullptr, 0) {}
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
  static uword Hash(Key key);
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
                     intptr_t trampoline_length)
      : expected_offset(expected_offset),
        op(ImageWriterCommand::InsertBytesOfTrampoline),
        insert_trampoline_bytes({trampoline_bytes, trampoline_length}) {}

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
  explicit ImageWriter(Thread* thread, bool generates_assembly);
  virtual ~ImageWriter() {}

  // Alignment constants used in writing ELF or assembly snapshots.

  // BSS sections contain word-sized data.
  static constexpr intptr_t kBssAlignment = compiler::target::kWordSize;
  // ROData sections contain objects wrapped in an Image object.
  static constexpr intptr_t kRODataAlignment = kObjectStartAlignment;
  // Text sections contain objects (even in bare instructions mode) wrapped
  // in an Image object.
  static constexpr intptr_t kTextAlignment = kObjectStartAlignment;

  void ResetOffsets() {
    next_data_offset_ = Image::kHeaderSize;
    next_text_offset_ = Image::kHeaderSize;
#if defined(DART_PRECOMPILER)
    if (FLAG_precompiled_mode) {
      // We reserve space for the initial InstructionsSection object. It is
      // manually serialized since it includes offsets to other snapshot parts.
      // It contains all the payloads which start directly after the header.
      next_text_offset_ += compiler::target::InstructionsSection::HeaderSize();
    }
#endif
    objects_.Clear();
    instructions_.Clear();
  }

  // Will start preparing the ".text" segment by interpreting the provided
  // [ImageWriterCommand]s.
  void PrepareForSerialization(GrowableArray<ImageWriterCommand>* commands);

  bool IsROSpace() const {
    return offset_space_ == IdSpace::kVmData ||
           offset_space_ == IdSpace::kVmText ||
           offset_space_ == IdSpace::kIsolateData ||
           offset_space_ == IdSpace::kIsolateText;
  }
  int32_t GetTextOffsetFor(InstructionsPtr instructions, CodePtr code);
#if defined(SNAPSHOT_BACKTRACE)
  uint32_t GetDataOffsetFor(ObjectPtr raw_object, ObjectPtr raw_parent);
#else
  uint32_t GetDataOffsetFor(ObjectPtr raw_object);
#endif

  uint32_t AddBytesToData(uint8_t* bytes, intptr_t length);

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
    return SizeInSnapshot(object.ptr());
  }

  // Returns nullptr if there is no profile writer.
  const char* ObjectTypeForProfile(const Object& object) const;
  static const char* TagObjectTypeAsReadOnly(Zone* zone, const char* type);

  enum class ProgramSection {
    Text,     // Instructions.
    Data,     // Read-only data.
    Bss,      // Statically allocated variables initialized at load.
    BuildId,  // GNU build ID (when applicable)
    // Adjust kNumProgramSections below to use last enum value added.
  };

  static constexpr intptr_t kNumProgramSections =
      static_cast<int>(ProgramSection::BuildId) + 1;

#if defined(DART_PRECOMPILER)
  // Returns a predetermined label for the given section in the VM isolate
  // (if vm is true) or application isolate (otherwise) section. Some sections
  // are shared by both.
  static constexpr intptr_t SectionLabel(ProgramSection section, bool vm) {
    // Both vm and isolate share the build id section.
    const bool shared = section == ProgramSection::BuildId;
    // The initial 1 is to ensure the result is positive.
    return 1 + 2 * static_cast<int>(section) + ((shared || vm) ? 0 : 1);
  }
#endif

 protected:
  virtual void WriteBss(bool vm) = 0;
  virtual void WriteROData(NonStreamingWriteStream* clustered_stream, bool vm);
  void WriteText(bool vm);

  // Returns the standard Dart dynamic symbol name for the given VM isolate (if
  // vm is true) or application isolate (otherwise) section. Some sections are
  // shared by both.
  static const char* SectionSymbol(ProgramSection section, bool vm);

  static uword GetMarkedTags(classid_t cid,
                             intptr_t size,
                             bool is_canonical = false);
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
#if defined(SNAPSHOT_BACKTRACE)
    explicit ObjectData(ObjectPtr raw_obj, ObjectPtr raw_parent)
        : raw_obj(raw_obj),
          raw_parent(raw_parent),
          flags(IsObjectField::encode(true) |
                IsOriginalObjectField::encode(true)) {}
    ObjectData(uint8_t* buf, intptr_t length)
        : bytes({buf, length}),
          raw_parent(Object::null()),
          flags(IsObjectField::encode(false) |
                IsOriginalObjectField::encode(false)) {}
#else
    explicit ObjectData(ObjectPtr raw_obj)
        : raw_obj(raw_obj),
          flags(IsObjectField::encode(true) |
                IsOriginalObjectField::encode(true)) {}
    ObjectData(uint8_t* buf, intptr_t length)
        : bytes({buf, length}),
          flags(IsObjectField::encode(false) |
                IsOriginalObjectField::encode(false)) {}
#endif

    union {
      struct {
        uint8_t* buf;
        intptr_t length;
      } bytes;
      ObjectPtr raw_obj;
      const Object* obj;
    };
#if defined(SNAPSHOT_BACKTRACE)
    union {
      ObjectPtr raw_parent;
      const Object* parent;
    };
#endif
    uint8_t flags;

    bool is_object() const {
      return IsObjectField::decode(flags);
    }
    bool is_original_object() const {
      return IsOriginalObjectField::decode(flags);
    }

    void set_is_object(bool value) {
      flags = IsObjectField::update(value, flags);
    }

    using IsObjectField = BitField<uint8_t, bool, 0, 1>;
    using IsOriginalObjectField =
        BitField<uint8_t, bool, IsObjectField::kNextBit, 1>;
  };

  // Methods abstracting out the particulars of the underlying concrete writer.

  // Marks the entrance into a particular ProgramSection for either the VM
  // isolate (if vm is true) or application isolate (if not). Returns false if
  // this section should not be written.
  virtual bool EnterSection(ProgramSection name,
                            bool vm,
                            intptr_t alignment,
                            intptr_t* alignment_padding = nullptr) = 0;
  // Marks the exit from a particular ProgramSection, allowing subclasses to
  // do any post-writing work.
  virtual void ExitSection(ProgramSection name, bool vm, intptr_t size) = 0;
  // Writes a prologue to the text section that describes how to interpret
  // Dart stack frames using DWARF's Call Frame Information (CFI).
  virtual void FrameUnwindPrologue() = 0;
  // Writes an epilogue to the text section that marks the end of instructions
  // covered by the CFI information in the prologue.
  virtual void FrameUnwindEpilogue() = 0;
  // Writes a target uword-sized value to the section contents.
  virtual intptr_t WriteTargetWord(word value) = 0;
  // Writes a sequence of bytes of length [size] from address [bytes] to the
  // section contents.
  virtual intptr_t WriteBytes(const void* bytes, intptr_t size) = 0;
  // Pads the section contents to a given alignment with zeroes.
  virtual intptr_t Align(intptr_t alignment,
                         intptr_t offset,
                         intptr_t position) = 0;
#if defined(DART_PRECOMPILER)
  // Writes a target word-sized value that depends on the final relocated
  // addresses of the sections named by the two symbols. If T is the final
  // relocated address of the target section and S is the final relocated
  // address of the source, the final value is:
  //   (T + target_offset + target_addend) - (S + source_offset)
  virtual intptr_t Relocation(intptr_t section_offset,
                              intptr_t source_label,
                              intptr_t source_offset,
                              intptr_t target_label,
                              intptr_t target_offset) = 0;
  // Writes a target word-sized value that contains the relocated address
  // pointed to by the given symbol.
  virtual intptr_t RelocatedAddress(intptr_t section_offset,
                                    intptr_t label) = 0;
  // Creates a static symbol for the given Code object when appropriate.
  virtual void AddCodeSymbol(const Code& code,
                             const char* symbol,
                             intptr_t section_offset) = 0;
  // Creates a static symbol for a read-only data object when appropriate.
  virtual void AddDataSymbol(const char* symbol,
                             intptr_t section_offset,
                             size_t size) = 0;

  // Overloaded convenience versions of the above virtual methods.

  // An overload of Relocation where the target and source offsets and
  // target addend are 0.
  intptr_t Relocation(intptr_t section_offset,
                      intptr_t source_label,
                      intptr_t target_label) {
    return Relocation(section_offset, source_label, 0, target_label, 0);
  }
#endif
  // Writes a fixed-sized value of type T to the section contents.
  template <typename T>
  intptr_t WriteFixed(T value) {
    return WriteBytes(&value, sizeof(value));
  }
  // Like Align, but instead of padding with zeroes, the appropriate break
  // instruction for the target architecture is used.
  intptr_t AlignWithBreakInstructions(intptr_t alignment, intptr_t offset);

  Thread* const thread_;
  Zone* const zone_;
  intptr_t next_data_offset_;
  intptr_t next_text_offset_;
  GrowableArray<ObjectData> objects_;
  GrowableArray<InstructionsData> instructions_;

#if defined(DART_PRECOMPILER)
  class SnapshotTextObjectNamer : ValueObject {
   public:
    explicit SnapshotTextObjectNamer(Zone* zone, bool for_assembly)
        : zone_(ASSERT_NOTNULL(zone)),
          lib_(Library::Handle(zone)),
          cls_(Class::Handle(zone)),
          parent_(Function::Handle(zone)),
          owner_(Object::Handle(zone)),
          string_(String::Handle(zone)),
          insns_(Instructions::Handle(zone)),
          store_(IsolateGroup::Current()->object_store()),
          for_assembly_(for_assembly),
          usage_count_(zone) {}

    const char* StubNameForType(const AbstractType& type) const;

    // Returns a unique name for text data to use in symbols. The name is
    // not assembly-safe and must be appropriately quoted in assembly output.
    // Assumes that code in the InstructionsData has been allocated a handle.
    const char* SnapshotNameFor(const InstructionsData& data);
    // Returns a unique name for read-only data to use in symbols. The name is
    // not assembly-safe and must be appropriately quoted in assembly output.
    // Assumes that the ObjectData has already been converted to object handles.
    const char* SnapshotNameFor(const ObjectData& data);

   private:
    // Returns a unique name for the given code or read-only data object for use
    // in symbols. The name is not assembly-safe and must be appropriately
    // quoted in assembly output.
    const char* SnapshotNameFor(const Object& object);
    // Adds a non-unique name for the given object to the given buffer.
    void AddNonUniqueNameFor(BaseTextBuffer* buffer, const Object& object);
    // Modifies the symbol name in the buffer as needed for assembly use.
    void ModifyForAssembly(BaseTextBuffer* buffer);

    Zone* const zone_;
    Library& lib_;
    Class& cls_;
    Function& parent_;
    Object& owner_;
    String& string_;
    Instructions& insns_;
    ObjectStore* const store_;
    // Used to decide whether we need to add a uniqueness suffix.
    bool for_assembly_;
    CStringIntMap usage_count_;

    DISALLOW_COPY_AND_ASSIGN(SnapshotTextObjectNamer);
  };

  SnapshotTextObjectNamer namer_;

  // Reserve two positive labels for each of the ProgramSection values (one for
  // vm, one for isolate).
  intptr_t next_label_ = 1 + 2 * kNumProgramSections;
#endif

  IdSpace offset_space_ = IdSpace::kSnapshot;
  V8SnapshotProfileWriter* profile_writer_ = nullptr;
  const char* const image_type_;
  const char* const instructions_section_type_;
  const char* const instructions_type_;
  const char* const trampoline_type_;

  template <class T>
  friend class TraceImageObjectScope;

 private:
  static intptr_t SizeInSnapshotForBytes(intptr_t length);

  DISALLOW_COPY_AND_ASSIGN(ImageWriter);
};

#if defined(DART_PRECOMPILER)
static_assert(ImageWriter::SectionLabel(ImageWriter::ProgramSection::Bss,
                                        /*vm=*/true) == Elf::kVmBssLabel,
              "unexpected label for VM BSS section");
static_assert(ImageWriter::SectionLabel(ImageWriter::ProgramSection::Bss,
                                        /*vm=*/false) == Elf::kIsolateBssLabel,
              "unexpected label for isolate BSS section");
static_assert(ImageWriter::SectionLabel(ImageWriter::ProgramSection::BuildId,
                                        /*vm=*/true) == Elf::kBuildIdLabel,
              "unexpected label for build id section");
static_assert(ImageWriter::SectionLabel(ImageWriter::ProgramSection::BuildId,
                                        /*vm=*/false) == Elf::kBuildIdLabel,
              "unexpected label for build id section");

#define AutoTraceImage(object, section_offset, stream)                         \
  TraceImageObjectScope<std::remove_pointer<decltype(stream)>::type>           \
      AutoTraceImageObjectScopeVar##__COUNTER__(this, section_offset, stream,  \
                                                object);

template <typename T>
class TraceImageObjectScope : ValueObject {
 public:
  TraceImageObjectScope(ImageWriter* writer,
                        intptr_t section_offset,
                        const T* stream,
                        const Object& object)
      : writer_(ASSERT_NOTNULL(writer)),
        stream_(ASSERT_NOTNULL(stream)),
        section_offset_(section_offset),
        start_offset_(stream_->Position() - section_offset),
        object_type_(writer->ObjectTypeForProfile(object)),
        object_name_(object.IsString() ? object.ToCString() : nullptr) {}

  ~TraceImageObjectScope() {
    if (writer_->profile_writer_ == nullptr) return;
    ASSERT(writer_->IsROSpace());
    writer_->profile_writer_->SetObjectTypeAndName(
        {writer_->offset_space_, start_offset_}, object_type_, object_name_);
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
  const char* const object_name_;

  DISALLOW_COPY_AND_ASSIGN(TraceImageObjectScope);
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

  virtual bool EnterSection(ProgramSection section,
                            bool vm,
                            intptr_t alignment,
                            intptr_t* alignment_padding = nullptr);
  virtual void ExitSection(ProgramSection name, bool vm, intptr_t size);
  virtual intptr_t WriteTargetWord(word value);
  virtual intptr_t WriteBytes(const void* bytes, intptr_t size);
  virtual intptr_t Align(intptr_t alignment,
                         intptr_t offset,
                         intptr_t position);
  virtual intptr_t Relocation(intptr_t section_offset,
                              intptr_t source_label,
                              intptr_t source_offset,
                              intptr_t target_label,
                              intptr_t target_offset);
  virtual intptr_t RelocatedAddress(intptr_t section_offset, intptr_t label) {
    // Cannot calculate snapshot-relative addresses in assembly snapshots.
    return WriteTargetWord(Image::kNoRelocatedAddress);
  }
  virtual void FrameUnwindPrologue();
  virtual void FrameUnwindEpilogue();
  virtual void AddCodeSymbol(const Code& code,
                             const char* symbol,
                             intptr_t offset);
  virtual void AddDataSymbol(const char* symbol, intptr_t offset, size_t size);

  BaseWriteStream* const assembly_stream_;
  Dwarf* const assembly_dwarf_;
  Elf* const debug_elf_;

  // Used in Relocation to output "(.)" for relocations involving the current
  // section position.
  intptr_t current_section_label_ = 0;

  // Used for creating local symbols for code and data objects in the
  // debugging info, if separately written.
  ZoneGrowableArray<Elf::SymbolData>* current_symbols_ = nullptr;

  // Maps labels to the appropriate symbol names for relocations and DWARF
  // output.
  IntMap<const char*> label_to_symbol_name_;

  DISALLOW_COPY_AND_ASSIGN(AssemblyImageWriter);
};
#endif

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

  virtual bool EnterSection(ProgramSection section,
                            bool vm,
                            intptr_t alignment,
                            intptr_t* alignment_padding = nullptr);
  virtual void ExitSection(ProgramSection name, bool vm, intptr_t size);
  virtual intptr_t WriteTargetWord(word value);
  virtual intptr_t WriteBytes(const void* bytes, intptr_t size);
  virtual intptr_t Align(intptr_t alignment,
                         intptr_t offset,
                         intptr_t position);
  // TODO(rmacnak): Generate .debug_frame / .eh_frame / .arm.exidx to
  // provide unwinding information.
  virtual void FrameUnwindPrologue() {}
  virtual void FrameUnwindEpilogue() {}
#if defined(DART_PRECOMPILER)
  virtual intptr_t Relocation(intptr_t section_offset,
                              intptr_t source_label,
                              intptr_t source_offset,
                              intptr_t target_label,
                              intptr_t target_offset);
  virtual intptr_t RelocatedAddress(intptr_t section_offset, intptr_t label) {
    return ImageWriter::Relocation(section_offset,
                                   Elf::Relocation::kSnapshotRelative, label);
  }
  virtual void AddCodeSymbol(const Code& code,
                             const char* symbol,
                             intptr_t offset);
  virtual void AddDataSymbol(const char* symbol, intptr_t offset, size_t size);

  // Set on section entrance to a new array containing the relocations for the
  // current section.
  ZoneGrowableArray<Elf::Relocation>* current_relocations_ = nullptr;
  // Set on section entrance to a new array containing the local symbol data
  // for the current section.
  ZoneGrowableArray<Elf::SymbolData>* current_symbols_ = nullptr;
#endif

  NonStreamingWriteStream* const vm_instructions_;
  NonStreamingWriteStream* const isolate_instructions_;
  Elf* const elf_;
  Elf* const debug_elf_;

  // Set on section entrance to the stream that should be used by the writing
  // methods.
  NonStreamingWriteStream* current_section_stream_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(BlobImageWriter);
};

}  // namespace dart

#endif  // RUNTIME_VM_IMAGE_SNAPSHOT_H_
