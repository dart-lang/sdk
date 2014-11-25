/// Defines static information collected by the type checker.
library ddc.src.static_info;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' show Level;

import 'type_rules.dart';

abstract class StaticInfo {
  // AST Node this info is attached to.
  AstNode get node;

  // Log level for error messages.  This is a placeholder
  // for severity.
  Level get level;

  // Description / error message.
  String get message;
}

abstract class TypeMismatch extends StaticInfo {
  final TypeRules rules;
  final Expression expression;
  AstNode get node => expression;

  TypeMismatch(this.rules, this.expression);

  DartType get baseType => rules.getStaticType(expression);
}

class StaticTypeError extends TypeMismatch {
  DartType expectedType;

  StaticTypeError(TypeRules rules, Expression expression, this.expectedType)
      : super(rules, expression);

  String get message =>
      'Type check failed: $expression ($baseType) is not of type $expectedType';

  Level get level => Level.SEVERE;
}

// Implicitly injected expression conversion.
abstract class Conversion extends TypeMismatch {
  DartType _convertedType;

  Conversion(TypeRules rules, Expression expression)
      : super(rules, expression) {
    this._convertedType = _getConvertedType();
  }

  DartType get convertedType => _convertedType;

  DartType _getConvertedType();

  // safe iff this cannot throw
  bool get safe => false;

  Level get level => safe ? Level.CONFIG : Level.INFO;

  String get description =>
      '${this.runtimeType}: $baseType to $convertedType';
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
    assert(_newType != baseType && (baseType.isDynamic || rules
        .isSubTypeOf(_newType, baseType)));
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

class InvalidRuntimeCheckError extends StaticInfo {
  final AstNode node;
  final DartType type;

  InvalidRuntimeCheckError(this.node, this.type) {
    assert(node is IsExpression || node is AsExpression);
  }

  String get message => "Invalid runtime check on non-ground type $type";

  Level get level => Level.SEVERE;
}

class InvalidOverride extends StaticInfo {
  final AstNode node;
  final ExecutableElement element;
  final InterfaceType base;
  final FunctionType methodType;
  final FunctionType baseType;
  // TODO(vsm): Refactor to a different class.
  final bool fieldOverride;

  InvalidOverride(this.node, this.element, this.base, this.methodType,
      this.baseType, [this.fieldOverride = false]);

  ClassDeclaration get parent =>
      element.enclosingElement.node as ClassDeclaration;
  String get message {
    if (fieldOverride) {
      return 'Invalid field override for ${element.name} in '
          '${parent.name} over $base';
    } else {
      return 'Invalid override for ${element.name} in ${parent.name} '
          'over $base: $methodType does not subtype $baseType';
    }
  }

  Level get level => Level.SEVERE;
}
