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

  _Directive? _firstDirective, _lastDirective;
  final List<FoldingRegion> _foldingRegions = [];

  /// A set of line numbers that already have folding regions defined.
  ///
  /// Multiple regions will not be produced that start on the same line because
  /// editors typically only show one folding action button per line.
  final _linesWithRegions = <int>{};

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
      _addRegion(
        firstDirective.keyword.end,
        lastDirective.directive.end,
        FoldingKind.DIRECTIVES,
      );
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
      // the EOF token may have preceding comments.
      if (token.isEof) {
        break;
      }
      token = token.next;
    }
  }

  /// Adds a region from [startOffset] to [endOffset] for [kind].
  ///
  /// If [startOffset] is the same line as a previous range and [fallbackStart]
  /// is provided (and not the same line), then [fallbackStart] will be used.
  void _addRegion(int startOffset, int endOffset, FoldingKind kind,
      {int? fallbackStart}) {
    var start = _lineInfo.getLocation(startOffset);
    var end = _lineInfo.getLocation(endOffset);

    // We cannot start multiple regions on the same line, so if this region
    // starts on the same line as the previous region, try the fallback start.
    //
    // This usually happens with function declarations and parameters, where we
    // want to support folding long parameter lists but also be able to fold the
    // whole declaration (parameters + body).
    if (_linesWithRegions.contains(start.lineNumber)) {
      if (fallbackStart == null) {
        return;
      }

      startOffset = fallbackStart;
      start = _lineInfo.getLocation(startOffset);

      // If it's still the same, then we don't have a usable start.
      if (_linesWithRegions.contains(start.lineNumber)) {
        return;
      }
    }

    if (end.lineNumber > start.lineNumber) {
      _foldingRegions
          .add(FoldingRegion(kind, startOffset, endOffset - startOffset));
      _linesWithRegions.add(start.lineNumber);
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

  void _recordDirective(_Directive node) {
    _firstDirective ??= node;
    _lastDirective = node;
  }
}

/// An AST visitor for [DartUnitFoldingComputer].
class _DartUnitFoldingComputerVisitor extends RecursiveAstVisitor<void> {
  final DartUnitFoldingComputer _computer;

  _DartUnitFoldingComputerVisitor(this._computer);

  @override
  void visitArgumentList(ArgumentList node) {
    _computer._addRegion(
      node.leftParenthesis.end,
      node.rightParenthesis.offset,
      FoldingKind.INVOCATION,
      fallbackStart: node.arguments.firstOrNull?.offset,
    );
    super.visitArgumentList(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _computer._addRegion(
      node.leftParenthesis.end,
      node.rightParenthesis.offset,
      FoldingKind.INVOCATION,
      fallbackStart: node.condition.offset,
    );
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _computer._addRegion(node.leftParenthesis.end, node.rightParenthesis.offset,
        FoldingKind.INVOCATION);
    super.visitAssertStatement(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(
        node.name.end, node.rightBracket.end, FoldingKind.CLASS_BODY);
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(node.name?.end ?? node.returnType.end, node.end,
        FoldingKind.FUNCTION_BODY);
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
    _computer._recordDirective(_Directive(node, node.exportKeyword));
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
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(
      node.leftBracket.end,
      node.rightBracket.offset,
      FoldingKind.CLASS_BODY,
    );
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _computer._addRegion(
      node.leftParenthesis.end,
      node.rightParenthesis.offset,
      FoldingKind.PARAMETERS,
      fallbackStart: node.parameters.firstOrNull?.offset,
    );
    super.visitFormalParameterList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    _computer._addRegion(node.name.end, node.end, FoldingKind.FUNCTION_BODY);
    super.visitFunctionDeclaration(node);
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
    _computer._recordDirective(_Directive(node, node.importKeyword));
    super.visitImportDirective(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _computer._recordDirective(_Directive(node, node.libraryKeyword));
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
    _computer._addRegion(node.name.end, node.end, FoldingKind.FUNCTION_BODY);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _computer._addRegionForAnnotations(node.metadata);
    // TODO(brianwilkerson) Define `FoldingKind.MIXIN_BODY`?
    _computer._addRegion(node.name.end, node.end, FoldingKind.CLASS_BODY);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _computer._recordDirective(_Directive(node, node.partKeyword));
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _computer._recordDirective(_Directive(node, node.partKeyword));
    super.visitPartOfDirective(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _computer._addRegion(node.leftParenthesis.end, node.rightParenthesis.offset,
        FoldingKind.LITERAL);
    super.visitRecordLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.LITERAL);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _computer._addRegion(node.colon.end, node.end, FoldingKind.BLOCK);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _computer._addRegion(node.colon.end, node.end, FoldingKind.BLOCK);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.end, FoldingKind.BLOCK);
    super.visitSwitchExpression(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _computer._addRegion(node.arrow.end, node.end, FoldingKind.BLOCK);
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _computer._addRegion(node.colon.end, node.end, FoldingKind.BLOCK);
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _computer._addRegion(
        node.leftBracket.end, node.rightBracket.end, FoldingKind.BLOCK);
    super.visitSwitchStatement(node);
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

class _Directive {
  final Directive directive;
  final Token keyword;

  _Directive(this.directive, this.keyword);
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
