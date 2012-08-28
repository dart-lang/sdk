// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mocks of things that Leg cannot read directly.

// TODO(ahe): Remove this file.

class TypeError extends AssertionError {
  final String msg;
  const TypeError(String this.msg);
  String toString() => msg;
}

/** Thrown by the 'as' operator if the cast isn't valid. */
class CastException implements TypeError {
  // TODO(lrn): Change actualType and expectedType to "Type" when reified
  // types are available.
  final Object actualType;
  final Object expectedType;

  CastException(this.actualType, this.expectedType);

  String toString() {
    return "CastException: Casting value of type $actualType to"
           " incompatible type $expectedType";
  }
}

class FallThroughError {
  const FallThroughError();
  String toString() => "Switch case fall-through.";
}

// TODO(ahe): VM specfic exception?
class InternalError {
  const InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}

// TODO(ahe): VM specfic exception?
class StaticResolutionException implements Exception {}

void assert(condition) {
  if (condition is Function) condition = condition();
  if (!condition) throw new AssertionError();
}

// TODO(ahe): Not sure ByteArray belongs in the core library.
interface Uint8List extends List default _InternalByteArray {
  Uint8List(int length);
}

class _InternalByteArray {
  factory Uint8List(int length) {
    throw new UnsupportedOperationException("new Uint8List($length)");
  }
}
