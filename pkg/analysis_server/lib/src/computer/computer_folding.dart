// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * A computer for [CompilationUnit] folding.
 */
class DartUnitFoldingComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;

  Directive _firstDirective, _lastDirective;
  final List<FoldingRegion> _foldingRegions = [];

  DartUnitFoldingComputer(this._lineInfo, this._unit);

  /**
   * Returns a list of folding regions, not `null`.
   */
  List<FoldingRegion> compute() {
    _addFileHeaderRegion();
    _unit.accept(new _DartUnitFoldingComputerVisitor(this));

    if (_firstDirective != null &&
        _lastDirective != null &&
        _firstDirective != _lastDirective) {
      _foldingRegions.add(new FoldingRegion(
          FoldingKind.DIRECTIVES,
          _firstDirective.keyword.end,
          _lastDirective.end - _firstDirective.keyword.end));
    }

    return _foldingRegions;
  }

  void _addFileHeaderRegion() {
    Token firstToken = _unit.beginToken;
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
    Token lastComment = firstComment;
    while (lastComment.next != null) {
      lastComment = lastComment.next;

      // If we ran out of tokens, use the original token as starting position.
      final hasBlankLine =
          _hasBlankLineBetween(lastComment, lastComment.next ?? firstToken);

      // Also considerd non-single-line-comments as the end
      final nextCommentIsDifferentType = lastComment.next != null &&
          lastComment.next.type != TokenType.SINGLE_LINE_COMMENT;

      if (hasBlankLine || nextCommentIsDifferentType) {
        _addRegion(firstComment.end, lastComment.end, FoldingKind.FILE_HEADER);
        break;
      }
    }
  }

  _addRegion(int startOffset, int endOffset, FoldingKind kind) {
    final CharacterLocation start = _lineInfo.getLocation(startOffset);
    final CharacterLocation end = _lineInfo.getLocation(endOffset);

    if (start.lineNumber != end.lineNumber) {
      _foldingRegions
          .add(new FoldingRegion(kind, startOffset, endOffset - startOffset));
    }
  }

  _addRegionForAnnotations(List<Annotation> annotations) {
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

  _recordDirective(Directive node) {
    _firstDirective ??= node;
    _lastDirective = node;
  }
}

/**
 * An AST visitor for [DartUnitFoldingComputer].
 */
class _DartUnitFoldingComputerVisitor extends RecursiveAstVisitor<Object> {
  final DartUnitFoldingComputer _computer;
  _DartUnitFoldingComputerVisitor(this._computer);

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    _computer._addRegion(node.block.leftBracket.end,
        node.block.rightBracket.offset, FoldingKind.FUNCTION_BODY);
    return super.visitBlockFunctionBody(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.CLASS_BODY);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitComment(Comment node) {
    if (node.isDocumentation) {
      _computer._addRegion(
          node.offset, node.end, FoldingKind.DOCUMENTATION_COMMENT);
    }
    return super.visitComment(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _computer._recordDirective(node);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    return super.visitFunctionDeclaration(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    _computer._recordDirective(node);
    return super.visitImportDirective(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    _computer._recordDirective(node);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    _computer._recordDirective(node);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    _computer._recordDirective(node);
    return super.visitPartOfDirective(node);
  }
}
