// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

typedef _RefactorData = ({
  FieldElement fieldElement,
  ConstructorFieldInitializer? initializer,
  PrimaryConstructorBody? constructorBody,
});

class ConvertToDeclaringParameter extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind? get assistKind => DartAssistKind.convertToDeclaringParameter;

  @override
  FixKind? get fixKind => DartFixKind.convertToDeclaringParameter;

  @override
  FixKind? get multiFixKind => DartFixKind.convertToDeclaringParameterMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    FormalParameter parameter;
    var n = node;
    if (n is FormalParameter) {
      var parameterName = n.name;
      if (parameterName == null) {
        // The assist only applies to formal parameters with a name.
        return;
      }

      var inName = parameterName.sourceRange.contains(selectionOffset);
      var inThisPrefix =
          n is FieldFormalParameter &&
          range.startEnd(n.thisKeyword, n.period).contains(selectionOffset);
      if (!inName && !inThisPrefix) {
        // The assist only applies if the name or the `this.` prefix of the
        // parameter is selected.
        return;
      }
      parameter = n;
    } else {
      var resolved = _resolveParameterFromFieldNode(n);
      if (resolved == null) return;
      parameter = resolved;
    }

    var parameterName = parameter.name;
    if (parameterName == null) return;

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

    // If the field has an initializer it must be a constant expression.
    // TODO(brianwilkerson): Handle the case where the initializer is a valid
    //  constant expression and can be moved to the parameter.
    if (fieldDeclaration.initializer != null) return;

    var parameterElement = parameter.declaredFragment?.element;
    if (parameterElement == null) return;

    var references = findParameterReferences(
      parameterElement: parameterElement,
      constructorBody: constructorBody?.body,
      initializers: constructorBody?.initializers,
      nodesBeingRemoved: [?initializer],
    );

    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;

      // Move metadata and/or doc comments.
      var variableList = fieldDeclaration.parent as VariableDeclarationList;
      var member = variableList.parent;
      if (member is FieldDeclaration) {
        var metadata = member.metadata;
        var docComment = member.documentationComment;
        if (metadata.isNotEmpty || docComment != null) {
          var text = _getMetadataText(member);
          var prefix =
              // Insert a newline/indent if there is metadata and this parameter
              // is not already the first thing on the line.
              text.isNotEmpty &&
                  utils.getLineContentStart(parameter.offset) !=
                      utils.getLineThis(parameter.offset)
              ? '$eol  '
              : '';
          var suffix = '$eol  ';

          builder.addSimpleInsertion(parameter.offset, '$prefix$text$suffix');
        }
      }

      // Insert the keyword, and a type if the parameter didn't already have a
      // type.
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
      // Rename the parameter if it's different than the name of the field.
      if (fieldName != parameterName.lexeme) {
        builder.addSimpleReplacement(range.token(parameterName), fieldName);
        for (var reference in references) {
          builder.addSimpleReplacement(range.node(reference), fieldName);
        }
      }
      if (!insertedVariable) {
        var offset = parameterName.offset;
        if (parameter.type case var type?) {
          offset = type.offset;
        } else if (parameter is FieldFormalParameter) {
          offset = parameter.thisKeyword.offset;
        }

        var keyword = fieldElement.isFinal ? 'final' : 'var';
        var requiredKeyword = parameter.requiredKeyword;
        if (requiredKeyword != null) {
          offset = requiredKeyword.end;
          builder.addSimpleInsertion(offset, ' $keyword');
        } else {
          builder.addSimpleInsertion(offset, '$keyword ');
        }

        var type = parameter.type;

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
      ClassDeclaration() => declaration.body.members,
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

  /// Gets the metadata text without any leading/trailing newlines/whitespace.
  String _getMetadataText(AnnotatedNode node) {
    var docComment = node.documentationComment;
    var metadata = node.metadata.isNotEmpty
        ? (
            offset: node.metadata.beginToken!.offset,
            end: node.metadata.endToken!.end,
          )
        : null;

    if (docComment == null && metadata == null) {
      return '';
    }

    int start, end;
    if (docComment != null && metadata != null) {
      // Handle doc comments / metadata in any order.
      start = math.min(docComment.offset, metadata.offset);
      end = math.max(docComment.end, metadata.end);
    } else if (docComment != null) {
      start = docComment.offset;
      end = docComment.end;
    } else {
      start = metadata!.offset;
      end = metadata.end;
    }

    return utils.getText(start, end - start);
  }

  _RefactorData? _getRefactorData(FormalParameter parameter) {
    if (parameter.functionTypedSuffix != null) {
      return null;
    }

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
      var element = parameter.declaredFragment?.element;
      if (element is FieldFormalParameterElement) {
        fieldElement = element.field;
      }
      if (fieldElement == null || fieldElement.name != parameter.name.lexeme) {
        return null;
      }
    } else if (parameter is RegularFormalParameter) {
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

  /// Returns the primary constructor parameter that initializes the field
  /// declared by [node], or `null` if no such parameter exists.
  FormalParameter? _resolveParameterFromFieldNode(AstNode node) {
    if (node is! VariableDeclaration) return null;

    var variableList = node.parent;
    if (variableList is! VariableDeclarationList) return null;

    if (variableList.parent is! FieldDeclaration) return null;

    var classOrEnum = node.thisOrAncestorMatching(
      (n) => n is ClassDeclaration || n is EnumDeclaration,
    );

    var primaryConstructor = switch (classOrEnum) {
      ClassDeclaration() => classOrEnum.namePart,
      EnumDeclaration() => classOrEnum.namePart,
      _ => null,
    };
    if (primaryConstructor is! PrimaryConstructorDeclaration) return null;

    var fieldElement = node.declaredFragment?.element;
    if (fieldElement is! FieldElement) return null;

    for (var parameter in primaryConstructor.formalParameters.parameters) {
      if (parameter is FieldFormalParameter) {
        var element = parameter.declaredFragment?.element;
        if (element is FieldFormalParameterElement &&
            element.field == fieldElement) {
          return parameter;
        }
      } else if (parameter is RegularFormalParameter) {
        var paramElement = parameter.declaredFragment?.element;
        if (paramElement == null) continue;
        var body = primaryConstructor.body;
        if (body == null) continue;
        for (var init in body.initializers) {
          if (init is ConstructorFieldInitializer) {
            var expression = init.expression;
            if (init.fieldName.element == fieldElement &&
                expression is SimpleIdentifier &&
                expression.element == paramElement) {
              return parameter;
            }
          }
        }
      }
    }
    return null;
  }
}
