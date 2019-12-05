// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Private field could be final.';

const _details = r'''

**DO** prefer declaring private fields as final if they are not reassigned later
in the class.

Declaring fields as final when possible is a good practice because it helps
avoid accidental reassignments and allows the compiler to do optimizations.

**BAD:**
```
class BadImmutable {
  var _label = 'hola mundo! BadImmutable'; // LINT
  var label = 'hola mundo! BadImmutable'; // OK
}
```

**BAD:**
```
class MultipleMutable {
  var _label = 'hola mundo! GoodMutable', _offender = 'mumble mumble!'; // LINT
  var _someOther; // LINT

  MultipleMutable() : _someOther = 5;

  MultipleMutable(this._someOther);

  void changeLabel() {
    _label= 'hello world! GoodMutable';
  }
}
```

**GOOD:**
```
class GoodImmutable {
  final label = 'hola mundo! BadImmutable', bla = 5; // OK
  final _label = 'hola mundo! BadImmutable', _bla = 5; // OK
}
```

**GOOD:**
```
class GoodMutable {
  var _label = 'hola mundo! GoodMutable';

  void changeLabel() {
    _label = 'hello world! GoodMutable';
  }
}
```

**BAD:**
```
class AssignedInAllConstructors {
  var _label; // LINT
  AssignedInAllConstructors(this._label);
  AssignedInAllConstructors.withDefault() : _label = 'Hello';
}
```

**GOOD:**
```
class NotAssignedInAllConstructors {
  var _label; // OK
  NotAssignedInAllConstructors();
  NotAssignedInAllConstructors.withDefault() : _label = 'Hello';
}
```
''';

bool _containedInFormal(Element element, FormalParameter formal) {
  final formalField = formal.identifier.staticElement;
  return formalField is FieldFormalParameterElement &&
      formalField.field == element;
}

bool _containedInInitializer(
        Element element, ConstructorInitializer initializer) =>
    initializer is ConstructorFieldInitializer &&
    DartTypeUtilities.getCanonicalElementFromIdentifier(
            initializer.fieldName) ==
        element;

class PreferFinalFields extends LintRule implements NodeLintRule {
  PreferFinalFields()
      : super(
            name: 'prefer_final_fields',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _MutatedFieldsCollector extends RecursiveAstVisitor<void> {
  final Set<FieldElement> _mutatedFields;

  _MutatedFieldsCollector(this._mutatedFields);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _addMutatedFieldElement(node.leftHandSide);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _addMutatedFieldElement(node.operand);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final operator = node.operator;
    if (operator.type == TokenType.MINUS_MINUS ||
        operator.type == TokenType.PLUS_PLUS) {
      _addMutatedFieldElement(node.operand);
    }
    super.visitPrefixExpression(node);
  }

  void _addMutatedFieldElement(Expression expression) {
    final element =
        DartTypeUtilities.getCanonicalElementFromIdentifier(expression);
    if (element is FieldElement) {
      _mutatedFields.add(element);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final Set<FieldElement> _mutatedFields = HashSet<FieldElement>();

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.accept(_MutatedFieldsCollector(_mutatedFields));
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final fields = node.fields;
    if (fields.isFinal || fields.isConst) {
      return;
    }

    for (var variable in fields.variables) {
      final element = variable.declaredElement;

      if (element.isPrivate && !_mutatedFields.contains(element)) {
        bool fieldInConstructor(ConstructorDeclaration constructor) =>
            constructor.initializers.any((ConstructorInitializer initializer) =>
                _containedInInitializer(element, initializer)) ||
            constructor.parameters.parameters.any((FormalParameter formal) =>
                _containedInFormal(element, formal));

        final classDeclaration = node.parent;
        final constructors = classDeclaration is ClassDeclaration
            ? classDeclaration.members.whereType<ConstructorDeclaration>()
            : <ConstructorDeclaration>[];
        final isFieldInConstructors = constructors.any(fieldInConstructor);
        final isFieldInAllConstructors = constructors.every(fieldInConstructor);

        if (isFieldInConstructors) {
          if (isFieldInAllConstructors) {
            rule.reportLint(variable);
          }
        } else if (element.initializer != null) {
          rule.reportLint(variable);
        }
      }
    }
  }
}
