// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid leading underscores for library prefixes.';

class NoLeadingUnderscoresForLibraryPrefixes extends MultiAnalysisRule {
  new()
    : super(
        name: LintNames.no_leading_underscores_for_library_prefixes,
        description: _desc,
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => const [
    diag.noLeadingUnderscoresForLibraryPrefixes,
    diag.noLeadingUnderscoresForLibraryPrefixesShadowed,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor(final MultiAnalysisRule rule, RuleContext context)
    extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled = context.isFeatureEnabled(
    Feature.wildcard_variables,
  );

  void checkIdentifier(SimpleIdentifier? id) {
    if (id == null) return;

    var name = id.name;

    if (_wildCardVariablesEnabled && name == '_') return;
    if (!name.hasLeadingUnderscore) return;

    rule.reportAtNode(
      id,
      arguments: [id.name],
      diagnosticCode: _isShadowing(name, id)
          ? diag.noLeadingUnderscoresForLibraryPrefixesShadowed
          : diag.noLeadingUnderscoresForLibraryPrefixes,
    );
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkIdentifier(node.prefix);
  }

  /// Whether removing the leading underscore from [name] would, at some
  /// reference to the prefix declared by [id], make that reference resolve
  /// to a different element.
  bool _isShadowing(String name, SimpleIdentifier id) {
    var newName = name.substring(1);
    if (newName.isEmpty) return false;

    var element = id.element;
    if (element == null) return false;

    return id.enclosingBody.isShadowedAtSomeReference(newName, element);
  }
}
