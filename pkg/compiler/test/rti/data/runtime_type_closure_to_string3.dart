// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: Class1:needsArgs*/
class Class1<T> {
  Class1();

  /*spec.member: Class1.method:needsSignature*/
  T method() => null;
}

class Class2<T> {
  Class2();
}

main() {
  Class1<int> cls1 = new Class1<int>();
  print(cls1.method.runtimeType.toString());
  new Class2<int>();
}
