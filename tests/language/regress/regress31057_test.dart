// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--reify-generic-functions

import 'package:expect/expect.dart';

class Foo<T> {
  a<A>() {
    b<B>() {
      c<C>() => '$T $A $B $C';
      return c;
    }

    return b;
  }
}

main() {
  Expect.equals('bool int double String',
      ((new Foo<bool>().a<int>())<double>())<String>());
}
