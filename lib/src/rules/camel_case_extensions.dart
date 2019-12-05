// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Name extensions using UpperCamelCase.';

// todo (pq): reference the style guide when advice is published.
const _details = r'''

**DO** name extensions using `UpperCamelCase`.

Extensions should capitalize the first letter of each word (including
the first word), and use no separators.

**GOOD:**
```
extension MyFancyList<T> on List<T> { 
  // ... 
}

extension SmartIterable<T> on Iterable<T> {
  // ...
}
```
''';

class CamelCaseExtensions extends LintRule implements NodeLintRule {
  CamelCaseExtensions()
      : super(
            name: 'camel_case_extensions',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addExtensionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final name = node.name;
    if (name != null && !isCamelCase(name.name)) {
      rule.reportLint(name);
    }
  }
}
