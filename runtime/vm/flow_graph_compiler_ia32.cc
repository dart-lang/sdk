// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/flow_graph_compiler.h"

#include "vm/compiler_stats.h"
#include "vm/longjump.h"

namespace dart {

DECLARE_FLAG(bool, compiler_stats);

void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s.";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


void FlowGraphCompiler::CompileGraph() {
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::graphcompiler_timer);
  Bailout("CompileGraph");
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  UNIMPLEMENTED();
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  UNIMPLEMENTED();
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
