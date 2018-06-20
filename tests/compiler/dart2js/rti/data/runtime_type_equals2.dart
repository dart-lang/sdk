// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*class: Class1a:needsArgs*/
class Class1a<T> {
  /*kernel.element: Class1a.:needsSignature*/
  /*!kernel.element: Class1a.:*/
  Class1a();

  /*kernel.element: Class1a.==:needsSignature*/
  /*!kernel.element: Class1a.==:*/
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType;
  }
}

/*class: Class1b:needsArgs*/
class Class1b<T> extends Class1a<T> {
  /*kernel.element: Class1b.:needsSignature*/
  /*!kernel.element: Class1b.:*/
  Class1b();
}

// TODO(johnniwinther): Specialize handling of `this.runtimeType` to exclude
// this class.
/*class: Class1c:needsArgs*/
class Class1c<T> implements Class1a<T> {
  /*kernel.element: Class1c.:needsSignature*/
  /*!kernel.element: Class1c.:*/
  Class1c();
}

/*kernel.class: Class2:needsArgs*/
/*!kernel.class: Class2:*/
class Class2<T> {
  /*kernel.element: Class2.:needsSignature*/
  /*!kernel.element: Class2.:*/
  Class2();
}

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
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
