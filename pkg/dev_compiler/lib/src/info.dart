/// Defines static information collected by the type checker and used later by
/// emitters to generate code.
library ddc.src.info;

import 'dart:mirrors';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:logging/logging.dart' show Level;

import 'checker/rules.dart';

/// Represents a summary of the results collected by running the program
/// checker.
class CheckerResults {
  final List<LibraryElement> libraries;
  final Map<AstNode, SemanticNode> infoMap;
  final TypeRules rules;
  final bool failure;

  CheckerResults(this.libraries, this.infoMap, this.rules, this.failure);
}

/// Semantic information about a node.
// TODO(jmesserly): this structure is very incomplete.
class SemanticNode {
  /// The syntax tree node this info is attached to.
  final AstNode node;

  /// If this operation is dynamically dispatched, this will be set.
  DynamicInvoke dynamicInvoke;

  /// Any other error or warning messages about this node.
  /// These messages are not used when generating code.
  final messages = <StaticInfo>[];

  SemanticNode(this.node);
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
}

class Box extends Conversion {
  Box(TypeRules rules, Expression expression) : super(rules, expression);

  DartType _getConvertedType() {
    assert(rules.isBoxable(baseType));
    return rules.boxedType(baseType);
  }

  bool get safe => true;

  String get message => '$expression ($baseType) must be boxed';

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitBox(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

class Unbox extends Conversion {
  DartType _unboxedType;

  Unbox(TypeRules rules, Expression expression, this._unboxedType)
      : super(rules, expression) {
    assert(rules.isBoxable(_unboxedType));
  }

  DartType _getConvertedType() => _unboxedType;

  // TODO(vsm): Could be safe for num->double and once we represent boxed int
  // and boxed double.
  bool get safe => false;

  String get message =>
      '$expression ($baseType) must be unboxed to type $convertedType';

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitUnbox(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

class DownCast extends Conversion {
  DartType _newType;

  DownCast(TypeRules rules, Expression expression, this._newType)
      : super(rules, expression) {
    assert(_newType != baseType &&
        (baseType.isDynamic || rules.isSubTypeOf(_newType, baseType)));
  }

  DartType _getConvertedType() => _newType;

  String get message => '$expression ($baseType) will need runtime check '
      'to cast to type $convertedType';

  // Differentiate between Function down cast and non-Function down cast?  The
  // former seems less likely to actually succeed.
  Level get level => (_newType is FunctionType) ? Level.WARNING : super.level;

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitDownCast(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

class ClosureWrap extends Conversion {
  FunctionType _wrappedType;

  ClosureWrap(TypeRules rules, Expression expression, this._wrappedType)
      : super(rules, expression) {
    assert(baseType is FunctionType);
    assert(!rules.isSubTypeOf(_wrappedType, baseType));
  }

  DartType _getConvertedType() => _wrappedType;

  String get message => '$expression ($baseType) will need to be wrapped '
      'with a closure of type $convertedType';

  Level get level => Level.WARNING;

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitClosureWrap(this);
    } else {
      return expression.accept(visitor);
    }
  }
}

class NumericConversion extends Conversion {
  // int to double only?

  NumericConversion(TypeRules rules, Expression expression)
      : super(rules, expression) {
    assert(baseType.displayName == rules.provider.intType);
  }

  bool get safe => true;

  DartType _getConvertedType() => rules.provider.doubleType;

  String get message =>
      '$expression ($baseType) should be converted to type $convertedType';

  accept(AstVisitor visitor) {
    if (visitor is ConversionVisitor) {
      return visitor.visitNumericConversion(this);
    } else {
      return expression.accept(visitor);
    }
  }
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

  InvalidOverride(AstNode node, this.element, this.base) : super(node);

  ClassDeclaration get parent =>
      element.enclosingElement.node as ClassDeclaration;
}

// Invalid override due to incompatible type.  I.e., the overridden signature
// is not compatible with the original.
class InvalidMethodOverride extends InvalidOverride {
  final FunctionType methodType;
  final FunctionType baseType;

  InvalidMethodOverride(AstNode node, ExecutableElement element,
      InterfaceType base, this.methodType, this.baseType)
      : super(node, element, base);

  String get message {
    return 'Invalid override for ${element.name} in ${parent.name} '
        'over $base: $methodType does not subtype $baseType';
  }
}

// TODO(vsm): Do we still need this?
// Under certain rules, we disallow overriding a field with a
// field/getter/setter.
class InvalidFieldOverride extends InvalidOverride {
  InvalidFieldOverride(
      AstNode node, ExecutableElement element, InterfaceType base)
      : super(node, element, base);

  String get message {
    return 'Invalid field override for ${element.name} in '
        '${parent.name} over $base';
  }
}

/// A simple generalizing visitor interface for the conversion nodes.
/// This can be mixed in to your visitor if the AST can contain these nodes.
abstract class ConversionVisitor<R> {
  /// This method must be implemented. It is typically supplied by the base
  /// GeneralizingAstVisitor<R>.
  R visitNode(AstNode node);

  /// The catch-all for any kind of converison
  R visitConversion(Conversion node) => visitNode(node);

  // Methods for conversion subtypes:

  R visitBox(Box node) => visitConversion(node);
  R visitUnbox(Unbox node) => visitConversion(node);
  R visitDownCast(DownCast node) => visitConversion(node);
  R visitClosureWrap(ClosureWrap node) => visitConversion(node);
  R visitNumericConversion(NumericConversion node) => visitConversion(node);
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
  return new List<Type>.from(allTypes.map((mirror) => mirror.reflectedType));
}();

main() => print(infoTypes);
