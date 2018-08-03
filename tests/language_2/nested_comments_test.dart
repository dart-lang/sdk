// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing nested comments

import "package:expect/expect.dart";

// /* nested comment */
/*// nested comment */
/*/* nested comment */*/
/* entire function
void main() {
  /* nested comment */
  Expect.isTrue(false); // nested
}
*/

/**
 test documentation
 /* nested comment */
*/
main() {
  Expect.isTrue(true);
}
