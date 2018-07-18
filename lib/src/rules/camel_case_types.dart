// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/utils.dart';

const _desc = r'Name types using UpperCamelCase.';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

**DO** name types using UpperCamelCase.

Classes and typedefs should capitalize the first letter of each word (including
the first word), and use no separators.

**GOOD:**
```
class SliderMenu {
  // ...
}

class HttpRequest {
  // ...
}

typedef num Adder(num x, num y);
```

''';

class CamelCaseTypes extends LintRule implements NodeLintRule {
  CamelCaseTypes()
      : super(
            name: 'camel_case_types',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!isCamelCase(node.name.toString())) {
      rule.reportLint(node.name);
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isCamelCase(node.name.toString())) {
      rule.reportLint(node.name);
    }
  }
}
