// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SO_WRITER_H_
#define RUNTIME_VM_SO_WRITER_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)
#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"
#include "vm/datastream.h"
#include "vm/growable_array.h"
#include "vm/zone.h"

namespace dart {

class Dwarf;
class ElfWriter;
class MachOWriter;

class SharedObjectWriter : public ZoneObject {
 public:
  enum class Type {
    // A snapshot that should include segment contents.
    Snapshot,
    // Separately compiled debugging information that should not include
    // most segment contents.
    DebugInfo,
    // A relocatable object file.
    Object,
  };

  enum class Output {
    Elf,
    MachO,
  };

  SharedObjectWriter(Zone* zone,
                     BaseWriteStream* stream,
                     Type type,
                     Dwarf* dwarf = nullptr)
      : zone_(zone), unwrapped_stream_(stream), type_(type), dwarf_(dwarf) {
    // Separate debugging information should always have a Dwarf object.
    ASSERT(type == Type::Snapshot || dwarf != nullptr);
    // Assumed by various offset logic in the subclasses.
    ASSERT_EQUAL(stream->Position(), 0);
  }
  virtual ~SharedObjectWriter() {}

  virtual intptr_t page_size() const = 0;
  virtual Output output() const = 0;

  static bool IsStripped(Dwarf* dwarf) { return dwarf == nullptr; }
  bool IsStripped() const { return IsStripped(dwarf_); }

  Zone* zone() const { return zone_; }
  Dwarf* dwarf() { return dwarf_; }
  SharedObjectWriter::Type type() const { return type_; }

  // Stores the information needed to appropriately generate a
  // relocation from the target to the source at the given section offset.
  struct Relocation {
    size_t size_in_bytes;
    intptr_t section_offset;
    intptr_t source_label;
    intptr_t source_offset;
    intptr_t target_label;
    intptr_t target_offset;

    // Used when the corresponding offset is relative from the location of the
    // relocation itself.
    static constexpr intptr_t kSelfRelative = -1;
    // Used when the corresponding offset is relative to the start of the
    // snapshot.
    static constexpr intptr_t kSnapshotRelative = -2;

    Relocation(size_t size_in_bytes,
               intptr_t section_offset,
               intptr_t source_label,
               intptr_t source_offset,
               intptr_t target_label,
               intptr_t target_offset)
        : size_in_bytes(size_in_bytes),
          section_offset(section_offset),
          source_label(source_label),
          source_offset(source_offset),
          target_label(target_label),
          target_offset(target_offset) {
      // Other than special values, all labels should be positive.
      ASSERT(source_label > 0 || source_label == kSelfRelative ||
             source_label == kSnapshotRelative);
      ASSERT(target_label > 0 || target_label == kSelfRelative ||
             target_label == kSnapshotRelative);
    }
  };

  using RelocationArray = ZoneGrowableArray<Relocation>;

  // Stores the information needed to appropriately generate a symbol
  // during finalization.
  struct SymbolData {
    enum class Type {
      Section,
      Function,
      Object,
    };

    const char* name;
    Type type;
    intptr_t offset;
    size_t size;
    // A positive unique ID only used internally in the Dart VM, not part of
    // the shared object output.
    intptr_t label;

    SymbolData(const char* name,
               Type type,
               intptr_t offset,
               size_t size,
               intptr_t label)
        : name(name), type(type), offset(offset), size(size), label(label) {
      ASSERT(label > 0);
    }
  };

  using SymbolDataArray = ZoneGrowableArray<SymbolData>;

  struct WriteStream : public AbstractWriteStream {
    explicit WriteStream(SharedObjectWriter::Type type) : type_(type) {}

    SharedObjectWriter::Type type() const { return type_; }

    void WriteBytesWithRelocations(const uint8_t* bytes,
                                   intptr_t size,
                                   intptr_t start_address,
                                   const RelocationArray& relocations);

    virtual bool HasValueForLabel(intptr_t label, intptr_t* value) const = 0;
    intptr_t FindValueForLabel(intptr_t label) const {
      intptr_t value = -1;
      const bool valid = HasValueForLabel(label, &value);
      if (!valid) {
        FATAL("Expected symbol for label: %" Pd "", label);
      }
      return value;
    }

   protected:
    virtual void WriteRelocatableValue(intptr_t address,
                                       const Relocation& reloc,
                                       intptr_t reloc_index);

   private:
    const SharedObjectWriter::Type type_;
    DISALLOW_COPY_AND_ASSIGN(WriteStream);
  };

  class DelegatingWriteStream : public WriteStream {
   public:
    DelegatingWriteStream(BaseWriteStream* stream,
                          const SharedObjectWriter& writer)
        : WriteStream(writer.type()),
          stream_(ASSERT_NOTNULL(stream)),
          start_(stream->Position()),
          page_size_(writer.page_size()) {
      // So that we can use the underlying stream's Align, as all alignments
      // will be less than or equal to this alignment.
      ASSERT(Utils::IsAligned(start_, page_size_));
    }

    // We return positions in terms of the local content that has been written,
    // ignoring any previous content on the stream.
    intptr_t Position() const override { return stream_->Position() - start_; }
    void WriteBytes(const void* b, intptr_t size) override {
      stream_->WriteBytes(b, size);
    }
    void WriteByte(uint8_t value) override { stream_->WriteByte(value); }
    intptr_t Align(intptr_t alignment, intptr_t offset = 0) override {
      ASSERT(Utils::IsPowerOfTwo(alignment));
      ASSERT(alignment <= page_size_);
      return stream_->Align(alignment, offset);
    }

   protected:
    BaseWriteStream* const stream_;

   private:
    const intptr_t start_;
    const intptr_t page_size_;

    DISALLOW_COPY_AND_ASSIGN(DelegatingWriteStream);
  };

  // Must be the same value as the values returned by ImageWriter::SectionLabel
  // for the appropriate section and vm values.
  enum ReservedLabels : intptr_t {
    kVmInstructionsLabel = 1,
    kIsolateInstructionsLabel = 2,
    kVmDataLabel = 3,
    kIsolateDataLabel = 4,
    kVmBssLabel = 5,
    kIsolateBssLabel = 6,
    kBuildIdLabel = 7,
    kMachOEhFrameLabel = 8,
    kLastReservedLabel = kMachOEhFrameLabel,
  };

  virtual void AddText(const char* name,
                       intptr_t label,
                       const uint8_t* bytes,
                       intptr_t size,
                       const RelocationArray* relocations,
                       const SymbolDataArray* symbols) = 0;
  virtual void AddROData(const char* name,
                         intptr_t label,
                         const uint8_t* bytes,
                         intptr_t size,
                         const RelocationArray* relocations,
                         const SymbolDataArray* symbols) = 0;

  virtual void Finalize() = 0;

  virtual void AssertConsistency(const SharedObjectWriter* debug) const = 0;

  virtual const ElfWriter* AsElfWriter() const { return nullptr; }
  virtual const MachOWriter* AsMachOWriter() const { return nullptr; }

 protected:
  Zone* const zone_;
  BaseWriteStream* const unwrapped_stream_;
  const Type type_;

  // If nullptr, then the shared object file should be stripped of static
  // information like the static symbol table.
  Dwarf* const dwarf_;
};

}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_VM_SO_WRITER_H_
