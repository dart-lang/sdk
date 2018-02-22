// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer const over final for declarations.';

const _details = r'''

**PREFER** using `const` for const declarations.

Const declarations are more hot-reload friendly and allow to use const
constructors if an instantiation references this declaration.

**GOOD:**
```
const o = const [];

class A {
  static const o = const [];
}
```

**BAD:**
```
final o = const [];

class A {
  static final o = const [];
}
```

''';

class PreferConstDeclarations extends LintRule {
  _Visitor _visitor;

  PreferConstDeclarations()
      : super(
            name: 'prefer_const_declarations',
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
  visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) return;
    _visitVariableDeclarationList(node.fields);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      _visitVariableDeclarationList(node.variables);

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      _visitVariableDeclarationList(node.variables);

  _visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.isConst) return;
    if (!node.isFinal) return;
    if (node.variables
        .every((declaration) => _isConst(declaration.initializer)))
      rule.reportLint(node);
  }

  bool _isConst(Expression node) {
    final cu = _getCompilationUnit(node);
    final listener = new MyAnalysisErrorListener();
    node.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(cu.element.context.typeProvider,
            cu.element.context.declaredVariables),
        new ErrorReporter(listener, cu.element.source)));
    return !listener.hasConstError;
  }

  CompilationUnit _getCompilationUnit(AstNode node) {
    AstNode result = node;
    while (result is! CompilationUnit) result = result.parent;
    return result;
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
      case CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL:
      case CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER:
      case CompileTimeErrorCode
          .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST:
      case CompileTimeErrorCode.INVALID_CONSTANT:
      case CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL:
        hasConstError = true;
    }
  }
}
