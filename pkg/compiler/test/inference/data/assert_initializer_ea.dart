// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {
  /*member: X.a:[exact=JSString|powerset={I}{O}{I}]*/
  final dynamic a;

  /*member: X.:[exact=X|powerset={N}{O}{N}]*/
  X(
    Object /*Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{GO}{IM})*/
    value,
  ) : assert(value is String),
      a = value;
}

/*member: main:[null|powerset={null}]*/
main() {
  X('a')
      . /*[exact=X|powerset={N}{O}{N}]*/ a
      . /*[exact=JSString|powerset={I}{O}{I}]*/ length;
  X([1])
      . /*[exact=X|powerset={N}{O}{N}]*/ a
      . /*[exact=JSString|powerset={I}{O}{I}]*/ length;
}
