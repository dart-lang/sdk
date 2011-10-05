// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _RangeWrappingImplementation extends DOMWrapperBase implements Range {
  _RangeWrappingImplementation() : super() {}

  static create__RangeWrappingImplementation() native {
    return new _RangeWrappingImplementation();
  }

  bool get collapsed() { return _get__Range_collapsed(this); }
  static bool _get__Range_collapsed(var _this) native;

  Node get commonAncestorContainer() { return _get__Range_commonAncestorContainer(this); }
  static Node _get__Range_commonAncestorContainer(var _this) native;

  Node get endContainer() { return _get__Range_endContainer(this); }
  static Node _get__Range_endContainer(var _this) native;

  int get endOffset() { return _get__Range_endOffset(this); }
  static int _get__Range_endOffset(var _this) native;

  Node get startContainer() { return _get__Range_startContainer(this); }
  static Node _get__Range_startContainer(var _this) native;

  int get startOffset() { return _get__Range_startOffset(this); }
  static int _get__Range_startOffset(var _this) native;

  String get text() { return _get__Range_text(this); }
  static String _get__Range_text(var _this) native;

  DocumentFragment cloneContents() {
    return _cloneContents(this);
  }
  static DocumentFragment _cloneContents(receiver) native;

  Range cloneRange() {
    return _cloneRange(this);
  }
  static Range _cloneRange(receiver) native;

  void collapse(bool toStart = null) {
    if (toStart === null) {
      _collapse(this);
      return;
    } else {
      _collapse_2(this, toStart);
      return;
    }
  }
  static void _collapse(receiver) native;
  static void _collapse_2(receiver, toStart) native;

  int compareBoundaryPoints() {
    return _compareBoundaryPoints(this);
  }
  static int _compareBoundaryPoints(receiver) native;

  int compareNode(Node refNode = null) {
    if (refNode === null) {
      return _compareNode(this);
    } else {
      return _compareNode_2(this, refNode);
    }
  }
  static int _compareNode(receiver) native;
  static int _compareNode_2(receiver, refNode) native;

  int comparePoint(Node refNode = null, int offset = null) {
    if (refNode === null) {
      if (offset === null) {
        return _comparePoint(this);
      }
    } else {
      if (offset === null) {
        return _comparePoint_2(this, refNode);
      } else {
        return _comparePoint_3(this, refNode, offset);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static int _comparePoint(receiver) native;
  static int _comparePoint_2(receiver, refNode) native;
  static int _comparePoint_3(receiver, refNode, offset) native;

  DocumentFragment createContextualFragment(String html = null) {
    if (html === null) {
      return _createContextualFragment(this);
    } else {
      return _createContextualFragment_2(this, html);
    }
  }
  static DocumentFragment _createContextualFragment(receiver) native;
  static DocumentFragment _createContextualFragment_2(receiver, html) native;

  void deleteContents() {
    _deleteContents(this);
    return;
  }
  static void _deleteContents(receiver) native;

  void detach() {
    _detach(this);
    return;
  }
  static void _detach(receiver) native;

  void expand(String unit = null) {
    if (unit === null) {
      _expand(this);
      return;
    } else {
      _expand_2(this, unit);
      return;
    }
  }
  static void _expand(receiver) native;
  static void _expand_2(receiver, unit) native;

  DocumentFragment extractContents() {
    return _extractContents(this);
  }
  static DocumentFragment _extractContents(receiver) native;

  void insertNode(Node newNode = null) {
    if (newNode === null) {
      _insertNode(this);
      return;
    } else {
      _insertNode_2(this, newNode);
      return;
    }
  }
  static void _insertNode(receiver) native;
  static void _insertNode_2(receiver, newNode) native;

  bool intersectsNode(Node refNode = null) {
    if (refNode === null) {
      return _intersectsNode(this);
    } else {
      return _intersectsNode_2(this, refNode);
    }
  }
  static bool _intersectsNode(receiver) native;
  static bool _intersectsNode_2(receiver, refNode) native;

  bool isPointInRange(Node refNode = null, int offset = null) {
    if (refNode === null) {
      if (offset === null) {
        return _isPointInRange(this);
      }
    } else {
      if (offset === null) {
        return _isPointInRange_2(this, refNode);
      } else {
        return _isPointInRange_3(this, refNode, offset);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static bool _isPointInRange(receiver) native;
  static bool _isPointInRange_2(receiver, refNode) native;
  static bool _isPointInRange_3(receiver, refNode, offset) native;

  void selectNode(Node refNode = null) {
    if (refNode === null) {
      _selectNode(this);
      return;
    } else {
      _selectNode_2(this, refNode);
      return;
    }
  }
  static void _selectNode(receiver) native;
  static void _selectNode_2(receiver, refNode) native;

  void selectNodeContents(Node refNode = null) {
    if (refNode === null) {
      _selectNodeContents(this);
      return;
    } else {
      _selectNodeContents_2(this, refNode);
      return;
    }
  }
  static void _selectNodeContents(receiver) native;
  static void _selectNodeContents_2(receiver, refNode) native;

  void setEnd(Node refNode = null, int offset = null) {
    if (refNode === null) {
      if (offset === null) {
        _setEnd(this);
        return;
      }
    } else {
      if (offset === null) {
        _setEnd_2(this, refNode);
        return;
      } else {
        _setEnd_3(this, refNode, offset);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setEnd(receiver) native;
  static void _setEnd_2(receiver, refNode) native;
  static void _setEnd_3(receiver, refNode, offset) native;

  void setEndAfter(Node refNode = null) {
    if (refNode === null) {
      _setEndAfter(this);
      return;
    } else {
      _setEndAfter_2(this, refNode);
      return;
    }
  }
  static void _setEndAfter(receiver) native;
  static void _setEndAfter_2(receiver, refNode) native;

  void setEndBefore(Node refNode = null) {
    if (refNode === null) {
      _setEndBefore(this);
      return;
    } else {
      _setEndBefore_2(this, refNode);
      return;
    }
  }
  static void _setEndBefore(receiver) native;
  static void _setEndBefore_2(receiver, refNode) native;

  void setStart(Node refNode = null, int offset = null) {
    if (refNode === null) {
      if (offset === null) {
        _setStart(this);
        return;
      }
    } else {
      if (offset === null) {
        _setStart_2(this, refNode);
        return;
      } else {
        _setStart_3(this, refNode, offset);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setStart(receiver) native;
  static void _setStart_2(receiver, refNode) native;
  static void _setStart_3(receiver, refNode, offset) native;

  void setStartAfter(Node refNode = null) {
    if (refNode === null) {
      _setStartAfter(this);
      return;
    } else {
      _setStartAfter_2(this, refNode);
      return;
    }
  }
  static void _setStartAfter(receiver) native;
  static void _setStartAfter_2(receiver, refNode) native;

  void setStartBefore(Node refNode = null) {
    if (refNode === null) {
      _setStartBefore(this);
      return;
    } else {
      _setStartBefore_2(this, refNode);
      return;
    }
  }
  static void _setStartBefore(receiver) native;
  static void _setStartBefore_2(receiver, refNode) native;

  void surroundContents(Node newParent = null) {
    if (newParent === null) {
      _surroundContents(this);
      return;
    } else {
      _surroundContents_2(this, newParent);
      return;
    }
  }
  static void _surroundContents(receiver) native;
  static void _surroundContents_2(receiver, newParent) native;

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  String get typeName() { return "Range"; }
}
