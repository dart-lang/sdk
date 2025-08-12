// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Always override `hashCode` if overriding `==`.';

class HashAndEquals extends LintRule {
  HashAndEquals() : super(name: LintNames.hash_and_equals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.hash_and_equals;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    MethodDeclaration? eq;
    ClassMember? hash;
    for (var member in node.members) {
      if (isEquals(member)) {
        eq = member as MethodDeclaration;
      } else if (isHashCode(member)) {
        hash = member;
      }
    }
    if (eq == null && hash == null) return;

    if (eq == null) {
      if (!node.hasMethod('==')) {
        if (hash is MethodDeclaration) {
          rule.reportAtToken(hash.name, arguments: ['==', 'hashCode']);
        } else if (hash is FieldDeclaration) {
          var hashCodeFieldName = getFieldName(hash, 'hashCode');
          if (hashCodeFieldName == null) return;
          rule.reportAtToken(hashCodeFieldName, arguments: ['==', 'hashCode']);
        }
      }
    }

    if (hash == null) {
      if (!node.hasField('hashCode') && !node.hasMethod('hashCode')) {
        rule.reportAtToken(eq!.name, arguments: ['hashCode', '==']);
      }
    }
  }
}

extension on ClassDeclaration {
  bool hasField(String name) =>
      declaredFragment?.element.fields.namedOrNull(name) != null;
  bool hasMethod(String name) =>
      declaredFragment?.element.methods.namedOrNull(name) != null;
}

extension<E extends Element> on List<E> {
  E? namedOrNull(String name) => firstWhereOrNull((e) => e.name == name);
}
