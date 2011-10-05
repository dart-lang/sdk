// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ElementTraversalWrappingImplementation extends DOMWrapperBase implements ElementTraversal {
  _ElementTraversalWrappingImplementation() : super() {}

  static create__ElementTraversalWrappingImplementation() native {
    return new _ElementTraversalWrappingImplementation();
  }

  int get childElementCount() { return _get__ElementTraversal_childElementCount(this); }
  static int _get__ElementTraversal_childElementCount(var _this) native;

  Element get firstElementChild() { return _get__ElementTraversal_firstElementChild(this); }
  static Element _get__ElementTraversal_firstElementChild(var _this) native;

  Element get lastElementChild() { return _get__ElementTraversal_lastElementChild(this); }
  static Element _get__ElementTraversal_lastElementChild(var _this) native;

  Element get nextElementSibling() { return _get__ElementTraversal_nextElementSibling(this); }
  static Element _get__ElementTraversal_nextElementSibling(var _this) native;

  Element get previousElementSibling() { return _get__ElementTraversal_previousElementSibling(this); }
  static Element _get__ElementTraversal_previousElementSibling(var _this) native;

  String get typeName() { return "ElementTraversal"; }
}
