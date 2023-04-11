// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart'
    show InlineExtensionIndex;
import 'package:kernel/ast.dart';

bool parametersNeedParens(List<String> parameters) =>
    parameters.isEmpty || parameters.length > 1;

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
