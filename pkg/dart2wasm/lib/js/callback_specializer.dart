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
        final nullability =
            callbackParameterType.extensionTypeErasure.nullability;
        // Null-check if we can tell the nullability. If we can't, the cast
        // closure handles the cast.
        if (nullability == Nullability.nonNullable) {
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
  /// passed, then a "cast closure" if needed, followed by all of the arguments
  /// to the Dart callback as JS objects. Depending on [boxExternRef], the
  /// trampoline will `dartifyRaw` or box all incoming JS objects and then cast
  /// them to their appropriate types, dispatch, and then `jsifyRaw` or box any
  /// returned value. [node] is the conversion function that was called to
  /// convert the callback.
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
    // the number of arguments passed. The third argument is a cast closure if
    // needed.
    final callbackVariable = VariableDeclaration('callback',
        type: _util.nonNullableObjectType, isSynthesized: true);
    final argumentsLength = VariableDeclaration('argumentsLength',
        type: _util.coreTypes.doubleNonNullableRawType, isSynthesized: true);
    final castClosure = VariableDeclaration('castClosure',
        type: _util.nonNullableObjectType, isSynthesized: true);

    // Initialize variable declarations.
    List<VariableDeclaration> positionalParameters = [];
    List<Expression> castClosureArguments = [];
    final positionalParametersLength = function.positionalParameters.length;
    for (int i = 0; i < positionalParametersLength; i++) {
      final parameter = VariableDeclaration('x${i + 1}',
          type: _util.nullableWasmExternRefType, isSynthesized: true);
      positionalParameters.add(parameter);
      if (_needCastClosure(function.positionalParameters[i])) {
        castClosureArguments.add(_createJSValue(VariableGet(parameter)));
      }
    }

    // Build the body of a function trampoline. To support default arguments, we
    // find the last defined argument in JS, that is the last argument which was
    // explicitly passed by the user, and then we dispatch to a Dart function
    // with the right number of arguments.
    List<Statement> body = [];
    if (castClosureArguments.isNotEmpty) {
      // Call the cast closure, but only if the arity is okay. In the case where
      // the arity is not sufficient, we end up coercing `undefined` to `null`,
      // which may result in a type error in the cast closure rather than an
      // arity error later.
      body.add(IfStatement(
          _util.variableGreaterThanOrEqualToConstant(
              argumentsLength, IntConstant(function.requiredParameterCount)),
          ExpressionStatement(FunctionInvocation(
              FunctionAccessKind.FunctionType,
              VariableGet(castClosure),
              Arguments(castClosureArguments),
              functionType: null)),
          null));
    }
    // If more arguments were passed than there are parameters, ignore the extra
    // arguments.
    body.add(IfStatement(
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
      body.add(IfStatement(
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
    body.add(ExpressionStatement(Throw(StringConcatenation([
      StringLiteral('Too few arguments passed. '
          'Expected ${function.requiredParameterCount} or more, got '),
      invokeMethod(argumentsLength, _util.numToIntTarget),
      StringLiteral(' instead.')
    ]))));
    Statement functionTrampolineBody = Block(body);

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
              if (castClosureArguments.isNotEmpty) castClosure,
              ...positionalParameters
            ],
            returnType: _util.nullableWasmExternRefType)
          ..fileOffset = node.fileOffset,
        node.fileUri,
        AnnotationType.export,
        isExternal: false);
    return functionTrampolineName;
  }

  /// Create a [Procedure] that will wrap a Dart callback in a JS wrapper.
  ///
  /// [node] is the conversion function that is called by the user (either
  /// `allowInterop`, `Function.toJS`, or `Function.toJSCaptureThis`). [type] is
  /// the static type of the callback. [boxExternRef] determines if the
  /// trampoline should box the arguments and return value or convert every
  /// value. [needsCastClosure] determines if a cast closure is needed in order
  /// to validate the types of some arguments. [captureThis] determines if
  /// `this` needs to be passed into the trampoline from the JS wrapper.
  ///
  /// The procedure will call a JS method that will create a wrapper, cache the
  /// callback, and call the trampoline function with the callback, the JS
  /// function's arguments' length, the cast closure if needed, and the JS
  /// function's arguments as arguments.
  ///
  /// Returns the created [Procedure].
  Procedure _getJSWrapperFunction(Procedure node, FunctionType type,
      {required bool boxExternRef,
      required bool needsCastClosure,
      required bool captureThis}) {
    final functionTrampolineName =
        _createFunctionTrampoline(node, type, boxExternRef: boxExternRef);
    List<String> jsParameters = [];
    var jsParametersLength = type.positionalParameters.length;
    if (captureThis) jsParametersLength--;
    for (int i = 0; i < jsParametersLength; i++) {
      jsParameters.add('x$i');
    }
    String jsWrapperParams = jsParameters.join(',');
    // We could avoid incrementing the arguments length in the case of
    // `captureThis` and have the function trampoline account for the extra
    // argument, but there's no benefit in doing that.
    String argumentsLength =
        captureThis ? 'arguments.length + 1' : 'arguments.length';
    String dartArguments = 'f,$argumentsLength';
    String jsMethodParams = 'f';
    if (needsCastClosure) {
      dartArguments = '$dartArguments,castClosure';
      jsMethodParams = '($jsMethodParams,castClosure)';
    }
    if (captureThis) dartArguments = '$dartArguments,this';
    if (jsParameters.isNotEmpty) {
      dartArguments = '$dartArguments,$jsWrapperParams';
    }

    // Create Dart procedure stub.
    final jsMethodName = functionTrampolineName;
    Procedure dartProcedure = _methodCollector.addInteropProcedure(
        '|$jsMethodName',
        'dart2wasm.$jsMethodName',
        FunctionNode(null,
            positionalParameters: [
              VariableDeclaration('dartFunction',
                  type: _util.nonNullableWasmExternRefType,
                  isSynthesized: true),
              if (needsCastClosure)
                VariableDeclaration('castClosure',
                    type: _util.nonNullableWasmExternRefType,
                    isSynthesized: true)
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
        "$jsMethodParams => finalizeWrapper(f, function($jsWrapperParams) {"
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
        boxExternRef: false, needsCastClosure: false, captureThis: false);
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

  /// Whether a closure is needed to capture [type] so that the arguments to the
  /// callback can be casted to that [type].
  ///
  /// This includes the case where the parameters have type parameters for
  /// types. The casts can't be done in the trampoline as the type parameters
  /// aren't in scope.
  bool _needCastClosure(DartType type) {
    if (type is TypeParameterType || type is StructuralParameterType) {
      assert(_util.isJSValueType(type));
      return true;
    }
    return false;
  }

  /// Creates a cast closure given the callback's [functionType].
  ///
  /// The cast closure accepts the boxed parameters which need to be casted in
  /// this closure, and then casts them to the captured types.
  ///
  /// Returns the cast closure if needed. Otherwise, returns `null`.
  FunctionExpression? _createCastClosure(FunctionType functionType) {
    final positionalParameters = functionType.positionalParameters;
    List<VariableDeclaration> castClosureParameters = [];
    List<Statement> casts = [];
    for (int i = 0; i < positionalParameters.length; i++) {
      final type = positionalParameters[i];
      if (_needCastClosure(type)) {
        final parameter = VariableDeclaration('x${i + 1}',
            type: _util.nullableJSValueType, isSynthesized: true);
        castClosureParameters.add(parameter);
        casts.add(
            ExpressionStatement(AsExpression(VariableGet(parameter), type)));
      }
    }
    return castClosureParameters.isEmpty
        ? null
        : FunctionExpression(FunctionNode(Block(casts),
            positionalParameters: castClosureParameters,
            returnType: VoidType()));
  }

  /// Given an invocation of `Function.toJS`, returns an [Expression]
  /// representing:
  ///
  ///   JSValue(jsWrapperFunction(<Function>))
  ///
  /// or if a cast closure is needed:
  ///
  ///   JSValue(jsWrapperFunction(<Function>, <CastClosure>))
  ///
  /// If [captureThis] is true, this is assumed to be an invocation of
  /// `Function.toJSCaptureThis`.
  Expression functionToJS(StaticInvocation staticInvocation,
      {bool captureThis = false}) {
    final argument = staticInvocation.arguments.positional.single;
    final type = argument.getStaticType(_staticTypeContext) as FunctionType;
    final castClosure = _createCastClosure(type);
    final jsWrapperFunction = _getJSWrapperFunction(
        staticInvocation.target, type,
        boxExternRef: true,
        needsCastClosure: castClosure != null,
        captureThis: captureThis);
    return _createJSValue(StaticInvocation(
        jsWrapperFunction,
        Arguments([
          StaticInvocation(
              _util.jsObjectFromDartObjectTarget, Arguments([argument])),
          if (castClosure != null)
            StaticInvocation(
                _util.jsObjectFromDartObjectTarget, Arguments([castClosure]))
        ])));
  }
}
