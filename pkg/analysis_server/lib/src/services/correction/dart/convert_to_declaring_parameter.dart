// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

typedef _RefactorData = ({
  FieldElement fieldElement,
  ConstructorFieldInitializer? initializer,
  PrimaryConstructorBody? constructorBody,
});

class ConvertToDeclaringParameter extends ResolvedCorrectionProducer {
  ConvertToDeclaringParameter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not a fix.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind? get assistKind => DartAssistKind.convertToDeclaringParameter;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node;
    if (parameter is! FormalParameter) {
      // The assist only applies to formal parameters.
      return;
    }

    var parameterName = parameter.name;
    if (parameterName == null) {
      // The assist only applies to formal parameters with a name.
      return;
    }

    if (!parameterName.sourceRange.contains(selectionOffset)) {
      // The assist only applies if the name of the parameter is selected.
      return;
    }

    var classMembers = _getClassMembers(parameter);
    if (classMembers == null) {
      // Only parameters in a class or enum can be converted.
      return;
    }

    var refactorData = _getRefactorData(parameter);
    if (refactorData == null) return;

    var fieldElement = refactorData.fieldElement;
    var initializer = refactorData.initializer;
    var constructorBody = refactorData.constructorBody;

    // Ensure that the field has a name.
    var fieldName = fieldElement.name;
    if (fieldName == null) return;

    // Ensure that we can find the declaration of the field.
    var fieldDeclaration = _getDeclaration(classMembers, fieldElement);
    if (fieldDeclaration == null) return;

    // If either the parameter or the field has comments or metadata, then
    // don't apply the assist. This is a temporary restriction until the assist
    // supports moving the comments and metadata to the parameter.
    if (parameter is AnnotatedNode &&
        _hasCommentOrMetadata(parameter as AnnotatedNode)) {
      return;
    }
    var fieldDeclarationList = fieldDeclaration.parent?.parent;
    if (fieldDeclarationList is AnnotatedNode &&
        _hasCommentOrMetadata(fieldDeclarationList)) {
      return;
    }

    // If the field has an initializer it must be a constant expression.
    // TODO(brianwilkerson): Handle the case where the initializer is a valid
    //  constant expression and can be moved to the parameter.
    if (fieldDeclaration.initializer != null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Move metadata and/or doc comments.
      var variableList = fieldDeclaration.parent as VariableDeclarationList;
      var member = variableList.parent;
      if (member is FieldDeclaration) {
        var metadata = member.metadata;
        var docComment = member.documentationComment;
        if (metadata.isNotEmpty || docComment != null) {
          var text = _getMetadataText(member);
          builder.addSimpleInsertion(parameter.offset, '\n$text  ');
        }
      }

      // Insert the keyword (and renaming if needed).
      var insertedVariable = false;
      if (parameter is FieldFormalParameter) {
        if (parameter.offset == parameter.thisKeyword.offset) {
          builder.addReplacement(
            range.startEnd(parameter.thisKeyword, parameter.period),
            (builder) {
              if (fieldElement.isFinal) {
                builder.write('final ');
              } else {
                builder.write('var ');
              }
              // If the parameter doesn't have a type, and the field does,
              // insert the type.
              if (parameter.type == null) {
                var variableList =
                    fieldDeclaration.parent as VariableDeclarationList;
                var type = variableList.type;
                if (type != null) {
                  builder.write(utils.getNodeText(type));
                  builder.write(' ');
                }
              }
            },
          );
          insertedVariable = true;
        } else {
          builder.addDeletion(
            range.startEnd(parameter.thisKeyword, parameter.period),
          );
        }
      }
      if (fieldName != parameterName.lexeme) {
        builder.addSimpleReplacement(range.token(parameterName), fieldName);
      }
      if (!insertedVariable) {
        var offset = parameter.offset;
        if (parameter is NormalFormalParameter) {
          if (parameter.requiredKeyword case var requiredKeyword?) {
            offset = requiredKeyword.end;
          }
        }
        var keyword = fieldElement.isFinal ? 'final' : 'var';
        if (offset == parameter.offset) {
          builder.addSimpleInsertion(offset, '$keyword ');
        } else {
          builder.addSimpleInsertion(offset, ' $keyword');
        }

        TypeAnnotation? type;
        if (parameter is SimpleFormalParameter) {
          type = parameter.type;
        } else if (parameter is FieldFormalParameter) {
          type = parameter.type;
        }

        if (type == null) {
          var variableList = fieldDeclaration.parent as VariableDeclarationList;
          var fieldType = variableList.type;
          if (fieldType != null) {
            builder.addSimpleInsertion(
              offset,
              ' ${utils.getNodeText(fieldType)}',
            );
          }
        }
      }

      // Remove the initializer.
      bool constructorBodyHasCommentOrMetadata = false;
      SourceRange? initializerDeletionRange;
      if (initializer != null && constructorBody != null) {
        constructorBodyHasCommentOrMetadata = _hasCommentOrMetadata(
          constructorBody,
        );
        if (constructorBody.initializers.length == 1) {
          var body = constructorBody.body;
          if (body is EmptyFunctionBody) {
            if (!constructorBodyHasCommentOrMetadata) {
              initializerDeletionRange = _getLinesRangeWithNextBlankLine(
                constructorBody,
              );
            } else {
              initializerDeletionRange = range.endStart(
                constructorBody.thisKeyword,
                body.semicolon,
              );
            }
          } else {
            initializerDeletionRange = range.startStart(
              constructorBody.colon ?? constructorBody.initializers.beginToken!,
              constructorBody.body.beginToken,
            );
          }
        } else {
          initializerDeletionRange = range.nodeInList(
            constructorBody.initializers,
            initializer,
          );
        }
      }

      // Remove the field.
      SourceRange? fieldDeletionRange;
      if (variableList.variables.length == 1) {
        fieldDeletionRange = _getLinesRangeWithNextBlankLine(
          variableList.parent!,
        );
      } else {
        fieldDeletionRange = range.nodeInList(
          variableList.variables,
          fieldDeclaration,
        );
      }

      if (initializerDeletionRange != null) {
        var fieldNode = variableList.parent!;
        var constructorNode = constructorBody!;
        var nextToken = fieldNode.endToken.next!;
        if (nextToken == constructorNode.beginToken) {
          bool deletingEntireConstructor =
              !constructorBodyHasCommentOrMetadata &&
              constructorBody.initializers.length == 1 &&
              constructorBody.body is EmptyFunctionBody;
          if (deletingEntireConstructor) {
            builder.addDeletion(
              utils.getLinesRange(range.startEnd(fieldNode, constructorNode)),
            );
            fieldDeletionRange = null;
            initializerDeletionRange = null;
          }
        }
      }

      if (initializerDeletionRange != null) {
        builder.addDeletion(initializerDeletionRange);
      }
      if (fieldDeletionRange != null) {
        builder.addDeletion(fieldDeletionRange);
      }
    });
  }

  /// Returns the primary constructor containing the [parameter].
  ///
  /// Returns `null` if the [parameter] isn't in a primary constructor.
  PrimaryConstructorDeclaration? _findPrimaryConstructor(
    FormalParameter parameter,
  ) {
    var ancestor = parameter.parent;
    if (ancestor is FormalParameter) {
      ancestor = ancestor.parent;
    }
    if (ancestor is FormalParameterList) {
      ancestor = ancestor.parent;
    }
    if (ancestor is! PrimaryConstructorDeclaration) {
      return null;
    }
    return ancestor;
  }

  List<ClassMember>? _getClassMembers(FormalParameter parameter) {
    var declaration = parameter.thisOrAncestorMatching(
      (node) => node is ClassDeclaration || node is EnumDeclaration,
    );
    return switch (declaration) {
      ClassDeclaration() => declaration.body.classMembers,
      EnumDeclaration() => declaration.body.members,
      _ => null,
    };
  }

  /// Returns the declaration of the field that declared the given [element].
  VariableDeclaration? _getDeclaration(
    List<ClassMember> classMembers,
    FieldElement element,
  ) {
    for (var member in classMembers) {
      if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          if (field.declaredFragment?.element == element) {
            return field;
          }
        }
      }
    }
    return null;
  }

  SourceRange _getLinesRangeWithNextBlankLine(AstNode node) {
    var linesRange = utils.getLinesRange(range.node(node));
    var lineInfo = unit.lineInfo;
    var nextLineOffset = linesRange.end;
    var nextLineLocation = lineInfo.getLocation(nextLineOffset);
    // getLocation returns 1-based line number.
    var nextLineIndex = nextLineLocation.lineNumber - 1;

    if (nextLineIndex < lineInfo.lineCount) {
      var nextLineStart = lineInfo.getOffsetOfLine(nextLineIndex);
      // Ensure we are strictly at the start of the next line.
      if (nextLineStart == nextLineOffset) {
        var nextLineEnd = nextLineIndex + 1 < lineInfo.lineCount
            ? lineInfo.getOffsetOfLine(nextLineIndex + 1)
            : unit.length;
        var nextLineContent = utils.getText(
          nextLineStart,
          nextLineEnd - nextLineStart,
        );
        if (nextLineContent.trim().isEmpty) {
          return SourceRange(
            linesRange.offset,
            linesRange.length + (nextLineEnd - nextLineStart),
          );
        }
      }
    }
    return linesRange;
  }

  String _getMetadataText(AnnotatedNode node) {
    // It might be better to grab all of the text in order to preserve the
    // current formatting and comments. Depends, in part, on how the formatter
    // handles wrapping primary constructor parameter lists.
    var buffer = StringBuffer();
    var docComment = node.documentationComment;
    if (docComment != null) {
      buffer.write('  ');
      buffer.writeln(utils.getNodeText(docComment));
    }
    for (var annotation in node.metadata) {
      buffer.write('  ');
      buffer.writeln(utils.getNodeText(annotation));
    }
    return buffer.toString();
  }

  _RefactorData? _getRefactorData(FormalParameter parameter) {
    var parameterElement = parameter.declaredFragment?.element;
    if (parameterElement == null) {
      // If the parameter hasn't been resolved, we woun't be able to find either
      // the existing field or the initialization of the field.
      return null;
    }

    var primaryConstructor = _findPrimaryConstructor(parameter);
    if (primaryConstructor == null) {
      // The parameter can't be converted because it isn't in a primary
      // constructor.
      return null;
    }

    FieldElement? fieldElement;
    ConstructorFieldInitializer? initializer;
    PrimaryConstructorBody? constructorBody;

    if (parameter is FieldFormalParameter) {
      if (parameterElement is FieldFormalParameterElement &&
          parameterElement.isDeclaring) {
        // The parameter is already a declaring parameter, so the assist isn't
        // necessary.
        return null;
      }
      fieldElement = parameter.declaredFragment?.element.field;
      if (fieldElement == null || fieldElement.name != parameter.name.lexeme) {
        return null;
      }
    } else if (parameter is SimpleFormalParameter) {
      var body = primaryConstructor.body;
      if (body != null) {
        for (var init in body.initializers) {
          if (init is ConstructorFieldInitializer) {
            var expression = init.expression;
            if (expression is SimpleIdentifier &&
                expression.element == parameterElement) {
              if (initializer != null) return null;
              initializer = init;
              constructorBody = body;
            }
          }
        }
      }
      if (initializer == null) {
        // The parameter is not used to initialize a field.
        return null;
      }

      if (_parameterHasOtherUses(parameter, parameterElement, initializer)) {
        // The parameter can't be converted because it's used for something
        // else.
        return null;
      }
      var fieldIdentifier = initializer.fieldName;
      var element = fieldIdentifier.element;
      if (element is! FieldElement) {
        // This shouldn't happen, but it here for promotion.
        return null;
      }
      fieldElement = element;
    } else {
      // Converting other kinds of parameters is not supported.
      return null;
    }

    if (parameterElement.type != fieldElement.type) {
      // The parameter and the field must have the same type. If they don't then
      // this assist would change the type of one or the other, and the change
      // might be difficult for users to notice.
      return null;
    }

    return (
      constructorBody: constructorBody,
      fieldElement: fieldElement,
      initializer: initializer,
    );
  }

  /// Whether the [node] has either a documentation comment or metadata.
  bool _hasCommentOrMetadata(AnnotatedNode node) {
    return node.documentationComment != null || node.metadata.isNotEmpty;
  }

  bool _parameterHasOtherUses(
    FormalParameter parameter,
    FormalParameterElement element,
    ConstructorFieldInitializer initializer,
  ) {
    var visitor = _UsageFinder(element, initializer);
    parameter.parent?.parent?.accept(visitor);
    return visitor.hasUsage;
  }
}

class _UsageFinder extends RecursiveAstVisitor<void> {
  final FormalParameterElement element;
  final ConstructorFieldInitializer initializer;
  bool hasUsage = false;

  _UsageFinder(this.element, this.initializer);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == element) {
      if (node != initializer.expression) {
        hasUsage = true;
      }
    }
  }
}
