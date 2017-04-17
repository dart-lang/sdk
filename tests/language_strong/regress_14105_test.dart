// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 14105.

typedef UsedAsFieldType();

class ClassOnlyForRti {
  UsedAsFieldType field;
}

class A<T> {
  var field;
}

use(a) => a.field = "";

var useFieldSetter = use;

main() {
  var a = new A<ClassOnlyForRti>();
  useFieldSetter(a);
  print(a is A<int>);
}
