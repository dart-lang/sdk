// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Lint rule: `api_deprecated_on_target`.
///
/// Fires when a method or function annotated with `@ExternalVersions` is called
/// and the API is in a deprecated (but still available) state on the project's
/// minimum deployment target — i.e., the target OS version falls within the
/// `[deprecatedAt, obsoletedAt)` window.
///
/// Emits a hint/info diagnostic to inform the developer that, while the call
/// won't crash, the underlying API is deprecated on the targeted OS.
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../deployment_target_resolver.dart';
import '../version_utils.dart';
import 'annotation_reader.dart';
import 'api_not_available_on_min_target.dart'
    show ApiNotAvailableOnMinTargetRule;

const _desc =
    'Called API is deprecated on the project\'s minimum OS deployment target.';

/// Lint rule that reports an INFO diagnostic when a native interop API is
/// called but is deprecated (not yet removed) on the project's minimum OS
/// deployment target.
class ApiDeprecatedOnTargetRule extends AnalysisRule {
  /// Lint code for deprecated-API calls.
  static const LintCode apiDeprecated = LintCode(
    'api_deprecated_on_target',
    "'{0}' is deprecated on {1} {2}+: {3}",
    correctionMessage:
        'Consider migrating to the recommended replacement before the API '
        'is fully removed, or suppress this warning if intentional.',
    severity: DiagnosticSeverity.INFO,
  );

  /// Lint code for deprecated API calls without a message.
  static const LintCode apiDeprecatedNoMessage = LintCode(
    'api_deprecated_on_target',
    "'{0}' is deprecated on {1} {2}+.",
    correctionMessage:
        'Consider migrating to a newer API.',
    severity: DiagnosticSeverity.INFO,
  );

  ApiDeprecatedOnTargetRule()
      : super(
          name: 'api_deprecated_on_target',
          description: _desc,
        );

  @override
  DiagnosticCode get diagnosticCode => apiDeprecated;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final resolver = ApiNotAvailableOnMinTargetRule.resolverFromContext(context);
    if (resolver == null) return;

    final visitor = _Visitor(this, resolver);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ApiDeprecatedOnTargetRule rule;
  final DeploymentTargetResolver resolver;

  _Visitor(this.rule, this.resolver);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.methodName.element, node.methodName);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _check(node.element, node.function);
  }

  void _check(Element? element, AstNode reportNode) {
    if (element == null) return;

    final versions = AnnotationReader.readExternalVersions(element);
    if (versions == null) return;

    for (final entry in versions.entries) {
      final platformStr = entry.key;
      final version = entry.value;

      final platform = _platformFromString(platformStr);
      if (platform == null) continue;

      final projectMin = resolver.resolve(platform);
      if (projectMin == null) continue;

      final deprecationMessage = version['deprecationMessage'];
      if (deprecationMessage == null) continue; // Not deprecated.

      final apiMin = version['min'];
      final apiMax = version['max'];

      // Only fire if the deprecation applies on the project's min target.
      if (apiMin != null &&
          apiDeprecatedOn(apiMin, apiMax, projectMin)) {
        if (deprecationMessage.isNotEmpty) {
          rule.reportAtNode(
            reportNode,
            arguments: [
              element.displayName,
              platformStr,
              apiMin,
              deprecationMessage,
            ],
          );
        } else {
          rule.reportAtNode(
            reportNode,
            diagnosticCode: ApiDeprecatedOnTargetRule.apiDeprecatedNoMessage,
            arguments: [
              element.displayName,
              platformStr,
              apiMin,
            ],
          );
        }
      }
    }
  }

  ApplePlatform? _platformFromString(String s) {
    for (final p in ApplePlatform.values) {
      if (p.name == s) return p;
    }
    return null;
  }
}
