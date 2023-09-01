// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid relative imports for files in `lib/`.';

const _details = r'''
**DO** avoid relative imports for files in `lib/`.

When mixing relative and absolute imports it's possible to create confusion
where the same member gets imported in two different ways.  An easy way to avoid
that is to ensure you have no relative imports that include `lib/` in their
paths.

You can also use 'always_use_package_imports' to disallow relative imports
between files within `lib/`.

**BAD:**
```dart
import 'package:foo/bar.dart';

import '../lib/baz.dart';

...
```

**GOOD:**
```dart
import 'package:foo/bar.dart';

import 'baz.dart';

...
```

''';

class AvoidRelativeLibImports extends LintRule {
  static const LintCode code = LintCode('avoid_relative_lib_imports',
      "Can't use a relative path to import a library in 'lib'.",
      correctionMessage:
          "Try fixing the relative path or changing the import to a 'package:' "
          'import.');

  AvoidRelativeLibImports()
      : super(
            name: 'avoid_relative_lib_imports',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isRelativeLibImport(ImportDirective node) {
    // Relative paths from within the `lib` folder are covered by the
    // `always_use_package_imports` lint.
    var uriContent = node.uri.stringValue;
    if (uriContent != null) {
      var uri = Uri.tryParse(uriContent);
      if (uri != null && uri.scheme.isEmpty) {
        return uri.path.contains('/lib/');
      }
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
