// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_DBC_H_
#define RUNTIME_VM_CONSTANTS_DBC_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {

// clang-format off
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
//  - Nop D
//
//    This instruction does nothing. It may refer to an object in the constant
//    pool that may be decoded by other instructions.
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
//  - Swap rA, rX
//
//    FP[rA], FP[rX] <- FP[rX], FP[rA]
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
//  - IndirectStaticCall ArgC, D
//
//    Invoke the function given by the ICData in SP[0] with arguments
//    SP[-(1+ArgC)], ..., SP[-1] and argument descriptor PP[D].
//
//  - InstanceCall<N> ArgC, D; InstanceCall<N>Opt ArgC, D
//
//    Lookup and invoke method with N checked arguments using ICData in PP[D]
//    with arguments SP[-(1+ArgC)], ..., SP[-1].
//
//  - NativeBootstrapCall, NativeNoScopeCall, NativeAutoScopeCall
//
//    Invoke native function SP[-1] with argc_tag SP[0].
//
//  - PushPolymorphicInstanceCall ArgC, D
//
//    Skips 2*D + 1 instructions and pushes a function object onto the stack
//    if one can be found as follows. Otherwise skips only 2*D instructions.
//    The function is looked up in the IC data encoded in the following 2*D
//    Nop instructions. The Nop instructions should be arranged in pairs with
//    the first being the cid, and the second being the function to push if
//    the cid matches the cid in the pair.
//
//  - PushPolymorphicInstanceCallByRange ArgC, D
//
//    Skips 3*D + 1 instructions and pushes a function object onto the stack
//    if one can be found as follows. Otherwise skips only 3*D instructions.
//    The function is looked up in the IC data encoded in the following 3*D
//    Nop instructions. The Nop instructions should be arranged in triples with
//    the first being the start cid, the second being the number of cids, and
//    the third being the function to push if the cid is in the range given
//    by the first two Nop instructions.
//
//  - OneByteStringFromCharCode rA, rX
//
//    Load the one-character symbol with the char code given by the Smi
//    in FP[rX] into FP[rA].
//
//  - StringToCharCode rA, rX
//
//    Load and smi-encode the single char code of the string in FP[rX] into
//    FP[rA]. If the string's length is not 1, load smi -1 instead.
//
//  - AddTOS; SubTOS; MulTOS; BitOrTOS; BitAndTOS; EqualTOS; LessThanTOS;
//    GreaterThanTOS;
//
//    Smi fast-path for a corresponding method. Checks if SP[0] and SP[-1] are
//    both smis and result of SP[0] <op> SP[-1] is a smi - if this is true
//    then pops operands and pushes result on the stack and skips the next
//    instruction (which implements a slow path fallback).
//
//  - Add, Sub, Mul, Div, Mod, Shl, Shr rA, rB, rC
//
//    Arithmetic operations on Smis. FP[rA] <- FP[rB] op FP[rC].
//    If these instructions can trigger a deoptimization, the following
//    instruction should be Deopt. If no deoptimization should be triggered,
//    the immediately following instruction is skipped. These instructions
//    expect their operands to be Smis, but don't check that they are.
//
//  - ShlImm rA, rB, rC
//
//    FP[rA] <- FP[rB] << rC. Shifts the Smi in FP[rB] left by rC. rC is
//    assumed to be a legal positive number by which left-shifting is possible.
//
//  - Min, Max rA, rB, rC
//
//    FP[rA] <- {min, max}(FP[rB], FP[rC]). Assumes that FP[rB], and FP[rC] are
//    Smis.
//
//  - Neg rA , rD
//
//    FP[rA] <- -FP[rD]. Assumes FP[rD] is a Smi. If there is no overflow the
//    immediately following instruction is skipped.
//
//  - DMin, DMax, DAdd, DSub, DMul, DDiv, DPow, DMod rA, rB, rC
//
//    Arithmetic operations on unboxed doubles. FP[rA] <- FP[rB] op FP[rC].
//
//  - DNeg, DCos, DSin, DSqrt rA, rD
//
//    FP[rA] <- op(FP[rD]). Assumes FP[rD] is an unboxed double.
//
//  - DTruncate, DFloor, DCeil rA, rD
//
//    Applies trunc(), floor(), or ceil() to the unboxed double in FP[rD], and
//    stores the result in FP[rA].
//
//  - DoubleToFloat, FloatToDouble rA, rD
//
//    Convert the unboxed float or double in FP[rD] as indicated, and store the
//    result in FP[rA].
//
//  - DoubleIsNaN rA, rD
//
//    If the unboxed double in FP[rD] is a NaN, then writes Bool::True().raw()
//    into FP[rA], and Bool::False().raw() otherwise.
//
//  - DoubleIsInfinite rA, rD
//
//    If the unboxed double in FP[rD] is + or - infinity, then
//    writes Bool::True().raw() into FP[rA], and Bool::False().raw() otherwise.
//
//  - BitOr, BitAnd, BitXor rA, rB, rC
//
//    FP[rA] <- FP[rB] op FP[rC]. These instructions expect their operands to be
//    Smis, but don't check that they are.
//
//  - BitNot rA, rD
//
//    FP[rA] <- ~FP[rD]. As above, assumes FP[rD] is a Smi.
//
//  - WriteIntoDouble rA, rD
//
//    Box the double in FP[rD] using the box in FP[rA].
//
//  - UnboxDouble rA, rD
//
//    Unbox the double in FP[rD] into FP[rA]. Assumes FP[rD] is a double.
//
//  - CheckedUnboxDouble rA, rD
//
//    Unboxes FP[rD] into FP[rA] and skips the following instruction unless
//    FP[rD] is not a double or a Smi. When FP[rD] is a Smi, converts it to a
//    double.
//
//  - UnboxInt32 rA, rB, C
//
//    Unboxes the integer in FP[rB] into FP[rA]. If C == 1, the value may be
//    truncated. If FP[rA] is successfully unboxed the following instruction is
//    skipped.
//
//  - BoxInt32 rA, rD
//
//    Boxes the unboxed signed 32-bit integer in FP[rD] into FP[rA].
//
//  - BoxUint32 rA, rD
//
//    Boxes the unboxed unsigned 32-bit integer in FP[rD] into FP[rA].
//
//  - SmiToDouble rA, rD
//
//    Convert the Smi in FP[rD] to an unboxed double in FP[rA].
//
//  - DoubleToSmi rA, rD
//
//    If the unboxed double in FP[rD] can be converted to a Smi in FP[rA], then
//    this instruction does so, and skips the following instruction. Otherwise,
//    the following instruction is not skipped.
//
//  - StoreStaticT`OS D
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
//  - If<Cond>(Num)TOS
//    If<Cond>(Num) rA, rD
//
//    Cond is either NeStrict or EqStrict
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
//  - If<Cond>Null rA
//
//    Cond is Eq or Ne. Skips the next instruction unless the given condition
//    holds.
//
//  - If<Cond> rA, rD
//
//    Cond is Le, Lt, Ge, Gt, unsigned variants ULe, ULt, UGe, UGt, and
//    unboxed double variants DEq, DNe, DLe, DLt, DGe, DGt.
//    Skips the next instruction unless FP[rA] <Cond> FP[rD]. Assumes that
//    FP[rA] and FP[rD] are Smis or unboxed doubles as indicated by <Cond>.
//
//  - CreateArrayTOS
//
//    Allocate array of length SP[0] with type arguments SP[-1].
//
//  - CreateArrayOpt rA, rB, rC
//
//    Try to allocate a new array where FP[rB] is the length, and FP[rC] is the
//    type. If allocation is successful, the result is stored in FP[rA], and
//    the next four instructions, which should be the
//    (Push type; Push length; AllocateTOS; PopLocal) slow path are skipped.
//
//  - Allocate D
//
//    Allocate object of class PP[D] with no type arguments.
//
//  - AllocateOpt rA, D
//
//    Try allocating an object with tags in PP[D] with no type arguments.
//    If allocation is successful, the result is stored in FP[rA], and
//    the next two instructions, which should be the (Allocate class; PopLocal)
//    slow path are skipped
//
//  - AllocateT
//
//    Allocate object of class SP[0] with type arguments SP[-1].
//
//  - AllocateTOpt rA, D
//
//    Similar to AllocateOpt with the difference that the offset of the
//    type arguments in the resulting object is taken from the D field of the
//    following Nop instruction, and on success 4 instructions are skipped and
//    the object at the top of the stack is popped.
//
//  - StoreIndexedTOS
//
//    Store SP[0] into array SP[-2] at index SP[-1]. No typechecking is done.
//    SP[-2] is assumed to be a RawArray, SP[-1] to be a smi.
//
//  - StoreIndexed rA, rB, rC
//
//    Store FP[rC] into array FP[rA] at index FP[rB]. No typechecking is done.
//    FP[rA] is assumed to be a RawArray, FP[rB] to be a smi.
//
//  - StoreIndexed{N}{Type} rA, rB, rC
//
//    Where Type is Float32, Float64, Uint8, or OneByteString
//    Where N is '', '4', or '8'. N may only be '4' for Float32 and '8' for
//    Float64.
//
//    Store the unboxed double or tagged Smi in FP[rC] into the typed data array
//    at FP[rA] at index FP[rB]. If N is not '', the index is assumed to be
//    already scaled by N.
//
//  - StoreIndexedExternalUint8 rA, rB, rC
//
//    Similar to StoreIndexedUint8 but FP[rA] is an external typed data aray.
//
//  - LoadIndexed rA, rB, rC
//
//    Loads from array FP[rB] at index FP[rC] into FP[rA]. No typechecking is
//    done. FP[rB] is assumed to be a RawArray, and to contain a Smi at FP[rC].
//
//  - LoadIndexed{N}{Type} rA, rB, rC
//
//    Where Type is Float32, Float64, OneByteString, TwoByteString, Uint8,
//    Int8, and N is '', '4', or '8'. N may only be '4' for Float32, and may
//    only be '8' for Float64.
//
//    Loads from typed data array FP[rB] at index FP[rC] into an unboxed double,
//    or tagged Smi in FP[rA] as indicated by the type in the name. If N is not
//    '', the index is assumed to be already scaled by N.
//
//  - LoadIndexedExternal{Int8, Uint8} rA, rB, rC
//
//    Loads from the external typed data array FP[rB] at index FP[rC] into
//    FP[rA]. No typechecking is done.
//
//  - StoreField rA, B, rC
//
//    Store value FP[rC] into object FP[rA] at offset (in words) B.
//
//  - StoreFieldExt rA, rD
//
//    Store value FP[rD] into object FP[rA] at offset (in words)
//    stored in the following Nop instruction. Used to access fields with
//    large offsets.
//
//  - StoreFieldTOS D
//
//    Store value SP[0] into object SP[-1] at offset (in words) D.
//
//  - LoadField rA, rB, C
//
//    Load value at offset (in words) C from object FP[rB] into FP[rA].
//
//  - LoadFieldExt rA, rD
//
//    Load value from object FP[rD] at offset (in words) stored in the
//    following Nop instruction into FP[rA]. Used to access fields with
//    large offsets.
//
//  - LoadUntagged rA, rB, C
//
//    Like LoadField, but assumes that FP[rB] is untagged.
//
//  - LoadFieldTOS D
//
//    Push value at offset (in words) D from object SP[0].
//
//  - BooleanNegateTOS
//
//    SP[0] = !SP[0]
//
//  - BooleanNegate rA, rD
//
//    FP[rA] = !FP[rD]
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
//    If C is not 0 then EntryOptional is followed by 2 * B LoadConstant
//    bytecodes.
//    Bytecode at 2 * i specifies name of the i-th named argument and at
//    2 * i + 1 default value. rA part of the LoadConstant bytecode specifies
//    the location of the parameter on the stack. Here named arguments are
//    sorted alphabetically to enable linear matching similar to how function
//    prologues are implemented on other architectures.
//
//    Note: Unlike Entry bytecode EntryOptional does not setup the frame for
//    local variables this is done by a separate bytecode Frame.
//
//  - EntryOptimized A, D
//
//    Function prologue for optimized functions with no optional or named
//    arguments.
//        A - expected number of positional arguments;
//        B - number of local slots to reserve for registers;
//
//    Note: reserved slots are not initialized because optimized code
//    has stack maps attached to call sites.
//
//  - HotCheck A, D
//
//    Increment current function's usage counter by A and check if it
//    exceeds D. If it does trigger (re)optimization of the current
//    function.
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
//  - AllocateUninitializedContext rA, D
//
//    Allocates an uninitialized context for D variables, and places the result
//    in FP[rA]. On success, skips the next 2 instructions, which should be the
//    slow path (AllocateContext D; PopLocal rA).
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
//    Instantiate type PP[D] with instantiator type arguments SP[-1] and
//    function type arguments SP[0].
//
//  - InstantiateTypeArgumentsTOS D
//
//    Instantiate type arguments PP[D] with instantiator type arguments SP[-1]
//    and function type arguments SP[0].
//
//  - InstanceOf
//
//    Test if instance SP[-4] with instantiator type arguments SP[-3] and
//    function type arguments SP[-2] is a subtype of type SP[-1] using
//    SubtypeTestCache SP[0], with result placed at top of stack.
//
//  - AssertAssignable A, D
//
//    Assert that instance SP[-4] is assignable to variable named SP[0] of
//    type SP[-1] with instantiator type arguments SP[-3] and function type
//    arguments SP[-2] using SubtypeTestCache PP[D].
//    If A is 1, then the instance may be a Smi.
//
//  - BadTypeError
//
//    If SP[-4] is non-null, throws a BadType error by calling into the runtime.
//    Assumes that the stack is arranged the same as for AssertAssignable.
//
//  - AssertBoolean A
//
//    Assert that TOS is a boolean (A = 1) or that TOS is not null (A = 0).
//
//  - TestSmi rA, rD
//
//    If FP[rA] & FP[rD] != 0, then skip the next instruction. FP[rA] and FP[rD]
//    must be Smis.
//
//  - TestCids rA, D
//
//    The next D instructions must be Nops whose D field encodes a class id. If
//    the class id of FP[rA] matches, jump to PC + N + 1 if the matching Nop's
//    A != 0 or PC + N + 2 if the matching Nop's A = 0. If no match is found,
//    jump to PC + N.
//
//  - CheckSmi rA
//
//    If FP[rA] is a Smi, then skip the next instruction.
//
//  - CheckEitherNonSmi rA, rD
//
//    If either FP[rA] or FP[rD] is not a Smi, then skip the next instruction.
//
//  - CheckClassId rA, D
//
//    If the class id in FP[rA] matches the class id D, then skip the
//    following instruction.
//
//  - CheckClassIdRange rA, D
//
//    Next instruction is a Nop with S, the size of the class-id range.
//    If the class id in FP[rA] is between the D D + S, then skip the
//    following instruction.
//
//  - CheckBitTest rA, D
//
//    Skips the next 3 instructions if the object at FP[rA] is a valid class for
//    a dense switch with low cid encoded in the following Nop instruction, and
//    the cid mask encoded in the Nop instruction after that, or if D == 1 and
//    FP[rA] is a Smi. Skips 2 instructions otherwise.
//
//  - CheckCids rA, rB, rC
//
//    Skips rC + 1 instructions if the object at FP[rA] is a Smi and
//    rB == 1, or if FP[rA]'s cid is found in the array of cids encoded by the
//    following rC Nop instructions. Otherwise skips only rC instructions.
//
//  - CheckCidsByRange rA, rB, rC
//
//    Skips rC + 1 instructions if the object at FP[rA] is a Smi and rB ==
//    1, or if FP[rA]'s cid is found in the array of cid ranges encoded by the
//    following rC Nop instructions. The cid ranges from a inclusive to b
//    exclusive are coded in pairs of (a, b - a). Otherwise skips only 2
//    instructions.
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
//  - LoadClassIdTOS, LoadClassId rA, D
//
//    LoadClassIdTOS loads the class id from the object at SP[0] and stores it
//    to SP[0]. LoadClassId loads the class id from FP[rA] and stores it to
//    FP[D].
//
//  - Deopt ArgC, D
//
//    If D != 0 then trigger eager deoptimization with deopt id (D - 1).
//    If D == 0 then trigger lazy deoptimization.
//
//    The meaning of operand ArgC (encoded as A operand) matches that of an
//    ArgC operand in call instructions. This is needed because we could
//    potentially patch calls instructions with a lazy deopt and we need to
//    ensure that any Return/ReturnTOS instructions
//    returning from the patched calls will continue to function,
//    e.g. in bytecode sequences like
//
//    InstanceCall ... <- lazy deopt inside first call
//    InstanceCall ... <- patches second call with Deopt
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
//               instruction because PC is incremented immediately after fetch
//               and before decoding.
//
#define BYTECODES_LIST(V)                                    \
  V(Trap,                                  0, ___, ___, ___) \
  V(Nop,                                 A_D, num, lit, ___) \
  V(Compile,                               0, ___, ___, ___) \
  V(HotCheck,                            A_D, num, num, ___) \
  V(Intrinsic,                             A, num, ___, ___) \
  V(Drop1,                                 0, ___, ___, ___) \
  V(DropR,                                 A, num, ___, ___) \
  V(Drop,                                  A, num, ___, ___) \
  V(Jump,                                  T, tgt, ___, ___) \
  V(Return,                                A, reg, ___, ___) \
  V(ReturnTOS,                             0, ___, ___, ___) \
  V(Move,                                A_X, reg, xeg, ___) \
  V(Swap,                                A_X, reg, xeg, ___) \
  V(Push,                                  X, xeg, ___, ___) \
  V(LoadConstant,                        A_D, reg, lit, ___) \
  V(LoadClassId,                         A_D, reg, reg, ___) \
  V(LoadClassIdTOS,                        0, ___, ___, ___) \
  V(PushConstant,                          D, lit, ___, ___) \
  V(StoreLocal,                            X, xeg, ___, ___) \
  V(PopLocal,                              X, xeg, ___, ___) \
  V(IndirectStaticCall,                  A_D, num, num, ___) \
  V(StaticCall,                          A_D, num, num, ___) \
  V(InstanceCall1,                       A_D, num, num, ___) \
  V(InstanceCall2,                       A_D, num, num, ___) \
  V(InstanceCall1Opt,                    A_D, num, num, ___) \
  V(InstanceCall2Opt,                    A_D, num, num, ___) \
  V(PushPolymorphicInstanceCall,         A_D, num, num, ___) \
  V(PushPolymorphicInstanceCallByRange,  A_D, num, num, ___) \
  V(NativeBootstrapCall,                   0, ___, ___, ___) \
  V(NativeNoScopeCall,                     0, ___, ___, ___) \
  V(NativeAutoScopeCall,                   0, ___, ___, ___) \
  V(OneByteStringFromCharCode,           A_X, reg, xeg, ___) \
  V(StringToCharCode,                    A_X, reg, xeg, ___) \
  V(AddTOS,                                0, ___, ___, ___) \
  V(SubTOS,                                0, ___, ___, ___) \
  V(MulTOS,                                0, ___, ___, ___) \
  V(BitOrTOS,                              0, ___, ___, ___) \
  V(BitAndTOS,                             0, ___, ___, ___) \
  V(EqualTOS,                              0, ___, ___, ___) \
  V(LessThanTOS,                           0, ___, ___, ___) \
  V(GreaterThanTOS,                        0, ___, ___, ___) \
  V(Add,                               A_B_C, reg, reg, reg) \
  V(Sub,                               A_B_C, reg, reg, reg) \
  V(Mul,                               A_B_C, reg, reg, reg) \
  V(Div,                               A_B_C, reg, reg, reg) \
  V(Mod,                               A_B_C, reg, reg, reg) \
  V(Shl,                               A_B_C, reg, reg, reg) \
  V(Shr,                               A_B_C, reg, reg, reg) \
  V(ShlImm,                            A_B_C, reg, reg, num) \
  V(Neg,                                 A_D, reg, reg, ___) \
  V(BitOr,                             A_B_C, reg, reg, reg) \
  V(BitAnd,                            A_B_C, reg, reg, reg) \
  V(BitXor,                            A_B_C, reg, reg, reg) \
  V(BitNot,                              A_D, reg, reg, ___) \
  V(Min,                               A_B_C, reg, reg, reg) \
  V(Max,                               A_B_C, reg, reg, reg) \
  V(WriteIntoDouble,                     A_D, reg, reg, ___) \
  V(UnboxDouble,                         A_D, reg, reg, ___) \
  V(CheckedUnboxDouble,                  A_D, reg, reg, ___) \
  V(UnboxInt32,                        A_B_C, reg, reg, num) \
  V(BoxInt32,                            A_D, reg, reg, ___) \
  V(BoxUint32,                           A_D, reg, reg, ___) \
  V(SmiToDouble,                         A_D, reg, reg, ___) \
  V(DoubleToSmi,                         A_D, reg, reg, ___) \
  V(DAdd,                              A_B_C, reg, reg, reg) \
  V(DSub,                              A_B_C, reg, reg, reg) \
  V(DMul,                              A_B_C, reg, reg, reg) \
  V(DDiv,                              A_B_C, reg, reg, reg) \
  V(DNeg,                                A_D, reg, reg, ___) \
  V(DSqrt,                               A_D, reg, reg, ___) \
  V(DMin,                              A_B_C, reg, reg, reg) \
  V(DMax,                              A_B_C, reg, reg, reg) \
  V(DCos,                                A_D, reg, reg, ___) \
  V(DSin,                                A_D, reg, reg, ___) \
  V(DPow,                              A_B_C, reg, reg, reg) \
  V(DMod,                              A_B_C, reg, reg, reg) \
  V(DTruncate,                           A_D, reg, reg, ___) \
  V(DFloor,                              A_D, reg, reg, ___) \
  V(DCeil,                               A_D, reg, reg, ___) \
  V(DoubleToFloat,                       A_D, reg, reg, ___) \
  V(FloatToDouble,                       A_D, reg, reg, ___) \
  V(DoubleIsNaN,                           A, reg, ___, ___) \
  V(DoubleIsInfinite,                      A, reg, ___, ___) \
  V(StoreStaticTOS,                        D, lit, ___, ___) \
  V(PushStatic,                            D, lit, ___, ___) \
  V(InitStaticTOS,                         0, ___, ___, ___) \
  V(IfNeStrictTOS,                         0, ___, ___, ___) \
  V(IfEqStrictTOS,                         0, ___, ___, ___) \
  V(IfNeStrictNumTOS,                      0, ___, ___, ___) \
  V(IfEqStrictNumTOS,                      0, ___, ___, ___) \
  V(IfNeStrict,                          A_D, reg, reg, ___) \
  V(IfEqStrict,                          A_D, reg, reg, ___) \
  V(IfLe,                                A_D, reg, reg, ___) \
  V(IfLt,                                A_D, reg, reg, ___) \
  V(IfGe,                                A_D, reg, reg, ___) \
  V(IfGt,                                A_D, reg, reg, ___) \
  V(IfULe,                               A_D, reg, reg, ___) \
  V(IfULt,                               A_D, reg, reg, ___) \
  V(IfUGe,                               A_D, reg, reg, ___) \
  V(IfUGt,                               A_D, reg, reg, ___) \
  V(IfDNe,                               A_D, reg, reg, ___) \
  V(IfDEq,                               A_D, reg, reg, ___) \
  V(IfDLe,                               A_D, reg, reg, ___) \
  V(IfDLt,                               A_D, reg, reg, ___) \
  V(IfDGe,                               A_D, reg, reg, ___) \
  V(IfDGt,                               A_D, reg, reg, ___) \
  V(IfNeStrictNum,                       A_D, reg, reg, ___) \
  V(IfEqStrictNum,                       A_D, reg, reg, ___) \
  V(IfEqNull,                              A, reg, ___, ___) \
  V(IfNeNull,                              A, reg, ___, ___) \
  V(CreateArrayTOS,                        0, ___, ___, ___) \
  V(CreateArrayOpt,                    A_B_C, reg, reg, reg) \
  V(Allocate,                              D, lit, ___, ___) \
  V(AllocateT,                             0, ___, ___, ___) \
  V(AllocateOpt,                         A_D, reg, lit, ___) \
  V(AllocateTOpt,                        A_D, reg, lit, ___) \
  V(StoreIndexedTOS,                       0, ___, ___, ___) \
  V(StoreIndexed,                      A_B_C, reg, reg, reg) \
  V(StoreIndexedUint8,                 A_B_C, reg, reg, reg) \
  V(StoreIndexedExternalUint8,         A_B_C, reg, reg, reg) \
  V(StoreIndexedOneByteString,         A_B_C, reg, reg, reg) \
  V(StoreIndexedUint32,                A_B_C, reg, reg, reg) \
  V(StoreIndexedFloat32,               A_B_C, reg, reg, reg) \
  V(StoreIndexed4Float32,              A_B_C, reg, reg, reg) \
  V(StoreIndexedFloat64,               A_B_C, reg, reg, reg) \
  V(StoreIndexed8Float64,              A_B_C, reg, reg, reg) \
  V(LoadIndexed,                       A_B_C, reg, reg, reg) \
  V(LoadIndexedUint8,                  A_B_C, reg, reg, reg) \
  V(LoadIndexedInt8,                   A_B_C, reg, reg, reg) \
  V(LoadIndexedInt32,                  A_B_C, reg, reg, reg) \
  V(LoadIndexedUint32,                 A_B_C, reg, reg, reg) \
  V(LoadIndexedExternalUint8,          A_B_C, reg, reg, reg) \
  V(LoadIndexedExternalInt8,           A_B_C, reg, reg, reg) \
  V(LoadIndexedFloat32,                A_B_C, reg, reg, reg) \
  V(LoadIndexed4Float32,               A_B_C, reg, reg, reg) \
  V(LoadIndexedFloat64,                A_B_C, reg, reg, reg) \
  V(LoadIndexed8Float64,               A_B_C, reg, reg, reg) \
  V(LoadIndexedOneByteString,          A_B_C, reg, reg, reg) \
  V(LoadIndexedTwoByteString,          A_B_C, reg, reg, reg) \
  V(StoreField,                        A_B_C, reg, num, reg) \
  V(StoreFieldExt,                       A_D, reg, reg, ___) \
  V(StoreFieldTOS,                         D, num, ___, ___) \
  V(LoadField,                         A_B_C, reg, reg, num) \
  V(LoadFieldExt,                        A_D, reg, reg, ___) \
  V(LoadUntagged,                      A_B_C, reg, reg, num) \
  V(LoadFieldTOS,                          D, num, ___, ___) \
  V(BooleanNegateTOS,                      0, ___, ___, ___) \
  V(BooleanNegate,                       A_D, reg, reg, ___) \
  V(Throw,                                 A, num, ___, ___) \
  V(Entry,                             A_B_C, num, num, num) \
  V(EntryOptional,                     A_B_C, num, num, num) \
  V(EntryOptimized,                      A_D, num, num, ___) \
  V(Frame,                                 D, num, ___, ___) \
  V(SetFrame,                              A, num, ___, num) \
  V(AllocateContext,                       D, num, ___, ___) \
  V(AllocateUninitializedContext,        A_D, reg, num, ___) \
  V(CloneContext,                          0, ___, ___, ___) \
  V(MoveSpecial,                         A_D, reg, num, ___) \
  V(InstantiateType,                       D, lit, ___, ___) \
  V(InstantiateTypeArgumentsTOS,         A_D, num, lit, ___) \
  V(InstanceOf,                            0, ___, ___, ___) \
  V(BadTypeError,                          0, ___, ___, ___) \
  V(AssertAssignable,                    A_D, num, lit, ___) \
  V(AssertBoolean,                         A, num, ___, ___) \
  V(TestSmi,                             A_D, reg, reg, ___) \
  V(TestCids,                            A_D, reg, num, ___) \
  V(CheckSmi,                              A, reg, ___, ___) \
  V(CheckEitherNonSmi,                   A_D, reg, reg, ___) \
  V(CheckClassId,                        A_D, reg, num, ___) \
  V(CheckClassIdRange,                   A_D, reg, num, ___) \
  V(CheckBitTest,                        A_D, reg, num, ___) \
  V(CheckCids,                         A_B_C, reg, num, num) \
  V(CheckCidsByRange,                  A_B_C, reg, num, num) \
  V(CheckStack,                            0, ___, ___, ___) \
  V(CheckStackAlwaysExit,                  0, ___, ___, ___) \
  V(DebugStep,                             0, ___, ___, ___) \
  V(DebugBreak,                            A, num, ___, ___) \
  V(Deopt,                               A_D, num, num, ___) \
  V(DeoptRewind,                           0, ___, ___, ___)

// clang-format on

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

  static Instr Encode(Opcode op) { return op; }

  DART_FORCE_INLINE static uint8_t DecodeA(Instr bc) {
    return (bc >> kAShift) & kAMask;
  }

  DART_FORCE_INLINE static uint16_t DecodeD(Instr bc) {
    return (bc >> kDShift) & kDMask;
  }

  DART_FORCE_INLINE static Opcode DecodeOpcode(Instr bc) {
    return static_cast<Opcode>(bc & 0xFF);
  }

  DART_FORCE_INLINE static bool IsCallOpcode(Instr instr) {
    switch (DecodeOpcode(instr)) {
      case Bytecode::kStaticCall:
      case Bytecode::kIndirectStaticCall:
      case Bytecode::kInstanceCall1:
      case Bytecode::kInstanceCall2:
      case Bytecode::kInstanceCall1Opt:
      case Bytecode::kInstanceCall2Opt:
      case Bytecode::kDebugBreak:
        return true;

      default:
        return false;
    }
  }

  DART_FORCE_INLINE static bool IsFastSmiOpcode(Instr instr) {
    switch (DecodeOpcode(instr)) {
      case Bytecode::kAddTOS:
      case Bytecode::kSubTOS:
      case Bytecode::kMulTOS:
      case Bytecode::kBitOrTOS:
      case Bytecode::kBitAndTOS:
      case Bytecode::kEqualTOS:
      case Bytecode::kLessThanTOS:
      case Bytecode::kGreaterThanTOS:
        return true;

      default:
        return false;
    }
  }

  DART_FORCE_INLINE static uint8_t DecodeArgc(Instr call) {
    ASSERT(IsCallOpcode(call));
    return (call >> 8) & 0xFF;
  }

  static Instr At(uword pc) { return *reinterpret_cast<Instr*>(pc); }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Bytecode);
};

// Various dummy declarations to make shared code compile.
// TODO(vegorov) we need to prune away as much dead code as possible instead
// of just making it compile.
typedef int16_t Register;

const int16_t FPREG = 0;
const int16_t SPREG = 1;
#if defined(ARCH_IS_64_BIT)
const intptr_t kNumberOfCpuRegisters = 64;
#else
const intptr_t kNumberOfCpuRegisters = 32;
#endif
const intptr_t kDartAvailableCpuRegs = -1;
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

// After a comparison, the condition NEXT_IS_TRUE means the following
// instruction is executed if the comparison is true and skipped over overwise.
// Condition NEXT_IS_FALSE means the following instruction is executed if the
// comparison is false and skipped over otherwise.
enum Condition { NEXT_IS_TRUE, NEXT_IS_FALSE, INVALID_CONDITION };

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_DBC_H_
