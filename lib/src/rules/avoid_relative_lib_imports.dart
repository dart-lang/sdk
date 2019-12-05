// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid relative imports for files in `lib/`.';

const _details = r'''*DO* avoid relative imports for files in `lib/`.

When mixing relative and absolute imports it's possible to create confusion
where the same member gets imported in two different ways.  An easy way to avoid
that is to ensure you have no relative imports that include `lib/` in their
paths.

**GOOD:**

```
import 'package:foo/bar.dart';

import 'baz.dart';

...
```

**BAD:**

```
import 'package:foo/bar.dart';

import '../lib/baz.dart';

...
```

''';

class AvoidRelativeLibImports extends LintRule implements NodeLintRule {
  AvoidRelativeLibImports()
      : super(
            name: 'avoid_relative_lib_imports',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isRelativeLibImport(ImportDirective node) {
    try {
      final uri = Uri.parse(node.uriContent);
      if (uri.scheme.isEmpty) {
        return uri.path.contains('/lib/');
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Ignore.
    }
    return false;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (isRelativeLibImport(node)) {
      rule.reportLint(node.uri);
    }
  }
}
