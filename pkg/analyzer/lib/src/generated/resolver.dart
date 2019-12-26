// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart'
    show ConstructorMember, Member;
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/type_promotion_manager.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:meta/meta.dart';

export 'package:analyzer/dart/element/type_provider.dart';
export 'package:analyzer/src/dart/constant/constant_verifier.dart';
export 'package:analyzer/src/dart/resolver/exit_detector.dart';
export 'package:analyzer/src/dart/resolver/scope.dart';
export 'package:analyzer/src/generated/type_system.dart';

/// Maintains and manages contextual type information used for
/// inferring types.
class InferenceContext {
  // TODO(leafp): Consider replacing these node properties with a
  // hash table help in an instance of this class.
  static const String _typeProperty =
      'analyzer.src.generated.InferenceContext.contextType';

  final ResolverVisitor _resolver;

  /// Type provider, needed for type matching.
  final TypeProvider _typeProvider;

  /// The type system in use.
  final TypeSystemImpl _typeSystem;

  /// When no context type is available, this will track the least upper bound
  /// of all return statements in a lambda.
  ///
  /// This will always be kept in sync with [_returnStack].
  final List<DartType> _inferredReturn = <DartType>[];

  /// A stack of return types for all of the enclosing
  /// functions and methods.
  final List<DartType> _returnStack = <DartType>[];

  InferenceContext._(ResolverVisitor resolver)
      : _resolver = resolver,
        _typeProvider = resolver.typeProvider,
        _typeSystem = resolver.typeSystem;

  /// Get the return type of the current enclosing function, if any.
  ///
  /// The type returned for a function is the type that is expected
  /// to be used in a return or yield context.  For ordinary functions
  /// this is the same as the return type of the function.  For async
  /// functions returning Future<T> and for generator functions
  /// returning Stream<T> or Iterable<T>, this is T.
  DartType get returnContext =>
      _returnStack.isNotEmpty ? _returnStack.last : null;

  /// Records the type of the expression of a return statement.
  ///
  /// This will be used for inferring a block bodied lambda, if no context
  /// type was available.
  void addReturnOrYieldType(DartType type) {
    if (_returnStack.isEmpty) {
      return;
    }

    DartType inferred = _inferredReturn.last;
    if (inferred == null) {
      inferred = type;
    } else {
      inferred = _typeSystem.getLeastUpperBound(type, inferred);
      inferred = _resolver.toLegacyTypeIfOptOut(inferred);
    }
    _inferredReturn[_inferredReturn.length - 1] = inferred;
  }

  /// Pop a return type off of the return stack.
  ///
  /// Also record any inferred return type using [setType], unless this node
  /// already has a context type. This recorded type will be the least upper
  /// bound of all types added with [addReturnOrYieldType].
  void popReturnContext(FunctionBody node) {
    if (_returnStack.isNotEmpty && _inferredReturn.isNotEmpty) {
      // If NNBD, and the function body end is reachable, infer nullable.
      // If legacy, we consider the end as always reachable, and return Null.
      if (_resolver._isNonNullableByDefault) {
        var flow = _resolver._flowAnalysis?.flow;
        if (flow != null && flow.isReachable) {
          addReturnOrYieldType(_typeProvider.nullType);
        }
      } else {
        addReturnOrYieldType(_typeProvider.nullType);
      }

      DartType context = _returnStack.removeLast();
      DartType inferred = _inferredReturn.removeLast();
      context ??= DynamicTypeImpl.instance;
      inferred ??= DynamicTypeImpl.instance;

      if (_typeSystem.isSubtypeOf(inferred, context)) {
        setType(node, inferred);
      }
    } else {
      assert(false);
    }
  }

  /// Push a block function body's return type onto the return stack.
  void pushReturnContext(FunctionBody node) {
    _returnStack.add(getContext(node));
    _inferredReturn.add(null);
  }

  /// Clear the type information associated with [node].
  static void clearType(AstNode node) {
    node?.setProperty(_typeProperty, null);
  }

  /// Look for contextual type information attached to [node], and returns
  /// the type if found.
  ///
  /// The returned type may be partially or completely unknown, denoted with an
  /// unknown type `?`, for example `List<?>` or `(?, int) -> void`.
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

/// The four states of a field initialization state through a constructor
/// signature, not initialized, initialized in the field declaration,
/// initialized in the field formal, and finally, initialized in the
/// initializers list.
class INIT_STATE implements Comparable<INIT_STATE> {
  static const INIT_STATE NOT_INIT = INIT_STATE('NOT_INIT', 0);

  static const INIT_STATE INIT_IN_DECLARATION =
      INIT_STATE('INIT_IN_DECLARATION', 1);

  static const INIT_STATE INIT_IN_FIELD_FORMAL =
      INIT_STATE('INIT_IN_FIELD_FORMAL', 2);

  static const INIT_STATE INIT_IN_INITIALIZERS =
      INIT_STATE('INIT_IN_INITIALIZERS', 3);

  static const List<INIT_STATE> values = [
    NOT_INIT,
    INIT_IN_DECLARATION,
    INIT_IN_FIELD_FORMAL,
    INIT_IN_INITIALIZERS
  ];

  /// The name of this init state.
  final String name;

  /// The ordinal value of the init state.
  final int ordinal;

  const INIT_STATE(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(INIT_STATE other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// Instances of the class `ResolverVisitor` are used to resolve the nodes
/// within a single compilation unit.
class ResolverVisitor extends ScopedVisitor {
  /**
   * The manager for the inheritance mappings.
   */
  final InheritanceManager3 inheritance;

  /**
   * The feature set that is enabled for the current unit.
   */
  final FeatureSet _featureSet;

  final bool _uiAsCodeEnabled;

  final ElementTypeProvider _elementTypeProvider;

  /// Helper for checking potentially nullable dereferences.
  NullableDereferenceVerifier nullableDereferenceVerifier;

  /// Helper for extension method resolution.
  ExtensionMemberResolver extensionResolver;

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

  InferenceContext inferenceContext;

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
  final List<Expression> unfinishedNullShorts = [null];

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
      bool propagateTypes = true,
      reportConstEvaluationErrors = true,
      FlowAnalysisHelper flowAnalysisHelper})
      : this._(
            inheritanceManager,
            definingLibrary,
            source,
            definingLibrary.typeSystem,
            typeProvider,
            errorListener,
            featureSet ??
                definingLibrary.context.analysisOptions.contextFeatures,
            nameScope,
            propagateTypes,
            reportConstEvaluationErrors,
            flowAnalysisHelper,
            const ElementTypeProvider());

  ResolverVisitor._(
      this.inheritance,
      LibraryElement definingLibrary,
      Source source,
      this.typeSystem,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      FeatureSet featureSet,
      Scope nameScope,
      bool propagateTypes,
      reportConstEvaluationErrors,
      this._flowAnalysis,
      this._elementTypeProvider)
      : _featureSet = featureSet,
        _uiAsCodeEnabled =
            featureSet.isEnabled(Feature.control_flow_collections) ||
                featureSet.isEnabled(Feature.spread_collections),
        super(definingLibrary, source, typeProvider, errorListener,
            nameScope: nameScope) {
    this._promoteManager = TypePromotionManager(typeSystem);
    this.nullableDereferenceVerifier = NullableDereferenceVerifier(
      typeSystem,
      errorReporter,
    );
    this.extensionResolver = ExtensionMemberResolver(this);
    this.elementResolver = ElementResolver(this,
        reportConstEvaluationErrors: reportConstEvaluationErrors,
        elementTypeProvider: _elementTypeProvider);
    this.inferenceContext = InferenceContext._(this);
    this.typeAnalyzer = _makeStaticTypeAnalyzer(featureSet, _flowAnalysis);
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

  /**
   * Return `true` if NNBD is enabled for this compilation unit.
   */
  bool get _isNonNullableByDefault =>
      _featureSet.isEnabled(Feature.non_nullable);

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

  /// Given a downward inference type [fnType], and the declared
  /// [typeParameterList] for a function expression, determines if we can enable
  /// downward inference and if so, returns the function type to use for
  /// inference.
  ///
  /// This will return null if inference is not possible. This happens when
  /// there is no way we can find a subtype of the function type, given the
  /// provided type parameter list.
  FunctionType matchFunctionTypeParameters(
      TypeParameterList typeParameterList, FunctionType fnType) {
    if (typeParameterList == null) {
      if (fnType.typeFormals.isEmpty) {
        return fnType;
      }

      // A non-generic function cannot be a subtype of a generic one.
      return null;
    }

    NodeList<TypeParameter> typeParameters = typeParameterList.typeParameters;
    if (fnType.typeFormals.isEmpty) {
      // TODO(jmesserly): this is a legal subtype. We don't currently infer
      // here, but we could.  This is similar to
      // Dart2TypeSystem.inferFunctionTypeInstantiation, but we don't
      // have the FunctionType yet for the current node, so it's not quite
      // straightforward to apply.
      return null;
    }

    if (fnType.typeFormals.length != typeParameters.length) {
      // A subtype cannot have different number of type formals.
      return null;
    }

    // Same number of type formals. Instantiate the function type so its
    // parameter and return type are in terms of the surrounding context.
    return fnType.instantiate(typeParameters.map((TypeParameter t) {
      return t.declaredElement.instantiate(
        nullabilitySuffix: noneOrStarSuffix,
      );
    }).toList());
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
    typeAnalyzer.thisType = enclosingClass?.thisType;
    _enclosingFunction = enclosingExecutableElement;
  }

  /// A client is about to resolve a member in the given class declaration.
  void prepareToResolveMembersInClass(ClassDeclaration node) {
    _enclosingClassDeclaration = node;
    enclosingClass = node.declaredElement;
    typeAnalyzer.thisType = enclosingClass?.thisType;
  }

  /// Visit the given [comment] if it is not `null`.
  void safelyVisitComment(Comment comment) {
    if (comment != null) {
      super.visitComment(comment);
    }
  }

  /// If in a legacy library, return the legacy view on the [element].
  /// Otherwise, return the original element.
  T toLegacyElement<T extends Element>(T element) {
    if (_isNonNullableByDefault) return element;
    return Member.legacy(element);
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
    node.name?.accept(this);
    node.constructorName?.accept(this);
    Element element = node.element;
    if (element is ExecutableElement) {
      InferenceContext.setType(
          node.arguments, _elementTypeProvider.getExecutableType(element));
    }
    node.arguments?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    ElementAnnotationImpl elementAnnotationImpl = node.elementAnnotation;
    if (elementAnnotationImpl == null) {
      // Analyzer ignores annotations on "part of" directives.
      assert(parent is PartOfDirective);
    } else {
      elementAnnotationImpl.annotationAst = _createCloner().cloneNode(node);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    DartType callerType = InferenceContext.getContext(node);
    if (callerType is FunctionType) {
      Map<String, DartType> namedParameterTypes =
          callerType.namedParameterTypes;
      List<DartType> normalParameterTypes = callerType.normalParameterTypes;
      List<DartType> optionalParameterTypes = callerType.optionalParameterTypes;
      int normalCount = normalParameterTypes.length;
      int optionalCount = optionalParameterTypes.length;

      NodeList<Expression> arguments = node.arguments;
      Iterable<Expression> positional =
          arguments.takeWhile((l) => l is! NamedExpression);
      Iterable<Expression> required = positional.take(normalCount);
      Iterable<Expression> optional =
          positional.skip(normalCount).take(optionalCount);
      Iterable<Expression> named =
          arguments.skipWhile((l) => l is! NamedExpression);

      //TODO(leafp): Consider using the parameter elements here instead.
      //TODO(leafp): Make sure that the parameter elements are getting
      // setup correctly with inference.
      int index = 0;
      for (Expression argument in required) {
        InferenceContext.setType(argument, normalParameterTypes[index++]);
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
    super.visitArgumentList(node);
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
    _flowAnalysis?.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis?.flow?.assert_end();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    InferenceContext.setType(node.condition, typeProvider.boolType);
    _flowAnalysis?.flow?.assert_begin();
    node.condition?.accept(this);
    _flowAnalysis?.flow?.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis?.flow?.assert_end();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;

    left?.accept(this);

    var leftLocalVariable = _flowAnalysis?.assignmentExpression(node);

    TokenType operator = node.operator.type;
    if (operator == TokenType.EQ ||
        operator == TokenType.QUESTION_QUESTION_EQ) {
      InferenceContext.setType(right, left.staticType);
    }

    right?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.assignmentExpression_afterRight(
        node,
        leftLocalVariable,
        operator == TokenType.QUESTION_QUESTION_EQ
            ? node.rightHandSide.staticType
            : node.staticType);
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
    TokenType operator = node.operator.type;
    Expression left = node.leftOperand;
    Expression right = node.rightOperand;
    var flow = _flowAnalysis?.flow;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      InferenceContext.setType(left, typeProvider.boolType);
      InferenceContext.setType(right, typeProvider.boolType);

      // TODO(scheglov) Do we need these checks for null?
      left?.accept(this);

      if (_flowAnalysis != null) {
        flow?.logicalBinaryOp_rightBegin(left, isAnd: true);
        _flowAnalysis.checkUnreachableNode(right);
        right.accept(this);
        flow?.logicalBinaryOp_end(node, right, isAnd: true);
      } else {
        _promoteManager.visitBinaryExpression_and_rhs(
          left,
          right,
          () {
            right.accept(this);
          },
        );
      }

      node.accept(elementResolver);
    } else if (operator == TokenType.BAR_BAR) {
      InferenceContext.setType(left, typeProvider.boolType);
      InferenceContext.setType(right, typeProvider.boolType);

      left?.accept(this);

      flow?.logicalBinaryOp_rightBegin(left, isAnd: false);
      _flowAnalysis?.checkUnreachableNode(right);
      right.accept(this);
      flow?.logicalBinaryOp_end(node, right, isAnd: false);

      node.accept(elementResolver);
    } else if (operator == TokenType.BANG_EQ || operator == TokenType.EQ_EQ) {
      left.accept(this);
      _flowAnalysis?.flow?.equalityOp_rightBegin(left);
      right.accept(this);
      node.accept(elementResolver);
      _flowAnalysis?.flow?.equalityOp_end(node, right,
          notEqual: operator == TokenType.BANG_EQ);
    } else {
      if (operator == TokenType.QUESTION_QUESTION) {
        InferenceContext.setTypeFromNode(left, node);
      }
      left?.accept(this);

      // Call ElementResolver.visitBinaryExpression to resolve the user-defined
      // operator method, if applicable.
      node.accept(elementResolver);

      if (operator == TokenType.QUESTION_QUESTION) {
        // Set the right side, either from the context, or using the information
        // from the left side if it is more precise.
        DartType contextType = InferenceContext.getContext(node);
        DartType leftType = left?.staticType;
        if (contextType == null || contextType.isDynamic) {
          contextType = leftType;
        }
        InferenceContext.setType(right, contextType);
      } else {
        var invokeType = node.staticInvokeType;
        if (invokeType != null && invokeType.parameters.isNotEmpty) {
          // If this is a user-defined operator, set the right operand context
          // using the operator method's parameter type.
          var rightParam = invokeType.parameters[0];
          InferenceContext.setType(
              right, _elementTypeProvider.getVariableType(rightParam));
        }
      }

      if (operator == TokenType.QUESTION_QUESTION) {
        flow?.ifNullExpression_rightBegin(node.leftOperand);
        right.accept(this);
        flow?.ifNullExpression_end();
      } else {
        right?.accept(this);
      }
    }
    node.accept(typeAnalyzer);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    try {
      inferenceContext.pushReturnContext(node);
      super.visitBlockFunctionBody(node);
    } finally {
      inferenceContext.popReturnContext(node);
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
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.breakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    InferenceContext.setTypeFromNode(node.target, node);
    super.visitCascadeExpression(node);
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
      typeAnalyzer.thisType = enclosingClass?.thisType;
      super.visitClassDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.thisType;
      enclosingClass = outerType;
      _enclosingClassDeclaration = null;
    }
  }

  @override
  void visitComment(Comment node) {
    AstNode parent = node.parent;
    if (parent is FunctionDeclaration ||
        parent is FunctionTypeAlias ||
        parent is ConstructorDeclaration ||
        parent is MethodDeclaration) {
      return;
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

    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);

    Expression thenExpression = node.thenExpression;
    InferenceContext.setTypeFromNode(thenExpression, node);

    if (_flowAnalysis != null) {
      if (flow != null) {
        flow.conditional_thenBegin(condition);
        _flowAnalysis.checkUnreachableNode(thenExpression);
      }
      thenExpression.accept(this);
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
      _flowAnalysis.checkUnreachableNode(elseExpression);
      elseExpression.accept(this);
      flow.conditional_end(node, elseExpression);
    } else {
      elseExpression.accept(this);
    }

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _flowAnalysis?.topLevelDeclaration_enter(
          node, node.parameters, node.body);
      _flowAnalysis?.executableDeclaration_enter(node, node.parameters, false);
      _promoteManager.enterFunctionBody(node.body);
      _enclosingFunction = node.declaredElement;
      FunctionType type =
          _elementTypeProvider.getExecutableType(_enclosingFunction);
      InferenceContext.setType(node.body, type.returnType);
      super.visitConstructorDeclaration(node);
    } finally {
      _flowAnalysis?.executableDeclaration_exit(node.body, false);
      _flowAnalysis?.topLevelDeclaration_exit();
      _promoteManager.exitFunctionBody();
      _enclosingFunction = outerFunction;
    }
    ConstructorElementImpl constructor = node.declaredElement;
    constructor.constantInitializers =
        _createCloner().cloneNodeList(node.initializers);
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
    InferenceContext.setType(
        node.expression, _elementTypeProvider.safeFieldType(fieldElement));
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
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
    _flowAnalysis?.continueStatement(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    InferenceContext.setType(node.defaultValue,
        _elementTypeProvider.safeVariableType(node.declaredElement));
    super.visitDefaultFormalParameter(node);
    ParameterElement element = node.declaredElement;

    if (element.initializer != null && node.defaultValue != null) {
      (element.initializer as FunctionElementImpl).returnType =
          node.defaultValue.staticType;
    }
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
    _flowAnalysis?.checkUnreachableNode(node);

    var body = node.body;
    var condition = node.condition;

    InferenceContext.setType(node.condition, typeProvider.boolType);

    _flowAnalysis?.flow?.doStatement_bodyBegin(node);
    visitStatementInScope(body);

    _flowAnalysis?.flow?.doStatement_conditionBegin();
    condition.accept(this);

    _flowAnalysis?.flow?.doStatement_end(node.condition);
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
      typeAnalyzer.thisType = enclosingClass?.thisType;
      super.visitEnumDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.thisType;
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
      InferenceContext.setTypeFromNode(node.expression, node);
      inferenceContext.pushReturnContext(node);
      super.visitExpressionFunctionBody(node);

      _flowAnalysis?.flow?.handleExit();

      DartType type = node.expression.staticType;
      if (_enclosingFunction.isAsynchronous) {
        type = typeSystem.flatten(type);
      }
      if (type != null) {
        inferenceContext.addReturnOrYieldType(type);
      }
    } finally {
      inferenceContext.popReturnContext(node);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    //
    // Resolve the metadata in the library scope
    // and associate the annotations with the element.
    //
    if (node.metadata != null) {
      node.metadata.accept(this);
      ElementResolver.resolveMetadata(node);
    }
    //
    // Continue the extension resolution.
    //
    try {
      typeAnalyzer.thisType = node.declaredElement.extendedType;
      super.visitExtensionDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = null;
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
  void visitForElementInScope(ForElement node) {
    ForLoopParts forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(this);
      } else if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      }
      var condition = forLoopParts.condition;
      InferenceContext.setType(condition, typeProvider.boolType);
      _flowAnalysis?.for_conditionBegin(node, condition);
      condition?.accept(this);
      _flowAnalysis?.for_bodyBegin(node, condition);
      node.body?.accept(this);
      _flowAnalysis?.flow?.for_updaterBegin();
      forLoopParts.updaters.accept(this);
      _flowAnalysis?.flow?.for_end();
    } else if (forLoopParts is ForEachParts) {
      Expression iterable = forLoopParts.iterable;
      DeclaredIdentifier loopVariable;
      DartType valueType;
      Element identifierElement;
      if (forLoopParts is ForEachPartsWithDeclaration) {
        loopVariable = forLoopParts.loopVariable;
        valueType = loopVariable?.type?.type ?? UnknownInferredType.instance;
      } else if (forLoopParts is ForEachPartsWithIdentifier) {
        SimpleIdentifier identifier = forLoopParts.identifier;
        identifier?.accept(this);
        identifierElement = identifier?.staticElement;
        if (identifierElement is VariableElement) {
          valueType = _elementTypeProvider.getVariableType(identifierElement);
        } else if (identifierElement is PropertyAccessorElement) {
          var parameters =
              _elementTypeProvider.getExecutableParameters(identifierElement);
          if (parameters.isNotEmpty) {
            valueType = _elementTypeProvider.getVariableType(parameters[0]);
          }
        }
      }

      if (valueType != null) {
        InterfaceType targetType = (node.awaitKeyword == null)
            ? typeProvider.iterableType2(valueType)
            : typeProvider.streamType2(valueType);
        InferenceContext.setType(iterable, targetType);
      }
      //
      // We visit the iterator before the loop variable because the loop
      // variable cannot be in scope while visiting the iterator.
      //
      iterable?.accept(this);
      // Note: the iterable could have been rewritten so grab it from
      // forLoopParts again.
      iterable = forLoopParts.iterable;
      loopVariable?.accept(this);
      var elementType = typeAnalyzer.computeForEachElementType(
          iterable, node.awaitKeyword != null);
      if (loopVariable != null &&
          elementType != null &&
          loopVariable.type == null) {
        var loopVariableElement =
            loopVariable.declaredElement as LocalVariableElementImpl;
        loopVariableElement.type = elementType;
      }
      _flowAnalysis?.flow?.forEach_bodyBegin(
          node,
          identifierElement is VariableElement
              ? identifierElement
              : loopVariable?.declaredElement,
          elementType ?? typeProvider.dynamicType);
      node.body?.accept(this);
      _flowAnalysis?.flow?.forEach_end();

      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    }
  }

  @override
  void visitForStatementInScope(ForStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    ForLoopParts forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(this);
      } else if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      }

      var condition = forLoopParts.condition;
      InferenceContext.setType(condition, typeProvider.boolType);

      _flowAnalysis?.for_conditionBegin(node, condition);
      if (condition != null) {
        condition.accept(this);
      }

      _flowAnalysis?.for_bodyBegin(node, condition);
      visitStatementInScope(node.body);

      _flowAnalysis?.flow?.for_updaterBegin();
      forLoopParts.updaters.accept(this);

      _flowAnalysis?.flow?.for_end();
    } else if (forLoopParts is ForEachParts) {
      Expression iterable = forLoopParts.iterable;
      DeclaredIdentifier loopVariable;
      SimpleIdentifier identifier;
      Element identifierElement;
      if (forLoopParts is ForEachPartsWithDeclaration) {
        loopVariable = forLoopParts.loopVariable;
      } else if (forLoopParts is ForEachPartsWithIdentifier) {
        identifier = forLoopParts.identifier;
        identifier?.accept(this);
      }

      DartType valueType;
      if (loopVariable != null) {
        TypeAnnotation typeAnnotation = loopVariable.type;
        valueType = typeAnnotation?.type ?? UnknownInferredType.instance;
      }
      if (identifier != null) {
        identifierElement = identifier.staticElement;
        if (identifierElement is VariableElement) {
          valueType = _elementTypeProvider.getVariableType(identifierElement);
        } else if (identifierElement is PropertyAccessorElement) {
          var parameters =
              _elementTypeProvider.getExecutableParameters(identifierElement);
          if (parameters.isNotEmpty) {
            valueType = _elementTypeProvider.getVariableType(parameters[0]);
          }
        }
      }
      if (valueType != null) {
        InterfaceType targetType = (node.awaitKeyword == null)
            ? typeProvider.iterableType2(valueType)
            : typeProvider.streamType2(valueType);
        InferenceContext.setType(iterable, targetType);
      }
      //
      // We visit the iterator before the loop variable because the loop variable
      // cannot be in scope while visiting the iterator.
      //
      iterable?.accept(this);
      // Note: the iterable could have been rewritten so grab it from
      // forLoopParts again.
      iterable = forLoopParts.iterable;
      loopVariable?.accept(this);
      var elementType = typeAnalyzer.computeForEachElementType(
          iterable, node.awaitKeyword != null);
      if (loopVariable != null &&
          elementType != null &&
          loopVariable.type == null) {
        var loopVariableElement =
            loopVariable.declaredElement as LocalVariableElementImpl;
        loopVariableElement.type = elementType;
      }

      _flowAnalysis?.flow?.forEach_bodyBegin(
          node,
          identifierElement is VariableElement
              ? identifierElement
              : loopVariable?.declaredElement,
          elementType ?? typeProvider.dynamicType);

      Statement body = node.body;
      if (body != null) {
        visitStatementInScope(body);
      }

      _flowAnalysis?.flow?.forEach_end();

      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    bool isFunctionDeclarationStatement =
        node.parent is FunctionDeclarationStatement;
    try {
      SimpleIdentifier functionName = node.name;
      if (_flowAnalysis != null) {
        if (isFunctionDeclarationStatement) {
          _flowAnalysis.flow.functionExpression_begin(node);
        } else {
          _flowAnalysis.topLevelDeclaration_enter(node,
              node.functionExpression.parameters, node.functionExpression.body);
        }
        _flowAnalysis.executableDeclaration_enter(node,
            node.functionExpression.parameters, isFunctionDeclarationStatement);
      }
      _promoteManager.enterFunctionBody(node.functionExpression.body);
      _enclosingFunction = functionName.staticElement as ExecutableElement;
      InferenceContext.setType(node.functionExpression,
          _elementTypeProvider.getExecutableType(_enclosingFunction));
      super.visitFunctionDeclaration(node);
    } finally {
      if (_flowAnalysis != null) {
        _flowAnalysis.executableDeclaration_exit(
            node.functionExpression.body, isFunctionDeclarationStatement);
        if (isFunctionDeclarationStatement) {
          _flowAnalysis.flow.functionExpression_end();
        } else {
          _flowAnalysis.topLevelDeclaration_exit();
        }
      }
      _promoteManager.exitFunctionBody();
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionDeclarationInScope(FunctionDeclaration node) {
    super.visitFunctionDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    ExecutableElement outerFunction = _enclosingFunction;
    bool isFunctionDeclaration = node.parent is FunctionDeclaration;
    try {
      if (_flowAnalysis != null) {
        if (!isFunctionDeclaration) {
          _flowAnalysis.flow.functionExpression_begin(node);
        }
      } else {
        _promoteManager.enterFunctionBody(node.body);
      }

      _enclosingFunction = node.declaredElement;
      DartType functionType = InferenceContext.getContext(node);
      if (functionType is FunctionType) {
        functionType =
            matchFunctionTypeParameters(node.typeParameters, functionType);
        if (functionType is FunctionType) {
          typeAnalyzer.inferFormalParameterList(node.parameters, functionType);
          InferenceContext.setType(
              node.body, _computeReturnOrYieldType(functionType.returnType));
        }
      }
      super.visitFunctionExpression(node);
    } finally {
      if (_flowAnalysis != null) {
        if (!isFunctionDeclaration) {
          _flowAnalysis.flow?.functionExpression_end();
        }
      } else {
        _promoteManager.exitFunctionBody();
      }

      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function?.accept(this);
    node.accept(elementResolver);
    _visitFunctionExpressionInvocation(node);
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
    Expression condition = node.condition;
    InferenceContext.setType(condition, typeProvider.boolType);
    // TODO(scheglov) Do we need these checks for null?
    condition?.accept(this);

    CollectionElement thenElement = node.thenElement;
    if (_flowAnalysis != null) {
      _flowAnalysis.flow.ifStatement_thenBegin(condition);
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
    _flowAnalysis?.checkUnreachableNode(node);

    Expression condition = node.condition;

    InferenceContext.setType(condition, typeProvider.boolType);
    condition?.accept(this);

    Statement thenStatement = node.thenStatement;
    if (_flowAnalysis != null) {
      _flowAnalysis.flow.ifStatement_thenBegin(condition);
      visitStatementInScope(thenStatement);
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
    }

    _flowAnalysis?.flow?.ifStatement_end(elseStatement != null);

    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    if (node.isNullAware && _isNonNullableByDefault) {
      _flowAnalysis.flow.nullAwareAccess_rightBegin(node.target);
      unfinishedNullShorts.add(node.nullShortingTermination);
    }
    node.accept(elementResolver);
    var method = node.staticElement;
    if (method != null) {
      var parameters = _elementTypeProvider.getExecutableParameters(method);
      if (parameters.isNotEmpty) {
        var indexParam = parameters[0];
        InferenceContext.setType(
            node.index, _elementTypeProvider.getVariableType(indexParam));
      }
    }
    node.index?.accept(this);
    node.accept(typeAnalyzer);
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
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitListLiteral(ListLiteral node) {
    InterfaceType listType;

    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      if (typeArguments.arguments.length == 1) {
        DartType elementType = typeArguments.arguments[0].type;
        if (!elementType.isDynamic) {
          listType = typeProvider.listType2(elementType);
        }
      }
    } else {
      listType = typeAnalyzer.inferListType(node, downwards: true);
    }
    if (listType != null) {
      DartType elementType = listType.typeArguments[0];
      DartType iterableType = typeProvider.iterableType2(elementType);
      _pushCollectionTypesDownToAll(node.elements,
          elementType: elementType, iterableType: iterableType);
      InferenceContext.setType(node, listType);
    } else {
      InferenceContext.clearType(node);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _flowAnalysis?.topLevelDeclaration_enter(
          node, node.parameters, node.body);
      _flowAnalysis?.executableDeclaration_enter(node, node.parameters, false);
      _promoteManager.enterFunctionBody(node.body);
      _enclosingFunction = node.declaredElement;
      DartType returnType = _computeReturnOrYieldType(
        _elementTypeProvider.safeExecutableReturnType(_enclosingFunction),
      );
      InferenceContext.setType(node.body, returnType);
      super.visitMethodDeclaration(node);
    } finally {
      _flowAnalysis?.executableDeclaration_exit(node.body, false);
      _flowAnalysis?.topLevelDeclaration_exit();
      _promoteManager.exitFunctionBody();
      _enclosingFunction = outerFunction;
    }
  }

  @override
  void visitMethodDeclarationInScope(MethodDeclaration node) {
    super.visitMethodDeclarationInScope(node);
    safelyVisitComment(node.documentationComment);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    //
    // We visit the target and argument list, but do not visit the method name
    // because it needs to be visited in the context of the invocation.
    //
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.accept(elementResolver);

    var functionRewrite = MethodInvocationResolver.getRewriteResult(node);
    if (functionRewrite != null) {
      _visitFunctionExpressionInvocation(functionRewrite);
    } else {
      _inferArgumentTypesForInvocation(node);
      node.argumentList?.accept(this);
      node.accept(typeAnalyzer);
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
      typeAnalyzer.thisType = enclosingClass?.thisType;
      super.visitMixinDeclaration(node);
      node.accept(elementResolver);
      node.accept(typeAnalyzer);
    } finally {
      typeAnalyzer.thisType = outerType?.thisType;
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
    _flowAnalysis?.checkUnreachableNode(node);
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
    super.visitPostfixExpression(node);

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      _flowAnalysis?.flow?.nonNullAssert_end(node.operand);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    //
    // We visit the prefix, but do not visit the identifier because it needs to
    // be visited in the context of the prefix.
    //
    node.prefix?.accept(this);
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    super.visitPrefixExpression(node);

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      _flowAnalysis?.flow?.logicalNot_end(node, node.operand);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    //
    // We visit the target, but do not visit the property name because it needs
    // to be visited in the context of the property access node.
    //
    node.target?.accept(this);
    if (node.isNullAware && _isNonNullableByDefault) {
      _flowAnalysis.flow.nullAwareAccess_rightBegin(node.target);
      unfinishedNullShorts.add(node.nullShortingTermination);
    }
    node.accept(elementResolver);
    node.accept(typeAnalyzer);
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
    InferenceContext.setType(node.argumentList,
        _elementTypeProvider.safeExecutableType(node.staticElement));
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
    InferenceContext.setType(node.expression, inferenceContext.returnContext);
    super.visitReturnStatement(node);
    DartType type = node.expression?.staticType;
    // Generators cannot return values, so don't try to do any inference if
    // we're processing erroneous code.
    if (type != null && _enclosingFunction?.isGenerator == false) {
      if (_enclosingFunction.isAsynchronous) {
        type = typeSystem.flatten(type);
      }
      inferenceContext.addReturnOrYieldType(type);
    }
    _flowAnalysis?.flow?.handleExit();
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments?.arguments;
    InterfaceType literalType;
    var literalResolution = _computeSetOrMapResolution(node);
    if (literalResolution.kind == _LiteralResolutionKind.set) {
      if (typeArguments != null && typeArguments.length == 1) {
        var elementType = typeArguments[0].type;
        literalType = typeProvider.setType2(elementType);
      } else {
        literalType = typeAnalyzer.inferSetTypeDownwards(
            node, literalResolution.contextType);
      }
    } else if (literalResolution.kind == _LiteralResolutionKind.map) {
      if (typeArguments != null && typeArguments.length == 2) {
        var keyType = typeArguments[0].type;
        var valueType = typeArguments[1].type;
        literalType = typeProvider.mapType2(keyType, valueType);
      } else {
        literalType = typeAnalyzer.inferMapTypeDownwards(
            node, literalResolution.contextType);
      }
    } else {
      assert(literalResolution.kind == _LiteralResolutionKind.ambiguous);
      literalType = null;
    }
    if (literalType is InterfaceType) {
      List<DartType> typeArguments = literalType.typeArguments;
      if (typeArguments.length == 1) {
        DartType elementType = literalType.typeArguments[0];
        DartType iterableType = typeProvider.iterableType2(elementType);
        _pushCollectionTypesDownToAll(node.elements,
            elementType: elementType, iterableType: iterableType);
        if (!_uiAsCodeEnabled &&
            node.elements.isEmpty &&
            node.typeArguments == null &&
            node.isMap) {
          // The node is really an empty set literal with no type arguments.
          (node as SetOrMapLiteralImpl).becomeMap();
        }
      } else if (typeArguments.length == 2) {
        DartType keyType = typeArguments[0];
        DartType valueType = typeArguments[1];
        _pushCollectionTypesDownToAll(node.elements,
            iterableType: literalType, keyType: keyType, valueType: valueType);
      }
      (node as SetOrMapLiteralImpl).contextType = literalType;
    } else {
      (node as SetOrMapLiteralImpl).contextType = null;
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }

    if (_flowAnalysis != null &&
        _flowAnalysis.isPotentiallyNonNullableLocalReadBeforeWrite(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode
            .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
        node,
        [node.name],
      );
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier
    // because it needs to be visited in the context of the constructor
    // invocation.
    //
    node.accept(elementResolver);
    InferenceContext.setType(node.argumentList,
        _elementTypeProvider.safeExecutableType(node.staticElement));
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _flowAnalysis?.checkUnreachableNode(node);

    InferenceContext.setType(
        node.expression, _enclosingSwitchStatementExpressionType);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchStatementInScope(SwitchStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    var previousExpressionType = _enclosingSwitchStatementExpressionType;
    try {
      var expression = node.expression;
      expression.accept(this);
      _enclosingSwitchStatementExpressionType = expression.staticType;

      if (_flowAnalysis != null) {
        var flow = _flowAnalysis.flow;

        flow.switchStatement_expressionEnd(node);

        var hasDefault = false;
        var members = node.members;
        for (var member in members) {
          flow.switchStatement_beginCase(member.labels.isNotEmpty, node);
          member.accept(this);

          if (member is SwitchDefault) {
            hasDefault = true;
          }
        }

        flow.switchStatement_end(hasDefault);
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

    _flowAnalysis.checkUnreachableNode(node);
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

      var catchLength = catchClauses.length;
      for (var i = 0; i < catchLength; ++i) {
        var catchClause = catchClauses[i];
        flow.tryCatchStatement_catchBegin(
            catchClause.exceptionParameter?.staticElement,
            catchClause.stackTraceParameter?.staticElement);
        catchClause.accept(this);
        flow.tryCatchStatement_catchEnd();
      }

      flow.tryCatchStatement_end();
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
    var grandParent = node.parent.parent;
    bool isTopLevel = grandParent is FieldDeclaration ||
        grandParent is TopLevelVariableDeclaration;
    InferenceContext.setTypeFromNode(node.initializer, node);
    if (isTopLevel) {
      _flowAnalysis?.topLevelDeclaration_enter(node, null, null);
    }
    super.visitVariableDeclaration(node);
    if (isTopLevel) {
      _flowAnalysis?.topLevelDeclaration_exit();
    }
    VariableElement element = node.declaredElement;
    if (element.initializer != null && node.initializer != null) {
      var initializer = element.initializer as FunctionElementImpl;
      initializer.returnType = node.initializer.staticType;
    }
    // Note: in addition to cloning the initializers for const variables, we
    // have to clone the initializers for non-static final fields (because if
    // they occur in a class with a const constructor, they will be needed to
    // evaluate the const constructor).
    if (element is ConstVariableElement) {
      (element as ConstVariableElement).constantInitializer =
          _createCloner().cloneNode(node.initializer);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _flowAnalysis?.variableDeclarationList(node);
    for (VariableDeclaration decl in node.variables) {
      VariableElement variableElement = decl.declaredElement;
      InferenceContext.setType(
          decl, _elementTypeProvider.safeVariableType(variableElement));
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _flowAnalysis?.checkUnreachableNode(node);

    // Note: since we don't call the base class, we have to maintain
    // _implicitLabelScope ourselves.
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      _implicitLabelScope = _implicitLabelScope.nest(node);

      Expression condition = node.condition;
      InferenceContext.setType(condition, typeProvider.boolType);

      _flowAnalysis?.flow?.whileStatement_conditionBegin(node);
      condition?.accept(this);

      Statement body = node.body;
      if (body != null) {
        _flowAnalysis?.flow?.whileStatement_bodyBegin(node, condition);
        visitStatementInScope(body);
        _flowAnalysis?.flow?.whileStatement_end();
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
    Expression e = node.expression;
    DartType returnType = inferenceContext.returnContext;
    bool isGenerator = _enclosingFunction?.isGenerator ?? false;
    if (returnType != null && isGenerator) {
      // If we're not in a generator ([a]sync*, then we shouldn't have a yield.
      // so don't infer

      // If this just a yield, then we just pass on the element type
      DartType type = returnType;
      if (node.star != null) {
        // If this is a yield*, then we wrap the element return type
        // If it's synchronous, we expect Iterable<T>, otherwise Stream<T>
        type = _enclosingFunction.isSynchronous
            ? typeProvider.iterableType2(type)
            : typeProvider.streamType2(type);
      }
      InferenceContext.setType(e, type);
    }
    super.visitYieldStatement(node);
    DartType type = e?.staticType;
    if (type != null && isGenerator) {
      // If this just a yield, then we just pass on the element type
      if (node.star != null) {
        // If this is a yield*, then we unwrap the element return type
        // If it's synchronous, we expect Iterable<T>, otherwise Stream<T>
        if (type is InterfaceType) {
          ClassElement wrapperElement = _enclosingFunction.isSynchronous
              ? typeProvider.iterableElement
              : typeProvider.streamElement;
          var asInstanceType =
              (type as InterfaceTypeImpl).asInstanceOf(wrapperElement);
          if (asInstanceType != null) {
            type = asInstanceType.typeArguments[0];
          }
        }
      }
      if (type != null) {
        inferenceContext.addReturnOrYieldType(type);
      }
    }
  }

  /// Given the declared return type of a function, compute the type of the
  /// values which should be returned or yielded as appropriate.  If a type
  /// cannot be computed from the declared return type, return null.
  DartType _computeReturnOrYieldType(DartType declaredType) {
    bool isGenerator = _enclosingFunction.isGenerator;
    bool isAsynchronous = _enclosingFunction.isAsynchronous;

    // Ordinary functions just return their declared types.
    if (!isGenerator && !isAsynchronous) {
      return declaredType;
    }
    if (declaredType is InterfaceType) {
      if (isGenerator) {
        // If it's sync* we expect Iterable<T>
        // If it's async* we expect Stream<T>
        // Match the types to instantiate the type arguments if possible
        List<DartType> targs = declaredType.typeArguments;
        if (targs.length == 1) {
          var arg = targs[0];
          if (isAsynchronous) {
            if (typeProvider.streamType2(arg) == declaredType) {
              return arg;
            }
          } else {
            if (typeProvider.iterableType2(arg) == declaredType) {
              return arg;
            }
          }
        }
      }
      // async functions expect `Future<T> | T`
      var futureTypeParam = typeSystem.flatten(declaredType);
      return _createFutureOr(futureTypeParam);
    }
    return declaredType;
  }

  /// Compute the context type for the given set or map [literal].
  _LiteralResolution _computeSetOrMapResolution(SetOrMapLiteral literal) {
    _LiteralResolution typeArgumentsResolution =
        _fromTypeArguments(literal.typeArguments);
    DartType contextType = InferenceContext.getContext(literal);
    _LiteralResolution contextResolution = _fromContextType(contextType);
    _LeafElements elementCounts = _LeafElements(literal.elements);
    _LiteralResolution elementResolution = elementCounts.resolution;

    List<_LiteralResolution> unambiguousResolutions = [];
    Set<_LiteralResolutionKind> kinds = <_LiteralResolutionKind>{};
    if (typeArgumentsResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(typeArgumentsResolution);
      kinds.add(typeArgumentsResolution.kind);
    }
    if (contextResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(contextResolution);
      kinds.add(contextResolution.kind);
    }
    if (elementResolution.kind != _LiteralResolutionKind.ambiguous) {
      unambiguousResolutions.add(elementResolution);
      kinds.add(elementResolution.kind);
    }

    if (kinds.length == 2) {
      // It looks like it needs to be both a map and a set. Attempt to recover.
      if (elementResolution.kind == _LiteralResolutionKind.ambiguous &&
          elementResolution.contextType != null) {
        return elementResolution;
      } else if (typeArgumentsResolution.kind !=
              _LiteralResolutionKind.ambiguous &&
          typeArgumentsResolution.contextType != null) {
        return typeArgumentsResolution;
      } else if (contextResolution.kind != _LiteralResolutionKind.ambiguous &&
          contextResolution.contextType != null) {
        return contextResolution;
      }
    } else if (unambiguousResolutions.length >= 2) {
      // If there are three resolutions, the last resolution is guaranteed to be
      // from the elements, which always has a context type of `null` (when it
      // is not ambiguous). So, whether there are 2 or 3 resolutions only the
      // first two are potentially interesting.
      return unambiguousResolutions[0].contextType == null
          ? unambiguousResolutions[1]
          : unambiguousResolutions[0];
    } else if (unambiguousResolutions.length == 1) {
      return unambiguousResolutions[0];
    } else if (literal.elements.isEmpty) {
      return _LiteralResolution(
          _LiteralResolutionKind.map,
          typeProvider.mapType2(
              typeProvider.dynamicType, typeProvider.dynamicType));
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
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

  /// If [contextType] is defined and is a subtype of `Iterable<Object>` and
  /// [contextType] is not a subtype of `Map<Object, Object>`, then *e* is a set
  /// literal.
  ///
  /// If [contextType] is defined and is a subtype of `Map<Object, Object>` and
  /// [contextType] is not a subtype of `Iterable<Object>` then *e* is a map
  /// literal.
  _LiteralResolution _fromContextType(DartType contextType) {
    if (contextType != null) {
      DartType unwrap(DartType type) {
        if (type is InterfaceType &&
            type.isDartAsyncFutureOr &&
            type.typeArguments.length == 1) {
          return unwrap(type.typeArguments[0]);
        }
        return type;
      }

      DartType unwrappedContextType = unwrap(contextType);
      // TODO(brianwilkerson) Find out what the "greatest closure" is and use that
      // where [unwrappedContextType] is used below.
      bool isIterable = typeSystem.isSubtypeOf(
          unwrappedContextType, typeProvider.iterableForSetMapDisambiguation);
      bool isMap = typeSystem.isSubtypeOf(
          unwrappedContextType, typeProvider.mapForSetMapDisambiguation);
      if (isIterable && !isMap) {
        return _LiteralResolution(
            _LiteralResolutionKind.set, unwrappedContextType);
      } else if (isMap && !isIterable) {
        return _LiteralResolution(
            _LiteralResolutionKind.map, unwrappedContextType);
      }
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Return the resolution that is indicated by the given [typeArgumentList].
  _LiteralResolution _fromTypeArguments(TypeArgumentList typeArgumentList) {
    if (typeArgumentList != null) {
      NodeList<TypeAnnotation> arguments = typeArgumentList.arguments;
      if (arguments.length == 1) {
        return _LiteralResolution(_LiteralResolutionKind.set,
            typeProvider.setType2(arguments[0].type));
      } else if (arguments.length == 2) {
        return _LiteralResolution(_LiteralResolutionKind.map,
            typeProvider.mapType2(arguments[0].type, arguments[1].type));
      }
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Return `true` if the given [parameter] element of the AST being resolved
  /// is resynthesized and is an API-level, not local, so has its initializer
  /// serialized.
  bool _hasSerializedConstantInitializer(ParameterElement parameter) {
    Element executable = parameter.enclosingElement;
    if (executable is MethodElement ||
        executable is FunctionElement &&
            executable.enclosingElement is CompilationUnitElement) {
      return LibraryElementImpl.hasResolutionCapability(
          definingLibrary, LibraryResolutionCapability.constantExpressions);
    }
    return false;
  }

  FunctionType _inferArgumentTypesForGeneric(AstNode inferenceNode,
      DartType uninstantiatedType, TypeArgumentList typeArguments,
      {AstNode errorNode, bool isConst = false}) {
    errorNode ??= inferenceNode;
    if (typeArguments == null &&
        uninstantiatedType is FunctionType &&
        uninstantiatedType.typeFormals.isNotEmpty) {
      var typeArguments = typeSystem.inferGenericFunctionOrType(
        typeParameters: uninstantiatedType.typeFormals,
        parameters: const <ParameterElement>[],
        declaredReturnType: uninstantiatedType.returnType,
        argumentTypes: const <DartType>[],
        contextReturnType: InferenceContext.getContext(inferenceNode),
        downwards: true,
        isConst: isConst,
        errorReporter: errorReporter,
        errorNode: errorNode,
        isNonNullableByDefault: _isNonNullableByDefault,
      );
      if (typeArguments != null) {
        return uninstantiatedType.instantiate(typeArguments);
      }
    }
    return null;
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

      FunctionType constructorType =
          typeAnalyzer.constructorToGenericFunctionType(rawElement);

      inferred = _inferArgumentTypesForGeneric(
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
        constructor.staticElement =
            ConstructorMember.from(rawElement, inferred.returnType);
        node.staticElement = constructor.staticElement;
      }
    }

    if (inferred == null) {
      InferenceContext.setType(node.argumentList,
          _elementTypeProvider.safeExecutableType(originalElement));
    }
  }

  void _inferArgumentTypesForInvocation(InvocationExpression node) {
    DartType inferred = _inferArgumentTypesForGeneric(
        node, node.function.staticType, node.typeArguments);
    InferenceContext.setType(
        node.argumentList, inferred ?? node.staticInvokeType);
  }

  StaticTypeAnalyzer _makeStaticTypeAnalyzer(
          FeatureSet featureSet, FlowAnalysisHelper flowAnalysis) =>
      StaticTypeAnalyzer(this, featureSet, flowAnalysis);

  void _pushCollectionTypesDown(CollectionElement element,
      {DartType elementType,
      @required DartType iterableType,
      DartType keyType,
      DartType valueType}) {
    if (element is ForElement) {
      _pushCollectionTypesDown(element.body,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    } else if (element is IfElement) {
      _pushCollectionTypesDown(element.thenElement,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
      _pushCollectionTypesDown(element.elseElement,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    } else if (element is Expression) {
      InferenceContext.setType(element, elementType);
    } else if (element is MapLiteralEntry) {
      InferenceContext.setType(element.key, keyType);
      InferenceContext.setType(element.value, valueType);
    } else if (element is SpreadElement) {
      InferenceContext.setType(element.expression, iterableType);
    }
  }

  void _pushCollectionTypesDownToAll(List<CollectionElement> elements,
      {DartType elementType,
      @required DartType iterableType,
      DartType keyType,
      DartType valueType}) {
    assert(iterableType != null);
    for (CollectionElement element in elements) {
      _pushCollectionTypesDown(element,
          elementType: elementType,
          iterableType: iterableType,
          keyType: keyType,
          valueType: valueType);
    }
  }

  /// Continues resolution of the [FunctionExpressionInvocation] node after
  /// resolving its function.
  void _visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _inferArgumentTypesForInvocation(node);
    node.argumentList?.accept(this);
    node.accept(typeAnalyzer);
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
        List<ParameterElement>(argumentCount);
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
  ResolverVisitorForMigration(
      InheritanceManager3 inheritanceManager,
      LibraryElement definingLibrary,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      TypeSystem typeSystem,
      FeatureSet featureSet,
      MigrationResolutionHooks migrationResolutionHooks)
      : super._(
            inheritanceManager,
            definingLibrary,
            source,
            typeSystem,
            typeProvider,
            errorListener,
            featureSet,
            null,
            true,
            true,
            FlowAnalysisHelperForMigration(
                typeSystem, migrationResolutionHooks),
            migrationResolutionHooks);

  @override
  void visitTypeName(TypeName node) {
    // TODO(paulberry): Need to handle generic function types too
    node.type = (_elementTypeProvider as MigrationResolutionHooks)
        .getMigratedTypeAnnotationType(source, node);
  }

  @override
  StaticTypeAnalyzer _makeStaticTypeAnalyzer(
          FeatureSet featureSet, FlowAnalysisHelper flowAnalysis) =>
      StaticTypeAnalyzerForMigration(
          this, featureSet, flowAnalysis, _elementTypeProvider);
}

/// The abstract class `ScopedVisitor` maintains name and label scopes as an AST
/// structure is being visited.
abstract class ScopedVisitor extends UnifyingAstVisitor<void> {
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
    nameScope = nameScope.enclosingScope;
    return nameScope;
  }

  /// Pushes a new [Scope] into the visitor.
  ///
  /// @return the new [Scope].
  Scope pushNameScope() {
    Scope newScope = EnclosedScope(nameScope);
    nameScope = newScope;
    return nameScope;
  }

  @override
  void visitBlock(Block node) {
    Scope outerScope = nameScope;
    try {
      EnclosedScope enclosedScope = BlockScope(nameScope, node);
      nameScope = enclosedScope;
      super.visitBlock(node);
    } finally {
      nameScope = outerScope;
    }
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
        nameScope = EnclosedScope(nameScope);
        nameScope.define(exception.staticElement);
        SimpleIdentifier stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          nameScope.define(stackTrace.staticElement);
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
    ClassElement classElement = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (classElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for class declaration ${node.name.name} in "
            "${definingLibrary.source.fullName}",
            CaughtException(AnalysisException(), null));
        super.visitClassDeclaration(node);
      } else {
        ClassElement outerClass = enclosingClass;
        try {
          enclosingClass = node.declaredElement;
          nameScope = TypeParameterScope(nameScope, classElement);
          visitClassDeclarationInScope(node);
          nameScope = ClassScope(nameScope, classElement);
          visitClassMembersInScope(node);
        } finally {
          enclosingClass = outerClass;
        }
      }
    } finally {
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
      nameScope = ClassScope(TypeParameterScope(nameScope, element), element);
      super.visitClassTypeAlias(node);
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement constructorElement = node.declaredElement;
    if (constructorElement == null) {
      StringBuffer buffer = StringBuffer();
      buffer.write("Missing element for constructor ");
      buffer.write(node.returnType.name);
      if (node.name != null) {
        buffer.write(".");
        buffer.write(node.name.name);
      }
      buffer.write(" in ");
      buffer.write(definingLibrary.source.fullName);
      AnalysisEngine.instance.instrumentationService.logInfo(buffer.toString());
    }
    Scope outerScope = nameScope;
    try {
      if (constructorElement != null) {
        nameScope = FunctionScope(nameScope, constructorElement);
      }
      node.documentationComment?.accept(this);
      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.name?.accept(this);
      node.parameters?.accept(this);
      Scope functionScope = nameScope;
      try {
        if (constructorElement != null) {
          nameScope =
              ConstructorInitializerScope(nameScope, constructorElement);
        }
        node.initializers.accept(this);
      } finally {
        nameScope = functionScope;
      }
      node.redirectedConstructor?.accept(this);
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
    VariableElement element = node.declaredElement;
    if (element != null) {
      nameScope.define(element);
    }
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
    ClassElement classElement = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (classElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for enum declaration ${node.name.name} in "
            "${definingLibrary.source.fullName}");
        super.visitEnumDeclaration(node);
      } else {
        ClassElement outerClass = enclosingClass;
        try {
          enclosingClass = node.declaredElement;
          nameScope = ClassScope(nameScope, classElement);
          visitEnumMembersInScope(node);
        } finally {
          enclosingClass = outerClass;
        }
      }
    } finally {
      nameScope = outerScope;
    }
  }

  void visitEnumMembersInScope(EnumDeclaration node) {
    node.documentationComment?.accept(this);
    node.metadata.accept(this);
    node.constants.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    ExtensionElement extensionElement = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (extensionElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for extension declaration ${node.name.name} "
            "in ${definingLibrary.source.fullName}");
        super.visitExtensionDeclaration(node);
      } else {
        ExtensionElement outerExtension = enclosingExtension;
        try {
          enclosingExtension = extensionElement;
          nameScope = TypeParameterScope(nameScope, extensionElement);
          visitExtensionDeclarationInScope(node);
          nameScope = ExtensionScope(nameScope, extensionElement);
          visitExtensionMembersInScope(node);
        } finally {
          enclosingExtension = outerExtension;
        }
      }
    } finally {
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
      nameScope = EnclosedScope(nameScope);
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
    if (nameScope is FunctionScope &&
        node.parent is! FunctionTypedFormalParameter) {
      (nameScope as FunctionScope).defineParameters();
    }
    if (nameScope is FunctionTypeScope) {
      (nameScope as FunctionTypeScope).defineParameters();
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    Scope outerNameScope = nameScope;
    ImplicitLabelScope outerImplicitScope = _implicitLabelScope;
    try {
      nameScope = EnclosedScope(nameScope);
      _implicitLabelScope = _implicitLabelScope.nest(node);
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
    ExecutableElement functionElement = node.declaredElement;
    if (functionElement != null &&
        functionElement.enclosingElement is! CompilationUnitElement) {
      nameScope.define(functionElement);
    }
    Scope outerScope = nameScope;
    try {
      if (functionElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for top-level function ${node.name.name} in "
            "${definingLibrary.source.fullName}");
      } else {
        nameScope = FunctionScope(nameScope, functionElement);
      }
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
    } else {
      Scope outerScope = nameScope;
      try {
        ExecutableElement functionElement = node.declaredElement;
        if (functionElement == null) {
          StringBuffer buffer = StringBuffer();
          buffer.write("Missing element for function ");
          AstNode parent = node.parent;
          while (parent != null) {
            if (parent is Declaration) {
              Element parentElement = parent.declaredElement;
              buffer.write(parentElement == null
                  ? "<unknown> "
                  : "${parentElement.name} ");
            }
            parent = parent.parent;
          }
          buffer.write("in ");
          buffer.write(definingLibrary.source.fullName);
          AnalysisEngine.instance.instrumentationService
              .logInfo(buffer.toString());
        } else {
          nameScope = FunctionScope(nameScope, functionElement);
        }
        super.visitFunctionExpression(node);
      } finally {
        nameScope = outerScope;
      }
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    Scope outerScope = nameScope;
    try {
      nameScope = FunctionTypeScope(nameScope, node.declaredElement);
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
      ParameterElement parameterElement = node.declaredElement;
      if (parameterElement == null) {
        AnalysisEngine.instance.instrumentationService.logInfo(
            "Missing element for function typed formal parameter "
            "${node.identifier.name} in ${definingLibrary.source.fullName}");
      } else {
        nameScope = EnclosedScope(nameScope);
        var typeParameters = parameterElement.typeParameters;
        int length = typeParameters.length;
        for (int i = 0; i < length; i++) {
          nameScope.define(typeParameters[i]);
        }
      }
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
    GenericFunctionTypeElement element =
        (node as GenericFunctionTypeImpl).declaredElement;
    Scope outerScope = nameScope;
    try {
      if (element == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo("Missing element for generic function type in "
                "${definingLibrary.source.fullName}");
        super.visitGenericFunctionType(node);
      } else {
        nameScope = TypeParameterScope(nameScope, element);
        super.visitGenericFunctionType(node);
      }
    } finally {
      nameScope = outerScope;
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    GenericTypeAliasElement element = node.declaredElement;
    Scope outerScope = nameScope;
    try {
      if (element == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo("Missing element for generic function type in "
                "${definingLibrary.source.fullName}");
        super.visitGenericTypeAlias(node);
      } else {
        nameScope = TypeParameterScope(nameScope, element);
        super.visitGenericTypeAlias(node);

        GenericFunctionTypeElement functionElement = element.function;
        if (functionElement != null) {
          nameScope = FunctionScope(nameScope, functionElement)
            ..defineParameters();
          visitGenericTypeAliasInFunctionScope(node);
        }
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
      ExecutableElement methodElement = node.declaredElement;
      if (methodElement == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo("Missing element for method ${node.name.name} in "
                "${definingLibrary.source.fullName}");
      } else {
        nameScope = FunctionScope(nameScope, methodElement);
      }
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
    ClassElement element = node.declaredElement;

    Scope outerScope = nameScope;
    ClassElement outerClass = enclosingClass;
    try {
      enclosingClass = element;

      nameScope = TypeParameterScope(nameScope, element);
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
        nameScope = EnclosedScope(nameScope);
        node.accept(this);
      } finally {
        nameScope = outerNameScope;
      }
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    node.expression.accept(this);
    Scope outerNameScope = nameScope;
    try {
      nameScope = EnclosedScope(nameScope);
      node.statements.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    Scope outerNameScope = nameScope;
    try {
      nameScope = EnclosedScope(nameScope);
      node.statements.accept(this);
    } finally {
      nameScope = outerNameScope;
    }
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
    if (node.parent.parent is! TopLevelVariableDeclaration &&
        node.parent.parent is! FieldDeclaration) {
      VariableElement element = node.declaredElement;
      if (element != null) {
        nameScope.define(element);
      }
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
}

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolveTypeName].
class TypeNameResolver {
  final TypeSystemImpl typeSystem;
  final DartType dynamicType;
  final bool isNonNullableByDefault;
  final AnalysisOptionsImpl analysisOptions;
  final LibraryElement definingLibrary;
  final Source source;
  final AnalysisErrorListener errorListener;

  /// Indicates whether bare typenames in "with" clauses should have their type
  /// inferred type arguments loaded from the element model.
  ///
  /// This is needed for mixin type inference, but is incompatible with the old
  /// task model.
  final bool shouldUseWithClauseInferredTypes;

  Scope nameScope;

  /// If [resolveTypeName] finds out that the given [TypeName] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName rewriteResult;

  TypeNameResolver(
      this.typeSystem,
      TypeProvider typeProvider,
      this.isNonNullableByDefault,
      this.definingLibrary,
      this.source,
      this.errorListener,
      {this.shouldUseWithClauseInferredTypes = true})
      : dynamicType = typeProvider.dynamicType,
        analysisOptions = definingLibrary.context.analysisOptions;

  NullabilitySuffix get _noneOrStarSuffix {
    return isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// Report an error with the given error code and arguments.
  ///
  /// @param errorCode the error code of the error to be reported
  /// @param node the node specifying the location of the error
  /// @param arguments the arguments to the error, used to compose the error
  ///        message
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    errorListener.onError(
        AnalysisError(source, node.offset, node.length, errorCode, arguments));
  }

  /// Resolve the given [TypeName] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolveTypeName].
  void resolveTypeName(TypeName node) {
    rewriteResult = null;
    Identifier typeName = node.name;
    _setElement(typeName, null); // Clear old Elements from previous run.
    TypeArgumentList argumentList = node.typeArguments;
    Element element = nameScope.lookup(typeName, definingLibrary);
    if (element == null) {
      //
      // Check to see whether the type name is either 'dynamic' or 'void',
      // neither of which are in the name scope and hence will not be found by
      // normal means.
      //
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        // There is no element for 'void'.
//        if (argumentList != null) {
//          // TODO(brianwilkerson) Report this error
//          reporter.reportError(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, node, voidType.getName(), 0, argumentList.getArguments().size());
//        }
        node.type = voidType;
        return;
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        node.type = dynamicType;
        return;
      }
      //
      // If not, the look to see whether we might have created the wrong AST
      // structure for a constructor name. If so, fix the AST structure and then
      // proceed.
      //
      AstNode parent = node.parent;
      if (typeName is PrefixedIdentifier &&
          parent is ConstructorName &&
          argumentList == null) {
        ConstructorName name = parent;
        if (name.name == null) {
          PrefixedIdentifier prefixedIdentifier =
              typeName as PrefixedIdentifier;
          SimpleIdentifier prefix = prefixedIdentifier.prefix;
          element = nameScope.lookup(prefix, definingLibrary);
          if (element is PrefixElement) {
            if (nameScope.shouldIgnoreUndefined(typeName)) {
              node.type = dynamicType;
              return;
            }
            AstNode grandParent = parent.parent;
            if (grandParent is InstanceCreationExpression &&
                grandParent.isConst) {
              // If, if this is a const expression, then generate a
              // CompileTimeErrorCode.CONST_WITH_NON_TYPE error.
              reportErrorForNode(
                  CompileTimeErrorCode.CONST_WITH_NON_TYPE,
                  prefixedIdentifier.identifier,
                  [prefixedIdentifier.identifier.name]);
            } else {
              // Else, if this expression is a new expression, report a
              // NEW_WITH_NON_TYPE warning.
              reportErrorForNode(
                  StaticWarningCode.NEW_WITH_NON_TYPE,
                  prefixedIdentifier.identifier,
                  [prefixedIdentifier.identifier.name]);
            }
            _setElement(prefix, element);
            return;
          } else if (element != null) {
            //
            // Rewrite the constructor name. The parser, when it sees a
            // constructor named "a.b", cannot tell whether "a" is a prefix and
            // "b" is a class name, or whether "a" is a class name and "b" is a
            // constructor name. It arbitrarily chooses the former, but in this
            // case was wrong.
            //
            name.name = prefixedIdentifier.identifier;
            name.period = prefixedIdentifier.period;
            node.name = prefix;
            typeName = prefix;
            rewriteResult = parent;
          }
        }
      }
      if (nameScope.shouldIgnoreUndefined(typeName)) {
        node.type = dynamicType;
        return;
      }
    }
    // check element
    bool elementValid = element is! MultiplyDefinedElement;
    if (elementValid &&
        element != null &&
        element is! ClassElement &&
        _isTypeNameInInstanceCreationExpression(node)) {
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      InstanceCreationExpression creation =
          node.parent.parent as InstanceCreationExpression;
      if (creation.isConst) {
        reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_TYPE,
            typeNameSimple, [typeName]);
        elementValid = false;
      } else {
        reportErrorForNode(
            StaticWarningCode.NEW_WITH_NON_TYPE, typeNameSimple, [typeName]);
        elementValid = false;
      }
    }
    if (elementValid && element == null) {
      // We couldn't resolve the type name.
      elementValid = false;
      // TODO(jwren) Consider moving the check for
      // CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE from the
      // ErrorVerifier, so that we don't have two errors on a built in
      // identifier being used as a class name.
      // See CompileTimeErrorCodeTest.test_builtInIdentifierAsType().
      SimpleIdentifier typeNameSimple = _getTypeSimpleIdentifier(typeName);
      if (_isBuiltInIdentifier(node) && _isTypeAnnotation(node)) {
        reportErrorForNode(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
            typeName, [typeName.name]);
      } else if (typeNameSimple.name == "boolean") {
        reportErrorForNode(
            StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, typeNameSimple, []);
      } else if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME,
            typeName, [typeName.name]);
      } else if (_isRedirectingConstructor(node)) {
        reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, typeName,
            [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else if (typeName is PrefixedIdentifier &&
          node.parent is ConstructorName &&
          argumentList != null) {
        SimpleIdentifier prefix = (typeName as PrefixedIdentifier).prefix;
        SimpleIdentifier identifier =
            (typeName as PrefixedIdentifier).identifier;
        Element prefixElement = nameScope.lookup(prefix, definingLibrary);
        ClassElement classElement;
        ConstructorElement constructorElement;
        if (prefixElement is ClassElement) {
          classElement = prefixElement;
          constructorElement =
              prefixElement.getNamedConstructor(identifier.name);
        }
        if (constructorElement != null) {
          reportErrorForNode(
              StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
              argumentList,
              [prefix.name, identifier.name]);
          prefix.staticElement = prefixElement;
          identifier.staticElement = constructorElement;
          AstNode grandParent = node.parent.parent;
          if (grandParent is InstanceCreationExpressionImpl) {
            var instanceType = classElement.instantiate(
              typeArguments: List.filled(
                classElement.typeParameters.length,
                dynamicType,
              ),
              nullabilitySuffix: _noneOrStarSuffix,
            );
            grandParent.staticElement = constructorElement;
            grandParent.staticType = instanceType;
            //
            // Re-write the AST to reflect the resolution.
            //
            TypeName newTypeName = astFactory.typeName(prefix, null);
            newTypeName.type = instanceType;
            ConstructorName newConstructorName = astFactory.constructorName(
                newTypeName,
                (typeName as PrefixedIdentifier).period,
                identifier);
            newConstructorName.staticElement = constructorElement;
            NodeReplacer.replace(node.parent, newConstructorName);
            grandParent.typeArguments = node.typeArguments;
            // Re-assign local variables that have effectively changed.
            node = newTypeName;
            typeName = prefix;
            element = prefixElement;
            argumentList = null;
            elementValid = true;
            rewriteResult = newConstructorName;
          }
        } else {
          reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_CLASS, typeName, [typeName.name]);
        }
      } else {
        reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CLASS, typeName, [typeName.name]);
      }
    }
    if (!elementValid) {
      if (element is MultiplyDefinedElement) {
        _setElement(typeName, element);
      }
      node.type = dynamicType;
      return;
    }

    if (element is ClassElement) {
      _resolveClassElement(node, typeName, argumentList, element);
      return;
    }

    DartType type;
    if (element == DynamicElementImpl.instance) {
      _setElement(typeName, element);
      type = DynamicTypeImpl.instance;
    } else if (element is NeverElementImpl) {
      _setElement(typeName, element);
      type = element.instantiate(
        nullabilitySuffix: _getNullability(node.question != null),
      );
    } else if (element is FunctionTypeAliasElement) {
      _setElement(typeName, element);
    } else if (element is TypeParameterElement) {
      _setElement(typeName, element);
      type = element.instantiate(
        nullabilitySuffix: _getNullability(node.question != null),
      );
    } else if (element is MultiplyDefinedElement) {
      var elements = (element as MultiplyDefinedElement).conflictingElements;
      element = _getElementWhenMultiplyDefined(elements);
    } else {
      // The name does not represent a type.
      if (_isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName,
            [typeName.name]);
      } else if (_isTypeNameInAsExpression(node)) {
        reportErrorForNode(
            StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (_isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, typeName,
            [typeName.name]);
      } else if (_isRedirectingConstructor(node)) {
        reportErrorForNode(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, typeName,
            [typeName.name]);
      } else if (_isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
            typeName, [typeName.name]);
      } else {
        AstNode parent = typeName.parent;
        while (parent is TypeName) {
          parent = parent.parent;
        }
        if (parent is ExtendsClause ||
            parent is ImplementsClause ||
            parent is WithClause ||
            parent is ClassTypeAlias) {
          // Ignored. The error will be reported elsewhere.
        } else if (element is LocalVariableElement ||
            (element is FunctionElement &&
                element.enclosingElement is ExecutableElement)) {
          errorListener.onError(DiagnosticFactory()
              .referencedBeforeDeclaration(source, typeName, element: element));
        } else {
          reportErrorForNode(
              StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
      node.type = dynamicType;
      return;
    }
    if (argumentList != null) {
      var parameters = const <TypeParameterElement>[];
      if (element is ClassElement) {
        parameters = element.typeParameters;
      } else if (element is FunctionTypeAliasElement) {
        parameters = element.typeParameters;
      }

      NodeList<TypeAnnotation> arguments = argumentList.arguments;
      int argumentCount = arguments.length;
      int parameterCount = parameters.length;
      List<DartType> typeArguments = List<DartType>(parameterCount);
      if (argumentCount == parameterCount) {
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = _getType(arguments[i]);
        }
      } else {
        reportErrorForNode(_getInvalidTypeParametersErrorCode(node), node,
            [typeName.name, parameterCount, argumentCount]);
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = dynamicType;
        }
      }
      if (element is GenericTypeAliasElementImpl) {
        type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _getNullability(node.question != null),
        );
        type ??= dynamicType;
      } else {
        type = typeSystem.instantiateType(type, typeArguments);
        type = (type as TypeImpl).withNullability(
          _getNullability(node.question != null),
        );
      }
    } else {
      if (element is GenericTypeAliasElementImpl) {
        var typeArguments = typeSystem.instantiateTypeFormalsToBounds(
          element.typeParameters,
        );
        type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _getNullability(node.question != null),
        );
        type ??= dynamicType;
      } else {
        type = typeSystem.instantiateToBounds(type);
      }
    }

    node.type = type;
  }

  /// Given the multiple elements to which a single name could potentially be
  /// resolved, return the single [ClassElement] that should be used, or `null`
  /// if there is no clear choice.
  ///
  /// @param elements the elements to which a single name could potentially be
  ///        resolved
  /// @return the single interface type that should be used for the type name
  ClassElement _getElementWhenMultiplyDefined(List<Element> elements) {
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      Element element = elements[i];
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
  }

  DartType _getInferredMixinType(
      ClassElement classElement, ClassElement mixinElement) {
    for (var candidateMixin in classElement.mixins) {
      if (candidateMixin.element == mixinElement) return candidateMixin;
    }
    return null; // Not found
  }

  /// The number of type arguments in the given [typeName] does not match the
  /// number of parameters in the corresponding class element. Return the error
  /// code that should be used to report this error.
  ErrorCode _getInvalidTypeParametersErrorCode(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      parent = parent.parent;
      if (parent is InstanceCreationExpression) {
        if (parent.isConst) {
          return CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS;
        } else {
          return StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS;
        }
      }
    }
    return StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;
  }

  NullabilitySuffix _getNullability(bool hasQuestion) {
    NullabilitySuffix nullability;
    if (isNonNullableByDefault) {
      if (hasQuestion) {
        nullability = NullabilitySuffix.question;
      } else {
        nullability = NullabilitySuffix.none;
      }
    } else {
      nullability = NullabilitySuffix.star;
    }
    return nullability;
  }

  /// Return the type represented by the given type [annotation].
  DartType _getType(TypeAnnotation annotation) {
    DartType type = annotation.type;
    if (type == null) {
      return dynamicType;
    }
    return type;
  }

  /// Returns the simple identifier of the given (may be qualified) type name.
  ///
  /// @param typeName the (may be qualified) qualified type name
  /// @return the simple identifier of the given (may be qualified) type name.
  SimpleIdentifier _getTypeSimpleIdentifier(Identifier typeName) {
    if (typeName is SimpleIdentifier) {
      return typeName;
    } else {
      PrefixedIdentifier prefixed = typeName;
      SimpleIdentifier prefix = prefixed.prefix;
      // The prefixed identifier can be:
      // 1. new importPrefix.TypeName()
      // 2. new TypeName.constructorName()
      // 3. new unresolved.Unresolved()
      if (prefix.staticElement is PrefixElement) {
        return prefixed.identifier;
      } else {
        return prefix;
      }
    }
  }

  /// If the [node] is the type name in a redirected factory constructor,
  /// infer type arguments using the enclosing class declaration. Return `null`
  /// otherwise.
  List<DartType> _inferTypeArgumentsForRedirectedConstructor(
      TypeName node, ClassElement typeElement) {
    AstNode constructorName = node.parent;
    AstNode enclosingConstructor = constructorName?.parent;
    if (constructorName is ConstructorName &&
        enclosingConstructor is ConstructorDeclaration &&
        enclosingConstructor.redirectedConstructor == constructorName) {
      ClassOrMixinDeclaration enclosingClassNode = enclosingConstructor.parent;
      var enclosingClassElement = enclosingClassNode.declaredElement;
      if (enclosingClassElement == typeElement) {
        return typeElement.thisType.typeArguments;
      } else {
        return typeSystem.inferGenericFunctionOrType(
          typeParameters: typeElement.typeParameters,
          parameters: const [],
          declaredReturnType: typeElement.thisType,
          argumentTypes: const [],
          contextReturnType: enclosingClassElement.thisType,
          isNonNullableByDefault: isNonNullableByDefault,
        );
      }
    }
    return null;
  }

  /// Return `true` if the given [typeName] is the target in a redirected
  /// constructor.
  bool _isRedirectingConstructor(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      AstNode grandParent = parent.parent;
      if (grandParent is ConstructorDeclaration) {
        if (identical(grandParent.redirectedConstructor, parent)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an as expression.
  bool _isTypeNameInAsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is AsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the exception type in a catch
  /// clause.
  bool _isTypeNameInCatchClause(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an instance creation
  /// expression.
  bool _isTypeNameInInstanceCreationExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName &&
        parent.parent is InstanceCreationExpression) {
      return parent != null && identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] is used as the type in an is expression.
  bool _isTypeNameInIsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is IsExpression) {
      return identical(parent.type, typeName);
    }
    return false;
  }

  /// Checks if the given [typeName] used in a type argument list.
  bool _isTypeNameInTypeArgumentList(TypeName typeName) =>
      typeName.parent is TypeArgumentList;

  /// Given a [typeName] that has a question mark, report an error and return
  /// `true` if it appears in a location where a nullable type is not allowed.
  void _reportInvalidNullableType(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ExtendsClause || parent is ClassTypeAlias) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE, typeName);
    } else if (parent is ImplementsClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE, typeName);
    } else if (parent is OnClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, typeName);
    } else if (parent is WithClause) {
      reportErrorForNode(
          CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE, typeName);
    }
  }

  void _resolveClassElement(TypeName node, Identifier typeName,
      TypeArgumentList argumentList, ClassElement element) {
    _setElement(typeName, element);

    var typeParameters = element.typeParameters;
    var parameterCount = typeParameters.length;

    List<DartType> typeArguments;
    if (argumentList != null) {
      var argumentNodes = argumentList.arguments;
      var argumentCount = argumentNodes.length;

      typeArguments = List<DartType>(parameterCount);
      if (argumentCount == parameterCount) {
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = _getType(argumentNodes[i]);
        }
      } else {
        reportErrorForNode(_getInvalidTypeParametersErrorCode(node), node,
            [typeName.name, parameterCount, argumentCount]);
        for (int i = 0; i < parameterCount; i++) {
          typeArguments[i] = dynamicType;
        }
      }
    } else if (parameterCount == 0) {
      typeArguments = const <DartType>[];
    } else {
      typeArguments =
          _inferTypeArgumentsForRedirectedConstructor(node, element);
      if (typeArguments == null) {
        typeArguments = typeSystem.instantiateTypeFormalsToBounds2(element);
      }
    }

    var parent = node.parent;

    NullabilitySuffix nullabilitySuffix;
    if (parent is ClassTypeAlias ||
        parent is ExtendsClause ||
        parent is ImplementsClause ||
        parent is OnClause ||
        parent is WithClause) {
      if (node.question != null) {
        _reportInvalidNullableType(node);
      }
      if (isNonNullableByDefault) {
        nullabilitySuffix = NullabilitySuffix.none;
      } else {
        nullabilitySuffix = NullabilitySuffix.star;
      }
    } else {
      nullabilitySuffix = _getNullability(node.question != null);
    }

    var type = InterfaceTypeImpl.explicit(element, typeArguments,
        nullabilitySuffix: nullabilitySuffix);

    if (shouldUseWithClauseInferredTypes) {
      if (parent is WithClause && parameterCount != 0) {
        // Get the (possibly inferred) mixin type from the element model.
        var grandParent = parent.parent;
        if (grandParent is ClassDeclaration) {
          type = _getInferredMixinType(grandParent.declaredElement, element);
        } else if (grandParent is ClassTypeAlias) {
          type = _getInferredMixinType(grandParent.declaredElement, element);
        } else {
          assert(false, 'Unexpected context for "with" clause');
        }
      }
    }

    node.type = type;
  }

  /// Records the new Element for a TypeName's Identifier.
  ///
  /// A null may be passed in to indicate that the element can't be resolved.
  /// (During a re-run of a task, it's important to clear any previous value
  /// of the element.)
  void _setElement(Identifier typeName, Element element) {
    if (typeName is SimpleIdentifier) {
      typeName.staticElement = element;
    } else if (typeName is PrefixedIdentifier) {
      typeName.identifier.staticElement = element;
      SimpleIdentifier prefix = typeName.prefix;
      prefix.staticElement = nameScope.lookup(prefix, definingLibrary);
    }
  }

  /// Return `true` if the name of the given [typeName] is an built-in
  /// identifier.
  static bool _isBuiltInIdentifier(TypeName typeName) {
    Token token = typeName.name.beginToken;
    return token.type.isKeyword;
  }

  /// @return `true` if given [typeName] is used as a type annotation.
  static bool _isTypeAnnotation(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is VariableDeclarationList) {
      return identical(parent.type, typeName);
    } else if (parent is FieldFormalParameter) {
      return identical(parent.type, typeName);
    } else if (parent is SimpleFormalParameter) {
      return identical(parent.type, typeName);
    }
    return false;
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
      : super(definingLibrary, source, typeProvider, errorListener,
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
    Element element = nameScope.lookup(node, definingLibrary);
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

/// A set of counts of the kinds of leaf elements in a collection, used to help
/// disambiguate map and set literals.
class _LeafElements {
  /// The number of expressions found in the collection.
  int expressionCount = 0;

  /// The number of map entries found in the collection.
  int mapEntryCount = 0;

  /// Initialize a newly created set of counts based on the given collection
  /// [elements].
  _LeafElements(List<CollectionElement> elements) {
    for (CollectionElement element in elements) {
      _count(element);
    }
  }

  /// Return the resolution suggested by the set elements.
  _LiteralResolution get resolution {
    if (expressionCount > 0 && mapEntryCount == 0) {
      return _LiteralResolution(_LiteralResolutionKind.set, null);
    } else if (mapEntryCount > 0 && expressionCount == 0) {
      return _LiteralResolution(_LiteralResolutionKind.map, null);
    }
    return _LiteralResolution(_LiteralResolutionKind.ambiguous, null);
  }

  /// Recursively add the given collection [element] to the counts.
  void _count(CollectionElement element) {
    if (element is ForElement) {
      _count(element.body);
    } else if (element is IfElement) {
      _count(element.thenElement);
      _count(element.elseElement);
    } else if (element is Expression) {
      if (_isComplete(element)) {
        expressionCount++;
      }
    } else if (element is MapLiteralEntry) {
      if (_isComplete(element)) {
        mapEntryCount++;
      }
    }
  }

  /// Return `true` if the given collection [element] does not contain any
  /// synthetic tokens.
  bool _isComplete(CollectionElement element) {
    // TODO(paulberry,brianwilkerson): the code below doesn't work because it
    // assumes access to token offsets, which aren't available when working with
    // expressions resynthesized from summaries.  For now we just assume the
    // collection element is complete.
    return true;
//    Token token = element.beginToken;
//    int endOffset = element.endToken.offset;
//    while (token != null && token.offset <= endOffset) {
//      if (token.isSynthetic) {
//        return false;
//      }
//      token = token.next;
//    }
//    return true;
  }
}

/// An indication of the way in which a set or map literal should be resolved to
/// be either a set literal or a map literal.
class _LiteralResolution {
  /// The kind of collection that the literal should be.
  final _LiteralResolutionKind kind;

  /// The type that should be used as the inference context when performing type
  /// inference for the literal.
  DartType contextType;

  /// Initialize a newly created resolution.
  _LiteralResolution(this.kind, this.contextType);

  @override
  String toString() {
    return '$kind ($contextType)';
  }
}

/// The kind of literal to which an unknown literal should be resolved.
enum _LiteralResolutionKind { ambiguous, map, set }
