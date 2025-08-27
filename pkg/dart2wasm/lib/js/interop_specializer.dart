// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/js_interop.dart'
    show
        getDartJSInteropJSName,
        getJSName,
        hasAnonymousAnnotation,
        hasJSInteropAnnotation;
import 'package:_js_interop_checks/src/transformations/js_util_optimizer.dart'
    show ExtensionIndex;
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'method_collector.dart';
import 'util.dart';

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
      factory._extensionIndex.isInstanceInteropMember(interopMethod);

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

  /// Whether this config is associated with a constructor or factory.
  bool get isConstructor;

  /// Whether this is a setter where there's no return value.
  bool get isSetter;

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
    String functionParameters = firstParameterIsObject
        ? '$object${callArguments.isEmpty ? '' : ',$callArgumentsString'}'
        : callArgumentsString;
    final body = bodyString(object, callArguments);

    if (parametersNeedParens(parameterNames)) {
      functionParameters = '($functionParameters)';
    }
    return isSetter
        ? '$functionParameters => { $body }'
        : '$functionParameters => $body';
  }

  /// Returns an [Expression] representing the specialization of a given
  /// [StaticInvocation] or [Procedure].
  Expression specialize();

  Procedure _getRawInteropProcedure() {
    // Initialize variable declarations.
    List<String> jsParameterStrings = [];
    List<VariableDeclaration> dartPositionalParameters = [];
    for (int i = 0; i < parameters.length; i++) {
      final VariableDeclaration parameter = parameters[i];
      final DartType parameterType = parameter.type;
      final interopFunctionParameterType =
          parameterType == _util.coreTypes.doubleNonNullableRawType
              ? _util.coreTypes.doubleNonNullableRawType
              : _util.nullableWasmExternRefType;
      String parameterString = 'x$i';
      dartPositionalParameters.add(VariableDeclaration(parameterString,
          type: interopFunctionParameterType, isSynthesized: true));
      jsParameterStrings.add(parameterString);
    }

    // Create Dart procedure stub for JS method.
    String jsMethodName = _methodCollector.generateMethodName();
    final dartProcedure = _methodCollector.addInteropProcedure(
      '|$jsMethodName',
      'dart2wasm.$jsMethodName',
      FunctionNode(null,
          positionalParameters: dartPositionalParameters,
          returnType: function.returnType is VoidType
              ? VoidType()
              : _util.nullableWasmExternRefType),
      fileUri,
      AnnotationType.import,
      library: interopMethod.enclosingLibrary,
      isExternal: true,
    );
    _methodCollector.addMethod(
        dartProcedure, jsMethodName, generateJS(jsParameterStrings));
    return dartProcedure;
  }

  /// Creates a Dart procedure that calls out to a specialized JS method for the
  /// given [config] and returns the created procedure.
  Procedure _getOrCreateInteropProcedure() {
    // Procedures are cached based on number of arguments they're passed at the
    // call sites.
    Procedure? cachedProcedure =
        _overloadedProcedures[interopMethod]?[parameters.length];
    if (cachedProcedure != null) return cachedProcedure;
    final dartProcedure = _getRawInteropProcedure();
    _overloadedProcedures.putIfAbsent(
        interopMethod, () => {})[parameters.length] = dartProcedure;
    return dartProcedure;
  }
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
    final interopProcedure = _getOrCreateInteropProcedure();
    final interopProcedureType =
        interopProcedure.computeSignatureOrFunctionType();
    final List<Expression> jsifiedArguments = [];
    for (int i = 0; i < parameters.length; i += 1) {
      jsifiedArguments.add(jsifyValue(
          parameters[i],
          interopProcedureType.positionalParameters[i],
          factory._util,
          factory._staticTypeContext.typeEnvironment));
    }
    final invocation =
        StaticInvocation(interopProcedure, Arguments(jsifiedArguments));
    return _util.castInvocationForReturn(invocation, function.returnType);
  }
}

class _ConstructorSpecializer extends _ProcedureSpecializer {
  _ConstructorSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => true;

  @override
  bool get isSetter => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "new $jsString(${callArguments.join(',')})";
}

class _GetterSpecializer extends _ProcedureSpecializer {
  _GetterSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  bool get isSetter => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      '$object.$jsString';
}

class _SetterSpecializer extends _ProcedureSpecializer {
  _SetterSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  bool get isSetter => true;

  @override
  String bodyString(String object, List<String> callArguments) =>
      '$object.$jsString = ${callArguments[0]}';
}

class _MethodSpecializer extends _ProcedureSpecializer {
  _MethodSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  bool get isSetter => false;

  @override
  String bodyString(String object, List<String> callArguments) =>
      "$object.$jsString(${callArguments.join(',')})";
}

class _OperatorSpecializer extends _ProcedureSpecializer {
  _OperatorSpecializer(super.factory, super.interopMethod, super.jsString);

  @override
  bool get isConstructor => false;

  @override
  bool get isSetter => switch (jsString) {
        '[]' => false,
        '[]=' => true,
        _ => throw UnimplementedError(
            'External operator $jsString is unsupported for static interop. '
            'Please file a request in the SDK if you want it to be supported.')
      };

  @override
  String bodyString(String object, List<String> callArguments) {
    return isSetter
        ? '$object[${callArguments[0]}] = ${callArguments[1]}'
        : '$object[${callArguments[0]}]';
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
    final interopProcedure = _getOrCreateInteropProcedure();
    final interopProcedureType =
        interopProcedure.computeSignatureOrFunctionType();
    final List<Expression> jsifiedArguments = [];
    final List<Expression> arguments = invocation.arguments.positional;
    for (int i = 0; i < arguments.length; i += 1) {
      final temp = VariableDeclaration(null,
          initializer: arguments[i],
          type: arguments[i].getStaticType(factory._staticTypeContext),
          isSynthesized: true);
      jsifiedArguments.add(Let(
          temp,
          jsifyValue(temp, interopProcedureType.positionalParameters[i],
              factory._util, factory._staticTypeContext.typeEnvironment)));
    }
    final staticInvocation =
        StaticInvocation(interopProcedure, Arguments(jsifiedArguments));
    return _util.castInvocationForReturn(
        staticInvocation, invocation.getStaticType(_staticTypeContext));
  }
}

class _ConstructorInvocationSpecializer
    extends _PositionalInvocationSpecializer {
  _ConstructorInvocationSpecializer(
      super.factory, super.interopMethod, super.jsString, super.invocation);

  @override
  bool get isConstructor => true;

  @override
  bool get isSetter => false;

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
  bool get isSetter => false;

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
  bool get isSetter => false;

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

  /// The name to use in JavaScript for the Dart parameter [variable].
  ///
  /// This defaults to the name of the [variable], but can be changed with a
  /// `@JS()` annotation.
  String _jsKey(VariableDeclaration variable) {
    // Only support `@JS` renaming on extension type object literal
    // constructors.
    final changedName = interopMethod.isExtensionTypeMember
        ? getDartJSInteropJSName(variable)
        : '';
    return changedName.isEmpty ? variable.name! : changedName;
  }

  @override
  String bodyString(String object, List<String> callArguments) {
    final keys = parameters.map(_jsKey).toList();
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
    final shape = parameters.map(_jsKey).join('|');
    final interopProcedure = _jsObjectLiteralMethods
        .putIfAbsent(interopMethod, () => {})
        .putIfAbsent(shape, () => _getRawInteropProcedure());

    // Return the args in the order of the procedure's parameters and not
    // the invocation.
    final namedArgs = <String, Expression>{};
    for (NamedExpression expr in invocation.arguments.named) {
      namedArgs[expr.name] = expr.value;
    }
    final interopProcedureType =
        interopProcedure.computeSignatureOrFunctionType();
    final arguments =
        parameters.map<Expression>((decl) => namedArgs[decl.name!]!).toList();
    final List<Expression> jsifiedArguments = [];
    for (int i = 0; i < arguments.length; i += 1) {
      final temp = VariableDeclaration(null,
          initializer: arguments[i],
          type: arguments[i].getStaticType(factory._staticTypeContext),
          isSynthesized: true);
      jsifiedArguments.add(Let(
          temp,
          jsifyValue(temp, interopProcedureType.positionalParameters[i],
              factory._util, factory._staticTypeContext.typeEnvironment)));
    }
    assert(factory._extensionIndex.isStaticInteropType(function.returnType));
    return invokeOneArg(_util.jsValueBoxTarget,
        StaticInvocation(interopProcedure, Arguments(jsifiedArguments)));
  }
}

class InteropSpecializerFactory {
  final StatefulStaticTypeContext _staticTypeContext;
  final CoreTypesUtil _util;
  final MethodCollector _methodCollector;

  /// Maps an interop procedure to the trampolines based on number of arguments
  /// they take.
  ///
  /// `_overloadedProcedures[procedure][numberOfArgs]` gives the trampoline that
  /// should be called with `numberOfArgs` arguments.
  final Map<Procedure, Map<int, Procedure>> _overloadedProcedures = {};

  /// Maps an interop procedure for a JS object literal to trampolines based on
  /// named arguments that are passed at invocation sites. For example:
  ///
  /// ```
  /// extension type Literal._(JSObject _) implements JSObject {
  ///   external factory Literal.fact({double a, String b, bool c});
  /// }
  ///
  /// Literal.fact(a: 1.2);
  /// Literal.fact(a: 3.4, b: 'a');
  /// Literal.fact(a: 5.6, b: 'b');
  /// ```
  ///
  /// Here we map the procedure for `Literal.fact` to interop procedures, based
  /// on the named arguments passed.
  ///
  /// The `String` keys are named arguments passed in the call sites, joined by
  /// `|`. E.g. `"a|b"` in the second and third calls above.
  final Map<Procedure, Map<String, Procedure>> _jsObjectLiteralMethods = {};

  late final ExtensionIndex _extensionIndex;

  InteropSpecializerFactory(this._staticTypeContext, this._util,
      this._methodCollector, this._extensionIndex);

  String _getJSString(Annotatable a, String initial) {
    String selectorString = getJSName(a);
    if (selectorString.isEmpty) {
      selectorString = initial;
    }
    return selectorString;
  }

  String _getTopLevelJSString(
      Annotatable a, String writtenName, Library enclosingLibrary) {
    final name = _getJSString(a, writtenName);
    final libraryName = getJSName(enclosingLibrary);
    if (libraryName.isEmpty) return name;
    return '$libraryName.$name';
  }

  /// Get the `_Specializer` for the non-constructor [node] with its
  /// associated [jsString] name, and the [invocation] it's used in if this is
  /// an invocation-level lowering.
  _Specializer? _getSpecializerForMember(Procedure node, String jsString,
      [StaticInvocation? invocation]) {
    if (invocation == null) {
      if (_extensionIndex.isGetter(node)) {
        return _GetterSpecializer(this, node, jsString);
      } else if (_extensionIndex.isSetter(node)) {
        return _SetterSpecializer(this, node, jsString);
      } else if (_extensionIndex.isOperator(node)) {
        return _OperatorSpecializer(this, node, jsString);
      } else if (_extensionIndex.isMethod(node)) {
        return _MethodSpecializer(this, node, jsString);
      }
    } else {
      if (_extensionIndex.isMethod(node)) {
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
      final clsString =
          _getTopLevelJSString(cls, cls.name, cls.enclosingLibrary);
      if (node.isFactory) {
        return _getSpecializerForConstructor(
            hasAnonymousAnnotation(cls), node, clsString, invocation);
      } else {
        final memberSelectorString = _getJSString(node, node.name.text);
        return _getSpecializerForMember(
            node, '$clsString.$memberSelectorString', invocation);
      }
    } else if (node.isExtensionTypeMember) {
      final nodeDescriptor = _extensionIndex.getExtensionTypeDescriptor(node);
      if (nodeDescriptor != null) {
        final cls = _extensionIndex.getExtensionType(node)!;
        final clsString =
            _getTopLevelJSString(cls, cls.name, node.enclosingLibrary);
        final kind = nodeDescriptor.kind;
        if (kind == ExtensionTypeMemberKind.Constructor ||
            kind == ExtensionTypeMemberKind.Factory) {
          return _getSpecializerForConstructor(
              _extensionIndex.isLiteralConstructor(node),
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
      final nodeDescriptor = _extensionIndex.getExtensionDescriptor(node);
      if (nodeDescriptor != null && !nodeDescriptor.isStatic) {
        return _getSpecializerForMember(
            node, _getJSString(node, nodeDescriptor.name.text), invocation);
      }
    } else if (hasJSInteropAnnotation(node)) {
      return _getSpecializerForMember(
          node,
          _getTopLevelJSString(node, node.name.text, node.enclosingLibrary),
          invocation);
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
    if (!node.isExternal) {
      return false;
    }

    final specializer = _getSpecializer(node);
    if (specializer == null) {
      return false;
    }

    final expression = specializer.specialize();
    final transformedBody = specializer.function.returnType is VoidType
        ? ExpressionStatement(expression)
        : ReturnStatement(expression);

    // For the time being to support tearoffs we simply replace the body of the
    // original procedure, but leave all the optional arguments intact. This
    // unfortunately results in inconsistent behavior between the tearoff and
    // the original functions.
    // TODO(joshualitt): Decide if we should disallow tearoffs of external
    // functions, and if so we can clean this up.
    FunctionNode function = node.function;
    function.body = transformedBody..parent = function;
    node.isExternal = false;
    return true;
  }
}
