// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that substitutions are emitted for classes that are only used as
// type arguments.

import 'package:expect/expect.dart';

class K {}

/*class: A:explicit=[X<A<String*>*>*]*/
class A<T> {}

class B extends A<K> {}

/*class: X:explicit=[X<A<String*>*>*],needsArgs*/
class X<T> {}

main() {
  var v = new DateTime.now().millisecondsSinceEpoch != 42
      ? new X<B>()
      : new X<A<String>>();
  Expect.isFalse(v is X<A<String>>);
}
