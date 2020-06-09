// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

class Class1a<T> {
  Class1a();

  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType;
  }
}

class Class1b<T> extends Class1a<T> {
  Class1b();
}

class Class1c<T> implements Class1a<T> {
  Class1c();
}

class Class2<T> {
  Class2();
}

main() {
  Class1a<int> cls1a = new Class1a<int>();
  Class1a<int> cls1b1 = new Class1b<int>();
  Class1a<int> cls1b2 = new Class1b<int>();
  Class1c<int> cls1c = new Class1c<int>();
  Class2<int> cls2 = new Class2<int>();
  Expect.isFalse(cls1a == cls1b1);
  Expect.isTrue(cls1b1 == cls1b2);
  Expect.isFalse(cls1a == cls1c);
  Expect.isFalse(cls1a == cls2);
}
