// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SECRET {
  const _SECRET();
  /*member: _SECRET.toString:Value([exact=JSString|powerset={I}{O}], value: "SECRET!", powerset: {I}{O})*/
  @override
  String toString() => "SECRET!";
}

class C {
  /*member: C.x:[exact=JSUInt31|powerset={I}{O}]*/
  final int x;

  /*member: C.y:Union([exact=JSString|powerset={I}{O}], [exact=_SECRET|powerset={N}{O}], powerset: {IN}{O})*/
  final y;

  /*member: C.a:[empty|powerset=empty]*/
  C.a(
    int /*[exact=JSUInt31|powerset={I}{O}]*/ x, [
    var /*Union([exact=JSString|powerset={I}{O}], [exact=_SECRET|powerset={N}{O}], powerset: {IN}{O})*/ b =
        const _SECRET(),
  ]) : this.x = x,
       this.y = b;

  /*member: C.b:[empty|powerset=empty]*/
  C.b(
    int /*[exact=JSUInt31|powerset={I}{O}]*/ x, {
    var /*Union([exact=JSString|powerset={I}{O}], [exact=_SECRET|powerset={N}{O}], powerset: {IN}{O})*/ b =
        const _SECRET(),
  }) : this.x = x,
       this.y = b;

  /*member: C.toString:[exact=JSString|powerset={I}{O}]*/
  @override
  String toString() =>
      "C(${ /*[exact=D|powerset={N}{O}]*/ x},${ /*[exact=D|powerset={N}{O}]*/ y})";
}
