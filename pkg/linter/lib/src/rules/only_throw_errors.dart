// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Only throw instances of classes extending either Exception or Error.';

const _details = r'''
**DO** throw only instances of classes that extend `dart.core.Error` or
`dart.core.Exception`.

Throwing instances that do not extend `Error` or `Exception` is a bad practice;
doing this is usually a hack for something that should be implemented more
thoroughly.

**BAD:**
```dart
void throwString() {
  throw 'hello world!'; // LINT
}
```

**GOOD:**
```dart
void throwArgumentError() {
  Error error = ArgumentError('oh!');
  throw error; // OK
}
```

''';

const _errorClassName = 'Error';

const _exceptionClassName = 'Exception';

const _library = 'dart.core';

final LinkedHashSet<InterfaceTypeDefinition> _interfaceDefinitions =
    LinkedHashSet.of([
  InterfaceTypeDefinition(_exceptionClassName, _library),
  InterfaceTypeDefinition(_errorClassName, _library),
]);

bool _isThrowable(DartType? type) {
  var typeForInterfaceCheck = type?.typeForInterfaceCheck;
  return typeForInterfaceCheck == null ||
      typeForInterfaceCheck is DynamicType ||
      type is NeverType ||
      typeForInterfaceCheck.implementsAnyInterface(_interfaceDefinitions);
}

class OnlyThrowErrors extends LintRule {
  OnlyThrowErrors()
      : super(
          name: 'only_throw_errors',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.only_throw_errors;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (node.expression is Literal) {
      rule.reportLint(node.expression);
      return;
    }

    if (!_isThrowable(node.expression.staticType)) {
      rule.reportLint(node.expression);
    }
  }
}
