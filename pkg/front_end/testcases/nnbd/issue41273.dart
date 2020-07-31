// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test(var x) {
  if (x is Never) {
    Never n1 = x.toString();
    Never n2 = x.runtimeType;
    Never n3 = x.someGetter;
    Never n4 = x.someMethod();
    Never n5 = x + x;
    Never n6 = x[x];
    Never n7 = x();
    Never n8 = x.runtimeType();
    Never n9 = x.toString;
    x.runtimeType = Object;
    x.toString = () => '';
    var v1 = x.toString();
    var v2 = x.runtimeType;
    var v3 = x.someGetter;
    var v4 = x.someMethod();
    var v5 = x + x;
    var v6 = x[x];
    var v7 = x();
    var v8 = x.runtimeType();
    var v9 = x.toString;
  }
}

main() {
  test(null);
}
