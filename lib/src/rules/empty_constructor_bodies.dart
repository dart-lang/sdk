// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library empty_constructor_bodies;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/services/lint.dart';

const msg = 'DO use ; instead of {} for empty constructor bodies.';

const name = 'EmptyConstructorBodies';

class EmptyConstructorBodies extends Linter {
  @override
  AstVisitor getVisitor() => new Visitor(reporter);
}

class Visitor extends SimpleAstVisitor {
  ErrorReporter reporter;

  Visitor(this.reporter);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.body is BlockFunctionBody) {
      Block block = (node.body as BlockFunctionBody).block;
      if (block.statements.length == 0) {
        reporter.reportErrorForNode(new LintCode(name, msg), block, []);
      }
    }
  }
}
