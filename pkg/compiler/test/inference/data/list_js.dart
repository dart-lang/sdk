// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test effect of NativeBehavior on list tracing.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper' show JS;

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
}

/*member: test1:[null|powerset={null}]*/
test1() {
  var list = [42];
  JS('', '#', list); // '#' is by default a no-op.
  witness1(list);
}

/*member: witness1:[null|powerset={null}]*/
witness1(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/ x,
) {}

/*member: test2:[null|powerset={null}]*/
test2() {
  var list = [42];
  JS('effects:all;depends:all', '#', list);
  witness2(list);
}

/*member: witness2:[null|powerset={null}]*/
witness2(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/ x,
) {}

/*member: test3:[null|powerset={null}]*/
test3() {
  var list = [42];
  JS('', '#.slice(0)', list);
  witness3(list);
}

/*member: witness3:[null|powerset={null}]*/
witness3(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}], length: null, powerset: {I}{G}{M})*/ x,
) {}

/*member: test4:[null|powerset={null}]*/
test4() {
  var list = [42];
  JS('effects:none;depends:all', '#.slice(0)', list);
  witness4(list);
}

/*member: witness4:[null|powerset={null}]*/
witness4(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/ x,
) {}
