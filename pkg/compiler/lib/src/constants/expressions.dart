// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions;

import '../dart2jslib.dart' show assertDebugMode;
import '../dart_types.dart';
import '../elements/elements.dart' show
    Element,
    FunctionElement,
    VariableElement;
import '../universe/universe.dart' show Selector;
import 'values.dart';

/// An expression that is a compile-time constant.
///
/// Whereas [ConstantValue] represent a compile-time value, a
/// [ConstantExpression] represents an expression for creating a constant.
///
/// There is no one-to-one mapping between [ConstantExpression] and
/// [ConstantValue], because different expressions can denote the same constant.
/// For instance, multiple `const` constructors may be used to create the same
/// object, and different `const` variables may hold the same value.
abstract class ConstantExpression {
  /// Returns the value of this constant expression.
  ConstantValue get value;

  // TODO(johnniwinther): Unify precedence handled between constants, front-end
  // and back-end.
  int get precedence => 16;

  accept(ConstantExpressionVisitor visitor, [context]);

  String getText() {
    ConstExpPrinter printer = new ConstExpPrinter();
    accept(printer);
    return printer.toString();
  }

  String toString() {
    assertDebugMode('Use ConstantExpression.getText() instead of '
                    'ConstantExpression.toString()');
    return getText();
  }
}

/// Boolean, int, double, string, or null constant.
class PrimitiveConstantExpression extends ConstantExpression {
  final PrimitiveConstantValue value;

  PrimitiveConstantExpression(this.value) {
    assert(value != null);
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitPrimitive(this, context);
  }
}

/// Literal list constant.
class ListConstantExpression extends ConstantExpression {
  final ListConstantValue value;
  final InterfaceType type;
  final List<ConstantExpression> values;

  ListConstantExpression(this.value, this.type, this.values);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitList(this, context);
  }
}

/// Literal map constant.
class MapConstantExpression extends ConstantExpression {
  final MapConstantValue value;
  final InterfaceType type;
  final List<ConstantExpression> keys;
  final List<ConstantExpression> values;

  MapConstantExpression(this.value, this.type, this.keys, this.values);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitMap(this, context);
  }
}

/// Invocation of a const constructor.
class ConstructedConstantExpresssion extends ConstantExpression {
  final ConstantValue value;
  final InterfaceType type;
  final FunctionElement target;
  final Selector selector;
  final List<ConstantExpression> arguments;

  ConstructedConstantExpresssion(this.value,
                      this.type,
                      this.target,
                      this.selector,
                      this.arguments) {
    assert(type.element == target.enclosingClass);
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConstructed(this, context);
  }
}

/// String literal with juxtaposition and/or interpolations.
// TODO(johnniwinther): Do we need this?
class ConcatenateConstantExpression extends ConstantExpression {
  final StringConstantValue value;
  final List<ConstantExpression> arguments;

  ConcatenateConstantExpression(this.value, this.arguments);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConcatenate(this, context);
  }
}

/// Symbol literal.
class SymbolConstantExpression extends ConstantExpression {
  final ConstructedConstantValue value;
  final String name;

  SymbolConstantExpression(this.value, this.name);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitSymbol(this, context);
  }
}

/// Type literal.
class TypeConstantExpression extends ConstantExpression {
  final TypeConstantValue value;
  /// Either [DynamicType] or a raw [GenericType].
  final DartType type;

  TypeConstantExpression(this.value, this.type) {
    assert(type is GenericType || type is DynamicType);
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitType(this, context);
  }
}

/// Reference to a constant local, top-level, or static variable.
class VariableConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final VariableElement element;

  VariableConstantExpression(this.value, this.element);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitVariable(this, context);
  }
}

/// Reference to a top-level or static function.
class FunctionConstantExpression extends ConstantExpression {
  final FunctionConstantValue value;
  final FunctionElement element;

  FunctionConstantExpression(this.value, this.element);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitFunction(this, context);
  }
}

/// A constant binary expression like `a * b` or `identical(a, b)`.
class BinaryConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final ConstantExpression left;
  final String operator;
  final ConstantExpression right;

  BinaryConstantExpression(this.value, this.left, this.operator, this.right) {
    assert(PRECEDENCE_MAP[operator] != null);
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBinary(this, context);
  }

  int get precedence => PRECEDENCE_MAP[operator];

  static const Map<String, int> PRECEDENCE_MAP = const {
    'identical': 15,
    '==': 6,
    '!=': 6,
    '&&': 5,
    '||': 4,
    '^': 9,
    '&': 10,
    '|': 8,
    '>>': 11,
    '<<': 11,
    '+': 12,
    '-': 12,
    '*': 13,
    '/': 13,
    '~/': 13,
    '>': 7,
    '<': 7,
    '>=': 7,
    '<=': 7,
    '%': 13,
  };
}

/// A unary constant expression like `-a`.
class UnaryConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final String operator;
  final ConstantExpression expression;

  UnaryConstantExpression(this.value, this.operator, this.expression) {
    assert(PRECEDENCE_MAP[operator] != null);
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitUnary(this, context);
  }

  int get precedence => PRECEDENCE_MAP[operator];

  static const Map<String, int> PRECEDENCE_MAP = const {
    '!': 14,
    '~': 14,
    '-': 14,
  };
}

/// A constant conditional expression like `a ? b : c`.
class ConditionalConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final ConstantExpression condition;
  final ConstantExpression trueExp;
  final ConstantExpression falseExp;

  ConditionalConstantExpression(this.value,
                                this.condition,
                                this.trueExp,
                                this.falseExp);

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConditional(this, context);
  }

  int get precedence => 3;
}

abstract class ConstantExpressionVisitor<C, R> {
  const ConstantExpressionVisitor();

  R visit(ConstantExpression constant, [C context]) {
    return constant.accept(this, context);
  }

  R visitPrimitive(PrimitiveConstantExpression exp, [C context]);
  R visitList(ListConstantExpression exp, [C context]);
  R visitMap(MapConstantExpression exp, [C context]);
  R visitConstructed(ConstructedConstantExpresssion exp, [C context]);
  R visitConcatenate(ConcatenateConstantExpression exp, [C context]);
  R visitSymbol(SymbolConstantExpression exp, [C context]);
  R visitType(TypeConstantExpression exp, [C context]);
  R visitVariable(VariableConstantExpression exp, [C context]);
  R visitFunction(FunctionConstantExpression exp, [C context]);
  R visitBinary(BinaryConstantExpression exp, [C context]);
  R visitUnary(UnaryConstantExpression exp, [C context]);
  R visitConditional(ConditionalConstantExpression exp, [C context]);
}

/// Represents the declaration of a constant [element] with value [expression].
// TODO(johnniwinther): Where does this class belong?
class ConstDeclaration {
  final VariableElement element;
  final ConstantExpression expression;

  ConstDeclaration(this.element, this.expression);
}

class ConstExpPrinter extends ConstantExpressionVisitor {
  final StringBuffer sb = new StringBuffer();

  write(ConstantExpression parent,
        ConstantExpression child,
        {bool leftAssociative: true}) {
    if (child.precedence < parent.precedence ||
        !leftAssociative && child.precedence == parent.precedence) {
      sb.write('(');
      child.accept(this);
      sb.write(')');
    } else {
      child.accept(this);
    }
  }

  writeTypeArguments(InterfaceType type) {
    if (type.treatAsRaw) return;
    sb.write('<');
    bool needsComma = false;
    for (DartType value in type.typeArguments) {
      if (needsComma) {
        sb.write(', ');
      }
      sb.write(value);
      needsComma = true;
    }
    sb.write('>');
  }

  visitPrimitive(PrimitiveConstantExpression exp, [_]) {
    sb.write(exp.value.unparse());
  }

  visitList(ListConstantExpression exp, [_]) {
    sb.write('const ');
    writeTypeArguments(exp.type);
    sb.write('[');
    bool needsComma = false;
    for (ConstantExpression value in exp.values) {
      if (needsComma) {
        sb.write(', ');
      }
      visit(value);
      needsComma = true;
    }
    sb.write(']');
  }

  visitMap(MapConstantExpression exp, [_]) {
    sb.write('const ');
    writeTypeArguments(exp.type);
    sb.write('{');
    for (int index = 0; index < exp.keys.length; index++) {
      if (index > 0) {
        sb.write(', ');
      }
      visit(exp.keys[index]);
      sb.write(': ');
      visit(exp.values[index]);
    }
    sb.write('}');
  }

  visitConstructed(ConstructedConstantExpresssion exp, [_]) {
    sb.write('const ');
    sb.write(exp.target.enclosingClass.name);
    if (exp.target.name != '') {
      sb.write('.');
      sb.write(exp.target.name);
    }
    writeTypeArguments(exp.type);
    sb.write('(');
    bool needsComma = false;

    int namedOffset = exp.selector.positionalArgumentCount;
    for (int index = 0; index < namedOffset; index++) {
      if (needsComma) {
        sb.write(', ');
      }
      visit(exp.arguments[index]);
      needsComma = true;
    }
    for (int index = 0; index < exp.selector.namedArgumentCount; index++) {
      if (needsComma) {
        sb.write(', ');
      }
      sb.write(exp.selector.namedArguments[index]);
      sb.write(': ');
      visit(exp.arguments[namedOffset + index]);
      needsComma = true;
    }
    sb.write(')');
  }

  visitConcatenate(ConcatenateConstantExpression exp, [_]) {
    sb.write(exp.value.unparse());
  }

  visitSymbol(SymbolConstantExpression exp, [_]) {
    sb.write('#');
    sb.write(exp.name);
  }

  visitType(TypeConstantExpression exp, [_]) {
    sb.write(exp.type.name);
  }

  visitVariable(VariableConstantExpression exp, [_]) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  visitFunction(FunctionConstantExpression exp, [_]) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  visitBinary(BinaryConstantExpression exp, [_]) {
    if (exp.operator == 'identical') {
      sb.write('identical(');
      visit(exp.left);
      sb.write(', ');
      visit(exp.right);
      sb.write(')');
    } else {
      write(exp, exp.left);
      sb.write(' ');
      sb.write(exp.operator);
      sb.write(' ');
      write(exp, exp.right);
    }
  }

  visitUnary(UnaryConstantExpression exp, [_]) {
    sb.write(exp.operator);
    write(exp, exp.expression);
  }

  visitConditional(ConditionalConstantExpression exp, [_]) {
    write(exp, exp.condition, leftAssociative: false);
    sb.write(' ? ');
    write(exp, exp.trueExp);
    sb.write(' : ');
    write(exp, exp.falseExp);
  }

  String toString() => sb.toString();
}