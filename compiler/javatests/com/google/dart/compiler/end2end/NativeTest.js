// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_NativeTest_jsIncrementBy(x, y) {
  return native_NativeTest_dartIncrementBy(x, y);
}

function FooBar() {
  this.js_const = 499;
}

function native_NativeClass_bar(x, y) {
  return this.js_const - x - y;
}

function native_NativeClass__createFooBar() {
  return new FooBar();
}

function JSA() {}

function native_NativeA__new() {
  return new JSA();
}
