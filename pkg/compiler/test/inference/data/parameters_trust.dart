// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*member: main:[null|powerset={null}]*/
main() {
  trustParameters();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustParameters:[exact=JSUInt31|powerset={I}]*/
_trustParameters(
  int
  /*spec.Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  /*prod.[exact=JSUInt31|powerset={I}]*/
  i,
) {
  return i;
}

/*member: trustParameters:[null|powerset={null}]*/
trustParameters() {
  dynamic f = _trustParameters;
  Expect.equals(0, f(0));
  Expect.throws(/*[null|subclass=Object|powerset={null}{IN}]*/ () => f('foo'));
}
