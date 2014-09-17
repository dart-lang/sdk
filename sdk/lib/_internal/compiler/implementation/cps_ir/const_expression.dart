// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library const_expression;

import '../dart2jslib.dart' show Constant, ListConstant, MapConstant,
    PrimitiveConstant, ConstructedConstant, TypeConstant, FunctionConstant,
    StringConstant;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../universe/universe.dart';

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
  accept(ConstExpVisitor visitor);
}

/// Boolean, int, double, string, or null constant.
class PrimitiveConstExp extends ConstExp {
  final PrimitiveConstant constant;

  PrimitiveConstExp(this.constant) {
    assert(constant != null);
  }

  accept(ConstExpVisitor visitor) => visitor.visitPrimitive(this);
}

/// Literal list constant.
class ListConstExp extends ConstExp {
  final GenericType type;
  final List<ConstExp> values;

  ListConstExp(this.type, this.values);

  accept(ConstExpVisitor visitor) => visitor.visitList(this);
}

/// Literal map constant.
class MapConstExp extends ConstExp {
  final GenericType type;
  final List<ConstExp> keys;
  final List<ConstExp> values;

  MapConstExp(this.type, this.keys, this.values);

  accept(ConstExpVisitor visitor) => visitor.visitMap(this);
}

/// Invocation of a const constructor.
class ConstructorConstExp extends ConstExp {
  final GenericType type;
  final FunctionElement target;
  final Selector selector;
  final List<ConstExp> arguments;

  ConstructorConstExp(this.type, this.target, this.selector, this.arguments) {
    assert(type.element == target.enclosingClass);
  }

  accept(ConstExpVisitor visitor) => visitor.visitConstructor(this);
}

/// String literal with juxtaposition and/or interpolations.
class ConcatenateConstExp extends ConstExp {
  final List<ConstExp> arguments;

  ConcatenateConstExp(this.arguments);

  accept(ConstExpVisitor visitor) => visitor.visitConcatenate(this);
}

/// Symbol literal.
class SymbolConstExp extends ConstExp {
  final String name;

  SymbolConstExp(this.name);

  accept(ConstExpVisitor visitor) => visitor.visitSymbol(this);
}

/// Type literal.
class TypeConstExp extends ConstExp {
  /// Either [DynamicType] or a raw [GenericType].
  final DartType type;

  TypeConstExp(this.type) {
    assert(type is GenericType || type is DynamicType);
  }

  accept(ConstExpVisitor visitor) => visitor.visitType(this);
}

/// A constant local, top-level, or static variable.
class VariableConstExp extends ConstExp {
  final VariableElement element;

  VariableConstExp(this.element);

  accept(ConstExpVisitor visitor) => visitor.visitVariable(this);
}

/// Reference to a top-level or static function.
class FunctionConstExp extends ConstExp {
  final FunctionElement element;

  FunctionConstExp(this.element);

  accept(ConstExpVisitor visitor) => visitor.visitFunction(this);
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
}

/// Represents the declaration of a constant [element] with value [expression].
class ConstDeclaration {
  final VariableElement element;
  final ConstExp expression;

  ConstDeclaration(this.element, this.expression);
}
