// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COMPILER_STATS_H_
#define VM_COMPILER_STATS_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/timer.h"



namespace dart {

DECLARE_FLAG(bool, compiler_stats);

class CompilerStats : AllStatic {
 public:
  static int64_t num_tokens_total;
  static int64_t num_literal_tokens_total;
  static int64_t num_ident_tokens_total;
  static int64_t num_tokens_consumed;
  static int64_t num_token_checks;
  static int64_t num_tokens_rewind;
  static int64_t num_tokens_lookahead;

  static int64_t num_lib_cache_hit;
  static int64_t num_names_cached;
  static int64_t make_accessor_name;
  static int64_t make_field_name;

  static int64_t num_classes_compiled;
  static int64_t num_functions_compiled;
  static int64_t num_implicit_final_getters;
  static int64_t num_static_initializer_funcs;

  static int64_t src_length;        // Total number of characters in source.
  static int64_t code_allocated;    // Bytes allocated for generated code.
  static Timer parser_timer;         // Cumulative runtime of parser.
  static Timer scanner_timer;        // Cumulative runtime of scanner.
  static Timer codegen_timer;        // Cumulative runtime of code generator.
  static Timer graphbuilder_timer;   // Included in codegen_timer.
  static Timer ssa_timer;            // Included in codegen_timer.
  static Timer graphinliner_timer;   // Included in codegen_timer.
  static Timer graphinliner_parse_timer;  // Included in codegen_timer.
  static Timer graphinliner_build_timer;  // Included in codegen_timer.
  static Timer graphinliner_ssa_timer;    // Included in codegen_timer.
  static Timer graphinliner_opt_timer;    // Included in codegen_timer.
  static Timer graphinliner_find_timer;   // Included in codegen_timer.
  static Timer graphinliner_plug_timer;   // Included in codegen_timer.
  static Timer graphinliner_subst_timer;  // Included in codegen_timer.

  static Timer graphoptimizer_timer;  // Included in codegen_timer.
  static Timer graphcompiler_timer;   // Included in codegen_timer.
  static Timer codefinalizer_timer;   // Included in codegen_timer.

  static void Print();
};


}  // namespace dart

#endif  // VM_COMPILER_STATS_H_
