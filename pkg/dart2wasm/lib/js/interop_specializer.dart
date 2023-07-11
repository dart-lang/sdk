// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/js_interop.dart'
    show getJSName, hasAnonymousAnnotation, hasJSInteropAnnotation;
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart'
    show InlineExtensionIndex;
import 'package:dart2wasm/js/method_collector.dart';
import 'package:dart2wasm/js/util.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

/// A general config class for an interop method.
///
/// dart2wasm needs to create a trampoline method in JS that then calls the
/// interop member in question. In order to do so, we need information on things
/// like the name of the member, how many parameters it takes in, and more.
abstract class _Specializer {
  final InteropSpecializerFactory factory;
  final Procedure interopMethod;
  final String jsString;
  late final bool firstParameterIsObject =
      factory._inlineExtensionIndex.isInstanceInteropMember(interopMethod);

  _Specializer(this.factory, this.interopMethod, this.jsString);

  StatefulStaticTypeContext get _staticTypeContext =>
      factory._staticTypeContext;
  CoreTypesUtil get _util => factory._util;
  MethodCollector get _methodCollector => factory._methodCollector;
  Map<Procedure, Map<int, Procedure>> get _overloadedProcedures =>
      factory._overloadedProcedures;
  Map<Procedure, Map<String, Procedure>> get _jsObjectLiteralMethods =>
      factory._jsObjectLiteralMethods;
  FunctionNode get function => interopMethod.function;
  Uri get fileUri => interopMethod.fileUri;
  bool get hasOptionalPositionalParameters =>
      function.requiredParameterCount < function.positionalParameters.length;

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

  /// Returns an [Expression] representing the specialization of a given
  /// [StaticInvocation] or [Procedure].
  Expression specialize();

  Procedure _getRawInteropProcedure() {
    // Initialize variable declarations.
    List<String> jsParameterStrings = [];
    List<VariableDeclaration> dartPositionalParameters = [];
    for (int j = 0; j < parameters.length; j++) {
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
        fileUri,
        AnnotationType.import,
        isExternal: true);
    _methodCollector.addMethod(
        dartProcedure, jsMethodName, generateJS(jsParameterStrings));
    return dartProcedure;
  }

  /// Creates a Dart procedure that calls out to a specialized JS method for the
  /// given [config] and returns the created procedure.
  Procedure _getOrCreateInteropProcedure() {
    // Procedures with optional arguments are specialized at the
    // invocation-level, so we cache if we've already created an interop
    // procedure for the given number of parameters.
    Procedure? cachedProcedure =
        _overloadedProcedures[interopMethod]?[parameters.length];
    if (cachedProcedure != null) return cachedProcedure;
    final dartProcedure = _getRawInteropProcedure();
    _overloadedProcedures.putIfAbsent(
        interopMethod, () => {})[parameters.length] = dartProcedure;
    return dartProcedure;
  }

  Procedure _getInteropProcedure() => hasOptionalPositionalParameters
      ? _getOrCreateInteropProcedure()
      : _getRawInteropProcedure();
}

/// Config class for interop members that get lowered on the procedure side.
abstract class _ProcedureSpecializer extends _Specializer {
  _ProcedureSpecializer(super.context, super.interopMethod, super.jsString);

  @override
  List<VariableDeclaration> get parameters => function.positionalParameters;

  /// Returns an invocation of a specialized JS method meant to be used in a
  /// procedure-level lowering.
  @override
  Expression specialize() {
    // Return the replacement body.
    Expression invocation = StaticInvocation(
        _getInteropProcedure(),
        Arguments(parameters
            .map<Expression>((value) => StaticInvocation(
                _util.jsifyTarget(value.type), Arguments([VariableGet(value)])))
            .toList()));
    return _util.castInvocationForReturn(invocation, function.returnType);
  }
}

class _ConstructorSpecializer extends _ProcedureSpecializer {
  _ConstructorSpecializer(InteropSpecializerFactory factory,
      Procedure interopMethod, String jsString)
      : super(factory, interopMethod, jsString);

  @override
  bool get isConstructor => true;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "new $jsString(${callArguments.join(',')})";
}

class _GetterSpecializer extends _ProcedureSpecializer {
  _GetterSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      '$object.$jsString';
}

class _SetterSpecializer extends _ProcedureSpecializer {
  _SetterSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      '$object.$jsString = ${callArguments[0]}';
}

class _MethodSpecializer extends _ProcedureSpecializer {
  _MethodSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "$object.$jsString(${callArguments.join(',')})";
}

class _OperatorSpecializer extends _ProcedureSpecializer {
  _OperatorSpecializer(super.factory, super.interopMethod, super.jsString);

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
abstract class _InvocationSpecializer extends _Specializer {
  final StaticInvocation invocation;
  _InvocationSpecializer(
      super.factory, super.interopMethod, super.jsString, this.invocation);
}

/// Config class for procedures that are lowered on the invocation-side, but
/// only contain positional parameters.
abstract class _PositionalInvocationSpecializer extends _InvocationSpecializer {
  _PositionalInvocationSpecializer(
      super.factory, super.interopMethod, super.jsString, super.invocation);

  @override
  List<VariableDeclaration> get parameters => function.positionalParameters
      .sublist(0, invocation.arguments.positional.length);

  /// Returns an invocation of a specialized JS method meant to be used in an
  /// invocation-level lowering.
  @override
  Expression specialize() {
    // Create or get the specialized procedure for the invoked number of
    // arguments. Cast as needed and return the final invocation.
    final staticInvocation = StaticInvocation(
        _getInteropProcedure(),
        Arguments(invocation.arguments.positional
            .map<Expression>((expr) => StaticInvocation(
                _util.jsifyTarget(expr.getStaticType(_staticTypeContext)),
                Arguments([expr])))
            .toList()));
    return _util.castInvocationForReturn(staticInvocation, function.returnType);
  }
}

class _ConstructorInvocationSpecializer
    extends _PositionalInvocationSpecializer {
  _ConstructorInvocationSpecializer(
      super.factory, super.interopMethod, super.jsString, super.invocation);

  @override
  bool get isConstructor => true;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "new $jsString(${callArguments.join(',')})";
}

class _MethodInvocationSpecializer extends _PositionalInvocationSpecializer {
  _MethodInvocationSpecializer(
      super.factory, super.interopMethod, super.jsString, super.invocation);

  @override
  bool get isConstructor => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "$object.$jsString(${callArguments.join(',')})";
}

/// Config class for object literals, which only use named arguments and are
/// only lowered at the invocation-level.
class _ObjectLiteralSpecializer extends _InvocationSpecializer {
  _ObjectLiteralSpecializer(InteropSpecializerFactory factory,
      Procedure interopMethod, StaticInvocation invocation)
      : super(factory, interopMethod, '', invocation);

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

  /// Returns an invocation of a specialized JS method that creates an object
  /// literal using the arguments from the invocation.
  @override
  Expression specialize() {
    // To avoid one method for every invocation, we optimize and compute one
    // method per invocation shape. For example, `Cons(a: 0, b: 0)`,
    // `Cons(a: 0)`, and `Cons(a: 1, b: 1)` only create two shapes:
    // `{a: value, b: value}` and `{a: value}`. Therefore, we only need two
    // methods to handle the `Cons` invocations.
    final shape =
        parameters.map((VariableDeclaration decl) => decl.name).join('|');
    final interopProcedure = _jsObjectLiteralMethods
        .putIfAbsent(interopMethod, () => {})
        .putIfAbsent(shape, () => _getRawInteropProcedure());

    // Return the args in the order of the procedure's parameters and not
    // the invocation.
    final namedArgs = <String, Expression>{};
    for (NamedExpression expr in invocation.arguments.named) {
      namedArgs[expr.name] = expr.value;
    }
    final arguments =
        parameters.map<Expression>((decl) => namedArgs[decl.name!]!).toList();
    final positionalArgs = arguments
        .map<Expression>((expr) => StaticInvocation(
            _util.jsifyTarget(expr.getStaticType(_staticTypeContext)),
            Arguments([expr])))
        .toList();
    assert(function.returnType.isStaticInteropType);
    return invokeOneArg(_util.jsValueBoxTarget,
        StaticInvocation(interopProcedure, Arguments(positionalArgs)));
  }
}

class InteropSpecializerFactory {
  final StatefulStaticTypeContext _staticTypeContext;
  final CoreTypesUtil _util;
  final MethodCollector _methodCollector;
  final Map<Procedure, Map<int, Procedure>> _overloadedProcedures = {};
  final Map<Procedure, Map<String, Procedure>> _jsObjectLiteralMethods = {};
  late String _libraryJSString;
  late final InlineExtensionIndex _inlineExtensionIndex;

  InteropSpecializerFactory(
      this._staticTypeContext, this._util, this._methodCollector) {
    final typeEnvironment = _staticTypeContext.typeEnvironment;
    _inlineExtensionIndex =
        InlineExtensionIndex(typeEnvironment.coreTypes, typeEnvironment);
  }

  void enterLibrary(Library library) {
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

  /// Get the `_Specializer` for the non-constructor [node] with its
  /// associated [jsString] name, and the [invocation] it's used in if this is
  /// an invocation-level lowering.
  _Specializer? _getSpecializerForMember(Procedure node, String jsString,
      [StaticInvocation? invocation]) {
    if (invocation == null) {
      if (_inlineExtensionIndex.isGetter(node)) {
        return _GetterSpecializer(this, node, jsString);
      } else if (_inlineExtensionIndex.isSetter(node)) {
        return _SetterSpecializer(this, node, jsString);
      } else if (_inlineExtensionIndex.isOperator(node)) {
        return _OperatorSpecializer(this, node, jsString);
      } else if (_inlineExtensionIndex.isMethod(node)) {
        return _MethodSpecializer(this, node, jsString);
      }
    } else {
      if (_inlineExtensionIndex.isMethod(node)) {
        return _MethodInvocationSpecializer(this, node, jsString, invocation);
      }
    }
    return null;
  }

  /// Get the `_Specializer` for the constructor [node], whether it
  /// [isObjectLiteral] or not, with its associated [jsString] name, and the
  /// [invocation] it's used in if this is an invocation-level lowering.
  _Specializer? _getSpecializerForConstructor(
      bool isObjectLiteral, Procedure node, String jsString,
      [StaticInvocation? invocation]) {
    if (invocation == null) {
      if (!isObjectLiteral) {
        return _ConstructorSpecializer(this, node, jsString);
      }
    } else {
      if (isObjectLiteral) {
        return _ObjectLiteralSpecializer(this, node, invocation);
      } else {
        return _ConstructorInvocationSpecializer(
            this, node, jsString, invocation);
      }
    }
    return null;
  }

  /// Given a procedure [node], determines if it's an interop procedure that
  /// needs to be specialized, and if so, returns the specializer associated
  /// with it.
  ///
  /// If [invocation] is not null, returns an invocation-level config for the
  /// [node] if it exists.
  _Specializer? _getSpecializer(Procedure node,
      [StaticInvocation? invocation]) {
    if (node.enclosingClass != null &&
        hasJSInteropAnnotation(node.enclosingClass!)) {
      final cls = node.enclosingClass!;
      final clsString = _getTopLevelJSString(cls, cls.name);
      if (node.isFactory) {
        return _getSpecializerForConstructor(
            hasAnonymousAnnotation(cls), node, clsString, invocation);
      } else {
        final memberSelectorString = _getJSString(node, node.name.text);
        return _getSpecializerForMember(
            node, '$clsString.$memberSelectorString', invocation);
      }
    } else if (node.isInlineClassMember) {
      final nodeDescriptor = _inlineExtensionIndex.getInlineDescriptor(node);
      if (nodeDescriptor != null) {
        final cls = _inlineExtensionIndex.getInlineClass(node)!;
        final clsString = _getTopLevelJSString(cls, cls.name);
        final kind = nodeDescriptor.kind;
        if ((kind == InlineClassMemberKind.Constructor ||
            kind == InlineClassMemberKind.Factory)) {
          return _getSpecializerForConstructor(
              _inlineExtensionIndex.isLiteralConstructor(node),
              node,
              clsString,
              invocation);
        } else {
          final memberSelectorString =
              _getJSString(node, nodeDescriptor.name.text);
          if (nodeDescriptor.isStatic) {
            return _getSpecializerForMember(
                node, '$clsString.$memberSelectorString', invocation);
          } else {
            return _getSpecializerForMember(
                node, memberSelectorString, invocation);
          }
        }
      }
    } else if (node.isExtensionMember) {
      final nodeDescriptor = _inlineExtensionIndex.getExtensionDescriptor(node);
      if (nodeDescriptor != null && !nodeDescriptor.isStatic) {
        return _getSpecializerForMember(
            node, _getJSString(node, nodeDescriptor.name.text), invocation);
      }
    } else if (hasJSInteropAnnotation(node)) {
      return _getSpecializerForMember(
          node, _getTopLevelJSString(node, node.name.text), invocation);
    }
    return null;
  }

  Expression? maybeSpecializeInvocation(
      Procedure target, StaticInvocation node) {
    if (target.isExternal || _overloadedProcedures.containsKey(target)) {
      return _getSpecializer(target, node)?.specialize();
    }
    return null;
  }

  bool maybeSpecializeProcedure(Procedure node) {
    if (node.isExternal) {
      final specializer = _getSpecializer(node);
      if (specializer != null) {
        final expression = specializer.specialize();
        final transformedBody = specializer.function.returnType is VoidType
            ? ExpressionStatement(expression)
            : ReturnStatement(expression);

        // For the time being to support tearoffs we simply replace the body of
        // the original procedure, but leave all the optional arguments intact.
        // This unfortunately results in inconsistent behavior between the
        // tearoff and the original functions.
        // TODO(joshualitt): Decide if we should disallow tearoffs of external
        // functions, and if so we can clean this up.
        FunctionNode function = node.function;
        function.body = transformedBody..parent = function;
        node.isExternal = false;
        return true;
      }
    }
    return false;
  }
}
