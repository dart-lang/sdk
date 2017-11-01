// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc =
    r'Place the `super` call last in a constructor initialization list.';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

**DO** place the `super` call last in a constructor initialization list.

Field initializers are evaluated in the order that they appear in the
constructor initialization list.  If you place a `super()` call in the middle of
an initializer list, the superclass's initializers will be evaluated right then
before evaluating the rest of the subclass's initializers.

What it doesn't mean is that the superclass's constructor body will be executed
then.  That always happens after all initializers are run regardless of where
`super` appears.  It's vanishingly rare that the order of initializers matters,
so the placement of `super` in the list almost never matters either.

Getting in the habit of placing it last improves consistency, visually
reinforces when the superclass's constructor body is run, and may help
performance.

**GOOD:**
```
View(Style style, List children)
    : _children = children,
      super(style) {
```

**BAD:**
```
View(Style style, List children)
    : super(style),
      _children = children {
```

''';

class SuperGoesLast extends LintRule {
  SuperGoesLast()
      : super(
            name: 'super_goes_last',
            description: _desc,
            details: _details,
            group: Group.style);

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
      var init = node.initializers[i];
      if (init is SuperConstructorInvocation && i != last) {
        rule.reportLint(init);
      }
    }
  }
}
