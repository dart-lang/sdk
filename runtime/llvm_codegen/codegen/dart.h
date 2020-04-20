// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_LLVM_CODEGEN_CODEGEN_DART_H_
#define RUNTIME_LLVM_CODEGEN_CODEGEN_DART_H_

#include <memory>
#include <vector>
#include <string>

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/WithColor.h"

// Ensure to use our own zone.
#include "custom_zone.h"
#include "vm/compiler/backend/sexpression.h"

// This file introduces several representations that exist between
// S-Expressions and llvm IR. To explain how each part is intended
// to be roughly translated using these I'll provide a mapping
// showing how each part is translated.

// At a high level two translations are very seamless:
//
// (function foo ...) -> DartFunction -> llvm::Function*
// (block B ...) -> DartBlock -> (sort of) llvm::BasicBlock*
//
// Internally within a function constants are given names and are then used in
// blocks. Each block additionally defines more names. Each of these names
// needs to be mapped to a DartValue (more on that later) so a context to help
// keep track of these name to DartValue mappings called a
// DartBasicBlockBuilder exists. It is only used for to aid in the
// (block B ...) -> DartBlock translation which is in turn used in the
// (function foo ...) -> DartFunction translation. DartFunctions and DartBlocks
// can be seen as validated representations of their S-Expression forms.

// Within a DartBlock we have DartInstructions. Each DartInstruction either
// has some effect (like calling a function or updating a value) or defines
// a new name mapping it to a DartValue later. DartValues are referenced as
// arguments to DartInstructions and map to llvm::Value*s. DartInstructions
// have no analogue which they're directly translated to in code but they
// do closely correspond mentally to llvm::Instruction*. The challenge is that
// a DartInstruction might map to a near arbitrary number of llvm Instructions
// and that mapping is very dependent on context. So instead of mapping them
// to objects DartInstructions just know how to add their llvm Instructions to
// an llvm::BasicBlock. These instructions might reference a verity of context
// and so BasicBlockBuilder is passed in to provide them with this context.
// Each DartInstruction is expected to already hold each DartValue that it
// needs as previously supplied by the DartBasicBlockBuilder on construction.

// An additional issue arises when translating DartInstructions into llvm IR.
// Many require introducing control flow when lowered to the level of llvm IR
// but this requires using multiple llvm::BasicBlock for a single DartBlock.
// Luckily each DartInstruction that is not a terminator is expected to make it
// possible for all non-exceptional control flow paths to wind up at a single
// basic block. Since BasicBlockBuilder keeps track of a "current" basic block
// via llvm::IRBuilder we simply ensure that after generating many blocks we
// end each instruction which requires new basic blocks on this final basic
// block that all generated blocks flow into. A picture better explains this:

// Say you have a DartBlock B_1 it would then be mapped to llvm blocks that
// look like this:
//
//                          B_1
//                          / \
//                         /   \
//                 B_1_left    B_1_right
//                         \   /
//                          \ /
//                         B_1_0
//
// And then we go on adding to B_1_0 as if it were the end of B_1 from before.

// Each DartValue knows how to map itself to an llvm::Value. In llvm a Value
// is really just anything you can give a name to in the IR but a DartValue
// is intended to be more specific, it's a compile time representation of a
// object, be it an integer, a tagged SMI, a pointer to a Dart Object, etc...
// its intended to correspond to some actual object that we're computing on.

// Class FunctionBuilder provides functionality for building
// and LLVM function object including the ability to add a
// named basic block, find an existing block, get the current
// context/module and additionally retrieve llvm Values valid
// in the current function.
class FunctionBuilder {
 public:
  FunctionBuilder(llvm::LLVMContext& ctx,
                  llvm::Module& mod,
                  llvm::Function& func)
      : ctx_(ctx), mod_(mod), func_(func) {}
  llvm::LLVMContext& Context() { return ctx_; }
  llvm::Module& Module() { return mod_; }
  llvm::Value* GetSymbolValue(llvm::StringRef name) {
    auto* symtab = func_.getValueSymbolTable();
    return symtab->lookup(name);
  }
  llvm::BasicBlock* AddBasicBlock() {
    return llvm::BasicBlock::Create(ctx_, "", &func_);
  }
  llvm::BasicBlock* AddBasicBlock(llvm::StringRef name) {
    auto* bb = llvm::BasicBlock::Create(ctx_, name, &func_);
    basic_blocks_[name] = bb;
    return bb;
  }
  llvm::BasicBlock* GetBasicBlock(llvm::StringRef name) const {
    auto iter = basic_blocks_.find(name);
    if (iter != basic_blocks_.end()) return iter->getValue();
    return nullptr;
  }

 private:
  llvm::LLVMContext& ctx_;
  llvm::Module& mod_;
  llvm::Function& func_;
  llvm::StringMap<llvm::BasicBlock*> basic_blocks_;
};

class BasicBlockBuilder;

// TODO(jakehehrlich): Make this architecture dependent
// Class DartThreadObject is used as a high level object for generating
// code that reads fields from the thread object.
class DartThreadObject {
 public:
  explicit DartThreadObject(BasicBlockBuilder& bb_builder)
      : bb_builder_(bb_builder) {}

  // StackLimit returns an llvm::Value representing the stack limit
  // of the thread object.
  llvm::Value* StackLimit() const;

 private:
  static constexpr intptr_t kThreadStackLimitOffset = 72;

  BasicBlockBuilder& bb_builder_;

  // GetOffset returns an llvm::Value* representing a pointer to a particular
  // field of the thread object. It adds the specified offset to the thread
  // pointer, and then casts to the specified type.
  llvm::Value* GetOffset(llvm::Type* type, intptr_t offset) const;
};

class DartValue;

// A class for keeping track of the basic block state and SSA values.
// This is similar to IRBuilder but also keeps track of the argument stack and
// basic block names.
class BasicBlockBuilder {
 public:
  BasicBlockBuilder(llvm::BasicBlock* bb, FunctionBuilder& fb)
      : fb_(fb), top_(bb), builder_(bb), thread_object_(*this) {}
  llvm::LLVMContext& Context() { return fb_.Context(); }
  llvm::Module& Module() { return fb_.Module(); }
  llvm::IRBuilder<>& Builder() { return builder_; }
  const DartThreadObject& ThreadObject() { return thread_object_; }
  llvm::BasicBlock* AddBasicBlock() { return fb_.AddBasicBlock(); }
  llvm::BasicBlock* GetBasicBlock(llvm::StringRef Name) const {
    return fb_.GetBasicBlock(Name);
  }
  llvm::Value* GetSymbolValue(llvm::StringRef name) const {
    return fb_.GetBasicBlock(name);
  }
  llvm::Value* GetValue(const DartValue* v);
  void PushArgument(llvm::Value* v) { stack_.push_back(v); }
  llvm::Value* PopArgument() {
    llvm::Value* out = stack_.back();
    stack_.pop_back();
    return out;
  }

 private:
  FunctionBuilder& fb_;
  llvm::BasicBlock* top_;
  llvm::SmallVector<llvm::Value*, 16> stack_;
  llvm::IRBuilder<> builder_;
  llvm::DenseMap<const DartValue*, llvm::Value*> values_;
  DartThreadObject thread_object_;
};

// Class DartValue represents an SSA value from the Dart SSA
// such that it can be converted into an llvm::Value*.
class DartValue {
 public:
  virtual ~DartValue() {}
  virtual llvm::Value* Make(BasicBlockBuilder& bb_builder) const = 0;
  virtual llvm::Type* GetType(BasicBlockBuilder& bb_builder) const = 0;
};

// Class DartBasicBlockBuilder provides helpful context for going
// from an S-Expression basic block to a DartBlock. It just lets
// one lookup DartValue's by name at this time.
class DartBasicBlockBuilder {
 public:
  void AddDef(llvm::StringRef name, const DartValue* v) { defs_[name] = v; }
  const DartValue* GetDef(llvm::StringRef name) const {
    auto iter = defs_.find(name);
    if (iter != defs_.end()) return iter->getValue();
    return nullptr;
  }

 private:
  llvm::StringMap<const DartValue*> defs_;
};

// A DartConstant is a DartValue for a constant.
class DartConstant : public DartValue {
 public:
  std::string str;
  enum class Type { String };
  Type type;

  llvm::Value* Make(BasicBlockBuilder& bb_builder) const override;
  llvm::Type* GetType(BasicBlockBuilder& bb_builder) const override;
};

// Class DartInstruction represents a step within a DartBasicBlock.
// CheckStackOverflow or PushArgument are instructions. They contain
// DartValues as arguments typically. SSA definitions are also
// DartInstructions which assign DartValues to names in the function's
// context.
class DartInstruction {
 public:
  virtual ~DartInstruction();
  virtual void Build(BasicBlockBuilder& bb_builder) const = 0;
};

// Class InstCheckStackOverflow is a DartInstruction that represents
// an instance of a CheckStackOverflow instruction.
class InstCheckStackOverflow : public DartInstruction {
 public:
  InstCheckStackOverflow() {}
  ~InstCheckStackOverflow() override {}
  void Build(BasicBlockBuilder& bb_builder) const override;
  static llvm::Expected<std::unique_ptr<DartInstruction>> Construct(
      dart::SExpList* inst,
      DartBasicBlockBuilder& bb_builder);
};

// Class InstPushArgument is a DartInstruction that represents
// and instance of a PushArgument Instruction.
class InstPushArgument : public DartInstruction {
 public:
  explicit InstPushArgument(const DartValue* arg) : arg_(arg) {}
  ~InstPushArgument() override {}
  void Build(BasicBlockBuilder& bb_builder) const override;
  static llvm::Expected<std::unique_ptr<DartInstruction>> Construct(
      dart::SExpList* inst,
      DartBasicBlockBuilder& bb_builder);

 private:
  const DartValue* arg_;
};

// Class InstStaticCall is a DartInstruction that represents a
// StaticCall instruction.
class InstStaticCall : public DartInstruction {
 public:
  InstStaticCall(const DartValue* func, size_t args_len)
      : function_(func), args_len_(args_len) {}
  ~InstStaticCall() override {}
  void Build(BasicBlockBuilder& bb_builder) const override;
  static llvm::Expected<std::unique_ptr<DartInstruction>> Construct(
      dart::SExpList* inst,
      DartBasicBlockBuilder& bb_builder);

 private:
  const DartValue* function_;
  size_t args_len_;
};

// Class InstReturn is a DartInstruction that represents a Return
// instruction.
class InstReturn : public DartInstruction {
 public:
  InstReturn() {}
  ~InstReturn() override {}
  void Build(BasicBlockBuilder& bb_builder) const override;
  static llvm::Expected<std::unique_ptr<DartInstruction>> Construct(
      dart::SExpList* inst,
      DartBasicBlockBuilder& bb_builder);
};

// Class DartBlock represents a validated basic block as parsed from
// a (block ...) S-Expression.
struct DartBlock {
  std::string name;
  std::vector<std::unique_ptr<DartInstruction>> instructions;
};

// Class DartFunction represents a validated function parsed from a
// (function ...) S-Expression.
struct DartFunction {
  std::string name;
  DartBlock* normal_entry;
  llvm::StringMap<DartConstant> constants;
  llvm::StringMap<DartBlock> blocks;
};

// MakeFunction takes an S-Expression and an environment of externally
// defined DartValues and produces a DartFunction corresponding to the
// S-Expression if everything is valid. If something about the syntax
// of the S-Expression is invalid then the llvm::Expected will hold an
// error explaining the issue.
llvm::Expected<DartFunction> MakeFunction(
    dart::Zone* zone,
    dart::SExpression* sexpr,
    const llvm::StringMap<const DartValue*>& env);

#endif  // RUNTIME_LLVM_CODEGEN_CODEGEN_DART_H_
