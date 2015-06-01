// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.suggestion.builder;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;

const String DYNAMIC = 'dynamic';

/**
 * Return a suggestion based upon the given element
 * or `null` if a suggestion is not appropriate for the given element.
 * If the suggestion is not currently in scope, then specify
 * importForSource as the source to which an import should be added.
 */
CompletionSuggestion createSuggestion(Element element,
    {CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
    int relevance: DART_RELEVANCE_DEFAULT, Source importForSource}) {
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
  CompletionSuggestion suggestion = new CompletionSuggestion(kind,
      isDeprecated ? DART_RELEVANCE_LOW : relevance, completion,
      completion.length, 0, isDeprecated, false);
  suggestion.element = protocol.newElement_fromEngine(element);
  Element enclosingElement = element.enclosingElement;
  if (enclosingElement is ClassElement) {
    suggestion.declaringType = enclosingElement.displayName;
  }
  suggestion.returnType = returnType;
  if (element is ExecutableElement && element is! PropertyAccessorElement) {
    suggestion.parameterNames = element.parameters
        .map((ParameterElement parameter) => parameter.name)
        .toList();
    suggestion.parameterTypes = element.parameters
        .map((ParameterElement parameter) => parameter.type.displayName)
        .toList();
    suggestion.requiredParameterCount = element.parameters.where(
        (ParameterElement parameter) =>
            parameter.parameterKind == ParameterKind.REQUIRED).length;
    suggestion.hasNamedParameters = element.parameters.any(
        (ParameterElement parameter) =>
            parameter.parameterKind == ParameterKind.NAMED);
  }
  if (importForSource != null) {
    String srcPath = path.dirname(importForSource.fullName);
    LibraryElement libElem = element.library;
    if (libElem != null) {
      Source libSource = libElem.source;
      if (libSource != null) {
        UriKind uriKind = libSource.uriKind;
        if (uriKind == UriKind.DART_URI) {
          suggestion.importUri = libSource.uri.toString();
        } else if (uriKind == UriKind.PACKAGE_URI) {
          suggestion.importUri = libSource.uri.toString();
        } else if (uriKind == UriKind.FILE_URI &&
            element.source.uriKind == UriKind.FILE_URI) {
          try {
            suggestion.importUri =
                path.relative(libSource.fullName, from: srcPath);
          } catch (_) {
            // ignored
          }
        }
      }
    }
    if (suggestion.importUri == null) {
      // Do not include out of scope suggestions
      // for which we cannot determine an import
      return null;
    }
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
  void addSuggestion(Element element, {int relevance: DART_RELEVANCE_DEFAULT}) {
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
    if (element.isSynthetic) {
      if ((element is PropertyAccessorElement) ||
          element is FieldElement && !_isSpecialEnumField(element)) {
        return;
      }
    }
    String completion = element.displayName;
    if (completion == null || completion.length <= 0) {
      return;
    }
    CompletionSuggestion suggestion =
        createSuggestion(element, kind: kind, relevance: relevance);
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
 * This class provides suggestions based upon the visible instance members in
 * an interface type.  Clients should call
 * [InterfaceTypeSuggestionBuilder.suggestionsFor].
 */
class InterfaceTypeSuggestionBuilder {
  /**
   * Enumerated value indicating that we have not generated any completions for
   * a given identifier yet.
   */
  static const int _COMPLETION_TYPE_NONE = 0;

  /**
   * Enumerated value indicating that we have generated a completion for a
   * getter.
   */
  static const int _COMPLETION_TYPE_GETTER = 1;

  /**
   * Enumerated value indicating that we have generated a completion for a
   * setter.
   */
  static const int _COMPLETION_TYPE_SETTER = 2;

  /**
   * Enumerated value indicating that we have generated a completion for a
   * field, a method, or a getter/setter pair.
   */
  static const int _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET = 3;

  final DartCompletionRequest request;

  /**
   * Map indicating, for each possible completion identifier, whether we have
   * already generated completions for a getter, setter, or both.  The "both"
   * case also handles the case where have generated a completion for a method
   * or a field.
   *
   * Note: the enumerated values stored in this map are intended to be bitwise
   * compared.
   */
  Map<String, int> _completionTypesGenerated = new HashMap<String, int>();

  InterfaceTypeSuggestionBuilder(this.request);

  CompletionSuggestionKind get kind => CompletionSuggestionKind.INVOCATION;

  /**
   * Add a suggestion based upon the given element, provided that it is not
   * shadowed by a previously added suggestion.
   */
  void addSuggestion(Element element, {int relevance: DART_RELEVANCE_DEFAULT}) {
    if (element.isPrivate) {
      LibraryElement elementLibrary = element.library;
      LibraryElement unitLibrary = request.unit.element.library;
      if (elementLibrary != unitLibrary) {
        return;
      }
    }
    String identifier = element.displayName;
    int alreadyGenerated = _completionTypesGenerated.putIfAbsent(
        identifier, () => _COMPLETION_TYPE_NONE);
    if (element is MethodElement) {
      // Anything shadows a method.
      if (alreadyGenerated != _COMPLETION_TYPE_NONE) {
        return;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else if (element is PropertyAccessorElement) {
      if (element.isGetter) {
        // Getters, fields, and methods shadow a getter.
        if ((alreadyGenerated & _COMPLETION_TYPE_GETTER) != 0) {
          return;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_GETTER;
      } else {
        // Setters, fields, and methods shadow a setter.
        if ((alreadyGenerated & _COMPLETION_TYPE_SETTER) != 0) {
          return;
        }
        _completionTypesGenerated[identifier] |= _COMPLETION_TYPE_SETTER;
      }
    } else if (element is FieldElement) {
      // Fields and methods shadow a field.  A getter/setter pair shadows a
      // field, but a getter or setter by itself doesn't.
      if (alreadyGenerated == _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET) {
        return;
      }
      _completionTypesGenerated[identifier] =
          _COMPLETION_TYPE_FIELD_OR_METHOD_OR_GETSET;
    } else {
      // Unexpected element type; skip it.
      assert(false);
      return;
    }
    CompletionSuggestion suggestion =
        createSuggestion(element, kind: kind, relevance: relevance);
    if (suggestion != null) {
      request.addSuggestion(suggestion);
    }
  }

  void _buildSuggestions(InterfaceType type, LibraryElement library,
      bool isSuper, String containingMethodName) {
    if (isSuper) {
      // Suggest members from superclass if the target is "super"
      type = type.superclass;
      if (type == null) {
        return;
      }
    }
    // Visit all of the types in the class hierarchy, collecting possible
    // completions.  If multiple elements are found that complete to the same
    // identifier, addSuggestion will discard all but the first (with a few
    // exceptions to handle getter/setter pairs).
    List<InterfaceType> types = _getTypeOrdering(type);
    for (InterfaceType targetType in types) {
      for (MethodElement method in targetType.methods) {
        // Exclude static methods when completion on an instance
        if (!method.isStatic) {
          addSuggestion(method,
              relevance: method.name == containingMethodName
                  ? DART_RELEVANCE_HIGH
                  : DART_RELEVANCE_DEFAULT);
        }
      }
      for (PropertyAccessorElement propertyAccessor in targetType.accessors) {
        if (!propertyAccessor.isStatic) {
          if (propertyAccessor.isSynthetic) {
            // Avoid visiting a field twice
            if (propertyAccessor.isGetter) {
              addSuggestion(propertyAccessor.variable);
            }
          } else {
            addSuggestion(propertyAccessor);
          }
        }
      }
    }
  }

  /**
   * Get a list of [InterfaceType]s that should be searched to find the
   * possible completions for an object having type [type].
   */
  List<InterfaceType> _getTypeOrdering(InterfaceType type) {
    // Candidate completions can come from [type] as well as any types above it
    // in the class hierarchy (including mixins, superclasses, and interfaces).
    // If a given completion identifier shows up in multiple types, we should
    // use the element that is nearest in the superclass chain, so we will
    // visit [type] first, then its mixins, then its superclass, then its
    // superclass's mixins, etc., and only afterwards visit interfaces.
    //
    // We short-circuit loops in the class hierarchy by keeping track of the
    // classes seen (not the interfaces) so that we won't be fooled by nonsense
    // like "class C<T> extends C<List<T>> {}"
    List<InterfaceType> result = <InterfaceType>[];
    Set<ClassElement> classesSeen = new HashSet<ClassElement>();
    List<InterfaceType> typesToVisit = <InterfaceType>[type];
    while (typesToVisit.isNotEmpty) {
      InterfaceType nextType = typesToVisit.removeLast();
      if (!classesSeen.add(nextType.element)) {
        // Class had already been seen, so ignore this type.
        continue;
      }
      result.add(nextType);
      // typesToVisit is a stack, so push on the interfaces first, then the
      // superclass, then the mixins.  This will ensure that they are visited
      // in the reverse order.
      typesToVisit.addAll(nextType.interfaces);
      if (nextType.superclass != null) {
        typesToVisit.add(nextType.superclass);
      }
      typesToVisit.addAll(nextType.mixins);
    }
    return result;
  }

  /**
   * Add suggestions for the visible members in the given interface
   */
  static void suggestionsFor(DartCompletionRequest request, DartType type,
      {bool isSuper: false, String containingMethodName: null}) {
    CompilationUnit compilationUnit =
        request.target.containingNode.getAncestor((n) => n is CompilationUnit);
    LibraryElement library = compilationUnit.element.library;
    if (type is DynamicTypeImpl) {
      type = request.cache.objectClassElement.type;
    }
    if (type is InterfaceType) {
      return new InterfaceTypeSuggestionBuilder(request)._buildSuggestions(
          type, library, isSuper, containingMethodName);
    }
  }
}

/**
 * This class visits elements in a library and provides suggestions based upon
 * the visible members in that library. Clients should call
 * [LibraryElementSuggestionBuilder.suggestionsFor].
 */
class LibraryElementSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder {
  final DartCompletionRequest request;
  final CompletionSuggestionKind kind;
  final bool typesOnly;

  LibraryElementSuggestionBuilder(this.request, this.kind, this.typesOnly);

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
    if (!typesOnly) {
      addSuggestion(element);
    }
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    addSuggestion(element);
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!typesOnly) {
      addSuggestion(element);
    }
  }

  /**
   * Add suggestions for the visible members in the given library
   */
  static void suggestionsFor(DartCompletionRequest request,
      CompletionSuggestionKind kind, LibraryElement library, bool typesOnly) {
    if (library != null) {
      library.visitChildren(
          new LibraryElementSuggestionBuilder(request, kind, typesOnly));
    }
  }
}

/**
 * This class visits elements in a class and provides suggestions based upon
 * the visible named constructors in that class.
 */
class NamedConstructorSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder implements SuggestionBuilder {
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
 * This class visits elements in a class and provides suggestions based upon
 * the visible static members in that class. Clients should call
 * [StaticClassElementSuggestionBuilder.suggestionsFor].
 */
class StaticClassElementSuggestionBuilder extends GeneralizingElementVisitor
    with ElementSuggestionBuilder {
  final DartCompletionRequest request;

  StaticClassElementSuggestionBuilder(this.request);

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
    if (!element.isStatic) {
      return;
    }
    addSuggestion(element);
  }

  @override
  visitMethodElement(MethodElement element) {
    if (!element.isStatic) {
      return;
    }
    if (element.isOperator) {
      return;
    }
    addSuggestion(element);
  }

  @override
  visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (!element.isStatic) {
      return;
    }
    addSuggestion(element);
  }

  /**
   * Add suggestions for the visible members in the given class
   */
  static void suggestionsFor(DartCompletionRequest request, Element element) {
    if (element == DynamicElementImpl.instance) {
      element = request.cache.objectClassElement;
    }
    if (element is ClassElement) {
      return element.accept(new StaticClassElementSuggestionBuilder(request));
    }
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
