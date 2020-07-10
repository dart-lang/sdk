// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*member: main:[null]*/
main() {
  trustParameters();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustParameters:[exact=JSUInt31]*/
_trustParameters(
    int
        /*spec.Union([exact=JSString], [exact=JSUInt31])*/
        /*prod.[exact=JSUInt31]*/
        i) {
  return i;
}

/*member: trustParameters:[null]*/
trustParameters() {
  dynamic f = _trustParameters;
  Expect.equals(0, f(0));
  Expect.throws(/*[null|subclass=Object]*/ () => f('foo'));
}
