// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler_stats.h"

#include "vm/flags.h"
#include "vm/log.h"
#include "vm/object_graph.h"
#include "vm/timer.h"


namespace dart {

DEFINE_FLAG(bool, compiler_stats, false, "Compiler stat counters.");


class TokenStreamVisitor : public ObjectVisitor {
 public:
  TokenStreamVisitor(Isolate* isolate, CompilerStats* compiler_stats)
      : ObjectVisitor(isolate),
        obj_(Object::Handle()),
        stats_(compiler_stats) {
  }

  void VisitObject(RawObject* raw_obj) {
    if (raw_obj->IsFreeListElement()) {
      return;
    }
    obj_ = raw_obj;
    if (obj_.GetClassId() == TokenStream::kClassId) {
      TokenStream::Iterator tkit(TokenStream::Cast(obj_),
                                 0,
                                 TokenStream::Iterator::kNoNewlines);
      Token::Kind kind = tkit.CurrentTokenKind();
      while (kind != Token::kEOS) {
        ++stats_->num_tokens_total;
        if (kind == Token::kIDENT) {
          ++stats_->num_ident_tokens_total;
        } else if (Token::NeedsLiteralToken(kind)) {
          ++stats_->num_literal_tokens_total;
        }
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
      parser_timer(true, "parser timer"),
      scanner_timer(true, "scanner timer"),
      codegen_timer(true, "codegen timer"),
      graphbuilder_timer(true, "flow graph builder timer"),
      ssa_timer(true, "flow graph SSA timer"),
      graphinliner_timer(true, "flow graph inliner timer"),
      graphinliner_parse_timer(true, "inliner parsing timer"),
      graphinliner_build_timer(true, "inliner building timer"),
      graphinliner_ssa_timer(true, "inliner SSA timer"),
      graphinliner_opt_timer(true, "inliner optimization timer"),
      graphinliner_subst_timer(true, "inliner substitution timer"),
      graphoptimizer_timer(true, "flow graph optimizer timer"),
      graphcompiler_timer(true, "flow graph compiler timer"),
      codefinalizer_timer(true, "code finalization timer"),
      num_tokens_total(0),
      num_literal_tokens_total(0),
      num_ident_tokens_total(0),
      num_tokens_consumed(0),
      num_cached_consts(0),
      num_const_cache_hits(0),
      num_classes_parsed(0),
      num_class_tokens(0),
      num_functions_parsed(0),
      num_functions_compiled(0),
      num_functions_optimized(0),
      num_func_tokens_compiled(0),
      num_implicit_final_getters(0),
      num_method_extractors(0),
      src_length(0),
      total_code_size(0),
      total_instr_size(0),
      pc_desc_size(0),
      vardesc_size(0),
      text(NULL) {
}


// This function is used as a callback in the log object to which the
// compiler stats are printed. It will be called only once, to print
// the accumulated text when all of the compiler stats values are
// added to the log.
static void PrintToStats(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);
static void PrintToStats(const char* format, ...) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  CompilerStats* stats = isolate->compiler_stats();
  Zone* zone = thread->zone();
  ASSERT(stats != NULL);
  va_list args;
  va_start(args, format);
  stats->text = zone->VPrint(format, args);
  va_end(args);
}


char* CompilerStats::PrintToZone() {
  if (!FLAG_compiler_stats) {
    return NULL;
  }

  // Traverse the heap and compute number of tokens in all
  // TokenStream objects.
  num_tokens_total = 0;
  num_literal_tokens_total = 0;
  num_ident_tokens_total = 0;
  TokenStreamVisitor visitor(isolate_, this);
  isolate_->heap()->IterateObjects(&visitor);
  Dart::vm_isolate()->heap()->IterateObjects(&visitor);

  Log log(PrintToStats);
  LogBlock lb(isolate_, &log);

  log.Print("==== Compiler Stats for isolate '%s' ====\n",
            isolate_->debugger_name());
  log.Print("Number of tokens:        %" Pd64 "\n", num_tokens_total);
  log.Print("  Literal tokens:        %" Pd64 "\n", num_literal_tokens_total);
  log.Print("  Ident tokens:          %" Pd64 "\n", num_ident_tokens_total);
  log.Print("Source length:           %" Pd64 " characters\n", src_length);

  log.Print("==== Parser stats:\n");
  log.Print("Total tokens consumed:   %" Pd64 "\n", num_tokens_consumed);
  log.Print("Classes parsed:          %" Pd64 "\n", num_classes_parsed);
  log.Print("  Tokens consumed:       %" Pd64 "\n", num_class_tokens);
  log.Print("Functions parsed:        %" Pd64 "\n", num_functions_parsed);
  log.Print("  Tokens consumed:       %" Pd64 "\n", num_func_tokens_compiled);
  log.Print("Impl getter funcs:       %" Pd64 "\n", num_implicit_final_getters);
  log.Print("Impl method extractors:  %" Pd64 "\n", num_method_extractors);
  log.Print("Consts cached:           %" Pd64 "\n", num_cached_consts);
  log.Print("Consts cache hits:       %" Pd64 "\n", num_const_cache_hits);

  int64_t scan_usecs = scanner_timer.TotalElapsedTime();
  log.Print("Scanner time:            %" Pd64 " msecs\n", scan_usecs / 1000);
  int64_t parse_usecs = parser_timer.TotalElapsedTime();
  log.Print("Parser time:             %" Pd64 " msecs\n", parse_usecs / 1000);
  log.Print("Parser speed:            %" Pd64 " tokens per msec\n",
            1000 * num_tokens_consumed / parse_usecs);
  int64_t codegen_usecs = codegen_timer.TotalElapsedTime();

  log.Print("==== Backend stats:\n");
  log.Print("Code gen. time:          %" Pd64 " msecs\n",
            codegen_usecs / 1000);
  int64_t graphbuilder_usecs = graphbuilder_timer.TotalElapsedTime();
  log.Print("  Graph builder:         %" Pd64 " msecs\n",
            graphbuilder_usecs / 1000);
  int64_t ssa_usecs = ssa_timer.TotalElapsedTime();
  log.Print("  Graph SSA:             %" Pd64 " msecs\n", ssa_usecs / 1000);

  int64_t graphinliner_usecs = graphinliner_timer.TotalElapsedTime();
  log.Print("  Graph inliner:         %" Pd64 " msecs\n",
            graphinliner_usecs / 1000);
  int64_t graphinliner_parse_usecs =
      graphinliner_parse_timer.TotalElapsedTime();
  log.Print("    Parsing:             %" Pd64 " msecs\n",
            graphinliner_parse_usecs / 1000);
  int64_t graphinliner_build_usecs =
      graphinliner_build_timer.TotalElapsedTime();
  log.Print("    Building:            %" Pd64 " msecs\n",
            graphinliner_build_usecs / 1000);
  int64_t graphinliner_ssa_usecs = graphinliner_ssa_timer.TotalElapsedTime();
  log.Print("    SSA:                 %" Pd64 " msecs\n",
            graphinliner_ssa_usecs / 1000);
  int64_t graphinliner_opt_usecs = graphinliner_opt_timer.TotalElapsedTime();
  log.Print("    Optimization:        %" Pd64 " msecs\n",
            graphinliner_opt_usecs / 1000);
  int64_t graphinliner_subst_usecs =
      graphinliner_subst_timer.TotalElapsedTime();
  log.Print("    Substitution:        %" Pd64 " msecs\n",
            graphinliner_subst_usecs / 1000);
  int64_t graphoptimizer_usecs = graphoptimizer_timer.TotalElapsedTime();
  log.Print("  Graph optimizer:       %" Pd64 " msecs\n",
            (graphoptimizer_usecs - graphinliner_usecs) / 1000);
  int64_t graphcompiler_usecs = graphcompiler_timer.TotalElapsedTime();
  log.Print("  Graph compiler:        %" Pd64 " msecs\n",
            graphcompiler_usecs / 1000);
  int64_t codefinalizer_usecs = codefinalizer_timer.TotalElapsedTime();
  log.Print("  Code finalizer:        %" Pd64 " msecs\n",
            codefinalizer_usecs / 1000);

  log.Print("==== Compiled code stats:\n");
  log.Print("Functions parsed:        %" Pd64 "\n", num_functions_parsed);
  log.Print("Functions compiled:      %" Pd64 "\n", num_functions_compiled);
  log.Print("  optimized:             %" Pd64 "\n", num_functions_optimized);
  log.Print("Tokens compiled:         %" Pd64 "\n", num_func_tokens_compiled);
  log.Print("Compilation speed:       %" Pd64 " tokens per msec\n",
            (1000 * num_func_tokens_compiled) / (parse_usecs + codegen_usecs));
  log.Print("Code density:            %" Pd64 " tokens per KB\n",
            (num_func_tokens_compiled * 1024) / total_instr_size);
  log.Print("Code size:               %" Pd64 " KB\n", total_code_size / 1024);
  log.Print("  Instr size:            %" Pd64 " KB\n",
            total_instr_size / 1024);
  log.Print("  Pc Desc size:          %" Pd64 " KB\n", pc_desc_size / 1024);
  log.Print("  VarDesc size:          %" Pd64 " KB\n", vardesc_size / 1024);
  log.Flush();
  char* stats_text = text;
  text = NULL;
  return stats_text;
}

}  // namespace dart
