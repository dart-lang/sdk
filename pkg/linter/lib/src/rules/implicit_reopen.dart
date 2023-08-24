// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r"Don't implicitly reopen classes.";

/// todo(pq): link out to (upcoming) dart.dev docs.
/// https://github.com/dart-lang/site-www/issues/4833
const _details = r'''
Using an `interface`, `base`, `final`, or `sealed` modifier on a class,
or a `base` modifier on a mixin,
authors can control whether classes and mixins allow being implemented,
extended, and/or mixed in from outside of the library where they're defined.
In some cases, it's possible for an author to inadvertently relax these controls
and implicitly "reopen" a class. (A similar reopening cannot occur with a mixin.)

This lint guards against unintentionally reopening a class by requiring such
cases to be made explicit with the
[`@reopen`](https://pub.dev/documentation/meta/latest/meta/reopen-constant.html)
annotation in `package:meta`.

**BAD:**
```dart
interface class I {}

class C extends I {} // LINT
```

**GOOD:**
```dart
interface class I {}

final class C extends I {}
```

```dart
import 'package:meta/meta.dart';

interface class I {}

@reopen
class C extends I {}
```
''';

class ImplicitReopen extends LintRule {
  static const LintCode code = LintCode('implicit_reopen',
      "The {0} '{1}' reopens '{2}' because it is not marked '{3}'",
      correctionMessage:
          "Try marking '{1}' '{3}' or annotating it with '@reopen'");

  ImplicitReopen()
      : super(
            name: 'implicit_reopen',
            description: _desc,
            details: _details,
            state: State.experimental(),
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  void checkElement(InterfaceElement? element, NamedCompilationUnitMember node,
      {required String type}) {
    if (element is! ClassElement) return;
    if (element.hasReopen) return;
    if (element.isSealed) return;
    if (element.isMixinClass) return;

    var library = element.library;
    var supertype = element.supertype?.element;
    if (supertype is! ClassElement) return;
    if (supertype.library != library) return;

    if (element.isBase) {
      if (supertype.isFinal) {
        reportLint(node,
            target: element, other: supertype, reason: 'final', type: type);
        return;
      } else if (supertype.isInterface) {
        reportLint(node,
            target: element, other: supertype, reason: 'interface', type: type);
        return;
      }
    } else if (element.hasNoModifiers) {
      if (supertype.isInterface) {
        reportLint(node,
            target: element, other: supertype, reason: 'interface', type: type);
        return;
      }
    }
  }

  void reportLint(
    NamedCompilationUnitMember member, {
    required String type,
    required InterfaceElement target,
    required InterfaceElement other,
    required String reason,
  }) {
    rule.reportLintForToken(member.name,
        arguments: [type, target.name, other.name, reason]);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    checkElement(node.declaredElement, node, type: 'class');
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    checkElement(node.declaredElement, node, type: 'class');
  }
}

extension on ClassElement {
  bool get hasNoModifiers => !isInterface && !isBase && !isSealed && !isFinal;
}
