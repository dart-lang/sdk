// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A computer for [CompilationUnit] folding.
class DartUnitFoldingComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;

  Directive _firstDirective, _lastDirective;
  final List<FoldingRegion> _foldingRegions = [];

  DartUnitFoldingComputer(this._lineInfo, this._unit);

  void addRegionForConditionalBlock(Block block) {
    // For class/function/method blocks, we usually include the whitespace up
    // until the `}` in the folding region so that when collapsed they would
    // look like:
    //
    //    class Foo { [...] }
    //
    // For if statements, they may have else/elseIfs which would result in long
    // lines like:
    //
    //     if (cond) { [...] } else { [...] }
    //
    // So these types of blocks should have their folding regions end at the
    // end of the preceeding statement.

    final start = block.leftBracket.end;
    if (block.endToken.precedingComments != null) {
      // If there are comments before the end token, use the last of those.
      var lastComment = block.endToken.precedingComments;
      while (lastComment.next != null) {
        lastComment = lastComment.next;
      }
      _addRegion(start, lastComment.end, FoldingKind.BLOCK);
    } else if (block.statements.isNotEmpty) {
      // Otherwise, use the end of the last statement.
      _addRegion(start, block.statements.last.end, FoldingKind.BLOCK);
    }
  }

  /// Returns a list of folding regions, not `null`.
  List<FoldingRegion> compute() {
    _addFileHeaderRegion();
    _unit.accept(_DartUnitFoldingComputerVisitor(this));

    if (_firstDirective != null &&
        _lastDirective != null &&
        _firstDirective != _lastDirective) {
      _foldingRegions.add(FoldingRegion(
          FoldingKind.DIRECTIVES,
          _firstDirective.keyword.end,
          _lastDirective.end - _firstDirective.keyword.end));
    }

    return _foldingRegions;
  }

  void _addFileHeaderRegion() {
    var firstToken = _unit.beginToken;
    while (firstToken?.type == TokenType.SCRIPT_TAG) {
      firstToken = firstToken.next;
    }

    final Token firstComment = firstToken?.precedingComments;
    if (firstComment == null ||
        firstComment.type != TokenType.SINGLE_LINE_COMMENT) {
      return;
    }

    // Walk through the comments looking for a blank line to signal the end of
    // the file header.
    var lastComment = firstComment;
    while (lastComment.next != null) {
      lastComment = lastComment.next;

      // If we ran out of tokens, use the original token as starting position.
      final hasBlankLine =
          _hasBlankLineBetween(lastComment, lastComment.next ?? firstToken);

      // Also considered non-single-line-comments as the end
      final nextCommentIsDifferentType = lastComment.next != null &&
          lastComment.next.type != TokenType.SINGLE_LINE_COMMENT;

      if (hasBlankLine || nextCommentIsDifferentType) {
        _addRegion(firstComment.end, lastComment.end, FoldingKind.FILE_HEADER);
        break;
      }
    }
  }

  void _addRegion(int startOffset, int endOffset, FoldingKind kind) {
    final CharacterLocation start = _lineInfo.getLocation(startOffset);
    final CharacterLocation end = _lineInfo.getLocation(endOffset);

    if (start.lineNumber != end.lineNumber) {
      _foldingRegions
          .add(FoldingRegion(kind, startOffset, endOffset - startOffset));
    }
  }

  void _addRegionForAnnotations(List<Annotation> annotations) {
    if (annotations.isNotEmpty) {
      _addRegion(annotations.first.name.end, annotations.last.end,
          FoldingKind.ANNOTATIONS);
    }
  }

  bool _hasBlankLineBetween(Token first, Token second) {
    final CharacterLocation firstLoc = _lineInfo.getLocation(first.end);
    final CharacterLocation secondLoc = _lineInfo.getLocation(second.offset);
    return secondLoc.lineNumber - firstLoc.lineNumber > 1;
  }

  void _recordDirective(Directive node) {
    _firstDirective ??= node;
    _lastDirective = node;
  }
}

/// An AST visitor for [DartUnitFoldingComputer].
class _DartUnitFoldingComputerVisitor extends RecursiveAstVisitor<void> {
  final DartUnitFoldingComputer _computer;

  _DartUnitFoldingComputerVisitor(this._computer);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _computer._addRegion(node.leftParenthesis.end, node.rightParenthesis.offset,
        FoldingKind.INVOCATION);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _computer._addRegion(node.leftParenthesis.end, node.rightParenthesis.offset,
        FoldingKind.INVOCATION);
    super.visitAssertStatement(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _computer._addRegion(node.block.leftBracket.end,
        node.block.rightBracket.offset, FoldingKind.FUNCTION_BODY);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.CLASS_BODY);
    super.visitClassDeclaration(node);
  }

  @override
  void visitComment(Comment node) {
    if (node.isDocumentation) {
      _computer._addRegion(
          node.offset, node.end, FoldingKind.DOCUMENTATION_COMMENT);
    }
    super.visitComment(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    if (node.body is Block) {
      _computer.addRegionForConditionalBlock(node.body);
    }
    super.visitDoStatement(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _computer._recordDirective(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.CLASS_BODY);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _computer._addRegion(node.argumentList.leftParenthesis.end,
        node.argumentList.rightParenthesis.offset, FoldingKind.INVOCATION);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (node.thenStatement is Block) {
      _computer.addRegionForConditionalBlock(node.thenStatement);
    }
    if (node.elseStatement is Block) {
      _computer.addRegionForConditionalBlock(node.elseStatement);
    }
    super.visitIfStatement(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _computer._recordDirective(node);
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _computer._addRegion(node.argumentList.leftParenthesis.end,
        node.argumentList.rightParenthesis.offset, FoldingKind.INVOCATION);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _computer._recordDirective(node);
    super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.LITERAL);
    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _computer._addRegion(node.argumentList.leftParenthesis.end,
        node.argumentList.rightParenthesis.offset, FoldingKind.INVOCATION);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    // TODO(brianwilkerson) Define `FoldingKind.MIXIN_BODY`?
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.CLASS_BODY);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _computer._recordDirective(node);
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _computer._recordDirective(node);
    super.visitPartOfDirective(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.LITERAL);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    if (node.body is Block) {
      _computer.addRegionForConditionalBlock(node.body);
    }
    super.visitWhileStatement(node);
  }
}
