// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/workspace/pub.dart'; // ignore: implementation_imports
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Deprecation in major version.';

bool isBreakingVersion(Version version) =>
    // Here we also consider prereleases to breaking versions breaking, as they
    // should already remove deprecated elements.
    version.build.isEmpty &&
    ((version.minor == 0 && version.patch == 0) ||
        (version.major == 0 && version.patch == 0));

class RemoveDeprecationsInBreakingVersion extends AnalysisRule {
  RemoveDeprecationsInBreakingVersion()
    : super(
        name: LintNames.remove_deprecations_in_breaking_versions,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      diag.removeDeprecationsInBreakingVersions;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // Only lint if we have a pubspec, and the version is of the form x.0.0 or
    // 0.x.0.
    var package = context.package;
    if (package is! PubPackage) return;
    var pubspec = package.pubspec;
    if (pubspec == null) return;
    var versionText = pubspec.version?.value.text;
    if (versionText == null) return;
    Version version;
    try {
      version = Version.parse(versionText);
    } on FormatException {
      // Bad version number. Skip.
      return;
    }
    if (!isBreakingVersion(version)) return;
    var visitor = _Visitor(this);
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitAnnotation(Annotation node) {
    var elementAnnotation = node.elementAnnotation;
    if (elementAnnotation != null && elementAnnotation.isDeprecated) {
      rule.reportAtNode(node.name);
    }
  }
}
