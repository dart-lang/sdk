// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

List<T> staticFn<T>(
    [T a1, T a2, T a3, T a4, T a5, T a6, T a7, T a8, T a9, T a10]) {
  return <T>[a1, a2, a3, a4, a5, a6, a7, a8, a9, a10];
}

class C<CT> {
  List<T> memberFn<T>(
      [T a1, T a2, T a3, T a4, T a5, T a6, T a7, T a8, T a9, T a10]) {
    return <T>[a1, a2, a3, a4, a5, a6, a7, a8, a9, a10];
  }

  // Intercepted, e.g. on JSArray.
  List<T> map<T>(
      [T a1, T a2, T a3, T a4, T a5, T a6, T a7, T a8, T a9, T a10]) {
    return <T>[a1, a2, a3, a4, a5, a6, a7, a8, a9, a10];
  }
}

check(a, b) {
  print('a: $a\nb: $b');
  Expect.equals(a.toString(), b.toString());
}

main() {
  check('[1, 2, 3, null, null, null, null, null, null, null]',
      Function.apply(staticFn, [1, 2, 3]));

  check('[1, 2, 3, 4, null, null, null, null, null, null]',
      Function.apply(staticFn, [1, 2, 3, 4]));

  check('[1, 2, 3, 4, 5, 6, 7, null, null, null]',
      Function.apply(staticFn, [1, 2, 3, 4, 5, 6, 7]));

  var o = new C<num>();
  dynamic memberFn1 = o.map;

  check('[1, 2, 3, null, null, null, null, null, null, null]',
      Function.apply(memberFn1, [1, 2, 3]));

  check('[1, 2, 3, 4, null, null, null, null, null, null]',
      Function.apply(memberFn1, [1, 2, 3, 4]));

  check('[1, 2, 3, 4, 5, 6, 7, null, null, null]',
      Function.apply(memberFn1, [1, 2, 3, 4, 5, 6, 7]));

  dynamic memberFn2 = o.memberFn;

  check('[1, 2, 3, null, null, null, null, null, null, null]',
      Function.apply(memberFn2, [1, 2, 3]));

  check('[1, 2, 3, 4, null, null, null, null, null, null]',
      Function.apply(memberFn2, [1, 2, 3, 4]));

  check('[1, 2, 3, 4, 5, 6, 7, null, null, null]',
      Function.apply(memberFn2, [1, 2, 3, 4, 5, 6, 7]));

  // TODO(sra): Apply of instantiations
}
