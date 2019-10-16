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
    r'AVOID overloading operator == and hashCode on classes not marked `@immutable`.';

const _details = r'''

**AVOID** overloading operator == and hashCode on classes not marked `@immutable`.

If a class is not immutable, overloading operator == and hashCode can lead to
unpredictable and undesirable behavior when used in collections. See
https://dart.dev/guides/language/effective-dart/design#avoid-defining-custom-equality-for-mutable-classes
for more information.

**GOOD:**
```
@immutable
class A {
  final String key;
  const A(this.key);
  @override
  operator ==(other) => other is A && other.key == key;
  @override
  int hashCode() => key.hashCode;
}
```

**BAD:**
```
class B {
  String key;
  const B(this.key);
  @override
  operator ==(other) => other is B && other.key == key;
  @override
  int hashCode() => key.hashCode;
}
```

NOTE: The lint checks the use of the @immutable annotation, and will trigger
even if the class is otherwise not mutable. Thus:

**BAD:**
```
class C {
  final String key;
  const C(this.key);
  @override
  operator ==(other) => other is B && other.key == key;
  @override
  int hashCode() => key.hashCode;
}
```

''';

/// The name of the top-level variable used to mark a immutable class.
String _IMMUTABLE_VAR_NAME = 'immutable';

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = 'meta';

bool _isImmutable(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _IMMUTABLE_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

class AvoidOperatorEqualsOnMutableClasses extends LintRule
    implements NodeLintRule {
  AvoidOperatorEqualsOnMutableClasses()
      : super(
            name: 'avoid_equals_and_hash_code_on_mutable_classes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.token?.type == TokenType.EQ_EQ || isHashCode(node)) {
      final classElement = _getClassForMethod(node);
      if (classElement != null && !_hasImmutableAnnotation(classElement)) {
        rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata);
      }
    }
  }

  ClassElement _getClassForMethod(MethodDeclaration node) =>
      node.parent.thisOrAncestorOfType<ClassDeclaration>()?.declaredElement;

  bool _hasImmutableAnnotation(ClassElement clazz) {
    final inheritedAndSelfElements = <ClassElement>[
      ...clazz.allSupertypes.map((t) => t.element),
      clazz,
    ];
    final inheritedAndSelfAnnotations = inheritedAndSelfElements
        .expand((c) => c.metadata)
        .map((m) => m.element);
    return inheritedAndSelfAnnotations.any(_isImmutable);
  }
}
