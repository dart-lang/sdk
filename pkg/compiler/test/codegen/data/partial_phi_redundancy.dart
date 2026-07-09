// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:never-inline')
/*member: foo1:function(x) {
  if (Date.now() > 0) {
    if (typeof x != "string")
      return "bad1";
  } else if (typeof x != "string")
    return "bad2";
  return x;
}*/
String foo1(Object x) {
  final Object y;
  if (DateTime.now().millisecondsSinceEpoch > 0) {
    if (x is! String) return 'bad1';
    y = x;
  } else {
    if (x is! String) return 'bad2';
    y = x;
  }
  // The phi for y has refinements to String on both branches, so the return
  // should not need stringification.
  return '$y';
}

/*member: main:ignore*/
main() {
  print(foo1('a'));
  print(foo1('b'));
  print(foo1(123));
}
