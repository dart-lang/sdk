// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

function date$validateValue(value) {
  if (isNaN(value)) {
    // TODO(floitsch): Use real exception object.
    throw Error("Invalid Date");
  }
  return value;
}

function native_DateImplementation__valueFromDecomposed(
    years, month, day, hours, minutes, seconds, milliseconds, isUtc) {
  // JavaScript has 0-based months.
  var jsMonth = month - 1;
  var value = isUtc ?
              Date.UTC(years, jsMonth, day,
                       hours, minutes, seconds, milliseconds) :
              new Date(years, jsMonth, day,
                       hours, minutes, seconds, milliseconds).valueOf();
  return date$validateValue(value);
}

function native_DateImplementation__valueFromString(str) {
  return date$validateValue(Date.parse(str));
}

function native_DateImplementation__now() {
  return new Date().valueOf();
}

function date$dateFrom(dartDate, value) {
  // Lazily keep a JS Date stored in the dart object.
  var date = dartDate.date;
  if (!date) {
    date = new Date(value);
    dartDate.date = date;
  }
  return date;
}

function native_DateImplementation__getYear(value, isUtc) {
  var date = date$dateFrom(this, value);
  return isUtc ? date.getUTCFullYear() : date.getFullYear();
}

function native_DateImplementation__getMonth(value, isUtc) {
  var date = date$dateFrom(this, value);
  var jsMonth = isUtc ? date.getUTCMonth() : date.getMonth();
  // JavaScript has 0-based months.
  return jsMonth + 1;
}

function native_DateImplementation__getDay(value, isUtc) {
  var date = date$dateFrom(this, value);
  return isUtc ? date.getUTCDate() : date.getDate();
}

function native_DateImplementation__getHours(value, isUtc) {
  var date = date$dateFrom(this, value);
  return isUtc ? date.getUTCHours() : date.getHours();
}

function native_DateImplementation__getMinutes(value, isUtc) {
  var date = date$dateFrom(this, value);
  return isUtc ? date.getUTCMinutes() : date.getMinutes();
}

function native_DateImplementation__getSeconds(value, isUtc) {
  var date = date$dateFrom(this, value);
  return isUtc ? date.getUTCSeconds() : date.getSeconds();
}

function native_DateImplementation__getMilliseconds(value, isUtc) {
  var date = date$dateFrom(this, value);
  return isUtc ? date.getUTCMilliseconds() : date.getMilliseconds();
}
