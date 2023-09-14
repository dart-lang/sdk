// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show templateJsInteropExportClassNotMarkedExportable;
import 'package:_js_interop_checks/js_interop_checks.dart'
    show JsInteropDiagnosticReporter;
import 'package:_js_interop_checks/src/js_interop.dart' as js_interop;
import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        templateJsInteropExportInvalidInteropTypeArgument,
        templateJsInteropExportInvalidTypeArgument;
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'export_checker.dart';
import 'static_interop_mock_validator.dart';

class ExportCreator extends Transformer {
  final Procedure _callMethodVarArgs;
  final Procedure _createDartExport;
  final Procedure _createStaticInteropMock;
  final JsInteropDiagnosticReporter _diagnosticReporter;
  final ExportChecker _exportChecker;
  final Procedure _functionToJS;
  final Procedure _getProperty;
  final Procedure _globalContext;
  final Class _jsAny;
  final Class _jsObject;
  final Procedure _setProperty;
  final Procedure _stringToJS;
  final StaticInteropMockValidator _staticInteropMockValidator;
  final TypeEnvironment _typeEnvironment;

  ExportCreator(
      this._typeEnvironment, this._diagnosticReporter, this._exportChecker)
      : _callMethodVarArgs = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_interop_unsafe',
                'JSObjectUtilExtension|callMethodVarArgs'),
        _createDartExport = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createDartExport'),
        _createStaticInteropMock = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createStaticInteropMock'),
        _functionToJS = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'FunctionToJSExportedDartFunction|get#toJS'),
        _getProperty = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop_unsafe', 'JSObjectUtilExtension|[]'),
        _globalContext = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_interop', 'get:globalContext'),
        _jsAny = _typeEnvironment.coreTypes.index
            .getClass('dart:_js_types', 'JSAny'),
        _jsObject = _typeEnvironment.coreTypes.index
            .getClass('dart:_js_types', 'JSObject'),
        _setProperty = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop_unsafe', 'JSObjectUtilExtension|[]='),
        _stringToJS = _typeEnvironment.coreTypes.index.getTopLevelProcedure(
            'dart:js_interop', 'StringToJSString|get#toJS'),
        _staticInteropMockValidator = StaticInteropMockValidator(
            _diagnosticReporter, _exportChecker, _typeEnvironment);

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    if (node.target == _createDartExport) {
      final typeArguments = node.arguments.types;
      assert(typeArguments.length == 1);
      if (_verifyExportable(node, typeArguments[0])) {
        return _createExport(node, typeArguments[0] as InterfaceType);
      }
    } else if (node.target == _createStaticInteropMock) {
      final typeArguments = node.arguments.types;
      assert(typeArguments.length == 2);
      final staticInteropType = typeArguments[0];
      final dartType = typeArguments[1];

      final exportable = _verifyExportable(node, dartType);
      final staticInteropTypeArgumentCorrect = _staticInteropMockValidator
          .validateStaticInteropTypeArgument(node, staticInteropType);
      final dartTypeArgumentCorrect =
          _staticInteropMockValidator.validateDartTypeArgument(node, dartType);
      if (exportable &&
          staticInteropTypeArgumentCorrect &&
          dartTypeArgumentCorrect &&
          _staticInteropMockValidator.validateCreateStaticInteropMock(
              node,
              (staticInteropType as InterfaceType).classNode,
              (dartType as InterfaceType).classNode)) {
        final arguments = node.arguments.positional;
        assert(arguments.length == 1 || arguments.length == 2);
        final proto = arguments.length == 2 ? arguments[1] : null;

        return _createExport(node, dartType, staticInteropType, proto);
      }
    }
    node.transformChildren(this);
    return node;
  }

  /// Validate that the [dartType] provided via `createDartExport` can be
  /// exported safely.
  ///
  /// Checks that:
  /// - Type argument is a valid Dart interface type.
  /// - Type argument is not a JS interop type.
  /// - Type argument was not marked as non-exportable.
  ///
  /// If there were no errors with processing the class, returns true.
  /// Otherwise, returns false.
  bool _verifyExportable(StaticInvocation node, DartType dartType) {
    if (dartType is! InterfaceType) {
      _diagnosticReporter.report(
          templateJsInteropExportInvalidTypeArgument.withArguments(
              dartType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      return false;
    }
    var dartClass = dartType.classNode;
    if (js_interop.hasJSInteropAnnotation(dartClass) ||
        js_interop.hasStaticInteropAnnotation(dartClass) ||
        js_interop.hasAnonymousAnnotation(dartClass)) {
      _diagnosticReporter.report(
          templateJsInteropExportInvalidInteropTypeArgument.withArguments(
              dartType, true),
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
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
          node.fileOffset,
          node.name.text.length,
          node.location?.file);
      return false;
    }
    return exportStatus == ExportStatus.exportable;
  }

  /// Create the object literal using the export map that was computed from the
  /// interface in [dartType].
  ///
  /// [node] is either a call to `createStaticInteropMock` or
  /// `createDartExport`. [dartType] is assumed to be a valid exportable class.
  /// [returnType] is the type that the object literal will be casted to.
  /// [proto] is an optional prototype object that users can pass to instantiate
  /// the object literal.
  ///
  /// The export map is already validated, so this method simply iterates over
  /// it and either assigns a method for a given property name, or assigns a
  /// getter and/or setter.
  ///
  /// Returns a call to the block of code that instantiates this object literal
  /// and returns it.
  TreeNode _createExport(StaticInvocation node, InterfaceType dartType,
      [DartType? returnType, Expression? proto]) {
    Expression asJSObject(Expression object, [bool nullable = false]) =>
        AsExpression(
            object,
            InterfaceType(_jsObject,
                nullable ? Nullability.nullable : Nullability.nonNullable))
          ..fileOffset = node.fileOffset;

    Expression toJSString(String string) =>
        StaticInvocation(_stringToJS, Arguments([StringLiteral(string)]))
          ..fileOffset = node.fileOffset;

    StaticInvocation callMethodVarArgs(Expression jsObject, String methodName,
        List<Expression> args, DartType returnType) {
      // `jsObject.callMethodVarArgs(methodName.toJS, args)`
      return StaticInvocation(
          _callMethodVarArgs,
          Arguments([
            jsObject,
            toJSString(methodName),
            ListLiteral(args,
                typeArgument: InterfaceType(_jsAny, Nullability.nullable))
          ], types: [
            returnType
          ]))
        ..fileOffset = node.fileOffset;
    }

    // Get the global 'Object' property.
    Expression getObjectProperty() => asJSObject(StaticInvocation(_getProperty,
        Arguments([StaticGet(_globalContext), toJSString('Object')])))
      ..fileOffset = node.fileOffset;

    // Get a fresh object literal, using the proto to create it if one was
    // given.
    StaticInvocation getLiteral([Expression? proto]) {
      return callMethodVarArgs(
          getObjectProperty(),
          'create',
          [asJSObject(proto ?? NullLiteral(), true)],
          InterfaceType(_jsObject, Nullability.nonNullable));
    }

    var exportMap =
        _exportChecker.exportClassToMemberMap[dartType.classNode.reference]!;

    var block = <Statement>[];
    returnType ??= _typeEnvironment.coreTypes.objectNonNullableRawType;

    var dartInstance = VariableDeclaration('#dartInstance',
        initializer: node.arguments.positional[0],
        type: dartType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(dartInstance);

    var jsExporter = VariableDeclaration('#jsExporter',
        initializer: getLiteral(proto),
        type: InterfaceType(_jsObject, Nullability.nonNullable),
        isSynthesized: true)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(jsExporter);

    for (var exportName in exportMap.keys) {
      var exports = exportMap[exportName]!;
      ExpressionStatement setProperty(
          VariableGet jsObject, String propertyName, StaticInvocation jsValue) {
        // `jsObject[propertyName.toJS] = jsValue`
        return ExpressionStatement(StaticInvocation(_setProperty,
            Arguments([jsObject, toJSString(propertyName), jsValue])))
          ..fileOffset = node.fileOffset
          ..parent = node.parent;
      }

      var firstExport = exports.first;
      // With methods, there's only one export per export name.
      if (firstExport is Procedure &&
          firstExport.kind == ProcedureKind.Method) {
        // `jsExport[jsName.toJS] = dartMock.tearoffMethod.toJS`
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
        // getSetMap['get'.toJS] = () {
        //   return dartInstance.getter;
        // }.toJS;
        // ```
        //
        // in the case of a getter and:
        //
        // ```
        // getSetMap['set'.toJS] = (val) {
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
            type: InterfaceType(_jsObject, Nullability.nonNullable),
            isSynthesized: true)
          ..fileOffset = node.fileOffset
          ..parent = node.parent;
        block.add(getSetMap);
        var getSet = _exportChecker.getGetterSetter(exports);
        var getter = getSet.getter;
        var setter = getSet.setter;
        if (getter != null) {
          block.add(setProperty(
              VariableGet(getSetMap),
              'get',
              StaticInvocation(
                  _functionToJS,
                  Arguments([
                    FunctionExpression(FunctionNode(ReturnStatement(InstanceGet(
                        InstanceAccessKind.Instance,
                        VariableGet(dartInstance),
                        getter.name,
                        interfaceTarget: getter,
                        resultType: _staticInteropMockValidator
                            .typeParameterResolver
                            .resolve(getter.getterType)))))
                  ]))));
        }
        if (setter != null) {
          var setterParameter = VariableDeclaration('#val',
              type: _staticInteropMockValidator.typeParameterResolver
                  .resolve(setter.setterType),
              isSynthesized: true)
            ..fileOffset = node.fileOffset
            ..parent = node.parent;
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
                        positionalParameters: [setterParameter]))
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
          ..fileOffset = node.fileOffset
          ..parent = node.parent);
      }
    }

    block.add(ReturnStatement(AsExpression(VariableGet(jsExporter), returnType)
      ..fileOffset = node.fileOffset));
    // Return a call to evaluate the entire block of code and return the JS mock
    // that was created.
    return FunctionInvocation(
        FunctionAccessKind.Function,
        FunctionExpression(FunctionNode(Block(block), returnType: returnType)),
        Arguments([]),
        functionType: FunctionType([], returnType, Nullability.nonNullable))
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
  }
}
