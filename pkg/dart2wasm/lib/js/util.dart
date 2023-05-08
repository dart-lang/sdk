// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/js_interop.dart'
    show hasJSInteropAnnotation, hasStaticInteropAnnotation;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

enum AnnotationType { import, export }

/// A utility wrapper for [CoreTypes].
class CoreTypesUtil {
  final CoreTypes coreTypes;
  final Procedure allowInteropTarget;
  final Procedure dartifyRawTarget;
  final Procedure functionToJSTarget;
  final Procedure inlineJSTarget;
  final Procedure isDartFunctionWrappedTarget;
  final Procedure jsifyRawTarget;
  final Procedure jsObjectFromDartObjectTarget;
  final Procedure jsValueBoxTarget;
  final Constructor jsValueConstructor;
  final Procedure jsValueUnboxTarget;
  final Procedure numToIntTarget;
  final Class wasmExternRefClass;
  final Procedure wrapDartFunctionTarget;

  CoreTypesUtil(this.coreTypes)
      : allowInteropTarget = coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'allowInterop'),
        dartifyRawTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'dartifyRaw'),
        functionToJSTarget = coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        inlineJSTarget =
            coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'JS'),
        isDartFunctionWrappedTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_isDartFunctionWrapped'),
        numToIntTarget = coreTypes.index
            .getClass('dart:core', 'num')
            .procedures
            .firstWhere((p) => p.name.text == 'toInt'),
        jsifyRawTarget =
            coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'jsifyRaw'),
        jsObjectFromDartObjectTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsObjectFromDartObject'),
        jsValueBoxTarget = coreTypes.index
            .getClass('dart:_js_helper', 'JSValue')
            .procedures
            .firstWhere((p) => p.name.text == 'box'),
        jsValueConstructor = coreTypes.index
            .getClass('dart:_js_helper', 'JSValue')
            .constructors
            .single,
        jsValueUnboxTarget = coreTypes.index
            .getClass('dart:_js_helper', 'JSValue')
            .procedures
            .firstWhere((p) => p.name.text == 'unbox'),
        wasmExternRefClass =
            coreTypes.index.getClass('dart:_wasm', 'WasmExternRef'),
        wrapDartFunctionTarget = coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_wrapDartFunction') {}

  DartType get nonNullableObjectType =>
      coreTypes.objectRawType(Nullability.nonNullable);

  DartType get nonNullableWasmExternRefType =>
      wasmExternRefClass.getThisType(coreTypes, Nullability.nonNullable);

  DartType get nullableWasmExternRefType =>
      wasmExternRefClass.getThisType(coreTypes, Nullability.nullable);

  Procedure jsifyTarget(DartType type) =>
      type.isStaticInteropType ? jsValueUnboxTarget : jsifyRawTarget;

  void annotateProcedure(
      Procedure procedure, String pragmaOptionString, AnnotationType type) {
    String pragmaNameType;
    switch (type) {
      case AnnotationType.import:
        pragmaNameType = 'import';
        break;
      case AnnotationType.export:
        pragmaNameType = 'export';
        break;
    }
    procedure.addAnnotation(ConstantExpression(
        InstanceConstant(coreTypes.pragmaClass.reference, [], {
      coreTypes.pragmaName.fieldReference:
          StringConstant('wasm:$pragmaNameType'),
      coreTypes.pragmaOptions.fieldReference:
          StringConstant('$pragmaOptionString')
    })));
  }

  Expression variableCheckConstant(
          VariableDeclaration variable, Constant constant) =>
      StaticInvocation(coreTypes.identicalProcedure,
          Arguments([VariableGet(variable), ConstantExpression(constant)]));

  /// Cast the [invocation] if needed to conform to the expected [returnType].
  Expression castInvocationForReturn(
      Expression invocation, DartType returnType) {
    if (returnType is VoidType) {
      // `undefined` may be returned for `void` external members. It, however,
      // is an extern ref, and therefore needs to be made a Dart type before
      // we can finish the invocation.
      return invokeOneArg(dartifyRawTarget, invocation);
    } else {
      Expression expression;
      if (returnType.isStaticInteropType) {
        // TODO(joshualitt): Expose boxed `JSNull` and `JSUndefined` to Dart
        // code after migrating existing users of js interop on Dart2Wasm.
        // expression = _createJSValue(invocation);
        expression = invokeOneArg(jsValueBoxTarget, invocation);
      } else {
        // Because we simply don't have enough information, we leave all JS
        // numbers as doubles. However, in cases where we know the user expects
        // an `int` we insert a cast. We also let static interop types flow
        // through without conversion, both as arguments, and as the return
        // type.
        final returnTypeOverride = returnType == coreTypes.intNullableRawType
            ? coreTypes.doubleNullableRawType
            : returnType == coreTypes.intNonNullableRawType
                ? coreTypes.doubleNonNullableRawType
                : returnType;
        expression = AsExpression(
            convertReturnType(returnType, returnTypeOverride,
                invokeOneArg(dartifyRawTarget, invocation)),
            returnType);
      }
      return expression;
    }
  }

  // Handles any necessary return type conversions. Today this is just for
  // handling the case where a user wants us to coerce a JS number to an int
  // instead of a double.
  Expression convertReturnType(
      DartType returnType, DartType returnTypeOverride, Expression expression) {
    if (returnType == coreTypes.intNullableRawType ||
        returnType == coreTypes.intNonNullableRawType) {
      VariableDeclaration v = VariableDeclaration('#var',
          initializer: expression,
          type: returnTypeOverride,
          isSynthesized: true);
      return Let(
          v,
          ConditionalExpression(
              variableCheckConstant(v, NullConstant()),
              ConstantExpression(NullConstant()),
              invokeMethod(v, numToIntTarget),
              returnType));
    } else {
      return expression;
    }
  }
}

extension DartTypeExtension on DartType {
  bool get isStaticInteropType {
    final type = this;
    return (type is InterfaceType &&
            hasStaticInteropAnnotation(type.className.asClass)) ||
        (type is InlineType && hasJSInteropAnnotation(type.inlineClass));
  }
}

StaticInvocation invokeOneArg(Procedure target, Expression arg) =>
    StaticInvocation(target, Arguments([arg]));

InstanceInvocation invokeMethod(
        VariableDeclaration receiver, Procedure target) =>
    InstanceInvocation(InstanceAccessKind.Instance, VariableGet(receiver),
        target.name, Arguments([]),
        interfaceTarget: target,
        functionType:
            target.function.computeFunctionType(Nullability.nonNullable));

bool parametersNeedParens(List<String> parameters) =>
    parameters.isEmpty || parameters.length > 1;
