// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  var bar = Bar();
  bar.doStuff();
}

class Foo {
  final List<String> /*s:7*/ /*s:9*/ /*s:12*/ /*s:14*/ data1;

  Foo() : data1 = ['a', 'b', 'c'];

  void doStuff() {
    print(data1);
    print(data1[1]);
  }
}

class Bar extends Foo {
  final List<String> /*s:2*/ /*s:4*/ data2;
  Foo data3;

  Bar() : data2 = ['d', 'e', 'f'] {
    data3 = this;
  }

  @override
  void doStuff() {
    /* bl */
    /*s:1*/ print(data2);
    /*s:3*/ print(data2 /*sl:5*/ [1]);

    /*s:6*/ print(data1);
    /*s:8*/ print(data1 /*sl:10*/ [1]);

    /*s:11*/ print(super.data1);
    /*s:13*/ print(super.data1 /*sl:15*/ [1]);
  }
}
