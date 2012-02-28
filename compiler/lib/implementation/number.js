// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


function native_NumberImplementation_BIT_OR(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_BIT_XOR(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_BIT_AND(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_SHL(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_SAR(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_BIT_NOT() {
  throw Error('UNREACHABLE');
}

function native_NumberImplementation_ADD(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_SUB(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_MUL(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_DIV(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_TRUNC(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_MOD(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_negate() {
  throw Error('UNREACHABLE');
}

function native_NumberImplementation_EQ(other) {
  throw Error('UNREACHABLE');
}

function native_NumberImplementation_LT(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_GT(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_LTE(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
}

function native_NumberImplementation_GTE(other) {
  native__NumberJsUtil__throwIllegalArgumentException(other);
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

function native_NumberImplementation_remainder(other) {
  "use strict";
  if (typeof other != 'number') {
    native__NumberJsUtil__throwIllegalArgumentException(other);
  }
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
  "use strict";
  var primitiveValue = +this;
  // TODO(floitsch): is there a faster way to detect -0?
  if (primitiveValue == 0 && (1 / primitiveValue) < 0) {
    return "-0.0";
  }
  return "" + primitiveValue;
}

function native_NumberImplementation_toStringAsFixed(fractionDigits) {
  var primitiveValue = +this;
  // TODO(floitsch): is there a faster way to detect -0?
  if (primitiveValue == 0 && (1 / primitiveValue) < 0) {
    return "-" + this.toFixed(fractionDigits);
  }
  return this.toFixed(fractionDigits);
}

function native_NumberImplementation_toStringAsPrecision(precision) {
  var primitiveValue = +this;
  // TODO(floitsch): is there a faster way to detect -0?
  if (primitiveValue == 0 && (1 / primitiveValue) < 0) {
    return "-" + this.toPrecision(precision);
  }
  return this.toPrecision(precision);
}

function native_NumberImplementation_toStringAsExponential(fractionDigits) {
  var primitiveValue = +this;
  // TODO(floitsch): is there a faster way to detect -0?
  if (primitiveValue == 0 && (1 / primitiveValue) < 0) {
    return "-" + this.toExponential(fractionDigits);
  }
  return this.toExponential(fractionDigits);
}

function native_NumberImplementation_toRadixString(radix) {
  return this.toString(radix);
}

function native_NumberImplementation_hashCode() {
  "use strict";
  return this & 0xFFFFFFF;
}
