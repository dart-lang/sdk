// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SECRET {
  const _SECRET();
  /*member: _SECRET.toString:Value([exact=JSString|powerset={I}], value: "SECRET!", powerset: {I})*/
  @override
  String toString() => "SECRET!";
}

class C {
  /*member: C.x:[exact=JSUInt31|powerset={I}]*/
  final int x;

  /*member: C.y:Union([exact=JSString|powerset={I}], [exact=_SECRET|powerset={N}], powerset: {IN})*/
  final y;

  /*member: C.a:[exact=C|powerset={N}]*/
  C.a(
    int /*[exact=JSUInt31|powerset={I}]*/ x, [
    var /*Union([exact=JSString|powerset={I}], [exact=_SECRET|powerset={N}], powerset: {IN})*/ b =
        const _SECRET(),
  ]) : this.x = x,
       this.y = b;

  /*member: C.b:[exact=C|powerset={N}]*/
  C.b(
    int /*[exact=JSUInt31|powerset={I}]*/ x, {
    var /*Union([exact=JSString|powerset={I}], [exact=_SECRET|powerset={N}], powerset: {IN})*/ b =
        const _SECRET(),
  }) : this.x = x,
       this.y = b;

  /*member: C.toString:[exact=JSString|powerset={I}]*/
  @override
  String toString() =>
      "C(${ /*[exact=D|powerset={N}]*/ x},${ /*[exact=D|powerset={N}]*/ y})";
}
