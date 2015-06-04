// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;


// TODO(ngeoffray): stop using this method once our optimizers can
// change str1.contains(str2) into str1.indexOf(str2) != -1.
bool contains(String userAgent, String name) {
  return JS('int', '#.indexOf(#)', userAgent, name) != -1;
}

int arrayLength(List array) {
  return JS('int', '#.length', array);
}

arrayGet(List array, int index) {
  return JS('var', '#[#]', array, index);
}

void arraySet(List array, int index, var value) {
  JS('var', '#[#] = #', array, index, value);
}

propertyGet(var object, String property) {
  return JS('var', '#[#]', object, property);
}

bool callHasOwnProperty(var function, var object, String property) {
  return JS('bool', '#.call(#, #)', function, object, property);
}

void propertySet(var object, String property, var value) {
  JS('var', '#[#] = #', object, property, value);
}

getPropertyFromPrototype(var object, String name) {
  return JS('var', 'Object.getPrototypeOf(#)[#]', object, name);
}

/**
 * Sets a JavaScript property on an object.
 */
void defineProperty(var obj, String property, var value) {
  JS('void',
      'Object.defineProperty(#, #, '
          '{value: #, enumerable: false, writable: true, configurable: true})',
      obj,
      property,
      value);
}
