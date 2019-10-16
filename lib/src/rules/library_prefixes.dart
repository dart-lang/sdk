// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc =
    r'Use `lowercase_with_underscores` when specifying a library prefix.';

const _details = r'''

**DO** use `lowercase_with_underscores` when specifying a library prefix.

**GOOD:**
```
import 'dart:math' as math;
import 'dart:json' as json;
import 'package:js/js.dart' as js;
import 'package:javascript_utils/javascript_utils.dart' as js_utils;
```

**BAD:**
```
import 'dart:math' as Math;
import 'dart:json' as JSON;
import 'package:js/js.dart' as JS;
import 'package:javascript_utils/javascript_utils.dart' as jsUtils;
```

''';

class LibraryPrefixes extends LintRule implements NodeLintRule {
  LibraryPrefixes()
      : super(
            name: 'library_prefixes',
            description: _desc,
            details: _details,
            group: Group.style);

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

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.prefix != null && !isValidLibraryPrefix(node.prefix.toString())) {
      rule.reportLint(node.prefix);
    }
  }
}
