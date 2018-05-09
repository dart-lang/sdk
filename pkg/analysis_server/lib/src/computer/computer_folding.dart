// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * A computer for [CompilationUnit] folding.
 */
class DartUnitFoldingComputer {
  final CompilationUnit _unit;

  Directive _firstDirective, _lastDirective;
  final List<FoldingRegion> _foldingRegions = [];

  DartUnitFoldingComputer(this._unit);

  /**
   * Returns a list of folding regions, not `null`.
   */
  List<FoldingRegion> compute() {
    _unit.accept(new _DartUnitFoldingComputerVisitor(this));

    if (_firstDirective != null &&
        _lastDirective != null &&
        _firstDirective != _lastDirective) {
      _foldingRegions.add(new FoldingRegion(FoldingKind.DIRECTIVES,
          _firstDirective.offset, _lastDirective.end - _firstDirective.offset));
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
  visitImportDirective(ImportDirective node) {
    if (_computer._firstDirective == null) {
      _computer._firstDirective = node;
    }
    _computer._lastDirective = node;
    return super.visitImportDirective(node);
  }
}
