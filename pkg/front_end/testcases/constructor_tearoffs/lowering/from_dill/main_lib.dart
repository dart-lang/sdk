// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {}

class Class2 {
  Class2.named();
  factory Class2.redirect() = Class2.named;
}

class Class3 {
  final int field;

  Class3(this.field);
}

class Class4<T> {
  Class4._();
  factory Class4() => new Class4<T>._();
  factory Class4.redirect() = Class4._;
}

class Class5<T extends num> {
  Class5._();
  factory Class5() => new Class5<T>._();
}
