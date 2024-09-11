// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Provide a deprecation message, via `@Deprecated("message")`.';

const _details = r'''
**DO** specify a deprecation message (with migration instructions and/or a
removal schedule) in the `Deprecated` constructor.

**BAD:**
```dart
@deprecated
void oldFunction(arg1, arg2) {}
```

**GOOD:**
```dart
@Deprecated("""
[oldFunction] is being deprecated in favor of [newFunction] (with slightly
different parameters; see [newFunction] for more information). [oldFunction]
will be removed on or after the 4.0.0 release.
""")
void oldFunction(arg1, arg2) {}
```

''';

class ProvideDeprecationMessage extends LintRule {
  ProvideDeprecationMessage()
      : super(
          name: 'provide_deprecation_message',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.provide_deprecation_message;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAnnotation(Annotation node) {
    var elementAnnotation = node.elementAnnotation;
    if (elementAnnotation != null &&
        elementAnnotation.isDeprecated &&
        node.arguments == null) {
      rule.reportLint(node);
    }
  }
}
