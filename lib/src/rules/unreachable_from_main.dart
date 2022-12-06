// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = 'Unreachable top-level members in executable libraries.';

const _details = r'''
Top-level members in an executable library should be used directly inside this
library.  An executable library is a library that contains a `main` top-level
function or that contains a top-level function annotated with
`@pragma('vm:entry-point')`).  Executable libraries are not usually imported
and it's better to avoid defining unused members.

This rule assumes that an executable library isn't imported by other files
except to execute its `main` function.

**BAD:**

```dart
main() {}
void f() {}
```

**GOOD:**

```dart
main() {
  f();
}
void f() {}
```

''';

class UnreachableFromMain extends LintRule {
  UnreachableFromMain()
      : super(
          name: 'unreachable_from_main',
          description: _desc,
          details: _details,
          group: Group.style,
          maturity: Maturity.experimental,
        );

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final LintRule rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // TODO(a14n): add support of libs with parts
    if (node.directives.whereType<PartOfDirective>().isNotEmpty) return;
    if (node.directives.whereType<PartDirective>().isNotEmpty) return;

    var topDeclarations = node.declarations
        .expand((e) => [
              if (e is TopLevelVariableDeclaration)
                ...e.variables.variables
              else
                e,
            ])
        .toSet();

    var entryPoints = topDeclarations.where(_isEntryPoint).toList();
    if (entryPoints.isEmpty) return;

    var declarationByElement = <Element, Declaration>{};
    for (var declaration in topDeclarations) {
      var element = declaration.declaredElement;
      if (element != null) {
        if (element is TopLevelVariableElement) {
          declarationByElement[element] = declaration;
          var getter = element.getter;
          if (getter != null) declarationByElement[getter] = declaration;
          var setter = element.setter;
          if (setter != null) declarationByElement[setter] = declaration;
        } else {
          declarationByElement[element] = declaration;
        }
      }
    }

    // The set of the declarations which each top-level declaration references.
    var dependencies = <Declaration, Set<Declaration>>{};
    for (var declaration in topDeclarations) {
      var visitor = _IdentifierVisitor(declarationByElement);
      declaration.accept(visitor);
      dependencies[declaration] = visitor.declarations;
    }

    var usedMembers = entryPoints.toSet();
    // The following variable will be used to visit every reachable declaration
    // starting from entry-points. At every loop an element is removed. This
    // element is marked as used and we add its dependencies in the declaration
    // list to traverse. Once this list is empty `usedMembers` contains every
    // declarations reachable from an entry-point.
    var declarationsToCheck = Queue.of(usedMembers);
    while (declarationsToCheck.isNotEmpty) {
      var declaration = declarationsToCheck.removeLast();
      for (var dep in dependencies[declaration]!) {
        if (usedMembers.add(dep)) {
          declarationsToCheck.add(dep);
        }
      }
    }

    var unusedMembers = topDeclarations.difference(usedMembers).where((e) {
      var element = e.declaredElement;
      return element != null &&
          element.isPublic &&
          !element.hasVisibleForTesting;
    });

    for (var member in unusedMembers) {
      if (member is NamedCompilationUnitMember) {
        rule.reportLintForToken(member.name);
      } else if (member is VariableDeclaration) {
        rule.reportLintForToken(member.name);
      } else if (member is ExtensionDeclaration) {
        rule.reportLintForToken(
            member.name ?? member.firstTokenAfterCommentAndMetadata);
      } else {
        rule.reportLintForToken(member.firstTokenAfterCommentAndMetadata);
      }
    }
  }

  bool _isEntryPoint(Declaration e) =>
      e is FunctionDeclaration &&
      (e.name.lexeme == 'main' || e.metadata.any(_isPragmaVmEntry));

  bool _isPragmaVmEntry(Annotation annotation) {
    if (!annotation.isPragma) return false;
    var value = annotation.elementAnnotation?.computeConstantValue();
    if (value == null) return false;
    var name = value.getField('name');
    return name != null &&
        name.hasKnownValue &&
        name.toStringValue() == 'vm:entry-point';
  }
}

/// A visitor which gathers the declarations of the identifiers it visits.
class _IdentifierVisitor extends RecursiveAstVisitor {
  Map<Element, Declaration> declarationMap;

  Set<Declaration> declarations = {};

  _IdentifierVisitor(this.declarationMap);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _visitCompoundAssignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _visitCompoundAssignmentExpression(node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _visitCompoundAssignmentExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var e = node.staticElement;
    if (e != null) {
      _addDeclaration(e);
    }
    super.visitSimpleIdentifier(node);
  }

  void _visitCompoundAssignmentExpression(CompoundAssignmentExpression node) {
    var readElement = node.readElement;
    if (readElement != null) {
      _addDeclaration(readElement);
    }
    var writeElement = node.writeElement;
    if (writeElement != null) {
      _addDeclaration(writeElement);
    }
  }

  /// Adds the declaration of the top-level element which contains [element] to
  /// [declarations], if it is found in [declarationMap].
  void _addDeclaration(Element element) {
    var enclosingElement = element.thisOrAncestorMatching((a) =>
        a.enclosingElement == null ||
        a.enclosingElement is CompilationUnitElement);
    var enclosingDeclaration = declarationMap[enclosingElement];
    if (enclosingDeclaration != null) {
      declarations.add(enclosingDeclaration);
    }
  }
}

extension on Element {
  bool get isPragma => (library?.isDartCore ?? false) && name == 'pragma';
}

extension on Annotation {
  bool get isPragma {
    var element = elementAnnotation?.element;
    DartType type;
    if (element is ConstructorElement) {
      type = element.returnType;
    } else if (element is PropertyAccessorElement && element.isGetter) {
      type = element.returnType;
    } else {
      // Dunno what this is.
      return false;
    }
    return type is InterfaceType && type.element.isPragma;
  }
}
