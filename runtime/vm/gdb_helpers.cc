// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/stacktrace.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/heap/safepoint.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/stack_frame.h"

namespace dart {

#if !defined(PRODUCT)

#if defined(__GNUC__)
// Older toolchains don't know about "retain"
#pragma GCC diagnostic ignored "-Wattributes"
#define GDB_HELPER extern "C" __attribute__((used, retain))
#else
#define GDB_HELPER extern "C"
#endif

GDB_HELPER
void* _currentThread() {
  return OSThread::CurrentVMThread();
}

GDB_HELPER
void _printObjectPtr(uword object) {
  OS::PrintErr("%s\n",
               Object::Handle(static_cast<ObjectPtr>(object)).ToCString());
}

GDB_HELPER
Object* _handle(uword object) {
  return &Object::Handle(static_cast<ObjectPtr>(object));
}

GDB_HELPER
void _disassemble(uword pc) {
  Code& code = Code::Handle(Code::FindCodeUnsafe(pc));
  if (code.IsNull()) {
    OS::PrintErr("No code found\n");
  } else {
    Object& owner = Object::Handle(code.owner());
    if (owner.IsFunction()) {
      Disassembler::DisassembleCode(Function::Cast(owner), code,
                                    code.is_optimized());
    } else {
      Disassembler::DisassembleStub(code.Name(), code);
    }
  }
}

// An utility method for convenient printing of dart stack traces when
// inside 'gdb'. Note: This function will only work when there is a
// valid exit frame information. It will not work when a breakpoint is
// set in dart code and control is got inside 'gdb' without going through
// the runtime or native transition stub.
GDB_HELPER
void _printDartStackTrace() {
  const StackTrace& stacktrace = GetCurrentStackTrace(0);
  OS::PrintErr("=== Current Trace:\n%s===\n", stacktrace.ToCString());
}

// Like _printDartStackTrace, but works in a NoSafepointScope. Use it if you're
// in the middle of a GC or interested in stub frames.
GDB_HELPER
void _printStackTrace() {
  StackFrame::DumpCurrentTrace();
}

// Like _printDartStackTrace, but works when stopped in generated code.
// Must be called with the current fp, sp, and pc. I.e.,
//
// (gdb) print _printGeneratedStackTrace($rbp, $rsp, $rip)
GDB_HELPER
void _printGeneratedStackTrace(uword fp, uword sp, uword pc) {
  StackFrameIterator frames(fp, sp, pc, ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

#if defined(DART_DYNAMIC_MODULES)
// Like _printDartStackTrace, but works in the interpreter loop.
// Must be called with the current interpreter fp, sp, and pc.
// Note that sp[0] is not modified, but sp[1] will be trashed.
DART_EXPORT
void _printInterpreterStackTrace(ObjectPtr* fp,
                                 ObjectPtr* sp,
                                 const KBCInstr* pc) {
  Thread* thread = Thread::Current();
  sp[1] = Function::null();
  sp[2] = Bytecode::null();
  sp[3] = static_cast<ObjectPtr>(reinterpret_cast<uword>(pc));
  sp[4] = static_cast<ObjectPtr>(reinterpret_cast<uword>(fp));
  ObjectPtr* exit_fp = sp + 1 + kKBCDartFrameFixedSize;
  thread->set_top_exit_frame_info(reinterpret_cast<uword>(exit_fp));
  thread->set_execution_state(Thread::kThreadInVM);
  _printDartStackTrace();
  thread->set_execution_state(Thread::kThreadInGenerated);
  thread->set_top_exit_frame_info(0);
}
#endif  // defined(DART_DYNAMIC_MODULES)

class PrintObjectPointersVisitor : public ObjectPointerVisitor {
 public:
  PrintObjectPointersVisitor()
      : ObjectPointerVisitor(IsolateGroup::Current()) {}

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    for (ObjectPtr* p = first; p <= last; p++) {
      Object& obj = Object::Handle(*p);
      OS::PrintErr("%p: %s\n", p, obj.ToCString());
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    for (CompressedObjectPtr* p = first; p <= last; p++) {
      Object& obj = Object::Handle(p->Decompress(heap_base));
      OS::PrintErr("%p: %s\n", p, obj.ToCString());
    }
  }
#endif
};

GDB_HELPER
void _printStackTraceWithLocals() {
  PrintObjectPointersVisitor visitor;
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame->VisitObjectPointers(&visitor);
    frame = frames.NextFrame();
  }
}

#endif  // !PRODUCT

}  // namespace dart
