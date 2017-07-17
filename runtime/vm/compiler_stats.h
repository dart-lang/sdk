// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_STATS_H_
#define RUNTIME_VM_COMPILER_STATS_H_

#include "vm/allocation.h"
#include "vm/atomic.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/timer.h"

namespace dart {

DECLARE_FLAG(bool, compiler_stats);
DECLARE_FLAG(bool, compiler_benchmark);

#define STAT_TIMERS(V)                                                         \
  V(parser_timer, "parser timer")                                              \
  V(scanner_timer, "scanner timer")                                            \
  V(codegen_timer, "codegen timer")                                            \
  V(graphbuilder_timer, "flow graph builder timer")                            \
  V(ssa_timer, "flow graph SSA timer")                                         \
  V(graphinliner_timer, "flow graph inliner timer")                            \
  V(graphinliner_parse_timer, "inliner parsing timer")                         \
  V(graphinliner_build_timer, "inliner building timer")                        \
  V(graphinliner_ssa_timer, "inliner SSA timer")                               \
  V(graphinliner_opt_timer, "inliner optimization timer")                      \
  V(graphinliner_subst_timer, "inliner substitution timer")                    \
  V(graphoptimizer_timer, "flow graph optimizer timer")                        \
  V(graphcompiler_timer, "flow graph compiler timer")                          \
  V(codefinalizer_timer, "code finalization timer")

#define STAT_COUNTERS(V)                                                       \
  V(num_tokens_total)                                                          \
  V(num_tokens_scanned)                                                        \
  V(num_tokens_consumed)                                                       \
  V(num_cached_consts)                                                         \
  V(num_const_cache_hits)                                                      \
  V(num_execute_const)                                                         \
  V(num_classes_parsed)                                                        \
  V(num_class_tokens)                                                          \
  V(num_functions_parsed)                                                      \
  V(num_functions_compiled)                                                    \
  V(num_functions_optimized)                                                   \
  V(num_func_tokens_compiled)                                                  \
  V(num_implicit_final_getters)                                                \
  V(num_method_extractors)                                                     \
  V(src_length)                                                                \
  V(total_code_size)                                                           \
  V(total_instr_size)                                                          \
  V(pc_desc_size)                                                              \
  V(vardesc_size)

class CompilerStats {
 public:
  explicit CompilerStats(Isolate* isolate);
  ~CompilerStats() {}

  Isolate* isolate_;

  // We could use STAT_TIMERS and STAT_COUNTERS to declare fields, but then
  // we would be losing the comments.
  Timer parser_timer;              // Cumulative runtime of parser.
  Timer scanner_timer;             // Cumulative runtime of scanner.
  Timer codegen_timer;             // Cumulative runtime of code generator.
  Timer graphbuilder_timer;        // Included in codegen_timer.
  Timer ssa_timer;                 // Included in codegen_timer.
  Timer graphinliner_timer;        // Included in codegen_timer.
  Timer graphinliner_parse_timer;  // Included in codegen_timer.
  Timer graphinliner_build_timer;  // Included in codegen_timer.
  Timer graphinliner_ssa_timer;    // Included in codegen_timer.
  Timer graphinliner_opt_timer;    // Included in codegen_timer.
  Timer graphinliner_subst_timer;  // Included in codegen_timer.

  Timer graphoptimizer_timer;  // Included in codegen_timer.
  Timer graphcompiler_timer;   // Included in codegen_timer.
  Timer codefinalizer_timer;   // Included in codegen_timer.

  int64_t num_tokens_total;  // Isolate + VM isolate
  int64_t num_tokens_scanned;
  int64_t num_tokens_consumed;
  int64_t num_cached_consts;
  int64_t num_const_cache_hits;
  int64_t num_execute_const;

  int64_t num_classes_parsed;
  int64_t num_class_tokens;
  int64_t num_functions_parsed;     // Num parsed functions.
  int64_t num_functions_compiled;   // Num unoptimized compilations.
  int64_t num_functions_optimized;  // Num optimized compilations.
  int64_t num_func_tokens_compiled;
  int64_t num_implicit_final_getters;
  int64_t num_method_extractors;

  int64_t src_length;        // Total number of characters in source.
  int64_t total_code_size;   // Bytes allocated for code and meta info.
  int64_t total_instr_size;  // Total size of generated code in bytes.
  int64_t pc_desc_size;
  int64_t vardesc_size;
  char* text;
  bool use_benchmark_output;

  void EnableBenchmark();
  char* BenchmarkOutput();
  char* PrintToZone();

  // Used to aggregate stats.
  void Add(const CompilerStats& other);
  void Clear();

  bool IsCleared() const;

 private:
  // Update stats that are computed, e.g. token count.
  void Update();
};

// Make increment atomic in case it occurs in parallel with aggregation from
// other thread.
#define INC_STAT(thread, counter, incr)                                        \
  if (FLAG_support_compiler_stats && FLAG_compiler_stats) {                    \
    AtomicOperations::IncrementInt64By(&(thread)->compiler_stats()->counter,   \
                                       (incr));                                \
  }

#define STAT_VALUE(thread, counter)                                            \
  ((FLAG_support_compiler_stats && FLAG_compiler_stats)                        \
       ? (thread)->compiler_stats()->counter                                   \
       : 0)

#define CSTAT_TIMER_SCOPE(thr, t)                                              \
  TimerScope timer(FLAG_support_compiler_stats&& FLAG_compiler_stats,          \
                   (FLAG_support_compiler_stats && FLAG_compiler_stats)        \
                       ? &((thr)->compiler_stats()->t)                         \
                       : NULL,                                                 \
                   thr);

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_STATS_H_
