// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Equality operator `==` invocation with references of unrelated types.';

const _details = r'''
**DON'T** Compare references of unrelated types for equality.

Comparing references of a type where neither is a subtype of the other most
likely will return `false` and might not reflect programmer's intent.

`Int64` and `Int32` from `package:fixnum` allow comparing to `int` provided
the `int` is on the right hand side. The lint allows this as a special case. 

**BAD:**
```dart
void someFunction() {
  var x = '1';
  if (x == 1) print('someFunction'); // LINT
}
```

**BAD:**
```dart
void someFunction1() {
  String x = '1';
  if (x == 1) print('someFunction1'); // LINT
}
```

**BAD:**
```dart
void someFunction13(DerivedClass2 instance) {
  var other = DerivedClass3();

  if (other == instance) print('someFunction13'); // LINT
}

class ClassBase {}

class DerivedClass1 extends ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}

class DerivedClass3 extends ClassBase implements Mixin {}
```

**GOOD:**
```dart
void someFunction2() {
  var x = '1';
  var y = '2';
  if (x == y) print(someFunction2); // OK
}
```

**GOOD:**
```dart
void someFunction3() {
  for (var i = 0; i < 10; i++) {
    if (i == 0) print(someFunction3); // OK
  }
}
```

**GOOD:**
```dart
void someFunction4() {
  var x = '1';
  if (x == null) print(someFunction4); // OK
}
```

**GOOD:**
```dart
void someFunction7() {
  List someList;

  if (someList.length == 0) print('someFunction7'); // OK
}
```

**GOOD:**
```dart
void someFunction8(ClassBase instance) {
  DerivedClass1 other;

  if (other == instance) print('someFunction8'); // OK
}
```

**GOOD:**
```dart
void someFunction10(unknown) {
  var what = unknown - 1;
  for (var index = 0; index < unknown; index++) {
    if (what == index) print('someFunction10'); // OK
  }
}
```

**GOOD:**
```dart
void someFunction11(Mixin instance) {
  var other = DerivedClass2();

  if (other == instance) print('someFunction11'); // OK
  if (other != instance) print('!someFunction11'); // OK
}

class ClassBase {}

abstract class Mixin {}

class DerivedClass2 extends ClassBase with Mixin {}
```

''';

class UnrelatedTypeEqualityChecks extends LintRule {
  static const LintCode expressionCode = LintCode(
      'unrelated_type_equality_checks',
      uniqueName: 'LintCode.unrelated_type_equality_checks_expression',
      "The type of the right operand ('{0}') isn't a subtype or a supertype of "
          "the left operand ('{1}').",
      correctionMessage: 'Try changing one or both of the operands.');

  static const LintCode patternCode = LintCode(
      'unrelated_type_equality_checks',
      uniqueName: 'LintCode.unrelated_type_equality_checks_pattern',
      "The type of the operand ('{0}') isn't a subtype or a supertype of the "
          "value being matched ('{1}').",
      correctionMessage: 'Try changing one or both of the operands.');

  UnrelatedTypeEqualityChecks()
      : super(
            name: 'unrelated_type_equality_checks',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  List<LintCode> get lintCodes => [expressionCode, patternCode];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeSystem);
    registry.addBinaryExpression(this, visitor);
    registry.addRelationalPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;

  _Visitor(this.rule, this.typeSystem);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var isDartCoreBoolean = node.staticType?.isDartCoreBool ?? false;
    if (!isDartCoreBoolean || !node.operator.isEqualityTest) {
      return;
    }

    var leftOperand = node.leftOperand;
    if (leftOperand is NullLiteral) return;
    var rightOperand = node.rightOperand;
    if (rightOperand is NullLiteral) return;
    var leftType = leftOperand.staticType;
    if (leftType == null) return;
    var rightType = rightOperand.staticType;
    if (rightType == null) return;

    if (_nonComparable(leftType, rightType)) {
      rule.reportLintForToken(
        node.operator,
        errorCode: UnrelatedTypeEqualityChecks.expressionCode,
        arguments: [
          rightType.getDisplayString(withNullability: true),
          leftType.getDisplayString(withNullability: true),
        ],
      );
    }
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    var valueType = node.matchedValueType;
    if (valueType == null) return;
    if (!node.operator.isEqualityTest) return;
    var operandType = node.operand.staticType;
    if (operandType == null) return;
    if (_nonComparable(valueType, operandType)) {
      rule.reportLint(
        node,
        errorCode: UnrelatedTypeEqualityChecks.patternCode,
        arguments: [
          operandType.getDisplayString(withNullability: true),
          valueType.getDisplayString(withNullability: true),
        ],
      );
    }
  }

  bool _nonComparable(DartType leftType, DartType rightType) =>
      typesAreUnrelated(typeSystem, leftType, rightType) &&
      !(leftType.isFixnumIntX && rightType.isCoreInt);
}

extension on DartType? {
  bool get isCoreInt => this != null && this!.isDartCoreInt;

  bool get isFixnumIntX {
    var self = this;
    // TODO(pq): add tests that ensure this predicate works with fixnum >= 1.1.0-dev
    // See: https://github.com/dart-lang/linter/issues/3868
    if (self is! InterfaceType) return false;
    var element = self.element;
    if (element.name != 'Int32' && element.name != 'Int64') return false;
    var uri = element.library.source.uri;
    if (!uri.isScheme('package')) return false;
    return uri.pathSegments.firstOrNull == 'fixnum';
  }
}

extension on Token {
  bool get isEqualityTest =>
      type == TokenType.EQ_EQ || type == TokenType.BANG_EQ;
}
