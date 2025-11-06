// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/utilities/extensions/uri.dart';

import '../analyzer.dart';

const _desc = r"Don't import implementation files from another package.";

class ImplementationImports extends LintRule {
  ImplementationImports()
    : super(name: LintNames.implementation_imports, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.implementationImports;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var libraryUri = context.libraryElement?.uri;
    if (libraryUri == null) return;

    // If the source URI is not a `package` URI, bail out.
    if (libraryUri.scheme != 'package') return;

    var visitor = _Visitor(this, libraryUri);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final Uri sourceUri;

  _Visitor(this.rule, this.sourceUri);

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.libraryImport?.uri case DirectiveUriWithSource importedLibrary) {
      var importUri = importedLibrary.source.uri;

      // Test for 'package:*/src/'.
      if (!importUri.isImplementation) return;

      if (!importUri.isSamePackageAs(sourceUri)) {
        rule.reportAtNode(node.uri);
      }
    }
  }
}
