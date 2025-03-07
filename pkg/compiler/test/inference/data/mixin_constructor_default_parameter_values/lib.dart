// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SECRET {
  const _SECRET();
  /*member: _SECRET.toString:Value([exact=JSString|powerset=0], value: "SECRET!", powerset: 0)*/
  @override
  String toString() => "SECRET!";
}

class C {
  /*member: C.x:[exact=JSUInt31|powerset=0]*/
  final int x;

  /*member: C.y:Union([exact=JSString|powerset=0], [exact=_SECRET|powerset=0], powerset: 0)*/
  final y;

  /*member: C.a:[exact=C|powerset=0]*/
  C.a(
    int /*[exact=JSUInt31|powerset=0]*/ x, [
    var /*Union([exact=JSString|powerset=0], [exact=_SECRET|powerset=0], powerset: 0)*/ b =
        const _SECRET(),
  ]) : this.x = x,
       this.y = b;

  /*member: C.b:[exact=C|powerset=0]*/
  C.b(
    int /*[exact=JSUInt31|powerset=0]*/ x, {
    var /*Union([exact=JSString|powerset=0], [exact=_SECRET|powerset=0], powerset: 0)*/ b =
        const _SECRET(),
  }) : this.x = x,
       this.y = b;

  /*member: C.toString:[exact=JSString|powerset=0]*/
  @override
  String toString() =>
      "C(${ /*[exact=D|powerset=0]*/ x},${ /*[exact=D|powerset=0]*/ y})";
}
