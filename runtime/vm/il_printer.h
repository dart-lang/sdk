// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_IL_PRINTER_H_
#define VM_IL_PRINTER_H_

#include "vm/flow_graph.h"
#include "vm/intermediate_language.h"

namespace dart {

class BufferFormatter : public ValueObject {
 public:
  BufferFormatter(char* buffer, intptr_t size)
    : position_(0),
      buffer_(buffer),
      size_(size) { }

  void VPrint(const char* format, va_list args);
  void Print(const char* format, ...);

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
  FlowGraphPrinter(const FlowGraph& flow_graph,
                   bool print_locations = false)
      : function_(flow_graph.parsed_function().function()),
        block_order_(flow_graph.reverse_postorder()),
        print_locations_(print_locations) { }

  // Print the instructions in a block terminated by newlines.  Add "goto N"
  // to the end of the block if it ends with an unconditional jump to
  // another block and that block is not next in reverse postorder.
  void PrintBlocks();
  void PrintInstruction(Instruction* instr);
  static void PrintComputation(Computation* comp);
  static void PrintTypeCheck(const ParsedFunction& parsed_function,
                             intptr_t token_pos,
                             Value* value,
                             const AbstractType& dst_type,
                             const String& dst_name,
                             bool eliminated);

 private:
  const Function& function_;
  const GrowableArray<BlockEntryInstr*>& block_order_;
  const bool print_locations_;
};


class FlowGraphVisualizer : public ValueObject {
 public:
  explicit FlowGraphVisualizer(const FlowGraph& flow_graph)
      : function_(flow_graph.parsed_function().function()),
        block_order_(flow_graph.reverse_postorder()),
        indent_(0) { }

  void PrintFunction();

 private:
  // Helpers for printing.
  void PrintInstruction(Instruction* instr);
  void Print(const char* format, ...);

  const Function& function_;
  const GrowableArray<BlockEntryInstr*>& block_order_;
  intptr_t indent_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphVisualizer);
};

}  // namespace dart

#endif  // VM_IL_PRINTER_H_
