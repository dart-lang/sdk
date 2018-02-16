// Copyright (c)  2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

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

class AvoidRelativeLibImports extends LintRule {
  AvoidRelativeLibImports()
      : super(
            name: 'avoid_relative_lib_imports',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitImportDirective(ImportDirective node) {
    if (isRelativeLibImport(node)) {
      rule.reportLint(node.uri);
    }
  }

  bool isRelativeLibImport(ImportDirective node) {
    try {
      Uri uri = Uri.parse(node.uriContent);
      if (uri.scheme.isEmpty) {
        return uri.path.contains('/lib/');
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Ignore.
    }
    return false;
  }
}
