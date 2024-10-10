// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid relative imports for files in `lib/`.';

class AvoidRelativeLibImports extends LintRule {
  AvoidRelativeLibImports()
      : super(
          name: LintNames.avoid_relative_lib_imports,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_relative_lib_imports;

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
