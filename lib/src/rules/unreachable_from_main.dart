// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

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

    // The following map contains for every declaration the set of the
    // declarations it references.
    var dependencies = Map<Declaration, Set<Declaration>>.fromIterable(
      topDeclarations,
      value: (declaration) =>
          DartTypeUtilities.traverseNodesInDFS(declaration as Declaration)
              .expand((e) => [
                    if (e is SimpleIdentifier) e.staticElement,
                    // with `id++` staticElement of `id` is null
                    if (e is CompoundAssignmentExpression) ...[
                      e.readElement,
                      e.writeElement,
                    ],
                  ])
              .whereNotNull()
              .map((e) => e.thisOrAncestorMatching((a) =>
                  a.enclosingElement3 == null ||
                  a.enclosingElement3 is CompilationUnitElement))
              .map((e) => declarationByElement[e])
              .whereNotNull()
              .where((e) => e != declaration)
              .toSet(),
    );

    var usedMembers = entryPoints.toSet();
    // The following variable will be used to visit every reachable declaration
    // starting from entry-points. At every loop an element is removed. This
    // element is marked as used and we add its dependencies in the declaration
    // list to traverse. Once this list is empty `usedMembers` contains every
    // declarations reachable from an entry-point.
    var toTraverse = Queue.of(usedMembers);
    while (toTraverse.isNotEmpty) {
      var declaration = toTraverse.removeLast();
      for (var dep in dependencies[declaration]!) {
        if (usedMembers.add(dep)) {
          toTraverse.add(dep);
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
        rule.reportLintForToken(member.name2);
      } else if (member is VariableDeclaration) {
        rule.reportLintForToken(member.name2);
      } else if (member is ExtensionDeclaration) {
        rule.reportLintForToken(
            member.name2 ?? member.firstTokenAfterCommentAndMetadata);
      } else {
        rule.reportLintForToken(member.firstTokenAfterCommentAndMetadata);
      }
    }
  }

  bool _isEntryPoint(Declaration e) =>
      e is FunctionDeclaration &&
      (e.name2.lexeme == 'main' || e.metadata.any(_isPragmaVmEntry));

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
    return type is InterfaceType && type.element2.isPragma;
  }
}
