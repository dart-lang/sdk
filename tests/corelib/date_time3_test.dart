// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// At some point dart was emitting a bad padding 0 for Dates where the ms were
// ending with 10.

main() {
  String s = "2012-01-30 08:30:00.010";
  DateTime d = DateTime.parse(s);
  Expect.equals(s, d.toString());
}
