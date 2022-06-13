// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToInitializingFormal extends CorrectionProducer {
  @override
  // The fix isn't able to remove the initializer list / block function body in
  // the case where multiple initializers / statements are being removed.
  bool get canBeAppliedInBulk => false;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_INITIALIZING_FORMAL;

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
      var identifier = parameter.identifier;
      if (identifier == null) {
        return;
      }

      var preserveType = parameter.type?.type != node.writeType;

      await builder.addDartFileEdit(file, (builder) {
        if (preserveType) {
          builder.addSimpleInsertion(identifier.offset, 'this.');
        } else {
          builder.addSimpleReplacement(
              range.node(parameter), 'this.${identifier.name}');
        }

        var statements = block.statements;
        var functionBody = block.parent;
        if (statements.length == 1 && functionBody is BlockFunctionBody) {
          builder.addSimpleReplacement(
              range.endEnd(constructor.parameters, functionBody), ';');
        } else {
          builder.addDeletion(range.nodeInList(statements, statement));
        }
      });
    } else if (node is ConstructorFieldInitializer) {
      var parameter = _parameter(constructor, node.expression);
      if (parameter == null) {
        return;
      }
      var identifier = parameter.identifier;
      if (identifier == null) {
        return;
      }

      var fieldElement = node.fieldName.staticElement;
      if (fieldElement is! VariableElement) {
        return;
      }

      var preserveType = parameter.type?.type != fieldElement.type;

      await builder.addDartFileEdit(file, (builder) {
        if (preserveType) {
          builder.addSimpleInsertion(identifier.offset, 'this.');
        } else {
          builder.addSimpleReplacement(
              range.node(parameter), 'this.${identifier.name}');
        }

        var initializers = constructor.initializers;
        if (initializers.length == 1) {
          builder.addDeletion(range.endEnd(constructor.parameters, node));
        } else {
          builder.addDeletion(range.nodeInList(initializers, node));
        }
      });
    }
  }

  SimpleFormalParameter? _parameter(
      ConstructorDeclaration constructor, Expression expression) {
    if (expression is! SimpleIdentifier) {
      return null;
    }
    var parameterElement = expression.staticElement;
    for (var parameter in constructor.parameters.parameters) {
      if (parameter.declaredElement == parameterElement) {
        if (parameter is DefaultFormalParameter) {
          parameter = parameter.parameter;
        }
        return parameter is SimpleFormalParameter ? parameter : null;
      }
    }
    return null;
  }
}
