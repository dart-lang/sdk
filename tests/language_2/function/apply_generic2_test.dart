// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

makeFn() {
  return <T extends num>({T a1, T a2, T a3, T a4, T a5}) {
    return <T>[a1, a2, a3, a4, a5];
  };
}

staticFn<T extends num>({T a1, T a2, T a3, T a4, T a5, T xx}) {
  return <T>[a1, a2, a3, a4, a5, xx];
}

class CCC {
  memberFn<T extends num>({T a1, T a2, T a3, T a4, T a5, T yy}) {
    return <T>[a1, a2, a3, a4, a5, yy];
  }
}

check(a, b) {
  print('a: $a\nb: $b');
  Expect.equals(a.toString(), b.toString());
}

main() {
  check('[null, 33, null, 11, 22, null]',
      Function.apply(new CCC().memberFn, [], {#a4: 11, #a5: 22, #a2: 33}));

  Expect.throwsTypeError(
      () => Function.apply(new CCC().memberFn, [], {#a3: 'hi'}));

  check('[11, 22, 33, null, null]',
      Function.apply(makeFn(), [], {#a1: 11, #a2: 22, #a3: 33}));

  check('[null, 33, null, 11, 22]',
      Function.apply(makeFn(), [], {#a4: 11, #a5: 22, #a2: 33}));

  Expect.throwsTypeError(() => Function.apply(makeFn(), [], {#a3: 'hi'}));

  check('[null, 33, null, 11, 22, null]',
      Function.apply(staticFn, [], {#a4: 11, #a5: 22, #a2: 33}));

  Expect.throwsTypeError(() => Function.apply(staticFn, [], {#a3: 'hi'}));
}
