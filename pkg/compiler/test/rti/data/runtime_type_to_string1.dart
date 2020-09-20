// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class1 {
  Class1();
}

class Class2<T> {
  Class2();
}

/*spec.class: Class3:needsArgs*/
class Class3<T> implements Class1 {
  Class3();
}

main() {
  Class1 cls1 = new Class1();
  print(cls1.runtimeType.toString());
  new Class2<int>();
  Class1 cls3 = new Class3<int>();
  print(cls3.runtimeType.toString());
}
