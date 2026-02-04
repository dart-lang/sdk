// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToInitializingFormal extends ResolvedCorrectionProducer {
  ConvertToInitializingFormal({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // The fix isn't able to remove the initializer list / block function body
      // in the case where multiple initializers / statements are being removed.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.convertToInitializingFormal;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }
    if (node is AssignmentExpression) {
      var statement = node.parent;
      if (statement is! ExpressionStatement) {
        return;
      }
      var block = statement.parent;
      if (block is! Block) {
        return;
      }
      var parameter = _parameter(constructor, node.rightHandSide);
      if (parameter == null) {
        return;
      }
      var identifier = parameter.name;
      if (identifier == null) {
        return;
      }
      var field = node.writeElement;
      if (field == null) {
        return;
      }

      var preserveType = parameter.type?.type != node.writeType;

      await builder.addDartFileEdit(file, (builder) {
        _makeInitializingFormal(builder, parameter, field.name, preserveType);

        // Remove the assignment.
        var statements = block.statements;
        var functionBody = block.parent;
        if (statements.length == 1 && functionBody is BlockFunctionBody) {
          builder.addSimpleReplacement(
            range.endEnd(constructor.parameters, functionBody),
            ';',
          );
        } else {
          builder.addDeletion(range.nodeInList(statements, statement));
        }
      });
    } else if (node is ConstructorFieldInitializer) {
      var parameter = _parameter(constructor, node.expression);
      if (parameter == null) {
        return;
      }
      var identifier = parameter.name;
      if (identifier == null) {
        return;
      }

      var fieldElement = node.fieldName.element;
      if (fieldElement is! VariableElement) {
        return;
      }

      var preserveType = parameter.type?.type != fieldElement.type;

      await builder.addDartFileEdit(file, (builder) {
        _makeInitializingFormal(
          builder,
          parameter,
          fieldElement.name,
          preserveType,
        );

        // Remove the initializer.
        var initializers = constructor.initializers;
        if (initializers.length == 1) {
          builder.addDeletion(range.endEnd(constructor.parameters, node));
        } else {
          builder.addDeletion(range.nodeInList(initializers, node));
        }
      });
    }
  }

  /// Convert [parameter] to an initializing formal for the field with name
  /// [fieldName].
  ///
  /// If [preserveType] is `true`, keep any type annotation on the parameter.
  /// Otherwise, remove it.
  void _makeInitializingFormal(
    DartFileEditBuilder builder,
    SimpleFormalParameter parameter,
    String? fieldName,
    bool preserveType,
  ) {
    if (preserveType) {
      var parameterName = parameter.name!;
      builder.addSimpleInsertion(parameterName.offset, 'this.');

      // If we're initializing a private field from a public parameter (which
      // will always be named), then convert it to a private named parameter.
      if (fieldName == '_${parameterName.lexeme}') {
        builder.addSimpleInsertion(parameterName.offset, '_');
      }
    } else {
      var prefix = parameter.requiredKeyword != null ? 'required ' : '';
      builder.addSimpleReplacement(
        range.node(parameter),
        '${prefix}this.$fieldName',
      );
    }
  }

  SimpleFormalParameter? _parameter(
    ConstructorDeclaration constructor,
    Expression expression,
  ) {
    if (expression is! SimpleIdentifier) {
      return null;
    }
    var parameterElement = expression.element;
    for (var parameter in constructor.parameters.parameters) {
      if (parameter.declaredFragment?.element == parameterElement) {
        parameter = parameter.notDefault;
        return parameter is SimpleFormalParameter ? parameter : null;
      }
    }
    return null;
  }
}
