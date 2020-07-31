// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple test of the subtype relationship on generic function types.

typedef F1 = void Function<X1 extends num>();
typedef F2 = void Function<X2 extends String>();

void f1<Y1 extends num>() {}
void f2<Y2 extends String>() {}

void foo() {





}

main() {}
