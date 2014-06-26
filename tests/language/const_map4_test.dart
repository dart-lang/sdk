// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
    var a = {1: 'a', 2: 'b', 3: 'c'};
    var b = {1: 'a', 2: 'b', 3: 'c'};
    Expect.equals(false, a == b);

    a = const {1: 'a', 2: 'b', 3: 'c'};
    b = const {1: 'a', 2: 'b', 3: 'c'};
    Expect.equals(true, a == b);

    a = const <num,String>{1: 'a', 2: 'b', 3: 'c'};
    b = const {1: 'a', 2: 'b', 3: 'c'};
    Expect.equals(false, a == b);

    a = const <dynamic,dynamic>{1: 'a', 2: 'b', 3: 'c'};
    b = const {1: 'a', 2: 'b', 3: 'c'};
    Expect.equals(true, a == b);
}
