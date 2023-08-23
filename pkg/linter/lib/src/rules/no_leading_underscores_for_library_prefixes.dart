// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
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
  static const LintCode code = LintCode(
      'no_leading_underscores_for_library_prefixes',
      "The library prefix '{0}' starts with an underscore.",
      correctionMessage:
          'Try renaming the prefix to not start with an underscore.');

  NoLeadingUnderscoresForLibraryPrefixes()
      : super(
            name: 'no_leading_underscores_for_library_prefixes',
            description: _desc,
            details: _details,
            group: Group.style);

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

  void checkIdentifier(SimpleIdentifier? id) {
    if (id == null) {
      return;
    }

    if (id.name.hasLeadingUnderscore) {
      rule.reportLint(id, arguments: [id.name]);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkIdentifier(node.prefix);
  }
}
