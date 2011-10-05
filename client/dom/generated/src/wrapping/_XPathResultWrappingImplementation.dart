// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathResultWrappingImplementation extends DOMWrapperBase implements XPathResult {
  _XPathResultWrappingImplementation() : super() {}

  static create__XPathResultWrappingImplementation() native {
    return new _XPathResultWrappingImplementation();
  }

  bool get booleanValue() { return _get__XPathResult_booleanValue(this); }
  static bool _get__XPathResult_booleanValue(var _this) native;

  bool get invalidIteratorState() { return _get__XPathResult_invalidIteratorState(this); }
  static bool _get__XPathResult_invalidIteratorState(var _this) native;

  num get numberValue() { return _get__XPathResult_numberValue(this); }
  static num _get__XPathResult_numberValue(var _this) native;

  int get resultType() { return _get__XPathResult_resultType(this); }
  static int _get__XPathResult_resultType(var _this) native;

  Node get singleNodeValue() { return _get__XPathResult_singleNodeValue(this); }
  static Node _get__XPathResult_singleNodeValue(var _this) native;

  int get snapshotLength() { return _get__XPathResult_snapshotLength(this); }
  static int _get__XPathResult_snapshotLength(var _this) native;

  String get stringValue() { return _get__XPathResult_stringValue(this); }
  static String _get__XPathResult_stringValue(var _this) native;

  Node iterateNext() {
    return _iterateNext(this);
  }
  static Node _iterateNext(receiver) native;

  Node snapshotItem(int index = null) {
    if (index === null) {
      return _snapshotItem(this);
    } else {
      return _snapshotItem_2(this, index);
    }
  }
  static Node _snapshotItem(receiver) native;
  static Node _snapshotItem_2(receiver, index) native;

  String get typeName() { return "XPathResult"; }
}
