// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/flow_graph_inliner.h"

#include "vm/aot_optimizer.h"
#include "vm/precompiler.h"
#include "vm/block_scheduler.h"
#include "vm/branch_optimizer.h"
#include "vm/compiler.h"
#include "vm/kernel.h"
#include "vm/kernel_to_il.h"
#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_type_propagator.h"
#include "vm/il_printer.h"
#include "vm/jit_optimizer.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(int,
            deoptimization_counter_inlining_threshold,
            12,
            "How many times we allow deoptimization before we stop inlining.");
DEFINE_FLAG(bool, trace_inlining, false, "Trace inlining");
DEFINE_FLAG(charp, inlining_filter, NULL, "Inline only in named function");

// Flags for inlining heuristics.
DEFINE_FLAG(int,
            inline_getters_setters_smaller_than,
            10,
            "Always inline getters and setters that have fewer instructions");
DEFINE_FLAG(int,
            inlining_depth_threshold,
            6,
            "Inline function calls up to threshold nesting depth");
DEFINE_FLAG(
    int,
    inlining_size_threshold,
    25,
    "Always inline functions that have threshold or fewer instructions");
DEFINE_FLAG(int,
            inlining_callee_call_sites_threshold,
            1,
            "Always inline functions containing threshold or fewer calls.");
DEFINE_FLAG(int,
            inlining_callee_size_threshold,
            80,
            "Do not inline callees larger than threshold");
DEFINE_FLAG(int,
            inlining_caller_size_threshold,
            50000,
            "Stop inlining once caller reaches the threshold.");
DEFINE_FLAG(int,
            inlining_constant_arguments_count,
            1,
            "Inline function calls with sufficient constant arguments "
            "and up to the increased threshold on instructions");
DEFINE_FLAG(
    int,
    inlining_constant_arguments_max_size_threshold,
    200,
    "Do not inline callees larger than threshold if constant arguments");
DEFINE_FLAG(int,
            inlining_constant_arguments_min_size_threshold,
            60,
            "Inline function calls with sufficient constant arguments "
            "and up to the increased threshold on instructions");
DEFINE_FLAG(int,
            inlining_hotness,
            10,
            "Inline only hotter calls, in percents (0 .. 100); "
            "default 10%: calls above-equal 10% of max-count are inlined.");
DEFINE_FLAG(int,
            inlining_recursion_depth_threshold,
            1,
            "Inline recursive function calls up to threshold recursion depth.");
DEFINE_FLAG(int,
            max_inlined_per_depth,
            500,
            "Max. number of inlined calls per depth");
DEFINE_FLAG(bool, print_inlining_tree, false, "Print inlining tree");
DEFINE_FLAG(bool,
            enable_inlining_annotations,
            false,
            "Enable inlining annotations");

DECLARE_FLAG(bool, compiler_stats);
DECLARE_FLAG(int, max_deoptimization_counter_threshold);
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);
DECLARE_FLAG(bool, support_externalizable_strings);
DECLARE_FLAG(bool, verify_compiler);

// Quick access to the current zone.
#define Z (zone())
#define I (isolate())

#define TRACE_INLINING(statement)                                              \
  do {                                                                         \
    if (trace_inlining()) statement;                                           \
  } while (false)

#define PRINT_INLINING_TREE(comment, caller, target, instance_call)            \
  do {                                                                         \
    if (FLAG_print_inlining_tree) {                                            \
      inlined_info_.Add(InlinedInfo(caller, target, inlining_depth_,           \
                                    instance_call, comment));                  \
    }                                                                          \
  } while (false)


// Test if a call is recursive by looking in the deoptimization environment.
static bool IsCallRecursive(const Function& function, Definition* call) {
  Environment* env = call->env();
  while (env != NULL) {
    if (function.raw() == env->function().raw()) {
      return true;
    }
    env = env->outer();
  }
  return false;
}


// Helper to get the default value of a formal parameter.
static ConstantInstr* GetDefaultValue(intptr_t i,
                                      const ParsedFunction& parsed_function) {
  return new ConstantInstr(parsed_function.DefaultParameterValueAt(i));
}


// Pair of an argument name and its value.
struct NamedArgument {
  String* name;
  Value* value;
  NamedArgument(String* name, Value* value) : name(name), value(value) {}
};


// Helper to collect information about a callee graph when considering it for
// inlining.
class GraphInfoCollector : public ValueObject {
 public:
  GraphInfoCollector() : call_site_count_(0), instruction_count_(0) {}

  void Collect(const FlowGraph& graph) {
    call_site_count_ = 0;
    instruction_count_ = 0;
    for (BlockIterator block_it = graph.postorder_iterator(); !block_it.Done();
         block_it.Advance()) {
      for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
           it.Advance()) {
        Instruction* current = it.Current();
        // Don't count instructions that won't generate any code.
        if (current->IsRedefinition()) {
          continue;
        }
        ++instruction_count_;
        if (current->IsInstanceCall() || current->IsStaticCall() ||
            current->IsClosureCall()) {
          ++call_site_count_;
          continue;
        }
        if (current->IsPolymorphicInstanceCall()) {
          PolymorphicInstanceCallInstr* call =
              current->AsPolymorphicInstanceCall();
          // These checks make sure that the number of call-sites counted does
          // not change relative to the time when the current set of inlining
          // parameters was fixed.
          // TODO(fschneider): Determine new heuristic parameters that avoid
          // these checks entirely.
          if (!call->IsSureToCallSingleRecognizedTarget() &&
              (call->instance_call()->token_kind() != Token::kEQ)) {
            ++call_site_count_;
          }
        }
      }
    }
  }

  intptr_t call_site_count() const { return call_site_count_; }
  intptr_t instruction_count() const { return instruction_count_; }

 private:
  intptr_t call_site_count_;
  intptr_t instruction_count_;
};


// Structure for collecting inline data needed to print inlining tree.
struct InlinedInfo {
  const Function* caller;
  const Function* inlined;
  intptr_t inlined_depth;
  const Definition* call_instr;
  const char* bailout_reason;
  InlinedInfo(const Function* caller_function,
              const Function* inlined_function,
              const intptr_t depth,
              const Definition* call,
              const char* reason)
      : caller(caller_function),
        inlined(inlined_function),
        inlined_depth(depth),
        call_instr(call),
        bailout_reason(reason) {}
};


// A collection of call sites to consider for inlining.
class CallSites : public ValueObject {
 public:
  explicit CallSites(FlowGraph* flow_graph, intptr_t threshold)
      : inlining_depth_threshold_(threshold),
        static_calls_(),
        closure_calls_(),
        instance_calls_() {}

  struct InstanceCallInfo {
    PolymorphicInstanceCallInstr* call;
    double ratio;
    const FlowGraph* caller_graph;
    InstanceCallInfo(PolymorphicInstanceCallInstr* call_arg,
                     FlowGraph* flow_graph)
        : call(call_arg), ratio(0.0), caller_graph(flow_graph) {}
    const Function& caller() const { return caller_graph->function(); }
  };

  struct StaticCallInfo {
    StaticCallInstr* call;
    double ratio;
    FlowGraph* caller_graph;
    StaticCallInfo(StaticCallInstr* value, FlowGraph* flow_graph)
        : call(value), ratio(0.0), caller_graph(flow_graph) {}
    const Function& caller() const { return caller_graph->function(); }
  };

  struct ClosureCallInfo {
    ClosureCallInstr* call;
    FlowGraph* caller_graph;
    ClosureCallInfo(ClosureCallInstr* value, FlowGraph* flow_graph)
        : call(value), caller_graph(flow_graph) {}
    const Function& caller() const { return caller_graph->function(); }
  };

  const GrowableArray<InstanceCallInfo>& instance_calls() const {
    return instance_calls_;
  }

  const GrowableArray<StaticCallInfo>& static_calls() const {
    return static_calls_;
  }

  const GrowableArray<ClosureCallInfo>& closure_calls() const {
    return closure_calls_;
  }

  bool HasCalls() const {
    return !(static_calls_.is_empty() && closure_calls_.is_empty() &&
             instance_calls_.is_empty());
  }

  intptr_t NumCalls() const {
    return instance_calls_.length() + static_calls_.length() +
           closure_calls_.length();
  }

  void Clear() {
    static_calls_.Clear();
    closure_calls_.Clear();
    instance_calls_.Clear();
  }

  void ComputeCallSiteRatio(intptr_t static_call_start_ix,
                            intptr_t instance_call_start_ix) {
    const intptr_t num_static_calls =
        static_calls_.length() - static_call_start_ix;
    const intptr_t num_instance_calls =
        instance_calls_.length() - instance_call_start_ix;

    intptr_t max_count = 0;
    GrowableArray<intptr_t> instance_call_counts(num_instance_calls);
    for (intptr_t i = 0; i < num_instance_calls; ++i) {
      const intptr_t aggregate_count =
          instance_calls_[i + instance_call_start_ix].call->CallCount();
      instance_call_counts.Add(aggregate_count);
      if (aggregate_count > max_count) max_count = aggregate_count;
    }

    GrowableArray<intptr_t> static_call_counts(num_static_calls);
    for (intptr_t i = 0; i < num_static_calls; ++i) {
      intptr_t aggregate_count =
          static_calls_[i + static_call_start_ix].call->CallCount();
      static_call_counts.Add(aggregate_count);
      if (aggregate_count > max_count) max_count = aggregate_count;
    }

    // max_count can be 0 if none of the calls was executed.
    for (intptr_t i = 0; i < num_instance_calls; ++i) {
      const double ratio =
          (max_count == 0)
              ? 0.0
              : static_cast<double>(instance_call_counts[i]) / max_count;
      instance_calls_[i + instance_call_start_ix].ratio = ratio;
    }
    for (intptr_t i = 0; i < num_static_calls; ++i) {
      const double ratio =
          (max_count == 0)
              ? 0.0
              : static_cast<double>(static_call_counts[i]) / max_count;
      static_calls_[i + static_call_start_ix].ratio = ratio;
    }
  }

  static void RecordAllNotInlinedFunction(
      FlowGraph* graph,
      intptr_t depth,
      GrowableArray<InlinedInfo>* inlined_info) {
    const Function* caller = &graph->function();
    Function& target = Function::ZoneHandle();
    for (BlockIterator block_it = graph->postorder_iterator(); !block_it.Done();
         block_it.Advance()) {
      for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
           it.Advance()) {
        Instruction* current = it.Current();
        Definition* call = NULL;
        if (current->IsPolymorphicInstanceCall()) {
          PolymorphicInstanceCallInstr* instance_call =
              current->AsPolymorphicInstanceCall();
          target ^= instance_call->targets().FirstTarget().raw();
          call = instance_call;
        } else if (current->IsStaticCall()) {
          StaticCallInstr* static_call = current->AsStaticCall();
          target ^= static_call->function().raw();
          call = static_call;
        } else if (current->IsClosureCall()) {
          // TODO(srdjan): Add data for closure calls.
        }
        if (call != NULL) {
          inlined_info->Add(
              InlinedInfo(caller, &target, depth + 1, call, "Too deep"));
        }
      }
    }
  }


  void FindCallSites(FlowGraph* graph,
                     intptr_t depth,
                     GrowableArray<InlinedInfo>* inlined_info) {
    ASSERT(graph != NULL);
    if (depth > inlining_depth_threshold_) {
      if (FLAG_print_inlining_tree) {
        RecordAllNotInlinedFunction(graph, depth, inlined_info);
      }
      return;
    }

    // Recognized methods are not treated as normal calls. They don't have
    // calls in themselves, so we keep adding those even when at the threshold.
    const bool inline_only_recognized_methods =
        (depth == inlining_depth_threshold_);

    const intptr_t instance_call_start_ix = instance_calls_.length();
    const intptr_t static_call_start_ix = static_calls_.length();
    for (BlockIterator block_it = graph->postorder_iterator(); !block_it.Done();
         block_it.Advance()) {
      for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
           it.Advance()) {
        Instruction* current = it.Current();
        if (current->IsPolymorphicInstanceCall()) {
          PolymorphicInstanceCallInstr* instance_call =
              current->AsPolymorphicInstanceCall();
          if (!inline_only_recognized_methods ||
              instance_call->IsSureToCallSingleRecognizedTarget() ||
              instance_call->HasOnlyDispatcherOrImplicitAccessorTargets()) {
            instance_calls_.Add(InstanceCallInfo(instance_call, graph));
          } else {
            // Method not inlined because inlining too deep and method
            // not recognized.
            if (FLAG_print_inlining_tree) {
              const Function* caller = &graph->function();
              const Function* target = &instance_call->targets().FirstTarget();
              inlined_info->Add(InlinedInfo(caller, target, depth + 1,
                                            instance_call, "Too deep"));
            }
          }
        } else if (current->IsStaticCall()) {
          StaticCallInstr* static_call = current->AsStaticCall();
          if (!inline_only_recognized_methods ||
              static_call->function().IsRecognized() ||
              static_call->function().IsDispatcherOrImplicitAccessor()) {
            static_calls_.Add(StaticCallInfo(static_call, graph));
          } else {
            // Method not inlined because inlining too deep and method
            // not recognized.
            if (FLAG_print_inlining_tree) {
              const Function* caller = &graph->function();
              const Function* target = &static_call->function();
              inlined_info->Add(InlinedInfo(caller, target, depth + 1,
                                            static_call, "Too deep"));
            }
          }
        } else if (current->IsClosureCall()) {
          if (!inline_only_recognized_methods) {
            ClosureCallInstr* closure_call = current->AsClosureCall();
            closure_calls_.Add(ClosureCallInfo(closure_call, graph));
          }
        }
      }
    }
    ComputeCallSiteRatio(static_call_start_ix, instance_call_start_ix);
  }

 private:
  intptr_t inlining_depth_threshold_;
  GrowableArray<StaticCallInfo> static_calls_;
  GrowableArray<ClosureCallInfo> closure_calls_;
  GrowableArray<InstanceCallInfo> instance_calls_;

  DISALLOW_COPY_AND_ASSIGN(CallSites);
};


struct InlinedCallData {
  InlinedCallData(Definition* call,
                  GrowableArray<Value*>* arguments,
                  const Function& caller,
                  intptr_t caller_inlining_id)
      : call(call),
        arguments(arguments),
        callee_graph(NULL),
        parameter_stubs(NULL),
        exit_collector(NULL),
        caller(caller),
        caller_inlining_id_(caller_inlining_id) {}

  Definition* call;
  GrowableArray<Value*>* arguments;
  FlowGraph* callee_graph;
  ZoneGrowableArray<Definition*>* parameter_stubs;
  InlineExitCollector* exit_collector;
  const Function& caller;
  const intptr_t caller_inlining_id_;
};


class CallSiteInliner;

class PolymorphicInliner : public ValueObject {
 public:
  PolymorphicInliner(CallSiteInliner* owner,
                     PolymorphicInstanceCallInstr* call,
                     const Function& caller_function,
                     intptr_t caller_inlining_id);

  void Inline();

 private:
  bool CheckInlinedDuplicate(const Function& target);
  bool CheckNonInlinedDuplicate(const Function& target);

  bool TryInliningPoly(const TargetInfo& target);
  bool TryInlineRecognizedMethod(intptr_t receiver_cid, const Function& target);

  TargetEntryInstr* BuildDecisionGraph();

  Isolate* isolate() const;
  Zone* zone() const;
  intptr_t AllocateBlockId() const;
  inline bool trace_inlining() const;

  CallSiteInliner* const owner_;
  PolymorphicInstanceCallInstr* const call_;
  const intptr_t num_variants_;
  const CallTargets& variants_;

  CallTargets inlined_variants_;
  // The non_inlined_variants_ can be used in a long-lived instruction object,
  // so they are not embedded into the shorter-lived PolymorphicInliner object.
  CallTargets* non_inlined_variants_;
  GrowableArray<BlockEntryInstr*> inlined_entries_;
  InlineExitCollector* exit_collector_;

  const Function& caller_function_;
  const intptr_t caller_inlining_id_;
};


static bool HasAnnotation(const Function& function, const char* annotation) {
  const Class& owner = Class::Handle(function.Owner());
  const Library& library = Library::Handle(owner.library());
  const Array& metadata =
      Array::Cast(Object::Handle(library.GetMetadata(function)));

  if (metadata.Length() > 0) {
    Object& val = Object::Handle();
    for (intptr_t i = 0; i < metadata.Length(); i++) {
      val = metadata.At(i);
      if (val.IsString() && String::Cast(val).Equals(annotation)) {
        return true;
      }
    }
  }
  return false;
}


class CallSiteInliner : public ValueObject {
 public:
  explicit CallSiteInliner(FlowGraphInliner* inliner, intptr_t threshold)
      : inliner_(inliner),
        caller_graph_(inliner->flow_graph()),
        inlined_(false),
        initial_size_(inliner->flow_graph()->InstructionCount()),
        inlined_size_(0),
        inlined_recursive_call_(false),
        inlining_depth_(1),
        inlining_recursion_depth_(0),
        inlining_depth_threshold_(threshold),
        collected_call_sites_(NULL),
        inlining_call_sites_(NULL),
        function_cache_(),
        inlined_info_() {}

  FlowGraph* caller_graph() const { return caller_graph_; }

  Thread* thread() const { return caller_graph_->thread(); }
  Isolate* isolate() const { return caller_graph_->isolate(); }
  Zone* zone() const { return caller_graph_->zone(); }

  bool trace_inlining() const { return inliner_->trace_inlining(); }

  // Inlining heuristics based on Cooper et al. 2008.
  bool ShouldWeInline(const Function& callee,
                      intptr_t instr_count,
                      intptr_t call_site_count,
                      intptr_t const_arg_count) {
    if (inliner_->AlwaysInline(callee)) {
      return true;
    }
    if (inlined_size_ > FLAG_inlining_caller_size_threshold) {
      // Prevent methods becoming humongous and thus slow to compile.
      return false;
    }
    if (const_arg_count > 0) {
      if (instr_count > FLAG_inlining_constant_arguments_max_size_threshold) {
        return false;
      }
    } else if (instr_count > FLAG_inlining_callee_size_threshold) {
      return false;
    }
    // 'instr_count' can be 0 if it was not computed yet.
    if ((instr_count != 0) && (instr_count <= FLAG_inlining_size_threshold)) {
      return true;
    }
    if (call_site_count <= FLAG_inlining_callee_call_sites_threshold) {
      return true;
    }
    if ((const_arg_count >= FLAG_inlining_constant_arguments_count) &&
        (instr_count <= FLAG_inlining_constant_arguments_min_size_threshold)) {
      return true;
    }
    return false;
  }

  void InlineCalls() {
    // If inlining depth is less then one abort.
    if (inlining_depth_threshold_ < 1) return;
    if (caller_graph_->function().deoptimization_counter() >=
        FLAG_deoptimization_counter_inlining_threshold) {
      return;
    }
    // Create two call site collections to swap between.
    CallSites sites1(caller_graph_, inlining_depth_threshold_);
    CallSites sites2(caller_graph_, inlining_depth_threshold_);
    CallSites* call_sites_temp = NULL;
    collected_call_sites_ = &sites1;
    inlining_call_sites_ = &sites2;
    // Collect initial call sites.
    collected_call_sites_->FindCallSites(caller_graph_, inlining_depth_,
                                         &inlined_info_);
    while (collected_call_sites_->HasCalls()) {
      TRACE_INLINING(
          THR_Print("  Depth %" Pd " ----------\n", inlining_depth_));
      if (collected_call_sites_->NumCalls() > FLAG_max_inlined_per_depth) {
        break;
      }
      if (FLAG_print_inlining_tree) {
        THR_Print("**Depth % " Pd " calls to inline %" Pd "\n", inlining_depth_,
                  collected_call_sites_->NumCalls());
      }
      // Swap collected and inlining arrays and clear the new collecting array.
      call_sites_temp = collected_call_sites_;
      collected_call_sites_ = inlining_call_sites_;
      inlining_call_sites_ = call_sites_temp;
      collected_call_sites_->Clear();
      // Inline call sites at the current depth.
      InlineInstanceCalls();
      InlineStaticCalls();
      InlineClosureCalls();
      // Increment the inlining depths. Checked before subsequent inlining.
      ++inlining_depth_;
      if (inlined_recursive_call_) {
        ++inlining_recursion_depth_;
        inlined_recursive_call_ = false;
      }
      thread()->CheckForSafepoint();
    }

    collected_call_sites_ = NULL;
    inlining_call_sites_ = NULL;
  }

  bool inlined() const { return inlined_; }

  double GrowthFactor() const {
    return static_cast<double>(inlined_size_) /
           static_cast<double>(initial_size_);
  }

  // Helper to create a parameter stub from an actual argument.
  Definition* CreateParameterStub(intptr_t i,
                                  Value* argument,
                                  FlowGraph* graph) {
    ConstantInstr* constant = argument->definition()->AsConstant();
    if (constant != NULL) {
      return new (Z) ConstantInstr(constant->value());
    } else {
      ParameterInstr* param = new (Z) ParameterInstr(i, graph->graph_entry());
      param->UpdateType(*argument->Type());
      return param;
    }
  }

  bool TryInlining(const Function& function,
                   const Array& argument_names,
                   InlinedCallData* call_data) {
    if (trace_inlining()) {
      String& name = String::Handle(function.QualifiedUserVisibleName());
      THR_Print("  => %s (deopt count %d)\n", name.ToCString(),
                function.deoptimization_counter());
    }

    // Abort if the inlinable bit on the function is low.
    if (!function.CanBeInlined()) {
      TRACE_INLINING(THR_Print("     Bailout: not inlinable\n"));
      PRINT_INLINING_TREE("Not inlinable", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Don't inline any intrinsified functions in precompiled mode
    // to reduce code size and make sure we use the intrinsic code.
    if (FLAG_precompiled_mode && function.is_intrinsic() &&
        !inliner_->AlwaysInline(function)) {
      TRACE_INLINING(THR_Print("     Bailout: intrinisic\n"));
      PRINT_INLINING_TREE("intrinsic", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Do not rely on function type feedback or presence of code to determine
    // if a function was compiled.
    if (!FLAG_precompiled_mode && !function.was_compiled()) {
      TRACE_INLINING(THR_Print("     Bailout: not compiled yet\n"));
      PRINT_INLINING_TREE("Not compiled", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    if ((inliner_->precompiler_ != NULL) &&
        inliner_->precompiler_->HasFeedback() &&
        (function.usage_counter() <= 0) && !inliner_->AlwaysInline(function)) {
      TRACE_INLINING(THR_Print("     Bailout: not compiled yet\n"));
      PRINT_INLINING_TREE("Not compiled", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Type feedback may have been cleared for this function (ClearICDataArray),
    // but we need it for inlining.
    if (!FLAG_precompiled_mode && (function.ic_data_array() == Array::null())) {
      TRACE_INLINING(THR_Print("     Bailout: type feedback cleared\n"));
      PRINT_INLINING_TREE("Not compiled", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Abort if this function has deoptimized too much.
    if (function.deoptimization_counter() >=
        FLAG_max_deoptimization_counter_threshold) {
      function.set_is_inlinable(false);
      TRACE_INLINING(THR_Print("     Bailout: deoptimization threshold\n"));
      PRINT_INLINING_TREE("Deoptimization threshold exceeded",
                          &call_data->caller, &function, call_data->call);
      return false;
    }

    const char* kNeverInlineAnnotation = "NeverInline";
    if (FLAG_enable_inlining_annotations &&
        HasAnnotation(function, kNeverInlineAnnotation)) {
      TRACE_INLINING(THR_Print("     Bailout: NeverInline annotation\n"));
      return false;
    }

    GrowableArray<Value*>* arguments = call_data->arguments;
    const intptr_t constant_arguments = CountConstants(*arguments);
    if (!ShouldWeInline(function, function.optimized_instruction_count(),
                        function.optimized_call_site_count(),
                        constant_arguments)) {
      TRACE_INLINING(
          THR_Print("     Bailout: early heuristics with "
                    "code size:  %" Pd ", "
                    "call sites: %" Pd ", "
                    "const args: %" Pd "\n",
                    function.optimized_instruction_count(),
                    function.optimized_call_site_count(), constant_arguments));
      PRINT_INLINING_TREE("Early heuristic", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Abort if this is a recursive occurrence.
    Definition* call = call_data->call;
    // Added 'volatile' works around a possible GCC 4.9 compiler bug.
    volatile bool is_recursive_call = IsCallRecursive(function, call);
    if (is_recursive_call &&
        inlining_recursion_depth_ >= FLAG_inlining_recursion_depth_threshold) {
      TRACE_INLINING(THR_Print("     Bailout: recursive function\n"));
      PRINT_INLINING_TREE("Recursive function", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Save and clear deopt id.
    const intptr_t prev_deopt_id = thread()->deopt_id();
    thread()->set_deopt_id(0);
    Error& error = Error::Handle();
    {
      // Install bailout jump.
      LongJumpScope jump;
      if (setjmp(*jump.Set()) == 0) {
        Isolate* isolate = Isolate::Current();
        // Makes sure no classes are loaded during parsing in background.
        const intptr_t loading_invalidation_gen_at_start =
            isolate->loading_invalidation_gen();

        if (Compiler::IsBackgroundCompilation()) {
          if (isolate->IsTopLevelParsing() ||
              (loading_invalidation_gen_at_start !=
               isolate->loading_invalidation_gen())) {
            // Loading occured while parsing. We need to abort here because
            // state changed while compiling.
            Compiler::AbortBackgroundCompilation(
                Thread::kNoDeoptId, "Loading occured while parsing in inliner");
          }
        }

        // Load IC data for the callee.
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new (Z) ZoneGrowableArray<const ICData*>();
        const bool clone_ic_data = Compiler::IsBackgroundCompilation();
        function.RestoreICDataMap(ic_data_array, clone_ic_data);
        if (Compiler::IsBackgroundCompilation() &&
            (function.ic_data_array() == Array::null())) {
          Compiler::AbortBackgroundCompilation(Thread::kNoDeoptId,
                                               "ICData cleared while inlining");
        }

        // Parse the callee function.
        bool in_cache;
        ParsedFunction* parsed_function;
        {
          CSTAT_TIMER_SCOPE(thread(), graphinliner_parse_timer);
          parsed_function = GetParsedFunction(function, &in_cache);
          if (!function.CanBeInlined()) {
            // As a side effect of parsing the function, it may be marked
            // as not inlinable. This happens for async and async* functions
            // when causal stack traces are being tracked.
            return false;
          }
        }


        // Build the callee graph.
        InlineExitCollector* exit_collector =
            new (Z) InlineExitCollector(caller_graph_, call);
        FlowGraph* callee_graph;
        if (UseKernelFrontEndFor(parsed_function)) {
          kernel::TreeNode* node = static_cast<kernel::TreeNode*>(
              parsed_function->function().kernel_function());

          kernel::FlowGraphBuilder builder(
              node, parsed_function, *ic_data_array,
              /* not building var desc */ NULL, exit_collector,
              Compiler::kNoOSRDeoptId, caller_graph_->max_block_id() + 1);
          {
            CSTAT_TIMER_SCOPE(thread(), graphinliner_build_timer);
            callee_graph = builder.BuildGraph();
          }
        } else {
          FlowGraphBuilder builder(*parsed_function, *ic_data_array,
                                   /* not building var desc */ NULL,
                                   exit_collector, Compiler::kNoOSRDeoptId);
          builder.SetInitialBlockId(caller_graph_->max_block_id());
          {
            CSTAT_TIMER_SCOPE(thread(), graphinliner_build_timer);
            callee_graph = builder.BuildGraph();
          }
        }
#ifdef DART_PRECOMPILER
        if (FLAG_precompiled_mode) {
          Precompiler::PopulateWithICData(parsed_function->function(),
                                          callee_graph);
          if (inliner_->precompiler_ != NULL) {
            inliner_->precompiler_->TryApplyFeedback(
                parsed_function->function(), callee_graph);
          }
        }
#endif

        // The parameter stubs are a copy of the actual arguments providing
        // concrete information about the values, for example constant values,
        // without linking between the caller and callee graphs.
        // TODO(zerny): Put more information in the stubs, eg, type information.
        ZoneGrowableArray<Definition*>* param_stubs =
            new (Z) ZoneGrowableArray<Definition*>(function.NumParameters());

        // Create a parameter stub for each fixed positional parameter.
        for (intptr_t i = 0; i < function.num_fixed_parameters(); ++i) {
          param_stubs->Add(
              CreateParameterStub(i, (*arguments)[i], callee_graph));
        }

        // If the callee has optional parameters, rebuild the argument and stub
        // arrays so that actual arguments are in one-to-one with the formal
        // parameters.
        if (function.HasOptionalParameters()) {
          TRACE_INLINING(THR_Print("     adjusting for optional parameters\n"));
          if (!AdjustForOptionalParameters(*parsed_function, argument_names,
                                           arguments, param_stubs,
                                           callee_graph)) {
            function.set_is_inlinable(false);
            TRACE_INLINING(THR_Print("     Bailout: optional arg mismatch\n"));
            PRINT_INLINING_TREE("Optional arg mismatch", &call_data->caller,
                                &function, call_data->call);
            return false;
          }
        }

        // After treating optional parameters the actual/formal count must
        // match.
        // TODO(regis): Consider type arguments in arguments.
        if (arguments->length() != function.NumParameters()) {
          ASSERT(function.IsGeneric());
          ASSERT(arguments->length() == function.NumParameters() + 1);
          TRACE_INLINING(
              THR_Print("     Bailout: unsupported type arguments\n"));
          PRINT_INLINING_TREE("Unsupported type arguments", &call_data->caller,
                              &function, call_data->call);
          return false;
        }
        ASSERT(param_stubs->length() == callee_graph->parameter_count());

        // Update try-index of the callee graph.
        BlockEntryInstr* call_block = call_data->call->GetBlock();
        if (call_block->InsideTryBlock()) {
          intptr_t try_index = call_block->try_index();
          for (BlockIterator it = callee_graph->reverse_postorder_iterator();
               !it.Done(); it.Advance()) {
            BlockEntryInstr* block = it.Current();
            block->set_try_index(try_index);
          }
        }

        BlockScheduler block_scheduler(callee_graph);
        block_scheduler.AssignEdgeWeights();

        {
          CSTAT_TIMER_SCOPE(thread(), graphinliner_ssa_timer);
          // Compute SSA on the callee graph, catching bailouts.
          callee_graph->ComputeSSA(caller_graph_->max_virtual_register_number(),
                                   param_stubs);
          DEBUG_ASSERT(callee_graph->VerifyUseLists());
        }

        {
          CSTAT_TIMER_SCOPE(thread(), graphinliner_opt_timer);
          // TODO(fschneider): Improve suppression of speculative inlining.
          // Deopt-ids overlap between caller and callee.
          if (FLAG_precompiled_mode) {
#ifdef DART_PRECOMPILER
            AotOptimizer optimizer(inliner_->precompiler_, callee_graph,
                                   inliner_->use_speculative_inlining_,
                                   inliner_->inlining_black_list_);

            optimizer.ApplyClassIds();
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            FlowGraphTypePropagator::Propagate(callee_graph);
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            optimizer.ApplyICData();
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            // Optimize (a << b) & c patterns, merge instructions. Must occur
            // before 'SelectRepresentations' which inserts conversion nodes.
            callee_graph->TryOptimizePatterns();
            DEBUG_ASSERT(callee_graph->VerifyUseLists());
#else
            UNREACHABLE();
#endif  // DART_PRECOMPILER
          } else {
            JitOptimizer optimizer(callee_graph);

            optimizer.ApplyClassIds();
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            FlowGraphTypePropagator::Propagate(callee_graph);
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            optimizer.ApplyICData();
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            // Optimize (a << b) & c patterns, merge instructions. Must occur
            // before 'SelectRepresentations' which inserts conversion nodes.
            callee_graph->TryOptimizePatterns();
            DEBUG_ASSERT(callee_graph->VerifyUseLists());

            callee_graph->Canonicalize();
          }
        }

        if (FLAG_support_il_printer && trace_inlining() &&
            (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized)) {
          THR_Print("Callee graph for inlining %s\n",
                    function.ToFullyQualifiedCString());
          FlowGraphPrinter printer(*callee_graph);
          printer.PrintBlocks();
        }

        // Collect information about the call site and caller graph.
        // TODO(zerny): Do this after CP and dead code elimination.
        intptr_t constants_count = 0;
        for (intptr_t i = 0; i < param_stubs->length(); ++i) {
          if ((*param_stubs)[i]->IsConstant()) ++constants_count;
        }

        FlowGraphInliner::CollectGraphInfo(callee_graph);
        const intptr_t size = function.optimized_instruction_count();
        const intptr_t call_site_count = function.optimized_call_site_count();

        function.set_optimized_instruction_count(size);
        function.set_optimized_call_site_count(call_site_count);

        // Use heuristics do decide if this call should be inlined.
        if (!ShouldWeInline(function, size, call_site_count, constants_count)) {
          // If size is larger than all thresholds, don't consider it again.
          if ((size > FLAG_inlining_size_threshold) &&
              (call_site_count > FLAG_inlining_callee_call_sites_threshold) &&
              (size > FLAG_inlining_constant_arguments_min_size_threshold) &&
              (size > FLAG_inlining_constant_arguments_max_size_threshold)) {
            function.set_is_inlinable(false);
          }
          thread()->set_deopt_id(prev_deopt_id);
          TRACE_INLINING(
              THR_Print("     Bailout: heuristics with "
                        "code size:  %" Pd ", "
                        "call sites: %" Pd ", "
                        "const args: %" Pd "\n",
                        size, call_site_count, constants_count));
          PRINT_INLINING_TREE("Heuristic fail", &call_data->caller, &function,
                              call_data->call);
          return false;
        }

        // Inline dispatcher methods regardless of the current depth.
        const intptr_t depth =
            function.IsDispatcherOrImplicitAccessor() ? 0 : inlining_depth_;
        collected_call_sites_->FindCallSites(callee_graph, depth,
                                             &inlined_info_);

        // Add the function to the cache.
        if (!in_cache) {
          function_cache_.Add(parsed_function);
        }

        // Build succeeded so we restore the bailout jump.
        inlined_ = true;
        inlined_size_ += size;
        if (is_recursive_call) {
          inlined_recursive_call_ = true;
        }
        thread()->set_deopt_id(prev_deopt_id);

        call_data->callee_graph = callee_graph;
        call_data->parameter_stubs = param_stubs;
        call_data->exit_collector = exit_collector;

        // When inlined, we add the guarded fields of the callee to the caller's
        // list of guarded fields.
        const ZoneGrowableArray<const Field*>& callee_guarded_fields =
            *callee_graph->parsed_function().guarded_fields();
        for (intptr_t i = 0; i < callee_guarded_fields.length(); ++i) {
          caller_graph()->parsed_function().AddToGuardedFields(
              callee_guarded_fields[i]);
        }
        // When inlined, we add the deferred prefixes of the callee to the
        // caller's list of deferred prefixes.
        caller_graph()->AddToDeferredPrefixes(
            callee_graph->deferred_prefixes());

        FlowGraphInliner::SetInliningId(
            callee_graph,
            inliner_->NextInlineId(callee_graph->function(),
                                   call_data->call->token_pos(),
                                   call_data->caller_inlining_id_));
        TRACE_INLINING(THR_Print("     Success\n"));
        TRACE_INLINING(THR_Print("       with size %" Pd "\n",
                                 function.optimized_instruction_count()));
        PRINT_INLINING_TREE(NULL, &call_data->caller, &function, call);
        return true;
      } else {
        error = thread()->sticky_error();
        thread()->clear_sticky_error();

        if (error.IsLanguageError() &&
            (LanguageError::Cast(error).kind() == Report::kBailout)) {
          if (error.raw() == Object::background_compilation_error().raw()) {
            // Fall through to exit the compilation, and retry it later.
          } else {
            thread()->set_deopt_id(prev_deopt_id);
            TRACE_INLINING(
                THR_Print("     Bailout: %s\n", error.ToErrorCString()));
            PRINT_INLINING_TREE("Bailout", &call_data->caller, &function, call);
            return false;
          }
        } else {
          // Fall through to exit long jump scope.
        }
      }
    }

    // Propagate a compile-time error. In precompilation we attempt to
    // inline functions that have never been compiled before; when JITing we
    // should only see language errors in unoptimized compilation.
    // Otherwise, there can be an out-of-memory error (unhandled exception).
    // In background compilation we may abort compilation as the state
    // changes while compiling. Propagate that 'error' and retry compilation
    // later.
    ASSERT(FLAG_precompiled_mode || Compiler::IsBackgroundCompilation() ||
           error.IsUnhandledException());
    Thread::Current()->long_jump_base()->Jump(1, error);
    UNREACHABLE();
    return false;
  }

  void PrintInlinedInfo(const Function& top) {
    if (inlined_info_.length() > 0) {
      THR_Print("Inlining into: '%s'\n    growth: %f (%" Pd " -> %" Pd ")\n",
                top.ToFullyQualifiedCString(), GrowthFactor(), initial_size_,
                inlined_size_);
      PrintInlinedInfoFor(top, 1);
    }
  }

 private:
  friend class PolymorphicInliner;

  static bool Contains(const GrowableArray<intptr_t>& a, intptr_t deopt_id) {
    for (intptr_t i = 0; i < a.length(); i++) {
      if (a[i] == deopt_id) return true;
    }
    return false;
  }

  void PrintInlinedInfoFor(const Function& caller, intptr_t depth) {
    // Prevent duplicate printing as inlined_info aggregates all inlinining.
    GrowableArray<intptr_t> call_instructions_printed;
    // Print those that were inlined.
    for (intptr_t i = 0; i < inlined_info_.length(); i++) {
      const InlinedInfo& info = inlined_info_[i];
      if (info.bailout_reason != NULL) {
        continue;
      }
      if ((info.inlined_depth == depth) &&
          (info.caller->raw() == caller.raw()) &&
          !Contains(call_instructions_printed, info.call_instr->GetDeoptId())) {
        for (int t = 0; t < depth; t++) {
          THR_Print("  ");
        }
        THR_Print("%" Pd " %s\n", info.call_instr->GetDeoptId(),
                  info.inlined->ToQualifiedCString());
        PrintInlinedInfoFor(*info.inlined, depth + 1);
        call_instructions_printed.Add(info.call_instr->GetDeoptId());
      }
    }
    call_instructions_printed.Clear();
    // Print those that were not inlined.
    for (intptr_t i = 0; i < inlined_info_.length(); i++) {
      const InlinedInfo& info = inlined_info_[i];
      if (info.bailout_reason == NULL) {
        continue;
      }
      if ((info.inlined_depth == depth) &&
          (info.caller->raw() == caller.raw()) &&
          !Contains(call_instructions_printed, info.call_instr->GetDeoptId())) {
        for (int t = 0; t < depth; t++) {
          THR_Print("  ");
        }
        THR_Print("NO %" Pd " %s - %s\n", info.call_instr->GetDeoptId(),
                  info.inlined->ToQualifiedCString(), info.bailout_reason);
        call_instructions_printed.Add(info.call_instr->GetDeoptId());
      }
    }
  }

  void InlineCall(InlinedCallData* call_data) {
    CSTAT_TIMER_SCOPE(Thread::Current(), graphinliner_subst_timer);
    FlowGraph* callee_graph = call_data->callee_graph;
    TargetEntryInstr* callee_entry =
        callee_graph->graph_entry()->normal_entry();
    // Plug result in the caller graph.
    InlineExitCollector* exit_collector = call_data->exit_collector;
    exit_collector->PrepareGraphs(callee_graph);
    exit_collector->ReplaceCall(callee_entry);

    // Replace each stub with the actual argument or the caller's constant.
    // Nulls denote optional parameters for which no actual was given.
    GrowableArray<Value*>* arguments = call_data->arguments;
    for (intptr_t i = 0; i < arguments->length(); ++i) {
      Definition* stub = (*call_data->parameter_stubs)[i];
      Value* actual = (*arguments)[i];
      if (actual != NULL) stub->ReplaceUsesWith(actual->definition());
    }

    // Remove push arguments of the call.
    Definition* call = call_data->call;
    for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
      PushArgumentInstr* push = call->PushArgumentAt(i);
      push->ReplaceUsesWith(push->value()->definition());
      push->RemoveFromGraph();
    }

    // Replace remaining constants with uses by constants in the caller's
    // initial definitions.
    GrowableArray<Definition*>* defns =
        callee_graph->graph_entry()->initial_definitions();
    for (intptr_t i = 0; i < defns->length(); ++i) {
      ConstantInstr* constant = (*defns)[i]->AsConstant();
      if ((constant != NULL) && constant->HasUses()) {
        constant->ReplaceUsesWith(
            caller_graph_->GetConstant(constant->value()));
      }
      CurrentContextInstr* context = (*defns)[i]->AsCurrentContext();
      if ((context != NULL) && context->HasUses()) {
        ASSERT(call->IsClosureCall());
        LoadFieldInstr* context_load = new (Z) LoadFieldInstr(
            new Value((*arguments)[0]->definition()), Closure::context_offset(),
            AbstractType::ZoneHandle(zone(), AbstractType::null()),
            call_data->call->token_pos());
        context_load->set_is_immutable(true);
        context_load->set_ssa_temp_index(caller_graph_->alloc_ssa_temp_index());
        context_load->InsertBefore(callee_entry->next());
        context->ReplaceUsesWith(context_load);
      }
    }

    // Check that inlining maintains use lists.
    DEBUG_ASSERT(!FLAG_verify_compiler || caller_graph_->VerifyUseLists());
  }

  static intptr_t CountConstants(const GrowableArray<Value*>& arguments) {
    intptr_t count = 0;
    for (intptr_t i = 0; i < arguments.length(); i++) {
      if (arguments[i]->BindsToConstant()) count++;
    }
    return count;
  }

  // Parse a function reusing the cache if possible.
  ParsedFunction* GetParsedFunction(const Function& function, bool* in_cache) {
    // TODO(zerny): Use a hash map for the cache.
    for (intptr_t i = 0; i < function_cache_.length(); ++i) {
      ParsedFunction* parsed_function = function_cache_[i];
      if (parsed_function->function().raw() == function.raw()) {
        *in_cache = true;
        return parsed_function;
      }
    }
    *in_cache = false;
    ParsedFunction* parsed_function =
        new (Z) ParsedFunction(thread(), function);
    if (!UseKernelFrontEndFor(parsed_function)) {
      Parser::ParseFunction(parsed_function);
      parsed_function->AllocateVariables();
    }
    return parsed_function;
  }

  void InlineStaticCalls() {
    const GrowableArray<CallSites::StaticCallInfo>& call_info =
        inlining_call_sites_->static_calls();
    TRACE_INLINING(THR_Print("  Static Calls (%" Pd ")\n", call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      StaticCallInstr* call = call_info[call_idx].call;
      const Function& target = call->function();
      if (!inliner_->AlwaysInline(target) &&
          (call_info[call_idx].ratio * 100) < FLAG_inlining_hotness) {
        if (trace_inlining()) {
          String& name = String::Handle(target.QualifiedUserVisibleName());
          THR_Print("  => %s (deopt count %d)\n     Bailout: cold %f\n",
                    name.ToCString(), target.deoptimization_counter(),
                    call_info[call_idx].ratio);
        }
        PRINT_INLINING_TREE("Too cold", &call_info[call_idx].caller(),
                            &call->function(), call);
        continue;
      }
      GrowableArray<Value*> arguments(call->ArgumentCount());
      for (int i = 0; i < call->ArgumentCount(); ++i) {
        arguments.Add(call->PushArgumentAt(i)->value());
      }
      InlinedCallData call_data(
          call, &arguments, call_info[call_idx].caller(),
          call_info[call_idx].caller_graph->inlining_id());
      if (TryInlining(call->function(), call->argument_names(), &call_data)) {
        InlineCall(&call_data);
      }
    }
  }

  void InlineClosureCalls() {
    const GrowableArray<CallSites::ClosureCallInfo>& call_info =
        inlining_call_sites_->closure_calls();
    TRACE_INLINING(
        THR_Print("  Closure Calls (%" Pd ")\n", call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      ClosureCallInstr* call = call_info[call_idx].call;
      // Find the closure of the callee.
      ASSERT(call->ArgumentCount() > 0);
      Function& target = Function::ZoneHandle();
      AllocateObjectInstr* alloc =
          call->ArgumentAt(0)->OriginalDefinition()->AsAllocateObject();
      if ((alloc != NULL) && !alloc->closure_function().IsNull()) {
        target ^= alloc->closure_function().raw();
        ASSERT(alloc->cls().IsClosureClass());
      }
      ConstantInstr* constant =
          call->ArgumentAt(0)->OriginalDefinition()->AsConstant();
      if ((constant != NULL) && constant->value().IsClosure()) {
        target ^= Closure::Cast(constant->value()).function();
      }

      if (target.IsNull()) {
        TRACE_INLINING(THR_Print("     Bailout: non-closure operator\n"));
        continue;
      }

      if (call->ArgumentCount() > target.NumParameters() ||
          call->ArgumentCount() < target.num_fixed_parameters()) {
        TRACE_INLINING(THR_Print("     Bailout: wrong parameter count\n"));
        continue;
      }

      GrowableArray<Value*> arguments(call->ArgumentCount());
      for (int i = 0; i < call->ArgumentCount(); ++i) {
        arguments.Add(call->PushArgumentAt(i)->value());
      }
      InlinedCallData call_data(
          call, &arguments, call_info[call_idx].caller(),
          call_info[call_idx].caller_graph->inlining_id());
      if (TryInlining(target, call->argument_names(), &call_data)) {
        InlineCall(&call_data);
      }
    }
  }

  void InlineInstanceCalls() {
    const GrowableArray<CallSites::InstanceCallInfo>& call_info =
        inlining_call_sites_->instance_calls();
    TRACE_INLINING(THR_Print("  Polymorphic Instance Calls (%" Pd ")\n",
                             call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      PolymorphicInstanceCallInstr* call = call_info[call_idx].call;
      // PolymorphicInliner introduces deoptimization paths.
      if (!call->complete() && !FLAG_polymorphic_with_deopt) {
        TRACE_INLINING(
            THR_Print("  => %s\n     Bailout: call with checks\n",
                      call->instance_call()->function_name().ToCString()));
        continue;
      }
      const Function& cl = call_info[call_idx].caller();
      intptr_t caller_inlining_id =
          call_info[call_idx].caller_graph->inlining_id();
      PolymorphicInliner inliner(this, call, cl, caller_inlining_id);
      inliner.Inline();
    }
  }

  bool AdjustForOptionalParameters(const ParsedFunction& parsed_function,
                                   const Array& argument_names,
                                   GrowableArray<Value*>* arguments,
                                   ZoneGrowableArray<Definition*>* param_stubs,
                                   FlowGraph* callee_graph) {
    const Function& function = parsed_function.function();
    // The language and this code does not support both optional positional
    // and optional named parameters for the same function.
    ASSERT(!function.HasOptionalPositionalParameters() ||
           !function.HasOptionalNamedParameters());

    // TODO(regis): Consider type arguments in arguments.
    intptr_t arg_count = arguments->length();
    intptr_t param_count = function.NumParameters();
    intptr_t fixed_param_count = function.num_fixed_parameters();
    ASSERT(fixed_param_count <= arg_count);
    ASSERT(arg_count <= param_count);

    if (function.HasOptionalPositionalParameters()) {
      // Create a stub for each optional positional parameters with an actual.
      for (intptr_t i = fixed_param_count; i < arg_count; ++i) {
        param_stubs->Add(CreateParameterStub(i, (*arguments)[i], callee_graph));
      }
      ASSERT(function.NumOptionalPositionalParameters() ==
             (param_count - fixed_param_count));
      // For each optional positional parameter without an actual, add its
      // default value.
      for (intptr_t i = arg_count; i < param_count; ++i) {
        const Instance& object =
            parsed_function.DefaultParameterValueAt(i - fixed_param_count);
        ConstantInstr* constant = new (Z) ConstantInstr(object);
        arguments->Add(NULL);
        param_stubs->Add(constant);
      }
      return true;
    }

    ASSERT(function.HasOptionalNamedParameters());

    // Passed arguments must match fixed parameters plus named arguments.
    intptr_t argument_names_count =
        (argument_names.IsNull()) ? 0 : argument_names.Length();
    ASSERT(arg_count == (fixed_param_count + argument_names_count));

    // Fast path when no optional named parameters are given.
    if (argument_names_count == 0) {
      for (intptr_t i = 0; i < param_count - fixed_param_count; ++i) {
        arguments->Add(NULL);
        param_stubs->Add(GetDefaultValue(i, parsed_function));
      }
      return true;
    }

    // Otherwise, build a collection of name/argument pairs.
    GrowableArray<NamedArgument> named_args(argument_names_count);
    for (intptr_t i = 0; i < argument_names.Length(); ++i) {
      String& arg_name = String::Handle(caller_graph_->zone());
      arg_name ^= argument_names.At(i);
      named_args.Add(
          NamedArgument(&arg_name, (*arguments)[i + fixed_param_count]));
    }

    // Truncate the arguments array to just fixed parameters.
    arguments->TruncateTo(fixed_param_count);

    // For each optional named parameter, add the actual argument or its
    // default if no argument is passed.
    intptr_t match_count = 0;
    for (intptr_t i = fixed_param_count; i < param_count; ++i) {
      String& param_name = String::Handle(function.ParameterNameAt(i));
      // Search for and add the named argument.
      Value* arg = NULL;
      for (intptr_t j = 0; j < named_args.length(); ++j) {
        if (param_name.Equals(*named_args[j].name)) {
          arg = named_args[j].value;
          match_count++;
          break;
        }
      }
      arguments->Add(arg);
      // Create a stub for the argument or use the parameter's default value.
      if (arg != NULL) {
        param_stubs->Add(CreateParameterStub(i, arg, callee_graph));
      } else {
        param_stubs->Add(
            GetDefaultValue(i - fixed_param_count, parsed_function));
      }
    }
    return argument_names_count == match_count;
  }

  FlowGraphInliner* inliner_;
  FlowGraph* caller_graph_;
  bool inlined_;
  const intptr_t initial_size_;
  intptr_t inlined_size_;
  bool inlined_recursive_call_;
  intptr_t inlining_depth_;
  intptr_t inlining_recursion_depth_;
  intptr_t inlining_depth_threshold_;
  CallSites* collected_call_sites_;
  CallSites* inlining_call_sites_;
  GrowableArray<ParsedFunction*> function_cache_;
  GrowableArray<InlinedInfo> inlined_info_;

  DISALLOW_COPY_AND_ASSIGN(CallSiteInliner);
};


PolymorphicInliner::PolymorphicInliner(CallSiteInliner* owner,
                                       PolymorphicInstanceCallInstr* call,
                                       const Function& caller_function,
                                       intptr_t caller_inlining_id)
    : owner_(owner),
      call_(call),
      num_variants_(call->NumberOfChecks()),
      variants_(call->targets_),
      inlined_variants_(zone()),
      non_inlined_variants_(new (zone()) CallTargets(zone())),
      inlined_entries_(num_variants_),
      exit_collector_(new (Z) InlineExitCollector(owner->caller_graph(), call)),
      caller_function_(caller_function),
      caller_inlining_id_(caller_inlining_id) {}


Isolate* PolymorphicInliner::isolate() const {
  return owner_->caller_graph()->isolate();
}


Zone* PolymorphicInliner::zone() const {
  return owner_->caller_graph()->zone();
}


intptr_t PolymorphicInliner::AllocateBlockId() const {
  return owner_->caller_graph()->allocate_block_id();
}


// Inlined bodies are shared if two different class ids have the same
// inlined target.  This sharing is represented by using three different
// types of entries in the inlined_entries_ array:
//
//   * GraphEntry: the inlined body is not shared.
//
//   * TargetEntry: the inlined body is shared and this is the first variant.
//
//   * JoinEntry: the inlined body is shared and this is a subsequent variant.
bool PolymorphicInliner::CheckInlinedDuplicate(const Function& target) {
  for (intptr_t i = 0; i < inlined_variants_.length(); ++i) {
    if ((target.raw() == inlined_variants_.TargetAt(i)->target->raw()) &&
        !MethodRecognizer::PolymorphicTarget(target)) {
      // The call target is shared with a previous inlined variant.  Share
      // the graph.  This requires a join block at the entry, and edge-split
      // form requires a target for each branch.
      //
      // Represent the sharing by recording a fresh target for the first
      // variant and the shared join for all later variants.
      if (inlined_entries_[i]->IsGraphEntry()) {
        // Convert the old target entry to a new join entry.
        TargetEntryInstr* old_target =
            inlined_entries_[i]->AsGraphEntry()->normal_entry();
        // Unuse all inputs in the old graph entry since it is not part of
        // the graph anymore. A new target be created instead.
        inlined_entries_[i]->AsGraphEntry()->UnuseAllInputs();

        JoinEntryInstr* new_join =
            BranchSimplifier::ToJoinEntry(zone(), old_target);
        old_target->ReplaceAsPredecessorWith(new_join);
        for (intptr_t j = 0; j < old_target->dominated_blocks().length(); ++j) {
          BlockEntryInstr* block = old_target->dominated_blocks()[j];
          new_join->AddDominatedBlock(block);
        }
        // Create a new target with the join as unconditional successor.
        TargetEntryInstr* new_target = new TargetEntryInstr(
            AllocateBlockId(), old_target->try_index(), Thread::kNoDeoptId);
        new_target->InheritDeoptTarget(zone(), new_join);
        GotoInstr* new_goto = new (Z) GotoInstr(new_join, Thread::kNoDeoptId);
        new_goto->InheritDeoptTarget(zone(), new_join);
        new_target->LinkTo(new_goto);
        new_target->set_last_instruction(new_goto);
        new_join->predecessors_.Add(new_target);

        // Record the new target for the first variant.
        inlined_entries_[i] = new_target;
      }
      ASSERT(inlined_entries_[i]->IsTargetEntry());
      // Record the shared join for this variant.
      BlockEntryInstr* join =
          inlined_entries_[i]->last_instruction()->SuccessorAt(0);
      ASSERT(join->IsJoinEntry());
      inlined_entries_.Add(join);
      return true;
    }
  }

  return false;
}


bool PolymorphicInliner::CheckNonInlinedDuplicate(const Function& target) {
  for (intptr_t i = 0; i < non_inlined_variants_->length(); ++i) {
    if (target.raw() == non_inlined_variants_->TargetAt(i)->target->raw()) {
      return true;
    }
  }

  return false;
}


bool PolymorphicInliner::TryInliningPoly(const TargetInfo& target_info) {
  if ((!FLAG_precompiled_mode ||
       owner_->inliner_->use_speculative_inlining()) &&
      target_info.IsSingleCid() &&
      TryInlineRecognizedMethod(target_info.cid_start, *target_info.target)) {
    owner_->inlined_ = true;
    return true;
  }

  GrowableArray<Value*> arguments(call_->ArgumentCount());
  for (int i = 0; i < call_->ArgumentCount(); ++i) {
    arguments.Add(call_->PushArgumentAt(i)->value());
  }
  InlinedCallData call_data(call_, &arguments, caller_function_,
                            caller_inlining_id_);
  Function& target = Function::ZoneHandle(zone(), target_info.target->raw());
  if (!owner_->TryInlining(target, call_->instance_call()->argument_names(),
                           &call_data)) {
    return false;
  }

  FlowGraph* callee_graph = call_data.callee_graph;
  call_data.exit_collector->PrepareGraphs(callee_graph);
  inlined_entries_.Add(callee_graph->graph_entry());
  exit_collector_->Union(call_data.exit_collector);

  // Replace parameter stubs and constants.  Replace the receiver argument
  // with a redefinition to prevent code from the inlined body from being
  // hoisted above the inlined entry.
  ASSERT(arguments.length() > 0);
  Value* actual = arguments[0];
  RedefinitionInstr* redefinition = new (Z) RedefinitionInstr(actual->Copy(Z));
  redefinition->set_ssa_temp_index(
      owner_->caller_graph()->alloc_ssa_temp_index());
  if (target_info.IsSingleCid()) {
    redefinition->UpdateType(CompileType::FromCid(target_info.cid_start));
  }
  redefinition->InsertAfter(callee_graph->graph_entry()->normal_entry());
  Definition* stub = (*call_data.parameter_stubs)[0];
  stub->ReplaceUsesWith(redefinition);

  for (intptr_t i = 1; i < arguments.length(); ++i) {
    actual = arguments[i];
    if (actual != NULL) {
      stub = (*call_data.parameter_stubs)[i];
      stub->ReplaceUsesWith(actual->definition());
    }
  }
  GrowableArray<Definition*>* defns =
      callee_graph->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < defns->length(); ++i) {
    ConstantInstr* constant = (*defns)[i]->AsConstant();
    if ((constant != NULL) && constant->HasUses()) {
      constant->ReplaceUsesWith(
          owner_->caller_graph()->GetConstant(constant->value()));
    }
    CurrentContextInstr* context = (*defns)[i]->AsCurrentContext();
    if ((context != NULL) && context->HasUses()) {
      ASSERT(call_data.call->IsClosureCall());
      LoadFieldInstr* context_load = new (Z)
          LoadFieldInstr(new Value(redefinition), Closure::context_offset(),
                         AbstractType::ZoneHandle(zone(), AbstractType::null()),
                         call_data.call->token_pos());
      context_load->set_is_immutable(true);
      context_load->set_ssa_temp_index(
          owner_->caller_graph()->alloc_ssa_temp_index());
      context_load->InsertAfter(redefinition);
      context->ReplaceUsesWith(context_load);
    }
  }
  return true;
}


static Instruction* AppendInstruction(Instruction* first, Instruction* second) {
  for (intptr_t i = second->InputCount() - 1; i >= 0; --i) {
    Value* input = second->InputAt(i);
    input->definition()->AddInputUse(input);
  }
  first->LinkTo(second);
  return second;
}


bool PolymorphicInliner::TryInlineRecognizedMethod(intptr_t receiver_cid,
                                                   const Function& target) {
  TargetEntryInstr* entry;
  Definition* last;
  // Replace the receiver argument with a redefinition to prevent code from
  // the inlined body from being hoisted above the inlined entry.
  GrowableArray<Definition*> arguments(call_->ArgumentCount());
  Definition* receiver = call_->ArgumentAt(0);
  RedefinitionInstr* redefinition =
      new (Z) RedefinitionInstr(new (Z) Value(receiver));
  redefinition->set_ssa_temp_index(
      owner_->caller_graph()->alloc_ssa_temp_index());
  if (FlowGraphInliner::TryInlineRecognizedMethod(
          owner_->caller_graph(), receiver_cid, target, call_, redefinition,
          call_->instance_call()->token_pos(),
          *call_->instance_call()->ic_data(), &entry, &last)) {
    // Create a graph fragment.
    redefinition->InsertAfter(entry);
    InlineExitCollector* exit_collector =
        new (Z) InlineExitCollector(owner_->caller_graph(), call_);

    ReturnInstr* result =
        new (Z) ReturnInstr(call_->instance_call()->token_pos(),
                            new (Z) Value(last), Thread::kNoDeoptId);
    owner_->caller_graph()->AppendTo(
        last, result,
        call_->env(),  // Return can become deoptimization target.
        FlowGraph::kEffect);
    entry->set_last_instruction(result);
    exit_collector->AddExit(result);
    ParsedFunction* temp_parsed_function =
        new ParsedFunction(Thread::Current(), target);
    GraphEntryInstr* graph_entry = new (Z)
        GraphEntryInstr(*temp_parsed_function, entry, Compiler::kNoOSRDeoptId);
    // Update polymorphic inliner state.
    inlined_entries_.Add(graph_entry);
    exit_collector_->Union(exit_collector);
    return true;
  }
  return false;
}


// Build a DAG to dispatch to the inlined function bodies.  Load the class
// id of the receiver and make explicit comparisons for each inlined body,
// in frequency order.  If all variants are inlined, the entry to the last
// inlined body is guarded by a CheckClassId instruction which can deopt.
// If not all variants are inlined, we add a PolymorphicInstanceCall
// instruction to handle the non-inlined variants.
TargetEntryInstr* PolymorphicInliner::BuildDecisionGraph() {
  const intptr_t try_idx = call_->GetBlock()->try_index();

  // Start with a fresh target entry.
  TargetEntryInstr* entry = new (Z) TargetEntryInstr(
      AllocateBlockId(), try_idx, Thread::Current()->GetNextDeoptId());
  entry->InheritDeoptTarget(zone(), call_);

  // This function uses a cursor (a pointer to the 'current' instruction) to
  // build the graph.  The next instruction will be inserted after the
  // cursor.
  BlockEntryInstr* current_block = entry;
  Instruction* cursor = entry;

  Definition* receiver = call_->ArgumentAt(0);
  // There are at least two variants including non-inlined ones, so we have
  // at least one branch on the class id.
  LoadClassIdInstr* load_cid =
      new (Z) LoadClassIdInstr(new (Z) Value(receiver));
  load_cid->set_ssa_temp_index(owner_->caller_graph()->alloc_ssa_temp_index());
  cursor = AppendInstruction(cursor, load_cid);
  for (intptr_t i = 0; i < inlined_variants_.length(); ++i) {
    const CidRange& variant = inlined_variants_[i];
    bool test_is_range = !variant.IsSingleCid();
    bool is_last_test = (i == inlined_variants_.length() - 1);
    // 1. Guard the body with a class id check.  We don't need any check if
    // it's the last test and global analysis has told us that the call is
    // complete.
    if (is_last_test && non_inlined_variants_->is_empty()) {
      // If it is the last variant use a check class id instruction which can
      // deoptimize, followed unconditionally by the body. Omit the check if
      // we know that we have covered all possible classes.
      if (!call_->complete()) {
        RedefinitionInstr* cid_redefinition =
            new RedefinitionInstr(new (Z) Value(load_cid));
        cid_redefinition->set_ssa_temp_index(
            owner_->caller_graph()->alloc_ssa_temp_index());
        cursor = AppendInstruction(cursor, cid_redefinition);
        CheckClassIdInstr* check_class_id = new (Z) CheckClassIdInstr(
            new (Z) Value(cid_redefinition), variant, call_->deopt_id());
        check_class_id->InheritDeoptTarget(zone(), call_);
        cursor = AppendInstruction(cursor, check_class_id);
      }

      // The next instruction is the first instruction of the inlined body.
      // Handle the two possible cases (unshared and shared subsequent
      // predecessors) separately.
      BlockEntryInstr* callee_entry = inlined_entries_[i];
      if (callee_entry->IsGraphEntry()) {
        // Unshared.  Graft the normal entry on after the check class
        // instruction.
        TargetEntryInstr* target = callee_entry->AsGraphEntry()->normal_entry();
        cursor->LinkTo(target->next());
        target->ReplaceAsPredecessorWith(current_block);
        // Unuse all inputs of the graph entry and the normal entry. They are
        // not in the graph anymore.
        callee_entry->UnuseAllInputs();
        target->UnuseAllInputs();
        // All blocks that were dominated by the normal entry are now
        // dominated by the current block.
        for (intptr_t j = 0; j < target->dominated_blocks().length(); ++j) {
          BlockEntryInstr* block = target->dominated_blocks()[j];
          current_block->AddDominatedBlock(block);
        }
      } else if (callee_entry->IsJoinEntry()) {
        // Shared inlined body and this is a subsequent entry.  We have
        // already constructed a join and set its dominator.  Add a jump to
        // the join.
        JoinEntryInstr* join = callee_entry->AsJoinEntry();
        ASSERT(join->dominator() != NULL);
        GotoInstr* goto_join = new GotoInstr(join, Thread::kNoDeoptId);
        goto_join->InheritDeoptTarget(zone(), join);
        cursor->LinkTo(goto_join);
        current_block->set_last_instruction(goto_join);
      } else {
        // There is no possibility of a TargetEntry (the first entry to a
        // shared inlined body) because this is the last inlined entry.
        UNREACHABLE();
      }
      cursor = NULL;
    } else {
      // For all variants except the last, use a branch on the loaded class
      // id.
      const Smi& cid = Smi::ZoneHandle(Smi::New(variant.cid_start));
      ConstantInstr* cid_constant = owner_->caller_graph()->GetConstant(cid);
      BranchInstr* branch;
      BranchInstr* upper_limit_branch = NULL;
      BlockEntryInstr* cid_test_entry_block = current_block;
      if (test_is_range) {
        // Double branch for testing a range of Cids.  TODO(erikcorry): Make a
        // special instruction that uses subtraction and unsigned comparison to
        // do this with a single branch.
        const Smi& cid_end = Smi::ZoneHandle(Smi::New(variant.cid_end));
        ConstantInstr* cid_constant_end =
            owner_->caller_graph()->GetConstant(cid_end);
        RelationalOpInstr* compare_top = new RelationalOpInstr(
            call_->instance_call()->token_pos(), Token::kLTE,
            new Value(load_cid), new Value(cid_constant_end), kSmiCid,
            call_->deopt_id());
        BranchInstr* branch_top = upper_limit_branch =
            new BranchInstr(compare_top, Thread::kNoDeoptId);
        branch_top->InheritDeoptTarget(zone(), call_);
        cursor = AppendInstruction(cursor, branch_top);
        current_block->set_last_instruction(branch_top);

        TargetEntryInstr* below_target = new TargetEntryInstr(
            AllocateBlockId(), try_idx, Thread::kNoDeoptId);
        below_target->InheritDeoptTarget(zone(), call_);
        current_block->AddDominatedBlock(below_target);
        cursor = current_block = below_target;
        *branch_top->true_successor_address() = below_target;

        RelationalOpInstr* compare_bottom = new RelationalOpInstr(
            call_->instance_call()->token_pos(), Token::kGTE,
            new Value(load_cid), new Value(cid_constant), kSmiCid,
            call_->deopt_id());
        branch = new BranchInstr(compare_bottom, Thread::kNoDeoptId);
      } else {
        StrictCompareInstr* compare = new StrictCompareInstr(
            call_->instance_call()->token_pos(), Token::kEQ_STRICT,
            new Value(load_cid), new Value(cid_constant),
            /* number_check = */ false, Thread::kNoDeoptId);
        branch = new BranchInstr(compare, Thread::kNoDeoptId);
      }

      branch->InheritDeoptTarget(zone(), call_);
      cursor = AppendInstruction(cursor, branch);
      current_block->set_last_instruction(branch);
      cursor = NULL;

      // 2. Handle a match by linking to the inlined body.  There are three
      // cases (unshared, shared first predecessor, and shared subsequent
      // predecessors).
      BlockEntryInstr* callee_entry = inlined_entries_[i];
      TargetEntryInstr* true_target = NULL;
      if (callee_entry->IsGraphEntry()) {
        // Unshared.
        true_target = callee_entry->AsGraphEntry()->normal_entry();
        // Unuse all inputs of the graph entry. It is not in the graph anymore.
        callee_entry->UnuseAllInputs();
      } else if (callee_entry->IsTargetEntry()) {
        // Shared inlined body and this is the first entry.  We have already
        // constructed a join and this target jumps to it.
        true_target = callee_entry->AsTargetEntry();
        BlockEntryInstr* join = true_target->last_instruction()->SuccessorAt(0);
        current_block->AddDominatedBlock(join);
      } else {
        // Shared inlined body and this is a subsequent entry.  We have
        // already constructed a join.  We need a fresh target that jumps to
        // the join.
        JoinEntryInstr* join = callee_entry->AsJoinEntry();
        ASSERT(join != NULL);
        ASSERT(join->dominator() != NULL);
        true_target = new TargetEntryInstr(AllocateBlockId(), try_idx,
                                           Thread::kNoDeoptId);
        true_target->InheritDeoptTarget(zone(), join);
        GotoInstr* goto_join = new GotoInstr(join, Thread::kNoDeoptId);
        goto_join->InheritDeoptTarget(zone(), join);
        true_target->LinkTo(goto_join);
        true_target->set_last_instruction(goto_join);
      }
      *branch->true_successor_address() = true_target;
      current_block->AddDominatedBlock(true_target);

      // 3. Prepare to handle a match failure on the next iteration or the
      // fall-through code below for non-inlined variants.

      TargetEntryInstr* false_target =
          new TargetEntryInstr(AllocateBlockId(), try_idx, Thread::kNoDeoptId);
      false_target->InheritDeoptTarget(zone(), call_);
      *branch->false_successor_address() = false_target;
      cid_test_entry_block->AddDominatedBlock(false_target);

      cursor = current_block = false_target;

      if (test_is_range) {
        // If we tested against a range of Cids there are two different tests
        // that can go to the no-cid-match target.
        JoinEntryInstr* join =
            new JoinEntryInstr(AllocateBlockId(), try_idx, Thread::kNoDeoptId);
        TargetEntryInstr* false_target2 = new TargetEntryInstr(
            AllocateBlockId(), try_idx, Thread::kNoDeoptId);
        *upper_limit_branch->false_successor_address() = false_target2;
        cid_test_entry_block->AddDominatedBlock(false_target2);
        cid_test_entry_block->AddDominatedBlock(join);
        GotoInstr* goto_1 = new GotoInstr(join, Thread::kNoDeoptId);
        GotoInstr* goto_2 = new GotoInstr(join, Thread::kNoDeoptId);
        false_target->LinkTo(goto_1);
        false_target2->LinkTo(goto_2);
        false_target->set_last_instruction(goto_1);
        false_target2->set_last_instruction(goto_2);

        join->InheritDeoptTarget(zone(), call_);
        false_target2->InheritDeoptTarget(zone(), call_);
        goto_1->InheritDeoptTarget(zone(), call_);
        goto_2->InheritDeoptTarget(zone(), call_);

        cursor = current_block = join;
      }
    }
  }

  // Handle any non-inlined variants.
  if (!non_inlined_variants_->is_empty()) {
    // Move push arguments of the call.
    for (intptr_t i = 0; i < call_->ArgumentCount(); ++i) {
      PushArgumentInstr* push = call_->PushArgumentAt(i);
      push->ReplaceUsesWith(push->value()->definition());
      push->previous()->LinkTo(push->next());
      cursor->LinkTo(push);
      cursor = push;
    }
    PolymorphicInstanceCallInstr* fallback_call =
        new PolymorphicInstanceCallInstr(
            call_->instance_call(), *non_inlined_variants_, call_->complete());
    fallback_call->set_ssa_temp_index(
        owner_->caller_graph()->alloc_ssa_temp_index());
    fallback_call->InheritDeoptTarget(zone(), call_);
    fallback_call->set_total_call_count(call_->CallCount());
    ReturnInstr* fallback_return =
        new ReturnInstr(call_->instance_call()->token_pos(),
                        new Value(fallback_call), Thread::kNoDeoptId);
    fallback_return->InheritDeoptTargetAfter(owner_->caller_graph(), call_,
                                             fallback_call);
    AppendInstruction(AppendInstruction(cursor, fallback_call),
                      fallback_return);
    exit_collector_->AddExit(fallback_return);
    cursor = NULL;
  } else {
    // Remove push arguments of the call.
    for (intptr_t i = 0; i < call_->ArgumentCount(); ++i) {
      PushArgumentInstr* push = call_->PushArgumentAt(i);
      push->ReplaceUsesWith(push->value()->definition());
      push->RemoveFromGraph();
    }
  }
  return entry;
}


static void TracePolyInlining(const CallTargets& targets,
                              intptr_t idx,
                              intptr_t total,
                              const char* message) {
  String& name =
      String::Handle(targets.TargetAt(idx)->target->QualifiedUserVisibleName());
  int percent = total == 0 ? 0 : (100 * targets.TargetAt(idx)->count) / total;
  THR_Print("%s cid %" Pd "-%" Pd ": %" Pd "/%" Pd " %d%% %s\n",
            name.ToCString(), targets[idx].cid_start, targets[idx].cid_end,
            targets.TargetAt(idx)->count, total, percent, message);
}


bool PolymorphicInliner::trace_inlining() const {
  return owner_->trace_inlining();
}


void PolymorphicInliner::Inline() {
  ASSERT(&variants_ == &call_->targets_);

  intptr_t total = call_->total_call_count();
  for (intptr_t var_idx = 0; var_idx < variants_.length(); ++var_idx) {
    TargetInfo* info = variants_.TargetAt(var_idx);
    if (variants_.length() > FLAG_max_polymorphic_checks) {
      non_inlined_variants_->Add(info);
      continue;
    }

    const Function& target = *variants_.TargetAt(var_idx)->target;
    const intptr_t count = variants_.TargetAt(var_idx)->count;

    // We we almost inlined all the cases then try a little harder to inline
    // the last two, because it's a big win if we inline all of them (compiler
    // can see all side effects).
    const bool try_harder = (var_idx >= variants_.length() - 2) &&
                            non_inlined_variants_->length() == 0;

    intptr_t size = target.optimized_instruction_count();
    bool small = (size != 0 && size < FLAG_inlining_size_threshold);

    // If it's less than 3% of the dispatches, we won't even consider
    // checking for the class ID and branching to another already-inlined
    // version.
    if (!try_harder && count < (total >> 5)) {
      TRACE_INLINING(
          TracePolyInlining(variants_, var_idx, total, "way too infrequent"));
      non_inlined_variants_->Add(info);
      continue;
    }

    // First check if this is the same target as an earlier inlined variant.
    if (CheckInlinedDuplicate(target)) {
      TRACE_INLINING(TracePolyInlining(variants_, var_idx, total,
                                       "duplicate already inlined"));
      inlined_variants_.Add(info);
      continue;
    }

    // If it's less than 12% of the dispatches and it's not already inlined, we
    // don't consider inlining.  For very small functions we are willing to
    // consider inlining for 6% of the cases.
    if (!try_harder && count < (total >> (small ? 4 : 3))) {
      TRACE_INLINING(
          TracePolyInlining(variants_, var_idx, total, "too infrequent"));
      non_inlined_variants_->Add(&variants_[var_idx]);
      continue;
    }

    // Also check if this is the same target as an earlier non-inlined
    // variant.  If so and since inlining decisions are costly, do not try
    // to inline this variant.
    if (CheckNonInlinedDuplicate(target)) {
      TRACE_INLINING(
          TracePolyInlining(variants_, var_idx, total, "already not inlined"));
      non_inlined_variants_->Add(&variants_[var_idx]);
      continue;
    }

    // Make an inlining decision.
    if (TryInliningPoly(*info)) {
      TRACE_INLINING(TracePolyInlining(variants_, var_idx, total, "inlined"));
      inlined_variants_.Add(&variants_[var_idx]);
    } else {
      TRACE_INLINING(
          TracePolyInlining(variants_, var_idx, total, "not inlined"));
      non_inlined_variants_->Add(&variants_[var_idx]);
    }
  }

  // If there are no inlined variants, leave the call in place.
  if (inlined_variants_.is_empty()) return;

  // Now build a decision tree (a DAG because of shared inline variants) and
  // inline it at the call site.
  TargetEntryInstr* entry = BuildDecisionGraph();
  exit_collector_->ReplaceCall(entry);
}


static uint16_t ClampUint16(intptr_t v) {
  return (v > 0xFFFF) ? 0xFFFF : static_cast<uint16_t>(v);
}


static bool ShouldTraceInlining(FlowGraph* flow_graph) {
  const Function& top = flow_graph->parsed_function().function();
  return FLAG_trace_inlining && FlowGraphPrinter::ShouldPrint(top);
}


FlowGraphInliner::FlowGraphInliner(
    FlowGraph* flow_graph,
    GrowableArray<const Function*>* inline_id_to_function,
    GrowableArray<TokenPosition>* inline_id_to_token_pos,
    GrowableArray<intptr_t>* caller_inline_id,
    bool use_speculative_inlining,
    GrowableArray<intptr_t>* inlining_black_list,
    Precompiler* precompiler)
    : flow_graph_(flow_graph),
      inline_id_to_function_(inline_id_to_function),
      inline_id_to_token_pos_(inline_id_to_token_pos),
      caller_inline_id_(caller_inline_id),
      trace_inlining_(ShouldTraceInlining(flow_graph)),
      use_speculative_inlining_(use_speculative_inlining),
      inlining_black_list_(inlining_black_list),
      precompiler_(precompiler) {
  ASSERT(!use_speculative_inlining || (inlining_black_list != NULL));
}


void FlowGraphInliner::CollectGraphInfo(FlowGraph* flow_graph, bool force) {
  const Function& function = flow_graph->function();
  if (force || (function.optimized_instruction_count() == 0)) {
    GraphInfoCollector info;
    info.Collect(*flow_graph);

    function.set_optimized_instruction_count(
        ClampUint16(info.instruction_count()));
    function.set_optimized_call_site_count(ClampUint16(info.call_site_count()));
  }
}


// TODO(srdjan): This is only needed when disassembling and/or profiling.
// Sets inlining id for all instructions of this flow-graph, as well for the
// FlowGraph itself.
void FlowGraphInliner::SetInliningId(FlowGraph* flow_graph,
                                     intptr_t inlining_id) {
  ASSERT(flow_graph->inlining_id() < 0);
  flow_graph->set_inlining_id(inlining_id);
  for (BlockIterator block_it = flow_graph->postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      Instruction* current = it.Current();
      // Do not overwrite owner function.
      ASSERT(!current->has_inlining_id());
      current->set_inlining_id(inlining_id);
    }
  }
}


// Use function name to determine if inlineable operator.
// Add names as necessary.
static bool IsInlineableOperator(const Function& function) {
  return (function.name() == Symbols::IndexToken().raw()) ||
         (function.name() == Symbols::AssignIndexToken().raw()) ||
         (function.name() == Symbols::Plus().raw()) ||
         (function.name() == Symbols::Minus().raw());
}


bool FlowGraphInliner::AlwaysInline(const Function& function) {
  const char* kAlwaysInlineAnnotation = "AlwaysInline";
  if (FLAG_enable_inlining_annotations &&
      HasAnnotation(function, kAlwaysInlineAnnotation)) {
    TRACE_INLINING(
        THR_Print("AlwaysInline annotation for %s\n", function.ToCString()));
    return true;
  }

  if (function.IsDispatcherOrImplicitAccessor()) {
    // Smaller or same size as the call.
    return true;
  }

  if (function.is_const()) {
    // Inlined const fields are smaller than a call.
    return true;
  }

  if (function.IsGetterFunction() || function.IsSetterFunction() ||
      IsInlineableOperator(function) ||
      (function.kind() == RawFunction::kConstructor)) {
    const intptr_t count = function.optimized_instruction_count();
    if ((count != 0) && (count < FLAG_inline_getters_setters_smaller_than)) {
      return true;
    }
  }
  return MethodRecognizer::AlwaysInline(function);
}


void FlowGraphInliner::Inline() {
  // Collect graph info and store it on the function.
  // We might later use it for an early bailout from the inlining.
  CollectGraphInfo(flow_graph_);

  const Function& top = flow_graph_->function();
  if ((FLAG_inlining_filter != NULL) &&
      (strstr(top.ToFullyQualifiedCString(), FLAG_inlining_filter) == NULL)) {
    return;
  }

  if (trace_inlining()) {
    String& name = String::Handle(top.QualifiedUserVisibleName());
    THR_Print("Inlining calls in %s\n", name.ToCString());
  }

  if (FLAG_support_il_printer && trace_inlining() &&
      (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized)) {
    THR_Print("Before Inlining of %s\n",
              flow_graph_->function().ToFullyQualifiedCString());
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }

  intptr_t inlining_depth_threshold = FLAG_inlining_depth_threshold;
  if ((precompiler_ != NULL) && precompiler_->HasFeedback() &&
      (top.usage_counter() <= 0)) {
    inlining_depth_threshold = 1;
  }

  CallSiteInliner inliner(this, inlining_depth_threshold);
  inliner.InlineCalls();
  if (FLAG_print_inlining_tree) {
    inliner.PrintInlinedInfo(top);
  }

  if (inliner.inlined()) {
    flow_graph_->DiscoverBlocks();
    if (trace_inlining()) {
      THR_Print("Inlining growth factor: %f\n", inliner.GrowthFactor());
      if (FLAG_support_il_printer &&
          (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized)) {
        THR_Print("After Inlining of %s\n",
                  flow_graph_->function().ToFullyQualifiedCString());
        FlowGraphPrinter printer(*flow_graph_);
        printer.PrintBlocks();
      }
    }
  }
}


intptr_t FlowGraphInliner::NextInlineId(const Function& function,
                                        TokenPosition tp,
                                        intptr_t parent_id) {
  const intptr_t id = inline_id_to_function_->length();
  // TODO(johnmccutchan): Do not allow IsNoSource once all nodes have proper
  // source positions.
  ASSERT(tp.IsReal() || tp.IsSynthetic() || tp.IsNoSource());
  inline_id_to_function_->Add(&function);
  inline_id_to_token_pos_->Add(tp);
  caller_inline_id_->Add(parent_id);
  // We always have one less token position than functions.
  ASSERT(inline_id_to_token_pos_->length() ==
         (inline_id_to_function_->length() - 1));
  return id;
}


static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}


static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}


static bool ShouldInlineInt64ArrayOps() {
#if defined(TARGET_ARCH_X64)
  return true;
#else
  return false;
#endif
}


static bool CanUnboxInt32() {
  // Int32/Uint32 can be unboxed if it fits into a smi or the platform
  // supports unboxed mints.
  return (kSmiBits >= 32) || FlowGraphCompiler::SupportsUnboxedMints();
}


// Quick access to the current one.
#undef Z
#define Z (flow_graph->zone())

static intptr_t PrepareInlineIndexedOp(FlowGraph* flow_graph,
                                       Instruction* call,
                                       intptr_t array_cid,
                                       Definition** array,
                                       Definition* index,
                                       Instruction** cursor) {
  // Insert array length load and bounds check.
  LoadFieldInstr* length = new (Z) LoadFieldInstr(
      new (Z) Value(*array), CheckArrayBoundInstr::LengthOffsetFor(array_cid),
      Type::ZoneHandle(Z, Type::SmiType()), call->token_pos());
  length->set_is_immutable(
      CheckArrayBoundInstr::IsFixedLengthArrayType(array_cid));
  length->set_result_cid(kSmiCid);
  length->set_recognized_kind(
      LoadFieldInstr::RecognizedKindFromArrayCid(array_cid));
  *cursor = flow_graph->AppendTo(*cursor, length, NULL, FlowGraph::kValue);

  *cursor = flow_graph->AppendTo(
      *cursor,
      new (Z) CheckArrayBoundInstr(new (Z) Value(length), new (Z) Value(index),
                                   call->deopt_id()),
      call->env(), FlowGraph::kEffect);

  if (array_cid == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements = new (Z) LoadFieldInstr(
        new (Z) Value(*array), GrowableObjectArray::data_offset(),
        Object::dynamic_type(), call->token_pos());
    elements->set_result_cid(kArrayCid);
    *cursor = flow_graph->AppendTo(*cursor, elements, NULL, FlowGraph::kValue);
    // Load from the data from backing store which is a fixed-length array.
    *array = elements;
    array_cid = kArrayCid;
  } else if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    LoadUntaggedInstr* elements = new (Z) LoadUntaggedInstr(
        new (Z) Value(*array), ExternalTypedData::data_offset());
    *cursor = flow_graph->AppendTo(*cursor, elements, NULL, FlowGraph::kValue);
    *array = elements;
  }
  return array_cid;
}


static bool InlineGetIndexed(FlowGraph* flow_graph,
                             MethodRecognizer::Kind kind,
                             Instruction* call,
                             Definition* receiver,
                             TargetEntryInstr** entry,
                             Definition** last) {
  intptr_t array_cid = MethodRecognizer::MethodKindToReceiverCid(kind);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineIndexedOp(flow_graph, call, array_cid, &array, index,
                                     &cursor);

  intptr_t deopt_id = Thread::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id = (kSmiBits >= 32) ? Thread::kNoDeoptId : call->deopt_id();
  }

  // Array load and return.
  intptr_t index_scale = Instance::ElementSizeFor(array_cid);
  *last = new (Z)
      LoadIndexedInstr(new (Z) Value(array), new (Z) Value(index), index_scale,
                       array_cid, kAlignedAccess, deopt_id, call->token_pos());
  cursor = flow_graph->AppendTo(
      cursor, *last, deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);

  if (array_cid == kTypedDataFloat32ArrayCid) {
    *last = new (Z) FloatToDoubleInstr(new (Z) Value(*last), deopt_id);
    flow_graph->AppendTo(cursor, *last,
                         deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
                         FlowGraph::kValue);
  }
  return true;
}


static bool InlineSetIndexed(FlowGraph* flow_graph,
                             MethodRecognizer::Kind kind,
                             const Function& target,
                             Instruction* call,
                             Definition* receiver,
                             TokenPosition token_pos,
                             const Cids* value_check,
                             TargetEntryInstr** entry,
                             Definition** last) {
  intptr_t array_cid = MethodRecognizer::MethodKindToReceiverCid(kind);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  if (flow_graph->isolate()->type_checks()) {
    // Only type check for the value. A type check for the index is not
    // needed here because we insert a deoptimizing smi-check for the case
    // the index is not a smi.
    const AbstractType& value_type =
        AbstractType::ZoneHandle(Z, target.ParameterTypeAt(2));
    Definition* type_args = NULL;
    switch (array_cid) {
      case kArrayCid:
      case kGrowableObjectArrayCid: {
        const Class& instantiator_class = Class::Handle(Z, target.Owner());
        intptr_t type_arguments_field_offset =
            instantiator_class.type_arguments_field_offset();
        LoadFieldInstr* load_type_args = new (Z)
            LoadFieldInstr(new (Z) Value(array), type_arguments_field_offset,
                           Type::ZoneHandle(Z),  // No type.
                           call->token_pos());
        cursor = flow_graph->AppendTo(cursor, load_type_args, NULL,
                                      FlowGraph::kValue);

        type_args = load_type_args;
        break;
      }
      case kTypedDataInt8ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
      case kTypedDataInt16ArrayCid:
      case kTypedDataUint16ArrayCid:
      case kTypedDataInt32ArrayCid:
      case kTypedDataUint32ArrayCid:
      case kTypedDataInt64ArrayCid:
        ASSERT(value_type.IsIntType());
      // Fall through.
      case kTypedDataFloat32ArrayCid:
      case kTypedDataFloat64ArrayCid: {
        type_args = flow_graph->constant_null();
        ASSERT((array_cid != kTypedDataFloat32ArrayCid &&
                array_cid != kTypedDataFloat64ArrayCid) ||
               value_type.IsDoubleType());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat32x4ArrayCid: {
        type_args = flow_graph->constant_null();
        ASSERT(value_type.IsFloat32x4Type());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat64x2ArrayCid: {
        type_args = flow_graph->constant_null();
        ASSERT(value_type.IsFloat64x2Type());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      default:
        // TODO(fschneider): Add support for other array types.
        UNREACHABLE();
    }
    AssertAssignableInstr* assert_value = new (Z) AssertAssignableInstr(
        token_pos, new (Z) Value(stored_value), new (Z) Value(type_args),
        new (Z) Value(flow_graph->constant_null()),  // Function type arguments.
        value_type, Symbols::Value(), call->deopt_id());
    cursor = flow_graph->AppendTo(cursor, assert_value, call->env(),
                                  FlowGraph::kValue);
  }

  array_cid = PrepareInlineIndexedOp(flow_graph, call, array_cid, &array, index,
                                     &cursor);

  // Check if store barrier is needed. Byte arrays don't need a store barrier.
  StoreBarrierType needs_store_barrier =
      (RawObject::IsTypedDataClassId(array_cid) ||
       RawObject::IsTypedDataViewClassId(array_cid) ||
       RawObject::IsExternalTypedDataClassId(array_cid))
          ? kNoStoreBarrier
          : kEmitStoreBarrier;

  // No need to class check stores to Int32 and Uint32 arrays because
  // we insert unboxing instructions below which include a class check.
  if ((array_cid != kTypedDataUint32ArrayCid) &&
      (array_cid != kTypedDataInt32ArrayCid) && value_check != NULL) {
    // No store barrier needed because checked value is a smi, an unboxed mint,
    // an unboxed double, an unboxed Float32x4, or unboxed Int32x4.
    needs_store_barrier = kNoStoreBarrier;
    Instruction* check = flow_graph->CreateCheckClass(
        stored_value, *value_check, call->deopt_id(), call->token_pos());
    cursor =
        flow_graph->AppendTo(cursor, check, call->env(), FlowGraph::kEffect);
  }

  if (array_cid == kTypedDataFloat32ArrayCid) {
    stored_value = new (Z)
        DoubleToFloatInstr(new (Z) Value(stored_value), call->deopt_id());
    cursor =
        flow_graph->AppendTo(cursor, stored_value, NULL, FlowGraph::kValue);
  } else if (array_cid == kTypedDataInt32ArrayCid) {
    stored_value =
        new (Z) UnboxInt32Instr(UnboxInt32Instr::kTruncate,
                                new (Z) Value(stored_value), call->deopt_id());
    cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                  FlowGraph::kValue);
  } else if (array_cid == kTypedDataUint32ArrayCid) {
    stored_value =
        new (Z) UnboxUint32Instr(new (Z) Value(stored_value), call->deopt_id());
    ASSERT(stored_value->AsUnboxInteger()->is_truncating());
    cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                  FlowGraph::kValue);
  }

  const intptr_t index_scale = Instance::ElementSizeFor(array_cid);
  *last = new (Z) StoreIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), new (Z) Value(stored_value),
      needs_store_barrier, index_scale, array_cid, kAlignedAccess,
      call->deopt_id(), call->token_pos());
  flow_graph->AppendTo(cursor, *last, call->env(), FlowGraph::kEffect);
  return true;
}


static bool InlineDoubleOp(FlowGraph* flow_graph,
                           Token::Kind op_kind,
                           Instruction* call,
                           Definition* receiver,
                           TargetEntryInstr** entry,
                           Definition** last) {
  if (!CanUnboxDouble()) {
    return false;
  }
  Definition* left = receiver;
  Definition* right = call->ArgumentAt(1);

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  // Arguments are checked. No need for class check.
  BinaryDoubleOpInstr* double_bin_op = new (Z)
      BinaryDoubleOpInstr(op_kind, new (Z) Value(left), new (Z) Value(right),
                          call->deopt_id(), call->token_pos());
  flow_graph->AppendTo(*entry, double_bin_op, call->env(), FlowGraph::kValue);
  *last = double_bin_op;

  return true;
}


static bool InlineDoubleTestOp(FlowGraph* flow_graph,
                               Instruction* call,
                               Definition* receiver,
                               MethodRecognizer::Kind kind,
                               TargetEntryInstr** entry,
                               Definition** last) {
  if (!CanUnboxDouble()) {
    return false;
  }

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  // Arguments are checked. No need for class check.

  DoubleTestOpInstr* double_test_op = new (Z) DoubleTestOpInstr(
      kind, new (Z) Value(receiver), call->deopt_id(), call->token_pos());
  flow_graph->AppendTo(*entry, double_test_op, call->env(), FlowGraph::kValue);
  *last = double_test_op;

  return true;
}


static bool InlineSmiBitAndFromSmi(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   TargetEntryInstr** entry,
                                   Definition** last) {
  Definition* left = receiver;
  Definition* right = call->ArgumentAt(1);

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  // Right arguments is known to be smi: other._bitAndFromSmi(this);
  BinarySmiOpInstr* smi_op =
      new (Z) BinarySmiOpInstr(Token::kBIT_AND, new (Z) Value(left),
                               new (Z) Value(right), call->deopt_id());
  flow_graph->AppendTo(*entry, smi_op, call->env(), FlowGraph::kValue);
  *last = smi_op;

  return true;
}


static bool InlineGrowableArraySetter(FlowGraph* flow_graph,
                                      intptr_t offset,
                                      StoreBarrierType store_barrier_type,
                                      Instruction* call,
                                      Definition* receiver,
                                      TargetEntryInstr** entry,
                                      Definition** last) {
  Definition* array = receiver;
  Definition* value = call->ArgumentAt(1);

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);

  // This is an internal method, no need to check argument types.
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      offset, new (Z) Value(array), new (Z) Value(value), store_barrier_type,
      call->token_pos());
  flow_graph->AppendTo(*entry, store, call->env(), FlowGraph::kEffect);
  *last = store;

  return true;
}


static void PrepareInlineByteArrayBaseOp(FlowGraph* flow_graph,
                                         Instruction* call,
                                         intptr_t array_cid,
                                         intptr_t view_cid,
                                         Definition** array,
                                         Definition* byte_index,
                                         Instruction** cursor) {
  LoadFieldInstr* length = new (Z) LoadFieldInstr(
      new (Z) Value(*array), CheckArrayBoundInstr::LengthOffsetFor(array_cid),
      Type::ZoneHandle(Z, Type::SmiType()), call->token_pos());
  length->set_is_immutable(true);
  length->set_result_cid(kSmiCid);
  length->set_recognized_kind(
      LoadFieldInstr::RecognizedKindFromArrayCid(array_cid));
  *cursor = flow_graph->AppendTo(*cursor, length, NULL, FlowGraph::kValue);

  intptr_t element_size = Instance::ElementSizeFor(array_cid);
  ConstantInstr* bytes_per_element =
      flow_graph->GetConstant(Smi::Handle(Z, Smi::New(element_size)));
  BinarySmiOpInstr* len_in_bytes = new (Z)
      BinarySmiOpInstr(Token::kMUL, new (Z) Value(length),
                       new (Z) Value(bytes_per_element), call->deopt_id());
  *cursor = flow_graph->AppendTo(*cursor, len_in_bytes, call->env(),
                                 FlowGraph::kValue);

  // adjusted_length = len_in_bytes - (element_size - 1).
  Definition* adjusted_length = len_in_bytes;
  intptr_t adjustment = Instance::ElementSizeFor(view_cid) - 1;
  if (adjustment > 0) {
    ConstantInstr* length_adjustment =
        flow_graph->GetConstant(Smi::Handle(Z, Smi::New(adjustment)));
    adjusted_length = new (Z)
        BinarySmiOpInstr(Token::kSUB, new (Z) Value(len_in_bytes),
                         new (Z) Value(length_adjustment), call->deopt_id());
    *cursor = flow_graph->AppendTo(*cursor, adjusted_length, call->env(),
                                   FlowGraph::kValue);
  }

  // Check adjusted_length > 0.
  ConstantInstr* zero = flow_graph->GetConstant(Smi::Handle(Z, Smi::New(0)));
  *cursor = flow_graph->AppendTo(
      *cursor,
      new (Z) CheckArrayBoundInstr(new (Z) Value(adjusted_length),
                                   new (Z) Value(zero), call->deopt_id()),
      call->env(), FlowGraph::kEffect);
  // Check 0 <= byte_index < adjusted_length.
  *cursor = flow_graph->AppendTo(
      *cursor,
      new (Z) CheckArrayBoundInstr(new (Z) Value(adjusted_length),
                                   new (Z) Value(byte_index), call->deopt_id()),
      call->env(), FlowGraph::kEffect);

  if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    LoadUntaggedInstr* elements = new (Z) LoadUntaggedInstr(
        new (Z) Value(*array), ExternalTypedData::data_offset());
    *cursor = flow_graph->AppendTo(*cursor, elements, NULL, FlowGraph::kValue);
    *array = elements;
  }
}


static bool InlineByteArrayBaseLoad(FlowGraph* flow_graph,
                                    Instruction* call,
                                    Definition* receiver,
                                    intptr_t array_cid,
                                    intptr_t view_cid,
                                    TargetEntryInstr** entry,
                                    Definition** last) {
  ASSERT(array_cid != kIllegalCid);
  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  PrepareInlineByteArrayBaseOp(flow_graph, call, array_cid, view_cid, &array,
                               index, &cursor);

  intptr_t deopt_id = Thread::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id = (kSmiBits >= 32) ? Thread::kNoDeoptId : call->deopt_id();
  }

  *last = new (Z)
      LoadIndexedInstr(new (Z) Value(array), new (Z) Value(index), 1, view_cid,
                       kUnalignedAccess, deopt_id, call->token_pos());
  cursor = flow_graph->AppendTo(
      cursor, *last, deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);

  if (view_cid == kTypedDataFloat32ArrayCid) {
    *last = new (Z) FloatToDoubleInstr(new (Z) Value(*last), deopt_id);
    flow_graph->AppendTo(cursor, *last,
                         deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
                         FlowGraph::kValue);
  }
  return true;
}


static bool InlineByteArrayBaseStore(FlowGraph* flow_graph,
                                     const Function& target,
                                     Instruction* call,
                                     Definition* receiver,
                                     intptr_t array_cid,
                                     intptr_t view_cid,
                                     TargetEntryInstr** entry,
                                     Definition** last) {
  ASSERT(array_cid != kIllegalCid);
  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  PrepareInlineByteArrayBaseOp(flow_graph, call, array_cid, view_cid, &array,
                               index, &cursor);

  // Extract the instance call so we can use the function_name in the stored
  // value check ICData.
  InstanceCallInstr* i_call = NULL;
  if (call->IsPolymorphicInstanceCall()) {
    i_call = call->AsPolymorphicInstanceCall()->instance_call();
  } else {
    ASSERT(call->IsInstanceCall());
    i_call = call->AsInstanceCall();
  }
  ASSERT(i_call != NULL);
  Cids* value_check = NULL;
  switch (view_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      // Check that value is always smi.
      value_check = Cids::CreateMonomorphic(Z, kSmiCid);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // On 64-bit platforms assume that stored value is always a smi.
      if (kSmiBits >= 32) {
        value_check = Cids::CreateMonomorphic(Z, kSmiCid);
      }
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid: {
      // Check that value is always double.
      value_check = Cids::CreateMonomorphic(Z, kDoubleCid);
      break;
    }
    case kTypedDataInt32x4ArrayCid: {
      // Check that value is always Int32x4.
      value_check = Cids::CreateMonomorphic(Z, kInt32x4Cid);
      break;
    }
    case kTypedDataFloat32x4ArrayCid: {
      // Check that value is always Float32x4.
      value_check = Cids::CreateMonomorphic(Z, kFloat32x4Cid);
      break;
    }
    default:
      // Array cids are already checked in the caller.
      UNREACHABLE();
  }

  Definition* stored_value = call->ArgumentAt(2);
  if (value_check != NULL) {
    Instruction* check = flow_graph->CreateCheckClass(
        stored_value, *value_check, call->deopt_id(), call->token_pos());
    cursor =
        flow_graph->AppendTo(cursor, check, call->env(), FlowGraph::kEffect);
  }

  if (view_cid == kTypedDataFloat32ArrayCid) {
    stored_value = new (Z)
        DoubleToFloatInstr(new (Z) Value(stored_value), call->deopt_id());
    cursor =
        flow_graph->AppendTo(cursor, stored_value, NULL, FlowGraph::kValue);
  } else if (view_cid == kTypedDataInt32ArrayCid) {
    stored_value =
        new (Z) UnboxInt32Instr(UnboxInt32Instr::kTruncate,
                                new (Z) Value(stored_value), call->deopt_id());
    cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                  FlowGraph::kValue);
  } else if (view_cid == kTypedDataUint32ArrayCid) {
    stored_value =
        new (Z) UnboxUint32Instr(new (Z) Value(stored_value), call->deopt_id());
    ASSERT(stored_value->AsUnboxInteger()->is_truncating());
    cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                  FlowGraph::kValue);
  }

  StoreBarrierType needs_store_barrier = kNoStoreBarrier;
  *last = new (Z) StoreIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), new (Z) Value(stored_value),
      needs_store_barrier,
      1,  // Index scale
      view_cid, kUnalignedAccess, call->deopt_id(), call->token_pos());

  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kEffect);
  return true;
}


// Returns the LoadIndexedInstr.
static Definition* PrepareInlineStringIndexOp(FlowGraph* flow_graph,
                                              Instruction* call,
                                              intptr_t cid,
                                              Definition* str,
                                              Definition* index,
                                              Instruction* cursor) {
  // Load the length of the string.
  // Treat length loads as mutable (i.e. affected by side effects) to avoid
  // hoisting them since we can't hoist the preceding class-check. This
  // is because of externalization of strings that affects their class-id.
  LoadFieldInstr* length = new (Z)
      LoadFieldInstr(new (Z) Value(str), String::length_offset(),
                     Type::ZoneHandle(Z, Type::SmiType()), str->token_pos());
  length->set_result_cid(kSmiCid);
  length->set_is_immutable(!FLAG_support_externalizable_strings);
  length->set_recognized_kind(MethodRecognizer::kStringBaseLength);

  cursor = flow_graph->AppendTo(cursor, length, NULL, FlowGraph::kValue);
  // Bounds check.
  cursor = flow_graph->AppendTo(
      cursor,
      new (Z) CheckArrayBoundInstr(new (Z) Value(length), new (Z) Value(index),
                                   call->deopt_id()),
      call->env(), FlowGraph::kEffect);

  // For external strings: Load backing store.
  if (cid == kExternalOneByteStringCid) {
    str = new LoadUntaggedInstr(new Value(str),
                                ExternalOneByteString::external_data_offset());
    cursor = flow_graph->AppendTo(cursor, str, NULL, FlowGraph::kValue);
    str = new LoadUntaggedInstr(
        new Value(str), RawExternalOneByteString::ExternalData::data_offset());
    cursor = flow_graph->AppendTo(cursor, str, NULL, FlowGraph::kValue);
  } else if (cid == kExternalTwoByteStringCid) {
    str = new LoadUntaggedInstr(new Value(str),
                                ExternalTwoByteString::external_data_offset());
    cursor = flow_graph->AppendTo(cursor, str, NULL, FlowGraph::kValue);
    str = new LoadUntaggedInstr(
        new Value(str), RawExternalTwoByteString::ExternalData::data_offset());
    cursor = flow_graph->AppendTo(cursor, str, NULL, FlowGraph::kValue);
  }

  LoadIndexedInstr* load_indexed = new (Z) LoadIndexedInstr(
      new (Z) Value(str), new (Z) Value(index), Instance::ElementSizeFor(cid),
      cid, kAlignedAccess, Thread::kNoDeoptId, call->token_pos());

  cursor = flow_graph->AppendTo(cursor, load_indexed, NULL, FlowGraph::kValue);
  ASSERT(cursor == load_indexed);
  return load_indexed;
}


static bool InlineStringBaseCharAt(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   intptr_t cid,
                                   TargetEntryInstr** entry,
                                   Definition** last) {
  if ((cid != kOneByteStringCid) && (cid != kExternalOneByteStringCid)) {
    return false;
  }
  Definition* str = receiver;
  Definition* index = call->ArgumentAt(1);

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(flow_graph, call, cid, str, index, *entry);

  OneByteStringFromCharCodeInstr* char_at =
      new (Z) OneByteStringFromCharCodeInstr(new (Z) Value(*last));

  flow_graph->AppendTo(*last, char_at, NULL, FlowGraph::kValue);
  *last = char_at;

  return true;
}


static bool InlineStringCodeUnitAt(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   intptr_t cid,
                                   TargetEntryInstr** entry,
                                   Definition** last) {
  ASSERT((cid == kOneByteStringCid) || (cid == kTwoByteStringCid) ||
         (cid == kExternalOneByteStringCid) ||
         (cid == kExternalTwoByteStringCid));
  Definition* str = receiver;
  Definition* index = call->ArgumentAt(1);

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(flow_graph, call, cid, str, index, *entry);

  return true;
}


// Only used for monomorphic calls.
bool FlowGraphInliner::TryReplaceInstanceCallWithInline(
    FlowGraph* flow_graph,
    ForwardInstructionIterator* iterator,
    InstanceCallInstr* call) {
  Function& target = Function::Handle(Z);
  GrowableArray<intptr_t> class_ids;
  call->ic_data()->GetCheckAt(0, &class_ids, &target);
  const intptr_t receiver_cid = class_ids[0];

  TargetEntryInstr* entry;
  Definition* last;
  if (FlowGraphInliner::TryInlineRecognizedMethod(
          flow_graph, receiver_cid, target, call, call->ArgumentAt(0),
          call->token_pos(), *call->ic_data(), &entry, &last)) {
    // Insert receiver class check if needed.
    if (MethodRecognizer::PolymorphicTarget(target) ||
        flow_graph->InstanceCallNeedsClassCheck(call, target.kind())) {
      Instruction* check = flow_graph->CreateCheckClass(
          call->ArgumentAt(0), *Cids::Create(Z, *call->ic_data(), 0),
          call->deopt_id(), call->token_pos());
      flow_graph->InsertBefore(call, check, call->env(), FlowGraph::kEffect);
    }

    // Remove the original push arguments.
    for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
      PushArgumentInstr* push = call->PushArgumentAt(i);
      push->ReplaceUsesWith(push->value()->definition());
      push->RemoveFromGraph();
    }
    // Replace all uses of this definition with the result.
    if (call->HasUses()) {
      call->ReplaceUsesWith(last);
    }
    // Finally insert the sequence other definition in place of this one in the
    // graph.
    if (entry->next() != NULL) {
      call->previous()->LinkTo(entry->next());
    }
    entry->UnuseAllInputs();  // Entry block is not in the graph.
    if (last != NULL) {
      last->LinkTo(call);
    }
    // Remove through the iterator.
    ASSERT(iterator->Current() == call);
    iterator->RemoveCurrentFromGraph();
    call->set_previous(NULL);
    call->set_next(NULL);
    return true;
  }
  return false;
}


bool FlowGraphInliner::TryReplaceStaticCallWithInline(
    FlowGraph* flow_graph,
    ForwardInstructionIterator* iterator,
    StaticCallInstr* call) {
  TargetEntryInstr* entry;
  Definition* last;
  if (FlowGraphInliner::TryInlineRecognizedMethod(
          flow_graph, kIllegalCid, call->function(), call, NULL,
          call->token_pos(), *call->ic_data(), &entry, &last)) {
    // Remove the original push arguments.
    for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
      PushArgumentInstr* push = call->PushArgumentAt(i);
      push->ReplaceUsesWith(push->value()->definition());
      push->RemoveFromGraph();
    }
    // Replace all uses of this definition with the result.
    if (call->HasUses()) {
      call->ReplaceUsesWith(last);
    }
    // Finally insert the sequence other definition in place of this one in the
    // graph.
    if (entry->next() != NULL) {
      call->previous()->LinkTo(entry->next());
    }
    entry->UnuseAllInputs();  // Entry block is not in the graph.
    if (last != NULL) {
      last->LinkTo(call);
    }
    // Remove through the iterator.
    ASSERT(iterator->Current() == call);
    iterator->RemoveCurrentFromGraph();
    call->set_previous(NULL);
    call->set_next(NULL);
    return true;
  }
  return false;
}


static bool InlineFloat32x4Method(FlowGraph* flow_graph,
                                  Instruction* call,
                                  Definition* receiver,
                                  MethodRecognizer::Kind kind,
                                  TargetEntryInstr** entry,
                                  Definition** last) {
  if (!ShouldInlineSimd()) {
    return false;
  }

  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  switch (kind) {
    case MethodRecognizer::kFloat32x4ShuffleX:
    case MethodRecognizer::kFloat32x4ShuffleY:
    case MethodRecognizer::kFloat32x4ShuffleZ:
    case MethodRecognizer::kFloat32x4ShuffleW: {
      *last = new (Z) Simd32x4ShuffleInstr(kind, new (Z) Value(receiver),
                                           0,  // mask ignored.
                                           call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4GetSignMask: {
      *last = new (Z) Simd32x4GetSignMaskInstr(kind, new (Z) Value(receiver),
                                               call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4Equal:
    case MethodRecognizer::kFloat32x4GreaterThan:
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
    case MethodRecognizer::kFloat32x4LessThan:
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
    case MethodRecognizer::kFloat32x4NotEqual: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      *last = new (Z) Float32x4ComparisonInstr(
          kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4Min:
    case MethodRecognizer::kFloat32x4Max: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      *last = new (Z) Float32x4MinMaxInstr(
          kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4Scale: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      // Left and right values are swapped when handed to the instruction,
      // this is done so that the double value is loaded into the output
      // register and can be destroyed.
      *last = new (Z) Float32x4ScaleInstr(
          kind, new (Z) Value(right), new (Z) Value(left), call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4Sqrt:
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
    case MethodRecognizer::kFloat32x4Reciprocal: {
      Definition* left = receiver;
      *last = new (Z)
          Float32x4SqrtInstr(kind, new (Z) Value(left), call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4WithW: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      *last = new (Z) Float32x4WithInstr(
          kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4Absolute:
    case MethodRecognizer::kFloat32x4Negate: {
      Definition* left = receiver;
      *last = new (Z)
          Float32x4ZeroArgInstr(kind, new (Z) Value(left), call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat32x4Clamp: {
      Definition* left = receiver;
      Definition* lower = call->ArgumentAt(1);
      Definition* upper = call->ArgumentAt(2);
      *last =
          new (Z) Float32x4ClampInstr(new (Z) Value(left), new (Z) Value(lower),
                                      new (Z) Value(upper), call->deopt_id());
      break;
    }
    default:
      UNREACHABLE();
      return false;
  }
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


static bool CheckMask(Definition* definition, intptr_t* mask_ptr) {
  if (!definition->IsConstant()) return false;
  ConstantInstr* constant_instruction = definition->AsConstant();
  const Object& constant_mask = constant_instruction->value();
  if (!constant_mask.IsSmi()) return false;
  const intptr_t mask = Smi::Cast(constant_mask).Value();
  if ((mask < 0) || (mask > 255)) {
    return false;  // Not a valid mask.
  }
  *mask_ptr = mask;
  return true;
}


static bool InlineSimdShuffleMethod(FlowGraph* flow_graph,
                                    Instruction* call,
                                    Definition* receiver,
                                    MethodRecognizer::Kind kind,
                                    TargetEntryInstr** entry,
                                    Definition** last) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  Definition* mask_definition = call->ArgumentAt(1);
  intptr_t mask = 0;
  if (!CheckMask(mask_definition, &mask)) {
    return false;
  }
  *last = new (Z) Simd32x4ShuffleInstr(kind, new (Z) Value(call->ArgumentAt(0)),
                                       mask, call->deopt_id());
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


static bool InlineSimdShuffleMixMethod(FlowGraph* flow_graph,
                                       Instruction* call,
                                       Definition* receiver,
                                       MethodRecognizer::Kind kind,
                                       TargetEntryInstr** entry,
                                       Definition** last) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  Definition* mask_definition = call->ArgumentAt(2);
  intptr_t mask = 0;
  if (!CheckMask(mask_definition, &mask)) {
    return false;
  }
  *last = new (Z) Simd32x4ShuffleMixInstr(kind, new (Z) Value(receiver),
                                          new (Z) Value(call->ArgumentAt(1)),
                                          mask, call->deopt_id());
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


static bool InlineInt32x4Method(FlowGraph* flow_graph,
                                Instruction* call,
                                Definition* receiver,
                                MethodRecognizer::Kind kind,
                                TargetEntryInstr** entry,
                                Definition** last) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  switch (kind) {
    case MethodRecognizer::kInt32x4GetFlagX:
    case MethodRecognizer::kInt32x4GetFlagY:
    case MethodRecognizer::kInt32x4GetFlagZ:
    case MethodRecognizer::kInt32x4GetFlagW: {
      *last = new (Z)
          Int32x4GetFlagInstr(kind, new (Z) Value(receiver), call->deopt_id());
      break;
    }
    case MethodRecognizer::kInt32x4GetSignMask: {
      *last = new (Z) Simd32x4GetSignMaskInstr(kind, new (Z) Value(receiver),
                                               call->deopt_id());
      break;
    }
    case MethodRecognizer::kInt32x4Select: {
      Definition* mask = receiver;
      Definition* trueValue = call->ArgumentAt(1);
      Definition* falseValue = call->ArgumentAt(2);
      *last = new (Z)
          Int32x4SelectInstr(new (Z) Value(mask), new (Z) Value(trueValue),
                             new (Z) Value(falseValue), call->deopt_id());
      break;
    }
    case MethodRecognizer::kInt32x4WithFlagX:
    case MethodRecognizer::kInt32x4WithFlagY:
    case MethodRecognizer::kInt32x4WithFlagZ:
    case MethodRecognizer::kInt32x4WithFlagW: {
      *last = new (Z) Int32x4SetFlagInstr(kind, new (Z) Value(receiver),
                                          new (Z) Value(call->ArgumentAt(1)),
                                          call->deopt_id());
      break;
    }
    default:
      return false;
  }
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


static bool InlineFloat64x2Method(FlowGraph* flow_graph,
                                  Instruction* call,
                                  Definition* receiver,
                                  MethodRecognizer::Kind kind,
                                  TargetEntryInstr** entry,
                                  Definition** last) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  switch (kind) {
    case MethodRecognizer::kFloat64x2GetX:
    case MethodRecognizer::kFloat64x2GetY: {
      *last = new (Z) Simd64x2ShuffleInstr(kind, new (Z) Value(receiver),
                                           0,  // mask is ignored.
                                           call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat64x2Negate:
    case MethodRecognizer::kFloat64x2Abs:
    case MethodRecognizer::kFloat64x2Sqrt:
    case MethodRecognizer::kFloat64x2GetSignMask: {
      *last = new (Z) Float64x2ZeroArgInstr(kind, new (Z) Value(receiver),
                                            call->deopt_id());
      break;
    }
    case MethodRecognizer::kFloat64x2Scale:
    case MethodRecognizer::kFloat64x2WithX:
    case MethodRecognizer::kFloat64x2WithY:
    case MethodRecognizer::kFloat64x2Min:
    case MethodRecognizer::kFloat64x2Max: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      *last = new (Z) Float64x2OneArgInstr(
          kind, new (Z) Value(left), new (Z) Value(right), call->deopt_id());
      break;
    }
    default:
      UNREACHABLE();
      return false;
  }
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


static bool InlineSimdConstructor(FlowGraph* flow_graph,
                                  Instruction* call,
                                  MethodRecognizer::Kind kind,
                                  TargetEntryInstr** entry,
                                  Definition** last) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  switch (kind) {
    case MethodRecognizer::kFloat32x4Zero:
      *last = new (Z) Float32x4ZeroInstr();
      break;
    case MethodRecognizer::kFloat32x4Splat:
      *last = new (Z) Float32x4SplatInstr(new (Z) Value(call->ArgumentAt(1)),
                                          call->deopt_id());
      break;
    case MethodRecognizer::kFloat32x4Constructor:
      *last = new (Z) Float32x4ConstructorInstr(
          new (Z) Value(call->ArgumentAt(1)),
          new (Z) Value(call->ArgumentAt(2)),
          new (Z) Value(call->ArgumentAt(3)),
          new (Z) Value(call->ArgumentAt(4)), call->deopt_id());
      break;
    case MethodRecognizer::kFloat32x4FromInt32x4Bits:
      *last = new (Z) Int32x4ToFloat32x4Instr(
          new (Z) Value(call->ArgumentAt(1)), call->deopt_id());
      break;
    case MethodRecognizer::kFloat32x4FromFloat64x2:
      *last = new (Z) Float64x2ToFloat32x4Instr(
          new (Z) Value(call->ArgumentAt(1)), call->deopt_id());
      break;
    case MethodRecognizer::kFloat64x2Zero:
      *last = new (Z) Float64x2ZeroInstr();
      break;
    case MethodRecognizer::kFloat64x2Splat:
      *last = new (Z) Float64x2SplatInstr(new (Z) Value(call->ArgumentAt(1)),
                                          call->deopt_id());
      break;
    case MethodRecognizer::kFloat64x2Constructor:
      *last = new (Z) Float64x2ConstructorInstr(
          new (Z) Value(call->ArgumentAt(1)),
          new (Z) Value(call->ArgumentAt(2)), call->deopt_id());
      break;
    case MethodRecognizer::kFloat64x2FromFloat32x4:
      *last = new (Z) Float32x4ToFloat64x2Instr(
          new (Z) Value(call->ArgumentAt(1)), call->deopt_id());
      break;
    case MethodRecognizer::kInt32x4BoolConstructor:
      *last = new (Z) Int32x4BoolConstructorInstr(
          new (Z) Value(call->ArgumentAt(1)),
          new (Z) Value(call->ArgumentAt(2)),
          new (Z) Value(call->ArgumentAt(3)),
          new (Z) Value(call->ArgumentAt(4)), call->deopt_id());
      break;
    case MethodRecognizer::kInt32x4Constructor:
      *last = new (Z) Int32x4ConstructorInstr(
          new (Z) Value(call->ArgumentAt(1)),
          new (Z) Value(call->ArgumentAt(2)),
          new (Z) Value(call->ArgumentAt(3)),
          new (Z) Value(call->ArgumentAt(4)), call->deopt_id());
      break;
    case MethodRecognizer::kInt32x4FromFloat32x4Bits:
      *last = new (Z) Float32x4ToInt32x4Instr(
          new (Z) Value(call->ArgumentAt(1)), call->deopt_id());
      break;
    default:
      UNREACHABLE();
      return false;
  }
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


static bool InlineMathCFunction(FlowGraph* flow_graph,
                                Instruction* call,
                                MethodRecognizer::Kind kind,
                                TargetEntryInstr** entry,
                                Definition** last) {
  if (!CanUnboxDouble()) {
    return false;
  }
  *entry = new (Z)
      TargetEntryInstr(flow_graph->allocate_block_id(),
                       call->GetBlock()->try_index(), Thread::kNoDeoptId);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  switch (kind) {
    case MethodRecognizer::kMathSqrt: {
      *last = new (Z)
          MathUnaryInstr(MathUnaryInstr::kSqrt,
                         new (Z) Value(call->ArgumentAt(0)), call->deopt_id());
      break;
    }
    default: {
      ZoneGrowableArray<Value*>* args =
          new (Z) ZoneGrowableArray<Value*>(call->ArgumentCount());
      for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
        args->Add(new (Z) Value(call->ArgumentAt(i)));
      }
      *last = new (Z) InvokeMathCFunctionInstr(args, call->deopt_id(), kind,
                                               call->token_pos());
      break;
    }
  }
  flow_graph->AppendTo(
      cursor, *last,
      call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);
  return true;
}


bool FlowGraphInliner::TryInlineRecognizedMethod(FlowGraph* flow_graph,
                                                 intptr_t receiver_cid,
                                                 const Function& target,
                                                 Definition* call,
                                                 Definition* receiver,
                                                 TokenPosition token_pos,
                                                 const ICData& ic_data,
                                                 TargetEntryInstr** entry,
                                                 Definition** last) {
  MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(target);
  switch (kind) {
    // Recognized [] operators.
    case MethodRecognizer::kImmutableArrayGetIndexed:
    case MethodRecognizer::kObjectArrayGetIndexed:
    case MethodRecognizer::kGrowableArrayGetIndexed:
    case MethodRecognizer::kInt8ArrayGetIndexed:
    case MethodRecognizer::kUint8ArrayGetIndexed:
    case MethodRecognizer::kUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kInt16ArrayGetIndexed:
    case MethodRecognizer::kUint16ArrayGetIndexed:
      return InlineGetIndexed(flow_graph, kind, call, receiver, entry, last);
    case MethodRecognizer::kFloat32ArrayGetIndexed:
    case MethodRecognizer::kFloat64ArrayGetIndexed:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, kind, call, receiver, entry, last);
    case MethodRecognizer::kFloat32x4ArrayGetIndexed:
    case MethodRecognizer::kFloat64x2ArrayGetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, kind, call, receiver, entry, last);
    case MethodRecognizer::kInt32ArrayGetIndexed:
    case MethodRecognizer::kUint32ArrayGetIndexed:
      if (!CanUnboxInt32()) return false;
      return InlineGetIndexed(flow_graph, kind, call, receiver, entry, last);

    case MethodRecognizer::kInt64ArrayGetIndexed:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, kind, call, receiver, entry, last);
    // Recognized []= operators.
    case MethodRecognizer::kObjectArraySetIndexed:
    case MethodRecognizer::kGrowableArraySetIndexed:
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, /* value_check = */ NULL, entry, last);
    case MethodRecognizer::kInt8ArraySetIndexed:
    case MethodRecognizer::kUint8ArraySetIndexed:
    case MethodRecognizer::kUint8ClampedArraySetIndexed:
    case MethodRecognizer::kExternalUint8ArraySetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArraySetIndexed:
    case MethodRecognizer::kInt16ArraySetIndexed:
    case MethodRecognizer::kUint16ArraySetIndexed: {
      // Optimistically assume Smi.
      if (ic_data.HasDeoptReason(ICData::kDeoptCheckSmi)) {
        // Optimistic assumption failed at least once.
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kSmiCid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, value_check, entry, last);
    }
    case MethodRecognizer::kInt32ArraySetIndexed:
    case MethodRecognizer::kUint32ArraySetIndexed: {
      // Value check not needed for Int32 and Uint32 arrays because they
      // implicitly contain unboxing instructions which check for right type.
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, /* value_check = */ NULL, entry, last);
    }
    case MethodRecognizer::kInt64ArraySetIndexed:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, /* value_check = */ NULL, entry, last);
    case MethodRecognizer::kFloat32ArraySetIndexed:
    case MethodRecognizer::kFloat64ArraySetIndexed: {
      if (!CanUnboxDouble()) {
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kDoubleCid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, value_check, entry, last);
    }
    case MethodRecognizer::kFloat32x4ArraySetIndexed: {
      if (!ShouldInlineSimd()) {
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kFloat32x4Cid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, value_check, entry, last);
    }
    case MethodRecognizer::kFloat64x2ArraySetIndexed: {
      if (!ShouldInlineSimd()) {
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kFloat64x2Cid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver,
                              token_pos, value_check, entry, last);
    }
    case MethodRecognizer::kByteArrayBaseGetInt8:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt8ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint8:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint8ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt16:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt16ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint16:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint16ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt32ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint32ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataFloat32ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataFloat64ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataFloat32x4ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt32x4ArrayCid, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt8:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt8ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint8:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint8ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt16:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt16ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint16:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint16ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt32:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt32ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint32:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint32ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataFloat32ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataFloat64ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataFloat32x4ArrayCid,
                                      entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt32x4ArrayCid,
                                      entry, last);
    case MethodRecognizer::kOneByteStringCodeUnitAt:
    case MethodRecognizer::kTwoByteStringCodeUnitAt:
    case MethodRecognizer::kExternalOneByteStringCodeUnitAt:
    case MethodRecognizer::kExternalTwoByteStringCodeUnitAt:
      return InlineStringCodeUnitAt(flow_graph, call, receiver, receiver_cid,
                                    entry, last);
    case MethodRecognizer::kStringBaseCharAt:
      return InlineStringBaseCharAt(flow_graph, call, receiver, receiver_cid,
                                    entry, last);
    case MethodRecognizer::kDoubleAdd:
      return InlineDoubleOp(flow_graph, Token::kADD, call, receiver, entry,
                            last);
    case MethodRecognizer::kDoubleSub:
      return InlineDoubleOp(flow_graph, Token::kSUB, call, receiver, entry,
                            last);
    case MethodRecognizer::kDoubleMul:
      return InlineDoubleOp(flow_graph, Token::kMUL, call, receiver, entry,
                            last);
    case MethodRecognizer::kDoubleDiv:
      return InlineDoubleOp(flow_graph, Token::kDIV, call, receiver, entry,
                            last);
    case MethodRecognizer::kDouble_getIsNaN:
    case MethodRecognizer::kDouble_getIsInfinite:
      return InlineDoubleTestOp(flow_graph, call, receiver, kind, entry, last);
    case MethodRecognizer::kGrowableArraySetData:
      ASSERT(receiver_cid == kGrowableObjectArrayCid);
      ASSERT(ic_data.NumberOfChecksIs(1));
      return InlineGrowableArraySetter(
          flow_graph, GrowableObjectArray::data_offset(), kEmitStoreBarrier,
          call, receiver, entry, last);
    case MethodRecognizer::kGrowableArraySetLength:
      ASSERT(receiver_cid == kGrowableObjectArrayCid);
      ASSERT(ic_data.NumberOfChecksIs(1));
      return InlineGrowableArraySetter(
          flow_graph, GrowableObjectArray::length_offset(), kNoStoreBarrier,
          call, receiver, entry, last);
    case MethodRecognizer::kSmi_bitAndFromSmi:
      return InlineSmiBitAndFromSmi(flow_graph, call, receiver, entry, last);

    case MethodRecognizer::kFloat32x4ShuffleX:
    case MethodRecognizer::kFloat32x4ShuffleY:
    case MethodRecognizer::kFloat32x4ShuffleZ:
    case MethodRecognizer::kFloat32x4ShuffleW:
    case MethodRecognizer::kFloat32x4GetSignMask:
    case MethodRecognizer::kFloat32x4Equal:
    case MethodRecognizer::kFloat32x4GreaterThan:
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
    case MethodRecognizer::kFloat32x4LessThan:
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
    case MethodRecognizer::kFloat32x4NotEqual:
    case MethodRecognizer::kFloat32x4Min:
    case MethodRecognizer::kFloat32x4Max:
    case MethodRecognizer::kFloat32x4Scale:
    case MethodRecognizer::kFloat32x4Sqrt:
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
    case MethodRecognizer::kFloat32x4Reciprocal:
    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4WithW:
    case MethodRecognizer::kFloat32x4Absolute:
    case MethodRecognizer::kFloat32x4Negate:
    case MethodRecognizer::kFloat32x4Clamp:
      return InlineFloat32x4Method(flow_graph, call, receiver, kind, entry,
                                   last);

    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
      return InlineSimdShuffleMixMethod(flow_graph, call, receiver, kind, entry,
                                        last);

    case MethodRecognizer::kFloat32x4Shuffle:
    case MethodRecognizer::kInt32x4Shuffle:
      return InlineSimdShuffleMethod(flow_graph, call, receiver, kind, entry,
                                     last);

    case MethodRecognizer::kInt32x4GetFlagX:
    case MethodRecognizer::kInt32x4GetFlagY:
    case MethodRecognizer::kInt32x4GetFlagZ:
    case MethodRecognizer::kInt32x4GetFlagW:
    case MethodRecognizer::kInt32x4GetSignMask:
    case MethodRecognizer::kInt32x4Select:
    case MethodRecognizer::kInt32x4WithFlagX:
    case MethodRecognizer::kInt32x4WithFlagY:
    case MethodRecognizer::kInt32x4WithFlagZ:
    case MethodRecognizer::kInt32x4WithFlagW:
      return InlineInt32x4Method(flow_graph, call, receiver, kind, entry, last);

    case MethodRecognizer::kFloat64x2GetX:
    case MethodRecognizer::kFloat64x2GetY:
    case MethodRecognizer::kFloat64x2Negate:
    case MethodRecognizer::kFloat64x2Abs:
    case MethodRecognizer::kFloat64x2Sqrt:
    case MethodRecognizer::kFloat64x2GetSignMask:
    case MethodRecognizer::kFloat64x2Scale:
    case MethodRecognizer::kFloat64x2WithX:
    case MethodRecognizer::kFloat64x2WithY:
    case MethodRecognizer::kFloat64x2Min:
    case MethodRecognizer::kFloat64x2Max:
      return InlineFloat64x2Method(flow_graph, call, receiver, kind, entry,
                                   last);

    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat32x4Splat:
    case MethodRecognizer::kFloat32x4Constructor:
    case MethodRecognizer::kFloat32x4FromFloat64x2:
    case MethodRecognizer::kFloat64x2Constructor:
    case MethodRecognizer::kFloat64x2Zero:
    case MethodRecognizer::kFloat64x2Splat:
    case MethodRecognizer::kFloat64x2FromFloat32x4:
    case MethodRecognizer::kInt32x4BoolConstructor:
    case MethodRecognizer::kInt32x4Constructor:
    case MethodRecognizer::kInt32x4FromFloat32x4Bits:
      return InlineSimdConstructor(flow_graph, call, kind, entry, last);

    case MethodRecognizer::kMathSqrt:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathAtan2:
      return InlineMathCFunction(flow_graph, call, kind, entry, last);

    case MethodRecognizer::kObjectConstructor: {
      *entry = new (Z)
          TargetEntryInstr(flow_graph->allocate_block_id(),
                           call->GetBlock()->try_index(), Thread::kNoDeoptId);
      (*entry)->InheritDeoptTarget(Z, call);
      ASSERT(!call->HasUses());
      *last = NULL;  // Empty body.
      return true;
    }

    case MethodRecognizer::kObjectArrayAllocate: {
      Value* num_elements = new (Z) Value(call->ArgumentAt(1));
      if (num_elements->BindsToConstant() &&
          num_elements->BoundConstant().IsSmi()) {
        intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
        if (length >= 0 && length <= Array::kMaxElements) {
          Value* type = new (Z) Value(call->ArgumentAt(0));
          *entry = new (Z) TargetEntryInstr(flow_graph->allocate_block_id(),
                                            call->GetBlock()->try_index(),
                                            Thread::kNoDeoptId);
          (*entry)->InheritDeoptTarget(Z, call);
          *last = new (Z) CreateArrayInstr(call->token_pos(), type,
                                           num_elements, call->deopt_id());
          flow_graph->AppendTo(
              *entry, *last,
              call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
              FlowGraph::kValue);
          return true;
        }
      }
      return false;
    }

    case MethodRecognizer::kObjectRuntimeType: {
      Type& type = Type::ZoneHandle(Z);
      if (RawObject::IsStringClassId(receiver_cid)) {
        type = Type::StringType();
      } else if (receiver_cid == kDoubleCid) {
        type = Type::Double();
      } else if (RawObject::IsIntegerClassId(receiver_cid)) {
        type = Type::IntType();
      } else if (receiver_cid != kClosureCid) {
        const Class& cls = Class::Handle(
            Z, flow_graph->isolate()->class_table()->At(receiver_cid));
        if (!cls.IsGeneric()) {
          type = cls.CanonicalType();
        }
      }

      if (!type.IsNull()) {
        *entry = new (Z)
            TargetEntryInstr(flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), Thread::kNoDeoptId);
        (*entry)->InheritDeoptTarget(Z, call);
        *last = new (Z) ConstantInstr(type);
        flow_graph->AppendTo(
            *entry, *last,
            call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
            FlowGraph::kValue);
        return true;
      }
      return false;
    }

    case MethodRecognizer::kOneByteStringSetAt: {
      // This is an internal method, no need to check argument types nor
      // range.
      *entry = new (Z)
          TargetEntryInstr(flow_graph->allocate_block_id(),
                           call->GetBlock()->try_index(), Thread::kNoDeoptId);
      (*entry)->InheritDeoptTarget(Z, call);
      Definition* str = call->ArgumentAt(0);
      Definition* index = call->ArgumentAt(1);
      Definition* value = call->ArgumentAt(2);
      *last =
          new (Z) StoreIndexedInstr(new (Z) Value(str), new (Z) Value(index),
                                    new (Z) Value(value), kNoStoreBarrier,
                                    1,  // Index scale
                                    kOneByteStringCid, kAlignedAccess,
                                    call->deopt_id(), call->token_pos());
      flow_graph->AppendTo(
          *entry, *last,
          call->deopt_id() != Thread::kNoDeoptId ? call->env() : NULL,
          FlowGraph::kEffect);
      return true;
    }

    default:
      return false;
  }
}


}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
