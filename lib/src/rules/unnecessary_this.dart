// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/resolver.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r"Don't access members with `this` unless avoiding shadowing.";

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

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

class UnnecessaryThis extends LintRule {
  _Visitor _visitor;
  UnnecessaryThis()
      : super(
            name: 'unnecessary_this',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _UnnecessaryThisVisitor extends ScopedVisitor {
  final LintRule rule;

  _UnnecessaryThisVisitor(this.rule, CompilationUnit node)
      : super(
            node.element.library,
            rule.reporter.source,
            node.element.library.context.typeProvider,
            AnalysisErrorListener.NULL_LISTENER);

  @override
  visitThisExpression(ThisExpression node) {
    final parent = node.parent;
    Element lookUpElement;
    Element localElement;
    if (parent is PropertyAccess) {
      lookUpElement = DartTypeUtilities.getCanonicalElement(
          nameScope.lookup(parent.propertyName, definingLibrary));
      localElement = DartTypeUtilities
          .getCanonicalElement(parent.propertyName.bestElement);
    } else if (parent is MethodInvocation) {
      lookUpElement = DartTypeUtilities.getCanonicalElement(
          nameScope.lookup(parent.methodName, definingLibrary));
      localElement = parent.methodName.bestElement;
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
  }
}

class _Visitor extends SimpleAstVisitor {
  LintRule rule;
  _Visitor(this.rule);

  @override
  visitCompilationUnit(CompilationUnit node) {
    new _UnnecessaryThisVisitor(rule, node).visitCompilationUnit(node);
  }
}
