// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  switch (x) {
    case 0:
    case int i:
      return i; // Error.
    case String s:
    case "foo":
      return s; // Error.
    case double d:
    case < 3.14:
      return d; // Error.
    case == false:
    case bool b:
      return b; // Error.
    default:
      return null;
  }
}

test2(dynamic x) {
  switch (x) {
    case <= 0:
      continue L;
    L:
    case int i2:
      return i2; // Error.
    case String s2:
    default:
      return s2; // Error.
  }
}

test3(dynamic x) {
  switch (x) {
    case <= 0:
      continue L;
    L:
    case int i3:
    case [int i3]:
      return i3; // Error.
    case String s3:
    case [String s3]:
    default:
      return s3; // Error.
  }
}

test4(dynamic x) {
  switch (x) {
    case <= 0:
      continue L;
    L:
    case int i4:
    case [double i4]:
      return i4; // Error.
    case String s4:
    case [final String s4]:
    default:
      return s4; // Error.
  }
}

test5(dynamic x) {
  switch (x) {
    case <= 0:
      continue L;
    L:
    case int i5 when i5 == 1: // Ok.
      return null;
    case String s5 when s5 == "foo": // Ok.
    default:
      return null;
  }
}

test6(dynamic x, bool b) {
  switch (x) {
    case <= 0:
      continue L;
    L:
    case int i6:
      if (b) {
        return i6; // Error.
      }
    case String s6:
    default:
      if (b) {
        if (b) {
          return s6; // Error.
        }
      }
  }
}

test7(dynamic x) {
  switch (x) {
    case <= 0:
      continue L;
    L:
    case int i7 when i7 == 1: // Ok.
      int i7 = 1;
      return i7; // Still ok.
    case String s7 when s7 == "foo": // Ok.
    default:
      String s7 = "foo";
      return s7; // Still ok.
  }
}
