// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library super_goes_last;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:dart_lint/src/linter.dart';

const desc =
    'DO place the super() call last in a constructor initialization list.';

class SuperGoesLast extends LintRule {

  SuperGoesLast()
      : super(
          name: 'SuperGoesLast',
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
    var last = node.initializers.length - 1;

    for (int i = 0; i <= last; ++i) {
      ConstructorInitializer init = node.initializers[i];
      if (init is SuperConstructorInvocation && i != last) {
        rule.reporter.reportErrorForNode(new LintCode(rule.name.value, rule.description), init, []);
      }
    }
  }
}
