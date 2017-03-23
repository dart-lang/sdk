// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const x = const {
  'a': 3, // //# 01: static type warning
  'a': 4
};
const y = const { 'a': 10, 'b': 11, 'a': 12, // //# 02: static type warning
                  'b': 13, 'a': 14 }; //        //# 02: continued
const z = const {
  '__proto__': 496, // //# 03: static type warning
  '__proto__': 497, // //# 03: continued
  '__proto__': 498, // //# 03: continued
  '__proto__': 499
};

const x2 = const {'a': 4};
const y2 = const {'a': 14, 'b': 13};
const z2 = const {'__proto__': 499};

main() {
  Expect.identical(x2, x);
  Expect.identical(y2, y); // //# 02: continued
  Expect.identical(z2, z);
}
