// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'main_lib.dart';

enum A { a, b }

enum B {
  a,
  b;

  static const B c = B.a;
}

int? a1(A? a) {
  switch (a) {
    case A.a:
      return 0;
  }
}

int? a2(A? a) {
  switch (a) {
    case null:
      return null;
    case A.a:
      return 0;
  }
}

int b1(B b) {
  switch (b) {
    case B.a:
      return 0;
    case B.b:
      return 1;
  }
}

int? b2(B? b) {
  switch (b) {
    case null:
      return null;
    case B.a:
      return 0;
  }
}

int? c1(C? c) {
  switch (c) {
    case C.a:
      return 0;
  }
}

int? c2(C? c) {
  switch (c) {
    case null:
      return null;
    case C.a:
      return 0;
  }
}

int d1(D d) {
  switch (d) {
    case D.a:
      return 0;
    case D.b:
      return 1;
  }
}

int? d2(D? d) {
  switch (d) {
    case null:
      return null;
    case D.a:
      return 0;
  }
}

void main() {
  a1(A.b);
  a2(A.b);
  b1(B.b);
  b2(B.b);
  c1(C.b);
  c2(C.b);
  d1(D.b);
  d2(D.b);
}
