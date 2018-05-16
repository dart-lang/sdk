// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: main:[null]*/
main() {
  trustParameters();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a parameter with
// --trust-type-annotations or --omit-implicit-checks.
////////////////////////////////////////////////////////////////////////////////

/*element: _trustParameters:[exact=JSUInt31]*/
_trustParameters(int /*[exact=JSUInt31]*/ i) {
  return i;
}

/*element: trustParameters:[null]*/
trustParameters() {
  dynamic f = _trustParameters;
  Expect.equals(0, f(0));
  Expect.throws(/*[null|subclass=Object]*/ () => f('foo'));
}
