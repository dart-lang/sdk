// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/workspace/pub.dart'; // ignore: implementation_imports

import '../../analyzer.dart';
import '../../ast.dart';

const _desc = r'Depend on referenced packages.';

class DependOnReferencedPackages extends LintRule {
  DependOnReferencedPackages()
    : super(name: LintNames.depend_on_referenced_packages, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.dependOnReferencedPackages;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // Only lint if we have a pubspec.
    var package = context.package;
    if (package is! PubPackage) return;
    var pubspec = package.pubspec;
    if (pubspec == null) return;
    var name = pubspec.name?.value.text;
    if (name == null) return;

    var dependencies = pubspec.dependencies;
    var devDependencies = pubspec.devDependencies;
    var availableDeps = [
      name,
      if (dependencies != null)
        for (var dep in dependencies)
          if (dep.name?.text != null) dep.name!.text!,
      if (devDependencies != null &&
          !isInPublicDir(context.definingUnit.unit, context.package))
        for (var dep in devDependencies)
          if (dep.name?.text != null) dep.name!.text!,
    ];

    var visitor = _Visitor(this, availableDeps);
    registry.addImportDirective(this, visitor);
    registry.addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Virtual packages will not have explicit dependencies
  /// and get skipped.
  static const virtualPackages = [
    //https://github.com/dart-lang/linter/issues/3308
    'flutter_gen',
  ];

  final DependOnReferencedPackages rule;
  final List<String> availableDeps;

  _Visitor(this.rule, this.availableDeps);

  @override
  void visitExportDirective(ExportDirective node) => _checkDirective(node);

  @override
  void visitImportDirective(ImportDirective node) => _checkDirective(node);

  void _checkDirective(UriBasedDirective node) {
    // Is it a package: uri?
    var uriContent = node.uri.stringValue;
    if (uriContent == null) return;
    if (!uriContent.startsWith('package:')) return;

    // The package name is the first segment of the uri, find the first slash.
    var firstSlash = uriContent.indexOf('/');
    if (firstSlash == -1) return;

    var packageName = uriContent.substring(8, firstSlash);
    if (virtualPackages.contains(packageName)) return;
    if (availableDeps.contains(packageName)) return;
    rule.reportAtNode(node.uri, arguments: [packageName]);
  }
}
