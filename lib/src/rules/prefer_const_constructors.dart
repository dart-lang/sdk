// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart'; // ignore: implementation_imports
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer const with constant constructors.';

const _details = r'''

**PREFER** using `const` for instantiating constant constructors.

If a const constructor is available, it is preferable to use it.

**GOOD:**
```
class A {
  const A();
}

void accessA() {
  A a = const A();
}
```

**GOOD:**
```
class A {
  final int x;

  const A(this.x);
}

A foo(int x) => new A(x);
```

**BAD:**
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
      final typeProvider = node.staticElement.context.typeProvider;
      final declaredVariables = node.staticElement.context.declaredVariables;

      if (node.staticElement.enclosingElement.type == typeProvider.objectType) {
        // Skip lint for `new Object()`, because it can be used for Id creation.
        return;
      }

      final listener = new MyAnalysisErrorListener();

      // put a fake const keyword to use ConstantVerifier
      final oldKeyword = node.keyword;
      node.keyword = new KeywordToken(Keyword.CONST, node.offset);
      try {
        final errorReporter = new ErrorReporter(listener, rule.reporter.source);
        node.accept(new ConstantVerifier(errorReporter,
            node.staticElement.library, typeProvider, declaredVariables));
      } finally {
        // restore old keyword
        node.keyword = oldKeyword;
      }

      if (!listener.hasConstError) {
        rule.reportLint(node);
      }
    }
  }
}

class MyAnalysisErrorListener extends AnalysisErrorListener {
  bool hasConstError = false;
  @override
  void onError(AnalysisError error) {
    switch (error.errorCode) {
      case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL:
      case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING:
      case CompileTimeErrorCode.CONST_EVAL_TYPE_INT:
      case CompileTimeErrorCode.CONST_EVAL_TYPE_NUM:
      case CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION:
      case CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE:
      case CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT:
      case CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER:
      case CompileTimeErrorCode
          .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST:
      case CompileTimeErrorCode.INVALID_CONSTANT:
      case CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL:
        hasConstError = true;
    }
  }
}
