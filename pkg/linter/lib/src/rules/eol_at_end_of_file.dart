// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Put a single newline at end of file.';

const _details = r'''
**DO** put a single newline at the end of non-empty files.

**BAD:**
```dart
a {
}
```

**GOOD:**
```dart
b {
}
    <-- newline
```
''';

class EolAtEndOfFile extends LintRule {
  static const LintCode code = LintCode(
      'eol_at_end_of_file', 'Missing a newline at the end of the file.',
      correctionMessage: 'Try adding a newline at the end of the file.');

  EolAtEndOfFile()
      : super(
            name: 'eol_at_end_of_file',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var content = context.currentUnit.content;
    if (content.isNotEmpty &&
        (!content.endsWithNewline || content.endsWithMultipleNewlines)) {
      rule.reportLintForOffset(content.trimRight().length, 1);
    }
  }
}

extension on String {
  static const newline = ['\n', '\r'];
  static const multipleNewlines = ['\n\n', '\r\r', '\r\n\r\n'];
  bool get endsWithMultipleNewlines => multipleNewlines.any(endsWith);
  bool get endsWithNewline => newline.any(endsWith);
}
