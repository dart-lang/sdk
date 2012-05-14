// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_IL_PRINTER_H_
#define VM_IL_PRINTER_H_

#include "vm/intermediate_language.h"

namespace dart {

// Graph printing.
class FlowGraphPrinter : public FlowGraphVisitor {
 public:
  FlowGraphPrinter(const Function& function,
                   const GrowableArray<BlockEntryInstr*>& block_order)
      : FlowGraphVisitor(block_order), function_(function) { }

  virtual ~FlowGraphPrinter() {}

  // Print the instructions in a block terminated by newlines.  Add "goto N"
  // to the end of the block if it ends with an unconditional jump to
  // another block and that block is not next in reverse postorder.
  void VisitBlocks();

  // Visiting a computation prints it with no indentation or newline.
#define DECLARE_VISIT_COMPUTATION(ShortName, ClassName)                        \
  virtual void Visit##ShortName(ClassName* comp);

  // Visiting an instruction prints it with a four space indent and no
  // trailing newline.  Basic block entries are labeled with their block
  // number.
#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr);

  FOR_EACH_COMPUTATION(DECLARE_VISIT_COMPUTATION)
  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_COMPUTATION
#undef DECLARE_VISIT_INSTRUCTION

 private:
  const Function& function_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphPrinter);
};

}  // namespace dart

#endif  // VM_IL_PRINTER_H_
