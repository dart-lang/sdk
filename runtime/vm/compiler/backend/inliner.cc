// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/inliner.h"

#include "vm/compiler/aot/aot_call_specializer.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/block_scheduler.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/flow_graph_checker.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/flags.h"
#include "vm/kernel.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"

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
            160,
            "Do not inline callees larger than threshold");
DEFINE_FLAG(int,
            inlining_small_leaf_size_threshold,
            50,
            "Do not inline leaf callees larger than threshold");
DEFINE_FLAG(int,
            inlining_caller_size_threshold,
            50000,
            "Stop inlining once caller reaches the threshold.");
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

DECLARE_FLAG(int, max_deoptimization_counter_threshold);
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);

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

// Test and obtain Smi value.
static bool IsSmiValue(Value* val, intptr_t* int_val) {
  if (val->BindsToConstant() && val->BoundConstant().IsSmi()) {
    *int_val = Smi::Cast(val->BoundConstant()).Value();
    return true;
  }
  return false;
}

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

// Helper to get result type from call (or nullptr otherwise).
static CompileType* ResultType(Definition* call) {
  if (auto static_call = call->AsStaticCall()) {
    return static_call->result_type();
  } else if (auto instance_call = call->AsInstanceCall()) {
    return instance_call->result_type();
  }
  return nullptr;
}

// Pair of an argument name and its value.
struct NamedArgument {
  String* name;
  Value* value;
  NamedArgument(String* name, Value* value) : name(name), value(value) {}
};

// Ensures we only inline callee graphs which are safe.  There are certain
// instructions which cannot be inlined and we ensure here that we don't do
// that.
class CalleeGraphValidator : public AllStatic {
 public:
  static void Validate(FlowGraph* callee_graph) {
#ifdef DEBUG
    for (BlockIterator block_it = callee_graph->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      BlockEntryInstr* entry = block_it.Current();

      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* current = it.Current();
        if (current->IsBranch()) {
          current = current->AsBranch()->comparison();
        }
        // The following instructions are not safe to inline, since they make
        // assumptions about the frame layout.
        ASSERT(!current->IsTailCall());
        ASSERT(!current->IsLoadIndexedUnsafe());
        ASSERT(!current->IsStoreIndexedUnsafe());
      }
    }
#endif  // DEBUG
  }
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
      // Skip any blocks from the prologue to make them not count towards the
      // inlining instruction budget.
      const intptr_t block_id = block_it.Current()->block_id();
      if (graph.prologue_info().Contains(block_id)) {
        continue;
      }

      for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
           it.Advance()) {
        Instruction* current = it.Current();
        // Don't count instructions that won't generate any code.
        if (current->IsRedefinition()) {
          continue;
        }
        // UnboxedConstant is often folded into the indexing
        // instructions (similar to Constant instructions which
        // belong to initial definitions and not counted here).
        if (current->IsUnboxedConstant()) {
          continue;
        }
        ++instruction_count_;
        // Count inputs of certain instructions as if separate PushArgument
        // instructions are used for inputs. This is done in order to
        // preserve inlining behavior and avoid code size growth after
        // PushArgument instructions are eliminated.
        if (current->IsAllocateObject()) {
          instruction_count_ += current->InputCount();
        } else if (current->ArgumentCount() > 0) {
          ASSERT(!current->HasPushArguments());
          instruction_count_ += current->ArgumentCount();
        }
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
              (call->token_kind() != Token::kEQ)) {
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
  explicit CallSites(intptr_t threshold)
      : inlining_depth_threshold_(threshold),
        static_calls_(),
        closure_calls_(),
        instance_calls_() {}

  struct InstanceCallInfo {
    PolymorphicInstanceCallInstr* call;
    double ratio;
    const FlowGraph* caller_graph;
    intptr_t nesting_depth;
    InstanceCallInfo(PolymorphicInstanceCallInstr* call_arg,
                     FlowGraph* flow_graph,
                     intptr_t depth)
        : call(call_arg),
          ratio(0.0),
          caller_graph(flow_graph),
          nesting_depth(depth) {}
    const Function& caller() const { return caller_graph->function(); }
  };

  struct StaticCallInfo {
    StaticCallInstr* call;
    double ratio;
    FlowGraph* caller_graph;
    intptr_t nesting_depth;
    StaticCallInfo(StaticCallInstr* value,
                   FlowGraph* flow_graph,
                   intptr_t depth)
        : call(value),
          ratio(0.0),
          caller_graph(flow_graph),
          nesting_depth(depth) {}
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

  // Heuristic that maps the loop nesting depth to a static estimate of number
  // of times code at that depth is executed (code at each higher nesting
  // depth is assumed to execute 10x more often up to depth 3).
  static intptr_t AotCallCountApproximation(intptr_t nesting_depth) {
    switch (nesting_depth) {
      case 0:
        // The value 1 makes most sense, but it may give a high ratio to call
        // sites outside loops. Therefore, such call sites are subject to
        // subsequent stricter heuristic to limit code size increase.
        return 1;
      case 1:
        return 10;
      case 2:
        return 10 * 10;
      default:
        return 10 * 10 * 10;
    }
  }

  // Computes the ratio for each call site in a method, defined as the
  // number of times a call site is executed over the maximum number of
  // times any call site is executed in the method. JIT uses actual call
  // counts whereas AOT uses a static estimate based on nesting depth.
  void ComputeCallSiteRatio(intptr_t static_call_start_ix,
                            intptr_t instance_call_start_ix) {
    const intptr_t num_static_calls =
        static_calls_.length() - static_call_start_ix;
    const intptr_t num_instance_calls =
        instance_calls_.length() - instance_call_start_ix;

    intptr_t max_count = 0;
    GrowableArray<intptr_t> instance_call_counts(num_instance_calls);
    for (intptr_t i = 0; i < num_instance_calls; ++i) {
      const InstanceCallInfo& info =
          instance_calls_[i + instance_call_start_ix];
      intptr_t aggregate_count =
          CompilerState::Current().is_aot()
              ? AotCallCountApproximation(info.nesting_depth)
              : info.call->CallCount();
      instance_call_counts.Add(aggregate_count);
      if (aggregate_count > max_count) max_count = aggregate_count;
    }

    GrowableArray<intptr_t> static_call_counts(num_static_calls);
    for (intptr_t i = 0; i < num_static_calls; ++i) {
      const StaticCallInfo& info = static_calls_[i + static_call_start_ix];
      intptr_t aggregate_count =
          CompilerState::Current().is_aot()
              ? AotCallCountApproximation(info.nesting_depth)
              : info.call->CallCount();
      static_call_counts.Add(aggregate_count);
      if (aggregate_count > max_count) max_count = aggregate_count;
    }

    // Note that max_count can be 0 if none of the calls was executed.
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
          target = instance_call->targets().FirstTarget().raw();
          call = instance_call;
        } else if (current->IsStaticCall()) {
          StaticCallInstr* static_call = current->AsStaticCall();
          target = static_call->function().raw();
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

    // At the maximum inlining depth, only profitable methods
    // are further considered for inlining.
    const bool inline_only_profitable_methods =
        (depth >= inlining_depth_threshold_);

    // In AOT, compute loop hierarchy.
    if (CompilerState::Current().is_aot()) {
      graph->GetLoopHierarchy();
    }

    const intptr_t instance_call_start_ix = instance_calls_.length();
    const intptr_t static_call_start_ix = static_calls_.length();
    for (BlockIterator block_it = graph->postorder_iterator(); !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* entry = block_it.Current();
      const intptr_t depth = entry->NestingDepth();
      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* current = it.Current();
        if (current->IsPolymorphicInstanceCall()) {
          PolymorphicInstanceCallInstr* instance_call =
              current->AsPolymorphicInstanceCall();
          if (!inline_only_profitable_methods ||
              instance_call->IsSureToCallSingleRecognizedTarget() ||
              instance_call->HasOnlyDispatcherOrImplicitAccessorTargets()) {
            // Consider instance call for further inlining. Note that it will
            // still be subject to all the inlining heuristics.
            instance_calls_.Add(InstanceCallInfo(instance_call, graph, depth));
          } else {
            // No longer consider the instance call because inlining is too
            // deep and the method is not deemed profitable by other criteria.
            if (FLAG_print_inlining_tree) {
              const Function* caller = &graph->function();
              const Function* target = &instance_call->targets().FirstTarget();
              inlined_info->Add(InlinedInfo(caller, target, depth + 1,
                                            instance_call, "Too deep"));
            }
          }
        } else if (current->IsStaticCall()) {
          StaticCallInstr* static_call = current->AsStaticCall();
          const Function& function = static_call->function();
          if (!inline_only_profitable_methods || function.IsRecognized() ||
              function.IsDispatcherOrImplicitAccessor() ||
              (function.is_const() && function.IsGenerativeConstructor())) {
            // Consider static call for further inlining. Note that it will
            // still be subject to all the inlining heuristics.
            static_calls_.Add(StaticCallInfo(static_call, graph, depth));
          } else {
            // No longer consider the static call because inlining is too
            // deep and the method is not deemed profitable by other criteria.
            if (FLAG_print_inlining_tree) {
              const Function* caller = &graph->function();
              const Function* target = &static_call->function();
              inlined_info->Add(InlinedInfo(caller, target, depth + 1,
                                            static_call, "Too deep"));
            }
          }
        } else if (current->IsClosureCall()) {
          if (!inline_only_profitable_methods) {
            // Consider closure for further inlining. Note that it will
            // still be subject to all the inlining heuristics.
            ClosureCallInstr* closure_call = current->AsClosureCall();
            closure_calls_.Add(ClosureCallInfo(closure_call, graph));
          } else {
            // No longer consider the closure because inlining is too deep.
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

// Determines if inlining this graph yields a small leaf node.
static bool IsSmallLeaf(FlowGraph* graph) {
  intptr_t instruction_count = 0;
  for (BlockIterator block_it = graph->postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* entry = block_it.Current();
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      ++instruction_count;
      if (current->IsInstanceCall() || current->IsPolymorphicInstanceCall() ||
          current->IsClosureCall()) {
        return false;
      } else if (current->IsStaticCall()) {
        const Function& function = current->AsStaticCall()->function();
        const intptr_t inl_size = function.optimized_instruction_count();
        const bool always_inline =
            FlowGraphInliner::FunctionHasPreferInlinePragma(function);
        // Accept a static call is always inlined in some way and add the
        // cached size to the total instruction count. A reasonable guess
        // is made if the count has not been collected yet (listed methods
        // are never very large).
        if (!always_inline && !function.IsRecognized()) {
          return false;
        }
        if (!always_inline) {
          static constexpr intptr_t kAvgListedMethodSize = 20;
          instruction_count +=
              (inl_size == 0 ? kAvgListedMethodSize : inl_size);
        }
      }
    }
  }
  return instruction_count <= FLAG_inlining_small_leaf_size_threshold;
}

struct InlinedCallData {
  InlinedCallData(Definition* call,
                  const Array& arguments_descriptor,
                  intptr_t first_arg_index,  // 1 if type args are passed.
                  GrowableArray<Value*>* arguments,
                  const Function& caller)
      : call(call),
        arguments_descriptor(arguments_descriptor),
        first_arg_index(first_arg_index),
        arguments(arguments),
        callee_graph(NULL),
        parameter_stubs(NULL),
        exit_collector(NULL),
        caller(caller) {}

  Definition* call;
  const Array& arguments_descriptor;
  const intptr_t first_arg_index;
  GrowableArray<Value*>* arguments;
  FlowGraph* callee_graph;
  ZoneGrowableArray<Definition*>* parameter_stubs;
  InlineExitCollector* exit_collector;
  const Function& caller;
};

class CallSiteInliner;

class PolymorphicInliner : public ValueObject {
 public:
  PolymorphicInliner(CallSiteInliner* owner,
                     PolymorphicInstanceCallInstr* call,
                     const Function& caller_function);

  bool Inline();

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
};

static void ReplaceParameterStubs(Zone* zone,
                                  FlowGraph* caller_graph,
                                  InlinedCallData* call_data,
                                  const TargetInfo* target_info) {
  const bool is_polymorphic = call_data->call->IsPolymorphicInstanceCall();
  ASSERT(is_polymorphic == (target_info != NULL));
  FlowGraph* callee_graph = call_data->callee_graph;
  auto callee_entry = callee_graph->graph_entry()->normal_entry();

  // Replace each stub with the actual argument or the caller's constant.
  // Nulls denote optional parameters for which no actual was given.
  const intptr_t first_arg_index = call_data->first_arg_index;
  // When first_arg_index > 0, the stub and actual argument processed in the
  // first loop iteration represent a passed-in type argument vector.
  GrowableArray<Value*>* arguments = call_data->arguments;
  intptr_t first_arg_stub_index = 0;
  if (arguments->length() != call_data->parameter_stubs->length()) {
    ASSERT(arguments->length() == call_data->parameter_stubs->length() - 1);
    ASSERT(first_arg_index == 0);
    // The first parameter stub accepts an optional type argument vector, but
    // none was provided in arguments.
    first_arg_stub_index = 1;
  }
  for (intptr_t i = 0; i < arguments->length(); ++i) {
    Value* actual = (*arguments)[i];
    Definition* defn = NULL;
    if (is_polymorphic && (i == first_arg_index)) {
      // Replace the receiver argument with a redefinition to prevent code from
      // the inlined body from being hoisted above the inlined entry.
      RedefinitionInstr* redefinition =
          new (zone) RedefinitionInstr(actual->Copy(zone));
      redefinition->set_ssa_temp_index(caller_graph->alloc_ssa_temp_index());
      if (FlowGraph::NeedsPairLocation(redefinition->representation())) {
        caller_graph->alloc_ssa_temp_index();
      }
      if (target_info->IsSingleCid()) {
        redefinition->UpdateType(CompileType::FromCid(target_info->cid_start));
      }
      redefinition->InsertAfter(callee_entry);
      defn = redefinition;
      // Since the redefinition does not dominate the callee entry, replace
      // uses of the receiver argument in this entry with the redefined value.
      callee_entry->ReplaceInEnvironment(
          call_data->parameter_stubs->At(first_arg_stub_index + i),
          actual->definition());
    } else if (actual != NULL) {
      defn = actual->definition();
    }
    if (defn != NULL) {
      call_data->parameter_stubs->At(first_arg_stub_index + i)
          ->ReplaceUsesWith(defn);
    }
  }

  // Replace remaining constants with uses by constants in the caller's
  // initial definitions.
  auto defns = callee_graph->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < defns->length(); ++i) {
    ConstantInstr* constant = (*defns)[i]->AsConstant();
    if (constant != NULL && constant->HasUses()) {
      constant->ReplaceUsesWith(caller_graph->GetConstant(constant->value()));
    }
  }

  defns = callee_graph->graph_entry()->normal_entry()->initial_definitions();
  for (intptr_t i = 0; i < defns->length(); ++i) {
    ConstantInstr* constant = (*defns)[i]->AsConstant();
    if (constant != NULL && constant->HasUses()) {
      constant->ReplaceUsesWith(caller_graph->GetConstant(constant->value()));
    }

    SpecialParameterInstr* param = (*defns)[i]->AsSpecialParameter();
    if (param != NULL && param->HasUses()) {
      switch (param->kind()) {
        case SpecialParameterInstr::kContext: {
          ASSERT(!is_polymorphic);
          // We do not support polymorphic inlining of closure calls.
          ASSERT(call_data->call->IsClosureCall());
          LoadFieldInstr* context_load = new (zone) LoadFieldInstr(
              new Value((*arguments)[first_arg_index]->definition()),
              Slot::Closure_context(), call_data->call->source());
          context_load->set_ssa_temp_index(
              caller_graph->alloc_ssa_temp_index());
          if (FlowGraph::NeedsPairLocation(context_load->representation())) {
            caller_graph->alloc_ssa_temp_index();
          }
          context_load->InsertBefore(callee_entry->next());
          param->ReplaceUsesWith(context_load);
          break;
        }
        case SpecialParameterInstr::kTypeArgs: {
          Definition* type_args;
          if (first_arg_index > 0) {
            type_args = (*arguments)[0]->definition();
          } else {
            type_args = caller_graph->constant_null();
          }
          param->ReplaceUsesWith(type_args);
          break;
        }
        case SpecialParameterInstr::kArgDescriptor: {
          param->ReplaceUsesWith(
              caller_graph->GetConstant(call_data->arguments_descriptor));
          break;
        }
        default: {
          UNREACHABLE();
          break;
        }
      }
    }
  }
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

  int inlining_depth() { return inlining_depth_; }

  struct InliningDecision {
    InliningDecision(bool b, const char* r) : value(b), reason(r) {}
    bool value;
    const char* reason;
    static InliningDecision Yes(const char* reason) {
      return InliningDecision(true, reason);
    }
    static InliningDecision No(const char* reason) {
      return InliningDecision(false, reason);
    }
  };

  // Inlining heuristics based on Cooper et al. 2008.
  InliningDecision ShouldWeInline(const Function& callee,
                                  intptr_t instr_count,
                                  intptr_t call_site_count) {
    // Pragma or size heuristics.
    if (inliner_->AlwaysInline(callee)) {
      return InliningDecision::Yes("AlwaysInline");
    } else if (inlined_size_ > FLAG_inlining_caller_size_threshold) {
      // Prevent caller methods becoming humongous and thus slow to compile.
      return InliningDecision::No("--inlining-caller-size-threshold");
    } else if (instr_count > FLAG_inlining_callee_size_threshold) {
      // Prevent inlining of callee methods that exceed certain size.
      return InliningDecision::No("--inlining-callee-size-threshold");
    }
    // Inlining depth.
    const int callee_inlining_depth = callee.inlining_depth();
    if (callee_inlining_depth > 0 &&
        ((callee_inlining_depth + inlining_depth_) >
         FLAG_inlining_depth_threshold)) {
      return InliningDecision::No("--inlining-depth-threshold");
    }
    // Situation instr_count == 0 denotes no counts have been computed yet.
    // In that case, we say ok to the early heuristic and come back with the
    // late heuristic.
    if (instr_count == 0) {
      return InliningDecision::Yes("need to count first");
    } else if (instr_count <= FLAG_inlining_size_threshold) {
      return InliningDecision::Yes("--inlining-size-threshold");
    } else if (call_site_count <= FLAG_inlining_callee_call_sites_threshold) {
      return InliningDecision::Yes("--inlining-callee-call-sites-threshold");
    }
    return InliningDecision::No("default");
  }

  void InlineCalls() {
    // If inlining depth is less than one abort.
    if (inlining_depth_threshold_ < 1) return;
    if (caller_graph_->function().deoptimization_counter() >=
        FLAG_deoptimization_counter_inlining_threshold) {
      return;
    }
    // Create two call site collections to swap between.
    CallSites sites1(inlining_depth_threshold_);
    CallSites sites2(inlining_depth_threshold_);
    CallSites* call_sites_temp = NULL;
    collected_call_sites_ = &sites1;
    inlining_call_sites_ = &sites2;
    // Collect initial call sites.
    collected_call_sites_->FindCallSites(caller_graph_, inlining_depth_,
                                         &inlined_info_);
    while (collected_call_sites_->HasCalls()) {
      TRACE_INLINING(
          THR_Print("  Depth %" Pd " ----------\n", inlining_depth_));
      if (FLAG_print_inlining_tree) {
        THR_Print("**Depth % " Pd " calls to inline %" Pd " (threshold % " Pd
                  ")\n",
                  inlining_depth_, collected_call_sites_->NumCalls(),
                  static_cast<intptr_t>(FLAG_max_inlined_per_depth));
      }
      if (collected_call_sites_->NumCalls() > FLAG_max_inlined_per_depth) {
        break;
      }
      // Swap collected and inlining arrays and clear the new collecting array.
      call_sites_temp = collected_call_sites_;
      collected_call_sites_ = inlining_call_sites_;
      inlining_call_sites_ = call_sites_temp;
      collected_call_sites_->Clear();
      // Inline call sites at the current depth.
      bool inlined_instance = InlineInstanceCalls();
      bool inlined_statics = InlineStaticCalls();
      bool inlined_closures = InlineClosureCalls();
      if (inlined_instance || inlined_statics || inlined_closures) {
        // Increment the inlining depths. Checked before subsequent inlining.
        ++inlining_depth_;
        if (inlined_recursive_call_) {
          ++inlining_recursion_depth_;
          inlined_recursive_call_ = false;
        }
        thread()->CheckForSafepoint();
      }
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
      ParameterInstr* param = new (Z)
          ParameterInstr(i, -1, graph->graph_entry(), kNoRepresentation);
      param->UpdateType(*argument->Type());
      return param;
    }
  }

  bool TryInlining(const Function& function,
                   const Array& argument_names,
                   InlinedCallData* call_data,
                   bool stricter_heuristic) {
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

    if (FlowGraphInliner::FunctionHasNeverInlinePragma(function)) {
      TRACE_INLINING(THR_Print("     Bailout: vm:never-inline pragma\n"));
      return false;
    }

    // Don't inline any intrinsified functions in precompiled mode
    // to reduce code size and make sure we use the intrinsic code.
    if (CompilerState::Current().is_aot() && function.is_intrinsic() &&
        !inliner_->AlwaysInline(function)) {
      TRACE_INLINING(THR_Print("     Bailout: intrinisic\n"));
      PRINT_INLINING_TREE("intrinsic", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Do not rely on function type feedback or presence of code to determine
    // if a function was compiled.
    if (!CompilerState::Current().is_aot() && !function.WasCompiled()) {
      TRACE_INLINING(THR_Print("     Bailout: not compiled yet\n"));
      PRINT_INLINING_TREE("Not compiled", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Type feedback may have been cleared for this function (ClearICDataArray),
    // but we need it for inlining.
    if (!CompilerState::Current().is_aot() &&
        (function.ic_data_array() == Array::null())) {
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

    // Apply early heuristics. For a specialized case
    // (constants_arg_counts > 0), don't use a previously
    // estimate of the call site and instruction counts.
    // Note that at this point, optional constant parameters
    // are not counted yet, which makes this decision approximate.
    GrowableArray<Value*>* arguments = call_data->arguments;
    const intptr_t constant_arg_count = CountConstants(*arguments);
    const intptr_t instruction_count =
        constant_arg_count == 0 ? function.optimized_instruction_count() : 0;
    const intptr_t call_site_count =
        constant_arg_count == 0 ? function.optimized_call_site_count() : 0;
    InliningDecision decision =
        ShouldWeInline(function, instruction_count, call_site_count);
    if (!decision.value) {
      TRACE_INLINING(
          THR_Print("     Bailout: early heuristics (%s) with "
                    "code size:  %" Pd ", "
                    "call sites: %" Pd ", "
                    "inlining depth of callee: %d, "
                    "const args: %" Pd "\n",
                    decision.reason, instruction_count, call_site_count,
                    function.inlining_depth(), constant_arg_count));
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

    Error& error = Error::Handle();
    {
      // Save and clear deopt id.
      DeoptIdScope deopt_id_scope(thread(), 0);

      // Install bailout jump.
      LongJumpScope jump;
      if (setjmp(*jump.Set()) == 0) {
        // Load IC data for the callee.
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new (Z) ZoneGrowableArray<const ICData*>();
        const bool clone_ic_data = Compiler::IsBackgroundCompilation();
        function.RestoreICDataMap(ic_data_array, clone_ic_data);
        if (Compiler::IsBackgroundCompilation() &&
            (function.ic_data_array() == Array::null())) {
          Compiler::AbortBackgroundCompilation(DeoptId::kNone,
                                               "ICData cleared while inlining");
        }

        // Parse the callee function.
        bool in_cache;
        ParsedFunction* parsed_function;
        {
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
        Code::EntryKind entry_kind = Code::EntryKind::kNormal;
        if (StaticCallInstr* instr = call_data->call->AsStaticCall()) {
          entry_kind = instr->entry_kind();
        } else if (InstanceCallInstr* instr =
                       call_data->call->AsInstanceCall()) {
          entry_kind = instr->entry_kind();
        } else if (PolymorphicInstanceCallInstr* instr =
                       call_data->call->AsPolymorphicInstanceCall()) {
          entry_kind = instr->entry_kind();
        } else if (ClosureCallInstr* instr = call_data->call->AsClosureCall()) {
          entry_kind = instr->entry_kind();
        }
        kernel::FlowGraphBuilder builder(
            parsed_function, ic_data_array, /* not building var desc */ NULL,
            exit_collector,
            /* optimized = */ true, Compiler::kNoOSRDeoptId,
            caller_graph_->max_block_id() + 1,
            entry_kind == Code::EntryKind::kUnchecked);
        {
          callee_graph = builder.BuildGraph();
#if defined(DEBUG)
          // The inlining IDs of instructions in the callee graph are unset
          // until we call SetInliningID later.
          GrowableArray<const Function*> callee_inline_id_to_function;
          callee_inline_id_to_function.Add(&function);
          FlowGraphChecker(callee_graph, callee_inline_id_to_function)
              .Check("Builder (callee)");
#endif
          CalleeGraphValidator::Validate(callee_graph);
        }
#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
        if (CompilerState::Current().is_aot()) {
          callee_graph->PopulateWithICData(parsed_function->function());
        }
#endif

        // If we inline a function which is intrinsified without a fall-through
        // to IR code, we will not have any ICData attached, so we do it
        // manually here.
        if (!CompilerState::Current().is_aot() && function.is_intrinsic()) {
          callee_graph->PopulateWithICData(parsed_function->function());
        }

        // The parameter stubs are a copy of the actual arguments providing
        // concrete information about the values, for example constant values,
        // without linking between the caller and callee graphs.
        // TODO(zerny): Put more information in the stubs, eg, type information.
        const intptr_t first_actual_param_index = call_data->first_arg_index;
        const intptr_t inlined_type_args_param = function.IsGeneric() ? 1 : 0;
        const intptr_t num_inlined_params =
            inlined_type_args_param + function.NumParameters();
        ZoneGrowableArray<Definition*>* param_stubs =
            new (Z) ZoneGrowableArray<Definition*>(num_inlined_params);

        // Create a ConstantInstr as Definition for the type arguments, if any.
        if (first_actual_param_index > 0) {
          // A type argument vector is explicitly passed.
          param_stubs->Add(
              CreateParameterStub(-1, (*arguments)[0], callee_graph));
        } else if (inlined_type_args_param > 0) {
          // No type argument vector is passed to the generic function,
          // pass a null vector, which is the same as a vector of dynamic types.
          param_stubs->Add(callee_graph->GetConstant(Object::ZoneHandle()));
        }
        // Create a parameter stub for each fixed positional parameter.
        for (intptr_t i = 0; i < function.num_fixed_parameters(); ++i) {
          param_stubs->Add(CreateParameterStub(
              i, (*arguments)[first_actual_param_index + i], callee_graph));
        }

        // If the callee has optional parameters, rebuild the argument and stub
        // arrays so that actual arguments are in one-to-one with the formal
        // parameters.
        if (function.HasOptionalParameters()) {
          TRACE_INLINING(THR_Print("     adjusting for optional parameters\n"));
          if (!AdjustForOptionalParameters(
                  *parsed_function, first_actual_param_index, argument_names,
                  arguments, param_stubs, callee_graph)) {
            function.set_is_inlinable(false);
            TRACE_INLINING(THR_Print("     Bailout: optional arg mismatch\n"));
            PRINT_INLINING_TREE("Optional arg mismatch", &call_data->caller,
                                &function, call_data->call);
            return false;
          }
        }

        // After treating optional parameters the actual/formal count must
        // match.
        ASSERT(arguments->length() ==
               first_actual_param_index + function.NumParameters());

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

        BlockScheduler::AssignEdgeWeights(callee_graph);

        {
          // Compute SSA on the callee graph, catching bailouts.
          callee_graph->ComputeSSA(caller_graph_->max_virtual_register_number(),
                                   param_stubs);
#if defined(DEBUG)
          // The inlining IDs of instructions in the callee graph are unset
          // until we call SetInliningID later.
          GrowableArray<const Function*> callee_inline_id_to_function;
          callee_inline_id_to_function.Add(&function);
          FlowGraphChecker(callee_graph, callee_inline_id_to_function)
              .Check("SSA (callee)");
#endif
        }

        if (FLAG_support_il_printer && trace_inlining() &&
            (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized)) {
          THR_Print("Callee graph for inlining %s (unoptimized)\n",
                    function.ToFullyQualifiedCString());
          FlowGraphPrinter printer(*callee_graph);
          printer.PrintBlocks();
        }

        {
          // TODO(fschneider): Improve suppression of speculative inlining.
          // Deopt-ids overlap between caller and callee.
          if (CompilerState::Current().is_aot()) {
#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
            AotCallSpecializer call_specializer(inliner_->precompiler_,
                                                callee_graph,
                                                inliner_->speculative_policy_);

            CompilerPassState state(Thread::Current(), callee_graph,
                                    inliner_->speculative_policy_);
            state.call_specializer = &call_specializer;
            CompilerPass::RunInliningPipeline(CompilerPass::kAOT, &state);
#else
            UNREACHABLE();
#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
          } else {
            JitCallSpecializer call_specializer(callee_graph,
                                                inliner_->speculative_policy_);

            CompilerPassState state(Thread::Current(), callee_graph,
                                    inliner_->speculative_policy_);
            state.call_specializer = &call_specializer;
            CompilerPass::RunInliningPipeline(CompilerPass::kJIT, &state);
          }
        }

        if (FLAG_support_il_printer && trace_inlining() &&
            (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized)) {
          THR_Print("Callee graph for inlining %s (optimized)\n",
                    function.ToFullyQualifiedCString());
          FlowGraphPrinter printer(*callee_graph);
          printer.PrintBlocks();
        }

        // Collect information about the call site and caller graph. At this
        // point, optional constant parameters are counted too, making the
        // specialized vs. non-specialized decision accurate.
        intptr_t constants_count = 0;
        for (intptr_t i = 0, n = param_stubs->length(); i < n; ++i) {
          if ((*param_stubs)[i]->IsConstant()) ++constants_count;
        }
        intptr_t instruction_count = 0;
        intptr_t call_site_count = 0;
        FlowGraphInliner::CollectGraphInfo(callee_graph, constants_count,
                                           /*force*/ false, &instruction_count,
                                           &call_site_count);

        // Use heuristics do decide if this call should be inlined.
        InliningDecision decision =
            ShouldWeInline(function, instruction_count, call_site_count);
        if (!decision.value) {
          // If size is larger than all thresholds, don't consider it again.
          if ((instruction_count > FLAG_inlining_size_threshold) &&
              (call_site_count > FLAG_inlining_callee_call_sites_threshold)) {
            function.set_is_inlinable(false);
          }
          TRACE_INLINING(
              THR_Print("     Bailout: heuristics (%s) with "
                        "code size:  %" Pd ", "
                        "call sites: %" Pd ", "
                        "inlining depth of callee: %d, "
                        "const args: %" Pd "\n",
                        decision.reason, instruction_count, call_site_count,
                        function.inlining_depth(), constants_count));
          PRINT_INLINING_TREE("Heuristic fail", &call_data->caller, &function,
                              call_data->call);
          return false;
        }

        // If requested, a stricter heuristic is applied to this inlining. This
        // heuristic always scans the method (rather than possibly reusing
        // cached results) to make sure all specializations are accounted for.
        // TODO(ajcbik): with the now better bookkeeping, explore removing this
        if (stricter_heuristic) {
          if (!IsSmallLeaf(callee_graph)) {
            TRACE_INLINING(
                THR_Print("     Bailout: heuristics (no small leaf)\n"));
            PRINT_INLINING_TREE("Heuristic fail (no small leaf)",
                                &call_data->caller, &function, call_data->call);
            return false;
          }
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
        inlined_size_ += instruction_count;
        if (is_recursive_call) {
          inlined_recursive_call_ = true;
        }

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

        FlowGraphInliner::SetInliningId(
            callee_graph, inliner_->NextInlineId(callee_graph->function(),
                                                 call_data->call->source()));
        TRACE_INLINING(THR_Print("     Success\n"));
        TRACE_INLINING(THR_Print(
            "       with reason %s, code size %" Pd ", call sites: %" Pd "\n",
            decision.reason, instruction_count, call_site_count));
        PRINT_INLINING_TREE(NULL, &call_data->caller, &function, call);
        return true;
      } else {
        error = thread()->StealStickyError();

        if (error.IsLanguageError() &&
            (LanguageError::Cast(error).kind() == Report::kBailout)) {
          if (error.raw() == Object::background_compilation_error().raw()) {
            // Fall through to exit the compilation, and retry it later.
          } else {
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
    ASSERT(CompilerState::Current().is_aot() ||
           Compiler::IsBackgroundCompilation() || error.IsUnhandledException());
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
    FlowGraph* callee_graph = call_data->callee_graph;
    auto callee_function_entry = callee_graph->graph_entry()->normal_entry();

    // Plug result in the caller graph.
    InlineExitCollector* exit_collector = call_data->exit_collector;
    exit_collector->PrepareGraphs(callee_graph);
    exit_collector->ReplaceCall(callee_function_entry);

    ReplaceParameterStubs(zone(), caller_graph_, call_data, NULL);

    ASSERT(!call_data->call->HasPushArguments());
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
    return parsed_function;
  }

  bool InlineStaticCalls() {
    bool inlined = false;
    const GrowableArray<CallSites::StaticCallInfo>& call_info =
        inlining_call_sites_->static_calls();
    TRACE_INLINING(THR_Print("  Static Calls (%" Pd ")\n", call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      StaticCallInstr* call = call_info[call_idx].call;

      if (FlowGraphInliner::TryReplaceStaticCallWithInline(
              inliner_->flow_graph(), NULL, call,
              inliner_->speculative_policy_)) {
        inlined = true;
        continue;
      }

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
        arguments.Add(call->ArgumentValueAt(i));
      }
      InlinedCallData call_data(
          call, Array::ZoneHandle(Z, call->GetArgumentsDescriptor()),
          call->FirstArgIndex(), &arguments, call_info[call_idx].caller());

      // Under AOT, calls outside loops may pass our regular heuristics due
      // to a relatively high ratio. So, unless we are optimizing solely for
      // speed, such call sites are subject to subsequent stricter heuristic
      // to limit code size increase.
      bool stricter_heuristic = CompilerState::Current().is_aot() &&
                                FLAG_optimization_level <= 2 &&
                                !inliner_->AlwaysInline(target) &&
                                call_info[call_idx].nesting_depth == 0;
      if (TryInlining(call->function(), call->argument_names(), &call_data,
                      stricter_heuristic)) {
        InlineCall(&call_data);
        inlined = true;
      }
    }
    return inlined;
  }

  bool InlineClosureCalls() {
    // Under this flag, tear off testing closure calls appear before the
    // StackOverflowInstr, which breaks assertions in our compiler when inlined.
    // TODO(sjindel): move testing closure calls after first check
    if (FLAG_enable_testing_pragmas) return false;  // keep all closures
    bool inlined = false;
    const GrowableArray<CallSites::ClosureCallInfo>& call_info =
        inlining_call_sites_->closure_calls();
    TRACE_INLINING(
        THR_Print("  Closure Calls (%" Pd ")\n", call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      ClosureCallInstr* call = call_info[call_idx].call;
      // Find the closure of the callee.
      ASSERT(call->ArgumentCount() > 0);
      Function& target = Function::ZoneHandle();
      Definition* receiver =
          call->Receiver()->definition()->OriginalDefinition();
      if (AllocateObjectInstr* alloc = receiver->AsAllocateObject()) {
        if (!alloc->closure_function().IsNull()) {
          target = alloc->closure_function().raw();
          ASSERT(alloc->cls().IsClosureClass());
        }
      } else if (ConstantInstr* constant = receiver->AsConstant()) {
        if (constant->value().IsClosure()) {
          target = Closure::Cast(constant->value()).function();
        }
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
        arguments.Add(call->ArgumentValueAt(i));
      }
      const Array& arguments_descriptor =
          Array::ZoneHandle(Z, call->GetArgumentsDescriptor());
      InlinedCallData call_data(call, arguments_descriptor,
                                call->FirstArgIndex(), &arguments,
                                call_info[call_idx].caller());
      if (TryInlining(target, call->argument_names(), &call_data, false)) {
        InlineCall(&call_data);
        inlined = true;
      }
    }
    return inlined;
  }

  bool InlineInstanceCalls() {
    bool inlined = false;
    const GrowableArray<CallSites::InstanceCallInfo>& call_info =
        inlining_call_sites_->instance_calls();
    TRACE_INLINING(THR_Print("  Polymorphic Instance Calls (%" Pd ")\n",
                             call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      PolymorphicInstanceCallInstr* call = call_info[call_idx].call;
      // PolymorphicInliner introduces deoptimization paths.
      if (!call->complete() && !FLAG_polymorphic_with_deopt) {
        TRACE_INLINING(THR_Print("  => %s\n     Bailout: call with checks\n",
                                 call->function_name().ToCString()));
        continue;
      }
      const Function& cl = call_info[call_idx].caller();
      PolymorphicInliner inliner(this, call, cl);
      if (inliner.Inline()) inlined = true;
    }
    return inlined;
  }

  bool AdjustForOptionalParameters(const ParsedFunction& parsed_function,
                                   intptr_t first_arg_index,
                                   const Array& argument_names,
                                   GrowableArray<Value*>* arguments,
                                   ZoneGrowableArray<Definition*>* param_stubs,
                                   FlowGraph* callee_graph) {
    const Function& function = parsed_function.function();
    // The language and this code does not support both optional positional
    // and optional named parameters for the same function.
    ASSERT(!function.HasOptionalPositionalParameters() ||
           !function.HasOptionalNamedParameters());

    intptr_t arg_count = arguments->length();
    intptr_t param_count = function.NumParameters();
    intptr_t fixed_param_count = function.num_fixed_parameters();
    ASSERT(fixed_param_count <= arg_count - first_arg_index);
    ASSERT(arg_count - first_arg_index <= param_count);

    if (function.HasOptionalPositionalParameters()) {
      // Create a stub for each optional positional parameters with an actual.
      for (intptr_t i = first_arg_index + fixed_param_count; i < arg_count;
           ++i) {
        param_stubs->Add(CreateParameterStub(i, (*arguments)[i], callee_graph));
      }
      ASSERT(function.NumOptionalPositionalParameters() ==
             (param_count - fixed_param_count));
      // For each optional positional parameter without an actual, add its
      // default value.
      for (intptr_t i = arg_count - first_arg_index; i < param_count; ++i) {
        const Instance& object =
            parsed_function.DefaultParameterValueAt(i - fixed_param_count);
        ConstantInstr* constant = new (Z) ConstantInstr(object);
        arguments->Add(NULL);
        param_stubs->Add(constant);
      }
      return true;
    }

    ASSERT(function.HasOptionalNamedParameters());

    // Passed arguments (not counting optional type args) must match fixed
    // parameters plus named arguments.
    intptr_t argument_names_count =
        (argument_names.IsNull()) ? 0 : argument_names.Length();
    ASSERT((arg_count - first_arg_index) ==
           (fixed_param_count + argument_names_count));

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
      named_args.Add(NamedArgument(
          &arg_name, (*arguments)[first_arg_index + fixed_param_count + i]));
    }

    // Truncate the arguments array to just type args and fixed parameters.
    arguments->TruncateTo(first_arg_index + fixed_param_count);

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
        param_stubs->Add(
            CreateParameterStub(first_arg_index + i, arg, callee_graph));
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
                                       const Function& caller_function)
    : owner_(owner),
      call_(call),
      num_variants_(call->NumberOfChecks()),
      variants_(call->targets_),
      inlined_variants_(zone()),
      non_inlined_variants_(new (zone()) CallTargets(zone())),
      inlined_entries_(num_variants_),
      exit_collector_(new (Z) InlineExitCollector(owner->caller_graph(), call)),
      caller_function_(caller_function) {}

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
        !target.is_polymorphic_target()) {
      // The call target is shared with a previous inlined variant.  Share
      // the graph.  This requires a join block at the entry, and edge-split
      // form requires a target for each branch.
      //
      // Represent the sharing by recording a fresh target for the first
      // variant and the shared join for all later variants.
      if (inlined_entries_[i]->IsGraphEntry()) {
        // Convert the old target entry to a new join entry.
        auto old_entry = inlined_entries_[i]->AsGraphEntry()->normal_entry();
        BlockEntryInstr* old_target = old_entry;

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
        // Since we are reusing the same inlined body across multiple cids,
        // reset the type information on the redefinition of the receiver
        // in case it was originally given a concrete type.
        ASSERT(new_join->next()->IsRedefinition());
        new_join->next()->AsRedefinition()->UpdateType(CompileType::Dynamic());
        // Create a new target with the join as unconditional successor.
        TargetEntryInstr* new_target = new TargetEntryInstr(
            AllocateBlockId(), old_target->try_index(), DeoptId::kNone);
        new_target->InheritDeoptTarget(zone(), new_join);
        GotoInstr* new_goto = new (Z) GotoInstr(new_join, DeoptId::kNone);
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
  if ((!CompilerState::Current().is_aot() ||
       owner_->inliner_->speculative_policy()->AllowsSpeculativeInlining()) &&
      target_info.IsSingleCid() &&
      TryInlineRecognizedMethod(target_info.cid_start, *target_info.target)) {
    owner_->inlined_ = true;
    return true;
  }

  GrowableArray<Value*> arguments(call_->ArgumentCount());
  for (int i = 0; i < call_->ArgumentCount(); ++i) {
    arguments.Add(call_->ArgumentValueAt(i));
  }
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, call_->GetArgumentsDescriptor());
  InlinedCallData call_data(call_, arguments_descriptor, call_->FirstArgIndex(),
                            &arguments, caller_function_);
  Function& target = Function::ZoneHandle(zone(), target_info.target->raw());
  if (!owner_->TryInlining(target, call_->argument_names(), &call_data,
                           false)) {
    return false;
  }

  FlowGraph* callee_graph = call_data.callee_graph;
  call_data.exit_collector->PrepareGraphs(callee_graph);
  inlined_entries_.Add(callee_graph->graph_entry());
  exit_collector_->Union(call_data.exit_collector);

  ReplaceParameterStubs(zone(), owner_->caller_graph(), &call_data,
                        &target_info);
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
  auto temp_parsed_function = new (Z) ParsedFunction(Thread::Current(), target);
  auto graph_entry =
      new (Z) GraphEntryInstr(*temp_parsed_function, Compiler::kNoOSRDeoptId);

  FunctionEntryInstr* entry = nullptr;
  Instruction* last = nullptr;
  Definition* result = nullptr;
  // Replace the receiver argument with a redefinition to prevent code from
  // the inlined body from being hoisted above the inlined entry.
  GrowableArray<Definition*> arguments(call_->ArgumentCount());
  Definition* receiver = call_->Receiver()->definition();
  RedefinitionInstr* redefinition =
      new (Z) RedefinitionInstr(new (Z) Value(receiver));
  redefinition->set_ssa_temp_index(
      owner_->caller_graph()->alloc_ssa_temp_index());
  if (FlowGraph::NeedsPairLocation(redefinition->representation())) {
    owner_->caller_graph()->alloc_ssa_temp_index();
  }
  if (FlowGraphInliner::TryInlineRecognizedMethod(
          owner_->caller_graph(), receiver_cid, target, call_, redefinition,
          call_->source(), call_->ic_data(), graph_entry, &entry, &last,
          &result, owner_->inliner_->speculative_policy())) {
    // The empty Object constructor is the only case where the inlined body is
    // empty and there is no result.
    ASSERT((last != nullptr && result != nullptr) ||
           (target.recognized_kind() == MethodRecognizer::kObjectConstructor));
    graph_entry->set_normal_entry(entry);
    // Create a graph fragment.
    redefinition->InsertAfter(entry);
    InlineExitCollector* exit_collector =
        new (Z) InlineExitCollector(owner_->caller_graph(), call_);
    ReturnInstr* return_result = new (Z)
        ReturnInstr(call_->source(), new (Z) Value(result), DeoptId::kNone);
    owner_->caller_graph()->AppendTo(
        last, return_result,
        call_->env(),  // Return can become deoptimization target.
        FlowGraph::kEffect);
    entry->set_last_instruction(return_result);
    exit_collector->AddExit(return_result);

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
      AllocateBlockId(), try_idx, CompilerState::Current().GetNextDeoptId());
  entry->InheritDeoptTarget(zone(), call_);

  // This function uses a cursor (a pointer to the 'current' instruction) to
  // build the graph.  The next instruction will be inserted after the
  // cursor.
  BlockEntryInstr* current_block = entry;
  Instruction* cursor = entry;

  Definition* receiver = call_->Receiver()->definition();
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
        auto target = callee_entry->AsGraphEntry()->normal_entry();
        ASSERT(cursor != nullptr);
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
        GotoInstr* goto_join = new GotoInstr(join, DeoptId::kNone);
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
      //
      // TODO(ajcbik): see if this can use the NewDiamond() utility.
      //
      const Smi& cid = Smi::ZoneHandle(Smi::New(variant.cid_start));
      ConstantInstr* cid_constant = owner_->caller_graph()->GetConstant(cid);
      BranchInstr* branch;
      BranchInstr* upper_limit_branch = NULL;
      BlockEntryInstr* cid_test_entry_block = current_block;
      if (test_is_range) {
        // Double branch for testing a range of Cids.
        // TODO(ajcbik): Make a special instruction that uses subtraction
        // and unsigned comparison to do this with a single branch.
        const Smi& cid_end = Smi::ZoneHandle(Smi::New(variant.cid_end));
        ConstantInstr* cid_constant_end =
            owner_->caller_graph()->GetConstant(cid_end);
        RelationalOpInstr* compare_top = new RelationalOpInstr(
            call_->source(), Token::kLTE, new Value(load_cid),
            new Value(cid_constant_end), kSmiCid, call_->deopt_id());
        BranchInstr* branch_top = upper_limit_branch =
            new BranchInstr(compare_top, DeoptId::kNone);
        branch_top->InheritDeoptTarget(zone(), call_);
        cursor = AppendInstruction(cursor, branch_top);
        current_block->set_last_instruction(branch_top);

        TargetEntryInstr* below_target =
            new TargetEntryInstr(AllocateBlockId(), try_idx, DeoptId::kNone);
        below_target->InheritDeoptTarget(zone(), call_);
        current_block->AddDominatedBlock(below_target);
        ASSERT(cursor != nullptr);  // read before overwrite
        cursor = current_block = below_target;
        *branch_top->true_successor_address() = below_target;

        RelationalOpInstr* compare_bottom = new RelationalOpInstr(
            call_->source(), Token::kGTE, new Value(load_cid),
            new Value(cid_constant), kSmiCid, call_->deopt_id());
        branch = new BranchInstr(compare_bottom, DeoptId::kNone);
      } else {
        StrictCompareInstr* compare =
            new StrictCompareInstr(call_->source(), Token::kEQ_STRICT,
                                   new Value(load_cid), new Value(cid_constant),
                                   /* number_check = */ false, DeoptId::kNone);
        branch = new BranchInstr(compare, DeoptId::kNone);
      }

      branch->InheritDeoptTarget(zone(), call_);
      AppendInstruction(cursor, branch);
      cursor = nullptr;
      current_block->set_last_instruction(branch);

      // 2. Handle a match by linking to the inlined body.  There are three
      // cases (unshared, shared first predecessor, and shared subsequent
      // predecessors).
      BlockEntryInstr* callee_entry = inlined_entries_[i];
      TargetEntryInstr* true_target = NULL;
      if (callee_entry->IsGraphEntry()) {
        // Unshared.
        auto graph_entry = callee_entry->AsGraphEntry();
        auto function_entry = graph_entry->normal_entry();

        true_target = BranchSimplifier::ToTargetEntry(zone(), function_entry);
        function_entry->ReplaceAsPredecessorWith(true_target);
        for (intptr_t j = 0; j < function_entry->dominated_blocks().length();
             ++j) {
          BlockEntryInstr* block = function_entry->dominated_blocks()[j];
          true_target->AddDominatedBlock(block);
        }

        // Unuse all inputs of the graph entry. It is not in the graph anymore.
        graph_entry->UnuseAllInputs();
      } else if (callee_entry->IsTargetEntry()) {
        ASSERT(!callee_entry->IsFunctionEntry());
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
        true_target =
            new TargetEntryInstr(AllocateBlockId(), try_idx, DeoptId::kNone);
        true_target->InheritDeoptTarget(zone(), join);
        GotoInstr* goto_join = new GotoInstr(join, DeoptId::kNone);
        goto_join->InheritDeoptTarget(zone(), join);
        true_target->LinkTo(goto_join);
        true_target->set_last_instruction(goto_join);
      }
      *branch->true_successor_address() = true_target;
      current_block->AddDominatedBlock(true_target);

      // 3. Prepare to handle a match failure on the next iteration or the
      // fall-through code below for non-inlined variants.

      TargetEntryInstr* false_target =
          new TargetEntryInstr(AllocateBlockId(), try_idx, DeoptId::kNone);
      false_target->InheritDeoptTarget(zone(), call_);
      *branch->false_successor_address() = false_target;
      cid_test_entry_block->AddDominatedBlock(false_target);

      cursor = current_block = false_target;

      if (test_is_range) {
        // If we tested against a range of Cids there are two different tests
        // that can go to the no-cid-match target.
        JoinEntryInstr* join =
            new JoinEntryInstr(AllocateBlockId(), try_idx, DeoptId::kNone);
        TargetEntryInstr* false_target2 =
            new TargetEntryInstr(AllocateBlockId(), try_idx, DeoptId::kNone);
        *upper_limit_branch->false_successor_address() = false_target2;
        cid_test_entry_block->AddDominatedBlock(false_target2);
        cid_test_entry_block->AddDominatedBlock(join);
        GotoInstr* goto_1 = new GotoInstr(join, DeoptId::kNone);
        GotoInstr* goto_2 = new GotoInstr(join, DeoptId::kNone);
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

  ASSERT(!call_->HasPushArguments());

  // Handle any non-inlined variants.
  if (!non_inlined_variants_->is_empty()) {
    PolymorphicInstanceCallInstr* fallback_call =
        PolymorphicInstanceCallInstr::FromCall(Z, call_, *non_inlined_variants_,
                                               call_->complete());
    fallback_call->set_ssa_temp_index(
        owner_->caller_graph()->alloc_ssa_temp_index());
    if (FlowGraph::NeedsPairLocation(fallback_call->representation())) {
      owner_->caller_graph()->alloc_ssa_temp_index();
    }
    fallback_call->InheritDeoptTarget(zone(), call_);
    fallback_call->set_total_call_count(call_->CallCount());
    ReturnInstr* fallback_return = new ReturnInstr(
        call_->source(), new Value(fallback_call), DeoptId::kNone);
    fallback_return->InheritDeoptTargetAfter(owner_->caller_graph(), call_,
                                             fallback_call);
    AppendInstruction(AppendInstruction(cursor, fallback_call),
                      fallback_return);
    exit_collector_->AddExit(fallback_return);
    cursor = nullptr;
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

bool PolymorphicInliner::Inline() {
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
  if (inlined_variants_.is_empty()) return false;

  // Now build a decision tree (a DAG because of shared inline variants) and
  // inline it at the call site.
  TargetEntryInstr* entry = BuildDecisionGraph();
  exit_collector_->ReplaceCall(entry);
  return true;
}

FlowGraphInliner::FlowGraphInliner(
    FlowGraph* flow_graph,
    GrowableArray<const Function*>* inline_id_to_function,
    GrowableArray<TokenPosition>* inline_id_to_token_pos,
    GrowableArray<intptr_t>* caller_inline_id,
    SpeculativeInliningPolicy* speculative_policy,
    Precompiler* precompiler)
    : flow_graph_(flow_graph),
      inline_id_to_function_(inline_id_to_function),
      inline_id_to_token_pos_(inline_id_to_token_pos),
      caller_inline_id_(caller_inline_id),
      trace_inlining_(FLAG_trace_inlining && flow_graph->should_print()),
      speculative_policy_(speculative_policy),
      precompiler_(precompiler) {}

void FlowGraphInliner::CollectGraphInfo(FlowGraph* flow_graph,
                                        intptr_t constants_count,
                                        bool force,
                                        intptr_t* instruction_count,
                                        intptr_t* call_site_count) {
  const Function& function = flow_graph->function();
  // For OSR, don't even bother.
  if (flow_graph->IsCompiledForOsr()) {
    *instruction_count = 0;
    *call_site_count = 0;
    return;
  }
  // Specialized case: always recompute, never cache.
  if (constants_count > 0) {
    ASSERT(!force);
    GraphInfoCollector info;
    info.Collect(*flow_graph);
    *instruction_count = info.instruction_count();
    *call_site_count = info.call_site_count();
    return;
  }
  // Non-specialized case: unless forced, only recompute on a cache miss.
  ASSERT(constants_count == 0);
  if (force || (function.optimized_instruction_count() == 0)) {
    GraphInfoCollector info;
    info.Collect(*flow_graph);
    function.SetOptimizedInstructionCountClamped(info.instruction_count());
    function.SetOptimizedCallSiteCountClamped(info.call_site_count());
  }
  *instruction_count = function.optimized_instruction_count();
  *call_site_count = function.optimized_call_site_count();
}

void FlowGraphInliner::SetInliningId(FlowGraph* flow_graph,
                                     intptr_t inlining_id) {
  ASSERT(flow_graph->inlining_id() < 0);
  flow_graph->set_inlining_id(inlining_id);
  // We only need to set the inlining ID on instructions that may possibly
  // have token positions, so no need to set it on blocks or internal
  // definitions.
  for (BlockIterator block_it = flow_graph->postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      Instruction* current = it.Current();
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

bool FlowGraphInliner::FunctionHasPreferInlinePragma(const Function& function) {
  Object& options = Object::Handle();
  return Library::FindPragma(dart::Thread::Current(), /*only_core=*/false,
                             function, Symbols::vm_prefer_inline(), &options);
}

bool FlowGraphInliner::FunctionHasNeverInlinePragma(const Function& function) {
  Object& options = Object::Handle();
  return Library::FindPragma(dart::Thread::Current(), /*only_core=*/false,
                             function, Symbols::vm_never_inline(), &options);
}

bool FlowGraphInliner::AlwaysInline(const Function& function) {
  if (FunctionHasPreferInlinePragma(function)) {
    TRACE_INLINING(
        THR_Print("vm:prefer-inline pragma for %s\n", function.ToCString()));
    return true;
  }

  // We don't want to inline DIFs for recognized methods because we would rather
  // replace them with inline FG before inlining introduces any superfluous
  // AssertAssignable instructions.
  if (function.IsDispatcherOrImplicitAccessor() &&
      !(function.kind() == FunctionLayout::kDynamicInvocationForwarder &&
        function.IsRecognized())) {
    // Smaller or same size as the call.
    return true;
  }

  if (function.is_const()) {
    // Inlined const fields are smaller than a call.
    return true;
  }

  if (function.IsGetterFunction() || function.IsSetterFunction() ||
      IsInlineableOperator(function) ||
      (function.kind() == FunctionLayout::kConstructor)) {
    const intptr_t count = function.optimized_instruction_count();
    if ((count != 0) && (count < FLAG_inline_getters_setters_smaller_than)) {
      return true;
    }
  }
  return false;
}

int FlowGraphInliner::Inline() {
  // Collect some early graph information assuming it is non-specialized
  // so that the cached approximation may be used later for an early
  // bailout from inlining.
  intptr_t instruction_count = 0;
  intptr_t call_site_count = 0;
  FlowGraphInliner::CollectGraphInfo(flow_graph_,
                                     /*constants_count*/ 0,
                                     /*force*/ false, &instruction_count,
                                     &call_site_count);

  const Function& top = flow_graph_->function();
  if ((FLAG_inlining_filter != NULL) &&
      (strstr(top.ToFullyQualifiedCString(), FLAG_inlining_filter) == NULL)) {
    return 0;
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
  return inliner.inlining_depth();
}

intptr_t FlowGraphInliner::NextInlineId(const Function& function,
                                        const InstructionSource& source) {
  const intptr_t id = inline_id_to_function_->length();
  // TODO(johnmccutchan): Do not allow IsNoSource once all nodes have proper
  // source positions.
  ASSERT(source.token_pos.IsReal() || source.token_pos.IsSynthetic() ||
         source.token_pos.IsNoSource());
  RELEASE_ASSERT(!function.IsNull());
  inline_id_to_function_->Add(&function);
  inline_id_to_token_pos_->Add(source.token_pos);
  caller_inline_id_->Add(source.inlining_id);
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
  return FlowGraphCompiler::SupportsUnboxedInt64();
}

static bool CanUnboxInt32() {
  // Int32/Uint32 can be unboxed if it fits into a smi or the platform
  // supports unboxed mints.
  return (compiler::target::kSmiBits >= 32) ||
         FlowGraphCompiler::SupportsUnboxedInt64();
}

// Quick access to the current one.
#undef Z
#define Z (flow_graph->zone())

static intptr_t PrepareInlineIndexedOp(FlowGraph* flow_graph,
                                       Instruction* call,
                                       intptr_t array_cid,
                                       Definition** array,
                                       Definition** index,
                                       Instruction** cursor) {
  // Insert array length load and bounds check.
  LoadFieldInstr* length = new (Z) LoadFieldInstr(
      new (Z) Value(*array), Slot::GetLengthFieldForArrayCid(array_cid),
      call->source());
  *cursor = flow_graph->AppendTo(*cursor, length, NULL, FlowGraph::kValue);
  *index = flow_graph->CreateCheckBound(length, *index, call->deopt_id());
  *cursor =
      flow_graph->AppendTo(*cursor, *index, call->env(), FlowGraph::kValue);

  if (array_cid == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements = new (Z)
        LoadFieldInstr(new (Z) Value(*array), Slot::GrowableObjectArray_data(),
                       call->source());
    *cursor = flow_graph->AppendTo(*cursor, elements, NULL, FlowGraph::kValue);
    // Load from the data from backing store which is a fixed-length array.
    *array = elements;
    array_cid = kArrayCid;
  } else if (IsExternalTypedDataClassId(array_cid)) {
    LoadUntaggedInstr* elements = new (Z)
        LoadUntaggedInstr(new (Z) Value(*array),
                          compiler::target::TypedDataBase::data_field_offset());
    *cursor = flow_graph->AppendTo(*cursor, elements, NULL, FlowGraph::kValue);
    *array = elements;
  }
  return array_cid;
}

static bool InlineGetIndexed(FlowGraph* flow_graph,
                             bool can_speculate,
                             bool is_dynamic_call,
                             MethodRecognizer::Kind kind,
                             Definition* call,
                             Definition* receiver,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  intptr_t array_cid = MethodRecognizer::MethodKindToReceiverCid(kind);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);

  if (!can_speculate && is_dynamic_call && !index->Type()->IsInt()) {
    return false;
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineIndexedOp(flow_graph, call, array_cid, &array,
                                     &index, &cursor);

  intptr_t deopt_id = DeoptId::kNone;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id =
        (compiler::target::kSmiBits >= 32) ? DeoptId::kNone : call->deopt_id();
  }

  // Array load and return.
  intptr_t index_scale = compiler::target::Instance::ElementSizeFor(array_cid);
  LoadIndexedInstr* load = new (Z) LoadIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), /*index_unboxed=*/false,
      index_scale, array_cid, kAlignedAccess, deopt_id, call->source(),
      ResultType(call));

  *last = load;
  cursor = flow_graph->AppendTo(cursor, load,
                                deopt_id != DeoptId::kNone ? call->env() : NULL,
                                FlowGraph::kValue);

  const bool value_needs_boxing =
      array_cid == kTypedDataInt8ArrayCid ||
      array_cid == kTypedDataInt16ArrayCid ||
      array_cid == kTypedDataUint8ArrayCid ||
      array_cid == kTypedDataUint8ClampedArrayCid ||
      array_cid == kTypedDataUint16ArrayCid ||
      array_cid == kExternalTypedDataUint8ArrayCid ||
      array_cid == kExternalTypedDataUint8ClampedArrayCid;

  if (array_cid == kTypedDataFloat32ArrayCid) {
    *last = new (Z) FloatToDoubleInstr(new (Z) Value(load), deopt_id);
    flow_graph->AppendTo(cursor, *last,
                         deopt_id != DeoptId::kNone ? call->env() : NULL,
                         FlowGraph::kValue);
  } else if (value_needs_boxing) {
    *last = BoxInstr::Create(kUnboxedIntPtr, new Value(load));
    flow_graph->AppendTo(cursor, *last, nullptr, FlowGraph::kValue);
  }
  *result = (*last)->AsDefinition();
  return true;
}

static bool InlineSetIndexed(FlowGraph* flow_graph,
                             MethodRecognizer::Kind kind,
                             const Function& target,
                             Instruction* call,
                             Definition* receiver,
                             const InstructionSource& source,
                             const Cids* value_check,
                             FlowGraphInliner::ExactnessInfo* exactness,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  intptr_t array_cid = MethodRecognizer::MethodKindToReceiverCid(kind);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  bool is_unchecked_call = false;
  if (StaticCallInstr* static_call = call->AsStaticCall()) {
    is_unchecked_call =
        static_call->entry_kind() == Code::EntryKind::kUnchecked;
  } else if (InstanceCallInstr* instance_call = call->AsInstanceCall()) {
    is_unchecked_call =
        instance_call->entry_kind() == Code::EntryKind::kUnchecked;
  } else if (PolymorphicInstanceCallInstr* instance_call =
                 call->AsPolymorphicInstanceCall()) {
    is_unchecked_call =
        instance_call->entry_kind() == Code::EntryKind::kUnchecked;
  }

  Instruction* cursor = *entry;
  if (!is_unchecked_call &&
      (kind != MethodRecognizer::kObjectArraySetIndexedUnchecked &&
       kind != MethodRecognizer::kGrowableArraySetIndexedUnchecked)) {
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
        LoadFieldInstr* load_type_args = new (Z)
            LoadFieldInstr(new (Z) Value(array),
                           Slot::GetTypeArgumentsSlotFor(flow_graph->thread(),
                                                         instantiator_class),
                           call->source());
        cursor = flow_graph->AppendTo(cursor, load_type_args, NULL,
                                      FlowGraph::kValue);
        type_args = load_type_args;
        break;
      }
      case kTypedDataInt8ArrayCid:
        FALL_THROUGH;
      case kTypedDataUint8ArrayCid:
        FALL_THROUGH;
      case kTypedDataUint8ClampedArrayCid:
        FALL_THROUGH;
      case kExternalTypedDataUint8ArrayCid:
        FALL_THROUGH;
      case kExternalTypedDataUint8ClampedArrayCid:
        FALL_THROUGH;
      case kTypedDataInt16ArrayCid:
        FALL_THROUGH;
      case kTypedDataUint16ArrayCid:
        FALL_THROUGH;
      case kTypedDataInt32ArrayCid:
        FALL_THROUGH;
      case kTypedDataUint32ArrayCid:
        FALL_THROUGH;
      case kTypedDataInt64ArrayCid:
        FALL_THROUGH;
      case kTypedDataUint64ArrayCid:
        ASSERT(value_type.IsIntType());
        FALL_THROUGH;
      case kTypedDataFloat32ArrayCid:
        FALL_THROUGH;
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

    if (exactness != nullptr && exactness->is_exact) {
      exactness->emit_exactness_guard = true;
    } else {
      auto const function_type_args = flow_graph->constant_null();
      auto const dst_type = flow_graph->GetConstant(value_type);
      AssertAssignableInstr* assert_value = new (Z) AssertAssignableInstr(
          source, new (Z) Value(stored_value), new (Z) Value(dst_type),
          new (Z) Value(type_args), new (Z) Value(function_type_args),
          Symbols::Value(), call->deopt_id());
      cursor = flow_graph->AppendTo(cursor, assert_value, call->env(),
                                    FlowGraph::kValue);
    }
  }

  array_cid = PrepareInlineIndexedOp(flow_graph, call, array_cid, &array,
                                     &index, &cursor);

  // Check if store barrier is needed. Byte arrays don't need a store barrier.
  StoreBarrierType needs_store_barrier =
      (IsTypedDataClassId(array_cid) || IsTypedDataViewClassId(array_cid) ||
       IsExternalTypedDataClassId(array_cid))
          ? kNoStoreBarrier
          : kEmitStoreBarrier;

  const bool value_needs_unboxing =
      array_cid == kTypedDataInt8ArrayCid ||
      array_cid == kTypedDataInt16ArrayCid ||
      array_cid == kTypedDataInt32ArrayCid ||
      array_cid == kTypedDataUint8ArrayCid ||
      array_cid == kTypedDataUint8ClampedArrayCid ||
      array_cid == kTypedDataUint16ArrayCid ||
      array_cid == kTypedDataUint32ArrayCid ||
      array_cid == kExternalTypedDataUint8ArrayCid ||
      array_cid == kExternalTypedDataUint8ClampedArrayCid;

  if (value_check != NULL) {
    // No store barrier needed because checked value is a smi, an unboxed mint,
    // an unboxed double, an unboxed Float32x4, or unboxed Int32x4.
    needs_store_barrier = kNoStoreBarrier;
    Instruction* check = flow_graph->CreateCheckClass(
        stored_value, *value_check, call->deopt_id(), call->source());
    cursor =
        flow_graph->AppendTo(cursor, check, call->env(), FlowGraph::kEffect);
  }

  if (array_cid == kTypedDataFloat32ArrayCid) {
    stored_value = new (Z)
        DoubleToFloatInstr(new (Z) Value(stored_value), call->deopt_id());
    cursor =
        flow_graph->AppendTo(cursor, stored_value, NULL, FlowGraph::kValue);
  } else if (value_needs_unboxing) {
    Representation representation = kNoRepresentation;
    switch (array_cid) {
      case kTypedDataInt32ArrayCid:
        representation = kUnboxedInt32;
        break;
      case kTypedDataUint32ArrayCid:
        representation = kUnboxedUint32;
        break;
      case kTypedDataInt8ArrayCid:
      case kTypedDataInt16ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kTypedDataUint16ArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
        representation = kUnboxedIntPtr;
        break;
      default:
        UNREACHABLE();
    }
    stored_value = UnboxInstr::Create(
        representation, new (Z) Value(stored_value), call->deopt_id());
    stored_value->AsUnboxInteger()->mark_truncating();
    cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                  FlowGraph::kValue);
  }

  const intptr_t index_scale =
      compiler::target::Instance::ElementSizeFor(array_cid);
  *last = new (Z) StoreIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), new (Z) Value(stored_value),
      needs_store_barrier, /*index_unboxed=*/false, index_scale, array_cid,
      kAlignedAccess, call->deopt_id(), call->source());
  flow_graph->AppendTo(cursor, *last, call->env(), FlowGraph::kEffect);
  // We need a return value to replace uses of the original definition. However,
  // the final instruction is a use of 'void operator[]=()', so we use null.
  *result = flow_graph->constant_null();
  return true;
}

static bool InlineDoubleOp(FlowGraph* flow_graph,
                           Token::Kind op_kind,
                           Instruction* call,
                           Definition* receiver,
                           GraphEntryInstr* graph_entry,
                           FunctionEntryInstr** entry,
                           Instruction** last,
                           Definition** result) {
  if (!CanUnboxDouble()) {
    return false;
  }
  Definition* left = receiver;
  Definition* right = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  // Arguments are checked. No need for class check.
  BinaryDoubleOpInstr* double_bin_op = new (Z)
      BinaryDoubleOpInstr(op_kind, new (Z) Value(left), new (Z) Value(right),
                          call->deopt_id(), call->source());
  flow_graph->AppendTo(*entry, double_bin_op, call->env(), FlowGraph::kValue);
  *last = double_bin_op;
  *result = double_bin_op->AsDefinition();

  return true;
}

static bool InlineDoubleTestOp(FlowGraph* flow_graph,
                               Instruction* call,
                               Definition* receiver,
                               MethodRecognizer::Kind kind,
                               GraphEntryInstr* graph_entry,
                               FunctionEntryInstr** entry,
                               Instruction** last,
                               Definition** result) {
  if (!CanUnboxDouble()) {
    return false;
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  // Arguments are checked. No need for class check.

  DoubleTestOpInstr* double_test_op = new (Z) DoubleTestOpInstr(
      kind, new (Z) Value(receiver), call->deopt_id(), call->source());
  flow_graph->AppendTo(*entry, double_test_op, call->env(), FlowGraph::kValue);
  *last = double_test_op;
  *result = double_test_op->AsDefinition();

  return true;
}

static bool InlineSmiBitAndFromSmi(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   GraphEntryInstr* graph_entry,
                                   FunctionEntryInstr** entry,
                                   Instruction** last,
                                   Definition** result) {
  Definition* left = receiver;
  Definition* right = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  // Right arguments is known to be smi: other._bitAndFromSmi(this);
  BinarySmiOpInstr* smi_op =
      new (Z) BinarySmiOpInstr(Token::kBIT_AND, new (Z) Value(left),
                               new (Z) Value(right), call->deopt_id());
  flow_graph->AppendTo(*entry, smi_op, call->env(), FlowGraph::kValue);
  *last = smi_op;
  *result = smi_op->AsDefinition();

  return true;
}

static bool InlineGrowableArraySetter(FlowGraph* flow_graph,
                                      const Slot& field,
                                      StoreBarrierType store_barrier_type,
                                      Instruction* call,
                                      Definition* receiver,
                                      GraphEntryInstr* graph_entry,
                                      FunctionEntryInstr** entry,
                                      Instruction** last,
                                      Definition** result) {
  Definition* array = receiver;
  Definition* value = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  // This is an internal method, no need to check argument types.
  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(field, new (Z) Value(array), new (Z) Value(value),
                              store_barrier_type, call->source());
  flow_graph->AppendTo(*entry, store, call->env(), FlowGraph::kEffect);
  *last = store;
  // We need a return value to replace uses of the original definition. However,
  // the last instruction is a field setter, which returns void, so we use null.
  *result = flow_graph->constant_null();

  return true;
}

static bool InlineLoadClassId(FlowGraph* flow_graph,
                              Instruction* call,
                              GraphEntryInstr* graph_entry,
                              FunctionEntryInstr** entry,
                              Instruction** last,
                              Definition** result) {
  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  auto load_cid =
      new (Z) LoadClassIdInstr(call->ArgumentValueAt(0)->CopyWithType(Z));
  flow_graph->InsertBefore(call, load_cid, nullptr, FlowGraph::kValue);
  *last = load_cid;
  *result = load_cid->AsDefinition();
  return true;
}

// Emits preparatory code for a typed getter/setter.
// Handles three cases:
//   (1) dynamic:  generates load untagged (internal or external)
//   (2) external: generates load untagged
//   (3) internal: no code required.
static void PrepareInlineByteArrayBaseOp(FlowGraph* flow_graph,
                                         Instruction* call,
                                         Definition* receiver,
                                         intptr_t array_cid,
                                         Definition** array,
                                         Instruction** cursor) {
  if (array_cid == kDynamicCid || IsExternalTypedDataClassId(array_cid)) {
    // Internal or External typed data: load untagged.
    auto elements = new (Z)
        LoadUntaggedInstr(new (Z) Value(*array),
                          compiler::target::TypedDataBase::data_field_offset());
    *cursor = flow_graph->AppendTo(*cursor, elements, NULL, FlowGraph::kValue);
    *array = elements;
  } else {
    // Internal typed data: no action.
    ASSERT(IsTypedDataClassId(array_cid));
  }
}

static bool InlineByteArrayBaseLoad(FlowGraph* flow_graph,
                                    Definition* call,
                                    Definition* receiver,
                                    intptr_t array_cid,
                                    intptr_t view_cid,
                                    GraphEntryInstr* graph_entry,
                                    FunctionEntryInstr** entry,
                                    Instruction** last,
                                    Definition** result) {
  ASSERT(array_cid != kIllegalCid);

  // Dynamic calls are polymorphic due to:
  // (A) extra bounds check computations (length stored in receiver),
  // (B) external/internal typed data in receiver.
  // Both issues are resolved in the inlined code.
  // All getters that go through InlineByteArrayBaseLoad() have explicit
  // bounds checks in all their clients in the library, so we can omit yet
  // another inlined bounds check.
  if (array_cid == kDynamicCid) {
    ASSERT(call->IsStaticCall());
  }

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;


  // Generates a template for the load, either a dynamic conditional
  // that dispatches on external and internal storage, or a single
  // case that deals with either external or internal storage.
  PrepareInlineByteArrayBaseOp(flow_graph, call, receiver, array_cid, &array,
                               &cursor);

  // Fill out the generated template with loads.
  // Load from either external or internal.
  LoadIndexedInstr* load = new (Z) LoadIndexedInstr(
      new (Z) Value(array), new (Z) Value(index),
      /*index_unboxed=*/false, /*index_scale=*/1, view_cid, kUnalignedAccess,
      DeoptId::kNone, call->source(), ResultType(call));
  flow_graph->AppendTo(
      cursor, load, call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
      FlowGraph::kValue);
  cursor = *last = load;

  if (view_cid == kTypedDataFloat32ArrayCid) {
    *last = new (Z) FloatToDoubleInstr(new (Z) Value((*last)->AsDefinition()),
                                       DeoptId::kNone);
    flow_graph->AppendTo(cursor, *last, nullptr, FlowGraph::kValue);
  }
  *result = (*last)->AsDefinition();
  return true;
}

static StoreIndexedInstr* NewStore(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* array,
                                   Definition* index,
                                   Definition* stored_value,
                                   intptr_t view_cid) {
  return new (Z) StoreIndexedInstr(
      new (Z) Value(array), new (Z) Value(index), new (Z) Value(stored_value),
      kNoStoreBarrier, /*index_unboxed=*/false,
      /*index_scale=*/1, view_cid, kUnalignedAccess, call->deopt_id(),
      call->source());
}

static bool InlineByteArrayBaseStore(FlowGraph* flow_graph,
                                     const Function& target,
                                     Instruction* call,
                                     Definition* receiver,
                                     intptr_t array_cid,
                                     intptr_t view_cid,
                                     GraphEntryInstr* graph_entry,
                                     FunctionEntryInstr** entry,
                                     Instruction** last,
                                     Definition** result) {
  ASSERT(array_cid != kIllegalCid);

  // Dynamic calls are polymorphic due to:
  // (A) extra bounds check computations (length stored in receiver),
  // (B) external/internal typed data in receiver.
  // Both issues are resolved in the inlined code.
  // All setters that go through InlineByteArrayBaseLoad() have explicit
  // bounds checks in all their clients in the library, so we can omit yet
  // another inlined bounds check.
  if (array_cid == kDynamicCid) {
    ASSERT(call->IsStaticCall());
  }

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  // Prepare additional checks. In AOT Dart2, we use an explicit null check and
  // non-speculative unboxing for most value types.
  Cids* value_check = nullptr;
  bool needs_null_check = false;
  switch (view_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      if (CompilerState::Current().is_aot()) {
        needs_null_check = true;
      } else {
        // Check that value is always smi.
        value_check = Cids::CreateMonomorphic(Z, kSmiCid);
      }
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      if (CompilerState::Current().is_aot()) {
        needs_null_check = true;
      } else {
        // On 64-bit platforms assume that stored value is always a smi.
        if (compiler::target::kSmiBits >= 32) {
          value_check = Cids::CreateMonomorphic(Z, kSmiCid);
        }
      }
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid: {
      // Check that value is always double.
      if (CompilerState::Current().is_aot()) {
        needs_null_check = true;
      } else {
        value_check = Cids::CreateMonomorphic(Z, kDoubleCid);
      }
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
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      // StoreIndexedInstr takes unboxed int64, so value is
      // checked when unboxing. In AOT, we use an
      // explicit null check and non-speculative unboxing.
      needs_null_check = CompilerState::Current().is_aot();
      break;
    default:
      // Array cids are already checked in the caller.
      UNREACHABLE();
  }

  Definition* stored_value = call->ArgumentAt(2);

  // Handle value check.
  if (value_check != nullptr) {
    Instruction* check = flow_graph->CreateCheckClass(
        stored_value, *value_check, call->deopt_id(), call->source());
    cursor =
        flow_graph->AppendTo(cursor, check, call->env(), FlowGraph::kEffect);
  }

  // Handle null check.
  if (needs_null_check) {
    String& name = String::ZoneHandle(Z, target.name());
    Instruction* check = new (Z) CheckNullInstr(
        new (Z) Value(stored_value), name, call->deopt_id(), call->source());
    cursor =
        flow_graph->AppendTo(cursor, check, call->env(), FlowGraph::kEffect);
    // With an explicit null check, a non-speculative unbox suffices.
    switch (view_cid) {
      case kTypedDataFloat32ArrayCid:
      case kTypedDataFloat64ArrayCid:
        stored_value =
            UnboxInstr::Create(kUnboxedDouble, new (Z) Value(stored_value),
                               call->deopt_id(), Instruction::kNotSpeculative);
        cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                      FlowGraph::kValue);
        break;
      case kTypedDataInt64ArrayCid:
      case kTypedDataUint64ArrayCid:
        stored_value = new (Z)
            UnboxInt64Instr(new (Z) Value(stored_value), call->deopt_id(),
                            Instruction::kNotSpeculative);
        cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                      FlowGraph::kValue);
        break;
    }
  }

  // Handle conversions and special unboxing (to ensure unboxing instructions
  // are marked as truncating, since [SelectRepresentations] does not take care
  // of that).
  switch (view_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kTypedDataUint16ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      stored_value =
          UnboxInstr::Create(kUnboxedIntPtr, new (Z) Value(stored_value),
                             call->deopt_id(), Instruction::kNotSpeculative);
      stored_value->AsUnboxInteger()->mark_truncating();
      cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                    FlowGraph::kValue);
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      stored_value = new (Z)
          DoubleToFloatInstr(new (Z) Value(stored_value), call->deopt_id());
      cursor = flow_graph->AppendTo(cursor, stored_value, nullptr,
                                    FlowGraph::kValue);
      break;
    }
    case kTypedDataInt32ArrayCid: {
      stored_value = new (Z)
          UnboxInt32Instr(UnboxInt32Instr::kTruncate,
                          new (Z) Value(stored_value), call->deopt_id());
      cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                    FlowGraph::kValue);
      break;
    }
    case kTypedDataUint32ArrayCid: {
      stored_value = new (Z)
          UnboxUint32Instr(new (Z) Value(stored_value), call->deopt_id());
      ASSERT(stored_value->AsUnboxInteger()->is_truncating());
      cursor = flow_graph->AppendTo(cursor, stored_value, call->env(),
                                    FlowGraph::kValue);
      break;
    }
    default:
      break;
  }

  // Generates a template for the store, either a dynamic conditional
  // that dispatches on external and internal storage, or a single
  // case that deals with either external or internal storage.
  PrepareInlineByteArrayBaseOp(flow_graph, call, receiver, array_cid, &array,
                               &cursor);

  // Fill out the generated template with stores.
  {
    // Store on either external or internal.
    StoreIndexedInstr* store =
        NewStore(flow_graph, call, array, index, stored_value, view_cid);
    flow_graph->AppendTo(
        cursor, store,
        call->deopt_id() != DeoptId::kNone ? call->env() : nullptr,
        FlowGraph::kEffect);
    *last = store;
  }
  // We need a return value to replace uses of the original definition. However,
  // the final instruction is a use of 'void operator[]=()', so we use null.
  *result = flow_graph->constant_null();
  return true;
}

// Returns the LoadIndexedInstr.
static Definition* PrepareInlineStringIndexOp(FlowGraph* flow_graph,
                                              Instruction* call,
                                              intptr_t cid,
                                              Definition* str,
                                              Definition* index,
                                              Instruction* cursor) {
  LoadFieldInstr* length = new (Z) LoadFieldInstr(
      new (Z) Value(str), Slot::GetLengthFieldForArrayCid(cid), str->source());
  cursor = flow_graph->AppendTo(cursor, length, NULL, FlowGraph::kValue);

  // Bounds check.
  index = flow_graph->CreateCheckBound(length, index, call->deopt_id());
  cursor = flow_graph->AppendTo(cursor, index, call->env(), FlowGraph::kValue);

  // For external strings: Load backing store.
  if (cid == kExternalOneByteStringCid) {
    str = new LoadUntaggedInstr(
        new Value(str),
        compiler::target::ExternalOneByteString::external_data_offset());
    cursor = flow_graph->AppendTo(cursor, str, NULL, FlowGraph::kValue);
  } else if (cid == kExternalTwoByteStringCid) {
    str = new LoadUntaggedInstr(
        new Value(str),
        compiler::target::ExternalTwoByteString::external_data_offset());
    cursor = flow_graph->AppendTo(cursor, str, NULL, FlowGraph::kValue);
  }

  LoadIndexedInstr* load_indexed = new (Z) LoadIndexedInstr(
      new (Z) Value(str), new (Z) Value(index), /*index_unboxed=*/false,
      compiler::target::Instance::ElementSizeFor(cid), cid, kAlignedAccess,
      DeoptId::kNone, call->source());
  cursor = flow_graph->AppendTo(cursor, load_indexed, NULL, FlowGraph::kValue);

  auto box = BoxInstr::Create(kUnboxedIntPtr, new Value(load_indexed));
  cursor = flow_graph->AppendTo(cursor, box, nullptr, FlowGraph::kValue);

  ASSERT(box == cursor);
  return box;
}

static bool InlineStringBaseCharAt(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   intptr_t cid,
                                   GraphEntryInstr* graph_entry,
                                   FunctionEntryInstr** entry,
                                   Instruction** last,
                                   Definition** result) {
  if ((cid != kOneByteStringCid) && (cid != kExternalOneByteStringCid)) {
    return false;
  }
  Definition* str = receiver;
  Definition* index = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(flow_graph, call, cid, str, index, *entry);

  OneByteStringFromCharCodeInstr* char_at = new (Z)
      OneByteStringFromCharCodeInstr(new (Z) Value((*last)->AsDefinition()));

  flow_graph->AppendTo(*last, char_at, NULL, FlowGraph::kValue);
  *last = char_at;
  *result = char_at->AsDefinition();

  return true;
}

static bool InlineStringCodeUnitAt(FlowGraph* flow_graph,
                                   Instruction* call,
                                   Definition* receiver,
                                   intptr_t cid,
                                   GraphEntryInstr* graph_entry,
                                   FunctionEntryInstr** entry,
                                   Instruction** last,
                                   Definition** result) {
  if (cid == kDynamicCid) {
    ASSERT(call->IsStaticCall());
    return false;
  } else if ((cid != kOneByteStringCid) && (cid != kTwoByteStringCid) &&
             (cid != kExternalOneByteStringCid) &&
             (cid != kExternalTwoByteStringCid)) {
    return false;
  }
  Definition* str = receiver;
  Definition* index = call->ArgumentAt(1);

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(flow_graph, call, cid, str, index, *entry);
  *result = (*last)->AsDefinition();

  return true;
}

// Only used for monomorphic calls.
bool FlowGraphInliner::TryReplaceInstanceCallWithInline(
    FlowGraph* flow_graph,
    ForwardInstructionIterator* iterator,
    InstanceCallInstr* call,
    SpeculativeInliningPolicy* policy) {
  const CallTargets& targets = call->Targets();
  ASSERT(targets.IsMonomorphic());
  const intptr_t receiver_cid = targets.MonomorphicReceiverCid();
  const Function& target = targets.FirstTarget();
  const auto exactness = targets.MonomorphicExactness();
  ExactnessInfo exactness_info{exactness.IsExact(), false};

  FunctionEntryInstr* entry = nullptr;
  Instruction* last = nullptr;
  Definition* result = nullptr;
  if (FlowGraphInliner::TryInlineRecognizedMethod(
          flow_graph, receiver_cid, target, call,
          call->Receiver()->definition(), call->source(), call->ic_data(),
          /*graph_entry=*/nullptr, &entry, &last, &result, policy,
          &exactness_info)) {
    // The empty Object constructor is the only case where the inlined body is
    // empty and there is no result.
    ASSERT((last != nullptr && result != nullptr) ||
           (target.recognized_kind() == MethodRecognizer::kObjectConstructor));
    // Determine if inlining instance methods needs a check.
    FlowGraph::ToCheck check = FlowGraph::ToCheck::kNoCheck;
    if (target.is_polymorphic_target()) {
      check = FlowGraph::ToCheck::kCheckCid;
    } else {
      check = flow_graph->CheckForInstanceCall(call, target.kind());
    }

    // Insert receiver class or null check if needed.
    switch (check) {
      case FlowGraph::ToCheck::kCheckCid: {
        Instruction* check_class = flow_graph->CreateCheckClass(
            call->Receiver()->definition(), targets, call->deopt_id(),
            call->source());
        flow_graph->InsertBefore(call, check_class, call->env(),
                                 FlowGraph::kEffect);
        break;
      }
      case FlowGraph::ToCheck::kCheckNull: {
        Instruction* check_null = new (Z) CheckNullInstr(
            call->Receiver()->CopyWithType(Z), call->function_name(),
            call->deopt_id(), call->source());
        flow_graph->InsertBefore(call, check_null, call->env(),
                                 FlowGraph::kEffect);
        break;
      }
      case FlowGraph::ToCheck::kNoCheck:
        break;
    }

    if (exactness_info.emit_exactness_guard && exactness.IsTriviallyExact()) {
      flow_graph->AddExactnessGuard(call, receiver_cid);
    }

    ASSERT(!call->HasPushArguments());

    // Replace all uses of this definition with the result.
    if (call->HasUses()) {
      ASSERT(result != nullptr && result->HasSSATemp());
      call->ReplaceUsesWith(result);
    }
    // Finally insert the sequence other definition in place of this one in the
    // graph.
    if (entry->next() != NULL) {
      call->previous()->LinkTo(entry->next());
    }
    entry->UnuseAllInputs();  // Entry block is not in the graph.
    if (last != NULL) {
      ASSERT(call->GetBlock() == last->GetBlock());
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
    StaticCallInstr* call,
    SpeculativeInliningPolicy* policy) {
  FunctionEntryInstr* entry = nullptr;
  Instruction* last = nullptr;
  Definition* result = nullptr;
  Definition* receiver = nullptr;
  intptr_t receiver_cid = kIllegalCid;
  if (!call->function().is_static()) {
    receiver = call->Receiver()->definition();
    receiver_cid = call->Receiver()->Type()->ToCid();
  }
  if (FlowGraphInliner::TryInlineRecognizedMethod(
          flow_graph, receiver_cid, call->function(), call, receiver,
          call->source(), call->ic_data(), /*graph_entry=*/nullptr, &entry,
          &last, &result, policy)) {
    // The empty Object constructor is the only case where the inlined body is
    // empty and there is no result.
    ASSERT((last != nullptr && result != nullptr) ||
           (call->function().recognized_kind() ==
            MethodRecognizer::kObjectConstructor));
    ASSERT(!call->HasPushArguments());
    // Replace all uses of this definition with the result.
    if (call->HasUses()) {
      ASSERT(result->HasSSATemp());
      call->ReplaceUsesWith(result);
    }
    // Finally insert the sequence other definition in place of this one in the
    // graph.
    if (entry != nullptr) {
      if (entry->next() != nullptr) {
        call->previous()->LinkTo(entry->next());
      }
      entry->UnuseAllInputs();  // Entry block is not in the graph.
      if (last != NULL) {
        BlockEntryInstr* link = call->GetBlock();
        BlockEntryInstr* exit = last->GetBlock();
        if (link != exit) {
          // Dominance relation and SSA are updated incrementally when
          // conditionals are inserted. But succ/pred and ordering needs
          // to be redone. TODO(ajcbik): do this incrementally too.
          for (intptr_t i = 0, n = link->dominated_blocks().length(); i < n;
               ++i) {
            exit->AddDominatedBlock(link->dominated_blocks()[i]);
          }
          link->ClearDominatedBlocks();
          for (intptr_t i = 0, n = entry->dominated_blocks().length(); i < n;
               ++i) {
            link->AddDominatedBlock(entry->dominated_blocks()[i]);
          }
          Instruction* scan = exit;
          while (scan->next() != nullptr) {
            scan = scan->next();
          }
          scan->LinkTo(call);
          flow_graph->DiscoverBlocks();
        } else {
          last->LinkTo(call);
        }
      }
    }
    // Remove through the iterator.
    if (iterator != NULL) {
      ASSERT(iterator->Current() == call);
      iterator->RemoveCurrentFromGraph();
    } else {
      call->RemoveFromGraph();
    }
    return true;
  }
  return false;
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

static bool InlineSimdOp(FlowGraph* flow_graph,
                         bool is_dynamic_call,
                         Instruction* call,
                         Definition* receiver,
                         MethodRecognizer::Kind kind,
                         GraphEntryInstr* graph_entry,
                         FunctionEntryInstr** entry,
                         Instruction** last,
                         Definition** result) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (is_dynamic_call && call->ArgumentCount() > 1) {
    // Issue(dartbug.com/37737): Dynamic invocation forwarders have the
    // same recognized kind as the method they are forwarding to.
    // That causes us to inline the recognized method and not the
    // dyn: forwarder itself.
    // This is only safe if all arguments are checked in the flow graph we
    // build.
    // For double/int arguments speculative unboxing instructions should ensure
    // to bailout in AOT (or deoptimize in JIT) if the incoming values are not
    // correct. Though for user-implementable types, like
    // operator+(Float32x4 other), this is not safe and we therefore bailout.
    return false;
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
  Instruction* cursor = *entry;
  switch (kind) {
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kInt32x4ShuffleMix:
    case MethodRecognizer::kFloat32x4Shuffle:
    case MethodRecognizer::kFloat32x4ShuffleMix: {
      Definition* mask_definition = call->ArgumentAt(call->ArgumentCount() - 1);
      intptr_t mask = 0;
      if (!CheckMask(mask_definition, &mask)) {
        return false;
      }
      *last = SimdOpInstr::CreateFromCall(Z, kind, receiver, call, mask);
      break;
    }

    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4WithW:
    case MethodRecognizer::kFloat32x4Scale: {
      Definition* left = receiver;
      Definition* right = call->ArgumentAt(1);
      // Note: left and right values are swapped when handed to the instruction,
      // this is done so that the double value is loaded into the output
      // register and can be destroyed.
      // TODO(dartbug.com/31035) this swapping is only needed because register
      // allocator has SameAsFirstInput policy and not SameAsNthInput(n).
      *last = SimdOpInstr::Create(kind, new (Z) Value(right),
                                  new (Z) Value(left), call->deopt_id());
      break;
    }

    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat32x4ToFloat64x2:
    case MethodRecognizer::kFloat64x2ToFloat32x4:
    case MethodRecognizer::kFloat32x4ToInt32x4:
    case MethodRecognizer::kInt32x4ToFloat32x4:
    case MethodRecognizer::kFloat64x2Zero:
      *last = SimdOpInstr::CreateFromFactoryCall(Z, kind, call);
      break;
    case MethodRecognizer::kFloat32x4Mul:
    case MethodRecognizer::kFloat32x4Div:
    case MethodRecognizer::kFloat32x4Add:
    case MethodRecognizer::kFloat32x4Sub:
    case MethodRecognizer::kFloat64x2Mul:
    case MethodRecognizer::kFloat64x2Div:
    case MethodRecognizer::kFloat64x2Add:
    case MethodRecognizer::kFloat64x2Sub:
      *last = SimdOpInstr::CreateFromCall(Z, kind, receiver, call);
      if (CompilerState::Current().is_aot()) {
        // Add null-checks in case of the arguments are known to be compatible
        // but they are possibly nullable.
        // By inserting the null-check, we can allow the unbox instruction later
        // inserted to be non-speculative.
        CheckNullInstr* check1 =
            new (Z) CheckNullInstr(new (Z) Value(receiver), Symbols::FirstArg(),
                                   call->deopt_id(), call->source());

        CheckNullInstr* check2 = new (Z) CheckNullInstr(
            new (Z) Value(call->ArgumentAt(1)), Symbols::SecondArg(),
            call->deopt_id(), call->source(), CheckNullInstr::kArgumentError);

        (*last)->SetInputAt(0, new (Z) Value(check1));
        (*last)->SetInputAt(1, new (Z) Value(check2));

        flow_graph->InsertBefore(call, check1, call->env(), FlowGraph::kValue);
        flow_graph->InsertBefore(call, check2, call->env(), FlowGraph::kValue);
      }
      break;
    default:
      *last = SimdOpInstr::CreateFromCall(Z, kind, receiver, call);
      break;
  }
  // InheritDeoptTarget also inherits environment (which may add 'entry' into
  // env_use_list()), so InheritDeoptTarget should be done only after decided
  // to inline.
  (*entry)->InheritDeoptTarget(Z, call);
  flow_graph->AppendTo(cursor, *last,
                       call->deopt_id() != DeoptId::kNone ? call->env() : NULL,
                       FlowGraph::kValue);
  *result = (*last)->AsDefinition();
  return true;
}

static bool InlineMathCFunction(FlowGraph* flow_graph,
                                Instruction* call,
                                MethodRecognizer::Kind kind,
                                GraphEntryInstr* graph_entry,
                                FunctionEntryInstr** entry,
                                Instruction** last,
                                Definition** result) {
  if (!CanUnboxDouble()) {
    return false;
  }

  for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
    if (call->ArgumentAt(i)->Type()->ToCid() != kDoubleCid) {
      return false;
    }
  }

  *entry =
      new (Z) FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
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
                                               call->source());
      break;
    }
  }
  flow_graph->AppendTo(cursor, *last,
                       call->deopt_id() != DeoptId::kNone ? call->env() : NULL,
                       FlowGraph::kValue);
  *result = (*last)->AsDefinition();
  return true;
}

static Instruction* InlineMul(FlowGraph* flow_graph,
                              Instruction* cursor,
                              Definition* x,
                              Definition* y) {
  BinaryInt64OpInstr* mul = new (Z)
      BinaryInt64OpInstr(Token::kMUL, new (Z) Value(x), new (Z) Value(y),
                         DeoptId::kNone, Instruction::kNotSpeculative);
  return flow_graph->AppendTo(cursor, mul, nullptr, FlowGraph::kValue);
}

static bool InlineMathIntPow(FlowGraph* flow_graph,
                             Instruction* call,
                             GraphEntryInstr* graph_entry,
                             FunctionEntryInstr** entry,
                             Instruction** last,
                             Definition** result) {
  // Invoking the _intPow(x, y) implies that both:
  // (1) x, y are int
  // (2) y >= 0.
  // Thus, try to inline some very obvious cases.
  // TODO(ajcbik): useful to generalize?
  intptr_t val = 0;
  Value* x = call->ArgumentValueAt(0);
  Value* y = call->ArgumentValueAt(1);
  // Use x^0 == 1, x^1 == x, and x^c == x * .. * x for small c.
  const intptr_t small_exponent = 5;
  if (IsSmiValue(y, &val)) {
    if (val == 0) {
      *last = flow_graph->GetConstant(Smi::ZoneHandle(Smi::New(1)));
      *result = (*last)->AsDefinition();
      return true;
    } else if (val == 1) {
      *last = x->definition();
      *result = (*last)->AsDefinition();
      return true;
    } else if (1 < val && val <= small_exponent) {
      // Lazily construct entry only in this case.
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      Definition* x_def = x->definition();
      Definition* square =
          InlineMul(flow_graph, *entry, x_def, x_def)->AsDefinition();
      *last = square;
      *result = square;
      switch (val) {
        case 2:
          return true;
        case 3:
          *last = InlineMul(flow_graph, *last, x_def, square);
          *result = (*last)->AsDefinition();
          return true;
        case 4:
          *last = InlineMul(flow_graph, *last, square, square);
          *result = (*last)->AsDefinition();
          return true;
        case 5:
          *last = InlineMul(flow_graph, *last, square, square);
          *last = InlineMul(flow_graph, *last, x_def, (*last)->AsDefinition());
          *result = (*last)->AsDefinition();
          return true;
      }
    }
  }
  // Use 0^y == 0 (only for y != 0) and 1^y == 1.
  if (IsSmiValue(x, &val)) {
    if (val == 1) {
      *last = x->definition();
      *result = x->definition();
      return true;
    }
  }
  return false;
}

bool FlowGraphInliner::TryInlineRecognizedMethod(
    FlowGraph* flow_graph,
    intptr_t receiver_cid,
    const Function& target,
    Definition* call,
    Definition* receiver,
    const InstructionSource& source,
    const ICData* ic_data,
    GraphEntryInstr* graph_entry,
    FunctionEntryInstr** entry,
    Instruction** last,
    Definition** result,
    SpeculativeInliningPolicy* policy,
    FlowGraphInliner::ExactnessInfo* exactness) {
  if (receiver_cid == kNeverCid) {
    // Receiver was defined in dead code and was replaced by the sentinel.
    // Original receiver cid is lost, so don't try to inline recognized
    // methods.
    return false;
  }

  const bool can_speculate = policy->IsAllowedForInlining(call->deopt_id());
  const bool is_dynamic_call = Function::IsDynamicInvocationForwarderName(
      String::Handle(flow_graph->zone(), target.name()));

  const MethodRecognizer::Kind kind = target.recognized_kind();
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
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kFloat32ArrayGetIndexed:
    case MethodRecognizer::kFloat64ArrayGetIndexed:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kFloat32x4ArrayGetIndexed:
    case MethodRecognizer::kFloat64x2ArrayGetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kInt32ArrayGetIndexed:
    case MethodRecognizer::kUint32ArrayGetIndexed:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kInt64ArrayGetIndexed:
    case MethodRecognizer::kUint64ArrayGetIndexed:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineGetIndexed(flow_graph, can_speculate, is_dynamic_call, kind,
                              call, receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kClassIDgetID:
      return InlineLoadClassId(flow_graph, call, graph_entry, entry, last,
                               result);
    default:
      break;
  }

  // The following ones need to speculate.
  if (!can_speculate) {
    return false;
  }

  switch (kind) {
    // Recognized []= operators.
    case MethodRecognizer::kObjectArraySetIndexed:
    case MethodRecognizer::kGrowableArraySetIndexed:
    case MethodRecognizer::kObjectArraySetIndexedUnchecked:
    case MethodRecognizer::kGrowableArraySetIndexedUnchecked:
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              /* value_check = */ NULL, exactness, graph_entry,
                              entry, last, result);
    case MethodRecognizer::kInt8ArraySetIndexed:
    case MethodRecognizer::kUint8ArraySetIndexed:
    case MethodRecognizer::kUint8ClampedArraySetIndexed:
    case MethodRecognizer::kExternalUint8ArraySetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArraySetIndexed:
    case MethodRecognizer::kInt16ArraySetIndexed:
    case MethodRecognizer::kUint16ArraySetIndexed: {
      // Optimistically assume Smi.
      if (ic_data != NULL && ic_data->HasDeoptReason(ICData::kDeoptCheckSmi)) {
        // Optimistic assumption failed at least once.
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kSmiCid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              value_check, exactness, graph_entry, entry, last,
                              result);
    }
    case MethodRecognizer::kInt32ArraySetIndexed:
    case MethodRecognizer::kUint32ArraySetIndexed: {
      // Value check not needed for Int32 and Uint32 arrays because they
      // implicitly contain unboxing instructions which check for right type.
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              /* value_check = */ NULL, exactness, graph_entry,
                              entry, last, result);
    }
    case MethodRecognizer::kInt64ArraySetIndexed:
    case MethodRecognizer::kUint64ArraySetIndexed:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              /* value_check = */ NULL, exactness, graph_entry,
                              entry, last, result);
    case MethodRecognizer::kFloat32ArraySetIndexed:
    case MethodRecognizer::kFloat64ArraySetIndexed: {
      if (!CanUnboxDouble()) {
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kDoubleCid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              value_check, exactness, graph_entry, entry, last,
                              result);
    }
    case MethodRecognizer::kFloat32x4ArraySetIndexed: {
      if (!ShouldInlineSimd()) {
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kFloat32x4Cid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              value_check, exactness, graph_entry, entry, last,
                              result);
    }
    case MethodRecognizer::kFloat64x2ArraySetIndexed: {
      if (!ShouldInlineSimd()) {
        return false;
      }
      Cids* value_check = Cids::CreateMonomorphic(Z, kFloat64x2Cid);
      return InlineSetIndexed(flow_graph, kind, target, call, receiver, source,
                              value_check, exactness, graph_entry, entry, last,
                              result);
    }
    case MethodRecognizer::kByteArrayBaseGetInt8:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt8ArrayCid, graph_entry, entry,
                                     last, result);
    case MethodRecognizer::kByteArrayBaseGetUint8:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint8ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetInt16:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt16ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetUint16:
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint16ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetInt32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt32ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetUint32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint32ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetInt64:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt64ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetUint64:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataUint64ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataFloat32ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataFloat64ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataFloat32x4ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseGetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseLoad(flow_graph, call, receiver, receiver_cid,
                                     kTypedDataInt32x4ArrayCid, graph_entry,
                                     entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetInt8:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt8ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetUint8:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint8ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetInt16:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt16ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetUint16:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint16ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetInt32:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt32ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetUint32:
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint32ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetInt64:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt64ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetUint64:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataUint64ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataFloat32ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataFloat64ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataFloat32x4ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kByteArrayBaseSetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseStore(flow_graph, target, call, receiver,
                                      receiver_cid, kTypedDataInt32x4ArrayCid,
                                      graph_entry, entry, last, result);
    case MethodRecognizer::kOneByteStringCodeUnitAt:
    case MethodRecognizer::kTwoByteStringCodeUnitAt:
    case MethodRecognizer::kExternalOneByteStringCodeUnitAt:
    case MethodRecognizer::kExternalTwoByteStringCodeUnitAt:
      return InlineStringCodeUnitAt(flow_graph, call, receiver, receiver_cid,
                                    graph_entry, entry, last, result);
    case MethodRecognizer::kStringBaseCharAt:
      return InlineStringBaseCharAt(flow_graph, call, receiver, receiver_cid,
                                    graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleAdd:
      return InlineDoubleOp(flow_graph, Token::kADD, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleSub:
      return InlineDoubleOp(flow_graph, Token::kSUB, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleMul:
      return InlineDoubleOp(flow_graph, Token::kMUL, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDoubleDiv:
      return InlineDoubleOp(flow_graph, Token::kDIV, call, receiver,
                            graph_entry, entry, last, result);
    case MethodRecognizer::kDouble_getIsNaN:
    case MethodRecognizer::kDouble_getIsInfinite:
      return InlineDoubleTestOp(flow_graph, call, receiver, kind, graph_entry,
                                entry, last, result);
    case MethodRecognizer::kGrowableArraySetData:
      ASSERT((receiver_cid == kGrowableObjectArrayCid) ||
             ((receiver_cid == kDynamicCid) && call->IsStaticCall()));
      return InlineGrowableArraySetter(
          flow_graph, Slot::GrowableObjectArray_data(), kEmitStoreBarrier, call,
          receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kGrowableArraySetLength:
      ASSERT((receiver_cid == kGrowableObjectArrayCid) ||
             ((receiver_cid == kDynamicCid) && call->IsStaticCall()));
      return InlineGrowableArraySetter(
          flow_graph, Slot::GrowableObjectArray_length(), kNoStoreBarrier, call,
          receiver, graph_entry, entry, last, result);
    case MethodRecognizer::kSmi_bitAndFromSmi:
      return InlineSmiBitAndFromSmi(flow_graph, call, receiver, graph_entry,
                                    entry, last, result);

    case MethodRecognizer::kFloat32x4Abs:
    case MethodRecognizer::kFloat32x4Clamp:
    case MethodRecognizer::kFloat32x4FromDoubles:
    case MethodRecognizer::kFloat32x4Equal:
    case MethodRecognizer::kFloat32x4GetSignMask:
    case MethodRecognizer::kFloat32x4GreaterThan:
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
    case MethodRecognizer::kFloat32x4LessThan:
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
    case MethodRecognizer::kFloat32x4Max:
    case MethodRecognizer::kFloat32x4Min:
    case MethodRecognizer::kFloat32x4Negate:
    case MethodRecognizer::kFloat32x4NotEqual:
    case MethodRecognizer::kFloat32x4Reciprocal:
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
    case MethodRecognizer::kFloat32x4Scale:
    case MethodRecognizer::kFloat32x4ShuffleW:
    case MethodRecognizer::kFloat32x4ShuffleX:
    case MethodRecognizer::kFloat32x4ShuffleY:
    case MethodRecognizer::kFloat32x4ShuffleZ:
    case MethodRecognizer::kFloat32x4Splat:
    case MethodRecognizer::kFloat32x4Sqrt:
    case MethodRecognizer::kFloat32x4ToFloat64x2:
    case MethodRecognizer::kFloat32x4ToInt32x4:
    case MethodRecognizer::kFloat32x4WithW:
    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat64x2Abs:
    case MethodRecognizer::kFloat64x2FromDoubles:
    case MethodRecognizer::kFloat64x2GetSignMask:
    case MethodRecognizer::kFloat64x2GetX:
    case MethodRecognizer::kFloat64x2GetY:
    case MethodRecognizer::kFloat64x2Max:
    case MethodRecognizer::kFloat64x2Min:
    case MethodRecognizer::kFloat64x2Negate:
    case MethodRecognizer::kFloat64x2Scale:
    case MethodRecognizer::kFloat64x2Splat:
    case MethodRecognizer::kFloat64x2Sqrt:
    case MethodRecognizer::kFloat64x2ToFloat32x4:
    case MethodRecognizer::kFloat64x2WithX:
    case MethodRecognizer::kFloat64x2WithY:
    case MethodRecognizer::kFloat64x2Zero:
    case MethodRecognizer::kInt32x4FromBools:
    case MethodRecognizer::kInt32x4FromInts:
    case MethodRecognizer::kInt32x4GetFlagW:
    case MethodRecognizer::kInt32x4GetFlagX:
    case MethodRecognizer::kInt32x4GetFlagY:
    case MethodRecognizer::kInt32x4GetFlagZ:
    case MethodRecognizer::kInt32x4GetSignMask:
    case MethodRecognizer::kInt32x4Select:
    case MethodRecognizer::kInt32x4ToFloat32x4:
    case MethodRecognizer::kInt32x4WithFlagW:
    case MethodRecognizer::kInt32x4WithFlagX:
    case MethodRecognizer::kInt32x4WithFlagY:
    case MethodRecognizer::kInt32x4WithFlagZ:
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kInt32x4ShuffleMix:
    case MethodRecognizer::kFloat32x4Shuffle:
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kFloat32x4Mul:
    case MethodRecognizer::kFloat32x4Div:
    case MethodRecognizer::kFloat32x4Add:
    case MethodRecognizer::kFloat32x4Sub:
    case MethodRecognizer::kFloat64x2Mul:
    case MethodRecognizer::kFloat64x2Div:
    case MethodRecognizer::kFloat64x2Add:
    case MethodRecognizer::kFloat64x2Sub:
      return InlineSimdOp(flow_graph, is_dynamic_call, call, receiver, kind,
                          graph_entry, entry, last, result);

    case MethodRecognizer::kMathSqrt:
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathSin:
    case MethodRecognizer::kMathCos:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathAtan2:
      return InlineMathCFunction(flow_graph, call, kind, graph_entry, entry,
                                 last, result);

    case MethodRecognizer::kMathIntPow:
      return InlineMathIntPow(flow_graph, call, graph_entry, entry, last,
                              result);

    case MethodRecognizer::kObjectConstructor: {
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      ASSERT(!call->HasUses());
      *last = NULL;    // Empty body.
      *result = NULL;  // Since no uses of original call, result will be unused.
      return true;
    }

    case MethodRecognizer::kListFactory: {
      // We only want to inline new List(n) which decreases code size and
      // improves performance. We don't want to inline new List().
      if (call->ArgumentCount() != 2) {
        return false;
      }

      const auto type = new (Z) Value(call->ArgumentAt(0));
      const auto num_elements = new (Z) Value(call->ArgumentAt(1));
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      *last = new (Z) CreateArrayInstr(call->source(), type, num_elements,
                                       call->deopt_id());
      flow_graph->AppendTo(
          *entry, *last,
          call->deopt_id() != DeoptId::kNone ? call->env() : NULL,
          FlowGraph::kValue);
      *result = (*last)->AsDefinition();
      return true;
    }

    case MethodRecognizer::kObjectArrayAllocate: {
      Value* num_elements = new (Z) Value(call->ArgumentAt(1));
      intptr_t length = 0;
      if (IsSmiValue(num_elements, &length)) {
        if (Array::IsValidLength(length)) {
          Value* type = new (Z) Value(call->ArgumentAt(0));
          *entry = new (Z)
              FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                                 call->GetBlock()->try_index(), DeoptId::kNone);
          (*entry)->InheritDeoptTarget(Z, call);
          *last = new (Z) CreateArrayInstr(call->source(), type, num_elements,
                                           call->deopt_id());
          flow_graph->AppendTo(
              *entry, *last,
              call->deopt_id() != DeoptId::kNone ? call->env() : NULL,
              FlowGraph::kValue);
          *result = (*last)->AsDefinition();
          return true;
        }
      }
      return false;
    }

    case MethodRecognizer::kObjectRuntimeType: {
      Type& type = Type::ZoneHandle(Z);
      if (receiver_cid == kDynamicCid) {
        return false;
      } else if (IsStringClassId(receiver_cid)) {
        type = Type::StringType();
      } else if (receiver_cid == kDoubleCid) {
        type = Type::Double();
      } else if (IsIntegerClassId(receiver_cid)) {
        type = Type::IntType();
      } else if (receiver_cid != kClosureCid) {
        const Class& cls = Class::Handle(
            Z, flow_graph->isolate()->class_table()->At(receiver_cid));
        if (!cls.IsGeneric()) {
          type = cls.DeclarationType();
        }
      }

      if (!type.IsNull()) {
        *entry = new (Z)
            FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                               call->GetBlock()->try_index(), DeoptId::kNone);
        (*entry)->InheritDeoptTarget(Z, call);
        ConstantInstr* ctype = flow_graph->GetConstant(type);
        // Create a synthetic (re)definition for return to flag insertion.
        // TODO(ajcbik): avoid this mechanism altogether
        RedefinitionInstr* redef =
            new (Z) RedefinitionInstr(new (Z) Value(ctype));
        flow_graph->AppendTo(
            *entry, redef,
            call->deopt_id() != DeoptId::kNone ? call->env() : NULL,
            FlowGraph::kValue);
        *last = *result = redef;
        return true;
      }
      return false;
    }

    case MethodRecognizer::kWriteIntoOneByteString:
    case MethodRecognizer::kWriteIntoTwoByteString: {
      // This is an internal method, no need to check argument types nor
      // range.
      *entry = new (Z)
          FunctionEntryInstr(graph_entry, flow_graph->allocate_block_id(),
                             call->GetBlock()->try_index(), DeoptId::kNone);
      (*entry)->InheritDeoptTarget(Z, call);
      Definition* str = call->ArgumentAt(0);
      Definition* index = call->ArgumentAt(1);
      Definition* value = call->ArgumentAt(2);

      auto env = call->deopt_id() != DeoptId::kNone ? call->env() : nullptr;

      // Insert explicit unboxing instructions with truncation to avoid relying
      // on [SelectRepresentations] which doesn't mark them as truncating.
      value =
          UnboxInstr::Create(kUnboxedIntPtr, new (Z) Value(value),
                             call->deopt_id(), Instruction::kNotSpeculative);
      value->AsUnboxInteger()->mark_truncating();
      flow_graph->AppendTo(*entry, value, env, FlowGraph::kValue);

      const bool is_onebyte = kind == MethodRecognizer::kWriteIntoOneByteString;
      const intptr_t index_scale = is_onebyte ? 1 : 2;
      const intptr_t cid = is_onebyte ? kOneByteStringCid : kTwoByteStringCid;
      *last = new (Z) StoreIndexedInstr(
          new (Z) Value(str), new (Z) Value(index), new (Z) Value(value),
          kNoStoreBarrier, /*index_unboxed=*/false, index_scale, cid,
          kAlignedAccess, call->deopt_id(), call->source());
      flow_graph->AppendTo(value, *last, env, FlowGraph::kEffect);

      // We need a return value to replace uses of the original definition.
      // The final instruction is a use of 'void operator[]=()', so we use null.
      *result = flow_graph->constant_null();
      return true;
    }

    default:
      return false;
  }
}

}  // namespace dart
