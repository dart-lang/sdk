// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethodOrFunction extends ResolvedCorrectionProducer {
  @override
  final FixKind fixKind;

  String _functionName = '';

  /// The [Element] for the target of the node's parent, if that is a
  /// [PrefixedIdentifier] or [PropertyAccess], and `null` otherwise.
  final Element? _targetElement;

  factory CreateMethodOrFunction({required CorrectionProducerContext context}) {
    if (context is StubCorrectionProducerContext) {
      return CreateMethodOrFunction._(
        context: context,
        fixKind: DartFixKind.createFunctionTearoff,
      );
    }

    if (context.node case SimpleIdentifier node) {
      // Prepare the argument expression (to get the parameter).
      Element? targetElement;
      var target = getQualifiedPropertyTarget(node);
      if (target == null) {
        targetElement = node.enclosingInterfaceElement;
      } else {
        var targetType = target.staticType;
        if (targetType is InterfaceType) {
          targetElement = targetType.element;
        } else {
          targetElement = switch (target) {
            SimpleIdentifier() => target.element,
            PrefixedIdentifier() => target.identifier.element,
            _ => null,
          };
        }
      }

      return CreateMethodOrFunction._(
        context: context,
        targetElement: targetElement,
        fixKind: targetElement is InterfaceElement
            ? DartFixKind.createMethodTearoff
            : DartFixKind.createFunctionTearoff,
      );
    }

    return CreateMethodOrFunction._(
      context: context,
      fixKind: DartFixKind.createFunctionTearoff,
    );
  }

  CreateMethodOrFunction._({
    required super.context,
    this._targetElement,
    required this.fixKind,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_functionName];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node case SimpleIdentifier node) {
      DartType? parameterType;
      var fieldTypeNode = climbPropertyAccess(node);
      parameterType = inferUndefinedExpressionType(fieldTypeNode);
      if (parameterType is InvalidType) {
        return;
      }

      var target = getQualifiedPropertyTarget(node);

      if (parameterType == null) {
        // If we cannot infer the type, we cannot create a method or function.
        return;
      }

      if (parameterType is InterfaceType && parameterType.isDartCoreFunction) {
        parameterType = FunctionTypeImpl(
          typeParameters: const [],
          parameters: const [],
          returnType: DynamicTypeImpl.instance,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }

      if (parameterType is! FunctionType) {
        // If the type is not a function type, we cannot create a method or
        // function.
        return;
      }

      if (_targetElement is InterfaceElement) {
        var isStatic =
            (target is SimpleIdentifier &&
                target.element is InterfaceElement) ||
            (target is PrefixedIdentifier &&
                target.identifier.element is InterfaceElement);
        await _createMethod(
          builder,
          _targetElement,
          parameterType,
          isStatic: isStatic,
        );
      } else {
        await _createFunction(builder, parameterType);
      }
    }
  }

  /// Prepares proposal for creating function corresponding to the given
  /// [FunctionType].
  void _createExecutable(
    DartEditBuilder builder,
    FunctionType functionType,
    String name,
    bool isStatic,
  ) {
    // may be static
    if (isStatic) {
      builder.write('static ');
    }
    // append return type
    if (builder.writeType(
      functionType.returnType,
      typeParametersInScope: functionType.typeParameters,
      groupName: 'RETURN_TYPE',
    )) {
      builder.write(' ');
    }
    // append name
    builder.addLinkedEdit('NAME', (builder) {
      builder.write(name);
    });
    // append type parameters
    builder.writeTypeParameters(functionType.typeParameters);
    // append parameters
    builder.writeFormalParameters(functionType.formalParameters);
    if (functionType.returnType.isDartAsyncFuture) {
      builder.write(' async');
    }
    // close method
    builder.write(' {}');
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] inside the target element.
  Future<void> _createFunction(
    ChangeBuilder builder,
    FunctionType functionType,
  ) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var insertOffset = unit.end;
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertOffset, (builder) {
        builder.writeln();
        _createExecutable(builder, functionType, name, false);
        builder.writeln();
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
    _functionName = name;
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] inside the target element.
  Future<void> _createMethod(
    ChangeBuilder builder,
    InterfaceElement targetClassElement,
    FunctionType functionType, {
    required bool isStatic,
  }) async {
    var name = (node as SimpleIdentifier).name;
    // prepare insert offset
    var targetNode = await getDeclarationNodeFromElement(targetClassElement);
    if (targetNode == null) {
      return;
    }
    // prepare environment
    var targetSource = targetClassElement.firstFragment.libraryFragment.source;
    var targetFile = targetSource.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.insertMethod(targetNode, (builder) {
        _createExecutable(
          builder,
          functionType,
          name,
          isStatic || inStaticContext,
        );
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    _functionName = name;
  }
}
