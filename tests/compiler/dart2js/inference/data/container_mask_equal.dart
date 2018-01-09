// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to have a bogus
// implementation of var.== and var.hashCode.

import 'dart:typed_data';

/*element: method1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
method1() => [0];

/*element: method2:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/
method2() => [1, 2];

/*element: method3:Container([exact=NativeUint8List], element: [exact=JSUInt31], length: 1)*/
method3() => new Uint8List(1);

/*element: method4:Container([exact=NativeUint8List], element: [exact=JSUInt31], length: 2)*/
method4() => new Uint8List(2);

/*element: method1or2:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
method1or2(/*[exact=JSBool]*/ c) => c ? method1() : method2();

/*element: method3or4:Container([exact=NativeUint8List], element: [exact=JSUInt31], length: null)*/
method3or4(/*[exact=JSBool]*/ c) => c ? method3() : method4();

/*element: main:[null]*/
main() {
  method1or2(true);
  method1or2(false);
  method3or4(true);
  method3or4(false);
}
