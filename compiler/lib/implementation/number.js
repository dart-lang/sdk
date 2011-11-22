// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



function native_NumberImplementation_BIT_OR(other) {
  "use strict";
  return this | other;
}

function native_NumberImplementation_BIT_XOR(other) {
  "use strict";
  return this ^ other;
}

function native_NumberImplementation_BIT_AND(other) {
  "use strict";
  return this & other;
}

function native_NumberImplementation_SHL(other) {
  "use strict";
  return this << other;
}

function native_NumberImplementation_SAR(other) {
  "use strict";
  return this >> other;
}

function native_NumberImplementation_ADD(other) {
  "use strict";
  return this + other;
}

function native_NumberImplementation_SUB(other) {
  "use strict";
   return this - other;
}

function native_NumberImplementation_MUL(other) {
  "use strict";
  return this * other;
}

function native_NumberImplementation_DIV(other) {
  "use strict";
  return this / other;
}

function native_NumberImplementation_TRUNC(other) {
  "use strict";
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
  "use strict";
  return number$euclideanModulo(this, other);
}

function native_NumberImplementation_LT(other) {
  "use strict";
  return this < other;
}

function native_NumberImplementation_GT(other) {
  "use strict";
  return this > other;
}

function native_NumberImplementation_LTE(other) {
  "use strict";
  return this <= other;
}

function native_NumberImplementation_GTE(other) {
  "use strict";
  return this >= other;
}

function native_NumberImplementation_EQ(other) {
  "use strict";
  return typeof other == 'number' && this == other;
}

function native_NumberImplementation_BIT_NOT() {
  "use strict";
  return ~this;
}

function native_NumberImplementation_negate() {
  "use strict";
  return -this;
}

function native_NumberImplementation_remainder(other) {
  "use strict";
  return this % other;
}

function native_NumberImplementation_abs() {
  "use strict";
  return Math.abs(this);
}

function native_NumberImplementation_round() {
  "use strict";
  return Math.round(this);
}
function native_NumberImplementation_floor() {
  "use strict";
  return Math.floor(this);
}
function native_NumberImplementation_ceil() {
  "use strict";
  return Math.ceil(this);
}
function native_NumberImplementation_truncate() {
  "use strict";
  return (this < 0) ? Math.ceil(this) : Math.floor(this);
}
function native_NumberImplementation_isNegative() {
  "use strict";
  // TODO(floitsch): is there a faster way to detect -0?
  if (this == 0) return (1 / this) < 0;
  return this < 0;
}
function native_NumberImplementation_isEven() {
  "use strict";
  return ((this & 1) == 0);
}
function native_NumberImplementation_isOdd() {
  "use strict";
  return ((this & 1) == 1);
}
function native_NumberImplementation_isNaN() {
  "use strict";
  return isNaN(this);
}
function native_NumberImplementation_isInfinite() {
  "use strict";
  return (this == Infinity) || (this == -Infinity);
}

function native_NumberImplementation_toDouble() {
  "use strict";
  return +this;
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
  "use strict";
  return this & 0xFFFFFFF;
}
