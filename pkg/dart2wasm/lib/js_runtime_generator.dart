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

enum _AnnotationType { import, export }

enum _MethodType {
  jsObjectLiteralConstructor,
  constructor,
  getter,
  method,
  setter,
}

bool parametersNeedParens(List<String> parameters) =>
    parameters.isEmpty || parameters.length > 1;

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
        bodyString = '({${keyValuePairs.join(',')}})';
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
    if (parametersNeedParens(parameters)) {
      return '($functionParameters) => $bodyString';
    } else {
      return '$functionParameters => $bodyString';
    }
  }
}

/// Lowers static interop to JS, generating specialized JS methods as required.
/// We lower methods to JS, but wait to emit the runtime until after we complete
/// translation. Ideally, we'd do everything after translation, but
/// unfortunately the TFA assumes classes with external factory constructors
/// that aren't mark with `entry-point` are abstract, and their methods thus get
/// replaced with `throw`s. Since we have to lower factory methods anyways, we
/// go ahead and lower everything, let the TFA tree shake, and then emit JS only
/// for the remaining nodes. We can revisit this if it becomes a performance
/// issue.
class _JSLowerer extends Transformer {
  final Procedure _dartifyRawTarget;
  final Procedure _jsifyRawTarget;
  final Procedure _isDartFunctionWrappedTarget;
  final Procedure _wrapDartFunctionTarget;
  final Procedure _allowInteropTarget;
  final Procedure _inlineJSTarget;
  final Procedure _numToInt;
  final Class _wasmExternRefClass;
  final Class _pragmaClass;
  final Field _pragmaName;
  final Field _pragmaOptions;
  bool _replaceProcedureWithInlineJS = false;
  late String _inlineJSImportName;
  final Map<Procedure, String> jsMethods = {};
  int _methodN = 1;
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
        _isDartFunctionWrappedTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_isDartFunctionWrapped'),
        _wrapDartFunctionTarget = _coreTypes.index
            .getTopLevelProcedure('dart:_js_helper', '_wrapDartFunction'),
        _allowInteropTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js', 'allowInterop'),
        _inlineJSTarget =
            _coreTypes.index.getTopLevelProcedure('dart:_js_helper', 'JS'),
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
  Expression visitStaticInvocation(StaticInvocation node) {
    node = super.visitStaticInvocation(node) as StaticInvocation;
    if (node.target == _allowInteropTarget) {
      Expression argument = node.arguments.positional.single;
      DartType functionType = argument.getStaticType(_staticTypeContext);
      return _allowInterop(node.target, functionType as FunctionType, argument);
    } else if (node.target == _inlineJSTarget) {
      return _expandInlineJS(node.target, node);
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
      // Under very restricted circumstances, we will make a procedure external
      // and clear it's body. See the description on [_expandInlineJS] for more
      // details.
      _replaceProcedureWithInlineJS = false;
      node.transformChildren(this);
      if (_replaceProcedureWithInlineJS) {
        node.isStatic = true;
        node.isExternal = true;
        node.function.body = null;
        _annotateProcedure(node, _inlineJSImportName, _AnnotationType.import);
        _replaceProcedureWithInlineJS = false;
      }
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

  // We could generate something more human readable, but for now we just
  // generate something short and unique.
  String generateMethodName() => '_${_methodN++}';

  DartType get _nonNullableObjectType =>
      _coreTypes.objectRawType(Nullability.nonNullable);

  DartType get _nullableWasmExternRefType =>
      _wasmExternRefClass.getThisType(_coreTypes, Nullability.nullable);

  DartType get _nonNullableWasmExternRefType =>
      _wasmExternRefClass.getThisType(_coreTypes, Nullability.nonNullable);

  Expression _variableCheckConstant(
          VariableDeclaration variable, Constant constant) =>
      StaticInvocation(_coreTypes.identicalProcedure,
          Arguments([VariableGet(variable), ConstantExpression(constant)]));

  void _annotateProcedure(
      Procedure procedure, String pragmaOptionString, _AnnotationType type) {
    String pragmaName;
    switch (type) {
      case _AnnotationType.import:
        pragmaName = 'import';
        break;
      case _AnnotationType.export:
        pragmaName = 'export';
        break;
    }
    procedure.addAnnotation(
        ConstantExpression(InstanceConstant(_pragmaClass.reference, [], {
      _pragmaName.fieldReference: StringConstant('wasm:$pragmaName'),
      _pragmaOptions.fieldReference: StringConstant('$pragmaOptionString')
    })));
  }

  Procedure _addInteropProcedure(String name, String pragmaOptionString,
      FunctionNode function, Uri fileUri, _AnnotationType type,
      {required bool isExternal}) {
    final procedure = Procedure(
        Name(name, _library), ProcedureKind.Method, function,
        isStatic: true, isExternal: isExternal, fileUri: fileUri)
      ..isNonNullableByDefault = true;
    _annotateProcedure(procedure, pragmaOptionString, type);
    _library.addProcedure(procedure);
    return procedure;
  }

  Statement _generateDispatchCase(
      FunctionType function,
      VariableDeclaration callbackVariable,
      List<VariableDeclaration> positionalParameters,
      int requiredParameterCount) {
    List<Expression> callbackArguments = [];
    for (int i = 0; i < requiredParameterCount; i++) {
      callbackArguments.add(AsExpression(
          StaticInvocation(_dartifyRawTarget,
              Arguments([VariableGet(positionalParameters[i])])),
          function.positionalParameters[i]));
    }
    return ReturnStatement(StaticInvocation(
        _jsifyRawTarget,
        Arguments([
          FunctionInvocation(
              FunctionAccessKind.FunctionType,
              AsExpression(VariableGet(callbackVariable), function),
              Arguments(callbackArguments),
              functionType: function),
        ])));
  }

  bool _needsArgumentsLength(FunctionType type) =>
      type.requiredParameterCount < type.positionalParameters.length;

  /// Creates a callback trampoline for the given [function]. This callback
  /// trampoline expects a Dart callback as its first argument, then an integer
  /// value(double type) indicating the position of the last defined
  /// argument(only for callbacks that take optional parameters), followed by
  /// all of the arguments to the Dart callback as JS objects.  The trampoline
  /// will `dartifyRaw` all incoming JS objects and then cast them to their
  /// approriate types, dispatch, and then `jsifyRaw` any returned value.
  /// [_createFunctionTrampoline] Returns a [String] function name representing
  /// the name of the wrapping function.
  String _createFunctionTrampoline(Procedure node, FunctionType function) {
    // Create arguments for each positional parameter in the function. These
    // arguments will be JS objects. The generated wrapper will cast each
    // argument to the correct type.  The first argument to this function will
    // be the Dart callback, which will be cast to the supplied [FunctionType]
    // before being invoked. If the callback takes optional parameters then, the
    // second argument will be a `double` indicating the last defined argument.
    int parameterId = 1;
    final callbackVariable =
        VariableDeclaration('callback', type: _nonNullableObjectType);
    VariableDeclaration? argumentsLength;
    if (_needsArgumentsLength(function)) {
      argumentsLength = VariableDeclaration('argumentsLength',
          type: _coreTypes.doubleNonNullableRawType);
    }

    // Initialize variable declarations.
    List<VariableDeclaration> positionalParameters = [];
    for (int j = 0; j < function.positionalParameters.length; j++) {
      positionalParameters.add(VariableDeclaration('x${parameterId++}',
          type: _nullableWasmExternRefType));
    }

    // Build the body of a function trampoline. To support default arguments, we
    // find the last defined argument in JS, that is the last argument which was
    // explicitly passed by the user, and then we dispatch to a Dart function
    // with the right number of arguments.
    //
    // First we handle cases where some or all arguments are undefined.
    // TODO(joshualitt): Consider using a switch instead.
    List<Statement> dispatchCases = [];
    for (int i = function.requiredParameterCount + 1;
        i <= function.positionalParameters.length;
        i++) {
      dispatchCases.add(IfStatement(
          _variableCheckConstant(
              argumentsLength!, DoubleConstant(i.toDouble())),
          _generateDispatchCase(
              function, callbackVariable, positionalParameters, i),
          null));
    }

    // Finally handle the case where only required parameters are passed.
    dispatchCases.add(_generateDispatchCase(function, callbackVariable,
        positionalParameters, function.requiredParameterCount));
    Statement functionTrampolineBody = Block(dispatchCases);

    // Create a new procedure for the callback trampoline. This procedure will
    // be exported from Wasm to JS so it can be called from JS. The argument
    // returned from the supplied callback will be converted with `jsifyRaw` to
    // a native JS value before being returned to JS.
    final functionTrampolineName = generateMethodName();
    _addInteropProcedure(
        functionTrampolineName,
        functionTrampolineName,
        FunctionNode(functionTrampolineBody,
            positionalParameters: [
              callbackVariable,
              if (argumentsLength != null) argumentsLength
            ].followedBy(positionalParameters).toList(),
            returnType: _nullableWasmExternRefType)
          ..fileOffset = node.fileOffset,
        node.fileUri,
        _AnnotationType.export,
        isExternal: false);
    return functionTrampolineName;
  }

  /// Returns a JS method that wraps a Dart callback in a JS wrapper.
  Procedure _getJSWrapperFunction(
      FunctionType type, String functionTrampolineName, Uri fileUri) {
    List<String> jsParameters = [];
    for (int i = 0; i < type.positionalParameters.length; i++) {
      jsParameters.add('x$i');
    }
    String jsParametersString = jsParameters.join(',');
    String dartArguments = 'f';
    bool needsArguments = _needsArgumentsLength(type);
    if (needsArguments) {
      dartArguments = '$dartArguments,arguments.length';
    }
    if (jsParameters.isNotEmpty) {
      dartArguments = '$dartArguments,$jsParametersString';
    }

    // Create Dart procedure stub.
    final jsMethodName = functionTrampolineName;
    Procedure dartProcedure = _addInteropProcedure(
        '|$jsMethodName',
        'dart2wasm.$jsMethodName',
        FunctionNode(null,
            positionalParameters: [
              VariableDeclaration('dartFunction',
                  type: _nonNullableWasmExternRefType)
            ],
            returnType: _nonNullableWasmExternRefType),
        fileUri,
        _AnnotationType.import,
        isExternal: true);

    // Create JS method.
    // Note: We have to use a regular function for the inner closure in some
    // cases because we need access to `arguments`.
    if (needsArguments) {
      jsMethods[dartProcedure] = "$jsMethodName: f => "
          "finalizeWrapper(f, function($jsParametersString) {"
          " return dartInstance.exports.$functionTrampolineName($dartArguments) "
          "})";
    } else {
      if (parametersNeedParens(jsParameters)) {
        jsParametersString = '($jsParametersString)';
      }
      jsMethods[dartProcedure] = "$jsMethodName: f => "
          "finalizeWrapper(f,$jsParametersString => "
          "dartInstance.exports.$functionTrampolineName($dartArguments))";
    }

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
  Expression _allowInterop(
      Procedure node, FunctionType type, Expression argument) {
    String functionTrampolineName = _createFunctionTrampoline(node, type);
    Procedure jsWrapperFunction =
        _getJSWrapperFunction(type, functionTrampolineName, node.fileUri);
    VariableDeclaration v =
        VariableDeclaration('#var', initializer: argument, type: type);
    return Let(
        v,
        ConditionalExpression(
            StaticInvocation(_isDartFunctionWrappedTarget,
                Arguments([VariableGet(v)], types: [type])),
            VariableGet(v),
            StaticInvocation(
                _wrapDartFunctionTarget,
                Arguments([
                  VariableGet(v),
                  StaticInvocation(
                      jsWrapperFunction, Arguments([VariableGet(v)])),
                ], types: [
                  type
                ])),
            type));
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
    String jsMethodName = generateMethodName();
    final dartProcedure = _addInteropProcedure(
        '|$jsMethodName',
        'dart2wasm.$jsMethodName',
        FunctionNode(null,
            positionalParameters: dartPositionalParameters,
            returnType: _nullableWasmExternRefType),
        config.fileUri,
        _AnnotationType.import,
        isExternal: true);

    // Create JS method
    jsMethods[dartProcedure] =
        "$jsMethodName: ${config.generateJS(jsParameterStrings)}";

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

  Procedure _getEnclosingProcedure(TreeNode node) {
    while (node is! Procedure) {
      node = node.parent!;
    }
    return node;
  }

  /// We will replace the enclosing procedure if:
  ///   1) The enclosing procedure is static.
  ///   2) The enclosing procedure has a body with a single statement, and that
  ///      statement is just a [StaticInvocation] of the inline JS helper.
  ///   3) All of the arguments to `inlineJS` are [VariableGet]s. (this is
  ///      checked by [_expandInlineJS]).
  bool _shouldReplaceEnclosingProcedure(StaticInvocation node) {
    Procedure enclosingProcedure = _getEnclosingProcedure(node);
    Statement enclosingBody = enclosingProcedure.function.body!;
    Expression? expression;
    if (enclosingBody is ReturnStatement) {
      expression = enclosingBody.expression;
    } else if (enclosingBody is Block && enclosingBody.statements.length == 1) {
      Statement statement = enclosingBody.statements.single;
      if (statement is ExpressionStatement) {
        expression = statement.expression;
      } else if (statement is ReturnStatement) {
        expression = statement.expression;
      }
    }
    return expression == node;
  }

  /// Calls to the `JS` helper are replaced in one of two ways:
  ///   1) By a static invocation to an external stub method that imports
  ///      the JS function.
  ///   2) Under restricted circumstances the entire enclosing procedure will be
  ///      replaced by an external stub method that imports the JS function. See
  ///      [_shouldReplaceEnclosingProcedure] for more details.
  Expression _expandInlineJS(Procedure inlineJSNode, StaticInvocation node) {
    Arguments arguments = node.arguments;
    List<Expression> originalArguments = arguments.positional.sublist(1);
    List<VariableDeclaration> dartPositionalParameters = [];
    bool allArgumentsAreGet = true;
    for (int j = 0; j < originalArguments.length; j++) {
      Expression originalArgument = originalArguments[j];
      String parameterString = 'x$j';
      DartType type = originalArgument.getStaticType(_staticTypeContext);
      dartPositionalParameters
          .add(VariableDeclaration(parameterString, type: type));
      if (originalArgument is! VariableGet) {
        allArgumentsAreGet = false;
      }
    }

    assert(arguments.positional[0] is StringLiteral,
        "Code template must be a StringLiteral");
    String codeTemplate = (arguments.positional[0] as StringLiteral).value;
    String jsMethodName = generateMethodName();
    _inlineJSImportName = 'dart2wasm.$jsMethodName';
    _replaceProcedureWithInlineJS =
        allArgumentsAreGet && _shouldReplaceEnclosingProcedure(node);
    Procedure dartProcedure;
    Expression result;
    if (_replaceProcedureWithInlineJS) {
      dartProcedure = _getEnclosingProcedure(node);
      result = InvalidExpression("Unreachable");
    } else {
      dartProcedure = _addInteropProcedure(
          '|$jsMethodName',
          _inlineJSImportName,
          FunctionNode(null,
              positionalParameters: dartPositionalParameters,
              returnType: arguments.types.single),
          inlineJSNode.fileUri,
          _AnnotationType.import,
          isExternal: true);
      result = StaticInvocation(dartProcedure, Arguments(originalArguments));
    }
    jsMethods[dartProcedure] = "$jsMethodName: $codeTemplate";
    return result;
  }
}

Map<Procedure, String> _performJSInteropTransformations(
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
  return jsLowerer.jsMethods;
}

class JSRuntimeFinalizer {
  final Map<Procedure, String> allJSMethods;

  JSRuntimeFinalizer(this.allJSMethods);

  String generate(Iterable<Procedure> translatedProcedures) {
    Set<Procedure> usedProcedures = {};
    List<String> usedJSMethods = [];
    for (Procedure p in translatedProcedures) {
      if (usedProcedures.add(p) && allJSMethods.containsKey(p)) {
        usedJSMethods.add(allJSMethods[p]!);
      }
    }
    return '''
  $jsRuntimeBlobPart1
  ${usedJSMethods.join(',\n')}
  $jsRuntimeBlobPart2
''';
  }
}

JSRuntimeFinalizer createJSRuntimeFinalizer(
    Component component, CoreTypes coreTypes, ClassHierarchy classHierarchy) {
  Set<Library> transitiveImportingJSInterop = {
    ...?calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("package:js/js.dart")),
    ...?calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("dart:_js_annotations")),
    ...?calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("dart:_js_helper")),
  };
  Map<Procedure, String> jsInteropMethods = {};
  jsInteropMethods = _performJSInteropTransformations(
      component, coreTypes, classHierarchy, transitiveImportingJSInterop);
  return JSRuntimeFinalizer(jsInteropMethods);
}
