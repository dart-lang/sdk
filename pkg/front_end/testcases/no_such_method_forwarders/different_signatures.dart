// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  dynamic noSuchMethod(Invocation invocation) => 42;

  void abstractMethod1(int i);
  void abstractMethod2(int i);
}

class SubClass extends Class {
  void abstractMethod1(num n);
  void abstractMethod2(int i);
}
