// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il_deserializer.h"

#include "vm/compiler/backend/il_serializer.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(bool,
            trace_round_trip_serialization,
            false,
            "Trace round trip serialization.");

void FlowGraphDeserializer::RoundTripSerialization(CompilerPassState* state) {
  auto const flow_graph = state->flow_graph;
  auto const inst =
      FlowGraphDeserializer::FirstUnhandledInstruction(flow_graph);
  if (inst != nullptr) {
    if (FLAG_trace_round_trip_serialization) {
      THR_Print("Cannot serialize graph due to instruction: %s\n",
                inst->DebugName());
    }
    return;
  }

  // The deserialized flow graph must be in the same zone as the original flow
  // graph, to ensure it has the right lifetime. Thus, we leave an explicit
  // use of [flow_graph->zone()] in the deserializer construction.
  //
  // Otherwise, it would be nice to use a StackZone to limit the lifetime of the
  // serialized form (and other values created with this [zone] variable), since
  // it only needs to live for the dynamic extent of this method.
  //
  // However, creating a StackZone for it also changes the zone associated with
  // the thread. Also, some parts of the VM used in later updates to the
  // deserializer implicitly pick up the zone to use either from a passed-in
  // thread or the current thread instead of taking an explicit zone.
  //
  // For now, just serialize into the same zone as the original flow graph, and
  // we can revisit this if this causes a performance issue or if we can ensure
  // that those VM parts mentioned can be passed an explicit zone.
  Zone* const zone = flow_graph->zone();

  auto const sexp = FlowGraphSerializer::SerializeToSExp(zone, flow_graph);
  if (FLAG_trace_round_trip_serialization) {
    THR_Print("----- Serialized flow graph:\n");
    TextBuffer buf(1000);
    sexp->SerializeTo(zone, &buf, "");
    THR_Print("%s\n", buf.buf());
    THR_Print("----- END Serialized flow graph\n");
  }

  // For the deserializer, use the thread from the compiler pass and zone
  // associated with the existing flow graph to make sure the new flow graph
  // has the right lifetime.
  FlowGraphDeserializer d(state->thread, flow_graph->zone(), sexp,
                          &flow_graph->parsed_function());
  auto const new_graph = d.ParseFlowGraph();
  if (FLAG_trace_round_trip_serialization) {
    if (new_graph == nullptr) {
      THR_Print("Failure during deserialization: %s\n", d.error_message());
      THR_Print("At S-expression %s\n", d.error_sexp()->ToCString(zone));
    } else {
      THR_Print("Successfully deserialized graph for %s\n",
                sexp->AsList()->At(1)->AsSymbol()->value());
    }
  }
  if (new_graph != nullptr) state->flow_graph = new_graph;
}

Instruction* FlowGraphDeserializer::FirstUnhandledInstruction(
    const FlowGraph* graph) {
  return graph->graph_entry();
}

FlowGraph* FlowGraphDeserializer::ParseFlowGraph() {
  StoreError(root_sexp_, "deserialization not implemented yet");
  return nullptr;
}

void FlowGraphDeserializer::StoreError(SExpression* sexp,
                                       const char* format,
                                       ...) {
  va_list args;
  va_start(args, format);
  const char* const message = OS::VSCreate(zone(), format, args);
  va_end(args);
  error_sexp_ = sexp;
  error_message_ = message;
}

void FlowGraphDeserializer::ReportError() const {
  ASSERT(error_sexp_ != nullptr);
  ASSERT(error_message_ != nullptr);
  OS::PrintErr("Unable to deserialize flow_graph: %s\n", error_message_);
  OS::PrintErr("Error at S-expression %s\n", error_sexp_->ToCString(zone()));
  OS::Abort();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
