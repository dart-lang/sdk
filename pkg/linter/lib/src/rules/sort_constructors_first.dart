// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/extensions.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Sort constructor declarations before other members.';

class SortConstructorsFirst extends AnalysisRule {
  SortConstructorsFirst()
    : super(name: LintNames.sort_constructors_first, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.sortConstructorsFirst;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  void check(NodeList<ClassMember> members) {
    var other = false;
    // Members are sorted by source position in the AST.
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        if (other) {
          var errorRange = member.errorRange;
          rule.reportAtOffset(errorRange.offset, errorRange.length);
        }
      } else if (member is PrimaryConstructorBody) {
        if (other) {
          rule.reportAtToken(member.thisKeyword);
        }
      } else {
        other = true;
      }
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.body case BlockClassBody body) {
      check(body.members);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    check(node.body.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.body case BlockClassBody body) {
      check(body.members);
    }
  }
}
