// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_StringImplementation__indexOperator(index) {
  "use strict";
  return this[index];
}

function native_StringImplementation__charCodeAt(index) {
  "use strict";
  return this.charCodeAt(index);
}

function native_StringImplementation_get$length() {
  "use strict";
  return this.length;
}

function native_StringImplementation_EQ(other) {
  // TODO(kasperl): We should really try to avoid having wrapped
  // strings floating around. The usually stem from referencing [this]
  // in Dart methods patched onto the String.prototype object.

  // Because of the checks in EQ$operator, we know [this] is a string
  // wrapper, but we have to make sure that [other] is either a
  // wrapper or a proper string before we can use == to compare the
  // contents.
  return (typeof(other) == 'string' || other.constructor === String)
      ? this == other
      : false;
}

function native_StringImplementation__nativeIndexOf(other, startIndex) {
  "use strict";
  return this.indexOf(other, startIndex);
}

function native_StringImplementation__nativeLastIndexOf(other, fromIndex) {
  "use strict";
  if (other == "") {
    return Math.min(this.length, fromIndex);
  }
  return this.lastIndexOf(other, fromIndex);
}

function native_StringImplementation_concat(other) {
  "use strict";
  return this.concat(other);
}

function native_StringImplementation__substringUnchecked(startIndex, endIndex) {
  "use strict";
  return this.substring(startIndex, endIndex);
}

function native_StringImplementation_trim() {
  "use strict";
  if (this.trim) return this.trim();
  return this.replace(new RegExp("^[\s]+|[\s]+$", "g"), "");
}

function native_StringImplementation__replace(from, to) {
  "use strict";
  if ($isString(from)) {
    return this.replace(from, to);
  } else {
    return this.replace($DartRegExpToJSRegExp(from), to);
  }
}

function native_StringImplementation__replaceAll(from, to) {
  "use strict";
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
  "use strict";
  if ($isString(pattern)) {
    return this.split(pattern);
  } else {
    return this.split($DartRegExpToJSRegExp(pattern));
  }
}

function native_StringImplementation_toLowerCase() {
  "use strict";
  return this.toLowerCase();
}

function native_StringImplementation_toUpperCase() {
  "use strict";
  return this.toUpperCase();
}

// Inherited from Hashable.
function native_StringImplementation_hashCode() {
  "use strict";
  var hash = 0;
  for (var i = 0; i < this.length; i++) {
    var ch = this.charCodeAt(i);
    hash += ch;
    hash += hash << 10;
    hash ^= hash >> 6;
  }

  hash += hash << 3;
  hash ^= hash >> 11;
  hash += hash << 15;
  hash = hash & ((1 << 29) - 1);

  return hash;
}

function native_StringImplementation_toString() {
  "use strict";
  // Return the primitive string of this String object.
  return String(this);
}

// TODO(floitsch): If we allow comparison operators on the String class we
// should move this function into dart world.
function native_StringImplementation_compareTo(other) {
  "use strict";
  if (this == other) return 0;
  if (this < other) return -1;
  return 1;
}

function native_StringImplementation__newFromValues(array) {
  "use strict";
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
