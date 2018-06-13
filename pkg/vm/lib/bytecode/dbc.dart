// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.dbc;

// List of changes from original DBC (described in runtime/vm/constants_dbc.h):
//
// 1. StoreFieldTOS, LoadFieldTOS instructions:
//    D = index of constant pool entry with FieldOffset,
//    TypeArgumentsFieldOffset or ConstantContextOffset tags
//    (instead of field offset in words).
//
// 2. EntryOptional instruction is revived in order to re-shuffle optional
//    parameters. This DBC instruction was removed at
//    https://github.com/dart-lang/sdk/commit/cf1de7d46cd88e204380e8f96a993439be56b24c
//
// 3. NativeCall instruction is modified to have 'D' format and take 1 argument:
//    D = index of NativeEntry constant pool entry
//

enum Opcode {
  kTrap,
  kNop,
  kCompile,
  kHotCheck,
  kIntrinsic,
  kDrop1,
  kDropR,
  kDrop,
  kJump,
  kReturn,
  kReturnTOS,
  kMove,
  kSwap,
  kPush,
  kLoadConstant,
  kLoadClassId,
  kLoadClassIdTOS,
  kPushConstant,
  kStoreLocal,
  kPopLocal,
  kIndirectStaticCall,
  kStaticCall,
  kInstanceCall1,
  kInstanceCall2,
  kInstanceCall1Opt,
  kInstanceCall2Opt,
  kPushPolymorphicInstanceCall,
  kPushPolymorphicInstanceCallByRange,
  kNativeCall,
  kOneByteStringFromCharCode,
  kStringToCharCode,
  kAddTOS,
  kSubTOS,
  kMulTOS,
  kBitOrTOS,
  kBitAndTOS,
  kEqualTOS,
  kLessThanTOS,
  kGreaterThanTOS,
  kSmiAddTOS,
  kSmiSubTOS,
  kSmiMulTOS,
  kSmiBitAndTOS,
  kAdd,
  kSub,
  kMul,
  kDiv,
  kMod,
  kShl,
  kShr,
  kShlImm,
  kNeg,
  kBitOr,
  kBitAnd,
  kBitXor,
  kBitNot,
  kMin,
  kMax,
  kWriteIntoDouble,
  kUnboxDouble,
  kCheckedUnboxDouble,
  kUnboxInt32,
  kBoxInt32,
  kBoxUint32,
  kSmiToDouble,
  kDoubleToSmi,
  kDAdd,
  kDSub,
  kDMul,
  kDDiv,
  kDNeg,
  kDSqrt,
  kDMin,
  kDMax,
  kDCos,
  kDSin,
  kDPow,
  kDMod,
  kDTruncate,
  kDFloor,
  kDCeil,
  kDoubleToFloat,
  kFloatToDouble,
  kDoubleIsNaN,
  kDoubleIsInfinite,
  kStoreStaticTOS,
  kPushStatic,
  kInitStaticTOS,
  kIfNeStrictTOS,
  kIfEqStrictTOS,
  kIfNeStrictNumTOS,
  kIfEqStrictNumTOS,
  kIfSmiLtTOS,
  kIfSmiLeTOS,
  kIfSmiGeTOS,
  kIfSmiGtTOS,
  kIfNeStrict,
  kIfEqStrict,
  kIfLe,
  kIfLt,
  kIfGe,
  kIfGt,
  kIfULe,
  kIfULt,
  kIfUGe,
  kIfUGt,
  kIfDNe,
  kIfDEq,
  kIfDLe,
  kIfDLt,
  kIfDGe,
  kIfDGt,
  kIfNeStrictNum,
  kIfEqStrictNum,
  kIfEqNull,
  kIfNeNull,
  kCreateArrayTOS,
  kCreateArrayOpt,
  kAllocate,
  kAllocateT,
  kAllocateOpt,
  kAllocateTOpt,
  kStoreIndexedTOS,
  kStoreIndexed,
  kStoreIndexedUint8,
  kStoreIndexedExternalUint8,
  kStoreIndexedOneByteString,
  kStoreIndexedUint32,
  kStoreIndexedFloat32,
  kStoreIndexed4Float32,
  kStoreIndexedFloat64,
  kStoreIndexed8Float64,
  kNoSuchMethod,
  kTailCall,
  kTailCallOpt,
  kLoadArgDescriptor,
  kLoadArgDescriptorOpt,
  kLoadFpRelativeSlot,
  kLoadFpRelativeSlotOpt,
  kStoreFpRelativeSlot,
  kStoreFpRelativeSlotOpt,
  kLoadIndexedTOS,
  kLoadIndexed,
  kLoadIndexedUint8,
  kLoadIndexedInt8,
  kLoadIndexedInt32,
  kLoadIndexedUint32,
  kLoadIndexedExternalUint8,
  kLoadIndexedExternalInt8,
  kLoadIndexedFloat32,
  kLoadIndexed4Float32,
  kLoadIndexedFloat64,
  kLoadIndexed8Float64,
  kLoadIndexedOneByteString,
  kLoadIndexedTwoByteString,
  kStoreField,
  kStoreFieldExt,
  kStoreFieldTOS,
  kLoadField,
  kLoadFieldExt,
  kLoadUntagged,
  kLoadFieldTOS,
  kBooleanNegateTOS,
  kBooleanNegate,
  kThrow,
  kEntry,
  kEntryOptional,
  kEntryOptimized,
  kFrame,
  kSetFrame,
  kAllocateContext,
  kAllocateUninitializedContext,
  kCloneContext,
  kMoveSpecial,
  kInstantiateType,
  kInstantiateTypeArgumentsTOS,
  kInstanceOf,
  kBadTypeError,
  kAssertAssignable,
  kAssertSubtype,
  kAssertBoolean,
  kTestSmi,
  kTestCids,
  kCheckSmi,
  kCheckEitherNonSmi,
  kCheckClassId,
  kCheckClassIdRange,
  kCheckBitTest,
  kCheckCids,
  kCheckCidsByRange,
  kCheckStack,
  kCheckStackAlwaysExit,
  kCheckFunctionTypeArgs,
  kDebugStep,
  kDebugBreak,
  kDeopt,
  kDeoptRewind,
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
  Opcode.kNop: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kCompile: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kHotCheck: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kIntrinsic: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kDrop1: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kDropR: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kDrop: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kJump: const Format(
      Encoding.kT, const [Operand.tgt, Operand.none, Operand.none]),
  Opcode.kReturn: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kReturnTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kMove: const Format(
      Encoding.kAX, const [Operand.reg, Operand.xeg, Operand.none]),
  Opcode.kSwap: const Format(
      Encoding.kAX, const [Operand.reg, Operand.xeg, Operand.none]),
  Opcode.kPush: const Format(
      Encoding.kX, const [Operand.xeg, Operand.none, Operand.none]),
  Opcode.kLoadConstant: const Format(
      Encoding.kAD, const [Operand.reg, Operand.lit, Operand.none]),
  Opcode.kLoadClassId: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kLoadClassIdTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kPushConstant: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kStoreLocal: const Format(
      Encoding.kX, const [Operand.xeg, Operand.none, Operand.none]),
  Opcode.kPopLocal: const Format(
      Encoding.kX, const [Operand.xeg, Operand.none, Operand.none]),
  Opcode.kIndirectStaticCall: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kStaticCall: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kInstanceCall1: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kInstanceCall2: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kInstanceCall1Opt: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kInstanceCall2Opt: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kPushPolymorphicInstanceCall: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kPushPolymorphicInstanceCallByRange: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kNativeCall: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kOneByteStringFromCharCode: const Format(
      Encoding.kAX, const [Operand.reg, Operand.xeg, Operand.none]),
  Opcode.kStringToCharCode: const Format(
      Encoding.kAX, const [Operand.reg, Operand.xeg, Operand.none]),
  Opcode.kAddTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kSubTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kMulTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBitOrTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBitAndTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kEqualTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kLessThanTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kGreaterThanTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kSmiAddTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kSmiSubTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kSmiMulTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kSmiBitAndTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAdd: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kSub: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kMul: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDiv: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kMod: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kShl: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kShr: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kShlImm: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.imm]),
  Opcode.kNeg: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kBitOr: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kBitAnd: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kBitXor: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kBitNot: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kMin: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kMax: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kWriteIntoDouble: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kUnboxDouble: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kCheckedUnboxDouble: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kUnboxInt32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.imm]),
  Opcode.kBoxInt32: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kBoxUint32: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kSmiToDouble: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDoubleToSmi: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDAdd: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDSub: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDMul: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDDiv: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDNeg: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDSqrt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDMin: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDMax: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDCos: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDSin: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDPow: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDMod: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kDTruncate: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDFloor: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDCeil: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDoubleToFloat: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kFloatToDouble: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kDoubleIsNaN: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kDoubleIsInfinite: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kStoreStaticTOS: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kPushStatic: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kInitStaticTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfNeStrictTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfEqStrictTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfNeStrictNumTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfEqStrictNumTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfSmiLtTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfSmiLeTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfSmiGeTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfSmiGtTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kIfNeStrict: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfEqStrict: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfLe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfLt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfGe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfGt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfULe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfULt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfUGe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfUGt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfDNe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfDEq: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfDLe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfDLt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfDGe: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfDGt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfNeStrictNum: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfEqStrictNum: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kIfEqNull: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kIfNeNull: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kCreateArrayTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCreateArrayOpt: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kAllocate: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kAllocateT: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAllocateOpt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.lit, Operand.none]),
  Opcode.kAllocateTOpt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.lit, Operand.none]),
  Opcode.kStoreIndexedTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kStoreIndexed: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexedUint8: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexedExternalUint8: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexedOneByteString: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexedUint32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexedFloat32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexed4Float32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexedFloat64: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreIndexed8Float64: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kNoSuchMethod: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kTailCall: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kTailCallOpt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kLoadArgDescriptor: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kLoadArgDescriptorOpt: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kLoadFpRelativeSlot: const Format(
      Encoding.kX, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kLoadFpRelativeSlotOpt: const Format(
      Encoding.kABY, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreFpRelativeSlot: const Format(
      Encoding.kX, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kStoreFpRelativeSlotOpt: const Format(
      Encoding.kABY, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kLoadIndexed: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedUint8: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedInt8: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedInt32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedUint32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedExternalUint8: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedExternalInt8: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedFloat32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexed4Float32: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedFloat64: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexed8Float64: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedOneByteString: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kLoadIndexedTwoByteString: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.reg]),
  Opcode.kStoreField: const Format(
      Encoding.kABC, const [Operand.reg, Operand.imm, Operand.reg]),
  Opcode.kStoreFieldExt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kStoreFieldTOS: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kLoadField: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.imm]),
  Opcode.kLoadFieldExt: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kLoadUntagged: const Format(
      Encoding.kABC, const [Operand.reg, Operand.reg, Operand.imm]),
  Opcode.kLoadFieldTOS: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kBooleanNegateTOS: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBooleanNegate: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kThrow: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kEntry: const Format(
      Encoding.kD, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kEntryOptimized: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kFrame: const Format(
      Encoding.kD, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kSetFrame: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kAllocateContext: const Format(
      Encoding.kD, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kAllocateUninitializedContext: const Format(
      Encoding.kAD, const [Operand.reg, Operand.imm, Operand.none]),
  Opcode.kCloneContext: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kMoveSpecial: const Format(
      Encoding.kAD, const [Operand.reg, Operand.spe, Operand.none]),
  Opcode.kInstantiateType: const Format(
      Encoding.kD, const [Operand.lit, Operand.none, Operand.none]),
  Opcode.kInstantiateTypeArgumentsTOS: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kInstanceOf: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kBadTypeError: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAssertAssignable: const Format(
      Encoding.kAD, const [Operand.imm, Operand.lit, Operand.none]),
  Opcode.kAssertSubtype: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kAssertBoolean: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kTestSmi: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kTestCids: const Format(
      Encoding.kAD, const [Operand.reg, Operand.imm, Operand.none]),
  Opcode.kCheckSmi: const Format(
      Encoding.kA, const [Operand.reg, Operand.none, Operand.none]),
  Opcode.kCheckEitherNonSmi: const Format(
      Encoding.kAD, const [Operand.reg, Operand.reg, Operand.none]),
  Opcode.kCheckClassId: const Format(
      Encoding.kAD, const [Operand.reg, Operand.imm, Operand.none]),
  Opcode.kCheckClassIdRange: const Format(
      Encoding.kAD, const [Operand.reg, Operand.imm, Operand.none]),
  Opcode.kCheckBitTest: const Format(
      Encoding.kAD, const [Operand.reg, Operand.imm, Operand.none]),
  Opcode.kCheckCids: const Format(
      Encoding.kABC, const [Operand.reg, Operand.imm, Operand.imm]),
  Opcode.kCheckCidsByRange: const Format(
      Encoding.kABC, const [Operand.reg, Operand.imm, Operand.imm]),
  Opcode.kCheckStack: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCheckStackAlwaysExit: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kCheckFunctionTypeArgs: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kDebugStep: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kDebugBreak: const Format(
      Encoding.kA, const [Operand.imm, Operand.none, Operand.none]),
  Opcode.kDeopt: const Format(
      Encoding.kAD, const [Operand.imm, Operand.imm, Operand.none]),
  Opcode.kDeoptRewind: const Format(
      Encoding.k0, const [Operand.none, Operand.none, Operand.none]),
  Opcode.kEntryOptional: const Format(
      Encoding.kABC, const [Operand.imm, Operand.imm, Operand.imm]),
};

// Should match constant in runtime/vm/stack_frame_dbc.h.
const int kParamEndSlotFromFp = 4;

enum SpecialIndex {
  exception,
  stackTrace,
}
