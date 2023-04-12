// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/js_interop.dart'
    show
        getJSName,
        hasAnonymousAnnotation,
        hasJSInteropAnnotation,
        hasObjectLiteralAnnotation;
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart'
    show InlineExtensionIndex;
import 'package:dart2wasm/js/method_collector.dart';
import 'package:dart2wasm/js/util.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

/// A general config class for an interop method.
///
/// dart2wasm needs to create a trampoline method in JS that then calls the
/// interop member in question. In order to do so, we need information on things
/// like the name of the member, how many parameters it takes in, and more.
abstract class LoweringConfig {
  final Procedure interopMethod;
  final String jsString;
  final InlineExtensionIndex _inlineExtensionIndex;
  late final bool firstParameterIsObject =
      _inlineExtensionIndex.isInstanceInteropMember(interopMethod);

  LoweringConfig(this.interopMethod, this.jsString, this._inlineExtensionIndex);

  FunctionNode get function => interopMethod.function;
  Uri get fileUri => interopMethod.fileUri;

  /// Whether this config is associated with a constructor or factory.
  bool get isConstructor;

  /// The parameters that determine arity of the interop procedure that is
  /// created from this config.
  List<VariableDeclaration> get parameters;

  /// Returns the string that will be the body of the JS trampoline.
  ///
  /// [object] is the callee if there is one for this config. [callArguments] is
  /// the remaining arguments of the `interopMethod`.
  String bodyString(String object, List<String> callArguments);

  /// Compute and return the JS trampoline string needed for this method
  /// lowering.
  String generateJS(List<String> parameterNames) {
    final object = isConstructor
        ? ''
        : firstParameterIsObject
            ? parameterNames[0]
            : 'globalThis';
    final callArguments =
        firstParameterIsObject ? parameterNames.sublist(1) : parameterNames;
    final callArgumentsString = callArguments.join(',');
    final functionParameters = firstParameterIsObject
        ? '$object${callArguments.isEmpty ? '' : ',$callArgumentsString'}'
        : callArgumentsString;
    final body = bodyString(object, callArguments);
    if (parametersNeedParens(parameterNames)) {
      return '($functionParameters) => $body';
    } else {
      return '$functionParameters => $body';
    }
  }
}

/// Config class for interop members that get lowered on the procedure side.
abstract class ProcedureLoweringConfig extends LoweringConfig {
  ProcedureLoweringConfig(
      super.interopMethod, super.jsString, super._inlineExtensionIndex);

  @override
  List<VariableDeclaration> get parameters => function.positionalParameters;
}

class ConstructorLoweringConfig extends ProcedureLoweringConfig {
  ConstructorLoweringConfig(
      super.interopMethod, super.jsString, super._inlineExtensionIndex);

  @override
  bool get isConstructor => true;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "new $jsString(${callArguments.join(',')})";
}

class GetterLoweringConfig extends ProcedureLoweringConfig {
  GetterLoweringConfig(
      super.interopMethod, super.jsString, super._inlineExtensionIndex);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      '$object.$jsString';
}

class SetterLoweringConfig extends ProcedureLoweringConfig {
  SetterLoweringConfig(
      super.interopMethod, super.jsString, super._inlineExtensionIndex);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      '$object.$jsString = ${callArguments[0]}';
}

class MethodLoweringConfig extends ProcedureLoweringConfig {
  MethodLoweringConfig(
      super.interopMethod, super.jsString, super._inlineExtensionIndex);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "$object.$jsString(${callArguments.join(',')})";
}

class OperatorLoweringConfig extends ProcedureLoweringConfig {
  OperatorLoweringConfig(
      super.interopMethod, super.jsString, super._inlineExtensionIndex);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) {
    if (jsString == '[]') {
      return '$object[${callArguments[0]}]';
    } else if (jsString == '[]=') {
      return '$object[${callArguments[0]}] = ${callArguments[1]}';
    } else {
      throw 'Unsupported operator: $jsString';
    }
  }
}

/// Config class for interop members that get lowered on the invocation side.
abstract class InvocationLoweringConfig extends LoweringConfig {
  final StaticInvocation invocation;
  InvocationLoweringConfig(super.interopMethod, super.jsString,
      super._inlineExtensionIndex, this.invocation);

  /// The parameters of the given `interopMethod` that were given a correspondig
  /// argument in the `invocation`.
  @override
  List<VariableDeclaration> get parameters;

  /// The expressions that were passed in the `invocation`.
  List<Expression> get arguments;
}

/// Config class for procedures that are lowered on the invocation-side, but
/// only contain positional parameters.
abstract class PositionalInvocationLoweringConfig
    extends InvocationLoweringConfig {
  PositionalInvocationLoweringConfig(super.interopMethod, super.jsString,
      super._inlineExtensionIndex, super.invocation);

  @override
  List<VariableDeclaration> get parameters => function.positionalParameters
      .sublist(0, invocation.arguments.positional.length);

  @override
  List<Expression> get arguments => invocation.arguments.positional;
}

class ConstructorInvocationLoweringConfig
    extends PositionalInvocationLoweringConfig {
  ConstructorInvocationLoweringConfig(super.interopMethod, super.jsString,
      super._inlineExtensionIndex, super.invocation);

  @override
  bool get isConstructor => true;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "new $jsString(${callArguments.join(',')})";
}

class MethodInvocationLoweringConfig
    extends PositionalInvocationLoweringConfig {
  MethodInvocationLoweringConfig(super.interopMethod, super.jsString,
      super._inlineExtensionIndex, super.invocation);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "$object.$jsString(${callArguments.join(',')})";
}

/// Config class for object literals, which only use named arguments and are
/// only lowered at the invocation-level.
class ObjectLiteralLoweringConfig extends InvocationLoweringConfig {
  ObjectLiteralLoweringConfig(Procedure interopMethod,
      InlineExtensionIndex _inlineExtensionIndex, StaticInvocation invocation)
      : super(interopMethod, '', _inlineExtensionIndex, invocation);

  @override
  bool get isConstructor => true;

  @override
  List<VariableDeclaration> get parameters {
    // Compute the named parameters that were used in the given `invocation`.
    // Note that we preserve the procedure's ordering and not the invocation's.
    // This is also used below for the names of object literal arguments in
    // `generateJS`.
    final usedArgs =
        invocation.arguments.named.map((expr) => expr.name).toSet();
    return function.namedParameters
        .where((decl) => usedArgs.contains(decl.name))
        .toList();
  }

  @override
  String bodyString(String object, List<String> callArguments) {
    final keys = parameters.map((named) => named.name!).toList();
    final keyValuePairs = <String>[];
    for (int i = 0; i < callArguments.length; i++) {
      keyValuePairs.add('${keys[i]}: ${callArguments[i]}');
    }
    return '({${keyValuePairs.join(',')}})';
  }

  @override
  List<Expression> get arguments {
    // Return the args in the order of the procedure's parameters and not
    // the invocation.
    final namedArgs = <String, Expression>{};
    for (NamedExpression expr in invocation.arguments.named) {
      namedArgs[expr.name] = expr.value;
    }
    return parameters
        .map<Expression>((decl) => namedArgs[decl.name!]!)
        .toList();
  }
}

// TODO(joshualitt): Have a factory that returns specializers and merge the
// specialization logic with the configuration logic.
class InteropSpecializer {
  final StatefulStaticTypeContext _staticTypeContext;
  final CoreTypesUtil _util;
  final MethodCollector _methodCollector;
  final Map<Procedure, Map<int, Procedure>> _overloadedProcedures = {};
  final Map<Procedure, Map<String, Procedure>> _jsObjectLiteralMethods = {};
  late String _libraryJSString;
  late InlineExtensionIndex _inlineExtensionIndex;

  InteropSpecializer(
      this._staticTypeContext, this._util, this._methodCollector);

  CoreTypes get _coreTypes => _util.coreTypes;

  void enterLibrary(Library library) {
    _inlineExtensionIndex = InlineExtensionIndex(library);
    _libraryJSString = getJSName(library);
    if (_libraryJSString.isNotEmpty) {
      _libraryJSString = '$_libraryJSString.';
    }
  }

  String _getJSString(Annotatable a, String initial) {
    String selectorString = getJSName(a);
    if (selectorString.isEmpty) {
      selectorString = initial;
    }
    return selectorString;
  }

  String _getTopLevelJSString(Annotatable a, String initial) =>
      '$_libraryJSString${_getJSString(a, initial)}';

  /// Get the `LoweringConfig` for the non-constructor [node] with its
  /// associated [jsString] name, and the [invocation] it's used in if this is
  /// an invocation-level lowering.
  LoweringConfig? _getConfigForMember(Procedure node, String jsString,
      [StaticInvocation? invocation]) {
    if (_inlineExtensionIndex.isGetter(node)) {
      return GetterLoweringConfig(node, jsString, _inlineExtensionIndex);
    } else if (_inlineExtensionIndex.isSetter(node)) {
      return SetterLoweringConfig(node, jsString, _inlineExtensionIndex);
    } else if (_inlineExtensionIndex.isOperator(node)) {
      return OperatorLoweringConfig(node, jsString, _inlineExtensionIndex);
    } else if (_inlineExtensionIndex.isMethod(node)) {
      return invocation != null
          ? MethodInvocationLoweringConfig(
              node, jsString, _inlineExtensionIndex, invocation)
          : MethodLoweringConfig(node, jsString, _inlineExtensionIndex);
    }
    return null;
  }

  /// Get the `LoweringConfig` for the constructor [node], whether it
  /// [isObjectLiteral] or not, with its associated [jsString] name, and the
  /// [invocation] it's used in if this is an invocation-level lowering.
  LoweringConfig? _getConfigForConstructor(
      bool isObjectLiteral, Procedure node, String jsString,
      [StaticInvocation? invocation]) {
    if (invocation != null) {
      if (isObjectLiteral) {
        return ObjectLiteralLoweringConfig(
            node, _inlineExtensionIndex, invocation);
      } else {
        return ConstructorInvocationLoweringConfig(
            node, jsString, _inlineExtensionIndex, invocation);
      }
    } else if (!isObjectLiteral) {
      return ConstructorLoweringConfig(node, jsString, _inlineExtensionIndex);
    }
    return null;
  }

  /// Given a procedure [node], determines if it's an interop procedure that
  /// needs to be lowered, and if so, returns the config associated with it.
  ///
  /// If [invocation] is not null, returns an invocation-level config for the
  /// [node] if it exists.
  LoweringConfig? getLoweringConfig(Procedure node,
      [StaticInvocation? invocation]) {
    if (node.enclosingClass != null &&
        hasJSInteropAnnotation(node.enclosingClass!)) {
      final cls = node.enclosingClass!;
      final clsString = _getTopLevelJSString(cls, cls.name);
      if (node.isFactory) {
        return _getConfigForConstructor(
            hasAnonymousAnnotation(cls), node, clsString, invocation);
      } else {
        final memberSelectorString = _getJSString(node, node.name.text);
        return _getConfigForMember(
            node, '$clsString.$memberSelectorString', invocation);
      }
    } else if (node.isInlineClassMember) {
      final nodeDescriptor =
          _inlineExtensionIndex.getInlineDescriptor(node.reference);
      if (nodeDescriptor != null) {
        final cls = _inlineExtensionIndex.getInlineClass(node.reference)!;
        final clsString = _getTopLevelJSString(cls, cls.name);
        final kind = nodeDescriptor.kind;
        if ((kind == InlineClassMemberKind.Constructor ||
            kind == InlineClassMemberKind.Factory)) {
          return _getConfigForConstructor(
              hasObjectLiteralAnnotation(node), node, clsString, invocation);
        } else {
          final memberSelectorString =
              _getJSString(node, nodeDescriptor.name.text);
          if (nodeDescriptor.isStatic) {
            return _getConfigForMember(
                node, '$clsString.$memberSelectorString', invocation);
          } else {
            return _getConfigForMember(node, memberSelectorString, invocation);
          }
        }
      }
    } else if (node.isExtensionMember) {
      final nodeDescriptor =
          _inlineExtensionIndex.getExtensionDescriptor(node.reference);
      if (nodeDescriptor != null && !nodeDescriptor.isStatic) {
        return _getConfigForMember(
            node, _getJSString(node, nodeDescriptor.name.text), invocation);
      }
    } else if (hasJSInteropAnnotation(node)) {
      return _getConfigForMember(
          node, _getTopLevelJSString(node, node.name.text), invocation);
    }
    return null;
  }

  /// Creates a Dart procedure that calls out to a specialized JS method for the
  /// given [config] and returns the created procedure.
  ///
  /// TODO(srujzs): This and the specialization logic should be moved to the
  /// configs themselves with some virtual method like `specialize`.
  Procedure _getInteropProcedure(LoweringConfig config) {
    // Procedures with optional arguments are specialized at the
    // invocation-level, so we cache if we've already created an interop
    // procedure for the given number of parameters.
    Procedure? cachedProcedure =
        _overloadedProcedures[config.interopMethod]?[config.parameters.length];
    if (cachedProcedure != null) return cachedProcedure;

    // Initialize variable declarations.
    List<String> jsParameterStrings = [];
    List<VariableDeclaration> dartPositionalParameters = [];
    for (int j = 0; j < config.parameters.length; j++) {
      String parameterString = 'x$j';
      dartPositionalParameters.add(VariableDeclaration(parameterString,
          type: _util.nullableWasmExternRefType, isSynthesized: true));
      jsParameterStrings.add(parameterString);
    }

    // Create Dart procedure stub for JS method.
    String jsMethodName = _methodCollector.generateMethodName();
    final dartProcedure = _methodCollector.addInteropProcedure(
        '|$jsMethodName',
        'dart2wasm.$jsMethodName',
        FunctionNode(null,
            positionalParameters: dartPositionalParameters,
            returnType: _util.nullableWasmExternRefType),
        config.fileUri,
        AnnotationType.import,
        isExternal: true);
    _methodCollector.addMethod(
        dartProcedure, jsMethodName, config.generateJS(jsParameterStrings));

    if (config is PositionalInvocationLoweringConfig ||
        config is MethodLoweringConfig ||
        config is ConstructorLoweringConfig) {
      // For now, these are the only configs that are cached in
      // `_overloadedProcedures` since they may contain optionals.
      _overloadedProcedures.putIfAbsent(
              config.interopMethod, () => {})[config.parameters.length] =
          dartProcedure;
    }

    return dartProcedure;
  }

  /// Given a [config], returns an invocation of a specialized JS method that
  /// creates an object literal using the arguments from the [config].
  Expression _specializeJSObjectLiteral(ObjectLiteralLoweringConfig config) {
    // To avoid one method for every invocation, we optimize and compute one
    // method per invocation shape. For example, `Cons(a: 0, b: 0)`,
    // `Cons(a: 0)`, and `Cons(a: 1, b: 1)` only create two shapes:
    // `{a: value, b: value}` and `{a: value}`. Therefore, we only need two
    // methods to handle the `Cons` invocations.
    final shape = config.parameters
        .map((VariableDeclaration decl) => decl.name)
        .join('|');
    final interopProcedure = _jsObjectLiteralMethods
        .putIfAbsent(config.interopMethod, () => {})
        .putIfAbsent(shape, () => _getInteropProcedure(config));
    final positionalArgs = config.arguments
        .map<Expression>((expr) => StaticInvocation(
            _util.jsifyTarget(expr.getStaticType(_staticTypeContext)),
            Arguments([expr])))
        .toList();
    final invocation =
        StaticInvocation(interopProcedure, Arguments(positionalArgs));
    assert(config.function.returnType.isStaticInteropType);
    return invokeOneArg(_util.jsValueBoxTarget, invocation);
  }

  /// Given a [config], returns an invocation of a specialized JS method meant
  /// to be used in an invocation-level lowering.
  Expression _specializeJSInvocation(
      PositionalInvocationLoweringConfig config) {
    // Create or get the specialized procedure for the invoked number of
    // arguments. Cast as needed and return the final invocation.
    final invocation = StaticInvocation(
        _getInteropProcedure(config),
        Arguments(config.arguments
            .map<Expression>((expr) => StaticInvocation(
                _util.jsifyTarget(expr.getStaticType(_staticTypeContext)),
                Arguments([expr])))
            .toList()));
    return _castInvocationForReturn(invocation, config.function.returnType);
  }

  /// Given a [config], returns an invocation of a specialized JS method meant
  /// to be used in a procedure-level lowering.
  Statement _specializeJSProcedure(ProcedureLoweringConfig config) {
    // Return the replacement body.
    final returnType = config.function.returnType;
    Expression invocation = StaticInvocation(
        _getInteropProcedure(config),
        Arguments(config.parameters
            .map<Expression>((value) => StaticInvocation(
                _util.jsifyTarget(value.type), Arguments([VariableGet(value)])))
            .toList()));
    invocation = _castInvocationForReturn(invocation, returnType);
    return returnType is VoidType
        ? ExpressionStatement(invocation)
        : ReturnStatement(invocation);
  }

  /// Cast the [invocation] if needed to conform to the expected [returnType].
  Expression _castInvocationForReturn(
      Expression invocation, DartType returnType) {
    if (returnType is VoidType) {
      // `undefined` may be returned for `void` external members. It, however,
      // is an extern ref, and therefore needs to be made a Dart type before
      // we can finish the invocation.
      return invokeOneArg(_util.dartifyRawTarget, invocation);
    } else {
      Expression expression;
      if (returnType.isStaticInteropType) {
        // TODO(joshualitt): Expose boxed `JSNull` and `JSUndefined` to Dart
        // code after migrating existing users of js interop on Dart2Wasm.
        // expression = _createJSValue(invocation);
        expression = invokeOneArg(_util.jsValueBoxTarget, invocation);
      } else {
        // Because we simply don't have enough information, we leave all JS
        // numbers as doubles. However, in cases where we know the user expects
        // an `int` we insert a cast. We also let static interop types flow
        // through without conversion, both as arguments, and as the return
        // type.
        final returnTypeOverride = returnType == _coreTypes.intNullableRawType
            ? _coreTypes.doubleNullableRawType
            : returnType == _coreTypes.intNonNullableRawType
                ? _coreTypes.doubleNonNullableRawType
                : returnType;
        expression = AsExpression(
            _convertReturnType(returnType, returnTypeOverride,
                invokeOneArg(_util.dartifyRawTarget, invocation)),
            returnType);
      }
      return expression;
    }
  }

  // Handles any necessary return type conversions. Today this is just for
  // handling the case where a user wants us to coerce a JS number to an int
  // instead of a double.
  Expression _convertReturnType(
      DartType returnType, DartType returnTypeOverride, Expression expression) {
    if (returnType == _coreTypes.intNullableRawType ||
        returnType == _coreTypes.intNonNullableRawType) {
      VariableDeclaration v = VariableDeclaration('#var',
          initializer: expression,
          type: returnTypeOverride,
          isSynthesized: true);
      return Let(
          v,
          ConditionalExpression(
              _util.variableCheckConstant(v, NullConstant()),
              ConstantExpression(NullConstant()),
              invokeMethod(v, _util.numToIntTarget),
              returnType));
    } else {
      return expression;
    }
  }

  Expression? maybeSpecializeInvocation(
      Procedure target, StaticInvocation node) {
    if (target.isExternal || _overloadedProcedures.containsKey(target)) {
      final config = getLoweringConfig(target, node);
      if (config is PositionalInvocationLoweringConfig) {
        // These types may contain optionals. Therefore, we do invocation-level
        // lowering to support passing fewer than the max arguments.
        return _specializeJSInvocation(config);
      } else if (config is ObjectLiteralLoweringConfig) {
        return _specializeJSObjectLiteral(config);
      }
    }
    return null;
  }

  bool maybeSpecializeProcedure(Procedure node) {
    if (node.isExternal) {
      final config = getLoweringConfig(node);
      if (config != null && config is ProcedureLoweringConfig) {
        // For the time being to support tearoffs we simply replace the body of
        // the original procedure, but leave all the optional arguments intact.
        // This unfortunately results in inconsistent behavior between the
        // tearoff and the original functions.
        // TODO(joshualitt): Decide if we should disallow tearoffs of external
        // functions, and if so we can clean this up.
        FunctionNode function = node.function;
        Statement transformedBody = _specializeJSProcedure(config);
        function.body = transformedBody..parent = function;
        node.isExternal = false;
        return true;
      }
    }
    return false;
  }
}
