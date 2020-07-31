// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

/*member: myList:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
var myList = [42];

/*member: main:[exact=JSUInt31]*/
main() {
  /// ignore: unused_local_variable
  var a = new List(42);
  return myList
      /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
      [0];
}
