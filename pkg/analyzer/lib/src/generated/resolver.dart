// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/null_shorting.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/binary_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/constructor_reference_resolver.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/for_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_expression_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_reference_resolver.dart';
import 'package:analyzer/src/dart/resolver/instance_creation_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/dart/resolver/list_pattern_resolver.dart';
import 'package:analyzer/src/dart/resolver/postfix_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/prefix_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/prefixed_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/dart/resolver/record_literal_resolver.dart';
import 'package:analyzer/src/dart/resolver/shared_type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/simple_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/this_lookup.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/dart/resolver/variable_declaration_resolver.dart';
import 'package:analyzer/src/dart/resolver/yield_statement_resolver.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart'
    show DiagnosticMessage, DiagnosticMessageImpl;
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/base_or_final_type_verifier.dart';
import 'package:analyzer/src/error/bool_expression_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/inference_error.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/error/super_formal_parameters_verifier.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

/// Function determining which source files should have inference logging
/// enabled.
///
/// By default, no files have inference logging enabled.
bool Function(Source) inferenceLoggingPredicate = (_) => false;

typedef SharedMatchContext =
    shared.MatchContext<
      AstNodeImpl,
      ExpressionImpl,
      DartPatternImpl,
      PromotableElementImpl
    >;

typedef SharedPatternField =
    shared.RecordPatternField<PatternFieldImpl, DartPatternImpl>;

/// A function which returns [NonPromotionReason]s that various types are not
/// promoted.
typedef WhyNotPromotedGetter =
    Map<SharedTypeView, NonPromotionReason> Function();

/// The context shared between different units of the same library.
final class LibraryResolutionContext {
  /// The declarations for [VariableFragment]s.
  final Map<VariableFragment, VariableDeclaration> _variableNodes =
      Map.identity();
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ThrowingAstVisitor2<void>
    with
        ErrorDetectionHelpers,
        TypeAnalyzer<
          AstNodeImpl,
          StatementImpl,
          ExpressionImpl,
          PromotableElementImpl,
          DartPatternImpl,
          void,
          InterfaceTypeImpl,
          InterfaceElementImpl
        >,
        NullShortingMixin<Null, ExpressionImpl, PromotableElementImpl> {
  /// Debug-only: if `true`, manipulations of [_rewriteStack] performed by
  /// [popRewrite], [pushRewrite], and [replaceExpression] will be printed.
  static const bool _debugRewriteStack = false;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl definingLibrary;

  /// The library fragment being visited.
  final LibraryFragmentImpl libraryFragment;

  /// The context shared between different units of the same library.
  final LibraryResolutionContext libraryResolutionContext;

  /// If the resolver visitor is visiting a switch statement and patterns
  /// support is disabled, the tracker that determines whether the switch is
  /// exhaustive.
  SwitchExhaustiveness? legacySwitchExhaustiveness;

  @override
  final TypeAnalyzerOptions typeAnalyzerOptions;

  @override
  late final SharedTypeAnalyzerErrors errors = SharedTypeAnalyzerErrors(
    diagnosticReporter,
  );

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  @override
  final DiagnosticReporter diagnosticReporter;

  /// The analysis options used by this resolver.
  final AnalysisOptions analysisOptions;

  /// The instance element containing the AST nodes being visited, or `null`
  /// if we are not in the scope of an instance element.
  InstanceElementImpl? enclosingInstanceElement;

  /// The executable element containing the AST nodes being visited, or `null`
  /// if we are not in the scope of an executable element.
  ExecutableElementImpl? enclosingExecutableElement;

  /// The manager for the inheritance mappings.
  @override
  final InheritanceManager3 inheritance;

  /// The feature set that is enabled for the current unit.
  final FeatureSet _featureSet;

  /// Helper for checking that subtypes of a base or final type must be base,
  /// final, or sealed.
  late final BaseOrFinalTypeVerifier baseOrFinalTypeVerifier;

  /// Helper for checking expression that should have the `bool` type.
  late final BoolExpressionVerifier boolExpressionVerifier =
      BoolExpressionVerifier(
        resolver: this,
        diagnosticReporter: diagnosticReporter,
        nullableDereferenceVerifier: nullableDereferenceVerifier,
      );

  /// Helper for checking potentially nullable dereferences.
  late final NullableDereferenceVerifier nullableDereferenceVerifier =
      NullableDereferenceVerifier(
        typeSystem: typeSystem,
        diagnosticReporter: diagnosticReporter,
        resolver: this,
      );

  /// Helper for extension method resolution.
  late final ExtensionMemberResolver extensionResolver =
      ExtensionMemberResolver(this);

  /// Helper for resolving properties on types.
  late final TypePropertyResolver typePropertyResolver = TypePropertyResolver(
    this,
  );

  /// Helper for resolving [ListLiteral] and [SetOrMapLiteral].
  late final TypedLiteralResolver _typedLiteralResolver = TypedLiteralResolver(
    this,
    typeSystem,
    typeProvider,
    analysisOptions,
  );

  late final AssignmentExpressionResolver _assignmentExpressionResolver =
      AssignmentExpressionResolver(resolver: this);

  late final BinaryExpressionResolver _binaryExpressionResolver;
  late final ConstructorReferenceResolver _constructorReferenceResolver =
      ConstructorReferenceResolver(this);
  late final FunctionExpressionInvocationResolver
  functionExpressionInvocationResolver;
  late final FunctionExpressionResolver _functionExpressionResolver;
  late final ForResolver _forResolver;
  late final PostfixExpressionResolver _postfixExpressionResolver;
  late final PrefixedIdentifierResolver _prefixedIdentifierResolver;
  late final PrefixExpressionResolver _prefixExpressionResolver;
  late final VariableDeclarationResolver _variableDeclarationResolver;
  late final YieldStatementResolver _yieldStatementResolver;
  late final NullSafetyDeadCodeVerifier nullSafetyDeadCodeVerifier;

  late final InvocationInferenceHelper inferenceHelper;

  /// The object used to resolve the element associated with the current node.
  late final ElementResolver elementResolver;

  /// The object used to compute the type associated with the current node.
  late final StaticTypeAnalyzer typeAnalyzer;

  /// The type system in use during resolution.
  @override
  final TypeSystemImpl typeSystem;

  /// Inference context information for the current function body, if the
  /// current node is inside a function body.
  BodyInferenceContext? _bodyContext;

  /// The type of the current `this` binding, before applying type promotion.
  ///
  /// If there is no `this` binding, `null`.
  TypeImpl? _unpromotedThisType;

  final FlowAnalysisHelper flowAnalysis;

  late final FunctionReferenceResolver _functionReferenceResolver;

  late final ConstructorInvocationResolver constructorInvocationResolver =
      ConstructorInvocationResolver(this);

  late final SimpleIdentifierResolver _simpleIdentifierResolver =
      SimpleIdentifierResolver(this);

  late final PropertyElementResolver _propertyElementResolver =
      PropertyElementResolver(this);

  late final RecordLiteralResolver _recordLiteralResolver =
      RecordLiteralResolver(resolver: this);

  late final AnnotationResolver _annotationResolver = AnnotationResolver(this);

  late final ListPatternResolver listPatternResolver = ListPatternResolver(
    this,
  );

  final bool genericMetadataIsEnabled;

  final bool inferenceUsingBoundsIsEnabled;

  /// Stack for obtaining rewritten expressions.  Prior to visiting an
  /// expression, a caller may push the expression on this stack; if
  /// [replaceExpression] is later called, it will update the top of the stack
  /// to point to the rewritten expression.
  ///
  /// The stack sometimes contains `null`s.  These account for situations where
  /// it's necessary to push a value onto the stack to balance a later pop, but
  /// there is no suitable expression to push.
  final List<ExpressionImpl?> _rewriteStack = [];

  /// Debug-only expando mapping AST nodes to the nodes they were replaced with
  /// by [replaceExpression].  This is used by [dispatchExpression] as a sanity
  /// check to make sure the expression it pops off the [_rewriteStack] is
  /// actually correct.
  late final Expando<AstNode> _replacements = Expando();

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [diagnosticListener]
  /// is the diagnostic listener that will be informed of any diagnostics that
  /// are found during resolution.
  ResolverVisitor(
    InheritanceManager3 inheritanceManager,
    LibraryElementImpl definingLibrary,
    LibraryResolutionContext libraryResolutionContext,
    Source source,
    TypeProvider typeProvider,
    DiagnosticListener diagnosticListener, {
    required LibraryFragmentImpl libraryFragment,
    required FeatureSet featureSet,
    required AnalysisOptions analysisOptions,
    required FlowAnalysisHelper flowAnalysisHelper,
    required TypeAnalyzerOptions typeAnalyzerOptions,
  }) : this._(
         inheritanceManager,
         definingLibrary,
         libraryResolutionContext,
         source,
         definingLibrary.typeSystem,
         typeProvider as TypeProviderImpl,
         DiagnosticReporter(diagnosticListener, source),
         featureSet,
         analysisOptions,
         flowAnalysisHelper,
         libraryFragment: libraryFragment,
         typeAnalyzerOptions: typeAnalyzerOptions,
       );

  ResolverVisitor._(
    this.inheritance,
    this.definingLibrary,
    this.libraryResolutionContext,
    this.source,
    this.typeSystem,
    this.typeProvider,
    this.diagnosticReporter,
    FeatureSet featureSet,
    this.analysisOptions,
    this.flowAnalysis, {
    required this.libraryFragment,
    required this.typeAnalyzerOptions,
  }) : _featureSet = featureSet,
       genericMetadataIsEnabled = definingLibrary.featureSet.isEnabled(
         Feature.generic_metadata,
       ),
       inferenceUsingBoundsIsEnabled = definingLibrary.featureSet.isEnabled(
         Feature.inference_using_bounds,
       ),
       baseOrFinalTypeVerifier = BaseOrFinalTypeVerifier(
         definingLibrary: definingLibrary,
         diagnosticReporter: diagnosticReporter,
         diagnosticSource: source,
       ) {
    inferenceHelper = InvocationInferenceHelper(
      resolver: this,
      diagnosticReporter: diagnosticReporter,
      typeSystem: typeSystem,
      dataForTesting: flowAnalysis.dataForTesting != null
          ? TypeConstraintGenerationDataForTesting()
          : null,
    );
    _binaryExpressionResolver = BinaryExpressionResolver(resolver: this);
    functionExpressionInvocationResolver = FunctionExpressionInvocationResolver(
      resolver: this,
    );
    _functionExpressionResolver = FunctionExpressionResolver(resolver: this);
    _forResolver = ForResolver(resolver: this);
    _postfixExpressionResolver = PostfixExpressionResolver(resolver: this);
    _prefixedIdentifierResolver = PrefixedIdentifierResolver(this);
    _prefixExpressionResolver = PrefixExpressionResolver(resolver: this);
    _variableDeclarationResolver = VariableDeclarationResolver(
      resolver: this,
      strictInference: analysisOptions.strictInference,
    );
    _yieldStatementResolver = YieldStatementResolver(resolver: this);
    nullSafetyDeadCodeVerifier = NullSafetyDeadCodeVerifier(
      typeSystem,
      diagnosticReporter,
      flowAnalysis,
    );
    elementResolver = ElementResolver(this);
    typeAnalyzer = StaticTypeAnalyzer(this);
    _functionReferenceResolver = FunctionReferenceResolver(this);
  }

  @override
  BodyInferenceContext? get bodyContext => _bodyContext;

  @override
  FlowAnalysis<
    AstNodeImpl,
    StatementImpl,
    ExpressionImpl,
    PromotableElementImpl
  >
  get flow => flowAnalysis.flow!;

  bool get isConstructorTearoffsEnabled =>
      _featureSet.isEnabled(Feature.constructor_tearoffs);

  bool get isInferenceUpdate1Enabled =>
      _featureSet.isEnabled(Feature.inference_update_1);

  /// Return the object providing promoted or declared types of variables.
  LocalVariableTypeProvider get localVariableTypeProvider {
    return flowAnalysis.localVariableTypeProvider;
  }

  @override
  shared.TypeAnalyzerOperations<
    PromotableElementImpl,
    InterfaceTypeImpl,
    InterfaceElementImpl,
    AstNodeImpl
  >
  get operations => flowAnalysis.typeOperations;

  /// Gets the current depth of the [_rewriteStack].  This may be used in
  /// assertions to verify that pushes and pops are properly balanced.
  int get rewriteStackDepth => _rewriteStack.length;

  @override
  bool get strictCasts => analysisOptions.strictCasts;

  /// The type of the current `this` binding, after applying type promotion.
  ///
  /// If there is no `this` binding, `null`.
  TypeImpl? get thisType =>
      flowAnalysis.flow?.promotedTypeOfThis?.unwrapTypeView<TypeImpl>() ??
      _unpromotedThisType;

  /// The type of the current `this` binding, before applying type promotion.
  ///
  /// If there is no `this` binding, `null`.
  TypeImpl? get unpromotedThisType => _unpromotedThisType;

  @override
  ExpressionTypeAnalysisResult analyzeExpression(
    ExpressionImpl node,
    SharedTypeSchemaView schema, {
    bool continueNullShorting = false,
    bool isVoidAllowed = false,
    bool needsCoercion = false,
  }) {
    inferenceLogWriter?.setExpressionVisitCodePath(
      node,
      ExpressionVisitCodePath.analyzeExpression,
    );
    return super.analyzeExpression(
      node,
      schema,
      continueNullShorting: continueNullShorting,
      isVoidAllowed: isVoidAllowed,
      needsCoercion: needsCoercion,
    );
  }

  List<SharedPatternField> buildSharedPatternFields(
    List<PatternFieldImpl> fields, {
    required bool mustBeNamed,
  }) {
    return fields.map((field) {
      Token? nameToken;
      var fieldName = field.name;
      if (fieldName != null) {
        nameToken = fieldName.name;
        if (nameToken == null) {
          var variablePattern = field.pattern.variablePattern;
          if (variablePattern != null) {
            variablePattern.fieldNameWithImplicitName = fieldName;
            nameToken = variablePattern.name;
          } else {
            diagnosticReporter.report(
              diag.missingNamedPatternFieldName.at(field),
            );
          }
        }
      } else if (mustBeNamed) {
        diagnosticReporter.report(
          diag.positionalFieldInObjectPattern.at(field),
        );
      }
      return shared.RecordPatternField(
        node: field,
        name: nameToken?.lexeme,
        pattern: field.pattern,
      );
    }).toList();
  }

  /// Verify that the arguments in the given [argumentList] can be assigned to
  /// their corresponding parameters.
  ///
  /// See [diag.argumentTypeNotAssignable].
  void checkForArgumentTypesNotAssignableInList(
    ArgumentListImpl argumentList,
    List<WhyNotPromotedGetter> whyNotPromotedArguments,
  ) {
    var arguments = argumentList.arguments2;
    for (int i = 0; i < arguments.length; i++) {
      checkForArgumentTypeNotAssignableForArgument(
        arguments[i],
        whyNotPromoted: flowAnalysis.isActive
            ? whyNotPromotedArguments[i]
            : null,
      );
    }
  }

  void checkForBodyMayCompleteNormally({
    required FunctionBodyImpl body,
    required SyntacticEntity errorNode,
  }) {
    var bodyContext = body.bodyContext;
    if (bodyContext == null) {
      return;
    }

    if (!flowAnalysis.flow!.isReachable) {
      bodyContext.mayCompleteNormally = false;
      return;
    }

    var returnType = bodyContext.contextType;
    if (returnType == null) {
      if (errorNode is BlockFunctionBody) {
        _checkForFutureCatchErrorOnError(errorNode);
      }
      return;
    }

    if (body is BlockFunctionBody) {
      if (body.isGenerator) {
        return;
      }

      if (body.isAsynchronous) {
        // Check whether the return type is legal. If not, return rather than
        // reporting a second error.

        // This is the same check as [ReturnTypeVerifier._isLegalReturnType].
        // TODO(srawlins): When this check is moved into the resolution stage,
        // use the result of that check to determine whether this check should
        // be done.
        var lowerBound = typeProvider.futureElement.instantiateImpl(
          typeArguments: fixedTypeList(NeverTypeImpl.instance),
          nullabilitySuffix: NullabilitySuffix.none,
        );
        var imposedType = bodyContext.imposedType;
        if (imposedType != null &&
            !typeSystem.isSubtypeOf(lowerBound, imposedType)) {
          // [imposedType] is an illegal return type for an asynchronous
          // non-generator function; do not report an additional error here.
          return;
        }
      }

      LocatableDiagnostic locatableDiagnostic;
      if (typeSystem.isPotentiallyNonNullable(returnType)) {
        locatableDiagnostic = diag.bodyMightCompleteNormally.withArguments(
          returnType: returnType,
        );
      } else {
        var returnTypeBase = typeSystem.futureOrBase(returnType);
        if (returnTypeBase is DynamicType ||
            returnTypeBase is InvalidType ||
            returnTypeBase is UnknownInferredType ||
            returnTypeBase is VoidType ||
            returnTypeBase.isDartCoreNull) {
          return;
        } else {
          locatableDiagnostic = diag.bodyMightCompleteNormallyNullable
              .withArguments(returnType: returnType);
        }
      }
      diagnosticReporter.report(
        locatableDiagnostic.atSourceRange(switch (errorNode) {
          ConstructorDeclaration() => errorNode.errorRange,
          BlockFunctionBody() => errorNode.block.leftBracket.sourceRange,
          _ => errorNode.sourceRange,
        }),
      );
    }
  }

  /// The client of the resolver should call this method after asking the
  /// resolver to visit an AST node.  This performs assertions to make sure that
  /// temporary resolver state has been properly cleaned up.
  void checkIdle() {
    assert(_rewriteStack.isEmpty);
    inferenceLogWriter?.assertIdle();
  }

  /// Reports an error if the [pattern] with the [requiredType] cannot
  /// match the [DartPatternImpl.matchedValueType].
  void checkPatternNeverMatchesValueType({
    required SharedMatchContext context,
    required DartPatternImpl pattern,
    required TypeImpl requiredType,
    required TypeImpl matchedValueType,
  }) {
    if (context.irrefutableContext == null) {
      if (!typeSystem.canBeSubtypeOf(matchedValueType, requiredType)) {
        AstNodeImpl? errorNode;
        if (pattern is CastPatternImpl) {
          errorNode = pattern.type;
        } else if (pattern is DeclaredVariablePatternImpl) {
          errorNode = pattern.type;
        } else if (pattern is ObjectPatternImpl) {
          errorNode = pattern.type;
        } else if (pattern is WildcardPatternImpl) {
          errorNode = pattern.type;
        }
        errorNode ??= pattern;
        diagnosticReporter.report(
          diag.patternNeverMatchesValueType
              .withArguments(
                matchedValueType: matchedValueType,
                requiredType: requiredType,
              )
              .at(errorNode),
        );
      }
    }
  }

  void checkReadOfNotAssignedLocalVariable(
    SimpleIdentifier node,
    Element? element,
  ) {
    if (!flowAnalysis.isActive) {
      return;
    }

    if (!node.inGetterContext()) {
      return;
    }

    if (element is PromotableElementImpl) {
      var assigned = flowAnalysis.isDefinitelyAssigned(node, element);
      var unassigned = flowAnalysis.isDefinitelyUnassigned(node, element);

      if (element.isLate) {
        if (unassigned) {
          diagnosticReporter.report(
            diag.definitelyUnassignedLateLocalVariable
                .withArguments(name: node.name)
                .at(node),
          );
        }
        return;
      }

      if (!assigned) {
        if (element.isFinal) {
          diagnosticReporter.report(
            diag.readPotentiallyUnassignedFinal
                .withArguments(name: node.name)
                .at(node),
          );
          return;
        }

        if (typeSystem.isPotentiallyNonNullable(element.type)) {
          diagnosticReporter.report(
            diag.notAssignedPotentiallyNonNullableLocalVariable
                .withArguments(name: node.name)
                .at(node),
          );
          return;
        }
      }
    }
  }

  void checkUnreachableNode(AstNode node) {
    nullSafetyDeadCodeVerifier.visitNode(node);
  }

  @override
  List<DiagnosticMessage> computeWhyNotPromotedMessages(
    SyntacticEntity errorEntity,
    Map<SharedTypeView, NonPromotionReason>? whyNotPromoted,
  ) {
    List<DiagnosticMessage> messages = [];
    if (whyNotPromoted != null) {
      for (var entry in whyNotPromoted.entries) {
        var whyNotPromotedVisitor = _WhyNotPromotedVisitor(
          source,
          errorEntity,
          flowAnalysis.dataForTesting,
        );
        if (typeSystem.isPotentiallyNullable(
          // TODO(paulberry): make this type argument unnecessary by changing
          // the parameter of `TypeSystemImpl.isPotentiallyNullable` to
          // (covariant) `TypeImpl`.
          entry.key.unwrapTypeView<TypeImpl>(),
        )) {
          continue;
        }
        messages = entry.value.accept(whyNotPromotedVisitor);
        // `messages` will be passed to the DiagnosticReporter, which might add
        // additional entries. So make sure that it's not a `const []`.
        assert(_isModifiableList(messages));
        if (messages.isNotEmpty) {
          if (flowAnalysis.dataForTesting != null) {
            var nonPromotionReasonText = entry.value.shortName;
            var args = <String>[];
            var propertyReference = whyNotPromotedVisitor.propertyReference;
            if (propertyReference != null) {
              var id = computeMemberId(propertyReference);
              args.add('target: $id');
            }
            if (args.isNotEmpty) {
              nonPromotionReasonText += '(${args.join(', ')})';
            }
            flowAnalysis.dataForTesting!.nonPromotionReasons[errorEntity] =
                nonPromotionReasonText;
          }
        }
        break;
      }
    }
    return messages;
  }

  @override
  void dispatchCollectionElement(
    covariant CollectionElementImpl element,
    covariant CollectionLiteralContext? context,
  ) {
    element.resolveElement(this, context);
    popRewrite();
  }

  @override
  ExpressionTypeAnalysisResult dispatchExpression(
    covariant ExpressionImpl expression,
    SharedTypeSchemaView context, {
    bool isVoidAllowed = false,
    bool needsCoercion = false,
  }) {
    // Note: the analyzer doesn't use the `isVoidAllowed` boolean; it detects
    // invalid use of void through more ad hoc mechanisms. See
    // https://github.com/dart-lang/sdk/issues/62942.
    // TODO(paulberry): address this.

    int? stackDepth;
    assert(() {
      stackDepth = rewriteStackDepth;
      return true;
    }());
    // Stack: ()
    pushRewrite(expression);
    // Stack: (Expression)
    expression.resolveExpression(this, context.unwrapTypeSchemaView());
    inferenceLogWriter?.assertExpressionWasRecorded(expression);
    assert(rewriteStackDepth == stackDepth! + 1);
    var replacementExpression = peekRewrite()!;
    assert(
      identical(_replacements[expression] ?? expression, replacementExpression),
    );
    var staticType = replacementExpression.staticType;
    if (staticType == null) {
      var shouldHaveType = true;
      if (replacementExpression is ExtensionOverride) {
        shouldHaveType = false;
      } else if (replacementExpression is IdentifierImpl) {
        var element = replacementExpression.element;
        if (element is ExtensionElement ||
            element is InterfaceElement ||
            element is PrefixElement ||
            element is TypeAliasElement) {
          shouldHaveType = false;
        }
      }
      if (shouldHaveType) {
        assert(
          false,
          'No static type for: '
          '(${replacementExpression.runtimeType}) $replacementExpression',
        );
      }
      staticType = operations.unknownType.unwrapTypeSchemaView();
    }
    var flowAnalysisInfo = flowAnalysis.getExpressionInfo(expression);
    assert(() {
      // When the AST is rewritten, the analyzer's convention is to associate
      // flow analysis expression info with the original expression, not the
      // replacement. (Note, however, that it's ok to associate the same info
      // with both expressions.)
      var replacementFlowAnalysisInfo = flowAnalysis.getExpressionInfo(
        replacementExpression,
      );
      assert(
        replacementFlowAnalysisInfo == null ||
            identical(flowAnalysisInfo, replacementFlowAnalysisInfo),
      );
      return true;
    }());
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(staticType),
      flowAnalysisInfo: flowAnalysisInfo,
    );
  }

  @override
  PatternResult dispatchPattern(SharedMatchContext context, AstNodeImpl node) {
    shared.PatternResult analysisResult;
    if (node is DartPatternImpl) {
      analysisResult = node.resolvePattern(this, context);
      node.matchedValueType = analysisResult.matchedValueType.unwrapTypeView();
    } else {
      // This can occur inside conventional switch statements, since
      // [SwitchCase] points directly to an [Expression] rather than to a
      // [ConstantPattern].  So we mimic what
      // [ConstantPatternImpl.resolvePattern] would do.
      analysisResult = analyzeConstantPattern(
        context,
        null,
        node as ExpressionImpl,
      );
      // Stack: (Expression)
      popRewrite();
      // Stack: ()
    }
    return analysisResult;
  }

  @override
  SharedTypeSchemaView dispatchPatternSchema(covariant DartPatternImpl node) {
    return SharedTypeSchemaView(node.computePatternSchema(this));
  }

  @override
  void dispatchStatement(Statement statement) {
    statement.accept2(this);
  }

  @override
  SharedTypeView downwardInferObjectPatternRequiredType({
    required SharedTypeView matchedType,
    required covariant ObjectPatternImpl pattern,
  }) {
    var typeNode = pattern.type;
    if (typeNode.typeArguments == null) {
      var typeNameElement = typeNode.element;
      if (typeNameElement is InterfaceElementImpl) {
        var typeParameters = typeNameElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var typeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            errorNode: typeNode,
            declaredType: typeNameElement.thisType,
            contextType: matchedType.unwrapTypeView(),
            nodeForTesting: pattern,
          );
          return SharedTypeView(
            typeNode.type = typeNameElement.instantiateImpl(
              typeArguments: typeArguments,
              nullabilitySuffix: NullabilitySuffix.none,
            ),
          );
        }
      } else if (typeNameElement is TypeAliasElementImpl) {
        var typeParameters = typeNameElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var typeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            errorNode: typeNode,
            declaredType: typeNameElement.aliasedType,
            contextType: matchedType.unwrapTypeView(),
            nodeForTesting: pattern,
          );
          return SharedTypeView(
            typeNode.type = typeNameElement.instantiateImpl(
              typeArguments: typeArguments,
              nullabilitySuffix: NullabilitySuffix.none,
            ),
          );
        }
      }
    }
    return SharedTypeView(typeNode.typeOrThrow);
  }

  @override
  void finishExpressionCase(
    covariant SwitchExpressionImpl node,
    int caseIndex,
  ) {
    var case_ = node.cases[caseIndex];
    case_.expression2 = popRewrite()!;
    nullSafetyDeadCodeVerifier.flowEnd(case_);
  }

  @override
  void finishJoinedPatternVariable(
    covariant JoinPatternVariableElementImpl variable, {
    required JoinedPatternVariableLocation location,
    required shared.JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required SharedTypeView type,
  }) {
    variable.inconsistency = variable.inconsistency.maxWith(inconsistency);
    variable.isFinal = isFinal;
    variable.type = type.unwrapTypeView();

    if (location == JoinedPatternVariableLocation.sharedCaseScope) {
      for (var reference in variable.references) {
        if (variable.inconsistency ==
            shared.JoinedPatternVariableInconsistency.sharedCaseAbsent) {
          diagnosticReporter.report(
            diag.patternVariableSharedCaseScopeNotAllCases
                .withArguments(name: variable.name!)
                .at(reference),
          );
        } else if (variable.inconsistency ==
            shared.JoinedPatternVariableInconsistency.sharedCaseHasLabel) {
          diagnosticReporter.report(
            diag.patternVariableSharedCaseScopeHasLabel
                .withArguments(name: variable.name!)
                .at(reference),
          );
        } else if (variable.inconsistency ==
            shared.JoinedPatternVariableInconsistency.differentFinalityOrType) {
          diagnosticReporter.report(
            diag.patternVariableSharedCaseScopeDifferentFinalityOrType
                .withArguments(name: variable.name!)
                .at(reference),
          );
        }
      }
    }
  }

  @override
  shared.ExpressionTypeAnalysisResult finishNullShorting(
    int targetDepth,
    shared.ExpressionTypeAnalysisResult innerResult, {
    required ExpressionImpl wholeExpression,
  }) {
    var analysisResult = super.finishNullShorting(
      targetDepth,
      innerResult,
      wholeExpression: wholeExpression,
    );
    // If any expression info or expression reference was stored for the
    // null-aware expression, it was only valid in the case where the target
    // expression was not null. So it needs to be cleared now.
    flowAnalysis.storeExpressionInfo(wholeExpression, null);
    return analysisResult;
  }

  @override
  shared.MapPatternEntry<ExpressionImpl, DartPatternImpl>? getMapPatternEntry(
    covariant MapPatternElementImpl element,
  ) {
    if (element is MapPatternEntryImpl) {
      return shared.MapPatternEntry(key: element.key2, value: element.value);
    }
    return null;
  }

  @override
  DartPatternImpl? getRestPatternElementPattern(
    covariant RestPatternElementImpl element,
  ) {
    return element.pattern;
  }

  @override
  SwitchExpressionMemberInfo<AstNodeImpl, ExpressionImpl, PromotableElementImpl>
  getSwitchExpressionMemberInfo(
    covariant SwitchExpressionImpl node,
    int index,
  ) {
    var case_ = node.cases[index];
    var guardedPattern = case_.guardedPattern;
    return SwitchExpressionMemberInfo(
      head: CaseHeadInfo(
        pattern: guardedPattern.pattern,
        guard: guardedPattern.whenClause?.expression2,
        variables: guardedPattern.variables,
      ),
      expression: case_.expression2,
    );
  }

  @override
  SwitchStatementMemberInfo<
    AstNodeImpl,
    StatementImpl,
    ExpressionImpl,
    PromotableElementImpl
  >
  getSwitchStatementMemberInfo(covariant SwitchStatementImpl node, int index) {
    CaseHeadOrDefaultInfo<AstNodeImpl, ExpressionImpl, PromotableElementImpl>
    ofMember(SwitchMemberImpl member) {
      if (member is SwitchCaseImpl) {
        return CaseHeadInfo(pattern: member.expression2, variables: {});
      } else if (member is SwitchPatternCaseImpl) {
        var guardedPattern = member.guardedPattern;
        return CaseHeadInfo(
          pattern: guardedPattern.pattern,
          variables: guardedPattern.variables,
          guard: guardedPattern.whenClause?.expression2,
        );
      } else {
        return CaseDefaultInfo();
      }
    }

    var group = node.memberGroups[index];
    return SwitchStatementMemberInfo(
      heads: group.members.map(ofMember).toList(),
      body: group.statements,
      variables: group.variables,
      hasLabels: group.hasLabels,
    );
  }

  @override
  void handle_ifElement_conditionEnd(covariant IfElementImpl node) {
    // Stack: (Expression condition)
    var condition = popRewrite()!;

    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(condition),
    );
    boolExpressionVerifier.checkForNonBoolCondition(
      condition,
      whyNotPromoted: whyNotPromoted,
    );
  }

  @override
  void handle_ifElement_elseEnd(
    covariant IfElementImpl node,
    covariant CollectionElementImpl ifFalse,
  ) {
    nullSafetyDeadCodeVerifier.flowEnd(ifFalse);
  }

  @override
  void handle_ifElement_thenEnd(
    covariant IfElementImpl node,
    covariant CollectionElementImpl ifTrue,
  ) {
    nullSafetyDeadCodeVerifier.flowEnd(ifTrue);
  }

  @override
  void handle_ifStatement_conditionEnd(Statement node) {
    // Stack: (Expression condition)
    var condition = popRewrite()!;

    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(condition),
    );
    boolExpressionVerifier.checkForNonBoolCondition(
      condition,
      whyNotPromoted: whyNotPromoted,
    );
  }

  @override
  void handle_ifStatement_elseEnd(Statement node, Statement ifFalse) {
    nullSafetyDeadCodeVerifier.flowEnd(ifFalse);
  }

  @override
  void handle_ifStatement_thenEnd(Statement node, Statement ifTrue) {
    nullSafetyDeadCodeVerifier.flowEnd(ifTrue);
  }

  @override
  void handle_logicalOrPattern_afterLhs(covariant LogicalOrPatternImpl node) {
    checkUnreachableNode(node.rightOperand);
  }

  @override
  void handleCase_afterCaseHeads(
    AstNode node,
    int caseIndex,
    Iterable<PromotableElementImpl> variables,
  ) {}

  @override
  void handleCaseHead(
    covariant AstNodeImpl node, {
    required int caseIndex,
    required int subIndex,
  }) {
    // Stack: (Expression)
    popRewrite(); // "when" expression
    // Stack: ()
    if (node is SwitchStatementImpl) {
      var group = node.memberGroups[caseIndex];
      legacySwitchExhaustiveness?.visitSwitchMember(group);
      nullSafetyDeadCodeVerifier.flowEnd(group.members[subIndex]);
    } else if (node is SwitchExpressionImpl) {
      legacySwitchExhaustiveness?.visitSwitchExpressionCase(
        node.cases[caseIndex],
      );
    }
  }

  @override
  void handleDefault(
    covariant SwitchStatementImpl node, {
    required int caseIndex,
    required int subIndex,
  }) {
    var group = node.memberGroups[caseIndex];
    legacySwitchExhaustiveness?.visitSwitchMember(group);
    nullSafetyDeadCodeVerifier.flowEnd(group.members[subIndex]);
  }

  @override
  void handleListPatternRestElement(
    DartPattern container,
    covariant RestPatternElementImpl restElement,
  ) {}

  @override
  void handleMapPatternEntry(
    DartPattern container,
    covariant MapPatternEntryImpl entry,
    SharedTypeView keyType,
  ) {
    entry.key2 = popRewrite()!;
  }

  @override
  void handleMapPatternRestElement(
    DartPattern container,
    covariant RestPatternElementImpl restElement,
  ) {}

  @override
  void handleMergedStatementCase(
    covariant SwitchStatementImpl node, {
    required int caseIndex,
    required bool isTerminating,
  }) {
    nullSafetyDeadCodeVerifier.flowEnd(
      node.memberGroups[caseIndex].members.last,
    );
  }

  @override
  void handleNoCollectionElement(AstNode node) {}

  @override
  void handleNoGuard(AstNode node, int caseIndex) {
    // Stack: ()
    // We can push `null` here because there is no actual expression associated
    // with the lack of a guard, so there's nothing that will need rewriting.
    pushRewrite(null);
    // Stack: (Expression)
  }

  @override
  void handleNoStatement(Statement node) {}

  @override
  void handleNullShortingFinished(SharedTypeView inferredType) {
    var expression = peekRewrite() as ExpressionImpl;
    expression.recordNullShortedType(inferredType.unwrapTypeView());
    nullSafetyDeadCodeVerifier.flowEnd(expression);
  }

  @override
  void handleSwitchBeforeAlternative(
    covariant AstNodeImpl node, {
    required int caseIndex,
    required int subIndex,
  }) {
    if (node is SwitchExpressionImpl) {
      var case_ = node.cases[caseIndex];
      checkUnreachableNode(case_);
    } else if (node is SwitchStatementImpl) {
      var member = node.memberGroups[caseIndex].members[subIndex];
      checkUnreachableNode(member);
    }
  }

  @override
  void handleSwitchScrutinee(SharedTypeView type) {
    if (!typeAnalyzerOptions.patternsEnabled) {
      legacySwitchExhaustiveness = SwitchExhaustiveness(type.unwrapTypeView());
    }
  }

  /// If generic function instantiation should be performed on `expression`,
  /// inserts a [FunctionReference] node which wraps [expression].
  ///
  /// If an [FunctionReference] is inserted, returns it; otherwise, returns
  /// [expression].
  ExpressionImpl insertGenericFunctionInstantiation(
    Expression expression, {
    required TypeImpl contextType,
  }) {
    expression as ExpressionImpl;
    if (!isConstructorTearoffsEnabled) {
      // Temporarily, only create [ImplicitCallReference] nodes under the
      // 'constructor-tearoffs' feature.
      // TODO(srawlins): When we are ready to make a breaking change release to
      // the analyzer package, remove this exception.
      return expression;
    }

    // Don't rewrite function declarations.
    if (expression.parent2 is FunctionDeclaration) {
      return expression;
    }

    var staticType = expression.staticType;
    if (staticType is! FunctionTypeImpl || staticType.typeParameters.isEmpty) {
      return expression;
    }

    var context = typeSystem.flatten(contextType);
    if (context is! FunctionTypeImpl || context.typeParameters.isNotEmpty) {
      return expression;
    }

    var typeArgumentTypes = typeSystem.inferFunctionTypeInstantiation(
      context,
      staticType,
      diagnosticReporter: diagnosticReporter,
      errorNode: expression,
      // If the constructor-tearoffs feature is enabled, then so is
      // generic-metadata.
      genericMetadataIsEnabled: true,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
      strictInference: analysisOptions.strictInference,
      strictCasts: analysisOptions.strictCasts,
      typeSystemOperations: flowAnalysis.typeOperations,
      dataForTesting: inferenceHelper.dataForTesting,
      nodeForTesting: expression,
    );
    if (typeArgumentTypes.isNotEmpty) {
      staticType = staticType.instantiate(typeArgumentTypes);
    }

    var parent = expression.parent2;
    var genericFunctionInstantiation = FunctionReferenceImpl(
      function2: expression,
      typeArguments: null,
    );
    replaceExpression(expression, genericFunctionInstantiation, parent: parent);

    genericFunctionInstantiation.typeArgumentTypes = typeArgumentTypes;
    genericFunctionInstantiation.setPseudoExpressionStaticType(staticType);

    return genericFunctionInstantiation;
  }

  @override
  bool isDotShorthand(ExpressionImpl node) {
    if (node is DotShorthandMixin) {
      return node.isDotShorthand;
    }
    return false;
  }

  @override
  bool isLegacySwitchExhaustive(AstNode node, SharedTypeView expressionType) =>
      legacySwitchExhaustiveness!.isExhaustive;

  @override
  bool isRestPatternElement(AstNode node) {
    return node is RestPatternElementImpl;
  }

  @override
  bool isVariablePattern(AstNode pattern) => pattern is DeclaredVariablePattern;

  /// If it is appropriate to do so, override the current type of the static
  /// element associated with the given expression with the given type.
  /// Generally speaking, it is appropriate if the given type is more specific
  /// than the current type.
  ///
  /// @param expression the expression used to access the static element whose
  ///        types might be overridden
  /// @param potentialType the potential type of the elements
  /// @param allowPrecisionLoss see @{code overrideVariable} docs
  void overrideExpression(
    Expression expression,
    DartType potentialType,
    bool allowPrecisionLoss,
    bool setExpressionType,
  ) {
    // TODO(brianwilkerson): Remove this method.
  }

  /// Examines the top entry of [_rewriteStack] but does not pop it.
  ExpressionImpl? peekRewrite() => _rewriteStack.last;

  /// Pops the top entry off of [_rewriteStack].
  ExpressionImpl? popRewrite() {
    var expression = _rewriteStack.removeLast();
    if (_debugRewriteStack) {
      assert(_debugPrint('POP ${expression.runtimeType} $expression'));
    }
    return expression;
  }

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    InterfaceElementImpl? enclosingInstanceElement,
    ExecutableElementImpl? enclosingExecutableElement,
  }) {
    this.enclosingInstanceElement = enclosingInstanceElement;
    _unpromotedThisType = enclosingInstanceElement?.thisType;
    this.enclosingExecutableElement = enclosingExecutableElement;
  }

  /// We are going to resolve [node], without visiting its parent.
  /// Do necessary preparations - set enclosing elements, scopes, etc.
  /// This [ResolverVisitor] instance is fresh, just created.
  ///
  /// Return `true` if we were able to do this, or `false` if it is not
  /// possible to resolve only [node].
  bool prepareForResolving(AstNode node) {
    var parent = node.parent2;

    if (parent is CompilationUnit) {
      return node is ClassDeclaration ||
          node is Directive ||
          node is ExtensionDeclaration ||
          node is FunctionDeclaration ||
          node is TopLevelVariableDeclaration;
    }

    if (parent is ClassBody) {
      parent = parent.parent2;
    }

    if (parent is ClassDeclarationImpl) {
      enclosingInstanceElement = parent.declaredFragment!.element;
      return true;
    }

    if (parent is ExtensionDeclarationImpl) {
      enclosingInstanceElement = parent.declaredFragment!.element;
      return true;
    }

    if (parent is MixinDeclarationImpl) {
      enclosingInstanceElement = parent.declaredFragment!.element;
      return true;
    }

    return false;
  }

  /// Pushes an entry onto [_rewriteStack].
  void pushRewrite(ExpressionImpl? expression) {
    if (_debugRewriteStack) {
      assert(_debugPrint('PUSH ${expression.runtimeType} $expression'));
    }
    _rewriteStack.add(expression);
  }

  /// Replaces the expression [oldNode] with [newNode], updating the node's
  /// parent as appropriate.
  ///
  /// If [newNode] is the parent of [oldNode] already (because [newNode] became
  /// the parent of [oldNode] in its constructor), this action will loop
  /// infinitely; pass [oldNode]'s previous parent as [parent] to avoid this.
  void replaceExpression(
    ExpressionImpl oldNode,
    ExpressionImpl newNode, {
    AstNodeImpl? parent,
  }) {
    assert(() {
      assert(_replacements[oldNode] == null);
      _replacements[oldNode] = newNode;
      return true;
    }());
    if (_rewriteStack.isNotEmpty && identical(peekRewrite(), oldNode)) {
      if (_debugRewriteStack) {
        assert(_debugPrint('REPLACE ${newNode.runtimeType} $newNode'));
      }
      _rewriteStack.last = newNode;
    }
    inferenceLogWriter?.recordExpressionRewrite(
      oldExpression: oldNode,
      newExpression: newNode,
    );
    parent ??= oldNode.parent2;
    parent!.replaceChild(oldNode, newNode);
    nullSafetyDeadCodeVerifier.maybeRewriteFirstDeadNode(oldNode, newNode);
  }

  PatternResult resolveAssignedVariablePattern({
    required AssignedVariablePatternImpl node,
    required SharedMatchContext context,
  }) {
    var element = node.element;
    if (element is! PromotableElementImpl) {
      return PatternResult(
        matchedValueType: SharedTypeView(InvalidTypeImpl.instance),
      );
    }

    if (element.isFinal) {
      var flow = this.flow;
      if (element.isLate) {
        if (flow.isAssigned(element)) {
          diagnosticReporter.report(
            diag.lateFinalLocalAlreadyAssigned.at(node.name),
          );
        }
      } else {
        if (!flow.isUnassigned(element)) {
          diagnosticReporter.report(
            diag.assignmentToFinalLocal
                .withArguments(variableName: node.name.lexeme)
                .at(node.name),
          );
        }
      }
    }

    return analyzeAssignedVariablePattern(context, node, element);
  }

  /// Resolve LHS [node] of an assignment, an explicit [AssignmentExpression],
  /// or implicit [PrefixExpression] or [PostfixExpression].
  PropertyElementResolverResult resolveForWrite({
    required ExpressionImpl node,
    required bool hasRead,
  }) {
    inferenceLogWriter?.enterLValue(node);
    if (node is IndexExpressionImpl) {
      var target = node.target2;
      if (target != null) {
        if (isDotShorthand(node)) {
          // Recovery.
          // It's a compile-time error to use postfix or prefix operators with
          // dot shorthands. We provide an unknown type since this shouldn't be
          // valid code, but we want to prevent any crashes.
          pushDotShorthandContext(target, operations.unknownType);
        }
        analyzeExpression(
          target,
          operations.unknownType,
          continueNullShorting: true,
        );
        popRewrite();
      }

      if (node.isNullAware) {
        _startNullAwareAccess(node.target2);
        nullSafetyDeadCodeVerifier.visitNode(node.index2);
      }

      var result = _propertyElementResolver.resolveIndexExpression(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      analyzeExpression(
        node.index2,
        SharedTypeSchemaView(result.indexContextType),
      );
      popRewrite();
      var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
        flowAnalysis.getExpressionInfo(node.index2),
      );
      checkIndexExpressionIndex(
        node.index2,
        readElement: hasRead
            ? result.readElement2 as InternalExecutableElement?
            : null,
        writeElement: result.writeElement2 as InternalExecutableElement?,
        whyNotPromoted: whyNotPromoted,
      );

      inferenceLogWriter?.exitLValue(node);
      return result;
    } else if (node is PrefixedIdentifierImpl) {
      var prefix = node.prefix;
      analyzeExpression(
        prefix,
        operations.unknownType,
        continueNullShorting: true,
      );
      popRewrite();

      // TODO(scheglov): It would be nice to rewrite all such cases.
      if (prefix.staticType is RecordType) {
        var propertyAccess = PropertyAccessImpl(
          target2: prefix,
          operator: node.period,
          propertyName: node.identifier,
        );
        node.replaceWith(propertyAccess);
        inferenceLogWriter?.exitLValue(node);
        return _propertyElementResolver.resolvePropertyAccess(
          node: propertyAccess,
          hasRead: hasRead,
          hasWrite: true,
        );
      }

      inferenceLogWriter?.exitLValue(node);
      return _propertyElementResolver.resolvePrefixedIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is PropertyAccessImpl) {
      if (node.target2 case var target?) {
        if (isDotShorthand(node)) {
          // Recovery.
          // It's a compile-time error to use a dot shorthand as the target of a
          // write, but to prevent any crashing we provide an unknown context
          // type since this shouldn't be valid code.
          pushDotShorthandContext(target, operations.unknownType);
        }
        analyzeExpression(
          target,
          operations.unknownType,
          continueNullShorting: true,
        );
        popRewrite();
      }
      if (node.isNullAware) {
        _startNullAwareAccess(node.target2);
        nullSafetyDeadCodeVerifier.visitNode(node.propertyName);
      }

      inferenceLogWriter?.exitLValue(node);
      return _propertyElementResolver.resolvePropertyAccess(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is SimpleIdentifierImpl) {
      var result = _propertyElementResolver.resolveSimpleIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      if (hasRead && result.readElementRequested2 == null) {
        diagnosticReporter.report(
          diag.undefinedIdentifier.withArguments(name: node.name).at(node),
        );
      }

      inferenceLogWriter?.exitLValue(node);
      return result;
    } else {
      inferenceLogWriter?.exitLValue(node, reanalyzeAsRValue: true);
      analyzeExpression(
        node,
        SharedTypeSchemaView(UnknownInferredType.instance),
      );
      popRewrite();
      return PropertyElementResolverResult();
    }
  }

  PatternResult resolveMapPattern({
    required MapPatternImpl node,
    required SharedMatchContext context,
  }) {
    inferenceLogWriter?.enterPattern(node);
    ({SharedTypeView keyType, SharedTypeView valueType})? typeArguments;
    var typeArgumentsList = node.typeArguments;
    if (typeArgumentsList != null) {
      typeArgumentsList.accept2(this);
      // Check that we have exactly two type arguments.
      var length = typeArgumentsList.arguments.length;
      if (length == 2) {
        typeArguments = (
          keyType: SharedTypeView(typeArgumentsList.arguments[0].typeOrThrow),
          valueType: SharedTypeView(typeArgumentsList.arguments[1].typeOrThrow),
        );
      } else {
        diagnosticReporter.report(
          diag.expectedTwoMapPatternTypeArguments
              .withArguments(count: length)
              .at(typeArgumentsList),
        );
      }
    }

    var result = analyzeMapPattern(
      context,
      node,
      typeArguments: typeArguments,
      elements: node.elements,
    );
    node.requiredType = result.requiredType.unwrapTypeView();

    checkPatternNeverMatchesValueType(
      context: context,
      pattern: node,
      requiredType: result.requiredType.unwrapTypeView(),
      matchedValueType: result.matchedValueType.unwrapTypeView(),
    );
    inferenceLogWriter?.exitPattern(node);

    return result;
  }

  @override
  (ExecutableElement?, SharedTypeView) resolveObjectPatternPropertyGet({
    required covariant ObjectPatternImpl objectPattern,
    required SharedTypeView receiverType,
    required covariant SharedPatternField field,
  }) {
    var fieldNode = field.node;
    var nameToken = fieldNode.name?.name;
    nameToken ??= field.pattern.variablePattern?.name;
    if (nameToken == null) {
      return (null, SharedTypeView(typeProvider.dynamicType));
    }

    var result = typePropertyResolver.resolve(
      receiver: null,
      receiverType: receiverType.unwrapTypeView(),
      name: nameToken.lexeme,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: objectPattern.type,
      nameErrorEntity: nameToken,
    );

    if (result.needsGetterError) {
      diagnosticReporter.report(
        diag.undefinedGetter
            .withArguments(
              memberName: nameToken.lexeme,
              type: receiverType.unwrapTypeView<TypeImpl>(),
            )
            .at(nameToken),
      );
    }

    var getter = result.getter2;
    if (getter != null) {
      fieldNode.element = getter;
      if (getter is InternalPropertyAccessorElement) {
        return (getter, SharedTypeView(getter.returnType));
      } else {
        return (getter, SharedTypeView(getter.type));
      }
    }

    var recordField = result.recordField;
    if (recordField != null) {
      return (null, SharedTypeView(recordField.type));
    }

    return (null, SharedTypeView(typeProvider.dynamicType));
  }

  @override
  RelationalOperatorResolution? resolveRelationalPatternOperator(
    covariant RelationalPatternImpl node,
    SharedTypeView matchedType,
  ) {
    var operatorLexeme = node.operator.lexeme;
    RelationalOperatorKind kind;
    String methodName;
    if (operatorLexeme == '==') {
      kind = RelationalOperatorKind.equals;
      methodName = '==';
    } else if (operatorLexeme == '!=') {
      kind = RelationalOperatorKind.notEquals;
      methodName = '==';
    } else {
      kind = RelationalOperatorKind.other;
      methodName = operatorLexeme;
    }

    var result = typePropertyResolver.resolve(
      receiver: null,
      receiverType: matchedType.unwrapTypeView(),
      name: methodName,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.operator,
      nameErrorEntity: node,
      parentNode: node,
    );

    if (result.needsGetterError) {
      diagnosticReporter.report(
        diag.undefinedOperator
            .withArguments(
              operator: methodName,
              type: matchedType.unwrapTypeView<TypeImpl>(),
            )
            .at(node.operator),
      );
    }

    var element = result.getter2 as InternalMethodElement?;
    node.element = element;
    if (element == null) {
      return null;
    }

    var parameterType = element.firstParameterType;
    if (parameterType == null) {
      return null;
    }

    return RelationalOperatorResolution(
      kind: kind,
      parameterType: SharedTypeView(parameterType),
      returnType: SharedTypeView(element.returnType),
    );
  }

  void setReadElement(
    Expression node,
    Element? element, {
    required bool atDynamicTarget,
  }) {
    var readType = atDynamicTarget
        ? DynamicTypeImpl.instance
        : InvalidTypeImpl.instance;
    if (node is IndexExpression) {
      if (element is InternalMethodElement) {
        readType = element.returnType;
      }
    } else if (node is PrefixedIdentifier ||
        node is PropertyAccess ||
        node is SimpleIdentifier) {
      if (element is InternalGetterElement) {
        readType = element.returnType;
      } else if (element is VariableElement) {
        readType = localVariableTypeProvider.getType(
          node as SimpleIdentifierImpl,
          isRead: true,
        );
      }
    }

    var parent = node.parent2;
    if (parent is AssignmentExpressionImpl && parent.leftHandSide2 == node) {
      parent.readElement = element;
      parent.readType = readType;
    } else if (parent is PostfixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.readElement = element;
      parent.readType = readType;
    } else if (parent is PrefixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.readElement = element;
      parent.readType = readType;
    }
  }

  @override
  void setVariableType(PromotableElementImpl variable, SharedTypeView type) {
    if (variable is LocalVariableElementImpl) {
      variable.type = type.unwrapTypeView();
    } else {
      throw UnimplementedError('TODO(paulberry)');
    }
  }

  void setWriteElement(
    Expression node,
    Element? element, {
    required bool atDynamicTarget,
  }) {
    var writeType = atDynamicTarget
        ? DynamicTypeImpl.instance
        : InvalidTypeImpl.instance;
    if (node is IndexExpression) {
      if (element is InternalMethodElement) {
        var parameters = element.formalParameters;
        if (parameters.length == 2) {
          writeType = parameters[1].type;
        }
      }
    } else if (node is PrefixedIdentifier ||
        node is PropertyAccess ||
        node is SimpleIdentifier) {
      if (element is InternalSetterElement) {
        if (element.isOriginVariable) {
          writeType = element.variable.type;
        } else {
          var parameters = element.formalParameters;
          if (parameters.length == 1) {
            writeType = parameters[0].type;
          }
        }
      } else if (element is InternalVariableElement) {
        writeType = element.type;
      }
    }

    var parent = node.parent2;
    if (parent is AssignmentExpressionImpl && parent.leftHandSide2 == node) {
      parent.writeElement = element;
      parent.writeType = writeType;
    } else if (parent is PostfixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.writeElement = element;
      parent.writeType = writeType;
    } else if (parent is PrefixExpressionImpl &&
        parent.operator.type.isIncrementOperator) {
      parent.writeElement = element;
      parent.writeType = writeType;
    }
  }

  /// Returns the result of an implicit `this.` lookup for the identifier [node]
  /// in a getter context, or `null` if no match was found.
  LexicalLookupResult? thisLookupGetter(SimpleIdentifier node) {
    return ThisLookup.lookupGetter(this, node);
  }

  /// Returns the result of an implicit `this.` lookup for the identifier [node]
  /// in a setter context, or `null` if no match was found.
  LexicalLookupResult? thisLookupSetter(SimpleIdentifier node) {
    return ThisLookup.lookupSetter(this, node);
  }

  @override
  SharedTypeView variableTypeFromInitializerType(SharedTypeView type) {
    TypeImpl unwrapped = type.unwrapTypeView();
    if (unwrapped.isDartCoreNull) {
      return SharedTypeView(DynamicTypeImpl.instance);
    }
    return SharedTypeView(typeSystem.demoteType(unwrapped));
  }

  @override
  void visitAdjacentStrings(
    covariant AdjacentStringsImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    for (var string in node.strings) {
      analyzeExpression(string, operations.unknownType);
      popRewrite();
    }
    typeAnalyzer.visitAdjacentStrings(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    inferenceLogWriter?.enterAnnotation(node);
    // Annotations can contain expressions, so we need flow analysis to be
    // available to process those expressions.
    flowAnalysis.withFlowAnalysis(
      node: node,
      formalParameters: null,
      operation: () {
        var whyNotPromotedArguments =
            <Map<SharedTypeView, NonPromotionReason> Function()>[];
        _annotationResolver.resolve(node, whyNotPromotedArguments);
        var arguments = node.arguments;
        if (arguments != null) {
          checkForArgumentTypesNotAssignableInList(
            arguments,
            whyNotPromotedArguments,
          );
        }
      },
    );
    inferenceLogWriter?.exitAnnotation(node);
  }

  @override
  TypeImpl visitAnonymousBlockBody(
    covariant AnonymousBlockBodyImpl node, {
    TypeImpl? imposedType,
  }) {
    var oldBodyContext = _bodyContext;
    try {
      _bodyContext = BodyInferenceContext.forAnonymousBlockBody(
        typeSystem: typeSystem,
        node: node,
        imposedType: imposedType,
      );

      flowAnalysis.flow?.anonymousBlockBody_begin();
      checkUnreachableNode(node);
      node.visitChildren2(this);
      var returnType = _finishFunctionBodyInference();
      flowAnalysis.flow?.anonymousBlockBody_end();

      return returnType;
    } finally {
      _bodyContext = oldBodyContext;
    }
  }

  @override
  TypeImpl visitAnonymousExpressionBody(
    covariant AnonymousExpressionBodyImpl node, {
    TypeImpl? imposedType,
  }) {
    checkUnreachableNode(node);

    analyzeExpression(
      node.expression2,
      SharedTypeSchemaView(imposedType ?? UnknownInferredType.instance),
    );
    popRewrite();

    return node.expression2.staticType ?? typeProvider.dynamicType;
  }

  @override
  void visitAnonymousMethodInvocation(
    covariant AnonymousMethodInvocationImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);

    var target = node.target2;
    if (target != null) {
      analyzeExpression(
        target,
        SharedTypeSchemaView(UnknownInferredType.instance),
        continueNullShorting: true,
      );
      popRewrite();
    }

    checkUnreachableNode(node.body);

    var targetType =
        node.realTarget.staticType ?? typeProvider.objectQuestionType;
    var isNullAware = node.isNullAware;
    var parameterType = isNullAware
        ? typeSystem.promoteToNonNull(targetType)
        : targetType;
    var parameters = node.parameters;
    if (isNullAware) {
      _startNullAwareAccess(node.target2);
      nullSafetyDeadCodeVerifier.visitNode(parameters ?? node.body);
    }
    if (parameters != null) {
      var formalParameters = parameters.allFormalParameters;
      for (var parameter in formalParameters) {
        if (parameter is RegularFormalParameterImpl &&
            parameter.functionTypedSuffix == null &&
            parameter.type == null) {
          if (parameter == formalParameters.first) {
            parameter.declaredFragment?.element.type = parameterType;
          }
        }
      }
      parameters.accept2(this);
      for (var parameter in formalParameters) {
        var element = parameter.declaredFragment?.element;
        if (element != null) {
          if (parameter == formalParameters.first) {
            flow.declare(
              element,
              SharedTypeView(element.type),
              initialized: false,
            );
            flow.initialize(
              element,
              SharedTypeView(element.type),
              target != null ? flowAnalysis.getExpressionInfo(target) : null,
              isFinal: false,
              isLate: false,
              isImplicitlyTyped: parameter.type == null,
              inheritPromotableProperties: false,
            );
          } else {
            // An error will occur because there are multiple parameters, but
            // those extra parameters should still allow for meaningful analysis
            // in the body of the anonymous method.
            flow.declare(
              element,
              SharedTypeView(element.type),
              initialized: true,
            );
          }
        }
      }
    }

    TypeImpl returnedType;
    if (parameters == null) {
      var target = node.target2;
      var targetInfo = target != null
          ? flowAnalysis.getExpressionInfo(target)
          : null;
      var body = node.body;
      returnedType = _withUnpromotedThisType(parameterType, () {
        flowAnalysis.flow?.thisBinding_begin(targetInfo);
        try {
          return body.resolve(this, contextType);
        } finally {
          flowAnalysis.flow?.thisBinding_end();
        }
      });
      if (body is AnonymousExpressionBodyImpl) {
        flowAnalysis.storeExpressionInfo(
          node,
          flowAnalysis.getExpressionInfo(body.expression2),
        );
      }
    } else {
      returnedType = node.body.resolve(this, contextType);
    }

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    node.recordStaticType(returnedType, resolver: this);

    if (parameters != null) {
      var parameter = parameters.allFormalParameters.firstOrNull;
      if (parameter is RegularFormalParameterImpl &&
          parameter.functionTypedSuffix == null) {
        var declaredParameterType = parameter.type;
        if (declaredParameterType != null) {
          var declaredType = declaredParameterType.typeOrThrow;
          if (!typeSystem.isAssignableTo(parameterType, declaredType)) {
            diagnosticReporter.atNode(
              declaredParameterType,
              diag.anonymousMethodWrongParameterType,
              arguments: [parameterType, declaredType],
            );
          }
        }
      }
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAsExpression(
    covariant AsExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);

    analyzeExpression(
      node.expression2,
      SharedTypeSchemaView(UnknownInferredType.instance),
    );
    popRewrite();

    checkUnreachableNode(node.type);
    node.type.accept2(this);

    typeAnalyzer.visitAsExpression(node);
    flowAnalysis.asExpression(node);
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );

    var expression = node.expression2;
    var staticType = node.staticType;
    if (staticType != null && expression is SimpleIdentifier) {
      var simpleIdentifier = expression as SimpleIdentifier;
      var element = simpleIdentifier.element;
      if (element is PromotableElementImpl &&
          !expression.typeOrThrow.isDartCoreNull &&
          typeSystem.isNullable(element.type) &&
          typeSystem.isNonNullable(staticType) &&
          flowAnalysis.isDefinitelyUnassigned(simpleIdentifier, element)) {
        diagnosticReporter.report(
          diag.castFromNullableAlwaysFails
              .withArguments(name: simpleIdentifier.name)
              .at(simpleIdentifier),
        );
      }
    }
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAssertInitializer(covariant AssertInitializerImpl node) {
    flowAnalysis.flow?.assert_begin();
    analyzeExpression(
      node.condition2,
      SharedTypeSchemaView(typeProvider.boolType),
    );
    popRewrite();
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition2,
      locatableDiagnostic: diag.nonBoolExpression,
      whyNotPromoted: flowAnalysis.flow?.whyNotPromoted(
        flowAnalysis.getExpressionInfo(node.condition2),
      ),
    );
    flowAnalysis.flow?.assert_afterCondition(
      flowAnalysis.getExpressionInfo(node.condition2),
    );
    if (node.message2 case var message?) {
      analyzeExpression(message, operations.unknownType);
      popRewrite();
    }
    flowAnalysis.flow?.assert_end();
  }

  @override
  void visitAssertStatement(covariant AssertStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    flowAnalysis.flow?.assert_begin();
    analyzeExpression(
      node.condition2,
      SharedTypeSchemaView(typeProvider.boolType),
    );
    popRewrite();
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition2,
      locatableDiagnostic: diag.nonBoolExpression,
      whyNotPromoted: flowAnalysis.flow?.whyNotPromoted(
        flowAnalysis.getExpressionInfo(node.condition2),
      ),
    );
    flowAnalysis.flow?.assert_afterCondition(
      flowAnalysis.getExpressionInfo(node.condition2),
    );
    if (node.message2 case var message?) {
      analyzeExpression(message, operations.unknownType);
      popRewrite();
    }
    flowAnalysis.flow?.assert_end();
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitAssignmentExpression(
    AssignmentExpression node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _assignmentExpressionResolver.resolve(
      node as AssignmentExpressionImpl,
      contextType: contextType,
    );
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAwaitExpression(
    covariant AwaitExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var analysisResult = analyzeAwaitExpression(
      node,
      node.expression2,
      contextType.wrapSharedTypeSchemaView(),
    );
    node.expression2 = popRewrite()!;
    node.recordStaticType(
      analysisResult.type.unwrapTypeView<TypeImpl>(),
      resolver: this,
    );
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitBinaryExpression(
    BinaryExpression node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _binaryExpressionResolver.resolve(
      node as BinaryExpressionImpl,
      contextType: contextType,
    );
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitBlock(Block node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitBlockClassBody(BlockClassBody node) {
    node.visitChildren2(this);
  }

  @override
  void visitBlockEnumBody(BlockEnumBody node) {
    node.visitChildren2(this);
  }

  @override
  TypeImpl visitBlockFunctionBody(
    covariant BlockFunctionBodyImpl node, {
    TypeImpl? imposedType,
  }) {
    var oldBodyContext = _bodyContext;
    try {
      _bodyContext = BodyInferenceContext(
        typeSystem: typeSystem,
        node: node,
        imposedType: imposedType,
      );
      checkUnreachableNode(node);
      node.visitChildren2(this);
      return _finishFunctionBodyInference();
    } finally {
      _bodyContext = oldBodyContext;
    }
  }

  @override
  void visitBooleanLiteral(
    covariant BooleanLiteralImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.flow?.booleanLiteral(node.value),
    );
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitBooleanLiteral(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    flowAnalysis.breakStatement(node);
  }

  @override
  void visitCascadeExpression(
    covariant CascadeExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(node.target2, SharedTypeSchemaView(contextType));
    var targetType = node.target2.staticType ?? typeProvider.dynamicType;
    popRewrite();

    flowAnalysis.flow!.cascadeExpression_afterTarget(
      flowAnalysis.getExpressionInfo(node.target2),
      SharedTypeView(targetType),
      isNullAware: node.isNullAware,
    );

    for (var cascadeSection in node.cascadeSections2) {
      analyzeExpression(cascadeSection, operations.unknownType);
      popRewrite();
    }

    typeAnalyzer.visitCascadeExpression(node);

    if (node.isNullAware) {
      flowAnalysis.flow!.nullAwareAccess_end();
    }
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.flow!.cascadeExpression_end(),
    );
    _insertImplicitCallReference(node, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyCascadeExpression(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    node.visitChildren2(this);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var declaredFragment = node.declaredFragment!;
    var declaredElement = declaredFragment.element;

    //
    // Continue the class resolution.
    //
    _withEnclosingInstanceElement(declaredElement, () {
      checkUnreachableNode(node);
      node.visitChildren2(this);
      elementResolver.visitClassDeclaration(node);
    });

    baseOrFinalTypeVerifier.checkElement(
      declaredElement,
      node.implementsClause,
    );
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var declaredFragment = node.declaredFragment!;
    var declaredElement = declaredFragment.element;

    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitClassTypeAlias(node);
    baseOrFinalTypeVerifier.checkElement(
      declaredElement,
      node.implementsClause,
    );
  }

  @override
  void visitComment(Comment node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitCommentReference(CommentReference node) {
    //
    // We do not visit the expression because it needs to be visited in the
    // context of the reference.
    //
    elementResolver.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    conditionallyStartInferenceLogging(dump: inferenceLoggingPredicate(source));
    try {
      NodeList<Directive> directives = node.directives;
      int directiveCount = directives.length;
      for (int i = 0; i < directiveCount; i++) {
        directives[i].accept2(this);
      }
      NodeList<CompilationUnitMember> declarations = node.declarations;
      int declarationCount = declarations.length;
      for (int i = 0; i < declarationCount; i++) {
        declarations[i].accept2(this);
      }
      checkIdle();
    } finally {
      stopInferenceLogging();
    }
  }

  @override
  void visitConditionalExpression(
    covariant ConditionalExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    ExpressionImpl condition = node.condition2;
    var flow = flowAnalysis.flow;
    flow?.conditional_conditionBegin();

    analyzeExpression(
      node.condition2,
      SharedTypeSchemaView(typeProvider.boolType),
    );
    condition = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(condition),
    );
    boolExpressionVerifier.checkForNonBoolCondition(
      condition,
      whyNotPromoted: whyNotPromoted,
    );

    if (flow != null) {
      flow.conditional_thenBegin(
        flowAnalysis.getExpressionInfo(condition),
        node,
      );
      checkUnreachableNode(node.thenExpression2);
    }
    analyzeExpression(node.thenExpression2, SharedTypeSchemaView(contextType));
    popRewrite();
    nullSafetyDeadCodeVerifier.flowEnd(node.thenExpression2);

    ExpressionImpl elseExpression = node.elseExpression2;

    if (flow != null) {
      flow.conditional_elseBegin(
        flowAnalysis.getExpressionInfo(node.thenExpression2),
        SharedTypeView(node.thenExpression2.typeOrThrow),
      );
      checkUnreachableNode(elseExpression);
      analyzeExpression(elseExpression, SharedTypeSchemaView(contextType));
    } else {
      analyzeExpression(elseExpression, SharedTypeSchemaView(contextType));
    }
    elseExpression = popRewrite()!;

    typeAnalyzer.visitConditionalExpression(node, contextType: contextType);
    if (flow != null) {
      flowAnalysis.storeExpressionInfo(
        node,
        flow.conditional_end(
          SharedTypeView(node.typeOrThrow),
          flowAnalysis.getExpressionInfo(elseExpression),
          SharedTypeView(elseExpression.typeOrThrow),
        ),
      );
      nullSafetyDeadCodeVerifier.flowEnd(elseExpression);
    }
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    // Don't visit the children. For the time being we don't resolve anything
    // inside the configuration.
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    var returnType = element.type.returnType;

    _withEnclosingExecutableElement(element, () {
      _withUnpromotedThisType(enclosingInstanceElement?.thisType, () {
        checkUnreachableNode(node);
        node.documentationComment?.accept2(this);
        node.metadata.accept2(this);
        node.typeName?.accept2(this);
        node.parameters.accept2(this);

        flowAnalysis.bodyOrInitializer_enter(node, element.formalParameters);
        flowAnalysis.executableDeclaration_enter(
          node,
          element.formalParameters,
          isClosure: false,
        );

        node.initializers.accept2(this);
        node.redirectedConstructor?.accept2(this);
        node.body.resolve(this, returnType is DynamicType ? null : returnType);
        elementResolver.visitConstructorDeclaration(node);

        if (node.factoryKeyword != null) {
          checkForBodyMayCompleteNormally(body: node.body, errorNode: node);
        }
        flowAnalysis.executableDeclaration_exit(node.body, false);
        flowAnalysis.bodyOrInitializer_exit();
        nullSafetyDeadCodeVerifier.flowEnd(node);
      });
    });
  }

  @override
  void visitConstructorFieldInitializer(
    covariant ConstructorFieldInitializerImpl node,
  ) {
    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    var fieldName = node.fieldName;
    var fieldElement = enclosingInstanceElement!.getField(fieldName.name);
    fieldName.element = fieldElement;
    var fieldType = fieldElement?.type ?? UnknownInferredType.instance;
    var expression = node.expression2;
    analyzeExpression(expression, SharedTypeSchemaView(fieldType));
    expression = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(expression),
    );
    if (fieldElement != null && enclosingExecutableElement != null) {
      var enclosingConstructor =
          enclosingExecutableElement as ConstructorElementImpl;
      checkForFieldInitializerNotAssignable(
        node,
        fieldElement,
        isConstConstructor: enclosingConstructor.isConst,
        whyNotPromoted: whyNotPromoted,
      );
    }
  }

  @override
  void visitConstructorInvocation(
    covariant ConstructorInvocationImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    // Types are resolved in an earlier phase, but type arguments can contain
    // invalid default-value expressions that still need expression resolution.
    node.constructorReference.typeReference.typeArguments?.accept2(this);
    constructorInvocationResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.accept2(this);
    elementResolver.visitConstructorName(node as ConstructorNameImpl);
  }

  @override
  void visitConstructorReference(
    covariant ConstructorReferenceImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    _constructorReferenceResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    flowAnalysis.continueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitDeclaredIdentifier(node);
  }

  @override
  void visitDelimitedFormalParameters(DelimitedFormalParameters node) {
    node.visitChildren2(this);
  }

  @override
  void visitDoStatement(covariant DoStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);

    var condition = node.condition2;

    flowAnalysis.flow?.doStatement_bodyBegin(node);
    node.body.accept2(this);

    flowAnalysis.flow?.doStatement_conditionBegin();
    analyzeExpression(condition, SharedTypeSchemaView(typeProvider.boolType));
    condition = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(condition),
    );
    boolExpressionVerifier.checkForNonBoolCondition(
      condition,
      whyNotPromoted: whyNotPromoted,
    );

    flowAnalysis.flow?.doStatement_end(
      flowAnalysis.getExpressionInfo(condition),
    );
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    covariant DotShorthandConstructorInvocationImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    constructorInvocationResolver.resolveDotShorthand(
      node,
      contextType: contextType,
    );

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitDotShorthandInvocation(
    covariant DotShorthandInvocationImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);
    var whyNotPromotedArguments =
        <Map<SharedTypeView, NonPromotionReason> Function()>[];

    node.typeArguments?.accept2(this);
    var rewrittenExpression = elementResolver.visitDotShorthandInvocation(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );

    // TODO(paulberry): why don't we do this for
    // DotShorthandConstructorInvocationImpl?
    if (rewrittenExpression is FunctionExpressionInvocationImpl ||
        rewrittenExpression == null) {
      var replacement = insertGenericFunctionInstantiation(
        node,
        contextType: contextType,
      );
      checkForArgumentTypesNotAssignableInList(
        node.argumentList,
        whyNotPromotedArguments,
      );
      _insertImplicitCallReference(replacement, contextType: contextType);
    }

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitDotShorthandPropertyAccess(
    covariant DotShorthandPropertyAccessImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);
    var result = _propertyElementResolver.resolveDotShorthand(
      node,
      contextType: contextType,
    );
    _resolvePropertyAccessRhs_common(
      result,
      node,
      node.propertyName,
      contextType,
    );

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitDottedName(DottedName node) {}

  @override
  void visitDoubleLiteral(
    DoubleLiteral node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitDoubleLiteral(node as DoubleLiteralImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {}

  @override
  void visitEmptyEnumBody(EmptyEnumBody node) {}

  @override
  TypeImpl visitEmptyFunctionBody(
    EmptyFunctionBody node, {
    TypeImpl? imposedType,
  }) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    return imposedType ?? typeProvider.dynamicType;
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitEnumConstantDeclaration(
    covariant EnumConstantDeclarationImpl node,
  ) {
    node.documentationComment?.accept2(this);
    node.metadata.accept2(this);
    checkUnreachableNode(node);

    var fragment = node.declaredFragment!;
    var initializer = fragment.constantInitializer2;
    if (initializer is ConstructorInvocationImpl) {
      var constructorName = initializer.constructorReference;
      var constructorElement = constructorName.element;
      if (constructorElement != null) {
        node.constructorElement = constructorElement;
        if (constructorElement.isFactory) {
          var constructorName = node.arguments?.constructorSelector?.name2;
          var errorTarget = constructorName ?? node.name;
          diagnosticReporter.report(
            diag.enumConstantInvokesFactoryConstructor.at(errorTarget),
          );
        }
      } else {
        if (constructorName.typeReference.element is EnumElementImpl) {
          var nameToken = node.arguments?.constructorSelector?.name2;
          if (nameToken != null) {
            diagnosticReporter.report(
              diag.undefinedEnumConstructorNamed
                  .withArguments(name: nameToken.lexeme)
                  .at(nameToken),
            );
          } else {
            diagnosticReporter.report(
              diag.undefinedEnumConstructorUnnamed.at(node.name),
            );
          }
        }
      }
      if (constructorElement != null) {
        var arguments = node.arguments;
        if (arguments != null) {
          var argumentList = arguments.argumentList;
          argumentList.correspondingStaticParameters =
              ResolverVisitor.resolveArgumentsToParameters(
                argumentList: argumentList,
                formalParameters: constructorElement.formalParameters,
                diagnosticReporter: diagnosticReporter,
              );
        } else if (definingLibrary.featureSet.isEnabled(
          Feature.enhanced_enums,
        )) {
          var requiredParameterCount = constructorElement.formalParameters
              .where((e) => e.isRequiredPositional)
              .length;
          if (requiredParameterCount != 0) {
            _reportNotEnoughPositionalArguments(
              token: node.name,
              requiredParameterCount: requiredParameterCount,
              actualArgumentCount: 0,
              nameNode: node,
              diagnosticReporter: diagnosticReporter,
            );
          }
        }
      }
    }

    var arguments = node.arguments;
    if (arguments != null) {
      var argumentList = arguments.argumentList;
      flowAnalysis.withFlowAnalysis(
        node: node,
        formalParameters: null,
        operation: () {
          for (var argument in argumentList.arguments2) {
            analyzeExpression(
              argument.argumentExpression2,
              SharedTypeSchemaView(
                argument.correspondingParameter?.type ??
                    UnknownInferredType.instance,
              ),
            );
            popRewrite();
          }
        },
      );

      arguments.typeArguments?.accept2(this);

      var whyNotPromotedArguments =
          <Map<SharedTypeView, NonPromotionReason> Function()>[];
      checkForArgumentTypesNotAssignableInList(
        argumentList,
        whyNotPromotedArguments,
      );
    }

    elementResolver.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    //
    // Continue the enum resolution.
    //
    _withEnclosingInstanceElement(node.declaredFragment!.element, () {
      checkUnreachableNode(node);
      node.visitChildren2(this);
      elementResolver.visitEnumDeclaration(node);
    });
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitExportDirective(node);
  }

  @override
  TypeImpl visitExpressionFunctionBody(
    covariant ExpressionFunctionBodyImpl node, {
    TypeImpl? imposedType,
  }) {
    var oldBodyContext = _bodyContext;
    try {
      var bodyContext = _bodyContext = BodyInferenceContext(
        typeSystem: typeSystem,
        node: node,
        imposedType: imposedType,
      );

      checkUnreachableNode(node);
      analyzeExpression(
        node.expression2,
        SharedTypeSchemaView(
          bodyContext.contextType ?? UnknownInferredType.instance,
        ),
      );
      popRewrite();

      flowAnalysis.flow?.handleReturn();

      bodyContext.addReturnExpression(node.expression2);
      return _finishFunctionBodyInference();
    } finally {
      _bodyContext = oldBodyContext;
    }
  }

  @override
  void visitExpressionStatement(covariant ExpressionStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    analyzeExpression(node.expression2, operations.unknownType);
    popRewrite();
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    _withEnclosingInstanceElement(node.declaredFragment!.element, () {
      checkUnreachableNode(node);
      node.visitChildren2(this);
      elementResolver.visitExtensionDeclaration(node);
    });
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitExtensionOverride(
    covariant ExtensionOverrideImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExtensionOverride(node, contextType);
    var whyNotPromotedArguments =
        <Map<SharedTypeView, NonPromotionReason> Function()>[];
    node.typeArguments?.accept2(this);

    var receiverContextType = ExtensionMemberResolver(
      this,
    ).computeOverrideReceiverContextType(node);
    InvocationTargetExtensionOverride? target;
    if (receiverContextType != null) {
      target = InvocationTargetExtensionOverride(
        element: node.element,
        type: FunctionTypeImpl(
          typeParameters: const [],
          formalParameters: [
            FormalParameterElementImpl.synthetic(
              null,
              receiverContextType,
              ParameterKind.REQUIRED,
            ),
          ],
          returnType: DynamicTypeImpl.instance,
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
    }
    InvocationInferrer<ExtensionOverrideImpl>(
      resolver: this,
      node: node,
      argumentList: node.argumentList,
      contextType: UnknownInferredType.instance,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: target,
    ).resolveInvocation();

    extensionResolver.resolveOverride(node, whyNotPromotedArguments);
    inferenceLogWriter?.exitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    _withEnclosingInstanceElement(node.declaredFragment!.element, () {
      checkUnreachableNode(node);
      node.visitChildren2(this);
      elementResolver.visitExtensionTypeDeclaration(node);
    });
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _withUnpromotedThisType(enclosingInstanceElement?.thisType, () {
      checkUnreachableNode(node);
      node.visitChildren2(this);
      elementResolver.visitFieldDeclaration(node);
    });
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _visitFormalParameter(node as FormalParameterImpl);
    elementResolver.visitFieldFormalParameter(node);
  }

  @override
  void visitForElement(
    covariant ForElementImpl node, {
    CollectionLiteralContext? context,
  }) {
    inferenceLogWriter?.enterElement(node);
    _forResolver.resolveElement(node, context);
    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitFormalParameterList(covariant FormalParameterListImpl node) {
    // Formal parameter lists can contain default values, which in turn contain
    // expressions, so we need flow analysis to be available to process those
    // expressions.
    flowAnalysis.withFlowAnalysis(
      node: node,
      formalParameters: null,
      operation: () {
        checkUnreachableNode(node);
        node.visitChildren2(this);
      },
    );
  }

  @override
  void visitForStatement(ForStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    _forResolver.resolveStatement(node as ForStatementImpl);
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    bool isLocal = node.parent2 is FunctionDeclarationStatement;
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    var functionType = element.type;

    _withEnclosingExecutableElement(element, () {
      checkUnreachableNode(node);
      node.documentationComment?.accept2(this);
      node.metadata.accept2(this);
      node.returnType?.accept2(this);

      if (isLocal) {
        flowAnalysis.flow!.functionExpression_begin(node);
      } else {
        flowAnalysis.bodyOrInitializer_enter(node, element.formalParameters);
      }
      flowAnalysis.executableDeclaration_enter(
        node,
        element.formalParameters,
        isClosure: isLocal,
      );

      analyzeExpression(
        node.functionExpression,
        SharedTypeSchemaView(functionType),
      );
      popRewrite();
      elementResolver.visitFunctionDeclaration(node);

      if (!node.isSetter) {
        checkForBodyMayCompleteNormally(
          body: node.functionExpression.body,
          errorNode: node.name,
        );
      }
      flowAnalysis.executableDeclaration_exit(
        node.functionExpression.body,
        isLocal,
      );
      if (isLocal) {
        flowAnalysis.flow!.functionExpression_end();
      } else {
        flowAnalysis.bodyOrInitializer_exit();
      }
      nullSafetyDeadCodeVerifier.flowEnd(node);
    });
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitFunctionExpression(
    covariant FunctionExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    _withEnclosingExecutableElement(node.declaredFragment!.element, () {
      _functionExpressionResolver.resolve(node, contextType: contextType);
      insertGenericFunctionInstantiation(node, contextType: contextType);
    });
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(
    covariant FunctionExpressionInvocationImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    analyzeExpression(
      node.function2,
      SharedTypeSchemaView(UnknownInferredType.instance),
      continueNullShorting: true,
    );
    node.function2 = popRewrite()!;

    var whyNotPromotedArguments =
        <Map<SharedTypeView, NonPromotionReason> Function()>[];
    functionExpressionInvocationResolver.resolve(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
    );
    var replacement = insertGenericFunctionInstantiation(
      node,
      contextType: contextType,
    );
    checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
    _insertImplicitCallReference(replacement, contextType: contextType);

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitFunctionReference(
    covariant FunctionReferenceImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    _functionReferenceResolver.resolve(node);

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {}

  @override
  void visitIfElement(
    covariant IfElementImpl node, {
    CollectionLiteralContext? context,
  }) {
    inferenceLogWriter?.enterElement(node);
    var caseClause = node.caseClause;
    if (caseClause != null) {
      var guardedPattern = caseClause.guardedPattern;
      analyzeIfCaseElement(
        node: node,
        expression: node.expression2,
        pattern: guardedPattern.pattern,
        variables: guardedPattern.variables,
        guard: guardedPattern.whenClause?.expression2,
        ifTrue: node.thenElement2,
        ifFalse: node.elseElement2,
        context: context,
      );
      // Stack: (Expression, Guard)
      popRewrite(); // guard
      popRewrite()!; // expression
    } else {
      analyzeIfElement(
        node: node,
        condition: node.expression2,
        ifTrue: node.thenElement2,
        ifFalse: node.elseElement2,
        context: context,
      );
    }
    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitIfStatement(covariant IfStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);

    var caseClause = node.caseClause;
    if (caseClause != null) {
      var guardedPattern = caseClause.guardedPattern;
      analyzeIfCaseStatement(
        node,
        node.expression2,
        guardedPattern.pattern,
        guardedPattern.whenClause?.expression2,
        node.thenStatement,
        node.elseStatement,
        guardedPattern.variables,
      );
      // Stack: (Expression, Guard)
      popRewrite(); // guard
      popRewrite()!; // expression
    } else {
      analyzeIfStatement(
        node,
        node.expression2,
        node.thenStatement,
        node.elseStatement,
      );
    }
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitImplicitCallReference(
    covariant ImplicitCallReferenceImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    checkUnreachableNode(node);
    analyzeExpression(
      node.expression2,
      SharedTypeSchemaView(UnknownInferredType.instance),
    );
    popRewrite();
    node.typeArguments?.accept2(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitImportDirective(node as ImportDirectiveImpl);
  }

  @override
  void visitIndexExpression(
    covariant IndexExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);

    var target = node.target2;
    if (target != null) {
      analyzeExpression(
        target,
        SharedTypeSchemaView(UnknownInferredType.instance),
        continueNullShorting: true,
      );
      popRewrite();
    }
    var targetType = node.realTarget.staticType;

    if (node.isNullAware) {
      _startNullAwareAccess(node.target2);
      nullSafetyDeadCodeVerifier.visitNode(node.index2);
    }

    var result = _propertyElementResolver.resolveIndexExpression(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement2;
    node.element = element as MethodElement?;

    analyzeExpression(
      node.index2,
      SharedTypeSchemaView(result.indexContextType),
    );
    popRewrite();
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(node.index2),
    );
    checkIndexExpressionIndex(
      node.index2,
      readElement: result.readElement2 as InternalExecutableElement?,
      writeElement: null,
      whyNotPromoted: whyNotPromoted,
    );

    DartType type;
    if (identical(targetType, NeverTypeImpl.instance)) {
      type = NeverTypeImpl.instance;
    } else if (element is MethodElement) {
      type = element.returnType;
    } else if (targetType is DynamicType) {
      type = DynamicTypeImpl.instance;
    } else {
      type = InvalidTypeImpl.instance;
    }
    node.recordStaticType(type, resolver: this);
    var replacement = insertGenericFunctionInstantiation(
      node,
      contextType: contextType,
    );

    _insertImplicitCallReference(replacement, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyIndexExpression(node);

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitIntegerLiteral(
    IntegerLiteral node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitIntegerLiteral(
      node as IntegerLiteralImpl,
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitInterpolationExpression(
    covariant InterpolationExpressionImpl node,
  ) {
    checkUnreachableNode(node);
    analyzeExpression(node.expression2, operations.unknownType);
    popRewrite();
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitIsExpression(
    covariant IsExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);

    analyzeExpression(
      node.expression2,
      SharedTypeSchemaView(UnknownInferredType.instance),
    );
    popRewrite();

    checkUnreachableNode(node.type);
    node.type.accept2(this);

    typeAnalyzer.visitIsExpression(node);
    flowAnalysis.isExpression(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitLabel(Label node) {}

  @override
  void visitLabeledStatement(covariant LabeledStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    flowAnalysis.labeledStatement_enter(node);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    flowAnalysis.labeledStatement_exit(node);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(
    covariant ListLiteralImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveListLiteral(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitMapLiteralEntry(
    covariant MapLiteralEntryImpl node, {
    CollectionLiteralContext? context,
  }) {
    inferenceLogWriter?.enterElement(node);
    checkUnreachableNode(node);

    // If the key is null-aware, the context of the expression under `?` should
    // be changed to the nullable version of the downwards context.
    var keyTypeContext = context?.keyType;
    if (keyTypeContext != null && node.keyQuestion != null) {
      keyTypeContext = typeSystem.makeNullable(keyTypeContext);
    }
    var keyType = analyzeExpression(
      node.key2,
      SharedTypeSchemaView(keyTypeContext ?? UnknownInferredType.instance),
    ).type;
    popRewrite();

    flowAnalysis.flow?.nullAwareMapEntry_valueBegin(
      flowAnalysis.getExpressionInfo(node.key2),
      keyType,
      isKeyNullAware: node.keyQuestion != null,
    );

    // If the value is null-aware, the context of the expression under `?`
    // should be changed to the nullable version of the downwards context.
    var valueTypeContext = context?.valueType;
    if (valueTypeContext != null && node.valueQuestion != null) {
      valueTypeContext = typeSystem.makeNullable(valueTypeContext);
    }
    analyzeExpression(
      node.value2,
      SharedTypeSchemaView(valueTypeContext ?? UnknownInferredType.instance),
    );
    popRewrite();

    flowAnalysis.flow?.nullAwareMapEntry_end(
      isKeyNullAware: node.keyQuestion != null,
    );
    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    var returnType = element.returnType;

    _withEnclosingExecutableElement(element, () {
      _withUnpromotedThisType(enclosingInstanceElement?.thisType, () {
        checkUnreachableNode(node);
        node.documentationComment?.accept2(this);
        node.metadata.accept2(this);
        node.returnType?.accept2(this);
        node.typeParameters?.accept2(this);
        node.parameters?.accept2(this);

        flowAnalysis.bodyOrInitializer_enter(node, element.formalParameters);
        flowAnalysis.executableDeclaration_enter(
          node,
          element.formalParameters,
          isClosure: false,
        );

        node.body.resolve(this, returnType is DynamicType ? null : returnType);
        elementResolver.visitMethodDeclaration(node);

        if (!node.isSetter) {
          checkForBodyMayCompleteNormally(
            body: node.body,
            errorNode: node.name,
          );
        }
        flowAnalysis.executableDeclaration_exit(node.body, false);
        flowAnalysis.bodyOrInitializer_exit();
        nullSafetyDeadCodeVerifier.flowEnd(node);
      });
    });
  }

  @override
  void visitMethodInvocation(
    covariant MethodInvocationImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);
    var whyNotPromotedArguments =
        <Map<SharedTypeView, NonPromotionReason> Function()>[];
    var target = node.target2;
    if (target != null) {
      analyzeExpression(
        target,
        operations.unknownType,
        continueNullShorting: true,
      );
      target = popRewrite();
    }

    if (node.isNullAware) {
      _startNullAwareAccess(target);
      nullSafetyDeadCodeVerifier.visitNode(node.methodName);
    }

    node.typeArguments?.accept2(this);
    elementResolver.visitMethodInvocation(
      node,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
    );

    var replacement = insertGenericFunctionInstantiation(
      node,
      contextType: contextType,
    );
    checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
    _insertImplicitCallReference(replacement, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyMethodInvocation(node);

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var declaredFragment = node.declaredFragment!;
    var declaredElement = declaredFragment.element;

    //
    // Continue the class resolution.
    //
    _withEnclosingInstanceElement(node.declaredFragment!.element, () {
      checkUnreachableNode(node);
      node.visitChildren2(this);
      elementResolver.visitMixinDeclaration(node);
    });

    baseOrFinalTypeVerifier.checkElement(
      declaredElement,
      node.implementsClause,
    );
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitNamedArgument(
    covariant NamedArgumentImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    checkUnreachableNode(node);
    analyzeExpression(
      node.argumentExpression2,
      SharedTypeSchemaView(contextType),
    );
    popRewrite();
  }

  @override
  void visitNamedType(NamedType node) {
    // All TypeName(s) are already resolved, so we don't resolve it here.
    // But there might be type arguments with Expression(s), such as default
    // values for formal parameters of GenericFunctionType(s). These are
    // invalid, but if they exist, they should be resolved.
    node.typeArguments?.accept2(this);
  }

  @override
  void visitNameWithTypeParameters(NameWithTypeParameters node) {
    node.visitChildren2(this);
  }

  @override
  void visitNativeClause(NativeClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  TypeImpl visitNativeFunctionBody(
    covariant NativeFunctionBodyImpl node, {
    TypeImpl? imposedType,
  }) {
    checkUnreachableNode(node);
    if (node.stringLiteral case var stringLiteral?) {
      analyzeExpression(stringLiteral, operations.unknownType);
      popRewrite();
    }
    return imposedType ?? typeProvider.dynamicType;
  }

  @override
  void visitNullAwareElement(
    covariant NullAwareElementImpl node, {
    CollectionLiteralContext? context,
  }) {
    inferenceLogWriter?.enterElement(node);

    var elementType = context?.elementType;
    if (elementType != null) {
      elementType = typeSystem.makeNullable(elementType);
    }

    analyzeExpression(
      node.value2,
      SharedTypeSchemaView(elementType ?? UnknownInferredType.instance),
    );
    popRewrite();

    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitNullLiteral(
    NullLiteral node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    node.visitChildren2(this);
    typeAnalyzer.visitNullLiteral(node as NullLiteralImpl);
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.flow?.nullLiteral(SharedTypeView(node.typeOrThrow)),
    );
    checkUnreachableNode(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitParenthesizedExpression(
    covariant ParenthesizedExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(node.expression2, SharedTypeSchemaView(contextType));
    popRewrite();
    typeAnalyzer.visitParenthesizedExpression(node);
    flowAnalysis.storeExpressionInfo(
      node,
      flowAnalysis.flow?.parenthesizedExpression(
        flowAnalysis.getExpressionInfo(node.expression2),
      ),
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitPartOfDirective(node);
  }

  @override
  void visitPatternAssignment(
    covariant PatternAssignmentImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var analysisResult = analyzePatternAssignment(
      node,
      node.pattern,
      node.expression2,
    );
    node.patternTypeSchema = analysisResult.patternSchema
        .unwrapTypeSchemaView();
    node.recordStaticType(
      // TODO(paulberry): make this type argument unnecessary by changing the
      // parameter of `ExpressionImpl.recordStaticType` to `TypeImpl`.
      analysisResult.type.unwrapTypeView<TypeImpl>(),
      resolver: this,
    );
    popRewrite(); // expression
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    node.metadata.accept2(this);
    var patternSchema = analyzePatternVariableDeclaration(
      node,
      node.pattern,
      node.expression2,
      isFinal: node.keyword.keyword == Keyword.FINAL,
    ).patternSchema;
    node.patternTypeSchema = patternSchema.unwrapTypeSchemaView();
    popRewrite(); // expression
  }

  @override
  void visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.declaration.accept2(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitPostfixExpression(
    covariant PostfixExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);
    _postfixExpressionResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPrefixedIdentifier(
    covariant PrefixedIdentifierImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var rewrittenPropertyAccess = _prefixedIdentifierResolver.resolve(
      node,
      contextType: contextType,
    );
    if (rewrittenPropertyAccess != null) {
      _resolvePropertyAccessRhs(
        rewrittenPropertyAccess,
        contextType,
        originalNode: node,
      );
      // We did record that `node` was replaced with `rewrittenPropertyAccess`.
      // But if `rewrittenPropertyAccess` was itself rewritten, replace the
      // rewrite result of `node`.
      assert(() {
        var rewrite = _replacements[rewrittenPropertyAccess];
        if (rewrite != null) {
          _replacements[node] = rewrite;
        }
        return true;
      }());
      inferenceLogWriter?.exitExpression(node);
      return;
    }
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPrefixExpression(
    PrefixExpression node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _prefixExpressionResolver.resolve(
      node as PrefixExpressionImpl,
      contextType: contextType,
    );
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPrimaryConstructorBody(covariant PrimaryConstructorBodyImpl node) {
    var primaryConstructorDeclaration = node.declaration;
    if (primaryConstructorDeclaration == null) {
      diagnosticReporter.report(
        diag.primaryConstructorBodyWithoutDeclaration.at(node.thisKeyword),
      );
    }

    var fragment = primaryConstructorDeclaration?.declaredFragment;
    var element = fragment?.element;

    var returnType = element?.type.returnType;

    _withEnclosingExecutableElement(element, () {
      _withUnpromotedThisType(enclosingInstanceElement?.thisType, () {
        checkUnreachableNode(node);
        node.documentationComment?.accept2(this);
        node.metadata.accept2(this);

        if (primaryConstructorDeclaration != null) {
          flowAnalysis.bodyOrInitializer_enter(node, element!.formalParameters);
          flowAnalysis.executableDeclaration_enter(
            node,
            element.formalParameters,
            isClosure: false,
          );
        }

        node.initializers.accept2(this);
        node.body.resolve(this, returnType is DynamicType ? null : returnType);

        if (primaryConstructorDeclaration != null) {
          flowAnalysis.executableDeclaration_exit(node.body, false);
          flowAnalysis.bodyOrInitializer_exit();
        }
        nullSafetyDeadCodeVerifier.flowEnd(node);
      });
    });
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    node.visitChildren2(this);
  }

  @override
  void visitPrimaryConstructorName(PrimaryConstructorName node) {
    node.visitChildren2(this);
  }

  @override
  void visitPropertyAccess(
    covariant PropertyAccessImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);

    // If [isDotShorthand] is set, cache the context type for resolution.
    if (isDotShorthand(node)) {
      pushDotShorthandContext(node, SharedTypeSchemaView(contextType));
    }

    checkUnreachableNode(node);

    var target = node.target2;
    if (target != null) {
      analyzeExpression(
        target,
        SharedTypeSchemaView(UnknownInferredType.instance),
        continueNullShorting: true,
      );
      popRewrite();
    }

    checkUnreachableNode(node.propertyName);
    _resolvePropertyAccessRhs(node, contextType);

    if (isDotShorthand(node)) {
      popDotShorthandContext();
    }

    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitRecordLiteral(
    covariant RecordLiteralImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _recordLiteralResolver.resolve(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    // All RecordTypeAnnotation(s) are already resolved, so we don't resolve
    // it here. But there might be types with Expression(s), such as default
    // values for formal parameters of GenericFunctionType(s). These are
    // invalid, but if they exist, they should be resolved.
    node.visitChildren2(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.visitChildren2(this);
    elementResolver.visitRecordTypeAnnotationNamedField(node);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.visitChildren2(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.visitChildren2(this);
    elementResolver.visitRecordTypeAnnotationPositionalField(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    var whyNotPromotedArguments =
        <Map<SharedTypeView, NonPromotionReason> Function()>[];
    elementResolver.visitRedirectingConstructorInvocation(
      node as RedirectingConstructorInvocationImpl,
    );
    var element = node.element;
    InvocationInferrer<RedirectingConstructorInvocationImpl>(
      resolver: this,
      node: node,
      argumentList: node.argumentList,
      contextType: UnknownInferredType.instance,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: element == null
          ? null
          : InvocationTargetConstructorElement(element, element.type),
    ).resolveInvocation();
    checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }

  @override
  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    _visitFormalParameter(node as FormalParameterImpl);
    elementResolver.visitRegularFormalParameter(node);
  }

  @override
  void visitRethrowExpression(
    RethrowExpression node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitRethrowExpression(node as RethrowExpressionImpl);
    flowAnalysis.flow?.handleExit();
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitReturnStatement(covariant ReturnStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    var expression = node.expression2;
    if (expression != null) {
      analyzeExpression(
        expression,
        SharedTypeSchemaView(
          bodyContext?.contextType ?? UnknownInferredType.instance,
        ),
      );
      // Pick up the expression again in case it was rewritten.
      expression = popRewrite();
    }

    bodyContext?.addReturnExpression(expression);
    flowAnalysis.flow?.handleReturn();
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitSetOrMapLiteral(
    SetOrMapLiteral node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveSetOrMapLiteral(
      node,
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleIdentifier(
    covariant SimpleIdentifierImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    _simpleIdentifierResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(
      insertGenericFunctionInstantiation(node, contextType: contextType),
      contextType: contextType,
    );
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSimpleStringLiteral(
    SimpleStringLiteral node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitSimpleStringLiteral(node as SimpleStringLiteralImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSpreadElement(
    covariant SpreadElementImpl node, {
    CollectionLiteralContext? context,
  }) {
    inferenceLogWriter?.enterElement(node);
    var iterableType = context?.iterableType;
    if (iterableType != null && node.isNullAware) {
      iterableType = typeSystem.makeNullable(iterableType);
    }
    checkUnreachableNode(node);
    analyzeExpression(
      node.expression2,
      SharedTypeSchemaView(iterableType ?? UnknownInferredType.instance),
    );
    popRewrite();

    if (!node.isNullAware) {
      nullableDereferenceVerifier.expression(
        diag.uncheckedUseOfNullableValueInSpread,
        node.expression2,
      );
    }

    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitStringInterpolation(
    StringInterpolation node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitStringInterpolation(node as StringInterpolationImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    var whyNotPromotedArguments =
        <Map<SharedTypeView, NonPromotionReason> Function()>[];
    elementResolver.visitSuperConstructorInvocation(
      node as SuperConstructorInvocationImpl,
    );
    var element = node.element;
    InvocationInferrer<SuperConstructorInvocationImpl>(
      resolver: this,
      node: node,
      argumentList: node.argumentList,
      contextType: UnknownInferredType.instance,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: element == null
          ? null
          : InvocationTargetConstructorElement(element, element.type),
    ).resolveInvocation();
    checkForArgumentTypesNotAssignableInList(
      node.argumentList,
      whyNotPromotedArguments,
    );
  }

  @override
  void visitSuperExpression(
    SuperExpression node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitSuperExpression(node);
    typeAnalyzer.visitSuperExpression(node as SuperExpressionImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _visitFormalParameter(node as FormalParameterImpl);
  }

  @override
  void visitSwitchExpression(
    covariant SwitchExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    var previousExhaustiveness = legacySwitchExhaustiveness;
    var staticType = analyzeSwitchExpression(
      node,
      node.expression2,
      node.cases.length,
      SharedTypeSchemaView(contextType),
    ).type.unwrapTypeView<TypeImpl>();
    node.recordStaticType(staticType, resolver: this);
    popRewrite();
    legacySwitchExhaustiveness = previousExhaustiveness;
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    // Stack: ()
    checkUnreachableNode(node);

    var previousExhaustiveness = legacySwitchExhaustiveness;
    analyzeSwitchStatement(node, node.expression2, node.memberGroups.length);
    // Stack: (Expression)
    popRewrite();
    // Stack: ()
    legacySwitchExhaustiveness = previousExhaustiveness;
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitSymbolLiteral(
    SymbolLiteral node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitSymbolLiteral(node as SymbolLiteralImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitThisExpression(
    ThisExpression node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    typeAnalyzer.visitThisExpression(node as ThisExpressionImpl);
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitThrowExpression(
    covariant ThrowExpressionImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(
      node.expression2,
      SharedTypeSchemaView(typeProvider.objectType),
    );
    popRewrite();
    typeAnalyzer.visitThrowExpression(node);
    flowAnalysis.flow?.handleExit();
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(covariant TryStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    var flow = flowAnalysis.flow!;

    var body = node.body;
    var catchClauses = node.catchClauses;
    var finallyBlock = node.finallyBlock;

    if (finallyBlock != null) {
      flow.tryFinallyStatement_bodyBegin();
    }

    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyBegin();
    }
    body.accept2(this);
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    nullSafetyDeadCodeVerifier.tryStatementEnter(node);
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);

      var catchLength = catchClauses.length;
      for (var i = 0; i < catchLength; ++i) {
        var catchClause = catchClauses[i];
        nullSafetyDeadCodeVerifier.verifyCatchClause(catchClause);
        // TODO(paulberry): try to remove these casts by changing `node` to a
        // `TryStatementImpl`
        flow.tryCatchStatement_catchBegin(
          catchClause.exceptionParameter?.declaredFragment?.element
              as PromotableElementImpl?,
          catchClause.stackTraceParameter?.declaredFragment?.element
              as PromotableElementImpl?,
        );
        catchClause.accept2(this);
        flow.tryCatchStatement_catchEnd();
        nullSafetyDeadCodeVerifier.flowEnd(catchClause.body);
      }

      flow.tryCatchStatement_end();
    }
    nullSafetyDeadCodeVerifier.tryStatementExit(node);

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
        catchClauses.isNotEmpty ? node : body,
      );
      finallyBlock.accept2(this);
      flow.tryFinallyStatement_end();
    }
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitTypeLiteral(
    covariant TypeLiteralImpl node, {
    TypeImpl contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    node.recordStaticType(typeProvider.typeType, resolver: this);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    libraryResolutionContext._variableNodes[fragment] = node;
    _variableDeclarationResolver.resolve(node);

    var initializer = node.initializer2;
    if (initializer != null) {
      var parent = node.parent2 as VariableDeclarationList;
      var declaredType = parent.type;
      var initializerStaticType = initializer.typeOrThrow;
      flowAnalysis.flow?.initialize(
        node.declaredFragment?.element as PromotableElementImpl,
        SharedTypeView(initializerStaticType),
        flowAnalysis.getExpressionInfo(initializer),
        isFinal: parent.isFinal,
        isLate: parent.isLate,
        isImplicitlyTyped: declaredType == null,
      );
    }

    _checkTopLevelCycle(node);
  }

  @override
  void visitVariableDeclarationList(
    covariant VariableDeclarationListImpl node,
  ) {
    flowAnalysis.variableDeclarationList(node);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    elementResolver.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren2(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitWhileStatement(covariant WhileStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);

    ExpressionImpl condition = node.condition2;

    flowAnalysis.flow?.whileStatement_conditionBegin(node);
    analyzeExpression(condition, SharedTypeSchemaView(typeProvider.boolType));
    condition = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(
      flowAnalysis.getExpressionInfo(condition),
    );

    boolExpressionVerifier.checkForNonBoolCondition(
      node.condition2,
      whyNotPromoted: whyNotPromoted,
    );

    flowAnalysis.flow?.whileStatement_bodyBegin(
      node,
      flowAnalysis.getExpressionInfo(condition),
    );
    node.body.accept2(this);
    flowAnalysis.flow?.whileStatement_end();
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    // TODO(brianwilkerson): If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    checkUnreachableNode(node);
    node.visitChildren2(this);
  }

  @override
  void visitYieldStatement(covariant YieldStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    _yieldStatementResolver.resolve(node);
    inferenceLogWriter?.exitStatement(node);
  }

  /// Check whether [errorNode] is an `onError` callback in a
  /// [Future.catchError] call, which might return an implicit `null`.
  void _checkForFutureCatchErrorOnError(BlockFunctionBody errorNode) {
    // Check for "body  might complete normally" in a `Future.catchError`'s
    //`onError` callback.
    var parent = errorNode.parent2?.parent2;
    if (parent is! ArgumentList) {
      return;
    }
    var invocation = parent.parent2;
    if (invocation is! MethodInvocation) {
      return;
    }
    var targetType = invocation.realTarget?.staticType;
    if (invocation.methodName.name == 'catchError' &&
        targetType is InterfaceTypeImpl) {
      var instanceOfFuture = targetType.asInstanceOf(
        typeProvider.futureElement,
      );
      if (instanceOfFuture != null) {
        var targetFutureType = instanceOfFuture.typeArguments.first;
        var expectedReturnType = typeProvider.futureOrType(targetFutureType);
        var returnTypeBase = typeSystem.futureOrBase(expectedReturnType);
        if (returnTypeBase is DynamicType ||
            returnTypeBase is UnknownInferredType ||
            returnTypeBase is VoidType ||
            returnTypeBase.isDartCoreNull) {
          return;
        }

        diagnosticReporter.report(
          diag.bodyMightCompleteNormallyCatchError
              .withArguments(type: returnTypeBase)
              .at(errorNode.block.leftBracket),
        );
      }
    }
  }

  void _checkTopLevelCycle(VariableDeclaration node) {
    var fragment = node.declaredFragment;
    if (fragment is! PropertyInducingFragmentImpl) {
      return;
    }
    // Errors on const are reported separately with
    // [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT].
    if (fragment.isConst) {
      return;
    }
    var error = fragment.element.typeInferenceError;
    if (error == null) {
      return;
    }
    if (error is TopLevelInferenceErrorDependencyCycle) {
      diagnosticReporter.report(
        diag.topLevelCycle
            .withArguments(
              name: node.name.lexeme,
              cycle: error.cycle.join(', '),
            )
            .at(node.name),
      );
    }
  }

  /// Helper function used to print information to the console in debug mode.
  /// This method returns `true` so that it can be conveniently called inside of
  /// an `assert` statement.
  bool _debugPrint(String s) {
    print(s);
    return true;
  }

  TypeImpl _finishFunctionBodyInference() {
    var flow = flowAnalysis.flow;

    return _bodyContext!.computeInferredReturnType(
      endOfBlockIsReachable: flow == null || flow.isReachable,
    );
  }

  /// Infers type arguments corresponding to [typeParameters] used it the
  /// [declaredType], so that thr resulting type is a subtype of [contextType].
  List<TypeImpl> _inferTypeArguments({
    required List<TypeParameterElementImpl> typeParameters,
    required AstNode errorNode,
    required TypeImpl declaredType,
    required TypeImpl contextType,
    required AstNodeImpl? nodeForTesting,
  }) {
    inferenceLogWriter?.enterGenericInference(typeParameters, declaredType);
    var inferrer = GenericInferrer(
      typeSystem,
      typeParameters,
      errorEntity: errorNode,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
      strictInference: analysisOptions.strictInference,
      typeSystemOperations: flowAnalysis.typeOperations,
      dataForTesting: inferenceHelper.dataForTesting,
    );
    inferrer.constrainReturnType(
      declaredType,
      contextType,
      nodeForTesting: nodeForTesting,
    );
    return inferrer.chooseFinalTypes();
  }

  /// If `expression` should be treated as `expression.call`, inserts an
  /// [ImplicitCallReference] node which wraps [expression].
  void _insertImplicitCallReference(
    ExpressionImpl expression, {
    required TypeImpl contextType,
  }) {
    var parent = expression.parent2;
    if (_shouldSkipImplicitCallReferenceDueToForm(expression, parent)) {
      return;
    }
    var staticType = expression.staticType;
    if (staticType == null) {
      return;
    }
    TypeImpl context;
    if (parent is AssignmentExpressionImpl) {
      if (parent.writeType == null) return;
      context = parent.writeType!;
    } else {
      context = contextType;
    }
    var callMethod = getImplicitCallMethod(staticType, context, expression);
    if (callMethod == null) {
      return;
    }

    // `expression` is to be treated as `expression.call`.
    context = typeSystem.flatten(context);
    var callMethodType = callMethod.type;
    List<DartType> typeArgumentTypes;
    if (isConstructorTearoffsEnabled &&
        callMethodType.typeParameters.isNotEmpty &&
        context is FunctionTypeImpl) {
      typeArgumentTypes = typeSystem.inferFunctionTypeInstantiation(
        context,
        callMethodType,
        diagnosticReporter: diagnosticReporter,
        errorNode: expression,
        // If the constructor-tearoffs feature is enabled, then so is
        // generic-metadata.
        genericMetadataIsEnabled: true,
        inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
        strictInference: analysisOptions.strictInference,
        strictCasts: analysisOptions.strictCasts,
        typeSystemOperations: flowAnalysis.typeOperations,
        dataForTesting: inferenceHelper.dataForTesting,
        nodeForTesting: expression,
      );
      if (typeArgumentTypes.isNotEmpty) {
        callMethodType = callMethodType.instantiate(typeArgumentTypes);
      }
    } else {
      typeArgumentTypes = [];
    }

    var callReference = ImplicitCallReferenceImpl(
      expression2: expression,
      element: callMethod,
      typeArguments: null,
      typeArgumentTypes: typeArgumentTypes,
    );
    replaceExpression(expression, callReference, parent: parent);

    callReference.setPseudoExpressionStaticType(callMethodType);
  }

  void _resolvePropertyAccessRhs(
    PropertyAccessImpl node,
    TypeImpl contextType, {
    PrefixedIdentifierImpl? originalNode,
  }) {
    if (node.isNullAware) {
      _startNullAwareAccess(node.target2);
      nullSafetyDeadCodeVerifier.visitNode(node.propertyName);
    }

    var result = _propertyElementResolver.resolvePropertyAccess(
      node: node,
      hasRead: true,
      hasWrite: false,
      originalNode: originalNode,
    );

    _resolvePropertyAccessRhs_common(
      result,
      node,
      node.propertyName,
      contextType,
    );
    nullSafetyDeadCodeVerifier.verifyPropertyAccess(node);
  }

  /// Common logic for resolving dot shorthands property accesses and
  /// [_resolvePropertyAccessRhs].
  void _resolvePropertyAccessRhs_common(
    PropertyElementResolverResult resolverResult,
    ExpressionImpl node,
    SimpleIdentifierImpl propertyName,
    TypeImpl contextType,
  ) {
    var element = resolverResult.readElement2;

    propertyName.element = element;

    DartType type;
    if (element is MethodElement) {
      type = element.type;
    } else if (element is InternalConstructorElement) {
      type = element.type;
    } else if (element is GetterElement) {
      type = resolverResult.getType!;
    } else if (resolverResult.functionTypeCallType != null) {
      type = resolverResult.functionTypeCallType!;
    } else if (resolverResult.recordField != null) {
      type = resolverResult.recordField!.type;
    } else if (resolverResult.atDynamicTarget) {
      type = DynamicTypeImpl.instance;
    } else {
      type = InvalidTypeImpl.instance;
    }

    if (!isConstructorTearoffsEnabled) {
      // Only perform a generic function instantiation on a [PrefixedIdentifier]
      // in pre-constructor-tearoffs code. In constructor-tearoffs-enabled code,
      // generic function instantiation is performed at assignability check
      // sites.
      // TODO(srawlins): Switch all resolution to use the latter method, in a
      // breaking change release.
      type = inferenceHelper.inferTearOff(
        node,
        propertyName,
        type,
        contextType: contextType,
      );
    }

    propertyName.setPseudoExpressionStaticType(type);
    node.recordStaticType(type, resolver: this);
    var replacement = insertGenericFunctionInstantiation(
      node,
      contextType: contextType,
    );

    _insertImplicitCallReference(replacement, contextType: contextType);
  }

  bool _shouldSkipImplicitCallReferenceDueToForm(
    Expression expression,
    AstNode? parent,
  ) {
    while (parent is ParenthesizedExpression) {
      expression = parent;
      parent = expression.parent2;
    }
    if (parent is CascadeExpression && parent.target2 == expression) {
      // Do not perform an "implicit tear-off conversion" here. It should only
      // be performed on [parent]. See
      // https://github.com/dart-lang/language/issues/1873.
      return true;
    }
    if (parent is ConditionalExpression &&
        (parent.thenExpression2 == expression ||
            parent.elseExpression2 == expression)) {
      // Do not perform an "implicit tear-off conversion" on the branches of a
      // conditional expression.
      return true;
    }
    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.QUESTION_QUESTION) {
      // Do not perform an "implicit tear-off conversion" on the branches of a
      // `??` operator.
      return true;
    }
    return false;
  }

  /// Starts null aware access on a given [target] expression.
  ///
  /// Note: there is no corresponding "stop" method. Null shorting will be
  /// automatically stopped by [TypeAnalyzer.analyzeExpression].
  void _startNullAwareAccess(ExpressionImpl? target) {
    var flow = flowAnalysis.flow;
    if (flow != null) {
      switch (target) {
        case null:
          // This means the property access target is the target of a cascade.
          // For this case, `node.isNullAware=true` means that the cascade is
          // null aware, but that has already been taken care of in
          // `visitCascadeExpression`. So there is nothing further to do.
          break;
        case SimpleIdentifier(element: InterfaceElement()):
          // `?.` to access static methods is equivalent to `.`, so do nothing.
          break;
        case ExtensionOverride(
          argumentList: ArgumentListImpl(
            arguments2: [ArgumentImpl(argumentExpression: var expression)],
          ),
        ):
        case var expression:
          flowAnalysis.storeExpressionInfo(
            expression,
            startNullShorting(
              null,
              flowAnalysis.getExpressionInfo(expression),
              SharedTypeView(expression.staticType ?? typeProvider.dynamicType),
            ),
          );
      }
    }
  }

  void _visitFormalParameter(FormalParameterImpl node) {
    var fragment = node.declaredFragment!;
    checkUnreachableNode(node);

    node.documentationComment?.accept2(this);
    node.metadata.accept2(this);
    node.type?.accept2(this);
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      functionTypedSuffix.typeParameters?.accept2(this);
      functionTypedSuffix.formalParameters.accept2(this);
    }

    if (node.defaultClause case var defaultClause?) {
      var defaultValue = defaultClause.value2;
      analyzeExpression(
        defaultValue,
        SharedTypeSchemaView(fragment.element.type),
      );
      defaultValue = popRewrite()!;

      if (node.isOfLocalFunction2) {
        fragment.constantInitializer2 = defaultValue;
      }
    }
  }

  void _withEnclosingExecutableElement(
    ExecutableElementImpl? element,
    void Function() operation,
  ) {
    var previous = enclosingExecutableElement;
    enclosingExecutableElement = element;
    try {
      operation();
    } finally {
      enclosingExecutableElement = previous;
    }
  }

  void _withEnclosingInstanceElement(
    InstanceElementImpl element,
    void Function() operation,
  ) {
    var previous = enclosingInstanceElement;
    enclosingInstanceElement = element;
    try {
      operation();
    } finally {
      enclosingInstanceElement = previous;
    }
  }

  T _withUnpromotedThisType<T>(TypeImpl? type, T Function() operation) {
    var previous = _unpromotedThisType;
    _unpromotedThisType = type;
    try {
      return operation();
    } finally {
      _unpromotedThisType = previous;
    }
  }

  /// Given an [argumentList] and the [formalParameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments.
  ///
  /// Returns the parameters that correspond to the arguments. If no parameter
  /// matched an argument, that position will be `null` in the list.
  static List<InternalFormalParameterElement?> resolveArgumentsToParameters({
    required ArgumentList argumentList,
    required List<FormalParameterElement> formalParameters,
    DiagnosticReporter? diagnosticReporter,
    FormalParameterList? enclosingConstructorFormalParameterList,
  }) {
    int requiredParameterCount = 0;
    int unnamedParameterCount = 0;
    var unnamedParameters = <InternalFormalParameterElement>[];
    Map<String, InternalFormalParameterElement>? namedParameters;
    int length = formalParameters.length;
    for (int i = 0; i < length; i++) {
      var parameter = formalParameters[i] as InternalFormalParameterElement;
      if (parameter.isRequiredPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
        requiredParameterCount++;
      } else if (parameter.isOptionalPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
      } else {
        namedParameters ??= {};
        namedParameters[parameter.name ?? ''] = parameter;
      }
    }
    int unnamedIndex = 0;
    NodeList<Argument> arguments = argumentList.arguments2;
    int argumentCount = arguments.length;
    var resolvedParameters = List<InternalFormalParameterElement?>.filled(
      argumentCount,
      null,
    );
    int positionalArgumentCount = 0;
    bool noBlankArguments = true;
    Expression? firstUnresolvedArgument;
    Expression? lastPositionalArgument;
    for (int i = 0; i < argumentCount; i++) {
      Argument argument = arguments[i];
      if (argument is! NamedArgument) {
        if (argument is SimpleIdentifier && argument.name.isEmpty) {
          noBlankArguments = false;
        }
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        } else {
          firstUnresolvedArgument ??= argument.argumentExpression2;
        }
        lastPositionalArgument = argument.argumentExpression2;
      }
    }

    Set<String>? usedNames;
    if (enclosingConstructorFormalParameterList != null) {
      var result = verifySuperFormalParameters(
        formalParameterList: enclosingConstructorFormalParameterList,
        hasExplicitPositionalArguments: positionalArgumentCount != 0,
        diagnosticReporter: diagnosticReporter,
      );
      positionalArgumentCount += result.positionalArgumentCount;
      if (result.namedArgumentNames.isNotEmpty) {
        usedNames = result.namedArgumentNames.toSet();
      }
    }

    for (int i = 0; i < argumentCount; i++) {
      Argument argument = arguments[i];
      if (argument is NamedArgumentImpl) {
        var nameNode = argument.name;
        String name = nameNode.lexeme;
        var element = namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          element =
              namedParameters != null && name.startsWith('_') && name.length > 1
              ? namedParameters[name.substring(1)]
              : null;
          if (element == null) {
            diagnosticReporter?.report(
              diag.undefinedNamedParameter
                  .withArguments(name: name)
                  .at(nameNode),
            );
          } else {
            diagnosticReporter?.report(
              diag.useOfPrivateParameterName
                  .withArguments(name: name.substring(1))
                  .at(nameNode),
            );
          }
        } else {
          resolvedParameters[i] = element;
        }
        usedNames ??= <String>{};
        if (!usedNames.add(name)) {
          diagnosticReporter?.report(
            diag.duplicateNamedArgument.withArguments(name: name).at(nameNode),
          );
        }
      }
    }

    if (positionalArgumentCount < requiredParameterCount && noBlankArguments) {
      var parent = argumentList.parent2;
      if (diagnosticReporter != null && parent != null) {
        var token =
            lastPositionalArgument?.endToken.next ??
            argumentList.leftParenthesis.next ??
            argumentList.rightParenthesis;
        _reportNotEnoughPositionalArguments(
          token: token,
          requiredParameterCount: requiredParameterCount,
          actualArgumentCount: positionalArgumentCount,
          nameNode: parent,
          diagnosticReporter: diagnosticReporter,
        );
      }
    } else if (positionalArgumentCount > unnamedParameterCount &&
        noBlankArguments) {
      int namedParameterCount = namedParameters?.length ?? 0;
      int namedArgumentCount = usedNames?.length ?? 0;
      if (firstUnresolvedArgument != null) {
        diagnosticReporter?.report(
          (namedParameterCount > namedArgumentCount
                  ? diag.extraPositionalArgumentsCouldBeNamed
                  : diag.extraPositionalArguments)
              .withArguments(
                expected: unnamedParameterCount,
                found: positionalArgumentCount,
              )
              .at(firstUnresolvedArgument),
        );
      }
    }
    return resolvedParameters;
  }

  /// Debug-only: verifies that [list] is a modifiable list by setting its
  /// length to itself.
  ///
  /// For a normal list this is a no-op; for an unmodifiable (i.e. const) list,
  /// this will cause an exception to be thrown.
  static bool _isModifiableList(List<Object?> list) {
    try {
      list.length = list.length;
    } catch (_) {
      return false;
    }
    return true;
  }

  /// Reports [diag.notEnoughPositionalArgumentsSingular] or
  /// [diag.notEnoughPositionalArgumentsPlural] at the
  /// specified [token], considering the name of the [nameNode].
  static void _reportNotEnoughPositionalArguments({
    required Token token,
    required int requiredParameterCount,
    required int actualArgumentCount,
    required AstNode nameNode,
    required DiagnosticReporter diagnosticReporter,
  }) {
    String? name;
    if (nameNode is ConstructorInvocation) {
      var constructorReference = nameNode.constructorReference;
      name =
          constructorReference.selector?.name2.lexeme ??
          '${constructorReference.typeReference.name.lexeme}.new';
    } else if (nameNode is RedirectingConstructorInvocation) {
      name = nameNode.constructorSelector?.name2.lexeme;
      if (name == null) {
        var element = nameNode.element;
        if (element != null) {
          name = '${element.returnType.getDisplayString()}.new';
        }
      }
    } else if (nameNode is SuperConstructorInvocation) {
      name = nameNode.constructorSelector?.name2.lexeme;
      if (name == null) {
        var element = nameNode.element;
        if (element != null) {
          name = '${element.returnType.getDisplayString()}.new';
        }
      }
    } else if (nameNode is MethodInvocation) {
      name = nameNode.methodName.name;
    } else if (nameNode is FunctionExpressionInvocation) {
      var function = nameNode.function2;
      if (function is SimpleIdentifier) {
        name = function.name;
      }
    } else if (nameNode is EnumConstantArguments) {
      var parent = nameNode.parent2;
      if (parent is EnumConstantDeclaration) {
        var declaredElement = parent.declaredFragment!.element;
        name = declaredElement.type.getDisplayString();
      }
    } else if (nameNode is EnumConstantDeclaration) {
      var declaredElement = nameNode.declaredFragment!.element;
      name = declaredElement.type.getDisplayString();
    } else if (nameNode is Annotation) {
      var nameNodeName = nameNode.name;
      name = nameNodeName is PrefixedIdentifier
          ? nameNodeName.identifier.name
          : '${nameNodeName.name}.new';
    } else if (nameNode is DotShorthandConstructorInvocation) {
      name = nameNode.constructorName.name;
    } else if (nameNode is DotShorthandInvocation) {
      name = nameNode.memberName.name;
    } else {
      throw UnimplementedError('(${nameNode.runtimeType}) $nameNode');
    }

    var isPlural = requiredParameterCount > 1;
    LocatableDiagnostic locatableDiagnostic;
    if (name == null) {
      locatableDiagnostic = isPlural
          ? diag.notEnoughPositionalArgumentsPlural.withArguments(
              requiredParameterCount: requiredParameterCount,
              actualArgumentCount: actualArgumentCount,
            )
          : diag.notEnoughPositionalArgumentsSingular;
    } else {
      locatableDiagnostic = isPlural
          ? diag.notEnoughPositionalArgumentsNamePlural.withArguments(
              requiredParameterCount: requiredParameterCount,
              actualArgumentCount: actualArgumentCount,
              name: name,
            )
          : diag.notEnoughPositionalArgumentsNameSingular.withArguments(
              name: name,
            );
    }
    diagnosticReporter.report(locatableDiagnostic.at(token));
  }
}

// TODO(scheglov): move this static method somewhere?
abstract class ScopeResolverVisitor {
  static Scope? getNodeNameScope(AstNode node) =>
      node is AstNodeWithNameScopeMixin ? node.nameScope : null;
}

/// Tracker for whether a `switch` statement has `default` or is on an
/// enumeration, and all the enum constants are covered.
class SwitchExhaustiveness {
  /// If the switch is on an enumeration, the set of enum constants to cover.
  /// Otherwise `null`.
  final Set<FieldElement>? _enumConstants;

  /// If the switch is on an enumeration, is `true` if the null value is
  /// covered, because the switch expression type is non-nullable, or `null`
  /// was covered explicitly.
  bool _isNullEnumValueCovered = false;

  bool isExhaustive = false;

  factory SwitchExhaustiveness(TypeImpl expressionType) {
    if (expressionType is InterfaceType) {
      var enum_ = expressionType.element;
      if (enum_ is EnumElementImpl) {
        return SwitchExhaustiveness._(
          enum_.constants.toSet(),
          expressionType.nullabilitySuffix == NullabilitySuffix.none,
        );
      }
    }
    return SwitchExhaustiveness._(null, false);
  }

  SwitchExhaustiveness._(this._enumConstants, this._isNullEnumValueCovered);

  void visitSwitchExpressionCase(SwitchExpressionCaseImpl node) {
    if (_enumConstants != null) {
      ExpressionImpl? caseConstant;
      var guardedPattern = node.guardedPattern;
      if (guardedPattern.whenClause == null) {
        var pattern = guardedPattern.pattern.unParenthesized;
        if (pattern is ConstantPatternImpl) {
          caseConstant = pattern.expression2;
        }
      }
      _handleCaseConstant(caseConstant);
    }
  }

  void visitSwitchMember(SwitchStatementCaseGroup group) {
    for (var node in group.members) {
      if (_enumConstants != null) {
        ExpressionImpl? caseConstant;
        if (node is SwitchCaseImpl) {
          caseConstant = node.expression2;
        } else if (node is SwitchPatternCaseImpl) {
          var guardedPattern = node.guardedPattern;
          if (guardedPattern.whenClause == null) {
            var pattern = guardedPattern.pattern.unParenthesized;
            if (pattern is ConstantPatternImpl) {
              caseConstant = pattern.expression2;
            }
          }
        }
        _handleCaseConstant(caseConstant);
      } else if (node is SwitchDefault) {
        isExhaustive = true;
      }
    }
  }

  void _handleCaseConstant(ExpressionImpl? caseConstant) {
    if (caseConstant != null) {
      var element = _referencedElement(caseConstant);
      if (element is PropertyAccessorElement) {
        _enumConstants!.remove(element.variable);
      }
      if (caseConstant is NullLiteral) {
        _isNullEnumValueCovered = true;
      }
      if (_enumConstants!.isEmpty && _isNullEnumValueCovered) {
        isExhaustive = true;
      }
    }
  }

  static Element? _referencedElement(Expression expression) {
    if (expression is ParenthesizedExpression) {
      return _referencedElement(expression.expression2);
    } else if (expression is PrefixedIdentifier) {
      return expression.element;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.element;
    } else if (expression is SimpleIdentifier) {
      return expression.element;
    }
    return null;
  }
}

class _WhyNotPromotedVisitor
    implements
        NonPromotionReasonVisitor<
          List<DiagnosticMessage>,
          AstNode,
          PromotableElementImpl
        > {
  final Source source;

  final SyntacticEntity _errorEntity;

  final FlowAnalysisDataForTesting? _dataForTesting;

  PropertyAccessorElement? propertyReference;

  _WhyNotPromotedVisitor(this.source, this._errorEntity, this._dataForTesting);

  @override
  List<DiagnosticMessage> visitDemoteViaExplicitWrite(
    DemoteViaExplicitWrite<PromotableElementImpl, AstNode> reason,
  ) {
    var node = reason.node;
    if (node is ForEachPartsWithIdentifier) {
      node = node.identifier;
    }
    if (_dataForTesting != null) {
      _dataForTesting.nonPromotionReasonTargets[node] = reason.shortName;
    }
    var variableName = reason.variable.name;
    return [_contextMessageForWrite(variableName, node, reason)];
  }

  @override
  List<DiagnosticMessage> visitDemoteViaSuspension(
    DemoteViaSuspension<PromotableElementImpl, AstNode> reason,
  ) {
    var node = reason.node;
    if (_dataForTesting != null) {
      _dataForTesting.nonPromotionReasonTargets[node] = reason.shortName;
    }
    var variableName = reason.variable.name;
    return [_contextMessageForSuspension(variableName, node, reason)];
  }

  @override
  List<DiagnosticMessage> visitPropertyNotPromotedForInherentReason(
    PropertyNotPromotedForInherentReason reason,
  ) {
    var receiverElement = reason.propertyMember;
    if (receiverElement is PropertyAccessorElement) {
      var property = propertyReference = receiverElement;
      var propertyName = reason.propertyName;
      String message = switch (reason.whyNotPromotable) {
        shared.PropertyNonPromotabilityReason.isNotField =>
          "'$propertyName' refers to a getter so it couldn't be promoted.",
        shared.PropertyNonPromotabilityReason.isNotPrivate =>
          "'$propertyName' refers to a public property so it couldn't be "
              "promoted.",
        shared.PropertyNonPromotabilityReason.isExternal =>
          "'$propertyName' refers to an external field so it couldn't be "
              "promoted.",
        shared.PropertyNonPromotabilityReason.isNotFinal =>
          "'$propertyName' refers to a non-final field so it couldn't be "
              "promoted.",
      };
      return [
        DiagnosticMessageImpl(
          filePath: property.firstFragment.libraryFragment.source.fullName,
          message: message,
          offset: property.nonSynthetic.firstFragment.nameOffset!,
          length: property.name!.length,
          url: reason.documentationLink.url,
        ),
        if (!reason.fieldPromotionEnabled)
          _fieldPromotionUnavailableMessage(property, propertyName),
      ];
    } else {
      assert(
        receiverElement == null,
        'Unrecognized property element: ${receiverElement.runtimeType}',
      );
      return [];
    }
  }

  @override
  List<DiagnosticMessage> visitPropertyNotPromotedForNonInherentReason(
    PropertyNotPromotedForNonInherentReason reason,
  ) {
    var receiverElement = reason.propertyMember;
    if (receiverElement is PropertyAccessorElement) {
      var property = propertyReference = receiverElement;
      var propertyName = reason.propertyName;
      var library = receiverElement.library as LibraryElementImpl;
      var fieldNonPromotabilityInfo = library.fieldNameNonPromotabilityInfo;
      var fieldNameInfo = fieldNonPromotabilityInfo[reason.propertyName];
      var messages = <DiagnosticMessage>[];
      void addConflictMessage({
        required Element conflictingElement,
        required String kind,
        required Element enclosingElement,
        required NonPromotionDocumentationLink link,
      }) {
        var enclosingKindName = enclosingElement.kind.displayName;
        var enclosingName = enclosingElement.name;
        var message =
            "'$propertyName' couldn't be promoted because there is a "
            "conflicting $kind in $enclosingKindName '$enclosingName'";
        var nonSyntheticElement = conflictingElement.nonSynthetic;
        var nonSyntheticFragment = nonSyntheticElement.firstFragment;
        var source = nonSyntheticFragment.libraryFragment?.source;
        messages.add(
          DiagnosticMessageImpl(
            filePath: source!.fullName,
            message: message,
            offset: nonSyntheticFragment.nameOffset!,
            length: nonSyntheticElement.name!.length,
            url: link.url,
          ),
        );
      }

      if (fieldNameInfo != null) {
        for (var field in fieldNameInfo.conflictingFields) {
          addConflictMessage(
            conflictingElement: field,
            kind: 'non-promotable field',
            enclosingElement: field.enclosingElement,
            link: NonPromotionDocumentationLink.conflictingNonPromotableField,
          );
        }
        for (var getter in fieldNameInfo.conflictingGetters) {
          addConflictMessage(
            conflictingElement: getter,
            kind: 'getter',
            enclosingElement: getter.enclosingElement,
            link: NonPromotionDocumentationLink.conflictingGetter,
          );
        }
        for (var nsmClass in fieldNameInfo.conflictingNsmClasses) {
          addConflictMessage(
            conflictingElement: nsmClass,
            kind: 'noSuchMethod forwarder',
            enclosingElement: nsmClass,
            link:
                NonPromotionDocumentationLink.conflictingNoSuchMethodForwarder,
          );
        }
      }
      if (reason.fieldPromotionEnabled) {
        // The only possible non-inherent reasons for field promotion to fail
        // are because of conflicts and because field promotion is disabled. So
        // if field promotion is enabled, the loops above should have found a
        // conflict.
        assert(messages.isNotEmpty);
      } else {
        messages.add(_fieldPromotionUnavailableMessage(property, propertyName));
      }
      return messages;
    } else {
      assert(
        receiverElement == null,
        'Unrecognized property element: ${receiverElement.runtimeType}',
      );
      return [];
    }
  }

  @override
  List<DiagnosticMessage> visitThisNotPromoted(ThisNotPromoted reason) {
    return [
      DiagnosticMessageImpl(
        filePath: source.fullName,
        message: "'this' can't be promoted",
        offset: _errorEntity.offset,
        length: _errorEntity.length,
        url: reason.documentationLink.url,
      ),
    ];
  }

  DiagnosticMessageImpl _contextMessageForSuspension(
    String? variableName,
    AstNode node,
    DemoteViaSuspension<PromotableElementImpl, AstNode> reason,
  ) {
    return DiagnosticMessageImpl(
      filePath: source.fullName,
      message:
          "Variable '${variableName!}' could not be promoted due to an "
          "'await' or 'yield'",
      offset: node.offset,
      length: node.length,
      url: reason.documentationLink.url,
    );
  }

  DiagnosticMessageImpl _contextMessageForWrite(
    String? variableName,
    AstNode node,
    DemoteViaExplicitWrite<PromotableElementImpl, AstNode> reason,
  ) {
    return DiagnosticMessageImpl(
      filePath: source.fullName,
      message:
          "Variable '${variableName!}' could not be promoted due to an "
          "assignment",
      offset: node.offset,
      length: node.length,
      url: reason.documentationLink.url,
    );
  }

  DiagnosticMessageImpl _fieldPromotionUnavailableMessage(
    PropertyAccessorElement property,
    String propertyName,
  ) {
    return DiagnosticMessageImpl(
      filePath: property.firstFragment.libraryFragment.source.fullName,
      message:
          "'$propertyName' couldn't be promoted "
          "because field promotion is only available in Dart 3.2 and "
          "above.",
      offset: property.nonSynthetic.firstFragment.nameOffset!,
      length: property.name!.length,
      url: NonPromotionDocumentationLink.fieldPromotionUnavailable.url,
    );
  }
}
