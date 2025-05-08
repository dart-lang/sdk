// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for Container type for Lists with huge or negative sizes.

/*member: main:[null|powerset={null}]*/
main() {
  hugeList1();
  hugeList2();
  hugeList3();
  hugeList4();
}

/*member: thing:[null|powerset={null}]*/
dynamic thing;

/*member: _huge1:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
final _huge1 = 5000000000;

/*member: hugeList1:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [null|powerset={null}], length: null, powerset: {I}{F}{M})*/
hugeList1() => List.filled(_huge1, thing);

const _huge2a = 10000000000 * 10000000000;

/*member: _huge2b:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
final _huge2b = _huge2a;

/*member: hugeList2:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [null|powerset={null}], length: null, powerset: {I}{F}{M})*/
hugeList2() => List.filled(_huge2b, thing);

const _huge3a = -10000000;

/*member: _huge3b:[subclass=JSInt|powerset={I}{O}{N}]*/
final _huge3b = _huge3a;

/*member: hugeList3:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [null|powerset={null}], length: null, powerset: {I}{F}{M})*/
hugeList3() => List.filled(_huge3b, thing);

// 'Small' limits are still tracked.

/*member: _huge4:[exact=JSUInt31|powerset={I}{O}{N}]*/
final _huge4 = 10000000;

/*member: hugeList4:Container([exact=JSFixedArray|powerset={I}{F}{M}], element: [null|powerset={null}], length: 10000000, powerset: {I}{F}{M})*/
hugeList4() => List.filled(_huge4, thing);
