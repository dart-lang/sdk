// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {
  /*member: X.a:Union([exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/
  final dynamic a;

  /*member: X.:[exact=X|powerset=0]*/
  X(
    Object /*Union([exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/
    value,
  ) : assert(value is String),
      a = value;
}

/*member: main:[null|powerset=1]*/
main() {
  X('a')
      . /*[exact=X|powerset=0]*/ a
      . /*Union([exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/ length;
  X([1])
      . /*[exact=X|powerset=0]*/ a
      . /*Union([exact=JSExtendableArray|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/ length;
}
