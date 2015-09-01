// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler_stats.h"

#include "vm/flags.h"
#include "vm/object_graph.h"
#include "vm/timer.h"


namespace dart {

DEFINE_FLAG(bool, compiler_stats, false, "Compiler stat counters.");


class TokenStreamVisitor : public ObjectGraph::Visitor {
 public:
  explicit TokenStreamVisitor(CompilerStats* compiler_stats)
      : obj_(Object::Handle()), stats_(compiler_stats) {
  }

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    RawObject* raw_obj = it->Get();
    if (raw_obj->IsFreeListElement()) {
      return kProceed;
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
    return kProceed;
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
      num_token_checks(0),
      num_tokens_lookahead(0),
      num_cached_consts(0),
      num_const_cache_hits(0),
      num_classes_compiled(0),
      num_functions_compiled(0),
      num_implicit_final_getters(0),
      src_length(0),
      total_code_size(0),
      total_instr_size(0),
      pc_desc_size(0),
      vardesc_size(0) {
}


void CompilerStats::Print() {
  if (!FLAG_compiler_stats) {
    return;
  }

  // Traverse the heap and compute number of tokens in all
  // TokenStream objects.
  num_tokens_total = 0;
  num_literal_tokens_total = 0;
  num_ident_tokens_total = 0;
  TokenStreamVisitor visitor(this);
  ObjectGraph graph(isolate_);
  graph.IterateObjects(&visitor);

  OS::Print("==== Compiler Stats for isolate '%s' ====\n",
            isolate_->debugger_name());
  OS::Print("Number of tokens:   %" Pd64 "\n", num_tokens_total);
  OS::Print("  Literal tokens:   %" Pd64 "\n", num_literal_tokens_total);
  OS::Print("  Ident tokens:     %" Pd64 "\n", num_ident_tokens_total);
  OS::Print("Tokens consumed:    %" Pd64 " (%.2f times number of tokens)\n",
            num_tokens_consumed,
            (1.0 * num_tokens_consumed) / num_tokens_total);
  OS::Print("Tokens checked:     %" Pd64 "  (%.2f times tokens consumed)\n",
            num_token_checks, (1.0 * num_token_checks) / num_tokens_consumed);
  OS::Print("Token lookahead:    %" Pd64 " (%" Pd64 "%% of tokens checked)\n",
            num_tokens_lookahead,
            (100 * num_tokens_lookahead) / num_token_checks);
  OS::Print("Consts cached:      %" Pd64 "\n", num_cached_consts);
  OS::Print("Consts cache hits:  %" Pd64 "\n", num_const_cache_hits);

  OS::Print("Classes parsed:     %" Pd64 "\n", num_classes_compiled);
  OS::Print("Functions compiled: %" Pd64 "\n", num_functions_compiled);
  OS::Print("  Impl getters:     %" Pd64 "\n", num_implicit_final_getters);

  OS::Print("Source length:      %" Pd64 " characters\n", src_length);
  int64_t scan_usecs = scanner_timer.TotalElapsedTime();
  OS::Print("Scanner time:       %" Pd64 " msecs\n",
            scan_usecs / 1000);
  int64_t parse_usecs = parser_timer.TotalElapsedTime();
  OS::Print("Parser time:        %" Pd64 " msecs\n",
            parse_usecs / 1000);
  int64_t codegen_usecs = codegen_timer.TotalElapsedTime();
  OS::Print("Code gen. time:     %" Pd64 " msecs\n",
            codegen_usecs / 1000);
  int64_t graphbuilder_usecs = graphbuilder_timer.TotalElapsedTime();
  OS::Print("  Graph builder:    %" Pd64 " msecs\n", graphbuilder_usecs / 1000);
  int64_t ssa_usecs = ssa_timer.TotalElapsedTime();
  OS::Print("  Graph SSA:        %" Pd64 " msecs\n", ssa_usecs / 1000);

  int64_t graphinliner_usecs = graphinliner_timer.TotalElapsedTime();
  OS::Print("  Graph inliner:    %" Pd64 " msecs\n", graphinliner_usecs / 1000);
  int64_t graphinliner_parse_usecs =
      graphinliner_parse_timer.TotalElapsedTime();
  OS::Print("    Parsing:        %" Pd64 " msecs\n",
            graphinliner_parse_usecs / 1000);
  int64_t graphinliner_build_usecs =
      graphinliner_build_timer.TotalElapsedTime();
  OS::Print("    Building:       %" Pd64 " msecs\n",
            graphinliner_build_usecs / 1000);
  int64_t graphinliner_ssa_usecs = graphinliner_ssa_timer.TotalElapsedTime();
  OS::Print("    SSA:            %" Pd64 " msecs\n",
            graphinliner_ssa_usecs / 1000);
  int64_t graphinliner_opt_usecs = graphinliner_opt_timer.TotalElapsedTime();
  OS::Print("    Optimization:   %" Pd64 " msecs\n",
            graphinliner_opt_usecs / 1000);
  int64_t graphinliner_subst_usecs =
      graphinliner_subst_timer.TotalElapsedTime();
  OS::Print("    Substitution:   %" Pd64 " msecs\n",
            graphinliner_subst_usecs / 1000);

  int64_t graphoptimizer_usecs = graphoptimizer_timer.TotalElapsedTime();
  OS::Print("  Graph optimizer:  %" Pd64 " msecs\n",
            (graphoptimizer_usecs - graphinliner_usecs) / 1000);
  int64_t graphcompiler_usecs = graphcompiler_timer.TotalElapsedTime();
  OS::Print("  Graph compiler:   %" Pd64 " msecs\n",
            graphcompiler_usecs / 1000);
  int64_t codefinalizer_usecs = codefinalizer_timer.TotalElapsedTime();
  OS::Print("  Code finalizer:   %" Pd64 " msecs\n",
            codefinalizer_usecs / 1000);
  OS::Print("Compilation speed:  %" Pd64 " tokens per msec\n",
            (1000 * num_tokens_total) / (parse_usecs + codegen_usecs));
  OS::Print("Code density:       %" Pd64 " tokens per KB\n",
            (num_tokens_total * 1024) / total_instr_size);
  OS::Print("Instr size:         %" Pd64 " KB\n",
            total_instr_size / 1024);
  OS::Print("Pc Desc size:       %" Pd64 " KB\n", pc_desc_size / 1024);
  OS::Print("VarDesc size:       %" Pd64 " KB\n", vardesc_size / 1024);

  OS::Print("Code size:          %" Pd64 " KB\n", total_code_size / 1024);
}

}  // namespace dart
