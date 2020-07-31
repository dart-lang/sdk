// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

#include "vm/compiler/api/print_filter.h"

#include "vm/flags.h"
#include "vm/object.h"

namespace dart {

DEFINE_FLAG(charp,
            print_flow_graph_filter,
            NULL,
            "Print only IR of functions with matching names");

namespace compiler {

// Checks whether function's name matches the given filter, which is
// a comma-separated list of strings.
static bool PassesFilter(const char* filter, const Function& function) {
  if (filter == NULL) {
    return true;
  }

  char* save_ptr;  // Needed for strtok_r.
  const char* scrubbed_name =
      String::Handle(function.QualifiedScrubbedName()).ToCString();
  const char* function_name = function.ToFullyQualifiedCString();
  intptr_t function_name_len = strlen(function_name);

  intptr_t len = strlen(filter) + 1;  // Length with \0.
  char* filter_buffer = new char[len];
  strncpy(filter_buffer, filter, len);  // strtok modifies arg 1.
  char* token = strtok_r(filter_buffer, ",", &save_ptr);
  bool found = false;
  while (token != NULL) {
    if ((strstr(function_name, token) != NULL) ||
        (strstr(scrubbed_name, token) != NULL)) {
      found = true;
      break;
    }
    const intptr_t token_len = strlen(token);
    if (token[token_len - 1] == '%') {
      if (function_name_len > token_len) {
        const char* suffix =
            function_name + (function_name_len - token_len + 1);
        if (strncmp(suffix, token, token_len - 1) == 0) {
          found = true;
          break;
        }
      }
    }
    token = strtok_r(NULL, ",", &save_ptr);
  }
  delete[] filter_buffer;

  return found;
}

bool PrintFilter::ShouldPrint(const Function& function) {
  return PassesFilter(FLAG_print_flow_graph_filter, function);
}

}  // namespace compiler

}  // namespace dart

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
