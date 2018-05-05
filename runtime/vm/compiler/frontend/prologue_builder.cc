// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/prologue_builder.h"

#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/frontend/kernel_binary_flowgraph.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/kernel_loader.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {
namespace kernel {

#define Z (zone_)

BlockEntryInstr* PrologueBuilder::BuildPrologue(BlockEntryInstr* entry,
                                                PrologueInfo* prologue_info) {
  Isolate* isolate = Isolate::Current();
  const bool strong = isolate->strong();

  // We always have to build the graph, but we only link it sometimes.
  const bool link = !is_inlining_ && !compiling_for_osr_;

  const intptr_t previous_block_id = last_used_block_id_;

  const bool load_optional_arguments = function_.HasOptionalParameters();
  const bool expect_type_args =
      function_.IsGeneric() && isolate->reify_generic_functions();
  const bool check_arguments =
      (function_.IsClosureFunction() || function_.IsConvertedClosureFunction());

  Fragment prologue = Fragment(entry);
  JoinEntryInstr* nsm = NULL;
  if (load_optional_arguments || check_arguments || expect_type_args) {
    nsm = BuildThrowNoSuchMethod();
  }
  if (check_arguments) {
    Fragment f = BuildTypeArgumentsLengthCheck(strong, nsm, expect_type_args);
    if (link) prologue += f;
  }
  if (load_optional_arguments) {
    Fragment f = BuildOptionalParameterHandling(strong, nsm);
    if (link) prologue += f;
  } else if (check_arguments) {
    Fragment f = BuildFixedParameterLengthChecks(strong, nsm);
    if (link) prologue += f;
  }
  if (function_.IsClosureFunction()) {
    Fragment f = BuildClosureContextHandling();
    if (!compiling_for_osr_) prologue += f;
  }
  if (expect_type_args) {
    Fragment f = BuildTypeArgumentsHandling(nsm);
    if (link) prologue += f;
  }

  const bool is_empty_prologue = prologue.entry == prologue.current;

  // Always do this to preserve deoptid numbering.
  JoinEntryInstr* normal_code = BuildJoinEntry();
  prologue += Goto(normal_code);

  if (is_empty_prologue) {
    *prologue_info = PrologueInfo(-1, -1);
    return entry;
  } else {
    *prologue_info =
        PrologueInfo(previous_block_id, normal_code->block_id() - 1);
    return normal_code;
  }
}

Fragment PrologueBuilder::BuildTypeArgumentsLengthCheck(bool strong,
                                                        JoinEntryInstr* nsm,
                                                        bool expect_type_args) {
  Fragment check_type_args;
  JoinEntryInstr* done = BuildJoinEntry();

  // Type args are always optional, so length can always be zero.
  // If expect_type_args, a non-zero length must match the declaration length.
  TargetEntryInstr *then, *fail;
  check_type_args += LoadArgDescriptor();
  check_type_args += LoadField(ArgumentsDescriptor::type_args_len_offset());
  if (expect_type_args) {
    JoinEntryInstr* join2 = BuildJoinEntry();

    LocalVariable* len = MakeTemporary();

    TargetEntryInstr* otherwise;
    check_type_args += LoadLocal(len);
    check_type_args += IntConstant(0);
    check_type_args += BranchIfEqual(&then, &otherwise);

    TargetEntryInstr* then2;
    Fragment check_len(otherwise);
    check_len += LoadLocal(len);
    check_len += IntConstant(function_.NumTypeParameters());
    check_len += BranchIfEqual(&then2, &fail);

    Fragment(then) + Goto(join2);
    Fragment(then2) + Goto(join2);

    Fragment(join2) + Drop() + Goto(done);
    Fragment(fail) + Goto(nsm);
  } else {
    check_type_args += IntConstant(0);
    check_type_args += BranchIfEqual(&then, &fail);
    Fragment(then) + Goto(done);
    Fragment(fail) + Goto(nsm);
  }

  return Fragment(check_type_args.entry, done);
}

Fragment PrologueBuilder::BuildOptionalParameterHandling(bool strong,
                                                         JoinEntryInstr* nsm) {
  Fragment copy_args_prologue;
  const int num_fixed_params = function_.num_fixed_parameters();
  const int num_opt_pos_params = function_.NumOptionalPositionalParameters();
  const int num_opt_named_params = function_.NumOptionalNamedParameters();
  const int num_params =
      num_fixed_params + num_opt_pos_params + num_opt_named_params;
  ASSERT(function_.NumParameters() == num_params);

  // Check that min_num_pos_args <= num_pos_args <= max_num_pos_args,
  // where num_pos_args is the number of positional arguments passed in.
  const int min_num_pos_args = num_fixed_params;
  const int max_num_pos_args = num_fixed_params + num_opt_pos_params;

  copy_args_prologue += LoadArgDescriptor();
  copy_args_prologue +=
      LoadField(ArgumentsDescriptor::positional_count_offset());
  LocalVariable* positional_count_var = MakeTemporary();

  copy_args_prologue += LoadArgDescriptor();
  copy_args_prologue += LoadField(ArgumentsDescriptor::count_offset());
  LocalVariable* count_var = MakeTemporary();

  // Ensure the caller provided at least [min_num_pos_args] arguments.
  copy_args_prologue += IntConstant(min_num_pos_args);
  copy_args_prologue += LoadLocal(positional_count_var);
  copy_args_prologue += SmiRelationalOp(Token::kLTE);
  TargetEntryInstr *success1, *fail1;
  copy_args_prologue += BranchIfTrue(&success1, &fail1);
  copy_args_prologue = Fragment(copy_args_prologue.entry, success1);

  // Ensure the caller provided at most [max_num_pos_args] arguments.
  copy_args_prologue += LoadLocal(positional_count_var);
  copy_args_prologue += IntConstant(max_num_pos_args);
  copy_args_prologue += SmiRelationalOp(Token::kLTE);
  TargetEntryInstr *success2, *fail2;
  copy_args_prologue += BranchIfTrue(&success2, &fail2);
  copy_args_prologue = Fragment(copy_args_prologue.entry, success2);

  // Link up the argument check failing code.
  Fragment(fail1) + Goto(nsm);
  Fragment(fail2) + Goto(nsm);

  copy_args_prologue += LoadLocal(count_var);
  copy_args_prologue += IntConstant(min_num_pos_args);
  copy_args_prologue += SmiBinaryOp(Token::kSUB, /* truncate= */ true);
  LocalVariable* optional_count_var = MakeTemporary();

  // Copy mandatory parameters down.
  intptr_t param = 0;
  for (; param < num_fixed_params; ++param) {
    copy_args_prologue += LoadLocal(optional_count_var);
    copy_args_prologue += LoadFpRelativeSlot(
        kWordSize * (kParamEndSlotFromFp + num_fixed_params - param));
    copy_args_prologue +=
        StoreLocalRaw(TokenPosition::kNoSource, ParameterVariable(param));
    copy_args_prologue += Drop();
  }

  // Copy optional parameters down.
  if (num_opt_pos_params > 0) {
    JoinEntryInstr* next_missing = NULL;
    for (intptr_t opt_param = 1; param < num_params; ++param, ++opt_param) {
      TargetEntryInstr *supplied, *missing;
      copy_args_prologue += IntConstant(opt_param);
      copy_args_prologue += LoadLocal(optional_count_var);
      copy_args_prologue += SmiRelationalOp(Token::kLTE);
      copy_args_prologue += BranchIfTrue(&supplied, &missing);

      Fragment good(supplied);
      good += LoadLocal(optional_count_var);
      good += LoadFpRelativeSlot(
          kWordSize * (kParamEndSlotFromFp + num_fixed_params - param));
      good += StoreLocalRaw(TokenPosition::kNoSource, ParameterVariable(param));
      good += Drop();

      Fragment not_good(missing);
      if (next_missing != NULL) {
        not_good += Goto(next_missing);
        not_good.current = next_missing;
      }
      next_missing = BuildJoinEntry();
      not_good += Constant(DefaultParameterValueAt(opt_param - 1));
      not_good +=
          StoreLocalRaw(TokenPosition::kNoSource, ParameterVariable(param));
      not_good += Drop();
      not_good += Goto(next_missing);

      copy_args_prologue.current = good.current;
    }
    copy_args_prologue += Goto(next_missing /* join good/not_good flows */);
    copy_args_prologue.current = next_missing;

    // If there are more arguments from the caller we haven't processed, go
    // NSM.
    TargetEntryInstr *done, *unknown_named_arg_passed;
    copy_args_prologue += LoadLocal(positional_count_var);
    copy_args_prologue += LoadLocal(count_var);
    copy_args_prologue += BranchIfEqual(&done, &unknown_named_arg_passed);
    copy_args_prologue.current = done;
    {
      Fragment f(unknown_named_arg_passed);
      f += Goto(nsm);
    }
  } else {
    ASSERT(num_opt_named_params > 0);

    const intptr_t first_name_offset =
        ArgumentsDescriptor::first_named_entry_offset() - Array::data_offset();

    // Start by alphabetically sorting the names of the optional parameters.
    LocalVariable** opt_param = new LocalVariable*[num_opt_named_params];
    int* opt_param_position = new int[num_opt_named_params];
    SortOptionalNamedParametersInto(opt_param, opt_param_position,
                                    num_fixed_params, num_params);

    LocalVariable* optional_count_vars_processed =
        parsed_function_->expression_temp_var();
    copy_args_prologue += IntConstant(0);
    copy_args_prologue +=
        StoreLocalRaw(TokenPosition::kNoSource, optional_count_vars_processed);
    copy_args_prologue += Drop();

    for (intptr_t i = 0; param < num_params; ++param, ++i) {
      JoinEntryInstr* join = BuildJoinEntry();

      copy_args_prologue +=
          IntConstant(ArgumentsDescriptor::named_entry_size() / kWordSize);
      copy_args_prologue += LoadLocal(optional_count_vars_processed);
      copy_args_prologue += SmiBinaryOp(Token::kMUL, /* truncate= */ true);
      LocalVariable* tuple_diff = MakeTemporary();

      // name = arg_desc[names_offset + arg_desc_name_index + nameOffset]
      copy_args_prologue += LoadArgDescriptor();
      copy_args_prologue += IntConstant(
          (first_name_offset + ArgumentsDescriptor::name_offset()) / kWordSize);
      copy_args_prologue += LoadLocal(tuple_diff);
      copy_args_prologue += SmiBinaryOp(Token::kADD, /* truncate= */ true);
      copy_args_prologue += LoadIndexed(/* index_scale = */ kWordSize);

      // first name in sorted list of all names
      ASSERT(opt_param[i]->name().IsSymbol());
      copy_args_prologue += Constant(opt_param[i]->name());

      // Compare the two names: Note that the ArgumentDescriptor array always
      // terminates with a "null" name (i.e. kNullCid), which will prevent us
      // from running out-of-bounds.
      TargetEntryInstr *supplied, *missing;
      copy_args_prologue += BranchIfStrictEqual(&supplied, &missing);

      // Let's load position from arg descriptor (to see which parameter is the
      // name) and move kEntrySize forward in ArgDescriptopr names array.
      Fragment good(supplied);

      {
        // fp[kParamEndSlotFromFp + (count_var - pos)]
        good += LoadLocal(count_var);
        {
          // pos = arg_desc[names_offset + arg_desc_name_index + positionOffset]
          good += LoadArgDescriptor();
          good += IntConstant(
              (first_name_offset + ArgumentsDescriptor::position_offset()) /
              kWordSize);
          good += LoadLocal(tuple_diff);
          good += SmiBinaryOp(Token::kADD, /* truncate= */ true);
          good += LoadIndexed(/* index_scale = */ kWordSize);
        }
        good += SmiBinaryOp(Token::kSUB, /* truncate= */ true);
        good += LoadFpRelativeSlot(kWordSize * kParamEndSlotFromFp);

        // Copy down.
        good += StoreLocalRaw(TokenPosition::kNoSource,
                              ParameterVariable(opt_param_position[i]));
        good += Drop();

        // Increase processed optional variable count.
        good += LoadLocal(optional_count_vars_processed);
        good += IntConstant(1);
        good += SmiBinaryOp(Token::kADD, /* truncate= */ true);
        good += StoreLocalRaw(TokenPosition::kNoSource,
                              optional_count_vars_processed);
        good += Drop();

        good += Goto(join);
      }

      // We had no match, let's just load the default constant.
      Fragment not_good(missing);
      {
        not_good += Constant(
            DefaultParameterValueAt(opt_param_position[i] - num_fixed_params));

        // Copy down with default value.
        not_good += StoreLocalRaw(TokenPosition::kNoSource,
                                  ParameterVariable(opt_param_position[i]));
        not_good += Drop();
        not_good += Goto(join);
      }

      copy_args_prologue.current = join;
      copy_args_prologue += Drop();  // tuple_diff
    }

    delete[] opt_param;
    delete[] opt_param_position;

    // If there are more arguments from the caller we haven't processed, go
    // NSM.
    TargetEntryInstr *done, *unknown_named_arg_passed;
    copy_args_prologue += LoadLocal(optional_count_var);
    copy_args_prologue += LoadLocal(optional_count_vars_processed);
    copy_args_prologue += BranchIfEqual(&done, &unknown_named_arg_passed);
    copy_args_prologue.current = done;

    {
      Fragment f(unknown_named_arg_passed);
      f += Goto(nsm);
    }
  }

  copy_args_prologue += Drop();  // optional_count_var
  copy_args_prologue += Drop();  // count_var
  copy_args_prologue += Drop();  // positional_count_var

  return copy_args_prologue;
}

Fragment PrologueBuilder::BuildFixedParameterLengthChecks(bool strong,
                                                          JoinEntryInstr* nsm) {
  Fragment check_args;
  JoinEntryInstr* done = BuildJoinEntry();

  check_args += LoadArgDescriptor();
  check_args += LoadField(ArgumentsDescriptor::count_offset());
  LocalVariable* count = MakeTemporary();

  TargetEntryInstr *then, *fail;
  check_args += LoadLocal(count);
  check_args += IntConstant(function_.num_fixed_parameters());
  check_args += BranchIfEqual(&then, &fail);

  TargetEntryInstr *then2, *fail2;
  Fragment check_len(then);
  check_len += LoadArgDescriptor();
  check_len += LoadField(ArgumentsDescriptor::positional_count_offset());
  check_len += BranchIfEqual(&then2, &fail2);

  Fragment(fail) + Goto(nsm);
  Fragment(fail2) + Goto(nsm);
  Fragment(then2) + Goto(done);

  return Fragment(check_args.entry, done);
}

Fragment PrologueBuilder::BuildClosureContextHandling() {
  LocalScope* scope = parsed_function_->node_sequence()->scope();
  LocalVariable* closure_parameter = scope->VariableAt(0);

  LocalVariable* context = parsed_function_->current_context_var();

  // Load closure.context & store it into the context variable.
  // (both load/store happen on the copyied-down places).
  Fragment populate_context;
  populate_context += LoadLocal(closure_parameter);
  populate_context += LoadField(Closure::context_offset());
  populate_context += StoreLocal(TokenPosition::kNoSource, context);
  populate_context += Drop();
  return populate_context;
}

Fragment PrologueBuilder::BuildTypeArgumentsHandling(JoinEntryInstr* nsm) {
  LocalVariable* type_args_var = parsed_function_->RawTypeArgumentsVariable();

  Fragment handling;

  Fragment store_type_args;
  store_type_args += LoadArgDescriptor();
  store_type_args += LoadField(ArgumentsDescriptor::count_offset());
  store_type_args += LoadFpRelativeSlot(kWordSize * (1 + kParamEndSlotFromFp));
  store_type_args += StoreLocal(TokenPosition::kNoSource, type_args_var);
  store_type_args += Drop();

  Fragment store_null;
  store_null += NullConstant();
  store_null += StoreLocal(TokenPosition::kNoSource, type_args_var);
  store_null += Drop();

  handling += TestTypeArgsLen(store_null, store_type_args, 0);

  if (parsed_function_->function().IsClosureFunction()) {
    LocalVariable* closure =
        parsed_function_->node_sequence()->scope()->VariableAt(0);

    // Currently, delayed type arguments can only be introduced through type
    // inference in the FE. So if they are present, we can assume they are
    // correct in number and bound.
    // clang-format off
    Fragment use_delayed_type_args = {
      LoadLocal(closure),
      LoadField(Closure::delayed_type_arguments_offset()),
      StoreLocal(TokenPosition::kNoSource, type_args_var),
      Drop()
    };

    handling += TestDelayedTypeArgs(
        closure,
        /*present=*/TestTypeArgsLen(
            use_delayed_type_args, Goto(nsm), 0),
        /*absent=*/Fragment());
    // clang-format on
  }

  return handling;
}

void PrologueBuilder::SortOptionalNamedParametersInto(LocalVariable** opt_param,
                                                      int* opt_param_position,
                                                      int num_fixed_params,
                                                      int num_params) {
  LocalScope* scope = parsed_function_->node_sequence()->scope();
  for (int pos = num_fixed_params; pos < num_params; pos++) {
    LocalVariable* parameter = scope->VariableAt(pos);
    const String& opt_param_name = parameter->name();
    int i = pos - num_fixed_params;
    while (--i >= 0) {
      LocalVariable* param_i = opt_param[i];
      const intptr_t result = opt_param_name.CompareTo(param_i->name());
      ASSERT(result != 0);
      if (result > 0) break;
      opt_param[i + 1] = opt_param[i];
      opt_param_position[i + 1] = opt_param_position[i];
    }
    opt_param[i + 1] = parameter;
    opt_param_position[i + 1] = pos;
  }
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
