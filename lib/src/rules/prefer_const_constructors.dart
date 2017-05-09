// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer const with constant constructors.';

const _details = r'''
**DO** prefer `const` for instantiating constant constructors.

**GOOD**
```
class A {
  const A();
}

void accessA() {
  A a = const A();
}
```

**GOOD**
```
class A {
  final int x;

  const A(this.x);
}

A foo(int x) => new A(x);
```

**BAD**
```
class A {
  const A();
}

void accessA() {
  A a = new A();
}
```
''';

class PreferConstConstructors extends LintRule {
  _Visitor _visitor;

  PreferConstConstructors()
      : super(
            name: 'prefer_const_constructors',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!node.isConst &&
        node.staticElement != null &&
        node.staticElement.isConst) {
      TypeProvider typeProvider = node.staticElement.context.typeProvider;

      if (node.staticElement.enclosingElement.type == typeProvider.objectType) {
        // Skip lint for `new Object()`, because it can be used for Id creation.
        return;
      }

      TypeSystem typeSystem = node.staticElement.context.typeSystem;
      DeclaredVariables declaredVariables =
          node.staticElement.context.declaredVariables;

      final ConstantVisitor constantVisitor = new ConstantVisitor(
          new ConstantEvaluationEngine(typeProvider, declaredVariables,
              typeSystem: typeSystem),
          new ErrorReporter(
              AnalysisErrorListener.NULL_LISTENER, rule.reporter.source));

      bool allConst = node.argumentList.arguments.every((Expression argument) {
        Expression realArgument =
            argument is NamedExpression ? argument.expression : argument;
        DartObjectImpl result = realArgument.accept(constantVisitor);

        return result != null;
      });

      if (allConst) {
        rule.reportLint(node);
      }
    }
  }
}
