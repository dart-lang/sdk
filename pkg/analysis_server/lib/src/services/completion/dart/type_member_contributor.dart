// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart';
import 'package:meta/meta.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/// A contributor for calculating instance invocation / access suggestions
/// `completion.getSuggestions` request results.
class TypeMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    LibraryElement containingLibrary = request.libraryElement;
    // Gracefully degrade if the library element is not resolved
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return const <CompletionSuggestion>[];
    }

    // Recompute the target since resolution may have changed it
    Expression expression = request.dotTarget;
    if (expression == null ||
        expression.isSynthetic ||
        expression is ExtensionOverride) {
      return const <CompletionSuggestion>[];
    }
    if (expression is Identifier) {
      Element elem = expression.staticElement;
      if (elem is ClassElement) {
        // Suggestions provided by StaticMemberContributor
        return const <CompletionSuggestion>[];
      }
      if (elem is PrefixElement) {
        // Suggestions provided by LibraryMemberContributor
        return const <CompletionSuggestion>[];
      }
    }

    // Determine the target expression's type
    DartType type = expression.staticType;
    if (type == null || type.isDynamic) {
      // If the expression does not provide a good type
      // then attempt to get a better type from the element
      if (expression is Identifier) {
        Element elem = expression.staticElement;
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
              _LocalBestTypeVisitor(expression.name, request.offset);
          if (visitor.visit(expression) && visitor.typeFound != null) {
            type = visitor.typeFound;
          }
        }
      }
    }
    String containingMethodName;
    List<InterfaceType> mixins;
    List<InterfaceType> superclassConstraints;
    if (expression is SuperExpression && type is InterfaceType) {
      // Suggest members from superclass if target is "super"
      mixins = (type as InterfaceType).mixins;
      superclassConstraints = (type as InterfaceType).superclassConstraints;
      type = (type as InterfaceType).superclass;
      // Determine the name of the containing method because
      // the most likely completion is a super expression with same name
      MethodDeclaration containingMethod =
          expression.thisOrAncestorOfType<MethodDeclaration>();
      if (containingMethod != null) {
        SimpleIdentifier id = containingMethod.name;
        if (id != null) {
          containingMethodName = id.name;
        }
      }
    }
    if (type == null || type.isDynamic) {
      // Suggest members from object if target is "dynamic"
      type = request.objectType;
    }

    // Build the suggestions
    if (type is InterfaceType) {
      _SuggestionBuilder builder = _SuggestionBuilder(request);
      builder.buildSuggestions(type, containingMethodName,
          mixins: mixins, superclassConstraints: superclassConstraints);
      return builder.suggestions.toList();
    }
    if (type is FunctionType) {
      return [_SuggestionBuilder._createFunctionCallSuggestion()];
    }

    return const <CompletionSuggestion>[];
  }
}

/// An [AstVisitor] which looks for a declaration with the given name
/// and if found, tries to determine a type for that declaration.
class _LocalBestTypeVisitor extends LocalDeclarationVisitor {
  /// The name for the declaration to be found.
  final String targetName;

  /// The best type for the found declaration,
  /// or `null` if no declaration found or failed to determine a type.
  DartType typeFound;

  /// Construct a new instance to search for a declaration
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
  void declaredExtension(ExtensionDeclaration declaration) {}

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
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {
    if (declaration.name.name == targetName) {
      TypeAnnotation typeName = declaration.functionType?.returnType;
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
      var element = name.staticElement as VariableElement;
      typeFound = element.type;
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

/// This class provides suggestions based upon the visible instance members in
/// an interface type.
class _SuggestionBuilder extends MemberSuggestionBuilder {
  final DartCompletionRequest request;

  _SuggestionBuilder(this.request) : super(request.libraryElement);

  /// Return completion suggestions for 'dot' completions on the given [type].
  /// If the 'dot' completion is a super expression, then [containingMethodName]
  /// is the name of the method in which the completion is requested.
  void buildSuggestions(InterfaceType type, String containingMethodName,
      {List<InterfaceType> mixins, List<InterfaceType> superclassConstraints}) {
    // Visit all of the types in the class hierarchy, collecting possible
    // completions.  If multiple elements are found that complete to the same
    // identifier, addSuggestion will discard all but the first (with a few
    // exceptions to handle getter/setter pairs).
    List<InterfaceType> types = _getTypeOrdering(type);
    if (mixins != null) {
      types.addAll(mixins);
    }
    if (superclassConstraints != null) {
      types.addAll(superclassConstraints);
    }
    var featureComputer =
        FeatureComputer(request.result.typeSystem, request.result.typeProvider);
    for (InterfaceType targetType in types) {
      var inheritanceDistance = featureComputer.inheritanceDistanceFeature(
          type.element, targetType.element);
      for (MethodElement method in targetType.methods) {
        // Exclude static methods when completion on an instance
        if (!method.isStatic) {
          // Boost the relevance of a super expression
          // calling a method of the same name as the containing method
          int relevance;
          if (request.useNewRelevance) {
            var contextType = featureComputer.contextTypeFeature(
                request.target.containingNode, method.returnType);
            var startsWithDollar =
                featureComputer.startsWithDollarFeature(method.name);
            var superMatches = featureComputer.superMatchesFeature(
                containingMethodName, method.name);
            relevance = _computeRelevance(
                contextType: contextType,
                inheritanceDistance: inheritanceDistance,
                startsWithDollar: startsWithDollar,
                superMatches: superMatches);
          } else {
            relevance = method.name == containingMethodName
                ? DART_RELEVANCE_HIGH
                : DART_RELEVANCE_DEFAULT;
          }
          addSuggestion(method, relevance: relevance);
        }
      }
      for (PropertyAccessorElement propertyAccessor in targetType.accessors) {
        if (!propertyAccessor.isStatic) {
          if (propertyAccessor.isSynthetic) {
            // Avoid visiting a field twice
            if (propertyAccessor.isGetter) {
              var variable = propertyAccessor.variable;
              int relevance;
              if (request.useNewRelevance) {
                var contextType = featureComputer.contextTypeFeature(
                    request.target.containingNode, variable.type);
                var startsWithDollar = featureComputer
                    .startsWithDollarFeature(propertyAccessor.name);
                var superMatches = featureComputer.superMatchesFeature(
                    containingMethodName, propertyAccessor.name);
                relevance = _computeRelevance(
                    contextType: contextType,
                    inheritanceDistance: inheritanceDistance,
                    startsWithDollar: startsWithDollar,
                    superMatches: superMatches);
              }
              addSuggestion(variable, relevance: relevance);
            }
          } else {
            var type = propertyAccessor.isGetter
                ? propertyAccessor.returnType
                : propertyAccessor.parameters[0].type;
            int relevance;
            if (request.useNewRelevance) {
              var contextType = featureComputer.contextTypeFeature(
                  request.target.containingNode, type);
              var startsWithDollar = featureComputer
                  .startsWithDollarFeature(propertyAccessor.name);
              var superMatches = featureComputer.superMatchesFeature(
                  containingMethodName, propertyAccessor.name);
              relevance = _computeRelevance(
                  contextType: contextType,
                  inheritanceDistance: inheritanceDistance,
                  startsWithDollar: startsWithDollar,
                  superMatches: superMatches);
            }
            addSuggestion(propertyAccessor, relevance: relevance);
          }
        }
      }
      if (targetType.isDartCoreFunction) {
        addCompletionSuggestion(_createFunctionCallSuggestion());
      }
    }
  }

  /// Compute a relevance value from the given feature scores:
  /// - [contextType] is higher if the type of the element matches the context
  ///   type,
  /// - [inheritanceDistance] is higher if the element is defined closer to the
  ///   target type,
  /// - [startsWithDollar] is higher if the element's name doe _not_ start with
  ///   a dollar sign, and
  /// - [superMatches] is higher if the element is being invoked through `super`
  ///   and the element's name matches the name of the enclosing method.
  int _computeRelevance(
      {@required double contextType,
      @required double inheritanceDistance,
      @required double startsWithDollar,
      @required double superMatches}) {
    return toRelevance(weightedAverage(
        [contextType, inheritanceDistance, startsWithDollar, superMatches],
        [1.0, 1.0, 0.5, 1.0]));
  }

  /// Get a list of [InterfaceType]s that should be searched to find the
  /// possible completions for an object having type [type].
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
    Set<ClassElement> classesSeen = HashSet<ClassElement>();
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
      typesToVisit.addAll(nextType.superclassConstraints);
      typesToVisit.addAll(nextType.mixins);
    }
    return result;
  }

  static CompletionSuggestion _createFunctionCallSuggestion() {
    const callString = 'call()';
    final element = protocol.Element(
        protocol.ElementKind.METHOD, callString, protocol.Element.makeFlags(),
        location: null,
        typeParameters: null,
        parameters: null,
        returnType: 'void');
    return CompletionSuggestion(
      CompletionSuggestionKind.INVOCATION,
      DART_RELEVANCE_HIGH,
      callString,
      callString.length,
      0,
      false,
      false,
      displayText: callString,
      element: element,
      returnType: 'void',
    );
  }
}
