// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/interpreter.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler_kbc.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/lockers.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/stack_frame_kbc.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(uint64_t,
            trace_interpreter_after,
            ULLONG_MAX,
            "Trace interpreter execution after instruction count reached.");
DEFINE_FLAG(charp,
            interpreter_trace_file,
            NULL,
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
    longjmp(buffer_, 1);
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
  RawObject** fp_;
  Interpreter* interpreter_;
  InterpreterSetjmpBuffer* link_;

  friend class Interpreter;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(InterpreterSetjmpBuffer);
};

DART_FORCE_INLINE static RawObject** SavedCallerFP(RawObject** FP) {
  return reinterpret_cast<RawObject**>(FP[kKBCSavedCallerFpSlotFromFp]);
}

DART_FORCE_INLINE static RawObject** FrameArguments(RawObject** FP,
                                                    intptr_t argc) {
  return FP - (kKBCDartFrameFixedSize + argc);
}

#define RAW_CAST(Type, val) (InterpreterHelpers::CastTo##Type(val))

class InterpreterHelpers {
 public:
#define DEFINE_CASTS(Type)                                                     \
  DART_FORCE_INLINE static Raw##Type* CastTo##Type(RawObject* obj) {           \
    ASSERT((k##Type##Cid == kSmiCid)                                           \
               ? !obj->IsHeapObject()                                          \
               : (k##Type##Cid == kIntegerCid)                                 \
                     ? (!obj->IsHeapObject() || obj->IsMint())                 \
                     : obj->Is##Type());                                       \
    return reinterpret_cast<Raw##Type*>(obj);                                  \
  }
  CLASS_LIST(DEFINE_CASTS)
#undef DEFINE_CASTS

  DART_FORCE_INLINE static RawSmi* GetClassIdAsSmi(RawObject* obj) {
    return Smi::New(obj->IsHeapObject() ? obj->GetClassId()
                                        : static_cast<intptr_t>(kSmiCid));
  }

  DART_FORCE_INLINE static intptr_t GetClassId(RawObject* obj) {
    return obj->IsHeapObject() ? obj->GetClassId()
                               : static_cast<intptr_t>(kSmiCid);
  }

  DART_FORCE_INLINE static RawTypeArguments* GetTypeArguments(
      Thread* thread,
      RawInstance* instance) {
    RawClass* instance_class =
        thread->isolate()->class_table()->At(GetClassId(instance));
    return instance_class->ptr()->num_type_arguments_ > 0
               ? reinterpret_cast<RawTypeArguments**>(
                     instance
                         ->ptr())[instance_class->ptr()
                                      ->type_arguments_field_offset_in_words_]
               : TypeArguments::null();
  }

  // The usage counter is actually a 'hotness' counter.
  // For an instance call, both the usage counters of the caller and of the
  // calle will get incremented, as well as the ICdata counter at the call site.
  DART_FORCE_INLINE static void IncrementUsageCounter(RawFunction* f) {
    f->ptr()->usage_counter_++;
  }

  DART_FORCE_INLINE static void IncrementICUsageCount(RawObject** entries,
                                                      intptr_t offset,
                                                      intptr_t args_tested) {
    const intptr_t count_offset = ICData::CountIndexFor(args_tested);
    const intptr_t raw_smi_old =
        reinterpret_cast<intptr_t>(entries[offset + count_offset]);
    const intptr_t raw_smi_new = raw_smi_old + Smi::RawValue(1);
    *reinterpret_cast<intptr_t*>(&entries[offset + count_offset]) = raw_smi_new;
  }

  DART_FORCE_INLINE static bool CheckIndex(RawSmi* index, RawSmi* length) {
    return !index->IsHeapObject() && (reinterpret_cast<intptr_t>(index) >= 0) &&
           (reinterpret_cast<intptr_t>(index) <
            reinterpret_cast<intptr_t>(length));
  }

  DART_FORCE_INLINE static intptr_t ArgDescTypeArgsLen(RawArray* argdesc) {
    return Smi::Value(*reinterpret_cast<RawSmi**>(
        reinterpret_cast<uword>(argdesc->ptr()) +
        Array::element_offset(ArgumentsDescriptor::kTypeArgsLenIndex)));
  }

  DART_FORCE_INLINE static intptr_t ArgDescArgCount(RawArray* argdesc) {
    return Smi::Value(*reinterpret_cast<RawSmi**>(
        reinterpret_cast<uword>(argdesc->ptr()) +
        Array::element_offset(ArgumentsDescriptor::kCountIndex)));
  }

  DART_FORCE_INLINE static intptr_t ArgDescPosCount(RawArray* argdesc) {
    return Smi::Value(*reinterpret_cast<RawSmi**>(
        reinterpret_cast<uword>(argdesc->ptr()) +
        Array::element_offset(ArgumentsDescriptor::kPositionalCountIndex)));
  }

  DART_FORCE_INLINE static RawBytecode* FrameBytecode(RawObject** FP) {
    ASSERT(GetClassId(FP[kKBCPcMarkerSlotFromFp]) == kBytecodeCid);
    return static_cast<RawBytecode*>(FP[kKBCPcMarkerSlotFromFp]);
  }

  DART_FORCE_INLINE static bool FieldNeedsGuardUpdate(RawField* field,
                                                      RawObject* value) {
    // The interpreter should never see a cloned field.
    ASSERT(field->ptr()->owner_->GetClassId() != kFieldCid);

    const classid_t guarded_cid = field->ptr()->guarded_cid_;

    if (guarded_cid == kDynamicCid) {
      // Field is not guarded.
      return false;
    }

    ASSERT(Isolate::Current()->use_field_guards());

    const classid_t nullability_cid = field->ptr()->is_nullable_;
    const classid_t value_cid = InterpreterHelpers::GetClassId(value);

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
        Smi::Value(field->ptr()->guarded_list_length_);

    if (UNLIKELY(guarded_list_length >= Field::kUnknownFixedLength)) {
      // Guarding length, check this in the runtime.
      return true;
    }

    if (UNLIKELY(field->ptr()->static_type_exactness_state_ >=
                 StaticTypeExactnessState::Uninitialized().Encode())) {
      // Guarding "exactness", check this in the runtime.
      return true;
    }

    // Everything matches.
    return false;
  }

  DART_FORCE_INLINE static bool IsFinalized(RawClass* cls) {
    return Class::ClassFinalizedBits::decode(cls->ptr()->state_bits_) ==
           RawClass::kFinalized;
  }
};

DART_FORCE_INLINE static uint32_t* SavedCallerPC(RawObject** FP) {
  return reinterpret_cast<uint32_t*>(FP[kKBCSavedCallerPcSlotFromFp]);
}

DART_FORCE_INLINE static RawFunction* FrameFunction(RawObject** FP) {
  RawFunction* function = static_cast<RawFunction*>(FP[kKBCFunctionSlotFromFp]);
  ASSERT(InterpreterHelpers::GetClassId(function) == kFunctionCid ||
         InterpreterHelpers::GetClassId(function) == kNullCid);
  return function;
}

DART_FORCE_INLINE static RawObject* InitializeHeader(uword addr,
                                                     intptr_t class_id,
                                                     intptr_t instance_size) {
  uint32_t tags = 0;
  tags = RawObject::ClassIdTag::update(class_id, tags);
  tags = RawObject::SizeTag::update(instance_size, tags);
  tags = RawObject::OldBit::update(false, tags);
  tags = RawObject::OldAndNotMarkedBit::update(false, tags);
  tags = RawObject::OldAndNotRememberedBit::update(false, tags);
  tags = RawObject::NewBit::update(true, tags);
  // Also writes zero in the hash_ field.
  *reinterpret_cast<uword*>(addr + Object::tags_offset()) = tags;
  return RawObject::FromAddr(addr);
}

void LookupCache::Clear() {
  for (intptr_t i = 0; i < kNumEntries; i++) {
    entries_[i].receiver_cid = kIllegalCid;
  }
}

bool LookupCache::Lookup(intptr_t receiver_cid,
                         RawString* function_name,
                         RawFunction** target) const {
  ASSERT(receiver_cid != kIllegalCid);  // Sentinel value.

  const intptr_t hash =
      receiver_cid ^ reinterpret_cast<intptr_t>(function_name);
  const intptr_t probe1 = hash & kTableMask;
  if (entries_[probe1].receiver_cid == receiver_cid &&
      entries_[probe1].function_name == function_name) {
    *target = entries_[probe1].target;
    return true;
  }

  intptr_t probe2 = (hash >> 3) & kTableMask;
  if (entries_[probe2].receiver_cid == receiver_cid &&
      entries_[probe2].function_name == function_name) {
    *target = entries_[probe2].target;
    return true;
  }

  return false;
}

void LookupCache::Insert(intptr_t receiver_cid,
                         RawString* function_name,
                         RawFunction* target) {
  // Otherwise we have to clear the cache or rehash on scavenges too.
  ASSERT(function_name->IsOldObject());
  ASSERT(target->IsOldObject());

  const intptr_t hash =
      receiver_cid ^ reinterpret_cast<intptr_t>(function_name);
  const intptr_t probe1 = hash & kTableMask;
  if (entries_[probe1].receiver_cid == kIllegalCid) {
    entries_[probe1].receiver_cid = receiver_cid;
    entries_[probe1].function_name = function_name;
    entries_[probe1].target = target;
    return;
  }

  const intptr_t probe2 = (hash >> 3) & kTableMask;
  if (entries_[probe2].receiver_cid == kIllegalCid) {
    entries_[probe2].receiver_cid = receiver_cid;
    entries_[probe2].function_name = function_name;
    entries_[probe2].target = target;
    return;
  }

  entries_[probe1].receiver_cid = receiver_cid;
  entries_[probe1].function_name = function_name;
  entries_[probe1].target = target;
}

Interpreter::Interpreter()
    : stack_(NULL), fp_(NULL), pp_(NULL), argdesc_(NULL), lookup_cache_() {
#if defined(TARGET_ARCH_DBC)
  FATAL("Interpreter is not supported when targeting DBC\n");
#endif  // defined(USING_SIMULATOR) || defined(TARGET_ARCH_DBC)

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

  last_setjmp_buffer_ = NULL;

  DEBUG_ONLY(icount_ = 1);  // So that tracing after 0 traces first bytecode.

#if defined(DEBUG)
  trace_file_bytes_written_ = 0;
  trace_file_ = NULL;
  if (FLAG_interpreter_trace_file != NULL) {
    Dart_FileOpenCallback file_open = Dart::file_open_callback();
    if (file_open != NULL) {
      trace_file_ = file_open(FLAG_interpreter_trace_file, /* write */ true);
      trace_buffer_ = new KBCInstr[kTraceBufferInstrs];
      trace_buffer_idx_ = 0;
    }
  }
#endif
}

Interpreter::~Interpreter() {
  delete[] stack_;
  pp_ = NULL;
  argdesc_ = NULL;
#if defined(DEBUG)
  if (trace_file_ != NULL) {
    FlushTraceBuffer();
    // Close the file.
    Dart_FileCloseCallback file_close = Dart::file_close_callback();
    if (file_close != NULL) {
      file_close(trace_file_);
      trace_file_ = NULL;
      delete[] trace_buffer_;
      trace_buffer_ = NULL;
    }
  }
#endif
}

// Get the active Interpreter for the current isolate.
Interpreter* Interpreter::Current() {
  Thread* thread = Thread::Current();
  Interpreter* interpreter = thread->interpreter();
  if (interpreter == NULL) {
    TransitionGeneratedToVM transition(thread);
    interpreter = new Interpreter();
    Thread::Current()->set_interpreter(interpreter);
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
DART_NOINLINE void Interpreter::TraceInstruction(uint32_t* pc) const {
  THR_Print("%" Pu64 " ", icount_);
  if (FLAG_support_disassembler) {
    KernelBytecodeDisassembler::Disassemble(reinterpret_cast<uword>(pc),
                                            reinterpret_cast<uword>(pc + 1));
  } else {
    THR_Print("Disassembler not supported in this mode.\n");
  }
}

DART_FORCE_INLINE bool Interpreter::IsWritingTraceFile() const {
  return (trace_file_ != NULL) &&
         (trace_file_bytes_written_ < FLAG_interpreter_trace_file_max_bytes);
}

void Interpreter::FlushTraceBuffer() {
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  if (file_write == NULL) {
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

DART_NOINLINE void Interpreter::WriteInstructionToTrace(uint32_t* pc) {
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  if (file_write == NULL) {
    return;
  }
  if (trace_buffer_idx_ < kTraceBufferInstrs) {
    trace_buffer_[trace_buffer_idx_++] = static_cast<KBCInstr>(*pc);
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
                       RawObject** base,
                       RawObject** frame,
                       uint32_t* pc) {
  frame[0] = Function::null();
  frame[1] = Bytecode::null();
  frame[2] = reinterpret_cast<RawObject*>(pc);
  frame[3] = reinterpret_cast<RawObject*>(base);

  RawObject** exit_fp = frame + kKBCDartFrameFixedSize;
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
  RawObject** exit_fp =
      reinterpret_cast<RawObject**>(thread->top_exit_frame_info());
  ASSERT(exit_fp != 0);
  pc_ = SavedCallerPC(exit_fp);
  fp_ = SavedCallerFP(exit_fp);
#endif
  thread->set_top_exit_frame_info(0);
}

// Calling into runtime may trigger garbage collection and relocate objects,
// so all RawObject* pointers become outdated and should not be used across
// runtime calls.
// Note: functions below are marked DART_NOINLINE to recover performance on
// ARM where inlining these functions into the interpreter loop seemed to cause
// some code quality issues.
static DART_NOINLINE bool InvokeRuntime(Thread* thread,
                                        Interpreter* interpreter,
                                        RuntimeFunction drt,
                                        const NativeArguments& args) {
  InterpreterSetjmpBuffer buffer(interpreter);
  if (!setjmp(buffer.buffer_)) {
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
                                       Dart_NativeFunction function,
                                       Dart_NativeArguments args) {
  InterpreterSetjmpBuffer buffer(interpreter);
  if (!setjmp(buffer.buffer_)) {
    thread->set_vm_tag(reinterpret_cast<uword>(function));
    wrapper(args, function);
    thread->set_vm_tag(VMTag::kDartInterpretedTagId);
    interpreter->Unexit(thread);
    return true;
  } else {
    return false;
  }
}

DART_NOINLINE bool Interpreter::InvokeCompiled(Thread* thread,
                                               RawFunction* function,
                                               RawObject** call_base,
                                               RawObject** call_top,
                                               uint32_t** pc,
                                               RawObject*** FP,
                                               RawObject*** SP) {
  ASSERT(Function::HasCode(function));
  RawCode* volatile code = function->ptr()->code_;
  ASSERT(code != StubCode::LazyCompile().raw());
  // TODO(regis): Once we share the same stack, try to invoke directly.
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("invoking compiled %s\n", Function::Handle(function).ToCString());
  }
#endif
  // On success, returns a RawInstance.  On failure, a RawError.
  typedef RawObject* (*invokestub)(RawCode * code, RawArray * argdesc,
                                   RawObject * *arg0, Thread * thread);
  invokestub volatile entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeFromBytecode().EntryPoint());
  RawObject* volatile result;
  Exit(thread, *FP, call_top + 1, *pc);
  {
    InterpreterSetjmpBuffer buffer(this);
    if (!setjmp(buffer.buffer_)) {
#if defined(TARGET_ARCH_DBC)
      USE(entrypoint);
      UNIMPLEMENTED();
#elif defined(USING_SIMULATOR)
      result = bit_copy<RawObject*, int64_t>(
          Simulator::Current()->Call(reinterpret_cast<intptr_t>(entrypoint),
                                     reinterpret_cast<intptr_t>(code),
                                     reinterpret_cast<intptr_t>(argdesc_),
                                     reinterpret_cast<intptr_t>(call_base),
                                     reinterpret_cast<intptr_t>(thread)));
#else
      result = entrypoint(code, argdesc_, call_base, thread);
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
  pp_ = InterpreterHelpers::FrameBytecode(*FP)->ptr()->object_pool_;

  // If the result is an error (not a Dart instance), it must either be rethrown
  // (in the case of an unhandled exception) or it must be returned to the
  // caller of the interpreter to be propagated.
  if (result->IsHeapObject()) {
    const intptr_t result_cid = result->GetClassId();
    if (result_cid == kUnhandledExceptionCid) {
      (*SP)[0] = UnhandledException::RawCast(result)->ptr()->exception_;
      (*SP)[1] = UnhandledException::RawCast(result)->ptr()->stacktrace_;
      (*SP)[2] = 0;  // Space for result.
      Exit(thread, *FP, *SP + 3, *pc);
      NativeArguments args(thread, 2, *SP, *SP + 2);
      if (!InvokeRuntime(thread, this, DRT_ReThrow, args)) {
        return false;
      }
      UNREACHABLE();
    }
    if (RawObject::IsErrorClassId(result_cid)) {
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
  }
  return true;
}

DART_NOINLINE bool Interpreter::ProcessInvocation(bool* invoked,
                                                  Thread* thread,
                                                  RawFunction* function,
                                                  RawObject** call_base,
                                                  RawObject** call_top,
                                                  uint32_t** pc,
                                                  RawObject*** FP,
                                                  RawObject*** SP) {
  ASSERT(!Function::HasCode(function) && !Function::HasBytecode(function));
  ASSERT(function == call_top[0]);
  RawFunction::Kind kind = Function::kind(function);
  switch (kind) {
    case RawFunction::kImplicitStaticFinalGetter: {
      // Field object is cached in function's data_.
      RawField* field = reinterpret_cast<RawField*>(function->ptr()->data_);
      RawInstance* value = field->ptr()->value_.static_value_;
      if (value == Object::sentinel().raw() ||
          value == Object::transition_sentinel().raw()) {
        call_top[1] = 0;  // Unused result of invoking the initializer.
        call_top[2] = field;
        Exit(thread, *FP, call_top + 3, *pc);
        NativeArguments native_args(thread, 1, call_top + 2, call_top + 1);
        if (!InvokeRuntime(thread, this, DRT_InitStaticField, native_args)) {
          *invoked = true;
          return false;
        }
        // Reload objects after the call which may trigger GC.
        function = reinterpret_cast<RawFunction*>(call_top[0]);
        field = reinterpret_cast<RawField*>(function->ptr()->data_);
        pp_ = InterpreterHelpers::FrameBytecode(*FP)->ptr()->object_pool_;
        // The field is initialized by the runtime call, but not returned.
        value = field->ptr()->value_.static_value_;
      }
      // Field was initialized. Return its value.
      *SP = call_base;
      **SP = value;
      *invoked = true;
      return true;
    }
    case RawFunction::kInvokeFieldDispatcher: {
      const intptr_t type_args_len =
          InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
      const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
      RawObject* receiver = call_base[receiver_idx];
      RawObject** callee_fp = call_top + kKBCDartFrameFixedSize;
      ASSERT(function == FrameFunction(callee_fp));
      RawFunction* call_function = Function::null();
      if (function->ptr()->name_ == Symbols::Call().raw()) {
        RawObject* owner = function->ptr()->owner_;
        if (owner->GetClassId() == kPatchClassCid) {
          owner = PatchClass::RawCast(owner)->ptr()->patched_class_;
        }
        if (owner == thread->isolate()->object_store()->closure_class()) {
          // Closure call.
          call_function = Closure::RawCast(receiver)->ptr()->function_;
        }
      }
      if (call_function == Function::null()) {
        // Invoke field getter on receiver.
        call_top[1] = argdesc_;                // Save argdesc_.
        call_top[2] = 0;                       // Result of runtime call.
        call_top[3] = receiver;                // Receiver.
        call_top[4] = function->ptr()->name_;  // Field name.
        Exit(thread, *FP, call_top + 5, *pc);
        NativeArguments native_args(thread, 2, call_top + 3, call_top + 2);
        if (!InvokeRuntime(thread, this, DRT_GetFieldForDispatch,
                           native_args)) {
          return false;
        }
        argdesc_ = Array::RawCast(call_top[1]);

        // Replace receiver with field value, keep all other arguments, and
        // invoke 'call' function, or if not found, invoke noSuchMethod.
        receiver = call_top[2];
        call_base[receiver_idx] = receiver;

        // If the field value is a closure, no need to resolve 'call' function.
        // Otherwise, call runtime to resolve 'call' function.
        if (InterpreterHelpers::GetClassId(receiver) == kClosureCid) {
          // Closure call.
          call_function = Closure::RawCast(receiver)->ptr()->function_;
        } else {
          // Resolve and invoke the 'call' function.
          call_top[3] = argdesc_;
          call_top[4] = 0;  // Result of runtime call.
          Exit(thread, *FP, call_top + 5, *pc);
          NativeArguments native_args(thread, 2, call_top + 2, call_top + 4);
          if (!InvokeRuntime(thread, this, DRT_ResolveCallFunction,
                             native_args)) {
            return false;
          }
          argdesc_ = Array::RawCast(call_top[1]);
          call_function = Function::RawCast(call_top[4]);
          if (call_function == Function::null()) {
            // Function 'call' could not be resolved for argdesc_.
            // Invoke noSuchMethod.
            const intptr_t argc =
                receiver_idx + InterpreterHelpers::ArgDescArgCount(argdesc_);
            RawObject* null_value = Object::null();
            call_top[1] = null_value;
            call_top[2] = call_base[receiver_idx];
            call_top[3] = argdesc_;
            call_top[4] = null_value;  // Array of arguments (will be filled).

            // Allocate array of arguments.
            {
              call_top[5] = Smi::New(argc);  // length
              call_top[6] = null_value;      // type
              Exit(thread, *FP, call_top + 7, *pc);
              NativeArguments native_args(thread, 2, call_top + 5,
                                          call_top + 4);
              if (!InvokeRuntime(thread, this, DRT_AllocateArray,
                                 native_args)) {
                return false;
              }

              // Copy arguments into the newly allocated array.
              RawArray* array = static_cast<RawArray*>(call_top[4]);
              ASSERT(array->GetClassId() == kArrayCid);
              for (intptr_t i = 0; i < argc; i++) {
                array->ptr()->data()[i] = call_base[i];
              }
            }

            // We failed to resolve 'call' function.
            call_top[5] = Symbols::Call().raw();

            // Invoke noSuchMethod passing down receiver, argument descriptor,
            // array of arguments, and target name.
            {
              Exit(thread, *FP, call_top + 6, *pc);
              NativeArguments native_args(thread, 4, call_top + 2,
                                          call_top + 1);
              if (!InvokeRuntime(thread, this, DRT_InvokeNoSuchMethod,
                                 native_args)) {
                return false;
              }
            }
            *SP = call_base;
            **SP = call_top[1];
            *invoked = true;
            return true;
          }
        }
      }
      ASSERT(call_function != Function::null());
      // Patch field dispatcher in callee frame with call function.
      callee_fp[kKBCFunctionSlotFromFp] = call_function;
      // Do not compile function if it has code or bytecode.
      if (Function::HasCode(call_function)) {
        *invoked = true;
        return InvokeCompiled(thread, call_function, call_base, call_top, pc,
                              FP, SP);
      }
      if (Function::HasBytecode(call_function)) {
        *invoked = false;
        return true;
      }
      function = call_function;
      break;  // Compile and invoke the function.
    }
    case RawFunction::kNoSuchMethodDispatcher:
      // TODO(regis): Implement. For now, use jitted version.
      break;
    case RawFunction::kDynamicInvocationForwarder:
      // TODO(regis): Implement. For now, use jitted version.
      break;
    default:
      break;
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
  if (Function::HasCode(function)) {
    *invoked = true;
    return InvokeCompiled(thread, function, call_base, call_top, pc, FP, SP);
  }
  ASSERT(Function::HasBytecode(function));
  // Bytecode was loaded in the above compilation step.
  // The caller will dispatch to the function's bytecode.
  *invoked = false;
  ASSERT(thread->vm_tag() == VMTag::kDartInterpretedTagId);
  ASSERT(thread->top_exit_frame_info() == 0);
  return true;
}

DART_FORCE_INLINE bool Interpreter::Invoke(Thread* thread,
                                           RawObject** call_base,
                                           RawObject** call_top,
                                           uint32_t** pc,
                                           RawObject*** FP,
                                           RawObject*** SP) {
  RawObject** callee_fp = call_top + kKBCDartFrameFixedSize;

  RawFunction* function = FrameFunction(callee_fp);
  if (Function::HasCode(function)) {
    return InvokeCompiled(thread, function, call_base, call_top, pc, FP, SP);
  }
  if (!Function::HasBytecode(function)) {
    bool invoked = false;
    bool result = ProcessInvocation(&invoked, thread, function, call_base,
                                    call_top, pc, FP, SP);
    if (invoked || !result) {
      return result;
    }
    function = FrameFunction(callee_fp);  // Function may have been patched.
    ASSERT(Function::HasBytecode(function));
  }
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("invoking %s\n",
              Function::Handle(function).ToFullyQualifiedCString());
  }
#endif
  RawBytecode* bytecode = function->ptr()->bytecode_;
  callee_fp[kKBCPcMarkerSlotFromFp] = bytecode;
  callee_fp[kKBCSavedCallerPcSlotFromFp] = reinterpret_cast<RawObject*>(*pc);
  callee_fp[kKBCSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(*FP);
  pp_ = bytecode->ptr()->object_pool_;
  *pc = reinterpret_cast<uint32_t*>(bytecode->ptr()->instructions_);
  NOT_IN_PRODUCT(pc_ = *pc);  // For the profiler.
  *FP = callee_fp;
  NOT_IN_PRODUCT(fp_ = callee_fp);  // For the profiler.
  *SP = *FP - 1;
  return true;
}

void Interpreter::InlineCacheMiss(int checked_args,
                                  Thread* thread,
                                  RawICData* icdata,
                                  RawObject** args,
                                  RawObject** top,
                                  uint32_t* pc,
                                  RawObject** FP,
                                  RawObject** SP) {
  RawObject** result = top;
  top[0] = 0;  // Clean up result slot.

  // Save arguments descriptor as it may be clobbered by running Dart code
  // during the call to miss handler (class finalization).
  top[1] = argdesc_;

  RawObject** miss_handler_args = top + 2;
  for (intptr_t i = 0; i < checked_args; i++) {
    miss_handler_args[i] = args[i];
  }
  miss_handler_args[checked_args] = icdata;
  RuntimeFunction handler = NULL;
  switch (checked_args) {
    case 1:
      handler = DRT_InlineCacheMissHandlerOneArg;
      break;
    case 2:
      handler = DRT_InlineCacheMissHandlerTwoArgs;
      break;
    default:
      UNREACHABLE();
      break;
  }

  // Handler arguments: arguments to check and an ICData object.
  const intptr_t miss_handler_argc = checked_args + 1;
  RawObject** exit_frame = miss_handler_args + miss_handler_argc;
  Exit(thread, FP, exit_frame, pc);
  NativeArguments native_args(thread, miss_handler_argc, miss_handler_args,
                              result);
  handler(native_args);

  argdesc_ = Array::RawCast(top[1]);
}

DART_FORCE_INLINE bool Interpreter::InterfaceCall(Thread* thread,
                                                  RawString* target_name,
                                                  RawObject** call_base,
                                                  RawObject** top,
                                                  uint32_t** pc,
                                                  RawObject*** FP,
                                                  RawObject*** SP) {
  const intptr_t type_args_len =
      InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
  const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;

  intptr_t receiver_cid =
      InterpreterHelpers::GetClassId(call_base[receiver_idx]);

  RawFunction* target;
  if (UNLIKELY(!lookup_cache_.Lookup(receiver_cid, target_name, &target))) {
    // Table lookup miss.
    top[1] = call_base[receiver_idx];
    top[2] = target_name;
    top[3] = argdesc_;
    top[4] = 0;  // Result slot.

    Exit(thread, *FP, top + 5, *pc);
    NativeArguments native_args(thread, 3, /* argv */ top + 1,
                                /* result */ top + 4);
    if (!InvokeRuntime(thread, this, DRT_InterpretedInterfaceCallMissHandler,
                       native_args)) {
      return false;
    }

    target = static_cast<RawFunction*>(top[4]);
    target_name = static_cast<RawString*>(top[2]);
    argdesc_ = static_cast<RawArray*>(top[3]);
    ASSERT(target->IsFunction());
    lookup_cache_.Insert(receiver_cid, target_name, target);
  }

  top[0] = target;
  return Invoke(thread, call_base, top, pc, FP, SP);
}

DART_FORCE_INLINE bool Interpreter::InstanceCall1(Thread* thread,
                                                  RawICData* icdata,
                                                  RawObject** call_base,
                                                  RawObject** top,
                                                  uint32_t** pc,
                                                  RawObject*** FP,
                                                  RawObject*** SP,
                                                  bool optimized) {
  ASSERT(icdata->GetClassId() == kICDataCid);

  const intptr_t kCheckedArgs = 1;
  RawObject** args = call_base;
  RawArray* cache = icdata->ptr()->entries_->ptr();

  const intptr_t type_args_len =
      InterpreterHelpers::ArgDescTypeArgsLen(icdata->ptr()->args_descriptor_);
  const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
  RawSmi* receiver_cid =
      InterpreterHelpers::GetClassIdAsSmi(args[receiver_idx]);

  bool found = false;
  const intptr_t length = Smi::Value(cache->length_);
  intptr_t i;
  for (i = 0; i < (length - (kCheckedArgs + 2)); i += (kCheckedArgs + 2)) {
    if (cache->data()[i + 0] == receiver_cid) {
      top[0] = cache->data()[i + kCheckedArgs];
      found = true;
      break;
    }
  }

  argdesc_ = icdata->ptr()->args_descriptor_;

  if (found) {
    if (!optimized) {
      InterpreterHelpers::IncrementICUsageCount(cache->data(), i, kCheckedArgs);
    }
  } else {
    InlineCacheMiss(kCheckedArgs, thread, icdata, call_base + receiver_idx, top,
                    *pc, *FP, *SP);
  }

  return Invoke(thread, call_base, top, pc, FP, SP);
}

DART_FORCE_INLINE bool Interpreter::InstanceCall2(Thread* thread,
                                                  RawICData* icdata,
                                                  RawObject** call_base,
                                                  RawObject** top,
                                                  uint32_t** pc,
                                                  RawObject*** FP,
                                                  RawObject*** SP,
                                                  bool optimized) {
  ASSERT(icdata->GetClassId() == kICDataCid);

  const intptr_t kCheckedArgs = 2;
  RawObject** args = call_base;
  RawArray* cache = icdata->ptr()->entries_->ptr();

  const intptr_t type_args_len =
      InterpreterHelpers::ArgDescTypeArgsLen(icdata->ptr()->args_descriptor_);
  const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
  RawSmi* receiver_cid =
      InterpreterHelpers::GetClassIdAsSmi(args[receiver_idx]);
  RawSmi* arg0_cid =
      InterpreterHelpers::GetClassIdAsSmi(args[receiver_idx + 1]);

  bool found = false;
  const intptr_t length = Smi::Value(cache->length_);
  intptr_t i;
  for (i = 0; i < (length - (kCheckedArgs + 2)); i += (kCheckedArgs + 2)) {
    if ((cache->data()[i + 0] == receiver_cid) &&
        (cache->data()[i + 1] == arg0_cid)) {
      top[0] = cache->data()[i + kCheckedArgs];
      found = true;
      break;
    }
  }

  argdesc_ = icdata->ptr()->args_descriptor_;

  if (found) {
    if (!optimized) {
      InterpreterHelpers::IncrementICUsageCount(cache->data(), i, kCheckedArgs);
    }
  } else {
    InlineCacheMiss(kCheckedArgs, thread, icdata, call_base + receiver_idx, top,
                    *pc, *FP, *SP);
  }

  return Invoke(thread, call_base, top, pc, FP, SP);
}

// Note:
// All macro helpers are intended to be used only inside Interpreter::Call.

// Counts and prints executed bytecode instructions (in DEBUG mode).
#if defined(DEBUG)
#define TRACE_INSTRUCTION                                                      \
  if (IsTracingExecution()) {                                                  \
    TraceInstruction(pc - 1);                                                  \
  }                                                                            \
  if (IsWritingTraceFile()) {                                                  \
    WriteInstructionToTrace(pc - 1);                                           \
  }                                                                            \
  icount_++;
#else
#define TRACE_INSTRUCTION
#endif  // defined(DEBUG)

// Decode opcode and A part of the given value and dispatch to the
// corresponding bytecode handler.
#ifdef DART_HAS_COMPUTED_GOTO
#define DISPATCH_OP(val)                                                       \
  do {                                                                         \
    op = (val);                                                                \
    rA = ((op >> 8) & 0xFF);                                                   \
    TRACE_INSTRUCTION                                                          \
    goto* dispatch[op & 0xFF];                                                 \
  } while (0)
#else
#define DISPATCH_OP(val)                                                       \
  do {                                                                         \
    op = (val);                                                                \
    rA = ((op >> 8) & 0xFF);                                                   \
    TRACE_INSTRUCTION                                                          \
    goto SwitchDispatch;                                                       \
  } while (0)
#endif

// Fetch next operation from PC, increment program counter and dispatch.
#define DISPATCH() DISPATCH_OP(*pc++)

// Load target of a jump instruction into PC.
#define LOAD_JUMP_TARGET() pc += ((static_cast<int32_t>(op) >> 8) - 1)

// Define entry point that handles bytecode Name with the given operand format.
#define BYTECODE(Name, Operands)                                               \
  BYTECODE_HEADER(Name, DECLARE_##Operands, DECODE_##Operands)

#define BYTECODE_HEADER(Name, Declare, Decode)                                 \
  Declare;                                                                     \
  bc##Name : Decode

// Helpers to decode common instruction formats. Used in conjunction with
// BYTECODE() macro.
#define DECLARE_A_B_C                                                          \
  uint16_t rB, rC;                                                             \
  USE(rB);                                                                     \
  USE(rC)
#define DECODE_A_B_C                                                           \
  rB = ((op >> KernelBytecode::kBShift) & KernelBytecode::kBMask);             \
  rC = ((op >> KernelBytecode::kCShift) & KernelBytecode::kCMask);

#define DECLARE_A_B_Y                                                          \
  uint16_t rB;                                                                 \
  int8_t rY;                                                                   \
  USE(rB);                                                                     \
  USE(rY)
#define DECODE_A_B_Y                                                           \
  rB = ((op >> KernelBytecode::kBShift) & KernelBytecode::kBMask);             \
  rY = ((op >> KernelBytecode::kYShift) & KernelBytecode::kYMask);

#define DECLARE_0
#define DECODE_0

#define DECLARE_A
#define DECODE_A

#define DECLARE___D                                                            \
  uint32_t rD;                                                                 \
  USE(rD)
#define DECODE___D rD = (op >> KernelBytecode::kDShift);

#define DECLARE_A_D DECLARE___D
#define DECODE_A_D DECODE___D

#define DECLARE_A_X                                                            \
  int32_t rD;                                                                  \
  USE(rD)
#define DECODE_A_X rD = (static_cast<int32_t>(op) >> KernelBytecode::kDShift);


// Exception handling helper. Gets handler FP and PC from the Interpreter where
// they were stored by Interpreter::Longjmp and proceeds to execute the handler.
// Corner case: handler PC can be a fake marker that marks entry frame, which
// means exception was not handled in the Dart code. In this case we return
// caught exception from Interpreter::Call.
#if defined(DEBUG)

#define HANDLE_EXCEPTION                                                       \
  do {                                                                         \
    FP = fp_;                                                                  \
    pc = pc_;                                                                  \
    if (IsEntryFrameMarker(pc)) {                                              \
      pp_ = reinterpret_cast<RawObjectPool*>(fp_[kKBCSavedPpSlotFromEntryFp]); \
      argdesc_ =                                                               \
          reinterpret_cast<RawArray*>(fp_[kKBCSavedArgDescSlotFromEntryFp]);   \
      uword exit_fp =                                                          \
          reinterpret_cast<uword>(fp_[kKBCExitLinkSlotFromEntryFp]);           \
      thread->set_top_exit_frame_info(exit_fp);                                \
      thread->set_top_resource(top_resource);                                  \
      thread->set_vm_tag(vm_tag);                                              \
      if (IsTracingExecution()) {                                              \
        THR_Print("%" Pu64 " ", icount_);                                      \
        THR_Print("Returning exception from interpreter 0x%" Px                \
                  " at fp_ 0x%" Px " exit 0x%" Px "\n",                        \
                  reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_), \
                  exit_fp);                                                    \
      }                                                                        \
      ASSERT(HasFrame(reinterpret_cast<uword>(fp_)));                          \
      return special_[KernelBytecode::kExceptionSpecialIndex];                 \
    }                                                                          \
    goto DispatchAfterException;                                               \
  } while (0)

#else  // !defined(DEBUG)

#define HANDLE_EXCEPTION                                                       \
  do {                                                                         \
    FP = fp_;                                                                  \
    pc = pc_;                                                                  \
    if (IsEntryFrameMarker(pc)) {                                              \
      pp_ = reinterpret_cast<RawObjectPool*>(fp_[kKBCSavedPpSlotFromEntryFp]); \
      argdesc_ =                                                               \
          reinterpret_cast<RawArray*>(fp_[kKBCSavedArgDescSlotFromEntryFp]);   \
      uword exit_fp =                                                          \
          reinterpret_cast<uword>(fp_[kKBCExitLinkSlotFromEntryFp]);           \
      thread->set_top_exit_frame_info(exit_fp);                                \
      thread->set_top_resource(top_resource);                                  \
      thread->set_vm_tag(vm_tag);                                              \
      return special_[KernelBytecode::kExceptionSpecialIndex];                 \
    }                                                                          \
    goto DispatchAfterException;                                               \
  } while (0)

#endif  // !defined(DEBUG)

#define HANDLE_RETURN                                                          \
  do {                                                                         \
    pp_ = InterpreterHelpers::FrameBytecode(FP)->ptr()->object_pool_;          \
  } while (0)

// Runtime call helpers: handle invocation and potential exception after return.
#define INVOKE_RUNTIME(Func, Args)                                             \
  if (!InvokeRuntime(thread, this, Func, Args)) {                              \
    HANDLE_EXCEPTION;                                                          \
  } else {                                                                     \
    HANDLE_RETURN;                                                             \
  }

#define INVOKE_NATIVE(Wrapper, Func, Args)                                     \
  if (!InvokeNative(thread, this, Wrapper, Func, Args)) {                      \
    HANDLE_EXCEPTION;                                                          \
  } else {                                                                     \
    HANDLE_RETURN;                                                             \
  }

#define LOAD_CONSTANT(index) (pp_->ptr()->data()[(index)].raw_obj_)

#define UNBOX_INT64(value, obj, selector)                                      \
  int64_t value;                                                               \
  {                                                                            \
    word raw_value = reinterpret_cast<word>(obj);                              \
    if (LIKELY((raw_value & kSmiTagMask) == kSmiTag)) {                        \
      value = raw_value >> kSmiTagShift;                                       \
    } else {                                                                   \
      if (UNLIKELY(obj == null_value)) {                                       \
        SP[0] = selector.raw();                                                \
        goto ThrowNullError;                                                   \
      }                                                                        \
      value = Integer::GetInt64Value(RAW_CAST(Integer, obj));                  \
    }                                                                          \
  }

#define BOX_INT64_RESULT(result)                                               \
  if (LIKELY(Smi::IsValid(result))) {                                          \
    SP[0] = Smi::New(static_cast<intptr_t>(result));                           \
  } else if (!AllocateMint(thread, result, pc, FP, SP)) {                      \
    HANDLE_EXCEPTION;                                                          \
  }                                                                            \
  ASSERT(Integer::GetInt64Value(RAW_CAST(Integer, SP[0])) == result);

bool Interpreter::AssertAssignable(Thread* thread,
                                   uint32_t* pc,
                                   RawObject** FP,
                                   RawObject** call_top,
                                   RawObject** args,
                                   RawSubtypeTestCache* cache) {
  RawObject* null_value = Object::null();
  if (cache != null_value) {
    RawInstance* instance = static_cast<RawInstance*>(args[0]);
    RawTypeArguments* instantiator_type_arguments =
        static_cast<RawTypeArguments*>(args[2]);
    RawTypeArguments* function_type_arguments =
        static_cast<RawTypeArguments*>(args[3]);

    const intptr_t cid = InterpreterHelpers::GetClassId(instance);

    RawTypeArguments* instance_type_arguments =
        static_cast<RawTypeArguments*>(null_value);
    RawObject* instance_cid_or_function;

    RawTypeArguments* parent_function_type_arguments;
    RawTypeArguments* delayed_function_type_arguments;
    if (cid == kClosureCid) {
      RawClosure* closure = static_cast<RawClosure*>(instance);
      instance_type_arguments = closure->ptr()->instantiator_type_arguments_;
      parent_function_type_arguments = closure->ptr()->function_type_arguments_;
      delayed_function_type_arguments = closure->ptr()->delayed_type_arguments_;
      instance_cid_or_function = closure->ptr()->function_;
    } else {
      instance_cid_or_function = Smi::New(cid);

      RawClass* instance_class = thread->isolate()->class_table()->At(cid);
      if (instance_class->ptr()->num_type_arguments_ < 0) {
        goto AssertAssignableCallRuntime;
      } else if (instance_class->ptr()->num_type_arguments_ > 0) {
        instance_type_arguments = reinterpret_cast<RawTypeArguments**>(
            instance->ptr())[instance_class->ptr()
                                 ->type_arguments_field_offset_in_words_];
      }
      parent_function_type_arguments =
          static_cast<RawTypeArguments*>(null_value);
      delayed_function_type_arguments =
          static_cast<RawTypeArguments*>(null_value);
    }

    for (RawObject** entries = cache->ptr()->cache_->ptr()->data();
         entries[0] != null_value;
         entries += SubtypeTestCache::kTestEntryLength) {
      if ((entries[SubtypeTestCache::kInstanceClassIdOrFunction] ==
           instance_cid_or_function) &&
          (entries[SubtypeTestCache::kInstanceTypeArguments] ==
           instance_type_arguments) &&
          (entries[SubtypeTestCache::kInstantiatorTypeArguments] ==
           instantiator_type_arguments) &&
          (entries[SubtypeTestCache::kFunctionTypeArguments] ==
           function_type_arguments) &&
          (entries[SubtypeTestCache::kInstanceParentFunctionTypeArguments] ==
           parent_function_type_arguments) &&
          (entries[SubtypeTestCache::kInstanceDelayedFunctionTypeArguments] ==
           delayed_function_type_arguments)) {
        if (Bool::True().raw() == entries[SubtypeTestCache::kTestResult]) {
          return true;
        } else {
          break;
        }
      }
    }
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

RawObject* Interpreter::Call(const Function& function,
                             const Array& arguments_descriptor,
                             const Array& arguments,
                             Thread* thread) {
  return Call(function.raw(), arguments_descriptor.raw(), arguments.Length(),
              arguments.raw_ptr()->data(), thread);
}

// Allocate a _Mint for the given int64_t value and puts it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateMint(Thread* thread,
                                             int64_t value,
                                             uint32_t* pc,
                                             RawObject** FP,
                                             RawObject** SP) {
  ASSERT(!Smi::IsValid(value));
  const intptr_t instance_size = Mint::InstanceSize();
  const uword start = thread->top();
  if (LIKELY((start + instance_size) < thread->end())) {
    thread->set_top(start + instance_size);
    RawMint* result =
        Mint::RawCast(InitializeHeader(start, kMintCid, instance_size));
    result->ptr()->value_ = value;
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate()->object_store()->mint_class();  // Class object.
    SP[2] = Object::null();                                  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    reinterpret_cast<RawMint*>(SP[0])->ptr()->value_ = value;
    return true;
  }
}

// Allocate a _Double for the given double value and put it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateDouble(Thread* thread,
                                               double value,
                                               uint32_t* pc,
                                               RawObject** FP,
                                               RawObject** SP) {
  const intptr_t instance_size = Double::InstanceSize();
  const uword start = thread->top();
  if (LIKELY((start + instance_size) < thread->end())) {
    thread->set_top(start + instance_size);
    RawDouble* result =
        Double::RawCast(InitializeHeader(start, kDoubleCid, instance_size));
    result->ptr()->value_ = value;
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate()->object_store()->double_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    Double::RawCast(SP[0])->ptr()->value_ = value;
    return true;
  }
}

// Allocate a _Float32x4 for the given simd value and put it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateFloat32x4(Thread* thread,
                                                  simd128_value_t value,
                                                  uint32_t* pc,
                                                  RawObject** FP,
                                                  RawObject** SP) {
  const intptr_t instance_size = Float32x4::InstanceSize();
  const uword start = thread->top();
  if (LIKELY((start + instance_size) < thread->end())) {
    thread->set_top(start + instance_size);
    RawFloat32x4* result = Float32x4::RawCast(
        InitializeHeader(start, kFloat32x4Cid, instance_size));
    value.writeTo(result->ptr()->value_);
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate()->object_store()->float32x4_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    value.writeTo(Float32x4::RawCast(SP[0])->ptr()->value_);
    return true;
  }
}

// Allocate _Float64x2 box for the given simd value and put it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateFloat64x2(Thread* thread,
                                                  simd128_value_t value,
                                                  uint32_t* pc,
                                                  RawObject** FP,
                                                  RawObject** SP) {
  const intptr_t instance_size = Float64x2::InstanceSize();
  const uword start = thread->top();
  if (LIKELY((start + instance_size) < thread->end())) {
    thread->set_top(start + instance_size);
    RawFloat64x2* result = Float64x2::RawCast(
        InitializeHeader(start, kFloat64x2Cid, instance_size));
    value.writeTo(result->ptr()->value_);
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate()->object_store()->float64x2_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    if (!InvokeRuntime(thread, this, DRT_AllocateObject, args)) {
      return false;
    }
    value.writeTo(Float64x2::RawCast(SP[0])->ptr()->value_);
    return true;
  }
}

// Allocate a _List with the given type arguments and length and put it into
// SP[0]. Returns false on exception.
bool Interpreter::AllocateArray(Thread* thread,
                                RawTypeArguments* type_args,
                                RawObject* length_object,
                                uint32_t* pc,
                                RawObject** FP,
                                RawObject** SP) {
  if (LIKELY(!length_object->IsHeapObject())) {
    const intptr_t length = Smi::Value(Smi::RawCast(length_object));
    if (LIKELY((0 <= length) && (length <= Array::kMaxElements))) {
      const intptr_t instance_size = Array::InstanceSize(length);
      const uword start = thread->top();
      if (LIKELY((start + instance_size) < thread->end())) {
        thread->set_top(start + instance_size);
        RawArray* result =
            Array::RawCast(InitializeHeader(start, kArrayCid, instance_size));
        result->ptr()->type_arguments_ = type_args;
        result->ptr()->length_ = Smi::New(length);
        for (intptr_t i = 0; i < length; i++) {
          result->ptr()->data()[i] = Object::null();
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

// Allocate a _Context with the given length and put it into SP[0].
// Returns false on exception.
bool Interpreter::AllocateContext(Thread* thread,
                                  intptr_t num_context_variables,
                                  uint32_t* pc,
                                  RawObject** FP,
                                  RawObject** SP) {
  const intptr_t instance_size = Context::InstanceSize(num_context_variables);
  ASSERT(Utils::IsAligned(instance_size, kObjectAlignment));
  const uword start = thread->top();
  if (LIKELY((start + instance_size) < thread->end())) {
    thread->set_top(start + instance_size);
    RawContext* result =
        Context::RawCast(InitializeHeader(start, kContextCid, instance_size));
    result->ptr()->num_variables_ = num_context_variables;
    RawObject* null_value = Object::null();
    result->ptr()->parent_ = static_cast<RawContext*>(null_value);
    for (intptr_t offset = sizeof(RawContext); offset < instance_size;
         offset += kWordSize) {
      *reinterpret_cast<RawObject**>(start + offset) = null_value;
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
                                  uint32_t* pc,
                                  RawObject** FP,
                                  RawObject** SP) {
  const intptr_t instance_size = Closure::InstanceSize();
  const uword start = thread->top();
  if (LIKELY((start + instance_size) < thread->end())) {
    thread->set_top(start + instance_size);
    RawClosure* result =
        Closure::RawCast(InitializeHeader(start, kClosureCid, instance_size));
    RawObject* null_value = Object::null();
    for (intptr_t offset = sizeof(RawInstance); offset < instance_size;
         offset += kWordSize) {
      *reinterpret_cast<RawObject**>(start + offset) = null_value;
    }
    SP[0] = result;
    return true;
  } else {
    SP[0] = 0;  // Space for the result.
    SP[1] = thread->isolate()->object_store()->closure_class();
    SP[2] = Object::null();  // Type arguments.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP);
    return InvokeRuntime(thread, this, DRT_AllocateObject, args);
  }
}

RawObject* Interpreter::Call(RawFunction* function,
                             RawArray* argdesc,
                             intptr_t argc,
                             RawObject* const* argv,
                             Thread* thread) {
  // Interpreter state (see constants_kbc.h for high-level overview).
  uint32_t* pc;    // Program Counter: points to the next op to execute.
  RawObject** FP;  // Frame Pointer.
  RawObject** SP;  // Stack Pointer.

  uint32_t op;  // Currently executing op.
  uint16_t rA;  // A component of the currently executing op.

  bool reentering = fp_ != NULL;
  if (!reentering) {
    fp_ = reinterpret_cast<RawObject**>(stack_base_);
  }
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("%s interpreter 0x%" Px " at fp_ 0x%" Px " exit 0x%" Px " %s\n",
              reentering ? "Re-entering" : "Entering",
              reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
              thread->top_exit_frame_info(),
              Function::Handle(function).ToCString());
  }
#endif

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
  // A negative argc indicates reverse memory order of arguments.
  const intptr_t arg_count = argc < 0 ? -argc : argc;
  FP = fp_ + kKBCEntrySavedSlots + arg_count + kKBCDartFrameFixedSize;
  SP = FP - 1;

  // Save outer top_exit_frame_info, current argdesc, and current pp.
  fp_[kKBCExitLinkSlotFromEntryFp] =
      reinterpret_cast<RawObject*>(thread->top_exit_frame_info());
  thread->set_top_exit_frame_info(0);
  fp_[kKBCSavedArgDescSlotFromEntryFp] = reinterpret_cast<RawObject*>(argdesc_);
  fp_[kKBCSavedPpSlotFromEntryFp] = reinterpret_cast<RawObject*>(pp_);

  // Copy arguments and setup the Dart frame.
  for (intptr_t i = 0; i < arg_count; i++) {
    fp_[kKBCEntrySavedSlots + i] = argv[argc < 0 ? -i : i];
  }

  RawBytecode* bytecode = function->ptr()->bytecode_;
  FP[kKBCFunctionSlotFromFp] = function;
  FP[kKBCPcMarkerSlotFromFp] = bytecode;
  FP[kKBCSavedCallerPcSlotFromFp] =
      reinterpret_cast<RawObject*>((arg_count << 2) | 2);
  FP[kKBCSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(fp_);

  // Load argument descriptor.
  argdesc_ = argdesc;

  // Ready to start executing bytecode. Load entry point and corresponding
  // object pool.
  pc = reinterpret_cast<uint32_t*>(bytecode->ptr()->instructions_);
  NOT_IN_PRODUCT(pc_ = pc);  // For the profiler.
  NOT_IN_PRODUCT(fp_ = FP);  // For the profiler.
  pp_ = bytecode->ptr()->object_pool_;

  // Save current VM tag and mark thread as executing Dart code. For the
  // profiler, do this *after* setting up the entry frame (compare the machine
  // code entry stubs).
  const uword vm_tag = thread->vm_tag();
  thread->set_vm_tag(VMTag::kDartInterpretedTagId);

  // Save current top stack resource and reset the list.
  StackResource* top_resource = thread->top_resource();
  thread->set_top_resource(NULL);

  // Cache some frequently used values in the frame.
  RawBool* true_value = Bool::True().raw();
  RawBool* false_value = Bool::False().raw();
  RawObject* null_value = Object::null();

#if defined(DEBUG)
  Function& function_h = Function::Handle();
#endif

#ifdef DART_HAS_COMPUTED_GOTO
  static const void* dispatch[] = {
#define TARGET(name, fmt, fmta, fmtb, fmtc) &&bc##name,
      KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
  };
  DISPATCH();  // Enter the dispatch loop.
#else
  DISPATCH();  // Enter the dispatch loop.
SwitchDispatch:
  switch (op & 0xFF) {
#define TARGET(name, fmt, fmta, fmtb, fmtc)                                    \
  case KernelBytecode::k##name:                                                \
    goto bc##name;
    KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
    default:
      FATAL1("Undefined opcode: %d\n", op);
  }
#endif

  // KernelBytecode handlers (see constants_kbc.h for bytecode descriptions).
  {
    BYTECODE(Entry, A_D);
    const uint16_t num_locals = rD;

    // Initialize locals with null & set SP.
    for (intptr_t i = 0; i < num_locals; i++) {
      FP[i] = null_value;
    }
    SP = FP + num_locals - 1;

    DISPATCH();
  }

  {
    BYTECODE(EntryFixed, A_D);
    const uint16_t num_fixed_params = rA;
    const uint16_t num_locals = rD;

    const intptr_t arg_count = InterpreterHelpers::ArgDescArgCount(argdesc_);
    const intptr_t pos_count = InterpreterHelpers::ArgDescPosCount(argdesc_);
    if ((arg_count != num_fixed_params) || (pos_count != num_fixed_params)) {
      goto ClosureNoSuchMethod;
    }

    // Initialize locals with null & set SP.
    for (intptr_t i = 0; i < num_locals; i++) {
      FP[i] = null_value;
    }
    SP = FP + num_locals - 1;

    DISPATCH();
  }

  {
    BYTECODE(EntryOptional, A_B_C);
    const uint16_t num_fixed_params = rA;
    const uint16_t num_opt_pos_params = rB;
    const uint16_t num_opt_named_params = rC;
    const intptr_t min_num_pos_args = num_fixed_params;
    const intptr_t max_num_pos_args = num_fixed_params + num_opt_pos_params;

    // Decode arguments descriptor.
    const intptr_t arg_count = InterpreterHelpers::ArgDescArgCount(argdesc_);
    const intptr_t pos_count = InterpreterHelpers::ArgDescPosCount(argdesc_);
    const intptr_t named_count = (arg_count - pos_count);

    // Check that got the right number of positional parameters.
    if ((min_num_pos_args > pos_count) || (pos_count > max_num_pos_args)) {
      goto ClosureNoSuchMethod;
    }

    // Copy all passed position arguments.
    RawObject** first_arg = FrameArguments(FP, arg_count);
    memmove(FP, first_arg, pos_count * kWordSize);

    if (num_opt_named_params != 0) {
      // This is a function with named parameters.
      // Walk the list of named parameters and their
      // default values encoded as pairs of LoadConstant instructions that
      // follows the entry point and find matching values via arguments
      // descriptor.
      RawObject** argdesc_data = argdesc_->ptr()->data();

      intptr_t i = named_count - 1;           // argument position
      intptr_t j = num_opt_named_params - 1;  // parameter position
      while ((j >= 0) && (i >= 0)) {
        // Fetch formal parameter information: name, default value, target slot.
        const uint32_t load_name = pc[2 * j];
        const uint32_t load_value = pc[2 * j + 1];
        ASSERT(KernelBytecode::DecodeOpcode(load_name) ==
               KernelBytecode::kLoadConstant);
        ASSERT(KernelBytecode::DecodeOpcode(load_value) ==
               KernelBytecode::kLoadConstant);
        const uint8_t reg = KernelBytecode::DecodeA(load_name);
        ASSERT(reg == KernelBytecode::DecodeA(load_value));

        RawString* name = static_cast<RawString*>(
            LOAD_CONSTANT(KernelBytecode::DecodeD(load_name)));
        if (name == argdesc_data[ArgumentsDescriptor::name_index(i)]) {
          // Parameter was passed. Fetch passed value.
          const intptr_t arg_index = Smi::Value(static_cast<RawSmi*>(
              argdesc_data[ArgumentsDescriptor::position_index(i)]));
          FP[reg] = first_arg[arg_index];
          i--;  // Consume passed argument.
        } else {
          // Parameter was not passed. Fetch default value.
          FP[reg] = LOAD_CONSTANT(KernelBytecode::DecodeD(load_value));
        }
        j--;  // Next formal parameter.
      }

      // If we have unprocessed formal parameters then initialize them all
      // using default values.
      while (j >= 0) {
        const uint32_t load_name = pc[2 * j];
        const uint32_t load_value = pc[2 * j + 1];
        ASSERT(KernelBytecode::DecodeOpcode(load_name) ==
               KernelBytecode::kLoadConstant);
        ASSERT(KernelBytecode::DecodeOpcode(load_value) ==
               KernelBytecode::kLoadConstant);
        const uint8_t reg = KernelBytecode::DecodeA(load_name);
        ASSERT(reg == KernelBytecode::DecodeA(load_value));

        FP[reg] = LOAD_CONSTANT(KernelBytecode::DecodeD(load_value));
        j--;
      }

      // If we have unprocessed passed arguments that means we have mismatch
      // between formal parameters and concrete arguments. This can only
      // occur if the current function is a closure.
      if (i != -1) {
        goto ClosureNoSuchMethod;
      }

      // Skip LoadConstant-s encoding information about named parameters.
      pc += num_opt_named_params * 2;

      // SP points past copied arguments.
      SP = FP + num_fixed_params + num_opt_named_params - 1;
    } else {
      ASSERT(num_opt_pos_params != 0);
      if (named_count != 0) {
        // Function can't have both named and optional positional parameters.
        // This kind of mismatch can only occur if the current function
        // is a closure.
        goto ClosureNoSuchMethod;
      }

      // Process the list of default values encoded as a sequence of
      // LoadConstant instructions after EntryOpt bytecode.
      // Execute only those that correspond to parameters that were not passed.
      for (intptr_t i = pos_count - num_fixed_params; i < num_opt_pos_params;
           i++) {
        const uint32_t load_value = pc[i];
        ASSERT(KernelBytecode::DecodeOpcode(load_value) ==
               KernelBytecode::kLoadConstant);
#if defined(DEBUG)
        const uint8_t reg = KernelBytecode::DecodeA(load_value);
        ASSERT((num_fixed_params + i) == reg);
#endif
        FP[num_fixed_params + i] =
            LOAD_CONSTANT(KernelBytecode::DecodeD(load_value));
      }

      // Skip LoadConstant-s encoding default values for optional positional
      // parameters.
      pc += num_opt_pos_params;

      // SP points past the last copied parameter.
      SP = FP + max_num_pos_args - 1;
    }

    DISPATCH();
  }

  {
    BYTECODE(Frame, A_D);
    // Initialize locals with null and increment SP.
    const uint16_t num_locals = rD;
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
          thread->HasScheduledInterrupts()) {
        Exit(thread, FP, SP + 1, pc);
        NativeArguments args(thread, 0, NULL, NULL);
        INVOKE_RUNTIME(DRT_StackOverflow, args);
      }
    }
    RawFunction* function = FrameFunction(FP);
    int32_t counter = ++(function->ptr()->usage_counter_);
    if (UNLIKELY(FLAG_compilation_counter_threshold >= 0 &&
                 counter >= FLAG_compilation_counter_threshold &&
                 !Function::HasCode(function))) {
      SP[1] = 0;  // Unused code result.
      SP[2] = function;
      Exit(thread, FP, SP + 3, pc);
      NativeArguments native_args(thread, 1, SP + 2, SP + 1);
      INVOKE_RUNTIME(DRT_OptimizeInvokedFunction, native_args);
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckFunctionTypeArgs, A_D);
    const uint16_t declared_type_args_len = rA;
    const uint16_t first_stack_local_index = rD;

    // Decode arguments descriptor's type args len.
    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    if ((type_args_len != declared_type_args_len) && (type_args_len != 0)) {
      goto ClosureNoSuchMethod;
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
    BYTECODE(InstantiateType, A_D);
    // Stack: instantiator type args, function type args
    RawObject* type = LOAD_CONSTANT(rD);
    SP[1] = type;
    SP[2] = SP[-1];
    SP[3] = SP[0];
    Exit(thread, FP, SP + 4, pc);
    {
      NativeArguments args(thread, 3, SP + 1, SP - 1);
      INVOKE_RUNTIME(DRT_InstantiateType, args);
    }
    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(InstantiateTypeArgumentsTOS, A_D);
    // Stack: instantiator type args, function type args
    RawTypeArguments* type_arguments =
        static_cast<RawTypeArguments*>(LOAD_CONSTANT(rD));

    RawObject* instantiator_type_args = SP[-1];
    RawObject* function_type_args = SP[0];
    // If both instantiators are null and if the type argument vector
    // instantiated from null becomes a vector of dynamic, then use null as
    // the type arguments.
    if ((rA == 0) || (null_value != instantiator_type_args) ||
        (null_value != function_type_args)) {
      // First lookup in the cache.
      RawArray* instantiations = type_arguments->ptr()->instantiations_;
      for (intptr_t i = 0;
           instantiations->ptr()->data()[i] != NULL;  // kNoInstantiator
           i += 3) {  // kInstantiationSizeInWords
        if ((instantiations->ptr()->data()[i] == instantiator_type_args) &&
            (instantiations->ptr()->data()[i + 1] == function_type_args)) {
          // Found in the cache.
          SP[-1] = instantiations->ptr()->data()[i + 2];
          goto InstantiateTypeArgumentsTOSDone;
        }
      }

      // Cache lookup failed, call runtime.
      SP[1] = type_arguments;
      SP[2] = instantiator_type_args;
      SP[3] = function_type_args;

      Exit(thread, FP, SP + 4, pc);
      NativeArguments args(thread, 3, SP + 1, SP - 1);
      INVOKE_RUNTIME(DRT_InstantiateTypeArguments, args);
    }

  InstantiateTypeArgumentsTOSDone:
    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(Throw, A);
    {
      SP[1] = 0;  // Space for result.
      Exit(thread, FP, SP + 2, pc);
      if (rA == 0) {  // Throw
        NativeArguments args(thread, 1, SP, SP + 1);
        INVOKE_RUNTIME(DRT_Throw, args);
      } else {  // ReThrow
        NativeArguments args(thread, 2, SP - 1, SP + 1);
        INVOKE_RUNTIME(DRT_ReThrow, args);
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
    BYTECODE(LoadConstant, A_D);
    FP[rA] = LOAD_CONSTANT(rD);
    DISPATCH();
  }

  {
    BYTECODE(PushConstant, __D);
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
    BYTECODE(PushInt, A_X);
    *++SP = Smi::New(rD);
    DISPATCH();
  }

  {
    BYTECODE(Push, A_X);
    *++SP = FP[rD];
    DISPATCH();
  }

  {
    BYTECODE(StoreLocal, A_X);
    FP[rD] = *SP;
    DISPATCH();
  }

  {
    BYTECODE(PopLocal, A_X);
    FP[rD] = *SP--;
    DISPATCH();
  }

  {
    BYTECODE(MoveSpecial, A_X);
    ASSERT(rA < KernelBytecode::kSpecialIndexCount);
    FP[rD] = special_[rA];
    DISPATCH();
  }

  {
    BYTECODE(BooleanNegateTOS, 0);
    SP[0] = (SP[0] == true_value) ? false_value : true_value;
    DISPATCH();
  }

  {
    BYTECODE(IndirectStaticCall, A_D);

#ifndef PRODUCT
    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }
#endif  // !PRODUCT

    // Invoke target function.
    {
      const uint16_t argc = rA;
      // Look up the function in the ICData.
      RawObject* ic_data_obj = SP[0];
      RawICData* ic_data = RAW_CAST(ICData, ic_data_obj);
      RawObject** data = ic_data->ptr()->entries_->ptr()->data();
      InterpreterHelpers::IncrementICUsageCount(data, 0, 0);
      SP[0] = data[ICData::TargetIndexFor(ic_data->ptr()->state_bits_ & 0x3)];
      RawObject** call_base = SP - argc;
      RawObject** call_top = SP;  // *SP contains function
      argdesc_ = static_cast<RawArray*>(LOAD_CONSTANT(rD));
      if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
        HANDLE_EXCEPTION;
      }
    }

    DISPATCH();
  }

  {
    BYTECODE(DirectCall, A_D);

#ifndef PRODUCT
    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }
#endif  // !PRODUCT

    // Invoke target function.
    {
      const uint16_t argc = rA;
      const uint16_t kidx = rD;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      *++SP = LOAD_CONSTANT(kidx);
      RawObject** call_base = SP - argc;
      RawObject** call_top = SP;
      argdesc_ = static_cast<RawArray*>(LOAD_CONSTANT(kidx + 1));
      if (!Invoke(thread, call_base, call_top, &pc, &FP, &SP)) {
        HANDLE_EXCEPTION;
      }
    }

    DISPATCH();
  }

  {
    BYTECODE(InterfaceCall, A_D);

#ifndef PRODUCT
    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }
#endif  // !PRODUCT

    {
      const uint16_t argc = rA;
      const uint16_t kidx = rD;

      RawObject** call_base = SP - argc + 1;
      RawObject** call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      RawString* target_name =
          static_cast<RawFunction*>(LOAD_CONSTANT(kidx))->ptr()->name_;
      argdesc_ = static_cast<RawArray*>(LOAD_CONSTANT(kidx + 1));
      if (!InterfaceCall(thread, target_name, call_base, call_top, &pc, &FP,
                         &SP)) {
        HANDLE_EXCEPTION;
      }
    }

    DISPATCH();
  }

  {
    BYTECODE(UncheckedInterfaceCall, A_D);

#ifndef PRODUCT
    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }
#endif  // !PRODUCT

    {
      const uint16_t argc = rA;
      const uint16_t kidx = rD;

      RawObject** call_base = SP - argc + 1;
      RawObject** call_top = SP + 1;

      InterpreterHelpers::IncrementUsageCounter(FrameFunction(FP));
      RawString* target_name =
          static_cast<RawFunction*>(LOAD_CONSTANT(kidx))->ptr()->name_;
      argdesc_ = static_cast<RawArray*>(LOAD_CONSTANT(kidx + 1));
      if (!InterfaceCall(thread, target_name, call_base, call_top, &pc, &FP,
                         &SP)) {
        HANDLE_EXCEPTION;
      }
    }

    DISPATCH();
  }

  {
    BYTECODE(DynamicCall, A_D);

#ifndef PRODUCT
    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }
#endif  // !PRODUCT

    {
      const uint16_t argc = rA;
      const uint16_t kidx = rD;

      RawObject** call_base = SP - argc + 1;
      RawObject** call_top = SP + 1;

      RawICData* icdata = RAW_CAST(ICData, LOAD_CONSTANT(kidx));
      InterpreterHelpers::IncrementUsageCounter(
          RAW_CAST(Function, icdata->ptr()->owner_));
      if (ICData::NumArgsTestedBits::decode(icdata->ptr()->state_bits_) == 1) {
        if (!InstanceCall1(thread, icdata, call_base, call_top, &pc, &FP, &SP,
                           false /* optimized */)) {
          HANDLE_EXCEPTION;
        }
      } else {
        ASSERT(ICData::NumArgsTestedBits::decode(icdata->ptr()->state_bits_) ==
               2);
        if (!InstanceCall2(thread, icdata, call_base, call_top, &pc, &FP, &SP,
                           false /* optimized */)) {
          HANDLE_EXCEPTION;
        }
      }
    }

    DISPATCH();
  }

  {
    BYTECODE(NativeCall, __D);
    RawTypedData* data = static_cast<RawTypedData*>(LOAD_CONSTANT(rD));
    MethodRecognizer::Kind kind = NativeEntryData::GetKind(data);
    switch (kind) {
      case MethodRecognizer::kObjectEquals: {
        SP[-1] = SP[-1] == SP[0] ? Bool::True().raw() : Bool::False().raw();
        SP--;
      } break;
      case MethodRecognizer::kStringBaseLength:
      case MethodRecognizer::kStringBaseIsEmpty: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[String::length_offset() / kWordSize];
        if (kind == MethodRecognizer::kStringBaseIsEmpty) {
          SP[0] =
              SP[0] == Smi::New(0) ? Bool::True().raw() : Bool::False().raw();
        }
      } break;
      case MethodRecognizer::kGrowableArrayLength: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[GrowableObjectArray::length_offset() / kWordSize];
      } break;
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[Array::length_offset() / kWordSize];
      } break;
      case MethodRecognizer::kTypedListLength:
      case MethodRecognizer::kTypedListViewLength:
      case MethodRecognizer::kByteDataViewLength: {
        RawInstance* instance = reinterpret_cast<RawTypedDataBase*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[TypedDataBase::length_offset() / kWordSize];
      } break;
      case MethodRecognizer::kClassIDgetID: {
        SP[0] = InterpreterHelpers::GetClassIdAsSmi(SP[0]);
      } break;
      case MethodRecognizer::kGrowableArrayCapacity: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        instance = reinterpret_cast<RawInstance**>(
            instance->ptr())[GrowableObjectArray::data_offset() / kWordSize];
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[Array::length_offset() / kWordSize];
      } break;
      case MethodRecognizer::kListFactory: {
        // factory List<E>([int length]) {
        //   return (:arg_desc.positional_count == 2) ? new _List<E>(length)
        //                                            : new _GrowableList<E>(0);
        // }
        if (InterpreterHelpers::ArgDescPosCount(argdesc_) == 2) {
          RawTypeArguments* type_args = TypeArguments::RawCast(SP[-1]);
          RawObject* length = SP[0];
          SP--;
          if (!AllocateArray(thread, type_args, length, pc, FP, SP)) {
            HANDLE_EXCEPTION;
          }
        } else {
          ASSERT(InterpreterHelpers::ArgDescPosCount(argdesc_) == 1);
          // SP[-1] is type.
          // The native wrapper pushed null as the optional length argument.
          ASSERT(SP[0] == null_value);
          SP[0] = Smi::New(0);  // Patch null length with zero length.
          SP[1] = thread->isolate()->object_store()->growable_list_factory();
          // Change the ArgumentsDescriptor of the call with a new cached one.
          argdesc_ = ArgumentsDescriptor::New(
              0, KernelBytecode::kNativeCallToGrowableListArgc);
          // Note the special handling of the return of this call in DecodeArgc.
          if (!Invoke(thread, SP - 1, SP + 1, &pc, &FP, &SP)) {
            HANDLE_EXCEPTION;
          }
        }
      } break;
      case MethodRecognizer::kObjectArrayAllocate: {
        RawTypeArguments* type_args = TypeArguments::RawCast(SP[-1]);
        RawObject* length = SP[0];
        SP--;
        if (!AllocateArray(thread, type_args, length, pc, FP, SP)) {
          HANDLE_EXCEPTION;
        }
      } break;
      case MethodRecognizer::kLinkedHashMap_getIndex: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::index_offset() / kWordSize];
      } break;
      case MethodRecognizer::kLinkedHashMap_setIndex: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
        instance->StorePointer(reinterpret_cast<RawObject**>(instance->ptr()) +
                                   LinkedHashMap::index_offset() / kWordSize,
                               SP[0]);
        *--SP = null_value;
      } break;
      case MethodRecognizer::kLinkedHashMap_getData: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::data_offset() / kWordSize];
      } break;
      case MethodRecognizer::kLinkedHashMap_setData: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
        instance->StorePointer(reinterpret_cast<RawObject**>(instance->ptr()) +
                                   LinkedHashMap::data_offset() / kWordSize,
                               SP[0]);
        *--SP = null_value;
      } break;
      case MethodRecognizer::kLinkedHashMap_getHashMask: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::hash_mask_offset() / kWordSize];
      } break;
      case MethodRecognizer::kLinkedHashMap_setHashMask: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
        ASSERT(!SP[0]->IsHeapObject());
        reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::hash_mask_offset() / kWordSize] =
            SP[0];
        *--SP = null_value;
      } break;
      case MethodRecognizer::kLinkedHashMap_getUsedData: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::used_data_offset() / kWordSize];
      } break;
      case MethodRecognizer::kLinkedHashMap_setUsedData: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
        ASSERT(!SP[0]->IsHeapObject());
        reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::used_data_offset() / kWordSize] =
            SP[0];
        *--SP = null_value;
      } break;
      case MethodRecognizer::kLinkedHashMap_getDeletedKeys: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::deleted_keys_offset() / kWordSize];
      } break;
      case MethodRecognizer::kLinkedHashMap_setDeletedKeys: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
        ASSERT(!SP[0]->IsHeapObject());
        reinterpret_cast<RawObject**>(
            instance->ptr())[LinkedHashMap::deleted_keys_offset() / kWordSize] =
            SP[0];
        *--SP = null_value;
      } break;
      default: {
        NativeEntryData::Payload* payload =
            NativeEntryData::FromTypedArray(data);
        intptr_t argc_tag = NativeEntryData::GetArgcTag(data);
        const intptr_t num_arguments =
            NativeArguments::ArgcBits::decode(argc_tag);

        if (payload->trampoline == NULL) {
          ASSERT(payload->native_function == NULL);
          payload->trampoline = &NativeEntry::BootstrapNativeCallWrapper;
          payload->native_function =
              reinterpret_cast<NativeFunction>(&NativeEntry::LinkNativeCall);
        }

        *++SP = null_value;  // Result slot.

        RawObject** incoming_args = SP - num_arguments;
        RawObject** return_slot = SP;
        Exit(thread, FP, SP + 1, pc);
        NativeArguments args(thread, argc_tag, incoming_args, return_slot);
        INVOKE_NATIVE(
            payload->trampoline,
            reinterpret_cast<Dart_NativeFunction>(payload->native_function),
            reinterpret_cast<Dart_NativeArguments>(&args));

        *(SP - num_arguments) = *return_slot;
        SP -= num_arguments;
      }
    }
    DISPATCH();
  }

  {
    RawObject* result;  // result to return to the caller.

    BYTECODE(ReturnTOS, 0);
    result = *SP;
    // Restore caller PC.
    pc = SavedCallerPC(FP);

    // Check if it is a fake PC marking the entry frame.
    if (IsEntryFrameMarker(pc)) {
      // Pop entry frame.
      RawObject** entry_fp = SavedCallerFP(FP);
      // Restore exit frame info saved in entry frame.
      pp_ = reinterpret_cast<RawObjectPool*>(
          entry_fp[kKBCSavedPpSlotFromEntryFp]);
      argdesc_ = reinterpret_cast<RawArray*>(
          entry_fp[kKBCSavedArgDescSlotFromEntryFp]);
      uword exit_fp =
          reinterpret_cast<uword>(entry_fp[kKBCExitLinkSlotFromEntryFp]);
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
      const intptr_t argc = reinterpret_cast<uword>(pc) >> 2;
      ASSERT(fp_ == FrameArguments(FP, argc + kKBCEntrySavedSlots));
      // Exception propagation should have been done.
      ASSERT(!result->IsHeapObject() ||
             result->GetClassId() != kUnhandledExceptionCid);
#endif
      return result;
    }

    // Look at the caller to determine how many arguments to pop.
    const uint8_t argc = KernelBytecode::DecodeArgc(pc[-1]);

    // Restore SP, FP and PP. Push result and dispatch.
    SP = FrameArguments(FP, argc);
    FP = SavedCallerFP(FP);
    NOT_IN_PRODUCT(fp_ = FP);  // For the profiler.
    NOT_IN_PRODUCT(pc_ = pc);  // For the profiler.
    pp_ = InterpreterHelpers::FrameBytecode(FP)->ptr()->object_pool_;
    *SP = result;
    DISPATCH();
  }

  {
    BYTECODE(StoreStaticTOS, A_D);
    RawField* field = reinterpret_cast<RawField*>(LOAD_CONSTANT(rD));
    RawInstance* value = static_cast<RawInstance*>(*SP--);
    field->StorePointer(&field->ptr()->value_.static_value_, value, thread);
    DISPATCH();
  }

  {
    BYTECODE(PushStatic, A_D);
    RawField* field = reinterpret_cast<RawField*>(LOAD_CONSTANT(rD));
    // Note: field is also on the stack, hence no increment.
    *SP = field->ptr()->value_.static_value_;
    DISPATCH();
  }

  {
    BYTECODE(StoreFieldTOS, __D);
    RawField* field = RAW_CAST(Field, LOAD_CONSTANT(rD + 1));
    RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
    RawObject* value = reinterpret_cast<RawObject*>(SP[0]);
    intptr_t offset_in_words = Smi::Value(field->ptr()->value_.offset_);

    if (InterpreterHelpers::FieldNeedsGuardUpdate(field, value)) {
      SP[1] = 0;  // Unused result of runtime call.
      SP[2] = field;
      SP[3] = value;
      Exit(thread, FP, SP + 4, pc);
      NativeArguments args(thread, 2, /* argv */ SP + 2, /* retval */ SP + 1);
      if (!InvokeRuntime(thread, this, DRT_UpdateFieldCid, args)) {
        HANDLE_EXCEPTION;
      }

      // Reload objects after the call which may trigger GC.
      field = RAW_CAST(Field, LOAD_CONSTANT(rD + 1));
      instance = reinterpret_cast<RawInstance*>(SP[-1]);
      value = SP[0];
    }

    const bool unboxing =
        (field->ptr()->is_nullable_ != kNullCid) &&
        Field::UnboxingCandidateBit::decode(field->ptr()->kind_bits_);
    classid_t guarded_cid = field->ptr()->guarded_cid_;
    if (unboxing && (guarded_cid == kDoubleCid)) {
      double raw_value = Double::RawCast(value)->ptr()->value_;
      ASSERT(*(reinterpret_cast<RawDouble**>(instance->ptr()) +
               offset_in_words) == null_value);  // Initializing store.
      if (!AllocateDouble(thread, raw_value, pc, FP, SP)) {
        HANDLE_EXCEPTION;
      }
      RawDouble* box = Double::RawCast(SP[0]);
      instance = reinterpret_cast<RawInstance*>(SP[-1]);
      instance->StorePointer(
          reinterpret_cast<RawDouble**>(instance->ptr()) + offset_in_words, box,
          thread);
    } else if (unboxing && (guarded_cid == kFloat32x4Cid)) {
      simd128_value_t raw_value;
      raw_value.readFrom(Float32x4::RawCast(value)->ptr()->value_);
      ASSERT(*(reinterpret_cast<RawFloat32x4**>(instance->ptr()) +
               offset_in_words) == null_value);  // Initializing store.
      if (!AllocateFloat32x4(thread, raw_value, pc, FP, SP)) {
        HANDLE_EXCEPTION;
      }
      RawFloat32x4* box = Float32x4::RawCast(SP[0]);
      instance = reinterpret_cast<RawInstance*>(SP[-1]);
      instance->StorePointer(
          reinterpret_cast<RawFloat32x4**>(instance->ptr()) + offset_in_words,
          box, thread);
    } else if (unboxing && (guarded_cid == kFloat64x2Cid)) {
      simd128_value_t raw_value;
      raw_value.readFrom(Float64x2::RawCast(value)->ptr()->value_);
      ASSERT(*(reinterpret_cast<RawFloat64x2**>(instance->ptr()) +
               offset_in_words) == null_value);  // Initializing store.
      if (!AllocateFloat64x2(thread, raw_value, pc, FP, SP)) {
        HANDLE_EXCEPTION;
      }
      RawFloat64x2* box = Float64x2::RawCast(SP[0]);
      instance = reinterpret_cast<RawInstance*>(SP[-1]);
      instance->StorePointer(
          reinterpret_cast<RawFloat64x2**>(instance->ptr()) + offset_in_words,
          box, thread);
    } else {
      instance->StorePointer(
          reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words,
          value, thread);
    }

    SP -= 2;  // Drop instance and value.
    DISPATCH();
  }

  {
    BYTECODE(StoreContextParent, 0);
    const uword offset_in_words =
        static_cast<uword>(Context::parent_offset() / kWordSize);
    RawContext* instance = reinterpret_cast<RawContext*>(SP[-1]);
    RawContext* value = reinterpret_cast<RawContext*>(SP[0]);
    SP -= 2;  // Drop instance and value.

    instance->StorePointer(
        reinterpret_cast<RawContext**>(instance->ptr()) + offset_in_words,
        value, thread);

    DISPATCH();
  }

  {
    BYTECODE(StoreContextVar, __D);
    const uword offset_in_words =
        static_cast<uword>(Context::variable_offset(rD) / kWordSize);
    RawContext* instance = reinterpret_cast<RawContext*>(SP[-1]);
    RawObject* value = reinterpret_cast<RawContext*>(SP[0]);
    SP -= 2;  // Drop instance and value.
    ASSERT(rD < static_cast<uint32_t>(instance->ptr()->num_variables_));
    instance->StorePointer(
        reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words, value,
        thread);

    DISPATCH();
  }

  {
    BYTECODE(LoadFieldTOS, __D);
#if defined(DEBUG)
    // Currently only used to load closure fields, which are not unboxed.
    // If used for general field, code for copying the mutable box must be
    // added.
    RawField* field = RAW_CAST(Field, LOAD_CONSTANT(rD + 1));
    const bool unboxing =
        (field->ptr()->is_nullable_ != kNullCid) &&
        Field::UnboxingCandidateBit::decode(field->ptr()->kind_bits_);
    ASSERT(!unboxing);
#endif
    const uword offset_in_words =
        static_cast<uword>(Smi::Value(RAW_CAST(Smi, LOAD_CONSTANT(rD))));
    RawInstance* instance = static_cast<RawInstance*>(SP[0]);
    SP[0] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(LoadTypeArgumentsField, __D);
    const uword offset_in_words =
        static_cast<uword>(Smi::Value(RAW_CAST(Smi, LOAD_CONSTANT(rD))));
    RawInstance* instance = static_cast<RawInstance*>(SP[0]);
    SP[0] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(LoadContextParent, 0);
    const uword offset_in_words =
        static_cast<uword>(Context::parent_offset() / kWordSize);
    RawContext* instance = static_cast<RawContext*>(SP[0]);
    SP[0] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(LoadContextVar, __D);
    const uword offset_in_words =
        static_cast<uword>(Context::variable_offset(rD) / kWordSize);
    RawContext* instance = static_cast<RawContext*>(SP[0]);
    ASSERT(rD < static_cast<uint32_t>(instance->ptr()->num_variables_));
    SP[0] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(AllocateContext, A_D);
    ++SP;
    const uint16_t num_context_variables = rD;
    if (!AllocateContext(thread, num_context_variables, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    DISPATCH();
  }

  {
    BYTECODE(CloneContext, A);
    {
      SP[1] = SP[0];  // Context to clone.
      Exit(thread, FP, SP + 2, pc);
      NativeArguments args(thread, 1, SP + 1, SP);
      INVOKE_RUNTIME(DRT_CloneContext, args);
    }
    DISPATCH();
  }

  {
    BYTECODE(Allocate, A_D);
    RawClass* cls = Class::RawCast(LOAD_CONSTANT(rD));
    if (LIKELY(InterpreterHelpers::IsFinalized(cls))) {
      const intptr_t class_id = cls->ptr()->id_;
      const intptr_t instance_size = cls->ptr()->instance_size_in_words_
                                     << kWordSizeLog2;
      const uword start = thread->top();
      if (LIKELY((start + instance_size) < thread->end())) {
        thread->set_top(start + instance_size);
        RawObject* result = InitializeHeader(start, class_id, instance_size);
        for (intptr_t offset = sizeof(RawInstance); offset < instance_size;
             offset += kWordSize) {
          *reinterpret_cast<RawObject**>(start + offset) = null_value;
        }
        *++SP = result;
        DISPATCH();
      }
    }

    SP[1] = 0;           // Space for the result.
    SP[2] = cls;         // Class object.
    SP[3] = null_value;  // Type arguments.
    Exit(thread, FP, SP + 4, pc);
    NativeArguments args(thread, 2, SP + 2, SP + 1);
    INVOKE_RUNTIME(DRT_AllocateObject, args);
    SP++;  // Result is in SP[1].
    DISPATCH();
  }

  {
    BYTECODE(AllocateT, 0);
    RawClass* cls = Class::RawCast(SP[0]);
    RawTypeArguments* type_args = TypeArguments::RawCast(SP[-1]);
    if (LIKELY(InterpreterHelpers::IsFinalized(cls))) {
      const intptr_t class_id = cls->ptr()->id_;
      const intptr_t instance_size = cls->ptr()->instance_size_in_words_
                                     << kWordSizeLog2;
      const uword start = thread->top();
      if (LIKELY((start + instance_size) < thread->end())) {
        thread->set_top(start + instance_size);
        RawObject* result = InitializeHeader(start, class_id, instance_size);
        for (intptr_t offset = sizeof(RawInstance); offset < instance_size;
             offset += kWordSize) {
          *reinterpret_cast<RawObject**>(start + offset) = null_value;
        }
        const intptr_t type_args_offset =
            cls->ptr()->type_arguments_field_offset_in_words_ << kWordSizeLog2;
        *reinterpret_cast<RawObject**>(start + type_args_offset) = type_args;
        *--SP = result;
        DISPATCH();
      }
    }

    SP[1] = cls;
    SP[2] = type_args;
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP - 1);
    INVOKE_RUNTIME(DRT_AllocateObject, args);
    SP -= 1;  // Result is in SP - 1.
    DISPATCH();
  }

  {
    BYTECODE(CreateArrayTOS, 0);
    RawTypeArguments* type_args = TypeArguments::RawCast(SP[-1]);
    RawObject* length = SP[0];
    SP--;
    if (!AllocateArray(thread, type_args, length, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    DISPATCH();
  }

  {
    BYTECODE(AssertAssignable, A_D);
    // Stack: instance, type, instantiator type args, function type args, name
    RawObject** args = SP - 4;
    const bool may_be_smi = (rA == 1);
    const bool is_smi =
        ((reinterpret_cast<intptr_t>(args[0]) & kSmiTagMask) == kSmiTag);
    const bool smi_ok = is_smi && may_be_smi;
    if (!smi_ok && (args[0] != null_value)) {
      RawSubtypeTestCache* cache =
          static_cast<RawSubtypeTestCache*>(LOAD_CONSTANT(rD));

      if (!AssertAssignable(thread, pc, FP, SP, args, cache)) {
        HANDLE_EXCEPTION;
      }
    }

    SP -= 4;  // Instance remains on stack.
    DISPATCH();
  }

  {
    BYTECODE(AssertSubtype, A);
    RawObject** args = SP - 4;

    // TODO(kustermann): Implement fast case for common arguments.

    // The arguments on the stack look like:
    //     args[0]  instantiator type args
    //     args[1]  function type args
    //     args[2]  sub_type
    //     args[3]  super_type
    //     args[4]  name

    // This is unused, since the negative case throws an exception.
    SP++;
    RawObject** result_slot = SP;

    Exit(thread, FP, SP + 1, pc);
    NativeArguments native_args(thread, 5, args, result_slot);
    INVOKE_RUNTIME(DRT_SubtypeCheck, native_args);

    // Result slot not used anymore.
    SP--;

    // Drop all arguments.
    SP -= 5;

    DISPATCH();
  }

  {
    BYTECODE(AssertBoolean, A);
    RawObject* value = SP[0];
    if (rA) {  // Should we perform type check?
      if ((value == true_value) || (value == false_value)) {
        goto AssertBooleanOk;
      }
    } else if (value != null_value) {
      goto AssertBooleanOk;
    }

    // Assertion failed.
    {
      SP[1] = SP[0];  // instance
      Exit(thread, FP, SP + 2, pc);
      NativeArguments args(thread, 1, SP + 1, SP);
      INVOKE_RUNTIME(DRT_NonBoolTypeError, args);
    }

  AssertBooleanOk:
    DISPATCH();
  }

  {
    BYTECODE(Jump, 0);
    LOAD_JUMP_TARGET();
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNoAsserts, 0);
    if (!thread->isolate()->asserts()) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNotZeroTypeArgs, 0);
    if (InterpreterHelpers::ArgDescTypeArgsLen(argdesc_) != 0) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfEqStrict, 0);
    SP -= 2;
    if (SP[1] == SP[2]) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNeStrict, 0);
    SP -= 2;
    if (SP[1] != SP[2]) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfTrue, 0);
    SP -= 1;
    if (SP[1] == true_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfFalse, 0);
    SP -= 1;
    if (SP[1] == false_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNull, 0);
    SP -= 1;
    if (SP[1] == null_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(JumpIfNotNull, 0);
    SP -= 1;
    if (SP[1] != null_value) {
      LOAD_JUMP_TARGET();
    }
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedTOS, 0);
    SP -= 3;
    RawArray* array = RAW_CAST(Array, SP[1]);
    RawSmi* index = RAW_CAST(Smi, SP[2]);
    RawObject* value = SP[3];
    ASSERT(InterpreterHelpers::CheckIndex(index, array->ptr()->length_));
    array->StorePointer(array->ptr()->data() + Smi::Value(index), value,
                        thread);
    DISPATCH();
  }

  {
    BYTECODE(EqualsNull, 0);
    SP[0] = (SP[0] == null_value) ? true_value : false_value;
    DISPATCH();
  }

  {
    BYTECODE(NegateInt, 0);
    UNBOX_INT64(value, SP[0], Symbols::UnaryMinus());
    int64_t result = Utils::SubWithWrapAround(0, value);
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
    if (UNLIKELY(b == 0)) {
      goto ThrowIntegerDivisionByZeroException;
    }
    int64_t result;
    if (UNLIKELY((a == Mint::kMinValue) && (b == -1))) {
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
    if (UNLIKELY(b == 0)) {
      goto ThrowIntegerDivisionByZeroException;
    }
    int64_t result;
    if (UNLIKELY((a == Mint::kMinValue) && (b == -1))) {
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
      int64_t a = Integer::GetInt64Value(RAW_CAST(Integer, SP[0]));
      int64_t b = Integer::GetInt64Value(RAW_CAST(Integer, SP[1]));
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
    BYTECODE(AllocateClosure, A_D);
    ++SP;
    if (!AllocateClosure(thread, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }
    DISPATCH();
  }

  {
    BYTECODE(Trap, 0);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitGetter, 0);

    RawFunction* function = FrameFunction(FP);
    int32_t counter = ++(function->ptr()->usage_counter_);
    if (UNLIKELY(FLAG_compilation_counter_threshold >= 0 &&
                 counter >= FLAG_compilation_counter_threshold &&
                 !Function::HasCode(function))) {
      SP[1] = 0;  // Unused code result.
      SP[2] = function;
      Exit(thread, FP, SP + 3, pc);
      NativeArguments native_args(thread, 1, SP + 2, SP + 1);
      INVOKE_RUNTIME(DRT_OptimizeInvokedFunction, native_args);
      function = FrameFunction(FP);
    }

    // Field object is cached in function's data_.
    RawField* field = reinterpret_cast<RawField*>(function->ptr()->data_);
    intptr_t offset_in_words = Smi::Value(field->ptr()->value_.offset_);

    const intptr_t kArgc = 1;
    RawInstance* instance =
        reinterpret_cast<RawInstance*>(FrameArguments(FP, kArgc)[0]);
    RawObject* value =
        reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];

    *++SP = value;

    const bool unboxing =
        (field->ptr()->is_nullable_ != kNullCid) &&
        Field::UnboxingCandidateBit::decode(field->ptr()->kind_bits_);
    classid_t guarded_cid = field->ptr()->guarded_cid_;
    if (unboxing && (guarded_cid == kDoubleCid)) {
      double raw_value = Double::RawCast(value)->ptr()->value_;
      // AllocateDouble places result at SP[0]
      if (!AllocateDouble(thread, raw_value, pc, FP, SP)) {
        HANDLE_EXCEPTION;
      }
    } else if (unboxing && (guarded_cid == kFloat32x4Cid)) {
      simd128_value_t raw_value;
      raw_value.readFrom(Float32x4::RawCast(value)->ptr()->value_);
      // AllocateFloat32x4 places result at SP[0]
      if (!AllocateFloat32x4(thread, raw_value, pc, FP, SP)) {
        HANDLE_EXCEPTION;
      }
    } else if (unboxing && (guarded_cid == kFloat64x2Cid)) {
      simd128_value_t raw_value;
      raw_value.readFrom(Float64x2::RawCast(value)->ptr()->value_);
      // AllocateFloat64x2 places result at SP[0]
      if (!AllocateFloat64x2(thread, raw_value, pc, FP, SP)) {
        HANDLE_EXCEPTION;
      }
    }

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_ImplicitSetter, 0);

    RawFunction* function = FrameFunction(FP);
    int32_t counter = ++(function->ptr()->usage_counter_);
    if (UNLIKELY(FLAG_compilation_counter_threshold >= 0 &&
                 counter >= FLAG_compilation_counter_threshold &&
                 !Function::HasCode(function))) {
      SP[1] = 0;  // Unused code result.
      SP[2] = function;
      Exit(thread, FP, SP + 3, pc);
      NativeArguments native_args(thread, 1, SP + 2, SP + 1);
      INVOKE_RUNTIME(DRT_OptimizeInvokedFunction, native_args);
      function = FrameFunction(FP);
    }

    // Field object is cached in function's data_.
    RawField* field = reinterpret_cast<RawField*>(function->ptr()->data_);
    intptr_t offset_in_words = Smi::Value(field->ptr()->value_.offset_);
    const intptr_t kArgc = 2;
    RawInstance* instance =
        reinterpret_cast<RawInstance*>(FrameArguments(FP, kArgc)[0]);
    RawObject* value = FrameArguments(FP, kArgc)[1];

    RawAbstractType* field_type = field->ptr()->type_;
    classid_t cid;
    if (field_type->GetClassId() == kTypeCid) {
      cid = Smi::Value(reinterpret_cast<RawSmi*>(
          Type::RawCast(field_type)->ptr()->type_class_id_));
    } else {
      cid = kIllegalCid;  // Not really illegal, but not a Type to skip.
    }
    // Perform type test of value if field type is not one of dynamic, object,
    // or void, and if the value is not null.
    RawObject* null_value = Object::null();
    if (cid != kDynamicCid && cid != kInstanceCid && cid != kVoidCid &&
        value != null_value) {
      RawSubtypeTestCache* cache = field->ptr()->type_test_cache_;
      if (cache->GetClassId() != kSubtypeTestCacheCid) {
        // Allocate new cache.
        SP[1] = null_value;  // Result.

        Exit(thread, FP, SP + 2, pc);
        NativeArguments native_args(thread, 0, /* argv */ SP + 1,
                                    /* retval */ SP + 1);
        if (!InvokeRuntime(thread, this, DRT_AllocateSubtypeTestCache,
                           native_args)) {
          HANDLE_EXCEPTION;
        }

        // Reload objects after the call which may trigger GC.
        field = reinterpret_cast<RawField*>(FrameFunction(FP)->ptr()->data_);
        field_type = field->ptr()->type_;
        instance = reinterpret_cast<RawInstance*>(FrameArguments(FP, kArgc)[0]);
        value = FrameArguments(FP, kArgc)[1];
        cache = reinterpret_cast<RawSubtypeTestCache*>(SP[1]);
        field->ptr()->type_test_cache_ = cache;
      }

      // Push arguments of type test.
      SP[1] = value;
      SP[2] = field_type;
      // Provide type arguments of instance as instantiator.
      SP[3] = InterpreterHelpers::GetTypeArguments(thread, instance);
      SP[4] = null_value;  // Implicit setters cannot be generic.
      SP[5] = field->ptr()->name_;
      if (!AssertAssignable(thread, pc, FP, /* argv */ SP + 5,
                            /* reval */ SP + 1, cache)) {
        HANDLE_EXCEPTION;
      }

      // Reload objects after the call which may trigger GC.
      field = reinterpret_cast<RawField*>(FrameFunction(FP)->ptr()->data_);
      instance = reinterpret_cast<RawInstance*>(FrameArguments(FP, kArgc)[0]);
      value = FrameArguments(FP, kArgc)[1];
    }

    if (InterpreterHelpers::FieldNeedsGuardUpdate(field, value)) {
      SP[1] = 0;  // Unused result of runtime call.
      SP[2] = field;
      SP[3] = value;
      Exit(thread, FP, SP + 4, pc);
      NativeArguments native_args(thread, 2, /* argv */ SP + 2,
                                  /* retval */ SP + 1);
      if (!InvokeRuntime(thread, this, DRT_UpdateFieldCid, native_args)) {
        HANDLE_EXCEPTION;
      }

      // Reload objects after the call which may trigger GC.
      instance = reinterpret_cast<RawInstance*>(FrameArguments(FP, kArgc)[0]);
      value = FrameArguments(FP, kArgc)[1];
    }

    const bool unboxing =
        (field->ptr()->is_nullable_ != kNullCid) &&
        Field::UnboxingCandidateBit::decode(field->ptr()->kind_bits_);
    classid_t guarded_cid = field->ptr()->guarded_cid_;
    if (unboxing && (guarded_cid == kDoubleCid)) {
      double raw_value = Double::RawCast(value)->ptr()->value_;
      RawDouble* box =
          *(reinterpret_cast<RawDouble**>(instance->ptr()) + offset_in_words);
      ASSERT(box != null_value);  // Non-initializing store.
      box->ptr()->value_ = raw_value;
    } else if (unboxing && (guarded_cid == kFloat32x4Cid)) {
      simd128_value_t raw_value;
      raw_value.readFrom(Float32x4::RawCast(value)->ptr()->value_);
      RawFloat32x4* box = *(reinterpret_cast<RawFloat32x4**>(instance->ptr()) +
                            offset_in_words);
      ASSERT(box != null_value);  // Non-initializing store.
      raw_value.writeTo(box->ptr()->value_);
    } else if (unboxing && (guarded_cid == kFloat64x2Cid)) {
      simd128_value_t raw_value;
      raw_value.readFrom(Float64x2::RawCast(value)->ptr()->value_);
      RawFloat64x2* box = *(reinterpret_cast<RawFloat64x2**>(instance->ptr()) +
                            offset_in_words);
      ASSERT(box != null_value);  // Non-initializing store.
      raw_value.writeTo(box->ptr()->value_);
    } else {
      instance->StorePointer(
          reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words,
          value, thread);
    }

    *++SP = null_value;

    DISPATCH();
  }

  {
    BYTECODE(VMInternal_MethodExtractor, 0);

    RawFunction* function = FrameFunction(FP);
    int32_t counter = ++(function->ptr()->usage_counter_);
    if (UNLIKELY(FLAG_compilation_counter_threshold >= 0 &&
                 counter >= FLAG_compilation_counter_threshold &&
                 !Function::HasCode(function))) {
      SP[1] = 0;  // Unused code result.
      SP[2] = function;
      Exit(thread, FP, SP + 3, pc);
      NativeArguments native_args(thread, 1, SP + 2, SP + 1);
      INVOKE_RUNTIME(DRT_OptimizeInvokedFunction, native_args);
      function = FrameFunction(FP);
    }

    ASSERT(InterpreterHelpers::ArgDescTypeArgsLen(argdesc_) == 0);

    ++SP;
    if (!AllocateClosure(thread, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }

    ++SP;
    if (!AllocateContext(thread, 1, pc, FP, SP)) {
      HANDLE_EXCEPTION;
    }

    RawContext* context = Context::RawCast(*SP--);
    RawInstance* instance = Instance::RawCast(FrameArguments(FP, 1)[0]);
    context->StorePointer(
        reinterpret_cast<RawInstance**>(&context->ptr()->data()[0]), instance);

    RawClosure* closure = Closure::RawCast(*SP);
    closure->StorePointer(
        &closure->ptr()->instantiator_type_arguments_,
        InterpreterHelpers::GetTypeArguments(thread, instance));
    // function_type_arguments_ is already null
    closure->ptr()->delayed_type_arguments_ =
        Object::empty_type_arguments().raw();
    closure->StorePointer(&closure->ptr()->function_,
                          Function::RawCast(FrameFunction(FP)->ptr()->data_));
    closure->StorePointer(&closure->ptr()->context_, context);
    // hash_ is already null

    DISPATCH();
  }

  // Helper used to handle noSuchMethod on closures.
  {
  ClosureNoSuchMethod:
#if defined(DEBUG)
    function_h ^= FrameFunction(FP);
    ASSERT(function_h.IsNull() || function_h.IsClosureFunction());
#endif

    // Restore caller context as we are going to throw NoSuchMethod.
    pc = SavedCallerPC(FP);

    const bool has_dart_caller = !IsEntryFrameMarker(pc);
    const intptr_t argc = has_dart_caller ? KernelBytecode::DecodeArgc(pc[-1])
                                          : (reinterpret_cast<uword>(pc) >> 2);
    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;

    SP = FrameArguments(FP, 0);
    RawObject** args = SP - argc;
    FP = SavedCallerFP(FP);
    NOT_IN_PRODUCT(fp_ = FP);  // For the profiler.
    if (has_dart_caller) {
      pp_ = InterpreterHelpers::FrameBytecode(FP)->ptr()->object_pool_;
    }

    *++SP = null_value;
    *++SP = args[receiver_idx];  // Closure object.
    *++SP = argdesc_;
    *++SP = null_value;  // Array of arguments (will be filled).

    // Allocate array of arguments.
    {
      SP[1] = Smi::New(argc);  // length
      SP[2] = null_value;      // type
      Exit(thread, FP, SP + 3, pc);
      NativeArguments native_args(thread, 2, SP + 1, SP);
      if (!InvokeRuntime(thread, this, DRT_AllocateArray, native_args)) {
        HANDLE_EXCEPTION;
      } else if (has_dart_caller) {
        HANDLE_RETURN;
      }

      // Copy arguments into the newly allocated array.
      RawArray* array = static_cast<RawArray*>(SP[0]);
      ASSERT(array->GetClassId() == kArrayCid);
      for (intptr_t i = 0; i < argc; i++) {
        array->ptr()->data()[i] = args[i];
      }
    }

    // Invoke noSuchMethod passing down closure, argument descriptor and
    // array of arguments.
    {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments native_args(thread, 3, SP - 2, SP - 3);
      INVOKE_RUNTIME(DRT_InvokeClosureNoSuchMethod, native_args);
      UNREACHABLE();
    }

    DISPATCH();
  }

  {
  ThrowNullError:
    // SP[0] contains selector.
    SP[1] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 2, pc);
    NativeArguments args(thread, 1, SP, SP + 1);
    INVOKE_RUNTIME(DRT_NullErrorWithSelector, args);
    UNREACHABLE();
  }

  {
  ThrowIntegerDivisionByZeroException:
    SP[0] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 1, pc);
    NativeArguments args(thread, 0, SP, SP);
    INVOKE_RUNTIME(DRT_IntegerDivisionByZeroException, args);
    UNREACHABLE();
  }

  {
  ThrowArgumentError:
    // SP[0] contains value.
    SP[1] = 0;  // Unused space for result.
    Exit(thread, FP, SP + 2, pc);
    NativeArguments args(thread, 1, SP, SP + 1);
    INVOKE_RUNTIME(DRT_ArgumentError, args);
    UNREACHABLE();
  }

  // Single dispatch point used by exception handling macros.
  {
  DispatchAfterException:
    pp_ = InterpreterHelpers::FrameBytecode(FP)->ptr()->object_pool_;
    DISPATCH();
  }

  UNREACHABLE();
  return 0;
}

void Interpreter::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
  // Walk over all setjmp buffers (simulated --> C++ transitions)
  // and try to find the setjmp associated with the simulated frame pointer.
  InterpreterSetjmpBuffer* buf = last_setjmp_buffer();
  while ((buf->link() != NULL) && (buf->link()->fp() > fp)) {
    buf = buf->link();
  }
  ASSERT(buf != NULL);
  ASSERT(last_setjmp_buffer() == buf);

  // The C++ caller has not cleaned up the stack memory of C++ frames.
  // Prepare for unwinding frames by destroying all the stack resources
  // in the previous C++ frames.
  StackResource::Unwind(thread);

  fp_ = reinterpret_cast<RawObject**>(fp);

  if (pc == StubCode::RunExceptionHandler().EntryPoint()) {
    // The RunExceptionHandler stub is a placeholder.  We implement
    // its behavior here.
    RawObject* raw_exception = thread->active_exception();
    RawObject* raw_stacktrace = thread->active_stacktrace();
    ASSERT(raw_exception != Object::null());
    thread->set_active_exception(Object::null_object());
    thread->set_active_stacktrace(Object::null_object());
    special_[KernelBytecode::kExceptionSpecialIndex] = raw_exception;
    special_[KernelBytecode::kStackTraceSpecialIndex] = raw_stacktrace;
    pc_ = reinterpret_cast<uint32_t*>(thread->resume_pc());
  } else {
    pc_ = reinterpret_cast<uint32_t*>(pc);
  }

  // Set the tag.
  thread->set_vm_tag(VMTag::kDartInterpretedTagId);
  // Clear top exit frame.
  thread->set_top_exit_frame_info(0);

  buf->Longjmp();
  UNREACHABLE();
}

void Interpreter::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&pp_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&argdesc_));
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
