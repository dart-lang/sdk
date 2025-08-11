// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int _defaultF1() => 41;
int _defaultF2() => 42;
int _defaultF3() => 43;

class Foo1 {
  final int Function() f1;
  const Foo1({this.f1 = _defaultF1});

  @override
  String toString() => "Foo1:${f1()}";
}

class Foo2 {
  final int Function() _f2 = _defaultF2;
  const Foo2();

  @override
  String toString() => "Foo2:${_f2()}";
}

class Foo3 {
  final int Function() _f3;
  const Foo3() : _f3 = _defaultF3;

  @override
  String toString() => "Foo3:${_f3()}";
}
