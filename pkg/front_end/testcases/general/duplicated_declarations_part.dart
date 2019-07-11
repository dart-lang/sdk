// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "duplicated_declarations.dart";

import 'duplicated_declarations_lib.dart' as Typedef;

import 'duplicated_declarations_lib.dart' as Typedef;

typedef Typedef = void Function();

typedef Typedef = Object Function();

import 'duplicated_declarations_lib.dart' as Typedef;

typedef void OldTypedef();

typedef Object OldTypedef();

var field = "3rd";

var field = 4;

var field = 5.0;

main() {
  "3rd";
}

main() {
  "4th";
}

main() {
  "5th";
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

class C {
  C._();
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

enum Enum {
  a,
}
