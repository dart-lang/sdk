// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(4910): Shouldn't this file be in the coreimpl and not the core
// library?

class TypeErrorImplementation implements TypeError {
  final String msg;
  const TypeErrorImplementation(String this.msg);
  String toString() => msg;
}

/** Thrown by the 'as' operator if the cast isn't valid. */
class CastExceptionImplementation implements CastException {
  // TODO(lrn): Change actualType and expectedType to "Type" when reified
  // types are available.
  final Object actualType;
  final Object expectedType;

  CastExceptionImplementation(this.actualType, this.expectedType);

  String toString() {
    return "CastException: Casting value of type $actualType to"
           " incompatible type $expectedType";
  }
}

class FallThroughErrorImplementation implements FallThroughError {
  const FallThroughErrorImplementation();
  String toString() => "Switch case fall-through.";
}
