// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMSelectionWrappingImplementation extends DOMWrapperBase implements DOMSelection {
  _DOMSelectionWrappingImplementation() : super() {}

  static create__DOMSelectionWrappingImplementation() native {
    return new _DOMSelectionWrappingImplementation();
  }

  Node get anchorNode() { return _get__DOMSelection_anchorNode(this); }
  static Node _get__DOMSelection_anchorNode(var _this) native;

  int get anchorOffset() { return _get__DOMSelection_anchorOffset(this); }
  static int _get__DOMSelection_anchorOffset(var _this) native;

  Node get baseNode() { return _get__DOMSelection_baseNode(this); }
  static Node _get__DOMSelection_baseNode(var _this) native;

  int get baseOffset() { return _get__DOMSelection_baseOffset(this); }
  static int _get__DOMSelection_baseOffset(var _this) native;

  Node get extentNode() { return _get__DOMSelection_extentNode(this); }
  static Node _get__DOMSelection_extentNode(var _this) native;

  int get extentOffset() { return _get__DOMSelection_extentOffset(this); }
  static int _get__DOMSelection_extentOffset(var _this) native;

  Node get focusNode() { return _get__DOMSelection_focusNode(this); }
  static Node _get__DOMSelection_focusNode(var _this) native;

  int get focusOffset() { return _get__DOMSelection_focusOffset(this); }
  static int _get__DOMSelection_focusOffset(var _this) native;

  bool get isCollapsed() { return _get__DOMSelection_isCollapsed(this); }
  static bool _get__DOMSelection_isCollapsed(var _this) native;

  int get rangeCount() { return _get__DOMSelection_rangeCount(this); }
  static int _get__DOMSelection_rangeCount(var _this) native;

  String get type() { return _get__DOMSelection_type(this); }
  static String _get__DOMSelection_type(var _this) native;

  void addRange(Range range = null) {
    if (range === null) {
      _addRange(this);
      return;
    } else {
      _addRange_2(this, range);
      return;
    }
  }
  static void _addRange(receiver) native;
  static void _addRange_2(receiver, range) native;

  void collapse(Node node = null, int index = null) {
    if (node === null) {
      if (index === null) {
        _collapse(this);
        return;
      }
    } else {
      if (index === null) {
        _collapse_2(this, node);
        return;
      } else {
        _collapse_3(this, node, index);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _collapse(receiver) native;
  static void _collapse_2(receiver, node) native;
  static void _collapse_3(receiver, node, index) native;

  void collapseToEnd() {
    _collapseToEnd(this);
    return;
  }
  static void _collapseToEnd(receiver) native;

  void collapseToStart() {
    _collapseToStart(this);
    return;
  }
  static void _collapseToStart(receiver) native;

  bool containsNode(Node node = null, bool allowPartial = null) {
    if (node === null) {
      if (allowPartial === null) {
        return _containsNode(this);
      }
    } else {
      if (allowPartial === null) {
        return _containsNode_2(this, node);
      } else {
        return _containsNode_3(this, node, allowPartial);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static bool _containsNode(receiver) native;
  static bool _containsNode_2(receiver, node) native;
  static bool _containsNode_3(receiver, node, allowPartial) native;

  void deleteFromDocument() {
    _deleteFromDocument(this);
    return;
  }
  static void _deleteFromDocument(receiver) native;

  void empty() {
    _empty(this);
    return;
  }
  static void _empty(receiver) native;

  void extend(Node node = null, int offset = null) {
    if (node === null) {
      if (offset === null) {
        _extend(this);
        return;
      }
    } else {
      if (offset === null) {
        _extend_2(this, node);
        return;
      } else {
        _extend_3(this, node, offset);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _extend(receiver) native;
  static void _extend_2(receiver, node) native;
  static void _extend_3(receiver, node, offset) native;

  Range getRangeAt(int index = null) {
    if (index === null) {
      return _getRangeAt(this);
    } else {
      return _getRangeAt_2(this, index);
    }
  }
  static Range _getRangeAt(receiver) native;
  static Range _getRangeAt_2(receiver, index) native;

  void modify(String alter = null, String direction = null, String granularity = null) {
    if (alter === null) {
      if (direction === null) {
        if (granularity === null) {
          _modify(this);
          return;
        }
      }
    } else {
      if (direction === null) {
        if (granularity === null) {
          _modify_2(this, alter);
          return;
        }
      } else {
        if (granularity === null) {
          _modify_3(this, alter, direction);
          return;
        } else {
          _modify_4(this, alter, direction, granularity);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _modify(receiver) native;
  static void _modify_2(receiver, alter) native;
  static void _modify_3(receiver, alter, direction) native;
  static void _modify_4(receiver, alter, direction, granularity) native;

  void removeAllRanges() {
    _removeAllRanges(this);
    return;
  }
  static void _removeAllRanges(receiver) native;

  void selectAllChildren(Node node = null) {
    if (node === null) {
      _selectAllChildren(this);
      return;
    } else {
      _selectAllChildren_2(this, node);
      return;
    }
  }
  static void _selectAllChildren(receiver) native;
  static void _selectAllChildren_2(receiver, node) native;

  void setBaseAndExtent(Node baseNode = null, int baseOffset = null, Node extentNode = null, int extentOffset = null) {
    if (baseNode === null) {
      if (baseOffset === null) {
        if (extentNode === null) {
          if (extentOffset === null) {
            _setBaseAndExtent(this);
            return;
          }
        }
      }
    } else {
      if (baseOffset === null) {
        if (extentNode === null) {
          if (extentOffset === null) {
            _setBaseAndExtent_2(this, baseNode);
            return;
          }
        }
      } else {
        if (extentNode === null) {
          if (extentOffset === null) {
            _setBaseAndExtent_3(this, baseNode, baseOffset);
            return;
          }
        } else {
          if (extentOffset === null) {
            _setBaseAndExtent_4(this, baseNode, baseOffset, extentNode);
            return;
          } else {
            _setBaseAndExtent_5(this, baseNode, baseOffset, extentNode, extentOffset);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setBaseAndExtent(receiver) native;
  static void _setBaseAndExtent_2(receiver, baseNode) native;
  static void _setBaseAndExtent_3(receiver, baseNode, baseOffset) native;
  static void _setBaseAndExtent_4(receiver, baseNode, baseOffset, extentNode) native;
  static void _setBaseAndExtent_5(receiver, baseNode, baseOffset, extentNode, extentOffset) native;

  void setPosition(Node node = null, int offset = null) {
    if (node === null) {
      if (offset === null) {
        _setPosition(this);
        return;
      }
    } else {
      if (offset === null) {
        _setPosition_2(this, node);
        return;
      } else {
        _setPosition_3(this, node, offset);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setPosition(receiver) native;
  static void _setPosition_2(receiver, node) native;
  static void _setPosition_3(receiver, node, offset) native;

  String get typeName() { return "DOMSelection"; }
}
