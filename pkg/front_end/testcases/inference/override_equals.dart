// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class NullEquality {
  @override
  Null operator ==(Object other) => null;
}

class SubNullEquality extends NullEquality {
  void test() {
    var /*@ type=bool* */ super_equals_self =
        super /*@target=NullEquality.==*/ == this;
    var /*@ type=bool* */ super_equals_null =
        super /*@target=NullEquality.==*/ == null;
    var /*@ type=bool* */ super_not_equals_self =
        super /*@target=NullEquality.==*/ != this;
    var /*@ type=bool* */ super_not_equals_null =
        super /*@target=NullEquality.==*/ != null;
  }
}

test() {
  NullEquality n = new NullEquality();
  var /*@ type=bool* */ equals_self = n /*@target=NullEquality.==*/ == n;
  var /*@ type=bool* */ equals_null = n /*@target=NullEquality.==*/ == null;
  var /*@ type=bool* */ null_equals = null /*@target=Object.==*/ == n;
  var /*@ type=bool* */ not_equals_self = n /*@target=NullEquality.==*/ != n;
  var /*@ type=bool* */ not_equals_null = n /*@target=NullEquality.==*/ != null;
  var /*@ type=bool* */ null_not_equals = null /*@target=Object.==*/ != n;
}

main() {
  test();
  new SubNullEquality(). /*@target=SubNullEquality.test*/ test();
}
