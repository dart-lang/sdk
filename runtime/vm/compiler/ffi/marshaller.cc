// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/marshaller.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/class_id.h"
#include "vm/compiler/ffi/frame_rebase.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/exceptions.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/log.h"
#include "vm/object_store.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

// Argument #0 is the function pointer.
const intptr_t kNativeParamsStartAt = 1;

// Representations of the arguments and return value of a C signature function.
const NativeFunctionType* NativeFunctionTypeFromFunctionType(
    Zone* zone,
    const FunctionType& c_signature,
    const char** error) {
  ASSERT(c_signature.NumOptionalParameters() == 0);
  ASSERT(c_signature.NumOptionalPositionalParameters() == 0);
  ObjectStore* object_store = IsolateGroup::Current()->object_store();

  const intptr_t num_arguments =
      c_signature.num_fixed_parameters() - kNativeParamsStartAt;
  auto& argument_representations =
      *new ZoneGrowableArray<const NativeType*>(zone, num_arguments);
  AbstractType& arg_type = AbstractType::Handle(zone);
  intptr_t variadic_arguments_index = NativeFunctionType::kNoVariadicArguments;
  for (intptr_t i = 0; i < num_arguments; i++) {
    arg_type = c_signature.ParameterTypeAt(i + kNativeParamsStartAt);
    const bool varargs = arg_type.type_class() == object_store->varargs_class();
    if (varargs) {
      arg_type = TypeArguments::Handle(zone, Type::Cast(arg_type).arguments())
                     .TypeAt(0);
      variadic_arguments_index = i;
      ASSERT(arg_type.IsRecordType());
      const auto& record_type = RecordType::Cast(arg_type);
      const intptr_t num_fields = record_type.NumFields();
      auto& field_type = AbstractType::Handle(zone);
      for (intptr_t i = 0; i < num_fields; i++) {
        field_type ^= record_type.FieldTypeAt(i);
        const auto rep = NativeType::FromAbstractType(zone, field_type, error);
        if (*error != nullptr) {
          return nullptr;
        }
        argument_representations.Add(rep);
      }
    } else {
      const auto rep = NativeType::FromAbstractType(zone, arg_type, error);
      if (*error != nullptr) {
        return nullptr;
      }
      argument_representations.Add(rep);
    }
  }

  const auto& result_type =
      AbstractType::Handle(zone, c_signature.result_type());
  const auto result_representation =
      NativeType::FromAbstractType(zone, result_type, error);
  if (*error != nullptr) {
    return nullptr;
  }

  const auto result = new (zone)
      NativeFunctionType(argument_representations, *result_representation,
                         variadic_arguments_index);
  return result;
}

CallMarshaller* CallMarshaller::FromFunction(Zone* zone,
                                             const Function& function,
                                             const FunctionType& c_signature,
                                             const char** error) {
  DEBUG_ASSERT(function.IsNotTemporaryScopedHandle());
  DEBUG_ASSERT(c_signature.IsNotTemporaryScopedHandle());
  const auto native_function_signature =
      NativeFunctionTypeFromFunctionType(zone, c_signature, error);
  if (*error != nullptr) {
    return nullptr;
  }
  const auto& native_calling_convention =
      NativeCallingConvention::FromSignature(zone, *native_function_signature);
  return new (zone)
      CallMarshaller(zone, function, c_signature, native_calling_convention);
}

AbstractTypePtr BaseMarshaller::CType(intptr_t arg_index) const {
  if (arg_index == kResultIndex) {
    return c_signature_.result_type();
  }

  Zone* zone = Thread::Current()->zone();
  const auto& parameter_types =
      Array::Handle(zone, c_signature_.parameter_types());
  const intptr_t parameter_type_length = parameter_types.Length();
  const intptr_t last_param_index = parameter_type_length - 1;
  const auto& last_arg_type = AbstractType::Handle(
      zone, c_signature_.ParameterTypeAt(last_param_index));
  ObjectStore* object_store = IsolateGroup::Current()->object_store();
  const bool has_varargs =
      last_arg_type.type_class() == object_store->varargs_class();

  // Skip #0 argument, the function pointer.
  const intptr_t real_arg_index = arg_index + kNativeParamsStartAt;

  if (has_varargs && real_arg_index >= last_param_index) {
    // The C-type is nested in a VarArgs.
    const auto& var_args_type_arg = AbstractType::Handle(
        zone, TypeArguments::Handle(zone, Type::Cast(last_arg_type).arguments())
                  .TypeAt(0));
    if (var_args_type_arg.IsRecordType()) {
      const intptr_t index_in_record = real_arg_index - last_param_index;
      const auto& record_type = RecordType::Cast(var_args_type_arg);
      ASSERT(index_in_record < record_type.NumFields());
      return record_type.FieldTypeAt(index_in_record);
    } else {
      ASSERT(!var_args_type_arg.IsNull());
      return var_args_type_arg.ptr();
    }
  }

  ASSERT(!AbstractType::Handle(c_signature_.ParameterTypeAt(real_arg_index))
              .IsNull());
  return c_signature_.ParameterTypeAt(real_arg_index);
}

// Keep consistent with Function::FfiCSignatureReturnsStruct.
bool BaseMarshaller::IsCompound(intptr_t arg_index) const {
  const auto& type = AbstractType::Handle(zone_, CType(arg_index));
  if (IsFfiTypeClassId(type.type_class_id())) {
    return false;
  }
  const auto& cls = Class::Handle(this->zone_, type.type_class());
  const auto& superClass = Class::Handle(this->zone_, cls.SuperClass());
  const bool is_abi_specific_int =
      String::Handle(this->zone_, superClass.UserVisibleName())
          .Equals(Symbols::AbiSpecificInteger());
  if (is_abi_specific_int) {
    return false;
  }
#ifdef DEBUG
  const bool is_struct =
      String::Handle(this->zone_, superClass.UserVisibleName())
          .Equals(Symbols::Struct());
  const bool is_union =
      String::Handle(this->zone_, superClass.UserVisibleName())
          .Equals(Symbols::Union());
  ASSERT(is_struct || is_union);
#endif
  return true;
}

bool BaseMarshaller::ContainsHandles() const {
  return c_signature_.ContainsHandles();
}

intptr_t BaseMarshaller::NumDefinitions() const {
  intptr_t total = 0;
  for (intptr_t i = 0; i < num_args(); i++) {
    total += NumDefinitions(i);
  }
  return total;
}

intptr_t BaseMarshaller::NumDefinitions(intptr_t arg_index) const {
  if (ArgumentIndexIsReturn(arg_index)) {
    return NumReturnDefinitions();
  }

  const auto& loc = Location(arg_index);
  const auto& type = loc.payload_type();

  if (type.IsPrimitive()) {
    // All non-struct arguments are 1 definition in IL. Even 64 bit values
    // on 32 bit architectures.
    return 1;
  }

  ASSERT(type.IsCompound());
  if (loc.IsMultiple()) {
    // One IL definition for every nested location.
    const auto& multiple = loc.AsMultiple();
    return multiple.locations().length();
  }

  if (loc.IsPointerToMemory()) {
    // For FFI calls, pass in TypedDataBase (1 IL definition) in IL, and copy
    // contents to stack and pass pointer in right location in MC.
    // For FFI callbacks, get the pointer in a NativeParameter and construct
    // the TypedDataBase in IL.
    return 1;
  }

  ASSERT(loc.IsStack());
  // For stack, word size definitions in IL. In FFI calls passed into the
  // native call, in FFI callbacks read in separate NativeParams.
  const intptr_t size_in_bytes = type.SizeInBytes();
  const intptr_t num_defs =
      Utils::RoundUp(size_in_bytes, compiler::target::kWordSize) /
      compiler::target::kWordSize;
  return num_defs;
}

intptr_t BaseMarshaller::NumReturnDefinitions() const {
  // For FFI calls we always have 1 definition, because the IL instruction can
  // only be 1 definition. We pass in a TypedDataBase in IL and fill it in
  // machine code.
  //
  // For FFI callbacks we always have 1 definition. If it's a struct and the
  // native ABI is passing a pointer, we copy to it in IL. If it's a multiple
  // locations return value we copy the value in machine code because some
  // native locations cannot be expressed in IL in Location.
  return 1;
}

bool BaseMarshaller::ArgumentIndexIsReturn(intptr_t arg_index) const {
  ASSERT(arg_index == kResultIndex || arg_index >= 0);
  return arg_index == kResultIndex;
}

// Definitions in return value count down.
bool BaseMarshaller::DefinitionIndexIsReturn(intptr_t def_index_global) const {
  return def_index_global <= kResultIndex;
}

intptr_t BaseMarshaller::ArgumentIndex(intptr_t def_index_global) const {
  if (DefinitionIndexIsReturn(def_index_global)) {
    const intptr_t def = DefinitionInArgument(def_index_global, kResultIndex);
    ASSERT(def < NumReturnDefinitions());
    return kResultIndex;
  }
  ASSERT(def_index_global < NumDefinitions());
  intptr_t defs = 0;
  intptr_t arg_index = 0;
  for (; arg_index < num_args(); arg_index++) {
    defs += NumDefinitions(arg_index);
    if (defs > def_index_global) {
      return arg_index;
    }
  }
  UNREACHABLE();
}

intptr_t BaseMarshaller::FirstDefinitionIndex(intptr_t arg_index) const {
  if (arg_index <= kResultIndex) {
    return kResultIndex;
  }
  ASSERT(arg_index < num_args());
  intptr_t num_defs = 0;
  for (intptr_t i = 0; i < arg_index; i++) {
    num_defs += NumDefinitions(i);
  }
  return num_defs;
}

intptr_t BaseMarshaller::DefinitionInArgument(intptr_t def_index_global,
                                              intptr_t arg_index) const {
  if (ArgumentIndexIsReturn(arg_index)) {
    // Counting down for return definitions.
    const intptr_t def = kResultIndex - def_index_global;
    ASSERT(def < NumReturnDefinitions());
    return def;
  } else {
    // Counting up for arguments in consecutive order.
    const intptr_t def = def_index_global - FirstDefinitionIndex(arg_index);
    ASSERT(def < NumDefinitions());
    return def;
  }
}

intptr_t BaseMarshaller::DefinitionIndex(intptr_t def_index_in_arg,
                                         intptr_t arg_index) const {
  ASSERT(def_index_in_arg < NumDefinitions(arg_index));
  if (ArgumentIndexIsReturn(arg_index)) {
    return kResultIndex - def_index_in_arg;
  } else {
    return FirstDefinitionIndex(arg_index) + def_index_in_arg;
  }
}

static Representation SelectRepresentationInIL(Zone* zone,
                                               const NativeLocation& location) {
  if (location.container_type().IsInt() && location.payload_type().IsFloat()) {
    // IL can only pass integers to integer Locations, so pass as integer if
    // the Location requires it to be an integer.
    return location.container_type().AsRepresentationOverApprox(zone);
  }
  // Representations do not support 8 or 16 bit ints, over approximate to 32
  // bits.
  return location.payload_type().AsRepresentationOverApprox(zone);
}

// Implemented partially in BaseMarshaller because most Representations are
// the same in Calls and Callbacks.
Representation BaseMarshaller::RepInFfiCall(intptr_t def_index_global) const {
  intptr_t arg_index = ArgumentIndex(def_index_global);
  const auto& location = Location(arg_index);

  if (location.container_type().IsPrimitive()) {
    return SelectRepresentationInIL(zone_, location);
  }
  ASSERT(location.container_type().IsCompound());

  if (location.IsStack()) {
    // Split the struct in architecture size chunks.
    return compiler::target::kWordSize == 8 ? Representation::kUnboxedInt64
                                            : Representation::kUnboxedInt32;
  }

  if (location.IsMultiple()) {
    const intptr_t def_index_in_arg =
        DefinitionInArgument(def_index_global, arg_index);
    const auto& def_loc =
        *(location.AsMultiple().locations()[def_index_in_arg]);
    return SelectRepresentationInIL(zone_, def_loc);
  }

  ASSERT(location.IsPointerToMemory());
  UNREACHABLE();  // Implemented in subclasses.
}

Representation CallMarshaller::RepInFfiCall(intptr_t def_index_global) const {
  intptr_t arg_index = ArgumentIndex(def_index_global);
  const auto& location = Location(arg_index);
  if (location.IsPointerToMemory()) {
    if (ArgumentIndexIsReturn(arg_index)) {
      // The IL type is the unboxed pointer.
      const auto& pointer_location = location.AsPointerToMemory();
      const auto& rep = pointer_location.pointer_location().payload_type();
      ASSERT(rep.Equals(
          pointer_location.pointer_return_location().payload_type()));
      return rep.AsRepresentation();
    } else {
      // We're passing Pointer/TypedData object, the GC might move TypedData so
      // we can't load the address from it eagerly.
      return kTagged;
    }
  }
  return BaseMarshaller::RepInFfiCall(def_index_global);
}

Representation CallbackMarshaller::RepInFfiCall(
    intptr_t def_index_global) const {
  intptr_t arg_index = ArgumentIndex(def_index_global);
  const auto& location = Location(arg_index);
  if (location.IsPointerToMemory()) {
    // The IL type is the unboxed pointer, and FFI callback return. In the
    // latter we've already copied the data into the result location in IL.
    const auto& pointer_location = location.AsPointerToMemory();
    const auto& rep = pointer_location.pointer_location().payload_type();
    ASSERT(
        rep.Equals(pointer_location.pointer_return_location().payload_type()));
    return rep.AsRepresentation();
  }
  if (ArgumentIndexIsReturn(arg_index) && location.IsMultiple()) {
    // We're passing a TypedData.
    return Representation::kTagged;
  }
  return BaseMarshaller::RepInFfiCall(def_index_global);
}

void BaseMarshaller::RepsInFfiCall(intptr_t arg_index,
                                   GrowableArray<Representation>* out) const {
  const intptr_t num_definitions = NumDefinitions(arg_index);
  const intptr_t first_def = FirstDefinitionIndex(arg_index);
  for (int i = 0; i < num_definitions; i++) {
    out->Add(RepInFfiCall(first_def + i));
  }
}

// Helper method for `LocInFfiCall` to turn a stack location into either any
// location or a pair of two any locations.
static Location ConvertToAnyLocation(const NativeStackLocation& loc,
                                     Representation rep_in_ffi_call) {
  // Floating point values are never split: they are either in a single "FPU"
  // register or a contiguous 64-bit slot on the stack. Unboxed 64-bit integer
  // values, in contrast, can be split between any two registers on a 32-bit
  // system.
  //
  // There is an exception for iOS and Android 32-bit ARM, where
  // floating-point values are treated as integers as far as the calling
  // convention is concerned. However, the representation of these arguments
  // are set to kUnboxedInt32 or kUnboxedInt64 already, so we don't have to
  // account for that here.
  const bool is_atomic =
      rep_in_ffi_call == kUnboxedDouble || rep_in_ffi_call == kUnboxedFloat;

  if (loc.payload_type().IsPrimitive() &&
      loc.payload_type().SizeInBytes() == 2 * compiler::target::kWordSize &&
      !is_atomic) {
    return Location::Pair(Location::Any(), Location::Any());
  }
  return Location::Any();
}

static Location SelectFpuLocationInIL(Zone* zone,
                                      const NativeLocation& location) {
  ASSERT((location.IsFpuRegisters()));
#if defined(TARGET_ARCH_ARM)
  // Only pin FPU register if it is the lowest bits.
  const auto& fpu_loc = location.AsFpuRegisters();
  if (fpu_loc.IsLowestBits()) {
    return fpu_loc.WidenToQFpuRegister(zone).AsLocation();
  }
  return Location::Any();
#endif  // defined(TARGET_ARCH_ARM)

  return location.AsLocation();
}

Location CallMarshaller::LocInFfiCall(intptr_t def_index_global) const {
  const intptr_t arg_index = ArgumentIndex(def_index_global);
  const NativeLocation& loc = this->Location(arg_index);

  if (ArgumentIndexIsReturn(arg_index)) {
    const intptr_t def = kResultIndex - def_index_global;
    if (loc.IsMultiple()) {
      ASSERT(loc.AsMultiple().locations()[def]->IsExpressibleAsLocation());
      return loc.AsMultiple().locations()[def]->AsLocation();
    }

    if (loc.IsPointerToMemory()) {
      // No location at all, because we store into TypedData passed to the
      // FfiCall instruction. But we have to supply a location.
      return Location::RegisterLocation(CallingConventions::kReturnReg);
    }

    return loc.AsLocation();
  }

  // Force all handles to be Stack locations.
  // Since non-leaf calls block all registers, Any locations effectively mean
  // Stack.
  // TODO(dartbug.com/38985): Once we start inlining FFI trampolines, the inputs
  // can be constants as well.
  if (IsHandle(arg_index)) {
    return Location::Any();
  }

  if (loc.IsMultiple()) {
    const intptr_t def_index_in_arg =
        def_index_global - FirstDefinitionIndex(arg_index);
    const auto& def_loc = *(loc.AsMultiple().locations()[def_index_in_arg]);
    if (def_loc.IsStack()) {
      // Don't pin stack locations, they need to be moved anyway.
      return ConvertToAnyLocation(def_loc.AsStack(),
                                  RepInFfiCall(def_index_global));
    }

    if (def_loc.IsFpuRegisters()) {
      return SelectFpuLocationInIL(zone_, def_loc);
    }

    return def_loc.AsLocation();
  }

  if (loc.IsPointerToMemory()) {
    const auto& pointer_location = loc.AsPointerToMemory().pointer_location();
    if (pointer_location.IsStack()) {
      // Don't pin stack locations, they need to be moved anyway.
      return ConvertToAnyLocation(pointer_location.AsStack(),
                                  RepInFfiCall(def_index_global));
    }
    return pointer_location.AsLocation();
  }

  if (loc.IsStack()) {
    return ConvertToAnyLocation(loc.AsStack(), RepInFfiCall(def_index_global));
  }

  if (loc.IsFpuRegisters()) {
    return SelectFpuLocationInIL(zone_, loc);
  }

  if (loc.IsBoth()) {
    const auto& fpu_reg_loc = loc.AsBoth().location(0).AsFpuRegisters();
    return SelectFpuLocationInIL(zone_, fpu_reg_loc);
  }

  ASSERT(loc.IsRegisters());
  return loc.AsLocation();
}

bool CallMarshaller::PassTypedData() const {
  return IsCompound(compiler::ffi::kResultIndex);
}

intptr_t CallMarshaller::TypedDataSizeInBytes() const {
  ASSERT(PassTypedData());
  return Utils::RoundUp(
      Location(compiler::ffi::kResultIndex).payload_type().SizeInBytes(),
      compiler::target::kWordSize);
}

// Const to be able to look up the `RequiredStackSpaceInBytes` in
// `PassByPointerStackOffset`.
const intptr_t kAfterLastArgumentIndex = kIntptrMax;

intptr_t CallMarshaller::PassByPointerStackOffset(intptr_t arg_index) const {
  ASSERT(arg_index == kResultIndex ||
         (arg_index >= 0 && arg_index < num_args()) ||
         arg_index == kAfterLastArgumentIndex);

  intptr_t stack_offset = 0;

  // First the native arguments are on the stack.
  // This is governed by the native ABI, the rest we can chose freely.
  stack_offset += native_calling_convention_.StackTopInBytes();
#if (defined(DART_TARGET_OS_MACOS_IOS) || defined(DART_TARGET_OS_MACOS)) &&    \
    defined(TARGET_ARCH_ARM64)
  // Add extra padding for possibly non stack-aligned word-size writes.
  // TODO(https://dartbug.com/48806): Re-engineer the moves to not over-
  // approximate struct sizes on stack.
  stack_offset += 4;
#endif
  stack_offset = Utils::RoundUp(stack_offset, compiler::target::kWordSize);
  if (arg_index == kResultIndex) {
    return stack_offset;
  }

  // Then save space for the result.
  const auto& result_location = Location(compiler::ffi::kResultIndex);
  if (result_location.IsPointerToMemory()) {
    stack_offset += result_location.payload_type().SizeInBytes();
    stack_offset = Utils::RoundUp(stack_offset, compiler::target::kWordSize);
  }

  // And finally put the arguments on the stack that are passed by pointer.
  for (int i = 0; i < num_args(); i++) {
    if (arg_index == i) {
      return stack_offset;
    }
    const auto& arg_location = Location(i);
    if (arg_location.IsPointerToMemory()) {
      stack_offset += arg_location.payload_type().SizeInBytes();
      stack_offset = Utils::RoundUp(stack_offset, compiler::target::kWordSize);
    }
  }

  // The total stack space we need.
  ASSERT(arg_index == kAfterLastArgumentIndex);
  return stack_offset;
}

intptr_t CallMarshaller::RequiredStackSpaceInBytes() const {
  return PassByPointerStackOffset(kAfterLastArgumentIndex);
}

// This classes translates the ABI location of arguments into the locations they
// will inhabit after entry-frame setup in the invocation of a native callback.
//
// Native -> Dart callbacks must push all the arguments before executing any
// Dart code because the reading the Thread from TLS requires calling a native
// stub, and the argument registers are volatile on all ABIs we support.
//
// To avoid complicating initial definitions, all callback arguments are read
// off the stack from their pushed locations, so this class updates the argument
// positions to account for this.
//
// See 'NativeEntryInstr::EmitNativeCode' for details.
class CallbackArgumentTranslator : public ValueObject {
 public:
  static NativeLocations& TranslateArgumentLocations(
      Zone* zone,
      const NativeLocations& argument_locations,
      const NativeLocation& return_loc) {
    const bool treat_return_loc = return_loc.IsPointerToMemory();

    auto& pushed_locs = *(new (zone) NativeLocations(
        argument_locations.length() + (treat_return_loc ? 1 : 0)));

    CallbackArgumentTranslator translator;
    for (intptr_t i = 0, n = argument_locations.length(); i < n; i++) {
      translator.AllocateArgument(*argument_locations[i]);
    }
    if (treat_return_loc) {
      translator.AllocateArgument(return_loc);
    }
    for (intptr_t i = 0, n = argument_locations.length(); i < n; ++i) {
      pushed_locs.Add(
          &translator.TranslateArgument(zone, *argument_locations[i]));
    }
    if (treat_return_loc) {
      pushed_locs.Add(&translator.TranslateArgument(zone, return_loc));
    }

    return pushed_locs;
  }

 private:
  void AllocateArgument(const NativeLocation& arg) {
    if (arg.IsStack()) return;

    if (arg.IsRegisters()) {
      argument_slots_required_ += arg.AsRegisters().num_regs();
    } else if (arg.IsFpuRegisters()) {
      argument_slots_required_ += 8 / target::kWordSize;
    } else if (arg.IsPointerToMemory()) {
      if (arg.AsPointerToMemory().pointer_location().IsRegisters()) {
        argument_slots_required_ += 1;
      }
    } else if (arg.IsMultiple()) {
      const auto& multiple = arg.AsMultiple();
      for (intptr_t i = 0; i < multiple.locations().length(); i++) {
        AllocateArgument(*multiple.locations().At(i));
      }
    } else {
      ASSERT(arg.IsBoth());
      const auto& both = arg.AsBoth();
      AllocateArgument(both.location(0));
    }
  }

  const NativeLocation& TranslateArgument(Zone* zone,
                                          const NativeLocation& arg) {
    if (arg.IsStack()) {
      // Add extra slots after the saved arguments for the return address and
      // frame pointer of the dummy arguments frame, which will be between the
      // saved argument registers and stack arguments. Also add slots for the
      // shadow space if present (factored into
      // kCallbackSlotsBeforeSavedArguments).
      //
      // Finally, for NativeCallbackTrampolines, factor in the extra stack space
      // corresponding to those trampolines' frames (above the entry frame).
      const intptr_t stack_delta =
          kCallbackSlotsBeforeSavedArguments +
          FfiCallbackMetadata::kNativeCallbackTrampolineStackDelta;
      FrameRebase rebase(
          zone,
          /*old_base=*/SPREG, /*new_base=*/SPREG,
          /*stack_delta=*/(argument_slots_required_ + stack_delta) *
              compiler::target::kWordSize);
      return rebase.Rebase(arg);
    }

    if (arg.IsRegisters()) {
      const auto& result = *new (zone) NativeStackLocation(
          arg.payload_type(), arg.container_type(), SPREG,
          argument_slots_used_ * compiler::target::kWordSize);
      argument_slots_used_ += arg.AsRegisters().num_regs();
      return result;
    }

    if (arg.IsFpuRegisters()) {
      const auto& result = *new (zone) NativeStackLocation(
          arg.payload_type(), arg.container_type(), SPREG,
          argument_slots_used_ * compiler::target::kWordSize);
      argument_slots_used_ += 8 / target::kWordSize;
      return result;
    }

    if (arg.IsPointerToMemory()) {
      const auto& pointer_loc = arg.AsPointerToMemory().pointer_location();
      const auto& pointer_ret_loc =
          arg.AsPointerToMemory().pointer_return_location();
      const auto& pointer_translated = TranslateArgument(zone, pointer_loc);
      return *new (zone) PointerToMemoryLocation(
          pointer_translated, pointer_ret_loc, arg.payload_type().AsCompound());
    }

    if (arg.IsMultiple()) {
      const auto& multiple = arg.AsMultiple();
      NativeLocations& multiple_locations =
          *new (zone) NativeLocations(multiple.locations().length());
      for (intptr_t i = 0; i < multiple.locations().length(); i++) {
        multiple_locations.Add(
            &TranslateArgument(zone, *multiple.locations().At(i)));
      }
      return *new (zone) MultipleNativeLocations(
          multiple.payload_type().AsCompound(), multiple_locations);
    }

    ASSERT(arg.IsBoth());
    const auto& both = arg.AsBoth();
    // We only need one.
    return TranslateArgument(zone, both.location(0));
  }

  intptr_t argument_slots_used_ = 0;
  intptr_t argument_slots_required_ = 0;
};

CallbackMarshaller* CallbackMarshaller::FromFunction(Zone* zone,
                                                     const Function& function,
                                                     const char** error) {
  DEBUG_ASSERT(function.IsNotTemporaryScopedHandle());
  const auto& c_signature =
      FunctionType::ZoneHandle(zone, function.FfiCSignature());
  const auto native_function_signature =
      NativeFunctionTypeFromFunctionType(zone, c_signature, error);
  if (*error != nullptr) {
    return nullptr;
  }
  const auto& native_calling_convention =
      NativeCallingConvention::FromSignature(zone, *native_function_signature);
  const auto& callback_locs =
      CallbackArgumentTranslator::TranslateArgumentLocations(
          zone, native_calling_convention.argument_locations(),
          native_calling_convention.return_location());
  return new (zone) CallbackMarshaller(
      zone, function, c_signature, native_calling_convention, callback_locs);
}

const NativeLocation& CallbackMarshaller::NativeLocationOfNativeParameter(
    intptr_t def_index) const {
  const intptr_t arg_index = ArgumentIndex(def_index);
  if (arg_index == kResultIndex) {
    const auto& result_loc = Location(arg_index);
    if (result_loc.IsPointerToMemory()) {
      // If it's a pointer we return it in the last.
      return *callback_locs_.At(callback_locs_.length() - 1);
    }
    // The other return types are not translated.
    return result_loc;
  }

  // Check that we only have stack arguments.
  const auto& loc = *callback_locs_.At(arg_index);
  ASSERT(loc.IsStack() || loc.IsPointerToMemory() || loc.IsMultiple());
  if (loc.IsStack()) {
    ASSERT(loc.AsStack().base_register() == SPREG);
    if (loc.payload_type().IsPrimitive()) {
      return loc;
    }
    const intptr_t index = DefinitionInArgument(def_index, arg_index);
    const intptr_t count = NumDefinitions(arg_index);
    return loc.Split(zone_, count, index);
  } else if (loc.IsPointerToMemory()) {
    const auto& pointer_loc = loc.AsPointerToMemory().pointer_location();
    ASSERT(pointer_loc.IsStack() &&
           pointer_loc.AsStack().base_register() == SPREG);
    return loc;
  }
  const auto& multiple = loc.AsMultiple();
  const intptr_t index = DefinitionInArgument(def_index, arg_index);
  const auto& multi_loc = *multiple.locations().At(index);
  ASSERT(multi_loc.IsStack() && multi_loc.AsStack().base_register() == SPREG);
  return multi_loc;
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
