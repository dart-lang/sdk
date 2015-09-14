// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.resolver.static_type_analyzer;

import 'dart:collection';

import 'package:analyzer/src/generated/scanner.dart';

import 'ast.dart';
import 'element.dart';
import 'java_engine.dart';
import 'resolver.dart';
import 'scanner.dart' as sc;

/**
 * Instances of the class `StaticTypeAnalyzer` perform two type-related tasks. First, they
 * compute the static type of every expression. Second, they look for any static type errors or
 * warnings that might need to be generated. The requirements for the type analyzer are:
 * <ol>
 * * Every element that refers to types should be fully populated.
 * * Every node representing an expression should be resolved to the Type of the expression.
 * </ol>
 */
class StaticTypeAnalyzer extends SimpleAstVisitor<Object> {
  /**
   * A table mapping HTML tag names to the names of the classes (in 'dart:html') that implement
   * those tags.
   */
  static HashMap<String, String> _HTML_ELEMENT_TO_CLASS_MAP =
      _createHtmlTagToClassMap();

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
   * The type representing the class containing the nodes being analyzed,
   * or `null` if the nodes are not within a class.
   */
  InterfaceType thisType;

  /**
   * The object keeping track of which elements have had their types overridden.
   */
  TypeOverrideManager _overrideManager;

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager;

  /**
   * A table mapping [ExecutableElement]s to their propagated return types.
   */
  HashMap<ExecutableElement, DartType> _propagatedReturnTypes =
      new HashMap<ExecutableElement, DartType>();

  /**
   * Initialize a newly created type analyzer.
   *
   * @param resolver the resolver driving this participant
   */
  StaticTypeAnalyzer(this._resolver) {
    _typeProvider = _resolver.typeProvider;
    _dynamicType = _typeProvider.dynamicType;
    _overrideManager = _resolver.overrideManager;
    _promoteManager = _resolver.promoteManager;
    _typeSystem = new TypeSystemImpl(_typeProvider);
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    _recordStaticType(node, _typeProvider.stringType);
    return null;
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
  Object visitAsExpression(AsExpression node) {
    _recordStaticType(node, _getType(node.type));
    return null;
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
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operator = node.operator.type;
    if (operator == sc.TokenType.EQ) {
      Expression rightHandSide = node.rightHandSide;
      DartType staticType = _getStaticType(rightHandSide);
      _recordStaticType(node, staticType);
      DartType overrideType = staticType;
      DartType propagatedType = rightHandSide.propagatedType;
      if (propagatedType != null) {
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
        overrideType = propagatedType;
      }
      _resolver.overrideExpression(node.leftHandSide, overrideType, true, true);
    } else if (operator == sc.TokenType.QUESTION_QUESTION_EQ) {
      // The static type of a compound assignment using ??= is the least upper
      // bound of the static types of the LHS and RHS.
      _analyzeLeastUpperBound(node, node.leftHandSide, node.rightHandSide);
      return null;
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      _recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (!identical(propagatedMethodElement, staticMethodElement)) {
        DartType propagatedType =
            _computeStaticReturnType(propagatedMethodElement);
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 16.29 (Await Expressions):
   *
   *   The static type of [the expression "await e"] is flatten(T) where T is
   *   the static type of e.
   */
  @override
  Object visitAwaitExpression(AwaitExpression node) {
    DartType staticExpressionType = _getStaticType(node.expression);
    if (staticExpressionType == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticExpressionType = _dynamicType;
    }
    DartType staticType = flattenFutures(_typeProvider, staticExpressionType);
    _recordStaticType(node, staticType);
    DartType propagatedExpressionType = node.expression.propagatedType;
    DartType propagatedType =
        flattenFutures(_typeProvider, propagatedExpressionType);
    _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    return null;
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
  Object visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION) {
      // Evaluation of an if-null expresion e of the form e1 ?? e2 is
      // equivalent to the evaluation of the expression
      // ((x) => x == null ? e2 : x)(e1).  The static type of e is the least
      // upper bound of the static type of e1 and the static type of e2.
      _analyzeLeastUpperBound(node, node.leftOperand, node.rightOperand);
      return null;
    }
    ExecutableElement staticMethodElement = node.staticElement;
    DartType staticType = _computeStaticReturnType(staticMethodElement);
    staticType = _refineBinaryExpressionType(node, staticType, _getStaticType);
    _recordStaticType(node, staticType);
    MethodElement propagatedMethodElement = node.propagatedElement;
    if (!identical(propagatedMethodElement, staticMethodElement)) {
      DartType propagatedType =
          _computeStaticReturnType(propagatedMethodElement);
      propagatedType =
          _refineBinaryExpressionType(node, propagatedType, _getBestType);
      _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.4: <blockquote>The static type of a boolean literal is
   * bool.</blockquote>
   */
  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    _recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.15.2: <blockquote>A cascaded method invocation expression
   * of the form <i>e..suffix</i> is equivalent to the expression <i>(t) {t.suffix; return
   * t;}(e)</i>.</blockquote>
   */
  @override
  Object visitCascadeExpression(CascadeExpression node) {
    _recordStaticType(node, _getStaticType(node.target));
    _resolver.recordPropagatedTypeIfBetter(node, node.target.propagatedType);
    return null;
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
  Object visitConditionalExpression(ConditionalExpression node) {
    _analyzeLeastUpperBound(node, node.thenExpression, node.elseExpression);
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    if (_resolver.definingLibrary.context.analysisOptions.strongMode) {
      _inferForEachLoopVariableType(node);
    }
  }

  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of a literal double is
   * double.</blockquote>
   */
  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    _recordStaticType(node, _typeProvider.doubleType);
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression function = node.functionExpression;
    ExecutableElementImpl functionElement =
        node.element as ExecutableElementImpl;
    functionElement.returnType =
        _computeStaticReturnTypeOfFunctionDeclaration(node);
    if (node.parent is FunctionDeclarationStatement) {
      _recordPropagatedTypeOfFunction(functionElement, function.body);
    }
    _recordStaticType(function, functionElement.type);
    return null;
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
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // The function type will be resolved and set when we visit the parent
      // node.
      return null;
    }
    ExecutableElementImpl functionElement =
        node.element as ExecutableElementImpl;
    functionElement.returnType =
        _computeStaticReturnTypeOfFunctionExpression(node);
    _recordPropagatedTypeOfFunction(functionElement, node.body);
    _recordStaticType(node, node.element.type);
    return null;
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
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    DartType functionStaticType = _getStaticType(node.function);
    DartType staticType;
    if (functionStaticType is FunctionType) {
      staticType = functionStaticType.returnType;
    } else {
      staticType = _dynamicType;
    }
    _recordStaticType(node, staticType);
    DartType functionPropagatedType = node.function.propagatedType;
    if (functionPropagatedType is FunctionType) {
      DartType propagatedType = functionPropagatedType.returnType;
      _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.29: <blockquote>An assignable expression of the form
   * <i>e<sub>1</sub>[e<sub>2</sub>]</i> is evaluated as a method invocation of the operator method
   * <i>[]</i> on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.</blockquote>
   */
  @override
  Object visitIndexExpression(IndexExpression node) {
    if (node.inSetterContext()) {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeArgumentType(staticMethodElement);
      _recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (!identical(propagatedMethodElement, staticMethodElement)) {
        DartType propagatedType = _computeArgumentType(propagatedMethodElement);
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
      }
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      _recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (!identical(propagatedMethodElement, staticMethodElement)) {
        DartType propagatedType =
            _computeStaticReturnType(propagatedMethodElement);
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
      }
    }
    return null;
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
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    _recordStaticType(node, node.constructorName.type.type);
    ConstructorElement element = node.staticElement;
    if (element != null && "Element" == element.enclosingElement.name) {
      LibraryElement library = element.library;
      if (_isHtmlLibrary(library)) {
        String constructorName = element.name;
        if ("tag" == constructorName) {
          DartType returnType = _getFirstArgumentAsTypeWithMap(
              library, node.argumentList, _HTML_ELEMENT_TO_CLASS_MAP);
          _resolver.recordPropagatedTypeIfBetter(node, returnType);
        } else {
          DartType returnType = _getElementNameAsType(
              library, constructorName, _HTML_ELEMENT_TO_CLASS_MAP);
          _resolver.recordPropagatedTypeIfBetter(node, returnType);
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of an integer literal is
   * `int`.</blockquote>
   */
  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    _recordStaticType(node, _typeProvider.intType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
   * denote a type available in the current lexical scope.
   *
   * The static type of an is-expression is `bool`.</blockquote>
   */
  @override
  Object visitIsExpression(IsExpression node) {
    _recordStaticType(node, _typeProvider.boolType);
    return null;
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
  Object visitListLiteral(ListLiteral node) {
    DartType staticType = _dynamicType;
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 1) {
        TypeName argumentTypeName = arguments[0];
        DartType argumentType = _getType(argumentTypeName);
        if (argumentType != null) {
          staticType = argumentType;
        }
      }
    }
    _recordStaticType(
        node, _typeProvider.listType.substitute4(<DartType>[staticType]));
    return null;
  }

  /**
   * The Dart Language Specification, 12.7: <blockquote>The static type of a map literal of the form
   * <i><b>const</b> &lt;K, V&gt; {k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> or the form <i>&lt;K, V&gt; {k<sub>1</sub>:e<sub>1</sub>,
   * &hellip;, k<sub>n</sub>:e<sub>n</sub>}</i> is `Map&lt;K, V&gt;`. The static type a map
   * literal of the form <i><b>const</b> {k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> or the form <i>{k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> is `Map&lt;dynamic, dynamic&gt;`.
   *
   * It is a compile-time error if the first type argument to a map literal is not
   * <i>String</i>.</blockquote>
   */
  @override
  Object visitMapLiteral(MapLiteral node) {
    DartType staticKeyType = _dynamicType;
    DartType staticValueType = _dynamicType;
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 2) {
        TypeName entryKeyTypeName = arguments[0];
        DartType entryKeyType = _getType(entryKeyTypeName);
        if (entryKeyType != null) {
          staticKeyType = entryKeyType;
        }
        TypeName entryValueTypeName = arguments[1];
        DartType entryValueType = _getType(entryValueTypeName);
        if (entryValueType != null) {
          staticValueType = entryValueType;
        }
      }
    }
    _recordStaticType(
        node,
        _typeProvider.mapType
            .substitute4(<DartType>[staticKeyType, staticValueType]));
    return null;
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
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodNameNode = node.methodName;
    Element staticMethodElement = methodNameNode.staticElement;
    // Record types of the variable invoked as a function.
    if (staticMethodElement is VariableElement) {
      VariableElement variable = staticMethodElement;
      DartType staticType = variable.type;
      _recordStaticType(methodNameNode, staticType);
      DartType propagatedType = _overrideManager.getType(variable);
      _resolver.recordPropagatedTypeIfBetter(methodNameNode, propagatedType);
    }
    // Record static return type of the static element.
    DartType staticStaticType = _computeStaticReturnType(staticMethodElement);
    _recordStaticType(node, staticStaticType);
    // Record propagated return type of the static element.
    DartType staticPropagatedType =
        _computePropagatedReturnType(staticMethodElement);
    _resolver.recordPropagatedTypeIfBetter(node, staticPropagatedType);
    // Check for special cases.
    bool needPropagatedType = true;
    String methodName = methodNameNode.name;
    if (methodName == "then") {
      Expression target = node.realTarget;
      if (target != null) {
        DartType targetType = target.bestType;
        if (_isAsyncFutureType(targetType)) {
          // Future.then(closure) return type is:
          // 1) the returned Future type, if the closure returns a Future;
          // 2) Future<valueType>, if the closure returns a value.
          NodeList<Expression> arguments = node.argumentList.arguments;
          if (arguments.length == 1) {
            // TODO(brianwilkerson) Handle the case where both arguments are
            // provided.
            Expression closureArg = arguments[0];
            if (closureArg is FunctionExpression) {
              FunctionExpression closureExpr = closureArg;
              DartType returnType =
                  _computePropagatedReturnType(closureExpr.element);
              if (returnType != null) {
                // prepare the type of the returned Future
                InterfaceTypeImpl newFutureType;
                if (_isAsyncFutureType(returnType)) {
                  newFutureType = returnType as InterfaceTypeImpl;
                } else {
                  InterfaceType futureType = targetType as InterfaceType;
                  newFutureType = new InterfaceTypeImpl(futureType.element);
                  newFutureType.typeArguments = <DartType>[returnType];
                }
                // set the 'then' invocation type
                _recordPropagatedType(node, newFutureType);
                needPropagatedType = false;
                return null;
              }
            }
          }
        }
      }
    } else if (methodName == "\$dom_createEvent") {
      Expression target = node.realTarget;
      if (target != null) {
        DartType targetType = target.bestType;
        if (targetType is InterfaceType &&
            (targetType.name == "HtmlDocument" ||
                targetType.name == "Document")) {
          LibraryElement library = targetType.element.library;
          if (_isHtmlLibrary(library)) {
            DartType returnType =
                _getFirstArgumentAsType(library, node.argumentList);
            if (returnType != null) {
              _recordPropagatedType(node, returnType);
              needPropagatedType = false;
            }
          }
        }
      }
    } else if (methodName == "query") {
      Expression target = node.realTarget;
      if (target == null) {
        Element methodElement = methodNameNode.bestElement;
        if (methodElement != null) {
          LibraryElement library = methodElement.library;
          if (_isHtmlLibrary(library)) {
            DartType returnType =
                _getFirstArgumentAsQuery(library, node.argumentList);
            if (returnType != null) {
              _recordPropagatedType(node, returnType);
              needPropagatedType = false;
            }
          }
        }
      } else {
        DartType targetType = target.bestType;
        if (targetType is InterfaceType &&
            (targetType.name == "HtmlDocument" ||
                targetType.name == "Document")) {
          LibraryElement library = targetType.element.library;
          if (_isHtmlLibrary(library)) {
            DartType returnType =
                _getFirstArgumentAsQuery(library, node.argumentList);
            if (returnType != null) {
              _recordPropagatedType(node, returnType);
              needPropagatedType = false;
            }
          }
        }
      }
    } else if (methodName == "\$dom_createElement") {
      Expression target = node.realTarget;
      if (target != null) {
        DartType targetType = target.bestType;
        if (targetType is InterfaceType &&
            (targetType.name == "HtmlDocument" ||
                targetType.name == "Document")) {
          LibraryElement library = targetType.element.library;
          if (_isHtmlLibrary(library)) {
            DartType returnType =
                _getFirstArgumentAsQuery(library, node.argumentList);
            if (returnType != null) {
              _recordPropagatedType(node, returnType);
              needPropagatedType = false;
            }
          }
        }
      }
    } else if (methodName == "JS") {
      DartType returnType = _getFirstArgumentAsType(
          _typeProvider.objectType.element.library, node.argumentList);
      if (returnType != null) {
        _recordPropagatedType(node, returnType);
        needPropagatedType = false;
      }
    } else if (methodName == "getContext") {
      Expression target = node.realTarget;
      if (target != null) {
        DartType targetType = target.bestType;
        if (targetType is InterfaceType &&
            (targetType.name == "CanvasElement")) {
          NodeList<Expression> arguments = node.argumentList.arguments;
          if (arguments.length == 1) {
            Expression argument = arguments[0];
            if (argument is StringLiteral) {
              String value = argument.stringValue;
              if ("2d" == value) {
                PropertyAccessorElement getter =
                    targetType.element.getGetter("context2D");
                if (getter != null) {
                  DartType returnType = getter.returnType;
                  if (returnType != null) {
                    _recordPropagatedType(node, returnType);
                    needPropagatedType = false;
                  }
                }
              }
            }
          }
        }
      }
    }
    if (needPropagatedType) {
      Element propagatedElement = methodNameNode.propagatedElement;
      // HACK: special case for object methods ([toString]) on dynamic
      // expressions. More special cases in [visitPrefixedIdentfier].
      if (propagatedElement == null) {
        propagatedElement =
            _typeProvider.objectType.getMethod(methodNameNode.name);
      }
      if (!identical(propagatedElement, staticMethodElement)) {
        // Record static return type of the propagated element.
        DartType propagatedStaticType =
            _computeStaticReturnType(propagatedElement);
        _resolver.recordPropagatedTypeIfBetter(
            node, propagatedStaticType, true);
        // Record propagated return type of the propagated element.
        DartType propagatedPropagatedType =
            _computePropagatedReturnType(propagatedElement);
        _resolver.recordPropagatedTypeIfBetter(
            node, propagatedPropagatedType, true);
      }
    }
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, _getStaticType(expression));
    _resolver.recordPropagatedTypeIfBetter(node, expression.propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of `null` is bottom.
   * </blockquote>
   */
  @override
  Object visitNullLiteral(NullLiteral node) {
    _recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, _getStaticType(expression));
    _resolver.recordPropagatedTypeIfBetter(node, expression.propagatedType);
    return null;
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
  Object visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    DartType staticType = _getStaticType(operand);
    sc.TokenType operator = node.operator.type;
    if (operator == sc.TokenType.MINUS_MINUS ||
        operator == sc.TokenType.PLUS_PLUS) {
      DartType intType = _typeProvider.intType;
      if (identical(_getStaticType(node.operand), intType)) {
        staticType = intType;
      }
    }
    _recordStaticType(node, staticType);
    _resolver.recordPropagatedTypeIfBetter(node, operand.propagatedType);
    return null;
  }

  /**
   * See [visitSimpleIdentifier].
   */
  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element staticElement = prefixedIdentifier.staticElement;
    DartType staticType = _dynamicType;
    DartType propagatedType = null;
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
      staticType = _getTypeOfProperty(staticElement, node.prefix.staticType);
      propagatedType =
          _getPropertyPropagatedType(staticElement, propagatedType);
    } else if (staticElement is ExecutableElement) {
      staticType = staticElement.type;
    } else if (staticElement is TypeParameterElement) {
      staticType = staticElement.type;
    } else if (staticElement is VariableElement) {
      staticType = staticElement.type;
    }
    _recordStaticType(prefixedIdentifier, staticType);
    _recordStaticType(node, staticType);
    Element propagatedElement = prefixedIdentifier.propagatedElement;
    // HACK: special case for object getters ([hashCode] and [runtimeType]) on
    // dynamic expressions. More special cases in [visitMethodInvocation].
    if (propagatedElement == null) {
      propagatedElement =
          _typeProvider.objectType.getGetter(prefixedIdentifier.name);
    }
    if (propagatedElement is ClassElement) {
      if (_isNotTypeLiteral(node)) {
        propagatedType = propagatedElement.type;
      } else {
        propagatedType = _typeProvider.typeType;
      }
    } else if (propagatedElement is FunctionTypeAliasElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is MethodElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is PropertyAccessorElement) {
      propagatedType =
          _getTypeOfProperty(propagatedElement, node.prefix.staticType);
      propagatedType =
          _getPropertyPropagatedType(propagatedElement, propagatedType);
    } else if (propagatedElement is ExecutableElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is TypeParameterElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is VariableElement) {
      propagatedType = propagatedElement.type;
    }
    DartType overriddenType = _overrideManager.getType(propagatedElement);
    if (propagatedType == null ||
        (overriddenType != null &&
            overriddenType.isMoreSpecificThan(propagatedType))) {
      propagatedType = overriddenType;
    }
    _resolver.recordPropagatedTypeIfBetter(prefixedIdentifier, propagatedType);
    _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.27: <blockquote>A unary expression <i>u</i> of the form
   * <i>op e</i> is equivalent to a method invocation <i>expression e.op()</i>. An expression of the
   * form <i>op super</i> is equivalent to the method invocation <i>super.op()<i>.</blockquote>
   */
  @override
  Object visitPrefixExpression(PrefixExpression node) {
    sc.TokenType operator = node.operator.type;
    if (operator == sc.TokenType.BANG) {
      _recordStaticType(node, _typeProvider.boolType);
    } else {
      // The other cases are equivalent to invoking a method.
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      if (operator == sc.TokenType.MINUS_MINUS ||
          operator == sc.TokenType.PLUS_PLUS) {
        DartType intType = _typeProvider.intType;
        if (identical(_getStaticType(node.operand), intType)) {
          staticType = intType;
        }
      }
      _recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (!identical(propagatedMethodElement, staticMethodElement)) {
        DartType propagatedType =
            _computeStaticReturnType(propagatedMethodElement);
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
      }
    }
    return null;
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
  Object visitPropertyAccess(PropertyAccess node) {
    SimpleIdentifier propertyName = node.propertyName;
    Element staticElement = propertyName.staticElement;
    DartType staticType = _dynamicType;
    if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      Expression realTarget = node.realTarget;
      staticType = _getTypeOfProperty(staticElement,
          realTarget != null ? _getStaticType(realTarget) : null);
    } else {
      // TODO(brianwilkerson) Report this internal error.
    }
    _recordStaticType(propertyName, staticType);
    _recordStaticType(node, staticType);
    Element propagatedElement = propertyName.propagatedElement;
    DartType propagatedType = _overrideManager.getType(propagatedElement);
    if (propagatedElement is MethodElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is PropertyAccessorElement) {
      Expression realTarget = node.realTarget;
      propagatedType = _getTypeOfProperty(
          propagatedElement, realTarget != null ? realTarget.bestType : null);
    } else {
      // TODO(brianwilkerson) Report this internal error.
    }
    _resolver.recordPropagatedTypeIfBetter(propertyName, propagatedType);
    _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a rethrow expression is
   * bottom.</blockquote>
   */
  @override
  Object visitRethrowExpression(RethrowExpression node) {
    _recordStaticType(node, _typeProvider.bottomType);
    return null;
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
  Object visitSimpleIdentifier(SimpleIdentifier node) {
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
      staticType = _getTypeOfProperty(element, null);
    } else if (element is ExecutableElement) {
      staticType = element.type;
    } else if (element is TypeParameterElement) {
      staticType = _typeProvider.typeType;
    } else if (element is VariableElement) {
      VariableElement variable = element;
      staticType = _promoteManager.getStaticType(variable);
    } else if (element is PrefixElement) {
      return null;
    } else if (element is DynamicElementImpl) {
      staticType = _typeProvider.typeType;
    } else {
      staticType = _dynamicType;
    }
    _recordStaticType(node, staticType);
    // TODO(brianwilkerson) I think we want to repeat the logic above using the
    // propagated element to get another candidate for the propagated type.
    DartType propagatedType = _getPropertyPropagatedType(element, null);
    if (propagatedType == null) {
      DartType overriddenType = _overrideManager.getType(element);
      if (propagatedType == null ||
          overriddenType != null &&
              overriddenType.isMoreSpecificThan(propagatedType)) {
        propagatedType = overriddenType;
      }
    }
    _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    _recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  @override
  Object visitStringInterpolation(StringInterpolation node) {
    _recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    if (thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported.
      _recordStaticType(node, _dynamicType);
    } else {
      _recordStaticType(node, thisType);
    }
    return null;
  }

  @override
  Object visitSymbolLiteral(SymbolLiteral node) {
    _recordStaticType(node, _typeProvider.symbolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.10: <blockquote>The static type of `this` is the
   * interface of the immediately enclosing class.</blockquote>
   */
  @override
  Object visitThisExpression(ThisExpression node) {
    if (thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported.
      _recordStaticType(node, _dynamicType);
    } else {
      _recordStaticType(node, thisType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.8: <blockquote>The static type of a throw expression is
   * bottom.</blockquote>
   */
  @override
  Object visitThrowExpression(ThrowExpression node) {
    _recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    Expression initializer = node.initializer;
    if (_resolver.definingLibrary.context.analysisOptions.strongMode) {
      _inferLocalVariableType(node, initializer);
    }
    if (initializer != null) {
      DartType rightType = initializer.bestType;
      SimpleIdentifier name = node.name;
      _resolver.recordPropagatedTypeIfBetter(name, rightType);
      VariableElement element = name.staticElement as VariableElement;
      if (element != null) {
        _resolver.overrideVariable(element, rightType, true);
      }
    }
    return null;
  }

  /**
   * Set the static (propagated) type of [node] to be the least upper bound
   * of the static (propagated) types of subexpressions [expr1] and [expr2].
   */
  void _analyzeLeastUpperBound(
      Expression node, Expression expr1, Expression expr2) {
    DartType staticType1 = _getStaticType(expr1);
    DartType staticType2 = _getStaticType(expr2);
    if (staticType1 == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticType1 = _dynamicType;
    }
    if (staticType2 == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticType2 = _dynamicType;
    }
    DartType staticType =
        _typeSystem.getLeastUpperBound(staticType1, staticType2);
    if (staticType == null) {
      staticType = _dynamicType;
    }
    _recordStaticType(node, staticType);
    DartType propagatedType1 = expr1.propagatedType;
    DartType propagatedType2 = expr2.propagatedType;
    if (propagatedType1 != null || propagatedType2 != null) {
      if (propagatedType1 == null) {
        propagatedType1 = staticType1;
      }
      if (propagatedType2 == null) {
        propagatedType2 = staticType2;
      }
      DartType propagatedType =
          _typeSystem.getLeastUpperBound(propagatedType1, propagatedType2);
      _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
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

  /**
   * Compute the propagated return type of the method or function represented by the given element.
   *
   * @param element the element representing the method or function invoked by the given node
   * @return the propagated return type that was computed
   */
  DartType _computePropagatedReturnType(Element element) {
    if (element is ExecutableElement) {
      return _propagatedReturnTypes[element];
    }
    return null;
  }

  /**
   * Given a function body, compute the propagated return type of the function. The propagated
   * return type of functions with a block body is the least upper bound of all
   * [ReturnStatement] expressions, with an expression body it is the type of the expression.
   *
   * @param body the boy of the function whose propagated return type is to be computed
   * @return the propagated return type that was computed
   */
  DartType _computePropagatedReturnTypeOfFunction(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      ExpressionFunctionBody expressionBody = body;
      return expressionBody.expression.bestType;
    }
    if (body is BlockFunctionBody) {
      _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction visitor =
          new _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction(
              _typeSystem);
      body.accept(visitor);
      return visitor.result;
    }
    return null;
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
        DartType returnType = propertyType.returnType;
        if (returnType.isDartCoreFunction) {
          return _dynamicType;
        } else if (returnType is InterfaceType) {
          MethodElement callMethod = returnType.lookUpMethod(
              FunctionElement.CALL_METHOD_NAME, _resolver.definingLibrary);
          if (callMethod != null) {
            return callMethod.type.returnType;
          }
        } else if (returnType is FunctionType) {
          DartType innerReturnType = returnType.returnType;
          if (innerReturnType != null) {
            return innerReturnType;
          }
        }
        if (returnType != null) {
          return returnType;
        }
      }
    } else if (element is ExecutableElement) {
      FunctionType type = element.type;
      if (type != null) {
        // TODO(brianwilkerson) Figure out the conditions under which the type
        // is null.
        return type.returnType;
      }
    } else if (element is VariableElement) {
      VariableElement variable = element;
      DartType variableType = _promoteManager.getStaticType(variable);
      if (variableType is FunctionType) {
        return variableType.returnType;
      }
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
    TypeName returnType = node.returnType;
    if (returnType == null) {
      return _dynamicType;
    }
    return returnType.type;
  }

  /**
   * Given a function expression, compute the return type of the function. The return type of
   * functions with a block body is `dynamicType`, with an expression body it is the type of
   * the expression.
   *
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  DartType _computeStaticReturnTypeOfFunctionExpression(
      FunctionExpression node) {
    FunctionBody body = node.body;
    if (body.isGenerator) {
      if (body.isAsynchronous) {
        return _typeProvider.streamDynamicType;
      } else {
        return _typeProvider.iterableDynamicType;
      }
    }
    DartType type;
    if (body is ExpressionFunctionBody) {
      type = _getStaticType(body.expression);
    } else {
      type = _dynamicType;
    }
    if (body.isAsynchronous) {
      return _typeProvider.futureType
          .substitute4(<DartType>[flattenFutures(_typeProvider, type)]);
    } else {
      return type;
    }
  }

  // TODO(vsm): Use leafp's matchType here?
  DartType _findIteratedType(InterfaceType type, DartType targetType) {
    // Set by _find if match is found
    DartType result = null;
    // Elements we've already visited on a given inheritance path.
    HashSet<ClassElement> visitedClasses = null;

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
    _find(type);
    return result;
  }

  /**
   * Return the best type of the given [expression].
   */
  DartType _getBestType(Expression expression) {
    return expression.bestType;
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
  DartType _getElementNameAsType(LibraryElement library, String elementName,
      HashMap<String, String> nameMap) {
    if (elementName != null) {
      if (nameMap != null) {
        elementName = nameMap[elementName.toLowerCase()];
      }
      ClassElement returnType = library.getType(elementName);
      if (returnType != null) {
        return returnType.type;
      }
    }
    return null;
  }

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, then parse that argument as a query string and return the type specified by the
   * argument.
   *
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  DartType _getFirstArgumentAsQuery(
      LibraryElement library, ArgumentList argumentList) {
    String argumentValue = _getFirstArgumentAsString(argumentList);
    if (argumentValue != null) {
      //
      // If the query has spaces, full parsing is required because it might be:
      //   E[text='warning text']
      //
      if (StringUtilities.indexOf1(argumentValue, 0, 0x20) >= 0) {
        return null;
      }
      //
      // Otherwise, try to extract the tag based on
      // http://www.w3.org/TR/CSS2/selector.html.
      //
      String tag = argumentValue;
      tag = StringUtilities.substringBeforeChar(tag, 0x3A);
      tag = StringUtilities.substringBeforeChar(tag, 0x5B);
      tag = StringUtilities.substringBeforeChar(tag, 0x2E);
      tag = StringUtilities.substringBeforeChar(tag, 0x23);
      tag = _HTML_ELEMENT_TO_CLASS_MAP[tag.toLowerCase()];
      ClassElement returnType = library.getType(tag);
      if (returnType != null) {
        return returnType.type;
      }
    }
    return null;
  }

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
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, and if the value of the argument is the name of a class defined within the
   * given library, return the type specified by the argument.
   *
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  DartType _getFirstArgumentAsType(
          LibraryElement library, ArgumentList argumentList) =>
      _getFirstArgumentAsTypeWithMap(library, argumentList, null);

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, and if the value of the argument is the name of a class defined within the
   * given library, return the type specified by the argument.
   *
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @param nameMap an optional map used to map the element name to a type name
   * @return the type specified by the first argument in the argument list
   */
  DartType _getFirstArgumentAsTypeWithMap(LibraryElement library,
          ArgumentList argumentList, HashMap<String, String> nameMap) =>
      _getElementNameAsType(
          library, _getFirstArgumentAsString(argumentList), nameMap);

  /**
   * Return the propagated type of the given [Element], or `null`.
   */
  DartType _getPropertyPropagatedType(Element element, DartType currentType) {
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element;
      if (accessor.isGetter) {
        PropertyInducingElement variable = accessor.variable;
        DartType propagatedType = variable.propagatedType;
        if (currentType == null ||
            propagatedType != null &&
                propagatedType.isMoreSpecificThan(currentType)) {
          return propagatedType;
        }
      }
    }
    return currentType;
  }

  /**
   * Return the static type of the given [expression].
   */
  DartType _getStaticType(Expression expression) {
    DartType type = expression.staticType;
    if (type == null) {
      // TODO(brianwilkerson) Determine the conditions for which the static type
      // is null.
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type represented by the given type name.
   *
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  DartType _getType(TypeName typeName) {
    DartType type = typeName.type;
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
   * @param context if the accessor element has context [by being the RHS of a
   *          [PrefixedIdentifier] or [PropertyAccess]], and the return type of the
   *          accessor is a parameter type, then the type of the LHS can be used to get more
   *          specific type information
   * @return the type that should be recorded for a node that resolved to the given accessor
   */
  DartType _getTypeOfProperty(
      PropertyAccessorElement accessor, DartType context) {
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
    DartType returnType = functionType.returnType;
    if (returnType is TypeParameterType && context is InterfaceType) {
      // if the return type is a TypeParameter, we try to use the context [that
      // the function is being called on] to get a more accurate returnType type
      InterfaceType interfaceTypeContext = context;
      //      Type[] argumentTypes = interfaceTypeContext.getTypeArguments();
      List<TypeParameterElement> typeParameterElements =
          interfaceTypeContext.element != null
              ? interfaceTypeContext.element.typeParameters
              : null;
      if (typeParameterElements != null) {
        for (int i = 0; i < typeParameterElements.length; i++) {
          TypeParameterElement typeParameterElement = typeParameterElements[i];
          if (returnType.name == typeParameterElement.name) {
            return interfaceTypeContext.typeArguments[i];
          }
        }
        // TODO(jwren) troubleshoot why call to substitute doesn't work
//        Type[] parameterTypes = TypeParameterTypeImpl.getTypes(parameterElements);
//        return returnType.substitute(argumentTypes, parameterTypes);
      }
    }
    return returnType;
  }

  void _inferForEachLoopVariableType(DeclaredIdentifier loopVariable) {
    if (loopVariable != null &&
        loopVariable.type == null &&
        loopVariable.parent is ForEachStatement) {
      ForEachStatement loop = loopVariable.parent;
      if (loop.iterable != null) {
        Expression expr = loop.iterable;
        LocalVariableElementImpl element = loopVariable.element;
        DartType exprType = expr.staticType;
        if (exprType is InterfaceType) {
          DartType targetType = (loop.awaitKeyword == null)
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
  }

  void _inferLocalVariableType(
      VariableDeclaration node, Expression initializer) {
    if (initializer != null &&
        (node.parent as VariableDeclarationList).type == null &&
        (node.element is LocalVariableElementImpl) &&
        (initializer.staticType != null) &&
        (!initializer.staticType.isBottom)) {
      LocalVariableElementImpl element = node.element;
      element.type = initializer.staticType;
      node.name.staticType = initializer.staticType;
    }
  }

  /**
   * Return `true` if the given [Type] is the `Future` form the 'dart:async'
   * library.
   */
  bool _isAsyncFutureType(DartType type) => type is InterfaceType &&
      type.name == "Future" &&
      _isAsyncLibrary(type.element.library);

  /**
   * Return `true` if the given library is the 'dart:async' library.
   *
   * @param library the library being tested
   * @return `true` if the library is 'dart:async'
   */
  bool _isAsyncLibrary(LibraryElement library) => library.name == "dart.async";

  /**
   * Return `true` if the given library is the 'dart:html' library.
   *
   * @param library the library being tested
   * @return `true` if the library is 'dart:html'
   */
  bool _isHtmlLibrary(LibraryElement library) =>
      library != null && "dart.dom.html" == library.name;

  /**
   * Return `true` if the given node is not a type literal.
   *
   * @param node the node being tested
   * @return `true` if the given node is not a type literal
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
   * Record that the propagated type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the propagated type of the node
   */
  void _recordPropagatedType(Expression expression, DartType type) {
    if (type != null && !type.isDynamic && !type.isBottom) {
      expression.propagatedType = type;
    }
  }

  /**
   * Given a function element and its body, compute and record the propagated return type of the
   * function.
   *
   * @param functionElement the function element to record propagated return type for
   * @param body the boy of the function whose propagated return type is to be computed
   * @return the propagated return type that was computed, may be `null` if it is not more
   *         specific than the static return type.
   */
  void _recordPropagatedTypeOfFunction(
      ExecutableElement functionElement, FunctionBody body) {
    DartType propagatedReturnType =
        _computePropagatedReturnTypeOfFunction(body);
    if (propagatedReturnType == null) {
      return;
    }
    // Ignore 'bottom' type.
    if (propagatedReturnType.isBottom) {
      return;
    }
    // Record only if we inferred more specific type.
    DartType staticReturnType = functionElement.returnType;
    if (!propagatedReturnType.isMoreSpecificThan(staticReturnType)) {
      return;
    }
    // OK, do record.
    _propagatedReturnTypes[functionElement] = propagatedReturnType;
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

  /**
   * Attempts to make a better guess for the type of the given binary
   * [expression], given that resolution has so far produced the [currentType].
   * The [typeAccessor] is used to access the corresponding type of the left
   * and right operands.
   */
  DartType _refineBinaryExpressionType(
      BinaryExpression expression, DartType currentType,
      [DartType typeAccessor(Expression node)]) {
    sc.TokenType operator = expression.operator.type;
    // bool
    if (operator == sc.TokenType.AMPERSAND_AMPERSAND ||
        operator == sc.TokenType.BAR_BAR ||
        operator == sc.TokenType.EQ_EQ ||
        operator == sc.TokenType.BANG_EQ) {
      return _typeProvider.boolType;
    }
    DartType intType = _typeProvider.intType;
    if (typeAccessor(expression.leftOperand) == intType) {
      // int op double
      if (operator == sc.TokenType.MINUS ||
          operator == sc.TokenType.PERCENT ||
          operator == sc.TokenType.PLUS ||
          operator == sc.TokenType.STAR) {
        DartType doubleType = _typeProvider.doubleType;
        if (typeAccessor(expression.rightOperand) == doubleType) {
          return doubleType;
        }
      }
      // int op int
      if (operator == sc.TokenType.MINUS ||
          operator == sc.TokenType.PERCENT ||
          operator == sc.TokenType.PLUS ||
          operator == sc.TokenType.STAR ||
          operator == sc.TokenType.TILDE_SLASH) {
        if (typeAccessor(expression.rightOperand) == intType) {
          return intType;
        }
      }
    }
    // default
    return currentType;
  }

  /**
   * Implements the function "flatten" defined in the spec:
   *
   *   If T = Future<S> then flatten(T) = flatten(S).
   *
   *   Otherwise if T <: Future then let S be a type such that T << Future<S>
   *   and for all R, if T << Future<R> then S << R.  Then flatten(T) = S.
   *
   *   In any other circumstance, flatten(T) = T.
   */
  static DartType flattenFutures(TypeProvider typeProvider, DartType type) {
    if (type is InterfaceType) {
      // Implement the case: "If T = Future<S> then flatten(T) = flatten(S)."
      if (type.element == typeProvider.futureType.element &&
          type.typeArguments.length > 0) {
        return flattenFutures(typeProvider, type.typeArguments[0]);
      }

      // Implement the case: "Otherwise if T <: Future then let S be a type
      // such that T << Future<S> and for all R, if T << Future<R> then S << R.
      // Then flatten(T) = S."
      //
      // In other words, given the set of all types R such that T << Future<R>,
      // let S be the most specific of those types, if any such S exists.
      //
      // Since we only care about the most specific type, it is sufficent to
      // look at the types appearing as a parameter to Future in the type
      // hierarchy of T.  We don't need to consider the supertypes of those
      // types, since they are by definition less specific.
      List<DartType> candidateTypes =
          _searchTypeHierarchyForFutureParameters(typeProvider, type);
      DartType flattenResult = _findMostSpecificType(candidateTypes);
      if (flattenResult != null) {
        return flattenResult;
      }
    }

    // Implement the case: "In any other circumstance, flatten(T) = T."
    return type;
  }

  /**
   * Create a table mapping HTML tag names to the names of the classes (in 'dart:html') that
   * implement those tags.
   *
   * @return the table that was created
   */
  static HashMap<String, String> _createHtmlTagToClassMap() {
    HashMap<String, String> map = new HashMap<String, String>();
    map["a"] = "AnchorElement";
    map["area"] = "AreaElement";
    map["br"] = "BRElement";
    map["base"] = "BaseElement";
    map["body"] = "BodyElement";
    map["button"] = "ButtonElement";
    map["canvas"] = "CanvasElement";
    map["content"] = "ContentElement";
    map["dl"] = "DListElement";
    map["datalist"] = "DataListElement";
    map["details"] = "DetailsElement";
    map["div"] = "DivElement";
    map["embed"] = "EmbedElement";
    map["fieldset"] = "FieldSetElement";
    map["form"] = "FormElement";
    map["hr"] = "HRElement";
    map["head"] = "HeadElement";
    map["h1"] = "HeadingElement";
    map["h2"] = "HeadingElement";
    map["h3"] = "HeadingElement";
    map["h4"] = "HeadingElement";
    map["h5"] = "HeadingElement";
    map["h6"] = "HeadingElement";
    map["html"] = "HtmlElement";
    map["iframe"] = "IFrameElement";
    map["img"] = "ImageElement";
    map["input"] = "InputElement";
    map["keygen"] = "KeygenElement";
    map["li"] = "LIElement";
    map["label"] = "LabelElement";
    map["legend"] = "LegendElement";
    map["link"] = "LinkElement";
    map["map"] = "MapElement";
    map["menu"] = "MenuElement";
    map["meter"] = "MeterElement";
    map["ol"] = "OListElement";
    map["object"] = "ObjectElement";
    map["optgroup"] = "OptGroupElement";
    map["output"] = "OutputElement";
    map["p"] = "ParagraphElement";
    map["param"] = "ParamElement";
    map["pre"] = "PreElement";
    map["progress"] = "ProgressElement";
    map["script"] = "ScriptElement";
    map["select"] = "SelectElement";
    map["source"] = "SourceElement";
    map["span"] = "SpanElement";
    map["style"] = "StyleElement";
    map["caption"] = "TableCaptionElement";
    map["td"] = "TableCellElement";
    map["col"] = "TableColElement";
    map["table"] = "TableElement";
    map["tr"] = "TableRowElement";
    map["textarea"] = "TextAreaElement";
    map["title"] = "TitleElement";
    map["track"] = "TrackElement";
    map["ul"] = "UListElement";
    map["video"] = "VideoElement";
    return map;
  }

  /**
   * If there is a single type which is at least as specific as all of the
   * types in [types], return it.  Otherwise return `null`.
   */
  static DartType _findMostSpecificType(List<DartType> types) {
    // The << relation ("more specific than") is a partial ordering on types,
    // so to find the most specific type of a set, we keep a bucket of the most
    // specific types seen so far such that no type in the bucket is more
    // specific than any other type in the bucket.
    List<DartType> bucket = <DartType>[];

    // Then we consider each type in turn.
    for (DartType type in types) {
      // If any existing type in the bucket is more specific than this type,
      // then we can ignore this type.
      if (bucket.any((DartType t) => t.isMoreSpecificThan(type))) {
        continue;
      }
      // Otherwise, we need to add this type to the bucket and remove any types
      // that are less specific than it.
      bool added = false;
      int i = 0;
      while (i < bucket.length) {
        if (type.isMoreSpecificThan(bucket[i])) {
          if (added) {
            if (i < bucket.length - 1) {
              bucket[i] = bucket.removeLast();
            } else {
              bucket.removeLast();
            }
          } else {
            bucket[i] = type;
            i++;
            added = true;
          }
        } else {
          i++;
        }
      }
      if (!added) {
        bucket.add(type);
      }
    }

    // Now that we are finished, if there is exactly one type left in the
    // bucket, it is the most specific type.
    if (bucket.length == 1) {
      return bucket[0];
    }

    // Otherwise, there is no single type that is more specific than the
    // others.
    return null;
  }

  /**
   * Given a seed type [type], search its class hierarchy for types of the form
   * Future<R>, and return a list of the resulting R's.
   */
  static List<DartType> _searchTypeHierarchyForFutureParameters(
      TypeProvider typeProvider, InterfaceType type) {
    List<DartType> result = <DartType>[];
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    void recurse(InterfaceType type) {
      if (type.element == typeProvider.futureType.element &&
          type.typeArguments.length > 0) {
        result.add(type.typeArguments[0]);
      }
      if (visitedClasses.add(type.element)) {
        if (type.superclass != null) {
          recurse(type.superclass);
        }
        for (InterfaceType interface in type.interfaces) {
          recurse(interface);
        }
        visitedClasses.remove(type.element);
      }
    }
    recurse(type);
    return result;
  }
}

class _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction
    extends GeneralizingAstVisitor<Object> {
  final TypeSystem typeSystem;
  DartType result = null;

  _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction(this.typeSystem);

  @override
  Object visitExpression(Expression node) => null;

  @override
  Object visitReturnStatement(ReturnStatement node) {
    // prepare this 'return' type
    DartType type;
    Expression expression = node.expression;
    if (expression != null) {
      type = expression.bestType;
    } else {
      type = BottomTypeImpl.instance;
    }
    // merge types
    if (result == null) {
      result = type;
    } else {
      result = typeSystem.getLeastUpperBound(result, type);
    }
    return null;
  }
}
