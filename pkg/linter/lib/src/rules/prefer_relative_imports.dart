// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';
import '../extensions.dart';
import 'implementation_imports.dart' show samePackage;

const _desc = r'Prefer relative imports for files in `lib/`.';

class PreferRelativeImports extends LintRule {
  PreferRelativeImports()
      : super(
          name: LintNames.prefer_relative_imports,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules =>
      const [LintNames.always_use_package_imports];

  @override
  LintCode get lintCode => LinterLintCode.prefer_relative_imports;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isInLibDir) return;

    var sourceUri = context.libraryElement2?.uri;
    if (sourceUri == null) return;

    var visitor = _Visitor(this, sourceUri, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferRelativeImports rule;
  final Uri sourceUri;
  final LinterContext context;

  _Visitor(this.rule, this.sourceUri, this.context);

  bool isPackageSelfReference(ImportDirective node) {
    if (node.libraryImport?.uri case DirectiveUriWithSource importedLibrary) {
      var importUri = importedLibrary.relativeUri;
      if (!importUri.isScheme('package')) return false;

      if (!samePackage(importUri, sourceUri)) return false;

      // TODO(pq): context.package.contains(source) should work (but does not)
      var packageRoot = context.package?.root;
      return packageRoot != null &&
          path.isWithin(packageRoot, importedLibrary.source.fullName);
    }

    return false;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (isPackageSelfReference(node)) {
      rule.reportLint(node.uri);
    }
  }
}
