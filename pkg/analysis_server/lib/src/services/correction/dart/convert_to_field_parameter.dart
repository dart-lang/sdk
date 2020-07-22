// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToFieldParameter extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_FIELD_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node == null) {
      return;
    }
    // prepare ConstructorDeclaration
    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }
    var parameterList = constructor.parameters;
    List<ConstructorInitializer> initializers = constructor.initializers;
    // prepare parameter
    SimpleFormalParameter parameter;
    if (node.parent is SimpleFormalParameter &&
        node.parent.parent is FormalParameterList &&
        node.parent.parent.parent is ConstructorDeclaration) {
      parameter = node.parent;
    }
    if (node is SimpleIdentifier &&
        node.parent is ConstructorFieldInitializer) {
      var name = (node as SimpleIdentifier).name;
      ConstructorFieldInitializer initializer = node.parent;
      if (initializer.expression == node) {
        for (var formalParameter in parameterList.parameters) {
          if (formalParameter is SimpleFormalParameter &&
              formalParameter.identifier.name == name) {
            parameter = formalParameter;
          }
        }
      }
    }
    // analyze parameter
    if (parameter != null) {
      var parameterName = parameter.identifier.name;
      var parameterElement = parameter.declaredElement;
      // check number of references
      var visitor = _ReferenceCounter(parameterElement);
      for (var initializer in initializers) {
        initializer.accept(visitor);
      }
      if (visitor.count != 1) {
        return;
      }
      // find the field initializer
      ConstructorFieldInitializer parameterInitializer;
      for (var initializer in initializers) {
        if (initializer is ConstructorFieldInitializer) {
          var expression = initializer.expression;
          if (expression is SimpleIdentifier &&
              expression.name == parameterName) {
            parameterInitializer = initializer;
          }
        }
      }
      if (parameterInitializer == null) {
        return;
      }
      var fieldName = parameterInitializer.fieldName.name;

      await builder.addDartFileEdit(file, (builder) {
        // replace parameter
        builder.addSimpleReplacement(range.node(parameter), 'this.$fieldName');
        // remove initializer
        var initializerIndex = initializers.indexOf(parameterInitializer);
        if (initializers.length == 1) {
          builder
              .addDeletion(range.endEnd(parameterList, parameterInitializer));
        } else {
          if (initializerIndex == 0) {
            var next = initializers[initializerIndex + 1];
            builder.addDeletion(range.startStart(parameterInitializer, next));
          } else {
            var prev = initializers[initializerIndex - 1];
            builder.addDeletion(range.endEnd(prev, parameterInitializer));
          }
        }
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertToFieldParameter newInstance() => ConvertToFieldParameter();
}

class _ReferenceCounter extends RecursiveAstVisitor<void> {
  final ParameterElement parameterElement;

  int count = 0;

  _ReferenceCounter(this.parameterElement);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == parameterElement) {
      count++;
    }
  }
}
