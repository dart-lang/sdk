// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_inliner.h"

#include "vm/assert.h"
#include "vm/compiler.h"
#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_optimizer.h"
#include "vm/il_printer.h"
#include "vm/intrinsifier.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, trace_inlining, false, "Trace inlining");
DEFINE_FLAG(charp, inlining_filter, NULL, "Inline only in named function");
DEFINE_FLAG(int, inlining_size_threshold, 250,
    "Inline only functions with up to threshold instructions");
DEFINE_FLAG(bool, inline_control_flow, true,
    "Inline functions with control flow.");
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(int, deoptimization_counter_threshold);

#define TRACE_INLINING(statement)                                              \
  do {                                                                         \
    if (FLAG_trace_inlining) statement;                                        \
  } while (false)


// Test if a call is recursive by looking in the deoptimization environment.
static bool IsCallRecursive(const Function& function, Definition* call) {
  Environment* env = call->env();
  while (env != NULL) {
    if (function.raw() == env->function().raw()) return true;
    env = env->outer();
  }
  return false;
}


class CallSiteInliner : public FlowGraphVisitor {
 public:
  explicit CallSiteInliner(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->postorder()),
        caller_graph_(flow_graph),
        next_ssa_temp_index_(flow_graph->max_virtual_register_number()),
        inlined_(false),
        initial_size_(flow_graph->InstructionCount()),
        inlined_size_(0),
        static_calls_(),
        closure_calls_(),
        instance_calls_() { }

  void VisitClosureCall(ClosureCallInstr* call) {
    closure_calls_.Add(call);
  }

  void VisitPolymorphicInstanceCall(PolymorphicInstanceCallInstr* call) {
    instance_calls_.Add(call);
  }

  void VisitStaticCall(StaticCallInstr* call) {
    if (call->function().is_inlinable()) static_calls_.Add(call);
  }

  void FindCallSites() {
    VisitBlocks();
  }

  void InlineCalls() {
    InlineStaticCalls();
    InlineClosureCalls();
    InlineInstanceCalls();
  }

  bool inlined() const { return inlined_; }

  double GrowthFactor() const {
    return static_cast<double>(inlined_size_) /
        static_cast<double>(initial_size_);
  }

 private:
  bool TryInlining(const Function& function,
                   GrowableArray<Value*>* arguments,
                   Definition* call) {
    TRACE_INLINING(OS::Print("  => %s\n", function.ToCString()));

    // Abort if the inlinable bit on the function is low.
    if (!function.is_inlinable()) {
      TRACE_INLINING(OS::Print("     Bailout: not inlinable\n"));
      return false;
    }

    // Abort if the callee has optional parameters.
    if (function.HasOptionalParameters()) {
      TRACE_INLINING(OS::Print("     Bailout: optional parameters\n"));
      return false;
    }

    // Assuming no optional parameters the actual/formal count should match.
    ASSERT(arguments->length() == function.num_fixed_parameters());

    // Abort if this function has deoptimized too much.
    if (function.deoptimization_counter() >=
        FLAG_deoptimization_counter_threshold) {
      function.set_is_inlinable(false);
      TRACE_INLINING(OS::Print("     Bailout: deoptimization threshold\n"));
      return false;
    }

    // Abort if this is a recursive occurrence.
    if (IsCallRecursive(function, call)) {
      function.set_is_inlinable(false);
      TRACE_INLINING(OS::Print("     Bailout: recursive function\n"));
      return false;
    }

    // Abort if the callee has an intrinsic translation.
    if (Intrinsifier::CanIntrinsify(function)) {
      function.set_is_inlinable(false);
      TRACE_INLINING(OS::Print("     Bailout: can intrinsify\n"));
      return false;
    }

    Isolate* isolate = Isolate::Current();
    // Save and clear IC data.
    const Array& prev_ic_data = Array::Handle(isolate->ic_data_array());
    isolate->set_ic_data_array(Array::null());
    // Save and clear deopt id.
    const intptr_t prev_deopt_id = isolate->deopt_id();
    isolate->set_deopt_id(0);
    // Install bailout jump.
    LongJump* base = isolate->long_jump_base();
    LongJump jump;
    isolate->set_long_jump_base(&jump);
    if (setjmp(*jump.Set()) == 0) {
      // Parse the callee function.
      ParsedFunction parsed_function(function);
      Parser::ParseFunction(&parsed_function);
      parsed_function.AllocateVariables();

      // Load IC data for the callee.
      if (function.HasCode()) {
        const Code& unoptimized_code =
            Code::Handle(function.unoptimized_code());
        isolate->set_ic_data_array(unoptimized_code.ExtractTypeFeedbackArray());
      }

      // Build the callee graph.
      FlowGraphBuilder builder(parsed_function);
      builder.SetInitialBlockId(caller_graph_->max_block_id());
      FlowGraph* callee_graph =
          builder.BuildGraph(FlowGraphBuilder::kValueContext);

      // Abort if the callee graph contains control flow.
      if ((callee_graph->preorder().length() != 2) &&
          !FLAG_inline_control_flow) {
        function.set_is_inlinable(false);
        isolate->set_long_jump_base(base);
        isolate->set_ic_data_array(prev_ic_data.raw());
        TRACE_INLINING(OS::Print("     Bailout: control flow\n"));
        return false;
      }

      // Compute SSA on the callee graph, catching bailouts.
      callee_graph->ComputeSSA(next_ssa_temp_index_);
      callee_graph->ComputeUseLists();

      // TODO(zerny): Do more optimization passes on the callee graph.
      FlowGraphOptimizer optimizer(callee_graph);
      optimizer.ApplyICData();
      callee_graph->ComputeUseLists();

      if (FLAG_trace_inlining && FLAG_print_flow_graph) {
        OS::Print("Callee graph for inlining %s\n",
                  parsed_function.function().ToFullyQualifiedCString());
        FlowGraphPrinter printer(*callee_graph);
        printer.PrintBlocks();
      }

      // If result is more than size threshold then abort.
      // TODO(zerny): Do this after CP and dead code elimination.
      intptr_t size = callee_graph->InstructionCount();
      if (size > FLAG_inlining_size_threshold) {
        function.set_is_inlinable(false);
        isolate->set_long_jump_base(base);
        isolate->set_deopt_id(prev_deopt_id);
        isolate->set_ic_data_array(prev_ic_data.raw());
        TRACE_INLINING(OS::Print("     Bailout: graph size %"Pd"\n", size));
        return false;
      }

      // TODO(zerny): If effort is less than threshold then inline recursively.

      // Plug result in the caller graph.
      caller_graph_->InlineCall(call, callee_graph);
      next_ssa_temp_index_ = caller_graph_->max_virtual_register_number();

      // Remove push arguments of the call.
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->ArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }

      // Replace formal parameters with actuals.
      intptr_t arg_index = 0;
      GrowableArray<Definition*>* defns =
          callee_graph->graph_entry()->initial_definitions();
      for (intptr_t i = 0; i < defns->length(); ++i) {
        ParameterInstr* param = (*defns)[i]->AsParameter();
        if (param != NULL) {
          param->ReplaceUsesWith((*arguments)[arg_index++]->definition());
        }
      }
      ASSERT(arg_index == arguments->length());

      // Replace callee's null constant with caller's null constant.
      callee_graph->graph_entry()->constant_null()->ReplaceUsesWith(
          caller_graph_->graph_entry()->constant_null());

      TRACE_INLINING(OS::Print("     Success\n"));

      // Check that inlining maintains use lists.
      SLOW_ASSERT(caller_graph_->ValidateUseLists());

      // Build succeeded so we restore the bailout jump.
      inlined_ = true;
      inlined_size_ += size;
      isolate->set_long_jump_base(base);
      isolate->set_deopt_id(prev_deopt_id);
      isolate->set_ic_data_array(prev_ic_data.raw());
      return true;
    } else {
      Error& error = Error::Handle();
      error = isolate->object_store()->sticky_error();
      isolate->object_store()->clear_sticky_error();
      isolate->set_long_jump_base(base);
      isolate->set_deopt_id(prev_deopt_id);
      isolate->set_ic_data_array(prev_ic_data.raw());
      TRACE_INLINING(OS::Print("     Bailout: %s\n", error.ToErrorCString()));
      return false;
    }
  }

  void InlineStaticCalls() {
    TRACE_INLINING(OS::Print("  Static Calls (%d)\n",
                             static_calls_.length()));
    for (intptr_t i = 0; i < static_calls_.length(); ++i) {
      StaticCallInstr* call = static_calls_[i];
      GrowableArray<Value*> arguments(call->ArgumentCount());
      for (int i = 0; i < call->ArgumentCount(); ++i) {
        arguments.Add(call->ArgumentAt(i)->value());
      }
      TryInlining(call->function(), &arguments, call);
    }
  }

  void InlineClosureCalls() {
    TRACE_INLINING(OS::Print("  Closure Calls (%d)\n",
                             closure_calls_.length()));
    for (intptr_t i = 0; i < closure_calls_.length(); ++i) {
      ClosureCallInstr* call = closure_calls_[i];
      // Find the closure of the callee.
      ASSERT(call->ArgumentCount() > 0);
      const CreateClosureInstr* closure =
          call->ArgumentAt(0)->value()->definition()->AsCreateClosure();
      if (closure == NULL) {
        TRACE_INLINING(OS::Print("     Bailout: non-closure operator\n"));
        continue;
      }
      GrowableArray<Value*> arguments(call->ArgumentCount() - 1);
      for (int i = 1; i < call->ArgumentCount(); ++i) {
        arguments.Add(call->ArgumentAt(i)->value());
      }
      TryInlining(closure->function(), &arguments, call);
    }
  }

  void InlineInstanceCalls() {
    TRACE_INLINING(OS::Print("  Polymorphic Instance Calls (%d)\n",
                             instance_calls_.length()));
    for (intptr_t i = 0; i < instance_calls_.length(); ++i) {
      PolymorphicInstanceCallInstr* instr = instance_calls_[i];
      const ICData& ic_data = instr->ic_data();
      const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));
      if (instr->with_checks()) {
        TRACE_INLINING(OS::Print("     Bailout: %"Pd" checks target '%s'\n",
                                 ic_data.NumberOfChecks(),
                                 target.ToCString()));
        continue;
      }
      GrowableArray<Value*> arguments(instr->ArgumentCount());
      for (int i = 0; i < instr->ArgumentCount(); ++i) {
        arguments.Add(instr->ArgumentAt(i)->value());
      }
      TryInlining(target, &arguments, instr);
    }
  }

  FlowGraph* caller_graph_;
  intptr_t next_ssa_temp_index_;
  bool inlined_;
  intptr_t initial_size_;
  intptr_t inlined_size_;

  GrowableArray<StaticCallInstr*> static_calls_;
  GrowableArray<ClosureCallInstr*> closure_calls_;
  GrowableArray<PolymorphicInstanceCallInstr*> instance_calls_;
};


void FlowGraphInliner::Inline() {
  if ((FLAG_inlining_filter != NULL) &&
      (strstr(flow_graph_->
              parsed_function().function().ToFullyQualifiedCString(),
              FLAG_inlining_filter) == NULL)) {
    return;
  }

  TRACE_INLINING(OS::Print(
      "Inlining calls in %s\n",
      flow_graph_->parsed_function().function().ToCString()));

  if (FLAG_trace_inlining && FLAG_print_flow_graph) {
    OS::Print("Before Inlining of %s\n", flow_graph_->
              parsed_function().function().ToFullyQualifiedCString());
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }

  CallSiteInliner inliner(flow_graph_);
  inliner.FindCallSites();
  inliner.InlineCalls();

  if (inliner.inlined()) {
    if (FLAG_trace_inlining) {
      OS::Print("Inlining growth factor: %f\n", inliner.GrowthFactor());
      if (FLAG_print_flow_graph) {
        OS::Print("After Inlining of %s\n", flow_graph_->
                  parsed_function().function().ToFullyQualifiedCString());
        FlowGraphPrinter printer(*flow_graph_);
        printer.PrintBlocks();
      }
    }
  }
}

}  // namespace dart
