// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

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

''';

class PreferFinalFields extends LintRule implements NodeLintRule {
  PreferFinalFields()
      : super(
            name: 'prefer_final_fields',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
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
    _addMutatedFieldElement(node.operand);
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

  final Set<FieldElement> _mutatedFields = new HashSet<FieldElement>();

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.accept(new _MutatedFieldsCollector(_mutatedFields));
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final fields = node.fields;
    if (fields.isFinal || fields.isConst) {
      return;
    }

    fields.variables.forEach((VariableDeclaration variable) {
      final element = variable.element;
      if (!element.isPrivate) {
        return;
      }

      if (variable.initializer == null) {
        return;
      }

      if (_mutatedFields.contains(element)) {
        return;
      }

      rule.reportLint(variable);
    });
  }
}
