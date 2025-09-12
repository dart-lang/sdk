// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#include "vm/globals.h"  // For INCLUDE_IL_PRINTER
#if defined(INCLUDE_IL_PRINTER)

#include "vm/compiler/api/print_filter.h"

#include "vm/flags.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#endif
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(charp,
            print_flow_graph_filter,
            nullptr,
            "Print only IR of functions with matching names");

namespace compiler {

// Checks whether function's name matches the given filter, which is
// a comma-separated list of strings.
static bool PassesFilter(const char* filter,
                         const Function& function,
                         uint8_t** compiler_pass_filter) {
  if (filter == nullptr) {
    return true;
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (strcmp(filter, "@pragma") == 0) {
    Object& pass_filter = Object::Handle();
    const auto has_pragma =
        Library::FindPragma(dart::Thread::Current(), /*only_core=*/false,
                            function, Symbols::vm_testing_print_flow_graph(),
                            /*multiple=*/false, &pass_filter);
    if (has_pragma && !pass_filter.IsNull() &&
        compiler_pass_filter != nullptr) {
      *compiler_pass_filter = dart::CompilerPass::ParseFiltersFromPragma(
          String::Cast(pass_filter).ToCString());
    }
    return has_pragma;
  }
#endif

  return function.NamePassesFilter(filter);
}

bool PrintFilter::ShouldPrint(const Function& function,
                              uint8_t** compiler_pass_filter /* = nullptr */) {
  return PassesFilter(FLAG_print_flow_graph_filter, function,
                      compiler_pass_filter);
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(INCLUDE_IL_PRINTER)
