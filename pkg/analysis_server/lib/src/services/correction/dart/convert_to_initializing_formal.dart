// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
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
  AssistKind get assistKind => DartAssistKind.convertToInitializingFormal;

  @override
  FixKind get fixKind => DartFixKind.convertToInitializingFormal;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) return;

    switch (node) {
      case AssignmentExpression assignment:
        // An assignment at the top level of the constructor body.
        var statement = node.parent;
        if (statement is! ExpressionStatement) return;

        var block = statement.parent;
        if (block is! Block) return;

        if (_findParameter(constructor, assignment.rightHandSide) case (
          var parameter,
          var parameterElement,
        )) {
          switch (assignment.writeElement) {
            case VariableElement field:
            case SetterElement(variable: VariableElement field):
              await _computeChange(
                builder,
                constructor,
                parameter,
                parameterElement,
                field,
                assignment: statement,
              );
          }
        }

      case ConstructorFieldInitializer initializer:
        // An explicit field initializer in a constructor initializer list.
        if (_findParameter(constructor, initializer.expression) case (
          var parameter,
          var parameterElement,
        )) {
          var field = initializer.fieldName.element;
          if (field is! VariableElement) return;

          await _computeChange(
            builder,
            constructor,
            parameter,
            parameterElement,
            field,
            initializer: initializer,
          );
        }

      case SimpleFormalParameter parameter:
        // A constructor parameter declaration.
        await _computeChangeFromParameter(
          builder,
          constructor,
          parameter,
          parameter.declaredFragment!.element,
        );

      case SimpleIdentifier parameterUse:
        // At an identifier expression that refers to a constructor parameter.
        if (parameterUse.element case FormalParameterElement parameterElement) {
          if (_findParameter(constructor, parameterUse) case (
            var parameter,
            _,
          )) {
            await _computeChangeFromParameter(
              builder,
              constructor,
              parameter,
              parameterElement,
            );
          }
        }
    }
  }

  /// Attempts to compute a change [parameter] to an initializing formal for
  /// [field].
  ///
  /// This may not produce a change if it's not valid or safe to convert to an
  /// initializing formal.
  ///
  /// The parameter should currently be initialized by either [initializer] or
  /// [assignment] but not both.
  Future<void> _computeChange(
    ChangeBuilder builder,
    ConstructorDeclaration constructor,
    SimpleFormalParameter parameter,
    FormalParameterElement parameterElement,
    VariableElement field, {
    ConstructorFieldInitializer? initializer,
    Statement? assignment,
  }) async {
    var parameterName = parameter.name!.lexeme;
    var fieldName = field.displayName;

    if (parameter.isNamed) {
      if (fieldName == '_$parameterName') {
        // We can't convert a private named parameter to an initializing formal
        // unless those are supported in this library.
        if (!isEnabled(Feature.private_named_parameters) &&
            Identifier.isPrivateName(fieldName)) {
          return;
        }
      } else if (fieldName != parameterName) {
        // We can't rename the parameter to match the field name if the parameter
        // is named since that's an API change.
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      // Convert the parameter to an initializing formal.
      if (parameter.type?.type != field.type) {
        builder.addSimpleInsertion(parameter.name!.offset, 'this.');

        // If we're initializing a private field from a public parameter (which
        // will always be named), then convert it to a private named parameter.
        if (field.name == '_$parameterName') {
          builder.addSimpleInsertion(parameter.name!.offset, '_');
        }
      } else {
        // The parameter type is the same as the field, so remove it and let it
        // be inferred from the field.
        var prefix = parameter.requiredKeyword != null ? 'required ' : '';
        builder.addSimpleReplacement(
          range.node(parameter),
          '${prefix}this.${field.name}',
        );
      }

      // Remove the constructor initializer.
      if (initializer != null) {
        var initializers = constructor.initializers;
        if (initializers.length == 1) {
          builder.addDeletion(
            range.endEnd(constructor.parameters, initializer),
          );
        } else {
          builder.addDeletion(range.nodeInList(initializers, initializer));
        }
      }

      // Remove the assignment.
      if (assignment != null) {
        var block = assignment.parent as Block;
        var statements = block.statements;
        var functionBody = block.parent;
        if (statements.length == 1 && functionBody is BlockFunctionBody) {
          builder.addSimpleReplacement(
            range.endEnd(constructor.parameters, functionBody),
            ';',
          );
        } else {
          builder.addDeletion(range.nodeInList(statements, assignment));
        }
      }
    });
  }

  /// Applies the conversion when the cursor is on the parameter or a reference
  /// to the parameter.
  ///
  /// Looks for a corresponding constructor initializer or assignment statement
  /// and applies the conversion if one is found.
  Future<void> _computeChangeFromParameter(
    ChangeBuilder builder,
    ConstructorDeclaration constructor,
    SimpleFormalParameter parameter,
    FormalParameterElement parameterElement,
  ) async {
    // If there happens to be both an initializer and an assignment, the
    // initializer will be first, so convert that and ignore the later mutating
    // assignment.
    var initializer = _findInitializer(constructor, parameterElement);
    if (initializer?.fieldName.element case VariableElement field) {
      await _computeChange(
        builder,
        constructor,
        parameter,
        parameterElement,
        field,
        initializer: initializer,
      );
    } else if (_findAssignment(constructor, parameterElement) case (
      var statement,
      var field,
    )) {
      await _computeChange(
        builder,
        constructor,
        parameter,
        parameterElement,
        field,
        assignment: statement,
      );
    }
  }

  /// Looks through the top-level statements in the [constructor] body for a
  /// statement like:
  ///
  ///      this.x = y;
  ///
  /// where `y` is refers to [parameter]. If found, returns the statement and
  /// the field it assigns to.
  (Statement, VariableElement)? _findAssignment(
    ConstructorDeclaration constructor,
    FormalParameterElement parameter,
  ) {
    if (constructor.body case BlockFunctionBody body) {
      for (var statement in body.block.statements) {
        if (statement case ExpressionStatement(
          expression: AssignmentExpression(
            leftHandSide: PropertyAccess(target: ThisExpression()),
            rightHandSide: SimpleIdentifier(
              element: FormalParameterElement parameterElement,
            ),
            writeElement: SetterElement field,
          ),
        )) {
          if (parameterElement != parameter) continue;

          return (statement, field.variable);
        }
      }
    }

    return null;
  }

  /// Looks for a constructor initializer that initializes a field directly from
  /// [parameter].
  ConstructorFieldInitializer? _findInitializer(
    ConstructorDeclaration constructor,
    FormalParameterElement parameter,
  ) {
    for (var initializer in constructor.initializers) {
      if (initializer case ConstructorFieldInitializer(
        expression: SimpleIdentifier identifier,
      ) when identifier.element == parameter) {
        return initializer;
      }
    }

    return null;
  }

  /// If [expression] is an identifier that refers to a formal parameter in
  /// [constructor], then returns the corresponding parameter AST node.
  (SimpleFormalParameter, FormalParameterElement)? _findParameter(
    ConstructorDeclaration constructor,
    Expression expression,
  ) {
    if (expression case SimpleIdentifier(
      element: FormalParameterElement element,
    )) {
      if (_findParameterForElement(constructor, element) case var parameter?) {
        return (parameter, element);
      }
    }

    return null;
  }

  /// If [element] is an element for a formal parameter in [constructor], then
  /// returns the corresponding parameter AST node.
  SimpleFormalParameter? _findParameterForElement(
    ConstructorDeclaration constructor,
    FormalParameterElement element,
  ) {
    for (var parameter in constructor.parameters.parameters) {
      if (parameter.notDefault case SimpleFormalParameter simpleParameter
          when parameter.declaredFragment?.element == element) {
        return simpleParameter;
      }
    }

    return null;
  }
}
