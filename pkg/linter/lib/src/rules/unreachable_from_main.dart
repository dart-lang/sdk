// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = 'Unreachable top-level members in executable libraries.';

class UnreachableFromMain extends AnalysisRule {
  UnreachableFromMain()
    : super(
        name: LintNames.unreachable_from_main,
        description: _desc,
        state: RuleState.stable(since: Version(3, 1, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.unreachableFromMain;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

/// This gathers all declarations which we may wish to report on.
class _DeclarationGatherer {
  final RuleContext linterContext;

  /// All declarations which we may wish to report on.
  final Set<Declaration> declarations = {};

  _DeclarationGatherer({required this.linterContext});

  void addDeclarations(CompilationUnit node) {
    for (var declaration in node.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        declarations.addAll(declaration.variables.variables);
      } else {
        declarations.add(declaration);
        var declaredElement = declaration.declaredFragment?.element;
        if (declaredElement == null || declaredElement.isPrivate) {
          continue;
        }
        if (declaration is ClassDeclaration) {
          if (declaration.body case BlockClassBody body) {
            _addMembers(
              containerElement: declaration.declaredFragment?.element,
              members: body.members,
            );
          }
        } else if (declaration is EnumDeclaration) {
          _addMembers(
            containerElement: declaration.declaredFragment?.element,
            members: declaration.body.members,
          );
        } else if (declaration is ExtensionDeclaration) {
          _addMembers(
            containerElement: null,
            members: declaration.body.members,
          );
        } else if (declaration is ExtensionTypeDeclaration) {
          if (declaration.body case BlockClassBody body) {
            _addMembers(containerElement: null, members: body.members);
          }
        } else if (declaration is MixinDeclaration) {
          _addMembers(
            containerElement: declaration.declaredFragment?.element,
            members: declaration.body.members,
          );
        }
      }
    }
  }

  void _addMembers({
    required Element? containerElement,
    required List<ClassMember> members,
  }) {
    bool isOverride(ExecutableElement? element) {
      if (containerElement is! InterfaceElement) {
        return false;
      }

      if (element == null) {
        return false;
      }

      var name = Name.forElement(element);
      if (name == null) {
        return false;
      }

      return containerElement.getOverridden(name) != null;
    }

    for (var member in members) {
      switch (member) {
        case ConstructorDeclaration():
          var e = member.declaredFragment?.element;
          if (e != null &&
              e.isPublic &&
              member.parent?.parent is! EnumDeclaration) {
            declarations.add(member);
          }
        case FieldDeclaration():
          for (var field in member.fields.variables) {
            var element = field.declaredFragment?.element;
            if (element is FieldElement && element.isPublic) {
              if (!isOverride(element.getter)) {
                declarations.add(field);
              }
            }
          }
        case MethodDeclaration():
          var element = member.declaredFragment?.element;
          if (element != null && element.isPublic) {
            var rawName = member.name.lexeme;
            var isTestMethod =
                rawName.startsWith('test_') ||
                rawName.startsWith('solo_test_') ||
                rawName == 'setUp' ||
                rawName == 'tearDown' ||
                rawName == 'setUpClass' ||
                rawName == 'tearDownClass';
            if (!isOverride(element) && !isTestMethod) {
              declarations.add(member);
            }
          }
        case PrimaryConstructorBody():
        // TODO(srawlins): Handle fields declared here, except in extension type
        // declarations.
        // No declarations to add.
      }
    }
  }
}

/// A visitor which gathers the declarations of the "references" it visits.
///
/// "References" are most often [SimpleIdentifier]s, but can also be other
/// nodes which refer to a declaration.
class _ReferenceVisitor extends RecursiveAstVisitor<void> {
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

    var element = node.declaredFragment?.element;

    if (element != null) {
      var body = node.body;
      var hasConstructors =
          body is BlockClassBody &&
          body.members.any((e) => e is ConstructorDeclaration);
      if (!hasConstructors) {
        // The default constructor will have an implicit super-initializer to
        // the super-type's unnamed constructor.
        _addDefaultSuperConstructorDeclaration(node);
      }

      var metadata = element.metadata;
      // This for-loop style is copied from analyzer's `hasX` getters on
      // [Element].
      for (var i = 0; i < metadata.annotations.length; i++) {
        if (metadata.annotations[i].isReflectiveTest) {
          // The class is instantiated through the use of mirrors in
          // 'test_reflective_loader'.
          var unnamedConstructor = element.constructors.firstWhereOrNull(
            (constructor) => constructor.name == 'new',
          );
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
    var hasSuperInitializer = node.initializers.any(
      (e) => e is SuperConstructorInvocation,
    );
    if (!hasSuperInitializer) {
      var enclosingClass = node.parent?.parent;
      if (enclosingClass is ClassDeclaration) {
        _addDefaultSuperConstructorDeclaration(enclosingClass);
      }
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    var e = node.element;
    if (e != null && _patternLevel == 0) {
      _addDeclaration(e);
      var type = node.type.element;
      if (type != null) {
        _addDeclaration(type);
      }
    }
    super.visitConstructorName(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _addNamedTypes(node.implementsClause?.interfaces);

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'toJson' && !node.isStatic) {
      // The 'dart:convert' library uses dynamic invocation to call `toJson` on
      // arbitrary objects. Any declaration of `toJson` is automatically
      // reachable.
      var element = node.declaredFragment?.element;
      if (element != null) {
        _addDeclaration(element);
      }
    }
    super.visitMethodDeclaration(node);
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
        // A reference to a type literal marks it as reachable, since the type
        // is being used as a value.
        node.parent is TypeLiteral ||
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
  void visitPatternField(PatternField node) {
    var e = node.element;
    if (e != null) {
      _addDeclaration(e);
    }
    super.visitPatternField(node);
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
    RedirectingConstructorInvocation node,
  ) {
    var element = node.element;
    if (element != null) {
      _addDeclaration(element);
    }
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      var e = node.element;
      if (e != null) {
        _addDeclaration(e);
      }
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var e = node.element;
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
    var enclosingTopLevelElement = element.thisOrAncestorMatching(
      (a) => a.enclosingElement == null || a.enclosingElement is LibraryElement,
    );
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
      var declaration = declarationMap[element.baseElement];
      if (declaration != null) {
        declarations.add(declaration);
      }
    }
  }

  void _addDefaultSuperConstructorDeclaration(ClassDeclaration class_) {
    var classElement = class_.declaredFragment?.element;
    var supertype = classElement?.supertype;
    if (supertype != null) {
      var unnamedConstructor = supertype.constructors.firstWhereOrNull(
        (e) => e.name == 'new',
      );
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
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var declarationGatherer = _DeclarationGatherer(linterContext: context);
    for (var unit in context.allUnits) {
      declarationGatherer.addDeclarations(unit.unit);
    }
    var declarations = declarationGatherer.declarations;
    var entryPoints = declarations.where(_isEntryPoint);
    if (entryPoints.isEmpty) return;

    // Map each top-level and static element to its declaration.
    var declarationByElement = <Element, Declaration>{};
    for (var declaration in declarations) {
      var element = declaration.declaredFragment?.element;
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

    var unitDeclarationGatherer = _DeclarationGatherer(linterContext: context);
    unitDeclarationGatherer.addDeclarations(node);
    var unitDeclarations = unitDeclarationGatherer.declarations;
    var unusedDeclarations = unitDeclarations.difference(usedMembers);
    var unusedMembers = unusedDeclarations.where((declaration) {
      var element = declaration.declaredFragment?.element;
      return element != null &&
          element.isPublic &&
          !element.hasVisibleForTesting &&
          !element.hasWidgetPreview;
    }).toList();

    for (var member in unusedMembers) {
      var nodeToAnnotate = getNodeToAnnotate(member);
      rule.reportAtOffset(
        nodeToAnnotate.offset,
        nodeToAnnotate.length,
        arguments: [member.nameForError],
      );
    }
  }

  bool _isEntryPoint(Declaration e) =>
      e is FunctionDeclaration &&
      (e.name.lexeme == 'main' || e.metadata.any(_isExemptingAnnotation));

  bool _isExemptingAnnotation(Annotation annotation) {
    if (annotation.isPragma) {
      return _isValidVmEntryPoint(annotation);
    } else if (annotation.isWidgetPreview) {
      return true;
    }
    return false;
  }

  bool _isValidVmEntryPoint(Annotation annotation) {
    var value = annotation.elementAnnotation?.computeConstantValue();
    if (value == null) return false;
    var name = value.getField('name');
    return name != null &&
        name.hasKnownValue &&
        name.toStringValue() == 'vm:entry-point';
  }
}

extension on Metadata {
  bool get hasWidgetPreview {
    var annotations = this.annotations;
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isWidgetPreview) {
        return true;
      }
    }
    return false;
  }
}

extension on ElementAnnotation {
  /// The URI of the Flutter widget previews library.
  static final Uri _flutterWidgetPreviewLibraryUri = Uri.parse(
    'package:flutter/src/widget_previews/widget_previews.dart',
  );

  bool get isWidgetPreview {
    var element = this.element;
    return element is ConstructorElement &&
        element.enclosingElement.name == 'Preview' &&
        element.library.uri == _flutterWidgetPreviewLibraryUri;
  }
}

extension on LibraryElement {
  bool get isWidgetPreviews =>
      uri ==
      Uri.parse('package:flutter/src/widget_previews/widget_previews.dart');
}

extension on Element {
  bool get hasVisibleForTesting => metadata.hasVisibleForTesting;

  bool get hasWidgetPreview =>
      // Widget previews can be applied to public:
      //   - Constructors (generative and factory)
      //   - Top-level functions
      //   - Static member functions
      (this is ConstructorElement ||
          this is TopLevelFunctionElement ||
          (this is ExecutableElement &&
              (this as ExecutableElement).isStatic)) &&
      !isPrivate &&
      metadata.hasWidgetPreview;
  bool get isPragma => (library?.isDartCore ?? false) && name == 'pragma';
  bool get isWidgetPreview =>
      (library?.isWidgetPreviews ?? false) && name == 'Preview';
}

extension on Annotation {
  bool get isPragma {
    DartType? type = _elementType;
    if (type == null) {
      // Dunno what this is.
      return false;
    }
    return type is InterfaceType && type.element.isPragma;
  }

  bool get isWidgetPreview {
    DartType? type = _elementType;
    if (type == null) {
      // Dunno what this is.
      return false;
    }
    return type is InterfaceType && type.element.isWidgetPreview;
  }

  DartType? get _elementType {
    var element = elementAnnotation?.element;
    DartType? type;
    if (element is ConstructorElement) {
      type = element.returnType;
    } else if (element is GetterElement) {
      type = element.returnType;
    }
    return type;
  }
}

extension on Declaration {
  String get nameForError {
    // TODO(srawlins): Move this to analyzer when other uses are found.
    var self = this;
    switch (self) {
      case ClassDeclaration():
        return self.namePart.typeName.lexeme;
      case ConstructorDeclaration():
        var name = self.name?.lexeme ?? 'new';
        // TODO(scheglov): support primary constructors
        return '${self.typeName!.name}.$name';
      case EnumConstantDeclaration():
        return self.name.lexeme;
      case EnumDeclaration():
        return self.namePart.typeName.lexeme;
      case ExtensionDeclaration():
        var name = self.name;
        return name?.lexeme ?? 'the unnamed extension';
      case ExtensionTypeDeclaration():
        return self.primaryConstructor.typeName.lexeme;
      case FunctionDeclaration():
        return self.name.lexeme;
      case MethodDeclaration():
        return self.name.lexeme;
      case MixinDeclaration():
        return self.name.lexeme;
      case TypeAlias():
        return self.name.lexeme;
      case VariableDeclaration():
        return self.name.lexeme;
      default:
        assert(false, 'Uncovered Declaration subtype: ${self.runtimeType}');
        return '';
    }
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
