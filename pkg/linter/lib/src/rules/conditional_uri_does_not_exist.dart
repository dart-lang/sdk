// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Missing conditional import.';

class ConditionalUriDoesNotExist extends LintRule {
  ConditionalUriDoesNotExist()
    : super(name: LintNames.conditional_uri_does_not_exist, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.conditional_uri_does_not_exist;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConfiguration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConfiguration(Configuration configuration) {
    var uri = configuration.resolvedUri;
    if (uri is DirectiveUriWithRelativeUriString) {
      var source = uri is DirectiveUriWithSource ? uri.source : null;
      // Checking source with .exists() will not detect the presence of overlays
      // in the analysis server (although running the script when the files
      // don't exist on disk would also fail to find it).
      if (!(source?.exists() ?? false)) {
        rule.reportAtNode(
          configuration.uri,
          arguments: [uri.relativeUriString],
        );
      }
    }
  }
}
