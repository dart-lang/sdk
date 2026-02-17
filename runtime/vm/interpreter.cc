// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if defined(DART_DYNAMIC_MODULES)

#include "vm/interpreter.h"

#include "vm/bytecode_reader.h"
#include "vm/class_id.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/lockers.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/native_function.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame_kbc.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(uint64_t,
            trace_interpreter_after,
            ULLONG_MAX,
            "Trace interpreter execution after instruction count reached.");
DEFINE_FLAG(charp,
            interpreter_trace_file,
            nullptr,
            "File to write a dynamic instruction trace to.");
DEFINE_FLAG(uint64_t,
            interpreter_trace_file_max_bytes,
            100 * MB,
            "Maximum size in bytes of the interpreter trace file");

// InterpreterSetjmpBuffer are linked together, and the last created one
// is referenced by the Interpreter. When an exception is thrown, the exception
// runtime looks at where to jump and finds the corresponding
// InterpreterSetjmpBuffer based on the stack pointer of the exception handler.
// The runtime then does a Longjmp on that buffer to return to the interpreter.
class InterpreterSetjmpBuffer {
 public:
  void Longjmp() {
    // "This" is now the last setjmp buffer.
    interpreter_->set_last_setjmp_buffer(this);
    DART_LONGJMP(buffer_, 1);
  }

  explicit InterpreterSetjmpBuffer(Interpreter* interpreter) {
    interpreter_ = interpreter;
    link_ = interpreter->last_setjmp_buffer();
    interpreter->set_last_setjmp_buffer(this);
    fp_ = interpreter->fp_;
  }

  ~InterpreterSetjmpBuffer() {
    ASSERT(interpreter_->last_setjmp_buffer() == this);
    interpreter_->set_last_setjmp_buffer(link_);
  }

  InterpreterSetjmpBuffer* link() const { return link_; }

  uword fp() const { return reinterpret_cast<uword>(fp_); }

  jmp_buf buffer_;

 private:
  ObjectPtr* fp_;
  Interpreter* interpreter_;
  InterpreterSetjmpBuffer* link_;

  friend class Interpreter;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(InterpreterSetjmpBuffer);
};

DART_FORCE_INLINE static ObjectPtr* SavedCallerFP(ObjectPtr* FP) {
  return reinterpret_cast<ObjectPtr*>(
      static_cast<uword>(FP[kKBCSavedCallerFpSlotFromFp]));
}

DART_FORCE_INLINE static ObjectPtr* FrameArguments(ObjectPtr* FP,
                                                   intptr_t argc) {
  return FP - (kKBCDartFrameFixedSize + argc);
}

class InterpreterHelpers {
 public:
  template <typename type, typename compressed_type>
  DART_FORCE_INLINE static type GetField(ObjectPtr obj,
                                         intptr_t offset_in_words) {
    return obj->untag()->LoadCompressedPointer<type, compressed_type>(
        reinterpret_cast<compressed_type*>(
            static_cast<uword>(obj) - kHeapObjectTag +
            offset_in_words * kCompressedWordSize));
  }
  DART_FORCE_INLINE static void SetField(ObjectPtr obj,
                                         intptr_t offset_in_words,
                                         ObjectPtr value,
                                         Thread* thread) {
    obj->untag()->StoreCompressedPointer<ObjectPtr, CompressedObjectPtr>(
        reinterpret_cast<CompressedObjectPtr*>(
            static_cast<uword>(obj) - kHeapObjectTag +
            offset_in_words * kCompressedWordSize),
        value, thread);
  }

#define GET_FIELD_T(type, obj, offset_in_words)                                \
  InterpreterHelpers::GetField<type, Compressed##type>(obj, offset_in_words)
#define GET_FIELD(obj, offset_in_words)                                        \
  GET_FIELD_T(ObjectPtr, obj, offset_in_words)

  DART_FORCE_INLINE static TypeArgumentsPtr GetTypeArguments(
      Thread* thread,
      InstancePtr instance) {
    ClassPtr instance_class =
        thread->isolate_group()->class_table()->At(instance->GetClassId());
    return instance_class->untag()->num_type_arguments_ > 0
               ? GET_FIELD_T(TypeArgumentsPtr, instance,
                             instance_class->untag()
                                 ->host_type_arguments_field_offset_in_words_)
               : TypeArguments::null();
  }

  // The usage counter is actually a 'hotness' counter. For a Dart->Dart
  // call, both the caller's and callee's usage counters are incremented.
  DART_FORCE_INLINE static void IncrementUsageCounter(FunctionPtr f) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    f->untag()->usage_counter_++;
#endif
  }

  DART_FORCE_INLINE static bool CheckIndex(SmiPtr index, SmiPtr length) {
    return !index->IsHeapObject() && (static_cast<intptr_t>(index) >= 0) &&
           (static_cast<intptr_t>(index) < static_cast<intptr_t>(length));
  }

  DART_FORCE_INLINE static intptr_t ArgDescTypeArgsLen(ArrayPtr argdesc) {
    return Smi::Value(Smi::RawCast(
        argdesc->untag()->element(ArgumentsDescriptor::kTypeArgsLenIndex)));
  }

  DART_FORCE_INLINE static intptr_t ArgDescArgCount(ArrayPtr argdesc) {
    return Smi::Value(Smi::RawCast(
        argdesc->untag()->element(ArgumentsDescriptor::kCountIndex)));
  }

  DART_FORCE_INLINE static intptr_t ArgDescPosCount(ArrayPtr argdesc) {
    return Smi::Value(Smi::RawCast(
        argdesc->untag()->element(ArgumentsDescriptor::kPositionalCountIndex)));
  }

  DART_FORCE_INLINE static BytecodePtr FrameBytecode(ObjectPtr* FP) {
    ASSERT(FP[kKBCPcMarkerSlotFromFp]->GetClassId() == kBytecodeCid);
    return static_cast<BytecodePtr>(FP[kKBCPcMarkerSlotFromFp]);
  }

  DART_FORCE_INLINE static bool FieldNeedsGuardUpdate(Thread* thread,
                                                      FieldPtr field,
                                                      ObjectPtr value) {
    if (!thread->isolate_group()->use_field_guards()) {
      return false;
    }

    // The interpreter should never see a cloned field.
    ASSERT(field->untag()->owner()->GetClassId() != kFieldCid);

    const classid_t guarded_cid = field->untag()->guarded_cid_;

    if (guarded_cid == kDynamicCid) {
      // Field is not guarded.
      return false;
    }

    const classid_t nullability_cid = field->untag()->is_nullable_;
    const classid_t value_cid = value->GetClassId();

    if (nullability_cid == value_cid) {
      // Storing null into a nullable field.
      return false;
    }

    if (guarded_cid != value_cid) {
      // First assignment (guarded_cid == kIllegalCid) or
      // field no longer monomorphic or
      // field has become nullable.
      return true;
    }

    intptr_t guarded_list_length =
        Smi::Value(field->untag()->guarded_list_length());

    if (guarded_list_length >= Field::kUnknownFixedLength) [[unlikely]] {
      // Guarding length, check this in the runtime.
      return true;
    }

    if (field->untag()->static_type_exactness_state_ >=
        StaticTypeExactnessState::Uninitialized().Encode()) [[unlikely]] {
      // Guarding "exactness", check this in the runtime.
      return true;
    }

    // Everything matches.
    return false;
  }

  DART_FORCE_INLINE static bool IsAllocateFinalized(ClassPtr cls) {
    return Class::ClassFinalizedBits::decode(cls->untag()->state_bits_) ==
           UntaggedClass::kAllocateFinalized;
  }
};

DART_FORCE_INLINE static const KBCInstr* SavedCallerPC(ObjectPtr* FP) {
  return reinterpret_cast<const KBCInstr*>(
      static_cast<uword>(FP[kKBCSavedCallerPcSlotFromFp]));
}

DART_FORCE_INLINE static FunctionPtr FrameFunction(ObjectPtr* FP) {
  return Function::RawCast(FP[kKBCFunctionSlotFromFp]);
}

void LookupCache::Clear() {
  for (intptr_t i = 0; i < kNumEntries; i++) {
    entries_[i].receiver_cid = kIllegalCid;
  }
}

bool LookupCache::Lookup(intptr_t receiver_cid,
                         StringPtr function_name,
                         ArrayPtr arguments_descriptor,
                         FunctionPtr* target) const {
  ASSERT(receiver_cid != kIllegalCid);  // Sentinel value.

  const intptr_t hash = receiver_cid ^ static_cast<intptr_t>(function_name) ^
                        static_cast<intptr_t>(arguments_descriptor);
  const intptr_t probe1 = hash & kTableMask;
  if (entries_[probe1].receiver_cid == receiver_cid &&
      entries_[probe1].function_name == function_name &&
      entries_[probe1].arguments_descriptor == arguments_descriptor) {
    *target = entries_[probe1].target;
    return true;
  }

  intptr_t probe2 = (hash >> 3) & kTableMask;
  if (entries_[probe2].receiver_cid == receiver_cid &&
      entries_[probe2].function_name == function_name &&
      entries_[probe2].arguments_descriptor == arguments_descriptor) {
    *target = entries_[probe2].target;
    return true;
  }

  return false;
}

void LookupCache::Insert(intptr_t receiver_cid,
                         StringPtr function_name,
                         ArrayPtr arguments_descriptor,
                         FunctionPtr target) {
  // Otherwise we have to clear the cache or rehash on scavenges too.
  ASSERT(function_name->IsOldObject());
  ASSERT(arguments_descriptor->IsOldObject());
  ASSERT(target->IsOldObject());

  const intptr_t hash = receiver_cid ^ static_cast<intptr_t>(function_name) ^
                        static_cast<intptr_t>(arguments_descriptor);
  const intptr_t probe1 = hash & kTableMask;
  if (entries_[probe1].receiver_cid == kIllegalCid) {
    entries_[probe1].receiver_cid = receiver_cid;
    entries_[probe1].function_name = function_name;
    entries_[probe1].arguments_descriptor = arguments_descriptor;
    entries_[probe1].target = target;
    return;
  }

  const intptr_t probe2 = (hash >> 3) & kTableMask;
  if (entries_[probe2].receiver_cid == kIllegalCid) {
    entries_[probe2].receiver_cid = receiver_cid;
    entries_[probe2].function_name = function_name;
    entries_[probe2].arguments_descriptor = arguments_descriptor;
    entries_[probe2].target = target;
    return;
  }

  entries_[probe1].receiver_cid = receiver_cid;
  entries_[probe1].function_name = function_name;
  entries_[probe1].arguments_descriptor = arguments_descriptor;
  entries_[probe1].target = target;
}

Interpreter::Interpreter()
    : stack_(nullptr),
      fp_(nullptr),
      pp_(ObjectPool::null()),
      argdesc_(Array::null()),
      subtype_test_cache_(SubtypeTestCache::null()),
      lookup_cache_() {
  // Setup interpreter support first. Some of this information is needed to
  // setup the architecture state.
  // We allocate the stack here, the size is computed as the sum of
  // the size specified by the user and the buffer space needed for
  // handling stack overflow exceptions. To be safe in potential
  // stack underflows we also add some underflow buffer space.
  stack_ = new uintptr_t[(OSThread::GetSpecifiedStackSize() +
                          OSThread::kStackSizeBufferMax +
                          kInterpreterStackUnderflowSize) /
                         sizeof(uintptr_t)];
  // Low address.
  stack_base_ =
      reinterpret_cast<uword>(stack_) + kInterpreterStackUnderflowSize;
  // Limit for StackOverflowError.
  overflow_stack_limit_ = stack_base_ + OSThread::GetSpecifiedStackSize();
  // High address.
  stack_limit_ = overflow_stack_limit_ + OSThread::kStackSizeBufferMax;

  fp_ = reinterpret_cast<ObjectPtr*>(stack_base_);

  last_setjmp_buffer_ = nullptr;

  DEBUG_ONLY(icount_ = 1);  // So that tracing after 0 traces first bytecode.

#if defined(DEBUG)
  trace_file_bytes_written_ = 0;
  trace_file_ = nullptr;
  if (FLAG_interpreter_trace_file != nullptr) {
    Dart_FileOpenCallback file_open = Dart::file_open_callback();
    if (file_open != nullptr) {
      trace_file_ = file_open(FLAG_interpreter_trace_file, /* write */ true);
      trace_buffer_ = new KBCInstr[kTraceBufferInstrs];
      trace_buffer_idx_ = 0;
    }
  }
#endif
}

Interpreter::~Interpreter() {
  delete[] stack_;
  pp_ = ObjectPool::null();
  argdesc_ = Array::null();
  subtype_test_cache_ = SubtypeTestCache::null();
#if defined(DEBUG)
  if (trace_file_ != nullptr) {
    FlushTraceBuffer();
    // Close the file.
    Dart_FileCloseCallback file_close = Dart::file_close_callback();
    if (file_close != nullptr) {
      file_close(trace_file_);
      trace_file_ = nullptr;
      delete[] trace_buffer_;
      trace_buffer_ = nullptr;
    }
  }
#endif
}

// Get the active Interpreter for the current isolate.
Interpreter* Interpreter::Current() {
  Thread* thread = Thread::Current();
  Interpreter* interpreter = thread->interpreter();
  if (interpreter == nullptr) {
    NoSafepointScope no_safepoint;
    interpreter = new Interpreter();
    thread->set_interpreter(interpreter);
  }
  return interpreter;
}

#if defined(DEBUG)
// Returns true if tracing of executed instructions is enabled.
// May be called on entry, when icount_ has not been incremented yet.
DART_FORCE_INLINE bool Interpreter::IsTracingExecution() const {
  return icount_ > FLAG_trace_interpreter_after;
}

// Prints bytecode instruction at given pc for instruction tracing.
DART_NOINLINE void Interpreter::TraceInstruction(const KBCInstr* pc,
                                                 ObjectPtr* FP) const {
  THR_Print("%" Pu64 " ", icount_);
  if (FLAG_support_disassembler) {
    auto const bytecode = Function::GetBytecode(FrameFunction(FP));
    KernelBytecodeDisassembler::Disassemble(
        reinterpret_cast<uword>(pc),
        reinterpret_cast<uword>(KernelBytecode::Next(pc)),
        Bytecode::PayloadStartOf(bytecode));
  } else {
    THR_Print("Disassembler not supported in this mode.\n");
  }
}

DART_FORCE_INLINE bool Interpreter::IsWritingTraceFile() const {
  return (trace_file_ != nullptr) &&
         (trace_file_bytes_written_ < FLAG_interpreter_trace_file_max_bytes);
}

void Interpreter::FlushTraceBuffer() {
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  if (file_write == nullptr) {
    return;
  }
  if (trace_file_bytes_written_ >= FLAG_interpreter_trace_file_max_bytes) {
    return;
  }
  const intptr_t bytes_to_write = Utils::Minimum(
      static_cast<uint64_t>(trace_buffer_idx_ * sizeof(KBCInstr)),
      FLAG_interpreter_trace_file_max_bytes - trace_file_bytes_written_);
  if (bytes_to_write == 0) {
    return;
  }
  file_write(trace_buffer_, bytes_to_write, trace_file_);
  trace_file_bytes_written_ += bytes_to_write;
  trace_buffer_idx_ = 0;
}

DART_NOINLINE void Interpreter::WriteInstructionToTrace(const KBCInstr* pc) {
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  if (file_write == nullptr) {
    return;
  }
  const KBCInstr* next = KernelBytecode::Next(pc);
  while ((trace_buffer_idx_ < kTraceBufferInstrs) && (pc != next)) {
    trace_buffer_[trace_buffer_idx_++] = *pc;
    ++pc;
  }
  if (trace_buffer_idx_ == kTraceBufferInstrs) {
    FlushTraceBuffer();
  }
}

#endif  // defined(DEBUG)

// Calls into the Dart runtime are based on this interface.
typedef void (*InterpreterRuntimeCall)(NativeArguments arguments);

// Calls to leaf Dart runtime functions are based on this interface.
typedef intptr_t (*InterpreterLeafRuntimeCall)(intptr_t r0,
                                               intptr_t r1,
                                               intptr_t r2,
                                               intptr_t r3);

// Calls to leaf float Dart runtime functions are based on this interface.
typedef double (*InterpreterLeafFloatRuntimeCall)(double d0, double d1);

void Interpreter::Exit(Thread* thread,
                       ObjectPtr* base,
                       ObjectPtr* frame,
                       const KBCInstr* pc) {
  frame[0] = Function::null();
  frame[1] = Bytecode::null();
  frame[2] = static_cast<ObjectPtr>(reinterpret_cast<uword>(pc));
  frame[3] = static_cast<ObjectPtr>(reinterpret_cast<uword>(base));

  ObjectPtr* exit_fp = frame + kKBCDartFrameFixedSize;
  thread->set_top_exit_frame_info(reinterpret_cast<uword>(exit_fp));
  fp_ = exit_fp;

#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("Exiting interpreter 0x%" Px " at fp_ 0x%" Px "\n",
              reinterpret_cast<uword>(this), reinterpret_cast<uword>(exit_fp));
  }
#endif
}

void Interpreter::Unexit(Thread* thread) {
#if !defined(PRODUCT)
  // For the profiler.
  ObjectPtr* exit_fp =
      reinterpret_cast<ObjectPtr*>(thread->top_exit_frame_info());
  ASSERT(exit_fp != 0);
  pc_ = SavedCallerPC(exit_fp);
  fp_ = SavedCallerFP(exit_fp);
#endif
  thread->set_top_exit_frame_info(0);
}

// Calling into runtime may trigger garbage collection and relocate objects,
// so all ObjectPtr pointers become outdated and should not be used across
// runtime calls.
// Note: functions below are marked DART_NOINLINE to recover performance where
// inlining these functions into the interpreter loop seemed to cause some code
// quality issues. Functions with the "returns_twice" attribute, such as setjmp,
// prevent reusing spill slots and large frame sizes.
static DART_NOINLINE bool InvokeRuntime(Thread* thread,
                                        Interpreter* interpreter,
                                        RuntimeFunction drt,
                                        const NativeArguments& args) {
  InterpreterSetjmpBuffer buffer(interpreter);
  if (!DART_SETJMP(buffer.buffer_)) {
    thread->set_vm_tag(reinterpret_cast<uword>(drt));
    drt(args);
    thread->set_vm_tag(VMTag::kDartInterpretedTagId);
    interpreter->Unexit(thread);
    return true;
  } else {
    return false;
  }
}

static DART_NOINLINE bool InvokeNative(Thread* thread,
                                       Interpreter* interpreter,
                                       NativeFunctionWrapper wrapper,
                                       NativeFunction function,
                                       NativeArguments* args) {
  InterpreterSetjmpBuffer buffer(interpreter);
  if (!DART_SETJMP(buffer.buffer_)) {
    thread->set_vm_tag(reinterpret_cast<uword>(function));
    wrapper(reinterpret_cast<Dart_NativeArguments>(args),
            reinterpret_cast<Dart_NativeFunction>(function));
    thread->set_vm_tag(VMTag::kDartInterpretedTagId);
    interpreter->Unexit(thread);
    return true;
  } else {
    return false;
  }
}

extern "C" {
// Note: The invocation stub follows the C ABI, so we cannot pass C++ struct
// values like ObjectPtr. In some calling conventions (IA32), ObjectPtr is
// passed/returned different from a pointer.
typedef uword /*ObjectPtr*/ (*invokestub)(
#if defined(DART_PRECOMPILED_RUNTIME)
    uword entry_point,
#else
    uword /*CodePtr*/ target_code,
#endif
    uword /*ArrayPtr*/ argdesc,
    ObjectPtr* arg0,
    Thread* thread);
}

DART_NOINLINE bool Interpreter::InvokeCompiled(Thread* thread,
                                               FunctionPtr function,
                                               ObjectPtr* call_base,
                                               ObjectPtr* call_top,
                                               const KBCInstr** pc,
                                               ObjectPtr** FP,
                                               ObjectPtr** SP) {
  ASSERT(Function::HasCode(function));
  ASSERT(function->untag()->code() != StubCode::LazyCompile().ptr());
  // TODO(regis): Once we share the same stack, try to invoke directly.
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("invoking compiled %s\n", Function::Handle(function).ToCString());
  }
#endif
  // On success, returns a RawInstance.  On failure, a RawError.
  invokestub volatile entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeFromBytecode().EntryPoint());
  ObjectPtr result;
  Exit(thread, *FP, call_top + 1, *pc);
  {
    InterpreterSetjmpBuffer buffer(this);
    if (!DART_SETJMP(buffer.buffer_)) {
#if defined(DART_INCLUDE_SIMULATOR)
      if (FLAG_use_simulator) {
        // We need to beware that bouncing between the interpreter and the
        // simulator may exhaust the C stack before exhausting either the
        // interpreter or simulator stacks.
        if (!thread->os_thread()->HasStackHeadroom()) {
          thread->SetStackLimit(-1);
        }
        result = bit_copy<ObjectPtr, int64_t>(Simulator::Current()->Call(
            reinterpret_cast<intptr_t>(entrypoint),
#if defined(DART_PRECOMPILED_RUNTIME)
            static_cast<intptr_t>(function->untag()->entry_point_),
#else
            static_cast<intptr_t>(function->untag()->code()),
#endif
            static_cast<intptr_t>(argdesc_),
            reinterpret_cast<intptr_t>(call_base),
            reinterpret_cast<intptr_t>(thread)));
      } else {
#endif
        result = static_cast<ObjectPtr>(entrypoint(
#if defined(DART_PRECOMPILED_RUNTIME)
            function->untag()->entry_point_,
#else
          static_cast<uword>(function->untag()->code()),
#endif
            static_cast<uword>(argdesc_), call_base, thread));
#if defined(DART_INCLUDE_SIMULATOR)
      }
#endif
      ASSERT(thread->vm_tag() == VMTag::kDartInterpretedTagId);
      ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
      Unexit(thread);
    } else {
      return false;
    }
  }
  // Pop args and push result.
  *SP = call_base;
  **SP = result;
  pp_ = InterpreterHelpers::FrameBytecode(*FP)->untag()->object_pool();

  // If the result is an error (not a Dart instance), it must either be rethrown
  // (in the case of an unhandled exception) or it must be returned to the
  // caller of the interpreter to be propagated.
  const intptr_t result_cid = result->GetClassId();
  if (result_cid == kUnhandledExceptionCid) [[unlikely]] {
    (*SP)[0] = UnhandledException::RawCast(result)->untag()->exception();
    (*SP)[1] = UnhandledException::RawCast(result)->untag()->stacktrace();
    (*SP)[2] = 0;  // Do not bypass debugger.
    (*SP)[3] = 0;  // Space for result.
    Exit(thread, *FP, *SP + 4, *pc);
    NativeArguments args(thread, 3, *SP, *SP + 3);
    if (!InvokeRuntime(thread, this, DRT_ReThrow, args)) {
      return false;
    }
    UNREACHABLE();
  }
  if (IsErrorClassId(result_cid)) [[unlikely]] {
    // Unwind to entry frame.
    fp_ = *FP;
    pc_ = SavedCallerPC(fp_);
    while (!IsEntryFrameMarker(pc_)) {
      fp_ = SavedCallerFP(fp_);
      pc_ = SavedCallerPC(fp_);
    }
    // Pop entry frame.
    fp_ = SavedCallerFP(fp_);
    special_[KernelBytecode::kExceptionSpecialIndex] = result;
    return false;
  }
  return true;
}

DART_FORCE_INLINE bool Interpreter::InvokeBytecode(Thread* thread,
                                                   FunctionPtr function,
                                                   ObjectPtr* call_base,
                                                   ObjectPtr* call_top,
                                                   const KBCInstr** pc,
                                                   ObjectPtr** FP,
                                                   ObjectPtr** SP) {
  ASSERT(Function::HasBytecode(function));
  ASSERT(Function::IsInterpreted(function));
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("invoking %s\n",
              Function::Handle(function).ToFullyQualifiedCString());
  }
#endif
  ObjectPtr* callee_fp = call_top + kKBCDartFrameFixedSize;
  ASSERT(function == FrameFunction(callee_fp));
  BytecodePtr bytecode = Function::GetBytecode(function);
  callee_fp[kKBCPcMarkerSlotFromFp] = bytecode;
  callee_fp[kKBCSavedCallerPcSlotFromFp] =
      static_cast<ObjectPtr>(reinterpret_cast<uword>(*pc));
  callee_fp[kKBCSavedCallerFpSlotFromFp] =
      static_cast<ObjectPtr>(reinterpret_cast<uword>(*FP));
  pp_ = bytecode->untag()->object_pool();
  *pc = reinterpret_cast<const KBCInstr*>(bytecode->untag()->instructions_);
  NOT_IN_PRODUCT(pc_ = *pc);  // For the profiler.
  *FP = callee_fp;
  NOT_IN_PRODUCT(fp_ = callee_fp);  // For the profiler.
  *SP = *FP - 1;
  return true;
}

DART_FORCE_INLINE bool Interpreter::Invoke(Thread* thread,
                                           ObjectPtr* call_base,
                                           ObjectPtr* call_top,
                                           const KBCInstr** pc,
                                           ObjectPtr** FP,
                                           ObjectPtr** SP) {
  ObjectPtr* callee_fp = call_top + kKBCDartFrameFixedSize;
  FunctionPtr function = FrameFunction(callee_fp);

  for (;;) {
    if (Function::IsInterpreted(function)) {
      return InvokeBytecode(thread, function, call_base, call_top, pc, FP, SP);
    } else if (Function::HasCode(function)) {
      return InvokeCompiled(thread, function, call_base, call_top, pc, FP, SP);
    }

    // Compile the function to either generate code or load bytecode.
    call_top[1] = 0;  // Code result.
    call_top[2] = function;
    Exit(thread, *FP, call_top + 3, *pc);
    NativeArguments native_args(thread, 1, call_top + 2, call_top + 1);
    if (!InvokeRuntime(thread, this, DRT_CompileFunction, native_args)) {
      return false;
    }
    // Reload objects after the call which may trigger GC.
    function = Function::RawCast(call_top[2]);

    ASSERT(Function::HasCode(function));
  }
}

DART_FORCE_INLINE bool Interpreter::InstanceCall(Thread* thread,
                                                 StringPtr target_name,
                                                 ObjectPtr* call_base,
                                                 ObjectPtr* top,
                                                 const KBCInstr** pc,
                                                 ObjectPtr** FP,
                                                 ObjectPtr** SP) {
  ObjectPtr null_value = Object::null();
  const intptr_t type_args_len =
      InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
  const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;

  intptr_t receiver_cid = call_base[receiver_idx]->GetClassId();

  FunctionPtr target;
  if (!lookup_cache_.Lookup(receiver_cid, target_name, argdesc_, &target))
      [[unlikely]] {
    // Table lookup miss.
    top[0] = null_value;  // Clean up slot as it may be visited by GC.
    top[1] = call_base[receiver_idx];
    top[2] = target_name;
    top[3] = argdesc_;
    top[4] = null_value;  // Result slot.

    Exit(thread, *FP, top + 5, *pc);
    NativeArguments native_args(thread, 3, /* argv */ top + 1,
                                /* result */ top + 4);
    if (!InvokeRuntime(thread, this, DRT_InterpretedInstanceCallMissHandler,
                       native_args)) {
      return false;
    }

    target = static_cast<FunctionPtr>(top[4]);
    target_name = static_cast<StringPtr>(top[2]);
    argdesc_ = static_cast<ArrayPtr>(top[3]);
  }

  if (target != Function::null()) {
    lookup_cache_.Insert(receiver_cid, target_name, argdesc_, target);
    top[0] = target;
    return Invoke(thread, call_base, top, pc, FP, SP);
  }

  // The miss handler should only fail to return a function in AOT mode,
  // in which case we need to call DRT_InvokeNoSuchMethod, which
  // walks the receiver appropriately in this case.
#if defined(DART_PRECOMPILED_RUNTIME)

  // The receiver, name, and argument descriptor are already in the appropriate
  // places on the stack from the previous call.
  ASSERT(top[4] == null_value);

  // Allocate array of arguments.
  {
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
    ASSERT_EQUAL(top - call_base, argc);

    top[5] = Smi::New(argc);  // length
    top[6] = null_value;      // type
    Exit(thread, *FP, top + 7, *pc);
    NativeArguments native_args(thread, 2, /* argv */ top + 5,
                                /* result */ top + 4);
    if (!InvokeRuntime(thread, this, DRT_AllocateArray, native_args)) {
      return false;
    }

    // Copy arguments into the newly allocated array.
    ArrayPtr array = Array::RawCast(top[4]);
    for (intptr_t i = 0; i < argc; i++) {
      array->untag()->set_element(i, call_base[i], thread);
    }
  }

  {
    Exit(thread, *FP, top + 5, *pc);
    NativeArguments native_args(thread, 4, /* argv */ top + 1,
                                /* result */ top);
    if (!InvokeRuntime(thread, this, DRT_InvokeNoSuchMethod, native_args)) {
      return false;
    }

    // Pop the call args and push the result.
    ObjectPtr result = top[0];
    *SP = call_base;
    **SP = result;
    pp_ = InterpreterHelpers::FrameBytecode(*FP)->untag()->object_pool();
  }
#else
  UNREACHABLE();
#endif

  return true;
}

// Note:
// All macro helpers are intended to be used only inside Interpreter::Call.

// Counts and prints executed bytecode instructions (in DEBUG mode).
#if defined(DEBUG)
#define TRACE_INSTRUCTION                                                      \
  if (IsTracingExecution()) {                                                  \
    TraceInstruction(pc, FP);                                                  \
  }                                                                            \
  if (IsWritingTraceFile()) {                                                  \
    WriteInstructionToTrace(pc);                                               \
  }                                                                            \
  icount_++;
#define BREAKPOINT_TRACE_ORIGINAL_INSTRUCTION                                  \
  do {                                                                         \
    if (IsTracingExecution()) {                                                \
      /* Use the original instruction count. */                                \
      auto const icount = icount_ - 1;                                         \
      auto const instr_size = KernelBytecode::kInstructionSize[op];            \
      THR_Print("%" Pu64 " ", icount);                                         \
      THR_Print("dispatching to original instruction\n");                      \
      THR_Print("%" Pu64 " ", icount);                                         \
      if (FLAG_support_disassembler) {                                         \
        KBCInstr temp[6];                                                      \
        *temp = op;                                                            \
        memmove(temp + 1, pc + 1, instr_size - 1);                             \
        KernelBytecodeDisassembler::Disassemble(                               \
            reinterpret_cast<uword>(temp),                                     \
            reinterpret_cast<uword>(temp + instr_size));                       \
      } else {                                                                 \
        THR_Print("Disassembler not supported in this mode.\n");               \
      }                                                                        \
    }                                                                          \
  } while (0)
#else
#define TRACE_INSTRUCTION
#define BREAKPOINT_TRACE_ORIGINAL_INSTRUCTION
#endif  // defined(DEBUG)

#if !defined(PRODUCT)
#define CALCULATE_SINGLE_STEPPING_OFFSET                                       \
  (thread->single_step() ? KernelBytecode::kNumOpcodes : 0)
#define CHECK_SINGLE_STEPPING                                                  \
  single_stepping_offset = CALCULATE_SINGLE_STEPPING_OFFSET
#define ADJUST_FOR_SINGLE_STEPPING(op) ((op) + single_stepping_offset)
#else
#define ADJUST_FOR_SINGLE_STEPPING(op) (op)
#define CHECK_SINGLE_STEPPING
#endif  // !defined(PRODUCT)

// Decode opcode and A part of the given value and dispatch to the
// corresponding bytecode handler.
#if defined(DART_HAS_COMPUTED_GOTO)
#define DISPATCH_OP(val)                                                       \
  do {                                                                         \
    op = (val);                                                                \
    TRACE_INSTRUCTION                                                          \
    goto* dispatch[ADJUST_FOR_SINGLE_STEPPING(op)];                            \
  } while (0)
#if !defined(PRODUCT)
// The breakpoint should dispatch to the single step handler, if any, in case
// the breakpoint was set on a call that should then be stepped into or over
// appropriately. Note that op has already been set to the original opcode
// that had been replaced with the breakpoint opcode during patching.
#define BREAKPOINT_DISPATCH                                                    \
  do {                                                                         \
    BREAKPOINT_TRACE_ORIGINAL_INSTRUCTION;                                     \
    goto* dispatch[ADJUST_FOR_SINGLE_STEPPING(op)];                            \
  } while (0)
// The dispatch from a single step check back to the original instruction
// implementation should ignore single_stepping_offset.
#define DISPATCH_ORIGINAL_OPCODE goto* dispatch[op]
#endif  // !defined(PRODUCT)
#else
#define DISPATCH_OP(val)                                                       \
  do {                                                                         \
    op = (val);                                                                \
    TRACE_INSTRUCTION                                                          \
    goto SwitchDispatch;                                                       \
  } while (0)
#if !defined(PRODUCT)
// The breakpoint should dispatch to the single step handler, if any, in case
// the breakpoint was set on a call that should then be stepped into or over
// appropriately. Note that op has already been set to the original opcode
// that had been replaced with the breakpoint opcode during patching.
#define BREAKPOINT_DISPATCH                                                    \
  do {                                                                         \
    BREAKPOINT_TRACE_ORIGINAL_INSTRUCTION;                                     \
    goto SwitchDispatch;                                                       \
  } while (0)
// The dispatch from a single step check back to the original instruction
// implementation should ignore single_stepping_offset.
#define DISPATCH_ORIGINAL_OPCODE goto SwitchDispatchNoSingleStep
#endif  // !defined(PRODUCT)
#endif  // defined(DART_HAS_COMPUTED_GOTO)

// Fetch next operation from PC and dispatch.
#define DISPATCH() DISPATCH_OP(*pc)

// Load target of a jump instruction into PC.
#define LOAD_JUMP_TARGET() pc = rT

#define BYTECODE_ENTRY_LABEL(Name) bc##Name:
#define BYTECODE_WIDE_ENTRY_LABEL(Name)                                        \
  static_assert(KernelBytecode::IsWide(KernelBytecode::k##Name##_Wide));       \
  bc##Name##_Wide:
#define BYTECODE_IMPL_LABEL(Name) bc##Name##Impl:
#define GOTO_BYTECODE_IMPL(Name) goto bc##Name##Impl;

// Define entry point that handles bytecode Name with the given operand format.
#define BYTECODE(Name, Operands) BYTECODE_HEADER_##Operands(Name)

// Helpers to decode common instruction formats. Used in conjunction with
// BYTECODE() macro.

#define BYTECODE_HEADER_0(Name)                                                \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  pc += 1;

#define BYTECODE_HEADER_A(Name)                                                \
  uint32_t rA;                                                                 \
  USE(rA);                                                                     \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rA = pc[1];                                                                  \
  pc += 2;

#define BYTECODE_HEADER_D(Name)                                                \
  uint32_t rD;                                                                 \
  USE(rD);                                                                     \
  BYTECODE_WIDE_ENTRY_LABEL(Name)                                              \
  rD = static_cast<uint32_t>(pc[1]) | (static_cast<uint32_t>(pc[2]) << 8) |    \
       (static_cast<uint32_t>(pc[3]) << 16) |                                  \
       (static_cast<uint32_t>(pc[4]) << 24);                                   \
  pc += 5;                                                                     \
  GOTO_BYTECODE_IMPL(Name);                                                    \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rD = pc[1];                                                                  \
  pc += 2;                                                                     \
  BYTECODE_IMPL_LABEL(Name)

#define BYTECODE_HEADER_X(Name)                                                \
  int32_t rX;                                                                  \
  USE(rX);                                                                     \
  BYTECODE_WIDE_ENTRY_LABEL(Name)                                              \
  rX = static_cast<int32_t>(static_cast<uint32_t>(pc[1]) |                     \
                            (static_cast<uint32_t>(pc[2]) << 8) |              \
                            (static_cast<uint32_t>(pc[3]) << 16) |             \
                            (static_cast<uint32_t>(pc[4]) << 24));             \
  pc += 5;                                                                     \
  GOTO_BYTECODE_IMPL(Name);                                                    \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rX = static_cast<int8_t>(pc[1]);                                             \
  pc += 2;                                                                     \
  BYTECODE_IMPL_LABEL(Name)

#define BYTECODE_HEADER_T(Name)                                                \
  const KBCInstr* rT;                                                          \
  USE(rT);                                                                     \
  BYTECODE_WIDE_ENTRY_LABEL(Name)                                              \
  rT = pc + (static_cast<int32_t>((static_cast<uint32_t>(pc[1]) << 8) |        \
                                  (static_cast<uint32_t>(pc[2]) << 16) |       \
                                  (static_cast<uint32_t>(pc[3]) << 24)) >>     \
             8);                                                               \
  pc += 4;                                                                     \
  GOTO_BYTECODE_IMPL(Name);                                                    \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rT = pc + static_cast<int8_t>(pc[1]);                                        \
  pc += 2;                                                                     \
  BYTECODE_IMPL_LABEL(Name)

#define BYTECODE_HEADER_A_E(Name)                                              \
  uint32_t rA, rE;                                                             \
  USE(rA);                                                                     \
  USE(rE);                                                                     \
  BYTECODE_WIDE_ENTRY_LABEL(Name)                                              \
  rA = pc[1];                                                                  \
  rE = static_cast<uint32_t>(pc[2]) | (static_cast<uint32_t>(pc[3]) << 8) |    \
       (static_cast<uint32_t>(pc[4]) << 16) |                                  \
       (static_cast<uint32_t>(pc[5]) << 24);                                   \
  pc += 6;                                                                     \
  GOTO_BYTECODE_IMPL(Name);                                                    \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rA = pc[1];                                                                  \
  rE = pc[2];                                                                  \
  pc += 3;                                                                     \
  BYTECODE_IMPL_LABEL(Name)

#define BYTECODE_HEADER_A_Y(Name)                                              \
  uint32_t rA;                                                                 \
  int32_t rY;                                                                  \
  USE(rA);                                                                     \
  USE(rY);                                                                     \
  BYTECODE_WIDE_ENTRY_LABEL(Name)                                              \
  rA = pc[1];                                                                  \
  rY = static_cast<int32_t>(static_cast<uint32_t>(pc[2]) |                     \
                            (static_cast<uint32_t>(pc[3]) << 8) |              \
                            (static_cast<uint32_t>(pc[4]) << 16) |             \
                            (static_cast<uint32_t>(pc[5]) << 24));             \
  pc += 6;                                                                     \
  GOTO_BYTECODE_IMPL(Name);                                                    \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rA = pc[1];                                                                  \
  rY = static_cast<int8_t>(pc[2]);                                             \
  pc += 3;                                                                     \
  BYTECODE_IMPL_LABEL(Name)

#define BYTECODE_HEADER_D_F(Name)                                              \
  uint32_t rD, rF;                                                             \
  USE(rD);                                                                     \
  USE(rF);                                                                     \
  BYTECODE_WIDE_ENTRY_LABEL(Name)                                              \
  rD = static_cast<uint32_t>(pc[1]) | (static_cast<uint32_t>(pc[2]) << 8) |    \
       (static_cast<uint32_t>(pc[3]) << 16) |                                  \
       (static_cast<uint32_t>(pc[4]) << 24);                                   \
  rF = pc[5];                                                                  \
  pc += 6;                                                                     \
  GOTO_BYTECODE_IMPL(Name);                                                    \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rD = pc[1];                                                                  \
  rF = pc[2];                                                                  \
  pc += 3;                                                                     \
  BYTECODE_IMPL_LABEL(Name)

#define BYTECODE_HEADER_A_B_C(Name)                                            \
  uint32_t rA, rB, rC;                                                         \
  USE(rA);                                                                     \
  USE(rB);                                                                     \
  USE(rC);                                                                     \
  BYTECODE_ENTRY_LABEL(Name)                                                   \
  rA = pc[1];                                                                  \
  rB = pc[2];                                                                  \
  rC = pc[3];                                                                  \
  pc += 4;

#define HANDLE_EXCEPTION                                                       \
  do {                                                                         \
    goto HandleException;                                                      \
  } while (0)

#define HANDLE_RETURN                                                          \
  do {                                                                         \
    pp_ = InterpreterHelpers::FrameBytecode(FP)->untag()->object_pool();       \
    CHECK_SINGLE_STEPPING;                                                     \
  } while (0)

// Runtime call helpers: handle invocation and potential exception after return.
#define INVOKE_RUNTIME(Func, Args)                                             \
  if (!InvokeRuntime(thread, this, Func, Args)) {                              \
    HANDLE_EXCEPTION;                                                          \
  } else {                                                                     \
    HANDLE_RETURN;                                                             \
  }

#define LOAD_CONSTANT(index) (pp_->untag()->data()[(index)].raw_obj_)
#define LOAD_CONSTANT_RAW(index) (pp_->untag()->data()[(index)].raw_value_)

#define UNBOX_INT64(value, obj, selector)                                      \
  int64_t value;                                                               \
  {                                                                            \
    if (!obj.IsHeapObject()) [[likely]] {                                      \
      value = Smi::Value(Smi::RawCast(obj));                                   \
    } else {                                                                   \
      if (obj == null_value) [[unlikely]] {                                    \
        SP[0] = selector.ptr();                                                \
        goto ThrowNullError;                                                   \
      }                                                                        \
      value = Integer::Value(Integer::RawCast(obj));                           \
    }                                                                          \
  }

#define BOX_INT64_RESULT(result)                                               \
  if (Smi::IsValid(result)) [[likely]] {                                       \
    SP[0] = Smi::New(static_cast<intptr_t>(result));                           \
  } else if (!AllocateMint(thread, result, pc, FP, SP)) {                      \
    HANDLE_EXCEPTION;                                                          \
  }                                                                            \
  ASSERT(Integer::Value(Integer::RawCast(SP[0])) == result);

#define UNBOX_DOUBLE(value, obj, selector)                                     \
  double value;                                                                \
  {                                                                            \
    if (obj == null_value) [[unlikely]] {                                      \
      SP[0] = selector.ptr();                                                  \
      goto ThrowNullError;                                                     \
    }                                                                          \
    value = Double::RawCast(obj)->untag()->value_;                             \
  }

#define BOX_DOUBLE_RESULT(result)                                              \
  if (!AllocateDouble(thread, result, pc, FP, SP)) {                           \
    HANDLE_EXCEPTION;                                                          \
  }                                                                            \
  ASSERT(Utils::DoublesBitEqual(Double::RawCast(SP[0])->untag()->value_,       \
                                result));

bool Interpreter::CopyParameters(Thread* thread,
                                 const KBCInstr** pc,
                                 ObjectPtr** FP,
                                 ObjectPtr** SP,
                                 const intptr_t num_fixed_params,
                                 const intptr_t num_opt_pos_params,
                                 const intptr_t num_opt_named_params,
                                 const intptr_t num_reserved_locals) {
  const intptr_t min_num_pos_args = num_fixed_params;
  const intptr_t max_num_pos_args = num_fixed_params + num_opt_pos_params;

  // Decode arguments descriptor.
  const intptr_t arg_count = InterpreterHelpers::ArgDescArgCount(argdesc_);
  const intptr_t pos_count = InterpreterHelpers::ArgDescPosCount(argdesc_);
  const intptr_t named_count = (arg_count - pos_count);

  // Check that got the right number of positional parameters.
  if ((min_num_pos_args > pos_count) || (pos_count > max_num_pos_args)) {
    return false;
  }

  // Copy all passed position arguments.
  ObjectPtr* first_arg = FrameArguments(*FP, arg_count);
  memmove(*SP + 1, first_arg, pos_count * kWordSize);

  if (num_opt_named_params != 0) {
    // This is a function with named parameters.
    // Walk the list of named parameters and their
    // default values encoded as pairs of LoadConstant instructions that
    // follows the entry point and find matching values via arguments
    // descriptor.

    intptr_t i = 0;  // argument position
    intptr_t j = 0;  // parameter position
    while ((j < num_opt_named_params) && (i < named_count)) {
      // Fetch formal parameter information: name, default value, target slot.
      const KBCInstr* load_name = *pc;
      const KBCInstr* load_value = KernelBytecode::Next(load_name);
      *pc = KernelBytecode::Next(load_value);
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_name));
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value));
      const uint8_t reg = KernelBytecode::DecodeA(load_name);
      ASSERT(reg == KernelBytecode::DecodeA(load_value));
      ASSERT(reg >= num_reserved_locals);

      StringPtr name = static_cast<StringPtr>(
          LOAD_CONSTANT(KernelBytecode::DecodeE(load_name)));
      if (name ==
          argdesc_->untag()->element(ArgumentsDescriptor::name_index(i))) {
        // Parameter was passed. Fetch passed value.
        const intptr_t arg_index =
            Smi::Value(static_cast<SmiPtr>(argdesc_->untag()->element(
                ArgumentsDescriptor::position_index(i))));
        (*FP)[reg] = first_arg[arg_index];
        ++i;  // Consume passed argument.
      } else {
        // Parameter was not passed. Fetch default value.
        (*FP)[reg] = LOAD_CONSTANT(KernelBytecode::DecodeE(load_value));
      }
      ++j;  // Next formal parameter.
    }

    // If we have unprocessed formal parameters then initialize them all
    // using default values.
    while (j < num_opt_named_params) {
      const KBCInstr* load_name = *pc;
      const KBCInstr* load_value = KernelBytecode::Next(load_name);
      *pc = KernelBytecode::Next(load_value);
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_name));
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value));
      const uint8_t reg = KernelBytecode::DecodeA(load_name);
      ASSERT(reg == KernelBytecode::DecodeA(load_value));
      ASSERT(reg >= num_reserved_locals);

      (*FP)[reg] = LOAD_CONSTANT(KernelBytecode::DecodeE(load_value));
      ++j;
    }

    // If we have unprocessed passed arguments that means we have mismatch
    // between formal parameters and concrete arguments. This can only
    // occur if the current function is a closure.
    if (i < named_count) {
      return false;
    }

    // SP points past copied arguments.
    *SP = *SP + num_fixed_params + num_opt_named_params;
  } else {
    if (named_count != 0) {
      // Function can't have both named and optional positional parameters.
      // This kind of mismatch can only occur if the current function
      // is a closure.
      return false;
    }

    // Process the list of default values encoded as a sequence of
    // LoadConstant instructions after EntryOpt bytecode.
    // Execute only those that correspond to parameters that were not passed.
    for (intptr_t i = num_fixed_params; i < pos_count; ++i) {
      ASSERT(KernelBytecode::IsLoadConstantOpcode(*pc));
      *pc = KernelBytecode::Next(*pc);
    }
    for (intptr_t i = pos_count; i < max_num_pos_args; ++i) {
      const KBCInstr* load_value = *pc;
      *pc = KernelBytecode::Next(load_value);
      ASSERT(KernelBytecode::IsLoadConstantOpcode(load_value));
      const uint8_t reg = KernelBytecode::DecodeA(load_value);
      ASSERT(reg == num_reserved_locals + i);
      (*FP)[reg] = LOAD_CONSTANT(KernelBytecode::DecodeE(load_value));
    }

    // SP points past the last copied parameter.
    *SP = *SP + max_num_pos_args;
  }

  return true;
}

bool Interpreter::AssertAssignable(Thread* thread,
                                   const KBCInstr* pc,
                                   ObjectPtr* FP,
                                   ObjectPtr* call_top,
                                   ObjectPtr* args,
                                   SubtypeTestCachePtr cache) {
  ObjectPtr null_value = Object::null();
  if (cache != null_value) {
    InstancePtr instance = Instance::RawCast(args[0]);
    AbstractTypePtr dst_type = AbstractType::RawCast(args[1]);
    TypeArgumentsPtr instantiator_type_arguments =
        static_cast<TypeArgumentsPtr>(args[2]);
    TypeArgumentsPtr function_type_arguments =
        static_cast<TypeArgumentsPtr>(args[3]);

    const intptr_t cid = instance->GetClassId();

    TypeArgumentsPtr instance_type_arguments =
        static_cast<TypeArgumentsPtr>(null_value);
    ObjectPtr instance_cid_or_function;

    TypeArgumentsPtr parent_function_type_arguments;
    TypeArgumentsPtr delayed_function_type_arguments;
    if (cid == kClosureCid) {
      ClosurePtr closure = static_cast<ClosurePtr>(instance);
      instance_type_arguments = closure->untag()->instantiator_type_arguments();
      parent_function_type_arguments =
          closure->untag()->function_type_arguments();
      delayed_function_type_arguments =
          closure->untag()->delayed_type_arguments();
      instance_cid_or_function =
          closure->untag()->function()->untag()->signature();
    } else {
      instance_cid_or_function = Smi::New(cid);

      ClassPtr instance_class = thread->isolate_group()->class_table()->At(cid);
      if (instance_class->untag()->num_type_arguments_ < 0) {
        goto AssertAssignableCallRuntime;
      } else if (instance_class->untag()->num_type_arguments_ > 0) {
        instance_type_arguments =
            GET_FIELD_T(TypeArgumentsPtr, instance,
                        instance_class->untag()
                            ->host_type_arguments_field_offset_in_words_);
      }
      parent_function_type_arguments =
          static_cast<TypeArgumentsPtr>(null_value);
      delayed_function_type_arguments =
          static_cast<TypeArgumentsPtr>(null_value);
    }

    ArrayPtr entries = cache->untag()->cache();
    const intptr_t num_inputs = cache->untag()->num_inputs_;
    // The search in a linear-based STC starts at 0.
    intptr_t probe = 0;
    if (SubtypeTestCache::IsHash(entries)) {
      // Perform the same hash as SubtypeTestCache::FindKeyOrUnused.
      //
      // Control flows to AssertAssignableCallRuntime if any of the individual
      // hashes are 0 (which denotes the hash is not yet computed).
      if (cid == kClosureCid) {
        auto sig = AbstractType::RawCast(instance_cid_or_function);
        probe = RawSmiValue(sig->untag()->hash());
        if (probe == 0) goto AssertAssignableCallRuntime;
      } else {
        probe = cid;
      }
      switch (num_inputs) {
        case 7: {
          intptr_t h = RawSmiValue(dst_type->untag()->hash());
          if (h == 0) goto AssertAssignableCallRuntime;
          probe = CombineHashes(probe, h);
        }
          FALL_THROUGH;
        case 6: {
          intptr_t h = TypeArguments::kAllDynamicHash;
          if (delayed_function_type_arguments != null_value) {
            h = RawSmiValue(delayed_function_type_arguments->untag()->hash());
            if (h == 0) goto AssertAssignableCallRuntime;
          }
          probe = CombineHashes(probe, h);
        }
          FALL_THROUGH;
        case 5: {
          intptr_t h = TypeArguments::kAllDynamicHash;
          if (parent_function_type_arguments != null_value) {
            h = RawSmiValue(parent_function_type_arguments->untag()->hash());
            if (h == 0) goto AssertAssignableCallRuntime;
          }
          probe = CombineHashes(probe, h);
        }
          FALL_THROUGH;
        case 4: {
          intptr_t h = TypeArguments::kAllDynamicHash;
          if (function_type_arguments != null_value) {
            h = RawSmiValue(function_type_arguments->untag()->hash());
            if (h == 0) goto AssertAssignableCallRuntime;
          }
          probe = CombineHashes(probe, h);
        }
          FALL_THROUGH;
        case 3: {
          intptr_t h = TypeArguments::kAllDynamicHash;
          if (instantiator_type_arguments != null_value) {
            h = RawSmiValue(instantiator_type_arguments->untag()->hash());
            if (h == 0) goto AssertAssignableCallRuntime;
          }
          probe = CombineHashes(probe, h);
        }
          FALL_THROUGH;
        case 2: {
          intptr_t h = TypeArguments::kAllDynamicHash;
          if (instance_type_arguments != null_value) {
            h = RawSmiValue(instance_type_arguments->untag()->hash());
            if (h == 0) goto AssertAssignableCallRuntime;
          }
          probe = CombineHashes(probe, h);
        }
          FALL_THROUGH;
        case 1:
          // Already included in the hash.
          break;
        default:
          UNREACHABLE();
      }
      probe = FinalizeHash(probe);
      // The number of entries for a hash-based cache is a power of 2,
      // so use it as a mask to get a valid entry index from the hash.
      probe = probe & (SubtypeTestCache::NumEntries(entries) - 1);
    }
    BoolPtr test_result = nullptr;
    auto loc = SubtypeTestCache::FindKeyOrUnusedFromProbe(
        entries, num_inputs, probe, instance_cid_or_function, dst_type,
        instance_type_arguments, instantiator_type_arguments,
        function_type_arguments, parent_function_type_arguments,
        delayed_function_type_arguments, &test_result);
    if (loc.present && test_result == Bool::True().ptr()) {
      return true;
    }
    // Either there is no matching entry or the matching entry had a false test
    // result, so a runtime call is needed to generate an appropriate error.
  }

AssertAssignableCallRuntime:
  // args[0]: Instance.
  // args[1]: Type.
  // args[2]: Instantiator type args.
  // args[3]: Function type args.
  // args[4]: Name.
  args[5] = cache;
  args[6] = Smi::New(kTypeCheckFromInline);
  args[7] = 0;  // Unused result.
  Exit(thread, FP, args + 8, pc);
  NativeArguments native_args(thread, 7, args, args + 7);
  return InvokeRuntime(thread, this, DRT_TypeCheck, native_args);
}

template <bool is_getter>
bool Interpreter::AssertAssignableField(Thread* thread,
                                        const KBCInstr* pc,
                                        ObjectPtr* FP,
                                        ObjectPtr* SP,
                                        InstancePtr instance,
                                        FieldPtr field,
                                        InstancePtr value) {
  AbstractTypePtr field_type = field->untag()->type();
  // Handle 'dynamic' early as it is not handled by the runtime type check.
  if ((field_type->GetClassId() == kTypeCid) &&
      (Type::RawCast(field_type)->untag()->type_class_id() == kDynamicCid)) {
    return true;
  }

  SubtypeTestCachePtr cache = subtype_test_cache_;
  if (cache == SubtypeTestCache::null()) [[unlikely]] {
    // Allocate new cache.
    SP[1] = instance;        // Preserve.
    SP[2] = field;           // Preserve.
    SP[3] = value;           // Preserve.
    SP[4] = Object::null();  // Result slot.

    Exit(thread, FP, SP + 5, pc);
    if (!InvokeRuntime(thread, this, DRT_AllocateSubtypeTestCache,
                       NativeArguments(thread, 0, /* argv */ SP + 4,
                                       /* retval */ SP + 4))) {
      return false;
    }

    // Reload objects after the call which may trigger GC.
    instance = static_cast<InstancePtr>(SP[1]);
    field = static_cast<FieldPtr>(SP[2]);
    value = static_cast<InstancePtr>(SP[3]);
    cache = static_cast<SubtypeTestCachePtr>(SP[4]);
    field_type = field->untag()->type();

    subtype_test_cache_ = cache;
  }

  // Push arguments of type test.
  SP[1] = value;
  SP[2] = field_type;
  // Provide type arguments of instance as instantiator.
  SP[3] = InterpreterHelpers::GetTypeArguments(thread, instance);
  SP[4] = Object::null();  // Implicit setters cannot be generic.
  SP[5] = is_getter ? Symbols::FunctionResult().ptr() : field->untag()->name();
  return AssertAssignable(thread, pc, FP, /* call_top */ SP + 5,
                          /* args */ SP + 1, cache);
}

ObjectPtr Interpreter::Call(const Function& function,
                            const Array& arguments_descriptor,
                            const Array& arguments,
                            Thread* thread) {
  return Call(function.ptr(), arguments_descriptor.ptr(), arguments.Length(),
              nullptr, arguments.ptr(), thread);
}

// Allocate a _Mint for the given int64_t value and puts it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateMint(Thread* thread,
                                             int64_t value,
                                             const KBCInstr* pc,
                                             ObjectPtr* FP,
                                             ObjectPtr* SP) {
  ASSERT(!Smi::IsValid(value));
  MintPtr result;
  if (TryAllocate(thread, kMintCid, Mint::InstanceSize(),
                  reinterpret_cast<ObjectPtr*>(&result))) {
    result->untag()->value_ = value;
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] =
        thread->isolate_group()->object_store()->mint_class();  // Class object.
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    Mint::RawCast(SP[0])->untag()->value_ = value;
    return true;
  }
}

// Allocate a _Double for the given double value and put it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateDouble(Thread* thread,
                                               double value,
                                               const KBCInstr* pc,
                                               ObjectPtr* FP,
                                               ObjectPtr* SP) {
  DoublePtr result;
  if (TryAllocate(thread, kDoubleCid, Double::InstanceSize(),
                  reinterpret_cast<ObjectPtr*>(&result))) {
    result->untag()->value_ = value;
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate_group()->object_store()->double_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    Double::RawCast(SP[0])->untag()->value_ = value;
    return true;
  }
}

// Allocate a _Float32x4 for the given simd value and put it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateFloat32x4(Thread* thread,
                                                  simd128_value_t value,
                                                  const KBCInstr* pc,
                                                  ObjectPtr* FP,
                                                  ObjectPtr* SP) {
  Float32x4Ptr result;
  if (TryAllocate(thread, kFloat32x4Cid, Float32x4::InstanceSize(),
                  reinterpret_cast<ObjectPtr*>(&result))) {
    value.writeTo(result->untag()->value_);
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate_group()->object_store()->float32x4_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    value.writeTo(Float32x4::RawCast(SP[0])->untag()->value_);
    return true;
  }
}

// Allocate _Float64x2 box for the given simd value and put it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateFloat64x2(Thread* thread,
                                                  simd128_value_t value,
                                                  const KBCInstr* pc,
                                                  ObjectPtr* FP,
                                                  ObjectPtr* SP) {
  Float64x2Ptr result;
  if (TryAllocate(thread, kFloat64x2Cid, Float64x2::InstanceSize(),
                  reinterpret_cast<ObjectPtr*>(&result))) {
    value.writeTo(result->untag()->value_);
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate_group()->object_store()->float64x2_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    value.writeTo(Float64x2::RawCast(SP[0])->untag()->value_);
    return true;
  }
}

// Allocate a _List with the given type arguments and length and put it into
// SP[0]. Returns false on exception.
bool Interpreter::AllocateArray(Thread* thread,
                                TypeArgumentsPtr type_args,
                                ObjectPtr length_object,
                                const KBCInstr* pc,
                                ObjectPtr* FP,
                                ObjectPtr* SP) {
  if (!length_object->IsHeapObject()) [[likely]] {
    const intptr_t length = Smi::Value(Smi::RawCast(length_object));
    if (static_cast<uintptr_t>(length) <=
        static_cast<uintptr_t>(Array::kMaxNewSpaceElements)) [[likely]] {
      ASSERT(Array::IsValidLength(length));
      ArrayPtr result;
      if (TryAllocate(thread, kArrayCid, Array::InstanceSize(length),
                      reinterpret_cast<ObjectPtr*>(&result))) {
        result->untag()->set_type_arguments(type_args);
        result->untag()->set_length(Smi::New(length));
        for (intptr_t i = 0; i < length; i++) {
          result->untag()->set_element(i, Object::null(), thread);
        }
        SP[0] = result;
        return true;
      }
    }
  }

  SP[0] = 0;  // Space for the result;
  SP[1] = length_object;
  SP[2] = type_args;
  Exit(thread, FP, SP + 3, pc);
  NativeArguments args(thread, 2, SP + 1, SP);
  return InvokeRuntime(thread, this, DRT_AllocateArray, args);
}

// Allocate a Record with the given shape and put it into SP[0].
// Returns false on exception.
bool Interpreter::AllocateRecord(Thread* thread,
                                 RecordShape shape,
                                 const KBCInstr* pc,
                                 ObjectPtr* FP,
                                 ObjectPtr* SP) {
  const intptr_t num_fields = shape.num_fields();
  RecordPtr result;
  if (TryAllocate(thread, kRecordCid, Record::InstanceSize(num_fields),
                  reinterpret_cast<ObjectPtr*>(&result))) {
    result->untag()->set_shape(shape.AsSmi());
    ObjectPtr null_value = Object::null();
    for (intptr_t i = 0; i < num_fields; i++) {
      result->untag()->set_field(i, null_value, thread);
    }
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = shape.AsSmi();
    Exit(thread, FP, SP + 2, pc);
    NativeArguments args(thread, 1, SP + 1, SP);
    return InvokeRuntime(thread, this, DRT_AllocateRecord, args);
  }
}

// Allocate a _Context with the given length and put it into SP[0].
// Returns false on exception.
bool Interpreter::AllocateContext(Thread* thread,
                                  intptr_t num_context_variables,
                                  const KBCInstr* pc,
                                  ObjectPtr* FP,
                                  ObjectPtr* SP) {
  ContextPtr result;
  if (TryAllocate(thread, kContextCid,
                  Context::InstanceSize(num_context_variables),
                  reinterpret_cast<ObjectPtr*>(&result))) {
    result->untag()->num_variables_ = num_context_variables;
    ObjectPtr null_value = Object::null();
    result->untag()->set_parent(static_cast<ContextPtr>(null_value));
    for (intptr_t i = 0; i < num_context_variables; i++) {
      result->untag()->set_element(i, null_value, thread);
    }
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = Smi::New(num_context_variables);
    Exit(thread, FP, SP + 2, pc);
    NativeArguments args(thread, 1, SP + 1, SP);
    return InvokeRuntime(thread, this, DRT_AllocateContext, args);
  }
}

// Allocate a _Closure and put it into SP[0].
// Returns false on exception.
bool Interpreter::AllocateClosure(Thread* thread,
                                  const KBCInstr* pc,
                                  ObjectPtr* FP,
                                  ObjectPtr* SP) {
  const intptr_t instance_size = Closure::InstanceSize();
  ClosurePtr result;
  if (TryAllocate(thread, kClosureCid, instance_size,
                  reinterpret_cast<ObjectPtr*>(&result))) {
    uword start = UntaggedObject::ToAddr(result);
    Object::InitializeObject(start, kClosureCid, instance_size,
                             Closure::ContainsCompressedPointers(),
                             Object::from_offset<Closure>(),
                             Object::to_offset<Closure>());
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate_group()->object_store()->closure_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    return InvokeRuntime(thread, this, DRT_AllocateObject, args);
  }
}

void Interpreter::SetupEntryFrame(Thread* thread) {
  // Setup entry frame:
  //
  //                        ^
  //                        |  previous Dart frames
  //                        |
  //       | ........... | -+
  // fp_ > | exit fp_    |     saved top_exit_frame_info
  //       | argdesc_    |     saved argdesc_ (for reentering interpreter)
  //       | pp_         |     saved pp_ (for reentering interpreter)
  //       | arg 0       | -+
  //       | arg 1       |  |
  //         ...            |
  //                         > incoming arguments
  //                        |
  //       | arg argc-1  | -+
  //       | function    | -+
  //       | code        |  |
  //       | caller PC   | ---> special fake PC marking an entry frame
  //  SP > | fp_         |  |
  //  FP > | ........... |   > normal Dart frame (see stack_frame_kbc.h)
  //                        |
  //                        v
  //

  // Save outer top_exit_frame_info, current argdesc, and current pp.
  fp_[kKBCExitLinkSlotFromEntryFp] =
      static_cast<ObjectPtr>(thread->top_exit_frame_info());
  thread->set_top_exit_frame_info(0);
  fp_[kKBCSavedArgDescSlotFromEntryFp] = static_cast<ObjectPtr>(argdesc_);
  fp_[kKBCSavedPpSlotFromEntryFp] = static_cast<ObjectPtr>(pp_);
}

ObjectPtr Interpreter::Call(FunctionPtr function,
                            ArrayPtr argdesc,
                            intptr_t argc,
                            ObjectPtr const* argv,
                            ArrayPtr args_array,
                            Thread* thread) {
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("Entering interpreter 0x%" Px " at fp_ 0x%" Px " exit 0x%" Px
              " %s\n",
              reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
              thread->top_exit_frame_info(),
              Function::Handle(function).ToFullyQualifiedCString());
  }
#endif

  SetupEntryFrame(thread);

  // A negative argc indicates reverse memory order of arguments.
  const intptr_t arg_count = argc < 0 ? -argc : argc;
  ObjectPtr* FP =
      fp_ + kKBCEntrySavedSlots + arg_count + kKBCDartFrameFixedSize;

  // Copy arguments and setup the Dart frame.
  if (argv != nullptr) {
    for (intptr_t i = 0; i < arg_count; ++i) {
      fp_[kKBCEntrySavedSlots + i] = argv[argc < 0 ? -i : i];
    }
  } else {
    ASSERT(arg_count == Smi::Value(args_array->untag()->length()));
    for (intptr_t i = 0; i < arg_count; ++i) {
      fp_[kKBCEntrySavedSlots + i] = args_array->untag()->element(i);
    }
  }

  BytecodePtr bytecode = Function::GetBytecode(function);
  FP[kKBCFunctionSlotFromFp] = function;
  FP[kKBCPcMarkerSlotFromFp] = bytecode;
  FP[kKBCSavedCallerPcSlotFromFp] = static_cast<ObjectPtr>(kEntryFramePcMarker);
  FP[kKBCSavedCallerFpSlotFromFp] =
      static_cast<ObjectPtr>(reinterpret_cast<uword>(fp_));

  // Load argument descriptor.
  argdesc_ = argdesc;

  // Ready to start executing bytecode. Load entry point and corresponding
  // object pool.
  pc_ = reinterpret_cast<const KBCInstr*>(bytecode->untag()->instructions_);
  pp_ = bytecode->untag()->object_pool();
  fp_ = FP;

  return Run(thread, FP - 1, /*rethrow_exception=*/false);
}

ObjectPtr Interpreter::Resume(Thread* thread,
                              uword resumed_frame_fp,
                              uword resumed_frame_sp,
                              ObjectPtr value,
                              ObjectPtr exception,
                              ObjectPtr stack_trace) {
  const intptr_t suspend_state_index_from_fp =
      runtime_frame_layout.FrameSlotForVariableIndex(
          SuspendState::kSuspendStateVarIndex);
  ASSERT(suspend_state_index_from_fp < 0);

  // Resumed native frame wraps interpreter state.
  ASSERT(resumed_frame_fp > resumed_frame_sp);
  ASSERT(resumed_frame_fp - resumed_frame_sp >=
         static_cast<uword>(-suspend_state_index_from_fp +
                            kKBCSuspendedFrameFixedSlots) *
             kWordSize);
  ObjectPtr* resumed_native_frame =
      reinterpret_cast<ObjectPtr*>(resumed_frame_sp);
  intptr_t interp_frame_size =
      resumed_frame_fp - resumed_frame_sp -
      (-suspend_state_index_from_fp + kKBCSuspendedFrameFixedSlots) * kWordSize;

  FunctionPtr function =
      Function::RawCast(resumed_native_frame[kKBCFunctionSlotInSuspendedFrame]);
  const intptr_t pc_offset = Smi::Value(
      Smi::RawCast(resumed_native_frame[kKBCPcOffsetSlotInSuspendedFrame]));

#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("Resuming interpreter 0x%" Px " at fp_ 0x%" Px " exit 0x%" Px
              " %s\n",
              reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
              thread->top_exit_frame_info(),
              Function::Handle(function).ToFullyQualifiedCString());
  }
#endif

  SetupEntryFrame(thread);

  ObjectPtr* FP = fp_ + kKBCEntrySavedSlots + kKBCDartFrameFixedSize;

  BytecodePtr bytecode = Function::GetBytecode(function);
  FP[kKBCFunctionSlotFromFp] = function;
  FP[kKBCPcMarkerSlotFromFp] = bytecode;
  FP[kKBCSavedCallerPcSlotFromFp] = static_cast<ObjectPtr>(kEntryFramePcMarker);
  FP[kKBCSavedCallerFpSlotFromFp] =
      static_cast<ObjectPtr>(reinterpret_cast<uword>(fp_));

  memmove(FP, &resumed_native_frame[kKBCSuspendedFrameFixedSlots],
          interp_frame_size);

  FP[kKBCSuspendStateSlotFromFp] = *reinterpret_cast<ObjectPtr*>(
      resumed_frame_fp + suspend_state_index_from_fp * kWordSize);

  ObjectPtr* SP = FP + (interp_frame_size >> kWordSizeLog2);

  const bool rethrow_exception = (exception != Object::null());
  if (rethrow_exception) {
    SP[0] = exception;
    *++SP = stack_trace;
  } else {
    SP[0] = value;
  }

  argdesc_ = Array::null();
  pc_ = reinterpret_cast<const KBCInstr*>(bytecode->untag()->instructions_ +
                                          pc_offset);
  pp_ = bytecode->untag()->object_pool();
  fp_ = FP;

#if !defined(PRODUCT)
  if (auto* const isolate = thread->isolate()) {
    if (isolate->has_resumption_breakpoints()) {
      Exit(thread, FP, SP + 1, pc_);
      InvokeRuntime(thread, this, DRT_ResumptionBreakpointHandler,
                    NativeArguments(thread, 0, nullptr, nullptr));
    }
  }
#endif

  return Run(thread, SP, rethrow_exception);
}

BytecodePtr Interpreter::GetSuspendedLocation(const SuspendState& suspend_state,
                                              uword* pc_offset) {
  ASSERT(suspend_state.pc() == StubCode::ResumeInterpreter().EntryPoint());
  ASSERT(suspend_state.frame_size() > kKBCSuspendedFrameFixedSlots);
  ObjectPtr* sp = reinterpret_cast<ObjectPtr*>(suspend_state.payload());
  *pc_offset = static_cast<uword>(
      Smi::Value(Smi::RawCast(sp[kKBCPcOffsetSlotInSuspendedFrame])));
  FunctionPtr function =
      Function::RawCast(sp[kKBCFunctionSlotInSuspendedFrame]);
  return Function::GetBytecode(function);
}

ObjectPtr Interpreter::Run(Thread* thread,
                           ObjectPtr* sp,
                           bool rethrow_exception) {
  // Interpreter state (see constants_kbc.h for high-level overview).
  const KBCInstr* pc =
      pc_;              // Program Counter: points to the next op to execute.
  ObjectPtr* FP = fp_;  // Frame Pointer.
  ObjectPtr* SP = sp;   // Stack Pointer.

  uint32_t op;  // Currently executing op.

#if !defined(PRODUCT)
  uint32_t single_stepping_offset = CALCULATE_SINGLE_STEPPING_OFFSET;
#endif

  // Save current VM tag and mark thread as executing Dart code. For the
  // profiler, do this *after* setting up the entry frame (compare the machine
  // code entry stubs).
  const uword vm_tag = thread->vm_tag();
  thread->set_vm_tag(VMTag::kDartInterpretedTagId);

  // Save current top stack resource and reset the list.
  StackResource* top_resource = thread->top_resource();
  thread->set_top_resource(nullptr);

  // Cache some frequently used values in the frame.
  BoolPtr true_value = Bool::True().ptr();
  BoolPtr false_value = Bool::False().ptr();
  ObjectPtr null_value = Object::null();

  if (rethrow_exception) {
    goto RethrowException;
  }

#if defined(DART_HAS_COMPUTED_GOTO)
  static const void* dispatch[] = {
#define TARGET(name, fmt, kind, fmta, fmtb, fmtc) &&bc##name,
      KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
#if !defined(PRODUCT)
#define TARGET(name, fmt, kind, fmta, fmtb, fmtc) &&bc##name##_SingleStep,
          KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
#endif  // !defined(PRODUCT)
  };
  DISPATCH();  // Enter the dispatch loop.
#else
  DISPATCH();  // Enter the dispatch loop.
SwitchDispatch:
  switch (ADJUST_FOR_SINGLE_STEPPING(op & 0xFF)) {
#define TARGET(name, fmt, kind, fmta, fmtb, fmtc)                              \
  case KernelBytecode::k##name:                                                \
    goto bc##name;
    KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
#if !defined(PRODUCT)
#define TARGET(name, fmt, kind, fmta, fmtb, fmtc)                              \
  case KernelBytecode::k##name + KernelBytecode::kNumOpcodes:                  \
    goto bc##name##_SingleStep;
    KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
#endif  // !defined(PRODUCT)
    default:
      FATAL1("Undefined opcode: %d\n", op);
  }
#if !defined(PRODUCT)
SwitchDispatchNoSingleStep:
  switch (op & 0xFF) {
#define TARGET(name, fmt, kind, fmta, fmtb, fmtc)                              \
  case KernelBytecode::k##name:                                                \
    goto bc##name;
    KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
    default:
      FATAL1("Undefined opcode: %d\n", op);
  }
#endif  // !defined(PRODUCT)
#endif  // defined(DART_HAS_COMPUTED_GOTO)

  // KernelBytecode handlers (see constants_kbc.h for bytecode descriptions).
  {
    BYTECODE(Entry, D);
    const intptr_t num_locals = rD;

    // Initialize locals with null & set SP.
    for (intptr_t i = 0; i < num_locals; i++) {
      FP[i] = null_value;
    }
    SP = FP + num_locals - 1;

    InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
    DISPATCH();
  }

  {
    BYTECODE(EntryOptional, A_B_C);
    SP = FP - 1;
    if (CopyParameters(thread, &pc, &FP, &SP, rA, rB, rC, 0)) {
      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      DISPATCH();
    } else {
      SP[1] = FrameFunction(FP);
      goto NoSuchMethodFromPrologue;
    }
  }

  {
    BYTECODE(EntrySuspendable, A_B_C);
    FP[kKBCSuspendStateSlotFromFp] = null_value;
    SP = FP + kKBCSuspendStateSlotFromFp;
    if (CopyParameters(thread, &pc, &FP, &SP, rA, rB, rC, 1)) {
      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      DISPATCH();
    } else {
      SP[1] = FrameFunction(FP);
      goto NoSuchMethodFromPrologue;
    }
  }

  {
    BYTECODE(Frame, D);
    // Initialize locals with null and increment SP.
    const intptr_t num_locals = rD;
    for (intptr_t i = 1; i <= num_locals; i++) {
      SP[i] = null_value;
    }
    SP += num_locals;

    DISPATCH();
  }

  {
    BYTECODE(SetFrame, A);
    SP = FP + rA - 1;
    DISPATCH();
  }

  {
    BYTECODE(CheckStack, A);
    {
      // Check the interpreter's own stack limit for actual interpreter's stack
      // overflows, and also the thread's stack limit for scheduled interrupts.
      if (reinterpret_cast<uword>(SP) >= overflow_stack_limit() ||
          thread->HasScheduledInterrupts() ||
          !thread->os_thread()->HasStackHeadroom()) {
        Exit(thread, FP, SP + 1, pc);
        INVOKE_RUNTIME(DRT_InterruptOrStackOverflow,
                       NativeArguments(thread, 0, nullptr, nullptr));
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(DebugCheck, 0);
    DISPATCH();
  }

  {
    BYTECODE(CheckFunctionTypeArgs, A_E);
    const intptr_t declared_type_args_len = rA;
    const intptr_t first_stack_local_index = rE;

    // Decode arguments descriptor's type args len.
    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    if ((type_args_len != declared_type_args_len) && (type_args_len != 0)) {
      SP[1] = FrameFunction(FP);
      goto NoSuchMethodFromPrologue;
    }
    if (type_args_len > 0) {
      // Decode arguments descriptor's argument count (excluding type args).
      const intptr_t arg_count = InterpreterHelpers::ArgDescArgCount(argdesc_);
      // Copy passed-in type args to first local slot.
      FP[first_stack_local_index] = *FrameArguments(FP, arg_count + 1);
    } else if (declared_type_args_len > 0) {
      FP[first_stack_local_index] = Object::null();
    }
    DISPATCH();
  }

  {
    BYTECODE(InstantiateType, D);
    // Stack: instantiator type args, function type args
    ObjectPtr type = LOAD_CONSTANT(rD);
    SP[1] = type;
    SP[2] = SP[-1];
    SP[3] = SP[0];
    Exit(thread, FP, SP + 4, pc);
    {
      INVOKE_RUNTIME(DRT_InstantiateType,
                     NativeArguments(thread, 3, SP + 1, SP - 1));
    }
    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(InstantiateTypeArgumentsTOS, A_E);
    // Stack: instantiator type args, function type args
    TypeArgumentsPtr type_arguments =
        static_cast<TypeArgumentsPtr>(LOAD_CONSTANT(rE));

    ObjectPtr instantiator_type_args = SP[-1];
    ObjectPtr function_type_args = SP[0];
    // If both instantiators are null and if the type argument vector
    // instantiated from null becomes a vector of dynamic, then use null as
    // the type arguments.
    if ((rA == 0) || (null_value != instantiator_type_args) ||
        (null_value != function_type_args)) {
      SP[1] = type_arguments;
      SP[2] = instantiator_type_args;
      SP[3] = function_type_args;

      Exit(thread, FP, SP + 4, pc);
      INVOKE_RUNTIME(DRT_InstantiateTypeArguments,
                     NativeArguments(thread, 3, SP + 1, SP - 1));
    }

    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(Throw, A);
    {
      if (rA == 0) {  // Throw
        SP[1] = 0;    // Space for result.
        Exit(thread, FP, SP + 2, pc);
        INVOKE_RUNTIME(DRT_Throw, NativeArguments(thread, 1, SP, SP + 1));
      } else {  // ReThrow
      RethrowException:
        SP[1] = 0;  // Do not bypass debugger.
        SP[2] = 0;  // Space for result.
        Exit(thread, FP, SP + 3, pc);
        INVOKE_RUNTIME(DRT_ReThrow, NativeArguments(thread, 3, SP - 1, SP + 2));
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(Drop1, 0);
    SP--;
    DISPATCH();
  }

  {
    BYTECODE(LoadConstant, A_E);
    FP[rA] = LOAD_CONSTANT(rE);
    DISPATCH();
  }

  {
    BYTECODE(PushConstant, D);
    *++SP = LOAD_CONSTANT(rD);
    DISPATCH();
  }

  {
    BYTECODE(PushNull, 0);
    *++SP = null_value;
    DISPATCH();
  }

  {
    BYTECODE(PushTrue, 0);
    *++SP = true_value;
    DISPATCH();
  }

  {
    BYTECODE(PushFalse, 0);
    *++SP = false_value;
    DISPATCH();
  }

  {
    BYTECODE(PushInt, X);
    *++SP = Smi::New(rX);
    DISPATCH();
  }

  {
    BYTECODE(Push, X);
    *++SP = FP[rX];
    DISPATCH();
  }

  {
    BYTECODE(StoreLocal, X);
    FP[rX] = *SP;
    DISPATCH();
  }

  {
    BYTECODE(PopLocal, X);
    FP[rX] = *SP--;
    DISPATCH();
  }

  {
    BYTECODE(MoveSpecial, A_Y);
    ASSERT(rA < KernelBytecode::kSpecialIndexCount);
    FP[rY] = special_[rA];
    DISPATCH();
  }

  {
    BYTECODE(BooleanNegateTOS, 0);
    SP[0] = (SP[0] == true_value) ? false_value : true_value;
    DISPATCH();
  }

  {
    BYTECODE(DirectCall, D_F);

    // Invoke target function.
    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      ObjectPtr target = LOAD_CONSTANT(kidx);
      *++SP = target;
#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT)
      if (target->IsArray()) {
        // Hot reload failed to find a suitable target for this call.
        goto ThrowNoSuchMethodError;
      }
#endif
      ASSERT(target->IsFunction());
      ObjectPtr* call_base = SP - argc;
      ObjectPtr* call_top = SP;
      argdesc_ = static_cast<ArrayPtr>(LOAD_CONSTANT(kidx + 1));
      if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }

  {
    BYTECODE(UncheckedDirectCall, D_F);

    // Invoke target function.
    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      ObjectPtr target = LOAD_CONSTANT(kidx);
      *++SP = target;
#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT)
      if (target->IsArray()) {
        // Hot reload failed to find a suitable target for this call.
        goto ThrowNoSuchMethodError;
      }
#endif
      ASSERT(target->IsFunction());
      ObjectPtr* call_base = SP - argc;
      ObjectPtr* call_top = SP;
      argdesc_ = static_cast<ArrayPtr>(LOAD_CONSTANT(kidx + 1));
      if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }

  {
    BYTECODE(InterfaceCall, D_F);

    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      ObjectPtr* call_base = SP - argc + 1;
      ObjectPtr* call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      StringPtr target_name =
          static_cast<FunctionPtr>(LOAD_CONSTANT(kidx))->untag()->name();
      argdesc_ = static_cast<ArrayPtr>(LOAD_CONSTANT(kidx + 1));
      if (!InstanceCall(thread, target_name, call_base, call_top, &pc, &FP,
                        &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }
  {
    BYTECODE(InstantiatedInterfaceCall, D_F);

    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      ObjectPtr* call_base = SP - argc + 1;
      ObjectPtr* call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      StringPtr target_name =
          static_cast<FunctionPtr>(LOAD_CONSTANT(kidx))->untag()->name();
      argdesc_ = static_cast<ArrayPtr>(LOAD_CONSTANT(kidx + 1));
      if (!InstanceCall(thread, target_name, call_base, call_top, &pc, &FP,
                        &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }

  {
    BYTECODE(UncheckedClosureCall, D_F);

    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      ClosurePtr receiver = Closure::RawCast(*SP--);
      ObjectPtr* call_base = SP - argc + 1;
      ObjectPtr* call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      if (receiver == null_value) [[unlikely]] {
        SP[0] = Symbols::call().ptr();
        goto ThrowNullError;
      }
      argdesc_ = static_cast<ArrayPtr>(LOAD_CONSTANT(kidx));
      call_top[0] = receiver->untag()->function();

      if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }

  {
    BYTECODE(UncheckedInterfaceCall, D_F);

    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      ObjectPtr* call_base = SP - argc + 1;
      ObjectPtr* call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      StringPtr target_name =
          static_cast<FunctionPtr>(LOAD_CONSTANT(kidx))->untag()->name();
      argdesc_ = static_cast<ArrayPtr>(LOAD_CONSTANT(kidx + 1));
      if (!InstanceCall(thread, target_name, call_base, call_top, &pc, &FP,
                        &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }

  {
    BYTECODE(DynamicCall, D_F);

    {
      const uint32_t argc = rF;
      const uint32_t kidx = rD;

      ObjectPtr* call_base = SP - argc + 1;
      ObjectPtr* call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      StringPtr target_name = String::RawCast(LOAD_CONSTANT(kidx));
      argdesc_ = Array::RawCast(LOAD_CONSTANT(kidx + 1));
      if (!InstanceCall(thread, target_name, call_base, call_top, &pc, &FP,
                        &SP)) {
        HANDLE_EXCEPTION;
      }
      CHECK_SINGLE_STEPPING;
    }

    DISPATCH();
  }

  {
    BYTECODE(ExternalCall, D);

    {
      FunctionPtr function = FrameFunction(FP);
      NativeFunctionWrapper trampoline =
          reinterpret_cast<NativeFunctionWrapper>(LOAD_CONSTANT_RAW(rD));
      NativeFunction native_function =
          reinterpret_cast<NativeFunction>(LOAD_CONSTANT_RAW(rD + 1));

      if (trampoline == nullptr || native_function == nullptr) [[unlikely]] {
        SP[1] = 0;  // Unused space for result.
        SP[2] = function;
        SP[3] = Smi::New(rD);
        Exit(thread, FP, SP + 4, pc);
        INVOKE_RUNTIME(DRT_ResolveExternalCall,
                       NativeArguments(thread, 2, SP + 2, SP + 1));

        // Reload after call is resolved.
        function = FrameFunction(FP);
        trampoline =
            reinterpret_cast<NativeFunctionWrapper>(LOAD_CONSTANT_RAW(rD));
        native_function =
            reinterpret_cast<NativeFunction>(LOAD_CONSTANT_RAW(rD + 1));
        ASSERT(trampoline != nullptr);
        ASSERT(native_function != nullptr);
      }

      *++SP = null_value;  // Result slot.

      const intptr_t num_arguments = FunctionType::NumParametersOf(
          FunctionType::RawCast(function->untag()->signature()));
      ObjectPtr* incoming_args = SP - num_arguments;
      ObjectPtr* return_slot = SP;
      Exit(thread, FP, SP + 1, pc);
      NativeArguments native_args(thread, num_arguments, incoming_args,
                                  return_slot);
      if (!InvokeNative(thread, this, trampoline, native_function,
                        &native_args)) {
        HANDLE_EXCEPTION;
      } else {
        HANDLE_RETURN;
      }

      *(SP - num_arguments) = *return_slot;
      SP -= num_arguments;
    }

    DISPATCH();
  }

  {
    BYTECODE(FfiCall, D);

    {
      FunctionPtr function = FrameFunction(FP);

      SP[1] = 0;  // Unused space for result.
      SP[2] = function;
      SP[3] = Smi::New(rD);
      Exit(thread, FP, SP + 4, pc);
      INVOKE_RUNTIME(DRT_FfiCall, NativeArguments(thread, 2, SP + 2, SP + 1));
      ++SP;
    }

    DISPATCH();
  }

  {
    BYTECODE(ReturnTOS, 0);

    ObjectPtr result;  // result to return to the caller.
    result = *SP;
    // Restore caller PC.
    pc = SavedCallerPC(FP);

    // Check if it is a fake PC marking the entry frame.
    if (IsEntryFrameMarker(pc)) {
      // Pop entry frame.
      ObjectPtr* entry_fp = SavedCallerFP(FP);
      // Restore exit frame info saved in entry frame.
      pp_ = static_cast<ObjectPoolPtr>(entry_fp[kKBCSavedPpSlotFromEntryFp]);
      argdesc_ =
          static_cast<ArrayPtr>(entry_fp[kKBCSavedArgDescSlotFromEntryFp]);
      uword exit_fp = static_cast<uword>(entry_fp[kKBCExitLinkSlotFromEntryFp]);
      thread->set_top_exit_frame_info(exit_fp);
      thread->set_top_resource(top_resource);
      thread->set_vm_tag(vm_tag);
      fp_ = entry_fp;
      NOT_IN_PRODUCT(pc_ = pc);  // For the profiler.
#if defined(DEBUG)
      if (IsTracingExecution()) {
        THR_Print("%" Pu64 " ", icount_);
        THR_Print("Returning from interpreter 0x%" Px " at fp_ 0x%" Px
                  " exit 0x%" Px "\n",
                  reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
                  exit_fp);
      }
      ASSERT(HasFrame(reinterpret_cast<uword>(fp_)));
      // Exception propagation should have been done.
      ASSERT(result->GetClassId() != kUnhandledExceptionCid);
#endif
      return result;
    }

    // Look at the caller to determine how many arguments to pop.
    const uint8_t argc = KernelBytecode::DecodeArgc(pc);

    // Restore SP, FP and PP. Push result and dispatch.
    SP = FrameArguments(FP, argc);
    FP = SavedCallerFP(FP);
    NOT_IN_PRODUCT(fp_ = FP);  // For the profiler.
    NOT_IN_PRODUCT(pc_ = pc);  // For the profiler.
    pp_ = InterpreterHelpers::FrameBytecode(FP)->untag()->object_pool();
    *SP = result;
#if defined(DEBUG)
    if (IsTracingExecution()) {
      THR_Print("%" Pu64 " ", icount_);
      THR_Print("Returning to %s (argc %d)\n",
                Function::Handle(FrameFunction(FP)).ToFullyQualifiedCString(),
                static_cast<int>(argc));
    }
#endif
    DISPATCH();
  }

  {
    BYTECODE(InitLateField, D);
    FieldPtr field = Field::RawCast(LOAD_CONSTANT(rD + 1));
    InstancePtr instance = Instance::RawCast(SP[0]);
    intptr_t offset_in_words =
        Smi::Value(field->untag()->host_offset_or_field_id());

    InterpreterHelpers::SetField(instance, offset_in_words,
                                 Object::sentinel().ptr(), thread);

    SP -= 1;  // Drop instance.
    DISPATCH();
  }

  {
    BYTECODE(PushUninitializedSentinel, 0);
    *++SP = Object::sentinel().ptr();
    DISPATCH();
  }

  {
    BYTECODE(JumpIfInitialized, T);
    SP -= 1;
    if (SP[1] != Object::sentinel().ptr()) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(StoreStaticTOS, D);
    FieldPtr field = Field::RawCast(LOAD_CONSTANT(rD));
    InstancePtr value = Instance::RawCast(*SP--);
    intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
    if (thread->isolate() == nullptr) [[unlikely]] {
      SP[0] = field;
      goto ThrowStaticFieldAccessedWithoutIsolateError;
    }
    thread->field_table_values()[field_id] = value;
    DISPATCH();
  }

  {
    BYTECODE(LoadStatic, D);
    FieldPtr field = Field::RawCast(LOAD_CONSTANT(rD));
    intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
    if (thread->isolate() == nullptr) [[unlikely]] {
      SP[0] = field;
      goto ThrowStaticFieldAccessedWithoutIsolateError;
    }
    ObjectPtr value = thread->field_table_values()[field_id];
    ASSERT(value != Object::sentinel().ptr());
    *++SP = value;
    DISPATCH();
  }

  {
    BYTECODE(StoreFieldTOS, D);
    FieldPtr field = Field::RawCast(LOAD_CONSTANT(rD + 1));
    InstancePtr instance = Instance::RawCast(SP[-1]);
    ObjectPtr value = static_cast<ObjectPtr>(SP[0]);
    intptr_t offset_in_words =
        Smi::Value(field->untag()->host_offset_or_field_id());

    if (InterpreterHelpers::FieldNeedsGuardUpdate(thread, field, value)) {
      SP[1] = 0;  // Unused result of runtime call.
      SP[2] = field;
      SP[3] = value;
      Exit(thread, FP, SP + 4, pc);
      if (!InvokeRuntime(thread, this, DRT_UpdateFieldCid,
                         NativeArguments(thread, 2, /* argv */ SP + 2,
                                         /* retval */ SP + 1))) {
        HANDLE_EXCEPTION;
      }

      // Reload objects after the call which may trigger GC.
      field = Field::RawCast(LOAD_CONSTANT(rD + 1));
      instance = Instance::RawCast(SP[-1]);
      value = SP[0];
    }

    const bool is_unboxed =
        Field::UnboxedBit::decode(field->untag()->kind_bits_);
    if (is_unboxed) {
      const classid_t guarded_cid = field->untag()->guarded_cid_;
      switch (guarded_cid) {
        case kDoubleCid: {
          double raw_value = Double::RawCast(value)->untag()->value_;
          *reinterpret_cast<double_t*>(
              reinterpret_cast<CompressedObjectPtr*>(instance->untag()) +
              offset_in_words) = raw_value;
          break;
        }
        case kFloat32x4Cid: {
          simd128_value_t raw_value;
          raw_value.readFrom(Float32x4::RawCast(value)->untag()->value_);
          *reinterpret_cast<simd128_value_t*>(
              reinterpret_cast<CompressedObjectPtr*>(instance->untag()) +
              offset_in_words) = raw_value;
          break;
        }
        case kFloat64x2Cid: {
          simd128_value_t raw_value;
          raw_value.readFrom(Float64x2::RawCast(value)->untag()->value_);
          *reinterpret_cast<simd128_value_t*>(
              reinterpret_cast<CompressedObjectPtr*>(instance->untag()) +
              offset_in_words) = raw_value;
          break;
        }
        default: {
          int64_t raw_value = Integer::Value(Integer::RawCast(value));
          *reinterpret_cast<int64_t*>(
              reinterpret_cast<CompressedObjectPtr*>(instance->untag()) +
              offset_in_words) = raw_value;
          break;
        }
      }
    } else {
      InterpreterHelpers::SetField(instance, offset_in_words, value, thread);
    }

    SP -= 2;  // Drop instance and value.
    DISPATCH();
  }

  {
    BYTECODE(StoreContextParent, 0);
    ContextPtr instance = static_cast<ContextPtr>(SP[-1]);
    ContextPtr value = static_cast<ContextPtr>(SP[0]);
    SP -= 2;  // Drop instance and value.
    instance->untag()->set_parent(value);
    DISPATCH();
  }

  {
    BYTECODE(StoreContextVar, A_E);
    const intptr_t index = rE;
    ContextPtr instance = static_cast<ContextPtr>(SP[-1]);
    ObjectPtr value = static_cast<ContextPtr>(SP[0]);
    SP -= 2;  // Drop instance and value.
    ASSERT(index < instance->untag()->num_variables_);
    instance->untag()->set_element(index, value, thread);
    DISPATCH();
  }

  {
    BYTECODE(LoadFieldTOS, D);
#if defined(DEBUG)
    // Currently only used to load closure fields, which are not unboxed.
    // If used for general field, boxing of the unboxed fields must be added.
    FieldPtr field = Field::RawCast(LOAD_CONSTANT(rD + 1));
    ASSERT(!Field::UnboxedBit::decode(field->untag()->kind_bits_));
#endif
    const uword offset_in_words =
        static_cast<uword>(Smi::Value(Smi::RawCast(LOAD_CONSTANT(rD))));
    InstancePtr instance = Instance::RawCast(SP[0]);
    SP[0] = GET_FIELD(instance, offset_in_words);
    DISPATCH();
  }

  {
    BYTECODE(LoadTypeArgumentsField, D);
    const uword offset_in_words =
        static_cast<uword>(Smi::Value(Smi::RawCast(LOAD_CONSTANT(rD))));
    InstancePtr instance = Instance::RawCast(SP[0]);
    SP[0] = GET_FIELD(instance, offset_in_words);
    DISPATCH();
  }

  {
    BYTECODE(LoadContextParent, 0);
    ContextPtr instance = static_cast<ContextPtr>(SP[0]);
    SP[0] = instance->untag()->parent();
    DISPATCH();
  }

  {
    BYTECODE(LoadContextVar, A_E);
    const intptr_t index = rE;
    ContextPtr instance = Context::RawCast(SP[0]);
    ASSERT(index < instance->untag()->num_variables_);
    SP[0] = instance->untag()->element(index);
    DISPATCH();
  }

  {
    BYTECODE(LoadRecordField, D);
    const intptr_t field_index = rD;
    RecordPtr record = Record::RawCast(SP[0]);
    SP[0] = record->untag()->field(field_index);
    DISPATCH();
  }

  {
    BYTECODE(AllocateContext, A_E);
    ++SP;
    const uint32_t num_context_variables = rE;
    if (!AllocateContext(thread, num_context_variables, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    DISPATCH();
  }

  {
    BYTECODE(CloneContext, A_E);
    {
      SP[1] = SP[0];  // Context to clone.
      Exit(thread, FP, SP + 2, pc);
      INVOKE_RUNTIME(DRT_CloneContext, NativeArguments(thread, 1, SP + 1, SP));
    }
    DISPATCH();
  }

  {
    BYTECODE(Allocate, D);
    ClassPtr cls = Class::RawCast(LOAD_CONSTANT(rD));
    if (InterpreterHelpers::IsAllocateFinalized(cls)) [[likely]] {
      const intptr_t class_id = cls->untag()->id_;
      ASSERT(Class::is_valid_id(class_id));
      const intptr_t instance_size =
          cls->untag()->host_instance_size_in_words_ * kCompressedWordSize;
      ObjectPtr result;
      if (TryAllocate(thread, class_id, instance_size, &result)) {
        uword start = UntaggedObject::ToAddr(result);
        const uword ptr_field_end_offset =
            instance_size - (Instance::ContainsCompressedPointers()
                                 ? kCompressedWordSize
                                 : kWordSize);
        Object::InitializeObject(start, class_id, instance_size,
                                 Instance::ContainsCompressedPointers(),
                                 Object::from_offset<Instance>(),
                                 ptr_field_end_offset);
        /*
        for (intptr_t offset = sizeof(UntaggedInstance); offset < instance_size;
             offset += kCompressedWordSize) {
          *reinterpret_cast<ObjectPtr*>(start + offset) = null_value;
        }
*/
        ASSERT(class_id ==
               UntaggedObject::ClassIdTag::decode(result->untag()->tags_));
        ASSERT(IsolateGroup::Current()->class_table()->At(
                   result->GetClassId()) == cls);
        *++SP = result;
        DISPATCH();
      }
    }

    SP[1] = 0;           // Space for the result.
    SP[2] = cls;         // Class object.
    SP[3] = null_value;  // Type arguments.
    Exit(thread, FP, SP + 4, pc);
    INVOKE_RUNTIME(DRT_AllocateObject,
                   NativeArguments(thread, 2, SP + 2, SP + 1));
    SP++;  // Result is in SP[1].
    DISPATCH();
  }

  {
    BYTECODE(AllocateT, 0);
    ClassPtr cls = Class::RawCast(SP[0]);
    TypeArgumentsPtr type_args = TypeArguments::RawCast(SP[-1]);
    if (InterpreterHelpers::IsAllocateFinalized(cls)) [[likely]] {
      const intptr_t class_id = cls->untag()->id_;
      const intptr_t instance_size =
          cls->untag()->host_instance_size_in_words_ * kCompressedWordSize;
      ObjectPtr result;
      if (TryAllocate(thread, class_id, instance_size, &result)) {
        uword start = UntaggedObject::ToAddr(result);
        const uword ptr_field_end_offset =
            instance_size - (Instance::ContainsCompressedPointers()
                                 ? kCompressedWordSize
                                 : kWordSize);
        Object::InitializeObject(start, class_id, instance_size,
                                 Instance::ContainsCompressedPointers(),
                                 Object::from_offset<Instance>(),
                                 ptr_field_end_offset);
        /*
        for (intptr_t offset = sizeof(UntaggedInstance); offset < instance_size;
             offset += kWordSize) {
          *reinterpret_cast<ObjectPtr*>(start + offset) = null_value;
        }
*/
        const intptr_t type_args_offset =
            cls->untag()->host_type_arguments_field_offset_in_words_;
        InterpreterHelpers::SetField(result, type_args_offset, type_args,
                                     thread);
        *--SP = result;
        DISPATCH();
      }
    }

    SP[1] = cls;
    SP[2] = type_args;
    Exit(thread, FP, SP + 3, pc);
    INVOKE_RUNTIME(DRT_AllocateObject,
                   NativeArguments(thread, 2, SP + 1, SP - 1));
    SP -= 1;  // Result is in SP - 1.
    DISPATCH();
  }

  {
    BYTECODE(CreateArrayTOS, 0);
    TypeArgumentsPtr type_args = TypeArguments::RawCast(SP[-1]);
    ObjectPtr length = SP[0];
    SP--;
    if (!AllocateArray(thread, type_args, length, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    DISPATCH();
  }

  {
    BYTECODE(AllocateRecord, D);
    RecordTypePtr type = RecordType::RawCast(LOAD_CONSTANT(rD));
    RecordShape shape(Smi::RawCast(type->untag()->shape()));
    ++SP;
    if (!AllocateRecord(thread, shape, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    RecordPtr record = Record::RawCast(SP[0]);
    const intptr_t num_fields = shape.num_fields();
    for (intptr_t i = 0; i < num_fields; ++i) {
      record->untag()->set_field(i, SP[-num_fields + i], thread);
    }
    SP -= num_fields;
    SP[0] = record;
    DISPATCH();
  }

  {
    BYTECODE(AssertAssignable, A_E);
    // Stack: instance, type, instantiator type args, function type args, name
    ObjectPtr* args = SP - 4;
    SubtypeTestCachePtr cache = SubtypeTestCache::RawCast(LOAD_CONSTANT(rE));

    if (!AssertAssignable(thread, pc, FP, SP, args, cache)) {
      HANDLE_EXCEPTION;
    }

    SP -= 4;  // Instance remains on stack.
    DISPATCH();
  }

  {
    BYTECODE(AssertSubtype, 0);
    ObjectPtr* args = SP - 4;

    // TODO(kustermann): Implement fast case for common arguments.

    // The arguments on the stack look like:
    //     args[0]  instantiator type args
    //     args[1]  function type args
    //     args[2]  sub_type
    //     args[3]  super_type
    //     args[4]  name

    // This is unused, since the negative case throws an exception.
    SP++;
    ObjectPtr* result_slot = SP;

    Exit(thread, FP, SP + 1, pc);
    INVOKE_RUNTIME(DRT_SubtypeCheck,
                   NativeArguments(thread, 5, args, result_slot));

    // Drop result slot and all arguments.
    SP -= 6;

    DISPATCH();
  }

  {
    BYTECODE(Jump, T);
    LOAD_JUMP_TARGET();
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNoAsserts, T);
    if (!thread->isolate_group()->asserts()) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNotZeroTypeArgs, T);
    if (InterpreterHelpers::ArgDescTypeArgsLen(argdesc_) != 0) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfEqStrict, T);
    SP -= 2;
    if (SP[1] == SP[2]) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNeStrict, T);
    SP -= 2;
    if (SP[1] != SP[2]) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfTrue, T);
    SP -= 1;
    if (SP[1] == true_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfFalse, T);
    SP -= 1;
    if (SP[1] == false_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNull, T);
    SP -= 1;
    if (SP[1] == null_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNotNull, T);
    SP -= 1;
    if (SP[1] != null_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfUnchecked, T);
    // Interpreter is not tracking unchecked calls, so fall through to
    // parameter type checks.
    DISPATCH();
  }

  {
    BYTECODE(Suspend, T);
    const intptr_t suspend_state_index_from_fp =
        runtime_frame_layout.FrameSlotForVariableIndex(
            SuspendState::kSuspendStateVarIndex);
    ASSERT(suspend_state_index_from_fp < 0);
    // Saved interpreter frame is "wrapped" into a native frame in
    // the suspend state:
    //
    // (-suspend_state_index_from_fp) words:
    //         header to mimic native frame with the slot for suspend state
    // (SP + 1 - FP) words:
    //         locals and expression stack
    // kKBCSuspendedFrameFixedSlots words:
    //         suspended function and PC offset to resume.
    const intptr_t frame_size = ((-suspend_state_index_from_fp) +
                                 (SP + 1 - FP) + kKBCSuspendedFrameFixedSlots) *
                                kWordSize;

    SuspendStatePtr state;
    ObjectPtr old_state = FP[kKBCSuspendStateSlotFromFp];
    if (!old_state->IsSuspendState() ||
#if defined(DART_PRECOMPILED_RUNTIME)
        (SuspendState::RawCast(old_state)->untag()->frame_size_ != frame_size)
#else
        (SuspendState::RawCast(old_state)->untag()->frame_capacity_ <
         frame_size)
#endif
    ) {
      SP[1] = 0;  // Space for result.
      SP[2] = Smi::New(frame_size);
      SP[3] = old_state;
      Exit(thread, FP, SP + 4, pc);
      INVOKE_RUNTIME(
          DRT_AllocateSuspendState,
          NativeArguments(thread, 2, /* argv */ SP + 2, /* retval */ SP + 1));
      state = SuspendState::RawCast(SP[1]);
      ASSERT(state->untag()->frame_size_ == frame_size);
      FP[kKBCSuspendStateSlotFromFp] = state;
    } else {
      state = SuspendState::RawCast(old_state);
#if !defined(DART_PRECOMPILED_RUNTIME)
      state->untag()->frame_size_ = frame_size;
#endif
    }

    // Copy interpreter frame, locals and expression stack.
    uint8_t* payload = state->untag()->payload();
    ObjectPtr* suspended_frame = reinterpret_cast<ObjectPtr*>(payload);

    FunctionPtr function = FrameFunction(FP);
    const intptr_t pc_offset =
        (reinterpret_cast<uword>(rT) -
         Function::GetBytecode(function)->untag()->instructions_);
    suspended_frame[kKBCFunctionSlotInSuspendedFrame] = function;
    suspended_frame[kKBCPcOffsetSlotInSuspendedFrame] = Smi::New(pc_offset);

    memmove(&suspended_frame[kKBCSuspendedFrameFixedSlots], FP,
            (SP + 1 - FP) * kWordSize);

    // Fill suspend state slot.
    const uword native_fp = reinterpret_cast<uword>(payload + frame_size);
    *reinterpret_cast<ObjectPtr*>(native_fp + suspend_state_index_from_fp *
                                                  kWordSize) = state;
    // Clear the rest of the slots.
    for (intptr_t i = suspend_state_index_from_fp + 1; i < 0; ++i) {
      *reinterpret_cast<ObjectPtr*>(native_fp + i * kWordSize) = 0;
    }

#if !defined(DART_PRECOMPILED_RUNTIME)
    *(reinterpret_cast<ObjectPtr*>(
        native_fp + runtime_frame_layout.code_from_fp * kWordSize)) =
        StubCode::ResumeInterpreter().ptr();
#endif
    state->untag()->pc_ = StubCode::ResumeInterpreter().EntryPoint();

    // Write barrier.
    if (state->IsOldObject() || thread->is_marking()) {
      DLRT_EnsureRememberedAndMarkingDeferred(static_cast<uword>(state),
                                              thread);
    }

    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedTOS, 0);
    SP -= 3;
    ArrayPtr array = Array::RawCast(SP[1]);
    SmiPtr index = Smi::RawCast(SP[2]);
    ObjectPtr value = SP[3];
    ASSERT(InterpreterHelpers::CheckIndex(index, array->untag()->length()));
    array->untag()->set_element(Smi::Value(index), value, thread);
    DISPATCH();
  }

  {
    BYTECODE(EqualsNull, 0);

    SP[0] = (SP[0] == null_value) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(NullCheck, D);

    if (SP[0] == null_value) [[unlikely]] {
      // Load selector.
      SP[0] = LOAD_CONSTANT(rD);
      goto ThrowNullError;
    }
    SP -= 1;

    DISPATCH();
  }

  {
    BYTECODE(NegateInt, 0);

    UNBOX_INT64(value, SP[0], Symbols::UnaryMinus());
    int64_t result = Utils::SubWithWrapAround<int64_t>(0, value);
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(AddInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::Plus());
    UNBOX_INT64(b, SP[1], Symbols::Plus());
    int64_t result = Utils::AddWithWrapAround(a, b);
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(SubInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::Minus());
    UNBOX_INT64(b, SP[1], Symbols::Minus());
    int64_t result = Utils::SubWithWrapAround(a, b);
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(MulInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::Star());
    UNBOX_INT64(b, SP[1], Symbols::Star());
    int64_t result = Utils::MulWithWrapAround(a, b);
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(TruncDivInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::TruncDivOperator());
    UNBOX_INT64(b, SP[1], Symbols::TruncDivOperator());
    if (b == 0) [[unlikely]] {
      goto ThrowIntegerDivisionByZeroException;
    }
    int64_t result;
    if ((a == Mint::kMinValue) && (b == -1)) [[unlikely]] {
      result = Mint::kMinValue;
    } else {
      result = a / b;
    }
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(ModInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::Percent());
    UNBOX_INT64(b, SP[1], Symbols::Percent());
    if (b == 0) [[unlikely]] {
      goto ThrowIntegerDivisionByZeroException;
    }
    int64_t result;
    if ((a == Mint::kMinValue) && (b == -1)) [[unlikely]] {
      result = 0;
    } else {
      result = a % b;
      if (result < 0) {
        if (b < 0) {
          result -= b;
        } else {
          result += b;
        }
      }
    }
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(BitAndInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::Ampersand());
    UNBOX_INT64(b, SP[1], Symbols::Ampersand());
    int64_t result = a & b;
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(BitOrInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::BitOr());
    UNBOX_INT64(b, SP[1], Symbols::BitOr());
    int64_t result = a | b;
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(BitXorInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::Caret());
    UNBOX_INT64(b, SP[1], Symbols::Caret());
    int64_t result = a ^ b;
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(ShlInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::LeftShiftOperator());
    UNBOX_INT64(b, SP[1], Symbols::LeftShiftOperator());
    if (b < 0) {
      SP[0] = SP[1];
      goto ThrowArgumentError;
    }
    int64_t result = Utils::ShiftLeftWithTruncation(a, b);
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(ShrInt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::RightShiftOperator());
    UNBOX_INT64(b, SP[1], Symbols::RightShiftOperator());
    if (b < 0) {
      SP[0] = SP[1];
      goto ThrowArgumentError;
    }
    int64_t result = a >> Utils::Minimum<int64_t>(b, Mint::kBits);
    BOX_INT64_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(CompareIntEq, 0);

    SP -= 1;
    if (SP[0] == SP[1]) {
      SP[0] = true_value;
    } else if (!SP[0]->IsHeapObject() || !SP[1]->IsHeapObject() ||
               (SP[0] == null_value) || (SP[1] == null_value)) {
      SP[0] = false_value;
    } else {
      int64_t a = Integer::Value(Integer::RawCast(SP[0]));
      int64_t b = Integer::Value(Integer::RawCast(SP[1]));
      SP[0] = (a == b) ? true_value : false_value;
    }
    DISPATCH();
  }

  {
    BYTECODE(CompareIntGt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::RAngleBracket());
    UNBOX_INT64(b, SP[1], Symbols::RAngleBracket());
    SP[0] = (a > b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(CompareIntLt, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::LAngleBracket());
    UNBOX_INT64(b, SP[1], Symbols::LAngleBracket());
    SP[0] = (a < b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(CompareIntGe, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::GreaterEqualOperator());
    UNBOX_INT64(b, SP[1], Symbols::GreaterEqualOperator());
    SP[0] = (a >= b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(CompareIntLe, 0);

    SP -= 1;
    UNBOX_INT64(a, SP[0], Symbols::LessEqualOperator());
    UNBOX_INT64(b, SP[1], Symbols::LessEqualOperator());
    SP[0] = (a <= b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(NegateDouble, 0);

    UNBOX_DOUBLE(value, SP[0], Symbols::UnaryMinus());
    double result = -value;
    BOX_DOUBLE_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(AddDouble, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::Plus());
    UNBOX_DOUBLE(b, SP[1], Symbols::Plus());
    double result = a + b;
    BOX_DOUBLE_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(SubDouble, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::Minus());
    UNBOX_DOUBLE(b, SP[1], Symbols::Minus());
    double result = a - b;
    BOX_DOUBLE_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(MulDouble, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::Star());
    UNBOX_DOUBLE(b, SP[1], Symbols::Star());
    double result = a * b;
    BOX_DOUBLE_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(DivDouble, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::Slash());
    UNBOX_DOUBLE(b, SP[1], Symbols::Slash());
    double result = a / b;
    BOX_DOUBLE_RESULT(result);
    DISPATCH();
  }

  {
    BYTECODE(CompareDoubleEq, 0);

    SP -= 1;
    if ((SP[0] == null_value) || (SP[1] == null_value)) {
      SP[0] = (SP[0] == SP[1]) ? true_value : false_value;
    } else {
      double a = Double::RawCast(SP[0])->untag()->value_;
      double b = Double::RawCast(SP[1])->untag()->value_;
      SP[0] = (a == b) ? true_value : false_value;
    }
    DISPATCH();
  }

  {
    BYTECODE(CompareDoubleGt, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::RAngleBracket());
    UNBOX_DOUBLE(b, SP[1], Symbols::RAngleBracket());
    SP[0] = (a > b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(CompareDoubleLt, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::LAngleBracket());
    UNBOX_DOUBLE(b, SP[1], Symbols::LAngleBracket());
    SP[0] = (a < b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(CompareDoubleGe, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::GreaterEqualOperator());
    UNBOX_DOUBLE(b, SP[1], Symbols::GreaterEqualOperator());
    SP[0] = (a >= b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(CompareDoubleLe, 0);

    SP -= 1;
    UNBOX_DOUBLE(a, SP[0], Symbols::LessEqualOperator());
    UNBOX_DOUBLE(b, SP[1], Symbols::LessEqualOperator());
    SP[0] = (a <= b) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(AllocateClosure, 0);
    ++SP;
    if (!AllocateClosure(thread, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    ClosurePtr closure = Closure::RawCast(SP[0]);
    FunctionPtr function = Function::RawCast(SP[-3]);
    ObjectPtr context = SP[-2];
    TypeArgumentsPtr instantiator_type_arguments =
        TypeArguments::RawCast(SP[-1]);

    ASSERT((Function::KindOf(function) == UntaggedFunction::kClosureFunction) ||
           (Function::KindOf(function) ==
            UntaggedFunction::kImplicitClosureFunction));
    closure->untag()->set_function(function);
    ONLY_IN_PRECOMPILED(closure->untag()->entry_point_ =
                            function->untag()->entry_point_);
    closure->untag()->set_context(context);
    closure->untag()->set_instantiator_type_arguments(
        instantiator_type_arguments);
    SP -= 3;
    SP[0] = closure;
    DISPATCH();
  }

  {
    BYTECODE_ENTRY_LABEL(Trap);

#define UNIMPLEMENTED_LABEL_ORDN(Name)
#define UNIMPLEMENTED_LABEL_WIDE(Name)
#define UNIMPLEMENTED_LABEL_RESV(Name) BYTECODE_ENTRY_LABEL(Name)
#define UNIMPLEMENTED_LABEL(name, encoding, kind, op1, op2, op3)               \
  UNIMPLEMENTED_LABEL_##kind(name)

    KERNEL_BYTECODES_LIST(UNIMPLEMENTED_LABEL)

#undef UNIMPLEMENTED_LABEL_ORDN
#undef UNIMPLEMENTED_LABEL_WIDE
#undef UNIMPLEMENTED_LABEL_RESV
#undef UNIMPLEMENTED_LABEL

#if defined(PRODUCT)
    // The breakpoint opcodes are unimplemented when the debugger
    // is unavailable.
    BYTECODE_ENTRY_LABEL(VMInternal_Breakpoint_0)
    BYTECODE_ENTRY_LABEL(VMInternal_Breakpoint_D)
    BYTECODE_ENTRY_LABEL(VMInternal_Breakpoint_D_Wide)
    BYTECODE_ENTRY_LABEL(VMInternal_Breakpoint_A_E)
    BYTECODE_ENTRY_LABEL(VMInternal_Breakpoint_A_E_Wide)
    BYTECODE_ENTRY_LABEL(VMInternal_Breakpoint_A_B_C)
#endif  // defined(PRODUCT)

    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitGetter, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) == UntaggedFunction::kImplicitGetter);

    // Field object is cached in function's data_.
    FieldPtr field = Field::RawCast(function->untag()->data());
    intptr_t offset_in_words =
        Smi::Value(field->untag()->host_offset_or_field_id());

    const intptr_t kArgc = 1;
    InstancePtr instance = Instance::RawCast(FrameArguments(FP, kArgc)[0]);

    ASSERT(!Field::UnboxedBit::decode(field->untag()->kind_bits_));
    ObjectPtr value = GET_FIELD(instance, offset_in_words);

    if (value == Object::sentinel().ptr()) [[unlikely]] {
      SP[1] = 0;  // Result slot.
      SP[2] = instance;
      SP[3] = field;
      Exit(thread, FP, SP + 4, pc);
      INVOKE_RUNTIME(
          DRT_InitInstanceField,
          NativeArguments(thread, 2, /* argv */ SP + 2, /* ret val */ SP + 1));

      function = FrameFunction(FP);
      instance = Instance::RawCast(SP[2]);
      field = Field::RawCast(SP[3]);
      offset_in_words = Smi::Value(field->untag()->host_offset_or_field_id());
      value = GET_FIELD(instance, offset_in_words);
    }

    *++SP = value;

#if !defined(PRODUCT)
    if (Field::NeedsLoadGuardBit::decode(field->untag()->kind_bits_))
        [[unlikely]] {
      if (!AssertAssignableField<true>(thread, pc, FP, SP, instance, field,
                                       Instance::RawCast(value))) {
        HANDLE_EXCEPTION;
      }
    }
#endif

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitSetter, 0);

    FunctionPtr function = FrameFunction(FP);
    if (Function::KindOf(function) ==
        UntaggedFunction::kDynamicInvocationForwarder) {
      function = Function::RawCast(function->untag()->data());
    }
    ASSERT(Function::KindOf(function) == UntaggedFunction::kImplicitSetter);

    // Field object is cached in function's data_.
    FieldPtr field = Field::RawCast(function->untag()->data());
    *++SP = field;
    intptr_t offset_in_words =
        Smi::Value(field->untag()->host_offset_or_field_id());
    const intptr_t kArgc = 2;
    InstancePtr instance = Instance::RawCast(FrameArguments(FP, kArgc)[0]);
    InstancePtr value = Instance::RawCast(FrameArguments(FP, kArgc)[1]);

    if (!AssertAssignableField<false>(thread, pc, FP, SP, instance, field,
                                      value)) {
      HANDLE_EXCEPTION;
    }
    // Reload objects after the call which may trigger GC.
    field = Field::RawCast(SP[0]);
    instance = Instance::RawCast(FrameArguments(FP, kArgc)[0]);
    value = Instance::RawCast(FrameArguments(FP, kArgc)[1]);

    if (Field::FinalBit::decode(field->untag()->kind_bits_)) {
      // Check that final field was not initialized already.
      ObjectPtr old_value = GET_FIELD(instance, offset_in_words);
      if (old_value != Object::sentinel().ptr()) [[unlikely]] {
        SP[0] = field;
        SP[1] = 0;  // Unused space for result.
        Exit(thread, FP, SP + 2, pc);
        INVOKE_RUNTIME(DRT_LateFieldAlreadyInitializedError,
                       NativeArguments(thread, 1, SP, SP + 1));
        UNREACHABLE();
      }
    }

    if (InterpreterHelpers::FieldNeedsGuardUpdate(thread, field, value)) {
      SP[1] = 0;  // Unused result of runtime call.
      SP[2] = field;
      SP[3] = value;
      Exit(thread, FP, SP + 4, pc);
      if (!InvokeRuntime(thread, this, DRT_UpdateFieldCid,
                         NativeArguments(thread, 2, /* argv */ SP + 2,
                                         /* retval */ SP + 1))) {
        HANDLE_EXCEPTION;
      }

      // Reload objects after the call which may trigger GC.
      field = Field::RawCast(SP[0]);
      instance = Instance::RawCast(FrameArguments(FP, kArgc)[0]);
      value = Instance::RawCast(FrameArguments(FP, kArgc)[1]);
    }

    ASSERT(!Field::UnboxedBit::decode(field->untag()->kind_bits_));
    InterpreterHelpers::SetField(instance, offset_in_words, value, thread);

    *SP = null_value;

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitStaticGetter, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kImplicitStaticGetter);

    // Field object is cached in function's data_.
    FieldPtr field = Field::RawCast(function->untag()->data());
    intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
    if (thread->isolate() == nullptr) [[unlikely]] {
      SP[0] = field;
      goto ThrowStaticFieldAccessedWithoutIsolateError;
    }
    ObjectPtr value = thread->field_table_values()[field_id];
    if (value == Object::sentinel().ptr()) {
      SP[1] = 0;  // Unused result of invoking the initializer.
      SP[2] = field;
      Exit(thread, FP, SP + 3, pc);
      INVOKE_RUNTIME(DRT_InitStaticField,
                     NativeArguments(thread, 1, SP + 2, SP + 1));

      // Reload objects after the call which may trigger GC.
      function = FrameFunction(FP);
      field = Field::RawCast(function->untag()->data());
      // The field is initialized by the runtime call, but not returned.
      intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
      value = thread->field_table_values()[field_id];
    }

    // Field was initialized. Return its value.
    *++SP = value;

#if !defined(PRODUCT)
    if (Field::NeedsLoadGuardBit::decode(field->untag()->kind_bits_))
        [[unlikely]] {
      if (!AssertAssignableField<true>(thread, pc, FP, SP,
                                       Instance::RawCast(null_value), field,
                                       Instance::RawCast(value))) {
        HANDLE_EXCEPTION;
      }
    }
#endif

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitSharedStaticGetter, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kImplicitStaticGetter);

    // Field object is cached in function's data_.
    FieldPtr field = Field::RawCast(function->untag()->data());
    intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
    ObjectPtr value = thread->shared_field_table_values()[field_id];
    if (value == Object::sentinel().ptr()) {
      SP[1] = 0;  // Unused result of invoking the initializer.
      SP[2] = field;
      Exit(thread, FP, SP + 3, pc);
      INVOKE_RUNTIME(DRT_InitStaticField,
                     NativeArguments(thread, 1, SP + 2, SP + 1));

      // Reload objects after the call which may trigger GC.
      function = FrameFunction(FP);
      field = Field::RawCast(function->untag()->data());
      // The field is initialized by the runtime call, but not returned.
      intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
      value = thread->shared_field_table_values()[field_id];
    }

    // Field was initialized. Return its value.
    *++SP = value;

#if !defined(PRODUCT)
    if (Field::NeedsLoadGuardBit::decode(field->untag()->kind_bits_))
        [[unlikely]] {
      if (!AssertAssignableField<true>(thread, pc, FP, SP,
                                       Instance::RawCast(null_value), field,
                                       Instance::RawCast(value))) {
        HANDLE_EXCEPTION;
      }
    }
#endif

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitStaticSetter, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) == UntaggedFunction::kImplicitSetter);

    // Field object is cached in function's data_.
    FieldPtr field = Field::RawCast(function->untag()->data());
    intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());
    if (thread->isolate() == nullptr) [[unlikely]] {
      SP[0] = field;
      goto ThrowStaticFieldAccessedWithoutIsolateError;
    }

    // Static fields use setters only if they are final.
    ASSERT(Field::FinalBit::decode(field->untag()->kind_bits_));
    // Check that final field was not initialized already.
    ObjectPtr old_value = thread->field_table_values()[field_id];
    if (old_value != Object::sentinel().ptr()) [[unlikely]] {
      ++SP;
      SP[0] = field;
      SP[1] = 0;  // Unused space for result.
      Exit(thread, FP, SP + 2, pc);
      INVOKE_RUNTIME(DRT_LateFieldAlreadyInitializedError,
                     NativeArguments(thread, 1, SP, SP + 1));
      UNREACHABLE();
    }

    const intptr_t kArgc = 1;
    InstancePtr value = Instance::RawCast(FrameArguments(FP, kArgc)[0]);
    thread->field_table_values()[field_id] = value;

    *++SP = null_value;
    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitSharedStaticSetter, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) == UntaggedFunction::kImplicitSetter);

    // Field object is cached in function's data_.
    FieldPtr field = Field::RawCast(function->untag()->data());
    intptr_t field_id = Smi::Value(field->untag()->host_offset_or_field_id());

    // Static fields use setters if they are final or shared.
    if (Field::FinalBit::decode(field->untag()->kind_bits_)) {
      // Check that final field was not initialized already.
      ObjectPtr old_value = thread->shared_field_table_values()[field_id];
      if (old_value != Object::sentinel().ptr()) [[unlikely]] {
        ++SP;
        SP[0] = field;
        SP[1] = 0;  // Unused space for result.
        Exit(thread, FP, SP + 2, pc);
        INVOKE_RUNTIME(DRT_LateFieldAlreadyInitializedError,
                       NativeArguments(thread, 1, SP, SP + 1));
        UNREACHABLE();
      }
    }

    const intptr_t kArgc = 1;
    InstancePtr value = Instance::RawCast(FrameArguments(FP, kArgc)[0]);
    if (FLAG_experimental_shared_data &&
        (value != Object::null() && !value->IsSmi() &&
         !value->untag()->IsCanonical() &&
         (!value->untag()->IsImmutable() || value->IsClosure()))) {
      ++SP;
      SP[0] = field;
      SP[1] = value;
      SP[2] = 0;  // Unused space for result.
      Exit(thread, FP, SP + 3, pc);
      INVOKE_RUNTIME(DRT_CheckedStoreIntoShared,
                     NativeArguments(thread, 2, SP, SP + 2));
    } else {
      thread->shared_field_table_values()[field_id] = value;
    }
    *++SP = null_value;
    DISPATCH();
  }

  {
    BYTECODE(VMInternal_MethodExtractor, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) == UntaggedFunction::kMethodExtractor);
    function = Function::RawCast(function->untag()->data());
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kImplicitClosureFunction);

    ASSERT(InterpreterHelpers::ArgDescTypeArgsLen(argdesc_) == 0);

    ++SP;
    if (!AllocateClosure(thread, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }

    InstancePtr instance = Instance::RawCast(FrameArguments(FP, 1)[0]);

    ClosurePtr closure = Closure::RawCast(*SP);
    closure->untag()->set_instantiator_type_arguments(
        InterpreterHelpers::GetTypeArguments(thread, instance));
    // function_type_arguments is already null
    closure->untag()->set_delayed_type_arguments(
        Object::empty_type_arguments().ptr());
    closure->untag()->set_function(function);
    ONLY_IN_PRECOMPILED(closure->untag()->entry_point_ =
                            function->untag()->entry_point_);
    closure->untag()->set_context(instance);
    // hash is already null

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_InvokeClosure, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kInvokeFieldDispatcher);
    const bool is_dynamic_call =
        Function::IsDynamicInvocationForwarderName(function->untag()->name());

    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;

    ClosurePtr receiver =
        Closure::RawCast(FrameArguments(FP, argc)[receiver_idx]);
    SP[1] = receiver->untag()->function();

    if (is_dynamic_call) {
      {
        SP[2] = null_value;
        SP[3] = receiver;
        SP[4] = argdesc_;
        Exit(thread, FP, SP + 5, pc);
        if (!InvokeRuntime(thread, this, DRT_ClosureArgumentsValid,
                           NativeArguments(thread, 2, SP + 3, SP + 2))) {
          HANDLE_EXCEPTION;
        }
        receiver = Closure::RawCast(SP[3]);
        argdesc_ = Array::RawCast(SP[4]);
      }

      if (SP[2] != Bool::True().ptr()) {
        goto NoSuchMethodFromPrologue;
      }

      // TODO(dartbug.com/40813): Move other checks that are currently
      // compiled in the closure body to here as they are also moved to
      // FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher.
    }

    goto TailCallSP1;
  }

  {
    BYTECODE(VMInternal_InvokeField, 0);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kInvokeFieldDispatcher);

    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
    ObjectPtr receiver = FrameArguments(FP, argc)[receiver_idx];

    // Possibly demangle field name and invoke field getter on receiver.
    {
      SP[1] = argdesc_;  // Save argdesc_.
      SP[2] = 0;         // Result of runtime call.
      SP[3] = receiver;  // Receiver.
      SP[4] =
          function->untag()->name();  // Field name (may change during call).
      Exit(thread, FP, SP + 5, pc);
      if (!InvokeRuntime(thread, this, DRT_GetFieldForDispatch,
                         NativeArguments(thread, 2, SP + 3, SP + 2))) {
        HANDLE_EXCEPTION;
      }
      function = FrameFunction(FP);
      argdesc_ = Array::RawCast(SP[1]);
    }

    // If the field name in the arguments is different after the call, then
    // this was a dynamic call.
    StringPtr field_name = String::RawCast(SP[4]);
    const bool is_dynamic_call = function->untag()->name() != field_name;

    // Replace receiver with field value, keep all other arguments, and
    // invoke 'call' function, or if not found, invoke noSuchMethod.
    FrameArguments(FP, argc)[receiver_idx] = receiver = SP[2];

    // If the field value is a closure, no need to resolve 'call' function.
    if (receiver->GetClassId() == kClosureCid) {
      SP[1] = Closure::RawCast(receiver)->untag()->function();

      if (is_dynamic_call) {
        {
          SP[2] = null_value;
          SP[3] = receiver;
          SP[4] = argdesc_;
          Exit(thread, FP, SP + 5, pc);
          if (!InvokeRuntime(thread, this, DRT_ClosureArgumentsValid,
                             NativeArguments(thread, 2, SP + 3, SP + 2))) {
            HANDLE_EXCEPTION;
          }
          receiver = SP[3];
          argdesc_ = Array::RawCast(SP[4]);
        }

        if (SP[2] != Bool::True().ptr()) {
          goto NoSuchMethodFromPrologue;
        }

        // TODO(dartbug.com/40813): Move other checks that are currently
        // compiled in the closure body to here as they are also moved to
        // FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher.
      }

      goto TailCallSP1;
    }

    // Otherwise, call runtime to resolve 'call' function.
    {
      SP[1] = 0;  // Result slot.
      SP[2] = receiver;
      SP[3] = argdesc_;
      Exit(thread, FP, SP + 4, pc);
      if (!InvokeRuntime(thread, this, DRT_ResolveCallFunction,
                         NativeArguments(thread, 2, SP + 2, SP + 1))) {
        HANDLE_EXCEPTION;
      }
      argdesc_ = Array::RawCast(SP[3]);
      function = Function::RawCast(SP[1]);
      receiver = SP[2];
    }

    if (function != Function::null()) {
      SP[1] = function;
      goto TailCallSP1;
    }

    // Function 'call' could not be resolved for argdesc_.
    // Invoke noSuchMethod.
    SP[1] = null_value;
    SP[2] = receiver;
    SP[3] = Symbols::call().ptr();  // We failed to resolve the 'call' function.
    SP[4] = argdesc_;
    SP[5] = null_value;  // Array of arguments (will be filled).

    // Allocate array of arguments.
    {
      SP[6] = Smi::New(argc);  // length
      SP[7] = null_value;      // type
      Exit(thread, FP, SP + 8, pc);
      if (!InvokeRuntime(thread, this, DRT_AllocateArray,
                         NativeArguments(thread, 2, SP + 6, SP + 5))) {
        HANDLE_EXCEPTION;
      }
    }

    // Copy arguments into the newly allocated array.
    ObjectPtr* argv = FrameArguments(FP, argc);
    ArrayPtr array = static_cast<ArrayPtr>(SP[5]);
    ASSERT(array->GetClassId() == kArrayCid);
    for (intptr_t i = 0; i < argc; i++) {
      array->untag()->set_element(i, argv[i], thread);
    }

    // Invoke noSuchMethod passing down receiver, target name, argument
    // descriptor, and array of arguments.
    {
      Exit(thread, FP, SP + 6, pc);
      if (!InvokeRuntime(thread, this, DRT_InvokeNoSuchMethod,
                         NativeArguments(thread, 4, SP + 2, SP + 1))) {
        HANDLE_EXCEPTION;
      }

      ++SP;  // Result at SP[0]
    }
    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ForwardDynamicInvocation, 0);
    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kDynamicInvocationForwarder);

    FunctionPtr target = Function::RawCast(function->untag()->data());
    ASSERT(Function::KindOf(target) !=
           UntaggedFunction::kDynamicInvocationForwarder);

    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;

    SP[1] = target;
    SP[2] = argdesc_;

    // Allocate array of arguments.
    {
      SP[3] = null_value;      // Reserve space for result.
      SP[4] = Smi::New(argc);  // length
      SP[5] = null_value;      // type
      Exit(thread, FP, SP + 6, pc);
      if (!InvokeRuntime(thread, this, DRT_AllocateArray,
                         NativeArguments(thread, 2, SP + 4, SP + 3))) {
        HANDLE_EXCEPTION;
      }
    }

    // Copy arguments into the newly allocated array.
    ObjectPtr* argv = FrameArguments(FP, argc);
    ArrayPtr array = Array::RawCast(SP[3]);
    for (intptr_t i = 0; i < argc; i++) {
      array->untag()->set_element(i, argv[i], thread);
    }

    // Check types of arguments.
    {
      SP[4] = null_value;  // Reserve space for result.
      Exit(thread, FP, SP + 5, pc);
      if (!InvokeRuntime(thread, this, DRT_CheckFunctionArgumentTypes,
                         NativeArguments(thread, 3, SP + 1, SP + 4))) {
        HANDLE_EXCEPTION;
      }

      argdesc_ = Array::RawCast(SP[2]);

      if (SP[4] != true_value) {
        goto NoSuchMethodFromPrologue;
      }
    }

    goto TailCallSP1;
  }

  {
    BYTECODE(VMInternal_NoSuchMethodDispatcher, 0);
    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kNoSuchMethodDispatcher);
    SP[1] = function;
    goto NoSuchMethodFromPrologue;
  }

  {
    BYTECODE(VMInternal_ImplicitStaticClosure, 0);
    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kImplicitClosureFunction);
    ClosureDataPtr data = ClosureData::RawCast(function->untag()->data());
    FunctionPtr target = Function::RawCast(data->untag()->parent_function());

    intptr_t type_args_len = InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
    ObjectPtr* argv = FrameArguments(FP, argc);

    TypeParametersPtr type_params =
        FunctionType::RawCast(function->untag()->signature())
            ->untag()
            ->type_parameters();
    if (type_params == null_value) {
      if (type_args_len > 0) {
        SP[1] = function;
        goto NoSuchMethodFromPrologue;
      }
      if (Function::KindOf(target) == UntaggedFunction::kConstructor) {
        // Factory constructors always take type arguments.
        // Replace closure receiver with type arguments.
        argv[0] = TypeArguments::null();
      }
    } else {
      TypeArgumentsPtr delayed_type_arguments =
          Closure::RawCast(argv[receiver_idx])
              ->untag()
              ->delayed_type_arguments();
      if (delayed_type_arguments != Object::empty_type_arguments().ptr()) {
        if (type_args_len > 0) {
          SP[1] = function;
          goto NoSuchMethodFromPrologue;
        }
        // Replace closure receiver with type arguments.
        argv[0] = delayed_type_arguments;
        type_args_len =
            Smi::Value(type_params->untag()->names()->untag()->length());
      } else if (type_args_len > 0) {
        // Replace closure receiver with type arguments.
        argv[1] = argv[0];
      } else if (Function::KindOf(target) == UntaggedFunction::kConstructor) {
        // Factory constructors always take type arguments.
        // Replace closure receiver with type arguments.
        argv[0] = type_params->untag()->defaults();
        type_args_len =
            Smi::Value(type_params->untag()->names()->untag()->length());
      }
    }

    SP[1] = target;
    SP[2] = 0;  // Space for result.
    SP[3] = argdesc_;
    SP[4] = target;
    SP[5] = Smi::New(type_args_len);
    Exit(thread, FP, SP + 6, pc);
    INVOKE_RUNTIME(DRT_AdjustArgumentsDesciptorForImplicitClosure,
                   NativeArguments(thread, 3, SP + 3, SP + 2));
    argdesc_ = Array::RawCast(SP[2]);

    goto TailCallSP1;
  }

  {
    BYTECODE(VMInternal_ImplicitInstanceClosure, D_F);
    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kImplicitClosureFunction);
    ClosureDataPtr data = ClosureData::RawCast(function->untag()->data());
    FunctionPtr target = Function::RawCast(data->untag()->parent_function());

    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
    ObjectPtr* argv = FrameArguments(FP, argc);
    ClosurePtr closure = Closure::RawCast(argv[receiver_idx]);

    TypeParametersPtr type_params =
        FunctionType::RawCast(function->untag()->signature())
            ->untag()
            ->type_parameters();
    if (type_params == null_value) {
      if (type_args_len > 0) {
        SP[1] = function;
        goto NoSuchMethodFromPrologue;
      }
    } else {
      TypeArgumentsPtr delayed_type_arguments =
          closure->untag()->delayed_type_arguments();
      if (delayed_type_arguments != Object::empty_type_arguments().ptr()) {
        if (type_args_len > 0) {
          SP[1] = function;
          goto NoSuchMethodFromPrologue;
        }

        // Type arguments.
        *++SP = delayed_type_arguments;
        ObjectPtr* call_base = SP;
        // Captured receiver.
        *++SP = closure->untag()->context();
        // Copy the rest of the arguments.
        for (intptr_t i = receiver_idx + 1; i < argc; i++) {
          *++SP = argv[i];
        }

        const intptr_t new_type_args_len =
            Smi::Value(type_params->untag()->names()->untag()->length());

        SP[1] = target;
        SP[2] = 0;  // Space for result.
        SP[3] = argdesc_;
        SP[4] = target;
        SP[5] = Smi::New(new_type_args_len);
        Exit(thread, FP, SP + 6, pc);
        INVOKE_RUNTIME(DRT_AdjustArgumentsDesciptorForImplicitClosure,
                       NativeArguments(thread, 3, SP + 3, SP + 2));
        argdesc_ = Array::RawCast(SP[2]);

        ObjectPtr* call_top = SP + 1;
        if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
          HANDLE_EXCEPTION;
        }

        DISPATCH();
      }
    }

    // Replace closure receiver with captured receiver
    // and call target function.
    argv[receiver_idx] = closure->untag()->context();
    SP[1] = target;

    goto TailCallSP1;
  }

  {
    BYTECODE(VMInternal_ImplicitConstructorClosure, D_F);

    FunctionPtr function = FrameFunction(FP);
    ASSERT(Function::KindOf(function) ==
           UntaggedFunction::kImplicitClosureFunction);
    ClosureDataPtr data = ClosureData::RawCast(function->untag()->data());
    FunctionPtr target = Function::RawCast(data->untag()->parent_function());
    ASSERT(Function::KindOf(target) == UntaggedFunction::kConstructor);

    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
    ObjectPtr* argv = FrameArguments(FP, argc);

    // Reserve space for the result (instance).
    *++SP = null_value;
    ASSERT(SP == FP);

    // Reserve space for receiver.
    *++SP = null_value;
    ObjectPtr* call_base = SP;
    // Copy arguments.
    for (intptr_t i = receiver_idx + 1; i < argc; i++) {
      *++SP = argv[i];
    }

    ClassPtr cls = Function::Owner(target);
    TypeParametersPtr type_params = cls->untag()->type_parameters();
    TypeArgumentsPtr type_args;
    if (type_params == null_value) {
      if (type_args_len > 0) {
        SP[1] = function;
        goto NoSuchMethodFromPrologue;
      }
      type_args = TypeArguments::null();
    } else {
      TypeArgumentsPtr delayed_type_arguments =
          Closure::RawCast(argv[receiver_idx])
              ->untag()
              ->delayed_type_arguments();
      if (delayed_type_arguments != Object::empty_type_arguments().ptr()) {
        if (type_args_len > 0) {
          SP[1] = function;
          goto NoSuchMethodFromPrologue;
        }
        type_args = delayed_type_arguments;
      } else {
        if (type_args_len > 0) {
          if (type_args_len !=
              Smi::Value(type_params->untag()->names()->untag()->length())) {
            SP[1] = function;
            goto NoSuchMethodFromPrologue;
          }
          type_args = TypeArguments::RawCast(argv[0]);
        } else {
          type_args = type_params->untag()->defaults();
        }
      }
    }
    const intptr_t num_type_args = cls->untag()->num_type_arguments_;
    if (num_type_args != 0) {
      if ((type_args == null_value) ||
          (Smi::Value(type_args->untag()->length()) != num_type_args)) {
        SP[1] = target;    // Save target.
        SP[2] = argdesc_;  // Save arguments descriptor.
        SP[3] = cls;       // Save class.

        SP[4] = 0;  // Space for result.
        SP[5] = cls;
        SP[6] = type_args;

        Exit(thread, FP, SP + 7, pc);
        INVOKE_RUNTIME(DRT_ConvertToInstanceTypeArguments,
                       NativeArguments(thread, 2, SP + 5, SP + 4));

        target = Function::RawCast(SP[1]);
        argdesc_ = Array::RawCast(SP[2]);
        cls = Class::RawCast(SP[3]);
        type_args = TypeArguments::RawCast(SP[4]);
      }
    }

    SP[1] = target;    // Save target.
    SP[2] = argdesc_;  // Save arguments descriptor.

    // Allocate instance and put it into the receiver slot.
    SP[3] = cls;
    SP[4] = type_args;
    Exit(thread, FP, SP + 5, pc);
    INVOKE_RUNTIME(DRT_AllocateObject, NativeArguments(thread, 2, SP + 3, FP));
    call_base[0] = FP[0];  // Copy receiver.
    argdesc_ = Array::RawCast(SP[2]);

    if (type_args_len > 0) {
      // Need to adjust arguments descriptor in order to drop type arguments.
      SP[2] = 0;  // Space for result.
      SP[3] = argdesc_;
      SP[4] = SP[1];  // Target.
      SP[5] = 0;      // New type_args_len.
      Exit(thread, FP, SP + 6, pc);
      INVOKE_RUNTIME(DRT_AdjustArgumentsDesciptorForImplicitClosure,
                     NativeArguments(thread, 3, SP + 3, SP + 2));
      argdesc_ = Array::RawCast(SP[2]);
    }

    ObjectPtr* call_top = SP + 1;
    if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
      HANDLE_EXCEPTION;
    }

    DISPATCH();
  }

  {
  TailCallSP1:
    FunctionPtr function = Function::RawCast(SP[1]);

    for (;;) {
      if (Function::IsInterpreted(function)) {
        ASSERT(function->IsFunction());
        BytecodePtr bytecode = Function::GetBytecode(function);
        ASSERT(bytecode->IsBytecode());
        FP[kKBCFunctionSlotFromFp] = function;
        FP[kKBCPcMarkerSlotFromFp] = bytecode;
        pp_ = bytecode->untag()->object_pool();
        pc =
            reinterpret_cast<const KBCInstr*>(bytecode->untag()->instructions_);
        NOT_IN_PRODUCT(pc_ = pc);  // For the profiler.
        DISPATCH();
      }

      if (Function::HasCode(function)) {
        const intptr_t type_args_len =
            InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
        const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
        const intptr_t argc =
            InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
        ObjectPtr* argv = FrameArguments(FP, argc);
        for (intptr_t i = 0; i < argc; i++) {
          *++SP = argv[i];
        }

        ObjectPtr* call_base = SP - argc + 1;
        ObjectPtr* call_top = SP + 1;
        call_top[0] = function;
        if (!InvokeCompiled(thread, function, call_base, call_top, &pc, &FP,
                            &SP)) {
          HANDLE_EXCEPTION;
        } else {
          HANDLE_RETURN;
        }
        DISPATCH();
      }

      // Compile the function to either generate code or load bytecode.
      SP[1] = argdesc_;
      SP[2] = 0;  // Code result.
      SP[3] = function;
      Exit(thread, FP, SP + 4, pc);
      if (!InvokeRuntime(thread, this, DRT_CompileFunction,
                         NativeArguments(thread, 1, /* argv */ SP + 3,
                                         /* retval */ SP + 2))) {
        HANDLE_EXCEPTION;
      }
      function = Function::RawCast(SP[3]);
      argdesc_ = Array::RawCast(SP[1]);

      ASSERT(Function::HasCode(function));
    }
  }

  // Helper used to handle noSuchMethod on closures. The function should be
  // placed into SP[1] before jumping here, similar to TailCallSP1.
  {
  NoSuchMethodFromPrologue:
    FunctionPtr function = Function::RawCast(SP[1]);

    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
    const intptr_t argc =
        InterpreterHelpers::ArgDescArgCount(argdesc_) + receiver_idx;
    ObjectPtr* args = FrameArguments(FP, argc);

    SP[1] = null_value;
    SP[2] = args[receiver_idx];
    SP[3] = function;
    SP[4] = argdesc_;
    SP[5] = null_value;  // Array of arguments (will be filled).

    // Allocate array of arguments.
    {
      SP[6] = Smi::New(argc);  // length
      SP[7] = null_value;      // type
      Exit(thread, FP, SP + 8, pc);
      if (!InvokeRuntime(thread, this, DRT_AllocateArray,
                         NativeArguments(thread, 2, SP + 6, SP + 5))) {
        HANDLE_EXCEPTION;
      }

      // Copy arguments into the newly allocated array.
      ArrayPtr array = static_cast<ArrayPtr>(SP[5]);
      ASSERT(array->GetClassId() == kArrayCid);
      for (intptr_t i = 0; i < argc; i++) {
        array->untag()->set_element(i, args[i], thread);
      }
    }

    // Invoke noSuchMethod passing down receiver, function, argument descriptor
    // and array of arguments.
    {
      Exit(thread, FP, SP + 6, pc);
      INVOKE_RUNTIME(DRT_NoSuchMethodFromPrologue,
                     NativeArguments(thread, 4, SP + 2, SP + 1));
      ++SP;  // Result at SP[0]
    }

    DISPATCH();
  }

  {
  ThrowNullError:
    // SP[0] contains selector.
    SP[1] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 2, pc);
    INVOKE_RUNTIME(DRT_NullErrorWithSelector,
                   NativeArguments(thread, 1, SP, SP + 1));
    UNREACHABLE();
  }

  {
  ThrowIntegerDivisionByZeroException:
    SP[0] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 1, pc);
    INVOKE_RUNTIME(DRT_IntegerDivisionByZeroException,
                   NativeArguments(thread, 0, SP, SP));
    UNREACHABLE();
  }

  {
  ThrowArgumentError:
    // SP[0] contains value.
    SP[1] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 2, pc);
    INVOKE_RUNTIME(DRT_ArgumentError, NativeArguments(thread, 1, SP, SP + 1));
    UNREACHABLE();
  }

  {
  ThrowStaticFieldAccessedWithoutIsolateError:
    // SP[0] contains field.
    SP[1] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 2, pc);
    INVOKE_RUNTIME(DRT_StaticFieldAccessedWithoutIsolateError,
                   NativeArguments(thread, 1, SP, SP + 1));
    UNREACHABLE();
  }

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT)
  {
  ThrowNoSuchMethodError:
    // SP[0] contains arguments.
    SP[1] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 2, pc);
    INVOKE_RUNTIME(DRT_NoSuchMethodError,
                   NativeArguments(thread, 1, SP, SP + 1));
    UNREACHABLE();
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT)

  // Exception handling helper. Gets handler FP and PC from the Interpreter
  // where they were stored by Interpreter::Longjmp and proceeds to execute the
  // handler. Corner case: handler PC can be a fake marker that marks entry
  // frame, which means exception was not handled in the interpreter. In this
  // case we return the caught exception from Interpreter::Call.
  {
  HandleException:
    FP = fp_;
    pc = pc_;
    if (IsEntryFrameMarker(pc)) {
      pp_ = static_cast<ObjectPoolPtr>(fp_[kKBCSavedPpSlotFromEntryFp]);
      argdesc_ = static_cast<ArrayPtr>(fp_[kKBCSavedArgDescSlotFromEntryFp]);
      uword exit_fp = static_cast<uword>(fp_[kKBCExitLinkSlotFromEntryFp]);
      thread->set_top_exit_frame_info(exit_fp);
      thread->set_top_resource(top_resource);
      thread->set_vm_tag(vm_tag);
#if defined(DEBUG)
      if (IsTracingExecution()) {
        THR_Print("%" Pu64 " ", icount_);
        THR_Print("Returning exception from interpreter 0x%" Px " at fp_ 0x%" Px
                  " exit 0x%" Px "\n",
                  reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
                  exit_fp);
      }
#endif
      ASSERT(HasFrame(reinterpret_cast<uword>(fp_)));
      return special_[KernelBytecode::kExceptionSpecialIndex];
    }

    pp_ = InterpreterHelpers::FrameBytecode(FP)->untag()->object_pool();
    DISPATCH();
  }

#if !defined(PRODUCT)
#define DEFINE_BREAKPOINT(Format)                                              \
  {                                                                            \
    BYTECODE(VMInternal_Breakpoint_##Format, Format)                           \
    SP[1] = 0; /* Smi containing the original opcode. */                       \
    Exit(thread, FP, SP + 2, pc);                                              \
    INVOKE_RUNTIME(DRT_BreakpointRuntimeHandler,                               \
                   NativeArguments(thread, 0, nullptr, SP + 1));               \
    uint32_t old_op = RawSmiValue(Smi::RawCast(SP[1]));                        \
    ASSERT_EQUAL(KernelBytecode::BreakpointOpcode(                             \
                     static_cast<KernelBytecode::Opcode>(old_op)),             \
                 op);                                                          \
    op = old_op;                                                               \
    /* The pc is moved to the next instruction during the dispatch to  */      \
    /* the original instruction's implementation, so re-adjust it to   */      \
    /* before the breakpoint/original instruction prior to dispatch.   */      \
    pc -= KernelBytecode::kInstructionSize[op];                                \
    BREAKPOINT_DISPATCH;                                                       \
  }
  DEFINE_BREAKPOINT(0)      // size 1
  DEFINE_BREAKPOINT(D)      // size 2 and 5
  DEFINE_BREAKPOINT(A_E)    // size 3 and 6
  DEFINE_BREAKPOINT(A_B_C)  // size 4
#undef DEFINE_BREAKPOINT

  {
#define SINGLE_STEP_HANDLER_ENTRY(Name, __, ___, ____, _____, ______)          \
  bc##Name##_SingleStep:
    KERNEL_BYTECODES_LIST(SINGLE_STEP_HANDLER_ENTRY)
#undef SINGLE_STEP_HANDLER_ENTRY

#if defined(DEBUG)
    if (IsTracingExecution()) {
      // Use the original instruction count, as it was incremented before
      // the dispatch jump.
      THR_Print("%" Pu64 " calling single step handler\n", icount_ - 1);
    }
#endif

    // The debugger expects return addresses in the frames when retrieving
    // source positions, so use the next instruction's address.
    Exit(thread, FP, SP + 1, KernelBytecode::Next(pc));
    INVOKE_RUNTIME(DRT_SingleStepHandler,
                   NativeArguments(thread, 0, nullptr, nullptr));
    DISPATCH_ORIGINAL_OPCODE;
  }
#endif  // !defined(PRODUCT)

  UNREACHABLE();
  return 0;
}

void Interpreter::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
  // Walk over all setjmp buffers (simulated --> C++ transitions)
  // and try to find the setjmp associated with the simulated frame pointer.
  InterpreterSetjmpBuffer* buf = last_setjmp_buffer();
  while ((buf->link() != nullptr) && (buf->link()->fp() > fp)) {
    buf = buf->link();
  }
  ASSERT(buf != nullptr);
  ASSERT(last_setjmp_buffer() == buf);

  fp_ = reinterpret_cast<ObjectPtr*>(fp);

  if (pc == StubCode::RunExceptionHandler().EntryPoint()) {
    // The RunExceptionHandler stub is a placeholder.  We implement
    // its behavior here.
    ObjectPtr raw_exception = thread->active_exception();
    ObjectPtr raw_stacktrace = thread->active_stacktrace();
    ASSERT(raw_exception != Object::null());
    thread->set_active_exception(Object::null_object());
    thread->set_active_stacktrace(Object::null_object());
    special_[KernelBytecode::kExceptionSpecialIndex] = raw_exception;
    special_[KernelBytecode::kStackTraceSpecialIndex] = raw_stacktrace;
    pc_ = reinterpret_cast<const KBCInstr*>(thread->resume_pc());
  } else {
    pc_ = reinterpret_cast<const KBCInstr*>(pc);
  }

#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("JumpToFrame interpreter 0x%" Px " at fp_ 0x%" Px " pc_ 0x%" Px
              "\n",
              reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
              reinterpret_cast<uword>(pc_));
  }
#endif

  // Set the tag.
  thread->set_vm_tag(VMTag::kDartInterpretedTagId);
  // Clear top exit frame.
  thread->set_top_exit_frame_info(0);

  buf->Longjmp();
  UNREACHABLE();
}

void Interpreter::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&pp_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&argdesc_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&subtype_test_cache_));
}

}  // namespace dart

#endif  // defined(DART_DYNAMIC_MODULES)
