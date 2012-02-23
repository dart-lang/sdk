// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_INTERMEDIATE_LANGUAGE_H_
#define VM_INTERMEDIATE_LANGUAGE_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/handles_impl.h"
#include "vm/object.h"

namespace dart {

class LocalVariable;

// Computations and values.
//
// <Computation> ::= <Value>
//                 | AssertAssignable <Value> <AbstractType>
//                 | InstanceCall <cstring> <Value> ...
//                 | StaticCall <Function> <Value> ...
//                 | LoadLocal <LocalVariable>
//                 | StoreLocal <LocalVariable> <Value>
//
// <Value> ::= Temp <int>
//           | Constant <Instance>

class Computation : public ZoneAllocated {
 public:
  Computation() { }

  // Prints a computation without indentation or trailing newlines.
  virtual void Print() const = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(Computation);
};


class Value : public Computation {
 public:
  Value() { }

 private:
  DISALLOW_COPY_AND_ASSIGN(Value);
};


class AssertAssignableComp : public Computation {
 public:
  AssertAssignableComp(Value* value, const AbstractType& type)
      : value_(value), type_(type) { }

  virtual void Print() const;

 private:
  Value* value_;
  const AbstractType& type_;

  DISALLOW_COPY_AND_ASSIGN(AssertAssignableComp);
};


class InstanceCallComp : public Computation {
 public:
  InstanceCallComp(const char* name, ZoneGrowableArray<Value*>* arguments)
      : name_(name), arguments_(arguments) { }

  virtual void Print() const;

 private:
  const char* name_;
  ZoneGrowableArray<Value*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(InstanceCallComp);
};


class StaticCallComp : public Computation {
 public:
  StaticCallComp(const Function& function, ZoneGrowableArray<Value*>* arguments)
      : function_(function), arguments_(arguments) {
    ASSERT(function.IsZoneHandle());
  }

  virtual void Print() const;

 private:
  const Function& function_;
  ZoneGrowableArray<Value*>* arguments_;

  DISALLOW_COPY_AND_ASSIGN(StaticCallComp);
};


class LoadLocalComp : public Computation {
 public:
  explicit LoadLocalComp(const LocalVariable& local) : local_(local) { }

  virtual void Print() const;

 private:
  const LocalVariable& local_;

  DISALLOW_COPY_AND_ASSIGN(LoadLocalComp);
};


class StoreLocalComp : public Computation {
 public:
  StoreLocalComp(const LocalVariable& local, Value* value)
      : local_(local), value_(value) { }

  virtual void Print() const;

 private:
  const LocalVariable& local_;
  Value* value_;

  DISALLOW_COPY_AND_ASSIGN(StoreLocalComp);
};


class TempValue : public Value {
 public:
  explicit TempValue(intptr_t index) : index_(index) { }

  virtual void Print() const;

 private:
  intptr_t index_;

  DISALLOW_COPY_AND_ASSIGN(TempValue);
};


class ConstantValue: public Value {
 public:
  explicit ConstantValue(const Instance& instance) : instance_(instance) { }

  virtual void Print() const;

 private:
  const Instance& instance_;

  DISALLOW_COPY_AND_ASSIGN(ConstantValue);
};


// Instructions.
//
// <Instruction> ::= Do <Computation> <Instruction>
//                 | Bind <int> <Computation> <Instruction>
//                 | Return <Value>
//                 | Branch <Value> <Instruction> <Instruction>
//                 | Empty <Instruction>

// M is a single argument macro.  It is applied to each concrete instruction
// type name.  The concrete instruction classes are the name with Instr
// concatenated.
#define FOR_EACH_INSTRUCTION(M)                 \
  M(JoinEntry)                                  \
  M(TargetEntry)                                \
  M(Do)                                         \
  M(Bind)                                       \
  M(Return)                                     \
  M(Branch)


// Forward declarations for Instruction classes.
class BlockEntryInstr;
class InstructionVisitor;
#define FORWARD_DECLARATION(type) class type##Instr;
FOR_EACH_INSTRUCTION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION


// Functions required in all concrete instruction classes.
#define DECLARE_INSTRUCTION(type)                               \
  virtual Tag tag() const { return k##type; }                   \
  static type##Instr* cast(Instruction* instr) {                \
    ASSERT(instr->Is##type());                                  \
    return reinterpret_cast<type##Instr*>(instr);               \
  }                                                             \
  virtual Instruction* Accept(InstructionVisitor* visitor);


class Instruction : public ZoneAllocated {
 public:
  // Declare a tag for each concrete instruction type.
#define DECLARE_TAG(type) k##type,
  enum Tag {
    FOR_EACH_INSTRUCTION(DECLARE_TAG)
    kInstructionCount  // To follow the trailing comma from the macro.
  };
#undef DECLARE_TAG

  Instruction() : mark_(false) { }

  // Pure virtual tag accessor.
  virtual Tag tag() const = 0;

  // Non-virtual type testing functions.
#define DEFINE_TYPE_FUNCTIONS(type)                             \
  bool Is##type() const { return tag() == k##type; }
  FOR_EACH_INSTRUCTION(DEFINE_TYPE_FUNCTIONS)
#undef DEFINE_TYPE_FUNCTIONS

  // Type testing and conversions for other classes of instructions.
  bool IsBlockEntry() const { return IsJoinEntry() || IsTargetEntry(); }

  // Visiting support.
  virtual Instruction* Accept(InstructionVisitor* visitor) = 0;

  virtual void SetSuccessor(Instruction* instr) = 0;
  // Perform a postorder traversal of the instruction graph reachable from
  // this instruction.  Accumulate basic block entries in the order visited
  // in the in/out parameter 'block_entries'.
  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries) = 0;

  // Mark bit to support non-reentrant recursive traversal (i.e.,
  // identification of cycles).  Before and after a traversal, all the nodes
  // must have the same mark.
  bool mark() const { return mark_; }
  void flip_mark() { mark_ = !mark_; }

 private:
  bool mark_;
};


// Basic block entries are administrative nodes.  Joins are the only nodes
// with multiple predecessors.  Targets are the other basic block entries.
// The types enforce edge-split form---joins are forbidden as the successors
// of branches.
class BlockEntryInstr : public Instruction {
 public:
  BlockEntryInstr() : Instruction(), block_number_(-1) { }

  static BlockEntryInstr* cast(Instruction* instr) {
    ASSERT(instr->IsBlockEntry());
    return reinterpret_cast<BlockEntryInstr*>(instr);
  }

  intptr_t block_number() const { return block_number_; }
  void set_block_number(intptr_t number) { block_number_ = number; }

 private:
  intptr_t block_number_;
};


class JoinEntryInstr : public BlockEntryInstr {
 public:
  JoinEntryInstr() : BlockEntryInstr(), successor_(NULL) { }

  DECLARE_INSTRUCTION(JoinEntry)

  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries);

 private:
  Instruction* successor_;
};


class TargetEntryInstr : public BlockEntryInstr {
 public:
  TargetEntryInstr() : BlockEntryInstr(), block_number_(-1), successor_(NULL) {
  }

  DECLARE_INSTRUCTION(TargetEntry)

  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries);

 private:
  intptr_t block_number_;
  Instruction* successor_;
};


class DoInstr : public Instruction {
 public:
  explicit DoInstr(Computation* comp)
      : Instruction(), computation_(comp), successor_(NULL) { }

  DECLARE_INSTRUCTION(Do)

  Computation* computation() const { return computation_; }

  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries);

 private:
  Computation* computation_;
  Instruction* successor_;
};


class BindInstr : public Instruction {
 public:
  BindInstr(intptr_t temp_index, Computation* computation)
      : Instruction(),
        temp_index_(temp_index),
        computation_(computation),
        successor_(NULL) { }

  DECLARE_INSTRUCTION(Bind)

  intptr_t temp_index() const { return temp_index_; }
  Computation* computation() const { return computation_; }

  virtual void SetSuccessor(Instruction* instr) {
    ASSERT(successor_ == NULL);
    successor_ = instr;
  }

  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries);

 private:
  const intptr_t temp_index_;
  Computation* computation_;
  Instruction* successor_;
};


class ReturnInstr : public Instruction {
 public:
  explicit ReturnInstr(Value* value) : Instruction(), value_(value) { }

  DECLARE_INSTRUCTION(Return)

  Value* value() const { return value_; }

  virtual void SetSuccessor(Instruction* instr) { UNREACHABLE(); }

  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries);

 private:
  Value* value_;
};


class BranchInstr : public Instruction {
 public:
  explicit BranchInstr(Value* value)
      : Instruction(),
        value_(value),
        true_successor_(NULL),
        false_successor_(NULL) { }

  DECLARE_INSTRUCTION(Branch)

  Value* value() const { return value_; }
  TargetEntryInstr* true_successor() const { return true_successor_; }
  TargetEntryInstr* false_successor() const { return false_successor_; }

  TargetEntryInstr** true_successor_address() { return &true_successor_; }
  TargetEntryInstr** false_successor_address() { return &false_successor_; }

  virtual void SetSuccessor(Instruction* instr) { UNREACHABLE(); }

  virtual void Postorder(GrowableArray<BlockEntryInstr*>* block_entries);

 private:
  Value* value_;
  TargetEntryInstr* true_successor_;
  TargetEntryInstr* false_successor_;
};

#undef DECLARE_INSTRUCTION


class InstructionVisitor {
 public:
  InstructionVisitor() { }
  virtual ~InstructionVisitor() { }

  // Visit each block in the array list in reverse, and for each block its
  // instructions in order from the block entry to exit.
  void VisitBlocks(const GrowableArray<BlockEntryInstr*>& block_order);

#define DECLARE_VISIT(type)                             \
  virtual void Visit##type(type##Instr* instr) { }
  FOR_EACH_INSTRUCTION(DECLARE_VISIT)
#undef DECLARE_VISIT

 private:
  DISALLOW_COPY_AND_ASSIGN(InstructionVisitor);
};


}  // namespace dart

#endif  // VM_INTERMEDIATE_LANGUAGE_H_
