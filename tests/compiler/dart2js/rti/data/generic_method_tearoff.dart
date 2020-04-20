// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

T method1a<T>() => null;
T method1b<T>() => null;

class Class {
  T method2a<T>() => null;
  T method2b<T>() => null;
}

main() {
  method1a();
  T Function<T>() f1 = method1b;

  Class c = new Class();
  c.method2a();
  T Function<T>() f2 = c.method2b;

  print(f1.runtimeType == f2.runtimeType);
}
