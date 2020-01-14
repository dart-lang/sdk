// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MixinA<T> {
  T intField;
}

class MixinB<S> {
  S stringField;
}

class MixinC<U, V> {
  U listField;
  V mapField;
}

class C extends Object with MixinA<int>, MixinB<String>, MixinC<List, Map> {}

void main() {
  var c = new C();
  c.intField = 0;
  c.stringField = '';
  c.listField = [];
  c.mapField = {};
}
