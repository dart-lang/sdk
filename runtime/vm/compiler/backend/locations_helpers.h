// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains two helper functions MakeLocationSummaryFromEmitter
// and InvokeEmitter which simplify the definition of MakeLocationSummary
// and EmitNativeCode methods for instructions.
//
// Canonical way to define instruction backend would be to override:
//
// A) MakeLocationSummary method that creates and fills LocationSummary object
// with location constraints for register allocator;
//
// B) EmitNativeCode method that unpacks results of register allocation from
// LocationSummary and uses them to generate native code.
//
// Helpers contained in this file allow to "autogenerate" both of these methods
// from a single *emitter* function that has the following signature:
//
//        void Emitter(FlowGraphCompiler*,
//                     Instr* instr,
//                     OutType out,
//                     InputType1 v1, ...)
//
// Here Instr is the type of the instruction, OutType is a type of an output
// register and InputType1, InputType2, etc are register types for inputs or
// temps.
//
// To create LocationSummary from emitter's signature invoke
//
//        MakeLocationSummaryFromEmitter(zone, instr, &Emitter);
//
// To unpack allocation results from LocationSummary and call emitter write
//
//        InvokeEmitter(zone, instr, &Emitter)
//
// See DEFINE_BACKEND macro below that can be used to do that.
//
// In addition to supporting Register and FpuRegister types several markers can
// be used to denote various register constraints, e.g. SameAsFirstInput, Fixed
// and Temp. See below.
//
#ifndef RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_HELPERS_H_
#define RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_HELPERS_H_

#include "vm/compiler/backend/locations.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;

#define DEFINE_BACKEND(Name, Args)                                             \
  static void EmitterFor##Name(FlowGraphCompiler* compiler,                    \
                               Name##Instr* instr, PP_APPLY(PP_UNPACK, Args)); \
  LocationSummary* Name##Instr::MakeLocationSummary(Zone* zone, bool opt)      \
      const {                                                                  \
    return MakeLocationSummaryFromEmitter(zone, this, &EmitterFor##Name);      \
  }                                                                            \
  void Name##Instr::EmitNativeCode(FlowGraphCompiler* compiler) {              \
    InvokeEmitter(compiler, this, &EmitterFor##Name);                          \
  }                                                                            \
  static void EmitterFor##Name(FlowGraphCompiler* compiler,                    \
                               Name##Instr* instr, PP_APPLY(PP_UNPACK, Args))

#define PP_UNPACK(...) __VA_ARGS__
#define PP_APPLY(a, b) a b

// Trait that specifies how different types of locations (e.g. Register,
// FpuRegister) can be extracted from Location objects and how register
// constraints can be created for different location types and markers like
// Temp, Fixed and SameAsFirstInput.
template <typename T>
struct LocationTrait;

// Marker type used to signal that output has SameAsFirstInput register
// constraint, which means that the first input needs to be in a writable
// register and the instruction will produce output in the same register.
struct SameAsFirstInput {};

// Marker type used to signal that this input, output or temp needs to
// be in a fixed register `reg` of type `R` (either Register or FpuRegister).
template <typename R, R reg>
struct Fixed {
  // Allow implicit coercion of Fixed<R, ...> to R.
  operator R() { return reg; }
};

// Marker type to signal that emitter needs a temporary register of type R.
template <typename R>
class Temp {
 private:
  typedef typename LocationTrait<R>::RegisterType RegisterType;

 public:
  explicit Temp(R reg) : reg_(reg) {}

  operator RegisterType() { return reg_; }

 private:
  R reg_;
};

// Implementation of MakeLocationSummaryFromEmitter and InvokeEmitter.

template <>
struct LocationTrait<Register> {
  typedef Register RegisterType;

  static const bool kIsTemp = false;  // This is not a temporary.

  static Register Unwrap(const Location& loc) { return loc.reg(); }

  template <intptr_t arity, intptr_t index>
  static Register UnwrapInput(LocationSummary* locs) {
    return Unwrap(locs->in(index));
  }

  template <intptr_t arity, intptr_t index>
  static void SetInputConstraint(LocationSummary* locs) {
    locs->set_in(index, ToConstraint());
  }

  static Location ToConstraint() { return Location::RequiresRegister(); }
  static Location ToFixedConstraint(Register reg) {
    return Location::RegisterLocation(reg);
  }
};

template <>
struct LocationTrait<FpuRegister> {
  typedef FpuRegister RegisterType;

  static const bool kIsTemp = false;  // This is not a temporary.

  static FpuRegister Unwrap(const Location& loc) { return loc.fpu_reg(); }

  template <intptr_t arity, intptr_t index>
  static FpuRegister UnwrapInput(LocationSummary* locs) {
    return Unwrap(locs->in(index));
  }

  template <intptr_t arity, intptr_t index>
  static void SetInputConstraint(LocationSummary* locs) {
    locs->set_in(index, ToConstraint());
  }

  static Location ToConstraint() { return Location::RequiresFpuRegister(); }
  static Location ToFixedConstraint(FpuRegister reg) {
    return Location::FpuRegisterLocation(reg);
  }
};

template <typename R, R reg>
struct LocationTrait<Fixed<R, reg> > {
  typedef R RegisterType;

  static const bool kIsTemp = false;  // This is not a temporary.

  static Fixed<R, reg> Unwrap(const Location& loc) {
    ASSERT(LocationTrait<R>::Unwrap(loc) == reg);
    return Fixed<R, reg>();
  }

  template <intptr_t arity, intptr_t index>
  static Fixed<R, reg> UnwrapInput(LocationSummary* locs) {
    return Unwrap(locs->in(index));
  }

  template <intptr_t arity, intptr_t index>
  static void SetInputConstraint(LocationSummary* locs) {
    locs->set_in(index, ToConstraint());
  }

  static Location ToConstraint() {
    return LocationTrait<R>::ToFixedConstraint(reg);
  }
};

template <typename RegisterType>
struct LocationTrait<Temp<RegisterType> > {
  static const bool kIsTemp = true;  // This is a temporary.

  static Temp<RegisterType> Unwrap(const Location& loc) {
    return Temp<RegisterType>(LocationTrait<RegisterType>::Unwrap(loc));
  }

  template <intptr_t arity, intptr_t index>
  static Temp<RegisterType> UnwrapInput(LocationSummary* locs) {
    return Unwrap(locs->temp(index - arity));
  }

  template <intptr_t arity, intptr_t index>
  static void SetInputConstraint(LocationSummary* locs) {
    locs->set_temp(index - arity, ToConstraint());
  }

  static Location ToConstraint() {
    return LocationTrait<RegisterType>::ToConstraint();
  }
};

template <>
struct LocationTrait<SameAsFirstInput> {
  static const bool kIsTemp = false;  // This is not a temporary.

  static SameAsFirstInput Unwrap(const Location& loc) {
    return SameAsFirstInput();
  }

  static Location ToConstraint() { return Location::SameAsFirstInput(); }
};

// Auxiliary types and macro helpers to construct lists of types.
// TODO(vegorov) rewrite this using variadic templates when we enable C++11

struct Nil;

template <typename T, typename U>
struct Cons {};

#define TYPE_LIST_0() Nil
#define TYPE_LIST_1(T0) Cons<T0, TYPE_LIST_0()>
#define TYPE_LIST_2(T0, T1) Cons<T0, TYPE_LIST_1(T1)>
#define TYPE_LIST_3(T0, T1, T2) Cons<T0, TYPE_LIST_2(T1, T2)>
#define TYPE_LIST_4(T0, T1, T2, T3) Cons<T0, TYPE_LIST_3(T1, T2, T3)>
#define TYPE_LIST_5(T0, T1, T2, T3, T4) Cons<T0, TYPE_LIST_4(T1, T2, T3, T4)>

// SignatureTrait is a recursively defined type that calculates InputCount and
// TempCount for a signature and can be used to invoke SetInputConstraint for
// each type in a signature to populate location summary with correct
// constraints.
#define SIGNATURE_TRAIT(Arity, Args)                                           \
  SignatureTrait<PP_APPLY(TYPE_LIST_##Arity, Args)>

template <typename T>
struct SignatureTrait;

template <>
struct SignatureTrait<Nil> {
  enum { kArity = 0, kTempCount = 0, kInputCount = kArity - kTempCount };

  template <intptr_t kArity, intptr_t kOffset>
  static void SetConstraints(LocationSummary* locs) {}
};

template <typename T0, typename Tx>
struct SignatureTrait<Cons<T0, Tx> > {
  typedef SignatureTrait<Tx> Tail;

  enum {
    kArity = 1 + Tail::kArity,
    kTempCount = (LocationTrait<T0>::kIsTemp ? 1 : 0) + Tail::kTempCount,
    kInputCount = kArity - kTempCount
  };

  template <intptr_t kArity, intptr_t kOffset>
  static void SetConstraints(LocationSummary* locs) {
    LocationTrait<T0>::template SetInputConstraint<kArity, kOffset>(locs);
    Tail::template SetConstraints<kArity, kOffset + 1>(locs);
  }
};

// MakeLocationSummaryFromEmitter overloadings below.

template <typename Instr, typename Out>
LocationSummary* MakeLocationSummaryFromEmitter(Zone* zone,
                                                const Instr* instr,
                                                void (*Emit)(FlowGraphCompiler*,
                                                             Instr*,
                                                             Out)) {
  typedef SIGNATURE_TRAIT(0, ()) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* summary = new (zone) LocationSummary(
      zone, S::kInputCount, S::kTempCount, LocationSummary::kNoCall);
  summary->set_out(0, LocationTrait<Out>::ToConstraint());
  return summary;
}

#define DEFINE_MAKE_LOCATION_SUMMARY_SPECIALIZATION(Arity, Types)              \
  LocationSummary* MakeLocationSummaryFromEmitter(                             \
      Zone* zone, const Instr* instr,                                          \
      void (*Emit)(FlowGraphCompiler*, Instr*, Out,                            \
                   PP_APPLY(PP_UNPACK, Types))) {                              \
    typedef SIGNATURE_TRAIT(Arity, Types) S;                                   \
    ASSERT(instr->InputCount() == S::kInputCount);                             \
    LocationSummary* summary = new (zone) LocationSummary(                     \
        zone, S::kInputCount, S::kTempCount, LocationSummary::kNoCall);        \
    S::template SetConstraints<S::kInputCount, 0>(summary);                    \
    summary->set_out(0, LocationTrait<Out>::ToConstraint());                   \
    return summary;                                                            \
  }

template <typename Instr, typename Out, typename T0>
DEFINE_MAKE_LOCATION_SUMMARY_SPECIALIZATION(1, (T0));

template <typename Instr, typename Out, typename T0, typename T1>
DEFINE_MAKE_LOCATION_SUMMARY_SPECIALIZATION(2, (T0, T1));

template <typename Instr, typename Out, typename T0, typename T1, typename T2>
DEFINE_MAKE_LOCATION_SUMMARY_SPECIALIZATION(3, (T0, T1, T2));

template <typename Instr,
          typename Out,
          typename T0,
          typename T1,
          typename T2,
          typename T3>
DEFINE_MAKE_LOCATION_SUMMARY_SPECIALIZATION(4, (T0, T1, T2, T3));

template <typename Instr,
          typename Out,
          typename T0,
          typename T1,
          typename T2,
          typename T3,
          typename T4>
DEFINE_MAKE_LOCATION_SUMMARY_SPECIALIZATION(5, (T0, T1, T2, T3, T4));

// InvokeEmitter overloadings below.

template <typename Instr, typename Out>
void InvokeEmitter(FlowGraphCompiler* compiler,
                   Instr* instr,
                   void (*Emit)(FlowGraphCompiler*, Instr*, Out)) {
  typedef SIGNATURE_TRAIT(0, ()) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* locs = instr->locs();
  Emit(compiler, instr, LocationTrait<Out>::Unwrap(locs->out(0)));
}

template <typename Instr, typename Out, typename T0>
void InvokeEmitter(FlowGraphCompiler* compiler,
                   Instr* instr,
                   void (*Emit)(FlowGraphCompiler*, Instr*, Out, T0)) {
  typedef SIGNATURE_TRAIT(1, (T0)) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* locs = instr->locs();
  Emit(compiler, instr, LocationTrait<Out>::Unwrap(locs->out(0)),
       LocationTrait<T0>::template UnwrapInput<S::kInputCount, 0>(locs));
}

template <typename Instr, typename Out, typename T0, typename T1>
void InvokeEmitter(FlowGraphCompiler* compiler,
                   Instr* instr,
                   void (*Emit)(FlowGraphCompiler*, Instr*, Out, T0, T1)) {
  typedef SIGNATURE_TRAIT(2, (T0, T1)) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* locs = instr->locs();
  Emit(compiler, instr, LocationTrait<Out>::Unwrap(locs->out(0)),
       LocationTrait<T0>::template UnwrapInput<S::kInputCount, 0>(locs),
       LocationTrait<T1>::template UnwrapInput<S::kInputCount, 1>(locs));
}

template <typename Instr, typename Out, typename T0, typename T1, typename T2>
void InvokeEmitter(FlowGraphCompiler* compiler,
                   Instr* instr,
                   void (*Emit)(FlowGraphCompiler*, Instr*, Out, T0, T1, T2)) {
  typedef SIGNATURE_TRAIT(3, (T0, T1, T2)) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* locs = instr->locs();
  Emit(compiler, instr, LocationTrait<Out>::Unwrap(locs->out(0)),
       LocationTrait<T0>::template UnwrapInput<S::kInputCount, 0>(locs),
       LocationTrait<T1>::template UnwrapInput<S::kInputCount, 1>(locs),
       LocationTrait<T2>::template UnwrapInput<S::kInputCount, 2>(locs));
}

template <typename Instr,
          typename Out,
          typename T0,
          typename T1,
          typename T2,
          typename T3>
void InvokeEmitter(
    FlowGraphCompiler* compiler,
    Instr* instr,
    void (*Emit)(FlowGraphCompiler*, Instr*, Out, T0, T1, T2, T3)) {
  typedef SIGNATURE_TRAIT(4, (T0, T1, T2, T3)) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* locs = instr->locs();
  Emit(compiler, instr, LocationTrait<Out>::Unwrap(locs->out(0)),
       LocationTrait<T0>::template UnwrapInput<S::kInputCount, 0>(locs),
       LocationTrait<T1>::template UnwrapInput<S::kInputCount, 1>(locs),
       LocationTrait<T2>::template UnwrapInput<S::kInputCount, 2>(locs),
       LocationTrait<T3>::template UnwrapInput<S::kInputCount, 3>(locs));
}

template <typename Instr,
          typename Out,
          typename T0,
          typename T1,
          typename T2,
          typename T3,
          typename T4>
void InvokeEmitter(
    FlowGraphCompiler* compiler,
    Instr* instr,
    void (*Emit)(FlowGraphCompiler*, Instr*, Out, T0, T1, T2, T3, T4)) {
  typedef SIGNATURE_TRAIT(5, (T0, T1, T2, T3, T4)) S;
  ASSERT(instr->InputCount() == S::kInputCount);
  LocationSummary* locs = instr->locs();
  Emit(compiler, instr, LocationTrait<Out>::Unwrap(locs->out(0)),
       LocationTrait<T0>::template UnwrapInput<S::kInputCount, 0>(locs),
       LocationTrait<T1>::template UnwrapInput<S::kInputCount, 1>(locs),
       LocationTrait<T2>::template UnwrapInput<S::kInputCount, 2>(locs),
       LocationTrait<T3>::template UnwrapInput<S::kInputCount, 3>(locs),
       LocationTrait<T4>::template UnwrapInput<S::kInputCount, 4>(locs));
}

}  // namespace dart

#if defined(TARGET_ARCH_IA32)

#elif defined(TARGET_ARCH_X64)

#elif defined(TARGET_ARCH_ARM)
#include "vm/compiler/backend/locations_helpers_arm.h"
#elif defined(TARGET_ARCH_ARM64)

#elif defined(TARGET_ARCH_DBC)

#else
#error Unknown architecture.
#endif

#endif  // RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_HELPERS_H_
