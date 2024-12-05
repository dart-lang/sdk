// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToFieldParameter extends ResolvedCorrectionProducer {
  ConvertToFieldParameter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_FIELD_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare parameter
    var context = _findParameter(node);
    if (context == null) {
      return;
    }

    // analyze parameter
    var parameterName = context.identifier.lexeme;
    var parameterElement = context.parameter.declaredFragment!.element;
    var initializers = context.constructor.initializers;

    // check number of references
    var visitor = _ReferenceCounter(parameterElement);
    for (var initializer in initializers) {
      initializer.accept(visitor);
    }
    if (visitor.count != 1) {
      return;
    }
    // find the field initializer
    ConstructorFieldInitializer? parameterInitializer;
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

    var context_final = context;
    var parameterInitializer_final = parameterInitializer;
    await builder.addDartFileEdit(file, (builder) {
      // replace parameter
      builder.addSimpleReplacement(
        range.node(context_final.parameter),
        'this.$fieldName',
      );
      // remove initializer
      var initializerIndex = initializers.indexOf(parameterInitializer_final);
      if (initializers.length == 1) {
        builder.addDeletion(
          range.endEnd(
            context_final.constructor.parameters,
            parameterInitializer_final,
          ),
        );
      } else {
        if (initializerIndex == 0) {
          var next = initializers[initializerIndex + 1];
          builder.addDeletion(
            range.startStart(parameterInitializer_final, next),
          );
        } else {
          var prev = initializers[initializerIndex - 1];
          builder.addDeletion(
            range.endEnd(prev, parameterInitializer_final),
          );
        }
      }
    });
  }

  static _Context? _findParameter(AstNode node) {
    var parent = node.parent;
    if (node is SimpleFormalParameter) {
      var identifier = node.name;
      if (identifier == null) return null;

      var formalParameterList = parent;
      if (formalParameterList is! FormalParameterList) return null;

      var constructor = formalParameterList.parent;
      if (constructor is! ConstructorDeclaration) return null;

      return _Context(
        parameter: node,
        identifier: identifier,
        constructor: constructor,
      );
    }

    if (node is SimpleIdentifier && parent is ConstructorFieldInitializer) {
      var constructor = parent.parent;
      if (constructor is! ConstructorDeclaration) return null;

      if (parent.expression == node) {
        for (var formalParameter in constructor.parameters.parameters) {
          if (formalParameter is SimpleFormalParameter) {
            var identifier = formalParameter.name;
            if (identifier != null && identifier.lexeme == node.name) {
              return _Context(
                parameter: formalParameter,
                identifier: identifier,
                constructor: constructor,
              );
            }
          }
        }
      }
    }

    return null;
  }
}

class _Context {
  final SimpleFormalParameter parameter;
  final Token identifier;
  final ConstructorDeclaration constructor;

  _Context({
    required this.parameter,
    required this.identifier,
    required this.constructor,
  });
}

class _ReferenceCounter extends RecursiveAstVisitor<void> {
  final FormalParameterElement parameterElement;

  int count = 0;

  _ReferenceCounter(this.parameterElement);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == parameterElement) {
      count++;
    }
  }
}
