// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x1) {
  if (x1 case int a1 && < a1 || int a1) { // Error.
    return a1;
  } else if (x1 case int a1 || int a1 && < a1) { // Error.
    return a1;
  } else {
    return null;
  }
}

test2(dynamic x2) {
  switch (x2) {
    case int a2:
    case String a2:
      return 1;
    default:
      return 0;
  }
}

test3(dynamic x3) {
  switch (x3) {
    case int a3 && < a3: // Error.
    case String a3 && == a3: // Error.
      return 1;
    default:
      return 0;
  }
}

test4(dynamic x4) {
  switch (x4) {
    case int a4 && < a4 when a4 > 0: // Error.
    case String a4 && == a4 when a4.startsWith("f"): // Error.
      return 1;
    default:
      return 0;
  }
}

test5(dynamic x5) {
  return switch (x5) {
    int a5 && < a5 => 1, // Error.
    _ => 0
  };
}

test6(dynamic x6) {
  return {for (var [int i6, int n6] = x6; i6 < n6; i6++) i6};
}

test7(dynamic x7) {
  for (var [int i7, int n7] = x7; i7 < n7; i7++) {
    if (i7 % 3 == 0) return i7;
  }
  return null;
}
