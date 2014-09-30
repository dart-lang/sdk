// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library const_expression;

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
/// Whereas [Constant] represent a compile-time value, a [ConstExp]
/// represents an expression for creating a constant.
///
/// There is no one-to-one mapping between [ConstExp] and [Constant], because
/// different expressions can denote the same constant. For instance,
/// multiple `const` constructors may be used to create the same object, and
/// different `const` variables may hold the same value.
abstract class ConstExp {
  /// Returns the value of this constant expression.
  Constant get value;

  // TODO(johnniwinther): Unify precedence handled between constants, front-end
  // and back-end.
  int get precedence => 16;

  accept(ConstExpVisitor visitor);

  String getText() {
    ConstExpPrinter printer = new ConstExpPrinter();
    accept(printer);
    return printer.toString();
  }

  String toString() {
    assertDebugMode('Use ConstExp.getText() instead of ConstExp.toString()');
    return getText();
  }
}

/// Boolean, int, double, string, or null constant.
class PrimitiveConstExp extends ConstExp {
  final PrimitiveConstant value;

  PrimitiveConstExp(this.value) {
    assert(value != null);
  }

  accept(ConstExpVisitor visitor) => visitor.visitPrimitive(this);
}

/// Literal list constant.
class ListConstExp extends ConstExp {
  final ListConstant value;
  final InterfaceType type;
  final List<ConstExp> values;

  ListConstExp(this.value, this.type, this.values);

  accept(ConstExpVisitor visitor) => visitor.visitList(this);
}

/// Literal map constant.
class MapConstExp extends ConstExp {
  final MapConstant value;
  final InterfaceType type;
  final List<ConstExp> keys;
  final List<ConstExp> values;

  MapConstExp(this.value, this.type, this.keys, this.values);

  accept(ConstExpVisitor visitor) => visitor.visitMap(this);
}

/// Invocation of a const constructor.
class ConstructorConstExp extends ConstExp {
  final Constant value;
  final InterfaceType type;
  final FunctionElement target;
  final Selector selector;
  final List<ConstExp> arguments;

  ConstructorConstExp(this.value,
                      this.type,
                      this.target,
                      this.selector,
                      this.arguments) {
    assert(type.element == target.enclosingClass);
  }

  accept(ConstExpVisitor visitor) => visitor.visitConstructor(this);
}

/// String literal with juxtaposition and/or interpolations.
// TODO(johnniwinther): Do we need this?
class ConcatenateConstExp extends ConstExp {
  final StringConstant value;
  final List<ConstExp> arguments;

  ConcatenateConstExp(this.value, this.arguments);

  accept(ConstExpVisitor visitor) => visitor.visitConcatenate(this);
}

/// Symbol literal.
class SymbolConstExp extends ConstExp {
  final ConstructedConstant value;
  final String name;

  SymbolConstExp(this.value, this.name);

  accept(ConstExpVisitor visitor) => visitor.visitSymbol(this);
}

/// Type literal.
class TypeConstExp extends ConstExp {
  final TypeConstant value;
  /// Either [DynamicType] or a raw [GenericType].
  final DartType type;

  TypeConstExp(this.value, this.type) {
    assert(type is GenericType || type is DynamicType);
  }

  accept(ConstExpVisitor visitor) => visitor.visitType(this);
}

/// A constant local, top-level, or static variable.
class VariableConstExp extends ConstExp {
  final Constant value;
  final VariableElement element;

  VariableConstExp(this.value, this.element);

  accept(ConstExpVisitor visitor) => visitor.visitVariable(this);
}

/// Reference to a top-level or static function.
class FunctionConstExp extends ConstExp {
  final FunctionConstant value;
  final FunctionElement element;

  FunctionConstExp(this.value, this.element);

  accept(ConstExpVisitor visitor) => visitor.visitFunction(this);
}

/// A constant binary expression like `a * b` or `identical(a, b)`.
class BinaryConstExp extends ConstExp {
  final Constant value;
  final ConstExp left;
  final String operator;
  final ConstExp right;

  BinaryConstExp(this.value, this.left, this.operator, this.right) {
    assert(PRECEDENCE_MAP[operator] != null);
  }

  accept(ConstExpVisitor visitor) => visitor.visitBinary(this);

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
class UnaryConstExp extends ConstExp {
  final Constant value;
  final String operator;
  final ConstExp expression;

  UnaryConstExp(this.value, this.operator, this.expression) {
    assert(PRECEDENCE_MAP[operator] != null);
  }

  accept(ConstExpVisitor visitor) => visitor.visitUnary(this);

  int get precedence => PRECEDENCE_MAP[operator];

  static const Map<String, int> PRECEDENCE_MAP = const {
    '!': 14,
    '~': 14,
    '-': 14,
  };
}

/// A constant conditional expression like `a ? b : c`.
class ConditionalConstExp extends ConstExp {
  final Constant value;
  final ConstExp condition;
  final ConstExp trueExp;
  final ConstExp falseExp;

  ConditionalConstExp(this.value, this.condition, this.trueExp, this.falseExp);

  accept(ConstExpVisitor visitor) => visitor.visitConditional(this);

  int get precedence => 3;
}

abstract class ConstExpVisitor<T> {
  T visit(ConstExp constant) => constant.accept(this);

  T visitPrimitive(PrimitiveConstExp exp);
  T visitList(ListConstExp exp);
  T visitMap(MapConstExp exp);
  T visitConstructor(ConstructorConstExp exp);
  T visitConcatenate(ConcatenateConstExp exp);
  T visitSymbol(SymbolConstExp exp);
  T visitType(TypeConstExp exp);
  T visitVariable(VariableConstExp exp);
  T visitFunction(FunctionConstExp exp);
  T visitBinary(BinaryConstExp exp);
  T visitUnary(UnaryConstExp exp);
  T visitConditional(ConditionalConstExp exp);
}

/// Represents the declaration of a constant [element] with value [expression].
class ConstDeclaration {
  final VariableElement element;
  final ConstExp expression;

  ConstDeclaration(this.element, this.expression);
}

class ConstExpPrinter extends ConstExpVisitor {
  final StringBuffer sb = new StringBuffer();

  write(ConstExp parent, ConstExp child, {bool leftAssociative: true}) {
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

  visitPrimitive(PrimitiveConstExp exp) {
    sb.write(exp.value.unparse());
  }

  visitList(ListConstExp exp) {
    sb.write('const ');
    writeTypeArguments(exp.type);
    sb.write('[');
    bool needsComma = false;
    for (ConstExp value in exp.values) {
      if (needsComma) {
        sb.write(', ');
      }
      visit(value);
      needsComma = true;
    }
    sb.write(']');
  }

  visitMap(MapConstExp exp) {
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

  visitConstructor(ConstructorConstExp exp) {
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

  visitConcatenate(ConcatenateConstExp exp) {
    sb.write(exp.value.unparse());
  }

  visitSymbol(SymbolConstExp exp) {
    sb.write('#');
    sb.write(exp.name);
  }

  visitType(TypeConstExp exp) {
    sb.write(exp.type.name);
  }

  visitVariable(VariableConstExp exp) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  visitFunction(FunctionConstExp exp) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  visitBinary(BinaryConstExp exp) {
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

  visitUnary(UnaryConstExp exp) {
    sb.write(exp.operator);
    write(exp, exp.expression);
  }

  visitConditional(ConditionalConstExp exp) {
    write(exp, exp.condition, leftAssociative: false);
    sb.write(' ? ');
    write(exp, exp.trueExp);
    sb.write(' : ');
    write(exp, exp.falseExp);
  }

  String toString() => sb.toString();
}