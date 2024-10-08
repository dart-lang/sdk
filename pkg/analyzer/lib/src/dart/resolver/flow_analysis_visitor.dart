// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart' show TypeSystemImpl;
import 'package:analyzer/src/generated/variable_type_provider.dart';

export 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart'
    show NullabilitySuffix;

/// Data gathered by flow analysis, retained for testing purposes.
class FlowAnalysisDataForTesting {
  /// The list of nodes, [Expression]s or [Statement]s, that cannot be reached,
  /// for example because a previous statement always exits.
  final List<AstNode> unreachableNodes = [];

  /// The list of [FunctionBody]s that don't complete, for example because
  /// there is a `return` statement at the end of the function body block.
  final List<FunctionBody> functionBodiesThatDontComplete = [];

  /// The list of references to variables, where a variable is read, and
  /// is not definitely assigned.
  final List<SimpleIdentifier> notDefinitelyAssigned = [];

  /// The list of references to variables, where a variable is read, and
  /// is definitely assigned.
  final List<SimpleIdentifier> definitelyAssigned = [];

  /// The list of references to variables, where a variable is written, and
  /// is definitely unassigned.
  final List<SimpleIdentifier> definitelyUnassigned = [];

  /// For each top level or class level declaration, the assigned variables
  /// information that was computed for it.
  final Map<AstNode, AssignedVariablesForTesting<AstNode, PromotableElement>>
      assignedVariables = {};

  /// For each expression that led to an error because it was not promoted, a
  /// string describing the reason it was not promoted.
  Map<SyntacticEntity, String> nonPromotionReasons = {};

  /// For each auxiliary AST node pointed to by a non-promotion reason, a string
  /// describing the non-promotion reason pointing to it.
  Map<AstNode, String> nonPromotionReasonTargets = {};
}

/// The helper for performing flow analysis during resolution.
///
/// It contains related precomputed data, result, and non-trivial pieces of
/// code that are independent from visiting AST during resolution, so can
/// be extracted.
class FlowAnalysisHelper {
  /// The reused instance for creating new [FlowAnalysis] instances.
  final TypeSystemOperations typeOperations;

  /// Precomputed sets of potentially assigned variables.
  AssignedVariables<AstNode, PromotableElement>? assignedVariables;

  /// The result for post-resolution stages of analysis, for testing only.
  final FlowAnalysisDataForTesting? dataForTesting;

  final bool isNonNullableByDefault;

  /// Indicates whether initializers of implicitly typed variables should be
  /// accounted for by SSA analysis.  (In an ideal world, they always would be,
  /// but due to https://github.com/dart-lang/language/issues/1785, they weren't
  /// always, and we need to be able to replicate the old behavior when
  /// analyzing old language versions).
  final bool respectImplicitlyTypedVarInitializers;

  final bool fieldPromotionEnabled;

  final bool inferenceUpdate4Enabled;

  /// The current flow, when resolving a function body, or `null` otherwise.
  FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
      SharedTypeView<DartType>>? flow;

  FlowAnalysisHelper(bool retainDataForTesting, FeatureSet featureSet,
      {required TypeSystemOperations typeSystemOperations})
      : this._(
          typeSystemOperations,
          retainDataForTesting ? FlowAnalysisDataForTesting() : null,
          isNonNullableByDefault: featureSet.isEnabled(Feature.non_nullable),
          respectImplicitlyTypedVarInitializers:
              featureSet.isEnabled(Feature.constructor_tearoffs),
          fieldPromotionEnabled:
              featureSet.isEnabled(Feature.inference_update_2),
          inferenceUpdate4Enabled:
              featureSet.isEnabled(Feature.inference_update_4),
        );

  FlowAnalysisHelper._(
    this.typeOperations,
    this.dataForTesting, {
    required this.isNonNullableByDefault,
    required this.respectImplicitlyTypedVarInitializers,
    required this.fieldPromotionEnabled,
    required this.inferenceUpdate4Enabled,
  });

  LocalVariableTypeProvider get localVariableTypeProvider {
    return _LocalVariableTypeProvider(this);
  }

  void asExpression(AsExpression node) {
    if (flow == null) return;

    var expression = node.expression;
    var typeAnnotation = node.type;

    flow!.asExpression_end(
        expression, SharedTypeView(typeAnnotation.typeOrThrow));
  }

  void assignmentExpression(AssignmentExpression node) {
    if (flow == null) return;

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      flow!.ifNullExpression_rightBegin(
          node.leftHandSide, SharedTypeView(node.readType!));
    }
  }

  void assignmentExpression_afterRight(AssignmentExpression node) {
    if (flow == null) return;

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      flow!.ifNullExpression_end();
    }
  }

  void breakStatement(BreakStatement node) {
    var target = getLabelTarget(node, node.label?.staticElement, isBreak: true);
    flow!.handleBreak(target);
  }

  /// Mark the [node] as unreachable if it is not covered by another node that
  /// is already known to be unreachable.
  void checkUnreachableNode(AstNode node) {
    if (flow == null) return;
    if (flow!.isReachable) return;

    if (dataForTesting != null) {
      dataForTesting!.unreachableNodes.add(node);
    }
  }

  void continueStatement(ContinueStatement node) {
    var target =
        getLabelTarget(node, node.label?.staticElement, isBreak: false);
    flow!.handleContinue(target);
  }

  void executableDeclaration_enter(
      AstNode node, FormalParameterList? parameters,
      {required bool isClosure}) {
    if (isClosure) {
      flow!.functionExpression_begin(node);
    }

    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        var declaredElement = parameter.declaredElement!;
        // TODO(paulberry): `skipDuplicateCheck` is currently needed to work
        // around a failure in duplicate_definition_test.dart; fix this.
        flow!.declare(declaredElement, SharedTypeView(declaredElement.type),
            initialized: true, skipDuplicateCheck: true);
      }
    }
  }

  void executableDeclaration_exit(FunctionBody body, bool isClosure) {
    if (isClosure) {
      flow!.functionExpression_end();
    }
    if (!flow!.isReachable) {
      dataForTesting?.functionBodiesThatDontComplete.add(body);
    }
  }

  void for_bodyBegin(AstNode node, Expression? condition) {
    flow?.for_bodyBegin(node is Statement ? node : null, condition);
  }

  void for_conditionBegin(AstNode node) {
    flow?.for_conditionBegin(node);
  }

  bool isDefinitelyAssigned(
    SimpleIdentifier node,
    PromotableElement element,
  ) {
    var isAssigned = flow!.isAssigned(element);

    if (dataForTesting != null) {
      if (isAssigned) {
        dataForTesting!.definitelyAssigned.add(node);
      } else {
        dataForTesting!.notDefinitelyAssigned.add(node);
      }
    }

    return isAssigned;
  }

  bool isDefinitelyUnassigned(
    SimpleIdentifier node,
    PromotableElement element,
  ) {
    var isUnassigned = flow!.isUnassigned(element);

    if (dataForTesting != null && isUnassigned) {
      dataForTesting!.definitelyUnassigned.add(node);
    }

    return isUnassigned;
  }

  void isExpression(IsExpression node) {
    if (flow == null) return;

    var expression = node.expression;
    var typeAnnotation = node.type;

    flow!.isExpression_end(
      node,
      expression,
      node.notOperator != null,
      SharedTypeView(typeAnnotation.typeOrThrow),
    );
  }

  void labeledStatement_enter(LabeledStatement node) {
    if (flow == null) return;

    flow!.labeledStatement_begin(node);
  }

  void labeledStatement_exit(LabeledStatement node) {
    if (flow == null) return;

    flow!.labeledStatement_end();
  }

  void topLevelDeclaration_enter(AstNode node, FormalParameterList? parameters,
      {void Function(AstVisitor<Object?> visitor)? visit}) {
    assert(flow == null);
    assignedVariables = computeAssignedVariables(node, parameters,
        retainDataForTesting: dataForTesting != null, visit: visit);
    if (dataForTesting != null) {
      dataForTesting!.assignedVariables[node] = assignedVariables
          as AssignedVariablesForTesting<AstNode, PromotableElement>;
    }
    flow = isNonNullableByDefault
        ? FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
            SharedTypeView<DartType>>(
            typeOperations,
            assignedVariables!,
            respectImplicitlyTypedVarInitializers:
                respectImplicitlyTypedVarInitializers,
            fieldPromotionEnabled: fieldPromotionEnabled,
            inferenceUpdate4Enabled: inferenceUpdate4Enabled,
          )
        : FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
                SharedTypeView<DartType>>.legacy(
            typeOperations, assignedVariables!);
  }

  void topLevelDeclaration_exit() {
    // Set this.flow to null before doing any clean-up so that if an exception
    // is raised, the state is already updated correctly, and we don't have
    // cascading failures.
    var flow = this.flow;
    this.flow = null;
    assignedVariables = null;

    flow!.finish();
  }

  /// Transfers any test data that was recorded for [oldNode] so that it is now
  /// associated with [newNode].  We need to do this when doing AST rewriting,
  /// so that test data can be found using the rewritten tree.
  void transferTestData(AstNode oldNode, AstNode newNode) {
    var dataForTesting = this.dataForTesting;
    if (dataForTesting != null) {
      var oldNonPromotionReasons = dataForTesting.nonPromotionReasons[oldNode];
      if (oldNonPromotionReasons != null) {
        dataForTesting.nonPromotionReasons[newNode] = oldNonPromotionReasons;
      }
    }
  }

  void variableDeclarationList(VariableDeclarationList node) {
    if (flow != null) {
      var variables = node.variables;
      for (var i = 0; i < variables.length; ++i) {
        var variable = variables[i];
        var declaredElement = variable.declaredElement as PromotableElement;
        flow!.declare(declaredElement, SharedTypeView(declaredElement.type),
            initialized: variable.initializer != null);
      }
    }
  }

  /// Computes the [AssignedVariables] map for the given [node].
  static AssignedVariables<AstNode, PromotableElement> computeAssignedVariables(
      AstNode node, FormalParameterList? parameters,
      {bool retainDataForTesting = false,
      void Function(AstVisitor<Object?> visitor)? visit}) {
    AssignedVariables<AstNode, PromotableElement> assignedVariables =
        retainDataForTesting
            ? AssignedVariablesForTesting()
            : AssignedVariables();
    var assignedVariablesVisitor = _AssignedVariablesVisitor(assignedVariables);
    assignedVariablesVisitor._declareParameters(parameters);
    if (visit != null) {
      visit(assignedVariablesVisitor);
    } else {
      node.visitChildren(assignedVariablesVisitor);
    }
    assignedVariables.finish();
    return assignedVariables;
  }

  /// Return the target of the `break` or `continue` statement with the
  /// [element] label. The [element] might be `null` (when the statement does
  /// not specify a label), so the default enclosing target is returned.
  ///
  /// [isBreak] is `true` for `break`, and `false` for `continue`.
  static Statement? getLabelTarget(AstNode? node, Element? element,
      {required bool isBreak}) {
    for (; node != null; node = node.parent) {
      if (element == null) {
        if (node is DoStatement ||
            node is ForStatement ||
            (isBreak && node is SwitchStatement) ||
            node is WhileStatement) {
          return node as Statement;
        }
      } else {
        if (node is LabeledStatement) {
          if (_hasLabel(node.labels, element)) {
            var statement = node.statement;
            // The inner statement is returned for labeled loops and
            // switch statements, while the LabeledStatement is returned
            // for the other known targets. This could be possibly changed
            // so that the inner statement is always returned.
            if (statement is Block ||
                statement is BreakStatement ||
                statement is IfStatement ||
                statement is TryStatement) {
              return node;
            }
            return statement;
          }
        }
        if (node is SwitchStatement) {
          for (var member in node.members) {
            if (_hasLabel(member.labels, element)) {
              return node;
            }
          }
        }
      }
    }
    return null;
  }

  static bool _hasLabel(List<Label> labels, Element element) {
    for (var nodeLabel in labels) {
      if (identical(nodeLabel.label.staticElement, element)) {
        return true;
      }
    }
    return false;
  }
}

class TypeSystemOperations
    with
        TypeAnalyzerOperationsMixin<DartType, PromotableElement,
            TypeParameterElement, InterfaceType, InterfaceElement>
    implements
        TypeAnalyzerOperations<DartType, PromotableElement,
            TypeParameterElement, InterfaceType, InterfaceElement> {
  final bool strictCasts;
  final TypeSystemImpl typeSystem;

  TypeSystemOperations(this.typeSystem, {required this.strictCasts});

  @override
  SharedTypeView<DartType> get boolType {
    return SharedTypeView(typeSystem.typeProvider.boolType);
  }

  @override
  SharedTypeView<DartType> get doubleType {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  SharedTypeView<DartType> get dynamicType {
    return SharedTypeView(typeSystem.typeProvider.dynamicType);
  }

  @override
  SharedTypeView<DartType> get errorType {
    return SharedTypeView(InvalidTypeImpl.instance);
  }

  @override
  SharedTypeView<DartType> get intType {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  SharedTypeView<DartType> get neverType {
    return SharedTypeView(typeSystem.typeProvider.neverType);
  }

  @override
  SharedTypeView<DartType> get nullType {
    return SharedTypeView(typeSystem.typeProvider.nullType);
  }

  @override
  SharedTypeView<DartType> get objectQuestionType {
    return SharedTypeView(typeSystem.objectQuestion);
  }

  @override
  SharedTypeView<DartType> get objectType {
    return SharedTypeView(typeSystem.objectNone);
  }

  @override
  SharedTypeSchemaView<DartType> get unknownType {
    return SharedTypeSchemaView(UnknownInferredType.instance);
  }

  @override
  TypeClassification classifyType(SharedTypeView<DartType> type) {
    DartType unwrapped = type.unwrapTypeView();
    if (isSubtypeOfInternal(unwrapped, typeSystem.typeProvider.objectType)) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOfInternal(
        unwrapped, typeSystem.typeProvider.nullType)) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  SharedTypeView<DartType> extensionTypeErasure(SharedTypeView<DartType> type) {
    return SharedTypeView(type.unwrapTypeView().extensionTypeErasure);
  }

  @override
  SharedTypeView<DartType> factor(
      SharedTypeView<DartType> from, SharedTypeView<DartType> what) {
    return SharedTypeView(
        typeSystem.factor(from.unwrapTypeView(), what.unwrapTypeView()));
  }

  @override
  DartType futureTypeInternal(DartType argumentType) {
    return typeSystem.typeProvider.futureType(argumentType);
  }

  @override
  TypeDeclarationKind? getTypeDeclarationKindInternal(DartType type) {
    if (isInterfaceType(SharedTypeView(type))) {
      return TypeDeclarationKind.interfaceDeclaration;
    } else if (isExtensionType(SharedTypeView(type))) {
      return TypeDeclarationKind.extensionTypeDeclaration;
    } else {
      return null;
    }
  }

  @override
  Variance getTypeParameterVariance(
      InterfaceElement typeDeclaration, int parameterIndex) {
    return (typeDeclaration.typeParameters[parameterIndex]
            as TypeParameterElementImpl)
        .variance;
  }

  @override
  DartType glbInternal(DartType type1, DartType type2) {
    return typeSystem.greatestLowerBound(type1, type2);
  }

  @override
  SharedTypeView<DartType> greatestClosure(
      SharedTypeSchemaView<DartType> schema) {
    return SharedTypeView(
        typeSystem.greatestClosureOfSchema(schema.unwrapTypeSchemaView()));
  }

  @override
  bool isAlwaysExhaustiveType(SharedTypeView<DartType> type) {
    return typeSystem.isAlwaysExhaustive(type.unwrapTypeView());
  }

  @override
  bool isAssignableTo(
      SharedTypeView<DartType> fromType, SharedTypeView<DartType> toType) {
    return typeSystem.isAssignableTo(
        fromType.unwrapTypeView(), toType.unwrapTypeView(),
        strictCasts: strictCasts);
  }

  @override
  bool isDartCoreFunction(SharedTypeView<DartType> type) {
    return type.nullabilitySuffix == NullabilitySuffix.none &&
        type.unwrapTypeView().isDartCoreFunction;
  }

  @override
  bool isExtensionType(SharedTypeView<DartType> type) {
    DartType unwrappedType = type.unwrapTypeView();
    return unwrappedType is InterfaceType &&
        unwrappedType.element is ExtensionTypeElement;
  }

  @override
  bool isInterfaceType(SharedTypeView<DartType> type) {
    DartType unwrappedType = type.unwrapTypeView();
    return unwrappedType is InterfaceType &&
        !unwrappedType.isDartCoreNull &&
        !unwrappedType.isDartAsyncFutureOr &&
        unwrappedType.element is! ExtensionTypeElement;
  }

  @override
  bool isNever(SharedTypeView<DartType> type) {
    return type.unwrapTypeView().isBottom;
  }

  @override
  bool isNonNullable(SharedTypeSchemaView<DartType> typeSchema) {
    return typeSystem.isNonNullable(typeSchema.unwrapTypeSchemaView());
  }

  @override
  bool isNull(SharedTypeView<DartType> type) {
    return type.unwrapTypeView().isDartCoreNull;
  }

  @override
  bool isObject(SharedTypeView<DartType> type) {
    return type.unwrapTypeView().isDartCoreObject &&
        type.nullabilitySuffix == NullabilitySuffix.none;
  }

  @override
  bool isPropertyPromotable(Object property) {
    if (property is! PropertyAccessorElement) return false;
    var field = property.variable2;
    if (field is! FieldElement) return false;
    return field.isPromotable;
  }

  @override
  bool isSubtypeOfInternal(DartType leftType, DartType rightType) {
    return typeSystem.isSubtypeOf(leftType, rightType);
  }

  @override
  bool isTypeParameterType(SharedTypeView<DartType> type) {
    return type.unwrapTypeView() is TypeParameterType;
  }

  @override
  bool isTypeSchemaSatisfied(
      {required SharedTypeSchemaView<DartType> typeSchema,
      required SharedTypeView<DartType> type}) {
    return typeSystem.isSubtypeOf(
        type.unwrapTypeView(), typeSchema.unwrapTypeSchemaView());
  }

  @override
  bool isVariableFinal(PromotableElement element) {
    return element.isFinal;
  }

  @override
  SharedTypeSchemaView<DartType> iterableTypeSchema(
      SharedTypeSchemaView<DartType> elementTypeSchema) {
    return SharedTypeSchemaView(typeSystem.typeProvider
        .iterableType(elementTypeSchema.unwrapTypeSchemaView()));
  }

  @override
  DartType listTypeInternal(DartType elementType) {
    return typeSystem.typeProvider.listType(elementType);
  }

  @override
  DartType lubInternal(DartType type1, DartType type2) {
    return typeSystem.leastUpperBound(type1, type2);
  }

  @override
  DartType makeNullableInternal(DartType type) {
    return typeSystem.makeNullable(type);
  }

  @override
  DartType mapTypeInternal({
    required DartType keyType,
    required DartType valueType,
  }) {
    return typeSystem.typeProvider.mapType(keyType, valueType);
  }

  @override
  DartType? matchFutureOrInternal(DartType type) {
    if (type is InterfaceType && type.isDartAsyncFutureOr) {
      return type.typeArguments[0];
    } else {
      return null;
    }
  }

  @override
  TypeParameterElement? matchInferableParameter(SharedTypeView<DartType> type) {
    DartType unwrappedType = type.unwrapTypeView();
    if (unwrappedType is TypeParameterType) {
      return unwrappedType.element;
    } else {
      return null;
    }
  }

  @override
  DartType? matchIterableTypeInternal(DartType type) {
    var iterableElement = typeSystem.typeProvider.iterableElement;
    var listType = type.asInstanceOf(iterableElement);
    return listType?.typeArguments[0];
  }

  @override
  SharedTypeView<DartType>? matchListType(SharedTypeView<DartType> type) {
    var listElement = typeSystem.typeProvider.listElement;
    var listType = type.unwrapTypeView().asInstanceOf(listElement);
    return listType == null ? null : SharedTypeView(listType.typeArguments[0]);
  }

  @override
  ({SharedTypeView<DartType> keyType, SharedTypeView<DartType> valueType})?
      matchMapType(SharedTypeView<DartType> type) {
    var mapElement = typeSystem.typeProvider.mapElement;
    var mapType = type.unwrapTypeView().asInstanceOf(mapElement);
    if (mapType != null) {
      return (
        keyType: SharedTypeView(mapType.typeArguments[0]),
        valueType: SharedTypeView(mapType.typeArguments[1]),
      );
    }
    return null;
  }

  @override
  SharedTypeView<DartType>? matchStreamType(SharedTypeView<DartType> type) {
    var streamElement = typeSystem.typeProvider.streamElement;
    var listType = type.unwrapTypeView().asInstanceOf(streamElement);
    return listType == null ? null : SharedTypeView(listType.typeArguments[0]);
  }

  @override
  TypeDeclarationMatchResult<InterfaceType, InterfaceElement, DartType>?
      matchTypeDeclarationType(SharedTypeView<DartType> type) {
    DartType unwrappedType = type.unwrapTypeView();
    if (isInterfaceType(type)) {
      InterfaceType interfaceType = unwrappedType as InterfaceType;
      return TypeDeclarationMatchResult(
          typeDeclarationKind: TypeDeclarationKind.interfaceDeclaration,
          typeDeclarationType: interfaceType,
          typeDeclaration: interfaceType.element,
          typeArguments: interfaceType.typeArguments);
    } else if (isExtensionType(type)) {
      InterfaceType interfaceType = unwrappedType as InterfaceType;
      return TypeDeclarationMatchResult(
          typeDeclarationKind: TypeDeclarationKind.extensionTypeDeclaration,
          typeDeclarationType: interfaceType,
          typeDeclaration: interfaceType.element,
          typeArguments: interfaceType.typeArguments);
    } else {
      return null;
    }
  }

  @override
  SharedTypeView<DartType> normalize(SharedTypeView<DartType> type) {
    return SharedTypeView(typeSystem.normalize(type.unwrapTypeView()));
  }

  @override
  SharedTypeView<DartType> promoteToNonNull(SharedTypeView<DartType> type) {
    return SharedTypeView(typeSystem.promoteToNonNull(type.unwrapTypeView()));
  }

  @override
  DartType recordTypeInternal(
      {required List<DartType> positional,
      required List<(String, DartType)> named}) {
    return RecordTypeImpl(
      positionalFields: positional.map((type) {
        return RecordTypePositionalFieldImpl(type: type);
      }).toList(),
      namedFields: named.map((namedType) {
        var (name, type) = namedType;
        return RecordTypeNamedFieldImpl(name: name, type: type);
      }).toList(),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  SharedTypeSchemaView<DartType> streamTypeSchema(
      SharedTypeSchemaView<DartType> elementTypeSchema) {
    return SharedTypeSchemaView(typeSystem.typeProvider
        .streamType(elementTypeSchema.unwrapTypeSchemaView()));
  }

  @override
  SharedTypeView<DartType>? tryPromoteToType(
      SharedTypeView<DartType> to, SharedTypeView<DartType> from) {
    DartType? result =
        typeSystem.tryPromoteToType(to.unwrapTypeView(), from.unwrapTypeView());
    return result == null ? null : SharedTypeView(result);
  }

  @override
  SharedTypeSchemaView<DartType> typeToSchema(SharedTypeView<DartType> type) {
    return SharedTypeSchemaView(type.unwrapTypeView());
  }

  @override
  SharedTypeView<DartType> variableType(PromotableElement variable) {
    return SharedTypeView(variable.type);
  }

  @override
  PropertyNonPromotabilityReason? whyPropertyIsNotPromotable(
      covariant ExecutableElement property) {
    if (property.isPublic) return PropertyNonPromotabilityReason.isNotPrivate;
    if (property is! PropertyAccessorElement) {
      return PropertyNonPromotabilityReason.isNotField;
    }
    var field = property.variable2;
    if (field is! FieldElement) {
      return PropertyNonPromotabilityReason.isNotField;
    }
    if (field.isSynthetic && !property.isSynthetic) {
      // The field is synthetic but not the property; this means that what was
      // declared by the user was the property (the getter).
      return PropertyNonPromotabilityReason.isNotField;
    }
    if (field.isPromotable) return null;
    if (field.isExternal) return PropertyNonPromotabilityReason.isExternal;
    if (!field.isFinal) return PropertyNonPromotabilityReason.isNotFinal;
    // Non-promotion reason must be due to a conflict with some other
    // declaration, or because field promotion is disabled.
    return null;
  }

  @override
  SharedTypeView<DartType> withNullabilitySuffix(
      SharedTypeView<DartType> type, NullabilitySuffix suffix) {
    return SharedTypeView(
        (type.unwrapTypeView() as TypeImpl).withNullability(suffix));
  }
}

/// The visitor that gathers local variables that are potentially assigned
/// in corresponding statements, such as loops, `switch` and `try`.
class _AssignedVariablesVisitor extends RecursiveAstVisitor<void> {
  final AssignedVariables<AstNode, PromotableElement> assignedVariables;

  _AssignedVariablesVisitor(this.assignedVariables);

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var element = node.element;
    if (element is PromotableElement) {
      assignedVariables.write(element);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;

    super.visitAssignmentExpression(node);

    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is PromotableElement) {
        assignedVariables.write(element);
      }
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
      node.leftOperand.accept(this);
      assignedVariables.beginNode();
      node.rightOperand.accept(this);
      assignedVariables.endNode(node);
    } else {
      super.visitBinaryExpression(node);
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    for (var identifier in [
      node.exceptionParameter,
      node.stackTraceParameter,
    ]) {
      if (identifier != null) {
        assignedVariables.declare(identifier.declaredElement!);
      }
    }
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    assignedVariables.beginNode();
    node.thenExpression.accept(this);
    assignedVariables.endNode(node);
    node.elseExpression.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    throw StateError('Should not visit top level declarations');
  }

  @override
  void visitDoStatement(DoStatement node) {
    assignedVariables.beginNode();
    super.visitDoStatement(node);
    assignedVariables.endNode(node);
  }

  @override
  void visitForElement(ForElement node) {
    _handleFor(node, node.forLoopParts, node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _handleFor(node, node.forLoopParts, node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit) {
      throw StateError('Should not visit top level declarations');
    }
    assignedVariables.beginNode();
    _declareParameters(node.functionExpression.parameters);
    super.visitFunctionDeclaration(node);
    assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // A FunctionExpression just inside a FunctionDeclaration is an analyzer
      // artifact--it doesn't correspond to a separate closure.  So skip our
      // usual processing.
      return super.visitFunctionExpression(node);
    }
    assignedVariables.beginNode();
    _declareParameters(node.parameters);
    super.visitFunctionExpression(node);
    assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
  }

  @override
  void visitIfElement(covariant IfElementImpl node) {
    _visitIf(node);
  }

  @override
  void visitIfStatement(covariant IfStatementImpl node) {
    _visitIf(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    throw StateError('Should not visit top level declarations');
  }

  @override
  void visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    for (var variable in node.elements) {
      assignedVariables.declare(variable);
    }
    super.visitPatternVariableDeclaration(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    super.visitPostfixExpression(node);
    if (node.operator.type.isIncrementOperator) {
      var operand = node.operand;
      if (operand is SimpleIdentifier) {
        var element = operand.staticElement;
        if (element is PromotableElement) {
          assignedVariables.write(element);
        }
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    super.visitPrefixExpression(node);
    if (node.operator.type.isIncrementOperator) {
      var operand = node.operand;
      if (operand is SimpleIdentifier) {
        var element = operand.staticElement;
        if (element is PromotableElement) {
          assignedVariables.write(element);
        }
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is PromotableElement &&
        node.inGetterContext() &&
        node.parent is! FormalParameter &&
        node.parent is! CatchClause &&
        node.parent is! CommentReference) {
      assignedVariables.read(element);
    }
  }

  @override
  void visitSwitchExpression(covariant SwitchExpressionImpl node) {
    node.expression.accept(this);

    for (var case_ in node.cases) {
      var guardedPattern = case_.guardedPattern;
      var variables = guardedPattern.variables;
      for (var variable in variables.values) {
        assignedVariables.declare(variable);
      }
      case_.accept(this);
    }
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    node.expression.accept(this);

    assignedVariables.beginNode();
    for (var group in node.memberGroups) {
      for (var member in group.members) {
        if (member is SwitchCaseImpl) {
          member.expression.accept(this);
        } else if (member is SwitchPatternCaseImpl) {
          var guardedPattern = member.guardedPattern;
          guardedPattern.pattern.accept(this);
          for (var variable in guardedPattern.variables.values) {
            assignedVariables.declare(variable);
          }
          guardedPattern.whenClause?.accept(this);
        }
      }
      for (var variable in group.variables.values) {
        // We pass `ignoreDuplicates: true` because this variable might be the
        // same as one of the variables declared earlier under a specific switch
        // case.
        assignedVariables.declare(variable, ignoreDuplicates: true);
      }
      group.statements.accept(this);
    }
    assignedVariables.endNode(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    var finallyBlock = node.finallyBlock;
    assignedVariables.beginNode(); // Begin info for [node].
    assignedVariables.beginNode(); // Begin info for [node.body].
    node.body.accept(this);
    assignedVariables.endNode(node.body);

    node.catchClauses.accept(this);
    assignedVariables.endNode(node);

    finallyBlock?.accept(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var grandParent = node.parent!.parent;
    if (grandParent is TopLevelVariableDeclaration ||
        grandParent is FieldDeclaration) {
      throw StateError('Should not visit top level declarations');
    }
    var declaredElement = node.declaredElement as PromotableElement;
    assignedVariables.declare(declaredElement);
    if (declaredElement.isLate && node.initializer != null) {
      assignedVariables.beginNode();
      super.visitVariableDeclaration(node);
      assignedVariables.endNode(node, isClosureOrLateVariableInitializer: true);
    } else {
      super.visitVariableDeclaration(node);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    assignedVariables.beginNode();
    super.visitWhileStatement(node);
    assignedVariables.endNode(node);
  }

  void _declareParameters(FormalParameterList? parameters) {
    if (parameters == null) return;
    for (var parameter in parameters.parameters) {
      assignedVariables.declare(parameter.declaredElement!);
    }
  }

  void _handleFor(AstNode node, ForLoopParts forLoopParts, AstNode body) {
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      } else if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables.accept(this);
      } else if (forLoopParts is ForPartsWithPattern) {
        forLoopParts.variables.accept(this);
      } else {
        throw StateError('Unrecognized for loop parts');
      }

      assignedVariables.beginNode();
      forLoopParts.condition?.accept(this);
      body.accept(this);
      forLoopParts.updaters.accept(this);
      assignedVariables.endNode(node);
    } else if (forLoopParts is ForEachParts) {
      var iterable = forLoopParts.iterable;

      iterable.accept(this);

      if (forLoopParts is ForEachPartsWithIdentifier) {
        var element = forLoopParts.identifier.staticElement;
        if (element is PromotableElement) {
          assignedVariables.write(element);
        }
      } else if (forLoopParts is ForEachPartsWithDeclaration) {
        var variable = forLoopParts.loopVariable.declaredElement!;
        assignedVariables.declare(variable);
      } else if (forLoopParts is ForEachPartsWithPatternImpl) {
        for (var variable in forLoopParts.variables) {
          assignedVariables.declare(variable);
        }
      } else {
        throw StateError('Unrecognized for loop parts');
      }
      assignedVariables.beginNode();
      body.accept(this);
      assignedVariables.endNode(node);
    } else {
      throw StateError('Unrecognized for loop parts');
    }
  }

  void _visitIf(IfElementOrStatementImpl node) {
    node.expression.accept(this);

    var caseClause = node.caseClause;
    if (caseClause != null) {
      var guardedPattern = caseClause.guardedPattern;
      assignedVariables.beginNode();
      for (var variable in guardedPattern.variables.values) {
        assignedVariables.declare(variable);
      }
      guardedPattern.whenClause?.accept(this);
      node.ifTrue.accept(this);
      assignedVariables.endNode(node);
      node.ifFalse?.accept(this);
    } else {
      assignedVariables.beginNode();
      node.ifTrue.accept(this);
      assignedVariables.endNode(node);
      node.ifFalse?.accept(this);
    }
  }
}

/// The flow analysis based implementation of [LocalVariableTypeProvider].
class _LocalVariableTypeProvider implements LocalVariableTypeProvider {
  final FlowAnalysisHelper _manager;

  _LocalVariableTypeProvider(this._manager);

  @override
  DartType getType(SimpleIdentifier node, {required bool isRead}) {
    var variable = node.staticElement as VariableElement;
    if (variable is PromotableElement) {
      var promotedType = isRead
          ? _manager.flow?.variableRead(node, variable)
          : _manager.flow?.promotedType(variable);
      if (promotedType != null) return promotedType.unwrapTypeView();
    }
    return variable.type;
  }
}
