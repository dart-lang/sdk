// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

class ValueTypeMask extends ForwardingTypeMask {
  final TypeMask forwardTo;
  final value;

  ValueTypeMask(this.forwardTo, this.value);

  TypeMask nullable() {
    return isNullable
        ? this
        : new ValueTypeMask(forwardTo.nullable(), value);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new ValueTypeMask(forwardTo.nonNullable(), value)
        : this;
  }

  bool get isValue => true;

  bool equalsDisregardNull(other) {
    if (other is! ValueTypeMask) return false;
    return value == other.value;
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    TypeMask forwardIntersection = forwardTo.intersection(other, compiler);
    if (forwardIntersection.isEmpty) return forwardIntersection;
    return forwardIntersection.isNullable
        ? nullable()
        : nonNullable();
  }

  bool operator==(other) => super == other;

  int get hashCode {
    return computeHashCode(value, isNullable, forwardTo);
  }

  String toString() {
    return 'Value mask: [$value] type: $forwardTo';
  }
}