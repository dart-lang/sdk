// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/utilities/extensions/uri.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';

const _desc = r'Prefer relative imports for files in `lib/`.';

class PreferRelativeImports extends AnalysisRule {
  PreferRelativeImports()
    : super(name: LintNames.prefer_relative_imports, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferRelativeImports;

  @override
  List<String> get incompatibleRules => const [
    LintNames.always_use_package_imports,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;

    var sourceUri = context.libraryElement?.uri;
    if (sourceUri == null) return;

    var visitor = _Visitor(this, sourceUri, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferRelativeImports rule;
  final Uri sourceUri;
  final RuleContext context;

  _Visitor(this.rule, this.sourceUri, this.context);

  bool isPackageSelfReference(ImportDirective node) {
    if (node.libraryImport?.uri case DirectiveUriWithSource importedLibrary) {
      var importUri = importedLibrary.relativeUri;
      if (!importUri.isScheme('package')) return false;

      if (!importUri.isSamePackageAs(sourceUri)) return false;

      // TODO(pq): `context.package.contains(source)` should work (but does
      // not).
      var packageRoot = context.package?.root.path;
      return packageRoot != null &&
          path.isWithin(packageRoot, importedLibrary.source.fullName);
    }

    return false;
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (isPackageSelfReference(node)) {
      rule.reportAtNode(node.uri);
    }
  }
}
