// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart'
    show ConstructorMember, Member;
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/annotation_resolver.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/binary_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/for_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_expression_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/function_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/postfix_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/prefix_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/prefixed_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/simple_identifier_resolver.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/dart/resolver/variable_declaration_resolver.dart';
import 'package:analyzer/src/dart/resolver/yield_statement_resolver.dart';
import 'package:analyzer/src/error/bool_expression_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/this_access_tracker.dart';
import 'package:analyzer/src/generated/type_promotion_manager.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:meta/meta.dart';

/// Maintains and manages contextual type information used for
/// inferring types.
class InferenceContext {
  // TODO(leafp): Consider replacing these node properties with a
  // hash table help in an instance of this class.
  static const String _typeProperty =
      'analyzer.src.generated.InferenceContext.contextType';

  final ResolverVisitor _resolver;

  /// The type system in use.
  final TypeSystemImpl _typeSystem;

  /// The stack of contexts for nested function bodies.
  final List<BodyInferenceContext> _bodyContexts = [];

  InferenceContext._(ResolverVisitor resolver)
      : _resolver = resolver,
        _typeSystem = resolver.typeSystem;

  BodyInferenceContext get bodyContext {
    if (_bodyContexts.isNotEmpty) {
      return _bodyContexts.last;
    } else {
      return null;
    }
  }

  void popFunctionBodyContext(FunctionBody node) {
    var context = _bodyContexts.removeLast();

    var flow = _resolver._flowAnalysis?.flow;

    var resultType = context.computeInferredReturnType(
      endOfBlockIsReachable: flow == null || flow.isReachable,
    );

    setType(node, resultType);
  }

  void pushFunctionBodyContext(FunctionBody node) {
    var imposedType = getContext(node);
    _bodyContexts.add(
      BodyInferenceContext(
        typeSystem: _typeSystem,
        node: node,
        imposedType: imposedType,
      ),
    );
  }

  /// Clear the type information associated with [node].
  static void clearType(AstNode node) {
    node?.setProperty(_typeProperty, null);
  }

  /// Look for contextual type information attached to [node], and returns
  /// the type if found.
  ///
  /// The returned type may be partially or completely unknown, denoted with an
  /// unknown type `_`, for example `List<_>` or `(_, int) -> void`.
  /// You can use [TypeSystemImpl.upperBoundForType] or
  /// [TypeSystemImpl.lowerBoundForType] if you would prefer a known type
  /// that represents the bound of the context type.
  static DartType getContext(AstNode node) => node?.getProperty(_typeProperty);

  /// Attach contextual type information [type] to [node] for use during
  /// inference.
  static void setType(AstNode node, DartType type) {
    if (type == null || type.isDynamic) {
      clearType(node);
    } else {
      node?.setProperty(_typeProperty, type);
    }
  }

  /// Attach contextual type information [type] to [node] for use during
  /// inference.
  static void setTypeFromNode(AstNode innerNode, AstNode outerNode) {
    setType(innerNode, getContext(outerNode));
  }
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ScopedVisitor {
  /// The manager for the inheritance mappings.
  final InheritanceManager3 inheritance;

  /// The feature set that is enabled for the current unit.
  final FeatureSet _featureSet;

  final MigratableAstInfoProvider _migratableAstInfoProvider;

  final MigrationResolutionHooks migrationResolutionHooks;

  /// Helper for checking expression that should have the `bool` type.
  BoolExpressionVerifier boolExpressionVerifier;

  /// Helper for checking potentially nullable dereferences.
  NullableDereferenceVerifier nullableDereferenceVerifier;

  /// Helper for extension method resolution.
  ExtensionMemberResolver extensionResolver;

  /// Helper for resolving properties on types.
  TypePropertyResolver typePropertyResolver;

  /// Helper for resolving [ListLiteral] and [SetOrMapLiteral].
  TypedLiteralResolver _typedLiteralResolver;

  AssignmentExpressionResolver _assignmentExpressionResolver;
  BinaryExpressionResolver _binaryExpressionResolver;
  FunctionExpressionInvocationResolver _functionExpressionInvocationResolver;
  FunctionExpressionResolver _functionExpressionResolver;
  ForResolver _forResolver;
  PostfixExpressionResolver _postfixExpressionResolver;
  PrefixedIdentifierResolver _prefixedIdentifierResolver;
  PrefixExpressionResolver _prefixExpressionResolver;
  VariableDeclarationResolver _variableDeclarationResolver;
  YieldStatementResolver _yieldStatementResolver;

  NullSafetyDeadCodeVerifier nullSafetyDeadCodeVerifier;

  InvocationInferenceHelper inferenceHelper;

  /// The object used to resolve the element associated with the current node.
  ElementResolver elementResolver;

  /// The object used to compute the type associated with the current node.
  StaticTypeAnalyzer typeAnalyzer;

  /// The type system in use during resolution.
  final TypeSystemImpl typeSystem;

  /// The class declaration representing the class containing the current node,
  /// or `null` if the current node is not contained in a class.
  ClassDeclaration _enclosingClassDeclaration;

  /// The function type alias representing the function type containing the
  /// current node, or `null` if the current node is not contained in a function
  /// type alias.
  FunctionTypeAlias _enclosingFunctionTypeAlias;

  /// The element representing the function containing the current node, or
  /// `null` if the current node is not contained in a function.
  ExecutableElement _enclosingFunction;

  /// The mixin declaration representing the class containing the current node,
  /// or `null` if the current node is not contained in a mixin.
  MixinDeclaration _enclosingMixinDeclaration;

  /// The helper for tracking if the current location has access to `this`.
  final ThisAccessTracker _thisAccessTracker = ThisAccessTracker.unit();

  InferenceContext inferenceContext;

  /// If a class, or mixin, is being resolved, the type of the class.
  /// Otherwise `null`.
  DartType _thisType;

  /// The object keeping track of which elements have had their types promoted.
  TypePromotionManager _promoteManager;

  final FlowAnalysisHelper _flowAnalysis;

  /// A comment before a function should be resolved in the context of the
  /// function. But when we incrementally resolve a comment, we don't want to
  /// resolve the whole function.
  ///
  /// So, this flag is set to `true`, when just context of the function should
  /// be built and the comment resolved.
  bool resolveOnlyCommentInFunctionBody = false;

  /// The type of the expression of the immediately enclosing [SwitchStatement],
  /// or `null` if not in a [SwitchStatement].
  DartType _enclosingSwitchStatementExpressionType;

  /// Stack of expressions which we have not yet finished visiting, that should
  /// terminate a null-shorting expression.
  ///
  /// The stack contains a `null` sentinel as its first entry so that it is
  /// always safe to use `.last` to examine the top of the stack.
  final List<Expression> _unfinishedNullShorts = [null];

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// The [definingLibrary] is the element for the library containing the node
  /// being visited. The [source] is the source representing the compilation
  /// unit containing the node being visited. The [typeProvider] is the object
  /// used to access the types from the core library. The [errorListener] is the
  /// error listener that will be informed of any errors that are found during
  /// resolution. The [nameScope] is the scope used to resolve identifiers in
  /// the node that will first be visited.  If `null` or unspecified, a new
  /// [LibraryScope] will be created based on [definingLibrary] and
  /// [typeProvider].
  ///
  /// TODO(paulberry): make [featureSet] a required parameter (this will be a
  /// breaking change).
  ResolverVisitor(
      InheritanceManager3 inheritanceManager,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      {FeatureSet featureSet,
      Scope nameScope,
      bool reportConstEvaluationErrors = true,
      FlowAnalysisHelper flowAnalysisHelper})
      : this._(
            inheritanceManager,
            definingLibrary,
            source,
            definingLibrary.typeSystem as TypeSystemImpl,
            typeProvider,
            errorListener,
            featureSet ??
                definingLibrary.context.analysisOptions.contextFeatures,
            nameScope,
            reportConstEvaluationErrors,
            flowAnalysisHelper,
            const MigratableAstInfoProvider(),
            null);

  ResolverVisitor._(
      this.inheritance,
      LibraryElement definingLibrary,
      Source source,
      this.typeSystem,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      Scope nameScope,
      bool reportConstEvaluationErrors,
      this._flowAnalysis,
      this._migratableAstInfoProvider,
      MigrationResolutionHooks migrationResolutionHooks)
      : _featureSet = featureSet,
        migrationResolutionHooks = migrationResolutionHooks,
        super(definingLibrary, source, typeProvider as TypeProviderImpl,
            errorListener,
            nameScope: nameScope) {
    _promoteManager = TypePromotionManager(typeSystem);

    var analysisOptions =
        definingLibrary.context.analysisOptions as AnalysisOptionsImpl;

    nullableDereferenceVerifier = NullableDereferenceVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
    );
    boolExpressionVerifier = BoolExpressionVerifier(
      typeSystem: typeSystem,
      errorReporter: errorReporter,
      nullableDereferenceVerifier: nullableDereferenceVerifier,
    );
    _typedLiteralResolver = TypedLiteralResolver(
        this, _featureSet, typeSystem, typeProvider,
        migratableAstInfoProvider: _migratableAstInfoProvider);
    extensionResolver = ExtensionMemberResolver(this);
    typePropertyResolver = TypePropertyResolver(this);
    inferenceHelper = InvocationInferenceHelper(
        resolver: this,
        flowAnalysis: _flowAnalysis,
        errorReporter: errorReporter,
        typeSystem: typeSystem,
        migrationResolutionHooks: migrationResolutionHooks);
    _assignmentExpressionResolver = AssignmentExpressionResolver(
      resolver: this,
      flowAnalysis: _flowAnalysis,
    );
    _binaryExpressionResolver = BinaryExpressionResolver(
      resolver: this,
      promoteManager: _promoteManager,
      flowAnalysis: _flowAnalysis,
    );
    _functionExpressionInvocationResolver =
        FunctionExpressionInvocationResolver(
      resolver: this,
    );
    _functionExpressionResolver = FunctionExpressionResolver(
      resolver: this,
      migrationResolutionHooks: migrationResolutionHooks,
      flowAnalysis: _flowAnalysis,
      promoteManager: _promoteManager,
    );
    _forResolver = ForResolver(
      resolver: this,
      flowAnalysis: _flowAnalysis,
    );
    _postfixExpressionResolver = PostfixExpressionResolver(
      resolver: this,
      flowAnalysis: _flowAnalysis,
    );
    _prefixedIdentifierResolver = PrefixedIdentifierResolver(this);
    _prefixExpressionResolver = PrefixExpressionResolver(
      resolver: this,
      flowAnalysis: _flowAnalysis,
    );
    _variableDeclarationResolver = VariableDeclarationResolver(
      resolver: this,
      flowAnalysis: _flowAnalysis,
      strictInference: analysisOptions.strictInference,
    );
    _yieldStatementResolver = YieldStatementResolver(
      resolver: this,
    );
    nullSafetyDeadCodeVerifier = NullSafetyDeadCodeVerifier(
      typeSystem,
      errorReporter,
      _flowAnalysis,
    );
    elementResolver = ElementResolver(this,
        reportConstEvaluationErrors: reportConstEvaluationErrors,
        migratableAstInfoProvider: _migratableAstInfoProvider);
    inferenceContext = InferenceContext._(this);
    typeAnalyzer =
        StaticTypeAnalyzer(this, _flowAnalysis, migrationResolutionHooks);
  }

  /// Return the element representing the function containing the current node,
  /// or `null` if the current node is not contained in a function.
  ///
  /// @return the element representing the function containing the current node
  ExecutableElement get enclosingFunction => _enclosingFunction;

  /// Return the object providing promoted or declared types of variables.
  LocalVariableTypeProvider get localVariableTypeProvider {
    if (_flowAnalysis != null) {
      return _flowAnalysis.localVariableTypeProvider;
    } else {
      return _promoteManager.localVariableTypeProvider;
    }
  }

  NullabilitySuffix get noneOrStarSuffix {
    return _isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// If a class, or mixin, is being resolved, the type of the class.
  ///
  /// If an extension is being resolved, the type of `this`, the declared
  /// extended type, or promoted.
  ///
  /// Otherwise `null`.
  DartType get thisType {
    return _thisType;
  }

  /// Return `true` if NNBD is enabled for this compilation unit.
  bool get _isNonNullableByDefault =>
      _featureSet.isEnabled(Feature.non_nullable);

  void checkForBodyMayCompleteNormally({
    @required DartType returnType,
    @required FunctionBody body,
    @required AstNode errorNode,
  }) {
    if (!_flowAnalysis.flow.isReachable) {
      return;
    }

    if (returnType == null) {
      return;
    }

    if (body is BlockFunctionBody) {
      if (body.isGenerator) {
        return;
      }

      if (typeSystem.isPotentiallyNonNullable(returnType)) {
        if (errorNode is ConstructorDeclaration) {
          errorReporter.reportErrorForName(
            CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY,
            errorNode,
          );
        } else {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY,
            errorNode,
          );
        }
      }
    }
  }

  void checkReadOfNotAssignedLocalVariable(
    SimpleIdentifier node,
    Element element,
  ) {
    if (_flowAnalysis?.flow == null) {
      return;
    }

    if (!node.inGetterContext()) {
      return;
    }

    if (element is VariableElement) {
      var assigned = _flowAnalysis.isDefinitelyAssigned(
          node, element as PromotableElement);
      var unassigned = _flowAnalysis.isDefinitelyUnassigned(node, element);

      if (element.isLate) {
        if (unassigned) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE,
            node,
            [node.name],
          );
        }
        return;
      }

      if (!assigned) {
        if (element.isFinal) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL,
            node,
            [node.name],
          );
          return;
        }

        if (typeSystem.isPotentiallyNonNullable(element.type)) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode
                .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
            node,
            [node.name],
          );
          return;
        }
      }
    }
  }

  void checkUnreachableNode(AstNode node) {
    nullSafetyDeadCodeVerifier.visitNode(node);
  }

  /// Return the static element associated with the given expression whose type
  /// can be overridden, or `null` if there is no element whose type can be
  /// overridden.
  ///
  /// @param expression the expression with which the element is associated
  /// @return the element associated with the given expression
  VariableElement getOverridableStaticElement(Expression expression) {
    Element element;
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

  /// Return the result of lexical lookup for the [node], not `null`.
  ///
  /// Implements `16.35 Lexical Lookup` from the language specification.
  LexicalLookupResult lexicalLookup({
    @required SimpleIdentifier node,
    @required bool setter,
  }) {
    return LexicalLookup(this).perform(node: node, setter: setter);
  }

  /// If we reached a null-shorting termination, and the [node] has null
  /// shorting, make the type of the [node] nullable.
  void nullShortingTermination(Expression node, {bool discardType = false}) {
    if (!_isNonNullableByDefault) return;

    if (identical(_unfinishedNullShorts.last, node)) {
      do {
        _unfinishedNullShorts.removeLast();
        _flowAnalysis.flow.nullAwareAccess_end();
      } while (identical(_unfinishedNullShorts.last, node));
      if (node is! CascadeExpression && !discardType) {
        node.staticType = typeSystem.makeNullable(node.staticType as TypeImpl);
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
    // TODO(brianwilkerson) Remove this method.
  }

  /// Set the enclosing function body when partial AST is resolved.
  void prepareCurrentFunctionBody(FunctionBody body) {
    _promoteManager.enterFunctionBody(body);
  }

  /// Set information about enclosing declarations.
  void prepareEnclosingDeclarations({
    ClassElement enclosingClassElement,
    ExecutableElement enclosingExecutableElement,
  }) {
    _enclosingClassDeclaration = null;
    enclosingClass = enclosingClassElement;
    _thisType = enclosingClass?.thisType;
    _enclosingFunction = enclosingExecutableElement;
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
          node is ExtensionDeclaration ||
          node is FunctionDeclaration;
    }

    void forClassElement(ClassElement parentElement) {
      enclosingClass = parentElement;
      nameScope = ClassScope(
        TypeParameterScope(
          nameScope,
          parentElement.typeParameters,
        ),
        parentElement,
      );
      _thisType = parentElement.thisType;
    }

    if (parent is ClassDeclaration) {
      forClassElement(parent.declaredElement);
      return true;
    }

    if (parent is MixinDeclaration) {
      forClassElement(parent.declaredElement);
      return true;
    }

    return false;
  }

  /// Resolve LHS [node] of an assignment, an explicit [AssignmentExpression],
  /// or implicit [PrefixExpression] or [PostfixExpression].
  PropertyElementResolverResult resolveForWrite({
    @required AstNode node,
    @required bool hasRead,
  }) {
    if (node is IndexExpression) {
      node.target?.accept(this);
      startNullAwareIndexExpression(node);

      var resolver = PropertyElementResolver(this);
      var result = resolver.resolveIndexExpression(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      InferenceContext.setType(node.index, result.indexContextType);
      node.index.accept(this);

      return result;
    } else if (node is PrefixedIdentifier) {
      node.prefix?.accept(this);

      var resolver = PropertyElementResolver(this);
      return resolver.resolvePrefixedIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is PropertyAccess) {
      node.target?.accept(this);
      startNullAwarePropertyAccess(node);

      var resolver = PropertyElementResolver(this);
      return resolver.resolvePropertyAccess(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );
    } else if (node is SimpleIdentifier) {
      var resolver = PropertyElementResolver(this);
      var result = resolver.resolveSimpleIdentifier(
        node: node,
        hasRead: hasRead,
        hasWrite: true,
      );

      if (hasRead && result.readElementRequested == null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
          node,
          [node.name],
        );
      }

      return result;
    } else {
      node.accept(this);
      return PropertyElementResolverResult();
    }
  }

  /// Visit the given [comment] if it is not `null`.
  void safelyVisitComment(Comment comment) {
    if (comment != null) {
      super.visitComment(comment);
    }
  }

  void setReadElement(Expression node, Element element) {
    DartType readType = DynamicTypeImpl.instance;
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
        readType = localVariableTypeProvider.getType(node as SimpleIdentifier);
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

  @visibleForTesting
  void setThisInterfaceType(InterfaceType thisType) {
    _thisType = thisType;
  }

  void setWriteElement(Expression node, Element element) {
    DartType writeType = DynamicTypeImpl.instance;
    if (node is IndexExpression) {
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
          writeType = element.variable.type;
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
    if (_migratableAstInfoProvider.isIndexExpressionNullAware(node)) {
      var flow = _flowAnalysis?.flow;
      if (flow != null) {
        flow.nullAwareAccess_rightBegin(node.target,
            node.realTarget.staticType ?? typeProvider.dynamicType);
        _unfinishedNullShorts.add(node.nullShortingTermination);
      }
    }
  }

  void startNullAwarePropertyAccess(PropertyAccess node) {
    if (_migratableAstInfoProvider.isPropertyAccessNullAware(node)) {
      var flow = _flowAnalysis?.flow;
      if (flow != null) {
        var target = node.target;
        if (target is SimpleIdentifier &&
            target.staticElement is ClassElement) {
          // `?.` to access static methods is equivalent to `.`, so do nothing.
        } else {
          flow.nullAwareAccess_rightBegin(
              target, node.realTarget.staticType ?? typeProvider.dynamicType);
          _unfinishedNullShorts.add(node.nullShortingTermination);
        }
      }
    }
  }

  /// If in a legacy library, return the legacy view on the [element].
  /// Otherwise, return the original element.
  T toLegacyElement<T extends Element>(T element) {
    if (_isNonNullableByDefault) return element;
    return Member.legacy(element) as T;
  }

  /// If in a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType toLegacyTypeIfOptOut(DartType type) {
    if (_isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  @override
  void visitAnnotation(Annotation node) {
    AstNode parent = node.parent;
    if (identical(parent, _enclosingClassDeclaration) ||
        identical(parent, _enclosingFunctionTypeAlias) ||
        identical(parent, _enclosingMixinDeclaration)) {
      return;
    }
    AnnotationResolver(this).resolve(node);
  }

  @override
  void visitArgumentList(ArgumentList node, {bool isIdentical = false}) {
    DartType callerType = InferenceContext.getContext(node);
    NodeList<Expression> arguments = node.arguments;
    if (callerType is FunctionType) {
      Map<String, DartType> namedParameterTypes =
          callerType.namedParameterTypes;
      List<DartType> normalParameterTypes = callerType.normalParameterTypes;
      List<DartType> optionalParameterTypes = callerType.optionalParameterTypes;
      int normalCount = normalParameterTypes.length;
      int optionalCount = optionalParameterTypes.length;

      Iterable<Expression> positional =
          arguments.takeWhile((l) => l is! NamedExpression);
      Iterable<Expression> required = positional.take(normalCount);
      Iterable<Expression> optional =
          positional.skip(normalCount).take(optionalCount);
      Iterable<Expression> named =
          arguments.skipWhile((l) => l is! NamedExpression);
      var parent = node.parent;
      DartType targetType;
      Element methodElement;
      DartType invocationContext;
      if (parent is MethodInvocation) {
        targetType = parent.realTarget?.staticType;
        methodElement = parent.methodName.staticElement;
        invocationContext = InferenceContext.getContext(parent);
      }

      //TODO(leafp): Consider using the parameter elements here instead.
      //TODO(leafp): Make sure that the parameter elements are getting
      // setup correctly with inference.
      int index = 0;
      for (Expression argument in required) {
        InferenceContext.setType(
            argument,
            typeSystem.refineNumericInvocationContext(targetType, methodElement,
                invocationContext, normalParameterTypes[index++]));
      }
      index = 0;
      for (Expression argument in optional) {
        InferenceContext.setType(argument, optionalParameterTypes[index++]);
      }

      for (Expression argument in named) {
        if (argument is NamedExpression) {
          DartType type = namedParameterTypes[argument.name.label.name];
          if (type != null) {
            InferenceContext.setType(argument, type);
          }
        }
      }
    }
    checkUnreachableNode(node);
    int length = arguments.length;
    for (var i = 0; i < length; i++) {
      if (isIdentical && length > 1 && i == 1) {
        var firstArg = arguments[0];
        _flowAnalysis?.flow
            ?.equalityOp_rightBegin(firstArg, firstArg.staticType);
      }
      arguments[i].accept(this);
    }
    if (isIdentical && length > 1) {
      var secondArg = arguments[1];
      _flowAnalysis?.flow
          ?.equalityOp_end(node.parent, secondArg, secondArg.staticType);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    _flowAnalysis?.asExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    _flowAnalysis?.flow?.assert_begin();
    node.condition?.accept(this);
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_EXPRESSION,
    );
    _flowAnalysis?.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis?.flow?.assert_end();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    _flowAnalysis?.flow?.assert_begin();
    node.condition?.accept(this);
    boolExpressionVerifier.checkForNonBoolExpression(
      node.condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_EXPRESSION,
    );
    _flowAnalysis?.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis?.flow?.assert_end();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _assignmentExpressionResolver.resolve(node as AssignmentExpressionImpl);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    DartType contextType = InferenceContext.getContext(node);
    if (contextType != null) {
      var futureUnion = _createFutureOr(contextType);
      InferenceContext.setType(node.expression, futureUnion);
    }
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _binaryExpressionResolver.resolve(node as BinaryExpressionImpl);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    try {
      inferenceContext.pushFunctionBodyContext(node);
      _thisAccessTracker.enterFunctionBody(node);
      super.visitBlockFunctionBody(node);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
      inferenceContext.popFunctionBodyContext(node);
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _flowAnalysis?.flow?.booleanLiteral(node, node.value);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.breakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    InferenceContext.setTypeFromNode(node.target, node);
    node.target.accept(this);

    if (node.isNullAware && _flowAnalysis != null) {
      _flowAnalysis.flow.nullAwareAccess_rightBegin(
          node.target, node.target.staticType ?? typeProvider.dynamicType);
      _unfinishedNullShorts.add(node.nullShortingTermination);
    }

    node.cascadeSections.accept(this);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);

    nullShortingTermination(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    //
    // Resolve the metadata in the library scope.
    //
    node.metadata?.accept(this);
    _enclosingClassDeclaration = node;
    //
    // Continue the class resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      _thisType = enclosingClass?.thisType;
      super.visitClassDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      _thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  @override
  void visitComment(Comment node) {
    AstNode parent = node.parent;
    if (parent is FunctionDeclaration ||
        parent is FunctionTypeAlias ||
        parent is ConstructorDeclaration) {
      return;
    }

    // TODO(scheglov) Change corresponding visiting places to visit comments
    // with name scopes set for correct comments resolution.
    if (parent is GenericTypeAlias) {
      var element = parent.declaredElement as TypeAliasElement;
      var outerScope = nameScope;
      try {
        nameScope = TypeParameterScope(nameScope, element.typeParameters);

        var aliasedElement = element.aliasedElement;
        if (aliasedElement is GenericFunctionTypeElement) {
          nameScope = FormalParameterScope(
            TypeParameterScope(nameScope, aliasedElement.typeParameters),
            aliasedElement.parameters,
          );
        }

        super.visitComment(node);
        return;
      } finally {
        nameScope = outerScope;
      }
    } else if (parent is MethodDeclaration) {
      var outerScope = nameScope;
      try {
        var element = parent.declaredElement;
        nameScope = FormalParameterScope(nameScope, element.parameters);

        super.visitComment(node);
        return;
      } finally {
        nameScope = outerScope;
      }
    }

    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    //
    // We do not visit the identifier because it needs to be visited in the
    // context of the reference.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
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
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    var flow = _flowAnalysis?.flow;
    flow?.conditional_conditionBegin();

    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);
    condition = node.condition;
    boolExpressionVerifier.checkForNonBoolCondition(condition);

    Expression thenExpression = node.thenExpression;
    InferenceContext.setTypeFromNode(thenExpression, node);

    if (_flowAnalysis != null) {
      if (flow != null) {
        flow.conditional_thenBegin(condition);
        checkUnreachableNode(thenExpression);
      }
      thenExpression.accept(this);
      nullSafetyDeadCodeVerifier?.flowEnd(thenExpression);
    } else {
      _promoteManager.visitConditionalExpression_then(
        condition,
        thenExpression,
        () {
          thenExpression.accept(this);
        },
      );
    }

    Expression elseExpression = node.elseExpression;
    InferenceContext.setTypeFromNode(elseExpression, node);

    if (flow != null) {
      flow.conditional_elseBegin(thenExpression);
      checkUnreachableNode(elseExpression);
      elseExpression.accept(this);
      flow.conditional_end(node, elseExpression);
      nullSafetyDeadCodeVerifier?.flowEnd(elseExpression);
    } else {
      elseExpression.accept(this);
    }

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConfiguration(Configuration node) {
    // Don't visit the children. For the time being we don't resolve anything
    // inside the configuration.
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    if (_flowAnalysis != null) {
      _flowAnalysis.topLevelDeclaration_enter(node, node.parameters, node.body);
      _flowAnalysis.executableDeclaration_enter(node, node.parameters, false);
    } else {
      _promoteManager.enterFunctionBody(node.body);
    }

    var returnType = _enclosingFunction.type.returnType;
    InferenceContext.setType(node.body, returnType);

    super.visitConstructorDeclaration(node);

    if (_flowAnalysis != null) {
      if (node.factoryKeyword != null) {
        var bodyContext = BodyInferenceContext.of(node.body);
        checkForBodyMayCompleteNormally(
          returnType: bodyContext?.contextType,
          body: node.body,
          errorNode: node,
        );
      }
      _flowAnalysis.executableDeclaration_exit(node.body, false);
      _flowAnalysis.topLevelDeclaration_exit();
      nullSafetyDeadCodeVerifier?.flowEnd(node);
    } else {
      _promoteManager.exitFunctionBody();
    }

    var constructor = node.declaredElement as ConstructorElementImpl;
    constructor.constantInitializers =
        _createCloner().cloneNodeList(node.initializers);

    _enclosingFunction = outerFunction;
  }

  @override
  void visitConstructorDeclarationInScope(ConstructorDeclaration node) {
    super.visitConstructorDeclarationInScope(node);
    // Because of needing a different scope for the initializer list, the
    // overridden implementation of this method cannot cause the visitNode
    // method to be invoked. As a result, we have to hard-code using the
    // element resolver and type analyzer to visit the constructor declaration.
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    //
    // We visit the expression, but do not visit the field name because it needs
    // to be visited in the context of the constructor field initializer node.
    //
    FieldElement fieldElement = enclosingClass.getField(node.fieldName.name);
    InferenceContext.setType(node.expression, fieldElement?.type);
    node.expression?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    //
    // We do not visit either the type name, because it won't be visited anyway,
    // or the name, because it needs to be visited in the context of the
    // constructor name.
    //
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context
    // of the statement.
    //
    checkUnreachableNode(node);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.continueStatement(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    InferenceContext.setType(node.defaultValue, node.declaredElement?.type);
    super.visitDefaultFormalParameter(node);
    ParameterElement element = node.declaredElement;

    // Clone the ASTs for default formal parameters, so that we can use them
    // during constant evaluation.
    if (element is ConstVariableElement &&
        !_hasSerializedConstantInitializer(element)) {
      (element as ConstVariableElement).constantInitializer =
          _createCloner().cloneNode(node.defaultValue);
    }
  }

  @override
  void visitDoStatementInScope(DoStatement node) {
    checkUnreachableNode(node);

    var body = node.body;
    var condition = node.condition;

    _flowAnalysis?.flow?.doStatement_bodyBegin(node);
    visitStatementInScope(body);

    _flowAnalysis?.flow?.doStatement_conditionBegin();
    InferenceContext.setType(condition, typeProvider.boolType);
    condition.accept(this);
    condition = node.condition;
    boolExpressionVerifier.checkForNonBoolCondition(condition);

    _flowAnalysis?.flow?.doStatement_end(condition);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return;
    }
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.metadata?.accept(this);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    //
    // Resolve the metadata in the library scope
    // and associate the annotations with the element.
    //
    node.metadata?.accept(this);
    //
    // Continue the enum resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      _thisType = enclosingClass?.thisType;
      super.visitEnumDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      _thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (resolveOnlyCommentInFunctionBody) {
      return;
    }

    try {
      inferenceContext.pushFunctionBodyContext(node);
      InferenceContext.setType(
        node.expression,
        inferenceContext.bodyContext.contextType,
      );
      _thisAccessTracker.enterFunctionBody(node);

      super.visitExpressionFunctionBody(node);

      _flowAnalysis?.flow?.handleExit();

      inferenceContext.bodyContext.addReturnExpression(node.expression);
    } finally {
      _thisAccessTracker.exitFunctionBody(node);
      inferenceContext.popFunctionBodyContext(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    try {
      _thisType = node.declaredElement.extendedType;
      super.visitExtensionDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      _thisType = null;
    }
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    node.extensionName.accept(this);
    node.typeArguments?.accept(this);

    ExtensionMemberResolver(this).setOverrideReceiverContextType(node);
    node.argumentList.accept(this);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _thisAccessTracker.enterFieldDeclaration(node);
    try {
      super.visitFieldDeclaration(node);
    } finally {
      _thisAccessTracker.exitFieldDeclaration(node);
    }
  }

  @override
  void visitForElementInScope(ForElement node) {
    _forResolver.resolveElement(node as ForElementImpl);
  }

  @override
  void visitForStatementInScope(ForStatement node) {
    _forResolver.resolveStatement(node as ForStatementImpl);
    nullSafetyDeadCodeVerifier?.flowEnd(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    bool isLocal = node.parent is FunctionDeclarationStatement;

    if (_flowAnalysis != null) {
      if (isLocal) {
        _flowAnalysis.flow.functionExpression_begin(node);
      } else {
        _flowAnalysis.topLevelDeclaration_enter(
          node,
          node.functionExpression.parameters,
          node.functionExpression.body,
        );
      }
      _flowAnalysis.executableDeclaration_enter(
        node,
        node.functionExpression.parameters,
        isLocal,
      );
    } else {
      _promoteManager.enterFunctionBody(node.functionExpression.body);
    }

    var functionType = _enclosingFunction.type;
    InferenceContext.setType(node.functionExpression, functionType);

    super.visitFunctionDeclaration(node);

    if (_flowAnalysis != null) {
      // TODO(scheglov) encapsulate
      var bodyContext = BodyInferenceContext.of(
        node.functionExpression.body,
      );
      checkForBodyMayCompleteNormally(
        returnType: bodyContext?.contextType,
        body: node.functionExpression.body,
        errorNode: node.name,
      );
      _flowAnalysis.executableDeclaration_exit(
        node.functionExpression.body,
        isLocal,
      );
      if (isLocal) {
        _flowAnalysis.flow.functionExpression_end();
      } else {
        _flowAnalysis.topLevelDeclaration_exit();
      }
      nullSafetyDeadCodeVerifier?.flowEnd(node);
    } else {
      _promoteManager.exitFunctionBody();
    }

    _enclosingFunction = outerFunction;
  }

  @override
  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    ExecutableElement outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    if (node.parent is FunctionDeclaration) {
      _functionExpressionResolver.resolve(node);
    } else {
      Scope outerScope = nameScope;
      try {
        ExecutableElement element = node.declaredElement;
        nameScope = FormalParameterScope(
          TypeParameterScope(nameScope, element.typeParameters),
          element.parameters,
        );
        _functionExpressionResolver.resolve(node);
      } finally {
        nameScope = outerScope;
      }
    }

    _enclosingFunction = outerFunction;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function?.accept(this);
    _functionExpressionInvocationResolver
        .resolve(node as FunctionExpressionInvocationImpl);
    nullShortingTermination(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // Resolve the metadata in the library scope.
    if (node.metadata != null) {
      node.metadata.accept(this);
    }
    FunctionTypeAlias outerAlias = _enclosingFunctionTypeAlias;
    _enclosingFunctionTypeAlias = node;
    try {
      super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingFunctionTypeAlias = outerAlias;
    }
  }

  @override
  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    super.visitFunctionTypeAliasInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitGenericTypeAliasInFunctionScope(GenericTypeAlias node) {
    super.visitGenericTypeAliasInFunctionScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitHideCombinator(HideCombinator node) {}

  @override
  void visitIfElement(IfElement node) {
    _flowAnalysis?.flow?.ifStatement_conditionBegin();
    Expression condition = node.condition;
    InferenceContext.setType(condition, typeProvider.boolType);
    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);
    condition = node.condition;

    boolExpressionVerifier.checkForNonBoolCondition(condition);

    CollectionElement thenElement = node.thenElement;
    if (_flowAnalysis != null) {
      _flowAnalysis.flow?.ifStatement_thenBegin(condition);
      thenElement.accept(this);
    } else {
      _promoteManager.visitIfElement_thenElement(
        condition,
        thenElement,
        () {
          thenElement.accept(this);
        },
      );
    }

    var elseElement = node.elseElement;
    if (elseElement != null) {
      _flowAnalysis?.flow?.ifStatement_elseBegin();
      elseElement.accept(this);
    }

    _flowAnalysis?.flow?.ifStatement_end(elseElement != null);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIfStatement(IfStatement node) {
    checkUnreachableNode(node);
    _flowAnalysis?.flow?.ifStatement_conditionBegin();

    Expression condition = node.condition;

    InferenceContext.setType(condition, typeProvider.boolType);
    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);
    condition = node.condition;

    boolExpressionVerifier.checkForNonBoolCondition(condition);

    Statement thenStatement = node.thenStatement;
    if (_flowAnalysis != null) {
      _flowAnalysis.flow?.ifStatement_thenBegin(condition);
      visitStatementInScope(thenStatement);
      nullSafetyDeadCodeVerifier?.flowEnd(thenStatement);
    } else {
      _promoteManager.visitIfStatement_thenStatement(
        condition,
        thenStatement,
        () {
          visitStatementInScope(thenStatement);
        },
      );
    }

    Statement elseStatement = node.elseStatement;
    if (elseStatement != null) {
      _flowAnalysis?.flow?.ifStatement_elseBegin();
      visitStatementInScope(elseStatement);
      nullSafetyDeadCodeVerifier?.flowEnd(elseStatement);
    }

    _flowAnalysis?.flow?.ifStatement_end(elseStatement != null);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    startNullAwareIndexExpression(node);

    var resolver = PropertyElementResolver(this);
    var result = resolver.resolveIndexExpression(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;
    node.staticElement = element as MethodElement;

    InferenceContext.setType(node.index, result.indexContextType);
    node.index?.accept(this);

    DartType type;
    if (identical(node.realTarget.staticType, NeverTypeImpl.instance)) {
      type = NeverTypeImpl.instance;
    } else if (element is MethodElement) {
      type = element.returnType;
    } else {
      type = DynamicTypeImpl.instance;
    }
    inferenceHelper.recordStaticType(node, type);

    nullShortingTermination(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.constructorName?.accept(this);
    _inferArgumentTypesForInstanceCreate(node);
    node.argumentList?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIsExpression(IsExpression node) {
    super.visitIsExpression(node);
    _flowAnalysis?.isExpression(node);
  }

  @override
  void visitLabel(Label node) {}

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _flowAnalysis?.labeledStatement_enter(node);
    super.visitLabeledStatement(node);
    _flowAnalysis?.labeledStatement_exit(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitListLiteral(ListLiteral node) {
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    _enclosingFunction = node.declaredElement;

    if (_flowAnalysis != null) {
      _flowAnalysis.topLevelDeclaration_enter(node, node.parameters, node.body);
      _flowAnalysis.executableDeclaration_enter(node, node.parameters, false);
    } else {
      _promoteManager.enterFunctionBody(node.body);
    }

    DartType returnType = _enclosingFunction?.returnType;
    InferenceContext.setType(node.body, returnType);

    super.visitMethodDeclaration(node);

    if (_flowAnalysis != null) {
      // TODO(scheglov) encapsulate
      var bodyContext = BodyInferenceContext.of(node.body);
      checkForBodyMayCompleteNormally(
        returnType: bodyContext?.contextType,
        body: node.body,
        errorNode: node.name,
      );
      _flowAnalysis.executableDeclaration_exit(node.body, false);
      _flowAnalysis.topLevelDeclaration_exit();
      nullSafetyDeadCodeVerifier?.flowEnd(node);
    } else {
      _promoteManager.exitFunctionBody();
    }

    _enclosingFunction = outerFunction;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var target = node.target;
    target?.accept(this);

    if (_migratableAstInfoProvider.isMethodInvocationNullAware(node)) {
      var flow = _flowAnalysis?.flow;
      if (flow != null) {
        if (target is SimpleIdentifier &&
            target.staticElement is ClassElement) {
          // `?.` to access static methods is equivalent to `.`, so do nothing.
        } else {
          flow.nullAwareAccess_rightBegin(
              target, node.realTarget.staticType ?? typeProvider.dynamicType);
          _unfinishedNullShorts.add(node.nullShortingTermination);
        }
      }
    }

    node.typeArguments?.accept(this);
    node.accept(elementResolver);

    var functionRewrite = MethodInvocationResolver.getRewriteResult(node);
    if (functionRewrite != null) {
      nullShortingTermination(node, discardType: true);
      _resolveRewrittenFunctionExpressionInvocation(functionRewrite);
    } else {
      nullShortingTermination(node);
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    //
    // Resolve the metadata in the library scope.
    //
    node.metadata?.accept(this);
    _enclosingMixinDeclaration = node;
    //
    // Continue the class resolution.
    //
    ClassElement outerType = enclosingClass;
    try {
      enclosingClass = node.declaredElement;
      _thisType = enclosingClass?.thisType;
      super.visitMixinDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      _thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingMixinDeclaration = null;
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    super.visitNamedExpression(node);
  }

  @override
  void visitNode(AstNode node) {
    checkUnreachableNode(node);
    node.visitChildren(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _flowAnalysis?.flow?.nullLiteral(node);
    super.visitNullLiteral(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    InferenceContext.setTypeFromNode(node.expression, node);
    super.visitParenthesizedExpression(node);
    _flowAnalysis?.flow?.parenthesizedExpression(node, node.expression);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _postfixExpressionResolver.resolve(node as PostfixExpressionImpl);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _prefixedIdentifierResolver.resolve(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _prefixExpressionResolver.resolve(node as PrefixExpressionImpl);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    startNullAwarePropertyAccess(node);

    var resolver = PropertyElementResolver(this);
    var result = resolver.resolvePropertyAccess(
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
      type = element.returnType;
    } else if (result.functionTypeCallType != null) {
      type = result.functionTypeCallType;
    } else {
      type = DynamicTypeImpl.instance;
    }

    type = inferenceHelper.inferTearOff(node, propertyName, type);

    inferenceHelper.recordStaticType(propertyName, type);
    inferenceHelper.recordStaticType(node, type);

    nullShortingTermination(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList, node.staticElement?.type);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    super.visitRethrowExpression(node);
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    InferenceContext.setType(
      node.expression,
      inferenceContext.bodyContext?.contextType,
    );

    super.visitReturnStatement(node);

    inferenceContext.bodyContext?.addReturnExpression(node.expression);
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    checkUnreachableNode(node);
    _typedLiteralResolver.resolveSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifierResolver(this, _flowAnalysis).resolve(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    super.visitSpreadElement(node);

    if (!node.isNullAware) {
      nullableDereferenceVerifier.expression(node.expression);
    }
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList, node.staticElement?.type);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    checkUnreachableNode(node);

    InferenceContext.setType(
        node.expression, _enclosingSwitchStatementExpressionType);
    super.visitSwitchCase(node);

    var flow = _flowAnalysis?.flow;
    if (flow != null && flow.isReachable) {
      var switchStatement = node.parent as SwitchStatement;
      if (switchStatement.members.last != node && node.statements.isNotEmpty) {
        errorReporter.reportErrorForToken(
          CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY,
          node.keyword,
        );
      }
    }

    nullSafetyDeadCodeVerifier?.flowEnd(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    super.visitSwitchDefault(node);
    nullSafetyDeadCodeVerifier?.flowEnd(node);
  }

  @override
  void visitSwitchStatementInScope(SwitchStatement node) {
    checkUnreachableNode(node);

    var previousExpressionType = _enclosingSwitchStatementExpressionType;
    try {
      var expression = node.expression;
      expression.accept(this);
      _enclosingSwitchStatementExpressionType = expression.staticType;

      if (_flowAnalysis != null) {
        var flow = _flowAnalysis.flow;

        flow.switchStatement_expressionEnd(node);

        var exhaustiveness = _SwitchExhaustiveness(
          _enclosingSwitchStatementExpressionType,
        );

        var members = node.members;
        for (var member in members) {
          flow.switchStatement_beginCase(member.labels.isNotEmpty, node);
          member.accept(this);

          exhaustiveness.visitSwitchMember(member);
        }

        flow.switchStatement_end(exhaustiveness.isExhaustive);
      } else {
        node.members.accept(this);
      }
    } finally {
      _enclosingSwitchStatementExpressionType = previousExpressionType;
    }
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    super.visitThrowExpression(node);
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (_flowAnalysis == null) {
      return super.visitTryStatement(node);
    }

    checkUnreachableNode(node);
    var flow = _flowAnalysis.flow;

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
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);
      nullSafetyDeadCodeVerifier?.flowEnd(node.body);
      nullSafetyDeadCodeVerifier.tryStatementEnter(node);

      var catchLength = catchClauses.length;
      for (var i = 0; i < catchLength; ++i) {
        var catchClause = catchClauses[i];
        nullSafetyDeadCodeVerifier.verifyCatchClause(catchClause);
        flow.tryCatchStatement_catchBegin(
          catchClause.exceptionParameter?.staticElement as PromotableElement,
          catchClause.stackTraceParameter?.staticElement as PromotableElement,
        );
        catchClause.accept(this);
        flow.tryCatchStatement_catchEnd();
        nullSafetyDeadCodeVerifier?.flowEnd(catchClause.body);
      }

      flow.tryCatchStatement_end();
      nullSafetyDeadCodeVerifier.tryStatementExit(node);
    }

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      finallyBlock.accept(this);
      flow.tryFinallyStatement_end(finallyBlock);
    }
  }

  @override
  void visitTypeName(TypeName node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _variableDeclarationResolver.resolve(node as VariableDeclarationImpl);

    var declaredElement = node.declaredElement;
    if (node.parent.parent is ForParts) {
      _define(declaredElement);
    }

    var initializer = node.initializer;
    var parent = node.parent as VariableDeclarationList;
    TypeAnnotation declaredType = parent.type;
    if (initializer != null) {
      var initializerStaticType = initializer.staticType;
      if (declaredType == null) {
        if (initializerStaticType is TypeParameterType) {
          _flowAnalysis?.flow?.promote(
              declaredElement as PromotableElement, initializerStaticType);
        }
      } else {
        _flowAnalysis?.flow?.initialize(declaredElement as PromotableElement,
            initializerStaticType, initializer,
            isFinal: parent.isFinal, isLate: parent.isLate);
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _flowAnalysis?.variableDeclarationList(node);
    for (VariableDeclaration decl in node.variables) {
      VariableElement variableElement = decl.declaredElement;
      InferenceContext.setType(decl, variableElement?.type);
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    checkUnreachableNode(node);

    // Note: since we don't call the base class, we have to maintain
    // _implicitLabelScope ourselves.
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);

      Expression condition = node.condition;
      InferenceContext.setType(condition, typeProvider.boolType);

      _flowAnalysis?.flow?.whileStatement_conditionBegin(node);
      condition?.accept(this);

      boolExpressionVerifier.checkForNonBoolCondition(node.condition);

      Statement body = node.body;
      if (body != null) {
        _flowAnalysis?.flow?.whileStatement_bodyBegin(node, condition);
        visitStatementInScope(body);
        _flowAnalysis?.flow?.whileStatement_end();
        nullSafetyDeadCodeVerifier?.flowEnd(node.body);
      }
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition
    // is false, then propagateFalseState(condition);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _yieldStatementResolver.resolve(node);
  }

  /// Return a newly created cloner that can be used to clone constant
  /// expressions.
  ConstantAstCloner _createCloner() {
    return ConstantAstCloner();
  }

  /// Creates a union of `T | Future<T>`, unless `T` is already a
  /// future-union, in which case it simply returns `T`.
  DartType _createFutureOr(DartType type) {
    if (type.isDartAsyncFutureOr) {
      return type;
    }
    return typeProvider.futureOrType2(type);
  }

  /// Return `true` if the given [parameter] element of the AST being resolved
  /// is resynthesized and is an API-level, not local, so has its initializer
  /// serialized.
  bool _hasSerializedConstantInitializer(ParameterElement parameter) {
    Element executable = parameter.enclosingElement;
    if (executable is MethodElement ||
        executable is FunctionElement &&
            executable.enclosingElement is CompilationUnitElement) {
      return true;
    }
    return false;
  }

  void _inferArgumentTypesForInstanceCreate(InstanceCreationExpression node) {
    ConstructorName constructor = node.constructorName;
    TypeName classTypeName = constructor?.type;
    if (classTypeName == null) {
      return;
    }

    ConstructorElement originalElement = constructor.staticElement;
    FunctionType inferred;
    // If the constructor is generic, we'll have a ConstructorMember that
    // substitutes in type arguments (possibly `dynamic`) from earlier in
    // resolution.
    //
    // Otherwise we'll have a ConstructorElement, and we can skip inference
    // because there's nothing to infer in a non-generic type.
    if (classTypeName.typeArguments == null &&
        originalElement is ConstructorMember) {
      // TODO(leafp): Currently, we may re-infer types here, since we
      // sometimes resolve multiple times.  We should really check that we
      // have not already inferred something.  However, the obvious ways to
      // check this don't work, since we may have been instantiated
      // to bounds in an earlier phase, and we *do* want to do inference
      // in that case.

      // Get back to the uninstantiated generic constructor.
      // TODO(jmesserly): should we store this earlier in resolution?
      // Or look it up, instead of jumping backwards through the Member?
      var rawElement = originalElement.declaration;
      rawElement = toLegacyElement(rawElement);

      FunctionType constructorType =
          typeAnalyzer.constructorToGenericFunctionType(rawElement);

      inferred = inferenceHelper.inferArgumentTypesForGeneric(
          node, constructorType, constructor.type.typeArguments,
          isConst: node.isConst, errorNode: node.constructorName);

      if (inferred != null) {
        ArgumentList arguments = node.argumentList;
        InferenceContext.setType(arguments, inferred);
        // Fix up the parameter elements based on inferred method.
        arguments.correspondingStaticParameters =
            resolveArgumentsToParameters(arguments, inferred.parameters, null);

        constructor.type.type = inferred.returnType;

        // Update the static element as well. This is used in some cases, such
        // as computing constant values. It is stored in two places.
        var constructorElement = ConstructorMember.from(
          rawElement,
          inferred.returnType as InterfaceType,
        );
        constructorElement = toLegacyElement(constructorElement);
        constructor.staticElement = constructorElement;
      }
    }

    if (inferred == null) {
      var type = originalElement?.type;
      type = toLegacyTypeIfOptOut(type) as FunctionType;
      InferenceContext.setType(node.argumentList, type);
    }
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
  ) {
    var function = node.function;

    if (function is PropertyAccess &&
        _migratableAstInfoProvider.isPropertyAccessNullAware(function) &&
        _isNonNullableByDefault) {
      var target = function.target;
      if (target is SimpleIdentifier && target.staticElement is ClassElement) {
        // `?.` to access static methods is equivalent to `.`, so do nothing.
      } else {
        _flowAnalysis.flow.nullAwareAccess_rightBegin(function,
            function.realTarget.staticType ?? typeProvider.dynamicType);
        _unfinishedNullShorts.add(node.nullShortingTermination);
      }
    }

    _functionExpressionInvocationResolver
        .resolve(node as FunctionExpressionInvocationImpl);

    nullShortingTermination(node);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments.
  ///
  /// An error will be reported to [onError] if any of the arguments cannot be
  /// matched to a parameter. onError can be null to ignore the error.
  ///
  /// Returns the parameters that correspond to the arguments. If no parameter
  /// matched an argument, that position will be `null` in the list.
  static List<ParameterElement> resolveArgumentsToParameters(
      ArgumentList argumentList,
      List<ParameterElement> parameters,
      void Function(ErrorCode errorCode, AstNode node, [List<Object> arguments])
          onError) {
    if (parameters.isEmpty && argumentList.arguments.isEmpty) {
      return const <ParameterElement>[];
    }
    int requiredParameterCount = 0;
    int unnamedParameterCount = 0;
    List<ParameterElement> unnamedParameters = <ParameterElement>[];
    Map<String, ParameterElement> namedParameters;
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
    List<ParameterElement> resolvedParameters =
        List<ParameterElement>.filled(argumentCount, null);
    int positionalArgumentCount = 0;
    HashSet<String> usedNames;
    bool noBlankArguments = true;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        SimpleIdentifier nameNode = argument.name.label;
        String name = nameNode.name;
        ParameterElement element =
            namedParameters != null ? namedParameters[name] : null;
        if (element == null) {
          if (onError != null) {
            onError(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, nameNode,
                [name]);
          }
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        usedNames ??= HashSet<String>();
        if (!usedNames.add(name)) {
          if (onError != null) {
            onError(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode,
                [name]);
          }
        }
      } else {
        if (argument is SimpleIdentifier && argument.name.isEmpty) {
          noBlankArguments = false;
        }
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        }
      }
    }
    if (positionalArgumentCount < requiredParameterCount && noBlankArguments) {
      if (onError != null) {
        onError(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS,
            argumentList, [requiredParameterCount, positionalArgumentCount]);
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
      if (onError != null) {
        onError(errorCode, argumentList,
            [unnamedParameterCount, positionalArgumentCount]);
      }
    }
    return resolvedParameters;
  }
}

/// Override of [ResolverVisitorForMigration] that invokes methods of
/// [MigrationResolutionHooks] when appropriate.
class ResolverVisitorForMigration extends ResolverVisitor {
  final MigrationResolutionHooks _migrationResolutionHooks;

  ResolverVisitorForMigration(
      InheritanceManager3 inheritanceManager,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      TypeSystemImpl typeSystem,
      FeatureSet featureSet,
      MigrationResolutionHooks migrationResolutionHooks)
      : _migrationResolutionHooks = migrationResolutionHooks,
        super._(
            inheritanceManager,
            definingLibrary,
            source,
            typeSystem,
            typeProvider,
            errorListener,
            featureSet,
            null,
            true,
            FlowAnalysisHelperForMigration(
                typeSystem, migrationResolutionHooks),
            migrationResolutionHooks,
            migrationResolutionHooks);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitConditionalExpression(node);
      return;
    } else {
      var subexpressionToKeep =
          conditionalKnownValue ? node.thenExpression : node.elseExpression;
      subexpressionToKeep.accept(this);
      typeAnalyzer.recordStaticType(node, subexpressionToKeep.staticType);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitIfElement(node);
      return;
    } else {
      (conditionalKnownValue ? node.thenElement : node.elseElement)
          ?.accept(this);
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    var conditionalKnownValue =
        _migrationResolutionHooks.getConditionalKnownValue(node);
    if (conditionalKnownValue == null) {
      super.visitIfStatement(node);
      return;
    } else {
      (conditionalKnownValue ? node.thenStatement : node.elseStatement)
          ?.accept(this);
    }
  }
}

/// The abstract class `ScopedVisitor` maintains name and label scopes as an AST
/// structure is being visited.
abstract class ScopedVisitor extends UnifyingAstVisitor<void> {
  static const _nameScopeProperty = 'nameScope';

  /// The element for the library containing the compilation unit being visited.
  final LibraryElement definingLibrary;

  /// The source representing the compilation unit being visited.
  final Source source;

  /// The object used to access the types from the core library.
  final TypeProviderImpl typeProvider;

  /// The error reporter that will be informed of any errors that are found
  /// during resolution.
  final ErrorReporter errorReporter;

  /// The scope used to resolve identifiers.
  Scope nameScope;

  /// The scope used to resolve unlabeled `break` and `continue` statements.
  ImplicitLabelScope _implicitLabelScope = ImplicitLabelScope.ROOT;

  /// The scope used to resolve labels for `break` and `continue` statements, or
  /// `null` if no labels have been defined in the current context.
  LabelScope labelScope;

  /// The class containing the AST nodes being visited,
  /// or `null` if we are not in the scope of a class.
  ClassElement enclosingClass;

  /// The element representing the extension containing the AST nodes being
  /// visited, or `null` if we are not in the scope of an extension.
  ExtensionElement enclosingExtension;

  /// Initialize a newly created visitor to resolve the nodes in a compilation
  /// unit.
  ///
  /// [definingLibrary] is the element for the library containing the
  /// compilation unit being visited.
  /// [source] is the source representing the compilation unit being visited.
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.  If `null` or unspecified, a new [LibraryScope] will be
  /// created based on [definingLibrary] and [typeProvider].
  ScopedVisitor(this.definingLibrary, Source source, this.typeProvider,
      AnalysisErrorListener errorListener,
      {Scope nameScope})
      : source = source,
        errorReporter = ErrorReporter(
          errorListener,
          source,
          isNonNullableByDefault: definingLibrary.isNonNullableByDefault,
        ) {
    if (nameScope == null) {
      this.nameScope = LibraryScope(definingLibrary);
    } else {
      this.nameScope = nameScope;
    }
  }

  /// Return the implicit label scope in which the current node is being
  /// resolved.
  ImplicitLabelScope get implicitLabelScope => _implicitLabelScope;

  /// Replaces the current [Scope] with the enclosing [Scope].
  ///
  /// @return the enclosing [Scope].
  Scope popNameScope() {
    nameScope = (nameScope as EnclosedScope).parent;
    return nameScope;
  }

  /// Pushes a new [Scope] into the visitor.
  ///
  /// @return the new [Scope].
  Scope pushNameScope() {
    Scope newScope = LocalScope(nameScope);
    nameScope = newScope;
    return nameScope;
  }

  @override
  void visitBlock(Block node) {
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
  void visitCatchClause(CatchClause node) {
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      Scope outerScope = nameScope;
      try {
        nameScope = LocalScope(nameScope);
        _define(exception.staticElement);
        SimpleIdentifier stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          _define(stackTrace.staticElement);
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
  void visitClassDeclaration(ClassDeclaration node) {
    Scope outerScope = nameScope;
    ClassElement outerClass = enclosingClass;
    try {
      ClassElement element = node.declaredElement;
      enclosingClass = node.declaredElement;

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      visitClassDeclarationInScope(node);

      nameScope = ClassScope(nameScope, element);
      visitClassMembersInScope(node);
    } finally {
      enclosingClass = outerClass;
      nameScope = outerScope;
    }
  }

  void visitClassDeclarationInScope(ClassDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    node.nativeClause?.accept(this);
  }

  void visitClassMembersInScope(ClassDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.members.accept(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      ClassElement element = node.declaredElement;
      nameScope = ClassScope(
        TypeParameterScope(nameScope, element.typeParameters),
        element,
      );
      super.visitClassTypeAlias(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _setNodeNameScope(node, nameScope);
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ConstructorElement element = node.declaredElement;

      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.name?.accept(this);
      node.parameters?.accept(this);

      try {
        nameScope = ConstructorInitializerScope(
          nameScope,
          element,
        );
        node.initializers.accept(this);
      } finally {
        nameScope = outerScope;
      }

      node.redirectedConstructor?.accept(this);

      nameScope = FormalParameterScope(
        nameScope,
        element.parameters,
      );
      visitConstructorDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitConstructorDeclarationInScope(ConstructorDeclaration node) {
    node.body?.accept(this);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _define(node.declaredElement);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitDoStatementInScope(node);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  void visitDoStatementInScope(DoStatement node) {
    visitStatementInScope(node.body);
    node.condition?.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    Scope outerScope = nameScope;
    ClassElement outerClass = enclosingClass;
    try {
      ClassElement element = node.declaredElement;
      enclosingClass = node.declaredElement;

      nameScope = ClassScope(nameScope, element);
      visitEnumMembersInScope(node);
    } finally {
      enclosingClass = outerClass;
      nameScope = outerScope;
    }
  }

  void visitEnumMembersInScope(EnumDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.constants.accept(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _setNodeNameScope(node, nameScope);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    Scope outerScope = nameScope;
    ExtensionElement outerExtension = enclosingExtension;
    try {
      ExtensionElement element = node.declaredElement;
      enclosingExtension = element;

      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      visitExtensionDeclarationInScope(node);

      nameScope = ExtensionScope(nameScope, element);
      visitExtensionMembersInScope(node);
    } finally {
      enclosingExtension = outerExtension;
      nameScope = outerScope;
    }
  }

  void visitExtensionDeclarationInScope(ExtensionDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.extendedType?.accept(this);
  }

  void visitExtensionMembersInScope(ExtensionDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.members.accept(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    //
    // We visit the iterator before the loop variable because the loop variable
    // cannot be in scope while visiting the iterator.
    //
    node.iterable?.accept(this);
    node.loopVariable?.accept(this);
  }

  @override
  void visitForElement(ForElement node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = LocalScope(nameScope);
      _setNodeNameScope(node, nameScope);
      visitForElementInScope(node);
    } finally {
      nameScope = outerNameScope;
    }
  }

  /// Visit the given [node] after it's scope has been created. This replaces
  /// the normal call to the inherited visit method so that ResolverVisitor can
  /// intervene when type propagation is enabled.
  void visitForElementInScope(ForElement node) {
    // TODO(brianwilkerson) Investigate the possibility of removing the
    //  visit...InScope methods now that type propagation is no longer done.
    node.forLoopParts?.accept(this);
    node.body?.accept(this);
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
        parent.declaredElement.parameters,
      );
    } else if (parent is FunctionTypeAlias) {
      var aliasedElement = parent.declaredElement.aliasedElement;
      var functionElement = aliasedElement as GenericFunctionTypeElement;
      nameScope = FormalParameterScope(
        nameScope,
        functionElement.parameters,
      );
    } else if (parent is MethodDeclaration) {
      nameScope = FormalParameterScope(
        nameScope,
        parent.declaredElement.parameters,
      );
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Scope outerNameScope = nameScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      nameScope = LocalScope(nameScope);
      _implicitLabelScope = _implicitLabelScope.nest(node);
      _setNodeNameScope(node, nameScope);
      visitForStatementInScope(node);
    } finally {
      nameScope = outerNameScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Visit the given [node] after it's scope has been created. This replaces
  /// the normal call to the inherited visit method so that ResolverVisitor can
  /// intervene when type propagation is enabled.
  void visitForStatementInScope(ForStatement node) {
    // TODO(brianwilkerson) Investigate the possibility of removing the
    //  visit...InScope methods now that type propagation is no longer done.
    node.forLoopParts?.accept(this);
    visitStatementInScope(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      visitFunctionDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // We have already created a function scope and don't need to do so again.
      super.visitFunctionExpression(node);
      return;
    }

    Scope outerScope = nameScope;
    try {
      ExecutableElement element = node.declaredElement;
      nameScope = FormalParameterScope(
        TypeParameterScope(nameScope, element.typeParameters),
        element.parameters,
      );
      super.visitFunctionExpression(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      visitFunctionTypeAliasInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitFunctionTypeAliasInScope(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    Scope outerScope = nameScope;
    try {
      ParameterElement element = node.declaredElement;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      super.visitFunctionTypedFormalParameter(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    DartType type = node.type;
    if (type == null) {
      // The function type hasn't been resolved yet, so we can't create a scope
      // for its parameters.
      super.visitGenericFunctionType(node);
      return;
    }

    Scope outerScope = nameScope;
    try {
      GenericFunctionTypeElement element =
          (node as GenericFunctionTypeImpl).declaredElement;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      super.visitGenericFunctionType(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      var element = node.declaredElement as TypeAliasElement;
      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      super.visitGenericTypeAlias(node);

      var aliasedElement = element.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        nameScope = FormalParameterScope(nameScope, aliasedElement.parameters);
        visitGenericTypeAliasInFunctionScope(node);
      }
    } finally {
      nameScope = outerScope;
    }
  }

  void visitGenericTypeAliasInFunctionScope(GenericTypeAlias node) {}

  @override
  void visitIfStatement(IfStatement node) {
    node.condition?.accept(this);
    visitStatementInScope(node.thenStatement);
    visitStatementInScope(node.elseStatement);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    LabelScope outerScope = _addScopesFor(node.labels, node.unlabeled);
    try {
      super.visitLabeledStatement(node);
    } finally {
      labelScope = outerScope;
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    Scope outerScope = nameScope;
    try {
      ExecutableElement element = node.declaredElement;
      nameScope = TypeParameterScope(
        nameScope,
        element.typeParameters,
      );
      visitMethodDeclarationInScope(node);
    } finally {
      nameScope = outerScope;
    }
  }

  void visitMethodDeclarationInScope(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    Scope outerScope = nameScope;
    ClassElement outerClass = enclosingClass;
    try {
      ClassElement element = node.declaredElement;
      enclosingClass = element;

      nameScope = TypeParameterScope(nameScope, element.typeParameters);
      visitMixinDeclarationInScope(node);

      nameScope = ClassScope(nameScope, element);
      visitMixinMembersInScope(node);
    } finally {
      nameScope = outerScope;
      enclosingClass = outerClass;
    }
  }

  void visitMixinDeclarationInScope(MixinDeclaration node) {
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
  }

  void visitMixinMembersInScope(MixinDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.members.accept(this);
  }

  /// Visit the given statement after it's scope has been created. This is used
  /// by ResolverVisitor to correctly visit the 'then' and 'else' statements of
  /// an 'if' statement.
  ///
  /// @param node the statement to be visited
  void visitStatementInScope(Statement node) {
    if (node is Block) {
      // Don't create a scope around a block because the block will create it's
      // own scope.
      visitBlock(node);
    } else if (node != null) {
      Scope outerNameScope = nameScope;
      try {
        nameScope = LocalScope(nameScope);
        node.accept(this);
      } finally {
        nameScope = outerNameScope;
      }
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    node.expression.accept(this);

    _withDeclaredLocals(node, node.statements, () {
      node.statements.accept(this);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _withDeclaredLocals(node, node.statements, () {
      node.statements.accept(this);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    LabelScope outerScope = labelScope;
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
      visitSwitchStatementInScope(node);
    } finally {
      labelScope = outerScope;
      _implicitLabelScope = outerImplicitScope;
    }
  }

  void visitSwitchStatementInScope(SwitchStatement node) {
    super.visitSwitchStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    if (node.parent.parent is ForParts) {
      _define(node.declaredElement);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.condition?.accept(this);
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);
      visitStatementInScope(node.body);
    } finally {
      _implicitLabelScope = outerImplicitScope;
    }
  }

  /// Add scopes for each of the given labels.
  ///
  /// @param labels the labels for which new scopes are to be added
  /// @return the scope that was in effect before the new scopes were added
  LabelScope _addScopesFor(NodeList<Label> labels, AstNode node) {
    LabelScope outerScope = labelScope;
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

  void _withDeclaredLocals(
    AstNode node,
    List<Statement> statements,
    void Function() f,
  ) {
    var outerScope = nameScope;
    try {
      var enclosedScope = LocalScope(nameScope);
      BlockScope.elementsInStatements(statements).forEach(enclosedScope.add);

      nameScope = enclosedScope;
      _setNodeNameScope(node, nameScope);

      f();
    } finally {
      nameScope = outerScope;
    }
  }

  /// Return the [Scope] to use while resolving inside the [node].
  ///
  /// Not every node has the scope set, for example we set the scopes for
  /// blocks, but statements don't have separate scopes. The compilation unit
  /// has the library scope.
  static Scope getNodeNameScope(AstNode node) {
    return node.getProperty(_nameScopeProperty);
  }

  /// Set the [Scope] to use while resolving inside the [node].
  static void _setNodeNameScope(AstNode node, Scope scope) {
    node.setProperty(_nameScopeProperty, scope);
  }
}

/// Instances of the class `VariableResolverVisitor` are used to resolve
/// [SimpleIdentifier]s to local variables and formal parameters.
class VariableResolverVisitor extends ScopedVisitor {
  /// The method or function that we are currently visiting, or `null` if we are
  /// not inside a method or function.
  ExecutableElement _enclosingFunction;

  /// The container with information about local variables.
  final LocalVariableInfo _localVariableInfo = LocalVariableInfo();

  /// Initialize a newly created visitor to resolve the nodes in an AST node.
  ///
  /// [definingLibrary] is the element for the library containing the node being
  /// visited.
  /// [source] is the source representing the compilation unit containing the
  /// node being visited
  /// [typeProvider] is the object used to access the types from the core
  /// library.
  /// [errorListener] is the error listener that will be informed of any errors
  /// that are found during resolution.
  /// [nameScope] is the scope used to resolve identifiers in the node that will
  /// first be visited.  If `null` or unspecified, a new [LibraryScope] will be
  /// created based on [definingLibrary] and [typeProvider].
  VariableResolverVisitor(LibraryElement definingLibrary, Source source,
      TypeProvider typeProvider, AnalysisErrorListener errorListener,
      {Scope nameScope})
      : super(definingLibrary, source, typeProvider as TypeProviderImpl,
            errorListener,
            nameScope: nameScope);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    assert(_localVariableInfo != null);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
      _enclosingFunction = node.declaredElement;
      super.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    assert(_localVariableInfo != null);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      (node.functionExpression.body as FunctionBodyImpl).localVariableInfo =
          _localVariableInfo;
      _enclosingFunction = node.declaredElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      try {
        (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
        _enclosingFunction = node.declaredElement;
        super.visitFunctionExpression(node);
      } finally {
        _enclosingFunction = outerFunction;
      }
    } else {
      super.visitFunctionExpression(node);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      (node.body as FunctionBodyImpl).localVariableInfo = _localVariableInfo;
      _enclosingFunction = node.declaredElement;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if already resolved - declaration or type.
    if (node.inDeclarationContext()) {
      return;
    }
    // Ignore if it cannot be a reference to a local variable.
    AstNode parent = node.parent;
    if (parent is FieldFormalParameter) {
      return;
    } else if (parent is ConstructorDeclaration && parent.returnType == node) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return;
    }
    // Ignore if qualified.
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return;
    }
    if (parent is PropertyAccess && identical(parent.propertyName, node)) {
      return;
    }
    if (parent is MethodInvocation &&
        identical(parent.methodName, node) &&
        parent.realTarget != null) {
      return;
    }
    if (parent is ConstructorName) {
      return;
    }
    if (parent is Label) {
      return;
    }
    // Prepare VariableElement.
    Element element = nameScope.lookup(node.name).getter;
    if (element is! VariableElement) {
      return;
    }
    // Must be local or parameter.
    ElementKind kind = element.kind;
    if (kind == ElementKind.LOCAL_VARIABLE || kind == ElementKind.PARAMETER) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        _localVariableInfo.potentiallyMutatedInScope.add(element);
        if (element.enclosingElement != _enclosingFunction) {
          _localVariableInfo.potentiallyMutatedInClosure.add(element);
        }
      }
    }
  }

  @override
  void visitTypeName(TypeName node) {}
}

/// Tracker for whether a `switch` statement has `default` or is on an
/// enumeration, and all the enum constants are covered.
class _SwitchExhaustiveness {
  /// If the switch is on an enumeration, the set of enum constants to cover.
  /// Otherwise `null`.
  final Set<FieldElement> _enumConstants;

  /// If the switch is on an enumeration, is `true` if the null value is
  /// covered, because the switch expression type is non-nullable, or `null`
  /// was covered explicitly.
  bool _isNullEnumValueCovered = false;

  bool isExhaustive = false;

  factory _SwitchExhaustiveness(DartType expressionType) {
    if (expressionType is InterfaceType) {
      var enum_ = expressionType.element;
      if (enum_ is EnumElementImpl) {
        return _SwitchExhaustiveness._(
          enum_.constants.toSet(),
          expressionType.nullabilitySuffix == NullabilitySuffix.none,
        );
      }
    }
    return _SwitchExhaustiveness._(null, false);
  }

  _SwitchExhaustiveness._(this._enumConstants, this._isNullEnumValueCovered);

  void visitSwitchMember(SwitchMember node) {
    if (_enumConstants != null && node is SwitchCase) {
      var element = _referencedElement(node.expression);
      if (element is PropertyAccessorElement) {
        _enumConstants.remove(element.variable);
      }

      if (node.expression is NullLiteral) {
        _isNullEnumValueCovered = true;
      }

      if (_enumConstants.isEmpty && _isNullEnumValueCovered) {
        isExhaustive = true;
      }
    } else if (node is SwitchDefault) {
      isExhaustive = true;
    }
  }

  static Element _referencedElement(Expression expression) {
    if (expression is PrefixedIdentifier) {
      return expression.staticElement;
    } else if (expression is PropertyAccess) {
      return expression.propertyName.staticElement;
    }
    return null;
  }
}
