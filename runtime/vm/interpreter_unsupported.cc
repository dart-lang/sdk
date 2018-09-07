// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME) && defined(TARGET_OS_WINDOWS)

#include "vm/interpreter.h"

#include "platform/assert.h"
#include "vm/object.h"

namespace dart {

IntrinsicHandler Interpreter::intrinsics_[Interpreter::kIntrinsicCount];

void Interpreter::InitOnce() {
  UNIMPLEMENTED();
}

Interpreter::Interpreter() {
  UNIMPLEMENTED();
}

Interpreter::~Interpreter() {
  UNIMPLEMENTED();
}

Interpreter* Interpreter::Current() {
  UNIMPLEMENTED();
  return NULL;
}

#if defined(DEBUG)
bool Interpreter::IsTracingExecution() const {
  UNIMPLEMENTED();
  return false;
}

void Interpreter::TraceInstruction(uint32_t* pc) const {
  UNIMPLEMENTED();
}
#endif  // defined(DEBUG)

void Interpreter::Exit(Thread* thread,
                       RawObject** base,
                       RawObject** frame,
                       uint32_t* pc) {
  UNIMPLEMENTED();
}

void Interpreter::CallRuntime(Thread* thread,
                              RawObject** base,
                              RawObject** exit_frame,
                              uint32_t* pc,
                              intptr_t argc_tag,
                              RawObject** args,
                              RawObject** result,
                              uword target) {
  UNIMPLEMENTED();
}

bool Interpreter::InvokeCompiled(Thread* thread,
                                 RawFunction* function,
                                 RawObject** call_base,
                                 RawObject** call_top,
                                 uint32_t** pc,
                                 RawObject*** FP,
                                 RawObject*** SP) {
  UNIMPLEMENTED();
  return false;
}

bool Interpreter::ProcessInvocation(bool* invoked,
                                    Thread* thread,
                                    RawFunction* function,
                                    RawObject** call_base,
                                    RawObject** call_top,
                                    uint32_t** pc,
                                    RawObject*** FP,
                                    RawObject*** SP) {
  UNIMPLEMENTED();
  return false;
}

bool Interpreter::Invoke(Thread* thread,
                         RawObject** call_base,
                         RawObject** call_top,
                         uint32_t** pc,
                         RawObject*** FP,
                         RawObject*** SP) {
  UNIMPLEMENTED();
  return false;
}

void Interpreter::InlineCacheMiss(int checked_args,
                                  Thread* thread,
                                  RawICData* icdata,
                                  RawObject** args,
                                  RawObject** top,
                                  uint32_t* pc,
                                  RawObject** FP,
                                  RawObject** SP) {
  UNIMPLEMENTED();
}

bool Interpreter::InstanceCall1(Thread* thread,
                                RawICData* icdata,
                                RawObject** call_base,
                                RawObject** top,
                                uint32_t** pc,
                                RawObject*** FP,
                                RawObject*** SP,
                                bool optimized) {
  UNIMPLEMENTED();
  return false;
}

bool Interpreter::InstanceCall2(Thread* thread,
                                RawICData* icdata,
                                RawObject** call_base,
                                RawObject** top,
                                uint32_t** pc,
                                RawObject*** FP,
                                RawObject*** SP,
                                bool optimized) {
  UNIMPLEMENTED();
  return false;
}

void Interpreter::PrepareForTailCall(RawCode* code,
                                     RawImmutableArray* args_desc,
                                     RawObject** FP,
                                     RawObject*** SP,
                                     uint32_t** pc) {
  UNIMPLEMENTED();
}

bool Interpreter::Deoptimize(Thread* thread,
                             uint32_t** pc,
                             RawObject*** FP,
                             RawObject*** SP,
                             bool is_lazy) {
  UNIMPLEMENTED();
  return false;
}

bool Interpreter::AssertAssignable(Thread* thread,
                                   uint32_t* pc,
                                   RawObject** FP,
                                   RawObject** call_top,
                                   RawObject** args,
                                   RawSubtypeTestCache* cache) {
  UNIMPLEMENTED();
  return false;
}

RawObject* Interpreter::Call(const Function& function,
                             const Array& arguments_descriptor,
                             const Array& arguments,
                             Thread* thread) {
  UNIMPLEMENTED();
  return NULL;
}

RawObject* Interpreter::Call(RawFunction* function,
                             RawArray* argdesc,
                             intptr_t argc,
                             RawObject* const* argv,
                             Thread* thread) {
  UNIMPLEMENTED();
  return NULL;
}

void Interpreter::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
  UNIMPLEMENTED();
}

void Interpreter::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME) && defined(TARGET_OS_WINDOWS)
