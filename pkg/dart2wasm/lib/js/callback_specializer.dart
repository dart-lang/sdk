// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'method_collector.dart';
import 'util.dart';

/// Specializes Dart callbacks so they can be called from JS.
class CallbackSpecializer {
  final StatefulStaticTypeContext _staticTypeContext;
  final MethodCollector _methodCollector;
  final CoreTypesUtil _util;

  CallbackSpecializer(
      this._staticTypeContext, this._util, this._methodCollector);

  Statement _generateDispatchCase(
      FunctionType function,
      VariableDeclaration callbackVariable,
      List<VariableDeclaration> positionalParameters,
      int requiredParameterCount,
      {required bool boxExternRef}) {
    List<Expression> callbackArguments = [];
    for (int i = 0; i < requiredParameterCount; i++) {
      DartType callbackParameterType = function.positionalParameters[i];
      Expression expression;
      VariableGet v = VariableGet(positionalParameters[i]);
      if (_util.isJSValueType(callbackParameterType) && boxExternRef) {
        expression = _createJSValue(v);
        if (!callbackParameterType.extensionTypeErasure.isPotentiallyNullable) {
          expression = NullCheck(expression);
        }
      } else {
        expression = _util.convertAndCast(
            callbackParameterType, invokeOneArg(_util.dartifyRawTarget, v));
      }
      callbackArguments.add(expression);
    }
    return ReturnStatement(StaticInvocation(
        _util.jsifyTarget(function.returnType),
        Arguments([
          FunctionInvocation(FunctionAccessKind.FunctionType,
              VariableGet(callbackVariable), Arguments(callbackArguments),
              functionType: null),
        ])));
  }

  /// Creates a callback trampoline for the given [function].
  ///
  /// This callback trampoline expects a Dart callback as its first argument,
  /// then an integer value(double type) indicating the number of arguments
  /// passed, followed by all of the arguments to the Dart callback as JS
  /// objects. The trampoline will `dartifyRaw` or box all incoming JS objects
  /// and then cast them to their appropriate types, dispatch, and then
  /// `jsifyRaw` or box any returned value.
  ///
  /// Returns a [String] function name representing the name of the wrapping
  /// function.
  String _createFunctionTrampoline(Procedure node, FunctionType function,
      {required bool boxExternRef}) {
    // Create arguments for each positional parameter in the function. These
    // arguments will be JS objects. The generated wrapper will cast each
    // argument to the correct type.  The first argument to this function will
    // be the Dart callback, which will be cast to the supplied [FunctionType]
    // before being invoked. The second argument will be a `double` indicating
    // the number of arguments passed.
    int parameterId = 1;
    final callbackVariable = VariableDeclaration('callback',
        type: _util.nonNullableObjectType, isSynthesized: true);
    final argumentsLength = VariableDeclaration('argumentsLength',
        type: _util.coreTypes.doubleNonNullableRawType, isSynthesized: true);

    // Initialize variable declarations.
    List<VariableDeclaration> positionalParameters = [];
    final positionalParametersLength = function.positionalParameters.length;
    for (int j = 0; j < positionalParametersLength; j++) {
      positionalParameters.add(VariableDeclaration('x${parameterId++}',
          type: _util.nullableWasmExternRefType, isSynthesized: true));
    }

    // Build the body of a function trampoline. To support default arguments, we
    // find the last defined argument in JS, that is the last argument which was
    // explicitly passed by the user, and then we dispatch to a Dart function
    // with the right number of arguments.
    List<Statement> dispatchCases = [];
    // If more arguments were passed than there are parameters, ignore the extra
    // arguments.
    dispatchCases.add(IfStatement(
        _util.variableGreaterThanOrEqualToConstant(
            argumentsLength, IntConstant(positionalParametersLength)),
        _generateDispatchCase(function, callbackVariable, positionalParameters,
            positionalParametersLength,
            boxExternRef: boxExternRef),
        null));
    // TODO(srujzs): Consider using a switch instead.
    for (int i = positionalParametersLength - 1;
        i >= function.requiredParameterCount;
        i--) {
      dispatchCases.add(IfStatement(
          _util.variableCheckConstant(
              argumentsLength, DoubleConstant(i.toDouble())),
          _generateDispatchCase(
              function, callbackVariable, positionalParameters, i,
              boxExternRef: boxExternRef),
          null));
    }

    // Throw since we have too few arguments. Alternatively, we can continue
    // checking lengths and try to call the callback, which will then throw, but
    // that's unnecessary extra code. Note that we can't exclude this and assume
    // the last dispatch case will catch this. Since arguments that are not
    // passed are `undefined` and `undefined` gets converted to `null`, they may
    // be treated as valid `null` arguments to the Dart function even though
    // they were never passed.
    dispatchCases.add(ExpressionStatement(Throw(StringConcatenation([
      StringLiteral('Too few arguments passed. '
          'Expected ${function.requiredParameterCount} or more, got '),
      invokeMethod(argumentsLength, _util.numToIntTarget),
      StringLiteral(' instead.')
    ]))));
    Statement functionTrampolineBody = Block(dispatchCases);

    // Create a new procedure for the callback trampoline. This procedure will
    // be exported from Wasm to JS so it can be called from JS. The argument
    // returned from the supplied callback will be converted with `jsifyRaw` to
    // a native JS value before being returned to JS.
    final functionTrampolineName = _methodCollector.generateMethodName();
    _methodCollector.addInteropProcedure(
        functionTrampolineName,
        functionTrampolineName,
        FunctionNode(functionTrampolineBody,
            positionalParameters: [
              callbackVariable,
              argumentsLength,
              ...positionalParameters
            ],
            returnType: _util.nullableWasmExternRefType)
          ..fileOffset = node.fileOffset,
        node.fileUri,
        AnnotationType.export,
        isExternal: false);
    return functionTrampolineName;
  }

  /// Returns a JS method that wraps a Dart callback in a JS wrapper.
  Procedure _getJSWrapperFunction(Procedure node, FunctionType type,
      {required bool boxExternRef}) {
    final functionTrampolineName =
        _createFunctionTrampoline(node, type, boxExternRef: boxExternRef);
    List<String> jsParameters = [];
    for (int i = 0; i < type.positionalParameters.length; i++) {
      jsParameters.add('x$i');
    }
    String jsParametersString = jsParameters.join(',');
    String dartArguments = 'f,arguments.length';
    if (jsParameters.isNotEmpty) {
      dartArguments = '$dartArguments,$jsParametersString';
    }

    // Create Dart procedure stub.
    final jsMethodName = functionTrampolineName;
    Procedure dartProcedure = _methodCollector.addInteropProcedure(
        '|$jsMethodName',
        'dart2wasm.$jsMethodName',
        FunctionNode(null,
            positionalParameters: [
              VariableDeclaration('dartFunction',
                  type: _util.nonNullableWasmExternRefType, isSynthesized: true)
            ],
            returnType: _util.nonNullableWasmExternRefType),
        node.fileUri,
        AnnotationType.import,
        isExternal: true);

    // Create JS method.
    // Note: We have to use a regular function for the inner closure in some
    // cases because we need access to `arguments`.
    _methodCollector.addMethod(
        dartProcedure,
        jsMethodName,
        "f => finalizeWrapper(f, function($jsParametersString) {"
        " return dartInstance.exports.$functionTrampolineName($dartArguments) "
        "})");

    return dartProcedure;
  }

  /// Lowers an invocation of `allowInterop<type>(foo)` to:
  ///
  ///   let #var = foo in
  ///     _isDartFunctionWrapped<type>(#var) ?
  ///       #var :
  ///       _wrapDartFunction<type>(#var, jsWrapperFunction(#var));
  ///
  /// The use of two functions here is necessary because we do not allow
  /// `WasmExternRef` to be an argument or return type for a tear off.
  ///
  /// Note: _wrapDartFunction tracks wrapped Dart functions in a map.  When
  /// these Dart functions flow to JS, they are replaced by their wrappers.  If
  /// the wrapper should ever flow back into Dart then it will be replaced by
  /// the original Dart function.
  // TODO(srujzs): It looks like there's no more code that references this
  // function anymore in dart2wasm. Should we delete this lowering and related
  // code?
  Expression allowInterop(StaticInvocation staticInvocation) {
    final argument = staticInvocation.arguments.positional.single;
    final type = argument.getStaticType(_staticTypeContext) as FunctionType;
    final jsWrapperFunction = _getJSWrapperFunction(
        staticInvocation.target, type,
        boxExternRef: false);
    final v = VariableDeclaration('#var',
        initializer: argument, type: type, isSynthesized: true);
    return Let(
        v,
        ConditionalExpression(
            StaticInvocation(_util.isDartFunctionWrappedTarget,
                Arguments([VariableGet(v)], types: [type])),
            VariableGet(v),
            StaticInvocation(
                _util.wrapDartFunctionTarget,
                Arguments([
                  VariableGet(v),
                  StaticInvocation(
                      jsWrapperFunction,
                      Arguments([
                        StaticInvocation(_util.jsObjectFromDartObjectTarget,
                            Arguments([VariableGet(v)]))
                      ])),
                ], types: [
                  type
                ])),
            type));
  }

  Expression _createJSValue(Expression value) =>
      StaticInvocation(_util.jsValueBoxTarget, Arguments([value]));

  /// Lowers an invocation of `<Function>.toJS` to:
  ///
  ///   JSValue(jsWrapperFunction(<Function>))
  Expression functionToJS(StaticInvocation staticInvocation) {
    final argument = staticInvocation.arguments.positional.single;
    final type = argument.getStaticType(_staticTypeContext) as FunctionType;
    final jsWrapperFunction = _getJSWrapperFunction(
        staticInvocation.target, type,
        boxExternRef: true);
    return _createJSValue(StaticInvocation(
        jsWrapperFunction,
        Arguments([
          StaticInvocation(
              _util.jsObjectFromDartObjectTarget, Arguments([argument]))
        ])));
  }
}
