// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid leading underscores for library prefixes.';

const _details = r'''
**DON'T** use a leading underscore for library prefixes.
There is no concept of "private" for library prefixes. When one of those has a
name that starts with an underscore, it sends a confusing signal to the reader. 
To avoid that, don't use leading underscores in those names.

**BAD:**
```dart
import 'dart:core' as _core;
```

**GOOD:**
```dart
import 'dart:core' as core;
```
''';

class NoLeadingUnderscoresForLibraryPrefixes extends LintRule {
  NoLeadingUnderscoresForLibraryPrefixes()
      : super(
          name: 'no_leading_underscores_for_library_prefixes',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.no_leading_underscores_for_library_prefixes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.libraryElement);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  _Visitor(this.rule, LibraryElement? library)
      : _wildCardVariablesEnabled =
            library?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;

  void checkIdentifier(SimpleIdentifier? id) {
    if (id == null) return;

    var name = id.name;

    if (_wildCardVariablesEnabled && name == '_') return;

    if (name.hasLeadingUnderscore) {
      rule.reportLint(id, arguments: [id.name]);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkIdentifier(node.prefix);
  }
}
