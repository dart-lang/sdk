// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';

import 'package:scrape/scrape.dart';

/// Known cases where an "if" statement could instead be an "if" element inside
/// a list or map literal. Usually this is an optional child widget in a list
/// of children.
final _knownCollection = {'flutter/examples/layers/widgets/styled_text.dart'};

final _buildMethods = <String>[];

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('build methods')
    ..addVisitor(() => ControlFlowVisitor())
    ..runCommandLine(arguments);

  _buildMethods.shuffle();
  _buildMethods.take(100).forEach(print);
}

class ControlFlowVisitor extends ScrapeVisitor {
  final List<String> _controlFlow = [];

  @override
  void beforeVisitBuildMethod(Declaration node) {
    _controlFlow.clear();
  }

  @override
  void afterVisitBuildMethod(Declaration node) {
    if (_controlFlow.isNotEmpty) {
      _buildMethods.add(nodeToString(node));

      var hasIf = _controlFlow.any((s) => s.startsWith('if'));
      var hasConditional = _controlFlow.any((s) => s.startsWith('conditional'));

      if (hasIf && hasConditional) {
        record('build methods', 'both');
      } else if (hasIf) {
        record('build methods', 'if');
      } else {
        record('build methods', 'conditional');
      }
    } else {
      record('build methods', 'no control flow');
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    super.visitConditionalExpression(node);

    if (!isInFlutterBuildMethod) return;

    if (node.parent is NamedExpression) {
      _controlFlow.add('conditional named arg');
    } else if (node.parent is ArgumentList) {
      _controlFlow.add('conditional positional arg');
    } else if (node.parent is VariableDeclaration) {
      _controlFlow.add('conditional variable');
    } else if (node.parent is InterpolationExpression) {
      _controlFlow.add('conditional interpolation');
    } else {
      _controlFlow.add('conditional');
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    super.visitIfStatement(node);

    if (!isInFlutterBuildMethod) return;

    if (_isReturn(node.thenStatement) && _isReturn(node.elseStatement)) {
      _controlFlow.add('if return');
    } else if (_isAdd(node.thenStatement) && _isAdd(node.elseStatement)) {
      _controlFlow.add('if add');
    } else if (_knownCollection.contains(path)) {
      _controlFlow.add('if collection');
    } else {
      _controlFlow.add('if');
    }
  }

  bool _isReturn(Statement statement) {
    // Ignore empty "else" clauses.
    if (statement == null) return true;

    if (statement is ReturnStatement) return true;

    if (statement is Block && statement.statements.length == 1) {
      return _isReturn(statement.statements.first);
    }

    return false;
  }

  bool _isAdd(Statement statement) {
    // Ignore empty "else" clauses.
    if (statement == null) return true;

    if (statement is ExpressionStatement) {
      var expr = statement.expression;
      if (expr is MethodInvocation) {
        if (expr.methodName.name == 'add' || expr.methodName.name == 'addAll') {
          return true;
        }
      }
    } else if (statement is Block && statement.statements.length == 1) {
      return _isAdd(statement.statements.first);
    }

    return false;
  }
}
