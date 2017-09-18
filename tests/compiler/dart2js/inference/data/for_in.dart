// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  forInDirect();
}

/*element: forInDirect:[null]*/
forInDirect() {
  /*iterator: Container mask: [exact=JSUInt31] length: 3 type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    print(a);
  }
}
