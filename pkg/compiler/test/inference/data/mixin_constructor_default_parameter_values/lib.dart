// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class _SECRET {
  const _SECRET();
  /*member: _SECRET.toString:Value([exact=JSString], value: "SECRET!")*/
  @override
  String toString() => "SECRET!";
}

class C {
  /*member: C.x:[exact=JSUInt31]*/
  final int x;

  /*member: C.y:Union([exact=JSString], [exact=_SECRET])*/
  final y;

  /*member: C.a:[exact=C]*/
  C.a(int /*[exact=JSUInt31]*/ x,
      [var /*Union([exact=JSString], [exact=_SECRET])*/ b = const _SECRET()])
      : this.x = x,
        this.y = b;

  /*member: C.b:[exact=C]*/
  C.b(int /*[exact=JSUInt31]*/ x,
      {var /*Union([exact=JSString], [exact=_SECRET])*/ b: const _SECRET()})
      : this.x = x,
        this.y = b;

  /*member: C.toString:[exact=JSString]*/
  @override
  String toString() => "C(${/*[exact=D]*/ x},${/*[exact=D]*/ y})";
}
