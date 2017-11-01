// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_const_constructors_in_immutables;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart'; // ignore: implementation_imports
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer declare const constructors on `@immutable` classes.';

const _details = r'''

**PREFER** declaring const constructors on `@immutable` classes.

If a class is immutable, it is usually a good idea to make its constructor a
const constructor.

**GOOD:**
```
@immutable
class A {
  final a;
  const A(this.a);
}
```

**BAD:**
```
@immutable
class A {
  final a;
  A(this.a);
}
```

''';

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = 'meta';

/// The name of the top-level variable used to mark a immutable class.
String _IMMUTABLE_VAR_NAME = 'immutable';

bool _isImmutable(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _IMMUTABLE_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

class PreferConstConstructorsInImmutables extends LintRule {
  PreferConstConstructorsInImmutables()
      : super(
            name: 'prefer_const_constructors_in_immutables',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    final isRedirected =
        node.element.isFactory && node.element.redirectedConstructor != null;
    if (node.body is EmptyFunctionBody &&
        !node.element.isConst &&
        !_hasMixin(node.element.enclosingElement) &&
        _hasImmutableAnnotation(node.element.enclosingElement) &&
        (isRedirected && node.element.redirectedConstructor.isConst ||
            (!isRedirected &&
                _hasConstConstructorInvocation(node) &&
                _hasOnlyConstExpressionsInIntializerList(node)))) {
      rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata);
    }
  }

  bool _hasMixin(ClassElement clazz) => clazz.mixins.isNotEmpty;

  bool _hasImmutableAnnotation(ClassElement clazz) {
    final inheritedAndSelfTypes = _getSelfAndInheritedTypes(clazz.type);
    final inheritedAndSelfAnnotations = inheritedAndSelfTypes
        .map((type) => type.element)
        .expand((c) => c.metadata)
        .map((m) => m.element);
    return inheritedAndSelfAnnotations.any(_isImmutable);
  }

  bool _hasConstConstructorInvocation(ConstructorDeclaration node) {
    final clazz = node.element.enclosingElement;
    // construct with super
    final SuperConstructorInvocation superInvocation = node.initializers
        .firstWhere((e) => e is SuperConstructorInvocation, orElse: () => null);
    if (superInvocation != null) return superInvocation.staticElement.isConst;
    // construct with this
    final RedirectingConstructorInvocation redirectInvocation = node
        .initializers
        .firstWhere((e) => e is RedirectingConstructorInvocation,
            orElse: () => null);
    if (redirectInvocation != null)
      return redirectInvocation.staticElement.isConst;
    // construct with implicit super()
    return clazz.supertype.constructors
        .firstWhere((e) => e.name.isEmpty)
        .isConst;
  }

  bool _hasOnlyConstExpressionsInIntializerList(ConstructorDeclaration node) {
    final typeProvider = node.element.context.typeProvider;
    final declaredVariables = node.element.context.declaredVariables;

    final listener = new MyAnalysisErrorListener();

    // put a fake const keyword to use ConstantVerifier
    node.constKeyword = new KeywordToken(Keyword.CONST, node.offset);
    try {
      final errorReporter = new ErrorReporter(listener, rule.reporter.source);
      node.accept(new ConstantVerifier(errorReporter, node.element.library,
          typeProvider, declaredVariables));
    } finally {
      // restore const keyword
      node.constKeyword = null;
    }

    return !listener.hasConstError;
  }

  Iterable<InterfaceType> _getSelfAndInheritedTypes(InterfaceType type) sync* {
    InterfaceType current = type;
    while (current != null) {
      yield current;
      current = current.superclass;
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
      case CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER:
      case CompileTimeErrorCode
          .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST:
      case CompileTimeErrorCode.INVALID_CONSTANT:
        hasConstError = true;
    }
  }
}
