// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.static_type_analyzer;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show ConstructorMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/java_engine.dart';
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
   * Are we running in strong mode or not.
   */
  bool _strongMode;

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
  Map<ExecutableElement, DartType> _propagatedReturnTypes =
      new HashMap<ExecutableElement, DartType>();

  /// Indicates whether type propagation should be performed.
  final bool propagateTypes;

  /**
   * Initialize a newly created type analyzer.
   *
   * @param resolver the resolver driving this participant
   */
  StaticTypeAnalyzer(this._resolver, {this.propagateTypes: true}) {
    _typeProvider = _resolver.typeProvider;
    _typeSystem = _resolver.typeSystem;
    _dynamicType = _typeProvider.dynamicType;
    _overrideManager = _resolver.overrideManager;
    _promoteManager = _resolver.promoteManager;
    _strongMode = _resolver.strongMode;
  }

  /**
   * Given a constructor name [node] and a type [type], record an inferred type
   * for the constructor if in strong mode. This is used to fill in any
   * inferred type parameters found by the resolver.
   */
  void inferConstructorName(ConstructorName node, InterfaceType type) {
    if (_strongMode) {
      node.type.type = type;
      if (type != _typeSystem.instantiateToBounds(type.element.type)) {
        _resolver.inferenceContext.recordInference(node.parent, type);
      }
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
    if (_strongMode && node != null && functionType is FunctionType) {
      var ts = _typeSystem as StrongTypeSystemImpl;
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
            parameters.where((p) => !p.isNamed).iterator;
        Iterator<ParameterElement> fnPositional =
            functionType.parameters.where((p) => !p.isNamed).iterator;
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

    var ts = _typeSystem as StrongTypeSystemImpl;
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
          .map((e) => e.staticType)
          .where((t) => t != null)
          .toList();
      var listTypeParam = _typeProvider.listType.typeParameters[0].type;
      var syntheticParamElement = new ParameterElementImpl.synthetic(
          'element', listTypeParam, ParameterKind.POSITIONAL);
      parameters = new List.filled(elementTypes.length, syntheticParamElement);
    }
    DartType inferred = ts.inferGenericFunctionOrType<InterfaceType>(
        _typeProvider.listType, parameters, elementTypes, contextType,
        downwards: downwards,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
    return inferred;
  }

  ParameterizedType inferMapType(MapLiteral node, {bool downwards: false}) {
    DartType contextType = InferenceContext.getContext(node);
    List<DartType> elementTypes;
    List<ParameterElement> parameters;
    if (downwards) {
      if (contextType == null) {
        return null;
      }
      elementTypes = [];
      parameters = [];
    } else {
      var keyTypes =
          node.entries.map((e) => e.key.staticType).where((t) => t != null);
      var valueTypes =
          node.entries.map((e) => e.value.staticType).where((t) => t != null);
      var keyTypeParam = _typeProvider.mapType.typeParameters[0].type;
      var valueTypeParam = _typeProvider.mapType.typeParameters[1].type;
      var syntheticKeyParameter = new ParameterElementImpl.synthetic(
          'key', keyTypeParam, ParameterKind.POSITIONAL);
      var syntheticValueParameter = new ParameterElementImpl.synthetic(
          'value', valueTypeParam, ParameterKind.POSITIONAL);
      parameters = new List.filled(keyTypes.length, syntheticKeyParameter,
          growable: true)
        ..addAll(new List.filled(valueTypes.length, syntheticValueParameter));
      elementTypes = new List<DartType>.from(keyTypes)..addAll(valueTypes);
    }

    // Use both downwards and upwards information to infer the type.
    var ts = _typeSystem as StrongTypeSystemImpl;
    ParameterizedType inferred = ts.inferGenericFunctionOrType(
        _typeProvider.mapType, parameters, elementTypes, contextType,
        downwards: downwards,
        errorReporter: _resolver.errorReporter,
        errorNode: node);
    return inferred;
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
    TokenType operator = node.operator.type;
    if (operator == TokenType.EQ) {
      Expression rightHandSide = node.rightHandSide;
      DartType staticType = _getStaticType(rightHandSide);
      _recordStaticType(node, staticType);
      DartType overrideType = staticType;
      if (propagateTypes) {
        DartType propagatedType = rightHandSide.propagatedType;
        if (propagatedType != null) {
          _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
          overrideType = propagatedType;
        }
      }
      _resolver.overrideExpression(node.leftHandSide, overrideType, true, true);
    } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
      // The static type of a compound assignment using ??= is the least upper
      // bound of the static types of the LHS and RHS.
      _analyzeLeastUpperBound(node, node.leftHandSide, node.rightHandSide,
          read: true);
      return null;
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
      if (propagateTypes) {
        MethodElement propagatedMethodElement = node.propagatedElement;
        if (!identical(propagatedMethodElement, staticMethodElement)) {
          DartType propagatedType =
              _computeStaticReturnType(propagatedMethodElement);
          propagatedType = _typeSystem.refineBinaryExpressionType(
              node.leftHandSide.propagatedType,
              operator,
              node.rightHandSide.propagatedType,
              propagatedType);
          _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
        }
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
    // Await the Future. This results in whatever type is (ultimately) returned.
    DartType awaitType(DartType awaitedType) {
      if (awaitedType == null) {
        return null;
      }
      if (awaitedType.isDartAsyncFutureOr) {
        return awaitType((awaitedType as InterfaceType).typeArguments[0]);
      }
      return awaitedType.flattenFutures(_typeSystem);
    }

    _recordStaticType(node, awaitType(_getStaticType(node.expression)));
    if (propagateTypes) {
      DartType propagatedType = awaitType(node.expression.propagatedType);
      _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    }
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
      // Evaluation of an if-null expression e of the form e1 ?? e2 is
      // equivalent to the evaluation of the expression
      // ((x) => x == null ? e2 : x)(e1).  The static type of e is the least
      // upper bound of the static type of e1 and the static type of e2.
      _analyzeLeastUpperBound(node, node.leftOperand, node.rightOperand);
      return null;
    }
    ExecutableElement staticMethodElement = node.staticElement;
    DartType staticType = _computeStaticReturnType(staticMethodElement);
    staticType = _typeSystem.refineBinaryExpressionType(
        node.leftOperand.staticType,
        node.operator.type,
        node.rightOperand.staticType,
        staticType);
    _recordStaticType(node, staticType);
    if (propagateTypes) {
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (!identical(propagatedMethodElement, staticMethodElement)) {
        DartType propagatedType =
            _computeStaticReturnType(propagatedMethodElement);
        propagatedType = _typeSystem.refineBinaryExpressionType(
            node.leftOperand.bestType,
            node.operator.type,
            node.rightOperand.bestType,
            propagatedType);
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
      }
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
    if (propagateTypes) {
      _resolver.recordPropagatedTypeIfBetter(node, node.target.propagatedType);
    }
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
    if (_strongMode) {
      _inferForEachLoopVariableType(node);
    }
    return null;
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
    if (node.parent is FunctionDeclarationStatement) {
      // TypeResolverVisitor sets the return type for top-level functions, so
      // we only need to handle local functions.
      if (_strongMode && node.returnType == null) {
        _inferLocalFunctionReturnType(node.functionExpression);
        return null;
      }
      functionElement.returnType =
          _computeStaticReturnTypeOfFunctionDeclaration(node);
      if (propagateTypes) {
        _recordPropagatedTypeOfFunction(functionElement, function.body);
      }
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
    _inferLocalFunctionReturnType(node);
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
    if (_strongMode) {
      _inferGenericInvocationExpression(node);
    }
    DartType staticType = _computeInvokeReturnType(node.staticInvokeType);
    _recordStaticType(node, staticType);
    if (propagateTypes) {
      DartType functionPropagatedType = node.propagatedInvokeType;
      if (functionPropagatedType is FunctionType) {
        DartType propagatedType = functionPropagatedType.returnType;
        _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
      }
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
      if (propagateTypes) {
        MethodElement propagatedMethodElement = node.propagatedElement;
        if (!identical(propagatedMethodElement, staticMethodElement)) {
          DartType propagatedType =
              _computeArgumentType(propagatedMethodElement);
          _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
        }
      }
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      _recordStaticType(node, staticType);
      if (propagateTypes) {
        MethodElement propagatedMethodElement = node.propagatedElement;
        if (!identical(propagatedMethodElement, staticMethodElement)) {
          DartType propagatedType =
              _computeStaticReturnType(propagatedMethodElement);
          _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
        }
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
    if (_strongMode) {
      _inferInstanceCreationExpression(node);
    }

    _recordStaticType(node, node.constructorName.type.type);
    if (propagateTypes) {
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
      return null;
    }

    DartType listDynamicType =
        _typeProvider.listType.instantiate(<DartType>[_dynamicType]);

    // If there are no type arguments and we are in strong mode, try to infer
    // some arguments.
    if (_strongMode) {
      DartType inferred = inferListType(node);

      if (inferred != listDynamicType) {
        // TODO(jmesserly): this results in an "inferred" message even when we
        // in fact had an error above, because it will still attempt to return
        // a type. Perhaps we should record inference from TypeSystem if
        // everything was successful?
        _resolver.inferenceContext.recordInference(node, inferred);
        _recordStaticType(node, inferred);
        return null;
      }
    }

    // If we have no type arguments and couldn't infer any, use dynamic.
    _recordStaticType(node, listDynamicType);
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
    TypeArgumentList typeArguments = node.typeArguments;

    DartType mapDynamicType = _typeProvider.mapType
        .instantiate(<DartType>[_dynamicType, _dynamicType]);

    // If we have type arguments, use them
    if (typeArguments != null) {
      DartType staticKeyType = _dynamicType;
      DartType staticValueType = _dynamicType;
      NodeList<TypeAnnotation> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 2) {
        DartType entryKeyType = _getType(arguments[0]);
        if (entryKeyType != null) {
          staticKeyType = entryKeyType;
        }
        DartType entryValueType = _getType(arguments[1]);
        if (entryValueType != null) {
          staticValueType = entryValueType;
        }
      }
      _recordStaticType(
          node,
          _typeProvider.mapType
              .instantiate(<DartType>[staticKeyType, staticValueType]));
      return null;
    }

    // If we have no explicit type arguments, and we are in strong mode
    // then try to infer type arguments.
    if (_strongMode) {
      ParameterizedType inferred = inferMapType(node);

      if (inferred != mapDynamicType) {
        // TODO(jmesserly): this results in an "inferred" message even when we
        // in fact had an error above, because it will still attempt to return
        // a type. Perhaps we should record inference from TypeSystem if
        // everything was successful?
        _resolver.inferenceContext.recordInference(node, inferred);
        _recordStaticType(node, inferred);
        return null;
      }
    }

    // If no type arguments and no inference, use dynamic
    _recordStaticType(node, mapDynamicType);
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
    if (_strongMode) {
      _inferGenericInvocationExpression(node);
    }
    // Record types of the variable invoked as a function.
    if (propagateTypes && staticMethodElement is VariableElement) {
      DartType propagatedType = _overrideManager.getType(staticMethodElement);
      _resolver.recordPropagatedTypeIfBetter(methodNameNode, propagatedType);
    }
    // Record static return type of the static element.
    bool inferredStaticType = _strongMode &&
        (_inferMethodInvocationObject(node) ||
            _inferMethodInvocationInlineJS(node));

    if (!inferredStaticType) {
      DartType staticStaticType =
          _computeInvokeReturnType(node.staticInvokeType);
      _recordStaticType(node, staticStaticType);
    }

    if (propagateTypes) {
      // Record propagated return type of the static element.
      DartType staticPropagatedType =
          _computePropagatedReturnType(staticMethodElement);
      _resolver.recordPropagatedTypeIfBetter(node, staticPropagatedType);
      // Check for special cases.
      bool needPropagatedType = true;
      String methodName = methodNameNode.name;
      if (!_strongMode && methodName == "then") {
        Expression target = node.realTarget;
        if (target != null) {
          DartType targetType = target.bestType;
          if (targetType.isDartAsyncFuture) {
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
                  InterfaceType newFutureType = _typeProvider.futureType
                      .instantiate([returnType.flattenFutures(_typeSystem)]);
                  // set the 'then' invocation type
                  _resolver.recordPropagatedTypeIfBetter(node, newFutureType);
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
        DartType propagatedInvokeType = node.propagatedInvokeType;
        // HACK: special case for object methods ([toString]) on dynamic
        // expressions. More special cases in [visitPrefixedIdentfier].
        if (propagatedElement == null) {
          MethodElement objMethod =
              _typeProvider.objectType.getMethod(methodNameNode.name);
          if (objMethod != null) {
            propagatedElement = objMethod;
            propagatedInvokeType = objMethod.type;
          }
        }
        if (!identical(propagatedElement, staticMethodElement)) {
          // Record static return type of the propagated element.
          DartType propagatedStaticType =
              _computeInvokeReturnType(propagatedInvokeType);
          _resolver.recordPropagatedTypeIfBetter(
              node, propagatedStaticType, true);
          // Record propagated return type of the propagated element.
          DartType propagatedPropagatedType =
              _computePropagatedReturnType(propagatedElement);
          _resolver.recordPropagatedTypeIfBetter(
              node, propagatedPropagatedType, true);
        }
      }
    }
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, _getStaticType(expression));
    if (propagateTypes) {
      _resolver.recordPropagatedTypeIfBetter(node, expression.propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of `null` is bottom.
   * </blockquote>
   */
  @override
  Object visitNullLiteral(NullLiteral node) {
    _recordStaticType(node, _typeProvider.nullType);
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, _getStaticType(expression));
    if (propagateTypes) {
      _resolver.recordPropagatedTypeIfBetter(node, expression.propagatedType);
    }
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
    DartType staticType = _getStaticType(operand, read: true);
    TokenType operator = node.operator.type;
    if (operator == TokenType.MINUS_MINUS || operator == TokenType.PLUS_PLUS) {
      DartType intType = _typeProvider.intType;
      if (identical(staticType, intType)) {
        staticType = intType;
      }
    }
    _recordStaticType(node, staticType);
    if (propagateTypes) {
      _resolver.recordPropagatedTypeIfBetter(node, operand.propagatedType);
    }
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
      staticType = _getTypeOfProperty(staticElement);
      if (propagateTypes) {
        propagatedType =
            _getPropertyPropagatedType(staticElement, propagatedType);
      }
    } else if (staticElement is ExecutableElement) {
      staticType = staticElement.type;
    } else if (staticElement is TypeParameterElement) {
      staticType = staticElement.type;
    } else if (staticElement is VariableElement) {
      staticType = staticElement.type;
    }
    staticType = _inferGenericInstantiationFromContext(node, staticType);
    if (!(_strongMode &&
        _inferObjectAccess(node, staticType, prefixedIdentifier))) {
      _recordStaticType(prefixedIdentifier, staticType);
      _recordStaticType(node, staticType);
    }
    if (propagateTypes) {
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
        propagatedType = _getTypeOfProperty(propagatedElement);
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
      _resolver.recordPropagatedTypeIfBetter(
          prefixedIdentifier, propagatedType);
      _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.27: <blockquote>A unary expression <i>u</i> of the form
   * <i>op e</i> is equivalent to a method invocation <i>expression e.op()</i>. An expression of the
   * form <i>op super</i> is equivalent to the method invocation <i>super.op()<i>.</blockquote>
   */
  @override
  Object visitPrefixExpression(PrefixExpression node) {
    TokenType operator = node.operator.type;
    if (operator == TokenType.BANG) {
      _recordStaticType(node, _typeProvider.boolType);
    } else {
      // The other cases are equivalent to invoking a method.
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      if (operator == TokenType.MINUS_MINUS ||
          operator == TokenType.PLUS_PLUS) {
        DartType intType = _typeProvider.intType;
        if (identical(_getStaticType(node.operand, read: true), intType)) {
          staticType = intType;
        }
      }
      _recordStaticType(node, staticType);
      if (propagateTypes) {
        MethodElement propagatedMethodElement = node.propagatedElement;
        if (!identical(propagatedMethodElement, staticMethodElement)) {
          DartType propagatedType =
              _computeStaticReturnType(propagatedMethodElement);
          _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
        }
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
      staticType = _getTypeOfProperty(staticElement);
    } else {
      // TODO(brianwilkerson) Report this internal error.
    }
    staticType = _inferGenericInstantiationFromContext(node, staticType);
    if (!(_strongMode && _inferObjectAccess(node, staticType, propertyName))) {
      _recordStaticType(propertyName, staticType);
      _recordStaticType(node, staticType);
    }
    if (propagateTypes) {
      Element propagatedElement = propertyName.propagatedElement;
      DartType propagatedType = _overrideManager.getType(propagatedElement);
      if (propagatedElement is MethodElement) {
        propagatedType = propagatedElement.type;
      } else if (propagatedElement is PropertyAccessorElement) {
        propagatedType = _getTypeOfProperty(propagatedElement);
      } else {
        // TODO(brianwilkerson) Report this internal error.
      }
      _resolver.recordPropagatedTypeIfBetter(propertyName, propagatedType);
      _resolver.recordPropagatedTypeIfBetter(node, propagatedType);
    }
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
      staticType = _getTypeOfProperty(element);
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
    staticType = _inferGenericInstantiationFromContext(node, staticType);
    _recordStaticType(node, staticType);
    if (propagateTypes) {
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
    }
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
    if (_strongMode) {
      _inferLocalVariableType(node, initializer);
    }
    if (initializer != null) {
      DartType rightType = initializer.bestType;
      SimpleIdentifier name = node.name;
      if (propagateTypes) {
        _resolver.recordPropagatedTypeIfBetter(name, rightType);
      }
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
    if (propagateTypes) {
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
      return body.expression.bestType;
    }
    if (body is BlockFunctionBody) {
      _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction visitor =
          new _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction(
              _typeProvider, _typeSystem);
      body.accept(visitor);
      return visitor.result;
    }
    return null;
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
          .instantiate(<DartType>[type.flattenFutures(_typeSystem)]);
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
          ArgumentList argumentList, Map<String, String> nameMap) =>
      _getElementNameAsType(
          library, _getFirstArgumentAsString(argumentList), nameMap);

  /**
   * Return the propagated type of the given [Element], or `null`.
   */
  DartType _getPropertyPropagatedType(Element element, DartType currentType) {
    if (element is PropertyAccessorElement && element.isGetter) {
      PropertyInducingElement variable = element.variable;
      DartType propagatedType = variable.propagatedType;
      if (currentType == null ||
          propagatedType != null &&
              propagatedType.isMoreSpecificThan(currentType)) {
        return propagatedType;
      }
    }
    return currentType;
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

  /**
   * Given a declared identifier from a foreach loop, attempt to infer
   * a type for it if one is not already present.  Inference is based
   * on the type of the iterator or stream over which the foreach loop
   * is defined.
   */
  void _inferForEachLoopVariableType(DeclaredIdentifier loopVariable) {
    if (loopVariable != null &&
        loopVariable.type == null &&
        loopVariable.parent is ForEachStatement) {
      ForEachStatement loop = loopVariable.parent;
      if (loop.iterable != null) {
        Expression expr = loop.iterable;
        LocalVariableElementImpl element = loopVariable.element;
        DartType exprType = expr.staticType;
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

  /**
   * Given an uninstantiated generic function type, try to infer the
   * instantiated generic function type from the surrounding context.
   */
  DartType _inferGenericInstantiationFromContext(AstNode node, DartType type) {
    if (_strongMode) {
      TypeSystem ts = _typeSystem;
      var context = InferenceContext.getContext(node);
      if (context is FunctionType &&
          type is FunctionType &&
          ts is StrongTypeSystemImpl) {
        return ts.inferFunctionTypeInstantiation(context, type,
            errorReporter: _resolver.errorReporter, errorNode: node);
      }
    } else if (type is FunctionType) {
      // In Dart 1 mode we want to implicitly instantiate generic functions to
      // their bounds always, so we don't get a universal function type.
      return _typeSystem.instantiateToBounds(type);
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
    var freshType =
        type is FunctionType ? new FunctionTypeImpl.fresh(type) : type;

    FunctionType inferred = _inferGenericInvoke(
        node, freshType, node.typeArguments, arguments, node.function);
    if (inferred != null && inferred != node.staticInvokeType) {
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters = ResolverVisitor
          .resolveArgumentsToParameters(arguments, inferred.parameters, null);
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
      AstNode errorNode) {
    TypeSystem ts = _typeSystem;
    if (typeArguments == null &&
        fnType is FunctionType &&
        fnType.typeFormals.isNotEmpty &&
        ts is StrongTypeSystemImpl) {
      // Get the parameters that correspond to the uninstantiated generic.
      List<ParameterElement> rawParameters = ResolverVisitor
          .resolveArgumentsToParameters(argumentList, fnType.parameters, null);

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
          errorReporter: _resolver.errorReporter, errorNode: errorNode);
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
        constructor.type.typeArguments, arguments, node.constructorName);

    if (inferred != null && inferred != originalElement.type) {
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters = ResolverVisitor
          .resolveArgumentsToParameters(arguments, inferred.parameters, null);
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
        node.element as ExecutableElementImpl;

    FunctionBody body = node.body;

    DartType computedType;
    if (_strongMode) {
      computedType = InferenceContext.getContext(body) ?? _dynamicType;
    } else {
      if (body is ExpressionFunctionBody) {
        computedType = _getStaticType(body.expression);
      } else {
        computedType = _dynamicType;
      }
    }

    computedType = _computeReturnTypeOfFunction(body, computedType);
    functionElement.returnType = computedType;
    if (propagateTypes) {
      _recordPropagatedTypeOfFunction(functionElement, node.body);
    }
    _recordStaticType(node, functionElement.type);
    if (_strongMode) {
      _resolver.inferenceContext.recordInference(node, functionElement.type);
    }
  }

  /**
   * Given a local variable declaration and its initializer, attempt to infer
   * a type for the local variable declaration based on the initializer.
   * Inference is only done if an explicit type is not present, and if
   * inferring a type improves the type.
   */
  void _inferLocalVariableType(
      VariableDeclaration node, Expression initializer) {
    if (initializer != null) {
      AstNode parent = node.parent;
      if (parent is VariableDeclarationList && parent.type == null) {
        DartType type = resolutionMap.staticTypeForExpression(initializer);
        if (type != null && !type.isBottom && !type.isDartCoreNull) {
          VariableElement element = node.element;
          if (element is LocalVariableElementImpl) {
            element.type = initializer.staticType;
            node.name.staticType = initializer.staticType;
          }
        }
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

  /**
   * Return `true` if the given library is the 'dart:html' library.
   *
   * @param library the library being tested
   * @return `true` if the library is 'dart:html'
   */
  bool _isHtmlLibrary(LibraryElement library) =>
      library != null && "dart.dom.html" == library.name;

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
   * Record that the propagated type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the propagated type of the node
   */
  void _recordPropagatedType(Expression expression, DartType type) {
    if (!_strongMode &&
        type != null &&
        !type.isBottom &&
        !type.isDynamic &&
        !type.isDartCoreNull) {
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
    if (_strongMode) {
      return;
    }
    DartType propagatedReturnType =
        _computePropagatedReturnTypeOfFunction(body);
    if (propagatedReturnType == null) {
      return;
    }
    // Ignore 'Bottom' and 'Null' types.
    if (propagatedReturnType.isBottom || propagatedReturnType.isDartCoreNull) {
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
}

class _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction
    extends GeneralizingAstVisitor<Object> {
  final TypeSystem _typeSystem;
  final TypeProvider _typeProvider;
  DartType result = null;

  _StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction(
      this._typeProvider, this._typeSystem);

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
      type = _typeProvider.nullType;
    }
    // merge types
    if (result == null) {
      result = type;
    } else {
      result = _typeSystem.getLeastUpperBound(result, type);
    }
    return null;
  }
}
