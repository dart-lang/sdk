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

#define FLAG_LIST(P, R, D) \
R(disassemble, false, bool, false, "Disassemble dart code.")                   \
R(disassemble_optimized, false, bool, false, "Disassemble optimized code.")    \
R(dump_symbol_stats, false, bool, false, "Dump symbol table statistics")       \
R(pretenure_all, false, bool, false, "Global pretenuring (for testing).")      \
D(trace_handles, bool, false, "Traces allocation of handles.")                 \
D(trace_zones, bool, false, "Traces allocation sizes in the zone.")            \
P(verbose_gc, bool, false, "Enables verbose GC.")                              \

#endif  // VM_FLAG_LIST_H_
