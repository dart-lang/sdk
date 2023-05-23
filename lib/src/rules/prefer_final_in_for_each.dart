// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer final in for-each loop variable if reference is not reassigned.';

const _details = r'''
**DO** prefer declaring for-each loop variables as final if they are not
reassigned later in the code.

Declaring for-each loop variables as final when possible is a good practice
because it helps avoid accidental reassignments and allows the compiler to do
optimizations.

**BAD:**
```dart
for (var element in elements) { // LINT
  print('Element: $element');
}
```

**GOOD:**
```dart
for (final element in elements) {
  print('Element: $element');
}
```

**GOOD:**
```dart
for (var element in elements) {
  element = element + element;
  print('Element: $element');
}
```

''';

class PreferFinalInForEach extends LintRule {
  static const LintCode code = LintCode(
      'prefer_final_in_for_each', "The variable '{0}' should be final.",
      correctionMessage: 'Try making the variable final.');

  PreferFinalInForEach()
      : super(
            name: 'prefer_final_in_for_each',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForEachPartsWithDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    var loopVariable = node.loopVariable;
    if (loopVariable.isFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    var loopVariableElement = loopVariable.declaredElement;
    if (function != null &&
        loopVariableElement != null &&
        !function.isPotentiallyMutatedInScope(loopVariableElement)) {
      var name = loopVariable.name;
      rule.reportLintForToken(name, arguments: [name.lexeme]);
    }
  }
}
