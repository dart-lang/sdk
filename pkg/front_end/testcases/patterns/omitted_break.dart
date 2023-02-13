// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b, c }

method(e) {
  switch (e) {
    case 0:
      print(0);
    case 1:
      print(1);
    case 2:
      print(2);
  }
  switch (e) {
    case int _ when e == 0:
      print(0);
    case int _ when e == 1:
      print(1);
    case int _ when e == 2:
      print(2);
  }
}

method2(Enum e) {
  switch (e) {
  case Enum.a:
    print(0);
  case Enum.b:
    print(1);
  case Enum.c:
    print(2);
  }
}