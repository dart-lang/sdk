// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_typing_uninitialized_variables`

class BadClass {
  static var bar; // LINT
  var foo; // LINT
  final baz; // LINT
  var a = 5,
      b; // LINT
  String d;

  BadClass(this.baz);

  void method() {
    var bar; // LINT
    bar = 5;
    print(bar);
  }

  void someMethod() {
    for (final v in <String>[]) {
      var foo; // LINT
      var bar = 8;
      foo = v.length;
      print('$foo$bar');
    }

    for (var i, // LINT
        j = 0; j < 5; i = j, j++) {
      print(i);
    }
  }
}

void aFunction() {
  var bar; // LINT
  bar = 5;
  print(bar);
}

var topLevel; // LINT
var other = 4;