// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "dart.h"

#include "llvm/ADT/StringSwitch.h"

using namespace llvm;

Value* DartThreadObject::GetOffset(Type* type, intptr_t offset) const {
  auto& ctx = bb_builder_.Context();
  auto& builder = bb_builder_.Builder();
  auto int64ty = IntegerType::getInt64Ty(ctx);
  // TODO: This is only correct for x86_64. On x86 we need to use 257,
  // and only arm targets an entirely different mechanism will be
  // required since there isn't an unused register. On Arm we can
  // probably still use the thread register as long as we're careful
  // to set it back on thread boundaries.
  // On x86_64 fs (257) is used for TLS but gs (256) is unused
  // On x86 gs (256) is used for TLS but fs (257) is unused
  // we use the unused segment so as to not conflict with TLS which
  // allows linking against native code that uses TLS without needing
  // to handle any kind of context switching.
  constexpr unsigned kDartThreadPointerAddressSpace = 256;
  auto* ptr_tls = PointerType::get(type, kDartThreadPointerAddressSpace);
  auto* offset_value = ConstantInt::get(int64ty, offset);
  auto* tls_value = builder.CreateIntToPtr(offset_value, ptr_tls);
  return builder.CreateLoad(tls_value);
}

Value* DartThreadObject::StackLimit() const {
  auto& ctx = bb_builder_.Context();
  return GetOffset(IntegerType::getInt64Ty(ctx), kThreadStackLimitOffset);
}

Value* BasicBlockBuilder::GetValue(const DartValue* v) {
  auto iter = values_.find(v);
  if (iter == values_.end()) {
    auto* out = v->Make(*this);
    values_[v] = out;
    return out;
  }
  return iter->second;
}

DartInstruction::~DartInstruction() {}

static Error CreateError(const Twine& err) {
  return make_error<StringError>(err, inconvertibleErrorCode());
}

Value* DartConstant::Make(BasicBlockBuilder& bb_builder) const {
  auto& ctx = bb_builder.Context();
  switch (type) {
    case DartConstant::Type::String:
      auto constant = ConstantDataArray::getString(ctx, str);
      auto gv =
          new GlobalVariable(bb_builder.Module(), constant->getType(), true,
                             GlobalVariable::ExternalLinkage, constant);
      return ConstantExpr::getBitCast(gv, GetType(bb_builder));
  }
}

Type* DartConstant::GetType(BasicBlockBuilder& bb_builder) const {
  // TODO: Right now this returns a c-string type but that's not correct.
  // We should move this to a generic object type (e.g. a tagged pointer).
  auto& ctx = bb_builder.Context();
  auto int8ty = IntegerType::getInt8Ty(ctx);
  return PointerType::get(int8ty, 0);
}

void InstCheckStackOverflow::Build(BasicBlockBuilder& bb_builder) const {
  auto& builder = bb_builder.Builder();
  auto& ctx = bb_builder.Context();
  auto& module = bb_builder.Module();
  auto& thread_object = bb_builder.ThreadObject();

  // TODO: This is only correct on 64-bit architectures.
  auto int64ty = IntegerType::getInt64Ty(ctx);

  // Get the stack pointer.
  auto spi_type = Intrinsic::getType(ctx, Intrinsic::stacksave);
  auto spi_func = Intrinsic::getDeclaration(&module, Intrinsic::stacksave);
  auto sp_raw = builder.CreateCall(spi_type, spi_func);
  auto sp = builder.CreatePtrToInt(sp_raw, int64ty);

  // Get the stack limit from the thread pointer.
  auto stack_limit = thread_object.StackLimit();

  // Now compare the stack pointer and limit.
  auto error_bb = bb_builder.AddBasicBlock();
  auto cont_bb = bb_builder.AddBasicBlock();
  auto cmp = builder.CreateICmpULT(sp, stack_limit);
  builder.CreateCondBr(cmp, error_bb, cont_bb);

  // Now build the error path.
  // TODO: Don't just trap here. For now we just trap rather than
  // handling the proper exceptional control flow here.
  builder.SetInsertPoint(error_bb);
  auto trap_type = Intrinsic::getType(ctx, Intrinsic::trap);
  auto trap_func = Intrinsic::getDeclaration(&module, Intrinsic::trap);
  builder.CreateCall(trap_type, trap_func);
  builder.CreateBr(cont_bb);

  // Now pretend as if this new block is just the end of the block we
  // started with.
  builder.SetInsertPoint(cont_bb);
}

Expected<std::unique_ptr<DartInstruction>> InstCheckStackOverflow::Construct(
    dart::SExpList* inst,
    DartBasicBlockBuilder& bb_builder) {
  // inst = (CheckStackoverflow)
  return llvm::make_unique<InstCheckStackOverflow>();
}

void InstPushArgument::Build(BasicBlockBuilder& bb_builder) const {
  bb_builder.PushArgument(bb_builder.GetValue(arg_));
}

Expected<std::unique_ptr<DartInstruction>> InstPushArgument::Construct(
    dart::SExpList* inst,
    DartBasicBlockBuilder& bb_builder) {
  // inst = (PushArgument <arg>)
  if (inst->Length() != 2) {
    return CreateError("PushArgument should have exactly 1 argument");
  }
  dart::SExpSymbol* arg = inst->At(1)->AsSymbol();
  if (arg == nullptr) {
    return CreateError("Expected PushArgument's argument to be a symbol");
  }
  const DartValue* dvalue = bb_builder.GetDef(arg->value());
  if (dvalue == nullptr) {
    return CreateError(Twine(arg->value()) + " is not a valid symbol");
  }
  return llvm::make_unique<InstPushArgument>(dvalue);
}

void InstStaticCall::Build(BasicBlockBuilder& bb_builder) const {
  // inst = (StaticCall <function-symbol> <arg> ...)

  SmallVector<Value*, 8> args;
  size_t arg_count = args_len_;
  while (arg_count > 0) {
    arg_count--;
    args.push_back(bb_builder.PopArgument());
  }
  auto& builder = bb_builder.Builder();

  // Hard code the function type for now.
  auto& ctx = bb_builder.Context();
  auto int8ty = IntegerType::getInt8Ty(ctx);
  auto i8ptr = PointerType::get(int8ty, 0);
  SmallVector<Type*, 8> arg_types;
  arg_types.push_back(i8ptr);
  auto print_type = FunctionType::get(Type::getVoidTy(ctx), arg_types, false);

  // Get the function value we need.
  auto func = bb_builder.GetValue(function_);
  builder.CreateCall(print_type, func, args);
}

Expected<std::unique_ptr<DartInstruction>> InstStaticCall::Construct(
    dart::SExpList* inst,
    DartBasicBlockBuilder& bb_builder) {
  // inst = (StaticCall <function_name> { args_len <N> })
  if (inst->Length() != 2) {
    return CreateError("StaticCall should have exactly 1 argument");
  }
  dart::SExpSymbol* func = inst->At(1)->AsSymbol();
  if (!func) {
    return CreateError("Expected StaticCall's argument to be a symbol");
  }
  const DartValue* dvalue = bb_builder.GetDef(func->value());
  dart::SExpression* args_len_expr = inst->ExtraLookupValue("args_len");
  // If args_len_expr isn't found args_len is assumed to be zero.
  size_t args_len = 0;
  if (args_len_expr) {
    dart::SExpInteger* args_len_expr_int = args_len_expr->AsInteger();
    if (args_len_expr_int) args_len = args_len_expr_int->value();
  }
  return llvm::make_unique<InstStaticCall>(dvalue, 1);
}

void InstReturn::Build(BasicBlockBuilder& bb_builder) const {
  auto& builder = bb_builder.Builder();
  builder.CreateRetVoid();
}

Expected<std::unique_ptr<DartInstruction>> InstReturn::Construct(
    dart::SExpList* inst,
    DartBasicBlockBuilder& bb_builder) {
  // inst = (Return)
  return llvm::make_unique<InstReturn>();
}

static Expected<StringMap<DartConstant>> MakeConstants(dart::Zone* zone,
                                                       dart::SExpList* sexpr) {
  StringMap<DartConstant> out;
  for (intptr_t i = 1; i < sexpr->Length(); ++i) {
    DartConstant constant;
    dart::SExpList* def = sexpr->At(i)->AsList();
    if (!def) {
      return CreateError(Twine("Stray token in constants at location ") +
                         Twine(i) + sexpr->At(i)->ToCString(zone));
    }
    if (def->Length() != 3) {
      return CreateError("Constant definitions must have exactly 3 lines");
    }
    dart::SExpSymbol* def_symbol = def->At(0)->AsSymbol();
    if (def_symbol->value() != StringRef("def")) {
      return CreateError(
          "first element in a constant definition expected to be `def`");
    }
    dart::SExpSymbol* def_name = def->At(1)->AsSymbol();
    if (!def_name) {
      return CreateError("element after `def` in constant expected to be name");
    }
    dart::SExpression* def_value = def->At(2);
    if (def_value->IsString()) {
      constant.str = def_value->AsString()->value();
      constant.type = DartConstant::Type::String;
    } else {
      return CreateError("We can't yet handle that element type");
    }
    out[def_name->value()] = constant;
  }
  return out;
}

#define FOREACH_INSTRUCTION(M)                                                 \
  M(CheckStackOverflow)                                                        \
  M(PushArgument)                                                              \
  M(StaticCall)                                                                \
  M(Return)

static Expected<std::unique_ptr<DartInstruction>> MakeInstruction(
    dart::SExpList* sexpr,
    DartBasicBlockBuilder& bb_builder) {
  if (sexpr->Length() < 1)
    return CreateError("An empty list can't be an instruction");
  dart::SExpSymbol* inst_sym = sexpr->At(0)->AsSymbol();
  if (!inst_sym)
    return CreateError(
        "Expected first element of list in instruction to be a symbol");
  using CtorFunc = std::function<Expected<std::unique_ptr<DartInstruction>>(
      dart::SExpList*, DartBasicBlockBuilder&)>;
  CtorFunc ctor = StringSwitch<CtorFunc>(inst_sym->value())
#define HANDLE_INSTRUCTION_CASE(INST) .Case(#INST, Inst##INST::Construct)
      FOREACH_INSTRUCTION(HANDLE_INSTRUCTION_CASE);
#undef HANDLE_INSTRUCTION_CASE
  return ctor(sexpr, bb_builder);
}

static Expected<DartBlock> MakeBlock(dart::SExpList* sexpr,
                                     DartFunction& function,
                                     const StringMap<const DartValue*>& env) {
  // Construct the basic block builder
  DartBasicBlockBuilder bb_builder;
  for (const auto& c : function.constants)
    bb_builder.AddDef(c.getKey(), &c.getValue());
  for (const auto& c : env)
    bb_builder.AddDef(c.getKey(), c.getValue());

  DartBlock out;

  // Make sure we have a basic block and get the name
  if (sexpr->Length() <= 2)
    return CreateError("too few elements in basic block");
  dart::SExpSymbol* block_name = sexpr->At(1)->AsSymbol();
  if (!block_name)
    return CreateError("expected block name after `block` symbol");
  out.name = block_name->value();

  // Now construct each instruction and add it to the basic block
  for (intptr_t i = 2; i < sexpr->Length(); ++i) {
    dart::SExpList* inst = sexpr->At(i)->AsList();
    if (!inst)
      return CreateError("stray token at element " + Twine(i) +
                         " in basic block " + out.name);
    auto inst_or = MakeInstruction(inst, bb_builder);
    if (!inst_or) return inst_or.takeError();
    out.instructions.emplace_back(std::move(*inst_or));
  }
  return out;
}

Expected<DartFunction> MakeFunction(dart::Zone* zone,
                                    dart::SExpression* sexpr,
                                    const StringMap<const DartValue*>& env) {
  // Basic checking that this s-expression looks like a function
  dart::SExpList* flist = sexpr->AsList();
  if (!flist) return CreateError("S-Expression was not a function list");
  if (flist->Length() < 2)
    return CreateError("S-Expression list was too short to be a function");
  dart::SExpSymbol* function_symbol = flist->At(0)->AsSymbol();
  if (function_symbol == nullptr ||
      function_symbol->value() != StringRef("function"))
    return CreateError(
        "S-Expression cannot be a function as it does not start with "
        "`function`");
  dart::SExpSymbol* function_name = flist->At(1)->AsSymbol();
  if (function_name == nullptr)
    return CreateError("Expected symbol name after `function` symbol");

  // Now we fill in all the details
  DartFunction function;
  function.name = function_name->value();
  Optional<StringRef> normal_entry;
  for (intptr_t i = 2; i < flist->Length(); ++i) {
    dart::SExpList* chunk = flist->At(i)->AsList();
    // Everything is a list so far so error out on other options
    if (!chunk) {
      return CreateError(Twine("Stray token in function at location ") +
                         Twine(i) + ": " + flist->At(i)->ToCString(zone));
    }
    dart::SExpSymbol* chunk_symbol = chunk->At(0)->AsSymbol();
    if (!chunk_symbol)
      return CreateError(Twine("Expected element ") + Twine(i) +
                         " of function to start with a symbol");
    StringRef chunk_tag = chunk_symbol->value();

    if (chunk_tag == "constants") {
      auto constants = MakeConstants(zone, chunk);
      if (!constants) return constants.takeError();
      function.constants = std::move(*constants);
    }

    if (chunk_tag == "block") {
      auto block = MakeBlock(chunk, function, env);
      if (!block) return block.takeError();
      StringRef name = block->name;
      function.blocks[name] = std::move(*block);
    }

    if (chunk_tag == "normal-entry") {
      if (chunk->Length() != 2)
        return CreateError("Expected 1 argument to normal-entry");
      dart::SExpSymbol* block_name = chunk->At(1)->AsSymbol();
      if (!block_name)
        return CreateError("expected block name after normal-entry symbol");
      normal_entry = block_name->value();
    }
  }

  if (normal_entry) {
    auto iter = function.blocks.find(*normal_entry);
    if (iter != function.blocks.end())
      function.normal_entry = &iter->getValue();
  } else {
    function.normal_entry = nullptr;
  }

  return function;
}
