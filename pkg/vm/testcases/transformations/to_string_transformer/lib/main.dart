// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

const keepToString = pragma('flutter:keep-to-string');
const keepToStringInSubtypes = pragma('flutter:keep-to-string-in-subtypes');

String toString() => 'I am static';

abstract class IFoo {
  @override
  String toString();
}

class Foo implements IFoo {
  @override
  String toString() => 'I am a Foo';
}

enum FooEnum { A, B, C }

class Keep {
  @keepToString
  @override
  String toString() => 'I am a Keep';
}

@keepToStringInSubtypes
class Base1 {}

class Base2 extends Base1 {}

class Base3 extends Object with Base2 {}

class KeepInherited implements Base3 {
  @override
  String toString() => 'Heir';
}

class MyException implements Exception {
  @override
  String toString() => 'A very detailed message';
}

void main() {
  final IFoo foo = Foo();
  print(foo.toString());
  print(Keep().toString());
  print(FooEnum.B.toString());
  print(KeepInherited().toString());
  print(MyException().toString());
}
