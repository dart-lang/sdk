// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // If the duration class multiplies "str" * microseconds-per-day (instead of
  // (microseconds-per-day * "str") it will try to build up a huge string and
  // terminate with an out-of-memory exception instead of an ArgumentError or
  // TypeError.
  // See dartbug.com/22309

  String longString = "str" * 1000;
  Expect.throws(() => new Duration(days: longString),
      (e) => e is ArgumentError || e is TypeError || e is NoSuchMethodError);
  Expect.throws(() => new Duration(hours: longString),
      (e) => e is ArgumentError || e is TypeError || e is NoSuchMethodError);
  Expect.throws(() => new Duration(minutes: longString),
      (e) => e is ArgumentError || e is TypeError || e is NoSuchMethodError);
  Expect.throws(() => new Duration(seconds: longString),
      (e) => e is ArgumentError || e is TypeError || e is NoSuchMethodError);
  Expect.throws(() => new Duration(milliseconds: longString),
      (e) => e is ArgumentError || e is TypeError || e is NoSuchMethodError);
  Expect.throws(() => new Duration(microseconds: longString),
      (e) => e is ArgumentError || e is TypeError || e is NoSuchMethodError);
}
