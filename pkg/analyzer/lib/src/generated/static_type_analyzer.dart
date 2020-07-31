// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show ConstructorMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_demotion.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';
import 'package:analyzer/src/task/strong/checker.dart'
    show getExpressionType, getReadType;

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

  /// The feature set that should be used to resolve types.
  final FeatureSet _featureSet;

  final MigrationResolutionHooks _migrationResolutionHooks;

  /// The object providing access to the types defined by the language.
  TypeProviderImpl _typeProvider;

  /// The type system in use for static type analysis.
  TypeSystemImpl _typeSystem;

  /// The type representing the type 'dynamic'.
  DartType _dynamicType;

  /// True if inference failures should be reported, otherwise false.
  bool _strictInference;

  /// The object providing promoted or declared types of variables.
  LocalVariableTypeProvider _localVariableTypeProvider;

  final FlowAnalysisHelper _flowAnalysis;

  /// Initialize a newly created static type analyzer to analyze types for the
  /// [_resolver] based on the
  ///
  /// @param resolver the resolver driving this participant
  StaticTypeAnalyzer(this._resolver, this._featureSet, this._flowAnalysis,
      this._migrationResolutionHooks) {
    _typeProvider = _resolver.typeProvider;
    _typeSystem = _resolver.typeSystem;
    _dynamicType = _typeProvider.dynamicType;
    _localVariableTypeProvider = _resolver.localVariableTypeProvider;
    AnalysisOptionsImpl analysisOptions =
        _resolver.definingLibrary.context.analysisOptions;
    _strictInference = analysisOptions.strictInference;
  }

  /// Is `true` if the library being analyzed is non-nullable by default.
  bool get _isNonNullableByDefault =>
      _featureSet.isEnabled(Feature.non_nullable);

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
  void recordStaticType(Expression expression, DartType type) {
    if (_migrationResolutionHooks != null) {
      type = _migrationResolutionHooks.modifyExpressionType(
          expression, type ?? _dynamicType);
    }

    if (type == null) {
      expression.staticType = _dynamicType;
    } else {
      expression.staticType = type;
      if (identical(type, NeverTypeImpl.instance)) {
        _flowAnalysis?.flow?.handleExit();
      }
    }
  }

  /// The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
  /// `String`.</blockquote>
  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    recordStaticType(node, _nonNullable(_typeProvider.stringType));
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
    DartType resultType = _getStaticType(node.expression);
    if (resultType != null) resultType = _typeSystem.flatten(resultType);
    recordStaticType(node, resultType);
  }

  /// The Dart Language Specification, 12.4: <blockquote>The static type of a boolean literal is
  /// bool.</blockquote>
  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    recordStaticType(node, _nonNullable(_typeProvider.boolType));
  }

  /// The Dart Language Specification, 12.15.2: <blockquote>A cascaded method invocation expression
  /// of the form <i>e..suffix</i> is equivalent to the expression <i>(t) {t.suffix; return
  /// t;}(e)</i>.</blockquote>
  @override
  void visitCascadeExpression(CascadeExpression node) {
    recordStaticType(node, _getStaticType(node.target));
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
    recordStaticType(node, _nonNullable(_typeProvider.doubleType));
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

  /// The Dart Language Specification, 12.29: <blockquote>An assignable expression of the form
  /// <i>e<sub>1</sub>[e<sub>2</sub>]</i> is evaluated as a method invocation of the operator method
  /// <i>[]</i> on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.</blockquote>
  @override
  void visitIndexExpression(IndexExpression node) {
    if (identical(node.realTarget.staticType, NeverTypeImpl.instance)) {
      recordStaticType(node, NeverTypeImpl.instance);
    } else {
      DartType type;
      if (node.inSetterContext()) {
        var parameters = node.staticElement?.parameters;
        if (parameters?.length == 2) {
          type = parameters[1].type;
        }
      } else {
        type = node.staticElement?.returnType;
      }

      type ??= _dynamicType;

      recordStaticType(node, type);
    }

    _resolver.nullShortingTermination(node);
  }

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
      recordStaticType(node, _nonNullable(_typeProvider.intType));
    } else {
      recordStaticType(node, _nonNullable(_typeProvider.doubleType));
    }
  }

  /// The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
  /// denote a type available in the current lexical scope.
  ///
  /// The static type of an is-expression is `bool`.</blockquote>
  @override
  void visitIsExpression(IsExpression node) {
    recordStaticType(node, _nonNullable(_typeProvider.boolType));
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    throw StateError('Should not be invoked');
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, _getStaticType(expression));
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
    recordStaticType(node, _getStaticType(expression));
  }

  /// See [visitSimpleIdentifier].
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element staticElement = prefixedIdentifier.staticElement;

    if (staticElement is ExtensionElement) {
      _setExtensionIdentifierType(node);
      return;
    }

    if (identical(node.prefix.staticType, NeverTypeImpl.instance)) {
      recordStaticType(prefixedIdentifier, NeverTypeImpl.instance);
      recordStaticType(node, NeverTypeImpl.instance);
      return;
    }

    DartType staticType = _dynamicType;
    if (staticElement is ClassElement) {
      if (_isExpressionIdentifier(node)) {
        var type = _nonNullable(_typeProvider.typeType);
        node.staticType = type;
        node.identifier.staticType = type;
      }
      return;
    } else if (staticElement is DynamicElementImpl) {
      var type = _nonNullable(_typeProvider.typeType);
      node.staticType = type;
      node.identifier.staticType = type;
      return;
    } else if (staticElement is FunctionTypeAliasElement) {
      if (node.parent is TypeName) {
        // no type
      } else {
        var type = _nonNullable(_typeProvider.typeType);
        node.staticType = type;
        node.identifier.staticType = type;
      }
      return;
    } else if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(staticElement);
    } else if (staticElement is ExecutableElement) {
      staticType = staticElement.type;
    } else if (staticElement is VariableElement) {
      staticType = staticElement.type;
    }

    staticType = _inferTearOff(node, node.identifier, staticType);
    if (!_inferObjectAccess(node, staticType, prefixedIdentifier)) {
      recordStaticType(prefixedIdentifier, staticType);
      recordStaticType(node, staticType);
    }
  }

  /// The Dart Language Specification, 12.13: <blockquote> Property extraction allows for a member of
  /// an object to be concisely extracted from the object. If <i>o</i> is an object, and if <i>m</i>
  /// is the name of a method member of <i>o</i>, then
  /// * <i>o.m</i> is defined to be equivalent to: <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
  /// {p<sub>1</sub> : d<sub>1</sub>, &hellip;, p<sub>k</sub> : d<sub>k</sub>}){return
  /// o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>, p<sub>1</sub>: p<sub>1</sub>, &hellip;,
  /// p<sub>k</sub>: p<sub>k</sub>);}</i> if <i>m</i> has required parameters <i>r<sub>1</sub>,
  /// &hellip;, r<sub>n</sub></i>, and named parameters <i>p<sub>1</sub> &hellip; p<sub>k</sub></i>
  /// with defaults <i>d<sub>1</sub>, &hellip;, d<sub>k</sub></i>.
  /// * <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>, [p<sub>1</sub> = d<sub>1</sub>, &hellip;,
  /// p<sub>k</sub> = d<sub>k</sub>]){return o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
  /// p<sub>1</sub>, &hellip;, p<sub>k</sub>);}</i> if <i>m</i> has required parameters
  /// <i>r<sub>1</sub>, &hellip;, r<sub>n</sub></i>, and optional positional parameters
  /// <i>p<sub>1</sub> &hellip; p<sub>k</sub></i> with defaults <i>d<sub>1</sub>, &hellip;,
  /// d<sub>k</sub></i>.
  /// Otherwise, if <i>m</i> is the name of a getter member of <i>o</i> (declared implicitly or
  /// explicitly) then <i>o.m</i> evaluates to the result of invoking the getter. </blockquote>
  ///
  /// The Dart Language Specification, 12.17: <blockquote> ... a getter invocation <i>i</i> of the
  /// form <i>e.m</i> ...
  ///
  /// Let <i>T</i> be the static type of <i>e</i>. It is a static type warning if <i>T</i> does not
  /// have a getter named <i>m</i>.
  ///
  /// The static type of <i>i</i> is the declared return type of <i>T.m</i>, if <i>T.m</i> exists;
  /// otherwise the static type of <i>i</i> is dynamic.
  ///
  /// ... a getter invocation <i>i</i> of the form <i>C.m</i> ...
  ///
  /// It is a static warning if there is no class <i>C</i> in the enclosing lexical scope of
  /// <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter named <i>m</i>.
  ///
  /// The static type of <i>i</i> is the declared return type of <i>C.m</i> if it exists or dynamic
  /// otherwise.
  ///
  /// ... a top-level getter invocation <i>i</i> of the form <i>m</i>, where <i>m</i> is an
  /// identifier ...
  ///
  /// The static type of <i>i</i> is the declared return type of <i>m</i>.</blockquote>
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

    staticType = _inferTearOff(node, node.propertyName, staticType);

    if (!_inferObjectAccess(node, staticType, propertyName)) {
      recordStaticType(propertyName, staticType);
      recordStaticType(node, staticType);
      _resolver.nullShortingTermination(node);
    }
  }

  /// The Dart Language Specification, 12.9: <blockquote>The static type of a rethrow expression is
  /// bottom.</blockquote>
  @override
  void visitRethrowExpression(RethrowExpression node) {
    recordStaticType(node, _typeProvider.bottomType);
  }

  /// The Dart Language Specification, 12.30: <blockquote>Evaluation of an identifier expression
  /// <i>e</i> of the form <i>id</i> proceeds as follows:
  ///
  /// Let <i>d</i> be the innermost declaration in the enclosing lexical scope whose name is
  /// <i>id</i>. If no such declaration exists in the lexical scope, let <i>d</i> be the declaration
  /// of the inherited member named <i>id</i> if it exists.
  /// * If <i>d</i> is a class or type alias <i>T</i>, the value of <i>e</i> is the unique instance
  /// of class `Type` reifying <i>T</i>.
  /// * If <i>d</i> is a type parameter <i>T</i>, then the value of <i>e</i> is the value of the
  /// actual type argument corresponding to <i>T</i> that was passed to the generative constructor
  /// that created the current binding of this. We are assured that this is well defined, because if
  /// we were in a static member the reference to <i>T</i> would be a compile-time error.
  /// * If <i>d</i> is a library variable then:
  /// * If <i>d</i> is of one of the forms <i>var v = e<sub>i</sub>;</i>, <i>T v =
  /// e<sub>i</sub>;</i>, <i>final v = e<sub>i</sub>;</i>, <i>final T v = e<sub>i</sub>;</i>, and no
  /// value has yet been stored into <i>v</i> then the initializer expression <i>e<sub>i</sub></i> is
  /// evaluated. If, during the evaluation of <i>e<sub>i</sub></i>, the getter for <i>v</i> is
  /// referenced, a CyclicInitializationError is thrown. If the evaluation succeeded yielding an
  /// object <i>o</i>, let <i>r = o</i>, otherwise let <i>r = null</i>. In any case, <i>r</i> is
  /// stored into <i>v</i>. The value of <i>e</i> is <i>r</i>.
  /// * If <i>d</i> is of one of the forms <i>const v = e;</i> or <i>const T v = e;</i> the result
  /// of the getter is the value of the compile time constant <i>e</i>. Otherwise
  /// * <i>e</i> evaluates to the current binding of <i>id</i>.
  /// * If <i>d</i> is a local variable or formal parameter then <i>e</i> evaluates to the current
  /// binding of <i>id</i>.
  /// * If <i>d</i> is a static method, top level function or local function then <i>e</i>
  /// evaluates to the function defined by <i>d</i>.
  /// * If <i>d</i> is the declaration of a static variable or static getter declared in class
  /// <i>C</i>, then <i>e</i> is equivalent to the getter invocation <i>C.id</i>.
  /// * If <i>d</i> is the declaration of a top level getter, then <i>e</i> is equivalent to the
  /// getter invocation <i>id</i>.
  /// * Otherwise, if <i>e</i> occurs inside a top level or static function (be it function,
  /// method, getter, or setter) or variable initializer, evaluation of e causes a NoSuchMethodError
  /// to be thrown.
  /// * Otherwise <i>e</i> is equivalent to the property extraction <i>this.id</i>.
  /// </blockquote>
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;

    if (element is ExtensionElement) {
      _setExtensionIdentifierType(node);
      return;
    }

    DartType staticType = _dynamicType;
    if (element is ClassElement) {
      if (_isExpressionIdentifier(node)) {
        node.staticType = _nonNullable(_typeProvider.typeType);
      }
      return;
    } else if (element is FunctionTypeAliasElement) {
      if (node.inDeclarationContext() || node.parent is TypeName) {
        // no type
      } else {
        node.staticType = _nonNullable(_typeProvider.typeType);
      }
      return;
    } else if (element is MethodElement) {
      staticType = element.type;
    } else if (element is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(element);
    } else if (element is ExecutableElement) {
      staticType = element.type;
    } else if (element is TypeParameterElement) {
      staticType = _nonNullable(_typeProvider.typeType);
    } else if (element is VariableElement) {
      staticType = _localVariableTypeProvider.getType(node);
    } else if (element is PrefixElement) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier && parent.prefix == node ||
          parent is MethodInvocation && parent.target == node) {
        return;
      }
      staticType = _typeProvider.dynamicType;
    } else if (element is DynamicElementImpl) {
      staticType = _nonNullable(_typeProvider.typeType);
    } else {
      staticType = _dynamicType;
    }
    staticType = _inferTearOff(node, node, staticType);
    recordStaticType(node, staticType);
  }

  /// The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
  /// `String`.</blockquote>
  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    recordStaticType(node, _nonNullable(_typeProvider.stringType));
  }

  /// The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
  /// `String`.</blockquote>
  @override
  void visitStringInterpolation(StringInterpolation node) {
    recordStaticType(node, _nonNullable(_typeProvider.stringType));
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
    recordStaticType(node, _nonNullable(_typeProvider.symbolType));
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

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _inferLocalVariableType(node, node.initializer);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types of subexpressions [expr1] and [expr2].
  void _analyzeLeastUpperBound(
      Expression node, Expression expr1, Expression expr2,
      {bool read = false}) {
    DartType staticType1 = _getExpressionType(expr1, read: read);
    DartType staticType2 = _getExpressionType(expr2, read: read);

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

  /// Gets the definite type of expression, which can be used in cases where
  /// the most precise type is desired, for example computing the least upper
  /// bound.
  ///
  /// See [getExpressionType] for more information. Without strong mode, this is
  /// equivalent to [_getStaticType].
  DartType _getExpressionType(Expression expr, {bool read = false}) =>
      getExpressionType(expr, _typeSystem, _typeProvider, read: read);

  /// Return the static type of the given [expression].
  DartType _getStaticType(Expression expression, {bool read = false}) {
    DartType type;
    if (read) {
      type = getReadType(expression);
    } else {
      if (expression is SimpleIdentifier && expression.inSetterContext()) {
        var element = expression.staticElement;
        if (element is PromotableElement) {
          // We're writing to the element so ignore promotions.
          type = element.type;
        } else {
          type = expression.staticType;
        }
      } else {
        type = expression.staticType;
      }
    }
    if (type == null) {
      // TODO(brianwilkerson) Determine the conditions for which the static type
      // is null.
      return _dynamicType;
    }
    return type;
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

  /// Return the type that should be recorded for a node that resolved to the given accessor.
  ///
  /// @param accessor the accessor that the node resolved to
  /// @return the type that should be recorded for a node that resolved to the given accessor
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
      if (parameterTypes != null && parameterTypes.isNotEmpty) {
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
      inferred = _resolver.toLegacyTypeIfOptOut(inferred);
      // Fix up the parameter elements based on inferred method.
      arguments.correspondingStaticParameters =
          ResolverVisitor.resolveArgumentsToParameters(
              arguments, inferred.parameters, null);
      constructor.type.type = inferred.returnType;
      // Update the static element as well. This is used in some cases, such as
      // computing constant values. It is stored in two places.
      var constructorElement = ConstructorMember.from(
        rawElement,
        inferred.returnType,
      );
      constructorElement = _resolver.toLegacyElement(constructorElement);
      constructor.staticElement = constructorElement;
    }
  }

  /// Given a local variable declaration and its initializer, attempt to infer
  /// a type for the local variable declaration based on the initializer.
  /// Inference is only done if an explicit type is not present, and if
  /// inferring a type improves the type.
  void _inferLocalVariableType(
      VariableDeclaration node, Expression initializer) {
    AstNode parent = node.parent;
    if (initializer != null) {
      if (parent is VariableDeclarationList && parent.type == null) {
        DartType type = initializer.staticType;
        if (type != null && !type.isDartCoreNull) {
          VariableElement element = node.declaredElement;
          if (element is LocalVariableElementImpl) {
            var initializerType = initializer.staticType;
            var inferredType = demoteType(
              _resolver.definingLibrary,
              initializerType,
            );
            element.type = inferredType;
          }
        }
      }
    } else if (_strictInference) {
      if (parent is VariableDeclarationList && parent.type == null) {
        _resolver.errorReporter.reportErrorForNode(
          HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE,
          node,
          [node.name.name],
        );
      }
    }
  }

  /// Given a property access [node] with static type [nodeType],
  /// and [id] is the property name being accessed, infer a type for the
  /// access itself and its constituent components if the access is to one of the
  /// methods or getters of the built in 'Object' type, and if the result type is
  /// a sealed type. Returns true if inference succeeded.
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
    inferredElement = _resolver.toLegacyElement(inferredElement);
    DartType inferredType = inferredElement.returnType;
    if (nodeType != null &&
        nodeType.isDynamic &&
        inferredType is InterfaceType &&
        _typeProvider.nonSubtypableClasses.contains(inferredType.element)) {
      recordStaticType(id, inferredType);
      recordStaticType(node, inferredType);
      return true;
    }
    return false;
  }

  /// Given an uninstantiated generic function type, referenced by the
  /// [identifier] in the tear-off [expression], try to infer the instantiated
  /// generic function type from the surrounding context.
  DartType _inferTearOff(
    Expression expression,
    SimpleIdentifier identifier,
    DartType tearOffType,
  ) {
    var context = InferenceContext.getContext(expression);
    if (context is FunctionType && tearOffType is FunctionType) {
      var typeArguments = _typeSystem.inferFunctionTypeInstantiation(
        context,
        tearOffType,
        errorReporter: _resolver.errorReporter,
        errorNode: expression,
      );
      (identifier as SimpleIdentifierImpl).tearOffTypeArgumentTypes =
          typeArguments;
      if (typeArguments.isNotEmpty) {
        return tearOffType.instantiate(typeArguments);
      }
    }
    return tearOffType;
  }

  /// Return `true` if the given [node] is not a type literal.
  bool _isExpressionIdentifier(Identifier node) {
    var parent = node.parent;
    if (node is SimpleIdentifier && node.inDeclarationContext()) {
      return false;
    }
    if (parent is ConstructorDeclaration) {
      if (parent.name == node || parent.returnType == node) {
        return false;
      }
    }
    if (parent is ConstructorName ||
        parent is MethodInvocation ||
        parent is PrefixedIdentifier && parent.prefix == node ||
        parent is PropertyAccess ||
        parent is TypeName) {
      return false;
    }
    return true;
  }

  /// Return the non-nullable variant of the [type] if NNBD is enabled, otherwise
  /// return the type itself.
  DartType _nonNullable(DartType type) {
    if (_isNonNullableByDefault) {
      return _typeSystem.promoteToNonNull(type);
    }
    return type;
  }

  void _setExtensionIdentifierType(Identifier node) {
    if (node is SimpleIdentifier && node.inDeclarationContext()) {
      return;
    }

    var parent = node.parent;

    if (parent is PrefixedIdentifier && parent.identifier == node) {
      node = parent;
      parent = node.parent;
    }

    if (parent is CommentReference ||
        parent is ExtensionOverride && parent.extensionName == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixedIdentifier && parent.prefix == node ||
        parent is PropertyAccess && parent.target == node) {
      return;
    }

    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.EXTENSION_AS_EXPRESSION,
      node,
      [node.name],
    );

    if (node is PrefixedIdentifier) {
      node.identifier.staticType = _dynamicType;
      node.staticType = _dynamicType;
    } else if (node is SimpleIdentifier) {
      node.staticType = _dynamicType;
    }
  }
}
