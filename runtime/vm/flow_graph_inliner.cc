// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_inliner.h"

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
    "Inline only functions with up to threshold instructions (default 250)");
DEFINE_FLAG(int, inlining_depth_threshold, 1,
    "Inline recursively up to threshold depth (default 1)");
DEFINE_FLAG(bool, inline_control_flow, true,
    "Inline functions with control flow.");
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(int, deoptimization_counter_threshold);
DECLARE_FLAG(bool, verify_compiler);

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


// A collection of call sites to consider for inlining.
class CallSites : public FlowGraphVisitor {
 public:
  explicit CallSites(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->postorder()),  // We don't use this order.
        static_calls_(),
        closure_calls_(),
        instance_calls_() { }

  GrowableArray<StaticCallInstr*>* static_calls() {
    return &static_calls_;
  }

  GrowableArray<ClosureCallInstr*>* closure_calls() {
    return &closure_calls_;
  }

  GrowableArray<PolymorphicInstanceCallInstr*>* instance_calls() {
    return &instance_calls_;
  }

  bool HasCalls() const {
    return !(static_calls_.is_empty() &&
             closure_calls_.is_empty() &&
             instance_calls_.is_empty());
  }

  void Clear() {
    static_calls_.Clear();
    closure_calls_.Clear();
    instance_calls_.Clear();
  }

  void FindCallSites(FlowGraph* graph) {
    for (BlockIterator block_it = graph->postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      for (ForwardInstructionIterator it(block_it.Current());
           !it.Done();
           it.Advance()) {
        it.Current()->Accept(this);
      }
    }
  }

  void VisitClosureCall(ClosureCallInstr* call) {
    closure_calls_.Add(call);
  }

  void VisitPolymorphicInstanceCall(PolymorphicInstanceCallInstr* call) {
    instance_calls_.Add(call);
  }

  void VisitStaticCall(StaticCallInstr* call) {
    if (call->function().is_inlinable()) static_calls_.Add(call);
  }

 private:
  GrowableArray<StaticCallInstr*> static_calls_;
  GrowableArray<ClosureCallInstr*> closure_calls_;
  GrowableArray<PolymorphicInstanceCallInstr*> instance_calls_;

  DISALLOW_COPY_AND_ASSIGN(CallSites);
};


class CallSiteInliner : public ValueObject {
 public:
  explicit CallSiteInliner(FlowGraph* flow_graph)
      : caller_graph_(flow_graph),
        next_ssa_temp_index_(flow_graph->max_virtual_register_number()),
        inlined_(false),
        initial_size_(flow_graph->InstructionCount()),
        inlined_size_(0),
        inlining_depth_(1),
        collected_call_sites_(NULL),
        inlining_call_sites_(NULL) { }

  void InlineCalls() {
    // If inlining depth is less then one abort.
    if (FLAG_inlining_depth_threshold < 1) return;
    // Create two call site collections to swap between.
    CallSites sites1(caller_graph_);
    CallSites sites2(caller_graph_);
    CallSites* call_sites_temp = NULL;
    collected_call_sites_ = &sites1;
    inlining_call_sites_ = &sites2;
    // Collect initial call sites.
    collected_call_sites_->FindCallSites(caller_graph_);
    while (collected_call_sites_->HasCalls()) {
      TRACE_INLINING(OS::Print("  Depth %"Pd" ----------\n", inlining_depth_));
      // Swap collected and inlining arrays and clear the new collecting array.
      call_sites_temp = collected_call_sites_;
      collected_call_sites_ = inlining_call_sites_;
      inlining_call_sites_ = call_sites_temp;
      collected_call_sites_->Clear();
      // Inline call sites at the current depth.
      InlineStaticCalls();
      InlineClosureCalls();
      InlineInstanceCalls();
      // Increment the inlining depth. Checked before recursive inlining.
      ++inlining_depth_;
    }
    collected_call_sites_ = NULL;
    inlining_call_sites_ = NULL;
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
    TRACE_INLINING(OS::Print("  => %s (deopt count %d)\n",
                             function.ToCString(),
                             function.deoptimization_counter()));

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
      if (!FLAG_inline_control_flow &&
          (callee_graph->preorder().length() != 2)) {
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

      // If depth is less or equal to threshold recursively add call sites.
      if (inlining_depth_ < FLAG_inlining_depth_threshold) {
        collected_call_sites_->FindCallSites(callee_graph);
      }

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
      DEBUG_ASSERT(!FLAG_verify_compiler || caller_graph_->ValidateUseLists());

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
    const GrowableArray<StaticCallInstr*>& calls =
        *inlining_call_sites_->static_calls();
    TRACE_INLINING(OS::Print("  Static Calls (%d)\n", calls.length()));
    for (intptr_t i = 0; i < calls.length(); ++i) {
      StaticCallInstr* call = calls[i];
      GrowableArray<Value*> arguments(call->ArgumentCount());
      for (int i = 0; i < call->ArgumentCount(); ++i) {
        arguments.Add(call->ArgumentAt(i)->value());
      }
      TryInlining(call->function(), &arguments, call);
    }
  }

  void InlineClosureCalls() {
    const GrowableArray<ClosureCallInstr*>& calls =
        *inlining_call_sites_->closure_calls();
    TRACE_INLINING(OS::Print("  Closure Calls (%d)\n", calls.length()));
    for (intptr_t i = 0; i < calls.length(); ++i) {
      ClosureCallInstr* call = calls[i];
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
    const GrowableArray<PolymorphicInstanceCallInstr*>& calls =
        *inlining_call_sites_->instance_calls();
    TRACE_INLINING(OS::Print("  Polymorphic Instance Calls (%d)\n",
                             calls.length()));
    for (intptr_t i = 0; i < calls.length(); ++i) {
      PolymorphicInstanceCallInstr* instr = calls[i];
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
  intptr_t inlining_depth_;
  CallSites* collected_call_sites_;
  CallSites* inlining_call_sites_;

  DISALLOW_COPY_AND_ASSIGN(CallSiteInliner);
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
