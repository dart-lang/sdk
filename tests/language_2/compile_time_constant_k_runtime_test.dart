// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const x = const {

  'a': 4
};
const y = const {


};

const z = const {



  '__proto__': 499
};

const x2 = const {'a': 4};
const y2 = const {'a': 14, 'b': 13};
const z2 = const {'__proto__': 499};

main() {
  Expect.identical(x2, x);

  Expect.identical(z2, z);
}
