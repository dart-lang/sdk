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

#define TRACE_INLINING(statement)                                              \
  do {                                                                         \
    if (FLAG_trace_inlining) statement;                                        \
  } while (false)


class CallSiteInliner : public FlowGraphVisitor {
 public:
  explicit CallSiteInliner(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->postorder()),
        caller_graph_(flow_graph),
        next_ssa_temp_index_(flow_graph->max_virtual_register_number()),
        inlined_(false) { }

  bool TryInlining(const Function& function,
                   GrowableArray<Value*>* arguments,
                   Definition* call) {
    TRACE_INLINING(OS::Print("  => %s\n", function.ToCString()));

    // Abort if the callee has optional parameters.
    if (function.HasOptionalParameters()) {
      TRACE_INLINING(OS::Print("     Bailout: optional parameters\n"));
      return false;
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
      parsed_function.AllocateVariables();
      FlowGraphBuilder builder(parsed_function);

      // Build the callee graph.
      FlowGraph* callee_graph =
          builder.BuildGraph(FlowGraphBuilder::kValueContext);

      // Abort if the callee graph contains control flow.
      if (callee_graph->preorder().length() != 2) {
        isolate->set_long_jump_base(base);
        isolate->set_ic_data_array(old_ic_data.raw());
        TRACE_INLINING(OS::Print("     Bailout: control flow\n"));
        return false;
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
      caller_graph_->InlineCall(call, callee_graph);
      next_ssa_temp_index_ = caller_graph_->max_virtual_register_number();

      // Remove (all) push arguments of the call.
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->ArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }

      // Replace all the formal parameters with the actuals.
      for (intptr_t i = 0; i < arguments->length(); ++i) {
        Value* val = callee_graph->graph_entry()->start_env()->ValueAt(i);
        ParameterInstr* param = val->definition()->AsParameter();
        ASSERT(param != NULL);
        param->ReplaceUsesWith((*arguments)[i]->definition());
      }

      // Replace callee's null constant with caller's null constant.
      callee_graph->graph_entry()->constant_null()->ReplaceUsesWith(
          caller_graph_->graph_entry()->constant_null());

      TRACE_INLINING(OS::Print("     Success\n"));

      // Build succeeded so we restore the bailout jump.
      inlined_ = true;
      isolate->set_long_jump_base(base);
      isolate->set_ic_data_array(old_ic_data.raw());
      return true;
    } else {
      Error& error = Error::Handle();
      error = isolate->object_store()->sticky_error();
      isolate->object_store()->clear_sticky_error();
      isolate->set_long_jump_base(base);
      isolate->set_ic_data_array(old_ic_data.raw());
      TRACE_INLINING(OS::Print("     Bailout: %s\n", error.ToErrorCString()));
      return false;
    }
  }

  void VisitClosureCall(ClosureCallInstr* call) {
    TRACE_INLINING(OS::Print("  ClosureCall\n"));
    // Find the closure of the callee.
    ASSERT(call->ArgumentCount() > 0);
    const CreateClosureInstr* closure =
        call->ArgumentAt(0)->value()->definition()->AsCreateClosure();
    if (closure == NULL) {
      TRACE_INLINING(OS::Print("     Bailout: non-closure operator\n"));
      return;
    }
    GrowableArray<Value*> arguments(call->ArgumentCount() - 1);
    for (int i = 1; i < call->ArgumentCount(); ++i) {
      arguments.Add(call->ArgumentAt(i)->value());
    }
    TryInlining(closure->function(), &arguments, call);
  }

  void VisitPolymorphicInstanceCall(PolymorphicInstanceCallInstr* instr) {
    TRACE_INLINING(OS::Print("  PolymorphicInstanceCall\n"));
    if (instr->with_checks()) {
      TRACE_INLINING(OS::Print("     Bailout: checks\n"));
      return;
    }
    const ICData& ic_data = instr->ic_data();
    const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));

    GrowableArray<Value*> arguments(instr->ArgumentCount());
    for (int i = 0; i < instr->ArgumentCount(); ++i) {
      arguments.Add(instr->ArgumentAt(i)->value());
    }

    TryInlining(target, &arguments, instr);
  }

  void VisitStaticCall(StaticCallInstr* call) {
    TRACE_INLINING(OS::Print("  StaticCall\n"));
    GrowableArray<Value*> arguments(call->ArgumentCount());
    for (int i = 0; i < call->ArgumentCount(); ++i) {
      arguments.Add(call->ArgumentAt(i)->value());
    }
    TryInlining(call->function(), &arguments, call);
  }

  bool inlined() const { return inlined_; }

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

  TRACE_INLINING(OS::Print(
      "Inlining calls in %s\n",
      flow_graph_->parsed_function().function().ToCString()));
  CallSiteInliner inliner(flow_graph_);
  inliner.VisitBlocks();

  if (inliner.inlined()) {
    if (FLAG_trace_inlining && FLAG_print_flow_graph) {
      OS::Print("After Inlining of %s\n", flow_graph_->
                parsed_function().function().ToFullyQualifiedCString());
      FlowGraphPrinter printer(*flow_graph_);
      printer.PrintBlocks();
    }
  }
}

}  // namespace dart
