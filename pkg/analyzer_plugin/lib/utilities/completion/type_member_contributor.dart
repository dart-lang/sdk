// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/suggestion_builder.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:analyzer_plugin/utilities/completion/suggestion_builder.dart';

/**
 * A completion contributor that will generate suggestions for instance
 * invocations and accesses.
 */
class TypeMemberContributor implements CompletionContributor {
  /**
   * Plugin contributors should primarily overload this function.
   * Should more parameters be needed for autocompletion needs, the
   * overloaded function should define those parameters and
   * call on `computeSuggestionsWithEntryPoint`.
   */
  @override
  Future<Null> computeSuggestions(
      DartCompletionRequest request, CompletionCollector collector) async {
    LibraryElement containingLibrary = request.result.libraryElement;
    // Gracefully degrade if the library element is not resolved
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return;
    }

    // Recompute the target since resolution may have changed it
    Expression expression = _computeDotTarget(request, null);
    if (expression == null || expression.isSynthetic) {
      return;
    }
    _computeSuggestions(request, collector, containingLibrary, expression);
  }

  /**
   * Clients should not overload this function.
   */
  Future<Null> computeSuggestionsWithEntryPoint(DartCompletionRequest request,
      CompletionCollector collector, AstNode entryPoint) async {
    LibraryElement containingLibrary = request.result.libraryElement;
    // Gracefully degrade if the library element is not resolved
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return;
    }

    // Recompute the target since resolution may have changed it
    Expression expression = _computeDotTarget(request, entryPoint);
    if (expression == null || expression.isSynthetic) {
      return;
    }
    _computeSuggestions(request, collector, containingLibrary, expression);
  }

  /**
   * Update the completion [target] and [dotTarget] based on the given [unit].
   */
  Expression _computeDotTarget(
      DartCompletionRequest request, AstNode entryPoint) {
    CompletionTarget target = new CompletionTarget.forOffset(
        request.result.unit, request.offset,
        entryPoint: entryPoint);
    AstNode node = target.containingNode;
    if (node is MethodInvocation) {
      if (identical(node.methodName, target.entity)) {
        return node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == target.offset) {
        return node.realTarget;
      }
    }
    if (node is PropertyAccess) {
      if (identical(node.propertyName, target.entity)) {
        return node.realTarget;
      } else if (node.isCascaded && node.operator.offset + 1 == target.offset) {
        return node.realTarget;
      }
    }
    if (node is PrefixedIdentifier) {
      if (identical(node.identifier, target.entity)) {
        return node.prefix;
      }
    }
    return null;
  }

  void _computeSuggestions(
      DartCompletionRequest request,
      CompletionCollector collector,
      LibraryElement containingLibrary,
      Expression expression) {
    if (expression is Identifier) {
      Element element = expression.bestElement;
      if (element is ClassElement) {
        // Suggestions provided by StaticMemberContributor
        return;
      }
      if (element is PrefixElement) {
        // Suggestions provided by LibraryMemberContributor
        return;
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
      type = request.result.typeProvider.objectType;
    }

    // Build the suggestions
    if (type is InterfaceType) {
      _SuggestionBuilder builder = new _SuggestionBuilder(
          request.resourceProvider, collector, containingLibrary);
      builder.buildSuggestions(type, containingMethodName);
    }
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
   * The resource provider used to access the file system.
   */
  final ResourceProvider resourceProvider;

  /**
   * The collector being used to collect completion suggestions.
   */
  final CompletionCollector collector;

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

  /**
   * The builder used to build suggestions.
   */
  final SuggestionBuilder builder;

  _SuggestionBuilder(
      this.resourceProvider, this.collector, this.containingLibrary)
      : builder = new SuggestionBuilderImpl(resourceProvider);

  Iterable<CompletionSuggestion> get suggestions => _suggestionMap.values;

  /**
   * Create completion suggestions for 'dot' completions on the given [type].
   * If the 'dot' completion is a super expression, then [containingMethodName]
   * is the name of the method in which the completion is requested.
   */
  void buildSuggestions(InterfaceType type, String containingMethodName) {
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
          _addSuggestion(method,
              relevance: method.name == containingMethodName
                  ? DART_RELEVANCE_HIGH
                  : null);
        }
      }
      for (PropertyAccessorElement propertyAccessor in targetType.accessors) {
        if (!propertyAccessor.isStatic) {
          if (propertyAccessor.isSynthetic) {
            // Avoid visiting a field twice
            if (propertyAccessor.isGetter) {
              _addSuggestion(propertyAccessor.variable);
            }
          } else {
            _addSuggestion(propertyAccessor);
          }
        }
      }
    }
    for (CompletionSuggestion suggestion in suggestions) {
      collector.addSuggestion(suggestion);
    }
  }

  /**
   * Add a suggestion based upon the given element, provided that it is not
   * shadowed by a previously added suggestion.
   */
  void _addSuggestion(Element element, {int relevance}) {
    if (element.isPrivate) {
      if (element.library != containingLibrary) {
        // Do not suggest private members for imported libraries
        return;
      }
    }
    String identifier = element.displayName;

    if (relevance == null) {
      // Decrease relevance of suggestions starting with $
      // https://github.com/dart-lang/sdk/issues/27303
      if (identifier != null && identifier.startsWith(r'$')) {
        relevance = DART_RELEVANCE_LOW;
      } else {
        relevance = DART_RELEVANCE_DEFAULT;
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
        builder.forElement(element, relevance: relevance);
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
