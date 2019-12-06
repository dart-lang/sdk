// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi.h"

#include <algorithm>

#include "platform/globals.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/compiler/runtime_api.h"
#include "vm/compiler/stub_code_compiler.h"
#include "vm/growable_array.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

static const size_t kSizeUnknown = 0;

static const intptr_t kNumElementSizes = kFfiVoidCid - kFfiPointerCid + 1;

static const size_t element_size_table[kNumElementSizes] = {
    target::kWordSize,  // kFfiPointerCid
    kSizeUnknown,       // kFfiNativeFunctionCid
    1,                  // kFfiInt8Cid
    2,                  // kFfiInt16Cid
    4,                  // kFfiInt32Cid
    8,                  // kFfiInt64Cid
    1,                  // kFfiUint8Cid
    2,                  // kFfiUint16Cid
    4,                  // kFfiUint32Cid
    8,                  // kFfiUint64Cid
    target::kWordSize,  // kFfiIntPtrCid
    4,                  // kFfiFloatCid
    8,                  // kFfiDoubleCid
    kSizeUnknown,       // kFfiVoidCid
};

size_t ElementSizeInBytes(intptr_t class_id) {
  ASSERT(class_id != kFfiNativeFunctionCid);
  ASSERT(class_id != kFfiVoidCid);
  if (!RawObject::IsFfiTypeClassId(class_id)) {
    // subtype of Pointer
    class_id = kFfiPointerCid;
  }
  intptr_t index = class_id - kFfiPointerCid;
  return element_size_table[index];
}

classid_t ElementTypedDataCid(classid_t class_id) {
  ASSERT(class_id >= kFfiPointerCid);
  ASSERT(class_id < kFfiVoidCid);
  ASSERT(class_id != kFfiNativeFunctionCid);
  switch (class_id) {
    case kFfiInt8Cid:
      return kTypedDataInt8ArrayCid;
    case kFfiUint8Cid:
      return kTypedDataUint8ArrayCid;
    case kFfiInt16Cid:
      return kTypedDataInt16ArrayCid;
    case kFfiUint16Cid:
      return kTypedDataUint16ArrayCid;
    case kFfiInt32Cid:
      return kTypedDataInt32ArrayCid;
    case kFfiUint32Cid:
      return kTypedDataUint32ArrayCid;
    case kFfiInt64Cid:
      return kTypedDataInt64ArrayCid;
    case kFfiUint64Cid:
      return kTypedDataUint64ArrayCid;
    case kFfiIntPtrCid:
      return target::kWordSize == 4 ? kTypedDataInt32ArrayCid
                                    : kTypedDataInt64ArrayCid;
    case kFfiPointerCid:
      return target::kWordSize == 4 ? kTypedDataUint32ArrayCid
                                    : kTypedDataUint64ArrayCid;
    case kFfiFloatCid:
      return kTypedDataFloat32ArrayCid;
    case kFfiDoubleCid:
      return kTypedDataFloat64ArrayCid;
    default:
      UNREACHABLE();
  }
}

classid_t RecognizedMethodTypeArgCid(MethodRecognizer::Kind kind) {
  switch (kind) {
#define LOAD_STORE(type)                                                       \
  case MethodRecognizer::kFfiLoad##type:                                       \
  case MethodRecognizer::kFfiStore##type:                                      \
    return kFfi##type##Cid;
    CLASS_LIST_FFI_NUMERIC(LOAD_STORE)
    LOAD_STORE(Pointer)
#undef LOAD_STORE
    default:
      UNREACHABLE();
  }
}

// See pkg/vm/lib/transformations/ffi.dart, which makes these assumptions.
struct AbiAlignmentDouble {
  int8_t use_one_byte;
  double d;
};
struct AbiAlignmentUint64 {
  int8_t use_one_byte;
  uint64_t i;
};

#if defined(HOST_ARCH_X64) || defined(HOST_ARCH_ARM64)
static_assert(offsetof(AbiAlignmentDouble, d) == 8,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 8,
              "FFI transformation alignment");
#elif (defined(HOST_ARCH_IA32) && /* NOLINT(whitespace/parens) */              \
       (defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||                    \
        defined(HOST_OS_ANDROID))) ||                                          \
    (defined(HOST_ARCH_ARM) && defined(HOST_OS_IOS))
static_assert(offsetof(AbiAlignmentDouble, d) == 4,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 4,
              "FFI transformation alignment");
#elif defined(HOST_ARCH_IA32) && defined(HOST_OS_WINDOWS) ||                   \
    defined(HOST_ARCH_ARM)
static_assert(offsetof(AbiAlignmentDouble, d) == 8,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 8,
              "FFI transformation alignment");
#else
#error "Unknown platform. Please add alignment requirements for ABI."
#endif

Abi TargetAbi() {
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64)
  return Abi::kWordSize64;
#elif (defined(TARGET_ARCH_IA32) && /* NOLINT(whitespace/parens) */            \
       (defined(TARGET_OS_LINUX) || defined(TARGET_OS_MACOS) ||                \
        defined(TARGET_OS_ANDROID))) ||                                        \
    (defined(TARGET_ARCH_ARM) && defined(TARGET_OS_IOS))
  return Abi::kWordSize32Align32;
#elif defined(TARGET_ARCH_IA32) && defined(TARGET_OS_WINDOWS) ||               \
    defined(TARGET_ARCH_ARM)
  return Abi::kWordSize32Align64;
#else
#error "Unknown platform. Please add alignment requirements for ABI."
#endif
}

#if !defined(DART_PRECOMPILED_RUNTIME)

Representation TypeRepresentation(classid_t class_id) {
  switch (class_id) {
    case kFfiFloatCid:
      return kUnboxedFloat;
    case kFfiDoubleCid:
      return kUnboxedDouble;
    case kFfiInt8Cid:
    case kFfiInt16Cid:
    case kFfiInt32Cid:
      return kUnboxedInt32;
    case kFfiUint8Cid:
    case kFfiUint16Cid:
    case kFfiUint32Cid:
      return kUnboxedUint32;
    case kFfiInt64Cid:
    case kFfiUint64Cid:
      return kUnboxedInt64;
    case kFfiIntPtrCid:
      return kUnboxedIntPtr;
    case kFfiPointerCid:
    case kFfiVoidCid:
      return kUnboxedFfiIntPtr;
    default:
      UNREACHABLE();
  }
}

SmallRepresentation TypeSmallRepresentation(const AbstractType& ffi_type) {
  switch (ffi_type.type_class_id()) {
    case kFfiInt8Cid:
      return kSmallUnboxedInt8;
    case kFfiInt16Cid:
      return kSmallUnboxedInt16;
    case kFfiUint8Cid:
      return kSmallUnboxedUint8;
    case kFfiUint16Cid:
      return kSmallUnboxedUint16;
    default:
      return kNoSmallRepresentation;
  }
}

bool NativeTypeIsVoid(const AbstractType& result_type) {
  return result_type.type_class_id() == kFfiVoidCid;
}

bool NativeTypeIsPointer(const AbstractType& result_type) {
  return result_type.type_class_id() == kFfiPointerCid;
}

// Converts a Ffi [signature] to a list of Representations.
// Note that this ignores first argument (receiver) which is dynamic.
template <class CallingConventions>
ZoneGrowableArray<Representation>* ArgumentRepresentationsBase(
    const Function& signature) {
  intptr_t num_arguments = signature.num_fixed_parameters() - 1;
  auto result = new ZoneGrowableArray<Representation>(num_arguments);
  for (intptr_t i = 0; i < num_arguments; i++) {
    AbstractType& arg_type =
        AbstractType::Handle(signature.ParameterTypeAt(i + 1));
    Representation rep = TypeRepresentation(arg_type.type_class_id());
    // In non simulator mode host::CallingConventions == CallingConventions.
    // In simulator mode convert arguments to host representation.
    if (rep == kUnboxedFloat && CallingConventions::kAbiSoftFP) {
      rep = kUnboxedInt32;
    } else if (rep == kUnboxedDouble && CallingConventions::kAbiSoftFP) {
      rep = kUnboxedInt64;
    }
    result->Add(rep);
  }
  return result;
}

template <class CallingConventions>
Representation ResultRepresentationBase(const Function& signature) {
  AbstractType& arg_type = AbstractType::Handle(signature.result_type());
  Representation rep = TypeRepresentation(arg_type.type_class_id());
  if (rep == kUnboxedFloat && CallingConventions::kAbiSoftFP) {
    rep = kUnboxedInt32;
  } else if (rep == kUnboxedDouble && CallingConventions::kAbiSoftFP) {
    rep = kUnboxedInt64;
  }
  return rep;
}

RawFunction* NativeCallbackFunction(const Function& c_signature,
                                    const Function& dart_target,
                                    const Instance& exceptional_return) {
  Thread* const thread = Thread::Current();
  const int32_t callback_id = thread->AllocateFfiCallbackId();

  // Create a new Function named '<target>_FfiCallback' and stick it in the
  // 'dart:ffi' library. Note that these functions will never be invoked by
  // Dart, so they have may have duplicate names.
  Zone* const zone = thread->zone();
  const auto& name = String::Handle(
      zone, Symbols::FromConcat(thread, Symbols::FfiCallback(),
                                String::Handle(zone, dart_target.name())));
  const Library& lib = Library::Handle(zone, Library::FfiLibrary());
  const Class& owner_class = Class::Handle(zone, lib.toplevel_class());
  const Function& function =
      Function::Handle(zone, Function::New(name, RawFunction::kFfiTrampoline,
                                           /*is_static=*/true,
                                           /*is_const=*/false,
                                           /*is_abstract=*/false,
                                           /*is_external=*/false,
                                           /*is_native=*/false, owner_class,
                                           TokenPosition::kNoSource));
  function.set_is_debuggable(false);

  // Set callback-specific fields which the flow-graph builder needs to generate
  // the body.
  function.SetFfiCSignature(c_signature);
  function.SetFfiCallbackId(callback_id);
  function.SetFfiCallbackTarget(dart_target);

  // We need to load the exceptional return value as a constant in the generated
  // function. Even though the FE ensures that it is a constant, it could still
  // be a literal allocated in new space. We need to copy it into old space in
  // that case.
  //
  // Exceptional return values currently cannot be pointers because we don't
  // have constant pointers.
  //
  // TODO(36730): We'll need to extend this when we support passing/returning
  // structs by value.
  ASSERT(exceptional_return.IsNull() || exceptional_return.IsNumber());
  if (!exceptional_return.IsSmi() && exceptional_return.IsNew()) {
    function.SetFfiCallbackExceptionalReturn(Instance::Handle(
        zone, exceptional_return.CopyShallowToOldSpace(thread)));
  } else {
    function.SetFfiCallbackExceptionalReturn(exceptional_return);
  }

  return function.raw();
}

ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature) {
  return ArgumentRepresentationsBase<CallingConventions>(signature);
}

Representation ResultRepresentation(const Function& signature) {
  return ResultRepresentationBase<CallingConventions>(signature);
}

#if defined(USING_SIMULATOR)

ZoneGrowableArray<Representation>* ArgumentHostRepresentations(
    const Function& signature) {
  return ArgumentRepresentationsBase<host::CallingConventions>(signature);
}

Representation ResultHostRepresentation(const Function& signature) {
  return ResultRepresentationBase<host::CallingConventions>(signature);
}

#endif  // defined(USING_SIMULATOR)

// Represents the state of a stack frame going into a call, between allocations
// of argument locations. Acts like a register allocator but for arguments in
// the native ABI.
template <class CallingConventions,
          class Location,
          class Register,
          class FpuRegister>
class ArgumentAllocator : public ValueObject {
 public:
  Location AllocateArgument(Representation rep) {
    switch (rep) {
      case kUnboxedFloat:
      case kUnboxedDouble: {
        Location result = AllocateFpuRegister();
        if (!result.IsUnallocated()) return result;
        break;
      }
      case kUnboxedInt64:
      case kUnboxedUint32:
      case kUnboxedInt32: {
        Location result = rep == kUnboxedInt64 && target::kWordSize == 4
                              ? AllocateAlignedRegisterPair()
                              : AllocateCpuRegister();
        if (!result.IsUnallocated()) return result;
        break;
      }
      default:
        UNREACHABLE();
    }

    // Argument must be spilled.
    if (rep == kUnboxedInt64 && target::kWordSize == 4) {
      return AllocateAlignedStackSlots(rep);
    } else if (rep == kUnboxedDouble) {
      // By convention, we always use DoubleStackSlot for doubles, even on
      // 64-bit systems.
      ASSERT(!CallingConventions::kAlignArguments);
      return AllocateDoubleStackSlot();
    } else {
      return AllocateStackSlot();
    }
  }

 private:
  Location AllocateStackSlot() {
    return Location::StackSlot(stack_height_in_slots++,
                               CallingConventions::kStackPointerRegister);
  }

  Location AllocateDoubleStackSlot() {
    const Location result = Location::DoubleStackSlot(
        stack_height_in_slots, CallingConventions::kStackPointerRegister);
    stack_height_in_slots += 8 / target::kWordSize;
    return result;
  }

  // Allocates a pair of stack slots where the first stack slot is aligned to an
  // 8-byte boundary, if necessary.
  Location AllocateAlignedStackSlots(Representation rep) {
    if (CallingConventions::kAlignArguments && target::kWordSize == 4) {
      stack_height_in_slots += stack_height_in_slots % 2;
    }

    Location result;
    if (rep == kUnboxedDouble) {
      result = Location::DoubleStackSlot(
          stack_height_in_slots, CallingConventions::kStackPointerRegister);
      stack_height_in_slots += 2;
    } else {
      const Location low = AllocateStackSlot();
      const Location high = AllocateStackSlot();
      result = Location::Pair(low, high);
    }
    return result;
  }

  Location AllocateFpuRegister() {
    if (fpu_regs_used == CallingConventions::kNumFpuArgRegs) {
      return Location::RequiresFpuRegister();
    }

    const Location result = Location::FpuRegisterLocation(
        CallingConventions::FpuArgumentRegisters[fpu_regs_used]);
    fpu_regs_used++;
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      cpu_regs_used++;
    }
    return result;
  }

  Location AllocateCpuRegister() {
    if (cpu_regs_used == CallingConventions::kNumArgRegs) {
      return Location::RequiresRegister();
    }

    const Location result = Location::RegisterLocation(
        CallingConventions::ArgumentRegisters[cpu_regs_used]);
    cpu_regs_used++;
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      fpu_regs_used++;
    }
    return result;
  }

  // Allocates a pair of registers where the first register index is even, if
  // necessary.
  Location AllocateAlignedRegisterPair() {
    if (CallingConventions::kAlignArguments) {
      cpu_regs_used += cpu_regs_used % 2;
    }
    if (cpu_regs_used > CallingConventions::kNumArgRegs - 2) {
      return Location::Any();
    }
    return Location::Pair(AllocateCpuRegister(), AllocateCpuRegister());
  }

  intptr_t cpu_regs_used = 0;
  intptr_t fpu_regs_used = 0;
  intptr_t stack_height_in_slots = 0;
};

ZoneGrowableArray<Location>*
CallbackArgumentTranslator::TranslateArgumentLocations(
    const ZoneGrowableArray<Location>& arg_locs) {
  auto& pushed_locs = *(new ZoneGrowableArray<Location>(arg_locs.length()));

  CallbackArgumentTranslator translator;
  for (intptr_t i = 0, n = arg_locs.length(); i < n; i++) {
    translator.AllocateArgument(arg_locs[i]);
  }
  for (intptr_t i = 0, n = arg_locs.length(); i < n; ++i) {
    pushed_locs.Add(translator.TranslateArgument(arg_locs[i]));
  }

  return &pushed_locs;
}

void CallbackArgumentTranslator::AllocateArgument(Location arg) {
  if (arg.IsPairLocation()) {
    AllocateArgument(arg.Component(0));
    AllocateArgument(arg.Component(1));
    return;
  }
  if (arg.HasStackIndex()) return;
  ASSERT(arg.IsRegister() || arg.IsFpuRegister());
  if (arg.IsRegister()) {
    argument_slots_required_++;
  } else {
    argument_slots_required_ += 8 / target::kWordSize;
  }
}

Location CallbackArgumentTranslator::TranslateArgument(Location arg) {
  if (arg.IsPairLocation()) {
    const Location low = TranslateArgument(arg.Component(0));
    const Location high = TranslateArgument(arg.Component(1));
    return Location::Pair(low, high);
  }

  if (arg.HasStackIndex()) {
    // Add extra slots after the saved arguments for the return address and
    // frame pointer of the dummy arguments frame, which will be between the
    // saved argument registers and stack arguments. Also add slots for the
    // shadow space if present (factored into
    // kCallbackSlotsBeforeSavedArguments).
    //
    // Finally, if we are using NativeCallbackTrampolines, factor in the extra
    // stack space corresponding to those trampolines' frames (above the entry
    // frame).
    intptr_t stack_delta = kCallbackSlotsBeforeSavedArguments;
    if (NativeCallbackTrampolines::Enabled()) {
      stack_delta += StubCodeCompiler::kNativeCallbackTrampolineStackDelta;
    }
    FrameRebase rebase(
        /*old_base=*/SPREG, /*new_base=*/SPREG,
        /*stack_delta=*/argument_slots_required_ + stack_delta);
    return rebase.Rebase(arg);
  }

  if (arg.IsRegister()) {
    return Location::StackSlot(argument_slots_used_++, SPREG);
  }

  ASSERT(arg.IsFpuRegister());
  const Location result =
      Location::DoubleStackSlot(argument_slots_used_, SPREG);
  argument_slots_used_ += 8 / target::kWordSize;
  return result;
}

// Takes a list of argument representations, and converts it to a list of
// argument locations based on calling convention.
template <class CallingConventions,
          class Location,
          class Register,
          class FpuRegister>
ZoneGrowableArray<Location>* ArgumentLocationsBase(
    const ZoneGrowableArray<Representation>& arg_reps) {
  intptr_t num_arguments = arg_reps.length();
  auto result = new ZoneGrowableArray<Location>(num_arguments);

  // Loop through all arguments and assign a register or a stack location.
  ArgumentAllocator<CallingConventions, Location, Register, FpuRegister>
      frame_state;
  for (intptr_t i = 0; i < num_arguments; i++) {
    Representation rep = arg_reps[i];
    result->Add(frame_state.AllocateArgument(rep));
  }
  return result;
}

ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps) {
  return ArgumentLocationsBase<dart::CallingConventions, Location,
                               dart::Register, dart::FpuRegister>(arg_reps);
}

Location ResultLocation(Representation result_rep) {
  switch (result_rep) {
    case kUnboxedFloat:
    case kUnboxedDouble:
#if defined(TARGET_ARCH_IA32)
      // The result is returned in ST0, but we don't allocate ST registers, so
      // the FFI trampoline will move it to XMM0.
      return Location::FpuRegisterLocation(XMM0);
#else
      return Location::FpuRegisterLocation(CallingConventions::kReturnFpuReg);
#endif
    case kUnboxedInt32:
    case kUnboxedUint32:
      return Location::RegisterLocation(CallingConventions::kReturnReg);
    case kUnboxedInt64:
      if (target::kWordSize == 4) {
        return Location::Pair(
            Location::RegisterLocation(CallingConventions::kReturnReg),
            Location::RegisterLocation(CallingConventions::kSecondReturnReg));
      } else {
        return Location::RegisterLocation(CallingConventions::kReturnReg);
      }
    default:
      UNREACHABLE();
  }
}

// TODO(36607): Cache the trampolines.
RawFunction* TrampolineFunction(const Function& dart_signature,
                                const Function& c_signature) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  String& name = String::Handle(zone, Symbols::New(thread, "FfiTrampoline"));
  const Library& lib = Library::Handle(zone, Library::FfiLibrary());
  const Class& owner_class = Class::Handle(zone, lib.toplevel_class());
  Function& function =
      Function::Handle(zone, Function::New(name, RawFunction::kFfiTrampoline,
                                           /*is_static=*/true,
                                           /*is_const=*/false,
                                           /*is_abstract=*/false,
                                           /*is_external=*/false,
                                           /*is_native=*/false, owner_class,
                                           TokenPosition::kMinSource));
  function.set_is_debuggable(false);
  function.set_num_fixed_parameters(dart_signature.num_fixed_parameters());
  function.set_result_type(AbstractType::Handle(dart_signature.result_type()));
  function.set_parameter_types(Array::Handle(dart_signature.parameter_types()));

  // The signature function won't have any names for the parameters. We need to
  // assign unique names for scope building and error messages.
  const intptr_t num_params = dart_signature.num_fixed_parameters();
  const Array& parameter_names = Array::Handle(Array::New(num_params));
  for (intptr_t i = 0; i < num_params; ++i) {
    if (i == 0) {
      name = Symbols::ClosureParameter().raw();
    } else {
      name = Symbols::NewFormatted(thread, ":ffi_param%" Pd, i);
    }
    parameter_names.SetAt(i, name);
  }
  function.set_parameter_names(parameter_names);
  function.SetFfiCSignature(c_signature);

  return function.raw();
}

// Accounts for alignment, where some stack slots are used as padding.
template <class Location>
intptr_t TemplateNumStackSlots(const ZoneGrowableArray<Location>& locations) {
  intptr_t num_arguments = locations.length();
  intptr_t max_height_in_slots = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    intptr_t height = 0;
    if (locations.At(i).IsStackSlot()) {
      height = locations.At(i).stack_index() + 1;
    } else if (locations.At(i).IsDoubleStackSlot()) {
      height = locations.At(i).stack_index() + 8 / target::kWordSize;
    } else if (locations.At(i).IsPairLocation()) {
      const Location first = locations.At(i).AsPairLocation()->At(0);
      const Location second = locations.At(i).AsPairLocation()->At(1);
      height = std::max(first.IsStackSlot() ? first.stack_index() + 1 : 0,
                        second.IsStackSlot() ? second.stack_index() + 1 : 0);
    }
    max_height_in_slots = std::max(height, max_height_in_slots);
  }
  return max_height_in_slots;
}

intptr_t NumStackSlots(const ZoneGrowableArray<Location>& locations) {
  return TemplateNumStackSlots(locations);
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
