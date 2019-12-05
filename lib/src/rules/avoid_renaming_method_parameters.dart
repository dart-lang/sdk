// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r"Don't rename parameters of overridden methods.";

const _details = r'''**DON'T** rename parameters of overridden methods.

Methods that override another method, but do not have their own documentation
comment, will inherit the overridden method's comment when dartdoc produces
documentation. If the inherited method contains the name of the parameter (in
square brackets), then dartdoc cannot link it correctly.

**BAD:**
```
abstract class A {
  m(a);
}

abstract class B extends A {
  m(b);
}
```

**GOOD:**
```
abstract class A {
  m(a);
}

abstract class B extends A {
  m(a);
}
```

''';

class AvoidRenamingMethodParameters extends LintRule implements NodeLintRule {
  AvoidRenamingMethodParameters()
      : super(
            name: 'avoid_renaming_method_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  /// Tracks if we are in a compilation unit within a `lib/` dir so we can
  /// short-circuit needless checking of method declarations.
  bool isInLib;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    isInLib = isInLibDir(node, context.package);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!isInLib) return;

    if (node.isStatic) return;
    if (node.documentationComment != null) return;

    final parentNode = node.parent as Declaration;
    final parentElement = parentNode.declaredElement;
    // Note: there are no override semantics with extension methods.
    if (parentElement is! ClassElement) {
      return;
    }

    final classElement = parentElement as ClassElement;

    if (classElement.isPrivate) return;

    final parentMethod = classElement.lookUpInheritedMethod(
        node.name.name, classElement.library);

    if (parentMethod == null) return;

    final parameters =
        node.parameters.parameters.where((p) => !p.isNamed).toList();
    final parentParameters =
        parentMethod.parameters.where((p) => !p.isNamed).toList();
    final count = math.min(parameters.length, parentParameters.length);
    for (var i = 0; i < count; i++) {
      if (parentParameters.length <= i) break;
      if (parameters[i].identifier.name != parentParameters[i].name) {
        rule.reportLint(parameters[i].identifier);
      }
    }
  }
}
