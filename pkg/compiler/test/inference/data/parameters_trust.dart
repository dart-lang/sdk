// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*member: main:[null|powerset=1]*/
main() {
  trustParameters();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustParameters:[exact=JSUInt31|powerset=0]*/
_trustParameters(
  int
  /*spec.Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  /*prod.[exact=JSUInt31|powerset=0]*/
  i,
) {
  return i;
}

/*member: trustParameters:[null|powerset=1]*/
trustParameters() {
  dynamic f = _trustParameters;
  Expect.equals(0, f(0));
  Expect.throws(/*[null|subclass=Object|powerset=1]*/ () => f('foo'));
}
