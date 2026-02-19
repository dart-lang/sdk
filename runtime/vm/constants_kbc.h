// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_KBC_H_
#define RUNTIME_VM_CONSTANTS_KBC_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {

// clang-format off
// Bytecode instructions are specified using the following format:
//
//     V(BytecodeName, OperandForm, BytecodeKind, Op1, Op2, Op3)
//
// - OperandForm specifies operand encoding and should be one of 0, A, D, X, T,
//   A_E, A_Y, D_F or A_B_C.
//
// - BytecodeKind is one of WIDE, RESV (reserved), ORDN (ordinary)
//
// - Op1, Op2, Op3 specify operand meaning. Possible values:
//
//     ___ ignored / non-existent operand
//     num immediate operand
//     lit constant literal from object pool
//     reg register (unsigned FP relative local)
//     xeg x-register (signed FP relative local)
//     tgt jump target relative to the PC of the current instruction
//
// TODO(vegorov) jump targets should be encoded relative to PC of the next
//               instruction because PC is incremented immediately after fetch
//               and before decoding.
//
#define PUBLIC_KERNEL_BYTECODES_LIST(V)                                        \
  V(Trap,                                  0, ORDN, ___, ___, ___)             \
  V(Unused00,                              0, RESV, ___, ___, ___)             \
  V(Entry,                                 D, ORDN, num, ___, ___)             \
  V(Entry_Wide,                            D, WIDE, num, ___, ___)             \
  V(EntryOptional,                     A_B_C, ORDN, num, num, num)             \
  V(EntrySuspendable,                  A_B_C, ORDN, num, num, num)             \
  V(LoadConstant,                        A_E, ORDN, reg, lit, ___)             \
  V(LoadConstant_Wide,                   A_E, WIDE, reg, lit, ___)             \
  V(Frame,                                 D, ORDN, num, ___, ___)             \
  V(Frame_Wide,                            D, WIDE, num, ___, ___)             \
  V(CheckFunctionTypeArgs,               A_E, ORDN, num, reg, ___)             \
  V(CheckFunctionTypeArgs_Wide,          A_E, WIDE, num, reg, ___)             \
  V(CheckStack,                            A, ORDN, num, ___, ___)             \
  V(Nop,                                   0, ORDN, ___, ___, ___)             \
  V(JumpIfUnchecked,                       T, ORDN, tgt, ___, ___)             \
  V(JumpIfUnchecked_Wide,                  T, WIDE, tgt, ___, ___)             \
  V(Allocate,                              D, ORDN, lit, ___, ___)             \
  V(Allocate_Wide,                         D, WIDE, lit, ___, ___)             \
  V(AllocateT,                             0, ORDN, ___, ___, ___)             \
  V(CreateArrayTOS,                        0, ORDN, ___, ___, ___)             \
  V(AllocateClosure,                       0, ORDN, ___, ___, ___)             \
  V(Unused03,                              0, RESV, ___, ___, ___)             \
  V(AllocateContext,                     A_E, ORDN, num, num, ___)             \
  V(AllocateContext_Wide,                A_E, WIDE, num, num, ___)             \
  V(CloneContext,                        A_E, ORDN, num, num, ___)             \
  V(CloneContext_Wide,                   A_E, WIDE, num, num, ___)             \
  V(LoadContextParent,                     0, ORDN, ___, ___, ___)             \
  V(StoreContextParent,                    0, ORDN, ___, ___, ___)             \
  V(LoadContextVar,                      A_E, ORDN, num, num, ___)             \
  V(LoadContextVar_Wide,                 A_E, WIDE, num, num, ___)             \
  V(Unused04,                              0, RESV, ___, ___, ___)             \
  V(Unused05,                              0, RESV, ___, ___, ___)             \
  V(StoreContextVar,                     A_E, ORDN, num, num, ___)             \
  V(StoreContextVar_Wide,                A_E, WIDE, num, num, ___)             \
  V(PushConstant,                          D, ORDN, lit, ___, ___)             \
  V(PushConstant_Wide,                     D, WIDE, lit, ___, ___)             \
  V(Unused06,                              0, RESV, ___, ___, ___)             \
  V(Unused07,                              0, RESV, ___, ___, ___)             \
  V(PushTrue,                              0, ORDN, ___, ___, ___)             \
  V(PushFalse,                             0, ORDN, ___, ___, ___)             \
  V(PushInt,                               X, ORDN, num, ___, ___)             \
  V(PushInt_Wide,                          X, WIDE, num, ___, ___)             \
  V(Unused08,                              0, RESV, ___, ___, ___)             \
  V(Unused09,                              0, RESV, ___, ___, ___)             \
  V(Unused10,                              0, RESV, ___, ___, ___)             \
  V(Unused11,                              0, RESV, ___, ___, ___)             \
  V(PushNull,                              0, ORDN, ___, ___, ___)             \
  V(Drop1,                                 0, ORDN, ___, ___, ___)             \
  V(Push,                                  X, ORDN, xeg, ___, ___)             \
  V(Push_Wide,                             X, WIDE, xeg, ___, ___)             \
  V(Unused12,                              0, RESV, ___, ___, ___)             \
  V(Unused13,                              0, RESV, ___, ___, ___)             \
  V(Unused14,                              0, RESV, ___, ___, ___)             \
  V(Unused15,                              0, RESV, ___, ___, ___)             \
  V(Unused16,                              0, RESV, ___, ___, ___)             \
  V(Unused17,                              0, RESV, ___, ___, ___)             \
  V(PopLocal,                              X, ORDN, xeg, ___, ___)             \
  V(PopLocal_Wide,                         X, WIDE, xeg, ___, ___)             \
  V(LoadStatic,                            D, ORDN, lit, ___, ___)             \
  V(LoadStatic_Wide,                       D, WIDE, lit, ___, ___)             \
  V(StoreLocal,                            X, ORDN, xeg, ___, ___)             \
  V(StoreLocal_Wide,                       X, WIDE, xeg, ___, ___)             \
  V(LoadFieldTOS,                          D, ORDN, lit, ___, ___)             \
  V(LoadFieldTOS_Wide,                     D, WIDE, lit, ___, ___)             \
  V(StoreFieldTOS,                         D, ORDN, lit, ___, ___)             \
  V(StoreFieldTOS_Wide,                    D, WIDE, lit, ___, ___)             \
  V(StoreIndexedTOS,                       0, ORDN, ___, ___, ___)             \
  V(Unused20,                              0, RESV, ___, ___, ___)             \
  V(JumpIfInitialized,                     T, ORDN, tgt, ___, ___)             \
  V(JumpIfInitialized_Wide,                T, WIDE, tgt, ___, ___)             \
  V(PushUninitializedSentinel,             0, ORDN, ___, ___, ___)             \
  V(Unused21,                              0, RESV, ___, ___, ___)             \
  V(InitLateField,                         D, ORDN, lit, ___, ___)             \
  V(InitLateField_Wide,                    D, WIDE, lit, ___, ___)             \
  V(StoreStaticTOS,                        D, ORDN, lit, ___, ___)             \
  V(StoreStaticTOS_Wide,                   D, WIDE, lit, ___, ___)             \
  V(Jump,                                  T, ORDN, tgt, ___, ___)             \
  V(Jump_Wide,                             T, WIDE, tgt, ___, ___)             \
  V(JumpIfNoAsserts,                       T, ORDN, tgt, ___, ___)             \
  V(JumpIfNoAsserts_Wide,                  T, WIDE, tgt, ___, ___)             \
  V(JumpIfNotZeroTypeArgs,                 T, ORDN, tgt, ___, ___)             \
  V(JumpIfNotZeroTypeArgs_Wide,            T, WIDE, tgt, ___, ___)             \
  V(JumpIfEqStrict,                        T, ORDN, tgt, ___, ___)             \
  V(JumpIfEqStrict_Wide,                   T, WIDE, tgt, ___, ___)             \
  V(JumpIfNeStrict,                        T, ORDN, tgt, ___, ___)             \
  V(JumpIfNeStrict_Wide,                   T, WIDE, tgt, ___, ___)             \
  V(JumpIfTrue,                            T, ORDN, tgt, ___, ___)             \
  V(JumpIfTrue_Wide,                       T, WIDE, tgt, ___, ___)             \
  V(JumpIfFalse,                           T, ORDN, tgt, ___, ___)             \
  V(JumpIfFalse_Wide,                      T, WIDE, tgt, ___, ___)             \
  V(JumpIfNull,                            T, ORDN, tgt, ___, ___)             \
  V(JumpIfNull_Wide,                       T, WIDE, tgt, ___, ___)             \
  V(JumpIfNotNull,                         T, ORDN, tgt, ___, ___)             \
  V(JumpIfNotNull_Wide,                    T, WIDE, tgt, ___, ___)             \
  V(Suspend,                               T, ORDN, tgt, ___, ___)             \
  V(Suspend_Wide,                          T, WIDE, tgt, ___, ___)             \
  V(DirectCall,                          D_F, ORDN, num, num, ___)             \
  V(DirectCall_Wide,                     D_F, WIDE, num, num, ___)             \
  V(UncheckedDirectCall,                 D_F, ORDN, num, num, ___)             \
  V(UncheckedDirectCall_Wide,            D_F, WIDE, num, num, ___)             \
  V(InterfaceCall,                       D_F, ORDN, num, num, ___)             \
  V(InterfaceCall_Wide,                  D_F, WIDE, num, num, ___)             \
  V(ExternalCall,                          D, ORDN, lit, ___, ___)             \
  V(ExternalCall_Wide,                     D, WIDE, lit, ___, ___)             \
  V(InstantiatedInterfaceCall,           D_F, ORDN, num, num, ___)             \
  V(InstantiatedInterfaceCall_Wide,      D_F, WIDE, num, num, ___)             \
  V(UncheckedClosureCall,                D_F, ORDN, num, num, ___)             \
  V(UncheckedClosureCall_Wide,           D_F, WIDE, num, num, ___)             \
  V(UncheckedInterfaceCall,              D_F, ORDN, num, num, ___)             \
  V(UncheckedInterfaceCall_Wide,         D_F, WIDE, num, num, ___)             \
  V(DynamicCall,                         D_F, ORDN, num, num, ___)             \
  V(DynamicCall_Wide,                    D_F, WIDE, num, num, ___)             \
  V(ReturnTOS,                             0, ORDN, ___, ___, ___)             \
  V(Unused25,                              0, RESV, ___, ___, ___)             \
  V(AssertAssignable,                    A_E, ORDN, num, lit, ___)             \
  V(AssertAssignable_Wide,               A_E, WIDE, num, lit, ___)             \
  V(AssertSubtype,                         0, ORDN, ___, ___, ___)             \
  V(Unused30,                              0, RESV, ___, ___, ___)             \
  V(LoadTypeArgumentsField,                D, ORDN, lit, ___, ___)             \
  V(LoadTypeArgumentsField_Wide,           D, WIDE, lit, ___, ___)             \
  V(InstantiateType,                       D, ORDN, lit, ___, ___)             \
  V(InstantiateType_Wide,                  D, WIDE, lit, ___, ___)             \
  V(InstantiateTypeArgumentsTOS,         A_E, ORDN, num, lit, ___)             \
  V(InstantiateTypeArgumentsTOS_Wide,    A_E, WIDE, num, lit, ___)             \
  V(Unused32,                              0, RESV, ___, ___, ___)             \
  V(Unused33,                              0, RESV, ___, ___, ___)             \
  V(Unused34,                              0, RESV, ___, ___, ___)             \
  V(Unused35,                              0, RESV, ___, ___, ___)             \
  V(Throw,                                 A, ORDN, num, ___, ___)             \
  V(SetFrame,                              A, ORDN, num, ___, num)             \
  V(MoveSpecial,                         A_Y, ORDN, num, xeg, ___)             \
  V(MoveSpecial_Wide,                    A_Y, WIDE, num, xeg, ___)             \
  V(BooleanNegateTOS,                      0, ORDN, ___, ___, ___)             \
  V(EqualsNull,                            0, ORDN, ___, ___, ___)             \
  V(NullCheck,                             D, ORDN, lit, ___, ___)             \
  V(NullCheck_Wide,                        D, WIDE, lit, ___, ___)             \
  V(NegateInt,                             0, ORDN, ___, ___, ___)             \
  V(AddInt,                                0, ORDN, ___, ___, ___)             \
  V(SubInt,                                0, ORDN, ___, ___, ___)             \
  V(MulInt,                                0, ORDN, ___, ___, ___)             \
  V(TruncDivInt,                           0, ORDN, ___, ___, ___)             \
  V(ModInt,                                0, ORDN, ___, ___, ___)             \
  V(BitAndInt,                             0, ORDN, ___, ___, ___)             \
  V(BitOrInt,                              0, ORDN, ___, ___, ___)             \
  V(BitXorInt,                             0, ORDN, ___, ___, ___)             \
  V(ShlInt,                                0, ORDN, ___, ___, ___)             \
  V(ShrInt,                                0, ORDN, ___, ___, ___)             \
  V(CompareIntEq,                          0, ORDN, ___, ___, ___)             \
  V(CompareIntGt,                          0, ORDN, ___, ___, ___)             \
  V(CompareIntLt,                          0, ORDN, ___, ___, ___)             \
  V(CompareIntGe,                          0, ORDN, ___, ___, ___)             \
  V(CompareIntLe,                          0, ORDN, ___, ___, ___)             \
  V(NegateDouble,                          0, ORDN, ___, ___, ___)             \
  V(AddDouble,                             0, ORDN, ___, ___, ___)             \
  V(SubDouble,                             0, ORDN, ___, ___, ___)             \
  V(MulDouble,                             0, ORDN, ___, ___, ___)             \
  V(DivDouble,                             0, ORDN, ___, ___, ___)             \
  V(CompareDoubleEq,                       0, ORDN, ___, ___, ___)             \
  V(CompareDoubleGt,                       0, ORDN, ___, ___, ___)             \
  V(CompareDoubleLt,                       0, ORDN, ___, ___, ___)             \
  V(CompareDoubleGe,                       0, ORDN, ___, ___, ___)             \
  V(CompareDoubleLe,                       0, ORDN, ___, ___, ___)             \
  V(AllocateRecord,                        D, ORDN, lit, ___, ___)             \
  V(AllocateRecord_Wide,                   D, WIDE, lit, ___, ___)             \
  V(LoadRecordField,                       D, ORDN, num, ___, ___)             \
  V(LoadRecordField_Wide,                  D, WIDE, num, ___, ___)             \
  V(FfiCall,                               D, ORDN, lit, ___, ___)             \
  V(FfiCall_Wide,                          D, WIDE, lit, ___, ___)             \

  // These bytecodes are only generated within the VM. Reassigning their
  // opcodes is not a breaking change.
#define INTERNAL_KERNEL_BYTECODES_WITH_CUSTOM_CODE(V) \
  /* ImplicitConstructorClosure and ImplicitInstanceClosure instructions  */   \
  /* use D_F encoding as they may call target constructor or method and   */   \
  /* should be compatible with other ***Call instructions                 */   \
  /* in order to support DecodeArgc when returning from a call.           */   \
  V(VMInternal_ImplicitConstructorClosure,      D_F, ORDN, num, num, ___)      \
  V(VMInternal_ImplicitConstructorClosure_Wide, D_F, ORDN, num, num, ___)      \
  V(VMInternal_ImplicitInstanceClosure,         D_F, ORDN, num, num, ___)      \
  V(VMInternal_ImplicitInstanceClosure_Wide,    D_F, ORDN, num, num, ___)      \

#define INTERNAL_KERNEL_BYTECODES_WITH_DEFAULT_CODE(V)                         \
  V(VMInternal_ImplicitGetter,                    0, ORDN, ___, ___, ___)      \
  V(VMInternal_ImplicitSetter,                    0, ORDN, ___, ___, ___)      \
  V(VMInternal_ImplicitStaticGetter,              0, ORDN, ___, ___, ___)      \
  V(VMInternal_ImplicitSharedStaticGetter,        0, ORDN, ___, ___, ___)      \
  V(VMInternal_ImplicitStaticSetter,              0, ORDN, ___, ___, ___)      \
  V(VMInternal_ImplicitSharedStaticSetter,        0, ORDN, ___, ___, ___)      \
  V(VMInternal_MethodExtractor,                   0, ORDN, ___, ___, ___)      \
  V(VMInternal_InvokeClosure,                     0, ORDN, ___, ___, ___)      \
  V(VMInternal_InvokeField,                       0, ORDN, ___, ___, ___)      \
  V(VMInternal_ForwardDynamicInvocation,          0, ORDN, ___, ___, ___)      \
  V(VMInternal_ImplicitStaticClosure,             0, ORDN, ___, ___, ___)      \
  V(VMInternal_NoSuchMethodDispatcher,            0, ORDN, ___, ___, ___)      \
  /* One breakpoint opcode for each instruction size. */                       \
  V(VMInternal_Breakpoint_0,                      0, ORDN, ___, ___, ___)      \
  V(VMInternal_Breakpoint_A_B_C,              A_B_C, ORDN, num, num, num)      \
  V(VMInternal_Breakpoint_D,                      D, ORDN, num, ___, ___)      \
  V(VMInternal_Breakpoint_D_Wide,                 D, WIDE, num, ___, ___)      \
  V(VMInternal_Breakpoint_A_E,                  A_E, ORDN, num, num, ___)      \
  V(VMInternal_Breakpoint_A_E_Wide,             A_E, WIDE, num, num, ___)      \

#define INTERNAL_KERNEL_BYTECODES_LIST(V)                                      \
  INTERNAL_KERNEL_BYTECODES_WITH_CUSTOM_CODE(V)                                \
  INTERNAL_KERNEL_BYTECODES_WITH_DEFAULT_CODE(V)

#define KERNEL_BYTECODES_LIST(V)                                               \
  PUBLIC_KERNEL_BYTECODES_LIST(V)                                              \
  INTERNAL_KERNEL_BYTECODES_LIST(V)

// clang-format on

typedef uint8_t KBCInstr;

class KernelBytecode {
 public:
  // Magic value of bytecode files.
  static const intptr_t kMagicValue = 0x44424333;  // 'DBC3'
  // Bytecode format version supported by the VM
  // (should match pkg/dart2bytecode/lib/dbc.dart).
  static const intptr_t kBytecodeFormatVersion = 1;

  enum Opcode {
#define DECLARE_BYTECODE(name, encoding, kind, op1, op2, op3) k##name,
    KERNEL_BYTECODES_LIST(DECLARE_BYTECODE)
#undef DECLARE_BYTECODE
        kNumOpcodes,
  };

  static const char* NameOf(Opcode op) {
    const char* names[] = {
#define NAME(name, encoding, kind, op1, op2, op3) #name,
        KERNEL_BYTECODES_LIST(NAME)
#undef NAME
    };
    return names[op];
  }

  static const intptr_t kInstructionSize[];

  enum SpecialIndex {
    kExceptionSpecialIndex,
    kStackTraceSpecialIndex,
    kSpecialIndexCount
  };

 private:
  static const intptr_t kWideModifier = 1;

  // Should be used only on instructions with wide variants.
  DART_FORCE_INLINE static bool IsWide(const KBCInstr* instr) {
    return IsWide(DecodeOpcode(instr));
  }

  // Should be used only on instructions with wide variants.
  DART_FORCE_INLINE static constexpr bool IsWide(Opcode opcode) {
    return ((opcode & kWideModifier) != 0);
  }

 public:
  DART_FORCE_INLINE static uint8_t DecodeA(const KBCInstr* bc) { return bc[1]; }

  DART_FORCE_INLINE static uint8_t DecodeB(const KBCInstr* bc) { return bc[2]; }

  DART_FORCE_INLINE static uint8_t DecodeC(const KBCInstr* bc) { return bc[3]; }

  DART_FORCE_INLINE static uint32_t DecodeD(const KBCInstr* bc) {
    if (IsWide(bc)) {
      return static_cast<uint32_t>(bc[1]) |
             (static_cast<uint32_t>(bc[2]) << 8) |
             (static_cast<uint32_t>(bc[3]) << 16) |
             (static_cast<uint32_t>(bc[4]) << 24);
    } else {
      return bc[1];
    }
  }

  DART_FORCE_INLINE static int32_t DecodeX(const KBCInstr* bc) {
    if (IsWide(bc)) {
      return static_cast<int32_t>(static_cast<uint32_t>(bc[1]) |
                                  (static_cast<uint32_t>(bc[2]) << 8) |
                                  (static_cast<uint32_t>(bc[3]) << 16) |
                                  (static_cast<uint32_t>(bc[4]) << 24));
    } else {
      return static_cast<int8_t>(bc[1]);
    }
  }

  DART_FORCE_INLINE static int32_t DecodeT(const KBCInstr* bc) {
    if (IsWide(bc)) {
      return static_cast<int32_t>((static_cast<uint32_t>(bc[1]) << 8) |
                                  (static_cast<uint32_t>(bc[2]) << 16) |
                                  (static_cast<uint32_t>(bc[3]) << 24)) >>
             8;
    } else {
      return static_cast<int8_t>(bc[1]);
    }
  }

  DART_FORCE_INLINE static uint32_t DecodeE(const KBCInstr* bc) {
    if (IsWide(bc)) {
      return static_cast<uint32_t>(bc[2]) |
             (static_cast<uint32_t>(bc[3]) << 8) |
             (static_cast<uint32_t>(bc[4]) << 16) |
             (static_cast<uint32_t>(bc[5]) << 24);
    } else {
      return bc[2];
    }
  }

  DART_FORCE_INLINE static int32_t DecodeY(const KBCInstr* bc) {
    if (IsWide(bc)) {
      return static_cast<int32_t>(static_cast<uint32_t>(bc[2]) |
                                  (static_cast<uint32_t>(bc[3]) << 8) |
                                  (static_cast<uint32_t>(bc[4]) << 16) |
                                  (static_cast<uint32_t>(bc[5]) << 24));
    } else {
      return static_cast<int8_t>(bc[2]);
    }
  }

  DART_FORCE_INLINE static uint8_t DecodeF(const KBCInstr* bc) {
    if (IsWide(bc)) {
      return bc[5];
    } else {
      return bc[2];
    }
  }

  DART_FORCE_INLINE static Opcode DecodeOpcode(const KBCInstr* bc) {
    return static_cast<Opcode>(bc[0]);
  }

  DART_FORCE_INLINE static const KBCInstr* Next(const KBCInstr* bc) {
    return bc + kInstructionSize[DecodeOpcode(bc)];
  }

  DART_FORCE_INLINE static uword Next(uword pc) {
    return pc + kInstructionSize[DecodeOpcode(
                    reinterpret_cast<const KBCInstr*>(pc))];
  }

  DART_FORCE_INLINE static bool IsLoadConstantOpcode(const KBCInstr* instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kLoadConstant:
      case KernelBytecode::kLoadConstant_Wide:
        return true;
      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsCheckStackOpcode(const KBCInstr* instr) {
    return DecodeOpcode(instr) == KernelBytecode::kCheckStack;
  }

  DART_FORCE_INLINE static bool IsCheckFunctionTypeArgs(const KBCInstr* instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kCheckFunctionTypeArgs:
      case KernelBytecode::kCheckFunctionTypeArgs_Wide:
        return true;
      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsEntryOpcode(const KBCInstr* instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kEntry:
      case KernelBytecode::kEntry_Wide:
        return true;
      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsEntryOptionalOpcode(const KBCInstr* instr) {
    return DecodeOpcode(instr) == KernelBytecode::kEntryOptional;
  }

  DART_FORCE_INLINE static bool IsFrameOpcode(const KBCInstr* instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kFrame:
      case KernelBytecode::kFrame_Wide:
        return true;
      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsSetFrameOpcode(const KBCInstr* instr) {
    return DecodeOpcode(instr) == KernelBytecode::kSetFrame;
  }

  DART_FORCE_INLINE static bool IsDirectCallOpcode(const KBCInstr* instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kDirectCall:
      case KernelBytecode::kDirectCall_Wide:
      case KernelBytecode::kUncheckedDirectCall:
      case KernelBytecode::kUncheckedDirectCall_Wide:
        return true;
      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsReturnOpcode(const KBCInstr* instr) {
    return DecodeOpcode(instr) == KernelBytecode::kReturnTOS;
  }

  DART_FORCE_INLINE static uint8_t DecodeArgc(const KBCInstr* ret_addr) {
    // All call instructions have DF encoding, with argc being the last byte
    // regardless of whether the wide variant is used or not.
    return ret_addr[-1];
  }

  // Converts bytecode PC into an offset.
  // For return addresses used in PcDescriptors, PC is also augmented by 1.
  // TODO(regis): Eliminate this correction.
  static intptr_t BytecodePcToOffset(uint32_t pc, bool is_return_address) {
    return pc + (is_return_address ? 1 : 0);
  }

  static uint32_t OffsetToBytecodePc(intptr_t offset, bool is_return_address) {
    return offset - (is_return_address ? 1 : 0);
  }

  static void GetVMInternalBytecodeInstructions(Opcode opcode,
                                                const KBCInstr** instructions,
                                                intptr_t* instructions_size);

  static Opcode BreakpointOpcode(Opcode opcode) {
    Opcode replacement;
    switch (kInstructionSize[opcode]) {
      case 1:
        replacement = kVMInternal_Breakpoint_0;
        break;
      case 2:
        replacement = kVMInternal_Breakpoint_D;
        break;
      case 3:
        replacement = kVMInternal_Breakpoint_A_E;
        break;
      case 4:
        replacement = kVMInternal_Breakpoint_A_B_C;
        break;
      case 5:
        replacement = kVMInternal_Breakpoint_D_Wide;
        break;
      case 6:
        replacement = kVMInternal_Breakpoint_A_E_Wide;
        break;
      default:
        UNREACHABLE();
        return kTrap;
    }
    ASSERT_EQUAL(kInstructionSize[replacement], kInstructionSize[opcode]);
    return replacement;
  }

  static Opcode BreakpointOpcode(const KBCInstr* instr) {
    return BreakpointOpcode(DecodeOpcode(instr));
  }

 private:
  friend class Interpreter;  // for IsWide(Opcode) in static_asserts.

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(KernelBytecode);
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_KBC_H_
