// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';
import '../ast.dart';
import 'implementation_imports.dart' show samePackage;

const _desc = r'Prefer relative imports for files in `lib/`.';

const _details = r'''
**PREFER** relative imports for files in `lib/`.

When mixing relative and absolute imports it's possible to create confusion
where the same member gets imported in two different ways. One way to avoid
that is to ensure you consistently use relative imports for files within the
`lib/` directory.

**BAD:**
```dart
import 'package:my_package/bar.dart';
```

**GOOD:**
```dart
import 'bar.dart';
```

''';

class PreferRelativeImports extends LintRule {
  static const LintCode code = LintCode('prefer_relative_imports',
      "Use relative imports for files in the 'lib' directory.",
      correctionMessage: 'Try converting the URI to a relative URI.');

  PreferRelativeImports()
      : super(
            name: 'prefer_relative_imports',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  List<String> get incompatibleRules => const ['always_use_package_imports'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!isInLibDir(context.currentUnit.unit, context.package)) {
      return;
    }

    var visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferRelativeImports rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  bool isPackageSelfReference(ImportDirective node) {
    var uri = node.element?.uri;
    if (uri is! DirectiveUriWithSource) {
      return false;
    }

    // Is it a package: import?
    var importUri = uri.relativeUri;
    if (!importUri.isScheme('package')) return false;

    var sourceUri = node.element?.source.uri;
    if (!samePackage(importUri, sourceUri)) return false;

    // todo (pq): context.package.contains(source) should work (but does not)
    var packageRoot = context.package?.root;
    return packageRoot != null &&
        path.isWithin(packageRoot, uri.source.fullName);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (isPackageSelfReference(node)) {
      rule.reportLint(node.uri);
    }
  }
}
