// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  inlineTypeTests();
}

/*element: Mixin1.:[inlineTypeTests:Mixin1<int>]*/
class Mixin1<S> {
  var field = /*[]*/ (S s) => null;
}

/*element: Class1.:[inlineTypeTests:Class1<int>]*/
class Class1<T> extends Object with Mixin1<T> {}

/*element: _inlineTypeTests:[inlineTypeTests]*/
_inlineTypeTests(o) => o.field is dynamic Function(int);

/*element: inlineTypeTests:[]*/
@NoInline()
void inlineTypeTests() {
  _inlineTypeTests(new Mixin1<int>());
  _inlineTypeTests(new Class1<int>());
}
