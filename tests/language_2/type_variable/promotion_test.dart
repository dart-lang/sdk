// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class Foo<T extends A> {
  String foo(T x) {
    if (x is B) {
      var list = [x];
      return list.runtimeType.toString();
    }
    return '';
  }

  List<T> bar(T x) {
    var tlist = <T>[];
    if (x is B) {
      var list = [x];
      tlist = list;
    }
    return tlist;
  }
}

main() {
  var foo = new Foo<B>();
  var b = new B();

  // List class has many different platform specific implementations
  // so we can't rely on the fact that all of them have the same
  // user visible name. Instead we build a name for List<B> from List<A>.
  final expected = (<A>[]).runtimeType.toString().replaceAll('<$A>', '<$B>');
  Expect.equals(expected, foo.foo(b));
  Expect.listEquals([b], foo.bar(b));
}
