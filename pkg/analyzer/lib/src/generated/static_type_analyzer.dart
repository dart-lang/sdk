// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart' show ConstructorMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Instances of the class `StaticTypeAnalyzer` perform two type-related tasks. First, they
/// compute the static type of every expression. Second, they look for any static type errors or
/// warnings that might need to be generated. The requirements for the type analyzer are:
/// <ol>
/// * Every element that refers to types should be fully populated.
/// * Every node representing an expression should be resolved to the Type of the expression.
/// </ol>
class StaticTypeAnalyzer extends SimpleAstVisitor<void> {
  /// The resolver driving the resolution and type analysis.
  final ResolverVisitor _resolver;

  final MigrationResolutionHooks _migrationResolutionHooks;

  /// The object providing access to the types defined by the language.
  TypeProviderImpl _typeProvider;

  /// The type system in use for static type analysis.
  TypeSystemImpl _typeSystem;

  /// The type representing the type 'dynamic'.
  DartType _dynamicType;

  final FlowAnalysisHelper _flowAnalysis;

  /// Initialize a newly created static type analyzer to analyze types for the
  /// [_resolver] based on the
  ///
  /// @param resolver the resolver driving this participant
  StaticTypeAnalyzer(
      this._resolver, this._flowAnalysis, this._migrationResolutionHooks) {
    _typeProvider = _resolver.typeProvider;
    _typeSystem = _resolver.typeSystem;
    _dynamicType = _typeProvider.dynamicType;
  }

  /// Given a constructor for a generic type, returns the equivalent generic
  /// function type that we could use to forward to the constructor, or for a
  /// non-generic type simply returns the constructor type.
  ///
  /// For example given the type `class C<T> { C(T arg); }`, the generic function
  /// type is `<T>(T) -> C<T>`.
  FunctionType constructorToGenericFunctionType(
      ConstructorElement constructor) {
    var classElement = constructor.enclosingElement;
    var typeParameters = classElement.typeParameters;
    if (typeParameters.isEmpty) {
      return constructor.type;
    }

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: constructor.parameters,
      returnType: constructor.returnType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplication
  void recordStaticType(Expression expression, DartType type) {
    if (_migrationResolutionHooks != null) {
      // TODO(scheglov) type cannot be null
      type = _migrationResolutionHooks.modifyExpressionType(
        expression,
        type ?? DynamicTypeImpl.instance,
      );
    }

    // TODO(scheglov) type cannot be null
    if (type == null) {
      expression.staticType = DynamicTypeImpl.instance;
    } else {
      expression.staticType = type;
      if (_typeSystem.isBottom(type)) {
        _flowAnalysis?.flow?.handleExit();
      }
    }
  }

  /// The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
  /// `String`.</blockquote>
  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    recordStaticType(node, _typeProvider.stringType);
  }

  /// The Dart Language Specification, 12.32: <blockquote>... the cast expression <i>e as T</i> ...
  ///
  /// It is a static warning if <i>T</i> does not denote a type available in the current lexical
  /// scope.
  ///
  /// The static type of a cast expression <i>e as T</i> is <i>T</i>.</blockquote>
  @override
  void visitAsExpression(AsExpression node) {
    recordStaticType(node, _getType(node.type));
  }

  /// The Dart Language Specification, 16.29 (Await Expressions):
  ///
  ///   The static type of [the expression "await e"] is flatten(T) where T is
  ///   the static type of e.
  @override
  void visitAwaitExpression(AwaitExpression node) {
    DartType resultType = node.expression.staticType;
    if (resultType != null) resultType = _typeSystem.flatten(resultType);
    recordStaticType(node, resultType);
  }

  /// The Dart Language Specification, 12.4: <blockquote>The static type of a boolean literal is
  /// bool.</blockquote>
  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    recordStaticType(node, _typeProvider.boolType);
  }

  /// The Dart Language Specification, 12.15.2: <blockquote>A cascaded method invocation expression
  /// of the form <i>e..suffix</i> is equivalent to the expression <i>(t) {t.suffix; return
  /// t;}(e)</i>.</blockquote>
  @override
  void visitCascadeExpression(CascadeExpression node) {
    recordStaticType(node, node.target.staticType);
  }

  /// The Dart Language Specification, 12.19: <blockquote> ... a conditional expression <i>c</i> of
  /// the form <i>e<sub>1</sub> ? e<sub>2</sub> : e<sub>3</sub></i> ...
  ///
  /// It is a static type warning if the type of e<sub>1</sub> may not be assigned to `bool`.
  ///
  /// The static type of <i>c</i> is the least upper bound of the static type of <i>e<sub>2</sub></i>
  /// and the static type of <i>e<sub>3</sub></i>.</blockquote>
  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _analyzeLeastUpperBound(node, node.thenExpression, node.elseExpression);
  }

  /// The Dart Language Specification, 12.3: <blockquote>The static type of a literal double is
  /// double.</blockquote>
  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    recordStaticType(node, _typeProvider.doubleType);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _resolver.extensionResolver.resolveOverride(node);
  }

  /// The Dart Language Specification, 12.9: <blockquote>The static type of a function literal of the
  /// form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;, T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub>
  /// x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub> = dk]) => e</i> is
  /// <i>(T<sub>1</sub>, &hellip;, Tn, [T<sub>n+1</sub> x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>
  /// x<sub>n+k</sub>]) &rarr; T<sub>0</sub></i>, where <i>T<sub>0</sub></i> is the static type of
  /// <i>e</i>. In any case where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is
  /// considered to have been specified as dynamic.
  ///
  /// The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
  /// T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
  /// x<sub>n+k</sub> : dk}) => e</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
  /// x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; T<sub>0</sub></i>, where
  /// <i>T<sub>0</sub></i> is the static type of <i>e</i>. In any case where <i>T<sub>i</sub>, 1
  /// &lt;= i &lt;= n</i>, is not specified, it is considered to have been specified as dynamic.
  ///
  /// The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
  /// T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub> x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub>
  /// x<sub>n+k</sub> = dk]) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>
  /// x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>]) &rarr; dynamic</i>. In any case
  /// where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
  /// specified as dynamic.
  ///
  /// The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
  /// T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
  /// x<sub>n+k</sub> : dk}) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
  /// x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; dynamic</i>. In any case
  /// where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
  /// specified as dynamic.</blockquote>
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  /// The Dart Language Specification, 12.11.1: <blockquote>The static type of a new expression of
  /// either the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the form <i>new
  /// T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>.</blockquote>
  ///
  /// The Dart Language Specification, 12.11.2: <blockquote>The static type of a constant object
  /// expression of either the form <i>const T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the
  /// form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>. </blockquote>
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _inferInstanceCreationExpression(node);
    recordStaticType(node, node.constructorName.type.type);
  }

  /// <blockquote>
  /// An integer literal has static type \code{int}, unless the surrounding
  /// static context type is a type which \code{int} is not assignable to, and
  /// \code{double} is. In that case the static type of the integer literal is
  /// \code{double}.
  /// <blockquote>
  ///
  /// and
  ///
  /// <blockquote>
  /// If $e$ is an expression of the form \code{-$l$} where $l$ is an integer
  /// literal (\ref{numbers}) with numeric integer value $i$, then the static
  /// type of $e$ is the same as the static type of an integer literal with the
  /// same contexttype
  /// </blockquote>
  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // Check the parent context for negated integer literals.
    var context = InferenceContext.getContext(
        (node as IntegerLiteralImpl).immediatelyNegated ? node.parent : node);
    if (context == null ||
        _typeSystem.isAssignableTo2(_typeProvider.intType, context) ||
        !_typeSystem.isAssignableTo2(_typeProvider.doubleType, context)) {
      recordStaticType(node, _typeProvider.intType);
    } else {
      recordStaticType(node, _typeProvider.doubleType);
    }
  }

  /// The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
  /// denote a type available in the current lexical scope.
  ///
  /// The static type of an is-expression is `bool`.</blockquote>
  @override
  void visitIsExpression(IsExpression node) {
    recordStaticType(node, _typeProvider.boolType);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, expression.staticType);
  }

  /// The Dart Language Specification, 12.2: <blockquote>The static type of `null` is bottom.
  /// </blockquote>
  @override
  void visitNullLiteral(NullLiteral node) {
    recordStaticType(node, _typeProvider.nullType);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, expression.staticType);
  }

  /// The Dart Language Specification, 12.9: <blockquote>The static type of a rethrow expression is
  /// bottom.</blockquote>
  @override
  void visitRethrowExpression(RethrowExpression node) {
    recordStaticType(node, _typeProvider.bottomType);
  }

  /// The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
  /// `String`.</blockquote>
  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    recordStaticType(node, _typeProvider.stringType);
  }

  /// The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
  /// `String`.</blockquote>
  @override
  void visitStringInterpolation(StringInterpolation node) {
    recordStaticType(node, _typeProvider.stringType);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    if (_resolver.thisType == null ||
        node.thisOrAncestorOfType<ExtensionDeclaration>() != null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported.
      recordStaticType(node, _dynamicType);
    } else {
      recordStaticType(node, _resolver.thisType);
    }
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    recordStaticType(node, _typeProvider.symbolType);
  }

  /// The Dart Language Specification, 12.10: <blockquote>The static type of `this` is the
  /// interface of the immediately enclosing class.</blockquote>
  @override
  void visitThisExpression(ThisExpression node) {
    if (_resolver.thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported.
      recordStaticType(node, _dynamicType);
    } else {
      recordStaticType(node, _resolver.thisType);
    }
  }

  /// The Dart Language Specification, 12.8: <blockquote>The static type of a throw expression is
  /// bottom.</blockquote>
  @override
  void visitThrowExpression(ThrowExpression node) {
    recordStaticType(node, _typeProvider.bottomType);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types of subexpressions [expr1] and [expr2].
  void _analyzeLeastUpperBound(
      Expression node, Expression expr1, Expression expr2) {
    DartType staticType1 = expr1.staticType;
    DartType staticType2 = expr2.staticType;

    _analyzeLeastUpperBoundTypes(node, staticType1, staticType2);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types [staticType1] and [staticType2].
  void _analyzeLeastUpperBoundTypes(
      Expression node, DartType staticType1, DartType staticType2) {
    // TODO(brianwilkerson) Determine whether this can still happen.
    staticType1 ??= _dynamicType;

    // TODO(brianwilkerson) Determine whether this can still happen.
    staticType2 ??= _dynamicType;

    DartType staticType =
        _typeSystem.getLeastUpperBound(staticType1, staticType2) ??
            _dynamicType;

    staticType = _resolver.toLegacyTypeIfOptOut(staticType);

    recordStaticType(node, staticType);
  }

  /// Return the type represented by the given type [annotation].
  DartType _getType(TypeAnnotation annotation) {
    DartType type = annotation.type;
    if (type == null) {
      //TODO(brianwilkerson) Determine the conditions for which the type is
      // null.
      return _dynamicType;
    }
    return type;
  }

  /// Given an instance creation of a possibly generic type, infer the type
  /// arguments using the current context type as well as the argument types.
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
    var rawElement = originalElement.declaration;
    rawElement = _resolver.toLegacyElement(rawElement);

    FunctionType constructorType = constructorToGenericFunctionType(rawElement);

    ArgumentList arguments = node.argumentList;
    FunctionType inferred = _resolver.inferenceHelper.inferGenericInvoke(
        node,
        constructorType,
        constructor.type.typeArguments,
        arguments,
        node.constructorName,
        isConst: node.isConst);

    if (inferred != null && inferred != originalElement.type) {
      inferred = _resolver.toLegacyTypeIfOptOut(inferred) as FunctionType;
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              arguments, inferred.parameters, null);
      constructor.type.type = inferred.returnType;
      // Update the static element as well. This is used in some cases, such as
      // computing constant values. It is stored in two places.
      var constructorElement = ConstructorMember.from(
        rawElement,
        inferred.returnType as InterfaceType,
      );
      constructorElement = _resolver.toLegacyElement(constructorElement);
      constructor.staticElement = constructorElement;
    }
  }
}
