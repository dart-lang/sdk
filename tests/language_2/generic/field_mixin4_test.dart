// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic types in mixins are handled.

import 'package:expect/expect.dart';

class M<T> {
  bool field = () {
    try {
      throw 0;
    } on T catch (e) {
      return true;
    } catch (e) {}
    return false;
  }();
}

class A<U> {}

class C1<V> = Object with M<V>;
class C2 = Object with M<int>;
class C3 = Object with M<String>;

main() {
  Expect.isTrue(new C1<int>().field);
  Expect.isFalse(new C1<String>().field);

  Expect.isTrue(new C2().field);

  Expect.isFalse(new C3().field);
}
