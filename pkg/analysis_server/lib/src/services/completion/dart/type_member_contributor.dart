// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/local_declaration_visitor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../../protocol_server.dart' show CompletionSuggestion;

/**
 * A contributor for calculating instance invocation / access suggestions
 * `completion.getSuggestions` request results.
 */
class TypeMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    LibraryElement containingLibrary = request.libraryElement;
    // Gracefully degrade if the library element is not resolved
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return EMPTY_LIST;
    }

    // Recompute the target since resolution may have changed it
    Expression expression = request.dotTarget;
    if (expression == null || expression.isSynthetic) {
      return EMPTY_LIST;
    }
    if (expression is Identifier) {
      Element elem = expression.bestElement;
      if (elem is ClassElement) {
        // Suggestions provided by StaticMemberContributor
        return EMPTY_LIST;
      }
      if (elem is PrefixElement) {
        // Suggestions provided by LibraryMemberContributor
        return EMPTY_LIST;
      }
    }

    // Determine the target expression's type
    DartType type = expression.bestType;
    if (type.isDynamic) {
      // If the expression does not provide a good type
      // then attempt to get a better type from the element
      if (expression is Identifier) {
        Element elem = expression.bestElement;
        if (elem is FunctionTypedElement) {
          type = elem.returnType;
        } else if (elem is ParameterElement) {
          type = elem.type;
        } else if (elem is LocalVariableElement) {
          type = elem.type;
        }
        if ((type == null || type.isDynamic) &&
            expression is SimpleIdentifier) {
          // If the element does not provide a good type
          // then attempt to get a better type from a local declaration
          _LocalBestTypeVisitor visitor =
              new _LocalBestTypeVisitor(expression.name, request.offset);
          if (visitor.visit(expression) && visitor.typeFound != null) {
            type = visitor.typeFound;
          }
        }
      }
    }
    String containingMethodName;
    if (expression is SuperExpression && type is InterfaceType) {
      // Suggest members from superclass if target is "super"
      type = (type as InterfaceType).superclass;
      // Determine the name of the containing method because
      // the most likely completion is a super expression with same name
      MethodDeclaration containingMethod =
          expression.getAncestor((p) => p is MethodDeclaration);
      if (containingMethod != null) {
        SimpleIdentifier id = containingMethod.name;
        if (id != null) {
          containingMethodName = id.name;
        }
      }
    }
    if (type.isDynamic) {
      // Suggest members from object if target is "dynamic"
      type = request.objectType;
    }

    // Build the suggestions
    if (type is InterfaceType) {
      _SuggestionBuilder builder = new _SuggestionBuilder(containingLibrary);
      builder.buildSuggestions(type, containingMethodName, request.ideOptions);
      return builder.suggestions.toList();
    }
    return EMPTY_LIST;
  }
}

/**
 * An [AstVisitor] which looks for a declaration with the given name
 * and if found, tries to determine a type for that declaration.
 */
class _LocalBestTypeVisitor extends LocalDeclarationVisitor {
  /**
   * The name for the declaration to be found.
   */
  final String targetName;

  /**
   * The best type for the found declaration,
   * or `null` if no declaration found or failed to determine a type.
   */
  DartType typeFound;

  /**
   * Construct a new instance to search for a declaration
   */
  _LocalBestTypeVisitor(this.targetName, int offset) : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (declaration.name.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (declaration.name.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (varDecl.name.name == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (declaration.name.name == targetName) {
      TypeAnnotation typeName = declaration.returnType;
      if (typeName != null) {
        typeFound = typeName.type;
      }
      finished();
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (declaration.name.name == targetName) {
      TypeAnnotation typeName = declaration.returnType;
      if (typeName != null) {
        typeFound = typeName.type;
      }
      finished();
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (label.label.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeAnnotation type) {
    if (name.name == targetName) {
      typeFound = name.bestType;
      finished();
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if (declaration.name.name == targetName) {
      TypeAnnotation typeName = declaration.returnType;
      if (typeName != null) {
        typeFound = typeName.type;
      }
      finished();
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeAnnotation type) {
    if (name.name == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (varDecl.name.name == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }
}

/**
 * This class provides suggestions based upon the visible instance members in
 * an interface type.
 */
class _SuggestionBuilder {
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

  /**
   * The library containing the unit in which the completion is requested.
   */
  final LibraryElement containingLibrary;

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

  /**
   * Map from completion identifier to completion suggestion
   */
  Map<String, CompletionSuggestion> _suggestionMap =
      <String, CompletionSuggestion>{};

  _SuggestionBuilder(this.containingLibrary);

  Iterable<CompletionSuggestion> get suggestions => _suggestionMap.values;

  /**
   * Return completion suggestions for 'dot' completions on the given [type].
   * If the 'dot' completion is a super expression, then [containingMethodName]
   * is the name of the method in which the completion is requested.
   */
  void buildSuggestions(
      InterfaceType type, String containingMethodName, IdeOptions ideOptions) {
    // Visit all of the types in the class hierarchy, collecting possible
    // completions.  If multiple elements are found that complete to the same
    // identifier, addSuggestion will discard all but the first (with a few
    // exceptions to handle getter/setter pairs).
    List<InterfaceType> types = _getTypeOrdering(type);
    for (InterfaceType targetType in types) {
      for (MethodElement method in targetType.methods) {
        // Exclude static methods when completion on an instance
        if (!method.isStatic) {
          // Boost the relevance of a super expression
          // calling a method of the same name as the containing method
          _addSuggestion(method, ideOptions,
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
              _addSuggestion(propertyAccessor.variable, ideOptions);
            }
          } else {
            _addSuggestion(propertyAccessor, ideOptions);
          }
        }
      }
    }
  }

  /**
   * Add a suggestion based upon the given element, provided that it is not
   * shadowed by a previously added suggestion.
   */
  void _addSuggestion(Element element, IdeOptions options,
      {int relevance: DART_RELEVANCE_DEFAULT}) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
        // Do not suggest private members for imported libraries
        return;
      }
    }
    String identifier = element.displayName;

    if (relevance == DART_RELEVANCE_DEFAULT && identifier != null) {
      // Decrease relevance of suggestions starting with $
      // https://github.com/dart-lang/sdk/issues/27303
      if (identifier.startsWith(r'$')) {
        relevance = DART_RELEVANCE_LOW;
      }
    }

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
        createSuggestion(element, options, relevance: relevance);
    if (suggestion != null) {
      _suggestionMap[suggestion.completion] = suggestion;
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
}
