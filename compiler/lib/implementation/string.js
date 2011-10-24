// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_StringImplementation__indexOperator(index) {
  return this[index];
}

function native_StringImplementation__charCodeAt(index) {
  return this.charCodeAt(index);
}

function native_StringImplementation_get$length() {
  return this.length;
}

function native_StringImplementation_EQ(other) {
  return typeof other == 'string' && this == other;
}

function native_StringImplementation_indexOf(other, startIndex) {
  return this.indexOf(other, startIndex);
}

function native_StringImplementation_lastIndexOf(other, fromIndex) {
  if (other == "") {
    return Math.min(this.length, fromIndex);
  }
  return this.lastIndexOf(other, fromIndex);
}

function native_StringImplementation_concat(other) {
  return this.concat(other);
}

function native_StringImplementation__substringUnchecked(startIndex, endIndex) {
  return this.substring(startIndex, endIndex);
}

function native_StringImplementation_trim() {
  if (this.trim) return this.trim();
  return this.replace(new RegExp("^[\s]+|[\s]+$", "g"), "");
}

function native_StringImplementation__replace(from, to) {
  if ($isString(from)) {
    return this.replace(from, to);
  } else {
    return this.replace($DartRegExpToJSRegExp(from), to);
  }
}

function native_StringImplementation__replaceAll(from, to) {
  if ($isString(from)) {
    var regexp = new RegExp(
        from.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'g');
    return this.replace(regexp, to);
  } else {
    var regexp = $DartRegExpToJSRegExp(from);
    return this.replace(regexp, to);
  }
}

function native_StringImplementation__split(pattern) {
  if ($isString(pattern)) {
    return this.split(pattern);
  } else {
    return this.split($DartRegExpToJSRegExp(pattern));
  }
}

function native_StringImplementation_toLowerCase() {
  return this.toLowerCase();
}

function native_StringImplementation_toUpperCase() {
  return this.toUpperCase();
}

// Inherited from Hashable.
function native_StringImplementation_hashCode() {
  if (this.hash_ === undefined) {
    for (var i = 0; i < this.length; i++) {
      var ch = this.charCodeAt(i);
      this.hash_ += ch;
      this.hash_ += this.hash_ << 10;
      this.hash_ ^= this.hash_ >> 6;
    }

    this.hash_ += this.hash_ << 3;
    this.hash_ ^= this.hash_ >> 11;
    this.hash_ += this.hash_ << 15;
    this.hash_ = this.hash_ & ((1 << 29) - 1);
  }
  return this.hash_;
}

function native_StringImplementation_toString() {
  // Return the primitive string of this String object.
  return String(this);
}

// TODO(floitsch): If we allow comparison operators on the String class we
// should move this function into dart world.
function native_StringImplementation_compareTo(other) {
  if (this == other) return 0;
  if (this < other) return -1;
  return 1;
}

function native_StringImplementation__newFromValues(array) {
  if (!(array instanceof Array)) {
    var length = native__ListJsUtil__listLength(array);
    var tmp = new Array(length);
    for (var i = 0; i < length; i++) {
      tmp[i] = INDEX$operator(array, i);
    }
    array = tmp;
  }
  return String.fromCharCode.apply(this, array);
}

// Deprecated old name of new String.fromValues(..).
function native_StringBase_createFromCharCodes(array) {
  return native_StringImplementation__newFromValues(array);
}
