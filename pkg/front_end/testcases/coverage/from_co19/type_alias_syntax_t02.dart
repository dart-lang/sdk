// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/Language/Types/Type_Aliases/syntax_t02.dart

const int meta = 1;

class C<T> {
  T t;
  C(this.t);
}

@meta typedef CAlias1 = C;
@meta typedef CAlias2<T> = C<T>;
typedef CAlias3 = C<String>;
typedef CAlias4<T> = C<int>;

void foo() {
  CAlias1 ca1 = new CAlias1(42);
  CAlias2<int> ca2 = new CAlias2<int>(1);
  CAlias3 ca3 = new CAlias3("");
  CAlias4<String> ca4 = new CAlias4<String>(1);
}
