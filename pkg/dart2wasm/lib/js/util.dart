// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart'
    show ExtensionIndex;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

enum AnnotationType { import, export, weakExport }

/// A utility wrapper for [CoreTypes].
class CoreTypesUtil {
  final ExtensionIndex extensionIndex;
  final CoreTypes coreTypes;
  final Procedure allowInteropTarget;
  final Procedure dartifyRawTarget;
  final Procedure functionToJSTarget;
  final Procedure functionToJSCaptureThisTarget;
  final Procedure greaterThanOrEqualToTarget;
  final Procedure inlineJSTarget;
  final Procedure isDartFunctionWrappedTarget;
  final Procedure jsifyRawTarget;
  final Procedure jsObjectFromDartObjectTarget;
  final Class jsValueClass;
  final Procedure jsValueBoxTarget;
  final Procedure jsValueUnboxTarget;
  final Procedure numToIntTarget;
  final Class wasmExternRefClass;
  final Class wasmArrayClass;
  final Class wasmArrayRefClass;
  final Procedure wrapDartFunctionTarget;
  final Procedure exportWasmFunctionTarget;
  final Member wasmExternRefNullRef;

  // Dart value to JS converters.
  final Procedure toJSBoolean;
  final Procedure jsifyInt;
  final Procedure toJSNumber;
  final Procedure jsifyNum;
  final Procedure jsifyJSValue;
  final Procedure jsifyString;
  final Procedure jsifyJSInt8ArrayImpl;
  final Procedure jsifyJSUint8ArrayImpl;
  final Procedure jsifyJSUint8ClampedArrayImpl;
  final Procedure jsifyJSInt16ArrayImpl;
  final Procedure jsifyJSUint16ArrayImpl;
  final Procedure jsifyJSInt32ArrayImpl;
  final Procedure jsifyJSUint32ArrayImpl;
  final Procedure jsifyJSFloat32ArrayImpl;
  final Procedure jsifyJSFloat64ArrayImpl;
  final Procedure jsInt8ArrayFromDartInt8List;
  final Procedure jsUint8ArrayFromDartUint8List;
  final Procedure jsUint8ClampedArrayFromDartUint8ClampedList;
  final Procedure jsInt16ArrayFromDartInt16List;
  final Procedure jsUint16ArrayFromDartUint16List;
  final Procedure jsInt32ArrayFromDartInt32List;
  final Procedure jsUint32ArrayFromDartUint32List;
  final Procedure jsFloat32ArrayFromDartFloat32List;
  final Procedure jsFloat64ArrayFromDartFloat64List;
  final Procedure jsifyJSDataViewImpl; // JS ByteData
  final Procedure jsifyByteData; // Wasm ByteData
  final Procedure jsifyRawList;
  final Procedure jsifyJSArrayBufferImpl; // JS ByteBuffer
  final Procedure jsArrayBufferFromDartByteBuffer; // Wasm ByteBuffer
  final Procedure jsifyFunction;
  final Procedure internalizeNullable;

  // Classes used in type tests for the converters.
  final Class jsInt8ArrayImplClass;
  final Class jsUint8ArrayImplClass;
  final Class jsUint8ClampedArrayImplClass;
  final Class jsInt16ArrayImplClass;
  final Class jsUint16ArrayImplClass;
  final Class jsInt32ArrayImplClass;
  final Class jsUint32ArrayImplClass;
  final Class jsFloat32ArrayImplClass;
  final Class jsFloat64ArrayImplClass;
  final Class int8ListClass;
  final Class uint8ListClass;
  final Class uint8ClampedListClass;
  final Class int16ListClass;
  final Class uint16ListClass;
  final Class int32ListClass;
  final Class uint32ListClass;
  final Class float32ListClass;
  final Class float64ListClass;
  final Class jsDataViewImplClass;
  final Class byteDataClass;
  final Class jsArrayBufferImplClass;
  final Class byteBufferClass;

  CoreTypesUtil(this.coreTypes, this.extensionIndex)
      : allowInteropTarget = coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'allowInterop'),
        dartifyRawTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'dartifyRaw'),
        functionToJSTarget = coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        functionToJSCaptureThisTarget = coreTypes.index.getTopLevelProcedure(
            'dart:js_interop',
            'FunctionToJSExportedDartFunction|get#toJSCaptureThis'),
        greaterThanOrEqualToTarget =
            coreTypes.index.getProcedure('dart:core', 'num', '>='),
        inlineJSTarget =
            coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'JS'),
        isDartFunctionWrappedTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_isDartFunctionWrapped'),
        numToIntTarget =
            coreTypes.index.getProcedure('dart:core', 'num', 'toInt'),
        jsifyRawTarget =
            coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'jsifyRaw'),
        jsObjectFromDartObjectTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsObjectFromDartObject'),
        jsValueBoxTarget =
            coreTypes.index.getProcedure('dart:_js_helper', 'JSValue', 'box'),
        jsValueClass = coreTypes.index.getClass('dart:_js_helper', 'JSValue'),
        jsValueUnboxTarget =
            coreTypes.index.getProcedure('dart:_js_helper', 'JSValue', 'unbox'),
        wasmExternRefClass =
            coreTypes.index.getClass('dart:_wasm', 'WasmExternRef'),
        wasmExternRefNullRef = coreTypes.index
            .getMember('dart:_wasm', 'WasmExternRef', 'get:nullRef'),
        wasmArrayClass = coreTypes.index.getClass('dart:_wasm', 'WasmArray'),
        wasmArrayRefClass =
            coreTypes.index.getClass('dart:_wasm', 'WasmArrayRef'),
        wrapDartFunctionTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_wrapDartFunction'),
        exportWasmFunctionTarget = coreTypes.index
            .getTopLevelProcedure('dart:_internal', 'exportWasmFunction'),
        toJSBoolean = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'toJSBoolean'),
        jsifyInt =
            coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'jsifyInt'),
        toJSNumber = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'toJSNumber'),
        jsifyNum =
            coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'jsifyNum'),
        jsifyJSValue = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSValue'),
        jsifyString = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyString'),
        jsifyJSInt8ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSInt8ArrayImpl'),
        jsifyJSUint8ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSUint8ArrayImpl'),
        jsifyJSUint8ClampedArrayImpl = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsifyJSUint8ClampedArrayImpl'),
        jsifyJSInt16ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSInt16ArrayImpl'),
        jsifyJSUint16ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSUint16ArrayImpl'),
        jsifyJSInt32ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSInt32ArrayImpl'),
        jsifyJSUint32ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSUint32ArrayImpl'),
        jsifyJSFloat32ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSFloat32ArrayImpl'),
        jsifyJSFloat64ArrayImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSFloat64ArrayImpl'),
        jsInt8ArrayFromDartInt8List = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsInt8ArrayFromDartInt8List'),
        jsUint8ArrayFromDartUint8List = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsUint8ArrayFromDartUint8List'),
        jsUint8ClampedArrayFromDartUint8ClampedList = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper',
                'jsUint8ClampedArrayFromDartUint8ClampedList'),
        jsInt16ArrayFromDartInt16List = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsInt16ArrayFromDartInt16List'),
        jsUint16ArrayFromDartUint16List = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsUint16ArrayFromDartUint16List'),
        jsInt32ArrayFromDartInt32List = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsInt32ArrayFromDartInt32List'),
        jsUint32ArrayFromDartUint32List = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsUint32ArrayFromDartUint32List'),
        jsFloat32ArrayFromDartFloat32List = coreTypes.index
            .getTopLevelProcedure(
                'dart:_js_helper', 'jsFloat32ArrayFromDartFloat32List'),
        jsFloat64ArrayFromDartFloat64List = coreTypes.index
            .getTopLevelProcedure(
                'dart:_js_helper', 'jsFloat64ArrayFromDartFloat64List'),
        jsifyJSDataViewImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSDataViewImpl'),
        jsifyByteData = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyByteData'),
        jsifyRawList = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_jsifyRawList'),
        jsifyJSArrayBufferImpl = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyJSArrayBufferImpl'),
        jsArrayBufferFromDartByteBuffer = coreTypes.index.getTopLevelProcedure(
            'dart:_js_helper', 'jsArrayBufferFromDartByteBuffer'),
        jsifyFunction = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyFunction'),
        internalizeNullable = coreTypes.index
            .getTopLevelProcedure('dart:_wasm', '_internalizeNullable'),
        jsInt8ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSInt8ArrayImpl'),
        jsUint8ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSUint8ArrayImpl'),
        jsUint8ClampedArrayImplClass = coreTypes.index
            .getClass('dart:_js_types', 'JSUint8ClampedArrayImpl'),
        jsInt16ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSInt16ArrayImpl'),
        jsUint16ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSUint16ArrayImpl'),
        jsInt32ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSInt32ArrayImpl'),
        jsUint32ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSUint32ArrayImpl'),
        jsFloat32ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSFloat32ArrayImpl'),
        jsFloat64ArrayImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSFloat64ArrayImpl'),
        int8ListClass = coreTypes.index.getClass('dart:typed_data', 'Int8List'),
        uint8ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Uint8List'),
        uint8ClampedListClass =
            coreTypes.index.getClass('dart:typed_data', 'Uint8ClampedList'),
        int16ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Int16List'),
        uint16ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Uint16List'),
        int32ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Int32List'),
        uint32ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Uint32List'),
        float32ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Float32List'),
        float64ListClass =
            coreTypes.index.getClass('dart:typed_data', 'Float64List'),
        jsDataViewImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSDataViewImpl'),
        byteDataClass = coreTypes.index.getClass('dart:typed_data', 'ByteData'),
        byteBufferClass =
            coreTypes.index.getClass('dart:typed_data', 'ByteBuffer'),
        jsArrayBufferImplClass =
            coreTypes.index.getClass('dart:_js_types', 'JSArrayBufferImpl');

  DartType get nonNullableObjectType =>
      coreTypes.objectRawType(Nullability.nonNullable);

  DartType get nonNullableWasmExternRefType =>
      wasmExternRefClass.getThisType(coreTypes, Nullability.nonNullable);

  DartType get nullableJSValueType =>
      InterfaceType(jsValueClass, Nullability.nullable);

  DartType get nullableWasmExternRefType =>
      wasmExternRefClass.getThisType(coreTypes, Nullability.nullable);

  /// Whether [type] erases to a `JSValue` or `JSValue?`.
  bool isJSValueType(DartType type) =>
      extensionIndex.isStaticInteropType(type) ||
      extensionIndex.isExternalDartReferenceType(type);

  void annotateProcedure(
      Procedure procedure, String pragmaOptionString, AnnotationType type) {
    String pragmaNameType = switch (type) {
      AnnotationType.import => 'import',
      AnnotationType.export => 'export',
      AnnotationType.weakExport => 'weak-export',
    };
    procedure.addAnnotation(ConstantExpression(
        InstanceConstant(coreTypes.pragmaClass.reference, [], {
      coreTypes.pragmaName.fieldReference:
          StringConstant('wasm:$pragmaNameType'),
      coreTypes.pragmaOptions.fieldReference: StringConstant(pragmaOptionString)
    })));
  }

  Expression variableCheckConstant(
          VariableDeclaration variable, Constant constant) =>
      StaticInvocation(coreTypes.identicalProcedure,
          Arguments([VariableGet(variable), ConstantExpression(constant)]));

  Expression variableGreaterThanOrEqualToConstant(
          VariableDeclaration variable, Constant constant) =>
      InstanceInvocation(
        InstanceAccessKind.Instance,
        VariableGet(variable),
        greaterThanOrEqualToTarget.name,
        Arguments([ConstantExpression(constant)]),
        interfaceTarget: greaterThanOrEqualToTarget,
        functionType: greaterThanOrEqualToTarget.getterType as FunctionType,
      );

  /// Cast the [invocation] if needed to conform to the expected [returnType].
  Expression castInvocationForReturn(
      Expression invocation, DartType returnType) {
    if (returnType is VoidType) {
      // Technically a `void` return value can still be used, by casting the
      // return type to `dynamic` or `Object?`. However this case should be
      // extremely rare, and `dartifyRaw` overhead for return values that will
      // never be used in practice is too much, so we avoid `dartifyRaw` on
      // `void` returns.
      return StaticInvocation(internalizeNullable, Arguments([invocation]));
    }

    Expression expression;
    if (isJSValueType(returnType)) {
      // TODO(joshualitt): Expose boxed `JSNull` and `JSUndefined` to Dart
      // code after migrating existing users of js interop on Dart2Wasm.
      // expression = _createJSValue(invocation);
      // Casts are expensive, so we stick to a null-assertion if needed. If
      // the nullability can't be determined, cast.
      expression = invokeOneArg(jsValueBoxTarget, invocation);
      final nullability = returnType.extensionTypeErasure.nullability;
      if (nullability == Nullability.nonNullable) {
        expression = NullCheck(expression);
      } else if (nullability == Nullability.undetermined) {
        expression = AsExpression(expression, returnType);
      }
    } else {
      // Because we simply don't have enough information, we leave all JS
      // numbers as doubles. However, in cases where we know the user expects
      // an `int` we check that the double is an integer, and then insert a
      // cast. We also let static interop types flow through without
      // conversion, both as arguments, and as the return type.
      expression = convertAndCast(
          returnType, invokeOneArg(dartifyRawTarget, invocation));
    }
    return expression;
  }

  // Handles any necessary type conversions. Today this is just for handling the
  // case where a user wants us to coerce a JS number to an int instead of a
  // double. This is okay as long as the value is an integer value.
  Expression convertAndCast(DartType staticType, Expression expression) {
    final erasedType = staticType.extensionTypeErasure;
    if (erasedType == coreTypes.intNullableRawType ||
        erasedType == coreTypes.intNonNullableRawType) {
      // let v = [expression] as double? in
      //  if (v == null) {
      //    return null;
      //  } else {
      //    let v2 = v.toInt() in
      //      if (v == v2) {
      //        return v2;
      //      } else {
      //        throw;
      //      }
      VariableDeclaration v = VariableDeclaration('#vardouble',
          initializer:
              AsExpression(expression, coreTypes.doubleNullableRawType),
          type: coreTypes.doubleNullableRawType,
          isSynthesized: true);
      VariableDeclaration v2 = VariableDeclaration('#varint',
          initializer: invokeMethod(v, numToIntTarget),
          type: coreTypes.intNonNullableRawType,
          isSynthesized: true);
      expression = Let(
          v,
          ConditionalExpression(
              variableCheckConstant(v, NullConstant()),
              ConstantExpression(NullConstant()),
              Let(
                  v2,
                  ConditionalExpression(
                      invokeMethod(v, coreTypes.objectEquals,
                          Arguments([VariableGet(v2)])),
                      VariableGet(v2),
                      Throw(StringLiteral(
                          'Expected integer value, but was not integer.')),
                      coreTypes.intNonNullableRawType)),
              coreTypes.intNullableRawType));
    }
    return AsExpression(expression, staticType);
  }
}

StaticInvocation invokeOneArg(Procedure target, Expression arg) =>
    StaticInvocation(target, Arguments([arg]));

InstanceInvocation invokeMethod(VariableDeclaration receiver, Procedure target,
        [Arguments? arguments]) =>
    InstanceInvocation(InstanceAccessKind.Instance, VariableGet(receiver),
        target.name, arguments ?? Arguments([]),
        interfaceTarget: target,
        functionType:
            target.function.computeFunctionType(Nullability.nonNullable));

bool parametersNeedParens(List<String> parameters) =>
    parameters.isEmpty || parameters.length > 1;

Expression jsifyValue(VariableDeclaration variable, CoreTypesUtil coreTypes,
    TypeEnvironment typeEnv) {
  final Procedure conversionProcedure;

  if (coreTypes.extensionIndex.isStaticInteropType(variable.type) ||
      coreTypes.extensionIndex.isExternalDartReferenceType(variable.type)) {
    conversionProcedure = coreTypes.jsValueUnboxTarget;
  } else {
    conversionProcedure =
        _conversionProcedure(variable.type, coreTypes, typeEnv);
  }

  final conversion =
      StaticInvocation(conversionProcedure, Arguments([VariableGet(variable)]));

  if (variable.type.isPotentiallyNullable) {
    return ConditionalExpression(
        EqualsNull(VariableGet(variable)),
        StaticGet(coreTypes.wasmExternRefNullRef),
        conversion,
        InterfaceType(coreTypes.wasmExternRefClass, Nullability.nullable));
  } else {
    return conversion;
  }
}

Procedure _conversionProcedure(
    DartType type, CoreTypesUtil util, TypeEnvironment typeEnv) {
  // NB. We rely on iteration ordering being insertion order to handle subtypes
  // before supertypes to convert as `int` and `double` before `num`.
  final Map<Class, Procedure> converterMap = {
    util.coreTypes.boolClass: util.toJSBoolean,
    util.coreTypes.intClass: util.jsifyInt,
    util.coreTypes.doubleClass: util.toJSNumber,
    util.coreTypes.numClass: util.jsifyNum,
    util.jsValueClass: util.jsifyJSValue,
    util.coreTypes.stringClass: util.jsifyString,
    util.jsInt8ArrayImplClass: util.jsifyJSInt8ArrayImpl,
    util.jsUint8ArrayImplClass: util.jsifyJSUint8ArrayImpl,
    util.jsUint8ClampedArrayImplClass: util.jsifyJSUint8ClampedArrayImpl,
    util.jsInt16ArrayImplClass: util.jsifyJSInt16ArrayImpl,
    util.jsUint16ArrayImplClass: util.jsifyJSUint16ArrayImpl,
    util.jsInt32ArrayImplClass: util.jsifyJSInt32ArrayImpl,
    util.jsUint32ArrayImplClass: util.jsifyJSUint32ArrayImpl,
    util.jsFloat32ArrayImplClass: util.jsifyJSFloat32ArrayImpl,
    util.jsFloat64ArrayImplClass: util.jsifyJSFloat64ArrayImpl,
    util.int8ListClass: util.jsInt8ArrayFromDartInt8List,
    util.uint8ListClass: util.jsUint8ArrayFromDartUint8List,
    util.uint8ClampedListClass:
        util.jsUint8ClampedArrayFromDartUint8ClampedList,
    util.int16ListClass: util.jsInt16ArrayFromDartInt16List,
    util.uint16ListClass: util.jsUint16ArrayFromDartUint16List,
    util.int32ListClass: util.jsInt32ArrayFromDartInt32List,
    util.uint32ListClass: util.jsUint32ArrayFromDartUint32List,
    util.float32ListClass: util.jsFloat32ArrayFromDartFloat32List,
    util.float64ListClass: util.jsFloat64ArrayFromDartFloat64List,
    util.jsDataViewImplClass: util.jsifyJSDataViewImpl,
    util.byteDataClass: util.jsifyByteData,
    util.coreTypes.listClass: util.jsifyRawList,
    util.jsArrayBufferImplClass: util.jsifyJSArrayBufferImpl,
    util.byteBufferClass: util.jsArrayBufferFromDartByteBuffer,
    util.coreTypes.functionClass: util.jsifyFunction,
  };

  for (final entry in converterMap.entries) {
    if (typeEnv.isSubtypeOf(
        type,
        InterfaceType(entry.key, Nullability.nonNullable),
        SubtypeCheckMode.withNullabilities)) {
      return entry.value;
    }
  }

  // `dynamic` or `Object?`, convert based on runtime type.
  return util.jsifyRawTarget;
}
