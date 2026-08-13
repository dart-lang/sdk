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

/*member: _trustParameters:[exact=JSUInt31|powerset={I}{O}{N}]*/
_trustParameters(
  int
  /*spec.Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  /*prod.[exact=JSUInt31|powerset={I}{O}{N}]*/
  i,
) {
  return i;
}

/*member: trustParameters:[null|powerset={null}]*/
trustParameters() {
  dynamic f = _trustParameters;
  Expect.equals(0, f(0));
  Expect.throws(
    /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ () => f('foo'),
  );
}
