// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test for Container type for Lists with huge or negative sizes.

/*member: main:[null]*/
main() {
  hugeList1();
  hugeList2();
  hugeList3();
  hugeList4();
}

/*member: _huge1:[subclass=JSPositiveInt]*/
final _huge1 = 5000000000;

/*member: hugeList1:Container([exact=JSFixedArray], element: [null], length: null)*/
hugeList1() => List(_huge1);

const _huge2a = 10000000000 * 10000000000;

/*member: _huge2b:[subclass=JSPositiveInt]*/
final _huge2b = _huge2a;

/*member: hugeList2:Container([exact=JSFixedArray], element: [null], length: null)*/
hugeList2() => List(_huge2b);

const _huge3a = -10000000;

/*member: _huge3b:[subclass=JSInt]*/
final _huge3b = _huge3a;

/*member: hugeList3:Container([exact=JSFixedArray], element: [null], length: null)*/
hugeList3() => List(_huge3b);

// 'Small' limits are still tracked.

/*member: _huge4:[exact=JSUInt31]*/
final _huge4 = 10000000;

/*member: hugeList4:Container([exact=JSFixedArray], element: [null], length: 10000000)*/
hugeList4() => List(_huge4);
