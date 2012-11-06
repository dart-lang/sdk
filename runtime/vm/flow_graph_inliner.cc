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
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(bool, trace_inlining, false, "Trace inlining");
DEFINE_FLAG(charp, inlining_filter, NULL, "Inline only in named function");

// Flags for inlining heuristics.
DEFINE_FLAG(int, inlining_depth_threshold, 3,
    "Inline function calls up to threshold nesting depth");
DEFINE_FLAG(int, inlining_size_threshold, 20,
    "Always inline functions that have threshold or fewer instructions");
DEFINE_FLAG(int, inlining_in_loop_size_threshold, 80,
    "Inline functions in loops that have threshold or fewer instructions");
DEFINE_FLAG(int, inlining_callee_call_sites_threshold, 1,
    "Always inline functions containing threshold or fewer calls.");
DEFINE_FLAG(int, inlining_constant_arguments_count, 1,
    "Inline function calls with sufficient constant arguments "
    "and up to the increased threshold on instructions");
DEFINE_FLAG(int, inlining_constant_arguments_size_threshold, 60,
    "Inline function calls with sufficient constant arguments "
    "and up to the increased threshold on instructions");

DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(int, deoptimization_counter_threshold);
DECLARE_FLAG(bool, verify_compiler);
DECLARE_FLAG(bool, compiler_stats);

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


// TODO(zerny): Remove the ChildrenVisitor and SourceLabelResetter once we have
// moved the label/join map for control flow out of the AST and into the flow
// graph builder.

// Default visitor to traverse child nodes.
class ChildrenVisitor : public AstNodeVisitor {
 public:
  ChildrenVisitor() { }
#define DEFINE_VISIT(type, name)                                               \
  virtual void Visit##type(type* node) { node->VisitChildren(this); }
  NODE_LIST(DEFINE_VISIT);
#undef DEFINE_VISIT
};


// Visitor to clear each AST node containing source labels.
class SourceLabelResetter : public ChildrenVisitor {
 public:
  SourceLabelResetter() { }
  virtual void VisitSequenceNode(SequenceNode* node) {
    Reset(node, node->label());
  }
  virtual void VisitCaseNode(CaseNode* node) {
    Reset(node, node->label());
  }
  virtual void VisitSwitchNode(SwitchNode* node) {
    Reset(node, node->label());
  }
  virtual void VisitWhileNode(WhileNode* node) {
    Reset(node, node->label());
  }
  virtual void VisitDoWhileNode(DoWhileNode* node) {
    Reset(node, node->label());
  }
  virtual void VisitForNode(ForNode* node) {
    Reset(node, node->label());
  }
  virtual void VisitJumpNode(JumpNode* node) {
    Reset(node, node->label());
  }
  void Reset(AstNode* node, SourceLabel* lbl) {
    node->VisitChildren(this);
    if (lbl == NULL) return;
    lbl->join_for_break_ = NULL;
    lbl->join_for_continue_ = NULL;
  }
};


// Helper to create a parameter stub from an actual argument.
static Definition* CreateParameterStub(intptr_t i,
                                       Value* argument,
                                       FlowGraph* graph) {
  ConstantInstr* constant = argument->definition()->AsConstant();
  if (constant != NULL) {
    return new ConstantInstr(constant->value());
  } else {
    return new ParameterInstr(i, graph->graph_entry());
  }
}


// Helper to get the default value of a formal parameter.
static ConstantInstr* GetDefaultValue(intptr_t i,
                                      const ParsedFunction& parsed_function) {
  return new ConstantInstr(Object::ZoneHandle(
      parsed_function.default_parameter_values().At(i)));
}


// Pair of an argument name and its value.
struct NamedArgument : ValueObject {
 public:
  String* name;
  Value* value;
  NamedArgument(String* name, Value* value)
    : name(name), value(value) { }
};


// Helper to collect information about a callee graph when considering it for
// inlining.
class GraphInfoCollector : public ValueObject {
 public:
  GraphInfoCollector()
      : call_site_count_(0),
        instruction_count_(0) { }

  void Collect(const FlowGraph& graph) {
    call_site_count_ = 0;
    instruction_count_ = 0;
    for (BlockIterator block_it = graph.postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      for (ForwardInstructionIterator it(block_it.Current());
           !it.Done();
           it.Advance()) {
        ++instruction_count_;
        if (it.Current()->IsStaticCall() ||
            it.Current()->IsClosureCall() ||
            it.Current()->IsPolymorphicInstanceCall()) {
          ++call_site_count_;
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


// A collection of call sites to consider for inlining.
class CallSites : public FlowGraphVisitor {
 public:
  CallSites(FlowGraph* flow_graph,
            const GrowableArray<intptr_t>& skip_static_call_deopt_ids)
      : FlowGraphVisitor(flow_graph->postorder()),  // We don't use this order.
        static_calls_(),
        closure_calls_(),
        instance_calls_(),
        skip_static_call_deopt_ids_(skip_static_call_deopt_ids) { }

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
    if (!call->function().IsInlineable()) return;
    const intptr_t call_deopt_id = call->deopt_id();
    for (intptr_t i = 0; i < skip_static_call_deopt_ids_.length(); i++) {
      if (call_deopt_id == skip_static_call_deopt_ids_[i]) {
        // Do not inline this call.
        return;
      }
    }
    static_calls_.Add(call);
  }

 private:
  GrowableArray<StaticCallInstr*> static_calls_;
  GrowableArray<ClosureCallInstr*> closure_calls_;
  GrowableArray<PolymorphicInstanceCallInstr*> instance_calls_;
  const GrowableArray<intptr_t>& skip_static_call_deopt_ids_;

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
        inlining_call_sites_(NULL),
        function_cache_() { }

  // Inlining heuristics based on Cooper et al. 2008.
  bool ShouldWeInline(intptr_t loop_depth,
                      intptr_t instr_count,
                      intptr_t call_site_count,
                      intptr_t const_arg_count) {
    if (instr_count <= FLAG_inlining_size_threshold) {
      return true;
    }
    if (call_site_count <= FLAG_inlining_callee_call_sites_threshold) {
      return true;
    }
    if ((loop_depth > 0) &&
        (instr_count <= FLAG_inlining_in_loop_size_threshold)) {
      return true;
    }
    if ((const_arg_count >= FLAG_inlining_constant_arguments_count) &&
        (instr_count <= FLAG_inlining_constant_arguments_size_threshold)) {
      return true;
    }
    return false;
  }

  // TODO(srdjan): Handle large 'skip_static_call_deopt_ids'. Currently
  // max. size observed is 11 (dart2js).
  void InlineCalls(const GrowableArray<intptr_t>& skip_static_call_deopt_ids) {
    // If inlining depth is less then one abort.
    if (FLAG_inlining_depth_threshold < 1) return;
    // Create two call site collections to swap between.
    CallSites sites1(caller_graph_, skip_static_call_deopt_ids);
    CallSites sites2(caller_graph_, skip_static_call_deopt_ids);
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
                   const Array& argument_names,
                   GrowableArray<Value*>* arguments,
                   Definition* call) {
    TRACE_INLINING(OS::Print("  => %s (deopt count %d)\n",
                             function.ToCString(),
                             function.deoptimization_counter()));

    // Abort if the inlinable bit on the function is low.
    if (!function.IsInlineable()) {
      TRACE_INLINING(OS::Print("     Bailout: not inlinable\n"));
      return false;
    }

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
      bool in_cache;
      ParsedFunction* parsed_function;
      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphinliner_parse_timer,
                         isolate);
        parsed_function = GetParsedFunction(function, &in_cache);
      }

      // Load IC data for the callee.
      if (function.HasCode()) {
        const Code& unoptimized_code =
            Code::Handle(function.unoptimized_code());
        isolate->set_ic_data_array(unoptimized_code.ExtractTypeFeedbackArray());
      }

      // Build the callee graph.
      const intptr_t loop_depth = call->GetBlock()->loop_depth();
      FlowGraphBuilder builder(*parsed_function);
      builder.SetInitialBlockId(caller_graph_->max_block_id());
      FlowGraph* callee_graph;
      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphinliner_build_timer,
                         isolate);
        callee_graph =
            builder.BuildGraph(FlowGraphBuilder::kValueContext, loop_depth);
      }

      // The parameter stubs are a copy of the actual arguments providing
      // concrete information about the values, for example constant values,
      // without linking between the caller and callee graphs.
      // TODO(zerny): Put more information in the stubs, eg, type information.
      GrowableArray<Definition*> param_stubs(function.NumParameters());

      // Create a parameter stub for each fixed positional parameter.
      for (intptr_t i = 0; i < function.num_fixed_parameters(); ++i) {
        param_stubs.Add(CreateParameterStub(i, (*arguments)[i], callee_graph));
      }

      // If the callee has optional parameters, rebuild the argument and stub
      // arrays so that actual arguments are in one-to-one with the formal
      // parameters.
      if (function.HasOptionalParameters()) {
        TRACE_INLINING(OS::Print("     adjusting for optional parameters\n"));
        AdjustForOptionalParameters(*parsed_function,
                                    argument_names,
                                    arguments,
                                    &param_stubs,
                                    callee_graph);
        // Add a bogus parameter at the end for the (unused) argument descriptor
        // slot. The parser allocates an extra slot between locals and
        // parameters to hold the argument descriptor in case it escapes.  We
        // currently bailout if there are argument test expressions or escaping
        // variables so this parameter and the stack slot are not used.
        if (parsed_function->GetSavedArgumentsDescriptorVar() != NULL) {
          param_stubs.Add(new ParameterInstr(
              function.NumParameters(), callee_graph->graph_entry()));
        }
      }

      // After treating optional parameters the actual/formal count must match.
      ASSERT(arguments->length() == function.NumParameters());
      ASSERT(param_stubs.length() == callee_graph->parameter_count());

      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphinliner_ssa_timer,
                         isolate);
        // Compute SSA on the callee graph, catching bailouts.
        callee_graph->ComputeSSA(next_ssa_temp_index_, &param_stubs);
        callee_graph->ComputeUseLists();
      }

      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphinliner_opt_timer,
                         isolate);
        // TODO(zerny): Do more optimization passes on the callee graph.
        FlowGraphOptimizer optimizer(callee_graph);
        optimizer.ApplyICData();
        callee_graph->ComputeUseLists();
      }

      if (FLAG_trace_inlining && FLAG_print_flow_graph) {
        OS::Print("Callee graph for inlining %s\n",
                  function.ToFullyQualifiedCString());
        FlowGraphPrinter printer(*callee_graph);
        printer.PrintBlocks();
      }

      // Collect information about the call site and caller graph.
      // TODO(zerny): Do this after CP and dead code elimination.
      intptr_t constants_count = 0;
      for (intptr_t i = 0; i < param_stubs.length(); ++i) {
        if (param_stubs[i]->IsConstant()) ++constants_count;
      }
      GraphInfoCollector info;
      info.Collect(*callee_graph);
      const intptr_t size = info.instruction_count();
      // Use heuristics do decide if this call should be inlined.
      if (!ShouldWeInline(loop_depth,
                          size,
                          info.call_site_count(),
                          constants_count)) {
        // If size is larger than all thresholds, don't consider it again.
        if ((size > FLAG_inlining_size_threshold) &&
            (size > FLAG_inlining_in_loop_size_threshold) &&
            (size > FLAG_inlining_callee_call_sites_threshold) &&
            (size > FLAG_inlining_constant_arguments_size_threshold)) {
          function.set_is_inlinable(false);
        }
        isolate->set_long_jump_base(base);
        isolate->set_deopt_id(prev_deopt_id);
        isolate->set_ic_data_array(prev_ic_data.raw());
        TRACE_INLINING(OS::Print("     Bailout: heuristics with "
                                 "loop depth: %"Pd", "
                                 "code size:  %"Pd", "
                                 "call sites: %"Pd", "
                                 "const args: %"Pd"\n",
                                 loop_depth,
                                 size,
                                 info.call_site_count(),
                                 constants_count));
        return false;
      }

      // If depth is less or equal to threshold recursively add call sites.
      if (inlining_depth_ < FLAG_inlining_depth_threshold) {
        collected_call_sites_->FindCallSites(callee_graph);
      }

      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphinliner_subst_timer,
                         isolate);

        // Plug result in the caller graph.
        caller_graph_->InlineCall(call, callee_graph);
        next_ssa_temp_index_ = caller_graph_->max_virtual_register_number();

        // Remove push arguments of the call.
        for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
          PushArgumentInstr* push = call->ArgumentAt(i);
          push->ReplaceUsesWith(push->value()->definition());
          push->RemoveFromGraph();
        }

        // Replace each stub with the actual argument or the caller's constant.
        // Nulls denote optional parameters for which no actual was given.
        for (intptr_t i = 0; i < arguments->length(); ++i) {
          Definition* stub = param_stubs[i];
          Value* actual = (*arguments)[i];
          if (actual != NULL) stub->ReplaceUsesWith(actual->definition());
        }

        // Replace remaining constants with uses by constants in the caller's
        // initial definitions.
        GrowableArray<Definition*>* defns =
            callee_graph->graph_entry()->initial_definitions();
        for (intptr_t i = 0; i < defns->length(); ++i) {
          ConstantInstr* constant = (*defns)[i]->AsConstant();
          if (constant == NULL ||
              ((constant->input_use_list() == NULL) &&
               (constant->env_use_list() == NULL))) {
            continue;
          }
          constant->ReplaceUsesWith(
            caller_graph_->AddConstantToInitialDefinitions(constant->value()));
        }
      }

      TRACE_INLINING(OS::Print("     Success\n"));

      // Add the function to the cache.
      if (!in_cache) function_cache_.Add(parsed_function);

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

  // Parse a function reusing the cache if possible.
  ParsedFunction* GetParsedFunction(const Function& function, bool* in_cache) {
    // TODO(zerny): Use a hash map for the cache.
    for (intptr_t i = 0; i < function_cache_.length(); ++i) {
      ParsedFunction* parsed_function = function_cache_[i];
      if (parsed_function->function().raw() == function.raw()) {
        *in_cache = true;
        SourceLabelResetter reset;
        parsed_function->node_sequence()->Visit(&reset);
        return parsed_function;
      }
    }
    *in_cache = false;
    ParsedFunction* parsed_function = new ParsedFunction(function);
    Parser::ParseFunction(parsed_function);
    parsed_function->AllocateVariables();
    return parsed_function;
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
      TryInlining(call->function(), call->argument_names(), &arguments, call);
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
      TryInlining(closure->function(),
                  call->argument_names(),
                  &arguments,
                  call);
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
        TRACE_INLINING(OS::Print(
          "  => %s (deopt count %d)\n     Bailout: %"Pd" checks\n",
          target.ToCString(),
          target.deoptimization_counter(),
          ic_data.NumberOfChecks()));
        continue;
      }
      GrowableArray<Value*> arguments(instr->ArgumentCount());
      for (int i = 0; i < instr->ArgumentCount(); ++i) {
        arguments.Add(instr->ArgumentAt(i)->value());
      }
      TryInlining(target,
                  instr->instance_call()->argument_names(),
                  &arguments,
                  instr);
    }
  }

  void AdjustForOptionalParameters(const ParsedFunction& parsed_function,
                                   const Array& argument_names,
                                   GrowableArray<Value*>* arguments,
                                   GrowableArray<Definition*>* param_stubs,
                                   FlowGraph* callee_graph) {
    const Function& function = parsed_function.function();
    // The language and this code does not support both optional positional
    // and optional named parameters for the same function.
    ASSERT(!function.HasOptionalPositionalParameters() ||
           !function.HasOptionalNamedParameters());

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
        const Object& object =
            Object::ZoneHandle(
                parsed_function.default_parameter_values().At(
                    i - fixed_param_count));
        ConstantInstr* constant = new ConstantInstr(object);
        arguments->Add(NULL);
        param_stubs->Add(constant);
      }
      return;
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
      return;
    }

    // Otherwise, build a collection of name/argument pairs.
    GrowableArray<NamedArgument> named_args(argument_names_count);
    for (intptr_t i = 0; i < argument_names.Length(); ++i) {
      String& arg_name = String::Handle(Isolate::Current());
      arg_name ^= argument_names.At(i);
      named_args.Add(
          NamedArgument(&arg_name, (*arguments)[i + fixed_param_count]));
    }

    // Truncate the arguments array to just fixed parameters.
    arguments->TruncateTo(fixed_param_count);

    // For each optional named parameter, add the actual argument or its
    // default if no argument is passed.
    for (intptr_t i = fixed_param_count; i < param_count; ++i) {
      String& param_name = String::Handle(function.ParameterNameAt(i));
      // Search for and add the named argument.
      Value* arg = NULL;
      for (intptr_t j = 0; j < named_args.length(); ++j) {
        if (param_name.Equals(*named_args[j].name)) {
          arg = named_args[j].value;
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
  }


  FlowGraph* caller_graph_;
  intptr_t next_ssa_temp_index_;
  bool inlined_;
  intptr_t initial_size_;
  intptr_t inlined_size_;
  intptr_t inlining_depth_;
  CallSites* collected_call_sites_;
  CallSites* inlining_call_sites_;
  GrowableArray<ParsedFunction*> function_cache_;

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
  inliner.InlineCalls(uncalled_static_static_call_deopt_ids_);

  if (inliner.inlined()) {
    flow_graph_->RepairGraphAfterInlining();
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
