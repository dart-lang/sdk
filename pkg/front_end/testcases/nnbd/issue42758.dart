// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(Never n1, Never? n2, Null n3) {
  var l1 = [...n1];
  var l2 = [...?n1];
  var l3 = [...n2];
  var l4 = [...?n2];
  var l5 = [...n3];
  var l6 = [...?n3];
  var s1 = {...n1, n1};
  var s2 = {...?n1, n1};
  var s3 = {...n2, n1};
  var s4 = {...?n2, n1};
  var s5 = {...n3, n1};
  var s6 = {...?n3, n1};
  var m1 = {...n1, n1: n1};
  var m2 = {...?n1, n1: n1};
  var m3 = {...n2, n1: n1};
  var m4 = {...?n2, n1: n1};
  var m5 = {...n3, n1: n1};
  var m6 = {...?n3, n1: n1};
}

test2<N1 extends Never, N2 extends Never?, N3 extends Null>(
    N1 n1, N2 n2, N3 n3) {
  var l1 = [...n1];
  var l2 = [...?n1];
  var l3 = [...n2];
  var l4 = [...?n2];
  var l5 = [...n3];
  var l6 = [...?n3];
  var s1 = {...n1, n1};
  var s2 = {...?n1, n1};
  var s3 = {...n2, n1};
  var s4 = {...?n2, n1};
  var s5 = {...n3, n1};
  var s6 = {...?n3, n1};
  var m1 = {...n1, n1: n1};
  var m2 = {...?n1, n1: n1};
  var m3 = {...n2, n1: n1};
  var m4 = {...?n2, n1: n1};
  var m5 = {...n3, n1: n1};
  var m6 = {...?n3, n1: n1};
}

main() {}
