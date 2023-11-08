// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't explicitly catch Error or types that implement it.";

const _details = r'''
**DON'T** explicitly catch Error or types that implement it.

Errors differ from Exceptions in that Errors can be analyzed and prevented prior
to runtime.  It should almost never be necessary to catch an error at runtime.

**BAD:**
```dart
try {
  somethingRisky();
} on Error catch(e) {
  doSomething(e);
}
```

**GOOD:**
```dart
try {
  somethingRisky();
} on Exception catch(e) {
  doSomething(e);
}
```

''';

class AvoidCatchingErrors extends LintRule {
  static const LintCode classCode = LintCode(
      'avoid_catching_errors', "The type 'Error' should not be caught.",
      uniqueName: 'LintCode.avoid_catching_errors_class');

  static const LintCode subclassCode = LintCode('avoid_catching_errors',
      "The type '{0}' should not be caught because it is a subclass of 'Error'.",
      uniqueName: 'LintCode.avoid_catching_errors_subclass');

  AvoidCatchingErrors()
      : super(
            name: 'avoid_catching_errors',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<LintCode> get lintCodes => [classCode, subclassCode];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    var exceptionType = node.exceptionType?.type;
    if (exceptionType.implementsInterface('Error', 'dart.core')) {
      if (exceptionType.isSameAs('Error', 'dart.core')) {
        rule.reportLint(node, errorCode: AvoidCatchingErrors.classCode);
      } else {
        rule.reportLint(node,
            errorCode: AvoidCatchingErrors.subclassCode,
            arguments: [
              exceptionType!.getDisplayString(withNullability: false)
            ]);
      }
    }
  }
}
