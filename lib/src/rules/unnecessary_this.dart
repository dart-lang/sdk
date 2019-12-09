// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r"Don't access members with `this` unless avoiding shadowing.";

const _details = r'''

From the [style guide](https://dart.dev/guides/language/effective-dart/style/):

**DON'T** use `this` when not needed to avoid shadowing.

**BAD:**
```
class Box {
  var value;
  void update(new_value) {
    this.value = new_value;
  }
}
```

**GOOD:**
```
class Box {
  var value;
  void update(new_value) {
    value = new_value;
  }
}
```

**GOOD:**
```
class Box {
  var value;
  void update(value) {
    this.value = value;
  }
}
```

''';

class UnnecessaryThis extends LintRule implements NodeLintRule {
  UnnecessaryThis()
      : super(
            name: 'unnecessary_this',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addConstructorFieldInitializer(this, visitor);
  }
}

// todo (pq): refactor to not use scoped visitor
class _UnnecessaryThisVisitor extends ScopedVisitor {
  final LintRule rule;

  _UnnecessaryThisVisitor(
      this.rule, LinterContext context, CompilationUnit node)
      : super(
          node.declaredElement.library,
          rule.reporter.source,
          context.typeProvider as TypeProviderImpl,
          AnalysisErrorListener.NULL_LISTENER,
        );

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.thisKeyword != null) {
      rule.reportLintForToken(node.thisKeyword);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    final parent = node.parent;
    Element lookUpElement;
    Element localElement;
    if (parent is PropertyAccess) {
      lookUpElement = DartTypeUtilities.getCanonicalElement(
          nameScope.lookup(parent.propertyName, definingLibrary));
      localElement = DartTypeUtilities.getCanonicalElement(
          parent.propertyName.staticElement);
    } else if (parent is MethodInvocation) {
      lookUpElement = DartTypeUtilities.getCanonicalElement(
          nameScope.lookup(parent.methodName, definingLibrary));
      localElement = parent.methodName.staticElement;
    }

    // Error in code
    if (localElement == null) {
      return null;
    }
    // If localElement was resolved, but lookUpElement was not, that means
    // the element is defined in an ancestor class.
    if (lookUpElement == localElement || lookUpElement == null) {
      rule.reportLint(parent);
    }
    return null;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _UnnecessaryThisVisitor(rule, context, node).visitCompilationUnit(node);
  }
}
