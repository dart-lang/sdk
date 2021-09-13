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

  const ValueTypeMask(this.forwardTo, this.value);

  /// Deserializes a [ValueTypeMask] object from [source].
  factory ValueTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = TypeMask.readFromDataSource(source, domain);
    ConstantValue constant = source.readConstant();
    source.end(tag);
    return ValueTypeMask(forwardTo, constant);
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
  ValueTypeMask withFlags({bool isNullable, bool hasLateSentinel}) {
    isNullable ??= this.isNullable;
    hasLateSentinel ??= this.hasLateSentinel;
    if (isNullable == this.isNullable &&
        hasLateSentinel == this.hasLateSentinel) {
      return this;
    }
    return ValueTypeMask(
        forwardTo.withFlags(
            isNullable: isNullable, hasLateSentinel: hasLateSentinel),
        value);
  }

  @override
  bool get isValue => true;

  @override
  TypeMask _unionSpecialCases(TypeMask other, CommonMasks domain,
      {bool isNullable, bool hasLateSentinel}) {
    assert(isNullable != null);
    assert(hasLateSentinel != null);
    if (other is ValueTypeMask &&
        forwardTo.withoutFlags() == other.forwardTo.withoutFlags() &&
        value == other.value) {
      return withFlags(
          isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    }
    return null;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ValueTypeMask) return false;
    return super == other && value == other.value;
  }

  @override
  int get hashCode => Hashing.objectHash(value, super.hashCode);

  @override
  String toString() {
    return 'Value($forwardTo, value: ${value.toDartText(null)})';
  }
}
