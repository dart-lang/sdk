// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/WithColor.h"

using namespace llvm;

namespace {

StringRef tool_name;

LLVM_ATTRIBUTE_NORETURN void error(Twine message) {
  WithColor::error(errs(), "llvm-codegen") << message << ".\n";
  errs().flush();
  exit(1);
}

}  // namespace

int main(int argc, char** argv) {
  InitLLVM X(argc, argv);

  LLVMContext context;
  SMDiagnostic err;
  if (argc != 2) error("exactly one argument is taken");
  tool_name = argv[0];
  std::unique_ptr<Module> mod = parseIRFile(argv[1], err, context);
  if (mod == nullptr) {
    err.print(tool_name.data(), errs());
    exit(1);
  }
  mod->print(outs(), nullptr);
}
