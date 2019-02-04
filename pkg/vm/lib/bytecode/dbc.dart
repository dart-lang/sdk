// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart kernel bytecode instructions (described in runtime/vm/constants_kbc.h).

library vm.bytecode.dbc;

/// Version of stable bytecode format, produced by default.
/// Before bumping stable bytecode version format, make sure that
/// all users have switched to a VM which is able to consume next
/// version of bytecode.
const int stableBytecodeFormatVersion = 1;

/// Version of bleeding edge bytecode format.
/// Produced by bytecode generator when --use-future-bytecode-format
/// option is enabled.
/// Should match kMaxSupportedBytecodeFormatVersion in
/// runtime/vm/constants_kbc.h.
const int futureBytecodeFormatVersion = stableBytecodeFormatVersion + 1;

/// Alignment of bytecode instructions.
const int bytecodeInstructionsAlignment = 4;

enum Opcode {
  kTrap,

  // Prologue and stack management.
  kEntry,
  kEntryFixed,
  kEntryOptional,
  kLoadConstant,
  kFrame,
  kCheckFunctionTypeArgs,
  kCheckStack,

  // Object allocation.
  kAllocate,
  kAllocateT,
  kCreateArrayTOS,

  // Context allocation and access.
  kAllocateContext,
  kCloneContext,
  kLoadContextParent,
  kStoreContextParent,
  kLoadContextVar,
  kStoreContextVar,

  // Constants.
  kPushConstant,
  kPushNull,
  kPushTrue,
  kPushFalse,
  kPushInt,

  // Locals and expression stack.
  kDrop1,
  kPush,
  kPopLocal,
  kStoreLocal,

  // Instance fields and arrays.
  kLoadFieldTOS,
  kStoreFieldTOS,
  kStoreIndexedTOS,

  // Static fields.
  kPushStatic,
  kStoreStaticTOS,

  // Jumps.
  kJump,
  kJumpIfNoAsserts,
  kJumpIfNotZeroTypeArgs,
  kJumpIfEqStrict,
  kJumpIfNeStrict,
  kJumpIfTrue,
  kJumpIfFalse,
  kJumpIfNull,
  kJumpIfNotNull,

  // Calls.
  kIndirectStaticCall,
  kInterfaceCall,
  kDynamicCall,
  kNativeCall,
  kReturnTOS,

  // Types and type checks.
  kAssertAssignable,
  kAssertBoolean,
  kAssertSubtype,
  kLoadTypeArgumentsField,
  kInstantiateType,
  kInstantiateTypeArgumentsTOS,

  // Exception handling.
  kThrow,
  kMoveSpecial,
  kSetFrame,

  // Bool operations.
  kBooleanNegateTOS,

  // Null operations.
  kEqualsNull,

  // Int operations.
  kNegateInt,
  kAddInt,
  kSubInt,
  kMulInt,
  kTruncDivInt,
  kModInt,
  kBitAndInt,
  kBitOrInt,
  kBitXorInt,
  kShlInt,
  kShrInt,
  kCompareIntEq,
  kCompareIntGt,
  kCompareIntLt,
  kCompareIntGe,
  kCompareIntLe,
}

enum Encoding {
  k0,
  kA,
  kAD,
  kAX,
  kD,
  kX,
  kABC,
  kABY,
  kT,
}

enum Operand {
  none, // ignored / non-existent operand
  imm, // immediate operand
  lit, // constant literal from object pool
  reg, // register (unsigned FP relative local)
  xeg, // x-register (signed FP relative local)
  tgt, // jump target relative to the PC of the current instruction
  spe, // SpecialIndex
}

class Format {
  final Encoding encoding;
  final List<Operand> operands;
  const Format(this.encoding, this.operands);
}

const Map<Opcode, Format> BytecodeFormats = const {
  Opcode.kTrap: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kEntry: const Format(
      Encoding.kD, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kEntryFixed: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kEntryOptional: const Format(
      Encoding.kABC, const [Operand.imm, Operand.imm, Operand.imm]),
  Opcode.kLoadConstant: const Format(
      Encoding.kAD, const [Operand.reg, Operand.lit, Operand.none]),
  Opcode.kFrame: const Format(
      Encoding.kD, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kCheckFunctionTypeArgs: const Format(
      Encoding.kAD, const [Operand.imm, Operand.reg, Operand.none]),
  Opcode.kCheckStack: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kAllocate: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kAllocateT: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCreateArrayTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAllocateContext: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kCloneContext: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kLoadContextParent: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kStoreContextParent: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kLoadContextVar: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kStoreContextVar: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kPushConstant: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kPushNull: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kPushTrue: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kPushFalse: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kPushInt: const Format(
      Encoding.kX, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kDrop1: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kPush: const Format(
      Encoding.kX, const [Operand.xeg, Operand.none, Operand.none]),
  Opcode.kPopLocal: const Format(
      Encoding.kX, const [Operand.xeg, Operand.none, Operand.none]),
  Opcode.kStoreLocal: const Format(
      Encoding.kX, const [Operand.xeg, Operand.none, Operand.none]),
  Opcode.kLoadFieldTOS: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kStoreFieldTOS: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kStoreIndexedTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kPushStatic: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kStoreStaticTOS: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kJump: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfNoAsserts: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfNotZeroTypeArgs: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfEqStrict: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfNeStrict: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfTrue: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfFalse: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfNull: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kJumpIfNotNull: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kIndirectStaticCall: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kInterfaceCall: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kDynamicCall: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kNativeCall: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kReturnTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAssertAssignable: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kAssertBoolean: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kAssertSubtype: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kLoadTypeArgumentsField: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kInstantiateType: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kInstantiateTypeArgumentsTOS: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kThrow: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kMoveSpecial: const Format(
      Encoding.kAX, const [Operand.spe, Operand.xeg, Operand.none]),
  Opcode.kSetFrame: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kBooleanNegateTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kEqualsNull: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kNegateInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAddInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kSubInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kMulInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kTruncDivInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kModInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBitAndInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBitOrInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBitXorInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kShlInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kShrInt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCompareIntEq: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCompareIntGt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCompareIntLt: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCompareIntGe: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCompareIntLe: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
};

// Should match constant in runtime/vm/stack_frame_dbc.h.
const int kParamEndSlotFromFp = 4;

enum SpecialIndex {
  exception,
  stackTrace,
}

bool isJump(Opcode opcode) => BytecodeFormats[opcode].encoding == Encoding.kT;

bool isThrow(Opcode opcode) => opcode == Opcode.kThrow;

bool isCall(Opcode opcode) {
  switch (opcode) {
    case Opcode.kIndirectStaticCall:
    case Opcode.kInterfaceCall:
    case Opcode.kDynamicCall:
    case Opcode.kNativeCall:
      return true;
    default:
      return false;
  }
}

bool isReturn(Opcode opcode) => opcode == Opcode.kReturnTOS;

bool isControlFlow(Opcode opcode) =>
    isJump(opcode) || isThrow(opcode) || isCall(opcode) || isReturn(opcode);

bool isPush(Opcode opcode) {
  switch (opcode) {
    case Opcode.kPush:
    case Opcode.kPushConstant:
    case Opcode.kPushNull:
    case Opcode.kPushTrue:
    case Opcode.kPushFalse:
    case Opcode.kPushInt:
    case Opcode.kPushStatic:
      return true;
    default:
      return false;
  }
}

// Bytecode instructions reference constant pool indices using
// unsigned 16-bit operands.
const int constantPoolIndexLimit = 1 << 16;

// Local variables are referenced using 16-bit signed operands.
const int localVariableIndexLimit = 1 << 15;

// Captured variables are referenced using 16-bit unsigned operands.
const int capturedVariableIndexLimit = 1 << 16;

// Context IDs are referenced using 8-bit unsigned operands.
const int contextIdLimit = 1 << 8;

// Base class for exceptions thrown when certain limit of bytecode
// format is exceeded.
abstract class BytecodeLimitExceededException {}
