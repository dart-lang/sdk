// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srdjan): fix limitations.
// - shift amount must be a Smi.
class IntegerImplementation {
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
    if (other == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return other.truncDivFromInteger(this);
  }
  num operator /(num other) {
    return this.toDouble() / other.toDouble();
  }
  num operator %(num other) {
    if (other == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return other.moduloFromInteger(this);
  }
  int operator negate() {
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
    return other.sarFromInt(this);
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

  int compareTo(Comparable other) {
    if (this == other) return 0;
    if (this < other) return -1;
    return 1;
  }
  int round() { return this; }
  int floor() { return this; }
  int ceil() { return this; }
  int truncate() { return this; }

  int toInt() { return this; }
  double toDouble() { return new Double.fromInteger(this); }

  int pow(int exponent) {
    throw "IntegerImplementation.pow not implemented";
  }

  String toStringAsFixed(int fractionDigits) {
    throw "IntegerImplementation.toStringAsFixed not implemented";
  }
  String toStringAsExponential(int fractionDigits) {
    throw "IntegerImplementation.toStringAsExponential not implemented";
  }
  String toStringAsPrecision(int precision) {
    throw "IntegerImplementation.toStringAsPrecision not implemented";
  }
  String toRadixString(int radix) {
    final table = const ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                         "A", "B", "C", "D", "E", "F"];
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

class Smi extends IntegerImplementation implements int {
  int hashCode() {
    return this;
  }
  int operator ~() native "Smi_bitNegate";
  int sarFromInt(int other) native "Smi_sarFromInt";
  int shlFromInt(int other) native "Smi_shlFromInt";
}

// Represents integers that cannot be represented by Smi but fit into 64bits.
class Mint extends IntegerImplementation implements int {
  int hashCode() {
    return this;
  }
  int operator ~() native "Mint_bitNegate";
}

// A number that can be represented as Smi or Mint will never be represented as
// Bigint.
class Bigint extends IntegerImplementation implements int {
  int hashCode() {
    return this;
  }
  int operator ~() native "Bigint_bitNegate";

  // Shift by bigint exceeds range that can be handled by the VM.
  int sarFromInt(int other) {
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
