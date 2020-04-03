// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "dart.h"

#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"

using namespace llvm;

namespace {

StringRef tool_name;

LLVM_ATTRIBUTE_NORETURN void error(Twine message) {
  WithColor::error(errs(), "llvm-codegen") << message << ".\n";
  errs().flush();
  exit(1);
}

LLVM_ATTRIBUTE_NORETURN void error(Error e) {
  assert(e);
  std::string buf;
  raw_string_ostream os(buf);
  logAllUnhandledErrors(std::move(e), os);
  os.flush();
  WithColor::error(errs(), tool_name) << buf;
  exit(1);
}

LLVM_ATTRIBUTE_NORETURN void reportError(StringRef File, std::error_code EC) {
  assert(EC);
  error(createFileError(File, EC));
}

// We need a prelude function for printing to help get something functional
// up off the ground.
class DartPrint : public DartValue {
 public:
  Type* GetType(BasicBlockBuilder& bbb) const override {
    auto& ctx = bbb.Context();
    auto int8ty = IntegerType::getInt8Ty(ctx);
    auto i8ptr = PointerType::get(int8ty, 0);
    SmallVector<Type*, 1> arg_types;
    arg_types.push_back(i8ptr);
    return FunctionType::get(Type::getVoidTy(ctx), arg_types, false);
  }
  Value* Make(BasicBlockBuilder& bbb) const override {
    auto ft = dyn_cast<FunctionType>(GetType(bbb));
    if (ft == nullptr) return nullptr;
    return Function::Create(ft, Function::ExternalLinkage, "dart:core::print",
                            bbb.Module());
  }
};

cl::opt<std::string> sexpr_file(cl::Positional,
                                cl::desc("The input S-Expression file"));
cl::opt<std::string> dump_obj(
    "dump-obj",
    cl::desc("Specifies where to output the .o file"));

void Dump(Module* module, StringRef file, TargetMachine::CodeGenFileType type) {
  legacy::PassManager pm;
  std::error_code ec;
  raw_fd_ostream out(file, ec);
  if (ec) reportError(file, ec);
  Triple target_triple{sys::getDefaultTargetTriple()};
  TargetOptions options;
  std::string err;
  const Target* the_target =
      TargetRegistry::lookupTarget(target_triple.getTriple(), err);
  if (the_target == nullptr) error(err);
  std::unique_ptr<TargetMachine> target(the_target->createTargetMachine(
      target_triple.getTriple(), "generic", "", options, Reloc::PIC_));

  if (target->addPassesToEmitFile(pm, out, nullptr, type, false))
    error("couldn't add pass to emit file");
  pm.run(*module);
}

}  // namespace

int main(int argc, const char** argv) {
  // Init llvm
  InitLLVM X(argc, argv);
  InitializeAllTargetInfos();
  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmParsers();
  InitializeAllAsmPrinters();

  // Basic init
  tool_name = argv[0];
  cl::ParseCommandLineOptions(argc, argv, "llvm system compiler\n");

  // Read in the file
  auto file_or = MemoryBuffer::getFile(argv[1]);
  if (!file_or) reportError(argv[1], file_or.getError());
  std::unique_ptr<MemoryBuffer> file = std::move(file_or.get());

  // Parse the file
  dart::Zone zone;
  dart::SExpParser parser(&zone, file->getBufferStart(), file->getBufferSize());
  dart::SExpression* root = parser.Parse();
  if (root == nullptr)
    error(Twine("SExpParser failed: ") + parser.error_message());

  // Setup our basic prelude
  StringMap<const DartValue*> prelude;
  DartPrint print;
  prelude["dart:core::print"] = &print;

  // Convert the function into an error checked format
  auto function_or = MakeFunction(&zone, root, prelude);
  if (!function_or) error(function_or.takeError());
  auto dart_function = std::move(*function_or);
  if (!dart_function.normal_entry)
    error(Twine("function ") + dart_function.name + " has no normal-entry");

  // Setup state for output an LLVMModule
  LLVMContext context;
  auto module = llvm::make_unique<Module>(argv[1], context);
  auto function_type = FunctionType::get(Type::getVoidTy(context), {}, false);
  auto function = Function::Create(function_type, Function::ExternalLinkage,
                                   dart_function.name, module.get());
  FunctionBuilder fb{context, *module, *function};
  for (auto& bbkey : dart_function.blocks) {
    auto& bb = bbkey.getValue();
    auto llvmbb = fb.AddBasicBlock(bb.name);
    BasicBlockBuilder bbb{llvmbb, fb};
    for (auto& inst : bb.instructions) {
      inst->Build(bbb);
    }
  }

  // Dump and print the file
  if (!dump_obj.empty())
    Dump(module.get(), dump_obj, LLVMTargetMachine::CGFT_ObjectFile);

  module->print(llvm::outs(), nullptr);

  return 0;
}
