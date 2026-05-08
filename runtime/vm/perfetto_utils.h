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

// Sequence of |length| elements of type |T|.
//
// These elements are treated as raw bytes for the purpose of equality and
// hashing.
template <typename T>
struct Span {
  const T* const data;
  intptr_t length;

  template <typename Allocator>
  Span<T> Copy(Allocator* allocator) const {
    T* copy = allocator->template Alloc<T>(length);
    memcpy(copy, data, length * sizeof(T));  // NOLINT
    return {copy, length};
  }

  template <typename Allocator>
  void Dispose(Allocator* allocator) const {
    if constexpr (Allocator::kSupportsFreeingIndividualAllocations) {
      allocator->Free(const_cast<T*>(data), length);
    }
  }

  bool Equals(const Span& other) const {
    if (length != other.length) {
      return false;
    }
    return memcmp(data, other.data, length * sizeof(T)) == 0;
  }

  uword Hash() const {
    return HashBytes(reinterpret_cast<const uint8_t*>(data),
                     length * sizeof(T));
  }
};

template <typename T, typename Allocator>
concept DefinesCopyAndDispose = requires(const T& a, Allocator* allocator) {
  { a.Copy(allocator) } -> std::same_as<T>;
  { a.Dispose(allocator) } -> std::same_as<void>;
};

// Sequence of elements which can be interned by |BytesInterner|.
//
// Equality and hash are defined in terms of raw byte content.
template <typename T>
struct Interned {
  explicit Interned(const T& data)
      : data(data), hash(ComputeHash(data)), iid(0) {}

  Interned(const T& data, uword hash, uint64_t iid)
      : data(data), hash(hash), iid(iid) {}

  bool Equals(const Interned& other) const {
    if constexpr (DefinesHashAndEquality<T>) {
      return data.Equals(other.data);
    } else {
      return memcmp(&data, &other.data, sizeof(T)) == 0;
    }
  }

  static uword ComputeHash(const T& data) {
    if constexpr (DefinesHashAndEquality<T>) {
      return data.Hash();
    } else {
      return HashBytes(reinterpret_cast<const uint8_t*>(&data), sizeof(T));
    }
  }

  uword Hash() const { return hash; }

  const T data;
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
class Interner
    : public BaseDirectChainedHashMap<PointerSetKeyValueTrait<Interned<T>>,
                                      ValueObject,
                                      Allocator> {
  using Base = BaseDirectChainedHashMap<PointerSetKeyValueTrait<Interned<T>>,
                                        ValueObject,
                                        Allocator>;

 public:
  explicit Interner(Allocator* allocator = nullptr) : Base(allocator) {}

  ~Interner() {
    if constexpr (Allocator::kSupportsFreeingIndividualAllocations) {
      auto it = Base::GetIterator();
      while (auto pair = it.Next()) {
        Dispose(*pair);
      }
    }
  }

  uint64_t Lookup(const T& data) {
    Interned<T> key(data);
    if (auto interned = Base::Lookup(&key)) {
      return (*interned)->iid;
    }
    return 0;
  }

  uint64_t Intern(const T& data) {
    state_ |= kInternerWasUsed;

    Interned<T> key(data);
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
      auto pair = Base::pairs_[i];
      callback(pair->iid, pair->data);
    }
    first_to_flush_ = Base::next_pair_index_;
  }

  InternerStateBits TakeAndResetState() {
    const auto result = state_;
    state_ = 0;
    return result;
  }

  Interned<T>** begin() { return &Base::pairs_[0]; }
  Interned<T>** end() { return &Base::pairs_[Base::next_pair_index_]; }

  const Interned<T>** begin() const { return &Base::pairs_[0]; }
  const Interned<T>** end() const {
    return &Base::pairs_[Base::next_pair_index_];
  }

  const T& GetByIid(uint64_t iid) const { return Base::pairs_[iid - 1]->data; }

 private:
  Allocator* allocator() const { return Base::allocator_; }

  Interned<T>* Copy(const Interned<T>& interned, uint64_t iid) const {
    auto copy = allocator()->template Alloc<Interned<T>>(1);
    if constexpr (DefinesCopyAndDispose<T, Allocator>) {
      new (copy)
          Interned<T>(interned.data.Copy(allocator()), interned.hash, iid);
    } else {
      new (copy) Interned<T>(interned.data, interned.hash, iid);
    }
    return copy;
  }

  void Dispose(Interned<T>* interned) {
    if constexpr (Allocator::kSupportsFreeingIndividualAllocations) {
      if constexpr (DefinesCopyAndDispose<T, Allocator>) {
        interned->data.Dispose(allocator());
      }
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

  uint64_t Lookup(const char* str) {
    return bytes_interner_.Lookup(
        {str, static_cast<intptr_t>(strlen(str) + 1)});
  }

  uint64_t Intern(const char* str) {
    // +1 to include terminating NUL character.
    return bytes_interner_.Intern(
        {str, static_cast<intptr_t>(strlen(str) + 1)});
  }

  InternerStateBits TakeAndResetState() {
    return bytes_interner_.TakeAndResetState();
  }

  template <typename F>
  void FlushNewlyInternedTo(F&& callback) {
    bytes_interner_.FlushNewlyInternedTo(
        [callback = std::move(callback)](auto iid, const auto& span) {
          callback(iid, span.data);
        });
  }

  const char* GetByIid(uint64_t iid) const {
    return bytes_interner_.GetByIid(iid).data;
  }

  Interned<Span<char>>** begin() { return bytes_interner_.begin(); }
  Interned<Span<char>>** end() { return bytes_interner_.end(); }

  const Interned<Span<char>>** begin() const { return bytes_interner_.begin(); }
  const Interned<Span<char>>** end() const { return bytes_interner_.end(); }

 private:
  Interner<Span<char>, Allocator> bytes_interner_;
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

  enum class UnknownMappingState { kNotNeeded, kNeeded, kEmitted };

 public:
  struct Mapping {
    uint64_t start;
    uint64_t end;
    uint64_t offset;
    uint64_t path_string;
    uint64_t build_id;
  };

  // Each frame is either eagerly symbolized or not. For eagerly symbolized
  // frames rel_pc is set to kEagerlySymbolizedFramePc and function_name_iid
  // is set to the iid of the function name. For non-eagerly symbolized frames
  // rel_pc is set to the relative pc and function_name_iid might or might
  // not be set.
  //
  // We assume that depending on the writer all frames are either eagerly
  // symbolized or not.
  struct Frame {
    static constexpr uint64_t kEagerlySymbolizedFramePc = kMaxUint64;

    uint64_t rel_pc = kEagerlySymbolizedFramePc;
    uint32_t mapping_iid = 0;
    uint32_t function_name_iid = 0;

    bool Equals(const Frame& other) const {
      // We assume symbolization mode is consistent: either all frames
      // have rel_pc set to kEagerlySymbolizedFramePc or none of them do.
      if (rel_pc == kEagerlySymbolizedFramePc) {
        return mapping_iid == other.mapping_iid &&
               function_name_iid == other.function_name_iid;
      }
      return mapping_iid == other.mapping_iid && rel_pc == other.rel_pc;
    }

    uword Hash() const {
      if (rel_pc == kEagerlySymbolizedFramePc) {
        return CombineHashes(Utils::WordHash(mapping_iid),
                             Utils::WordHash(function_name_iid));
      } else {
        return CombineHashes(Utils::WordHash(mapping_iid),
                             Utils::WordHash(rel_pc));
      }
    }
  };

  // InternedData contains multiple independent interning dictionaries which
  // are used for different attributes.
#define PERFETTO_INTERNED_STRINGS_FIELDS_LIST(V)                               \
  V(event_categories, name)                                                    \
  V(event_names, name)                                                         \
  V(debug_annotation_names, name)                                              \
  V(debug_annotation_string_values, str)                                       \
  V(function_names, str)                                                       \
  V(mapping_paths, str)                                                        \
  V(build_ids, str)

#define PERFETTO_INTERNED_FIELDS_LIST(V)                                       \
  V(callstacks, Span<uint64_t>)                                                \
  V(mappings, Mapping)                                                         \
  V(frames, Frame)

  // Direct access for known strings.
#define PERFETTO_COMMON_INTERNED_STRINGS_LIST(V)                               \
  V(debug_annotation_names, isolateId)                                         \
  V(debug_annotation_names, isolateGroupId)

  InternedDataBuilder() = default;

  void MarkNeedUnknownMapping() {
    if (unknown_mapping_ == UnknownMappingState::kNotNeeded) {
      unknown_mapping_ = UnknownMappingState::kNeeded;
    }
  }

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

    callstacks_.FlushNewlyInternedTo(
        [interned_data](const auto iid, const auto& stack) {
          auto callstack = interned_data->add_callstacks();
          callstack->set_iid(iid);
          for (intptr_t i = 0; i < stack.length; i++) {
            callstack->add_frame_ids(stack.data[i]);
          }
        });

    // Perfetto proto message definition claim that mapping iid 0 means
    // the same as frame not having mapping information. However Perfetto UI
    // fails to load profiles if they contain any frames without mapping iid or
    // with 0 mapping iid - but such mapping (with 0 iid) is not present in
    // interned mappings. To work-around this bug we simply emit an empty
    // mapping with 0 iid if we need it.
    if (unknown_mapping_ == UnknownMappingState::kNeeded) {
      auto mapping = interned_data->add_mappings();
      mapping->set_iid(0);
      unknown_mapping_ = UnknownMappingState::kEmitted;
    }

    mappings_.FlushNewlyInternedTo(
        [interned_data](const auto iid, const auto& data) {
          auto mapping = interned_data->add_mappings();
          mapping->set_iid(iid);
          mapping->set_start(data.start);
          mapping->set_end(data.end);
          mapping->set_start_offset(data.offset);
          mapping->add_path_string_ids(data.path_string);
          if (data.build_id != 0) {
            mapping->set_build_id(data.build_id);
          }
        });

    frames_.FlushNewlyInternedTo([interned_data](const auto iid,
                                                 const auto& data) {
      auto frame = interned_data->add_frames();
      frame->set_iid(iid);
      if (data.function_name_iid != 0) {
        frame->set_function_name_id(data.function_name_iid);
      }
      if (data.mapping_iid != 0) {
        frame->set_mapping_id(data.mapping_iid);
      }
      if (data.rel_pc != 0 && data.rel_pc != Frame::kEagerlySymbolizedFramePc) {
        frame->set_rel_pc(data.rel_pc);
      }
    });
  }

#define DEFINE_GETTER(name, ignored)                                           \
  perfetto_utils::StringInterner<Malloc>& name() { return name##_; }
  PERFETTO_INTERNED_STRINGS_FIELDS_LIST(DEFINE_GETTER)
#undef DEFINE_GETTER

#define DEFINE_GETTER(name, element_type)                                      \
  perfetto_utils::Interner<element_type, Malloc>& name() { return name##_; }
  PERFETTO_INTERNED_FIELDS_LIST(DEFINE_GETTER)
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

  uint64_t InternSyntheticBuildIdForIsolateGroup(Dart_Port isolate_group_id) {
    char build_id_string[3 + sizeof(Dart_Port) * 2 + 1];
    Utils::SNPrint(build_id_string, ARRAY_SIZE(build_id_string),
                   "ig/%016" Px64 "", isolate_group_id);
    return build_ids().Intern(build_id_string);
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
    PERFETTO_INTERNED_FIELDS_LIST(TAKE_AND_RESET)
#undef TAKE_AND_RESET

    return result;
  }

  uint32_t sequence_flags_ = SequenceFlags::SEQ_INCREMENTAL_STATE_CLEARED |
                             SequenceFlags::SEQ_NEEDS_INCREMENTAL_STATE;

  UnknownMappingState unknown_mapping_ = UnknownMappingState::kNotNeeded;

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
  perfetto_utils::Interner<element_type, Malloc> name##_;
  PERFETTO_INTERNED_FIELDS_LIST(DEFINE_FIELD)
#undef DEFINE_FIELD

  DISALLOW_COPY_AND_ASSIGN(InternedDataBuilder);
};

}  // namespace perfetto_utils

}  // namespace dart

#endif  // defined(SUPPORT_PERFETTO)

#endif  // RUNTIME_VM_PERFETTO_UTILS_H_
