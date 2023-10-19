// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to compute the value of the features used for code
/// completion.
library;

import 'dart:math' as math;

import 'package:analysis_server/src/protocol_server.dart' as protocol
    show ElementKind;
import 'package:analysis_server/src/services/completion/dart/relevance_tables.g.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server/src/utilities/extensions/numeric.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

const List<String> intNames = ['i', 'j', 'index', 'length'];
const List<String> listNames = ['list', 'items'];

/// The maximum relevance score a completion can have.
const int maximumRelevance = 1000;

const List<String> numNames = ['height', 'width'];

const List<String> stringNames = [
  'key',
  'text',
  'url',
  'uri',
  'name',
  'str',
  'string'
];

/// Convert a relevance score (assumed to be between `0.0` and `1.0` inclusive)
/// to a relevance value between `0` and `1000` ([maximumRelevance]).
int toRelevance(double score) {
  assert(score.between(0.0, 1.0));
  return (score * maximumRelevance).truncate();
}

/// Return the weighted average of the given values, applying some constant and
/// predetermined weights.
double weightedAverage(
    {double contextType = 0.0,
    double elementKind = 0.0,
    double hasDeprecated = 0.0,
    double isConstant = 0.0,
    double isNoSuchMethod = 0.0,
    double isNotImported = 0.0,
    double keyword = 0.0,
    double startsWithDollar = 0.0,
    double superMatches = 0.0}) {
  assert(contextType.between(0.0, 1.0));
  assert(elementKind.between(0.0, 1.0));
  assert(hasDeprecated.between(-1.0, 0.0));
  assert(isConstant.between(0.0, 1.0));
  assert(isNoSuchMethod.between(-1.0, 0.0));
  assert(isNotImported.between(-1.0, 0.0));
  assert(keyword.between(0.0, 1.0));
  assert(startsWithDollar.between(-1.0, 0.0));
  assert(superMatches.between(0.0, 1.0));
  var average = _weightedAverage([
    contextType,
    elementKind,
    hasDeprecated,
    isConstant,
    isNoSuchMethod,
    isNotImported,
    keyword,
    startsWithDollar,
    superMatches,
  ], FeatureComputer.featureWeights);
  return (average + 1.0) / 2.0;
}

DartType? _impliedDartTypeWithName(TypeProvider typeProvider, String name) {
  if (name.isEmpty) {
    return null;
  }
  if (intNames.contains(name)) {
    return typeProvider.intType;
  } else if (numNames.contains(name)) {
    return typeProvider.numType;
  } else if (listNames.contains(name)) {
    return typeProvider.listType(typeProvider.dynamicType);
  } else if (stringNames.contains(name)) {
    return typeProvider.stringType;
  } else if (name == 'iterator') {
    return typeProvider.iterableDynamicType;
  } else if (name == 'map') {
    return typeProvider.mapType(
        typeProvider.dynamicType, typeProvider.dynamicType);
  }
  return null;
}

/// Return the weighted average of the given [values], applying the given
/// [weights]. The number of weights must be equal to the number of values.
double _weightedAverage(List<double> values, List<double> weights) {
  assert(values.length == weights.length);
  var totalValue = 0.0;
  var totalWeight = 0.0;
  for (var i = 0; i < values.length; i++) {
    var value = values[i];
    var weight = weights[i];
    totalWeight += weight;
    totalValue += value * weight;
  }
  return totalValue / totalWeight;
}

/// An object that computes the values of features.
class FeatureComputer {
  /// The names of features whose values are averaged.
  static List<String> featureNames = [
    'contextType',
    'elementKind',
    'hasDeprecated',
    'inheritanceDistance',
    'isConstant',
    'isNoSuchMethod',
    'keyword',
    'localVariableDistance',
    'startsWithDollar',
    'superMatches',
  ];

  /// The values of the weights used to compute an average of feature values.
  static List<double> featureWeights = defaultFeatureWeights;

  /// The default values of the weights used to compute an average of feature
  /// values.
  static const List<double> defaultFeatureWeights = [
    1.00, // contextType
    1.00, // elementKind
    0.50, // hasDeprecated
    1.00, // isConstant
    1.00, // isNoSuchMethod
    1.00, // isNotImported
    1.00, // keyword
    0.50, // startsWithDollar
    1.00, // superMatches
  ];

  /// The type system used to perform operations on types.
  final TypeSystem typeSystem;

  /// The type provider used to access types defined by the spec.
  final TypeProvider typeProvider;

  /// Initialize a newly created feature computer.
  FeatureComputer(this.typeSystem, this.typeProvider);

  /// Return the type imposed when completing at the given [offset], where the
  /// offset is within the given [node], or `null` if the context does not
  /// impose any type.
  DartType? computeContextType(AstNode node, int offset) {
    final contextType = node.accept(
      _ContextTypeVisitor(typeProvider, offset),
    );
    if (contextType == null || contextType is DynamicType) {
      return null;
    }
    return typeSystem.resolveToBound(contextType);
  }

  /// Return the element kind used to compute relevance for the given [element].
  /// This differs from the kind returned to the client in that getters and
  /// setters are always mapped into a different kind: FIELD for getters and
  /// setters declared in a class or extension, and TOP_LEVEL_VARIABLE for
  /// top-level getters and setters.
  protocol.ElementKind computeElementKind(Element element) {
    if (element is LibraryElement) {
      return protocol.ElementKind.PREFIX;
    } else if (element is EnumElement) {
      return protocol.ElementKind.ENUM;
    } else if (element is MixinElement) {
      return protocol.ElementKind.MIXIN;
    } else if (element is ClassElement) {
      return protocol.ElementKind.CLASS;
    } else if (element is FieldElement && element.isEnumConstant) {
      return protocol.ElementKind.ENUM_CONSTANT;
    } else if (element is PropertyAccessorElement) {
      element = element.variable;
    }
    var kind = element.kind;
    if (kind == ElementKind.CONSTRUCTOR) {
      return protocol.ElementKind.CONSTRUCTOR;
    } else if (kind == ElementKind.EXTENSION) {
      return protocol.ElementKind.EXTENSION;
    } else if (kind == ElementKind.FIELD) {
      return protocol.ElementKind.FIELD;
    } else if (kind == ElementKind.FUNCTION) {
      return protocol.ElementKind.FUNCTION;
    } else if (kind == ElementKind.FUNCTION_TYPE_ALIAS) {
      return protocol.ElementKind.FUNCTION_TYPE_ALIAS;
    } else if (kind == ElementKind.GENERIC_FUNCTION_TYPE) {
      return protocol.ElementKind.FUNCTION_TYPE_ALIAS;
    } else if (kind == ElementKind.LABEL) {
      return protocol.ElementKind.LABEL;
    } else if (kind == ElementKind.LOCAL_VARIABLE) {
      return protocol.ElementKind.LOCAL_VARIABLE;
    } else if (kind == ElementKind.METHOD) {
      return protocol.ElementKind.METHOD;
    } else if (kind == ElementKind.PARAMETER) {
      return protocol.ElementKind.PARAMETER;
    } else if (kind == ElementKind.PREFIX) {
      return protocol.ElementKind.PREFIX;
    } else if (kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return protocol.ElementKind.TOP_LEVEL_VARIABLE;
    } else if (kind == ElementKind.TYPE_ALIAS) {
      return protocol.ElementKind.TYPE_ALIAS;
    } else if (kind == ElementKind.TYPE_PARAMETER) {
      return protocol.ElementKind.TYPE_PARAMETER;
    }
    return protocol.ElementKind.UNKNOWN;
  }

  /// Return the value of the _context type_ feature for an element with the
  /// given [elementType] when completing in a location with the given
  /// [contextType].
  double contextTypeFeature(DartType? contextType, DartType? elementType) {
    if (contextType == null || elementType == null) {
      // Disable the feature if we don't have both types.
      return 0.0;
    }
    if (elementType == contextType) {
      // Exact match.
      return 1.0;
    } else if (typeSystem.isSubtypeOf(elementType, contextType)) {
      // Subtype.
      return 0.40;
    } else if (typeSystem.isSubtypeOf(contextType, elementType)) {
      // Supertype.
      return 0.02;
    } else {
      // Unrelated.
      return 0.13;
    }
  }

  /// Return the value of the _element kind_ feature for the [element] when
  /// completing at the given [completionLocation]. If a [distance] is given it
  /// will be used to provide finer-grained relevance scores.
  double elementKindFeature(Element element, String? completionLocation,
      {double? distance}) {
    if (completionLocation == null) {
      return 0.0;
    }
    var locationTable = elementKindRelevance[completionLocation];
    if (locationTable == null) {
      return 0.0;
    }
    var range = locationTable[computeElementKind(element)];
    if (range == null) {
      return 0.0;
    }
    if (distance == null) {
      return range.middle;
    }
    return range.conditionalProbability(distance);
  }

  /// Return the value of the _has deprecated_ feature for the given [element].
  double hasDeprecatedFeature(Element element) {
    return element.hasOrInheritsDeprecated ? -1.0 : 0.0;
  }

  /// Return the inheritance distance between the [subclass] and the
  /// [superclass]. We define the inheritance distance between two types to be
  /// zero if the two types are the same and the minimum number of edges that
  /// must be traversed in the type graph to get from the subtype to the
  /// supertype if the two types are not the same. Return `-1` if the [subclass]
  /// is not a subclass of the [superclass].
  int inheritanceDistance(
      InterfaceElement subclass, InterfaceElement superclass) {
    // This method is only visible for the metrics computation and might be made
    // private at some future date.
    return _inheritanceDistance(subclass, superclass, {});
  }

  /// Return the value of the _inheritance distance_ feature for a member
  /// defined in the [superclass] that is being accessed through an expression
  /// whose static type is the [subclass].
  double inheritanceDistanceFeature(
      InterfaceElement subclass, InterfaceElement superclass) {
    var distance = _inheritanceDistance(subclass, superclass, {});
    return _distanceToPercent(distance);
  }

  /// Return the value of the _is constant_ feature for the given [element].
  double isConstantFeature(Element element) {
    if (element is ConstructorElement && element.isConst) {
      return 1.0;
    } else if (element is FieldElement && element.isStatic && element.isConst) {
      return 1.0;
    } else if (element is TopLevelVariableElement && element.isConst) {
      return 1.0;
    } else if (element is PropertyAccessorElement &&
        element.isSynthetic &&
        element.variable.isStatic &&
        element.variable.isConst) {
      return 1.0;
    }
    return 0.0;
  }

  /// Return the value of the _is noSuchMethod_ feature.
  double isNoSuchMethodFeature(
      String? containingMethodName, String proposedMemberName) {
    if (proposedMemberName == containingMethodName) {
      // Don't penalize `noSuchMethod` when completing after `super` in an
      // override of `noSuchMethod`.
      return 0.0;
    }
    return proposedMemberName == FunctionElement.NO_SUCH_METHOD_METHOD_NAME
        ? -1.0
        : 0.0;
  }

  /// Return the feature for the not-yet-imported property.
  double isNotImportedFeature(bool isNotImported) {
    return isNotImported ? -1.0 : 0.0;
  }

  /// Return the value of the _keyword_ feature for the [keyword] when
  /// completing at the given [completionLocation].
  double keywordFeature(String keyword, String? completionLocation) {
    if (completionLocation == null) {
      return 0.0;
    }
    var locationTable = keywordRelevance[completionLocation];
    if (locationTable == null) {
      return 0.0;
    }
    var range = locationTable[keyword];
    if (range == null) {
      // We sometimes suggest multiple tokens where a keyword is allowed, such
      // as 'async*'. In those cases a valid keyword is always first followed by
      // a non-alphabetic character. Try stripping off everything after the
      // keyword and indexing into the table again.
      var index = keyword.indexOf(RegExp('[^a-z]'));
      if (index > 0) {
        range = locationTable[keyword.substring(0, index)];
      }
    }
    if (range == null) {
      return 0.0;
    }
    return range.upper;
  }

  /// Return the distance between the [reference] and the referenced local
  /// [variable], where the distance is defined to be the number of variable
  /// declarations between the local variable and the reference.
  int localVariableDistance(AstNode reference, LocalVariableElement variable) {
    var distance = 0;
    AstNode? node = reference;
    while (node != null) {
      if (node is ForStatement || node is ForElement) {
        var loopParts = node is ForStatement
            ? node.forLoopParts
            : (node as ForElement).forLoopParts;
        if (loopParts is ForPartsWithDeclarations) {
          for (var declaredVariable in loopParts.variables.variables.reversed) {
            if (declaredVariable.declaredElement == variable) {
              return distance;
            }
            distance++;
          }
        } else if (loopParts is ForEachPartsWithDeclaration) {
          if (loopParts.loopVariable.declaredElement == variable) {
            return distance;
          }
          distance++;
        }
      } else if (node is VariableDeclaration) {
        var parent = node.parent;
        if (parent is VariableDeclarationList) {
          var variables = parent.variables;
          var index = variables.indexOf(node);
          for (var i = index - 1; i >= 0; i--) {
            var declaredVariable = variables[i];
            if (declaredVariable.declaredElement == variable) {
              return distance;
            }
            distance++;
          }
        }
      } else if (node is CatchClause) {
        if (node.exceptionParameter?.declaredElement == variable ||
            node.stackTraceParameter?.declaredElement == variable) {
          return distance;
        }
      }
      if (node is Statement) {
        var parent = node.parent;
        var statements = const <Statement>[];
        if (parent is Block) {
          statements = parent.statements;
        } else if (parent is SwitchCase) {
          statements = parent.statements;
        } else if (parent is SwitchDefault) {
          statements = parent.statements;
        }
        var index = statements.indexOf(node);
        for (var i = index - 1; i >= 0; i--) {
          var statement = statements[i];
          if (statement is VariableDeclarationStatement) {
            for (var declaredVariable
                in statement.variables.variables.reversed) {
              if (declaredVariable.declaredElement == variable) {
                return distance;
              }
              distance++;
            }
          }
        }
      }
      node = node.parent;
    }
    return -1;
  }

  /// Return the value of the _local variable distance_ feature for a local
  /// variable whose declaration is separated from the completion location by
  /// [distance] other variable declarations.
  double localVariableDistanceFeature(
      AstNode reference, LocalVariableElement variable) {
    var distance = localVariableDistance(reference, variable);
    return _distanceToPercent(distance);
  }

  /// Return the value of the _starts with dollar_ feature.
  double startsWithDollarFeature(String name) {
    return name.startsWith('\$') ? -1.0 : 0.0;
  }

  /// Return the value of the _super matches_ feature.
  double superMatchesFeature(
          String? containingMethodName, String proposedMemberName) =>
      containingMethodName == null
          ? 0.0
          : (proposedMemberName == containingMethodName ? 1.0 : 0.0);

  /// Convert a [distance] to a percentage value and return the percentage. If
  /// the [distance] is negative, return `0.0`.
  double _distanceToPercent(int distance) {
    if (distance < 0) {
      return 0.0;
    }
    return math.pow(0.9, distance) as double;
  }

  /// Return the inheritance distance between the [subclass] and the
  /// [superclass]. The set of [visited] elements is used to guard against
  /// cycles in the type graph.
  ///
  /// This is the implementation of [inheritanceDistance].
  int _inheritanceDistance(InterfaceElement? subclass,
      InterfaceElement superclass, Set<InterfaceElement> visited) {
    if (subclass == null) {
      return -1;
    } else if (subclass == superclass) {
      return 0;
    } else if (!visited.add(subclass)) {
      return -1;
    }
    var minDepth =
        _inheritanceDistance(subclass.supertype?.element, superclass, visited);

    void visitTypes(List<InterfaceType> types) {
      for (var type in types) {
        var depth = _inheritanceDistance(type.element, superclass, visited);
        if (minDepth < 0 || (depth >= 0 && depth < minDepth)) {
          minDepth = depth;
        }
      }
    }

    if (subclass is MixinElement) {
      visitTypes(subclass.superclassConstraints);
    }
    visitTypes(subclass.mixins);
    visitTypes(subclass.interfaces);

    visited.remove(subclass);
    if (minDepth < 0) {
      return minDepth;
    }
    return minDepth + 1;
  }
}

/// An visitor used to compute the required type of an expression or identifier
/// based on its context. The visitor should be initialized with the node whose
/// context type is to be computed and the parent of that node should be
/// visited.
class _ContextTypeVisitor extends SimpleAstVisitor<DartType> {
  final TypeProvider typeProvider;

  int offset;

  _ContextTypeVisitor(this.typeProvider, this.offset);

  @override
  DartType? visitAdjacentStrings(AdjacentStrings node) {
    if (offset == node.offset) {
      return _visitParent(node);
    }
    return typeProvider.stringType;
  }

  @override
  DartType? visitArgumentList(ArgumentList node) {
    if (range
        .endStart(node.leftParenthesis, node.rightParenthesis)
        .contains(offset)) {
      final parameters = node.functionType?.parameters;
      if (parameters == null) {
        return null;
      }

      var index = 0;

      DartType? typeOfIndexPositionalParameter() {
        if (index < parameters.length) {
          var parameter = parameters[index];
          if (parameter.isPositional) {
            return parameter.type;
          }
        }
        return null;
      }

      Expression? previousArgument;
      for (var argument in node.arguments) {
        if (argument is NamedExpression) {
          if (offset <= argument.offset) {
            return typeOfIndexPositionalParameter();
          }
          if (argument.contains(offset)) {
            if (offset >= argument.name.end) {
              return argument.staticParameterElement?.type;
            }
            return null;
          }
        } else {
          if (previousArgument == null || previousArgument.end < offset) {
            if (offset <= argument.end) {
              return argument.staticParameterElement?.type;
            }
          }
          previousArgument = argument;
          index++;
        }
      }

      return typeOfIndexPositionalParameter();
    }
    return null;
  }

  @override
  DartType? visitAsExpression(AsExpression node) {
    if (node.asOperator.end < offset) {
      return node.expression.staticType;
    }
    return null;
  }

  @override
  DartType? visitAssertInitializer(AssertInitializer node) {
    if (range
        .endStart(node.leftParenthesis,
            node.message?.beginToken.previous ?? node.rightParenthesis)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitAssertStatement(AssertStatement node) {
    if (range
        .endStart(node.leftParenthesis,
            node.message?.beginToken.previous ?? node.rightParenthesis)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.end <= offset) {
      // RHS
      if (node.operator.type == TokenType.EQ) {
        return node.writeType;
      }
      var method = node.staticElement;
      if (method != null) {
        var parameters = method.parameters;
        if (parameters.isNotEmpty) {
          return parameters[0].type;
        }
      }
    }
    return null;
  }

  @override
  DartType? visitAwaitExpression(AwaitExpression node) {
    return _visitParent(node);
  }

  @override
  DartType? visitBinaryExpression(BinaryExpression node) {
    if (node.operator.end <= offset) {
      return node.rightOperand.staticParameterElement?.type;
    }
    return _visitParent(node);
  }

  @override
  DartType? visitCascadeExpression(CascadeExpression node) {
    if (offset == node.target.offset) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType? visitConditionalExpression(ConditionalExpression node) {
    if (offset <= node.question.offset) {
      return typeProvider.boolType;
    } else {
      return _visitParent(node);
    }
  }

  @override
  DartType? visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.equals.end <= offset) {
      var element = node.fieldName.staticElement;
      if (element is FieldElement) {
        return element.type;
      }
    }
    return null;
  }

  @override
  DartType? visitConstructorName(ConstructorName node) {
    return _visitParent(node);
  }

  @override
  DartType? visitConstructorReference(ConstructorReference node) {
    return _visitParent(node);
  }

  @override
  DartType? visitDefaultFormalParameter(DefaultFormalParameter node) {
    var separator = node.separator;
    if (separator != null && separator.end <= offset) {
      return node.parameter.declaredElement?.type;
    }
    return null;
  }

  @override
  DartType? visitDoStatement(DoStatement node) {
    if (range
        .endStart(node.leftParenthesis, node.rightParenthesis)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (range.endEnd(node.functionDefinition, node).contains(offset)) {
      var parent = node.parent;
      if (parent is MethodDeclaration) {
        var bodyContext = BodyInferenceContext.of(parent.body);
        // TODO(scheglov) https://github.com/dart-lang/sdk/issues/45429
        if (bodyContext == null) {
          throw StateError('''
Expected body context.
Method: $parent
Class: ${parent.parent}
''');
        }
        return bodyContext.contextType;
      } else if (parent is FunctionExpression) {
        var grandparent = parent.parent;
        if (grandparent is FunctionDeclaration) {
          return BodyInferenceContext.of(parent.body)?.contextType;
        }
        return _visitParent(parent);
      }
    }
    return null;
  }

  @override
  DartType? visitFieldDeclaration(FieldDeclaration node) {
    if (node.fields.contains(offset)) {
      return node.fields.accept(this);
    }
    return null;
  }

  @override
  DartType? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    if (range
        .startOffsetEndOffset(node.inKeyword.end, node.end)
        .contains(offset)) {
      var parent = node.parent;
      if ((parent is ForStatement && parent.awaitKeyword != null) ||
          (parent is ForElement && parent.awaitKeyword != null)) {
        return typeProvider.streamDynamicType;
      }
      return typeProvider.iterableDynamicType;
    }
    return null;
  }

  @override
  DartType? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    if (range.endEnd(node.inKeyword, node).contains(offset)) {
      var parent = node.parent;
      if ((parent is ForStatement && parent.awaitKeyword != null) ||
          (parent is ForElement && parent.awaitKeyword != null)) {
        return typeProvider.streamDynamicType;
      }
      return typeProvider.iterableDynamicType;
    }
    return null;
  }

  @override
  DartType? visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    if (range
        .startOffsetEndOffset(node.inKeyword.end, node.end)
        .contains(offset)) {
      return typeProvider.iterableDynamicType;
    }
    return null;
  }

  @override
  DartType? visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    if (range
        .endStart(node.leftSeparator, node.rightSeparator)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitForPartsWithExpression(ForPartsWithExpression node) {
    if (range
        .endStart(node.leftSeparator, node.rightSeparator)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitForPartsWithPattern(ForPartsWithPattern node) {
    if (range
        .endStart(node.leftSeparator, node.rightSeparator)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    if (node.function.contains(offset)) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType? visitIfElement(IfElement node) {
    if (range
        .endStart(node.leftParenthesis, node.rightParenthesis)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitIfStatement(IfStatement node) {
    if (range
        .endStart(node.leftParenthesis, node.rightParenthesis)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitIndexExpression(IndexExpression node) {
    if (range.endStart(node.leftBracket, node.rightBracket).contains(offset)) {
      var parameters = node.staticElement?.parameters;
      if (parameters != null && parameters.isNotEmpty) {
        return parameters[0].type;
      }
    }
    return null;
  }

  @override
  DartType? visitIsExpression(IsExpression node) {
    if (node.isOperator.end < offset) {
      return node.expression.staticType;
    }
    return null;
  }

  @override
  DartType? visitLabel(Label node) {
    if (offset == node.offset) {
      return _visitParent(node);
    }
    if (node.colon.end <= offset) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType? visitListLiteral(ListLiteral node) {
    if (range.endStart(node.leftBracket, node.rightBracket).contains(offset)) {
      final type = node.staticType;
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/48965
      if (type == null) {
        throw '''
No type.
node: $node
parent: ${node.parent}
parent2: ${node.parent?.parent}
parent3: ${node.parent?.parent?.parent}
''';
      }
      return (type as InterfaceType).typeArguments[0];
    }
    return null;
  }

  @override
  DartType? visitListPattern(ListPattern node) {
    if (range.endStart(node.leftBracket, node.rightBracket).contains(offset)) {
      final type = node.requiredType;
      if (type == null) {
        throw '''
No required type.
node: $node
parent: ${node.parent}
parent2: ${node.parent?.parent}
parent3: ${node.parent?.parent?.parent}
''';
      }
      return (type as InterfaceType).typeArguments[0];
    }
    return null;
  }

  @override
  DartType? visitMapLiteralEntry(MapLiteralEntry node) {
    var literal = node.thisOrAncestorOfType<SetOrMapLiteral>();
    var literalType = literal?.staticType;
    if (literalType is InterfaceType && literalType.isDartCoreMap) {
      var typeArguments = literalType.typeArguments;
      if (offset <= node.separator.offset) {
        return typeArguments[0];
      } else {
        return typeArguments[1];
      }
    }
    return null;
  }

  @override
  DartType? visitMapPattern(MapPattern node) {
    if (range.endStart(node.leftBracket, node.rightBracket).contains(offset)) {
      var type = node.requiredType;
      if (type is InterfaceType && type.isDartCoreMap) {
        var typeArguments = type.typeArguments;
        return typeArguments[0];
      }
    }
    return null;
  }

  @override
  DartType? visitMapPatternEntry(MapPatternEntry node) {
    var pattern = node.parent.ifTypeOrNull<MapPattern>();
    var type = pattern?.requiredType;
    if (type is InterfaceType && type.isDartCoreMap) {
      var typeArguments = type.typeArguments;
      if (offset <= node.separator.offset) {
        return typeArguments[0];
      } else {
        return typeArguments[1];
      }
    }
    return null;
  }

  @override
  DartType? visitMethodInvocation(MethodInvocation node) {
    if (offset == node.offset) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType? visitNamedExpression(NamedExpression node) {
    if (offset == node.offset) {
      return _visitParent(node);
    }
    if (node.name.end <= offset) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType? visitParenthesizedExpression(ParenthesizedExpression node) {
    final type = _visitParent(node);

    // `RecordType := (^)` without any fields.
    if (type is RecordType) {
      return type.positionalFields.firstOrNull?.type;
    }

    return type;
  }

  @override
  DartType? visitPatternAssignment(PatternAssignment node) {
    if (offset >= node.equals.end) {
      return _requiredTypeOfPattern(node.pattern);
    }
    return null;
  }

  @override
  DartType? visitPatternField(PatternField node) {
    var parent = node.parent;
    if (parent is ObjectPattern) {
      return _visitFieldInObjectPattern(parent, node);
    } else if (parent is RecordPattern) {
      return _visitFieldInRecordPattern(parent, node);
    }
    return null;
  }

  @override
  DartType? visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    if (offset >= node.equals.end) {
      return _requiredTypeOfPattern(node.pattern);
    }
    return null;
  }

  @override
  DartType? visitPostfixExpression(PostfixExpression node) {
    return node.operand.staticParameterElement?.type;
  }

  @override
  DartType? visitPrefixedIdentifier(PrefixedIdentifier node) {
    return _visitParent(node);
  }

  @override
  DartType? visitPrefixExpression(PrefixExpression node) {
    return node.operand.staticParameterElement?.type;
  }

  @override
  DartType? visitPropertyAccess(PropertyAccess node) {
    return _visitParent(node);
  }

  @override
  DartType? visitRecordLiteral(RecordLiteral node) {
    final type = node.parent?.accept(this);
    if (type is! RecordType) {
      return null;
    }

    var index = 0;

    DartType? typeOfIndexPositionalField() {
      if (index < type.positionalFields.length) {
        return type.positionalFields[index].type;
      }
      return null;
    }

    for (final argument in node.fields) {
      if (argument is NamedExpression) {
        if (offset <= argument.offset) {
          return typeOfIndexPositionalField();
        }
        if (argument.contains(offset)) {
          if (offset >= argument.name.colon.end) {
            final name = argument.name.label.name;
            return type.namedField(name)?.type;
          }
          return null;
        }
      } else {
        if (offset <= argument.end) {
          return typeOfIndexPositionalField();
        }
        index++;
      }
    }

    return typeOfIndexPositionalField();
  }

  @override
  DartType? visitRecordPattern(RecordPattern node) {
    if (!range
        .endStart(node.leftParenthesis, node.rightParenthesis)
        .contains(offset)) {
      return null;
    }
    var recordType = node.matchedValueType;
    if (recordType is! RecordType) {
      return null;
    }
    var positionalIndex = _computePositionalIndex(node);
    var positionalFields = recordType.positionalFields;
    if (positionalIndex < positionalFields.length) {
      return positionalFields[positionalIndex].type;
    }
    return null;
  }

  @override
  DartType? visitReturnStatement(ReturnStatement node) {
    if (node.returnKeyword.end < offset) {
      var functionBody = node.thisOrAncestorOfType<FunctionBody>();
      if (functionBody != null) {
        return BodyInferenceContext.of(functionBody)?.contextType;
      }
    }
    return null;
  }

  @override
  DartType? visitSetOrMapLiteral(SetOrMapLiteral node) {
    var type = node.staticType;
    if (type is InterfaceType &&
        range.endStart(node.leftBracket, node.rightBracket).contains(offset) &&
        (type.isDartCoreMap || type.isDartCoreSet)) {
      return type.typeArguments[0];
    }
    return null;
  }

  @override
  DartType? visitSimpleIdentifier(SimpleIdentifier node) {
    return _visitParent(node);
  }

  @override
  DartType? visitSimpleStringLiteral(SimpleStringLiteral node) {
    // The only completion inside of a String literal would be a directive,
    // where the context type would not be of value.
    return null;
  }

  @override
  DartType? visitSpreadElement(SpreadElement node) {
    if (node.spreadOperator.end <= offset) {
      var currentNode = node.parent;
      while (currentNode != null) {
        if (currentNode is ListLiteral) {
          return typeProvider.iterableDynamicType;
        } else if (currentNode is SetOrMapLiteral) {
          if (currentNode.isSet) {
            return typeProvider.iterableDynamicType;
          }
          return typeProvider.mapType(
              typeProvider.dynamicType, typeProvider.dynamicType);
        }
        currentNode = currentNode.parent;
      }
    }
    return null;
  }

  @override
  DartType? visitSwitchCase(SwitchCase node) {
    if (range.endStart(node.keyword, node.colon).contains(offset)) {
      var parent = node.parent;
      if (parent is SwitchStatement) {
        return parent.expression.staticType;
      }
    }
    return super.visitSwitchCase(node);
  }

  @override
  DartType? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.contains(offset)) {
      return node.variables.accept(this);
    }
    return null;
  }

  @override
  DartType? visitVariableDeclaration(VariableDeclaration node) {
    var equals = node.equals;
    if (equals != null && equals.end <= offset) {
      var parent = node.parent;
      if (parent is VariableDeclarationList) {
        return parent.type?.type ??
            _impliedDartTypeWithName(typeProvider, node.name.lexeme);
      }
    }
    return null;
  }

  @override
  DartType? visitVariableDeclarationList(VariableDeclarationList node) {
    for (var varDecl in node.variables) {
      if (varDecl.contains(offset)) {
        var equals = varDecl.equals;
        if (equals != null && equals.end <= offset) {
          return node.type?.type ??
              _impliedDartTypeWithName(typeProvider, varDecl.name.lexeme);
        }
      }
    }
    return null;
  }

  @override
  DartType? visitWhenClause(WhenClause node) {
    return typeProvider.boolType;
  }

  @override
  DartType? visitWhileStatement(WhileStatement node) {
    if (range
        .endStart(node.leftParenthesis, node.rightParenthesis)
        .contains(offset)) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType? visitYieldStatement(YieldStatement node) {
    if (range.endStart(node.yieldKeyword, node.semicolon).contains(offset)) {
      var functionBody = node.thisOrAncestorOfType<FunctionBody>();
      if (functionBody != null) {
        return BodyInferenceContext.of(functionBody)?.contextType;
      }
    }
    return null;
  }

  int _computePositionalIndex(RecordPattern node) {
    var fields = node.fields;
    if (fields.isEmpty) {
      return 0;
    }
    var index = 0;
    for (var field in fields) {
      var rightToken = field.endToken;
      if (rightToken.next!.type == TokenType.COMMA) {
        rightToken = rightToken.next!;
      }
      if (offset <= rightToken.offset) {
        return index;
      }
      if (field.name == null) {
        index++;
      }
    }
    return index;
  }

  /// Given a [pattern] that can appear on the left of either a
  /// `PatternAssignment` or a `PatternVariableDeclaration`, return the context
  /// type for the right-hand side.
  DartType? _requiredTypeOfPattern(DartPattern pattern) {
    // TODO(brianwilkerson) Replace with `patternTypeSchema` (on AST) where
    //  possible.
    pattern = pattern.unParenthesized;
    Element? element;
    if (pattern is AssignedVariablePattern) {
      element = pattern.element;
    } else if (pattern is DeclaredVariablePattern) {
      element = pattern.declaredElement;
      // } else if (pattern is RecordPattern) {
      //   pattern.fields.map((e) => _requiredTypeOfPattern(e.pattern)).toList();
    } else if (pattern is ListPattern) {
      return pattern.requiredType;
    }
    if (element is VariableElement) {
      return element.type;
    }
    return null;
  }

  DartType? _visitFieldInObjectPattern(
      ObjectPattern parent, PatternField field) {
    var fieldName = field.name;
    if (fieldName == null || offset < fieldName.end) {
      return null;
    }
    var name = fieldName.name?.lexeme;
    if (name == null) {
      return null;
    }
    var type = parent.type.type;
    if (type is! InterfaceType) {
      return null;
    }
    var declaredElement2 = (field.root as CompilationUnit).declaredElement;
    var uri = declaredElement2?.source.uri;
    if (uri == null) {
      return null;
    }
    var manager = InheritanceManager3();
    var member = manager.getMember(type, Name(uri, name));
    if (member is PropertyAccessorElement) {
      if (member.isGetter) {
        return member.type.returnType;
      }
    } else if (member is MethodElement) {
      return member.type;
    }
    return null;
  }

  DartType? _visitFieldInRecordPattern(
      RecordPattern parent, PatternField field) {
    var recordType = parent.matchedValueType;
    if (recordType is! RecordType) {
      return null;
    }
    var fieldName = field.name;
    if (fieldName == null) {
      // Completing a positional field.
      var fields = parent.fields;
      var index = fields.indexOf(field);
      int fieldIndex = 0; // The index of the positional field being matched.
      for (int i = 0; i < index; i++) {
        if (fields[i].name == null) {
          fieldIndex++;
        }
      }
      var positionalFields = recordType.positionalFields;
      if (fieldIndex < positionalFields.length) {
        return positionalFields[fieldIndex].type;
      }
      return null;
    }
    // Completing a named field.
    if (offset < fieldName.end) {
      // Completing before the end of the colon means we're not in the field's
      // value, so there is no context type.
      return null;
    }
    var name = fieldName.name?.lexeme;
    if (name == null) {
      return null;
    }
    var namedFields = recordType.namedFields;
    for (var field in namedFields) {
      if (field.name == name) {
        return field.type;
      }
    }
    return null;
  }

  /// Return the result of visiting the parent of the [node] after setting the
  /// [childNode] to the [node]. Note that this method is destructive in that it
  /// does not reset the [childNode] before returning.
  DartType? _visitParent(AstNode node) {
    var parent = node.parent;
    if (parent == null) {
      return null;
    }
    return parent.accept(this);
  }
}

/// Some useful extensions on [AstNode] for this computer.
extension on AstNode {
  bool contains(int o) => offset <= o && o <= end;
}

/// Some useful extensions on [ArgumentList] for this computer.
extension on ArgumentList {
  /// Return the [FunctionType], if there is one, for this [ArgumentList].
  FunctionType? get functionType {
    final parent = this.parent;
    if (parent is InstanceCreationExpression) {
      return parent.constructorName.staticElement?.type;
    } else if (parent is MethodInvocation) {
      var type = parent.staticInvokeType;
      if (type is FunctionType) {
        return type;
      }
    } else if (parent is FunctionExpressionInvocation) {
      var type = parent.staticInvokeType;
      if (type is FunctionType) {
        return type;
      }
    }
    return null;
  }
}
