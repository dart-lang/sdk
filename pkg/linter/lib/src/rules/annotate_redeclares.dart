// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Annotate redeclared members.';

const _details = r'''
**DO** annotate redeclared members.

This practice improves code readability and helps protect against
unintentionally redeclaring members or being surprised when a member ceases to
redeclare (due for example to a rename refactoring).

**BAD:**
```dart
class C {
  void f() { }
}

extension type E(C c) implements C {
  void f() {
    ...
  }
}
```

**GOOD:**
```dart
import 'package:meta/meta.dart';

class C {
  void f() { }
}

extension type E(C c) implements C {
  @redeclare
  void f() {
    ...
  }
}
```
''';

class AnnotateRedeclares extends LintRule {
  static const LintCode code = LintCode('annotate_redeclares',
      "The member '{0}' is redeclaring but isn't annotated with '@redeclare'.",
      correctionMessage: "Try adding the '@redeclare' annotation.");

  AnnotateRedeclares()
      : super(
            name: 'annotate_redeclares',
            description: _desc,
            details: _details,
            group: Group.style,
            state: State.experimental());

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    node.members.whereType<MethodDeclaration>().forEach(_check);
  }

  void _check(MethodDeclaration node) {
    if (node.isStatic) return;
    var parent = node.parent;
    // Shouldn't happen.
    if (parent is! ExtensionTypeDeclaration) return;

    var element = node.declaredElement;
    if (element == null || element.hasRedeclare) return;

    var extensionType = parent.declaredElement;
    if (extensionType == null) return;

    if (_redeclaresMember(element, extensionType)) {
      rule.reportLintForToken(node.name, arguments: [element.displayName]);
    }
  }

  /// Return `true` if the [member] redeclares a member from a superinterface.
  bool _redeclaresMember(
      ExecutableElement member, InterfaceElement extensionType) {
    // TODO(pq): unify with similar logic in `redeclare_verifier` and move to inheritanceManager
    var uri = member.library.source.uri;
    var interface = context.inheritanceManager.getInterface(extensionType);
    return interface.redeclared.containsKey(Name(uri, member.name));
  }
}
