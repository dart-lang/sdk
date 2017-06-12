// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib1;

class ConstClass {
  final x;
  const ConstClass(this.x);
}

var x = const ConstClass(const ConstClass(1));

class C {
  static foo() {
    () {}(); // Hack to avoid inlining.
    return 1;
  }

  bar() {
    () {}(); // Hack to avoid inlining.
    return 1;
  }
}

class C1 {
  static var foo = const {};
  var bar = const {};
}

class C2 {
  static var foo = new Map.from({1: 2});
  var bar = new Map.from({1: 2});
}

class C3 {
  static final foo = const ConstClass(const ConstClass(1));
  final bar = const ConstClass(const ConstClass(1));
}

class C4 {
  static final foo = new Map.from({x: x});
  final bar = new Map.from({x: x});
}

class C5 {
  static const foo = const [
    const {1: 3}
  ];
  bar() {
    () {}(); // Hack to avoid inlining.
    return 1;
  }
}
