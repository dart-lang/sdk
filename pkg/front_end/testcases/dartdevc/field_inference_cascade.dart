// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  static late final b = B()..c = c;
}

class B {
  late C c;
}

class C {}

late final c = C();
