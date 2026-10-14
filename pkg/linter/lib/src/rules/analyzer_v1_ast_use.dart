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

const _desc = 'Use V1 AST API only from other V1 AST API.';

/// Reports uses of `@V1Ast` elements outside `@V1Ast` declarations.
///
/// This is `deprecated_member_use_from_same_package` for the V1 AST API, which
/// is not deprecated, and remains supported for clients, while its V2
/// counterpart is experimental. It keeps the V1 AST API used only to implement
/// other V1 AST API, so that it can later be deprecated, and removed, without
/// migrating the rest of the analyzer.
class AnalyzerV1AstUse extends AnalysisRule {
  new()
    : super(
        name: LintNames.analyzer_v1_ast_use,
        description: _desc,
        state: const RuleState.internal(),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.analyzerV1AstUse;

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
  /// not a use. Exporting is how the V1 AST API is provided.
  @override
  void visitHideCombinator(HideCombinator node) {}

  /// See [visitHideCombinator].
  @override
  void visitShowCombinator(ShowCombinator node) {}
}

class _V1AstElementUsageReporter extends ElementUsageReporter<String> {
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

/// The elements annotated with `@V1Ast`.
///
/// The annotation is recognized by the name of its class. The analyzer
/// declares it in `package:analyzer/src/dart/ast/ast.dart`.
class _V1AstElementUsageSet implements ElementUsageSet<String> {
  const new();

  @override
  bool get reliesOnlyOnElementMetadata => true;

  /// The message of the `@V1Ast` annotation of [element], or `null`
  /// if [element] is not annotated with `@V1Ast`.
  @override
  String? getTagInfo(Element element, Metadata elementMetadata) {
    for (var annotation in elementMetadata.annotations) {
      if (annotation.element case ConstructorElement(
        enclosingElement: InterfaceElement(name: 'V1Ast'),
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
            const _V1AstElementUsageSet(),
            _V1AstElementUsageReporter(_rule),
          ),
        ],
      ),
    );
    node.accept(visitor);
  }
}
