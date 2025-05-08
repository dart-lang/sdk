// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SECRET {
  const _SECRET();
  /*member: _SECRET.toString:Value([exact=JSString|powerset={I}{O}{I}], value: "SECRET!", powerset: {I}{O}{I})*/
  @override
  String toString() => "SECRET!";
}

class C {
  /*member: C.x:[exact=JSUInt31|powerset={I}{O}{N}]*/
  final int x;

  /*member: C.y:Union([exact=JSString|powerset={I}{O}{I}], [exact=_SECRET|powerset={N}{O}{N}], powerset: {IN}{O}{IN})*/
  final y;

  /*member: C.a:[empty|powerset=empty]*/
  C.a(
    int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ x, [
    var /*Union([exact=JSString|powerset={I}{O}{I}], [exact=_SECRET|powerset={N}{O}{N}], powerset: {IN}{O}{IN})*/ b =
        const _SECRET(),
  ]) : this.x = x,
       this.y = b;

  /*member: C.b:[empty|powerset=empty]*/
  C.b(
    int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ x, {
    var /*Union([exact=JSString|powerset={I}{O}{I}], [exact=_SECRET|powerset={N}{O}{N}], powerset: {IN}{O}{IN})*/ b =
        const _SECRET(),
  }) : this.x = x,
       this.y = b;

  /*member: C.toString:[exact=JSString|powerset={I}{O}{I}]*/
  @override
  String toString() =>
      "C(${ /*[exact=D|powerset={N}{O}{N}]*/ x},${ /*[exact=D|powerset={N}{O}{N}]*/ y})";
}
