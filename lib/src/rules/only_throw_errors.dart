// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r'Only throw instances of classes extending either Exception or Error';

const _details = r'''

**DO** throw only instances of classes that extend `dart.core.Error` or
`dart.core.Exception`.

**BAD:**
```
void throwString() {
  throw 'hello world!'; // LINT
}
```

**GOOD:**
```
void throwArgumentError() {
  Error error = new ArgumentError('oh!');
  throw error; // OK
}
```
''';

const _errorClassName = 'Error';

const _exceptionClassName = 'Exception';

const _library = 'dart.core';
final LinkedHashSet<InterfaceTypeDefinition> _interfaceDefinitions =
    new LinkedHashSet<InterfaceTypeDefinition>.from([
  new InterfaceTypeDefinition(_exceptionClassName, _library),
  new InterfaceTypeDefinition(_errorClassName, _library)
]);
bool _isThrowable(DartType type) =>
    type.isDynamic ||
    DartTypeUtilities.implementsAnyInterface(type, _interfaceDefinitions);

class OnlyThrowErrors extends LintRule {
  _Visitor _visitor;

  OnlyThrowErrors()
      : super(
            name: 'only_throw_errors',
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
  void visitThrowExpression(ThrowExpression node) {
    if (node.expression is Literal) {
      rule.reportLint(node.expression);
      return;
    }

    if (!_isThrowable(node.expression.bestType)) {
      rule.reportLint(node.expression);
    }
  }
}
