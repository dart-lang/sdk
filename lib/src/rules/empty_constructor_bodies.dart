// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library empty_constructor_bodies;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:dart_lint/src/linter.dart';

const desc = 'DO use ; instead of {} for empty constructor bodies.';

class EmptyConstructorBodies extends LintRule {

  EmptyConstructorBodies()
      : super(
          name: 'EmptyConstructorBodies',
          description: desc,
          group: Group.STYLE_GUIDE,
          kind: Kind.DO);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;

  Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.body is BlockFunctionBody) {
      Block block = (node.body as BlockFunctionBody).block;
      if (block.statements.length == 0) {
        rule.reporter.reportErrorForNode(
            new LintCode(rule.name.value, rule.description),
            block,
            []);
      }
    }
  }
}
