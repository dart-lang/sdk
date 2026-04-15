// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToInitializingFormal extends ResolvedCorrectionProducer {
  ConvertToInitializingFormal({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // The code to remove an initializer or assignment statement assumes that
      // no other initializers or statements are being removed concurrently, so
      // only works one at a time. But it is safe to run this fix multiple times
      // sequentially.
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToInitializingFormal;

  @override
  FixKind get fixKind => DartFixKind.convertToInitializingFormal;

  @override
  FixKind get multiFixKind => DartFixKind.convertToInitializingFormalMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    FormalParameterList? parameterList;
    NodeList<ConstructorInitializer>? initializers;
    Comment? documentationComment;
    FunctionBody? body;

    var anchorNode = _findAnchorNode();
    if (anchorNode case ConstructorDeclaration constructor) {
      parameterList = constructor.parameters;
      initializers = constructor.initializers;
      documentationComment = constructor.documentationComment;
      body = constructor.body;
    } else if (anchorNode
        case PrimaryConstructorDeclaration primaryConstructor) {
      parameterList = primaryConstructor.formalParameters;
      var primaryBody = primaryConstructor.body;
      if (primaryBody != null) {
        initializers = primaryBody.initializers;
        documentationComment = primaryBody.documentationComment;
        body = primaryBody.body;
      }
    } else if (anchorNode case PrimaryConstructorBody primaryBody) {
      var declaration = primaryBody.declaration;
      if (declaration == null) return;
      parameterList = declaration.formalParameters;
      initializers = primaryBody.initializers;
      documentationComment = primaryBody.documentationComment;
      body = primaryBody.body;
    } else {
      return;
    }

    switch (node) {
      case AssignmentExpression assignment:
        // An assignment at the top level of the constructor body.
        var statement = node.parent;
        if (statement is! ExpressionStatement) return;

        var block = statement.parent;
        if (block is! Block) return;

        if (_findParameter(parameterList, assignment.rightHandSide) case (
          var parameter,
          var parameterElement,
        )) {
          switch (assignment.writeElement) {
            case VariableElement field:
            case SetterElement(variable: VariableElement field):
              await _computeChange(
                builder,
                parameterList,
                initializers,
                documentationComment,
                parameter,
                parameterElement,
                field,
                assignment: statement,
              );
          }
        }

      case ConstructorFieldInitializer initializer:
        // An explicit field initializer in a constructor initializer list.
        if (_findParameter(parameterList, initializer.expression) case (
          var parameter,
          var parameterElement,
        )) {
          var field = initializer.fieldName.element;
          if (field is! VariableElement) return;

          await _computeChange(
            builder,
            parameterList,
            initializers,
            documentationComment,
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
          parameterList,
          initializers,
          documentationComment,
          body,
          parameter,
          parameter.declaredFragment!.element,
        );

      case SimpleIdentifier parameterUse:
        // At an identifier expression that refers to a constructor parameter.
        if (parameterUse.element case FormalParameterElement parameterElement) {
          if (_findParameter(parameterList, parameterUse) case (
            var parameter,
            _,
          )) {
            await _computeChangeFromParameter(
              builder,
              parameterList,
              initializers,
              documentationComment,
              body,
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
  /// This won't produce a change if it's not valid or safe to convert to an
  /// initializing formal.
  ///
  /// The parameter should currently be initialized by either [initializer] or
  /// [assignment] but not both.
  Future<void> _computeChange(
    ChangeBuilder builder,
    FormalParameterList parameterList,
    NodeList<ConstructorInitializer>? initializers,
    Comment? documentationComment,
    NormalFormalParameter parameter,
    FormalParameterElement parameterElement,
    VariableElement field, {
    ConstructorFieldInitializer? initializer,
    Statement? assignment,
  }) async {
    assert(initializer == null || assignment == null);
    if (parameter is SuperFormalParameter) return;
    var parameterName = parameter.name!.lexeme;
    var fieldName = field.displayName;
    var updateCommentReferences = false;

    if (parameter.isNamed) {
      if (fieldName == '_$parameterName') {
        // We can't convert a private named parameter to an initializing formal
        // unless those are supported in this library.
        if (!isEnabled(Feature.private_named_parameters) &&
            Identifier.isPrivateName(fieldName)) {
          return;
        }
        updateCommentReferences = true;
      } else if (fieldName != parameterName) {
        // We can't rename the parameter to match the field name if the parameter
        // is named since that's an API change.
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      // Convert the parameter to an initializing formal.
      builder.addSimpleInsertion(parameter.name!.offset, 'this.');

      // Change the name if necessary.
      if (fieldName != parameterName) {
        builder.addSimpleReplacement(range.token(parameter.name!), fieldName);
      }

      if (parameter.declaredFragment!.element.type == field.type) {
        // The parameter type is the same as the field, so remove it and let it
        // be inferred from the field.
        switch (parameter) {
          case FieldFormalParameter(:var type):
          case SimpleFormalParameter(:var type):
          case SuperFormalParameter(:var type):
            if (type != null) builder.addDeletion(range.deletionRange(type));
          case FunctionTypedFormalParameter(
            :var returnType,
            :var typeParameters,
            :var parameters,
          ):
            if (returnType != null) {
              builder.addDeletion(range.deletionRange(returnType));
            }
            builder.addDeletion(
              range.deletionRange(
                typeParameters ?? parameters,
                overrideEnd: parameters.endToken,
              ),
            );
        }
      }

      // Remove the constructor initializer.
      if (initializer != null) {
        if (initializers!.length == 1) {
          var initializerParent = initializer.parent;
          if (initializerParent is PrimaryConstructorBody) {
            builder.addDeletion(
              range.endEnd(initializerParent.thisKeyword, initializer),
            );
          } else {
            builder.addDeletion(range.endEnd(parameterList, initializer));
          }
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
          var bodyParent = functionBody.parent;
          if (bodyParent is PrimaryConstructorBody) {
            builder.addSimpleReplacement(
              range.endEnd(
                initializers != null && initializers.isNotEmpty
                    ? initializers.last
                    : bodyParent.thisKeyword,
                functionBody,
              ),
              ';',
            );
          } else {
            builder.addSimpleReplacement(
              range.endEnd(
                initializers != null && initializers.isNotEmpty
                    ? initializers.last
                    : parameterList,
                functionBody,
              ),
              ';',
            );
          }
        } else {
          builder.addDeletion(range.nodeInList(statements, assignment));
        }
      }

      if (updateCommentReferences) {
        var references = documentationComment?.references;
        if (references != null) {
          for (var reference in references) {
            if (reference.expression case SimpleIdentifier expression) {
              if (expression.element == parameterElement) {
                builder.addSimpleInsertion(expression.offset, '_');
              }
            }
          }
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
    FormalParameterList parameterList,
    NodeList<ConstructorInitializer>? initializers,
    Comment? documentationComment,
    FunctionBody? body,
    NormalFormalParameter parameter,
    FormalParameterElement parameterElement,
  ) async {
    // If there happens to be both an initializer and an assignment, the
    // initializer will be first, so convert that and ignore the later mutating
    // assignment.
    var initializer = initializers != null
        ? _findInitializer(initializers, parameterElement)
        : null;
    if (initializer?.fieldName.element case VariableElement field) {
      await _computeChange(
        builder,
        parameterList,
        initializers,
        documentationComment,
        parameter,
        parameterElement,
        field,
        initializer: initializer,
      );
    } else if (_findAssignment(body, parameterElement) case (
      var statement,
      var field,
    )) {
      await _computeChange(
        builder,
        parameterList,
        initializers,
        documentationComment,
        parameter,
        parameterElement,
        field,
        assignment: statement,
      );
    }
  }

  AstNode? _findAnchorNode() {
    AstNode? currentNode = node;
    while (currentNode != null) {
      if (currentNode is ConstructorDeclaration) {
        return currentNode;
      } else if (currentNode is PrimaryConstructorDeclaration) {
        return currentNode;
      } else if (currentNode is PrimaryConstructorBody) {
        return currentNode;
      }
      currentNode = currentNode.parent;
    }
    return null;
  }

  /// Looks through the top-level statements in the constructor [body] for a
  /// statement like:
  ///
  ///      this.x = y;
  ///
  /// where `y` refers to the [parameter]. If found, returns the statement and
  /// the field it assigns to.
  (Statement, VariableElement)? _findAssignment(
    FunctionBody? body,
    FormalParameterElement parameter,
  ) {
    if (body case BlockFunctionBody blockBody) {
      for (var statement in blockBody.block.statements) {
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
    NodeList<ConstructorInitializer> initializers,
    FormalParameterElement parameter,
  ) {
    for (var initializer in initializers) {
      if (initializer case ConstructorFieldInitializer(
        expression: SimpleIdentifier identifier,
      ) when identifier.element == parameter) {
        return initializer;
      }
    }

    return null;
  }

  /// If [expression] is an identifier that refers to a formal parameter in the
  /// [parameterList], then returns the corresponding parameter AST node.
  (NormalFormalParameter, FormalParameterElement)? _findParameter(
    FormalParameterList parameterList,
    Expression expression,
  ) {
    if (expression case SimpleIdentifier(
      element: FormalParameterElement element,
    )) {
      if (_findParameterForElement(parameterList, element)
          case var parameter?) {
        return (parameter, element);
      }
    }
    return null;
  }

  /// If [element] is an element for a formal parameter in the [parameterList],
  /// then returns the corresponding parameter AST node.
  NormalFormalParameter? _findParameterForElement(
    FormalParameterList parameterList,
    FormalParameterElement element,
  ) {
    for (var parameter in parameterList.parameters) {
      if (parameter.notDefault case var parameter
          when parameter.declaredFragment?.element == element) {
        return parameter;
      }
    }

    return null;
  }
}
