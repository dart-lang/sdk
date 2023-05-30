// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r"Don't use wildcard parameters or variables.";

const _details = r'''
**DON'T** use wildcard parameters or variables.

Wildcard parameters and local variables
(e.g. underscore-only names like `_`, `__`, `___`, etc.) will
become non-binding in a future version of the Dart language.
Any existing code that uses wildcard parameters or variables will
break. In anticipation of this change, and to make adoption easier,
this lint disallows wildcard and variable parameter uses.


**BAD:**
```dart
var _ = 1;
print(_); // LINT
```

```dart
void f(int __) {
  print(__); // LINT multiple underscores too
}
```

**GOOD:**
```dart
for (var _ in [1, 2, 3]) count++;
```

```dart
var [a, _, b, _] = [1, 2, 3, 4];
```
''';

class NoWildcardVariableUses extends LintRule {
  static const LintCode code = LintCode(
      'no_wildcard_variable_uses', 'The referenced identifier is a wildcard.',
      correctionMessage: 'Use an identifier name that is not a wildcard.');

  NoWildcardVariableUses()
      : super(
            name: 'no_wildcard_variable_uses',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is! LocalVariableElement && element is! ParameterElement) {
      return;
    }

    if (node.name.isJustUnderscores) {
      rule.reportLint(node);
    }
  }
}
