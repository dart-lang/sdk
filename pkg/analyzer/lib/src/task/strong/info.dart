// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines static information collected by the type checker and used later by
/// emitters to generate code.
// TODO(jmesserly): this was ported from package:dev_compiler, and needs to be
// refactored to fit into analyzer.
library analyzer.src.task.strong.info;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/type_system.dart';

// A down cast due to a variable declaration to a ground type.  E.g.,
//   T x = expr;
// where T is ground.  We exclude non-ground types as these behave differently
// compared to standard Dart.
class AssignmentCast extends DownCast {
  AssignmentCast(TypeSystem rules, Expression expression, Cast cast)
      : super._internal(rules, expression, cast);

  @override
  String get name => 'STRONG_MODE_ASSIGNMENT_CAST';

  toErrorCode() => new HintCode(name, message);
}

// Coercion which casts one type to another
class Cast extends Coercion {
  Cast(DartType fromType, DartType toType) : super(fromType, toType);
}

// The abstract type of coercions mapping one type to another.
// This class also exposes static builder functions which
// check for errors and reduce redundant coercions to the identity.
abstract class Coercion {
  final DartType fromType;
  final DartType toType;
  Coercion(this.fromType, this.toType);
  static Coercion cast(DartType fromT, DartType toT) => new Cast(fromT, toT);
  static Coercion error() => new CoercionError();
  static Coercion identity(DartType type) => new Identity(type);
}

// The error coercion.  This coercion signals that a coercion
// could not be generated.  The code generator should not see
// these.
class CoercionError extends Coercion {
  CoercionError() : super(null, null);
}

/// Implicitly injected expression conversion.
abstract class CoercionInfo extends StaticInfo {
  static const String _propertyName = 'dev_compiler.src.info.CoercionInfo';

  final TypeSystem rules;

  final Expression node;

  CoercionInfo(this.rules, this.node);

  DartType get baseType => node.staticType ?? DynamicTypeImpl.instance;
  DartType get convertedType;

  String get message;
  DartType get staticType => convertedType;

  toErrorCode() => new HintCode(name, message);

  /// Gets the coercion info associated with this node.
  static CoercionInfo get(AstNode node) => node.getProperty(_propertyName);

  /// Sets the coercion info associated with this node.
  static CoercionInfo set(AstNode node, CoercionInfo info) {
    node.setProperty(_propertyName, info);
    return info;
  }
}

// Base class for all casts from base type to sub type.
abstract class DownCast extends CoercionInfo {
  Cast _cast;

  DownCast._internal(TypeSystem rules, Expression expression, this._cast)
      : super(rules, expression) {
    assert(_cast.toType != baseType &&
        _cast.fromType == baseType &&
        (baseType.isDynamic ||
            // Call methods make the following non-redundant
            _cast.toType.isSubtypeOf(baseType) ||
            baseType.isAssignableTo(_cast.toType)));
  }

  @override List<Object> get arguments => [node, baseType, convertedType];

  Cast get cast => _cast;

  DartType get convertedType => _cast.toType;
  @override String get message => '{0} ({1}) will need runtime check '
      'to cast to type {2}';

  // Factory to create correct DownCast variant.
  static StaticInfo create(
      StrongTypeSystemImpl rules, Expression expression, Cast cast,
      {String reason}) {
    final fromT = cast.fromType;
    final toT = cast.toType;

    // toT <:_R fromT => to <: fromT
    // NB: classes with call methods are subtypes of function
    // types, but the function type is not assignable to the class
    assert(toT.isSubtypeOf(fromT) || fromT.isAssignableTo(toT));

    // Handle null call specially.
    if (expression is NullLiteral) {
      // TODO(vsm): Create a NullCast for this once we revisit nonnullability.
      return new DownCastImplicit(rules, expression, cast);
    }

    // Inference "casts":
    if (expression is Literal) {
      // fromT should be an exact type - this will almost certainly fail at
      // runtime.
      return new StaticTypeError(rules, expression, toT, reason: reason);
    }
    if (expression is FunctionExpression) {
      // fromT should be an exact type - this will almost certainly fail at
      // runtime.
      return new UninferredClosure(rules, expression, cast);
    }
    if (expression is InstanceCreationExpression) {
      // fromT should be an exact type - this will almost certainly fail at
      // runtime.
      return new StaticTypeError(rules, expression, toT, reason: reason);
    }

    // TODO(vsm): Change this to an assert when we have generic methods and
    // fix TypeRules._coerceTo to disallow implicit sideways casts.
    if (!rules.isSubtypeOf(toT, fromT)) {
      assert(toT.isSubtypeOf(fromT) || fromT.isAssignableTo(toT));
      return new DownCastComposite(rules, expression, cast);
    }

    // Composite cast: these are more likely to fail.
    if (!rules.isGroundType(toT)) {
      // This cast is (probably) due to our different treatment of dynamic.
      // It may be more likely to fail at runtime.
      if (fromT is InterfaceType) {
        // For class types, we'd like to allow non-generic down casts, e.g.,
        // Iterable<T> to List<T>.  The intuition here is that raw (generic)
        // casts are problematic, and we should complain about those.
        var typeArgs = fromT.typeArguments;
        if (typeArgs.isEmpty || typeArgs.any((t) => t.isDynamic)) {
          return new DownCastComposite(rules, expression, cast);
        }
      } else {
        return new DownCastComposite(rules, expression, cast);
      }
    }

    // Dynamic cast
    if (fromT.isDynamic) {
      return new DynamicCast(rules, expression, cast);
    }

    // Assignment cast
    var parent = expression.parent;
    if (parent is VariableDeclaration && (parent.initializer == expression)) {
      return new AssignmentCast(rules, expression, cast);
    }

    // Other casts
    return new DownCastImplicit(rules, expression, cast);
  }
}

//
// Implicit down casts.  These are only injected by the compiler by flag.
//
// A down cast to a non-ground type.  These behave differently from standard
// Dart and may be more likely to fail at runtime.
class DownCastComposite extends DownCast {
  DownCastComposite(TypeSystem rules, Expression expression, Cast cast)
      : super._internal(rules, expression, cast);

  @override
  String get name => 'STRONG_MODE_DOWN_CAST_COMPOSITE';

  toErrorCode() => new StaticTypeWarningCode(name, message);
}

// A down cast to a non-ground type.  These behave differently from standard
// Dart and may be more likely to fail at runtime.
class DownCastImplicit extends DownCast {
  DownCastImplicit(TypeSystem rules, Expression expression, Cast cast)
      : super._internal(rules, expression, cast);

  @override
  String get name => 'STRONG_MODE_DOWN_CAST_IMPLICIT';

  toErrorCode() => new HintCode(name, message);
}

// A down cast from dynamic to T.
class DynamicCast extends DownCast {
  DynamicCast(TypeSystem rules, Expression expression, Cast cast)
      : super._internal(rules, expression, cast);

  @override
  String get name => 'STRONG_MODE_DYNAMIC_CAST';

  toErrorCode() => new HintCode(name, message);
}

class DynamicInvoke extends CoercionInfo {
  static const String _propertyName = 'dev_compiler.src.info.DynamicInvoke';

  DynamicInvoke(TypeSystem rules, Expression expression)
      : super(rules, expression);
  DartType get convertedType => DynamicTypeImpl.instance;
  String get message => '{0} requires dynamic invoke';

  @override
  String get name => 'STRONG_MODE_DYNAMIC_INVOKE';

  toErrorCode() => new HintCode(name, message);

  /// Whether this [node] is the target of a dynamic operation.
  static bool get(AstNode node) {
    var value = node.getProperty(_propertyName);
    return value != null ? value : false;
  }

  /// Sets whether this node is the target of a dynamic operation.
  static bool set(AstNode node, bool value) {
    // Free the storage for things that aren't dynamic.
    if (value == false) value = null;
    node.setProperty(_propertyName, value);
    return value;
  }
}

// The identity coercion
class Identity extends Coercion {
  Identity(DartType fromType) : super(fromType, fromType);
}

// Standard / unspecialized inferred type
class InferredType extends InferredTypeBase {
  InferredType(TypeSystem rules, Expression expression, DartType type)
      : super._internal(rules, expression, type);

  @override
  String get name => 'STRONG_MODE_INFERRED_TYPE';

  // Factory to create correct InferredType variant.
  static InferredTypeBase create(
      TypeSystem rules, Expression expression, DartType type) {
    // Specialized inference:
    if (expression is Literal) {
      return new InferredTypeLiteral(rules, expression, type);
    }
    if (expression is InstanceCreationExpression) {
      return new InferredTypeAllocation(rules, expression, type);
    }
    if (expression is FunctionExpression) {
      return new InferredTypeClosure(rules, expression, type);
    }
    return new InferredType(rules, expression, type);
  }
}

// An inferred type for a non-literal allocation site.
class InferredTypeAllocation extends InferredTypeBase {
  InferredTypeAllocation(TypeSystem rules, Expression expression, DartType type)
      : super._internal(rules, expression, type);

  @override
  String get name => 'STRONG_MODE_INFERRED_TYPE_ALLOCATION';
}

// An inferred type for the wrapped expression, which may need to be
// reified into the term
abstract class InferredTypeBase extends CoercionInfo {
  final DartType _type;

  InferredTypeBase._internal(
      TypeSystem rules, Expression expression, this._type)
      : super(rules, expression);

  @override List get arguments => [node, type];
  DartType get convertedType => type;
  @override String get message => '{0} has inferred type {1}';
  DartType get type => _type;

  toErrorCode() => new HintCode(name, message);
}

// An inferred type for a closure expression
class InferredTypeClosure extends InferredTypeBase {
  InferredTypeClosure(TypeSystem rules, Expression expression, DartType type)
      : super._internal(rules, expression, type);

  @override
  String get name => 'STRONG_MODE_INFERRED_TYPE_CLOSURE';
}

// An inferred type for a literal expression.
class InferredTypeLiteral extends InferredTypeBase {
  InferredTypeLiteral(TypeSystem rules, Expression expression, DartType type)
      : super._internal(rules, expression, type);

  @override
  String get name => 'STRONG_MODE_INFERRED_TYPE_LITERAL';
}

class InvalidFieldOverride extends InvalidOverride {
  InvalidFieldOverride(AstNode node, ExecutableElement element,
      InterfaceType base, DartType subType, DartType baseType)
      : super(node, element, base, subType, baseType);

  String get message => 'Field declaration {3}.{1} cannot be '
      'overridden in {0}.';

  @override
  String get name => 'STRONG_MODE_INVALID_FIELD_OVERRIDE';
}

// Invalid override due to incompatible type.  I.e., the overridden signature
// is not compatible with the original.
class InvalidMethodOverride extends InvalidOverride {
  InvalidMethodOverride(AstNode node, ExecutableElement element,
      InterfaceType base, FunctionType subType, FunctionType baseType)
      : super(node, element, base, subType, baseType);

  String get message => _messageHelper('Invalid override');

  @override
  String get name => 'STRONG_MODE_INVALID_METHOD_OVERRIDE';
}

// Invalid override of an instance member of a class.
abstract class InvalidOverride extends StaticError {
  /// Member declaration with the invalid override.
  final ExecutableElement element;

  /// Type (class or interface) that provides the base declaration.
  final InterfaceType base;

  /// Actual type of the overridden member.
  final DartType subType;

  /// Actual type of the base member.
  final DartType baseType;

  /// Whether the error comes from combining a base class and an interface
  final bool fromBaseClass;

  /// Whether the error comes from a mixin (either overriding a base class or an
  /// interface declaration).
  final bool fromMixin;

  InvalidOverride(
      AstNode node, this.element, this.base, this.subType, this.baseType)
      : fromBaseClass = node is ExtendsClause,
        fromMixin = node.parent is WithClause,
        super(node);

  @override List<Object> get arguments =>
      [parent.name, element.name, subType, base, baseType];

  ClassElement get parent => element.enclosingElement;

  String _messageHelper(String errorName) {
    var lcErrorName = errorName.toLowerCase();
    var intro = fromBaseClass
        ? 'Base class introduces an $lcErrorName'
        : (fromMixin ? 'Mixin introduces an $lcErrorName' : errorName);
    return '$intro. The type of {0}.{1} ({2}) is not a '
        'subtype of {3}.{1} ({4}).';
  }
}

class InvalidParameterDeclaration extends StaticError {
  final DartType expectedType;

  InvalidParameterDeclaration(
      TypeSystem rules, FormalParameter declaration, this.expectedType)
      : super(declaration);

  @override List<Object> get arguments => [node, expectedType];
  @override String get message => 'Type check failed: {0} is not of type {1}';
  @override
  String get name => 'STRONG_MODE_INVALID_PARAMETER_DECLARATION';
}

/// Dart constructors have one weird quirk, illustrated with this example:
///
///     class Base {
///       var x;
///       Base() : x = print('Base.1') {
///         print('Base.2');
///       }
///     }
///
///     class Derived extends Base {
///       var y, z;
///       Derived()
///           : y = print('Derived.1'),
///             super(),
///             z = print('Derived.2') {
///         print('Derived.3');
///       }
///     }
///
/// The order will be Derived.1, Base.1, Derived.2, Base.2, Derived.3; this
/// ordering preserves the invariant that code can't observe uninitialized
/// state, however it results in super constructor body not being run
/// immediately after super initializers. Normally this isn't observable, but it
/// could be if initializers have side effects.
///
/// Better to have `super` at the end, as required by the Dart style guide:
/// <http://goo.gl/q1T4BB>
///
/// For now this is the only pattern we support.
class InvalidSuperInvocation extends StaticError {
  InvalidSuperInvocation(SuperConstructorInvocation node) : super(node);

  @override String get message => "super call must be last in an initializer "
      "list (see http://goo.gl/q1T4BB): {0}";

  @override
  String get name => 'STRONG_MODE_INVALID_SUPER_INVOCATION';
}

class InvalidVariableDeclaration extends StaticError {
  final DartType expectedType;

  InvalidVariableDeclaration(
      TypeSystem rules, AstNode declaration, this.expectedType)
      : super(declaration);

  @override List<Object> get arguments => [expectedType];
  @override String get message => 'Type check failed: null is not of type {0}';

  @override
  String get name => 'STRONG_MODE_INVALID_VARIABLE_DECLARATION';
}

class NonGroundTypeCheckInfo extends StaticInfo {
  final DartType type;
  final AstNode node;

  NonGroundTypeCheckInfo(this.node, this.type) {
    assert(node is IsExpression || node is AsExpression);
  }

  @override List<Object> get arguments => [type];
  String get message =>
      "Runtime check on non-ground type {0} may throw StrongModeError";

  @override
  String get name => 'STRONG_MODE_NON_GROUND_TYPE_CHECK_INFO';

  toErrorCode() => new HintCode(name, message);
}

abstract class StaticError extends StaticInfo {
  final AstNode node;

  StaticError(this.node);

  String get message;

  toErrorCode() => new CompileTimeErrorCode(name, message);
}

// TODO(jmesserly): this could use some refactoring. These are essentially
// like ErrorCodes in analyzer, but we're including some details in our message.
// Analyzer instead has template strings, and replaces '{0}' with the first
// argument.
abstract class StaticInfo {
  /// Strong-mode error code names.
  ///
  /// Used for error code configuration validation in `.analysis_options`.
  static const List<String> names = const [
    //
    // Manually populated.
    //
    'STRONG_MODE_ASSIGNMENT_CAST',
    'STRONG_MODE_DOWN_CAST_COMPOSITE',
    'STRONG_MODE_DOWN_CAST_IMPLICIT',
    'STRONG_MODE_DYNAMIC_CAST',
    'STRONG_MODE_DYNAMIC_INVOKE',
    'STRONG_MODE_INFERRED_TYPE',
    'STRONG_MODE_INFERRED_TYPE_ALLOCATION',
    'STRONG_MODE_INFERRED_TYPE_CLOSURE',
    'STRONG_MODE_INFERRED_TYPE_LITERAL',
    'STRONG_MODE_INVALID_FIELD_OVERRIDE',
    'STRONG_MODE_INVALID_METHOD_OVERRIDE',
    'STRONG_MODE_INVALID_PARAMETER_DECLARATION',
    'STRONG_MODE_INVALID_SUPER_INVOCATION',
    'STRONG_MODE_INVALID_VARIABLE_DECLARATION',
    'STRONG_MODE_NON_GROUND_TYPE_CHECK_INFO',
    'STRONG_MODE_STATIC_TYPE_ERROR',
    'STRONG_MODE_UNINFERRED_CLOSURE',
  ];

  List<Object> get arguments => [node];

  String get name;

  /// AST Node this info is attached to.
  AstNode get node;

  AnalysisError toAnalysisError() {
    int begin = node is AnnotatedNode
        ? (node as AnnotatedNode).firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    int length = node.end - begin;
    var source = (node.root as CompilationUnit).element.source;
    return new AnalysisError(source, begin, length, toErrorCode(), arguments);
  }

  // TODO(jmesserly): review the usage of error codes. We probably want our own,
  // as well as some DDC specific [ErrorType]s.
  ErrorCode toErrorCode();
}

class StaticTypeError extends StaticError {
  final DartType baseType;
  final DartType expectedType;
  String reason = null;

  StaticTypeError(TypeSystem rules, Expression expression, this.expectedType,
      {this.reason})
      : baseType = expression.staticType ?? DynamicTypeImpl.instance,
        super(expression);

  @override List<Object> get arguments => [node, baseType, expectedType];
  @override String get message =>
      'Type check failed: {0} ({1}) is not of type {2}' +
      ((reason == null) ? '' : ' because $reason');

  @override
  String get name => 'STRONG_MODE_STATIC_TYPE_ERROR';
}

//
// Temporary "casts" of allocation sites - literals, constructor invocations,
// and closures.  These should be handled by contextual inference.  In most
// cases, inference will be sufficient, though in some it may unmask an actual
// error: e.g.,
//   List<int> l = [1, 2, 3]; // Inference succeeds
//   List<String> l = [1, 2, 3]; // Inference reveals static type error
// We're marking all as warnings for now.
//
// TODO(vsm,leafp): Remove this.
class UninferredClosure extends DownCast {
  UninferredClosure(TypeSystem rules, FunctionExpression expression, Cast cast)
      : super._internal(rules, expression, cast);

  @override
  String get name => 'STRONG_MODE_UNINFERRED_CLOSURE';

  toErrorCode() => new StaticTypeWarningCode(name, message);
}
