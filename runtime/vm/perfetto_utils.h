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
#include "vm/json_stream.h"
#include "vm/os.h"
#include "vm/protos/perfetto/common/builtin_clock.pbzero.h"
#include "vm/protos/perfetto/trace/clock_snapshot.pbzero.h"
#include "vm/protos/perfetto/trace/trace_packet.pbzero.h"
#include "vm/protos/perfetto/trace/track_event/process_descriptor.pbzero.h"
#include "vm/protos/perfetto/trace/track_event/track_descriptor.pbzero.h"

namespace dart {

namespace perfetto_utils {

inline void SetTrustedPacketSequenceId(
    perfetto::protos::pbzero::TracePacket* packet) {
  // trusted_packet_sequence_id uniquely identifies a trace producer + writer
  // pair. We set the trusted_packet_sequence_id of all packets that we write to
  // the arbitrary value of 1.
  packet->set_trusted_packet_sequence_id(1);
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

}  // namespace perfetto_utils

}  // namespace dart

#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

#endif  // RUNTIME_VM_PERFETTO_UTILS_H_
