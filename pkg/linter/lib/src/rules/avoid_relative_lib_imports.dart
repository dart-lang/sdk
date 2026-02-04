// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid relative imports for files in `lib/`.';

class AvoidRelativeLibImports extends AnalysisRule {
  AvoidRelativeLibImports()
    : super(name: LintNames.avoid_relative_lib_imports, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.avoidRelativeLibImports;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

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
      rule.reportAtNode(node.uri);
    }
  }
}
