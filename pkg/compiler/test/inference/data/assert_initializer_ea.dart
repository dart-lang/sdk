// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {
  /*member: X.a:[exact=JSString]*/
  final dynamic a;

  /*member: X.:[exact=X]*/
  X(Object /*Union([exact=JSExtendableArray], [exact=JSString])*/ value)
      : assert(value is String),
        a = value;
}

/*member: main:[null]*/
main() {
  X('a'). /*[exact=X]*/ a. /*[exact=JSString]*/ length;
  X([1]). /*[exact=X]*/ a. /*[exact=JSString]*/ length;
}
