// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_KBC_H_
#define RUNTIME_VM_CONSTANTS_KBC_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {

// clang-format off
// List of KernelBytecode instructions.
//
// INTERPRETER STATE
//
//      current frame info (see stack_frame_kbc.h for layout)
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
//   | opcode |    A   |    B   |    Y   | A_B_Y: 2 unsigned 8-bit operands
//   +--------+--------+--------+--------+        1 signed 8-bit operand
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
//  - Entry rD
//
//    Function prologue for the function
//        rD - number of local slots to reserve;
//
//  - EntryFixed A, D
//
//    Function prologue for functions without optional arguments.
//    Checks number of arguments.
//        A - expected number of positional arguments;
//        D - number of local slots to reserve;
//
//  - EntryOptional A, B, C
//
//    Function prologue for the function with optional or named arguments:
//        A - expected number of positional arguments;
//        B - number of optional arguments;
//        C - number of named arguments;
//
//    Only one of B and C can be not 0.
//
//    If B is not 0 then EntryOptional bytecode is followed by B LoadConstant
//    bytecodes specifying default values for optional arguments.
//
//    If C is not 0 then EntryOptional is followed by 2 * C LoadConstant
//    bytecodes.
//    Bytecode at 2 * i specifies name of the i-th named argument and at
//    2 * i + 1 default value. rA part of the LoadConstant bytecode specifies
//    the location of the parameter on the stack. Here named arguments are
//    sorted alphabetically to enable linear matching similar to how function
//    prologues are implemented on other architectures.
//
//    Note: Unlike Entry bytecode EntryOptional does not setup the frame for
//    local variables this is done by a separate bytecode Frame, which should
//    follow EntryOptional and its LoadConstant instructions.
//
//  - LoadConstant rA, D
//
//    Used in conjunction with EntryOptional instruction to describe names and
//    default values of optional parameters.
//
//  - Frame D
//
//    Reserve and initialize with null space for D local variables.
//
//  - CheckFunctionTypeArgs A, D
//
//    Check for a passed-in type argument vector of length A and
//    store it at FP[D].
//
//  - CheckStack
//
//    Compare SP against isolate stack limit and call StackOverflow handler if
//    necessary.
//
//  - Allocate D
//
//    Allocate object of class PP[D] with no type arguments.
//
//  - AllocateT
//
//    Allocate object of class SP[0] with type arguments SP[-1].
//
//  - CreateArrayTOS
//
//    Allocate array of length SP[0] with type arguments SP[-1].
//
//  - AllocateContext D
//
//    Allocate Context object assuming for D context variables.
//
//  - CloneContext
//
//    Clone context stored in TOS.
//
//  - LoadContextParent
//
//    Load parent from context SP[0].
//
//  - StoreContextParent
//
//    Store context SP[0] into `parent` field of context SP[-1].
//
//  - LoadContextVar D
//
//    Load value from context SP[0] at index D.
//
//  - StoreContextVar D
//
//    Store value SP[0] into context SP[-1] at index D.
//
//  - PushConstant D
//
//    Push value at index D from constant pool onto the stack.
//
//  - PushNull
//
//    Push `null` onto the stack.
//
//  - PushTrue
//
//    Push `true` onto the stack.
//
//  - PushFalse
//
//    Push `false` onto the stack.
//
//  - PushInt rX
//
//    Push int rX onto the stack.
//
//  - Drop1
//
//    Drop 1 value from the stack
//
//  - Push rX
//
//    Push FP[rX] to the stack.
//
//  - StoreLocal rX; PopLocal rX
//
//    Store top of the stack into FP[rX] and pop it if needed.
//
//  - LoadFieldTOS D
//
//    Push value at offset (in words) PP[D] from object SP[0].
//
//  - StoreFieldTOS D
//
//    Store value SP[0] into object SP[-1] at offset (in words) PP[D].
//
//  - StoreIndexedTOS
//
//    Store SP[0] into array SP[-2] at index SP[-1]. No typechecking is done.
//    SP[-2] is assumed to be a RawArray, SP[-1] to be a smi.
//
//  - PushStatic
//
//    Pushes value of the static field PP[D] on to the stack.
//
//  - StoreStaticTOS D
//
//    Stores TOS into the static field PP[D].
//
//  - Jump target
//
//    Jump to the given target. Target is specified as offset from the PC of the
//    jump instruction.
//
//  - JumpIfNoAsserts target
//
//    Jump to the given target if assertions are not enabled.
//    Target is specified as offset from the PC of the jump instruction.
//
//  - JumpIfNotZeroTypeArgs target
//
//    Jump to the given target if number of passed function type
//    arguments is not zero.
//    Target is specified as offset from the PC of the jump instruction.
//
//  - JumpIfEqStrict target; JumpIfNeStrict target
//
//    Jump to the given target if SP[-1] is the same (JumpIfEqStrict) /
//    not the same (JumpIfNeStrict) object as SP[0].
//
//  - JumpIfTrue target; JumpIfFalse target
//  - JumpIfNull target; JumpIfNotNull target
//
//    Jump to the given target if SP[0] is true/false/null/not null.
//
//  - IndirectStaticCall ArgC, D
//
//    Invoke the function given by the ICData in SP[0] with arguments
//    SP[-(1+ArgC)], ..., SP[-1] and argument descriptor PP[D], which
//    indicates whether the first argument is a type argument vector.
//
//  - InstanceCall ArgC, D
//
//    Lookup and invoke method using ICData in PP[D]
//    with arguments SP[-(1+ArgC)], ..., SP[-1].
//    The ICData indicates whether the first argument is a type argument vector.
//
//  - NativeCall D
//
//    Invoke native function described by array at pool[D].
//    array[0] is wrapper, array[1] is function, array[2] is argc_tag.
//
//  - ReturnTOS
//
//    Return to the caller using a value from the top-of-stack as a result.
//
//    Note: return instruction knows how many arguments to remove from the
//    stack because it can look at the call instruction at caller's PC and
//    take argument count from it.
//
//  - AssertAssignable A, D
//
//    Assert that instance SP[-4] is assignable to variable named SP[0] of
//    type SP[-1] with instantiator type arguments SP[-3] and function type
//    arguments SP[-2] using SubtypeTestCache PP[D].
//    If A is 1, then the instance may be a Smi.
//
//    Instance remains on stack. Other arguments are consumed.
//
//  - AssertBoolean A
//
//    Assert that TOS is a boolean (A = 1) or that TOS is not null (A = 0).
//
//  - AssertSubtype
//
//    Assert that one type is a subtype of another.  Throws a TypeError
//    otherwise.  The stack has the following arguments on it:
//
//        SP[-4]  instantiator type args
//        SP[-3]  function type args
//        SP[-2]  sub_type
//        SP[-1]  super_type
//        SP[-0]  dst_name
//
//    All 5 arguments are consumed from the stack and no results is pushed.
//
//  - LoadTypeArgumentsField D
//
//    Load instantiator type arguments from an instance SP[0].
//    PP[D] = offset (in words) of type arguments field corresponding
//    to an instance's class.
//
//  - InstantiateType D
//
//    Instantiate type PP[D] with instantiator type arguments SP[-1] and
//    function type arguments SP[0].
//
//  - InstantiateTypeArgumentsTOS D
//
//    Instantiate type arguments PP[D] with instantiator type arguments SP[-1]
//    and function type arguments SP[0].
//
//  - Throw A
//
//    Throw (Rethrow if A != 0) exception. Exception object and stack object
//    are taken from TOS.
//
//  - MoveSpecial rA, D
//
//    Copy special values from inside interpreter to FP[rA]. Currently only
//    used to pass exception object (D = 0) and stack trace object (D = 1) to
//    catch handler.
//
//  - SetFrame A
//
//    Reinitialize SP assuming that current frame has size A.
//    Used to drop temporaries from the stack in the exception handler.
//
//  - BooleanNegateTOS
//
//    SP[0] = !SP[0]
//
//  - EqualsNull
//
//    SP[0] = (SP[0] == null) ? true : false
//
//  - NegateInt
//
//    Equivalent to invocation of unary int operator-.
//    Receiver should have static type int.
//    Check SP[0] for null; SP[0] = -SP[0].
//
//  - AddInt; SubInt; MulInt; TruncDivInt; ModInt; BitAndInt; BitOrInt;
//    BitXorInt; ShlInt; ShrInt
//
//    Equivalent to invocation of binary int operator +, -, *, ~/, %, &, |,
//    ^, << or >>. Receiver and argument should have static type int.
//    Check SP[-1] and SP[0] for null; push SP[-1] <op> SP[0].
//
//  - CompareIntEq; CompareIntGt; CompareIntLt; CompareIntGe; CompareIntLe
//
//    Equivalent to invocation of binary int operator ==, >, <, >= or <=.
//    Receiver and argument should have static type int.
//    Check SP[-1] and SP[0] for null; push SP[-1] <op> SP[0] ? true : false.
//
// BYTECODE LIST FORMAT
//
// KernelBytecode list below is specified using the following format:
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
//               instruction because PC is incremented immediately after fetch
//               and before decoding.
//
#define KERNEL_BYTECODES_LIST(V)                                               \
  V(Trap,                                  0, ___, ___, ___)                   \
  V(Entry,                                 D, num, ___, ___)                   \
  V(EntryFixed,                          A_D, num, num, ___)                   \
  V(EntryOptional,                     A_B_C, num, num, num)                   \
  V(LoadConstant,                        A_D, reg, lit, ___)                   \
  V(Frame,                                 D, num, ___, ___)                   \
  V(CheckFunctionTypeArgs,               A_D, num, num, ___)                   \
  V(CheckStack,                            0, ___, ___, ___)                   \
  V(Allocate,                              D, lit, ___, ___)                   \
  V(AllocateT,                             0, ___, ___, ___)                   \
  V(CreateArrayTOS,                        0, ___, ___, ___)                   \
  V(AllocateContext,                       D, num, ___, ___)                   \
  V(CloneContext,                          0, ___, ___, ___)                   \
  V(LoadContextParent,                     0, ___, ___, ___)                   \
  V(StoreContextParent,                    0, ___, ___, ___)                   \
  V(LoadContextVar,                        D, num, ___, ___)                   \
  V(StoreContextVar,                       D, num, ___, ___)                   \
  V(PushConstant,                          D, lit, ___, ___)                   \
  V(PushNull,                              0, ___, ___, ___)                   \
  V(PushTrue,                              0, ___, ___, ___)                   \
  V(PushFalse,                             0, ___, ___, ___)                   \
  V(PushInt,                               X, num, ___, ___)                   \
  V(Drop1,                                 0, ___, ___, ___)                   \
  V(Push,                                  X, xeg, ___, ___)                   \
  V(PopLocal,                              X, xeg, ___, ___)                   \
  V(StoreLocal,                            X, xeg, ___, ___)                   \
  V(LoadFieldTOS,                          D, lit, ___, ___)                   \
  V(StoreFieldTOS,                         D, lit, ___, ___)                   \
  V(StoreIndexedTOS,                       0, ___, ___, ___)                   \
  V(PushStatic,                            D, lit, ___, ___)                   \
  V(StoreStaticTOS,                        D, lit, ___, ___)                   \
  V(Jump,                                  T, tgt, ___, ___)                   \
  V(JumpIfNoAsserts,                       T, tgt, ___, ___)                   \
  V(JumpIfNotZeroTypeArgs,                 T, tgt, ___, ___)                   \
  V(JumpIfEqStrict,                        T, tgt, ___, ___)                   \
  V(JumpIfNeStrict,                        T, tgt, ___, ___)                   \
  V(JumpIfTrue,                            T, tgt, ___, ___)                   \
  V(JumpIfFalse,                           T, tgt, ___, ___)                   \
  V(JumpIfNull,                            T, tgt, ___, ___)                   \
  V(JumpIfNotNull,                         T, tgt, ___, ___)                   \
  V(IndirectStaticCall,                  A_D, num, num, ___)                   \
  V(InstanceCall,                        A_D, num, num, ___)                   \
  V(NativeCall,                            D, lit, ___, ___)                   \
  V(ReturnTOS,                             0, ___, ___, ___)                   \
  V(AssertAssignable,                    A_D, num, lit, ___)                   \
  V(AssertBoolean,                         A, num, ___, ___)                   \
  V(AssertSubtype,                         0, ___, ___, ___)                   \
  V(LoadTypeArgumentsField,                D, lit, ___, ___)                   \
  V(InstantiateType,                       D, lit, ___, ___)                   \
  V(InstantiateTypeArgumentsTOS,         A_D, num, lit, ___)                   \
  V(Throw,                                 A, num, ___, ___)                   \
  V(MoveSpecial,                         A_D, reg, num, ___)                   \
  V(SetFrame,                              A, num, ___, num)                   \
  V(BooleanNegateTOS,                      0, ___, ___, ___)                   \
  V(EqualsNull,                            0, ___, ___, ___)                   \
  V(NegateInt,                             0, ___, ___, ___)                   \
  V(AddInt,                                0, ___, ___, ___)                   \
  V(SubInt,                                0, ___, ___, ___)                   \
  V(MulInt,                                0, ___, ___, ___)                   \
  V(TruncDivInt,                           0, ___, ___, ___)                   \
  V(ModInt,                                0, ___, ___, ___)                   \
  V(BitAndInt,                             0, ___, ___, ___)                   \
  V(BitOrInt,                              0, ___, ___, ___)                   \
  V(BitXorInt,                             0, ___, ___, ___)                   \
  V(ShlInt,                                0, ___, ___, ___)                   \
  V(ShrInt,                                0, ___, ___, ___)                   \
  V(CompareIntEq,                          0, ___, ___, ___)                   \
  V(CompareIntGt,                          0, ___, ___, ___)                   \
  V(CompareIntLt,                          0, ___, ___, ___)                   \
  V(CompareIntGe,                          0, ___, ___, ___)                   \
  V(CompareIntLe,                          0, ___, ___, ___)

// clang-format on

typedef uint32_t KBCInstr;

class KernelBytecode {
 public:
  enum Opcode {
#define DECLARE_BYTECODE(name, encoding, op1, op2, op3) k##name,
    KERNEL_BYTECODES_LIST(DECLARE_BYTECODE)
#undef DECLARE_BYTECODE
  };

  static const char* NameOf(KBCInstr instr) {
    const char* names[] = {
#define NAME(name, encoding, op1, op2, op3) #name,
        KERNEL_BYTECODES_LIST(NAME)
#undef NAME
    };
    return names[DecodeOpcode(instr)];
  }

  enum SpecialIndex {
    kExceptionSpecialIndex,
    kStackTraceSpecialIndex,
    kSpecialIndexCount
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
  static const intptr_t kYShift = 24;
  static const intptr_t kYMask = 0xFF;
  static const intptr_t kTShift = 8;

  static KBCInstr Encode(Opcode op, uintptr_t a, uintptr_t b, uintptr_t c) {
    ASSERT((a & kAMask) == a);
    ASSERT((b & kBMask) == b);
    ASSERT((c & kCMask) == c);
    return op | (a << kAShift) | (b << kBShift) | (c << kCShift);
  }

  static KBCInstr Encode(Opcode op, uintptr_t a, uintptr_t d) {
    ASSERT((a & kAMask) == a);
    ASSERT((d & kDMask) == d);
    return op | (a << kAShift) | (d << kDShift);
  }

  static KBCInstr EncodeSigned(Opcode op, uintptr_t a, intptr_t x) {
    ASSERT((a & kAMask) == a);
    ASSERT((x << kDShift) >> kDShift == x);
    return op | (a << kAShift) | (x << kDShift);
  }

  static KBCInstr EncodeSigned(Opcode op, intptr_t x) {
    ASSERT((x << kAShift) >> kAShift == x);
    return op | (x << kAShift);
  }

  static KBCInstr Encode(Opcode op) { return op; }

  DART_FORCE_INLINE static uint8_t DecodeA(KBCInstr bc) {
    return (bc >> kAShift) & kAMask;
  }

  DART_FORCE_INLINE static uint8_t DecodeB(KBCInstr bc) {
    return (bc >> kBShift) & kBMask;
  }

  DART_FORCE_INLINE static uint8_t DecodeC(KBCInstr bc) {
    return (bc >> kCShift) & kCMask;
  }

  DART_FORCE_INLINE static uint16_t DecodeD(KBCInstr bc) {
    return (bc >> kDShift) & kDMask;
  }

  DART_FORCE_INLINE static int16_t DecodeX(KBCInstr bc) {
    return static_cast<int16_t>((bc >> kDShift) & kDMask);
  }

  DART_FORCE_INLINE static int32_t DecodeT(KBCInstr bc) {
    return static_cast<int32_t>(bc) >> kTShift;
  }

  DART_FORCE_INLINE static Opcode DecodeOpcode(KBCInstr bc) {
    return static_cast<Opcode>(bc & 0xFF);
  }

  DART_FORCE_INLINE static bool IsTrap(KBCInstr instr) {
    return DecodeOpcode(instr) == KernelBytecode::kTrap;
  }

  DART_FORCE_INLINE static bool IsJumpOpcode(KBCInstr instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kJump:
      case KernelBytecode::kJumpIfNoAsserts:
      case KernelBytecode::kJumpIfNotZeroTypeArgs:
      case KernelBytecode::kJumpIfEqStrict:
      case KernelBytecode::kJumpIfNeStrict:
      case KernelBytecode::kJumpIfTrue:
      case KernelBytecode::kJumpIfFalse:
      case KernelBytecode::kJumpIfNull:
      case KernelBytecode::kJumpIfNotNull:
        return true;

      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsCallOpcode(KBCInstr instr) {
    switch (DecodeOpcode(instr)) {
      case KernelBytecode::kIndirectStaticCall:
      case KernelBytecode::kInstanceCall:
        return true;

      default:
        return false;
    }
  }

  static const uint8_t kNativeCallToGrowableListArgc = 2;

  DART_FORCE_INLINE static uint8_t DecodeArgc(KBCInstr call) {
    if (DecodeOpcode(call) == KernelBytecode::kNativeCall) {
      // The only NativeCall redirecting to a bytecode function is the call
      // to new _GrowableList<E>(0).
      return kNativeCallToGrowableListArgc;
    }
    ASSERT(IsCallOpcode(call));
    return (call >> 8) & 0xFF;
  }

  static KBCInstr At(uword pc) { return *reinterpret_cast<KBCInstr*>(pc); }

  // Converts bytecode PC into an offset.
  // For return addresses used in PcDescriptors, PC is also advanced to the
  // next instruction.
  static intptr_t BytecodePcToOffset(uint32_t pc, bool is_return_address) {
    return sizeof(KBCInstr) * (pc + (is_return_address ? 1 : 0));
  }

  static uint32_t OffsetToBytecodePc(intptr_t offset, bool is_return_address) {
    return (offset / sizeof(KBCInstr)) - (is_return_address ? 1 : 0);
  }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(KernelBytecode);
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_KBC_H_
