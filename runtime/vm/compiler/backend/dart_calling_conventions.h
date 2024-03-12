// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_DART_CALLING_CONVENTIONS_H_
#define RUNTIME_VM_COMPILER_BACKEND_DART_CALLING_CONVENTIONS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <utility>

#include "platform/globals.h"
#include "platform/growable_array.h"
#include "vm/compiler/backend/locations.h"

namespace dart {

class Function;

namespace compiler {

// Array which for every parameter (or argument) contains its expected
// |Location| and its |Representation|.
using ParameterInfoArray = GrowableArray<std::pair<Location, Representation>>;

// For a call to the |target| function with |argc| arguments compute
// amount of stack space needed to pass all arguments in words.
//
// If |parameter_info| is not |nullptr| then it will be populated to
// describe expected location and representation of each argument.
//
// If |should_assign_stack_locations| is |false| then only arguments
// which will be passsed in registers have their locations computed.
// This does not affect return value: it is always equal to the
// number of words needed for all arguments which are passed on the stack.
intptr_t ComputeCallingConvention(
    Zone* zone,
    const Function& target,
    intptr_t argc,
    std::function<Representation(intptr_t)> argument_rep,
    bool should_assign_stack_locations,
    ParameterInfoArray* parameter_info);

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_DART_CALLING_CONVENTIONS_H_
