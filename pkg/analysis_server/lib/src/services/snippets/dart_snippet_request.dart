// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/// The information about a request for a list of snippets within a Dart file.
class DartSnippetRequest {
  /// The resolved unit for the file that snippets are being requested for.
  final ResolvedUnitResult unit;

  /// The path of the file snippets are being requested for.
  final String filePath;

  /// The offset within the source at which snippets are being
  /// requested for.
  final int offset;

  /// The context in which the snippet request is being made.
  late final SnippetContext context;

  /// The source range that represents the region of text that should be
  /// replaced if the snippet is selected.
  late final SourceRange replacementRange;

  DartSnippetRequest({
    required this.unit,
    required this.offset,
  }) : filePath = unit.path {
    final target = CompletionTarget.forOffset(unit.unit, offset);
    context = _getContext(target);
    replacementRange = target.computeReplacementRange(offset);
  }

  /// The analysis session that produced the elements of the request.
  AnalysisSession get analysisSession => unit.session;

  /// The resource provider associated with this request.
  ResourceProvider get resourceProvider => analysisSession.resourceProvider;

  static SnippetContext _getContext(CompletionTarget target) {
    final entity = target.entity;
    if (entity is Token) {
      final tokenType = (entity.beforeSynthetic ?? entity).type;

      if (tokenType == TokenType.MULTI_LINE_COMMENT ||
          tokenType == TokenType.SINGLE_LINE_COMMENT) {
        return SnippetContext.inComment;
      }

      if (tokenType == TokenType.STRING ||
          tokenType == TokenType.STRING_INTERPOLATION_EXPRESSION ||
          tokenType == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
        return SnippetContext.inString;
      }
    }

    AstNode? node = target.containingNode;
    while (node != null) {
      if (node is Comment) {
        return SnippetContext.inComment;
      }

      if (node is StringLiteral) {
        return SnippetContext.inString;
      }

      if (node is VariableDeclaration) {
        return SnippetContext.inExpression;
      }

      if (node is VariableDeclarationList) {
        return SnippetContext.inIdentifierDeclaration;
      }

      if (node is PropertyAccess) {
        return SnippetContext.inQualifiedMemberAccess;
      }

      if (node is InstanceCreationExpression) {
        return SnippetContext.inConstructorInvocation;
      }

      if (node is Block) {
        return SnippetContext.inBlock;
      }

      if (node is Statement) {
        return SnippetContext.inStatement;
      }

      // SwitchExpression outside of SwitchExpressionCase is a pattern.
      if (node is SwitchExpression) {
        return SnippetContext.inPattern;
      }

      if (node is Expression) {
        return SnippetContext.inExpression;
      }

      if (node is Annotation) {
        return SnippetContext.inAnnotation;
      }

      if (node is BlockFunctionBody) {
        return SnippetContext.inBlock;
      }

      if (node is ClassDeclaration ||
          node is ExtensionDeclaration ||
          node is MixinDeclaration ||
          node is EnumDeclaration) {
        return SnippetContext.inClass;
      }

      node = node.parent;
    }

    return SnippetContext.atTopLevel;
  }
}
