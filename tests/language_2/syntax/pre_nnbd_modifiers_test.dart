// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that the modifiers added as part of NNBD are not enabled
// until NNBD is enabled by default. At that time, this test should be removed.

// [NNBD non-migrated] Note: This test is specific to legacy mode and
// deliberately does not have a counter-part in language/.

import 'package:expect/expect.dart';

class late {
  int get g => 1;
}

class required {
  int get g => 2;
}

class C {
  late l = late();
  required r = required();
}

main() {
  Expect.equals(C().l.g, 1);
  Expect.equals(C().r.g, 2);
}
