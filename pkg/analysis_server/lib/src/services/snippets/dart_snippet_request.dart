// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/snippet_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/// The information about a request for a list of snippets within a Dart file.
class DartSnippetRequest {
  /// The analysis session that produced the elements of the request.
  final AnalysisSession analysisSession;

  /// The type provider used when resolving the compilation [unit].
  final TypeProvider typeProvider;

  /// The file resource.
  final File file;

  /// The file resource.
  final String content;

  /// The parsed, unresolved compilation unit for the [content].
  final CompilationUnit compilationUnit;

  /// The element representing the library containing the compilation [unit].
  final LibraryElement libraryElement;

  /// The path of the file snippets are being requested for.
  final String filePath;

  /// Whether [file] is in a "test" directory of its workspace package.
  final bool isInTestDirectory;

  /// The offset within the source at which snippets are being
  /// requested for.
  final int offset;

  /// The context in which the snippet request is being made.
  late final SnippetContext context;

  /// The source range that represents the region of text that should be
  /// replaced if the snippet is selected.
  late final SourceRange replacementRange;

  new({required ResolvedUnitResult unit, required this.offset})
    : analysisSession = unit.session,
      typeProvider = unit.typeProvider,
      file = unit.file,
      content = unit.content,
      compilationUnit = unit.unit,
      libraryElement = unit.libraryElement,
      filePath = unit.path,
      isInTestDirectory =
          unit is ResolvedUnitResultImpl && unit.fileState.isInTestDirectory {
    var target = CompletionTarget.forOffset(unit.unit, offset);
    context = _getContext(target);
    replacementRange = target.computeReplacementRange(
      offset,
      isDotShorthandEnabled: unit.libraryElement.featureSet.isEnabled(
        .dot_shorthands,
      ),
    );
  }

  new fromCompletionResult({
    required ResolvedForCompletionResultImpl unit,
    required this.offset,
    required this.file,
  }) : analysisSession = unit.analysisSession,
       typeProvider = unit.libraryFragment.element.typeProvider,
       content = unit.content,
       compilationUnit = unit.parsedUnit,
       libraryElement = unit.libraryFragment.element,
       filePath = unit.path,
       isInTestDirectory = unit.fileState.isInTestDirectory {
    var target = CompletionTarget.forOffset(unit.parsedUnit, offset);
    context = _getContext(target);
    replacementRange = target.computeReplacementRange(
      offset,
      isDotShorthandEnabled: unit.libraryFragment.element.featureSet.isEnabled(
        .dot_shorthands,
      ),
    );
  }

  /// The resource provider associated with this request.
  ResourceProvider get resourceProvider => analysisSession.resourceProvider;

  static SnippetContext _getContext(CompletionTarget target) {
    var entity = target.entity;
    if (entity is Token) {
      var tokenType = (entity.beforeSynthetic ?? entity).type;

      if (tokenType == TokenType.MULTI_LINE_COMMENT ||
          tokenType == TokenType.SINGLE_LINE_COMMENT) {
        return .inComment;
      }

      if (tokenType == TokenType.STRING ||
          tokenType == TokenType.STRING_INTERPOLATION_EXPRESSION ||
          tokenType == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
        return .inString;
      }
    } else if (entity is NamedArgument &&
        target.offset >= entity.name.offset &&
        target.offset <= entity.name.end) {
      return .inName;
    }

    AstNode? node = target.containingNode;
    while (node != null) {
      // For return statements, containingNode could be the return statement
      // and not the expression. If the target is after the end of the return
      // keyword, assume expression.
      if (node is ReturnStatement && target.offset > node.returnKeyword.end) {
        return .inExpression;
      }

      if (node is Comment) {
        return .inComment;
      }

      if (node is StringLiteral) {
        return .inString;
      }

      if (node is VariableDeclaration) {
        return node.isConst ? .inConstantExpression : .inExpression;
      }

      if (node is VariableDeclarationList) {
        return .inIdentifierDeclaration;
      }

      if (node is DotShorthandInvocation ||
          node is DotShorthandConstructorInvocation ||
          node is DotShorthandPropertyAccess) {
        return .inDotShorthand;
      }

      if (node is PropertyAccess ||
          node is FieldFormalParameter ||
          node is PrefixedIdentifier ||
          node is ConstructorReference) {
        return .inQualifiedMemberAccess;
      }

      if (node is InstanceCreationExpression) {
        return .inConstructorInvocation;
      }

      if (node is Block) {
        return .inBlock;
      }

      if (node is Statement) {
        return .inStatement;
      }

      // SwitchExpression outside of SwitchExpressionCase is a pattern.
      if (node is SwitchExpression) {
        return .inPattern;
      }

      if (node is Expression) {
        return node.inConstantContext ? .inConstantExpression : .inExpression;
      }

      if (node is Annotation) {
        return .inAnnotation;
      }

      if (node is BlockFunctionBody) {
        return .inBlock;
      }

      if (node is BlockClassBody) {
        return .inClassBody;
      }

      if (node is ClassDeclaration ||
          node is ExtensionDeclaration ||
          node is MixinDeclaration) {
        return .inClassDeclaration;
      }

      if (node is EnumConstantArguments) {
        return .inConstantExpression;
      }

      if (node is EnumDeclaration) {
        var semicolon = switch (node.body) {
          BlockEnumBody body => body.semicolon,
          EmptyEnumBody body => body.semicolon,
        };
        return semicolon == null || target.offset <= semicolon.offset
            ? .inEnumConstants
            : .inEnumMembers;
      }

      node = node.parent;
    }

    return .atTopLevel;
  }
}
