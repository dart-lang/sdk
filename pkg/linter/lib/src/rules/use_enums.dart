// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Use enums rather than classes that behave like enums.';

const _details = r'''
Classes that look like enumerations should be declared as `enum`s.

**DO** use enums where appropriate.

Candidates for enums are classes that:

  * are concrete,
  * are private or have only private generative constructors,
  * have two or more static const fields with the same type as the class,
  * have generative constructors that are only invoked at the top-level of the
    initialization expression of these static fields,
  * do not define `hashCode`, `==`, `values` or `index`,
  * do not extend any class other than `Object`, and
  * have no subclasses declared in the defining library.

To learn more about creating and using these enums, check out
[Declaring enhanced enums](https://dart.dev/language/enums#declaring-enhanced-enums).

**BAD:**
```dart
class LogPriority {
  static const error = LogPriority._(1, 'Error');
  static const warning = LogPriority._(2, 'Warning');
  static const log = LogPriority._unknown('Log');

  final String prefix;
  final int priority;
  const LogPriority._(this.priority, this.prefix);
  const LogPriority._unknown(String prefix) : this._(-1, prefix);
}
```

**GOOD:**
```dart
enum LogPriority {
  error(1, 'Error'),
  warning(2, 'Warning'),
  log.unknown('Log');

  final String prefix;
  final int priority;
  const LogPriority(this.priority, this.prefix);
  const LogPriority.unknown(String prefix) : this(-1, prefix);
}
```
''';

class UseEnums extends LintRule {
  static const LintCode code = LintCode('use_enums', 'Class should be an enum.',
      correctionMessage: 'Try using an enum rather than a class.');

  UseEnums()
      : super(
            name: 'use_enums',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.enhanced_enums)) return;

    var visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

/// A superclass for the [_EnumVisitor] and [_NonEnumVisitor].
class _BaseVisitor extends RecursiveAstVisitor<void> {
  /// The element representing the enum declaration that's being visited.
  final ClassElement classElement;

  _BaseVisitor(this.classElement);

  /// Return `true` if the given [node] is an invocation of a generative
  /// constructor from the class being converted.
  bool invokesGenerativeConstructor(InstanceCreationExpression node) {
    var constructorElement = node.constructorName.staticElement;
    return constructorElement != null &&
        !constructorElement.isFactory &&
        constructorElement.enclosingElement == classElement;
  }
}

/// A visitor used to visit the class being linted. This visitor throws an
/// exception if a constructor for the class is invoked anywhere other than the
/// top-level expression of an initializer for one of the fields being converted.
///
/// Note: copied and modified from server.
class _EnumVisitor extends _BaseVisitor {
  /// A flag indicating whether we are currently visiting the children of a
  /// field declaration that will be converted to be a constant.
  bool inConstantDeclaration = false;

  List<VariableDeclaration> variableDeclarations;

  _EnumVisitor(super.classElement, this.variableDeclarations);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!inConstantDeclaration) {
      if (invokesGenerativeConstructor(node)) {
        throw _InvalidEnumException();
      }
    }
    inConstantDeclaration = false;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (variableDeclarations.contains(node)) {
      inConstantDeclaration = true;
    }
    super.visitVariableDeclaration(node);
    inConstantDeclaration = false;
  }
}

/// Note: copied and modified from server.
class _InvalidEnumException implements Exception {}

/// A visitor that visits everything in the library other than the class being
/// linted. This visitor throws an exception if
/// - there is a subclass of the class, or
/// - there is an invocation of one of the constructors of the class.
///
/// Note: copied and modified from server.
class _NonEnumVisitor extends _BaseVisitor {
  /// Initialize a newly created visitor to visit everything except the class
  /// declaration corresponding to the given [classElement].
  _NonEnumVisitor(super.classElement);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredElement;
    if (element == null) {
      throw _InvalidEnumException();
    }
    if (element != classElement) {
      if (element.supertype?.element == classElement) {
        throw _InvalidEnumException();
      } else if (element.interfaces
          .map((e) => e.element)
          .contains(classElement)) {
        throw _InvalidEnumException();
      } else if (element.mixins.map((e) => e.element).contains(classElement)) {
        // This case won't occur unless there's an error in the source code, but
        // it's easier to check for the condition than it is to check for the
        // diagnostic.
        throw _InvalidEnumException();
      }
      super.visitClassDeclaration(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (invokesGenerativeConstructor(node)) {
      throw _InvalidEnumException();
    }
    super.visitInstanceCreationExpression(node);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword != null) return;
    var classElement = node.declaredElement;
    if (classElement == null) return;

    // Enums can only extend Object.
    if (classElement.supertype?.isDartCoreObject == false) {
      return;
    }

    var candidateConstants = <VariableDeclaration>[];

    for (var member in node.members) {
      if (isHashCode(member)) return;
      if (isIndex(member)) return;
      if (isEquals(member)) return;
      if (isValues(member)) return;

      if (member is FieldDeclaration) {
        if (!member.isStatic) continue;
        for (var field in member.fields.variables) {
          var fieldElement = field.declaredElement;
          if (fieldElement is! FieldElement) continue;
          if (field.isSynthetic || !field.isConst) continue;
          var initializer = field.initializer;
          if (initializer is! InstanceCreationExpression) continue;

          var constructorElement = initializer.constructorName.staticElement;
          if (constructorElement == null) continue;
          if (constructorElement.isFactory) continue;
          if (constructorElement.enclosingElement != classElement) continue;

          if (fieldElement.computeConstantValue() == null) continue;

          candidateConstants.add(field);
        }
      }
      if (member is ConstructorDeclaration) {
        var constructor = member.declaredElement;
        if (constructor == null) return;
        if (!constructor.isFactory && !constructor.isConst) return;
        var name = member.name?.lexeme;
        if (classElement.isPublic &&
            (name == null || !Identifier.isPrivateName(name))) {
          return;
        }
      }
    }

    if (candidateConstants.length < 2) return;

    try {
      node.accept(_EnumVisitor(classElement, candidateConstants));
      node.root.accept(_NonEnumVisitor(classElement));
    } on _InvalidEnumException {
      return;
    }

    rule.reportLintForToken(node.name);
  }
}
