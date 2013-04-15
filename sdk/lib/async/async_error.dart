// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

final Expando _stackTraceExpando = new Expando("asynchronous error");

void _attachStackTrace(o, st) {
  if (o == null || o is bool || o is num || o is String) return;
  _stackTraceExpando[o] = st;
}

getAttachedStackTrace(o) {
  if (o == null || o is bool || o is num || o is String) return null;
  return _stackTraceExpando[o];
}
