// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Errors are created and thrown by DartVM only.
// Changes here should also be reflected in corelib/error.dart as well

class AssertionError {
  factory AssertionError._uninstantiable() {
    throw const UnsupportedOperationException(
        "AssertionError can only be allocated by the VM");
  }
  static _throwNew(int assertionStart, int assertionEnd)
      native "AssertionError_throwNew";
  String toString() {
    return "'$url': Failed assertion: line $line pos $column: " +
        "'$failedAssertion' is not true.";
  }
  final String failedAssertion;
  final String url;
  final int line;
  final int column;
}

class TypeError extends AssertionError {
  factory TypeError._uninstantiable() {
    throw const UnsupportedOperationException(
        "TypeError can only be allocated by the VM");
  }
  String toString() {
    return "'$url': Failed type check: line $line pos $column: " +
        "type '$srcType' is not assignable to type '$dstType' of '$dstName'.";
  }
  final String srcType;
  final String dstType;
  final String dstName;
}

class FallThroughError {
  factory FallThroughError._uninstantiable() {
    throw const UnsupportedOperationException(
        "FallThroughError can only be allocated by the VM");
  }
  static _throwNew(int case_clause_pos) native "FallThroughError_throwNew";
  String toString() {
    return "'$url': Switch case fall-through at line $line.";
  }
  final String url;
  final int line;
}

class InternalError {
  const InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}
