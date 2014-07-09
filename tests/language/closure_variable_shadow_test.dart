// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// The intermediate variable 'y' must either be preserved 
// or parameters must be renamed.

foo(x) {
    var y = x;
    bar(x) {
        return y - x;
    }
    return bar;
}

main() {
    Expect.equals(-10, foo(10)(20));
}
