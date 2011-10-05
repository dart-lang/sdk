// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Native methods for Math.
var native_Math_ceil = Math.ceil;
var native_Math_floor = Math.floor;
var native_Math_max = Math.max;
var native_Math_min = Math.min;
var native_Math_round = Math.round;

// A valid integer-string is composed of:
//   optional whitespace: \s*
//   an optional sign: [+-]?
//   either digits (at least one): \d+
//       or a hex-literal: 0[xX][0-9abcdefABCDEF]+
//   optional whitespace: \s*
var math$INT_REGEXP =
    /^\s*[+-]?(:?\d+|0[xX][0-9abcdefABCDEF]+)\s*$/;

// A valid double-string is composed of:
//   optional whitespace: \s*
//   an optional sign: [+-]?
//   either:
//      digits* . digits+ exponent?
//      digits+ exponent
//      Infinity
//      NaN
//   optional whitespace: \s*
var math$DOUBLE_REGEXP =
    /^\s*[+-]?((\d*\.\d+([eE][+-]?\d+)?)|(\d+([eE][+-]?\d+))|Infinity|NaN)\s*$/;

function native_MathNatives_parseDouble(str) {
  if (math$INT_REGEXP.test(str) || math$DOUBLE_REGEXP.test(str)) return +str;
  throw native_MathNatives__newBadNumberFormat(str);
}



function native_MathNatives_parseInt(str) {
  if (math$INT_REGEXP.test(str)) return +str;
  throw native_MathNatives__newBadNumberFormat(str);
}

function native_MathNatives_random() { return Math.random(); }
function native_MathNatives_sin(x) { return Math.sin(x); }
function native_MathNatives_cos(x) { return Math.cos(x); }
function native_MathNatives_tan(x) { return Math.tan(x); }
function native_MathNatives_asin(x) { return Math.asin(x); }
function native_MathNatives_acos(x) { return Math.acos(x); }
function native_MathNatives_atan(x) { return Math.atan(x); }
function native_MathNatives_atan2(x, y) { return Math.atan2(x, y); }
function native_MathNatives_sqrt(x) { return Math.sqrt(x); }
function native_MathNatives_exp(x) { return Math.exp(x); }
function native_MathNatives_log(x) { return Math.log(x); }
function native_MathNatives_pow(x, y) { return Math.pow(x, y); }
