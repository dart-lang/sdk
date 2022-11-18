// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Do use sound null safety.';

const _details = r'''
**DO** use sound null safety, by not specifying a dart version lower than `2.12`.

**BAD:**
```dart
// @dart=2.8
a() {
}
```

**GOOD:**
```dart
b() {
}
```
''';

class EnableNullSafety extends LintRule implements NodeLintRule {
  EnableNullSafety()
      : super(
            name: 'enable_null_safety',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  // to be kept in sync with LanguageVersionOverrideVerifier (added groups for the version)
  static final regExp = RegExp(r'^\s*//\s*@dart\s*=\s*(\d+)\.(\d+)');
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var beginToken = node.beginToken;
    if (beginToken.type == TokenType.SCRIPT_TAG) {
      beginToken = beginToken.next!;
    }
    CommentToken? comment = beginToken.precedingComments;
    while (comment != null) {
      var match = regExp.firstMatch(comment.lexeme);
      if (match != null && match.groupCount == 2) {
        var major = int.parse(match.group(1)!);
        var minor = int.parse(match.group(2)!);
        if (major == 1 || (major == 2 && minor < 12)) {
          rule.reportLintForToken(comment);
        }
      }

      var next = comment.next;
      comment = next is CommentToken ? next : null;
    }
  }
}
