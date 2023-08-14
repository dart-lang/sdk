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
  final Procedure _allowInterop;
  final Procedure _createDartExport;
  final Procedure _createStaticInteropMock;
  final JsInteropDiagnosticReporter _diagnosticReporter;
  final ExportChecker _exportChecker;
  final InterfaceType _functionType;
  final Procedure _getProperty;
  final Procedure _globalThis;
  final InterfaceType _objectType;
  final Procedure _setProperty;
  final StaticInteropMockValidator _staticInteropMockValidator;
  final TypeEnvironment _typeEnvironment;

  ExportCreator(
      this._typeEnvironment, this._diagnosticReporter, this._exportChecker)
      : _allowInterop = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'allowInterop'),
        _createDartExport = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createDartExport'),
        _createStaticInteropMock = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'createStaticInteropMock'),
        _functionType = _typeEnvironment.coreTypes.functionNonNullableRawType,
        _getProperty = (_typeEnvironment.coreTypes.index.tryGetTopLevelMember(
                'dart:js_util', '_getPropertyTrustType') ??
            _typeEnvironment.coreTypes.index.getTopLevelProcedure(
                'dart:js_util', 'getProperty')) as Procedure,
        _globalThis = _typeEnvironment.coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'get:globalThis'),
        _objectType = _typeEnvironment.coreTypes.objectNonNullableRawType,
        _setProperty = (_typeEnvironment.coreTypes.index.tryGetTopLevelMember(
                'dart:js_util', '_setPropertyUnchecked') ??
            _typeEnvironment.coreTypes.index.getTopLevelProcedure(
                'dart:js_util', 'setProperty')) as Procedure,
        _staticInteropMockValidator = StaticInteropMockValidator(
            _diagnosticReporter, _exportChecker, _typeEnvironment);

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    if (node.target == _createDartExport) {
      var typeArguments = node.arguments.types;
      assert(typeArguments.length == 1);
      if (_verifyExportable(node, typeArguments[0])) {
        return _createExport(node, typeArguments[0] as InterfaceType);
      }
    } else if (node.target == _createStaticInteropMock) {
      var typeArguments = node.arguments.types;
      assert(typeArguments.length == 2);
      var staticInteropType = typeArguments[0];
      var dartType = typeArguments[1];

      var exportable = _verifyExportable(node, dartType);
      var staticInteropTypeArgumentCorrect = _staticInteropMockValidator
          .validateStaticInteropTypeArgument(node, staticInteropType);
      if (exportable &&
          staticInteropTypeArgumentCorrect &&
          _staticInteropMockValidator.validateCreateStaticInteropMock(
              node,
              (staticInteropType as InterfaceType).classNode,
              (dartType as InterfaceType).classNode)) {
        var arguments = node.arguments.positional;
        assert(arguments.length == 1 || arguments.length == 2);
        var proto = arguments.length == 2 ? arguments[1] : null;

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

    // Get the global 'Object' property.
    StaticInvocation getObjectProperty() => StaticInvocation(
        _getProperty,
        Arguments([StaticGet(_globalThis), StringLiteral('Object')],
            types: [_objectType]));

    // Get a fresh object literal, using the proto to create it if one was
    // given.
    StaticInvocation getLiteral([Expression? proto]) {
      return _callMethod(getObjectProperty(), StringLiteral('create'),
          [proto ?? NullLiteral()], _objectType);
    }

    var jsExporter = VariableDeclaration('#jsExporter',
        initializer: AsExpression(getLiteral(proto), returnType)
          ..fileOffset = node.fileOffset,
        type: returnType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
    block.add(jsExporter);

    for (var exportName in exportMap.keys) {
      var exports = exportMap[exportName]!;
      ExpressionStatement setProperty(VariableGet jsObject, String propertyName,
          StaticInvocation wrappedValue) {
        // `setProperty(jsObject, propertyName, wrappedValue)`
        return ExpressionStatement(StaticInvocation(
            _setProperty,
            Arguments([jsObject, StringLiteral(propertyName), wrappedValue],
                types: [_objectType])))
          ..fileOffset = node.fileOffset
          ..parent = node.parent;
      }

      var firstExport = exports.first;
      // With methods, there's only one export per export name.
      if (firstExport is Procedure &&
          firstExport.kind == ProcedureKind.Method) {
        // `setProperty(jsMock, jsName, allowInterop(dartMock.tearoffMethod))`
        block.add(setProperty(
            VariableGet(jsExporter),
            exportName,
            StaticInvocation(
                _allowInterop,
                Arguments([
                  InstanceTearOff(InstanceAccessKind.Instance,
                      VariableGet(dartInstance), firstExport.name,
                      interfaceTarget: firstExport,
                      resultType: firstExport.getterType)
                ], types: [
                  _functionType
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
        // setProperty(getSetMap, 'get', allowInterop(() {
        //   return dartInstance.getter;
        // }));
        // ```
        //
        // in the case of a getter and:
        //
        // ```
        // setProperty(getSetMap, 'set', allowInterop((val) {
        //  dartInstance.setter = val;
        // }));
        // ```
        //
        // in the case of a setter.
        //
        // A new map VariableDeclaration is created and added to the block of
        // statements for each export name.
        var getSetMap = VariableDeclaration('#${exportName}Mapping',
            initializer: getLiteral(), type: _objectType, isSynthesized: true)
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
                  _allowInterop,
                  Arguments([
                    FunctionExpression(FunctionNode(ReturnStatement(InstanceGet(
                        InstanceAccessKind.Instance,
                        VariableGet(dartInstance),
                        getter.name,
                        interfaceTarget: getter,
                        resultType: getter.getterType))))
                  ], types: [
                    _functionType
                  ]))));
        }
        if (setter != null) {
          var setterParameter = VariableDeclaration('#val',
              type: setter.setterType, isSynthesized: true)
            ..fileOffset = node.fileOffset
            ..parent = node.parent;
          block.add(setProperty(
              VariableGet(getSetMap),
              'set',
              StaticInvocation(
                  _allowInterop,
                  Arguments([
                    FunctionExpression(FunctionNode(
                        ExpressionStatement(InstanceSet(
                            InstanceAccessKind.Instance,
                            VariableGet(dartInstance),
                            setter.name,
                            VariableGet(setterParameter),
                            interfaceTarget: setter)),
                        positionalParameters: [setterParameter]))
                  ], types: [
                    _functionType
                  ]))));
        }
        // Call `Object.defineProperty` to define the export name with the
        // 'get' and/or 'set' mapping. This allows us to treat get/set
        // semantics as methods.
        block.add(ExpressionStatement(_callMethod(
            getObjectProperty(),
            StringLiteral('defineProperty'),
            [
              VariableGet(jsExporter),
              StringLiteral(exportName),
              VariableGet(getSetMap)
            ],
            VoidType()))
          ..fileOffset = node.fileOffset
          ..parent = node.parent);
      }
    }

    block.add(ReturnStatement(VariableGet(jsExporter)));
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

  // Optimize `callMethod` calls if possible.
  StaticInvocation _callMethod(Expression object, StringLiteral methodName,
      List<Expression> args, DartType returnType) {
    var index = args.length;
    var callMethodOptimized = _typeEnvironment.coreTypes.index
        .tryGetTopLevelMember(
            'dart:js_util', '_callMethodUncheckedTrustType$index');
    if (callMethodOptimized == null) {
      var callMethod = _typeEnvironment.coreTypes.index
          .getTopLevelProcedure('dart:js_util', 'callMethod');
      return StaticInvocation(
          callMethod,
          Arguments([object, methodName, ListLiteral(args)],
              types: [returnType]));
    } else {
      return StaticInvocation(callMethodOptimized as Procedure,
          Arguments([object, methodName, ...args], types: [returnType]));
    }
  }
}
