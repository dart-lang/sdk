// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use generic function type syntax for parameters.';

const _details = r'''
Use generic function type syntax for parameters.

**BAD:**
```dart
Iterable<T> where(bool predicate(T element)) {}
```

**GOOD:**
```dart
Iterable<T> where(bool Function(T) predicate) {}
```

''';

class UseFunctionTypeSyntaxForParameters extends LintRule {
  static const LintCode code = LintCode(
      'use_function_type_syntax_for_parameters',
      "Use the generic function type syntax to declare the parameter '{0}'.",
      correctionMessage: 'Try using the generic function type syntax.');

  UseFunctionTypeSyntaxForParameters()
      : super(
            name: 'use_function_type_syntax_for_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionTypedFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    rule.reportLint(node, arguments: [node.name.lexeme]);
  }
}
