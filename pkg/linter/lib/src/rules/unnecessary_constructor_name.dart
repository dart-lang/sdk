// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary `.new` constructor name.';

const _details = r'''
**PREFER** using the default unnamed Constructor over `.new`.

Given a class `C`, the named unnamed constructor `C.new` refers to the same
constructor as the unnamed `C`. As such it adds nothing but visual noise to
invocations and should be avoided (unless being used to identify a constructor
tear-off).

**BAD:**
```dart
class A {
  A.new(); // LINT
}

var a = A.new(); // LINT
```

**GOOD:**
```dart
class A {
  A.ok();
}

var a = A();
var aa = A.ok();
var makeA = A.new;
```
''';

class UnnecessaryConstructorName extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_constructor_name', "Unnecessary '.new' constructor name.",
      correctionMessage: "Try removing the '.new'.");

  UnnecessaryConstructorName()
      : super(
            name: 'unnecessary_constructor_name',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addRepresentationConstructorName(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var parent = node.parent;
    if (parent is ExtensionTypeDeclaration &&
        parent.representation.constructorName == null) {
      return;
    }

    _check(node.name);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.constructorName.name?.token);
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    _check(node.name);
  }

  void _check(Token? name) {
    if (name?.lexeme == 'new') {
      rule.reportLintForToken(name);
    }
  }
}
