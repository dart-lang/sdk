// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DWARF_SO_WRITER_H_
#define RUNTIME_VM_DWARF_SO_WRITER_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)

#include "vm/datastream.h"
#include "vm/dwarf.h"
#include "vm/so_writer.h"

namespace dart {

class DwarfSharedObjectStream : public DwarfWriteStream {
 public:
  DwarfSharedObjectStream(Zone* zone, NonStreamingWriteStream* stream)
      : zone_(ASSERT_NOTNULL(zone)),
        stream_(ASSERT_NOTNULL(stream)),
        relocations_(new (zone) SharedObjectWriter::RelocationArray()) {}

  static constexpr intptr_t kInitialBufferSize = 64 * KB;

  const uint8_t* buffer() const { return stream_->buffer(); }
  intptr_t bytes_written() const { return stream_->bytes_written(); }
  intptr_t Position() const { return stream_->Position(); }

  void sleb128(intptr_t value) { stream_->WriteSLEB128(value); }
  void uleb128(uintptr_t value) { stream_->WriteLEB128(value); }
  void u1(uint8_t value) { stream_->WriteByte(value); }
  void u2(uint16_t value) { stream_->WriteFixed(value); }
  void u4(uint32_t value) { stream_->WriteFixed(value); }
  void u8(uint64_t value) { stream_->WriteFixed(value); }
  void string(const char* cstr) {  // NOLINT
    // Unlike stream_->WriteString(), we want the null terminator written.
    stream_->WriteBytes(cstr, strlen(cstr) + 1);
  }
  // The prefix is ignored for DwarfSharedObjectStreams.
  void WritePrefixedLength(const char* unused, std::function<void()> body) {
    const intptr_t fixup = stream_->Position();
    // We assume DWARF v2 currently, so all sizes are 32-bit.
    u4(0);
    // All sizes for DWARF sections measure the size of the section data _after_
    // the size value.
    const intptr_t start = stream_->Position();
    body();
    const intptr_t end = stream_->Position();
    stream_->SetPosition(fixup);
    u4(end - start);
    stream_->SetPosition(end);
  }
  // Shorthand for when working directly with DwarfSharedObjectStreams.
  void WritePrefixedLength(std::function<void()> body) {
    WritePrefixedLength(nullptr, body);
  }

  void OffsetFromSymbol(intptr_t label, intptr_t offset) {
    relocations_->Add({kAddressSize, stream_->Position(),
                       SharedObjectWriter::Relocation::kSnapshotRelative, 0,
                       label, offset});
    addr(0);  // Resolved later.
  }
  template <typename T>
  void RelativeSymbolOffset(intptr_t label) {
    relocations_->Add({sizeof(T), stream_->Position(),
                       SharedObjectWriter::Relocation::kSelfRelative, 0, label,
                       0});
    stream_->WriteFixed<T>(0);  // Resolved later.
  }
  void InitializeAbstractOrigins(intptr_t size) {
    abstract_origins_size_ = size;
    abstract_origins_ = zone_->Alloc<uint32_t>(abstract_origins_size_);
  }
  void RegisterAbstractOrigin(intptr_t index) {
    ASSERT(abstract_origins_ != nullptr);
    ASSERT(index < abstract_origins_size_);
    abstract_origins_[index] = stream_->Position();
  }
  void AbstractOrigin(intptr_t index) { u4(abstract_origins_[index]); }

  const SharedObjectWriter::RelocationArray* relocations() const {
    return relocations_;
  }

 protected:
#if defined(TARGET_ARCH_IS_32_BIT)
  static constexpr intptr_t kAddressSize = kInt32Size;
#else
  static constexpr intptr_t kAddressSize = kInt64Size;
#endif

  void addr(uword value) {
#if defined(TARGET_ARCH_IS_32_BIT)
    u4(value);
#else
    u8(value);
#endif
  }

  Zone* const zone_;
  NonStreamingWriteStream* const stream_;
  SharedObjectWriter::RelocationArray* const relocations_ = nullptr;
  uint32_t* abstract_origins_ = nullptr;
  intptr_t abstract_origins_size_ = -1;

 private:
  DISALLOW_COPY_AND_ASSIGN(DwarfSharedObjectStream);
};

}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_VM_DWARF_SO_WRITER_H_
