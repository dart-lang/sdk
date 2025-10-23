// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PERFETTO_UTILS_H_
#define RUNTIME_VM_PERFETTO_UTILS_H_

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

#include <memory>
#include <tuple>
#include <utility>

#include "perfetto/ext/tracing/core/trace_packet.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "third_party/perfetto/protos/perfetto/common/builtin_clock.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/clock_snapshot.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/trace_packet.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/track_event/process_descriptor.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/track_event/track_descriptor.pbzero.h"
#include "vm/hash_map.h"
#include "vm/json_stream.h"
#include "vm/os.h"

namespace dart {

namespace perfetto_utils {

inline void SetTrustedPacketSequenceId(
    perfetto::protos::pbzero::TracePacket* packet) {
  // trusted_packet_sequence_id uniquely identifies a trace producer + writer
  // pair. We set the trusted_packet_sequence_id of all packets that we write to
  // the arbitrary value of 1.
  packet->set_trusted_packet_sequence_id(1);
}

inline void SetTimestampAndMonotonicClockId(
    perfetto::protos::pbzero::TracePacket* packet,
    int64_t timestamp_micros) {
  ASSERT(packet != nullptr);
  // TODO(derekx): We should be able to set the unit_multiplier_ns field in a
  // ClockSnapshot to avoid manually converting from microseconds to
  // nanoseconds, but I haven't been able to get it to work.
  packet->set_timestamp(timestamp_micros * 1000);
  packet->set_timestamp_clock_id(
      perfetto::protos::pbzero::BuiltinClock::BUILTIN_CLOCK_MONOTONIC);
}

inline void PopulateClockSnapshotPacket(
    perfetto::protos::pbzero::TracePacket* packet) {
  SetTrustedPacketSequenceId(packet);

  perfetto::protos::pbzero::ClockSnapshot& clock_snapshot =
      *packet->set_clock_snapshot();
  clock_snapshot.set_primary_trace_clock(
      perfetto::protos::pbzero::BuiltinClock::BUILTIN_CLOCK_MONOTONIC);

  perfetto::protos::pbzero::ClockSnapshot_Clock& clock =
      *clock_snapshot.add_clocks();
  clock.set_clock_id(
      perfetto::protos::pbzero::BuiltinClock::BUILTIN_CLOCK_MONOTONIC);
  clock.set_timestamp(OS::GetCurrentMonotonicMicrosForTimeline() * 1000);
}

inline void PopulateProcessDescriptorPacket(
    perfetto::protos::pbzero::TracePacket* packet) {
  perfetto_utils::SetTrustedPacketSequenceId(packet);

  perfetto::protos::pbzero::TrackDescriptor& track_descriptor =
      *packet->set_track_descriptor();
  const int64_t pid = OS::ProcessId();
  track_descriptor.set_uuid(pid);

  perfetto::protos::pbzero::ProcessDescriptor& process_descriptor =
      *track_descriptor.set_process();
  process_descriptor.set_pid(pid);
  // TODO(derekx): Add the process name.
}

inline const std::tuple<std::unique_ptr<const uint8_t[]>, intptr_t>
GetProtoPreamble(
    protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>* packet) {
  ASSERT(packet != nullptr);

  intptr_t size = 0;
  for (const protozero::ScatteredHeapBuffer::Slice& slice :
       packet->GetSlices()) {
    size += slice.size() - slice.unused_bytes();
  }

  std::unique_ptr<uint8_t[]> preamble =
      std::make_unique<uint8_t[]>(perfetto::TracePacket::kMaxPreambleBytes);
  uint8_t* ptr = &preamble[0];

  const uint8_t tag = protozero::proto_utils::MakeTagLengthDelimited(
      perfetto::TracePacket::kPacketFieldNumber);
  static_assert(tag < 0x80, "TracePacket tag should fit in one byte");
  *(ptr++) = tag;

  ptr = protozero::proto_utils::WriteVarInt(size, ptr);
  intptr_t preamble_size = reinterpret_cast<intptr_t>(ptr) -
                           reinterpret_cast<intptr_t>(&preamble[0]);
  return std::make_tuple(std::move(preamble), preamble_size);
}

inline void AppendPacketToJSONBase64String(
    JSONBase64String* jsonBase64String,
    protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>* packet) {
  ASSERT(jsonBase64String != nullptr);
  ASSERT(packet != nullptr);

  const std::tuple<std::unique_ptr<const uint8_t[]>, intptr_t>& response =
      perfetto_utils::GetProtoPreamble(packet);
  const uint8_t* preamble = std::get<0>(response).get();
  const intptr_t preamble_length = std::get<1>(response);
  jsonBase64String->AppendBytes(preamble, preamble_length);
  for (const protozero::ScatteredHeapBuffer::Slice& slice :
       packet->GetSlices()) {
    jsonBase64String->AppendBytes(slice.start(),
                                  slice.size() - slice.unused_bytes());
  }
}

// Sequence of elements which can be interned by |BytesInterner|.
//
// Equality and hash are defined in terms of raw byte content.
template <typename T>
struct InternedBytes {
  InternedBytes(const T* data, intptr_t length)
      : data(data),
        length(length),
        hash(HashBytes(reinterpret_cast<const uint8_t*>(data),
                       length * sizeof(T))),
        iid(0) {}

  InternedBytes(const T* data, intptr_t length, uword hash, uint64_t iid)
      : data(data), length(length), hash(hash), iid(iid) {}

  bool Equals(const InternedBytes& other) const {
    if (length != other.length) {
      return false;
    }
    return memcmp(data, other.data, length * sizeof(T)) == 0;
  }

  uword Hash() const { return hash; }

  const T* const data;
  const intptr_t length;
  const uword hash;

  // Interning id. Only set after interning and does not participate in
  // equality or hash computations.
  const uint64_t iid;
};

// Interning dictionary used to construct various parts of |InternedData|
// message.
template <typename T, typename Allocator>
class BytesInterner
    : public BaseDirectChainedHashMap<PointerSetKeyValueTrait<InternedBytes<T>>,
                                      ValueObject,
                                      Allocator> {
  using Base =
      BaseDirectChainedHashMap<PointerSetKeyValueTrait<InternedBytes<T>>,
                               ValueObject,
                               Allocator>;

 public:
  explicit BytesInterner(Allocator* allocator = nullptr) : Base(allocator) {}

  ~BytesInterner() {
    if constexpr (Allocator::kSupportsFreeingIndividualAllocations) {
      auto it = Base::GetIterator();
      while (auto pair = it.Next()) {
        Dispose(*pair);
      }
    }
  }

  uint64_t Intern(const T* data, const intptr_t length) {
    InternedBytes<T> key(data, length);
    if (auto interned = Base::Lookup(&key)) {
      return (*interned)->iid;
    }

    const uint64_t iid = Base::Size() + 1;
    Base::Insert(Copy(key, iid));
    return iid;
  }

  // Enumerate all entries added to this interner since the last call to this
  // function.
  template <typename F>
  void FlushNewlyInternedTo(F&& callback) {
    // Note: we never remove elements from this map so we can just iterate
    // |pairs_| linearly.
    for (uint32_t i = first_to_flush_; i < Base::next_pair_index_; i++) {
      callback(*Base::pairs_[i]);
    }
    first_to_flush_ = Base::next_pair_index_;
  }

  // Returns |true| if there are entries added to this interner since the
  // last call to |FlushNewlyInternedTo|
  bool HasNewlyInternedEntries() const {
    return first_to_flush_ < Base::next_pair_index_;
  }

 private:
  Allocator* allocator() const { return Base::allocator_; }

  InternedBytes<T>* Copy(const InternedBytes<T>& interned, uint64_t iid) const {
    auto data_copy = allocator()->template Alloc<T>(interned.length);
    memcpy(data_copy, interned.data, interned.length * sizeof(T));  // NOLINT
    auto copy = allocator()->template Alloc<InternedBytes<T>>(1);
    new (copy) InternedBytes<T>(data_copy, interned.length, interned.hash, iid);
    return copy;
  }

  void Dispose(InternedBytes<T>* interned) {
    if constexpr (Allocator::kSupportsFreeingIndividualAllocations) {
      allocator()->Free(const_cast<T*>(interned->data),
                        interned->length * sizeof(T));
      allocator()->Free(interned, 1);
    }
  }

  // The index of the first entry which was not flushed via
  // |FlushNewlyInternedTo|.
  uint32_t first_to_flush_ = 0;
};

template <typename Allocator>
class StringInterner : public ValueObject {
 public:
  explicit StringInterner(Allocator* allocator = nullptr)
      : bytes_interner_(allocator) {}

  uint64_t Intern(const char* str) {
    // +1 to include terminating NUL character.
    return bytes_interner_.Intern(str, strlen(str) + 1);
  }

  bool HasNewlyInternedEntries() const {
    return bytes_interner_.HasNewlyInternedEntries();
  }

  template <typename F>
  void FlushNewlyInternedTo(F&& callback) {
    bytes_interner_.FlushNewlyInternedTo(
        [callback = std::move(callback)](const auto& interned_bytes) {
          callback(interned_bytes.iid, interned_bytes.data);
        });
  }

 private:
  BytesInterner<char, Allocator> bytes_interner_;
};

}  // namespace perfetto_utils

}  // namespace dart

#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

#endif  // RUNTIME_VM_PERFETTO_UTILS_H_
