// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

/*member: myList:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
var myList = [42];

/*member: main:[exact=JSUInt31|powerset={I}]*/
main() {
  /// ignore: unused_local_variable
  var a = List.filled(42, null);
  return myList
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
  [0];
}
