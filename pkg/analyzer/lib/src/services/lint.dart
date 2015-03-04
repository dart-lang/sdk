// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lint;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/visitors.dart';

/// Implementers contribute lint warnings via the provided error [reporter].
abstract class Linter {
  /// Used to report lint warnings.
  /// NOTE: this is set by the framework before visit begins.
  ErrorReporter reporter;

  /// Return a visitor to be passed to compilation units to perform lint
  /// analysis.
  /// Lint errors are reported via this [Linter]'s error [reporter].
  AstVisitor getVisitor();
}

/// Traverses a library's worth of dart code at a time to generate lint warnings
/// over the set of sources.
///
/// See [LintCode].
class LintGenerator {

  /// A global container for contributed linters.
  static final List<Linter> LINTERS = <Linter>[];

  final Iterable<CompilationUnit> _compilationUnits;
  final AnalysisErrorListener _errorListener;
  final Iterable<Linter> _linters;

  LintGenerator(this._compilationUnits, this._errorListener,
      [Iterable<Linter> linters])
      : _linters = linters != null ? linters : LINTERS;

  void generate() {
    PerformanceStatistics.lint.makeCurrentWhile(() {
      _compilationUnits.forEach((cu) {
        if (cu.element != null) {
          _generate(cu, cu.element.source);
        }
      });
    });
  }

  void _generate(CompilationUnit unit, Source source) {
    ErrorReporter errorReporter = new ErrorReporter(_errorListener, source);
    _linters.forEach((l) => l.reporter = errorReporter);
    Iterable<AstVisitor> visitors = _linters.map((l) => l.getVisitor());
    unit.accept(new DelegatingAstVisitor(visitors.where((v) => v != null)));
  }
}
