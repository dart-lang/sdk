// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library malformed_test;

// This part includes the actual tests.
part 'malformed2_lib.dart';

// The part-file cannot contain error markers.
// Therefore we create a fresh class for each test.
/* //# 01: compile-time error
class Unresolved1 {}
*/ //# 01: continued
/* //# 02: compile-time error
class Unresolved2 {}
*/ //# 02: continued
/* //# 03: compile-time error
class Unresolved3 {}
*/ //# 03: continued
/* //# 04: compile-time error
class Unresolved4 {}
*/ //# 04: continued
/* //# 05: compile-time error
class Unresolved5 {}
*/ //# 05: continued
/* //# 06: compile-time error
class Unresolved6 {}
*/ //# 06: continued
/* //# 07: compile-time error
class Unresolved7 {}
*/ //# 07: continued
/* //# 08: compile-time error
class Unresolved8 {}
*/ //# 08: continued
/* //# 09: compile-time error
class Unresolved9 {}
*/ //# 09: continued
/* //# 10: compile-time error
class Unresolved10 {}
*/ //# 10: continued
/* //# 11: compile-time error
class Unresolved11 {}
*/ //# 11: continued
/* //# 12: compile-time error
class Unresolved12 {}
*/ //# 12: continued
/* //# 13: compile-time error
class Unresolved13 {}
*/ //# 13: continued

const Unresolved c1 = 0;  //# 00: compile-time error

void main() {
  print(c1);  //# 00: continued
  testValue(null);
}
