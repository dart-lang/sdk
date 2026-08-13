// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-filter=var50 --deoptimize-every=1

final var50 = Expando<int>('expando');

foo(int arg) {
  if (arg >= 14) {
    return var50[15];
  }
  try {
    return foo(arg + 1);
  } catch (exception) {}

  foo(arg + 1);
}

main() {
  try {
    foo(0);
  } catch (e) {
    print('rows');
  }
}
