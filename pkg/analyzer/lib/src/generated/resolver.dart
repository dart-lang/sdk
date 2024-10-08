// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/scope.dart';
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
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/shared_type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/simple_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/this_lookup.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/dart/resolver/variable_declaration_resolver.dart';
import 'package:analyzer/src/dart/resolver/yield_statement_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/base_or_final_type_verifier.dart';
import 'package:analyzer/src/error/bool_expression_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/error/super_formal_parameters_verifier.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// Function determining which source files should have inference logging
/// enabled.
///
/// By default, no files have inference logging enabled.
bool Function(Source) inferenceLoggingPredicate = (_) => false;

typedef SharedMatchContext = shared.MatchContext<AstNode, Expression,
    DartPattern, SharedTypeView<DartType>, PromotableElement>;

typedef SharedPatternField
    = shared.RecordPatternField<PatternFieldImpl, DartPatternImpl>;

/// A function which returns [NonPromotionReason]s that various types are not
/// promoted.
typedef WhyNotPromotedGetter = Map<SharedTypeView<DartType>, NonPromotionReason>
    Function();

/// The context shared between different units of the same library.
final class LibraryResolutionContext {
  /// The declarations for [VariableElement]s.
  final Map<VariableElement, VariableDeclaration> _variableNodes =
      Map.identity();
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ThrowingAstVisitor<void>
    with
        ErrorDetectionHelpers,
        TypeAnalyzer<
            DartType,
            AstNode,
            Statement,
            Expression,
            PromotableElement,
            DartPattern,
            void,
            TypeParameterElement,
            InterfaceType,
            InterfaceElement> {
  /// Debug-only: if `true`, manipulations of [_rewriteStack] performed by
  /// [popRewrite], [pushRewrite], and [replaceExpression] will be printed.
  static const bool _debugRewriteStack = false;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl definingLibrary;

  /// The library fragment being visited.
  final CompilationUnitElementImpl libraryFragment;

  /// The context shared between different units of the same library.
  final LibraryResolutionContext libraryResolutionContext;

  /// If the resolver visitor is visiting a switch statement and patterns
  /// support is disabled, the tracker that determines whether the switch is
  /// exhaustive.
  SwitchExhaustiveness? legacySwitchExhaustiveness;

  @override
  final TypeAnalyzerOptions options;

  @override
  late final SharedTypeAnalyzerErrors errors =
      SharedTypeAnalyzerErrors(errorReporter);

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  @override
  final ErrorReporter errorReporter;

  /// The analysis options used by this resolver.
  final AnalysisOptionsImpl analysisOptions;

  /// The class containing the AST nodes being visited,
  /// or `null` if we are not in the scope of a class.
  InterfaceElement? enclosingClass;

  /// The element representing the extension containing the AST nodes being
  /// visited, or `null` if we are not in the scope of an extension.
  ExtensionElement? enclosingExtension;

  /// The element representing the function containing the current node, or
  /// `null` if the current node is not contained in a function.
  ExecutableElement? _enclosingFunction;

  /// The element that can be referenced by the `augmented` expression.
  AugmentableElement? enclosingAugmentation;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 inheritance;

  /// The feature set that is enabled for the current unit.
  final FeatureSet _featureSet;

  /// Helper for checking that subtypes of a base or final type must be base,
  /// final, or sealed.
  late final BaseOrFinalTypeVerifier baseOrFinalTypeVerifier;

  /// Helper for checking expression that should have the `bool` type.
  late final BoolExpressionVerifier boolExpressionVerifier;

  /// Helper for checking potentially nullable dereferences.
  late final NullableDereferenceVerifier nullableDereferenceVerifier;

  /// Helper for extension method resolution.
  late final ExtensionMemberResolver extensionResolver;

  /// Helper for resolving properties on types.
  late final TypePropertyResolver typePropertyResolver;

  /// Helper for resolving [ListLiteral] and [SetOrMapLiteral].
  late final TypedLiteralResolver _typedLiteralResolver;

  late final AssignmentExpressionResolver _assignmentExpressionResolver;
  late final BinaryExpressionResolver _binaryExpressionResolver;
  late final ConstructorReferenceResolver _constructorReferenceResolver =
      ConstructorReferenceResolver(this);
  late final FunctionExpressionInvocationResolver
      _functionExpressionInvocationResolver;
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

  /// If a class, or mixin, is being resolved, the type of the class.
  /// Otherwise `null`.
  DartType? _thisType;

  final FlowAnalysisHelper flowAnalysis;

  /// A comment before a function should be resolved in the context of the
  /// function. But when we incrementally resolve a comment, we don't want to
  /// resolve the whole function.
  ///
  /// So, this flag is set to `true`, when just context of the function should
  /// be built and the comment resolved.
  bool resolveOnlyCommentInFunctionBody = false;

  /// Stack of expressions which we have not yet finished visiting, that should
  /// terminate a null-shorting expression.
  ///
  /// The stack contains a `null` sentinel as its first entry so that it is
  /// always safe to use `.last` to examine the top of the stack.
  final List<Expression?> _unfinishedNullShorts = [null];

  late final FunctionReferenceResolver _functionReferenceResolver;

  late final InstanceCreationExpressionResolver
      _instanceCreationExpressionResolver =
      InstanceCreationExpressionResolver(this);

  late final SimpleIdentifierResolver _simpleIdentifierResolver =
      SimpleIdentifierResolver(this);

  late final PropertyElementResolver _propertyElementResolver =
      PropertyElementResolver(this);

  late final RecordLiteralResolver _recordLiteralResolver =
      RecordLiteralResolver(resolver: this);

  late final AnnotationResolver _annotationResolver = AnnotationResolver(this);

  late final ListPatternResolver listPatternResolver =
      ListPatternResolver(this);

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
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution.
  ///
  // TODO(paulberry): make [featureSet] a required parameter (this will be a
  // breaking change).
  ResolverVisitor(
    InheritanceManager3 inheritanceManager,
    LibraryElementImpl definingLibrary,
    LibraryResolutionContext libraryResolutionContext,
    Source source,
    TypeProvider typeProvider,
    AnalysisErrorListener errorListener, {
    required CompilationUnitElementImpl libraryFragment,
    required FeatureSet featureSet,
    required AnalysisOptionsImpl analysisOptions,
    required FlowAnalysisHelper flowAnalysisHelper,
  }) : this._(
          inheritanceManager,
          definingLibrary,
          libraryResolutionContext,
          source,
          definingLibrary.typeSystem,
          typeProvider as TypeProviderImpl,
          errorListener,
          featureSet,
          analysisOptions,
          flowAnalysisHelper,
          libraryFragment: libraryFragment,
        );

  ResolverVisitor._(
    this.inheritance,
    this.definingLibrary,
    this.libraryResolutionContext,
    this.source,
    this.typeSystem,
    this.typeProvider,
    AnalysisErrorListener errorListener,
    FeatureSet featureSet,
    this.analysisOptions,
    this.flowAnalysis, {
    required this.libraryFragment,
  })  : errorReporter = ErrorReporter(errorListener, source),
        _featureSet = featureSet,
        genericMetadataIsEnabled =
            definingLibrary.featureSet.isEnabled(Feature.generic_metadata),
        inferenceUsingBoundsIsEnabled = definingLibrary.featureSet
            .isEnabled(Feature.inference_using_bounds),
        options = TypeAnalyzerOptions(
            nullSafetyEnabled: true,
            patternsEnabled:
                definingLibrary.featureSet.isEnabled(Feature.patterns),
            inferenceUpdate3Enabled: definingLibrary.featureSet
                .isEnabled(Feature.inference_update_3)) {
    nullableDereferenceVerifier = NullableDereferenceVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
      resolver: this,
    );
    baseOrFinalTypeVerifier = BaseOrFinalTypeVerifier(
        definingLibrary: definingLibrary, errorReporter: errorReporter);
    boolExpressionVerifier = BoolExpressionVerifier(
      resolver: this,
      errorReporter: errorReporter,
      nullableDereferenceVerifier: nullableDereferenceVerifier,
    );
    _typedLiteralResolver =
        TypedLiteralResolver(this, typeSystem, typeProvider, analysisOptions);
    extensionResolver = ExtensionMemberResolver(this);
    typePropertyResolver = TypePropertyResolver(this);
    inferenceHelper = InvocationInferenceHelper(
      resolver: this,
      errorReporter: errorReporter,
      typeSystem: typeSystem,
      dataForTesting: flowAnalysis.dataForTesting != null
          ? TypeConstraintGenerationDataForTesting()
          : null,
    );
    _assignmentExpressionResolver = AssignmentExpressionResolver(
      resolver: this,
    );
    _binaryExpressionResolver = BinaryExpressionResolver(
      resolver: this,
    );
    _functionExpressionInvocationResolver =
        FunctionExpressionInvocationResolver(
      resolver: this,
    );
    _functionExpressionResolver = FunctionExpressionResolver(resolver: this);
    _forResolver = ForResolver(
      resolver: this,
    );
    _postfixExpressionResolver = PostfixExpressionResolver(
      resolver: this,
    );
    _prefixedIdentifierResolver = PrefixedIdentifierResolver(this);
    _prefixExpressionResolver = PrefixExpressionResolver(
      resolver: this,
    );
    _variableDeclarationResolver = VariableDeclarationResolver(
      resolver: this,
      strictInference: analysisOptions.strictInference,
    );
    _yieldStatementResolver = YieldStatementResolver(
      resolver: this,
    );
    nullSafetyDeadCodeVerifier = NullSafetyDeadCodeVerifier(
      typeSystem,
      errorReporter,
      flowAnalysis,
    );
    elementResolver = ElementResolver(this);
    typeAnalyzer = StaticTypeAnalyzer(this);
    _functionReferenceResolver = FunctionReferenceResolver(this);
  }

  /// Inference context information for the current function body, if the
  /// current node is inside a function body.
  BodyInferenceContext? get bodyContext => _bodyContext;

  /// Return the element representing the function containing the current node,
  /// or `null` if the current node is not contained in a function.
  ///
  /// @return the element representing the function containing the current node
  ExecutableElement? get enclosingFunction => _enclosingFunction;

  @override
  FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
      SharedTypeView<DartType>> get flow => flowAnalysis.flow!;

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
      DartType,
      PromotableElement,
      TypeParameterElement,
      InterfaceType,
      InterfaceElement> get operations => flowAnalysis.typeOperations;

  /// Gets the current depth of the [_rewriteStack].  This may be used in
  /// assertions to verify that pushes and pops are properly balanced.
  int get rewriteStackDepth => _rewriteStack.length;

  @override
  bool get strictCasts => analysisOptions.strictCasts;

  /// If a class, or mixin, is being resolved, the type of the class.
  ///
  /// If an extension is being resolved, the type of `this`, the declared
  /// extended type, or promoted.
  ///
  /// Otherwise `null`.
  DartType? get thisType {
    return _thisType;
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
            errorReporter.atNode(
              field,
              CompileTimeErrorCode.MISSING_NAMED_PATTERN_FIELD_NAME,
            );
          }
        }
      } else if (mustBeNamed) {
        errorReporter.atNode(
          field,
          CompileTimeErrorCode.POSITIONAL_FIELD_IN_OBJECT_PATTERN,
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
  /// See [CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
  void checkForArgumentTypesNotAssignableInList(ArgumentList argumentList,
      List<WhyNotPromotedGetter> whyNotPromotedList) {
    var arguments = argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      checkForArgumentTypeNotAssignableForArgument(arguments[i],
          whyNotPromoted:
              flowAnalysis.flow == null ? null : whyNotPromotedList[i]);
    }
  }

  void checkForBodyMayCompleteNormally({
    required FunctionBodyImpl body,
    required SyntacticEntity errorNode,
  }) {
    if (!flowAnalysis.flow!.isReachable) {
      return;
    }

    var bodyContext = body.bodyContext;
    if (bodyContext == null) {
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
        var lowerBound = typeProvider.futureElement.instantiate(
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

      ErrorCode errorCode;
      if (typeSystem.isPotentiallyNonNullable(returnType)) {
        errorCode = CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY;
      } else {
        var returnTypeBase = typeSystem.futureOrBase(returnType);
        if (returnTypeBase is DynamicType ||
            returnTypeBase is InvalidType ||
            returnTypeBase is UnknownInferredType ||
            returnTypeBase is VoidType ||
            returnTypeBase.isDartCoreNull) {
          return;
        } else {
          errorCode = WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE;
        }
      }
      if (errorNode is ConstructorDeclaration) {
        errorReporter.atConstructorDeclaration(
          errorNode,
          errorCode,
          arguments: [returnType],
        );
      } else if (errorNode is BlockFunctionBody) {
        errorReporter.atToken(
          errorNode.block.leftBracket,
          errorCode,
          arguments: [returnType],
        );
      } else if (errorNode is Token) {
        errorReporter.atToken(
          errorNode,
          errorCode,
          arguments: [returnType],
        );
      }
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
    required DartType requiredType,
    required DartType matchedValueType,
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
        errorReporter.atNode(
          errorNode,
          WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE,
          arguments: [matchedValueType, requiredType],
        );
      }
    }
  }

  void checkReadOfNotAssignedLocalVariable(
    SimpleIdentifier node,
    Element? element,
  ) {
    if (flowAnalysis.flow == null) {
      return;
    }

    if (!node.inGetterContext()) {
      return;
    }

    if (element is VariableElement) {
      var assigned =
          flowAnalysis.isDefinitelyAssigned(node, element as PromotableElement);
      var unassigned = flowAnalysis.isDefinitelyUnassigned(node, element);

      if (element.isLate) {
        if (unassigned) {
          errorReporter.atNode(
            node,
            CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE,
            arguments: [node.name],
          );
        }
        return;
      }

      if (!assigned) {
        if (element.isFinal) {
          errorReporter.atNode(
            node,
            CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL,
            arguments: [node.name],
          );
          return;
        }

        if (typeSystem.isPotentiallyNonNullable(element.type)) {
          errorReporter.atNode(
            node,
            CompileTimeErrorCode
                .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
            arguments: [node.name],
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
      Map<SharedTypeView<DartType>, NonPromotionReason>? whyNotPromoted) {
    List<DiagnosticMessage> messages = [];
    if (whyNotPromoted != null) {
      for (var entry in whyNotPromoted.entries) {
        var whyNotPromotedVisitor = _WhyNotPromotedVisitor(
            source, errorEntity, flowAnalysis.dataForTesting);
        if (typeSystem.isPotentiallyNullable(entry.key.unwrapTypeView())) {
          continue;
        }
        messages = entry.value.accept(whyNotPromotedVisitor);
        // `messages` will be passed to the ErrorReporter, which might add
        // additional entries. So make sure that it's not a `const []`.
        assert(_isModifiableList(messages));
        if (messages.isNotEmpty) {
          if (flowAnalysis.dataForTesting != null) {
            var nonPromotionReasonText = entry.value.shortName;
            var args = <String>[];
            if (whyNotPromotedVisitor.propertyReference != null) {
              var id =
                  computeMemberId(whyNotPromotedVisitor.propertyReference!);
              args.add('target: $id');
            }
            var propertyType = whyNotPromotedVisitor.propertyType;
            if (propertyType != null) {
              var propertyTypeStr = propertyType.getDisplayString();
              args.add('type: $propertyTypeStr');
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
  ExpressionTypeAnalysisResult<DartType> dispatchExpression(
      covariant ExpressionImpl expression,
      SharedTypeSchemaView<DartType> context) {
    int? stackDepth;
    assert(() {
      stackDepth = rewriteStackDepth;
      return true;
    }());
    // TODO(paulberry): implement null shorting
    // Stack: ()
    pushRewrite(expression);
    // Stack: (Expression)
    expression.resolveExpression(this, context.unwrapTypeSchemaView());
    inferenceLogWriter?.assertExpressionWasRecorded(expression);
    assert(rewriteStackDepth == stackDepth! + 1);
    var replacementExpression = peekRewrite()!;
    assert(identical(
        _replacements[expression] ?? expression, replacementExpression));
    var staticType = replacementExpression.staticType;
    if (staticType == null) {
      var shouldHaveType = true;
      if (replacementExpression is ExtensionOverride) {
        shouldHaveType = false;
      } else if (replacementExpression is IdentifierImpl) {
        var element = replacementExpression.staticElement;
        if (element is ExtensionElement || element is InterfaceElement) {
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
    return SimpleTypeAnalysisResult<DartType>(type: SharedTypeView(staticType));
  }

  @override
  PatternResult<DartType> dispatchPattern(
      SharedMatchContext context, AstNode node) {
    shared.PatternResult<DartType> analysisResult;
    if (node is DartPatternImpl) {
      analysisResult = node.resolvePattern(this, context);
      node.matchedValueType = analysisResult.matchedValueType.unwrapTypeView();
    } else {
      // This can occur inside conventional switch statements, since
      // [SwitchCase] points directly to an [Expression] rather than to a
      // [ConstantPattern].  So we mimic what
      // [ConstantPatternImpl.resolvePattern] would do.
      analysisResult =
          analyzeConstantPattern(context, node, node as Expression);
      // Stack: (Expression)
      popRewrite();
      // Stack: ()
    }
    return analysisResult;
  }

  @override
  SharedTypeSchemaView<DartType> dispatchPatternSchema(
      covariant DartPatternImpl node) {
    return SharedTypeSchemaView(node.computePatternSchema(this));
  }

  @override
  void dispatchStatement(Statement statement) {
    statement.accept(this);
  }

  @override
  SharedTypeView<DartType> downwardInferObjectPatternRequiredType({
    required SharedTypeView<DartType> matchedType,
    required covariant ObjectPatternImpl pattern,
  }) {
    var typeNode = pattern.type;
    if (typeNode.typeArguments == null) {
      var typeNameElement = typeNode.element;
      if (typeNameElement is InterfaceElement) {
        var typeParameters = typeNameElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var typeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            errorNode: typeNode,
            declaredType: typeNameElement.thisType,
            contextType: matchedType.unwrapTypeView(),
            nodeForTesting: pattern,
          );
          return SharedTypeView(typeNode.type = typeNameElement.instantiate(
            typeArguments: typeArguments,
            nullabilitySuffix: NullabilitySuffix.none,
          ));
        }
      } else if (typeNameElement is TypeAliasElement) {
        var typeParameters = typeNameElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var typeArguments = _inferTypeArguments(
            typeParameters: typeParameters,
            errorNode: typeNode,
            declaredType: typeNameElement.aliasedType,
            contextType: matchedType.unwrapTypeView(),
            nodeForTesting: pattern,
          );
          return SharedTypeView(typeNode.type = typeNameElement.instantiate(
            typeArguments: typeArguments,
            nullabilitySuffix: NullabilitySuffix.none,
          ));
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
    case_.expression = popRewrite()!;
    nullSafetyDeadCodeVerifier.flowEnd(case_);
  }

  @override
  void finishJoinedPatternVariable(
    covariant JoinPatternVariableElementImpl variable, {
    required JoinedPatternVariableLocation location,
    required shared.JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required SharedTypeView<DartType> type,
  }) {
    variable.inconsistency = variable.inconsistency.maxWith(inconsistency);
    variable.isFinal = isFinal;
    variable.type = type.unwrapTypeView();

    if (location == JoinedPatternVariableLocation.sharedCaseScope) {
      for (var reference in variable.references) {
        if (variable.inconsistency ==
            shared.JoinedPatternVariableInconsistency.sharedCaseAbsent) {
          errorReporter.atNode(
            reference,
            CompileTimeErrorCode
                .PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
            arguments: [variable.name],
          );
        } else if (variable.inconsistency ==
            shared.JoinedPatternVariableInconsistency.sharedCaseHasLabel) {
          errorReporter.atNode(
            reference,
            CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
            arguments: [variable.name],
          );
        } else if (variable.inconsistency ==
            shared.JoinedPatternVariableInconsistency.differentFinalityOrType) {
          errorReporter.atNode(
            reference,
            CompileTimeErrorCode
                .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
            arguments: [variable.name],
          );
        }
      }
    }
  }

  @override
  shared.MapPatternEntry<Expression, DartPattern>? getMapPatternEntry(
    covariant MapPatternElementImpl element,
  ) {
    if (element is MapPatternEntryImpl) {
      return shared.MapPatternEntry(
        key: element.key,
        value: element.value,
      );
    }
    return null;
  }

  /// Return the static element associated with the given expression whose type
  /// can be overridden, or `null` if there is no element whose type can be
  /// overridden.
  ///
  /// @param expression the expression with which the element is associated
  /// @return the element associated with the given expression
  VariableElement? getOverridableStaticElement(Expression expression) {
    Element? element;
    if (expression is SimpleIdentifier) {
      element = expression.staticElement;
    } else if (expression is PrefixedIdentifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is VariableElement) {
      return element;
    }
    return null;
  }

  @override
  DartPattern? getRestPatternElementPattern(
    covariant RestPatternElementImpl element,
  ) {
    return element.pattern;
  }

  @override
  SwitchExpressionMemberInfo<AstNode, Expression, PromotableElement>
      getSwitchExpressionMemberInfo(
    covariant SwitchExpressionImpl node,
    int index,
  ) {
    var case_ = node.cases[index];
    var guardedPattern = case_.guardedPattern;
    return SwitchExpressionMemberInfo(
      head: CaseHeadOrDefaultInfo(
        pattern: guardedPattern.pattern,
        guard: guardedPattern.whenClause?.expression,
        variables: guardedPattern.variables,
      ),
      expression: case_.expression,
    );
  }

  @override
  SwitchStatementMemberInfo<AstNode, Statement, Expression, PromotableElement>
      getSwitchStatementMemberInfo(
    covariant SwitchStatementImpl node,
    int index,
  ) {
    CaseHeadOrDefaultInfo<AstNode, Expression, PromotableElement> ofMember(
      SwitchMemberImpl member,
    ) {
      if (member is SwitchCaseImpl) {
        return CaseHeadOrDefaultInfo(
          pattern: member.expression,
          variables: {},
        );
      } else if (member is SwitchPatternCaseImpl) {
        var guardedPattern = member.guardedPattern;
        return CaseHeadOrDefaultInfo(
          pattern: guardedPattern.pattern,
          variables: guardedPattern.variables,
          guard: guardedPattern.whenClause?.expression,
        );
      } else {
        return CaseHeadOrDefaultInfo(
          pattern: null,
          variables: {},
        );
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

    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);
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

    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);
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
      AstNode node, int caseIndex, Iterable<PromotableElement> variables) {}

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
      legacySwitchExhaustiveness
          ?.visitSwitchExpressionCase(node.cases[caseIndex]);
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
    SharedTypeView<DartType> keyType,
  ) {
    entry.key = popRewrite()!;
  }

  @override
  void handleMapPatternRestElement(
    DartPattern container,
    covariant RestPatternElementImpl restElement,
  ) {}

  @override
  void handleMergedStatementCase(covariant SwitchStatementImpl node,
      {required int caseIndex, required bool isTerminating}) {
    nullSafetyDeadCodeVerifier
        .flowEnd(node.memberGroups[caseIndex].members.last);
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
  void handleSwitchScrutinee(SharedTypeView<DartType> type) {
    if (!options.patternsEnabled) {
      legacySwitchExhaustiveness = SwitchExhaustiveness(type.unwrapTypeView());
    }
  }

  /// If generic function instantiation should be performed on `expression`,
  /// inserts a [FunctionReference] node which wraps [expression].
  ///
  /// If an [FunctionReference] is inserted, returns it; otherwise, returns
  /// [expression].
  ExpressionImpl insertGenericFunctionInstantiation(Expression expression,
      {required DartType contextType}) {
    expression as ExpressionImpl;
    if (!isConstructorTearoffsEnabled) {
      // Temporarily, only create [ImplicitCallReference] nodes under the
      // 'constructor-tearoffs' feature.
      // TODO(srawlins): When we are ready to make a breaking change release to
      // the analyzer package, remove this exception.
      return expression;
    }

    var staticType = expression.staticType;
    if (staticType is! FunctionType || staticType.typeFormals.isEmpty) {
      return expression;
    }

    var context = typeSystem.flatten(contextType);
    if (context is! FunctionType || context.typeFormals.isNotEmpty) {
      return expression;
    }

    List<DartType> typeArgumentTypes =
        typeSystem.inferFunctionTypeInstantiation(
      context,
      staticType,
      errorReporter: errorReporter,
      errorNode: expression,
      // If the constructor-tearoffs feature is enabled, then so is
      // generic-metadata.
      genericMetadataIsEnabled: true,
      inferenceUsingBoundsIsEnabled:
          _featureSet.isEnabled(Feature.inference_using_bounds),
      strictInference: analysisOptions.strictInference,
      strictCasts: analysisOptions.strictCasts,
      typeSystemOperations: flowAnalysis.typeOperations,
      dataForTesting: inferenceHelper.dataForTesting,
      nodeForTesting: expression,
    );
    if (typeArgumentTypes.isNotEmpty) {
      staticType = staticType.instantiate(typeArgumentTypes);
    }

    var parent = expression.parent;
    var genericFunctionInstantiation = FunctionReferenceImpl(
      function: expression,
      typeArguments: null,
    );
    replaceExpression(expression, genericFunctionInstantiation, parent: parent);

    genericFunctionInstantiation.typeArgumentTypes = typeArgumentTypes;
    genericFunctionInstantiation.setPseudoExpressionStaticType(staticType);

    return genericFunctionInstantiation;
  }

  @override
  bool isLegacySwitchExhaustive(
          AstNode node, SharedTypeView<DartType> expressionType) =>
      legacySwitchExhaustiveness!.isExhaustive;

  @override
  bool isRestPatternElement(AstNode node) {
    return node is RestPatternElementImpl;
  }

  @override
  bool isVariablePattern(AstNode pattern) => pattern is DeclaredVariablePattern;

  /// If we reached a null-shorting termination, and the [node] has null
  /// shorting, make the type of the [node] nullable.
  void nullShortingTermination(ExpressionImpl node,
      {bool discardType = false}) {
    if (identical(_unfinishedNullShorts.last, node)) {
      do {
        _unfinishedNullShorts.removeLast();
        flowAnalysis.flow!.nullAwareAccess_end();
      } while (identical(_unfinishedNullShorts.last, node));
      if (node is! CascadeExpression && !discardType) {
        node.setPseudoExpressionStaticType(
            typeSystem.makeNullable(node.staticType as TypeImpl));
      }
    }
  }

  /// If it is appropriate to do so, override the current type of the static
  /// element associated with the given expression with the given type.
  /// Generally speaking, it is appropriate if the given type is more specific
  /// than the current type.
  ///
  /// @param expression the expression used to access the static element whose
  ///        types might be overridden
  /// @param potentialType the potential type of the elements
  /// @param allowPrecisionLoss see @{code overrideVariable} docs
  void overrideExpression(Expression expression, DartType potentialType,
      bool allowPrecisionLoss, bool setExpressionType) {
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
    InterfaceElement? enclosingClassElement,
    ExecutableElement? enclosingExecutableElement,
    AugmentableElement? enclosingAugmentation,
  }) {
    enclosingClass = enclosingClassElement;
    _setupThisType();
    _enclosingFunction = enclosingExecutableElement;
    this.enclosingAugmentation = enclosingAugmentation;
  }

  /// We are going to resolve [node], without visiting its parent.
  /// Do necessary preparations - set enclosing elements, scopes, etc.
  /// This [ResolverVisitor] instance is fresh, just created.
  ///
  /// Return `true` if we were able to do this, or `false` if it is not
  /// possible to resolve only [node].
  bool prepareForResolving(AstNode node) {
    var parent = node.parent;

    if (parent is CompilationUnit) {
      return node is ClassDeclaration ||
          node is Directive ||
          node is ExtensionDeclaration ||
          node is FunctionDeclaration ||
          node is TopLevelVariableDeclaration;
    }

    void forClassElement(InterfaceElement parentElement) {
      enclosingClass = parentElement;
    }

    if (parent is ClassDeclaration) {
      forClassElement(parent.declaredElement!);
      return true;
    }

    if (parent is ExtensionDeclaration) {
      enclosingExtension = parent.declaredElement!;
      return true;
    }

    if (parent is MixinDeclaration) {
      forClassElement(parent.declaredElement!);
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
  void replaceExpression(Expression oldNode, ExpressionImpl newNode,
      {AstNode? parent}) {
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
        oldExpression: oldNode, newExpression: newNode);
    NodeReplacer.replace(oldNode, newNode, parent: parent);
  }

  PatternResult<DartType> resolveAssignedVariablePattern({
    required AssignedVariablePatternImpl node,
    required SharedMatchContext context,
  }) {
    var element = node.element;
    if (element is! PromotableElement) {
      return PatternResult(
          matchedValueType: SharedTypeView(InvalidTypeImpl.instance));
    }

    if (element.isFinal) {
      var flow = this.flow;
      if (element.isLate) {
        if (flow.isAssigned(element)) {
          errorReporter.atToken(
            node.name,
            CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED,
          );
        }
      } else {
        if (!flow.isUnassigned(element)) {
          errorReporter.atToken(
            node.name,
            CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL,
            arguments: [node.name.lexeme],
          );
        }
      }
    }

    return analyzeAssignedVariablePattern(context, node, element);
  }

  /// Resolve LHS [node] of an assignment, an explicit [AssignmentExpression],
  /// or implicit [PrefixExpression] or [PostfixExpression].
  PropertyElementResolverResult resolveForWrite({
    required Expression node,
    required bool hasRead,
  }) {
    inferenceLogWriter?.enterLValue(node);
    if (node is AugmentedExpressionImpl) {
      var augmentation = enclosingAugmentation;
      var augmentationTarget = augmentation?.augmentationTarget;
      if (augmentation is PropertyAccessorElementImpl &&
          augmentation.isSetter &&
          augmentationTarget is PropertyAccessorElementImpl &&
          augmentationTarget.isSetter) {
        node.element = augmentationTarget;
        inferenceLogWriter?.exitLValue(node);
        return PropertyElementResolverResult(
          writeElementRequested: augmentationTarget,
        );
      }
      errorReporter.atNode(
        node,
        CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_NOT_SETTER,
      );
      inferenceLogWriter?.exitLValue(node);
      return PropertyElementResolverResult();
    } else if (node is IndexExpression) {
      var target = node.target;
      if (target != null) {
        analyzeExpression(
            target, SharedTypeSchemaView(UnknownInferredType.instance));
        popRewrite();
      }

      startNullAwareIndexExpression(node);

      var result = _propertyElementResolver.resolveIndexExpression(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      analyzeExpression(
          node.index, SharedTypeSchemaView(result.indexContextType));
      popRewrite();
      var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(node.index);
      checkIndexExpressionIndex(
        node.index,
        readElement: hasRead ? result.readElement as ExecutableElement? : null,
        writeElement: result.writeElement as ExecutableElement?,
        whyNotPromoted: whyNotPromoted,
      );

      inferenceLogWriter?.exitLValue(node);
      return result;
    } else if (node is PrefixedIdentifierImpl) {
      var prefix = node.prefix;
      prefix.accept(this);

      // TODO(scheglov): It would be nice to rewrite all such cases.
      if (prefix.staticType is RecordType) {
        var propertyAccess = PropertyAccessImpl(
          target: prefix,
          operator: node.period,
          propertyName: node.identifier,
        );
        NodeReplacer.replace(node, propertyAccess);
        inferenceLogWriter?.exitLValue(node);
        return resolveForWrite(
          node: propertyAccess,
          hasRead: hasRead,
        );
      }

      inferenceLogWriter?.exitLValue(node);
      return _propertyElementResolver.resolvePrefixedIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is PropertyAccess) {
      node.target?.accept(this);
      startNullAwarePropertyAccess(node);

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

      if (hasRead && result.readElementRequested == null) {
        errorReporter.atNode(
          node,
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
          arguments: [node.name],
        );
      }

      inferenceLogWriter?.exitLValue(node);
      return result;
    } else {
      inferenceLogWriter?.exitLValue(node, reanalyzeAsRValue: true);
      analyzeExpression(
          node, SharedTypeSchemaView(UnknownInferredType.instance));
      popRewrite();
      return PropertyElementResolverResult();
    }
  }

  PatternResult<DartType> resolveMapPattern({
    required MapPatternImpl node,
    required SharedMatchContext context,
  }) {
    inferenceLogWriter?.enterPattern(node);
    ({
      SharedTypeView<DartType> keyType,
      SharedTypeView<DartType> valueType
    })? typeArguments;
    var typeArgumentsList = node.typeArguments;
    if (typeArgumentsList != null) {
      typeArgumentsList.accept(this);
      // Check that we have exactly two type arguments.
      var length = typeArgumentsList.arguments.length;
      if (length == 2) {
        typeArguments = (
          keyType: SharedTypeView(typeArgumentsList.arguments[0].typeOrThrow),
          valueType: SharedTypeView(typeArgumentsList.arguments[1].typeOrThrow),
        );
      } else {
        errorReporter.atNode(
          typeArgumentsList,
          CompileTimeErrorCode.EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS,
          arguments: [length],
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
  (ExecutableElement?, SharedTypeView<DartType>)
      resolveObjectPatternPropertyGet({
    required covariant ObjectPatternImpl objectPattern,
    required SharedTypeView<DartType> receiverType,
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
      propertyErrorEntity: objectPattern.type,
      nameErrorEntity: nameToken,
    );

    if (result.needsGetterError) {
      errorReporter.atToken(
        nameToken,
        CompileTimeErrorCode.UNDEFINED_GETTER,
        arguments: [nameToken.lexeme, receiverType],
      );
    }

    var getter = result.getter;
    if (getter != null) {
      fieldNode.element = getter;
      if (getter is PropertyAccessorElement) {
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
  RelationalOperatorResolution<DartType>? resolveRelationalPatternOperator(
    covariant RelationalPatternImpl node,
    SharedTypeView<DartType> matchedType,
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
      propertyErrorEntity: node.operator,
      nameErrorEntity: node,
      parentNode: node,
    );

    if (result.needsGetterError) {
      errorReporter.atToken(
        node.operator,
        CompileTimeErrorCode.UNDEFINED_OPERATOR,
        arguments: [methodName, matchedType],
      );
    }

    var element = result.getter as MethodElement?;
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
    DartType readType =
        atDynamicTarget ? DynamicTypeImpl.instance : InvalidTypeImpl.instance;
    if (node is IndexExpression) {
      if (element is MethodElement) {
        readType = element.returnType;
      }
    } else if (node is PrefixedIdentifier ||
        node is PropertyAccess ||
        node is SimpleIdentifier) {
      if (element is PropertyAccessorElement && element.isGetter) {
        readType = element.returnType;
      } else if (element is VariableElement) {
        readType = localVariableTypeProvider.getType(node as SimpleIdentifier,
            isRead: true);
      }
    }

    var parent = node.parent;
    if (parent is AssignmentExpressionImpl && parent.leftHandSide == node) {
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
  void setVariableType(
      PromotableElement variable, SharedTypeView<DartType> type) {
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
    DartType writeType =
        atDynamicTarget ? DynamicTypeImpl.instance : InvalidTypeImpl.instance;
    if (node is AugmentedExpression) {
      if (element is PropertyAccessorElement && element.isSetter) {
        if (element.parameters case [var valueParameter]) {
          writeType = valueParameter.type;
        }
      }
    } else if (node is IndexExpression) {
      if (element is MethodElement) {
        var parameters = element.parameters;
        if (parameters.length == 2) {
          writeType = parameters[1].type;
        }
      }
    } else if (node is PrefixedIdentifier ||
        node is PropertyAccess ||
        node is SimpleIdentifier) {
      if (element is PropertyAccessorElement && element.isSetter) {
        if (element.isSynthetic) {
          var variable = element.variable2;
          if (variable != null) {
            writeType = variable.type;
          }
        } else {
          var parameters = element.parameters;
          if (parameters.length == 1) {
            writeType = parameters[0].type;
          }
        }
      } else if (element is VariableElement) {
        writeType = element.type;
      }
    }

    var parent = node.parent;
    if (parent is AssignmentExpressionImpl && parent.leftHandSide == node) {
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

  void startNullAwareIndexExpression(IndexExpression node) {
    if (node.isNullAware) {
      var flow = flowAnalysis.flow;
      if (flow != null) {
        flow.nullAwareAccess_rightBegin(
            node.target,
            SharedTypeView(
                node.realTarget.staticType ?? typeProvider.dynamicType));
        _unfinishedNullShorts.add(node.nullShortingTermination);
      }
    }
  }

  void startNullAwarePropertyAccess(PropertyAccess node) {
    if (node.isNullAware) {
      var flow = flowAnalysis.flow;
      if (flow != null) {
        var target = node.target;
        if (target is SimpleIdentifier &&
            target.staticElement is InterfaceElement) {
          // `?.` to access static methods is equivalent to `.`, so do nothing.
        } else {
          flow.nullAwareAccess_rightBegin(
              target,
              SharedTypeView(
                  node.realTarget.staticType ?? typeProvider.dynamicType));
          _unfinishedNullShorts.add(node.nullShortingTermination);
        }
      }
    }
  }

  /// Returns the result of an implicit `this.` lookup for the identifier string
  /// [id] in a getter context, or `null` if no match was found.
  LexicalLookupResult? thisLookupGetter(SimpleIdentifier node) {
    return ThisLookup.lookupGetter(this, node);
  }

  /// Returns the result of an implicit `this.` lookup for the identifier string
  /// [id] in a setter context, or `null` if no match was found.
  LexicalLookupResult? thisLookupSetter(SimpleIdentifier node) {
    return ThisLookup.lookupSetter(this, node);
  }

  @override
  SharedTypeView<DartType> variableTypeFromInitializerType(
      SharedTypeView<DartType> type) {
    DartType unwrapped = type.unwrapTypeView();
    if (unwrapped.isDartCoreNull) {
      return SharedTypeView(DynamicTypeImpl.instance);
    }
    return SharedTypeView(typeSystem.demoteType(unwrapped));
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitAdjacentStrings(node as AdjacentStringsImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    inferenceLogWriter?.enterAnnotation(node);
    // Annotations can contain expressions, so we need flow analysis to be
    // available to process those expressions.
    var isTopLevel = flowAnalysis.flow == null;
    if (isTopLevel) {
      flowAnalysis.topLevelDeclaration_enter(node, null);
    }
    assert(flowAnalysis.flow != null);
    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
    _annotationResolver.resolve(node, whyNotPromotedList);
    var arguments = node.arguments;
    if (arguments != null) {
      checkForArgumentTypesNotAssignableInList(arguments, whyNotPromotedList);
    }
    if (isTopLevel) {
      flowAnalysis.topLevelDeclaration_exit();
    }
    inferenceLogWriter?.exitAnnotation(node);
  }

  @override
  void visitAsExpression(
    covariant AsExpressionImpl node, {
    DartType contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);

    analyzeExpression(
        node.expression, SharedTypeSchemaView(UnknownInferredType.instance));
    popRewrite();

    node.type.accept(this);

    typeAnalyzer.visitAsExpression(node);
    flowAnalysis.asExpression(node);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);

    var expression = node.expression;
    var staticType = node.staticType;
    if (staticType != null && expression is SimpleIdentifier) {
      var simpleIdentifier = expression as SimpleIdentifier;
      var element = simpleIdentifier.staticElement;
      if (element is PromotableElement &&
          !expression.typeOrThrow.isDartCoreNull &&
          typeSystem.isNullable(element.type) &&
          typeSystem.isNonNullable(staticType) &&
          flowAnalysis.isDefinitelyUnassigned(simpleIdentifier, element)) {
        errorReporter.atNode(
          simpleIdentifier,
          WarningCode.CAST_FROM_NULLABLE_ALWAYS_FAILS,
          arguments: [simpleIdentifier.name],
        );
      }
    }
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    flowAnalysis.flow?.assert_begin();
    analyzeExpression(
        node.condition, SharedTypeSchemaView(typeProvider.boolType));
    popRewrite();
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_EXPRESSION,
      whyNotPromoted: flowAnalysis.flow?.whyNotPromoted(node.condition),
    );
    flowAnalysis.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    flowAnalysis.flow?.assert_end();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    flowAnalysis.flow?.assert_begin();
    analyzeExpression(
        node.condition, SharedTypeSchemaView(typeProvider.boolType));
    popRewrite();
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_EXPRESSION,
      whyNotPromoted: flowAnalysis.flow?.whyNotPromoted(node.condition),
    );
    flowAnalysis.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    flowAnalysis.flow?.assert_end();
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _assignmentExpressionResolver.resolve(node as AssignmentExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAugmentedExpression(covariant AugmentedExpressionImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    if (enclosingAugmentation case var augmentation?) {
      var augmentedElement = augmentation.augmentationTarget;
      if (augmentation is PropertyAccessorElementImpl &&
          augmentation.isGetter &&
          augmentedElement is PropertyAccessorElementImpl &&
          augmentedElement.isGetter) {
        node.element = augmentedElement;
        node.recordStaticType(augmentedElement.returnType, resolver: this);
        inferenceLogWriter?.exitExpression(node);
        return;
      }
      if (augmentation is PropertyInducingElementImpl &&
          augmentedElement is PropertyInducingElementImpl) {
        node.element = augmentedElement;
        var augmentedNode =
            libraryResolutionContext._variableNodes[augmentedElement];
        if (augmentedNode != null) {
          if (augmentedNode.initializer case var augmentedInitializer?) {
            node.recordStaticType(augmentedInitializer.staticType!,
                resolver: this);
            inferenceLogWriter?.exitExpression(node);
            return;
          }
        }
      }
    }

    node.recordStaticType(InvalidTypeImpl.instance, resolver: this);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAugmentedInvocation(
    covariant AugmentedInvocationImpl node, {
    DartType contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];

    var augmentation = enclosingAugmentation;
    var augmentationTarget = augmentation?.augmentationTarget;

    void resolveArgumentsOfInvalid() {
      for (var argument in node.arguments.arguments) {
        analyzeExpression(
            argument, SharedTypeSchemaView(InvalidTypeImpl.instance));
        popRewrite();
      }
    }

    // Rewrite invocation of a function-typed getter.
    if (augmentationTarget is PropertyAccessorElementImpl) {
      if (augmentationTarget.isSetter) {
        errorReporter.atToken(
          node.augmentedKeyword,
          CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER,
        );
        node.element = augmentationTarget;
        node.recordStaticType(InvalidTypeImpl.instance, resolver: this);
        resolveArgumentsOfInvalid();
        inferenceLogWriter?.exitExpression(node);
        return;
      }

      var result = typePropertyResolver.resolve(
        receiver: null,
        receiverType: augmentationTarget.returnType,
        name: FunctionElement.CALL_METHOD_NAME,
        propertyErrorEntity: node.augmentedKeyword,
        nameErrorEntity: node.augmentedKeyword,
      );
      var callElement = result.getter;
      var functionType = callElement?.type ?? result.callFunctionType;

      if (functionType == null) {
        errorReporter.atToken(
          node.augmentedKeyword,
          CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION,
        );
        node.element = augmentationTarget;
        node.recordStaticType(InvalidTypeImpl.instance, resolver: this);
        resolveArgumentsOfInvalid();
        inferenceLogWriter?.exitExpression(node);
        return;
      }

      var augmentedExpression = AugmentedExpressionImpl(
        augmentedKeyword: node.augmentedKeyword,
      );
      augmentedExpression.element = augmentationTarget;
      augmentedExpression.setPseudoExpressionStaticType(functionType);
      var rewrite = FunctionExpressionInvocationImpl(
        function: augmentedExpression,
        typeArguments: node.typeArguments,
        argumentList: node.arguments,
      );
      replaceExpression(node, rewrite);
      rewrite.staticElement = callElement;
      flowAnalysis.transferTestData(node, rewrite);
      _resolveRewrittenFunctionExpressionInvocation(rewrite, whyNotPromotedList,
          contextType: contextType);
      inferenceLogWriter?.exitExpression(node);
      return;
    }

    FunctionType? rawType;
    if (augmentationTarget is ExecutableElementImpl) {
      node.element = augmentationTarget;
      rawType = augmentationTarget.type;
    }

    var returnType = AugmentedInvocationInferrer(
      resolver: this,
      node: node,
      argumentList: node.arguments,
      contextType: contextType,
      whyNotPromotedList: whyNotPromotedList,
    ).resolveInvocation(rawType: rawType);

    node.recordStaticType(
        augmentationTarget is ExecutableElementImpl
            ? returnType
            : InvalidTypeImpl.instance,
        resolver: this);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(
        node.expression, SharedTypeSchemaView(_createFutureOr(contextType)));
    popRewrite();
    typeAnalyzer.visitAwaitExpression(node as AwaitExpressionImpl);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _binaryExpressionResolver.resolve(node as BinaryExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitBlock(Block node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  DartType visitBlockFunctionBody(covariant BlockFunctionBodyImpl node,
      {DartType? imposedType}) {
    var oldBodyContext = _bodyContext;
    try {
      _bodyContext = BodyInferenceContext(
          typeSystem: typeSystem, node: node, imposedType: imposedType);
      checkUnreachableNode(node);
      node.visitChildren(this);
      return _finishFunctionBodyInference();
    } finally {
      _bodyContext = oldBodyContext;
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    flowAnalysis.flow?.booleanLiteral(node, node.value);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitBooleanLiteral(node as BooleanLiteralImpl);
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
  void visitCascadeExpression(covariant CascadeExpressionImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(node.target, SharedTypeSchemaView(contextType));
    var targetType = node.target.staticType ?? typeProvider.dynamicType;
    popRewrite();

    flowAnalysis.flow!.cascadeExpression_afterTarget(
        node.target, SharedTypeView(targetType),
        isNullAware: node.isNullAware);

    if (node.isNullAware) {
      flowAnalysis.flow!
          .nullAwareAccess_rightBegin(node.target, SharedTypeView(targetType));
      _unfinishedNullShorts.add(node.nullShortingTermination);
    }

    node.cascadeSections.accept(this);

    typeAnalyzer.visitCascadeExpression(node);

    nullShortingTermination(node);
    flowAnalysis.flow!.cascadeExpression_end(node);
    _insertImplicitCallReference(node, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyCascadeExpression(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    node.visitChildren(this);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    //
    // Continue the class resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitClassDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }

    baseOrFinalTypeVerifier.checkElement(
        node.declaredElement!, node.implementsClause);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitClassTypeAlias(node);
    baseOrFinalTypeVerifier.checkElement(
        node.declaredElement!, node.implementsClause);
  }

  @override
  void visitComment(Comment node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
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
        directives[i].accept(this);
      }
      NodeList<CompilationUnitMember> declarations = node.declarations;
      int declarationCount = declarations.length;
      for (int i = 0; i < declarationCount; i++) {
        declarations[i].accept(this);
      }
      checkIdle();
    } finally {
      stopInferenceLogging();
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    Expression condition = node.condition;
    var flow = flowAnalysis.flow;
    flow?.conditional_conditionBegin();

    analyzeExpression(
        node.condition, SharedTypeSchemaView(typeProvider.boolType));
    condition = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    if (flow != null) {
      flow.conditional_thenBegin(condition, node);
      checkUnreachableNode(node.thenExpression);
    }
    analyzeExpression(node.thenExpression, SharedTypeSchemaView(contextType));
    popRewrite();
    nullSafetyDeadCodeVerifier.flowEnd(node.thenExpression);

    Expression elseExpression = node.elseExpression;

    if (flow != null) {
      flow.conditional_elseBegin(
          node.thenExpression, SharedTypeView(node.thenExpression.typeOrThrow));
      checkUnreachableNode(elseExpression);
      analyzeExpression(elseExpression, SharedTypeSchemaView(contextType));
    } else {
      analyzeExpression(elseExpression, SharedTypeSchemaView(contextType));
    }
    elseExpression = popRewrite()!;

    typeAnalyzer.visitConditionalExpression(node as ConditionalExpressionImpl,
        contextType: contextType);
    if (flow != null) {
      flow.conditional_end(node, SharedTypeView(node.typeOrThrow),
          elseExpression, SharedTypeView(elseExpression.typeOrThrow));
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
    var element = node.declaredElement!;

    flowAnalysis.topLevelDeclaration_enter(node, node.parameters);
    flowAnalysis.executableDeclaration_enter(node, node.parameters,
        isClosure: false);

    var returnType = element.type.returnType;

    var outerFunction = _enclosingFunction;
    var outerAugmentation = enclosingAugmentation;
    try {
      _enclosingFunction = element;
      enclosingAugmentation = element;
      assert(_thisType == null);
      _setupThisType();
      checkUnreachableNode(node);
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType.accept(this);
      node.parameters.accept(this);
      node.initializers.accept(this);
      node.redirectedConstructor?.accept(this);
      node.body.resolve(this, returnType is DynamicType ? null : returnType);
      elementResolver.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      enclosingAugmentation = outerAugmentation;
      _thisType = null;
    }

    if (node.factoryKeyword != null) {
      checkForBodyMayCompleteNormally(
        body: node.body,
        errorNode: node,
      );
    }
    flowAnalysis.executableDeclaration_exit(node.body, false);
    flowAnalysis.topLevelDeclaration_exit();
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitConstructorFieldInitializer(
    covariant ConstructorFieldInitializerImpl node,
  ) {
    var augmented = enclosingClass!.augmented;

    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    var fieldName = node.fieldName;
    var fieldElement = augmented.getField(fieldName.name);
    fieldName.staticElement = fieldElement;
    var fieldType = fieldElement?.type ?? UnknownInferredType.instance;
    var expression = node.expression;
    analyzeExpression(expression, SharedTypeSchemaView(fieldType));
    expression = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(expression);
    if (fieldElement != null) {
      var enclosingConstructor = enclosingFunction as ConstructorElement;
      checkForFieldInitializerNotAssignable(node, fieldElement,
          isConstConstructor: enclosingConstructor.isConst,
          whyNotPromoted: whyNotPromoted);
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.accept(this);
    elementResolver.visitConstructorName(node as ConstructorNameImpl);
  }

  @override
  void visitConstructorReference(covariant ConstructorReferenceImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    _constructorReferenceResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
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
    node.visitChildren(this);
    elementResolver.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(
    covariant DefaultFormalParameterImpl node,
  ) {
    checkUnreachableNode(node);
    node.parameter.accept(this);
    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      analyzeExpression(
          defaultValue,
          SharedTypeSchemaView(
              node.declaredElement?.type ?? UnknownInferredType.instance));
      popRewrite();
    }
    ParameterElement element = node.declaredElement!;

    if (element is DefaultParameterElementImpl && node.isOfLocalFunction) {
      element.constantInitializer = defaultValue;
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);

    var condition = node.condition;

    flowAnalysis.flow?.doStatement_bodyBegin(node);
    node.body.accept(this);

    flowAnalysis.flow?.doStatement_conditionBegin();
    analyzeExpression(condition, SharedTypeSchemaView(typeProvider.boolType));
    condition = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);
    boolExpressionVerifier.checkForNonBoolCondition(condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.doStatement_end(condition);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitDoubleLiteral(node as DoubleLiteralImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  DartType visitEmptyFunctionBody(EmptyFunctionBody node,
      {DartType? imposedType}) {
    if (!resolveOnlyCommentInFunctionBody) {
      checkUnreachableNode(node);
      node.visitChildren(this);
    }
    return imposedType ?? typeProvider.dynamicType;
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantDeclaration(
    covariant EnumConstantDeclarationImpl node,
  ) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    checkUnreachableNode(node);

    var element = node.declaredElement!;
    var initializer = element.constantInitializer;
    if (initializer is InstanceCreationExpression) {
      var constructorName = initializer.constructorName;
      var constructorElement = constructorName.staticElement;
      if (constructorElement != null) {
        node.constructorElement = constructorElement;
        if (constructorElement.isFactory) {
          var constructorName = node.arguments?.constructorSelector?.name;
          var errorTarget = constructorName ?? node.name;
          errorReporter.atEntity(
            errorTarget,
            CompileTimeErrorCode.ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR,
          );
        }
      } else {
        if (constructorName.type.element is EnumElementImpl) {
          var nameNode = node.arguments?.constructorSelector?.name;
          if (nameNode != null) {
            errorReporter.atNode(
              nameNode,
              CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED,
              arguments: [nameNode.name],
            );
          } else {
            errorReporter.atToken(
              node.name,
              CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED,
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
            parameters: constructorElement.parameters,
            errorReporter: errorReporter,
          );
        } else if (definingLibrary.featureSet
            .isEnabled(Feature.enhanced_enums)) {
          var requiredParameterCount = constructorElement.parameters
              .where((e) => e.isRequiredPositional)
              .length;
          if (requiredParameterCount != 0) {
            _reportNotEnoughPositionalArguments(
                token: node.name,
                requiredParameterCount: requiredParameterCount,
                actualArgumentCount: 0,
                nameNode: node,
                errorReporter: errorReporter);
          }
        }
      }
    }

    var arguments = node.arguments;
    if (arguments != null) {
      var argumentList = arguments.argumentList;
      for (var argument in argumentList.arguments) {
        analyzeExpression(
            argument,
            SharedTypeSchemaView(argument.staticParameterElement?.type ??
                UnknownInferredType.instance));
        popRewrite();
      }
      arguments.typeArguments?.accept(this);

      var whyNotPromotedList =
          <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
      checkForArgumentTypesNotAssignableInList(
          argumentList, whyNotPromotedList);
    }

    elementResolver.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    //
    // Continue the enum resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitEnumDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitExportDirective(node);
  }

  @override
  DartType visitExpressionFunctionBody(
      covariant ExpressionFunctionBodyImpl node,
      {DartType? imposedType}) {
    if (resolveOnlyCommentInFunctionBody) {
      return imposedType ?? typeProvider.dynamicType;
    }

    var oldBodyContext = _bodyContext;
    try {
      var bodyContext = _bodyContext = BodyInferenceContext(
          typeSystem: typeSystem, node: node, imposedType: imposedType);

      checkUnreachableNode(node);
      analyzeExpression(
        node.expression,
        SharedTypeSchemaView(
            bodyContext.contextType ?? UnknownInferredType.instance),
      );
      popRewrite();

      flowAnalysis.flow?.handleExit();

      bodyContext.addReturnExpression(node.expression);
      return _finishFunctionBodyInference();
    } finally {
      _bodyContext = oldBodyContext;
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var outerExtension = enclosingExtension;
    try {
      enclosingExtension = node.declaredElement!;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitExtensionDeclaration(node);
    } finally {
      enclosingExtension = outerExtension;
    }
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitExtensionOverride(covariant ExtensionOverrideImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExtensionOverride(node, contextType);
    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
    node.typeArguments?.accept(this);

    var receiverContextType =
        ExtensionMemberResolver(this).computeOverrideReceiverContextType(node);
    InvocationInferrer<ExtensionOverrideImpl>(
            resolver: this,
            node: node,
            argumentList: node.argumentList,
            contextType: UnknownInferredType.instance,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(
            rawType: receiverContextType == null
                ? null
                : FunctionTypeImpl(
                    typeFormals: const [],
                    parameters: [
                        ParameterElementImpl.synthetic(
                            null, receiverContextType, ParameterKind.REQUIRED)
                      ],
                    returnType: DynamicTypeImpl.instance,
                    nullabilitySuffix: NullabilitySuffix.none));

    extensionResolver.resolveOverride(node, whyNotPromotedList);
    inferenceLogWriter?.exitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitExtensionTypeDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    try {
      assert(_thisType == null);
      _setupThisType();
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitFieldDeclaration(node);
    } finally {
      _thisType = null;
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
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
  void visitFormalParameterList(FormalParameterList node) {
    // Formal parameter lists can contain default values, which in turn contain
    // expressions, so we need flow analysis to be available to process those
    // expressions.
    var isTopLevel = flowAnalysis.flow == null;
    if (isTopLevel) {
      flowAnalysis.topLevelDeclaration_enter(node, null);
    }
    checkUnreachableNode(node);
    node.visitChildren(this);
    if (isTopLevel) {
      flowAnalysis.topLevelDeclaration_exit();
    }
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
    bool isLocal = node.parent is FunctionDeclarationStatement;
    var element = node.declaredElement!;

    if (isLocal) {
      flowAnalysis.flow!.functionExpression_begin(node);
    } else {
      flowAnalysis.topLevelDeclaration_enter(
          node, node.functionExpression.parameters);
    }
    flowAnalysis.executableDeclaration_enter(
      node,
      node.functionExpression.parameters,
      isClosure: isLocal,
    );

    var functionType = node.declaredElement!.type;

    var outerFunction = _enclosingFunction;
    var outerAugmentation = enclosingAugmentation;
    try {
      _enclosingFunction = element;
      if (!isLocal) {
        if (element case AugmentableElement augmentation) {
          enclosingAugmentation = augmentation;
        }
      }
      checkUnreachableNode(node);
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      analyzeExpression(
          node.functionExpression, SharedTypeSchemaView(functionType));
      popRewrite();
      elementResolver.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      enclosingAugmentation = outerAugmentation;
    }

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
      flowAnalysis.topLevelDeclaration_exit();
    }
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    var outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    _functionExpressionResolver.resolve(node, contextType: contextType);
    insertGenericFunctionInstantiation(node, contextType: contextType);

    _enclosingFunction = outerFunction;
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(
    covariant FunctionExpressionInvocationImpl node, {
    DartType contextType = UnknownInferredType.instance,
  }) {
    inferenceLogWriter?.enterExpression(node, contextType);
    analyzeExpression(
        node.function, SharedTypeSchemaView(UnknownInferredType.instance));
    node.function = popRewrite()!;

    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
    _functionExpressionInvocationResolver.resolve(node, whyNotPromotedList,
        contextType: contextType);
    nullShortingTermination(node);
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
    _insertImplicitCallReference(replacement, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitFunctionReference(FunctionReference node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    _functionReferenceResolver.resolve(node as FunctionReferenceImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
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
        expression: node.expression,
        pattern: guardedPattern.pattern,
        variables: guardedPattern.variables,
        guard: guardedPattern.whenClause?.expression,
        ifTrue: node.thenElement,
        ifFalse: node.elseElement,
        context: context,
      );
      // Stack: (Expression, Guard)
      popRewrite(); // guard
      popRewrite()!; // expression
    } else {
      analyzeIfElement(
        node: node,
        condition: node.expression,
        ifTrue: node.thenElement,
        ifFalse: node.elseElement,
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
        node.expression,
        guardedPattern.pattern,
        guardedPattern.whenClause?.expression,
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
        node.expression,
        node.thenStatement,
        node.elseStatement,
      );
    }
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    checkUnreachableNode(node);
    analyzeExpression(
        node.expression, SharedTypeSchemaView(UnknownInferredType.instance));
    popRewrite();
    node.typeArguments?.accept(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitImportDirective(node as ImportDirectiveImpl);
  }

  @override
  void visitIndexExpression(covariant IndexExpressionImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);

    var target = node.target;
    if (target != null) {
      analyzeExpression(
          target, SharedTypeSchemaView(UnknownInferredType.instance));
      popRewrite();
    }
    var targetType = node.realTarget.staticType;

    startNullAwareIndexExpression(node);

    var result = _propertyElementResolver.resolveIndexExpression(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;
    node.staticElement = element as MethodElement?;

    analyzeExpression(
        node.index, SharedTypeSchemaView(result.indexContextType));
    popRewrite();
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(node.index);
    checkIndexExpressionIndex(
      node.index,
      readElement: result.readElement as ExecutableElement?,
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
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);

    nullShortingTermination(node);
    _insertImplicitCallReference(replacement, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyIndexExpression(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitInstanceCreationExpression(
      covariant InstanceCreationExpressionImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _instanceCreationExpressionResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitIntegerLiteral(node as IntegerLiteralImpl,
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(covariant IsExpressionImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);

    analyzeExpression(
        node.expression, SharedTypeSchemaView(UnknownInferredType.instance));
    popRewrite();

    node.type.accept(this);

    typeAnalyzer.visitIsExpression(node);
    flowAnalysis.isExpression(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitLabel(Label node) {}

  @override
  void visitLabeledStatement(LabeledStatement node) {
    inferenceLogWriter?.enterStatement(node);
    flowAnalysis.labeledStatement_enter(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    flowAnalysis.labeledStatement_exit(node);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitListLiteral(covariant ListLiteralImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveListLiteral(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node,
      {CollectionLiteralContext? context}) {
    inferenceLogWriter?.enterElement(node);
    checkUnreachableNode(node);

    // If the key is null-aware, the context of the expression under `?` should
    // be changed to the nullable version of the downwards context.
    var keyTypeContext = context?.keyType;
    if (keyTypeContext != null && node.keyQuestion != null) {
      keyTypeContext = typeSystem.makeNullable(keyTypeContext);
    }
    var keyType = analyzeExpression(node.key,
        SharedTypeSchemaView(keyTypeContext ?? UnknownInferredType.instance));
    popRewrite();

    flowAnalysis.flow?.nullAwareMapEntry_valueBegin(node.key, keyType,
        isKeyNullAware: node.keyQuestion != null);

    // If the value is null-aware, the context of the expression under `?`
    // should be changed to the nullable version of the downwards context.
    var valueTypeContext = context?.valueType;
    if (valueTypeContext != null && node.valueQuestion != null) {
      valueTypeContext = typeSystem.makeNullable(valueTypeContext);
    }
    analyzeExpression(node.value,
        SharedTypeSchemaView(valueTypeContext ?? UnknownInferredType.instance));
    popRewrite();

    flowAnalysis.flow
        ?.nullAwareMapEntry_end(isKeyNullAware: node.keyQuestion != null);
    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var element = node.declaredElement!;

    flowAnalysis.topLevelDeclaration_enter(node, node.parameters);
    flowAnalysis.executableDeclaration_enter(node, node.parameters,
        isClosure: false);

    DartType returnType = element.returnType;

    var outerFunction = _enclosingFunction;
    var outerAugmentation = enclosingAugmentation;
    try {
      _enclosingFunction = element;
      if (element case AugmentableElement augmentation) {
        enclosingAugmentation = augmentation;
      }
      assert(_thisType == null);
      _setupThisType();
      checkUnreachableNode(node);
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      node.body.resolve(this, returnType is DynamicType ? null : returnType);
      elementResolver.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
      enclosingAugmentation = outerAugmentation;
      _thisType = null;
    }

    if (!node.isSetter) {
      checkForBodyMayCompleteNormally(
        body: node.body,
        errorNode: node.name,
      );
    }
    flowAnalysis.executableDeclaration_exit(node.body, false);
    flowAnalysis.topLevelDeclaration_exit();
    nullSafetyDeadCodeVerifier.flowEnd(node);
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
    var target = node.target;
    target?.accept(this);
    target = node.target;

    if (node.isNullAware) {
      var flow = flowAnalysis.flow;
      if (flow != null) {
        if (target is SimpleIdentifierImpl &&
            target.staticElement is InterfaceElement) {
          // `?.` to access static methods is equivalent to `.`, so do nothing.
        } else {
          flow.nullAwareAccess_rightBegin(
              target,
              SharedTypeView(
                  node.realTarget!.staticType ?? typeProvider.dynamicType));
          _unfinishedNullShorts.add(node.nullShortingTermination);
        }
      }
    }

    node.typeArguments?.accept(this);
    var functionRewrite = elementResolver.visitMethodInvocation(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);

    if (functionRewrite != null) {
      _resolveRewrittenFunctionExpressionInvocation(
          functionRewrite, whyNotPromotedList,
          contextType: contextType);
      nullShortingTermination(node, discardType: true);
    } else {
      nullShortingTermination(node);
    }
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
    _insertImplicitCallReference(replacement, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyMethodInvocation(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    //
    // Continue the class resolution.
    //
    var outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement!;
      checkUnreachableNode(node);
      node.visitChildren(this);
      elementResolver.visitMixinDeclaration(node);
    } finally {
      enclosingClass = outerType;
    }

    baseOrFinalTypeVerifier.checkElement(
        node.declaredElement!, node.implementsClause);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.name.accept(this);
    analyzeExpression(node.expression, SharedTypeSchemaView(contextType));
    popRewrite();
    typeAnalyzer.visitNamedExpression(node as NamedExpressionImpl);
    // Any "why not promoted" information that flow analysis had associated with
    // `node.expression` now needs to be forwarded to `node`, so that when
    // `visitArgumentList` iterates through the arguments, it will find it.
    flowAnalysis.flow?.forwardExpression(node, node.expression);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitNamedType(NamedType node) {
    // All TypeName(s) are already resolved, so we don't resolve it here.
    // But there might be type arguments with Expression(s), such as default
    // values for formal parameters of GenericFunctionType(s). These are
    // invalid, but if they exist, they should be resolved.
    node.typeArguments?.accept(this);
  }

  @override
  void visitNativeClause(NativeClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  DartType visitNativeFunctionBody(NativeFunctionBody node,
      {DartType? imposedType}) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    return imposedType ?? typeProvider.dynamicType;
  }

  @override
  void visitNullAwareElement(NullAwareElement node,
      {CollectionLiteralContext? context}) {
    inferenceLogWriter?.enterElement(node);

    var elementType = context?.elementType;
    if (elementType != null) {
      elementType = typeSystem.makeNullable(elementType);
    }

    analyzeExpression(node.value,
        SharedTypeSchemaView(elementType ?? UnknownInferredType.instance));
    popRewrite();

    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitNullLiteral(NullLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    node.visitChildren(this);
    typeAnalyzer.visitNullLiteral(node as NullLiteralImpl);
    flowAnalysis.flow?.nullLiteral(node, SharedTypeView(node.typeOrThrow));
    checkUnreachableNode(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(node.expression, SharedTypeSchemaView(contextType));
    popRewrite();
    typeAnalyzer
        .visitParenthesizedExpression(node as ParenthesizedExpressionImpl);
    flowAnalysis.flow?.parenthesizedExpression(node, node.expression);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitPartOfDirective(node);
  }

  @override
  void visitPatternAssignment(covariant PatternAssignmentImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var analysisResult =
        analyzePatternAssignment(node, node.pattern, node.expression);
    node.patternTypeSchema =
        analysisResult.patternSchema.unwrapTypeSchemaView();
    node.recordStaticType(analysisResult.resolveShorting().unwrapTypeView(),
        resolver: this);
    popRewrite(); // expression
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    var patternSchema = analyzePatternVariableDeclaration(
            node, node.pattern, node.expression,
            isFinal: node.keyword.keyword == Keyword.FINAL)
        .patternSchema;
    node.patternTypeSchema = patternSchema.unwrapTypeSchemaView();
    popRewrite(); // expression
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.declaration.accept(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _postfixExpressionResolver.resolve(node as PostfixExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    var rewrittenPropertyAccess =
        _prefixedIdentifierResolver.resolve(node, contextType: contextType);
    if (rewrittenPropertyAccess != null) {
      inferenceLogWriter?.exitExpression(node, reanalyze: true);
      visitPropertyAccess(rewrittenPropertyAccess, contextType: contextType);
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
      return;
    }
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _prefixExpressionResolver.resolve(node as PrefixExpressionImpl,
        contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitPropertyAccess(covariant PropertyAccessImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);

    var target = node.target;
    if (target != null) {
      analyzeExpression(
          target, SharedTypeSchemaView(UnknownInferredType.instance));
      popRewrite();
    }

    startNullAwarePropertyAccess(node);

    var result = _propertyElementResolver.resolvePropertyAccess(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;

    var propertyName = node.propertyName;
    propertyName.staticElement = element;

    DartType type;
    if (element is MethodElement) {
      type = element.type;
    } else if (element is PropertyAccessorElement && element.isGetter) {
      type = result.getType!;
    } else if (result.functionTypeCallType != null) {
      type = result.functionTypeCallType!;
    } else if (result.recordField != null) {
      type = result.recordField!.type;
    } else if (result.atDynamicTarget) {
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
      type = inferenceHelper.inferTearOff(node, propertyName, type,
          contextType: contextType);
    }

    propertyName.setPseudoExpressionStaticType(type);
    node.recordStaticType(type, resolver: this);
    var replacement =
        insertGenericFunctionInstantiation(node, contextType: contextType);

    nullShortingTermination(node);
    _insertImplicitCallReference(replacement, contextType: contextType);
    nullSafetyDeadCodeVerifier.verifyPropertyAccess(node);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitRecordLiteral(
    covariant RecordLiteralImpl node, {
    DartType contextType = UnknownInferredType.instance,
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
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.visitChildren(this);
    elementResolver.visitRecordTypeAnnotationNamedField(node);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.visitChildren(this);
    elementResolver.visitRecordTypeAnnotationPositionalField(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
    elementResolver.visitRedirectingConstructorInvocation(
        node as RedirectingConstructorInvocationImpl);
    InvocationInferrer<RedirectingConstructorInvocationImpl>(
            resolver: this,
            node: node,
            argumentList: node.argumentList,
            contextType: UnknownInferredType.instance,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: node.staticElement?.type);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {}

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitRepresentationDeclaration(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitRethrowExpression(node as RethrowExpressionImpl);
    flowAnalysis.flow?.handleExit();
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    var expression = node.expression;
    if (expression != null) {
      analyzeExpression(
        expression,
        SharedTypeSchemaView(
            bodyContext?.contextType ?? UnknownInferredType.instance),
      );
      // Pick up the expression again in case it was rewritten.
      expression = popRewrite();
    }

    bodyContext?.addReturnExpression(expression);
    flowAnalysis.flow?.handleExit();
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveSetOrMapLiteral(node,
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    _simpleIdentifierResolver.resolve(node, contextType: contextType);
    _insertImplicitCallReference(
        insertGenericFunctionInstantiation(node, contextType: contextType),
        contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitSimpleStringLiteral(node as SimpleStringLiteralImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSpreadElement(SpreadElement node,
      {CollectionLiteralContext? context}) {
    inferenceLogWriter?.enterElement(node);
    var iterableType = context?.iterableType;
    if (iterableType != null && node.isNullAware) {
      iterableType = typeSystem.makeNullable(iterableType);
    }
    checkUnreachableNode(node);
    analyzeExpression(node.expression,
        SharedTypeSchemaView(iterableType ?? UnknownInferredType.instance));
    popRewrite();

    if (!node.isNullAware) {
      nullableDereferenceVerifier.expression(
        CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD,
        node.expression,
      );
    }

    inferenceLogWriter?.exitElement(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
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
    var whyNotPromotedList =
        <Map<SharedTypeView<DartType>, NonPromotionReason> Function()>[];
    elementResolver.visitSuperConstructorInvocation(
        node as SuperConstructorInvocationImpl);
    InvocationInferrer<SuperConstructorInvocationImpl>(
            resolver: this,
            node: node,
            argumentList: node.argumentList,
            contextType: UnknownInferredType.instance,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: node.staticElement?.type);
    checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  @override
  void visitSuperExpression(SuperExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitSuperExpression(node);
    typeAnalyzer.visitSuperExpression(node as SuperExpressionImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitSwitchExpression(
    covariant SwitchExpressionImpl node, {
    DartType contextType = UnknownInferredType.instance,
  }) {
    analyzeExpression(node, SharedTypeSchemaView(contextType));
    popRewrite();
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    inferenceLogWriter?.enterStatement(node);
    // Stack: ()
    checkUnreachableNode(node);

    var previousExhaustiveness = legacySwitchExhaustiveness;
    analyzeSwitchStatement(node, node.expression, node.memberGroups.length);
    // Stack: (Expression)
    popRewrite();
    // Stack: ()
    legacySwitchExhaustiveness = previousExhaustiveness;
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitSymbolLiteral(node as SymbolLiteralImpl);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitThisExpression(ThisExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    typeAnalyzer.visitThisExpression(node as ThisExpressionImpl);
    _insertImplicitCallReference(node, contextType: contextType);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    analyzeExpression(
        node.expression, SharedTypeSchemaView(typeProvider.objectType));
    popRewrite();
    typeAnalyzer.visitThrowExpression(node as ThrowExpressionImpl);
    flowAnalysis.flow?.handleExit();
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
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
    body.accept(this);
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    nullSafetyDeadCodeVerifier.tryStatementEnter(node);
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);

      var catchLength = catchClauses.length;
      for (var i = 0; i < catchLength; ++i) {
        var catchClause = catchClauses[i];
        nullSafetyDeadCodeVerifier.verifyCatchClause(catchClause);
        flow.tryCatchStatement_catchBegin(
          catchClause.exceptionParameter?.declaredElement,
          catchClause.stackTraceParameter?.declaredElement,
        );
        catchClause.accept(this);
        flow.tryCatchStatement_catchEnd();
        nullSafetyDeadCodeVerifier.flowEnd(catchClause.body);
      }

      flow.tryCatchStatement_end();
    }
    nullSafetyDeadCodeVerifier.tryStatementExit(node);

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      finallyBlock.accept(this);
      flow.tryFinallyStatement_end();
    }
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteral(covariant TypeLiteralImpl node,
      {DartType contextType = UnknownInferredType.instance}) {
    inferenceLogWriter?.enterExpression(node, contextType);
    checkUnreachableNode(node);
    node.visitChildren(this);
    node.recordStaticType(typeProvider.typeType, resolver: this);
    inferenceLogWriter?.exitExpression(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(covariant VariableDeclarationImpl node) {
    var element = node.declaredElement!;

    var outerAugmentation = enclosingAugmentation;
    try {
      if (element case AugmentableElement augmentation) {
        enclosingAugmentation = augmentation;
      }
      libraryResolutionContext._variableNodes[element] = node;
      _variableDeclarationResolver.resolve(node);
    } finally {
      enclosingAugmentation = outerAugmentation;
    }

    var initializer = node.initializer;
    if (initializer != null) {
      var parent = node.parent as VariableDeclarationList;
      var declaredType = parent.type;
      var initializerStaticType = initializer.typeOrThrow;
      flowAnalysis.flow?.initialize(element as PromotableElement,
          SharedTypeView(initializerStaticType), initializer,
          isFinal: parent.isFinal,
          isLate: parent.isLate,
          isImplicitlyTyped: declaredType == null);
    }

    _checkTopLevelCycle(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    flowAnalysis.variableDeclarationList(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    elementResolver.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);
    node.visitChildren(this);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    inferenceLogWriter?.enterStatement(node);
    checkUnreachableNode(node);

    Expression condition = node.condition;

    flowAnalysis.flow?.whileStatement_conditionBegin(node);
    analyzeExpression(condition, SharedTypeSchemaView(typeProvider.boolType));
    condition = popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(condition);

    boolExpressionVerifier.checkForNonBoolCondition(node.condition,
        whyNotPromoted: whyNotPromoted);

    flowAnalysis.flow?.whileStatement_bodyBegin(node, condition);
    node.body.accept(this);
    flowAnalysis.flow?.whileStatement_end();
    nullSafetyDeadCodeVerifier.flowEnd(node.body);
    // TODO(brianwilkerson): If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
    inferenceLogWriter?.exitStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
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
    var parent = errorNode.parent?.parent;
    if (parent is! ArgumentList) {
      return;
    }
    var invocation = parent.parent;
    if (invocation is! MethodInvocation) {
      return;
    }
    var targetType = invocation.realTarget?.staticType;
    if (invocation.methodName.name == 'catchError' &&
        targetType is InterfaceType) {
      var instanceOfFuture =
          targetType.asInstanceOf(typeProvider.futureElement);
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

        errorReporter.atToken(
          errorNode.block.leftBracket,
          WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR,
          arguments: [returnTypeBase],
        );
      }
    }
  }

  void _checkTopLevelCycle(VariableDeclaration node) {
    var element = node.declaredElement;
    if (element is! PropertyInducingElementImpl) {
      return;
    }
    // Errors on const are reported separately with
    // [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT].
    if (element.isConst) {
      return;
    }
    var error = element.typeInferenceError;
    if (error == null) {
      return;
    }
    if (error.kind == TopLevelInferenceErrorKind.dependencyCycle) {
      var argumentsText = error.arguments.join(', ');
      errorReporter.atToken(
        node.name,
        CompileTimeErrorCode.TOP_LEVEL_CYCLE,
        arguments: [node.name.lexeme, argumentsText],
      );
    }
  }

  /// Creates a union of `T | Future<T>`, unless `T` is already a
  /// future-union, in which case it simply returns `T`.
  DartType _createFutureOr(DartType type) {
    if (type.isDartAsyncFutureOr) {
      return type;
    }
    return typeProvider.futureOrType(type);
  }

  /// Helper function used to print information to the console in debug mode.
  /// This method returns `true` so that it can be conveniently called inside of
  /// an `assert` statement.
  bool _debugPrint(String s) {
    print(s);
    return true;
  }

  DartType _finishFunctionBodyInference() {
    var flow = flowAnalysis.flow;

    return _bodyContext!.computeInferredReturnType(
      endOfBlockIsReachable: flow == null || flow.isReachable,
    );
  }

  /// Infers type arguments corresponding to [typeParameters] used it the
  /// [declaredType], so that thr resulting type is a subtype of [contextType].
  List<DartType> _inferTypeArguments({
    required List<TypeParameterElement> typeParameters,
    required AstNode errorNode,
    required DartType declaredType,
    required DartType contextType,
    required AstNode? nodeForTesting,
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
    inferrer.constrainReturnType(declaredType, contextType,
        nodeForTesting: nodeForTesting);
    return inferrer.chooseFinalTypes();
  }

  /// If `expression` should be treated as `expression.call`, inserts an
  /// [ImplicitCallReference] node which wraps [expression].
  void _insertImplicitCallReference(ExpressionImpl expression,
      {required DartType contextType}) {
    var parent = expression.parent;
    if (_shouldSkipImplicitCallReferenceDueToForm(expression, parent)) {
      return;
    }
    var staticType = expression.staticType;
    if (staticType == null) {
      return;
    }
    DartType context;
    if (parent is AssignmentExpression) {
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
        callMethodType.typeFormals.isNotEmpty &&
        context is FunctionType) {
      typeArgumentTypes = typeSystem.inferFunctionTypeInstantiation(
        context,
        callMethodType,
        errorReporter: errorReporter,
        errorNode: expression,
        // If the constructor-tearoffs feature is enabled, then so is
        // generic-metadata.
        genericMetadataIsEnabled: true,
        inferenceUsingBoundsIsEnabled:
            _featureSet.isEnabled(Feature.inference_using_bounds),
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
      expression: expression,
      staticElement: callMethod,
      typeArguments: null,
      typeArgumentTypes: typeArgumentTypes,
    );
    replaceExpression(expression, callReference, parent: parent);

    callReference.setPseudoExpressionStaticType(callMethodType);
  }

  /// Continues resolution of a [FunctionExpressionInvocation] that was created
  /// from a rewritten [MethodInvocation]. The target function is already
  /// resolved.
  ///
  /// The specification says that `target.getter()` should be treated as an
  /// ordinary method invocation. So, we need to perform the same null shorting
  /// as for method invocations.
  void _resolveRewrittenFunctionExpressionInvocation(
      FunctionExpressionInvocation node,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType contextType}) {
    var function = node.function;

    if (function is PropertyAccess && function.isNullAware) {
      var target = function.target;
      if (target is SimpleIdentifier &&
          target.staticElement is InterfaceElement) {
        // `?.` to access static methods is equivalent to `.`, so do nothing.
      } else {
        flowAnalysis.flow!.nullAwareAccess_rightBegin(
            function,
            SharedTypeView(
                function.realTarget.staticType ?? typeProvider.dynamicType));
        _unfinishedNullShorts.add(node.nullShortingTermination);
      }
    }

    _functionExpressionInvocationResolver.resolve(
        node as FunctionExpressionInvocationImpl, whyNotPromotedList,
        contextType: contextType);

    nullShortingTermination(node);
  }

  void _setupThisType() {
    var enclosingClass = this.enclosingClass;
    if (enclosingClass != null) {
      var augmented = enclosingClass.augmented;
      _thisType = augmented.declaration.thisType;
    } else {
      var enclosingExtension = this.enclosingExtension;
      if (enclosingExtension != null) {
        _thisType = enclosingExtension.extendedType;
      }
    }
  }

  bool _shouldSkipImplicitCallReferenceDueToForm(
      Expression expression, AstNode? parent) {
    while (parent is ParenthesizedExpression) {
      expression = parent;
      parent = expression.parent;
    }
    if (parent is CascadeExpression && parent.target == expression) {
      // Do not perform an "implicit tear-off conversion" here. It should only
      // be performed on [parent]. See
      // https://github.com/dart-lang/language/issues/1873.
      return true;
    }
    if (parent is ConditionalExpression &&
        (parent.thenExpression == expression ||
            parent.elseExpression == expression)) {
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

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments.
  ///
  /// Returns the parameters that correspond to the arguments. If no parameter
  /// matched an argument, that position will be `null` in the list.
  static List<ParameterElement?> resolveArgumentsToParameters({
    required ArgumentList argumentList,
    required List<ParameterElement> parameters,
    ErrorReporter? errorReporter,
    ConstructorDeclaration? enclosingConstructor,
  }) {
    int requiredParameterCount = 0;
    int unnamedParameterCount = 0;
    List<ParameterElement> unnamedParameters = <ParameterElement>[];
    Map<String, ParameterElement>? namedParameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
        requiredParameterCount++;
      } else if (parameter.isOptionalPositional) {
        unnamedParameters.add(parameter);
        unnamedParameterCount++;
      } else {
        namedParameters ??= HashMap<String, ParameterElement>();
        namedParameters[parameter.name] = parameter;
      }
    }
    int unnamedIndex = 0;
    NodeList<Expression> arguments = argumentList.arguments;
    int argumentCount = arguments.length;
    List<ParameterElement?> resolvedParameters =
        List<ParameterElement?>.filled(argumentCount, null);
    int positionalArgumentCount = 0;
    bool noBlankArguments = true;
    Expression? firstUnresolvedArgument;
    Expression? lastPositionalArgument;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is! NamedExpression) {
        if (argument is SimpleIdentifier && argument.name.isEmpty) {
          noBlankArguments = false;
        }
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        } else {
          firstUnresolvedArgument ??= argument;
        }
        lastPositionalArgument = argument;
      }
    }

    Set<String>? usedNames;
    if (enclosingConstructor != null) {
      var result = verifySuperFormalParameters(
        constructor: enclosingConstructor,
        hasExplicitPositionalArguments: positionalArgumentCount != 0,
        errorReporter: errorReporter,
      );
      positionalArgumentCount += result.positionalArgumentCount;
      if (result.namedArgumentNames.isNotEmpty) {
        usedNames = result.namedArgumentNames.toSet();
      }
    }

    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpressionImpl) {
        var nameNode = argument.name.label;
        String name = nameNode.name;
        var element = namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          errorReporter?.atNode(
            nameNode,
            CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER,
            arguments: [name],
          );
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        usedNames ??= <String>{};
        if (!usedNames.add(name)) {
          errorReporter?.atNode(
            nameNode,
            CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT,
            arguments: [name],
          );
        }
      }
    }

    if (positionalArgumentCount < requiredParameterCount && noBlankArguments) {
      var parent = argumentList.parent;
      if (errorReporter != null && parent != null) {
        var token = lastPositionalArgument?.endToken.next ??
            argumentList.leftParenthesis.next ??
            argumentList.rightParenthesis;
        _reportNotEnoughPositionalArguments(
            token: token,
            requiredParameterCount: requiredParameterCount,
            actualArgumentCount: positionalArgumentCount,
            nameNode: parent,
            errorReporter: errorReporter);
      }
    } else if (positionalArgumentCount > unnamedParameterCount &&
        noBlankArguments) {
      ErrorCode errorCode;
      int namedParameterCount = namedParameters?.length ?? 0;
      int namedArgumentCount = usedNames?.length ?? 0;
      if (namedParameterCount > namedArgumentCount) {
        errorCode =
            CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED;
      } else {
        errorCode = CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS;
      }
      if (firstUnresolvedArgument != null) {
        errorReporter?.atNode(
          firstUnresolvedArgument,
          errorCode,
          arguments: [unnamedParameterCount, positionalArgumentCount],
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

  /// Report [CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS] or one of
  /// its derivatives at the specified [token], considering the name of the
  /// [nameNode].
  static void _reportNotEnoughPositionalArguments(
      {required Token token,
      required int requiredParameterCount,
      required int actualArgumentCount,
      required AstNode nameNode,
      required ErrorReporter errorReporter}) {
    String? name;
    if (nameNode is InstanceCreationExpression) {
      var constructorName = nameNode.constructorName;
      name = constructorName.name?.name ??
          '${constructorName.type.name2.lexeme}.new';
    } else if (nameNode is RedirectingConstructorInvocation) {
      name = nameNode.constructorName?.name;
      if (name == null) {
        var staticElement = nameNode.staticElement;
        if (staticElement != null) {
          name = '${staticElement.returnType.getDisplayString()}.new';
        }
      }
    } else if (nameNode is SuperConstructorInvocation) {
      name = nameNode.constructorName?.name;
      if (name == null) {
        var staticElement = nameNode.staticElement;
        if (staticElement != null) {
          name = '${staticElement.returnType.getDisplayString()}.new';
        }
      }
    } else if (nameNode is MethodInvocation) {
      name = nameNode.methodName.name;
    } else if (nameNode is FunctionExpressionInvocation) {
      var function = nameNode.function;
      if (function is SimpleIdentifier) {
        name = function.name;
      }
    } else if (nameNode is EnumConstantArguments) {
      var parent = nameNode.parent;
      if (parent is EnumConstantDeclaration) {
        var declaredElement = parent.declaredElement!;
        name = declaredElement.type.getDisplayString();
      }
    } else if (nameNode is EnumConstantDeclaration) {
      var declaredElement = nameNode.declaredElement!;
      name = declaredElement.type.getDisplayString();
    } else if (nameNode is Annotation) {
      var nameNodeName = nameNode.name;
      name = nameNodeName is PrefixedIdentifier
          ? nameNodeName.identifier.name
          : '${nameNodeName.name}.new';
    } else {
      throw UnimplementedError('(${nameNode.runtimeType}) $nameNode');
    }

    var isPlural = requiredParameterCount > 1;
    var arguments = <Object>[];
    if (isPlural) {
      arguments.add(requiredParameterCount);
      arguments.add(actualArgumentCount);
    }
    ErrorCode errorCode;
    if (name == null) {
      errorCode = isPlural
          ? CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL
          : CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR;
    } else {
      errorCode = isPlural
          ? CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL
          : CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR;
      arguments.add(name);
    }
    errorReporter.atToken(
      token,
      errorCode,
      arguments: arguments,
    );
  }
}

/// Instances of the class `ScopeResolverVisitor` are used to resolve
/// [SimpleIdentifier]s to declarations using scoping rules.
///
// TODO(paulberry): migrate the responsibility for all scope resolution into
// this visitor.
class ScopeResolverVisitor extends UnifyingAstVisitor<void> {
  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl definingLibrary;

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  /// The error reporter that will be informed of any errors that are found
  /// during resolution.
  final ErrorReporter errorReporter;

  /// The scope used to resolve identifiers.
  Scope nameScope;

  /// The scope of libraries imported by `@docImport`s.
  final DocImportScope _docImportScope;

  /// The scope used to resolve unlabeled `break` and `continue` statements.
  ImplicitLabelScope _implicitLabelScope = ImplicitLabelScope.ROOT;

  /// The scope used to resolve labels for `break` and `continue` statements, or
  /// `null` if no labels have been defined in the current context.
  LabelScope? labelScope;

  /// The container with information about local variables.
  final LocalVariableInfo _localVariableInfo = LocalVariableInfo();

  /// If the current function is contained within a closure (a local function or
  /// function expression inside another executable declaration), the element
  /// representing the closure; otherwise `null`.
  ExecutableElement? _enclosingClosure;

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// [definingLibrary] is the element for the library containing the node being
  /// visited.
  /// [source] is the source representing the compilation unit containing the
  /// node being visited.
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.
  /// [docImportLibraries] are the `@docImport` imported elements of this node's
  /// library.
  ScopeResolverVisitor(
    this.definingLibrary,
    this.source,
    this.typeProvider,
    AnalysisErrorListener errorListener, {
    required this.nameScope,
    List<LibraryElement> docImportLibraries = const [],
  })  : errorReporter = ErrorReporter(errorListener, source),
        _docImportScope = DocImportScope(nameScope, docImportLibraries);

  /// Return the implicit label scope in which the current node is being
  /// resolved.
  ImplicitLabelScope get implicitLabelScope => _implicitLabelScope;

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var element = node.element;
    if (element is PromotableElement) {
      _localVariableInfo.potentiallyMutatedInScope.add(element);
    }
  }

  @override
  void visitBlock(covariant BlockImpl node) {
    _withDeclaredLocals(node, node.statements, () {
      super.visitBlock(node);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    ImplicitLabelScope implicitOuterScope = _implicitLabelScope;
    try {
      _implicitLabelScope = ImplicitLabelScope.ROOT;
      super.visitBlockFunctionBody(node);
    } finally {
      _implicitLabelScope = implicitOuterScope;
    }
  }

  @override
  void visitBreakStatement(covariant BreakStatementImpl node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, false);
  }

  @override
  void visitCatchClause(CatchClause node) {
    var exception = node.exceptionParameter;
    if (exception != null) {
      Scope outerScope = nameScope;
      try {
        nameScope = LocalScope(nameScope);
        _define(exception.declaredElement!);
        var stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          _define(stackTrace.declaredElement!);
        }
        super.visitCatchClause(node);
      } finally {
        nameScope = outerScope;
      }
    } else {
      super.visitCatchClause(node);
    }
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      node.nameScope = nameScope;
      node.typeParameters?.accept(this);
      node.extendsClause?.accept(this);
      node.withClause?.accept(this);
      node.implementsClause?.accept(this);
      node.nativeClause?.accept(this);

      nameScope = InstanceScope(nameScope, element);
      _visitDocumentationComment(node.documentationComment);
      node.members.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement!;
      nameScope = InstanceScope(
        TypeParameterScope(nameScope, element.typeParameters),
        element,
      );
      _visitDocumentationComment(node.documentationComment);
      node.typeParameters?.accept(this);
      node.superclass.accept(this);
      node.withClause.accept(this);
      node.implementsClause?.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitCompilationUnit(covariant CompilationUnitImpl node) {
    node.nameScope = nameScope;
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    node.body.localVariableInfo = _localVariableInfo;
    Scope outerScope = nameScope;
    try {
      ConstructorElement element = node.declaredElement!;

      node.metadata.accept(this);
      node.returnType.accept(this);
      node.parameters.accept(this);

      try {
        nameScope = ConstructorInitializerScope(
          nameScope,
          element,
        );
        node.initializers.accept(this);
        _visitDocumentationComment(node.documentationComment);
      } finally {
        nameScope = outerScope;
      }

      node.redirectedConstructor?.accept(this);

      nameScope = FormalParameterScope(
        nameScope,
        element.parameters,
      );
      node.body.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitContinueStatement(covariant ContinueStatementImpl node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, true);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _define(node.declaredElement!);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      _visitStatementInScope(node.body);
      node.condition.accept(this);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  @override
  void visitEnumConstantDeclaration(
      covariant EnumConstantDeclarationImpl node) {
    node.metadata.accept(this);
    _visitDocumentationComment(node.documentationComment);
    node.arguments?.accept(this);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      node.nameScope = nameScope;
      node.typeParameters?.accept(this);
      node.withClause?.accept(this);
      node.implementsClause?.accept(this);

      nameScope = InstanceScope(nameScope, element);
      _visitDocumentationComment(node.documentationComment);
      node.constants.accept(this);
      node.members.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitExpressionFunctionBody(covariant ExpressionFunctionBodyImpl node) {
    node.nameScope = nameScope;
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      node.nameScope = nameScope;
      node.typeParameters?.accept(this);
      node.onClause?.accept(this);

      nameScope = ExtensionScope(nameScope, element);
      _visitDocumentationComment(node.documentationComment);
      node.members.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      node.nameScope = nameScope;
      node.typeParameters?.accept(this);
      node.representation.accept(this);
      node.implementsClause?.accept(this);

      nameScope = InstanceScope(nameScope, element);
      _visitDocumentationComment(node.documentationComment);
      node.members.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    node.metadata.accept(this);
    _visitDocumentationComment(node.documentationComment);
    node.fields.accept(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    // We visit the iterator before the loop variable because the loop variable
    // cannot be in scope while visiting the iterator.
    node.iterable.accept(this);
    node.loopVariable.accept(this);
  }

  @override
  void visitForEachPartsWithPattern(
    covariant ForEachPartsWithPatternImpl node,
  ) {
    // We visit the iterator before the pattern because the pattern variables
    // cannot be in scope while visiting the iterator.
    node.iterable.accept(this);

    for (var variable in node.variables) {
      _define(variable);
    }

    node.pattern.accept(this);
  }

  @override
  void visitForElement(covariant ForElementImpl node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = LocalScope(nameScope);
      node.nameScope = nameScope;
      node.forLoopParts.accept(this);
      node.body.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    super.visitFormalParameterList(node);
    // We finished resolving function signature, now include formal parameters
    // scope.  Note: we must not do this if the parent is a
    // FunctionTypedFormalParameter, because in that case we aren't finished
    // resolving the full function signature, just a part of it.
    var parent = node.parent;
    if (parent is FunctionExpression) {
      nameScope = FormalParameterScope(
        nameScope,
        parent.declaredElement!.parameters,
      );
    } else if (parent is FunctionTypeAlias) {
      var aliasedElement = parent.declaredElement!.aliasedElement;
      var functionElement = aliasedElement as GenericFunctionTypeElement;
      nameScope = FormalParameterScope(
        nameScope,
        functionElement.parameters,
      );
    } else if (parent is MethodDeclaration) {
      nameScope = FormalParameterScope(
        nameScope,
        parent.declaredElement!.parameters,
      );
    }
  }

  @override
  void visitForStatement(covariant ForStatementImpl node) {
    Scope outerNameScope = nameScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      nameScope = LocalScope(nameScope);
      _implicitLabelScope = _implicitLabelScope.nest(node);
      node.nameScope = nameScope;
      node.forLoopParts.accept(this);
      _visitStatementInScope(node.body);
    } finally {
      nameScope = outerNameScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    node.functionExpression.body.localVariableInfo = _localVariableInfo;
    var outerClosure = _enclosingClosure;
    Scope outerScope = nameScope;
    try {
      _enclosingClosure = node.parent is FunctionDeclarationStatement
          ? node.declaredElement
          : null;
      node.metadata.accept(this);
      var element = node.declaredElement!;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      node.nameScope = nameScope;
      node.returnType?.accept(this);
      node.functionExpression.accept(this);
    } finally {
      nameScope = outerScope;
      _enclosingClosure = outerClosure;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var outerClosure = _enclosingClosure;
    Scope outerScope = nameScope;
    try {
      if (node.parent is! FunctionDeclaration) {
        (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
        _enclosingClosure = node.declaredElement;
      }
      var parent = node.parent;
      if (parent is FunctionDeclarationImpl) {
        // We have already created a function scope and don't need to do so again.
        super.visitFunctionExpression(node);
        _visitDocumentationComment(parent.documentationComment);
        return;
      }

      ExecutableElement element = node.declaredElement!;
      nameScope = FormalParameterScope(
        TypeParameterScope(nameScope, element.typeParameters),
        element.parameters,
      );
      super.visitFunctionExpression(node);
    } finally {
      nameScope = outerScope;
      _enclosingClosure = outerClosure;
    }
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters.accept(this);
      // Visiting the parameters added them to the scope as a side effect. So it
      // is safe to visit the documentation comment now.
      _visitDocumentationComment(node.documentationComment);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitFunctionTypedFormalParameter(
      covariant FunctionTypedFormalParameterImpl node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      ParameterElement element = node.declaredElement!;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      _visitDocumentationComment(node.documentationComment);
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var type = node.type;
    if (type == null) {
      // The function type hasn't been resolved yet, so we can't create a scope
      // for its parameters.
      super.visitGenericFunctionType(node);
      return;
    }

    Scope outerScope = nameScope;
    try {
      GenericFunctionTypeElement element = node.declaredElement!;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      node.nameScope = nameScope;
      super.visitGenericFunctionType(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement as TypeAliasElement;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      node.nameScope = nameScope;
      node.typeParameters?.accept(this);
      node.type.accept(this);

      var aliasedElement = element.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        nameScope = FormalParameterScope(
            TypeParameterScope(nameScope, aliasedElement.typeParameters),
            aliasedElement.parameters);
      }
      _visitDocumentationComment(node.documentationComment);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGuardedPattern(covariant GuardedPatternImpl node) {
    var patternVariables = node.variables.values.toList();
    for (var variable in patternVariables) {
      _define(variable);
    }

    node.pattern.accept(this);

    for (var variable in patternVariables) {
      variable.isVisitingWhenClause = true;
    }

    node.whenClause?.accept(this);

    for (var variable in patternVariables) {
      variable.isVisitingWhenClause = false;
    }
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    var scope = nameScope.ifTypeOrNull<LibraryFragmentScope>();
    scope?.importsTrackingActive(false);
    try {
      super.visitHideCombinator(node);
    } finally {
      scope?.importsTrackingActive(true);
    }
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
  void visitLabeledStatement(LabeledStatement node) {
    var outerScope = _addScopesFor(node.labels, node.unlabeled);
    try {
      super.visitLabeledStatement(node);
    } finally {
      labelScope = outerScope;
    }
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    node.metadata.accept(this);
    _visitDocumentationComment(node.documentationComment);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    node.body.localVariableInfo = _localVariableInfo;
    node.metadata.accept(this);
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      node.nameScope = nameScope;
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      // Visiting the parameters added them to the scope as a side effect. So it
      // is safe to visit the documentation comment now.
      _visitDocumentationComment(node.documentationComment);
      node.body.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Only visit the method name if there's no real target (so this is an
    // unprefixed function invocation, outside a cascade).  This is the only
    // circumstance in which the method name is meant to be looked up in the
    // current scope.
    node.target?.accept(this);
    if (node.realTarget == null) {
      node.methodName.accept(this);
    }
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement!;
      node.metadata.accept(this);

      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      node.nameScope = nameScope;
      node.typeParameters?.accept(this);
      node.onClause?.accept(this);
      node.implementsClause?.accept(this);

      nameScope = InstanceScope(nameScope, element);
      _visitDocumentationComment(node.documentationComment);
      node.members.accept(this);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitNamedType(NamedType node) {
    // All TypeName(s) are already resolved, so we don't resolve it here.
    // But there might be type arguments with Expression(s), such as
    // annotations on formal parameters of GenericFunctionType(s).
    node.typeArguments?.accept(this);
  }

  @override
  void visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    for (var variable in node.elements) {
      _define(variable);
    }

    super.visitPatternVariableDeclaration(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Do not visit the identifier after the `.`, since it is not meant to be
    // looked up in the current scope.
    node.prefix.accept(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Do not visit the property name, since it is not meant to be looked up in
    // the current scope.
    node.target?.accept(this);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    var scope = nameScope.ifTypeOrNull<LibraryFragmentScope>();
    scope?.importsTrackingActive(false);
    try {
      super.visitShowCombinator(node);
    } finally {
      scope?.importsTrackingActive(true);
    }
  }

  @override
  void visitSimpleIdentifier(covariant SimpleIdentifierImpl node) {
    // Ignore if already resolved - declaration or type.
    if (node.inDeclarationContext()) {
      return;
    }
    // Ignore if qualified.
    var parent = node.parent;
    if (parent is ConstructorName && parent.name == node) {
      return;
    }
    if (parent is Label && parent.parent is NamedExpression) {
      return;
    }
    var scopeLookupResult = nameScope.lookup(node.name);
    node.scopeLookupResult = scopeLookupResult;
    // Ignore if it cannot be a reference to a local variable.
    if (parent is FieldFormalParameter) {
      return;
    } else if (parent is ConstructorDeclaration && parent.returnType == node) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return;
    }
    if (parent is Label) {
      return;
    }
    // Prepare VariableElement.
    var element = scopeLookupResult.getter;
    if (element is! VariableElement) {
      return;
    }
    // Must be local or parameter.
    ElementKind kind = element.kind;
    if (kind == ElementKind.LOCAL_VARIABLE || kind == ElementKind.PARAMETER) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        if (element is PatternVariableElementImpl &&
            element.isVisitingWhenClause) {
          errorReporter.atNode(
            node,
            CompileTimeErrorCode.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD,
          );
        }
        _localVariableInfo.potentiallyMutatedInScope.add(element);
      }
    }
    if (element is JoinPatternVariableElementImpl) {
      element.references.add(node);
    }
  }

  @override
  void visitSwitchExpression(covariant SwitchExpressionImpl node) {
    node.expression.accept(this);

    for (var case_ in node.cases) {
      _withNameScope(() {
        case_.nameScope = nameScope;
        var guardedPattern = case_.guardedPattern;
        var variables = guardedPattern.variables;
        for (var variable in variables.values) {
          _define(variable);
        }
        case_.accept(this);
      });
    }
  }

  @override
  void visitSwitchStatement(covariant SwitchStatementImpl node) {
    var outerScope = labelScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      for (SwitchMember member in node.members) {
        for (Label label in member.labels) {
          SimpleIdentifier labelName = label.label;
          LabelElement labelElement = labelName.staticElement as LabelElement;
          labelScope =
              LabelScope(labelScope, labelName.name, member, labelElement);
        }
      }
      node.expression.accept(this);
      for (var group in node.memberGroups) {
        for (var member in group.members) {
          if (member is SwitchCaseImpl) {
            member.expression.accept(this);
          } else if (member is SwitchPatternCaseImpl) {
            _withNameScope(() {
              member.guardedPattern.accept(this);
            });
          }
        }
        if (group.members.isEmpty) {
          return;
        }
        var lastMember = group.members.last;
        _withDeclaredLocals(lastMember, lastMember.statements, () {
          for (var variable in group.variables.values) {
            _define(variable);
          }
          lastMember.statements.accept(this);
        });
      }
    } finally {
      labelScope = outerScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  @override
  void visitTopLevelVariableDeclaration(
      covariant TopLevelVariableDeclarationImpl node) {
    node.metadata.accept(this);
    _visitDocumentationComment(node.documentationComment);
    node.variables.accept(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    if (node.parent!.parent is ForParts) {
      _define(node.declaredElement!);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition.accept(this);
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      _visitStatementInScope(node.body);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Adds scopes for each of the given [labels].
  ///
  /// Returns the scope that was in effect before the new scopes were added.
  LabelScope? _addScopesFor(NodeList<Label> labels, AstNode node) {
    var outerScope = labelScope;
    for (Label label in labels) {
      SimpleIdentifier labelNameNode = label.label;
      String labelName = labelNameNode.name;
      LabelElement labelElement = labelNameNode.staticElement as LabelElement;
      labelScope = LabelScope(labelScope, labelName, node, labelElement);
    }
    return outerScope;
  }

  void _define(Element element) {
    (nameScope as LocalScope).add(element);
  }

  /// Return the target of a break or continue statement, and update the static
  /// element of its label (if any). The [parentNode] is the AST node of the
  /// break or continue statement. The [labelNode] is the label contained in
  /// that statement (if any). The flag [isContinue] is `true` if the node being
  /// visited is a continue statement.
  AstNode? _lookupBreakOrContinueTarget(
      AstNode parentNode, SimpleIdentifierImpl? labelNode, bool isContinue) {
    if (labelNode == null) {
      return implicitLabelScope.getTarget(isContinue);
    } else {
      var labelScope = this.labelScope;
      if (labelScope == null) {
        // There are no labels in scope, so by definition the label is
        // undefined.
        errorReporter.atNode(
          labelNode,
          CompileTimeErrorCode.LABEL_UNDEFINED,
          arguments: [labelNode.name],
        );
        return null;
      }
      var definingScope = labelScope.lookup(labelNode.name);
      if (definingScope == null) {
        // No definition of the given label name could be found in any
        // enclosing scope.
        errorReporter.atNode(
          labelNode,
          CompileTimeErrorCode.LABEL_UNDEFINED,
          arguments: [labelNode.name],
        );
        return null;
      }
      // The target has been found.
      labelNode.staticElement = definingScope.element;
      ExecutableElement? labelContainer =
          definingScope.element.thisOrAncestorOfType();
      if (_enclosingClosure != null &&
          !identical(labelContainer, _enclosingClosure)) {
        errorReporter.atNode(
          labelNode,
          CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE,
          arguments: [labelNode.name],
        );
      }
      var node = definingScope.node;
      if (isContinue &&
          node is! DoStatement &&
          node is! ForStatement &&
          node is! SwitchMember &&
          node is! WhileStatement) {
        errorReporter.atNode(
          parentNode,
          CompileTimeErrorCode.CONTINUE_LABEL_INVALID,
        );
      }
      return node;
    }
  }

  /// Visits a documentation comment with a [DocImportScope] that encloses the
  /// current [nameScope].
  void _visitDocumentationComment(CommentImpl? node) {
    if (node == null) return;

    Scope outerScope = nameScope;
    Scope docImportInnerScope = _docImportScope.innerScope;
    try {
      _docImportScope.innerScope = nameScope;
      nameScope = _docImportScope;

      node.nameScope = nameScope;
      node.accept(this);
    } finally {
      nameScope = outerScope;
      _docImportScope.innerScope = docImportInnerScope;
    }
  }

  void _visitIf(IfElementOrStatementImpl node) {
    node.expression.accept(this);

    var caseClause = node.caseClause;
    if (caseClause != null) {
      var guardedPattern = caseClause.guardedPattern;
      _withNameScope(() {
        guardedPattern.accept(this);
        node.ifTrue.accept(this);
      });
      node.ifFalse?.accept(this);
    } else {
      node.ifTrue.accept(this);
      node.ifFalse?.accept(this);
    }
  }

  /// Visits the given statement.
  ///
  /// This is used by [ResolverVisitor] to correctly visit the 'then' and 'else'
  /// statements of an 'if' statement.
  void _visitStatementInScope(Statement? node) {
    if (node is BlockImpl) {
      // Don't create a scope around a block because the block will create it's
      // own scope.
      visitBlock(node);
    } else if (node != null) {
      var outerNameScope = nameScope;
      try {
        nameScope = LocalScope(nameScope);
        node.accept(this);
      } finally {
        nameScope = outerNameScope;
      }
    }
  }

  void _withDeclaredLocals(
    AstNodeWithNameScopeMixin node,
    List<Statement> statements,
    void Function() f,
  ) {
    var outerScope = nameScope;
    try {
      var enclosedScope = LocalScope(nameScope);
      for (var statement in BlockScope.elementsInStatements(statements)) {
        if (!statement.isWildcardFunction) {
          enclosedScope.add(statement);
        }
      }

      nameScope = enclosedScope;
      node.nameScope = nameScope;

      f();
    } finally {
      nameScope = outerScope;
    }
  }

  /// Run [f] with the new name scope.
  void _withNameScope(void Function() f) {
    var current = nameScope;
    try {
      nameScope = LocalScope(current);
      f();
    } finally {
      nameScope = current;
    }
  }

  /// Return the [Scope] to use while resolving inside the [node].
  ///
  /// Not every node has the scope set, for example we set the scopes for
  /// blocks, but statements don't have separate scopes. The compilation unit
  /// has the library scope.
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

  factory SwitchExhaustiveness(DartType expressionType) {
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
          caseConstant = pattern.expression;
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
          caseConstant = node.expression;
        } else if (node is SwitchPatternCaseImpl) {
          var guardedPattern = node.guardedPattern;
          if (guardedPattern.whenClause == null) {
            var pattern = guardedPattern.pattern.unParenthesized;
            if (pattern is ConstantPatternImpl) {
              caseConstant = pattern.expression;
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
        _enumConstants!.remove(element.variable2);
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
      return _referencedElement(expression.expression);
    } else if (expression is PrefixedIdentifier) {
      return expression.staticElement;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.staticElement;
    } else if (expression is SimpleIdentifier) {
      return expression.staticElement;
    }
    return null;
  }
}

class _WhyNotPromotedVisitor
    implements
        NonPromotionReasonVisitor<List<DiagnosticMessage>, AstNode,
            PromotableElement, SharedTypeView<DartType>> {
  final Source source;

  final SyntacticEntity _errorEntity;

  final FlowAnalysisDataForTesting? _dataForTesting;

  PropertyAccessorElement? propertyReference;

  DartType? propertyType;

  _WhyNotPromotedVisitor(this.source, this._errorEntity, this._dataForTesting);

  @override
  List<DiagnosticMessage> visitDemoteViaExplicitWrite(
      DemoteViaExplicitWrite<PromotableElement> reason) {
    var node = reason.node as AstNode;
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
  List<DiagnosticMessage> visitPropertyNotPromotedForInherentReason(
      PropertyNotPromotedForInherentReason<SharedTypeView<DartType>> reason) {
    var receiverElement = reason.propertyMember;
    if (receiverElement is PropertyAccessorElement) {
      var property = propertyReference = receiverElement;
      propertyType = reason.staticType.unwrapTypeView();
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
              "promoted."
      };
      return [
        DiagnosticMessageImpl(
            filePath: property.source.fullName,
            message: message,
            offset: property.nonSynthetic.nameOffset,
            length: property.nameLength,
            url: reason.documentationLink.url),
        if (!reason.fieldPromotionEnabled)
          _fieldPromotionUnavailableMessage(property, propertyName)
      ];
    } else {
      assert(receiverElement == null,
          'Unrecognized property element: ${receiverElement.runtimeType}');
      return [];
    }
  }

  @override
  List<DiagnosticMessage> visitPropertyNotPromotedForNonInherentReason(
      PropertyNotPromotedForNonInherentReason<SharedTypeView<DartType>>
          reason) {
    var receiverElement = reason.propertyMember;
    if (receiverElement is PropertyAccessorElement) {
      var property = propertyReference = receiverElement;
      propertyType = reason.staticType.unwrapTypeView();
      var propertyName = reason.propertyName;
      var library = receiverElement.library as LibraryElementImpl;
      var fieldNonPromotabilityInfo = library.fieldNameNonPromotabilityInfo;
      var fieldNameInfo = fieldNonPromotabilityInfo[reason.propertyName];
      var messages = <DiagnosticMessage>[];
      void addConflictMessage(
          {required Element conflictingElement,
          required String kind,
          required Element enclosingElement,
          required NonPromotionDocumentationLink link}) {
        var enclosingKindName = enclosingElement.kind.displayName;
        var enclosingName = enclosingElement.name;
        var message = "'$propertyName' couldn't be promoted because there is a "
            "conflicting $kind in $enclosingKindName '$enclosingName'";
        var nonSyntheticElement = conflictingElement.nonSynthetic;
        messages.add(DiagnosticMessageImpl(
            filePath: nonSyntheticElement.source!.fullName,
            message: message,
            offset: nonSyntheticElement.nameOffset,
            length: nonSyntheticElement.nameLength,
            url: link.url));
      }

      if (fieldNameInfo != null) {
        for (var field in fieldNameInfo.conflictingFields) {
          addConflictMessage(
              conflictingElement: field,
              kind: 'non-promotable field',
              enclosingElement: field.enclosingElement3,
              link:
                  NonPromotionDocumentationLink.conflictingNonPromotableField);
        }
        for (var getter in fieldNameInfo.conflictingGetters) {
          addConflictMessage(
              conflictingElement: getter,
              kind: 'getter',
              enclosingElement: getter.enclosingElement3,
              link: NonPromotionDocumentationLink.conflictingGetter);
        }
        for (var nsmClass in fieldNameInfo.conflictingNsmClasses) {
          addConflictMessage(
              conflictingElement: nsmClass,
              kind: 'noSuchMethod forwarder',
              enclosingElement: nsmClass,
              link: NonPromotionDocumentationLink
                  .conflictingNoSuchMethodForwarder);
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
      assert(receiverElement == null,
          'Unrecognized property element: ${receiverElement.runtimeType}');
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
          url: reason.documentationLink.url)
    ];
  }

  DiagnosticMessageImpl _contextMessageForWrite(String variableName,
      AstNode node, DemoteViaExplicitWrite<PromotableElement> reason) {
    return DiagnosticMessageImpl(
        filePath: source.fullName,
        message: "Variable '$variableName' could not be promoted due to an "
            "assignment",
        offset: node.offset,
        length: node.length,
        url: reason.documentationLink.url);
  }

  DiagnosticMessageImpl _fieldPromotionUnavailableMessage(
      PropertyAccessorElement property, String propertyName) {
    return DiagnosticMessageImpl(
        filePath: property.source.fullName,
        message: "'$propertyName' couldn't be promoted "
            "because field promotion is only available in Dart 3.2 and "
            "above.",
        offset: property.nonSynthetic.nameOffset,
        length: property.nameLength,
        url: NonPromotionDocumentationLink.fieldPromotionUnavailable.url);
  }
}

extension on Element {
  bool get isWildcardFunction =>
      this is FunctionElement &&
      name == '_' &&
      library.hasWildcardVariablesFeatureEnabled;
}
