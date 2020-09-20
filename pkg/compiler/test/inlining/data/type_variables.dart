// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  inlineTypeTests();
}

/*member: Mixin1.:closure*/
class Mixin1<S> {
  var field = /*[]*/ (S s) => null;
}

/*member: Class1.:closure*/
class Class1<T> extends Object with Mixin1<T> {}

/*member: _inlineTypeTests:[inlineTypeTests]*/
_inlineTypeTests(o) => o.field is dynamic Function(int);

/*member: inlineTypeTests:[]*/
@pragma('dart2js:noInline')
void inlineTypeTests() {
  _inlineTypeTests(new Mixin1<int>());
  _inlineTypeTests(new Class1<int>());
}
