// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.




final x = 1; //LINT
final int xx = 3;
const y = 2; //LINT
const int yy = 3;

a(var x) {} //LINT
b(s) {} //LINT
c(int x) {}
d(final x) {} //LINT
e(final int x) {}

main() {
  var x = ''; //LINT
  for (var i = 0; i < 10; ++i) { //LINT
  }
  List<String> l = <String>[];
  l.forEach((s) => print(s)); //LINT
}

var z; //LINT

class Foo {
  static var bar; //LINT
  static final baz  = 1; //LINT
  static final int bazz = 42;
  var foo; //LINT
  Foo(var bar); //LINT
}
