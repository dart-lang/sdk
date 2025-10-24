// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PERFETTO_UTILS_H_
#define RUNTIME_VM_PERFETTO_UTILS_H_

#if defined(SUPPORT_PERFETTO)

#include <memory>
#include <tuple>
#include <utility>

#include "perfetto/ext/tracing/core/trace_packet.h"
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "third_party/perfetto/protos/perfetto/common/builtin_clock.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/clock_snapshot.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/interned_data/interned_data.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/profiling/profile_common.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/trace_packet.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/track_event/debug_annotation.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/track_event/process_descriptor.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/track_event/track_descriptor.pbzero.h"
#include "third_party/perfetto/protos/perfetto/trace/track_event/track_event.pbzero.h"
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

template <typename WriteBytesFunction>
inline void WritePacketBytes(
    protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>* packet,
    WriteBytesFunction&& write_bytes) {
  ASSERT(packet != nullptr);
  const std::tuple<std::unique_ptr<const uint8_t[]>, intptr_t>& response =
      perfetto_utils::GetProtoPreamble(packet);
  const uint8_t* preamble = std::get<0>(response).get();
  const intptr_t preamble_length = std::get<1>(response);
  write_bytes(preamble, preamble_length);
  for (const protozero::ScatteredHeapBuffer::Slice& slice :
       packet->GetSlices()) {
    write_bytes(slice.start(), slice.size() - slice.unused_bytes());
  }
}

inline void AppendPacketToJSONBase64String(
    JSONBase64String* jsonBase64String,
    protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>* packet) {
  ASSERT(jsonBase64String != nullptr);
  WritePacketBytes(packet, [&](auto bytes, auto bytes_length) {
    jsonBase64String->AppendBytes(bytes, bytes_length);
  });
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

constexpr uint8_t kInternerWasUsed = 1 << 0;
constexpr uint8_t kInternerHasNewEntries = 1 << 1;
typedef uint8_t InternerStateBits;

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
    state_ |= kInternerWasUsed;

    InternedBytes<T> key(data, length);
    if (auto interned = Base::Lookup(&key)) {
      return (*interned)->iid;
    }

    state_ |= kInternerHasNewEntries;
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

  InternerStateBits TakeAndResetState() {
    const auto result = state_;
    state_ = 0;
    return result;
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

  // Combination of |kInternerWasUsed| and |kInternerHasNewEntries|.
  InternerStateBits state_ = 0;
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

  InternerStateBits TakeAndResetState() {
    return bytes_interner_.TakeAndResetState();
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

// Trait used to map 64-bit ids (e.g. isolate or isolate group id) to
// interned id of a corresponding string representation.
//
// This way we only need to generate formatted string once, instead of
// repeatedly formatting it and then interning resulting string to get an
// iid.
class IdToIidTrait {
 public:
  struct Pair {
    uint64_t id;
    uint64_t formatted_iid;
  };
  using Key = uint64_t;
  using Value = uint64_t;

  static Key KeyOf(const Pair& kv) { return kv.id; }
  static Value ValueOf(const Pair& kv) { return kv.formatted_iid; }
  static uword Hash(Key key) {
    return Utils::WordHash(static_cast<intptr_t>(key));
  }
  static bool IsKeyEqual(const Pair& kv, Key key) { return kv.id == key; }
};

using IdToIidMap = MallocDirectChainedHashMap<IdToIidTrait>;

class InternedDataBuilder : public ValueObject {
 private:
  using SequenceFlags = perfetto::protos::pbzero::TracePacket_SequenceFlags;

 public:
  // InternedData contains multiple independent interning dictionaries which
  // are used for different attributes.
#define PERFETTO_INTERNED_STRINGS_FIELDS_LIST(V)                               \
  V(event_categories, name)                                                    \
  V(event_names, name)                                                         \
  V(debug_annotation_names, name)                                              \
  V(debug_annotation_string_values, str)                                       \
  V(function_names, str)                                                       \
  V(mapping_paths, str)

#define PERFETTO_INTERNED_RAW_BYTES_FIELDS_LIST(V)                             \
  V(callstacks, uint64_t)                                                      \
  V(mappings, uint64_t)                                                        \
  V(frames, uint64_t)

  // Direct access for known strings.
#define PERFETTO_COMMON_INTERNED_STRINGS_LIST(V)                               \
  V(debug_annotation_names, isolateId)                                         \
  V(debug_annotation_names, isolateGroupId)

  InternedDataBuilder() = default;

  // Emit all strings added since the last invocation of |AttachInternedDataTo|
  // into |interned_data| of the given |TracePacket|.
  //
  // Mark the packet as depending on incremental state.
  void AttachInternedDataTo(perfetto::protos::pbzero::TracePacket* packet) {
    const auto interners_state = TakeAndResetStateOfAllInterners();
    if ((interners_state & kInternerWasUsed) != 0) {
      // At least one interner was used.
      packet->set_sequence_flags(sequence_flags_);
    }

    if ((interners_state & kInternerHasNewEntries) == 0) {
      // None of interners have new entries.
      return;
    }

    // The first packet will have SEQ_INCREMENTAL_STATE_CLEARED
    // the rest will just have SEQ_NEEDS_INCREMENTAL_STATE.
    sequence_flags_ &= ~SequenceFlags::SEQ_INCREMENTAL_STATE_CLEARED;

    auto interned_data = packet->set_interned_data();

    // Flush individual interning dictionaries.
#define FLUSH_FIELD(name, proto_field)                                         \
  name##_.FlushNewlyInternedTo([interned_data](auto& iid, auto& str) {         \
    auto entry = interned_data->add_##name();                                  \
    entry->set_iid(iid);                                                       \
    entry->set_##proto_field(str);                                             \
  });

    PERFETTO_INTERNED_STRINGS_FIELDS_LIST(FLUSH_FIELD)
#undef FLUSH_FIELD

    callstacks_.FlushNewlyInternedTo([interned_data](const auto& interned) {
      auto callstack = interned_data->add_callstacks();
      callstack->set_iid(interned.iid);
      for (intptr_t i = 0; i < interned.length; i++) {
        callstack->add_frame_ids(interned.data[i]);
      }
    });

    mappings_.FlushNewlyInternedTo([interned_data](const auto& interned) {
      auto mapping = interned_data->add_mappings();
      mapping->set_iid(interned.iid);
      mapping->add_path_string_ids(interned.data[0]);
    });

    frames_.FlushNewlyInternedTo([interned_data](const auto& interned) {
      auto frame = interned_data->add_frames();
      frame->set_iid(interned.iid);
      frame->set_function_name_id(interned.data[0]);
      if (interned.data[1] != 0) {
        frame->set_mapping_id(interned.data[1]);
      }
    });
  }

#define DEFINE_GETTER(name, ignored)                                           \
  perfetto_utils::StringInterner<Malloc>& name() { return name##_; }
  PERFETTO_INTERNED_STRINGS_FIELDS_LIST(DEFINE_GETTER)
#undef DEFINE_GETTER

#define DEFINE_GETTER(name, element_type)                                      \
  perfetto_utils::BytesInterner<element_type, Malloc>& name() {                \
    return name##_;                                                            \
  }
  PERFETTO_INTERNED_RAW_BYTES_FIELDS_LIST(DEFINE_GETTER)
#undef DEFINE_GETTER

#define DEFINE_GETTER_FOR_COMMON_STRING(category, str)                         \
  uint64_t iid_##str() {                                                       \
    if (iid_##str##_ == 0) {                                                   \
      iid_##str##_ = category().Intern(#str);                                  \
    }                                                                          \
    return iid_##str##_;                                                       \
  }

  PERFETTO_COMMON_INTERNED_STRINGS_LIST(DEFINE_GETTER_FOR_COMMON_STRING)

#undef DEFINE_GETTER_FOR_COMMON_STRING

  uint64_t InternFormattedIsolateId(uint64_t isolate_id) {
    return InternFormattedIdForDebugAnnotation(
        isolate_id_to_iid_of_formatted_string_,
        ISOLATE_SERVICE_ID_FORMAT_STRING, isolate_id);
  }

  uint64_t InternFormattedIsolateGroupId(uint64_t isolate_group_id) {
    return InternFormattedIdForDebugAnnotation(
        isolate_group_id_to_iid_of_formatted_string_,
        ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING, isolate_group_id);
  }

 private:
  template <std::size_t kFormatLen>
  uint64_t InternFormattedIdForDebugAnnotation(IdToIidMap& cache,
                                               const char (&format)[kFormatLen],
                                               uint64_t id) {
    if (auto iid = cache.Lookup(id)) {
      return iid->formatted_iid;
    }

    // 20 characters is enough to format any uint64_t (or int64_t) value.
    char formatted[kFormatLen + 20];
    Utils::SNPrint(formatted, ARRAY_SIZE(formatted), format, id);

    auto formatted_iid = debug_annotation_string_values().Intern(formatted);
    cache.Insert({id, formatted_iid});
    return formatted_iid;
  }

  // Returns the union of state of all interners.
  InternerStateBits TakeAndResetStateOfAllInterners() {
    InternerStateBits result = 0;

#define TAKE_AND_RESET(name, ignored) result |= name##_.TakeAndResetState();

    PERFETTO_INTERNED_STRINGS_FIELDS_LIST(TAKE_AND_RESET)
    PERFETTO_INTERNED_RAW_BYTES_FIELDS_LIST(TAKE_AND_RESET)
#undef TAKE_AND_RESET

    return result;
  }

  uint32_t sequence_flags_ = SequenceFlags::SEQ_INCREMENTAL_STATE_CLEARED |
                             SequenceFlags::SEQ_NEEDS_INCREMENTAL_STATE;

  // These are interned in debug_annotation_string_values space.
  IdToIidMap isolate_id_to_iid_of_formatted_string_;
  IdToIidMap isolate_group_id_to_iid_of_formatted_string_;

#define DEFINE_FIELD_FOR_COMMON_STRING(category, str) uint64_t iid_##str##_ = 0;

  PERFETTO_COMMON_INTERNED_STRINGS_LIST(DEFINE_FIELD_FOR_COMMON_STRING)

#undef DEFINE_FIELD_FOR_COMMON_STRING

#define DEFINE_FIELD(name, proto_field)                                        \
  perfetto_utils::StringInterner<Malloc> name##_;
  PERFETTO_INTERNED_STRINGS_FIELDS_LIST(DEFINE_FIELD)
#undef DEFINE_FIELD

#define DEFINE_FIELD(name, element_type)                                       \
  perfetto_utils::BytesInterner<element_type, Malloc> name##_;
  PERFETTO_INTERNED_RAW_BYTES_FIELDS_LIST(DEFINE_FIELD)
#undef DEFINE_FIELD

  DISALLOW_COPY_AND_ASSIGN(InternedDataBuilder);
};

}  // namespace perfetto_utils

}  // namespace dart

#endif  // defined(SUPPORT_PERFETTO)

#endif  // RUNTIME_VM_PERFETTO_UTILS_H_
