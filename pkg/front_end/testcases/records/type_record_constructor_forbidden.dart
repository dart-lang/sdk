// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef R = Record;
typedef RR = R;

foo1() => Record(); // Error.
foo2() => R(); // Error.
foo3() => RR(); // Error.

main() {}
