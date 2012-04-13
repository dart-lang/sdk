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
  static intptr_t num_tokens_total;
  static intptr_t num_literal_tokens_total;
  static intptr_t num_ident_tokens_total;
  static intptr_t num_tokens_consumed;
  static intptr_t num_token_checks;
  static intptr_t num_tokens_rewind;
  static intptr_t num_tokens_lookahead;

  static intptr_t src_length;        // Total number of characters in source.
  static intptr_t code_allocated;    // Bytes allocated for generated code.
  static Timer    parser_timer;      // Cumulative runtime of parser.
  static Timer    scanner_timer;     // Cumulative runtime of scanner.
  static Timer    codegen_timer;     // Cumulative runtime of code generator.

  static void Print();
};


}  // namespace dart

#endif  // VM_COMPILER_STATS_H_
