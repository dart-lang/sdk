// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Rename CompilerException to be SourceException then this
//              exception would be derived from SourceException.

/** Can be thrown on any Css runtime problem includes source location. */
class CssSelectorException implements Exception {
  final String _message;
  final lang.SourceSpan _location;

  CssSelectorException(this._message, [this._location = null]);

  String toString() {
    if (_location != null) {
      return 'CssSelectorException: ${_location.toMessageString(_message)}';
    } else {
      return 'CssSelectorException: $_message';
    }
  }

}
