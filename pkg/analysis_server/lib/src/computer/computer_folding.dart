// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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
    _addRegion(node.block.leftBracket.end, node.block.rightBracket.offset,
        FoldingKind.FUNCTION_BODY);
    return super.visitBlockFunctionBody(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _addRegionForAnnotations(node.metadata);
    _addRegion(
        node.leftBracket.end, node.rightBracket.offset, FoldingKind.CLASS_BODY);
    return super.visitClassDeclaration(node);
  }

  @override
  Object visitComment(Comment node) {
    if (node.isDocumentation) {
      _addRegion(node.offset, node.end, FoldingKind.DOCUMENTATION_COMMENT);
    }
    return super.visitComment(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _addRegionForAnnotations(node.metadata);
    return super.visitConstructorDeclaration(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _recordDirective(node);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _addRegionForAnnotations(node.metadata);
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    _addRegionForAnnotations(node.metadata);
    return super.visitFunctionDeclaration(node);
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
  Object visitMethodDeclaration(MethodDeclaration node) {
    _addRegionForAnnotations(node.metadata);
    return super.visitMethodDeclaration(node);
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
    final CharacterLocation start =
        _computer._lineInfo.getLocation(startOffset);
    final CharacterLocation end = _computer._lineInfo.getLocation(endOffset);

    if (start.lineNumber != end.lineNumber) {
      _computer._foldingRegions
          .add(new FoldingRegion(kind, startOffset, endOffset - startOffset));
    }
  }

  _addRegionForAnnotations(List<Annotation> annotations) {
    if (annotations.isNotEmpty) {
      _addRegion(annotations.first.name.end, annotations.last.end,
          FoldingKind.ANNOTATIONS);
    }
  }

  _recordDirective(Directive node) {
    _computer._firstDirective ??= node;
    _computer._lastDirective = node;
  }
}
