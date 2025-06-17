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

  void sleb128(intptr_t value) override { stream_->WriteSLEB128(value); }
  void uleb128(uintptr_t value) override { stream_->WriteLEB128(value); }
  void u1(uint8_t value) override { stream_->WriteByte(value); }
  void u2(uint16_t value) override { stream_->WriteFixed(value); }
  void u4(uint32_t value) override { stream_->WriteFixed(value); }
  void u8(uint64_t value) override { stream_->WriteFixed(value); }
  void string(const char* cstr) override {  // NOLINT
    // Unlike stream_->WriteString(), we want the null terminator written.
    stream_->WriteBytes(cstr, strlen(cstr) + 1);
  }
  // The prefix is ignored for DwarfSharedObjectStreams.
  void WritePrefixedLength(const char* unused,
                           std::function<void()> body) override {
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

  void OffsetFromSymbol(intptr_t label,
                        intptr_t offset,
                        size_t size = kAddressSize) override {
    ASSERT(size > 0);
    ASSERT(size <= static_cast<size_t>(kInt64Size));
    relocations_->Add({size, stream_->Position(),
                       SharedObjectWriter::Relocation::kSnapshotRelative, 0,
                       label, offset});
    const uint64_t placeholder = 0;  // Resolved later.
    stream_->WriteBytes(&placeholder, size);
  }
  void InitializeAbstractOrigins(intptr_t size) override {
    abstract_origins_size_ = size;
    abstract_origins_ = zone_->Alloc<uint32_t>(abstract_origins_size_);
  }
  void RegisterAbstractOrigin(intptr_t index) override {
    ASSERT(abstract_origins_ != nullptr);
    ASSERT(index < abstract_origins_size_);
    abstract_origins_[index] = stream_->Position();
  }
  void AbstractOrigin(intptr_t index) override { u4(abstract_origins_[index]); }

  // Generates the offset of the virtual address corresponding to the given
  // symbol label from the current position in the output. That is, if
  //   X = the virtual address of the current position
  //   Y = the virtual address of the symbol
  // then the value at the current position in the output is Y - X.
  //
  // If no size is provided, the size of the offset in the stream is
  // the native word size.
  void RelativeSymbolOffset(intptr_t label, size_t size = kAddressSize) {
    relocations_->Add({size, stream_->Position(),
                       SharedObjectWriter::Relocation::kSelfRelative, 0, label,
                       0});
    const uint64_t placeholder = 0;  // Resolved later.
    stream_->WriteBytes(&placeholder, size);
  }

  intptr_t Align(intptr_t alignment, intptr_t offset = 0) {
    return stream_->Align(alignment, offset);
  }

  const SharedObjectWriter::RelocationArray* relocations() const {
    return relocations_;
  }

 protected:
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
