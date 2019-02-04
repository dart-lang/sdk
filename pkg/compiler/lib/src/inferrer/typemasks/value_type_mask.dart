// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

class ValueTypeMask extends ForwardingTypeMask {
  /// Tag used for identifying serialized [ValueTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'value-type-mask';

  final TypeMask forwardTo;
  final PrimitiveConstantValue value;

  ValueTypeMask(this.forwardTo, this.value);

  /// Deserializes a [ValueTypeMask] object from [source].
  factory ValueTypeMask.readFromDataSource(
      DataSource source, JClosedWorld closedWorld) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, closedWorld);
    ConstantValue constant = source.readConstant();
    source.end(tag);
    return new ValueTypeMask(forwardTo, constant);
  }

  /// Serializes this [ValueTypeMask] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(TypeMaskKind.value);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeConstant(value);
    sink.end(tag);
  }

  TypeMask nullable() {
    return isNullable ? this : new ValueTypeMask(forwardTo.nullable(), value);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new ValueTypeMask(forwardTo.nonNullable(), value)
        : this;
  }

  bool get isValue => true;

  bool equalsDisregardNull(other) {
    if (other is! ValueTypeMask) return false;
    return super.equalsDisregardNull(other) && value == other.value;
  }

  TypeMask intersection(TypeMask other, JClosedWorld closedWorld) {
    TypeMask forwardIntersection = forwardTo.intersection(other, closedWorld);
    if (forwardIntersection.isEmptyOrNull) return forwardIntersection;
    return forwardIntersection.isNullable ? nullable() : nonNullable();
  }

  bool operator ==(other) => super == other;

  int get hashCode {
    return computeHashCode(value, isNullable, forwardTo);
  }

  String toString() {
    return 'Value($forwardTo, value: ${value.toDartText()})';
  }
}
