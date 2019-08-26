// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_DESERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_DESERIALIZER_H_

#include "platform/assert.h"

#include "vm/allocation.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/sexpression.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/parser.h"
#include "vm/thread.h"
#include "vm/zone.h"

namespace dart {

// Deserializes FlowGraphs from S-expressions.
class FlowGraphDeserializer : ValueObject {
 public:
  // Returns the first instruction that is guaranteed not to be handled by
  // the current implementation of the FlowGraphDeserializer. This way,
  // we can filter out graphs that are guaranteed not to be deserializable
  // before going through the round-trip serialization process.
  //
  // Note that there may be other reasons that the deserializer may fail on
  // a given flow graph, so getting back nullptr here is necessary, but not
  // sufficient, for a successful round-trip pass.
  static Instruction* FirstUnhandledInstruction(const FlowGraph* graph);

  // Takes the FlowGraph from [state] and runs it through the serializer
  // and deserializer. If the deserializer successfully deserializes the
  // graph, then the FlowGraph in [state] is replaced with the new one.
  static void RoundTripSerialization(CompilerPassState* state);

  FlowGraphDeserializer(Thread* thread,
                        Zone* zone,
                        SExpression* root,
                        const ParsedFunction* pf)
      : thread_(thread),
        zone_(zone),
        root_sexp_(ASSERT_NOTNULL(root)),
        parsed_function_(pf) {}

  // Walks [root_sexp_] and constructs a new FlowGraph.
  FlowGraph* ParseFlowGraph();

  const char* error_message() const { return error_message_; }
  SExpression* error_sexp() const { return error_sexp_; }

  // Prints the current error information to stderr and aborts.
  DART_NORETURN void ReportError() const;

 private:
  // Stores appropriate error information using the SExpression as the location
  // and the rest of the arguments as an error message for the user.
  void StoreError(SExpression* s, const char* fmt, ...) PRINTF_ATTRIBUTE(3, 4);

  Thread* thread() const { return thread_; }
  Zone* zone() const { return zone_; }

  Thread* const thread_;
  Zone* const zone_;
  SExpression* const root_sexp_;
  const ParsedFunction* parsed_function_;

  // Stores a message appropriate to surfacing to the user when an error
  // occurs.
  const char* error_message_ = nullptr;
  // Stores the location of the deserialization error by containing the
  // S-expression which caused the failure.
  SExpression* error_sexp_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphDeserializer);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_DESERIALIZER_H_
