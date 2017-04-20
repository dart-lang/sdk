// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A implements C {}

class B extends A {}

class C extends B implements D {}

class D {}

main() {
  print(new A());
  print(new B());
  print(new C());
  print(new D());
}
