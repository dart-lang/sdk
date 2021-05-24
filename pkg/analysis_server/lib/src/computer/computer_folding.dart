// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A computer for [CompilationUnit] folding.
class DartUnitFoldingComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;

  Directive? _firstDirective, _lastDirective;
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
    // end of the preceding statement.

    final start = block.leftBracket.end;
    Token? comment = block.endToken.precedingComments;
    if (comment != null) {
      var lastComment = comment;
      // If there are comments before the end token, use the last of those.
      var nextComment = lastComment.next;
      while (nextComment != null) {
        lastComment = nextComment;
        nextComment = nextComment.next;
      }
      _addRegion(start, lastComment.end, FoldingKind.BLOCK);
    } else if (block.statements.isNotEmpty) {
      // Otherwise, use the end of the last statement.
      _addRegion(start, block.statements.last.end, FoldingKind.BLOCK);
    }
  }

  /// Returns a list of folding regions, not `null`.
  List<FoldingRegion> compute() {
    _unit.accept(_DartUnitFoldingComputerVisitor(this));

    var firstDirective = _firstDirective;
    var lastDirective = _lastDirective;
    if (firstDirective != null &&
        lastDirective != null &&
        firstDirective != lastDirective) {
      _foldingRegions.add(FoldingRegion(
          FoldingKind.DIRECTIVES,
          firstDirective.keyword.end,
          lastDirective.end - firstDirective.keyword.end));
    }

    _addCommentRegions();

    return _foldingRegions;
  }

  /// Create a folding region for the provided comment, reading forwards if
  /// necessary.
  ///
  /// If [mayBeFileHeader] is true, the token will be considered a file header
  /// if comment is a single-line-comment and there is a blank line or another
  /// comment type after it.
  ///
  /// Returns the next comment to be processed or null if there are no more
  /// comments to process in the chain.
  Token? _addCommentRegion(Token commentToken, {bool mayBeFileHeader = false}) {
    int offset, end;
    var isFileHeader = false;
    Token? nextComment;

    if (commentToken.type == TokenType.MULTI_LINE_COMMENT) {
      // Multiline comments already span all of their lines but the folding
      // region should start at the end of the first line.
      offset = commentToken.offset + (commentToken.eolOffset ?? 0);
      end = commentToken.end;
      nextComment = commentToken.next;
    } else {
      // Single line comments need grouping together explicitly but should
      // only group if the prefix is the same and up to any blank line.
      final isTripleSlash = commentToken.isTripleSlash;
      // Track the last comment that belongs to this folding region.
      var lastComment = commentToken;
      var current = lastComment.next;
      while (current != null &&
          current.type == lastComment.type &&
          current.isTripleSlash == isTripleSlash &&
          !_hasBlankLineBetween(lastComment.end, current.offset)) {
        lastComment = current;
        current = current.next;
      }

      // For single line comments we prefer to start the range at the end of
      // first token so the first line is still visible when the range is
      // collapsed.
      offset = commentToken.end;
      end = lastComment.end;
      nextComment = lastComment.next;

      // Single line comments are file headers if they're followed by a different
      // comment type of there's a blank line between them and the first token.
      isFileHeader = mayBeFileHeader &&
          (nextComment != null ||
              _hasBlankLineBetween(end, _unit.beginToken.offset));
    }

    final kind = isFileHeader
        ? FoldingKind.FILE_HEADER
        : (commentToken.lexeme.startsWith('///') ||
                commentToken.lexeme.startsWith('/**'))
            ? FoldingKind.DOCUMENTATION_COMMENT
            : FoldingKind.COMMENT;

    _addRegion(offset, end, kind);

    return nextComment;
  }

  void _addCommentRegions() {
    Token? token = _unit.beginToken;
    if (token.type == TokenType.SCRIPT_TAG) {
      token = token.next;
    }
    var isFirstToken = true;
    while (token != null) {
      Token? commentToken = token.precedingComments;
      while (commentToken != null) {
        commentToken =
            _addCommentRegion(commentToken, mayBeFileHeader: isFirstToken);
      }
      isFirstToken = false;
      // Only exit the loop when hitting EOF *after* processing the token as
      // the EOF token may have preceeding comments.
      if (token.type == TokenType.EOF) {
        break;
      }
      token = token.next;
    }
  }

  void _addRegion(int startOffset, int endOffset, FoldingKind kind) {
    var start = _lineInfo.getLocation(startOffset);
    var end = _lineInfo.getLocation(endOffset);

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

  bool _hasBlankLineBetween(int offset, int end) {
    var firstLoc = _lineInfo.getLocation(offset);
    var secondLoc = _lineInfo.getLocation(end);
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
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    var body = node.body;
    if (body is Block) {
      _computer.addRegionForConditionalBlock(body);
    }
    super.visitDoStatement(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.CLASS_BODY);
    super.visitEnumDeclaration(node);
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
  void visitFormalParameterList(FormalParameterList node) {
    _computer._addRegion(node.leftParenthesis.end, node.rightParenthesis.offset,
        FoldingKind.PARAMETERS);
    super.visitFormalParameterList(node);
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
    var thenStatement = node.thenStatement;
    if (thenStatement is Block) {
      _computer.addRegionForConditionalBlock(thenStatement);
    }
    var elseStatement = node.elseStatement;
    if (elseStatement is Block) {
      _computer.addRegionForConditionalBlock(elseStatement);
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
    var body = node.body;
    if (body is Block) {
      _computer.addRegionForConditionalBlock(body);
    }
    super.visitWhileStatement(node);
  }
}

extension _CommentTokenExtensions on Token {
  static final _newlinePattern = RegExp(r'[\r\n]');

  /// Return the offset of the first eol character or `null` if no newlines were
  /// found.
  int? get eolOffset {
    final offset = lexeme.indexOf(_newlinePattern);
    return offset != -1 ? offset : null;
  }

  /// Return `true` if this comment is a triple-slash single line comment.
  bool get isTripleSlash => lexeme.startsWith('///');
}
