// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Avoid relative imports for files in `lib/`.';

const _details = r'''
**DO** avoid relative imports for files in `lib/`.

When mixing relative and absolute imports it's possible to create confusion
where the same member gets imported in two different ways. One way to avoid
that is to ensure you consistently use absolute imports for files within the
`lib/` directory.

This is the opposite of 'prefer_relative_imports'.

You can also use 'avoid_relative_lib_imports' to disallow relative imports of
files within `lib/` directory outside of it (for example `test/`).

**BAD:**
```dart
import 'baz.dart';

import 'src/bag.dart'

import '../lib/baz.dart';

...
```

**GOOD:**
```dart
import 'package:foo/bar.dart';

import 'package:foo/baz.dart';

import 'package:foo/src/baz.dart';
...
```

''';

class AlwaysUsePackageImports extends LintRule {
  static const LintCode code = LintCode('always_use_package_imports',
      "Use 'package:' imports for files in the 'lib' directory.",
      correctionMessage: "Try converting the URI to a 'package:' URI.");

  AlwaysUsePackageImports()
      : super(
            name: 'always_use_package_imports',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  List<String> get incompatibleRules => const ['prefer_relative_imports'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    // Relative paths from outside of the lib folder are handled by the
    // `avoid_relative_lib_imports` lint.
    if (!isInLibDir(context.currentUnit.unit, context.package)) {
      return;
    }

    var visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isRelativeImport(ImportDirective node) {
    var uriContent = node.uri.stringValue;
    if (uriContent != null) {
      var uri = Uri.tryParse(uriContent);
      return uri != null && uri.scheme.isEmpty;
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
