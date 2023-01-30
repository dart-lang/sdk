// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const recordConstant = (42, 'Hey', foo: 'foo');

recordLiteral(x, y, z) => (x, y, bar: z);

recordFieldAccess1((int, String) rec) => rec.$2;

recordFieldAccess2(({int a, String b}) rec) => rec.b;

main() {}
