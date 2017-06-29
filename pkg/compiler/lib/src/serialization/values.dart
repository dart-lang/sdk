// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Class hierarchy for semantic wrapping of serializable values.

library dart2js.serialization.values;

import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import 'keys.dart';

/// Intermediate representation of a serializable value.
///
/// Serializable values are
///    * [bool],
///    * [int],
///    * [double],
///    * [String],
///    * enum values,
///    * [ConstantExpression],
///    * [DartType],
///    * [Element],
///    * [Uri],
///    * lists of serializeable values,
///    * maps from arbitrary strings to serializable values; these are called
///         `Map` values, and
///    * maps from [Key] to serializable values; these are called `Object`
///         values.
///
/// The distinction between map and object values is chosen to provide a more
/// robust and checkable implementation of the latter; since the keys are drawn
/// from a fixed typed set of values, consistency between serialization and
/// deserialization is more easily maintained.
abstract class Value {
  accept(ValueVisitor visitor, arg);
}

class ElementValue implements Value {
  final Element element;
  final Value id;

  ElementValue(this.element, this.id);

  accept(ValueVisitor visitor, arg) => visitor.visitElement(this, arg);

  String toString() => element.toString();
}

class TypeValue implements Value {
  final ResolutionDartType type;
  final Value id;

  TypeValue(this.type, this.id);

  accept(ValueVisitor visitor, arg) => visitor.visitType(this, arg);

  String toString() => type.toString();
}

class ConstantValue implements Value {
  final ConstantExpression constant;
  final Value id;

  ConstantValue(this.constant, this.id);

  accept(ValueVisitor visitor, arg) => visitor.visitConstant(this, arg);

  String toString() => constant.toDartText();
}

abstract class PrimitiveValue implements Value {
  get value;

  String toString() => value.toString();
}

class BoolValue extends PrimitiveValue {
  final bool value;

  BoolValue(this.value);

  accept(ValueVisitor visitor, arg) => visitor.visitBool(this, arg);
}

class IntValue extends PrimitiveValue {
  final int value;

  IntValue(this.value);

  accept(ValueVisitor visitor, arg) => visitor.visitInt(this, arg);
}

class DoubleValue extends PrimitiveValue {
  final double value;

  DoubleValue(this.value);

  accept(ValueVisitor visitor, arg) => visitor.visitDouble(this, arg);
}

class StringValue extends PrimitiveValue {
  final String value;

  StringValue(this.value);

  accept(ValueVisitor visitor, arg) => visitor.visitString(this, arg);
}

class ObjectValue implements Value {
  final Map<Key, Value> map;

  ObjectValue(this.map);

  accept(ValueVisitor visitor, arg) => visitor.visitObject(this, arg);

  String toString() => map.toString();
}

class MapValue implements Value {
  final Map<String, Value> map;

  MapValue(this.map);

  accept(ValueVisitor visitor, arg) => visitor.visitMap(this, arg);

  String toString() => map.toString();
}

class ListValue implements Value {
  final List<Value> values;

  ListValue(this.values);

  accept(ValueVisitor visitor, arg) => visitor.visitList(this, arg);

  String toString() => values.toString();
}

class EnumValue implements Value {
  final value;

  EnumValue(this.value);

  accept(ValueVisitor visitor, arg) => visitor.visitEnum(this, arg);

  String toString() => value.toString();
}

class UriValue implements Value {
  final Uri baseUri;
  final Uri value;

  UriValue(this.baseUri, this.value);

  accept(ValueVisitor visitor, arg) => visitor.visitUri(this, arg);

  String toString() => value.toString();
}

/// Visitor for the [Value] class hierarchy.
abstract class ValueVisitor<R, A> {
  R visit(Value value, A arg);

  R visitElement(ElementValue value, A arg);
  R visitType(TypeValue value, A arg);
  R visitConstant(ConstantValue value, A arg);
  R visitBool(BoolValue value, A arg);
  R visitInt(IntValue value, A arg);
  R visitDouble(DoubleValue value, A arg);
  R visitString(StringValue value, A arg);
  R visitObject(ObjectValue value, A arg);
  R visitMap(MapValue value, A arg);
  R visitList(ListValue value, A arg);
  R visitEnum(EnumValue value, A arg);
  R visitUri(UriValue value, A arg);
}
