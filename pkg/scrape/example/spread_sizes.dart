// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';

import 'package:scrape/scrape.dart';

/// Looks at expressions that could likely be converted to spread operators and
/// measures their length. "Likely" means calls to `addAll()` where the
/// receiver is a list or map literal.
void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Arguments')
    ..addHistogram('Lengths', order: SortOrder.numeric)
    ..addVisitor(() => SpreadVisitor())
    ..runCommandLine(arguments);
}

class SpreadVisitor extends ScrapeVisitor {
  @override
  void visitCascadeExpression(CascadeExpression node) {
    for (var section in node.cascadeSections) {
      if (section is MethodInvocation) {
        _countCall(node, section.methodName, node.target, section.argumentList);
      }
    }

    super.visitCascadeExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _countCall(node, node.methodName, node.target, node.argumentList);
    super.visitMethodInvocation(node);
  }

  void _countCall(Expression node, SimpleIdentifier name, Expression target,
      ArgumentList args) {
    if (name.name != 'addAll') return;

    // See if the target is a collection literal.
    while (target is MethodInvocation) {
      target = (target as MethodInvocation).target;
    }

    if (target is ListLiteral || target is SetOrMapLiteral) {
      if (args.arguments.length == 1) {
        var arg = args.arguments[0];
        record('Arguments', arg.toString());
        record('Lengths', arg.length);
      }

      printNode(node);
    }
  }
}
