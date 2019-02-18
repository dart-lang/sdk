// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(dacoharkes): Move this into compiler namespace.

#include "vm/class_id.h"
#include "vm/globals.h"

#include "vm/stub_code.h"

#if defined(TARGET_ARCH_X64) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/constants_x64.h"
#include "vm/dart_entry.h"
#include "vm/heap/heap.h"
#include "vm/heap/scavenger.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"
#include "vm/tags.h"
#include "vm/type_testing_stubs.h"

#define __ assembler->

namespace dart {

static Representation TypeRepresentation(const AbstractType& result_type) {
  switch (result_type.type_class_id()) {
    case kFfiFloatCid:
    case kFfiDoubleCid:
      return kUnboxedDouble;
    case kFfiInt8Cid:
    case kFfiInt16Cid:
    case kFfiInt32Cid:
    case kFfiInt64Cid:
    case kFfiUint8Cid:
    case kFfiUint16Cid:
    case kFfiUint32Cid:
    case kFfiUint64Cid:
    case kFfiIntPtrCid:
    case kFfiPointerCid:
    default:  // Subtypes of Pointer.
      return kUnboxedInt64;
  }
}

// Converts a Ffi [signature] to a list of Representations.
// Note that this ignores first argument (receiver) which is dynamic.
static ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature) {
  intptr_t num_arguments = signature.num_fixed_parameters() - 1;
  auto result = new ZoneGrowableArray<Representation>(num_arguments);
  for (intptr_t i = 0; i < num_arguments; i++) {
    AbstractType& arg_type =
        AbstractType::Handle(signature.ParameterTypeAt(i + 1));
    result->Add(TypeRepresentation(arg_type));
  }
  return result;
}

// Takes a list of argument representations, and converts it to a list of
// argument locations based on calling convention.
static ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_representations) {
  intptr_t num_arguments = arg_representations.length();
  auto result = new ZoneGrowableArray<Location>(num_arguments);
  result->FillWith(Location(), 0, num_arguments);
  Location* data = result->data();

  // Loop through all arguments and assign a register or a stack location.
  intptr_t int_regs_used = 0;
  intptr_t xmm_regs_used = 0;
  intptr_t nth_stack_argument = 0;
  bool on_stack;
  for (intptr_t i = 0; i < num_arguments; i++) {
    on_stack = true;
    switch (arg_representations.At(i)) {
      case kUnboxedInt64:
        if (int_regs_used < CallingConventions::kNumArgRegs) {
          data[i] = Location::RegisterLocation(
              CallingConventions::ArgumentRegisters[int_regs_used]);
          int_regs_used++;
          if (CallingConventions::kArgumentIntRegXorXmmReg) {
            xmm_regs_used++;
          }
          on_stack = false;
        }
        break;
      case kUnboxedDouble:
        if (xmm_regs_used < CallingConventions::kNumXmmArgRegs) {
          data[i] = Location::FpuRegisterLocation(
              CallingConventions::XmmArgumentRegisters[xmm_regs_used]);
          xmm_regs_used++;
          if (CallingConventions::kArgumentIntRegXorXmmReg) {
            int_regs_used++;
          }
          on_stack = false;
        }
        break;
      default:
        UNREACHABLE();
    }
    if (on_stack) {
      data[i] = Location::StackSlot(nth_stack_argument, RSP);
      nth_stack_argument++;
    }
  }
  return result;
}

static intptr_t NumStackArguments(
    const ZoneGrowableArray<Location>& locations) {
  intptr_t num_arguments = locations.length();
  intptr_t num_stack_arguments = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    if (locations.At(i).IsStackSlot()) {
      num_stack_arguments++;
    }
  }
  return num_stack_arguments;
}

// Input parameters:
//   Register reg : a Null, or something else
static void GenerateNotNullCheck(Assembler* assembler, Register reg) {
  Label not_null;
  Address throw_null_pointer_address =
      Address(THR, Thread::OffsetFromThread(&kArgumentNullErrorRuntimeEntry));

  __ CompareObject(reg, Object::null_object());
  __ j(NOT_EQUAL, &not_null, Assembler::kNearJump);

  // TODO(dacoharkes): Create the message here and use
  // kArgumentErrorRuntimeEntry to report which argument was null.
  __ movq(CODE_REG, Address(THR, Thread::call_to_runtime_stub_offset()));
  __ movq(RBX, throw_null_pointer_address);
  __ movq(R10, Immediate(0));
  __ call(Address(THR, Thread::call_to_runtime_entry_point_offset()));

  __ Bind(&not_null);
}

// Saves an int64 in the thread so GC does not trip.
//
// Input parameters:
//   Register src : a C int64
static void GenerateSaveInt64GCSafe(Assembler* assembler, Register src) {
  __ movq(Address(THR, Thread::unboxed_int64_runtime_arg_offset()), src);
}

// Loads an int64 from the thread.
static void GenerateLoadInt64GCSafe(Assembler* assembler, Register dst) {
  __ movq(dst, Address(THR, Thread::unboxed_int64_runtime_arg_offset()));
}

// Takes a Dart int and converts it to a C int64.
//
// Input parameters:
//   Register reg : a Dart Null, Smi, or Mint
// Output parameters:
//   Register reg : a C int64
// Invariant: keeps ArgumentRegisters and XmmArgumentRegisters intact
void GenerateMarshalInt64(Assembler* assembler, Register reg) {
  ASSERT(reg != TMP);
  ASSERT((1 << TMP & CallingConventions::kArgumentRegisters) == 0);
  Label done, not_smi;

  // Exception on Null
  GenerateNotNullCheck(assembler, reg);

  // Smi or Mint?
  __ movq(TMP, reg);
  __ testq(TMP, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);

  // Smi
  __ SmiUntag(reg);
  __ jmp(&done, Assembler::kNearJump);

  // Mint
  __ Bind(&not_smi);
  __ movq(reg, FieldAddress(reg, Mint::value_offset()));
  __ Bind(&done);
}

// Takes a C int64 and converts it to a Dart int.
//
// Input parameters:
//   RAX : a C int64
// Output paramaters:
//   RAX : a Dart Smi or Mint
static void GenerateUnmarshalInt64(Assembler* assembler) {
  const Class& mint_class =
      Class::ZoneHandle(Isolate::Current()->object_store()->mint_class());
  ASSERT(!mint_class.IsNull());
  const auto& mint_allocation_stub =
      Code::ZoneHandle(StubCode::GetAllocationStubForClass(mint_class));
  ASSERT(!mint_allocation_stub.IsNull());
  Label done;

  // Try whether it fits in a Smi.
  __ movq(TMP, RAX);
  __ SmiTag(RAX);
  __ j(NO_OVERFLOW, &done, Assembler::kNearJump);

  // Mint
  // Backup result value (to avoid GC).
  GenerateSaveInt64GCSafe(assembler, TMP);

  // Allocate object (can call into runtime).
  __ Call(mint_allocation_stub);

  // Store result value.
  GenerateLoadInt64GCSafe(assembler, TMP);
  __ movq(FieldAddress(RAX, Mint::value_offset()), TMP);

  __ Bind(&done);
}

// Takes a Dart double and converts it into a C double.
//
// Input parameters:
//   Register reg : a Dart Null or Double
// Output parameters:
//   XmmRegister xmm_reg : a C double
// Invariant: keeps ArgumentRegisters and other XmmArgumentRegisters intact
static void GenerateMarshalDouble(Assembler* assembler,
                                  Register reg,
                                  XmmRegister xmm_reg) {
  ASSERT((1 << reg & CallingConventions::kArgumentRegisters) == 0);

  // Throw a Dart Exception on Null.
  GenerateNotNullCheck(assembler, reg);

  __ movq(reg, FieldAddress(reg, Double::value_offset()));
  __ movq(xmm_reg, reg);
}

// Takes a C double and converts it into a Dart double.
//
// Input parameters:
//   XMM0 : a C double
// Output parameters:
//   RAX : a Dart Double
static void GenerateUnmarshalDouble(Assembler* assembler) {
  const auto& double_class =
      Class::ZoneHandle(Isolate::Current()->object_store()->double_class());
  ASSERT(!double_class.IsNull());
  const auto& double_allocation_stub =
      Code::ZoneHandle(StubCode::GetAllocationStubForClass(double_class));
  ASSERT(!double_allocation_stub.IsNull());

  // Backup result value (to avoid GC).
  __ movq(RAX, XMM0);
  GenerateSaveInt64GCSafe(assembler, RAX);

  // Allocate object (can call into runtime).
  __ Call(double_allocation_stub);

  // Store the result value.
  GenerateLoadInt64GCSafe(assembler, TMP);
  __ movq(FieldAddress(RAX, Double::value_offset()), TMP);
}

// Takes a Dart double and converts into a C float.
//
// Input parameters:
//   Register reg : a Dart double
// Output parameters:
//   XmmRegister xxmReg : a C float
// Invariant: keeps ArgumentRegisters and other XmmArgumentRegisters intact
static void GenerateMarshalFloat(Assembler* assembler,
                                 Register reg,
                                 XmmRegister xmm_reg) {
  ASSERT((1 << reg & CallingConventions::kArgumentRegisters) == 0);

  GenerateMarshalDouble(assembler, reg, xmm_reg);

  __ cvtsd2ss(xmm_reg, xmm_reg);
}

// Takes a C float and converts it into a Dart double.
//
// Input parameters:
//   XMM0 : a C float
// Output paramaters:
//   RAX : a Dart Double
static void GenerateUnmarshalFloat(Assembler* assembler) {
  __ cvtss2sd(XMM0, XMM0);
  GenerateUnmarshalDouble(assembler);
}

// Takes a Dart ffi.Pointer and converts it into a C pointer.
//
// Input parameters:
//   Register reg : a Dart ffi.Pointer or Null
// Output parameters:
//   Register reg : a C pointer
static void GenerateMarshalPointer(Assembler* assembler, Register reg) {
  Label done, not_null;

  __ CompareObject(reg, Object::null_object());
  __ j(NOT_EQUAL, &not_null, Assembler::kNearJump);

  // If null, the address is 0.
  __ movq(reg, Immediate(0));
  __ jmp(&done);

  // If not null but a Pointer, load the address.
  __ Bind(&not_null);
  __ movq(reg, FieldAddress(reg, Pointer::address_offset()));
  __ Bind(&done);
}

// Takes a C pointer and converts it into a Dart ffi.Pointer or Null.
//
// Input parameters:
//   RAX : a C pointer
// Outpot paramaters:
//   RAX : a Dart ffi.Pointer or Null
static void GenerateUnmarshalPointer(Assembler* assembler,
                                     Address closure_dart,
                                     const Class& pointer_class) {
  Label done, not_null;
  ASSERT(!pointer_class.IsNull());
  const auto& pointer_allocation_stub =
      Code::ZoneHandle(StubCode::GetAllocationStubForClass(pointer_class));
  ASSERT(!pointer_allocation_stub.IsNull());

  // If the address is 0, return a Dart Null.
  __ cmpq(RAX, Immediate(0));
  __ j(NOT_EQUAL, &not_null, Assembler::kNearJump);
  __ LoadObject(RAX, Object::null_object());
  __ jmp(&done);

  // Backup result value (to avoid GC).
  __ Bind(&not_null);
  GenerateSaveInt64GCSafe(assembler, RAX);

  // Allocate object (can call into runtime).
  __ movq(TMP, closure_dart);
  __ movq(TMP, FieldAddress(TMP, Closure::function_offset()));
  __ movq(TMP, FieldAddress(TMP, Function::result_type_offset()));
  __ pushq(FieldAddress(TMP, Type::arguments_offset()));
  __ Call(pointer_allocation_stub);
  __ popq(TMP);  // Pop type arguments.

  // Store the result value.
  GenerateLoadInt64GCSafe(assembler, RDX);
  __ movq(FieldAddress(RAX, Pointer::address_offset()), RDX);
  __ Bind(&done);
}

static void GenerateMarshalArgument(Assembler* assembler,
                                    const AbstractType& arg_type,
                                    Register reg,
                                    XmmRegister xmm_reg) {
  switch (arg_type.type_class_id()) {
    case kFfiInt8Cid:
    case kFfiInt16Cid:
    case kFfiInt32Cid:
    case kFfiInt64Cid:
    case kFfiUint8Cid:
    case kFfiUint16Cid:
    case kFfiUint32Cid:
    case kFfiUint64Cid:
    case kFfiIntPtrCid:
      // TODO(dacoharkes): Truncate and sign extend 8 bit and 16 bit, and write
      // tests. https://github.com/dart-lang/sdk/issues/35787
      GenerateMarshalInt64(assembler, reg);
      return;
    case kFfiFloatCid:
      GenerateMarshalFloat(assembler, reg, xmm_reg);
      return;
    case kFfiDoubleCid:
      GenerateMarshalDouble(assembler, reg, xmm_reg);
      return;
    case kFfiPointerCid:
    default:  // Subtypes of Pointer.
      GenerateMarshalPointer(assembler, reg);
      return;
  }
}

static void GenerateUnmarshalResult(Assembler* assembler,
                                    const AbstractType& result_type,
                                    Address closure_dart) {
  switch (result_type.type_class_id()) {
    case kFfiVoidCid:
      __ LoadObject(RAX, Object::null_object());
      return;
    case kFfiInt8Cid:
    case kFfiInt16Cid:
    case kFfiInt32Cid:
    case kFfiInt64Cid:
    case kFfiUint8Cid:
    case kFfiUint16Cid:
    case kFfiUint32Cid:
    case kFfiUint64Cid:
    case kFfiIntPtrCid:
      GenerateUnmarshalInt64(assembler);
      return;
    case kFfiFloatCid:
      GenerateUnmarshalFloat(assembler);
      return;
    case kFfiDoubleCid:
      GenerateUnmarshalDouble(assembler);
      return;
    case kFfiPointerCid:
    default:  // subtypes of Pointer
      break;
  }
  Class& cls = Class::ZoneHandle(Thread::Current()->zone(),
                                 Type::Cast(result_type).type_class());

  GenerateUnmarshalPointer(assembler, closure_dart, cls);
}

// Generates a assembly for dart:ffi trampolines:
// - marshal arguments
// - put the arguments in registers and on the c stack
// - invoke the c function
// - (c result register is the same as dart, so keep in place)
// - unmarshal c result
// - return
//
// Input parameters:
//   RSP + kWordSize *  num_arguments      : closure.
//   RSP + kWordSize * (num_arguments - 1) : arg 1.
//   RSP + kWordSize * (num_arguments - 2) : arg 2.
//   RSP + kWordSize                       : arg n.
// After entering stub:
//   RBP = RSP (before stub) - kWordSize
//   RBP + kWordSize * (num_arguments + 1) : closure.
//   RBP + kWordSize *  num_arguments      : arg 1.
//   RBP + kWordSize * (num_arguments - 1) : arg 2.
//   RBP + kWordSize *  2                  : arg n.
//
// TODO(dacoharkes): Test truncation on non 64 bits ints and floats.
void GenerateFfiTrampoline(Assembler* assembler, const Function& signature) {
  ZoneGrowableArray<Representation>* arg_representations =
      ArgumentRepresentations(signature);
  ZoneGrowableArray<Location>* arg_locations =
      ArgumentLocations(*arg_representations);

  intptr_t num_dart_arguments = signature.num_fixed_parameters();
  intptr_t num_arguments = num_dart_arguments - 1;  // ignore closure

  __ EnterStubFrame();

  // Save exit frame information to enable stack walking as we are about
  // to transition to Dart VM C++ code.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), RBP);

#if defined(DEBUG)
  {
    Label ok;
    // Check that we are always entering from Dart code.
    __ movq(TMP, Immediate(VMTag::kDartCompiledTagId));
    __ cmpq(TMP, Assembler::VMTagAddress());
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Not coming from Dart code.");
    __ Bind(&ok);
  }
#endif

  // Reserve space for arguments and align frame before entering C++ world.
  __ subq(RSP, Immediate(NumStackArguments(*arg_locations) * kWordSize));
  if (OS::ActivationFrameAlignment() > 1) {
    __ andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }

  // Prepare address for calling the C function.
  Address closure_dart = Address(RBP, (num_dart_arguments + 1) * kWordSize);
  __ movq(RBX, closure_dart);
  __ movq(RBX, FieldAddress(RBX, Closure::context_offset()));
  __ movq(RBX, FieldAddress(RBX, Context::variable_offset(0)));
  GenerateMarshalInt64(assembler, RBX);  // Address is a Smi or Mint.

  // Marshal arguments and store in the right register.
  for (intptr_t i = 0; i < num_arguments; i++) {
    Representation rep = arg_representations->At(i);
    Location loc = arg_locations->At(i);

    // We do marshalling in the the target register or in RAX.
    Register reg = loc.IsRegister() ? loc.reg() : RAX;
    // For doubles and floats we use target xmm register or first non param reg.
    FpuRegister xmm_reg = loc.IsFpuRegister()
                              ? loc.fpu_reg()
                              : CallingConventions::xmmFirstNonParameterReg;

    // Load parameter from Dart stack.
    __ movq(reg, Address(RBP, (num_arguments + 1 - i) * kWordSize));

    // Marshal argument.
    AbstractType& arg_type =
        AbstractType::Handle(signature.ParameterTypeAt(i + 1));
    GenerateMarshalArgument(assembler, arg_type, reg, xmm_reg);

    // Store marshalled argument where c expects value.
    if (loc.IsStackSlot()) {
      if (rep == kUnboxedDouble) {
        __ movq(reg, xmm_reg);
      }
      __ movq(loc.ToStackSlotAddress(), reg);
    }
  }

  // Mark that the thread is executing VM code.
  __ movq(Assembler::VMTagAddress(), RBX);

  __ CallCFunction(RBX);

  // Mark that the thread is executing Dart code.
  __ movq(Assembler::VMTagAddress(), Immediate(VMTag::kDartCompiledTagId));

  // Unmarshal result.
  AbstractType& return_type = AbstractType::Handle(signature.result_type());
  GenerateUnmarshalResult(assembler, return_type, closure_dart);

  // Reset exit frame information in Isolate structure.
  __ movq(Address(THR, Thread::top_exit_frame_info_offset()), Immediate(0));

  __ LeaveStubFrame();

  __ ret();
}

void GenerateFfiInverseTrampoline(Assembler* assembler,
                                  const Function& signature,
                                  void* dart_entry_point) {
  ZoneGrowableArray<Representation>* arg_representations =
      ArgumentRepresentations(signature);
  ZoneGrowableArray<Location>* arg_locations =
      ArgumentLocations(*arg_representations);

  intptr_t num_dart_arguments = signature.num_fixed_parameters();
  intptr_t num_arguments = num_dart_arguments - 1;  // Ignore closure.

  // TODO(dacoharkes): Implement this.
  // https://github.com/dart-lang/sdk/issues/35761
  // Look at StubCode::GenerateInvokeDartCodeStub.

  __ int3();

  for (intptr_t i = 0; i < num_arguments; i++) {
    Register reg = arg_locations->At(i).reg();
    __ SmiTag(reg);
  }

  __ movq(RBX, Immediate(reinterpret_cast<intptr_t>(dart_entry_point)));

  __ int3();

  __ call(RBX);

  __ int3();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64) && !defined(DART_PRECOMPILED_RUNTIME)
