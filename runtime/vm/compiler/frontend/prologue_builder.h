// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_PROLOGUE_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_PROLOGUE_BUILDER_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/kernel_to_il.h"

namespace dart {
namespace kernel {

// Responsible for building IR code for prologues of functions.
//
// This code handles initialization of local variables which the
// prologue needs to setup, including initialization of the:
//
//    * current context variable, from the passed closure object
//    * function_type_arguments variable, from the stack above fp
//    * raw parameter variables, from the stack above fp
//
// if needed.
//
// Furthermore it performs all necessary checks which could lead into a
// no-such-method bailout, including check that:
//
//    * the number of passed positional arguments is correct
//    * the names of passed named arguments are correct
//    * the number of function type arguments is correct
//
// if needed.
//
// Most of these things are done by interpreting the caller-supplied arguments
// descriptor.
class PrologueBuilder : public BaseFlowGraphBuilder {
 public:
  PrologueBuilder(const ParsedFunction* parsed_function,
                  intptr_t last_used_id,
                  bool compiling_for_osr,
                  bool is_inlining)
      : BaseFlowGraphBuilder(parsed_function, last_used_id),
        compiling_for_osr_(compiling_for_osr),
        is_inlining_(is_inlining) {}

  BlockEntryInstr* BuildPrologue(BlockEntryInstr* entry,
                                 PrologueInfo* prologue_info);

  intptr_t last_used_block_id() const { return last_used_block_id_; }

 private:
  Fragment BuildTypeArgumentsLengthCheck(bool strong,
                                         JoinEntryInstr* nsm,
                                         bool expect_type_args);

  Fragment BuildOptionalParameterHandling(bool strong, JoinEntryInstr* nsm);

  Fragment BuildFixedParameterLengthChecks(bool strong, JoinEntryInstr* nsm);

  Fragment BuildClosureContextHandling();

  Fragment BuildTypeArgumentsHandling(bool strong);

  LocalVariable* ParameterVariable(intptr_t index) {
    return parsed_function_->RawParameterVariable(index);
  }

  const Instance& DefaultParameterValueAt(intptr_t i) {
    if (parsed_function_->default_parameter_values() != NULL) {
      return parsed_function_->DefaultParameterValueAt(i);
    }

    ASSERT(parsed_function_->function().kind() ==
           RawFunction::kNoSuchMethodDispatcher);
    return Instance::null_instance();
  }

  void SortOptionalNamedParametersInto(LocalVariable** opt_param,
                                       int* opt_param_position,
                                       int num_fixed_params,
                                       int num_params);

  bool compiling_for_osr_;
  bool is_inlining_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_PROLOGUE_BUILDER_H_
