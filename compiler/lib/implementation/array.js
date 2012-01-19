// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_ListImplementation_INDEX(index) {
  var i = index | 0;
  if (i !== index) {
    native__NumberJsUtil__throwIllegalArgumentException(index);
  } else if (i < 0 || i >= this.length) {
    native__ListJsUtil__throwIndexOutOfRangeException(index);
  }
  return this[i];
}

function native_ListImplementation_ASSIGN_INDEX(index, value) {
  var i = index | 0;
  if (i !== index) {
    native__NumberJsUtil__throwIllegalArgumentException(index);
  } else if (i < 0 || i >= this.length) {
    native__ListJsUtil__throwIndexOutOfRangeException(index);
  }
  this[i] = value;
}

function native_ListImplementation_get$length() {
  return this.length;
}

function native_ListImplementation__setLength(length) {
  this.length = length;
}

function native_ListImplementation__add(element) {
  this.push(element);
}

function native_ListImplementation__removeRange(start, length) {
  this.splice(start, length);
}

function native_ListImplementation__insertRange(start, length, initialValue) {
  var array = [start, 0];
  for (var i = 0; i < length; i++){
    array.push(initialValue);
  }
  this.splice.apply(this, array);
}

function $inlineArrayIndexCheck(array, index) {
  var i = index | 0;
  if (i !== index) {
    native__NumberJsUtil__throwIllegalArgumentException(index);
  } else if (i < 0 || i >= array.length) {
    native__ListJsUtil__throwIndexOutOfRangeException(index);
  }
  return i;
}
