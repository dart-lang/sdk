// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part "duplicated_declarations_part.dart";

import 'duplicated_declarations_lib.dart' as Typedef;

import 'duplicated_declarations_lib.dart' as Typedef;

typedef Typedef = void Function();

typedef Typedef = Object Function();

import 'duplicated_declarations_lib.dart' as Typedef;

typedef void OldTypedef();

typedef Object OldTypedef();

var field = "1st";

var field = "2nd";

main() {
  "1st";
}

main() {
  "2nd";
}

foo() {
  main();
  print(field);
  C.s();
}

class C {
  C(a);
  C(a, b);
  var field = "1st";

  var field = "2nd";

  m() {
    "1st";
  }

  m() {
    "2nd";
  }

  static s() {
    "1st";
  }

  static s() {
    "2nd";
  }

  static f() => s;
}

class Sub extends C {
  Sub() : super(null);
  m() => super.m();
}

class C {
  C._();
}

enum Enum {
  Enum,
  a,
  a,
  b,
}

enum Enum {
  a,
  b,
  c,
}

enum AnotherEnum {
  a,
  b,
  c,
  _name,
  index,
  toString,
  values,
}

useAnotherEnum() {
  <String, Object>{
    "AnotherEnum.a": AnotherEnum.a,
    "AnotherEnum.b": AnotherEnum.b,
    "AnotherEnum.c": AnotherEnum.c,
    "AnotherEnum._name": AnotherEnum._name,
    "AnotherEnum.index": AnotherEnum.index,
    "AnotherEnum.toString": AnotherEnum.toString,
    "AnotherEnum.values": AnotherEnum.values,
  };
}
