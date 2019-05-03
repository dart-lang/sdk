// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show ConstructorMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/strong/checker.dart'
    show getExpressionType, getReadType;

/**
 * Instances of the class `StaticTypeAnalyzer` perform two type-related tasks. First, they
 * compute the static type of every expression. Second, they look for any static type errors or
 * warnings that might need to be generated. The requirements for the type analyzer are:
 * <ol>
 * * Every element that refers to types should be fully populated.
 * * Every node representing an expression should be resolved to the Type of the expression.
 * </ol>
 */
class StaticTypeAnalyzer extends SimpleAstVisitor<void> {
  /**
   * The resolver driving the resolution and type analysis.
   */
  final ResolverVisitor _resolver;

  /**
   * The object providing access to the types defined by the language.
   */
  TypeProvider _typeProvider;

  /**
   * The type system in use for static type analysis.
   */
  TypeSystem _typeSystem;

  /**
   * The type representing the type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * True if inference failures should be reported, otherwise false.
   */
  bool _strictInference;

  /**
   * The type representing the class containing the nodes being analyzed,
   * or `null` if the nodes are not within a class.
   */
  InterfaceType thisType;

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager;

  /**
   * Initialize a newly created type analyzer.
   *
   * @param resolver the resolver driving this participant
   */
  StaticTypeAnalyzer(this._resolver) {
    _typeProvider = _resolver.typeProvider;
    _typeSystem = _resolver.typeSystem;
    _dynamicType = _typeProvider.dynamicType;
    _promoteManager = _resolver.promoteManager;
    AnalysisOptionsImpl analysisOptions =
        _resolver.definingLibrary.context.analysisOptions;
    _strictInference = analysisOptions.strictInference;
  }

  /**
   * Given a constructor name [node] and a type [type], record an inferred type
   * for the constructor if in strong mode. This is used to fill in any
   * inferred type parameters found by the resolver.
   */
  void inferConstructorName(ConstructorName node, InterfaceType type) {
    node.type.type = type;
    if (type != _typeSystem.instantiateToBounds(type.element.type)) {
      _resolver.inferenceContext.recordInference(node.parent, type);
    }
  }

  /**
   * Given a formal parameter list and a function type use the function type
   * to infer types for any of the parameters which have implicit (missing)
   * types.  Only infers types in strong mode.  Returns true if inference
   * has occurred.
   */
  bool inferFormalParameterList(
      FormalParameterList node, DartType functionType) {
    bool inferred = false;
    if (node != null && functionType is FunctionType) {
      var ts = _typeSystem as Dart2TypeSystem;
      void inferType(ParameterElementImpl p, DartType inferredType) {
        // Check that there is no declared type, and that we have not already
        // inferred a type in some fashion.
        if (p.hasImplicitType && (p.type == null || p.type.isDynamic)) {
          inferredType = ts.upperBoundForType(inferredType);
          if (inferredType.isDartCoreNull) {
            inferredType = _typeProvider.objectType;
          }
          if (!inferredType.isDynamic) {
            p.type = inferredType;
            inferred = true;
          }
        }
      }

      List<ParameterElement> parameters = node.parameterElements;
      {
        Iterator<ParameterElement> positional =
            parameters.where((p) => p.isPositional).iterator;
        Iterator<ParameterElement> fnPositional =
            functionType.parameters.where((p) => p.isPositional).iterator;
        while (positional.moveNext() && fnPositional.moveNext()) {
          inferType(positional.current, fnPositional.current.type);
        }
      }

      {
        Map<String, DartType> namedParameterTypes =
            functionType.namedParameterTypes;
        Iterable<ParameterElement> named = parameters.where((p) => p.isNamed);
        for (ParameterElementImpl p in named) {
          if (!namedParameterTypes.containsKey(p.name)) {
            continue;
          }
          inferType(p, namedParameterTypes[p.name]);
        }
      }
    }
    return inferred;
  }

  DartType inferListType(ListLiteral node, {bool downwards: false}) {
    DartType contextType = InferenceContext.getContext(node);

    var ts = _typeSystem as Dart2TypeSystem;
    List<DartType> elementTypes;
    List<ParameterElement> parameters;

    if (downwards) {
      if (contextType == null) {
        return null;
      }
      elementTypes = [];
      parameters = [];
    } else {
      // Also use upwards information to infer the type.
      elementTypes = node.elements
          .map((element) => _computeElementType(element))
          .where((t) => t != null)
          .toList();
      TypeParameterType listTypeParam =
          _typeProvider.listType.typeParameters[0].type;
      ParameterElementImpl syntheticParamElement =
          new ParameterElementImpl.synthetic(
              'element', listTypeParam, ParameterKind.POSITIONAL);
      parameters = new List.filled(elementTypes.length, syntheticParamElement);
    }
    InterfaceType inferred = ts.inferGenericFunctionOrType<InterfaceType>(
        _typeProvider.listType, parameters, elementTypes, contextType,
        downwards: downwards,
        isConst: node.isConst,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
    return inferred;
  }

  ParameterizedType inferMapTypeDownwards(
      SetOrMapLiteral node, DartType contextType) {
    if (contextType == null) {
      return null;
    }

    var ts = _typeSystem as Dart2TypeSystem;
    ParameterizedType inferred = ts.inferGenericFunctionOrType(
        _typeProvider.mapType, [], [], contextType,
        downwards: true,
        isConst: node.isConst,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
    return inferred;
  }

  DartType inferSetTypeDownwards(SetOrMapLiteral node, DartType contextType) {
    if (contextType == null) {
      return null;
    }

    var ts = _typeSystem as Dart2TypeSystem;
    DartType inferred = ts.inferGenericFunctionOrType<InterfaceType>(
        _typeProvider.setType, [], [], contextType,
        downwards: true,
        isConst: node.isConst,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
    return inferred;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _recordStaticType(node, _typeProvider.stringType);
  }

  /**
   * The Dart Language Specification, 12.32: <blockquote>... the cast expression <i>e as T</i> ...
   *
   * It is a static warning if <i>T</i> does not denote a type available in the current lexical
   * scope.
   *
   * The static type of a cast expression <i>e as T</i> is <i>T</i>.</blockquote>
   */
  @override
  void visitAsExpression(AsExpression node) {
    _recordStaticType(node, _getType(node.type));
  }

  /**
   * The Dart Language Specification, 12.18: <blockquote>... an assignment <i>a</i> of the form <i>v
   * = e</i> ...
   *
   * It is a static type warning if the static type of <i>e</i> may not be assigned to the static
   * type of <i>v</i>.
   *
   * The static type of the expression <i>v = e</i> is the static type of <i>e</i>.
   *
   * ... an assignment of the form <i>C.v = e</i> ...
   *
   * It is a static type warning if the static type of <i>e</i> may not be assigned to the static
   * type of <i>C.v</i>.
   *
   * The static type of the expression <i>C.v = e</i> is the static type of <i>e</i>.
   *
   * ... an assignment of the form <i>e<sub>1</sub>.v = e<sub>2</sub></i> ...
   *
   * Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type warning if
   * <i>T</i> does not have an accessible instance setter named <i>v=</i>. It is a static type
   * warning if the static type of <i>e<sub>2</sub></i> may not be assigned to <i>T</i>.
   *
   * The static type of the expression <i>e<sub>1</sub>.v = e<sub>2</sub></i> is the static type of
   * <i>e<sub>2</sub></i>.
   *
   * ... an assignment of the form <i>e<sub>1</sub>[e<sub>2</sub>] = e<sub>3</sub></i> ...
   *
   * The static type of the expression <i>e<sub>1</sub>[e<sub>2</sub>] = e<sub>3</sub></i> is the
   * static type of <i>e<sub>3</sub></i>.
   *
   * A compound assignment of the form <i>v op= e</i> is equivalent to <i>v = v op e</i>. A compound
   * assignment of the form <i>C.v op= e</i> is equivalent to <i>C.v = C.v op e</i>. A compound
   * assignment of the form <i>e<sub>1</sub>.v op= e<sub>2</sub></i> is equivalent to <i>((x) => x.v
   * = x.v op e<sub>2</sub>)(e<sub>1</sub>)</i> where <i>x</i> is a variable that is not used in
   * <i>e<sub>2</sub></i>. A compound assignment of the form <i>e<sub>1</sub>[e<sub>2</sub>] op=
   * e<sub>3</sub></i> is equivalent to <i>((a, i) => a[i] = a[i] op e<sub>3</sub>)(e<sub>1</sub>,
   * e<sub>2</sub>)</i> where <i>a</i> and <i>i</i> are a variables that are not used in
   * <i>e<sub>3</sub></i>.</blockquote>
   */
  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operator = node.operator.type;
    if (operator == TokenType.EQ) {
      Expression rightHandSide = node.rightHandSide;
      DartType staticType = _getStaticType(rightHandSide);
      _recordStaticType(node, staticType);
    } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
      // The static type of a compound assignment using ??= is the least upper
      // bound of the static types of the LHS and RHS.
      _analyzeLeastUpperBound(node, node.leftHandSide, node.rightHandSide,
          read: true);
      return;
    } else if (operator == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operator == TokenType.BAR_BAR_EQ) {
      _recordStaticType(node, _typeProvider.boolType);
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      staticType = _typeSystem.refineBinaryExpressionType(
          _getStaticType(node.leftHandSide, read: true),
          operator,
          node.rightHandSide.staticType,
          staticType);
      _recordStaticType(node, staticType);
    }
  }

  /**
   * The Dart Language Specification, 16.29 (Await Expressions):
   *
   *   The static type of [the expression "await e"] is flatten(T) where T is
   *   the static type of e.
   */
  @override
  void visitAwaitExpression(AwaitExpression node) {
    // Await the Future. This results in whatever type is (ultimately) returned.
    DartType awaitType(DartType awaitedType) {
      if (awaitedType == null) {
        return null;
      }
      if (awaitedType.isDartAsyncFutureOr) {
        return awaitType((awaitedType as InterfaceType).typeArguments[0]);
      }
      return _typeSystem.flatten(awaitedType);
    }

    _recordStaticType(node, awaitType(_getStaticType(node.expression)));
  }

  /**
   * The Dart Language Specification, 12.20: <blockquote>The static type of a logical boolean
   * expression is `bool`.</blockquote>
   *
   * The Dart Language Specification, 12.21:<blockquote>A bitwise expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A bitwise expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.22: <blockquote>The static type of an equality expression
   * is `bool`.</blockquote>
   *
   * The Dart Language Specification, 12.23: <blockquote>A relational expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A relational expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.24: <blockquote>A shift expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A shift expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.25: <blockquote>An additive expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. An additive expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.26: <blockquote>A multiplicative expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A multiplicative expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   */
  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION) {
      // Evaluation of an if-null expression e of the form e1 ?? e2 is
      // equivalent to the evaluation of the expression
      // ((x) => x == null ? e2 : x)(e1).  The static type of e is the least
      // upper bound of the static type of e1 and the static type of e2.
      _analyzeLeastUpperBound(node, node.leftOperand, node.rightOperand);
      return;
    }
    DartType staticType = node.staticInvokeType?.returnType ?? _dynamicType;
    staticType = _typeSystem.refineBinaryExpressionType(
        node.leftOperand.staticType,
        node.operator.type,
        node.rightOperand.staticType,
        staticType);
    _recordStaticType(node, staticType);
  }

  /**
   * The Dart Language Specification, 12.4: <blockquote>The static type of a boolean literal is
   * bool.</blockquote>
   */
  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _recordStaticType(node, _typeProvider.boolType);
  }

  /**
   * The Dart Language Specification, 12.15.2: <blockquote>A cascaded method invocation expression
   * of the form <i>e..suffix</i> is equivalent to the expression <i>(t) {t.suffix; return
   * t;}(e)</i>.</blockquote>
   */
  @override
  void visitCascadeExpression(CascadeExpression node) {
    _recordStaticType(node, _getStaticType(node.target));
  }

  /**
   * The Dart Language Specification, 12.19: <blockquote> ... a conditional expression <i>c</i> of
   * the form <i>e<sub>1</sub> ? e<sub>2</sub> : e<sub>3</sub></i> ...
   *
   * It is a static type warning if the type of e<sub>1</sub> may not be assigned to `bool`.
   *
   * The static type of <i>c</i> is the least upper bound of the static type of <i>e<sub>2</sub></i>
   * and the static type of <i>e<sub>3</sub></i>.</blockquote>
   */
  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _analyzeLeastUpperBound(node, node.thenExpression, node.elseExpression);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    _inferForEachLoopVariableType(node);
  }

  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of a literal double is
   * double.</blockquote>
   */
  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _recordStaticType(node, _typeProvider.doubleType);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression function = node.functionExpression;
    ExecutableElementImpl functionElement =
        node.declaredElement as ExecutableElementImpl;
    if (node.parent is FunctionDeclarationStatement) {
      // TypeResolverVisitor sets the return type for top-level functions, so
      // we only need to handle local functions.
      if (node.returnType == null) {
        _inferLocalFunctionReturnType(node.functionExpression);
        return;
      }
      functionElement.returnType =
          _computeStaticReturnTypeOfFunctionDeclaration(node);
    }
    _recordStaticType(function, functionElement.type);
  }

  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a function literal of the
   * form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;, T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub>
   * x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub> = dk]) => e</i> is
   * <i>(T<sub>1</sub>, &hellip;, Tn, [T<sub>n+1</sub> x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub>]) &rarr; T<sub>0</sub></i>, where <i>T<sub>0</sub></i> is the static type of
   * <i>e</i>. In any case where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is
   * considered to have been specified as dynamic.
   *
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> : dk}) => e</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; T<sub>0</sub></i>, where
   * <i>T<sub>0</sub></i> is the static type of <i>e</i>. In any case where <i>T<sub>i</sub>, 1
   * &lt;= i &lt;= n</i>, is not specified, it is considered to have been specified as dynamic.
   *
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub> x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> = dk]) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>]) &rarr; dynamic</i>. In any case
   * where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
   * specified as dynamic.
   *
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> : dk}) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; dynamic</i>. In any case
   * where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
   * specified as dynamic.</blockquote>
   */
  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // The function type will be resolved and set when we visit the parent
      // node.
      return;
    }
    _inferLocalFunctionReturnType(node);
  }

  /**
   * The Dart Language Specification, 12.14.4: <blockquote>A function expression invocation <i>i</i>
   * has the form <i>e<sub>f</sub>(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is
   * an expression.
   *
   * It is a static type warning if the static type <i>F</i> of <i>e<sub>f</sub></i> may not be
   * assigned to a function type.
   *
   * If <i>F</i> is not a function type, the static type of <i>i</i> is dynamic. Otherwise the
   * static type of <i>i</i> is the declared return type of <i>F</i>.</blockquote>
   */
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _inferGenericInvocationExpression(node);
    DartType staticType = _computeInvokeReturnType(node.staticInvokeType);
    _recordStaticType(node, staticType);
  }

  /**
   * The Dart Language Specification, 12.29: <blockquote>An assignable expression of the form
   * <i>e<sub>1</sub>[e<sub>2</sub>]</i> is evaluated as a method invocation of the operator method
   * <i>[]</i> on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.</blockquote>
   */
  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.inSetterContext()) {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeArgumentType(staticMethodElement);
      _recordStaticType(node, staticType);
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      _recordStaticType(node, staticType);
    }
  }

  /**
   * The Dart Language Specification, 12.11.1: <blockquote>The static type of a new expression of
   * either the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the form <i>new
   * T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>.</blockquote>
   *
   * The Dart Language Specification, 12.11.2: <blockquote>The static type of a constant object
   * expression of either the form <i>const T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the
   * form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>. </blockquote>
   */
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _inferInstanceCreationExpression(node);
    _recordStaticType(node, node.constructorName.type.type);
  }

  /**
   * <blockquote>
   * An integer literal has static type \code{int}, unless the surrounding
   * static context type is a type which \code{int} is not assignable to, and
   * \code{double} is. In that case the static type of the integer literal is
   * \code{double}.
   * <blockquote>
   *
   * and
   *
   * <blockquote>
   * If $e$ is an expression of the form \code{-$l$} where $l$ is an integer
   * literal (\ref{numbers}) with numeric integer value $i$, then the static
   * type of $e$ is the same as the static type of an integer literal with the
   * same contexttype
   * </blockquote>
   */
  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // Check the parent context for negated integer literals.
    var context = InferenceContext.getContext(
        (node as IntegerLiteralImpl).immediatelyNegated ? node.parent : node);
    if (context == null ||
        _typeSystem.isAssignableTo(_typeProvider.intType, context) ||
        !_typeSystem.isAssignableTo(_typeProvider.doubleType, context)) {
      _recordStaticType(node, _typeProvider.intType);
    } else {
      _recordStaticType(node, _typeProvider.doubleType);
    }
  }

  /**
   * The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
   * denote a type available in the current lexical scope.
   *
   * The static type of an is-expression is `bool`.</blockquote>
   */
  @override
  void visitIsExpression(IsExpression node) {
    _recordStaticType(node, _typeProvider.boolType);
  }

  /**
   * The Dart Language Specification, 12.6: <blockquote>The static type of a list literal of the
   * form <i><b>const</b> &lt;E&gt;[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> or the form
   * <i>&lt;E&gt;[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> is `List&lt;E&gt;`. The static
   * type a list literal of the form <i><b>const</b> [e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> or
   * the form <i>[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> is `List&lt;dynamic&gt;`
   * .</blockquote>
   */
  @override
  void visitListLiteral(ListLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;

    // If we have explicit arguments, use them
    if (typeArguments != null) {
      DartType staticType = _dynamicType;
      NodeList<TypeAnnotation> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 1) {
        DartType argumentType = _getType(arguments[0]);
        if (argumentType != null) {
          staticType = argumentType;
        }
      }
      _recordStaticType(
          node, _typeProvider.listType.instantiate(<DartType>[staticType]));
      return;
    }

    DartType listDynamicType =
        _typeProvider.listType.instantiate(<DartType>[_dynamicType]);

    // If there are no type arguments, try to infer some arguments.
    DartType inferred = inferListType(node);

    if (inferred != listDynamicType) {
      // TODO(jmesserly): this results in an "inferred" message even when we
      // in fact had an error above, because it will still attempt to return
      // a type. Perhaps we should record inference from TypeSystem if
      // everything was successful?
      _resolver.inferenceContext.recordInference(node, inferred);
      _recordStaticType(node, inferred);
      return;
    }

    // If we have no type arguments and couldn't infer any, use dynamic.
    _recordStaticType(node, listDynamicType);
  }

  /**
   * The Dart Language Specification, 12.15.1: <blockquote>An ordinary method invocation <i>i</i>
   * has the form <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if <i>T</i> does not
   * have an accessible instance member named <i>m</i>. If <i>T.m</i> exists, it is a static warning
   * if the type <i>F</i> of <i>T.m</i> may not be assigned to a function type.
   *
   * If <i>T.m</i> does not exist, or if <i>F</i> is not a function type, the static type of
   * <i>i</i> is dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   *
   * The Dart Language Specification, 11.15.3: <blockquote>A static method invocation <i>i</i> has
   * the form <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * It is a static type warning if the type <i>F</i> of <i>C.m</i> may not be assigned to a
   * function type.
   *
   * If <i>F</i> is not a function type, or if <i>C.m</i> does not exist, the static type of i is
   * dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   *
   * The Dart Language Specification, 11.15.4: <blockquote>A super method invocation <i>i</i> has
   * the form <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * It is a static type warning if <i>S</i> does not have an accessible instance member named m. If
   * <i>S.m</i> exists, it is a static warning if the type <i>F</i> of <i>S.m</i> may not be
   * assigned to a function type.
   *
   * If <i>S.m</i> does not exist, or if <i>F</i> is not a function type, the static type of
   * <i>i</i> is dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   */
  @override
  void visitMethodInvocation(MethodInvocation node) {
    _inferGenericInvocationExpression(node);
    // Record static return type of the static element.
    bool inferredStaticType = _inferMethodInvocationObject(node) ||
        _inferMethodInvocationInlineJS(node);

    if (!inferredStaticType) {
      DartType staticStaticType =
          _computeInvokeReturnType(node.staticInvokeType);
      _recordStaticType(node, staticStaticType);
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, _getStaticType(expression));
  }

  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of `null` is bottom.
   * </blockquote>
   */
  @override
  void visitNullLiteral(NullLiteral node) {
    _recordStaticType(node, _typeProvider.nullType);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, _getStaticType(expression));
  }

  /**
   * The Dart Language Specification, 12.28: <blockquote>A postfix expression of the form
   * <i>v++</i>, where <i>v</i> is an identifier, is equivalent to <i>(){var r = v; v = r + 1;
   * return r}()</i>.
   *
   * A postfix expression of the form <i>C.v++</i> is equivalent to <i>(){var r = C.v; C.v = r + 1;
   * return r}()</i>.
   *
   * A postfix expression of the form <i>e1.v++</i> is equivalent to <i>(x){var r = x.v; x.v = r +
   * 1; return r}(e1)</i>.
   *
   * A postfix expression of the form <i>e1[e2]++</i> is equivalent to <i>(a, i){var r = a[i]; a[i]
   * = r + 1; return r}(e1, e2)</i>
   *
   * A postfix expression of the form <i>v--</i>, where <i>v</i> is an identifier, is equivalent to
   * <i>(){var r = v; v = r - 1; return r}()</i>.
   *
   * A postfix expression of the form <i>C.v--</i> is equivalent to <i>(){var r = C.v; C.v = r - 1;
   * return r}()</i>.
   *
   * A postfix expression of the form <i>e1.v--</i> is equivalent to <i>(x){var r = x.v; x.v = r -
   * 1; return r}(e1)</i>.
   *
   * A postfix expression of the form <i>e1[e2]--</i> is equivalent to <i>(a, i){var r = a[i]; a[i]
   * = r - 1; return r}(e1, e2)</i></blockquote>
   */
  @override
  void visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    TypeImpl staticType = _getStaticType(operand, read: true);

    if (node.operator.type == TokenType.BANG) {
      // TODO(paulberry): This does the wrong thing if staticType is a type
      // parameter type.
      staticType = staticType.withNullability(NullabilitySuffix.none);
    } else {
      // No need to check for `intVar++`, the result is `int`.
      if (!staticType.isDartCoreInt) {
        var operatorElement = node.staticElement;
        var operatorReturnType = _computeStaticReturnType(operatorElement);
        _checkForInvalidAssignmentIncDec(node, operand, operatorReturnType);
      }
    }

    _recordStaticType(node, staticType);
  }

  /**
   * See [visitSimpleIdentifier].
   */
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element staticElement = prefixedIdentifier.staticElement;
    DartType staticType = _dynamicType;
    if (staticElement is ClassElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = staticElement.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (staticElement is FunctionTypeAliasElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = staticElement.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(staticElement);
    } else if (staticElement is ExecutableElement) {
      staticType = staticElement.type;
    } else if (staticElement is TypeParameterElement) {
      staticType = staticElement.type;
    } else if (staticElement is VariableElement) {
      staticType = staticElement.type;
    }
    staticType = _inferGenericInstantiationFromContext(node, staticType);
    if (!_inferObjectAccess(node, staticType, prefixedIdentifier)) {
      _recordStaticType(prefixedIdentifier, staticType);
      _recordStaticType(node, staticType);
    }
  }

  /**
   * The Dart Language Specification, 12.27: <blockquote>A unary expression <i>u</i> of the form
   * <i>op e</i> is equivalent to a method invocation <i>expression e.op()</i>. An expression of the
   * form <i>op super</i> is equivalent to the method invocation <i>super.op()<i>.</blockquote>
   */
  @override
  void visitPrefixExpression(PrefixExpression node) {
    TokenType operator = node.operator.type;
    if (operator == TokenType.BANG) {
      _recordStaticType(node, _typeProvider.boolType);
    } else {
      // The other cases are equivalent to invoking a method.
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      if (operator == TokenType.MINUS_MINUS ||
          operator == TokenType.PLUS_PLUS) {
        Expression operand = node.operand;
        var operandReadType = _getStaticType(operand, read: true);
        if (operandReadType.isDartCoreInt) {
          staticType = _typeProvider.intType;
        } else {
          _checkForInvalidAssignmentIncDec(node, operand, staticType);
        }
      }
      _recordStaticType(node, staticType);
    }
  }

  /**
   * The Dart Language Specification, 12.13: <blockquote> Property extraction allows for a member of
   * an object to be concisely extracted from the object. If <i>o</i> is an object, and if <i>m</i>
   * is the name of a method member of <i>o</i>, then
   * * <i>o.m</i> is defined to be equivalent to: <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
   * {p<sub>1</sub> : d<sub>1</sub>, &hellip;, p<sub>k</sub> : d<sub>k</sub>}){return
   * o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>, p<sub>1</sub>: p<sub>1</sub>, &hellip;,
   * p<sub>k</sub>: p<sub>k</sub>);}</i> if <i>m</i> has required parameters <i>r<sub>1</sub>,
   * &hellip;, r<sub>n</sub></i>, and named parameters <i>p<sub>1</sub> &hellip; p<sub>k</sub></i>
   * with defaults <i>d<sub>1</sub>, &hellip;, d<sub>k</sub></i>.
   * * <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>, [p<sub>1</sub> = d<sub>1</sub>, &hellip;,
   * p<sub>k</sub> = d<sub>k</sub>]){return o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
   * p<sub>1</sub>, &hellip;, p<sub>k</sub>);}</i> if <i>m</i> has required parameters
   * <i>r<sub>1</sub>, &hellip;, r<sub>n</sub></i>, and optional positional parameters
   * <i>p<sub>1</sub> &hellip; p<sub>k</sub></i> with defaults <i>d<sub>1</sub>, &hellip;,
   * d<sub>k</sub></i>.
   * Otherwise, if <i>m</i> is the name of a getter member of <i>o</i> (declared implicitly or
   * explicitly) then <i>o.m</i> evaluates to the result of invoking the getter. </blockquote>
   *
   * The Dart Language Specification, 12.17: <blockquote> ... a getter invocation <i>i</i> of the
   * form <i>e.m</i> ...
   *
   * Let <i>T</i> be the static type of <i>e</i>. It is a static type warning if <i>T</i> does not
   * have a getter named <i>m</i>.
   *
   * The static type of <i>i</i> is the declared return type of <i>T.m</i>, if <i>T.m</i> exists;
   * otherwise the static type of <i>i</i> is dynamic.
   *
   * ... a getter invocation <i>i</i> of the form <i>C.m</i> ...
   *
   * It is a static warning if there is no class <i>C</i> in the enclosing lexical scope of
   * <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter named <i>m</i>.
   *
   * The static type of <i>i</i> is the declared return type of <i>C.m</i> if it exists or dynamic
   * otherwise.
   *
   * ... a top-level getter invocation <i>i</i> of the form <i>m</i>, where <i>m</i> is an
   * identifier ...
   *
   * The static type of <i>i</i> is the declared return type of <i>m</i>.</blockquote>
   */
  @override
  void visitPropertyAccess(PropertyAccess node) {
    SimpleIdentifier propertyName = node.propertyName;
    Element staticElement = propertyName.staticElement;
    DartType staticType = _dynamicType;
    if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(staticElement);
    } else {
      // TODO(brianwilkerson) Report this internal error.
    }
    staticType = _inferGenericInstantiationFromContext(node, staticType);
    if (!_inferObjectAccess(node, staticType, propertyName)) {
      _recordStaticType(propertyName, staticType);
      _recordStaticType(node, staticType);
    }
  }

  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a rethrow expression is
   * bottom.</blockquote>
   */
  @override
  void visitRethrowExpression(RethrowExpression node) {
    _recordStaticType(node, _typeProvider.bottomType);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments?.arguments;

    // If we have type arguments, use them.
    // TODO(paulberry): this logic seems redundant with
    //  ResolverVisitor._fromTypeArguments
    if (typeArguments != null) {
      if (typeArguments.length == 1) {
        (node as SetOrMapLiteralImpl).becomeSet();
        var elementType = _getType(typeArguments[0]) ?? _dynamicType;
        _recordStaticType(
            node, _typeProvider.setType.instantiate(<DartType>[elementType]));
        return;
      } else if (typeArguments.length == 2) {
        (node as SetOrMapLiteralImpl).becomeMap();
        var keyType = _getType(typeArguments[0]) ?? _dynamicType;
        var valueType = _getType(typeArguments[1]) ?? _dynamicType;
        _recordStaticType(node,
            _typeProvider.mapType.instantiate(<DartType>[keyType, valueType]));
        return;
      }
      // If we get here, then a nonsense number of type arguments were provided,
      // so treat it as though no type arguments were provided.
    }
    DartType literalType = _inferSetOrMapLiteralType(node);
    if (literalType.isDynamic) {
      // The literal is ambiguous, and further analysis won't resolve the
      // ambiguity.  Leave it as neither a set nor a map.
    } else if (literalType.element == _typeProvider.mapType.element) {
      (node as SetOrMapLiteralImpl).becomeMap();
    } else {
      assert(literalType.element == _typeProvider.setType.element);
      (node as SetOrMapLiteralImpl).becomeSet();
    }
    _resolver.inferenceContext.recordInference(node, literalType);
    _recordStaticType(node, literalType);
  }

  /**
   * The Dart Language Specification, 12.30: <blockquote>Evaluation of an identifier expression
   * <i>e</i> of the form <i>id</i> proceeds as follows:
   *
   * Let <i>d</i> be the innermost declaration in the enclosing lexical scope whose name is
   * <i>id</i>. If no such declaration exists in the lexical scope, let <i>d</i> be the declaration
   * of the inherited member named <i>id</i> if it exists.
   * * If <i>d</i> is a class or type alias <i>T</i>, the value of <i>e</i> is the unique instance
   * of class `Type` reifying <i>T</i>.
   * * If <i>d</i> is a type parameter <i>T</i>, then the value of <i>e</i> is the value of the
   * actual type argument corresponding to <i>T</i> that was passed to the generative constructor
   * that created the current binding of this. We are assured that this is well defined, because if
   * we were in a static member the reference to <i>T</i> would be a compile-time error.
   * * If <i>d</i> is a library variable then:
   * * If <i>d</i> is of one of the forms <i>var v = e<sub>i</sub>;</i>, <i>T v =
   * e<sub>i</sub>;</i>, <i>final v = e<sub>i</sub>;</i>, <i>final T v = e<sub>i</sub>;</i>, and no
   * value has yet been stored into <i>v</i> then the initializer expression <i>e<sub>i</sub></i> is
   * evaluated. If, during the evaluation of <i>e<sub>i</sub></i>, the getter for <i>v</i> is
   * referenced, a CyclicInitializationError is thrown. If the evaluation succeeded yielding an
   * object <i>o</i>, let <i>r = o</i>, otherwise let <i>r = null</i>. In any case, <i>r</i> is
   * stored into <i>v</i>. The value of <i>e</i> is <i>r</i>.
   * * If <i>d</i> is of one of the forms <i>const v = e;</i> or <i>const T v = e;</i> the result
   * of the getter is the value of the compile time constant <i>e</i>. Otherwise
   * * <i>e</i> evaluates to the current binding of <i>id</i>.
   * * If <i>d</i> is a local variable or formal parameter then <i>e</i> evaluates to the current
   * binding of <i>id</i>.
   * * If <i>d</i> is a static method, top level function or local function then <i>e</i>
   * evaluates to the function defined by <i>d</i>.
   * * If <i>d</i> is the declaration of a static variable or static getter declared in class
   * <i>C</i>, then <i>e</i> is equivalent to the getter invocation <i>C.id</i>.
   * * If <i>d</i> is the declaration of a top level getter, then <i>e</i> is equivalent to the
   * getter invocation <i>id</i>.
   * * Otherwise, if <i>e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer, evaluation of e causes a NoSuchMethodError
   * to be thrown.
   * * Otherwise <i>e</i> is equivalent to the property extraction <i>this.id</i>.
   * </blockquote>
   */
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    DartType staticType = _dynamicType;
    if (element is ClassElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = element.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is FunctionTypeAliasElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = element.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is MethodElement) {
      staticType = element.type;
    } else if (element is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(element);
    } else if (element is ExecutableElement) {
      staticType = element.type;
    } else if (element is TypeParameterElement) {
      staticType = _typeProvider.typeType;
    } else if (element is VariableElement) {
      VariableElement variable = element;
      staticType = _promoteManager.getStaticType(variable);
    } else if (element is PrefixElement) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier && parent.prefix == node ||
          parent is MethodInvocation && parent.target == node) {
        return;
      }
      staticType = _typeProvider.dynamicType;
    } else if (element is DynamicElementImpl) {
      staticType = _typeProvider.typeType;
    } else {
      staticType = _dynamicType;
    }
    staticType = _inferGenericInstantiationFromContext(node, staticType);
    _recordStaticType(node, staticType);
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _recordStaticType(node, _typeProvider.stringType);
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  @override
  void visitStringInterpolation(StringInterpolation node) {
    _recordStaticType(node, _typeProvider.stringType);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    if (thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported.
      _recordStaticType(node, _dynamicType);
    } else {
      _recordStaticType(node, thisType);
    }
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _recordStaticType(node, _typeProvider.symbolType);
  }

  /**
   * The Dart Language Specification, 12.10: <blockquote>The static type of `this` is the
   * interface of the immediately enclosing class.</blockquote>
   */
  @override
  void visitThisExpression(ThisExpression node) {
    if (thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported.
      _recordStaticType(node, _dynamicType);
    } else {
      _recordStaticType(node, thisType);
    }
  }

  /**
   * The Dart Language Specification, 12.8: <blockquote>The static type of a throw expression is
   * bottom.</blockquote>
   */
  @override
  void visitThrowExpression(ThrowExpression node) {
    _recordStaticType(node, _typeProvider.bottomType);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _inferLocalVariableType(node, node.initializer);
  }

  /**
   * Set the static type of [node] to be the least upper bound of the static
   * types of subexpressions [expr1] and [expr2].
   */
  void _analyzeLeastUpperBound(
      Expression node, Expression expr1, Expression expr2,
      {bool read: false}) {
    DartType staticType1 = _getExpressionType(expr1, read: read);
    DartType staticType2 = _getExpressionType(expr2, read: read);
    if (staticType1 == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticType1 = _dynamicType;
    }
    if (staticType2 == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticType2 = _dynamicType;
    }

    DartType staticType =
        _typeSystem.getLeastUpperBound(staticType1, staticType2) ??
            _dynamicType;

    _recordStaticType(node, staticType);
  }

  /// Check that the result [type] of a prefix or postfix `++` or `--`
  /// expression is assignable to the write type of the [operand].
  void _checkForInvalidAssignmentIncDec(
      AstNode node, Expression operand, DartType type) {
    var operandWriteType = _getStaticType(operand);
    if (!_typeSystem.isAssignableTo(type, operandWriteType)) {
      _resolver.errorReporter.reportTypeErrorForNode(
        StaticTypeWarningCode.INVALID_ASSIGNMENT,
        node,
        [type, operandWriteType],
      );
    }
  }

  /**
   * Record that the static type of the given node is the type of the second argument to the method
   * represented by the given element.
   *
   * @param element the element representing the method invoked by the given node
   */
  DartType _computeArgumentType(ExecutableElement element) {
    if (element != null) {
      List<ParameterElement> parameters = element.parameters;
      if (parameters != null && parameters.length == 2) {
        return parameters[1].type;
      }
    }
    return _dynamicType;
  }

  DartType _computeElementType(CollectionElement element) {
    if (element is ForElement) {
      return _computeElementType(element.body);
    } else if (element is IfElement) {
      DartType thenType = _computeElementType(element.thenElement);
      if (element.elseElement == null) {
        return thenType;
      }
      DartType elseType = _computeElementType(element.elseElement);
      return _typeSystem.leastUpperBound(thenType, elseType);
    } else if (element is Expression) {
      return element.staticType;
    } else if (element is MapLiteralEntry) {
      // This error will be reported elsewhere.
      return _typeProvider.dynamicType;
    } else if (element is SpreadElement) {
      DartType expressionType = element.expression.staticType;
      bool isNull = expressionType.isDartCoreNull;
      if (!isNull && expressionType is InterfaceType) {
        if (_typeSystem.isSubtypeOf(
            expressionType, _typeProvider.iterableObjectType)) {
          InterfaceType iterableType = (expressionType as InterfaceTypeImpl)
              .asInstanceOf(_typeProvider.iterableType.element);
          return iterableType.typeArguments[0];
        }
      } else if (expressionType.isDynamic) {
        return expressionType;
      } else if (isNull &&
          element.spreadOperator.type ==
              TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
        return expressionType;
      }
      // TODO(brianwilkerson) Report this as an error.
      return _typeProvider.dynamicType;
    }
    throw StateError('Unhandled element type ${element.runtimeType}');
  }

  /**
   * Compute the return type of the method or function represented by the given
   * type that is being invoked.
   */
  DartType _computeInvokeReturnType(DartType type) {
    if (type is InterfaceType) {
      MethodElement callMethod = type.lookUpMethod(
          FunctionElement.CALL_METHOD_NAME, _resolver.definingLibrary);
      return callMethod?.type?.returnType ?? _dynamicType;
    } else if (type is FunctionType) {
      return type.returnType ?? _dynamicType;
    }
    return _dynamicType;
  }

  /**
   * Given a function body and its return type, compute the return type of
   * the entire function, taking into account whether the function body
   * is `sync*`, `async` or `async*`.
   *
   * See also [FunctionBody.isAsynchronous], [FunctionBody.isGenerator].
   */
  DartType _computeReturnTypeOfFunction(FunctionBody body, DartType type) {
    if (body.isGenerator) {
      InterfaceType genericType = body.isAsynchronous
          ? _typeProvider.streamType
          : _typeProvider.iterableType;
      return genericType.instantiate(<DartType>[type]);
    } else if (body.isAsynchronous) {
      if (type.isDartAsyncFutureOr) {
        type = (type as InterfaceType).typeArguments[0];
      }
      return _typeProvider.futureType
          .instantiate(<DartType>[_typeSystem.flatten(type)]);
    } else {
      return type;
    }
  }

  /**
   * Compute the static return type of the method or function represented by the given element.
   *
   * @param element the element representing the method or function invoked by the given node
   * @return the static return type that was computed
   */
  DartType _computeStaticReturnType(Element element) {
    if (element is PropertyAccessorElement) {
      //
      // This is a function invocation expression disguised as something else.
      // We are invoking a getter and then invoking the returned function.
      //
      FunctionType propertyType = element.type;
      if (propertyType != null) {
        return _computeInvokeReturnType(propertyType.returnType);
      }
    } else if (element is ExecutableElement) {
      return _computeInvokeReturnType(element.type);
    } else if (element is VariableElement) {
      DartType variableType = _promoteManager.getStaticType(element);
      return _computeInvokeReturnType(variableType);
    }
    return _dynamicType;
  }

  /**
   * Given a function declaration, compute the return static type of the function. The return type
   * of functions with a block body is `dynamicType`, with an expression body it is the type
   * of the expression.
   *
   * @param node the function expression whose static return type is to be computed
   * @return the static return type that was computed
   */
  DartType _computeStaticReturnTypeOfFunctionDeclaration(
      FunctionDeclaration node) {
    TypeAnnotation returnType = node.returnType;
    if (returnType == null) {
      return _dynamicType;
    }
    return returnType.type;
  }

  DartType _findIteratedType(DartType type, DartType targetType) {
    // TODO(vsm): Use leafp's matchType here?
    // Set by _find if match is found
    DartType result;
    // Elements we've already visited on a given inheritance path.
    HashSet<ClassElement> visitedClasses;

    type = type.resolveToBound(_typeProvider.objectType);

    bool _find(InterfaceType type) {
      ClassElement element = type.element;
      if (type == _typeProvider.objectType || element == null) {
        return false;
      }
      if (element == targetType.element) {
        List<DartType> typeArguments = type.typeArguments;
        assert(typeArguments.length == 1);
        result = typeArguments[0];
        return true;
      }
      if (visitedClasses == null) {
        visitedClasses = new HashSet<ClassElement>();
      }
      // Already visited this class along this path
      if (!visitedClasses.add(element)) {
        return false;
      }
      try {
        return _find(type.superclass) ||
            type.interfaces.any(_find) ||
            type.mixins.any(_find);
      } finally {
        visitedClasses.remove(element);
      }
    }

    if (type is InterfaceType) {
      _find(type);
    }
    return result;
  }

  /**
   * If the given element name can be mapped to the name of a class defined within the given
   * library, return the type specified by the argument.
   *
   * @param library the library in which the specified type would be defined
   * @param elementName the name of the element for which a type is being sought
   * @param nameMap an optional map used to map the element name to a type name
   * @return the type specified by the first argument in the argument list
   */
  DartType _getElementNameAsType(
      LibraryElement library, String elementName, Map<String, String> nameMap) {
    if (elementName != null) {
      if (nameMap != null) {
        elementName = nameMap[elementName.toLowerCase()];
      }
      ClassElement returnType = library.getType(elementName);
      if (returnType != null) {
        if (returnType.typeParameters.isNotEmpty) {
          // Caller can't deal with unbound type parameters, so substitute
          // `dynamic`.
          return returnType.type.instantiate(
              returnType.typeParameters.map((_) => _dynamicType).toList());
        }
        return returnType.type;
      }
    }
    return null;
  }

  /**
   * Gets the definite type of expression, which can be used in cases where
   * the most precise type is desired, for example computing the least upper
   * bound.
   *
   * See [getExpressionType] for more information. Without strong mode, this is
   * equivalent to [_getStaticType].
   */
  DartType _getExpressionType(Expression expr, {bool read: false}) =>
      getExpressionType(expr, _typeSystem, _typeProvider, read: read);

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, return the String value of the argument.
   *
   * @param argumentList the list of arguments from which a string value is to be extracted
   * @return the string specified by the first argument in the argument list
   */
  String _getFirstArgumentAsString(ArgumentList argumentList) {
    NodeList<Expression> arguments = argumentList.arguments;
    if (arguments.length > 0) {
      Expression argument = arguments[0];
      if (argument is SimpleStringLiteral) {
        return argument.value;
      }
    }
    return null;
  }

  /**
   * Return the static type of the given [expression].
   */
  DartType _getStaticType(Expression expression, {bool read: false}) {
    DartType type;
    if (read) {
      type = getReadType(expression);
    } else {
      type = expression.staticType;
    }
    if (type == null) {
      // TODO(brianwilkerson) Determine the conditions for which the static type
      // is null.
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type represented by the given type [annotation].
   */
  DartType _getType(TypeAnnotation annotation) {
    DartType type = annotation.type;
    if (type == null) {
      //TODO(brianwilkerson) Determine the conditions for which the type is
      // null.
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type that should be recorded for a node that resolved to the given accessor.
   *
   * @param accessor the accessor that the node resolved to
   * @return the type that should be recorded for a node that resolved to the given accessor
   */
  DartType _getTypeOfProperty(PropertyAccessorElement accessor) {
    FunctionType functionType = accessor.type;
    if (functionType == null) {
      // TODO(brianwilkerson) Report this internal error. This happens when we
      // are analyzing a reference to a property before we have analyzed the
      // declaration of the property or when the property does not have a
      // defined type.
      return _dynamicType;
    }
    if (accessor.isSetter) {
      List<DartType> parameterTypes = functionType.normalParameterTypes;
      if (parameterTypes != null && parameterTypes.length > 0) {
        return parameterTypes[0];
      }
      PropertyAccessorElement getter = accessor.variable.getter;
      if (getter != null) {
        functionType = getter.type;
        if (functionType != null) {
          return functionType.returnType;
        }
      }
      return _dynamicType;
    }
    return functionType.returnType;
  }

  _InferredCollectionElementTypeInformation _inferCollectionElementType(
      CollectionElement element) {
    if (element is ForElement) {
      return _inferCollectionElementType(element.body);
    } else if (element is IfElement) {
      _InferredCollectionElementTypeInformation thenType =
          _inferCollectionElementType(element.thenElement);
      if (element.elseElement == null) {
        return thenType;
      }
      _InferredCollectionElementTypeInformation elseType =
          _inferCollectionElementType(element.elseElement);
      return _InferredCollectionElementTypeInformation.forIfElement(
          _typeSystem, thenType, elseType);
    } else if (element is Expression) {
      return _InferredCollectionElementTypeInformation(
          elementType: element.staticType, keyType: null, valueType: null);
    } else if (element is MapLiteralEntry) {
      return _InferredCollectionElementTypeInformation(
          elementType: null,
          keyType: element.key.staticType,
          valueType: element.value.staticType);
    } else if (element is SpreadElement) {
      DartType expressionType = element.expression.staticType;
      bool isNull = expressionType.isDartCoreNull;
      if (!isNull && expressionType is InterfaceType) {
        if (_typeSystem.isSubtypeOf(
            expressionType, _typeProvider.iterableObjectType)) {
          InterfaceType iterableType = (expressionType as InterfaceTypeImpl)
              .asInstanceOf(_typeProvider.iterableType.element);
          return _InferredCollectionElementTypeInformation(
              elementType: iterableType.typeArguments[0],
              keyType: null,
              valueType: null);
        } else if (_typeSystem.isSubtypeOf(
            expressionType, _typeProvider.mapObjectObjectType)) {
          InterfaceType mapType = (expressionType as InterfaceTypeImpl)
              .asInstanceOf(_typeProvider.mapType.element);
          List<DartType> typeArguments = mapType.typeArguments;
          return _InferredCollectionElementTypeInformation(
              elementType: null,
              keyType: typeArguments[0],
              valueType: typeArguments[1]);
        }
      } else if (expressionType.isDynamic) {
        return _InferredCollectionElementTypeInformation(
            elementType: expressionType,
            keyType: expressionType,
            valueType: expressionType);
      } else if (isNull &&
          element.spreadOperator.type ==
              TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
        return _InferredCollectionElementTypeInformation(
            elementType: expressionType,
            keyType: expressionType,
            valueType: expressionType);
      }
      return _InferredCollectionElementTypeInformation(
          elementType: null, keyType: null, valueType: null);
    } else {
      throw StateError('Unknown element type ${element.runtimeType}');
    }
  }

  /**
   * Given a declared identifier from a foreach loop, attempt to infer
   * a type for it if one is not already present.  Inference is based
   * on the type of the iterator or stream over which the foreach loop
   * is defined.
   */
  void _inferForEachLoopVariableType(DeclaredIdentifier loopVariable) {
    if (loopVariable != null && loopVariable.type == null) {
      AstNode parent = loopVariable.parent;
      Token awaitKeyword;
      Expression iterable;
      if (parent is ForEachPartsWithDeclaration) {
        AstNode parentParent = parent.parent;
        if (parentParent is ForStatementImpl) {
          awaitKeyword = parentParent.awaitKeyword;
        } else if (parentParent is ForElement) {
          awaitKeyword = parentParent.awaitKeyword;
        } else {
          return;
        }
        iterable = parent.iterable;
      } else {
        return;
      }
      if (iterable != null) {
        LocalVariableElementImpl element = loopVariable.declaredElement;
        DartType exprType = iterable.staticType;
        DartType targetType = (awaitKeyword == null)
            ? _typeProvider.iterableType
            : _typeProvider.streamType;
        DartType iteratedType = _findIteratedType(exprType, targetType);
        if (element != null && iteratedType != null) {
          element.type = iteratedType;
          loopVariable.identifier.staticType = iteratedType;
        }
      }
    }
  }

  /**
   * Given an uninstantiated generic function type, try to infer the
   * instantiated generic function type from the surrounding context.
   */
  DartType _inferGenericInstantiationFromContext(AstNode node, DartType type) {
    TypeSystem ts = _typeSystem;
    var context = InferenceContext.getContext(node);
    if (context is FunctionType &&
        type is FunctionType &&
        ts is Dart2TypeSystem) {
      return ts.inferFunctionTypeInstantiation(context, type,
          errorReporter: _resolver.errorReporter, errorNode: node);
    }
    return type;
  }

  /**
   * Given a possibly generic invocation like `o.m(args)` or `(f)(args)` try to
   * infer the instantiated generic function type.
   *
   * This takes into account both the context type, as well as information from
   * the argument types.
   */
  void _inferGenericInvocationExpression(InvocationExpression node) {
    ArgumentList arguments = node.argumentList;
    var type = node.function.staticType;
    var freshType = _getFreshType(type);

    FunctionType inferred = _inferGenericInvoke(
        node, freshType, node.typeArguments, arguments, node.function);
    if (inferred != null && inferred != node.staticInvokeType) {
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              arguments, inferred.parameters, null);
      node.staticInvokeType = inferred;
    }
  }

  /**
   * Given a possibly generic invocation or instance creation, such as
   * `o.m(args)` or `(f)(args)` or `new T(args)` try to infer the instantiated
   * generic function type.
   *
   * This takes into account both the context type, as well as information from
   * the argument types.
   */
  FunctionType _inferGenericInvoke(
      Expression node,
      DartType fnType,
      TypeArgumentList typeArguments,
      ArgumentList argumentList,
      AstNode errorNode,
      {bool isConst: false}) {
    TypeSystem ts = _typeSystem;
    if (typeArguments == null &&
        fnType is FunctionType &&
        fnType.typeFormals.isNotEmpty &&
        ts is Dart2TypeSystem) {
      // Get the parameters that correspond to the uninstantiated generic.
      List<ParameterElement> rawParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              argumentList, fnType.parameters, null);

      List<ParameterElement> params = <ParameterElement>[];
      List<DartType> argTypes = <DartType>[];
      for (int i = 0, length = rawParameters.length; i < length; i++) {
        ParameterElement parameter = rawParameters[i];
        if (parameter != null) {
          params.add(parameter);
          argTypes.add(argumentList.arguments[i].staticType);
        }
      }
      return ts.inferGenericFunctionOrType(
          fnType, params, argTypes, InferenceContext.getContext(node),
          isConst: isConst,
          errorReporter: _resolver.errorReporter,
          errorNode: errorNode);
    }
    return null;
  }

  /**
   * Given an instance creation of a possibly generic type, infer the type
   * arguments using the current context type as well as the argument types.
   */
  void _inferInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructor = node.constructorName;
    ConstructorElement originalElement = constructor.staticElement;
    // If the constructor is generic, we'll have a ConstructorMember that
    // substitutes in type arguments (possibly `dynamic`) from earlier in
    // resolution.
    //
    // Otherwise we'll have a ConstructorElement, and we can skip inference
    // because there's nothing to infer in a non-generic type.
    if (originalElement is! ConstructorMember) {
      return;
    }

    // TODO(leafp): Currently, we may re-infer types here, since we
    // sometimes resolve multiple times.  We should really check that we
    // have not already inferred something.  However, the obvious ways to
    // check this don't work, since we may have been instantiated
    // to bounds in an earlier phase, and we *do* want to do inference
    // in that case.

    // Get back to the uninstantiated generic constructor.
    // TODO(jmesserly): should we store this earlier in resolution?
    // Or look it up, instead of jumping backwards through the Member?
    var rawElement = (originalElement as ConstructorMember).baseElement;

    FunctionType constructorType = constructorToGenericFunctionType(rawElement);

    ArgumentList arguments = node.argumentList;
    FunctionType inferred = _inferGenericInvoke(node, constructorType,
        constructor.type.typeArguments, arguments, node.constructorName,
        isConst: node.isConst);

    if (inferred != null && inferred != originalElement.type) {
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              arguments, inferred.parameters, null);
      inferConstructorName(constructor, inferred.returnType);
      // Update the static element as well. This is used in some cases, such as
      // computing constant values. It is stored in two places.
      constructor.staticElement =
          ConstructorMember.from(rawElement, inferred.returnType);
      node.staticElement = constructor.staticElement;
    }
  }

  /**
   * Infers the return type of a local function, either a lambda or
   * (in strong mode) a local function declaration.
   */
  void _inferLocalFunctionReturnType(FunctionExpression node) {
    ExecutableElementImpl functionElement =
        node.declaredElement as ExecutableElementImpl;

    FunctionBody body = node.body;

    DartType computedType = InferenceContext.getContext(body) ?? _dynamicType;

    computedType = _computeReturnTypeOfFunction(body, computedType);
    functionElement.returnType = computedType;
    _recordStaticType(node, functionElement.type);
    _resolver.inferenceContext.recordInference(node, functionElement.type);
  }

  /**
   * Given a local variable declaration and its initializer, attempt to infer
   * a type for the local variable declaration based on the initializer.
   * Inference is only done if an explicit type is not present, and if
   * inferring a type improves the type.
   */
  void _inferLocalVariableType(
      VariableDeclaration node, Expression initializer) {
    AstNode parent = node.parent;
    if (initializer != null) {
      if (parent is VariableDeclarationList && parent.type == null) {
        DartType type = resolutionMap.staticTypeForExpression(initializer);
        if (type != null && !type.isBottom && !type.isDartCoreNull) {
          VariableElement element = node.declaredElement;
          if (element is LocalVariableElementImpl) {
            element.type = initializer.staticType;
            node.name.staticType = initializer.staticType;
          }
        }
      }
    } else if (_strictInference) {
      if (parent is VariableDeclarationList && parent.type == null) {
        _resolver.errorReporter.reportTypeErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE,
          node,
          [node.name.name],
        );
      }
    }
  }

  /**
   * Given a method invocation [node], attempt to infer a better
   * type for the result if it is an inline JS invocation
   */
  // TODO(jmesserly): we should remove this, and infer type from context, rather
  // than try to understand the dart2js type grammar.
  // (At the very least, we should lookup type name in the correct scope.)
  bool _inferMethodInvocationInlineJS(MethodInvocation node) {
    Element e = node.methodName.staticElement;
    if (e is FunctionElement &&
        e.library.source.uri.toString() == 'dart:_foreign_helper' &&
        e.name == 'JS') {
      String typeStr = _getFirstArgumentAsString(node.argumentList);
      DartType returnType = null;
      if (typeStr == '-dynamic') {
        returnType = _typeProvider.bottomType;
      } else {
        var components = typeStr.split('|');
        if (components.remove('Null')) {
          typeStr = components.join('|');
        }
        returnType = _getElementNameAsType(
            _typeProvider.objectType.element.library, typeStr, null);
      }
      if (returnType != null) {
        _recordStaticType(node, returnType);
        return true;
      }
    }
    return false;
  }

  /**
   * Given a method invocation [node], attempt to infer a better
   * type for the result if the target is dynamic and the method
   * being called is one of the object methods.
   */
  // TODO(jmesserly): we should move this logic to ElementResolver.
  // If we do it here, we won't have correct parameter elements set on the
  // node's argumentList. (This likely affects only explicit calls to
  // `Object.noSuchMethod`.)
  bool _inferMethodInvocationObject(MethodInvocation node) {
    // If we have a call like `toString()` or `libraryPrefix.toString()` don't
    // infer it.
    Expression target = node.realTarget;
    if (target == null ||
        target is SimpleIdentifier && target.staticElement is PrefixElement) {
      return false;
    }

    // Object methods called on dynamic targets can have their types improved.
    String name = node.methodName.name;
    MethodElement inferredElement =
        _typeProvider.objectType.element.getMethod(name);
    if (inferredElement == null || inferredElement.isStatic) {
      return false;
    }
    DartType inferredType = inferredElement.type;
    DartType nodeType = node.staticInvokeType;
    if (nodeType != null &&
        nodeType.isDynamic &&
        inferredType is FunctionType &&
        inferredType.parameters.isEmpty &&
        node.argumentList.arguments.isEmpty &&
        _typeProvider.nonSubtypableTypes.contains(inferredType.returnType)) {
      node.staticInvokeType = inferredType;
      _recordStaticType(node, inferredType.returnType);
      return true;
    }
    return false;
  }

  /**
   * Given a property access [node] with static type [nodeType],
   * and [id] is the property name being accessed, infer a type for the
   * access itself and its constituent components if the access is to one of the
   * methods or getters of the built in 'Object' type, and if the result type is
   * a sealed type. Returns true if inference succeeded.
   */
  bool _inferObjectAccess(
      Expression node, DartType nodeType, SimpleIdentifier id) {
    // If we have an access like `libraryPrefix.hashCode` don't infer it.
    if (node is PrefixedIdentifier &&
        node.prefix.staticElement is PrefixElement) {
      return false;
    }
    // Search for Object accesses.
    String name = id.name;
    PropertyAccessorElement inferredElement =
        _typeProvider.objectType.element.getGetter(name);
    if (inferredElement == null || inferredElement.isStatic) {
      return false;
    }
    DartType inferredType = inferredElement.type.returnType;
    if (nodeType != null &&
        nodeType.isDynamic &&
        inferredType != null &&
        _typeProvider.nonSubtypableTypes.contains(inferredType)) {
      _recordStaticType(id, inferredType);
      _recordStaticType(node, inferredType);
      return true;
    }
    return false;
  }

  DartType _inferSetOrMapLiteralType(SetOrMapLiteral literal) {
    var literalImpl = literal as SetOrMapLiteralImpl;
    DartType contextType = literalImpl.contextType;
    literalImpl.contextType = null; // Not needed anymore.
    NodeList<CollectionElement> elements = literal.elements;
    List<_InferredCollectionElementTypeInformation> inferredTypes = [];
    bool canBeAMap = true;
    bool mustBeAMap = false;
    bool canBeASet = true;
    bool mustBeASet = false;
    for (CollectionElement element in elements) {
      _InferredCollectionElementTypeInformation inferredType =
          _inferCollectionElementType(element);
      inferredTypes.add(inferredType);
      canBeAMap = canBeAMap && inferredType.canBeAMap;
      mustBeAMap = mustBeAMap || inferredType.mustBeAMap;
      canBeASet = canBeASet && inferredType.canBeASet;
      mustBeASet = mustBeASet || inferredType.mustBeASet;
    }
    if (canBeASet && mustBeASet) {
      return _toSetType(literal, contextType, inferredTypes);
    } else if (canBeAMap && mustBeAMap) {
      return _toMapType(literal, contextType, inferredTypes);
    }
    // Note: according to the spec, the following computations should be based
    // on the greatest closure of the context type (unless the context type is
    // `?`).  In practice, we can just use the context type directly, because
    // the only way the greatest closure of the context type could possibly have
    // a different subtype relationship to `Iterable<Object>` and
    // `Map<Object, Object>` is if the context type is `?`.
    bool contextProvidesAmbiguityResolutionClues =
        contextType != null && contextType is! UnknownInferredType;
    bool contextIsIterable = contextProvidesAmbiguityResolutionClues &&
        _typeSystem.isSubtypeOf(contextType, _typeProvider.iterableObjectType);
    bool contextIsMap = contextProvidesAmbiguityResolutionClues &&
        _typeSystem.isSubtypeOf(contextType, _typeProvider.mapObjectObjectType);
    if (contextIsIterable && !contextIsMap) {
      return _toSetType(literal, contextType, inferredTypes);
    } else if ((contextIsMap && !contextIsIterable) || elements.isEmpty) {
      return _toMapType(literal, contextType, inferredTypes);
    } else {
      // Ambiguous.  We're not going to get any more information to resolve the
      // ambiguity.  We don't want to make an arbitrary decision at this point
      // because it will interfere with future type inference (see
      // dartbug.com/36210), so we return a type of `dynamic`.
      if (mustBeAMap && mustBeASet) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, literal);
      } else {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, literal);
      }
      return _typeProvider.dynamicType;
    }
  }

  /**
   * Return `true` if the given [node] is not a type literal.
   */
  bool _isNotTypeLiteral(Identifier node) {
    AstNode parent = node.parent;
    return parent is TypeName ||
        (parent is PrefixedIdentifier &&
            (parent.parent is TypeName || identical(parent.prefix, node))) ||
        (parent is PropertyAccess &&
            identical(parent.target, node) &&
            parent.operator.type == TokenType.PERIOD) ||
        (parent is MethodInvocation &&
            identical(node, parent.target) &&
            parent.operator.type == TokenType.PERIOD);
  }

  /**
   * Record that the static type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the static type of the node
   */
  void _recordStaticType(Expression expression, DartType type) {
    if (type == null) {
      expression.staticType = _dynamicType;
    } else {
      expression.staticType = type;
    }
  }

  DartType _toMapType(SetOrMapLiteral node, DartType contextType,
      List<_InferredCollectionElementTypeInformation> inferredTypes) {
    DartType dynamicType = _typeProvider.dynamicType;
    List<DartType> keyTypes = [];
    List<DartType> valueTypes = [];
    for (int i = 0; i < inferredTypes.length; i++) {
      keyTypes.add(inferredTypes[i].keyType ?? dynamicType);
      valueTypes.add(inferredTypes[i].valueType ?? dynamicType);
    }
    TypeParameterType keyTypeParam =
        _typeProvider.mapType.typeParameters[0].type;
    TypeParameterType valueTypeParam =
        _typeProvider.mapType.typeParameters[1].type;
    ParameterElementImpl syntheticKeyParameter =
        new ParameterElementImpl.synthetic(
            'key', keyTypeParam, ParameterKind.POSITIONAL);
    ParameterElementImpl syntheticValueParameter =
        new ParameterElementImpl.synthetic(
            'value', valueTypeParam, ParameterKind.POSITIONAL);
    List<ParameterElement> typeParameters =
        new List.filled(keyTypes.length, syntheticKeyParameter, growable: true)
          ..addAll(new List.filled(valueTypes.length, syntheticValueParameter));
    List<DartType> elementTypes = new List<DartType>.from(keyTypes)
      ..addAll(valueTypes);
    return (_typeSystem as Dart2TypeSystem).inferGenericFunctionOrType(
        _typeProvider.mapType, typeParameters, elementTypes, contextType,
        isConst: node.isConst,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
  }

  DartType _toSetType(SetOrMapLiteral node, DartType contextType,
      List<_InferredCollectionElementTypeInformation> inferredTypes) {
    DartType dynamicType = _typeProvider.dynamicType;
    List<DartType> elementTypes = [];
    for (int i = 0; i < inferredTypes.length; i++) {
      elementTypes.add(inferredTypes[i].elementType ?? dynamicType);
    }
    TypeParameterType elementTypeParam =
        _typeProvider.setType.typeParameters[0].type;
    ParameterElementImpl syntheticElementParameter =
        new ParameterElementImpl.synthetic(
            'key', elementTypeParam, ParameterKind.POSITIONAL);
    List<ParameterElement> parameters = new List.filled(
        elementTypes.length, syntheticElementParameter,
        growable: true);
    return (_typeSystem as Dart2TypeSystem).inferGenericFunctionOrType(
        _typeProvider.setType, parameters, elementTypes, contextType,
        isConst: node.isConst,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
  }

  /**
   * Given a constructor for a generic type, returns the equivalent generic
   * function type that we could use to forward to the constructor, or for a
   * non-generic type simply returns the constructor type.
   *
   * For example given the type `class C<T> { C(T arg); }`, the generic function
   * type is `<T>(T) -> C<T>`.
   */
  static FunctionType constructorToGenericFunctionType(
      ConstructorElement constructor) {
    // TODO(jmesserly): it may be worth making this available from the
    // constructor. It's nice if our inference code can operate uniformly on
    // function types.
    ClassElement cls = constructor.enclosingElement;
    FunctionType type = constructor.type;
    if (cls.typeParameters.isEmpty) {
      return type;
    }

    // Create a synthetic function type using the class type parameters,
    // and then rename it with fresh variables.
    var name = cls.name;
    if (constructor.name != null) {
      name += '.' + constructor.name;
    }
    var function = new FunctionElementImpl(name, -1);
    function.enclosingElement = cls.enclosingElement;
    function.isSynthetic = true;
    function.returnType = type.returnType;
    function.shareTypeParameters(cls.typeParameters);
    function.shareParameters(type.parameters);
    function.type = new FunctionTypeImpl(function);
    return new FunctionTypeImpl.fresh(function.type);
  }

  static DartType _getFreshType(DartType type) {
    if (type is FunctionType) {
      if (AnalysisDriver.useSummary2) {
        var parameters = getFreshTypeParameters(type.typeFormals);
        return parameters.applyToFunctionType(type);
      } else {
        return new FunctionTypeImpl.fresh(type);
      }
    } else {
      return type;
    }
  }
}

class _InferredCollectionElementTypeInformation {
  final DartType elementType;
  final DartType keyType;
  final DartType valueType;

  _InferredCollectionElementTypeInformation(
      {this.elementType, this.keyType, this.valueType});

  factory _InferredCollectionElementTypeInformation.forIfElement(
      TypeSystem typeSystem,
      _InferredCollectionElementTypeInformation thenInfo,
      _InferredCollectionElementTypeInformation elseInfo) {
    if (thenInfo.isDynamic) {
      DartType dynamic = thenInfo.elementType;
      return _InferredCollectionElementTypeInformation(
          elementType: _dynamicOrNull(elseInfo.elementType, dynamic),
          keyType: _dynamicOrNull(elseInfo.keyType, dynamic),
          valueType: _dynamicOrNull(elseInfo.valueType, dynamic));
    } else if (elseInfo.isDynamic) {
      DartType dynamic = elseInfo.elementType;
      return _InferredCollectionElementTypeInformation(
          elementType: _dynamicOrNull(thenInfo.elementType, dynamic),
          keyType: _dynamicOrNull(thenInfo.keyType, dynamic),
          valueType: _dynamicOrNull(thenInfo.valueType, dynamic));
    }
    return _InferredCollectionElementTypeInformation(
        elementType: _leastUpperBoundOfTypes(
            typeSystem, thenInfo.elementType, elseInfo.elementType),
        keyType: _leastUpperBoundOfTypes(
            typeSystem, thenInfo.keyType, elseInfo.keyType),
        valueType: _leastUpperBoundOfTypes(
            typeSystem, thenInfo.valueType, elseInfo.valueType));
  }

  bool get canBeAMap => keyType != null || valueType != null;

  bool get canBeASet => elementType != null;

  bool get isDynamic =>
      elementType != null &&
      elementType.isDynamic &&
      keyType != null &&
      keyType.isDynamic &&
      valueType != null &&
      valueType.isDynamic;

  bool get mustBeAMap => canBeAMap && elementType == null;

  bool get mustBeASet => canBeASet && keyType == null && valueType == null;

  @override
  String toString() {
    return '($elementType, $keyType, $valueType)';
  }

  static DartType _dynamicOrNull(DartType type, DartType dynamic) {
    if (type == null) {
      return null;
    }
    return dynamic;
  }

  static DartType _leastUpperBoundOfTypes(
      TypeSystem typeSystem, DartType first, DartType second) {
    if (first == null) {
      return second;
    } else if (second == null) {
      return first;
    } else {
      return typeSystem.leastUpperBound(first, second);
    }
  }
}
