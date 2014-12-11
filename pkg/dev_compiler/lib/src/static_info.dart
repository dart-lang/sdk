/// Defines static information collected by the type checker.
library ddc.src.static_info;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:logging/logging.dart' show Level;

import 'type_rules.dart';

/// Represents a summary of the results collected by running the program
/// checker.
class CheckerResults {
  final Map<Uri, LibraryInfo> libraries;
  final Map<AstNode, SemanticNode> infoMap;
  final TypeRules rules;
  final bool failure;

  CheckerResults(this.libraries, this.infoMap, this.rules, this.failure);
}

/// Holds information about a Dart library.
class LibraryInfo {
  final Uri uri;
  final Source source;
  final CompilationUnit lib;
  final Map<Uri, CompilationUnit> parts = new Map<Uri, CompilationUnit>();
  final Map<Uri, LibraryInfo> imports = new Map<Uri, LibraryInfo>();

  LibraryInfo(this.uri, this.source, this.lib);
}

/// Semantic information about a node.
// TODO(jmesserly): this structure is very incomplete.
class SemanticNode {
  /// The syntax tree node this info is attached to.
  final AstNode node;

  /// The conversion or check to apply, if any. Otherwise null.
  /// Only relevant for expressions.
  Conversion conversion;

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

// Implicitly injected expression conversion.
abstract class Conversion extends StaticInfo {
  final TypeRules rules;
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
}

class Box extends Conversion {
  Box(TypeRules rules, Expression expression) : super(rules, expression);

  DartType _getConvertedType() {
    assert(rules.isBoxable(baseType));
    return rules.boxedType(baseType);
  }

  bool get safe => true;

  String get message => '$expression ($baseType) must be boxed';
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
}

class DynamicInvoke extends Conversion {
  DynamicInvoke(TypeRules rules, Expression expression)
      : super(rules, expression);

  DartType _getConvertedType() => rules.provider.dynamicType;

  String get message => '$expression requires dynamic invoke';
  Level get level => Level.WARNING;
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
