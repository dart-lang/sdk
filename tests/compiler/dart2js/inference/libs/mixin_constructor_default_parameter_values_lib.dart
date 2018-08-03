// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SECRET {
  /*element: _SECRET.:[exact=_SECRET]*/
  const _SECRET();
  /*element: _SECRET.toString:Value([exact=JSString], value: "SECRET!")*/
  String toString() => "SECRET!";
}

class C {
  /*element: C.x:[exact=JSUInt31]*/
  final int x;

  /*element: C.y:Union([exact=JSString], [exact=_SECRET])*/
  final y;

  /*element: C.a:[exact=C]*/
  C.a(int /*[exact=JSUInt31]*/ x,
      [var /*Union([exact=JSString], [exact=_SECRET])*/ b = const _SECRET()])
      : this.x = x,
        this.y = b;

  /*element: C.b:[exact=C]*/
  C.b(int /*[exact=JSUInt31]*/ x,
      {var /*Union([exact=JSString], [exact=_SECRET])*/ b: const _SECRET()})
      : this.x = x,
        this.y = b;

  /*element: C.toString:[exact=JSString]*/
  String toString() => "C(${/*[exact=D]*/x},${/*[exact=D]*/y})";
}
