// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COMPILER_STATS_H_
#define VM_COMPILER_STATS_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/timer.h"



namespace dart {

DECLARE_FLAG(bool, compiler_stats);

// TODO(hausner): Might want to expose some of these values in the
// observatory. Use the metrics mechanism (metrics.h) for this.

class CompilerStats {
 public:
  explicit CompilerStats(Isolate* isolate);
  ~CompilerStats() { }

  Isolate* isolate_;

  // TODO(hausner): add these timers to the timer list maintained
  // in the isolate?
  Timer parser_timer;         // Cumulative runtime of parser.
  Timer scanner_timer;        // Cumulative runtime of scanner.
  Timer codegen_timer;        // Cumulative runtime of code generator.
  Timer graphbuilder_timer;   // Included in codegen_timer.
  Timer ssa_timer;            // Included in codegen_timer.
  Timer graphinliner_timer;   // Included in codegen_timer.
  Timer graphinliner_parse_timer;  // Included in codegen_timer.
  Timer graphinliner_build_timer;  // Included in codegen_timer.
  Timer graphinliner_ssa_timer;    // Included in codegen_timer.
  Timer graphinliner_opt_timer;    // Included in codegen_timer.
  Timer graphinliner_subst_timer;  // Included in codegen_timer.

  Timer graphoptimizer_timer;  // Included in codegen_timer.
  Timer graphcompiler_timer;   // Included in codegen_timer.
  Timer codefinalizer_timer;   // Included in codegen_timer.

  int64_t num_tokens_total;
  int64_t num_literal_tokens_total;
  int64_t num_ident_tokens_total;
  int64_t num_tokens_consumed;
  int64_t num_token_checks;
  int64_t num_tokens_lookahead;

  int64_t num_classes_compiled;
  int64_t num_functions_compiled;
  int64_t num_implicit_final_getters;

  int64_t src_length;          // Total number of characters in source.
  int64_t total_code_size;     // Bytes allocated for code and meta info.
  int64_t total_instr_size;    // Total size of generated code in bytes.
  int64_t pc_desc_size;
  int64_t vardesc_size;

  void Print();
};

#define INC_STAT(isolate, counter, incr)                                       \
  if (FLAG_compiler_stats) { (isolate)->compiler_stats()->counter += (incr); }

#define CSTAT_TIMER_SCOPE(thr, t)                                              \
  TimerScope timer(FLAG_compiler_stats,                                        \
      FLAG_compiler_stats ? &((thr)->isolate()->compiler_stats()->t) : NULL,   \
      thr);

}  // namespace dart

#endif  // VM_COMPILER_STATS_H_
