// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc =
    r'Avoid wrapping fields in getters and setters just to be "safe".';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#dont-wrap-a-field-in-a-getter-and-setter-unnecessarily):

**AVOID** wrapping fields in getters and setters just to be "safe".

In Java and C#, it's common to hide all fields behind getters and setters (or
properties in C#), even if the implementation just forwards to the field.  That
way, if you ever need to do more work in those members, you can do it without needing
to touch the callsites.  This is because calling a getter method is different
than accessing a field in Java, and accessing a property isn't binary-compatible
with accessing a raw field in C#.

Dart doesn't have this limitation.  Fields and getters/setters are completely
indistinguishable.  You can expose a field in a class and later wrap it in a
getter and setter without having to touch any code that uses that field.

**BAD:**
```dart
class Box {
  var _contents;
  get contents => _contents;
  set contents(value) {
    _contents = value;
  }
}
```

**GOOD:**
```dart
class Box {
  var contents;
}
```

''';

class UnnecessaryGettersSetters extends LintRule {
  static const LintCode code = LintCode('unnecessary_getters_setters',
      'Unnecessary use of getter and setter to wrap a field.',
      correctionMessage:
          'Try removing the getter and setter and renaming the field.');

  UnnecessaryGettersSetters()
      : super(
            name: 'unnecessary_getters_setters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _check(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _check(node.members);
  }

  void _check(NodeList<ClassMember> members) {
    var getters = <String, MethodDeclaration>{};
    var setters = <String, MethodDeclaration>{};

    // Build getter/setter maps
    for (var method in members.whereType<MethodDeclaration>()) {
      var methodName = method.name.lexeme;
      if (method.isGetter) {
        getters[methodName] = method;
      } else if (method.isSetter) {
        setters[methodName] = method;
      }
    }

    // Only select getters with setter pairs
    for (var id in getters.keys) {
      _visitGetterSetter(getters[id]!, setters[id]);
    }
  }

  void _visitGetterSetter(MethodDeclaration getter, MethodDeclaration? setter) {
    if (setter == null) return;
    var getterElement = getter.declaredElement;
    var setterElement = setter.declaredElement;
    if (getterElement == null || setterElement == null) return;
    if (isSimpleSetter(setter) &&
        isSimpleGetter(getter) &&
        getterElement.metadata.isEmpty &&
        setterElement.metadata.isEmpty) {
      // Just flag the getter (https://github.com/dart-lang/linter/issues/2851)
      rule.reportLintForToken(getter.name);
    }
  }
}
