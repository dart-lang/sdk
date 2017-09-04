// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_PRINTER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_PRINTER_H_

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

class BufferFormatter : public ValueObject {
 public:
  BufferFormatter(char* buffer, intptr_t size)
      : position_(0), buffer_(buffer), size_(size) {}

  void VPrint(const char* format, va_list args);
  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

 private:
  intptr_t position_;
  char* buffer_;
  const intptr_t size_;

  DISALLOW_COPY_AND_ASSIGN(BufferFormatter);
};

class ParsedFunction;

// Graph printing.
class FlowGraphPrinter : public ValueObject {
 public:
  static const intptr_t kPrintAll = -1;

  explicit FlowGraphPrinter(const FlowGraph& flow_graph,
                            bool print_locations = false)
      : function_(flow_graph.function()),
        block_order_(flow_graph.reverse_postorder()),
        print_locations_(print_locations) {}

  // Print the instructions in a block terminated by newlines.  Add "goto N"
  // to the end of the block if it ends with an unconditional jump to
  // another block and that block is not next in reverse postorder.
  void PrintBlocks();
  void PrintInstruction(Instruction* instr);
  static void PrintOneInstruction(Instruction* instr, bool print_locations);
  static void PrintTypeCheck(const ParsedFunction& parsed_function,
                             TokenPosition token_pos,
                             Value* value,
                             const AbstractType& dst_type,
                             const String& dst_name,
                             bool eliminated);
  static void PrintBlock(BlockEntryInstr* block, bool print_locations);

  static void PrintGraph(const char* phase, FlowGraph* flow_graph);

  // Debugging helper function. If 'num_checks_to_print' is not specified
  // all checks will be printed.
  static void PrintICData(const ICData& ic_data,
                          intptr_t num_checks_to_print = kPrintAll);

  // Debugging helper function. If 'num_checks_to_print' is not specified
  // all checks will be printed.
  static void PrintCidRangeData(const CallTargets& ic_data,
                                intptr_t num_checks_to_print = kPrintAll);

  static bool ShouldPrint(const Function& function);

  static bool PassesFilter(const char* filter, const Function& function);

 private:
  const Function& function_;
  const GrowableArray<BlockEntryInstr*>& block_order_;
  const bool print_locations_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_PRINTER_H_
