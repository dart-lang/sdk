// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*element: main:[null]*/
main() {
  awaitOfFuture();
  awaitOfInt();
  awaitForOfStream();
}

////////////////////////////////////////////////////////////////////////////////
// Await of Future.value.
////////////////////////////////////////////////////////////////////////////////

/*element: _method1:[null]*/
_method1(/*[null|subclass=Object]*/ o) {}

/*element: awaitOfFuture:[exact=_Future]*/
awaitOfFuture() async {
  var future = new Future.value(0);
  var local = await future;
  _method1(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await of int.
////////////////////////////////////////////////////////////////////////////////

/*element: _method2:[null]*/
_method2(/*[null|subclass=Object]*/ o) {}

/*element: awaitOfInt:[exact=_Future]*/
awaitOfInt() async {
  var local = await 0;
  _method2(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await for of Stream.fromIterable.
////////////////////////////////////////////////////////////////////////////////

/*element: _method3:[null]*/
_method3(
    /*Container mask: [exact=JSUInt31] length: 1 type: [exact=JSExtendableArray]*/ o) {}

/*element: _method4:[null]*/
_method4(/*[null|subclass=Object]*/ o) {}

/*element: awaitForOfStream:[exact=_Future]*/
awaitForOfStream() async {
  var list = [0];
  _method3(list);
  var stream = new Stream.fromIterable(list);
  /*current: [exact=_StreamIterator]*/
  /*moveNext: [exact=_StreamIterator]*/
  await for (var local in stream) {
    _method4(local);
  }
}
