// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: global#instantiate1:needsArgs*/

/*spec.member: id:direct,explicit=[id.T*],needsArgs,needsInst=[<int*>]*/
T id<T>(T t, String s) => t;

main() {
  int Function(int, String s) x = id;
  print("${x.runtimeType}");
}
