// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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
}

/**
 * An AST visitor for [DartUnitFoldingComputer].
 */
class _DartUnitFoldingComputerVisitor extends RecursiveAstVisitor<Object> {
  final DartUnitFoldingComputer _computer;
  _DartUnitFoldingComputerVisitor(this._computer);

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    final FoldingKind kind = node.parent is ConstructorDeclaration ||
            node.parent is MethodDeclaration
        ? FoldingKind.CLASS_MEMBER
        : FoldingKind.TOP_LEVEL_DECLARATION;
    _addRegion(
        node.block.leftBracket.end, node.block.rightBracket.offset, kind);
    return super.visitBlockFunctionBody(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _addRegion(node.leftBracket.end, node.rightBracket.offset,
        FoldingKind.TOP_LEVEL_DECLARATION);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitAnnotation(Annotation node) {
    _addRegion(
        node.arguments.leftParenthesis.end,
        node.arguments.rightParenthesis.offset,
        FoldingKind.TOP_LEVEL_DECLARATION);
    return super.visitAnnotation(node);
  }

  @override
  Object visitComment(Comment node) {
    final FoldingKind kind = node.isDocumentation
        ? FoldingKind.DOCUMENTATION_COMMENT
        : FoldingKind.COMMENT;
    _addRegion(node.offset, node.end, kind);
    return super.visitComment(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _recordDirective(node);
    return super.visitExportDirective(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    _recordDirective(node);
    return super.visitImportDirective(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    _recordDirective(node);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitPartDirective(PartDirective node) {
    _recordDirective(node);
    return super.visitPartDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    _recordDirective(node);
    return super.visitPartOfDirective(node);
  }

  _addRegion(int startOffset, int endOffset, FoldingKind kind) {
    // TODO(dantup): This class is marked deprecated; find out what to change it to.
    final LineInfo_Location start =
        _computer._lineInfo.getLocation(startOffset);
    final LineInfo_Location end = _computer._lineInfo.getLocation(endOffset);

    if (start.lineNumber != end.lineNumber) {
      _computer._foldingRegions
          .add(new FoldingRegion(kind, startOffset, endOffset - startOffset));
    }
  }

  _recordDirective(Directive node) {
    _computer._firstDirective ??= node;
    _computer._lastDirective = node;
  }
}
