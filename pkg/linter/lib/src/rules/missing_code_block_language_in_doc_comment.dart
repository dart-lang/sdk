// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'A code block is missing a specified language.';

const _details = r'''
**DO** specify the language used in the code block of a doc comment.

To enable proper syntax highlighting of Markdown code blocks,
[`dart doc`](https://dart.dev/tools/dart-doc) strongly recommends code blocks to
specify the language used after the initial code fence.

See [highlight.js](https://github.com/highlightjs/highlight.js/blob/main/SUPPORTED_LANGUAGES.md)
for the list of languages supported by `dart doc`.
To disable syntax highlighting or if no language is suitable,
you can specify `none` as the language.

**BAD:**
```dart
/// ```
/// void main() {}
/// ```
class A {}
```

**GOOD:**
```dart
/// ```dart
/// void main() {}
/// ```
class A {}
```

''';

class MissingCodeBlockLanguageInDocComment extends LintRule {
  MissingCodeBlockLanguageInDocComment()
      : super(
            name: 'missing_code_block_language_in_doc_comment',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.errorProne});

  @override
  LintCode get lintCode =>
      LinterLintCode.missing_code_block_language_in_doc_comment;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addComment(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitComment(Comment node) {
    for (var codeBlock in node.codeBlocks) {
      if (codeBlock.infoString != null) continue;
      if (codeBlock.type != CodeBlockType.fenced) continue;

      var openingCodeBlockFence = codeBlock.lines.first;
      rule.reportLintForOffset(
        openingCodeBlockFence.offset,
        openingCodeBlockFence.length,
      );
    }
  }
}
