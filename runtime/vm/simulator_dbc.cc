// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#if !defined(USING_SIMULATOR)
#error "DBC is a simulated architecture"
#endif

#include "vm/simulator.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/constants_dbc.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/lockers.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(uint64_t,
            trace_sim_after,
            ULLONG_MAX,
            "Trace simulator execution after instruction count reached.");
DEFINE_FLAG(uint64_t,
            stop_sim_at,
            ULLONG_MAX,
            "Instruction address or instruction count to stop simulator at.");

#define LIKELY(cond) __builtin_expect((cond), 1)
#define UNLIKELY(cond) __builtin_expect((cond), 0)

// SimulatorSetjmpBuffer are linked together, and the last created one
// is referenced by the Simulator. When an exception is thrown, the exception
// runtime looks at where to jump and finds the corresponding
// SimulatorSetjmpBuffer based on the stack pointer of the exception handler.
// The runtime then does a Longjmp on that buffer to return to the simulator.
class SimulatorSetjmpBuffer {
 public:
  void Longjmp() {
    // "This" is now the last setjmp buffer.
    simulator_->set_last_setjmp_buffer(this);
    longjmp(buffer_, 1);
  }

  explicit SimulatorSetjmpBuffer(Simulator* sim) {
    simulator_ = sim;
    link_ = sim->last_setjmp_buffer();
    sim->set_last_setjmp_buffer(this);
    fp_ = sim->fp_;
  }

  ~SimulatorSetjmpBuffer() {
    ASSERT(simulator_->last_setjmp_buffer() == this);
    simulator_->set_last_setjmp_buffer(link_);
  }

  SimulatorSetjmpBuffer* link() const { return link_; }

  uword fp() const { return reinterpret_cast<uword>(fp_); }

  jmp_buf buffer_;

 private:
  RawObject** fp_;
  Simulator* simulator_;
  SimulatorSetjmpBuffer* link_;

  friend class Simulator;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(SimulatorSetjmpBuffer);
};

DART_FORCE_INLINE static RawObject** SavedCallerFP(RawObject** FP) {
  return reinterpret_cast<RawObject**>(FP[kSavedCallerFpSlotFromFp]);
}

DART_FORCE_INLINE static RawObject** FrameArguments(RawObject** FP,
                                                    intptr_t argc) {
  return FP - (kDartFrameFixedSize + argc);
}

#define RAW_CAST(Type, val) (SimulatorHelpers::CastTo##Type(val))

class SimulatorHelpers {
 public:
#define DEFINE_CASTS(Type)                                                     \
  DART_FORCE_INLINE static Raw##Type* CastTo##Type(RawObject* obj) {           \
    ASSERT((k##Type##Cid == kSmiCid) ? !obj->IsHeapObject()                    \
                                     : obj->Is##Type());                       \
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

          case kBigintCid:
            return (DLRT_BigintCompare(static_cast<RawBigint*>(lhs),
                                       static_cast<RawBigint*>(rhs)) == 0);
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
    if (thread->isolate()->type_checks()) {
      return false;
    }

    RawObject** args = FrameArguments(FP, 3);
    RawSmi* index = static_cast<RawSmi*>(args[1]);
    RawArray* array = static_cast<RawArray*>(args[0]);
    if (CheckIndex(index, array->ptr()->length_)) {
      array->StorePointer(array->ptr()->data() + Smi::Value(index), args[2]);
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
    if (thread->isolate()->type_checks()) {
      return false;
    }

    RawObject** args = FrameArguments(FP, 3);
    RawSmi* index = static_cast<RawSmi*>(args[1]);
    RawGrowableObjectArray* array =
        static_cast<RawGrowableObjectArray*>(args[0]);
    if (CheckIndex(index, array->ptr()->length_)) {
      RawArray* data = array->ptr()->data_;
      data->StorePointer(data->ptr()->data() + Smi::Value(index), args[2]);
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
    ASSERT(GetClassId(FP[kPcMarkerSlotFromFp]) == kCodeCid);
    return static_cast<RawCode*>(FP[kPcMarkerSlotFromFp]);
  }

  DART_FORCE_INLINE static void SetFrameCode(RawObject** FP, RawCode* code) {
    ASSERT(GetClassId(code) == kCodeCid);
    FP[kPcMarkerSlotFromFp] = code;
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
  return reinterpret_cast<uint32_t*>(FP[kSavedCallerPcSlotFromFp]);
}

DART_FORCE_INLINE static RawFunction* FrameFunction(RawObject** FP) {
  RawFunction* function = static_cast<RawFunction*>(FP[kFunctionSlotFromFp]);
  ASSERT(SimulatorHelpers::GetClassId(function) == kFunctionCid);
  return function;
}

IntrinsicHandler Simulator::intrinsics_[Simulator::kIntrinsicCount];

// Synchronization primitives support.
void Simulator::InitOnce() {
  for (intptr_t i = 0; i < kIntrinsicCount; i++) {
    intrinsics_[i] = 0;
  }

  intrinsics_[kObjectArraySetIndexedIntrinsic] =
      SimulatorHelpers::ObjectArraySetIndexed;
  intrinsics_[kObjectArrayGetIndexedIntrinsic] =
      SimulatorHelpers::ObjectArrayGetIndexed;
  intrinsics_[kGrowableArraySetIndexedIntrinsic] =
      SimulatorHelpers::GrowableArraySetIndexed;
  intrinsics_[kGrowableArrayGetIndexedIntrinsic] =
      SimulatorHelpers::GrowableArrayGetIndexed;
  intrinsics_[kObjectEqualsIntrinsic] = SimulatorHelpers::ObjectEquals;
  intrinsics_[kObjectRuntimeTypeIntrinsic] =
      SimulatorHelpers::ObjectRuntimeType;

  intrinsics_[kDouble_getIsNaNIntrinsic] = SimulatorHelpers::Double_getIsNan;
  intrinsics_[kDouble_getIsInfiniteIntrinsic] =
      SimulatorHelpers::Double_getIsInfinite;
  intrinsics_[kDouble_addIntrinsic] = SimulatorHelpers::Double_add;
  intrinsics_[kDouble_mulIntrinsic] = SimulatorHelpers::Double_mul;
  intrinsics_[kDouble_subIntrinsic] = SimulatorHelpers::Double_sub;
  intrinsics_[kDouble_divIntrinsic] = SimulatorHelpers::Double_div;
  intrinsics_[kDouble_greaterThanIntrinsic] =
      SimulatorHelpers::Double_greaterThan;
  intrinsics_[kDouble_greaterEqualThanIntrinsic] =
      SimulatorHelpers::Double_greaterEqualThan;
  intrinsics_[kDouble_lessThanIntrinsic] = SimulatorHelpers::Double_lessThan;
  intrinsics_[kDouble_equalIntrinsic] = SimulatorHelpers::Double_equal;
  intrinsics_[kDouble_lessEqualThanIntrinsic] =
      SimulatorHelpers::Double_lessEqualThan;
  intrinsics_[kClearAsyncThreadStackTraceIntrinsic] =
      SimulatorHelpers::ClearAsyncThreadStack;
  intrinsics_[kSetAsyncThreadStackTraceIntrinsic] =
      SimulatorHelpers::SetAsyncThreadStackTrace;
}

Simulator::Simulator() : stack_(NULL), fp_(NULL) {
  // Setup simulator support first. Some of this information is needed to
  // setup the architecture state.
  // We allocate the stack here, the size is computed as the sum of
  // the size specified by the user and the buffer space needed for
  // handling stack overflow exceptions. To be safe in potential
  // stack underflows we also add some underflow buffer space.
  stack_ = new uintptr_t[(OSThread::GetSpecifiedStackSize() +
                          OSThread::kStackSizeBuffer +
                          kSimulatorStackUnderflowSize) /
                         sizeof(uintptr_t)];
  last_setjmp_buffer_ = NULL;
  top_exit_frame_info_ = 0;

  NOT_IN_PRODUCT(icount_ = 0;)
}

Simulator::~Simulator() {
  delete[] stack_;
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    isolate->set_simulator(NULL);
  }
}

// Get the active Simulator for the current isolate.
Simulator* Simulator::Current() {
  Simulator* simulator = Isolate::Current()->simulator();
  if (simulator == NULL) {
    simulator = new Simulator();
    Isolate::Current()->set_simulator(simulator);
  }
  return simulator;
}

// Returns the top of the stack area to enable checking for stack pointer
// validity.
uword Simulator::StackTop() const {
  // To be safe in potential stack underflows we leave some buffer above and
  // set the stack top.
  return StackBase() +
         (OSThread::GetSpecifiedStackSize() + OSThread::kStackSizeBuffer);
}

#if !defined(PRODUCT)
// Returns true if tracing of executed instructions is enabled.
DART_FORCE_INLINE bool Simulator::IsTracingExecution() const {
  return icount_ > FLAG_trace_sim_after;
}

// Prints bytecode instruction at given pc for instruction tracing.
DART_NOINLINE void Simulator::TraceInstruction(uint32_t* pc) const {
  THR_Print("%" Pu64 " ", icount_);
  if (FLAG_support_disassembler) {
    Disassembler::Disassemble(reinterpret_cast<uword>(pc),
                              reinterpret_cast<uword>(pc + 1));
  } else {
    THR_Print("Disassembler not supported in this mode.\n");
  }
}
#endif  // !defined(PRODUCT)

// Calls into the Dart runtime are based on this interface.
typedef void (*SimulatorRuntimeCall)(NativeArguments arguments);

// Calls to leaf Dart runtime functions are based on this interface.
typedef intptr_t (*SimulatorLeafRuntimeCall)(intptr_t r0,
                                             intptr_t r1,
                                             intptr_t r2,
                                             intptr_t r3);

// Calls to leaf float Dart runtime functions are based on this interface.
typedef double (*SimulatorLeafFloatRuntimeCall)(double d0, double d1);

// Calls to native Dart functions are based on this interface.
typedef void (*SimulatorBootstrapNativeCall)(NativeArguments* arguments);
typedef void (*SimulatorNativeCall)(NativeArguments* arguments, uword target);

void Simulator::Exit(Thread* thread,
                     RawObject** base,
                     RawObject** frame,
                     uint32_t* pc) {
  frame[0] = Function::null();
  frame[1] = Code::null();
  frame[2] = reinterpret_cast<RawObject*>(pc);
  frame[3] = reinterpret_cast<RawObject*>(base);
  fp_ = frame + kDartFrameFixedSize;
  thread->set_top_exit_frame_info(reinterpret_cast<uword>(fp_));
}

// TODO(vegorov): Investigate advantages of using
// __builtin_s{add,sub,mul}_overflow() intrinsics here and below.
// Note that they may clobber the output location even when there is overflow:
// https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html
DART_FORCE_INLINE static bool SignedAddWithOverflow(intptr_t lhs,
                                                    intptr_t rhs,
                                                    intptr_t* out) {
  intptr_t res = 1;
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  asm volatile(
      "add %2, %1\n"
      "jo 1f;\n"
      "xor %0, %0\n"
      "mov %1, 0(%3)\n"
      "1: "
      : "+r"(res), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc");
#elif defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
  asm volatile(
      "adds %1, %1, %2;\n"
      "bvs 1f;\n"
      "mov %0, #0;\n"
      "str %1, [%3, #0]\n"
      "1:"
      : "+r"(res), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc");
#else
#error "Unsupported platform"
#endif
  return (res != 0);
}

DART_FORCE_INLINE static bool SignedSubWithOverflow(intptr_t lhs,
                                                    intptr_t rhs,
                                                    intptr_t* out) {
  intptr_t res = 1;
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  asm volatile(
      "sub %2, %1\n"
      "jo 1f;\n"
      "xor %0, %0\n"
      "mov %1, 0(%3)\n"
      "1: "
      : "+r"(res), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc");
#elif defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
  asm volatile(
      "subs %1, %1, %2;\n"
      "bvs 1f;\n"
      "mov %0, #0;\n"
      "str %1, [%3, #0]\n"
      "1:"
      : "+r"(res), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc");
#else
#error "Unsupported platform"
#endif
  return (res != 0);
}

DART_FORCE_INLINE static bool SignedMulWithOverflow(intptr_t lhs,
                                                    intptr_t rhs,
                                                    intptr_t* out) {
  intptr_t res = 1;
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  asm volatile(
      "imul %2, %1\n"
      "jo 1f;\n"
      "xor %0, %0\n"
      "mov %1, 0(%3)\n"
      "1: "
      : "+r"(res), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc");
#elif defined(HOST_ARCH_ARM)
  asm volatile(
      "smull %1, ip, %1, %2;\n"
      "cmp ip, %1, ASR #31;\n"
      "bne 1f;\n"
      "mov %0, $0;\n"
      "str %1, [%3, #0]\n"
      "1:"
      : "+r"(res), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc", "r12");
#elif defined(HOST_ARCH_ARM64)
  int64_t prod_lo = 0;
  asm volatile(
      "mul %1, %2, %3\n"
      "smulh %2, %2, %3\n"
      "cmp %2, %1, ASR #63;\n"
      "bne 1f;\n"
      "mov %0, #0;\n"
      "str %1, [%4, #0]\n"
      "1:"
      : "=r"(res), "+r"(prod_lo), "+r"(lhs)
      : "r"(rhs), "r"(out)
      : "cc");
#else
#error "Unsupported platform"
#endif
  return (res != 0);
}

DART_FORCE_INLINE static bool AreBothSmis(intptr_t a, intptr_t b) {
  return ((a | b) & kHeapObjectTag) == 0;
}

#define SMI_MUL(lhs, rhs, pres) SignedMulWithOverflow((lhs), (rhs) >> 1, pres)
#define SMI_COND(cond, lhs, rhs, pres)                                         \
  ((*(pres) = ((lhs cond rhs) ? true_value : false_value)), false)
#define SMI_EQ(lhs, rhs, pres) SMI_COND(==, lhs, rhs, pres)
#define SMI_LT(lhs, rhs, pres) SMI_COND(<, lhs, rhs, pres)
#define SMI_GT(lhs, rhs, pres) SMI_COND(>, lhs, rhs, pres)
#define SMI_BITOR(lhs, rhs, pres) ((*(pres) = (lhs | rhs)), false)
#define SMI_BITAND(lhs, rhs, pres) ((*(pres) = ((lhs) & (rhs))), false)
#define SMI_BITXOR(lhs, rhs, pres) ((*(pres) = ((lhs) ^ (rhs))), false)

void Simulator::CallRuntime(Thread* thread,
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
  RawObject** fp = *SP + kDartFrameFixedSize;
  fp[kPcMarkerSlotFromFp] = 0;
  fp[kSavedCallerPcSlotFromFp] = reinterpret_cast<RawObject*>(pc);
  fp[kSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(*FP);
  *FP = fp;
  *SP = fp - 1;
}

DART_FORCE_INLINE static void LeaveSyntheticFrame(RawObject*** FP,
                                                  RawObject*** SP) {
  RawObject** fp = *FP;
  *FP = reinterpret_cast<RawObject**>(fp[kSavedCallerFpSlotFromFp]);
  *SP = fp - kDartFrameFixedSize;
}

DART_FORCE_INLINE void Simulator::Invoke(Thread* thread,
                                         RawObject** call_base,
                                         RawObject** call_top,
                                         RawObjectPool** pp,
                                         uint32_t** pc,
                                         RawObject*** FP,
                                         RawObject*** SP) {
  RawObject** callee_fp = call_top + kDartFrameFixedSize;

  RawFunction* function = FrameFunction(callee_fp);
  RawCode* code = function->ptr()->code_;
  callee_fp[kPcMarkerSlotFromFp] = code;
  callee_fp[kSavedCallerPcSlotFromFp] = reinterpret_cast<RawObject*>(*pc);
  callee_fp[kSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(*FP);
  *pp = code->ptr()->object_pool_->ptr();
  *pc = reinterpret_cast<uint32_t*>(code->ptr()->entry_point_);
  pc_ = reinterpret_cast<uword>(*pc);  // For the profiler.
  *FP = callee_fp;
  *SP = *FP - 1;
}

void Simulator::InlineCacheMiss(int checked_args,
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

DART_FORCE_INLINE void Simulator::InstanceCall1(Thread* thread,
                                                RawICData* icdata,
                                                RawObject** call_base,
                                                RawObject** top,
                                                RawArray** argdesc,
                                                RawObjectPool** pp,
                                                uint32_t** pc,
                                                RawObject*** FP,
                                                RawObject*** SP,
                                                bool optimized) {
  ASSERT(icdata->GetClassId() == kICDataCid);

  const intptr_t kCheckedArgs = 1;
  RawObject** args = call_base;
  RawArray* cache = icdata->ptr()->ic_data_->ptr();

  const intptr_t type_args_len =
      SimulatorHelpers::ArgDescTypeArgsLen(icdata->ptr()->args_descriptor_);
  const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
  RawSmi* receiver_cid = SimulatorHelpers::GetClassIdAsSmi(args[receiver_idx]);

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

  if (found) {
    if (!optimized) {
      SimulatorHelpers::IncrementICUsageCount(cache->data(), i, kCheckedArgs);
    }
  } else {
    InlineCacheMiss(kCheckedArgs, thread, icdata, call_base + receiver_idx, top,
                    *pc, *FP, *SP);
  }

  *argdesc = icdata->ptr()->args_descriptor_;
  Invoke(thread, call_base, top, pp, pc, FP, SP);
}

DART_FORCE_INLINE void Simulator::InstanceCall2(Thread* thread,
                                                RawICData* icdata,
                                                RawObject** call_base,
                                                RawObject** top,
                                                RawArray** argdesc,
                                                RawObjectPool** pp,
                                                uint32_t** pc,
                                                RawObject*** FP,
                                                RawObject*** SP,
                                                bool optimized) {
  ASSERT(icdata->GetClassId() == kICDataCid);

  const intptr_t kCheckedArgs = 2;
  RawObject** args = call_base;
  RawArray* cache = icdata->ptr()->ic_data_->ptr();

  const intptr_t type_args_len =
      SimulatorHelpers::ArgDescTypeArgsLen(icdata->ptr()->args_descriptor_);
  const intptr_t receiver_idx = type_args_len > 0 ? 1 : 0;
  RawSmi* receiver_cid = SimulatorHelpers::GetClassIdAsSmi(args[receiver_idx]);
  RawSmi* arg0_cid = SimulatorHelpers::GetClassIdAsSmi(args[receiver_idx + 1]);

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

  if (found) {
    if (!optimized) {
      SimulatorHelpers::IncrementICUsageCount(cache->data(), i, kCheckedArgs);
    }
  } else {
    InlineCacheMiss(kCheckedArgs, thread, icdata, call_base + receiver_idx, top,
                    *pc, *FP, *SP);
  }

  *argdesc = icdata->ptr()->args_descriptor_;
  Invoke(thread, call_base, top, pp, pc, FP, SP);
}

// Note: functions below are marked DART_NOINLINE to recover performance on
// ARM where inlining these functions into the interpreter loop seemed to cause
// some code quality issues.
static DART_NOINLINE bool InvokeRuntime(Thread* thread,
                                        Simulator* sim,
                                        RuntimeFunction drt,
                                        const NativeArguments& args) {
  SimulatorSetjmpBuffer buffer(sim);
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

static DART_NOINLINE bool InvokeBootstrapNative(Thread* thread,
                                                Simulator* sim,
                                                SimulatorBootstrapNativeCall f,
                                                NativeArguments* args) {
  SimulatorSetjmpBuffer buffer(sim);
  if (!setjmp(buffer.buffer_)) {
    thread->set_vm_tag(reinterpret_cast<uword>(f));
    f(args);
    thread->set_vm_tag(VMTag::kDartTagId);
    thread->set_top_exit_frame_info(0);
    return true;
  } else {
    return false;
  }
}

static DART_NOINLINE bool InvokeNativeNoScopeWrapper(Thread* thread,
                                                     Simulator* sim,
                                                     Dart_NativeFunction f,
                                                     NativeArguments* args) {
  SimulatorSetjmpBuffer buffer(sim);
  if (!setjmp(buffer.buffer_)) {
    thread->set_vm_tag(reinterpret_cast<uword>(f));
    NativeEntry::NoScopeNativeCallWrapper(
        reinterpret_cast<Dart_NativeArguments>(args), f);
    thread->set_vm_tag(VMTag::kDartTagId);
    thread->set_top_exit_frame_info(0);
    return true;
  } else {
    return false;
  }
}

static DART_NOINLINE bool InvokeNativeAutoScopeWrapper(Thread* thread,
                                                       Simulator* sim,
                                                       Dart_NativeFunction f,
                                                       NativeArguments* args) {
  SimulatorSetjmpBuffer buffer(sim);
  if (!setjmp(buffer.buffer_)) {
    thread->set_vm_tag(reinterpret_cast<uword>(f));
    NativeEntry::AutoScopeNativeCallWrapper(
        reinterpret_cast<Dart_NativeArguments>(args), f);
    thread->set_vm_tag(VMTag::kDartTagId);
    thread->set_top_exit_frame_info(0);
    return true;
  } else {
    return false;
  }
}

// Note: all macro helpers are intended to be used only inside Simulator::Call.

// Counts and prints executed bytecode instructions (in a non-PRODUCT mode).
#if !defined(PRODUCT)
#define TRACE_INSTRUCTION                                                      \
  icount_++;                                                                   \
  if (IsTracingExecution()) {                                                  \
    TraceInstruction(pc - 1);                                                  \
  }
#else
#define TRACE_INSTRUCTION
#endif  // !defined(PRODUCT)

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
  rB = ((op >> Bytecode::kBShift) & Bytecode::kBMask);                         \
  rC = ((op >> Bytecode::kCShift) & Bytecode::kCMask);

#define DECLARE_0
#define DECODE_0

#define DECLARE_A
#define DECODE_A

#define DECLARE___D                                                            \
  uint32_t rD;                                                                 \
  USE(rD)
#define DECODE___D rD = (op >> Bytecode::kDShift);

#define DECLARE_A_D DECLARE___D
#define DECODE_A_D DECODE___D

#define DECLARE_A_X                                                            \
  int32_t rD;                                                                  \
  USE(rD)
#define DECODE_A_X rD = (static_cast<int32_t>(op) >> Bytecode::kDShift);

#define SMI_FASTPATH_ICDATA_INC                                                \
  do {                                                                         \
    ASSERT(Bytecode::IsCallOpcode(*pc));                                       \
    const uint16_t kidx = Bytecode::DecodeD(*pc);                              \
    const RawICData* icdata = RAW_CAST(ICData, LOAD_CONSTANT(kidx));           \
    RawObject** entries = icdata->ptr()->ic_data_->ptr()->data();              \
    SimulatorHelpers::IncrementICUsageCount(entries, 0, 2);                    \
  } while (0);

// Declare bytecode handler for a smi operation (e.g. AddTOS) with the
// given result type and the given behavior specified as a function
// that takes left and right operands and result slot and returns
// true if fast-path succeeds.
#define SMI_FASTPATH_TOS(ResultT, Func)                                        \
  {                                                                            \
    const intptr_t lhs = reinterpret_cast<intptr_t>(SP[-1]);                   \
    const intptr_t rhs = reinterpret_cast<intptr_t>(SP[-0]);                   \
    ResultT* slot = reinterpret_cast<ResultT*>(SP - 1);                        \
    if (LIKELY(!thread->isolate()->single_step()) &&                           \
        LIKELY(AreBothSmis(lhs, rhs) && !Func(lhs, rhs, slot))) {              \
      SMI_FASTPATH_ICDATA_INC;                                                 \
      /* Fast path succeeded. Skip the generic call that follows. */           \
      pc++;                                                                    \
      /* We dropped 2 arguments and push result                   */           \
      SP--;                                                                    \
    }                                                                          \
  }

// Skip the next instruction if there is no overflow.
#define SMI_OP_CHECK(ResultT, Func)                                            \
  {                                                                            \
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);                   \
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]);                   \
    ResultT* slot = reinterpret_cast<ResultT*>(&FP[rA]);                       \
    if (LIKELY(!Func(lhs, rhs, slot))) {                                       \
      /* Success. Skip the instruction that follows. */                        \
      pc++;                                                                    \
    }                                                                          \
  }

// Do not check for overflow.
#define SMI_OP_NOCHECK(ResultT, Func)                                          \
  {                                                                            \
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);                   \
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]);                   \
    ResultT* slot = reinterpret_cast<ResultT*>(&FP[rA]);                       \
    Func(lhs, rhs, slot);                                                      \
  }

// Exception handling helper. Gets handler FP and PC from the Simulator where
// they were stored by Simulator::Longjmp and proceeds to execute the handler.
// Corner case: handler PC can be a fake marker that marks entry frame, which
// means exception was not handled in the Dart code. In this case we return
// caught exception from Simulator::Call.
#define HANDLE_EXCEPTION                                                       \
  do {                                                                         \
    FP = reinterpret_cast<RawObject**>(fp_);                                   \
    pc = reinterpret_cast<uint32_t*>(pc_);                                     \
    if ((reinterpret_cast<uword>(pc) & 2) != 0) { /* Entry frame? */           \
      fp_ = reinterpret_cast<RawObject**>(fp_[0]);                             \
      thread->set_top_exit_frame_info(reinterpret_cast<uword>(fp_));           \
      thread->set_top_resource(top_resource);                                  \
      thread->set_vm_tag(vm_tag);                                              \
      return special_[kExceptionSpecialIndex];                                 \
    }                                                                          \
    pp = SimulatorHelpers::FrameCode(FP)->ptr()->object_pool_->ptr();          \
    goto DispatchAfterException;                                               \
  } while (0)

// Runtime call helpers: handle invocation and potential exception after return.
#define INVOKE_RUNTIME(Func, Args)                                             \
  if (!InvokeRuntime(thread, this, Func, Args)) {                              \
    HANDLE_EXCEPTION;                                                          \
  }

#define INVOKE_BOOTSTRAP_NATIVE(Func, Args)                                    \
  if (!InvokeBootstrapNative(thread, this, Func, &Args)) {                     \
    HANDLE_EXCEPTION;                                                          \
  }

#define INVOKE_NATIVE_NO_SCOPE(Func, Args)                                     \
  if (!InvokeNativeNoScopeWrapper(thread, this, Func, &Args)) {                \
    HANDLE_EXCEPTION;                                                          \
  }

#define INVOKE_NATIVE_AUTO_SCOPE(Func, Args)                                   \
  if (!InvokeNativeAutoScopeWrapper(thread, this, Func, &Args)) {              \
    HANDLE_EXCEPTION;                                                          \
  }

#define LOAD_CONSTANT(index) (pp->data()[(index)].raw_obj_)

// Returns true if deoptimization succeeds.
DART_FORCE_INLINE bool Simulator::Deoptimize(Thread* thread,
                                             RawObjectPool** pp,
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
  ASSERT((reinterpret_cast<uword>(*pc) & 2) == 0);

  // Restore SP, FP and PP.
  // Unoptimized frame SP is one below FrameArguments(...) because
  // FrameArguments(...) returns a pointer to the first argument.
  *SP = FrameArguments(*FP, materialization_arg_count) - 1;
  *FP = SavedCallerFP(*FP);

  // Restore pp.
  *pp = SimulatorHelpers::FrameCode(*FP)->ptr()->object_pool_->ptr();

  return true;
}

RawObject* Simulator::Call(const Code& code,
                           const Array& arguments_descriptor,
                           const Array& arguments,
                           Thread* thread) {
  // Dispatch used to interpret bytecode. Contains addresses of
  // labels of bytecode handlers. Handlers themselves are defined below.
  static const void* dispatch[] = {
#define TARGET(name, fmt, fmta, fmtb, fmtc) &&bc##name,
      BYTECODES_LIST(TARGET)
#undef TARGET
  };

  // Interpreter state (see constants_dbc.h for high-level overview).
  uint32_t* pc;       // Program Counter: points to the next op to execute.
  RawObjectPool* pp;  // Pool Pointer.
  RawObject** FP;     // Frame Pointer.
  RawObject** SP;     // Stack Pointer.

  RawArray* argdesc;  // Arguments Descriptor: used to pass information between
                      // call instruction and the function entry.

  uint32_t op;  // Currently executing op.
  uint16_t rA;  // A component of the currently executing op.

  if (fp_ == NULL) {
    fp_ = reinterpret_cast<RawObject**>(stack_);
  }

  // Save current VM tag and mark thread as executing Dart code.
  const uword vm_tag = thread->vm_tag();
  thread->set_vm_tag(VMTag::kDartTagId);

  // Save current top stack resource and reset the list.
  StackResource* top_resource = thread->top_resource();
  thread->set_top_resource(NULL);

  // Setup entry frame:
  //
  //                        ^
  //                        |  previous Dart frames
  //       ~~~~~~~~~~~~~~~  |
  //       | ........... | -+
  // fp_ > |             |     saved top_exit_frame_info
  //       | arg 0       | -+
  //       ~~~~~~~~~~~~~~~  |
  //                         > incoming arguments
  //       ~~~~~~~~~~~~~~~  |
  //       | arg 1       | -+
  //       | function    | -+
  //       | code        |  |
  //       | callee PC   | ---> special fake PC marking an entry frame
  //  SP > | fp_         |  |
  //  FP > | ........... |   > normal Dart frame (see stack_frame_dbc.h)
  //                        |
  //                        v
  //
  FP = fp_ + 1 + arguments.Length() + kDartFrameFixedSize;
  SP = FP - 1;

  // Save outer top_exit_frame_info.
  fp_[0] = reinterpret_cast<RawObject*>(thread->top_exit_frame_info());
  thread->set_top_exit_frame_info(0);

  // Copy arguments and setup the Dart frame.
  const intptr_t argc = arguments.Length();
  for (intptr_t i = 0; i < argc; i++) {
    fp_[1 + i] = arguments.At(i);
  }

  FP[kFunctionSlotFromFp] = code.function();
  FP[kPcMarkerSlotFromFp] = code.raw();
  FP[kSavedCallerPcSlotFromFp] = reinterpret_cast<RawObject*>((argc << 2) | 2);
  FP[kSavedCallerFpSlotFromFp] = reinterpret_cast<RawObject*>(fp_);

  // Load argument descriptor.
  argdesc = arguments_descriptor.raw();
  ASSERT(ArgumentsDescriptor(arguments_descriptor).TypeArgsLen() == 0);

  // Ready to start executing bytecode. Load entry point and corresponding
  // object pool.
  pc = reinterpret_cast<uint32_t*>(code.raw()->ptr()->entry_point_);
  pc_ = reinterpret_cast<uword>(pc);  // For the profiler.
  pp = code.object_pool()->ptr();

  // Cache some frequently used values in the frame.
  RawBool* true_value = Bool::True().raw();
  RawBool* false_value = Bool::False().raw();
  RawObject* null_value = Object::null();
  RawObject* empty_context = Object::empty_context().raw();

#if defined(DEBUG)
  Function& function_h = Function::Handle();
#endif

  // Enter the dispatch loop.
  DISPATCH();

  // Bytecode handlers (see constants_dbc.h for bytecode descriptions).
  {
    BYTECODE(Entry, A_B_C);
    const uint8_t num_fixed_params = rA;
    const uint16_t num_locals = rB;
    const uint16_t context_reg = rC;

    // Decode arguments descriptor.
    const intptr_t pos_count = SimulatorHelpers::ArgDescPosCount(argdesc);

    // Check that we got the right number of positional parameters.
    if (pos_count != num_fixed_params) {
      // Mismatch can only occur if current function is a closure.
      goto ClosureNoSuchMethod;
    }

    // Initialize locals with null and set current context variable to
    // empty context.
    {
      RawObject** L = FP;
      for (intptr_t i = 0; i < num_locals; i++) {
        L[i] = null_value;
      }
      L[context_reg] = empty_context;
      SP = FP + num_locals - 1;
    }

    DISPATCH();
  }

  {
    BYTECODE(EntryOptimized, A_D);
    const uint8_t num_fixed_params = rA;
    const uint16_t num_registers = rD;

    // Decode arguments descriptor.
    const intptr_t pos_count = SimulatorHelpers::ArgDescPosCount(argdesc);

    // Check that we got the right number of positional parameters.
    if (pos_count != num_fixed_params) {
      // Mismatch can only occur if current function is a closure.
      goto ClosureNoSuchMethod;
    }

    // Reserve space for registers used by the optimized code.
    SP = FP + num_registers - 1;

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
    const intptr_t arg_count = SimulatorHelpers::ArgDescArgCount(argdesc);
    const intptr_t pos_count = SimulatorHelpers::ArgDescPosCount(argdesc);
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
      RawObject** argdesc_data = argdesc->ptr()->data();

      intptr_t i = named_count - 1;           // argument position
      intptr_t j = num_opt_named_params - 1;  // parameter position
      while ((j >= 0) && (i >= 0)) {
        // Fetch formal parameter information: name, default value, target slot.
        const uint32_t load_name = pc[2 * j];
        const uint32_t load_value = pc[2 * j + 1];
        ASSERT(Bytecode::DecodeOpcode(load_name) == Bytecode::kLoadConstant);
        ASSERT(Bytecode::DecodeOpcode(load_value) == Bytecode::kLoadConstant);
        const uint8_t reg = Bytecode::DecodeA(load_name);
        ASSERT(reg == Bytecode::DecodeA(load_value));

        RawString* name = static_cast<RawString*>(
            LOAD_CONSTANT(Bytecode::DecodeD(load_name)));
        if (name == argdesc_data[ArgumentsDescriptor::name_index(i)]) {
          // Parameter was passed. Fetch passed value.
          const intptr_t arg_index = Smi::Value(static_cast<RawSmi*>(
              argdesc_data[ArgumentsDescriptor::position_index(i)]));
          FP[reg] = first_arg[arg_index];
          i--;  // Consume passed argument.
        } else {
          // Parameter was not passed. Fetch default value.
          FP[reg] = LOAD_CONSTANT(Bytecode::DecodeD(load_value));
        }
        j--;  // Next formal parameter.
      }

      // If we have unprocessed formal parameters then initialize them all
      // using default values.
      while (j >= 0) {
        const uint32_t load_name = pc[2 * j];
        const uint32_t load_value = pc[2 * j + 1];
        ASSERT(Bytecode::DecodeOpcode(load_name) == Bytecode::kLoadConstant);
        ASSERT(Bytecode::DecodeOpcode(load_value) == Bytecode::kLoadConstant);
        const uint8_t reg = Bytecode::DecodeA(load_name);
        ASSERT(reg == Bytecode::DecodeA(load_value));

        FP[reg] = LOAD_CONSTANT(Bytecode::DecodeD(load_value));
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
        ASSERT(Bytecode::DecodeOpcode(load_value) == Bytecode::kLoadConstant);
#if defined(DEBUG)
        const uint8_t reg = Bytecode::DecodeA(load_value);
        ASSERT((num_fixed_params + i) == reg);
#endif
        FP[num_fixed_params + i] = LOAD_CONSTANT(Bytecode::DecodeD(load_value));
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
    BYTECODE(Compile, 0);
    FP[0] = FrameFunction(FP);
    FP[1] = 0;
    Exit(thread, FP, FP + 2, pc);
    NativeArguments args(thread, 1, FP, FP + 1);
    INVOKE_RUNTIME(DRT_CompileFunction, args);
    {
      // Function should be compiled now, dispatch to its entry point.
      RawCode* code = FrameFunction(FP)->ptr()->code_;
      SimulatorHelpers::SetFrameCode(FP, code);
      pp = code->ptr()->object_pool_->ptr();
      pc = reinterpret_cast<uint32_t*>(code->ptr()->entry_point_);
      pc_ = reinterpret_cast<uword>(pc);  // For the profiler.
    }
    DISPATCH();
  }

  {
    BYTECODE(HotCheck, A_D);
    const uint8_t increment = rA;
    const uint16_t threshold = rD;
    RawFunction* f = FrameFunction(FP);
    int32_t counter = f->ptr()->usage_counter_;
    // Note: we don't increment usage counter in the prologue of optimized
    // functions.
    if (increment) {
      counter += increment;
      f->ptr()->usage_counter_ = counter;
    }
    if (UNLIKELY(counter >= threshold)) {
      FP[0] = f;
      FP[1] = 0;

      // Make the DRT_OptimizeInvokedFunction see a stub as its caller for
      // consistency with the other architectures, and to avoid needing to
      // generate a stackmap for the HotCheck pc.
      const StubEntry* stub = StubCode::OptimizeFunction_entry();
      FP[kPcMarkerSlotFromFp] = stub->code();
      pc = reinterpret_cast<uint32_t*>(stub->EntryPoint());

      Exit(thread, FP, FP + 2, pc);
      NativeArguments args(thread, 1, FP, FP + 1);
      INVOKE_RUNTIME(DRT_OptimizeInvokedFunction, args);
      {
        // DRT_OptimizeInvokedFunction returns the code object to execute.
        ASSERT(FP[1]->GetClassId() == kFunctionCid);
        RawFunction* function = static_cast<RawFunction*>(FP[1]);
        RawCode* code = function->ptr()->code_;
        SimulatorHelpers::SetFrameCode(FP, code);
        pp = code->ptr()->object_pool_->ptr();
        pc = reinterpret_cast<uint32_t*>(function->ptr()->entry_point_);
        pc_ = reinterpret_cast<uword>(pc);  // For the profiler.
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckStack, A);
    {
      if (reinterpret_cast<uword>(SP) >= thread->stack_limit()) {
        Exit(thread, FP, SP + 1, pc);
        NativeArguments args(thread, 0, NULL, NULL);
        INVOKE_RUNTIME(DRT_StackOverflow, args);
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckStackAlwaysExit, A);
    {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_StackOverflow, args);
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckFunctionTypeArgs, A_D);
    const uint16_t declared_type_args_len = rA;
    const uint16_t first_stack_local_index = rD;

    // Decode arguments descriptor's type args len.
    const intptr_t type_args_len =
        SimulatorHelpers::ArgDescTypeArgsLen(argdesc);
    if ((type_args_len != declared_type_args_len) && (type_args_len != 0)) {
      goto ClosureNoSuchMethod;
    }
    if (type_args_len > 0) {
      // Decode arguments descriptor's argument count (excluding type args).
      const intptr_t arg_count = SimulatorHelpers::ArgDescArgCount(argdesc);
      // Copy passed-in type args to first local slot.
      FP[first_stack_local_index] = *FrameArguments(FP, arg_count + 1);
    } else if (declared_type_args_len > 0) {
      FP[first_stack_local_index] = Object::null();
    }
    DISPATCH();
  }

  {
    BYTECODE(DebugStep, A);
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }
    DISPATCH();
  }

  {
    BYTECODE(DebugBreak, A);
#if !defined(PRODUCT)
    {
      const uint32_t original_bc =
          static_cast<uint32_t>(reinterpret_cast<uintptr_t>(
              thread->isolate()->debugger()->GetPatchedStubAddress(
                  reinterpret_cast<uword>(pc))));

      SP[1] = null_value;
      Exit(thread, FP, SP + 2, pc);
      NativeArguments args(thread, 0, NULL, SP + 1);
      INVOKE_RUNTIME(DRT_BreakpointRuntimeHandler, args)
      DISPATCH_OP(original_bc);
    }
#else
    // There should be no debug breaks in product mode.
    UNREACHABLE();
#endif
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
    BYTECODE(Drop, 0);
    SP -= rA;
    DISPATCH();
  }

  {
    BYTECODE(DropR, 0);
    RawObject* result = SP[0];
    SP -= rA;
    SP[0] = result;
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
    BYTECODE(Push, A_X);
    *++SP = FP[rD];
    DISPATCH();
  }

  {
    BYTECODE(Move, A_X);
    FP[rA] = FP[rD];
    DISPATCH();
  }

  {
    BYTECODE(Swap, A_X);
    RawObject* tmp = FP[rD];
    FP[rD] = FP[rA];
    FP[rA] = tmp;
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
    BYTECODE(BooleanNegate, A_D);
    FP[rA] = (FP[rD] == true_value) ? false_value : true_value;
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
      SimulatorHelpers::IncrementICUsageCount(data, 0, 0);
      SP[0] = data[ICData::TargetIndexFor(ic_data->ptr()->state_bits_ & 0x3)];
      RawObject** call_base = SP - argc;
      RawObject** call_top = SP;  // *SP contains function
      argdesc = static_cast<RawArray*>(LOAD_CONSTANT(rD));
      Invoke(thread, call_base, call_top, &pp, &pc, &FP, &SP);
    }

    DISPATCH();
  }

  {
    BYTECODE(StaticCall, A_D);
    const uint16_t argc = rA;
    RawObject** call_base = SP - argc;
    RawObject** call_top = SP;  // *SP contains function
    argdesc = static_cast<RawArray*>(LOAD_CONSTANT(rD));
    Invoke(thread, call_base, call_top, &pp, &pc, &FP, &SP);
    DISPATCH();
  }

  {
    BYTECODE(InstanceCall1, A_D);

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
      SimulatorHelpers::IncrementUsageCounter(
          RAW_CAST(Function, icdata->ptr()->owner_));
      InstanceCall1(thread, icdata, call_base, call_top, &argdesc, &pp, &pc,
                    &FP, &SP, false /* optimized */);
    }

    DISPATCH();
  }

  {
    BYTECODE(InstanceCall2, A_D);
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
      SimulatorHelpers::IncrementUsageCounter(
          RAW_CAST(Function, icdata->ptr()->owner_));
      InstanceCall2(thread, icdata, call_base, call_top, &argdesc, &pp, &pc,
                    &FP, &SP, false /* optimized */);
    }

    DISPATCH();
  }

  {
    BYTECODE(InstanceCall1Opt, A_D);

    {
      const uint16_t argc = rA;
      const uint16_t kidx = rD;

      RawObject** call_base = SP - argc + 1;
      RawObject** call_top = SP + 1;

      RawICData* icdata = RAW_CAST(ICData, LOAD_CONSTANT(kidx));
      SimulatorHelpers::IncrementUsageCounter(FrameFunction(FP));
      InstanceCall1(thread, icdata, call_base, call_top, &argdesc, &pp, &pc,
                    &FP, &SP, true /* optimized */);
    }

    DISPATCH();
  }

  {
    BYTECODE(InstanceCall2Opt, A_D);

    {
      const uint16_t argc = rA;
      const uint16_t kidx = rD;

      RawObject** call_base = SP - argc + 1;
      RawObject** call_top = SP + 1;

      RawICData* icdata = RAW_CAST(ICData, LOAD_CONSTANT(kidx));
      SimulatorHelpers::IncrementUsageCounter(FrameFunction(FP));
      InstanceCall2(thread, icdata, call_base, call_top, &argdesc, &pp, &pc,
                    &FP, &SP, true /* optimized */);
    }

    DISPATCH();
  }

  {
    BYTECODE(PushPolymorphicInstanceCall, A_D);
    const uint8_t argc = rA;
    const intptr_t cids_length = rD;
    RawObject** args = SP - argc + 1;
    const intptr_t receiver_cid = SimulatorHelpers::GetClassId(args[0]);
    for (intptr_t i = 0; i < 2 * cids_length; i += 2) {
      const intptr_t icdata_cid = Bytecode::DecodeD(*(pc + i));
      if (receiver_cid == icdata_cid) {
        RawFunction* target =
            RAW_CAST(Function, LOAD_CONSTANT(Bytecode::DecodeD(*(pc + i + 1))));
        *++SP = target;
        pc++;
        break;
      }
    }
    pc += 2 * cids_length;
    DISPATCH();
  }

  {
    BYTECODE(PushPolymorphicInstanceCallByRange, A_D);
    const uint8_t argc = rA;
    const intptr_t cids_length = rD;
    RawObject** args = SP - argc + 1;
    const intptr_t receiver_cid = SimulatorHelpers::GetClassId(args[0]);
    for (intptr_t i = 0; i < 3 * cids_length; i += 3) {
      // Note unsigned types to get an unsigned range compare.
      const uintptr_t cid_start = Bytecode::DecodeD(*(pc + i));
      const uintptr_t cids = Bytecode::DecodeD(*(pc + i + 1));
      if (receiver_cid - cid_start < cids) {
        RawFunction* target =
            RAW_CAST(Function, LOAD_CONSTANT(Bytecode::DecodeD(*(pc + i + 2))));
        *++SP = target;
        pc++;
        break;
      }
    }
    pc += 3 * cids_length;
    DISPATCH();
  }

  {
    BYTECODE(NativeBootstrapCall, 0);
    RawFunction* function = FrameFunction(FP);
    RawObject** incoming_args =
        (function->ptr()->num_optional_parameters_ == 0)
            ? FrameArguments(FP, function->ptr()->num_fixed_parameters_)
            : FP;

    SimulatorBootstrapNativeCall native_target =
        reinterpret_cast<SimulatorBootstrapNativeCall>(SP[-1]);
    intptr_t argc_tag = reinterpret_cast<intptr_t>(SP[-0]);
    SP[-0] = 0;  // Note: argc_tag is not smi-tagged.
    SP[-1] = null_value;
    Exit(thread, FP, SP + 1, pc);
    NativeArguments args(thread, argc_tag, incoming_args, SP - 1);
    INVOKE_BOOTSTRAP_NATIVE(native_target, args);
    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(NativeNoScopeCall, 0);
    RawFunction* function = FrameFunction(FP);
    RawObject** incoming_args =
        (function->ptr()->num_optional_parameters_ == 0)
            ? FrameArguments(FP, function->ptr()->num_fixed_parameters_)
            : FP;

    Dart_NativeFunction native_target =
        reinterpret_cast<Dart_NativeFunction>(SP[-1]);
    intptr_t argc_tag = reinterpret_cast<intptr_t>(SP[-0]);
    SP[-0] = 0;  // argc_tag is not smi tagged!
    SP[-1] = null_value;
    Exit(thread, FP, SP + 1, pc);
    NativeArguments args(thread, argc_tag, incoming_args, SP - 1);
    INVOKE_NATIVE_NO_SCOPE(native_target, args);
    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(NativeAutoScopeCall, 0);
    RawFunction* function = FrameFunction(FP);
    RawObject** incoming_args =
        (function->ptr()->num_optional_parameters_ == 0)
            ? FrameArguments(FP, function->ptr()->num_fixed_parameters_)
            : FP;

    Dart_NativeFunction native_target =
        reinterpret_cast<Dart_NativeFunction>(SP[-1]);
    intptr_t argc_tag = reinterpret_cast<intptr_t>(SP[-0]);
    SP[-0] = 0;  // argc_tag is not smi tagged!
    SP[-1] = null_value;
    Exit(thread, FP, SP + 1, pc);
    NativeArguments args(thread, argc_tag, incoming_args, SP - 1);
    INVOKE_NATIVE_AUTO_SCOPE(native_target, args);
    SP -= 1;
    DISPATCH();
  }

  {
    BYTECODE(OneByteStringFromCharCode, A_X);
    const intptr_t char_code = Smi::Value(RAW_CAST(Smi, FP[rD]));
    ASSERT(char_code >= 0);
    ASSERT(char_code <= 255);
    RawString** strings = Symbols::PredefinedAddress();
    const intptr_t index = char_code + Symbols::kNullCharCodeSymbolOffset;
    FP[rA] = strings[index];
    DISPATCH();
  }

  {
    BYTECODE(StringToCharCode, A_X);
    RawOneByteString* str = RAW_CAST(OneByteString, FP[rD]);
    if (str->ptr()->length_ == Smi::New(1)) {
      FP[rA] = Smi::New(str->ptr()->data()[0]);
    } else {
      FP[rA] = Smi::New(-1);
    }
    DISPATCH();
  }

  {
    BYTECODE(AddTOS, A_B_C);
    SMI_FASTPATH_TOS(intptr_t, SignedAddWithOverflow);
    DISPATCH();
  }
  {
    BYTECODE(SubTOS, A_B_C);
    SMI_FASTPATH_TOS(intptr_t, SignedSubWithOverflow);
    DISPATCH();
  }
  {
    BYTECODE(MulTOS, A_B_C);
    SMI_FASTPATH_TOS(intptr_t, SMI_MUL);
    DISPATCH();
  }
  {
    BYTECODE(BitOrTOS, A_B_C);
    SMI_FASTPATH_TOS(intptr_t, SMI_BITOR);
    DISPATCH();
  }
  {
    BYTECODE(BitAndTOS, A_B_C);
    SMI_FASTPATH_TOS(intptr_t, SMI_BITAND);
    DISPATCH();
  }
  {
    BYTECODE(EqualTOS, A_B_C);
    SMI_FASTPATH_TOS(RawObject*, SMI_EQ);
    DISPATCH();
  }
  {
    BYTECODE(LessThanTOS, A_B_C);
    SMI_FASTPATH_TOS(RawObject*, SMI_LT);
    DISPATCH();
  }
  {
    BYTECODE(GreaterThanTOS, A_B_C);
    SMI_FASTPATH_TOS(RawObject*, SMI_GT);
    DISPATCH();
  }
  {
    BYTECODE(Add, A_B_C);
    SMI_OP_CHECK(intptr_t, SignedAddWithOverflow);
    DISPATCH();
  }
  {
    BYTECODE(Sub, A_B_C);
    SMI_OP_CHECK(intptr_t, SignedSubWithOverflow);
    DISPATCH();
  }
  {
    BYTECODE(Mul, A_B_C);
    SMI_OP_CHECK(intptr_t, SMI_MUL);
    DISPATCH();
  }
  {
    BYTECODE(Neg, A_D);
    const intptr_t value = reinterpret_cast<intptr_t>(FP[rD]);
    intptr_t* out = reinterpret_cast<intptr_t*>(&FP[rA]);
    if (LIKELY(!SignedSubWithOverflow(0, value, out))) {
      pc++;
    }
    DISPATCH();
  }
  {
    BYTECODE(BitOr, A_B_C);
    SMI_OP_NOCHECK(intptr_t, SMI_BITOR);
    DISPATCH();
  }
  {
    BYTECODE(BitAnd, A_B_C);
    SMI_OP_NOCHECK(intptr_t, SMI_BITAND);
    DISPATCH();
  }
  {
    BYTECODE(BitXor, A_B_C);
    SMI_OP_NOCHECK(intptr_t, SMI_BITXOR);
    DISPATCH();
  }
  {
    BYTECODE(BitNot, A_D);
    const intptr_t value = reinterpret_cast<intptr_t>(FP[rD]);
    *reinterpret_cast<intptr_t*>(&FP[rA]) = ~value & (~kSmiTagMask);
    DISPATCH();
  }

  {
    BYTECODE(Div, A_B_C);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]);
    if (rhs != 0) {
      const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);
      const intptr_t res = (lhs >> kSmiTagSize) / (rhs >> kSmiTagSize);
#if defined(ARCH_IS_64_BIT)
      const intptr_t untaggable = 0x4000000000000000LL;
#else
      const intptr_t untaggable = 0x40000000L;
#endif  // defined(ARCH_IS_64_BIT)
      if (res != untaggable) {
        *reinterpret_cast<intptr_t*>(&FP[rA]) = res << kSmiTagSize;
        pc++;
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(Mod, A_B_C);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]);
    if (rhs != 0) {
      const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);
      const intptr_t res = ((lhs >> kSmiTagSize) % (rhs >> kSmiTagSize))
                           << kSmiTagSize;
      *reinterpret_cast<intptr_t*>(&FP[rA]) =
          (res < 0) ? ((rhs < 0) ? (res - rhs) : (res + rhs)) : res;
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(Shl, A_B_C);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]) >> kSmiTagSize;
    if (static_cast<uintptr_t>(rhs) < kBitsPerWord) {
      const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);
      const intptr_t res = lhs << rhs;
      if (lhs == (res >> rhs)) {
        *reinterpret_cast<intptr_t*>(&FP[rA]) = res;
        pc++;
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(Shr, A_B_C);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]) >> kSmiTagSize;
    if (rhs >= 0) {
      const intptr_t shift_amount =
          (rhs >= kBitsPerWord) ? (kBitsPerWord - 1) : rhs;
      const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]) >> kSmiTagSize;
      *reinterpret_cast<intptr_t*>(&FP[rA]) = (lhs >> shift_amount)
                                              << kSmiTagSize;
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(ShlImm, A_B_C);
    const uint8_t shift = rC;
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);
    FP[rA] = reinterpret_cast<RawObject*>(lhs << shift);
    DISPATCH();
  }

  {
    BYTECODE(Min, A_B_C);
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]);
    FP[rA] = reinterpret_cast<RawObject*>((lhs < rhs) ? lhs : rhs);
    DISPATCH();
  }

  {
    BYTECODE(Max, A_B_C);
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rB]);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rC]);
    FP[rA] = reinterpret_cast<RawObject*>((lhs > rhs) ? lhs : rhs);
    DISPATCH();
  }

  {
    BYTECODE(UnboxInt32, A_B_C);
    const intptr_t box_cid = SimulatorHelpers::GetClassId(FP[rB]);
    const bool may_truncate = rC == 1;
    if (box_cid == kSmiCid) {
      const intptr_t value = reinterpret_cast<intptr_t>(FP[rB]) >> kSmiTagSize;
      const int32_t value32 = static_cast<int32_t>(value);
      if (may_truncate || (value == static_cast<intptr_t>(value32))) {
        FP[rA] = reinterpret_cast<RawObject*>(value);
        pc++;
      }
    } else if (box_cid == kMintCid) {
      RawMint* mint = RAW_CAST(Mint, FP[rB]);
      const int64_t value = mint->ptr()->value_;
      const int32_t value32 = static_cast<int32_t>(value);
      if (may_truncate || (value == static_cast<int64_t>(value32))) {
        FP[rA] = reinterpret_cast<RawObject*>(value);
        pc++;
      }
    }
    DISPATCH();
  }

#if defined(ARCH_IS_64_BIT)
  {
    BYTECODE(WriteIntoDouble, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    RawDouble* box = RAW_CAST(Double, FP[rA]);
    box->ptr()->value_ = value;
    DISPATCH();
  }

  {
    BYTECODE(UnboxDouble, A_D);
    const RawDouble* box = RAW_CAST(Double, FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(box->ptr()->value_);
    DISPATCH();
  }

  {
    BYTECODE(CheckedUnboxDouble, A_D);
    const intptr_t box_cid = SimulatorHelpers::GetClassId(FP[rD]);
    if (box_cid == kSmiCid) {
      const intptr_t value = reinterpret_cast<intptr_t>(FP[rD]) >> kSmiTagSize;
      const double result = static_cast<double>(value);
      FP[rA] = bit_cast<RawObject*, double>(result);
      pc++;
    } else if (box_cid == kDoubleCid) {
      const RawDouble* box = RAW_CAST(Double, FP[rD]);
      FP[rA] = bit_cast<RawObject*, double>(box->ptr()->value_);
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(DoubleToSmi, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    if (!isnan(value)) {
      const intptr_t result = static_cast<intptr_t>(value);
      if ((result <= Smi::kMaxValue) && (result >= Smi::kMinValue)) {
        FP[rA] = reinterpret_cast<RawObject*>(result << kSmiTagSize);
        pc++;
      }
    }
    DISPATCH();
  }

  {
    BYTECODE(SmiToDouble, A_D);
    const intptr_t value = reinterpret_cast<intptr_t>(FP[rD]) >> kSmiTagSize;
    const double result = static_cast<double>(value);
    FP[rA] = bit_cast<RawObject*, double>(result);
    DISPATCH();
  }

  {
    BYTECODE(DAdd, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    FP[rA] = bit_cast<RawObject*, double>(lhs + rhs);
    DISPATCH();
  }

  {
    BYTECODE(DSub, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    FP[rA] = bit_cast<RawObject*, double>(lhs - rhs);
    DISPATCH();
  }

  {
    BYTECODE(DMul, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    FP[rA] = bit_cast<RawObject*, double>(lhs * rhs);
    DISPATCH();
  }

  {
    BYTECODE(DDiv, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    const double result = lhs / rhs;
    FP[rA] = bit_cast<RawObject*, double>(result);
    DISPATCH();
  }

  {
    BYTECODE(DNeg, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(-value);
    DISPATCH();
  }

  {
    BYTECODE(DSqrt, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(sqrt(value));
    DISPATCH();
  }

  {
    BYTECODE(DSin, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(sin(value));
    DISPATCH();
  }

  {
    BYTECODE(DCos, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(cos(value));
    DISPATCH();
  }

  {
    BYTECODE(DPow, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    const double result = pow(lhs, rhs);
    FP[rA] = bit_cast<RawObject*, double>(result);
    DISPATCH();
  }

  {
    BYTECODE(DMod, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    const double result = DartModulo(lhs, rhs);
    FP[rA] = bit_cast<RawObject*, double>(result);
    DISPATCH();
  }

  {
    BYTECODE(DMin, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    FP[rA] = bit_cast<RawObject*, double>(fmin(lhs, rhs));
    DISPATCH();
  }

  {
    BYTECODE(DMax, A_B_C);
    const double lhs = bit_cast<double, RawObject*>(FP[rB]);
    const double rhs = bit_cast<double, RawObject*>(FP[rC]);
    FP[rA] = bit_cast<RawObject*, double>(fmax(lhs, rhs));
    DISPATCH();
  }

  {
    BYTECODE(DTruncate, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(trunc(value));
    DISPATCH();
  }

  {
    BYTECODE(DFloor, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(floor(value));
    DISPATCH();
  }

  {
    BYTECODE(DCeil, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    FP[rA] = bit_cast<RawObject*, double>(ceil(value));
    DISPATCH();
  }

  {
    BYTECODE(DoubleToFloat, A_D);
    const double value = bit_cast<double, RawObject*>(FP[rD]);
    const float valuef = static_cast<float>(value);
    *reinterpret_cast<float*>(&FP[rA]) = valuef;
    DISPATCH();
  }

  {
    BYTECODE(FloatToDouble, A_D);
    const float valuef = *reinterpret_cast<float*>(&FP[rD]);
    const double value = static_cast<double>(valuef);
    FP[rA] = bit_cast<RawObject*, double>(value);
    DISPATCH();
  }

  {
    BYTECODE(DoubleIsNaN, A);
    const double v = bit_cast<double, RawObject*>(FP[rA]);
    if (!isnan(v)) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(DoubleIsInfinite, A);
    const double v = bit_cast<double, RawObject*>(FP[rA]);
    if (!isinf(v)) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedFloat32, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rB], FP[rC]);
    const uint32_t value = *reinterpret_cast<uint32_t*>(data);
    const uint64_t value64 = value;
    FP[rA] = reinterpret_cast<RawObject*>(value64);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexed4Float32, A_B_C);
    ASSERT(RawObject::IsTypedDataClassId(FP[rB]->GetClassId()));
    RawTypedData* array = reinterpret_cast<RawTypedData*>(FP[rB]);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    const uint32_t value =
        reinterpret_cast<uint32_t*>(array->ptr()->data())[Smi::Value(index)];
    const uint64_t value64 = value;  // sign extend to clear high bits.
    FP[rA] = reinterpret_cast<RawObject*>(value64);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedFloat64, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rB], FP[rC]);
    *reinterpret_cast<uint64_t*>(&FP[rA]) = *reinterpret_cast<uint64_t*>(data);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexed8Float64, A_B_C);
    ASSERT(RawObject::IsTypedDataClassId(FP[rB]->GetClassId()));
    RawTypedData* array = reinterpret_cast<RawTypedData*>(FP[rB]);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    const int64_t value =
        reinterpret_cast<int64_t*>(array->ptr()->data())[Smi::Value(index)];
    FP[rA] = reinterpret_cast<RawObject*>(value);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedFloat32, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rA], FP[rB]);
    const uint64_t value = reinterpret_cast<uint64_t>(FP[rC]);
    const uint32_t value32 = value;
    *reinterpret_cast<uint32_t*>(data) = value32;
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexed4Float32, A_B_C);
    ASSERT(RawObject::IsTypedDataClassId(FP[rA]->GetClassId()));
    RawTypedData* array = reinterpret_cast<RawTypedData*>(FP[rA]);
    RawSmi* index = RAW_CAST(Smi, FP[rB]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    const uint64_t value = reinterpret_cast<uint64_t>(FP[rC]);
    const uint32_t value32 = value;
    reinterpret_cast<uint32_t*>(array->ptr()->data())[Smi::Value(index)] =
        value32;
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedFloat64, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rA], FP[rB]);
    *reinterpret_cast<uint64_t*>(data) = reinterpret_cast<uint64_t>(FP[rC]);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexed8Float64, A_B_C);
    ASSERT(RawObject::IsTypedDataClassId(FP[rA]->GetClassId()));
    RawTypedData* array = reinterpret_cast<RawTypedData*>(FP[rA]);
    RawSmi* index = RAW_CAST(Smi, FP[rB]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    const int64_t value = reinterpret_cast<int64_t>(FP[rC]);
    reinterpret_cast<int64_t*>(array->ptr()->data())[Smi::Value(index)] = value;
    DISPATCH();
  }

  {
    BYTECODE(BoxInt32, A_D);
    // Casts sign-extend high 32 bits from low 32 bits.
    const intptr_t value = reinterpret_cast<intptr_t>(FP[rD]);
    const int32_t value32 = static_cast<int32_t>(value);
    FP[rA] = Smi::New(static_cast<intptr_t>(value32));
    DISPATCH();
  }

  {
    BYTECODE(BoxUint32, A_D);
    // Casts to zero out high 32 bits.
    const uintptr_t value = reinterpret_cast<uintptr_t>(FP[rD]);
    const uint32_t value32 = static_cast<uint32_t>(value);
    FP[rA] = Smi::New(static_cast<intptr_t>(value32));
    DISPATCH();
  }
#else   // defined(ARCH_IS_64_BIT)
  {
    BYTECODE(WriteIntoDouble, A_D);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(UnboxDouble, A_D);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(CheckedUnboxDouble, A_D);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DoubleToSmi, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(SmiToDouble, A_D);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DAdd, A_B_C);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DSub, A_B_C);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DMul, A_B_C);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DDiv, A_B_C);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DNeg, A_D);
    UNIMPLEMENTED();
    DISPATCH();
  }

  {
    BYTECODE(DSqrt, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DSin, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DCos, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DPow, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DMod, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DMin, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DMax, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DTruncate, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DFloor, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DCeil, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DoubleToFloat, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(FloatToDouble, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DoubleIsNaN, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(DoubleIsInfinite, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedFloat32, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexed4Float32, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedFloat64, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexed8Float64, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedFloat32, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexed4Float32, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedFloat64, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexed8Float64, A_B_C);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(BoxInt32, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(BoxUint32, A_D);
    UNREACHABLE();
    DISPATCH();
  }
#endif  // defined(ARCH_IS_64_BIT)

  // Return and return like instructions (Instrinsic).
  {
    RawObject* result;  // result to return to the caller.

    BYTECODE(Intrinsic, A);
    // Try invoking intrinsic handler. If it succeeds (returns true)
    // then just return the value it returned to the caller.
    result = null_value;
    if (!intrinsics_[rA](thread, FP, &result)) {
      DISPATCH();
    }
    goto ReturnImpl;

    BYTECODE(Return, A);
    result = FP[rA];
    goto ReturnImpl;

    BYTECODE(ReturnTOS, 0);
    result = *SP;
  // Fall through to the ReturnImpl.

  ReturnImpl:
    // Restore caller PC.
    pc = SavedCallerPC(FP);
    pc_ = reinterpret_cast<uword>(pc);  // For the profiler.

    // Check if it is a fake PC marking the entry frame.
    if ((reinterpret_cast<uword>(pc) & 2) != 0) {
      const intptr_t argc = reinterpret_cast<uword>(pc) >> 2;
      fp_ = reinterpret_cast<RawObject**>(FrameArguments(FP, argc + 1)[0]);
      thread->set_top_exit_frame_info(reinterpret_cast<uword>(fp_));
      thread->set_top_resource(top_resource);
      thread->set_vm_tag(vm_tag);
      return result;
    }

    // Look at the caller to determine how many arguments to pop.
    const uint8_t argc = Bytecode::DecodeArgc(pc[-1]);

    // Restore SP, FP and PP. Push result and dispatch.
    SP = FrameArguments(FP, argc);
    FP = SavedCallerFP(FP);
    pp = SimulatorHelpers::FrameCode(FP)->ptr()->object_pool_->ptr();
    *SP = result;
    DISPATCH();
  }

  {
    BYTECODE(StoreStaticTOS, A_D);
    RawField* field = reinterpret_cast<RawField*>(LOAD_CONSTANT(rD));
    RawInstance* value = static_cast<RawInstance*>(*SP--);
    field->StorePointer(&field->ptr()->value_.static_value_, value);
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
    BYTECODE(StoreField, A_B_C);
    const uint16_t offset_in_words = rB;
    const uint16_t value_reg = rC;

    RawInstance* instance = reinterpret_cast<RawInstance*>(FP[rA]);
    RawObject* value = FP[value_reg];

    instance->StorePointer(
        reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words,
        value);
    DISPATCH();
  }

  {
    BYTECODE(StoreFieldExt, A_D);
    // The offset is stored in the following nop-instruction which is skipped.
    const uint16_t offset_in_words = Bytecode::DecodeD(*pc++);
    RawInstance* instance = reinterpret_cast<RawInstance*>(FP[rA]);
    RawObject* value = FP[rD];

    instance->StorePointer(
        reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words,
        value);
    DISPATCH();
  }

  {
    BYTECODE(StoreFieldTOS, A_D);
    const uint16_t offset_in_words = rD;
    RawInstance* instance = reinterpret_cast<RawInstance*>(SP[-1]);
    RawObject* value = reinterpret_cast<RawObject*>(SP[0]);
    SP -= 2;  // Drop instance and value.
    instance->StorePointer(
        reinterpret_cast<RawObject**>(instance->ptr()) + offset_in_words,
        value);

    DISPATCH();
  }

  {
    BYTECODE(LoadField, A_B_C);
    const uint16_t instance_reg = rB;
    const uint16_t offset_in_words = rC;
    RawInstance* instance = reinterpret_cast<RawInstance*>(FP[instance_reg]);
    FP[rA] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(LoadFieldExt, A_D);
    // The offset is stored in the following nop-instruction which is skipped.
    const uint16_t offset_in_words = Bytecode::DecodeD(*pc++);
    const uint16_t instance_reg = rD;
    RawInstance* instance = reinterpret_cast<RawInstance*>(FP[instance_reg]);
    FP[rA] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(LoadUntagged, A_B_C);
    const uint16_t instance_reg = rB;
    const uint16_t offset_in_words = rC;
    RawInstance* instance = reinterpret_cast<RawInstance*>(FP[instance_reg]);
    FP[rA] = reinterpret_cast<RawObject**>(instance)[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(LoadFieldTOS, __D);
    const uint16_t offset_in_words = rD;
    RawInstance* instance = static_cast<RawInstance*>(SP[0]);
    SP[0] = reinterpret_cast<RawObject**>(instance->ptr())[offset_in_words];
    DISPATCH();
  }

  {
    BYTECODE(InitStaticTOS, 0);
    RawField* field = static_cast<RawField*>(*SP--);
    RawObject* value = field->ptr()->value_.static_value_;
    if ((value == Object::sentinel().raw()) ||
        (value == Object::transition_sentinel().raw())) {
      // Note: SP[1] already contains the field object.
      SP[2] = 0;
      Exit(thread, FP, SP + 3, pc);
      NativeArguments args(thread, 1, SP + 1, SP + 2);
      INVOKE_RUNTIME(DRT_InitStaticField, args);
    }
    DISPATCH();
  }

  // TODO(vegorov) allocation bytecodes can benefit from the new-space
  // allocation fast-path that does not transition into the runtime system.
  {
    BYTECODE(AllocateUninitializedContext, A_D);
    const uint16_t num_context_variables = rD;
    const intptr_t instance_size = Context::InstanceSize(num_context_variables);
    const uword start =
        thread->heap()->new_space()->TryAllocateInTLAB(thread, instance_size);
    if (LIKELY(start != 0)) {
      uint32_t tags = 0;
      tags = RawObject::ClassIdTag::update(kContextCid, tags);
      tags = RawObject::SizeTag::update(instance_size, tags);
      // Also writes 0 in the hash_ field of the header.
      *reinterpret_cast<uword*>(start + Array::tags_offset()) = tags;
      *reinterpret_cast<uword*>(start + Context::num_variables_offset()) =
          num_context_variables;
      FP[rA] = reinterpret_cast<RawObject*>(start + kHeapObjectTag);
      pc += 2;
    }
    DISPATCH();
  }

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
    BYTECODE(AllocateOpt, A_D);
    const uword tags =
        static_cast<uword>(Smi::Value(RAW_CAST(Smi, LOAD_CONSTANT(rD))));
    const intptr_t instance_size = RawObject::SizeTag::decode(tags);
    const uword start =
        thread->heap()->new_space()->TryAllocateInTLAB(thread, instance_size);
    if (LIKELY(start != 0)) {
      // Writes both the tags and the initial identity hash on 64 bit platforms.
      *reinterpret_cast<uword*>(start + Instance::tags_offset()) = tags;
      for (intptr_t current_offset = sizeof(RawInstance);
           current_offset < instance_size; current_offset += kWordSize) {
        *reinterpret_cast<RawObject**>(start + current_offset) = null_value;
      }
      FP[rA] = reinterpret_cast<RawObject*>(start + kHeapObjectTag);
      pc += 2;
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
    BYTECODE(AllocateTOpt, A_D);
    const uword tags = Smi::Value(RAW_CAST(Smi, LOAD_CONSTANT(rD)));
    const intptr_t instance_size = RawObject::SizeTag::decode(tags);
    const uword start =
        thread->heap()->new_space()->TryAllocateInTLAB(thread, instance_size);
    if (LIKELY(start != 0)) {
      RawObject* type_args = SP[0];
      const intptr_t type_args_offset = Bytecode::DecodeD(*pc);
      // Writes both the tags and the initial identity hash on 64 bit platforms.
      *reinterpret_cast<uword*>(start + Instance::tags_offset()) = tags;
      for (intptr_t current_offset = sizeof(RawInstance);
           current_offset < instance_size; current_offset += kWordSize) {
        *reinterpret_cast<RawObject**>(start + current_offset) = null_value;
      }
      *reinterpret_cast<RawObject**>(start + type_args_offset) = type_args;
      FP[rA] = reinterpret_cast<RawObject*>(start + kHeapObjectTag);
      SP -= 1;  // Consume the type arguments on the stack.
      pc += 4;
    }
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
    BYTECODE(CreateArrayOpt, A_B_C);
    if (LIKELY(!FP[rB]->IsHeapObject())) {
      const intptr_t length = Smi::Value(RAW_CAST(Smi, FP[rB]));
      if (LIKELY(static_cast<uintptr_t>(length) <= Array::kMaxElements)) {
        const intptr_t fixed_size_plus_alignment_padding =
            sizeof(RawArray) + kObjectAlignment - 1;
        const intptr_t instance_size =
            (fixed_size_plus_alignment_padding + length * kWordSize) &
            ~(kObjectAlignment - 1);
        const uword start = thread->heap()->new_space()->TryAllocateInTLAB(
            thread, instance_size);
        if (LIKELY(start != 0)) {
          const intptr_t cid = kArrayCid;
          uword tags = 0;
          if (LIKELY(instance_size <= RawObject::SizeTag::kMaxSizeTag)) {
            tags = RawObject::SizeTag::update(instance_size, tags);
          }
          tags = RawObject::ClassIdTag::update(cid, tags);
          // Writes both the tags and the initial identity hash on 64 bit
          // platforms.
          *reinterpret_cast<uword*>(start + Instance::tags_offset()) = tags;
          *reinterpret_cast<RawObject**>(start + Array::length_offset()) =
              FP[rB];
          *reinterpret_cast<RawObject**>(
              start + Array::type_arguments_offset()) = FP[rC];
          RawObject** data =
              reinterpret_cast<RawObject**>(start + Array::data_offset());
          for (intptr_t i = 0; i < length; i++) {
            data[i] = null_value;
          }
          FP[rA] = reinterpret_cast<RawObject*>(start + kHeapObjectTag);
          pc += 4;
        }
      }
    }
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
    BYTECODE(InstanceOf, 0);
    // Stack: instance, instantiator type args, function type args, type, cache
    RawInstance* instance = static_cast<RawInstance*>(SP[-4]);
    RawTypeArguments* instantiator_type_arguments =
        static_cast<RawTypeArguments*>(SP[-3]);
    RawTypeArguments* function_type_arguments =
        static_cast<RawTypeArguments*>(SP[-2]);
    RawAbstractType* type = static_cast<RawAbstractType*>(SP[-1]);
    RawSubtypeTestCache* cache = static_cast<RawSubtypeTestCache*>(SP[0]);

    if (cache != null_value) {
      const intptr_t cid = SimulatorHelpers::GetClassId(instance);

      RawTypeArguments* instance_type_arguments =
          static_cast<RawTypeArguments*>(null_value);
      RawObject* instance_cid_or_function;
      if (cid == kClosureCid) {
        RawClosure* closure = static_cast<RawClosure*>(instance);
        if (closure->ptr()->function_type_arguments_ != TypeArguments::null()) {
          // Cache cannot be used for generic closures.
          goto InstanceOfCallRuntime;
        }
        instance_type_arguments = closure->ptr()->instantiator_type_arguments_;
        instance_cid_or_function = closure->ptr()->function_;
      } else {
        instance_cid_or_function = Smi::New(cid);

        RawClass* instance_class = thread->isolate()->class_table()->At(cid);
        if (instance_class->ptr()->num_type_arguments_ < 0) {
          goto InstanceOfCallRuntime;
        } else if (instance_class->ptr()->num_type_arguments_ > 0) {
          instance_type_arguments = reinterpret_cast<RawTypeArguments**>(
              instance->ptr())[instance_class->ptr()
                                   ->type_arguments_field_offset_in_words_];
        }
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
             function_type_arguments)) {
          SP[-4] = entries[SubtypeTestCache::kTestResult];
          goto InstanceOfOk;
        }
      }
    }

  // clang-format off
  InstanceOfCallRuntime:
    {
      SP[1] = instance;
      SP[2] = type;
      SP[3] = instantiator_type_arguments;
      SP[4] = function_type_arguments;
      SP[5] = cache;
      Exit(thread, FP, SP + 6, pc);
      NativeArguments native_args(thread, 5, SP + 1, SP - 4);
      INVOKE_RUNTIME(DRT_Instanceof, native_args);
    }
  // clang-format on

  InstanceOfOk:
    SP -= 4;
    DISPATCH();
  }

  {
    BYTECODE(BadTypeError, 0);
    // Stack: instance, instantiator type args, function type args, type, name
    RawObject** args = SP - 4;
    if (args[0] != null_value) {
      SP[1] = args[0];  // instance.
      SP[2] = args[4];  // name.
      SP[3] = args[3];  // type.
      Exit(thread, FP, SP + 4, pc);
      NativeArguments native_args(thread, 3, SP + 1, SP - 4);
      INVOKE_RUNTIME(DRT_BadTypeError, native_args);
      UNREACHABLE();
    }
    SP -= 4;
    DISPATCH();
  }

  {
    BYTECODE(AssertAssignable, A_D);
    // Stack: instance, instantiator type args, function type args, type, name
    RawObject** args = SP - 4;
    const bool may_be_smi = (rA == 1);
    const bool is_smi =
        ((reinterpret_cast<intptr_t>(args[0]) & kSmiTagMask) == kSmiTag);
    const bool smi_ok = is_smi && may_be_smi;
    if (!smi_ok && (args[0] != null_value)) {
      RawSubtypeTestCache* cache =
          static_cast<RawSubtypeTestCache*>(LOAD_CONSTANT(rD));
      if (cache != null_value) {
        RawInstance* instance = static_cast<RawInstance*>(args[0]);
        RawTypeArguments* instantiator_type_arguments =
            static_cast<RawTypeArguments*>(args[1]);
        RawTypeArguments* function_type_arguments =
            static_cast<RawTypeArguments*>(args[2]);

        const intptr_t cid = SimulatorHelpers::GetClassId(instance);

        RawTypeArguments* instance_type_arguments =
            static_cast<RawTypeArguments*>(null_value);
        RawObject* instance_cid_or_function;
        if (cid == kClosureCid) {
          RawClosure* closure = static_cast<RawClosure*>(instance);
          if (closure->ptr()->function_type_arguments_ !=
              TypeArguments::null()) {
            // Cache cannot be used for generic closures.
            goto AssertAssignableCallRuntime;
          }
          instance_type_arguments =
              closure->ptr()->instantiator_type_arguments_;
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
               function_type_arguments)) {
            if (true_value == entries[SubtypeTestCache::kTestResult]) {
              goto AssertAssignableOk;
            } else {
              break;
            }
          }
        }
      }

    AssertAssignableCallRuntime:
      SP[1] = args[0];  // instance
      SP[2] = args[3];  // type
      SP[3] = args[1];  // instantiator type args
      SP[4] = args[2];  // function type args
      SP[5] = args[4];  // name
      SP[6] = cache;
      Exit(thread, FP, SP + 7, pc);
      NativeArguments native_args(thread, 6, SP + 1, SP - 4);
      INVOKE_RUNTIME(DRT_TypeCheck, native_args);
    }

  AssertAssignableOk:
    SP -= 4;
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
    BYTECODE(TestSmi, A_D);
    intptr_t left = reinterpret_cast<intptr_t>(RAW_CAST(Smi, FP[rA]));
    intptr_t right = reinterpret_cast<intptr_t>(RAW_CAST(Smi, FP[rD]));
    if ((left & right) != 0) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(TestCids, A_D);
    const intptr_t cid = SimulatorHelpers::GetClassId(FP[rA]);
    const intptr_t num_cases = rD;
    for (intptr_t i = 0; i < num_cases; i++) {
      ASSERT(Bytecode::DecodeOpcode(pc[i]) == Bytecode::kNop);
      intptr_t test_target = Bytecode::DecodeA(pc[i]);
      intptr_t test_cid = Bytecode::DecodeD(pc[i]);
      if (cid == test_cid) {
        if (test_target != 0) {
          pc += 1;  // Match true.
        } else {
          pc += 2;  // Match false.
        }
        break;
      }
    }
    pc += num_cases;
    DISPATCH();
  }

  {
    BYTECODE(CheckSmi, 0);
    intptr_t obj = reinterpret_cast<intptr_t>(FP[rA]);
    if ((obj & kSmiTagMask) == kSmiTag) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckEitherNonSmi, A_D);
    const intptr_t obj1 = reinterpret_cast<intptr_t>(FP[rA]);
    const intptr_t obj2 = reinterpret_cast<intptr_t>(FP[rD]);
    const intptr_t tag = (obj1 | obj2) & kSmiTagMask;
    if (tag != kSmiTag) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckClassId, A_D);
    const intptr_t actual_cid =
        reinterpret_cast<intptr_t>(FP[rA]) >> kSmiTagSize;
    const intptr_t desired_cid = rD;
    pc += (actual_cid == desired_cid) ? 1 : 0;
    DISPATCH();
  }

  {
    BYTECODE(CheckClassIdRange, A_D);
    const intptr_t actual_cid =
        reinterpret_cast<intptr_t>(FP[rA]) >> kSmiTagSize;
    const uintptr_t cid_start = rD;
    const uintptr_t cid_range = Bytecode::DecodeD(*pc);
    // Unsigned comparison.  Skip either just the nop or both the nop and the
    // following instruction.
    pc += (actual_cid - cid_start <= cid_range) ? 2 : 1;
    DISPATCH();
  }

  {
    BYTECODE(CheckBitTest, A_D);
    const intptr_t raw_value = reinterpret_cast<intptr_t>(FP[rA]);
    const bool is_smi = ((raw_value & kSmiTagMask) == kSmiTag);
    const intptr_t cid_min = Bytecode::DecodeD(*pc);
    const intptr_t cid_mask =
        Smi::Value(RAW_CAST(Smi, LOAD_CONSTANT(Bytecode::DecodeD(*(pc + 1)))));
    if (LIKELY(!is_smi)) {
      const intptr_t cid_max = Utils::HighestBit(cid_mask) + cid_min;
      const intptr_t cid = SimulatorHelpers::GetClassId(FP[rA]);
      // The cid is in-bounds, and the bit is set in the mask.
      if ((cid >= cid_min) && (cid <= cid_max) &&
          ((cid_mask & (1 << (cid - cid_min))) != 0)) {
        pc += 3;
      } else {
        pc += 2;
      }
    } else {
      const bool may_be_smi = (rD == 1);
      pc += (may_be_smi ? 3 : 2);
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckCids, A_B_C);
    const intptr_t raw_value = reinterpret_cast<intptr_t>(FP[rA]);
    const bool is_smi = ((raw_value & kSmiTagMask) == kSmiTag);
    const bool may_be_smi = (rB == 1);
    const intptr_t cids_length = rC;
    if (LIKELY(!is_smi)) {
      const intptr_t cid = SimulatorHelpers::GetClassId(FP[rA]);
      for (intptr_t i = 0; i < cids_length; i++) {
        const intptr_t desired_cid = Bytecode::DecodeD(*(pc + i));
        if (cid == desired_cid) {
          pc++;
          break;
        }
      }
      pc += cids_length;
    } else {
      pc += cids_length;
      pc += (may_be_smi ? 1 : 0);
    }
    DISPATCH();
  }

  {
    BYTECODE(CheckCidsByRange, A_B_C);
    const intptr_t raw_value = reinterpret_cast<intptr_t>(FP[rA]);
    const bool is_smi = ((raw_value & kSmiTagMask) == kSmiTag);
    const bool may_be_smi = (rB == 1);
    const intptr_t cids_length = rC;
    if (LIKELY(!is_smi)) {
      const intptr_t cid = SimulatorHelpers::GetClassId(FP[rA]);
      for (intptr_t i = 0; i < cids_length; i += 2) {
        // Note unsigned type to get unsigned range check below.
        const uintptr_t cid_start = Bytecode::DecodeD(*(pc + i));
        const uintptr_t cids = Bytecode::DecodeD(*(pc + i + 1));
        if (cid - cid_start < cids) {
          pc++;
          break;
        }
      }
      pc += cids_length;
    } else {
      pc += cids_length;
      pc += (may_be_smi ? 1 : 0);
    }
    DISPATCH();
  }

  {
    BYTECODE(IfEqStrictTOS, 0);
    SP -= 2;
    if (SP[1] != SP[2]) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfNeStrictTOS, 0);
    SP -= 2;
    if (SP[1] == SP[2]) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfEqStrictNumTOS, 0);
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }

    SP -= 2;
    if (!SimulatorHelpers::IsStrictEqualWithNumberCheck(SP[1], SP[2])) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfNeStrictNumTOS, 0);
    if (thread->isolate()->single_step()) {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_SingleStepHandler, args);
    }

    SP -= 2;
    if (SimulatorHelpers::IsStrictEqualWithNumberCheck(SP[1], SP[2])) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfEqStrict, A_D);
    RawObject* lhs = FP[rA];
    RawObject* rhs = FP[rD];
    if (lhs != rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfNeStrict, A_D);
    RawObject* lhs = FP[rA];
    RawObject* rhs = FP[rD];
    if (lhs == rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfLe, A_D);
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rA]);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rD]);
    if (lhs > rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfLt, A_D);
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rA]);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rD]);
    if (lhs >= rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfGe, A_D);
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rA]);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rD]);
    if (lhs < rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfGt, A_D);
    const intptr_t lhs = reinterpret_cast<intptr_t>(FP[rA]);
    const intptr_t rhs = reinterpret_cast<intptr_t>(FP[rD]);
    if (lhs <= rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfULe, A_D);
    const uintptr_t lhs = reinterpret_cast<uintptr_t>(FP[rA]);
    const uintptr_t rhs = reinterpret_cast<uintptr_t>(FP[rD]);
    if (lhs > rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfULt, A_D);
    const uintptr_t lhs = reinterpret_cast<uintptr_t>(FP[rA]);
    const uintptr_t rhs = reinterpret_cast<uintptr_t>(FP[rD]);
    if (lhs >= rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfUGe, A_D);
    const uintptr_t lhs = reinterpret_cast<uintptr_t>(FP[rA]);
    const uintptr_t rhs = reinterpret_cast<uintptr_t>(FP[rD]);
    if (lhs < rhs) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfUGt, A_D);
    const uintptr_t lhs = reinterpret_cast<uintptr_t>(FP[rA]);
    const uintptr_t rhs = reinterpret_cast<uintptr_t>(FP[rD]);
    if (lhs <= rhs) {
      pc++;
    }
    DISPATCH();
  }

#if defined(ARCH_IS_64_BIT)
  {
    BYTECODE(IfDEq, A_D);
    const double lhs = bit_cast<double, RawObject*>(FP[rA]);
    const double rhs = bit_cast<double, RawObject*>(FP[rD]);
    pc += (lhs == rhs) ? 0 : 1;
    DISPATCH();
  }

  {
    BYTECODE(IfDNe, A_D);
    const double lhs = bit_cast<double, RawObject*>(FP[rA]);
    const double rhs = bit_cast<double, RawObject*>(FP[rD]);
    pc += (lhs != rhs) ? 0 : 1;
    DISPATCH();
  }

  {
    BYTECODE(IfDLe, A_D);
    const double lhs = bit_cast<double, RawObject*>(FP[rA]);
    const double rhs = bit_cast<double, RawObject*>(FP[rD]);
    pc += (lhs <= rhs) ? 0 : 1;
    DISPATCH();
  }

  {
    BYTECODE(IfDLt, A_D);
    const double lhs = bit_cast<double, RawObject*>(FP[rA]);
    const double rhs = bit_cast<double, RawObject*>(FP[rD]);
    pc += (lhs < rhs) ? 0 : 1;
    DISPATCH();
  }

  {
    BYTECODE(IfDGe, A_D);
    const double lhs = bit_cast<double, RawObject*>(FP[rA]);
    const double rhs = bit_cast<double, RawObject*>(FP[rD]);
    pc += (lhs >= rhs) ? 0 : 1;
    DISPATCH();
  }

  {
    BYTECODE(IfDGt, A_D);
    const double lhs = bit_cast<double, RawObject*>(FP[rA]);
    const double rhs = bit_cast<double, RawObject*>(FP[rD]);
    pc += (lhs > rhs) ? 0 : 1;
    DISPATCH();
  }
#else   // defined(ARCH_IS_64_BIT)
  {
    BYTECODE(IfDEq, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(IfDNe, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(IfDLe, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(IfDLt, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(IfDGe, A_D);
    UNREACHABLE();
    DISPATCH();
  }

  {
    BYTECODE(IfDGt, A_D);
    UNREACHABLE();
    DISPATCH();
  }
#endif  // defined(ARCH_IS_64_BIT)

  {
    BYTECODE(IfEqStrictNum, A_D);
    RawObject* lhs = FP[rA];
    RawObject* rhs = FP[rD];
    if (!SimulatorHelpers::IsStrictEqualWithNumberCheck(lhs, rhs)) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfNeStrictNum, A_D);
    RawObject* lhs = FP[rA];
    RawObject* rhs = FP[rD];
    if (SimulatorHelpers::IsStrictEqualWithNumberCheck(lhs, rhs)) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfEqNull, A);
    if (FP[rA] != null_value) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(IfNeNull, A_D);
    if (FP[rA] == null_value) {
      pc++;
    }
    DISPATCH();
  }

  {
    BYTECODE(Jump, 0);
    const int32_t target = static_cast<int32_t>(op) >> 8;
    pc += (target - 1);
    DISPATCH();
  }

  {
    BYTECODE(LoadClassId, A_D);
    const uint16_t object_reg = rD;
    RawObject* obj = static_cast<RawObject*>(FP[object_reg]);
    FP[rA] = SimulatorHelpers::GetClassIdAsSmi(obj);
    DISPATCH();
  }

  {
    BYTECODE(LoadClassIdTOS, 0);
    RawObject* obj = static_cast<RawObject*>(SP[0]);
    SP[0] = SimulatorHelpers::GetClassIdAsSmi(obj);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedTOS, 0);
    SP -= 3;
    RawArray* array = RAW_CAST(Array, SP[1]);
    RawSmi* index = RAW_CAST(Smi, SP[2]);
    RawObject* value = SP[3];
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    array->StorePointer(array->ptr()->data() + Smi::Value(index), value);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexed, A_B_C);
    RawArray* array = RAW_CAST(Array, FP[rA]);
    RawSmi* index = RAW_CAST(Smi, FP[rB]);
    RawObject* value = FP[rC];
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    array->StorePointer(array->ptr()->data() + Smi::Value(index), value);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedUint8, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rA], FP[rB]);
    *data = Smi::Value(RAW_CAST(Smi, FP[rC]));
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedExternalUint8, A_B_C);
    uint8_t* array = reinterpret_cast<uint8_t*>(FP[rA]);
    RawSmi* index = RAW_CAST(Smi, FP[rB]);
    RawSmi* value = RAW_CAST(Smi, FP[rC]);
    array[Smi::Value(index)] = Smi::Value(value);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedOneByteString, A_B_C);
    RawOneByteString* array = RAW_CAST(OneByteString, FP[rA]);
    RawSmi* index = RAW_CAST(Smi, FP[rB]);
    RawSmi* value = RAW_CAST(Smi, FP[rC]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    array->ptr()->data()[Smi::Value(index)] = Smi::Value(value);
    DISPATCH();
  }

  {
    BYTECODE(StoreIndexedUint32, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rA], FP[rB]);
    const uintptr_t value = reinterpret_cast<uintptr_t>(FP[rC]);
    *reinterpret_cast<uint32_t*>(data) = static_cast<uint32_t>(value);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexed, A_B_C);
    RawObject* obj = FP[rB];
    ASSERT(obj->IsArray() || obj->IsImmutableArray());
    RawArray* array = reinterpret_cast<RawArray*>(obj);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    FP[rA] = array->ptr()->data()[Smi::Value(index)];
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedUint8, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rB], FP[rC]);
    FP[rA] = Smi::New(*data);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedInt8, A_B_C);
    uint8_t* data = SimulatorHelpers::GetTypedData(FP[rB], FP[rC]);
    FP[rA] = Smi::New(*reinterpret_cast<int8_t*>(data));
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedUint32, A_B_C);
    const uint8_t* data = SimulatorHelpers::GetTypedData(FP[rB], FP[rC]);
    const uint32_t value = *reinterpret_cast<const uint32_t*>(data);
    FP[rA] = reinterpret_cast<RawObject*>(value);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedInt32, A_B_C);
    const uint8_t* data = SimulatorHelpers::GetTypedData(FP[rB], FP[rC]);
    const int32_t value = *reinterpret_cast<const int32_t*>(data);
    FP[rA] = reinterpret_cast<RawObject*>(value);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedExternalUint8, A_B_C);
    uint8_t* data = reinterpret_cast<uint8_t*>(FP[rB]);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    FP[rA] = Smi::New(data[Smi::Value(index)]);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedExternalInt8, A_B_C);
    int8_t* data = reinterpret_cast<int8_t*>(FP[rB]);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    FP[rA] = Smi::New(data[Smi::Value(index)]);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedOneByteString, A_B_C);
    RawOneByteString* array = RAW_CAST(OneByteString, FP[rB]);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    FP[rA] = Smi::New(array->ptr()->data()[Smi::Value(index)]);
    DISPATCH();
  }

  {
    BYTECODE(LoadIndexedTwoByteString, A_B_C);
    RawTwoByteString* array = RAW_CAST(TwoByteString, FP[rB]);
    RawSmi* index = RAW_CAST(Smi, FP[rC]);
    ASSERT(SimulatorHelpers::CheckIndex(index, array->ptr()->length_));
    FP[rA] = Smi::New(array->ptr()->data()[Smi::Value(index)]);
    DISPATCH();
  }

  {
    BYTECODE(Deopt, A_D);
    const bool is_lazy = rD == 0;
    if (!Deoptimize(thread, &pp, &pc, &FP, &SP, is_lazy)) {
      HANDLE_EXCEPTION;
    }
    DISPATCH();
  }

  {
    BYTECODE(DeoptRewind, 0);
    pc = reinterpret_cast<uint32_t*>(thread->resume_pc());
    if (!Deoptimize(thread, &pp, &pc, &FP, &SP, false /* eager */)) {
      HANDLE_EXCEPTION;
    }
    {
      Exit(thread, FP, SP + 1, pc);
      NativeArguments args(thread, 0, NULL, NULL);
      INVOKE_RUNTIME(DRT_RewindPostDeopt, args);
    }
    UNREACHABLE();  // DRT_RewindPostDeopt does not exit normally.
    DISPATCH();
  }

  {
    BYTECODE(Nop, 0);
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
    ASSERT(function_h.IsClosureFunction());
#endif

    // Restore caller context as we are going to throw NoSuchMethod.
    pc = SavedCallerPC(FP);

    const bool has_dart_caller = (reinterpret_cast<uword>(pc) & 2) == 0;
    const intptr_t argc = has_dart_caller ? Bytecode::DecodeArgc(pc[-1])
                                          : (reinterpret_cast<uword>(pc) >> 2);

    SP = FrameArguments(FP, 0);
    RawObject** args = SP - argc;
    FP = SavedCallerFP(FP);
    if (has_dart_caller) {
      pp = SimulatorHelpers::FrameCode(FP)->ptr()->object_pool_->ptr();
    }

    *++SP = null_value;
    *++SP = args[0];  // Closure object.
    *++SP = argdesc;
    *++SP = null_value;  // Array of arguments (will be filled).

    // Allocate array of arguments.
    {
      SP[1] = Smi::New(argc);  // length
      SP[2] = null_value;      // type
      Exit(thread, FP, SP + 3, pc);
      NativeArguments native_args(thread, 2, SP + 1, SP);
      INVOKE_RUNTIME(DRT_AllocateArray, native_args);

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

  // Single dispatch point used by exception handling macros.
  {
  DispatchAfterException:
    DISPATCH();
  }

  UNREACHABLE();
  return 0;
}

void Simulator::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
  // Walk over all setjmp buffers (simulated --> C++ transitions)
  // and try to find the setjmp associated with the simulated frame pointer.
  SimulatorSetjmpBuffer* buf = last_setjmp_buffer();
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
    special_[kExceptionSpecialIndex] = raw_exception;
    special_[kStackTraceSpecialIndex] = raw_stacktrace;
    pc_ = thread->resume_pc();
  } else {
    pc_ = pc;
  }

  buf->Longjmp();
  UNREACHABLE();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
