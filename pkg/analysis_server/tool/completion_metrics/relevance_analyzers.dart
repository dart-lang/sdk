// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'metrics_util.dart';
import 'visitors.dart';

/// Concrete instances of [RelevanceAnalyzer]s are intended to assist in the
/// collection of data around the best relevances for completions in specific
/// locations in the AST.  Concrete classes override [isApplicable], which
/// accepts an [ExpectedCompletion], the objects created by
/// [ExpectedCompletionsVisitor], as well as a [DartCompletionRequest], the same
/// object used in the [DartCompletionManager] to identify which completions and
/// relevances a user should see when using code completion.
abstract class RelevanceAnalyzer {
  final String _name;
  final Counter _counter;

  RelevanceAnalyzer(this._name)
      : _counter = Counter('$_name element kind counter');

  String get name => _name;

  void clear() => _counter.clear();

  bool isApplicable(ExpectedCompletion expectedCompletion,
      DartCompletionRequest dartCompletionRequest);

  void printData() {
    _counter.printCounterValues();
    print('');
  }

  void report(ExpectedCompletion expectedCompletion,
      DartCompletionRequest dartCompletionRequest) {
    if (isApplicable(expectedCompletion, dartCompletionRequest)) {
      _counter.count(expectedCompletion.elementKind.toString());
    }
  }
}

/// This [RelevanceAnalyzer] gathers data on the right hand side of an
/// [AsExpression].
class RHSOfAsExpression extends RelevanceAnalyzer {
  RHSOfAsExpression() : super('RHS Of AsExpression');

  @override
  bool isApplicable(ExpectedCompletion expectedCompletion,
      DartCompletionRequest dartCompletionRequest) {
    var entity = expectedCompletion.syntacticEntity;
    if (entity is AstNode) {
      var asExpression = entity.thisOrAncestorOfType<AsExpression>();
      if (asExpression != null) {
        var typeAnnotation = asExpression.type;
        if (typeAnnotation is TypeName) {
          return typeAnnotation.name == entity;
        }
      }
    }
    return false;
  }
}
