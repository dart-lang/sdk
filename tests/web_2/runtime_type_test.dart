// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong --no-minify

// Test that Type.toString returns nice strings for native classes with
// reserved names and for raw types.

import "package:expect/expect.dart";

class C<T> {}

class D<X, Y, Z> {}

class Class$With$Dollar {}

void main() {
  Expect.equals('C<dynamic>', new C().runtimeType.toString());
  Expect.equals('C<int>', new C<int>().runtimeType.toString());
  Expect.equals('C<double>', new C<double>().runtimeType.toString());
  Expect.equals('C<num>', new C<num>().runtimeType.toString());
  Expect.equals('C<bool>', new C<bool>().runtimeType.toString());
  Expect.equals('D<dynamic, dynamic, dynamic>', new D().runtimeType.toString());
  Expect.equals('D<dynamic, int, dynamic>',
      new D<dynamic, int, dynamic>().runtimeType.toString());
  D d = new D<dynamic, D, D<dynamic, dynamic, int>>();
  Expect.equals(
      'D<dynamic, D<dynamic, dynamic, dynamic>, D<dynamic, dynamic, int>>',
      d.runtimeType.toString());
  Expect.equals(r'C<Class$With$Dollar>',
      new C<Class$With$Dollar>().runtimeType.toString());
}
