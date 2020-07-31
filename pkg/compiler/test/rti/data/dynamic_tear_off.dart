// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: staticMethod:direct,explicit=[staticMethod.T*],needsArgs,selectors=[Selector(call, call, arity=1, types=1)]*/
staticMethod<T>(t) => t is T;

main() {
  var a = staticMethod;
  a<int>(0);
}
