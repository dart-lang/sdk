// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to have a bogus
// implementation of var.== and var.hashCode.

import 'dart:typed_data';

/*member: method1:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
method1() => [0];

/*member: method2:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
method2() => [1, 2];

/*member: method3:Container([exact=NativeUint8List|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
method3() => Uint8List(1);

/*member: method4:Container([exact=NativeUint8List|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
method4() => Uint8List(2);

/*member: method1or2:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0)*/
method1or2(/*[exact=JSBool|powerset=0]*/ c) => c ? method1() : method2();

/*member: method3or4:Container([exact=NativeUint8List|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0)*/
method3or4(/*[exact=JSBool|powerset=0]*/ c) => c ? method3() : method4();

/*member: main:[null|powerset=1]*/
main() {
  method1or2(true);
  method1or2(false);
  method3or4(true);
  method3or4(false);
}
