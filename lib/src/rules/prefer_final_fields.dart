// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Private field could be final.';

const _details = r'''
**DO** prefer declaring private fields as final if they are not reassigned later
in the library.

Declaring fields as final when possible is a good practice because it helps
avoid accidental reassignments and allows the compiler to do optimizations.

**BAD:**
```dart
class BadImmutable {
  var _label = 'hola mundo! BadImmutable'; // LINT
  var label = 'hola mundo! BadImmutable'; // OK
}
```

**BAD:**
```dart
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
```dart
class GoodImmutable {
  final label = 'hola mundo! BadImmutable', bla = 5; // OK
  final _label = 'hola mundo! BadImmutable', _bla = 5; // OK
}
```

**GOOD:**
```dart
class GoodMutable {
  var _label = 'hola mundo! GoodMutable';

  void changeLabel() {
    _label = 'hello world! GoodMutable';
  }
}
```

**BAD:**
```dart
class AssignedInAllConstructors {
  var _label; // LINT
  AssignedInAllConstructors(this._label);
  AssignedInAllConstructors.withDefault() : _label = 'Hello';
}
```

**GOOD:**
```dart
class NotAssignedInAllConstructors {
  var _label; // OK
  NotAssignedInAllConstructors();
  NotAssignedInAllConstructors.withDefault() : _label = 'Hello';
}
```
''';

class PreferFinalFields extends LintRule {
  static const LintCode code = LintCode(
      'prefer_final_fields', "The private field {0} could be 'final'.",
      correctionMessage: "Try making the field 'final'.");

  PreferFinalFields()
      : super(
            name: 'prefer_final_fields',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _DeclarationsCollector extends RecursiveAstVisitor<void> {
  final fields = <FieldElement, VariableDeclaration>{};

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isInvalidExtensionTypeField) return;
    if (node.parent is EnumDeclaration) return;
    if (node.fields.isFinal || node.fields.isConst) {
      return;
    }

    for (var variable in node.fields.variables) {
      var element = variable.declaredElement;
      if (element is FieldElement &&
          element.isPrivate &&
          !element.overridesField) {
        fields[element] = variable;
      }
    }
  }
}

class _FieldMutationFinder extends RecursiveAstVisitor<void> {
  /// The collection of fields declared in this library.
  ///
  /// This visitor removes a field when it finds that it is assigned anywhere.
  final Map<FieldElement, VariableDeclaration> _fields;

  _FieldMutationFinder(this._fields);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _addMutatedFieldElement(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _addMutatedFieldElement(node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var operator = node.operator;
    if (operator.type == TokenType.MINUS_MINUS ||
        operator.type == TokenType.PLUS_PLUS) {
      _addMutatedFieldElement(node);
    }
    super.visitPrefixExpression(node);
  }

  void _addMutatedFieldElement(CompoundAssignmentExpression assignment) {
    var element = assignment.writeElement?.canonicalElement;
    if (element is FieldElement) {
      _fields.remove(element);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var declarationsCollector = _DeclarationsCollector();
    node.accept(declarationsCollector);
    var fields = declarationsCollector.fields;

    var fieldMutationFinder = _FieldMutationFinder(fields);
    for (var unit in context.allUnits) {
      unit.unit.accept(fieldMutationFinder);
    }

    for (var MapEntry(key: field, value: variable) in fields.entries) {
      // TODO(srawlins): We could look at the constructors once and store a set
      // of which fields are initialized by any, and a set of which fields are
      // initialized by all. This would conceivably improve performance.
      var classDeclaration = variable.parent?.parent?.parent;
      var constructors = classDeclaration is ClassDeclaration
          ? classDeclaration.members.whereType<ConstructorDeclaration>()
          : <ConstructorDeclaration>[];

      var isSetInAnyConstructor = constructors
          .any((constructor) => field.isSetInConstructor(constructor));

      if (isSetInAnyConstructor) {
        var isSetInEveryConstructor = constructors
            .every((constructor) => field.isSetInConstructor(constructor));

        if (isSetInEveryConstructor) {
          rule.reportLint(variable, arguments: [variable.name.lexeme]);
        }
      } else if (field.hasInitializer) {
        rule.reportLint(variable, arguments: [variable.name.lexeme]);
      }
    }
  }
}

extension on VariableElement {
  bool get overridesField {
    var enclosingElement = this.enclosingElement;
    if (enclosingElement is! InterfaceElement) return false;

    var library = this.library;
    if (library == null) return false;

    return enclosingElement.thisType
            .lookUpSetter2(name, inherited: true, library) !=
        null;
  }

  bool isSetInConstructor(ConstructorDeclaration constructor) =>
      constructor.initializers.any(isSetInInitializer) ||
      constructor.parameters.parameters.any(isSetInParameter);

  /// Whether `this` is initialized in [initializer].
  bool isSetInInitializer(ConstructorInitializer initializer) =>
      initializer is ConstructorFieldInitializer &&
      initializer.fieldName.canonicalElement == this;

  /// Whether `this` is initialized with [parameter].
  bool isSetInParameter(FormalParameter parameter) {
    var formalField = parameter.declaredElement;
    return formalField is FieldFormalParameterElement &&
        formalField.field == this;
  }
}
