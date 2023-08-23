// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use string in part of directives.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#do-use-strings-in-part-of-directives):

**DO** use strings in `part of` directives.

**BAD:**

```dart
part of my_library;
```

**GOOD:**

```dart
part of '../../my_library.dart';
```

''';

class UseStringInPartOfDirectives extends LintRule {
  static const LintCode code = LintCode('use_string_in_part_of_directives',
      'The part-of directive uses a library name.',
      correctionMessage:
          'Try converting the directive to use the URI of the library.');

  UseStringInPartOfDirectives()
      : super(
          name: 'use_string_in_part_of_directives',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addPartOfDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitPartOfDirective(PartOfDirective node) {
    if (node.libraryName != null) {
      rule.reportLint(node);
    }
  }
}
