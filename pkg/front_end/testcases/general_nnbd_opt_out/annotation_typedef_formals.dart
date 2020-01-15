// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This test checks that the compiler handles annotations on formals of
// typedefs.

const int foo = 21;
const int bar = 42;
const int baz = 84;

typedef void F(@foo int x, num y, {@bar @baz String z, Object w});
typedef void G(@foo int a, num b, [@bar @baz String c, Object d]);

main() {}
