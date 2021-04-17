// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() async {
  final a = A();
  print(a is N);
  print(a is M);
}

mixin M {
  int get number => 20;
}

mixin N {
  String get text => 'Foo';
}

class Mixed = Object with N, M;

class A with Mixed {}
