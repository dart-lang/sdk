// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import 'metrics_util.dart';
import 'visitors.dart';

abstract class RelevanceAnalyzer {
  final String _name;
  final Counter _counter;

  RelevanceAnalyzer(this._name)
      : _counter = Counter('$_name element kind counter');

  String get name => _name;

  void clear() => _counter.clear();

  bool isApplicable(ExpectedCompletion expectedCompletion);

  void printData() {
    _counter.printCounterValues();
  }

  void report(ExpectedCompletion expectedCompletion) {
    if (isApplicable(expectedCompletion)) {
      _counter.count(expectedCompletion.elementKind.toString());
    }
  }
}

class RHSOfAsExpression extends RelevanceAnalyzer {
  RHSOfAsExpression() : super('RHS Of AsExpression');

  @override
  bool isApplicable(ExpectedCompletion expectedCompletion) {
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
