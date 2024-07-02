// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        messageJsInteropIsATearoff,
        templateJsInteropExportClassNotMarkedExportable;
import 'package:_js_interop_checks/js_interop_checks.dart'
    show JsInteropDiagnosticReporter;
import 'package:_js_interop_checks/src/js_interop.dart' as js_interop;
import 'package:front_end/src/codes/cfe_codes.dart'
    show
        templateJsInteropExportInvalidInteropTypeArgument,
        templateJsInteropExportInvalidTypeArgument,
        templateJsInteropIsAInvalidType,
        templateJsInteropIsAObjectLiteralType,
        templateJsInteropIsAPrimitiveExtensionType;
import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/type_environment.dart';

import 'export_checker.dart';
import 'js_util_optimizer.dart';
import 'static_interop_mock_validator.dart';

class SharedInteropTransformer extends Transformer {
  final Procedure _callMethodVarArgs;
  final Procedure _createDartExport;
  final Procedure _createJSInteropWrapper;
  final Procedure _createStaticInteropMock;
  final JsInteropDiagnosticReporter _diagnosticReporter;
  final ExportChecker _exportChecker;
  final ExtensionIndex _extensionIndex;
  final Procedure _functionToJS;
  final Procedure _getProperty;
  final Procedure _globalContext;
  late bool _inIsATearoff;
  final Procedure _instanceof;
  final Procedure _instanceOfString;
  late StaticInvocation? _invocation;
  final Procedure _isA;
  final Procedure _isATearoff;
  final ExtensionTypeDeclaration _jsAny;
  final ExtensionTypeDeclaration _jsFunction;
  final ExtensionTypeDeclaration _jsObject;
  final Procedure _setProperty;
  final Procedure _stringToJS;
  final StaticInteropMockValidator _staticInteropMockValidator;
  final TypeEnvironment _typeEnvironment;
  final Procedure _typeofEquals;

  StaticInvocation get invocation => _invocation!;

  SharedInteropTransformer(this._typeEnvironment, this._diagnosticReporter,
      this._exportChecker, this._extensionIndex)
      : _callMethodVarArgs = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_interop_unsafe',
                'JSObjectUnsafeUtilExtension|callMethodVarArgs'),
        _createDartExport = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createDartExport'),
        _createJSInteropWrapper = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_interop', 'createJSInteropWrapper'),
        _createStaticInteropMock = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createStaticInteropMock'),
        _functionToJS = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        _getProperty = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop_unsafe', 'JSObjectUnsafeUtilExtension|[]'),
        _globalContext = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_interop', 'get:globalContext'),
        _instanceof = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'JSAnyUtilityExtension|instanceof'),
        _instanceOfString = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure(
                'dart:js_interop', 'JSAnyUtilityExtension|instanceOfString'),
        _isA = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'JSAnyUtilityExtension|isA'),
        _isATearoff = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop',
            'JSAnyUtilityExtension|${LibraryIndex.tearoffPrefix}isA'),
        _jsAny = _typeEnvironment.coreTypes.index
            .getExtensionType('dart:js_interop', 'JSAny'),
        _jsFunction = _typeEnvironment.coreTypes.index
            .getExtensionType('dart:js_interop', 'JSFunction'),
        _jsObject = _typeEnvironment.coreTypes.index
            .getExtensionType('dart:js_interop', 'JSObject'),
        _setProperty = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop_unsafe', 'JSObjectUnsafeUtilExtension|[]='),
        _stringToJS = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'StringToJSString|get#toJS'),
        _staticInteropMockValidator = StaticInteropMockValidator(
            _diagnosticReporter, _exportChecker, _typeEnvironment),
        _typeofEquals = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'JSAnyUtilityExtension|typeofEquals');

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    _invocation = node;
    TreeNode replacement = invocation;
    final target = invocation.target;
    if (target == _createDartExport || target == _createJSInteropWrapper) {
      final typeArguments = invocation.arguments.types;
      assert(typeArguments.length == 1);
      if (_verifyExportable(typeArguments[0])) {
        final interface = typeArguments[0] as InterfaceType;
        if (target == _createJSInteropWrapper) {
          replacement = _createExport(
              interface, ExtensionType(_jsObject, Nullability.nonNullable));
        }
        replacement = _createExport(interface);
      }
    } else if (target == _createStaticInteropMock) {
      final typeArguments = invocation.arguments.types;
      assert(typeArguments.length == 2);
      final staticInteropType = typeArguments[0];
      final dartType = typeArguments[1];

      final exportable = _verifyExportable(dartType);
      final staticInteropTypeArgumentCorrect = _staticInteropMockValidator
          .validateStaticInteropTypeArgument(invocation, staticInteropType);
      final dartTypeArgumentCorrect = _staticInteropMockValidator
          .validateDartTypeArgument(invocation, dartType);
      if (exportable &&
          staticInteropTypeArgumentCorrect &&
          dartTypeArgumentCorrect &&
          _staticInteropMockValidator.validateCreateStaticInteropMock(
              invocation,
              (staticInteropType as InterfaceType).classNode,
              (dartType as InterfaceType).classNode)) {
        final arguments = invocation.arguments.positional;
        assert(arguments.length == 1 || arguments.length == 2);
        final proto = arguments.length == 2 ? arguments[1] : null;

        replacement = _createExport(dartType, staticInteropType, proto);
      }
    } else if (target == _isA) {
      final receiver = invocation.arguments.positional[0];
      final typeArguments = invocation.arguments.types;
      assert(typeArguments.length == 1);
      final interopType = typeArguments[0];
      final coreInteropType =
          _extensionIndex.getCoreInteropType(interopType)?.node;
      if (coreInteropType is ExtensionTypeDeclaration &&
          _extensionIndex.isJSType(coreInteropType)) {
        replacement = _createIsACheck(
            receiver, interopType as ExtensionType, coreInteropType);
      } else {
        // Generated tear-offs call the original method, so ignore that
        // invocation.
        if (!_inIsATearoff) {
          _diagnosticReporter.report(
              templateJsInteropIsAInvalidType.withArguments(interopType),
              invocation.fileOffset,
              invocation.name.text.length,
              invocation.location?.file);
        }
        replacement = invocation;
      }
    } else if (target == _isATearoff) {
      // Calling the generated tear-off is still bad, however.
      _diagnosticReporter.report(
          messageJsInteropIsATearoff,
          invocation.fileOffset,
          invocation.name.text.length,
          invocation.location?.file);
    }
    replacement.transformChildren(this);
    _invocation = null;
    return replacement;
  }

  @override
  TreeNode visitProcedure(Procedure node) {
    _inIsATearoff = node == _isATearoff;
    node.transformChildren(this);
    _inIsATearoff = false;
    return node;
  }

  /// Validate that the [dartType] provided via `createDartExport` or
  /// `createJSInteropWrapper` can be exported safely.
  ///
  /// Checks that:
  /// - Type argument is a valid Dart interface type.
  /// - Type argument is not a JS interop type.
  /// - Type argument was not marked as non-exportable.
  ///
  /// If there were no errors with processing the class, returns true.
  /// Otherwise, returns false.
  bool _verifyExportable(DartType dartType) {
    if (dartType is! InterfaceType) {
      _diagnosticReporter.report(
          templateJsInteropExportInvalidTypeArgument.withArguments(dartType),
          invocation.fileOffset,
          invocation.name.text.length,
          invocation.location?.file);
      return false;
    }
    var dartClass = dartType.classNode;
    if (js_interop.hasJSInteropAnnotation(dartClass) ||
        js_interop.hasStaticInteropAnnotation(dartClass) ||
        js_interop.hasAnonymousAnnotation(dartClass)) {
      _diagnosticReporter.report(
          templateJsInteropExportInvalidInteropTypeArgument
              .withArguments(dartType),
          invocation.fileOffset,
          invocation.name.text.length,
          invocation.location?.file);
      return false;
    }
    if (!_exportChecker.exportStatus.containsKey(dartClass.reference)) {
      // This occurs when we deserialize previously compiled modules. Those
      // modules may contain export classes, so we need to revisit the classes
      // in those previously compiled modules if they are used.
      for (var member in dartClass.procedures) {
        _exportChecker.visitMember(member);
      }
      for (var member in dartClass.fields) {
        _exportChecker.visitMember(member);
      }
      _exportChecker.visitClass(dartClass);
    }
    var exportStatus = _exportChecker.exportStatus[dartClass.reference];
    if (exportStatus == ExportStatus.nonExportable) {
      _diagnosticReporter.report(
          templateJsInteropExportClassNotMarkedExportable
              .withArguments(dartClass.name),
          invocation.fileOffset,
          invocation.name.text.length,
          invocation.location?.file);
      return false;
    }
    return exportStatus == ExportStatus.exportable;
  }

  /// Create the object literal using the export map that was computed from the
  /// interface in [dartType].
  ///
  /// [dartType] is assumed to be a valid exportable class. [returnType] is the
  /// type that the object literal will be casted to. [proto] is an optional
  /// prototype object that users can pass to instantiate the object literal.
  ///
  /// The export map is already validated, so this method simply iterates over
  /// it and either assigns a method for a given property name, or assigns a
  /// getter and/or setter.
  ///
  /// Returns a call to the block of code that instantiates this object literal
  /// and returns it.
  TreeNode _createExport(InterfaceType dartType,
      [DartType? returnType, Expression? proto]) {
    var exportMap =
        _exportChecker.exportClassToMemberMap[dartType.classNode.reference]!;

    var block = <Statement>[];
    returnType ??= _typeEnvironment.coreTypes.objectNonNullableRawType;

    // TODO(srujzs): We can avoid creating a variable if the passed-in value is
    // already a variable for both these declarations.
    // TODO(srujzs): Change these to `VariableDeclaration.forValue` once
    // https://github.com/dart-lang/sdk/issues/54734 is resolved.
    var dartInstance = VariableDeclaration('#dartInstance',
        initializer: invocation.arguments.positional[0],
        type: dartType,
        isSynthesized: true)
      ..fileOffset = invocation.fileOffset;
    block.add(dartInstance);

    var jsExporter = VariableDeclaration('#jsExporter',
        initializer: getLiteral(proto),
        type: ExtensionType(_jsObject, Nullability.nonNullable),
        isSynthesized: true)
      ..fileOffset = invocation.fileOffset;
    block.add(jsExporter);

    for (var MapEntry(key: exportName, value: exports) in exportMap.entries) {
      ExpressionStatement setProperty(
          VariableGet jsObject, String propertyName, StaticInvocation jsValue) {
        // `jsObject[propertyName] = jsValue`
        return ExpressionStatement(StaticInvocation(_setProperty,
            Arguments([jsObject, StringLiteral(propertyName), jsValue])))
          ..fileOffset = invocation.fileOffset;
      }

      var firstExport = exports.first;
      // With methods, there's only one export per export name.
      if (firstExport is Procedure &&
          firstExport.kind == ProcedureKind.Method) {
        // `jsExport[jsName] = dartMock.tearoffMethod.toJS`
        block.add(setProperty(
            VariableGet(jsExporter),
            exportName,
            StaticInvocation(
                _functionToJS,
                Arguments([
                  InstanceTearOff(InstanceAccessKind.Instance,
                      VariableGet(dartInstance), firstExport.name,
                      interfaceTarget: firstExport,
                      resultType: _staticInteropMockValidator
                          .typeParameterResolver
                          .resolve(firstExport.getterType))
                ]))));
      } else {
        // Create the mapping from `get` and `set` to their `dartInstance` calls
        // to be used in `Object.defineProperty`.

        // Add the given exports to the mapping that corresponds to the given
        // exportName that is used by `Object.defineProperty`. In order to
        // conform to that API, this function defines 'get' or 'set' properties
        // on a given object literal.
        // The AST code looks like:
        //
        // ```
        // getSetMap['get'] = () {
        //   return dartInstance.getter;
        // }.toJS;
        // ```
        //
        // in the case of a getter and:
        //
        // ```
        // getSetMap['set'] = (val) {
        //  dartInstance.setter = val;
        // }.toJS;
        // ```
        //
        // in the case of a setter.
        //
        // A new map VariableDeclaration is created and added to the block of
        // statements for each export name.
        var getSetMap = VariableDeclaration('#${exportName}Mapping',
            initializer: getLiteral(),
            type: ExtensionType(_jsObject, Nullability.nonNullable),
            isSynthesized: true)
          ..fileOffset = invocation.fileOffset;
        block.add(getSetMap);
        var (:getter, :setter) = _exportChecker.getGetterSetter(exports);
        if (getter != null) {
          final resultType = _staticInteropMockValidator.typeParameterResolver
              .resolve(getter.getterType);
          block.add(setProperty(
              VariableGet(getSetMap),
              'get',
              StaticInvocation(
                  _functionToJS,
                  Arguments([
                    FunctionExpression(FunctionNode(
                        ReturnStatement(InstanceGet(InstanceAccessKind.Instance,
                            VariableGet(dartInstance), getter.name,
                            interfaceTarget: getter, resultType: resultType)),
                        returnType: resultType))
                  ]))));
        }
        if (setter != null) {
          var setterParameter = VariableDeclaration('#val',
              type: _staticInteropMockValidator.typeParameterResolver
                  .resolve(setter.setterType),
              isSynthesized: true)
            ..fileOffset = invocation.fileOffset;
          block.add(setProperty(
              VariableGet(getSetMap),
              'set',
              StaticInvocation(
                  _functionToJS,
                  Arguments([
                    FunctionExpression(FunctionNode(
                        ExpressionStatement(InstanceSet(
                            InstanceAccessKind.Instance,
                            VariableGet(dartInstance),
                            setter.name,
                            VariableGet(setterParameter),
                            interfaceTarget: setter)),
                        positionalParameters: [setterParameter],
                        returnType: const VoidType()))
                  ]))));
        }
        // Call `Object.defineProperty` to define the export name with the
        // 'get' and/or 'set' mapping. This allows us to treat get/set
        // semantics as methods.
        block.add(ExpressionStatement(callMethodVarArgs(
            getObjectProperty(),
            'defineProperty',
            [
              VariableGet(jsExporter),
              toJSString(exportName),
              VariableGet(getSetMap)
            ],
            VoidType()))
          ..fileOffset = invocation.fileOffset);
      }
    }

    block.add(ReturnStatement(AsExpression(VariableGet(jsExporter), returnType)
      ..fileOffset = invocation.fileOffset));
    // Return a call to evaluate the entire block of code and return the JS mock
    // that was created.
    return FunctionInvocation(
        FunctionAccessKind.Function,
        FunctionExpression(FunctionNode(Block(block), returnType: returnType)),
        Arguments([]),
        functionType: FunctionType([], returnType, Nullability.nonNullable))
      ..fileOffset = invocation.fileOffset
      ..parent = invocation.parent;
  }

  /// Create and return an appropriate type-check for the given [receiver] and
  /// [interopType].
  ///
  /// [jsType] is the JS type that [interopType] is or wraps.
  ///
  /// If [interopType] is an erroneous type like a type that wraps a JS
  /// primitive type or one with an object literal constructor, an error is
  /// reported.
  TreeNode _createIsACheck(Expression receiver, ExtensionType interopType,
      ExtensionTypeDeclaration jsType) {
    // In the case where the receiver wasn't a variable to begin with,
    // synthesize a var so that we don't evaluate the receiver multiple times.
    final any = receiver is VariableGet
        ? receiver.variable
        : (VariableDeclaration.forValue(receiver,
            type: ExtensionType(_jsAny, Nullability.nullable))
          ..fileOffset = invocation.fileOffset);

    Expression? check;
    final interopTypeDecl = interopType.extensionTypeDeclaration;
    final jsTypeName = jsType.name;
    String? typeofString;
    String? instanceOfString;
    switch (jsTypeName) {
      case 'JSAny' when interopTypeDecl == jsType:
        // Only avoids any non null-related checks when users are referring
        // directly to the `dart:js_interop` type and not some wrapper.
        break;
      case 'JSNumber':
        typeofString = 'number';
        break;
      case 'JSBoolean':
        typeofString = 'boolean';
        break;
      case 'JSString':
        typeofString = 'string';
        break;
      case 'JSBigInt':
        typeofString = 'bigint';
        break;
      case 'JSSymbol':
        typeofString = 'symbol';
        break;
      case 'JSTypedArray' when interopTypeDecl == jsType:
        // Only do this special case when users are referring directly to
        // the `dart:js_interop` type and not some wrapper.

        // `TypedArray` doesn't exist as a property in JS, but rather as a
        // superclass of all typed arrays. In order to do the most sensible
        // thing here, we can use the prototype of some typed array, and
        // check that the receiver is an `instanceof` that prototype.
        // See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray#description
        // for more details.
        check = StaticInvocation(_instanceof,
            Arguments([VariableGet(any), getInt8ArrayPrototype()]));
        break;
      default:
        for (final descriptor in interopTypeDecl.memberDescriptors) {
          final descriptorNode = descriptor.memberReference.node;
          if (descriptorNode is Procedure &&
              _extensionIndex.isLiteralConstructor(descriptorNode)) {
            _diagnosticReporter.report(
                templateJsInteropIsAObjectLiteralType
                    .withArguments(interopType),
                invocation.fileOffset,
                invocation.name.text.length,
                invocation.location?.file);
            break;
          }
        }
        // Currently, any type that is not recursively a JS primitive type or
        // `JSTypedArray` will use the written type (with renames) to do a
        // type check. This means using any extension type that wraps
        // `JSArray` in `isA` will use the extension type's name instead of
        // `Array`. This may lead to confusion when a user writes an
        // extension type that wraps `JSArray` but did not intend to give it
        // a separate JS type. We could change this, but that means users
        // can't use any actual subtypes of `JSArray`. Users who want to do
        // a check against `Array` can always use `isA<JSArray>()` or use
        // `@JS('Array')` (with no library scoping) to provide the right
        // type.
        var typeName = js_interop.getJSName(interopTypeDecl);
        if (typeName.isEmpty) typeName = interopTypeDecl.name;
        instanceOfString = JsUtilOptimizer.concatenateJSNames(
            js_interop.getJSName(interopTypeDecl.enclosingLibrary), typeName);
    }
    if (typeofString != null) {
      if (interopTypeDecl != jsType) {
        _diagnosticReporter.report(
            templateJsInteropIsAPrimitiveExtensionType.withArguments(
                interopType, jsTypeName),
            invocation.fileOffset,
            invocation.name.text.length,
            invocation.location?.file);
      } else {
        check = StaticInvocation(_typeofEquals,
            Arguments([VariableGet(any), StringLiteral(typeofString)]));
      }
    } else if (instanceOfString != null) {
      check = StaticInvocation(_instanceOfString,
          Arguments([VariableGet(any), StringLiteral(instanceOfString)]));
    }
    final nullable = interopType.nullability == Nullability.nullable;
    Expression nullCheck = EqualsNull(VariableGet(any));
    Expression notNullCheck = Not(EqualsNull(VariableGet(any)));
    if (check != null) {
      check = nullable
          ? LogicalExpression(nullCheck, LogicalExpressionOperator.OR, check)
          : LogicalExpression(
              notNullCheck, LogicalExpressionOperator.AND, check);
    } else if (!nullable) {
      // `JSAny`
      check = notNullCheck;
    } else {
      // `JSAny?`
      check = BoolLiteral(true);
    }
    return receiver is VariableGet ? check : Let(any, check)
      ..fileOffset = invocation.fileOffset
      ..parent = invocation.parent;
  }

  // Various shared helpers to make calls to `dart:js_interop`/
  // `dart:js_interop_unsafe` members easier. These helpers need to access the
  // current node's file offset so that the CFE verifier is happy.

  Expression asJSObject(Expression object,
          [bool nullable = false]) =>
      AsExpression(
          object,
          ExtensionType(_jsObject,
              nullable ? Nullability.nullable : Nullability.nonNullable))
        ..fileOffset = invocation.fileOffset;

  Expression toJSString(String string) =>
      StaticInvocation(_stringToJS, Arguments([StringLiteral(string)]))
        ..fileOffset = invocation.fileOffset;

  StaticInvocation callMethodVarArgs(Expression jsObject, String methodName,
      List<Expression> args, DartType returnType) {
    // `jsObject.callMethodVarArgs(methodName.toJS, args)`
    return StaticInvocation(
        _callMethodVarArgs,
        Arguments([
          jsObject,
          toJSString(methodName),
          ListLiteral(args,
              typeArgument: ExtensionType(_jsAny, Nullability.nullable))
        ], types: [
          returnType
        ]))
      ..fileOffset = invocation.fileOffset;
  }

  // Get the object with the given [property] off of the global context.
  Expression getGlobalProperty(String property) => asJSObject(StaticInvocation(
      _getProperty,
      Arguments([StaticGet(_globalContext), StringLiteral(property)])))
    ..fileOffset = invocation.fileOffset;

  Expression getObjectProperty() => getGlobalProperty('Object');

  Expression getInt8ArrayPrototype() => callMethodVarArgs(
      getObjectProperty(),
      'getPrototypeOf',
      [getGlobalProperty('Int8Array')],
      ExtensionType(_jsFunction, Nullability.nonNullable));

  // Get a fresh object literal, using the proto to create it if one was
  // given.
  StaticInvocation getLiteral([Expression? proto]) => callMethodVarArgs(
      getObjectProperty(),
      'create',
      [asJSObject(proto ?? NullLiteral(), true)],
      ExtensionType(_jsObject, Nullability.nonNullable));
}
