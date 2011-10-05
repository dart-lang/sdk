// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLResultSetRowListWrappingImplementation extends DOMWrapperBase implements SQLResultSetRowList {
  _SQLResultSetRowListWrappingImplementation() : super() {}

  static create__SQLResultSetRowListWrappingImplementation() native {
    return new _SQLResultSetRowListWrappingImplementation();
  }

  int get length() { return _get__SQLResultSetRowList_length(this); }
  static int _get__SQLResultSetRowList_length(var _this) native;

  Object item(int index) {
    return _item(this, index);
  }
  static Object _item(receiver, index) native;

  String get typeName() { return "SQLResultSetRowList"; }
}
