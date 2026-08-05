// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use a primary constructor.';

class UsePrimaryConstructors extends AnalysisRule {
  new()
    : super(
        name: LintNames.use_primary_constructors,
        description: _desc,
        state: .testing(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.usePrimaryConstructors;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.primary_constructors)) return;
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // There can only be one primary constructor.
    if (node.namePart is! PrimaryConstructorDeclaration) {
      _checkMembers(
        members: node.body.members,
        containerName: node.namePart.typeName,
      );
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // There can only be one primary constructor.
    if (node.namePart is! PrimaryConstructorDeclaration) {
      _checkMembers(
        members: node.body.members,
        containerName: node.namePart.typeName,
      );
    }
  }

  void _checkMembers({
    required Token containerName,
    required List<ClassMember> members,
  }) {
    var hasConstructor = false;
    ConstructorDeclaration? root;
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        if (member.externalKeyword != null) {
          // Classes with an external constructor can't be converted to use a
          // primary constructor.
          return;
        }
        hasConstructor = true;
        if (member.factoryKeyword == null) {
          if (member.redirect == null) {
            if (root != null) {
              // If there's more than one non-redirecting generative
              // constructor, then none of them can be a primary constructor.
              return;
            }
            root = member;
          }
        }
      }
    }
    if (!hasConstructor) {
      // Use an explicit primary constructor rather than a default constructor.
      rule.reportAtToken(containerName);
      return;
    }
    if (root == null) {
      // If there aren't any non-redirecting constructors, then there's nothing
      // to convert.
      return;
    }
    // Otherwise, there's a single non-redirecting generative constructor, so it
    // can be converted.
    _reportConstructor(root);
  }

  void _reportConstructor(ConstructorDeclaration constructor) {
    var name = constructor.name;
    if (name != null) {
      rule.reportAtToken(name);
      return;
    }
    var typeName = constructor.typeName;
    if (typeName != null) {
      rule.reportAtNode(typeName);
      return;
    }
    var keyword = constructor.newKeyword;
    if (keyword != null) {
      rule.reportAtToken(keyword);
    }
  }
}

extension on ConstructorDeclaration {
  ConstructorElement? get redirect {
    var initializer = initializers.lastOrNull;
    if (initializer is RedirectingConstructorInvocation) {
      return initializer.element;
    }
    return null;
  }
}
