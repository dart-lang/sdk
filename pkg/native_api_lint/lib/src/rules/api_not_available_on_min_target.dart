// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Lint rule: `api_not_available_on_min_target`.
///
/// Fires when a method or function annotated with `@ExternalVersions` is called
/// and its `min` version is higher than the project's minimum deployment target
/// for that platform.
///
/// For example, if the project targets iOS 13.0 and the called API requires
/// iOS 14.0, a warning is emitted.
library;

import 'dart:io' show FileStat, FileSystemEntityType;

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

const _desc =
    'Called API is not available on the project\'s minimum OS deployment target.';

/// Lint rule that warns when a native interop API is called on a project that
/// targets an OS version older than the API's minimum supported version.
class ApiNotAvailableOnMinTargetRule extends MultiAnalysisRule {
  /// The lint code emitted when an API call is incompatible with the
  /// project's minimum deployment target.
  static const LintCode apiNotAvailable = LintCode(
    'api_not_available_on_min_target',
    "'{0}' requires {1} {2}+, but the project's minimum {1} "
    "deployment target is {3}.",
    correctionMessage:
        'Either raise the minimum deployment target in ios/Podfile '
        "(e.g. 'platform :ios, \"{2}\"'), guard this call with a version "
        'check, or update your ffigen bindings.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The lint code emitted when an API is entirely unavailable (removed)
  /// on the project target (`API_UNAVAILABLE` or obsoleted before target).
  static const LintCode apiObsoleted = LintCode(
    'api_obsoleted_on_min_target',
    "'{0}' was removed in {1} {2}, but the project's minimum {1} "
    "deployment target is {3}.",
    correctionMessage:
        'This API no longer exists on the targeted OS version. '
        'Use an alternative API or lower the deployment target.',
    severity: DiagnosticSeverity.ERROR,
  );

  ApiNotAvailableOnMinTargetRule()
      : super(
          name: 'api_not_available_on_min_target',
          description: _desc,
        );

  @override
  List<DiagnosticCode> get diagnosticCodes => [apiNotAvailable, apiObsoleted];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final resolver = resolverFromContext(context);
    if (resolver == null) return; // not in a Flutter project

    final visitor = _Visitor(this, resolver);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }

  /// Builds a [DeploymentTargetResolver] from the analysis context.
  ///
  /// Returns `null` if the project root cannot be determined or if no
  /// Apple platform directories (`ios/`, `macos/`) exist under the project.
  static DeploymentTargetResolver? resolverFromContext(RuleContext context) {
    // The project root is the package root (parent of lib/).
    final package = context.package;
    if (package == null) return null;

    final projectRoot = package.root.path;
    final resolver = DeploymentTargetResolver(projectRoot);

    // Only return a resolver if at least one supported platform directory
    // exists — avoids unnecessary file I/O for non-Flutter packages.
    for (final platform in ApplePlatform.values) {
      final dir = '${resolver.projectRoot}/${platform.flutterDir}';
      if (_directoryExists(dir)) return resolver;
    }
    return null;
  }

  static bool _directoryExists(String path) {
    try {
      final stat = FileStat.statSync(path);
      return stat.type == FileSystemEntityType.directory;
    } catch (_) {
      return false;
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ApiNotAvailableOnMinTargetRule rule;
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

      // Map platform string to enum.
      final platform = _platformFromString(platformStr);
      if (platform == null) continue;

      final projectMin = resolver.resolve(platform);
      if (projectMin == null) continue; // target unknown — skip

      final apiMin = version['min'];
      final apiMax = version['max'];

      // Case 1: API completely unavailable / obsoleted on this target.
      if (apiMax != null && apiObsoletedBefore(apiMax, projectMin)) {
        rule.reportAtNode(
          reportNode,
          diagnosticCode: ApiNotAvailableOnMinTargetRule.apiObsoleted,
          arguments: [
            element.displayName,
            platformStr,
            apiMax,
            projectMin,
          ],
        );
        continue;
      }

      // Case 2: API requires newer OS than the project minimum.
      if (apiMin != null && apiRequiresNewerThan(apiMin, projectMin)) {
        rule.reportAtNode(
          reportNode,
          arguments: [
            element.displayName,
            platformStr,
            apiMin,
            projectMin,
          ],
        );
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
