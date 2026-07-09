// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {
  var $identityHash;
}

void main() {
  Foo foo = new Foo();
  foo.$identityHash = 'fisk';
  Expect.isTrue(foo.$identityHash is String);
  int hash = foo.hashCode;
  Expect.isTrue(hash is int);
  Expect.isTrue(foo.$identityHash is String);
  Expect.equals(hash, foo.hashCode);
}
