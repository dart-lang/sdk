// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srdjan): fix limitations.
// - shift amount must be a Smi.
class _IntegerImplementation {
  factory _IntegerImplementation._uninstantiable() {
    throw const UnsupportedOperationException(
        "_IntegerImplementation can only be allocated by the VM");
  }
  num operator +(num other) {
    return other.addFromInteger(this);
  }
  num operator -(num other) {
    return other.subFromInteger(this);
  }
  num operator *(num other) {
    return other.mulFromInteger(this);
  }
  num operator ~/(num other) {
    if ((other is int) && (other == 0)) {
      throw const IntegerDivisionByZeroException();
    }
    return other.truncDivFromInteger(this);
  }
  num operator /(num other) {
    return this.toDouble() / other.toDouble();
  }
  num operator %(num other) {
    if ((other is int) && (other == 0)) {
      throw const IntegerDivisionByZeroException();
    }
    return other.moduloFromInteger(this);
  }
  int operator -() {
    return 0 - this;
  }
  int operator &(int other) {
    return other.bitAndFromInteger(this);
  }
  int operator |(int other) {
    return other.bitOrFromInteger(this);
  }
  int operator ^(int other) {
    return other.bitXorFromInteger(this);
  }
  num remainder(num other) {
    return other.remainderFromInteger(this);
  }
  int bitAndFromInteger(int other) native "Integer_bitAndFromInteger";
  int bitOrFromInteger(int other) native "Integer_bitOrFromInteger";
  int bitXorFromInteger(int other) native "Integer_bitXorFromInteger";
  int addFromInteger(int other) native "Integer_addFromInteger";
  int subFromInteger(int other) native "Integer_subFromInteger";
  int mulFromInteger(int other) native "Integer_mulFromInteger";
  int truncDivFromInteger(int other) native "Integer_truncDivFromInteger";
  int moduloFromInteger(int other) native "Integer_moduloFromInteger";
  int remainderFromInteger(int other) {
    return other - (other ~/ this) * this;
  }
  int operator >>(int other) {
    return other.shrFromInt(this);
  }
  int operator <<(int other) {
    return other.shlFromInt(this);
  }
  bool operator <(num other) {
    return other > this;
  }
  bool operator >(num other) {
    return other.greaterThanFromInteger(this);
  }
  bool operator >=(num other) {
    return (this == other) ||  (this > other);
  }
  bool operator <=(num other) {
    return (this == other) || (this < other);
  }
  bool greaterThanFromInteger(int other)
      native "Integer_greaterThanFromInteger";
  bool operator ==(other) {
    if (other is num) {
      return other.equalToInteger(this);
    }
    return false;
  }
  bool equalToInteger(int other) native "Integer_equalToInteger";
  int abs() {
    return this < 0 ? -this : this;
  }
  bool isEven() { return ((this & 1) === 0); }
  bool isOdd() { return !isEven(); }
  bool isNaN() { return false; }
  bool isNegative() { return this < 0; }
  bool isInfinite() { return false; }

  int compareTo(num other) {
    final int EQUAL = 0, LESS = -1, GREATER = 1;
    if (other is double) {
      // TODO(floitsch): the following locals should be 'const'.
      int MAX_EXACT_INT_TO_DOUBLE = 9007199254740992;  // 2^53.
      int MIN_EXACT_INT_TO_DOUBLE = -MAX_EXACT_INT_TO_DOUBLE;
      double d = other;
      if (d.isInfinite()) {
        return d == double.NEGATIVE_INFINITY ? GREATER : LESS;
      }
      if (d.isNaN()) {
        return LESS;
      }
      if (MIN_EXACT_INT_TO_DOUBLE <= this && this <= MAX_EXACT_INT_TO_DOUBLE) {
        // Let the double implementation deal with -0.0.
        return -(d.compareTo(this.toDouble()));
      } else {
        // If abs(other) > MAX_EXACT_INT_TO_DOUBLE, then other has an integer
        // value (no bits below the decimal point).
        other = d.toInt();
      }
    }
    if (this < other) {
      return LESS;
    } else if (this > other) {
      return GREATER;
    } else {
      return EQUAL;
    }
  }

  int round() { return this; }
  int floor() { return this; }
  int ceil() { return this; }
  int truncate() { return this; }

  int toInt() { return this; }
  double toDouble() { return new _Double.fromInteger(this); }

  int pow(int exponent) {
    double res = this.toDouble().pow(exponent);
    if (res.isInfinite()) {
      // Use Bigint instead.
      throw "_IntegerImplementation.pow not implemented for large integers.";
    }
    return res.toInt();
  }

  String toStringAsFixed(int fractionDigits) {
    return this.toDouble().toStringAsFixed(fractionDigits);
  }
  String toStringAsExponential(int fractionDigits) {
    return this.toDouble().toStringAsExponential(fractionDigits);
  }
  String toStringAsPrecision(int precision) {
    return this.toDouble().toStringAsPrecision(precision);
  }
  String toRadixString(int radix) {
    final table = const ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                         "a", "b", "c", "d", "e", "f"];
    if ((radix <= 1) || (radix > 16)) {
      throw "Bad radix: $radix";
    }
    final bool isNegative = this < 0;
    var value = isNegative ? -this : this;
    List temp = new List();
    while (value > 0) {
      var digit = value % radix;
      value ~/= radix;
      temp.add(digit);
    }
    if (temp.isEmpty()) {
      return "0";
    }
    StringBuffer buffer = new StringBuffer();
    if (isNegative) buffer.add("-");
    for (int i = temp.length - 1; i >= 0; i--) {
      buffer.add(table[temp[i]]);
    }
    return buffer.toString();
  }
}

class _Smi extends _IntegerImplementation implements int {
  factory _Smi._uninstantiable() {
    throw const UnsupportedOperationException(
        "_Smi can only be allocated by the VM");
  }
  int hashCode() {
    return this;
  }
  int operator ~() native "Smi_bitNegate";
  int shrFromInt(int other) native "Smi_shrFromInt";
  int shlFromInt(int other) native "Smi_shlFromInt";
}

// Represents integers that cannot be represented by Smi but fit into 64bits.
class _Mint extends _IntegerImplementation implements int {
  factory _Mint._uninstantiable() {
    throw const UnsupportedOperationException(
        "_Mint can only be allocated by the VM");
  }
  int hashCode() {
    return this;
  }
  int operator ~() native "Mint_bitNegate";

  // Shift by mint exceeds range that can be handled by the VM.
  int shrFromInt(int other) {
    if (other < 0) {
      return -1;
    } else {
      return 0;
    }
  }
  int shlFromInt(int other) {
    throw const OutOfMemoryException();
  }
}

// A number that can be represented as Smi or Mint will never be represented as
// Bigint.
class _Bigint extends _IntegerImplementation implements int {
  factory _Bigint._uninstantiable() {
    throw const UnsupportedOperationException(
        "_Bigint can only be allocated by the VM");
  }
  int hashCode() {
    return this;
  }
  int operator ~() native "Bigint_bitNegate";

  // Shift by bigint exceeds range that can be handled by the VM.
  int shrFromInt(int other) {
    if (other < 0) {
      return -1;
    } else {
      return 0;
    }
  }
  int shlFromInt(int other) {
    throw const OutOfMemoryException();
  }

  int pow(int exponent) {
    throw "Bigint.pow not implemented";
  }
}
