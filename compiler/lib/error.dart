// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exceptions thrown by the VM -- user code should never throw these directly.
// TODO(jat): these should be compatible with the definitions in runtime/lib/error.dart

class AssertionError {
  const AssertionError();

  String toString() {
    return "Failed assertion";
  }
}

class TypeError extends AssertionError {
  final String dstType;
  final String srcType;

  const TypeError(this.srcType, this.dstType);

  String toString() {
    return "Failed type check: type $srcType is not assignable to type $dstType";
  }
}

class FallThroughError {
  const FallThroughError();

  String toString() {
    return "Switch case fall-through";
  }
}

