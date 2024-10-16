// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';

const _desc =
    r'Avoid overloading operator == and hashCode on classes not marked `@immutable`.';

class AvoidEqualsAndHashCodeOnMutableClasses extends LintRule {
  AvoidEqualsAndHashCodeOnMutableClasses()
      : super(
          name: LintNames.avoid_equals_and_hash_code_on_mutable_classes,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.avoid_equals_and_hash_code_on_mutable_classes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAugmentation) return;

    if (node.name.type == TokenType.EQ_EQ || isHashCode(node)) {
      var classElement = node.classElement;
      if (classElement != null && !classElement.hasImmutableAnnotation) {
        rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata,
            arguments: [node.name.lexeme]);
      }
    }
  }
}

extension on MethodDeclaration {
  ClassElement2? get classElement =>
      // TODO(pq): should this be ClassOrMixinDeclaration ?
      thisOrAncestorOfType<ClassDeclaration>()?.declaredFragment?.element;
}
