// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    r'Prefix library names with the package name and a dot-separated path.';

/// Checks if the [name] is equivalent to the specified [prefix] or at least
/// is prefixed by it with a delimiting `.`.
bool matchesOrIsPrefixedBy(String name, String prefix) =>
    name == prefix || name.startsWith('$prefix.');

class PackagePrefixedLibraryNames extends LintRule {
  PackagePrefixedLibraryNames()
    : super(name: LintNames.package_prefixed_library_names, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.package_prefixed_library_names;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PackagePrefixedLibraryNames rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    // Project info is not being set.
    //See: https://github.com/dart-lang/linter/issues/3395
    return;

    // // If no project info is set, bail early.
    // // https://github.com/dart-lang/linter/issues/154
    // var project = rule.project;
    // var element = node.element;
    // if (project == null || element == null) {
    //   return;
    // }
    //
    // var source = element.source;
    // if (source == null) {
    //   return;
    // }
    //
    // var prefix = Analyzer.facade.createLibraryNamePrefix(
    //     libraryPath: source.fullName,
    //     projectRoot: project.root.absolute.path,
    //     packageName: project.name);
    //
    // var name = element.name;
    // if (name == null || !matchesOrIsPrefixedBy(name, prefix)) {
    //   rule.reportLint(node.name, arguments: ['$prefix.$name']);
    // }
  }
}
