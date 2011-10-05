// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLStatementCallbackWrappingImplementation extends DOMWrapperBase implements SQLStatementCallback {
  _SQLStatementCallbackWrappingImplementation() : super() {}

  static create__SQLStatementCallbackWrappingImplementation() native {
    return new _SQLStatementCallbackWrappingImplementation();
  }

  bool handleEvent(SQLTransaction transaction, SQLResultSet resultSet) {
    return _handleEvent(this, transaction, resultSet);
  }
  static bool _handleEvent(receiver, transaction, resultSet) native;

  String get typeName() { return "SQLStatementCallback"; }
}
