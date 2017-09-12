// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

/*element: main:[null]*/
main() {
  simpleStaticCall();
}

/*element: returnInt:[exact=JSUInt31]*/
returnInt() => 0;

/*element: simpleStaticCall:[exact=JSUInt31]*/
simpleStaticCall() => returnInt();
