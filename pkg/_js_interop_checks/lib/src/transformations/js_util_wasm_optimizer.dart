// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../js_interop.dart'
    show
        getJSName,
        hasAnonymousAnnotation,
        hasStaticInteropAnnotation,
        hasJSInteropAnnotation;

/// Replaces:
///   1) Factory constructors in classes with `@staticInterop` annotations with
///      calls to `js_util.callConstructor`.
///   2) External methods in `@staticInterop` class extensions to their
///      corresponding `js_util` calls.
/// TODO(joshualitt): In the long term we'd like to have the same
/// `JsUtilOptimizer` for all web backends. This is to ensure uniform semantics
/// across all web backends. Some known challenges remain, and there may be
/// unknown challenges that appear as we proceed. Known challenges include:
///   1) Some constructs may need to be restricted on Dart2wasm, for example
///      callbacks must be fully typed for the time being, though we could
///      generalize this using `Function.apply`, but this is currently not
///      implemented on Dart2wasm.
///   2) We may want to handle this lowering differently on Dart2wasm in the
///      long term. Currently, js_util on Wasm is implemented using a single
///      trampoline per js_util function. We may want to specialize these
///      trampolines based off the interop type, to avoid megamorphic behavior.
///      This would have code size implications though, so we would need to
///      proceed carefully.
/// TODO(joshualitt): A few of the functions in this file use js_utils in a
/// naive way, and could be optimized further. In particular, there are a few
/// complex operations in [JsUtilWasmOptimizer] where it is obvious a value is
/// flowing from / to JS, and we have a few options for optimization:
///    1) Integrate with `js_ast` and emit custom JavaScript for each of these
///       operations.
///    2) Use the `raw` variants of the js_util calls.
///    3) Move more of the logic for these calls into JS where it will likely be
///       faster.
class JsUtilWasmOptimizer extends Transformer {
  final Procedure _callMethodTarget;
  final Procedure _callConstructorTarget;
  final Procedure _getPropertyTarget;
  final Procedure _setPropertyTarget;
  final Procedure _jsifyRawTarget;
  final Procedure _newObjectTarget;
  final Procedure _wrapDartFunctionTarget;
  final Procedure _allowInteropTarget;
  final Procedure _numToInt;
  final Class _wasmExternRefClass;
  final Class _pragmaClass;
  final Field _pragmaName;
  final Field _pragmaOptions;
  final Member _globalThisMember;
  int _functionTrampolineN = 1;
  late Library _library;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;
  Map<Reference, ExtensionMemberDescriptor>? _extensionMemberIndex;
  final Set<Class> _transformedClasses = {};

  JsUtilWasmOptimizer(this._coreTypes, ClassHierarchy hierarchy)
      : _callMethodTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js_util', 'callMethod'),
        _globalThisMember = _coreTypes.index
            .getTopLevelMember('dart:js_util', 'get:globalThis'),
        _callConstructorTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'callConstructor'),
        _getPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'getProperty'),
        _setPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'setProperty'),
        _jsifyRawTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyRaw'),
        _wrapDartFunctionTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_wrapDartFunction'),
        _newObjectTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js_util', 'newObject'),
        _allowInteropTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js', 'allowInterop'),
        _wasmExternRefClass =
            _coreTypes.index.getClass('dart:wasm', 'WasmExternRef'),
        _numToInt = _coreTypes.index
            .getClass('dart:core', 'num')
            .procedures
            .firstWhere((p) => p.name.text == 'toInt'),
        _pragmaClass = _coreTypes.pragmaClass,
        _pragmaName = _coreTypes.pragmaName,
        _pragmaOptions = _coreTypes.pragmaOptions,
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {}

  @override
  Library visitLibrary(Library lib) {
    _library = lib;
    _staticTypeContext.enterLibrary(lib);
    lib.transformChildren(this);
    _staticTypeContext.leaveLibrary(lib);
    _extensionMemberIndex = null;
    _transformedClasses.clear();
    return lib;
  }

  @override
  Member defaultMember(Member node) {
    _staticTypeContext.enterMember(node);
    node.transformChildren(this);
    _staticTypeContext.leaveMember(node);
    return node;
  }

  @override
  StaticInvocation visitStaticInvocation(StaticInvocation node) {
    node = super.visitStaticInvocation(node) as StaticInvocation;
    if (node.target == _allowInteropTarget) {
      Expression argument = node.arguments.positional.single;
      DartType functionType = argument.getStaticType(_staticTypeContext);
      return _allowInterop(node.target, functionType as FunctionType, argument);
    }
    return node;
  }

  @override
  Procedure visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    Statement? transformedBody;
    if (node.isExternal) {
      if (node.isFactory) {
        Class cls = node.enclosingClass!;
        if (hasStaticInteropAnnotation(cls)) {
          if (hasAnonymousAnnotation(cls)) {
            transformedBody = _getExternalAnonymousConstructorBody(node);
          } else {
            _JSMemberSelector selector = _processJSName(cls, cls.name, node);
            transformedBody = _getExternalCallConstructorBody(
                node, selector.target, selector.member);
          }
        }
      } else if (node.isExtensionMember) {
        var index = _extensionMemberIndex ??=
            _createExtensionMembersIndex(node.enclosingLibrary);
        var nodeDescriptor = index[node.reference];
        if (nodeDescriptor != null) {
          if (!nodeDescriptor.isStatic) {
            if (nodeDescriptor.kind == ExtensionMemberKind.Getter) {
              transformedBody = _getExternalExtensionGetterBody(node);
            } else if (nodeDescriptor.kind == ExtensionMemberKind.Setter) {
              transformedBody = _getExternalExtensionSetterBody(node);
            } else if (nodeDescriptor.kind == ExtensionMemberKind.Method) {
              transformedBody = _getExternalExtensionMethodBody(node);
            }
          }
        }
      } else if (hasJSInteropAnnotation(node)) {
        _JSMemberSelector selector = _processJSName(node, node.name.text, node);
        Expression target = selector.target;
        String name = selector.member;
        if (node.isGetter) {
          transformedBody = _getExternalGetterBody(node, target, name);
        } else if (node.isSetter) {
          transformedBody = _getExternalSetterBody(
              node, target, name, node.function.positionalParameters.single);
        } else {
          assert(node.kind == ProcedureKind.Method);
          transformedBody = _getExternalMethodBody(
              node, target, name, node.function.positionalParameters);
        }
      }
    }
    if (transformedBody != null) {
      node.function.body = transformedBody..parent = node.function;
      node.isExternal = false;
    } else {
      node.transformChildren(this);
    }
    _staticTypeContext.leaveMember(node);
    return node;
  }

  _JSMemberSelector _processJSName(
      Annotatable a, String nameOnEmpty, Procedure node) {
    String selectorString = getJSName(a);
    Expression target;
    String name;
    if (selectorString.isEmpty) {
      target = _globalThis;
      name = nameOnEmpty;
    } else {
      List<String> selectors = selectorString.split('.');
      if (selectors.length == 1) {
        target = _globalThis;
        name = selectors.single;
      } else {
        target = getObjectOffGlobalThis(
            node, selectors.sublist(0, selectors.length - 1));
        name = selectors.last;
      }
    }
    return _JSMemberSelector(target, name);
  }

  /// Returns and initializes `_extensionMemberIndex` to an index of the member
  /// reference to the member `ExtensionMemberDescriptor`, for all extension
  /// members in the given [library] of classes annotated with
  /// `@staticInterop`.
  Map<Reference, ExtensionMemberDescriptor> _createExtensionMembersIndex(
      Library library) {
    _extensionMemberIndex = {};
    library.extensions.forEach((extension) {
      DartType onType = extension.onType;
      if (onType is InterfaceType &&
          hasStaticInteropAnnotation(onType.className.asClass)) {
        extension.members.forEach((descriptor) {
          _extensionMemberIndex![descriptor.member] = descriptor;
        });
      }
    });
    return _extensionMemberIndex!;
  }

  DartType get _nullableObjectType =>
      _coreTypes.objectRawType(Nullability.nullable);

  DartType get _nonNullableObjectType =>
      _coreTypes.objectRawType(Nullability.nonNullable);

  Expression _variableCheckConstant(
          VariableDeclaration variable, Constant constant) =>
      StaticInvocation(_coreTypes.identicalProcedure,
          Arguments([VariableGet(variable), ConstantExpression(constant)]));

  Expression _variableNullCheck(VariableDeclaration variable) =>
      _variableCheckConstant(variable, NullConstant());

  List<Expression> _generateCallbackArguments(
      FunctionType function, List<VariableDeclaration> positionalParameters,
      [int? requiredParameterCount]) {
    List<Expression> callbackArguments = [];
    int length = requiredParameterCount ?? function.positionalParameters.length;
    for (int i = 0; i < length; i++) {
      callbackArguments.add(AsExpression(VariableGet(positionalParameters[i]),
          function.positionalParameters[i]));
    }
    return callbackArguments;
  }

  Statement _generateDispatchCase(
          FunctionType function,
          VariableDeclaration callbackVariable,
          List<VariableDeclaration> positionalParameters,
          [int? requiredParameterCount]) =>
      ReturnStatement(StaticInvocation(
          _jsifyRawTarget,
          Arguments([
            FunctionInvocation(
                FunctionAccessKind.FunctionType,
                AsExpression(VariableGet(callbackVariable), function),
                Arguments(_generateCallbackArguments(
                    function, positionalParameters, requiredParameterCount)),
                functionType: function),
          ])));

  /// Builds the body of a function trampoline. To support default arguments, we
  /// find the last defined argument in JS, that is the last argument which was
  /// explicitly passed by the user, and then we dispatch to a Dart function
  /// with the right number of arguments.
  Statement _createFunctionTrampolineBody(
      FunctionType function,
      VariableDeclaration callbackVariable,
      VariableDeclaration lastDefinedArgument,
      List<VariableDeclaration> positionalParameters) {
    // Handle cases where some or all arguments are undefined.
    // TODO(joshualitt): Consider using a switch instead.
    List<Statement> dispatchCases = [];
    for (int i = function.requiredParameterCount - 1;
        i < function.positionalParameters.length;
        i++) {
      // In this case, [i] is the last defined argument which can range from
      // -1(no arguments defined), to an actual index in the positional
      // parameters. [_generateDispatchCase] must also take the required
      // parameter count, which is always the index of the last defined argument
      // + 1, i.e. the total number of defined arguments.
      int requiredParameterCount = i + 1;
      dispatchCases.add(IfStatement(
          _variableCheckConstant(
              lastDefinedArgument, DoubleConstant(i.toDouble())),
          _generateDispatchCase(function, callbackVariable,
              positionalParameters, requiredParameterCount),
          null));
    }

    // Finally handle the case where all arguments are defined.
    dispatchCases.add(_generateDispatchCase(
        function, callbackVariable, positionalParameters));

    return Block(dispatchCases);
  }

  /// Creates a callback trampoline for the given [function]. This callback
  /// trampoline expects a Dart callback as its first argument, then an integer
  /// value(double type) indicating the position of the last defined argument,
  /// followed by all of the arguments to the Dart callback as Dart objects.  We
  /// will always pad the argument list up to the maximum number of positional
  /// arguments with `undefined` values.  The trampoline will cast all incoming
  /// Dart objects to the appropriate types, dispatch, and then `jsifyRaw` any
  /// returned value. [_createFunctionTrampoline] Returns a [String] function
  /// name representing the name of the wrapping function.
  /// TODO(joshualitt): Share callback trampolines if the [FunctionType]
  /// matches.
  /// TODO(joshualitt): Simplify the trampoline in JS for the case where there
  /// are no default arguments.
  String _createFunctionTrampoline(Procedure node, FunctionType function) {
    int fileOffset = node.fileOffset;

    // Create arguments for each positional parameter in the function. These
    // arguments will be converted in JS to Dart objects. The generated wrapper
    // will cast each argument to the correct type.  The first argument to this
    // function will be the Dart callback, which will be cast to the supplied
    // [FunctionType] before being invoked. The second argument will be the
    // last defined argument which is necessary to support default arguments in
    // callbacks.
    int parameterId = 1;
    final callbackVariable =
        VariableDeclaration('callback', type: _nonNullableObjectType);
    final lastDefinedArgument = VariableDeclaration('lastDefinedArgument',
        type: _coreTypes.doubleNonNullableRawType);

    // Initialize variable declarations.
    List<VariableDeclaration> positionalParameters = [];
    for (int j = 0; j < function.positionalParameters.length; j++) {
      positionalParameters.add(
          VariableDeclaration('x${parameterId++}', type: _nullableObjectType));
    }

    Statement functionTrampolineBody = _createFunctionTrampolineBody(
        function, callbackVariable, lastDefinedArgument, positionalParameters);

    // Create a new procedure for the callback trampoline. This procedure will
    // be exported from Wasm to JS so it can be called from JS. The argument
    // returned from the supplied callback will be converted with `jsifyRaw` to
    // a native JS value before being returned to JS.
    DartType nullableWasmExternRefType =
        _wasmExternRefClass.getThisType(_coreTypes, Nullability.nullable);
    final String libraryName = _library.name ?? 'Unnamed';
    final functionTrampolineName =
        '|_functionTrampoline${_functionTrampolineN++}For$libraryName';
    final functionTrampolineImportName = '\$$functionTrampolineName';
    final functionTrampoline = Procedure(
        Name(functionTrampolineName, _library),
        ProcedureKind.Method,
        FunctionNode(functionTrampolineBody,
            positionalParameters: [callbackVariable, lastDefinedArgument]
                .followedBy(positionalParameters)
                .toList(),
            returnType: nullableWasmExternRefType)
          ..fileOffset = fileOffset,
        isStatic: true,
        fileUri: node.fileUri)
      ..fileOffset = fileOffset
      ..isNonNullableByDefault = true;
    functionTrampoline.addAnnotation(
        ConstantExpression(InstanceConstant(_pragmaClass.reference, [], {
      _pragmaName.fieldReference: StringConstant('wasm:export'),
      _pragmaOptions.fieldReference:
          StringConstant(functionTrampolineImportName)
    })));
    _library.addProcedure(functionTrampoline);
    return functionTrampolineImportName;
  }

  /// Lowers a [StaticInvocation] of `allowInterop` to
  /// [_createFunctionTrampoline] followed by `_wrapDartFunction`.
  StaticInvocation _allowInterop(
      Procedure node, FunctionType type, Expression argument) {
    String functionTrampolineName = _createFunctionTrampoline(node, type);
    return StaticInvocation(
        _wrapDartFunctionTarget,
        Arguments([
          argument,
          StringLiteral(functionTrampolineName),
          ConstantExpression(IntConstant(type.positionalParameters.length))
        ], types: [
          type
        ]));
  }

  StaticGet get _globalThis => StaticGet(_globalThisMember);

  /// Takes a list of [selectors] and returns an object off of
  /// `globalThis`. We could optimize this with a custom method built with
  /// js_ast.
  Expression getObjectOffGlobalThis(Procedure node, List<String> selectors) {
    Expression currentTarget = _globalThis;
    for (String selector in selectors) {
      currentTarget = _getProperty(node, currentTarget, selector,
          typeArgument: _nonNullableObjectType);
    }
    return currentTarget;
  }

  /// Returns a new function body for the given [node] external factory method
  /// for a class annotated with `@anonymous`.
  ///
  /// This lowers a factory function with named arguments to the creation of a
  /// new object literal, and a series of `setProperty` calls.
  Block _getExternalAnonymousConstructorBody(Procedure node) {
    List<Statement> body = [];
    final object = VariableDeclaration('|anonymousObject',
        initializer: StaticInvocation(
            _newObjectTarget, Arguments([], types: [node.function.returnType])),
        type: _nonNullableObjectType);
    body.add(object);
    for (VariableDeclaration variable in node.function.namedParameters) {
      body.add(ExpressionStatement(_setProperty(
          node, VariableGet(object), variable.name!, variable,
          typeArgument: variable.type)));
    }
    body.add(ReturnStatement(VariableGet(object)));
    return Block(body);
  }

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body will call `js_util.callConstructor`
  /// for the given external method.
  ReturnStatement _getExternalCallConstructorBody(
      Procedure node, Expression target, String constructorName) {
    var function = node.function;
    var callConstructorInvocation = StaticInvocation(
        _callConstructorTarget,
        Arguments([
          _getProperty(node, target, constructorName),
          ListLiteral(
              function.positionalParameters
                  .map<Expression>((value) => VariableGet(value))
                  .toList(),
              typeArgument: _nullableObjectType)
        ], types: [
          node.function.returnType
        ]))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(callConstructorInvocation);
  }

  // Handles any necessary return type conversions. Today this is just for
  // handling the case where a user wants us to coerce a JS number to an int
  // instead of a double.
  Expression _convertReturnType(DartType type, Expression expression) {
    if (type == _coreTypes.intNullableRawType ||
        type == _coreTypes.intNonNullableRawType) {
      VariableDeclaration v =
          VariableDeclaration('#var', initializer: expression);
      return Let(
          v,
          ConditionalExpression(
              _variableNullCheck(v),
              ConstantExpression(NullConstant()),
              InstanceInvocation(InstanceAccessKind.Instance, VariableGet(v),
                  _numToInt.name, Arguments([]),
                  interfaceTarget: _numToInt,
                  functionType: _numToInt.function
                      .computeFunctionType(Nullability.nonNullable)),
              type));
    } else {
      return expression;
    }
  }

  Expression _callAndConvertReturn(
      DartType returnType, Expression generateCall(DartType type)) {
    // Because we simply don't have enough information, we leave all JS numbers
    // as doubles. However, in cases where we know the user expects an `int` we
    // insert a cast.
    DartType typeArgumentOverride = returnType == _coreTypes.intNullableRawType
        ? _coreTypes.doubleNullableRawType
        : returnType == _coreTypes.intNonNullableRawType
            ? _coreTypes.doubleNonNullableRawType
            : returnType;
    return _convertReturnType(returnType, generateCall(typeArgumentOverride));
  }

  /// Returns a new [Expression] for the given [node] external getter.
  ///
  /// The new [Expression] is equivalent to:
  /// `js_util.getProperty([object], [getterName])`.
  Expression _getProperty(Procedure node, Expression object, String getterName,
          {DartType? typeArgument}) =>
      _callAndConvertReturn(
          typeArgument ?? node.function.returnType,
          (DartType typeArgumentOverride) => StaticInvocation(
              _getPropertyTarget,
              Arguments([object, StringLiteral(getterName)],
                  types: [typeArgumentOverride]))
            ..fileOffset = node.fileOffset);

  /// Returns a new function body for the given [node] external getter.
  ReturnStatement _getExternalGetterBody(
          Procedure node, Expression object, String getterName) =>
      ReturnStatement(_getProperty(node, object, getterName));

  ReturnStatement _getExternalExtensionGetterBody(Procedure node) =>
      _getExternalGetterBody(
          node,
          VariableGet(node.function.positionalParameters.single),
          _getExtensionMemberName(node));

  /// Returns a new [Expression] for the given [node] external setter.
  ///
  /// The new [Expression] is equivalent to:
  /// `js_util.setProperty([object], [setterName], [value])`.
  Expression _setProperty(Procedure node, Expression object, String setterName,
          VariableDeclaration value, {DartType? typeArgument}) =>
      StaticInvocation(
          _setPropertyTarget,
          Arguments([object, StringLiteral(setterName), VariableGet(value)],
              types: [typeArgument ?? node.function.returnType]))
        ..fileOffset = node.fileOffset;

  /// Returns a new function body for the given [node] external setter.
  ReturnStatement _getExternalSetterBody(Procedure node, Expression object,
          String setterName, VariableDeclaration value) =>
      ReturnStatement(_setProperty(node, object, setterName, value));

  ReturnStatement _getExternalExtensionSetterBody(Procedure node) {
    final parameters = node.function.positionalParameters;
    assert(parameters.length == 2);
    return _getExternalSetterBody(node, VariableGet(parameters.first),
        _getExtensionMemberName(node), parameters.last);
  }

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body is equivalent to:
  /// `js_util.callMethod([object], [methodName], [values])`.
  ReturnStatement _getExternalMethodBody(Procedure node, Expression object,
          String methodName, List<VariableDeclaration> values) =>
      ReturnStatement(_callAndConvertReturn(
          node.function.returnType,
          (DartType typeArgumentOverride) => StaticInvocation(
              _callMethodTarget,
              Arguments([
                object,
                StringLiteral(methodName),
                ListLiteral(
                    values
                        .map<Expression>((value) => VariableGet(value))
                        .toList(),
                    typeArgument: _nullableObjectType)
              ], types: [
                typeArgumentOverride,
              ]))
            ..fileOffset = node.fileOffset));

  ReturnStatement _getExternalExtensionMethodBody(Procedure node) {
    final parameters = node.function.positionalParameters;
    assert(parameters.isNotEmpty);
    return _getExternalMethodBody(node, VariableGet(parameters.first),
        _getExtensionMemberName(node), parameters.sublist(1));
  }

  /// Returns the extension member name.
  ///
  /// Returns either the name from the `@JS` annotation if non-empty, or the
  /// declared name of the extension member. Does not return the CFE generated
  /// name for the top level member for this extension member.
  String _getExtensionMemberName(Procedure node) {
    var jsAnnotationName = getJSName(node);
    if (jsAnnotationName.isNotEmpty) {
      return jsAnnotationName;
    }
    return _extensionMemberIndex![node.reference]!.name.text;
  }
}

class _JSMemberSelector {
  final Expression target;
  final String member;

  _JSMemberSelector(this.target, this.member);
}
