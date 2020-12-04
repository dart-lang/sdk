// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

class ValueTypeMask extends ForwardingTypeMask {
  /// Tag used for identifying serialized [ValueTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'value-type-mask';

  @override
  final TypeMask forwardTo;
  final PrimitiveConstantValue value;

  ValueTypeMask(this.forwardTo, this.value);

  /// Deserializes a [ValueTypeMask] object from [source].
  factory ValueTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, domain);
    ConstantValue constant = source.readConstant();
    source.end(tag);
    return new ValueTypeMask(forwardTo, constant);
  }

  /// Serializes this [ValueTypeMask] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(TypeMaskKind.value);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeConstant(value);
    sink.end(tag);
  }

  @override
  TypeMask nullable() {
    return isNullable ? this : new ValueTypeMask(forwardTo.nullable(), value);
  }

  @override
  TypeMask nonNullable() {
    return isNullable
        ? new ValueTypeMask(forwardTo.nonNullable(), value)
        : this;
  }

  @override
  bool get isValue => true;

  @override
  bool equalsDisregardNull(other) {
    if (other is! ValueTypeMask) return false;
    return super.equalsDisregardNull(other) && value == other.value;
  }

  @override
  TypeMask intersection(TypeMask other, CommonMasks domain) {
    TypeMask forwardIntersection = forwardTo.intersection(other, domain);
    if (forwardIntersection.isEmptyOrNull) return forwardIntersection;
    return forwardIntersection.isNullable ? nullable() : nonNullable();
  }

  @override
  bool operator ==(other) => super == other;

  @override
  int get hashCode {
    return computeHashCode(value, isNullable, forwardTo);
  }

  @override
  String toString() {
    return 'Value($forwardTo, value: ${value.toDartText(null)})';
  }
}
