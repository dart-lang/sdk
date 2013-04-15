// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

final Expando _stackTraceExpando = new Expando("asynchronous error");

void _attachStackTrace(o, st) {
  if (o == null || o is bool || o is num || o is String) return;
  _stackTraceExpando[o] = st;
}

/**
 * *This is an experimental API.*
 *
 * Get the [StackTrace] attached to [o].
 *
 * If object [o] was thrown and caught in a dart:async method, a [StackTrace]
 * object was attached to it. Use [getAttachedStackTrace] to get that object.
 *
 * Returns [null] if no [StackTrace] was attached.
 */
getAttachedStackTrace(o) {
  if (o == null || o is bool || o is num || o is String) return null;
  return _stackTraceExpando[o];
}
