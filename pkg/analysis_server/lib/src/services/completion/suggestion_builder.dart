// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion.builder;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

const String DYNAMIC = 'dynamic';

/**
 * Return a suggestion based upon the given element
 * or `null` if a suggestion is not appropriate for the given element.
 */
CompletionSuggestion createSuggestion(Element element,
    {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
    int relevance: COMPLETION_RELEVANCE_DEFAULT}) {

  String nameForType(DartType type) {
    if (type == null) {
      return DYNAMIC;
    }
    String name = type.displayName;
    if (name == null || name.length <= 0) {
      return DYNAMIC;
    }
    //TODO (danrubel) include type arguments ??
    return name;
  }

  String returnType = null;
  if (element is ExecutableElement) {
    if (element.isOperator) {
      // Do not include operators in suggestions
      return null;
    }
    if (element is PropertyAccessorElement && element.isSetter) {
      // no return type
    } else {
      returnType = nameForType(element.returnType);
    }
  } else if (element is VariableElement) {
    returnType = nameForType(element.type);
  } else if (element is FunctionTypeAliasElement) {
    returnType = nameForType(element.returnType);
  }

  String completion = element.displayName;
  bool isDeprecated = element.isDeprecated;
  CompletionSuggestion suggestion = new CompletionSuggestion(
      kind,
      isDeprecated ? COMPLETION_RELEVANCE_LOW : relevance,
      completion,
      completion.length,
      0,
      isDeprecated,
      false);
  suggestion.element = protocol.newElement_fromEngine(element);
  if (element is ClassMemberElement) {
    ClassElement enclosingElement = element.enclosingElement;
    if (enclosingElement != null) {
      suggestion.declaringType = enclosingElement.displayName;
    }
  }
  suggestion.returnType = returnType;
  if (element is ExecutableElement && element is! PropertyAccessorElement) {
    suggestion.parameterNames = element.parameters.map(
        (ParameterElement parameter) => parameter.name).toList();
    suggestion.parameterTypes = element.parameters.map(
        (ParameterElement parameter) => parameter.type.displayName).toList();
    suggestion.requiredParameterCount = element.parameters.where(
        (ParameterElement parameter) =>
            parameter.parameterKind == ParameterKind.REQUIRED).length;
    suggestion.hasNamedParameters = element.parameters.any(
        (ParameterElement parameter) => parameter.parameterKind == ParameterKind.NAMED);
  }
  return suggestion;
}

/**
 * Call the given function with each non-null non-empty inherited type name
 * that is defined in the given class.
 */
visitInheritedTypeNames(ClassDeclaration node, void inherited(String name)) {

  void visit(TypeName type) {
    if (type != null) {
      Identifier id = type.name;
      if (id != null) {
        String name = id.name;
        if (name != null && name.length > 0) {
          inherited(name);
        }
      }
    }
  }

  ExtendsClause extendsClause = node.extendsClause;
  if (extendsClause != null) {
    visit(extendsClause.superclass);
  }
  ImplementsClause implementsClause = node.implementsClause;
  if (implementsClause != null) {
    NodeList<TypeName> interfaces = implementsClause.interfaces;
    if (interfaces != null) {
      interfaces.forEach((TypeName type) {
        visit(type);
      });
    }
  }
  WithClause withClause = node.withClause;
  if (withClause != null) {
    NodeList<TypeName> mixinTypes = withClause.mixinTypes;
    if (mixinTypes != null) {
      mixinTypes.forEach((TypeName type) {
        visit(type);
      });
    }
  }
}

/**
 * Starting with the given class node, traverse the inheritence hierarchy
 * calling the given functions with each non-null non-empty inherited class
 * declaration. For each locally defined class declaration, call [local].
 * For each class identifier in the hierarchy that is not defined locally,
 * call the [imported] function.
 */
void visitInheritedTypes(ClassDeclaration node, void
    local(ClassDeclaration classNode), void imported(String typeName)) {
  CompilationUnit unit = node.getAncestor((p) => p is CompilationUnit);
  List<ClassDeclaration> todo = new List<ClassDeclaration>();
  todo.add(node);
  Set<String> visited = new Set<String>();
  while (todo.length > 0) {
    node = todo.removeLast();
    visitInheritedTypeNames(node, (String name) {
      if (visited.add(name)) {
        var classNode = unit.declarations.firstWhere((member) {
          if (member is ClassDeclaration) {
            SimpleIdentifier id = member.name;
            if (id != null && id.name == name) {
              return true;
            }
          }
          return false;
        }, orElse: () => null);
        if (classNode is ClassDeclaration) {
          local(classNode);
          todo.add(classNode);
        } else {
          imported(name);
        }
      }
    });
  }
}

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible members in that class. Clients should call
 * [ClassElementSuggestionBuilder.suggestionsFor].
 */
class ClassElementSuggestionBuilder extends GeneralizingElementVisitor with
    ElementSuggestionBuilder {
  final bool staticOnly;
  final DartCompletionRequest request;

  ClassElementSuggestionBuilder(this.request, bool staticOnly)
      : this.staticOnly = staticOnly;

  @override
  CompletionSuggestionKind get kind => CompletionSuggestionKind.INVOCATION;

  @override
  visitClassElement(ClassElement element) {
    element.visitChildren(this);
    element.allSupertypes.forEach((InterfaceType type) {
      type.element.visitChildren(this);
    });
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFieldElement(FieldElement element) {
    if (staticOnly && !element.isStatic) {
      return;
    }
    addSuggestion(element);
  }

  @override
  visitMethodElement(MethodElement element) {
    if (staticOnly && !element.isStatic) {
      return;
    }
    if (element.isOperator) {
      return;
    }
    addSuggestion(element);
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (staticOnly && !element.isStatic) {
      return;
    }
    addSuggestion(element);
  }

  /**
   * Add suggestions for the visible members in the given class
   */
  static void suggestionsFor(DartCompletionRequest request, Element element,
      {bool staticOnly: false}) {
    if (element == DynamicElementImpl.instance) {
      element = request.cache.objectClassElement;
    }
    if (element is ClassElement) {
      return element.accept(
          new ClassElementSuggestionBuilder(request, staticOnly));
    }
  }
}

/**
 * Common mixin for sharing behavior
 */
abstract class ElementSuggestionBuilder {

  /**
   * Internal collection of completions to prevent duplicate completions.
   */
  final Set<String> _completions = new Set<String>();

  /**
   * Return the kind of suggestions that should be built.
   */
  CompletionSuggestionKind get kind;

  /**
   * Return the request on which the builder is operating.
   */
  DartCompletionRequest get request;

  /**
   * Add a suggestion based upon the given element.
   */
  void addSuggestion(Element element) {
    if (element.isPrivate) {
      LibraryElement elementLibrary = element.library;
      LibraryElement unitLibrary = request.unit.element.library;
      if (elementLibrary != unitLibrary) {
        return;
      }
    }
    if (element.isSynthetic) {
      if (element is PropertyAccessorElement || element is FieldElement) {
        return;
      }
    }
    String completion = element.displayName;
    if (completion == null ||
        completion.length <= 0 ||
        !_completions.add(completion)) {
      return;
    }
    CompletionSuggestion suggestion = createSuggestion(element, kind: kind);
    if (suggestion != null) {
      request.suggestions.add(suggestion);
    }
  }
}

/**
 * This class visits elements in a library and provides suggestions based upon
 * the visible members in that library. Clients should call
 * [LibraryElementSuggestionBuilder.suggestionsFor].
 */
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor with
    ElementSuggestionBuilder {
  final DartCompletionRequest request;
  final CompletionSuggestionKind kind;

  LibraryElementSuggestionBuilder(this.request, this.kind);

  @override
  visitClassElement(ClassElement element) {
    addSuggestion(element);
  }

  @override
  visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFunctionElement(FunctionElement element) {
    addSuggestion(element);
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    addSuggestion(element);
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    addSuggestion(element);
  }

  /**
   * Add suggestions for the visible members in the given library
   */
  static void suggestionsFor(DartCompletionRequest request,
      CompletionSuggestionKind kind, LibraryElement library) {
    if (library != null) {
      library.visitChildren(new LibraryElementSuggestionBuilder(request, kind));
    }
  }
}

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible named constructors in that class.
 */
class NamedConstructorSuggestionBuilder extends GeneralizingElementVisitor with
    ElementSuggestionBuilder implements SuggestionBuilder {
  final DartCompletionRequest request;

  NamedConstructorSuggestionBuilder(this.request);

  @override
  CompletionSuggestionKind get kind => CompletionSuggestionKind.INVOCATION;

  @override
  bool computeFast(AstNode node) {
    return false;
  }

  @override
  Future<bool> computeFull(AstNode node) {
    if (node is SimpleIdentifier) {
      node = node.parent;
    }
    if (node is ConstructorName) {
      TypeName typeName = node.type;
      if (typeName != null) {
        DartType type = typeName.type;
        if (type != null) {
          if (type.element is ClassElement) {
            type.element.accept(this);
          }
          return new Future.value(true);
        }
      }
    }
    return new Future.value(false);
  }

  @override
  visitClassElement(ClassElement element) {
    element.visitChildren(this);
  }

  @override
  visitConstructorElement(ConstructorElement element) {
    addSuggestion(element);
  }

  @override
  visitElement(Element element) {
    // ignored
  }
}

/**
 * Common interface implemented by suggestion builders.
 */
abstract class SuggestionBuilder {
  /**
   * Compute suggestions and return `true` if building is complete,
   * or `false` if [computeFull] should be called.
   */
  bool computeFast(AstNode node);

  /**
   * Return a future that computes the suggestions given a fully resolved AST.
   * The future returns `true` if suggestions were added, else `false`.
   */
  Future<bool> computeFull(AstNode node);
}
