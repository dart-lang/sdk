// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion.builder;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show createSuggestion;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

export 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show createSuggestion;

const String DYNAMIC = 'dynamic';

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
 * Starting with the given class node, traverse the inheritance hierarchy
 * calling the given functions with each non-null non-empty inherited class
 * declaration. For each locally defined declaration, call [localDeclaration].
 * For each class identifier in the hierarchy that is not defined locally,
 * call the [importedTypeName] function.
 */
void visitInheritedTypes(ClassDeclaration node,
    {void localDeclaration(ClassDeclaration classNode),
    void importedTypeName(String typeName)}) {
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
          if (localDeclaration != null) {
            localDeclaration(classNode);
          }
          todo.add(classNode);
        } else {
          if (importedTypeName != null) {
            importedTypeName(name);
          }
        }
      }
    });
  }
}

/**
 * Common mixin for sharing behavior
 */
abstract class ElementSuggestionBuilder {
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
  void addSuggestion(Element element,
      {String prefix, int relevance: DART_RELEVANCE_DEFAULT}) {
    if (element.isPrivate) {
      LibraryElement elementLibrary = element.library;
      CompilationUnitElement unitElem = request.unit.element;
      if (unitElem == null) {
        return;
      }
      LibraryElement unitLibrary = unitElem.library;
      if (elementLibrary != unitLibrary) {
        return;
      }
    }
    if (prefix == null && element.isSynthetic) {
      if ((element is PropertyAccessorElement) ||
          element is FieldElement && !_isSpecialEnumField(element)) {
        return;
      }
    }
    String completion = element.displayName;
    if (prefix != null && prefix.length > 0) {
      if (completion == null || completion.length <= 0) {
        completion = prefix;
      } else {
        completion = '$prefix.$completion';
      }
    }
    if (completion == null || completion.length <= 0) {
      return;
    }
    CompletionSuggestion suggestion = createSuggestion(element,
        completion: completion, kind: kind, relevance: relevance);
    if (suggestion != null) {
      request.addSuggestion(suggestion);
    }
  }

  /**
   * Determine if the given element is one of the synthetic enum accessors
   * for which we should generate a suggestion.
   */
  bool _isSpecialEnumField(FieldElement element) {
    Element parent = element.enclosingElement;
    if (parent is ClassElement && parent.isEnum) {
      if (element.name == 'values') {
        return true;
      }
    }
    return false;
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
