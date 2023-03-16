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
  static const LintCode code = LintCode('unreachable_from_main',
      'Unreachable top-level member in an executable library.',
      correctionMessage: 'Try referencing the member or removing it.');

  UnreachableFromMain()
      : super(
          name: 'unreachable_from_main',
          description: _desc,
          details: _details,
          group: Group.style,
          state: State.experimental(),
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

/// This gathers all of the top-level and static declarations which we may wish
/// to report on.
class _DeclarationGatherer {
  // A complete set of the declaration of each public static class member, and
  // each public top-level declaration.
  final declarations = <Declaration>{};

  void addDeclarations(CompilationUnit node) {
    for (var declaration in node.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        declarations.addAll(declaration.variables.variables);
      } else {
        declarations.add(declaration);
        var declaredElement = declaration.declaredElement;
        if (declaredElement == null || declaredElement.isPrivate) {
          continue;
        }
        if (declaration is MixinDeclaration) {
          declaration.members.forEach(_addStaticMember);
        } else if (declaration is ClassDeclaration) {
          declaration.members.forEach(_addStaticMember);
        } else if (declaration is EnumDeclaration) {
          declaration.members.forEach(_addStaticMember);
        } else if (declaration is ExtensionDeclaration) {
          declaration.members.forEach(_addStaticMember);
        }
      }
    }
  }

  void _addStaticMember(ClassMember member) {
    if (member is FieldDeclaration && member.isStatic) {
      for (var field in member.fields.variables) {
        var e = field.declaredElement;
        if (e != null && e.isPublic) {
          declarations.add(field);
        }
      }
    } else if (member is MethodDeclaration && member.isStatic) {
      var e = member.declaredElement;
      if (e != null && e.isPublic) {
        declarations.add(member);
      }
    }
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
    if (!node.inDeclarationContext()) {
      var e = node.staticElement;
      if (e != null) {
        _addDeclaration(e);
      }
    }
    super.visitSimpleIdentifier(node);
  }

  /// Adds the declaration of the top-level element which contains [element] to
  /// [declarations], if it is found in [declarationMap].
  ///
  /// Also adds the declaration of [element] if it is a public static accessor
  /// or static method on a public top-level element.
  void _addDeclaration(Element element) {
    // First add the enclosing top-level declaration.
    var enclosingTopLevelElement = element.thisOrAncestorMatching((a) =>
        a.enclosingElement == null ||
        a.enclosingElement is CompilationUnitElement);
    var enclosingTopLevelDeclaration = declarationMap[enclosingTopLevelElement];
    if (enclosingTopLevelDeclaration != null) {
      declarations.add(enclosingTopLevelDeclaration);
    }

    // Also add [element]'s declaration if it is a static accessor or static
    // method.
    if (element.isPrivate) {
      return;
    }
    var enclosingElement = element.enclosingElement;
    if (enclosingElement == null || enclosingElement.isPrivate) {
      return;
    }
    if (enclosingElement is InterfaceElement ||
        enclosingElement is ExtensionElement) {
      if (element is PropertyAccessorElement && element.isStatic) {
        var declaration = declarationMap[element];
        if (declaration != null) {
          declarations.add(declaration);
        }
      } else if (element is MethodElement && element.isStatic) {
        var declaration = declarationMap[element];
        if (declaration != null) {
          declarations.add(declaration);
        }
      }
    }
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
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var declarationGatherer = _DeclarationGatherer();
    for (var unit in context.allUnits) {
      declarationGatherer.addDeclarations(unit.unit);
    }
    var declarations = declarationGatherer.declarations;
    var entryPoints = declarations.where(_isEntryPoint);
    if (entryPoints.isEmpty) return;

    // Map each top-level and static element to its declaration.
    var declarationByElement = <Element, Declaration>{};
    for (var declaration in declarations) {
      var element = declaration.declaredElement;
      if (element != null) {
        declarationByElement[element] = declaration;
        if (element is TopLevelVariableElement) {
          var getter = element.getter;
          if (getter != null) declarationByElement[getter] = declaration;
          var setter = element.setter;
          if (setter != null) declarationByElement[setter] = declaration;
        } else if (element is FieldElement) {
          var getter = element.getter;
          if (getter != null) declarationByElement[getter] = declaration;
          var setter = element.setter;
          if (setter != null) declarationByElement[setter] = declaration;
        }
      }
    }

    // The set of the declarations which each top-level declaration references.
    var dependencies = <Declaration, Set<Declaration>>{};

    // Map each declaration to the collection of declarations which are
    // referenced within its body.
    for (var declaration in declarations) {
      var visitor = _IdentifierVisitor(declarationByElement);
      declaration.accept(visitor);
      dependencies[declaration] = visitor.declarations;
    }

    var usedMembers = entryPoints.toSet();
    var declarationsToCheck = Queue.of(usedMembers);

    // Loop through declarations which are reachable from the set of
    // entry-points. We mark each such declaration as "used", and add its
    // dependencies to the queue to loop through. Once the queue is empty,
    // `usedMembers` contains every declaration reachable from an entry-point.
    while (declarationsToCheck.isNotEmpty) {
      var declaration = declarationsToCheck.removeLast();
      for (var dep in dependencies[declaration]!) {
        if (usedMembers.add(dep)) {
          declarationsToCheck.add(dep);
        }
      }
    }

    var unusedMembers = declarations.difference(usedMembers).where((e) {
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
