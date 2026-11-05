// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart' // ignore: implementation_imports
    show normalizeDeprecationMessage;
import 'package:analyzer/src/error/element_usage_detector.dart' // ignore: implementation_imports
    show
        ElementUsageKind,
        ElementUsageReporter,
        ElementUsageSet,
        UsageSetAndReporter;
import 'package:analyzer/src/error/element_usage_frontier_detector.dart' // ignore: implementation_imports
    show ElementUsageFrontierDetector;

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/element_usage_frontier_visitor.dart';

const _desc =
    'Use API that is to be deprecated only from API that is to be deprecated.';

/// Reports uses of `@ToBeDeprecated` elements outside `@ToBeDeprecated`
/// declarations.
///
/// This is `deprecated_member_use_from_same_package` for the API that is not
/// deprecated yet, such as the V1 AST while its V2 replacement is
/// experimental. It keeps such API used only to implement other such API, so
/// that it can be deprecated, and later removed, without migrating its users.
class AnalyzerToBeDeprecatedUse extends AnalysisRule {
  new()
    : super(
        name: LintNames.analyzer_to_be_deprecated_use,
        description: _desc,
        state: const RuleState.internal(),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.analyzerToBeDeprecatedUse;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _FrontierVisitor extends ElementUsageFrontierVisitor<String> {
  new(super.detector);

  /// A reference in a comment, such as `[SimpleIdentifier]`, is not a use.
  @override
  void visitComment(Comment node) {}

  /// A name in a combinator only selects what is imported or exported, it is
  /// not a use. Exporting is how the API that is to be deprecated is provided.
  @override
  void visitHideCombinator(HideCombinator node) {}

  /// See [visitHideCombinator].
  @override
  void visitShowCombinator(ShowCombinator node) {}
}

class _ToBeDeprecatedElementUsageReporter extends ElementUsageReporter<String> {
  final AnalysisRule _rule;

  new(this._rule);

  @override
  void report(
    SourceRange usageRange,
    String displayName,
    String tagInfo, {
    required bool isInSamePackage,
    ElementUsageKind usageKind = ElementUsageKind.explicit,
  }) {
    var message = normalizeDeprecationMessage(tagInfo);
    _rule.reportAtSourceRange(
      usageRange,
      arguments: [displayName, message != null ? ' $message' : ''],
    );
  }
}

/// The elements annotated with `@ToBeDeprecated`.
///
/// The annotation is recognized by the name of its class. The analyzer
/// declares it in `package:analyzer/src/dart/ast/ast.dart`.
class _ToBeDeprecatedElementUsageSet implements ElementUsageSet<String> {
  const new();

  @override
  bool get reliesOnlyOnElementMetadata => true;

  /// The message of the `@ToBeDeprecated` annotation of [element], or `null`
  /// if [element] is not annotated with `@ToBeDeprecated`.
  @override
  String? getTagInfo(Element element, Metadata elementMetadata) {
    for (var annotation in elementMetadata.annotations) {
      if (annotation.element case ConstructorElement(
        enclosingElement: InterfaceElement(name: 'ToBeDeprecated'),
      )) {
        var value = annotation.computeConstantValue();
        return value?.getField('message')?.toStringValue() ?? '';
      }
    }
    return null;
  }
}

class _Visitor(final AnalysisRule _rule, final RuleContext _context)
    extends SimpleAstVisitor<void> {
  @override
  void visitCompilationUnit(CompilationUnit node) {
    var visitor = _FrontierVisitor(
      ElementUsageFrontierDetector(
        workspacePackage: _context.package,
        usagesAndReporters: [
          UsageSetAndReporter(
            const _ToBeDeprecatedElementUsageSet(),
            _ToBeDeprecatedElementUsageReporter(_rule),
          ),
        ],
      ),
    );
    node.accept(visitor);
  }
}
