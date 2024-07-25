// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc =
    r'Use `lowercase_with_underscores` when specifying a library prefix.';

const _details = r'''
**DO** use `lowercase_with_underscores` when specifying a library prefix.

**BAD:**
```dart
import 'dart:math' as Math;
import 'dart:json' as JSON;
import 'package:js/js.dart' as JS;
import 'package:javascript_utils/javascript_utils.dart' as jsUtils;
```

**GOOD:**
```dart
import 'dart:math' as math;
import 'dart:json' as json;
import 'package:js/js.dart' as js;
import 'package:javascript_utils/javascript_utils.dart' as js_utils;
```

''';

class LibraryPrefixes extends LintRule {
  static const LintCode code =
      LintCode('library_prefixes',
          "The prefix '{0}' isn't a lower_case_with_underscores identifier.",
          correctionMessage:
              'Try changing the prefix to follow the lower_case_with_underscores '
              'style.',
          hasPublishedDocs: true);

  LibraryPrefixes()
      : super(
            name: 'library_prefixes',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.style});

  @override
  LintCode get lintCode => code;

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

  @override
  void visitImportDirective(ImportDirective node) {
    var prefix = node.prefix;
    if (prefix == null) return;

    var prefixString = prefix.toString();
    // With wildcards, `_` is allowed.
    if (_wildCardVariablesEnabled && prefixString == '_') return;

    if (!isValidLibraryPrefix(prefixString)) {
      rule.reportLint(prefix, arguments: [prefixString]);
    }
  }
}
