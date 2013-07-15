// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Errors are created and thrown by DartVM only.
// Changes here should also be reflected in corelib/error.dart as well

class _AssertionErrorImplementation extends AssertionError {
  _AssertionErrorImplementation(
    this.failedAssertion, this.url, this.line, this.column);

  static _throwNew(int assertionStart, int assertionEnd)
      native "AssertionError_throwNew";

  String toString() {
    return "'$url': Failed assertion: line $line pos $column: "
        "'$failedAssertion' is not true.";
  }
  final String failedAssertion;
  final String url;
  final int line;
  final int column;
}

class _TypeErrorImplementation
    extends _AssertionErrorImplementation
    implements TypeError {

  _TypeErrorImplementation(
    String failedAssertion, String url, int line, int column,
    this.srcType, this.dstType, this.dstName, this._malformedError)
      : super(failedAssertion, url, line, column);

  static _throwNew(int location,
                   Object src_value,
                   String dst_type_name,
                   String dst_name,
                   String malformed_error)
      native "TypeError_throwNew";

  String toString() {
    String str = (_malformedError != null) ? _malformedError : "";
    if ((dstName != null) && (dstName.length > 0)) {
      str = "${str}type '$srcType' is not a subtype of "
            "type '$dstType' of '$dstName'.";
    } else {
      str = "${str}malformed type used.";
    }
    return str;
  }

  final String srcType;
  final String dstType;
  final String dstName;
  final String _malformedError;
}

class _CastErrorImplementation
    extends _TypeErrorImplementation
    implements CastError {

  _CastErrorImplementation(
    String failedAssertion, String url, int line, int column,
    String srcType, String dstType, String dstName, String malformedError)
      : super(failedAssertion, url, line, column,
              srcType, dstType, dstName, malformedError);

  // A CastError is allocated by TypeError._throwNew() when dst_name equals
  // Exceptions::kCastErrorDstName.
  String toString() {
    String str = (_malformedError != null) ? _malformedError : "";
    if ((dstName != null) && (dstName.length > 0)) {
      str = "${str}type '$srcType' is not a subtype of "
            "type '$dstType' in type cast.";
    } else {
      str = "${str}malformed type used in type cast.";
    }
    return str;
  }
}

class _FallThroughErrorImplementation extends FallThroughError {

  _FallThroughErrorImplementation(this._url, this._line);

  static _throwNew(int case_clause_pos) native "FallThroughError_throwNew";

  String toString() {
    return "'$_url': Switch case fall-through at line $_line.";
  }

  final String _url;
  final int _line;
}

class _InternalError {
  const _InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}


class _AbstractClassInstantiationErrorImplementation
    extends AbstractClassInstantiationError {

  _AbstractClassInstantiationErrorImplementation(
      String className, this._url, this._line)
      : super(className);

  static _throwNew(int case_clause_pos, String className)
      native "AbstractClassInstantiationError_throwNew";

  String toString() {
    return "Cannot instantiate abstract class $_className: "
           "_url '$_url' line $_line";
  }

  final String _url;
  final int _line;
}
