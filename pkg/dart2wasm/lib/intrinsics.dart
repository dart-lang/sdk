// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'abi.dart' show kWasmAbiEnumIndex;
import 'class_info.dart';
import 'code_generator.dart';
import 'dynamic_forwarders.dart';
import 'dynamic_modules.dart';
import 'translator.dart';
import 'types.dart';
import 'util.dart';

typedef CodeGenCallback = void Function(AstCodeGenerator);

typedef InlineCodeGenCallback = void Function(
    AstCodeGenerator, Expression receiver);

enum MemberIntrinsic {
  objectEquals('dart:core', 'Object', '=='),
  objectRuntimeType('dart:core', 'Object', 'runtimeType'),
  identical('dart:core', null, 'identical'),
  closureRuntimeType('dart:core', '_Closure', '_getClosureRuntimeType'),
  identityHashCode('dart:core', null, 'identityHashCode'),
  typeArguments('dart:core', '', ''),
  intAdd('dart:_boxed_int', 'BoxedInt', '+'),
  intSub('dart:_boxed_int', 'BoxedInt', '-'),
  intMul('dart:_boxed_int', 'BoxedInt', '*'),
  intAnd('dart:_boxed_int', 'BoxedInt', '&'),
  intOr('dart:_boxed_int', 'BoxedInt', '|'),
  intXor('dart:_boxed_int', 'BoxedInt', '^'),
  intLt('dart:_boxed_int', 'BoxedInt', '<'),
  intGt('dart:_boxed_int', 'BoxedInt', '>'),
  intLe('dart:_boxed_int', 'BoxedInt', '<='),
  intGe('dart:_boxed_int', 'BoxedInt', '>='),
  intNeg('dart:_boxed_int', 'BoxedInt', 'unary-'),
  intInv('dart:_boxed_int', 'BoxedInt', '~'),
  intToDouble('dart:_boxed_int', 'BoxedInt', 'toDouble'),
  doubleNeg('dart:_boxed_double', 'BoxedDouble', 'unary-'),
  doubleFloorToDouble('dart:_boxed_double', 'BoxedDouble', 'floorToDouble'),
  doubleCeilToDouble('dart:_boxed_double', 'BoxedDouble', 'ceilToDouble'),
  doubleTruncateToDouble(
      'dart:_boxed_double', 'BoxedDouble', 'truncateToDouble'),
  isInstantiationClosure('dart:core', '_Closure', '_isInstantiationClosure'),
  instantiatedClosure('dart:core', '_Closure', '_instantiatedClosure'),
  instantiationClosureTypeHash(
      'dart:core', '_Closure', '_instantiationClosureTypeHash'),
  instantiationClosureTypeEquals(
      'dart:core', '_Closure', '_instantiationClosureTypeEquals'),
  isInstanceTearOff('dart:core', '_Closure', '_isInstanceTearOff'),
  instanceTearOffReceiver('dart:core', '_Closure', '_instanceTearOffReceiver'),
  vtable('dart:core', '_Closure', '_vtable'),
  functionApply('dart:core', 'Function', 'apply'),
  errorThrow('dart:core', 'Error', '_throw'),
  nullRef('dart:_wasm', 'WasmExternRef', 'nullRef');

  final String library;
  final String? cls;
  final String name;

  const MemberIntrinsic(this.library, this.cls, this.name);

  static Map<String, Map<String?, Map<String, MemberIntrinsic>>>? _lookup;

  static Map<String, Map<String?, Map<String, MemberIntrinsic>>>
      _populateLookup() {
    final result = <String, Map<String?, Map<String, MemberIntrinsic>>>{};
    for (var intrinsic in MemberIntrinsic.values) {
      ((result[intrinsic.library] ??= {})[intrinsic.cls] ??=
          {})[intrinsic.name] = intrinsic;
    }
    return result;
  }

  static MemberIntrinsic? fromProcedure(CoreTypes coreTypes, Procedure member) {
    if (member.name.text == '_typeArguments' &&
        hasPragma(coreTypes, member, 'wasm:intrinsic')) {
      return MemberIntrinsic.typeArguments;
    }
    final intrinsic = (_lookup ??=
            _populateLookup())['${member.enclosingLibrary.importUri}']
        ?[member.enclosingClass?.name]?[member.name.text];
    assert(intrinsic == null || hasPragma(coreTypes, member, 'wasm:intrinsic'));
    return intrinsic;
  }
}

enum StaticIntrinsic {
  wasmArrayNew('dart:_wasm', 'WasmArray', ''),
  wasmArrayFilled('dart:_wasm', 'WasmArray', 'filled'),
  wasmArrayIndex('dart:_wasm', null, 'WasmArrayExt|[]'),
  wasmArrayIndexSet('dart:_wasm', null, 'WasmArrayExt|[]='),
  wasmArrayCopy('dart:_wasm', null, 'WasmArrayExt|copy'),
  wasmArrayFill('dart:_wasm', null, 'WasmArrayExt|fill'),
  wasmArrayClone('dart:_wasm', null, 'WasmArrayExt|clone'),
  immutableWasmArrayNew('dart:_wasm', 'ImmutableWasmArray', ''),
  immutableWasmArrayFilled('dart:_wasm', 'ImmutableWasmArray', 'filled'),
  immutableWasmArrayIndex('dart:_wasm', null, 'ImmutableWasmArrayExt|[]'),
  i64ArrayExtRead('dart:_wasm', null, 'I64ArrayExt|read'),
  f32ArrayExtRead('dart:_wasm', null, 'F32ArrayExt|read'),
  f64ArrayExtRead('dart:_wasm', null, 'F64ArrayExt|read'),
  immutableI64ArrayExtRead('dart:_wasm', null, 'ImmutableI64ArrayExt|read'),
  immutableF32ArrayExtRead('dart:_wasm', null, 'ImmutableF32ArrayExt|read'),
  immutableF64ArrayExtRead('dart:_wasm', null, 'ImmutableF64ArrayExt|read'),
  i8ArrayExtReadSigned('dart:_wasm', null, 'I8ArrayExt|readSigned'),
  i16ArrayExtReadSigned('dart:_wasm', null, 'I16ArrayExt|readSigned'),
  i32ArrayExtReadSigned('dart:_wasm', null, 'I32ArrayExt|readSigned'),
  immutableI8ArrayExtReadSigned(
      'dart:_wasm', null, 'ImmutableI8ArrayExt|readSigned'),
  immutableI16ArrayExtReadSigned(
      'dart:_wasm', null, 'ImmutableI16ArrayExt|readSigned'),
  immutableI32ArrayExtReadSigned(
      'dart:_wasm', null, 'ImmutableI32ArrayExt|readSigned'),
  i8ArrayExtReadUnsigned('dart:_wasm', null, 'I8ArrayExt|readUnsigned'),
  i16ArrayExtReadUnsigned('dart:_wasm', null, 'I16ArrayExt|readUnsigned'),
  i32ArrayExtReadUnsigned('dart:_wasm', null, 'I32ArrayExt|readUnsigned'),
  immutableI8ArrayExtReadUnsigned(
      'dart:_wasm', null, 'ImmutableI8ArrayExt|readUnsigned'),
  immutableI16ArrayExtReadUnsigned(
      'dart:_wasm', null, 'ImmutableI16ArrayExt|readUnsigned'),
  immutableI32ArrayExtReadUnsigned(
      'dart:_wasm', null, 'ImmutableI32ArrayExt|readUnsigned'),
  i8ArrayExtWrite('dart:_wasm', null, 'I8ArrayExt|write'),
  i16ArrayExtWrite('dart:_wasm', null, 'I16ArrayExt|write'),
  i32ArrayExtWrite('dart:_wasm', null, 'I32ArrayExt|write'),
  i64ArrayExtWrite('dart:_wasm', null, 'I64ArrayExt|write'),
  f32ArrayExtWrite('dart:_wasm', null, 'F32ArrayExt|write'),
  f64ArrayExtWrite('dart:_wasm', null, 'F64ArrayExt|write'),
  wasmFunctionFromFuncRef('dart:_wasm', 'WasmFunction', 'fromFuncRef'),
  wasmFunctionFromFunction('dart:_wasm', 'WasmFunction', 'fromFunction'),
  wasmI32FromInt('dart:_wasm', 'WasmI32', 'fromInt'),
  wasmI32Int8FromInt('dart:_wasm', 'WasmI32', 'int8FromInt'),
  wasmI32Uint8FromInt('dart:_wasm', 'WasmI32', 'uint8FromInt'),
  wasmI32Int16FromInt('dart:_wasm', 'WasmI32', 'int16FromInt'),
  wasmI32Uint16FromInt('dart:_wasm', 'WasmI32', 'uint16FromInt'),
  wasmI32FromBool('dart:_wasm', 'WasmI32', 'fromBool'),
  wasmI64FromInt('dart:_wasm', 'WasmI64', 'fromInt'),
  wasmF32FromDouble('dart:_wasm', 'WasmF32', 'fromDouble'),
  wasmF64FromDouble('dart:_wasm', 'WasmF64', 'fromDouble'),
  wasmI8x16Splat('dart:_wasm', null, 'WasmI8x16|constructor#splat'),
  wasmI8x16ExtractLaneS('dart:_wasm', null, 'WasmI8x16|extractLaneSigned'),
  wasmI8x16ExtractLaneU('dart:_wasm', null, 'WasmI8x16|extractLaneUnsigned'),
  wasmI8x16ReplaceLane('dart:_wasm', null, 'WasmI8x16|replaceLane'),
  wasmI16x8Splat('dart:_wasm', null, 'WasmI16x8|constructor#splat'),
  wasmI16x8ExtractLaneS('dart:_wasm', null, 'WasmI16x8|extractLaneSigned'),
  wasmI16x8ExtractLaneU('dart:_wasm', null, 'WasmI16x8|extractLaneUnsigned'),
  wasmI16x8ReplaceLane('dart:_wasm', null, 'WasmI16x8|replaceLane'),
  wasmI32x4Splat('dart:_wasm', null, 'WasmI32x4|constructor#splat'),
  wasmI32x4ExtractLane('dart:_wasm', null, 'WasmI32x4|extractLane'),
  wasmI32x4ReplaceLane('dart:_wasm', null, 'WasmI32x4|replaceLane'),
  wasmI64x2Splat('dart:_wasm', null, 'WasmI64x2|constructor#splat'),
  wasmI64x2ExtractLane('dart:_wasm', null, 'WasmI64x2|extractLane'),
  wasmI64x2ReplaceLane('dart:_wasm', null, 'WasmI64x2|replaceLane'),
  wasmF32x4Splat('dart:_wasm', null, 'WasmF32x4|constructor#splat'),
  wasmF32x4ExtractLane('dart:_wasm', null, 'WasmF32x4|extractLane'),
  wasmF32x4ReplaceLane('dart:_wasm', null, 'WasmF32x4|replaceLane'),
  wasmF64x2Splat('dart:_wasm', null, 'WasmF64x2|constructor#splat'),
  wasmF64x2ExtractLane('dart:_wasm', null, 'WasmF64x2|extractLane'),
  wasmF64x2ReplaceLane('dart:_wasm', null, 'WasmF64x2|replaceLane'),
  wasmF32x4Add('dart:_wasm', null, 'WasmF32x4|+'),
  wasmF32x4Sub('dart:_wasm', null, 'WasmF32x4|-'),
  wasmF32x4Mul('dart:_wasm', null, 'WasmF32x4|*'),
  wasmF32x4Div('dart:_wasm', null, 'WasmF32x4|/'),
  wasmF32x4Neg('dart:_wasm', null, 'WasmF32x4|unary-'),
  wasmF32x4Abs('dart:_wasm', null, 'WasmF32x4|abs'),
  wasmF32x4Sqrt('dart:_wasm', null, 'WasmF32x4|sqrt'),
  wasmF32x4Min('dart:_wasm', null, 'WasmF32x4|min'),
  wasmF32x4Max('dart:_wasm', null, 'WasmF32x4|max'),
  wasmF32x4Lt('dart:_wasm', null, 'WasmF32x4|lt'),
  wasmF32x4Le('dart:_wasm', null, 'WasmF32x4|le'),
  wasmF32x4Gt('dart:_wasm', null, 'WasmF32x4|gt'),
  wasmF32x4Ge('dart:_wasm', null, 'WasmF32x4|ge'),
  wasmF32x4Ceil('dart:_wasm', null, 'WasmF32x4|ceil'),
  wasmF32x4Floor('dart:_wasm', null, 'WasmF32x4|floor'),
  wasmF32x4Trunc('dart:_wasm', null, 'WasmF32x4|trunc'),
  wasmF32x4Nearest('dart:_wasm', null, 'WasmF32x4|nearest'),
  wasmF64x2Add('dart:_wasm', null, 'WasmF64x2|+'),
  wasmF64x2Sub('dart:_wasm', null, 'WasmF64x2|-'),
  wasmF64x2Mul('dart:_wasm', null, 'WasmF64x2|*'),
  wasmF64x2Div('dart:_wasm', null, 'WasmF64x2|/'),
  wasmF64x2Neg('dart:_wasm', null, 'WasmF64x2|unary-'),
  wasmF64x2Abs('dart:_wasm', null, 'WasmF64x2|abs'),
  wasmF64x2Sqrt('dart:_wasm', null, 'WasmF64x2|sqrt'),
  wasmF64x2Min('dart:_wasm', null, 'WasmF64x2|min'),
  wasmF64x2Max('dart:_wasm', null, 'WasmF64x2|max'),
  wasmF64x2Ceil('dart:_wasm', null, 'WasmF64x2|ceil'),
  wasmF64x2Floor('dart:_wasm', null, 'WasmF64x2|floor'),
  wasmF64x2Trunc('dart:_wasm', null, 'WasmF64x2|trunc'),
  wasmF64x2Nearest('dart:_wasm', null, 'WasmF64x2|nearest'),
  wasmF64x2Lt('dart:_wasm', null, 'WasmF64x2|lt'),
  wasmF64x2Le('dart:_wasm', null, 'WasmF64x2|le'),
  wasmF64x2Gt('dart:_wasm', null, 'WasmF64x2|gt'),
  wasmF64x2Ge('dart:_wasm', null, 'WasmF64x2|ge'),
  wasmI8x16Add('dart:_wasm', null, 'WasmI8x16|+'),
  wasmI8x16Sub('dart:_wasm', null, 'WasmI8x16|-'),
  wasmI8x16Neg('dart:_wasm', null, 'WasmI8x16|unary-'),
  wasmI16x8Add('dart:_wasm', null, 'WasmI16x8|+'),
  wasmI16x8Sub('dart:_wasm', null, 'WasmI16x8|-'),
  wasmI16x8Mul('dart:_wasm', null, 'WasmI16x8|*'),
  wasm32x4MulDotI16x8('dart:_wasm', null, 'WasmI16x8|dotProduct'),
  wasmI16x8Neg('dart:_wasm', null, 'WasmI16x8|unary-'),
  wasmI32x4Add('dart:_wasm', null, 'WasmI32x4|+'),
  wasmI32x4Sub('dart:_wasm', null, 'WasmI32x4|-'),
  wasmI32x4Mul('dart:_wasm', null, 'WasmI32x4|*'),
  wasmI32x4Neg('dart:_wasm', null, 'WasmI32x4|unary-'),
  wasmI64x2Add('dart:_wasm', null, 'WasmI64x2|+'),
  wasmI64x2Sub('dart:_wasm', null, 'WasmI64x2|-'),
  wasmI64x2Mul('dart:_wasm', null, 'WasmI64x2|*'),
  wasmI64x2Neg('dart:_wasm', null, 'WasmI64x2|unary-'),
  wasmI8x16Eq('dart:_wasm', null, 'WasmI8x16|eq'),
  wasmI16x8Eq('dart:_wasm', null, 'WasmI16x8|eq'),
  wasmI32x4Eq('dart:_wasm', null, 'WasmI32x4|eq'),
  wasmI64x2Eq('dart:_wasm', null, 'WasmI64x2|eq'),
  wasmF32x4Eq('dart:_wasm', null, 'WasmF32x4|eq'),
  wasmF64x2Eq('dart:_wasm', null, 'WasmF64x2|eq'),
  wasmV128Not('dart:_wasm', null, 'WasmV128Extension|~'),
  wasmV128And('dart:_wasm', null, 'WasmV128Extension|&'),
  wasmV128Or('dart:_wasm', null, 'WasmV128Extension||'),
  wasmV128Xor('dart:_wasm', null, 'WasmV128Extension|^'),
  wasmV128AndNot('dart:_wasm', null, 'WasmV128Extension|andNot'),
  wasmV128BitSelect('dart:_wasm', null, 'WasmV128Extension|bitSelect'),
  wasmAnyRefFromObject('dart:_wasm', 'WasmAnyRef', 'fromObject'),
  wasmFuncRefFromWasmFunction('dart:_wasm', 'WasmFuncRef', 'fromWasmFunction'),
  wasmEqRefFromObject('dart:_wasm', 'WasmEqRef', 'fromObject'),
  wasmStructRefFromObject('dart:_wasm', 'WasmStructRef', 'fromObject'),
  externalizeNonNullable('dart:_wasm', null, '_externalizeNonNullable'),
  externalizeNullable('dart:_wasm', null, '_externalizeNullable'),
  internalizeNonNullable('dart:_wasm', null, '_internalizeNonNullable'),
  internalizeNullable('dart:_wasm', null, '_internalizeNullable'),
  wasmExternRefIsNull('dart:_wasm', null, '_wasmExternRefIsNull'),
  isSubClassOf('dart:_wasm', null, 'isSubClassOf'),
  identical('dart:core', null, 'identical'),
  isObjectClassId('dart:core', null, '_isObjectClassId'),
  isClosureClassId('dart:core', null, '_isClosureClassId'),
  isRecordClassId('dart:core', null, '_isRecordClassId'),
  getIdentityHashField('dart:_object_helper', null, 'getIdentityHashField'),
  setIdentityHashField('dart:_object_helper', null, 'setIdentityHashField'),
  unsafeCast('dart:_internal', null, 'unsafeCast'),
  unsafeCastOpaque('dart:_internal', null, 'unsafeCastOpaque'),
  nativeEffect('dart:_internal', null, '_nativeEffect'),
  floatToIntBits('dart:_internal', null, 'floatToIntBits'),
  intBitsToFloat('dart:_internal', null, 'intBitsToFloat'),
  doubleToIntBits('dart:_internal', null, 'doubleToIntBits'),
  intBitsToDouble('dart:_internal', null, 'intBitsToDouble'),
  exportWasmFunction('dart:_internal', null, 'exportWasmFunction'),
  getID('dart:_internal', 'ClassID', 'getID'),
  loadInt8('dart:ffi', null, '_loadInt8'),
  loadUint8('dart:ffi', null, '_loadUint8'),
  loadInt16('dart:ffi', null, '_loadInt16'),
  loadUint16('dart:ffi', null, '_loadUint16'),
  loadInt32('dart:ffi', null, '_loadInt32'),
  loadUint32('dart:ffi', null, '_loadUint32'),
  loadInt64('dart:ffi', null, '_loadInt64'),
  loadUint64('dart:ffi', null, '_loadUint64'),
  loadFloat('dart:ffi', null, '_loadFloat'),
  loadFloatUnaligned('dart:ffi', null, '_loadFloatUnaligned'),
  loadDouble('dart:ffi', null, '_loadDouble'),
  loadDoubleUnaligned('dart:ffi', null, '_loadDoubleUnaligned'),
  storeInt8('dart:ffi', null, '_storeInt8'),
  storeUint8('dart:ffi', null, '_storeUint8'),
  storeInt16('dart:ffi', null, '_storeInt16'),
  storeUint16('dart:ffi', null, '_storeUint16'),
  storeInt32('dart:ffi', null, '_storeInt32'),
  storeUint32('dart:ffi', null, '_storeUint32'),
  storeInt64('dart:ffi', null, '_storeInt64'),
  storeUint64('dart:ffi', null, '_storeUint64'),
  storeFloat('dart:ffi', null, '_storeFloat'),
  storeFloatUnaligned('dart:ffi', null, '_storeFloatUnaligned'),
  storeDouble('dart:ffi', null, '_storeDouble'),
  storeDoubleUnaligned('dart:ffi', null, '_storeDoubleUnaligned'),
  wasmI31RefNew('dart:_wasm', 'WasmI31Ref', 'fromI32'),
  wasmI31RefExtensionsExternalize(
      'dart:_wasm', null, 'WasmI31RefExtensions|externalize'),
  wasmI31RefExtensionsGetS('dart:_wasm', null, 'WasmI31RefExtensions|get_s'),
  wasmI31RefExtensionsGetU('dart:_wasm', null, 'WasmI31RefExtensions|get_u'),
  wasmMemorySize('dart:_wasm', null, 'MemoryAccessExtension|get#size'),
  wasmMemoryGrow('dart:_wasm', null, 'MemoryAccessExtension|grow'),
  wasmMemoryFill('dart:_wasm', null, 'MemoryAccessExtension|fill'),
  wasmMemoryLoadFloat32(
      'dart:_wasm', null, 'MemoryAccessExtension|loadFloat32'),
  wasmMemoryLoadFloat64(
      'dart:_wasm', null, 'MemoryAccessExtension|loadFloat64'),
  wasmMemoryLoadInt8('dart:_wasm', null, 'MemoryAccessExtension|loadInt8'),
  wasmMemoryLoadInt16('dart:_wasm', null, 'MemoryAccessExtension|loadInt16'),
  wasmMemoryLoadInt32('dart:_wasm', null, 'MemoryAccessExtension|loadInt32'),
  wasmMemoryLoadInt64('dart:_wasm', null, 'MemoryAccessExtension|loadInt64'),
  wasmMemoryLoadUint8('dart:_wasm', null, 'MemoryAccessExtension|loadUint8'),
  wasmMemoryLoadUint16('dart:_wasm', null, 'MemoryAccessExtension|loadUint16'),
  wasmMemoryLoadUint32('dart:_wasm', null, 'MemoryAccessExtension|loadUint32'),
  wasmMemoryStoreFloat32(
      'dart:_wasm', null, 'MemoryAccessExtension|storeFloat32'),
  wasmMemoryStoreFloat64(
      'dart:_wasm', null, 'MemoryAccessExtension|storeFloat64'),
  wasmMemoryStoreInt8('dart:_wasm', null, 'MemoryAccessExtension|storeInt8'),
  wasmMemoryStoreInt16('dart:_wasm', null, 'MemoryAccessExtension|storeInt16'),
  wasmMemoryStoreInt32('dart:_wasm', null, 'MemoryAccessExtension|storeInt32'),
  wasmMemoryStoreInt64('dart:_wasm', null, 'MemoryAccessExtension|storeInt64'),
  ;

  final String library;
  final String? cls;
  final String name;

  const StaticIntrinsic(this.library, this.cls, this.name);

  static Map<String, Map<String?, Map<String, StaticIntrinsic>>>? _lookup;

  static Map<String, Map<String?, Map<String, StaticIntrinsic>>>
      _populateLookup() {
    final result = <String, Map<String?, Map<String, StaticIntrinsic>>>{};
    for (var intrinsic in StaticIntrinsic.values) {
      ((result[intrinsic.library] ??= {})[intrinsic.cls] ??=
          {})[intrinsic.name] = intrinsic;
    }
    return result;
  }

  static StaticIntrinsic? fromProcedure(CoreTypes coreTypes, Procedure member) {
    final intrinsic = (_lookup ??=
            _populateLookup())['${member.enclosingLibrary.importUri}']
        ?[member.enclosingClass?.name]?[member.name.text];
    assert(intrinsic == null || hasPragma(coreTypes, member, 'wasm:intrinsic'));
    return intrinsic;
  }
}

/// Specialized code generation for external members.
///
/// The code is generated either inlined at the call site, or as the body of
/// the member in [generateMemberIntrinsic].
class Intrinsifier {
  final AstCodeGenerator codeGen;

  static const w.ValueType boolType = w.NumType.i32;
  static const w.ValueType intType = w.NumType.i64;
  static const w.ValueType doubleType = w.NumType.f64;

  static final Map<w.ValueType, Map<w.ValueType, Map<String, CodeGenCallback>>>
      _binaryOperatorMap = {
    boolType: {
      boolType: {
        '|': (c) => c.b.i32_or(),
        '^': (c) => c.b.i32_xor(),
        '&': (c) => c.b.i32_and(),
      }
    },
    intType: {
      intType: {
        '+': (c) => c.b.i64_add(),
        '-': (c) => c.b.i64_sub(),
        '*': (c) => c.b.i64_mul(),
        '&': (c) => c.b.i64_and(),
        '|': (c) => c.b.i64_or(),
        '^': (c) => c.b.i64_xor(),
        '<': (c) => c.b.i64_lt_s(),
        '<=': (c) => c.b.i64_le_s(),
        '>': (c) => c.b.i64_gt_s(),
        '>=': (c) => c.b.i64_ge_s(),
        '~/': (c) => c.call(c.translator.truncDiv.reference),
      }
    },
    doubleType: {
      doubleType: {
        '+': (c) => c.b.f64_add(),
        '-': (c) => c.b.f64_sub(),
        '*': (c) => c.b.f64_mul(),
        '/': (c) => c.b.f64_div(),
        '<': (c) => c.b.f64_lt(),
        '<=': (c) => c.b.f64_le(),
        '>': (c) => c.b.f64_gt(),
        '>=': (c) => c.b.f64_ge(),
      }
    },
  };

  static final Map<w.ValueType, Map<String, CodeGenCallback>>
      _unaryOperatorMap = {
    intType: {
      'unary-': (c) {
        c.b.i64_const(-1);
        c.b.i64_mul();
      },
      '~': (c) {
        c.b.i64_const(-1);
        c.b.i64_xor();
      },
      'toDouble': (c) {
        c.b.f64_convert_i64_s();
      },
    },
    doubleType: {
      'unary-': (c) {
        c.b.f64_neg();
      },
      'floorToDouble': (c) {
        c.b.f64_floor();
      },
      'ceilToDouble': (c) {
        c.b.f64_ceil();
      },
      'truncateToDouble': (c) {
        c.b.f64_trunc();
      },
    },
  };

  static final Map<w.ValueType, Map<String, InlineCodeGenCallback>>
      _inlineUnaryOperatorMap = {
    intType: {
      'unary-': (c, receiver) {
        final int? intValue = extractIntValue(receiver);
        if (intValue == null) {
          c.translateExpression(receiver, intType);
          c.b.i64_const(-1);
          c.b.i64_mul();
        } else {
          c.b.i64_const(-intValue);
        }
      },
      '~': (c, receiver) {
        final int? intValue = extractIntValue(receiver);
        if (intValue == null) {
          c.translateExpression(receiver, intType);
          c.b.i64_const(-1);
          c.b.i64_xor();
        } else {
          c.b.i64_const(~intValue);
        }
      },
      'toDouble': (c, receiver) {
        final int? intValue = extractIntValue(receiver);
        if (intValue == null) {
          c.translateExpression(receiver, intType);
          c.b.f64_convert_i64_s();
        } else {
          c.b.f64_const(intValue.toDouble());
        }
      },
    },
    doubleType: {
      'unary-': (c, receiver) {
        final double? doubleValue = _extractDoubleValue(receiver);
        if (doubleValue == null) {
          c.translateExpression(receiver, doubleType);
          c.b.f64_neg();
        } else {
          c.b.f64_const(-doubleValue);
        }
      },
      'floorToDouble': (c, receiver) {
        final double? doubleValue = _extractDoubleValue(receiver);
        if (doubleValue == null) {
          c.translateExpression(receiver, doubleType);
          c.b.f64_floor();
        } else {
          c.b.f64_const(doubleValue.floorToDouble());
        }
      },
      'ceilToDouble': (c, receiver) {
        final double? doubleValue = _extractDoubleValue(receiver);
        if (doubleValue == null) {
          c.translateExpression(receiver, doubleType);
          c.b.f64_ceil();
        } else {
          c.b.f64_const(doubleValue.ceilToDouble());
        }
      },
      'truncateToDouble': (c, receiver) {
        final double? doubleValue = _extractDoubleValue(receiver);
        if (doubleValue == null) {
          c.translateExpression(receiver, doubleType);
          c.b.f64_trunc();
        } else {
          c.b.f64_const(doubleValue.truncateToDouble());
        }
      },
    },
  };

  static final Map<String, w.ValueType> _unaryResultMap = {
    'toDouble': w.NumType.f64,
    'floorToDouble': w.NumType.f64,
    'ceilToDouble': w.NumType.f64,
    'truncateToDouble': w.NumType.f64,
  };

  Translator get translator => codeGen.translator;
  Types get types => codeGen.translator.types;
  w.InstructionsBuilder get b => codeGen.b;

  DartType dartTypeOf(Expression exp) => codeGen.dartTypeOf(exp);

  w.ValueType typeOfExp(Expression exp) {
    return translator.translateType(dartTypeOf(exp));
  }

  static bool isComparison(String op) =>
      op == '<' ||
      op == '<=' ||
      op == '>' ||
      op == '>=' ||
      op == '_le_u' ||
      op == '_lt_u';

  Intrinsifier(this.codeGen);

  /// Generate inline code for an [InstanceGet] if the member is an inlined
  /// intrinsic.
  w.ValueType? generateInstanceGetterIntrinsic(InstanceGet node) {
    Expression receiver = node.receiver;
    String name = node.name.text;
    Member target = node.interfaceTarget;
    Class cls = target.enclosingClass!;

    // WasmAnyRef.isObject, WasmAnyRef.isI31
    if (cls == translator.wasmAnyRefClass) {
      if (name == "isObject") {
        codeGen.translateExpression(receiver, w.RefType.any(nullable: false));
        b.ref_test(translator.topTypeNonNullable);
        return w.NumType.i32;
      } else if (name == "isI31") {
        codeGen.translateExpression(receiver, w.RefType.any(nullable: false));
        b.ref_test(w.RefType.i31(nullable: false));
        return w.NumType.i32;
      }
    }

    // WasmArrayRef.length
    if (cls == translator.wasmArrayRefClass) {
      assert(name == 'length');
      codeGen.translateExpression(receiver, w.RefType.array(nullable: false));
      b.array_len();
      b.i64_extend_i32_u();
      return w.NumType.i64;
    }

    // WasmTable.size
    if (cls == translator.wasmTableClass) {
      if (receiver is! StaticGet || receiver.target is! Field) {
        throw "Table size not directly on a static field"
            " at ${node.location}";
      }
      w.Table table =
          translator.getTable(b.moduleBuilder, receiver.target as Field)!;
      assert(name == "size");
      b.table_size(table);
      return w.NumType.i32;
    }

    // int.bitlength
    if (cls == translator.coreTypes.intClass && name == 'bitLength') {
      w.Local temp = b.addLocal(w.NumType.i64);
      b.i64_const(64);
      codeGen.translateExpression(receiver, w.NumType.i64);
      b.local_tee(temp);
      b.local_get(temp);
      b.i64_const(63);
      b.i64_shr_s();
      b.i64_xor();
      b.i64_clz();
      b.i64_sub();
      return w.NumType.i64;
    }

    return null;
  }

  /// Generate inline code for an [InstanceInvocation] if the member is an
  /// inlined intrinsic.
  w.ValueType? generateInstanceIntrinsic(InstanceInvocation node) {
    Expression receiver = node.receiver;
    DartType receiverType = dartTypeOf(receiver);
    String name = node.name.text;
    Procedure target = node.interfaceTarget;
    Class cls = target.enclosingClass!;

    // WasmAnyRef.toObject
    if (cls == translator.wasmAnyRefClass && name == "toObject") {
      w.Label succeed = b.block(const [], [translator.topTypeNonNullable]);
      codeGen.translateExpression(
          receiver, const w.RefType.any(nullable: false));
      b.br_on_cast(succeed, const w.RefType.any(nullable: false),
          translator.topTypeNonNullable);
      codeGen.throwWasmRefError("a Dart object");
      b.end(); // succeed
      return translator.topTypeNonNullable;
    }

    // Wasm(I32|I64|F32|F64) conversions
    if (cls.superclass == translator.wasmTypesBaseClass) {
      w.StorageType? receiverType = translator.builtinTypes[cls];
      switch (receiverType) {
        case w.NumType.i32:
          switch (name) {
            case "unary-":
              b.i32_const(0);
              codeGen.translateExpression(receiver, w.NumType.i32);
              b.i32_sub();
              return w.NumType.i32;
          }
          codeGen.translateExpression(receiver, w.NumType.i32);
          switch (name) {
            case "toIntSigned":
              b.i64_extend_i32_s();
              return w.NumType.i64;
            case "toIntUnsigned":
              b.i64_extend_i32_u();
              return w.NumType.i64;
            case "toBool":
              b.i32_const(0);
              b.i32_ne();
              return w.NumType.i32;
          }
          codeGen.translateExpression(
              node.arguments.positional[0], w.NumType.i32);
          switch (name) {
            case "toIntSigned":
              b.i64_extend_i32_s();
              return w.NumType.i64;
            case "toIntUnsigned":
              b.i64_extend_i32_u();
              return w.NumType.i64;
            case "toBool":
              b.i32_const(0);
              b.i32_ne();
              return w.NumType.i32;
            case "+":
              b.i32_add();
              return w.NumType.i32;
            case "-":
              b.i32_sub();
              return w.NumType.i32;
            case ">>":
              b.i32_shr_s();
              return w.NumType.i32;
            case "<":
              b.i32_lt_s();
              return boolType;
            case "<=":
              b.i32_le_s();
              return boolType;
            case "==":
              b.i32_eq();
              return boolType;
            case ">=":
              b.i32_ge_s();
              return boolType;
            case ">":
              b.i32_gt_s();
              return boolType;
            case "leU":
              b.i32_le_u();
              return boolType;
            case "ltU":
              b.i32_lt_u();
              return boolType;
            case "geU":
              b.i32_ge_u();
              return boolType;
            case "gtU":
              b.i32_gt_u();
              return boolType;
            default:
              throw 'Unknown WasmI32 member $name';
          }
        case w.NumType.i64:
          switch (name) {
            case "toInt":
              codeGen.translateExpression(receiver, w.NumType.i64);
              return w.NumType.i64;
            case "leU":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_le_u();
              return boolType;
            case "ltU":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_lt_u();
              return boolType;
            case "geU":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_ge_u();
              return boolType;
            case "gtU":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_gt_u();
              return boolType;
            case "shl":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_shl();
              return w.NumType.i64;
            case "shrS":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_shr_s();
              return w.NumType.i64;
            case "shrU":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_shr_u();
              return w.NumType.i64;
            case "divS":
              codeGen.translateExpression(receiver, w.NumType.i64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.i64);
              b.i64_div_s();
              return w.NumType.i64;
            default:
              throw 'Unknown WasmI64 member $name';
          }
        case w.NumType.f32:
          switch (name) {
            case 'toDouble':
              codeGen.translateExpression(receiver, w.NumType.f32);
              b.f64_promote_f32();
              return w.NumType.f64;
            default:
              throw 'Unknown WasmF32 member $name';
          }
        case w.NumType.f64:
          switch (name) {
            case "toDouble":
              codeGen.translateExpression(receiver, w.NumType.f64);
              return w.NumType.f64;
            case "truncSatS":
              codeGen.translateExpression(receiver, w.NumType.f64);
              b.i64_trunc_sat_f64_s();
              return w.NumType.i64;
            case "sqrt":
              codeGen.translateExpression(receiver, w.NumType.f64);
              b.f64_sqrt();
              return w.NumType.f64;
            case "copysign":
              codeGen.translateExpression(receiver, w.NumType.f64);
              codeGen.translateExpression(
                  node.arguments.positional[0], w.NumType.f64);
              b.f64_copysign();
              return w.NumType.f64;
            default:
              throw 'Unknown WasmF64 member $name';
          }
      }
    }

    // WasmTable.[] and WasmTable.[]=
    if (cls == translator.wasmTableClass) {
      if (receiver is! StaticGet || receiver.target is! Field) {
        throw "Table indexing not directly on a static field"
            " at ${node.location}";
      }
      w.Table table =
          translator.getTable(b.moduleBuilder, receiver.target as Field)!;
      codeGen.translateExpression(node.arguments.positional[0], w.NumType.i32);
      if (name == '[]') {
        b.table_get(table);
        return table.type;
      } else {
        assert(name == '[]=');
        codeGen.translateExpression(node.arguments.positional[1], table.type);
        b.table_set(table);
        return codeGen.voidMarker;
      }
    }

    // List.[] on list constants
    if (receiver is ConstantExpression &&
        receiver.constant is ListConstant &&
        name == '[]') {
      Expression arg = node.arguments.positional.single;

      // If the list is indexed by a constant, or the ABI index, just pick
      // the element at that constant index.
      int? constIndex;
      if (arg is IntLiteral) {
        constIndex = arg.value;
      } else if (arg is ConstantExpression) {
        Constant argConst = arg.constant;
        if (argConst is IntConstant) {
          constIndex = argConst.value;
        }
      } else if (arg is StaticInvocation) {
        if (arg.target.enclosingLibrary.name == "dart.ffi" &&
            arg.name.text == "_abi") {
          constIndex = kWasmAbiEnumIndex;
        }
      }
      if (constIndex != null) {
        final entries = (receiver.constant as ListConstant).entries;
        if (0 <= constIndex && constIndex < entries.length) {
          Expression element = ConstantExpression(entries[constIndex]);
          return codeGen.translateExpression(element, typeOfExp(element));
        }
      }

      return null;
    }

    if (node.arguments.positional.length == 1) {
      // Binary operator
      Expression left = node.receiver;
      Expression right = node.arguments.positional.single;
      DartType argType = dartTypeOf(right);
      w.ValueType leftType = translator.translateType(receiverType);
      w.ValueType rightType = translator.translateType(argType);
      var code = _binaryOperatorMap[leftType]?[rightType]?[name];
      if (code != null) {
        w.ValueType outType = isComparison(name) ? w.NumType.i32 : leftType;
        codeGen.translateExpression(left, leftType);
        codeGen.translateExpression(right, rightType);
        code(codeGen);
        return outType;
      }
    } else if (node.arguments.positional.isEmpty) {
      // Unary operator
      Expression operand = node.receiver;
      w.ValueType operandType = translator.translateType(receiverType);
      var code = _inlineUnaryOperatorMap[operandType]?[name];
      if (code != null) {
        code(codeGen, operand);
        return _unaryResultMap[name] ?? operandType;
      }
    }

    return null;
  }

  /// Generate inline code for an [EqualsCall] with an unboxed receiver.
  w.ValueType? generateEqualsIntrinsic(EqualsCall node) {
    w.ValueType leftType = typeOfExp(node.left);
    w.ValueType rightType = typeOfExp(node.right);

    // Compare bool or WasmI32.
    if (leftType == w.NumType.i32 && rightType == w.NumType.i32) {
      codeGen.translateExpression(node.left, w.NumType.i32);
      codeGen.translateExpression(node.right, w.NumType.i32);
      b.i32_eq();
      return w.NumType.i32;
    }

    // Compare int or WasmI64.
    if (leftType == w.NumType.i64 && rightType == w.NumType.i64) {
      codeGen.translateExpression(node.left, w.NumType.i64);
      codeGen.translateExpression(node.right, w.NumType.i64);
      b.i64_eq();
      return w.NumType.i32;
    }

    // Compare WasmF32.
    if (leftType == w.NumType.f32 && rightType == w.NumType.f32) {
      codeGen.translateExpression(node.left, w.NumType.f32);
      codeGen.translateExpression(node.right, w.NumType.f32);
      b.f32_eq();
      return w.NumType.i32;
    }

    // Compare double or WasmF64.
    if (leftType == doubleType && rightType == doubleType) {
      codeGen.translateExpression(node.left, w.NumType.f64);
      codeGen.translateExpression(node.right, w.NumType.f64);
      b.f64_eq();
      return w.NumType.i32;
    }

    return null;
  }

  /// Generate inline code for a [StaticGet] if the member is an inlined
  /// intrinsic.
  w.ValueType? generateStaticGetterIntrinsic(StaticGet node) {
    final Member target = node.target;
    final Class? cls = target.enclosingClass;

    // ClassID getters
    if (cls?.name == 'ClassID') {
      if (target.name.text == 'maxClassId') {
        codeGen.b.i32_const(translator.classIdNumbering.maxClassId);
        return w.NumType.i32;
      }
      final libAndClassName = translator.getPragma(target, "wasm:class-id");
      if (libAndClassName != null) {
        List<String> libAndClassNameParts = libAndClassName.split("#");
        final String lib = libAndClassNameParts[0];
        final String className = libAndClassNameParts[1];
        Class cls = translator.libraries
            .firstWhere((l) => l.name == lib && l.importUri.scheme == 'dart',
                orElse: () =>
                    throw 'Library $lib not found (${target.location})')
            .classes
            .firstWhere((c) => c.name == className,
                orElse: () =>
                    throw 'Class $className not found in library $lib '
                        '(${target.location})');
        ClassId classId = translator.classInfo[cls]!.classId;
        b.pushClassIdToStack(translator, classId);
        return w.NumType.i32;
      }

      if (target.name.text == 'firstNonMasqueradedInterfaceClassCid') {
        b.i32_const(
            translator.classIdNumbering.firstNonMasqueradedInterfaceClassCid);
        return w.NumType.i32;
      }
    }

    if (target.enclosingLibrary.name == 'dart._internal') {
      if (target.name.text == '_numClassesForConstCaches') {
        b.i64_const(translator.classIdNumbering.maxClassId);
        return w.NumType.i64;
      }
    }

    if (node.target.enclosingLibrary == translator.coreTypes.coreLibrary) {
      switch (target.name.text) {
        case "_isIntrinsified":
          // This is part of the VM's [BigInt] implementation. We just return false.
          // TODO(joshualitt): Can we find another way to reuse this patch file
          // without hardcoding this case?
          b.i32_const(0);
          return w.NumType.i32;
        case "_noSubstitutionIndex":
          b.i32_const(RuntimeTypeInformation.noSubstitutionIndex);
          return w.NumType.i32;
        case "_mainModuleRtt":
          final moduleRttType = translator.translateType(
              InterfaceType(translator.moduleRtt, Nullability.nonNullable));
          translator.constants.instantiateConstant(
              b, translator.types.rtt.mainModuleRtt, moduleRttType);
          return moduleRttType;
      }
    }

    if (target.enclosingLibrary.name == 'dart._js_helper') {
      if (target.name.text == 'thisModule') {
        final global = translator.getThisModuleGlobal(b.moduleBuilder);
        b.global_get(global);
        return global.type.type;
      }
    }

    return null;
  }

  int _getSimdLaneIndex(Expression argument, int numLanes, TreeNode node) {
    final lane = extractIntValue(argument);
    if (lane == null) {
      throw ArgumentError('Lane index must be an integer literal or constant: '
          '$node (${node.location})');
    }
    if (lane < 0 || lane >= numLanes) {
      throw ArgumentError('Lane index, $lane, out of bounds: '
          '$node (${node.location})');
    }
    return lane;
  }

  /// Generate inline code for a [StaticInvocation] if the member is an inlined
  /// intrinsic.
  w.ValueType? generateStaticIntrinsic(StaticInvocation node) {
    String name = node.name.text;
    final Procedure target = node.target;
    Class? cls = target.enclosingClass;

    final intrinsic =
        StaticIntrinsic.fromProcedure(translator.coreTypes, target);

    if (intrinsic == null) return null;

    switch (intrinsic) {
      // extension {,Immutable}WasmArrayExt on {,Immutable}WasmArray<T>
      case StaticIntrinsic.wasmArrayIndex:
      case StaticIntrinsic.wasmArrayIndexSet:
      case StaticIntrinsic.wasmArrayCopy:
      case StaticIntrinsic.wasmArrayFill:
      case StaticIntrinsic.wasmArrayClone:
      case StaticIntrinsic.immutableWasmArrayIndex:
        final dartWasmArrayType = dartTypeOf(node.arguments.positional.first);
        final dartElementType =
            (dartWasmArrayType as InterfaceType).typeArguments.single;
        final w.ArrayType arrayType =
            (translator.translateType(dartWasmArrayType) as w.RefType).heapType
                as w.ArrayType;
        final w.FieldType fieldType = arrayType.elementType;
        final w.StorageType wasmType = fieldType.type;
        switch (intrinsic) {
          case StaticIntrinsic.wasmArrayIndex:
          case StaticIntrinsic.immutableWasmArrayIndex:
            final array = node.arguments.positional[0];
            final index = node.arguments.positional[1];
            codeGen.translateExpression(
                array, w.RefType.def(arrayType, nullable: false));
            codeGen.translateExpression(index, w.NumType.i64);
            b.i32_wrap_i64();
            if (wasmType is w.PackedType) {
              b.array_get_u(arrayType);
            } else {
              b.array_get(arrayType);
            }
            return wasmType.unpacked;
          case StaticIntrinsic.wasmArrayIndexSet:
            assert(fieldType.mutable);
            final array = node.arguments.positional[0];
            final index = node.arguments.positional[1];
            final value = node.arguments.positional[2];
            codeGen.translateExpression(
                array, w.RefType.def(arrayType, nullable: false));
            codeGen.translateExpression(index, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.translateExpression(value, typeOfExp(value));
            b.array_set(arrayType);
            return codeGen.voidMarker;
          case StaticIntrinsic.wasmArrayCopy:
            assert(fieldType.mutable);
            final destArray = node.arguments.positional[0];
            final destOffset = node.arguments.positional[1];
            final sourceArray = node.arguments.positional[2];
            final sourceOffset = node.arguments.positional[3];
            final size = node.arguments.positional[4];

            codeGen.translateExpression(
                destArray, w.RefType.def(arrayType, nullable: false));
            codeGen.translateExpression(destOffset, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.translateExpression(
                sourceArray, w.RefType.def(arrayType, nullable: false));
            codeGen.translateExpression(sourceOffset, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.translateExpression(size, w.NumType.i64);
            b.i32_wrap_i64();
            b.array_copy(arrayType, arrayType);
            return codeGen.voidMarker;
          case StaticIntrinsic.wasmArrayFill:
            assert(fieldType.mutable);
            final array = node.arguments.positional[0];
            final offset = node.arguments.positional[1];
            final value = node.arguments.positional[2];
            final size = node.arguments.positional[3];

            codeGen.translateExpression(
                array, w.RefType.def(arrayType, nullable: false));
            codeGen.translateExpression(offset, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.translateExpression(
                value, translator.translateType(dartElementType));
            codeGen.translateExpression(size, w.NumType.i64);
            b.i32_wrap_i64();
            b.array_fill(arrayType);
            return codeGen.voidMarker;
          case StaticIntrinsic.wasmArrayClone:
            assert(fieldType.mutable);
            // Until `array.new_copy` we need a special case for empty arrays.
            // https://github.com/WebAssembly/gc/issues/367
            final sourceArray = node.arguments.positional[0];

            final sourceArrayRefType =
                w.RefType.def(arrayType, nullable: false);
            final sourceArrayLocal = b.addLocal(sourceArrayRefType);
            final newArrayLocal = b.addLocal(sourceArrayRefType);

            codeGen.translateExpression(sourceArray, sourceArrayRefType);
            b.local_tee(sourceArrayLocal);

            b.array_len();
            b.if_([], [sourceArrayRefType]);
            // Non-empty array. Create new one with the first element of the
            // source, then copy the rest.
            b.local_get(sourceArrayLocal);
            b.i32_const(0);
            b.array_get(arrayType);
            b.local_get(sourceArrayLocal);
            b.array_len();
            b.array_new(arrayType);
            b.local_tee(newArrayLocal); // copy dest
            b.i32_const(1); // copy dest offset
            b.local_get(sourceArrayLocal); // copy source
            b.i32_const(1); // copy source offset

            // copy size
            b.local_get(sourceArrayLocal);
            b.array_len();
            b.i32_const(1);
            b.i32_sub();

            b.array_copy(arrayType, arrayType);

            b.local_get(newArrayLocal);
            b.else_();
            // Empty array.
            b.array_new_fixed(arrayType, 0);
            b.end();

            return sourceArrayRefType;
          default:
            throw StateError('Unhandled WasmArray intrinsic: $intrinsic');
        }

      // extension {,Immutable}(I8|I16|I32|I64|F32|F64)ArrayExt on {,Immutable}WasmArray<...>
      case StaticIntrinsic.i8ArrayExtReadSigned:
      case StaticIntrinsic.immutableI8ArrayExtReadSigned:
      case StaticIntrinsic.i16ArrayExtReadSigned:
      case StaticIntrinsic.immutableI16ArrayExtReadSigned:
      case StaticIntrinsic.i32ArrayExtReadSigned:
      case StaticIntrinsic.immutableI32ArrayExtReadSigned:
      case StaticIntrinsic.i64ArrayExtRead:
      case StaticIntrinsic.immutableI64ArrayExtRead:
      case StaticIntrinsic.f32ArrayExtRead:
      case StaticIntrinsic.immutableF32ArrayExtRead:
      case StaticIntrinsic.f64ArrayExtRead:
      case StaticIntrinsic.immutableF64ArrayExtRead:
        return readIntArray(node, unsigned: false);
      case StaticIntrinsic.i8ArrayExtReadUnsigned:
      case StaticIntrinsic.immutableI8ArrayExtReadUnsigned:
      case StaticIntrinsic.i16ArrayExtReadUnsigned:
      case StaticIntrinsic.immutableI16ArrayExtReadUnsigned:
      case StaticIntrinsic.i32ArrayExtReadUnsigned:
      case StaticIntrinsic.immutableI32ArrayExtReadUnsigned:
        return readIntArray(node, unsigned: true);
      case StaticIntrinsic.i8ArrayExtWrite:
      case StaticIntrinsic.i16ArrayExtWrite:
      case StaticIntrinsic.i32ArrayExtWrite:
      case StaticIntrinsic.i64ArrayExtWrite:
      case StaticIntrinsic.f32ArrayExtWrite:
      case StaticIntrinsic.f64ArrayExtWrite:
        final dartWasmArrayType = dartTypeOf(node.arguments.positional.first);
        final w.ArrayType arrayType =
            (translator.translateType(dartWasmArrayType) as w.RefType).heapType
                as w.ArrayType;
        final w.FieldType fieldType = arrayType.elementType;
        final w.StorageType wasmType = fieldType.type;

        final outerExtend =
            wasmType.unpacked == w.NumType.i32 || wasmType == w.NumType.f32;
        assert(fieldType.mutable);
        final array = node.arguments.positional[0];
        final index = node.arguments.positional[1];
        final value = node.arguments.positional[2];
        codeGen.translateExpression(
            array, w.RefType.def(arrayType, nullable: false));
        codeGen.translateExpression(index, w.NumType.i64);
        b.i32_wrap_i64();
        codeGen.translateExpression(value, typeOfExp(value));
        if (outerExtend) {
          if (wasmType == w.NumType.f32) {
            b.f32_demote_f64();
          } else {
            b.i32_wrap_i64();
          }
        }
        b.array_set(arrayType);
        return codeGen.voidMarker;

      case StaticIntrinsic.identical:
        // We can use reference equality for `identical()` except if one of the
        // arguments can be a value type which would need to be compared by
        // value instead of by reference.
        //
        // NOTE: Even though `bool` is a value type, it has only two singleton
        // instances for `true` and `false` and we can therefore use reference
        // equality for it. Other value types may have different objects
        // containing the same value and need to be unboxed & compared by value.
        //
        // NOTE: We may get more value types in the future in Dart, for example
        // for SIMD types, see: https://github.com/dart-lang/sdk/issues/43255

        final first = node.arguments.positional[0];
        final second = node.arguments.positional[1];

        final firstType =
            translator.toMostSpecificInterfaceType(dartTypeOf(first));
        final secondType =
            translator.toMostSpecificInterfaceType(dartTypeOf(second));

        final intType = translator.boxedIntType;
        if (firstType == intType && secondType == intType) {
          codeGen.translateExpression(first, w.NumType.i64);
          codeGen.translateExpression(second, w.NumType.i64);
          b.i64_eq();
          return w.NumType.i32;
        }

        final doubleType = translator.boxedDoubleType;
        if (firstType == doubleType && secondType == doubleType) {
          codeGen.translateExpression(first, w.NumType.f64);
          b.i64_reinterpret_f64();
          codeGen.translateExpression(second, w.NumType.f64);
          b.i64_reinterpret_f64();
          b.i64_eq();
          return w.NumType.i32;
        }

        bool canBeValueType(DartType type) =>
            translator.typeEnvironment.isSubtypeOf(doubleType, type) ||
            translator.typeEnvironment.isSubtypeOf(intType, type);

        if (!canBeValueType(firstType) || !canBeValueType(secondType)) {
          final nullableEqRefType = w.RefType.eq(nullable: true);
          codeGen.translateExpression(first, nullableEqRefType);
          codeGen.translateExpression(second, nullableEqRefType);
          b.ref_eq();
          return w.NumType.i32;
        }

        return null;
      case StaticIntrinsic.isObjectClassId:
        final classId = node.arguments.positional.single;

        final objectClassId = (translator.classIdNumbering
                .classIds[translator.coreTypes.objectClass] as AbsoluteClassId)
            .value;

        codeGen.translateExpression(classId, w.NumType.i32);
        b.emitClassIdRangeCheck([Range(objectClassId, objectClassId)]);
        return w.NumType.i32;
      case StaticIntrinsic.isClosureClassId:
        final classId = node.arguments.positional.single;

        final ranges = translator.classIdNumbering
            .getConcreteClassIdRangeForMainModule(
                translator.coreTypes.functionClass);
        assert(ranges.length <= 1);

        codeGen.translateExpression(classId, w.NumType.i32);
        b.emitClassIdRangeCheck(ranges);

        return w.NumType.i32;
      case StaticIntrinsic.isRecordClassId:
        final classId = node.arguments.positional.single;
        final ranges = translator.classIdNumbering
            .getConcreteClassIdRangeForMainModule(
                translator.coreTypes.recordClass);
        assert(ranges.length <= 1);

        if (translator.dynamicModuleSupportEnabled) {
          final submoduleRanges = translator.classIdNumbering
              .getConcreteClassIdRangeForDynamicSubmodule(
                  translator.coreTypes.recordClass);
          final classIdLocal = b.addLocal(w.NumType.i32);
          codeGen.translateExpression(classId, w.NumType.i32);
          b.local_tee(classIdLocal);
          b.local_get(classIdLocal);
          translator.dynamicModuleInfo!.callClassIdBranchBuiltIn(
              BuiltinUpdatableFunctions.recordId, b,
              skipSubmodule: submoduleRanges.isEmpty);
        } else {
          codeGen.translateExpression(classId, w.NumType.i32);
          b.emitClassIdRangeCheck(ranges);
        }
        return w.NumType.i32;

      // dart:_object_helper static functions.
      case StaticIntrinsic.getIdentityHashField:
        Expression arg = node.arguments.positional[0];
        w.ValueType objectType = translator.objectInfo.nonNullableType;
        codeGen.translateExpression(arg, objectType);
        b.struct_get(translator.objectInfo.struct, FieldIndex.identityHash);
        b.i64_extend_i32_u();
        return w.NumType.i64;
      case StaticIntrinsic.setIdentityHashField:
        Expression arg = node.arguments.positional[0];
        Expression hash = node.arguments.positional[1];
        w.ValueType objectType = translator.objectInfo.nonNullableType;
        codeGen.translateExpression(arg, objectType);
        codeGen.translateExpression(hash, w.NumType.i64);
        b.i32_wrap_i64();
        b.struct_set(translator.objectInfo.struct, FieldIndex.identityHash);
        return codeGen.voidMarker;

      // dart:_internal static functions
      case StaticIntrinsic.unsafeCast:
      case StaticIntrinsic.unsafeCastOpaque:
        Expression operand = node.arguments.positional.single;
        // Just evaluate the operand and let the context convert it to the
        // expected type.
        return codeGen.translateExpression(operand, typeOfExp(operand));
      case StaticIntrinsic.nativeEffect:
        // Ignore argument
        return translator.voidMarker;
      case StaticIntrinsic.floatToIntBits:
        codeGen.translateExpression(
            node.arguments.positional.single, w.NumType.f64);
        b.f32_demote_f64();
        b.i32_reinterpret_f32();
        b.i64_extend_i32_u();
        return w.NumType.i64;
      case StaticIntrinsic.intBitsToFloat:
        codeGen.translateExpression(
            node.arguments.positional.single, w.NumType.i64);
        b.i32_wrap_i64();
        b.f32_reinterpret_i32();
        b.f64_promote_f32();
        return w.NumType.f64;
      case StaticIntrinsic.doubleToIntBits:
        codeGen.translateExpression(
            node.arguments.positional.single, w.NumType.f64);
        b.i64_reinterpret_f64();
        return w.NumType.i64;
      case StaticIntrinsic.intBitsToDouble:
        codeGen.translateExpression(
            node.arguments.positional.single, w.NumType.i64);
        b.f64_reinterpret_i64();
        return w.NumType.f64;
      case StaticIntrinsic.exportWasmFunction:
        const error =
            'The `dart:_internal:exportWasmFunction` expects its argument '
            'to be a tear-off of a `@pragma(\'wasm:weak-export\', ...)` '
            'annotated function';

        // Sanity check argument.
        final argument = node.arguments.positional.single;
        if (argument is! ConstantExpression) throw error;
        final constant = argument.constant;
        if (constant is! StaticTearOffConstant) throw error;
        final target = constant.target;
        if (translator.getPragma(target, 'wasm:weak-export', '') == null) {
          throw error;
        }

        // Ensure we compile the target function & export it.
        translator.functions.getFunction(target.reference);

        final topType = translator.topType;
        codeGen.translateExpression(NullLiteral(), topType);
        return topType;
      case StaticIntrinsic.getID:
        final type = translator.topTypeNonNullable;
        codeGen.translateExpression(node.arguments.positional.single, type);
        b.loadClassId(translator, type);
        return w.NumType.i32;

      // dart:ffi static functions
      case StaticIntrinsic.loadInt8:
      case StaticIntrinsic.loadUint8:
      case StaticIntrinsic.loadInt16:
      case StaticIntrinsic.loadUint16:
      case StaticIntrinsic.loadInt32:
      case StaticIntrinsic.loadUint32:
      case StaticIntrinsic.loadInt64:
      case StaticIntrinsic.loadUint64:
      case StaticIntrinsic.loadFloat:
      case StaticIntrinsic.loadFloatUnaligned:
      case StaticIntrinsic.loadDouble:
      case StaticIntrinsic.loadDoubleUnaligned:
      case StaticIntrinsic.storeInt8:
      case StaticIntrinsic.storeUint8:
      case StaticIntrinsic.storeInt16:
      case StaticIntrinsic.storeUint16:
      case StaticIntrinsic.storeInt32:
      case StaticIntrinsic.storeUint32:
      case StaticIntrinsic.storeInt64:
      case StaticIntrinsic.storeUint64:
      case StaticIntrinsic.storeFloat:
      case StaticIntrinsic.storeFloatUnaligned:
      case StaticIntrinsic.storeDouble:
      case StaticIntrinsic.storeDoubleUnaligned:
        Expression pointerArg = node.arguments.positional[0];
        Expression offsetArg = node.arguments.positional[1];
        final ffiPointerDartType =
            InterfaceType(translator.ffiPointerClass, Nullability.nonNullable);
        final ffiPointerWasmType =
            translator.translateType(ffiPointerDartType) as w.RefType;
        codeGen.translateExpression(pointerArg, ffiPointerWasmType);
        final ffiPointerStruct = ffiPointerWasmType.heapType as w.StructType;
        b.struct_get(ffiPointerStruct, FieldIndex.ffiPointerAddress);

        int offset;
        if (offsetArg is IntLiteral) {
          offset = offsetArg.value;
        } else if (offsetArg is ConstantExpression &&
            offsetArg.constant is IntConstant) {
          offset = (offsetArg.constant as IntConstant).value;
        } else {
          codeGen.translateExpression(offsetArg, w.NumType.i64);
          b.i32_wrap_i64();
          b.i32_add();
          offset = 0;
        }
        switch (intrinsic) {
          case StaticIntrinsic.loadInt8:
            b.i64_load8_s(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadUint8:
            b.i64_load8_u(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadInt16:
            b.i64_load16_s(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadUint16:
            b.i64_load16_u(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadInt32:
            b.i64_load32_s(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadUint32:
            b.i64_load32_u(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadInt64:
          case StaticIntrinsic.loadUint64:
            b.i64_load(translator.ffiMemory, offset);
            return w.NumType.i64;
          case StaticIntrinsic.loadFloat:
            b.f32_load(translator.ffiMemory, offset);
            b.f64_promote_f32();
            return w.NumType.f64;
          case StaticIntrinsic.loadFloatUnaligned:
            b.f32_load(translator.ffiMemory, offset, 0);
            b.f64_promote_f32();
            return w.NumType.f64;
          case StaticIntrinsic.loadDouble:
            b.f64_load(translator.ffiMemory, offset);
            return w.NumType.f64;
          case StaticIntrinsic.loadDoubleUnaligned:
            b.f64_load(translator.ffiMemory, offset, 0);
            return w.NumType.f64;
          case StaticIntrinsic.storeInt8:
          case StaticIntrinsic.storeUint8:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.i64);
            b.i64_store8(translator.ffiMemory, offset);
            return translator.voidMarker;
          case StaticIntrinsic.storeInt16:
          case StaticIntrinsic.storeUint16:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.i64);
            b.i64_store16(translator.ffiMemory, offset);
            return translator.voidMarker;
          case StaticIntrinsic.storeInt32:
          case StaticIntrinsic.storeUint32:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.i64);
            b.i64_store32(translator.ffiMemory, offset);
            return translator.voidMarker;
          case StaticIntrinsic.storeInt64:
          case StaticIntrinsic.storeUint64:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.i64);
            b.i64_store(translator.ffiMemory, offset);
            return translator.voidMarker;
          case StaticIntrinsic.storeFloat:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.f64);
            b.f32_demote_f64();
            b.f32_store(translator.ffiMemory, offset);
            return translator.voidMarker;
          case StaticIntrinsic.storeFloatUnaligned:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.f64);
            b.f32_demote_f64();
            b.f32_store(translator.ffiMemory, offset, 0);
            return translator.voidMarker;
          case StaticIntrinsic.storeDouble:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.f64);
            b.f64_store(translator.ffiMemory, offset);
            return translator.voidMarker;
          case StaticIntrinsic.storeDoubleUnaligned:
            codeGen.translateExpression(
                node.arguments.positional[2], w.NumType.f64);
            b.f64_store(translator.ffiMemory, offset, 0);
            return translator.voidMarker;
          default:
            throw StateError('Unhandled ffi intrinsic: $intrinsic');
        }

      // WasmArray constructors
      case StaticIntrinsic.wasmArrayNew:
      case StaticIntrinsic.wasmArrayFilled:
      case StaticIntrinsic.immutableWasmArrayNew:
      case StaticIntrinsic.immutableWasmArrayFilled:
        final dartWasmArrayType =
            InterfaceType(cls!, Nullability.nonNullable, node.arguments.types);
        final dartElementType = node.arguments.types.single;
        final w.ArrayType arrayType =
            (translator.translateType(dartWasmArrayType) as w.RefType).heapType
                as w.ArrayType;

        final elementType = arrayType.elementType.type;
        final isDefaultable = elementType is! w.RefType || elementType.nullable;
        if (!isDefaultable && node.arguments.positional.length == 1) {
          throw 'The element type $dartElementType does not have a default value'
              '- please use WasmArray<$dartElementType>.filled() instead.';
        }

        Expression length = node.arguments.positional[0];
        codeGen.translateExpression(length, w.NumType.i64);
        b.i32_wrap_i64();
        if (node.arguments.positional.length < 2) {
          b.array_new_default(arrayType);
        } else {
          Expression initialValue = node.arguments.positional[1];
          if (initialValue is NullLiteral ||
              initialValue is ConstantExpression &&
                  initialValue.constant is NullConstant) {
            // Initialize to `null`
            b.array_new_default(arrayType);
          } else {
            // Initialize to the provided value
            w.Local lengthTemp = b.addLocal(w.NumType.i32);
            b.local_set(lengthTemp);
            codeGen.translateExpression(
                initialValue, arrayType.elementType.type.unpacked);
            b.local_get(lengthTemp);
            b.array_new(arrayType);
          }
        }
        return w.RefType.def(arrayType, nullable: false);

      // (WasmFuncRef|WasmFunction).fromRef constructors
      case StaticIntrinsic.wasmFunctionFromFuncRef:
        Expression ref = node.arguments.positional[0];
        w.RefType resultType = typeOfExp(node) as w.RefType;
        w.Label succeed = b.block(const [], [resultType]);
        codeGen.translateExpression(ref, w.RefType.func(nullable: false));
        b.br_on_cast(succeed, w.RefType.func(nullable: false), resultType);
        codeGen.throwWasmRefError("a function with the expected signature");
        b.end(); // succeed
        return resultType;
      case StaticIntrinsic.wasmFunctionFromFunction:
        assert(name == "fromFunction");
        Expression f = node.arguments.positional[0];
        if (f is! ConstantExpression || f.constant is! StaticTearOffConstant) {
          throw "Argument to WasmFunction.fromFunction isn't a static function";
        }
        StaticTearOffConstant func = f.constant as StaticTearOffConstant;
        w.BaseFunction wasmFunction =
            translator.functions.getFunction(func.targetReference);
        return translator.globals
            .readGlobal(b, translator.makeFunctionRef(wasmFunction));

      // Wasm(AnyRef|FuncRef|EqRef|StructRef|I32|I64|F32|F64) constructors
      case StaticIntrinsic.wasmI32FromInt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        b.i32_wrap_i64();
        return w.NumType.i32;
      case StaticIntrinsic.wasmI32Int8FromInt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        b.i32_wrap_i64();
        b.i32_extend8_s();
        return w.NumType.i32;
      case StaticIntrinsic.wasmI32Uint8FromInt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        b.i32_wrap_i64();
        b.i32_const(0xFF);
        b.i32_and();
        return w.NumType.i32;
      case StaticIntrinsic.wasmI32Int16FromInt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        b.i32_wrap_i64();
        b.i32_extend16_s();
        return w.NumType.i32;
      case StaticIntrinsic.wasmI32Uint16FromInt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        b.i32_wrap_i64();
        b.i32_const(0xFFFF);
        b.i32_and();
        return w.NumType.i32;
      case StaticIntrinsic.wasmI32FromBool:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i32);
        return w.NumType.i32;
      case StaticIntrinsic.wasmI64FromInt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        return w.NumType.i64;
      case StaticIntrinsic.wasmF32FromDouble:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.f64);
        b.f32_demote_f64();
        return w.NumType.f32;
      case StaticIntrinsic.wasmF64FromDouble:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.f64);
        return w.NumType.f64;
      case StaticIntrinsic.wasmI8x16Splat:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i32);
        b.i8x16_splat();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8Splat:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i32);
        b.i16x8_splat();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4Splat:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i32);
        b.i32x4_splat();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2Splat:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i64);
        b.i64x2_splat();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Splat:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.f32);
        b.f32x4_splat();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Splat:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.f64);
        b.f64x2_splat();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI8x16ExtractLaneS:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 16, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.i8x16_extract_lane_s(lane);
        return w.NumType.i32;
      case StaticIntrinsic.wasmI8x16ExtractLaneU:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 16, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.i8x16_extract_lane_u(lane);
        return w.NumType.i32;
      case StaticIntrinsic.wasmI8x16ReplaceLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 16, node);
        Expression element = node.arguments.positional[2];
        codeGen.translateExpression(value, w.NumType.v128);
        codeGen.translateExpression(element, w.NumType.i32);
        b.i8x16_replace_lane(lane);
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8ExtractLaneS:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 8, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.i16x8_extract_lane_s(lane);
        return w.NumType.i32;
      case StaticIntrinsic.wasmI16x8ExtractLaneU:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 8, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.i16x8_extract_lane_u(lane);
        return w.NumType.i32;

      case StaticIntrinsic.wasmI8x16Eq:
        Expression left = node.arguments.positional[0];
        Expression right = node.arguments.positional[1];
        codeGen.translateExpression(left, w.NumType.v128);
        codeGen.translateExpression(right, w.NumType.v128);
        b.i8x16_eq();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8Eq:
        Expression left = node.arguments.positional[0];
        Expression right = node.arguments.positional[1];
        codeGen.translateExpression(left, w.NumType.v128);
        codeGen.translateExpression(right, w.NumType.v128);
        b.i16x8_eq();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4Eq:
        Expression left = node.arguments.positional[0];
        Expression right = node.arguments.positional[1];
        codeGen.translateExpression(left, w.NumType.v128);
        codeGen.translateExpression(right, w.NumType.v128);
        b.i32x4_eq();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2Eq:
        Expression left = node.arguments.positional[0];
        Expression right = node.arguments.positional[1];
        codeGen.translateExpression(left, w.NumType.v128);
        codeGen.translateExpression(right, w.NumType.v128);
        b.i64x2_eq();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Eq:
        Expression left = node.arguments.positional[0];
        Expression right = node.arguments.positional[1];
        codeGen.translateExpression(left, w.NumType.v128);
        codeGen.translateExpression(right, w.NumType.v128);
        b.f32x4_eq();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Eq:
        Expression left = node.arguments.positional[0];
        Expression right = node.arguments.positional[1];
        codeGen.translateExpression(left, w.NumType.v128);
        codeGen.translateExpression(right, w.NumType.v128);
        b.f64x2_eq();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8ReplaceLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 8, node);
        Expression element = node.arguments.positional[2];
        codeGen.translateExpression(value, w.NumType.v128);
        codeGen.translateExpression(element, w.NumType.i32);
        b.i16x8_replace_lane(lane);
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4ExtractLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 4, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.i32x4_extract_lane(lane);
        return w.NumType.i32;
      case StaticIntrinsic.wasmI32x4ReplaceLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 4, node);
        Expression element = node.arguments.positional[2];
        codeGen.translateExpression(value, w.NumType.v128);
        codeGen.translateExpression(element, w.NumType.i32);
        b.i32x4_replace_lane(lane);
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2ExtractLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 2, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.i64x2_extract_lane(lane);
        return w.NumType.i64;
      case StaticIntrinsic.wasmI64x2ReplaceLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 2, node);
        Expression element = node.arguments.positional[2];
        codeGen.translateExpression(value, w.NumType.v128);
        codeGen.translateExpression(element, w.NumType.i64);
        b.i64x2_replace_lane(lane);
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4ExtractLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 4, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_extract_lane(lane);
        return w.NumType.f32;
      case StaticIntrinsic.wasmF32x4ReplaceLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 4, node);
        Expression element = node.arguments.positional[2];
        codeGen.translateExpression(value, w.NumType.v128);
        codeGen.translateExpression(element, w.NumType.f32);
        b.f32x4_replace_lane(lane);
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2ExtractLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 2, node);
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_extract_lane(lane);
        return w.NumType.f64;
      case StaticIntrinsic.wasmF64x2ReplaceLane:
        Expression value = node.arguments.positional[0];
        int lane = _getSimdLaneIndex(node.arguments.positional[1], 2, node);
        Expression element = node.arguments.positional[2];
        codeGen.translateExpression(value, w.NumType.v128);
        codeGen.translateExpression(element, w.NumType.f64);
        b.f64x2_replace_lane(lane);
        return w.NumType.v128;
      case StaticIntrinsic.wasmI8x16Add:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i8x16_add();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI8x16Sub:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i8x16_sub();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI8x16Neg:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.i8x16_neg();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8Add:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i16x8_add();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8Sub:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i16x8_sub();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8Mul:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i16x8_mul();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI16x8Neg:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.i16x8_neg();
        return w.NumType.v128;
      case StaticIntrinsic.wasm32x4MulDotI16x8:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i32x4_dot_i16x8();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4Add:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i32x4_add();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4Sub:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i32x4_sub();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4Mul:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i32x4_mul();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI32x4Neg:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.i32x4_neg();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2Add:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i64x2_add();
        return w.NumType.v128;
      case StaticIntrinsic.wasmV128Not:
        codeGen.translateExpression(
            node.arguments.positional[0], w.NumType.v128);
        b.v128_not();
        return w.NumType.v128;
      case StaticIntrinsic.wasmV128And:
        codeGen.translateExpression(
            node.arguments.positional[0], w.NumType.v128);
        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.v128);
        b.v128_and();
        return w.NumType.v128;
      case StaticIntrinsic.wasmV128Or:
        codeGen.translateExpression(
            node.arguments.positional[0], w.NumType.v128);
        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.v128);
        b.v128_or();
        return w.NumType.v128;
      case StaticIntrinsic.wasmV128Xor:
        codeGen.translateExpression(
            node.arguments.positional[0], w.NumType.v128);
        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.v128);
        b.v128_xor();
        return w.NumType.v128;
      case StaticIntrinsic.wasmV128AndNot:
        codeGen.translateExpression(
            node.arguments.positional[0], w.NumType.v128);
        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.v128);
        b.v128_andnot();
        return w.NumType.v128;
      case StaticIntrinsic.wasmV128BitSelect:
        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.v128);
        codeGen.translateExpression(
            node.arguments.positional[2], w.NumType.v128);
        codeGen.translateExpression(
            node.arguments.positional[0], w.NumType.v128);
        b.v128_bitselect();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2Sub:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i64x2_sub();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2Mul:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.i64x2_mul();
        return w.NumType.v128;
      case StaticIntrinsic.wasmI64x2Neg:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.i64x2_neg();
        return w.NumType.v128;

      case StaticIntrinsic.wasmF32x4Add:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_add();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Sub:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_sub();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Mul:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_mul();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Div:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_div();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Min:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_min();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Max:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_max();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Neg:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_neg();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Abs:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_abs();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Sqrt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_sqrt();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Lt:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_lt();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Le:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_le();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Gt:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_gt();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Ge:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f32x4_ge();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Ceil:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_ceil();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Floor:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_floor();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Trunc:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_trunc();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF32x4Nearest:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f32x4_nearest();
        return w.NumType.v128;

      case StaticIntrinsic.wasmF64x2Add:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_add();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Sub:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_sub();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Mul:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_mul();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Div:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_div();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Min:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_min();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Max:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_max();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Neg:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_neg();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Abs:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_abs();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Sqrt:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_sqrt();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Ceil:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_ceil();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Floor:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_floor();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Trunc:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_trunc();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Nearest:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.v128);
        b.f64x2_nearest();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Lt:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_lt();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Le:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_le();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Gt:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_gt();
        return w.NumType.v128;
      case StaticIntrinsic.wasmF64x2Ge:
        Expression value1 = node.arguments.positional[0];
        Expression value2 = node.arguments.positional[1];
        codeGen.translateExpression(value1, w.NumType.v128);
        codeGen.translateExpression(value2, w.NumType.v128);
        b.f64x2_ge();
        return w.NumType.v128;

      case StaticIntrinsic.wasmAnyRefFromObject:
      case StaticIntrinsic.wasmFuncRefFromWasmFunction:
      case StaticIntrinsic.wasmEqRefFromObject:
      case StaticIntrinsic.wasmStructRefFromObject:
        Expression value = node.arguments.positional[0];
        w.StorageType targetType = translator.builtinTypes[cls]!;
        w.RefType valueType = targetType as w.RefType;
        codeGen.translateExpression(value, valueType);
        return valueType;
      case StaticIntrinsic.externalizeNonNullable:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.any(nullable: false));
        b.extern_convert_any();
        return w.RefType.extern(nullable: false);
      case StaticIntrinsic.externalizeNullable:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.any(nullable: true));
        b.extern_convert_any();
        return w.RefType.extern(nullable: true);
      case StaticIntrinsic.internalizeNonNullable:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.extern(nullable: false));
        b.any_convert_extern();
        return w.RefType.any(nullable: false);
      case StaticIntrinsic.internalizeNullable:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.extern(nullable: true));
        b.any_convert_extern();
        return w.RefType.any(nullable: true);
      case StaticIntrinsic.wasmExternRefIsNull:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.extern(nullable: true));
        b.ref_is_null();
        return w.NumType.i32;

      // dart:_wasm static functions
      case StaticIntrinsic.isSubClassOf:
        final baseClass =
            (node.arguments.types.single as InterfaceType).classNode;
        final ranges =
            translator.classIdNumbering.getConcreteSubclassRanges(baseClass);

        final object = node.arguments.positional.single;
        codeGen.translateExpression(object, translator.topTypeNonNullable);
        b.loadClassId(translator, translator.topTypeNonNullable);
        b.emitClassIdRangeCheck(ranges);
        return w.NumType.i32;

      case StaticIntrinsic.wasmI31RefNew:
        Expression value = node.arguments.positional[0];
        codeGen.translateExpression(value, w.NumType.i32);
        b.i31_new();
        return w.RefType.i31(nullable: false);

      case StaticIntrinsic.wasmI31RefExtensionsExternalize:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.i31(nullable: false));
        b.extern_convert_any();
        return w.RefType.extern(nullable: false);

      case StaticIntrinsic.wasmI31RefExtensionsGetS:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.i31(nullable: false));
        b.i31_get_s();
        return w.NumType.i32;

      case StaticIntrinsic.wasmI31RefExtensionsGetU:
        final value = node.arguments.positional.single;
        codeGen.translateExpression(value, w.RefType.i31(nullable: false));
        b.i31_get_u();
        return w.NumType.i32;

      case StaticIntrinsic.wasmMemorySize:
        final memory = _extractMemoryFromCall(node, b);
        b.memory_size(memory);
        // Unsigned because memory sizes can't be negative.
        b.i64_extend_i32_u();
        return w.NumType.i64;
      case StaticIntrinsic.wasmMemoryGrow:
        final memory = _extractMemoryFromCall(node, b);
        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.i64);
        b.i32_wrap_i64();
        b.memory_grow(memory);
        // Signed because memory.grow returns -1 on failure.
        b.i64_extend_i32_s();
        return w.NumType.i64;
      case StaticIntrinsic.wasmMemoryFill:
        final memory = _extractMemoryFromCall(node, b);
        // The positional arguments in Dart are value, startOffset, length. The
        // stack for memory_fill needs to be [..., start, value, length] though.
        final [_, value, start, length] = node.arguments.positional;
        codeGen.translateExpression(value, w.NumType.i32);
        codeGen.translateExpression(start, w.NumType.i64);
        b.i32_wrap_i64();
        final startVar = b.addLocal(w.NumType.i32);
        final valueVar = b.addLocal(w.NumType.i32);

        b
          ..local_set(startVar)
          ..local_set(valueVar)
          ..local_get(startVar)
          ..local_get(valueVar);
        codeGen.translateExpression(length, w.NumType.i64);
        b.i32_wrap_i64();
        b.memory_fill(memory);
        return codeGen.voidMarker;
      case StaticIntrinsic.wasmMemoryLoadFloat32:
      case StaticIntrinsic.wasmMemoryLoadFloat64:
      case StaticIntrinsic.wasmMemoryLoadInt8:
      case StaticIntrinsic.wasmMemoryLoadInt16:
      case StaticIntrinsic.wasmMemoryLoadInt32:
      case StaticIntrinsic.wasmMemoryLoadInt64:
      case StaticIntrinsic.wasmMemoryLoadUint8:
      case StaticIntrinsic.wasmMemoryLoadUint16:
      case StaticIntrinsic.wasmMemoryLoadUint32:
        final (:memory, :align, :offset) = _extractMemoryOperands(node, b);

        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.i64);
        b.i32_wrap_i64();

        switch (intrinsic) {
          case StaticIntrinsic.wasmMemoryLoadFloat32:
            b.f32_load(memory, offset, align);
            return w.NumType.f32;
          case StaticIntrinsic.wasmMemoryLoadFloat64:
            b.f64_load(memory, offset, align);
            return w.NumType.f64;
          case StaticIntrinsic.wasmMemoryLoadInt8:
            b.i32_load8_s(memory, offset, align);
            return w.NumType.i32;
          case StaticIntrinsic.wasmMemoryLoadInt16:
            b.i32_load16_s(memory, offset, align);
            return w.NumType.i32;
          case StaticIntrinsic.wasmMemoryLoadInt32:
            b.i32_load(memory, offset, align);
            return w.NumType.i32;
          case StaticIntrinsic.wasmMemoryLoadInt64:
            b.i64_load(memory, offset, align);
            return w.NumType.i64;
          case StaticIntrinsic.wasmMemoryLoadUint8:
            b.i32_load8_u(memory, offset, align);
            return w.NumType.i32;
          case StaticIntrinsic.wasmMemoryLoadUint16:
            b.i32_load16_u(memory, offset, align);
            return w.NumType.i32;
          case StaticIntrinsic.wasmMemoryLoadUint32:
            b.i32_load(memory, offset, align);
            return w.NumType.i32;
          default:
            throw AssertionError('unreachable');
        }
      case StaticIntrinsic.wasmMemoryStoreFloat32:
      case StaticIntrinsic.wasmMemoryStoreFloat64:
      case StaticIntrinsic.wasmMemoryStoreInt8:
      case StaticIntrinsic.wasmMemoryStoreInt16:
      case StaticIntrinsic.wasmMemoryStoreInt32:
      case StaticIntrinsic.wasmMemoryStoreInt64:
        final (:memory, :align, :offset) = _extractMemoryOperands(node, b);

        codeGen.translateExpression(
            node.arguments.positional[1], w.NumType.i64);
        b.i32_wrap_i64();
        final valueExpression = node.arguments.positional[2];

        switch (intrinsic) {
          case StaticIntrinsic.wasmMemoryStoreFloat32:
            codeGen.translateExpression(valueExpression, w.NumType.f32);
            b.f32_store(memory, offset, align);
          case StaticIntrinsic.wasmMemoryStoreFloat64:
            codeGen.translateExpression(valueExpression, w.NumType.f64);
            b.f64_store(memory, offset, align);
          case StaticIntrinsic.wasmMemoryStoreInt8:
            codeGen.translateExpression(valueExpression, w.NumType.i32);
            b.i32_store8(memory, offset, align);
          case StaticIntrinsic.wasmMemoryStoreInt16:
            codeGen.translateExpression(valueExpression, w.NumType.i32);
            b.i32_store16(memory, offset, align);
          case StaticIntrinsic.wasmMemoryStoreInt32:
            codeGen.translateExpression(valueExpression, w.NumType.i32);
            b.i32_store(memory, offset, align);
          case StaticIntrinsic.wasmMemoryStoreInt64:
            codeGen.translateExpression(valueExpression, w.NumType.i64);
            b.i64_store(memory, offset, align);
          default:
            throw AssertionError('unreachable');
        }

        return codeGen.voidMarker;
    }
  }

  /// Generate inline code for a [ConstructorInvocation] if the constructor is
  /// an inlined intrinsic.
  w.ValueType? generateConstructorIntrinsic(ConstructorInvocation node) {
    String name = node.name.text;

    // WasmArray.literal
    final klass = node.target.enclosingClass;
    if ((klass == translator.wasmArrayClass ||
            klass == translator.immutableWasmArrayClass) &&
        name == "literal") {
      final dartWasmArrayType = InterfaceType(node.target.enclosingClass,
          Nullability.nonNullable, node.arguments.types);
      final w.ArrayType arrayType =
          (translator.translateType(dartWasmArrayType) as w.RefType).heapType
              as w.ArrayType;

      w.ValueType elementType = arrayType.elementType.type.unpacked;
      Expression value = node.arguments.positional[0];
      List<Expression> elements = value is ListLiteral
          ? value.expressions
          : value is ConstantExpression && value.constant is ListConstant
              ? (value.constant as ListConstant)
                  .entries
                  .map(ConstantExpression.new)
                  .toList()
              : throw "WasmArray.literal argument is not a list literal"
                  " at ${value.location}";
      for (Expression element in elements) {
        codeGen.translateExpression(element, elementType);
      }
      b.array_new_fixed(arrayType, elements.length);
      return w.RefType.def(arrayType, nullable: false);
    }

    return null;
  }

  /// Generate inline code for a [FunctionInvocation] if the function is an
  /// inlined intrinsic.
  w.ValueType? generateFunctionCallIntrinsic(FunctionInvocation node) {
    Expression receiver = node.receiver;

    if (receiver is InstanceGet &&
        receiver.interfaceTarget == translator.wasmFunctionCall) {
      // Receiver is a WasmFunction
      assert(receiver.name.text == "call");
      w.RefType receiverType =
          translator.translateType(dartTypeOf(receiver.receiver)) as w.RefType;
      w.Local temp = b.addLocal(receiverType);
      codeGen.translateExpression(receiver.receiver, receiverType);
      b.local_set(temp);
      w.FunctionType functionType = receiverType.heapType as w.FunctionType;
      assert(node.arguments.positional.length == functionType.inputs.length);
      for (int i = 0; i < node.arguments.positional.length; i++) {
        codeGen.translateExpression(
            node.arguments.positional[i], functionType.inputs[i]);
      }
      b.local_get(temp);
      b.call_ref(functionType);
      return translator.outputOrVoid(functionType.outputs);
    }

    if (receiver is InstanceInvocation &&
        receiver.interfaceTarget == translator.wasmTableCallIndirect) {
      // Receiver is a WasmTable.callIndirect
      assert(receiver.name.text == "callIndirect");
      Expression tableExp = receiver.receiver;
      if (tableExp is! StaticGet || tableExp.target is! Field) {
        throw "Table callIndirect not directly on a static field"
            " at ${node.location}";
      }
      w.Table table =
          translator.getTable(b.moduleBuilder, tableExp.target as Field)!;
      InterfaceType wasmFunctionType = InterfaceType(
          translator.wasmFunctionClass,
          Nullability.nonNullable,
          [receiver.arguments.types.single]);
      w.RefType receiverType =
          translator.translateType(wasmFunctionType) as w.RefType;
      w.Local tableIndex = b.addLocal(w.NumType.i32);
      codeGen.translateExpression(
          receiver.arguments.positional.single, w.NumType.i32);
      b.local_set(tableIndex);
      w.FunctionType functionType = receiverType.heapType as w.FunctionType;
      assert(node.arguments.positional.length == functionType.inputs.length);
      for (int i = 0; i < node.arguments.positional.length; i++) {
        codeGen.translateExpression(
            node.arguments.positional[i], functionType.inputs[i]);
      }
      b.local_get(tableIndex);
      b.call_indirect(functionType, table);
      return translator.outputOrVoid(functionType.outputs);
    }

    return null;
  }

  /// Generate Wasm function for an intrinsic member.
  bool generateMemberIntrinsic(Reference target, w.FunctionType functionType,
      List<w.Local> paramLocals, w.Label? returnLabel) {
    Member member = target.asMember;
    if (member is! Procedure) return false;
    final intrinsic =
        MemberIntrinsic.fromProcedure(translator.coreTypes, member);
    if (intrinsic == null) return false;

    switch (intrinsic) {
      case MemberIntrinsic.objectEquals:
        b.local_get(paramLocals[0]);
        b.local_get(paramLocals[1]);
        b.ref_eq();

      case MemberIntrinsic.objectRuntimeType:
        // Simple redirect to `_getMasqueradedRuntimeType`. This is done to keep
        // `Object.runtimeType` external. If `Object.runtimeType` is implemented
        // in Dart, the TFA will conclude that `null.runtimeType` never returns,
        // since it dispatches to `Object.runtimeType`, which uses the receiver
        // as non-nullable.
        w.Local receiver = paramLocals[0];
        b.local_get(receiver);
        codeGen.call(translator.getMasqueradedRuntimeType.reference);

      // identical
      case MemberIntrinsic.identical:
        w.Local first = paramLocals[0];
        w.Local second = paramLocals[1];
        ClassInfo intInfo = translator.classInfo[translator.boxedIntClass]!;
        ClassInfo doubleInfo =
            translator.classInfo[translator.boxedDoubleClass]!;
        w.Local cid = b.addLocal(w.NumType.i32);

        // If the references are identical, return true.
        b.local_get(first);
        b.local_get(second);
        b.ref_eq();
        b.if_();
        b.i32_const(1);
        b.return_();
        b.end();

        w.Label fail = b.block();

        // If either is `null`, or their class IDs are different, return false.
        b.local_get(first);
        b.br_on_null(fail);
        b.loadClassId(translator, translator.topTypeNonNullable);
        b.local_tee(cid);
        b.local_get(second);
        b.br_on_null(fail);
        b.loadClassId(translator, translator.topTypeNonNullable);
        b.i32_ne();
        b.br_if(fail);

        // Cannot be equal `bool`s as we have unique singleton objects for `true`
        // and `false`. If they were equal bools we would have triggered the
        // reference equality above.

        // Both int?
        b.local_get(cid);
        b.i32_const((intInfo.classId as AbsoluteClassId).value);
        b.i32_eq();
        b.if_();
        b.local_get(first);
        b.ref_cast(intInfo.nonNullableType);
        b.struct_get(intInfo.struct, FieldIndex.boxValue);
        b.local_get(second);
        b.ref_cast(intInfo.nonNullableType);
        b.struct_get(intInfo.struct, FieldIndex.boxValue);
        b.i64_eq();
        b.return_();
        b.end();

        // Both double?
        b.local_get(cid);
        b.i32_const((doubleInfo.classId as AbsoluteClassId).value);
        b.i32_eq();
        b.if_();
        b.local_get(first);
        b.ref_cast(doubleInfo.nonNullableType);
        b.struct_get(doubleInfo.struct, FieldIndex.boxValue);
        b.i64_reinterpret_f64();
        b.local_get(second);
        b.ref_cast(doubleInfo.nonNullableType);
        b.struct_get(doubleInfo.struct, FieldIndex.boxValue);
        b.i64_reinterpret_f64();
        b.i64_eq();
        b.return_();
        b.end();

        // Not identical
        b.end(); // fail
        b.i32_const(0);

      // _Closure._getClosureRuntimeType
      case MemberIntrinsic.closureRuntimeType:
        final w.Local object = paramLocals[0];
        w.StructType closureBase = translator.closureLayouter.closureBaseStruct;
        b.local_get(object);
        b.ref_cast(w.RefType.def(closureBase, nullable: false));
        b.struct_get(closureBase, FieldIndex.closureRuntimeType);

      case MemberIntrinsic.identityHashCode:
        final w.Local arg = paramLocals[0];
        final w.Local nonNullArg = b.addLocal(translator.topTypeNonNullable);
        final List<int> classIds = translator.valueClasses.keys
            .map((cls) =>
                (translator.classInfo[cls]!.classId as AbsoluteClassId).value)
            .toList()
          ..sort();

        // If the argument is `null`, return the hash code of `null`.
        final w.Label notNull =
            b.block(const [], [translator.topTypeNonNullable]);
        b.local_get(arg);
        b.br_on_non_null(notNull);
        b.i64_const(null.hashCode);
        b.return_();
        b.end(); // notNull
        b.local_set(nonNullArg);

        // Branch on class ID.
        final w.Label defaultLabel = b.block();
        final List<w.Label> labels =
            List.generate(classIds.length, (_) => b.block());
        b.local_get(nonNullArg);
        b.loadClassId(translator, translator.topTypeNonNullable);
        int labelIndex = 0;
        final List<w.Label> targets = List.generate(classIds.last + 1, (id) {
          return id == classIds[labelIndex]
              ? labels[labelIndex++]
              : defaultLabel;
        });
        b.br_table(targets, defaultLabel);

        // For value classes, dispatch to their `hashCode` implementation.
        for (final int id in classIds.reversed) {
          final Class cls =
              translator.valueClasses[translator.classes[id].cls!]!;
          final Procedure hashCodeProcedure =
              cls.procedures.firstWhere((p) => p.name.text == "hashCode");
          b.end(); // Jump target for class ID
          b.local_get(nonNullArg);
          codeGen.call(hashCodeProcedure.reference);
          b.return_();
        }

        // For all other classes, dispatch to the `hashCode` implementation in
        // `Object`.
        b.end(); // defaultLabel
        b.local_get(nonNullArg);
        codeGen.call(translator.objectHashCode.reference);

      // _typeArguments
      case MemberIntrinsic.typeArguments:
        Class cls = member.enclosingClass!;
        ClassInfo classInfo = translator.classInfo[cls]!;
        w.ArrayType arrayType =
            (functionType.outputs.single as w.RefType).heapType as w.ArrayType;
        w.Local object = paramLocals[0];
        w.Local preciseObject =
            codeGen.addLocal(classInfo.nonNullableType, name: "this");
        b.local_get(object);
        b.ref_cast(classInfo.nonNullableType);
        b.local_set(preciseObject);
        for (int i = 0; i < cls.typeParameters.length; i++) {
          TypeParameter typeParameter = cls.typeParameters[i];
          int typeParameterIndex =
              translator.typeParameterIndex[typeParameter]!;
          b.local_get(preciseObject);
          b.struct_get(classInfo.struct, typeParameterIndex);
        }
        b.array_new_fixed(arrayType, cls.typeParameters.length);

      // int members
      case MemberIntrinsic.intAdd:
      case MemberIntrinsic.intSub:
      case MemberIntrinsic.intMul:
      case MemberIntrinsic.intAnd:
      case MemberIntrinsic.intOr:
      case MemberIntrinsic.intXor:
      case MemberIntrinsic.intLt:
      case MemberIntrinsic.intGt:
      case MemberIntrinsic.intGe:
      case MemberIntrinsic.intLe:
      case MemberIntrinsic.intNeg:
      case MemberIntrinsic.intInv:
      case MemberIntrinsic.intToDouble:
        final functionNode = member.function;
        String op = member.name.text;
        if (functionNode.requiredParameterCount == 0) {
          CodeGenCallback? code = _unaryOperatorMap[intType]![op];
          if (code != null) {
            w.ValueType resultType = _unaryResultMap[op] ?? intType;
            w.ValueType inputType = functionType.inputs.single;
            w.ValueType outputType = functionType.outputs.single;
            b.local_get(paramLocals[0]);
            translator.convertType(b, inputType, intType);
            code(codeGen);
            translator.convertType(b, resultType, outputType);
            return true;
          }
        } else if (functionNode.requiredParameterCount == 1) {
          CodeGenCallback? code = _binaryOperatorMap[intType]![intType]![op];
          if (code != null) {
            w.ValueType leftType = functionType.inputs[0];
            w.ValueType rightType = functionType.inputs[1];
            w.ValueType outputType = functionType.outputs.single;
            if (rightType == intType) {
              // int parameter
              b.local_get(paramLocals[0]);
              translator.convertType(b, leftType, intType);
              b.local_get(paramLocals[1]);
              code(codeGen);
              if (!isComparison(op)) {
                translator.convertType(b, intType, outputType);
              }
              return true;
            }
            // num parameter
            ClassInfo intInfo = translator.classInfo[translator.boxedIntClass]!;
            w.Label intArg = b.block(const [], [intInfo.nonNullableType]);
            b.local_get(paramLocals[1]);
            b.br_on_cast(intArg, paramLocals[1].type as w.RefType,
                intInfo.nonNullableType);
            // double argument
            b.drop();
            b.local_get(paramLocals[0]);
            translator.convertType(b, leftType, intType);
            b.f64_convert_i64_s();
            b.local_get(paramLocals[1]);
            translator.convertType(b, rightType, doubleType);
            // Inline double op
            CodeGenCallback doubleCode =
                _binaryOperatorMap[doubleType]![doubleType]![op]!;
            doubleCode(codeGen);
            if (!isComparison(op)) {
              translator.convertType(b, doubleType, outputType);
            }
            b.return_();
            b.end();
            // int argument
            translator.convertType(b, intInfo.nonNullableType, intType);
            w.Local rightTemp = b.addLocal(intType);
            b.local_set(rightTemp);
            b.local_get(paramLocals[0]);
            translator.convertType(b, leftType, intType);
            b.local_get(rightTemp);
            code(codeGen);
            if (!isComparison(op)) {
              translator.convertType(b, intType, outputType);
            }
            return true;
          }
        }

      // double unary members
      case MemberIntrinsic.doubleNeg:
      case MemberIntrinsic.doubleFloorToDouble:
      case MemberIntrinsic.doubleCeilToDouble:
      case MemberIntrinsic.doubleTruncateToDouble:
        final op = member.name.text;
        CodeGenCallback? code = _unaryOperatorMap[doubleType]![op]!;
        w.ValueType resultType = _unaryResultMap[op] ?? doubleType;
        w.ValueType inputType = functionType.inputs.single;
        w.ValueType outputType = functionType.outputs.single;
        b.local_get(paramLocals[0]);
        translator.convertType(b, inputType, doubleType);
        code(codeGen);
        translator.convertType(b, resultType, outputType);

      case MemberIntrinsic.isInstantiationClosure:
        assert(paramLocals.length == 1);
        b.local_get(paramLocals[0]); // ref _Closure
        b.emitInstantiationClosureCheck(translator);

      case MemberIntrinsic.instantiatedClosure:
        assert(paramLocals.length == 1);
        b.local_get(paramLocals[0]); // ref _Closure
        b.emitGetInstantiatedClosure(translator);

      case MemberIntrinsic.instantiationClosureTypeHash:
        assert(paramLocals.length == 1);

        // Instantiation context, to be passed to the hash function.
        b.local_get(paramLocals[0]); // ref _Closure
        b.ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
            nullable: false));
        b.struct_get(translator.closureLayouter.closureBaseStruct,
            FieldIndex.closureContext);
        b.ref_cast(w.RefType(
            translator.closureLayouter.instantiationContextBaseStruct,
            nullable: false));

        // Hash function.
        b.local_get(paramLocals[0]); // ref _Closure
        b.emitGetInstantiatedClosure(translator);
        b.emitGetClosureVtable(translator);
        b.ref_cast(w.RefType.def(
            translator.closureLayouter.genericVtableBaseStruct,
            nullable: false));
        b.struct_get(
            translator.closureLayouter.genericVtableBaseStruct,
            translator
                .closureLayouter.vtableInstantiationTypeHashFunctionIndex);
        b.call_ref(translator
            .closureLayouter.instantiationClosureTypeHashFunctionType);

      case MemberIntrinsic.instantiationClosureTypeEquals:
        assert(paramLocals.length == 2);

        final w.StructType closureBaseStruct =
            translator.closureLayouter.closureBaseStruct;

        final w.RefType instantiationContextBase = w.RefType(
            translator.closureLayouter.instantiationContextBaseStruct,
            nullable: false);

        b.local_get(paramLocals[0]); // ref _Closure
        b.ref_cast(w.RefType(closureBaseStruct, nullable: false));
        b.struct_get(closureBaseStruct, FieldIndex.closureContext);
        b.ref_cast(instantiationContextBase);

        b.local_get(paramLocals[1]); // ref _Closure
        b.ref_cast(w.RefType(closureBaseStruct, nullable: false));
        b.struct_get(closureBaseStruct, FieldIndex.closureContext);
        b.ref_cast(instantiationContextBase);

        b.local_get(paramLocals[0]);
        b.emitGetInstantiatedClosure(translator);
        b.emitGetClosureVtable(translator);
        b.ref_cast(w.RefType.def(
            translator.closureLayouter.genericVtableBaseStruct,
            nullable: false));

        final vtableIndex = translator
            .closureLayouter.vtableInstantiationTypeComparisonFunctionIndex;
        b.struct_get(
            translator.closureLayouter.genericVtableBaseStruct, vtableIndex);
        b.call_ref(translator
            .closureLayouter.instantiationClosureTypeComparisonFunctionType);

      case MemberIntrinsic.isInstanceTearOff:
        assert(paramLocals.length == 1);
        b.local_get(paramLocals[0]); // ref _Closure
        b.emitTearOffCheck(translator);

      case MemberIntrinsic.instanceTearOffReceiver:
        assert(paramLocals.length == 1);
        b.local_get(paramLocals[0]); // ref _Closure
        b.emitGetTearOffReceiver(translator);

      case MemberIntrinsic.vtable:
        assert(paramLocals.length == 1);
        b.local_get(paramLocals[0]); // ref _Closure
        b.emitGetClosureVtable(translator);

      case MemberIntrinsic.functionApply:
        assert(functionType.inputs.length == 3);

        final closureLocal = paramLocals[0]; // ref #ClosureBase
        final posArgsNullableLocal = paramLocals[1]; // ref null Object
        final namedArgsLocal = paramLocals[2]; // ref null Object

        // Create empty type arguments array.
        final typeArgsLocal = b.addLocal(translator.makeArray(
            b, translator.typeArrayType, 0, (elementType, elementIndex) {}));
        b.local_set(typeArgsLocal);

        // Create empty list for positional args if the argument is null
        final posArgsLocal = b.addLocal(translator.nullableObjectArrayTypeRef);
        b.local_get(posArgsNullableLocal);
        b.ref_is_null();

        b.if_([], [translator.nullableObjectArrayTypeRef]);
        translator.makeArray(
            b, translator.nullableObjectArrayType, 0, (_, __) {});

        b.else_();
        // List argument may be a custom list type, convert it to `WasmListBase`
        // with `WasmListBase.of`.
        translator.constants.instantiateConstant(
          b,
          TypeLiteralConstant(DynamicType()),
          translator.types.nonNullableTypeType,
        );
        b.local_get(posArgsNullableLocal);
        b.ref_as_non_null();
        codeGen.call(translator.listOf.reference);
        translator.getListBaseArray(b);
        b.end();
        b.local_set(posArgsLocal);

        // Convert named argument map to array, to be passed to shape and type
        // checkers and the dynamic call entry.
        final namedArgsListLocal =
            b.addLocal(translator.nullableObjectArrayTypeRef);
        b.local_get(namedArgsLocal);
        b.local_get(closureLocal);
        codeGen.call(translator.namedParameterMapToArray.reference);
        b.local_set(namedArgsListLocal);

        final noSuchMethodBlock = b.block();

        generateDynamicClosureCallShapeAndTypeCheck(translator, b, closureLocal,
            typeArgsLocal, posArgsLocal, namedArgsListLocal, noSuchMethodBlock);
        if (translator.dynamicModuleSupportEnabled ||
            translator.closureLayouter.usesFunctionApplyWithNamedArguments) {
          generateDynamicClosureCallViaDynamicEntry(translator, b, closureLocal,
              typeArgsLocal, posArgsLocal, namedArgsListLocal);
        } else {
          if (compilerAssertsEnabled) {
            final good = b.block();
            b.local_get(namedArgsListLocal);
            b.array_len();
            b.i32_eqz();
            b.br_if(good);
            b.unreachable();
            b.end();
          }
          generateDynamicClosureCallViaPositionalArgs(
              translator, b, closureLocal, typeArgsLocal, posArgsLocal);
        }
        b.return_();

        b.end(); // noSuchMethodBlock

        generateNoSuchMethodCall(
            translator,
            b,
            () => b.local_get(closureLocal),
            () => createInvocationObject(translator, b, Name('call'),
                typeArgsLocal, posArgsLocal, namedArgsListLocal));

      // Error._throw
      case MemberIntrinsic.errorThrow:
        final objectLocal = paramLocals[0]; // ref #Top
        final stackTraceLocal = paramLocals[1]; // ref Object

        final notErrorBlock = b.block([], [objectLocal.type]);

        final errorClassInfo = translator.classInfo[translator.errorClass]!;
        final errorRefType = errorClassInfo.nonNullableType;
        final stackTraceFieldIndex =
            translator.fieldIndex[translator.errorClassStackTraceField]!;
        b.local_get(objectLocal);
        b.br_on_cast_fail(
            notErrorBlock, objectLocal.type as w.RefType, errorRefType);

        final errorLocal = b.addLocal(errorRefType);
        b.local_tee(errorLocal);

        b.struct_get(errorClassInfo.struct, stackTraceFieldIndex);
        b.ref_is_null();
        b.if_();
        b.local_get(errorLocal);
        b.local_get(stackTraceLocal);
        b.struct_set(errorClassInfo.struct, stackTraceFieldIndex);
        b.end();

        b.local_get(objectLocal);
        b.end(); // notErrorBlock

        b.local_get(stackTraceLocal);
        b.throw_(translator.getDartExceptionTag(b.moduleBuilder));

      case MemberIntrinsic.nullRef:
        b.ref_null(w.HeapType.noextern);
    }

    return true;
  }

  w.ValueType readIntArray(StaticInvocation node, {required bool unsigned}) {
    final dartWasmArrayType = dartTypeOf(node.arguments.positional.first);
    final w.ArrayType arrayType =
        (translator.translateType(dartWasmArrayType) as w.RefType).heapType
            as w.ArrayType;
    final w.FieldType fieldType = arrayType.elementType;
    final w.StorageType wasmType = fieldType.type;

    final innerExtend =
        wasmType == w.PackedType.i8 || wasmType == w.PackedType.i16;
    final outerExtend =
        wasmType.unpacked == w.NumType.i32 || wasmType == w.NumType.f32;
    final array = node.arguments.positional[0];
    final index = node.arguments.positional[1];
    codeGen.translateExpression(
        array, w.RefType.def(arrayType, nullable: false));
    codeGen.translateExpression(index, w.NumType.i64);
    b.i32_wrap_i64();
    if (innerExtend) {
      if (unsigned) {
        b.array_get_u(arrayType);
      } else {
        b.array_get_s(arrayType);
      }
    } else {
      b.array_get(arrayType);
    }
    if (outerExtend) {
      if (wasmType == w.NumType.f32) {
        b.f64_promote_f32();
        return w.NumType.f64;
      } else {
        if (unsigned) {
          b.i64_extend_i32_u();
        } else {
          b.i64_extend_i32_s();
        }
        return w.NumType.i64;
      }
    }
    return wasmType.unpacked;
  }

  /// Extracts the memory instance for an intrinsic call on a memory extension.
  w.Memory _extractMemoryFromCall(
      Expression expr, w.InstructionsBuilder builder) {
    // All validated memory calls look like MemoryAccessExtension|size(memory)
    final memory =
        (expr as StaticInvocation).arguments.positional[0] as StaticGet;
    return translator.findMemory(
        memory.target as Procedure, builder.moduleBuilder);
  }

  ({w.Memory memory, int offset, int align}) _extractMemoryOperands(
      StaticInvocation call, w.InstructionsBuilder builder) {
    final memory = _extractMemoryFromCall(call, builder);
    var align = 0;
    var offset = 0;

    for (final NamedExpression(:name, :value) in call.arguments.named) {
      // align and offset are verified to be compile-time constants in
      // wasm_library_checks.dart
      if (name == 'align') {
        align = extractIntValue(value)!;
      } else if (name == 'offset') {
        offset = extractIntValue(value)!;
      } else {
        throw UnsupportedError('Unhandled named argument: $name');
      }
    }

    return (memory: memory, align: align, offset: offset);
  }
}

int? extractIntValue(Expression expr) {
  if (expr is IntLiteral) {
    return expr.value;
  }

  if (expr is ConstantExpression) {
    final constant = expr.constant;
    if (constant is IntConstant) {
      return constant.value;
    }
  }

  return null;
}

double? _extractDoubleValue(Expression expr) {
  if (expr is DoubleLiteral) {
    return expr.value;
  }

  if (expr is ConstantExpression) {
    final constant = expr.constant;
    if (constant is DoubleConstant) {
      return constant.value;
    }
  }

  return null;
}
