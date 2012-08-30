// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_inliner.h"

#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_builder.h"
#include "vm/il_printer.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, trace_inlining, false, "Trace inlining");
DEFINE_FLAG(charp, inlining_filter, NULL, "Inline only in named function");
DECLARE_FLAG(bool, print_flow_graph);

class CallSiteInliner : public FlowGraphVisitor {
 public:
  explicit CallSiteInliner(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->postorder()),
        caller_graph_(flow_graph),
        next_ssa_temp_index_(flow_graph->max_virtual_register_number()),
        inlined_(false) { }

  void TryInlining(const Function& function,
                   GrowableArray<Value*>* arguments,
                   StaticCallComp* comp,  // TODO(zerny): Generalize to calls.
                   BindInstr* instr) {
    // Abort if the callee has named parameters.
    if (function.num_optional_parameters() > 0) {
      if (FLAG_trace_inlining) {
        OS::Print("Inline aborted %s\nReason: optional parameters\n",
                  function.ToFullyQualifiedCString());
      }
      return;
    }

    // Assuming no optional parameters the actual/formal count should match.
    ASSERT(arguments->length() == function.num_fixed_parameters());

    Isolate* isolate = Isolate::Current();
    // Save and clear IC data.
    const Array& old_ic_data = Array::Handle(isolate->ic_data_array());
    isolate->set_ic_data_array(Array::null());
    // Install bailout jump.
    LongJump* base = isolate->long_jump_base();
    LongJump jump;
    isolate->set_long_jump_base(&jump);
    if (setjmp(*jump.Set()) == 0) {
      // Parse the callee function.
      ParsedFunction parsed_function(function);
      Parser::ParseFunction(&parsed_function);
      FlowGraphBuilder builder(parsed_function);

      // Build the callee graph.
      FlowGraph* callee_graph =
          builder.BuildGraphForInlining(FlowGraphBuilder::kValueContext);

      // Abort if the callee graph contains control flow.
      if (callee_graph->preorder().length() != 2) {
        isolate->set_long_jump_base(base);
        isolate->set_ic_data_array(old_ic_data.raw());
        if (FLAG_trace_inlining) {
          OS::Print("Inline aborted %s\nReason: control flow\n",
                    parsed_function.function().ToFullyQualifiedCString());
        }
        return;
      }

      if (FLAG_trace_inlining && FLAG_print_flow_graph) {
        OS::Print("Callee graph before SSA %s\n",
                  parsed_function.function().ToFullyQualifiedCString());
        FlowGraphPrinter printer(*callee_graph);
        printer.PrintBlocks();
      }

      // Compute SSA on the callee graph. (catching bailouts)
      callee_graph->ComputeSSA(next_ssa_temp_index_);

      if (FLAG_trace_inlining && FLAG_print_flow_graph) {
        OS::Print("Callee graph after SSA %s\n",
                  parsed_function.function().ToFullyQualifiedCString());
        FlowGraphPrinter printer(*callee_graph);
        printer.PrintBlocks();
      }

      callee_graph->ComputeUseLists();

      // TODO(zerny): Do optimization passes on the callee graph.

      // TODO(zerny): If result is more than size threshold then abort.

      // TODO(zerny): If effort is less than threshold then inline recursively.

      // Plug result in the caller graph.
      caller_graph_->InlineCall(instr, comp, callee_graph);
      next_ssa_temp_index_ = caller_graph_->max_virtual_register_number();

      // Replace all the formal parameters with the actuals.
      for (intptr_t i = 0; i < arguments->length(); ++i) {
        Value* val = callee_graph->graph_entry()->start_env()->values()[i];
        ParameterInstr* param = val->definition()->AsParameter();
        ASSERT(param != NULL);
        param->ReplaceUsesWith((*arguments)[i]->definition());
      }

      if (FLAG_trace_inlining) {
        OS::Print("Inlined %s\n", function.ToFullyQualifiedCString());
      }

      // Build succeeded so we restore the bailout jump.
      inlined_ = true;
      isolate->set_long_jump_base(base);
      isolate->set_ic_data_array(old_ic_data.raw());
    } else {
      Error& error = Error::Handle();
      error = isolate->object_store()->sticky_error();
      isolate->object_store()->clear_sticky_error();
      isolate->set_long_jump_base(base);
      isolate->set_ic_data_array(old_ic_data.raw());
      if (FLAG_trace_inlining) {
        OS::Print("Inline aborted for %s\nReason: %s\n",
                  function.ToFullyQualifiedCString(),
                  error.ToErrorCString());
      }
    }
  }

  void VisitBind(BindInstr* instr) {
    instr->computation()->Accept(this, instr);
  }

  void VisitStaticCall(StaticCallComp* comp, BindInstr* instr) {
    if (FLAG_trace_inlining) OS::Print("Static call\n");
    GrowableArray<Value*> arguments(comp->ArgumentCount());
    for (int i = 0; i < comp->ArgumentCount(); ++i) {
      arguments.Add(comp->ArgumentAt(i)->value());
    }
    TryInlining(comp->function(), &arguments, comp, instr);
  }

  bool preformed_inlining() const { return inlined_; }

 private:
  FlowGraph* caller_graph_;
  intptr_t next_ssa_temp_index_;
  bool inlined_;
};


void FlowGraphInliner::Inline() {
  if ((FLAG_inlining_filter != NULL) &&
      (strstr(flow_graph_->
              parsed_function().function().ToFullyQualifiedCString(),
              FLAG_inlining_filter) == NULL)) {
    return;
  }

  if (FLAG_trace_inlining && FLAG_print_flow_graph) {
    OS::Print("Before Inlining of %s\n", flow_graph_->
              parsed_function().function().ToFullyQualifiedCString());
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }

  CallSiteInliner inliner(flow_graph_);
  inliner.VisitBlocks();

  if (inliner.preformed_inlining()) {
    if (FLAG_trace_inlining && FLAG_print_flow_graph) {
      OS::Print("After Inlining of %s\n", flow_graph_->
                parsed_function().function().ToFullyQualifiedCString());
      FlowGraphPrinter printer(*flow_graph_);
      printer.PrintBlocks();
    }
  }
}

}  // namespace dart
