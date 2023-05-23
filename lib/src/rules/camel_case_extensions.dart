// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Name extensions using UpperCamelCase.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/style#do-name-extensions-using-uppercamelcase):

**DO** name extensions using `UpperCamelCase`.

Extensions should capitalize the first letter of each word (including
the first word), and use no separators.

**GOOD:**
```dart
extension MyFancyList<T> on List<T> { 
  // ... 
}

extension SmartIterable<T> on Iterable<T> {
  // ...
}
```
''';

class CamelCaseExtensions extends LintRule {
  static const LintCode code = LintCode('camel_case_extensions',
      "The extension name '{0}' isn't an UpperCamelCase identifier.",
      correctionMessage:
          'Try changing the name to follow the UpperCamelCase style.');

  CamelCaseExtensions()
      : super(
            name: 'camel_case_extensions',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addExtensionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var name = node.name;
    if (name != null && !isCamelCase(name.lexeme)) {
      rule.reportLintForToken(name, arguments: [name.lexeme]);
    }
  }
}
