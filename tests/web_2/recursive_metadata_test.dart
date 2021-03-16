// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

// Tests that the compiler doesn't crash resolving annotations that refer
// to other annotated types.

class Annotation {
  final String value;
  const Annotation({this.value});
}

enum Enum {
  a,
  b,
}

class SubAnno extends Annotation {
  final Enum e;
  final Type type;
  const SubAnno({String value, this.e, this.type}) : super(value: value);
}

@SubAnno(value: 'super')
class A {}

@SubAnno(value: 'sub')
class B extends A {}

@SubAnno(type: B)
class C {}

main() {
  var c = new C();
  Expect.isTrue(c != null);
}
