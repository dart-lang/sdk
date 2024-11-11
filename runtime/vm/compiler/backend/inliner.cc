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
#include "vm/compiler/compiler_timings.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/flags.h"
#include "vm/kernel.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(int,
            deoptimization_counter_inlining_threshold,
            12,
            "How many times we allow deoptimization before we stop inlining.");
DEFINE_FLAG(bool, trace_inlining, false, "Trace inlining");
DEFINE_FLAG(charp, inlining_filter, nullptr, "Inline only in named function");

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
  while (env != nullptr) {
    if (function.ptr() == env->function().ptr()) {
      return true;
    }
    env = env->outer();
  }
  return false;
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
          current = current->AsBranch()->condition();
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
        // Count inputs of certain instructions as if separate MoveArgument
        // instructions are used for inputs. This is done in order to
        // preserve inlining behavior and avoid code size growth after
        // MoveArgument insertion was moved to the end of the
        // compilation pipeline.
        if (current->IsAllocateObject()) {
          instruction_count_ += current->InputCount();
        } else if (current->ArgumentCount() > 0) {
          ASSERT(!current->HasMoveArguments());
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

// A collection of call sites to consider for inlining.
class CallSites : public ValueObject {
 public:
  template <typename CallType>
  struct CallInfo {
    FlowGraph* caller_graph;
    CallType* call;
    intptr_t call_depth;
    intptr_t nesting_depth;
    intptr_t call_count;
    double ratio = 0.0;

    CallInfo(FlowGraph* caller_graph,
             CallType* call,
             intptr_t call_depth,
             intptr_t nesting_depth)
        : caller_graph(caller_graph),
          call(call),
          call_depth(call_depth),
          nesting_depth(nesting_depth) {
      if (CompilerState::Current().is_aot()) {
        call_count = AotCallCountApproximation(nesting_depth);
      } else {
        call_count = call->CallCount();
      }
    }

    const Function& caller() const { return caller_graph->function(); }
  };

  explicit CallSites(intptr_t threshold,
                     GrowableArray<CallInfo<InstanceCallInstr>>* calls)
      : inlining_depth_threshold_(threshold),
        static_calls_(),
        closure_calls_(),
        instance_calls_(),
        calls_(calls) {}

  const GrowableArray<CallInfo<PolymorphicInstanceCallInstr>>& instance_calls()
      const {
    return instance_calls_;
  }

  const GrowableArray<CallInfo<StaticCallInstr>>& static_calls() const {
    return static_calls_;
  }

  const GrowableArray<CallInfo<ClosureCallInstr>>& closure_calls() const {
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

  template <typename CallType>
  static intptr_t ComputeMaxCallCount(
      const GrowableArray<CallInfo<CallType>>& calls,
      intptr_t start_index) {
    intptr_t max_count = 0;
    for (intptr_t i = start_index; i < calls.length(); ++i) {
      const auto count = calls[i].call_count;
      if (count > max_count) {
        max_count = count;
      }
    }
    return max_count;
  }

  template <typename CallType>
  static void ComputeCallRatio(GrowableArray<CallInfo<CallType>>& calls,
                               intptr_t start_index,
                               intptr_t max_count) {
    for (intptr_t i = start_index; i < calls.length(); ++i) {
      calls[i].ratio = static_cast<double>(calls[i].call_count) / max_count;
    }
  }

  // Computes the ratio for each call site in a method, defined as the
  // number of times a call site is executed over the maximum number of
  // times any call site is executed in the method. JIT uses actual call
  // counts whereas AOT uses a static estimate based on nesting depth.
  void ComputeCallSiteRatio(intptr_t static_calls_start_ix,
                            intptr_t instance_calls_start_ix,
                            intptr_t calls_start_ix) {
    intptr_t max_count = 0;
    max_count = Utils::Maximum(
        max_count,
        ComputeMaxCallCount(instance_calls_, instance_calls_start_ix));
    max_count = Utils::Maximum(
        max_count, ComputeMaxCallCount(static_calls_, static_calls_start_ix));
    max_count =
        Utils::Maximum(max_count, ComputeMaxCallCount(*calls_, calls_start_ix));

    if (max_count == 0) {
      return;
    }

    ComputeCallRatio(instance_calls_, instance_calls_start_ix, max_count);
    ComputeCallRatio(static_calls_, static_calls_start_ix, max_count);
    ComputeCallRatio(*calls_, calls_start_ix, max_count);
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
        Definition* call = nullptr;
        if (current->IsPolymorphicInstanceCall()) {
          PolymorphicInstanceCallInstr* instance_call =
              current->AsPolymorphicInstanceCall();
          target = instance_call->targets().FirstTarget().ptr();
          call = instance_call;
        } else if (current->IsStaticCall()) {
          StaticCallInstr* static_call = current->AsStaticCall();
          target = static_call->function().ptr();
          call = static_call;
        } else if (current->IsClosureCall()) {
          // TODO(srdjan): Add data for closure calls.
        }
        if (call != nullptr) {
          inlined_info->Add(
              InlinedInfo(caller, &target, depth + 1, call, "Too deep"));
        }
      }
    }
  }

  template <typename CallType>
  static void PruneRemovedCallsIn(GrowableArray<CallInfo<CallType>>* arr) {
    intptr_t j = 0;
    for (intptr_t i = 0; i < arr->length(); i++) {
      if ((*arr)[i].call->previous() != nullptr) {
        if (i != j) {
          (*arr)[j] = (*arr)[i];
        }
        j++;
      }
    }
    arr->TruncateTo(j);
  }

  // Attempt to devirtualize collected call-sites by applying Canonicalization
  // rules.
  void TryDevirtualize(FlowGraph* graph) {
    GrowableArray<Definition*> worklist(calls_->length());
    BitVector processed(graph->zone(), graph->current_ssa_temp_index());

    auto add_to_worklist = [&](Definition* defn) {
      ASSERT(defn->HasSSATemp());
      const auto ssa_index = defn->ssa_temp_index();
      if (ssa_index < processed.length() && !processed.Contains(ssa_index)) {
        processed.Add(ssa_index);
        worklist.Add(defn);
        return true;
      }
      return false;
    };

    auto add_transitive_dependencies_to_worklist = [&](intptr_t from_index) {
      // Caveat: worklist is growing as we are iterating over it. This loop
      // goes up to |worklist.length()| and thus is going to visit all newly
      // added definitions and add their dependencies to the worklist
      // transitively.
      for (intptr_t i = from_index; i < worklist.length(); i++) {
        auto defn = worklist[i];
        for (auto input : defn->inputs()) {
          add_to_worklist(input);
        }
        // For instructions with arguments we don't expect push arguments to
        // be inserted yet.
        ASSERT(defn->ArgumentCount() == 0 || !defn->HasMoveArguments());
      }
    };

    // Step 1: add all calls to worklist and then transitively add all
    // their dependencies (values that flow into inputs). Calls will
    // form the prefix of the worklist followed by their inputs.
    for (auto& call_info : *calls_) {
      // Call might not have an SSA temp assigned because its result is
      // not used. We still want to add such call to worklist but we
      // should not try to update the bitvector.
      if (call_info.call->HasSSATemp()) {
        add_to_worklist(call_info.call);
      } else {
        worklist.Add(call_info.call);
      }
    }
    RELEASE_ASSERT(worklist.length() == calls_->length());
    add_transitive_dependencies_to_worklist(0);

    // Step 2: canonicalize each definition from the worklist. We process
    // worklist backwards which means we will usually canonicalize inputs before
    // we canonicalize the instruction that uses them.
    // Note: worklist is not topologically sorted, so we might end up
    // processing some uses before the defs.
    bool changed = false;
    intptr_t last_unhandled_call_index = calls_->length() - 1;
    while (!worklist.is_empty()) {
      auto defn = worklist.RemoveLast();

      // Once we reach the prefix of the worklist we know that we are processing
      // calls we are interested in.
      CallInfo<InstanceCallInstr>* call_info = nullptr;
      if (worklist.length() == last_unhandled_call_index) {
        call_info = &(*calls_)[last_unhandled_call_index];
        RELEASE_ASSERT(call_info->call == defn);
        last_unhandled_call_index--;
      }

      auto replacement = defn->Canonicalize(graph);
      if (replacement != defn) {
        changed = true;
        if (replacement != nullptr) {
          defn->ReplaceUsesWith(replacement);
          if (replacement->ssa_temp_index() == -1) {
            graph->EnsureSSATempIndex(defn, replacement);
          }

          // Add the replacement with all of its dependencies to the worklist.
          if (add_to_worklist(replacement)) {
            add_transitive_dependencies_to_worklist(worklist.length() - 1);
          }

          // We have devirtualized |InstanceCall| into |StaticCall| check
          // inlining heuristics and add the |StaticCall| into |static_calls_|
          // if heuristics suggest inlining.
          //
          // Note: currently |InstanceCallInstr::Canonicalize| can only return
          // a newly constructed |StaticCallInstr|, so the check below is
          // redundant (it will always succeed). Nevertheless we add it to
          // catch situations in the future when canonicalization rule is
          // strengthened.
          const bool newly_inserted =
              replacement->ssa_temp_index() >= processed.length();
          if (call_info != nullptr && replacement->IsStaticCall() &&
              newly_inserted) {
            HandleDevirtualization(call_info,
                                   replacement->Cast<StaticCallInstr>());
          }
        }
        if (auto phi = defn->AsPhi()) {
          phi->UnuseAllInputs();
          phi->block()->RemovePhi(phi);
        } else {
          defn->RemoveFromGraph();
        }
      }
    }

    if (changed) {
      PruneRemovedCallsIn(&instance_calls_);
      PruneRemovedCallsIn(&static_calls_);
      PruneRemovedCallsIn(&closure_calls_);
      PruneRemovedCallsIn(calls_);
    }
  }

  void FindCallSites(FlowGraph* graph,
                     intptr_t depth,
                     GrowableArray<InlinedInfo>* inlined_info) {
    COMPILER_TIMINGS_TIMER_SCOPE(graph->thread(), FindCallSites);
    ASSERT(graph != nullptr);
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
    const bool is_aot = CompilerState::Current().is_aot();
    if (is_aot) {
      graph->GetLoopHierarchy();
    }

    const intptr_t instance_calls_start_ix = instance_calls_.length();
    const intptr_t static_calls_start_ix = static_calls_.length();
    const intptr_t calls_start_ix = calls_->length();
    for (BlockIterator block_it = graph->postorder_iterator(); !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* entry = block_it.Current();
      const intptr_t nesting_depth = entry->NestingDepth();
      for (auto current : entry->instructions()) {
        if (auto instance_call = current->AsPolymorphicInstanceCall()) {
          if (!inline_only_profitable_methods ||
              instance_call->IsSureToCallSingleRecognizedTarget() ||
              instance_call->HasOnlyDispatcherOrImplicitAccessorTargets()) {
            // Consider instance call for further inlining. Note that it will
            // still be subject to all the inlining heuristics.
            instance_calls_.Add({graph, instance_call, depth, nesting_depth});
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
        } else if (auto call = current->AsInstanceCall()) {
          calls_->Add({graph, call, depth, nesting_depth});
        } else if (auto static_call = current->AsStaticCall()) {
          HandleStaticCall(static_call, inline_only_profitable_methods, graph,
                           depth, nesting_depth, inlined_info);
        } else if (auto closure_call = current->AsClosureCall()) {
          if (!inline_only_profitable_methods) {
            // Consider closure for further inlining. Note that it will
            // still be subject to all the inlining heuristics.
            closure_calls_.Add({graph, closure_call, depth, nesting_depth});
          } else {
            // No longer consider the closure because inlining is too deep.
          }
        }
      }
    }
    ComputeCallSiteRatio(static_calls_start_ix, instance_calls_start_ix,
                         calls_start_ix);
  }

 private:
  bool HandleStaticCall(StaticCallInstr* static_call,
                        bool inline_only_profitable_methods,
                        FlowGraph* graph,
                        intptr_t depth,
                        intptr_t nesting_depth,
                        GrowableArray<InlinedInfo>* inlined_info) {
    const Function& function = static_call->function();
    if (!inline_only_profitable_methods || function.IsRecognized() ||
        function.IsDispatcherOrImplicitAccessor() ||
        function.IsMethodExtractor() ||
        (function.is_const() && function.IsGenerativeConstructor())) {
      // Consider static call for further inlining. Note that it will
      // still be subject to all the inlining heuristics.
      static_calls_.Add({graph, static_call, depth, nesting_depth});
      return true;
    } else if (inlined_info != nullptr) {
      // No longer consider the static call because inlining is too
      // deep and the method is not deemed profitable by other criteria.
      if (FLAG_print_inlining_tree) {
        const Function* caller = &graph->function();
        const Function* target = &static_call->function();
        inlined_info->Add(
            InlinedInfo(caller, target, depth + 1, static_call, "Too deep"));
      }
    }
    return false;
  }

  bool HandleDevirtualization(CallInfo<InstanceCallInstr>* call_info,
                              StaticCallInstr* static_call) {
    // Found devirtualized call and associated information.
    const bool inline_only_profitable_methods =
        (call_info->call_depth >= inlining_depth_threshold_);
    if (HandleStaticCall(static_call, inline_only_profitable_methods,
                         call_info->caller_graph, call_info->call_depth,
                         call_info->nesting_depth,
                         /*inlined_info=*/nullptr)) {
      static_calls_.Last().ratio = call_info->ratio;
      return true;
    }
    return false;
  }

  intptr_t inlining_depth_threshold_;
  GrowableArray<CallInfo<StaticCallInstr>> static_calls_;
  GrowableArray<CallInfo<ClosureCallInstr>> closure_calls_;
  GrowableArray<CallInfo<PolymorphicInstanceCallInstr>> instance_calls_;
  GrowableArray<CallInfo<InstanceCallInstr>>* calls_;

  DISALLOW_COPY_AND_ASSIGN(CallSites);
};

// Determines if inlining this graph yields a small leaf node, or a sequence of
// static calls that is no larger than the call site it will replace.
static bool IsSmallLeafOrReduction(int inlining_depth,
                                   intptr_t call_site_instructions,
                                   FlowGraph* graph) {
  intptr_t instruction_count = 0;
  intptr_t call_count = 0;
  for (BlockIterator block_it = graph->postorder_iterator(); !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* entry = block_it.Current();
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (current->IsDartReturn()) continue;
      ASSERT(!current->IsNativeReturn());
      ++instruction_count;
      if (current->IsInstanceCall() || current->IsPolymorphicInstanceCall() ||
          current->IsClosureCall()) {
        return false;
      }
      if (current->IsStaticCall()) {
        const Function& function = current->AsStaticCall()->function();
        const intptr_t inl_size = function.optimized_instruction_count();
        const bool always_inline =
            FlowGraphInliner::FunctionHasPreferInlinePragma(function);
        // Accept a static call that is always inlined in some way and add the
        // cached size to the total instruction count. A reasonable guess is
        // made if the count has not been collected yet (listed methods are
        // never very large).
        if (always_inline || function.IsRecognized()) {
          if (!always_inline) {
            const intptr_t kAvgListedMethodSize = 20;
            instruction_count +=
                (inl_size == 0 ? kAvgListedMethodSize : inl_size);
          }
        } else {
          ++call_count;
          instruction_count += current->AsStaticCall()->ArgumentCount();
          instruction_count += 1;  // pop the call frame.
        }
        continue;
      }
      if (auto check = current->AsGenericCheckBound()) {
        if (check->IsPhantom()) {
          // Discount the check since it is guaranteed to be removed.
          instruction_count -= 1;
          // TODO(dartbug.com/56902): The bound (length input) might also become
          // dead. Discount these instructions too.
        }
      }
    }
  }
  if (call_count > 0) {
    return instruction_count <= call_site_instructions;
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
        callee_graph(nullptr),
        parameter_stubs(nullptr),
        exit_collector(nullptr),
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

  TargetEntryInstr* BuildDecisionGraph();

  IsolateGroup* isolate_group() const;
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

static bool IsAThisCallThroughAnUncheckedEntryPoint(Definition* call) {
  if (auto instance_call = call->AsInstanceCallBase()) {
    return (instance_call->entry_kind() == Code::EntryKind::kUnchecked) &&
           instance_call->is_call_on_this();
  }
  return false;
}

// Helper which returns true if callee potentially has a more specific
// parameter type and thus a redefinition needs to be inserted.
static bool CalleeParameterTypeMightBeMoreSpecific(
    BitVector* is_generic_covariant_impl,
    const FunctionType& interface_target_signature,
    const FunctionType& callee_signature,
    intptr_t first_arg_index,
    intptr_t arg_index) {
  if (arg_index > first_arg_index && is_generic_covariant_impl != nullptr &&
      is_generic_covariant_impl->Contains(arg_index - first_arg_index)) {
    const intptr_t param_index = arg_index - first_arg_index;
    const intptr_t num_named_params =
        callee_signature.NumOptionalNamedParameters();
    const intptr_t num_params = callee_signature.NumParameters();
    if (num_named_params == 0 &&
        param_index >= interface_target_signature.NumParameters()) {
      // An optional positional parameter which was added in the callee but
      // not present in the interface target.
      return false;
    }

    // Check if this argument corresponds to a named parameter. In this case
    // we need to find correct index based on the name.
    intptr_t interface_target_param_index = param_index;
    if (num_named_params > 0 &&
        (num_params - num_named_params) <= param_index) {
      // This is a named parameter.
      const String& name =
          String::Handle(callee_signature.ParameterNameAt(param_index));
      interface_target_param_index = -1;
      for (intptr_t i = interface_target_signature.NumParameters() -
                        interface_target_signature.NumOptionalNamedParameters(),
                    n = interface_target_signature.NumParameters();
           i < n; i++) {
        if (interface_target_signature.ParameterNameAt(i) == name.ptr()) {
          interface_target_param_index = i;
          break;
        }
      }

      // This is a named parameter which was added in the callee.
      if (interface_target_param_index == -1) {
        return false;
      }
    }
    const AbstractType& callee_parameter_type =
        AbstractType::Handle(callee_signature.ParameterTypeAt(param_index));
    const AbstractType& interface_target_parameter_type =
        AbstractType::Handle(interface_target_signature.ParameterTypeAt(
            interface_target_param_index));
    if (interface_target_parameter_type.ptr() != callee_parameter_type.ptr()) {
      // This a conservative approximation.
      return true;
    }
  }
  return false;
}

static ConstantInstr* GetConstantInGraph(FlowGraph* graph,
                                         const ConstantInstr* instr) {
  return graph->GetConstant(instr->value(), instr->representation());
}

static void ReplaceParameterStubs(Zone* zone,
                                  FlowGraph* caller_graph,
                                  InlinedCallData* call_data,
                                  const TargetInfo* target_info) {
  const bool is_polymorphic = call_data->call->IsPolymorphicInstanceCall();
  const bool no_checks =
      IsAThisCallThroughAnUncheckedEntryPoint(call_data->call);
  ASSERT(is_polymorphic == (target_info != nullptr));
  FlowGraph* callee_graph = call_data->callee_graph;
  auto callee_entry = callee_graph->graph_entry()->normal_entry();
  const Function& callee = callee_graph->function();

  FunctionType& interface_target_signature = FunctionType::Handle();
  FunctionType& callee_signature = FunctionType::Handle(callee.signature());

  // If we are inlining a call on this and we are going to skip parameter checks
  // then a situation can arise when parameter type in the callee has a narrower
  // type than what interface target specifies, e.g.
  //
  //    class A<T> {
  //      void f(T v);
  //      void g(T v) { f(v); }
  //    }
  //    class B extends A<X> { void f(X v) { ... } }
  //
  // Consider when B.f is inlined into a callsite in A.g (e.g. due to
  // polymorphic inlining). v is known to be X within the body of B.f, but not
  // guaranteed to be X outside of it. Thus we must ensure that all operations
  // with v that depend on its type being X are pinned to stay within the
  // inlined body.
  //
  // We achieve that by inserting redefinitions for parameters which potentially
  // have narrower types in callee compared to those in the interface target of
  // the call.
  BitVector* is_generic_covariant_impl = nullptr;
  if (no_checks && callee.IsRegularFunction()) {
    const Function& interface_target =
        call_data->call->AsInstanceCallBase()->interface_target();

    callee_signature = callee.signature();
    interface_target_signature = interface_target.signature();

    // If signatures match then there is nothing to do.
    if (interface_target.signature() != callee.signature()) {
      const intptr_t num_params = callee.NumParameters();
      BitVector is_covariant(zone, num_params);
      is_generic_covariant_impl = new (zone) BitVector(zone, num_params);

      kernel::ReadParameterCovariance(callee_graph->function(), &is_covariant,
                                      is_generic_covariant_impl);
    }
  }

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
    Definition* defn = nullptr;

    // Replace the receiver argument with a redefinition to prevent code from
    // the inlined body from being hoisted above the inlined entry.
    const bool is_polymorphic_receiver =
        (is_polymorphic && (i == first_arg_index));

    if (actual == nullptr) {
      ASSERT(!is_polymorphic_receiver);
      continue;
    }

    if (is_polymorphic_receiver ||
        CalleeParameterTypeMightBeMoreSpecific(
            is_generic_covariant_impl, interface_target_signature,
            callee_signature, first_arg_index, i)) {
      RedefinitionInstr* redefinition =
          new (zone) RedefinitionInstr(actual->Copy(zone));
      caller_graph->AllocateSSAIndex(redefinition);
      if (is_polymorphic_receiver && target_info->IsSingleCid()) {
        redefinition->UpdateType(CompileType::FromCid(target_info->cid_start));
      }
      redefinition->InsertAfter(callee_entry);
      defn = redefinition;
      // Since the redefinition does not dominate the callee entry, replace
      // uses of the receiver argument in this entry with the redefined value.
      callee_entry->ReplaceInEnvironment(
          call_data->parameter_stubs->At(first_arg_stub_index + i),
          actual->definition());
    } else {
      defn = actual->definition();
    }

    call_data->parameter_stubs->At(first_arg_stub_index + i)
        ->ReplaceUsesWith(defn);
  }

  // Replace remaining constants with uses by constants in the caller's
  // initial definitions.
  auto defns = callee_graph->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < defns->length(); ++i) {
    ConstantInstr* constant = (*defns)[i]->AsConstant();
    if (constant != nullptr && constant->HasUses()) {
      constant->ReplaceUsesWith(GetConstantInGraph(caller_graph, constant));
    }
  }

  defns = callee_graph->graph_entry()->normal_entry()->initial_definitions();
  for (intptr_t i = 0; i < defns->length(); ++i) {
    auto defn = (*defns)[i];
    if (!defn->HasUses()) continue;

    if (auto constant = defn->AsConstant()) {
      constant->ReplaceUsesWith(GetConstantInGraph(caller_graph, constant));
    }

    if (auto param = defn->AsParameter()) {
      if (param->location().Equals(Location::RegisterLocation(ARGS_DESC_REG))) {
        param->ReplaceUsesWith(
            caller_graph->GetConstant(call_data->arguments_descriptor));
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
        collected_call_sites_(nullptr),
        inlining_call_sites_(nullptr),
        function_cache_(),
        inlined_info_() {}

  FlowGraph* caller_graph() const { return caller_graph_; }

  Thread* thread() const { return caller_graph_->thread(); }
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
    GrowableArray<CallSites::CallInfo<InstanceCallInstr>> calls;
    CallSites sites1(inlining_depth_threshold_, &calls);
    CallSites sites2(inlining_depth_threshold_, &calls);
    CallSites* call_sites_temp = nullptr;
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
        collected_call_sites_->TryDevirtualize(caller_graph());
        // Increment the inlining depths. Checked before subsequent inlining.
        ++inlining_depth_;
        if (inlined_recursive_call_) {
          ++inlining_recursion_depth_;
          inlined_recursive_call_ = false;
        }
        thread()->CheckForSafepoint();
      }
    }

    collected_call_sites_ = nullptr;
    inlining_call_sites_ = nullptr;
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
    if (auto* constant = argument->definition()->AsConstant()) {
      return GetConstantInGraph(graph, constant);
    }
    ParameterInstr* param = new (Z) ParameterInstr(
        graph->graph_entry(),
        /*env_index=*/i, /*param_index=*/i, Location(), kNoRepresentation);
    if (i >= 0) {
      // Compute initial parameter type using static and inferred types
      // and combine it with an argument type from the caller.
      param->UpdateType(
          *CompileType::ComputeRefinedType(param->Type(), argument->Type()));
    } else {
      // Parameter stub for function type arguments.
      // It doesn't correspond to a real parameter, so don't try to
      // query its static/inferred type.
      param->UpdateType(*argument->Type());
    }
    return param;
  }

  bool TryInlining(const Function& function,
                   const Array& argument_names,
                   InlinedCallData* call_data,
                   bool stricter_heuristic) {
    Timer timer;
    if (thread()->compiler_timings() != nullptr) {
      timer.Start();
    }
    const bool success = TryInliningImpl(function, argument_names, call_data,
                                         stricter_heuristic);
    if (thread()->compiler_timings() != nullptr) {
      timer.Stop();
      thread()->compiler_timings()->RecordInliningStatsByOutcome(success,
                                                                 timer);
    }
    return success;
  }

  bool TryInliningImpl(const Function& function,
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
      TRACE_INLINING(THR_Print(
          "     Bailout: not inlinable due to !function.CanBeInlined()\n"));
      PRINT_INLINING_TREE("Not inlinable", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    if (FlowGraphInliner::FunctionHasNeverInlinePragma(function)) {
      TRACE_INLINING(THR_Print("     Bailout: vm:never-inline pragma\n"));
      PRINT_INLINING_TREE("vm:never-inline", &call_data->caller, &function,
                          call_data->call);
      return false;
    }

    // Don't inline any intrinsified functions in precompiled mode
    // to reduce code size and make sure we use the intrinsic code.
    if (CompilerState::Current().is_aot() && function.is_intrinsic() &&
        !inliner_->AlwaysInline(function)) {
      TRACE_INLINING(THR_Print("     Bailout: intrinsic\n"));
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
    if (!CompilerState::Current().is_aot() && !function.ForceOptimize() &&
        function.ic_data_array() == Array::null()) {
      TRACE_INLINING(THR_Print("     Bailout: type feedback cleared\n"));
      PRINT_INLINING_TREE("No ICData", &call_data->caller, &function,
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

    if ((function.HasOptionalPositionalParameters() ||
         function.HasOptionalNamedParameters()) &&
        !function.AreValidArguments(function.NumTypeParameters(),
                                    arguments->length(), argument_names,
                                    nullptr)) {
      TRACE_INLINING(THR_Print("     Bailout: optional arg mismatch\n"));
      PRINT_INLINING_TREE("Optional arg mismatch", &call_data->caller,
                          &function, call_data->call);
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
        ASSERT(CompilerState::Current().is_aot() || function.ForceOptimize() ||
               function.ic_data_array() != Array::null());
        function.RestoreICDataMap(ic_data_array, clone_ic_data);

        // Parse the callee function.
        bool in_cache;
        ParsedFunction* parsed_function =
            GetParsedFunction(function, &in_cache);

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
        } else if (call_data->call->IsClosureCall()) {
          // Closure functions only have one entry point.
        }
        // context_level_array=nullptr below means we are not building var desc.
        kernel::FlowGraphBuilder builder(
            parsed_function, ic_data_array, /*context_level_array=*/nullptr,
            exit_collector,
            /*optimized=*/true, Compiler::kNoOSRDeoptId,
            caller_graph_->max_block_id() + 1,
            entry_kind == Code::EntryKind::kUnchecked, &call_data->caller);
        {
          COMPILER_TIMINGS_TIMER_SCOPE(thread(), BuildGraph);
          callee_graph = builder.BuildGraph();
          // Make sure SSA temp indices in the callee graph
          // do not intersect with SSA temp indices in the caller.
          ASSERT(callee_graph->current_ssa_temp_index() == 0);
          callee_graph->set_current_ssa_temp_index(
              caller_graph_->current_ssa_temp_index());
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

        {
          COMPILER_TIMINGS_TIMER_SCOPE(thread(), PopulateWithICData);

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
          if (CompilerState::Current().is_aot()) {
            callee_graph->PopulateWithICData(parsed_function->function());
          }
#endif

          // If we inline a function which is intrinsified without a
          // fall-through to IR code, we will not have any ICData attached, so
          // we do it manually here.
          if (!CompilerState::Current().is_aot() && function.is_intrinsic()) {
            callee_graph->PopulateWithICData(parsed_function->function());
          }
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
          COMPILER_TIMINGS_TIMER_SCOPE(thread(), ComputeSSA);
          callee_graph->ComputeSSA(param_stubs);
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
        {
          COMPILER_TIMINGS_TIMER_SCOPE(thread(), MakeInliningDecision);
          InliningDecision decision =
              ShouldWeInline(function, instruction_count, call_site_count);
          if (!decision.value) {
            // If size is larger than all thresholds, don't consider it again.

            // TODO(dartbug.com/49665): Make compiler smart enough so it itself
            // can identify highly-specialized functions that should always
            // be considered for inlining, without relying on a pragma.
            if ((instruction_count > FLAG_inlining_size_threshold) &&
                (call_site_count > FLAG_inlining_callee_call_sites_threshold)) {
              // Will keep trying to inline the function if it can be
              // specialized based on argument types.
              if (!FlowGraphInliner::FunctionHasAlwaysConsiderInliningPragma(
                      function)) {
                function.set_is_inlinable(false);
                TRACE_INLINING(THR_Print("     Mark not inlinable\n"));
              }
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

          // If requested, a stricter heuristic is applied to this inlining.
          // This heuristic always scans the method (rather than possibly
          // reusing cached results) to make sure all specializations are
          // accounted for.
          // TODO(ajcbik): with the now better bookkeeping, explore removing
          // this
          if (stricter_heuristic) {
            intptr_t call_site_instructions = 0;
            if (auto static_call = call->AsStaticCall()) {
              // Push all the arguments, do the call, drop arguments.
              call_site_instructions = static_call->ArgumentCount() + 1 + 1;
            }
            if (!IsSmallLeafOrReduction(inlining_depth_, call_site_instructions,
                                        callee_graph)) {
              TRACE_INLINING(
                  THR_Print("     Bailout: heuristics (no small leaf)\n"));
              PRINT_INLINING_TREE("Heuristic fail (no small leaf)",
                                  &call_data->caller, &function,
                                  call_data->call);
              return false;
            }
          }
        }

        // Inline dispatcher methods regardless of the current depth.
        {
          const intptr_t depth =
              function.IsDispatcherOrImplicitAccessor() ? 0 : inlining_depth_;
          collected_call_sites_->FindCallSites(callee_graph, depth,
                                               &inlined_info_);
        }

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
        const FieldSet* callee_guarded_fields =
            callee_graph->parsed_function().guarded_fields();
        FieldSet::Iterator it = callee_guarded_fields->GetIterator();
        while (const Field** field = it.Next()) {
          caller_graph()->parsed_function().AddToGuardedFields(*field);
        }

        {
          COMPILER_TIMINGS_TIMER_SCOPE(thread(), SetInliningId);
          FlowGraphInliner::SetInliningId(
              callee_graph, inliner_->NextInlineId(callee_graph->function(),
                                                   call_data->call->source()));
        }
        TRACE_INLINING(THR_Print("     Success\n"));
        TRACE_INLINING(THR_Print(
            "       with reason %s, code size %" Pd ", call sites: %" Pd "\n",
            decision.reason, instruction_count, call_site_count));
        PRINT_INLINING_TREE(nullptr, &call_data->caller, &function, call);
        return true;
      } else {
        error = thread()->StealStickyError();

        if (error.IsLanguageError() &&
            (LanguageError::Cast(error).kind() == Report::kBailout)) {
          if (error.ptr() == Object::background_compilation_error().ptr()) {
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
           (error.ptr() == Object::out_of_memory_error().ptr()) ||
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
    // Prevent duplicate printing as inlined_info aggregates all inlining.
    GrowableArray<intptr_t> call_instructions_printed;
    // Print those that were inlined.
    for (intptr_t i = 0; i < inlined_info_.length(); i++) {
      const InlinedInfo& info = inlined_info_[i];
      if (info.bailout_reason != nullptr) {
        continue;
      }
      if ((info.inlined_depth == depth) &&
          (info.caller->ptr() == caller.ptr()) &&
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
      if (info.bailout_reason == nullptr) {
        continue;
      }
      if ((info.inlined_depth == depth) &&
          (info.caller->ptr() == caller.ptr()) &&
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
    COMPILER_TIMINGS_TIMER_SCOPE(thread(), InlineCall);
    FlowGraph* callee_graph = call_data->callee_graph;
    auto callee_function_entry = callee_graph->graph_entry()->normal_entry();

    // Plug result in the caller graph.
    InlineExitCollector* exit_collector = call_data->exit_collector;
    exit_collector->PrepareGraphs(callee_graph);
    ReplaceParameterStubs(zone(), caller_graph_, call_data, nullptr);

    // Inlined force-optimized idempotent functions get deopt-id and
    // environment from the call, so when deoptimized, the call is repeated.
    if (callee_graph->function().ForceOptimize()) {
      // We should only reach here if `Function::CanBeInlined()` returned true,
      // which only happens if the force-optimized function is idempotent.
      ASSERT(CompilerState::Current().is_aot() ||
             callee_graph->function().IsIdempotent());
      for (BlockIterator block_it = callee_graph->postorder_iterator();
           !block_it.Done(); block_it.Advance()) {
        for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
             it.Advance()) {
          Instruction* current = it.Current();
          if (current->env() != nullptr) {
            call_data->call->env()->DeepCopyTo(zone(), current);
            current->CopyDeoptIdFrom(*call_data->call);
            current->env()->MarkAsLazyDeoptToBeforeDeoptId();
          }
        }
      }
    }
    exit_collector->ReplaceCall(callee_function_entry);

    ASSERT(!call_data->call->HasMoveArguments());
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
      if (parsed_function->function().ptr() == function.ptr()) {
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
    const auto& call_info = inlining_call_sites_->static_calls();
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
    const auto& call_info = inlining_call_sites_->closure_calls();
    TRACE_INLINING(
        THR_Print("  Closure Calls (%" Pd ")\n", call_info.length()));
    for (intptr_t call_idx = 0; call_idx < call_info.length(); ++call_idx) {
      ClosureCallInstr* call = call_info[call_idx].call;
      // Find the closure of the callee.
      ASSERT(call->ArgumentCount() > 0);
      Function& target = Function::ZoneHandle(call->target_function().ptr());
      if (target.IsNull()) {
        Definition* receiver =
            call->Receiver()->definition()->OriginalDefinition();
        if (const auto* alloc = receiver->AsAllocateClosure()) {
          target = alloc->known_function().ptr();
        } else if (ConstantInstr* constant = receiver->AsConstant()) {
          if (constant->value().IsClosure()) {
            target = Closure::Cast(constant->value()).function();
          }
        }
      }

      if (target.IsNull()) {
        TRACE_INLINING(THR_Print("     Bailout: unknown target\n"));
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
    const auto& call_info = inlining_call_sites_->instance_calls();
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
    intptr_t argument_names_count =
        (argument_names.IsNull()) ? 0 : argument_names.Length();
    ASSERT(fixed_param_count <= arg_count - first_arg_index);
    ASSERT(arg_count - first_arg_index <= param_count);

    if (function.HasOptionalPositionalParameters()) {
      // Arguments mismatch: Caller supplied unsupported named argument.
      ASSERT(argument_names_count == 0);
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
        ConstantInstr* constant = callee_graph->GetConstant(object);
        arguments->Add(nullptr);
        param_stubs->Add(constant);
      }
      return true;
    }

    ASSERT(function.HasOptionalNamedParameters());

    const intptr_t positional_args =
        arg_count - first_arg_index - argument_names_count;
    // Arguments mismatch: Caller supplied unsupported positional argument.
    ASSERT(positional_args == fixed_param_count);

    // Fast path when no optional named parameters are given.
    if (argument_names_count == 0) {
      for (intptr_t i = 0; i < param_count - fixed_param_count; ++i) {
        const Instance& object = parsed_function.DefaultParameterValueAt(i);
        ConstantInstr* constant = callee_graph->GetConstant(object);
        arguments->Add(nullptr);
        param_stubs->Add(constant);
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
      Value* arg = nullptr;
      for (intptr_t j = 0; j < named_args.length(); ++j) {
        if (param_name.Equals(*named_args[j].name)) {
          arg = named_args[j].value;
          match_count++;
          break;
        }
      }
      arguments->Add(arg);
      // Create a stub for the argument or use the parameter's default value.
      if (arg != nullptr) {
        param_stubs->Add(CreateParameterStub(i, arg, callee_graph));
      } else {
        const Instance& object =
            parsed_function.DefaultParameterValueAt(i - fixed_param_count);
        ConstantInstr* constant = callee_graph->GetConstant(object);
        param_stubs->Add(constant);
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
      non_inlined_variants_(new(zone()) CallTargets(zone())),
      inlined_entries_(num_variants_),
      exit_collector_(new(Z) InlineExitCollector(owner->caller_graph(), call)),
      caller_function_(caller_function) {}

IsolateGroup* PolymorphicInliner::isolate_group() const {
  return owner_->caller_graph()->isolate_group();
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
    if ((target.ptr() == inlined_variants_.TargetAt(i)->target->ptr()) &&
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
    if (target.ptr() == non_inlined_variants_->TargetAt(i)->target->ptr()) {
      return true;
    }
  }

  return false;
}

bool PolymorphicInliner::TryInliningPoly(const TargetInfo& target_info) {
  GrowableArray<Value*> arguments(call_->ArgumentCount());
  for (int i = 0; i < call_->ArgumentCount(); ++i) {
    arguments.Add(call_->ArgumentValueAt(i));
  }
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, call_->GetArgumentsDescriptor());
  InlinedCallData call_data(call_, arguments_descriptor, call_->FirstArgIndex(),
                            &arguments, caller_function_);
  Function& target = Function::ZoneHandle(zone(), target_info.target->ptr());
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

// Build a DAG to dispatch to the inlined function bodies.  Load the class
// id of the receiver and make explicit comparisons for each inlined body,
// in frequency order.  If all variants are inlined, the entry to the last
// inlined body is guarded by a CheckClassId instruction which can deopt.
// If not all variants are inlined, we add a PolymorphicInstanceCall
// instruction to handle the non-inlined variants.
TargetEntryInstr* PolymorphicInliner::BuildDecisionGraph() {
  COMPILER_TIMINGS_TIMER_SCOPE(owner_->thread(), BuildDecisionGraph);
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
  // Redefinition and CheckClassId assume kTagged.
  Representation cid_representation =
      call_->complete() ? kUnboxedUword : kTagged;
  LoadClassIdInstr* load_cid =
      new (Z) LoadClassIdInstr(new (Z) Value(receiver), cid_representation);
  owner_->caller_graph()->AllocateSSAIndex(load_cid);
  cursor = AppendInstruction(cursor, load_cid);
  for (intptr_t i = 0; i < inlined_variants_.length(); ++i) {
    const CidRange& variant = inlined_variants_[i];
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
        owner_->caller_graph()->AllocateSSAIndex(cid_redefinition);
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
        ASSERT(join->dominator() != nullptr);
        GotoInstr* goto_join = new GotoInstr(join, DeoptId::kNone);
        goto_join->InheritDeoptTarget(zone(), join);
        cursor->LinkTo(goto_join);
        current_block->set_last_instruction(goto_join);
      } else {
        // There is no possibility of a TargetEntry (the first entry to a
        // shared inlined body) because this is the last inlined entry.
        UNREACHABLE();
      }
      cursor = nullptr;
    } else {
      // For all variants except the last, use a branch on the loaded class
      // id.
      BlockEntryInstr* cid_test_entry_block = current_block;
      ConditionInstr* condition;
      if (variant.cid_start == variant.cid_end) {
        ConstantInstr* cid_constant = owner_->caller_graph()->GetConstant(
            Smi::ZoneHandle(Smi::New(variant.cid_end)), cid_representation);
        condition = new EqualityCompareInstr(
            call_->source(), Token::kEQ, new Value(load_cid),
            new Value(cid_constant), cid_representation, DeoptId::kNone,
            /*null_aware=*/false);
      } else {
        condition = new TestRangeInstr(call_->source(), new Value(load_cid),
                                       variant.cid_start, variant.cid_end,
                                       cid_representation);
      }
      BranchInstr* branch = new BranchInstr(condition, DeoptId::kNone);

      branch->InheritDeoptTarget(zone(), call_);
      AppendInstruction(cursor, branch);
      cursor = nullptr;
      current_block->set_last_instruction(branch);

      // 2. Handle a match by linking to the inlined body.  There are three
      // cases (unshared, shared first predecessor, and shared subsequent
      // predecessors).
      BlockEntryInstr* callee_entry = inlined_entries_[i];
      TargetEntryInstr* true_target = nullptr;
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
        ASSERT(join != nullptr);
        ASSERT(join->dominator() != nullptr);
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
    }
  }

  ASSERT(!call_->HasMoveArguments());

  // Handle any non-inlined variants.
  if (!non_inlined_variants_->is_empty()) {
    PolymorphicInstanceCallInstr* fallback_call =
        PolymorphicInstanceCallInstr::FromCall(Z, call_, *non_inlined_variants_,
                                               call_->complete());
    owner_->caller_graph()->AllocateSSAIndex(fallback_call);
    fallback_call->InheritDeoptTarget(zone(), call_);
    fallback_call->set_total_call_count(call_->CallCount());
    DartReturnInstr* fallback_return = new DartReturnInstr(
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
  COMPILER_TIMINGS_TIMER_SCOPE(flow_graph->thread(), CollectGraphInfo);
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
  return (function.name() == Symbols::IndexToken().ptr()) ||
         (function.name() == Symbols::AssignIndexToken().ptr()) ||
         (function.name() == Symbols::Plus().ptr()) ||
         (function.name() == Symbols::Minus().ptr());
}

bool FlowGraphInliner::FunctionHasPreferInlinePragma(const Function& function) {
  if (!function.has_pragma()) {
    return false;
  }
  Thread* thread = dart::Thread::Current();
  COMPILER_TIMINGS_TIMER_SCOPE(thread, CheckForPragma);
  Object& options = Object::Handle();
  return Library::FindPragma(thread, /*only_core=*/false, function,
                             Symbols::vm_prefer_inline(),
                             /*multiple=*/false, &options);
}

bool FlowGraphInliner::FunctionHasNeverInlinePragma(const Function& function) {
  if (!function.has_pragma()) {
    return false;
  }
  Thread* thread = dart::Thread::Current();
  COMPILER_TIMINGS_TIMER_SCOPE(thread, CheckForPragma);
  Object& options = Object::Handle();
  return Library::FindPragma(thread, /*only_core=*/false, function,
                             Symbols::vm_never_inline(),
                             /*multiple=*/false, &options);
}

bool FlowGraphInliner::FunctionHasAlwaysConsiderInliningPragma(
    const Function& function) {
  if (!function.has_pragma()) {
    return false;
  }
  Thread* thread = dart::Thread::Current();
  COMPILER_TIMINGS_TIMER_SCOPE(thread, CheckForPragma);
  Object& options = Object::Handle();
  return Library::FindPragma(thread, /*only_core=*/false, function,
                             Symbols::vm_always_consider_inlining(),
                             /*multiple=*/false, &options);
}

bool FlowGraphInliner::AlwaysInline(const Function& function) {
  if (FunctionHasPreferInlinePragma(function)) {
    TRACE_INLINING(
        THR_Print("vm:prefer-inline pragma for %s\n", function.ToCString()));
    return true;
  }

  COMPILER_TIMINGS_TIMER_SCOPE(dart::Thread::Current(), MakeInliningDecision);
  // We don't want to inline DIFs for recognized methods because we would rather
  // replace them with inline FG before inlining introduces any superfluous
  // AssertAssignable instructions.
  if (function.IsDispatcherOrImplicitAccessor() &&
      !(function.kind() == UntaggedFunction::kDynamicInvocationForwarder &&
        function.IsRecognized())) {
    // Smaller or same size as the call.
    return true;
  }

  if (function.is_const()) {
    // Inlined const fields are smaller than a call.
    return true;
  }

  if (function.IsMethodExtractor()) {
    // Tear-off closure allocation has about the same size as the call.
    return true;
  }

  if (function.IsGetterFunction() || function.IsSetterFunction() ||
      IsInlineableOperator(function) ||
      (function.kind() == UntaggedFunction::kConstructor)) {
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
  if ((FLAG_inlining_filter != nullptr) &&
      (strstr(top.ToFullyQualifiedCString(), FLAG_inlining_filter) ==
       nullptr)) {
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
  ASSERT(FunctionType::Handle(function.signature()).IsFinalized());
  inline_id_to_function_->Add(&function);
  inline_id_to_token_pos_->Add(source.token_pos);
  caller_inline_id_->Add(source.inlining_id);
  // We always have one less token position than functions.
  ASSERT(inline_id_to_token_pos_->length() ==
         (inline_id_to_function_->length() - 1));
  return id;
}

}  // namespace dart
