// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_IL_PRINTER_H_
#define VM_IL_PRINTER_H_

#include "vm/intermediate_language.h"

namespace dart {

class BufferFormatter : public ValueObject {
 public:
  BufferFormatter(char* buffer, intptr_t size)
    : position_(0),
      buffer_(buffer),
      size_(size) { }

  void Print(const char* format, ...);

 private:
  intptr_t position_;
  char* buffer_;
  const intptr_t size_;

  DISALLOW_COPY_AND_ASSIGN(BufferFormatter);
};


// Graph printing.
class FlowGraphPrinter : public ValueObject {
 public:
  FlowGraphPrinter(const Function& function,
                   const GrowableArray<BlockEntryInstr*>& block_order)
      : function_(function), block_order_(block_order) { }

  virtual ~FlowGraphPrinter() {}

  // Print the instructions in a block terminated by newlines.  Add "goto N"
  // to the end of the block if it ends with an unconditional jump to
  // another block and that block is not next in reverse postorder.
  void PrintBlocks();
  void Print(Instruction* instr);

 private:
  const Function& function_;
  const GrowableArray<BlockEntryInstr*>& block_order_;
};

}  // namespace dart

#endif  // VM_IL_PRINTER_H_
