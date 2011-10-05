// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLTransactionCallbackWrappingImplementation extends DOMWrapperBase implements SQLTransactionCallback {
  _SQLTransactionCallbackWrappingImplementation() : super() {}

  static create__SQLTransactionCallbackWrappingImplementation() native {
    return new _SQLTransactionCallbackWrappingImplementation();
  }

  bool handleEvent(SQLTransaction transaction) {
    return _handleEvent(this, transaction);
  }
  static bool _handleEvent(receiver, transaction) native;

  String get typeName() { return "SQLTransactionCallback"; }
}
