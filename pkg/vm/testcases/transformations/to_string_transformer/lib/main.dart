// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

const keepToString = pragma('flutter:keep-to-string');

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

void main() {
  final IFoo foo = Foo();
  print(foo.toString());
  print(Keep().toString());
  print(FooEnum.B.toString());
}
