// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/mach_o.h"

#if defined(DART_PRECOMPILER)

#include <utility>

#include "openssl/sha.h"
#include "platform/mach_o.h"
#include "platform/unwinding_records.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dwarf.h"
#include "vm/dwarf_so_writer.h"
#include "vm/flags.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/os.h"
#include "vm/unwinding_records.h"
#include "vm/zone_text_buffer.h"

namespace dart {

DEFINE_FLAG(bool,
            macho_linker_signature,
            true,
            "Whether to include a ad-hoc linker-signed code signature block");

DEFINE_FLAG(charp,
            macho_install_name,
            nullptr,
            "The install name to be used for the dynamic library. "
            "The output filename is used if not provided.");

DEFINE_FLAG(bool,
            macho_reduce_padding,
            false,
            "Whether to use a smaller alignment size for segments and the "
            "text/const sections in Mach-O outputs.")

#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
DEFINE_FLAG(charp,
            macho_min_os_version,
            nullptr,
            "The minimum OS version required for MacOS/iOS Mach-O snapshots");

DEFINE_FLAG(charp,
            macho_rpath,
            nullptr,
            "Run paths to be added at runtime (comma delimited)");
#endif

static constexpr intptr_t kLinearInitValue = -1;

#define DEFINE_LINEAR_FIELD_METHODS(name)                                      \
  intptr_t name() const {                                                      \
    ASSERT(name##_ != kLinearInitValue);                                       \
    return name##_;                                                            \
  }                                                                            \
  bool name##_is_set() const {                                                 \
    return name##_ != kLinearInitValue;                                        \
  }                                                                            \
  void set_##name(intptr_t value) {                                            \
    ASSERT(value != kLinearInitValue);                                         \
    ASSERT_EQUAL(name##_, kLinearInitValue);                                   \
    name##_ = value;                                                           \
  }

#define DEFINE_LINEAR_FIELD(name) intptr_t name##_ = kLinearInitValue;

// Only subclasses of MachOContents that need to be distinguished dynamically
// via Is/As checks are listed here.
#define FOR_EACH_CHECKABLE_MACHO_CONTENTS_TYPE(V)                              \
  V(MachOCommand)                                                              \
  V(MachOSegment)                                                              \
  V(MachOSection)                                                              \
  V(MachOHeader)

#define DEFINE_TYPE_CHECK_FOR(Type)                                            \
  bool Is##Type() const override {                                             \
    return true;                                                               \
  }

#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
#define FOR_EACH_MACOS_ONLY_CONCRETE_MACHO_CONTENTS_TYPE(V)                    \
  V(MachORunPath)                                                              \
  V(MachOBuildVersion)                                                         \
  V(MachOLoadDylib)
#else
#define FOR_EACH_MACOS_ONLY_CONCRETE_MACHO_CONTENTS_TYPE(V)
#endif

// All concrete subclasses of MachOContents should go here:
#define FOR_EACH_CONCRETE_MACHO_CONTENTS_TYPE(V)                               \
  FOR_EACH_MACOS_ONLY_CONCRETE_MACHO_CONTENTS_TYPE(V)                          \
  V(MachOHeader)                                                               \
  V(MachOSegment)                                                              \
  V(MachOSection)                                                              \
  V(MachOSymbolTable)                                                          \
  V(MachODynamicSymbolTable)                                                   \
  V(MachOUuid)                                                                 \
  V(MachOIdDylib)                                                              \
  V(MachOCodeSignature)

#define DECLARE_CONTENTS_TYPE_CLASS(Type) class Type;
FOR_EACH_CHECKABLE_MACHO_CONTENTS_TYPE(DECLARE_CONTENTS_TYPE_CLASS)
FOR_EACH_CONCRETE_MACHO_CONTENTS_TYPE(DECLARE_CONTENTS_TYPE_CLASS)
#undef DECLARE_CONTENTS_TYPE_CLASS

using MachORelocationsArray = ZoneGrowableArray<mach_o::relocation_info>;
using MachORelocationAddendsArray = ZoneGrowableArray<intptr_t>;

// The interface for a SharedObjectWriter::WriteStream with MachO-specific
// utility methods.
//
// If HasHashes() is true, the stream calculates and store hashes of
// written content up to the point that FinalizeHashedContent() is called.
class MachOWriteStream : public SharedObjectWriter::WriteStream {
  template <typename T, typename S>
  using only_if_unsigned = typename std::enable_if_t<std::is_unsigned_v<T>, S>;
  using Relocation = SharedObjectWriter::Relocation;

 public:
  explicit MachOWriteStream(const MachOWriter& macho)
      : SharedObjectWriter::WriteStream(macho.type()), macho_(macho) {}

  const MachOSegment& TextSegment() const;

  // Write methods that write values of a certain size out to disk.
  // The disk are written in host endian format, which matches the
  // header's magic value (since it is also written with this).
  void Write16(uword value) { WriteBytes(&value, sizeof(uint16_t)); }
  void Write32(uint32_t value) { WriteBytes(&value, sizeof(uint32_t)); }
  void Write64(uint64_t value) { WriteBytes(&value, sizeof(uint64_t)); }
  void WriteWord(compiler::target::uword value) {
    WriteBytes(&value, sizeof(compiler::target::uword));
  }

  // Write methods that force big endian output. Used in the code signature.
  void WriteBE16(uint16_t value) { Write16(Utils::HostToBigEndian16(value)); }
  void WriteBE32(uint32_t value) { Write32(Utils::HostToBigEndian32(value)); }
  void WriteBE64(uint64_t value) { Write64(Utils::HostToBigEndian64(value)); }

  // Many load commands have adjacent uint32_t fields that correspond to an
  // offset into the file and a number of bytes or objects to read starting
  // from that offset, so abstract that out to make such writes stand out.
  void WriteOffsetCount(uintptr_t offset, uintptr_t count) {
    ASSERT(Utils::IsUint(32, offset));
    Write32(offset);
    ASSERT(Utils::IsUint(32, count));
    Write32(count);
  }

  void WriteNullTerminatedCString(const char* str) {
    WriteBytes(str, strlen(str) + 1);
  }

  // Writes the first n bytes of the given string. If the string is shorter
  // than n bytes, then the remainder of the space is padded with '\0'.
  void WriteFixedLengthCString(const char* str, intptr_t n) {
    const intptr_t len = strlen(str);
    WriteBytes(str, n - len <= 0 ? n : len);
    for (intptr_t i = n - len; i > 0; --i) {
      WriteByte('\0');
    }
  }

  bool HasValueForLabel(intptr_t label, intptr_t* value) const override;

  // The maximum size of a chunk of hashed content.
  static constexpr intptr_t kChunkSize = 1 << 12;
  static_assert(Utils::IsPowerOfTwo(kChunkSize));

  // Used for cs_code_directory::hash_type.
  static constexpr uint8_t kHashType = mach_o::CS_HASHTYPE_SHA256;
  // used for cs_code_directory::hash_size.
  static constexpr uint8_t kHashSize = SHA256_DIGEST_LENGTH;

  // Whether or not this MachOWriter supports hashing content.
  virtual bool HasHashes() const = 0;
  // The number of hashes calculated from the hashed content.
  // Assumes the hashed content has already been finalized.
  virtual intptr_t num_hashes() const = 0;
  // Writes the calculated hashes to the stream.
  // Assumes the hashed content has already been finalized.
  virtual void WriteHashes() = 0;
  // Call once all content that should be hashed has been written to the stream.
  virtual void FinalizeHashedContent() = 0;

  void set_current_relocation_addends(
      const MachORelocationAddendsArray* array) {
    current_relocation_addends_ = array;
  }

 protected:
  void WriteRelocatableValue(intptr_t address,
                             const Relocation& reloc,
                             intptr_t reloc_index) override {
    if (type() != SharedObjectWriter::Type::Object) {
      // Use the super implementation.
      return SharedObjectWriter::WriteStream::WriteRelocatableValue(
          address, reloc, reloc_index);
    }
    // Relocatable objects do not resolve relocations eagerly unless
    // the source and target are the same, in which case the eagerly
    // computed value has already been calculated as the "addend".
    intptr_t to_write = 0;
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64)
    // For X64 and ARM64, the addend is stored in the relocated location
    // as the MachOWriter only uses UNSIGNED/SUBTRACTOR relocation entries.
    RELEASE_ASSERT(current_relocation_addends_ != nullptr);
    to_write = current_relocation_addends_->At(reloc_index);
#else
    // Relocatable objects aren't handled for this architecture.
    UNREACHABLE();
#endif
    ASSERT(Utils::IsInt(reloc.size_in_bytes * kBitsPerByte, to_write));
    WriteBytes(reinterpret_cast<const uint8_t*>(&to_write),
               reloc.size_in_bytes);
  }

  const MachOWriter& macho_;
  const MachORelocationAddendsArray* current_relocation_addends_ = nullptr;

 private:
  DISALLOW_COPY_AND_ASSIGN(MachOWriteStream);
};

// A MachOWriteStream that strictly delegates to the provided BaseWriteStream
// without any internal caching.
class NonHashingMachOWriteStream
    : public SharedObjectWriter::DelegatingWriteStream,
      public MachOWriteStream {
 public:
  explicit NonHashingMachOWriteStream(BaseWriteStream* stream,
                                      const MachOWriter& macho)
      : SharedObjectWriter::DelegatingWriteStream(stream, macho),
        MachOWriteStream(macho) {}

  intptr_t Position() const override {
    return SharedObjectWriter::DelegatingWriteStream::Position();
  }
  void WriteByte(const uint8_t value) override {
    SharedObjectWriter::DelegatingWriteStream::WriteByte(value);
  }
  void WriteBytes(const void* bytes, intptr_t len) override {
    SharedObjectWriter::DelegatingWriteStream::WriteBytes(bytes, len);
  }
  intptr_t Align(intptr_t alignment, intptr_t offset = 0) override {
    return SharedObjectWriter::DelegatingWriteStream::Align(alignment, offset);
  }
  bool HasValueForLabel(intptr_t label, intptr_t* value) const override {
    return MachOWriteStream::HasValueForLabel(label, value);
  }

  bool HasHashes() const override { return false; }
  intptr_t num_hashes() const override { UNREACHABLE(); }
  void WriteHashes() override { UNREACHABLE(); }
  void FinalizeHashedContent() override { UNREACHABLE(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(NonHashingMachOWriteStream);
};

// A wrapper around an BaseWriteStream that calculates hashes for kChunkSize
// chunks being flushed.
//
// FinalizeHashedContent() is called after the last write of content that
// should be hashed; further writes skip the hashing process.
// (E.g., FinalizeHashes() is called before writing the code signature in
// a Mach-O file.)
class HashingMachOWriteStream : public BaseWriteStream,
                                public MachOWriteStream {
 public:
  HashingMachOWriteStream(Zone* zone,
                          BaseWriteStream* stream,
                          const MachOWriter& macho)
      : BaseWriteStream(stream->initial_size()),
        MachOWriteStream(macho),
        zone_(zone),
        wrapped_stream_(stream),
        hashes_(zone, SHA256_DIGEST_LENGTH) {
    // So that we can use the underlying stream's Align, as all alignments
    // will be less than or equal to this alignment.
    ASSERT(Utils::IsAligned(stream->Position(), macho_.page_size()));
  }

  ~HashingMachOWriteStream() {
    // Hashed content should always been finalized earlier so the
    // hashes can be retrieved before destruction.
    ASSERT(!hashing_);
    Flush(/*chunks_only=*/false);  // Flush all bytes.
    ASSERT_EQUAL(BaseWriteStream::Position(), 0);
  }

  intptr_t Position() const override {
    return flushed_size_ + BaseWriteStream::Position();
  }
  void WriteByte(const uint8_t value) override {
    BaseWriteStream::WriteByte(value);
  }
  void WriteBytes(const void* bytes, intptr_t len) override {
    BaseWriteStream::WriteBytes(bytes, len);
  }
  intptr_t Align(intptr_t alignment, intptr_t offset = 0) override {
    ASSERT(Utils::IsPowerOfTwo(alignment));
    ASSERT(alignment <= macho_.page_size());
    return BaseWriteStream::Align(alignment, offset);
  }

  bool HasHashes() const override { return true; }
  intptr_t num_hashes() const override {
    ASSERT(!hashing_);  // Don't allow uses until hashes are finalized.
    return num_hashes_;
  }
  void WriteHashes() override {
    ASSERT(!hashing_);  // Don't allow uses until hashes are finalized.
    WriteBytes(hashes_.buffer(), num_hashes_ * kHashSize);
  }

  // First hashes and then flushes all data in the internal buffer. Afterwards,
  // the internal buffer is empty and future Flush() calls no longer perform
  // hashing before flushing to the wrapped stream.
  //
  // Changes current_ and flushed_size_ accordingly.
  void FinalizeHashedContent() override {
    Flush(/*chunks_only=*/false);
    hashing_ = false;  // End of the hashed content.
    // The only content in the hashes buffer should be the hashes themselves.
    ASSERT_EQUAL(num_hashes_ * kHashSize, hashes_.Position());
  }

 private:
  // Hashes [count] bytes of [buffer_] in [kChunkSize]-sized chunks and
  // returns the number of bytes hashed.
  intptr_t Hash(intptr_t count) {
    ASSERT(count >= 0);
    if (count > 0) {
      ASSERT(count <= BaseWriteStream::Position());
      for (intptr_t offset = 0; offset < count; offset += kChunkSize) {
        const intptr_t len = Utils::Minimum(count - offset, kChunkSize);
        SHA256(buffer_ + offset, len, digest_);
        hashes_.WriteBytes(digest_, kHashSize);
        num_hashes_ += 1;
      }
    }
    return count;
  }

  // If hashing, then hash all complete chunks and, if [chunks_only] is false,
  // a final incomplete one, then flush all hashed bytes to the wrapped stream.
  // The internal buffer is then reset to contain only unhashed bytes (if any).
  //
  // If not hashing, then all cached content is flushed immediately.
  //
  // Changes current_ and flushed_size_ accordingly.
  void Flush(bool chunks_only) {
    intptr_t size_to_flush = BaseWriteStream::Position();
    if (hashing_) {
      intptr_t size_to_hash = size_to_flush;
      if (chunks_only) {
        size_to_hash -= size_to_hash % kChunkSize;
      }
      size_to_flush = Hash(size_to_hash);
    }
    FlushBytes(size_to_flush);
  }

  // Flushes the initial [count] bytes of [buffer_] to the wrapped stream.
  //
  // Changes current_ and flushed_size_ accordingly.
  void FlushBytes(intptr_t count) {
    ASSERT(count >= 0);
    if (count == 0) return;
    const intptr_t remaining = BaseWriteStream::Position() - count;
    ASSERT(remaining >= 0);
    wrapped_stream_->WriteBytes(buffer_, count);
    flushed_size_ += count;
    if (remaining > 0) {
      memmove(buffer_, buffer_ + count, remaining);
    }
    current_ = buffer_ + remaining;
  }

  void Realloc(intptr_t new_size) override {
    Flush(/*chunks_only=*/true);
    // Check whether there's enough space after flushing.
    if (new_size <= Remaining()) return;
    // There isn't, so realloc the buffer.
    const intptr_t old_offset = BaseWriteStream::Position();
    buffer_ = zone_->Realloc(buffer_, capacity_, new_size);
    capacity_ = buffer_ != nullptr ? new_size : 0;
    current_ = buffer_ != nullptr ? buffer_ + old_offset : nullptr;
  }

  void SetPosition(intptr_t value) override {
    // Make sure we're not trying to set the position to already-flushed data.
    ASSERT(value >= flushed_size_);
    BaseWriteStream::SetPosition(value - flushed_size_);
  }

  Zone* const zone_;
  BaseWriteStream* const wrapped_stream_;
  ZoneWriteStream hashes_;
  bool hashing_ = true;
  intptr_t flushed_size_ = 0;
  intptr_t num_hashes_ = 0;
  uint8_t digest_[kHashSize];  // Used for SHA256().

  DISALLOW_COPY_AND_ASSIGN(HashingMachOWriteStream);
};

// A superclass for all objects that represent some content in the MachO output.
class MachOContents : public ZoneAllocated {
 public:
  explicit MachOContents(bool needs_offset = true, bool in_segment = true)
      // Set the file offset and/or (relative) memory address to 0 if unneeded.
      : file_offset_(needs_offset ? kLinearInitValue : 0),
        memory_address_(in_segment ? kLinearInitValue : 0) {}
  virtual ~MachOContents() {}

  struct Visitor : public ValueObject {
   public:
    Visitor() {}
    virtual ~Visitor() {}

    virtual void Default(MachOContents* c) {}

#define DEFINE_VISIT_METHOD(Type)                                              \
  virtual void Visit##Type(Type* m) {                                          \
    Default(reinterpret_cast<MachOContents*>(m));                              \
  }
    FOR_EACH_CONCRETE_MACHO_CONTENTS_TYPE(DEFINE_VISIT_METHOD)
#undef DEFINE_VISIT_METHOD

   private:
    DISALLOW_COPY_AND_ASSIGN(Visitor);
  };

  virtual void Accept(Visitor* visitor) = 0;
  virtual void VisitChildren(Visitor* visitor) {}

  // Content methods.

  // Whether WriteSelf() for this object or any nested object writes content
  // to the file. For most objects, the file offset is set to 0 at construction
  // if no content is written by it or nested objects.
  //
  // Overwrite this if the computed file offset can be 0 (e.g., the header).
  virtual bool HasContents() const { return file_offset_ != 0; }

  // Returns the size written to disk by WriteSelf().
  //
  // Only needs to be overwritten for unallocated objects or objects where
  // the number of bytes written by WriteSelf() does not match SelfMemorySize().
  virtual intptr_t SelfFileSize() const {
    if (!HasContents()) return 0;
    return SelfMemorySize();
  }

  // Writes the file contents for this object to the stream.
  //
  // Note that this does not write the load command for a command, as that
  // is handled separately by MachOCommand::WriteLoadCommand().
  //
  // Only needs to be overwritten for objects with non-zero SelfFileSize().
  virtual void WriteSelf(MachOWriteStream* stream) const {
    ASSERT_EQUAL(SelfFileSize(), 0);
    return;
  }

  // Returns whether the contents of an object is a segment or contained within
  // a segment and thus has an assigned relative memory address. If it has none,
  // then the memory offset is set to 0 at construction.
  //
  // Note: While technically load commands are in a segment due to being in the
  // header, this returns false for commands that only generate load commands.
  //
  // Should be overwritten if a segment or segment-contained object has a
  // computed relative memory address of 0 (e.g., the header).
  virtual bool IsAllocated() const { return memory_address_ != 0; }

  // Returns the size allocated in the output's memory space for this object
  // without including any allocation for nested objects.
  //
  // Should be overridden for allocated objects.
  virtual intptr_t SelfMemorySize() const {
    if (!IsAllocated()) return 0;
    UNREACHABLE();
  }

  // Utility/miscellaneous methods.

#define DEFINE_BASE_TYPE_CHECKS(Type)                                          \
  Type* As##Type() {                                                           \
    return Is##Type() ? reinterpret_cast<Type*>(this) : nullptr;               \
  }                                                                            \
  const Type* As##Type() const {                                               \
    return const_cast<Type*>(const_cast<MachOContents*>(this)->As##Type());    \
  }                                                                            \
  virtual bool Is##Type() const { return false; }

  FOR_EACH_CHECKABLE_MACHO_CONTENTS_TYPE(DEFINE_BASE_TYPE_CHECKS)
#undef DEFINE_BASE_TYPE_CHECKS

  // Returns the alignment needed for the non-header contents.
  virtual intptr_t Alignment() const {
    // No need to override for non-allocated commands with no contents.
    ASSERT(!IsAllocated() && !HasContents());
    UNREACHABLE();
  }

  // The size of the contents written to disk by WriteSelf() for this
  // object and any nested subobjects.
  //
  // Should be overwritten for objects that can have different
  // file and memory sizes.
  virtual intptr_t FileSize() const {
    if (!HasContents()) return 0;
    ASSERT(IsAllocated());
    return MemorySize();
  }

  // The size of this object and any subobjects combined in the output's memory
  // space. Note that objects may have a different MemorySize() than FileSize()
  // (e.g., a segment that contains zerofill sections).
  //
  // Should be overridden when the object contains nested objects.
  virtual intptr_t MemorySize() const { return SelfMemorySize(); }

#define FOR_EACH_CONTENTS_LINEAR_FIELD(M)                                      \
  M(file_offset)                                                               \
  M(memory_address)

  FOR_EACH_CONTENTS_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

 private:
  FOR_EACH_CONTENTS_LINEAR_FIELD(DEFINE_LINEAR_FIELD);

#undef FOR_EACH_CONTENTS_LINEAR_FIELD

  DISALLOW_COPY_AND_ASSIGN(MachOContents);
};

// Each MachO command corresponds to two parts in the file contents:
// the load command in the header that describes how to load the command
// contents and the command contents somewhere after the header.
//
// The load command is written via WriteLoadCommand() while WriteSelf()
// handles writing the command contents.
//
// Each concrete subclass of MachOCommand should define
//   static constexpr uint32_t kCommandCode = ...
// with the appropriate mach_o::LC_* constant.
class MachOCommand : public MachOContents {
 public:
  explicit MachOCommand(intptr_t cmd,
                        bool needs_offset = true,
                        bool in_segment = true)
      : MachOContents(needs_offset, in_segment), cmd_(cmd) {
    ASSERT(Utils::IsUint(32, cmd));
  }

  DEFINE_TYPE_CHECK_FOR(MachOCommand)

  // Load command fields and methods.

  // The value identifying the type of section the load command represents.
  // Should be one of the LC_* constants in platform/mach_o.h.
  uint32_t cmd() const { return cmd_; }

  // The alignment expected for load commands.
  static constexpr intptr_t kLoadCommandAlignment = compiler::target::kWordSize;

  // The size of the load command representing this command in the header.
  //
  // Note that all load commands must have a size that is a multiple of
  // kLoadCommandAlignment, so padding may be required.
  virtual uint32_t cmdsize() const = 0;

  // Each load command has a common prefix, which is written by the
  // class's WriteLoadCommand. Call the base class's implementation
  // prior to writing the rest of the load command for the subclass.
  virtual void WriteLoadCommand(MachOWriteStream* stream) const {
    stream->Write32(cmd());
    stream->Write32(cmdsize());
  }

  // Only the offset within the header is defined since the file offset
  // and memory address for the load command can be derived from the
  // header's file offset and memory address using this offset.
#define FOR_EACH_COMMAND_LINEAR_FIELD(M) M(header_offset)

  FOR_EACH_COMMAND_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

 private:
  FOR_EACH_COMMAND_LINEAR_FIELD(DEFINE_LINEAR_FIELD);

#undef FOR_EACH_COMMAND_LINEAR_FIELD

 private:
  uint32_t cmd_;

  DISALLOW_COPY_AND_ASSIGN(MachOCommand);
};

class MachOSection : public MachOContents {
#if defined(TARGET_ARCH_IS_32_BIT)
  using SectionType = mach_o::section;
#else
  using SectionType = mach_o::section_64;
#endif

 public:
  MachOSection(Zone* zone,
               const char* name,
               const char* segname,
               intptr_t alignment,
               intptr_t type = mach_o::S_REGULAR,
               intptr_t attributes = mach_o::S_NO_ATTRIBUTES,
               bool has_contents = true)
      : MachOContents(/*needs_offset=*/has_contents,
                      /*in_segment=*/true),
        name_(name),
        segname_(segname),
        flags_(mach_o::SectionFlags(type, attributes)),
        alignment_(alignment),
        portions_(zone, 0) {
    ASSERT(strlen(name) <= sizeof(SectionType::sectname));
    ASSERT(strlen(segname) <= sizeof(SectionType::segname));
    ASSERT(Utils::IsPowerOfTwo(alignment));
    ASSERT_EQUAL(type & mach_o::SECTION_TYPE, static_cast<uint32_t>(type));
    ASSERT_EQUAL(attributes & mach_o::SECTION_ATTRIBUTES,
                 static_cast<uint32_t>(attributes));
    if (type == mach_o::S_ZEROFILL && type == mach_o::S_GB_ZEROFILL) {
      ASSERT(!has_contents);
    }
  }

  DEFINE_TYPE_CHECK_FOR(MachOSection)

  intptr_t Alignment() const override { return alignment_; }

  const char* name() const { return name_; }
  const char* segname() const { return segname_; }

  bool HasName(const char* name) const { return strcmp(name_, name) == 0; }
  bool HasSegname(const char* segname) const {
    return strcmp(segname_, segname) == 0;
  }

  intptr_t index() const {
    // The getter should not be called until after an initial index is assigned.
    ASSERT(index_ != mach_o::NO_SECT);
    return index_;
  }
  void set_index(intptr_t value) {
    ASSERT(value != mach_o::NO_SECT);
    index_ = value;
  }

  struct Portion {
    void Write(MachOWriteStream* stream, intptr_t section_start) const {
      ASSERT(bytes != nullptr);
      if (relocations != nullptr) {
        const intptr_t address = section_start + offset;
        stream->WriteBytesWithRelocations(bytes, size, address, *relocations);
      } else {
        stream->WriteBytes(bytes, size);
      }
    }

    bool ContainsSymbols() const {
      return symbol_name != nullptr ||
             (symbols != nullptr && !symbols->is_empty());
    }

    intptr_t offset;
    const char* symbol_name;
    intptr_t label;
    const uint8_t* bytes;
    intptr_t size;
    const SharedObjectWriter::RelocationArray* relocations;
    const SharedObjectWriter::SymbolDataArray* symbols;

   private:
    DISALLOW_ALLOCATION();
  };

  const GrowableArray<Portion>& portions() const { return portions_; }

  void AddPortion(
      const uint8_t* bytes,
      intptr_t size,
      const SharedObjectWriter::RelocationArray* relocations = nullptr,
      const SharedObjectWriter::SymbolDataArray* symbols = nullptr,
      const char* symbol_name = nullptr,
      intptr_t label = 0) {
    // Any named portion should also have a valid symbol label.
    ASSERT(symbol_name == nullptr || label > 0);
    ASSERT(!HasContents() || bytes != nullptr);
    ASSERT(bytes != nullptr || relocations == nullptr);
    // Make sure all portions are consistent in containing bytes.
    ASSERT(portions_.is_empty() ||
           (portions_[0].bytes != nullptr) == (bytes != nullptr));
    intptr_t offset = 0;
    if (!portions_.is_empty()) {
      const auto& last = portions_.Last();
      offset = last.offset + last.size;
    }
    // Each portion is aligned within the section.
    offset = Utils::RoundUp(offset, Alignment());
    portions_.Add(
        {offset, symbol_name, label, bytes, size, relocations, symbols});
  }

  intptr_t SelfMemorySize() const override {
    const auto& last = portions_.Last();
    return last.offset + last.size;
  }

  // The first section in relocated objects will have a memory offset of 0, so
  // don't use the superclass's implementation as all sections are allocated.
  bool IsAllocated() const override { return true; }

  void WriteSelf(MachOWriteStream* stream) const override {
    if (!HasContents()) return;
    stream->set_current_relocation_addends(relocation_addends_);
    for (const auto& portion : portions_) {
      // Each portion is aligned within the section.
      stream->Align(Alignment());
      ASSERT_EQUAL(stream->Position(), file_offset() + portion.offset);
      portion.Write(stream, memory_address());
    }
    stream->set_current_relocation_addends(nullptr);
  }

  const Portion* FindPortion(const char* symbol_name) const {
    for (const auto& portion : portions_) {
      if (strcmp(symbol_name, portion.symbol_name) == 0) {
        return &portion;
      }
    }
    return nullptr;
  }

  bool ContainsSymbols() const {
    for (const auto& p : portions_) {
      if (p.ContainsSymbols()) return true;
    }
    return false;
  }

  void Accept(Visitor* visitor) override { visitor->VisitMachOSection(this); }

  const MachORelocationsArray* relocations() const { return relocations_; }
  void set_relocations(const MachORelocationsArray* relocations) {
    relocations_ = relocations;
  }
  intptr_t num_relocations() const {
    return relocations_ == nullptr ? 0 : relocations_->length();
  }

  const MachORelocationAddendsArray* relocation_addends() const {
    return relocation_addends_;
  }
  void set_relocation_addends(const MachORelocationAddendsArray* array) {
    relocation_addends_ = array;
  }

 private:
  uint32_t HeaderInfoSize() const { return sizeof(SectionType); }

  // Called during MachOSegment::WriteLoadCommand.
  void WriteHeaderInfo(MachOWriteStream* stream) const {
    auto const start = stream->Position();
    stream->WriteFixedLengthCString(name_, sizeof(SectionType::sectname));
    stream->WriteFixedLengthCString(segname_, sizeof(SectionType::segname));
    // While
    stream->WriteWord(memory_address());
    stream->WriteWord(MemorySize());
    stream->Write32(file_offset());
    stream->Write32(Utils::ShiftForPowerOfTwo(Alignment()));
    stream->WriteOffsetCount(relocations_file_offset(), num_relocations());
    stream->Write32(flags_);
    // All reserved fields are 0 for our purposes.
    stream->Write32(0);  // reserved1
    stream->Write32(0);  // reserved2
#if defined(TARGET_ARCH_IS_64_BIT)
    stream->Write32(0);  // reserved3
#endif
    ASSERT_EQUAL(stream->Position(),
                 static_cast<intptr_t>(start + HeaderInfoSize()));
  }

  const char* const name_;
  const char* const segname_;
  const decltype(SectionType::flags) flags_ = 0;
  const intptr_t alignment_;
  intptr_t index_ = mach_o::NO_SECT;
  GrowableArray<Portion> portions_;
  // The array of relocation_info structs that should be output for this
  // section iff the output format is a relocatable object.
  const MachORelocationsArray* relocations_ = nullptr;
  // A list of relocation addends for relocatable objects.
  const MachORelocationAddendsArray* relocation_addends_ = nullptr;

#define FOR_EACH_CONTENTS_LINEAR_FIELD(M) M(relocations_file_offset)

 public:
  FOR_EACH_CONTENTS_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

 private:
  FOR_EACH_CONTENTS_LINEAR_FIELD(DEFINE_LINEAR_FIELD);

#undef FOR_EACH_CONTENTS_LINEAR_FIELD

  friend class MachOSegment;

  DISALLOW_COPY_AND_ASSIGN(MachOSection);
};

class MachOSegment : public MachOCommand {
#if defined(TARGET_ARCH_IS_32_BIT)
  using SegmentCommandType = mach_o::segment_command;
#else
  using SegmentCommandType = mach_o::segment_command_64;
#endif

 public:
#if defined(TARGET_ARCH_IS_32_BIT)
  static constexpr uint32_t kCommandCode = mach_o::LC_SEGMENT;
#else
  static constexpr uint32_t kCommandCode = mach_o::LC_SEGMENT_64;
#endif

  MachOSegment(Zone* zone,
               const char* name,
               intptr_t initial_vm_protection = mach_o::VM_PROT_READ,
               intptr_t max_vm_protection = mach_o::VM_PROT_READ)
      // We don't know if a segment has a file offset until we
      // know what it contains, so set it to 0 in ComputeOffsets()
      // if there are no contents.
      : MachOCommand(kCommandCode),
        name_(name),
        initial_vm_protection_(initial_vm_protection),
        max_vm_protection_(max_vm_protection),
        contents_(zone, 0) {
    ASSERT(Utils::IsInt(32, initial_vm_protection));
    ASSERT(Utils::IsInt(32, max_vm_protection));
    ASSERT(strlen(name) <= sizeof(SegmentCommandType::segname));
  }

  DEFINE_TYPE_CHECK_FOR(MachOSegment)

  const char* name() const { return name_; }
  const GrowableArray<MachOContents*>& contents() const { return contents_; }

  bool IsReadable() const {
    return (initial_vm_protection_ & mach_o::VM_PROT_READ) != 0;
  }
  bool IsWritable() const {
    return (initial_vm_protection_ & mach_o::VM_PROT_WRITE) != 0;
  }
  bool IsExecutable() const {
    return (initial_vm_protection_ & mach_o::VM_PROT_EXECUTE) != 0;
  }

  intptr_t Alignment() const override {
    // TODO(dartbug.com/61973): Use the reduced padding size as the default
    // for native (macOS/iOS) snapshots once the loading issue is resolved, or
    // document why we can't use it for native snapshots loaded by the Dart VM.
    return FLAG_macho_reduce_padding ? 64 : MachOWriter::kPageSize;
  }

  // The text segment has a file and memory offset of 0, so the superclass's
  // implementations give false negatives after ComputeOffsets.
  bool HasContents() const override { return next_contents_index_ > 0; }
  bool IsAllocated() const override { return true; }

  bool HasZerofillSections() const {
    return next_contents_index_ != contents_.length();
  }

  uint32_t cmdsize() const override {
    uword size = sizeof(SegmentCommandType);
    // The header information for sections is nested within the
    // segment load command.
    for (auto* const c : contents_) {
      if (auto* const s = c->AsMachOSection()) {
        size += s->HeaderInfoSize();
      }
    }
    ASSERT(Utils::IsUint(32, size));
    return size;
  }

  bool PadFileSizeToAlignment() const {
    // The linkedit segment should _not_ be padded to alignment, because
    // that means the code signature isn't the last contents of the file
    // when applicable.
    return !HasName(mach_o::SEG_LINKEDIT);
  }

  // Segments do not contain any header information, just nested content.
  intptr_t SelfMemorySize() const override { return 0; }

  intptr_t FileSize() const override {
    intptr_t file_size = SelfFileSize();
    for (auto* const c : contents_) {
      if (!c->HasContents()) continue;
      file_size = Utils::RoundUp(file_size, c->Alignment());
      file_size += c->FileSize();
    }
    if (PadFileSizeToAlignment()) {
      file_size = Utils::RoundUp(file_size, Alignment());
    }
    return file_size;
  }

  intptr_t UnpaddedMemorySize() const {
    intptr_t memory_size = SelfMemorySize();
    for (auto* const c : contents_) {
      ASSERT(c->IsAllocated());  // Segments never contain unallocated contents.
      memory_size = Utils::RoundUp(memory_size, c->Alignment());
      memory_size += c->MemorySize();
    }
    return memory_size;
  }

  intptr_t MemorySize() const override {
    return Utils::RoundUp(UnpaddedMemorySize(), Alignment());
  }

  // The initial segment of the Mach-O file always includes the header
  // as its first contents.
  bool IsInitial() const { return header() != nullptr; }

  // Returns the header if this is the initial segment (which contains it),
  // otherwise nullptr.
  const MachOHeader* header() const {
    return contents_.is_empty() ? nullptr : contents_[0]->AsMachOHeader();
  }

  bool HasName(const char* name) const { return strcmp(name_, name) == 0; }

  bool ContainsSymbols() const {
    for (auto* const c : contents_) {
      if (auto* const s = c->AsMachOSection()) {
        if (s->ContainsSymbols()) {
          return true;
        }
      }
    }
    return false;
  }

  void AddContents(MachOContents* c);

  bool IsDebugOnly() const {
    // Currently, the dwarf segment is the only debug-only info we add.
    return HasName(mach_o::SEG_DWARF);
  }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    stream->WriteFixedLengthCString(name_, sizeof(SegmentCommandType::segname));
    stream->WriteWord(memory_address());
    stream->WriteWord(MemorySize());
    stream->WriteWord(file_offset());
    // Only report the actual file size if there is non-header content.
    if (IsInitial() && next_contents_index_ == 1) {
      stream->WriteWord(0);
    } else {
      stream->WriteWord(FileSize());
    }
    stream->Write32(max_vm_protection_);
    stream->Write32(initial_vm_protection_);
    stream->Write32(NumSections());
    // The writer never uses segment flags.
    stream->Write32(0);
    // The load command for a segment also contains descriptions for its
    // sections instead of these being in separate load commands.
    for (auto* const c : contents_) {
      if (!c->IsMachOSection()) continue;
      c->AsMachOSection()->WriteHeaderInfo(stream);
    }
  }

  MachOSection* FindSection(const char* name, const char* segname) const {
    // Unless this is the unnamed segment in a relocatable object file, there
    // should be no need to check the segment name of the section.
    const bool unnamed = HasName(mach_o::SEG_UNNAMED);
    if (!unnamed && !HasName(segname)) {
      return nullptr;
    }
    for (auto* const c : contents_) {
      if (auto* const s = c->AsMachOSection()) {
        if (s->HasName(name)) {
          ASSERT(unnamed || s->HasSegname(name_));
          if (!unnamed || s->HasSegname(segname)) {
            return s;
          }
        }
      }
    }
    return nullptr;
  }

  intptr_t NumSections() const {
    intptr_t count = 0;
    for (auto* const c : contents_) {
      if (c->IsMachOSection()) {
        count += 1;
      }
    }
    return count;
  }

  void Accept(Visitor* visitor) override { visitor->VisitMachOSegment(this); }
  void VisitChildren(Visitor* visitor) override {
    for (auto* const c : contents_) {
      c->Accept(visitor);
    }
  }

 private:
  const char* const name_;
  bool has_contents_ = false;
  intptr_t next_contents_index_ = 0;
  mach_o::vm_prot_t initial_vm_protection_;
  mach_o::vm_prot_t max_vm_protection_;
  GrowableArray<MachOContents*> contents_;

  DISALLOW_COPY_AND_ASSIGN(MachOSegment);
};

class MachOUuid : public MachOCommand {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_UUID;

  explicit MachOUuid(const void* bytes, intptr_t len)
      : MachOCommand(kCommandCode,
                     /*needs_offset=*/false,
                     /*in_segment=*/false),
        bytes_() {
    // Make sure the length of the byte buffer matches the UUID length, so
    // that the provided UUID isn't unexpectedly truncated or extended.
    ASSERT_EQUAL(len, sizeof(bytes_));
    memmove(bytes_, bytes, sizeof(bytes_));
  }

  uint32_t cmdsize() const override { return sizeof(mach_o::uuid_command); }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    stream->WriteBytes(bytes_, sizeof(bytes_));
  }

  void Accept(Visitor* visitor) override { visitor->VisitMachOUuid(this); }

 private:
  uint8_t bytes_[sizeof(mach_o::uuid_command::uuid)];
  DISALLOW_COPY_AND_ASSIGN(MachOUuid);
};

#define MACHO_XYZ_VERSION_ENCODING(x, y, z)                                    \
  static_cast<uint32_t>(((x) << 16) | ((y) << 8) | (z))

class MachODylib : public MachOCommand {
 public:
  uint32_t cmdsize() const override {
    intptr_t size = NameOffset() + strlen(name_) + 1;
    return Utils::RoundUp(size, kLoadCommandAlignment);
  }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    stream->Write32(NameOffset());
    stream->Write32(timestamp_);
    stream->Write32(current_version_);
    stream->Write32(compatibility_version_);
    stream->WriteNullTerminatedCString(name_);
    stream->Align(kLoadCommandAlignment);
  }

  static constexpr auto kNoVersion = MACHO_XYZ_VERSION_ENCODING(0, 0, 0);

 protected:
  // This is really an abstract class, with concrete subclasses providing
  // the command code.
  MachODylib(intptr_t cmd,
             const char* name,
             intptr_t timestamp,
             intptr_t current_version = kNoVersion,
             intptr_t compatibility_version = kNoVersion)
      : MachOCommand(cmd,
                     /*needs_offset=*/false,
                     /*in_segment=*/false),
        name_(ASSERT_NOTNULL(name)),
        timestamp_(timestamp),
        current_version_(current_version),
        compatibility_version_(compatibility_version) {
    ASSERT(Utils::IsUint(32, timestamp));
    ASSERT(Utils::IsUint(32, current_version));
    ASSERT(Utils::IsUint(32, compatibility_version));
  }

 private:
  uint32_t NameOffset() const { return sizeof(mach_o::dylib_command); }

  const char* const name_;
  const uint32_t timestamp_;
  const uint32_t current_version_;
  const uint32_t compatibility_version_;

  DISALLOW_COPY_AND_ASSIGN(MachODylib);
};

class MachOIdDylib : public MachODylib {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_ID_DYLIB;

  explicit MachOIdDylib(const char* name = kDefaultSnapshotName,
                        intptr_t current_version = kNoVersion,
                        intptr_t compatibility_version = kNoVersion)
      : MachODylib(kCommandCode,
                   name,
                   0,  // Snapshots aren't copied into user.
                   current_version,
                   compatibility_version) {}

  void Accept(Visitor* visitor) override { visitor->VisitMachOIdDylib(this); }

 private:
  static constexpr char kDefaultSnapshotName[] = "aot.snapshot";
  DISALLOW_COPY_AND_ASSIGN(MachOIdDylib);
};

#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
class MachOLoadDylib : public MachODylib {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_LOAD_DYLIB;

  static MachOLoadDylib* CreateLoadSystemDylib(Zone* zone) {
    return new (zone) MachOLoadDylib(kSystemDylibName, 0, kSystemCurrentVersion,
                                     kSystemCompatVersion);
  }

  void Accept(Visitor* visitor) override { visitor->VisitMachOLoadDylib(this); }

 private:
  MachOLoadDylib(const char* name,
                 intptr_t timestamp,
                 intptr_t current_version,
                 intptr_t compatibility_version)
      : MachODylib(kCommandCode,
                   name,
                   timestamp,
                   current_version,
                   compatibility_version) {}

  static constexpr char kSystemDylibName[] = "/usr/lib/libSystem.B.dylib";
  static constexpr auto kSystemCurrentVersion =
      MACHO_XYZ_VERSION_ENCODING(1351, 0, 0);
  static constexpr auto kSystemCompatVersion =
      MACHO_XYZ_VERSION_ENCODING(1, 0, 0);

  DISALLOW_COPY_AND_ASSIGN(MachOLoadDylib);
};

class Version {
 public:
  explicit Version(intptr_t major) : Version(major, 0, 0) {}

  Version(intptr_t major, intptr_t minor) : Version(major, minor, 0) {}

  Version(intptr_t major, intptr_t minor, intptr_t patch)
      : major_(major), minor_(minor), patch_(patch) {
    ASSERT(Utils::IsUint(16, major));
    ASSERT(Utils::IsUint(8, minor));
    ASSERT(Utils::IsUint(8, patch));
  }

  Version(const Version& other)
      : major_(other.major_), minor_(other.minor_), patch_(other.patch_) {}

  static Version FromString(const char* str) {
    ASSERT(str != nullptr);
    int64_t major = 0;
    int64_t minor = 0;
    int64_t patch = 0;
    char* current = nullptr;
    if (!OS::ParseInitialInt64(str, &major, &current)) {
      FATAL("Expected an integer, got %s", str);
    }
    if (!Utils::IsUint(16, major)) {
      FATAL("Major version is too large to represent in 16 bits: %" Pd64,
            major);
    }
    if (*current != '\0' && *current != '.') {
      FATAL("Unexpected characters when parsing version: %s", current);
    }
    if (*current == '.') {
      if (!OS::ParseInitialInt64(current + 1, &minor, &current)) {
        FATAL("Expected an integer, got %s", str);
      }
      if (!Utils::IsUint(8, minor)) {
        FATAL("Minor version is too large to represent in 8 bits: %" Pd64,
              minor);
      }
      if (*current != '\0' && *current != '.') {
        FATAL("Unexpected characters when parsing version: %s", current);
      }
      if (*current == '.') {
        if (!OS::ParseInitialInt64(current + 1, &patch, &current)) {
          FATAL("Expected an integer, got %s", str);
        }
        if (!Utils::IsUint(8, patch)) {
          FATAL("Patch version is too large to represent in 8 bits: %" Pd64,
                patch);
        }
        if (*current != '\0') {
          FATAL("Unexpected characters when parsing version: %s", current);
        }
      }
    }
    return Version(major, minor, patch);
  }

  void Write(MachOWriteStream* stream) const {
    stream->Write32(MACHO_XYZ_VERSION_ENCODING(major_, minor_, patch_));
  }

  const char* ToCString() const {
    return OS::SCreate(Thread::Current()->zone(), "%" Pd ".%" Pd ".%" Pd "",
                       major_, minor_, patch_);
  }

 private:
  const intptr_t major_;
  const intptr_t minor_;
  const intptr_t patch_;
  DISALLOW_ALLOCATION();
  void operator=(const Version&) = delete;
};

// These defaults were taken from Flutter at the time of editing, but can be
// overridden using the --min-ios-version and --min-macos-version flags.
#if defined(DART_TARGET_OS_MACOS_IOS)
static const Version kDefaultMinOSVersion(13, 0, 0);  // iOS 13
#else
static const Version kDefaultMinOSVersion(10, 15, 0);  // MacOS Catalina (10.15)
#endif

class MachOBuildVersion : public MachOCommand {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_BUILD_VERSION;

  MachOBuildVersion()
      : MachOCommand(kCommandCode,
                     /*needs_offset=*/false,
                     /*in_segment=*/false),
        min_os_(FLAG_macho_min_os_version != nullptr
                    ? Version::FromString(FLAG_macho_min_os_version)
                    : kDefaultMinOSVersion) {}

  uint32_t cmdsize() const override {
    return sizeof(mach_o::build_version_command);
  }

  uint32_t platform() const {
#if defined(DART_TARGET_OS_MACOS_IOS)
    return mach_o::PLATFORM_IOS;
#else
    return mach_o::PLATFORM_MACOS;
#endif
  }

  const Version& minos() const { return min_os_; }

  const Version& sdk() const {
    // Just use the minimum version as the targeted version.
    return minos();
  }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    stream->Write32(platform());
    minos().Write(stream);
    sdk().Write(stream);
    stream->Write32(0);  // No tool versions.
  }

  void Accept(Visitor* visitor) override {
    visitor->VisitMachOBuildVersion(this);
  }

 private:
  const Version min_os_;

  DISALLOW_COPY_AND_ASSIGN(MachOBuildVersion);
};

class MachORunPath : public MachOCommand {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_RPATH;

  MachORunPath(const char* path, intptr_t length)
      : MachOCommand(kCommandCode,
                     /*needs_offset=*/false,
                     /*in_segment=*/false),
        path_(path),
        length_(length) {}

  uint32_t cmdsize() const override {
    return Utils::RoundUp(HeaderSize() + length_ + 1, kLoadCommandAlignment);
  }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    const intptr_t start = stream->Position();
    MachOCommand::WriteLoadCommand(stream);
    stream->Write32(HeaderSize());  // path.offset
    ASSERT_EQUAL(HeaderSize(), stream->Position() - start);
    stream->WriteFixedLengthCString(path_, length_);
    stream->WriteByte('\0');  // Null-terminate the string.
    stream->Align(kLoadCommandAlignment);
  }

  void Accept(Visitor* visitor) override { visitor->VisitMachORunPath(this); }

 private:
  uint32_t HeaderSize() const { return sizeof(mach_o::rpath_command); }

  const char* const path_;
  const intptr_t length_;

  DISALLOW_COPY_AND_ASSIGN(MachORunPath);
};
#endif
#undef MACHO_XYZ_VERSION_ENCODING

class MachOSymbolTable : public MachOCommand {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_SYMTAB;

  MachOSymbolTable(Zone* zone, bool in_segment)
      : MachOCommand(kCommandCode, /*needs_offset=*/true, in_segment),
        zone_(zone),
        strings_(zone),
        symbols_(zone, 0),
        by_label_index_(zone) {}

  class StringTable : public ValueObject {
   public:
    explicit StringTable(Zone* zone) : text_(zone), text_indices_(zone) {
      // Ensure the string containing a single space is always at index 0.
      const intptr_t index = Add(" ");
      ASSERT_EQUAL(index, 0);
      // Assign the empty string the index of the null byte in the
      // string added above.
      text_indices_.Insert({"", index + 1});
    }

    intptr_t Add(const char* str) {
      ASSERT(str != nullptr);
      if (auto const kv = text_indices_.Lookup(str)) {
        return kv->value;
      }
      intptr_t offset = text_.length();
      text_.AddString(str);
      text_.AddChar('\0');
      text_indices_.Insert({str, offset});
      return offset;
    }

    const char* At(intptr_t index) const {
      if (index >= text_.length()) return nullptr;
      return text_.buffer() + index;
    }

    intptr_t FileSize() const { return text_.length(); }

    void Write(MachOWriteStream* stream) const {
      stream->WriteBytes(text_.buffer(), text_.length());
    }

   private:
    ZoneTextBuffer text_;
    CStringIntMap text_indices_;
    DISALLOW_COPY_AND_ASSIGN(StringTable);
  };

  struct Symbol {
    Symbol(intptr_t n_idx,
           intptr_t n_type,
           const MachOSection* section,
           intptr_t n_desc,
           uword section_offset_or_value)
        : name_index(n_idx),
          type(n_type),
          section(section),
          description(n_desc),
          section_offset_or_value(section_offset_or_value) {
      ASSERT(Utils::IsUint(32, n_idx));
      ASSERT(Utils::IsUint(8, n_type));
      ASSERT(Utils::IsUint(16, n_desc));
    }

    void Write(MachOWriteStream* stream) const {
      const intptr_t start = stream->Position();
      stream->Write32(name_index);
      stream->WriteByte(type);
      stream->WriteByte(section_index());
      stream->Write16(description);
      stream->WriteWord(value());
      ASSERT_EQUAL(stream->Position() - start, sizeof(mach_o::nlist));
    }

    uint8_t section_index() const {
      ASSERT(section == nullptr || Utils::IsUint(8, section->index()));
      return section == nullptr ? mach_o::NO_SECT : section->index();
    }

    compiler::target::uword value() const {
      const intptr_t base = section != nullptr ? section->memory_address() : 0;
      ASSERT(Utils::IsUint(sizeof(compiler::target::uword) * kBitsPerByte,
                           base + section_offset_or_value));
      return base + section_offset_or_value;
    }

    // The index of the name in the symbol table's string table.
    uint32_t name_index;
    // See the mach_o::N_* constants for the encoding of this field.
    uint8_t type;
    // The section to which this symbol belongs, if any.
    const MachOSection* section;
    // See the mach_o::N_* constants for the encoding of this field.
    uint16_t description;
    // If section == nullptr, then this is the final value of the symbol.
    // Otherwise, it is used to calculate the final value, which can be
    // computed once the section's memory address has been set.
    intptr_t section_offset_or_value;

    DISALLOW_ALLOCATION();
  };

  const StringTable& strings() const { return strings_; }
  const GrowableArray<Symbol>& symbols() const { return symbols_; }
  DEBUG_ONLY(intptr_t max_label() const { return max_label_; })

  void AddSymbol(const char* name,
                 intptr_t type,
                 const MachOSection* section,
                 intptr_t description,
                 uword section_offset_or_value,
                 intptr_t label = -1) {
    // Section symbols should always have labels, and other symbols
    // (including symbolic debugging symbols) do not.
    if ((type & mach_o::N_STAB) != 0) {
      ASSERT(label <= 0);
    } else {
      ASSERT_EQUAL((type & mach_o::N_TYPE) == mach_o::N_SECT, label > 0);
    }
    ASSERT(!file_offset_is_set());  // Can grow until offsets computed.
    auto const name_index = strings_.Add(name);
    ASSERT(*name == '\0' || name_index != 0);
    const intptr_t new_index = num_symbols();
    symbols_.Add(
        {name_index, type, section, description, section_offset_or_value});
    if (label > 0) {
      DEBUG_ONLY(max_label_ = max_label_ > label ? max_label_ : label);
      // Store an 1-based index since 0 is kNoValue for IntMap.
      by_label_index_.Insert(label, new_index + 1);
    }
  }

  const Symbol* FindLabel(intptr_t label) const {
    ASSERT(label > 0);
    // The stored index is 1-based.
    const intptr_t symbols_index = IndexForLabel(label);
    if (symbols_index < 0) return nullptr;  // Not found.
    return &symbols_[symbols_index];
  }

  intptr_t IndexForLabel(intptr_t label) const {
    ASSERT(label > 0);
    // The stored index is 1-based.
    return by_label_index_.Lookup(label) - 1;
  }

  void Initialize(SharedObjectWriter::Type type,
                  const char* path,
                  const GrowableArray<MachOSection*>& sections,
                  bool is_stripped);

  uint32_t cmdsize() const override { return sizeof(mach_o::symtab_command); }

  intptr_t SelfMemorySize() const override {
    if (!IsAllocated()) return 0;
    return SelfFileSize();
  }

  intptr_t SelfFileSize() const override {
    return SymbolsSize() + strings_.FileSize();
  }

  intptr_t FileSize() const override { return SelfFileSize(); }

  intptr_t Alignment() const override { return compiler::target::kWordSize; }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    stream->WriteOffsetCount(file_offset(), num_symbols());
    stream->WriteOffsetCount(file_offset() + SymbolsSize(),
                             strings_.FileSize());
  }

  void WriteSelf(MachOWriteStream* stream) const override {
    for (const auto& symbol : symbols_) {
      symbol.Write(stream);
    }
    strings_.Write(stream);
  }

  intptr_t num_symbols() const { return symbols_.length(); }

  void Accept(Visitor* visitor) override {
    visitor->VisitMachOSymbolTable(this);
  }

#define FOR_EACH_SYMBOL_TABLE_LINEAR_FIELD(M)                                  \
  M(num_local_symbols)                                                         \
  M(num_external_symbols)

  FOR_EACH_SYMBOL_TABLE_LINEAR_FIELD(DEFINE_LINEAR_FIELD_METHODS);

 private:
  intptr_t SymbolsSize() const { return num_symbols() * sizeof(mach_o::nlist); }

  Zone* const zone_;
  StringTable strings_;
  GrowableArray<Symbol> symbols_;
  // Maps symbol labels (positive integers) to indexes in symbols_.
  IntMap<intptr_t> by_label_index_;
  DEBUG_ONLY(intptr_t max_label_ = 0;)  // For consistency checks.

  FOR_EACH_SYMBOL_TABLE_LINEAR_FIELD(DEFINE_LINEAR_FIELD);
#undef FOR_EACH_SYMBOL_TABLE_LINEAR_FIELD

  DISALLOW_COPY_AND_ASSIGN(MachOSymbolTable);
};

class MachODynamicSymbolTable : public MachOCommand {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_DYSYMTAB;

  MachODynamicSymbolTable(const MachOSymbolTable& table, bool in_segment)
      : MachOCommand(kCommandCode, /*needs_offset=*/true, in_segment),
        table_(table) {}

  uint32_t cmdsize() const override { return sizeof(mach_o::dysymtab_command); }

  intptr_t Alignment() const override { return compiler::target::kWordSize; }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    // The symbol table contains local symbols and then external symbols.
    intptr_t index = 0;
    stream->WriteOffsetCount(index, table_.num_local_symbols());
    index += table_.num_local_symbols();
    stream->WriteOffsetCount(index, table_.num_external_symbols());
    index += table_.num_external_symbols();
    // No undefined symbols.
    stream->WriteOffsetCount(index, 0);
    // The rest of the fields are 0-filled.
    for (intptr_t i = 0; i < kUnusedOffsetCountPairs; ++i) {
      stream->WriteOffsetCount(0, 0);
    }
  }

  // Currently no contents are written to the linkedit segment, as the
  // only non-zero fields are indexes/counts into the symbol table.
  intptr_t SelfMemorySize() const override { return 0; }
  intptr_t SelfFileSize() const override { return 0; }
  intptr_t FileSize() const override { return SelfFileSize(); }

  void Accept(Visitor* visitor) override {
    visitor->VisitMachODynamicSymbolTable(this);
  }

 private:
  static constexpr intptr_t kUnusedOffsetCountPairs = 6;

  const MachOSymbolTable& table_;
  DISALLOW_COPY_AND_ASSIGN(MachODynamicSymbolTable);
};

class MachOLinkEditData : public MachOCommand {
 public:
  uint32_t cmdsize() const override {
    return sizeof(mach_o::linkedit_data_command);
  }

  void WriteLoadCommand(MachOWriteStream* stream) const override {
    MachOCommand::WriteLoadCommand(stream);
    stream->WriteOffsetCount(file_offset(), FileSize());
  }

 protected:
  // This is really an abstract class, with concrete subclasses providing
  // the command code.
  explicit MachOLinkEditData(intptr_t cmd)
      : MachOCommand(cmd, /*needs_offset=*/true, /*in_segment=*/true) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(MachOLinkEditData);
};

class MachOCodeSignature : public MachOLinkEditData {
 public:
  static constexpr uint32_t kCommandCode = mach_o::LC_CODE_SIGNATURE;

  explicit MachOCodeSignature(const char* identifier)
      : MachOLinkEditData(kCommandCode), identifier_(identifier) {}

  static constexpr intptr_t kHeaderAlignment = 8;
  static constexpr intptr_t kHashAlignment = 16;

  intptr_t Alignment() const override { return kHashAlignment; }

  intptr_t SelfMemorySize() const override {
    return DirectoryOffset() + DirectoryLength();
  }

  void WriteSelf(MachOWriteStream* stream) const override {
    // The code signature marks the end of the hashed content, as
    // it contains the hashes that ensure the previous content has
    // not been modified (modulo hash collisions).
    stream->FinalizeHashedContent();
    ASSERT_EQUAL(stream->num_hashes(), ExpectedNumHashes());
    const intptr_t start = stream->Position();
    // The superblob header, which includes a single blob index.
    stream->WriteBE32(mach_o::CSMAGIC_EMBEDDED_SIGNATURE);  // magic
    stream->WriteBE32(FileSize());                          // length
    stream->WriteBE32(1);                                   // count
    // Blob index for the code directory.
    stream->WriteBE32(mach_o::CSSLOT_CODEDIRECTORY);  // type
    stream->WriteBE32(DirectoryOffset());             // offset
    stream->Align(kHeaderAlignment);
    // Now the header for the code directory.
    ASSERT_EQUAL(stream->Position() - start, DirectoryOffset());
    const intptr_t directory_start = stream->Position();
    stream->WriteBE32(mach_o::CSMAGIC_CODEDIRECTORY);                // magic
    stream->WriteBE32(DirectoryLength());                            // length
    stream->WriteBE32(mach_o::CS_SUPPORTSEXECSEG);                   // version
    stream->WriteBE32(mach_o::CS_ADHOC | mach_o::CS_LINKER_SIGNED);  // flags
    stream->WriteBE32(HashOffset());
    stream->WriteBE32(IdentOffset());
    stream->WriteBE32(0);                     // num special slots (hashes)
    stream->WriteBE32(stream->num_hashes());  // num code slots (hashes)
    stream->WriteBE32(file_offset());         // code limit
    stream->WriteByte(MachOWriteStream::kHashSize);
    stream->WriteByte(MachOWriteStream::kHashType);
    stream->WriteByte(0);  // platform
    // The page size is represented by its base 2 logarithm.
    stream->WriteByte(Utils::ShiftForPowerOfTwo(MachOWriteStream::kChunkSize));
    stream->WriteBE32(0);  // spare2 (always 0)
    // version >= 0x20100 (CS_SUPPORTSSCATTER)
    stream->WriteBE32(0);  // scatter offset
    // version >= 0x20200 (CS_SUPPORTSTEAMID)
    stream->WriteBE32(0);  // teamid offset
    // version >= 0x20300 (CS_SUPPORTSCODELIMIT64)
    stream->WriteBE32(0);  // spare3 (always 0)
    stream->WriteBE64(0);  // code limit (64-bit)
    // version >= 0x20400 (CS_SUPPORTSEXECSEG)
    stream->WriteBE64(stream->TextSegment().file_offset());  // offset
    stream->WriteBE64(stream->TextSegment().FileSize());     // limit
    stream->WriteBE64(0);                                    // flags
    stream->Align(kHeaderAlignment);
    ASSERT_EQUAL(stream->Position() - directory_start, IdentOffset());
    stream->WriteFixedLengthCString(identifier_, strlen(identifier_) + 1);
    stream->Align(kHashAlignment);
    ASSERT_EQUAL(stream->Position() - directory_start, HashOffset());
    stream->WriteHashes();
    ASSERT_EQUAL(stream->Position() - directory_start, DirectoryLength());
  }

  void Accept(Visitor* visitor) override {
    visitor->VisitMachOCodeSignature(this);
  }

 private:
  // The offset of the code directory in the code signature.
  intptr_t DirectoryOffset() const {
    // A single blob index for the code directory.
    const intptr_t offset =
        sizeof(mach_o::cs_superblob) + sizeof(mach_o::cs_blob_index);
    return Utils::RoundUp(offset, kHeaderAlignment);
  }

  intptr_t DirectoryLength() const {
    return HashOffset() + ExpectedNumHashes() * MachOWriteStream::kHashSize;
  }

  // The offset of the identifier within the code directory.
  intptr_t IdentOffset() const {
    // Include the directory offset to ensure proper alignment, but the
    // returned value is relative to the code directory start.
    intptr_t signature_offset =
        DirectoryOffset() + sizeof(mach_o::cs_code_directory);
    return Utils::RoundUp(signature_offset, kHeaderAlignment) -
           DirectoryOffset();
  }

  // The offset of the list of hashes within the code directory.
  intptr_t HashOffset() const {
    // Include the directory offset to ensure proper alignment, but the
    // returned value is relative to the code directory start.
    const intptr_t signature_offset =
        DirectoryOffset() + IdentOffset() + strlen(identifier_) + 1;
    return Utils::RoundUp(signature_offset, kHashAlignment) - DirectoryOffset();
  }

  intptr_t ExpectedNumHashes() const {
    // The actual hashes are stored in the stream, which isn't available yet.
    // However, if the file offsets of the code signature has been computed, the
    // number of hashes that should be contained in the stream can be computed.
    const intptr_t chunk_size = MachOWriteStream::kChunkSize;
    return (file_offset() + chunk_size - 1) / chunk_size;
  }

  const char* const identifier_;

  DISALLOW_COPY_AND_ASSIGN(MachOCodeSignature);
};

// A representation of the header of the Mach-O file. This contains
// any commands that have load commands within the header.
class MachOHeader : public MachOContents {
#if defined(TARGET_ARCH_IS_32_BIT)
  using HeaderType = mach_o::mach_header;
#else
  using HeaderType = mach_o::mach_header_64;
#endif

  using SnapshotType = SharedObjectWriter::Type;

 public:
  MachOHeader(Zone* zone,
              SnapshotType type,
              bool is_stripped,
              bool has_separate_object,
              const char* identifier,
              const char* path,
              Dwarf* dwarf)
      : MachOContents(/*needs_offset=*/true,
                      /*in_segment=*/type != SnapshotType::Object),
        zone_(zone),
        type_(type),
        is_stripped_(is_stripped),
        has_separate_object_(has_separate_object),
        identifier_(identifier != nullptr ? identifier : ""),
        path_(path),
        dwarf_(dwarf),
        commands_(zone, 0),
        full_symtab_(zone, /*in_segment=*/type != SnapshotType::Object) {
#if defined(DART_TARGET_OS_MACOS)
    // A non-nullptr identifier must be provided for MacOS targets.
    ASSERT(identifier != nullptr);
#endif
    // Unstripped content must have DWARF information available.
    ASSERT(dwarf != nullptr || is_stripped_);
    // Only snapshots should be stripped.
    ASSERT(!is_stripped_ || type == SnapshotType::Snapshot);
  }

  DEFINE_TYPE_CHECK_FOR(MachOHeader)

  Zone* zone() const { return zone_; }
  const GrowableArray<MachOCommand*>& commands() const { return commands_; }
  const MachOSymbolTable& relocation_symbol_table() const {
    return full_symtab_;
  }
  const MachOSegment& text_segment() const {
    ASSERT(text_segment_ != nullptr);
    return *text_segment_;
  }
  SharedObjectWriter::Type type() const { return type_; }

  intptr_t NumSections() const {
    intptr_t num_sections = 0;
    for (auto* const command : commands()) {
      if (auto* const s = command->AsMachOSegment()) {
        num_sections += s->NumSections();
      }
    }
    return num_sections;
  }

  // The contents of the header is always at offset/address 0, so the
  // superclass's check returns a false negative here after ComputeOffsets.
  bool HasContents() const override { return true; }
  bool IsAllocated() const override { return type_ != SnapshotType::Object; }
  intptr_t Alignment() const override { return compiler::target::kWordSize; }

  // The header uses the default MemorySize() implementation, because
  // VisitChildren() doesn't visit the load commands and so the header is
  // not considered to contain nested content.
  //
  // This should be used if the size of the header without the load commands
  // is desired.
  intptr_t SizeWithoutLoadCommands() const {
    const intptr_t size = sizeof(HeaderType);
    ASSERT(Utils::IsAligned(size, MachOCommand::kLoadCommandAlignment));
    return size;
  }

  intptr_t SelfMemorySize() const override {
    if (!IsAllocated()) return 0;
    return SelfFileSize();
  }

  intptr_t SelfFileSize() const override {
    intptr_t size = SizeWithoutLoadCommands();
    for (auto* const command : commands_) {
      size += command->cmdsize();
    }
    return size;
  }

  intptr_t FileSize() const override { return SelfFileSize(); }

  uint32_t filetype() const {
    switch (type_) {
      case SnapshotType::Snapshot:
        return mach_o::MH_DYLIB;
      case SnapshotType::DebugInfo:
        return mach_o::MH_DSYM;
      case SnapshotType::Object:
        return mach_o::MH_OBJECT;
      default:
        UNREACHABLE();
        return 0;
    }
  }

  uint32_t flags() const {
    if (type_ == SnapshotType::Snapshot) {
      return mach_o::MH_NOUNDEFS | mach_o::MH_DYLDLINK |
             mach_o::MH_NO_REEXPORTED_DYLIBS;
    }
    ASSERT(type_ == SnapshotType::DebugInfo || type_ == SnapshotType::Object);
    return 0;
  }

  mach_o::cpu_type_t cpu_type() const {
#if defined(TARGET_ARCH_X64)
    return mach_o::CPU_TYPE_X86_64;
#elif defined(TARGET_ARCH_ARM64)
    return mach_o::CPU_TYPE_ARM64;
#elif defined(TARGET_ARCH_IA32)
    return mach_o::CPU_TYPE_I386;
#elif defined(TARGET_ARCH_ARM)
    return mach_o::CPU_TYPE_ARM;
#else
    // This architecture doesn't have specific constants defined in
    // <mach/machine.h>, so just mark it as ANY since the snapshot
    // header check also catches architecture mismatches.
    return mach_o::CPU_TYPE_ANY;
#endif
  }

  mach_o::cpu_subtype_t cpu_subtype() const {
#if defined(TARGET_ARCH_X64)
    return mach_o::CPU_SUBTYPE_X86_64_ALL;
#elif defined(TARGET_ARCH_ARM64)
    return mach_o::CPU_SUBTYPE_ARM64_ALL;
#elif defined(TARGET_ARCH_IA32)
    return mach_o::CPU_SUBTYPE_I386_ALL;
#elif defined(TARGET_ARCH_ARM)
    return mach_o::CPU_SUBTYPE_ARM_ALL;
#else
    // This architecture doesn't have specific constants defined in
    // <mach/machine.h>, so just mark it as ANY since the snapshot
    // header check also catches architecture mismatches.
    return mach_o::CPU_SUBTYPE_ANY;
#endif
  }

  void WriteSelf(MachOWriteStream* stream) const override {
    intptr_t start = stream->Position();
    ASSERT_EQUAL(start, 0);
#if defined(TARGET_ARCH_IS_32_BIT)
    stream->Write32(mach_o::MH_MAGIC);
#else
    stream->Write32(mach_o::MH_MAGIC_64);
#endif
    stream->Write32(cpu_type());
    stream->Write32(cpu_subtype());
    stream->Write32(filetype());
    stream->Write32(commands_.length());
    uint32_t sizeofcmds = 0;
    for (auto* const command : commands_) {
      sizeofcmds += command->cmdsize();
    }
    stream->Write32(sizeofcmds);
    stream->Write32(flags());
#if !defined(TARGET_ARCH_IS_32_BIT)
    stream->Write32(0);  // Reserved field.
#endif
    ASSERT_EQUAL(stream->Position() - start, sizeof(HeaderType));
    for (auto* const command : commands_) {
      const intptr_t load_start = stream->Position();
      ASSERT_EQUAL(load_start, start + command->header_offset());
      command->WriteLoadCommand(stream);
      ASSERT_EQUAL(stream->Position() - load_start,
                   static_cast<intptr_t>(command->cmdsize()));
    }
  }

  // Returns the command with the given concrete subclass of MachOCommand
  // (that is, a subclass that defines a kCommandCode constant). Should only
  // be used for commands that appear at most once (e.g., not segments).
  template <typename T>
  T* FindCommand() const {
    return reinterpret_cast<T*>(FindCommand(T::kCommandCode));
  }

  // Returns the command with the given command code. Should only be used
  // for commands that appear at most once (e.g., not segments).
  MachOCommand* FindCommand(uint32_t cmd) const {
    MachOCommand* result = nullptr;
    for (auto* const command : commands_) {
      if (command->cmd() == cmd) {
        ASSERT(result == nullptr);
        result = command;
#if !defined(DEBUG)
        break;  // No checking, so don't continue iterating.
#endif
      }
    }
    return result;
  }

  // Returns whether there is a command has the given command code.
  bool HasCommand(uint32_t cmd) const {
    for (auto* const command : commands_) {
      if (command->cmd() == cmd) return true;
    }
    return false;
  }

  // Returns the segment with name [name] or nullptr if there is none.
  MachOSegment* FindSegment(const char* name) const {
    for (auto* const command : commands_) {
      if (auto* const s = command->AsMachOSegment()) {
        if (s->HasName(name)) return s;
      }
    }
    return nullptr;
  }

  // Returns the section with name [sectname] in segment [segname]
  // or nullptr if there is none.
  MachOSection* FindSection(const char* segname, const char* sectname) const {
    // All sections are in the unnamed segment for object files.
    auto* const segment =
        type_ == SnapshotType::Object ? text_segment_ : FindSegment(segname);
    if (segment == nullptr) return nullptr;
    return segment->FindSection(sectname, segname);
  }

  MachOSegment* EnsureTextSegment() {
    if (text_segment_ == nullptr) {
      // For relocatable objects, all sections are put into a single unnamed
      // segment.
      auto* const name = type_ == SnapshotType::Object ? mach_o::SEG_UNNAMED
                                                       : mach_o::SEG_TEXT;
      // Make sure it didn't get added outside this method.
      ASSERT(FindSegment(name) == nullptr);
      auto const vm_protection =
          type_ == SnapshotType::Object
              ? mach_o::VM_PROT_ALL
              : mach_o::VM_PROT_READ | mach_o::VM_PROT_EXECUTE;
      text_segment_ =
          new (zone()) MachOSegment(zone(), name, vm_protection, vm_protection);
      commands_.Add(text_segment_);
    }
    return text_segment_;
  }

  void Finalize();

  void Accept(Visitor* visitor) override { visitor->VisitMachOHeader(this); }

  // Since the header is in the initial segment for most snapshot types,
  // visiting the load commands here and also visiting the header in
  // MachOSegment::VisitChildren() would cause a cycle if, say, Default()
  // is overridden to be recursive. Thus, the default VisitChildren
  // implementation here does no recursion.
  void VisitChildren(Visitor* visitor) override {}
  void VisitContents(Visitor* visitor) {
    if (type_ == SnapshotType::Object) {
      // The header is visited during the initial segment for other types.
      Accept(visitor);
    }
    for (auto* const c : commands_) {
      if (type_ != SnapshotType::Object) {
        // All commands with non-header content should be part of a segment.
        if (!c->IsMachOSegment()) continue;
      }
      c->Accept(visitor);
    }
  }

  // Returns the symbol table that is included in the output, which
  // may or may not be the full symbol table.
  //
  // Returns nullptr if called before symbol table initialization.
  const MachOSymbolTable* IncludedSymbolTable() const {
    return const_cast<MachOHeader*>(this)->IncludedSymbolTable();
  }

 private:
  void GenerateUuid();
  void CreateBSS();
  void GenerateUnwindingInformation();
  void GenerateMiscellaneousCommands();
  void InitializeSymbolTables();
  void FinalizeDwarfSections();
  void FinalizeCommands();
  void ComputeOffsets();

#if defined(DART_TARGET_OS_MACOS) && defined(TARGET_ARCH_ARM64)
  void GenerateCompactUnwindingInformation(
      DwarfSharedObjectStream& stream,
      const GrowableArray<Dwarf::FrameDescriptionEntry>& fdes);
#endif

  // Returns the symbol table that is included in the output, which
  // may or may not be the full symbol table.
  //
  // Returns nullptr if called before symbol table initialization.
  MachOSymbolTable* IncludedSymbolTable() {
    // True when the symbol tables haven't been initialized.
    if (full_symtab_.symbols().is_empty()) return nullptr;
    // The full symbol table is reused for unstripped contents.
    if (!is_stripped_) return &full_symtab_;
    return FindCommand<MachOSymbolTable>();
  }

  Zone* const zone_;
  const SnapshotType type_;
  // Used to determine whether to include non-global symbols in the
  // symbol table written to disk.
  bool const is_stripped_;
  // Whether this is a snapshot that has an associated relocatable object
  // emitted.
  bool const has_separate_object_;
  // The identifier, used in the LC_ID_DYLIB command and the code signature.
  const char* const identifier_;
  // The absolute path, used to create an N_OSO symbolic debugging variable
  // in unstripped snapshots.
  const char* const path_;
  Dwarf* const dwarf_;
  GrowableArray<MachOCommand*> commands_;
  // Contains all symbols for relocation calculations.
  MachOSymbolTable full_symtab_;
  // For relocatable objects, the "text" segment is the unnamed segment that
  // holds all sections. Otherwise, it is the text segment as expected.
  MachOSegment* text_segment_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(MachOHeader);
};

void MachOSegment::AddContents(MachOContents* c) {
  ASSERT(c != nullptr);
  // Segment contents are always allocated.
  ASSERT(c->IsAllocated());
  // Only sections should be added to the unnamed segment.
  ASSERT(!HasName(mach_o::SEG_UNNAMED) || c->IsMachOSection());
  // The order of segment contents is as follows:
  // 1) The header (if this is the initial segment).
  // 2) Content-containing sections and commands (in the linkedit segment).
  // 3) Sections without contents like zerofill sections.
  if (c->IsMachOHeader()) {
    ASSERT(c->AsMachOHeader()->commands()[0] == this);
    contents_.InsertAt(0, c);
    next_contents_index_ += 1;
  } else if (c->HasContents()) {
    ASSERT_EQUAL(c->IsMachOCommand(), HasName(mach_o::SEG_LINKEDIT));
    contents_.InsertAt(next_contents_index_, c);
    next_contents_index_ += 1;
  } else {
    ASSERT(c->IsMachOSection());
    contents_.Add(c);
  }
}

bool MachOWriteStream::HasValueForLabel(intptr_t label, intptr_t* value) const {
  ASSERT(value != nullptr);
  const auto& header = macho_.header();
  if (label == SharedObjectWriter::kBuildIdLabel) {
    // Unlike ELF, the uuid is not in a MachO section and so can't have a symbol
    // assigned. Instead, we look up its load command offset in the header.
    auto* const uuid = header.FindCommand<MachOUuid>();
    if (uuid == nullptr) return false;
    *value = header.file_offset() + uuid->header_offset();
    return true;
  }
  const auto& symtab = header.relocation_symbol_table();
  auto* const symbol = symtab.FindLabel(label);
  if (symbol == nullptr) return false;
  *value = symbol->value();
  return true;
}

const MachOSegment& MachOWriteStream::TextSegment() const {
  return macho_.header().text_segment();
}

MachOWriter::MachOWriter(Zone* zone,
                         BaseWriteStream* stream,
                         Type type,
                         const char* id,
                         const char* path,
                         Dwarf* dwarf,
                         MachOWriter* object_writer)
    : SharedObjectWriter(zone, stream, type, dwarf),
      object_writer_(object_writer),
      header_(*new (zone) MachOHeader(
          zone,
          type,
          IsStripped(dwarf),
          type == SharedObjectWriter::Type::Snapshot &&
              object_writer != nullptr,
          FLAG_macho_install_name != nullptr ? FLAG_macho_install_name : id,
          path,
          dwarf)) {
  ASSERT(type == Type::Snapshot || object_writer == nullptr);
}

void MachOWriter::AddText(const char* name,
                          intptr_t label,
                          const uint8_t* bytes,
                          intptr_t size,
                          const ZoneGrowableArray<Relocation>* relocations,
                          const ZoneGrowableArray<SymbolData>* symbols) {
  auto* const text_segment = header_.EnsureTextSegment();
  auto* text_section =
      text_segment->FindSection(mach_o::SECT_TEXT, mach_o::SEG_TEXT);
  if (text_section == nullptr) {
    const bool has_contents = type_ != Type::DebugInfo;
    const intptr_t attributes =
        mach_o::S_ATTR_PURE_INSTRUCTIONS | mach_o::S_ATTR_SOME_INSTRUCTIONS;
    text_section = new (zone()) MachOSection(
        zone(), mach_o::SECT_TEXT, mach_o::SEG_TEXT, text_segment->Alignment(),
        mach_o::S_REGULAR, attributes, has_contents);
    text_segment->AddContents(text_section);
  }
  text_section->AddPortion(bytes, size, relocations, symbols, name, label);
  if (object_writer_ != nullptr) {
    object_writer_->AddText(name, label, bytes, size, relocations, symbols);
  }
}

void MachOWriter::AddROData(const char* name,
                            intptr_t label,
                            const uint8_t* bytes,
                            intptr_t size,
                            const ZoneGrowableArray<Relocation>* relocations,
                            const ZoneGrowableArray<SymbolData>* symbols) {
  // Const data goes in the text segment, not the data one.
  auto* const text_segment = header_.EnsureTextSegment();
  auto* const_section =
      text_segment->FindSection(mach_o::SECT_CONST, mach_o::SEG_TEXT);
  if (const_section == nullptr) {
    const bool has_contents = type_ != Type::DebugInfo;
    const_section = new (zone()) MachOSection(
        zone(), mach_o::SECT_CONST, mach_o::SEG_TEXT, text_segment->Alignment(),
        mach_o::S_REGULAR, mach_o::S_NO_ATTRIBUTES, has_contents);
    text_segment->AddContents(const_section);
  }
  const_section->AddPortion(bytes, size, relocations, symbols, name, label);
  if (object_writer_ != nullptr) {
    object_writer_->AddROData(name, label, bytes, size, relocations, symbols);
  }
}

class WriteVisitor : public MachOContents::Visitor {
 public:
  explicit WriteVisitor(MachOWriteStream* stream) : stream_(stream) {}

  void Default(MachOContents* contents) override {
    if (!contents->HasContents()) return;
    stream_->Align(contents->Alignment());
    const intptr_t start = stream_->Position();
    ASSERT_EQUAL(start, contents->file_offset());
    contents->WriteSelf(stream_);
    ASSERT_EQUAL(stream_->Position() - start, contents->SelfFileSize());
    contents->VisitChildren(this);
    // Segments include post-nested content alignment.
    if (auto* const s = contents->AsMachOSegment()) {
      if (s->PadFileSizeToAlignment()) {
        stream_->Align(contents->Alignment());
      }
    }
    ASSERT_EQUAL(stream_->Position() - start, contents->FileSize());
  }

 private:
  MachOWriteStream* stream_;
  DISALLOW_COPY_AND_ASSIGN(WriteVisitor);
};

class WriteRelocationsVisitor : public MachOContents::Visitor {
 public:
  explicit WriteRelocationsVisitor(MachOWriteStream* stream)
      : stream_(stream) {}

  void Default(MachOContents* contents) override {}

  void VisitMachOSegment(MachOSegment* segment) override {
    segment->VisitChildren(this);
  }

  void VisitMachOSection(MachOSection* section) override {
    if (auto* const relocations = section->relocations()) {
      ASSERT_EQUAL(stream_->Position(), section->relocations_file_offset());
      for (const auto& reloc : *relocations) {
        stream_->Write32(reloc.address);
        stream_->Write32(reloc.metadata);
      }
    } else {
      ASSERT_EQUAL(section->relocations_file_offset(), 0);
    }
  }

 private:
  MachOWriteStream* stream_;
  DISALLOW_COPY_AND_ASSIGN(WriteRelocationsVisitor);
};

void MachOWriter::Finalize() {
  header_.Finalize();
  if (header_.HasCommand(MachOCodeSignature::kCommandCode)) {
    HashingMachOWriteStream wrapped(zone_, unwrapped_stream_, *this);
    WriteVisitor visitor(&wrapped);
    header_.VisitContents(&visitor);
    // Relocatable objects aren't signed, so no relocations to write.
  } else {
    NonHashingMachOWriteStream wrapped(unwrapped_stream_, *this);
    WriteVisitor visitor(&wrapped);
    header_.VisitContents(&visitor);
    if (type_ == SharedObjectWriter::Type::Object) {
      WriteRelocationsVisitor reloc_visitor(&wrapped);
      header_.VisitContents(&reloc_visitor);
    }
  }
  if (object_writer_ != nullptr) {
    object_writer_->Finalize();
  }
}

void MachOWriter::AssertConsistency(const SharedObjectWriter* debug) const {
  if (FLAG_macho_reduce_padding) {
    // TODO(sstrickl): This currently fails because the reduced padding
    // and difference in header sizes means the virtual addresses won't
    // align (though symbolicizing the symbol+offset (PCOffset) information
    // in traces still gives appropriately matching information).
    //
    // However, the only usecase for this reduced padding creates a .dSYM
    // for symbolization instead of using the separate debug info, so
    // ignore this mismatch for now.
    return;
  }
  if (auto* const debug_macho = debug->AsMachOWriter()) {
    AssertConsistency(this, debug_macho);
  } else {
    FATAL("Expected both snapshot and debug to be MachO");
  }
}

void MachOHeader::Finalize() {
  // Generate the UUID now that we have all user-provided sections.
  GenerateUuid();

  // We add a BSS section for all Mach-O output with text sections, even in
  // the separate debugging information, to ensure that relocated addresses
  // are consistent between snapshots and the corresponding separate
  // debugging information.
  CreateBSS();

  FinalizeDwarfSections();

  // Generate miscellenous load commands needed for the final output.
  GenerateMiscellaneousCommands();

  // Generate appropriate unwinding information for the target platform,
  // for example, unwinding records on Windows.
  GenerateUnwindingInformation();

  // Initialize both the static and dynamic symbol tables. Calls to methods
  // that change section numbering (by either adding or reordering sections
  // and/or segments) after this point must update the section numbers on
  // section symbols to match.
  InitializeSymbolTables();

  // Reorders the added commands as well as adding segments and commands
  // that must appear at the end of the file.
  FinalizeCommands();

  // Calculate file and memory offsets, and finalizes symbol values in any
  // symbol tables.
  ComputeOffsets();
}

void MachOWriter::AssertConsistency(const MachOWriter* snapshot,
                                    const MachOWriter* debug_info) {
#if defined(DEBUG)
  // For now, just check that the symbol information for both match
  // in that all labelled symbols used for relocation have the same
  // value.
  const auto& snapshot_symtab = snapshot->header().relocation_symbol_table();
  const auto& debug_info_symtab =
      debug_info->header().relocation_symbol_table();

  intptr_t max_label = snapshot_symtab.max_label();
  ASSERT_EQUAL(max_label, debug_info_symtab.max_label());
  for (intptr_t i = 1; i < max_label; ++i) {
    if (auto* const snapshot_symbol = snapshot_symtab.FindLabel(i)) {
      auto* const debug_info_symbol = debug_info_symtab.FindLabel(i);
      ASSERT(debug_info_symbol != nullptr);
      if (snapshot_symbol->value() != debug_info_symbol->value()) {
        FATAL("Snapshot: %s -> %" Px64 ", %s -> %" Px64 "",
              snapshot_symtab.strings().At(snapshot_symbol->name_index),
              static_cast<uint64_t>(snapshot_symbol->value()),
              debug_info_symtab.strings().At(debug_info_symbol->name_index),
              static_cast<uint64_t>(debug_info_symbol->value()));
      }
    } else {
      ASSERT(debug_info_symtab.FindLabel(i) == nullptr);
    }
  }
#endif
}

static uint32_t HashPortion(const MachOSection::Portion& portion) {
  if (portion.bytes == nullptr) return 0;
  const uint32_t hash = Utils::StringHash(portion.bytes, portion.size);
  // Ensure a non-zero return.
  return hash == 0 ? 1 : hash;
}

// For the UUID, we generate a 128-bit hash, where each 32 bits is a
// hash of the contents of the following segments in order:
//
// .text(VM) | .text(Isolate) | .rodata(VM) | .rodata(Isolate)
//
// Any component of the build ID which does not have an associated section
// in the output is kept as 0.
void MachOHeader::GenerateUuid() {
  // Don't create a UUID for a relocatable object.
  if (type_ == SnapshotType::Object) return;
  // Not idempotent.
  ASSERT(!HasCommand(MachOUuid::kCommandCode));
  // Currently, we construct the UUID out of data from two different
  // sections in the text segment: the text section and the const section.
  if (text_segment_ == nullptr) return;

  auto* const text_section =
      text_segment_->FindSection(mach_o::SECT_TEXT, mach_o::SEG_TEXT);
  // If there is no text section, then a UUID is not needed, as it is only
  // used to symbolicize non-symbolic stack traces.
  if (text_section == nullptr) return;

  auto* const vm_instructions =
      text_section->FindPortion(kVmSnapshotInstructionsAsmSymbol);
  auto* const isolate_instructions =
      text_section->FindPortion(kIsolateSnapshotInstructionsAsmSymbol);
  // All MachO snapshots have at least one of the two instruction sections.
  ASSERT(vm_instructions != nullptr || isolate_instructions != nullptr);

  auto* const data_section =
      text_segment_->FindSection(mach_o::SECT_CONST, mach_o::SEG_TEXT);
  auto* const vm_data =
      data_section == nullptr
          ? nullptr
          : data_section->FindPortion(kVmSnapshotDataAsmSymbol);
  auto* const isolate_data =
      data_section == nullptr
          ? nullptr
          : data_section->FindPortion(kIsolateSnapshotDataAsmSymbol);

  uint32_t hashes[4];
  hashes[0] = vm_instructions == nullptr ? 0 : HashPortion(*vm_instructions);
  hashes[1] =
      isolate_instructions == nullptr ? 0 : HashPortion(*isolate_instructions);
  hashes[2] = vm_data == nullptr ? 0 : HashPortion(*vm_data);
  hashes[3] = isolate_data == nullptr ? 0 : HashPortion(*isolate_data);

  auto* const uuid_command = new (zone()) MachOUuid(hashes, sizeof(hashes));
  commands_.Add(uuid_command);
}

void MachOHeader::CreateBSS() {
  // No text section means no BSS section.
  auto* const text_section = FindSection(mach_o::SEG_TEXT, mach_o::SECT_TEXT);
  ASSERT(text_section != nullptr);

  // Not idempotent.
  ASSERT(FindSection(mach_o::SECT_BSS, mach_o::SEG_DATA) == nullptr);
  MachOSegment* data_segment = nullptr;
  if (type_ == SnapshotType::Object) {
    // The "text" segment in a relocatable object is the unnamed segment
    // that contains all sections.
    data_segment = EnsureTextSegment();
    ASSERT(data_segment->HasName(mach_o::SEG_UNNAMED));
  } else {
    // Currently the data segment only contains BSS data, so it
    // shouldn't already exist.
    ASSERT(FindSegment(mach_o::SEG_DATA) == nullptr);
    auto const vm_protection = mach_o::VM_PROT_READ | mach_o::VM_PROT_WRITE;
    data_segment = new (zone())
        MachOSegment(zone(), mach_o::SEG_DATA, vm_protection, vm_protection);
    commands_.Add(data_segment);
  }

  auto* const bss_section = new (zone()) MachOSection(
      zone(), mach_o::SECT_BSS, mach_o::SEG_DATA,
      /*alignment=*/compiler::target::kWordSize, mach_o::S_ZEROFILL,
      mach_o::S_NO_ATTRIBUTES, /*has_contents=*/false);
  data_segment->AddContents(bss_section);

  for (const auto& portion : text_section->portions()) {
    size_t size;
    const char* symbol_name;
    intptr_t label;
    // First determine whether this is the VM's text portion or the isolate's.
    if (strcmp(portion.symbol_name, kVmSnapshotInstructionsAsmSymbol) == 0) {
      size = BSS::kVmEntryCount * compiler::target::kWordSize;
      symbol_name = kVmSnapshotBssAsmSymbol;
      label = SharedObjectWriter::kVmBssLabel;
    } else if (strcmp(portion.symbol_name,
                      kIsolateSnapshotInstructionsAsmSymbol) == 0) {
      size = BSS::kIsolateGroupEntryCount * compiler::target::kWordSize;
      symbol_name = kIsolateSnapshotBssAsmSymbol;
      label = SharedObjectWriter::kIsolateBssLabel;
    } else {
      // Not VM or isolate text.
      UNREACHABLE();
    }

    // For the BSS section, we add the section symbols as local symbols in the
    // static symbol table, as these addresses are only used for relocation.
    // (This matches the behavior in the assembly output.)
    auto* symbols = new (zone_) SharedObjectWriter::SymbolDataArray(zone_, 1);
    symbols->Add({symbol_name, SharedObjectWriter::SymbolData::Type::Section, 0,
                  size, label});
    bss_section->AddPortion(/*bytes=*/nullptr, size, /*relocations=*/nullptr,
                            symbols);
  }
}

#if defined(DART_TARGET_OS_MACOS) && defined(TARGET_ARCH_ARM64)
void MachOHeader::GenerateCompactUnwindingInformation(
    DwarfSharedObjectStream& stream,
    const GrowableArray<Dwarf::FrameDescriptionEntry>& fdes) {
  // Each instructions image starts with the Image header and the
  // InstructionsSection header.
  const intptr_t header_size =
      Image::kHeaderSize + compiler::target::InstructionsSection::HeaderSize();

  if (type_ == SnapshotType::Object) {
    // In relocatable objects, the compact unwind information is written
    // differently. In this case, it's just a flat table with entries of
    // the following format:
    //   start                (word-sized)
    //   length               (32 bits)
    //   encoding             (32 bits)
    //   personality-function (word-sized, 0 if none)
    //   ldsa                 (word-sized, 0 if none)
    for (intptr_t i = 0, n = fdes.length(); i < n; i++) {
      const auto& fde = fdes[i];
      // The payload of the InstructionsSection.
      stream.OffsetFromSymbol(fde.label, header_size);
      stream.u4(fde.size);
      stream.u4(mach_o::UNWIND_INFO_ENCODING_ARM64_MODE_FRAME);
#if defined(TARGET_ARCH_IS_32_BIT)
      stream.u4(0);  // Personality function
      stream.u4(0);  // LDSA
#else
      stream.u8(0);  // Personality function
      stream.u8(0);  // LDSA
#endif
    }
    return;
  }

  // Since we currently generate only regular second level pages, there's
  // no need for common encodings as those are only used by compressed
  // second level pages.
  const intptr_t common_encodings_offset = sizeof(mach_o::unwind_info_header);
  GrowableArray<uint32_t> common_encodings(zone(), 0);

  const intptr_t personalities_offset =
      common_encodings_offset + common_encodings.length() * kInt32Size;
  GrowableArray<uint32_t> personalities(zone(), 0);

  // For N FDEs, we generate 2N entries:
  // * One at the start of the text section with the none encoding.
  // * One at the start of each FDE's InstructionsSection payload with
  //   the frame encoding.
  // * For all but the last FDE, one at the end of the InstructionsSection
  //   payload with the none encoding.
  // No entry is needed for the end of the last FDE, since it is
  // already recorded as the end of the instructions in the first
  // page index sentinel entry.
  const intptr_t second_level_page_entry_count = 2 * fdes.length();
  const bool second_level_pages_count =
      (second_level_page_entry_count +
       (mach_o::UNWIND_INFO_REGULAR_SECOND_LEVEL_PAGE_MAX_ENTRIES - 1)) /
      mach_o::UNWIND_INFO_REGULAR_SECOND_LEVEL_PAGE_MAX_ENTRIES;

  const intptr_t first_level_page_indices_offset =
      personalities_offset + personalities.length() * kInt32Size;
  // There is one first level page index per second level page, plus an
  // additional first level page index that serves as as a sentinel and
  // contains the ending offset of the LSDA entries.
  const intptr_t first_level_page_indices_count = second_level_pages_count + 1;

  // Align the LSDA indices to the target word size, as the first level page
  // indices are 12 bytes long and so may not end on a word boundary
  // on 64-bit systems.
  const intptr_t lsda_indices_offset =
      Utils::RoundUp(first_level_page_indices_offset +
                         first_level_page_indices_count *
                             sizeof(mach_o::unwind_info_first_level_page_index),
                     compiler::target::kWordSize);
  GrowableArray<mach_o::unwind_info_lsda_index> lsda_indices(zone(), 0);

  const intptr_t second_level_pages_offset =
      lsda_indices_offset +
      lsda_indices.length() * sizeof(mach_o::unwind_info_lsda_index);
  // We should only generate at most 2 FDEs and thus 4 entries, so there
  // should only be one second level page that, if placed right after
  // the other content, is wholly contained in a 4 * KB page.
  ASSERT_EQUAL(1, second_level_pages_count);
  const intptr_t second_level_pages_size =
      mach_o::UnwindInfoRegularSecondLevelPageSize(
          second_level_page_entry_count);
  const intptr_t unwind_info_size =
      second_level_pages_offset + second_level_pages_size;
  ASSERT(static_cast<size_t>(unwind_info_size) <=
         mach_o::UNWIND_INFO_SECOND_LEVEL_PAGE_MAX_SIZE);

  stream.u4(mach_o::UNWIND_INFO_VERSION);
  stream.u4(common_encodings_offset);
  stream.u4(common_encodings.length());
  stream.u4(personalities_offset);
  stream.u4(personalities.length());
  stream.u4(first_level_page_indices_offset);
  stream.u4(first_level_page_indices_count);

  ASSERT_EQUAL(common_encodings_offset, stream.Position());
  for (const auto& encoding : common_encodings) {
    stream.u4(encoding);
  }

  ASSERT_EQUAL(personalities_offset, stream.Position());
  for (const auto& personality : personalities) {
    stream.u4(personality);
  }

  ASSERT_EQUAL(first_level_page_indices_offset, stream.Position());
  ASSERT_EQUAL(2, first_level_page_indices_count);
  const auto& first_fde = fdes[0];
  const auto& last_fde = fdes.Last();
  stream.OffsetFromSymbol(first_fde.label, 0, kInt32Size);
  stream.u4(second_level_pages_offset);
  stream.u4(lsda_indices_offset);
  // Sentinel that includes the end of the function space as the offset
  // and has an LSDA index offset at the end of the LSDA index array.
  stream.OffsetFromSymbol(last_fde.label, last_fde.size, kInt32Size);
  stream.u4(0);  // No second level page.
  stream.u4(lsda_indices_offset +
            lsda_indices.length() * sizeof(mach_o::unwind_info_lsda_index));

  stream.Align(compiler::target::kWordSize);
  ASSERT_EQUAL(lsda_indices_offset, stream.Position());
  for (const auto& lsda_index : lsda_indices) {
    stream.u4(lsda_index.function_offset);
    stream.u4(lsda_index.lsda_offset);
  }

  ASSERT_EQUAL(second_level_pages_offset, stream.Position());
  ASSERT_EQUAL(1, second_level_pages_count);
  stream.u4(mach_o::UNWIND_INFO_REGULAR_SECOND_LEVEL_PAGE);
  stream.u2(sizeof(mach_o::unwind_info_regular_second_level_page_header));
  stream.u2(second_level_page_entry_count);
  // There are no instructions until the first InstructionsSection payload.
  stream.OffsetFromSymbol(fdes[0].label, 0, kInt32Size);
  stream.u4(mach_o::UNWIND_INFO_ENCODING_NONE);
  for (intptr_t i = 0, n = fdes.length(); i < n - 1; i++) {
    const auto& fde = fdes[i];
    // The payload of the InstructionsSection.
    stream.OffsetFromSymbol(fde.label, header_size, kInt32Size);
    stream.u4(mach_o::UNWIND_INFO_ENCODING_ARM64_MODE_FRAME);
    // The padding (if any) between this Image and the next.
    stream.OffsetFromSymbol(fde.label, fde.size, kInt32Size);
    stream.u4(mach_o::UNWIND_INFO_ENCODING_NONE);
  }
  // The payload of the last InstructionsSection.
  stream.OffsetFromSymbol(fdes.Last().label, header_size, kInt32Size);
  stream.u4(mach_o::UNWIND_INFO_ENCODING_ARM64_MODE_FRAME);
  ASSERT_EQUAL(unwind_info_size, stream.Position());
}
#endif

void MachOHeader::GenerateUnwindingInformation() {
#if !defined(TARGET_ARCH_IA32)
  // Unwinding information is added to the text segment in Mach-O files
  // (except for relocatable object files, where the __LD segment name is used).
  // Thus, we need the size of the unwinding information even for debugging
  // information, since adding the unwinding information changes the memory size
  // of the initial text segment and thus changes the values for symbols
  // of sections in later segments.
  //
  // However, since the debugging information should never be loaded by
  // the Mach-O loader, we don't actually need to generate the instructions,
  // just use an appropriate zerofill section for it.
  const bool use_zerofill = type_ == SnapshotType::DebugInfo;
  const intptr_t alignment = compiler::target::kWordSize;
  auto create_unwind_section =
      [&](const char* segname, const char* sectname,
          const ZoneWriteStream& stream,
          const SharedObjectWriter::RelocationArray* relocations = nullptr,
          const SharedObjectWriter::SymbolDataArray* symbols =
              nullptr) -> MachOSection* {
    // Not idempotent.
    ASSERT(FindSection(sectname, segname) == nullptr);
    auto* const section = new (zone())
        MachOSection(zone(), sectname, segname, alignment,
                     use_zerofill ? mach_o::S_ZEROFILL : mach_o::S_REGULAR,
                     mach_o::S_NO_ATTRIBUTES, !use_zerofill);
    section->AddPortion(use_zerofill ? nullptr : stream.buffer(),
                        stream.bytes_written(),
                        use_zerofill ? nullptr : relocations, symbols);
    return section;
  };

  ASSERT(text_segment_ != nullptr);
  if (auto* const text_section =
          text_segment_->FindSection(mach_o::SECT_TEXT, mach_o::SEG_TEXT)) {
    // Generate the DWARF FDEs even for MacOS, because the same information
    // is used to create the compact unwinding info.
    GrowableArray<Dwarf::FrameDescriptionEntry> fdes(zone_, 0);
    for (const auto& portion : text_section->portions()) {
      ASSERT(portion.label != 0);
      fdes.Add({portion.label, portion.size});
    }

    // Even if the unwinding information is not written to the output, it is
    // generated so a zerofill section of the appropriate size can be created.
    ZoneWriteStream stream(zone(), DwarfSharedObjectStream::kInitialBufferSize);
    DwarfSharedObjectStream dwarf_stream(zone(), &stream);

    SharedObjectWriter::SymbolDataArray* symbols = nullptr;
#if defined(DART_TARGET_OS_MACOS) && defined(TARGET_ARCH_ARM64)
    GenerateCompactUnwindingInformation(dwarf_stream, fdes);
    auto* const sectname = type_ == SnapshotType::Object
                               ? mach_o::SECT_COMPACT_UNWIND
                               : mach_o::SECT_UNWIND_INFO;
#else
    Dwarf::WriteCallFrameInformationRecords(&dwarf_stream, fdes);
    auto* const sectname = mach_o::SECT_EH_FRAME;
    if (type_ == SnapshotType::Object) {
      // To add appropriate relocations for the EH_FRAME section, a local symbol
      // must be added since this section includes relocations with
      // kSelfRelative source labels.
      const size_t size = stream.bytes_written();
      symbols = new (zone_) SharedObjectWriter::SymbolDataArray(zone_, 1);
      symbols->Add({"_kDartMachOEhFrameSection",
                    SharedObjectWriter::SymbolData::Type::Section, 0, size,
                    SharedObjectWriter::kMachOEhFrameLabel});
    }
#endif

    auto* const segname =
        type_ == SnapshotType::Object ? mach_o::SEG_LD : mach_o::SEG_TEXT;
    auto* const section = create_unwind_section(
        segname, sectname, stream, dwarf_stream.relocations(), symbols);
    text_segment_->AddContents(section);
  }

#if defined(UNWINDING_RECORDS_WINDOWS_PRECOMPILER)
  // Append Windows unwinding instructions as a __unwind_info section at
  // the end of any executable segments.
  //
  // Don't do this for relocatable objects, because those can't be loaded
  // by the non-native loader and there's no way to link them into a
  // program since Mach-O is not a supported object type on Windows anyway.
  if (type_ != SnapshotType::Object) {
    for (auto* const command : commands_) {
      if (auto* const segment = command->AsMachOSegment()) {
        if (segment->IsExecutable()) {
          // Only more zerofill sections can come after zerofill sections, and
          // the unwinding instructions cover the entire executable segment up
          // to the unwinding instructions including zerofill sections.
          ASSERT(use_zerofill || !segment->HasZerofillSections());
          const intptr_t records_size = UnwindingRecordsPlatform::SizeInBytes();
          ZoneWriteStream stream(zone(), /*initial_size=*/records_size);
          uint8_t* unwinding_instructions =
              zone()->Alloc<uint8_t>(records_size);
          const intptr_t section_start =
              Utils::RoundUp(segment->UnpaddedMemorySize(), alignment);
          stream.WriteBytes(UnwindingRecords::GenerateRecordsInto(
                                section_start, unwinding_instructions),
                            records_size);
          ASSERT_EQUAL(records_size, stream.Position());
          auto* const section = create_unwind_section(
              segment->name(), mach_o::SECT_UNWIND_INFO, stream);
          segment->AddContents(section);
        }
      }
    }
  }
#endif  // defined(DART_TARGET_OS_WINDOWS) && defined(TARGET_ARCH_IS_64_BIT)
#endif  // !defined(TARGET_ARCH_IA32)
}

void MachOHeader::GenerateMiscellaneousCommands() {
  if (type_ == SnapshotType::Snapshot) {
    // Not idempotent;
    ASSERT(!HasCommand(MachOIdDylib::kCommandCode));
    commands_.Add(new (zone_) MachOIdDylib(identifier_));
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
    ASSERT(!HasCommand(MachOLoadDylib::kCommandCode));
    ASSERT(!HasCommand(MachORunPath::kCommandCode));
    commands_.Add(MachOLoadDylib::CreateLoadSystemDylib(zone_));
    if (FLAG_macho_rpath != nullptr) {
      const char* current = FLAG_macho_rpath;
      for (const char* next = current;; next += 1) {
        if (*next == ',' || *next == '\0') {
          commands_.Add(new (zone_) MachORunPath(current, next - current));
          if (*next == '\0') break;
          current = next + 1;
        }
      }
    }
#endif
  }
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
  if (type_ == SnapshotType::Snapshot || type_ == SnapshotType::Object) {
    ASSERT(!HasCommand(MachOBuildVersion::kCommandCode));
    commands_.Add(new (zone_) MachOBuildVersion());
  }
#endif
}

void MachOHeader::InitializeSymbolTables() {
  // Not idempotent.
  ASSERT_EQUAL(full_symtab_.num_symbols(), 0);
  ASSERT(!HasCommand(MachOSymbolTable::kCommandCode));

  // Grab all the sections in order and set their current index.
  GrowableArray<MachOSection*> sections(zone_, 0);
  intptr_t section_index = 1;  // 1-based.
  for (auto* const command : commands_) {
    // Should be run before ComputeOffsets.
    ASSERT(!command->HasContents() || !command->file_offset_is_set());
    if (auto* const s = command->AsMachOSegment()) {
      for (auto* const c : s->contents()) {
        if (auto* const section = c->AsMachOSection()) {
          section->set_index(section_index++);
          sections.Add(section);
        }
      }
    }
  }

  // This symbol table is for the MachOWriter's internal use. All symbols
  // should be added to it so the writer can resolve relocations.
  full_symtab_.Initialize(type_, path_, sections, /*is_stripped=*/false);
  auto* table = &full_symtab_;
  if (is_stripped_) {
    // Create a separate symbol table that is actually written to the output.
    // This one will only contain what's needed for the dynamic symbol table.
    auto* const table = new (zone())
        MachOSymbolTable(zone(), /*in_segment=*/type_ != SnapshotType::Object);
    table->Initialize(type_, path_, sections, is_stripped_);
  }
  commands_.Add(table);

  // For non-debugging information, include a dynamic symbol table as well.
  if (type_ != SnapshotType::DebugInfo) {
    auto* const dynamic_symtab = new (zone()) MachODynamicSymbolTable(
        *table, /*in_segment=*/type_ != SnapshotType::Object);
    commands_.Add(dynamic_symtab);
  }
}

void MachOHeader::FinalizeDwarfSections() {
  if (dwarf_ == nullptr) return;

  if (has_separate_object_) {
    // If there is an associated relocatable object, do not emit the DWARF
    // sections; they'll be emitted in the relocatable object instead.
    ASSERT(type_ == SnapshotType::Snapshot);
    return;
  }

  // Currently we only output DWARF information involving code.
#if defined(DEBUG)
  ASSERT(text_segment_ != nullptr);
  ASSERT(text_segment_->FindSection(mach_o::SECT_TEXT, mach_o::SEG_TEXT) !=
         nullptr);
#endif

  MachOSegment* dwarf_segment = nullptr;
  if (type_ == SnapshotType::Object) {
    // All sections are put into the unnamed segment.
    dwarf_segment = text_segment_;
    ASSERT(dwarf_segment->HasName(mach_o::SEG_UNNAMED));
  } else {
    // Create the DWARF segment, which should not already exist.
    ASSERT(FindSegment(mach_o::SEG_DWARF) == nullptr);
    auto const init_vm_protection =
        mach_o::VM_PROT_READ | mach_o::VM_PROT_WRITE;
    auto const max_vm_protection = init_vm_protection | mach_o::VM_PROT_EXECUTE;
    dwarf_segment = new (zone()) MachOSegment(
        zone(), mach_o::SEG_DWARF, init_vm_protection, max_vm_protection);
    commands_.Add(dwarf_segment);
  }

  const intptr_t alignment = 1;  // No extra padding.
  auto add_debug = [&](const char* name,
                       const DwarfSharedObjectStream& stream) {
    ASSERT(!dwarf_segment->FindSection(name, mach_o::SEG_DWARF));
    auto* const section =
        new (zone()) MachOSection(zone(), name, mach_o::SEG_DWARF, alignment,
                                  mach_o::S_REGULAR, mach_o::S_ATTR_DEBUG);
    section->AddPortion(stream.buffer(), stream.bytes_written(),
                        stream.relocations());
    dwarf_segment->AddContents(section);
  };

  {
    ZoneWriteStream stream(zone(), DwarfSharedObjectStream::kInitialBufferSize);
    DwarfSharedObjectStream dwarf_stream(zone_, &stream);
    dwarf_->WriteAbbreviations(&dwarf_stream);
    add_debug(mach_o::SECT_DEBUG_ABBREV, dwarf_stream);
  }

  {
    ZoneWriteStream stream(zone(), DwarfSharedObjectStream::kInitialBufferSize);
    DwarfSharedObjectStream dwarf_stream(zone_, &stream);
    dwarf_->WriteDebugInfo(&dwarf_stream);
    add_debug(mach_o::SECT_DEBUG_INFO, dwarf_stream);
  }

  {
    ZoneWriteStream stream(zone(), DwarfSharedObjectStream::kInitialBufferSize);
    DwarfSharedObjectStream dwarf_stream(zone_, &stream);
    dwarf_->WriteLineNumberProgram(&dwarf_stream);
    add_debug(mach_o::SECT_DEBUG_LINE, dwarf_stream);
  }
}

void MachOHeader::FinalizeCommands() {
  // Not idempotent.
  ASSERT(FindSegment(mach_o::SEG_LINKEDIT) == nullptr);
  ASSERT(!HasCommand(MachOCodeSignature::kCommandCode));

  intptr_t num_commands = commands_.length();
  // We shouldn't be writing empty Mach-O snapshots.
  ASSERT(num_commands != 0);
  GrowableArray<MachOCommand*> reordered_commands(zone_, num_commands);

  // Now do a single pass over the commands, sorting them into bins based on
  // the desired final ordering and also calculating a map from old section
  // indices in the old order to new section indices in the new order.

  // First, any commands that are only part of the header.
  GrowableArray<MachOCommand*> header_only_commands(zone_, 0);

  // Ensure the text segment is the initial segment. This means the
  // text segment contains the header in its file contents/memory space.
  MachOSegment* text_segment = text_segment_;
  // We should be writing instructions and/or const data.
  ASSERT(text_segment != nullptr);

  // Then all segments that have defined symbols. These segments
  // are present in both snapshots and separate debugging information,
  // and the symbols defined in these sections should have consistent
  // relocated memory addresses in both.
  GrowableArray<MachOSegment*> symbol_segments(zone_, 0);

  // Then all other segments added prior to calling this function.
  // These need to be before the linkedit segment, which is created
  // below, so that they are also protected by the code signature
  // (if there is one).
  GrowableArray<MachOSegment*> other_segments(zone_, 0);

  // Next comes any non-segment load commands that have allocated content
  // outside of the header like the symbol table. For relocatable objects,
  // the contents of these sections are written after the unnamed segment,
  // otherwise a linkedit segment is created later to contain the non-header
  // contents of these commands.
  GrowableArray<MachOCommand*> linkedit_commands(zone_, 0);
  for (auto* const command : commands_) {
    // Check that we're not reordering after offsets have been computed.
    ASSERT(!command->HasContents() || !command->file_offset_is_set());
    if (auto* const s = command->AsMachOSegment()) {
      if (s->HasName(mach_o::SEG_TEXT) || s->HasName(mach_o::SEG_UNNAMED)) {
        ASSERT_EQUAL(type_ == SnapshotType::Object,
                     s->HasName(mach_o::SEG_UNNAMED));
        ASSERT(text_segment == s);
      } else if (s->ContainsSymbols()) {
        symbol_segments.Add(s);
      } else {
        other_segments.Add(s);
      }
    } else if (type_ == SnapshotType::Object || command->HasContents()) {
      // Stick every non-segment into linkedit_commands so that the segment
      // load command is first in a relocatable object.
      linkedit_commands.Add(command);
    } else {
      header_only_commands.Add(command);
    }
  }

  // We should always have a symbol table, even in stripped files where
  // it only contains global exported symbols, which means there should
  // be a linkedit segment.
  ASSERT(!linkedit_commands.is_empty());
  MachOSegment* linkedit_segment = nullptr;
  if (type_ != SnapshotType::Object) {
    linkedit_segment = new (zone_) MachOSegment(zone_, mach_o::SEG_LINKEDIT);
    num_commands += 1;
    for (auto* const c : linkedit_commands) {
      linkedit_segment->AddContents(c);
    }
    if (type_ == SnapshotType::Snapshot && FLAG_macho_linker_signature) {
      // Also include an embedded ad-hoc linker signed code signature as the
      // last contents of the linkedit segment (which is the last segment).
      auto* const signature = new (zone_) MachOCodeSignature(identifier_);
      linkedit_segment->AddContents(signature);
      linkedit_commands.Add(signature);
      num_commands += 1;
    }
  }

  GrowableArray<MachOSegment*> segments(
      zone_, symbol_segments.length() + other_segments.length() + 2);
  // Put the text, data, and linkedit segments in the expected ordering.
  segments.Add(text_segment);
  segments.AddArray(symbol_segments);
  segments.AddArray(other_segments);
  if (type_ != SnapshotType::Object) {
    segments.Add(linkedit_segment);
  }

  if (type_ != SnapshotType::Object) {
    // The initial segment in the file should have the header as its initial
    // contents. Since the header is not a section, this won't change the
    // section numbering.
    segments[0]->AddContents(this);
  }

  // Now populate reordered_commands.
  reordered_commands.AddArray(header_only_commands);

  // While adding segments, also re-index sections.
  intptr_t current_section_index = 1;  // 1-based.
  for (auto* const segment : segments) {
    reordered_commands.Add(segment);
    for (auto* const c : segment->contents()) {
      if (auto* const s = c->AsMachOSection()) {
        ASSERT(current_section_index != mach_o::NO_SECT);
        s->set_index(current_section_index++);
      }
    }
  }
  reordered_commands.AddArray(linkedit_commands);

  // All sections should have been accounted for in the loops above as well as
  // the new linkedit segment (and, if applicable, the code signature).
  ASSERT_EQUAL(reordered_commands.length(), num_commands);
  // Replace the content of commands_ with the reordered commands.
  commands_.Clear();
  commands_.AddArray(reordered_commands);
}

struct ContentOffsetsVisitor : public MachOContents::Visitor {
  explicit ContentOffsetsVisitor(Zone* zone) {}

  void Default(MachOContents* contents) {
    ASSERT_EQUAL(contents->IsMachOHeader(), file_offset == 0);
    // This can't be strictly equal, because the header is not in a segment
    // in relocatable objects and thus is not allocated, so the first
    // allocated contents (a section) will have a memory offset of 0.
    ASSERT(!contents->IsMachOHeader() || memory_address == 0);
    // Increment the file and memory offsets by the appropriate amounts.
    if (contents->HasContents()) {
      file_offset = Utils::RoundUp(file_offset, contents->Alignment());
      contents->set_file_offset(file_offset);
      file_offset += contents->SelfFileSize();
    }
    if (contents->IsAllocated()) {
      memory_address = Utils::RoundUp(memory_address, contents->Alignment());
      contents->set_memory_address(memory_address);
      memory_address += contents->SelfMemorySize();
    }
    contents->VisitChildren(this);
    if (contents->HasContents()) {
      ASSERT_EQUAL(file_offset, contents->file_offset() + contents->FileSize());
    }
    if (contents->IsAllocated()) {
      ASSERT_EQUAL(memory_address,
                   contents->memory_address() + contents->MemorySize());
    }
  }

  void VisitMachOSegment(MachOSegment* segment) {
    ASSERT_EQUAL(segment->IsInitial(), file_offset == 0);
    ASSERT_EQUAL(segment->IsInitial() || segment->HasName(mach_o::SEG_UNNAMED),
                 memory_address == 0);
    // Segments are always allocated and we set the file offset even
    // when the segment doesn't actually write any contents.
    file_offset = Utils::RoundUp(file_offset, segment->Alignment());
    segment->set_file_offset(file_offset);
    file_offset += segment->SelfFileSize();
    memory_address = Utils::RoundUp(memory_address, segment->Alignment());
    segment->set_memory_address(memory_address);
    memory_address += segment->SelfMemorySize();
    segment->VisitChildren(this);
    if (segment->PadFileSizeToAlignment()) {
      file_offset = Utils::RoundUp(file_offset, segment->Alignment());
    }
    memory_address = Utils::RoundUp(memory_address, segment->Alignment());
    ASSERT_EQUAL(file_offset, segment->file_offset() + segment->FileSize());
    ASSERT_EQUAL(memory_address,
                 segment->memory_address() + segment->MemorySize());
  }

  intptr_t file_offset = 0;
  intptr_t memory_address = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(ContentOffsetsVisitor);
};

class RelocationsConverter : public MachOContents::Visitor {
  using SnapshotType = SharedObjectWriter::Type;
  using Relocation = SharedObjectWriter::Relocation;

 public:
  explicit RelocationsConverter(Zone* zone,
                                const MachOHeader& header,
                                intptr_t start)
      : zone_(zone),
        output_is_relocatable_object_(header.type() == SnapshotType::Object),
        symbol_table_(*ASSERT_NOTNULL(header.IncludedSymbolTable())),
        file_offset_(Utils::RoundUp(start, compiler::target::kWordSize)),
        portion_and_section_by_label_(zone) {
    for (auto* const command : header.commands()) {
      if (auto* const segment = command->AsMachOSegment()) {
        for (auto* const c : segment->contents()) {
          if (auto* const s = c->AsMachOSection()) {
            for (const auto& p : s->portions()) {
              portion_and_section_by_label_.Insert({p.label, {s, &p}});
            }
          }
        }
      }
    }
  }

  void Default(MachOContents* contents) override {}

  void VisitMachOSegment(MachOSegment* segment) override {
    segment->VisitChildren(this);
  }

  void VisitMachOSection(MachOSection* section) override {
    current_relocations_ = nullptr;
    current_relocation_addends_ = nullptr;
    if (output_is_relocatable_object_) {
      ASSERT(section->file_offset_is_set());
      current_section_ = section;
      for (const auto& p : section->portions()) {
        if (p.relocations == nullptr) continue;
        if (p.symbols != nullptr && !p.symbols->is_empty()) {
          // Local symbols are sorted in order of offset into the portion.
          starting_index_for_self_ =
              symbol_table_.IndexForLabel(p.symbols->At(0).label);
        }
        current_portion_ = &p;
        for (const auto& reloc : *p.relocations) {
          ConvertRelocation(reloc);
        }
        starting_index_for_self_ = -1;
        current_portion_ = nullptr;
      }
      current_section_ = nullptr;
    }
    section->set_relocations(current_relocations_);
    section->set_relocation_addends(current_relocation_addends_);
    section->set_relocations_file_offset(
        current_relocations_ != nullptr ? file_offset_ : 0);
    file_offset_ +=
        section->num_relocations() * sizeof(mach_o::relocation_info);
  }

 private:
  static uint32_t RelocationSize(intptr_t size) {
    switch (size) {
      case 1:
        return mach_o::RELOC_SIZE_BYTE;
      case 2:
        return mach_o::RELOC_SIZE_2BYTES;
      case 4:
        return mach_o::RELOC_SIZE_4BYTES;
      case 8:
        return mach_o::RELOC_SIZE_8BYTES;
      default:
        FATAL("Unexpected relocation size %" Pd "", size);
        return mach_o::RELOC_SIZE_BYTE;
    }
  }

  // Finds the closest symbol to the offset in the given section portion.
  // Starts the search of local symbols in the symbol table from starting_index
  // and updates starting_index if the closest symbol is a local symbol with an
  // appropriate place to start the next search for any portion offsets after
  // the current one.
  intptr_t FindClosestSymbolIndexTo(intptr_t portion_offset,
                                    const MachOSection* section,
                                    const MachOSection::Portion* portion,
                                    intptr_t& starting_index) {
    const uword address =
        section->memory_address() + portion->offset + portion_offset;
    MachOSymbolTable::Symbol* current = nullptr;
    if (starting_index >= 0) {
      current = &symbol_table_.symbols()[starting_index];
      if (current->value() == address) {
        return starting_index;
      } else if (current->value() < address) {
        // Since index is the index of a local symbol, we're guaranteed
        // that there's always at least one more symbol in the symbol table,
        // as the global symbols come afterwards.
        auto* next_symbol = &symbol_table_.symbols()[starting_index + 1];
        // Search until we run out of local symbols for this section.
        while (next_symbol->section_index() == section->index()) {
          // Stop if the current symbol is closer than the next.
          if (Utils::Abs(next_symbol->value() - address) >=
              Utils::Abs(address - current->value())) {
            break;
          }
          ++starting_index;
          current = next_symbol;
          next_symbol = &symbol_table_.symbols()[starting_index + 1];
        }
        return starting_index;
      }
      // Fall through to see if the closest global symbol preceding
      // this address is closer.
    }
    intptr_t label = portion->label;
    if (label == 0) {
      // Search for a global symbol label in the portions preceding this one.
      for (const auto& p : section->portions()) {
        if (portion == &p) break;
        if (p.label != 0) {
          label = p.label;
        }
      }
    }
    if (current != nullptr) {
      // Check to see if the found global symbol (if any) is closer than the
      // local symbol following this address.
      intptr_t global_index = symbol_table_.IndexForLabel(label);
      if (global_index >= 0) {
        const auto& global_symbol = symbol_table_.symbols()[global_index];
        if (Utils::Abs(address - global_symbol.value()) <=
            Utils::Abs(current->value() - address)) {
          return global_index;
        }
      }
      return starting_index;
    }
    // IndexForLabel will return a negative value for label == 0.
    return symbol_table_.IndexForLabel(label);
  }

  MachORelocationsArray* EnsureCurrentRelocations() {
    if (current_relocations_ == nullptr) {
      current_relocations_ = new (zone_) MachORelocationsArray(zone_, 0);
    }
    return current_relocations_;
  }

  MachORelocationAddendsArray* EnsureCurrentRelocationAddends() {
    if (current_relocation_addends_ == nullptr) {
      current_relocation_addends_ =
          new (zone_) MachORelocationAddendsArray(zone_, 0);
    }
    return current_relocation_addends_;
  }

  void ConvertRelocation(const Relocation& reloc) {
    // In the Dart VM, we turn relocations into up to three different parts
    // in a Mach-O relocatable object:
    //
    // - A SUBTRACTOR relocation entry for [reloc.source_label].
    // - An UNSIGNED relocation entry for [reloc.target_label].
    // - An addend stored at [reloc.section_offset] in the section contents.
    //
    // If the source and target labels are the same, then there are no
    // relocation entries added and the addend is simply:
    //    [reloc.target_offset] - [reloc.source_offset]
    //
    // If there are distinct source and target labels, then a SUBTRACTOR
    // relocation entry for [reloc.source_label] is emitted followed by the
    // UNSIGNED relocation entry for [reloc.target_label]. Both relocation
    // entries are based on symbols. The addend, like the previous case, is:
    //    [reloc.target_offset] - [reloc.source_offset]
    //
    // If [reloc.source_label] is kSnapshotRelative, then only an UNSIGNED
    // relocation based on the section is emitted. Since a section-based
    // relocation entry is used, the addend differs from the other two cases:
    //     [current_section_.memory_address()] + [reloc.section_offset] +
    //         [reloc.target_offset] - [reloc.source_offset]
    // That is, the virtual address of the relocation is added to the addend.
    if (!Utils::IsInt(kBitsPerInt32,
                      current_portion_->offset + reloc.section_offset)) {
      FATAL("Offset into section for relocation is not a 32-bit integer.");
    }
    int32_t section_offset = current_portion_->offset + reloc.section_offset;
    const intptr_t address =
        current_section_->memory_address() + section_offset;
    if (reloc.target_label == SharedObjectWriter::kBuildIdLabel) {
      ASSERT_EQUAL(reloc.target_offset, 0);
      ASSERT_EQUAL(reloc.source_offset, 0);
      ASSERT_EQUAL(reloc.size_in_bytes, compiler::target::kWordSize);
      // Build IDs are UUID load commands in Mach-O and so have no
      // associated symbol to use for relocations.
      EnsureCurrentRelocationAddends()->Add(Image::kNoBuildId);
      return;
    }
    intptr_t addend = reloc.target_offset - reloc.source_offset;
    // If there is an emitted subtrahend (the source), emit it before
    // the minuend (the target).
    bool emitted_subtrahend = false;
    if (reloc.source_label == reloc.target_label) {
      // The relocation can be computed eagerly as the source and target
      // refer to the same object.
    } else if (reloc.source_label == Relocation::kSnapshotRelative) {
      ASSERT_EQUAL(reloc.source_offset, 0);
      ASSERT_EQUAL(reloc.size_in_bytes, compiler::target::kWordSize);
      if (auto* const kv =
              portion_and_section_by_label_.Lookup(reloc.target_label)) {
        const auto [section, portion] = kv->value;
        if (section == current_section_) {
          ASSERT(section->HasName(mach_o::SECT_TEXT) &&
                 section->HasSegname(mach_o::SEG_TEXT));
          // This is considered an illegal text relocation by clang, so omit
          // this relocation.
          EnsureCurrentRelocationAddends()->Add(Image::kNoRelocatedAddress);
          return;
        }
      }
    } else {
      // The subtrahend _must_ be a symbol.
      intptr_t index = -1;
      if (reloc.source_label == Relocation::kSelfRelative) {
        index = FindClosestSymbolIndexTo(reloc.section_offset, current_section_,
                                         current_portion_,
                                         starting_index_for_self_);
        if (index < 0) {
          FATAL("Cannot find any symbol in section %" Pd "",
                current_section_->index());
        }
        const auto& closest_symbol = symbol_table_.symbols()[index];
        // Adjust the addend by subtracting the offset from the found symbol.
        addend -= address - closest_symbol.value();
      } else {
        index = symbol_table_.IndexForLabel(reloc.source_label);
        RELEASE_ASSERT(index >= 0);
      }
      if (!Utils::IsUint(mach_o::RELOC_METADATA_INDEX_BITS, index)) {
        FATAL("Symbol index cannot fit into metadata payload: %" Pd "", index);
      }
      uint32_t source_metadata = index | mach_o::RELOC_EXTERN;
#if defined(TARGET_ARCH_X64)
      source_metadata |= mach_o::RELOC_TYPE_X64_SUBTRACTOR;
#elif defined(TARGET_ARCH_ARM64)
      source_metadata |= mach_o::RELOC_TYPE_ARM64_SUBTRACTOR;
#else
      // Relocatable objects aren't handled for this architecture.
      UNREACHABLE();
#endif
      source_metadata |= RelocationSize(reloc.size_in_bytes);
      EnsureCurrentRelocations()->Add({section_offset, source_metadata});
      emitted_subtrahend = true;
    }
    // Now calculate the relocation entry for the base or minuend (target).
    // If there is no subtrahend, the base is emitted as a relocation using
    // a section index. If the target and source are the same, then no entries
    // are emitted and the relocatable value is computed eagerly and stored as
    // the addend.
    //
    // Note that the base addend for section-based relocations is the virtual
    // address of the relocation, which is added here after determining which
    // kind of relocation to use.
    //
    // For symbol-based relocations, the base addend is 0.
    if (reloc.target_label != reloc.source_label) {
      uint32_t target_metadata = 0;
      intptr_t index = symbol_table_.IndexForLabel(reloc.target_label);
      if (index >= 0) {
        if (emitted_subtrahend) {
          // Both subtrahend and minuend must be emitted as symbols.
          target_metadata |= mach_o::RELOC_EXTERN;
        } else {
          const auto& symbol = symbol_table_.symbols()[index];
          index = symbol.section_index();
          addend += symbol.value();
        }
      } else if (reloc.target_label == Relocation::kSelfRelative) {
        if (emitted_subtrahend) {
          index = FindClosestSymbolIndexTo(reloc.section_offset,
                                           current_section_, current_portion_,
                                           starting_index_for_self_);
          if (index < 0) {
            FATAL("Cannot find any symbol in section %" Pd "",
                  current_section_->index());
          }
          const auto& closest_symbol = symbol_table_.symbols()[index];
          // Adjust the addend by adding the offset from the found symbol.
          addend += address - closest_symbol.value();
        } else {
          index = current_section_->index();
          addend += address;
        }
      } else {
        auto* const kv =
            portion_and_section_by_label_.Lookup(reloc.target_label);
        RELEASE_ASSERT(kv != nullptr);
        const auto [section, portion] = kv->value;
        const intptr_t target_address =
            section->memory_address() + portion->offset;
        if (emitted_subtrahend) {
          intptr_t starting_index = symbol_table_.IndexForLabel(portion->label);
          index = FindClosestSymbolIndexTo(0, section, portion, starting_index);
          if (index < 0) {
            FATAL("Cannot find any symbol in section %" Pd "",
                  section->index());
          }
          const auto& closest_symbol = symbol_table_.symbols()[index];
          // Adjust the addend by adding the offset from the found symbol.
          addend += target_address - closest_symbol.value();
        } else {
          index = section->index();
          addend += target_address;
        }
        ASSERT(index != mach_o::NO_SECT);
      }
      if (!Utils::IsUint(mach_o::RELOC_METADATA_INDEX_BITS, index)) {
        FATAL("Could not convert target label %" Pd
              " of relocation, got %s index %" Pd " and addend %#" Px "",
              reloc.target_label,
              (target_metadata & mach_o::RELOC_EXTERN) != 0 ? "symbol"
                                                            : "section",
              index, addend);
      }
      target_metadata |= index;
#if defined(TARGET_ARCH_X64)
      target_metadata |= mach_o::RELOC_TYPE_X64_UNSIGNED;
#elif defined(TARGET_ARCH_ARM64)
      target_metadata |= mach_o::RELOC_TYPE_ARM64_UNSIGNED;
#else
      // Relocatable objects aren't handled for this architecture.
      UNREACHABLE();
#endif
      target_metadata |= RelocationSize(reloc.size_in_bytes);
      EnsureCurrentRelocations()->Add({section_offset, target_metadata});
    }
    if (!Utils::IsInt(reloc.size_in_bytes * kBitsPerByte, addend)) {
      FATAL("Calculated addend for relocation too large: %#" Px "", addend);
    }
    EnsureCurrentRelocationAddends()->Add(addend);
  }

  Zone* const zone_;
  const bool output_is_relocatable_object_;
  const MachOSymbolTable& symbol_table_;
  intptr_t file_offset_;
  // A mapping of portion labels to the associated section and portion.
  DirectChainedHashMap<IntKeyRawPointerValueTrait<
      std::pair<const MachOSection*, const MachOSection::Portion*>>>
      portion_and_section_by_label_;

  // Internal state fields used by ConvertRelocation/ConvertRelocationLabel.
  const MachOSection* current_section_ = nullptr;
  const MachOSection::Portion* current_portion_ = nullptr;
  MachORelocationsArray* current_relocations_ = nullptr;
  MachORelocationAddendsArray* current_relocation_addends_ = nullptr;
  intptr_t starting_index_for_self_ = -1;

  DISALLOW_COPY_AND_ASSIGN(RelocationsConverter);
};

void MachOHeader::ComputeOffsets() {
  // First, set the offsets of the load commands in the header.
  intptr_t header_offset = SizeWithoutLoadCommands();
  for (auto* const c : commands_) {
    ASSERT(
        Utils::IsAligned(header_offset, MachOCommand::kLoadCommandAlignment));
    c->set_header_offset(header_offset);
    header_offset += c->cmdsize();
  }

  // Next, set the offsets of the contents of load commands with post-header
  // content (segments, symbol tables, etc.).
  ContentOffsetsVisitor visitor(zone());
  VisitContents(&visitor);

  // Finally, for relocatable objects, convert the relocations into appropriate
  // relocation entries and addends and also set the offsets at which relocation
  // information is stored for sections, as this information is written into
  // the file after the other contents.
  //
  // For other types of output, there is no converted relocation information (as
  // the relocatable values are fully computed), so this visitor sets the
  // section fields for relocations to reflect this.
  RelocationsConverter relocs_visitor(zone_, *this, visitor.file_offset);
  VisitContents(&relocs_visitor);
}

void MachOSymbolTable::Initialize(SharedObjectWriter::Type type,
                                  const char* path,
                                  const GrowableArray<MachOSection*>& sections,
                                  bool is_stripped) {
  using SnapshotType = SharedObjectWriter::Type;
  // Not idempotent.
  ASSERT(!num_local_symbols_is_set());

  // If symbolic debugging symbols are emitted, then any section
  // symbols are marked as alternate entries in favor of the symbolic
  // debugging symbols.
  const intptr_t desc =
      (type == SnapshotType::Object || is_stripped) ? 0 : mach_o::N_ALT_ENTRY;

  // For unstripped symbol tables, we do two initial passes. In the first
  // pass, we add section symbols for local static symbols.
  if (!is_stripped) {
    for (intptr_t i = 0, n = sections.length(); i < n; ++i) {
      auto* const section = sections[i];
      for (const auto& portion : section->portions()) {
        if (portion.symbols != nullptr) {
          for (const auto& symbol_data : *portion.symbols) {
            AddSymbol(symbol_data.name, mach_o::N_SECT, section, desc,
                      portion.offset + symbol_data.offset, symbol_data.label);
          }
        }
      }
    }

    // The second pass adds appropriate symbolic debugging symbols.  This pass
    // is skipped for relocatable objects.
    if (type != SnapshotType::Object) {
      using Type = SharedObjectWriter::SymbolData::Type;
      if (path != nullptr) {
        // The value of the OSO symbolic debugging symbol is the mtime of the
        // object file. However, clang may warn about a mismatch if this is not
        // 0 and differs from the actual mtime of the object file.
        AddSymbol(path, mach_o::N_OSO, /*section=*/nullptr,
                  /*description=*/1, /*section_offset_or_value=*/0);
      }
      auto add_symbolic_debugging_symbols = [&](const char* name, Type type,
                                                const MachOSection* section,
                                                intptr_t offset, intptr_t size,
                                                bool is_global) {
        switch (type) {
          case Type::Function: {
            AddSymbol("", mach_o::N_BNSYM, section, /*description=*/0, offset);
            AddSymbol(name, mach_o::N_FUN, section, /*description=*/0, offset);
            // The size is output as an unnamed N_FUN symbol with no section
            // following the actual N_FUN symbol.
            AddSymbol("", mach_o::N_FUN, /*section=*/nullptr, /*description=*/0,
                      size);
            AddSymbol("", mach_o::N_ENSYM, section, /*description=*/0,
                      offset + size);

            break;
          }
          case Type::Section:
          case Type::Object: {
            if (is_global) {
              AddSymbol(name, mach_o::N_GSYM, /*section=*/nullptr,
                        /*description=*/0,
                        /*section_offset_or_value=*/0);
            } else {
              AddSymbol(name, mach_o::N_STSYM, section,
                        /*description=*/0, offset);
            }
            break;
          }
        }
      };

      for (intptr_t i = 0, n = sections.length(); i < n; ++i) {
        auto* const section = sections[i];
        // We handle global symbols for text sections slightly differently than
        // those for other sections.
        const bool is_text_section = section->HasName(mach_o::SECT_TEXT);
        for (const auto& portion : section->portions()) {
          if (portion.symbol_name != nullptr) {
            // Matching the symbolic debugging symbols created for assembled
            // snapshots.
            auto const type = is_text_section ? Type::Function : Type::Section;
            // The "size" of a function symbol created for start of a text
            // portion is up to the first function symbol.
            auto const size = is_text_section && portion.symbols != nullptr
                                  ? portion.symbols->At(0).offset
                                  : portion.size;
            add_symbolic_debugging_symbols(portion.symbol_name, type, section,
                                           portion.offset, size,
                                           /*is_global=*/true);
          }
          if (portion.symbols != nullptr) {
            for (const auto& symbol_data : *portion.symbols) {
              add_symbolic_debugging_symbols(
                  symbol_data.name, symbol_data.type, section,
                  portion.offset + symbol_data.offset, symbol_data.size,
                  /*is_global=*/false);
            }
          }
        }
      }
    }
  }
  set_num_local_symbols(num_symbols());

  // In the final pass, we add external symbols for section global symbols
  // (so added to both stripped and unstripped symbol tables).
  for (intptr_t i = 0, n = sections.length(); i < n; ++i) {
    auto* const section = sections[i];
    for (const auto& portion : section->portions()) {
      if (portion.symbol_name != nullptr) {
        AddSymbol(portion.symbol_name, mach_o::N_SECT | mach_o::N_EXT, section,
                  desc, portion.offset, portion.label);
      }
    }
  }
  set_num_external_symbols(num_symbols() - num_local_symbols());
}

}  // namespace dart

#endif  // defined(DART_PRECOMPILER)
