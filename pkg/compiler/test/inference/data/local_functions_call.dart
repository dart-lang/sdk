// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is the same test as `closureCallToString` in 'local_functions.dart' but
// with a different expectancy because the closed world contains less '.call'
// methods.

/*member: main:[null|powerset={null}]*/
main() {
  closureCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Explicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureCallToString:[exact=JSString|powerset={I}{O}{I}]*/
closureCallToString() {
  var local = /*[null|powerset={null}]*/ () {};
  local.call();
  return local
      .
      /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/
      toString();
}
