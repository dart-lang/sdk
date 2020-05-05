// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Define case clauses for all constants in enum-like classes.';

const _details = r'''
Switching on instances of enum-like classes should be exhaustive.

Enum-like classes are defined as concrete (non-abstract) classes that have:
  * only private non-factory constructors
  * two or more static const fields whose type is the enclosing class and
  * no subclasses of the class in the defining library

**DO** define case clauses for all constants in enum-like classes.

**BAD:**
```
class EnumLike {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void bad(EnumLike e) {
  // Missing case.
  switch(e) { // LINT
    case E.e :
      print('e');
      break;
    case E.f :
      print('e');
      break;
  }
}
```

**GOOD:**
```
class EnumLike {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void ok(E e) {
  // All cases covered.
  switch(e) { // OK
    case E.e :
      print('e');
      break;
    case E.f :
      print('e');
      break;
    case E.g :
      print('e');
      break;
  }
}
```
''';

class ExhaustiveCases extends LintRule implements NodeLintRule {
  ExhaustiveCases()
      : super(
            name: 'exhaustive_cases',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  static const LintCode lintCode = LintCode(
    'exhaustive_cases',
    "Missing case clause for '{0}'.",
    correction: 'Try adding a case clause for the missing constant.',
  );

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement statement) {
    var expressionType = statement.expression.staticType;
    if (expressionType is InterfaceType) {
      var classElement = expressionType.element;
      // Handled in analyzer.
      if (classElement.isEnum) {
        return;
      }
      var enumDescription = DartTypeUtilities.asEnumLikeClass(classElement);
      if (enumDescription == null) {
        return;
      }

      var enumConstantNames = enumDescription.enumConstantNames;
      for (var member in statement.members) {
        if (member is SwitchCase) {
          var expression = member.expression;
          if (expression is Identifier) {
            var element = expression.staticElement;
            if (element is PropertyAccessorElement) {
              enumConstantNames.remove(element.name);
            }
          } else if (expression is PropertyAccess) {
            enumConstantNames.remove(expression.propertyName.name);
          }
        }
      }

      for (var constantName in enumConstantNames) {
        // Use the same offset as MISSING_ENUM_CONSTANT_IN_SWITCH
        var offset = statement.offset;
        var end = statement.rightParenthesis.end;
        // todo (pq): update to use reportLintForOffset when published (> 0.39.8)
        rule.reporter.reportErrorForOffset(
          lintCode,
          offset,
          end - offset,
          [constantName],
        );
      }
    }
  }
}
