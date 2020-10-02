// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Avoid relative imports for files in `lib/`.';

const _details = r'''*DO* avoid relative imports for files in `lib/`.

When mixing relative and absolute imports it's possible to create confusion
where the same member gets imported in two different ways. One way to avoid
that is to ensure you consistently use absolute imports for files withing the
`lib/` directory.

This is the opposite of 'prefer_relative_imports'.
Might be used with 'avoid_relative_lib_imports' to avoid relative imports of
files within `lib/` directory outside of it. (for example `test/`)

**GOOD:**

```
import 'package:foo/bar.dart';

import 'package:foo/baz.dart';

import 'package:foo/src/baz.dart';
...
```

**BAD:**

```
import 'baz.dart';

import 'src/bag.dart'

import '../lib/baz.dart';

...
```

''';

class AlwaysUsePackageImports extends LintRule implements NodeLintRule {
  AlwaysUsePackageImports()
      : super(
            name: 'always_use_package_imports',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!isInLibDir(context.currentUnit.unit, context.package)) {
      return;
    }

    final visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  bool isRelativeImport(ImportDirective node) {
    try {
      final uri = Uri.parse(node.uriContent);
      return uri.scheme.isEmpty;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Ignore.
    }
    return false;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (isRelativeImport(node)) {
      rule.reportLint(node.uri);
    }
  }
}
