// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/prologue_builder.h"

#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/frontend/base_flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/kernel_loader.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"

namespace dart {
namespace kernel {

#define Z (zone_)

// Returns static type of the parameter if it can be trusted (was type checked
// by caller) and dynamic otherwise.
static CompileType ParameterType(LocalVariable* param,
                                 Representation representation = kTagged) {
  return param->was_type_checked_by_caller()
             ? CompileType::FromAbstractType(param->static_type(),
                                             representation == kTagged,
                                             CompileType::kCannotBeSentinel)
             : ((representation == kTagged)
                    ? CompileType::Dynamic()
                    : CompileType::Dynamic().CopyNonNullable());
}

bool PrologueBuilder::PrologueSkippableOnUncheckedEntry(
    const Function& function) {
  return !function.MakesCopyOfParameters() &&
         !function.IsNonImplicitClosureFunction() && !function.IsGeneric();
}

bool PrologueBuilder::HasEmptyPrologue(const Function& function) {
  return !function.MakesCopyOfParameters() && !function.IsGeneric() &&
         !function.IsClosureFunction();
}

BlockEntryInstr* PrologueBuilder::BuildPrologue(BlockEntryInstr* entry,
                                                PrologueInfo* prologue_info) {
  // We always have to build the graph, but we only link it sometimes.
  const bool link = !is_inlining_ && !compiling_for_osr_;

  const intptr_t previous_block_id = last_used_block_id_;

  const bool copy_parameters = function_.MakesCopyOfParameters();
  const bool expect_type_args = function_.IsGeneric();

  Fragment prologue = Fragment(entry);

  if (copy_parameters) {
    Fragment f = BuildParameterHandling();
    if (link) prologue += f;
  }
  if (function_.IsClosureFunction()) {
    Fragment f = BuildClosureContextHandling();
    if (!compiling_for_osr_) prologue += f;
  }
  if (expect_type_args) {
    Fragment f = BuildTypeArgumentsHandling();
    if (link) prologue += f;

    if (function_.IsClosureFunction()) {
      Fragment f = BuildClosureDelayedTypeArgumentsHandling();
      if (!compiling_for_osr_) prologue += f;
    }
  }

  const bool is_empty_prologue = prologue.entry == prologue.current;
  // Double-check we create empty prologues when HasEmptyPrologue returns true.
  ASSERT(!HasEmptyPrologue(function_) || is_empty_prologue);

  // Always do this to preserve deoptid numbering.
  JoinEntryInstr* normal_code = BuildJoinEntry();
  Fragment jump_to_normal_code = Goto(normal_code);

  if (is_empty_prologue) {
    *prologue_info = PrologueInfo(-1, -1);
    return entry;
  } else {
    prologue += jump_to_normal_code;
    *prologue_info =
        PrologueInfo(previous_block_id, normal_code->block_id() - 1);
    return normal_code;
  }
}

Fragment PrologueBuilder::BuildParameterHandling() {
  Fragment copy_args_prologue;
  const int num_fixed_params = function_.num_fixed_parameters();
  const int num_opt_pos_params = function_.NumOptionalPositionalParameters();
  const int num_opt_named_params = function_.NumOptionalNamedParameters();
  const int num_params =
      num_fixed_params + num_opt_pos_params + num_opt_named_params;
  ASSERT(function_.NumParameters() == num_params);

  // This will contain information about registers assigned to fixed
  // parameters as well as their stack locations relative to callee FP
  // under the assumption that no other arguments were passed.
  compiler::ParameterInfoArray fixed_params(num_fixed_params);
  FlowGraph::ComputeLocationsOfFixedParameters(
      zone_, function_,
      /*should_assign_stack_locations=*/true, &fixed_params);

  // Check that min_num_pos_args <= num_pos_args <= max_num_pos_args,
  // where num_pos_args is the number of positional arguments passed in.
  const int min_num_pos_args = num_fixed_params;

  LocalVariable* count_var = nullptr;
  LocalVariable* optional_count_var = nullptr;
  if ((num_opt_pos_params > 0) || (num_opt_named_params > 0)) {
    copy_args_prologue += LoadArgDescriptor();
    copy_args_prologue +=
        LoadNativeField(Slot::ArgumentsDescriptor_positional_count());

    copy_args_prologue += LoadArgDescriptor();
    copy_args_prologue += LoadNativeField(Slot::ArgumentsDescriptor_count());
    count_var = MakeTemporary();

    copy_args_prologue += LoadLocal(count_var);
    copy_args_prologue += IntConstant(min_num_pos_args);
    copy_args_prologue += SmiBinaryOp(Token::kSUB, /*is_truncating=*/true);
    optional_count_var = MakeTemporary();
  }

  // Copy mandatory parameters down.
  intptr_t param = 0;
  for (; param < num_fixed_params; ++param) {
    const auto [location, representation] = fixed_params[param];

    const auto lo_location =
        location.IsPairLocation() ? location.AsPairLocation()->At(0) : location;

    if (lo_location.IsMachineRegister()) {
      continue;
    }

    if ((num_opt_pos_params > 0) || (num_opt_named_params > 0)) {
      copy_args_prologue += LoadLocal(optional_count_var);
    } else {
      copy_args_prologue += IntConstant(0);
    }
    const intptr_t stack_slot_offset = lo_location.ToStackSlotOffset();
    copy_args_prologue += LoadFpRelativeSlot(
        stack_slot_offset,
        ParameterType(ParameterVariable(param), representation),
        representation);
    copy_args_prologue +=
        StoreLocalRaw(TokenPosition::kNoSource, ParameterVariable(param));
    copy_args_prologue += Drop();
  }

  // Copy optional parameters down.
  if (num_opt_pos_params > 0) {
    JoinEntryInstr* next_missing = nullptr;
    for (intptr_t opt_param = 0; param < num_params; ++param, ++opt_param) {
      TargetEntryInstr *supplied, *missing;
      copy_args_prologue += IntConstant(opt_param + 1);
      copy_args_prologue += LoadLocal(optional_count_var);
      copy_args_prologue += SmiRelationalOp(Token::kLTE);
      copy_args_prologue += BranchIfTrue(&supplied, &missing);

      Fragment good(supplied);
      good += LoadLocal(optional_count_var);
      // Note: FP[param_end_from_fp + 1 + (optional_count_var - 1)] points to
      // the first optional parameter.
      good += LoadFpRelativeSlot(
          compiler::target::kWordSize *
              (compiler::target::frame_layout.param_end_from_fp - opt_param),
          ParameterType(ParameterVariable(param)));
      good += StoreLocalRaw(TokenPosition::kNoSource, ParameterVariable(param));
      good += Drop();

      Fragment not_good(missing);
      if (next_missing != nullptr) {
        not_good += Goto(next_missing);
        not_good.current = next_missing;
      }
      next_missing = BuildJoinEntry();
      not_good += Constant(DefaultParameterValueAt(opt_param));
      not_good +=
          StoreLocalRaw(TokenPosition::kNoSource, ParameterVariable(param));
      not_good += Drop();
      not_good += Goto(next_missing);

      copy_args_prologue.current = good.current;
    }
    copy_args_prologue += Goto(next_missing /* join good/not_good flows */);
    copy_args_prologue.current = next_missing;

  } else if (num_opt_named_params > 0) {
    const intptr_t first_name_offset =
        compiler::target::ArgumentsDescriptor::first_named_entry_offset() -
        compiler::target::Array::data_offset();

    // Start by alphabetically sorting the names of the optional parameters.
    int* opt_param_position = Z->Alloc<int>(num_opt_named_params);
    SortOptionalNamedParametersInto(opt_param_position, num_fixed_params,
                                    num_params);

    LocalVariable* optional_count_vars_processed =
        parsed_function_->expression_temp_var();
    ASSERT(optional_count_vars_processed != nullptr);
    copy_args_prologue += IntConstant(0);
    copy_args_prologue +=
        StoreLocalRaw(TokenPosition::kNoSource, optional_count_vars_processed);
    copy_args_prologue += Drop();

    for (intptr_t i = 0; param < num_params; ++param, ++i) {
      copy_args_prologue += IntConstant(
          compiler::target::ArgumentsDescriptor::named_entry_size() /
          compiler::target::kCompressedWordSize);
      copy_args_prologue += LoadLocal(optional_count_vars_processed);
      copy_args_prologue += SmiBinaryOp(Token::kMUL, /*is_truncating=*/true);
      LocalVariable* tuple_diff = MakeTemporary();

      // Let's load position from arg descriptor (to see which parameter is the
      // name) and move kEntrySize forward in ArgDescriptor names array.
      //
      // Later we'll either add this fragment directly to the copy_args_prologue
      // if no check is needed or add an appropriate check.
      Fragment good;
      {
        // fp[target::frame_layout.param_end_from_fp + (count_var - pos)]
        good += LoadLocal(count_var);
        {
          // pos = arg_desc[names_offset + arg_desc_name_index + positionOffset]
          good += LoadArgDescriptor();
          good += IntConstant(
              (first_name_offset +
               compiler::target::ArgumentsDescriptor::position_offset()) /
              compiler::target::kCompressedWordSize);
          good += LoadLocal(tuple_diff);
          good += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
          good += LoadIndexed(
              kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);
        }
        good += SmiBinaryOp(Token::kSUB, /*is_truncating=*/true);
        good += LoadFpRelativeSlot(
            compiler::target::kWordSize *
                compiler::target::frame_layout.param_end_from_fp,
            ParameterType(ParameterVariable(opt_param_position[i])));

        // Copy down.
        good += StoreLocalRaw(TokenPosition::kNoSource,
                              ParameterVariable(opt_param_position[i]));
        good += Drop();

        // Increase processed optional variable count.
        good += LoadLocal(optional_count_vars_processed);
        good += IntConstant(1);
        good += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
        good += StoreLocalRaw(TokenPosition::kNoSource,
                              optional_count_vars_processed);
        good += Drop();
      }

      const bool required = function_.IsRequiredAt(opt_param_position[i]);

      if (required) {
        copy_args_prologue += good;
      } else {
        // name = arg_desc[names_offset + arg_desc_name_index + nameOffset]
        copy_args_prologue += LoadArgDescriptor();
        copy_args_prologue +=
            IntConstant((first_name_offset +
                         compiler::target::ArgumentsDescriptor::name_offset()) /
                        compiler::target::kCompressedWordSize);
        copy_args_prologue += LoadLocal(tuple_diff);
        copy_args_prologue += SmiBinaryOp(Token::kADD, /*is_truncating=*/true);
        copy_args_prologue += LoadIndexed(
            kArrayCid, /*index_scale*/ compiler::target::kCompressedWordSize);

        // first name in sorted list of all names
        const String& param_name = String::ZoneHandle(
            Z, function_.ParameterNameAt(opt_param_position[i]));
        ASSERT(param_name.IsSymbol());
        copy_args_prologue += Constant(param_name);

        // Compare the two names: Note that the ArgumentDescriptor array always
        // terminates with a "null" name (i.e. kNullCid), which will prevent us
        // from running out-of-bounds.
        TargetEntryInstr *supplied, *missing;
        copy_args_prologue += BranchIfStrictEqual(&supplied, &missing);

        // Join good/not_good.
        JoinEntryInstr* join = BuildJoinEntry();

        // Put good in the flowgraph as a separate basic block.
        good.Prepend(supplied);
        good += Goto(join);

        // We had no match, so load the default constant.
        Fragment not_good(missing);
        not_good += Constant(
            DefaultParameterValueAt(opt_param_position[i] - num_fixed_params));

        // Copy down with default value.
        not_good += StoreLocalRaw(TokenPosition::kNoSource,
                                  ParameterVariable(opt_param_position[i]));
        not_good += Drop();
        not_good += Goto(join);

        copy_args_prologue.current = join;
      }

      copy_args_prologue += Drop();  // tuple_diff
    }
  }

  if ((num_opt_pos_params > 0) || (num_opt_named_params > 0)) {
    copy_args_prologue += Drop();  // optional_count_var
    copy_args_prologue += Drop();  // count_var
    copy_args_prologue += Drop();  // positional_count_var
  }

  return copy_args_prologue;
}

Fragment PrologueBuilder::BuildClosureContextHandling() {
  LocalVariable* closure_parameter = parsed_function_->ParameterVariable(0);
  LocalVariable* context = parsed_function_->current_context_var();

  // Load closure.context & store it into the context variable.
  // (both load/store happen on the copied-down places).
  Fragment populate_context;
  populate_context += LoadLocal(closure_parameter);
  populate_context += LoadNativeField(Slot::Closure_context());
  populate_context += StoreLocal(TokenPosition::kNoSource, context);
  populate_context += Drop();
  return populate_context;
}

Fragment PrologueBuilder::BuildTypeArgumentsHandling() {
  LocalVariable* type_args_var = parsed_function_->RawTypeArgumentsVariable();
  ASSERT(type_args_var != nullptr);

  Fragment handling;

  Fragment store_type_args;
  store_type_args += LoadArgDescriptor();
  store_type_args += LoadNativeField(Slot::ArgumentsDescriptor_size());
  store_type_args += LoadFpRelativeSlot(
      compiler::target::kWordSize *
          (1 + compiler::target::frame_layout.param_end_from_fp),
      CompileType(CompileType::kCanBeNull, CompileType::kCannotBeSentinel,
                  kTypeArgumentsCid, nullptr));
  store_type_args += StoreLocal(TokenPosition::kNoSource, type_args_var);
  store_type_args += Drop();

  Fragment store_null;
  store_null += NullConstant();
  store_null += StoreLocal(TokenPosition::kNoSource, type_args_var);
  store_null += Drop();

  handling += TestTypeArgsLen(store_null, store_type_args, 0);

  return handling;
}

Fragment PrologueBuilder::BuildClosureDelayedTypeArgumentsHandling() {
  const auto& function = parsed_function_->function();
  ASSERT(function.IsClosureFunction());
  LocalVariable* const type_args_var =
      parsed_function_->RawTypeArgumentsVariable();
  ASSERT(type_args_var != nullptr);

  LocalVariable* const closure = parsed_function_->ParameterVariable(0);

  // Currently, delayed type arguments can only be introduced through type
  // inference in the FE. So if they are present, we can assume they are
  // correct in number and bound.
  Fragment use_delayed_type_args;
  use_delayed_type_args += LoadLocal(closure);
  use_delayed_type_args +=
      LoadNativeField(Slot::Closure_delayed_type_arguments());
  use_delayed_type_args += StoreLocal(TokenPosition::kNoSource, type_args_var);
  use_delayed_type_args += Drop();

  return TestDelayedTypeArgs(closure,
                             /*present=*/use_delayed_type_args,
                             /*absent=*/Fragment());
}

void PrologueBuilder::SortOptionalNamedParametersInto(int* opt_param_position,
                                                      int num_fixed_params,
                                                      int num_params) {
  String& name = String::Handle(Z);
  String& name_i = String::Handle(Z);
  for (int pos = num_fixed_params; pos < num_params; pos++) {
    name = function_.ParameterNameAt(pos);
    int i = pos - num_fixed_params;
    while (--i >= 0) {
      name_i = function_.ParameterNameAt(opt_param_position[i]);
      const intptr_t result = name.CompareTo(name_i);
      ASSERT(result != 0);
      if (result > 0) break;
      opt_param_position[i + 1] = opt_param_position[i];
    }
    opt_param_position[i + 1] = pos;
  }
}

}  // namespace kernel
}  // namespace dart
