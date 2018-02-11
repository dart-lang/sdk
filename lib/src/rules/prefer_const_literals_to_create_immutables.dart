// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_const_literals_to_create_immutables;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstVisitor;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:linter/src/analyzer.dart';

const desc =
    'Prefer use const literals as parameter of constructors on @immutable classes.';

const details = '''

**PREFER** using `const` for instantiating list and map literal used as
parameters in immutable class instantiations.

**BAD:**
```
@immutable
class A {
  A(this.v);
  final v;
}

A a1 = new A([1]);
A a2 = new A({});
```

**GOOD:**
```
A a1 = new A(const [1]);
A a2 = new A(const {});
```

''';

/// The name of the top-level variable used to mark a immutable class.
String _IMMUTABLE_VAR_NAME = 'immutable';

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = 'meta';

bool _isImmutable(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _IMMUTABLE_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

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
      case CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT:
      case CompileTimeErrorCode.NON_CONSTANT_MAP_KEY:
      case CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE:
      case CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER:
      case CompileTimeErrorCode
          .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST:
      case CompileTimeErrorCode.INVALID_CONSTANT:
      case CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL:
        hasConstError = true;
    }
  }
}

class PreferConstLiteralsToCreateImmutables extends LintRule {
  PreferConstLiteralsToCreateImmutables()
      : super(
            name: 'prefer_const_literals_to_create_immutables',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  void visitListLiteral(ListLiteral node) => _visitTypedLiteral(node);

  @override
  void visitMapLiteral(MapLiteral node) => _visitTypedLiteral(node);

  Iterable<InterfaceType> _getSelfAndInheritedTypes(InterfaceType type) sync* {
    InterfaceType current = type;
    while (current != null) {
      yield current;
      current = current.superclass;
    }
  }

  bool _hasImmutableAnnotation(ClassElement clazz) {
    final inheritedAndSelfTypes = _getSelfAndInheritedTypes(clazz.type);
    final inheritedAndSelfAnnotations = inheritedAndSelfTypes
        .map((type) => type.element)
        .expand((c) => c.metadata)
        .map((m) => m.element);
    return inheritedAndSelfAnnotations.any(_isImmutable);
  }

  void _visitTypedLiteral(TypedLiteral literal) {
    if (literal.isConst) return;

    // looking for parent instance creation to check if class is immutable
    var node = literal;
    while (node is! InstanceCreationExpression &&
        (node is ParenthesizedExpression ||
            node is ArgumentList ||
            node is ListLiteral ||
            node is MapLiteral ||
            node is MapLiteralEntry ||
            node is NamedExpression)) {
      node = node.parent;
    }
    if (!(node is InstanceCreationExpression &&
        _hasImmutableAnnotation(node.bestType.element))) {
      return;
    }

    final element = literal.bestType.element;
    final typeProvider = element.context.typeProvider;
    final declaredVariables = element.context.declaredVariables;
    final listener = new MyAnalysisErrorListener();

    // put a fake const keyword to use ConstantVerifier
    final oldKeyword = literal.constKeyword;
    literal.constKeyword = new KeywordToken(Keyword.CONST, node.offset);
    try {
      final errorReporter = new ErrorReporter(listener, rule.reporter.source);
      literal.accept(new ConstantVerifier(
          errorReporter, element.library, typeProvider, declaredVariables));
    } finally {
      // restore old keyword
      literal.constKeyword = oldKeyword;
    }

    if (!listener.hasConstError) {
      rule.reportLint(literal);
    }
  }
}
