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
DECLARE_FLAG(bool, compiler_benchmark);

class CompilerStats {
 public:
  explicit CompilerStats(Isolate* isolate);
  ~CompilerStats() { }

  Isolate* isolate_;

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

  int64_t num_tokens_total;    // Isolate + VM isolate
  int64_t num_tokens_scanned;
  int64_t num_tokens_consumed;
  int64_t num_cached_consts;
  int64_t num_const_cache_hits;

  int64_t num_classes_parsed;
  int64_t num_class_tokens;
  int64_t num_functions_parsed;      // Num parsed functions.
  int64_t num_functions_compiled;    // Num unoptimized compilations.
  int64_t num_functions_optimized;   // Num optimized compilations.
  int64_t num_func_tokens_compiled;
  int64_t num_implicit_final_getters;
  int64_t num_method_extractors;

  int64_t src_length;          // Total number of characters in source.
  int64_t total_code_size;     // Bytes allocated for code and meta info.
  int64_t total_instr_size;    // Total size of generated code in bytes.
  int64_t pc_desc_size;
  int64_t vardesc_size;
  char* text;
  bool use_benchmark_output;

  // Update stats that are computed, e.g. token count.
  void Update();

  void EnableBenchmark();
  char* BenchmarkOutput();
  char* PrintToZone();
};

#define INC_STAT(thread, counter, incr)                                        \
  if (FLAG_compiler_stats) {                                                   \
    MutexLocker ml((thread)->isolate()->mutex());                              \
    (thread)->isolate()->compiler_stats()->counter += (incr);                  \
  }

#define STAT_VALUE(thread, counter)                                            \
  ((FLAG_compiler_stats != false) ?                                            \
      (thread)->isolate()->compiler_stats()->counter : 0)

#define CSTAT_TIMER_SCOPE(thr, t)                                              \
  TimerScope timer(FLAG_compiler_stats,                                        \
      FLAG_compiler_stats ? &((thr)->isolate()->compiler_stats()->t) : NULL,   \
      thr);

}  // namespace dart

#endif  // VM_COMPILER_STATS_H_
