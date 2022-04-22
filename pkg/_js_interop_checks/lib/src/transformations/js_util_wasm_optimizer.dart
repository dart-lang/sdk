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
///      calls to `js_util_wasm.callConstructorVarArgs`.
///   2) External methods in `@staticInterop` class extensions to their
///      corresponding `js_util_wasm` calls.
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
  final Procedure _globalThisTarget;
  final Procedure _getPropertyTarget;
  final Procedure _setPropertyTarget;
  final Procedure _jsifyTarget;
  final Procedure _jsifyRawTarget;
  final Procedure _dartifyTarget;
  final Procedure _newObjectTarget;
  final Procedure _wrapDartCallbackTarget;
  final Procedure _allowInteropTarget;
  final Class _jsValueClass;
  final Class _wasmAnyRefClass;
  final Class _objectClass;
  final Class _pragmaClass;
  final Field _pragmaName;
  final Field _pragmaOptions;
  int _callbackTrampolineN = 1;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;
  Map<Reference, ExtensionMemberDescriptor>? _extensionMemberIndex;
  final Set<Class> _transformedClasses = {};

  JsUtilWasmOptimizer(this._coreTypes, ClassHierarchy hierarchy)
      : _callMethodTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'callMethodVarArgs'),
        _globalThisTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'globalThis'),
        _callConstructorTarget = _coreTypes.index.getTopLevelProcedure(
            'dart:js_util_wasm', 'callConstructorVarArgs'),
        _getPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'getProperty'),
        _setPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'setProperty'),
        _jsifyTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js_util_wasm', 'jsify'),
        _jsifyRawTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'jsifyRaw'),
        _dartifyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'dartify'),
        _wrapDartCallbackTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', '_wrapDartCallback'),
        _newObjectTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'newObject'),
        _allowInteropTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'allowInterop'),
        _jsValueClass =
            _coreTypes.index.getClass('dart:js_util_wasm', 'JSValue'),
        _wasmAnyRefClass = _coreTypes.index.getClass('dart:wasm', 'WasmAnyRef'),
        _objectClass = _coreTypes.objectClass,
        _pragmaClass = _coreTypes.pragmaClass,
        _pragmaName = _coreTypes.pragmaName,
        _pragmaOptions = _coreTypes.pragmaOptions,
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {}

  @override
  Library visitLibrary(Library lib) {
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
            String jsName = getJSName(cls);
            String constructorName = jsName == '' ? cls.name : jsName;
            transformedBody =
                _getExternalCallConstructorBody(node, constructorName);
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
        String selectorString = getJSName(node);
        late Expression target;
        if (selectorString.isEmpty) {
          target = _globalThis;
        } else {
          List<String> selectors = selectorString.split('.');
          target = getObjectOffGlobalThis(node, selectors);
        }
        if (node.isGetter) {
          transformedBody = _getExternalTopLevelGetterBody(node, target);
        } else if (node.isSetter) {
          transformedBody = _getExternalTopLevelSetterBody(node, target);
        } else {
          assert(node.kind == ProcedureKind.Method);
          transformedBody = _getExternalTopLevelMethodBody(node, target);
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

  DartType get _nullableJSValueType =>
      _jsValueClass.getThisType(_coreTypes, Nullability.nullable);

  DartType get _nonNullableJSValueType =>
      _jsValueClass.getThisType(_coreTypes, Nullability.nonNullable);

  Expression _dartify(Expression expression) =>
      StaticInvocation(_dartifyTarget, Arguments([expression]));

  /// Creates a callback trampoline for the given [function]. This callback
  /// trampoline expects a Dart callback as its first argument, followed by all
  /// of the arguments to the Dart callback as Dart objects. The trampoline will
  /// cast all incoming Dart objects to the appropriate types, dispatch, and
  /// then `jsifyRaw` any returned value. [_createCallbackTrampoline] Returns a
  /// [String] function name representing the name of the wrapping function.
  /// TODO(joshualitt): Share callback trampolines if the [FunctionType]
  /// matches.
  String _createCallbackTrampoline(Procedure node, FunctionType function) {
    int fileOffset = node.fileOffset;
    Library library = node.enclosingLibrary;

    // Create arguments for each positional parameter in the function. These
    // arguments will be converted in JS to Dart objects. The generated wrapper
    // will cast each argument to the correct type.  The first argument to this
    // function will be the Dart callback, which will be cast to the supplied
    // [FunctionType] before being invoked.
    int parameterId = 1;
    DartType nonNullableObjectType =
        _objectClass.getThisType(_coreTypes, Nullability.nonNullable);
    final callbackVariable =
        VariableDeclaration('callback', type: nonNullableObjectType);
    List<VariableDeclaration> positionalParameters = [callbackVariable];
    List<Expression> callbackArguments = [];
    DartType nullableObjectType =
        _objectClass.getThisType(_coreTypes, Nullability.nullable);
    for (DartType type in function.positionalParameters) {
      VariableDeclaration variable =
          VariableDeclaration('x${parameterId++}', type: nullableObjectType);
      positionalParameters.add(variable);
      callbackArguments.add(AsExpression(VariableGet(variable), type));
    }

    // Create a new procedure for the callback trampoline. This procedure will
    // be exported from Wasm to JS so it can be called from JS. The argument
    // returned from the supplied callback will be converted with `jsifyRaw` to
    // a native JS value before being returned to JS.
    DartType nullableWasmAnyRefType =
        _wasmAnyRefClass.getThisType(_coreTypes, Nullability.nullable);
    final callbackTrampolineName =
        '|_callbackTrampoline${_callbackTrampolineN++}';
    final callbackTrampolineImportName = '\$$callbackTrampolineName';
    final callbackTrampoline = Procedure(
        Name(callbackTrampolineName, library),
        ProcedureKind.Method,
        FunctionNode(
            ReturnStatement(StaticInvocation(
                _jsifyRawTarget,
                Arguments([
                  FunctionInvocation(
                      FunctionAccessKind.FunctionType,
                      AsExpression(VariableGet(callbackVariable), function),
                      Arguments(callbackArguments),
                      functionType: function),
                ]))),
            positionalParameters: positionalParameters,
            returnType: nullableWasmAnyRefType)
          ..fileOffset = fileOffset,
        isStatic: true,
        fileUri: node.fileUri)
      ..fileOffset = fileOffset
      ..isNonNullableByDefault = true;
    callbackTrampoline.addAnnotation(
        ConstantExpression(InstanceConstant(_pragmaClass.reference, [], {
      _pragmaName.fieldReference: StringConstant('wasm:export'),
      _pragmaOptions.fieldReference:
          StringConstant(callbackTrampolineImportName)
    })));
    library.addProcedure(callbackTrampoline);
    return callbackTrampolineImportName;
  }

  /// Lowers a [StaticInvocation] of `allowInterop` to
  /// [_createCallbackTrampoline] followed by `_wrapDartCallback`.
  StaticInvocation _allowInterop(
      Procedure node, FunctionType type, Expression argument) {
    String callbackTrampolineName = _createCallbackTrampoline(node, type);
    return StaticInvocation(_wrapDartCallbackTarget,
        Arguments([argument, StringLiteral(callbackTrampolineName)]));
  }

  Expression _jsifyVariable(Procedure node, VariableDeclaration variable) {
    if (variable.type is FunctionType) {
      return _allowInterop(
          node, variable.type as FunctionType, VariableGet(variable));
    } else {
      return StaticInvocation(_jsifyTarget, Arguments([VariableGet(variable)]));
    }
  }

  StaticInvocation get _globalThis =>
      StaticInvocation(_globalThisTarget, Arguments([]));

  /// Takes a list of [selectors] and returns an object off of
  /// `globalThis`. We could optimize this with a custom method built with
  /// js_ast.
  Expression getObjectOffGlobalThis(Procedure node, List<String> selectors) {
    Expression currentTarget = _globalThis;
    for (String selector in selectors) {
      currentTarget = _getProperty(node, currentTarget, selector);
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
        initializer: StaticInvocation(_newObjectTarget, Arguments([])),
        type: _nonNullableJSValueType);
    body.add(object);
    for (VariableDeclaration variable in node.function.namedParameters) {
      body.add(ExpressionStatement(
          _setProperty(node, VariableGet(object), variable.name!, variable)));
    }
    body.add(ReturnStatement(VariableGet(object)));
    return Block(body);
  }

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body will call `js_util_wasm.callConstructorVarArgs`
  /// for the given external method.
  ReturnStatement _getExternalCallConstructorBody(
      Procedure node, String constructorName) {
    var function = node.function;
    var callConstructorInvocation = StaticInvocation(
        _callConstructorTarget,
        Arguments([
          _globalThis,
          StringLiteral(constructorName),
          ListLiteral(
              function.positionalParameters
                  .map((arg) => _jsifyVariable(node, arg))
                  .toList(),
              typeArgument: _nonNullableJSValueType)
        ]))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(callConstructorInvocation);
  }

  /// Returns a new [Expression] for the given [node] external getter.
  ///
  /// The new [Expression] is equivalent to:
  /// `js_util_wasm.getProperty([object], [getterName])`.
  Expression _getProperty(
          Procedure node, Expression object, String getterName) =>
      StaticInvocation(
          _getPropertyTarget, Arguments([object, StringLiteral(getterName)]))
        ..fileOffset = node.fileOffset;

  /// Returns a new function body for the given [node] external getter.
  ReturnStatement _getExternalGetterBody(
          Procedure node, Expression object, String getterName) =>
      ReturnStatement(_dartify(_getProperty(node, object, getterName)));

  ReturnStatement _getExternalExtensionGetterBody(Procedure node) =>
      _getExternalGetterBody(
          node,
          VariableGet(node.function.positionalParameters.single),
          _getExtensionMemberName(node));

  ReturnStatement _getExternalTopLevelGetterBody(
          Procedure node, Expression target) =>
      _getExternalGetterBody(node, target, node.name.text);

  /// Returns a new [Expression] for the given [node] external setter.
  ///
  /// The new [Expression] is equivalent to:
  /// `js_util_wasm.setProperty([object], [setterName], [value])`.
  Expression _setProperty(Procedure node, Expression object, String setterName,
          VariableDeclaration value) =>
      StaticInvocation(
          _setPropertyTarget,
          Arguments(
              [object, StringLiteral(setterName), _jsifyVariable(node, value)]))
        ..fileOffset = node.fileOffset;

  /// Returns a new function body for the given [node] external setter.
  ReturnStatement _getExternalSetterBody(Procedure node, Expression object,
          String setterName, VariableDeclaration value) =>
      ReturnStatement(_dartify(_setProperty(node, object, setterName, value)));

  ReturnStatement _getExternalExtensionSetterBody(Procedure node) {
    final parameters = node.function.positionalParameters;
    assert(parameters.length == 2);
    return _getExternalSetterBody(node, VariableGet(parameters.first),
        _getExtensionMemberName(node), parameters.last);
  }

  ReturnStatement _getExternalTopLevelSetterBody(
          Procedure node, Expression target) =>
      _getExternalSetterBody(node, target, node.name.text,
          node.function.positionalParameters.single);

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body is equivalent to:
  /// `js_util_wasm.callMethodVarArgs([object], [methodName], [values])`.
  ReturnStatement _getExternalMethodBody(Procedure node, Expression object,
      String methodName, List<VariableDeclaration> values) {
    final callMethodInvocation = _dartify(StaticInvocation(
        _callMethodTarget,
        Arguments([
          object,
          StringLiteral(methodName),
          ListLiteral(
              values.map((value) => _jsifyVariable(node, value)).toList(),
              typeArgument: _nullableJSValueType)
        ])))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(callMethodInvocation);
  }

  ReturnStatement _getExternalExtensionMethodBody(Procedure node) {
    final parameters = node.function.positionalParameters;
    assert(parameters.length > 0);
    return _getExternalMethodBody(node, VariableGet(parameters.first),
        _getExtensionMemberName(node), parameters.sublist(1));
  }

  ReturnStatement _getExternalTopLevelMethodBody(
          Procedure node, Expression target) =>
      _getExternalMethodBody(
          node, target, node.name.text, node.function.positionalParameters);

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
