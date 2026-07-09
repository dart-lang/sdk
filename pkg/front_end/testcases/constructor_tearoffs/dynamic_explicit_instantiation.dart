// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) => x.foo<int>; // Error.
test2(Never x) => x.foo<int>; // Error.
test3(dynamic x) => x.toString<int>; // Error.
test4(Never x) => x.toString<int>; // Error.

main() {}
