// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  check(0x8000000000000000);

  check(0x7FFF00001111F000);
  check(0x7FFF00001111FC00);




  check(0xFFFF00001111F000);
  check(0xFFFF00001111F800);





  // Test all runs of 53 and 54 bits.
  check(0x000FFFFFFFFFFFFF);
  check(0x001FFFFFFFFFFFFF);

  check(0x003FFFFFFFFFFFFE);

  check(0x007FFFFFFFFFFFFC);

  check(0x00FFFFFFFFFFFFF8);

  check(0x01FFFFFFFFFFFFF0);

  check(0x03FFFFFFFFFFFFE0);

  check(0x07FFFFFFFFFFFFC0);

  check(0x0FFFFFFFFFFFFF80);

  check(0x1FFFFFFFFFFFFF00);

  check(0x3FFFFFFFFFFFFE00);

  check(0x7FFFFFFFFFFFFC00);

  check(0xFFFFFFFFFFFFF800);

  // Too big, even on VM.



  // 9223372036854775808 - 512 is rounded.

  // 9223372036854775808 - 1024 is exact.
  check(9223372036854774784);

  check(-9223372036854775808);


  check(-9223372036854774784);


}

check(int n) {}
