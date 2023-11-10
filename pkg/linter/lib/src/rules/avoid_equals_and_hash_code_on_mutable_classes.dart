// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc =
    r'Avoid overloading operator == and hashCode on classes not marked `@immutable`.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/design#avoid-defining-custom-equality-for-mutable-classes):

**AVOID** overloading operator == and hashCode on classes not marked `@immutable`.

If a class is not immutable, overloading `operator ==` and `hashCode` can
lead to unpredictable and undesirable behavior when used in collections.

**BAD:**
```dart
class B {
  String key;
  const B(this.key);
  @override
  operator ==(other) => other is B && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
```

**GOOD:**
```dart
@immutable
class A {
  final String key;
  const A(this.key);
  @override
  operator ==(other) => other is A && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
```

NOTE: The lint checks the use of the `@immutable` annotation, and will trigger
even if the class is otherwise not mutable. Thus:

**BAD:**
```dart
class C {
  final String key;
  const C(this.key);
  @override
  operator ==(other) => other is C && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
```

''';

class AvoidEqualsAndHashCodeOnMutableClasses extends LintRule {
  static const LintCode code = LintCode(
      'avoid_equals_and_hash_code_on_mutable_classes',
      "The method '{0}' should not be overridden in classes not annotated with '@immutable'.",
      correctionMessage:
          "Try removing the override or annotating the class with '@immutable'.");

  AvoidEqualsAndHashCodeOnMutableClasses()
      : super(
            name: 'avoid_equals_and_hash_code_on_mutable_classes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

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
    if (node.name.type == TokenType.EQ_EQ || isHashCode(node)) {
      var classElement = _getClassForMethod(node);
      if (classElement != null && !_hasImmutableAnnotation(classElement)) {
        rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata,
            arguments: [node.name.lexeme]);
      }
    }
  }

  ClassElement? _getClassForMethod(MethodDeclaration node) =>
      // TODO(pq): should this be ClassOrMixinDeclaration ?
      node.thisOrAncestorOfType<ClassDeclaration>()?.declaredElement;

  bool _hasImmutableAnnotation(ClassElement clazz) {
    var inheritedAndSelfElements = <InterfaceElement>[
      ...clazz.allSupertypes.map((t) => t.element),
      clazz,
    ];
    return inheritedAndSelfElements.any((e) => e.hasImmutable);
  }
}
