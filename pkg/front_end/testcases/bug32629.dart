// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=error*/

class A {
  dynamic call(dynamic a, dynamic b) {
    return a;
  }
}

typedef S Reducer<S>(S a, dynamic b);

void foo<S>(Reducer<S> v) {}

void main() {
  foo<String>(new /*@error=InvalidAssignment*/ A());
}
