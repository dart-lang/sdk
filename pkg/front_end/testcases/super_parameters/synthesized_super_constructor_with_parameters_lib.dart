// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A6 {
  final int a;
  A6({this.a = 0});
}

class B6 {}

// C6 has a synthesized constructor that takes a named parameter.
class C6 = A6 with B6;

class A7 {
  final int a;
  A7([this.a = 0]);
}

class A8 {
  final int? a;
  A8({this.a});
}

class B8 {}

// C8 has a synthesized constructor that takes a named parameter.
class C8 = A8 with B8;

class A9 {
  final int? a;
  A9([this.a]);
}
