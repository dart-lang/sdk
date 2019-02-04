// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_INTERPRETER_H_
#define RUNTIME_VM_INTERPRETER_H_

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/method_recognizer.h"
#include "vm/constants_kbc.h"

namespace dart {

class Isolate;
class RawObject;
class InterpreterSetjmpBuffer;
class Thread;
class Code;
class Array;
class RawICData;
class RawImmutableArray;
class RawArray;
class RawObjectPool;
class RawFunction;
class RawString;
class RawSubtypeTestCache;
class ObjectPointerVisitor;

class LookupCache : public ValueObject {
 public:
  LookupCache() {
    ASSERT(Utils::IsPowerOfTwo(sizeof(Entry)));
    ASSERT(Utils::IsPowerOfTwo(sizeof(kNumEntries)));
    Clear();
  }

  void Clear();
  bool Lookup(intptr_t receiver_cid,
              RawString* function_name,
              RawFunction** target) const;
  void Insert(intptr_t receiver_cid,
              RawString* function_name,
              RawFunction* target);

 private:
  struct Entry {
    intptr_t receiver_cid;
    RawString* function_name;
    RawFunction* target;
    intptr_t padding;
  };

  static const intptr_t kNumEntries = 1024;
  static const intptr_t kTableMask = kNumEntries - 1;

  Entry entries_[kNumEntries];
};

// Interpreter intrinsic handler. It is invoked on entry to the intrinsified
// function via Intrinsic bytecode before the frame is setup.
// If the handler returns true then Intrinsic bytecode works as a return
// instruction returning the value in result. Otherwise interpreter proceeds to
// execute the body of the function.
typedef bool (*IntrinsicHandler)(Thread* thread,
                                 RawObject** FP,
                                 RawObject** result);

class Interpreter {
 public:
  static const uword kInterpreterStackUnderflowSize = 0x80;

  Interpreter();
  ~Interpreter();

  // The currently executing Interpreter instance, which is associated to the
  // current isolate
  static Interpreter* Current();

  // Low address (KBC stack grows up).
  uword stack_base() const { return stack_base_; }
  // Limit for StackOverflowError.
  uword overflow_stack_limit() const { return overflow_stack_limit_; }
  // High address (KBC stack grows up).
  uword stack_limit() const { return stack_limit_; }

  // Returns true if the interpreter's stack contains the given frame.
  // TODO(regis): We should rely on a new thread vm_tag to identify an
  // interpreter frame and not need this HasFrame() method.
  bool HasFrame(uword frame) const {
    return frame >= stack_base() && frame < stack_limit();
  }

  // Identify an entry frame by looking at its pc marker value.
  static bool IsEntryFrameMarker(uword pc) { return (pc & 2) != 0; }

  RawObject* Call(const Function& function,
                  const Array& arguments_descriptor,
                  const Array& arguments,
                  Thread* thread);

  RawObject* Call(RawFunction* function,
                  RawArray* argdesc,
                  intptr_t argc,
                  RawObject* const* argv,
                  Thread* thread);

  void JumpToFrame(uword pc, uword sp, uword fp, Thread* thread);

  uword get_sp() const { return reinterpret_cast<uword>(fp_); }  // Yes, fp_.
  uword get_fp() const { return reinterpret_cast<uword>(fp_); }
  uword get_pc() const { return pc_; }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  void MajorGC() { lookup_cache_.Clear(); }

 private:
  uintptr_t* stack_;
  uword stack_base_;
  uword overflow_stack_limit_;
  uword stack_limit_;

  RawObject** fp_;
  uword pc_;
  DEBUG_ONLY(uint64_t icount_;)

  InterpreterSetjmpBuffer* last_setjmp_buffer_;

  RawObjectPool* pp_;  // Pool Pointer.
  RawArray* argdesc_;  // Arguments Descriptor: used to pass information between
                       // call instruction and the function entry.
  RawObject* special_[KernelBytecode::kSpecialIndexCount];

  LookupCache lookup_cache_;

  void Exit(Thread* thread,
            RawObject** base,
            RawObject** exit_frame,
            uint32_t* pc);

  bool Invoke(Thread* thread,
              RawObject** call_base,
              RawObject** call_top,
              uint32_t** pc,
              RawObject*** FP,
              RawObject*** SP);

  bool ProcessInvocation(bool* invoked,
                         Thread* thread,
                         RawFunction* function,
                         RawObject** call_base,
                         RawObject** call_top,
                         uint32_t** pc,
                         RawObject*** FP,
                         RawObject*** SP);

  bool InvokeCompiled(Thread* thread,
                      RawFunction* function,
                      RawObject** call_base,
                      RawObject** call_top,
                      uint32_t** pc,
                      RawObject*** FP,
                      RawObject*** SP);

  void InlineCacheMiss(int checked_args,
                       Thread* thread,
                       RawICData* icdata,
                       RawObject** call_base,
                       RawObject** top,
                       uint32_t* pc,
                       RawObject** FP,
                       RawObject** SP);

  bool InterfaceCall(Thread* thread,
                     RawString* target_name,
                     RawObject** call_base,
                     RawObject** call_top,
                     uint32_t** pc,
                     RawObject*** FP,
                     RawObject*** SP);

  bool InstanceCall1(Thread* thread,
                     RawICData* icdata,
                     RawObject** call_base,
                     RawObject** call_top,
                     uint32_t** pc,
                     RawObject*** FP,
                     RawObject*** SP,
                     bool optimized);

  bool InstanceCall2(Thread* thread,
                     RawICData* icdata,
                     RawObject** call_base,
                     RawObject** call_top,
                     uint32_t** pc,
                     RawObject*** FP,
                     RawObject*** SP,
                     bool optimized);

  bool AssertAssignable(Thread* thread,
                        uint32_t* pc,
                        RawObject** FP,
                        RawObject** call_top,
                        RawObject** args,
                        RawSubtypeTestCache* cache);

  bool AllocateInt64Box(Thread* thread,
                        int64_t value,
                        uint32_t* pc,
                        RawObject** FP,
                        RawObject** SP);

#if defined(DEBUG)
  // Returns true if tracing of executed instructions is enabled.
  bool IsTracingExecution() const;

  // Prints bytecode instruction at given pc for instruction tracing.
  void TraceInstruction(uint32_t* pc) const;

  bool IsWritingTraceFile() const;
  void FlushTraceBuffer();
  void WriteInstructionToTrace(uint32_t* pc);

  void* trace_file_;
  uint64_t trace_file_bytes_written_;

  static const intptr_t kTraceBufferSizeInBytes = 10 * KB;
  static const intptr_t kTraceBufferInstrs =
      kTraceBufferSizeInBytes / sizeof(KBCInstr);
  KBCInstr* trace_buffer_;
  intptr_t trace_buffer_idx_;
#endif  // defined(DEBUG)

  // Longjmp support for exceptions.
  InterpreterSetjmpBuffer* last_setjmp_buffer() { return last_setjmp_buffer_; }
  void set_last_setjmp_buffer(InterpreterSetjmpBuffer* buffer) {
    last_setjmp_buffer_ = buffer;
  }

  friend class InterpreterSetjmpBuffer;
  DISALLOW_COPY_AND_ASSIGN(Interpreter);
};

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#endif  // RUNTIME_VM_INTERPRETER_H_
