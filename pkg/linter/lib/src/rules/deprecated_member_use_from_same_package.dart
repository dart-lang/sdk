// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/deprecated_member_use_verifier.dart' // ignore: implementation_imports
    show DeprecatedElementUsageSet, normalizeDeprecationMessage;
import 'package:analyzer/src/error/element_usage_detector.dart' // ignore: implementation_imports
    show ElementUsageReporter, UsageSetAndReporter;
import 'package:analyzer/src/error/element_usage_frontier_detector.dart' // ignore: implementation_imports
    show ElementUsageFrontierDetector;
import 'package:analyzer/src/utilities/extensions/ast.dart'; // ignore: implementation_imports
import 'package:analyzer/workspace/workspace.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    'Avoid using deprecated elements from within the package in which they are '
    'declared.';

class DeprecatedMemberUseFromSamePackage extends MultiAnalysisRule {
  DeprecatedMemberUseFromSamePackage()
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

  _DeprecatedElementUsageReporter({required MultiAnalysisRule rule})
    : _rule = rule;

  @override
  void report(
    SyntacticEntity usageSite,
    String displayName,
    String tagInfo, {
    required bool isInSamePackage,
  }) {
    if (!isInSamePackage) {
      // In this case, `DEPRECATED_MEMBER_USE` is reported by the analyzer.
      return;
    }

    if (normalizeDeprecationMessage(tagInfo) case var message?) {
      _rule.reportAtSourceRange(
        usageSite.sourceRange,
        arguments: [displayName, message],
        diagnosticCode: diag.deprecatedMemberUseFromSamePackageWithMessage,
      );
    } else {
      _rule.reportAtSourceRange(
        usageSite.sourceRange,
        arguments: [displayName],
        diagnosticCode: diag.deprecatedMemberUseFromSamePackageWithoutMessage,
      );
    }
  }
}

/// This visitor uses an [ElementUsageFrontierDetector] to both report uses of
/// deprecated elements, and to track the deprecated-ness of ancestor
/// declaration nodes.
class _RecursiveVisitor extends RecursiveAstVisitor<void> {
  final ElementUsageFrontierDetector<String> _deprecatedVerifier;

  _RecursiveVisitor(MultiAnalysisRule rule, WorkspacePackage package)
    : _deprecatedVerifier = ElementUsageFrontierDetector(
        workspacePackage: package,
        usagesAndReporters: [
          UsageSetAndReporter(
            const DeprecatedElementUsageSet(),
            _DeprecatedElementUsageReporter(rule: rule),
          ),
        ],
      );

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _deprecatedVerifier.assignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _deprecatedVerifier.binaryExpression(node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitClassDeclaration(node);
    });
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _withDeprecatedDeclaration(node, () {
      super.visitClassTypeAlias(node);
    });
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var library = node.declaredFragment?.element;
    if (library == null) {
      return;
    }
    _deprecatedVerifier.pushElement(library);

    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      _deprecatedVerifier.constructorDeclaration(node);
      super.visitConstructorDeclaration(node);
    });
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _deprecatedVerifier.constructorName(node);
    super.visitConstructorName(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _withDeprecatedFormalParameter(node, () {
      super.visitDefaultFormalParameter(node);
    });
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitEnumDeclaration(node);
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _deprecatedVerifier.exportDirective(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitExtensionDeclaration(node);
    });
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _deprecatedVerifier.extensionOverride(node);
    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitExtensionTypeDeclaration(node);
    });
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _deprecatedVerifier.pushElement(node.firstVariableElement);

    try {
      super.visitFieldDeclaration(node);
    } finally {
      _deprecatedVerifier.popElement();
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _withDeprecatedFormalParameter(node, () {
      super.visitFieldFormalParameter(node);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitFunctionDeclaration(node);
    });
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _deprecatedVerifier.functionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _withDeprecatedDeclaration(node, () {
      super.visitFunctionTypeAlias(node);
    });
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _withDeprecatedDeclaration(node, () {
      super.visitGenericTypeAlias(node);
    });
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _deprecatedVerifier.importDirective(node);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _deprecatedVerifier.indexExpression(node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _deprecatedVerifier.instanceCreationExpression(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitMethodDeclaration(node);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _deprecatedVerifier.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _withDeprecatedDeclaration(node, () {
      super.visitMixinDeclaration(node);
    });
  }

  @override
  void visitNamedType(NamedType node) {
    _deprecatedVerifier.namedType(node);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _deprecatedVerifier.patternField(node);
    super.visitPatternField(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _deprecatedVerifier.postfixExpression(node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _deprecatedVerifier.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _deprecatedVerifier.redirectingConstructorInvocation(node);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _withDeprecatedFormalParameter(node, () {
      super.visitSimpleFormalParameter(node);
    });
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _deprecatedVerifier.simpleIdentifier(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _deprecatedVerifier.superConstructorInvocation(node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _deprecatedVerifier.pushElement(node.firstVariableElement);

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _deprecatedVerifier.popElement();
    }
  }

  void _withDeprecatedDeclaration<T extends Declaration>(
    T node,
    void Function() recurse,
  ) {
    _withDeprecatedFragment(node.declaredFragment, recurse);
  }

  void _withDeprecatedFormalParameter<T extends FormalParameter>(
    T node,
    void Function() recurse,
  ) {
    _withDeprecatedFragment(node.declaredFragment, recurse);
  }

  void _withDeprecatedFragment(Fragment? fragment, void Function() recurse) {
    _deprecatedVerifier.pushElement(fragment?.element);
    try {
      recurse();
    } finally {
      _deprecatedVerifier.popElement();
    }
  }
}

/// This [SimpleAstVisitor] visits the [CompilationUnit], and forwards the
/// remainder of visitations to [_RecursiveVisitor], which keeps track of
/// the deprecated-ness of ancestor declaration nodes.
class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule _rule;
  final RuleContext _context;

  _Visitor(this._rule, this._context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var package = _context.package;
    if (package == null) {
      // If we don't appear to be in any known package structure, then we can
      // never report that a deprecated use is from the same package as the
      // declaration.
      return;
    }

    var visitor = _RecursiveVisitor(_rule, package);
    node.accept(visitor);
  }
}
