// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(TARGET_OS_WINDOWS)

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

#define LIKELY(cond) __builtin_expect((cond), 1)
#define UNLIKELY(cond) __builtin_expect((cond), 0)

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

  DART_FORCE_INLINE static bool IsStrictEqualWithNumberCheck(RawObject* lhs,
                                                             RawObject* rhs) {
    if (lhs == rhs) {
      return true;
    }

    if (lhs->IsHeapObject() && rhs->IsHeapObject()) {
      const intptr_t lhs_cid = lhs->GetClassId();
      const intptr_t rhs_cid = rhs->GetClassId();
      if (lhs_cid == rhs_cid) {
        switch (lhs_cid) {
          case kDoubleCid:
            return (bit_cast<uint64_t, double>(
                        static_cast<RawDouble*>(lhs)->ptr()->value_) ==
                    bit_cast<uint64_t, double>(
                        static_cast<RawDouble*>(rhs)->ptr()->value_));

          case kMintCid:
            return (static_cast<RawMint*>(lhs)->ptr()->value_ ==
                    static_cast<RawMint*>(rhs)->ptr()->value_);
        }
      }
    }

    return false;
  }

  template <typename T>
  DART_FORCE_INLINE static T* Untag(T* tagged) {
    return tagged->ptr();
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

  static bool ObjectArraySetIndexed(Thread* thread,
                                    RawObject** FP,
                                    RawObject** result) {
    return !thread->isolate()->type_checks() &&
           ObjectArraySetIndexedUnchecked(thread, FP, result);
  }

  static bool ObjectArraySetIndexedUnchecked(Thread* thread,
                                             RawObject** FP,
                                             RawObject** result) {
    RawObject** args = FrameArguments(FP, 3);
    RawSmi* index = static_cast<RawSmi*>(args[1]);
    RawArray* array = static_cast<RawArray*>(args[0]);
    if (CheckIndex(index, array->ptr()->length_)) {
      array->StorePointer(array->ptr()->data() + Smi::Value(index), args[2],
                          thread);
      return true;
    }
    return false;
  }

  static bool ObjectArrayGetIndexed(Thread* thread,
                                    RawObject** FP,
                                    RawObject** result) {
    RawObject** args = FrameArguments(FP, 2);
    RawSmi* index = static_cast<RawSmi*>(args[1]);
    RawArray* array = static_cast<RawArray*>(args[0]);
    if (CheckIndex(index, array->ptr()->length_)) {
      *result = array->ptr()->data()[Smi::Value(index)];
      return true;
    }
    return false;
  }

  static bool GrowableArraySetIndexed(Thread* thread,
                                      RawObject** FP,
                                      RawObject** result) {
    return !thread->isolate()->type_checks() &&
           GrowableArraySetIndexedUnchecked(thread, FP, result);
  }

  static bool GrowableArraySetIndexedUnchecked(Thread* thread,
                                               RawObject** FP,
                                               RawObject** result) {
    RawObject** args = FrameArguments(FP, 3);
    RawSmi* index = static_cast<RawSmi*>(args[1]);
    RawGrowableObjectArray* array =
        static_cast<RawGrowableObjectArray*>(args[0]);
    if (CheckIndex(index, array->ptr()->length_)) {
      RawArray* data = array->ptr()->data_;
      data->StorePointer(data->ptr()->data() + Smi::Value(index), args[2],
                         thread);
      return true;
    }
    return false;
  }

  static bool GrowableArrayGetIndexed(Thread* thread,
                                      RawObject** FP,
                                      RawObject** result) {
    RawObject** args = FrameArguments(FP, 2);
    RawSmi* index = static_cast<RawSmi*>(args[1]);
    RawGrowableObjectArray* array =
        static_cast<RawGrowableObjectArray*>(args[0]);
    if (CheckIndex(index, array->ptr()->length_)) {
      *result = array->ptr()->data_->ptr()->data()[Smi::Value(index)];
      return true;
    }
    return false;
  }

  static bool Double_getIsNan(Thread* thread,
                              RawObject** FP,
                              RawObject** result) {
    RawObject** args = FrameArguments(FP, 1);
    RawDouble* d = static_cast<RawDouble*>(args[0]);
    *result =
        isnan(d->ptr()->value_) ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool Double_getIsInfinite(Thread* thread,
                                   RawObject** FP,
                                   RawObject** result) {
    RawObject** args = FrameArguments(FP, 1);
    RawDouble* d = static_cast<RawDouble*>(args[0]);
    *result =
        isinf(d->ptr()->value_) ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool ObjectEquals(Thread* thread, RawObject** FP, RawObject** result) {
    RawObject** args = FrameArguments(FP, 2);
    *result = args[0] == args[1] ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool ObjectRuntimeType(Thread* thread,
                                RawObject** FP,
                                RawObject** result) {
    RawObject** args = FrameArguments(FP, 1);
    const intptr_t cid = GetClassId(args[0]);
    if (cid == kClosureCid) {
      return false;
    }
    if (cid < kNumPredefinedCids) {
      if (cid == kDoubleCid) {
        *result = thread->isolate()->object_store()->double_type();
        return true;
      } else if (RawObject::IsStringClassId(cid)) {
        *result = thread->isolate()->object_store()->string_type();
        return true;
      } else if (RawObject::IsIntegerClassId(cid)) {
        *result = thread->isolate()->object_store()->int_type();
        return true;
      }
    }
    RawClass* cls = thread->isolate()->class_table()->At(cid);
    if (cls->ptr()->num_type_arguments_ != 0) {
      return false;
    }
    RawType* typ = cls->ptr()->canonical_type_;
    if (typ == Object::null()) {
      return false;
    }
    *result = static_cast<RawObject*>(typ);
    return true;
  }

  static bool GetDoubleOperands(RawObject** args, double* d1, double* d2) {
    RawObject* obj2 = args[1];
    if (!obj2->IsHeapObject()) {
      *d2 =
          static_cast<double>(reinterpret_cast<intptr_t>(obj2) >> kSmiTagSize);
    } else if (obj2->GetClassId() == kDoubleCid) {
      RawDouble* obj2d = static_cast<RawDouble*>(obj2);
      *d2 = obj2d->ptr()->value_;
    } else {
      return false;
    }
    RawDouble* obj1 = static_cast<RawDouble*>(args[0]);
    *d1 = obj1->ptr()->value_;
    return true;
  }

  static RawObject* AllocateDouble(Thread* thread, double value) {
    const intptr_t instance_size = Double::InstanceSize();
    const uword start =
        thread->heap()->new_space()->TryAllocateInTLAB(thread, instance_size);
    if (LIKELY(start != 0)) {
      uword tags = 0;
      tags = RawObject::ClassIdTag::update(kDoubleCid, tags);
      tags = RawObject::SizeTag::update(instance_size, tags);
      tags = RawObject::NewBit::update(true, tags);
      // Also writes zero in the hash_ field.
      *reinterpret_cast<uword*>(start + Double::tags_offset()) = tags;
      *reinterpret_cast<double*>(start + Double::value_offset()) = value;
      return reinterpret_cast<RawObject*>(start + kHeapObjectTag);
    }
    return NULL;
  }

  static bool Double_add(Thread* thread, RawObject** FP, RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    RawObject* new_double = AllocateDouble(thread, d1 + d2);
    if (new_double != NULL) {
      *result = new_double;
      return true;
    }
    return false;
  }

  static bool Double_mul(Thread* thread, RawObject** FP, RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    RawObject* new_double = AllocateDouble(thread, d1 * d2);
    if (new_double != NULL) {
      *result = new_double;
      return true;
    }
    return false;
  }

  static bool Double_sub(Thread* thread, RawObject** FP, RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    RawObject* new_double = AllocateDouble(thread, d1 - d2);
    if (new_double != NULL) {
      *result = new_double;
      return true;
    }
    return false;
  }

  static bool Double_div(Thread* thread, RawObject** FP, RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    RawObject* new_double = AllocateDouble(thread, d1 / d2);
    if (new_double != NULL) {
      *result = new_double;
      return true;
    }
    return false;
  }

  static bool Double_greaterThan(Thread* thread,
                                 RawObject** FP,
                                 RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    *result = d1 > d2 ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool Double_greaterEqualThan(Thread* thread,
                                      RawObject** FP,
                                      RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    *result = d1 >= d2 ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool Double_lessThan(Thread* thread,
                              RawObject** FP,
                              RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    *result = d1 < d2 ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool Double_equal(Thread* thread, RawObject** FP, RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    *result = d1 == d2 ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool Double_lessEqualThan(Thread* thread,
                                   RawObject** FP,
                                   RawObject** result) {
    double d1, d2;
    if (!GetDoubleOperands(FrameArguments(FP, 2), &d1, &d2)) {
      return false;
    }
    *result = d1 <= d2 ? Bool::True().raw() : Bool::False().raw();
    return true;
  }

  static bool ClearAsyncThreadStack(Thread* thread,
                                    RawObject** FP,
                                    RawObject** result) {
    thread->clear_async_stack_trace();
    *result = Object::null();
    return true;
  }

  static bool SetAsyncThreadStackTrace(Thread* thread,
                                       RawObject** FP,
                                       RawObject** result) {
    RawObject** args = FrameArguments(FP, 1);
    thread->set_raw_async_stack_trace(
        reinterpret_cast<RawStackTrace*>(args[0]));
    *result = Object::null();
    return true;
  }

  DART_FORCE_INLINE static RawCode* FrameCode(RawObject** FP) {
    ASSERT(GetClassId(FP[kKBCPcMarkerSlotFromFp]) == kCodeCid);
    return static_cast<RawCode*>(FP[kKBCPcMarkerSlotFromFp]);
  }

  DART_FORCE_INLINE static void SetFrameCode(RawObject** FP, RawCode* code) {
    ASSERT(GetClassId(code) == kCodeCid);
    FP[kKBCPcMarkerSlotFromFp] = code;
  }

  DART_FORCE_INLINE static uint8_t* GetTypedData(RawObject* obj,
                                                 RawObject* index) {
    ASSERT(RawObject::IsTypedDataClassId(obj->GetClassId()));
    RawTypedData* array = reinterpret_cast<RawTypedData*>(obj);
    const intptr_t byte_offset = Smi::Value(RAW_CAST(Smi, index));
    ASSERT(byte_offset >= 0);
    return array->ptr()->data() + byte_offset;
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

IntrinsicHandler Interpreter::intrinsics_[Interpreter::kIntrinsicCount];

// Synchronization primitives support.
void Interpreter::InitOnce() {
  for (intptr_t i = 0; i < kIntrinsicCount; i++) {
    intrinsics_[i] = 0;
  }

  intrinsics_[kObjectArraySetIndexedIntrinsic] =
      InterpreterHelpers::ObjectArraySetIndexed;
  intrinsics_[kObjectArraySetIndexedUncheckedIntrinsic] =
      InterpreterHelpers::ObjectArraySetIndexedUnchecked;
  intrinsics_[kObjectArrayGetIndexedIntrinsic] =
      InterpreterHelpers::ObjectArrayGetIndexed;
  intrinsics_[kGrowableArraySetIndexedIntrinsic] =
      InterpreterHelpers::GrowableArraySetIndexed;
  intrinsics_[kGrowableArraySetIndexedUncheckedIntrinsic] =
      InterpreterHelpers::GrowableArraySetIndexedUnchecked;
  intrinsics_[kGrowableArrayGetIndexedIntrinsic] =
      InterpreterHelpers::GrowableArrayGetIndexed;
  intrinsics_[kObjectEqualsIntrinsic] = InterpreterHelpers::ObjectEquals;
  intrinsics_[kObjectRuntimeTypeIntrinsic] =
      InterpreterHelpers::ObjectRuntimeType;

  intrinsics_[kDouble_getIsNaNIntrinsic] = InterpreterHelpers::Double_getIsNan;
  intrinsics_[kDouble_getIsInfiniteIntrinsic] =
      InterpreterHelpers::Double_getIsInfinite;
  intrinsics_[kDouble_addIntrinsic] = InterpreterHelpers::Double_add;
  intrinsics_[kDouble_mulIntrinsic] = InterpreterHelpers::Double_mul;
  intrinsics_[kDouble_subIntrinsic] = InterpreterHelpers::Double_sub;
  intrinsics_[kDouble_divIntrinsic] = InterpreterHelpers::Double_div;
  intrinsics_[kDouble_greaterThanIntrinsic] =
      InterpreterHelpers::Double_greaterThan;
  intrinsics_[kDouble_greaterEqualThanIntrinsic] =
      InterpreterHelpers::Double_greaterEqualThan;
  intrinsics_[kDouble_lessThanIntrinsic] = InterpreterHelpers::Double_lessThan;
  intrinsics_[kDouble_equalIntrinsic] = InterpreterHelpers::Double_equal;
  intrinsics_[kDouble_lessEqualThanIntrinsic] =
      InterpreterHelpers::Double_lessEqualThan;
  intrinsics_[kClearAsyncThreadStackTraceIntrinsic] =
      InterpreterHelpers::ClearAsyncThreadStack;
  intrinsics_[kSetAsyncThreadStackTraceIntrinsic] =
      InterpreterHelpers::SetAsyncThreadStackTrace;
}

Interpreter::Interpreter()
    : stack_(NULL), fp_(NULL), pp_(NULL), argdesc_(NULL) {
  // Setup interpreter support first. Some of this information is needed to
  // setup the architecture state.
  // We allocate the stack here, the size is computed as the sum of
  // the size specified by the user and the buffer space needed for
  // handling stack overflow exceptions. To be safe in potential
  // stack underflows we also add some underflow buffer space.
  stack_ = new uintptr_t[(OSThread::GetSpecifiedStackSize() +
                          OSThread::kStackSizeBuffer +
                          kInterpreterStackUnderflowSize) /
                         sizeof(uintptr_t)];
  // Low address.
  stack_base_ =
      reinterpret_cast<uword>(stack_) + kInterpreterStackUnderflowSize;
  // High address.
  stack_limit_ = stack_base_ + OSThread::GetSpecifiedStackSize();

  last_setjmp_buffer_ = NULL;

  DEBUG_ONLY(icount_ = 1);  // So that tracing after 0 traces first bytecode.
}

Interpreter::~Interpreter() {
  delete[] stack_;
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    isolate->set_interpreter(NULL);
  }
}

// Get the active Interpreter for the current isolate.
Interpreter* Interpreter::Current() {
  Interpreter* interpreter = Isolate::Current()->interpreter();
  if (interpreter == NULL) {
    interpreter = new Interpreter();
    Isolate::Current()->set_interpreter(interpreter);
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
  frame[1] = Code::null();
  frame[2] = reinterpret_cast<RawObject*>(pc);
  frame[3] = reinterpret_cast<RawObject*>(base);
  fp_ = frame + kKBCDartFrameFixedSize;
  thread->set_top_exit_frame_info(reinterpret_cast<uword>(fp_));
#if defined(DEBUG)
  if (IsTracingExecution()) {
    THR_Print("%" Pu64 " ", icount_);
    THR_Print("Exiting interpreter 0x%" Px " at fp_ 0x%" Px "\n",
              reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_));
  }
#endif
}

void Interpreter::CallRuntime(Thread* thread,
                              RawObject** base,
                              RawObject** exit_frame,
                              uint32_t* pc,
                              intptr_t argc_tag,
                              RawObject** args,
                              RawObject** result,
                              uword target) {
  Exit(thread, base, exit_frame, pc);
  NativeArguments native_args(thread, argc_tag, args, result);
  reinterpret_cast<RuntimeFunction>(target)(native_args);
}

DART_FORCE_INLINE static void EnterSyntheticFrame(RawObject*** FP,
                                                  RawObject*** SP,
                                                  uint32_t* pc) {
  RawObject** fp = *SP + kKBCDartFrameFixedSize;
  fp[kKBCPcMarkerSlotFromFp] = 0;
  fp[kKBCSavedCallerPcSlotFromFp] = reinterpret_cast<RawObject*>(pc);
  fp[kKBCSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(*FP);
  *FP = fp;
  *SP = fp - 1;
}

DART_FORCE_INLINE static void LeaveSyntheticFrame(RawObject*** FP,
                                                  RawObject*** SP) {
  RawObject** fp = *FP;
  *FP = reinterpret_cast<RawObject**>(fp[kKBCSavedCallerFpSlotFromFp]);
  *SP = fp - kKBCDartFrameFixedSize;
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
    thread->set_vm_tag(VMTag::kDartTagId);
    thread->set_top_exit_frame_info(0);
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
    thread->set_vm_tag(VMTag::kDartTagId);
    thread->set_top_exit_frame_info(0);
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
#if defined(USING_SIMULATOR) || defined(TARGET_ARCH_DBC)
  // TODO(regis): Revisit.
  UNIMPLEMENTED();
#endif
  ASSERT(Function::HasCode(function));
  RawCode* volatile code = function->ptr()->code_;
  ASSERT(code != StubCode::LazyCompile_entry()->code());
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
      StubCode::InvokeDartCodeFromBytecode_entry()->EntryPoint());
  RawObject* volatile result;
  Exit(thread, *FP, call_top + 1, *pc);
  {
    InterpreterSetjmpBuffer buffer(this);
    if (!setjmp(buffer.buffer_)) {
      thread->set_vm_tag(reinterpret_cast<uword>(entrypoint));
      result = entrypoint(code, argdesc_, call_base, thread);
      thread->set_vm_tag(VMTag::kDartTagId);
      thread->set_top_exit_frame_info(0);
      ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
    } else {
      return false;
    }
  }
  // Pop args and push result.
  *SP = call_base;
  **SP = result;
  pp_ = InterpreterHelpers::FrameCode(*FP)->ptr()->object_pool_;

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
      pc_ = reinterpret_cast<uword>(SavedCallerPC(fp_));
      while (!IsEntryFrameMarker(pc_)) {
        fp_ = SavedCallerFP(fp_);
        pc_ = reinterpret_cast<uword>(SavedCallerPC(fp_));
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
  // If the function is an implicit getter or setter, process its invocation
  // here without code or bytecode.
  RawFunction::Kind kind = Function::kind(function);
  switch (kind) {
    case RawFunction::kImplicitGetter: {
      // Field object is cached in function's data_.
      RawInstance* instance = reinterpret_cast<RawInstance*>(*call_base);
      RawField* field = reinterpret_cast<RawField*>(function->ptr()->data_);
      intptr_t offset_in_words = Smi::Value(field->ptr()->value_.offset_);
      *SP = call_base;
      **SP = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
      *invoked = true;
      return true;
    }
    case RawFunction::kImplicitSetter: {
      // Field object is cached in function's data_.
      RawInstance* instance = reinterpret_cast<RawInstance*>(call_base[0]);
      RawField* field = reinterpret_cast<RawField*>(function->ptr()->data_);
      intptr_t offset_in_words = Smi::Value(field->ptr()->value_.offset_);
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
      RawObject* value = call_base[1];
      if (cid != kDynamicCid && cid != kInstanceCid && cid != kVoidCid &&
          value != null_value) {
        RawSubtypeTestCache* cache = field->ptr()->type_test_cache_;
        if (cache->GetClassId() != kSubtypeTestCacheCid) {
          // Allocate new cache.
          call_top[1] = null_value;  // Result.
          Exit(thread, *FP, call_top + 2, *pc);
          NativeArguments native_args(thread, 0, call_top + 1, call_top + 1);
          if (!InvokeRuntime(thread, this, DRT_AllocateSubtypeTestCache,
                             native_args)) {
            *invoked = true;
            return false;
          }
          // Reload objects after the call which may trigger GC.
          function = reinterpret_cast<RawFunction*>(call_top[0]);
          field = reinterpret_cast<RawField*>(function->ptr()->data_);
          field_type = field->ptr()->type_;
          instance = reinterpret_cast<RawInstance*>(call_base[0]);
          value = call_base[1];
          cache = reinterpret_cast<RawSubtypeTestCache*>(call_top[1]);
          field->ptr()->type_test_cache_ = cache;
        }
        // Push arguments of type test.
        call_top[1] = value;
        call_top[2] = field_type;
        // Provide type arguments of instance as instantiator.
        RawClass* instance_class = thread->isolate()->class_table()->At(
            InterpreterHelpers::GetClassId(instance));
        call_top[3] =
            instance_class->ptr()->num_type_arguments_ > 0
                ? reinterpret_cast<RawObject**>(
                      instance
                          ->ptr())[instance_class->ptr()
                                       ->type_arguments_field_offset_in_words_]
                : null_value;
        call_top[4] = null_value;  // Implicit setters cannot be generic.
        call_top[5] = field->ptr()->name_;
        if (!AssertAssignable(thread, *pc, *FP, call_top + 5, call_top + 1,
                              cache)) {
          *invoked = true;
          return false;
        }
        // Reload objects after the call which may trigger GC.
        function = reinterpret_cast<RawFunction*>(call_top[0]);
        field = reinterpret_cast<RawField*>(function->ptr()->data_);
        instance = reinterpret_cast<RawInstance*>(call_base[0]);
        value = call_base[1];
      }
      if (thread->isolate()->use_field_guards()) {
        // Check value cid according to field.guarded_cid().
        // The interpreter should never see a cloned field.
        ASSERT(field->ptr()->owner_->GetClassId() != kFieldCid);
        const classid_t field_guarded_cid = field->ptr()->guarded_cid_;
        const classid_t field_nullability_cid = field->ptr()->is_nullable_;
        const classid_t value_cid = InterpreterHelpers::GetClassId(value);
        if (value_cid != field_guarded_cid &&
            value_cid != field_nullability_cid) {
          if (Smi::Value(field->ptr()->guarded_list_length_) <
                  Field::kUnknownFixedLength &&
              field_guarded_cid == kIllegalCid) {
            field->ptr()->guarded_cid_ = value_cid;
            field->ptr()->is_nullable_ = value_cid;
          } else if (field_guarded_cid != kDynamicCid) {
            call_top[1] = 0;  // Unused result of runtime call.
            call_top[2] = field;
            call_top[3] = value;
            Exit(thread, *FP, call_top + 4, *pc);
            NativeArguments native_args(thread, 2, call_top + 2, call_top + 1);
            if (!InvokeRuntime(thread, this, DRT_UpdateFieldCid, native_args)) {
              *invoked = true;
              return false;
            }
            // Reload objects after the call which may trigger GC.
            instance = reinterpret_cast<RawInstance*>(call_base[0]);
            value = call_base[1];
          }
        }
      }
      instance->StorePointer(
          reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words,
          value, thread);
      *SP = call_base;
      **SP = null_value;
      *invoked = true;
      return true;
    }
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
        pp_ = InterpreterHelpers::FrameCode(*FP)->ptr()->object_pool_;
        // The field is initialized by the runtime call, but not returned.
        value = field->ptr()->value_.static_value_;
      }
      // Field was initialized. Return its value.
      *SP = call_base;
      **SP = value;
      *invoked = true;
      return true;
    }
    case RawFunction::kMethodExtractor: {
      ASSERT(InterpreterHelpers::ArgDescTypeArgsLen(argdesc_) == 0);
      call_top[1] = 0;                       // Result of runtime call.
      call_top[2] = *call_base;              // Receiver.
      call_top[3] = function->ptr()->data_;  // Method.
      Exit(thread, *FP, call_top + 4, *pc);
      NativeArguments native_args(thread, 2, call_top + 2, call_top + 1);
      if (!InvokeRuntime(thread, this, DRT_ExtractMethod, native_args)) {
        return false;
      }
      *SP = call_base;
      **SP = call_top[1];
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
        call_top[1] = 0;                       // Result of runtime call.
        call_top[2] = receiver;                // Receiver.
        call_top[3] = function->ptr()->name_;  // Field name.
        Exit(thread, *FP, call_top + 4, *pc);
        NativeArguments native_args(thread, 2, call_top + 2, call_top + 1);
        if (!InvokeRuntime(thread, this, DRT_GetFieldForDispatch,
                           native_args)) {
          return false;
        }
        // If the field value is a closure, no need to resolve 'call' function.
        // Otherwise, call runtime to resolve 'call' function.
        if (InterpreterHelpers::GetClassId(call_top[1]) == kClosureCid) {
          // Closure call.
          call_function = Closure::RawCast(call_top[1])->ptr()->function_;
        } else {
          // Resolve and invoke the 'call' function.
          call_top[2] = 0;  // Result of runtime call.
          Exit(thread, *FP, call_top + 3, *pc);
          NativeArguments native_args(thread, 1, call_top + 1, call_top + 2);
          if (!InvokeRuntime(thread, this, DRT_ResolveCallFunction,
                             native_args)) {
            return false;
          }
          call_function = Function::RawCast(call_top[2]);
          if (call_function == Function::null()) {
            // 'Call' could not be resolved. TODO(regis): Can this happen?
            // Fall back to jitting the field dispatcher function.
            break;
          }
        }
        // Replace receiver with field value, keep all other arguments, and
        // invoke 'call' function.
        call_base[receiver_idx] = call_top[1];
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
  if (Function::HasCode(function)) {
    *invoked = true;
    return InvokeCompiled(thread, function, call_base, call_top, pc, FP, SP);
  }
  ASSERT(Function::HasBytecode(function));
  // Bytecode was loaded in the above compilation step.
  // The caller will dispatch to the function's bytecode.
  *invoked = false;
  ASSERT(thread->vm_tag() == VMTag::kDartTagId);
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
  RawCode* bytecode = function->ptr()->bytecode_;
  callee_fp[kKBCPcMarkerSlotFromFp] = bytecode;
  callee_fp[kKBCSavedCallerPcSlotFromFp] = reinterpret_cast<RawObject*>(*pc);
  callee_fp[kKBCSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(*FP);
  pp_ = bytecode->ptr()->object_pool_;
  *pc = reinterpret_cast<uint32_t*>(bytecode->ptr()->entry_point_);
  pc_ = reinterpret_cast<uword>(*pc);  // For the profiler.
  *FP = callee_fp;
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
  RawObject** miss_handler_args = top + 1;
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
  CallRuntime(thread, FP, exit_frame, pc, miss_handler_argc, miss_handler_args,
              result, reinterpret_cast<uword>(handler));
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
  RawArray* cache = icdata->ptr()->ic_data_->ptr();

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
  RawArray* cache = icdata->ptr()->ic_data_->ptr();

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

DART_FORCE_INLINE void Interpreter::PrepareForTailCall(
    RawCode* code,
    RawImmutableArray* args_desc,
    RawObject** FP,
    RawObject*** SP,
    uint32_t** pc) {
  // Drop all stack locals.
  *SP = FP - 1;

  // Replace the callee with the new [code].
  FP[kKBCFunctionSlotFromFp] = Object::null();
  FP[kKBCPcMarkerSlotFromFp] = code;
  *pc = reinterpret_cast<uint32_t*>(code->ptr()->entry_point_);
  pc_ = reinterpret_cast<uword>(pc);  // For the profiler.
  pp_ = code->ptr()->object_pool_;
  argdesc_ = args_desc;
}

// Note:
// All macro helpers are intended to be used only inside Interpreter::Call.

// Counts and prints executed bytecode instructions (in DEBUG mode).
#if defined(DEBUG)
#define TRACE_INSTRUCTION                                                      \
  if (IsTracingExecution()) {                                                  \
    TraceInstruction(pc - 1);                                                  \
  }                                                                            \
  icount_++;
#else
#define TRACE_INSTRUCTION
#endif  // defined(DEBUG)

// Decode opcode and A part of the given value and dispatch to the
// corresponding bytecode handler.
#define DISPATCH_OP(val)                                                       \
  do {                                                                         \
    op = (val);                                                                \
    rA = ((op >> 8) & 0xFF);                                                   \
    TRACE_INSTRUCTION                                                          \
    goto* dispatch[op & 0xFF];                                                 \
  } while (0)

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
    FP = reinterpret_cast<RawObject**>(fp_);                                   \
    pc = reinterpret_cast<uint32_t*>(pc_);                                     \
    if (IsEntryFrameMarker(reinterpret_cast<uword>(pc))) {                     \
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
      ASSERT(reinterpret_cast<uword>(fp_) < stack_limit());                    \
      return special_[KernelBytecode::kExceptionSpecialIndex];                 \
    }                                                                          \
    goto DispatchAfterException;                                               \
  } while (0)

#else  // !defined(DEBUG)

#define HANDLE_EXCEPTION                                                       \
  do {                                                                         \
    FP = reinterpret_cast<RawObject**>(fp_);                                   \
    pc = reinterpret_cast<uint32_t*>(pc_);                                     \
    if (IsEntryFrameMarker(reinterpret_cast<uword>(pc))) {                     \
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
    pp_ = InterpreterHelpers::FrameCode(FP)->ptr()->object_pool_;              \
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
  } else if (!AllocateInt64Box(thread, result, pc, FP, SP)) {                  \
    HANDLE_EXCEPTION;                                                          \
  }                                                                            \
  ASSERT(Integer::GetInt64Value(RAW_CAST(Integer, SP[0])) == result);

// Returns true if deoptimization succeeds.
DART_FORCE_INLINE bool Interpreter::Deoptimize(Thread* thread,
                                               uint32_t** pc,
                                               RawObject*** FP,
                                               RawObject*** SP,
                                               bool is_lazy) {
  // Note: frame translation will take care of preserving result at the
  // top of the stack. See CompilerDeoptInfo::CreateDeoptInfo.

  // Make sure we preserve SP[0] when entering synthetic frame below.
  (*SP)++;

  // Leaf runtime function DeoptimizeCopyFrame expects a Dart frame.
  // The code in this frame may not cause GC.
  // DeoptimizeCopyFrame and DeoptimizeFillFrame are leaf runtime calls.
  EnterSyntheticFrame(FP, SP, *pc - (is_lazy ? 1 : 0));
  const intptr_t frame_size_in_bytes =
      DLRT_DeoptimizeCopyFrame(reinterpret_cast<uword>(*FP), is_lazy ? 1 : 0);
  LeaveSyntheticFrame(FP, SP);

  *SP = *FP + (frame_size_in_bytes / kWordSize);
  EnterSyntheticFrame(FP, SP, *pc - (is_lazy ? 1 : 0));
  DLRT_DeoptimizeFillFrame(reinterpret_cast<uword>(*FP));

  // We are now inside a valid frame.
  {
    *++(*SP) = 0;  // Space for the result: number of materialization args.
    Exit(thread, *FP, *SP + 1, /*pc=*/0);
    NativeArguments native_args(thread, 0, *SP, *SP);
    if (!InvokeRuntime(thread, this, DRT_DeoptimizeMaterialize, native_args)) {
      return false;
    }
  }
  const intptr_t materialization_arg_count =
      Smi::Value(RAW_CAST(Smi, *(*SP)--)) / kWordSize;

  // Restore caller PC.
  *pc = SavedCallerPC(*FP);
  pc_ = reinterpret_cast<uword>(*pc);  // For the profiler.

  // Check if it is a fake PC marking the entry frame.
  ASSERT(!IsEntryFrameMarker(reinterpret_cast<uword>(*pc)));

  // Restore SP, FP and PP.
  // Unoptimized frame SP is one below FrameArguments(...) because
  // FrameArguments(...) returns a pointer to the first argument.
  *SP = FrameArguments(*FP, materialization_arg_count) - 1;
  *FP = SavedCallerFP(*FP);

  // Restore pp.
  pp_ = InterpreterHelpers::FrameCode(*FP)->ptr()->object_pool_;

  return true;
}

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

// Allocate _Mint box for the given int64_t value and puts it into SP[0].
// Returns false on exception.
DART_NOINLINE bool Interpreter::AllocateInt64Box(Thread* thread,
                                                 int64_t value,
                                                 uint32_t* pc,
                                                 RawObject** FP,
                                                 RawObject** SP) {
  ASSERT(!Smi::IsValid(value));
  const intptr_t instance_size = Mint::InstanceSize();
  const uword start =
      thread->heap()->new_space()->TryAllocateInTLAB(thread, instance_size);
  if (LIKELY(start != 0)) {
    uword tags = 0;
    tags = RawObject::ClassIdTag::update(kMintCid, tags);
    tags = RawObject::SizeTag::update(instance_size, tags);
    tags = RawObject::NewBit::update(true, tags);
    // Also writes zero in the hash_ field.
    *reinterpret_cast<uword*>(start + Mint::tags_offset()) = tags;
    *reinterpret_cast<int64_t*>(start + Mint::value_offset()) = value;
    SP[0] = reinterpret_cast<RawObject*>(start + kHeapObjectTag);
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
    *reinterpret_cast<int64_t*>(reinterpret_cast<uword>(SP[0]) -
                                kHeapObjectTag + Mint::value_offset()) = value;
    return true;
  }
}

RawObject* Interpreter::Call(RawFunction* function,
                             RawArray* argdesc,
                             intptr_t argc,
                             RawObject* const* argv,
                             Thread* thread) {
  // Dispatch used to interpret bytecode. Contains addresses of
  // labels of bytecode handlers. Handlers themselves are defined below.
  static const void* dispatch[] = {
#define TARGET(name, fmt, fmta, fmtb, fmtc) &&bc##name,
      KERNEL_BYTECODES_LIST(TARGET)
#undef TARGET
  };

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

  // Save current VM tag and mark thread as executing Dart code.
  const uword vm_tag = thread->vm_tag();
  thread->set_vm_tag(VMTag::kDartTagId);  // TODO(regis): kDartBytecodeTagId?

  // Save current top stack resource and reset the list.
  StackResource* top_resource = thread->top_resource();
  thread->set_top_resource(NULL);

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

  RawCode* bytecode = function->ptr()->bytecode_;
  FP[kKBCFunctionSlotFromFp] = function;
  FP[kKBCPcMarkerSlotFromFp] = bytecode;
  FP[kKBCSavedCallerPcSlotFromFp] =
      reinterpret_cast<RawObject*>((arg_count << 2) | 2);
  FP[kKBCSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(fp_);

  // Load argument descriptor.
  argdesc_ = argdesc;

  // Ready to start executing bytecode. Load entry point and corresponding
  // object pool.
  pc = reinterpret_cast<uint32_t*>(bytecode->ptr()->entry_point_);
  pc_ = reinterpret_cast<uword>(pc);  // For the profiler.
  pp_ = bytecode->ptr()->object_pool_;

  // Cache some frequently used values in the frame.
  RawBool* true_value = Bool::True().raw();
  RawBool* false_value = Bool::False().raw();
  RawObject* null_value = Object::null();

#if defined(DEBUG)
  Function& function_h = Function::Handle();
#endif

  // Enter the dispatch loop.
  DISPATCH();

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
      if (reinterpret_cast<uword>(SP) >= stack_limit() ||
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
    BYTECODE(MoveSpecial, A_D);
    FP[rA] = special_[rD];
    DISPATCH();
  }

  {
    BYTECODE(BooleanNegateTOS, 0);
    SP[0] = (SP[0] == true_value) ? false_value : true_value;
    DISPATCH();
  }

  {
    BYTECODE(IndirectStaticCall, A_D);

    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }

    // Invoke target function.
    {
      const uint16_t argc = rA;
      // Look up the function in the ICData.
      RawObject* ic_data_obj = SP[0];
      RawICData* ic_data = RAW_CAST(ICData, ic_data_obj);
      RawObject** data = ic_data->ptr()->ic_data_->ptr()->data();
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
    BYTECODE(InstanceCall, A_D);

    // Check if single stepping.
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }

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
      case MethodRecognizer::kTypedDataLength: {
        RawInstance* instance = reinterpret_cast<RawInstance*>(SP[0]);
        SP[0] = reinterpret_cast<RawObject**>(
            instance->ptr())[TypedData::length_offset() / kWordSize];
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
          SP[1] = SP[0];   // length
          SP[2] = SP[-1];  // type
          Exit(thread, FP, SP + 3, pc);
          NativeArguments native_args(thread, 2, SP + 1, SP - 1);
          INVOKE_RUNTIME(DRT_AllocateArray, native_args);
          SP -= 1;  // Result is in SP - 1.
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
        SP[1] = SP[0];   // length
        SP[2] = SP[-1];  // type
        Exit(thread, FP, SP + 3, pc);
        NativeArguments native_args(thread, 2, SP + 1, SP - 1);
        INVOKE_RUNTIME(DRT_AllocateArray, native_args);
        SP -= 1;  // Result is in SP - 1.
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
        Exit(thread, FP, SP, pc);
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

  // Return and return like instructions (Intrinsic).
  {
    RawObject* result;  // result to return to the caller.

    BYTECODE(ReturnTOS, 0);
    result = *SP;
    // Restore caller PC.
    pc = SavedCallerPC(FP);
    pc_ = reinterpret_cast<uword>(pc);  // For the profiler.

    // Check if it is a fake PC marking the entry frame.
    if (IsEntryFrameMarker(reinterpret_cast<uword>(pc))) {
      // Pop entry frame.
      fp_ = SavedCallerFP(FP);
      // Restore exit frame info saved in entry frame.
      pp_ = reinterpret_cast<RawObjectPool*>(fp_[kKBCSavedPpSlotFromEntryFp]);
      argdesc_ =
          reinterpret_cast<RawArray*>(fp_[kKBCSavedArgDescSlotFromEntryFp]);
      uword exit_fp = reinterpret_cast<uword>(fp_[kKBCExitLinkSlotFromEntryFp]);
      thread->set_top_exit_frame_info(exit_fp);
      thread->set_top_resource(top_resource);
      thread->set_vm_tag(vm_tag);
#if defined(DEBUG)
      if (IsTracingExecution()) {
        THR_Print("%" Pu64 " ", icount_);
        THR_Print("Returning from interpreter 0x%" Px " at fp_ 0x%" Px
                  " exit 0x%" Px "\n",
                  reinterpret_cast<uword>(this), reinterpret_cast<uword>(fp_),
                  exit_fp);
      }
      ASSERT(reinterpret_cast<uword>(fp_) < stack_limit());
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
    pp_ = InterpreterHelpers::FrameCode(FP)->ptr()->object_pool_;
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
    const uword offset_in_words =
        static_cast<uword>(Smi::Value(RAW_CAST(Smi, LOAD_CONSTANT(rD))));
    RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
    RawObject* value = reinterpret_cast<RawObject*>(SP[0]);
    SP -= 2;  // Drop instance and value.

    // TODO(regis): Implement cid guard.
    ASSERT(!thread->isolate()->use_field_guards());

    instance->StorePointer(
        reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words, value,
        thread);

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

  // TODO(vegorov) allocation bytecodes can benefit from the new-space
  // allocation fast-path that does not transition into the runtime system.
  {
    BYTECODE(AllocateContext, A_D);
    const uint16_t num_context_variables = rD;
    {
      *++SP = 0;
      SP[1] = Smi::New(num_context_variables);
      Exit(thread, FP, SP + 2, pc);
      NativeArguments args(thread, 1, SP + 1, SP);
      INVOKE_RUNTIME(DRT_AllocateContext, args);
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
    SP[1] = 0;                  // Space for the result.
    SP[2] = LOAD_CONSTANT(rD);  // Class object.
    SP[3] = null_value;         // Type arguments.
    Exit(thread, FP, SP + 4, pc);
    NativeArguments args(thread, 2, SP + 2, SP + 1);
    INVOKE_RUNTIME(DRT_AllocateObject, args);
    SP++;  // Result is in SP[1].
    DISPATCH();
  }

  {
    BYTECODE(AllocateT, 0);
    SP[1] = SP[-0];  // Class object.
    SP[2] = SP[-1];  // Type arguments
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP - 1);
    INVOKE_RUNTIME(DRT_AllocateObject, args);
    SP -= 1;  // Result is in SP - 1.
    DISPATCH();
  }

  {
    BYTECODE(CreateArrayTOS, 0);
    SP[1] = SP[-0];  // Length.
    SP[2] = SP[-1];  // Type.
    Exit(thread, FP, SP + 3, pc);
    NativeArguments args(thread, 2, SP + 1, SP - 1);
    INVOKE_RUNTIME(DRT_AllocateArray, args);
    SP -= 1;
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
    BYTECODE(Trap, 0);
    UNIMPLEMENTED();
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

    const bool has_dart_caller =
        !IsEntryFrameMarker(reinterpret_cast<uword>(pc));
    const intptr_t argc = has_dart_caller ? KernelBytecode::DecodeArgc(pc[-1])
                                          : (reinterpret_cast<uword>(pc) >> 2);
    const intptr_t type_args_len =
        InterpreterHelpers::ArgDescTypeArgsLen(argdesc_);
    const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;

    SP = FrameArguments(FP, 0);
    RawObject** args = SP - argc;
    FP = SavedCallerFP(FP);
    if (has_dart_caller) {
      pp_ = InterpreterHelpers::FrameCode(FP)->ptr()->object_pool_;
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
    pp_ = InterpreterHelpers::FrameCode(FP)->ptr()->object_pool_;
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

  // Set the tag.
  thread->set_vm_tag(VMTag::kDartTagId);
  // Clear top exit frame.
  thread->set_top_exit_frame_info(0);

  fp_ = reinterpret_cast<RawObject**>(fp);

  if (pc == StubCode::RunExceptionHandler_entry()->EntryPoint()) {
    // The RunExceptionHandler stub is a placeholder.  We implement
    // its behavior here.
    RawObject* raw_exception = thread->active_exception();
    RawObject* raw_stacktrace = thread->active_stacktrace();
    ASSERT(raw_exception != Object::null());
    thread->set_active_exception(Object::null_object());
    thread->set_active_stacktrace(Object::null_object());
    special_[KernelBytecode::kExceptionSpecialIndex] = raw_exception;
    special_[KernelBytecode::kStackTraceSpecialIndex] = raw_stacktrace;
    pc_ = thread->resume_pc();
  } else {
    pc_ = pc;
  }

  buf->Longjmp();
  UNREACHABLE();
}

void Interpreter::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&pp_));
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&argdesc_));
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(TARGET_OS_WINDOWS)
