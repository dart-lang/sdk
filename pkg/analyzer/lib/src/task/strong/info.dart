// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines static information collected by the type checker and used later by
/// emitters to generate code.
// TODO(jmesserly): this was ported from package:dev_compiler, and needs to be
// refactored to fit into analyzer.
library analyzer.src.task.strong.info;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/type_system.dart';

/// Implicitly injected expression conversion.
abstract class CoercionInfo extends StaticInfo {
  static const String _propertyName = 'dev_compiler.src.info.CoercionInfo';

  final Expression node;

  CoercionInfo(this.node);

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

/// Implicit casts from base type to sub type.
class DownCast extends CoercionInfo {
  final DartType _fromType;
  final DartType _toType;
  ErrorCode _errorCode;

  DownCast._(
      Expression expression, this._fromType, this._toType, this._errorCode)
      : super(expression);

  @override
  List<Object> get arguments => [baseType, convertedType];

  /// The type being cast from.
  ///
  /// This is usually the static type of the associated expression, but may not
  /// be if the cast is attached to a variable in a for-in loop.
  @override
  DartType get baseType => _fromType;

  @override
  DartType get convertedType => _toType;

  @override
  String get message => _message;

  @override
  String get name => _errorCode.name;

  @override
  toErrorCode() => _errorCode;

  static const String _message = 'Unsound implicit cast from {0} to {1}';

  /// Factory to create correct DownCast variant.
  static StaticInfo create(StrongTypeSystemImpl rules, Expression expression,
      DartType fromType, DartType toType, AnalysisOptionsImpl options) {
    // toT <:_R fromT => to <: fromT
    // NB: classes with call methods are subtypes of function
    // types, but the function type is not assignable to the class
    assert(toType.isSubtypeOf(fromType) || fromType.isAssignableTo(toType));

    // Inference "casts":
    if (expression is Literal || expression is FunctionExpression) {
      // fromT should be an exact type - this will almost certainly fail at
      // runtime.
      return new StaticTypeError(expression, toType);
    }

    if (expression is InstanceCreationExpression) {
      ConstructorElement e = expression.staticElement;
      if (e == null || !e.isFactory) {
        // fromT should be an exact type - this will almost certainly fail at
        // runtime.
        return new StaticTypeError(expression, toType);
      }
    }

    if (StaticInfo.isKnownFunction(expression)) {
      return new StaticTypeError(expression, toType);
    }

    // TODO(vsm): Change this to an assert when we have generic methods and
    // fix TypeRules._coerceTo to disallow implicit sideways casts.
    bool downCastComposite = false;
    if (!rules.isSubtypeOf(toType, fromType)) {
      assert(toType.isSubtypeOf(fromType) || fromType.isAssignableTo(toType));
      downCastComposite = true;
    }

    // Composite cast: these are more likely to fail.
    if (!rules.isGroundType(toType)) {
      // This cast is (probably) due to our different treatment of dynamic.
      // It may be more likely to fail at runtime.
      if (fromType is InterfaceType) {
        // For class types, we'd like to allow non-generic down casts, e.g.,
        // Iterable<T> to List<T>.  The intuition here is that raw (generic)
        // casts are problematic, and we should complain about those.
        var typeArgs = fromType.typeArguments;
        downCastComposite =
            typeArgs.isEmpty || typeArgs.any((t) => t.isDynamic);
      } else {
        downCastComposite = true;
      }
    }

    var parent = expression.parent;
    String name;
    if (downCastComposite) {
      name = 'STRONG_MODE_DOWN_CAST_COMPOSITE';
    } else if (fromType.isDynamic) {
      name = 'STRONG_MODE_DYNAMIC_CAST';
    } else if (parent is VariableDeclaration &&
        parent.initializer == expression) {
      name = 'STRONG_MODE_ASSIGNMENT_CAST';
    } else {
      name = 'STRONG_MODE_DOWN_CAST_IMPLICIT';
    }

    // For the remaining cases, we allow implicit casts by default.
    // However this can be disabled with an option.
    ErrorCode errorCode;
    if (!options.implicitCasts) {
      errorCode = new CompileTimeErrorCode(name, _message);
    } else if (downCastComposite) {
      errorCode = new StaticWarningCode(name, _message);
    } else {
      errorCode = new HintCode(name, _message);
    }
    return new DownCast._(expression, fromType, toType, errorCode);
  }
}

class DynamicInvoke extends CoercionInfo {
  static const String _propertyName = 'dev_compiler.src.info.DynamicInvoke';

  DynamicInvoke(Expression expression) : super(expression);
  DartType get convertedType => DynamicTypeImpl.instance;
  String get message => '{0} requires dynamic invoke';

  @override
  String get name => 'STRONG_MODE_DYNAMIC_INVOKE';

  toErrorCode() => new HintCode(name, message);

  /// Whether this [node] is the target of a dynamic operation.
  static bool get(AstNode node) => node.getProperty(_propertyName) ?? false;

  /// Sets whether this node is the target of a dynamic operation.
  static bool set(AstNode node, bool value) {
    // Free the storage for things that aren't dynamic.
    if (value == false) value = null;
    node.setProperty(_propertyName, value);
    return value;
  }
}

/// A marker for an inferred type.
class InferredType extends CoercionInfo {
  @override
  final String name;

  final DartType type;

  InferredType(Expression expression, this.type, this.name) : super(expression);

  /// Factory to create correct InferredType variant.
  static InferredType create(
      TypeSystem rules, Expression expression, DartType type) {
    // Specialized inference:
    String name;
    if (expression is Literal) {
      name = 'STRONG_MODE_INFERRED_TYPE_LITERAL';
    } else if (expression is InstanceCreationExpression) {
      name = 'STRONG_MODE_INFERRED_TYPE_ALLOCATION';
    } else if (expression is FunctionExpression) {
      name = 'STRONG_MODE_INFERRED_TYPE_CLOSURE';
    } else {
      name = 'STRONG_MODE_INFERRED_TYPE';
    }
    return new InferredType(expression, type, name);
  }

  @override
  List get arguments => [node, type];

  DartType get convertedType => type;

  @override
  String get message => '{0} has inferred type {1}';

  toErrorCode() => new HintCode(name, message);
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

/// Invalid override due to incompatible type.  I.e., the overridden signature
/// is not compatible with the original.
class InvalidMethodOverride extends InvalidOverride {
  InvalidMethodOverride(AstNode node, ExecutableElement element,
      InterfaceType base, FunctionType subType, FunctionType baseType)
      : super(node, element, base, subType, baseType);

  String get message => _messageHelper('Invalid override');

  @override
  String get name => 'STRONG_MODE_INVALID_METHOD_OVERRIDE';
}

/// Invalid override of an instance member of a class.
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

  @override
  List<Object> get arguments =>
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

  @override
  List<Object> get arguments => [node, expectedType];
  @override
  String get message => 'Type check failed: {0} is not of type {1}';
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
/// <https://goo.gl/EY6hDP>
///
/// For now this is the only pattern we support.
class InvalidSuperInvocation extends StaticError {
  InvalidSuperInvocation(SuperConstructorInvocation node) : super(node);

  @override
  String get message => "super call must be last in an initializer "
      "list (see https://goo.gl/EY6hDP): {0}";

  @override
  String get name => 'STRONG_MODE_INVALID_SUPER_INVOCATION';
}

class InvalidVariableDeclaration extends StaticError {
  final DartType expectedType;

  InvalidVariableDeclaration(
      TypeSystem rules, AstNode declaration, this.expectedType)
      : super(declaration);

  @override
  List<Object> get arguments => [expectedType];
  @override
  String get message => 'Type check failed: null is not of type {0}';

  @override
  String get name => 'STRONG_MODE_INVALID_VARIABLE_DECLARATION';
}

class NonGroundTypeCheckInfo extends StaticInfo {
  final DartType type;
  final AstNode node;

  NonGroundTypeCheckInfo(this.node, this.type) {
    assert(node is IsExpression || node is AsExpression);
  }

  @override
  List<Object> get arguments => [type];
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
  /// Used for error code configuration validation in an analysis options file.
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

  static bool isKnownFunction(Expression expression) {
    Element element = null;
    if (expression is FunctionExpression) {
      return true;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    } else if (expression is Identifier) {
      element = expression.staticElement;
    }
    // First class functions and static methods, where we know the original
    // declaration, will have an exact type, so we know a downcast will fail.
    return element is FunctionElement ||
        element is MethodElement && element.isStatic;
  }
}

class StaticTypeError extends StaticError {
  final DartType baseType;
  final DartType expectedType;

  StaticTypeError(Expression expression, this.expectedType)
      : baseType = expression.staticType ?? DynamicTypeImpl.instance,
        super(expression);

  @override
  List<Object> get arguments => [node, baseType, expectedType];
  @override
  String get message => 'Type check failed: {0} ({1}) is not of type {2}';

  @override
  String get name => 'STRONG_MODE_STATIC_TYPE_ERROR';
}
