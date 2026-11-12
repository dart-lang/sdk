// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart'; // ignore: implementation_imports
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use string in part of directives.';

class UseStringInPartOfDirectives extends AnalysisRule {
  new()
    : super(
        name: LintNames.use_string_in_part_of_directives,
        description: _desc,
        state: RuleState.deprecated(
          since:
              Feature.enhanced_parts.releaseVersion ??
              // Until `enhanced_parts` has a release version, bumping minor by 1
              // makes `since <= min` match both the next minor and next major
              // versions while excluding patch releases of `currentVersion`.
              Version(
                ExperimentStatus.currentVersion.major,
                ExperimentStatus.currentVersion.minor + 1,
                0,
              ),
        ),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.useStringInPartOfDirectives;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.enhanced_parts)) {
      var visitor = _Visitor(this);
      registry.addPartOfDirective(this, visitor);
    }
  }
}

class _Visitor(final AnalysisRule rule) extends SimpleAstVisitor<void> {
  @override
  void visitPartOfDirective(PartOfDirective node) {
    if (node.libraryName != null) {
      rule.reportAtNode(node);
    }
  }
}
