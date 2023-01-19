// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_js_interop_checks/src/js_interop.dart'
    show
        calculateTransitiveImportsOfJsInteropIfUsed,
        getJSName,
        hasAnonymousAnnotation,
        hasStaticInteropAnnotation,
        hasJSInteropAnnotation;
import 'package:_js_interop_checks/src/transformations/static_interop_class_eraser.dart';
import 'package:dart2wasm/js_runtime_blob.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

enum _MethodType {
  jsObjectLiteralConstructor,
  constructor,
  getter,
  method,
  setter,
}

class _MethodLoweringConfig {
  final Procedure procedure;
  final _MethodType type;
  final String jsString;
  late final bool isConstructor =
      type == _MethodType.jsObjectLiteralConstructor ||
          type == _MethodType.constructor;
  late final bool firstParameterIsObject = procedure.isExtensionMember;
  late final List<VariableDeclaration> parameters =
      type == _MethodType.jsObjectLiteralConstructor
          ? function.namedParameters
          : function.positionalParameters;
  late String tag = procedure.name.text.replaceAll(RegExp(r'[^a-zA-Z_]'), '_');

  _MethodLoweringConfig(this.procedure, this.type, this.jsString);

  FunctionNode get function => procedure.function;
  Uri get fileUri => procedure.fileUri;

  String generateJS(List<String> parameters) {
    String callArguments;
    String functionParameters;
    String object;
    if (isConstructor) {
      object = '';
      callArguments = parameters.join(',');
      functionParameters = callArguments;
    } else if (firstParameterIsObject) {
      object = parameters[0];
      callArguments = parameters.sublist(1).join(',');
      functionParameters =
          '$object${callArguments.isEmpty ? '' : ',$callArguments'}';
    } else {
      object = 'globalThis';
      callArguments = parameters.join(',');
      functionParameters = callArguments;
    }
    String bodyString;
    switch (type) {
      case _MethodType.jsObjectLiteralConstructor:
        List<String> keys =
            function.namedParameters.map((named) => named.name!).toList();
        List<String> keyValuePairs = [];
        for (int i = 0; i < parameters.length; i++) {
          keyValuePairs.add('${keys[i]}: ${parameters[i]}');
        }
        bodyString = '{${keyValuePairs.join(',')}}';
        break;
      case _MethodType.constructor:
        bodyString = 'new $jsString($callArguments)';
        break;
      case _MethodType.getter:
        bodyString = '$object.$jsString';
        break;
      case _MethodType.method:
        bodyString = '$object.$jsString($callArguments)';
        break;
      case _MethodType.setter:
        bodyString = '$object.$jsString = $callArguments';
        break;
    }
    return """function($functionParameters) {
      return $bodyString;
    }""";
  }
}

/// Lowers static interop to JS, generating specialized JS methods as required.
/// TODO(joshualitt): Generate specialized JS callback trampolines.
class _JSLowerer extends Transformer {
  final Procedure _dartifyRawTarget;
  final Procedure _jsifyRawTarget;
  final Procedure _wrapDartFunctionTarget;
  final Procedure _allowInteropTarget;
  final Procedure _numToInt;
  final Class _wasmExternRefClass;
  final Class _pragmaClass;
  final Field _pragmaName;
  final Field _pragmaOptions;
  // TODO(joshualitt): Tree shake js methods by holding on to
  // _MethodLoweringConfigs until after we run the TFA, and then only generating
  // js methods for the dart stubs that remain.
  final List<String> jsMethods = [];
  int _jsTrampolineN = 1;
  late Library _library;
  late String _libraryJSString;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;
  Map<Reference, ExtensionMemberDescriptor>? _extensionMemberIndex;

  _JSLowerer(this._coreTypes, ClassHierarchy hierarchy)
      : _dartifyRawTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'dartifyRaw'),
        _jsifyRawTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', 'jsifyRaw'),
        _wrapDartFunctionTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_wrapDartFunction'),
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
    _libraryJSString = getJSName(_library);
    if (_libraryJSString.isNotEmpty) {
      _libraryJSString = '$_libraryJSString.';
    }
    _staticTypeContext.enterLibrary(lib);
    lib.transformChildren(this);
    _staticTypeContext.leaveLibrary(lib);
    _extensionMemberIndex = null;
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

  String _getJSString(Annotatable a, String initial) {
    String selectorString = getJSName(a);
    if (selectorString.isEmpty) {
      selectorString = initial;
    }
    return selectorString;
  }

  String _getTopLevelJSString(Annotatable a, String initial) =>
      '$_libraryJSString${_getJSString(a, initial)}';

  _MethodType _getTypeForNonExtensionMember(Procedure node) {
    if (node.isGetter) {
      return _MethodType.getter;
    } else if (node.isSetter) {
      return _MethodType.setter;
    } else {
      assert(node.kind == ProcedureKind.Method);
      return _MethodType.method;
    }
  }

  @override
  Procedure visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    Statement? transformedBody;
    if (node.isExternal) {
      _MethodType? type;
      String jsString = '';
      if (node.enclosingClass != null &&
          hasJSInteropAnnotation(node.enclosingClass!)) {
        Class cls = node.enclosingClass!;
        jsString = _getTopLevelJSString(cls, cls.name);
        if (node.isFactory) {
          if (hasAnonymousAnnotation(cls)) {
            type = _MethodType.jsObjectLiteralConstructor;
          } else {
            type = _MethodType.constructor;
          }
        } else {
          String memberSelectorString = _getJSString(node, node.name.text);
          jsString = '$jsString.$memberSelectorString';
          type = _getTypeForNonExtensionMember(node);
        }
      } else if (node.isExtensionMember) {
        var index = _extensionMemberIndex ??=
            _createExtensionMembersIndex(node.enclosingLibrary);
        var nodeDescriptor = index[node.reference];
        if (nodeDescriptor != null) {
          if (!nodeDescriptor.isStatic) {
            jsString = _getJSString(
                node, _extensionMemberIndex![node.reference]!.name.text);
            if (nodeDescriptor.kind == ExtensionMemberKind.Getter) {
              type = _MethodType.getter;
            } else if (nodeDescriptor.kind == ExtensionMemberKind.Setter) {
              type = _MethodType.setter;
            } else if (nodeDescriptor.kind == ExtensionMemberKind.Method) {
              type = _MethodType.method;
            }
          }
        }
      } else if (hasJSInteropAnnotation(node)) {
        jsString = _getTopLevelJSString(node, node.name.text);
        type = _getTypeForNonExtensionMember(node);
      }
      if (type != null) {
        transformedBody =
            _specializeJSMethod(_MethodLoweringConfig(node, type, jsString));
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

  DartType get _nullableObjectType =>
      _coreTypes.objectRawType(Nullability.nullable);

  DartType get _nonNullableObjectType =>
      _coreTypes.objectRawType(Nullability.nonNullable);

  DartType get _nullableWasmExternRefType =>
      _wasmExternRefClass.getThisType(_coreTypes, Nullability.nullable);

  Expression _variableCheckConstant(
          VariableDeclaration variable, Constant constant) =>
      StaticInvocation(_coreTypes.identicalProcedure,
          Arguments([VariableGet(variable), ConstantExpression(constant)]));

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
    final callbackVariable =
        VariableDeclaration('callback', type: _nonNullableObjectType);
    final lastDefinedArgument = VariableDeclaration('lastDefinedArgument',
        type: _coreTypes.doubleNonNullableRawType);

    // Initialize variable declarations.
    List<VariableDeclaration> positionalParameters = [];
    for (int j = 0; j < function.positionalParameters.length; j++) {
      positionalParameters
          .add(VariableDeclaration('x$j', type: _nullableObjectType));
    }

    Statement functionTrampolineBody = _createFunctionTrampolineBody(
        function, callbackVariable, lastDefinedArgument, positionalParameters);

    // Create a new procedure for the callback trampoline. This procedure will
    // be exported from Wasm to JS so it can be called from JS. The argument
    // returned from the supplied callback will be converted with `jsifyRaw` to
    // a native JS value before being returned to JS.
    final String libraryName = _library.name ?? 'Unnamed';
    final functionTrampolineName =
        '|_functionTrampoline${_jsTrampolineN++}For$libraryName';
    final functionTrampolineImportName = '\$$functionTrampolineName';
    final functionTrampoline = Procedure(
        Name(functionTrampolineName, _library),
        ProcedureKind.Method,
        FunctionNode(functionTrampolineBody,
            positionalParameters: [callbackVariable, lastDefinedArgument]
                .followedBy(positionalParameters)
                .toList(),
            returnType: _nullableWasmExternRefType)
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

  // Specializes a JS method for a given [_MethodLoweringConfig] and returns an
  // invocation of the specialized method.
  ReturnStatement _specializeJSMethod(_MethodLoweringConfig config) {
    // Initialize variable declarations.
    List<String> jsParameterStrings = [];
    List<VariableDeclaration> originalParameters = config.parameters;
    List<VariableDeclaration> dartPositionalParameters = [];
    for (int j = 0; j < originalParameters.length; j++) {
      String parameterString = 'x$j';
      dartPositionalParameters.add(VariableDeclaration(parameterString,
          type: _nullableWasmExternRefType));
      jsParameterStrings.add(parameterString);
    }

    // Create Dart procedure stub for JS method.
    final jsMethodName = '${config.tag}${_jsTrampolineN++}';
    final dartProcedureName = '|$jsMethodName';
    final dartProcedure = Procedure(
        Name(dartProcedureName, _library),
        ProcedureKind.Method,
        FunctionNode(null,
            positionalParameters: dartPositionalParameters,
            returnType: _nullableWasmExternRefType),
        isExternal: true,
        isStatic: true,
        fileUri: config.fileUri)
      ..isNonNullableByDefault = true;
    dartProcedure.addAnnotation(
        ConstantExpression(InstanceConstant(_pragmaClass.reference, [], {
      _pragmaName.fieldReference: StringConstant('wasm:import'),
      _pragmaOptions.fieldReference: StringConstant('dart2wasm.$jsMethodName')
    })));
    _library.addProcedure(dartProcedure);

    // Create JS method
    jsMethods.add("$jsMethodName: ${config.generateJS(jsParameterStrings)}");

    // Return the replacement body.
    // Because we simply don't have enough information, we leave all JS numbers
    // as doubles. However, in cases where we know the user expects an `int` we
    // insert a cast.
    DartType returnType = config.function.returnType;
    DartType returnTypeOverride = returnType == _coreTypes.intNullableRawType
        ? _coreTypes.doubleNullableRawType
        : returnType == _coreTypes.intNonNullableRawType
            ? _coreTypes.doubleNonNullableRawType
            : returnType;
    return ReturnStatement(AsExpression(
        _convertReturnType(
            returnType,
            returnTypeOverride,
            StaticInvocation(
                _dartifyRawTarget,
                Arguments([
                  StaticInvocation(
                      dartProcedure,
                      Arguments(originalParameters
                          .map<Expression>((value) => StaticInvocation(
                              _jsifyRawTarget, Arguments([VariableGet(value)])))
                          .toList()))
                ]))),
        returnType));
  }

  // Handles any necessary return type conversions. Today this is just for
  // handling the case where a user wants us to coerce a JS number to an int
  // instead of a double.
  Expression _convertReturnType(
      DartType returnType, DartType returnTypeOverride, Expression expression) {
    if (returnType == _coreTypes.intNullableRawType ||
        returnType == _coreTypes.intNonNullableRawType) {
      VariableDeclaration v = VariableDeclaration('#var',
          initializer: expression, type: returnTypeOverride);
      return Let(
          v,
          ConditionalExpression(
              _variableCheckConstant(v, NullConstant()),
              ConstantExpression(NullConstant()),
              InstanceInvocation(InstanceAccessKind.Instance, VariableGet(v),
                  _numToInt.name, Arguments([]),
                  interfaceTarget: _numToInt,
                  functionType: _numToInt.function
                      .computeFunctionType(Nullability.nonNullable)),
              returnType));
    } else {
      return expression;
    }
  }
}

String _performJSInteropTransformations(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy classHierarchy,
    Set<Library> interopDependentLibraries) {
  final jsLowerer = _JSLowerer(coreTypes, classHierarchy);
  for (Library library in interopDependentLibraries) {
    jsLowerer.visitLibrary(library);
  }

  // We want static types to help us specialize methods based on receivers.
  // Therefore, erasure must come after the lowering.
  final staticInteropClassEraser = StaticInteropClassEraser(coreTypes, null,
      libraryForJavaScriptObject: 'dart:_js_helper',
      classNameOfJavaScriptObject: 'JSValue');
  for (Library library in interopDependentLibraries) {
    staticInteropClassEraser.visitLibrary(library);
  }
  return jsLowerer.jsMethods.join(',\n');
}

// TODO(joshualitt): Breakup the runtime blob and tree shake unused JS from the
// runtime.
String generateJSRuntime(
    Component component, CoreTypes coreTypes, ClassHierarchy classHierarchy) {
  String? jsInteropMethods;
  Set<Library> transitiveImportingJSInterop = {
    ...?calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("package:js/js.dart")),
    ...?calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("dart:_js_annotations"))
  };
  if (transitiveImportingJSInterop.isNotEmpty) {
    jsInteropMethods = _performJSInteropTransformations(
        component, coreTypes, classHierarchy, transitiveImportingJSInterop);
  }

  return '''
$jsRuntimeBlobPart1
$jsInteropMethods
$jsRuntimeBlobPart2
''';
}
