// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLAG_LIST_H_
#define VM_FLAG_LIST_H_

// List of all flags in the VM.
// Flags can be one of three categories:
// * P roduct flags: Can be set in any of the deployment modes, including in
//   production.
// * D ebug flags: Can only be set in debug VMs, which also have assertions
//   enabled.
// * R elease flags: Generally available flags except when building product.

#define FLAG_LIST(P, R, D)                                                     \
R(dedup_instructions, true, bool, false,                                       \
  "Canonicalize instructions when precompiling.")                              \
R(disable_alloc_stubs_after_gc, false, bool, false,                            \
  "Stress testing flag.")                                                      \
R(disassemble, false, bool, false,                                             \
  "Disassemble dart code.")                                                    \
R(disassemble_optimized, false, bool, false,                                   \
  "Disassemble optimized code.")                                               \
R(dump_symbol_stats, false, bool, false,                                       \
  "Dump symbol table statistics")                                              \
R(gc_at_alloc, false, bool, false,                                             \
  "GC at every allocation.")                                                   \
P(new_gen_ext_limit, int, 64,                                                  \
  "maximum total external size (MB) in new gen before triggering GC")          \
R(pretenure_all, false, bool, false,                                           \
  "Global pretenuring (for testing).")                                         \
P(pretenure_interval, int, 10,                                                 \
  "Back off pretenuring after this many cycles.")                              \
P(pretenure_threshold, int, 98,                                                \
  "Trigger pretenuring when this many percent are promoted.")                  \
R(profiler, false, bool, true,                                                 \
  "Enable the profiler.")                                                      \
R(support_ast_printer, false, bool, true,                                      \
  "Support the AST printer.")                                                  \
R(support_debugger, false, bool, true,                                         \
  "Support the debugger.")                                                     \
R(support_disassembler, false, bool, true,                                     \
  "Support the disassembler.")                                                 \
R(support_il_printer, false, bool, true,                                       \
  "Support the IL printer.")                                                   \
R(support_service, false, bool, true,                                          \
  "Support the service protocol.")                                             \
R(support_coverage, false, bool, true,                                         \
  "Support code coverage.")                                                    \
R(support_timeline, false, bool, true,                                         \
  "Support timeline.")                                                         \
D(trace_handles, bool, false,                                                  \
  "Traces allocation of handles.")                                             \
D(trace_zones, bool, false,                                                    \
  "Traces allocation sizes in the zone.")                                      \
P(verbose_gc, bool, false,                                                     \
  "Enables verbose GC.")                                                       \
P(verbose_gc_hdr, int, 40,                                                     \
  "Print verbose GC header interval.")                                         \
R(verify_after_gc, false, bool, false,                                         \
  "Enables heap verification after GC.")                                       \
R(verify_before_gc, false, bool, false,                                        \
  "Enables heap verification before GC.")                                      \


#endif  // VM_FLAG_LIST_H_
