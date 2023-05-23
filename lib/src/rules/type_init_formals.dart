// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = "Don't type annotate initializing formals.";

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/design#dont-type-annotate-initializing-formals):

**DON'T** type annotate initializing formals.

If a constructor parameter is using `this.x` to initialize a field, then the
type of the parameter is understood to be the same type as the field. If a 
a constructor parameter is using `super.x` to forward to a super constructor,
then the type of the parameter is understood to be the same as the super
constructor parameter.

Type annotating an initializing formal with a different type than that of the
field is OK.

**BAD:**
```dart
class Point {
  int x, y;
  Point(int this.x, int this.y);
}
```

**GOOD:**
```dart
class Point {
  int x, y;
  Point(this.x, this.y);
}
```

**BAD:**
```dart
class A {
  int a;
  A(this.a);
}

class B extends A {
  B(int super.a);
}
```

**GOOD:**
```dart
class A {
  int a;
  A(this.a);
}

class B extends A {
  B(super.a);
}
```

''';

class TypeInitFormals extends LintRule {
  static const LintCode code = LintCode('type_init_formals',
      "Don't needlessly type annotate initializing formals.",
      correctionMessage: 'Try removing the type.');

  TypeInitFormals()
      : super(
            name: 'type_init_formals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldFormalParameter(this, visitor);
    registry.addSuperFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var nodeType = node.type;
    if (nodeType == null) return;

    var paramElement = node.declaredElement;
    if (paramElement is! FieldFormalParameterElement) return;

    var field = paramElement.field;
    // If no such field exists, the code is invalid; do not report lint.
    if (field != null && nodeType.type == field.type) {
      rule.reportLint(nodeType);
    }
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    var nodeType = node.type;
    if (nodeType == null) return;

    var paramElement = node.declaredElement;
    if (paramElement is! SuperFormalParameterElement) return;

    var superConstructorParameter = paramElement.superConstructorParameter;
    if (superConstructorParameter == null) return;

    if (superConstructorParameter.type == nodeType.type) {
      rule.reportLint(nodeType);
    }
  }
}
