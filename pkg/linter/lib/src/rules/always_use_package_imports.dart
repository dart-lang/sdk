// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid relative imports for files in `lib/`.';

class AlwaysUsePackageImports extends LintRule {
  AlwaysUsePackageImports()
      : super(
          name: LintNames.always_use_package_imports,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules =>
      const [LintNames.prefer_relative_imports];

  @override
  LintCode get lintCode => LinterLintCode.always_use_package_imports;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    // Relative paths from outside of the lib folder are handled by the
    // `avoid_relative_lib_imports` lint rule.
    if (!context.isInLibDir) return;

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
