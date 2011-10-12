// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



function native_NumberImplementation_BIT_OR(other) {
  return this | other;
}

function native_NumberImplementation_BIT_XOR(other) {
  return this ^ other;
}

function native_NumberImplementation_BIT_AND(other) {
  return this & other;
}

function native_NumberImplementation_SHL(other) {
  return this << other;
}

function native_NumberImplementation_SAR(other) {
  return this >> other;
}

function native_NumberImplementation_ADD(other) {
  return this + other;
}

function native_NumberImplementation_SUB(other) {
  return this - other;
}

function native_NumberImplementation_MUL(other) {
  return this * other;
}

function native_NumberImplementation_DIV(other) {
  return this / other;
}

function native_NumberImplementation_TRUNC(other) {
  var tmp = this / other;
  if (tmp < 0) {
    return Math.ceil(tmp);
  } else {
    return Math.floor(tmp);
  }
}

function number$euclideanModulo(a, b) {
  var result = a % b;
  if (result == 0) {
    return 0;  // Make sure we don't return -0.0.
  } else if (result < 0) {
    if (b < 0) {
      return result - b;
    } else {
      return result + b;
    }
  }
  return result;
}

function native_NumberImplementation_MOD(other) {
  return number$euclideanModulo(this, other);
}

function native_NumberImplementation_LT(other) {
  return this < other;
}

function native_NumberImplementation_GT(other) {
  return this > other;
}

function native_NumberImplementation_LTE(other) {
  return this <= other;
}

function native_NumberImplementation_GTE(other) {
  return this >= other;
}

function native_NumberImplementation_EQ(other) {
  if (typeof other == 'number') {
    return this == other;
  } else if (other instanceof Number) {
    // Must convert other to a primitive for value equality to work
    return this == Number(other);
  } else {
    return false;
  }
}

function native_NumberImplementation_BIT_NOT() {
  return ~this;
}

function native_NumberImplementation_negate() { return -this; }

function native_NumberImplementation_remainder(other) {
  return this % other;
}

function native_NumberImplementation_abs() { return Math.abs(this); }

function native_NumberImplementation_round() { return Math.round(this); }
function native_NumberImplementation_floor() { return Math.floor(this); }
function native_NumberImplementation_ceil() { return Math.ceil(this); }
function native_NumberImplementation_truncate() {
  return (this < 0) ? Math.ceil(this) : Math.floor(this);
}
function native_NumberImplementation_isNegative() {
  // TODO(floitsch): is there a faster way to detect -0?
  if (this == 0) return (1 / this) < 0;
  return this < 0;
}
function native_NumberImplementation_isEven() { return ((this & 1) == 0); }
function native_NumberImplementation_isOdd() { return ((this & 1) == 1); }
function native_NumberImplementation_isNaN() { return isNaN(this); }
function native_NumberImplementation_isInfinite() {
  return (this == Infinity) || (this == -Infinity);
}

function native_NumberImplementation_toString() {
  return this.toString();
}
function native_NumberImplementation_toStringAsFixed(fractionDigits) {
  return this.toFixed(fractionDigits);
}
function native_NumberImplementation_toStringAsPrecision(precision) {
  return this.toPrecision(precision);
}
function native_NumberImplementation_toStringAsExponential(fractionDigits) {
  return this.toExponential(fractionDigits);
}
function native_NumberImplementation_toRadixString(radix) {
  return this.toString(radix);
}

function native_NumberImplementation_hashCode() {
  return this & 0xFFFFFFF;
}
