// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CONSTANTS_DBC_H_
#define VM_CONSTANTS_DBC_H_

#include "platform/globals.h"
#include "platform/assert.h"
#include "platform/utils.h"


namespace dart {

// List of Dart Bytecode instructions.
//
// INTERPRETER STATE
//
//      current frame info (see stack_frame_dbc.h for layout)
//        v-----^-----v
//   ~----+----~ ~----+-------+-------+-~ ~-+-------+-------+-~
//   ~    |    ~ ~    | FP[0] | FP[1] | ~ ~ | SP[-1]| SP[0] |
//   ~----+----~ ~----+-------+-------+-~ ~-+-------+-------+-~
//                    ^                             ^
//                    FP                            SP
//
//
// The state of execution is captured in few interpreter registers:
//
//   FP - base of the current frame
//   SP - top of the stack (TOS) for the current frame
//   PP - object pool for the currently execution function
//
// Frame info stored below FP additionally contains pointers to the currently
// executing function and code (see stack_frame_dbc.h for more information).
//
// In the unoptimized code most of bytecodes take operands implicitly from
// stack and store results again on the stack. Constant operands are usually
// taken from the object pool by index.
//
// ENCODING
//
// Each instruction is a 32-bit integer with opcode stored in the least
// significant byte. The following operand encodings are used:
//
//   0........8.......16.......24.......32
//   +--------+--------+--------+--------+
//   | opcode |~~~~~~~~~~~~~~~~~~~~~~~~~~|   0: no operands
//   +--------+--------+--------+--------+
//
//   +--------+--------+--------+--------+
//   | opcode |    A   |~~~~~~~~~~~~~~~~~|   A: single unsigned 8-bit operand
//   +--------+--------+--------+--------+
//
//   +--------+--------+--------+--------+
//   | opcode |    A   |        D        | A_D: unsigned 8-bit operand and
//   +--------+--------+--------+--------+      unsigned 16-bit operand
//
//   +--------+--------+--------+--------+
//   | opcode |    A   |        X        | A_X: unsigned 8-bit operand and
//   +--------+--------+--------+--------+      signed 16-bit operand
//
//   +--------+--------+--------+--------+
//   | opcode |~~~~~~~~|        D        |   D: unsigned 16-bit operand
//   +--------+--------+--------+--------+
//
//   +--------+--------+--------+--------+
//   | opcode |~~~~~~~~|        X        |   X: signed 16-bit operand
//   +--------+--------+--------+--------+
//
//   +--------+--------+--------+--------+
//   | opcode |    A   |    B   |    C   | A_B_C: 3 unsigned 8-bit operands
//   +--------+--------+--------+--------+
//
//   +--------+--------+--------+--------+
//   | opcode |             T            |   T: signed 24-bit operand
//   +--------+--------+--------+--------+
//
//
// INSTRUCTIONS
//
//  - Trap
//
//    Unreachable instruction.
//
//  - Compile
//
//    Compile current function and start executing newly produced code
//    (used to implement LazyCompileStub);
//
//  - Intrinsic id
//
//    Execute intrinsic with the given id. If intrinsic returns true then
//    return from the current function to the caller passing value produced
//    by the intrinsic as a result;
//
//  - Drop1; DropR n; Drop n
//
//    Drop 1 or n values from the stack, if instruction is DropR push the first
//    dropped value to the stack;
//
//  - Jump target
//
//    Jump to the given target. Target is specified as offset from the PC of the
//    jump instruction.
//
//  - Return R; ReturnTOS
//
//    Return to the caller using either a value from the given register or a
//    value from the top-of-stack as a result.
//
//    Note: return instruction knows how many arguments to remove from the
//    stack because it can look at the call instruction at caller's PC and
//    take argument count from it.
//
//  - Move rA, rX
//
//    FP[rA] <- FP[rX]
//    Note: rX is signed so it can be used to address parameters which are
//    at negative indices with respect to FP.
//
//  - Push rX
//
//    Push FP[rX] to the stack.
//
//  - LoadConstant rA, D; PushConstant D
//
//    Load value at index D from constant pool into FP[rA] or push it onto the
//    stack.
//
//  - StoreLocal rX; PopLocal rX
//
//    Store top of the stack into FP[rX] and pop it if needed.
//
//  - StaticCall ArgC, D
//
//    Invoke function in SP[0] with arguments SP[-(1+ArgC)], ..., SP[-1] and
//    argument descriptor PP[D].
//
//  - InstanceCall ArgC, D; InstanceCall2 ArgC, D; InstanceCall3 ArgC, D
//
//    Lookup and invoke method using ICData in PP[D] with arguments
//    SP[-(1+ArgC)], ..., SP[-1].
//
//  - NativeCall, NativeBootstrapCall
//
//    Invoke native function SP[-1] with argc_tag SP[0].
//
//  - AddTOS; SubTOS; MulTOS; BitOrTOS; BitAndTOS; EqualTOS; LessThanTOS;
//    GreaterThanTOS;
//
//    Smi fast-path for a corresponding method. Checks if SP[0] and SP[-1] are
//    both smis and result of SP[0] <op> SP[-1] is a smi - if this is true
//    then pops operands and pushes result on the stack and skips the next
//    instruction (which implements a slow path fallback).
//
//  - StoreStaticTOS D
//
//    Stores TOS into the static field PP[D].
//
//  - PushStatic
//
//    Pushes value of the static field PP[D] on to the stack.
//
//  - InitStaticTOS
//
//    Takes static field from TOS and ensures that it is initialized.
//
//  - IfNeStrictTOS; IfEqStrictTOS; IfNeStrictNumTOS; IfEqStrictNumTOS
//
//    Skips the next instruction unless the given condition holds. 'Num'
//    variants perform number check while non-Num variants just compare
//    RawObject pointers.
//
//    Used to implement conditional jump:
//
//        IfNeStrictTOS
//        Jump T         ;; jump if not equal
//
//  - CreateArrayTOS
//
//    Allocate array of length SP[0] with type arguments SP[-1].
//
//  - Allocate D
//
//    Allocate object of class PP[D] with no type arguments.
//
//  - AllocateT
//
//    Allocate object of class SP[0] with type arguments SP[-1].
//
//  - StoreIndexedTOS
//
//    Store SP[0] into array SP[-2] at index SP[-1]. No typechecking is done.
//    SP[-2] is assumed to be a RawArray, SP[-1] to be a smi.
//
//  - StoreField rA, B, rC
//
//    Store value FP[rC] into object FP[rA] at offset (in words) B.
//
//  - StoreFieldTOS D
//
//    Store value SP[0] into object SP[-1] at offset (in words) D.
//
//  - LoadField rA, rB, C
//
//    Load value at offset (in words) C from object FP[rB] into FP[rA].
//
//  - LoadFieldTOS D
//
//    Push value at offset (in words) D from object SP[0].
//
//  - BooleanNegateTOS
//
//    SP[0] = !SP[0]
//
//  - Throw A
//
//    Throw (Rethrow if A != 0) exception. Exception object and stack object
//    are taken from TOS.
//
//  - Entry A, B, rC
//
//    Function prologue for the function with no optional or named arguments:
//        A - expected number of positional arguments;
//        B - number of local slots to reserve;
//        rC - specifies context register to initialize with empty context.
//
//  - EntryOpt A, B, C
//
//    Function prologue for the function with optional or named arguments:
//        A - expected number of positional arguments;
//        B - number of optional arguments;
//        C - number of named arguments;
//
//    Only one of B and C can be not 0.
//
//    If B is not 0 then EntryOpt bytecode is followed by B LoadConstant
//    bytecodes specifying default values for optional arguments.
//
//    If C is not 0 then EntryOpt is followed by 2 * B LoadConstant bytecodes.
//    Bytecode at 2 * i specifies name of the i-th named argument and at
//    2 * i + 1 default value. rA part of the LoadConstant bytecode specifies
//    the location of the parameter on the stack. Here named arguments are
//    sorted alphabetically to enable linear matching similar to how function
//    prologues are implemented on other architectures.
//
//    Note: Unlike Entry bytecode EntryOpt does not setup the frame for
//    local variables this is done by a separate bytecode Frame.
//
//  - Frame D
//
//    Reserve and initialize with null space for D local variables.
//
//  - SetFrame A
//
//    Reinitialize SP assuming that current frame has size A.
//    Used to drop temporaries from the stack in the exception handler.
//
//  - AllocateContext D
//
//    Allocate Context object assuming for D context variables.
//
//  - CloneContext
//
//    Clone context stored in TOS.
//
//  - MoveSpecial rA, D
//
//    Copy special values from inside interpreter to FP[rA]. Currently only
//    used to pass exception object (D = 0) and stack trace object (D = 1) to
//    catch handler.
//
//  - InstantiateType D
//
//    Instantiate type PP[D] with instantiator type arguments SP[0].
//
//  - InstantiateTypeArgumentsTOS D
//
//    Instantiate type arguments PP[D] with instantiator SP[0].
//
//  - AssertAssignable D
//
//    Assert that SP[-3] is assignable to variable named SP[0] of type
//    SP[-1] with type arguments SP[-2] using SubtypeTestCache PP[D].
//
//  - AssertBoolean A
//
//    Assert that TOS is a boolean (A = 1) or that TOS is not null (A = 0).
//
//  - CheckStack
//
//    Compare SP against isolate stack limit and call StackOverflow handler if
//    necessary.
//
//  - DebugStep, DebugBreak A
//
//    Debugger support. DebugBreak is bytecode that can be patched into the
//    instruction stream to trigger in place breakpoint.
//
//    When patching instance or static call with DebugBreak we set A to
//    match patched call's argument count so that Return instructions continue
//    to work.
//
// TODO(vegorov) the way we replace calls with DebugBreak does not work
//               with our smi fast paths because DebugBreak is simply skipped.
//
// BYTECODE LIST FORMAT
//
// Bytecode list below is specified using the following format:
//
//     V(BytecodeName, OperandForm, Op1, Op2, Op3)
//
// - OperandForm specifies operand encoding and should be one of 0, A, T, A_D,
//   A_X, X, D (see ENCODING section above).
//
// - Op1, Op2, Op2 specify operand meaning. Possible values:
//
//     ___ ignored / non-existent operand
//     num immediate operand
//     lit constant literal from object pool
//     reg register (unsigned FP relative local)
//     xeg x-register (signed FP relative local)
//     tgt jump target relative to the PC of the current instruction
//
// TODO(vegorov) jump targets should be encoded relative to PC of the next
//               instruction because PC is incremeted immediately after fetch
//               and before decoding.
//
#define BYTECODES_LIST(V)                              \
  V(Trap,                            0, ___, ___, ___) \
  V(Compile,                         0, ___, ___, ___) \
  V(Intrinsic,                       A, num, ___, ___) \
  V(Drop1,                           0, ___, ___, ___) \
  V(DropR,                           A, num, ___, ___) \
  V(Drop,                            A, num, ___, ___) \
  V(Jump,                            T, tgt, ___, ___) \
  V(Return,                          A, num, ___, ___) \
  V(ReturnTOS,                       0, ___, ___, ___) \
  V(Move,                          A_X, reg, xeg, ___) \
  V(Push,                            X, xeg, ___, ___) \
  V(LoadConstant,                  A_D, reg, lit, ___) \
  V(PushConstant,                    D, lit, ___, ___) \
  V(StoreLocal,                      X, xeg, ___, ___) \
  V(PopLocal,                        X, xeg, ___, ___) \
  V(StaticCall,                    A_D, num, num, ___) \
  V(InstanceCall,                  A_D, num, num, ___) \
  V(InstanceCall2,                 A_D, num, num, ___) \
  V(InstanceCall3,                 A_D, num, num, ___) \
  V(NativeCall,                      0, ___, ___, ___) \
  V(NativeBootstrapCall,             0, ___, ___, ___) \
  V(AddTOS,                          0, ___, ___, ___) \
  V(SubTOS,                          0, ___, ___, ___) \
  V(MulTOS,                          0, ___, ___, ___) \
  V(BitOrTOS,                        0, ___, ___, ___) \
  V(BitAndTOS,                       0, ___, ___, ___) \
  V(EqualTOS,                        0, ___, ___, ___) \
  V(LessThanTOS,                     0, ___, ___, ___) \
  V(GreaterThanTOS,                  0, ___, ___, ___) \
  V(StoreStaticTOS,                  D, lit, ___, ___) \
  V(PushStatic,                      D, lit, ___, ___) \
  V(InitStaticTOS,                   0, ___, ___, ___) \
  V(IfNeStrictTOS,                   0, ___, ___, ___) \
  V(IfEqStrictTOS,                   0, ___, ___, ___) \
  V(IfNeStrictNumTOS,                0, ___, ___, ___) \
  V(IfEqStrictNumTOS,                0, ___, ___, ___) \
  V(CreateArrayTOS,                  0, ___, ___, ___) \
  V(Allocate,                        D, lit, ___, ___) \
  V(AllocateT,                       0, ___, ___, ___) \
  V(StoreIndexedTOS,                 0, ___, ___, ___) \
  V(StoreField,                  A_B_C, reg, reg, reg) \
  V(StoreFieldTOS,                   D, num, ___, ___) \
  V(LoadField,                   A_B_C, reg, reg, reg) \
  V(LoadFieldTOS,                    D, num, ___, ___) \
  V(BooleanNegateTOS,                0, ___, ___, ___) \
  V(Throw,                           A, num, ___, ___) \
  V(Entry,                       A_B_C, num, num, num) \
  V(EntryOpt,                    A_B_C, num, num, num) \
  V(Frame,                           D, num, ___, ___) \
  V(SetFrame,                        A, num, ___, num) \
  V(AllocateContext,                 D, num, ___, ___) \
  V(CloneContext,                    0, ___, ___, ___) \
  V(MoveSpecial,                   A_D, reg, num, ___) \
  V(InstantiateType,                 D, lit, ___, ___) \
  V(InstantiateTypeArgumentsTOS,   A_D, num, lit, ___) \
  V(AssertAssignable,                D, num, lit, ___) \
  V(AssertBoolean,                   A, num, ___, ___) \
  V(CheckStack,                      0, ___, ___, ___) \
  V(DebugStep,                       0, ___, ___, ___) \
  V(DebugBreak,                      A, num, ___, ___) \

typedef uint32_t Instr;

class Bytecode {
 public:
  enum Opcode {
#define DECLARE_BYTECODE(name, encoding, op1, op2, op3) k##name,
BYTECODES_LIST(DECLARE_BYTECODE)
#undef DECLARE_BYTECODE
  };

  static const intptr_t kOpShift = 0;
  static const intptr_t kAShift = 8;
  static const intptr_t kAMask = 0xFF;
  static const intptr_t kBShift = 16;
  static const intptr_t kBMask = 0xFF;
  static const intptr_t kCShift = 24;
  static const intptr_t kCMask = 0xFF;
  static const intptr_t kDShift = 16;
  static const intptr_t kDMask = 0xFFFF;

  static Instr Encode(Opcode op, uintptr_t a, uintptr_t b, uintptr_t c) {
    ASSERT((a & kAMask) == a);
    ASSERT((b & kBMask) == b);
    ASSERT((c & kCMask) == c);
    return op | (a << kAShift) | (b << kBShift) | (c << kCShift);
  }

  static Instr Encode(Opcode op, uintptr_t a, uintptr_t d) {
    ASSERT((a & kAMask) == a);
    ASSERT((d & kDMask) == d);
    return op | (a << kAShift) | (d << kDShift);
  }

  static Instr EncodeSigned(Opcode op, uintptr_t a, intptr_t x) {
    ASSERT((a & kAMask) == a);
    ASSERT((x << kDShift) >> kDShift == x);
    return op | (a << kAShift) | (x << kDShift);
  }

  static Instr EncodeSigned(Opcode op, intptr_t x) {
    ASSERT((x << kAShift) >> kAShift == x);
    return op | (x << kAShift);
  }

  static Instr Encode(Opcode op) {
    return op;
  }

  DART_FORCE_INLINE static uint8_t DecodeA(Instr bc) {
    return (bc >> kAShift) & kAMask;
  }

  DART_FORCE_INLINE static uint16_t DecodeD(Instr bc) {
    return (bc >> kDShift) & kDMask;
  }

  DART_FORCE_INLINE static Opcode DecodeOpcode(Instr bc) {
    return static_cast<Opcode>(bc & 0xFF);
  }

  DART_FORCE_INLINE static uint8_t DecodeArgc(Instr call) {
#if defined(DEBUG)
    const Opcode op = DecodeOpcode(call);
    ASSERT((op == Bytecode::kStaticCall) ||
           (op == Bytecode::kInstanceCall) ||
           (op == Bytecode::kInstanceCall2) ||
           (op == Bytecode::kInstanceCall3) ||
           (op == Bytecode::kDebugBreak));
#endif
    return (call >> 8) & 0xFF;
  }
};

// Various dummy declarations to make shared code compile.
// TODO(vegorov) we need to prune away as much dead code as possible instead
// of just making it compile.
typedef int16_t Register;

const int16_t FPREG = 0;
const int16_t SPREG = 1;
const intptr_t kNumberOfCpuRegisters = 20;
const intptr_t kDartAvailableCpuRegs = 0;
const intptr_t kNoRegister = -1;
const intptr_t kReservedCpuRegisters = 0;
const intptr_t ARGS_DESC_REG = 0;
const intptr_t CODE_REG = 0;
const intptr_t kExceptionObjectReg = 0;
const intptr_t kStackTraceObjectReg = 0;
const intptr_t CTX = 0;

enum FpuRegister {
  kNoFpuRegister = -1,
  kFakeFpuRegister,
  kNumberOfDummyFpuRegisters,
};
const FpuRegister FpuTMP = kFakeFpuRegister;
const intptr_t kNumberOfFpuRegisters = 1;

enum Condition { EQ, NE };

}  // namespace dart

#endif  // VM_CONSTANTS_DBC_H_
