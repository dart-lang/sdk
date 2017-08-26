// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler_stats.h"

#include "vm/flags.h"
#include "vm/log.h"
#include "vm/object_graph.h"
#include "vm/object_store.h"
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(bool, compiler_stats, false, "Compiler stat counters.");
DEFINE_FLAG(bool,
            compiler_benchmark,
            false,
            "Compiler stat counters for benchmark.");

class TokenStreamVisitor : public ObjectVisitor {
 public:
  explicit TokenStreamVisitor(CompilerStats* compiler_stats)
      : obj_(Object::Handle()), stats_(compiler_stats) {}

  void VisitObject(RawObject* raw_obj) {
    if (raw_obj->IsPseudoObject()) {
      return;  // Cannot be wrapped in handles.
    }
    obj_ = raw_obj;
    if (obj_.GetClassId() == TokenStream::kClassId) {
      TokenStream::Iterator tkit(
          Thread::Current()->zone(), TokenStream::Cast(obj_),
          TokenPosition::kMinSource, TokenStream::Iterator::kNoNewlines);
      Token::Kind kind = tkit.CurrentTokenKind();
      while (kind != Token::kEOS) {
        ++stats_->num_tokens_total;
        tkit.Advance();
        kind = tkit.CurrentTokenKind();
      }
    }
  }

 private:
  Object& obj_;
  CompilerStats* stats_;
};

CompilerStats::CompilerStats(Isolate* isolate)
    : isolate_(isolate),
#define INITIALIZE_TIMER(timer_name, description) timer_name(true, description),
      STAT_TIMERS(INITIALIZE_TIMER)
#undef INITIALIZE_TIMER

#define INITIALIZE_COUNTERS(counter_name) counter_name(0),
          STAT_COUNTERS(INITIALIZE_COUNTERS)
#undef INITIALIZE_COUNTERS
              text(NULL),
      use_benchmark_output(false) {
}

#ifndef PRODUCT

// Used to aggregate stats. Must be atomic.
void CompilerStats::Add(const CompilerStats& other) {
#define ADD_TOTAL(timer_name, literal) timer_name.AddTotal(other.timer_name);

  STAT_TIMERS(ADD_TOTAL)
#undef ADD_TOTAL

#define ADD_COUNTER(counter_name)                                              \
  AtomicOperations::IncrementInt64By(&counter_name, other.counter_name);

  STAT_COUNTERS(ADD_COUNTER)
#undef ADD_COUNTER
}

void CompilerStats::Clear() {
#define CLEAR_TIMER(timer_name, literal) timer_name.Reset();

  STAT_TIMERS(CLEAR_TIMER)
#undef CLEAR_TIMER

#define CLEAR_COUNTER(counter_name) counter_name = 0;

  STAT_COUNTERS(CLEAR_COUNTER)
#undef CLEAR_COUNTER
}

bool CompilerStats::IsCleared() const {
#define CHECK_TIMERS(timer_name, literal)                                      \
  if (!timer_name.IsReset()) return false;

  STAT_TIMERS(CHECK_TIMERS)
#undef CHECK_TIMERS

#define CHECK_COUNTERS(counter_name)                                           \
  if (counter_name != 0) return false;

  STAT_COUNTERS(CHECK_COUNTERS)
#undef CHECK_COUNTERS
  return true;
}

// This function is used as a callback in the log object to which the
// compiler stats are printed. It will be called only once, to print
// the accumulated text when all of the compiler stats values are
// added to the log.
static void PrintToStats(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
static void PrintToStats(const char* format, ...) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CompilerStats* stats = isolate->aggregate_compiler_stats();
  Zone* zone = thread->zone();
  ASSERT(stats != NULL);
  va_list args;
  va_start(args, format);
  stats->text = zone->VPrint(format, args);
  va_end(args);
}

void CompilerStats::Update() {
  // Traverse the heap and compute number of tokens in all
  // TokenStream objects.
  num_tokens_total = 0;

  {
    HeapIterationScope iteration(Thread::Current());
    TokenStreamVisitor visitor(this);
    iteration.IterateObjects(&visitor);
    iteration.IterateVMIsolateObjects(&visitor);
  }
}

void CompilerStats::EnableBenchmark() {
  FLAG_compiler_stats = true;
  use_benchmark_output = true;
}

// Generate output for Golem benchmark harness. If the output format
// changes, the parsing function in Golem must be updated.
char* CompilerStats::BenchmarkOutput() {
  Update();
  Log log(PrintToStats);
  LogBlock lb(Thread::Current(), &log);
  log.Print("==== Compiler Stats for isolate (%" Pd64 ") '%s' ====\n",
            static_cast<int64_t>(isolate_->main_port()), isolate_->name());

  log.Print("NumberOfTokens: %" Pd64 "\n", num_tokens_total);
  log.Print("NumClassesParsed: %" Pd64 "\n", num_classes_parsed);
  log.Print("NumFunctionsCompiled: %" Pd64 "\n", num_functions_compiled);
  log.Print("NumFunctionsOptimized: %" Pd64 "\n", num_functions_optimized);
  log.Print("NumFunctionsParsed: %" Pd64 "\n", num_functions_parsed);

  // Scanner stats.
  int64_t scan_usecs = scanner_timer.TotalElapsedTime();
  int64_t scan_speed =
      scan_usecs > 0 ? 1000 * num_tokens_scanned / scan_usecs : 0;
  log.Print("NumTokensScanned: %" Pd64 " tokens\n", num_tokens_scanned);
  log.Print("ScannerTime: %" Pd64 " ms\n", scan_usecs / 1000);
  log.Print("ScannerSpeed: %" Pd64 " tokens/ms\n", scan_speed);

  // Parser stats.
  int64_t parse_usecs = parser_timer.TotalElapsedTime();
  int64_t parse_speed =
      parse_usecs > 0 ? 1000 * num_tokens_consumed / parse_usecs : 0;
  log.Print("NumTokensParsed: %" Pd64 " tokens\n", num_tokens_consumed);
  log.Print("ParserTime: %" Pd64 " ms\n", parse_usecs / 1000);
  log.Print("ParserSpeed: %" Pd64 " tokens/ms\n", parse_speed);

  // Compiler stats.
  int64_t codegen_usecs = codegen_timer.TotalElapsedTime();
  int64_t compile_usecs = scan_usecs + parse_usecs + codegen_usecs;
  int64_t compile_speed =
      compile_usecs > 0 ? (1000 * num_func_tokens_compiled / compile_usecs) : 0;
  log.Print("NumTokensCompiled: %" Pd64 " tokens\n", num_func_tokens_compiled);
  log.Print("CompilerTime: %" Pd64 " ms\n", compile_usecs / 1000);

  log.Print("CompilerSpeed: %" Pd64 " tokens/ms\n", compile_speed);
  log.Print("CodeSize: %" Pd64 " KB\n", total_code_size / 1024);
  int64_t code_density =
      total_instr_size > 0
          ? (num_func_tokens_compiled * 1024) / total_instr_size
          : 0;

  log.Print("CodeDensity: %" Pd64 " tokens/KB\n", code_density);
  log.Print("InstrSize: %" Pd64 " KB\n", total_instr_size / 1024);
  log.Flush();
  char* benchmark_text = text;
  text = NULL;
  return benchmark_text;
}

char* CompilerStats::PrintToZone() {
  if (!FLAG_compiler_stats) {
    return NULL;
  } else if (use_benchmark_output) {
    return BenchmarkOutput();
  }

  Update();

  Log log(PrintToStats);
  LogBlock lb(Thread::Current(), &log);

  log.Print("==== Compiler Stats for isolate  (%" Pd64 ") '%s' ====\n",
            static_cast<int64_t>(isolate_->main_port()), isolate_->name());
  log.Print("Number of tokens:        %" Pd64 "\n", num_tokens_total);
  log.Print("Source length:           %" Pd64 " characters\n", src_length);
  log.Print("Number of source tokens: %" Pd64 "\n", num_tokens_scanned);

  int64_t num_local_functions =
      GrowableObjectArray::Handle(isolate_->object_store()->closure_functions())
          .Length();

  log.Print("==== Parser stats:\n");
  log.Print("Total tokens consumed:   %" Pd64 "\n", num_tokens_consumed);
  log.Print("Classes parsed:          %" Pd64 "\n", num_classes_parsed);
  log.Print("  Tokens consumed:       %" Pd64 "\n", num_class_tokens);
  log.Print("Functions parsed:        %" Pd64 "\n", num_functions_parsed);
  log.Print("  Tokens consumed:       %" Pd64 "\n", num_func_tokens_compiled);
  log.Print("Impl getter funcs:       %" Pd64 "\n", num_implicit_final_getters);
  log.Print("Impl method extractors:  %" Pd64 "\n", num_method_extractors);
  log.Print("Local functions:         %" Pd64 "\n", num_local_functions);
  log.Print("Consts cached:           %" Pd64 "\n", num_cached_consts);
  log.Print("Consts cache hits:       %" Pd64 "\n", num_const_cache_hits);
  log.Print("Consts calcuated:        %" Pd64 "\n", num_execute_const);

  int64_t scan_usecs = scanner_timer.TotalElapsedTime();
  log.Print("Scanner time:            %" Pd64 " ms\n", scan_usecs / 1000);
  int64_t scan_speed =
      scan_usecs > 0 ? 1000 * num_tokens_consumed / scan_usecs : 0;
  log.Print("Scanner speed:           %" Pd64 " tokens/ms\n", scan_speed);
  int64_t parse_usecs = parser_timer.TotalElapsedTime();
  int64_t parse_speed =
      parse_usecs > 0 ? 1000 * num_tokens_consumed / parse_usecs : 0;
  log.Print("Parser time:             %" Pd64 " ms\n", parse_usecs / 1000);
  log.Print("Parser speed:            %" Pd64 " tokens/ms\n", parse_speed);

  int64_t codegen_usecs = codegen_timer.TotalElapsedTime();

  log.Print("==== Backend stats:\n");
  log.Print("Code gen. time:          %" Pd64 " ms\n", codegen_usecs / 1000);
  int64_t graphbuilder_usecs = graphbuilder_timer.TotalElapsedTime();
  log.Print("  Graph builder:         %" Pd64 " ms\n",
            graphbuilder_usecs / 1000);
  int64_t ssa_usecs = ssa_timer.TotalElapsedTime();
  log.Print("  Graph SSA:             %" Pd64 " ms\n", ssa_usecs / 1000);

  int64_t graphinliner_usecs = graphinliner_timer.TotalElapsedTime();
  log.Print("  Graph inliner:         %" Pd64 " ms\n",
            graphinliner_usecs / 1000);
  int64_t graphinliner_parse_usecs =
      graphinliner_parse_timer.TotalElapsedTime();
  log.Print("    Parsing:             %" Pd64 " ms\n",
            graphinliner_parse_usecs / 1000);
  int64_t graphinliner_build_usecs =
      graphinliner_build_timer.TotalElapsedTime();
  log.Print("    Building:            %" Pd64 " ms\n",
            graphinliner_build_usecs / 1000);
  int64_t graphinliner_ssa_usecs = graphinliner_ssa_timer.TotalElapsedTime();
  log.Print("    SSA:                 %" Pd64 " ms\n",
            graphinliner_ssa_usecs / 1000);
  int64_t graphinliner_opt_usecs = graphinliner_opt_timer.TotalElapsedTime();
  log.Print("    Optimization:        %" Pd64 " ms\n",
            graphinliner_opt_usecs / 1000);
  int64_t graphinliner_subst_usecs =
      graphinliner_subst_timer.TotalElapsedTime();
  log.Print("    Substitution:        %" Pd64 " ms\n",
            graphinliner_subst_usecs / 1000);
  int64_t graphoptimizer_usecs = graphoptimizer_timer.TotalElapsedTime();
  log.Print("  Graph optimizer:       %" Pd64 " ms\n",
            (graphoptimizer_usecs - graphinliner_usecs) / 1000);
  int64_t graphcompiler_usecs = graphcompiler_timer.TotalElapsedTime();
  log.Print("  Graph compiler:        %" Pd64 " ms\n",
            graphcompiler_usecs / 1000);
  int64_t codefinalizer_usecs = codefinalizer_timer.TotalElapsedTime();
  log.Print("  Code finalizer:        %" Pd64 " ms\n",
            codefinalizer_usecs / 1000);

  log.Print("==== Compiled code stats:\n");
  int64_t compile_usecs = scan_usecs + parse_usecs + codegen_usecs;
  int64_t compile_speed =
      compile_usecs > 0 ? (1000 * num_func_tokens_compiled / compile_usecs) : 0;
  log.Print("Functions parsed:        %" Pd64 "\n", num_functions_parsed);
  log.Print("Functions compiled:      %" Pd64 "\n", num_functions_compiled);
  log.Print("  optimized:             %" Pd64 "\n", num_functions_optimized);
  log.Print("Compiler time:           %" Pd64 " ms\n", compile_usecs / 1000);
  log.Print("Tokens compiled:         %" Pd64 "\n", num_func_tokens_compiled);
  log.Print("Compilation speed:       %" Pd64 " tokens/ms\n", compile_speed);
  int64_t code_density =
      total_instr_size > 0
          ? (num_func_tokens_compiled * 1024) / total_instr_size
          : 0;
  log.Print("Code density:            %" Pd64 " tokens per KB\n", code_density);
  log.Print("Code size:               %" Pd64 " KB\n", total_code_size / 1024);
  log.Print("  Instr size:            %" Pd64 " KB\n", total_instr_size / 1024);
  log.Print("  Pc Desc size:          %" Pd64 " KB\n", pc_desc_size / 1024);
  log.Print("  VarDesc size:          %" Pd64 " KB\n", vardesc_size / 1024);
  log.Flush();
  char* stats_text = text;
  text = NULL;
  return stats_text;
}

#endif  // !PRODUCT

}  // namespace dart
