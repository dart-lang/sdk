/// Defines static information collected by the type checker and used later by
/// emitters to generate code.
library ddc.src.info;

import 'dart:mirrors';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:logging/logging.dart' show Level;

import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/utils.dart' as utils;

/// Represents a summary of the results collected by running the program
/// checker.
class CheckerResults {
  final List<LibraryInfo> libraries;
  final TypeRules rules;
  final bool failure;

  CheckerResults(this.libraries, this.rules, this.failure);
}

/// Computed information about each library.
class LibraryInfo {
  /// Name of the library. If not specified in a library directive, this is
  /// inferred from the path to the file defining the library.
  String name;

  /// Corresponding analyzer element.
  final LibraryElement library;

  LibraryInfo(this.library) {
    name = utils.libraryNameFromLibraryElement(library);
  }
}

// The abstract type of coercions mapping one type to another.
// This class also exposes static builder functions which
// check for errors and reduce redundant coercions to the identity.
abstract class Coercion {
  final DartType fromType;
  final DartType toType;
  Coercion(this.fromType, this.toType);
  static Coercion cast(DartType fromT, DartType toT) => new Cast(fromT, toT);
  static Coercion identity(DartType type) => new Identity(type);
  static Coercion error() => new CoercionError();
  static Coercion wrapper(DartType fromType, DartType toType,
                          List<Coercion> normalParameters,
                          List<Coercion> optionalParameters,
                          Map<String, Coercion> namedParameters,
                          Coercion ret) {
    {
      // If any sub coercion is error, return error
      bool isError(Coercion c) => c is CoercionError;
      if (ret is CoercionError) return error();
      if (namedParameters.values.any(isError)) return error();
      if (normalParameters.any(isError)) return error();
      if (optionalParameters.any(isError)) return error();
    }
    {
      // If all sub coercions are the identity, return identity
      bool folder(bool id, Coercion c) => id && (c is Identity);
      bool id = (ret is CoercionError);
      id = namedParameters.values.fold(id, folder);
      id = normalParameters.fold(id, folder);
      id = optionalParameters.fold(id, folder);
      if (id) return identity(fromType);
    }
    return new Wrapper(fromType, toType, normalParameters, optionalParameters,
        namedParameters, ret);
  }
}

// Coercion which casts one type to another
class Cast extends Coercion {
  Cast(DartType fromType, DartType toType) : super(fromType, toType);
}

// The identity coercion
class Identity extends Coercion {
  Identity(DartType fromType) : super(fromType, fromType);
}

// A closure wrapper coercion.
// The parameter coercions are the coercions which should
// be applied to coerce the wrapper parameters to the
// appropriate type for the wrapped closure.
// The return coercion is appropriate to coerce the return
// value of the wrapped function to the type expected by the
// context.
class Wrapper extends Coercion {
  final Map<String, Coercion> namedParameters;
  final List<Coercion> normalParameters;
  final List<Coercion> optionalParameters;
  final Coercion ret;
  Wrapper(DartType fromType, DartType toType, this.normalParameters,
      this.optionalParameters, this.namedParameters, this.ret)
      : super(fromType, toType);
}

// The error coercion.  This coercion signals that a coercion
// could not be generated.  The code generator should not see
// these.
class CoercionError extends Coercion {
  CoercionError() : super(null, null);
}

abstract class StaticInfo {
  /// AST Node this info is attached to.
  // TODO(jmesserly): this is somewhat redundant with SemanticNode.
  AstNode get node;

  /// Log level for error messages.  This is a placeholder
  /// for severity.
  Level get level;

  /// Description / error message.
  String get message;
}

/// Implicitly injected expression conversion.
// TODO(jmesserly): rename to have Expression suffix?
abstract class Conversion extends Expression implements StaticInfo {
  final TypeRules rules;

  // TODO(jmesserly): should probably rename this "operand" for consistency with
  // analyzer's unary expressions (e.g. PrefixExpression).
  final Expression expression;

  AstNode get node => expression;
  DartType _convertedType;

  Conversion(this.rules, this.expression) {
    this._convertedType = _getConvertedType();
  }

  DartType get baseType => rules.getStaticType(expression);
  DartType get convertedType => _convertedType;

  DartType _getConvertedType();

  // safe iff this cannot throw
  bool get safe => false;

  Level get level => safe ? Level.CONFIG : Level.INFO;

  String get description => '${this.runtimeType}: $baseType to $convertedType';

  Token get beginToken => expression.beginToken;
  Token get endToken => expression.endToken;

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  // Use same precedence as MethodInvocation.
  int get precedence => 15;
}

// A down cast from a subtype to a supertype.  This must be checked at
// runtime to recover soundness.
abstract class DownCastBase extends Conversion {
  Cast _cast;

  DownCastBase._internal(TypeRules rules, Expression expression, this._cast)
      : super(rules, expression) {
    assert(_cast.toType != baseType &&
        _cast.fromType == baseType &&
        (baseType.isDynamic || rules.isSubTypeOf(_cast.toType, baseType)));
  }

  Cast get cast => _cast;

  DartType _getConvertedType() => _cast.toType;

  String get message => '$expression ($baseType) will need runtime check '
      'to cast to type $convertedType';

  // Differentiate between Function down cast and non-Function down cast?  The
  // former seems less likely to actually succeed.
  Level get level =>
      (_cast.toType is FunctionType) ? Level.WARNING : super.level;

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitDownCastBase(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

// Standard / unspecialized down cast.
class DownCast extends DownCastBase {
  DownCast(TypeRules rules, Expression expression, Cast cast) :
    super._internal(rules, expression, cast);
}

// A down cast that would be "unnecessary" with standard Dart rules.
// E.g., the fromType <: toType in standard Dart but not in our restricted
// rules.  These occur due to our stricter rules on dynamic type parameters in
// generics.
class DownCastDynamic extends DownCastBase {
  DownCastDynamic(TypeRules rules, Expression expression, Cast cast) :
    super._internal(rules, expression, cast);

  final Level level = Level.WARNING;
}

// A down cast on a literal expression.  This should never succeed.
// TODO(vsm): Mark as severe / error?
class DownCastLiteral extends DownCastBase {
  DownCastLiteral(TypeRules rules, Expression expression, Cast cast) :
    super._internal(rules, expression, cast);

  final Level level = Level.WARNING;
}

// A down cast on a non-literal allocation site.  This should never succeed.
// TODO(vsm): Mark as severe / error?
class DownCastExact extends DownCastBase {
  DownCastExact(TypeRules rules, Expression expression, Cast cast) :
    super._internal(rules, expression, cast);

  final Level level = Level.WARNING;
}

// A wrapped closure coerces the underlying type to the desired type.
class ClosureWrapBase extends Conversion {
  FunctionType _wrappedType;
  Wrapper _wrapper;

  ClosureWrapBase._internal(
      TypeRules rules, Expression expression, this._wrapper, this._wrappedType)
      : super(rules, expression) {
    assert(baseType is FunctionType);
    assert(!rules.isSubTypeOf(baseType, _wrappedType));
  }

  DartType _getConvertedType() => _wrappedType;

  String get message => '$expression ($baseType) will need to be wrapped '
      'with a closure of type $convertedType';

  Level get level => Level.WARNING;

  Wrapper get wrapper => _wrapper;

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitClosureWrapBase(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

// Standard closure wrapping.
class ClosureWrap extends ClosureWrapBase {
  ClosureWrap(TypeRules rules, Expression expression, Wrapper wrapper,
      FunctionType wrappedType)
      : super._internal(rules, expression, wrapper, wrappedType);
}

// "Wrapping" of an inline closure.  This could be optimized and / or we
// could propagate the types into the literal.
class ClosureWrapLiteral extends ClosureWrapBase {
  ClosureWrapLiteral(TypeRules rules, Expression expression, Wrapper wrapper,
      FunctionType wrappedType)
      : super._internal(rules, expression, wrapper, wrappedType);
}

class DynamicInvoke extends Conversion {
  DynamicInvoke(TypeRules rules, Expression expression)
      : super(rules, expression);

  DartType _getConvertedType() => rules.provider.dynamicType;

  String get message => '$expression requires dynamic invoke';
  Level get level => Level.WARNING;

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitDynamicInvoke(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

abstract class StaticError extends StaticInfo {
  final AstNode node;

  StaticError(this.node);

  Level get level => Level.SEVERE;
}

class StaticTypeError extends StaticError {
  final DartType baseType;
  final DartType expectedType;

  StaticTypeError(TypeRules rules, Expression expression, this.expectedType)
      : baseType = rules.getStaticType(expression),
        super(expression);

  String get message =>
      'Type check failed: $node ($baseType) is not of type $expectedType';

  Level get level => Level.SEVERE;
}

class InvalidRuntimeCheckError extends StaticError {
  final DartType type;

  InvalidRuntimeCheckError(AstNode node, this.type) : super(node) {
    assert(node is IsExpression || node is AsExpression);
  }

  String get message => "Invalid runtime check on non-ground type $type";
}

// Invalid override of an instance member of a class.
abstract class InvalidOverride extends StaticError {
  final ExecutableElement element;
  final InterfaceType base;
  final DartType subType;
  final DartType baseType;

  InvalidOverride(
      AstNode node, this.element, this.base, this.subType, this.baseType)
      : super(node);

  ClassDeclaration get parent =>
      element.enclosingElement.node as ClassDeclaration;
}

// Invalid override due to incompatible type.  I.e., the overridden signature
// is not compatible with the original.
class InvalidMethodOverride extends InvalidOverride {
  InvalidMethodOverride(AstNode node, ExecutableElement element,
      InterfaceType base, FunctionType subType, FunctionType baseType)
      : super(node, element, base, subType, baseType);

  String get message {
    return 'Invalid override for ${element.name} in ${parent.name} '
        'over $base: $subType does not subtype $baseType';
  }
}

// TODO(sigmund): delete, if we fix this, this should be part of the type
// inference, not something we detect in the checker.
// TODO(sigmund): split and track field, getter, setter, method separately
class InferableOverride extends InvalidOverride {
  InferableOverride(AstNode node, ExecutableElement element, InterfaceType base,
      DartType subType, DartType baseType)
      : super(node, element, base, subType, baseType);

  Level get level => Level.WARNING;

  String get message {
    return 'Invalid but inferrable override for ${element.name} in '
        '${parent.name} over $base: $subType does not subtype $baseType';
  }
}

/// Used to mark unexpected situations in our compiler were we couldn't compute
/// the type of an expression.
// TODO(sigmund): This is normally a result of another error that is caught by
// the analyzer, so this should likely be removed in the future.
class MissingTypeError extends StaticInfo {
  final AstNode node;
  Level get level => Level.WARNING;

  String get message =>
      "type analysis didn't compute the type of: $node ${node.runtimeType}";
  MissingTypeError(this.node);
}

/// A simple generalizing visitor interface for the conversion nodes.
/// This can be mixed in to your visitor if the AST can contain these nodes.
abstract class ConversionVisitor<R> implements AstVisitor<R> {
  /// This method must be implemented. It is typically supplied by the base
  /// GeneralizingAstVisitor<R>.
  R visitNode(AstNode node);

  /// The catch-all for any kind of conversion
  R visitConversion(Conversion node) => visitNode(node);

  // Methods for conversion subtypes:
  R visitDownCastBase(DownCastBase node) => visitConversion(node);
  R visitDownCast(DownCastDynamic node) => visitDownCastBase(node);
  R visitDownCastDynamic(DownCastDynamic node) => visitDownCastBase(node);
  R visitDownCastExact(DownCastDynamic node) => visitDownCastBase(node);
  R visitClosureWrapBase(ClosureWrapBase node) => visitConversion(node);
  R visitClosureWrap(ClosureWrap node) => visitClosureWrapBase(node);
  R visitDynamicInvoke(DynamicInvoke node) => visitConversion(node);
}

/// Automatically infer list of types by scanning this library using mirrors.
final List<Type> infoTypes = () {
  var allTypes = new Set();
  var baseTypes = new Set();
  var lib = currentMirrorSystem().findLibrary(#ddc.src.info);
  var infoMirror = reflectClass(StaticInfo);
  for (var cls in lib.declarations.values.where((d) => d is ClassMirror)) {
    if (cls.isSubtypeOf(infoMirror)) {
      allTypes.add(cls);
      baseTypes.add(cls.superclass);
    }
  }
  allTypes.removeAll(baseTypes);
  return new List<Type>.from(allTypes.map((mirror) => mirror.reflectedType))
    ..sort((t1, t2) => '$t1'.compareTo('$t2'));
}();
