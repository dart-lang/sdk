// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.util;

/// Indentation utility class. Should be used as a mixin in most cases.
class Indentation {
  /// The current indentation string.
  String get indentation {
    // Lazily add new indentation strings as required.
    for (int i = _indentList.length; i <= _indentLevel; i++) {
      _indentList.add(_indentList[i - 1] + indentationUnit);
    }
    return _indentList[_indentLevel];
  }

  /// The current indentation level.
  int _indentLevel = 0;

  /// A cache of all indentation strings used so far.
  /// Always at least of length 1.
  List<String> _indentList = <String>[""];

  /// The indentation unit, defaulting to two spaces. May be overwritten.
  String _indentationUnit = "  ";
  String get indentationUnit => _indentationUnit;
  set indentationUnit(String value) {
    if (value != _indentationUnit) {
      _indentationUnit = value;
      _indentList = <String>[""];
    }
  }

  /// Increases the current level of indentation.
  void indentMore() {
    _indentLevel++;
  }

  /// Decreases the current level of indentation.
  void indentLess() {
    _indentLevel--;
  }

  /// Calls [f] with one more indentation level, restoring indentation context
  /// upon return of [f] and returning its result.
  indentBlock(Function f) {
    indentMore();
    var result = f();
    indentLess();
    return result;
  }
}

abstract class Tagging<N> implements Indentation {
  StringBuffer sb = new StringBuffer();
  Link<String> tagStack = const Link<String>();

  void pushTag(String tag) {
    tagStack = tagStack.prepend(tag);
    indentMore();
  }

  String popTag() {
    assert(!tagStack.isEmpty);
    String tag = tagStack.head;
    tagStack = tagStack.tail;
    indentLess();
    return tag;
  }

  /// Adds given string to result string.
  void add(String string) {
    sb.write(string);
  }

  /// Adds default parameters for [node] into [params].
  void addDefaultParameters(N node, Map params) {}

  /// Adds given node type to result string.
  /// The method "opens" the node, meaning that all output after calling
  /// this method and before calling closeNode() will represent contents
  /// of given node.
  void openNode(N node, String type, [Map params]) {
    if (params == null) params = new Map();
    addCurrentIndent();
    sb.write("<");
    addDefaultParameters(node, params);
    addTypeWithParams(type, params);
    sb.write(">\n");
    pushTag(type);
  }

  /// Adds given node to result string.
  void openAndCloseNode(N node, String type, [Map params]) {
    if (params == null) params = {};
    addCurrentIndent();
    sb.write("<");
    addDefaultParameters(node, params);
    addTypeWithParams(type, params);
    sb.write("/>\n");
  }

  /// Closes current node type.
  void closeNode() {
    String tag = popTag();
    addCurrentIndent();
    sb.write("</");
    addTypeWithParams(tag);
    sb.write(">\n");
  }

  void addTypeWithParams(String type, [Map params]) {
    if (params == null) params = new Map();
    sb.write("${type}");
    params.forEach((k, v) {
      String value;
      if (v != null) {
        String str = valueToString(v);
        value = str
            .replaceAll("<", "&lt;")
            .replaceAll(">", "&gt;")
            .replaceAll('"', "'");
      } else {
        value = "[null]";
      }
      sb.write(' $k="$value"');
    });
  }

  void addCurrentIndent() {
    sb.write(indentation);
  }

  /// Converts a parameter value into a string.
  String valueToString(var value) => value;
}
