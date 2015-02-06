// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library super_goes_last;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/services/lint.dart';

const msg =
    'DO place the super() call last in a constructor initialization list.';

const name = 'SuperGoesLast';

class SuperGoesLast extends Linter {
  @override
  AstVisitor getVisitor() => new Visitor(reporter);
}

class Visitor extends SimpleAstVisitor {
  ErrorReporter reporter;

  Visitor(this.reporter);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    var last = node.initializers.length - 1;

    for (int i = 0; i <= last; ++i) {
      ConstructorInitializer init = node.initializers[i];
      if (init is SuperConstructorInvocation && i != last) {
        reporter.reportErrorForNode(new LintCode(name, msg), init, []);
      }
    }
  }
}
