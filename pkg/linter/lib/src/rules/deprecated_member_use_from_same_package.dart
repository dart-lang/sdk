// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart' // ignore: implementation_imports
    show DeprecatedElementUsageSet, normalizeDeprecationMessage;
import 'package:analyzer/src/error/element_usage_detector.dart' // ignore: implementation_imports
    show ElementUsageKind, ElementUsageReporter, UsageSetAndReporter;
import 'package:analyzer/src/error/element_usage_frontier_detector.dart' // ignore: implementation_imports
    show ElementUsageFrontierDetector;

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/element_usage_frontier_visitor.dart';

const _desc =
    'Avoid using deprecated elements from within the package in which they are '
    'declared.';

class DeprecatedMemberUseFromSamePackage extends MultiAnalysisRule {
  new()
    : super(
        name: LintNames.deprecated_member_use_from_same_package,
        description: _desc,
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.deprecatedMemberUseFromSamePackageWithMessage,
    diag.deprecatedMemberUseFromSamePackageWithoutMessage,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _DeprecatedElementUsageReporter extends ElementUsageReporter<String> {
  final MultiAnalysisRule _rule;

  new({required this._rule});

  @override
  void report(
    SourceRange usageRange,
    String displayName,
    String tagInfo, {
    required bool isInSamePackage,
    ElementUsageKind usageKind = ElementUsageKind.explicit,
  }) {
    if (!isInSamePackage) {
      // In this case, `DEPRECATED_MEMBER_USE` is reported by the analyzer.
      return;
    }

    if (normalizeDeprecationMessage(tagInfo) case var message?) {
      _rule.reportAtSourceRange(
        usageRange,
        arguments: [displayName, message],
        diagnosticCode: diag.deprecatedMemberUseFromSamePackageWithMessage,
      );
    } else {
      _rule.reportAtSourceRange(
        usageRange,
        arguments: [displayName],
        diagnosticCode: diag.deprecatedMemberUseFromSamePackageWithoutMessage,
      );
    }
  }
}

/// This [SimpleAstVisitor] visits the [CompilationUnit], and forwards the
/// remainder of visitations to an [ElementUsageFrontierVisitor], which keeps
/// track of the deprecated-ness of ancestor declaration nodes.
class _Visitor(final MultiAnalysisRule _rule, final RuleContext _context)
    extends SimpleAstVisitor<void> {
  @override
  void visitCompilationUnit(CompilationUnit node) {
    var package = _context.package;
    if (package == null) {
      // If we don't appear to be in any known package structure, then we can
      // never report that a deprecated use is from the same package as the
      // declaration.
      return;
    }

    var visitor = ElementUsageFrontierVisitor(
      ElementUsageFrontierDetector(
        workspacePackage: package,
        usagesAndReporters: [
          UsageSetAndReporter(
            const DeprecatedElementUsageSet(),
            _DeprecatedElementUsageReporter(rule: _rule),
          ),
        ],
      ),
    );
    node.accept(visitor);
  }
}
