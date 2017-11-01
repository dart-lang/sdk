// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r'Equality operator `==` invocation with references of unrelated types.';

const _details = r'''

**DON'T** Compare references of unrelated types for equality.

Comparing references of a type where neither is a subtype of the other most
likely will return `false` and might not reflect programmer's intent.

**BAD:**
```
void someFunction() {
  var x = '1';
  if (x == 1) print('someFunction'); // LINT
}
```

**BAD:**
```
void someFunction1() {
  String x = '1';
  if (x == 1) print('someFunction1'); // LINT
}
```

**BAD:**
```
void someFunction13(DerivedClass2 instance) {
  var other = new DerivedClass3();

  if (other == instance) print('someFunction13'); // LINT
}

class ClassBase {}

class DerivedClass1 extends ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}

class DerivedClass3 extends ClassBase implements Mixin {}
```

**GOOD:**
```
void someFunction2() {
  var x = '1';
  var y = '2';
  if (x == y) print(someFunction2); // OK
}
```

**GOOD:**
```
void someFunction3() {
  for (var i = 0; i < 10; i++) {
    if (i == 0) print(someFunction3); // OK
  }
}
```

**GOOD:**
```
void someFunction4() {
  var x = '1';
  if (x == null) print(someFunction4); // OK
}
```

**GOOD:**
```
void someFunction7() {
  List someList;

  if (someList.length == 0) print('someFunction7'); // OK
}
```

**GOOD:**
```
void someFunction8(ClassBase instance) {
  DerivedClass1 other;

  if (other == instance) print('someFunction8'); // OK
}
```

**GOOD:**
```
void someFunction10(unknown) {
  var what = unknown - 1;
  for (var index = 0; index < unknown; index++) {
    if (what == index) print('someFunction10'); // OK
  }
}
```

**GOOD:**
```
void someFunction11(Mixin instance) {
  var other = new DerivedClass2();

  if (other == instance) print('someFunction11'); // OK
  if (other != instance) print('!someFunction11'); // OK
}

class ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}
```

''';

bool _hasNonComparableOperands(BinaryExpression node) =>
    !DartTypeUtilities.isNullLiteral(node.leftOperand) &&
    !DartTypeUtilities.isNullLiteral(node.rightOperand) &&
    DartTypeUtilities.unrelatedTypes(
        node.leftOperand.bestType, node.rightOperand.bestType);

class UnrelatedTypeEqualityChecks extends LintRule {
  _Visitor _visitor;

  UnrelatedTypeEqualityChecks()
      : super(
            name: 'unrelated_type_equality_checks',
            description: _desc,
            details: _details,
            group: Group.errors) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  static const String _dartCoreLibraryName = 'dart.core';
  static const String _boolClassName = 'bool';

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    bool isDartCoreBoolean =
        resolutionMap.bestTypeForExpression(node).name == _boolClassName &&
            resolutionMap.bestTypeForExpression(node).element?.library?.name ==
                _dartCoreLibraryName;
    if (!isDartCoreBoolean ||
        (node.operator.type != TokenType.EQ_EQ &&
            node.operator.type != TokenType.BANG_EQ)) {
      return;
    }

    if (_hasNonComparableOperands(node)) {
      rule.reportLint(node);
    }
  }
}
