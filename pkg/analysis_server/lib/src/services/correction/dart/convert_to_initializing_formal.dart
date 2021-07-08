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
      var right = node.rightHandSide;
      if (right is! SimpleIdentifier) {
        return;
      }
      var parameterElement = right.staticElement;
      var parameter = _parameterForElement(constructor, parameterElement);
      if (parameter is! SimpleFormalParameter) {
        return;
      }
      var name = parameter.identifier?.name;
      if (name == null) {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(parameter), 'this.$name');
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
      var right = node.expression;
      if (right is! SimpleIdentifier) {
        return;
      }
      var parameterElement = right.staticElement;
      var parameter = _parameterForElement(constructor, parameterElement);
      if (parameter is! SimpleFormalParameter) {
        return;
      }
      var name = parameter.identifier?.name;
      if (name == null) {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(parameter), 'this.$name');
        var initializers = constructor.initializers;
        if (initializers.length == 1) {
          builder.addDeletion(range.endEnd(constructor.parameters, node));
        } else {
          builder.addDeletion(range.nodeInList(initializers, node));
        }
      });
    }
  }

  FormalParameter? _parameterForElement(
      ConstructorDeclaration constructor, Element? parameterElement) {
    for (var parameter in constructor.parameters.parameters) {
      if (parameter.declaredElement == parameterElement) {
        return parameter;
      }
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToInitializingFormal newInstance() =>
      ConvertToInitializingFormal();
}
