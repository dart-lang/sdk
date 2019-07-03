// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  hugeList1();
  hugeList2();
}

/*element: _huge1:[subclass=JSPositiveInt]*/
final _huge1 = 5000000000;

/*element: hugeList1:Container([exact=JSFixedArray], element: [null], length: 5000000000)*/
hugeList1() => List(_huge1);

/*strong.element: _huge2a:[subclass=JSPositiveInt]*/
/*omit.element: _huge2a:[subclass=JSPositiveInt]*/
const _huge2a = 10000000000
/*strong.invoke: [subclass=JSPositiveInt]*/
/*omit.invoke: [subclass=JSPositiveInt]*/
    *
    10000000000;

/*strong.element: _huge2b:[null|subclass=JSPositiveInt]*/
/*omit.element: _huge2b:[null|subclass=JSPositiveInt]*/
/*strongConst.element: _huge2b:[subclass=JSPositiveInt]*/
/*omitConst.element: _huge2b:[subclass=JSPositiveInt]*/
final _huge2b = _huge2a;

/*element: hugeList2:Container([exact=JSFixedArray], element: [null], length: 9223372036854775807)*/
hugeList2() => List(_huge2b);
