// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

smiLiteral() => 42;

intLiteral() => 0x8000000000000000;

strLiteral() => 'abc';

const _constList1 = [1, 2, 3];
indexingIntoConstantList1(int i) => _constList1[i];

const _constList2 = ['hi', 33, null, -5];
indexingIntoConstantList2(int i) => _constList2[i];

main() {}
