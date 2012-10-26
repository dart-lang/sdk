// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler_stats.h"

#include "vm/flags.h"
#include "vm/timer.h"


namespace dart {

DEFINE_FLAG(bool, compiler_stats, false, "Compiler stat counters.");

// Bytes allocated for generated code.
intptr_t CompilerStats::code_allocated = 0;

// Total number of characters in source.
intptr_t CompilerStats::src_length = 0;

// Cumulative runtime of parser.
Timer CompilerStats::parser_timer(true, "parser timer");

// Cumulative runtime of scanner.
Timer CompilerStats::scanner_timer(true, "scanner timer");

// Cumulative runtime of code generator.
Timer CompilerStats::codegen_timer(true, "codegen timer");

// Cumulative timer of flow graph builder, included in codegen_timer.
Timer CompilerStats::graphbuilder_timer(true, "flow graph builder timer");

// Cumulative timer of flow graph SSA construction, included in codegen_timer.
Timer CompilerStats::ssa_timer(true, "flow graph SSA timer");

// Cumulative timer of flow graph inliner, included in codegen_timer.
Timer CompilerStats::graphinliner_timer(true, "flow graph inliner timer");
// Cumulative sub-timers of flow graph inliner.
Timer CompilerStats::graphinliner_parse_timer(true, "inliner parsing timer");
Timer CompilerStats::graphinliner_build_timer(true, "inliner building timer");
Timer CompilerStats::graphinliner_ssa_timer(true, "inliner SSA timer");
Timer CompilerStats::graphinliner_opt_timer(true, "inliner optimization timer");
Timer CompilerStats::graphinliner_subst_timer(true,
                                              "inliner substitution timer");

// Cumulative timer of flow graph optimizer, included in codegen_timer.
Timer CompilerStats::graphoptimizer_timer(true, "flow graph optimizer timer");

// Cumulative timer of flow graph compiler, included in codegen_timer.
Timer CompilerStats::graphcompiler_timer(true, "flow graph compiler timer");

// Cumulative timer of code finalization, included in codegen_timer.
Timer CompilerStats::codefinalizer_timer(true, "code finalization timer");


intptr_t CompilerStats::num_tokens_total = 0;
intptr_t CompilerStats::num_literal_tokens_total = 0;
intptr_t CompilerStats::num_ident_tokens_total = 0;
intptr_t CompilerStats::num_tokens_consumed = 0;
intptr_t CompilerStats::num_token_checks = 0;
intptr_t CompilerStats::num_tokens_rewind = 0;
intptr_t CompilerStats::num_tokens_lookahead = 0;

void CompilerStats::Print() {
  if (!FLAG_compiler_stats) {
    return;
  }
  OS::Print("==== Compiler Stats ====\n");
  OS::Print("Number of tokens:   %"Pd"\n", num_tokens_total);
  OS::Print("  Literal tokens:   %"Pd"\n", num_literal_tokens_total);
  OS::Print("  Ident tokens:     %"Pd"\n", num_ident_tokens_total);
  OS::Print("Tokens consumed:    %"Pd" (%.2f times number of tokens)\n",
            num_tokens_consumed,
            (1.0 * num_tokens_consumed) / num_tokens_total);
  OS::Print("Tokens checked:     %"Pd"  (%.2f times tokens consumed)\n",
            num_token_checks, (1.0 * num_token_checks) / num_tokens_consumed);
  OS::Print("Token rewind:       %"Pd" (%"Pd"%% of tokens checked)\n",
            num_tokens_rewind, (100 * num_tokens_rewind) / num_token_checks);
  OS::Print("Token lookahead:    %"Pd" (%"Pd"%% of tokens checked)\n",
            num_tokens_lookahead,
            (100 * num_tokens_lookahead) / num_token_checks);
  OS::Print("Source length:      %"Pd" characters\n", src_length);
  int64_t scan_usecs = scanner_timer.TotalElapsedTime();
  OS::Print("Scanner time:       %"Pd64" msecs\n",
            scan_usecs / 1000);
  int64_t parse_usecs = parser_timer.TotalElapsedTime();
  OS::Print("Parser time:        %"Pd64" msecs\n",
            parse_usecs / 1000);
  int64_t codegen_usecs = codegen_timer.TotalElapsedTime();
  OS::Print("Code gen. time:     %"Pd64" msecs\n",
            codegen_usecs / 1000);
  int64_t graphbuilder_usecs = graphbuilder_timer.TotalElapsedTime();
  OS::Print("  Graph builder:    %"Pd64" msecs\n", graphbuilder_usecs / 1000);
  int64_t ssa_usecs = ssa_timer.TotalElapsedTime();
  OS::Print("  Graph SSA:        %"Pd64" msecs\n", ssa_usecs / 1000);

  int64_t graphinliner_usecs = graphinliner_timer.TotalElapsedTime();
  OS::Print("  Graph inliner:    %"Pd64" msecs\n", graphinliner_usecs / 1000);
  int64_t graphinliner_parse_usecs =
      graphinliner_parse_timer.TotalElapsedTime();
  OS::Print("    Parsing:        %"Pd64" msecs\n",
            graphinliner_parse_usecs / 1000);
  int64_t graphinliner_build_usecs =
      graphinliner_build_timer.TotalElapsedTime();
  OS::Print("    Building:       %"Pd64" msecs\n",
            graphinliner_build_usecs / 1000);
  int64_t graphinliner_ssa_usecs = graphinliner_ssa_timer.TotalElapsedTime();
  OS::Print("    SSA:            %"Pd64" msecs\n",
            graphinliner_ssa_usecs / 1000);
  int64_t graphinliner_opt_usecs = graphinliner_opt_timer.TotalElapsedTime();
  OS::Print("    Optimization:   %"Pd64" msecs\n",
            graphinliner_opt_usecs / 1000);
  int64_t graphinliner_subst_usecs =
      graphinliner_subst_timer.TotalElapsedTime();
  OS::Print("    Substitution:   %"Pd64" msecs\n",
            graphinliner_subst_usecs / 1000);

  int64_t graphoptimizer_usecs = graphoptimizer_timer.TotalElapsedTime();
  OS::Print("  Graph optimizer:  %"Pd64" msecs\n",
            (graphoptimizer_usecs - graphinliner_usecs) / 1000);
  int64_t graphcompiler_usecs = graphcompiler_timer.TotalElapsedTime();
  OS::Print("  Graph compiler:   %"Pd64" msecs\n",
            graphcompiler_usecs / 1000);
  int64_t codefinalizer_usecs = codefinalizer_timer.TotalElapsedTime();
  OS::Print("  Code finalizer:   %"Pd64" msecs\n",
            codefinalizer_usecs / 1000);
  OS::Print("Compilation speed:  %"Pd64" tokens per msec\n",
            1000 * num_tokens_total / (parse_usecs + codegen_usecs));
  OS::Print("Code size:          %"Pd" KB\n",
            code_allocated / 1024);
  OS::Print("Code density:       %"Pd" tokens per KB\n",
            num_tokens_total * 1024 / code_allocated);
}

}  // namespace dart
