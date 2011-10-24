// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_ListFactory__new(typeToken, length) {
  return RTT.setTypeInfo(
      new Array(length),
      Array.$lookupRTT(RTT.getTypeInfo(typeToken).typeArgs));
}

function native_ListImplementation__indexOperator(index) {
  return this[index];
}

function native_ListImplementation__indexAssignOperator(index, value) {
  this[index] = value;
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

function $inlineArrayIndexCheck(array, index) {
  if (index >= 0 && index < array.length) {
    return index;
  }
  native__ListJsUtil__throwIndexOutOfRangeException(index);
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
