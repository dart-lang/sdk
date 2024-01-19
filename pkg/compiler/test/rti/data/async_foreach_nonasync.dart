// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*spec.class: Class:explicit=[Class.T*],implicit=[Class.T],needsArgs,test*/
/*prod.class: Class:implicit=[Class.T],needsArgs,test*/
class Class<T> {
  method() {
    var list = <T>[];
    // If any method was `async`, this would have triggered the need for type
    // arguments on `Class`. See the 'async_foreach.dart' test.
    list.forEach(
        /*spec.needsSignature*/
        (x) => makeLive(x));
  }
}

main() {
  Class<int>().method();
}
