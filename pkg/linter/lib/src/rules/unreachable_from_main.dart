// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';

const _desc = 'Unreachable top-level members in executable libraries.';

const _details = r'''
Any member declared in an executable library should be used directly inside that
library.  An executable library is a library that contains a `main` top-level
function or that contains a top-level function annotated with
`@pragma('vm:entry-point')`).  Executable libraries are not usually imported
and it's better to avoid defining unused members.

This rule assumes that an executable library isn't imported by other libraries
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
      "Unreachable member '{0}' in an executable library.",
      correctionMessage: 'Try referencing the member or removing it.');

  UnreachableFromMain()
      : super(
          name: 'unreachable_from_main',
          description: _desc,
          details: _details,
          group: Group.style,
          state: State.stable(since: Version(3, 1, 0)),
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

/// This gathers all declarations which we may wish to report on.
class _DeclarationGatherer {
  final LinterContext linterContext;

  /// All declarations which we may wish to report on.
  final Set<Declaration> declarations = {};

  _DeclarationGatherer({
    required this.linterContext,
  });

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
        if (declaration is ClassDeclaration) {
          _addMembers(
            containerElement: declaration.declaredElement,
            members: declaration.members,
          );
        } else if (declaration is EnumDeclaration) {
          _addMembers(
            containerElement: declaration.declaredElement,
            members: declaration.members,
          );
        } else if (declaration is ExtensionDeclaration) {
          _addMembers(
            containerElement: null,
            members: declaration.members,
          );
        } else if (declaration is ExtensionTypeDeclaration) {
          _addMembers(
            containerElement: null,
            members: declaration.members,
          );
        } else if (declaration is MixinDeclaration) {
          _addMembers(
            containerElement: declaration.declaredElement,
            members: declaration.members,
          );
        }
      }
    }
  }

  void _addMembers({
    required Element? containerElement,
    required List<ClassMember> members,
  }) {
    bool isOverride(String rawName) {
      if (containerElement is! InterfaceElement) {
        return false;
      }
      var libraryUri = containerElement.library.source.uri;
      var name = Name(libraryUri, rawName);
      var inheritance = linterContext.inheritanceManager;
      return inheritance.getOverridden2(containerElement, name) != null;
    }

    for (var member in members) {
      switch (member) {
        case ConstructorDeclaration():
          var e = member.declaredElement;
          if (e != null && e.isPublic && member.parent is! EnumDeclaration) {
            declarations.add(member);
          }
        case FieldDeclaration():
          for (var field in member.fields.variables) {
            var element = field.declaredElement;
            if (element != null && element.isPublic) {
              if (!isOverride(element.name)) {
                declarations.add(field);
              }
            }
          }
        case MethodDeclaration():
          var element = member.declaredElement;
          if (element != null && element.isPublic) {
            var rawName = member.name.lexeme;
            var isTestMethod = rawName.startsWith('test_') ||
                rawName.startsWith('solo_test_') ||
                rawName == 'setUp' ||
                rawName == 'tearDown';
            if (!isOverride(element.name) && !isTestMethod) {
              declarations.add(member);
            }
          }
      }
    }
  }
}

/// A visitor which gathers the declarations of the "references" it visits.
///
/// "References" are most often [SimpleIdentifier]s, but can also be other
/// nodes which refer to a declaration.
class _ReferenceVisitor extends RecursiveAstVisitor {
  Map<Element, Declaration> declarationMap;

  Set<Declaration> declarations = {};

  /// References from patterns should not be counted.
  int _patternLevel = 0;

  _ReferenceVisitor(this.declarationMap);

  @override
  void visitAnnotation(Annotation node) {
    var e = node.element;
    if (e != null) {
      _addDeclaration(e);
    }
    super.visitAnnotation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _visitCompoundAssignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addNamedType(node.extendsClause?.superclass);
    _addNamedTypes(node.withClause?.mixinTypes);
    _addNamedTypes(node.implementsClause?.interfaces);

    var element = node.declaredElement;
    if (element != null) {
      var hasConstructors =
          node.members.any((e) => e is ConstructorDeclaration);
      if (!hasConstructors) {
        // The default constructor will have an implicit super-initializer to
        // the super-type's unnamed constructor.
        _addDefaultSuperConstructorDeclaration(node);
      }

      var metadata = element.metadata;
      // This for-loop style is copied from analyzer's `hasX` getters on
      // [Element].
      for (var i = 0; i < metadata.length; i++) {
        var annotation = metadata[i].element;
        if (annotation is PropertyAccessorElement &&
            annotation.name == 'reflectiveTest' &&
            annotation.library.name == 'test_reflective_loader') {
          // The class is instantiated through the use of mirrors in
          // 'test_reflective_loader'.
          var unnamedConstructor = element.constructors
              .firstWhereOrNull((constructor) => constructor.name == '');
          if (unnamedConstructor != null) {
            _addDeclaration(unnamedConstructor);
          }
        }
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  visitConstantPattern(ConstantPattern node) {
    _patternLevel++;
    try {
      return super.visitConstantPattern(node);
    } finally {
      _patternLevel--;
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // If a constructor in a class declaration does not have an explicit
    // super-initializer (or redirection?) then it has an implicit
    // super-initializer to the super-type's unnamed constructor.
    var hasSuperInitializer =
        node.initializers.any((e) => e is SuperConstructorInvocation);
    if (!hasSuperInitializer) {
      var enclosingClass = node.parent;
      if (enclosingClass is ClassDeclaration) {
        _addDefaultSuperConstructorDeclaration(enclosingClass);
      }
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    var e = node.staticElement;
    if (e != null && _patternLevel == 0) {
      _addDeclaration(e);
    }
    super.visitConstructorName(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _addNamedTypes(node.implementsClause?.interfaces);

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    var element = node.element;
    if (element == null) {
      return;
    }

    var nodeIsInTypeArgument =
        node.thisOrAncestorOfType<TypeArgumentList>() != null;

    if (
        // Any reference to a typedef marks it as reachable, since structural
        // typing is used to match against objects.
        node.type?.alias != null ||
            // Any reference to an extension type marks it as reachable, since
            // casting can be used to instantiate the type.
            node.type?.element is ExtensionTypeElement ||
            nodeIsInTypeArgument ||
            // A reference to any type in an external variable declaration marks
            // that type as reachable, since the external implementation can
            // instantiate it.
            node.isInExternalVariableTypeOrFunctionReturnType) {
      _addDeclaration(element);
    }

    // Intentionally do not add the declaration of non-alias named types, as a
    // reference to such a type in a [TypeAnnotation] is not good enough to
    // count as "reachable". Marking a type as reachable only because it was
    // seen in a type annotation would be a miscategorization if the type is
    // never instantiated or subtyped.

    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      for (var typeArgument in typeArguments.arguments) {
        typeArgument.accept(this);
      }
    }
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
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var element = node.staticElement;
    if (element != null) {
      _addDeclaration(element);
    }
    super.visitRedirectingConstructorInvocation(node);
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

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var e = node.staticElement;
    if (e != null) {
      _addDeclaration(e);
    }
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var parent = node.parent;
    if (parent is VariableDeclarationList) {
      var type = parent.type;
      if (type != null) {
        type.accept(this);
      }
    }
    super.visitVariableDeclaration(node);
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

    // Also add [element]'s declaration if it is a constructor, static accessor,
    // or static method.
    if (element.isPrivate) {
      return;
    }
    var enclosingElement = element.enclosingElement;
    if (enclosingElement == null || enclosingElement.isPrivate) {
      return;
    }
    if (enclosingElement is InterfaceElement ||
        enclosingElement is ExtensionElement ||
        enclosingElement is ExtensionTypeElement) {
      var declarationElement = element.declaration;
      var declaration = declarationMap[declarationElement];
      if (declaration != null) {
        declarations.add(declaration);
      }
    }
  }

  void _addDefaultSuperConstructorDeclaration(ClassDeclaration class_) {
    var classElement = class_.declaredElement;
    var supertype = classElement?.supertype;
    if (supertype != null) {
      var unnamedConstructor =
          supertype.constructors.firstWhereOrNull((e) => e.name.isEmpty);
      if (unnamedConstructor != null) {
        _addDeclaration(unnamedConstructor);
      }
    }
  }

  void _addNamedType(NamedType? node) {
    if (node == null) {
      return;
    }

    var element = node.element;
    if (element == null) {
      return;
    }

    var declaration = declarationMap[element];
    if (declaration == null) {
      return;
    }

    declarations.add(declaration);
  }

  void _addNamedTypes(List<NamedType>? nodes) {
    nodes?.forEach(_addNamedType);
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
    var declarationGatherer = _DeclarationGatherer(
      linterContext: context,
    );
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

    // The set of the declarations which each top-level and static declaration
    // references.
    var dependencies = <Declaration, Set<Declaration>>{};

    // Map each declaration to the collection of declarations which are
    // referenced within its body.
    for (var declaration in declarations) {
      var visitor = _ReferenceVisitor(declarationByElement);
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

    var unusedDeclarations = declarations.difference(usedMembers);
    var unusedMembers = unusedDeclarations.where((declaration) {
      var element = declaration.declaredElement;
      return element != null &&
          element.isPublic &&
          !element.hasVisibleForTesting;
    }).toList();

    for (var member in unusedMembers) {
      if (member is ConstructorDeclaration) {
        if (member.name == null) {
          rule.reportLint(member.returnType, arguments: [member.nameForError]);
        } else {
          rule.reportLintForToken(member.name,
              arguments: [member.nameForError]);
        }
      } else if (member is NamedCompilationUnitMember) {
        rule.reportLintForToken(member.name, arguments: [member.nameForError]);
      } else if (member is MethodDeclaration) {
        rule.reportLintForToken(member.name, arguments: [member.name.lexeme]);
      } else if (member is VariableDeclaration) {
        rule.reportLintForToken(member.name, arguments: [member.nameForError]);
      } else if (member is ExtensionDeclaration) {
        var name = member.name;
        rule.reportLintForToken(
          name ?? member.extensionKeyword,
          arguments: [name?.lexeme ?? '<unnamed>'],
        );
      } else {
        throw UnimplementedError('(${member.runtimeType}) $member');
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

extension on Declaration {
  String get nameForError {
    // TODO(srawlins): Move this to analyzer when other uses are found.
    var self = this;
    if (self is ConstructorDeclaration) {
      var name = self.name?.lexeme ?? 'new';
      return '${self.returnType.name}.$name';
    } else if (self is EnumConstantDeclaration) {
      return self.name.lexeme;
    } else if (self is ExtensionDeclaration) {
      var name = self.name;
      return name?.lexeme ?? 'the unnamed extension';
    } else if (self is MethodDeclaration) {
      return self.name.lexeme;
    } else if (self is NamedCompilationUnitMember) {
      return self.name.lexeme;
    } else if (self is VariableDeclaration) {
      return self.name.lexeme;
    }

    assert(false, 'Uncovered Declaration subtype: ${self.runtimeType}');
    return '';
  }
}

extension on NamedType {
  bool get isInExternalVariableTypeOrFunctionReturnType {
    var topTypeAnnotation = topmostTypeAnnotation;

    switch (topTypeAnnotation.parent) {
      case MethodDeclaration(:var externalKeyword, :var returnType):
        return externalKeyword != null && returnType == topTypeAnnotation;
      case VariableDeclarationList(
          parent: FieldDeclaration(:var externalKeyword),
        ):
      case VariableDeclarationList(
          parent: TopLevelVariableDeclaration(:var externalKeyword),
        ):
        return externalKeyword != null;
    }
    return false;
  }

  TypeAnnotation get topmostTypeAnnotation {
    TypeAnnotation topTypeAnnotation = this;
    var parent = this.parent;
    while (parent is TypeAnnotation) {
      topTypeAnnotation = parent;
      parent = topTypeAnnotation.parent;
    }
    return topTypeAnnotation;
  }
}
