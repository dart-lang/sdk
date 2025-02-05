// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Always override `hashCode` if overriding `==`.';

class HashAndEquals extends LintRule {
  HashAndEquals()
      : super(
          name: LintNames.hash_and_equals,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.hash_and_equals;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
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
          rule.reportLintForToken(hash.name, arguments: ['==', 'hashCode']);
        } else if (hash is FieldDeclaration) {
          rule.reportLintForToken(getFieldName(hash, 'hashCode'),
              arguments: ['==', 'hashCode']);
        }
      }
    }

    if (hash == null) {
      if (!node.hasField('hashCode') && !node.hasMethod('hashCode')) {
        rule.reportLintForToken(eq!.name, arguments: ['hashCode', '==']);
      }
    }
  }
}

extension on ClassDeclaration {
  bool hasField(String name) =>
      declaredFragment?.element.fields2.namedOrNull(name) != null;
  bool hasMethod(String name) =>
      declaredFragment?.element.methods2.namedOrNull(name) != null;
}

extension<E extends Element2> on List<E> {
  E? namedOrNull(String name) => firstWhereOrNull((e) => e.name3 == name);
}
